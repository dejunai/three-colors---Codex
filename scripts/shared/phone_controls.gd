extends CanvasLayer

# Short-lived phone experiment. Uses existing interaction checks and movement.
var rig: Node3D
var bar: Control
var use_button: Button
var held: Array[String] = []
var touch_index = -1
var touch_start = Vector2.ZERO
var dragged = false
var pending = ""
var pending_world = ""

func setup(owner_rig: Node3D) -> void:
	rig = owner_rig
	layer = 40
	bar = Control.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var left = VBoxContainer.new()
	left.position = Vector2(12, 310)
	bar.add_child(left)
	_hold(left, "▲", "walk_forward")
	var row = HBoxContainer.new()
	left.add_child(row)
	_hold(row, "◀", "walk_left")
	_hold(row, "▼", "walk_back")
	_hold(row, "▶", "walk_right")
	var top = HBoxContainer.new()
	top.position = Vector2(12, 8)
	bar.add_child(top)
	_button(top, "Case file", func(): rig.chapter._journal())
	_button(top, "Effects", func(): rig.chapter._case_file())
	_button(top, "Pause", func(): rig.chapter._pause())
	var right = VBoxContainer.new()
	right.position = Vector2(730, 310)
	bar.add_child(right)
	var turns = HBoxContainer.new()
	right.add_child(turns)
	_hold(turns, "Look ‹", "camera_left")
	_hold(turns, "Look ›", "camera_right")
	use_button = _button(right, "Interact", func():
		if not rig.chapter.focused.is_empty():
			pending = ""
			rig.chapter._interact(rig.chapter.focused))

func _button(parent: Node, title: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(72, 62)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _hold(parent: Node, title: String, action: String) -> void:
	var b = _button(parent, title, func(): pass)
	b.button_down.connect(func():
		pending = ""
		rig.move_target = null
		if not held.has(action): held.append(action)
		Input.action_press(action))
	b.button_up.connect(func():
		held.erase(action)
		Input.action_release(action))

func _process(_delta: float) -> void:
	var playing = rig.chapter.page == "play"
	bar.visible = playing
	if not playing:
		for action in held: Input.action_release(action)
		held.clear()
		pending = ""
		touch_index = -1
		return
	use_button.disabled = rig.chapter.focused.is_empty()
	if not pending.is_empty():
		if rig.chapter.state.world != pending_world or not rig.chapter.estate.points.has(pending):
			pending = ""
		elif rig.chapter.focused == pending:
			var target = pending
			pending = ""
			rig.move_target = null
			rig.player.velocity = Vector3.ZERO
			rig.chapter._interact(target)

func _unhandled_input(event: InputEvent) -> void:
	if rig.chapter.page != "play": return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			touch_start = event.position
			dragged = false
		elif not event.pressed and event.index == touch_index:
			if not dragged: tap(event.position)
			touch_index = -1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		if event.position.distance_to(touch_start) > 12: dragged = true
		if dragged:
			rig.yaw -= event.relative.x * 0.006
			rig.pitch = clampf(rig.pitch + event.relative.y * 0.006, 0.15, 1.05)
		get_viewport().set_input_as_handled()

func tap(screen: Vector2) -> void:
	pending = ""
	var best = 52.0
	for id in rig.chapter.estate.points:
		if id == "report" and not rig.chapter.state.visited.has("odell"): continue
		var point: Vector3 = rig.chapter.estate.points[id].pos + Vector3.UP
		if rig.camera.is_position_behind(point): continue
		var pixels = rig.camera.unproject_position(point).distance_to(screen)
		if pixels < best:
			var query = PhysicsRayQueryParameters3D.create(rig.camera.global_position, point, 1, rig.chapter.estate.points[id].get("excluded", []))
			if not rig.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
			best = pixels
			pending = id
	if not pending.is_empty():
		pending_world = rig.chapter.state.world
		rig.move_target = rig.chapter.estate.points[pending].pos
		rig.chapter._toast(str(rig.chapter.estate.points[pending].title), 2)
		return
	var origin = rig.camera.project_ray_origin(screen)
	var hit = rig.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + rig.camera.project_ray_normal(screen) * 100, 1))
	if not hit.is_empty(): rig.move_target = hit.position
