shader_type canvas_item;

// CEL-04 (cel 2.5D pass, character — 2026-06-13).
// Brings the maid into the SAME cel render language as the blocks so she stops
// reading as a stock sprite pasted on a busy neon stage. Alpha-keyed (no UV
// rect mask) → her hand-drawn silhouette is preserved exactly. Three things,
// all gentle enough to keep the pastel art intact:
//   1. soft banded top-light (anime cel shade, much lighter than the blocks),
//   2. a thin ink rim hugging the silhouette (matches the block ink tone),
//   3. a cool rim light along the upper/side edges that LIFTS her off the dark
//      background — the #1 readability fix from the ANIM-01 critique.
// Reads uniform defaults so player.gd can share one material on body + tray.

uniform float cel_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 shadow_tint = vec3(0.74, 0.70, 0.86);   // faint cool violet shade
uniform vec3 rim_color = vec3(0.62, 0.90, 1.0);      // cool neon-stage rim
uniform vec4 ink_color : source_color = vec4(0.13, 0.09, 0.22, 1.0);
uniform float ink_width : hint_range(0.0, 4.0) = 1.2;
uniform float rim_strength : hint_range(0.0, 1.5) = 0.7;
uniform float band_depth : hint_range(0.0, 0.3) = 0.12; // how dark the low band

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.02) {
		COLOR = tex;
	} else {
		vec3 base = tex.rgb;
		vec2 px = TEXTURE_PIXEL_SIZE;

		// Soft cel bands from a synthetic top light. Kept shallow so the
		// pastel maid never crushes to muddy darks.
		float l = clamp(0.5 - (UV.y - 0.5) * 1.1, 0.0, 1.0);
		float band = clamp(floor(l * 3.0) / 2.0, 0.0, 1.0);  // 0 / 0.5 / 1
		float lum = mix(1.0 - band_depth, 1.0 + band_depth * 0.4, band);
		vec3 cel = base * lum;

		// Lowest band leans a faint cool violet (tinted anime shadow).
		float shadow_w = 1.0 - step(0.4, l);
		cel = mix(cel, cel * shadow_tint * 1.35, shadow_w * 0.30);

		// Rim light: edges that face up/out and border transparency catch the
		// stage light. Sampling the alpha gradient gives a cheap edge normal.
		float a_up = texture(TEXTURE, UV - vec2(0.0, px.y * 2.0)).a;
		float a_dn = texture(TEXTURE, UV + vec2(0.0, px.y * 2.0)).a;
		float a_l = texture(TEXTURE, UV - vec2(px.x * 2.0, 0.0)).a;
		float a_r = texture(TEXTURE, UV + vec2(px.x * 2.0, 0.0)).a;
		float top_edge = clamp(tex.a - a_up, 0.0, 1.0);
		float side_edge = max(clamp(tex.a - a_l, 0.0, 1.0), clamp(tex.a - a_r, 0.0, 1.0));
		float rim = clamp(top_edge * 1.0 + side_edge * 0.5, 0.0, 1.0);
		cel += rim_color * rim * rim_strength;

		COLOR.rgb = mix(base, cel, cel_strength);

		// Thin ink outline on the silhouette (manga line, matches blocks).
		float ink_a = texture(TEXTURE, UV - vec2(px.x * ink_width, 0.0)).a;
		float ink_b = texture(TEXTURE, UV + vec2(px.x * ink_width, 0.0)).a;
		float ink_c = texture(TEXTURE, UV - vec2(0.0, px.y * ink_width)).a;
		float ink_d = texture(TEXTURE, UV + vec2(0.0, px.y * ink_width)).a;
		float edge = (1.0 - min(min(ink_a, ink_b), min(ink_c, ink_d))) * step(0.5, tex.a);
		COLOR.rgb = mix(COLOR.rgb, ink_color.rgb, edge * ink_color.a * cel_strength * 0.85);

		COLOR.a = tex.a;
	}
}
