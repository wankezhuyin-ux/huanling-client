## 战斗背景的横向卷动与无缝拼接（**当前是打开的**）。
##
## 做法：把同一张背景铺三块（`BattleBackground` / `Next` / `Next2`），
## 中间那块用原图的**水平镜像**，然后整体往左平移：
##   A | 镜像A | A | 镜像A …
## 镜像图的第一列和原图的最后一列是**同一列像素**，所以接缝像素级连续，
## 不用阴影带也不需要左右边缘对齐的专门素材（拿现成的图就能用）。
## 内容周期是两屏，走满两屏折回 0，贴图不换、画面完全一样，看不出来。
##
## 只平移背景，不碰战场格子：怪物站在格子上，格子坐标一旦跟着移，
## 飘字、受击、突进的落点全要跟着改，风险远大于收益。
## 所以「往前移动」只靠背景位移来表达，单位留在原地打——就是 DNF 过门那种感觉。
##
## ⚠ 「有没有接缝」只能按**屏幕上实际看得见的那两列**判，不能按原图左右边缘判。
## 三块铺贴都是 STRETCH_KEEP_ASPECT_COVERED，会按面板宽高比把源图居中裁一条：
##   面板高/宽 > 原图高/宽（暮还道 700/512≈1.37）→ 按高度铺满，左右各裁一截
## 一被裁，重复铺的接缝处拼起来的就不是原图左右边缘，而是图中间的两列 → 硬竖线。
## 裁多少由面板比例决定，所以同一张图**在不同比例的机型上表现不同**：
## 787x1005 那种偏矮的面板几乎不裁、缝看不出来；1080x2400 这种瘦长面板裁掉一大截，
## 缝就非常明显。判定必须走 _window_is_tileable()（按面板尺寸算可视列）。
extends Node
class_name BattleScrollWorld

## —— 背景卷动总开关 ——
##
## true  = 横向卷动 + 无缝拼接（当前用的就是这个）：背景一直往左走，做出「队伍在往前赶路」的观感。
## false = 静态背景：一张图铺满战场，**不拼接、不卷动**（老行为）。
##
## 做成 static var 而不是 const：自检脚本要能把它翻来翻去，两条路都得验。
static var ENABLED: bool = true

## 强制走「镜像拼接」：A | 镜像A | A | 镜像A …
##
## 默认关，改由「屏幕上真正相邻的那两列」自动判定（见 _window_is_tileable）：
##   · 两列接起来看不出竖线 → 同图重复铺，一屏一个周期，既无接缝也无镜像对称
##   · 能看出竖线 → 镜像拼接，接缝像素级连续
## 把这里固定成 true 会把所有图都拉回镜像模式，只在排查「到底走的是哪条路」时临时打开。
static var FORCE_MIRROR: bool = false

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

## 反过来：有的图左右两侧内容差得太多（赏月谷实测左边碎石密、右边泛白发虚），
## 同图重复铺时缝上会有一条「左虚右实」的竖界线 —— 这条界线是细节差，不是色差，
## 调色调/压阴影都盖不住（试过 edge_match + fade_seam + flatten_columns 三件套，
## 结果是缝两侧各 80 列被抹平，反而更像一条糊带）。
## 这类图直接走镜像拼接：A|镜像A 的接缝是**同一列像素**，绝对无缝，
## 代价是画面左右对称。用文件名（不含扩展名）匹配。
var force_mirror_maps: Array[String] = [
	"赏月谷",
]

## 可平铺判定：把**屏幕上真正相邻的两列**接起来，看会不会看到一条竖线。
##
## 以前用的是「原图左右边缘窄条的平均色差 ≤ 14」——两处都不对：
##   1) 判的是原图边缘，可 COVERED 会裁掉一条，缝上露出来的其实是图中间的两列；
##   2) 用「逐行差取绝对值的平均」当色差。人眼看到的竖线是「几百行都朝同一个方向偏」，
##      逐行 abs 会把正负抵消成噪声——实测一条 12 级（0~255）的硬缝能算成 0.1，
##      比普通相邻列还「平滑」，于是被判成可平铺，直接漏过去。
## 现在改成「整列有符号偏色」（先按通道求行均值再取绝对值），并叠一层分段检查，
## 免得「悬崖边缘上下对不齐」这种局部断裂被全图的平均抹平。
const SEAM_BIAS_MAX: float = 3.0
const SEAM_BAND_MAX: float = 6.0
const SEAM_BAND_ROWS: int = 48
## 面板尺寸变了（换设备 / 转屏 / 布局重排）超过这个像素数就重新判一次可平铺。
const RETILE_EPSILON: float = 2.0

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
var _mirror_mode: bool = false
var _seam_tex: Texture2D = null
## 上次判定可平铺时用的面板尺寸；_apply() 里发现尺寸变了就重判。
var _decided_panel_size: Vector2 = Vector2.ZERO
var _retile_pending: bool = false




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


