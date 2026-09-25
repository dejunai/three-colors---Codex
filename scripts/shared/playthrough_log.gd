extends Node

const DayClock = preload("res://scripts/shared/day_clock.gd")
const SESSION_PATH = "user://anonymous_playthrough_session.json"
const REQUEST_TIMEOUT_SEC := 5.0
const REQUEST_TIMEOUT_MS := 5000
const MAX_BUFFER_SIZE := 300
const MAX_REQUEST_BATCH := 32 # Must match the Worker's MAX_EVENTS contract.
const MAX_BEACON_BACKLOG := 24 # Worker accepts at most 32 events per request.

# Empty by design until the collection endpoint and its CORS policy are approved.
# A deployment can set three_colors/telemetry_endpoint without changing this script.
var endpoint_url := String(ProjectSettings.get_setting("three_colors/telemetry_endpoint", ""))
var enabled := true
var session_id := ""
var buffer: Array[Dictionary] = []
var request: HTTPRequest
var request_busy := false
var in_flight_count := 0
var request_sent_ms := 0
var session_started_ms := 0
var previous_transition_ms := 0
var previous_transition_game_minutes := 0.0
var phase_token := ""
var known_visited_npcs := {}
var phase_npcs := {}
var first_objective_sent := false
var day3_started_ms := -1
var day3_bed_sent := false
var debrief_sent := false
var ended := false
var dev_brisk_used := false
var latest_day := 1
var _pagehide_callback

func _ready() -> void:
	_ensure_request()
	_install_web_pagehide()

func _install_web_pagehide() -> void:
	if not OS.has_feature("web"): return
	var window = JavaScriptBridge.get_interface("window")
	if window == null: return
	_pagehide_callback = JavaScriptBridge.create_callback(_on_web_pagehide)
	window.addEventListener("pagehide", _pagehide_callback)

func _on_web_pagehide(args:Array) -> void:
	# A persisted pagehide enters the browser back-forward cache and can resume;
	# do not terminate telemetry for that temporary suspension.
	if not args.is_empty() and bool(args[0].persisted): return
	if session_id.is_empty() or ended: return
	var closing_event := _event("session_end", {
		"total_real_seconds": _total_real_seconds(),
		"final_day": latest_day,
		"ended_via": "closed",
		"dev_brisk_used": dev_brisk_used
	})
	if not _send_web_beacon(_with_recent_pending([closing_event])): _queue_event(closing_event)
	ended = true

func _ensure_request() -> void:
	if is_instance_valid(request): return
	request = HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT_SEC
	add_child(request)
	request.request_completed.connect(_request_completed)

func begin(state, npc_ids:Array = []) -> void:
	if not enabled: return
	reset_runtime()
	session_id = _uuid_v4()
	_store_session_id()
	_initialize_tracking(state, npc_ids)
	latest_day = int(state.day)
	_log("session_start")

func resume(state, npc_ids:Array = []) -> void:
	if not enabled: return
	if not session_id.is_empty():
		# Save-and-return can resume in the same process after a closed event.
		if ended:
			var persisted_dev_brisk_used := dev_brisk_used
			reset_runtime(false)
			dev_brisk_used = persisted_dev_brisk_used
			_initialize_tracking(state, npc_ids)
			latest_day = int(state.day)
		return
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null: return
	var parsed = JSON.parse_string(file.get_as_text())
	var persisted_dev_brisk_used := false
	if parsed is Dictionary:
		session_id = String(parsed.get("session_id", ""))
		persisted_dev_brisk_used = bool(parsed.get("dev_brisk_used", false))
	if session_id.is_empty(): return
	reset_runtime(false)
	dev_brisk_used = persisted_dev_brisk_used
	_initialize_tracking(state, npc_ids)
	latest_day = int(state.day)

func reset_runtime(clear_id:bool = true) -> void:
	if clear_id: session_id = ""
	buffer.clear()
	if request_busy and is_instance_valid(request):
		request.cancel_request()
	request_busy = false
	in_flight_count = 0
	request_sent_ms = 0
	session_started_ms = Time.get_ticks_msec()
	previous_transition_ms = session_started_ms
	previous_transition_game_minutes = 0.0
	phase_token = ""
	known_visited_npcs.clear()
	phase_npcs.clear()
	first_objective_sent = false
	day3_started_ms = -1
	day3_bed_sent = false
	debrief_sent = false
	ended = false
	dev_brisk_used = false
	latest_day = 1

