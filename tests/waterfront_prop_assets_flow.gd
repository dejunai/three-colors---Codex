extends SceneTree

const ASSETS := [
	"boat_frame",
	"cargo_cluster",
	"dock_crane",
	"dock_shed",
	"fishing_boat",
]

func _initialize() -> void:
	for asset_name in ASSETS:
		var path := "res://assets/models/waterfront/%s.glb" % asset_name
		var packed := load(path) as PackedScene
		assert(packed != null, "%s must import as a PackedScene" % path)
		var instance := packed.instantiate()
		root.add_child(instance)
		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		if instance is MeshInstance3D: meshes.push_front(instance)
		assert(meshes.size() == 1, "%s must remain one placement mesh; found %d" % [asset_name, meshes.size()])
		var bounds: AABB = (meshes[0] as MeshInstance3D).get_aabb()
		assert(absf(bounds.position.y) < 0.01, "%s must retain its bottom-grounded pivot; min y=%f" % [asset_name, bounds.position.y])
		assert(bounds.size.length() > 0.5, "%s must have nontrivial visible bounds" % asset_name)
		instance.queue_free()
	print("WATERFRONT PROP ASSETS PASS: five 2K quay props load as single, bottom-grounded placement meshes")
	quit(0)
