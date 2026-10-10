shader_type spatial;
render_mode diffuse_lambert;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform vec4 tint : source_color = vec4(1.0);
uniform float texture_saturation : hint_range(0.0, 1.0) = 1.0;
uniform vec3 flicker_color : source_color = vec3(1.0, 0.9, 0.72);
uniform float emission_boost = 1.0;
uniform float unlit_energy = -1.0;
// Compensa texturas oscuras al teñirlas con `tint` (p. ej. alfombra en grises × azul).
uniform float texture_gain = 1.0;
// Doble realidad (docs/15): la misma pared tiene dos pieles. `alt_tex` es la de backrooms —lo que
// la mente del oficinista pone para soportar lo que ve— y `albedo_tex` la real. El global
// `reality` (0 = backrooms, 1 = real) decide cuál se ve; a medio camino, a parches que saltan.
uniform bool dual = false;
uniform sampler2D alt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform vec4 alt_tint : source_color = vec4(1.0);
uniform float alt_uv = 1.0;
// Materiales emisivos: 1 = solo brillan en lo real, -1 = solo en backrooms, 0 = siempre.
uniform float emissive_side = 0.0;
global uniform float reality;
global uniform float reality_seed;
global uniform float world_light;
global uniform float flicker_seed;
// < 0: parpadeo propio de cada tubo; >= 0: nivel que dicta el guion del nivel (prólogo).
global uniform float flicker_override;
varying vec4 baked_color;
varying vec3 world_pos;

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

void vertex() {
	// COLOR es dato lineal normalizado; sin source_color ni conversión sRGB.
	baked_color = COLOR;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 texel = texture(albedo_tex, UV).rgb;
	float luminance = dot(texel, vec3(0.2126, 0.7152, 0.0722));
	vec3 base = mix(vec3(luminance), texel, texture_saturation) * texture_gain * tint.rgb;
	float real_light = 1.0;
	float back_light = 1.0;
	if (dual) {
		// Parches de ~1 m que cambian de piel a destiempo: la alucinación no es limpia.
		vec3 block = floor(world_pos * 0.85 + 0.013);
		float order = fract(sin(dot(block, vec3(12.9898, 78.233, 37.719)) + reality_seed * 17.0) * 43758.5453);
		float real = step(order, reality * 1.04 - 0.02);
		base = mix(texture(alt_tex, UV * alt_uv).rgb * alt_tint.rgb, base, real);
		real_light = reality;
		back_light = 1.0 - reality;
	}
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (unlit_energy >= 0.0) {
		float side = emissive_side > 0.5 ? real_light : (emissive_side < -0.5 ? back_light : 1.0);
		ALBEDO = vec3(0.0);
		EMISSION = base * unlit_energy * world_light * (dual ? side : 1.0);
	} else {
		ALBEDO = base;
		EMISSION = ALBEDO * (baked_color.rgb * 2.0 * real_light + baked_color.a * 2.0 * flicker_color * flick(TIME) * back_light) * world_light * emission_boost;
	}
}
