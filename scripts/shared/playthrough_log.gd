extends Node

const DayClock = preload("res://scripts/shared/day_clock.gd")
const SESSION_PATH = "user://anonymous_playthrough_session.json"

# Empty by design until the collection endpoint and its CORS policy are approved.
# A deployment can set three_colors/telemetry_endpoint without changing this script.
var endpoint_url := String(ProjectSettings.get_setting("three_colors/telemetry_endpoint", ""))
var enabled := true
var session_id := ""
var buffer: Array[Dictionary] = []
var request: HTTPRequest
var request_busy := false
var in_flight_count := 0
var session_started_ms := 0
var previous_transition_ms := 0
var previous_transition_game_minutes := 0.0
var phase_token := ""
var known_visited_npcs := {}
var phase_npcs := {}
var first_objective_sent := false
var day3_started_ms := -1
var day3_bed_sent := false
var ended := false

func _ready() -> void:
	request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_request_completed)

func begin(state, npc_ids:Array = []) -> void:
	if not enabled: return
	reset_runtime()
	session_id = _uuid_v4()
	_store_session_id()
	_initialize_tracking(state, npc_ids)
	_log("session_start")

func resume(state, npc_ids:Array = []) -> void:
	if not enabled: return
	if not session_id.is_empty(): return
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null: return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		session_id = String(parsed.get("session_id", ""))
	if session_id.is_empty(): return
	reset_runtime(false)
	_initialize_tracking(state, npc_ids)

func reset_runtime(clear_id:bool = true) -> void:
	if clear_id: session_id = ""
	buffer.clear()
	request_busy = false
	in_flight_count = 0
	session_started_ms = Time.get_ticks_msec()
	previous_transition_ms = session_started_ms
	previous_transition_game_minutes = 0.0
	phase_token = ""
	known_visited_npcs.clear()
	phase_npcs.clear()
	first_objective_sent = false
	day3_started_ms = -1
	day3_bed_sent = false
	ended = false

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
	var now := Time.get_ticks_msec()
	_log("district_transition", {
		"from_world": from_world,
		"to_world": to_world,
		"real_seconds_elapsed": maxf(0.0, float(now - previous_transition_ms) / 1000.0),
		"game_minutes_elapsed": maxf(0.0, float(state.clock_minutes) - previous_transition_game_minutes)
	})
	previous_transition_ms = now
	previous_transition_game_minutes = float(state.clock_minutes)

func day3_bed_reached() -> void:
	if session_id.is_empty() or ended or day3_bed_sent: return
	day3_bed_sent = true
	var elapsed := 0.0 if day3_started_ms < 0 else maxf(0.0, float(Time.get_ticks_msec() - day3_started_ms) / 1000.0)
	_log("day3_bed_reached", {"real_seconds_since_day3_start": elapsed})

func debrief(town_feel:String, time_natural:String) -> void:
	if session_id.is_empty() or ended: return
	_log("debrief", {"town_feel": town_feel, "time_natural": time_natural})

func end(state, ended_via:String) -> void:
	if session_id.is_empty() or ended: return
	_log("session_end", {
		"total_real_seconds": maxf(0.0, float(Time.get_ticks_msec() - session_started_ms) / 1000.0),
		"final_day": int(state.day),
		"ended_via": ended_via
	})
	ended = true
	_flush()
	if ended_via == "completed": DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))

func _log(event_name:String, fields:Dictionary = {}) -> void:
	var event := {
		"session_id": session_id,
		"event": event_name,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	for key in fields: event[key] = fields[key]
	buffer.append(event)
	_flush()

func _flush() -> void:
	if endpoint_url.is_empty() or request_busy or buffer.is_empty() or not is_instance_valid(request): return
	in_flight_count = buffer.size()
	request_busy = true
	var error := request.request(endpoint_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"events": buffer.slice(0, in_flight_count)}))
	if error != OK:
		request_busy = false
		in_flight_count = 0

func _request_completed(_result:int, response_code:int, _headers:PackedStringArray, _body:PackedByteArray) -> void:
	var succeeded := response_code >= 200 and response_code < 300
	if succeeded:
		for _index in in_flight_count:
			if not buffer.is_empty(): buffer.pop_front()
	request_busy = false
	in_flight_count = 0
	# A failure remains buffered until the next event. Never retry in a gameplay loop.
	if succeeded: _flush()

func _store_session_id() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"session_id": session_id}))

func _uuid_v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0,8), hex.substr(8,4), hex.substr(12,4), hex.substr(16,4), hex.substr(20,12)]
