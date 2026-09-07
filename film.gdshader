shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grain = 0.025;
uniform float distortion = 0.0;
uniform float iris = 1.0;
uniform float contrast = 1.0;
uniform bool animated_grain = false;
// Observer color tell (bible Part Two): the world renders grayscale except for
// the specific warm-red accent flagged on Observer materials (estate.gd's
// person() "accent" jewelry). Every other material in the game's palette is a
// desaturated gray/green/brown with no red-channel dominance, so this narrow
// hue band only ever fires on deliberately flagged geometry, not a blanket filter.
uniform float preserve_color : hint_range(0.0, 1.0) = 0.9;
void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 p = uv - vec2(0.5);
    float wobble = sin(uv.y * 16.0 + TIME * 0.4) * 0.001 * distortion;
    uv.x += wobble;
    vec3 col = texture(screen_texture, uv).rgb;
    float mono = dot(col, vec3(0.299, 0.587, 0.114));
    float seed = animated_grain ? floor(TIME * 12.0) : 1.0;
    float noise = fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)) + seed) * 43758.5453);
    mono = (mono - 0.5) * contrast + 0.5;
    mono += (noise - 0.5) * grain;
    float red_dominance = smoothstep(0.05, 0.22, col.r - max(col.g, col.b));
    vec3 graded = mix(vec3(max(0.0, mono)), col, red_dominance * preserve_color);
    float vignette = 1.0 - smoothstep(0.22, 0.72, length(p)) * 0.48;
    vec2 circle = p * vec2(1.6, 1.0);
    float mask = 1.0 - smoothstep(iris, iris + 0.025, length(circle));
    float frame = step(0.0833, SCREEN_UV.x) * step(SCREEN_UV.x, 0.9167);
    COLOR = vec4(graded * vignette * mask * frame, 1.0);
}

