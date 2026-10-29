extends Control

## 弹窗「金属包边」——纯 draw 绘制，不依赖任何贴图，尺寸变了自动重画。
##
## 为什么不用 StyleBoxFlat 的 border：它只能一条等色描边，画出来是"细线框"，
## 这正是用户说的「太单薄」。金属感来自**厚度 + 倒角侧光**：
##   最外 1px 暗铁线 → 4px 金铜斜面（上/左提亮、下/右压暗，模拟左上打光）
##   → 1px 深色缝 → 1px 亮金内线 → 内缩 9px 一条暗金细线（双线框）
##   四角各一枚小菱形铆钉。
##
## 用法（不要用 class_name，避免全局类缓存没更新的老工程报未定义）：
##   const MetalFrameScript := preload("res://ui/metal_frame.gd")
##   var f = MetalFrameScript.new()
##   f.set_anchors_preset(Control.PRESET_FULL_RECT)
##   panel.add_child(f)   # 放在内容之前，才能被内容压住

@export var band: float = 5.0            ## 斜面厚度（像素）
@export var hairline_inset: float = 9.0  ## 内侧细线的内缩距离
@export var rivets: bool = true          ## 四角铆钉

const IRON := Color(0.075, 0.058, 0.032, 1.0)      ## 暗铁边
const DEEP := Color(0.329, 0.239, 0.094, 1.0)      ## 深铜
const MID := Color(0.596, 0.443, 0.169, 1.0)       ## 中金
const BRIGHT := Color(0.855, 0.702, 0.376, 1.0)    ## 亮金
const HI := Color(0.973, 0.910, 0.749, 1.0)        ## 高光


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < band * 5.0 or h < band * 5.0:
		return

	# ① 外缘：上/左一道金属高光、下/右压成暗铁 —— 侧光下金属条才有厚度，
	#    四边同色会退化成"一根线"
	draw_line(Vector2(0.5, 0.5), Vector2(w - 0.5, 0.5), Color(HI.r, HI.g, HI.b, 0.55), 1.0)
	draw_line(Vector2(0.5, 0.5), Vector2(0.5, h - 0.5), Color(HI.r, HI.g, HI.b, 0.42), 1.0)
	draw_line(Vector2(0.5, h - 0.5), Vector2(w - 0.5, h - 0.5), IRON, 1.0)
	draw_line(Vector2(w - 0.5, 0.5), Vector2(w - 0.5, h - 0.5), IRON, 1.0)

	# ② 斜面：逐像素叠线，越靠内越亮；上/左提亮、下/右压暗
	var steps: int = maxi(2, int(round(band)))
	for i in range(steps):
		var k: float = (float(i) + 0.5) / float(steps)
		var base: Color = DEEP.lerp(BRIGHT, k)
		var lit: Color = base.lerp(HI, 0.20)
		var shade: Color = base.darkened(0.24)
		var o: float = 1.0 + float(i) + 0.5
		draw_line(Vector2(o, o), Vector2(w - o, o), lit, 1.0)
		draw_line(Vector2(o, o), Vector2(o, h - o), lit, 1.0)
		draw_line(Vector2(o, h - o), Vector2(w - o, h - o), shade, 1.0)
		draw_line(Vector2(w - o, o), Vector2(w - o, h - o), shade, 1.0)

	# ③ 缝 + 亮金内线
	var g: float = 1.0 + float(steps)
	_outline(g + 0.5, IRON)
	_outline(g + 1.5, Color(BRIGHT.r, BRIGHT.g, BRIGHT.b, 0.62))

	# ④ 内衬细线（双线框的那一圈）
	_outline(hairline_inset + 0.5, Color(MID.r, MID.g, MID.b, 0.30))

	if rivets:
		_draw_rivets(w, h)


func _outline(inset: float, col: Color) -> void:
	var rw: float = size.x - inset * 2.0
	var rh: float = size.y - inset * 2.0
	if rw <= 0.0 or rh <= 0.0:
		return
	draw_rect(Rect2(inset, inset, rw, rh), col, false, 1.0)


func _draw_rivets(w: float, h: float) -> void:
	var d: float = hairline_inset + 8.0
	var r: float = maxf(2.5, band * 0.95)
	var corners := [Vector2(d, d), Vector2(w - d, d), Vector2(d, h - d), Vector2(w - d, h - d)]
	for c in corners:
		var outer := PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		draw_colored_polygon(outer, BRIGHT)
		var ir: float = r * 0.46
		var inner := PackedVector2Array([
			c + Vector2(0, -ir), c + Vector2(ir, 0), c + Vector2(0, ir), c + Vector2(-ir, 0)])
		draw_colored_polygon(inner, DEEP)
