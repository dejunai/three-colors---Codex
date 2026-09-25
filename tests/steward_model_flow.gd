extends SceneTree

const StewardModel = preload("res://scripts/shared/steward_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := StewardModel.create()
	assert(model != null, "Steward model must instantiate")
	root.add_child(model)
	var player := StewardModel.animation_player(model)
	assert(player != null, "Steward model must have an AnimationPlayer")
	var anims := StewardModel.animation_map(player)
	for req in ["Clean_Glass", "Idle", "Idle_Alt", "Confer", "Listen"]:
		assert(anims.has(req), "Steward must have animation " + req + "; found: " + str(anims))

	assert(player.current_animation == anims["Clean_Glass"], "Steward must begin in Clean_Glass idle")
	
	StewardModel.set_conversing(model, true)
	assert(player.current_animation == anims["Confer"], "set_conversing(true) must trigger Confer")
	StewardModel.set_conversing(model, false)
	assert(player.current_animation == anims["Clean_Glass"], "set_conversing(false) must return to Clean_Glass")

	StewardModel.set_listening(model, true)
	assert(player.current_animation == anims["Listen"], "set_listening(true) must trigger Listen")
	StewardModel.set_listening(model, false)
	assert(player.current_animation == anims["Clean_Glass"], "set_listening(false) must return to Clean_Glass")

	StewardModel.set_cleaning_glass(model, false)
	assert(player.current_animation == anims["Idle"], "set_cleaning_glass(false) must set Idle")
	StewardModel.set_cleaning_glass(model, true)
	assert(player.current_animation == anims["Clean_Glass"], "set_cleaning_glass(true) must restore Clean_Glass")

	# Verify child scale
	var rendered: Node3D = model.get_node_or_null("RenderedSteward")
	assert(rendered != null and is_equal_approx(rendered.scale.y, 1.15), "Steward scale must remain 1.15")

	print("STEWARD MODEL PASS: instantiates at 1.15 scale, exposes 5 animations, and toggles clean/confer/listen states")
	quit(0)
