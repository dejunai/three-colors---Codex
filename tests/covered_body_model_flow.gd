extends SceneTree

const CoveredBodyModel = preload("res://scripts/shared/covered_body_model.gd")

func _initialize() -> void:
	# 1. Adult model (Naomi Freeman)
	var naomi = CoveredBodyModel.create(false)
	assert(naomi != null, "CoveredBodyModel.create() must return a valid Node3D")
	assert(naomi.name == "CoveredBody")
	
	var rendered_naomi = naomi.get_node_or_null("RenderedCoveredBody")
	assert(rendered_naomi != null, "Must contain RenderedCoveredBody")
	assert(is_equal_approx(rendered_naomi.scale.x, CoveredBodyModel.SCALE_FACTOR), "Adult scale must match SCALE_FACTOR")
	
	# Find MeshInstance3D
	var mesh_inst: MeshInstance3D = null
	for child in rendered_naomi.get_children():
		if child is MeshInstance3D:
			mesh_inst = child
			break
		for grandchild in child.get_children():
			if grandchild is MeshInstance3D:
				mesh_inst = grandchild
				break
	
	assert(mesh_inst != null, "Must contain a MeshInstance3D")
	var aabb = mesh_inst.get_aabb()
	print("Naomi Covered Mesh AABB: ", aabb)
	assert(aabb.position.y >= -0.05 and aabb.position.y <= 0.05, "Sheet should be grounded near Y=0")
	assert(aabb.position.z < -0.5, "Head should extend into negative Z")
	assert(aabb.end.z > 0.5, "Feet should extend into positive Z")
	
	# 2. Child model (young son)
	var son = CoveredBodyModel.create(true)
	assert(son.name == "CoveredBody_Child")
	var rendered_son = son.get_node_or_null("RenderedCoveredBody")
	var expected_son_scale = CoveredBodyModel.SCALE_FACTOR * CoveredBodyModel.CHILD_SCALE_RATIO
	assert(is_equal_approx(rendered_son.scale.x, expected_son_scale), "Son scale must be scaled down to young child ratio")
	assert(rendered_son.scale.x < rendered_naomi.scale.x * 0.7, "Son must be distinctly smaller than Naomi")
	
	naomi.free()
	son.free()
	print("COVERED BODY MODEL PASS: adult and child covered models instantiate cleanly at correct scale hierarchy, grounded at Y=0")
	quit(0)
