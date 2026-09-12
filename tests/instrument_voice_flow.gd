extends SceneTree

const ESTATE_FILES = ["gatehouse_boy", "coroners_assistant", "gardener", "groundskeeper", "odell"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var voice_cues: Array[String] = []
	for filename in DirAccess.get_files_at("res://dialogue"):
		if not filename.ends_with(".dialogue"): continue
		var definition = Runtime.load_npc("res://dialogue/" + filename)
		assert(definition.errors.is_empty(), "%s: %s" % [filename, definition.errors])
		var before = voice_cues.size()
		for topic in definition.topics:
			_collect_voice_cues(topic.steps, voice_cues)
		if voice_cues.size() > before:
			assert(ESTATE_FILES.has(filename.trim_suffix(".dialogue")), "Audition escaped estate scope: " + filename)
	for cue in voice_cues:
		assert(cue.is_valid_identifier())
		assert(ResourceLoader.exists("res://assets/audio/instrument_voices/" + cue + ".wav"), "Missing " + cue)
	assert(voice_cues.size() == 17, "Expected the limited estate audition set")
	var fixture = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: trombone_cautious_v1\n  TEST: \"One line.\"\n")
	assert(fixture.errors.is_empty())
	var rendered = Runtime.render("test", fixture.topics[0], null)
	assert(rendered.cards[0] == ["TEST", "One line.", "trombone_cautious_v1"])
	var malformed = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: ../escape\n  TEST: \"No.\"\n")
	assert(not malformed.errors.is_empty(), "Unsafe cue id must fail authoring validation")
	var fork_cue = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: trombone_cautious_v1\n  FORK:\n    CHOICE: \"One\"\n      TEST: \"Reply.\"\n")
	assert(not fork_cue.errors.is_empty(), "VOICE before FORK must fail instead of leaking to a later line")

	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	assert(is_instance_valid(g.instrument_voice_player))
	g._play_instrument_voice("trombone_bureaucratic_v1")
	assert(g.instrument_voice_player.playing)
	g._next_card()
	assert(not g.instrument_voice_player.playing, "Advancing must stop the current voice")
	g.settings.instrument_voice_volume = 0.0
	g._play_instrument_voice("trombone_bureaucratic_v1")
	assert(not g.instrument_voice_player.playing, "Zero instrument voice volume must mute cues")
	print("INSTRUMENT VOICE PASS: DSL, estate cues, asset safety, playback stop, independent mute")
	quit()

func _collect_voice_cues(steps:Array,cues:Array[String]) -> void:
	for step in steps:
		if step.kind == "line" and not String(step.get("voice", "")).is_empty(): cues.append(String(step.voice))
		elif step.kind == "fork":
			for option in step.options: _collect_voice_cues(option.steps,cues)
