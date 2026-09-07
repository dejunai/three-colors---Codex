extends "res://estate.gd"

# Encounter state is advanced by main only during exploration. Menus pause it.
const CYCLE = 12.0
const NOTICE_TIME = 1.4
var clock = 0.0
var exposure = 0.0
var figure: Node3D
var reflected_edges: Node3D
var wall_shadow: MeshInstance3D
var strain_shadows: Array[MeshInstance3D] = []
var route_available = false

func _ready() -> void:
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("151a19")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("929b93")
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	box(self,Vector3(-1.5,-0.25,-12),Vector3(16,0.5,44),"565c56",true)
	for x in [-9.3,6.3]:
		box(self,Vector3(x,2,-12),Vector3(0.6,4,44),"424b45",true)
	box(self,Vector3(-1.5,2,-33.7),Vector3(16,4,0.6),"414a43",true)
	box(self,Vector3(-1.5,2,9.5),Vector3(16,4,0.6),"414a43",true)
	# A long outer walk and a shorter right-hand recess are always physically open.
	box(self,Vector3(-3.2,1.6,-15),Vector3(0.65,3.2,19),"3c453f",true)
	box(self,Vector3(2.7,1.4,-16),Vector3(0.65,2.8,9),"444e46",true)
	for z in [5,-3,-10,-23,-30]:
		var light = OmniLight3D.new()
		light.position = Vector3(-1.0,3.3,z)
		light.light_energy = 1.1
		light.omni_range = 11
		add_child(light)
		# Reflected light is provisional; no extra audible source is introduced.
		box(self,Vector3(-8.95,1.3,z),Vector3(0.05,0.16,0.6),"b2b6a7")
	for z in range(-30,8,3):
		box(self,Vector3(-7.1,0.02,z),Vector3(0.5,0.03,1.5),"969d8e")
	lettering("SERVICE WALK",Vector3(-6.9,1.7,-3.5),30)
	box(self,Vector3(-1.0,0.65,6),Vector3(2,1.3,1),"645f50",true)
	target("tunnel_notes","Examine the service plan",Vector3(-1,0,4.5))
	target("tunnel_exit","Return to Pickman Street",Vector3(0,0,8))
	target("tunnel_record","Examine the lower foundation",Vector3(0,0,-30.2))
	figure = person(Vector3(0,0,-16),"404941",false)
	figure.scale = Vector3(1.05,1.18,0.9)
	# A visible face plane and reaching arms make its facing legible without audio.
	box(figure,Vector3(0,1.83,0.18),Vector3(0.19,0.20,0.05),"b2b4a6")
	reflected_edges = Node3D.new()
	add_child(reflected_edges)
	for z in [-10,-13,-16,-19,-22]:
		box(reflected_edges,Vector3(4.4,0.055,z),Vector3(0.18,0.08,1.5),"c4c9b6")
	reflected_edges.visible = false
	wall_shadow = box(self,Vector3(-1,2,-33.32),Vector3(0.8,2.4,0.035),"151d19")
	for z in [-7,-11,-15,-19,-23]:
		strain_shadows.append(box(self,Vector3(-2.85,1.6,z),Vector3(0.035,2.2,0.5),"18221c"))

func reveal(perception:int) -> void:
	route_available = perception >= 4
	reflected_edges.visible = route_available
	if route_available:
		target("tunnel_edge","Follow the reflected service marks",Vector3(4.4,0,-9))
	else: points.erase("tunnel_edge")

func phase() -> String:
	var beat = fposmod(clock,CYCLE)
	if beat < 2.0: return "warning"
	if beat < 6.0: return "watching"
	return "turned"

func in_sight(pos:Vector3) -> bool:
	# These bounds describe the unobstructed central strip between the stone walls.
	return absf(pos.x) < 2.2 and pos.z < -11.5 and pos.z > -20.5

func advance(delta:float,pos:Vector3) -> bool:
	clock += delta
	if phase() == "watching" and in_sight(pos): exposure += delta
	else: exposure = 0.0
	pose()
	return exposure >= NOTICE_TIME

func pose() -> void:
	figure.rotation.y = PI if phase() == "turned" else 0.0
	figure.position.z = -16 + minf(exposure,NOTICE_TIME)*0.7
	figure.get_node("LeftArm").rotation.x = -0.9 if phase()=="watching" else 0.0
	figure.get_node("RightArm").rotation.x = -0.9 if phase()=="watching" else 0.0

func cue() -> String:
	if exposure > 0: return "It sees Walter. Get behind stone."
	match phase():
		"warning": return "[A thin, wet cough.] Its head lifts toward the central passage."
		"watching": return "It watches the central passage."
	return "It turns toward the wall."

func presentation(strain:float,relieved:bool) -> void:
	# A quiet geometric alternative remains readable even at zero optical distortion.
	wall_shadow.scale.x = 1.0 + strain*(0.4 if relieved else 3.5)
	for shadow in strain_shadows:
		shadow.scale.z = 1.0 + strain*(0.4 if relieved else 3.5)
