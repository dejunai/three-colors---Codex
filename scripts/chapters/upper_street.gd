extends RefCounted

# Upper-quarter exterior geometry. Stable building IDs remain in TownPlaces so
# this builder can serve both the legacy hub and the contiguous town.
const Places = preload("res://scripts/chapters/town_places.gd")
const DistrictSurfaces = preload("res://scripts/shared/district_surfaces.gd")

func block(g: Node, p: Vector3, size: Vector3, tint: String, solid: bool = false, kind: String = "plaster") -> MeshInstance3D:
	return DistrictSurfaces.apply(g.box(g, p, size, tint, solid), kind, tint)

func build(g: Node) -> void:
	block(g, Vector3(0, -0.3, 10), Vector3(66, 0.5, 54), "586052", true, "cut_stone")
	block(g, Vector3(0, 0, 8), Vector3(60, 0.07, 15), "787e70", false, "cobble")
	for z in [-2, 18]:
		block(g, Vector3(0, 0.05, z), Vector3(60, 0.16, 5), "929887", false, "cut_stone")
	for z in [0.6, 15.4]:
		block(g, Vector3(0, 0.12, z), Vector3(60, 0.2, 0.18), "adb19c", false, "cut_stone")
	for i in 6:
		var spec: Array = Places.BUILDINGS.upper[i]
		var p: Vector3 = Places.front(i)
		var back = -1.0 if i < 3 else 1.0
		var width = 14.0
		var height = 8.5
		var wall_tint: String = ["a6a68f", "989d8c", "b0aa91", "909888", "aaa48f", "969b87"][i]
		block(g, p + Vector3(0, height / 2, back * 4), Vector3(width, height, 7), wall_tint, true, "plaster")
		block(g, p + Vector3(0, height + 0.2, back * 4), Vector3(width + 0.6, 0.4, 7.5), "34483b", false, "slate")
		for x in [-width * 0.32, width * 0.32]:
			for y in [2.1, 5.4]:
				block(g, p + Vector3(x, y, back * 0.4), Vector3(2, 1.8, 0.14), "2e4439", false, "wood")
				for dx in [-1.08, 0, 1.08]:
					block(g, p + Vector3(x + dx, y, back * 0.25), Vector3(0.09, 2, 0.12), "b0b59e", false, "cut_stone")
		var door_color = "253b30" if spec[3] != "exterior" else "525d4e"
		block(g, p + Vector3(0, 1.5, back * 0.3), Vector3(1.8, 3, 0.18), door_color, false, "wood")
		g.lettering(spec[1], p + Vector3(0, 4.3, -back * 0.05), 36).rotation.y = 0.0 if i < 3 else PI
		for x in [-2, 2]:
			var column = g.cylinder(g, p + Vector3(x, 1.7, -back * 0.2), 0.18, 3.4, "a9ae97")
			DistrictSurfaces.apply(column, "cut_stone", "a9ae97")
		block(g, p + Vector3(0, 3.5, -back * 0.2), Vector3(5, 0.3, 1.5), "a0aa91", false, "cut_stone")
		for x in [-5, 5]:
			block(g, p + Vector3(x, 0.35, -back), Vector3(3, 0.7, 1.1), "43593e", true, "cut_stone")
		if spec[3] == "exterior":
			for y in [0.7, 1.5, 2.3]:
				block(g, p + Vector3(0, y, 0), Vector3(1.8, 0.2, 0.1), "718367", false, "wood")
		else:
			var id = "route_" + spec[0]
			g.target(id, "Enter " + String(spec[1]).to_lower(), p)
			g.routes[id] = [spec[0], Vector3(0, 0.1, 6), 0.0]
	for x in [-28, -9, 9, 28]:
		g.lamp(Vector3(x, 0, 1))
		g.tree(Vector3(x, 0, 18))
	for x in [8, 12]:
		block(g, Vector3(x, 1.8, 27), Vector3(0.3, 3.6, 0.4), "8e9b81", false, "cut_stone")
	g.target("route_pickman", "Return to Pickman Street", Vector3(10, 0, 26))
	g.routes["route_pickman"] = ["town", Vector3(-10, 0.1, 20), PI]
