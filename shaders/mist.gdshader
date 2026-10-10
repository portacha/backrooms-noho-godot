shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert, specular_disabled, shadows_disabled;

// Jirones de bruma de la dimensión oscura: láminas que miran a cámara y derivan despacio. No
// llevan luz propia más allá de un resto del color de la niebla; la linterna es la que las
// enciende, y así el haz se ve en el aire. En doble realidad solo existen en lo real.
global uniform float world_light;
global uniform float reality;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.05, 0.05, 0.05);
uniform float density : hint_range(0.0, 1.0) = 0.3;
uniform float reach = 15.0;
// 1 = la bruma sigue a `reality`; 0 = siempre presente (niveles sin doble realidad).
uniform float dual = 1.0;
uniform float rise = 1.4;
uniform float ceiling_at = 3.2;
varying float fade;
varying float seed;
varying float height;

void vertex() {
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	vec3 centre = MODEL_MATRIX[3].xyz;
	float distance_to_eye = distance(centre, CAMERA_POSITION_WORLD);
	// Se desvanece antes de tocar la cámara y antes del borde donde se recoloca: nunca salta.
	fade = smoothstep(1.2, 4.0, distance_to_eye) * (1.0 - smoothstep(reach * 0.6, reach, distance_to_eye));
	// Los jirones se colocan a `rise` del suelo: se deshacen antes de cortarse contra él o el techo.
	height = rise + INV_VIEW_MATRIX[0].y * VERTEX.x + INV_VIEW_MATRIX[1].y * VERTEX.y;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float edge = 1.0 - smoothstep(0.12, 0.5, length(UV - 0.5));
	float slow = texture(noise_tex, UV * 0.55 + seed * 7.0 + TIME * vec2(0.011, 0.003)).r;
	float fine = texture(noise_tex, UV * 1.25 + seed * 3.0 - TIME * vec2(0.007, 0.005)).r;
	float body = smoothstep(0.2, 0.75, slow * 0.65 + fine * 0.35);
	ALBEDO = vec3(0.5) + tint;
	EMISSION = tint * world_light;
	float room = smoothstep(0.02, 0.9, height) * (1.0 - smoothstep(ceiling_at - 0.8, ceiling_at, height));
	ALPHA = room * edge * body * density * fade * mix(1.0, reality, dual) * world_light;
}
