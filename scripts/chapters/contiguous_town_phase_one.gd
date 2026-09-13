extends RefCounted

# Phase 1 begins at Pickman Street and grows northward. This first seam keeps
# the business district as its existing scene while giving it a real, walkable
# uphill approach and establishing the upper quarter above the roofline.

static func build_pickman_edge(g: Node) -> void:
	var root = Node3D.new()
	root.name = "ContiguousTownPhaseOne"
	g.add_child(root)

	# A crooked stone ramp rises through the former flat destination portal.
	# The shallow grade is comfortably inside CharacterBody3D's floor angle.
	var rise = 6.0
	var run = 30.0
	# Sink the long leading edge beneath the existing street surface. This avoids
	# a tiny vertical lip that CharacterBody3D correctly treats as a wall.
	var ramp = g.box(root, Vector3(8, 2.30, 35), Vector3(7.2, 0.42, run), "717b70")
	ramp.name = "BusinessApproach"
	ramp.rotation.x = -atan2(rise, run)
	var ramp_body = StaticBody3D.new()
	ramp_body.name = "BusinessApproachCollision"
	ramp_body.position = ramp.position
	ramp_body.rotation = ramp.rotation
	root.add_child(ramp_body)
	var ramp_collision = CollisionShape3D.new()
	var ramp_shape = BoxShape3D.new()
	ramp_shape.size = Vector3(7.2, 0.42, run)
	ramp_collision.shape = ramp_shape
	ramp_body.add_child(ramp_collision)
	for z in range(22, 50, 3):
		var progress = float(z - 20) / run
		var y = progress * rise + 0.08
		g.box(root, Vector3(8, y, z), Vector3(6.5, 0.025, 0.12), "a1a594")

	# Uneven retaining walls make the climb feel fitted into older construction.
	for side in [-1.0, 1.0]:
		for section in 4:
			var z = 27.0 + section * 6.0
			var y = 0.9 + section * 1.25
			g.box(root, Vector3(8 + side * 4.2, y, z), Vector3(0.65, 1.8 + section * 0.7, 6.4), "505d53", true)

	# The upper quarter is only a silhouette in this seam. Its mass and lamps are
	# already visible above business roofs, fixing the permanent vertical order.
	for spec in [[-6.0, 12.5, 8.0], [5.0, 15.0, 10.5], [18.0, 11.0, 7.2]]:
		var x: float = spec[0]
		var h: float = spec[1]
		var w: float = spec[2]
		g.box(root, Vector3(x, 8.0 + h * 0.5, 58), Vector3(w, h, 7), "4b594f")
		g.box(root, Vector3(x, 8.2 + h, 58), Vector3(w + 0.6, 0.45, 7.5), "303d35")
	for x in [-8.0, 8.0, 20.0]: g.lamp(Vector3(x, 7.9, 52))

	# Retain the stable route id until the business street is physically folded
	# into this exterior in the next seam.
	g.target("route_business", "Continue uphill to the business district", Vector3(8, 5.5, 48))
	g.routes["route_business"] = ["business", Vector3(10, 0.1, 25), 0.0]
