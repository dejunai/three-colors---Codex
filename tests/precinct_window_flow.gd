extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var Town = load("res://town.gd")
	var precinct = Town.new()
	precinct.location = "precinct"
	root.add_child(precinct)
	await process_frame

	var found_left_window = false
	var found_right_window = false
	var found_morgue_door = false

	for child in precinct.get_children():
		if child is MeshInstance3D:
			var pos = child.position
			var z_match = abs(pos.z - -7.78) < 0.05 or abs(pos.z - -7.61) < 0.05
			if z_match:
				if pos.x < -2.0:
					found_left_window = true
				if pos.x > 2.0:
					found_right_window = true
			if abs(pos.x - -4.0) < 0.1 and abs(pos.z - -7.7) < 0.1 and abs(pos.y - 1.5) < 0.1:
				found_morgue_door = true

	assert(not found_left_window, "Left window at x = -5 must be removed from precinct")
	assert(found_right_window, "Right window at x = 5 must remain in precinct")
	assert(found_morgue_door, "Morgue door at x = -4 must remain intact")
	assert(precinct.routes.has("route_morgue"), "Morgue route must exist")
	precinct.queue_free()

	# Verify shop interiors (stationer, haberdasher) have the right window removed
	var TownExpansion = load("res://town_expansion.gd")
	for shop_id in ["stationer", "haberdasher"]:
		var shop = TownExpansion.new()
		shop.location = shop_id
		root.add_child(shop)
		await process_frame

		var shop_left_window = false
		var shop_right_window = false
		var shop_rooms_door = false

		for child in shop.get_children():
			if child is MeshInstance3D:
				var pos = child.position
				# Window glass is positioned at z = -7.78
				if abs(pos.z - -7.78) < 0.05:
					if abs(pos.x - -5.0) < 0.5:
						shop_left_window = true
					if abs(pos.x - 5.0) < 0.5:
						shop_right_window = true
				if abs(pos.x - 6.0) < 0.1 and abs(pos.z - -7.6) < 0.1 and abs(pos.y - 1.5) < 0.1:
					shop_rooms_door = true

		assert(shop_left_window, "Shop left window at x = -5 must remain in " + shop_id)
		assert(not shop_right_window, "Shop right window at x = 5 must be removed to avoid door clipping in " + shop_id)
		assert(shop_rooms_door, "Rooms above door at x = 6 must remain intact in " + shop_id)
		shop.queue_free()

	print("PRECINCT & SHOP WINDOW FIX PASS: window-door collisions resolved cleanly across all interiors")
	quit(0)
