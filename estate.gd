extends Node3D

var mats = {}
var points = {}
var colliders: Array[Rect2] = []
var rng = RandomNumberGenerator.new()
var conditional_actors: Dictionary = {}
var routes: Dictionary = {}
var rose_bodies: Array[Node3D] = []
var birch_bodies: Array[Node3D] = []
var scene_bodies: Array[Node3D] = []
var gardener_actor: Node3D
var groundskeeper_actor: Node3D
var opening_knife: Node3D
var birch_belongings: Node3D
var opening_staff: Dictionary = {}
var departure_leaves: Array[Node3D] = []

func sync_staging(st) -> void:
	for leaf in departure_leaves:
		leaf.rotation.y = -float(leaf.get_meta("side"))*PI/2 if not st.report.is_empty() else 0.0
	for corpse in rose_bodies: corpse.visible = not st.rose_bodies_removed
	for corpse in birch_bodies: corpse.visible = not st.birch_bodies_removed
	if is_instance_valid(birch_belongings): birch_belongings.visible = not st.birch_bodies_removed
	for id in opening_staff:
		opening_staff[id].visible = not st.estate_complete
		if st.estate_complete: points.erase(id)
	if st.rose_bodies_removed:
		for id in ["wounds","watch","knife"]: points.erase(id)
	if st.birch_bodies_removed:
		for id in ["eight","shoes"]: points.erase(id)
	if is_instance_valid(opening_knife): opening_knife.visible = not st.rose_bodies_removed
	if is_instance_valid(groundskeeper_actor):
		groundskeeper_actor.visible = st.lounge_exited
		if st.lounge_exited: target("crew","Watch the groundskeeper",Vector3(-12.6,0,-16.9))
		else: points.erase("crew")
	if is_instance_valid(gardener_actor):
		gardener_actor.position = Vector3(-4,0,12) if st.estate_complete else Vector3(-12,0,1)
		target("gardener","Speak to the gardener",gardener_actor.position)
	if st.visited.has("almy"):
		target("service_entrance","Enter the smoking lounge through the service entrance",Vector3(-10,0,-18))
	else: points.erase("service_entrance")

func register_actor(id: String, node: Node3D, target_id: String = "", condition: Callable = Callable()) -> void:
	conditional_actors[id] = {
		"node": node,
		"target_id": target_id if not target_id.is_empty() else id,
		"condition": condition
	}

func sync_actors(state_obj: RefCounted) -> void:
	for id in conditional_actors:
		var info = conditional_actors[id]
		if info.condition.is_valid():
			var is_present: bool = info.condition.call(state_obj)
			if not is_present:
				dismiss_actor(id)

func dismiss_actor(id: String) -> void:
	if not conditional_actors.has(id):
		points.erase(id)
		return
	var info = conditional_actors[id]
	if not info.target_id.is_empty():
		points.erase(info.target_id)
	if is_instance_valid(info.node):
		info.node.hide()
		info.node.queue_free()

func dismiss_old_woman() -> void:
	dismiss_actor("old_woman")

func mat(c: String, glow: bool = false) -> StandardMaterial3D:
	var key = c + str(glow)
	if mats.has(key): return mats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.92
	if glow:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = 0.5
	mats[key] = m
	return m

func mesh_at(parent: Node3D, mesh: Mesh, pos: Vector3, c: String, glow: bool = false) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.position = pos
	n.material_override = mat(c,glow)
	parent.add_child(n)
	return n

func box(parent: Node3D, pos: Vector3, size: Vector3, c: String, solid: bool = false) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	var n = mesh_at(parent,m,pos,c)
	if solid:
		var body = StaticBody3D.new()
		var shape = BoxShape3D.new()
		shape.size = size
		var col = CollisionShape3D.new()
		col.shape = shape
		n.add_child(body)
		body.add_child(col)
		if parent == self and pos.y > 0.1:
			colliders.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	return n

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, c: String, top: float = -1.0) -> MeshInstance3D:
	var m = CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top < 0 else top
	m.height = height
	m.radial_segments = 10
	return mesh_at(parent,m,pos,c)

