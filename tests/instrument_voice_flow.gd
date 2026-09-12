extends SceneTree

const SILENT_SPEAKERS = ["WALTER CORWIN", "WALTER'S NOTEBOOK", "THE KITCHEN WING YARD", "THE COVERING LETTER", "THE DAY BOOK", "THE GAZETTE — CORRECTION", "OUTSIDE THE SHUTTERED SHOP", "A CLEAN READ", "THE SMOKING LOUNGE"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var manifest_ids: Dictionary = Runtime._known_voice_ids()
	assert(manifest_ids.size() == 144, "Expected the complete instrument voice manifest")
	for cue in manifest_ids:
		assert(ResourceLoader.exists("res://assets/audio/instrument_voices/" + cue + ".wav"), "Manifest asset missing: " + cue)
	var unknown_errors: Array = []
	Runtime._validate_voice_cues("VOICE: trombone_typo_medium_v1\nTEST: \"No.\"", unknown_errors)
	assert(unknown_errors.size() == 1 and String(unknown_errors[0].message).contains("Unknown VOICE cue"), "Unknown cue must fail manifest validation")
	var voice_cues: Array[String] = []
	var unvoiced_npc_lines: Array[String] = []
	var speaker_instruments: Dictionary = {}
	for filename in DirAccess.get_files_at("res://dialogue"):
		if not filename.ends_with(".dialogue"): continue
		var definition = Runtime.load_npc("res://dialogue/" + filename)
		assert(definition.errors.is_empty(), "%s: %s" % [filename, definition.errors])
		if filename == "background_npc_template.dialogue": continue
		for topic in definition.topics:
			_audit_voice_cues(topic.steps, filename, voice_cues, unvoiced_npc_lines, speaker_instruments)
	for cue in voice_cues:
		assert(cue.is_valid_identifier())
		assert(ResourceLoader.exists("res://assets/audio/instrument_voices/" + cue + ".wav"), "Missing " + cue)
	assert(unvoiced_npc_lines.is_empty(), "Every authored NPC line must have a voice cue: %s" % [unvoiced_npc_lines])
	assert(not voice_cues.is_empty(), "Expected authored NPC voice cues")
	var fixture = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: violin_cautious_medium_v1\n  TEST: \"One line.\"\n")
	assert(fixture.errors.is_empty())
	var rendered = Runtime.render("test", fixture.topics[0], null)
	assert(rendered.cards[0] == ["TEST", "One line.", "violin_cautious_medium_v1"])
	var fallback_fixture = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  TEST: \"Uncued line.\"\n")
	Runtime._supply_default_voice_cues(fallback_fixture,"test fixture")
	var fallback_rendered = Runtime.render("test",fallback_fixture.topics[0],null)
	assert(fallback_rendered.cards[0] == ["TEST","Uncued line.","trombone_neutral_medium_v1"], "Uncued NPC line must receive an audible fallback")
	for cards in [load("res://town_story.gd").SCENES.intake,load("res://town_story.gd").SCENES.intake_thin,load("res://town_story.gd").SCENES.intake_rich,load("res://town_story.gd").SCENES.supplement]:
		for card in cards:
			if card[0] == "THE INTAKE CLERK": assert(card.size() == 3 and not String(card[2]).is_empty(), "Legacy intake clerk line must be voiced")
	var malformed = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: ../escape\n  TEST: \"No.\"\n")
	assert(not malformed.errors.is_empty(), "Unsafe cue id must fail authoring validation")
	var fork_cue = load("res://scripts/shared/dialogue_lang.gd").parse("NPC: test\nLOCATION: estate\nTOPIC: default\n  GATE: always\n  VOICE: violin_cautious_medium_v1\n  FORK:\n    CHOICE: \"One\"\n      TEST: \"Reply.\"\n")
	assert(not fork_cue.errors.is_empty(), "VOICE before FORK must fail instead of leaking to a later line")

	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	assert(is_instance_valid(g.instrument_voice_player))
	g._play_instrument_voice("trombone_bureaucratic_medium_v1")
	assert(g.instrument_voice_player.playing)
	g._next_card()
	assert(not g.instrument_voice_player.playing, "Advancing must stop the current voice")
	g.settings.instrument_voice_volume = 0.0
	g._play_instrument_voice("trombone_bureaucratic_medium_v1")
	assert(not g.instrument_voice_player.playing, "Zero instrument voice volume must mute cues")
	print("INSTRUMENT VOICE PASS: 144-cue manifest, %d NPC lines, character consistency, playback stop, independent mute" % voice_cues.size())
	quit()

func _audit_voice_cues(steps:Array,filename:String,cues:Array[String],unvoiced:Array[String],instruments:Dictionary) -> void:
	for step in steps:
		if step.kind == "line":
			var speaker = String(step.get("speaker", ""))
			var cue = String(step.get("voice", ""))
			if speaker in SILENT_SPEAKERS or bool(step.get("player", false)):
				assert(cue.is_empty(), "Silent/player line was voiced: %s / %s" % [filename, speaker])
				continue
			if cue.is_empty():
				unvoiced.append("%s / %s" % [filename, speaker])
				continue
			cues.append(cue)
			var instrument = cue.get_slice("_", 0)
			if instruments.has(speaker):
				assert(instruments[speaker] == instrument, "Character changed instruments: %s" % speaker)
			else: instruments[speaker] = instrument
		elif step.kind == "fork":
			for option in step.options: _audit_voice_cues(option.steps, filename, cues, unvoiced, instruments)
