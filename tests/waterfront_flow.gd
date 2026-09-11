extends SceneTree

func _initialize() -> void: call_deferred("run")
func cards(g:Node) -> void:
	while g.page=="dialogue": g._next_card()

func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	g.state=g.CaseState.new()
	g.state.started=true
	g._travel("town",Vector3(-26,0.1,7),0,false)
	g._close()
	await physics_frame
	assert(g.estate.routes.has("route_waterfront"))
	g._interact("route_waterfront")
	await physics_frame
	assert(g.state.world=="waterfront")
	assert(g.state.clock_minutes>=390)
	assert(g.daylight!=null)
	assert(g.estate.has_node("OffshoreWhalingStation"))
	assert(g.estate.routes.size()==1, "No island travel or unbuilt interiors")
	for id in ["harbor_observer","quay_bookkeeper","chandlers_boy","net_seller","quay_docker","ropewalk_foreman"]:
		assert(g.estate.points.has(id), "Missing morning resident: "+id)
	assert(not g.estate.points.has("salt_mender"))
	var catalog=g.scripted_dialogue.catalog
	assert(catalog.slot("chandlers_boy",g.state)[0]=="waterfront")
	assert(catalog.slot("net_seller",g.state)[0]=="waterfront")
	assert(catalog.slot("quay_docker",g.state)[0]=="waterfront")
	assert(catalog.slot("ropewalk_foreman",g.state)[0]=="waterfront")
	for id in ["harbor_observer","quay_bookkeeper","chandlers_boy","net_seller","quay_docker","ropewalk_foreman"]:
		var point=g.estate.points[id].pos
		g.player.position=point+Vector3(0,0.1,-1.4)
		await physics_frame
		g._find_focus()
		assert(g.focused==id,"Unreachable morning resident: "+id)
		g._interact(id)
		assert(g.page=="dialogue" or g.page=="witness")
		cards(g)
		g._close()
	g.state.clock_minutes=720
	g.scripted_dialogue.populate(g)
	for id in ["harbor_observer","quay_bookkeeper","salt_mender","chandlers_boy","net_seller","quay_docker","ropewalk_foreman"]:
		assert(g.estate.points.has(id), "Missing midday resident: "+id)
	assert(catalog.slot("salt_mender",g.state)[0]=="waterfront")
	# Resident locations are reachable from the open quay; no desks/walls hide focus.
	for id in ["harbor_observer","quay_bookkeeper","salt_mender","chandlers_boy","net_seller","quay_docker","ropewalk_foreman"]:
		var point=g.estate.points[id].pos
		g.player.position=point+Vector3(0,0.1,-1.4)
		await physics_frame
		g._find_focus()
		assert(g.focused==id,"Unreachable resident: "+id)
		g._interact(id)
		assert(g.page=="dialogue" or g.page=="witness")
		cards(g)
		g._close()
	g.state.clock_minutes=1020
	assert(catalog.slot("harbor_observer",g.state)[0]=="lower_house_3")
	assert(catalog.slot("salt_mender",g.state)[0]=="lower_house_2")
	assert(catalog.slot("quay_bookkeeper",g.state).is_empty())
	for id in ["chandlers_boy","net_seller","quay_docker","ropewalk_foreman"]:
		assert(catalog.slot(id,g.state).is_empty())
	g.state.clock_minutes=1200
	g.scripted_dialogue.populate(g)
	assert(not g.estate.points.has("harbor_observer"))
	g.daylight.update_clock(g.state.clock_minutes,g.player.position)
	assert(not g.daylight.sun_disk.visible)
	var restored=g.CaseState.new()
	assert(restored.restore(g.state.pack()))
	assert(restored.world=="waterfront")
	g._interact("route_pickman")
	g = scene.chapter
	assert(g.state.world=="town")
	if OS.get_cmdline_user_args().has("--view"):
		g.state.clock_minutes=720
		g._travel("waterfront",Vector3(0,0.1,5),0,false)
		g._close()
		g.pitch=0.18
		g.distance=9
		g.rig._update_camera(1)
		await create_timer(1).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://waterfront.png")
	print("WATERFRONT PASS: travel, clock, seven residents, live focus/interactions, evening/night schedules, save and return")
	quit()
