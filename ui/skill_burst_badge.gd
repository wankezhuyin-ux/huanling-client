extends Control
## 战斗技能提示徽记（一闪而过的技能名，取代原先那张白色漫画爆炸星贴图）
##
## 设计取向：不要"实心小黑板"，要一道横着劈过去的光。
## 构图（后 → 前）：
##   1. 金芒    从字的两侧甩出去的锥形金线，起手时最亮，随 _intro 收束
##   2. 墨气    柔边暗色长条（skill_burst_soft.png），两端和上下都化开，战斗背景能透出来
##   3. 上下金线 两道末端渐隐的细金线，只留"框"的暗示，不封口
##   4. 光扫    起手 0.10s 内一道竖亮带从左掠到右，掠完就没
##   5. 火星    少量金屑，贴在字的两端
##   6. 技能名  深墨粗描边 → 金底 → 上金亮层 → 顶端白高光
## 节奏：整块只活 ~0.5s，入场 0.10s 内完成，出场 0.12s 淡掉（时间轴在 main_ui 的 tween 里）

const BADGE_FONT_PATH: = "res://assets/fonts/youshe_title.ttf"
const SOFT_TEX_PATH: = "res://assets/ui/skill_burst_soft.png"

const INK: = Color(0.045, 0.038, 0.052, 0.92)
const GOLD: = Color(1.0, 0.86, 0.44, 1.0)
const GOLD_LIGHT: = Color(1.0, 0.99, 0.92, 1.0)
const GOLD_DEEP: = Color(0.60, 0.32, 0.06, 1.0)

## 入场时长（秒）：越短越"闪"
const INTRO_TIME: = 0.10

## 显示文本（技能名）
var title: String = ""
## 字体覆盖：留空则用 BADGE_FONT_PATH；预览工具可塞 FontVariation 进来
var font_override: Font = null
## 主题色：控制金芒与光带色相，默认暖金
var accent: Color = Color(1.0, 0.74, 0.28, 1.0)

var _t: float = 0.0
var _intro: float = 0.0
var _font: Font = null
var _soft: Texture2D = null
var _spark_spec: Array = []
## 由 accent 派生：亮面 / 中层 / 深底，整枚徽记统一吃同一套主题色
var _hi: Color = Color(1, 1, 1)
var _mid: Color = Color(1, 0.86, 0.44)
var _deep: Color = Color(0.6, 0.32, 0.06)
var _ray_ang: Array = []


func _ready() -> void :
	_font = font_override if font_override != null else (load(BADGE_FONT_PATH) as Font)
	_hi = accent.lerp(Color(1.0, 1.0, 1.0), 0.55)
	_mid = accent.lerp(Color(1.0, 1.0, 1.0), 0.14)
	_deep = accent.darkened(0.58)
	_soft = load(SOFT_TEX_PATH) as Texture2D
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_geometry()
	set_process(true)
	_intro = 0.0


func _process(delta: float) -> void :
	_t += delta
	if _intro < 1.0:
		_intro = minf(1.0, _intro + delta / INTRO_TIME)
		queue_redraw()
		return
	# 入场结束后不再每帧重绘：这枚徽记只活半秒，省一点是一点
	if _t < 0.65:
		queue_redraw()


func _build_geometry() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash(title) if title != "" else 20261102
	_spark_spec.clear()
	for i in range(7):
		_spark_spec.append({
			"ang": rng.randf_range(0.0, TAU), 
			"spd": rng.randf_range(0.9, 2.2), 
			"size": rng.randf_range(0.7, 1.6), 
			"phase": rng.randf_range(0.0, 1.0), 
		})
	_ray_ang.clear()
	# 横向甩出的金芒：角度集中在左右两侧的上下斜坡上
	for i in range(10):
		var k: = float(i) / 9.0
		var ang: = lerpf(-0.62, 0.62, k)
		if i % 2 == 1:
			ang += PI
		_ray_ang.append(ang + rng.randf_range(-0.05, 0.05))


