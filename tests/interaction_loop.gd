extends RefCounted

func finish_cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()

func run(g:Node) -> void:
	await g.get_tree().physics_frame
	g.state=g.CaseState.new()
	g.state.started=true
	g.state.finished=true
	g.state.estate_complete=true
	for id in ["eight","naomi","intake"]: g.state.discover(id)
	g.state.complete_report("Observations filed")
	g.state.receive_report()
	g.state.flask=0
	g._begin_tunnel()
	finish_cards(g)
	assert(g.state.world=="tunnel")
	assert(not g.estate.route_available,"Minimal build retains the marked outer route")
	assert(not g._take_pour())
	# Actual movement, not teleported completion, with no flask and no optional evidence.
	await g._walk_to(Vector3(-7,0,4))
	await g._walk_to(Vector3(-7,0,-28))
	await g._walk_to(Vector3(0,0,-30.2))
	assert(g.page=="play" and g.focused=="tunnel_record")
	g._interact("tunnel_record")
	finish_cards(g)
	assert(g.state.evidence.has("lower_foundation"))
	await g._walk_to(Vector3(-7,0,-28))
	await g._walk_to(Vector3(-7,0,4))
	await g._walk_to(Vector3(0,0,8))
	g._interact("tunnel_exit")
	finish_cards(g)
	assert(g.state.tunnel_complete and g.state.world=="precinct")
	assert(g._custody_result().begins_with("No county"))
	assert(not g._county_has_comparison())
	print("LOOP PASS: minimal route without flask or board; lower measurement; return and unsent-copy consequence")
	# Complete snapshots, including statements captured after the original was received.
	g.state.record("Later gardener statement · source: gardener in plain coat")
	g.state.discover("wounds")
	g.state.discover("gas")
	g.state.file_supplement(true,g._current_sources())
	var first=g.state.supplement_history[0].duplicate(true)
	assert(first.statements.has("Later gardener statement · source: gardener in plain coat"))
	assert(first.sources.has("lower_foundation"))
	g.state.record("A still later statement")
	g.state.file_supplement(false)
	assert(g.state.supplement_history[0]==first)
	assert(g._custody_result().contains("service plan"))
	assert(g._county_has_comparison())
	g._intake()
	var request_buttons=g.content.find_children("*","Button",true,false)
	var request_found=false
	for button in request_buttons:
		if button.text.contains("foundation request"):
			button.pressed.emit()
			request_found=true
			break
	assert(request_found and g.state.evidence.has("county_foundation_request"))
	g.state.flask=3
	g.comfort_time=37
	g._begin_tunnel()
	finish_cards(g)
	assert(g.estate.route_available)
	var checkpoint=g.tunnel_checkpoint.duplicate(true)
	g._take_pour()
	assert(g.state.flask==2 and g.comfort_time==90)
	g.state.discover("service_recess")
	g.estate.clock=2.1
	g.player.position=Vector3(0,0,-13)
	# Let the actual encounter detect and kill, without invoking its death handler directly.
	for i in 120:
		await g.get_tree().physics_frame
		if g.page=="death": break
	assert(g.page=="death")
	g._load_game()
	assert(g.page=="death","Continue must not revive a dead save")
	g._retry_tunnel()
	assert(g._session_snapshot()==checkpoint,"Every checkpoint field must restore exactly")
	g.estate.clock=7.25
	g.player.position=Vector3(4.4,0,-16)
	g.comfort_time=51
	g._save_game()
	var saved=g._session_snapshot()
	g.state.flask=0
	g._load_game()
	assert(g._session_snapshot()==saved,"Mid-encounter save restores clock, exposure and relief")
	assert(g.tunnel_checkpoint==checkpoint)
	assert(g.estate.in_sight(Vector3(0,0,-16)))
	assert(not g.estate.in_sight(Vector3(4.4,0,-16)))
	g.settings.distortion=0
	g.settings.reduced_flicker=true
	g.estate.presentation(1,false)
	var unrest=g.estate.wall_shadow.scale.x
	g.estate.presentation(1,true)
	assert(g.estate.wall_shadow.scale.x<unrest)
	assert(g.estate.reflected_edges.visible)
	# The shorter recess is genuinely traversable, not merely highlighted decoration.
	g._restore_session(checkpoint)
	g._close()
	await g._walk_to(Vector3(4.4,0,4))
	await g._walk_to(Vector3(4.4,0,-24))
	await g._walk_to(Vector3(0,0,-30.2))
	assert(g.page=="play" and g.focused=="tunnel_record")
	var paused_clock=g.estate.clock
	g._journal()
	for i in 20: await g.get_tree().physics_frame
	assert(g.estate.clock==paused_clock,"Reading must not advance the encounter")
	var legacy=g.CaseState.new()
	assert(legacy.restore({"version":2,"evidence":["eight"],"flask":1,"supplement_history":[{"evidence":["eight"],"county":true}]}))
	assert(not legacy.supplement_history[0].has("statements"),"Old saves must not invent missing statement snapshots")
	assert(not legacy.restore({"version":3,"evidence":[42]}))
	var options=g.settings_schema.decode({"distortion":0,"text_scale":1.3,"hints":false})
	assert(options.distortion==0 and options.text_scale==1.3 and options.hints==false)
	assert(g.settings_schema.decode(g.settings_schema.encode(options))==options)
	print("LOOP PASS: Perception route detail; full statement snapshots; county response; death/continue/retry; exact checkpoint and mid-encounter restore; accessible relief")
	g.get_tree().quit()
