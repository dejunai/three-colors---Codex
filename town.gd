extends "res://estate.gd"

var location = "town"
var departing_woman: Node3D
# Corwin's room: a glass planted from the first night, and the board's twine.
# Both are inert until the chapter's final beat (chapter_one_break.gd).
var desk_glass: Node3D
var whiskey: MeshInstance3D
var board_threads: Array[MeshInstance3D] = []
var glass_shattered := false
const DistrictSurfaces = preload("res://scripts/shared/district_surfaces.gd")

func district_box(parent: Node3D, position: Vector3, size: Vector3, tint: String, solid: bool = false, kind: String = "soot_brick") -> MeshInstance3D:
	return DistrictSurfaces.apply(box(parent, position, size, tint, solid), kind, tint)

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
			"lounge": _smoking_lounge()

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
	district_box(self,Vector3(x,1.55,-7.0),Vector3(1.7,3.1,0.12),"242d2a",false,"wood")
	for dx in [-1,1]: district_box(self,Vector3(x+dx,1.7,-6.8),Vector3(0.14,3.4,0.25),"a0a18e",false,"cut_stone")
	district_box(self,Vector3(x,3.5,-6.7),Vector3(2.3,0.23,0.4),"a4a28f",false,"cut_stone")
	sphere(self,Vector3(x+0.57,1.2,-6.82),0.06,"b8b29a")
	lettering(title,Vector3(x,4.25,-6.6),42)
	target(id,"Enter "+title.to_lower(),Vector3(x,0,-5.6))