func _draw() -> void :
	var s: = minf(size.x, size.y)
	if s <= 4.0:
		return
	var c: = size * 0.5
	var R: = s * 0.42
	var metrics: = _title_metrics(R)
	var fs: int = metrics["fs"]
	var tw: float = metrics["tw"]
	var hw: = tw * 0.5 + R * 0.46
	var hh: = float(fs) * 0.60
	_draw_rays(c, R, hw, hh)
	_draw_ink_band(c, hw, hh, R)
	_draw_streaks(c, hw, hh, R)
	_draw_edges(c, hw, hh, R)
	_draw_sweep(c, hw, hh)
	_draw_sparks(c, R, hw, hh)
	_draw_title(c, R, fs, tw)
	_draw_intro_fx(c, R, hw, hh)


func _title_metrics(R: float) -> Dictionary:
	var fs: = int(clampf(R * 0.68, 15.0, 40.0))
	var tw: float = 0.0
	if _font != null and title != "":
		tw = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var limit: = R * 2.05
		if tw > limit and tw > 0.0:
			fs = maxi(11, int(float(fs) * limit / tw))
			tw = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return {"fs": fs, "tw": tw}


func _intro_k() -> float:
	# 1 → 0：入场瞬间最强，0.10s 内衰减到 0
	return clampf(1.0 - _intro, 0.0, 1.0)


## 金芒：起手一道亮甩，随后迅速收束、变淡
func _draw_rays(c: Vector2, R: float, hw: float, hh: float) -> void :
	var boost: = _intro_k()
	var a_base: = boost * 0.95
	for i in range(_ray_ang.size()):
		var a: float = float(_ray_ang[i])
		var ca: = cos(a)
		var sa: = sin(a)
		var r_edge: = minf(hw / maxf(absf(ca), 0.10), hh / maxf(absf(sa), 0.10))
		var r0: = r_edge * 0.94
		var reach: = lerpf(0.30, 1.10, boost)
		var r1: = r0 + R * reach * (0.7 + 0.5 * absf(sin(float(i) * 2.3)))
		if r1 <= r0:
			continue
		var half: = 0.030 + 0.012 * absf(sin(float(i) * 1.7))
		var p_in_l: = c + Vector2(cos(a - half), sin(a - half)) * r0
		var p_in_r: = c + Vector2(cos(a + half), sin(a + half)) * r0
		var p_tip: = c + Vector2(ca, sa) * r1
		var a_ray: = a_base
		draw_polygon(PackedVector2Array([p_in_l, p_in_r, p_tip]), PackedColorArray([
			Color(accent.r, accent.g, accent.b, a_ray), 
			Color(accent.r, accent.g, accent.b, a_ray), 
			Color(GOLD_LIGHT.r, GOLD_LIGHT.g, GOLD_LIGHT.b, 0.0), 
		]))
		# 刃线：一根更亮的细芯，闪一下就断
		var p_mid: = c + (Vector2(ca, sa) * r0 + Vector2(ca, sa) * (r1 * 0.92)) * 0.5
		draw_line(p_mid, c + Vector2(ca, sa) * (r1 * 0.92), Color(_hi.r, _hi.g, _hi.b, a_ray * 0.55), maxf(0.8, R * 0.014), true)


## 墨气长条：柔边贴图，不是实心板；上下两端化开，背景能透出来
func _draw_ink_band(c: Vector2, hw: float, hh: float, R: float) -> void :
	var boost: = _intro_k()
	var w: = hw * 2.0 * 1.06
	var h: = hh * 2.0 * 1.72
	var body: = 0.66 + 0.12 * boost
	if _soft != null:
		# 只留"烟"不留"板"：一层淡墨压住字底，边缘全化开
		var tint: Color = Color(_deep.r * 0.16 + 0.012, _deep.g * 0.16 + 0.010, _deep.b * 0.16 + 0.016)
		draw_texture_rect(_soft, Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), false, Color(tint.r, tint.g, tint.b, body))
		# 字正下方再补一小团，保证笔画不吃背景
		draw_texture_rect(_soft, Rect2(c.x - w * 0.31, c.y - h * 0.24, w * 0.62, h * 0.48), false, Color(0.014, 0.011, 0.018, 0.72))
	else:
		draw_rect(Rect2(c.x - hw, c.y - hh, hw * 2.0, hh * 2.0), Color(0.03, 0.025, 0.03, 0.7))


