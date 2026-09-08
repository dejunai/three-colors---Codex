extends SceneTree

# Standalone check for scripts/shared/trinket_generator.gd, runnable directly:
#   godot --headless --path . --script res://tests/trinket_generator.gd
# No chapter context needed, so this doesn't go through chapter_one.gd's --qa
# argument parsing the way the other test suites do.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Estate = load("res://estate.gd")
	var Generator = load("res://scripts/shared/trinket_generator.gd")
	var host = Estate.new()
	var gen = Generator.new()

	var a = gen.build(host,42,"common")
	var b = gen.build(host,42,"common")
	assert(a.get_child_count()==b.get_child_count(),"The same seed must produce the same shape count")
	for i in a.get_child_count():
		var shape_a:MeshInstance3D = a.get_child(i)
		var shape_b:MeshInstance3D = b.get_child(i)
		assert(shape_a.mesh.get_class()==shape_b.mesh.get_class(),"The same seed must produce the same shape kinds in the same order")
		assert(shape_a.mesh.get_aabb()==shape_b.mesh.get_aabb(),"The same seed must produce the same shape dimensions")
		assert(shape_a.position==shape_b.position,"The same seed must produce the same layout")
		assert(shape_a.material_override==shape_b.material_override,"The same seed must produce the same color")
	assert(a!=b,"Each call still builds its own, independent node")

	var c = gen.build(host,43,"common")
	var same_everything=true
	if a.get_child_count()!=c.get_child_count(): same_everything=false
	else:
		for i in a.get_child_count():
			if a.get_child(i).position!=c.get_child(i).position: same_everything=false
	assert(not same_everything,"A different seed must not coincidentally reproduce the same trinket")

	for seed in range(200):
		var trinket = gen.build(host,seed,"common")
		assert(trinket.get_child_count()>=1,"Every common trinket must have visible geometry")
		for child in trinket.get_children():
			assert(child is MeshInstance3D,"Every child must be an actual rendered shape")

	var common = gen.build(host,7,"common")
	var artifact = gen.build(host,7,"artifact")
	assert(artifact.get_child_count()>=common.get_child_count(),"Artifact tier is at least as detailed as common tier")
	var glowing=false
	for child in artifact.get_children():
		if child.material_override.emission_enabled: glowing=true
	assert(glowing,"Artifact tier marks itself with the shared glow flag, not a reserved color")
	for child in common.get_children():
		assert(not child.material_override.emission_enabled,"Common tier never borrows the artifact mark")

	# The Observer accent's red-dominance channel must stay reserved: nothing
	# generated here may share that hue, at either tier.
	for tier in ["common","artifact"]:
		for seed in range(60):
			var trinket = gen.build(host,seed+1000,tier)
			for child in trinket.get_children():
				var albedo:Color = child.material_override.albedo_color
				assert(albedo.r<=maxf(albedo.g,albedo.b)+0.05,"Trinket colors must not trip the Observer red-dominance shader tell")

	print("TRINKET PASS: deterministic per seed, varied across seeds, tier distinction via glow only, Observer hue reserved")
	host.free()
	quit(0)
