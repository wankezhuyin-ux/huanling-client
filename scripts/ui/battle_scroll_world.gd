## 战斗背景的拼接与卷动（**当前是关闭的**）。
##
## 用户最终决定：背景不卷动、不拼接，一张图铺满战场，靠斜站位（我方左下、
## 敌方阵列朝右上铺开）表达纵深。所以 ENABLED 默认 false，走静态背景这条路：
## 只换贴图，不建第二/第三张铺贴，也不建接缝阴影带，更没有速度线。
##
## 下面是卷动那套的完整实现（用户说「先不重绘新图」时试过一段时间），
## 开关一翻就能回来，自检脚本两条路都验：
##   · 可平铺的新图（AI 出图时左右边缘做成一样的）：A=B=C=原图，周期 = 一屏。
##     接缝像素级连续，也没有镜像对称。
##   · 不可平铺的老图：A=原图，B=**原图的水平镜像**，C=原图，周期 = 两屏。
##     原图的右边缘与镜像图的左边缘是**同一列像素**，接缝天然无缝。
##     代价：屏幕上会出现左右镜像对称（一座山对称着出现两次）。
##
## 只平移背景，不碰战场格子：怪物站在格子上，格子坐标一旦跟着移，
## 飘字、受击、突进的落点全要跟着改，风险远大于收益。
extends Node
class_name BattleScrollWorld

## —— 背景卷动总开关 ——
##
## false = 静态背景：一张图铺满战场，**不拼接、不卷动、没有速度线**（当前用的就是这个）。
## true  = 老行为：横向卷动 + 无缝拼接（镜像）。
##
## 想再开卷动，把这里改成 true 即可，代码都还在。
## 做成 static var 而不是 const：自检脚本要能把它翻来翻去，两条路都得验。
static var ENABLED: bool = false

## 接缝阴影带的宽度（像素）。压在接缝正中，两侧各一半。
## 做得宽一点、软一点：窄而深的黑带反而像一条竖着画上去的线。
const SEAM_WIDTH: float = 220.0
## 接缝阴影的最深不透明度。太深会像一条黑杠，太浅压不住接缝的落差。
const SEAM_MAX_ALPHA: float = 0.6
## 镜像拼接时接缝本身已经无缝了，这条带子只剩「压住镜像轴」一个作用，
## 所以压得比普通模式轻一半，免得成了一条黑杠。
const SEAM_MAX_ALPHA_MIRROR: float = 0.3
## 接缝离屏幕边缘多近开始减弱阴影 —— 贴边的时候接缝本来就在屏幕外，
## 这时候还压一条黑带反而是杂质。
const SEAM_EDGE_FADE: float = 90.0

## 个别图有很强的地标（一座桥、一棵孤树、一道门），镜像后它会对称着出现两次，
## 看着像贴错了图。这些图可以列在这里，强制走「同一张重复铺」——
## 代价是接缝不连续（靠阴影带盖），但至少不会复制地标。
## 用文件名（不含扩展名）匹配，清单见 tools/map_tiling_report.csv（按「不对称度」排序）。
## 做成 var 而不是 const：自检脚本要能临时改它。
var force_repeat_maps: Array[String] = [
	# "mingyueqiao",
]

## 可平铺判定：AI 生成背景时把左右边缘做成相同（无缝平铺图），
## 这种图接缝天然对齐，不再需要阴影带。用左右边缘窄条的平均色差判断：
## 低于阈值视为可平铺。老图（边缘无关）判不过，继续走阴影带兜底。
const TILEABLE_EDGE_STRIP: int = 2
const TILEABLE_MAX_DIFF: float = 14.0

var _panel: Control = null
var _bg: TextureRect = null
var _next: TextureRect = null
var _next2: TextureRect = null
var _seam: TextureRect = null
var _seam_needed: bool = true
var _offset: float = 0.0
var _cycle: float = 0.0
var _tween: Tween = null
var _source_tex: Texture2D = null
var _mirror_tex: Texture2D = null
var _mirror_mode: bool = false
var _seam_tex: Texture2D = null


func bind(panel: Control, bg: TextureRect) -> void:
	_panel = panel
	_bg = bg
	if not is_instance_valid(_bg):
		return
	if not ENABLED:
		# 静态背景：只留一张铺满，不建第二张/第三张铺贴，也不建接缝阴影带。
		_seam_needed = false
		_cycle = 0.0
		return
	_ensure_next()
	_ensure_next2()
	_ensure_seam()
	_refresh_cycle()
	_apply()


func is_bound() -> bool:
	return is_instance_valid(_panel) and is_instance_valid(_bg) and is_instance_valid(_next)


