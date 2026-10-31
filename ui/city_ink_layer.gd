extends Control
class_name CityInkLayer

## 主城「水墨」HUD 图层（reskin 设计稿的 Godot 落地）
##
## 坐标换算（唯一规则，所有元素都走这里）：
##     s  = size.x / 1024               宽度贴合，保证左右两端吊牌不被裁
##     oy = size.y / 2 - 768 * s        纵向以设计中心对齐
##     local = (dx * s, oy + dy * s)
##
## 背景图是 1024×2000（原 1536 高上下各补 232 的雾），多出来的部分专门用来
## 兜 20:9 / 21:9 这类比 9:16 更长的屏幕，保证任何比例下都不会露底。
##
## 标题周围原来挂了两片「光翼」（wing_l / wing_r + UV 扭动 shader），羽片太抢眼、
## 把山水压住了，已撤掉。换成两层更轻的仙气：
##   ① 毫光：标题背后一条极淡的暖色柔光带，极缓呼吸（一张程序化贴图，静态 1 draw call）
##   ② 灵尘：十几个金色微尘贴着字往上升、明灭不定（一个 GPUParticles2D）
## 两者都不含大块半透明，像素开销远小于原来两片 360×360 的翼。

const D = preload("res://ui/city_ink_data.gd")
const FxScript = preload("res://ui/city_fx.gd")

## 标题整体上移（设计像素，负 = 往上），让出宝塔塔尖
const TITLE_DY := -56.0

## 毫光：设计尺寸 + 呼吸参数
const AURA_W := 880.0
const AURA_H := 250.0
const AURA_CY := -12.0          # 相对设计 y=0 的中心（已含 TITLE_DY 的位移）
const AURA_ALPHA := 0.36        # 峰值不透明度
const AURA_BREATH := 0.26       # 呼吸幅度
const AURA_TINT := Color(1.0, 0.90, 0.68)

var s: float = 1.0
var oy: float = 0.0

var _bg: TextureRect = null
var _fx: Control = null
var _title: TextureRect = null
var _aura: TextureRect = null
var _dust: GPUParticles2D = null
var _fogs: Array = []
var _t: float = 0.0
var _built: bool = false
var _ambient_active: bool = true

## 动效总开关与强度（想关掉动画就改这里，一处生效）
const INK_FX := true
const TITLE_SWEEP := 0.50      # 标题扫光强度
const TITLE_FLOAT := 1.2       # 标题上下浮动幅度（设计像素）
## 背景呼吸缩放：会让整张底图每帧重采样，观感是「背景一直在抖」，且贴片动效
## 与底图之间出现相对位移（悬空岛和底图上画的岛错位）。默认关闭。
const BG_BREATH := 0.0
const SWAY_AMP := 0.0          # 吊牌浮动幅度（0 = 不动按钮，用户明确要求界面静止）
var _bg_base_pos: Vector2 = Vector2.ZERO
var _bg_base_size: Vector2 = Vector2.ZERO
var _aura_base_pos: Vector2 = Vector2.ZERO
var _title_base_pos: Vector2 = Vector2.ZERO
var _sway: Array = []          # [{node, pos(设计坐标), amp, phase, freq}]
var _sway_scan_t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(relayout)
	relayout()


