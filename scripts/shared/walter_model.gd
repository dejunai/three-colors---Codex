extends RefCounted

const MODEL_SCENE: PackedScene = preload("res://assets/models/walter_phase1.glb")

static func create() -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "Walter"
	var compatibility_coat := Node3D.new()
	compatibility_coat.name = "Coat"
	wrapper.add_child(compatibility_coat)
	var compatibility_badge := Node3D.new()
	compatibility_badge.name = "Badge"
	wrapper.add_child(compatibility_badge)
	var rendered := MODEL_SCENE.instantiate()
	rendered.name = "RenderedWalter"
	# Blender's authored face points +Z; the existing controller's forward is -Z.
	rendered.rotation.y = PI
	# The imported rest mesh is 1.70m tall; 1.33 puts Walter at about 2.26m
	# including his cap, retaining his stature without the 1.38 pass's excess.
	rendered.scale = Vector3.ONE * 1.33
	wrapper.add_child(rendered)
	return wrapper

static func set_outfit(model: Node3D, plain: bool, badge_visible: bool) -> void:
	if not is_instance_valid(model): return
	for node in model.find_children("Police*", "", true, false):
		node.visible = not plain
	for node in model.find_children("Plain*", "", true, false):
		node.visible = plain
	for node in model.find_children("Badge*", "", true, false):
		node.visible = badge_visible
	var marker := model.get_node_or_null("Badge")
	if marker != null: marker.visible = badge_visible

static func animation_player(model: Node3D) -> AnimationPlayer:
	if not is_instance_valid(model): return null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null

static func animation_map(player: AnimationPlayer) -> Dictionary:
	var result := {}
	if not is_instance_valid(player): return result
	for imported_name in player.get_animation_list():
		var full_name := String(imported_name)
		var base_name := full_name.get_file()
		if base_name in ["Idle", "Walk", "Brisk", "Interact", "Pickup_Ground"]:
			result[base_name] = imported_name
	# The generated Walk alias is a copy of Quick_Walk. Its narrow crossover
	# stride reads like a catwalk on Walter; the separate Walking take keeps
	# his hips square and gives the ordinary pace more weight.
	var walking := _find_animation(player, "Walking")
	if walking != StringName():
		result["Walk"] = walking
	return result

static func _find_animation(player: AnimationPlayer, base_name: String) -> StringName:
	for imported_name in player.get_animation_list():
		if String(imported_name).get_file() == base_name:
			return imported_name
	return StringName()
