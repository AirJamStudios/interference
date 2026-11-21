shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.0;
uniform vec4 phosphor_color : source_color = vec4(0.8314, 1.0, 0.8627, 1.0);
uniform float line_thickness = 0.004; // fraction of screen height
uniform float glow_size = 12.0;       // pixels
uniform float glow_strength = 0.45;   // 0..1, halo brightness

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float aspect = px.y / px.x;

	float squash = smoothstep(0.0, 0.55, progress);
	float shrink = smoothstep(0.5, 0.85, progress);
	float fade = smoothstep(0.85, 1.0, progress);

	float h = mix(1.0, line_thickness, squash);
	float w = mix(1.0, line_thickness / aspect, shrink);

	vec2 c = SCREEN_UV - 0.5;

	vec2 sample_uv = vec2(0.5 + c.x / w, 0.5 + c.y / h);
	vec3 col = texture(screen_tex, clamp(sample_uv, 0.0, 1.0)).rgb;

	col = mix(col, phosphor_color.rgb, squash * 0.5) * (1.0 + squash * 0.4);

	vec2 d = max(abs(c) - vec2(w, h) * 0.5, 0.0) / px;
	float dist = length(d);
	float inside = 1.0 - smoothstep(0.0, 1.5, dist);
	float glow = exp(-dist / glow_size) * squash * glow_strength;

	vec3 result = col * inside + phosphor_color.rgb * glow * (1.0 - inside);
	result *= 1.0 - fade;

	if (flicker > 0.0) {
		float t = floor(TIME * 30.0);
		float jitter = 1.0 - flicker * 0.3 * hash(t);
		float scan = 1.0 - flicker * 0.25 * step(0.5, fract(SCREEN_UV.y / px.y * 0.5 + TIME * 4.0));
		result *= jitter * scan;
	}

	COLOR = vec4(result, 1.0);
}