func _street() -> void:
	district_box(self,Vector3(0,-0.3,7),Vector3(100,0.5,75),"4b554d",true,"stone")
	district_box(self,Vector3(0,-0.035,8),Vector3(67,0.06,15),"646e66",false,"cobble")
	district_box(self,Vector3(0,0,-3),Vector3(67,0.1,6.5),"8a9083",false,"cut_stone")
	district_box(self,Vector3(0,0,19),Vector3(67,0.1,6),"7c8579",false,"cut_stone")
	for z in [0.4,16]: district_box(self,Vector3(0,0.065,z),Vector3(66,0.13,0.18),"a0a28f",false,"cut_stone")
	for x in range(-30,32,2): box(self,Vector3(x,0.06,-3),Vector3(0.026,0.015,6),"636f63")
	for i in 370:
		box(self,Vector3(rng.randf_range(-32,32),0.01,rng.randf_range(1,15)),Vector3(0.08,0.02,rng.randf_range(0.1,0.32)),"838c7d")
	# The north side of Pickman Street: ordinary institutions rather than a monumental hub.
	for spec in [[-18,14,8.8,"677568"],[-2,15,10.7,"828c79"],[16,16,9.5,"596b5d"]]:
		var x:float=spec[0]
		var width:float=spec[1]
		var h:float=spec[2]
		var wall_kind := "soot_brick" if x in [-18,16] else "cracked_plaster"
		district_box(self,Vector3(x,h/2,-11),Vector3(width,h,7),spec[3],true,wall_kind)
		district_box(self,Vector3(x,h+0.2,-11),Vector3(width+0.5,0.4,7.5),"333f38",false,"slate")
		for y in [0.4,3.9,h-0.3]: district_box(self,Vector3(x,y,-7.44),Vector3(width,0.15,0.24),"949984",false,"cut_stone")
		for dx in [-4.5,0,4.5]:
			for y in [5.6,8.1]:
				if y>h-1: continue
				district_box(self,Vector3(x+dx,y,-7.42),Vector3(1.4,1.7,0.12),"2b3933",false,"wood")
				for dy in [-0.92,0,0.92]: district_box(self,Vector3(x+dx,y+dy,-7.25),Vector3(1.7,0.09,0.17),"a2a38f",false,"wood")
				for edge in [-0.78,0.78]: district_box(self,Vector3(x+dx+edge,y,-7.25),Vector3(0.1,1.9,0.17),"969b87",false,"wood")
	_door(-18,"PRECINCT 4","street_precinct")
	_door(-1,"ALMY'S BOARDINGHOUSE","street_almy")
	_door(18,"ROOMS ABOVE","street_room")
	lettering("P I C K M A N   S T R E E T",Vector3(-11,1.4,19),35).rotation.y = PI
	# Cobbler's display with a bench and modest shop window.
	district_box(self,Vector3(23,1.7,-7.2),Vector3(3.8,2.0,0.14),"364a3d",false,"wood")
	lettering("SHOE REPAIRS",Vector3(23,3,-7.0),32)
	for x in [21.8,22.6,23.4,24.2]:
		box(self,Vector3(x,0.8,-6.9),Vector3(0.24,0.22,0.5),"8d977f")
	# Far-side warehouses frame the street but do not imply explorable doors.
	# The center warehouse footprint is now the western descent's opening.
	for x in [-24,25]:
		district_box(self,Vector3(x,4.0,28),Vector3(12,8,7),"536156",true,"soot_brick")
		district_box(self,Vector3(x,8.2,28),Vector3(12.6,0.4,7.5),"303f35",false,"slate")
	for x in [-25,-10,7,25]: lamp(Vector3(x,0,0))
	for x in [-20,9]:
		box(self,Vector3(x,0.55,18.2),Vector3(3,0.15,0.7),"6f7e66",true)
		box(self,Vector3(x,0.98,18.6),Vector3(3,0.75,0.14),"6a7962")
		for dx in [-1.1,1.1]: box(self,Vector3(x+dx,0.24,18.2),Vector3(0.12,0.5,0.6),"37483a")
	box(self,Vector3(8.5,0.65,18.2),Vector3(0.55,0.025,0.4),"c5c5ad")
	target("gazette","Read the morning paper",Vector3(8.5,0,17.3))
	lettering("ESTATE ROAD",Vector3(-27,2.4,15.5),38).rotation.y=PI/2
	target("street_estate","Return to the Ophion estate",Vector3(-27,0,15))
	# A rectory marker behind which Father Behan will speak plainly, if asked.
	box(self,Vector3(-8.6,0.55,-1.6),Vector3(0.06,1.1,0.06),"3a443a")
	box(self,Vector3(-8.6,0.85,-1.6),Vector3(0.5,0.06,0.06),"3a443a")
	person(Vector3(-8,0,-1),"242423",false).rotation.y=1.8
	target("behan","Speak with Father Behan",Vector3(-8,0,-1))
	# Kessler's shop, shuttered since his death, and a woman who won't give her name.
	box(self,Vector3(-20,1.1,12),Vector3(3.2,2.2,0.3),"333a2f",true)
	lettering("KESSLER",Vector3(-20,2.5,11.85),26)
	for y in [0.6,1.1,1.6]: box(self,Vector3(-20,y,11.83),Vector3(2.6,0.16,0.1),"241f1a")
	var old_woman = person(Vector3(-19.2,0,11.2),"3c3a34")
	departing_woman=old_woman
	old_woman.rotation.y = -2.0
	target("old_woman","Speak with the woman outside the shop",Vector3(-19.2,0,11.2))
	register_actor("old_woman", old_woman, "old_woman", func(st): return not st.evidence.has("old_woman"))
	for x in [-28,28]: tree(Vector3(x,0,20))
	# District portals have been replaced by physical streets. Interior doors
	# retain their stable route IDs in the shared exterior.
	district_box(self,Vector3(-24,1.6,24.3),Vector3(1.7,3.2,0.16),"283c32",false,"wood")
	lettering("POST OFFICE",Vector3(-24,3.7,24.05),32).rotation.y=PI
	target("route_post","Enter the post office",Vector3(-24,0,22))
	routes["route_post"]=["post_office",Vector3(0,0.1,6),0.0]

	var contiguous = preload("res://scripts/chapters/contiguous_town_phase_one.gd")
	contiguous.build_pickman_edge(self)
	contiguous.build_business(self)
	contiguous.build_upper_approach(self)
	contiguous.build_upper(self)
	contiguous.build_return_loop(self)
	var phase_two = preload("res://scripts/chapters/contiguous_town_phase_two.gd")
	phase_two.build(self)
	phase_two.build_waterfront_approach(self)
	phase_two.build_waterfront(self)

