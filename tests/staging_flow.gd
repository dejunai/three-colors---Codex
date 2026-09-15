extends RefCounted

# gatehouse_boy.dialogue's post-completion pool: estate_complete draws from a
# weighted pair of variants (plain coat vs. not), and the plain-coat pair's
# "boy_return_cold" entry opens on an unlabelled beat before THE GATEHOUSE BOY
# speaks — so check across every rendered card, not just card[0].
const BOY_RETURN_TEXTS = [
	"You took your star off, mister. Are you walking back to town along the ditch?",
	"The boy shivers in his thin coat, watching the empty carriage drive.",
	"The gardener's still down by the hedge. Nobody's come up from town yet.",
	"The wagon's been and gone. The captain and the coroner's man went right with the bodies.",
	"I'm not supposed to leave the gate, Officer. That's what the captain told me."
]

func _has_boy_return_text(g:Node) -> bool:
	for card in g.dialogue.cards:
		if BOY_RETURN_TEXTS.has(card[1]): return true
	return false

func cards(g:Node) -> void:
	while g.page == "dialogue": g._next_card()

func advance(g:Node) -> void:
	var buttons=g.content.find_children("*","Button",true,false)
	assert(not buttons.is_empty())
	buttons[0].pressed.emit()

func settle(g:Node) -> void:
	await g.get_tree().physics_frame
	await g.get_tree().physics_frame

