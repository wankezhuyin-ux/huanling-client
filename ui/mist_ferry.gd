extends PanelContainer

# Each lantern lights or extinguishes itself and the adjacent moorings.
const CROSSINGS := [
	{"name": "芦花浅滩", "story": "雾吞了渡口。对岸的舟子约定，五盏岸灯齐明，才肯撑船。", "moves": [1, 3]},
	{"name": "沉钟水巷", "story": "水下传来钟声。舟子收起桨，等你照亮通往旧城的第二道水门。", "moves": [0, 2, 4]},
	{"name": "白鹿归津", "story": "一头白鹿站在最后的石阶上。它身后的归舟，还差一行灯火领路。", "moves": [0, 1, 3]},
]

var chapter := 0
var lights: Array[bool] = []
var turns := 0
var lanterns: Array[Button] = []
var heading := Label.new()
var passage := Label.new()
var report := Label.new()
var forward := Button.new()
var column := VBoxContainer.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _paper(Color("112c32"), Color("426266"), 0))
	var center := CenterContainer.new()
	add_child(center)
	column.custom_minimum_size.x = 540
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	_caption("渡 津 录     /     雾 渡 引 灯", 22, Color("dfbd80"))
	_format(heading, 48, Color("fff2d7"))
	_format(passage, 24, Color("d6e5de"))
	passage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption("点一盏灯，会同时翻转它与左右邻灯。", 22, Color("d6e5de"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for i in range(5):
		var lamp := Button.new()
		lamp.custom_minimum_size = Vector2(92, 116)
		lamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lamp.add_theme_font_size_override("font_size", 24)
		row.add_child(lamp)
		lamp.pressed.connect(_tap.bind(i))
		lanterns.append(lamp)
	_format(report, 22, Color("dfbd80"))
	column.add_child(forward)
	forward.custom_minimum_size.y = 68
	forward.pressed.connect(_advance)
	var leave := Button.new()
	leave.text = "返回洞府"
	leave.custom_minimum_size.y = 62
	column.add_child(leave)
	leave.pressed.connect(queue_free)
	_reset()

func _paper(fill: Color, edge: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style

func _format(label: Label, points: int, tint: Color) -> void:
	label.add_theme_font_size_override("font_size", points)
	label.add_theme_color_override("font_color", tint)
	column.add_child(label)

func _caption(words: String, points: int, tint: Color) -> void:
	var label := Label.new()
	label.text = words
	_format(label, points, tint)

func _flip(index: int) -> void:
	for i in range(maxi(0, index - 1), mini(5, index + 2)):
		lights[i] = not lights[i]

func _reset() -> void:
	lights.assign([true, true, true, true, true])
	for index in CROSSINGS[chapter].moves:
		_flip(index)
	turns = 0
	heading.text = CROSSINGS[chapter].name
	passage.text = CROSSINGS[chapter].story
	_refresh()

func _tap(index: int) -> void:
	if not lights.has(false):
		return
	_flip(index)
	turns += 1
	_refresh()

func _refresh() -> void:
	var solved := not lights.has(false)
	for i in range(5):
		var lamp := lanterns[i]
		var ink := Color("302813") if lights[i] else Color("bed4d0")
		var fill := Color("f2cc80") if lights[i] else Color("214047")
		lamp.text = "%s\n%s" % [["壹","贰","叁","肆","伍"][i], "明" if lights[i] else "暗"]
		lamp.disabled = solved
		for state in ["normal", "disabled", "hover", "pressed"]:
			lamp.add_theme_stylebox_override(state, _paper(fill.lightened(0.1) if state == "hover" else fill, ink, 16))
		for key in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color"]:
			lamp.add_theme_color_override(key, ink)
	report.text = "第 %d / 3 渡　·　已点灯 %d 次" % [chapter + 1, turns]
	forward.text = "重新布灯"
	if solved:
		report.text += "　·　渡口已通"
		forward.text = "驶向下一渡" if chapter < 2 else "白鹿已归津　·　回洞府"

func _advance() -> void:
	if not lights.has(false):
		if chapter == CROSSINGS.size() - 1:
			queue_free()
			return
		chapter += 1
	_reset()
