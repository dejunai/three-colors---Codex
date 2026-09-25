extends RefCounted

# Cached, deliberately low-resolution town surfaces.  The patterns are generated
# at startup rather than shipped as large source images; each district keeps a
# small material vocabulary and the geometry remains the same primitive blockout.
static var _textures: Dictionary = {}
static var _materials: Dictionary = {}

static func material(kind: String, tint: String, scale: float = -1.0) -> StandardMaterial3D:
	var resolved_scale := scale if scale > 0.0 else _default_scale(kind)
	var key := "%s:%s:%.3f" % [kind, tint, resolved_scale]
	if _materials.has(key): return _materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(tint)
	result.albedo_texture = texture(kind)
	result.uv1_triplanar = true
	result.uv1_scale = Vector3.ONE * resolved_scale
	result.roughness = 0.94
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = result
	return result

static func apply(node: MeshInstance3D, kind: String, tint: String, scale: float = -1.0) -> MeshInstance3D:
	if is_instance_valid(node): node.material_override = material(kind, tint, scale)
	return node

static func texture(kind: String) -> ImageTexture:
	if _textures.has(kind): return _textures[kind]
	var image := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var random := RandomNumberGenerator.new()
	random.seed = hash("widows-bight:" + kind)
	for y in 128:
		for x in 128:
			var value := 0.82 + random.randf_range(-0.055, 0.055)
			var stain := 0.0
			match kind:
				"brick":
					var row := floori(y / 16.0)
					if y % 16 < 2 or (x + (16 if row % 2 else 0)) % 32 < 2: value = 0.48
					elif random.randf() < 0.025: value -= 0.12
				"soot_brick":
					var row := floori(y / 16.0)
					if y % 16 < 2 or (x + (16 if row % 2 else 0)) % 32 < 2: value = 0.43
					stain = 0.11 * (1.0 - float(y) / 127.0) + 0.025 * sin(float(x) * 0.21)
					value -= stain
				"stone":
					var row := floori(y / 32.0)
					if y % 32 < 2 or (x + (16 if row % 2 else 0)) % 32 < 2: value = 0.50
				"cut_stone":
					if y % 24 < 2 or x % 32 < 2: value = 0.62
					elif (x + y * 3) % 53 == 0: value -= 0.08
				"cobble":
					var row := floori(y / 16.0)
					var xx := (x + (8 if row % 2 else 0)) % 16
					if y % 16 < 2 or xx < 2: value = 0.42
					else: value += 0.035 * sin(float(x + y) * 0.43)
				"patched_cobble":
					var row := floori(y / 16.0)
					var xx := (x + (8 if row % 2 else 0)) % 16
					if y % 16 < 2 or xx < 2: value = 0.39
					elif (floori(x / 32.0) + floori(y / 32.0)) % 3 == 0: value -= 0.11
				"plaster":
					value += 0.025 * sin(float(x) * 0.13) + 0.018 * sin(float(y) * 0.19)
					if random.randf() < 0.012: value -= 0.14
				"cracked_plaster":
					value += 0.02 * sin(float(x + y) * 0.15)
					if (x + y * 2) % 47 < 2 and y % 13 < 8: value = 0.48
				"wood", "salt_wood", "tar_wood":
					value += sin(float(x) * 0.72 + sin(float(y) * 0.08)) * 0.035
					if x % 32 < 2: value = 0.43
					if kind == "salt_wood": value += 0.08 * sin(float(y) * 0.035)
					if kind == "tar_wood": value -= 0.17 + 0.04 * sin(float(y) * 0.09)
				"slate":
					var row := floori(y / 24.0)
					if y % 24 < 2 or (x + (12 if row % 2 else 0)) % 24 < 1: value = 0.40
				"rust_metal":
					value = 0.68 + random.randf_range(-0.06, 0.06)
					if random.randf() < 0.09: value -= random.randf_range(0.12, 0.28)
				"algae_stone":
					var row := floori(y / 32.0)
					if y % 32 < 2 or (x + (16 if row % 2 else 0)) % 32 < 2: value = 0.45
					value -= maxf(0.0, 0.12 - float(y % 64) / 600.0)
				_:
					pass
			value = clampf(value, 0.22, 1.0)
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	var result := ImageTexture.create_from_image(image)
	_textures[kind] = result
	return result

static func _default_scale(kind: String) -> float:
	if kind in ["wood", "salt_wood", "tar_wood"]: return 0.82
	if kind in ["cobble", "patched_cobble"]: return 0.42
	if kind in ["brick", "soot_brick"]: return 0.56
	return 0.52
