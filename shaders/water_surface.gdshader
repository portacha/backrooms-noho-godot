shader_type spatial;
render_mode diffuse_lambert;

// Agua opaca; el mismo shader comparte concreto y limo sin otra superficie.
global uniform float world_light;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D floor_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D metal_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D clay_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D palette_tex : source_color, filter_nearest, repeat_disable, hint_default_white;
uniform bool architecture = false;
varying vec3 baked;
varying vec3 world_pos;
varying float floor_face;
varying float surface_kind;

void vertex() {
	baked = COLOR.rgb;
	surface_kind = UV2.x;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	floor_face = step(0.7, NORMAL.y);
}

void fragment() {
	vec3 base;
	if (architecture) {
		base = mix(texture(albedo_tex, UV).rgb, texture(floor_tex, UV).rgb, floor_face);
		if (surface_kind > 0.5 && surface_kind < 1.5) { base = texture(metal_tex, UV).rgb; }
		if (surface_kind > 1.5 && surface_kind < 2.5) { base = texture(clay_tex, UV).rgb; }
		if (surface_kind > 2.5 && surface_kind < 3.5) { base = texture(palette_tex, UV).rgb; }
		ALBEDO = base;
		EMISSION = base * baked * 2.0 * world_light;
		if (surface_kind > 3.5 && surface_kind < 4.5) {
			ALBEDO = vec3(0.0);
			EMISSION = vec3(0.32, 0.76, 0.8) * 0.65 * world_light;
		}
		if (surface_kind > 4.5) {
			ALBEDO = baked;
			float energy = surface_kind > 6.5 ? 0.025 : (surface_kind > 5.5 ? 2.6 : 0.15);
			EMISSION = baked * energy * world_light;
		}
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else {
		vec2 drift = world_pos.xz * 0.32 + vec2(TIME * 0.007, TIME * 0.004);
		base = texture(albedo_tex, drift).rgb;
		float ripple = 0.9 + 0.1 * sin(world_pos.z * 9.0 + TIME * 0.8);
		ALBEDO = base * 0.65;
		EMISSION = (base * 0.11 + vec3(0.009, 0.026, 0.028) * ripple) * world_light;
		ROUGHNESS = 0.35;
		SPECULAR = 0.3;
	}
}
