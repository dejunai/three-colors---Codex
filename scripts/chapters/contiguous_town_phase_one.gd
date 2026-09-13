extends RefCounted

# Phase 1 begins at Pickman Street and grows northward. Pickman and the business
# district now share a walkable exterior; the upper quarter is established above
# their roofline for the next seam.

const BusinessStreet = preload("res://scripts/chapters/business_street.gd")
const UpperStreet = preload("res://scripts/chapters/upper_street.gd")
const Places = preload("res://scripts/chapters/town_places.gd")
const BUSINESS_ORIGIN = Vector3(0, 5.5, 67)
const UPPER_ORIGIN = Vector3(0, 12.5, 134)

class PlacementProxy extends Node3D:
	var host: Node
	var routes: Dictionary

	func _init(owner: Node) -> void:
		host = owner
		routes = owner.routes

	func box(_parent: Node, p: Vector3, size: Vector3, color: String, solid: bool = false):
		return host.box(self, p, size, color, solid)

	func lettering(text: String, p: Vector3, font_size: int = 56):
		var label = host.lettering(text, position + p, font_size)
		return label

	func target(id: String, title: String, p: Vector3) -> void:
		host.target(id, title, position + p)

	func lamp(p: Vector3, tall: bool = true) -> void:
		host.lamp(position + p, tall)

	func cylinder(_parent: Node, p: Vector3, radius: float, height: float, color: String, top: float = -1.0):
		return host.cylinder(self, p, radius, height, color, top)

	func tree(p: Vector3) -> void:
		host.tree(position + p)

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
	# Keep the walking face uninterrupted. Earlier horizontal course strips were
	# positioned above the tilted plane and read as floating step barriers.

	# Uneven retaining walls make the climb feel fitted into older construction.
	for side in [-1.0, 1.0]:
		for section in 4:
			var z = 27.0 + section * 6.0
			var y = 0.9 + section * 1.25
			g.box(root, Vector3(8 + side * 4.2, y, z), Vector3(0.65, 1.8 + section * 0.7, 6.4), "505d53", true)

	# Step 1's compatibility route is removed after build_business folds the
	# existing street into this exterior.
	g.target("route_business", "Continue uphill to the business district", Vector3(8, 5.5, 48))
	g.routes["route_business"] = ["business", Vector3(10, 0.1, 25), 0.0]

static func build_business(g: Node) -> void:
	var phase_root = g.get_node("ContiguousTownPhaseOne")
	var proxy = PlacementProxy.new(g)
	proxy.name = "BusinessDistrictExterior"
	proxy.position = BUSINESS_ORIGIN
	phase_root.add_child(proxy)
	BusinessStreet.new().build(proxy)
	_build_business_retaining_works(g, phase_root)
	# The incline is now the exterior connection. Keep interior route IDs, but
	# remove both obsolete exterior-to-exterior transition targets.
	for id in ["route_business", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func _build_business_retaining_works(g: Node, root: Node3D) -> void:
	# The raised business block is earth retained by old masonry, rather than a
	# street-width slab hanging in the air. Its southern face leaves one gateway
	# around the Pickman incline and closes the exposed void on either side.
	g.box(root, Vector3(-14.65, 2.45, 50.0), Vector3(36.7, 4.9, 1.2), "4d5850", true)
	g.box(root, Vector3(22.65, 2.45, 50.0), Vector3(20.7, 4.9, 1.2), "4d5850", true)
	# Deep side walls make the plateau read as terrain fitted between buildings.
	for x in [-32.4, 32.4]:
		g.box(root, Vector3(x, 2.35, 77.0), Vector3(1.2, 4.7, 53.0), "465249", true)
	# Uneven buttresses and a heavy gateway lintel keep the support hand-built.
	for x in [-30.0, -19.0, -7.0, 15.0, 27.0]:
		g.box(root, Vector3(x, 2.55, 49.25), Vector3(1.6, 5.1, 2.3), "5c675b", true)
	g.box(root, Vector3(8.0, 4.55, 49.35), Vector3(8.6, 0.8, 2.0), "626d60", true)
	for x in [4.0, 12.0]:
		g.box(root, Vector3(x, 2.0, 49.2), Vector3(0.75, 4.0, 2.2), "596459", true)

static func build_upper_approach(g: Node) -> void:
	var root = g.get_node("ContiguousTownPhaseOne")
	# The first upper-quarter connection occupies the quieter northwest end of
	# the business block. An underlying ramp keeps traversal smooth; shallow
	# stone courses make the grade read as old, repaired steps.
	var rise = 7.5
	var run = 18.0
	var slope_length = sqrt(rise * rise + run * run)
	# Bury the leading edge slightly below the business pavement so the
	# CharacterBody never encounters a collision lip at the grade change.
	var center = Vector3(-24, 8.85, 108)
	var ramp = g.box(root, center, Vector3(6.0, 0.42, slope_length), "747c70")
	ramp.name = "UpperQuarterApproach"
	ramp.rotation.x = -atan2(rise, run)
	var body = StaticBody3D.new()
	body.name = "UpperQuarterApproachCollision"
	body.position = center
	body.rotation = ramp.rotation
	root.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(6.0, 0.42, slope_length)
	collision.shape = shape
	body.add_child(collision)
	# The incline itself remains one continuous surface. Masonry rhythm belongs
	# on its retaining walls; separate horizontal strips visibly float here.
	for side in [-1.0, 1.0]:
		# Leave the first metre open so the approach can be entered laterally
		# behind the last storefront before the walls close around it.
		g.box(root, Vector3(-24 + side * 3.45, 8.6, 109), Vector3(0.6, 6.2, 15.0), "4f5b51", true)
		for z in [100.0, 106.0, 112.0]:
			g.box(root, Vector3(-24 + side * 3.0, 6.2 + (z - 99.0) * rise / run, z), Vector3(0.25, 1.1, 0.25), "879181")
	# This remains a compatibility handoff until Step 4 folds the upper street
	# into the shared exterior. Its location now corresponds to real geography.
	g.target("route_upper", "Continue uphill to the upper quarter", Vector3(-24, 12.6, 117))
	g.routes["route_upper"] = ["upper", Vector3(10, 0.1, 25), 0.0]

static func build_upper(g: Node) -> void:
	var phase_root = g.get_node("ContiguousTownPhaseOne")
	var proxy = PlacementProxy.new(g)
	proxy.name = "UpperDistrictExterior"
	proxy.position = UPPER_ORIGIN
	phase_root.add_child(proxy)
	UpperStreet.new().build(proxy)
	# The existing climb is now the district boundary; exterior route portals
	# disappear while all residence routes remain stable.
	for id in ["route_upper", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func business_return(interior_id: String) -> Variant:
	var specs: Array = Places.BUILDINGS.business
	for index in specs.size():
		if String(specs[index][0]) != interior_id: continue
		var toward_street = Vector3(0, 0.1, 1.5 if index < 3 else -1.5)
		return BUSINESS_ORIGIN + Places.front(index) + toward_street
	return null

static func upper_return(interior_id: String) -> Variant:
	var specs: Array = Places.BUILDINGS.upper
	for index in specs.size():
		if String(specs[index][0]) != interior_id: continue
		var toward_street = Vector3(0, 0.1, 1.5 if index < 3 else -1.5)
		return UPPER_ORIGIN + Places.front(index) + toward_street
	return null
