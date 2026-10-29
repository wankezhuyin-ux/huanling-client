extends RefCounted
class_name InkReskin

## 全局「去蓝」：把残留旧版蓝灰/亮蓝控件统一压进水墨暖墨金线。
##
## 为什么不在源码里逐处改色：整个工程有 40 多个文件、近 400 处偏蓝字面量
## （选择地图、加点方案、欢迎回来、旧弹窗、表格、旧面板…），手改既容易漏，
## 又容易把功能色（朱砂红 / 成功绿 / 金）改坏。
##
## 这里只认「明显偏蓝」的颜色，在运行时把它的明度重新映射到暖色轴：
##   深（面板底）→ 暖墨  中（分割线/描边）→ 暖棕  亮（文字/高光）→ 纸白/金
## 对红色、绿色、金色这类功能色零影响 —— 它们本来就不满足 is_blueish。

# 暖墨金线族的基准色（和 scripts/ui_style.gd 的 COLORS 同源）
const INK_DEEP := Color(0.055, 0.047, 0.035)
const INK_PANEL := Color(0.098, 0.086, 0.063)
const INK_MID := Color(0.300, 0.260, 0.200)
const INK_DIM := Color(0.640, 0.615, 0.560)
const INK_PAPER := Color(0.925, 0.898, 0.840)
const INK_GOLD := Color(0.788, 0.635, 0.294)
const INK_GOLD_HI := Color(0.950, 0.820, 0.550)

# 项目全局水墨主题（project.godot 里 gui/theme/custom 用的就是它）
const INK_THEME: Theme = preload("res://ui/ink_theme.tres")

# 需要扫的 stylebox 槽位：面板 + 按钮三态 + 页签 + 输入框 + 分割线
const STYLE_KEYS := [
	"panel", "normal", "hover", "pressed", "focus", "disabled",
	"selected", "selected_focus", "hover_pressed", "read_only",
	"tab_selected", "tab_unselected", "tab_hovered", "tab_disabled",
	"separator", "grabber", "grabber_highlight", "scroll", "scroll_focus",
	"embedded_border", "embedded_unfocused_border", "title_bar",
]

# 需要扫的颜色槽位：主要就是字体色和光标色
const COLOR_KEYS := [
	"font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
	"font_disabled_color", "font_hover_pressed_color", "font_outline_color",
	"font_selected_color", "font_unselected_color", "font_hovered_color",
	"font_placeholder_color", "caret_color", "default_color",
	"icon_normal_color", "icon_hover_color", "icon_pressed_color",
	"icon_disabled_color", "icon_focus_color",
]


## 判断一个颜色是不是「旧版蓝」。阈值分档：深色面板只要稍微偏蓝就算，
## 亮色则要求偏蓝更明显，避免把中性的纸白/浅灰误判。
static func is_blueish(c: Color) -> bool:
	if c.a <= 0.02:
		return false
	var mx: float = maxf(c.r, maxf(c.g, c.b))
	if mx <= 0.02:
		return false
	var thr: float = 0.016 if mx < 0.34 else 0.045
	if c.b <= c.r + thr:
		return false
	# 纯紫（r 和 b 都高、g 低）也算旧版冷色，一起收
	if c.b > c.g + 0.010:
		return true
	return false


## 面（背景）色：保留原明度，落在「暖墨 → 暖棕」这条轴上
static func surface(c: Color) -> Color:
	if not is_blueish(c):
		return c
	var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var out: Color
	if lum <= 0.10:
		out = INK_DEEP.lerp(INK_PANEL, clampf(lum / 0.10, 0.0, 1.0))
	elif lum <= 0.55:
		# 旧版控件的蓝底普遍在 0.3~0.45 明度，直接映射会变成"浅棕坨"
		# （加点方案里那条启用栏就是这样），这里压到 0.10~0.20，
		# 只比面板底色亮一点点，才是水墨皮里"被选中"的观感。
		out = INK_PANEL.lerp(Color(0.200, 0.175, 0.135), (lum - 0.10) / 0.45)
	else:
		out = Color(0.200, 0.175, 0.135).lerp(INK_DIM, clampf((lum - 0.55) / 0.40, 0.0, 1.0))
	out.a = c.a
	return out


