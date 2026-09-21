extends Node3D

@export var chapter_path: NodePath = ^"ChapterOne"
var chapter: Node3D
var player: CharacterBody3D
var model: Node3D
var camera: Camera3D
var yaw = 0.0
var pitch = 0.38
var distance = 6.3
var animation_time = 0.0
var movement_bounds = Rect2(-31,-18.4,62,60.4)
var fall_reset_y = -3.0
const WALK_SPEED = 2.15
const BRISK_SPEED = 4.0
const DEVELOPER_BRISK_SPEED = 10.5
const WALK_ACCEL = 13.0
const BRISK_ACCEL = 18.0
const DEVELOPER_BRISK_ACCEL = 39.0
var developer_brisk = false
var _model_left_leg: Node3D
var _model_right_leg: Node3D
var _model_left_arm: Node3D
var _model_right_arm: Node3D
var _model_animation: AnimationPlayer
var _model_animations: Dictionary = {}
var _model_animation_base := ""
var _animation_lock := false
# Guarantees a keydown/keyup pair resolves as movement even if it completes within one physics frame (synthetic/automated input).
const MOVE_LATCH_MIN = 0.15
var move_latch_timer = {"walk_forward":0.0,"walk_back":0.0,"walk_left":0.0,"walk_right":0.0}
# Click-to-move waypoint: accessibility/automation fallback for players who can't sustain a held key.
var move_target = null
# Fix + diagnostics for the intermittent "camera pivots straight up" report: tracks
# when mouse capture last re-engaged (leaving a menu), because browsers can report
# the entire pointer movement that happened while the mouse was free — including
# however far it drifted off the game canvas — as one inflated relative delta on the
# very first motion event after pointer lock re-acquires. That single event was
# large enough to slam pitch straight into its clamp. Browsers may emit more than
# one synthetic sample, and the first sample can arrive before the next physics
# frame notices the mouse-mode change. Arm a short guard at the capture call itself;
# every motion sample in that window is discarded.
const RECAPTURE_MOTION_GUARD_SECONDS = 0.12
var _prev_mouse_mode = Input.MOUSE_MODE_VISIBLE
var _recapture_time = -1000.0
var _motion_guard_until = -1000.0

func _ready() -> void:
	_setup_inputs()
	chapter = get_node_or_null(chapter_path)
	assert(chapter != null, "Chapter node not found at %s" % chapter_path)
	chapter.start(self)

