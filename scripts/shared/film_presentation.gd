extends CanvasLayer

var material: ShaderMaterial
var shader: Shader
var aperture=0.51
var aperture_target=0.51

func _ready() -> void:
	layer=20
	var screen=ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	material=ShaderMaterial.new()
	material.shader=shader
	screen.material=material
	add_child(screen)

func apply_settings(settings:Dictionary) -> void:
	material.set_shader_parameter("grain",float(settings.grain))
	material.set_shader_parameter("contrast",float(settings.contrast))
	material.set_shader_parameter("animated_grain",not bool(settings.reduced_flicker))

func advance(delta:float,strain:float,relieved:bool,settings:Dictionary) -> void:
	aperture=move_toward(aperture,aperture_target,delta*0.16)
	material.set_shader_parameter("iris",aperture)
	material.set_shader_parameter("distortion",float(settings.distortion)*strain*(0.1 if relieved else 1.0))
