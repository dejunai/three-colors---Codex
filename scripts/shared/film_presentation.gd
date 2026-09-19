extends CanvasLayer

const BOXED_FRAME = 0.0833

var material: ShaderMaterial
var shader: Shader
var aperture=0.51
var aperture_target=0.51
# Frame width and color return are authored beats, not player-driven degradation.
# Both hold their value until a chapter sets a target; speeds are units per second.
var frame_edge=BOXED_FRAME
var frame_target=BOXED_FRAME
var frame_speed=0.02
var color_return=0.0
var color_target=0.0
var color_speed=0.1

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

func widen_frame(duration:float) -> void:
	frame_target=0.0
	frame_speed=frame_edge/maxf(0.001,duration)

func return_color(amount:float,duration:float) -> void:
	color_target=clampf(amount,0.0,1.0)
	color_speed=absf(color_target-color_return)/maxf(0.001,duration)

func restore_frame() -> void:
	frame_edge=BOXED_FRAME
	frame_target=BOXED_FRAME
	color_return=0.0
	color_target=0.0

func advance(delta:float,strain:float,relieved:bool,settings:Dictionary) -> void:
	aperture=move_toward(aperture,aperture_target,delta*0.16)
	frame_edge=move_toward(frame_edge,frame_target,delta*frame_speed)
	color_return=move_toward(color_return,color_target,delta*color_speed)
	material.set_shader_parameter("iris",aperture)
	material.set_shader_parameter("frame_edge",frame_edge)
	material.set_shader_parameter("color_return",color_return)
	material.set_shader_parameter("distortion",float(settings.distortion)*strain*(0.1 if relieved else 1.0))
