shader_type spatial;
render_mode unshaded;
// El cuadro (docs/14 §6): dos composiciones de la misma pintura y brillo animable.

uniform sampler2D painting_tex : source_color, filter_linear_mipmap, repeat_disable;
// 0 = composición A, 1 = composición B (las formas se desplazan; la paleta no cambia).
uniform float variant : hint_range(0.0, 1.0) = 0.0;
uniform float energy = 1.0;
// 0 = color pleno, 1 = sin color (el cuadro del final, docs/11 §9.4).
uniform float drained : hint_range(0.0, 1.0) = 0.0;
// Durante la caída el lienzo se estira en radial (docs/14 §7).
uniform float stretch : hint_range(0.0, 1.0) = 0.0;
global uniform float world_light;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	// Remolino suave: mayor en el borde, nulo en el centro para no deformar el logotipo.
	float angle = variant * 0.5 * smoothstep(0.12, 0.6, dist);
	mat2 swirl = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	vec2 uv = vec2(0.5) + swirl * centered * (1.0 - stretch * 0.6 * dist);
	uv += centered * sin(dist * 20.0 - TIME * 5.0) * 0.03 * stretch;
	vec3 color = texture(painting_tex, uv).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(color, vec3(grey) * 0.6, drained) * energy * max(world_light, 0.2);
}
