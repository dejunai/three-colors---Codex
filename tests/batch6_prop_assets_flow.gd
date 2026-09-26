extends SceneTree

const ASSETS := [
	"barrel_side_hd",
	"barrel_upright_hd",
	"bench_plank_low",
	"bucket_wooden",
	"cargo_bundle_roped",
	"crate_slatted_hd",
	"fish_pile",
	"fish_single",
	"rope_coil_flat",
	"rope_coil_tall",
	"sack_tied",
	"stool_rustic",
	"stump_seat",
	"work_table_rustic",
]

func _initialize() -> void:
	for asset_name in ASSETS:
		var path := "res://assets/models/props/common/%s.glb" % asset_name
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
	print("BATCH 6 PROP ASSETS PASS: 14 textured, single-mesh, grounded props load cleanly")
	quit(0)
