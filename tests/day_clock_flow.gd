extends SceneTree
const Clock=preload("res://scripts/shared/day_clock.gd")
func _initialize() -> void: call_deferred("run")
func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	g.state=g.CaseState.new()
	g.state.started=true
	g._travel("estate",Vector3(0,0.1,35),0,false)
	assert(g.state.clock_minutes==360)
	g.tick_world(60)
	assert(is_equal_approx(g.state.clock_minutes,365))
	g._interact("boy")
	var before=g.state.clock_minutes
	g.tick_world(60)
	assert(g.state.clock_minutes==before,"Dialogue pauses wandering time")
	cards(g)
	assert(g.state.clock_minutes==before+4)
	g._interact("boy")
	cards(g)
	assert(g.state.clock_minutes==before+7,"A new unpriced repeat variant costs the authored default three minutes once")
	g._cards(g.Story.SCENES.boy,g._close)
	cards(g)
	assert(g.state.clock_minutes==before+7,"Exact same substantive dialogue cannot be charged twice")
	g._cards([["A RESIDENT","I've got nothing to say about it."]],g._close)
	cards(g)
	assert(g.state.clock_minutes==before+7)
	g._travel("town",Vector3(0,0.1,8))
	assert(g.state.clock_minutes==before+37)
	g._travel("boardinghouse",Vector3(0,0.1,6))
	assert(g.state.clock_minutes==before+37)
	g._travel("town",Vector3(0,0.1,8))
	g._travel("business",Vector3(10,0.1,25))
	assert(g.state.clock_minutes==before+67)
	g._travel("schoolhouse",Vector3(0,0.1,6))
	g._travel("business",Vector3(-19,0.1,-3))
	assert(g.state.clock_minutes==before+67)
	g._save_game()
	g._load_game()
	assert(g.state.clock_minutes==before+67 and g.state.timed_conversations.has("boy"))
	g._journal()
	g.tick_world(600)
	assert(g.state.clock_minutes==before+67,"Notebook reading is free")
	g._close()
	for spec in [[360.0,"morning"],[720.0,"noon"],[1020.0,"evening"],[1200.0,"night"]]:
		g.state.clock_minutes=spec[0]
		g.daylight.update_clock(spec[0],g.player.position)
		assert(g.daylight.phase_name==spec[1])
		assert(g.daylight.sun_disk.visible==(spec[1]!="night"))
		for light in g.estate.find_children("*","OmniLight3D",true,false):
			if light.has_meta("street_lamp"): assert(light.visible==(spec[1] in ["evening","night"]))
		if spec[1]=="morning": assert(g.daylight.sun_disk.position.x>g.player.position.x)
		if spec[1]=="evening": assert(g.daylight.sun_disk.position.x<g.player.position.x)
		if spec[1]=="noon": assert(g.daylight.sun_disk.position.y>90 and g.daylight.sun_disk.position.x==g.player.position.x)
	g.tick_world(600)
	g._travel("town",Vector3(0,0.1,8))
	assert(g.state.clock_minutes==1200,"Night holds through wandering and travel")
	g._save_game()
	g._load_game()
	assert(g.state.clock_minutes==1200 and not g.daylight.sun_disk.visible)
	var data=g.state.pack()
	data.version=6
	data.erase("clock_minutes")
	data.erase("timed_conversations")
	data.visited=["boy"]
	var restored=g.CaseState.new()
	assert(restored.restore(data))
	assert(restored.clock_minutes==360 and restored.timed_conversations.has("boy"))
	data.version=7
	data.clock_minutes="bad"
	assert(not restored.restore(data))
	g.state.intake_done=true
	g.state.discover("naomi")
	g.state.steward_visits=1
	g._travel("room",Vector3(0,0.1,6))
	g._interact("sleep")
	assert(g.page=="montage")
	while g.page=="montage": g.content.find_children("*","Button",true,false)[0].pressed.emit()
	assert(g.state.day==3 and g.state.clock_minutes==360)
	print("CLOCK PASS: 5x walking; paused dialogue/menus; completion-only authored minute cost; no repeat/refusal farming; district-only travel; four sun/lamp states; night hold; save migration; montage resets morning")
	quit()
