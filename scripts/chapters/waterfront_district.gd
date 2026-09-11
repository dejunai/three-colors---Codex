extends RefCounted

# Ordinary working waterfront. The distant station is scenery, never a route.
func build(w: Node3D) -> void:
	w.box(w,Vector3(0,-0.5,8),Vector3(64,1,42),"59605a",true)
	w.box(w,Vector3(0,-1.35,-53),Vector3(190,0.12,92),"465b60")
	# Seawall: continuous collision keeps the water outside the playable quay.
	w.box(w,Vector3(0,-0.3,-12),Vector3(64,2.2,1.4),"73766b",true)
	for x in range(-30,31,3):
		w.box(w,Vector3(x,0.85,-12),Vector3(2.95,0.25,1.6),"929589")
		w.box(w,Vector3(x,-0.35,-12.76),Vector3(0.06,1.6,0.03),"3e4c48")
	# Narrow plank apron and mooring hardware.
	for x in range(-30,31):
		w.box(w,Vector3(x,0.03,-8),Vector3(0.94,0.08,6),"73776a")
	for x in [-27,-15,-3,9,21,29]:
		w.cylinder(w,Vector3(x,0.45,-10.5),0.19,0.9,"343e39")
		w.box(w,Vector3(x,0.8,-10.5),Vector3(0.8,0.12,0.22),"343e39")
	# Simple fishing boats moored below the quay, without boarding prompts.
	for x in [-20,3,23]:
		w.box(w,Vector3(x,-0.85,-18),Vector3(3.3,0.6,7),"333d37")
		w.box(w,Vector3(x,-0.48,-18),Vector3(2.6,0.12,5.8),"858473")
		w.box(w,Vector3(x,0.1,-19),Vector3(1.7,1.1,1.7),"656c5d")
		w.cylinder(w,Vector3(x,1.7,-17),0.07,5.4,"5b6053")
	# Four modest fronts, reserved for future writers; no invented residents.
	for spec in [[-22,"CHANDLERY"],[-7,"FREIGHT OFFICE"],[8,"NET LOFT"],[23,"FISH STORES"]]:
		var x:float=spec[0]
		w.box(w,Vector3(x,3,17),Vector3(12,6,9),"60695e",true)
		w.box(w,Vector3(x,6.2,17),Vector3(12.6,0.4,9.5),"35453e")
		w.box(w,Vector3(x,1.4,12.42),Vector3(1.7,2.8,0.12),"34463b")
		for dx in [-3.5,3.5]:
			w.box(w,Vector3(x+dx,2.4,12.42),Vector3(2.1,1.7,0.12),"344943")
			w.box(w,Vector3(x+dx,2.4,12.3),Vector3(0.08,1.9,0.12),"969a85")
		w.lettering(spec[1],Vector3(x,4.3,12.2),30).rotation.y=PI
	# Repairs and nets give the existing residents places to work.
	for x in [17,20,23]:
		w.box(w,Vector3(x,0.35,-3),Vector3(1.8,0.7,1.3),"929184",true)
	for x in [-25,-21]:
		w.cylinder(w,Vector3(x,1.4,0),0.07,2.8,"57604f")
	for y in [0.8,1.1,1.4,1.7,2.0]:
		w.box(w,Vector3(-23,y,0),Vector3(4,0.025,0.025),"94957c")
	for x in range(-25,-20):
		w.box(w,Vector3(x,1.4,0),Vector3(0.025,1.5,0.025),"94957c")
	for x in [-27,-12,12,27]: w.lamp(Vector3(x,0,7))
	# Return lane between the buildings, easy to see from the arrival point.
	w.lettering("PICKMAN STREET",Vector3(0,3.3,23),30).rotation.y=PI
	w.target("route_pickman","Return uphill to Pickman Street",Vector3(0,0,23))
	w.routes["route_pickman"]=["town",Vector3(-26,0.1,7),PI/2]
	# Low island silhouette; mud covers the base of the abandoned works.
	var island=Node3D.new()
	island.name="OffshoreWhalingStation"
	w.add_child(island)
	w.box(island,Vector3(9,-0.3,-72),Vector3(28,2.2,13),"626b62")
	w.box(island,Vector3(8,1.25,-72),Vector3(13,3.8,6),"4a5751")
	w.box(island,Vector3(8,3.25,-72),Vector3(14,0.5,7),"364941")
	w.box(island,Vector3(1,3.5,-73),Vector3(1.7,8,1.7),"48574f")
	for spec in [[3,-68,8],[12,-67,12],[20,-71,9]]:
		w.box(island,Vector3(spec[0],0.8,spec[1]),Vector3(spec[2],2.8,7),"777563")