func _room_shell() -> void:
	box(self,Vector3(0,-0.3,0),Vector3(18,0.5,20),"747d6b",true)
	for x in range(-8,9): box(self,Vector3(x,0.001,0),Vector3(0.022,0.015,20),"46563f")
	box(self,Vector3(0,2.1,-8),Vector3(18,4.2,0.3),"7c8975",true)
	for x in [-9,9]: box(self,Vector3(x,2.1,0),Vector3(0.3,4.2,16.3),"75836e",true)
	for x in [-5.3,5.3]: box(self,Vector3(x,2.1,8),Vector3(7.2,4.2,0.3),"6e7e68",true)
	for z in [-7.8,7.8]: box(self,Vector3(0,0.14,z),Vector3(18,0.25,0.16),"344b35")
	for x in [-8.8,8.8]: box(self,Vector3(x,0.14,0),Vector3(0.16,0.25,16),"344b35")
	var window_xs = [5] if location == "precinct" else ([-5] if location in ["stationer", "haberdasher", "printer", "repairer"] else [-5, 5])
	for x in window_xs:
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
	box(self,Vector3(-4,1.5,-7.7),Vector3(1.7,3,0.12),"2d3d34")
	lettering("MORGUE",Vector3(-4,3.3,-7.5),28)
	target("route_morgue","Enter the morgue",Vector3(-4,0,-6.2))
	routes["route_morgue"]=["morgue",Vector3(0,0.1,6),0.0]

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
	var ledger_cabinet=box(self,Vector3(6.3,0.9,2),Vector3(2.6,1.8,0.9),"556f4c",true)
	box(self,Vector3(6.3,1.84,2),Vector3(0.8,0.07,0.6),"bebea1")
	box(self,Vector3(-6.8,1.4,-6),Vector3(2.8,2.8,1.1),"4d6846",true)
	for y in [0.6,1.3,2.1]:
		box(self,Vector3(-6.8,y,-5.35),Vector3(2.7,0.12,0.15),"a7b494")
		for x in [-7.6,-7,-6.4,-5.9]: cylinder(self,Vector3(x,y+0.2,-5.4),0.12,0.3,"b4c09b")
	box(self,Vector3(0,0.06,3),Vector3(5,0.03,3),"5c7050")
	target("almy","Speak to Mrs. Almy",Vector3(1.7,0,-3.3))
	tabletop_target("lodging","Examine the meal ledger",Vector3(6.3,1.9,2),ledger_cabinet)

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
		board_threads.append(thread)
	# A tumbler with an inch of something in it, left beside the notebook. Kept
	# inside the room's gray palette until the break: a warm color anywhere in the
	# world before then would read as the Observers' tell.
	desk_glass=Node3D.new()
	desk_glass.name="DeskGlass"
	desk_glass.position=Vector3(4.75,1.03,-3.5)
	add_child(desk_glass)
	var tumbler=cylinder(desk_glass,Vector3(0,0.12,0),0.095,0.24,"c3cbc2")
	var tumbler_material=mat("c3cbc2").duplicate()
	tumbler_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	tumbler_material.albedo_color=Color(0.76,0.8,0.76,0.42)
	tumbler.material_override=tumbler_material
	whiskey=cylinder(desk_glass,Vector3(0,0.05,0),0.083,0.09,"7e7c6e")
	var notice_dresser=box(self,Vector3(6.8,0.9,3.5),Vector3(2.6,1.8,1.1),"5c7250",true)
	box(self,Vector3(6.8,1.84,3.5),Vector3(0.7,0.025,0.45),"c8c7a8")
	for y in [0.5,1.1]: box(self,Vector3(6.8,y,4.1),Vector3(0.3,0.07,0.06),"b6b798")
	lettering("",Vector3(0,3.6,-7.35),28)
	target("board","Consult the case board",Vector3(0,0,-6.2))
	target("sleep","Turn in for the night",Vector3(-3.4,0,-2.2))
	target("day_close","Set the notebook down for the evening",Vector3(3.5,0,-2.9))
	tabletop_target("exemption","Examine the folded notice",Vector3(6.8,1.9,3.5),notice_dresser)

# Color returns as materials the film grade already lets through: a red thread
# (red-dominant, so film.gdshader's preserve band passes it) then amber in the glass.
func redden_threads() -> void:
	for thread in board_threads: thread.material_override=mat("a8261d")

func amber_glass() -> void:
	if is_instance_valid(whiskey): whiskey.material_override=mat("c8842a")

