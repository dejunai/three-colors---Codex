extends RefCounted

func run(g:Node) -> void:
	g.state.started=true
	g.player.position=Vector3(1,0.1,7.5)
	g.yaw=-0.12
	g.distance=8
	g.pitch=0.35
	g.aperture=1.2
	g.aperture_target=1.2
	g._update_camera(1)
	if g.capture_mode != "title":
		g.prologue.hide_all()
		g._close()
	if g.capture_mode == "observer":
		g.state.lounge_exited=true
		g.estate.sync_staging(g.state)
		g.page="capture"
		g.model.hide()
		g.player.position=Vector3(-14.6,0.1,-14.4)
		g.yaw=0.74
		g.distance=3.2
		g.pitch=0.24
		g.settings.grain=0
		g.settings.distortion=0
		g._apply_settings()
		g.camera.global_position=Vector3(-13.7,1.8,-15.4)
		g.camera.look_at(Vector3(-12.6,1.4,-16.6))
	if g.capture_mode == "case":
		for id in g.Story.FACTS: g.state.discover(id)
		g.state.visited.assign(["garden","odell"])
		g.state.complete_report("Full inquest requested")
		g._journal()
	if g.capture_mode == "dialogue": g._interact("odell")
	if g.capture_mode == "odell":
		g.page = "capture"
		g.model.hide()
		g.camera.global_position = Vector3(4,1.7,-7.4)
		g.camera.look_at(Vector3(4,1.15,-11.5))
	if g.capture_mode == "coroners_assistant":
		g.page = "capture"
		g.model.hide()
		# View her from Walter's garden approach rather than from behind the tables.
		g.camera.global_position = Vector3(7.0,1.75,3.0)
		g.camera.look_at(Vector3(12.5,1.1,-3.8))
	if g.capture_mode == "odell_precinct":
		g.state.day = 2
		g.state.clock_minutes = 540.0
		g.state.estate_complete = true
		g._travel("precinct",Vector3(0,0.1,6))
		g.page = "capture"
		g.model.hide()
		g.camera.global_position = Vector3(3.8,1.7,5.0)
		g.camera.look_at(Vector3(3.8,1.15,1.0))
	if g.capture_mode == "settings": g._settings()
	if g.capture_mode == "effects": g._case_file()
	if g.capture_mode == "watch":
		g.state.day = 2
		g.state.clock_minutes = 1110.0
		g._pocket_watch()
	if g.capture_mode in ["walter","walter_pickup"]:
		g.state.started = true
		g.player.position = Vector3(1,0.1,7.5)
		g.model.rotation.y = 0.0
		g.pitch = 0.16
		g.distance = 3.2
		g.yaw = 0.05
		g._update_camera(1.0)
		if g.capture_mode == "walter_pickup":
			g.rig._animation_lock = true
			g.rig._play_model_animation("Pickup_Ground",0.0)
			var pickup_name = g.rig._model_animations.get("Pickup_Ground","")
			var pickup_clip = g.rig._model_animation.get_animation(pickup_name)
			g.rig._model_animation.seek(pickup_clip.length*0.46,true)
			g.rig._model_animation.pause()
	if g.capture_mode == "large_text": g.settings.text_scale=1.3; g._settings()
	if g.capture_mode == "gate":
		g.player.position=Vector3(0,0.1,36)
		g.distance=6.3
		g.pitch=0.38
		g.yaw=0
		g.aperture=0.51
		g.aperture_target=0.51
		g._update_camera(1)
	if g.capture_mode == "estate_approach":
		g.page = "capture"
		g.model.hide()
		g.camera.global_position = Vector3(0, 8.0, 8.0)
		g.camera.look_at(Vector3(0, 2.0, 37.0))
		g.set_process(false)
	if g.capture_mode in ["town","town_pickman","town_business","town_schoolhouse","town_upper","town_upper_residence","town_lower","town_waterfront","town_waterfront_frontage","town_waterfront_seaward","town_waterfront_workyard","precinct","boardinghouse","room","board","witness"]:
		for id in ["eight","wounds","gas"]: g.state.discover(id)
		g.state.complete_report("Full inquest requested")
		g.state.receive_report()
		g.state.estate_complete=true
		for id in ["intake","naomi","lodging","lay_lead","service_work"]: g.state.discover(id)
		var scene="town" if g.capture_mode.begins_with("town_") else g.capture_mode
		if g.capture_mode=="board": scene="room"
		if g.capture_mode=="witness": scene="boardinghouse"
		g._travel(scene,Vector3(0,0.1,17) if scene=="town" else Vector3(0,0.1,4))
		if g.capture_mode == "town_pickman":
			g.page = "capture"
			g.player.hide()
			g.camera.global_position = Vector3(0,5.8,11)
			g.camera.look_at(Vector3(0,4.8,-10))
			g.set_process(false)
		elif g.capture_mode == "town_business":
			g.player.position = Vector3(0,5.6,75)
			g.yaw = 0.1
		elif g.capture_mode == "town_schoolhouse":
			g.player.position = Vector3(-19,5.6,70)
			g.yaw = 0.0
		elif g.capture_mode == "town_upper":
			g.player.position = Vector3(0,12.6,142)
			g.yaw = -0.15
		elif g.capture_mode == "town_upper_residence":
			g.player.position = Vector3(-19,12.6,148)
			g.yaw = PI
		elif g.capture_mode == "town_lower":
			g.player.position = Vector3(91,-2.2,8)
			g.yaw = 0.25
		elif g.capture_mode == "town_waterfront":
			g.player.position = Vector3(100,-4.9,-58)
			g.yaw = PI
		elif g.capture_mode == "town_waterfront_frontage":
			g.player.position = Vector3(100,-4.9,-64)
			g.yaw = PI
		elif g.capture_mode == "town_waterfront_seaward":
			g.player.position = Vector3(100,-4.9,-65)
			g.yaw = 0.0
		elif g.capture_mode == "town_waterfront_workyard":
			g.player.position = Vector3(88,-4.9,-64)
			g.yaw = -PI / 2.0
		if g.capture_mode.begins_with("town_"):
			g.pitch = 0.42
			g.distance = 7.2
			if g.capture_mode in ["town_waterfront","town_waterfront_frontage","town_waterfront_seaward","town_waterfront_workyard"]:
				g.pitch = 0.28
				g.distance = 15.0 if g.capture_mode == "town_waterfront_frontage" else 9.0
			g._update_camera(1.0)
		if g.capture_mode=="board": g._board()
		if g.capture_mode=="witness": g._witness_menu()
	if g.capture_mode.begins_with("tunnel"):
		for id in ["eight","naomi","wounds","gas"]: g.state.discover(id)
		g.state.finished=true
		g._travel("tunnel",Vector3(0,0.1,-7),0,false)
		g.tunnel_checkpoint=g._session_snapshot()
		if g.capture_mode=="tunnel_access": g.settings.distortion=0; g.settings.text_scale=1.3; g._apply_settings()
		if g.capture_mode=="tunnel_death": g._show_tunnel_death(false)
		if g.capture_mode=="tunnel_record": g._tunnel_interaction("tunnel_notes")
	if g.capture_mode == "return_gardener":
		g.state.estate_complete=true
		g.state.coat="Plain wool coat"
		g._travel("estate",Vector3(0,0.1,16))
		g.model.hide()
		g.page="capture"
		g.camera.global_position=Vector3(0,2.4,18)
		g.camera.look_at(Vector3(-4,1,12))
	if g.capture_mode in ["lounge","montage","notebook","cleared_estate"]:
		g.state.visited.append("almy")
		g.state.estate_complete=true
		g.state.day=3
		g.state.steward_visits=2
		g.state.coat="Plain wool coat"
		g.state.lounge_exited=true
		if g.capture_mode=="lounge": g._travel("lounge",Vector3(0,0.1,2))
		elif g.capture_mode=="montage":
			g._travel("room",Vector3(0,0.1,6))
			g.state.day=2
			g.state.montage_index=3
			g.staging.draw_montage(g)
		elif g.capture_mode=="notebook":
			for id in ["eight","naomi","lodging"]: g.state.discover(id)
			g.state.record_link("naomi_address")
			g._notebook()
		else: g._travel("estate",Vector3(1,0.1,7.5))
	if g.capture_mode in ["link_picker","link_positive","link_negative"]:
		g._travel("room",Vector3(0,0.1,4))
		for id in ["naomi","lodging","wounds"]: g.state.discover(id)
		if g.capture_mode=="link_picker": g.archive._link_picker(g,"naomi")
		else: g.archive._link_result(g,"naomi","lodging" if g.capture_mode=="link_positive" else "wounds")
	if g.capture_mode == "glass_break":
		g.state.started = true
		g.state.day = 3
		g.state.coat = "Plain wool coat"
		g.state.dialogue_state.set_flag("tunnel_retreated",true)
		g._travel("room",Vector3(0,0.1,4),0,false)
		g._refresh_outfit()
		g.page = "break"
		g.distance = 3.0
		g.pitch = 0.38
		g._update_camera(1.0)
		g.presentation.widen_frame(0.01)
		g.presentation.return_color(0.75,0.01)
		g.breaker._break_glass(g,g.estate)
	await g.get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var path=ProjectSettings.globalize_path("res://qa_"+g.capture_mode+".png")
	var result=g.get_viewport().get_texture().get_image().save_png(path)
	if result==OK: print("CAPTURE "+path)
	else: push_error("Capture failed: "+str(result))
	g.get_tree().quit()


