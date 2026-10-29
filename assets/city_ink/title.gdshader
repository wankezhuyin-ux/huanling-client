shader_type canvas_item;

// 标题「浮影水城」动态：
//   ① 一道窄光从右往左扫过字面（和光翼的流光同方向，视觉上连成一片）
//   ② 整体极缓的呼吸，避免静止时像贴纸
// 只读原贴图 + 叠加，不破坏笔锋边缘，也不额外占包体。

uniform float sweep_speed = 0.42;                 // 扫光速度（秒的倒数）
uniform float sweep_strength : hint_range(0.0, 2.0) = 0.50;
uniform vec4 sweep_color : source_color = vec4(1.0, 0.91, 0.70, 1.0);
uniform float pulse : hint_range(0.0, 0.5) = 0.05;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);

	// 周期性从右向左的一道窄光
	float head = 1.30 - fract(TIME * sweep_speed) * 1.60;   // 1.30 → -0.30
	float d = (UV.x - head) / 0.115;
	float band = exp(-d * d);
	c.rgb += sweep_color.rgb * band * sweep_strength * c.a;

	// 极缓呼吸（两个周期叠加，看不出规律）
	float br = 1.0 + pulse * (0.6 * sin(TIME * 1.15) + 0.4 * sin(TIME * 1.87 + 0.9));
	c.rgb *= br;

	COLOR = c * tint;
}
