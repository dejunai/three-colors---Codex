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
	# Arrive exactly as a real Day 3 save does: two completed visits. The third
	# visit must be earned by finishing steward_open below.
	g.state.steward_visits = 2
	g.state.intake_done = true
	g.state.estate_complete = true
	g.state.visited.append("almy")
	g.state.discover("naomi")
	g.state.coat = "Plain wool coat"
	g.state.flask = 3
	g.playthrough_log.begin(g.state, g.scripted_dialogue.FILES.keys())

	# --- The pantry door is offered only once the player earns the lead through
	# the steward's live Day 3 dialogue. Do not inject pantry_lead here: this is the
	# handoff most likely to strand a real playthrough while isolated tests pass.
	g._travel("lounge", Vector3(0, 0.1, 6), 0, false)
	await _settle(g)
	assert(g.estate.points.has("pantry_door") and g.estate.points["pantry_door"]["title"] == "Examine the boarded pantry door", "The pantry door must be offered for curious inspection before the steward names it")
	g._interact("pantry_door")
	assert(g.page == "dialogue", "Examining the boarded door shows its flavor card")
	_drain(g)
	assert(g.state.world == "lounge", "Examining the boarded door must not travel to the tunnel")
	assert(g._objective().contains("leave your badge behind"), "Day 3 before the third visit must point back to the steward")
	g._interact("barman")
	_drain(g)
	assert(g.state.steward_visits == 3 and g.page == "witness" and _button(g, "Ask what the members used to talk about") != null, "Finishing the third steward visit must open the inquiry menu")
	assert(g._objective().contains("Ask what the members used to talk about"), "The objective must advance with the third steward visit")
	for inquiry in [
		["Ask what the members used to talk about", "club_talk"],
		["Ask what Kessler used to say", "club_devotion"],
		["Ask about the old pantry door", "pantry_lead"]
	]:
		var option = _button(g, inquiry[0])
		assert(option != null, "The steward route must expose: %s" % inquiry[0])
		option.pressed.emit()
		assert(g.page == "dialogue")
		_drain(g)
		assert(g.state.evidence.has(inquiry[1]), "The completed steward topic must record %s" % inquiry[1])
	assert(g.page == "witness" and _button(g, "Leave the conversation") != null)
	_button(g, "Leave the conversation").pressed.emit()
	assert(g.page == "play")
	assert(g.estate.points.has("pantry_door") and g.estate.points["pantry_door"]["title"] == "Open the boarded pantry door", "The door must offer to open as soon as the lead is recorded, without leaving the lounge")
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

	# The forced door state is portal history, not a transient room flag. An early
	# detour through the precinct must never rebuild the boards on return.
	g._travel("precinct", Vector3(0,0.1,6), 0, false)
	g._travel("lounge", Vector3(0,0.1,6), 0, false)
	var pantry_states: Node3D = g.estate.get_node("PantryDoorStates")
	assert(not pantry_states.get_node("Boarded").visible and pantry_states.get_node("Cleared").visible, "Completed pantry door must stay cleared after precinct-to-lounge round trip")
	g._travel("tunnel", Vector3(0,0.1,7), 0, false)

	# --- Assertion 1: Flask intact on tunnel entry.
	assert(g.state.flask == 3 and not g.state.flask_spilled, "Flask must remain intact on tunnel entry")
	assert(not g.state.dialogue_state.flag("badge_lost"), "Badge must remain intact on tunnel entry")

	# --- The spur (Assertion 2: Flask intact after observing the spur).
	g._interact("tunnel_descent")
	_drain(g)
	assert(g.state.flask == 3 and not g.state.flask_spilled, "Flask must remain intact after observing the spur")
	assert(not g.state.dialogue_state.flag("badge_lost"), "Badge must remain intact after observing the spur")
	assert(g.state.dialogue_state.flag("tunnel_spur_seen"), "Spur observation must be marked seen")

	# --- Assertion 3: All three effects intact after choosing to step back.
	g._interact("tunnel_descent")
	assert(_button(g, "Go on into the dark") != null and _button(g, "Step back to the foundation support") != null, "After the spur the player chooses; stepping back must stay available (Law 11)")
	_button(g, "Step back to the foundation support").pressed.emit()
	assert(g.state.world == "tunnel" and not g.state.dialogue_state.flag("tunnel_retreated"), "Stepping back must not trigger the retreat")
	assert(g.state.flask == 3 and not g.state.flask_spilled, "Flask must remain intact after choosing to step back")
	assert(not g.state.dialogue_state.flag("badge_lost"), "Badge must remain intact after choosing to step back")

	# --- Assertion 5 (part 1): Plain-coat badge inspection says pocketed before retreat.
	g._case_file()
	g._badge()
	var badge_text_before = ""
	for child in g.content.find_children("*", "Label", true, false): badge_text_before += child.text + "\n"
	assert(badge_text_before.contains("pocketed") and badge_text_before.contains("inside"), "Plain-coat badge inspection must say it is pocketed inside the coat before retreat")
	g._close()

	# --- Assertion 4: All three lost together after continuing and completing the retreat.
	g._interact("tunnel_descent")
	var evidence_before = g.state.evidence.duplicate()
	_button(g, "Go on into the dark").pressed.emit()
	_drain(g)
	assert(g.state.world == "room", "The retreat must end at home")
	assert(g.state.dialogue_state.flag("tunnel_retreated") and g.state.dialogue_state.flag("badge_lost"))
	assert(g.state.flask_spilled and g.state.flask == 0 and g.state.flask_spill_amount == 3, "Flask must be lost at retreat fall")
	assert(g.state.evidence.has("flask_spill"), "flask_spill evidence granted on retreat")
	assert(g.state.statements.any(func(t): return t.contains("badge and the whistle")), "The loss must be recorded in the case file, not only shown once (Law 4)")
	assert(not g.model.get_node("Badge").visible, "The badge must actually be gone")
	assert(g._objective() == "Home. The board is on the wall.")

	# --- Assertion 5 (part 2): Plain-coat badge inspection says lost afterward.
	g._case_file()
	g._badge()
	var badge_text_after = ""
	for child in g.content.find_children("*", "Label", true, false): badge_text_after += child.text + "\n"
	assert(badge_text_after.contains("Lost below the estate"), "Badge inspection must say it was lost below the estate after retreat")
	g._close()

	# --- Assertion 6: Save/load preserves the resulting loss state.
	var saved_dict = g.state.pack()
	var loaded_state = g.CaseState.new()
	assert(loaded_state.restore(saved_dict), "State must restore cleanly")
	assert(loaded_state.flask_spilled and loaded_state.flask == 0 and loaded_state.flask_spill_amount == 3, "Save/load must preserve flask loss state")
	assert(loaded_state.dialogue_state.flag("badge_lost"), "Save/load must preserve badge_lost flag")
	assert(loaded_state.dialogue_state.flag("tunnel_retreated"), "Save/load must preserve tunnel_retreated flag")
	assert(loaded_state.dialogue_state.flag("tunnel_spur_seen"), "Save/load must preserve tunnel_spur_seen flag")

	# --- The world stays shut and silent until the beat.
	evidence_before = g.state.evidence.duplicate()
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
	assert(g.rig._model_animation_base == "Surprise", "The glass must trigger Walter's custom Surprise action")
	assert(g.hazard_caption.text == "[Glass breaking.]" and g.hazard_caption.visible, "The sound needs a protected caption (Law 9)")
	assert(g.estate.glass_shattered)
	assert(g.state.finished, "Breaking the glass is the point of no return: a save from here resumes at the ending")
	assert(g.presentation.frame_edge < g.presentation.BOXED_FRAME, "The frame must widen even at zero distortion and reduced flicker")
	assert(g.presentation.color_return > 0.0, "Color must return even at zero distortion and reduced flicker")
	assert(g.estate.board_threads[0].material_override != null and g.estate.whiskey.material_override != null)
	frames = 0
	while g.page != "case" and frames < 900:
		await process_frame
		frames += 1
	assert(g.page == "case" and _button(g, "Skip") != null, "The glass must cut directly to the out-of-fiction tester questions")
	assert(g.presentation.frame_edge == 0.0, "The frame must finish fully wide")
	assert(g.state.evidence == evidence_before, "The beat must not add or remove evidence (Law 4)")
	assert(g.breaker.glass_player.stream == load("res://glass_shatter.ogg"), "The ending must use the authored glass-shatter recording")
	assert(g.breaker.glass_player.stream.get_length() > 0.1, "The authored glass-shatter recording must contain audio")

	# --- Save after the glass resumes at the ending, never inside the beat.
	var resumed = g.CaseState.new()
	assert(resumed.restore(g.state.pack().duplicate(true)))
	assert(resumed.finished and resumed.dialogue_state.flag("glass_broken") and resumed.dialogue_state.flag("tunnel_retreated"))

	# --- The two optional out-of-fiction questions, then the ending.
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
	assert(g.playthrough_log.buffer.filter(func(item): return item.event == "session_end").size() == 1, "Debrief and completion must be queued together")
	assert(g.state.dialogue_state.flag("debrief_completed"))
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
