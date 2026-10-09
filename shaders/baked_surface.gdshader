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
global uniform float world_light;
global uniform float flicker_seed;
// < 0: parpadeo propio de cada tubo; >= 0: nivel que dicta el guion del nivel (prólogo).
global uniform float flicker_override;
varying vec4 baked_color;

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
}
void fragment() {
	vec3 texel = texture(albedo_tex, UV).rgb;
	float luminance = dot(texel, vec3(0.2126, 0.7152, 0.0722));
	vec3 base = mix(vec3(luminance), texel, texture_saturation) * texture_gain * tint.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (unlit_energy >= 0.0) {
		ALBEDO = vec3(0.0);
		EMISSION = base * unlit_energy * world_light;
	} else {
		ALBEDO = base;
		EMISSION = ALBEDO * (baked_color.rgb * 2.0 + baked_color.a * 2.0 * flicker_color * flick(TIME)) * world_light * emission_boost;
	}
}
