extends SceneTree

const GatekeeperBoyModel = preload("res://scripts/shared/gatekeeper_boy_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := GatekeeperBoyModel.create()
	assert(model != null, "Gatekeeper Boy model must instantiate")
	root.add_child(model)
	var player := GatekeeperBoyModel.animation_player(model)
	assert(player != null, "Gatekeeper Boy must have an AnimationPlayer")
	var anims := GatekeeperBoyModel.animation_map(player)
	for req in ["Idle", "Idle_Alt", "Listen"]:
		assert(anims.has(req), "Gatekeeper Boy must have animation " + req + "; found: " + str(anims))
	
	assert(player.current_animation == anims["Idle"], "Gatekeeper Boy must begin in Idle")
	GatekeeperBoyModel.set_listening(model, true)
	assert(player.current_animation == anims["Listen"], "set_listening(true) must trigger Listen")
	GatekeeperBoyModel.set_listening(model, false)
	assert(player.current_animation == anims["Idle"], "set_listening(false) must return to Idle")
	
	# Verify the accepted child scale without allowing a future adult-size regression.
	var rendered: Node3D = model.get_node_or_null("RenderedBoy")
	assert(rendered != null and is_equal_approx(rendered.scale.y, 0.95), "Gatekeeper Boy scale must remain 0.95")
	
	print("BOY MODEL PASS: instantiates at 0.95 scale, exposes Idle/Idle_Alt/Listen, and toggles listening state")
	quit(0)
