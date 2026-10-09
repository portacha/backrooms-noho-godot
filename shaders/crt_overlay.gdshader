shader_type canvas_item;
// Cristal de monitor viejo sobre el bloc de notas: líneas de barrido, viñeta de tubo,
// banda que recorre la pantalla y parpadeo leve. No lee la pantalla: es una capa encima.

uniform vec3 phosphor : source_color = vec3(0.55, 0.9, 1.0);
uniform float lines = 270.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float scan = 0.5 + 0.5 * sin(UV.y * lines * 6.28318);
	float tube = smoothstep(0.38, 0.74, length(centered * vec2(1.0, 1.15)));
	float band = 1.0 - smoothstep(0.0, 0.07, abs(fract(UV.y - TIME * 0.09) - 0.5));
	float flicker = 0.015 * sin(TIME * 47.0);
	float dark = clamp(scan * 0.2 + tube * 0.7 + flicker, 0.0, 1.0);
	float glow = band * 0.05;
	COLOR = vec4(phosphor * glow / max(dark + glow, 0.001), dark + glow);
}
