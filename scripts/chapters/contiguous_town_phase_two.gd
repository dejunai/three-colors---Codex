extends RefCounted

const LowerStreet = preload("res://scripts/chapters/lower_street.gd")
const Waterfront = preload("res://scripts/chapters/waterfront_district.gd")
const Places = preload("res://scripts/chapters/town_places.gd")
const DistrictSurfaces = preload("res://scripts/shared/district_surfaces.gd")
const LOWER_ORIGIN = Vector3(91, -2.3, 0)
const WATERFRONT_ORIGIN = Vector3(100, -5.0, -60)

class PlacementProxy extends Node3D:
	var host: Node
	var routes: Dictionary

	func _init(owner: Node) -> void:
		host = owner
		routes = owner.routes

	func box(parent: Node, p: Vector3, size: Vector3, color: String, solid: bool = false):
		return host.box(self if parent == self or parent == host else parent, p, size, color, solid)

	func cylinder(parent: Node, p: Vector3, radius: float, height: float, color: String, top: float = -1.0):
		return host.cylinder(self if parent == self or parent == host else parent, p, radius, height, color, top)

	func lettering(text: String, p: Vector3, font_size: int = 56):
		return host.lettering(text, position + p, font_size)

	func target(id: String, title: String, p: Vector3) -> void:
		host.target(id, title, position + p)

	func lamp(p: Vector3, tall: bool = true) -> void:
		host.lamp(position + p, tall)