func _initialize_tracking(state, npc_ids:Array) -> void:
	var now := Time.get_ticks_msec()
	session_started_ms = now
	previous_transition_ms = now
	previous_transition_game_minutes = float(state.clock_minutes)
	phase_token = "%d:%s" % [int(state.day), DayClock.phase(float(state.clock_minutes))]
	first_objective_sent = not state.evidence.is_empty() or not state.statements.is_empty()
	for id in state.visited:
		if npc_ids.has(id): known_visited_npcs[String(id)] = true
	if int(state.day) == 3: day3_started_ms = now

func observe(state, npc_ids:Array) -> void:
	if session_id.is_empty() or ended: return
	latest_day = int(state.day)
	if not first_objective_sent and (not state.evidence.is_empty() or not state.statements.is_empty()):
		first_objective_sent = true
		_log("first_objective")
	for raw_id in state.visited:
		var id := String(raw_id)
		if npc_ids.has(id) and not known_visited_npcs.has(id):
			known_visited_npcs[id] = true
			phase_npcs[id] = true
	var current_phase := DayClock.phase(float(state.clock_minutes))
	var current_token := "%d:%s" % [int(state.day), current_phase]
	if current_token != phase_token:
		_log("phase_change", {
			"day": int(state.day),
			"new_phase": current_phase,
			"npcs_spoken_to_this_phase": phase_npcs.size()
		})
		phase_npcs.clear()
		phase_token = current_token
		if int(state.day) == 3 and day3_started_ms < 0:
			day3_started_ms = Time.get_ticks_msec()

func district_transition(from_world:String, to_world:String, state) -> void:
	if session_id.is_empty() or ended or from_world == to_world: return
	latest_day = int(state.day)
	var now := Time.get_ticks_msec()
	_log("district_transition", {
		"from_world": from_world,
		"to_world": to_world,
		"real_seconds_elapsed": roundi(maxf(0.0, float(now - previous_transition_ms) / 1000.0)),
		"game_minutes_elapsed": snappedf(maxf(0.0, float(state.clock_minutes) - previous_transition_game_minutes), 0.1)
	})
	previous_transition_ms = now
	previous_transition_game_minutes = float(state.clock_minutes)

func conversation(npc_id:String, topic_id:String, state) -> void:
	if session_id.is_empty() or ended: return
	latest_day = int(state.day)
	_log("conversation", {
		"npc_id": npc_id,
		"topic_id": topic_id,
		"coat_state": "plain" if String(state.coat) == "Plain wool coat" else "police",
		"world": String(state.world),
		"day": int(state.day),
		"phase": DayClock.phase(float(state.clock_minutes))
	})

func note_developer_brisk_used() -> void:
	if session_id.is_empty() or ended or dev_brisk_used: return
	dev_brisk_used = true
	_store_session_id()

func day3_bed_reached() -> void:
	if session_id.is_empty() or ended or day3_bed_sent: return
	day3_bed_sent = true
	var elapsed := 0 if day3_started_ms < 0 else roundi(maxf(0.0, float(Time.get_ticks_msec() - day3_started_ms) / 1000.0))
	_log("day3_bed_reached", {"real_seconds_since_day3_start": elapsed})

func debrief(town_feel:String, time_natural:String) -> void:
	if session_id.is_empty() or ended or debrief_sent: return
	debrief_sent = true
	_log("debrief", {"town_feel": town_feel, "time_natural": time_natural})

func complete(state, town_feel:String, time_natural:String) -> void:
	if session_id.is_empty() or ended: return
	latest_day = int(state.day)
	debrief_sent = true
	var final_events := [
		_event("debrief", {"town_feel": town_feel, "time_natural": time_natural}),
		_event("session_end", {
			"total_real_seconds": _total_real_seconds(),
			"final_day": latest_day,
			"ended_via": "completed",
			"dev_brisk_used": dev_brisk_used
		})
	]
	ended = true
	# On Web, Beacon owns this small final batch so navigation or an immediate
	# Save-and-Quit cannot cancel it. D1's deterministic event keys make a
	# retry harmless; R2 keeps the accepted raw batch.
	if not _send_web_beacon(_with_recent_pending(final_events)):
		for event in final_events: _queue_event(event, false)
		_flush()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))

