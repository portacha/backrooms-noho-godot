shader_type spatial;
render_mode unshaded, cull_disabled, world_vertex_coords;

// Pétalos de cempasúchil que suben desde el abismo (Nivel 4). Cada instancia es un pétalo con
// forma que gira sobre su propio eje y deriva; todo ocurre aquí, sin coste por fotograma en CPU.
// La nube acompaña a la cámara: los pétalos que salen de la caja reaparecen por el lado opuesto,
// encogidos a nada en el borde para que nunca salten.
uniform vec3 extent = vec3(24.0, 10.0, 24.0);
uniform vec3 base_color : source_color = vec3(0.86, 0.3, 0.03);
uniform vec3 tip_color : source_color = vec3(1.0, 0.68, 0.14);
varying float shade;
varying float along;

void vertex() {
	vec4 seed = INSTANCE_CUSTOM;
	vec3 home = MODEL_MATRIX[3].xyz;
	vec3 local = VERTEX - home;
	along = UV.y;
	vec3 centre = home;
	centre.y += TIME * (0.1 + 0.32 * seed.x);
	centre.x += sin(TIME * (0.21 + 0.2 * seed.z) + seed.y * 6.283) * (0.5 + seed.w) + TIME * 0.06;
	centre.z += cos(TIME * (0.17 + 0.2 * seed.x) + seed.z * 6.283) * (0.5 + seed.y);
	vec3 offset = mod(centre - CAMERA_POSITION_WORLD + extent, 2.0 * extent) - extent;
	vec3 edge = abs(offset) / extent;
	float size = (0.7 + 1.1 * seed.w) * (1.0 - smoothstep(0.82, 1.0, max(edge.x, max(edge.y, edge.z))));
	// Giro de Rodrigues en torno a un eje propio, con un cabeceo lento encima.
	vec3 axis = normalize(seed.xyz * 2.0 - 1.0 + vec3(0.001, 0.002, 0.003));
	float angle = TIME * (0.5 + 2.2 * seed.y) + seed.x * 40.0 + 0.6 * sin(TIME * 0.9 + seed.w * 20.0);
	float c = cos(angle);
	float s = sin(angle);
	vec3 turned = local * c + cross(axis, local) * s + axis * dot(axis, local) * (1.0 - c);
	vec3 normal = NORMAL * c + cross(axis, NORMAL) * s + axis * dot(axis, NORMAL) * (1.0 - c);
	VERTEX = CAMERA_POSITION_WORLD + offset + turned * size;
	NORMAL = normal;
	// De canto se oscurece, de cara brilla: el aleteo se lee aunque el pétalo sea diminuto.
	shade = 0.45 + 0.55 * abs(dot(normal, normalize(CAMERA_POSITION_WORLD - VERTEX)));
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, along) * shade;
}
