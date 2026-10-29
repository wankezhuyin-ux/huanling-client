extends Control
class_name CityFx

## 主城环境动效层 —— 把 out/city_live/index.html 那套 Canvas 分层动效搬进引擎
##
## 挂载位置：CityInkLayer 内、背景之上、雾与标题之下。
## 自身用 scale 做设计坐标 → 屏幕换算，子节点一律直接写 1024×1536 设计像素，
## 因此所有参数可以跟原型逐条对齐，不需要到处乘 s。
##
## 原型绘制顺序：底图 → 悬空岛 → 远景雾 → 后景云 → 石龙 → 前景云 → 瀑布
##   → 水面 → 塔窗幽光 → 灯笼 → 花瓣 → 金粉 → 地面灯火 → 人群/宠物 → 仙鹤
## 底图由 CityInkLayer 自己画，这里从「悬空岛」开始。

const DIR := "res://assets/city_fx/"
const DESIGN := Vector2(1024.0, 1536.0)

# ---- 原型 CFG（逐条对齐，改这里就能调）----
const FALLS_SPEED := 46.0
const FALLS_ALPHA := 0.30
const FALLS_ALPHA2 := 0.13
const WATER_SPEED := 0.055   # 水面贴图宽/秒（shader 里滚 UV，不再挪节点）
const WATER_ALPHA := 0.17
const NPC_S := 192.0
const NPC_BASE := 174.0
const PET_S := 96.0
const PET_BASE := 84.0

## 云：y / 高 / 速度(像素每秒) / 宽倍率 / 透明度 / 色调 / 上下起伏(像素) / 起伏频率(Hz)
## 分前后两组，石龙夹在中间。
## 水墨底接近纸白，纯白云没有对比 → 后景云压成冷灰（暗部）、前景云提亮（亮部），
## 一亮一暗才有「云在流」的层次，否则整片糊成白的。
## 只有横向平移时几乎看不出动（贴图是无缝循环的，1 像素/秒和静止没区别），
## 所以要叠一层很慢的上下起伏 + 透明度呼吸，雾气才会显得在「飘」。
const CLOUDS_BACK := [
	{"k": "cloud3", "y": 108.0, "h": 300.0, "sp": 11.0, "wm": 1.0, "a": 0.38, "tint": Color(0.78, 0.83, 0.88), "bob": 7.0, "bf": 0.070},
	{"k": "cloud1", "y": 196.0, "h": 340.0, "sp": 8.0, "wm": 1.35, "a": 0.42, "tint": Color(0.80, 0.85, 0.90), "bob": 9.0, "bf": 0.055},
	{"k": "cloud2", "y": 288.0, "h": 300.0, "sp": 6.0, "wm": 1.15, "a": 0.34, "tint": Color(0.84, 0.88, 0.92), "bob": 6.0, "bf": 0.085},
]
const CLOUDS_FRONT := [
	{"k": "cloud2", "y": 330.0, "h": 400.0, "sp": 24.0, "wm": 1.6, "a": 0.34, "tint": Color(1.0, 1.0, 1.0), "bob": 11.0, "bf": 0.075},
	{"k": "cloud3", "y": 486.0, "h": 250.0, "sp": 31.0, "wm": 1.2, "a": 0.26, "tint": Color(1.0, 1.0, 1.0), "bob": 13.0, "bf": 0.058},
]

## 飞鸟数量：9 只各飞各的，天空才不空
const CRANE_N := 9

## 石龙：贴片从底图同位置同像素裁下，中心不透明、边缘羽化，位移 2~4px 不出双影
const DR_POS := Vector2(146.0, 392.0)
const DR_SIZE := Vector2(268.0, 244.0)
const DR_NECK := Vector2(110.0, 78.0)
const DR_EYE := Vector2(188.0, 51.0)
const DR_MOUTH := Vector2(220.0, 74.0)

## 口吐白雾：从龙嘴朝水池方向喷出，喷程收得很短（约 110 设计像素）。
## 嘴口在 (≈352, 472)，水池中心 (≈832, 912) → 方向归一化后是 (0.745, 0.667)，斜向右下。
## 纸底是接近白的暖色（0.98, 0.93, 0.83）：纯白雾在上面看不见，暖白更看不见，
## 所以雾必须**偏冷**（掺一点蓝）才有对比 —— 水墨里画雾用淡墨/淡花青也是这个道理。
## 上一版的琥珀暖光与碎光点已整块删掉。
const DR_MOUTH_ANCHOR := Vector2(222.0, 66.0)   # 贴片坐标：嘴口（不是鼻尖，实测张嘴处在贴片 (222,66)）
const BREATH_DIR := Vector2(0.745, 0.667)       # 喷向水池
const BREATH_N := 14                            # 同时存在的雾团数
## 纸上画雾：纸底 (0.98,0.93,0.83) 已经接近白，再加白光只会更白、看不出形状。
## 水墨里画雾用的是「淡墨留白」——雾比纸**略暗一点、偏冷一点**，靠明度差读出形体。
## 所以雾色直接烘进贴图（见 _get_mist_tex），运行时只用 modulate.a 控浓淡。
const BREATH_TINT := Color(0.902, 0.898, 0.892)
const BREATH_ALPHA := 1.60
const BREATH_REACH := 1.65                      # 喷程系数：spd*life*该系数 ≈ 150 设计像素
const BREATH_LIFE := 2.6                        # 每团雾的寿命（秒），也是相位铺开的周期
const BREATH_PUFF_PX := 128.0                   # 雾团贴图边长（Sprite2D scale 的基准）

## 脊柱（贴片坐标），鳞光沿这条线流过
const DR_SPINE := [
	Vector2(32, 156), Vector2(22, 180), Vector2(36, 202), Vector2(58, 212),
	Vector2(84, 216), Vector2(108, 209), Vector2(130, 197), Vector2(142, 179),
	Vector2(140, 159), Vector2(131, 137), Vector2(121, 114), Vector2(113, 89),
	Vector2(107, 63), Vector2(113, 41), Vector2(135, 29), Vector2(160, 27),
	Vector2(180, 34), Vector2(195, 49),
]

## 瀑布 / 水面：都要严格对齐底图上的水流，别盖到别处去。
## 底图实测：水口在 y≈566，落到 y≈812 化成水雾；横向 x≈720..932。
## 早先 FALLS_RECT 高 240 且三段堆叠，覆盖 308~1028 —— 上面的浮岛、下面的商店街
## 屋顶全被刷上了流水条纹，所以这版加了 falls_band.gdshader 把贴片夹在带内。
const FALLS_RECT := Rect2(716, 556, 220, 264)
## 水面（瀑布下的池子 + 右侧河道）：底图实测 y≈834..1000，x≈656..1008。
const WATER_RECT := Rect2(656, 828, 352, 168)

## 灯笼 / 石柱灯（暖光点）：[x, y, 强度]
## 原型里这套坐标跟底图对不上（会飘在半空），这里逐盏按底图重新标过：
## 三盏是两座亭子檐下挂的灯笼，两盏是下层店铺廊下的灯，四盏是广场上的石柱灯。
const LANTERNS := [
	# 亭子檐下挂灯笼
	[282.0, 789.0, 1.00], [347.0, 787.0, 1.00],
	# 下层店铺廊灯
	[317.0, 1173.0, 0.92], [447.0, 1232.0, 0.95], [592.0, 1228.0, 0.92],
	# 广场石柱灯
	[204.0, 1354.0, 1.15], [298.0, 1380.0, 1.12],
	[689.0, 1380.0, 1.05], [796.0, 1342.0, 1.00],
]

