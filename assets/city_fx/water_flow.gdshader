shader_type canvas_item;
render_mode blend_add;

// 水面波光：横向缓慢流动 + 轻微纵向起伏。
// 贴图本身不是左右可平铺的（首尾列色差 0.42），直接 fract 会在接缝处跳一条竖线，
// 所以用「镜像平铺」——把滚动坐标折成三角波，接缝处方向反转但像素连续，看不出来。
uniform float speed = 0.055;    // 每秒滚过多少个贴图宽度
uniform float phase = 0.0;
uniform float strength = 0.17;
uniform float edge = 0.12;      // 左右收边（UV 比例）
uniform float top_fade = 0.24;  // 上下淡出（UV 比例）
uniform float bot_fade = 0.30;
uniform float ripple = 0.010;   // 纵向起伏幅度（打散波纹，看起来不是一张死图）

void fragment() {
	float s = UV.x + TIME * speed + phase;
	float u = abs(fract(s * 0.5) * 2.0 - 1.0);          // 镜像平铺
	float v = UV.y + sin(UV.x * 6.2831 + TIME * 0.33) * ripple;
	vec4 c = texture(TEXTURE, vec2(u, clamp(v, 0.0, 1.0)));

	float mask = smoothstep(0.0, edge, UV.x) * smoothstep(0.0, edge, 1.0 - UV.x)
		* smoothstep(0.0, top_fade, UV.y) * smoothstep(0.0, bot_fade, 1.0 - UV.y);

	COLOR = vec4(c.rgb, c.a * mask * strength);
}