## 换背景图（换地图）。顺带判定这张图是否可平铺：
##   · 可平铺 → 三张都用原图，周期一屏（无缝，也没有镜像对称）
##   · 不可平铺 → 中间那张用原图的水平镜像，周期两屏（接缝像素级连续）
func prepare(source: Texture2D) -> void:
	if source == null:
		return
	if not ENABLED:
		# 静态背景：换图就是换一张贴图，没有拼接、没有卷动。
		if _source_tex == source:
			return
		_source_tex = source
		if is_instance_valid(_bg):
			_bg.texture = source
		return
	var tileable: bool = _is_tileable(source)
	var want_mirror: bool = not tileable and not _is_force_repeat(source)
	# 同一张图重复调用时也要重新判一次：强制重复铺名单可能刚被改过。
	if _source_tex == source and want_mirror == _mirror_mode:
		return
	_source_tex = source
	_mirror_mode = want_mirror
	_seam_needed = not tileable
	_mirror_tex = null if not _mirror_mode else _make_mirrored(source)
	if is_instance_valid(_seam):
		_seam.visible = _seam_needed
	if is_bound():
		_bg.texture = source
		_next.texture = _mirror_tex if _mirror_tex != null else source
		if is_instance_valid(_next2):
			_next2.texture = source
		_refresh_cycle()
		_apply()


## 水平镜像一份贴图。原图的右边缘与镜像图的左边缘是同一列像素，
## 两张并排时接缝处像素完全连续 —— 这才是真无缝（阴影带只是盖住落差）。
func _make_mirrored(tex: Texture2D) -> Texture2D:
	var img: Image = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		if img.decompress() != OK:
			return null
	# ⚠ 必须 duplicate 再翻：Texture2D.get_image() 返回的可能是纹理内部缓冲的**引用**，
	# 直接 flip_x() 会把原贴图一起翻掉 —— 结果两张图内容完全一样，
	# 接缝根本不连续（实测：原图左右边缘直接对调了）。
	var flipped: Image = img.duplicate()
	flipped.flip_x()
	return ImageTexture.create_from_image(flipped)


