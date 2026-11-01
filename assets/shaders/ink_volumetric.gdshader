// 3D 水墨体积感着色器
//
// 平面插画像纸片，是因为它有颜色、没有**体块**。这里用三样东西造体块：
//   1. 烘焙体积图（tools/bake_volume_maps.py）：轮廓距离场软饱和成「充气」高度场，
//      粗的地方鼓到 1、细胳膊细腿自成一根圆管 —— 跟画面内容无关，是真几何；
//   2. 局部明暗锐化（clarity）：源图是手绘的，肚子、脸颊、腿缝里本来就有明暗，
//      只是 256px 一缩放就糊成一片灰。这里估出「低频亮度」再往反方向推，
//      手绘的体块立刻咬出棱来，而且不动色相 —— 这是最能去纸片感的一步；
//   3. 棚拍打光：主光（左上）+ 轮廓光 + 窄高光 + 空腔遮蔽 + 墨线勾边。
//
// 混合方式用「线性光」而不是简单相乘：
//   lit < 1 走 multiply（压暗，但不糊色），lit > 1 走 screen（提亮，但不炸白）。
//   白毛这类高亮度区域才有明暗层次，不会一片死白或一片发灰。
//
// ⚠ Godot 4 canvas_item 两个坑：
//   · fragment 的 COLOR 进来时已乘过贴图（COLOR = 贴图 × modulate），只乘增益，
//     绝不能再乘一次 texture（否则贴图平方，整张图暗一半）。
//   · 加光（轮廓光/高光/自发光）必须乘覆盖率 cov：轮廓外那圈 alpha≈0.05 的像素
//     rgb 是黑的，直接加光就会在剪影外描出一圈白晕 —— 纸片感有一半是这么来的。
shader_type canvas_item;

// —— 体积图 ——
uniform sampler2D volume_tex : filter_linear, repeat_disable;
uniform float use_volume : hint_range(0.0, 1.0) = 1.0;    // 没有烘焙图时退回明度近似
uniform float relief : hint_range(0.0, 12.0) = 6.0;       // 起伏强度
// 法线取样步长（归一化 UV）：必须够大才能吃到「整个体块」的曲率。
// 太小只会在轮廓附近起反应，画内部还是平的。
uniform float grad_step : hint_range(0.004, 0.10) = 0.030;
uniform float volume_gain : hint_range(0.5, 2.0) = 1.0;
uniform float volume_bias : hint_range(-1.0, 1.0) = 0.0;

// —— 局部明暗锐化 ——
uniform float clarity : hint_range(0.0, 3.0) = 0.15;      // 0 = 关（回到旧的糊平效果）
uniform float clarity_radius : hint_range(0.5, 4.0) = 1.55; // 低频半径 = grad_step 的倍数

// —— 主光 ——
uniform vec3 key_dir = vec3(-0.55, -0.62, 0.56);          // 左上偏前（屏幕坐标：y 向下）
uniform vec3 key_color : source_color = vec3(1.05, 1.01, 0.95);
uniform vec3 shade_color : source_color = vec3(0.80, 0.86, 1.03);
uniform float shade_gain : hint_range(0.4, 3.0) = 1.15;    // 明暗对比强度（幂律指数）
uniform float key_neutral : hint_range(0.2, 0.9) = 0.562;  // 受光量的中性点，增益为 1 的位置
uniform float tint_strength : hint_range(0.0, 1.0) = 0.25; // 色温分离（暗冷亮暖）的幅度

// —— 边缘光 ——
uniform vec3 rim_dir = vec3(0.55, -0.55, 0.63);           // 左上方偏后（跟主光同侧但更靠轮廓）
uniform vec3 rim_color : source_color = vec3(1.0, 0.97, 0.90);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.12;

// —— 高光 / 自发光 ——
uniform float spec_strength : hint_range(0.0, 1.0) = 0.30;
uniform float spec_power : hint_range(4.0, 128.0) = 36.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.18;

// —— 空腔 / 勾边 ——
uniform float ao_strength : hint_range(0.0, 1.5) = 0.30;
uniform float ink_line : hint_range(0.0, 1.0) = 0.45;     // 轮廓墨线浓度（勾线）
uniform float ink_crevice : hint_range(0.0, 1.0) = 0.18;  // 沟边积墨：凹处往墨里沉
uniform float ink_bleed : hint_range(0.0, 1.0) = 0.0;   // 轮廓外墨晕（宣纸洇开的一圈淡墨）
uniform vec3 ink_tint : source_color = vec3(0.14, 0.12, 0.13);
// 曝光：环境光遮蔽、墨线、暗部色偏都是「只压不提」，叠起来整只怪会发闷。
// 整体提一档补回来，让它跟原图一个亮度，只是明暗拉开了。
uniform float exposure : hint_range(0.7, 1.5) = 1.07;

