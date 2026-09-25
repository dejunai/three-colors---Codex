extends SceneTree

const ASSETS := [
	"envelope_stack",
	"parcel_tied_square",
	"parcel_wrapped_large",
	"parcel_wrapped_long",
	"post_office_balance_scale",
	"post_office_corkboard",
	"post_office_frosted_window",
	"post_office_hanging_sign",
	"post_office_pendant_a",
	"post_office_pendant_b",
]

func _initialize() -> void:
	for asset_name in ASSETS:
		var path := "res://assets/models/props/civic/%s.glb" % asset_name
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
	print("BATCH 7 POST-OFFICE ASSETS PASS: 10 textured, single-mesh, grounded props load cleanly")
	quit(0)
