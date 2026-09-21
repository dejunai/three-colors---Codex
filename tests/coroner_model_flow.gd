extends SceneTree

const CoronerModel = preload("res://scripts/shared/coroner_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := CoronerModel.create()
	assert(model != null, "Coroner model must instantiate")
	root.add_child(model)
	var player := CoronerModel.animation_player(model)
	assert(player != null, "Coroner model must have an AnimationPlayer")
	var anims := CoronerModel.animation_map(player)
	for req in ["Idle", "Idle_Alt", "Confer"]:
		assert(anims.has(req), "Coroner must have animation " + req + "; found: " + str(anims))

	assert(player.current_animation == anims["Idle"], "Coroner must begin in Idle")
	CoronerModel.set_conversing(model, true)
	assert(player.current_animation == anims["Confer"], "set_conversing(true) must trigger Confer")
	CoronerModel.set_conversing(model, false)
	assert(player.current_animation == anims["Idle"], "set_conversing(false) must return to Idle")

	# Verify child scale
	var rendered: Node3D = model.get_node_or_null("RenderedCoroner")
	assert(rendered != null and is_equal_approx(rendered.scale.y, 1.18), "Coroner scale must remain 1.18")

	print("CORONER MODEL PASS: instantiates at 1.18 scale, exposes Idle/Idle_Alt/Confer, and toggles conversing state")
	quit(0)
