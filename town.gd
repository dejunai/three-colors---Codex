extends "res://estate.gd"

var location = "town"

func _ready() -> void:
	rng.seed = 1924
	_lighting(location != "town")
	if location == "town": _street()
	else:
		_room_shell()
		match location:
			"precinct": _precinct()
			"boardinghouse": _boardinghouse()
			"room": _corwin_room()

func _lighting(inside:bool) -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("232c2b") if inside else Color("555f5d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a8b0a3")
	env.ambient_light_energy = 0.47 if inside else 0.42
	if not inside:
		env.fog_enabled = true
		env.fog_light_color = Color("64716b")
		env.fog_density = 0.015
	we.environment = env
	add_child(we)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)
	if inside:
		for x in [-4,4]:
			var light = OmniLight3D.new()
			light.position = Vector3(x,3.1,-2)
			light.light_energy = 1.2
			light.omni_range = 11
			add_child(light)
			cylinder(self,Vector3(x,3.3,-2),0.4,0.2,"b3b29f",0.22)

func _door(x:float, title:String, id:String) -> void:
	box(self,Vector3(x,1.55,-7.0),Vector3(1.7,3.1,0.12),"242d2a")
	for dx in [-1,1]: box(self,Vector3(x+dx,1.7,-6.8),Vector3(0.14,3.4,0.25),"b1b09d")
	box(self,Vector3(x,3.5,-6.7),Vector3(2.3,0.23,0.4),"b4b19e")
	sphere(self,Vector3(x+0.57,1.2,-6.82),0.06,"b8b29a")
	lettering(title,Vector3(x,4.25,-6.6),42)
	target(id,"Enter "+title.to_lower(),Vector3(x,0,-5.6))

func _street() -> void:
	box(self,Vector3(0,-0.3,7),Vector3(100,0.5,75),"4b554d",true)
	box(self,Vector3(0,-0.035,8),Vector3(67,0.06,15),"6c766c")
	box(self,Vector3(0,0,-3),Vector3(67,0.1,6.5),"939889")
	box(self,Vector3(0,0,19),Vector3(67,0.1,6),"878e80")
	for z in [0.4,16]: box(self,Vector3(0,0.065,z),Vector3(66,0.13,0.18),"b2b3a1")
	for x in range(-30,32,2): box(self,Vector3(x,0.06,-3),Vector3(0.026,0.015,6),"636f63")
	for i in 370:
		box(self,Vector3(rng.randf_range(-32,32),0.01,rng.randf_range(1,15)),Vector3(0.08,0.02,rng.randf_range(0.1,0.32)),"838c7d")
	# The north side of Pickman Street: ordinary institutions rather than a monumental hub.
	for spec in [[-18,14,8.8,"677568"],[-2,15,10.7,"828c79"],[16,16,9.5,"596b5d"]]:
		var x:float=spec[0]
		var width:float=spec[1]
		var h:float=spec[2]
		box(self,Vector3(x,h/2,-11),Vector3(width,h,7),spec[3],true)
		box(self,Vector3(x,h+0.2,-11),Vector3(width+0.5,0.4,7.5),"333f38")
		for y in [0.4,3.9,h-0.3]: box(self,Vector3(x,y,-7.44),Vector3(width,0.15,0.24),"adb29d")
		for dx in [-4.5,0,4.5]:
			for y in [5.6,8.1]:
				if y>h-1: continue
				box(self,Vector3(x+dx,y,-7.42),Vector3(1.4,1.7,0.12),"2b3933")
				for dy in [-0.92,0,0.92]: box(self,Vector3(x+dx,y+dy,-7.25),Vector3(1.7,0.09,0.17),"b7b7a2")
				for edge in [-0.78,0.78]: box(self,Vector3(x+dx+edge,y,-7.25),Vector3(0.1,1.9,0.17),"a7ae99")
	_door(-18,"PRECINCT 4","street_precinct")
	_door(-1,"ALMY'S BOARDINGHOUSE","street_almy")
	_door(18,"ROOMS ABOVE","street_room")
	lettering("P I C K M A N   S T R E E T",Vector3(-11,1.4,19),35).rotation.y = PI
	# Cobbler's display with a bench and modest shop window.
	box(self,Vector3(23,1.7,-7.2),Vector3(3.8,2.0,0.14),"364a3d")
	lettering("SHOE REPAIRS",Vector3(23,3,-7.0),32)
	for x in [21.8,22.6,23.4,24.2]:
		box(self,Vector3(x,0.8,-6.9),Vector3(0.24,0.22,0.5),"8d977f")
	# Far-side warehouses frame the street but do not imply explorable doors.
	for x in [-24,-10,8,25]:
		box(self,Vector3(x,4.0,28),Vector3(12,8,7),"536156",true)
		box(self,Vector3(x,8.2,28),Vector3(12.6,0.4,7.5),"303f35")
	for x in [-25,-10,7,25]: lamp(Vector3(x,0,0))
	for x in [-20,9]:
		box(self,Vector3(x,0.55,18.2),Vector3(3,0.15,0.7),"6f7e66",true)
		box(self,Vector3(x,0.98,18.6),Vector3(3,0.75,0.14),"6a7962")
		for dx in [-1.1,1.1]: box(self,Vector3(x+dx,0.24,18.2),Vector3(0.12,0.5,0.6),"37483a")
	box(self,Vector3(8.5,0.65,18.2),Vector3(0.55,0.025,0.4),"c5c5ad")
	target("gazette","Read the morning paper",Vector3(8.5,0,17.3))
	lettering("ESTATE ROAD",Vector3(-27,2.4,15.5),38)
	target("street_estate","Return to the Ophion estate",Vector3(-27,0,15))
	# A rectory marker behind which Father Behan will speak plainly, if asked.
	box(self,Vector3(-8.6,0.55,-1.6),Vector3(0.06,1.1,0.06),"3a443a")
	box(self,Vector3(-8.6,0.85,-1.6),Vector3(0.5,0.06,0.06),"3a443a")
	person(Vector3(-8,0,-1),"242423",false).rotation.y=1.8
	target("behan","Speak with Father Behan",Vector3(-8,0,-1))
	person(Vector3(12,0,14),"414f42").rotation.y=-1.4
	for x in [-28,28]: tree(Vector3(x,0,20))

