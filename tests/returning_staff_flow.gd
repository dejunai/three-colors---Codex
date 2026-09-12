extends SceneTree
func _initialize() -> void: call_deferred("run")
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
	print("RETURNING STAFF SLOTS PASS")
	quit()
