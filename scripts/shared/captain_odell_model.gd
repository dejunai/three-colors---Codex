extends RefCounted

const MODEL_SCENE: PackedScene = preload("res://assets/models/captain_odell.glb")
# The source stands about 1.80m in its idle pose. This keeps Odell imposing but
# visibly below Walter's deliberately heightened 1.33-scale silhouette.
const SCALE_FACTOR: float = 1.18

static func create() -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "CaptainOdell"
	var rendered := MODEL_SCENE.instantiate()
	rendered.name = "RenderedOdell"
	rendered.scale = Vector3.ONE * SCALE_FACTOR
	# Meshy authors the face toward +Z; Godot character forward is -Z.
	rendered.rotation.y = PI
	wrapper.add_child(rendered)
	var player := animation_player(wrapper)
	if is_instance_valid(player):
		var clips := animation_map(player)
		for animation_name in ["Idle", "Idle_Alt", "Confer"]:
			if clips.has(animation_name):
				var clip: Animation = player.get_animation(clips[animation_name])
				if clip != null: clip.loop_mode = Animation.LOOP_LINEAR
		if clips.has("Idle"): player.play(clips["Idle"])
	return wrapper

static func animation_player(model: Node3D) -> AnimationPlayer:
	if not is_instance_valid(model): return null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null

static func animation_map(player: AnimationPlayer) -> Dictionary:
	var result := {}
	if not is_instance_valid(player): return result
	for imported_name in player.get_animation_list():
		var base_name := String(imported_name).get_file()
		if base_name in ["Idle", "Idle_Alt", "Confer"]:
			result[base_name] = imported_name
	return result

static func set_conversing(model: Node3D, conversing: bool) -> void:
	var player := animation_player(model)
	if not is_instance_valid(player): return
	var clips := animation_map(player)
	var target := "Confer" if conversing else "Idle"
	if clips.has(target): player.play(clips[target], 0.3)
