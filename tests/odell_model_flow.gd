extends SceneTree

const CaptainOdellModel = preload("res://scripts/shared/captain_odell_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := CaptainOdellModel.create()
	assert(model != null, "Captain Odell model must instantiate")
	root.add_child(model)
	var player := CaptainOdellModel.animation_player(model)
	assert(player != null, "Captain Odell must have an AnimationPlayer")
	var animations := CaptainOdellModel.animation_map(player)
	for required in ["Idle", "Idle_Alt", "Confer"]:
		assert(animations.has(required), "Captain Odell must have animation " + required + "; found: " + str(animations))
	assert(player.current_animation == animations["Idle"], "Captain Odell must begin in Idle")
	CaptainOdellModel.set_conversing(model, true)
	assert(player.current_animation == animations["Confer"], "Odell must use Confer during dialogue")
	CaptainOdellModel.set_conversing(model, false)
	assert(player.current_animation == animations["Idle"], "Odell must return to Idle after dialogue")
	var rendered: Node3D = model.get_node_or_null("RenderedOdell")
	assert(rendered != null and is_equal_approx(rendered.scale.y, 1.30), "Captain Odell scale must remain 1.30")
	print("ODELL MODEL PASS: instantiates at 1.30 scale and toggles Idle/Confer dialogue animation")
	quit(0)
