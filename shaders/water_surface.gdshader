shader_type spatial;
render_mode diffuse_lambert, cull_back;

// Agua turbia del Nivel 3. Se lee como agua por cuatro cosas: devuelve la cara de las calaveras
// (espejo roto por el oleaje), deja ver el fondo a los pies y se vuelve espejo a lo lejos
// (Fresnel), lame los muros con una línea clara y se abre en anillos alrededor de quien camina.
// Encima, balsas de cempasúchil a la deriva. La linterna saca destellos del oleaje.
global uniform float world_light;
// Doble realidad: en backrooms el agua se ve como la alfombra empapada (pero sigue sonando).
global uniform float reality;
global uniform float reality_seed;
uniform sampler2D carpet_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tube_color : source_color = vec3(1.0, 0.93, 0.7);
uniform sampler2D petals_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D bed_tex : source_color, filter_linear_mipmap, repeat_enable;
// Pendiente del oleaje (RG, 0,5 = plano) y planta de lo que brilla arriba (RGB) + orilla (A).
uniform sampler2D ripple_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D ceiling_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 map_origin = vec2(0.0);
uniform vec2 map_size = vec2(1.0);
uniform float ceiling_height = 2.9;
uniform float mirror_energy = 2.6;
uniform float ripple_strength : hint_range(0.0, 0.5) = 0.14;
uniform vec3 turbid_color : source_color = vec3(0.1, 0.25, 0.22);
uniform float flower_cover : hint_range(0.0, 1.0) = 0.36;
// xy = posición (XZ) de quien camina, z = cuánto remueve el agua.
uniform vec3 wake = vec3(0.0);
varying vec3 lit;
varying float tube;
varying vec3 world_pos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	lit = COLOR.rgb * reality;
	tube = COLOR.a * (1.0 - reality);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 block = floor(world_pos * 0.85 + 0.013);
	float order = fract(sin(dot(block, vec3(12.9898, 78.233, 37.719)) + reality_seed * 17.0) * 43758.5453);
	if (order > reality * 1.04 - 0.02) {
		vec3 carpet = texture(carpet_tex, world_pos.xz * 0.5).rgb * 0.8;
		ALBEDO = carpet;
		EMISSION = carpet * tube * 2.0 * tube_color * world_light;
		ROUGHNESS = 0.7;
		SPECULAR = 0.2;
	} else {
		vec2 p = world_pos.xz;
		// Dos capas de oleaje que se cruzan, más los anillos que levanta quien camina.
		vec2 slope = texture(ripple_tex, p * 0.19 + TIME * vec2(0.012, 0.02)).rg * 2.0 - 1.0;
		slope += (texture(ripple_tex, p.yx * 0.53 - TIME * vec2(0.031, 0.017)).rg * 2.0 - 1.0) * 0.6;
		slope *= ripple_strength;
		vec2 away = p - wake.xy;
		float reach = length(away);
		float ring = cos(reach * 7.5 - TIME * 6.5) * exp(-reach * 0.75) * smoothstep(0.1, 0.45, reach) * wake.z;
		slope += away / max(reach, 0.001) * ring * 0.42;
		vec3 n = normalize(vec3(-slope.x, 1.0, -slope.y));
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
		float fresnel = mix(0.1, 1.0, pow(1.0 - clamp(dot(n, view_dir), 0.0, 1.0), 3.5));

		// Espejo: el rayo reflejado se sigue hasta la altura de las calaveras.
		vec3 bounce = reflect(-view_dir, n);
		float travel = ceiling_height / max(bounce.y, 0.035);
		vec4 above = texture(ceiling_tex, (p + bounce.xz * travel - map_origin) / map_size);
		vec3 mirror = above.rgb * mirror_energy * (1.0 - smoothstep(26.0, 60.0, travel));
		// Lo que no es calavera es muro mojado: devuelve la luz que hay en el sitio.
		mirror += lit * (0.16 + 0.5 * (1.0 - above.a));
		// Crestas: el lomo de cada onda que mira a la luz se enciende con su color.
		float crest = pow(clamp(0.5 + (slope.x + slope.y) / ripple_strength * 0.42, 0.0, 1.0), 5.0);
		vec3 crests = (lit + vec3(0.003, 0.008, 0.009)) * crest * 0.9;

		// Bajo la superficie: el fondo de limo, desplazado por el oleaje y teñido de turbio.
		vec3 bed = texture(bed_tex, p * 0.31 + slope * 0.5).rgb;
		vec3 under = bed * turbid_color * 3.0;

		// Orilla: una línea clara que respira contra los muros.
		float shore = 1.0 - texture(ceiling_tex, (p - map_origin) / map_size).a;
		float lap = 0.5 + 0.5 * sin(TIME * 1.1 + (p.x + p.y) * 2.3 + slope.x * 30.0);
		float foam = smoothstep(0.55 + 0.3 * lap, 1.0, shore) * 0.55;

		// Balsas de cempasúchil: solo las cabezas de flor, agrupadas, meciéndose con el oleaje.
		vec2 drift = vec2(TIME * 0.011, TIME * 0.006);
		vec3 flowers = texture(petals_tex, p * 0.3 + drift + slope * 0.12).rgb;
		float rafts = smoothstep(1.0 - flower_cover - 0.05, 1.0 - flower_cover + 0.07, noise(p * 0.42 + drift * 2.0));
		float petal = rafts * smoothstep(0.1, 0.2, flowers.r - flowers.b);
		float brightness = dot(lit, vec3(0.3, 0.5, 0.2));

		vec3 water_glow = under * lit * 0.9 * (1.0 - fresnel) + mirror * fresnel + crests + (lit + 0.01) * foam;
		ALBEDO = mix(under * (1.0 - fresnel), flowers * 0.9, petal);
		// Las flores conservan su naranja: reciben la intensidad de la luz, no su color.
		EMISSION = mix(water_glow, flowers * (0.03 + brightness * 1.3), petal) * world_light;
		ROUGHNESS = mix(0.16, 0.95, petal);
		SPECULAR = mix(0.75, 0.1, petal);
		NORMAL = normalize((VIEW_MATRIX * vec4(mix(n, vec3(0.0, 1.0, 0.0), petal), 0.0)).xyz);
	}
}