func _room_shell() -> void:
	box(self,Vector3(0,-0.3,0),Vector3(18,0.5,20),"747d6b",true)
	for x in range(-8,9): box(self,Vector3(x,0.001,0),Vector3(0.022,0.015,20),"46563f")
	box(self,Vector3(0,2.1,-8),Vector3(18,4.2,0.3),"7c8975",true)
	for x in [-9,9]: box(self,Vector3(x,2.1,0),Vector3(0.3,4.2,16.3),"75836e",true)
	for x in [-5.3,5.3]: box(self,Vector3(x,2.1,8),Vector3(7.2,4.2,0.3),"6e7e68",true)
	for z in [-7.8,7.8]: box(self,Vector3(0,0.14,z),Vector3(18,0.25,0.16),"344b35")
	for x in [-8.8,8.8]: box(self,Vector3(x,0.14,0),Vector3(0.16,0.25,16),"344b35")
	for x in [-5,5]:
		box(self,Vector3(x,2.35,-7.78),Vector3(2.5,2.3,0.12),"afb9a0")
		for dx in [-1.35,0,1.35]: box(self,Vector3(x+dx,2.35,-7.61),Vector3(0.13,2.55,0.16),"3c533e")
		for dy in [-1.2,0,1.2]: box(self,Vector3(x,2.35+dy,-7.61),Vector3(2.8,0.13,0.16),"3c533e")
	# Cutaway doorway keeps the third-person view into the room clear.
	target("interior_exit","Return to Pickman Street",Vector3(0,0,7.2))

func _desk(pos:Vector3,size:Vector3=Vector3(3,0.16,1.4)) -> void:
	box(self,pos+Vector3(0,0.95,0),size,"687c5c",true)
	for x in [-size.x*0.4,size.x*0.4]:
		box(self,pos+Vector3(x,0.46,0),Vector3(0.15,0.9,size.z*0.8),"3d543d",true)
	box(self,pos+Vector3(-0.5,1.05,0.1),Vector3(0.7,0.04,0.8),"c5c4a8")
	box(self,pos+Vector3(0.5,1.05,0.1),Vector3(0.7,0.07,0.8),"b6bda0")

func _chair(pos:Vector3,angle:float=0) -> void:
	var root=Node3D.new()
	root.position=pos
	root.rotation.y=angle
	add_child(root)
	box(root,Vector3(0,0.5,0),Vector3(0.65,0.12,0.65),"536d4d")
	box(root,Vector3(0,0.95,0.3),Vector3(0.65,0.85,0.1),"536d4d")
	for x in [-0.23,0.23]:
		for z in [-0.23,0.23]: box(root,Vector3(x,0.23,z),Vector3(0.09,0.45,0.09),"3b533b")

func _precinct() -> void:
	lettering("PRECINCT 4  ·  INTAKE",Vector3(0,3.3,-7.6),46)
	_desk(Vector3(0,0,-2.5),Vector3(6.2,0.16,1.4))
	person(Vector3(0.4,0,-4),"78896b",false)
	_chair(Vector3(0,0,-4.2),PI)
	for x in [-7,7]:
		box(self,Vector3(x,1.5,-6),Vector3(1.5,3,2),"4d654b",true)
		for y in [0.5,1.3,2.1]:
			box(self,Vector3(x,y,-4.95),Vector3(1.35,0.65,0.1),"647b59")
			box(self,Vector3(x,y,-4.86),Vector3(0.3,0.07,0.07),"c1c1a1")
	_desk(Vector3(-5,0,1))
	_chair(Vector3(-5,0,2.2))
	for z in [0,2,4]: _chair(Vector3(7,0,z),PI/2)
	box(self,Vector3(6.8,2.3,7.78),Vector3(2.2,1.5,0.1),"374d37")
	target("intake","Submit the estate report",Vector3(0,0,-1.3))
	target("supplement","File additional observations",Vector3(-5,0,2.1))
	lettering("SURVEYS",Vector3(7,3.25,-4.85),28)
	target("survey_drawer","Consult the survey drawer",Vector3(7,0,-3.8))

