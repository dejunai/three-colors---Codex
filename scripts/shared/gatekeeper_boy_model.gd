extends RefCounted

const MODEL_SCENE: PackedScene = preload("res://assets/models/gatekeeper_boy.glb")
# Tuned against Walter and adult estate staff: 1.05 scale preserves youth proportions,
# keeping the gatekeeper boy visibly shorter and slighter than Walter and the adult cast.
const SCALE_FACTOR: float = 1.05

static func create() -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "GatekeeperBoy"
	var rendered := MODEL_SCENE.instantiate()
	rendered.name = "RenderedBoy"
	rendered.scale = Vector3.ONE * SCALE_FACTOR
	# Blender authored face points +Z in glTF; rotate PI to align with Godot forward (-Z)
	rendered.rotation.y = PI
	wrapper.add_child(rendered)
	var player := animation_player(wrapper)
	if is_instance_valid(player):
		var clips := animation_map(player)
		for anim_name in ["Idle", "Idle_Alt", "Listen"]:
			if clips.has(anim_name):
				var clip: Animation = player.get_animation(clips[anim_name])
				if clip != null:
					clip.loop_mode = Animation.LOOP_LINEAR
		if clips.has("Idle"):
			player.play(clips["Idle"])
	return wrapper

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
		if base_name in ["Idle", "Idle_Alt", "Listen"]:
			result[base_name] = imported_name
	return result

static func set_listening(model: Node3D, listening: bool) -> void:
	var player := animation_player(model)
	if not is_instance_valid(player): return
	var clips := animation_map(player)
	var target_anim := "Listen" if listening else "Idle"
	if clips.has(target_anim):
		player.play(clips[target_anim], 0.3)
