extends RefCounted

func walk_to(g:Node,destination:Vector3) -> void:
	for i in 1500:
		var offset=Vector2(destination.x-g.player.position.x,destination.z-g.player.position.z)
		if offset.length()<0.25: break
		var dir=offset.normalized()
		for action in ["walk_left","walk_right","walk_forward","walk_back"]: Input.action_release(action)
		if dir.x>0: Input.action_press("walk_right",dir.x)
		else: Input.action_press("walk_left",-dir.x)
		if dir.y>0: Input.action_press("walk_back",dir.y)
		else: Input.action_press("walk_forward",-dir.y)
		await g.get_tree().physics_frame
	for action in ["walk_left","walk_right","walk_forward","walk_back"]: Input.action_release(action)
	assert(Vector2(destination.x-g.player.position.x,destination.z-g.player.position.z).length()<0.6,"Unreachable walking destination: "+str(destination)+" from "+str(g.player.position))

