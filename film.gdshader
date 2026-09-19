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
// The boxed silent-film frame (bible Part One, The Frame). Chapter One's starting
// frame is 4:3 inside the 16:10 window, so each pillar is 0.0833 of the width.
// Widening the frame is an authored beat, driven from film_presentation.gd.
uniform float frame_edge : hint_range(0.0, 0.5) = 0.0833;
// Color returning to Walter's world (bible Part One, The Baseline). 0 leaves the
// grayscale grade untouched. It does not wash the frame: only warm hues come back,
// first the ones the Observer band already passes (red thread, amber), then, as this
// rises, warm-leaning materials (paper, wood, skin) a little at a time and unevenly.
uniform float color_return : hint_range(0.0, 1.0) = 0.0;
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
    if (color_return > 0.0) {
        // Widen the warm band as color returns: less red dominance is needed to pass.
        // Green-gray materials never lead in red, so the room stays gray around it.
        float lead = col.r - max(col.g, col.b);
        float warm = smoothstep(mix(0.05, -0.02, color_return), mix(0.22, 0.10, color_return), lead);
        float drift = 0.5 + 0.5 * sin(SCREEN_UV.x * 7.0 + sin(SCREEN_UV.y * 5.0 + TIME * 0.15) * 1.5);
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 lifted = clamp(mix(vec3(luma), col, 2.2), 0.0, 1.0);
        graded = mix(graded, lifted, clamp(color_return * warm * mix(0.5, 1.3, drift) * 1.5, 0.0, 1.0));
    }
    float vignette = 1.0 - smoothstep(0.22, 0.72, length(p)) * 0.48;
    vec2 circle = p * vec2(1.6, 1.0);
    float mask = 1.0 - smoothstep(iris, iris + 0.025, length(circle));
    float frame = step(frame_edge, SCREEN_UV.x) * step(SCREEN_UV.x, 1.0 - frame_edge);
    COLOR = vec4(graded * vignette * mask * frame, 1.0);
}

