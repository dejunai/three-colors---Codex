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
		"net_seller": "res://dialogue/net_seller.dialogue",
		"quay_docker": "res://dialogue/quay_docker.dialogue",
		"ropewalk_foreman": "res://dialogue/ropewalk_foreman.dialogue",
		"chandlers_boy": "res://dialogue/chandlers_boy.dialogue",
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
	assert(after_departure.session.tag in ["boy_return", "boy_return_cold", "boy_return_post"], "estate_complete must win over a mere repeat, regardless of visit count")

	# --- coroner's assistant: pre-Odell flavor, then post-Odell testimony & count ---
	var assistant_before = Runtime.enter(defs.assistant, ctx, dstate)
	_play(assistant_before, state, dstate)
	assert(assistant_before.session.tag == "assistant_pre_odell", "before Odell, assistant must give opening flavor directing Walter to the captain")
	assert(not dstate.evidence.has("testimony"), "pre-Odell encounter must not grant explosion testimony")

	var post_odell_dstate = DialogueState.new()
	post_odell_dstate.complete_topic("odell", "default")
	var post_odell_ctx = Runtime.make_context(state, post_odell_dstate)
	var assistant_play = Runtime.enter(defs.assistant, post_odell_ctx, post_odell_dstate)
	_play(assistant_play, state, post_odell_dstate)
	var has_flavor_card = false
	for card in assistant_play.cards:
		if card[0] == "A CLEAN READ": has_flavor_card = true
	assert(has_flavor_card, "the closing flavor card must still render even though it writes no fact")
	assert(post_odell_dstate.evidence.has("testimony") and post_odell_dstate.evidence.has("eight"), "both bonus discover()s from the source must land as real EVIDENCE ids")

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

	# --- Mrs. Almy: coat-gated intro, evidence-gated menu, revisitable topic ---
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
	assert(almy_ids_after_trust.has("almy_trust"), "topics stay revisitable — answering almy_trust once must not remove it from the menu")
	assert(almy_menu_after_trust.entries[almy_ids_after_trust.find("almy_trust")].label.ends_with("· recorded"), "a completed topic must carry the recorded marker")
	var facts_after_first_trust = dstate.facts.size()
	_play(Runtime.play_topic(defs.almy, dstate, "almy_trust"), state, dstate)
	assert(dstate.facts.size() == facts_after_first_trust, "replaying a self-guard-free topic must not duplicate its recorded fact")

	# --- old woman: one-shot, gated on evidence(naomi) (known via almy above) plus the scene's own evidence() ---
	var woman_menu_before = Runtime.menu(defs.old_woman, ctx)
	assert(woman_menu_before.default_topic != null, "the scene must be available once naomi is known, before it has ever been recorded")
	_play(Runtime.enter(defs.old_woman, ctx, dstate), state, dstate)
	state.discover("old_woman")
	var woman_menu_after = Runtime.menu(defs.old_woman, ctx)
	assert(woman_menu_after.default_topic == null, "once evidence(old_woman) is true, the one-shot scene must no longer resolve")

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

	# --- Father Behan: the real behan_name topic, unlocked by (not exclusive with) club_invitation ---
	dstate.complete_topic("steward", "club_talk")
	var behan_ctx_intro = Runtime.make_context(state, dstate)
	var behan_intro = Runtime.enter(defs.father_behan, behan_ctx_intro, dstate)
	_play(behan_intro, state, dstate)
	var behan_ctx = Runtime.make_context(state, dstate)
	var behan_menu_before = Runtime.menu(defs.father_behan, behan_ctx)
	var behan_ids_before = []
	for entry in behan_menu_before.entries: behan_ids_before.append(entry.id)
	assert(behan_ids_before.has("club_invitation") and not behan_ids_before.has("behan_name"), "behan_name must stay hidden until club_invitation has been answered")
	_play(Runtime.play_topic(defs.father_behan, dstate, "club_invitation"), state, dstate)
	var behan_menu_after = Runtime.menu(defs.father_behan, behan_ctx)
	var behan_ids_after = []
	for entry in behan_menu_after.entries: behan_ids_after.append(entry.id)
	assert(behan_ids_after.has("behan_name") and behan_ids_after.has("club_invitation"), "behan_name must unlock alongside club_invitation, which stays revisitable rather than disappearing")
	_play(Runtime.play_topic(defs.father_behan, dstate, "behan_name"), state, dstate)
	assert(dstate.evidence.has("behan_name"), "the real ship-naming fact must be recorded")

	# --- County clerk: postal details must be earned before the wage-claim filing topic appears ---
	state.discover("lay_lead")
	var clerk_ctx = Runtime.make_context(state, dstate)
	var clerk_menu_before = Runtime.menu(defs.county_clerk, clerk_ctx)
	var clerk_ids_before = []
	for entry in clerk_menu_before.entries: clerk_ids_before.append(entry.id)
	assert(not clerk_ids_before.has("wage_claim_inquiry"), "lay_lead alone must not surface postal details or the county filing topic")
	state.discover("new_bedford_letters")
	var clerk_menu_letters = Runtime.menu(defs.county_clerk, clerk_ctx)
	var clerk_ids_letters = []
	for entry in clerk_menu_letters.entries: clerk_ids_letters.append(entry.id)
	assert(not clerk_ids_letters.has("wage_claim_inquiry"), "the filing topic must still stay hidden until the postmaster refusal establishes the minor-son detail")
	state.discover("postal_bureaucracy_refusal")
	var clerk_menu_after = Runtime.menu(defs.county_clerk, clerk_ctx)
	var clerk_ids_after = []
	for entry in clerk_menu_after.entries: clerk_ids_after.append(entry.id)
	assert(clerk_ids_after.has("wage_claim_inquiry"), "the county filing topic must appear once the wage lead and postal trail are both in evidence")

	# --- County clerk: repeat defaults must play after initial six-deceased notice ---
	state.coat = "Police coat"
	var clerk_badge_ctx = Runtime.make_context(state, dstate)
	var clerk_first = Runtime.enter(defs.county_clerk, clerk_badge_ctx, dstate)
	_play(clerk_first, state, dstate)
	assert(clerk_first.session.tag == "clerk_badge", "initial encounter with badge must deliver the six-deceased notice")
	var clerk_repeat_badge = Runtime.enter(defs.county_clerk, clerk_badge_ctx, dstate)
	assert(not clerk_repeat_badge.cards.is_empty(), "Mr. Pence must not become a totem pole after the initial notice")
	assert(clerk_repeat_badge.session.tag in ["clerk_repeat_badge_notices", "clerk_repeat_badge_requisition", "clerk_repeat_badge_entries"], "repeat encounter with badge must play a badge repeat default")
	state.coat = "Plain wool coat"
	var clerk_repeat_plain = Runtime.enter(defs.county_clerk, Runtime.make_context(state, dstate), dstate)
	assert(not clerk_repeat_plain.cards.is_empty(), "Mr. Pence must speak to plain-coated Walter on repeat visits")
	assert(clerk_repeat_plain.session.tag in ["clerk_repeat_plain_dockets", "clerk_repeat_plain_vaults", "clerk_repeat_plain_quiet"], "repeat encounter with plain coat must play a plain repeat default")

	print("DIALOGUE CONTENT PASS: gatehouse_boy/coroners_assistant/groundskeeper/gardener/old_woman/mrs_almy/odell/father_behan all reverse-engineered, parsing clean and gating correctly against real game state")
	quit(0)

# Test-only stand-in for consuming every displayed card in a segment.
func _play(segment: Dictionary, state, dstate) -> void:
	load("res://scripts/shared/dialogue_runtime.gd").commit_through(segment, state, dstate, segment.cards.size())
