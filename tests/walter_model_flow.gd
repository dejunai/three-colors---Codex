extends SceneTree

const MODEL_PATH := "res://assets/models/walter_phase1.glb"
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
	WalterModel.set_outfit(model,false,true)
	for node in model.find_children("Plain*", "", true, false):
		assert(not node.visible, "The plain-coat shell must hide in police state")
	for node in model.find_children("Police*", "", true, false):
		assert(node.visible, "Police geometry must show in police state")
	WalterModel.set_outfit(model,true,false)
	for node in model.find_children("Police*", "", true, false):
		assert(not node.visible, "Police geometry must hide in plain-coat state")
	for node in model.find_children("Plain*", "", true, false):
		assert(node.visible, "The plain-coat shell must show in plain-coat state")
	for node in model.find_children("Badge*", "", true, false):
		assert(not node.visible, "Badge geometry must obey badge-loss/plain-coat state")
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
	print("WALTER MODEL PASS: rendered hierarchy, modular coat/badge groups, and five animation clips imported")
	quit()