## 灯斑闪耀：[x, y, 尺寸(设计像素), 相位]。与 LANTERNS 一一对应，
## 尺寸按灯体大小给（石柱灯比檐下灯笼大一圈），相位错开避免整排同时闪。
const GLINTS := [
	[282.0, 789.0, 32.0, 0.0], [347.0, 787.0, 32.0, 2.4],
	[317.0, 1173.0, 30.0, 4.1], [447.0, 1232.0, 30.0, 1.4], [592.0, 1228.0, 30.0, 5.4],
	[204.0, 1354.0, 42.0, 1.9], [298.0, 1380.0, 42.0, 5.0],
	[689.0, 1380.0, 40.0, 0.7], [796.0, 1342.0, 40.0, 4.6],
]

## 塔窗暖光
const PAGODA_WIN := [
	[446.0, 126.0], [506.0, 126.0], [444.0, 182.0], [504.0, 182.0],
	[440.0, 240.0], [502.0, 240.0], [442.0, 296.0], [506.0, 296.0],
	[450.0, 348.0], [512.0, 348.0], [456.0, 392.0], [518.0, 392.0],
]

## 地面灯火
const GROUND_GLOW := [
	[140.0, 1408.0, 1.15], [390.0, 1420.0, 1.15], [505.0, 1306.0, 0.95],
	[300.0, 1240.0, 0.8], [600.0, 1268.0, 0.8],
]

## 人群行走带：x 区间 + 两端 y（按 x 线性过渡，天然支持斜向台阶）+ 抖动 + 尺度/透明度/步速。
## 用户要求：人物不要全挤在广场（红圈），要在总数不变的前提下分几个到
## 中央大台阶（黄）、近景石板（蓝）、高处长廊（绿），越远的越小越淡。
## n 是该带的人数；各带 n 之和 = NPC_CAST.size() = 22。
const WALK := [
	# 0 广场·店铺檐下（红圈上半）
	{"x0": 536.0, "x1": 620.0, "y0": 1120.0, "y1": 1120.0, "jit": 14.0, "sc0": 0.30, "sc1": 0.36, "a": 0.44, "v0": 4.0, "v1": 7.0, "n": 4},
	# 1 广场·右侧短台阶（红圈右）
	{"x0": 518.0, "x1": 626.0, "y0": 1268.0, "y1": 1168.0, "jit": 5.0, "sc0": 0.34, "sc1": 0.42, "a": 0.58, "v0": 9.0, "v1": 14.0, "n": 3},
	# 2 广场·前排（红圈主体）
	{"x0": 336.0, "x1": 660.0, "y0": 1282.0, "y1": 1282.0, "jit": 30.0, "sc0": 0.42, "sc1": 0.52, "a": 0.70, "v0": 12.0, "v1": 19.0, "n": 7},
	# 3 黄圈：中央大台阶（斜向往上走，越往上越远越小）
	{"x0": 400.0, "x1": 498.0, "y0": 888.0, "y1": 1076.0, "jit": 3.0, "sc0": 0.25, "sc1": 0.30, "a": 0.45, "v0": 7.0, "v1": 11.0, "n": 3, "sc_grad": true},
	# 4 蓝圈：近景石板（离镜头最近，比广场的还大一圈）
	{"x0": 352.0, "x1": 640.0, "y0": 1420.0, "y1": 1452.0, "jit": 7.0, "sc0": 0.46, "sc1": 0.54, "a": 0.74, "v0": 13.0, "v1": 20.0, "n": 3},
	# 5 绿圈：高处长廊（最远，只有 1/5 大小、淡淡的，还会轻微明灭）
	{"x0": 272.0, "x1": 356.0, "y0": 830.0, "y1": 836.0, "jit": 1.5, "sc0": 0.20, "sc1": 0.24, "a": 0.32, "v0": 4.0, "v1": 6.0, "n": 2, "shimmer": true},
]

## 身份配比：修士/商贩最多，撑伞、孩童、老者、抱宠者点缀
const NPC_CAST := [
	"xiushi", "vendor", "child", "petowner", "vendor", "elder",
	"xiushi", "child", "vendor", "umbrella", "xiushi", "child",
	"child", "vendor", "xiushi", "elder", "vendor", "xiushi",
	"xiushi", "child", "petowner", "vendor",
]
const PET_KINDS := ["fox", "puff", "pup"]

const GOLD := 0.6180339887

var s: float = 1.0
var _t: float = 0.0
var _built: bool = false

var _tex: Dictionary = {}
var _npc_tex: Dictionary = {}
var _pet_tex: Dictionary = {}
var _crane_tex: Array = []
var _petal_tex: Array = []
var _glow_tex: Texture2D = null
var _soft_glow_tex: Texture2D = null
var _mist_tex: Texture2D = null
var _glint_tex: Texture2D = null

var _cloud_nodes: Array = []     # [{segs:[TextureRect], ...}]
var _falls_nodes: Array = []     # [{segs:[TextureRect], mats:[ShaderMaterial]}]
var _water_node: TextureRect = null
var _dragon: Dictionary = {}
var _spine_dots: Array = []
var _lights: Array = []          # [{node, kind, idx, sc}]
var _crowd: Array = []
var _pets: Array = []
var _cranes: Array = []
var _glints: Array = []          # [{node, base, ph}]
var _petals: Array = []          # 左下桃树的手写飘落花瓣（见 _build_peach）


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = DESIGN
	_build()


## 由 CityInkLayer 在 relayout 时调用：s 为宽度贴合比，oy 为纵向居中偏移
func apply_layout(scale_val: float, oy: float) -> void:
	s = scale_val
	position = Vector2(0.0, oy)
	size = DESIGN
	scale = Vector2(s, s)


func _ld(name_: String) -> Texture2D:
	if _tex.has(name_):
		return _tex[name_]
	var t := load(DIR + name_ + ".png") as Texture2D
	_tex[name_] = t
	return t


# ================================================================= 构建
func _build() -> void:
	if _built:
		return
	_built = true

	for c in CLOUDS_BACK:
		_build_cloud(c)
	_build_dragon()
	for c in CLOUDS_FRONT:
		_build_cloud(c)
	_build_falls()
	_build_water()
	_build_pagoda()
	_build_lanterns()
	_build_glints()
	_build_peach()
	_build_ground()
	_build_crowd()

	set_process(true)


## 云：横向平铺，靠挪节点位置循环（不走 shader 滚动，避免接缝闪一下）
func _build_cloud(cfg: Dictionary) -> void:
	var t := _ld(String(cfg["k"]))
	if t == null:
		return
	var csh := load(DIR + "cloud_fade.gdshader") as Shader
	var tint: Color = cfg.get("tint", Color.WHITE)
	var tw := float(t.get_width()) * float(cfg["wm"])
	var h := float(cfg["h"])
	var segs: Array = []
	var need := int(ceil(DESIGN.x / tw)) + 1
	for i in range(maxi(2, need)):
		var r := TextureRect.new()
		r.texture = t
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.size = Vector2(tw, h)
		r.position = Vector2(float(i) * tw, float(cfg["y"]))
		r.modulate = Color(tint.r, tint.g, tint.b, float(cfg["a"]))
		if csh != null:
			var cm := ShaderMaterial.new()
			cm.shader = csh
			cm.set_shader_parameter("top_fade", 0.24)
			cm.set_shader_parameter("bot_fade", 0.28)
			r.material = cm
		add_child(r)
		segs.append(r)
	_cloud_nodes.append({
		"segs": segs, "tw": tw, "sp": float(cfg["sp"]), "y": float(cfg["y"]),
		"bob": float(cfg.get("bob", 0.0)), "bf": float(cfg.get("bf", 0.07)),
		"ph": randf() * TAU, "a0": float(cfg["a"]),
	})


