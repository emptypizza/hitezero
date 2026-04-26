shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.34;
uniform float scanline_strength : hint_range(0.0, 0.25) = 0.075;
uniform float gradient_shade : hint_range(0.0, 0.35) = 0.12;

void fragment() {
	vec4 tex_sample = texture(TEXTURE, UV);
	vec3 col = tex_sample.rgb;
	float gy = abs(UV.y - 0.5) * 2.0;
	col *= 1.0 - gradient_shade * gy;
	vec2 c = UV - 0.5;
	float dist = length(c) * 2.0;
	float vig = 1.0 - vignette_strength * smoothstep(0.38, 1.15, dist);
	col *= vig;
	float scan = sin(UV.y * 3.14159265 * 520.0) * 0.5 + 0.5;
	col *= 1.0 - scanline_strength * scan;
	COLOR = vec4(col, tex_sample.a);
}
