shader_type spatial;
render_mode diffuse_lambert, cull_back;

// Agua turbia del Nivel 3: negra y lisa, refleja la luz de las calaveras (horneada en los
// vértices por el nivel) y lleva manchas de cempasúchil a la deriva. La linterna la ilumina.
global uniform float world_light;
uniform sampler2D petals_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 deep_color : source_color = vec3(0.004, 0.011, 0.013);
uniform float flower_cover : hint_range(0.0, 1.0) = 0.5;
varying vec3 lit;
varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lit = COLOR.rgb;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 drift = vec2(TIME * 0.011, TIME * 0.006);
	vec3 flowers = texture(petals_tex, world_pos.xz * 0.24 + drift).rgb;
	// Las flores se agrupan en balsas; entre ellas queda agua negra que refleja.
	float rafts = smoothstep(1.0 - flower_cover - 0.08, 1.0 - flower_cover + 0.1, noise(world_pos.xz * 0.33 + drift * 2.0));
	float petal = rafts * smoothstep(0.06, 0.22, flowers.r - flowers.b);
	// Reflejo roto por la ondulación: destellos finos que tiemblan bajo cada calavera.
	float slow = noise(world_pos.xz * vec2(2.3, 0.9) + vec2(TIME * 0.21, TIME * 0.13));
	float fine = noise(world_pos.xz * vec2(9.0, 3.4) - vec2(TIME * 0.34, TIME * 0.27));
	float shimmer = slow * slow * (0.4 + 1.6 * fine * fine);
	vec3 reflection = lit * (0.05 + shimmer * 0.55);
	float brightness = dot(lit, vec3(0.3, 0.5, 0.2));
	ALBEDO = mix(deep_color, flowers * 0.85, petal);
	// Las flores conservan su naranja: reciben la intensidad de la luz, no su color.
	EMISSION = mix(deep_color + reflection, flowers * (0.035 + brightness * 1.25), petal) * world_light;
	ROUGHNESS = mix(0.08, 0.95, petal);
	SPECULAR = mix(0.6, 0.1, petal);
}