## 石龙：身体 shader 蠕动 + 头部绕颈根微旋 + 脊柱鳞光 + 双眼 + 口吐云气
func _build_dragon() -> void:
	var body_t := _ld("dragon_body")
	var head_t := _ld("dragon_head")

	# 身体
	var body := TextureRect.new()
	body.name = "DragonBody"
	body.texture = body_t
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_SCALE
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = DR_POS
	body.size = DR_SIZE
	var bsh := load(DIR + "dragon_body.gdshader") as Shader
	var bmat: ShaderMaterial = null
	if bsh != null:
		bmat = ShaderMaterial.new()
		bmat.shader = bsh
		bmat.set_shader_parameter("px_size", DR_SIZE)
		body.material = bmat
	add_child(body)

	# 头部：pivot 落在颈根，绕它慢慢抬落
	var head := TextureRect.new()
	head.name = "DragonHead"
	head.texture = head_t
	head.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	head.stretch_mode = TextureRect.STRETCH_SCALE
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.position = DR_POS
	head.size = DR_SIZE
	head.pivot_offset = DR_NECK
	add_child(head)

	# 龙身玉质暖光：同一张贴片染成暖色，加法叠 + 呼吸
	var aura := TextureRect.new()
	aura.name = "DragonAura"
	aura.texture = body_t
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_SCALE
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.position = DR_POS
	aura.size = DR_SIZE
	aura.modulate = Color(1.0, 0.886, 0.659, 0.0)
	var am := CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	aura.material = am
	add_child(aura)

	# 脊柱鳞光：沿脊柱流动的一串光点
	var gl := _get_glow()
	_spine_dots.clear()
	for p in DR_SPINE:
		var sp := Sprite2D.new()
		sp.texture = gl
		sp.position = DR_POS + (p as Vector2)
		sp.modulate = Color(1.0, 0.851, 0.549, 0.0)
		var sm := CanvasItemMaterial.new()
		sm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sp.material = sm
		add_child(sp)
		_spine_dots.append(sp)

	# 双眼：大光晕 + 小亮芯
	var eyes: Array = []
	for i in range(2):
		var e := Sprite2D.new()
		e.texture = gl
		e.modulate = Color(1.0, 0.808, 0.486, 0.0)
		var em := CanvasItemMaterial.new()
		em.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		e.material = em
		add_child(e)
		eyes.append(e)

	# 口吐白雾：手写雾团（不用 GPUParticles2D —— 喷射方向、喷程、尺寸增长都要精确可控，
	# 粒子那边一改方向就得调三个参数，还看不出到底多长）
	var mist := _get_mist_tex()
	var puffs: Array = []
	for i in range(BREATH_N):
		var pf := Sprite2D.new()
		pf.name = "BreathPuff%d" % i
		pf.texture = mist
		pf.modulate = Color(1.0, 1.0, 1.0, 0.0)
		add_child(pf)
		# 相位均匀铺满一整个生命周期，并且开局就摆在飞行途中 ——
		# 否则进主城后要等 2.6 秒雾才慢慢多起来，头几秒看着像「没做」
		var it := _new_puff(pf, 0.0)
		it["t"] = float(i) / float(BREATH_N) * float(it["life"])
		puffs.append(it)

	# 嘴口常驻的那一团：雾团都往前飘，嘴口反而会空出来
	var src := Sprite2D.new()
	src.name = "BreathSource"
	src.texture = mist
	src.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(src)

	_dragon = {
		"body": body, "bmat": bmat, "head": head, "aura": aura,
		"eyes": eyes, "base": DR_POS, "puffs": puffs, "src": src,
	}


## 一粒碎光：延迟为负 → 先隐着。飘出嘴外后按 sin 曲线亮起再淡掉
## 一团口气：延迟为负 → 先隐着。喷程按 (1 - (1-u)^2.2) 缓出，越远越慢、越大、越淡
func _new_puff(node: Sprite2D, delay: float) -> Dictionary:
	# 寿命给固定的值（只留极小抖动）：相位一旦均匀，雾带就一直是均匀的；
	# 上一版每次重生都随机 2.0~2.8 秒，几轮之后相位就乱了，画面会出现「没雾」的空档。
	var life := BREATH_LIFE + randf() * 0.12
	return {
		"node": node,
		"t": -delay - randf() * 0.25,
		"life": life,
		"spd": 28.0 + randf() * 12.0,
		"sc0": 0.16 + randf() * 0.08,
		"sc1": 0.40 + randf() * 0.20,
		"a": BREATH_ALPHA * (0.78 + randf() * 0.40),
		"side": randf() * 2.0 - 1.0,
		"ph": randf() * TAU,
	}


## 雾团贴图：四团高斯叠成不规则的一团（单个圆太假），每一团再各自带一点点明暗差，
## 让它有「体积」而不是一块平色。颜色烘进 RGB（淡墨偏冷），alpha 是软边。
## 之前用 smoothstep 收边会得到一圈平台 —— 贴在纸上就是一个硬邦邦的圆盘，改用 pow 压边。
func _get_mist_tex() -> Texture2D:
	if _mist_tex != null:
		return _mist_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var blobs := [
		Vector3(0.47, 0.53, 0.33),
		Vector3(0.63, 0.44, 0.25),
		Vector3(0.35, 0.44, 0.23),
		Vector3(0.54, 0.65, 0.21),
	]
	for y in range(n):
		for x in range(n):
			var px := float(x) / float(n - 1)
			var py := float(y) / float(n - 1)
			var a := 0.0
			var shade := 0.0
			for bi in range(blobs.size()):
				var b: Vector3 = blobs[bi]
				var dx: float = (px - b.x) / b.z
				var dy: float = (py - b.y) / b.z
				var g: float = exp(-(dx * dx + dy * dy) * 1.55)
				a += g
				# 前两团偏亮（受光面）、后两团偏暗（背光面），叠出一点立体感
				shade += g * (0.024 if bi < 2 else -0.026)
			a = clampf(a * 0.46, 0.0, 1.0)
			a = pow(a, 1.35)
			var r := BREATH_TINT.r + shade
			var gch := BREATH_TINT.g + shade
			var bch := BREATH_TINT.b + shade * 1.35
			img.set_pixel(x, y, Color(r, gch, bch, a))
	_mist_tex = ImageTexture.create_from_image(img)
	return _mist_tex


## 瀑布：竖向平铺滚动，两层不同速度（lighter 叠色）。
## 每段都挂 falls_band.gdshader，用「相对有效带的纵向位置」做遮罩 ——
## 贴片滑出瀑布带就完全透明，滚动本身仍然靠挪节点（同纹理等距堆叠，接缝天然连续）。
func _build_falls() -> void:
	var t := _ld("falls_soft")
	if t == null:
		return
	var fsh := load(DIR + "falls_band.gdshader") as Shader
	for layer in range(2):
		var segs: Array = []
		var mats: Array = []
		var w := FALLS_RECT.size.x + (6.0 if layer == 1 else 0.0)
		var x := FALLS_RECT.position.x - (3.0 if layer == 1 else 0.0)
		for k in range(-1, 2):
			var r := TextureRect.new()
			r.texture = t
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_SCALE
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			r.size = Vector2(w, FALLS_RECT.size.y)
			r.position = Vector2(x, FALLS_RECT.position.y + float(k) * FALLS_RECT.size.y)
			if fsh != null:
				var m := ShaderMaterial.new()
				m.shader = fsh
				# 慢的一层拉更长的淡出，让两层叠起来没有硬边
				m.set_shader_parameter("fade_top", 34.0 if layer == 0 else 20.0)
				m.set_shader_parameter("fade_bot", 58.0 if layer == 0 else 40.0)
				m.set_shader_parameter("strength", FALLS_ALPHA if layer == 0 else FALLS_ALPHA2)
				r.material = m
				mats.append(m)
			else:
				r.modulate = Color(1, 1, 1, FALLS_ALPHA if layer == 0 else FALLS_ALPHA2)
				var bm := CanvasItemMaterial.new()
				bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				r.material = bm
			add_child(r)
			segs.append(r)
		_falls_nodes.append({"segs": segs, "mats": mats})


