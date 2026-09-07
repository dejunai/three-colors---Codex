shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float instability : hint_range(0.0, 1.0) = 0.08;
uniform float aperture_radius : hint_range(0.1, 2.0) = 2.0;
uniform float frame_width : hint_range(0.2, 1.0) = 1.0;
uniform float time_value = 0.0;
uniform float preserve_red : hint_range(0.0, 1.0) = 0.9;
uniform float tunnel_darkness : hint_range(0.0, 0.8) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float shiver = sin(UV.y * 73.0 + time_value * 2.1) * 0.0017 * instability;
	shiver += sin(UV.y * 181.0 - time_value * 1.3) * 0.0007 * instability;
	vec2 warped_uv = clamp(UV + vec2(shiver, 0.0), vec2(0.001), vec2(0.999));
	vec3 source = textureLod(screen_texture, warped_uv, 0.0).rgb;
	float luminance = dot(source, vec3(0.299, 0.587, 0.114));
	vec3 silver = vec3(luminance * 0.96, luminance * 0.985, luminance * 1.02);
	float red_dominance = smoothstep(0.08, 0.38, source.r - max(source.g, source.b));
	vec3 graded = mix(silver, source, red_dominance * preserve_red);

	float grain = hash(floor(UV * vec2(1280.0, 720.0)) + floor(time_value * 18.0));
	graded += (grain - 0.5) * (0.055 + instability * 0.12);
	float vignette = smoothstep(0.82, 0.18, length(centered * vec2(1.08, 1.0)));
	graded *= mix(0.62, 1.0, vignette);
	graded *= 1.0 - tunnel_darkness;

	float color_fringe = instability * smoothstep(0.2, 0.72, length(centered));
	graded.r += color_fringe * 0.07 * sin(time_value + UV.y * 11.0);
	graded.b += color_fringe * 0.085 * cos(time_value * 0.7 + UV.x * 13.0);

	float aspect = 1280.0 / 720.0;
	float iris_distance = length(vec2(centered.x * aspect, centered.y));
	float iris_mask = 1.0 - smoothstep(aperture_radius - 0.025, aperture_radius, iris_distance);
	float frame_mask = 1.0 - smoothstep(frame_width * 0.5 - 0.004, frame_width * 0.5 + 0.004, abs(centered.x));
	float mask = iris_mask * frame_mask;
	COLOR = vec4(max(graded, vec3(0.0)) * mask, 1.0);
}