func close_with_debrief(state, town_feel:String, time_natural:String) -> void:
	if session_id.is_empty() or ended: return
	latest_day = int(state.day)
	debrief_sent = true
	var final_events := [
		_event("debrief", {"town_feel": town_feel, "time_natural": time_natural}),
		_event("session_end", {
			"total_real_seconds": _total_real_seconds(),
			"final_day": latest_day,
			"ended_via": "closed",
			"dev_brisk_used": dev_brisk_used
		})
	]
	ended = true
	if not _send_web_beacon(_with_recent_pending(final_events)):
		for event in final_events: _queue_event(event, false)
		_flush()

func end(state, ended_via:String) -> void:
	if session_id.is_empty() or ended: return
	latest_day = int(state.day)
	var ending_event := _event("session_end", {
		"total_real_seconds": _total_real_seconds(),
		"final_day": latest_day,
		"ended_via": ended_via,
		"dev_brisk_used": dev_brisk_used
	})
	ended = true
	if not _send_web_beacon(_with_recent_pending([ending_event])):
		_queue_event(ending_event, false)
		_flush()
	if ended_via == "completed": DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))

func _total_real_seconds() -> int:
	return roundi(maxf(0.0, float(Time.get_ticks_msec() - session_started_ms) / 1000.0))

func _event(event_name:String, fields:Dictionary = {}) -> Dictionary:
	var event := {
		"session_id": session_id,
		"event": event_name,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	for key in fields: event[key] = fields[key]
	return event

func _queue_event(event:Dictionary, flush_now:bool = true) -> void:
	buffer.append(event)
	while buffer.size() > MAX_BUFFER_SIZE:
		buffer.pop_front()
	if flush_now: _flush()

func _log(event_name:String, fields:Dictionary = {}) -> void:
	_queue_event(_event(event_name, fields))

func _with_recent_pending(final_events:Array) -> Array:
	# A failed or still-running HTTPRequest can leave the glass marker in memory.
	# Include the newest pending events in the teardown-safe batch; D1 event keys
	# make retransmission harmless. Keep the batch below the Worker's 32-event cap.
	var events:Array = []
	var start := maxi(0, buffer.size() - MAX_BEACON_BACKLOG)
	for index in range(start, buffer.size()):
		events.append(buffer[index].duplicate(true))
	for event in final_events:
		events.append(event)
	return events

func _send_web_beacon(events:Array) -> bool:
	if not OS.has_feature("web") or endpoint_url.is_empty() or events.is_empty(): return false
	var body := JSON.stringify({"events": events})
	var script := "navigator.sendBeacon(%s, new Blob([%s], {type: 'text/plain;charset=UTF-8'}))" % [JSON.stringify(endpoint_url), JSON.stringify(body)]
	return bool(JavaScriptBridge.eval(script, true))

func _request_batch() -> Array:
	return buffer.slice(0, mini(buffer.size(), MAX_REQUEST_BATCH))

func _flush() -> void:
	if endpoint_url.is_empty() or buffer.is_empty(): return
	_ensure_request()
	if not is_instance_valid(request): return

	if request_busy:
		if Time.get_ticks_msec() - request_sent_ms > REQUEST_TIMEOUT_MS:
			# Stale request recovery: prior request hung without completing.
			request.cancel_request()
			request_busy = false
			in_flight_count = 0
			request_sent_ms = 0
		else:
			return

	var batch := _request_batch()
	in_flight_count = batch.size()
	request_busy = true
	request_sent_ms = Time.get_ticks_msec()
	var error := request.request(endpoint_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"events": batch}))
	if error != OK:
		request_busy = false
		in_flight_count = 0
		request_sent_ms = 0

func _request_completed(result:int, response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	if succeeded:
		for _index in in_flight_count:
			if not buffer.is_empty(): buffer.pop_front()
	request_busy = false
	in_flight_count = 0
	request_sent_ms = 0
	# A failure remains buffered until the next event. Never retry in a gameplay loop.
	if succeeded: _flush()

func _store_session_id() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"session_id": session_id, "dev_brisk_used": dev_brisk_used}))

func _uuid_v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8), hex.substr(8,4), hex.substr(12,4), hex.substr(16,4), hex.substr(20,12)]
