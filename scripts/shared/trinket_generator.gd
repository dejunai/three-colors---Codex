extends RefCounted

# Procedural Trinket Generation (Design Bible, Chapter Two Mechanics): the
# fiction needs thousands of trinkets: production does not. Felt abundance is
# a systemic effect, not an asset-count commitment. Only the roughly two
# hundred artifacts of real value need individual, bespoke authorship — and
# "bespoke" here means a hand-authored data entry (name, description, source,
# significance), not a hand-authored mesh. Every trinket, common or artifact,
# is composed from the same primitive vocabulary (box/cylinder/sphere) the
# rest of this build already uses, per the procedural-geometry pipeline
# decision in docs/ARCHITECTURE.md.
#
# A given seed always produces the same shapes, sizes, and color: a player's
# saved inventory must render identically on reload without storing geometry.
#
# This is a starting point for Chapter Two, not a finished system — no
# chapter currently calls it. It exists to prove the approach (seeded,
# parametric, reusing the existing helpers) rather than to author actual
# Chapter Two content, which needs its own design pass.

# Colors stay inside the same desaturated gray/green/brown discipline every
# other material in this build already respects, so nothing generated here
# can accidentally trip film.gdshader's red-dominance Observer tell. That
# color channel is reserved for Design Law 5's supernatural tell; ordinary
# valuables never borrow it, however rare.
const COMMON_PALETTE = ["656a66","747b6c","555b50","3b443b","5c7050","6a7962","4d654b","8d977f"]
const ARTIFACT_PALETTE = ["a5a698","b7b6a7","989b90","c5c5bd","aaa99d","9fa295"]

# host must expose estate.gd's box/cylinder/sphere/mat interface (estate.gd
# itself, or anything extending it, e.g. tunnel.gd or a future Chapter Two
# world). mount defaults to host; pass a different Node3D to place the
# trinket somewhere other than directly under the world root (an inventory
# slot anchor, a pickup point already parented elsewhere).
func build(host:Node3D,seed:int,tier:String="common",mount:Node3D=null) -> Node3D:
	if mount == null: mount = host
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var root = Node3D.new()
	root.name = "Trinket"+str(seed)
	mount.add_child(root)
	var artifact = tier == "artifact"
	var palette = ARTIFACT_PALETTE if artifact else COMMON_PALETTE
	var color = palette[rng.randi() % palette.size()]
	var shape_count = rng.randi_range(2,4) if artifact else rng.randi_range(1,2)
	for i in shape_count:
		var offset = Vector3(rng.randf_range(-0.045,0.045),i*rng.randf_range(0.02,0.045),rng.randf_range(-0.045,0.045))
		match rng.randi() % 3:
			0: host.box(root,offset,Vector3(rng.randf_range(0.03,0.09),rng.randf_range(0.02,0.06),rng.randf_range(0.03,0.09)),color,false)
			1: host.cylinder(root,offset,rng.randf_range(0.018,0.05),rng.randf_range(0.03,0.09),color)
			2: host.sphere(root,offset,rng.randf_range(0.018,0.05),color)
	if artifact:
		# The one liberty artifact tier takes: a faint glow, not a color, marks
		# something as worth cataloging. Still inside the safe palette.
		var mark = host.mat(color,true)
		for child in root.get_children():
			if child is MeshInstance3D: child.material_override = mark
	return root