func run(g:Node) -> void:
	await settle(g)
	g.state=g.CaseState.new()
	g.state.started=true
	g._travel("estate",Vector3(0,0.1,7))
	assert(g.estate.scene_bodies.size()==8)
	for body in g.estate.scene_bodies: assert(body.visible)
	for id in ["odell","assistant"]:
		assert(g.estate.opening_staff[id].visible and g.estate.points.has(id))
	g._interact("boy")
	assert(g.dialogue.cards[0][0]=="THE GATEHOUSE BOY" and g.dialogue.cards[0][1].contains("ROSE GARDEN"))
	cards(g)
	g._interact("boy")
	assert(g.dialogue.cards[0][0]=="THE GATEHOUSE BOY" and g.dialogue.cards[0][1].contains("gap in the hedge"))
	cards(g)
	assert(not g.estate.points.has("barman") and not g.estate.points.has("crew"))
	assert(g.estate.points.has("service_entrance"))
	g._interact("barman")
	g._estate_observation("club_talk",true)
	assert(g.page=="play" and not g.state.evidence.has("club_talk"))
	g._interact("service_entrance")
	cards(g)
	g._travel("lounge",Vector3.ZERO)
	assert(g.state.world=="estate","Neither interaction nor direct travel bypasses Mrs. Almy")
	g.state.coat="Plain wool coat"
	g._interact("gardener")
	cards(g)
	assert(not g.state.statements.has("The gardener saw the woman at the service door. Ask the steward."))
	g._interact("odell")
	cards(g)
	advance(g)
	g._write_report("Observations filed","report_routine")
	cards(g)
	g._finish()
	cards(g)
	g._travel("estate",Vector3(0,0.1,35))
	for body in g.estate.rose_bodies: assert(not body.visible)
	for body in g.estate.birch_bodies: assert(body.visible)
	for id in ["wounds","watch","knife"]: assert(not g.estate.points.has(id))
	var evidence=g.state.evidence.duplicate()
	g._interact("wounds")
	assert(g.state.evidence==evidence and g.page=="play")
	assert(g.estate.gardener_actor.position==Vector3(-4,0,12))
	for id in ["odell","assistant"]:
		assert(not g.estate.opening_staff[id].visible and not g.estate.points.has(id))
		g._interact(id)
		assert(g.page=="play")
	assert(not g.estate.points.has("report") and not g.estate.opening_report.visible)
	g._interact("report")
	assert(g.page=="play")
	g._interact("boy")
	assert(g.page=="dialogue" and _has_boy_return_text(g))
	cards(g)
	g._save_game()
	g._load_game()
	for body in g.estate.rose_bodies: assert(not body.visible)
	for body in g.estate.birch_bodies: assert(body.visible)
	for id in ["odell","assistant"]:
		assert(not g.estate.opening_staff[id].visible and not g.estate.points.has(id))
		g._interact(id)
		assert(g.page=="play")
	g._interact("boy")
	assert(g.page=="dialogue" and _has_boy_return_text(g))
	cards(g)
	g.yaw=0
	await settle(g)
	await g._walk_to(Vector3(0,0,15))
	await g._walk_to(Vector3(-3.5,0,12))
	assert(g.focused=="gardener" and g.estate.gardener_actor.visible,"Returning players can reach the gardener from the drive")
	g._interact("gardener")
	cards(g)
	assert(g.state.statements.has("The gardener saw the woman at the service door. Ask the steward."))
	g._travel("room",Vector3(0,0.1,6))
	g._interact("sleep")
	assert(g.state.day==1 and g.state.steward_visits==0 and g.page=="case")
	g._travel("precinct",Vector3(0,0.1,6))
	g._intake()
	cards(g)
	g._travel("boardinghouse",Vector3(0,0.1,6))
	g._interact("almy")
	cards(g)
	advance(g)
	cards(g)
	assert(g.state.visited.has("almy") and g.state.evidence.has("naomi"))
	g._travel("estate",Vector3(-8,0.1,-18))
	await settle(g)
	await g._walk_to(Vector3(-10,0,-18))
	assert(g.focused=="service_entrance","Staff entrance reachable through actual collision")
	g._interact("service_entrance")
	await settle(g)
	await g._walk_to(Vector3(0,0,-3.3))
	assert(g.focused=="barman","Steward is reachable inside the lounge")
	g._interact("barman")
	cards(g)
	assert(g.state.steward_visits==1 and not g.state.evidence.has("club_talk"))
	g._save_game()
	g._load_game()
	assert(g.state.world=="lounge" and g.state.steward_visits==1)
	for i in 3:
		g._interact("barman")
		cards(g)
	assert(g.state.steward_visits==1,"Repeat conversations do not count as another day")
	g._barman_menu()
	cards(g)
	g._estate_observation("pantry_lead",true)
	assert(not g.state.evidence.has("pantry_lead"))
	g._close()
	await g._walk_to(Vector3(0,0,7.1))
	assert(g.focused=="lounge_exit")
	g._interact("lounge_exit")
	await settle(g)
	assert(g.state.lounge_exited and g.estate.points.has("crew"))
	g.yaw=0
	await g._walk_to(Vector3(-13.5,0,-12.0))
	assert(g.focused=="crew")
	g._interact("crew")
	cards(g)
	g._save_game()
	g._load_game()
	assert(g.estate.points.has("crew"))
	g._travel("room",Vector3(0,0.1,6))
	g._interact("sleep")
	assert(g.page=="play" and g.state.day==2 and g.state.montage_index==-1)
	var before=g.state.evidence.duplicate()
	g._travel("lounge",Vector3(0,0.1,6),0,false)
	g._interact("barman")
	cards(g)
	assert(g.state.day==2 and g.state.steward_visits==2)
	assert(g.state.evidence==before,"The enacted second visit does not manufacture testimony")
	g._travel("room",Vector3(0,0.1,6),0,false)
	g._interact("sleep")
	assert(g.page=="play" and g.state.day==3 and g.state.steward_visits==2)
	g._save_game()
	g._load_game()
	assert(g.state.day==3 and g.state.steward_visits==2)
	g._travel("estate",Vector3(-10,0.1,-18))
	g._interact("service_entrance")
	g.state.coat="Police coat"
	g._interact("barman")
	cards(g)
	assert(g.state.steward_visits==2 and g.page=="play")
	g.state.coat="Plain wool coat"
	g._refresh_outfit()
	g._interact("barman")
	cards(g)
	assert(g.state.steward_visits==3 and g.page=="witness")
	advance(g)
	cards(g)
	assert(g.state.evidence.has("club_talk"))
	# Every gate independently blocks the information path, even via direct calls.
	var ready=g.state.pack().duplicate(true)
	for missing in ["almy","day","visits","coat"]:
		g.state.restore(ready)
		if missing=="almy": g.state.visited.erase("almy")
		if missing=="day": g.state.day=1
		if missing=="visits": g.state.steward_visits=1
		if missing=="coat": g.state.coat="Police coat"
		g._close()
		g._interact("pantry_lead")
		assert(not g.state.evidence.has("pantry_lead") and g.page=="play")
		g._estate_observation("pantry_lead",true)
		assert(not g.state.evidence.has("pantry_lead") and g.page=="play")
	g.state.restore(ready)
	g._save_game()
	g._load_game()
	g._interact("barman")
	assert(g.page=="dialogue","A restored steward revisit begins with authored repeat chatter")
	cards(g)
	assert(g.page=="witness","Completing restored repeat chatter returns to the steward topic menu")
	# Notebook has exactly one close button and does not mutate any serialized field.
	g.state.record_link("same_door")
	for count in [0,6,9]:
		g.state.evidence.clear()
		g.state.links.clear()
		for id in g.facts.keys().slice(0,count): g.state.discover(id)
		var prior=g.state.pack().duplicate(true)
		g._notebook()
		var label_text=""
		for label in g.content.find_children("*","Label",true,false): label_text+=label.text
		assert(label_text.contains("CAUSE UNRESOLVED"))
		var buttons=g.content.find_children("*","Button",true,false)
		assert(buttons.size()==1)
		buttons[0].pressed.emit()
		assert(g.state.pack()==prior)
	g.state.restore(ready)
	g.state.record_link("same_door")
	g._notebook()
	var text=""
	for label in g.content.find_children("*","Label",true,false): text+=label.text
	assert(text.contains("THE GROUNDSKEEPER AND THE STEWARD"))
	for destination in ["estate","town","precinct","boardinghouse","room","lounge"]:
		g._travel(destination,Vector3(0,0.1,6))
		assert(g.state.world==destination)
	# Existing completed saves retain their progress; unfinished saves start the bridge.
	var old=g.CaseState.new()
	assert(old.restore({"version":4,"finished":true,"evidence":["naomi"]}))
	assert(old.day==3 and old.steward_visits==3 and old.evidence==["naomi"])
	assert(old.restore({"version":4,"visited":["barman"]}))
	assert(old.day==1 and old.steward_visits==1)
	g._travel("room",Vector3(0,0.1,6))
	g._interact("sleep")
	cards(g)
	g.content.find_children("*","Button",true,false)[0].pressed.emit()
	g.content.find_children("*","Button",true,false)[0].pressed.emit()
	assert(g.state.finished and g.page=="ending")
	g._begin_tunnel()
	cards(g)
	assert(g.state.world=="tunnel")
	print("STAGING PASS: service-entry gates; rose bodies removed; birches retained on same-day revisit/load; reachable optional gardener; departed staff; boy repeat/return dialogue; enacted Day 2 and three steward visits; no repeat farming; coat gate; groundskeeper on exit; immutable notebook; legacy migration; revisits and tunnel continuation")
	g.get_tree().quit()
