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

	var behan_path = "res://dialogue/father_behan.dialogue"
	var odell_path = "res://dialogue/odell.dialogue"
	var steward_path = "res://dialogue/steward.dialogue"

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
	assert(invitation.fork == null, "club_invitation has no FORK, must resolve fully in one call")
	var found_why = false
	for card in invitation.cards:
		if card[0] == "WALTER CORWIN" and card[1] == "Why?": found_why = true
	assert(found_why, "CHOICE lines must render as Walter's own spoken line")
	var fact_found = false
	for id in dstate.facts:
		if dstate.facts[id].begins_with("A refusal offered"): fact_found = true
	assert(fact_found, "NOTEBOOK effect must write its text directly, no separate facts table")

	# --- cross-NPC tally: "ask N people about xyz" ---
	assert(dstate.topic_count("bullets") == 0, "bullets topic not yet completed by anyone")
	Runtime.play_topic(behan_def, dstate, "bullets")
	assert(dstate.topic_count("bullets") == 1, "one distinct NPC has completed the shared 'bullets' topic id")
	var odell_def = Runtime.load_npc(odell_path)
	assert(odell_def.errors.is_empty(), "odell.dialogue must parse without errors: %s" % str(odell_def.errors))

	# --- FORK branching: halts for an unresolved choice, resumes once given ---
	var first_pass = Runtime.play_topic(odell_def, dstate, "bullets")
	assert(first_pass.fork != null, "the FORK must halt rendering until a choice is supplied")
	assert(first_pass.fork.options == ["All six through the same spot? That's debris?", "Maybe you're right."], "fork options must be exposed in author order")
	assert(dstate.topic_count("bullets") == 1, "an unresolved fork must not mark the topic complete or tally it yet")
	var resumed = Runtime.play_topic(odell_def, dstate, "bullets", [0])
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
	Runtime.play_topic(behan_def, dstate, "bullets")
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
	assert(early.cards[0][1] == "Polite. Attentive. Gives nothing.", "first visit must resolve to the low-visit-count default")
	assert(dstate.visit_count("steward") == 1, "enter() must count the visit")
	Runtime.enter(steward_def, stew_ctx, dstate)
	assert(dstate.visit_count("steward") == 2, "each enter() call counts a separate visit")
	state.coat = "Plain wool coat"
	dstate.visit("mrs_almy")
	var opened_up = Runtime.enter(steward_def, stew_ctx, dstate)
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

	print("DIALOGUE LANG PASS: menu/never/always, linear CHOICE + inline NOTEBOOK, cross-NPC topic tally, FORK branching and resume, doc-only topics hidden, mutually exclusive default resolution, fuzzy gate matching")
	quit(0)
