extends SceneTree
const R=preload("res://scripts/shared/dialogue_runtime.gd")
func _initialize() -> void: call_deferred("run")
func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	g.state=g.CaseState.new()
	g.state.started=true
	var catalog=g.scripted_dialogue.catalog
	assert(catalog.definitions.size()>=29, "Every concrete authored NPC must be registered")
	var count=0
	for npc in catalog.definitions:
		var def=catalog.definitions[npc]
		assert(def.errors.is_empty(), str(def.errors))
		for topic in def.topics:
			if topic.steps.is_empty(): continue
			var state=g.CaseState.new()
			var ds=state.dialogue_state
			var result=R.render(npc,topic,ds)
			while true:
				R.commit_through(result,state,ds,result.cards.size())
				if result.fork==null: break
				result=R.resume(result,0)
			var raw=String(topic.get("timing",""))
			var expected=float(raw) if raw.is_valid_float() else R.DEFAULT_MINUTES
			assert(is_equal_approx(state.clock_minutes,360+maxf(0,expected)), npc+":"+topic.id)
			for id in ds.evidence: assert(g.facts.has(id), "Missing case description: "+id)
			var repeat=R.render(npc,topic,ds)
			while true:
				R.commit_through(repeat,state,ds,repeat.cards.size())
				if repeat.fork==null: break
				repeat=R.resume(repeat,0)
			assert(is_equal_approx(state.clock_minutes,360+maxf(0,expected)), "Repeat charged again")
			count+=1
	# Every added resident has at least one reachable location and real interaction.
	for actor in g.scripted_dialogue.extra_actors:
		g.state.clock_minutes=360
		var spot=catalog.slot(actor,g.state)
		assert(not spot.is_empty())
		g._travel(spot[0],spot[1]+Vector3(0,0.1,1.8),0,false)
		assert(g.estate.points.has(actor), "Actor missing: "+actor)
		g._find_focus()
		assert(g.focused==actor,"Actor cannot be focused: "+actor+" got "+g.focused)
		g._interact(actor)
		assert(g.page=="dialogue" or g.page=="witness")
		cards(g)
		g._close()
	# A full museum conversation records the new evidence, then opens the next topic.
	g._travel("museum",Vector3(2,0.1,-2),0,false)
	g.scripted_dialogue.play_topic(g,"local_historian","ship_origin")
	var before=g.state.clock_minutes
	cards(g)
	assert(g.state.clock_minutes==before+7 and g.state.evidence.has("ophion_myth_classical"))
	g._save_game()
	g._load_game()
	assert(g.state.evidence.has("ophion_myth_classical"))
	g._notebook()
	assert(g.page=="notebook")
	g._close()
	g.state.clock_minutes=1200
	g.scripted_dialogue.populate(g)
	assert(not g.estate.points.has("local_historian"),"Residents unavailable at night")
	for entry in g.archive.LINKS:
		var pair=entry.split("|")
		g.state.discover(pair[0])
		g.state.discover(pair[1])
		assert(not g.archive._try_link(g,pair[0],pair[1]).is_empty())
		assert(g.facts.has(pair[0]) and g.facts.has(pair[1]))
	print("DIALOGUE CATALOG PASS: ",catalog.definitions.size()," NPCs, ",count," topics; numeric minutes, default cost, no repeat farming, evidence descriptions, reachable scheduled actors, notebook, links and save")
	quit()
