// Credits to: https://godotshaders.com/shader/crt-visual-shader-godot-4-0/

shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_tex : source_color, filter_linear, repeat_disable;

// Display settings
uniform vec2 resolution = vec2(681.0, 512.0);
uniform float brightness = 1.4;

// Scanline settings
uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;

// Distortion settings
uniform bool roll = true;
uniform float roll_speed = 8.0;
uniform float roll_size : hint_range(0.0, 100.0) = 15.0;
uniform float roll_variation : hint_range(0.1, 5.0) = 1.8;
uniform float distort_intensity : hint_range(0.0, 0.2) = 0.05;
uniform float aberration : hint_range(-1.0, 1.0) = 0.03;

// Noise settings
uniform float noise_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_speed = 5.0;
uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;

// Additional effects
uniform bool pixelate = true;
uniform bool discolor = false;
uniform float warp_amount : hint_range(0.0, 5.0) = 1.0;
uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

vec2 random(vec2 uv) {
	uv = vec2(dot(uv, vec2(127.1, 311.7)), dot(uv, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
	vec2 uv_index = floor(uv);
	vec2 uv_fract = fract(uv);
	vec2 blur = smoothstep(0.0, 1.0, uv_fract);
	return mix(
		mix(
			dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0)),
			dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0)),
			blur.x
		),
		mix(
			dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0)),
			dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0)),
			blur.x
		),
		blur.y
	) * 0.5 + 0.5;
}

vec2 warp(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta.xy, delta.xy);
	float delta4 = delta2 * delta2;
	return uv + delta * (delta4 * warp_amount);
}

float border(vec2 uv) {
	float radius = min(warp_amount, 0.08);
	radius = max(min(min(abs(radius * 2.0), abs(1.0)), abs(1.0)), 1e-5);
	vec2 abs_uv = abs(uv * 2.0 - 1.0) - vec2(1.0, 1.0) + radius;
	float dist = length(max(vec2(0.0), abs_uv)) / radius;
	return clamp(1.0 - smoothstep(0.96, 1.0, dist), 0.0, 1.0);
}

float vignette(vec2 uv) {
	uv *= 1.0 - uv.xy;
	float vig = uv.x * uv.y * 15.0;
	return pow(vig, vignette_intensity * vignette_opacity);
}

void fragment() {
	vec2 uv = warp(UV);
	vec2 text_uv = uv;

	if (pixelate) {
		text_uv = ceil(uv * resolution) / resolution;
	}

	float roll_line = 0.0;
	vec2 roll_uv = vec2(0.0);

	if (roll || noise_opacity > 0.0) {
		float time = roll ? TIME : 0.0;
		roll_line = smoothstep(0.3, 0.9, sin(uv.y * roll_size - (time * roll_speed)));
		roll_line *= roll_line * smoothstep(0.3, 0.9, sin(uv.y * roll_size * roll_variation - (time * roll_speed * roll_variation)));
		roll_uv = vec2(roll_line * distort_intensity * (1.0 - UV.x), 0.0);
	}

	vec3 text;
	if (roll) {
		text.r = texture(screen_tex, text_uv + roll_uv * 0.8 + vec2(aberration, 0.0) * 0.1).r;
		text.g = texture(screen_tex, text_uv + roll_uv * 1.2 - vec2(aberration, 0.0) * 0.1).g;
		text.b = texture(screen_tex, text_uv + roll_uv).b;
	} else {
		text.r = texture(screen_tex, text_uv + vec2(aberration, 0.0) * 0.1).r;
		text.g = texture(screen_tex, text_uv - vec2(aberration, 0.0) * 0.1).g;
		text.b = texture(screen_tex, text_uv).b;
	}

	if (grille_opacity > 0.0) {
		float gr = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
		float gg = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
		float gb = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));
		text.r = mix(text.r, text.r * gr, grille_opacity);
		text.g = mix(text.g, text.g * gg, grille_opacity);
		text.b = mix(text.b, text.b * gb, grille_opacity);
	}

	text = clamp(text * brightness, 0.0, 1.0);

	if (scanlines_opacity > 0.0) {
		float scan = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
		text = mix(text, text * vec3(scan), scanlines_opacity);
	}

	if (noise_opacity > 0.0) {
		float n = smoothstep(0.4, 0.5, noise(uv * vec2(2.0, 200.0) + vec2(10.0, TIME * noise_speed)));
		float nl = n * roll_line * clamp(random((ceil(uv * resolution) / resolution) + vec2(TIME * 0.8, 0.0)).x + 0.8, 0.0, 1.0);
		text = clamp(mix(text, text + nl, noise_opacity), vec3(0.0), vec3(1.0));
	}

	if (static_noise_intensity > 0.0) {
		text += clamp(random((ceil(uv * resolution) / resolution) + fract(TIME)).x, 0.0, 1.0) * static_noise_intensity;
	}

	text *= border(uv);
	text *= vignette(uv);

	if (discolor) {
		vec3 greyscale = vec3(dot(text, vec3(0.333)));
		text = mix(text, greyscale, 0.5);
		float midpoint = pow(0.5, 2.2);
		text = (text - vec3(midpoint)) * 1.2 + midpoint;
	}

	ALBEDO = text;
}