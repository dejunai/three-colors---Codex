extends CharacterBody3D
class_name PlayerController

signal prompt_changed(text: String)
signal interacted(target: Node, result: Dictionary)

@export var walk_speed := 4.0
@export var interaction_range := 2.65

var active := true
var view_camera: Camera3D
var focused
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _physics_process(delta: float) -> void:
	if not active:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta * 6.0)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * delta * 6.0)
		move_and_slide()
		_update_focus(null)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var movement := Vector3.ZERO
	if view_camera != null:
		var right := view_camera.global_transform.basis.x
		var forward := -view_camera.global_transform.basis.z
		right.y = 0.0
		forward.y = 0.0
		right = right.normalized()
		forward = forward.normalized()
		movement = (right * input_vector.x + forward * -input_vector.y).normalized()
	else:
		movement = Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	velocity.x = movement.x * walk_speed
	velocity.z = movement.z * walk_speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
	move_and_slide()

	if movement.length_squared() > 0.05:
		var target_rotation := atan2(movement.x, movement.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 9.0)

	_find_interaction_focus()
	if Input.is_action_just_pressed("interact") and focused != null:
		var result: Dictionary = focused.interact()
		interacted.emit(focused, result)

func set_camera(camera_node: Camera3D) -> void:
	view_camera = camera_node

func teleport(destination: Vector3) -> void:
	global_position = destination
	velocity = Vector3.ZERO

func _find_interaction_focus() -> void:
	var best = null
	var best_score := INF
	for candidate_node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate_node):
			continue
		var candidate = candidate_node
		if candidate.disabled or not candidate.is_visible_in_tree():
			continue
		var offset: Vector3 = candidate.global_position - global_position
		var distance: float = offset.length()
		if distance > interaction_range:
			continue
		var facing := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
		var direction := Vector3(offset.x, 0.0, offset.z).normalized()
		var facing_penalty := 0.0
		if direction.length_squared() > 0.0:
			facing_penalty = maxf(0.0, 1.0 - facing.dot(direction)) * 0.55
		var score: float = distance + facing_penalty
		if score < best_score:
			best_score = score
			best = candidate
	_update_focus(best)

func _update_focus(candidate) -> void:
	if focused == candidate:
		return
	focused = candidate
	prompt_changed.emit("" if focused == null else focused.interaction_text())