## 换背景图（换地图）。顺带判定这张图能不能「重复铺」：
##   · 能 → 三张都用原图，周期一屏（无缝，也没有镜像对称）
##   · 不能 → 中间那张用原图的水平镜像，周期两屏（接缝像素级连续）
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
	# 判定用的是「面板尺寸」，所以尺寸变了要重判（见 _apply 里的 _schedule_retile）。
	var panel_size: Vector2 = _panel.size if is_instance_valid(_panel) else Vector2.ZERO
	_decided_panel_size = panel_size
	# 布局还没算出来（尺寸是 0）时只能按整图边缘判，判不准。等一帧拿到真尺寸再判一次。
	if panel_size.x <= 4.0 or panel_size.y <= 4.0:
		_schedule_retile()
	var tileable: bool = _window_is_tileable(source, panel_size)
	var want_mirror: bool = false
	if FORCE_MIRROR or _is_force_mirror(source):
		want_mirror = not _is_force_repeat(source)
	else:
		want_mirror = not tileable and not _is_force_repeat(source)
	# 同一张图重复调用时也要重新判一次：强制名单或面板比例可能刚变过。
	if _source_tex == source and want_mirror == _mirror_mode:
		return
	_source_tex = source
	_mirror_mode = want_mirror
	# 镜像拼接本身就是像素级连续，再压一条阴影带反而会变成「每隔一屏一条黑杠」，
	# 所以镜像模式下不建阴影带；只有「同一张图重复铺」（强制重复名单）才需要它兜底。
	_seam_needed = not want_mirror and not tileable
	if is_instance_valid(_seam):
		_seam.visible = _seam_needed
	if is_bound():
		_bg.texture = source
		# 镜像不再「翻出一张贴图」，直接用 TextureRect 自带的 flip_h：
		#   · 不占额外显存（512x700 的 RGBA 副本约 1.4MB）
		#   · 不依赖 get_image()/decompress() —— 那两条在部分机型上会失败，
		#     以前失败就静默退回「两张一样的图」，正好表现为一条硬缝
		#   · COVERED 的裁切窗口是居中的，翻采样等价于「翻整图再按同一窗口裁」，
		#     所以接缝两侧仍是同一列像素（tools/probe_battle_seam.gd 实测偏色 1.15 vs 普通列 0.46）
		_next.texture = source
		_next.flip_h = _mirror_mode
		if is_instance_valid(_next2):
			_next2.texture = source
		_refresh_cycle()
		_apply()


## 这张图在当前面板尺寸下能不能「重复铺」。
##
## 判的是**屏幕上真正会相邻的那两列**：COVERED 居中裁切之后，左块的右边缘是
## 源图第 `range.y` 列，右块的左边缘是源图第 `range.x` 列。这两列接起来有没有一条
## 竖线，才是玩家看到的东西。原图左右边缘对不对得上，跟这件事没关系。
func _window_is_tileable(tex: Texture2D, panel_size: Vector2) -> bool:
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null:
		return false
	if img.is_compressed():
		if img.decompress() != OK:
			return false
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 64 or h < 32:
		return false
	var cols: Vector2i = visible_source_columns(tex, panel_size)
	# 各留 1 列余量：边缘那一列在放大采样时会被 CLAMP 拉住，量它总是偏乐观。
	var left: int = clampi(cols.x + 1, 0, w - 1)
	var right: int = clampi(cols.y - 2, 0, w - 1)
	if right - left < 16:
		return false
	if _column_bias(img, left, right, 0, h) > SEAM_BIAS_MAX:
		return false
	# 分段再量一遍：全图平均会把「某一段对不上」（比如悬崖边缘高低错开）抹平，
	# 但玩家眼睛盯着的就是那一段。
	var y: int = 0
	while y + SEAM_BAND_ROWS <= h:
		if _column_bias(img, left, right, y, y + SEAM_BAND_ROWS) > SEAM_BAND_MAX:
			return false
		y += SEAM_BAND_ROWS
	return true


