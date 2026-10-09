shader_type canvas_item;
// Posprocesado por eventos (docs/07): aberración cromática, distorsión, viñeta y fundido.
// El nodo solo es visible mientras algún parámetro es distinto de cero.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float aberration : hint_range(0.0, 1.0) = 0.0;
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 0.0;
// Viñeta + fundido sin leer la pantalla: calidad baja en Android.
uniform bool simple = false;

void fragment() {
	vec2 centered = SCREEN_UV - vec2(0.5);
	float dist = length(centered);
	vec3 color;
	float alpha = 1.0;
	if (simple) {
		color = vec3(0.0);
		alpha = smoothstep(0.35, 0.85, dist) * vignette;
	} else {
		// Ondas radiales que tiran hacia el centro: la pantalla "respira" hacia el cuadro.
		float ripple = sin(dist * 34.0 - TIME * 7.0) * 0.012 * distortion;
		vec2 uv = vec2(0.5) + centered * (1.0 - distortion * 0.22 * (1.0 - dist) + ripple);
		vec2 shift = centered * (0.004 + dist * 0.07) * aberration;
		color.r = texture(screen_tex, uv + shift).r;
		color.g = texture(screen_tex, uv).g;
		color.b = texture(screen_tex, uv - shift).b;
		color *= 1.0 - smoothstep(0.35, 0.85, dist) * vignette;
	}
	COLOR = vec4(mix(color, fade_color.rgb, fade), mix(alpha, 1.0, fade));
}
