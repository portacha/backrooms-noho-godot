shader_type spatial;
render_mode cull_disabled;
uniform bool use_texture = false;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
// Paleta plana compartida: una sola superficie material para todos los huesos y jirones.
void fragment() {
	vec3 color = use_texture ? texture(albedo_texture, UV).rgb : COLOR.rgb;
	if (use_texture && max(max(color.r, color.g), color.b) < 0.012) {
		color = vec3(0.0);
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
	EMISSION = color * 0.025;
}