func sphere(parent: Node3D,pos:Vector3,r:float,c:String) -> MeshInstance3D:
	var m = SphereMesh.new()
	m.radius = r
	m.height = r*2
	m.radial_segments = 10
	m.rings = 5
	return mesh_at(parent,m,pos,c)

func lettering(text: String,pos: Vector3,font_size: int = 56) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.009
	l.position = pos
	l.modulate = Color("c5c5bd")
	l.outline_size = 0
	l.no_depth_test = false
	add_child(l)
	return l

func lamp(pos: Vector3, tall: bool = true) -> void:
	var h = 3.8 if tall else 1.7
	cylinder(self,pos+Vector3.UP*h*0.45,0.08,h*0.9,"242626")
	cylinder(self,pos+Vector3.UP*0.15,0.23,0.3,"333535")
	var glass=box(self,pos+Vector3.UP*h,Vector3(0.42,0.62,0.42),"aaa99d")
	glass.set_meta("lamp_glass",true)
	glass.material_override=glass.material_override.duplicate()
	glass.material_override.emission=Color("dddcc2")
	glass.material_override.emission_energy_multiplier=0.7
	for x in [-0.24,0.24]:
		for z in [-0.24,0.24]: box(self,pos+Vector3(x,h,z),Vector3(0.045,0.75,0.045),"191b1c")
	cylinder(self,pos+Vector3.UP*(h+0.47),0.42,0.32,"252726",0.02)
	var light = OmniLight3D.new()
	light.set_meta("street_lamp",true)
	light.position = pos+Vector3.UP*(h-0.1)
	light.light_color = Color("eeeee2")
	light.light_energy = 2.3
	light.omni_range = 8.0
	add_child(light)

func person(pos: Vector3, coat: String = "353838", hat: bool = true, accent: String = "") -> Node3D:
	var root = Node3D.new()
	root.position = pos
	add_child(root)
	cylinder(root,Vector3(0,1.08,0),0.32,0.85,coat,0.24).name = "Coat"
	box(root,Vector3(0,1.48,0),Vector3(0.52,0.27,0.32),coat)
	if not accent.is_empty():
		box(root,Vector3(0.16,1.48,-0.17),Vector3(0.07,0.10,0.025),accent).name = "Accent"
	cylinder(root,Vector3(0,1.78,0),0.15,0.3,"a0a095",0.17)
	box(root,Vector3(0,1.38,-0.18),Vector3(0.08,0.24,0.025),"b9b8ac")
	for side in [-1,1]:
		var leg = Node3D.new()
		leg.name = "LeftLeg" if side == -1 else "RightLeg"
		leg.position = Vector3(side*0.14,0.76,0)
		root.add_child(leg)
		cylinder(leg,Vector3(0,-0.3,0),0.10,0.58,"262929")
		box(leg,Vector3(0,-0.66,-0.055),Vector3(0.19,0.15,0.32),"181a1b")
		var arm = Node3D.new()
		arm.name = "LeftArm" if side == -1 else "RightArm"
		arm.position = Vector3(side*0.34,1.48,0)
		root.add_child(arm)
		cylinder(arm,Vector3(0,-0.29,0),0.095,0.57,coat)
		sphere(arm,Vector3(0,-0.61,0),0.08,"96968b")
	if hat:
		cylinder(root,Vector3(0,1.97,0),0.29,0.045,"222526")
		cylinder(root,Vector3(0,2.06,0),0.2,0.16,"343737",0.16)
	return root