## 水面：横向缓慢位移 + 加法提亮（滚动在 shader 里做，节点不动）
func _build_water() -> void:
	var t := _ld("water_soft")
	if t == null:
		return
	var r := TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = WATER_RECT.position
	r.size = WATER_RECT.size
	var wsh := load(DIR + "water_flow.gdshader") as Shader
	if wsh != null:
		var m := ShaderMaterial.new()
		m.shader = wsh
		m.set_shader_parameter("strength", WATER_ALPHA)
		m.set_shader_parameter("speed", WATER_SPEED)
		m.set_shader_parameter("edge", 0.13)
		r.material = m
	else:
		r.modulate = Color(1, 1, 1, WATER_ALPHA)
		var bm := CanvasItemMaterial.new()
		bm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		r.material = bm
	add_child(r)
	_water_node = r


## 塔内幽光：大范围暖雾 + 每扇窗各自呼吸 + 塔尖灵光
func _build_pagoda() -> void:
	var gl := _get_glow()
	# 大范围暖雾
	var big := _mk_glow_node(gl, "255,236,190", 340.0, Vector2(300.0, 60.0) + Vector2(170, 170))
	big.set_meta("kind", "pagoda_big")
	_lights.append({"node": big, "kind": "pagoda_big", "idx": 0, "sc": 1.0})
	# 窗格
	var i := 0
	for p in PAGODA_WIN:
		var n := _mk_glow_node(gl, "255,214,150", 46.0, Vector2(float(p[0]), float(p[1])))
		_lights.append({"node": n, "kind": "win", "idx": i, "sc": 1.0})
		i += 1
	# 塔尖灵光
	var tip := _mk_glow_node(gl, "255,244,206", 110.0, Vector2(470.0 + 55.0, -10.0 + 55.0))
	_lights.append({"node": tip, "kind": "tip", "idx": 0, "sc": 1.0})


## 灯笼：各自闪动频率不同
func _build_lanterns() -> void:
	var gl := _get_glow()
	var i := 0
	for it in LANTERNS:
		var n := _mk_glow_node(gl, "255,206,132", 42.0 * float(it[2]), Vector2(float(it[0]), float(it[1])))
		_lights.append({"node": n, "kind": "lantern", "idx": i, "sc": float(it[2])})
		i += 1


## 地面灯火倒影
func _build_ground() -> void:
	var gl := _get_glow()
	var i := 0
	for it in GROUND_GLOW:
		var sc := float(it[2])
		var n := _mk_glow_node(gl, "255,196,120", 190.0 * sc, Vector2(float(it[0]), float(it[1])))
		# 地面倒影是扁椭圆：宽 190*sc、高 90*sc
		n.scale = Vector2(190.0 * sc / 128.0, 90.0 * sc / 128.0)
		_lights.append({"node": n, "kind": "ground", "idx": i, "sc": sc})
		i += 1


