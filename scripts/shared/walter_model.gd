extends RefCounted

const MODEL_SCENE: PackedScene = preload("res://assets/models/walter_phase1.glb")
const PLAIN_MODEL_SCENE: PackedScene = preload("res://assets/models/walter_plain.glb")

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
	# Walter establishes the baseline player-character scale (1.30), retaining
	# commanding investigator stature against which other cast models are tuned.
	rendered.scale = Vector3.ONE * 1.30
	wrapper.add_child(rendered)
	var plain_rendered := PLAIN_MODEL_SCENE.instantiate()
	plain_rendered.name = "RenderedPlainWalter"
	plain_rendered.rotation.y = PI
	plain_rendered.scale = Vector3.ONE * 1.30
	wrapper.add_child(plain_rendered)
	set_outfit(wrapper, false, true)
	return wrapper

static func set_outfit(model: Node3D, plain: bool, badge_visible: bool) -> void:
	if not is_instance_valid(model): return
	var police_rendered := model.get_node_or_null("RenderedWalter") as Node3D
	var plain_rendered := model.get_node_or_null("RenderedPlainWalter") as Node3D
	if police_rendered != null:
		police_rendered.visible = not plain
		# The earlier single-asset experiment left a recolored police duplicate in
		# this GLB.  It must never substitute for the independently modeled coat.
		for node in police_rendered.find_children("Police*", "", true, false):
			node.visible = true
		for node in police_rendered.find_children("Plain*", "", true, false):
			node.visible = false
	if plain_rendered != null:
		plain_rendered.visible = plain
	for node in model.find_children("Badge*", "", true, false):
		node.visible = badge_visible
	var marker := model.get_node_or_null("Badge")
	if marker != null: marker.visible = badge_visible

static func animation_player(model: Node3D) -> AnimationPlayer:
	var players := animation_players(model)
	return players[0] as AnimationPlayer if not players.is_empty() else null

static func animation_players(model: Node3D) -> Array[AnimationPlayer]:
	var result: Array[AnimationPlayer] = []
	if not is_instance_valid(model): return result
	for node in model.find_children("*", "AnimationPlayer", true, false):
		result.append(node as AnimationPlayer)
	return result

static func animation_map(player: AnimationPlayer) -> Dictionary:
	var result := {}
	if not is_instance_valid(player): return result
	for imported_name in player.get_animation_list():
		var full_name := String(imported_name)
		var base_name := full_name.get_file()
		if base_name in ["Idle", "Walk", "Brisk", "Interact", "Pickup_Ground", "Surprise", "Examine"]:
			result[base_name] = imported_name
	# Meshy exported the two custom actions under opaque UUIDs. Keep these aliases
	# until the next Blender rebuild writes the semantic action names into the GLB.
	if not result.has("Surprise"):
		var surprise := _find_animation(player, "01a0c2dc-c106-73a8-b359-a699e575b489")
		if surprise != StringName(): result["Surprise"] = surprise
	if not result.has("Examine"):
		var examine := _find_animation(player, "01a0c2de-e825-716d-a1ed-53dcfa00916a")
		if examine != StringName(): result["Examine"] = examine
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