## 面板尺寸 → 屏幕上看得见的源图列范围 [x0, x1)（COVERED 居中裁切后的结果）。
##
## COVERED 的缩放比 = max(面板宽/图宽, 面板高/图高)，多出来的部分左右均分裁掉。
## 面板尺寸还没布局好（0）时退回整图，跟老行为一致。
func visible_source_columns(tex: Texture2D, panel_size: Vector2) -> Vector2i:
	if tex == null:
		return Vector2i(0, 0)
	var iw: float = float(tex.get_width())
	var ih: float = float(tex.get_height())
	if iw <= 1.0 or ih <= 1.0:
		return Vector2i(0, 0)
	if panel_size.x <= 4.0 or panel_size.y <= 4.0:
		return Vector2i(0, int(iw))
	var s: float = maxf(panel_size.x / iw, panel_size.y / ih)
	var drawn_w: float = iw * s
	var crop: float = maxf(0.0, (drawn_w - panel_size.x) * 0.5) / s
	return Vector2i(int(floor(crop)), int(ceil(iw - crop)))


## 两列的「整列偏色」（0~255）：先按通道求逐行有符号差的均值，再取绝对值。
## 用有符号均值而不是逐行 abs —— 竖线之所以扎眼，就是因为几百行都朝同一方向偏；
## 逐行 abs 会让正负互相抵消，把一条硬缝算成「比普通相邻列还平滑」。
func _column_bias(img: Image, xa: int, xb: int, y0: int, y1: int) -> float:
	var sr: float = 0.0
	var sg: float = 0.0
	var sb: float = 0.0
	var n: int = 0
	for y in range(y0, y1, 2):
		var ca: Color = img.get_pixel(xa, y)
		var cb: Color = img.get_pixel(xb, y)
		sr += ca.r - cb.r
		sg += ca.g - cb.g
		sb += ca.b - cb.b
		n += 1
	if n <= 0:
		return 0.0
	return (absf(sr / float(n)) + absf(sg / float(n)) + absf(sb / float(n))) / 3.0 * 255.0


## 这张图是否被强制走「重复铺」（见 force_repeat_maps）。
func _is_force_repeat(tex: Texture2D) -> bool:
	if force_repeat_maps.is_empty() or tex == null:
		return false
	var path: String = tex.resource_path
	if path.is_empty():
		return false
	var stem: String = path.get_file().get_basename()
	return force_repeat_maps.has(stem)


## 这张图是否被强制走「镜像拼接」（见 force_mirror_maps）。
func _is_force_mirror(tex: Texture2D) -> bool:
	if force_mirror_maps.is_empty() or tex == null:
		return false
	var path: String = tex.resource_path
	if path.is_empty():
		return false
	var stem: String = path.get_file().get_basename()
	return force_mirror_maps.has(stem)


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
	# 中间那块是镜像：用 TextureRect 自带的 flip_h，不另造一张翻转贴图。
	node.flip_h = _mirror_mode
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
	# 面板比例变了（换机型 / 转屏 / 战斗区重排）→ 可见列变了 → 可平铺与否可能翻盘。
	# 这一步只在尺寸有明显变化时触发，跑完 prepare() 里会把 _decided_panel_size 更新掉，
	# 不会来回抖。
	if _source_tex != null:
		if absf(pw - _decided_panel_size.x) > RETILE_EPSILON \
				or absf(ph - _decided_panel_size.y) > RETILE_EPSILON:
			_schedule_retile()
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


## 面板尺寸变了要重新判一次可平铺。用 deferred 调，别在 _apply() 里重入 prepare()。
func _schedule_retile() -> void:
	if _retile_pending or _source_tex == null:
		return
	_retile_pending = true
	_retile_now.call_deferred()


func _retile_now() -> void:
	_retile_pending = false
	if _source_tex == null or not is_instance_valid(_panel):
		return
	var sz: Vector2 = _panel.size
	if sz.x <= 4.0 or sz.y <= 4.0:
		# 还是没布局好。别在这里再排一次（会变成每帧重判），等 _apply() 拿到真尺寸自然会重判。
		return
	prepare(_source_tex)


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
