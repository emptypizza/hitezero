shader_type canvas_item;

// CEL-03 (cel 2.5D pass, enemy blob — 2026-06-13).
// Gives the falling RED_ENEMY the same subculture cel-shaded read as the card
// blocks WITHOUT the rounded-rect card mask, so the hand-drawn blob silhouette
// (E1.webp) survives intact. The mask deliberately comes from the sprite's own
// alpha, never a UV rectangle — that's the contract the VX-02 / red-enemy
// tests protect. Everything stays red-first: bands MULTIPLY the texture's own
// red, the rim light is warm (never a white wash), and the ink rim is a deep
// maroon. Reads uniform defaults so block.gd can share one material instance.

uniform float cel_strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 shadow_tint = vec3(0.55, 0.12, 0.14);   // deep crimson under-shade
uniform vec3 rim_light = vec3(1.0, 0.62, 0.42);      // warm top rim, not white
uniform vec4 ink_color : source_color = vec4(0.20, 0.02, 0.05, 1.0); // maroon ink
uniform float ink_width : hint_range(0.0, 4.0) = 1.4;  // silhouette outline px
uniform float rim_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.02) {
		COLOR = tex;
	} else {
		vec3 base = tex.rgb;

		// Cel bands: synthetic top light snapped to 3 steps, MULTIPLIED onto
		// the sprite's own colour so the result can only get redder/darker.
		float l = clamp(0.5 - (UV.y - 0.5) * 1.25, 0.0, 1.0);
		float band = clamp(floor(l * 3.0) / 2.0, 0.0, 1.0); // 0.0 / 0.5 / 1.0
		float lum = mix(0.78, 1.08, band);
		vec3 cel = base * lum;

		// Lowest band leans crimson (tinted anime shadow, still red-first).
		float shadow_w = 1.0 - step(0.34, l);
		cel = mix(cel, cel * shadow_tint * 2.0, shadow_w * 0.42);

		// Warm rim light along the upper silhouette edge.
		vec2 px = TEXTURE_PIXEL_SIZE;
		float a_up = texture(TEXTURE, UV - vec2(0.0, px.y * 2.0)).a;
		float top_edge = clamp(tex.a - a_up, 0.0, 1.0);
		cel += rim_light * top_edge * rim_strength;

		COLOR.rgb = mix(base, cel, cel_strength);

		// Inner ink outline: any texel whose neighbourhood pokes outside the
		// silhouette gets the maroon line — manga edge on the blob.
		float a_l = texture(TEXTURE, UV - vec2(px.x * ink_width, 0.0)).a;
		float a_r = texture(TEXTURE, UV + vec2(px.x * ink_width, 0.0)).a;
		float a_d = texture(TEXTURE, UV + vec2(0.0, px.y * ink_width)).a;
		float edge = 1.0 - min(min(a_l, a_r), min(a_up, a_d));
		edge *= step(0.5, tex.a);
		COLOR.rgb = mix(COLOR.rgb, ink_color.rgb, edge * ink_color.a * cel_strength);

		COLOR.a = tex.a;
	}
}
