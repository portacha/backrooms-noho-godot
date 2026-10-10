shader_type spatial;
render_mode cull_disabled;
// Paleta plana compartida: una sola superficie material para todos los huesos y jirones.
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	EMISSION = COLOR.rgb * 0.025;
}
