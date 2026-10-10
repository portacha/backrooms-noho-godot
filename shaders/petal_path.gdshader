shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

// Sendero de pétalos del Nivel 4 (docs/02, docs/13 §3.2): invisible hasta que la linterna lo
// barre; entonces resplandece cálido y se apaga despacio.
uniform sampler2D petals : source_color, filter_linear_mipmap;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glow_color : source_color = vec3(1.0, 0.62, 0.22);

void fragment() {
	vec4 ink = texture(petals, UV);
	ALBEDO = ink.rgb * glow_color * (0.6 + 1.5 * reveal);
	ALPHA = ink.a * smoothstep(0.0, 0.35, reveal);
}
