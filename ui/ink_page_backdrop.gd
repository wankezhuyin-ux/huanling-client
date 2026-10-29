extends Control
class_name InkPageBackdrop

## 内页统一底板 —— 让玩家"还在城里"，但零动态开销。
##
## 结构（自下而上）：
##   ① 主城水墨景的预烘焙虚化版（bg_page_blur.jpg，40KB，1/2.7 分辨率 + 高斯模糊）
##   ② 墨青色调层（把米黄景压成墨色，避免亮底压不住浅色字）
##   ③ 竖向明暗（顶部留一线光，底部压得更深给 dock 让位）
##   ④ 主题光晕（每页一个极淡的色，宠物青 / 战斗朱 / 图鉴金，制造"这页有性格"的记忆点）
##   ⑤ 四角暗角（收边，视线集中到中间面板）
##   ⑥ 纸纹颗粒（256×256 平铺，alpha 极低，去掉数字面板的"塑料感"）
##
## 全部是一次性静态绘制，没有任何 _process，也不含 shader。
## 主城动效在内页期间本来就是 PROCESS_MODE_DISABLED，所以从主城切内页时 GPU 负载是净下降的。

const BG_PATH := "res://assets/city_ink/bg_page_blur.jpg"
const GRAIN_PATH := "res://assets/city_ink/paper_grain.png"

## 虚化景的压暗倍率：先压到能看见山影，再靠 INK_TINT 压到墨色。
## 实测设计稿底板 = (17,14,10)，只靠 modulate 压会糊成一团棕，所以分两层：
## 第一层保留笔触结构，第二层用厚墨罩吃掉亮度、只留氤氲。
const SCENE_DIM := Color(0.34, 0.31, 0.27)
## 暖墨罩：alpha 0.78 才够"墨"，低于 0.7 会泛褐
const INK_TINT := Color(0.020, 0.017, 0.012, 0.78)

const ACCENT_GOLD := Color("#C9A24E")

## 主题色：让每页有色彩区分，但强度一致（都只是 0.1 级别）
const ACCENTS := {
	"pet": Color("#5E8C5A"),
	"warehouse": Color("#8A6A4A"),
	"bag": Color("#8A6A4A"),
	"battle": Color("#A8422E"),
	"atlas": Color("#C9A24E"),
	"settings": Color("#6A7E8C"),
	"shop": Color("#B98C4A"),
	"rank": Color("#7A6A9A"),
}

var _img: TextureRect
var _tint: ColorRect
var _shade: TextureRect
var _glow: TextureRect
var _vign: TextureRect
var _grain: TextureRect
var _accent: Color = Color("#C9A24E")
var _last_tag: String = ""
var _built: bool = false
var _fade: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()
	_fit()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_fit):
		vp.size_changed.connect(_fit)


## 兜底尺寸同步：这个节点挂在 MainUI 根上，而根的 size 在某些登录流程里
## 还是 (0,0)（anchors 尚未被 viewport 拉伸），anchors 算出来就是 0×0，
## 之后也没有 resize 事件 —— 表现是"visible=true 但整层什么都没画"。
## 内页本来就按 viewport 做设计坐标（见 _ink_s()），所以直接用视口尺寸。
func _fit() -> void:
	var ps := get_viewport_rect().size
	if ps.x <= 1.0 or ps.y <= 1.0:
		return
	if absf(size.x - ps.x) <= 0.5 and absf(size.y - ps.y) <= 0.5:
		return
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = ps
	position = Vector2.ZERO
	# 尺寸变了，视差也要按新尺寸重算
	if _img != null:
		_apply_shift(_img, _parallax_for(_last_tag))


