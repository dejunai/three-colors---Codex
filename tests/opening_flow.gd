extends RefCounted

func run(g:Node) -> void:
	# Actual scene integration tests exercise cards, progression, copies and disk reload.
	await g.get_tree().physics_frame
	g.state.started=true
	g._close()
	g._interact("odell")
	while g.page == "dialogue": g._next_card()
	assert(g.state.evidence.has("eight"),"Required consultation supplies the count without optional collection")
	assert(g.state.visited.has("odell"))
	assert(g.page=="witness","Odell's dismissal opens a response choice")
	for button in g.content.find_children("*","Button",true,false):
		if button.text.begins_with("\"I understand it"):
			button.pressed.emit()
			break
	assert(g.state.statements.has("Walter told Odell to his face that six was not the whole count. Odell did not answer."))
	g._save_game()
	g._load_game()
	g._interact("odell")
	while g.page=="dialogue": g._next_card()
	for button in g.content.find_children("*","Button",true,false):
		assert(not button.text.begins_with("Say nothing"),"Saved Odell answer cannot be reversed")
	g._write_report("Observations filed","report_routine")
	while g.page == "dialogue": g._next_card()
	assert(g.state.copies.size()==2)
	assert(not g.state.visited.has("wounds"),"Minimal path must not claim examinations not performed")
	for id in ["wounds","eight","knife","watch","gas","register","shoes","assistant"]:
		g._interact(id)
		while g.page == "dialogue": g._next_card()
	assert(not g.estate.points.has("barman") and not g.estate.points.has("crew"))
	g._interact("barman")
	assert(g.page!="witness","Steward cannot be interviewed at the opening crime scene")
	assert(g.state.evidence.size()==8)
	assert(g.state.report_evidence.size()==1,"Later observations do not rewrite prepared copies")
	g.state.coat="Plain wool coat"
	g._write_report("Full inquest requested","report_inquest")
	while g.page == "dialogue": g._next_card()
	assert(g.state.copies.size()==3)
	g.state.flask=1
	g.comfort_time=45
	g.player.position=Vector3(10,0.1,-3)
	assert(g._save_game())
	g.state=g.CaseState.new()
	g._load_game()
	assert(g.state.evidence.size()==8 and g.state.flask==1 and g.state.copies.size()==3)
	assert(g.state.coat=="Plain wool coat" and g.comfort_time==45)
	assert(g.player.position.distance_to(Vector3(10,0.1,-3))<0.01)
	g._journal()
	assert(g.page=="journal")
	g._case_file()
	assert(g.page=="case")
	g._settings()
	assert(g.page=="settings")
	g._finish()
	assert(g.state.estate_complete)
	assert(g._save_game())
	var file=FileAccess.open(g._save_path(),FileAccess.READ)
	var saved=JSON.parse_string(file.get_as_text())
	assert(saved.estate_complete and saved.copies.size()==3)
	print("QA PASS: minimal route; eight opening observations; Odell response choice; deferred steward and groundskeeper; two/three copies; full save/load; protected menus; completion")
	# Walk through actual physics using the same input actions as the g.player.
	g.state.finished=false
	g._close()
	g.player.position=Vector3(0,0.1,36)
	g.yaw=0
	for stop in [Vector3(-1,0,31),Vector3(0,0,7),Vector3(0,0,1),Vector3(-4,0,-2),Vector3(-6,0,-0.4),Vector3(-12,0,1),Vector3(-5,0,1),Vector3(6,0,0),Vector3(12,0,-4),Vector3(23,0,-3.3),Vector3(25.6,0,-4),Vector3(12,0,-4),Vector3(10,0,-12),Vector3(4,0,-11.5),Vector3(7.4,0,-12.7),Vector3(6,0,-12.7),Vector3(-8,0,-18)]:
		await g._walk_to(stop)
	for stop in [Vector3(-8,0,-18),Vector3(-5,0,-11),Vector3(-5,0,1),Vector3(0,0,7),Vector3(0,0,39)]:
		await g._walk_to(stop)
	assert(g.focused=="exit","Departure must be reachable through real collision and interaction focus")
	# The hedge must block movement, rather than merely decorate the lawn.
	g.player.position=Vector3(10,0.1,9)
	Input.action_press("walk_forward")
	for i in 100: await g.get_tree().physics_frame
	Input.action_release("walk_forward")
	assert(g.player.position.z>6.6,"Hedge must block the g.player")
	print("QA PASS: actual WASD traversal through gate, garden, birch grove and terrace; departure focus; hedge collision")
	g.get_tree().quit()