# The break itself. Pieces fall on tweens rather than physics: the beat has to play
# identically every time, and a stray rigid body must never block the desk or the door.
func shatter_glass() -> void:
	if glass_shattered or not is_instance_valid(desk_glass): return
	glass_shattered=true
	var origin:Vector3=desk_glass.position
	desk_glass.visible=false
	var shards=RandomNumberGenerator.new()
	shards.seed=1923
	var fall=create_tween().set_parallel(true)
	for i in 18:
		var piece=box(self,origin+Vector3(shards.randf_range(-0.06,0.06),0.12+shards.randf_range(0.0,0.14),shards.randf_range(-0.06,0.06)),Vector3(shards.randf_range(0.025,0.075),0.006,shards.randf_range(0.025,0.06)),"d4dcd3")
		piece.rotation=Vector3(shards.randf_range(-0.6,0.6),shards.randf_range(0.0,TAU),shards.randf_range(-0.6,0.6))
		var on_desk=i%2==0
		var landing=Vector3(origin.x+shards.randf_range(-0.4,0.4),1.045,origin.z+shards.randf_range(-0.2,0.25)) if on_desk else Vector3(origin.x+shards.randf_range(-0.6,0.6),0.02,origin.z+shards.randf_range(0.45,1.1))
		var drop=0.14 if on_desk else 0.42
		fall.tween_property(piece,"position",landing,drop+shards.randf_range(0.0,0.08)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_property(piece,"rotation",Vector3(shards.randf_range(-0.2,0.2),shards.randf_range(0.0,TAU),shards.randf_range(-0.2,0.2)),drop+0.1)
	var pool=box(self,Vector3(origin.x,1.043,origin.z),Vector3(0.05,0.006,0.05),"c8842a")
	pool.scale=Vector3.ONE
	create_tween().tween_property(pool,"scale",Vector3(11.0,1.0,7.5),3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func update_board(evidence:Array) -> void:
	if location != "room": return
	for i in 8:
		var card=get_node_or_null("BoardCard"+str(i))
		if card: card.visible=i<evidence.size()

func dismiss_old_woman() -> void:
	dismiss_actor("old_woman")
	if is_instance_valid(departing_woman):
		departing_woman.hide()
		departing_woman.queue_free()

func _smoking_lounge() -> void:
	points.erase("interior_exit")
	target("lounge_exit","Leave through the service entrance",Vector3(0,0,7.2))
	lettering("SMOKING LOUNGE",Vector3(0,3.3,-7.6),42)
	# A modest staff-side approach to a members' sitting room.
	for x in [-5,4]:
		cylinder(self,Vector3(x,0.62,-2),0.75,0.12,"57614e")
		cylinder(self,Vector3(x,0.3,-2),0.12,0.6,"35422f")
		cylinder(self,Vector3(x,0.72,-2),0.18,0.05,"999b87")
		for offset in [-1.6,1.6]:
			var seat=Vector3(x+offset,0,-2)
			box(self,seat+Vector3(0,0.45,0),Vector3(1.05,0.65,1.05),"4b5544",true)
			box(self,seat+Vector3(0,1.0,0.43),Vector3(1.05,1.1,0.22),"48513f")
			for arm in [-0.48,0.48]: box(self,seat+Vector3(arm,0.75,0),Vector3(0.22,0.35,1.05),"3b4735")
	box(self,Vector3(0,0.03,-1),Vector3(4.4,0.03,6),"626957")
	box(self,Vector3(0,1,-5.8),Vector3(3,2,0.8),"394638",true)
	person(Vector3(0,0,-4.4),"3f4540",false)
	target("barman","Speak with the club's steward",Vector3(0,0,-3.6))
	# The steward's boarded pantry door. Only offered once he has pointed to it;
	# see sync_pantry() and portals/lounge.portal.
	box(self,Vector3(-8.78,1.55,-3.0),Vector3(0.12,3.1,1.7),"2a302b")
	for y in [0.7,1.55,2.4]:
		var board=box(self,Vector3(-8.62,y,-3.0),Vector3(0.1,0.22,2.0),"5b5f52")
		if y > 2.0: board.rotation.z=0.11

# The old pantry door exists in the wall from the start; the way to it is not
# offered until the steward has named it. Portal sync only ever erases a hotspot,
# so the chapter re-offers it here whenever the lounge's conversation closes.
func sync_pantry(open:bool) -> void:
	if location != "lounge": return
	if open: target("pantry_door","Open the boarded pantry door",Vector3(-7.4,0,-3.0))
	else: points.erase("pantry_door")
