shader_type canvas_item;

// 悬空岛「浮动」：不再在底图上叠一张同位置的矩形贴片（那样贴片边缘必然是
// 一道横向/纵向断层，用户截图里看到的就是它），改成直接在底图上做局部位移：
// 椭圆形软掩码内整块内容上下漂移，掩码边缘平滑过渡，画面里不会出现任何硬边。
//
// 坐标全部用底图 UV（1024×2000），位移幅度按「设计像素 / 2000」折算。

uniform vec2 isle_uv[3];    // 岛中心（UV）
uniform vec2 isle_rh[3];    // 掩码半宽 / 半高（UV）
uniform float isle_amp[3];  // 位移幅度（UV）
uniform float isle_sp[3];   // 角速度
uniform float isle_ph[3];   // 相位
uniform float edge_soft : hint_range(0.05, 0.9) = 0.42;

// 石龙身边那团雾：底图上的云气是画死的，给它一层极缓的涡流位移就会「飘」起来。
// 幅度只有 2~3 像素（0.0016 UV ≈ 3.2 像素），掩码边缘完全平滑，看不出任何形变。
uniform vec2 mist_uv = vec2(0.195, 0.430);
uniform vec2 mist_rh = vec2(0.340, 0.200);
uniform float mist_amp = 0.0016;

void fragment() {
	vec2 uv = UV;
	for (int i = 0; i < 3; i++) {
		vec2 d = (uv - isle_uv[i]) / isle_rh[i];
		float r = length(d);
		float m = 1.0 - smoothstep(1.0 - edge_soft, 1.0, r);
		if (m <= 0.001) {
			continue;
		}
		// -1(上) .. +1(下)：越往下摆幅略大，岛底/垂枝比岛顶的亭子晃得多一点
		float low = clamp((uv.y - isle_uv[i].y) / isle_rh[i].y, -1.0, 1.0);
		float w = mix(0.82, 1.16, (low + 1.0) * 0.5);
		float wob = sin(TIME * isle_sp[i] + isle_ph[i]);
		uv.y -= isle_amp[i] * wob * m * w;
		// 垂枝横向轻摆：只在岛体下半部生效，幅度极小（0.9/1000 UV ≈ 1.8 像素）
		float vw = smoothstep(0.15, 0.95, (low + 1.0) * 0.5) * m;
		uv.x += sin(TIME * 0.9 + isle_ph[i] + low * 5.0) * 0.0009 * vw;
	}

	// 雾：缓涡流。两个方向的波长都取得很长（几十个像素），只做「漂」不做「扭」
	vec2 dm = (uv - mist_uv) / mist_rh;
	float rm = length(dm);
	float mm = 1.0 - smoothstep(0.45, 1.0, rm);
	if (mm > 0.001) {
		uv.x += sin(TIME * 0.33 + uv.y * 26.0) * mist_amp * mm;
		uv.y += cos(TIME * 0.21 + uv.x * 17.0) * mist_amp * 0.62 * mm;
	}
	COLOR = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
}
