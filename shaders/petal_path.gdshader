shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

// Sendero de pétalos del Nivel 4 (docs/02, docs/13 §3.2): invisible hasta que la linterna lo
// barre; entonces resplandece cálido y se apaga despacio. Es una cinta continua que dobla con el
// puente: `UV` recorre la textura a lo largo y `UV2.x` es la posición (0–1) en la memoria de luz.
uniform sampler2D petals : source_color, filter_linear_mipmap, repeat_enable;
// Memoria de lo ya alumbrado, una muestra cada medio metro; el filtro lineal la funde.
uniform sampler2D reveal_tex : filter_linear, repeat_disable;
uniform vec3 glow_color : source_color = vec3(1.0, 0.62, 0.22);
// El haz en este instante: lo que revela es el círculo de luz, no un tramo entero.
uniform vec3 beam_origin;
uniform vec3 beam_direction = vec3(0.0, 0.0, -1.0);
uniform float beam_cos = 0.97;
uniform float beam_range = 30.0;
uniform float beam_on = 0.0;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 ink = texture(petals, UV);
	vec3 to_point = world_pos - beam_origin;
	float distance_to_beam = length(to_point);
	float cone = smoothstep(beam_cos - 0.012, beam_cos + 0.012, dot(to_point / max(distance_to_beam, 0.001), beam_direction));
	float beam = beam_on * cone * (1.0 - smoothstep(beam_range * 0.75, beam_range, distance_to_beam));
	float reveal = max(texture(reveal_tex, vec2(UV2.x, 0.5)).r, beam);
	// Cada pétalo se enciende a su tiempo: el borde de lo revelado es un salpicado, no una raya.
	float order = texture(petals, UV * 3.7 + vec2(0.31, 0.17)).g;
	float lit = smoothstep(order * 0.45, order * 0.45 + 0.3, reveal);
	// Los extremos de la cinta se deshacen en pétalos sueltos.
	float ends = smoothstep(0.0, 0.03, UV2.x) * (1.0 - smoothstep(0.97, 1.0, UV2.x));
	ALBEDO = ink.rgb * glow_color * (0.55 + 1.2 * reveal);
	ALPHA = ink.a * lit * mix(order, 1.0, ends);
}