## 线（描边/高光）色：一律转金，亮度越高越亮
static func accent(c: Color) -> Color:
	if not is_blueish(c):
		return c
	var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var out: Color = INK_GOLD.lerp(INK_GOLD_HI, clampf((lum - 0.40) / 0.45, 0.0, 1.0))
	out.a = c.a * (0.60 + clampf(lum, 0.0, 1.0) * 0.55)
	return out


## 字（文字/图标）色：亮度高的转纸白，中低转暖金/暖灰
static func text(c: Color) -> Color:
	if not is_blueish(c):
		return c
	var lum: float = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var out: Color
	if lum >= 0.70:
		out = INK_DIM.lerp(INK_PAPER, clampf((lum - 0.70) / 0.25, 0.0, 1.0))
	elif lum >= 0.40:
		out = INK_GOLD.lerp(INK_DIM, clampf((lum - 0.40) / 0.30, 0.0, 1.0))
	else:
		out = INK_MID.lerp(INK_GOLD, clampf(lum / 0.40, 0.0, 1.0))
	out.a = c.a
	return out


## 阴影色：偏蓝的投影统一压成纯黑，只保留透明度
static func shadow(c: Color) -> Color:
	if not is_blueish(c):
		return c
	return Color(0.0, 0.0, 0.0, clampf(c.a * 0.9, 0.0, 1.0))


static func _supports_theme(node: Node) -> bool:
	return (node is Control or node is Window) and node.has_method("has_theme_stylebox_override")


## 处理单个节点（Control 或 Window）。返回改写的槽位数量。
static func purge_node(node: Node) -> int:
	if not _supports_theme(node):
		return 0
	var changed: int = 0
	# Window 默认不继承项目主题，会掉回引擎默认的蓝灰皮（就是"有些弹窗到现在
	# 还是蓝的"的根因），这里统一补上水墨主题：字体、滚动条、默认控件样式一起换。
	if node is Window:
		var w: Window = node
		if w.theme == null:
			w.theme = INK_THEME
			changed += 1
	for key in STYLE_KEYS:
		if not node.call("has_theme_stylebox_override", key):
			continue
		var sb = node.call("get_theme_stylebox", key)
		if not (sb is StyleBoxFlat):
			continue
		var f: StyleBoxFlat = sb
		var nb: Color = surface(f.bg_color)
		var nc: Color = accent(f.border_color)
		var ns: Color = shadow(f.shadow_color)
		if nb == f.bg_color and nc == f.border_color and ns == f.shadow_color:
			continue
		var dup: StyleBoxFlat = f.duplicate()
		dup.bg_color = nb
		dup.border_color = nc
		dup.shadow_color = ns
		# 水墨皮是全直角语言（ui_style.gd 的弹窗一律 0 圆角），
		# 旧控件的 8~12px 大圆角一起平掉，否则一眼还看得出是"旧版控件"
		dup.set_corner_radius_all(0)
		node.call("add_theme_stylebox_override", key, dup)
		changed += 1
	for key in COLOR_KEYS:
		if not node.has_method("has_theme_color_override"):
			break
		if not node.call("has_theme_color_override", key):
			continue
		var col: Color = node.call("get_theme_color", key)
		var ncol: Color = text(col)
		if ncol == col:
			continue
		node.call("add_theme_color_override", key, ncol)
		changed += 1
	# ColorRect 直接拿 color 画，没有 theme 通道
	if node is ColorRect:
		var cr: ColorRect = node
		var ncr: Color = surface(cr.color)
		if ncr != cr.color:
			cr.color = ncr
			changed += 1
	return changed


## 递归处理整棵子树。root 自己也算。
static func purge_tree(root: Node) -> int:
	if root == null:
		return 0
	var changed: int = purge_node(root)
	for child in root.get_children():
		changed += purge_tree(child)
	return changed
