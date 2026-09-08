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
# Guarantees a keydown/keyup pair resolves as movement even if it completes within one physics frame (synthetic/automated input).
const MOVE_LATCH_MIN = 0.15
var move_latch_timer = {"walk_forward":0.0,"walk_back":0.0,"walk_left":0.0,"walk_right":0.0}
# Click-to-move waypoint: accessibility/automation fallback for players who can't sustain a held key.
var move_target = null

func _ready() -> void:
	_setup_inputs()
	chapter=get_node(chapter_path)
	chapter.start(self)

func _setup_inputs() -> void:
	var keys = {"walk_forward":[KEY_W,KEY_UP],"walk_back":[KEY_S,KEY_DOWN],"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"use":[KEY_E,KEY_F],"case":[KEY_TAB,KEY_I],"journal":[KEY_J],"pause_game":[KEY_ESCAPE],"brisk":[KEY_SHIFT],"camera_left":[KEY_Q],"camera_right":[KEY_R]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var e = InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event(action,e)

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
	if camera.global_position.distance_to(pivot) > 0.01: camera.look_at(pivot)

func _physics_process(delta:float) -> void:
	if not is_instance_valid(chapter) or chapter.page != "play":
		move_target = null
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
	var speed = 3.5 if Input.is_action_pressed("brisk") else 2.15
	player.velocity.x = move_toward(player.velocity.x,movement.x*speed,delta*13)
	player.velocity.z = move_toward(player.velocity.z,movement.z*speed,delta*13)
	if not player.is_on_floor(): player.velocity.y -= 18*delta
	else: player.velocity.y = -0.2
	player.move_and_slide()
	player.position.x = clampf(player.position.x,movement_bounds.position.x,movement_bounds.end.x)
	player.position.z = clampf(player.position.z,movement_bounds.position.y,movement_bounds.end.y)
	if player.position.y < -3: player.position = Vector3(0,0.1,30)
	if movement.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-movement.x,-movement.z),delta*10)
		animation_time += delta*speed*3
	var swing = sin(animation_time)*0.34*movement.length()
	model.get_node("LeftLeg").rotation.x = swing
	model.get_node("RightLeg").rotation.x = -swing
	model.get_node("LeftArm").rotation.x = -swing*0.8
	model.get_node("RightArm").rotation.x = swing*0.8
	var orbit = Input.get_axis("camera_left","camera_right")
	yaw -= orbit*delta*1.5
	_update_camera(delta)
	chapter.tick_world(delta)

func _dir_pressed(action:String) -> bool:
	return Input.is_action_pressed(action) or move_latch_timer[action] > 0.0

func _unhandled_input(event:InputEvent) -> void:
	for action in move_latch_timer.keys():
		if event.is_action_pressed(action): move_latch_timer[action] = MOVE_LATCH_MIN
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if chapter.page == "play":
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			yaw -= event.relative.x*float(chapter.settings.sensitivity)
			pitch = clampf(pitch+event.relative.y*float(chapter.settings.sensitivity)*(-1 if chapter.settings.invert_y else 1),0.08,1.05)
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
