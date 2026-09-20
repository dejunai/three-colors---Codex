extends RefCounted

const Places = preload("res://scripts/chapters/town_places.gd")
const DistrictSurfaces = preload("res://scripts/shared/district_surfaces.gd")

func block(g: Node, p: Vector3, size: Vector3, tint: String, solid: bool = false, kind: String = "cracked_plaster") -> MeshInstance3D:
	return DistrictSurfaces.apply(g.box(g, p, size, tint, solid), kind, tint)

func build(g: Node) -> void:
	block(g, Vector3(0, -0.3, 10), Vector3(66, 0.5, 54), "4c554c", true, "soot_brick")
	block(g, Vector3(0, 0, 8), Vector3(60, 0.07, 15), "505c52", false, "patched_cobble")
	for z in [-2, 18]:
		block(g, Vector3(0, 0.05, z), Vector3(60, 0.16, 5), "68705f", false, "stone")
	for z in [0.6, 15.4]:
		block(g, Vector3(0, 0.12, z), Vector3(60, 0.2, 0.18), "8d927e", false, "stone")
	for i in 6:
		var spec: Array = Places.BUILDINGS.lower[i]
		var p: Vector3 = Places.front(i)
		var back = -1.0 if i < 3 else 1.0
		var width = 12.0
		var height = 5.2
		var wall_tint: String = ["665d50", "6f6758", "5d6658", "746b59", "626a5b", "6b5f51"][i]
		var wall_kind: String = "soot_brick" if i in [0, 3, 5] else "cracked_plaster"
		block(g, p + Vector3(0, height / 2, back * 4), Vector3(width, height, 7), wall_tint, true, wall_kind)
		block(g, p + Vector3(0, height + 0.2, back * 4), Vector3(width + 0.6, 0.4, 7.5), "303a34", false, "slate")
		for x in [-width * 0.32, width * 0.32]:
			block(g, p + Vector3(x, 2.1, back * 0.4), Vector3(2, 1.8, 0.14), "27372f", false, "wood")
			for dx in [-1.08, 0, 1.08]:
				block(g, p + Vector3(x + dx, 2.1, back * 0.25), Vector3(0.09, 2, 0.12), "8c907b", false, "wood")
		var door_color = "253b30" if spec[3] != "exterior" else "525d4e"
		block(g, p + Vector3(0, 1.5, back * 0.3), Vector3(1.8, 3, 0.18), door_color, false, "wood")
		g.lettering(spec[1], p + Vector3(0, 4.3, -back * 0.05), 36).rotation.y = 0.0 if i < 3 else PI
		block(g, p + Vector3(-3, 0.45, -back * 0.7), Vector3(2.4, 0.18, 0.65), "5d654f", true, "wood")
		for y in [0.6, 1.2, 1.8, 2.4, 3.0, 4.1]:
			block(g, p + Vector3(0, y, back * 0.3), Vector3(width, 0.035, 0.07), "493f35", false, "wood")
		if spec[3] == "exterior":
			for y in [0.7, 1.5, 2.3]:
				block(g, p + Vector3(0, y, 0), Vector3(1.8, 0.2, 0.1), "625d4c", false, "wood")
		else:
			var id = "route_" + String(spec[0])
			if id == "route_speakeasy":
				var hatch = p + Vector3(7, 0, 8)
				block(g, hatch + Vector3(0, 0.06, 0), Vector3(2.3, 0.12, 1.9), "3c2f20", true, "rust_metal")
				block(g, hatch + Vector3(-0.62, 0.32, 0), Vector3(1.05, 0.1, 1.8), "55432c", false, "wood").rotation.x = -0.5
				block(g, hatch + Vector3(0.62, 0.32, 0), Vector3(1.05, 0.1, 1.8), "55432c", false, "wood").rotation.x = 0.5
				g.target(id, "Try the cellar door", hatch)
			else:
				g.target(id, "Enter " + String(spec[1]).to_lower(), p)
			g.routes[id] = [spec[0], Vector3(0, 0.1, 6), 0.0]
	for x in [-28, -9, 9, 28]: g.lamp(Vector3(x, 0, 1))
	for x in [-10, 10]:
		var pole = g.cylinder(g, Vector3(x, 1.7, 19), 0.045, 3.4, "4c6248")
		DistrictSurfaces.apply(pole, "rust_metal", "4c6248")
	block(g, Vector3(0, 3.2, 19), Vector3(20, 0.025, 0.025), "8d927e", false, "wood")
	for x in [-7, -3, 2, 6]: block(g, Vector3(x, 2.65, 19), Vector3(1.3, 1.1, 0.025), "8b8f7a", false, "plaster")
	g.target("route_pickman", "Return to Pickman Street", Vector3(-30, 0, 8))
	g.routes["route_pickman"] = ["town", Vector3(25, 0.1, 8), PI / 2]
