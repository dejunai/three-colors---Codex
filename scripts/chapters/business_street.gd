extends RefCounted

# A single visual reference street. Stable entrances and save IDs belong to TownPlaces.
const Places = preload("res://scripts/chapters/town_places.gd")
static var materials: Dictionary = {}
static var textures: Dictionary = {}

func surface(kind:String,tint:String) -> StandardMaterial3D:
	var key=kind+tint
	if materials.has(key): return materials[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=Color(tint)
	m.albedo_texture=texture(kind)
	m.uv1_triplanar=true
	m.uv1_scale=Vector3.ONE*(0.8 if kind=="wood" else 0.55)
	m.roughness=0.95
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	materials[key]=m
	return m

func texture(kind:String) -> ImageTexture:
	if textures.has(kind): return textures[kind]
	var img=Image.create(128,128,false,Image.FORMAT_RGB8)
	var noise=RandomNumberGenerator.new()
	noise.seed=192309
	for y in 128:
		for x in 128:
			var v=0.86+noise.randf_range(-0.065,0.065)
			match kind:
				"stone":
					if y%32<2 or (x+(16 if floori(y/32.0)%2 else 0))%32<2: v=0.58
				"brick":
					if y%16<2 or (x+(16 if floori(y/16.0)%2 else 0))%32<2: v=0.62
				"wood":
					v+=sin(float(x)*0.8+sin(float(y)*0.08))*0.035
					if x%32<2: v=0.48
				"slate":
					if y%24<2 or (x+(12 if floori(y/24.0)%2 else 0))%24<1: v=0.48
			img.set_pixel(x,y,Color(v,v,v))
	img.generate_mipmaps()
	var result=ImageTexture.create_from_image(img)
	textures[kind]=result
	return result

func block(g:Node,p:Vector3,size:Vector3,kind:String,tint:String,solid:bool=false) -> MeshInstance3D:
	var n=g.box(g,p,size,tint,solid)
	n.material_override=surface(kind,tint)
	return n

func triangles(g:Node,vertices:Array,kind:String,tint:String) -> void:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices: st.add_vertex(vertex)
	st.generate_normals()
	var n=MeshInstance3D.new()
	n.mesh=st.commit()
	n.material_override=surface(kind,tint)
	g.add_child(n)

func beam(g:Node,a:Vector3,b:Vector3,width:float=0.13) -> void:
	var n=block(g,(a+b)/2,Vector3(width,a.distance_to(b),width),"wood","465348")
	n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

func window(g:Node,p:Vector3,width:float,height:float,back:float) -> void:
	block(g,p,Vector3(width,height,0.10),"plaster","293d38")
	for dx in [-width/2,0,width/2]:
		block(g,p+Vector3(dx,0,-back*0.09),Vector3(0.10,height+0.2,0.14),"wood","a3aa96")
	for dy in [-height/2,0,height/2]:
		block(g,p+Vector3(0,dy,-back*0.1),Vector3(width+0.2,0.1,0.14),"wood","a3aa96")
	block(g,p+Vector3(0,-height/2-0.1,-back*0.2),Vector3(width+0.45,0.16,0.45),"stone","828e80")

func build(g:Node) -> void:
	block(g,Vector3(0,-0.3,10),Vector3(66,0.5,54),"stone","69746a",true)
	block(g,Vector3(0,-0.015,8),Vector3(60,0.05,11),"stone","667469")
	# Uneven frontage widths read as piecemeal construction; the through route stays clear.
	for i in 6:
		var p=Places.front(i)
		var back=-1.0 if i<3 else 1.0
		var widths=[15.8,12.8,14.5,14.0,15.4,12.0]
		var heights=[7.3,5.9,7.7,7.0,6.6,5.5]
		var w:float=widths[i]
		var h:float=heights[i]
		var spec=Places.BUILDINGS.business[i]
		var tint="a2aa95" if i in [0,3] else ("7d8c7c" if i%2 else "8e9987")
		var kind="brick" if i in [0,4] else "plaster"
		block(g,p+Vector3(0,-0.02,-back*2.9),Vector3(w+1.4,0.13,6.6),"stone","9ba58f")
		block(g,p+Vector3(0,0.38,back*4),Vector3(w+0.15,0.76,7),"stone","788779",true)
		block(g,p+Vector3(0,h/2+0.25,back*4),Vector3(w,h-0.5,7),kind,tint,true)
		# Recessed dark door, with substantial jambs and lintel.
		block(g,p+Vector3(0,1.48,back*0.42),Vector3(1.7,2.95,0.1),"wood","34473d")
		for x in [-1.04,1.04]: block(g,p+Vector3(x,1.55,back*0.12),Vector3(0.28,3.1,0.55),"stone","939e89")
		block(g,p+Vector3(0,3.12,back*0.12),Vector3(2.35,0.3,0.6),"stone","a2ac96")
		for x in [-w*0.32,w*0.32]:
			window(g,p+Vector3(x,1.95,back*0.36),3.2 if i!=0 else 2.0,2.0,back)
			window(g,p+Vector3(x,h-1.25,back*0.35),1.45,1.7,back)
		# Slightly projecting upper storeys and visible timber divisions.
		if i in [1,2,3,5]:
			for y in [3.65,h-0.08]: block(g,p+Vector3(0,y,back*0.1),Vector3(w+0.3,0.24,0.45),"wood","465348")
			for x in [-w/2+0.12,0,w/2-0.12]:
				beam(g,p+Vector3(x,3.65,back*0.1),p+Vector3(x,h,back*0.1),0.18)
		# Gable ends face the street. Roof silhouette varies without bespoke assets.
		var rise=3.0 if i in [0,2] else 2.1
		var z0=back*0.2
		var z1=back*8.0
		var a=p+Vector3(-w/2-0.5,h,z0)
		var b=p+Vector3(w/2+0.5,h,z0)
		var c=p+Vector3(0,h+rise,z0)
		var d=p+Vector3(-w/2-0.5,h,z1)
		var e=p+Vector3(w/2+0.5,h,z1)
		var f=p+Vector3(0,h+rise,z1)
		triangles(g,[a,b,c,d,f,e],kind,tint)
		triangles(g,[a,c,f,a,f,d,c,b,e,c,e,f],"slate","435449")
		beam(g,a,c,0.2)
		beam(g,c,b,0.2)
		beam(g,a,b,0.2)
		window(g,p+Vector3(0,h+0.85,back*0.12),0.9,1.0,back)
		block(g,p+Vector3(w*0.3,h+1.0,back*5.5),Vector3(0.9,3.2,1.0),"brick","7a8878")
		block(g,p+Vector3(w*0.3,h+2.65,back*5.5),Vector3(1.1,0.2,1.2),"stone","4c5d50")
		# Signs remain readable against a dark fascia, independent of plaster values.
		var title:String=spec[1].split(" · ")[0]
		block(g,p+Vector3(0,3.5,-back*0.15),Vector3(6.8,0.58,0.16),"wood","2c4036")
		var sign=g.lettering(title,p+Vector3(0,3.5,-back*0.26),40)
		sign.rotation.y=0 if i<3 else PI
		if i!=0:
			var awning=block(g,p+Vector3(w*0.31,3.2,-back*0.4),Vector3(4.1,0.14,1.4),"wood","687e64")
			awning.rotation.x=back*0.13
		if spec[3]=="exterior":
			for y in [0.7,1.5,2.3]: block(g,p+Vector3(0,y,0),Vector3(1.8,0.2,0.1),"wood","7b8975")
		else:
			var id="route_"+spec[0]
			g.target(id,"Enter "+title.to_lower(),p)
			g.routes[id]=[spec[0],Vector3(0,0.1,6),0.0]
	# Gutters and a paved walking strip link the mismatched individual frontages.
	for z in [2.4,13.6]:
		block(g,Vector3(0,0.01,z),Vector3(60,0.055,0.3),"stone","3b5045")
	for x in [-28,-9,9,28]: g.lamp(Vector3(x,0,1))
	# School bench and a modest notice case: no new clues or dialogue.
	block(g,Vector3(-25,0.55,-2),Vector3(3,0.16,0.7),"wood","596e53",true)
	block(g,Vector3(-25,1.0,-2.35),Vector3(3,0.75,0.13),"wood","596e53")
	block(g,Vector3(-12.6,1.8,-4.3),Vector3(1.3,1.4,0.12),"wood","384d3e")
	for x in [-12.9,-12.35]: block(g,Vector3(x,1.8,-4.21),Vector3(0.42,0.8,0.02),"plaster","b7bca4")
	for x in [8,12]: block(g,Vector3(x,1.8,27),Vector3(0.3,3.6,0.4),"stone","8e9b81")
	g.lettering("PICKMAN STREET",Vector3(10,3.7,27),34).rotation.y=PI
	g.target("route_pickman","Return to Pickman Street",Vector3(10,0,26))
	g.routes["route_pickman"]=["town",Vector3(8,0.1,20),PI]