func _setup_inputs() -> void:
	var keys = {"walk_forward":[KEY_W,KEY_UP],"walk_back":[KEY_S,KEY_DOWN],"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"use":[KEY_E,KEY_F],"case":[KEY_TAB,KEY_I],"journal":[KEY_J],"pause_game":[KEY_ESCAPE,KEY_F1],"brisk":[KEY_SHIFT],"camera_left":[KEY_Q],"camera_right":[KEY_R]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var e = InputEventKey.new()
			e.physical_keycode = key
			if not InputMap.action_has_event(action, e):
				InputMap.action_add_event(action, e)

func build_player(avatar:Node3D,spawn:Vector3) -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.3
	add_child(player)
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.85
	capsule.radius = 0.3
	var collision = CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.95
	player.add_child(collision)
	model = avatar
	model.reparent(player,false)
	model.position = Vector3.ZERO
	_model_left_leg = model.get_node_or_null("LeftLeg")
	_model_right_leg = model.get_node_or_null("RightLeg")
	_model_left_arm = model.get_node_or_null("LeftArm")
	_model_right_arm = model.get_node_or_null("RightArm")
	_model_animation = preload("res://scripts/shared/walter_model.gd").animation_player(model)
	_model_animations = preload("res://scripts/shared/walter_model.gd").animation_map(_model_animation)
	if is_instance_valid(_model_animation):
		for loop_name in ["Idle", "Walk", "Brisk"]:
			if not _model_animations.has(loop_name): continue
			var clip := _model_animation.get_animation(_model_animations[loop_name])
			if clip != null: clip.loop_mode = Animation.LOOP_LINEAR
		_play_model_animation("Idle", 0.0)
	player.position = spawn
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.fov = 53
	camera.near = 0.1
	camera.far = 180
	camera.current = true
	add_child(camera)
	_update_camera(1.0)

func _update_camera(delta:float) -> void:
	var pivot = player.global_position+Vector3(0,1.45,0)
	var offset = Vector3(0,sin(pitch)*distance,cos(pitch)*distance).rotated(Vector3.UP,yaw)
	var desired = pivot+offset
	if is_inside_tree():
		var query = PhysicsRayQueryParameters3D.create(pivot,desired,1)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty(): desired = hit.position+hit.normal*0.3
	camera.global_position = camera.global_position.lerp(desired,minf(1,delta*12))
	# Keep skyward and collision-shortened views clear of the avatar.
	if is_instance_valid(model): model.visible = pitch > -0.55 and camera.global_position.distance_to(pivot) > 1.5
	if camera.global_position.distance_to(pivot) > 0.01: camera.look_at(pivot)

func _notification(what: int) -> void:
	# Losing window/tab focus while a movement key is held (alt-tab, a browser dialog,
	# clicking off the canvas) can drop the browser's keyup event entirely, leaving
	# Godot's internal action state stuck "pressed" forever — the reported "W won't
	# release" bug. Force every held directional/camera/sprint action to a clean
	# released state on focus loss so a dropped keyup can never latch a direction on
	# indefinitely.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for action in ["walk_forward","walk_back","walk_left","walk_right","brisk","camera_left","camera_right","use","case","journal"]:
			if InputMap.has_action(action):
				Input.action_release(action)
		for action in move_latch_timer.keys():
			move_latch_timer[action] = 0.0

func _physics_process(delta:float) -> void:
	if not is_instance_valid(chapter) or chapter.page != "play":
		move_target = null
		# Guards against Input.mouse_mode drifting out of sync with an open panel/menu —
		# a browser can silently release pointer lock (e.g. on Escape, or a focus change)
		# without the engine's captured/visible state noticing. Re-asserting VISIBLE every
		# frame while a menu is open is a no-op when already correct, and prevents the
		# cursor from ever being invisible/unresponsive while a panel is up.
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if Input.mouse_mode != _prev_mouse_mode:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_arm_mouse_motion_guard()
		_prev_mouse_mode = Input.mouse_mode
	if _animation_lock:
		player.velocity.x = move_toward(player.velocity.x,0.0,delta*WALK_ACCEL)
		player.velocity.z = move_toward(player.velocity.z,0.0,delta*WALK_ACCEL)
		if not player.is_on_floor(): player.velocity.y -= 18*delta
		else: player.velocity.y = -0.2
		player.move_and_slide()
		_update_camera(delta)
		chapter.tick_world(delta)
		return
	for action in move_latch_timer.keys(): move_latch_timer[action] = maxf(0.0,move_latch_timer[action]-delta)
	var axis = Vector2(
		(1.0 if _dir_pressed("walk_right") else 0.0)-(1.0 if _dir_pressed("walk_left") else 0.0),
		(1.0 if _dir_pressed("walk_back") else 0.0)-(1.0 if _dir_pressed("walk_forward") else 0.0)
	)
	if axis.length() > 1.0: axis = axis.normalized()
	var movement:Vector3
	if axis.length() > 0.05:
		move_target = null
		movement = Vector3(axis.x,0,axis.y).rotated(Vector3.UP,yaw)
	elif move_target != null:
		var to_target:Vector3 = move_target-player.global_position
		to_target.y = 0
		if to_target.length() < 0.35:
			move_target = null
			movement = Vector3.ZERO
		else:
			movement = to_target.normalized()
	else:
		movement = Vector3.ZERO
	var brisk = Input.is_action_pressed("brisk")
	var speed = (DEVELOPER_BRISK_SPEED if developer_brisk else BRISK_SPEED) if brisk else WALK_SPEED
	var accel = (DEVELOPER_BRISK_ACCEL if developer_brisk else BRISK_ACCEL) if brisk else WALK_ACCEL
	player.velocity.x = move_toward(player.velocity.x,movement.x*speed,delta*accel)
	player.velocity.z = move_toward(player.velocity.z,movement.z*speed,delta*accel)
	if not player.is_on_floor(): player.velocity.y -= 18*delta
	else: player.velocity.y = -0.2
	player.move_and_slide()
	player.position.x = clampf(player.position.x,movement_bounds.position.x,movement_bounds.end.x)
	player.position.z = clampf(player.position.z,movement_bounds.position.y,movement_bounds.end.y)
	if player.position.y < fall_reset_y: player.position = Vector3(0,0.1,30)
	if movement.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-movement.x,-movement.z),delta*10)
		animation_time += delta*speed*3
	if is_instance_valid(_model_animation):
		_play_model_animation(("Brisk" if brisk else "Walk") if movement.length() > 0.1 else "Idle", 0.16, 1.0)
	else:
		var swing = sin(animation_time)*0.34*movement.length()
		if _model_left_leg != null: _model_left_leg.rotation.x = swing
		if _model_right_leg != null: _model_right_leg.rotation.x = -swing
		if _model_left_arm != null: _model_left_arm.rotation.x = -swing*0.8
		if _model_right_arm != null: _model_right_arm.rotation.x = swing*0.8
	var orbit = Input.get_axis("camera_left","camera_right")
	yaw -= orbit*delta*1.5
	_update_camera(delta)
	chapter.tick_world(delta)

