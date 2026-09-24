extends SceneTree

const MODELS_TO_CHECK = [
	"res://assets/models/steward.glb",
	"res://assets/models/coroner.glb",
	"res://assets/models/coroners_assistant.glb",
	"res://assets/models/father_behan.glb",
	"res://assets/models/gatekeeper_boy.glb",
	"res://assets/models/captain_odell.glb",
	"res://assets/models/walter_phase1.glb",
	"res://assets/models/cast_upper_man.glb",
	"res://assets/models/cast_upper_woman.glb",
	"res://assets/models/cast_lower_man.glb",
	"res://assets/models/cast_lower_woman.glb",
	"res://assets/models/cast_observer_man.glb",
	"res://assets/models/cast_observer_woman.glb",
	"res://assets/models/murder_victim.glb",
	"res://assets/models/covered_body.glb",
	"res://assets/models/waterfront/dock_crane.glb",
	"res://assets/models/waterfront/fishing_boat.glb",
	"res://assets/models/waterfront/boat_frame.glb",
	"res://assets/models/waterfront/cargo_cluster.glb",
	"res://assets/models/waterfront/dock_shed.glb",
	"res://assets/models/waterfront_phase1.glb",
]

func check_scene(path: String) -> void:
	var s = load(path)
	assert(s != null, "Failed to load scene: " + path)
	var inst = s.instantiate()
	assert(inst != null, "Failed to instantiate scene: " + path)
	var meshes = inst.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() > 0, "No MeshInstance3D found in " + path)
	print("--- Scene: ", path, " (found ", meshes.size(), " meshes) ---")
	for m in meshes:
		var surface_count = m.mesh.get_surface_count() if m.mesh else 0
		print("  Mesh: ", m.name, " (surfaces: ", surface_count, ")")
		for i in range(surface_count):
			var mat = m.get_surface_override_material(i)
			if mat == null and m.mesh:
				mat = m.mesh.surface_get_material(i)
			assert(mat != null, "Null material on surface " + str(i) + " of " + m.name + " in " + path)
			if mat is StandardMaterial3D:
				assert(mat.albedo_texture != null, "Missing albedo_texture on surface " + str(i) + " of " + m.name + " in " + path)
				print("    Surface ", i, " OK - Texture: ", mat.albedo_texture.resource_path)
			else:
				print("    Surface ", i, " Material: ", mat.get_class())
	inst.free()

func _initialize() -> void:
	print("Running full model & quay texture validation...")
	for p in MODELS_TO_CHECK:
		check_scene(p)
	print("\nALL MODELS AND QUAY PROPS PASS TEXTURE AUDIT 100%!")
	quit(0)
