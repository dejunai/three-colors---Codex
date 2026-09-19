extends SceneTree

# The Observer color tell (Design Bible Part Two) must survive every hour of the day
# clock. A lit accent lost its red once the scene dimmed: film.gdshader only passes
# pixels whose red leads green and blue, and lighting scales that lead toward zero.
# Measured in a real window: the lit accent rendered 0 colored pixels at every phase
# including morning; the unlit accent rendered the same count at every phase.
#   godot --headless --path . --script res://tests/observer_accent_flow.gd

# film.gdshader's red_dominance = smoothstep(0.05, 0.22, r - max(g, b)); at or above
# the upper edge the accent passes at full strength.
const SHADER_FULL_PASS = 0.22
# Every accent color currently used: groundskeeper (estate.gd) and harbor_observer
# (chapter_one_dialogue.gd).
const ACCENTS = ["7a2a1a", "b8743a"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var estate = load("res://estate.gd").new()
	root.add_child(estate)
	await process_frame
	for hex in ACCENTS:
		var c = Color(hex)
		assert(c.r - maxf(c.g, c.b) >= SHADER_FULL_PASS, "Accent %s must pass the shader's red-dominance band at full strength" % hex)
		var figure = estate.person(Vector3.ZERO, "55624f", true, hex)
		var jewel = figure.get_node("Accent") as MeshInstance3D
		var material = jewel.material_override as StandardMaterial3D
		assert(material != null and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "Accent %s must ignore lighting" % hex)
		assert(material.disable_fog, "Accent %s must ignore fog" % hex)
		assert(material.albedo_color.is_equal_approx(c))
		assert(jewel.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		for arm_name in ["LeftArm", "RightArm"]:
			var band = figure.get_node(arm_name + "/AccentBand") as MeshInstance3D
			assert(band != null and (band.material_override as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "Each wrist band must carry the tell from any side, unlit")
	var plain = estate.person(Vector3.ZERO, "55624f")
	assert(not plain.has_node("Accent"), "Only Observers carry the tell")
	# The groundskeeper built by the real estate scene carries it too.
	assert(estate.groundskeeper_actor.get_node("Accent").material_override.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
	print("OBSERVER ACCENT PASS: every Observer accent is unlit, fog-free and inside the shader's full-pass band; ordinary figures carry none")
	quit(0)