func _dir_pressed(action:String) -> bool:
	return Input.is_action_pressed(action) or move_latch_timer[action] > 0.0

func capture_mouse() -> void:
	# Called by menu-close paths so the guard exists before pointer-lock can emit
	# its first synthetic motion event. The physics fallback above still covers a
	# browser or OS changing capture mode independently.
	_arm_mouse_motion_guard()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_prev_mouse_mode = Input.MOUSE_MODE_CAPTURED

func _arm_mouse_motion_guard() -> void:
	_recapture_time = Time.get_ticks_msec()/1000.0
	_motion_guard_until = _recapture_time + RECAPTURE_MOTION_GUARD_SECONDS

func _mouse_motion_is_guarded() -> bool:
	return Time.get_ticks_msec()/1000.0 <= _motion_guard_until

func _apply_mouse_look(relative: Vector2) -> bool:
	if _mouse_motion_is_guarded():
		print("[camera-pivot-diagnostic] suppressed post-recapture motion event, relative=",relative)
		return false
	var sensitivity = float(chapter.settings.sensitivity)
	var raw_pitch_delta = relative.y*sensitivity*(-1 if chapter.settings.invert_y else 1)
	var new_pitch = clampf(pitch+raw_pitch_delta,-1.3,1.05)
	# Retained in case a spike still shows up outside the recapture window —
	# that would mean pointer-lock timing isn't the whole story.
	if absf(relative.y) > 40.0 or (new_pitch >= 1.04 and pitch < 1.0) or (new_pitch <= -1.29 and pitch > -1.2):
		var since_recapture = Time.get_ticks_msec()/1000.0 - _recapture_time
		print("[camera-pivot-diagnostic] relative=",relative," sensitivity=",sensitivity," pitch ",pitch,"->",new_pitch," seconds_since_recapture=",since_recapture)
	yaw -= relative.x*sensitivity
	pitch = new_pitch
	return true

func _unhandled_input(event:InputEvent) -> void:
	if _animation_lock: return
	for action in move_latch_timer.keys():
		if event.is_action_pressed(action): move_latch_timer[action] = MOVE_LATCH_MIN
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F3 or event.physical_keycode == KEY_F3):
		developer_brisk = not developer_brisk
		print("[movement] Shift pace: ", "DEVELOPER (10.5)" if developer_brisk else "PLAYER BRISK (4.0)")
	if chapter.page == "play":
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_apply_mouse_look(event.relative)
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(3.2,distance-0.5)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(9,distance+0.5)
			# Click-to-move: not gated on pointer-lock, so it works whether or not mouse capture is available (accessibility/automation fallback).
			if event.button_index == MOUSE_BUTTON_LEFT:
				var from = camera.project_ray_origin(event.position)
				var to = from+camera.project_ray_normal(event.position)*100
				var query = PhysicsRayQueryParameters3D.create(from,to,1)
				var hit = get_world_3d().direct_space_state.intersect_ray(query)
				if not hit.is_empty():
					move_target = Vector3(
						clampf(hit.position.x,movement_bounds.position.x,movement_bounds.end.x),
						hit.position.y,
						clampf(hit.position.z,movement_bounds.position.y,movement_bounds.end.y)
					)
	chapter.handle_input(event)

func _play_model_animation(base_name: String, blend: float = 0.16, speed: float = 1.0) -> void:
	if not is_instance_valid(_model_animation) or not _model_animations.has(base_name): return
	_model_animation.speed_scale = speed
	if _model_animation_base == base_name and _model_animation.is_playing(): return
	_model_animation_base = base_name
	_model_animation.play(_model_animations[base_name], blend, speed)

func play_ground_pickup(target_position: Vector3, on_reach: Callable, on_complete: Callable) -> void:
	_play_ground_pickup(target_position, on_reach, on_complete)

func _play_ground_pickup(target_position: Vector3, on_reach: Callable, on_complete: Callable) -> void:
	if _animation_lock: return
	var direction := target_position - player.global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		model.rotation.y = atan2(-direction.x,-direction.z)
	if not is_instance_valid(_model_animation) or not _model_animations.has("Pickup_Ground"):
		if on_reach.is_valid(): on_reach.call()
		if on_complete.is_valid(): on_complete.call()
		return
	_animation_lock = true
	_play_model_animation("Pickup_Ground", 0.12)
	var clip := _model_animation.get_animation(_model_animations["Pickup_Ground"])
	var duration := clip.length if clip != null else 1.8
	await get_tree().create_timer(maxf(0.2,duration*0.46)).timeout
	if on_reach.is_valid(): on_reach.call()
	await get_tree().create_timer(maxf(0.2,duration*0.54)).timeout
	_animation_lock = false
	_play_model_animation("Idle", 0.12)
	if on_complete.is_valid(): on_complete.call()
