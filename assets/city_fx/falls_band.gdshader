shader_type canvas_item;
render_mode blend_add;

// 瀑布流动贴片的「有效带」遮罩。
// 贴着底图真实瀑布（设计坐标 y 556..820）裁一刀：贴片滑出这条带就完全透明，
// 这样滚动动画只会发生在瀑布本体上，不会甩到上面的浮岛和下面的商店街。
//
// band.x = 本片顶边相对带顶的偏移（px），band.y = 本片高度，band.z = 带高度
// 每帧由 city_fx.gd 的 _update_falls() 按贴片实际位置刷新。
uniform vec3 band = vec3(0.0, 264.0, 264.0);
uniform float fade_top = 30.0;     // 带顶淡入（px）：水口处不要突然出现
uniform float fade_bot = 52.0;     // 带底淡出（px）：融进下面的水雾
uniform float fade_side = 0.085;   // 带顶左右收边（UV 比例），水口比底部窄
uniform float side_bottom = 0.018; // 带底左右收边
uniform float strength = 0.30;

void fragment() {
	vec4 c = texture(TEXTURE, UV);

	// 该像素在「带」里的纵向位置（px），跟贴片滑到哪里无关
	float b = band.x + UV.y * band.y;
	float hb = clamp(b / max(band.z, 1.0), 0.0, 1.0);

	float mask = smoothstep(0.0, fade_top, b) * smoothstep(0.0, fade_bot, band.z - b);

	// 上窄下宽的梯形收边：水流从岩缝里出来，越往下越散
	float side = mix(fade_side, side_bottom, hb);
	float ms = smoothstep(0.0, side, UV.x) * smoothstep(0.0, side, 1.0 - UV.x);

	COLOR = vec4(c.rgb, c.a * mask * ms * strength);
}
