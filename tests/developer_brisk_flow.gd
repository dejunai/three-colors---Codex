extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.WALK_SPEED < scene.BRISK_SPEED)
	assert(scene.BRISK_SPEED < scene.DEVELOPER_BRISK_SPEED)
	assert(not scene.developer_brisk)
	assert(not scene.developer_brisk_used)
	var toggle = InputEventKey.new()
	toggle.keycode = KEY_F3
	toggle.pressed = true
	scene._unhandled_input(toggle)
	assert(scene.developer_brisk, "F3 must enable the development Shift pace")
	assert(scene.developer_brisk_used, "enabling developer pace must mark it used for this playthrough")
	scene._unhandled_input(toggle)
	assert(not scene.developer_brisk, "F3 must restore the player Shift pace")
	assert(scene.developer_brisk_used, "developer pace usage must remain sticky after it is disabled")
	print("DEVELOPER BRISK PASS: Shift 4.0; F3 toggles 10.5 development pace and usage remains sticky")
	quit(0)
