extends SceneTree

# Standalone check for the reverse-engineered content files (dialogue/
# gatehouse_boy.dialogue, coroners_assistant.dialogue, groundskeeper.dialogue,
# gardener.dialogue, old_woman.dialogue, mrs_almy.dialogue), runnable
# directly:
#   godot --headless --path . --script res://tests/dialogue_content_flow.gd
# Complements tests/dialogue_lang_flow.gd, which proves the grammar itself;
# this proves the grammar can faithfully hold real, already-shipped content
# and its real GATE conditions, not just the illustrative fixtures.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var CaseState = load("res://case_state.gd")
	var DialogueState = load("res://scripts/shared/dialogue_state.gd")

	var paths = {
		"boy": "res://dialogue/gatehouse_boy.dialogue",
		"assistant": "res://dialogue/coroners_assistant.dialogue",
		"crew": "res://dialogue/groundskeeper.dialogue",
		"gardener": "res://dialogue/gardener.dialogue",
		"old_woman": "res://dialogue/old_woman.dialogue",
		"almy": "res://dialogue/mrs_almy.dialogue",
		"odell": "res://dialogue/odell.dialogue",
		"father_behan": "res://dialogue/father_behan.dialogue",
		"widow_kessler": "res://dialogue/widow_kessler.dialogue",
		"county_clerk": "res://dialogue/county_clerk.dialogue",
		"gazette_editor": "res://dialogue/gazette_editor.dialogue",
		"tailor": "res://dialogue/tailor.dialogue",
		"harbor_observer": "res://dialogue/harbor_observer.dialogue",
		"schoolteacher": "res://dialogue/schoolteacher.dialogue",
		"local_historian": "res://dialogue/local_historian.dialogue",
		"post_office_clerk": "res://dialogue/post_office_clerk.dialogue",
		"stationer": "res://dialogue/stationer.dialogue",
		"clockmaker": "res://dialogue/clockmaker.dialogue",
		"school_parent": "res://dialogue/school_parent.dialogue",
		"salt_mender": "res://dialogue/salt_mender.dialogue",
		"apothecary": "res://dialogue/apothecary.dialogue",
	}
	var defs = {}
	for key in paths:
		var def = Runtime.load_npc(paths[key])
		assert(def.errors.is_empty(), "%s must parse without errors: %s" % [paths[key], str(def.errors)])
		defs[key] = def

	var state = CaseState.new()
	var dstate = DialogueState.new()
	var ctx = Runtime.make_context(state, dstate)

	# --- gatehouse boy: three mutually exclusive states, most-specific first ---
	var first = Runtime.enter(defs.boy, ctx, dstate)
	_play(first, state, dstate)
	assert(first.cards[0][1].begins_with("THEY'RE IN THE ROSE GARDEN"), "first encounter must be the opening line")
	var second = Runtime.enter(defs.boy, ctx, dstate)
	_play(second, state, dstate)
	assert(second.cards[0][1] == "Through the gap in the hedge. The captain's still on the terrace.", "second visit must be the repeat line, not the opening again")
	state.estate_complete = true
	var after_departure = Runtime.enter(defs.boy, ctx, dstate)
	_play(after_departure, state, dstate)
	assert(after_departure.cards[0][1].begins_with("The wagon's been and gone"), "estate_complete must win over a mere repeat, regardless of visit count")

	# --- coroner's assistant: two real EVIDENCE ids, one flavor-only card ---
	var assistant_play = Runtime.play_topic(defs.assistant, dstate, "default")
	_play(assistant_play, state, dstate)
	var has_flavor_card = false
	for card in assistant_play.cards:
		if card[0] == "A CLEAN READ": has_flavor_card = true
	assert(has_flavor_card, "the closing flavor card must still render even though it writes no fact")
	assert(dstate.evidence.has("testimony") and dstate.evidence.has("eight"), "both bonus discover()s from the source must land as real EVIDENCE ids")

	# --- groundskeeper: ephemeral WALTER'S NOTEBOOK card must not be persisted ---
	var crew_play = Runtime.play_topic(defs.crew, dstate, "default")
	_play(crew_play, state, dstate)
	assert(dstate.evidence.has("crew"), "the FACTS-backed observation must be recorded")
	var ephemeral_persisted = false
	for text in dstate.facts.values():
		if text.begins_with("The distance he keeps is exact"): ephemeral_persisted = true
	assert(not ephemeral_persisted, "a flavor-only WALTER'S NOTEBOOK card must render but never persist as a fact")
	var crew_has_heading = false
	for card in crew_play.cards:
		if card[0] == "THE KITCHEN WING YARD" and card[1].begins_with("A groundskeeper stacks crates"): crew_has_heading = true
	assert(crew_has_heading, "the opening scene-heading card must render with its source speaker, matching story.gd's own card shape")

	# --- gardener: estate_complete + plain coat must win over the base scene ---
	var gardener_before = Runtime.enter(defs.gardener, ctx, dstate)
	_play(gardener_before, state, dstate)
	assert(gardener_before.cards[0][1].begins_with("I keep the roses"), "before estate_complete, the base gardener scene must play regardless of coat")
	state.coat = "Plain wool coat"
	var gardener_after = Runtime.enter(defs.gardener, ctx, dstate)
	_play(gardener_after, state, dstate)
	assert(gardener_after.cards[0][1] == "You took the badge off.", "estate_complete + plain coat must unlock the later gardener scene")

	# --- old woman: one-shot, gated purely on the evidence() the scene itself implies ---
	var woman_menu_before = Runtime.menu(defs.old_woman, ctx)
	assert(woman_menu_before.default_topic != null, "the scene must be available before it has ever been recorded")
	_play(Runtime.enter(defs.old_woman, ctx, dstate), state, dstate)
	state.discover("old_woman")
	var woman_menu_after = Runtime.menu(defs.old_woman, ctx)
	assert(woman_menu_after.default_topic == null, "once evidence(old_woman) is true, the one-shot scene must no longer resolve")

	# --- Mrs. Almy: coat-gated intro, evidence-gated menu, disappearing topic ---
	state.coat = "Police coat" # undo the gardener section's coat change above
	var almy_badge_intro = Runtime.enter(defs.almy, ctx, dstate)
	_play(almy_badge_intro, state, dstate)
	assert(almy_badge_intro.cards[0][1].begins_with("If you've come to tell me"), "in uniform, the badge intro must play on the first visit")
	var almy_menu_no_naomi = Runtime.menu(defs.almy, ctx)
	var almy_ids_no_naomi = []
	for entry in almy_menu_no_naomi.entries: almy_ids_no_naomi.append(entry.id)
	assert(almy_ids_no_naomi.has("identify") and not almy_ids_no_naomi.has("lay_lead") and not almy_ids_no_naomi.has("almy_trust"), "lay_lead/service_work/almy_ledger must stay hidden until naomi is known, and almy_trust needs the plain coat too")
	_play(Runtime.play_topic(defs.almy, dstate, "identify"), state, dstate)
	state.discover("naomi")
	var almy_menu_with_naomi = Runtime.menu(defs.almy, ctx)
	var almy_ids_with_naomi = []
	for entry in almy_menu_with_naomi.entries: almy_ids_with_naomi.append(entry.id)
	assert(almy_ids_with_naomi.has("lay_lead") and almy_ids_with_naomi.has("service_work") and almy_ids_with_naomi.has("almy_ledger"), "naomi known must unlock the three follow-up topics")
	assert(not almy_ids_with_naomi.has("almy_trust"), "almy_trust still needs the plain coat")
	state.coat = "Plain wool coat"
	var almy_menu_plain = Runtime.menu(defs.almy, ctx)
	var almy_ids_plain = []
	for entry in almy_menu_plain.entries: almy_ids_plain.append(entry.id)
	assert(almy_ids_plain.has("almy_trust"), "plain coat + naomi known must surface almy_trust")
	_play(Runtime.play_topic(defs.almy, dstate, "almy_trust"), state, dstate)
	var almy_menu_after_trust = Runtime.menu(defs.almy, ctx)
	var almy_ids_after_trust = []
	for entry in almy_menu_after_trust.entries: almy_ids_after_trust.append(entry.id)
	assert(not almy_ids_after_trust.has("almy_trust"), "answering almy_trust once must remove it from the menu, via topic_done")

	# --- Odell: the real branching response, ported alongside the invented 'bullets' demo ---
	var odell_ctx = Runtime.make_context(state, dstate)
	var odell_first = Runtime.enter(defs.odell, odell_ctx, dstate)
	_play(odell_first, state, dstate)
	assert(odell_first.cards[0][1].begins_with("A gas-main tragedy"), "the real Odell opening line must play first")
	assert(odell_first.fork != null, "the branching response must halt for a choice, same as odell.dialogue's invented FORK proof")
	assert(odell_first.fork.options == ["I understand it. I don't accept it.", "Say nothing. Write it down instead."], "both of Walter's real documented reactions must be offered, in source order")
	var odell_resumed = Runtime.resume(odell_first, 0)
	_play(odell_resumed, state, dstate)
	assert(odell_resumed.fork == null, "supplying a choice must resume the default topic to completion")
	var odell_recorded = false
	for text in dstate.facts.values():
		if text.begins_with("Walter told Odell to his face"): odell_recorded = true
	assert(odell_recorded, "the chosen branch's real statement must be persisted")
	var odell_replay = Runtime.enter(defs.odell, odell_ctx, dstate)
	_play(odell_replay, state, dstate)
	assert(odell_replay.cards.is_empty(), "once answered, topic_done(odell, default) must keep the scene from replaying")

	# --- Father Behan: the real behan_name topic, mutually exclusive with club_invitation ---
	var behan_ctx = Runtime.make_context(state, dstate)
	var behan_menu_before = Runtime.menu(defs.father_behan, behan_ctx)
	var behan_ids_before = []
	for entry in behan_menu_before.entries: behan_ids_before.append(entry.id)
	assert(behan_ids_before.has("club_invitation") and not behan_ids_before.has("behan_name"), "behan_name must stay hidden until club_invitation has been answered")
	_play(Runtime.play_topic(defs.father_behan, dstate, "club_invitation"), state, dstate)
	var behan_menu_after = Runtime.menu(defs.father_behan, behan_ctx)
	var behan_ids_after = []
	for entry in behan_menu_after.entries: behan_ids_after.append(entry.id)
	assert(behan_ids_after.has("behan_name") and not behan_ids_after.has("club_invitation"), "behan_name must replace club_invitation, never both at once")
	_play(Runtime.play_topic(defs.father_behan, dstate, "behan_name"), state, dstate)
	assert(dstate.evidence.has("behan_name"), "the real ship-naming fact must be recorded")

	print("DIALOGUE CONTENT PASS: gatehouse_boy/coroners_assistant/groundskeeper/gardener/old_woman/mrs_almy/odell/father_behan all reverse-engineered, parsing clean and gating correctly against real game state")
	quit(0)

# Test-only stand-in for consuming every displayed card in a segment.
func _play(segment: Dictionary, state, dstate) -> void:
	load("res://scripts/shared/dialogue_runtime.gd").commit_through(segment, state, dstate, segment.cards.size())
