extends "res://town.gd"

const Places = preload("res://scripts/chapters/town_places.gd")

func _ready() -> void:
	rng.seed=1925
	_lighting(not Places.BUILDINGS.has(location) and location != "waterfront")
	if location == "waterfront":
		preload("res://scripts/chapters/waterfront_district.gd").new().build(self)
		return
	if Places.BUILDINGS.has(location):
		_neighborhood()
		return
	_room_shell()
	points.erase("interior_exit")
	if location=="morgue":
		_morgue()
		_exit_to("precinct",Vector3(-4,0.1,-5.5),"Return to precinct intake")
	elif location=="post_office":
		_post_office()
		_exit_to("town",Vector3(-24,0.1,20),"Return to Pickman Street",PI)
	else:
		var spec=Places.entry(location)
		_dress(spec[2])
		lettering(Places.title(location) if location=="speakeasy" else spec[1],Vector3(0,3.4,-7.5),32)
		var hub=Places.parent_hub(location)
		var index=Places.BUILDINGS[hub].find(spec)
		var pos=Places.front(index)+Vector3(0,0.1,1.4 if index<3 else -1.4)
		_exit_to(hub,pos,"Return to the neighborhood",PI if index<3 else 0.0)
		if spec[3]=="occupied" and location!="speakeasy":
			person(Vector3(3,0,-3),"55624f",false)
			target("local_resident","Speak with the resident",Vector3(3,0,-2))

func _exit_to(destination:String,spawn:Vector3,label:String,angle:float=0.0) -> void:
	target("route_return",label,Vector3(0,0,7.2))
	routes["route_return"]=[destination,spawn,angle]