func body(pos: Vector3, angle: float, covered: bool = false, small: bool = false, group: String = "rose") -> void:
	var n = Node3D.new()
	n.position = pos
	n.rotation.y = angle
	add_child(n)
	scene_bodies.append(n)
	if group == "birch": birch_bodies.append(n)
	elif group == "rose": rose_bodies.append(n)
	if small: n.scale = Vector3.ONE*0.68
	if covered:
		var sheet = sphere(n,Vector3(0,0.24,0),0.62,"9e9e96")
		sheet.scale = Vector3(0.67,0.39,1.55)
		box(n,Vector3(0,0.13,0),Vector3(0.85,0.05,2.1),"999a92")
	else:
		box(n,Vector3(0,0.23,0),Vector3(0.6,0.32,0.84),"333637")
		box(n,Vector3(0,0.405,-0.28),Vector3(0.22,0.012,0.2),"b9b8ad")
		sphere(n,Vector3(0,0.24,-0.69),0.19,"a09f92")
		for x in [-0.16,0.16]:
			box(n,Vector3(x,0.14,0.67),Vector3(0.2,0.22,0.75),"292c2d")
			box(n,Vector3(x,0.14,1.08),Vector3(0.24,0.22,0.27),"191b1b")
		for x in [-0.4,0.4]: box(n,Vector3(x,0.16,0.08),Vector3(0.16,0.2,0.82),"333637")

func hedge(pos:Vector3,size:Vector3) -> void:
	box(self,pos,size,"343b36",true)
	var amount = int(maxf(size.x,size.z)*1.4)
	for i in amount:
		var t = float(i)/maxi(1,amount-1)-0.5
		var p = pos+Vector3(t*size.x, size.y*0.35,t*size.z)
		if size.x > size.z: p.z = pos.z+rng.randf_range(-0.2,0.2)
		else: p.x = pos.x+rng.randf_range(-0.2,0.2)
		var s = sphere(self,p,0.52,"414840")
		s.scale.y = 0.65

func tree(pos:Vector3, birch:bool = false) -> void:
	var trunk = "85877e" if birch else "363b38"
	var h = rng.randf_range(5.0,8.0)
	cylinder(self,pos+Vector3(0,h/2,0),0.17,h,trunk,0.07)
	for i in 5:
		var a = i*2.2
		var limb = cylinder(self,pos+Vector3(sin(a)*0.65,h*0.7+i*0.28,cos(a)*0.65),0.085,2.3,trunk,0.02)
		limb.rotation = Vector3(sin(a)*0.8,0,cos(a)*0.8)
		var leaves = sphere(self,pos+Vector3(sin(a)*1.15,h+i*0.15,cos(a)*1.15),1.2,"444b44")
		leaves.scale.y = 0.6
	if birch:
		for i in 10: box(self,pos+Vector3(0,0.8+i*0.45,0.13),Vector3(0.22,0.045,0.04),"3c403c")

func target(id:String,title:String,pos:Vector3) -> void:
	points[id] = {"title":title,"pos":pos}

# The object's own supporting cabinet may occlude its center from the far side.
# Exclude only that cabinet from sight checks; its movement collision stays active.
func tabletop_target(id:String,title:String,surface:Vector3,support:Node3D) -> void:
	target(id,title,Vector3(surface.x,0,surface.z))
	points[id]["sight"] = surface
	points[id]["marker"] = surface
	var excluded: Array[RID] = []
	for child in support.get_children():
		if child is CollisionObject3D: excluded.append(child.get_rid())
	points[id]["excluded"] = excluded

