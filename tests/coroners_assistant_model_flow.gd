extends SceneTree

const AssistantModel = preload("res://scripts/shared/coroners_assistant_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model := AssistantModel.create()
	assert(model != null, "Coroner's assistant model must instantiate")
	root.add_child(model)
	var player := AssistantModel.animation_player(model)
	assert(player != null, "Coroner's assistant must have an AnimationPlayer")
	var anims := AssistantModel.animation_map(player)
	for req in ["Idle", "Idle_Alt", "Confer"]:
		assert(anims.has(req), "Coroner's assistant must map semantic animation " + req + "; found: " + str(anims))
	assert(player.current_animation == anims["Idle"], "Coroner's assistant must begin in the mapped idle")
	AssistantModel.set_conversing(model, true)
	assert(player.current_animation == anims["Confer"], "Conversation must use the mapped Stand_and_Chat clip")
	AssistantModel.set_conversing(model, false)
	assert(player.current_animation == anims["Idle"], "Closing dialogue must return to idle")
	var rendered := model.get_node_or_null("RenderedCoronersAssistant") as Node3D
	assert(rendered != null and is_equal_approx(rendered.scale.y, AssistantModel.SCALE_FACTOR), "Assistant scale must remain at the established adult scale")
	print("CORONER'S ASSISTANT MODEL PASS: female model instantiates and maps idle/alternate/conversation animations")
	quit(0)