func _neighborhood() -> void:
	if location == "business":
		preload("res://scripts/chapters/business_street.gd").new().build(self)
		return
	var upper=location=="upper"
	var lower=location=="lower"
	box(self,Vector3(0,-0.3,10),Vector3(66,0.5,54),"586052",true)
	box(self,Vector3(0,0,8),Vector3(60,0.07,15),"787e70" if not lower else "586355")
	for z in [-2,18]:
		box(self,Vector3(0,0.05,z),Vector3(60,0.16,5),"929887" if not lower else "727c69")
	for z in [0.6,15.4]: box(self,Vector3(0,0.12,z),Vector3(60,0.2,0.18),"adb19c")
	for i in 150:
		box(self,Vector3(rng.randf_range(-29,29),0.07,rng.randf_range(1,15)),Vector3(0.08,0.02,0.22),"969d87")
	# Continuous street center, six fronts; pocket worlds are separately instantiated.
	for i in 6:
		var spec=Places.BUILDINGS[location][i]
		var p=Places.front(i)
		var back=-1.0 if i<3 else 1.0
		var width=14.0 if upper else (12.0 if lower else 16.0)
		var height=8.5 if upper else (5.2 if lower else 7.1)
		var color="86907b" if upper else ("62715d" if lower else "74846d")
		box(self,p+Vector3(0,height/2,back*4),Vector3(width,height,7),color,true)
		box(self,p+Vector3(0,height+0.2,back*4),Vector3(width+0.6,0.4,7.5),"34483b")
		for x in [-width*0.32,width*0.32]:
			for y in [2.1,5.4]:
				if y>height-0.5: continue
				box(self,p+Vector3(x,y,back*0.4),Vector3(2,1.8,0.14),"2e4439")
				for dx in [-1.08,0,1.08]: box(self,p+Vector3(x+dx,y,back*0.25),Vector3(0.09,2,0.12),"b0b59e")
		var door_color="253b30" if spec[3]!="exterior" else "525d4e"
		box(self,p+Vector3(0,1.5,back*0.3),Vector3(1.8,3,0.18),door_color)
		lettering(spec[1],p+Vector3(0,4.3,-back*0.05),36).rotation.y=0.0 if i<3 else PI
		if upper:
			for x in [-2,2]: cylinder(self,p+Vector3(x,1.7,-back*0.2),0.18,3.4,"a9ae97")
			box(self,p+Vector3(0,3.5,-back*0.2),Vector3(5,0.3,1.5),"a0aa91")
			for x in [-5,5]:
				box(self,p+Vector3(x,0.35,-back*1.0),Vector3(3,0.7,1.1),"43593e",true)
		elif lower:
			box(self,p+Vector3(-3,0.45,-back*0.7),Vector3(2.4,0.18,0.65),"687659",true)
			for y in [0.6,1.2,1.8,2.4,3.0,4.1]:
				box(self,p+Vector3(0,y,back*0.3),Vector3(width,0.035,0.07),"4f614b")
		else:
			for x in [-4,4]:
				box(self,p+Vector3(x,1.8,back*0.25),Vector3(4,2.2,0.12),"3c5648")
			box(self,p+Vector3(0,3.1,-back*0.2),Vector3(width-0.5,0.2,1.3),"566950")
		if spec[3]=="exterior":
			for y in [0.7,1.5,2.3]: box(self,p+Vector3(0,y,0),Vector3(1.8,0.2,0.1),"718367")
		if spec[3]!="exterior":
			var id="route_"+spec[0]
			if id == "route_speakeasy":
				# The house keeps its ordinary street face. The cellar door is
				# reached around the rear, beyond the southeast corner.
				target(id,"Try the cellar door",p+Vector3(7,0,8))
			else:
				target(id,"Enter "+spec[1].to_lower(),p)
			routes[id]=[spec[0],Vector3(0,0.1,6),0.0]
	for x in [-28,-9,9,28]: lamp(Vector3(x,0,1))
	if upper:
		for x in [-28,-9,9,28]: tree(Vector3(x,0,18))
	elif lower:
		for x in [-10,10]:
			cylinder(self,Vector3(x,1.7,19),0.045,3.4,"4c6248")
		box(self,Vector3(0,3.2,19),Vector3(20,0.025,0.025),"adb299")
		for x in [-7,-3,2,6]: box(self,Vector3(x,2.65,19),Vector3(1.3,1.1,0.025),"a6b29a")
	else:
		# Space at the school frontage for a later pickup gathering.
		box(self,Vector3(-25,0.55,-2),Vector3(3,0.16,0.7),"667e59",true)
		lettering("SCHOOL YARD",Vector3(-25,2.2,-4.8),24)
	# Return passage sits between the south row, not behind a building.
	for x in [8,12]: box(self,Vector3(x,1.8,27),Vector3(0.3,3.6,0.4),"8e9b81")
	lettering("PICKMAN STREET",Vector3(10,3.7,27),27).rotation.y=PI
	target("route_pickman","Return to Pickman Street",Vector3(10,0,26))
	var street_x={"upper":-10,"business":8,"lower":25}[location]
	routes["route_pickman"]=["town",Vector3(street_x,0.1,20),PI]

