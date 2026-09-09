extends RefCounted

func settle(g:Node) -> void:
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame

func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()

func press(g:Node,text:String) -> void:
	for b in g.content.find_children("*","Button",true,false):
		if b.text==text: b.pressed.emit(); return
	assert(false,"Missing control: "+text)

func run(g:Node) -> void:
	await settle(g)
	g.state=g.CaseState.new()
	g.state.started=true
	g._travel("estate",Vector3(0,0.1,35))
	await settle(g)
	g._find_focus()
	assert(g.focused=="exit","Unfinished paperwork must not hide the exit prompt")
	for leaf in g.estate.departure_leaves: assert(is_zero_approx(leaf.rotation.y))
	g._interact("exit")
	assert(g.page=="dialogue" and g.dialogue.cards[0][1].contains("paperwork"))
	cards(g)
	assert(g.state.world=="estate" and not g.state.estate_complete)
	g._interact("odell")
	cards(g)
	g._write_report("Observations filed","report_routine")
	cards(g)
	for leaf in g.estate.departure_leaves: assert(is_equal_approx(absf(leaf.rotation.y),PI/2))
	g._save_game()
	g._load_game()
	for leaf in g.estate.departure_leaves: assert(is_equal_approx(absf(leaf.rotation.y),PI/2))
	g.yaw=0
	await g._walk_to(Vector3(0,0,39))
	assert(g.focused=="exit")
	g._interact("exit")
	cards(g)
	assert(g.state.world=="town")
	g.state.discover("naomi")
	for spec in [["boardinghouse","lodging",Vector3(6.3,0,2)],["room","exemption",Vector3(6.8,0,3.5)]]:
		g._travel(spec[0],Vector3(0,0.1,6))
		for offset in [Vector3(0,0,1.3),Vector3(0,0,-1.3),Vector3(-2,0,0),Vector3(1.85,0,0)]:
			g.player.position=spec[2]+offset+Vector3(0,0.1,0)
			await settle(g)
			g._find_focus()
			assert(g.focused==spec[1],"All four sides must reach "+spec[1]+": "+str(offset))
			g._interact(g.focused)
			cards(g)
			assert(g.state.evidence.has(spec[1]))
		# An unrelated obstruction still blocks the ray; support exceptions are narrow.
		g.player.position=spec[2]+Vector3(0,0.1,1.3)
		var wall=g.estate.box(g.estate,spec[2]+Vector3(0,1.5,0.85),Vector3(2,3,0.12),"222222",true)
		await settle(g)
		g._find_focus()
		assert(g.focused!=spec[1],"Do not examine through other obstacles")
		wall.queue_free()
	g._board()
	await settle(g)
	var buttons=g.content.find_children("*","Button",true,false)
	assert(buttons[0].text=="Link" and not buttons[0].disabled)
	assert(buttons[0].get_global_rect().position.y<400,"Link is visible at the top, before scrolling")
	press(g,"Link")
	press(g,"NAOMI FREEMAN")
	for b in g.content.find_children("*","Button",true,false): assert(b.text!="NAOMI FREEMAN")
	press(g,"A LOCAL ADDRESS")
	assert(g.state.has_link("naomi_address"))
	print("USABILITY PASS: blocked-exit feedback; open gate and saved state; walkable departure; ledger and notice four-sided access; walls still occlude; top-level Link uses existing picker")
	g.get_tree().quit()
