extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var view=load("res://scripts/shared/chapter_interface.gd").new()
	view.settings={"text_scale":1.0}
	root.add_child(view)
	view._panel("board","Scroll regression","CASE BOARD",true)
	var board=load("res://scripts/shared/case_board.gd").new()
	var facts={}
	var ids=[]
	for i in range(18):
		var id=str(i)
		ids.append(id)
		facts[id]=["Observation "+id,"Recorded testimony for scroll testing.","Test source"]
	board.configure(view,ids,facts,["test"],{"0|15":{"id":"test"}},{},func(_id): pass)
	view.content.add_child(board)
	await create_timer(0.3).timeout
	var scroll=view.content.get_parent()
	scroll.scroll_vertical=500
	await create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image=root.get_texture().get_image()
		# The first pin is offscreen, but its thread must still cross the visible
		# left gutter. Test rendered pixels, not just the overlay's properties.
		var red_pixels=0
		var left=int(board.global_position.x)
		for x in range(left,left+24):
			for y in range(200,500):
				var color=image.get_pixel(x,y)
				if color.r>color.g*1.7 and color.g>color.b*1.1: red_pixels+=1
		assert(red_pixels>100,"Twine disappeared with its offscreen first pin")
	print("TWINE SCROLL PASS")
	quit()
