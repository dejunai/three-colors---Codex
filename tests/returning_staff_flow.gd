extends SceneTree
func _initialize() -> void: call_deferred("run")

func menu_ids(runtime, definition:Dictionary, state) -> Array:
	return runtime.menu(definition, runtime.make_context(state, state.dialogue_state)).entries.map(func(entry): return entry.id)

func run() -> void:
	var catalog=load("res://scripts/chapters/dialogue_catalog.gd").new()
	assert(catalog.RETURNING_STAFF.has("coroners_assistant_morgue"))
	assert(not catalog.RETURNING_STAFF.has("assistant_morgue"))
	var state=load("res://case_state.gd").new()
	for npc in catalog.RETURNING_STAFF:
		var location=catalog.RETURNING_STAFF[npc][0]
		catalog.definitions[npc]={"location":location,"schedule":{"morning":location,"midday":location,"evening":"closed"}}
		state.day=1
		state.estate_complete=true
		assert(catalog.slot(npc,state).is_empty())
		state.day=2
		state.estate_complete=false
		assert(catalog.slot(npc,state).is_empty())
		state.estate_complete=true
		assert(catalog.slot(npc,state)[0]==location)
		state.day=3
		assert(catalog.slot(npc,state)[0]==location)
		state.clock_minutes=1200
		assert(catalog.slot(npc,state).is_empty())
		state.clock_minutes=360

	# Precinct topics complete under the location-specific NPC identity. The
	# estate Odell identity must not keep a finished precinct topic available.
	var runtime=load("res://scripts/shared/dialogue_runtime.gd")
	var odell=runtime.load_npc("res://dialogue/odell_precinct.dialogue")
	state=load("res://case_state.gd").new()
	state.day=2
	state.estate_complete=true
	assert(menu_ids(runtime,odell,state).has("day_two_check"))
	state.dialogue_state.complete_topic("odell_precinct","day_two_check")
	assert(not menu_ids(runtime,odell,state).has("day_two_check"))
	state.discover("insurance_fraud_record")
	assert(menu_ids(runtime,odell,state).has("day_two_pressure"))
	state.dialogue_state.complete_topic("odell_precinct","day_two_pressure")
	assert(not menu_ids(runtime,odell,state).has("day_two_pressure"))
	state.day=3
	assert(menu_ids(runtime,odell,state).has("day_three_final"))
	state.dialogue_state.complete_topic("odell_precinct","day_three_final")
	assert(not menu_ids(runtime,odell,state).has("day_three_final"))
	print("RETURNING STAFF PASS: slots and location-specific topic completion")
	quit()