## 上下两道细金线：末端渐隐，不封口 —— 只给"框"的暗示
func _draw_edges(c: Vector2, hw: float, hh: float, R: float) -> void :
	var boost: = _intro_k()
	var alpha: = 0.72 + 0.28 * boost
	var thick: = maxf(1.4, R * 0.034)
	for sgn in [-1.0, 1.0]:
		var y: float = c.y + sgn * hh * 1.06
		var inner: float = 0.94
		var col_mid: = Color(_mid.r, _mid.g, _mid.b, alpha)
		for side in [-1.0, 1.0]:
			var x0: float = c.x
			var x1: float = c.x + side * hw * inner
			var seg: = 4
			for i in range(seg):
				var f0: = float(i) / float(seg)
				var f1: = float(i + 1) / float(seg)
				var a0: = lerpf(1.0, 0.0, smoothstep(0.25, 1.0, f0))
				var a1: = lerpf(1.0, 0.0, smoothstep(0.25, 1.0, f1))
				var p0: = Vector2(lerpf(x0, x1, f0), y)
				var p1: = Vector2(lerpf(x0, x1, f1), y)
				draw_polygon(PackedVector2Array([
					p0 + Vector2(0, -thick * 0.5), p1 + Vector2(0, -thick * 0.5), 
					p1 + Vector2(0, thick * 0.5), p0 + Vector2(0, thick * 0.5), 
				]), PackedColorArray([
					Color(col_mid.r, col_mid.g, col_mid.b, col_mid.a * a0), 
					Color(col_mid.r, col_mid.g, col_mid.b, col_mid.a * a1), 
					Color(col_mid.r, col_mid.g, col_mid.b, col_mid.a * a1), 
					Color(col_mid.r, col_mid.g, col_mid.b, col_mid.a * a0), 
				]))


## 横向速度线：从字的两端甩出去，越远越淡 —— 让整块有"横劈"的动势
func _draw_streaks(c: Vector2, hw: float, hh: float, R: float) -> void :
	var boost: = _intro_k()
	if boost <= 0.02:
		return
	var a: = 0.62 * boost
	var thick: = maxf(1.2, R * 0.026)
	for side in [-1.0, 1.0]:
		for k in range(2):
			var y: float = c.y + (float(k) - 0.5) * 2.0 * hh * 0.62
			var len_k: float = 1.0 - absf(float(k) - 0.5) * 0.60
			var x0: float = c.x + side * hw * 0.52
			var x1: float = c.x + side * hw * (1.05 + 0.85 * len_k)
			var seg: = 4
			for i in range(seg):
				var f0: = float(i) / float(seg)
				var f1: = float(i + 1) / float(seg)
				var a0: = (1.0 - f0) * a
				var a1: = (1.0 - f1) * a
				var p0: = Vector2(lerpf(x0, x1, f0), y)
				var p1: = Vector2(lerpf(x0, x1, f1), y)
				draw_polygon(PackedVector2Array([
					p0 + Vector2(0, -thick * 0.5), p1 + Vector2(0, -thick * 0.5), 
					p1 + Vector2(0, thick * 0.5), p0 + Vector2(0, thick * 0.5), 
				]), PackedColorArray([
					Color(_hi.r, _hi.g, _hi.b, a0), 
					Color(_hi.r, _hi.g, _hi.b, a1), 
					Color(_hi.r, _hi.g, _hi.b, a1), 
					Color(_hi.r, _hi.g, _hi.b, a0), 
				]))


## 光扫：起手 0.10s 内一道竖亮带从左掠到右，掠完即无
func _draw_sweep(c: Vector2, hw: float, hh: float) -> void :
	var boost: = _intro_k()
	if boost <= 0.02:
		return
	var k: = 1.0 - boost
	var x: float = lerpf(c.x - hw * 1.15, c.x + hw * 1.05, ease(k, 0.35))
	var band: float = hw * 0.34
	var top: float = c.y - hh * 1.75
	var bot: float = c.y + hh * 1.75
	var skew: float = hh * 0.55
	draw_polygon(PackedVector2Array([
		Vector2(x - band, bot), Vector2(x + band * 0.35, bot), 
		Vector2(x + band * 0.35 + skew, top), Vector2(x - band + skew, top), 
	]), PackedColorArray([
		Color(_hi.r, _hi.g, _hi.b, 0.0), 
		Color(_hi.r, _hi.g, _hi.b, 0.30 * boost), 
		Color(_hi.r, _hi.g, _hi.b, 0.34 * boost), 
		Color(_hi.r, _hi.g, _hi.b, 0.0), 
	]))
	draw_line(Vector2(x + skew * 0.6, top), Vector2(x, bot), Color(_hi.r, _hi.g, _hi.b, 0.55 * boost), maxf(1.0, hw * 0.010), true)


