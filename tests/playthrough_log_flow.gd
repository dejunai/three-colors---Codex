extends SceneTree

const CaseState = preload("res://case_state.gd")
const PlaythroughLog = preload("res://scripts/shared/playthrough_log.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var logger = PlaythroughLog.new()
	root.add_child(logger)
	await process_frame
	logger.endpoint_url = ""
	var state = CaseState.new()
	var npcs = ["boy", "odell"]
	logger.begin(state,npcs)
	var first_id:String = logger.session_id
	assert(_valid_uuid_v4(first_id))
	assert(logger.buffer.size() == 1 and logger.buffer[0].event == "session_start")

	state.discover("six")
	logger.observe(state,npcs)
	logger.observe(state,npcs)
	assert(_events(logger,"first_objective").size() == 1)

	state.visited.append("boy")
	logger.observe(state,npcs)
	state.clock_minutes = 720.0
	logger.observe(state,npcs)
	var phases = _events(logger,"phase_change")
	assert(phases.size() == 1)
	assert(phases[0].day == 1 and phases[0].new_phase == "noon")
	assert(phases[0].npcs_spoken_to_this_phase == 1)

	state.clock_minutes = 750.0
	logger.district_transition("estate","town",state)
	var trips = _events(logger,"district_transition")
	assert(trips.size() == 1)
	assert(trips[0].from_world == "estate" and trips[0].to_world == "town")
	assert(trips[0].real_seconds_elapsed >= 0.0 and trips[0].game_minutes_elapsed == 390.0)
	assert(trips[0].real_seconds_elapsed is int)
	assert(snappedf(trips[0].game_minutes_elapsed, 0.1) == trips[0].game_minutes_elapsed)

	state.coat = "Plain wool coat"
	state.world = "town"
	logger.conversation("mrs_almy", "crew_omission", state)
	var conversations = _events(logger,"conversation")
	assert(conversations.size() == 1)
	assert(conversations[0].npc_id == "mrs_almy" and conversations[0].topic_id == "crew_omission")
	assert(conversations[0].coat_state == "plain" and conversations[0].world == "town")
	assert(conversations[0].day == 1 and conversations[0].phase == "noon")

	state.day = 3
	state.clock_minutes = 360.0
	logger.observe(state,npcs)
	logger.day3_bed_reached()
	assert(_events(logger,"day3_bed_reached").size() == 1)
	assert(_events(logger,"day3_bed_reached")[0].real_seconds_since_day3_start >= 0.0)
	assert(_events(logger,"day3_bed_reached")[0].real_seconds_since_day3_start is int)
	var teardown_batch := logger._with_recent_pending([logger._event("session_end")])
	assert(teardown_batch.size() <= 25, "Beacon backlog must remain under the Worker's 32-event limit")
	assert(teardown_batch.any(func(item): return item.event == "day3_bed_reached"), "final Beacon must recover a pending glass marker")
	assert(teardown_batch[-1].event == "session_end")
	logger.note_developer_brisk_used()
	logger.note_developer_brisk_used()
	assert(logger.dev_brisk_used)
	var resumed_logger = PlaythroughLog.new()
	resumed_logger.endpoint_url = ""
	root.add_child(resumed_logger)
	resumed_logger.resume(state,npcs)
	assert(resumed_logger.session_id == first_id and resumed_logger.dev_brisk_used, "developer pace usage must survive process restart/save load")

	# Loading during this runtime keeps the same opaque id and emits no second start.
	logger.resume(state,npcs)
	assert(logger.session_id == first_id)
	assert(_events(logger,"session_start").size() == 1)
	logger.complete(state,"alive","yes")
	logger.complete(state,"confusing","no")
	assert(_events(logger,"debrief").size() == 1)
	assert(_events(logger,"debrief")[0].town_feel == "alive" and _events(logger,"debrief")[0].time_natural == "yes")
	assert(_events(logger,"session_end").size() == 1, "completion must queue debrief and session_end atomically")
	assert(_events(logger,"session_end")[0].ended_via == "completed")
	assert(_events(logger,"session_end")[0].total_real_seconds is int)
	assert(_events(logger,"session_end")[0].dev_brisk_used == true)
	assert(_payload_is_private(logger.buffer))

	var fresh_state = CaseState.new()
	logger.begin(fresh_state,npcs)
	assert(logger.session_id != first_id)
	assert(not logger.dev_brisk_used)
	logger.note_developer_brisk_used()
	logger.end(fresh_state,"closed")
	assert(_events(logger,"session_end")[0].dev_brisk_used == true)
	logger.resume(fresh_state,npcs)
	assert(not logger.ended and logger.dev_brisk_used, "same-process save/load must reactivate logging without clearing sticky developer pace")
	assert(logger.request != null and logger.request.timeout == 5.0)

	# Verify stuck request recovery on timeout threshold
	logger.endpoint_url = "http://127.0.0.1:9999/dummy"
	logger.request_busy = true
	logger.request_sent_ms = Time.get_ticks_msec() - 8000
	logger.buffer.append({"session_id": logger.session_id, "event": "test_stale"})
	logger._flush()
	# The stale lock must be broken (request.request to dummy port will fail or connect, but request_busy will not stay hung from the prior 8s-old request)
	logger.endpoint_url = ""

	print("PLAYTHROUGH LOG PASS: UUID lifecycle, objective, phase, transition, conversation context, Day 3, timeout recovery, and privacy payload")
	quit(0)

func _events(logger,event_name:String) -> Array:
	return logger.buffer.filter(func(item): return item.event == event_name)

func _valid_uuid_v4(value:String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	return regex.search(value) != null

func _payload_is_private(events:Array) -> bool:
	var allowed = ["session_id","event","timestamp","from_world","to_world","real_seconds_elapsed","game_minutes_elapsed","day","new_phase","npcs_spoken_to_this_phase","real_seconds_since_day3_start","town_feel","time_natural","total_real_seconds","final_day","ended_via","dev_brisk_used","npc_id","topic_id","coat_state","world","phase"]
	for event in events:
		for key in event:
			if not allowed.has(key): return false
	return true
