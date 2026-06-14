shader_type canvas_item;

// VX-02 (duckflock ph.4): rounded block corners.
// Masks the sprite with a UV-space rounded-rect SDF so the brick reads as a
// soft card like the reference, without touching collision AABBs or HP logic.
//
// CEL-01 (cel 2.5D pass, 2026-06-13): subculture cel-slab look layered onto
// the same SDF. Quantized top-light bands, purple-tinted anime shadow with a
// screen-space halftone tone (manga screentone), inner ink outline, key-lit
// bevel rim and a slow diagonal foil glint. Everything reads uniform defaults
// so the single shared ShaderMaterial in block.gd keeps working unchanged.
//
// Applied to NORMAL/STAR/POW block sprites only — never to RED_ENEMY, whose
// blob silhouette must stay untouched (see test_red_enemy_sprite.py).

uniform float corner_radius : hint_range(0.0, 0.5) = 0.16;
uniform float edge_softness : hint_range(0.0, 0.05) = 0.012;

// ── CEL-01 uniforms ──────────────────────────────────────────────────────────
uniform float cel_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec2 light_dir = vec2(-0.35, -0.94);        // key light: top, nudged left
uniform vec3 shadow_tint = vec3(0.42, 0.33, 0.62);  // anime purple shadow, not black
uniform vec4 outline_color : source_color = vec4(0.13, 0.09, 0.22, 1.0);
uniform float outline_width : hint_range(0.0, 0.08) = 0.028;
uniform float bevel_width : hint_range(0.0, 0.2) = 0.085;
uniform float halftone_strength : hint_range(0.0, 1.0) = 0.55;
uniform float halftone_scale = 4.0;                 // screen px between tone dots
uniform float glint_strength : hint_range(0.0, 1.0) = 0.45;
uniform float glint_period = 7.0;                   // s per foil sweep

void fragment() {
	vec2 p = abs(UV - vec2(0.5));
	vec2 q = p - (vec2(0.5 - corner_radius));
	float dist = length(max(q, vec2(0.0))) - corner_radius;
	float mask = 1.0 - smoothstep(-edge_softness, edge_softness, dist);

	// ── Cel bands: synthetic top light snapped to 3 steps ────────────────────
	float l = clamp(0.5 - (UV.y - 0.5) * 1.25, 0.0, 1.0);
	float band = clamp(floor(l * 3.0) / 2.0, 0.0, 1.0);  // 0.0 / 0.5 / 1.0
	float lum = mix(0.86, 1.10, band);
	vec3 cel = COLOR.rgb * lum;

	// Darkest band leans purple — anime shadows are tinted, never plain dark.
	float shadow_w = 1.0 - step(0.34, l);
	cel = mix(cel, cel * shadow_tint * 2.0, shadow_w * 0.38);

	// Manga screentone: screen-space halftone dots inside the shadow band.
	vec2 cell = mod(FRAGCOORD.xy, vec2(halftone_scale));
	float dot_d = length(cell - vec2(halftone_scale * 0.5));
	float tone = 1.0 - smoothstep(0.9, 1.5, dot_d);
	cel = mix(cel, cel * 0.78, tone * shadow_w * halftone_strength);

	// Bevel rim: bright where the rounded edge faces the key light, shaded
	// where it falls away — sells the card as a lit slab, not a sticker.
	float edge_w = smoothstep(-bevel_width, 0.0, dist);
	vec2 edge_dir = max(q, vec2(0.0001)) * sign(UV - vec2(0.5));
	float facing = dot(normalize(edge_dir), normalize(light_dir));
	cel += vec3(0.30) * edge_w * max(facing, 0.0);
	cel *= 1.0 - 0.30 * edge_w * max(-facing, 0.0);

	// Slow diagonal foil glint sweeping the card face (kept neutral/white so
	// the duckflock two-glow-hues restraint rule still holds).
	float sweep = fract(TIME / glint_period);
	float g = (UV.x + UV.y) * 0.5;
	float glint = smoothstep(0.06, 0.0, abs(g - sweep)) * glint_strength;
	cel += vec3(0.45, 0.43, 0.50) * glint * 0.18;

	COLOR.rgb = mix(COLOR.rgb, cel, cel_strength);

	// Inner ink outline hugging the silhouette (manga line art).
	float ink = smoothstep(-outline_width - edge_softness, -outline_width + edge_softness, dist);
	COLOR.rgb = mix(COLOR.rgb, outline_color.rgb, ink * outline_color.a * cel_strength);

	COLOR.a *= mask;
}
