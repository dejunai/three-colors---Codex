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
		var exit_dest=hub
		var exit_pos=Places.front(index)+Vector3(0,0.1,1.4 if index<3 else -1.4)
		var exit_label="Return to the neighborhood"
		var parent_chapter=get_parent()
		var entered_from_hub=parent_chapter!=null and "town_exterior_world" in parent_chapter and parent_chapter.town_exterior_world==hub
		if not entered_from_hub:
			var contiguous_pos=null
			if hub=="upper":
				contiguous_pos=preload("res://scripts/chapters/contiguous_town_phase_one.gd").upper_return(location)
			elif hub=="business":
				contiguous_pos=preload("res://scripts/chapters/contiguous_town_phase_one.gd").business_return(location)
			elif hub=="lower":
				contiguous_pos=preload("res://scripts/chapters/contiguous_town_phase_two.gd").lower_return(location)
			if contiguous_pos!=null:
				exit_dest="town"
				exit_pos=contiguous_pos
				exit_label="Return to the street"
		_exit_to(exit_dest,exit_pos,exit_label,PI if index<3 else 0.0)
		if spec[3]=="occupied" and location!="speakeasy":
			person(Vector3(3,0,-3),"55624f",false)
			target("local_resident","Speak with the resident",Vector3(3,0,-2))

func _exit_to(destination:String,spawn:Vector3,label:String,angle:float=0.0) -> void:
	target("route_return",label,Vector3(0,0,7.2))
	routes["route_return"]=[destination,spawn,angle]
	routes["interior_exit"]=routes["route_return"]

func _neighborhood() -> void:
	if location == "business":
		preload("res://scripts/chapters/business_street.gd").new().build(self)
		return
	if location == "upper":
		preload("res://scripts/chapters/upper_street.gd").new().build(self)
		return
	if location == "lower":
		preload("res://scripts/chapters/lower_street.gd").new().build(self)
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
				# reached around the rear, beyond the southeast corner. The
				# bulkhead itself is always visible, day or night — only
				# whether it actually opens is time/coat-gated, in
				# chapter_one.gd's _town_interaction().
				var hatch=p+Vector3(7,0,8)
				box(self,hatch+Vector3(0,0.06,0),Vector3(2.3,0.12,1.9),"3c2f20",true)
				box(self,hatch+Vector3(-0.62,0.32,0),Vector3(1.05,0.1,1.8),"55432c").rotation.x=-0.5
				box(self,hatch+Vector3(0.62,0.32,0),Vector3(1.05,0.1,1.8),"55432c").rotation.x=0.5
				box(self,hatch+Vector3(0,0.62,0),Vector3(2.3,0.1,0.12),"241b12")
				target(id,"Try the cellar door",hatch)
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
			_place_prop(PROP_RUG_PATTERNED,"ParlorRug",Vector3(0,0.006,0),5.8,0.0)
			_place_prop(PROP_STONE_FIREPLACE,"ParlorFireplace",Vector3(0,0,-7.2),3.4,PI/2,Vector3(0.392,0.675,1.0))
			_place_prop(PROP_CLUB_SOFA,"ParlorClubSofa",Vector3(-5.6,0,-0.5),3.8,-PI/2,Vector3(0.39,0.393,1.0))
			_place_prop(PROP_PILLOW_BURGUNDY,"ParlorPillowBurgundy",Vector3(-5.0,0.62,-1.2),0.62,-PI/2)
			_place_prop(PROP_PILLOW_GREEN,"ParlorPillowGreen",Vector3(-5.0,0.62,0.5),0.62,-PI/2)
			_place_prop(PROP_CLUB_ARMCHAIR,"ParlorClubChairNorth",Vector3(4.8,0,-1.7),1.35,PI/2,Vector3(0.862,0.893,1.0))
			_place_prop(PROP_CLUB_ARMCHAIR,"ParlorClubChairSouth",Vector3(4.8,0,1.7),1.35,PI/2,Vector3(0.862,0.893,1.0))
			_place_prop(PROP_LOW_TABLE,"ParlorLowTable",Vector3(0,0,0),2.35,0.0,Vector3(0.609,0.339,1.0))
			_place_prop(PROP_SIDEBOARD,"ParlorSideboard",Vector3(5.5,0,-5.7),3.0,PI/2,Vector3(0.324,0.502,1.0))
			_place_prop(PROP_TABLE_LAMP_B,"ParlorTableLamp",Vector3(4.55,1.51,-5.7),0.58,0.0)
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
	for spec in [["Left",-2.15],["Right",2.15]]:
		_place_prop(PROP_POST_COUNTER,"PostOfficeCounter"+spec[0],Vector3(spec[1],0,-2.25),4.0,0.0,Vector3(1,0.43,0.26))
	for spec in [["Left",-2.65],["Right",2.65]]:
		_place_prop(PROP_POST_PIGEONHOLES,"PostOfficePigeonholes"+spec[0],Vector3(spec[1],0,-7.25),5.3,0.0,Vector3(1,0.55,0.20))
	# A few uneven bundles keep the sorting wall from reading as an unused display.
	for spec in [
		[Vector3(-4.4,0.65,-6.66),Vector3(0.46,0.10,0.05),-0.03],
		[Vector3(-2.0,1.22,-6.66),Vector3(0.62,0.12,0.05),0.02],
		[Vector3(0.1,0.72,-6.66),Vector3(0.52,0.11,0.05),-0.015],
		[Vector3(2.2,1.72,-6.66),Vector3(0.58,0.13,0.05),0.025],
		[Vector3(4.25,2.28,-6.66),Vector3(0.43,0.10,0.05),-0.02],
	]:
		var letters := box(self,spec[0],spec[1],"c3bfa3")
		letters.name = "PostOfficeLetterBundle"
		letters.rotation.z = spec[2]
	_place_chair("PostOfficeChairLeft",Vector3(-6,0,3),1.15,PI/2)
	_place_chair("PostOfficeChairRight",Vector3(6,0,3),1.15,-PI/2)
	_place_prop(PROP_CRATE,"PostOfficeCrate",Vector3(-7.1,0,4.6),1.3,0.0,Vector3(1,0.66,0.65))
	_place_prop(PROP_OPEN_CRATE,"PostOfficeOpenCrate",Vector3(7.0,0,4.7),1.15,0.0,Vector3(1,0.61,0.72))
	_place_prop(PROP_BARREL,"PostOfficeBarrel",Vector3(7.4,0,0.4),1.1,0.0,Vector3(0.70,1,0.71))
	lettering("COLLECTIONS  ·  ENQUIRIES",Vector3(0,3.18,-6.64),26)

func _morgue() -> void:
	lettering("MORGUE",Vector3(0,3.3,-7.5),36)
	for x in range(-8,9): box(self,Vector3(x,0.01,0),Vector3(0.025,0.025,16),"acb4a0")
	for z in range(-7,8): box(self,Vector3(0,0.01,z),Vector3(17,0.025,0.025),"acb4a0")
	for x in [-4,4]:
		for z in [-4,0,4]:
			box(self,Vector3(x,0.72,z),Vector3(1.7,0.2,2.8),"89998c",true)
			for dx in [-0.65,0.65]: box(self,Vector3(x+dx,0.35,z),Vector3(0.12,0.7,2),"5d7566",true)
			body(Vector3(x,0.83,z),0,true,false,"morgue")
	# Kept clear of the coroner/assistant work station at x=+-1.6,z=-1.0 (dialogue_catalog.gd
	# FIXED_STAFF/RETURNING_STAFF) so the two hotspots never compete for focus.
	target("morgue_tables","Examine the tables",Vector3(-2.4,0,3.0))

