extends SceneTree

const VictimModel = preload("res://scripts/shared/victim_model.gd")

func _initialize() -> void:
	var victim = VictimModel.create()
	assert(victim != null, "VictimModel.create() must return a valid Node3D")
	assert(victim.name == "MurderVictim", "Wrapper should be named MurderVictim")
	
	var rendered = victim.get_node_or_null("RenderedVictim")
	assert(rendered != null, "Must have RenderedVictim child")
	assert(is_equal_approx(rendered.scale.x, VictimModel.SCALE_FACTOR), "Scale should match SCALE_FACTOR")
	
	# Find MeshInstance3D
	var mesh_inst: MeshInstance3D = null
	for child in rendered.get_children():
		if child is MeshInstance3D:
			mesh_inst = child
			break
		for grandchild in child.get_children():
			if grandchild is MeshInstance3D:
				mesh_inst = grandchild
				break
	
	assert(mesh_inst != null, "Must contain a MeshInstance3D")
	var aabb = mesh_inst.get_aabb()
	print("Victim Mesh AABB: ", aabb)
	print("AABB min: ", aabb.position, " max: ", aabb.end)
	
	# Verify that in Godot:
	# Y is UP (height should be positive, resting near 0)
	assert(aabb.position.y >= -0.05 and aabb.position.y <= 0.05, "Back should be grounded near Y=0")
	# Z is length (head to feet): -Z to +Z
	assert(aabb.position.z < -0.5, "Head should extend into negative Z")
	assert(aabb.end.z > 0.5, "Feet should extend into positive Z")
	
	victim.free()
	print("VICTIM MODEL PASS: model instantiates cleanly, correctly grounded at Y=0 with head at -Z and feet at +Z")
	quit(0)
