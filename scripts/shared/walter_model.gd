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
	# Scale Walter to match the game's NPC height (~2.22m with cap in idle / ~1.92m eye level)
	rendered.scale = Vector3.ONE * 1.38
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
	return result
