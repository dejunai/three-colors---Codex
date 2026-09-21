extends SceneTree

# Integration proof for the two estate pickups that use Walter's rendered
# ground-reach animation. The object/evidence runtime still owns completion.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = false
	g.playthrough_log.enabled = false
	g.playthrough_log.endpoint_url = ""
	g.state = g.CaseState.new()
	g.state.started = true
	g._close()
	g._refresh_outfit()

	assert(is_instance_valid(g.estate.opening_knife) and g.estate.opening_knife.visible, "The knife prop must begin visible")
	g._interact("knife")
	assert(g.rig._animation_lock and g.page == "play", "The pickup must hold gameplay before opening the object cards")
	var reach_frames := 0
	while g.estate.opening_knife.visible and reach_frames < 400:
		await process_frame
		reach_frames += 1
	assert(not g.estate.opening_knife.visible, "The knife must disappear at Walter's reach point")
	assert(g.rig._animation_lock, "The reach point must occur before the pickup animation releases control")
	await _pickup_complete(g)
	assert(g.page == "dialogue", "Knife examination cards must begin after the pickup finishes")
	_drain(g)
	assert(g.state.evidence.has("knife"), "The existing object runtime must still commit knife evidence")

	g._interact("watch")
	assert(g.rig._animation_lock and g.page == "play", "The stopped watch must use the same ground-pickup beat")
	await _pickup_complete(g)
	assert(g.page == "dialogue", "Watch examination cards must begin after the pickup finishes")
	_drain(g)
	assert(g.state.evidence.has("watch"), "The existing object runtime must still commit watch evidence")
	assert(g.state.has_item("pocketwatch"), "The pocket watch must be taken into inventory")

	# Second examination: repeat text triggers when pocketwatch is in inventory / evidence
	g._interact("watch")
	assert(not g.rig._animation_lock, "Second examination must not trigger ground pickup lock")
	assert(g.page == "dialogue", "Second examination cards must open")
	var found_repeat_text := false
	for child in g.content.get_children():
		if child is Label and child.text.contains("already searched the wool coat"):
			found_repeat_text = true
			break
	assert(found_repeat_text, "Repeat examination must display the new flavor text reflecting watch in inventory")
	_drain(g)

	print("WALTER PICKUP PASS: knife reach timing, watch pickup, control lock, and repeat examination flavor text verified")
	quit()

func _pickup_complete(g: Node) -> void:
	var frames := 0
	while g.rig._animation_lock and frames < 600:
		await process_frame
		frames += 1
	assert(not g.rig._animation_lock, "Ground pickup must release control")

func _drain(g: Node) -> void:
	while g.page == "dialogue":
		g._next_card()
