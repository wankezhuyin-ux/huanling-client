extends SceneTree

## 校验横向卷轴的铺贴与推进：
##   1) 三张铺贴（A / 镜像A / A）首尾相接，任何偏移下都铺满一屏（不留缝、不重叠）；
##   2) 第二张是 A 的水平镜像、第三张又是 A → A 的右边缘与镜像图的左边缘是**同一列像素**，
##      接缝像素级连续（真无缝，不靠阴影带「盖住」）。镜像模式下**不建阴影带**，
##      否则会变成「每隔一屏一条黑杠」；
##   3) 走满两屏折回 0，贴图不换，画面自然连续（无闪屏）；
##   4) tick() 推进偏移：速度 × 时间 = 位移；速度为 0 / 未启用时不动；
##   5) 强制重复铺（地标很强的图）关掉镜像、留阴影带兜底；
##   6) 静态模式（ENABLED=false）不建铺贴、不推进。
## 用法：godot --headless --path . --script res://tools/test_battle_scroll_world.gd

const ScrollWorldScript = preload("res://scripts/ui/battle_scroll_world.gd")
const PANEL_SIZE := Vector2(700.0, 460.0)


func _initialize() -> void:
	var root: Node = get_root()

	var panel: Control = Control.new()
	panel.name = "FakeBattlePanel"
	panel.size = PANEL_SIZE
	root.add_child(panel)

	var bg: TextureRect = TextureRect.new()
	bg.name = "BattleBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.add_child(bg)

	var tex: Texture2D = load("res://assets/backgrounds/morenzhandoubj.jpg") as Texture2D
	if tex == null:
		print("FAIL 背景图加载失败")
		quit(1)
		return

	# 先验静态模式：不建第二张铺贴、不推进。
	var world = ScrollWorldScript.new()
	root.add_child(world)
	ScrollWorldScript.ENABLED = false
	world.bind(panel, bg)
	world.prepare(tex)
	world.tick(1.0, 100.0)
	var static_ok: bool = panel.get_node_or_null("BattleBackgroundNext") == null \
		and bg.texture == tex and world.current_offset() == 0.0
	print("静态模式：不建第二张铺贴、贴图直接换上、tick 不推进: ", "OK" if static_ok else "FAIL")
	var fails: int = 0 if static_ok else 1

	# 卷动 + 镜像拼接
	ScrollWorldScript.ENABLED = true
	world.bind(panel, bg)
	world.prepare(tex)

	var next: TextureRect = panel.get_node_or_null("BattleBackgroundNext") as TextureRect
	if next == null:
		print("FAIL 没有创建第二张铺贴")
		quit(1)
		return
	var next2: TextureRect = panel.get_node_or_null("BattleBackgroundNext2") as TextureRect
	if next2 == null:
		print("FAIL 没有创建第三张铺贴")
		quit(1)
		return

	# 1) 铺满：三张紧贴，宽度都等于面板宽。
	for offset in [0.0, 1.0, 123.5, 350.0, 699.9]:
		world._set_offset(offset)
		var bg_l: float = bg.offset_left
		var bg_r: float = PANEL_SIZE.x + bg.offset_right
		var nx_l: float = next.offset_left
		var nx_r: float = PANEL_SIZE.x + next.offset_right
		var n2_l: float = next2.offset_left
		var n2_r: float = PANEL_SIZE.x + next2.offset_right
		var covered_ok: bool = absf(bg_l - (-offset)) < 0.01 and absf(bg_r - (PANEL_SIZE.x - offset)) < 0.01 \
			and absf(nx_l - (PANEL_SIZE.x - offset)) < 0.01 and absf(nx_r - (PANEL_SIZE.x * 2.0 - offset)) < 0.01 \
			and absf(n2_l - (PANEL_SIZE.x * 2.0 - offset)) < 0.01 and absf(n2_r - (PANEL_SIZE.x * 3.0 - offset)) < 0.01
		print("offset=%.1f  bg=[%.1f,%.1f]  next=[%.1f,%.1f]  next2=[%.1f,%.1f]  %s" % [offset, bg_l, bg_r, nx_l, nx_r, n2_l, n2_r, "OK" if covered_ok else "FAIL"])
		if not covered_ok:
			fails += 1

	# 2) 镜像拼接：靠 TextureRect.flip_h（不再翻出一张贴图，省 1.4MB，也不依赖 get_image）
	var mirrored: bool = next.flip_h and _texture_of(next) == tex
	var third_same: bool = _texture_of(next2) == tex and not next2.flip_h
	print("第二张=镜像(flip_h)、第三张=原图: ", "OK" if (mirrored and third_same) else "FAIL")
	if not (mirrored and third_same):
		fails += 1

	# 镜像接缝「像素级连续」这件事 headless 验不出来（要真渲染 + COVERED 裁切），
	# 交给 tools/probe_battle_seam.gd 按不同屏幕比例实测。这里只保证：
	#   · 第二张是原图 + flip_h（不是「两张一样的图」，那就成硬缝了）
	#   · 镜像模式下不压阴影带
	var flip_ok: bool = next.flip_h == world._mirror_mode
	print("flip_h 与镜像模式一致: ", "OK" if flip_ok else "FAIL")
	if not flip_ok:
		fails += 1

	var seam: TextureRect = panel.get_node_or_null("BattleBackgroundSeam") as TextureRect
	var no_band: bool = seam != null and not seam.visible and not world._seam_needed
	print("镜像模式不压阴影带（否则每屏一条黑杠）: ", "OK" if no_band else "FAIL")
	if not no_band:
		fails += 1

	# 3) 折回：镜像模式下内容周期是两屏，折回点要对齐内容，否则会闪一下。
	world._set_offset(PANEL_SIZE.x * 0.5)
	var tex_before: Texture2D = _texture_of(bg)
	var cycle_ok: bool = absf(world._cycle - PANEL_SIZE.x * 2.0) < 0.01
	print("镜像模式周期=两屏: ", "OK" if cycle_ok else "FAIL", "  cycle=", world._cycle)
	if not cycle_ok:
		fails += 1
	world._set_offset(PANEL_SIZE.x * 2.0 + 0.5)
	var offset_after: float = world.current_offset()
	var wrap_ok: bool = absf(offset_after - 0.5) < 0.01 and _texture_of(bg) == tex_before
	print("走满两屏折回: offset=%.2f 折回后贴图不变: %s" % [offset_after, "OK" if wrap_ok else "FAIL"])
	if not wrap_ok:
		fails += 1

	# 4) tick 推进：位移 = 速度 × 时间，且一直跑也不会跑出周期。
	world.reset()
	var s0: float = world.current_offset()
	world.tick(1.0, 22.0)
	var s1: float = world.current_offset()
	var tick_ok: bool = absf(s0) < 0.01 and absf(s1 - 22.0) < 0.01
	print("tick(1s, 22px/s) 位移 0 → %.2f: %s" % [s1, "OK" if tick_ok else "FAIL"])
	if not tick_ok:
		fails += 1
	world.tick(1.0, 0.0)
	var s2: float = world.current_offset()
	var idle_ok: bool = absf(s2 - s1) < 0.01
	print("速度 0 时不动: ", "OK" if idle_ok else "FAIL")
	if not idle_ok:
		fails += 1
	for i in range(100):
		world.tick(1.0, 200.0)
	var s3: float = world.current_offset()
	var loop_ok: bool = s3 >= 0.0 and s3 < world._cycle
	print("跑 2 万像素后仍在 [0, 周期) 内: offset=%.1f cycle=%.1f  %s" % [s3, world._cycle, "OK" if loop_ok else "FAIL"])
	if not loop_ok:
		fails += 1

	# 5) 强制重复铺：地标很强的图（对称会看出是复制品）可以单独关掉镜像。
	world.force_repeat_maps.append("morenzhandoubj")
	world.prepare(tex)
	var forced_ok: bool = not world._mirror_mode and _texture_of(next) == tex \
		and absf(world._cycle - PANEL_SIZE.x) < 0.01 and seam.visible and world._seam_needed
	print("地标强的图强制重复铺（关镜像、周期一屏、留阴影带）: ", "OK" if forced_ok else "FAIL")
	if not forced_ok:
		fails += 1
	world.force_repeat_maps.clear()
	world.prepare(tex)

	# 6) 关掉强制镜像：真·无缝素材 + **比例对得上的面板**（COVERED 左右不裁）
	#    → 走「三张同图、周期一屏」。这是以后重画成「左右边缘对齐」的素材时的路。
	ScrollWorldScript.FORCE_MIRROR = false
	var tile_tex: ImageTexture = _make_tileable_texture(256, 128)
	var square_panel: Vector2 = Vector2(512.0, 256.0)   # 和 256x128 同比例 → 不裁
	panel.size = square_panel
	world.prepare(tile_tex)
	var tile_ok: bool = not seam.visible and not world._seam_needed \
		and _texture_of(next) == tile_tex and _texture_of(next2) == tile_tex \
		and absf(world._cycle - square_panel.x) < 0.01
	print("无缝图 + 同比例面板（不裁）→ 三张同图、周期一屏: ", "OK" if tile_ok else "FAIL")
	if not tile_ok:
		fails += 1

	# 6b) ★回归用例★ 同一张图，比例不同 → 结论必须不同。
	#     线上反馈的「有的手机地图拼接是一条硬缝」就是这个：
	#       · 面板高/宽 1.36 ≈ 原图 700/512=1.367 → 左右不裁 → 接缝拼的是原图左右边缘 → 缝看不出
	#       · 面板高/宽 1.57（瘦长屏）→ 左右各裁一截 → 接缝拼的是图中间两列 → 硬竖线
	var muj: Texture2D = load("res://assets/backgrounds/暮归道.jpg") as Texture2D
	if muj == null:
		print("FAIL 暮归道.jpg 加载失败")
		fails += 1
	else:
		panel.size = Vector2(700.0, 950.0)
		world.prepare(muj)
		var short_cols: Vector2i = world.visible_source_columns(muj, panel.size)
		var short_ok: bool = not world._mirror_mode and short_cols.x == 0
		print("矮面板(700x950) 不裁 %s → 重复铺: %s" % [str(short_cols), "OK" if short_ok else "FAIL"])
		if not short_ok:
			fails += 1

		panel.size = Vector2(700.0, 1100.0)
		world.prepare(muj)
		var tall_cols: Vector2i = world.visible_source_columns(muj, panel.size)
		var tall_ok: bool = world._mirror_mode and next.flip_h \
			and tall_cols.x > 4 and tall_cols.y < 508
		print("瘦长面板(700x1100) 左右被裁 %s → 自动改镜像: %s" % [str(tall_cols), "OK" if tall_ok else "FAIL"])
		if not tall_ok:
			fails += 1

	panel.size = PANEL_SIZE
	world.prepare(tex)
	ScrollWorldScript.FORCE_MIRROR = false

	# 7) 真素材：重画成「左右边缘同质」的密林图，应该自动走重复铺——
	#    不镜像、不压阴影带、周期一屏。这是方案 C 的验收点。
	var forest: Texture2D = load("res://assets/backgrounds/徘徊林.jpg") as Texture2D
	if forest == null:
		print("FAIL 密林图加载失败")
		fails += 1
	else:
		world.prepare(forest)
		var forest_ok: bool = not world._mirror_mode and not world._seam_needed \
			and not seam.visible and _texture_of(next) == forest \
			and absf(world._cycle - PANEL_SIZE.x) < 0.01
		print("真素材（边缘同质的密林）自动走重复铺、不镜像不压带: ", "OK" if forest_ok else "FAIL")
		if not forest_ok:
			fails += 1
		var f_img: Image = forest.get_image()
		if f_img != null:
			if f_img.is_compressed():
				f_img.decompress()
			var fw: int = f_img.get_width()
			var fh: int = f_img.get_height()
			# 判定口径跟代码一致：整列偏色（有符号均值）+ 分段偏色，不是逐行 abs。
			var bias_all: float = world._column_bias(f_img, 1, fw - 2, 0, fh)
			var bias_band: float = 0.0
			var yy: int = 0
			while yy + ScrollWorldScript.SEAM_BAND_ROWS <= fh:
				bias_band = maxf(bias_band, world._column_bias(f_img, 1, fw - 2, yy, yy + ScrollWorldScript.SEAM_BAND_ROWS))
				yy += ScrollWorldScript.SEAM_BAND_ROWS
			var edge_ok: bool = bias_all <= ScrollWorldScript.SEAM_BIAS_MAX and bias_band <= ScrollWorldScript.SEAM_BAND_MAX
			print("重复铺接缝：整列偏色 %.2f（≤%.0f）分段偏色 %.2f（≤%.0f）: %s" % [
				bias_all, ScrollWorldScript.SEAM_BIAS_MAX, bias_band, ScrollWorldScript.SEAM_BAND_MAX,
				"OK" if edge_ok else "FAIL"])
			if not edge_ok:
				fails += 1

	ScrollWorldScript.ENABLED = false
	print("FAIL_COUNT=", fails)
	print("DONE")
	quit(0 if fails == 0 else 1)


func _texture_of(node: TextureRect) -> Texture2D:
	if node == null or not is_instance_valid(node):
		return null
	return node.texture


## 一张「左边缘=右边缘」的测试图：横向按 cos(2πx/w) 渐变，首尾同色。
func _make_tileable_texture(w: int, h: int) -> ImageTexture:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in range(w):
		var v: float = 0.5 + 0.5 * cos(TAU * float(x) / float(w))
		var c: Color = Color(v, v * 0.9, v * 0.8, 1.0)
		for y in range(h):
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
