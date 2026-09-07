extends CharacterBody3D
class_name TunnelHazard

signal player_caught

var player: CharacterBody3D
var patrol_start := Vector3.ZERO
var patrol_end := Vector3.ZERO
var patrol_target := Vector3.ZERO
var walk_speed := 0.72
var detection_range := 5.6
var awake := true
var pulse_time := 0.0
var model_root: Node3D

func configure(target_player: CharacterBody3D, first_point: Vector3, second_point: Vector3) -> void:
	player = target_player
	patrol_start = first_point
	patrol_end = second_point
	patrol_target = second_point

func _physics_process(delta: float) -> void:
	if not awake or player == null:
		return
	pulse_time += delta
	var direction := patrol_target - global_position
	direction.y = 0.0
	if direction.length() < 0.35:
		patrol_target = patrol_start if patrol_target == patrol_end else patrol_end
		direction = patrol_target - global_position
	direction = direction.normalized()
	velocity = direction * walk_speed
	velocity.y = -0.5
	move_and_slide()
	if direction.length_squared() > 0.0:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 4.0)
	if model_root != null:
		var breathing := 1.0 + sin(pulse_time * 2.4) * 0.035
		model_root.scale = Vector3(1.0 / breathing, breathing, 1.0 / breathing)
	_check_for_player()

func _check_for_player() -> void:
	var origin := global_position + Vector3.UP * 1.1
	var target := player.global_position + Vector3.UP * 0.8
	var offset := target - origin
	if offset.length() > detection_range:
		return
	var forward := Vector3(sin(rotation.y), 0.0, cos(rotation.y)).normalized()
	var flat_direction := Vector3(offset.x, 0.0, offset.z).normalized()
	if forward.dot(flat_direction) < 0.18:
		return
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.get("collider") == player:
		awake = false
		player_caught.emit()

func reset_hazard() -> void:
	global_position = patrol_start
	patrol_target = patrol_end
	velocity = Vector3.ZERO
	awake = true
