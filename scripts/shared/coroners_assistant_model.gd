extends RefCounted

# Female coroner's-assistant model used by both the opening estate scene and the
# returning morgue schedule. Tuned to the same adult scale as the original male
# stand-in so placement, focus distance, and camera framing remain unchanged.
const MODEL_SCENE: PackedScene = preload("res://assets/models/coroners_assistant.glb")
const SCALE_FACTOR: float = 1.18

const ANIMATION_ALIASES := {
	"Idle": ["Idle_11", "Idle_3", "Armature|clip0|baselayer"],
	"Idle_Alt": ["Idle_3", "Idle_11"],
	"Confer": ["Stand_and_Chat", "Listening_Gesture"],
}

static func create() -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "CoronersAssistant"
	var rendered := MODEL_SCENE.instantiate()
	rendered.name = "RenderedCoronersAssistant"
	rendered.scale = Vector3.ONE * SCALE_FACTOR
	# Meshy authors face toward +Z; rotate PI to align with Godot's forward (-Z).
	rendered.rotation.y = PI
	wrapper.add_child(rendered)
	var player := animation_player(wrapper)
	if is_instance_valid(player):
		var clips := animation_map(player)
		for semantic_name in clips:
			var clip: Animation = player.get_animation(clips[semantic_name])
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
	var imported := player.get_animation_list()
	for semantic_name in ANIMATION_ALIASES:
		for alias in ANIMATION_ALIASES[semantic_name]:
			for imported_name in imported:
				if String(imported_name).get_file() == alias:
					result[semantic_name] = imported_name
					break
			if result.has(semantic_name): break
	return result

static func set_conversing(model: Node3D, conversing: bool) -> void:
	var player := animation_player(model)
	if not is_instance_valid(player): return
	var clips := animation_map(player)
	var target := "Confer" if conversing else "Idle"
	if clips.has(target):
		player.play(clips[target], 0.3)