func _draw_sparks(c: Vector2, R: float, hw: float, hh: float) -> void :
	var boost: = _intro_k()
	if boost <= 0.02:
		return
	for spec in _spark_spec:
		var ph: float = fmod(_t * float(spec["spd"]) + float(spec["phase"]), 1.0)
		var side: float = -1.0 if int(float(spec["phase"]) * 10.0) % 2 == 0 else 1.0
		var x: float = c.x + side * hw * (0.85 + ph * 0.75)
		var y: float = c.y + sin(float(spec["ang"]) + ph * 2.2) * hh * 0.95
		var a: = (1.0 - ph) * 0.85 * boost
		draw_circle(Vector2(x, y), float(spec["size"]) * maxf(0.7, R * 0.020), Color(_hi.r, _hi.g, _hi.b, a))


func _draw_title(c: Vector2, R: float, fs: int, tw: float) -> void :
	if title == "" or _font == null:
		return
	var ascent: = _font.get_ascent(fs)
	var descent: = _font.get_descent(fs)
	var pos: = Vector2(c.x - tw * 0.5, c.y + (ascent - descent) * 0.44)
	draw_string_outline(_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(maxf(4.0, R * 0.13)), Color(0.06, 0.028, 0.012, 0.96))
	draw_string(_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _deep)
	draw_string(_font, pos - Vector2(0.0, maxf(1.0, float(fs) * 0.05)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _mid)
	draw_string(_font, pos - Vector2(0.0, maxf(1.8, float(fs) * 0.10)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(_hi.r, _hi.g, _hi.b, 0.40))
	# 起手第一帧：字顶一层白，砸一下就散
	var boost: = _intro_k()
	if boost > 0.45:
		draw_string(_font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 1.0, 1.0, (boost - 0.45) * 1.2))


## 入场特效：一道横扫白光（0.06s 内拉长消失）+ 文字边缘两记短冲击
func _draw_intro_fx(c: Vector2, R: float, hw: float, hh: float) -> void :
	var k: = 1.0 - _intro_k()
	if k >= 1.0:
		return
	if k < 0.60:
		var f: = 1.0 - k / 0.60
		var reach: = hw * (0.55 + 1.55 * (1.0 - k))
		var th: float = maxf(1.6, R * 0.085 * f)
		var a: float = 0.80 * f
		for side in [-1.0, 1.0]:
			var x0: float = c.x
			var x1: float = c.x + side * reach
			var seg: = 5
			for i in range(seg):
				var f0: = float(i) / float(seg)
				var f1: = float(i + 1) / float(seg)
				var t0: = 1.0 - f0
				var t1: = 1.0 - f1
				var p0: = Vector2(lerpf(x0, x1, f0), c.y)
				var p1: = Vector2(lerpf(x0, x1, f1), c.y)
				var h0: = th * (0.35 + 0.65 * t0)
				var h1: = th * (0.35 + 0.65 * t1)
				draw_polygon(PackedVector2Array([
					p0 + Vector2(0, -h0), p1 + Vector2(0, -h1), 
					p1 + Vector2(0, h1), p0 + Vector2(0, h0), 
				]), PackedColorArray([
					Color(1.0, 0.99, 0.94, a * t0), 
					Color(1.0, 0.99, 0.94, a * t1), 
					Color(1.0, 0.99, 0.94, a * t1), 
					Color(1.0, 0.99, 0.94, a * t0), 
				]))
	# 字两侧各一道竖直冲击，短、快、只闪一下
	if k < 0.35:
		var g: = 1.0 - k / 0.35
		var len: float = hh * (1.6 + 1.4 * (1.0 - k))
		for side in [-1.0, 1.0]:
			var x: float = c.x + side * hw * 0.98
			draw_line(Vector2(x, c.y - len), Vector2(x, c.y + len), Color(1.0, 0.98, 0.90, 0.55 * g), maxf(1.2, R * 0.030), true)


func _ellipse_points(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts: = PackedVector2Array()
	for i in range(n):
		var a: = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