func _build() -> void:
	if _built:
		return
	_built = true

	_img = TextureRect.new()
	_img.name = "Scene"
	_img.texture = load(BG_PATH)
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_img.modulate = SCENE_DIM
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_img)

	_tint = ColorRect.new()
	_tint.name = "InkTint"
	_tint.color = INK_TINT
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_tint)

	_shade = TextureRect.new()
	_shade.name = "Shade"
	_shade.texture = _vertical_shade()
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_shade)

	_glow = TextureRect.new()
	_glow.name = "AccentGlow"
	_glow.texture = _radial(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.0), Vector2(0.5, 0.12), 0.95)
	_glow.modulate = ACCENT_GOLD
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_glow)

	_vign = TextureRect.new()
	_vign.name = "Vignette"
	_vign.texture = _radial(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.34), Vector2(0.5, 0.5), 0.92)
	_vign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vign.stretch_mode = TextureRect.STRETCH_SCALE
	_vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_vign)

	_grain = TextureRect.new()
	_grain.name = "Grain"
	_grain.texture = load(GRAIN_PATH)
	_grain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_grain.stretch_mode = TextureRect.STRETCH_TILE
	_grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_grain.modulate = Color(1, 1, 1, 0.035)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_full(_grain)


func _add_full(node: Control) -> void:
	add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## 竖向明暗：顶部留光（标题区），底部压深（dock 区）
func _vertical_shade() -> GradientTexture2D:
	var g := Gradient.new()
	g.remove_point(1)
	g.add_point(0.14, Color(0.02, 0.03, 0.035, 0.18))
	g.add_point(0.52, Color(0.02, 0.03, 0.035, 0.26))
	g.add_point(0.82, Color(0.015, 0.022, 0.026, 0.42))
	g.add_point(1.0, Color(0.012, 0.018, 0.020, 0.54))
	g.set_color(0, Color(0.02, 0.03, 0.035, 0.10))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 8
	t.height = 512
	t.fill_from = Vector2(0.0, 0.0)
	t.fill_to = Vector2(0.0, 1.0)
	return t


func _radial(inner: Color, outer: Color, center: Vector2, radius: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	g.add_point(0.55, Color(inner.r, inner.g, inner.b, inner.a * 0.42))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 384
	t.height = 384
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = center
	t.fill_to = center + Vector2(radius, 0.0)
	return t


## 打开内页底板。navigation_tag 只用来选主题色和视差偏移（同一个城，不同窗口看出去的角度不同）
func open_for(navigation_tag: String = "", instant: bool = false) -> void:
	_build()
	_fit()
	var key := _accent_key(navigation_tag)
	_accent = ACCENTS.get(key, ACCENT_GOLD)
	_glow.modulate = _accent
	_last_tag = navigation_tag
	_apply_shift(_img, _parallax_for(navigation_tag))
	visible = true
	if instant:
		modulate.a = 1.0
		return
	if _fade != null and _fade.is_valid():
		_fade.kill()
	modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, 0.18).set_ease(Tween.EASE_OUT)


func close(instant: bool = false) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if instant or not visible:
		visible = false
		modulate.a = 0.0
		return
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.0, 0.14).set_ease(Tween.EASE_IN)
	_fade.tween_callback(func() -> void: visible = false)


func accent_color() -> Color:
	return _accent


func _accent_key(tag: String) -> String:
	var t := tag.strip_edges()
	if t.begins_with("city:"):
		t = t.substr(5)
	for k in ACCENTS.keys():
		if t.begins_with(k):
			return k
	if t == "local_warehouse" or t == "local_qiankun":
		return "warehouse"
	return ""


## 视差：按 tag 哈希到 ±2.2% 的横向偏移，避免每页背景一模一样
func _parallax_for(tag: String) -> Vector2:
	if tag.is_empty():
		return Vector2.ZERO
	var h := absi(hash(tag)) % 1000
	var fx := float(h) / 1000.0 - 0.5
	var fy := float((h / 7) % 1000) / 1000.0 - 0.5
	return Vector2(-fx * 0.045 * size.x, -fy * 0.02 * size.y)


## 全屏锚点下平移：四个 offset 同加减，尺寸不变
func _apply_shift(node: Control, p: Vector2) -> void:
	node.offset_left = p.x
	node.offset_top = p.y
	node.offset_right = p.x
	node.offset_bottom = p.y
