extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	g.state=g.CaseState.new()
	for id in ["eight","intake","naomi","lodging","watch","wounds"]: g.state.discover(id)
	g.archive._try_link(g,"eight","intake")
	g.archive._try_link(g,"naomi","lodging")
	var before=g.state.pack().duplicate(true)
	g._board()
	await create_timer(0.5).timeout
	assert(g.state.pack()==before,"Opening the board changed investigation state")
	var board: Control
	for child in g.content.get_children():
		if child.get_script()==load("res://scripts/shared/case_board.gd"): board=child
	assert(board!=null and board.connections.size()==2)
	for card in board.cards.values(): assert(card.position.x>=0 and card.position.x+card.size.x<=board.size.x+1)
	g.archive._link_picker(g,"eight")
	for button in g.content.find_children("*","Button",true,false):
		assert(button.text!=str(g.facts.eight[0]),"Picker offers self-link")
	g._board()
	await create_timer(0.2).timeout
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://color-board.png")
	g._notebook()
	await create_timer(0.5).timeout
	assert(g.state.pack()==before,"Opening the notebook changed investigation state")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://color-notebook.png")
	root.content_scale_size=Vector2i(960,640)
	root.size=Vector2i(960,640)
	g.settings.text_scale=1.3
	g._board()
	await create_timer(0.3).timeout
	for child in g.content.get_children():
		if child.get_script()==load("res://scripts/shared/case_board.gd"):
			for card in child.cards.values():
				assert(card.position.x>=0 and card.position.x+card.size.x<=child.size.x+1)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://color-board-small.png")
	assert(g.state.pack()==before)
	print("COLOR CASE PASS")
	quit()
