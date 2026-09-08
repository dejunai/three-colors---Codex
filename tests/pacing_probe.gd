extends SceneTree

var words = 0
var cards_read = 0
var g:Node

func _initialize() -> void:
	call_deferred("run")

func read_text(value:String) -> void:
	words += value.replace("\n"," ").split(" ",false).size()

func drain() -> void:
	while g.page=="dialogue":
		var card=g.dialogue.cards[g.dialogue.index]
		read_text(str(card[0])+" "+str(card[1]))
		cards_read+=1
		g._next_card()

func choose(prefix:String) -> void:
	for label in g.content.find_children("*","Label",true,false): read_text(label.text)
	for button in g.content.find_children("*","Button",true,false):
		if button.text.begins_with(prefix):
			read_text(button.text)
			button.pressed.emit()
			return
	assert(false,"Missing choice: "+prefix)

func walk(points:Array) -> void:
	g._close()
	g.yaw=0
	await physics_frame
	await physics_frame
	for point in points: await g._walk_to(point)

func speak(id:String) -> void:
	g._interact(id)
	drain()

func report(section:String) -> void:
	var movement=g.state.minutes*60.0
	print("PACING %s: cumulative traversal=%.1fs; text=%d words; cards=%d; estimated total=%.2f–%.2f min (240–180 wpm plus 1s/card)" % [section,movement,words,cards_read,(movement+words/4.0+cards_read)/60.0,(movement+words/3.0+cards_read)/60.0])

func estate_to_town() -> void:
	await walk([Vector3(-8,0,-18),Vector3(-5,0,-11),Vector3(-5,0,1),Vector3(0,0,7),Vector3(0,0,39)])
	speak("exit")

func lounge_visit() -> void:
	await walk([Vector3(0,0,8),Vector3(-27,0,8),Vector3(-27,0,15)])
	speak("street_estate")
	await walk([Vector3(0,0,7),Vector3(-5,0,1),Vector3(-5,0,-11),Vector3(-8,0,-18),Vector3(-10,0,-18)])
	speak("service_entrance")
	await walk([Vector3(0,0,-3.3)])
	speak("barman")

func room_sleep() -> void:
	await walk([Vector3(18,0,-5.3)])
	speak("street_room")
	await walk([Vector3(-3.4,0,-2.2)])
	speak("sleep")

func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	g=scene.chapter
	g.test_mode=true
	g._new_game()
	drain()
	await walk([Vector3(-1,0,31)])
	speak("boy")
	await walk([Vector3(0,0,7),Vector3(0,0,1)])
	speak("wounds")
	await walk([Vector3(-4,0,-2)])
	speak("watch")
	await walk([Vector3(-6,0,-0.4)])
	speak("knife")
	await walk([Vector3(-12,0,1)])
	speak("gardener")
	await walk([Vector3(-5,0,1),Vector3(6,0,0),Vector3(12,0,-4)])
	speak("assistant")
	await walk([Vector3(23,0,-3.3)])
	speak("eight")
	await walk([Vector3(25.6,0,-4)])
	speak("shoes")
	await walk([Vector3(12,0,-4),Vector3(10,0,-12),Vector3(4,0,-11.5)])
	speak("odell")
	choose("Say nothing")
	await walk([Vector3(7.4,0,-12.7)])
	speak("register")
	await walk([Vector3(-8,0,-18)])
	speak("gas")
	await walk([Vector3(6,0,-12.7)])
	g._report_screen()
	choose("File the observations")
	drain()
	await estate_to_town()
	report("opening incl. all eight opening observations")
	await walk([Vector3(-18,0,-5.3)])
	speak("street_precinct")
	await walk([Vector3(0,0,-1.3)])
	speak("intake")
	await walk([Vector3(0,0,7)])
	speak("interior_exit")
	await walk([Vector3(-1,0,-5.3)])
	speak("street_almy")
	await walk([Vector3(4,0,1),Vector3(4,0,-4.1),Vector3(1.7,0,-3.7)])
	speak("almy")
	choose("Ask for the woman's name")
	drain()
	await walk([Vector3(4,0,-4.1),Vector3(4,0,4.5),Vector3(0,0,7)])
	speak("interior_exit")
	await lounge_visit()
	await walk([Vector3(0,0,7.1)])
	speak("lounge_exit")
	await walk([Vector3(-12.6,0,-16.9)])
	speak("crew")
	await estate_to_town()
	await room_sleep()
	while g.page=="montage":
		for label in g.content.find_children("*","Label",true,false): read_text(label.text)
		cards_read+=1
		g.content.find_children("*","Button",true,false)[0].pressed.emit()
	report("through second-visit montage")
	g.state.coat="Plain wool coat"
	g._refresh_outfit()
	await walk([Vector3(0,0,7)])
	speak("interior_exit")
	await lounge_visit()
	# All three existing steward topics included, despite being optional for progression.
	for prefix in ["Ask what the members","Ask what Kessler","Ask about the old pantry"]:
		choose(prefix)
		drain()
	await walk([Vector3(0,0,7.1)])
	speak("lounge_exit")
	await estate_to_town()
	await room_sleep()
	choose("Continue to the service passage")
	drain()
	assert(g.state.world=="tunnel")
	report("opening + Pickman Street + visits + tunnel entry")
	quit()
