extends SceneTree

# The slice's final path, end to end through the real chapter_one.gd adapters:
# steward's pantry lead -> pantry door -> descent -> retreat -> home -> the break
# (frame widens, color returns, glass breaks) -> tester questions -> ending.
#   godot --headless --path . --script res://tests/break_flow.gd
#
# Every assertion below also guards a Design Law: 4 (the beat cannot alter fairness
# state and must not be skippable into a soft-lock), 9 (the beat survives the
# accessibility settings at their floor), 11 (nothing here strands the player).

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.playthrough_log.endpoint_url = ""
	# Accessibility floor: the break must still read as a break.
	g.settings.distortion = 0.0
	g.settings.reduced_flicker = true
	g._apply_settings()

	g.state = g.CaseState.new()
	g.state.started = true
	g.state.day = 3
	g.state.steward_visits = 3
	g.state.intake_done = true
	g.state.estate_complete = true
	g.state.visited.append("almy")
	g.state.discover("naomi")
	g.state.coat = "Plain wool coat"
	g.state.flask = 3
	g.playthrough_log.begin(g.state, g.scripted_dialogue.FILES.keys())

	# --- The pantry door is offered only once the steward has named it.
	g._travel("lounge", Vector3(0, 0.1, 6), 0, false)
	await _settle(g)
	assert(not g.estate.points.has("pantry_door"), "The pantry door must not be offered before the steward names it")
	assert(g._objective().contains("Ask what the members used to talk about"), "Day 3 with no pantry lead must point at the steward")
	g.state.discover("pantry_lead")
	g._close()
	assert(g.estate.points.has("pantry_door"), "The door must be offered as soon as the lead is recorded, without leaving the lounge")
	assert(g._objective().contains("old pantry door"))
	g.player.position = Vector3(-6.4, 0.1, -3.0)
	await _settle(g)
	g._find_focus()
	assert(g.focused == "pantry_door", "The door must be reachable on foot: focused=%s" % g.focused)

	# --- Through the door: checkpoint, no death, tunnel world.
	g._interact("pantry_door")
	assert(g.page == "dialogue", "The door must show its authored cards")
	_drain(g)
	assert(g.state.world == "tunnel", "The pantry door must lead into the passage")
	assert(not g.tunnel_checkpoint.is_empty(), "Entering by the pantry door must take the service-stair checkpoint")
	assert(g.state.portal_state.portal_done("lounge", "pantry_door"))

	# --- The spur, then the choice to go on.
	g._interact("tunnel_descent")
	_drain(g)
	assert(g.state.flask_spilled and g.state.flask == 0)
	g._interact("tunnel_descent")
	assert(_button(g, "Go on into the dark") != null and _button(g, "Step back to the foundation support") != null, "After the spur the player chooses; stepping back must stay available (Law 11)")
	_button(g, "Step back to the foundation support").pressed.emit()
	assert(g.state.world == "tunnel" and not g.state.dialogue_state.flag("tunnel_retreated"), "Stepping back must not trigger the retreat")
	g._interact("tunnel_descent")
	var evidence_before = g.state.evidence.duplicate()
	_button(g, "Go on into the dark").pressed.emit()
	_drain(g)
	assert(g.state.world == "room", "The retreat must end at home")
	assert(g.state.dialogue_state.flag("tunnel_retreated") and g.state.dialogue_state.flag("badge_lost"))
	assert(g.state.statements.any(func(t): return t.contains("badge and the whistle")), "The loss must be recorded in the case file, not only shown once (Law 4)")
	assert(not g.model.get_node("Badge").visible, "The badge must actually be gone")
	assert(g._objective() == "Home. The board is on the wall.")

	# --- The world stays shut and silent until the beat.
	g._interact("sleep")
	assert(g.page == "case" and not g.state.finished, "Sleeping must not end the slice before the break")
	g._close()
	g._interact("interior_exit")
	_drain(g)
	assert(g.state.world == "room", "The door must stay shut while the break is pending")
	assert(g.breaker.pending(g))
	assert(g.presentation.frame_edge == g.presentation.BOXED_FRAME and g.presentation.color_return == 0.0, "No widening or color before the break")
	assert(not g.estate.glass_shattered)
	g.breaker.tick(g, 3.0)
	assert(g.page == "play", "The quiet interval must not fire early")

	# --- The break.
	g.breaker.tick(g, 8.0)
	assert(g.page == "dialogue", "The board cards open the beat")
	_drain(g)
	assert(g.page == "break", "Between the cards and the glass the page is held, so nothing can interrupt the beat")
	g.focused = "sleep"
	g.handle_input(_action("use"))
	g.handle_input(_action("pause_game"))
	g.handle_input(_action("case"))
	assert(g.page == "break", "Neither an interaction, Escape, nor the case file may interrupt the held beat")
	var frames = 0
	while not g.state.dialogue_state.flag("glass_broken") and frames < 900:
		await process_frame
		frames += 1
	assert(g.state.dialogue_state.flag("glass_broken"), "The glass must break")
	assert(g.hazard_caption.text == "[Glass breaking.]" and g.hazard_caption.visible, "The sound needs a protected caption (Law 9)")
	assert(g.estate.glass_shattered)
	assert(g.state.finished, "Breaking the glass is the point of no return: a save from here resumes at the ending")
	assert(g.presentation.frame_edge < g.presentation.BOXED_FRAME, "The frame must widen even at zero distortion and reduced flicker")
	assert(g.presentation.color_return > 0.0, "Color must return even at zero distortion and reduced flicker")
	assert(g.estate.board_threads[0].material_override != null and g.estate.whiskey.material_override != null)
	frames = 0
	while g.page != "dialogue" and frames < 900:
		await process_frame
		frames += 1
	assert(g.page == "dialogue", "The aftermath cards must follow the silence")
	assert(g.presentation.frame_edge == 0.0, "The frame must finish fully wide")
	assert(g.state.evidence == evidence_before, "The beat must not add or remove evidence (Law 4)")
	assert(g.breaker.build_glass_stream().data.size() > 44100, "The glass must have a real sound")

	# --- Save after the glass resumes at the ending, never inside the beat.
	var resumed = g.CaseState.new()
	assert(resumed.restore(g.state.pack().duplicate(true)))
	assert(resumed.finished and resumed.dialogue_state.flag("glass_broken") and resumed.dialogue_state.flag("tunnel_retreated"))

	# --- Aftermath, the two optional questions, the ending.
	_drain(g)
	assert(_button(g, "Skip") != null, "The tester questions follow the glass")
	_button(g, "Skip").pressed.emit()
	_button(g, "Skip").pressed.emit()
	assert(g.page == "ending" and g.state.finished)
	assert(not g.breaker.running)
	var text = ""
	for label in g.content.find_children("*", "Label", true, false): text += label.text + "\n"
	assert(text.contains("Is that the way sound works?") and text.contains("Notebook:"), "The ending must be the slice ending, not the legacy town-inquiry ending")
	assert(_button(g, "Continue exploring") == null, "The slice does not offer the world after the break")
	assert(_button(g, "Review the board") != null)
	var debriefs = g.playthrough_log.buffer.filter(func(item): return item.event == "debrief")
	assert(debriefs.size() == 1, "Exactly one debrief event")
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "day3_bed_reached").size() == 1)

	# --- Loading the finished save returns to the ending, and the break cannot replay.
	g._close()
	g.breaker.tick(g, 60.0)
	assert(g.page == "play" and not g.breaker.running, "A finished slice must never replay the break")
	g._town_complete()
	assert(g.page == "ending")
	print("BREAK PASS: pantry door gated on the lead, checkpoint, spur, chosen retreat, badge lost and recorded, silent held beat, widening and color at zero distortion, caption, point of no return, ending, one debrief, no replay")
	quit(0)

func _settle(g:Node) -> void:
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame

func _drain(g:Node) -> void:
	var guard = 0
	while g.page == "dialogue" and guard < 200:
		g._next_card()
		guard += 1

func _button(g:Node, text:String) -> Button:
	for button in g.content.find_children("*", "Button", true, false):
		if button.text == text: return button
	return null

func _action(name:String) -> InputEventAction:
	var event = InputEventAction.new()
	event.action = name
	event.pressed = true
	return event