func _mk_glow_node(gl: Texture2D, rgb: String, size_px: float, center: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = gl
	sp.position = center
	sp.scale = Vector2(size_px / 128.0, size_px / 128.0)
	var parts := rgb.split(",")
	sp.modulate = Color(float(parts[0]) / 255.0, float(parts[1]) / 255.0, float(parts[2]) / 255.0, 0.0)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = m
	add_child(sp)
	return sp


## 桃花瓣：只从画面左下角那棵桃树飘落（用户指定），不做满屏撒花。
## 这版改成手写小系统，不用粒子：用户要求「更小、更少、稀稀落落一直飘到地面」，
## 而粒子寿命固定，前半段就会在半空淡掉，看起来像「飘一半没了」。
## 现在每片花瓣：树冠出生 → 横摆慢落 → 落到近景石板 → 停一下淡掉 → 隔几秒再从树上飘下来。
const PETAL_N := 12
const PEACH_BOX_C := Vector2(98.0, 1032.0)    # 树冠中心（贴底图实际花朵位置）
const PEACH_BOX_E := Vector2(94.0, 50.0)      # 树冠半宽 / 半高
const PETAL_LAND_Y := 1362.0                  # 落地线：近景石板，到这个高度就停
const PETAL_FADE_IN := 0.7                    # 出生淡入（秒）
const PETAL_LINGER := 1.5                     # 落地后停留淡出（秒）


func _build_peach() -> void:
	_petal_tex.clear()
	for k in range(3):
		_petal_tex.append(_make_petal(k))
	for i in range(PETAL_N):
		var sp := Sprite2D.new()
		sp.name = "Petal%d" % i
		sp.texture = _petal_tex[i % 3]
		add_child(sp)
		var it := {
			"node": sp, "x": 0.0, "y": 0.0, "gy": PETAL_LAND_Y,
			"state": 0, "life": 0.0, "fade": 0.0,
			"vy": 18.0, "drift": 4.0, "sw": 0.8, "swph": 0.0, "amp": 11.0,
			"rot": 0.0, "spin": 0.0, "sc": 0.2, "a": 0.6,
		}
		# 开机时按「已经落了多久」摊开，避免十几片全挤在树冠里一起下
		_spawn_petal(it, float(i) / float(PETAL_N))
		_petals.append(it)


## frac: 0 = 刚从树冠出生，1 = 已经落了一段时间（只用于初始化分布）
func _spawn_petal(it: Dictionary, frac: float) -> void:
	var sx := PEACH_BOX_C.x + (randf() * 2.0 - 1.0) * PEACH_BOX_E.x
	var sy := PEACH_BOX_C.y + (randf() * 2.0 - 1.0) * PEACH_BOX_E.y
	var gy := PETAL_LAND_Y + randf() * 24.0
	# 尺寸：贴图 64 宽、花瓣本体约 36 高，scale 0.15~0.26 → 花瓣 5~9 设计像素
	var sc := 0.20 + randf() * 0.10
	var vy := 26.0 + randf() * 12.0
	var pre := clampf(frac, 0.0, 0.98)
	it["x"] = sx + pre * 30.0
	it["y"] = sy + (gy - sy) * pre
	it["gy"] = gy
	it["vy"] = vy
	it["drift"] = 5.0 + randf() * 6.0
	it["sw"] = 0.50 + randf() * 0.60
	it["swph"] = randf() * TAU
	it["amp"] = 10.0 + randf() * 7.0
	it["rot"] = randf() * TAU
	it["spin"] = (randf() - 0.5) * 0.9
	it["sc"] = sc
	it["a"] = 0.55 + randf() * 0.25
	it["state"] = 0
	it["life"] = 0.0
	it["fade"] = PETAL_FADE_IN * pre2fade(pre)
	var n: Sprite2D = it["node"]
	n.visible = true
	n.position = Vector2(float(it["x"]), float(it["y"]))
	n.scale = Vector2(sc, sc)
	n.rotation = float(it["rot"])
	n.modulate = Color(1, 1, 1, float(it["a"]) * clampf(float(it["fade"]) / PETAL_FADE_IN, 0.0, 1.0))


func pre2fade(pre: float) -> float:
	return 1.0 if pre > 0.06 else pre / 0.06


func _update_petals(delta: float) -> void:
	if _petals.is_empty():
		return
	var t := _t
	for it in _petals:
		var n: Sprite2D = it["node"]
		var st := int(it["state"])
		# 2 = 等待下一次出生（此时节点隐藏）
		if st == 2:
			var wt := float(it["life"]) - delta
			it["life"] = wt
			if wt <= 0.0:
				_spawn_petal(it, 0.0)
			continue
		var life := float(it["life"]) + delta
		it["life"] = life
		var x := float(it["x"])
		var y := float(it["y"])
		if st == 0:
			y += float(it["vy"]) * delta
			# 横摆 + 每片自带的一点右向漂移（画面左下角的树，风往右下游走）
			x += (float(it["drift"]) + sin(t * float(it["sw"]) + float(it["swph"])) * float(it["amp"])) * delta
			it["rot"] = float(it["rot"]) + float(it["spin"]) * delta
			if y >= float(it["gy"]):
				y = float(it["gy"])
				it["state"] = 1
				it["life"] = 0.0
		it["x"] = x
		it["y"] = y
		var a := float(it["a"])
		if st == 0:
			a *= clampf(life / PETAL_FADE_IN, 0.0, 1.0) if life < PETAL_FADE_IN else 1.0
		else:
			# 落地后停在石板上淡掉，然后消失、等下一轮
			a *= clampf(1.0 - float(it["life"]) / PETAL_LINGER, 0.0, 1.0)
			if float(it["life"]) >= PETAL_LINGER:
				n.visible = false
				it["state"] = 2
				it["life"] = 2.0 + randf() * 5.0
				continue
		n.position = Vector2(x, y)
		n.rotation = float(it["rot"])
		var sc := float(it["sc"])
		n.scale = Vector2(sc, sc)
		n.modulate = Color(1, 1, 1, clampf(a, 0.0, 1.0))


## 灯笼 / 石柱灯的光斑：中心亮点 + 四道短芒，偶发一次闪耀。
## 用户要求「光电闪耀时灯笼和石柱灯有光斑闪耀」，所以是尖峰式闪烁，不是常亮。
func _build_glints() -> void:
	var tex := _get_glint()
	for it in GLINTS:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.position = Vector2(float(it[0]), float(it[1]))
		sp.modulate = Color(1.0, 0.96, 0.85, 0.0)
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sp.material = m
		add_child(sp)
		_glints.append({"node": sp, "base": float(it[2]), "ph": float(it[3])})


## 人群 + 宠物 + 仙鹤
func _build_crowd() -> void:
	# 预载帧序列
	for k in ["xiushi", "vendor", "umbrella", "child", "elder", "petowner"]:
		var frames: Array = []
		for i in range(4):
			frames.append(load(DIR + "p_%s_%d.png" % [k, i]) as Texture2D)
		_npc_tex[k] = frames
	for k in PET_KINDS:
		var frames: Array = []
		for i in range(4):
			frames.append(load(DIR + "pet_%s_%d.png" % [k, i]) as Texture2D)
		_pet_tex[k] = frames
	for i in range(4):
		_crane_tex.append(load(DIR + "crane_%d.png" % i) as Texture2D)

	# ---- 人物 ----
	# 先把「每个带几个人」摊平成一串 band 序号，再逐个建精灵
	var order: Array = []
	for bi in range(WALK.size()):
		for _k in range(int(WALK[bi]["n"])):
			order.append(bi)
	var band_i := {}   # 带内序号，用于黄金分割铺 x
	for i in range(mini(NPC_CAST.size(), order.size())):
		var kind := String(NPC_CAST[i])
		var layer := int(order[i])
		var R: Dictionary = WALK[layer]
		var k_in := int(band_i.get(layer, 0))
		band_i[layer] = k_in + 1
		var x0 := float(R["x0"])
		var x1 := float(R["x1"])
		var dir := 1.0 if randf() < 0.5 else -1.0
		# 黄金分割铺 x，比纯随机均匀；人少的带也保证不扎堆
		var x := x0 + _frac(float(k_in) * GOLD + 0.31) * (x1 - x0)
		var room := (x - x0) if dir > 0.0 else (x1 - x)
		var span := maxf(26.0, minf(40.0 + randf() * 90.0, room))
		var t01 := (x - x0) / maxf(1.0, x1 - x0)
		var yjit := (_frac(float(i) * GOLD * 1.7 + 0.13) * 2.0 - 1.0) * float(R["jit"])
		var y := float(R["y0"]) + (float(R["y1"]) - float(R["y0"])) * t01 + yjit
		var sc := 0.0
		if bool(R.get("sc_grad", false)):
			# 台阶带：按 x 进度插值，站得越高越小
			sc = lerpf(float(R["sc0"]), float(R["sc1"]), t01)
		else:
			sc = float(R["sc0"]) + randf() * (float(R["sc1"]) - float(R["sc0"]))
		var sp := Sprite2D.new()
		sp.texture = _npc_tex[kind][0]
		sp.scale = Vector2(sc, sc)
		sp.flip_h = dir < 0.0
		sp.position = Vector2(x, y - NPC_S * sc * 0.5 + (NPC_S - NPC_BASE) * sc)
		var a0 := float(R["a"]) * (0.86 + randf() * 0.22)
		sp.modulate = Color(1, 1, 1, a0)
		add_child(sp)
		_crowd.append({
			"node": sp, "kind": kind, "x": x, "y": y, "yjit": yjit, "dir": dir,
			"from": x, "span": span, "layer": layer, "a0": a0,
			"y0": float(R["y0"]), "y1": float(R["y1"]), "bx0": x0, "bx1": x1,
			"shimmer": bool(R.get("shimmer", false)), "sph": randf() * TAU,
			"v": float(R["v0"]) + randf() * (float(R["v1"]) - float(R["v0"])),
			"sc": sc, "frame": randf() * 4.0, "fps": 5.0 + randf() * 2.0,
		})

	# ---- 宠物 ----
	for i in range(5):
		var owner_: Dictionary = _crowd[i % _crowd.size()]
		var kind2 := String(PET_KINDS[i % PET_KINDS.size()])
		var sp2 := Sprite2D.new()
		sp2.texture = _pet_tex[kind2][0]
		var osc := float(owner_["sc"])
		sp2.modulate = Color(1, 1, 1, minf(1.0, float(owner_["node"].modulate.a) * 1.04))
		sp2.flip_h = float(owner_["dir"]) < 0.0
		add_child(sp2)
		_pets.append({
			"node": sp2, "kind": kind2, "owner": owner_,
			"x": float(owner_["x"]) - float(owner_["dir"]) * 24.0,
			"y": float(owner_["y"]) + 2.0,
			"dir": float(owner_["dir"]), "frame": randf() * 4.0,
			"base": 15.0 + randf() * 15.0, "ph": randf() * TAU,
			"vx": 0.0, "follow": i < 3, "sc": osc,
		})

	# ---- 仙鹤 ----
	# 一只鸟一身参数：尺寸 / 速度 / 航向 / 扇翅频率都各自随机，
	# 这样天空里才有「远的有小的、近的有大的，各飞各的」层次，而不是五只一队的复制品。
	for i in range(CRANE_N):
		var sp3 := Sprite2D.new()
		sp3.texture = _crane_tex[0]
		sp3.position = Vector2(-300, 100)
		add_child(sp3)
		_cranes.append(_new_crane(0.0, sp3, true))


## 造一只仙鹤的运动参数。boot=true 时直接铺在航程中间（进主城立刻就能看到满天鸟），
## 否则从屏幕外开始飞。
func _new_crane(delay: float, node: Sprite2D, boot: bool = false) -> Dictionary:
	# 尺寸差异拉大：小的像远处掠过的，大的像从头顶飞过
	# 体型整体下调过一版（原来 0.15~0.57 → 贴图 38~146 设计像素，玩家反馈太大）：
	# 现在 0.09~0.30 → 约 23~77 设计像素，最大的也不到屏宽 1/13。
	var sc := 0.09 + pow(randf(), 1.8) * 0.21
	var dirx := 1.0 if randf() < 0.5 else -1.0
	# 航向：以水平为主，允许 ±16° 的上扬 / 下压
	var ang := deg_to_rad(randf_range(-16.0, 16.0))
	var spd := 0.0
	# 小鸟扇得快、飞得慢；大鸟扇得慢、飞得快（视觉上像真的远近）
	spd = randf_range(30.0, 52.0) + sc * 62.0
	var flap := randf_range(2.3, 3.4) - sc * 1.1
	var life := 0.0
	var x := 0.0
	var y := randf_range(64.0, 286.0)
	if boot:
		x = randf() * DESIGN.x
	else:
		life = 0.0
		x = -170.0 if dirx > 0.0 else DESIGN.x + 170.0
	var vx := cos(ang) * spd * dirx
	var vy := sin(ang) * spd
	return {
		"node": node,
		"t": -delay - randf() * 0.4,
		"sc": sc, "a": 0.38 + randf() * 0.50, "dir": dirx,
		"vx": vx, "vy": vy, "speed": spd,
		"x": x, "y": y,
		"bob": 2.0 + randf() * 7.0,           # 上下浮动幅度（随体型）
		"bf": 0.55 + randf() * 0.75,          # 浮动频率
		"flap": flap, "fph": randf() * 4.0,   # 扇翅频率 / 相位
		"life": life,
	}


func _frac(v: float) -> float:
	return v - floor(v)


# ================================================================= 贴图生成
func _get_glow() -> Texture2D:
	if _glow_tex != null:
		return _glow_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(x - c, y - c).length() / c
			var a := 0.0
			if d <= 1.0:
				# 中心实、0.28 处半透、0.62 处极淡，1.0 归零（同原型 4 段渐变）
				if d < 0.28:
					a = lerpf(1.0, 0.52, d / 0.28)
				elif d < 0.62:
					a = lerpf(0.52, 0.14, (d - 0.28) / 0.34)
				else:
					a = lerpf(0.14, 0.0, (d - 0.62) / 0.38)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex


## 柔和光斑：纯高斯衰减，没有分段。
## 龙嘴那圈暖光是「正常混合」把纸白染暖，色差只有几个 1/255 ——
## 用 _get_glow() 的 4 段渐变去染会在边缘画出几圈「等高线」（8bit 量化的马赫带），
## 换成连续高斯就没有可见边界了。
func _get_soft_glow() -> Texture2D:
	if _soft_glow_tex != null:
		return _soft_glow_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in range(n):
		for x in range(n):
			var dx := (float(x) - c) / c
			var dy := (float(y) - c) / c
			var d := sqrt(dx * dx + dy * dy)
			var a := 0.0
			if d < 1.0:
				a = exp(-pow(d * 1.85, 2.0)) * (1.0 - smoothstep(0.80, 1.0, d))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	_soft_glow_tex = ImageTexture.create_from_image(img)
	return _soft_glow_tex


## 灯斑贴图：中心柔核 + 横/竖两道长芒 + 两道斜短芒（128×128，加法叠）
func _get_glint() -> Texture2D:
	if _glint_tex != null:
		return _glint_tex
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for y in range(n):
		for x in range(n):
			var dx := (float(x) - c) / c
			var dy := (float(y) - c) / c
			var d := sqrt(dx * dx + dy * dy)
			var a := 0.0
			if d < 1.0:
				a = exp(-pow(d / 0.155, 2.0))
			# 十字长芒：一条细带 + 沿线渐隐
			var ray := 0.0
			ray = maxf(ray, exp(-pow(absf(dy) / 0.050, 2.0)) * maxf(0.0, 1.0 - absf(dx)) * 0.90)
			ray = maxf(ray, exp(-pow(absf(dx) / 0.050, 2.0)) * maxf(0.0, 1.0 - absf(dy)) * 0.90)
			# 斜向短芒，弱一档
			var d1 := absf(dx - dy) * 0.7071
			var d2 := absf(dx + dy) * 0.7071
			ray = maxf(ray, exp(-pow(d1 / 0.048, 2.0)) * maxf(0.0, 1.0 - d) * 0.45)
			ray = maxf(ray, exp(-pow(d2 / 0.048, 2.0)) * maxf(0.0, 1.0 - d) * 0.45)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(maxf(a, ray), 0.0, 1.0)))
	_glint_tex = ImageTexture.create_from_image(img)
	return _glint_tex