static func build(g: Node) -> void:
	var root = Node3D.new()
	root.name = "ContiguousTownPhaseTwo"
	g.add_child(root)
	var proxy = PlacementProxy.new(g)
	proxy.name = "LowerDistrictExterior"
	proxy.position = LOWER_ORIGIN
	root.add_child(proxy)
	LowerStreet.new().build(proxy)
	_build_pickman_descent(g, root)
	for id in ["route_lower", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func build_waterfront_approach(g: Node) -> void:
	var root = g.get_node("ContiguousTownPhaseTwo")
	var run = 14.0
	var drop = 2.7
	var length = sqrt(run * run + drop * drop)
	var center = Vector3(100, -3.85, -24)
	var ramp = DistrictSurfaces.apply(g.box(root, center, Vector3(5.5, 0.42, length), "59665f"), "patched_cobble", "59665f")
	ramp.name = "WaterfrontDescent"
	ramp.rotation.x = -atan2(drop, run)
	var body = StaticBody3D.new()
	body.name = "WaterfrontDescentCollision"
	body.position = center
	body.rotation = ramp.rotation
	root.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(5.5, 0.42, length)
	collision.shape = shape
	body.add_child(collision)
	_build_bridge_activator(g, root, "WaterfrontDescent", ramp.position, ramp.rotation, Vector3(5.5, 3.5, 3.0))
	for side in [-1.0, 1.0]:
		var rail_pos = Vector3(100 + side * 3.2, center.y + 0.6, center.z)
		var rail = DistrictSurfaces.apply(g.box(root, rail_pos, Vector3(0.5, 1.4, length), "46534c"), "algae_stone", "46534c")
		rail.rotation.x = ramp.rotation.x
		var rbody = StaticBody3D.new()
		rbody.position = rail_pos
		rbody.rotation = ramp.rotation
		root.add_child(rbody)
		var rcol = CollisionShape3D.new()
		var rshape = BoxShape3D.new()
		rshape.size = Vector3(0.5, 1.4, length)
		rcol.shape = rshape
		rbody.add_child(rcol)
	g.target("route_waterfront", "Continue downhill to the waterfront", Vector3(100, -5.0, -31))
	g.routes["route_waterfront"] = ["waterfront", Vector3(0, 0.1, 23), 0.0]
	# A low, unreachable preview of the buried-whole whaling station (Bible v18).
	var station = Node3D.new()
	station.name = "DistantWhalingStation"
	root.add_child(station)
	DistrictSurfaces.apply(g.cylinder(station, Vector3(108, -4.7, -132), 16.0, 3.6, "4b544b", 9.5), "algae_stone", "4b544b")
	DistrictSurfaces.apply(g.cylinder(station, Vector3(102, -4.1, -133), 10.5, 3.2, "444c44", 5.5), "algae_stone", "444c44")
	DistrictSurfaces.apply(g.cylinder(station, Vector3(116, -4.4, -131), 9.5, 3.0, "485048", 5.0), "algae_stone", "485048")
	DistrictSurfaces.apply(g.box(station, Vector3(101.5, -2.1, -133), Vector3(1.7, 2.4, 1.7), "384440"), "rust_metal", "384440")
	DistrictSurfaces.apply(g.box(station, Vector3(109.0, -2.4, -131.5), Vector3(11.0, 0.45, 1.7), "2c3933"), "slate", "2c3933")
	DistrictSurfaces.apply(g.box(station, Vector3(114.5, -2.7, -128.5), Vector3(5.2, 1.3, 0.45), "36423c"), "tar_wood", "36423c")

static func build_waterfront(g: Node) -> void:
	var root = g.get_node("ContiguousTownPhaseTwo")
	var preview = root.get_node_or_null("DistantWhalingStation")
	if preview != null: preview.free()
	var proxy = PlacementProxy.new(g)
	proxy.name = "WaterfrontExterior"
	proxy.position = WATERFRONT_ORIGIN
	root.add_child(proxy)
	Waterfront.new().build(proxy)
	for id in ["route_waterfront", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func _build_pickman_descent(g: Node, root: Node3D) -> void:
	var run = 8.0
	var drop = 2.3
	var length = sqrt(run * run + drop * drop)
	# Bury the Pickman edge below its pavement so the character controller meets
	# a descending floor rather than the slab's vertical face.
	var center = Vector3(54, -1.45, 8)
	var ramp = DistrictSurfaces.apply(g.box(root, center, Vector3(length, 0.42, 5.5), "687269"), "patched_cobble", "687269")
	ramp.name = "LowerDistrictDescent"
	ramp.rotation.z = -atan2(drop, run)
	var body = StaticBody3D.new()
	body.name = "LowerDistrictDescentCollision"
	body.position = center
	body.rotation = ramp.rotation
	root.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(length, 0.42, 5.5)
	collision.shape = shape
	body.add_child(collision)
	_build_bridge_activator(g, root, "LowerDistrictDescent", ramp.position, ramp.rotation, Vector3(3.0, 3.5, 5.5))
	for z in [4.7, 11.3]:
		var wall_pos = Vector3(center.x, center.y + 0.6, z)
		var wall = DistrictSurfaces.apply(g.box(root, wall_pos, Vector3(length, 1.4, 0.5), "4b574e"), "stone", "4b574e")
		wall.rotation.z = ramp.rotation.z
		var wbody = StaticBody3D.new()
		wbody.position = wall_pos
		wbody.rotation = ramp.rotation
		root.add_child(wbody)
		var wcol = CollisionShape3D.new()
		var wshape = BoxShape3D.new()
		wshape.size = Vector3(length, 1.4, 0.5)
		wcol.shape = wshape
		wbody.add_child(wcol)

static func _build_bridge_activator(g: Node, root: Node3D, bridge_id: String, center: Vector3, rot: Vector3, size: Vector3) -> void:
	var trigger = Area3D.new()
	trigger.name = bridge_id + "Activator"
	trigger.position = center
	trigger.rotation = rot
	trigger.collision_layer = 0
	trigger.collision_mask = 2
	trigger.monitorable = false
	root.add_child(trigger)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position.y = 1.5
	trigger.add_child(col)
	trigger.body_entered.connect(func(body: Node3D):
		var chapter = g if g.has_method("on_bridge_crossed") else g.get_parent()
		if chapter != null and chapter.has_method("on_bridge_crossed"):
			chapter.on_bridge_crossed(bridge_id)
	)

static func lower_return(interior_id: String) -> Variant:
	var specs: Array = Places.BUILDINGS.lower
	for index in specs.size():
		if String(specs[index][0]) != interior_id: continue
		var toward_street = Vector3(0, 0.1, 1.5 if index < 3 else -1.5)
		if interior_id == "speakeasy":
			toward_street = Vector3(7, 0.1, 6.0)
		return LOWER_ORIGIN + Places.front(index) + toward_street
	return null

static func shared_spot(spot: Array) -> Array:
	if spot.is_empty(): return spot
	var district = String(spot[0])
	var position: Vector3 = spot[1]
	if district == "lower": return ["town", LOWER_ORIGIN + position]
	if district == "waterfront": return ["town", WATERFRONT_ORIGIN + position]
	return spot
