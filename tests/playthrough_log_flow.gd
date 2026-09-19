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
	logger.debrief("alive","yes")
	logger.debrief("confusing","no")
	assert(_events(logger,"debrief").size() == 1)
	assert(_events(logger,"debrief")[0].town_feel == "alive")
	assert(_events(logger,"debrief")[0].time_natural == "yes")

	# Loading during this runtime keeps the same opaque id and emits no second start.
	logger.resume(state,npcs)
	assert(logger.session_id == first_id)
	assert(_events(logger,"session_start").size() == 1)
	logger.end(state,"completed")
	assert(_events(logger,"session_end")[0].ended_via == "completed")
	assert(_events(logger,"session_end")[0].total_real_seconds is int)
	assert(_payload_is_private(logger.buffer))

	logger.begin(CaseState.new(),npcs)
	assert(logger.session_id != first_id)
	print("PLAYTHROUGH LOG PASS: UUID lifecycle, objective, phase, transition, conversation context, Day 3 and privacy payload")
	quit(0)

func _events(logger,event_name:String) -> Array:
	return logger.buffer.filter(func(item): return item.event == event_name)

func _valid_uuid_v4(value:String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	return regex.search(value) != null

func _payload_is_private(events:Array) -> bool:
	var allowed = ["session_id","event","timestamp","from_world","to_world","real_seconds_elapsed","game_minutes_elapsed","day","new_phase","npcs_spoken_to_this_phase","real_seconds_since_day3_start","town_feel","time_natural","total_real_seconds","final_day","ended_via","npc_id","topic_id","coat_state","world","phase"]
	for event in events:
		for key in event:
			if not allowed.has(key): return false
	return true