## 花瓣精灵：64×64 画布上画一枚细长椭圆，边缘 0.82 起快速收边。
## 原来 26×26 的画布放大后是一团粉色糊斑，手机上看着像脏点。
func _make_petal(kind: int) -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var palette := [
		Vector3(238, 186, 200), Vector3(228, 168, 186), Vector3(246, 214, 216),
	]
	var col: Vector3 = palette[kind % 3]
	var c := (n - 1) * 0.5
	var rot := -0.38
	var cs := cos(-rot)
	var sn := sin(-rot)
	for y in range(n):
		for x in range(n):
			var px := float(x) - c
			var py := float(y) - c
			# 反旋转到花瓣自身坐标
			var rx := px * cs - py * sn
			var ry := px * sn + py * cs
			# 椭圆：半短轴 11、半长轴 18
			var e := (rx * rx) / 121.0 + (ry * ry) / 324.0
			if e > 1.0:
				continue
			var d := sqrt(e)
			var a := 1.0
			if d > 0.82:
				a = 1.0 - (d - 0.82) / 0.18
			a *= 0.92 - 0.14 * d
			# 瓣尖略透，看起来更轻
			if ry < 0.0:
				a *= 1.0 - 0.12 * (-ry / 18.0)
			img.set_pixel(x, y, Color(col.x / 255.0, col.y / 255.0, col.z / 255.0, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ================================================================= 每帧
func _process(delta: float) -> void:
	if not _built or not visible:
		return
	_t += delta
	var t := _t

	_update_clouds(delta)
	_update_dragon(t, delta)
	_update_falls(t)
	_update_water(t)
	_update_lights(t)
	_update_glints(t)
	_update_petals(delta)
	_update_crowd(delta)
	_update_cranes(delta)


func _update_clouds(delta: float) -> void:
	for it in _cloud_nodes:
		var segs: Array = it["segs"]
		var tw := float(it["tw"])
		var sp := float(it["sp"])
		var span := tw * float(segs.size())
		# 起伏与呼吸：两组相位不同，前后云才会「各飘各的」
		var bob := float(it["bob"])
		var bf := float(it["bf"])
		var ph := float(it["ph"])
		var cy := float(it["y"])
		if bob > 0.01:
			cy += sin(_t * bf * TAU + ph) * bob
		var a0 := float(it["a0"])
		var am := 1.0 + 0.13 * sin(_t * bf * TAU * 0.63 + ph + 1.7)
		var aa := clampf(a0 * am, 0.0, 1.0)
		for i in range(segs.size()):
			var r: TextureRect = segs[i]
			var x := r.position.x - sp * delta
			if x <= -tw:
				x += span
			r.position = Vector2(x, cy)
			r.modulate.a = aa


func _update_dragon(t: float, delta: float) -> void:
	if _dragon.is_empty():
		return
	var bmat: ShaderMaterial = _dragon["bmat"]
	if bmat != null:
		bmat.set_shader_parameter("t", t)

	# 头部：绕颈根缓慢抬落
	var hk := sin(t * 0.46)
	var hdy := -3.4 * hk
	var hdx := 1.1 * sin(t * 0.46 + 1.9)
	var hrot := 0.010 * hk
	var head: TextureRect = _dragon["head"]
	head.position = DR_POS + Vector2(hdx, hdy)
	head.rotation = hrot

	# 鳞光：沿脊柱跑一条亮带
	var n := _spine_dots.size()
	for i in range(n):
		var sp: Sprite2D = _spine_dots[i]
		var u := float(i) / float(n)
		var b := sin(u * TAU - t * 1.05)
		if b < 0.10:
			sp.modulate.a = 0.0
			continue
		var r := 14.0 + 4.0 * sin(u * 9.0 + t * 0.8)
		sp.scale = Vector2(r / 128.0, r / 128.0)
		sp.modulate.a = 0.34 * b * b

	# 玉质暖光呼吸（含偶发强脉冲）
	var aura: TextureRect = _dragon["aura"]
	var pulse := pow(maxf(0.0, sin(t * 0.31)), 10.0)
	# 加法叠 + 浅底 → 会把龙身糊成一片白，只留极弱的暖意
	aura.modulate.a = 0.008 + 0.006 * sin(t * 0.8) + 0.022 * pulse

	# 双眼：呼吸 + 偶发强闪；位置跟随头部旋转
	var eyes: Array = _dragon["eyes"]
	var rel := DR_EYE - DR_NECK
	var cs := cos(hrot)
	var sn := sin(hrot)
	var ex := DR_POS.x + DR_NECK.x + hdx + rel.x * cs - rel.y * sn
	var ey := DR_POS.y + DR_NECK.y + hdy + rel.x * sn + rel.y * cs
	var blink := 0.5 + 0.5 * sin(t * 1.25)
	var flare := pow(maxf(0.0, sin(t * 0.31)), 14.0)
	if eyes.size() == 2:
		var big: Sprite2D = eyes[0]
		var core: Sprite2D = eyes[1]
		big.position = Vector2(ex, ey)
		big.scale = Vector2(22.0 / 128.0, 22.0 / 128.0)
		big.modulate.a = 0.14 + 0.10 * blink + 0.18 * flare
		core.position = Vector2(ex, ey)
		core.scale = Vector2(7.5 / 128.0, 7.5 / 128.0)
		core.modulate.a = 0.34 + 0.14 * blink + 0.22 * flare

	# ---- 口吐白雾 ----
	# 嘴的位置跟眼睛一样绕颈根旋转，否则抬头时雾会从别的地方冒出来
	var rel_m := DR_MOUTH_ANCHOR - DR_NECK
	var mx := DR_POS.x + DR_NECK.x + hdx + rel_m.x * cs - rel_m.y * sn
	var my := DR_POS.y + DR_NECK.y + hdy + rel_m.x * sn + rel_m.y * cs
	var dir := BREATH_DIR.normalized()
	var perp := Vector2(-dir.y, dir.x)
	# 喷劲：约 8.7 秒一个来回，弱的时候雾团只飘一小段就散
	var gust := 0.80 + 0.20 * sin(t * 0.72)
	# 嘴口常驻雾团：跟着呼吸起伏，靠它把「雾从嘴里出来」这件事说清楚
	var src: Sprite2D = _dragon["src"]
	var src_sc := 0.34 + 0.04 * sin(t * 1.9)
	src.position = Vector2(mx + dir.x * 7.0, my + dir.y * 7.0)
	src.scale = Vector2(src_sc, src_sc)
	src.modulate.a = 0.62 + 0.16 * sin(t * 2.1)
	for it in _dragon["puffs"]:
		var pf: Sprite2D = it["node"]
		var pt := float(it["t"]) + delta
		var life := float(it["life"])
		if pt > life:
			var fresh := _new_puff(pf, 0.0)
			for kk in fresh.keys():
				it[kk] = fresh[kk]
			pt = float(it["t"])
		it["t"] = pt
		if pt < 0.0:
			pf.visible = false
			continue
		pf.visible = true
		var u01 := clampf(pt / maxf(0.05, life), 0.0, 1.0)
		# 缓出：出嘴时快、越远越慢，像是撞进了空气里
		var travel := 1.0 - pow(1.0 - u01, 2.2)
		var reach := float(it["spd"]) * life * BREATH_REACH * gust
		var dist := reach * travel
		var sway := float(it["side"]) * 18.0 * u01 + sin(u01 * 4.4 + float(it["ph"])) * 3.6 * u01
		var d2 := dist + 9.0
		pf.position = Vector2(
			mx + dir.x * d2 + perp.x * sway,
			my + dir.y * d2 + perp.y * sway + 7.0 * u01 * u01)
		var psc := lerpf(float(it["sc0"]), float(it["sc1"]), u01)
		pf.scale = Vector2(psc, psc)
		# 淡入 / 淡出：两端都收，中间最实（开 0.55 次方 → 中段平台更宽，雾带才连续）
		pf.modulate.a = float(it["a"]) * pow(sin(PI * u01), 0.55)



func _update_falls(t: float) -> void:
	if _falls_nodes.size() < 2:
		return
	var h := FALLS_RECT.size.y
	var y0 := FALLS_RECT.position.y
	var offs := [
		fmod(t * FALLS_SPEED, h),
		fmod(t * FALLS_SPEED * 0.55 + 40.0, h),
	]
	for layer in range(2):
		var segs: Array = _falls_nodes[layer]["segs"]
		var mats: Array = _falls_nodes[layer]["mats"]
		var off := float(offs[layer])
		for k in range(segs.size()):
			var r: TextureRect = segs[k]
			var ny := y0 + off + float(k - 1) * h
			r.position = Vector2(r.position.x, ny)
			# 把「这条贴片相对瀑布带顶的偏移」喂给遮罩：
			# 无论它滑到哪里，落在带外的部分 alpha 都是 0
			if k < mats.size():
				(mats[k] as ShaderMaterial).set_shader_parameter(
					"band", Vector3(ny - y0, h, h))


## 水面滚动已经交给 water_flow.gdshader（滚 UV，不挪节点），
## 原来 fmod(t*9,20) 那种位移每 2.2 秒会「跳」回原位，是个可见的抽帧感，顺手去掉。
func _update_water(_t: float) -> void:
	pass


func _update_lights(t: float) -> void:
	for it in _lights:
		var sp: Sprite2D = it["node"]
		var kind := String(it["kind"])
		var i := int(it["idx"])
		var sc := float(it["sc"])
		var a := 0.0
		match kind:
			"pagoda_big":
				var breathe := 0.36 + 0.16 * sin(t * 0.55)
				a = 0.19 * breathe
			"win":
				a = (0.20 + 0.20 * (0.5 + 0.5 * sin(t * (0.9 + float(i) * 0.17) + float(i) * 1.3))) * 0.85
				var s2 := 46.0 + 10.0 * sin(t * 0.7 + float(i))
				sp.scale = Vector2(s2 / 128.0, s2 / 128.0)
			"tip":
				var up := 0.5 + 0.5 * sin(t * 0.42)
				a = 0.07 + 0.09 * up
			"lantern":
				var fl := 0.5 + 0.5 * sin(t * (1.7 + float(i % 4) * 0.35) + float(i) * 2.1)
				var fl2 := 0.5 + 0.5 * sin(t * (4.3 + float(i % 3) * 0.6) + float(i))
				a = (0.30 + 0.26 * fl) * (1.0 - 0.14 * fl2) * sc
				var s3 := (42.0 + 9.0 * fl) * sc
				sp.scale = Vector2(s3 / 128.0, s3 / 128.0)
			"ground":
				var fl3 := 0.5 + 0.5 * sin(t * (1.4 + float(i) * 0.3) + float(i) * 2.3)
				a = (0.10 + 0.10 * fl3) * sc
		sp.modulate.a = a


## 灯斑：慢呼吸决定「这一轮亮不亮」，尖峰决定「闪的一瞬」。
## 两者相乘 → 隔几秒突然亮一下，而不是均匀呼吸像霓虹灯。
func _update_glints(t: float) -> void:
	for it in _glints:
		var sp: Sprite2D = it["node"]
		var ph := float(it["ph"])
		var base := float(it["base"])
		var slow := 0.5 + 0.5 * sin(t * 0.31 + ph * 1.7)
		var spike := pow(maxf(0.0, sin(t * (0.85 + fmod(ph, 0.7)) + ph * 2.3)), 7.0)
		var a := spike * (0.18 + 0.82 * slow)
		if a < 0.006:
			sp.modulate.a = 0.0
			continue
		var sz := base * (0.62 + 0.62 * spike)
		sp.scale = Vector2(sz / 128.0, sz / 128.0)
		sp.modulate.a = a * 0.92


func _update_crowd(delta: float) -> void:
	var t := _t
	for it in _crowd:
		var n: Sprite2D = it["node"]
		var x := float(it["x"]) + float(it["v"]) * float(it["dir"]) * delta
		var dir := float(it["dir"])
		var from_ := float(it["from"])
		var span := float(it["span"])
		if dir > 0.0 and x > from_ + span:
			dir = -1.0
		if dir < 0.0 and x < from_ - span:
			dir = 1.0
		var y := float(it["y"])
		# 斜向带（台阶）：y 跟着 x 走，保证脚一直踩在踏步上
		if absf(float(it["y1"]) - float(it["y0"])) > 0.5:
			var tt := (x - float(it["bx0"])) / maxf(1.0, float(it["bx1"]) - float(it["bx0"]))
			y = float(it["y0"]) + clampf(tt, 0.0, 1.0) * (float(it["y1"]) - float(it["y0"])) + float(it["yjit"])
		it["x"] = x
		it["dir"] = dir
		it["y"] = y
		var fr := float(it["frame"]) + delta * float(it["fps"])
		it["frame"] = fr
		var frames: Array = _npc_tex[String(it["kind"])]
		n.texture = frames[int(fr) % 4]
		var sc := float(it["sc"])
		n.scale = Vector2(sc, sc)
		n.flip_h = dir < 0.0
		n.position = Vector2(x, y - NPC_S * sc * 0.5 + (NPC_S - NPC_BASE) * sc)
		n.z_index = int(y)
		# 远景（长廊）轻微明灭，做出「若隐若现」
		if bool(it["shimmer"]):
			var base_a := float(it["a0"])
			n.modulate.a = base_a * (0.74 + 0.26 * (0.5 + 0.5 * sin(t * 0.55 + float(it["sph"]))))

	# ---- 宠物 ----
	for it2 in _pets:
		var pn: Sprite2D = it2["node"]
		var o: Dictionary = it2["owner"]
		var ox := float(o["x"])
		var oy := float(o["y"])
		var odir := float(o["dir"])
		var x2 := float(it2["x"])
		var y2 := float(it2["y"])
		var vx := float(it2["vx"])
		if bool(it2["follow"]):
			var gap := float(it2["base"]) + sin(t * 0.85 + float(it2["ph"])) * 9.0
			var tx := ox - odir * gap
			var d := tx - x2
			var want := clampf(d * 4.4, -90.0, 90.0)
			vx += (want - vx) * minf(1.0, delta * 6.0)
			x2 += vx * delta
			y2 += ((oy + 2.0) - y2) * minf(1.0, delta * 3.0)
			it2["frame"] = float(it2["frame"]) + absf(vx) * delta * 0.13
			var pd := 1.0 if vx >= 0.0 else -1.0
			if absf(vx) < 5.0:
				pd = odir
			it2["dir"] = pd
		else:
			var pdir := float(it2["dir"])
			x2 += 11.0 * pdir * delta
			it2["frame"] = float(it2["frame"]) + delta * 8.0
			y2 = 1286.0 + sin(t * 0.5 + float(it2["ph"])) * 14.0
			if x2 < 330.0:
				pdir = 1.0
			if x2 > 680.0:
				pdir = -1.0
			it2["dir"] = pdir
		it2["x"] = x2
		it2["y"] = y2
		it2["vx"] = vx
		var osc := float(o["sc"]) * 0.68
		var w := PET_S * osc
		var pframes: Array = _pet_tex[String(it2["kind"])]
		pn.texture = pframes[int(float(it2["frame"])) % 4]
		pn.scale = Vector2(osc, osc)
		pn.flip_h = float(it2["dir"]) < 0.0
		pn.position = Vector2(x2, y2 - w * 0.5 + (PET_S - PET_BASE) * osc)
		pn.modulate.a = minf(1.0, float(o["node"].modulate.a) * 1.04) * 0.85
		pn.z_index = int(y2)


func _update_cranes(delta: float) -> void:
	for it in _cranes:
		var n: Sprite2D = it["node"]
		var tt := float(it["t"]) + delta
		it["t"] = tt
		if tt < 0.0:
			n.visible = false
			continue
		var x := float(it["x"]) + float(it["vx"]) * delta
		var y := float(it["y"]) + float(it["vy"]) * delta
		# 飞出画面就换一只（新参数全部重掷）
		var out_x := x < -220.0 or x > DESIGN.x + 220.0
		var out_y := y < 24.0 or y > 330.0
		if out_x or out_y:
			var fresh := _new_crane(0.0, n, false)
			for k in fresh.keys():
				it[k] = fresh[k]
			it["t"] = 0.0
			n.visible = false
			continue
		it["x"] = x
		it["y"] = y
		n.visible = true
		n.z_index = 900
		var sc := float(it["sc"])
		n.scale = Vector2(sc, sc)
		# 扇翅：四帧循环，频率按体型给
		n.texture = _crane_tex[int(tt * float(it["flap"]) + float(it["fph"])) % 4]
		# 姿态：朝右用原图，朝左镜像；再按航向倾一点，爬升/下滑才看得出来
		var dirx := float(it["dir"])
		var ang := atan2(float(it["vy"]), float(it["vx"]))
		n.flip_h = dirx < 0.0
		n.rotation = ang if dirx > 0.0 else ang + PI
		n.position = Vector2(x, y + sin(tt * float(it["bf"]) + float(it["fph"])) * float(it["bob"]))
		# 进出画面时淡入淡出，别凭空出现
		var edge := minf(1.0, minf((x + 200.0) / 200.0, (DESIGN.x + 200.0 - x) / 200.0))
		n.modulate.a = float(it["a"]) * clampf(edge, 0.0, 1.0)
