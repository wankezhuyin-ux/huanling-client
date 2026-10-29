shader_type canvas_item;

// 云雾层：一张可平铺的噪声图，按 TIME 横向漂移，纵向做淡入淡出。
// 用来给静态水墨背景「加一层呼吸」，成本 1 个 draw call，手机端无压力。

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 scroll_speed = vec2(0.012, 0.0);   // UV/秒
uniform float density : hint_range(0.0, 1.0) = 0.16;
uniform vec4 tint : source_color = vec4(1.0, 0.99, 0.95, 1.0);
uniform float y_from : hint_range(0.0, 1.0) = 0.05;
uniform float y_to : hint_range(0.0, 1.0) = 0.55;
uniform float fade_soft : hint_range(0.01, 0.5) = 0.22;

void fragment() {
	// 横向拉长 1.6 倍，纵向保持方格感，避免看出重复的圆斑
	vec2 uv = UV * vec2(1.6, 1.0) + scroll_speed * TIME;
	float n = texture(noise_tex, uv).r;
	n = smoothstep(0.46, 0.96, n);

	// 纵向窗口：y_from 淡入、y_to 淡出（雾只出现在该区域）
	float a = smoothstep(y_from, y_from + fade_soft, UV.y)
			* (1.0 - smoothstep(y_to - fade_soft, y_to, UV.y));

	COLOR = vec4(tint.rgb, n * density * a);
}