func _dress(kind:String) -> void:
	match kind:
		"school":
			box(self,Vector3(0,2.1,-7.5),Vector3(6,2.2,0.1),"2c4335")
			for x in [-4,4]:
				for z in [-2,1,4]:
					_desk(Vector3(x,0,z),Vector3(1.7,0.16,0.9))
					_chair(Vector3(x,0,z+0.85))
			_desk(Vector3(-4,0,-5.5))
		"museum":
			for x in [-5,5]:
				for z in [-4,0,3]:
					box(self,Vector3(x,0.55,z),Vector3(2.1,1.1,1.1),"52694d",true)
					cylinder(self,Vector3(x,1.25,z),0.22,0.35,"a8b098")
					box(self,Vector3(x,1.13,z+0.4),Vector3(0.6,0.025,0.2),"c3c7ad")
			_desk(Vector3(0,0,-5.5))
			for x in [-5,5]: box(self,Vector3(x,2.4,-7.5),Vector3(2.3,1.5,0.08),"879980")
		"shop":
			_desk(Vector3(-3,0,-2),Vector3(5,0.16,1.5))
			for y in [0.6,1.4,2.2]:
				box(self,Vector3(-6,y,-6),Vector3(3,0.15,1),"58734f",true)
				for x in [-7,-6,-5]: box(self,Vector3(x,y+0.25,-6),Vector3(0.6,0.4,0.6),"a0ad8d")
			box(self,Vector3(6,1.5,-7.6),Vector3(1.7,3,0.1),"425b3f")
			lettering("PRIVATE · ROOMS ABOVE",Vector3(5.2,3.3,-7.4),22)
		"parlor":
			box(self,Vector3(0,0.03,0),Vector3(7,0.04,6),"64775b")
			for x in [-5,5]:
				box(self,Vector3(x,0.55,-2),Vector3(1.8,0.8,1.8),"576f4e",true)
				box(self,Vector3(x,1.2,-2.7),Vector3(1.8,1.3,0.25),"4b6646")
			_desk(Vector3(0,0,-5))
			box(self,Vector3(0,2.4,-7.5),Vector3(2.8,1.4,0.1),"8e9c80")
		"home":
			box(self,Vector3(-5,0.45,-3),Vector3(2.3,0.8,4),"657953",true)
			box(self,Vector3(-5,0.9,-3),Vector3(2.2,0.12,3.9),"a4b193")
			_desk(Vector3(3,0,0),Vector3(2,0.16,1.2))
			_chair(Vector3(3,0,1.1))
			cylinder(self,Vector3(6,0.6,-5),0.5,1.2,"384f38")
			cylinder(self,Vector3(6,2.2,-5),0.12,2.2,"344632")
		"speakeasy":
			# Bar counter along back wall
			_desk(Vector3(-2,0,-3),Vector3(6,0.16,1.4))
			# Bar stools along counter
			for x in [-4,-2,0]: _chair(Vector3(x,0,-1.4))
			# Liquor barrels and bottles behind the bar counter
			for x in [-5,-3,-1]:
				cylinder(self,Vector3(x,0.7,-6.8),0.4,1.4,"3f3123")
				cylinder(self,Vector3(x,1.5,-6.8),0.08,0.3,"7d8c72")
			# Low corner table with two chairs for night owls
			_desk(Vector3(4,0,1),Vector3(2.2,0.14,1.8))
			_chair(Vector3(4,0,2.4),0.0)
			_chair(Vector3(4,0,-0.4),PI)
			# Low ceiling beam & hanging lantern
			box(self,Vector3(0,3.6,0),Vector3(18,0.4,0.4),"282019")
			box(self,Vector3(0,2.8,0),Vector3(0.3,0.5,0.3),"c29f4a")
			# Bar stool interaction for eavesdropping
			target("speakeasy_bar","Sit quietly at the bar",Vector3(-5,0,-1.4))

func _post_office() -> void:
	lettering("POST OFFICE",Vector3(0,3.3,-7.5),38)
	_desk(Vector3(0,0,-2),Vector3(9,0.16,1.5))
	for x in range(-6,7,2):
		for y in [0.6,1.25,1.9,2.55]:
			box(self,Vector3(x,y,-7.5),Vector3(1.6,0.5,0.25),"455e42")
			box(self,Vector3(x,y,-7.32),Vector3(0.4,0.07,0.05),"b5bd9e")
	for x in [-6,6]: _chair(Vector3(x,0,3),PI/2)
	lettering("COLLECTIONS  ·  ENQUIRIES",Vector3(0,2.3,-7.3),26)

func _morgue() -> void:
	lettering("MORGUE",Vector3(0,3.3,-7.5),36)
	for x in range(-8,9): box(self,Vector3(x,0.01,0),Vector3(0.025,0.025,16),"acb4a0")
	for z in range(-7,8): box(self,Vector3(0,0.01,z),Vector3(17,0.025,0.025),"acb4a0")
	for x in [-4,4]:
		for z in [-4,0,4]:
			box(self,Vector3(x,0.72,z),Vector3(1.7,0.2,2.8),"89998c",true)
			for dx in [-0.65,0.65]: box(self,Vector3(x+dx,0.35,z),Vector3(0.12,0.7,2),"5d7566",true)
			body(Vector3(x,0.83,z),0,true,false,"morgue")
	person(Vector3(0,0,-5.5),"a1ae98",false)
	target("morgue_coroner","Speak with the coroner",Vector3(0,0,-4.5))