func _build() -> void:
	if _built:
		return
	_built = true

	# 纸色兜底：极端长屏（>2.2:1）时背景也够，但保险起见垫一层
	var paper := ColorRect.new()
	paper.name = "Paper"
	paper.color = Color(0.929, 0.906, 0.859, 1.0)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var _ptm: int = Time.get_ticks_msec()
	_bg = _make_tex("bg_ink.jpg")
	_ptm = Time.get_ticks_msec()
	_bg.name = "Bg"
	_apply_isle_float()
	add_child(_bg)

	# 环境动效层：悬空岛 / 云雾 / 石龙 / 瀑布 / 水面 / 灯火 / 花瓣 / 人群 / 仙鹤
	# 必须在背景之后、雾之前建立，子节点顺序即绘制顺序。
	if INK_FX:
		_fx = FxScript.new()
		_fx.name = "CityFx"
		add_child(_fx)

	# 云雾层：两张可平铺噪声，一快一慢反向漂，做出纵深。
	# 必须夹在背景和标题之间，否则雾会糊到字上。
	var fog_sh := load(D.DIR + "fog.gdshader") as Shader
	if fog_sh != null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.010
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 3
		noise.seed = 20261026
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		nt.noise = noise
		var cfg := [
			{"name": "FogNear", "scroll": Vector2(0.011, 0.0), "density": 0.085,
				"from": 0.02, "to": 0.78, "soft": 0.26, "color": Color(1.0, 0.99, 0.95)},
			{"name": "FogFar", "scroll": Vector2(-0.017, 0.0), "density": 0.055,
				"from": 0.28, "to": 1.02, "soft": 0.20, "color": Color(0.97, 0.97, 0.96)},
		]
		for c in cfg:
			var f := TextureRect.new()
			f.name = String(c["name"])
			f.texture = nt
			f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			f.stretch_mode = TextureRect.STRETCH_SCALE
			f.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var fm := ShaderMaterial.new()
			fm.shader = fog_sh
			fm.set_shader_parameter("noise_tex", nt)
			fm.set_shader_parameter("scroll_speed", c["scroll"])
			fm.set_shader_parameter("density", c["density"])
			fm.set_shader_parameter("y_from", c["from"])
			fm.set_shader_parameter("y_to", c["to"])
			fm.set_shader_parameter("fade_soft", c["soft"])
			fm.set_shader_parameter("tint", c["color"])
			f.material = fm
			add_child(f)
			_fogs.append(f)

	# 毫光：垫在标题底下，只让字背后的雾气微微透暖，不画出任何形状
	_aura = TextureRect.new()
	_aura.name = "TitleAura"
	_aura.texture = _make_aura_tex()
	_aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_aura.stretch_mode = TextureRect.STRETCH_SCALE
	_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aura.modulate.a = AURA_ALPHA
	add_child(_aura)

	_title = _make_tex("title.png")
	_title.name = "Title"
	add_child(_title)
	var tsh := load(D.DIR + "title.gdshader") as Shader
	if tsh != null:
		var tm := ShaderMaterial.new()
		tm.shader = tsh
		tm.set_shader_parameter("sweep_strength", TITLE_SWEEP)
		_title.material = tm

	# 灵尘：一圈细碎金点从字下缓缓浮起，明灭靠 color_ramp 做，不用额外贴图
	_dust = _make_spirit_dust()
	_dust.name = "TitleDust"
	add_child(_dust)

	set_process(_ambient_active)


## 程序化生成「毫光」贴图：横向拉长的椭圆柔光，暖白偏金。
## 128×64 足够（会被拉伸到 880×250 设计像素），纯 alpha 渐变，无噪点。
func _make_aura_tex() -> Texture2D:
	var w := 128
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx := (w - 1) * 0.5
	var cy := (h - 1) * 0.5
	for y in range(h):
		for x in range(w):
			# 归一化椭圆距离（横向已经是 2:1，压回正圆再算）
			var dx := (x - cx) / cx
			var dy := (y - cy) / cy
			var d := sqrt(dx * dx + dy * dy * 1.15)
			var a := clampf(1.0 - d, 0.0, 1.0)
			# 三次平滑，边缘拖得极散，避免看出矩形/椭圆轮廓
			a = a * a * a
			img.set_pixel(x, y, Color(AURA_TINT.r, AURA_TINT.g, AURA_TINT.b, a))
	return ImageTexture.create_from_image(img)


