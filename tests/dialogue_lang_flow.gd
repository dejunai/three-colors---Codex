extends SceneTree

# Standalone check for the dialogue authoring format, runnable directly:
#   godot --headless --path . --script res://tests/dialogue_lang_flow.gd
# No chapter context needed — this exercises scripts/shared/dialogue_lang.gd
# and scripts/shared/dialogue_runtime.gd against the real dialogue/*.dialogue
# content, not through chapter_one.gd's --qa argument parsing.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var Lang = load("res://scripts/shared/dialogue_lang.gd")
	var CaseState = load("res://case_state.gd")
	var DialogueState = load("res://scripts/shared/dialogue_state.gd")

	var behan_path = "res://tests/fixtures/dialogue/father_behan.dialogue"
	var odell_path = "res://tests/fixtures/dialogue/odell.dialogue"
	var steward_path = "res://tests/fixtures/dialogue/steward.dialogue"

	var state = CaseState.new()
	var dstate = DialogueState.new()

	# --- permanent exclusion and menu visibility ---
	var behan_def = Runtime.load_npc(behan_path)
	assert(behan_def.errors.is_empty(), "father_behan.dialogue must parse without errors: %s" % str(behan_def.errors))
	var ctx = Runtime.make_context(state, dstate)
	var behan_menu = Runtime.menu(behan_def, ctx)
	assert(behan_menu.default_topic == null, "father_behan has no 'default' topic authored")
	var ids = []
	for entry in behan_menu.entries: ids.append(entry.id)
	assert(not ids.has("sixth_man"), "GATE: never must keep a topic out of the menu permanently")
	assert(ids.has("club_five") and ids.has("club_invitation") and ids.has("bullets"), "all three always-gated topics must be visible")
	assert(behan_menu.entries.size() == 3, "sixth_man must not count as a fourth entry")

	# --- linear CHOICE content and inline NOTEBOOK effect ---
	var invitation = Runtime.play_topic(behan_def, dstate, "club_invitation")
	_play(invitation, state, dstate)
	assert(invitation.fork == null, "club_invitation has no FORK, must resolve fully in one call")
	var found_why = false
	for card in invitation.cards:
		if card[0] == "WALTER CORWIN" and card[1] == "Why?": found_why = true
	assert(found_why, "CHOICE lines must render as Walter's own spoken line")
	var fact_found = false
	for id in dstate.facts:
		if dstate.facts[id].begins_with("A refusal offered"): fact_found = true
	assert(fact_found, "NOTEBOOK effect must write its text directly, no separate facts table")
	_play(Runtime.play_topic(behan_def, dstate, "club_five"), state, dstate)
	var recorded_entry = Runtime.menu(behan_def, Runtime.make_context(state, dstate)).entries.filter(func(entry): return entry.id == "club_five")[0]
	assert(recorded_entry.label.ends_with("  · recorded"), "A completed repeatable dialogue topic must be marked recorded")
	dstate.complete_topic("father_behan", "tagged_complete")
	assert(Runtime._menu_topic_recorded(behan_def, {"id":"unfinished", "tag":"tagged_complete"}, Runtime.make_context(state, dstate)), "A completed TAG must also mark its menu topic recorded")

	# --- cross-NPC tally: "ask N people about xyz" ---
	assert(dstate.topic_count("bullets") == 0, "bullets topic not yet completed by anyone")
	_play(Runtime.play_topic(behan_def, dstate, "bullets"), state, dstate)
	assert(dstate.topic_count("bullets") == 1, "one distinct NPC has completed the shared 'bullets' topic id")
	var odell_def = Runtime.load_npc(odell_path)
	assert(odell_def.errors.is_empty(), "odell.dialogue must parse without errors: %s" % str(odell_def.errors))

	# --- FORK branching: halts for an unresolved choice, resumes once given ---
	var first_pass = Runtime.play_topic(odell_def, dstate, "bullets")
	_play(first_pass, state, dstate)
	assert(first_pass.fork != null, "the FORK must halt rendering until a choice is supplied")
	assert(first_pass.fork.options == ["All six through the same spot? That's debris?", "Maybe you're right."], "fork options must be exposed in author order")
	assert(dstate.topic_count("bullets") == 1, "an unresolved fork must not mark the topic complete or tally it yet")
	var resumed = Runtime.resume(first_pass, 0)
	_play(resumed, state, dstate)
	assert(resumed.fork == null, "supplying a choice index must resume to completion")
	var found_pressed = false
	for card in resumed.cards:
		if card[1] == "Coincidence. Odd ones happen.": found_pressed = true
	assert(found_pressed, "the chosen branch's lines must play")
	var found_other_branch = false
	for card in resumed.cards:
		if card[1] == "Good. Keep thinking that.": found_other_branch = true
	assert(not found_other_branch, "the unchosen branch's lines must not play")
	assert(dstate.topic_count("bullets") == 2, "a second, distinct NPC completing the same topic id must grow the tally")
	_play(Runtime.play_topic(behan_def, dstate, "bullets"), state, dstate)
	assert(dstate.topic_count("bullets") == 2, "re-completing the same NPC's topic must not double-count")

	# --- doc-only topic must not surface, and empty steps ---
	var odell_menu = Runtime.menu(odell_def, ctx)
	var odell_ids = []
	for entry in odell_menu.entries: odell_ids.append(entry.id)
	assert(not odell_ids.has("exit_paperwork"), "a topic with no dialogue lines must never surface")

	# --- mutually exclusive 'default' resolution, driven purely by GATE ---
	var steward_def = Runtime.load_npc(steward_path)
	assert(steward_def.errors.is_empty(), "steward.dialogue must parse without errors: %s" % str(steward_def.errors))
	var stew_ctx = Runtime.make_context(state, dstate)
	var early = Runtime.enter(steward_def, stew_ctx, dstate)
	_play(early, state, dstate)
	assert(early.cards[0][1] == "Polite. Attentive. Gives nothing.", "first visit must resolve to the low-visit-count default")
	assert(dstate.visit_count("steward") == 1, "enter() must count the visit")
	_play(Runtime.enter(steward_def, stew_ctx, dstate), state, dstate)
	assert(dstate.visit_count("steward") == 2, "each enter() call counts a separate visit")
	state.coat = "Plain wool coat"
	dstate.visit("mrs_almy")
	var opened_up = Runtime.enter(steward_def, stew_ctx, dstate)
	_play(opened_up, state, dstate)
	assert(dstate.visit_count("steward") == 3, "third enter() reaches the threshold")
	var found_return_line = false
	for card in opened_up.cards:
		if card[1] == "You came back. Alone this time.": found_return_line = true
	assert(found_return_line, "once visit_count>=3, coat=plain, and spoken_to(mrs_almy) all hold, the second default must win")

	# --- fuzzy '=' matching and numeric comparators directly ---
	var gate = Lang._parse_gate("coat = plain")
	assert(Lang.evaluate(gate, stew_ctx), "'coat = plain' must match the full stored string 'Plain wool coat'")
	var below = Lang._parse_gate("visit_count(steward) < 3")
	assert(not Lang.evaluate(below, stew_ctx), "visit_count is already 3, so < 3 must now be false")

	# --- npc_done sugar and weighted repeat greetings ---
	assert(Lang.evaluate(Lang._parse_gate("npc_done(steward)"), ctx), "npc_done must alias topic_done(npc, default): steward's default topic already completed above")
	assert(not Lang.evaluate(Lang._parse_gate("npc_done(nobody_yet)"), ctx), "npc_done must be false before that NPC's default topic completes")
	var weighted = Lang.parse("NPC: chatter\nLOCATION: test\nTOPIC: default\n  GATE: always\n  WEIGHT: 3\n  ONE: \"First.\"\nTOPIC: default\n  GATE: always\n  WEIGHT: 1\n  TWO: \"Second.\"\n")
	assert(weighted.errors.is_empty(), "positive WEIGHT metadata must parse on defaults")
	var chatter_state = DialogueState.new()
	var first_chatter = Runtime.enter(weighted, Runtime.make_context(state, chatter_state), chatter_state)
	var second_chatter = Runtime.enter(weighted, Runtime.make_context(state, chatter_state), chatter_state)
	var third_chatter = Runtime.enter(weighted, Runtime.make_context(state, chatter_state), chatter_state)
	assert(first_chatter.cards[0][1] != second_chatter.cards[0][1], "weighted defaults must avoid an immediate repeat")
	assert(second_chatter.cards[0][1] != third_chatter.cards[0][1], "repeat avoidance must continue across interactions")
	assert(int(first_chatter.topic_index) in [0, 1] and int(second_chatter.topic_index) in [0, 1], "enter() must expose the exact selected default index")
	var bad_weight = Lang.parse("NPC: bad\nLOCATION: test\nTOPIC: question\n  GATE: always\n  WEIGHT: 2\n  TEST: \"No.\"\nTOPIC: default\n  GATE: always\n  WEIGHT: 0\n  TEST: \"No.\"\n")
	assert(bad_weight.errors.size() == 2, "WEIGHT must be positive and limited to default topics")

	# --- omitted default TIME is free; explicit zero wins; inquiries retain fallback ---
	var timing = Lang.parse("NPC: timing\nLOCATION: test\nTOPIC: default\n  GATE: always\n  TEST: \"Hello.\"\nTOPIC: default\n  GATE: always\n  TAG: explicit_zero\n  TIME: 0\n  TEST: \"Still free.\"\nTOPIC: inquiry\n  GATE: always\n  TEST: \"A question.\"\n")
	var timing_state = DialogueState.new()
	var clock_before = state.clock_minutes
	_play(Runtime.render("timing", timing.topics[0], timing_state), state, timing_state)
	assert(state.clock_minutes == clock_before, "An unpriced default must cost zero minutes")
	_play(Runtime.render("timing", timing.topics[1], timing_state), state, timing_state)
	assert(state.clock_minutes == clock_before, "Explicit TIME: 0 must be honored")
	_play(Runtime.render("timing", timing.topics[2], timing_state), state, timing_state)
	assert(state.clock_minutes == clock_before + Runtime.DEFAULT_MINUTES, "An unpriced substantive topic must use DEFAULT_MINUTES")

	print("DIALOGUE LANG PASS: menu/never/always, linear CHOICE + inline NOTEBOOK, cross-NPC topic tally, FORK branching and resume, doc-only topics hidden, gated and weighted defaults, greeting timing, fuzzy gate matching")
	quit(0)

# Test-only stand-in for consuming every displayed card in a segment.
func _play(segment: Dictionary, state, dstate) -> void:
	load("res://scripts/shared/dialogue_runtime.gd").commit_through(segment, state, dstate, segment.cards.size())
