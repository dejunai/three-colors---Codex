extends SceneTree

const CastModel = preload("res://scripts/shared/cast_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Verify instantiation of all 6 archetypes
	var archetypes := [
		CastModel.UPPER_MAN,
		CastModel.UPPER_WOMAN,
		CastModel.LOWER_MAN,
		CastModel.LOWER_WOMAN,
		CastModel.OBSERVER_MAN,
		CastModel.OBSERVER_WOMAN,
	]
	for arch in archetypes:
		var model := CastModel.create(arch)
		assert(model != null, "Archetype %s must instantiate" % arch)
		root.add_child(model)
		assert(model.get_meta("archetype") == arch, "Metadata must match archetype %s" % arch)
		var rendered: Node3D = model.get_node_or_null("RenderedCast")
		assert(rendered != null, "Must have RenderedCast child for %s" % arch)
		assert(is_equal_approx(rendered.scale.y, 1.05), "Scale must be 1.05 for %s" % arch)
		assert(is_equal_approx(rendered.rotation.y, PI), "Rotation must be PI for %s" % arch)
		model.queue_free()

	# 2. Verify NPC classification logic
	assert(CastModel.archetype_for_npc("harbor_observer") == CastModel.OBSERVER_MAN)
	assert(CastModel.archetype_for_npc("waterfront_sail_mender") == CastModel.OBSERVER_MAN)
	assert(CastModel.archetype_for_npc("crew") == CastModel.OBSERVER_MAN)
	assert(CastModel.archetype_for_npc("almy") == CastModel.UPPER_WOMAN)
	assert(CastModel.archetype_for_npc("mrs_almy") == CastModel.UPPER_WOMAN)
	assert(CastModel.archetype_for_npc("old_woman") == CastModel.LOWER_WOMAN)
	assert(CastModel.archetype_for_npc("widow_kessler") == CastModel.LOWER_WOMAN)
	assert(CastModel.archetype_for_npc("mr_whitehouse") == CastModel.UPPER_MAN)
	assert(CastModel.archetype_for_npc("clockmaker") == CastModel.UPPER_MAN)
	assert(CastModel.archetype_for_npc("business_resident_01") == CastModel.UPPER_MAN)
	assert(CastModel.archetype_for_npc("quay_docker") == CastModel.LOWER_MAN)
	assert(CastModel.archetype_for_npc("waterfront_stevedore") == CastModel.LOWER_MAN)
	assert(CastModel.archetype_for_npc("lower_laundress") == CastModel.LOWER_WOMAN)
	assert(CastModel.archetype_for_npc("miriam_ashcroft") == CastModel.UPPER_WOMAN)
	assert(CastModel.archetype_for_npc("eleanor_whitlock") == CastModel.UPPER_WOMAN)
	assert(CastModel.archetype_for_npc("schoolteacher") == CastModel.UPPER_WOMAN)
	assert(CastModel.archetype_for_npc("salt_mender") == CastModel.LOWER_WOMAN)
	assert(CastModel.archetype_for_npc("gardener") == CastModel.LOWER_MAN)

	# 3. Verify Observer tell attachment
	var sail_mender_fig := CastModel.create_for_npc("waterfront_sail_mender")
	assert(sail_mender_fig.has_node("Accent"), "Observer figures must receive an Accent tell")
	var tell_mesh := sail_mender_fig.get_node("Accent") as MeshInstance3D
	var tell_mat := tell_mesh.material_override as StandardMaterial3D
	assert(tell_mat != null and tell_mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "Tell must be unshaded")
	assert(tell_mat.disable_fog, "Tell must disable fog")
	sail_mender_fig.queue_free()

	print("CAST MODEL PASS: all 6 archetypes instantiate at 1.05 scale with PI yaw, and NPC classification maps accurately")
	quit(0)

