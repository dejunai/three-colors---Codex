extends RefCounted

# Phase 1 begins at Pickman Street and grows northward. Pickman and the business
# district now share a walkable exterior; the upper quarter is established above
# their roofline for the next seam.

const BusinessStreet = preload("res://scripts/chapters/business_street.gd")
const Places = preload("res://scripts/chapters/town_places.gd")
const BUSINESS_ORIGIN = Vector3(0, 5.5, 67)

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
		g.box(root, Vector3(x, 13.0 + h * 0.5, 112), Vector3(w, h, 7), "4b594f")
		g.box(root, Vector3(x, 13.2 + h, 112), Vector3(w + 0.6, 0.45, 7.5), "303d35")
	for x in [-8.0, 8.0, 20.0]: g.lamp(Vector3(x, 12.9, 106))

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
	# The incline is now the exterior connection. Keep interior route IDs, but
	# remove both obsolete exterior-to-exterior transition targets.
	for id in ["route_business", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func business_return(interior_id: String) -> Variant:
	var specs: Array = Places.BUILDINGS.business
	for index in specs.size():
		if String(specs[index][0]) != interior_id: continue
		var toward_street = Vector3(0, 0.1, 1.5 if index < 3 else -1.5)
		return BUSINESS_ORIGIN + Places.front(index) + toward_street
	return null
