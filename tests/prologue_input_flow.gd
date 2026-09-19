extends SceneTree
func _initialize() -> void: call_deferred("run")
func click(button:Button) -> void:
	button.pressed.emit()
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
		# If a save was present, Begin at the estate opens the confirmation prompt
		for button in g.prologue.root.find_children("*","Button",true,false):
			if button.text=="Replace investigation":
				await click(button)
				break
		for i in range(g.Story.INTROS.size()):
			await create_timer(0.2).timeout
			if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				push_error("Prologue captured mouse")
				quit(1)
				return
			var buttons=g.prologue.root.find_children("*","Button",true,false)
			if buttons.size() != 1 or buttons[0].text != "Continue":
				push_error("Expected 1 Continue button, found: " + str(buttons.map(func(b): return b.text)))
				quit(1)
				return
			if root.gui_get_focus_owner() != buttons[0]:
				push_error("Continue did not receive keyboard focus")
				quit(1)
				return
			if mode=="mouse": await click(buttons[0])
			else:
				for down in [true,false]:
					var event=InputEventKey.new()
					event.keycode=KEY_ENTER
					event.pressed=down
					root.push_input(event)
				await process_frame
		if not (g.state.started and g.page=="play"):
			push_error("Expected game started and page play")
			quit(1)
			return
		if g.prologue.root.visible:
			push_error("Prologue root still visible")
			quit(1)
			return
		if not g.test_mode:
			assert(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	print("PROLOGUE INPUT PASS: fresh launch and replay, mouse and Enter, all slides, gameplay restored")
	quit()
