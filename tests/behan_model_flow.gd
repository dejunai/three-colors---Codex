extends SceneTree

const FatherBehanModel = preload("res://scripts/shared/father_behan_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := FatherBehanModel.create()
	assert(model != null, "Father Behan model must instantiate")
	root.add_child(model)
	var player := FatherBehanModel.animation_player(model)
	assert(player != null, "Father Behan must have an AnimationPlayer")
	var anims := FatherBehanModel.animation_map(player)
	for req in ["Idle", "Idle_Alt", "Listen"]:
		assert(anims.has(req), "Father Behan must have animation " + req + "; found: " + str(anims))
	
	assert(player.current_animation == anims["Idle"], "Father Behan must begin in Idle")
	FatherBehanModel.set_listening(model, true)
	assert(player.current_animation == anims["Listen"], "set_listening(true) must trigger Listen")
	FatherBehanModel.set_listening(model, false)
	assert(player.current_animation == anims["Idle"], "set_listening(false) must return to Idle")
	
	print("BEHAN MODEL PASS: instantiates, exposes Idle/Idle_Alt/Listen, and toggles listening state")
	quit(0)
