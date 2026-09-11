extends SceneTree
func _initialize() -> void: call_deferred("run")
func click(button:Button) -> void:
	var at=button.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new()
	motion.position=at
	root.push_input(motion)
	for down in [true,false]:
		var event=InputEventMouseButton.new()
		event.position=at
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		root.push_input(event)
	await process_frame
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	for mode in ["mouse","keyboard"]:
		g._title()
		await create_timer(0.2).timeout
		for button in g.prologue.root.find_children("*","Button",true,false):
			if button.text=="Begin at the estate":
				await click(button)
				break
		for i in range(g.Story.INTROS.size()):
			await create_timer(0.2).timeout
			assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Prologue captured mouse")
			var buttons=g.prologue.root.find_children("*","Button",true,false)
			assert(buttons.size()==1 and buttons[0].text=="Continue")
			assert(root.gui_get_focus_owner()==buttons[0],"Continue did not receive keyboard focus")
			if mode=="mouse":await click(buttons[0])
			else:
				for down in [true,false]:
					var event=InputEventKey.new()
					event.keycode=KEY_ENTER
					event.pressed=down
					root.push_input(event)
				await process_frame
		assert(g.state.started and g.page=="play")
		assert(not g.prologue.root.visible)
		assert(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	print("PROLOGUE INPUT PASS: fresh launch and replay, mouse and Enter, all slides, gameplay restored")
	quit()
