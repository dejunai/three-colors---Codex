extends SceneTree

const MODEL_PATH := "res://assets/models/walter_phase1.glb"
const PLAIN_MODEL_PATH := "res://assets/models/walter_plain.glb"
const REQUIRED_ANIMATIONS := ["Idle", "Walk", "Brisk", "Interact", "Pickup_Ground"]
const WalterModel = preload("res://scripts/shared/walter_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed: PackedScene = load(MODEL_PATH)
	assert(packed != null, "Walter's rendered GLB must load")
	var model := packed.instantiate()
	root.add_child(model)
	assert(model.find_child("WalterPhase1", true, false) != null or model.name == "WalterPhase1", "Walter model must retain its authored root")
	for required_node in ["Body", "PoliceCoat", "PlainCoat", "Badge", "WalterSkeleton"]:
		assert(model.find_child(required_node, true, false) != null, "Walter model must expose " + required_node)
	var plain_packed: PackedScene = load(PLAIN_MODEL_PATH)
	assert(plain_packed != null, "Walter's independently modeled civilian GLB must load")
	var plain_source := plain_packed.instantiate()
	root.add_child(plain_source)
	assert(plain_source.find_child("PlainWalterMesh", true, false) != null, "Civilian Walter must expose its own rendered mesh")
	assert(plain_source.find_child("PlainWalterSkeleton", true, false) != null, "Civilian Walter must preserve its own compatible rig")
	var players := model.find_children("*", "AnimationPlayer", true, false)
	assert(not players.is_empty(), "Walter model must import an AnimationPlayer")
	var player: AnimationPlayer = players[0]
	var imported_names: PackedStringArray = player.get_animation_list()
	for required_animation in REQUIRED_ANIMATIONS:
		var found := false
		for imported_name in imported_names:
			if String(imported_name).get_file() == required_animation or String(imported_name).ends_with("/" + required_animation):
				found = true
		assert(found, "Walter model must import animation " + required_animation + "; imported=" + str(imported_names))
	var runtime_model := WalterModel.create()
	root.add_child(runtime_model)
	var rendered := runtime_model.get_node_or_null("RenderedWalter") as Node3D
	assert(rendered != null and is_equal_approx(rendered.scale.x, 1.30), "Walter's accepted world scale must remain 1.30")
	var rendered_plain := runtime_model.get_node_or_null("RenderedPlainWalter") as Node3D
	assert(rendered_plain != null and is_equal_approx(rendered_plain.scale.x, 1.30), "Civilian Walter must share the accepted world scale")
	assert(rendered.visible and not rendered_plain.visible, "Police Walter must be the initial rendered outfit")
	WalterModel.set_outfit(runtime_model, true, false)
	assert(not rendered.visible and rendered_plain.visible, "Plain coat must switch complete rendered models")
	assert(not runtime_model.find_child("Badge", true, false).visible, "The badge must remain absent in civilian clothes")
	WalterModel.set_outfit(runtime_model, false, true)
	assert(rendered.visible and not rendered_plain.visible, "Police coat must restore the complete police model")
	var runtime_players := WalterModel.animation_players(runtime_model)
	assert(runtime_players.size() == 2, "Both independently rigged outfits must expose an animation player")
	for runtime_player in runtime_players:
		var runtime_anims := WalterModel.animation_map(runtime_player)
		assert(String(runtime_anims.get("Walk", "")).get_file() == "Walking", "Both outfits must use the straighter Walking take")
		assert(runtime_anims.has("Surprise"), "Both outfits need the surprise-to-ear action")
		assert(runtime_anims.has("Examine"), "Both outfits need the desk-height examination action")
	print("WALTER MODEL PASS: distinct police/civilian models, complete outfit switch, two compatible rigs, scale, straight gait, Surprise, and Examine available")
	quit()
