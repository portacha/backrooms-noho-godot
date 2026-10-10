shader_type spatial;
render_mode diffuse_lambert;

// Elementos principales con textura propia (Meshy). No pasan por el horneado: reciben las cuatro
// luces horneadas más fuertes de su sitio (las calcula el nivel al instanciarlos) y la linterna.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 light_pos[4];
uniform vec3 light_col[4];
uniform float light_rad[4];
// Luz de los tubos de backrooms en su sitio (solo cuenta con reality baja).
uniform vec3 tube_light = vec3(0.0);
uniform vec3 ambient = vec3(0.0);
uniform float self_light = 0.0;
// Las zonas cian puro de la textura son fosforescentes (calaveras del Nivel 3).
uniform float glow_energy = 0.0;
uniform vec3 glow_color : source_color = vec3(0.28, 0.82, 0.9);
uniform float gain = 1.0;
uniform bool dual = false;
global uniform float world_light;
global uniform float reality;
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb * gain;
	vec3 lit = ambient;
	for (int i = 0; i < 4; i++) {
		vec3 to_light = light_pos[i] - world_pos;
		float distance_to = length(to_light);
		float falloff = max(0.0, 1.0 - distance_to / max(light_rad[i], 0.01));
		float facing = max(dot(world_normal, to_light / max(distance_to, 0.001)), 0.0) * 0.8 + 0.2;
		lit += light_col[i] * falloff * falloff * facing;
	}
	float real = dual ? reality : 1.0;
	float tubes = dual ? 1.0 - reality * 0.9 : 0.0;
	float phosphor = smoothstep(0.3, 0.55, min(base.g, base.b) - base.r);
	ALBEDO = base;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	EMISSION = (base * (lit * 2.0 * real + tube_light * 2.0 * tubes) + glow_color * phosphor * glow_energy * real + base * self_light * real) * world_light;
}
