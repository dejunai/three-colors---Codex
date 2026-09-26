extends SceneTree

const Town = preload("res://town.gd")
const TownExpansion = preload("res://town_expansion.gd")

const EXPECTED := {
	"room": ["CorwinBed", "CorwinRug", "CorwinDesk", "CorwinDresser", "CorwinRadiator", "CorwinWashstand", "CorwinWashBasin", "CorwinWashPitcher"],
	"precinct": ["PrecinctIntakeCounterLeft", "PrecinctIntakeCounterRight", "PrecinctFilesSingle", "PrecinctFilesWide", "PrecinctSideDesk", "PrecinctDeskLamp"],
	"lounge": ["LoungeBookshelf", "LoungeSideboard", "LoungeTableLamp", "LoungeDisplaySloped", "LoungeDisplayRectangular", "LoungeWallClock", "LoungeRug", "LoungeBarCounter", "LoungeFireplace", "LoungeClubSofa", "LoungePillowBurgundy", "LoungePillowGreen", "LoungeClubChairNorth", "LoungeClubChairSouth", "LoungeRoundTable", "LoungeAshtray", "PantryDoorStates"],
	"upper_house_1": ["ParlorRug", "ParlorFireplace", "ParlorTuftedSofa", "ParlorPillowBurgundy", "ParlorPillowGreen", "ParlorArmchairNorth", "ParlorArmchairSouth", "ParlorLowTable", "ParlorDecorativeBowl", "ParlorSideboard", "ParlorTableLamp", "ParlorRoundVase"],
	"post_office": ["PostOfficeCounterLeft", "PostOfficeCounterRight", "PostOfficePigeonholesLeft", "PostOfficePigeonholesRight", "PostOfficeBalanceScale", "PostOfficeEnvelopeStack", "PostOfficeParcelSquare", "PostOfficeParcelLarge", "PostOfficeParcelLong", "PostOfficePendantLeft", "PostOfficePendantRight", "PostOfficeCorkboard", "PostOfficeFrostedWindow", "PostOfficeHangingSign", "PostOfficeCrate", "PostOfficeOpenCrate", "PostOfficeBarrel"],
}

const TARGETS := {
	"room": ["board", "sleep", "day_close", "exemption", "interior_exit"],
	"precinct": ["intake_clerk", "intake", "supplement", "survey_drawer", "route_morgue", "interior_exit"],
	"lounge": ["barman", "pantry_door", "lounge_exit"],
	"post_office": ["route_return"],
	"upper_house_1": ["local_resident", "route_return"],
}