func _ready() -> void:
	rng.seed = 1923
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("303b3b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("abb4b3")
	env.ambient_light_energy = 0.32
	env.fog_enabled = true
	env.fog_light_color = Color("43504c")
	env.fog_density = 0.018
	world_env.environment = env
	add_child(world_env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24,-42,0)
	sun.light_energy = 0.58
	sun.light_color = Color("e3e5db")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	box(self,Vector3(0,-0.3,0),Vector3(110,0.5,140),"535b52",true)
	box(self,Vector3(0,-0.035,21),Vector3(7,0.07,43),"969990")
	box(self,Vector3(0,-0.025,-5),Vector3(35,0.09,27),"85897f")
	# A procedural surface treatment, not a downloaded art dependency.
	var noise = FastNoiseLite.new()
	noise.seed = 1923
	noise.frequency = 0.11
	var texture = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	for c in ["85897f","969990","777a75","656a66"]:
		var material = mat(c)
		material.albedo_texture = texture
		material.uv1_scale = Vector3(8,8,8)
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
	# Drive edging and gravel: deterministic placement keeps saves reproducible.
	for x in [-3.65,3.65]: box(self,Vector3(x,0.035,21),Vector3(0.24,0.16,43),"b6b7ab")
	for i in 350:
		var x = rng.randf_range(-3.35,3.35)
		var z = rng.randf_range(6,42)
		box(self,Vector3(x,0.014,z),Vector3(0.05,0.025,rng.randf_range(0.1,0.24)),"777d75")
	# Estate's long facade and two projecting wings.
	box(self,Vector3(0,5.5,-24),Vector3(34,11,8),"777a75",true)
	box(self,Vector3(0,11.5,-24),Vector3(35,0.6,9),"515b53")
	for x in [-11,10]:
		box(self,Vector3(x,12.3,-25),Vector3(1.2,2.4,1.3),"5d665d")
		box(self,Vector3(x,13.55,-25),Vector3(1.5,0.25,1.55),"898f7f")
	for x in [-17,17]:
		box(self,Vector3(x,4.5,-20.5),Vector3(6,9,14),"656a66",true)
		box(self,Vector3(x,9.2,-20.5),Vector3(6.7,0.4,14.6),"a5a89b")
	for y in [0.7,4.6,8.1,11.2]: box(self,Vector3(0,y,-19.92),Vector3(34.5,0.22,0.35),"aaa99b")
	for x in [-12,-8,-4,4,8,12]:
		for y in [2.6,6.3,9.7]:
			box(self,Vector3(x,y,-19.84),Vector3(1.7,2.25,0.15),"2e3737")
			for dx in [-0.91,0.91]: box(self,Vector3(x+dx,y,-19.7),Vector3(0.12,2.5,0.22),"bab9a9")
			for dy in [-1.2,0,1.2]: box(self,Vector3(x,y+dy,-19.7),Vector3(1.95,0.12,0.22),"bab9a9")
			box(self,Vector3(x,y,-19.65),Vector3(0.08,2.2,0.08),"a4a496")
	box(self,Vector3(0,2.2,-19.75),Vector3(3.4,4.4,0.35),"292e2e")
	for x in [-1.5,1.5]: box(self,Vector3(x,2.5,-19.45),Vector3(0.1,3.6,0.1),"a8a694")
	# Portico columns, shallow walkable approach, triangular roof.
	for x in [-5,-2.6,2.6,5]:
		cylinder(self,Vector3(x,2.8,-16.1),0.25,5.5,"b7b6a7")
		box(self,Vector3(x,0.12,-16.1),Vector3(0.8,0.24,0.8),"989b90")
		box(self,Vector3(x,5.5,-16.1),Vector3(0.7,0.3,0.7),"b5b4a6")
	box(self,Vector3(0,5.85,-17.5),Vector3(12,0.55,6),"afb0a3")
	var pediment = CylinderMesh.new()
	pediment.top_radius = 0
	pediment.bottom_radius = 7
	pediment.height = 2.5
	pediment.radial_segments = 4
	var roof = mesh_at(self,pediment,Vector3(0,7.3,-17.5),"6a706b")
	roof.scale.z = 0.45
	roof.rotation.y = PI/4
	lettering("O P H I O N",Vector3(0,5.87,-14.44),62)
	# Staff entrance in the kitchen-wing facade; member doors remain scenery.
	box(self,Vector3(-10,1.4,-19.7),Vector3(1.4,2.8,0.16),"242b28")
	lettering("SERVICE",Vector3(-10,3.1,-19.5),26)
	# Garden: openings in southern hedge and eastern birch access.
	hedge(Vector3(-10,0.65,6),Vector3(12,1.3,1.25))
	hedge(Vector3(10,0.65,6),Vector3(12,1.3,1.25))
	hedge(Vector3(-16,0.65,-4),Vector3(1.2,1.3,21))
	hedge(Vector3(16,0.65,2),Vector3(1.2,1.3,7))
	hedge(Vector3(16,0.65,-10),Vector3(1.2,1.3,7))
	for x in [-9,9]:
		box(self,Vector3(x,0.08,-4),Vector3(3.8,0.2,11.5),"555b50")
		for i in 15:
			var p = Vector3(x+rng.randf_range(-1.5,1.5),0.6,-9+i*0.7)
			cylinder(self,p,0.025,0.95,"343f35")
			for j in 2:
				var rose = sphere(self,p+Vector3(j*0.16,0.55+j*0.12,0),0.13,"95968a")
				rose.scale.y = 0.6
	# Fountain, benches, six individual bodies.
	cylinder(self,Vector3(0,0.25,-6.0),2.0,0.5,"b1b1a1")
	cylinder(self,Vector3(0,0.52,-6.0),1.65,0.12,"424e4c")
	cylinder(self,Vector3(0,1.0,-6),0.32,1.1,"a5a698",0.17)
	cylinder(self,Vector3(0,1.58,-6),0.85,0.16,"b3b3a4",0.55)
	sphere(self,Vector3(0,1.87,-6),0.21,"9fa295")
	for i in 6:
		var a = PI*0.13+float(i)*PI*0.145
		body(Vector3(cos(a)*4.5,0,-5+sin(a)*4.1),a-PI/2)
	for x in [-12,12]:
		box(self,Vector3(x,0.65,-11),Vector3(2.6,0.16,0.65),"747b6c")
		box(self,Vector3(x,1.1,-11.3),Vector3(2.6,0.7,0.12),"747b6c")
		for dx in [-0.95,0.95]: box(self,Vector3(x+dx,0.3,-11),Vector3(0.12,0.6,0.4),"353c36")
	# Birch grove has a clear path and two non-graphic covered figures.
	box(self,Vector3(20,-0.025,-4),Vector3(11,0.08,4),"8c9185")
	body(Vector3(23,0,-5),0.6,true,false,"birch")
	body(Vector3(24.6,0,-4.5),0.4,true,true,"birch")
	# A visible inspection grouping on the approach from the assistant.
	birch_belongings = Node3D.new()
	birch_belongings.name = "BirchBelongings"
	birch_belongings.position = Vector3(19,0,-4)
	add_child(birch_belongings)
	box(birch_belongings,Vector3(0,0.055,0),Vector3(1.5,0.03,1.25),"aaa28d")
	box(birch_belongings,Vector3(-0.23,0.14,-0.12),Vector3(0.65,0.14,0.85),"65594f")
	for x in [-0.64,0.18]:
		var sleeve = box(birch_belongings,Vector3(x,0.13,-0.26),Vector3(0.22,0.1,0.55),"65594f")
		sleeve.rotation.y = -0.35 if x < 0 else 0.35
	for z in [0.12,0.43]:
		box(birch_belongings,Vector3(0.48,0.10,z),Vector3(0.39,0.06,0.22),"9c8770")
		box(birch_belongings,Vector3(0.48,0.18,z),Vector3(0.36,0.12,0.20),"40382f")
	for p in [Vector3(20,0,-9),Vector3(26,0,-8),Vector3(27,0,-1),Vector3(22,0,1)]: tree(p,true)
	# Kitchen wing yard: the grounds crew keeps a fixed distance from the service door.
	box(self,Vector3(-13.4,0.35,-16.4),Vector3(0.55,0.5,0.55),"3b443b")
	box(self,Vector3(-13.0,0.85,-16.6),Vector3(0.5,0.42,0.5),"353c36")
	cylinder(self,Vector3(-12.0,0.06,-15.4),0.32,0.12,"242626")
	sphere(self,Vector3(-12.0,0.24,-15.4),0.15,"656a66")
	var groundskeeper = person(Vector3(-12.6,0,-16.6),"3a3f36",true,"7a2a1a")
	groundskeeper.rotation.y = 2.4
	groundskeeper_actor = groundskeeper
	groundskeeper.hide()
	# Boundary walls and iron gate, with a lodge beside the entrance.
	for x in [-14,14]: box(self,Vector3(x,1.2,37),Vector3(20,2.4,0.65),"6c736b",true)
	for x in [-4.1,4.1]:
		box(self,Vector3(x,2.0,37),Vector3(1,4,1),"92978b",true)
		cylinder(self,Vector3(x,4.2,37),0.75,0.4,"b0b1a1",0.5)
	for side in [-1,1]:
		var leaf=Node3D.new()
		leaf.position=Vector3(side*3.6,0,37)
		leaf.set_meta("side",side)
		add_child(leaf)
		departure_leaves.append(leaf)
		for i in 8: cylinder(leaf,Vector3(-side*(0.2+i*0.45),1.8,0),0.035,3.2,"292f2c")
		for y in [0.6,2.7]: box(leaf,Vector3(-side*1.8,y,0),Vector3(3.6,0.09,0.09),"292f2c")
		var barrier=StaticBody3D.new()
		var collision=CollisionShape3D.new()
		var shape=BoxShape3D.new()
		shape.size=Vector3(3.6,3.2,0.12)
		collision.shape=shape
		collision.position=Vector3(-side*1.8,1.6,0)
		barrier.add_child(collision)
		leaf.add_child(barrier)
	box(self,Vector3(-10,2.2,29),Vector3(6,4.4,7),"777c71",true)
	box(self,Vector3(-10,4.6,29),Vector3(6.5,0.3,7.5),"4f5750")
	box(self,Vector3(-6.95,2.3,29),Vector3(0.12,1.7,2),"282f2d")
	for x in [-5.2,5.2]:
		for z in [9,23,36]: lamp(Vector3(x,0,z))
	for x in [-12,12]: lamp(Vector3(x,0,-13),false)
	for side in [-1,1]:
		for i in 10: tree(Vector3(side*rng.randf_range(22,34),0,-25+i*7))
	# A field desk and witness silhouettes.
	box(self,Vector3(7,0.97,-14),Vector3(2.4,0.15,1.1),"6f7469",true)
	for x in [6,8]: box(self,Vector3(x,0.45,-14),Vector3(0.13,0.9,0.8),"3b443b")
	box(self,Vector3(6.6,1.06,-13.8),Vector3(0.52,0.035,0.7),"cccbba")
	box(self,Vector3(7.4,1.06,-13.8),Vector3(0.48,0.035,0.6),"babaa8")
	person(Vector3(-2,0,31),"555c52").rotation.y = -0.3
	opening_staff["odell"] = person(Vector3(4,0,-11.5),"272e2b")
	opening_staff["odell"].rotation.y = 0.2
	opening_staff["assistant"] = person(Vector3(12.5,0,-3.8),"aaa99a",false)
	opening_staff["assistant"].rotation.y = -1.2
	gardener_actor = person(Vector3(-12,0,1),"4e5a4b")
	gardener_actor.rotation.y = 0.7
	opening_knife = box(self,Vector3(-7,0.08,-1),Vector3(0.08,0.1,0.72),"b8b8a6")
	opening_knife.rotation.y = 0.5
	# Interaction positions are reachable on foot and never embedded in collision.
	target("boy","Speak to the gatehouse boy",Vector3(-2,0,31))
	target("wounds","Examine the six men",Vector3(0,0,0))
	target("eight","Examine the birch grove",Vector3(23,0,-3.3))
	target("knife","Examine beneath the hedge",Vector3(-7,0,-0.4))
	target("watch","Examine the unidentified man",Vector3(-3.8,0,-3.1))
	points["watch"]["marker"] = Vector3(-3.8,0.7,-3.1)
	# Keep this inspection on the east side of the terrace. The service entrance
	# occupies the west side, and nearby rings made the two read as one target.
	target("gas","Examine the terrace windows",Vector3(8,0,-18.0))
	target("register","Read the seating list",Vector3(7.4,0,-13.1))
	target("shoes","Examine the belongings",Vector3(19,0,-4))
	points["shoes"]["marker"] = Vector3(19,0.32,-4)
	target("assistant","Speak to the coroner's assistant",Vector3(12.5,0,-3.8))
	target("gardener","Speak to the gardener",Vector3(-12,0,1))
	target("odell","Speak to Captain Odell",Vector3(4,0,-11.5))
	target("report","Write the preliminary report",Vector3(6,0,-13.1))
	target("exit","Leave through the estate gates",Vector3(0,0,37))
	var gate_bodies: Array[RID] = []
	for leaf in departure_leaves:
		for child in leaf.get_children():
			if child is CollisionObject3D: gate_bodies.append(child.get_rid())
	points.exit["excluded"] = gate_bodies
