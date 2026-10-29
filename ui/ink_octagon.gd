extends Control
class_name InkOctagon

## 八角形框 —— 设计稿里宠物/道具头像统一是"切角"，不是圆角也不是方形。
##
## 为什么不用 NinePatchRect / StyleBoxFlat：
##   八角形的切角必须按当前尺寸算比例，拉伸的九宫格会把切角拉变形；
##   Panel 只能画矩形。所以这里直接 draw，一次静态绘制，开销可以忽略。
##
## 用法：
##   var f := InkOctagon.new()
##   f.line = tier_color
##   f.custom_minimum_size = Vector2(88, 88) * s
##   parent.add_child(f)   # 尺寸变化会自动重绘

## 内底：比面板更深的墨，让宠物图浮起来
var fill: Color = Color(0.020, 0.018, 0.014, 0.82)
## 描边：按成长档位上色（灰白/绿/蓝/金）
var line: Color = Color(0.788, 0.635, 0.294, 0.62)
var line_width: float = 1.0
## 切角占短边的比例：0.29 最接近设计稿的"八边"，再大就成菱形
var cut_ratio: float = 0.29
## 外扩柔光：稀有度越高，描边外侧透一点同色光（0 = 不画）
var halo: Color = Color(0, 0, 0, 0)


func _ready() -> void:
	resized.connect(queue_redraw)


func set_tier(col: Color, halo_alpha: float = 0.0) -> void:
	line = Color(col.r, col.g, col.b, 0.90)
	if halo_alpha > 0.0:
		halo = Color(col.r, col.g, col.b, halo_alpha)
	queue_redraw()


func _points(inset: float) -> PackedVector2Array:
	var w: float = maxf(size.x - inset * 2.0, 1.0)
	var h: float = maxf(size.y - inset * 2.0, 1.0)
	var c: float = minf(w, h) * cut_ratio
	var o := Vector2(inset, inset)
	var pts := PackedVector2Array()
	pts.append(o + Vector2(c, 0))
	pts.append(o + Vector2(w - c, 0))
	pts.append(o + Vector2(w, c))
	pts.append(o + Vector2(w, h - c))
	pts.append(o + Vector2(w - c, h))
	pts.append(o + Vector2(c, h))
	pts.append(o + Vector2(0, h - c))
	pts.append(o + Vector2(0, c))
	return pts


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	if halo.a > 0.0:
		draw_colored_polygon(_points(-2.0), halo)
	draw_colored_polygon(_points(0.0), fill)
	var ring := _points(0.0)
	ring.append(ring[0])
	draw_polyline(ring, line, line_width, true)
	# 内缩 3px 的暗线：八角框内侧压一圈，避免大图贴边显得"糊"
	var inner := _points(3.0)
	inner.append(inner[0])
	draw_polyline(inner, Color(0, 0, 0, 0.34), 1.0, true)