// —— 轮廓外投影 ——
uniform vec2 shadow_uv = vec2(-0.014, -0.013);
// 默认关掉：战斗里的接地阴影由 FootShadow 节点负责，shader 再打一层会变成贴纸。
uniform float shadow_alpha : hint_range(0.0, 1.0) = 0.0;

// —— 顶点轻摆 ——
uniform float sway_pixels : hint_range(0.0, 8.0) = 2.0;

// —— 调参探针（正式运行保持 0）——
// 1 = 输出受光量 key，2 = 输出体积高度 h_c，3 = 输出局部明暗锐化的 detail。
// 用来量 key 的中位数：中性点必须等于它，整张图的平均亮度才守恒。
uniform int probe_mode = 0;

float _lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// 高度：有烘焙图就用距离场（真体积），没有就退回明度（只能勾轮廓）
float _height(vec2 uv, vec4 col) {
	if (use_volume > 0.5) {
		return clamp(texture(volume_tex, uv).r * volume_gain + volume_bias, 0.0, 1.0);
	}
	return _lum(col.rgb) * col.a;
}

void vertex() {
	// 上身随风轻摆：UV.y=0 头顶摆得最多，UV.y=1 脚底钉住。
	float weight = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.7 + VERTEX.x * 0.02) * sway_pixels * weight * weight;
}

