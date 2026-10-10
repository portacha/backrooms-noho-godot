shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha, fog_disabled;
// Un material para senderos y objetos móviles; compatible con WebGL 2 sin instance uniforms.
uniform sampler2D petals : source_color;
uniform float path_reveals[128];
uniform float candles = 0.0;
uniform float emergency = 0.0;
varying float distance_view;
void vertex() {
	distance_view = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}
void fragment() {
	float kind = UV2.x;
	vec3 color = COLOR.rgb;
	float alpha = 1.0;
	float energy = UV2.y;
	if (kind < 0.5) {
		vec4 ink = texture(petals, UV);
		float reveal = path_reveals[int(UV2.y)];
		color = ink.rgb;
		alpha = ink.a * reveal;
		energy = 1.4 * reveal;
	} else if (kind < 2.5 && kind > 1.5) {
		energy = candles > UV2.y ? 2.5 : 0.0;
	} else if (kind < 3.5 && kind > 2.5) {
		color = vec3(1.0, 0.005, 0.015);
		energy = emergency * 3.0;
	}
	vec3 fog = mix(vec3(0.014, 0.017, 0.027), vec3(0.09, 0.008, 0.015), emergency);
	vec3 lit = color * energy;
	// El neón de la puerta es el único objeto que atraviesa toda la niebla.
	if (kind < 3.5 || kind > 4.5) {
		lit = mix(fog, lit, exp(-distance_view * 0.025));
	}
	ALBEDO = lit;
	ALPHA = alpha;
}
