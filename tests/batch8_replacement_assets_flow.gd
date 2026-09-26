extends SceneTree

const ASSETS := [
	"res://assets/models/props/common/desk_lamp.glb",
	"res://assets/models/props/common/oil_lamp_round.glb",
	"res://assets/models/props/common/table_lamp_a.glb",
	"res://assets/models/props/domestic/decorative_bowl_ceramic.glb",
	"res://assets/models/props/domestic/parlor_armchair_a.glb",
	"res://assets/models/props/domestic/parlor_armchair_b.glb",
	"res://assets/models/props/domestic/parlor_sofa_tufted.glb",
	"res://assets/models/props/domestic/stone_fireplace.glb",
	"res://assets/models/props/domestic/throw_pillow_burgundy.glb",
	"res://assets/models/props/domestic/throw_pillow_green.glb",
	"res://assets/models/props/domestic/vase_ceramic_round.glb",
	"res://assets/models/props/domestic/vase_ceramic_tall.glb",
]

func _initialize() -> void:
	for path in ASSETS:
		var packed := load(path) as PackedScene
		assert(packed != null, path + " must import as a PackedScene")
		var instance := packed.instantiate() as Node3D
		assert(instance != null, path + " must instantiate as Node3D")
		root.add_child(instance)
		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		if instance is MeshInstance3D: meshes.push_front(instance)
		assert(meshes.size() == 1, path + " must remain one placement mesh")
		var mesh_instance := meshes[0] as MeshInstance3D
		var bounds := mesh_instance.get_aabb()
		assert(absf(bounds.position.y) < 0.01, "%s must remain grounded; min y=%f" % [path, bounds.position.y])
		assert(mesh_instance.mesh.get_surface_count() == 1, path + " must retain one material surface")
		assert(mesh_instance.mesh.surface_get_material(0) != null, path + " must retain its material")
		instance.free()
	print("BATCH 8 REPLACEMENT ASSETS PASS: 12 textured, single-mesh, grounded props load cleanly")
	quit(0)