## 左右边缘够接近 → 可平铺。比较两侧各 TILEABLE_EDGE_STRIP 列的平均色差。
func _is_tileable(tex: Texture2D) -> bool:
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null:
		return false
	if img.is_compressed():
		img.decompress()
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 64 or h < 32:
		return false
	var s: int = mini(TILEABLE_EDGE_STRIP, w / 4)
	var total: float = 0.0
	var n: int = 0
	for y in range(0, h, 4):
		for i in range(s):
			var ca: Color = img.get_pixel(i, y)
			var cb: Color = img.get_pixel(w - 1 - i, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	if n == 0:
		return false
	# 每通道平均差（0~1 标度），换算成 0~255 口径跟阈值比。
	var avg: float = total / float(n) / 3.0 * 255.0
	return avg <= TILEABLE_MAX_DIFF


## 这张图是否被强制走「重复铺」（见 force_repeat_maps）。
func _is_force_repeat(tex: Texture2D) -> bool:
	if force_repeat_maps.is_empty() or tex == null:
		return false
	var path: String = tex.resource_path
	if path.is_empty():
		return false
	var stem: String = path.get_file().get_basename()
	return force_repeat_maps.has(stem)


func tick(delta: float, speed: float) -> void:
	if not ENABLED or speed <= 0.0 or not is_bound():
		return
	if _cycle <= 0.0:
		_refresh_cycle()
	if _cycle <= 0.0:
		return
	_set_offset(_offset + speed * delta)


func advance(distance: float, duration: float) -> void:
	if duration <= 0.0:
		return
	if not ENABLED:
		return
	if not is_bound():
		return
	if _cycle <= 0.0:
		_refresh_cycle()
	if _cycle <= 0.0:
		return
	_stop_tween()
	var from: float = _offset
	var to: float = _offset + distance
	_tween = create_tween()
	_tween.tween_method(_set_offset, from, to, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## 兼容旧调用点：现在越过一屏会自动折回，不再需要「挑个瞬间跳回去」。
func wrap_now() -> bool:
	return false


func current_offset() -> float:
	return _offset


func reset() -> void:
	_stop_tween()
	_offset = 0.0
	_apply()


func _ensure_next() -> void:
	if is_instance_valid(_next):
		return
	var panel: Control = _panel
	if panel == null:
		return
	var node: TextureRect = panel.get_node_or_null("BattleBackgroundNext") as TextureRect
	if node == null:
		node = TextureRect.new()
		node.name = "BattleBackgroundNext"
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.z_index = 12
		panel.add_child(node)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_top = 0
	node.offset_bottom = 0
	_next = node
	if _source_tex != null and _next.texture != _source_tex:
		_next.texture = _source_tex


func _ensure_next2() -> void:
	if is_instance_valid(_next2):
		return
	var panel: Control = _panel
	if panel == null:
		return
	var node: TextureRect = panel.get_node_or_null("BattleBackgroundNext2") as TextureRect
	if node == null:
		node = TextureRect.new()
		node.name = "BattleBackgroundNext2"
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.z_index = 12
		panel.add_child(node)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_top = 0
	node.offset_bottom = 0
	_next2 = node
	if _source_tex != null and _next2.texture != _source_tex:
		_next2.texture = _source_tex


func _ensure_seam() -> void:
	if is_instance_valid(_seam):
		return
	var panel: Control = _panel
	if panel == null:
		return
	var node: TextureRect = panel.get_node_or_null("BattleBackgroundSeam") as TextureRect
	if node == null:
		node = TextureRect.new()
		node.name = "BattleBackgroundSeam"
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.z_index = 12
		node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node.stretch_mode = TextureRect.STRETCH_SCALE
		panel.add_child(node)
	if _seam_tex == null:
		_seam_tex = _build_seam_texture()
	node.texture = _seam_tex
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_top = 0
	node.offset_bottom = 0
	_seam = node


## 一条「黑 → 透明 → 黑」的横向渐变，用来压接缝。
func _build_seam_texture() -> Texture2D:
	var steps: int = int(SEAM_WIDTH)
	var img: Image = Image.create(steps, 1, false, Image.FORMAT_RGBA8)
	for x in range(steps):
		var t: float = (float(x) + 0.5) / float(steps)
		# 中间最黑、两侧全透明；用 sin 保证两端导数为 0，不会有硬边。
		var a: float = pow(sin(PI * t), 1.15) * SEAM_MAX_ALPHA
		img.set_pixel(x, 0, Color(0.02, 0.02, 0.03, a))
	return ImageTexture.create_from_image(img)




func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _set_offset(v: float) -> void:
	if _cycle > 0.0 and v >= _cycle:
		# 走满一屏就折回：两张铺贴内容相同，折回去画面完全一样，不会跳。
		var steps: int = int(floor(v / _cycle))
		steps = mini(steps, 8)
		v -= float(steps) * _cycle
	_offset = maxf(0.0, v)
	_apply()


func _apply() -> void:
	if not is_bound():
		return
	var pw: float = _panel.size.x
	var ph: float = _panel.size.y
	if pw < 32.0 or ph < 32.0:
		return
	# 三个节点都用 full rect 锚点，只写左右 offset。
	# 左右同时减同一个值 = 整体平移、宽度不变，COVERED 的缩放比例也就不会跳。
	# 早先试过把锚点摘成 TOP_LEFT 再改 position，那会把面板原本的布局打乱，
	# 结果整个屏幕变黑——面板里的 Control 不要轻易换锚点。
	_bg.offset_left = -_offset
	_bg.offset_right = -_offset
	_next.offset_left = pw - _offset
	_next.offset_right = pw - _offset
	if is_instance_valid(_next2):
		_next2.offset_left = pw * 2.0 - _offset
		_next2.offset_right = pw * 2.0 - _offset
	if is_instance_valid(_seam) and _seam_needed and _seam.visible:
		# 屏幕上那一条接缝的位置。镜像模式下内容周期是两屏，屏幕上可能露出的是
		# 第二条缝（A|镜像A 的缝在左侧时，露出来的是 镜像A|A 这条），
		# 所以要对一屏取模，不能直接用 pw - offset。
		var seam_x: float = pw - fmod(_offset, pw)
		_seam.offset_left = seam_x - SEAM_WIDTH * 0.5
		_seam.offset_right = seam_x + SEAM_WIDTH * 0.5 - pw
		# 接缝贴到屏幕边时把阴影收掉：那时接缝在视野外，压一条黑带只是杂质。
		var edge: float = minf(seam_x, pw - seam_x)
		var k: float = clampf(edge / SEAM_EDGE_FADE, 0.0, 1.0)
		# 镜像拼接时接缝本身像素级连续，这条带子只剩「压住镜像轴」的作用，压轻一半。
		var peak: float = SEAM_MAX_ALPHA_MIRROR if _mirror_mode else SEAM_MAX_ALPHA
		_seam.modulate = Color(1.0, 1.0, 1.0, k * (peak / maxf(0.001, SEAM_MAX_ALPHA)))


func _refresh_cycle() -> void:
	if not is_bound():
		_cycle = 0.0
		return
	_ensure_next()
	_ensure_next2()
	_cycle = _panel.size.x
	if _cycle < 32.0:
		_cycle = 0.0
		return
	# 镜像拼接的内容周期是「A + 镜像A」两屏（A|B|A|B…），折回点要对齐内容，
	# 否则折回的瞬间画面会从镜像跳回原图，肉眼可见地闪一下。
	if _mirror_mode:
		_cycle *= 2.0
	_apply()
