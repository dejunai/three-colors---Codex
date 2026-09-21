extends SceneTree

const EXTERIORS = [
	"res://assets/models/exteriors/estate_house.glb",
	"res://assets/models/exteriors/pickman_house_1.glb",
	"res://assets/models/exteriors/pickman_house_2.glb",
	"res://assets/models/exteriors/pickman_house_3.glb",
	"res://assets/models/exteriors/police_precinct.glb",
	"res://assets/models/exteriors/schoolhouse.glb",
	"res://assets/models/exteriors/storefront_1.glb",
	"res://assets/models/exteriors/storefront_2.glb",
	"res://assets/models/exteriors/storefront_3.glb",
	"res://assets/models/exteriors/upper_house_1.glb",
	"res://assets/models/exteriors/upper_house_2.glb",
	"res://assets/models/exteriors/upper_house_3.glb",
]

const PROPS = [
	"res://assets/models/props/prop_fence_gate.glb",
	"res://assets/models/props/prop_hedge.glb",
	"res://assets/models/props/prop_tree_bush.glb",
]

func _initialize() -> void:
	print("Checking 12 exterior models...")
	for path in EXTERIORS:
		var scene = load(path)
		assert(scene != null, "Failed to load exterior: " + path)
		var inst = scene.instantiate()
		assert(inst != null, "Failed to instantiate exterior: " + path)
		var meshes = inst.find_children("*", "MeshInstance3D", true, false)
		assert(meshes.size() > 0, "No MeshInstance3D found in " + path)
		var mesh_inst: MeshInstance3D = meshes[0]
		var aabb = mesh_inst.get_aabb()
		assert(aabb.position.y >= -0.05 and aabb.position.y <= 0.05, "Base must be grounded near Y=0 for " + path)
		inst.free()

	print("Checking 3 prop models...")
	for path in PROPS:
		var scene = load(path)
		assert(scene != null, "Failed to load prop: " + path)
		var inst = scene.instantiate()
		assert(inst != null, "Failed to instantiate prop: " + path)
		var meshes = inst.find_children("*", "MeshInstance3D", true, false)
		assert(meshes.size() > 0, "No MeshInstance3D found in " + path)
		var mesh_inst: MeshInstance3D = meshes[0]
		var aabb = mesh_inst.get_aabb()
		assert(aabb.position.y >= -0.05 and aabb.position.y <= 0.05, "Base must be grounded near Y=0 for " + path)
		inst.free()

	print("EXTERIOR & PROP ASSETS PASS: all 12 exteriors and 3 props instantiate cleanly and are grounded at Y=0")
	quit(0)
