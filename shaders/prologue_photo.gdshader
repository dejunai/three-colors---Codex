shader_type canvas_item;

// Desaturate + lift contrast on the prologue/title background photos.
uniform float saturation : hint_range(0.0, 1.0) = 0.45;
uniform float contrast : hint_range(0.5, 2.0) = 1.08;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(vec3(gray), tex.rgb, saturation);
	vec3 lifted = (desaturated - vec3(0.5)) * contrast + vec3(0.5);
	COLOR = vec4(lifted, tex.a);
}
