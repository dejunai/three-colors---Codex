extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.phone_controls != null)
	game.chapter._new_game()
	await process_frame
	await process_frame
	# Opening may present cards first; close for control-level smoke checks.
	game.chapter._close()
	await physics_frame
	assert(game.phone_controls.bar.visible)
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var before = game.player.position
	Input.action_press("walk_forward")
	await create_timer(0.5).timeout
	Input.action_release("walk_forward")
	assert(game.player.position.distance_to(before) > 0.1)
	game.chapter._pause()
	await process_frame
	await process_frame
	assert(not game.phone_controls.bar.visible)
	assert(game.chapter.interface.modal != null)
	game.chapter._close()
	await process_frame
	await process_frame
	assert(game.phone_controls.bar.visible)
	print("PHONE PASS: boot, touch overlay, movement, pause, return, visible pointer")
	quit()
