extends SceneTree

# Live-content audit for the object system, runnable directly:
#   godot --headless --path . --script res://tests/object_content_flow.gd
# Unlike object_lang_flow.gd/object_template_flow.gd (pure grammar/runtime, inline
# fixtures), this scans the REAL shipped objects/*.object files and cross-checks
# them against chapter_one.gd's own wiring, plus drives one live FORK through the
# actual chapter_one_objects.gd adapter inside a real main.tscn instance.

const ObjectRuntime = preload("res://scripts/shared/object_runtime.gd")
const ObjectLang = preload("res://scripts/shared/object_lang.gd")
const Story = preload("res://story.gd")
const TownStory = preload("res://town_story.gd")
const TunnelStory = preload("res://tunnel_story.gd")

# Single source of truth this test checks the real files against: every id
# chapter_one.gd's objects.sync_points()/objects.interact() calls expect a given
# location's .object file to define. Update this alongside chapter_one.gd's own
# wiring so drift between the two is caught here, not discovered live.
const LIVE_FILES = {
	"estate": ["wounds", "watch", "knife", "eight", "shoes", "gas", "register"],
	"town": ["gazette", "lodging", "exemption", "morgue_tables"],
	"tunnel": ["tunnel_record"],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_parse_and_wiring()
	await _check_live_fork()
	await process_frame # let queue_free()'d UI nodes from the fork panel actually clear
	print("PASS: live object content audits clean; parse errors, EVIDENCE/FACTS coverage, chapter_one.gd wiring parity, and a live FORK all verified")
	quit(0)

func _check_parse_and_wiring() -> void:
	var known_facts: Dictionary = {}
	for id in Story.FACTS: known_facts[id] = true
	for id in TownStory.FACTS: known_facts[id] = true
	for id in TunnelStory.FACTS: known_facts[id] = true
	for location in LIVE_FILES:
		var path = "res://objects/%s.object" % location
		var def = ObjectRuntime.load_location(path)
		assert(def.errors.is_empty(), "%s must parse without errors: %s" % [path, str(def.errors)])
		assert(String(def.location) == location, "%s's LOCATION header must match its filename" % path)
		var known = ObjectRuntime.known_ids(def)
		for id in LIVE_FILES[location]:
			assert(known.has(id), "%s is wired in chapter_one.gd but %s has no OBJECT block for it" % [id, path])
		for obj in def.objects:
			for step in obj.steps:
				if String(step.get("kind", "")) == "evidence":
					assert(known_facts.has(step.id), "%s.%s writes EVIDENCE: %s, which has no FACTS entry — g.facts would never mirror it into case_state.evidence" % [location, obj.id, step.id])

# Exercises FORK/OUTCOME/TAKE through the real chapter_one_objects.gd adapter, not
# just object_runtime.gd directly — no live object currently authors a FORK, so this
# seeds a synthetic definition straight into ObjectRuntime's path cache (same trick
# as swapping a preload) rather than writing a throwaway file under objects/.
func _check_live_fork() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.playthrough_log.endpoint_url = ""
	g.state = g.CaseState.new()
	var fork_source = "LOCATION: test_fork_location\nOBJECT: chest\n  GATE: always\n  [A locked chest.]\n  FORK:\n    CHOICE: \"Force it open.\"\n      NOTEBOOK: chest_note | \"The chest was forced.\"\n      EVIDENCE: chest_forced\n      TAKE: chest_key\n      OUTCOME: chest_response = forced\n    CHOICE: \"Leave it alone.\"\n      OUTCOME: chest_response = left\n"
	var parsed = ObjectLang.parse(fork_source)
	assert(parsed.errors.is_empty(), str(parsed.errors))
	var fake_path = "res://objects/test_fork_location.object"
	ObjectRuntime._cache[fake_path] = parsed
	assert(g.objects.interact(g, "test_fork_location", "chest"), "interact() must accept a known, available id")
	assert(g.rig._model_animation_base == "Examine", "opening an authored object must play Walter's Examine action")
	while g.page == "dialogue": g._next_card()
	assert(g.page == "witness", "reaching an unresolved FORK must present a live choice screen, not silently close")
	var options = g.content.find_children("*", "Button", true, false)
	assert(options.size() == 2, "both authored CHOICE options must render as buttons")
	options[0].pressed.emit()
	while g.page == "dialogue": g._next_card()
	assert(g.state.has_item("chest_key"), "TAKE on the chosen branch must reach case_state.inventory through the live adapter")
	assert(g.state.dialogue_state.outcome_is("chest_response", "forced"), "OUTCOME must commit through the shared dialogue_state store via the live adapter")
	assert(g.page == "play", "a finished object with no further cards must close back to play")
	assert(g.rig._model_animation_base == "Idle", "finishing the object must return Walter to Idle")
	ObjectRuntime._cache.erase(fake_path)
