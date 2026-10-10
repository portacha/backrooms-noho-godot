shader_type spatial;
render_mode unshaded;

uniform vec3 panel_color : source_color = vec3(1.0);
uniform float energy = 1.0;
uniform bool flicker = false;
// Doble realidad: los fluorescentes son de backrooms; en lo real están muertos.
uniform bool dual = false;
global uniform float reality;
global uniform float world_light;
global uniform float flicker_seed;
// < 0: parpadeo propio de cada tubo; >= 0: nivel que dicta el guion del nivel (prólogo).
global uniform float flicker_override;
varying vec4 panel_data;
varying float baked_energy;

// Idéntico en ambos shaders: apagones breves y tartamudeo irregular.
float flick_hash(float x) { return fract(sin(x * 127.1 + flicker_seed * 311.7) * 43758.5453); }
float flick(float t) {
	if (flicker_override >= 0.0) { return flicker_override; }
	float block = flick_hash(floor(t * 3.0));
	float fast = flick_hash(floor(t * 37.0));
	float blackout = flick_hash(floor(t * 11.0));
	if (blackout < 0.025) { return 0.0; }
	if (block < 0.14) { return step(0.43, fast); }
	return 0.94 + 0.06 * fast;
}
void vertex() { panel_data = COLOR; baked_energy = UV2.x; }
void fragment() {
	// El color y la energía por panel permiten agruparlos en dos superficies.
	// Estrías del difusor prismático, suavizadas a distancia para evitar moiré.
	vec2 ribs = UV * vec2(118.0, 58.0);
	vec2 visibility = vec2(1.0) - smoothstep(vec2(0.3), vec2(1.0), fwidth(ribs));
	vec2 pattern = cos(ribs * 6.2831853) * visibility;
	float diffuser = 0.94 + 0.03 * (pattern.x + pattern.y);
	ALBEDO = panel_color * energy * panel_data.rgb * baked_energy * diffuser * world_light * (flicker ? flick(TIME) : 1.0) * (dual ? mix(1.0, 0.14, reality) : 1.0);
}