func _make_spirit_dust() -> GPUParticles2D:
	var n := 24
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(x - c, y - c).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1.0, 0.94, 0.74, a))

	var p := GPUParticles2D.new()
	p.texture = ImageTexture.create_from_image(img)
	p.amount = 30
	p.lifetime = 6.5
	p.preprocess = 2.4
	p.local_coords = false
	p.emitting = true
	p.visibility_rect = Rect2(-760, -460, 1520, 800)

	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(360.0, 46.0, 0.0)
	m.direction = Vector3(0.0, -1.0, 0.0)
	m.spread = 20.0
	m.initial_velocity_min = 4.0
	m.initial_velocity_max = 12.0
	m.gravity = Vector3(2.5, -3.0, 0.0)   # 极轻的侧偏，看着像被风带
	m.scale_min = 0.16
	m.scale_max = 0.38
	m.color = Color(1.0, 0.84, 0.50, 0.85)

	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.16, Color(1, 1, 1, 0.70))
	ramp.add_point(0.40, Color(1, 1, 1, 1.00))   # 中段微亮 → 明灭感
	ramp.add_point(0.62, Color(1, 1, 1, 0.26))
	ramp.add_point(0.84, Color(1, 1, 1, 0.78))
	var rt := GradientTexture1D.new()
	rt.gradient = ramp
	m.color_ramp = rt

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.process_material = m
	return p


