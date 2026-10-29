extends Control
class_name InkInnerLine

## 面板"第二根金线" —— 设计稿的框是两层：外沿 1px 亮金，内缩 5-6px 再压一根淡金。
## 单根线看起来像"截图边框"，双线才有"装裱"的厚度感。
##
## StyleBoxFlat 只能画一圈，所以这里单独 draw 一根内线，挂到面板子节点上，
## 锚点铺满、鼠标穿透，不影响布局也不吃点击。

var inset: float = 5.0
var line_color: Color = Color(0.788, 0.635, 0.294, 0.20)
var line_width: float = 1.0
## 是否在四角断开（宣纸"断口"效果，设计稿的角上是虚的）
var corner_gap: float = 0.0
## 顶边不画：页面级面板的顶沿交给金色光带（中间亮两端淡出），
## 再叠一根等宽实线就成了"两条线打架"，反而看不出光带
var skip_top: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x - inset * 2.0
	var h: float = size.y - inset * 2.0
	if w <= 2.0 or h <= 2.0:
		return
	if corner_gap <= 0.0:
		if skip_top:
			draw_line(Vector2(inset, inset + h), Vector2(inset + w, inset + h), line_color, line_width)
			draw_line(Vector2(inset, inset), Vector2(inset, inset + h), line_color, line_width)
			draw_line(Vector2(inset + w, inset), Vector2(inset + w, inset + h), line_color, line_width)
			return
		draw_rect(Rect2(inset, inset, w, h), line_color, false, line_width)
		return
	var g: float = minf(corner_gap, minf(w, h) * 0.24)
	var x0: float = inset
	var x1: float = inset + w
	var y0: float = inset
	var y1: float = inset + h
	# 四条边各留两端断口，比整框更像手绘装裱
	if not skip_top:
		draw_line(Vector2(x0 + g, y0), Vector2(x1 - g, y0), line_color, line_width)
	draw_line(Vector2(x0 + g, y1), Vector2(x1 - g, y1), line_color, line_width)
	draw_line(Vector2(x0, y0 + g), Vector2(x0, y1 - g), line_color, line_width)
	draw_line(Vector2(x1, y0 + g), Vector2(x1, y1 - g), line_color, line_width)