void fragment() {
	float a = COLOR.a;
	if (a < 0.004) {
		// 轮廓外：墨晕 + 沿光方向的投影。
		// 墨晕 = 轮廓外 2~3px 的一圈淡墨，像宣纸吃进墨汁那样洇开一圈 ——
		// 这是水墨最认得出「笔触」的地方，也是把平涂立绘「钉」在纸上的关键。
		vec2 buv = vec2(0.0042, 0.0042);
		float cov_b = texture(TEXTURE, UV + vec2(buv.x, 0.0)).a * 0.25
			+ texture(TEXTURE, UV - vec2(buv.x, 0.0)).a * 0.25
			+ texture(TEXTURE, UV + vec2(0.0, buv.y)).a * 0.25
			+ texture(TEXTURE, UV - vec2(0.0, buv.y)).a * 0.25;
		float bleed = smoothstep(0.04, 0.55, cov_b) * ink_bleed;

		// 沿光的方向落一道墨色投影，纸片因此有了厚度。
		// 只做「压暗」，不按源图明度反算 —— 否则在深色背景上会亮成一圈灰边。
		// 五点采样 = 糊一下影子边缘，否则会变成一张硬邦邦的剪影贴纸。
		vec2 suv = UV + shadow_uv;
		vec2 px = vec2(0.0075, 0.0075);
		float cov_s = texture(TEXTURE, suv).a * 0.36
			+ texture(TEXTURE, suv + vec2(px.x, 0.0)).a * 0.14
			+ texture(TEXTURE, suv - vec2(px.x, 0.0)).a * 0.14
			+ texture(TEXTURE, suv + vec2(0.0, px.y)).a * 0.14
			+ texture(TEXTURE, suv - vec2(0.0, px.y)).a * 0.14
			+ texture(TEXTURE, suv + px).a * 0.04
			+ texture(TEXTURE, suv - px).a * 0.04;
		float sh = smoothstep(0.06, 0.62, cov_s) * shadow_alpha;
		COLOR = vec4(ink_tint.rgb, max(bleed, sh));
	} else {
		vec4 here = texture(TEXTURE, UV);
		vec3 base = COLOR.rgb;
		float lum = _lum(base);

		// —— 体积场的十字采样（法线 + 空腔共用，省一半取样）——
		vec2 gs = vec2(grad_step, grad_step);
		float h_c = _height(UV, here);
		float h_l = _height(UV - vec2(gs.x, 0.0), here);
		float h_r = _height(UV + vec2(gs.x, 0.0), here);
		float h_t = _height(UV - vec2(0.0, gs.y), here);
		float h_b = _height(UV + vec2(0.0, gs.y), here);

		// —— 局部明暗锐化：把「糊掉的手绘体块」重新推出对比 ——
		// 低频用 alpha 加权，邻居都空（贴边）时退回自身，免得边缘被无端提亮。
		vec2 cs = gs * clarity_radius;
		vec4 s_l = texture(TEXTURE, UV - vec2(cs.x, 0.0));
		vec4 s_r = texture(TEXTURE, UV + vec2(cs.x, 0.0));
		vec4 s_t = texture(TEXTURE, UV - vec2(0.0, cs.y));
		vec4 s_b = texture(TEXTURE, UV + vec2(0.0, cs.y));
		float wsum = s_l.a + s_r.a + s_t.a + s_b.a;
		float bsum = _lum(s_l.rgb) * s_l.a + _lum(s_r.rgb) * s_r.a
			+ _lum(s_t.rgb) * s_t.a + _lum(s_b.rgb) * s_b.a;
		float blur = bsum / max(wsum, 0.0001);
		blur = mix(lum, blur, clamp(wsum * 0.25, 0.0, 1.0));
		float detail = clamp(lum - blur, -0.45, 0.45);
		// 必须夹回 [0,1]：白色通道乘 1.24 就过了 1，后面 1-v 变负数，
		// pow(负数, 小数) 在 GPU 上是 NaN，画面上就是一块死黑。
		base = clamp(base * (1.0 + detail * clarity), vec3(0.0), vec3(1.0));

		// 伪法线：屏幕 y 向下，所以上半侧取负
		vec3 n = normalize(vec3((h_l - h_r) * relief, (h_t - h_b) * relief, 1.0));

		// —— 主光：wrap 半兰伯特，指数抬高让明暗交界更明确（糊着就没有体积）——
		vec3 L = normalize(key_dir);
		float diff = pow(clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0), 1.35);

		// 球面衰减：越靠近体块中心越亮、贴边自然暗 —— 宽扁形状内部也才鼓得起来
		float dome = smoothstep(0.05, 0.92, h_c);

		// 受光量：方向光负责「哪边朝光」，球面衰减负责「鼓不鼓」
		float key = clamp(diff * 0.84 + dome * 0.16, 0.0, 1.0);
		// 亮度增益用幂律 (key/中性点)^g，不用「1 + 偏差 × 斜率」：
		//   · key 恰等于中性点时增益严格为 1，整幅平均亮度天然守恒，
		//     不会因为改了 relief / 光向就整体变亮或变暗（线性式就得每次重算中点）；
		//   · 乘性关系，压暗提亮都不改色相；
		//   · 两头夹住 0.30 / 1.60，背光面能沉下去（原来 0.52 太客气，看着就平）。
		float lit = clamp(pow(max(key, 0.002) / max(key_neutral, 0.05), shade_gain), 0.76, 1.18);

		// 只推「明度」，色相和彩度一分不动：
		// RGB 三通道各自 screen 会把艳色洗成粉白（实测饱和度掉 60%），
		// 那样就不是水墨而是塑料了。这里把颜色拆成 色度向量 × 明度，
		// 明度走 multiply（压暗）/ screen（提亮）两条都锚在 0 和 1 上的曲线，
		// 白毛压得下去、黄毛亮得起来，颜色始终是原来那一色。
		float v = max(base.r, max(base.g, base.b));
		vec3 chroma = base / max(v, 0.0001);
		float v2 = lit < 1.0 ? v * lit : 1.0 - pow(max(1.0 - v, 0.0), lit);
		vec3 shaded = chroma * v2;

		// 色温分离：暗部偏冷、亮部回暖（幅度很小，不能把水墨调成塑料）
		shaded = mix(shaded, shaded * shade_color, clamp((key_neutral - key) * 1.5, 0.0, 1.0) * tint_strength);
		shaded = mix(shaded, shaded * key_color, clamp((key - key_neutral) * 1.6, 0.0, 1.0) * tint_strength * 0.8);

		// —— 空腔：四周比自己高 = 凹处（耳根、下巴、腋下、腿缝），压暗才咬得住 ——
		float around = (h_l + h_r + h_t + h_b) * 0.25;
		float cav = clamp((around - h_c) * 14.0, 0.0, 1.0);
		// 再来一圈大半径的：大凹处（腋下、腿间）靠小半径吃不到
		float h_l2 = _height(UV - vec2(cs.x, 0.0), here);
		float h_r2 = _height(UV + vec2(cs.x, 0.0), here);
		float h_t2 = _height(UV - vec2(0.0, cs.y), here);
		float h_b2 = _height(UV + vec2(0.0, cs.y), here);
		float around2 = (h_l2 + h_r2 + h_t2 + h_b2) * 0.25;
		float cav2 = clamp((around2 - h_c) * 7.0, 0.0, 1.0);
		float occ = clamp(cav * 0.62 + cav2 * 0.55, 0.0, 1.0);
		shaded *= 1.0 - occ * ao_strength;

		// —— 覆盖度：只有实心像素才加光/勾墨 ——
		// 半透明边缘像素 rgb 近黑，任何加光都会变成剪影外的一圈白晕。
		float cov = smoothstep(0.55, 0.95, a);

		// 轮廓带：靠 alpha 的骤降找真剪影，跟体块粗细无关
		// （用高度 h_c 找边缘的写法，会把细胳膊整条都算成边缘，于是整条胳膊发光。）
		// 半径必须小：用低频采样那个 26px 半径去找轮廓，整只怪都会被判成「边缘」。
		vec2 es = vec2(0.0045, 0.0045);
		float a_ring = min(
			min(texture(TEXTURE, UV - vec2(es.x, 0.0)).a, texture(TEXTURE, UV + vec2(es.x, 0.0)).a),
			min(texture(TEXTURE, UV - vec2(0.0, es.y)).a, texture(TEXTURE, UV + vec2(0.0, es.y)).a));
		float band = clamp(1.0 - a_ring, 0.0, 1.0) * cov;              // 轮廓光用：约 5px 宽
		float band_near = clamp(1.0 - a_ring * 1.55, 0.0, 1.0) * cov;  // 墨线用：约 3px 宽

		// —— 勾线：水墨的轮廓线在背光侧更重（积墨），受光侧更淡 ——
		// 线的粗细用体积场的法线朝向决定：法线背对光的那边 = 暗侧 = 墨重。
		// 这样一圈线有轻重变化，而不是机械的一圈描边。
		//
		// ⚠ 一律用 min() 而不是 mix()：mix 到墨色会把「本来就比墨色还深的描边」
		// 提亮成灰边（看着像脏了一圈）。min() 保证只压不抬 —— 已经够黑的地方不动。
		float facing = dot(n, L);
		float line_w = ink_line * mix(1.45, 0.40, smoothstep(-0.20, 0.55, facing));
		shaded = min(shaded, mix(shaded, ink_tint.rgb, clamp(band_near * line_w, 0.0, 0.92)));

		// —— 沟边：轮廓内侧一圈极淡的墨色渐深，模仿笔锋收尾处的积墨 ——
		float groove = band * ink_crevice * mix(0.7, 1.5, smoothstep(0.55, -0.20, facing));
		shaded = min(shaded, mix(shaded, ink_tint.rgb, clamp(groove, 0.0, 0.5)));

		// —— 凹处积墨：耳根、下巴、腋下、腿缝往墨里沉一笔（比单纯压暗更像水墨）——
		shaded = min(shaded, mix(shaded, ink_tint.rgb, clamp(occ * ink_crevice * 0.8, 0.0, 0.35)));

		// —— 边缘光：朝光的那一侧轮廓提亮，颜色取「本色提亮」而不是纯白 ——
		vec3 R = normalize(rim_dir);
		float side = clamp(dot(n, R) * 0.5 + 0.5, 0.0, 1.0);
		float rim = band * pow(side, 1.7) * rim_strength;
		vec3 rim_col = mix(rim_color, base * 1.45 + vec3(0.04), 0.70);
		shaded += rim_col * rim;

		// —— 高光：窄，只落在正对光的凸起上 ——
		vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
		float spec = pow(clamp(dot(n, H), 0.0, 1.0), spec_power) * spec_strength;
		shaded += key_color * spec * cov;

		// —— 饱和亮部自发光：眼睛、宝石这种地方要「亮起来」——
		float mx = max(base.r, max(base.g, base.b));
		float mn = min(base.r, min(base.g, base.b));
		float glow = smoothstep(0.34, 0.62, mx - mn) * smoothstep(0.62, 0.92, lum);
		shaded += base * glow * glow_strength * cov;

		// 高光软膝：过 0.88 之后斜率减半，白色区域不会整片焊死
		shaded *= exposure;
		shaded = shaded - max(shaded - vec3(0.88), vec3(0.0)) * 0.60;

		// 顶部微亮 / 底部微沉：接地感
		shaded *= mix(1.02, 0.965, UV.y);

		COLOR = vec4(clamp(shaded, vec3(0.0), vec3(1.0)), a);
		if (probe_mode == 1) {
			COLOR = vec4(vec3(key), a);
		} else if (probe_mode == 2) {
			COLOR = vec4(vec3(h_c), a);
		} else if (probe_mode == 3) {
			COLOR = vec4(vec3(detail + 0.5), a);
		}
	}
}
