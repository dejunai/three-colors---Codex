extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var Lang = load("res://scripts/shared/portal_lang.gd")
	var Runtime = load("res://scripts/shared/portal_runtime.gd")
	var toll_src = "LOCATION: test_toll\nPORTAL: toll_gate\n  GATE: always\n  TIME: 15\n  GO: estate | 0,0.1,35 | 0\n"
	var parsed = Lang.parse(toll_src)
	print("errors=", parsed.errors)

	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.playthrough_log.endpoint_url = ""
	g.state = g.CaseState.new()
	g.state.started = true

	print("clock_before=", g.state.clock_minutes)
	var first = Runtime.enter(parsed, "toll_gate", Runtime.make_context(g.state), g.state)
	print("go=", first.go, " session=", first.session)
	g.portals._play(g, first)
	await process_frame
	print("clock_after=", g.state.clock_minutes)
	print("portal_done=", g.state.portal_state.portal_done("test_toll", "toll_gate"))
	quit(0)

