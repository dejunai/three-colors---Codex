extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state.started = true
	g._panel("case", "Guard test")
	var before_pitch = scene.pitch
	var before_yaw = scene.yaw
	g._close()
	for relative in [Vector2(800, -900), Vector2(-500, 700)]:
		assert(not scene._apply_mouse_look(relative))
	assert(is_equal_approx(scene.pitch, before_pitch) and is_equal_approx(scene.yaw, before_yaw),
		"Every motion sample in the post-menu recapture burst must be ignored")
	scene._motion_guard_until = -1.0
	assert(scene._apply_mouse_look(Vector2(4, 3)))
	assert(not is_equal_approx(scene.pitch, before_pitch) and not is_equal_approx(scene.yaw, before_yaw),
		"Mouse look must resume after the short recapture guard")
	print("CAMERA RECAPTURE PASS: menu close arms immediately; multiple relock samples suppressed; ordinary mouse look resumes")
	quit(0)
