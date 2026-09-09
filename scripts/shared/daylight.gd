extends Node3D

const Clock=preload("res://scripts/shared/day_clock.gd")
var phase_name=""
var sun_disk:MeshInstance3D
var directional:DirectionalLight3D
var environment:Environment
var world:Node3D

func setup(scene:Node3D) -> void:
	world=scene
	for node in scene.get_children():
		if node is DirectionalLight3D: directional=node
		if node is WorldEnvironment: environment=node.environment
	sun_disk=MeshInstance3D.new()
	var mesh=SphereMesh.new()
	mesh.radius=4.0
	mesh.height=8.0
	mesh.radial_segments=24
	mesh.rings=12
	sun_disk.mesh=mesh
	var m=StandardMaterial3D.new()
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color=Color("e6e6cf")
	m.disable_fog=true
	sun_disk.material_override=m
	sun_disk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sun_disk)

func update_clock(minutes:float,anchor:Vector3) -> void:
	var current=Clock.phase(minutes)
	# +X is east in every outdoor hub. Noon is at the zenith.
	var direction=Vector3(95,40,0) if current=="morning" else (Vector3(0,100,0) if current=="noon" else Vector3(-95,40,0))
	sun_disk.position=anchor+direction
	if current==phase_name: return
	phase_name=current
	sun_disk.visible=current!="night"
	var night=current=="night"
	var dusk=current=="evening"
	if is_instance_valid(directional):
		directional.light_energy=0.0 if night else (0.42 if dusk else (0.8 if current=="noon" else 0.58))
		# Fixed phase poses, not a continuously simulated sun/shadow cycle.
		directional.rotation_degrees=Vector3(-90,0,0) if current=="noon" else Vector3(-23,90 if current=="morning" else -90,0)
	if environment:
		environment.background_color=Color("111a20") if night else (Color("545b59") if dusk else Color("82918d"))
		environment.ambient_light_energy=0.23 if night else (0.3 if dusk else 0.42)
		environment.fog_light_color=environment.background_color
	for lamp in world.find_children("*","OmniLight3D",true,false):
		if lamp.has_meta("street_lamp"): lamp.visible=night or dusk
	for glass in world.find_children("*","MeshInstance3D",true,false):
		if glass.has_meta("lamp_glass"):
			var material=glass.material_override as StandardMaterial3D
			material.emission_enabled=night or dusk