func _initialize() -> void:
	for location in EXPECTED:
		var world = TownExpansion.new() if location in ["post_office", "upper_house_1"] else Town.new()
		world.location = location
		root.add_child(world)
		await process_frame
		for prop_name in EXPECTED[location]:
			var prop := world.get_node_or_null(prop_name) as Node3D
			assert(prop != null, location + " missing rendered prop " + prop_name)
			assert(prop.find_children("*", "MeshInstance3D", true, false).size() > 0, prop_name + " has no rendered mesh")
			assert(is_equal_approx(prop.scale.x, prop.scale.y) and is_equal_approx(prop.scale.y, prop.scale.z), prop_name + " must use uniform scale")
			assert(prop.find_children("*", "StaticBody3D", true, false).is_empty(), prop_name + " must remain presentation-only")
		for target_id in TARGETS[location]:
			assert(world.points.has(target_id), location + " lost interaction target " + target_id)
		if location == "precinct": assert(world.has_node("PrecinctBookStack"), "Precinct must use period book clutter instead of lever-arch binders")
		if location == "post_office":
			assert(world.find_children("PostOfficeLetterBundle*", "MeshInstance3D", true, false).size() >= 5, "Post-office sorting wall needs visible mail bundles")
			# Counter desk props sit on the open writing surface, clear of each module's wicket.
			var counter_top_y := 1.0
			for prop_name in ["PostOfficeBalanceScale", "PostOfficeEnvelopeStack", "PostOfficeParcelSquare", "PostOfficeParcelLarge", "PostOfficeParcelLong"]:
				var desk_prop := world.get_node(prop_name) as Node3D
				assert(is_equal_approx(desk_prop.position.y, counter_top_y), prop_name + " must sit on the counter writing surface")
			assert(world.get_node("PostOfficeParcelSquare").position.x > -2.9, "Square parcel must clear the left wicket bars")
			assert(world.get_node("PostOfficeParcelLarge").position.x > 1.5, "Large parcel must clear the right wicket bars")
			# Side-wall props are thin on local X; keep them flush facing into the room.
			var cork := world.get_node("PostOfficeCorkboard") as Node3D
			assert(is_equal_approx(cork.rotation.y, PI), "Corkboard faces into the room from the left wall")
			assert(cork.position.x < -8.7, "Corkboard sits flush to the left wall")
			var window := world.get_node("PostOfficeFrostedWindow") as Node3D
			assert(is_equal_approx(window.rotation.y, PI), "Frosted window faces into the room from the right wall")
			assert(window.position.x > 8.6, "Frosted window sits flush to the right wall")
			var sign := world.get_node("PostOfficeHangingSign") as Node3D
			assert(is_equal_approx(sign.rotation.y, 0.0), "Hanging sign faces into the room from the right wall")
			assert(sign.position.x > 8.6, "Hanging sign sits flush to the right wall")
			for seat_name in ["PostOfficeChairLeft", "PostOfficeChairRight", "PostOfficeBarrel"]:
				assert(is_equal_approx(world.get_node(seat_name).position.y, 0.0), seat_name + " must remain on the floor")
		if location == "lounge":
			assert(world.has_node("LoungeBarCounter") and world.has_node("LoungeClubSofa"), "Purpose-built club furniture must replace the provisional lounge primitives")
			assert(world.steward_actor.position.is_equal_approx(Vector3(0,0,-7.0)), "Steward must remain behind the rendered bar")
			assert(world.points.barman.pos.is_equal_approx(Vector3(0,0,-4.45)), "Steward talk point must remain on the public side of the bar")
			var states := world.get_node("PantryDoorStates")
			assert(states.get_node("Boarded").visible and not states.get_node("Cleared").visible, "Pantry begins visibly boarded")
			world.sync_pantry(true, true)
			assert(not states.get_node("Boarded").visible and states.get_node("Cleared").visible, "Completed pantry portal shows removed boards")
		# Tripo seat/front faces local +X (backrest/drawers opposite). Assert key room-facing yaws and Walter-relative bed scale.
		if location == "precinct":
			assert(is_equal_approx(world.get_node("PrecinctWaitingChair0").rotation.y, PI), "Waiting chairs face into the room toward intake")
			assert(is_equal_approx(world.get_node("PrecinctSideChair").rotation.y, PI / 2), "Side chair faces the precinct desk")
			assert(is_equal_approx(world.get_node("PrecinctClerkChair").rotation.y, -PI / 2), "Clerk chair faces the intake counter")
		if location == "room":
			assert(is_equal_approx(world.get_node("CorwinDeskChair").rotation.y, PI / 2), "Corwin desk chair faces the desk")
			assert(is_equal_approx(world.get_node("CorwinBed").scale.x, 3.2), "Corwin bed scaled to Walter-relative single-bed size")
			assert(is_equal_approx(world.get_node("CorwinDresser").rotation.y, PI), "Corwin dresser drawers face into the room")
		if location == "lounge":
			assert(is_equal_approx(world.get_node("LoungeFireplace").rotation.y, PI), "Lounge fireplace opens into the room")
			assert(is_equal_approx(world.get_node("LoungeSideboard").rotation.y, PI), "Lounge sideboard drawers face into the room")
			assert(is_equal_approx(world.get_node("LoungeClubChairNorth").rotation.y, 0.0), "Lounge club chairs face the round table")
			assert(is_equal_approx(world.get_node("LoungeClubSofa").rotation.y, PI), "Lounge club sofa faces the rug")
		if location == "upper_house_1":
			assert(is_equal_approx(world.get_node("ParlorFireplace").rotation.y, -PI / 2), "Parlor fireplace opens into the room")
			assert(is_equal_approx(world.get_node("ParlorSideboard").rotation.y, -PI / 2), "Parlor sideboard drawers face into the room")
			assert(is_equal_approx(world.get_node("ParlorArmchairNorth").rotation.y, PI), "Parlor armchairs face into the room")
			assert(is_equal_approx(world.get_node("ParlorArmchairSouth").rotation.y, PI), "Parlor armchairs face into the room")
		if location == "post_office":
			assert(is_equal_approx(world.get_node("PostOfficeChairLeft").rotation.y, 0.0), "Post-office left chair faces into the room")
			assert(is_equal_approx(world.get_node("PostOfficeChairRight").rotation.y, PI), "Post-office right chair faces into the room")
		for shade in world.find_children("InteriorLampShade", "MeshInstance3D", true, false): assert(shade.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Interior shades must not cast floor blobs")
		world.free()
	print("INTERIOR PROP DRESSING PASS: domestic, precinct, parlor, post office, and lounge props render with correct facing/scale and gameplay targets intact")
	quit(0)