func _boardinghouse() -> void:
	box(self,Vector3(-5.8,0.6,-2.3),Vector3(3,0.65,1.2),"5c7853",true)
	box(self,Vector3(-5.8,1.2,-2.8),Vector3(3,0.9,0.35),"5c7853")
	_desk(Vector3(1.5,0,-2.3),Vector3(2.8,0.16,1.5))
	person(Vector3(1.7,0,-4.2),"6e865d",false)
	_chair(Vector3(1.5,0,-4.3),PI)
	_chair(Vector3(1.5,0,0))
	for x in [0.9,1.9]:
		cylinder(self,Vector3(x,1.13,-2.6),0.10,0.17,"cac9ad")
		cylinder(self,Vector3(x,1.05,-2.6),0.18,0.03,"b8c09f")
	box(self,Vector3(6.3,0.9,2),Vector3(2.6,1.8,0.9),"556f4c",true)
	box(self,Vector3(6.3,1.84,2),Vector3(0.8,0.07,0.6),"bebea1")
	box(self,Vector3(-6.8,1.4,-6),Vector3(2.8,2.8,1.1),"4d6846",true)
	for y in [0.6,1.3,2.1]:
		box(self,Vector3(-6.8,y,-5.35),Vector3(2.7,0.12,0.15),"a7b494")
		for x in [-7.6,-7,-6.4,-5.9]: cylinder(self,Vector3(x,y+0.2,-5.4),0.12,0.3,"b4c09b")
	box(self,Vector3(0,0.06,3),Vector3(5,0.03,3),"5c7050")
	target("almy","Speak to Mrs. Almy",Vector3(1.7,0,-3.3))
	target("lodging","Examine the meal ledger",Vector3(6.3,0,3.1))

func _corwin_room() -> void:
	# Bed, desk, dresser, and a physical board. Every playable card has an immutable text source.
	box(self,Vector3(-5.5,0.5,-3.1),Vector3(2.6,0.8,4.5),"526c4b",true)
	box(self,Vector3(-5.5,0.94,-3.1),Vector3(2.5,0.18,4.3),"a4b28e")
	box(self,Vector3(-5.5,1.1,-4.6),Vector3(1.6,0.18,0.8),"c2c6a8")
	box(self,Vector3(-5.5,1.2,-5.4),Vector3(2.8,1.3,0.15),"3a5539")
	_desk(Vector3(3.5,0,-4),Vector3(3.8,0.16,1.6))
	_chair(Vector3(3.5,0,-2.7))
	box(self,Vector3(0,2.2,-7.64),Vector3(5.8,2.9,0.19),"374b33")
	box(self,Vector3(0,2.2,-7.50),Vector3(5.4,2.5,0.06),"817d5b")
	for i in 8:
		var x=-2.0+(i%4)*1.3
		var y=1.7+floori(i/4)*1.1
		var card=box(self,Vector3(x,y,-7.42),Vector3(0.88,0.6,0.03),"c3c7a5")
		card.name="BoardCard"+str(i)
		card.rotation.z=(i%3-1)*0.04
		sphere(self,Vector3(x,y+0.22,-7.38),0.035,"454e3d")
	for x in [-1.2,0.1,1.4]:
		var thread=box(self,Vector3(x,2.15,-7.35),Vector3(1.8,0.016,0.018),"343e2a")
		thread.rotation.z=0.6
	box(self,Vector3(6.8,0.9,3.5),Vector3(2.6,1.8,1.1),"5c7250",true)
	box(self,Vector3(6.8,1.84,3.5),Vector3(0.7,0.025,0.45),"c8c7a8")
	for y in [0.5,1.1]: box(self,Vector3(6.8,y,4.1),Vector3(0.3,0.07,0.06),"b6b798")
	lettering("",Vector3(0,3.6,-7.35),28)
	target("board","Consult the case board",Vector3(0,0,-6.2))
	target("day_close","Set the notebook down for the evening",Vector3(3.5,0,-2.9))
	target("exemption","Examine the folded notice",Vector3(6.8,0,4.4))

func update_board(evidence:Array) -> void:
	if location != "room": return
	for i in 8:
		var card=get_node_or_null("BoardCard"+str(i))
		if card: card.visible=i<evidence.size()