func _make_tex(path: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(D.DIR + path) as Texture2D
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## 悬空岛浮动：在底图 shader 上按椭圆软掩码做局部位移（见 isle_float.gdshader）。
## 之前是在底图之上再叠一张「同位置的矩形贴片」上下移动 —— 贴片矩形边界就是
## 用户看到的横向断层（岛体比贴片宽、垂枝比贴片长，边缘必然露出接缝）。
## 底图本身只有一张、内容连续，位移不会产生任何硬边。
## 数据：[x, y, w, h, 幅度(设计像素), 角速度, 相位]，x/y/w/h 是岛在底图上的范围。
const ISLE_MASKS := [
	[46.0, 196.0, 152.0, 202.0, 10.0, 0.50, 0.0],
	[792.0, 190.0, 134.0, 200.0, 8.6, 0.42, 1.9],
	[276.0, 182.0, 96.0, 130.0, 6.0, 0.62, 3.4],
]


func _apply_isle_float() -> void:
	if _bg == null:
		return
	var sh := load(D.DIR + "isle_float.gdshader") as Shader
	if sh == null:
		return
	var uv := PackedVector2Array()
	var rh := PackedVector2Array()
	var amp := PackedFloat32Array()
	var spd := PackedFloat32Array()
	var pha := PackedFloat32Array()
	for it in ISLE_MASKS:
		var x := float(it[0])
		var y := float(it[1])
		var w := float(it[2])
		var h := float(it[3])
		# 掩码比贴片外扩一圈：岛体和垂枝都包进去，掩码边缘落在空处，位移看不见边界
		uv.append(Vector2(
			(x + w * 0.5) / D.BG_SIZE.x,
			(y + D.BG_PAD + h * 0.5) / D.BG_SIZE.y))
		rh.append(Vector2(
			w * 0.62 / D.BG_SIZE.x,
			h * 0.70 / D.BG_SIZE.y))
		amp.append(float(it[4]) / D.BG_SIZE.y)
		spd.append(float(it[5]))
		pha.append(float(it[6]))
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("isle_uv", uv)
	m.set_shader_parameter("isle_rh", rh)
	m.set_shader_parameter("isle_amp", amp)
	m.set_shader_parameter("isle_sp", spd)
	m.set_shader_parameter("isle_ph", pha)
	m.set_shader_parameter("edge_soft", 0.42)
	# 龙身边雾团的缓涡流（底图坐标 UV：雾团中心约在设计 (200,600)）
	m.set_shader_parameter("mist_uv", Vector2(200.0 / D.BG_SIZE.x,
		(600.0 + D.BG_PAD) / D.BG_SIZE.y))
	m.set_shader_parameter("mist_rh", Vector2(0.340, 0.200))
	m.set_shader_parameter("mist_amp", 0.0017)
	_bg.material = m


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if not INK_FX:
		return

	# ① 毫光呼吸：双周期叠加，看不出规律；只改 modulate.a，不重绘贴图
	if _aura != null and is_instance_valid(_aura):
		var k := 1.0 + AURA_BREATH * (0.62 * sin(_t * 0.72) + 0.38 * sin(_t * 1.13 + 1.1))
		_aura.modulate.a = AURA_ALPHA * k
		# 极缓的左右飘移（±10 设计像素），像云气在移
		_aura.position = _aura_base_pos + Vector2(sin(_t * 0.23) * 10.0 * s, 0.0)

	# ② 背景呼吸：默认关闭（BG_BREATH=0）。开启会让整张底图逐帧重采样，
	#    视觉上就是「背景在抖」，同时贴片动效与底图会产生相对位移。
	if BG_BREATH > 0.0 and _bg and _bg_base_size.x > 1.0:
		var k := 1.0 + BG_BREATH * sin(_t * 0.55)
		var sz := _bg_base_size * k
		_bg.size = sz
		_bg.position = _bg_base_pos + (_bg_base_size - sz) * 0.5

	# ③ 标题：上下轻浮（扫光在 shader 里跑）
	if _title and _title_base_pos != Vector2.ZERO:
		var dy := sin(_t * 0.85) * TITLE_FLOAT * s
		_title.position = _title_base_pos + Vector2(0.0, dy)

	# ④ 吊牌 / 圆钮：像挂在檐下被风吹，各自相位不同
	if _t - _sway_scan_t > 0.8:
		_sway_scan_t = _t
		_rebuild_sway()
	# 按钮/吊牌一律不动（界面元素静止，动效只做背景环境）
	for it in _sway:
		pass


## 扫描一遍 _ink 下带 ink_pos 的节点，建立浮动表（聊天面板 / 喇叭不参与）
func _rebuild_sway() -> void:
	_sway.clear()
	var idx := 0
	for c in get_children():
		if not (c is Control):
			continue
		if not c.has_meta("ink_pos"):
			continue
		var nm := String(c.name)
		if nm.begins_with("Chat") or nm == "ChatHorn":
			continue
		var pos: Vector2 = c.get_meta("ink_pos")
		var sz: Vector2 = c.get_meta("ink_size")
		# 竖牌摆得多一点，圆钮/小件摆得少一点
		var amp: float = SWAY_AMP if sz.y > sz.x * 1.25 else SWAY_AMP * 0.45
		_sway.append({
			"node": c,
			"pos": pos,
			"amp": amp,
			"phase": float(idx) * 1.37,
			"freq": 0.62 + float(idx % 5) * 0.09,
		})
		idx += 1


# ---------------------------------------------------------------- 坐标
func to_local_from_design(p: Vector2) -> Vector2:
	return Vector2(p.x * s, oy + p.y * s)


func to_design_from_local(p: Vector2) -> Vector2:
	if s < 0.0001:
		return Vector2.ZERO
	return Vector2(p.x / s, (p.y - oy) / s)


## 把一个 Control 按设计坐标摆放（位置 + 尺寸都在设计坐标里给）
func place(c: Control, pos: Vector2, sz: Vector2) -> void:
	if c == null:
		return
	c.custom_minimum_size = Vector2.ZERO
	c.position = to_local_from_design(pos)
	c.size = sz * s


## 同上，但记住位置：之后窗口尺寸变化会自动重排
func bind(c: Control, pos: Vector2, sz: Vector2) -> void:
	if c == null:
		return
	c.set_meta("ink_pos", pos)
	c.set_meta("ink_size", sz)
	place(c, pos, sz)


func relayout() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	s = size.x / D.DESIGN.x
	oy = size.y * 0.5 - D.DESIGN.y * 0.5 * s

	if _bg:
		_bg.position = Vector2(0.0, oy - D.BG_PAD * s)
		_bg.size = D.BG_SIZE * s
		_bg_base_pos = _bg.position
		_bg_base_size = _bg.size
	if _fx != null:
		_fx.call("apply_layout", s, oy)
	if _fogs.size() > 0:
		# 雾层铺满「背景可见区」：从 bg 顶到 bg 底，UV.y 由 shader 再裁窗口
		var fog_pos := Vector2(0.0, oy - D.BG_PAD * s)
		var fog_size := D.BG_SIZE * s
		for f in _fogs:
			(f as TextureRect).position = fog_pos
			(f as TextureRect).size = fog_size
	if _aura != null and is_instance_valid(_aura):
		var ap := to_local_from_design(Vector2(
			(D.DESIGN.x - AURA_W) * 0.5,
			AURA_CY - AURA_H * 0.5))
		_aura.position = ap
		_aura.size = Vector2(AURA_W, AURA_H) * s
		_aura_base_pos = ap
	if _title:
		# 标题整体上移，避开宝塔塔尖（见 TITLE_DY）
		_title.position = to_local_from_design(D.TITLE_RECT + Vector2(0.0, TITLE_DY))
		_title.size = D.TITLE_SIZE * s
		_title_base_pos = _title.position
	if _dust != null and is_instance_valid(_dust):
		# 发射器放在字下方一点，粒子往上飘过字面
		_dust.position = to_local_from_design(Vector2(D.DESIGN.x * 0.5, AURA_CY + 96.0))
		_dust.scale = Vector2(s, s)

	# 已经有主的按钮跟着重排
	reposition_children()


## 所有「已接管」的节点都带 ink_design_rect 元数据，重排时统一刷新
func reposition_children() -> void:
	_apply_meta(self)


func _apply_meta(n: Node) -> void:
	for c in n.get_children():
		if c is Control and c.has_meta("ink_pos"):
			var pos: Vector2 = c.get_meta("ink_pos")
			var sz: Vector2 = c.get_meta("ink_size")
			(c as Control).custom_minimum_size = Vector2.ZERO
			(c as Control).position = to_local_from_design(pos)
			(c as Control).size = sz * s
		_apply_meta(c)


## 打开功能页时把吊牌 / 圆钮 / 齿轮一起收起，避免压在功能页上被误点
func set_ui_visible(v: bool) -> void:
	for c in get_children():
		if c is Control and c.has_meta("ink_pos"):
			(c as Control).visible = v


## 功能页 / 弹窗打开时把「环境动效」整层停摆（回到主城再开）。
##
## 两个作用：
## 1) 正确性：CityFx 里人群 / 仙鹤按设计 y 写过正的 z_index，只要它还在画，
##    就有可能压到功能页上（z_index 是整块画布的全局排序，不受父子层级约束）。
## 2) 性能：主城动效是逐帧模拟 + 大量全屏半透明贴图（云 7 层、瀑布、水面、
##    石龙双 shader、22 个人物逐帧换图、9 只仙鹤、两三层全屏噪声雾）。
##    功能页是全屏不透明面板，这些一秒都看不见，但还在跑 —— 手机帧率就是被这里吃掉的。
##    所以除了 visible=false，还要把 process 也停掉（隐藏的节点默认仍然会 _process），
##    粒子顺带关掉发射。
##
## 只停动效，静态底图（_bg）保留：万一日后有半透明页面，背后仍然是主城而不是白底。
func set_ambient_active(v: bool) -> void:
	_ambient_active = v
	if _fx != null and is_instance_valid(_fx):
		_fx.visible = v
		_fx.process_mode = Node.PROCESS_MODE_INHERIT if v else Node.PROCESS_MODE_DISABLED
	for f in _fogs:
		if is_instance_valid(f):
			(f as CanvasItem).visible = v
	if _aura != null and is_instance_valid(_aura):
		_aura.visible = v
	if _dust != null and is_instance_valid(_dust):
		_dust.visible = v
		_dust.emitting = v
	if _title != null and is_instance_valid(_title):
		_title.visible = v
	# 本层自己的 _process 也在挪标题 / 推进 shader 相位，一起停
	set_process(v)
