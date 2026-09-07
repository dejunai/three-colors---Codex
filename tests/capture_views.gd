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
	if g.capture_mode != "title": g._close()
	if g.capture_mode == "case":
		for id in g.Story.FACTS: g.state.discover(id)
		g.state.visited.assign(["garden","odell"])
		g.state.complete_report("Full inquest requested")
		g._journal()
	if g.capture_mode == "dialogue": g._interact("odell")
	if g.capture_mode == "settings": g._settings()
	if g.capture_mode == "effects": g._case_file()
	if g.capture_mode == "large_text": g.settings.text_scale=1.3; g._settings()
	if g.capture_mode == "gate":
		g.player.position=Vector3(0,0.1,36)
		g.distance=6.3
		g.pitch=0.38
		g.yaw=0
		g.aperture=0.51
		g.aperture_target=0.51
		g._update_camera(1)
	if g.capture_mode in ["town","precinct","boardinghouse","room","board","witness"]:
		for id in ["eight","wounds","gas"]: g.state.discover(id)
		g.state.complete_report("Full inquest requested")
		g.state.receive_report()
		g.state.estate_complete=true
		for id in ["intake","naomi","lodging","lay_lead","service_work"]: g.state.discover(id)
		var scene=g.capture_mode
		if g.capture_mode=="board": scene="room"
		if g.capture_mode=="witness": scene="boardinghouse"
		g._travel(scene,Vector3(0,0.1,17) if scene=="town" else Vector3(0,0.1,4))
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
	await g.get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var path=ProjectSettings.globalize_path("res://qa_"+g.capture_mode+".png")
	var result=g.get_viewport().get_texture().get_image().save_png(path)
	if result==OK: print("CAPTURE "+path)
	else: push_error("Capture failed: "+str(result))
	g.get_tree().quit()


