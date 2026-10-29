extends Control



const UIStyle = preload("res://scripts/ui_style.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")
const InventoryIconHelper = preload("res://scripts/ui/inventory_icon_helper.gd")

const HELP_TEXT: = "活动期内每天可领取 1 次，漏了下次上线继续领下一天，不必连着签。礼包和宠物蛋会进背包，需要自行打开。过了结束时间就不能再领。"
const BG_PATH: = "res://assets/ui/city/signin7_bg.jpg"
const GOLD_ICON_PATH: = "res://assets/items/jinbi_icon.png"

var game_manager = null
var _title_lbl: Label = null
var _status: Label = null
var _window_lbl: Label = null
var _days_grid: GridContainer = null
var _day7_slot: Control = null
var _claim_btn: Button = null
var _bg_rect: TextureRect = null
var _busy: bool = false
var _info: Dictionary = {}


static func create_fullscreen(manager) -> Control:
	var ui: = load("res://ui/city/signin7_ui.gd").new() as Control
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.offset_left = 0
	ui.offset_top = 0
	ui.offset_right = 0
	ui.offset_bottom = 0
	if ui.has_method("setup"):
		ui.call("setup", manager)
	return ui


func setup(gm) -> void :
	game_manager = gm
	_build_ui()
	call_deferred("_load_info")


func on_feature_shown(gm) -> void :
	if gm:
		game_manager = gm
	_load_info()


func _build_ui() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	if ResourceLoader.exists(BG_PATH):
		_bg_rect = TextureRect.new()
		_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg_rect.layout_mode = 1
		_bg_rect.anchor_left = 0.0
		_bg_rect.anchor_right = 1.0
		_bg_rect.anchor_top = 1.0
		_bg_rect.anchor_bottom = 1.0
		_bg_rect.offset_left = 0.0
		_bg_rect.offset_right = 0.0
		_bg_rect.offset_bottom = 0.0
		_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg_rect.texture = load(BG_PATH) as Texture2D
		add_child(_bg_rect)
		_fit_bg()
		_add_bg_veil()
		call_deferred("_fit_bg")

	var root: = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_right = -12
	root.offset_top = 8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head: = Control.new()
	head.custom_minimum_size = Vector2(0, 44)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(head)

	_title_lbl = UIStyle.create_title_label("七日签到领好礼")
	_title_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_lbl.offset_left = 48
	_title_lbl.offset_right = -48
	head.add_child(_title_lbl)

	var help_btn: = Button.new()
	help_btn.text = "?"
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.custom_minimum_size = Vector2(44, 44)
	help_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	help_btn.anchor_left = 1.0
	help_btn.anchor_right = 1.0
	help_btn.offset_left = -44
	help_btn.offset_right = 0
	help_btn.offset_top = -22
	help_btn.offset_bottom = 22
	UIStyle.apply_button_style(help_btn)
	TouchScrollUtils.bind_tap(help_btn, _on_help_pressed)
	head.add_child(help_btn)

	_status = Label.new()
	_status.text = "加载中…"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	root.add_child(_status)

	_window_lbl = Label.new()
	_window_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_window_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_window_lbl.add_theme_font_size_override("font_size", 14)
	_window_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	root.add_child(_window_lbl)

	var grid_host: = HBoxContainer.new()
	grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid_host.alignment = BoxContainer.ALIGNMENT_CENTER
	grid_host.add_theme_constant_override("separation", 10)
	root.add_child(grid_host)

	_days_grid = GridContainer.new()
	_days_grid.columns = 3
	_days_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_days_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_days_grid.size_flags_stretch_ratio = 3.0
	_days_grid.add_theme_constant_override("h_separation", 8)
	_days_grid.add_theme_constant_override("v_separation", 8)
	grid_host.add_child(_days_grid)

	_day7_slot = MarginContainer.new()
	_day7_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_day7_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_day7_slot.size_flags_stretch_ratio = 1.25
	_day7_slot.custom_minimum_size = Vector2(0, 304)
	grid_host.add_child(_day7_slot)

	_claim_btn = Button.new()
	_claim_btn.text = "领取"
	_claim_btn.focus_mode = Control.FOCUS_NONE
	_claim_btn.custom_minimum_size = Vector2(220, 48)
	_claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(_claim_btn)
	TouchScrollUtils.bind_tap(_claim_btn, _on_claim_pressed)
	root.add_child(_claim_btn)

	var spacer: = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)


func _notification(what: int) -> void :
	if what == NOTIFICATION_RESIZED:
		_fit_bg()


func _fit_bg() -> void :
	if _bg_rect == null:
		return
	var w: = size.x
	var h: = size.y
	if w < 8.0:
		w = 720.0
	if h < 8.0:
		h = 900.0

	var need_h: = w * 1280.0 / 720.0
	if need_h < h:
		need_h = h
	_bg_rect.offset_top = - need_h


func _add_bg_veil() -> void :
	var top_c: = Color(0.060, 0.068, 0.069)
	var grad: = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.26, 0.5, 1.0])
	grad.colors = PackedColorArray([
		Color(top_c.r, top_c.g, top_c.b, 0.97), 
		Color(top_c.r, top_c.g, top_c.b, 0.72), 
		Color(top_c.r, top_c.g, top_c.b, 0.0), 
		Color(top_c.r, top_c.g, top_c.b, 0.0), 
	])
	var gtex: = GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 8
	gtex.height = 256
	gtex.fill = GradientTexture2D.FILL_LINEAR
	gtex.fill_from = Vector2(0.5, 0.0)
	gtex.fill_to = Vector2(0.5, 1.0)
	var veil: = TextureRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.texture = gtex
	add_child(veil)


func _on_help_pressed() -> void :
	ConfirmDialog.show_message(self, "七日签到说明", HELP_TEXT)


func _load_info() -> void :
	if game_manager == null or game_manager.network == null:
		_status.text = "需要登录并连接服务器"
		return
	if not game_manager.network.is_logged_in():
		_status.text = "需要登录并连接服务器"
		return
	var res: Dictionary = await game_manager.network.signin7_info()
	if not bool(res.get("ok", false)):
		_status.text = str(res.get("message", res.get("error", "加载失败")))
		if _claim_btn:
			_claim_btn.disabled = true
		return
	var payload: Variant = res.get("data", {})
	_apply_info(payload if payload is Dictionary else {})


func _apply_info(data: Dictionary) -> void :
	_info = data
	if _title_lbl:
		_title_lbl.text = str(data.get("title", "七日签到领好礼"))
	if not bool(data.get("active", false)):
		var msg: = str(data.get("message", "活动未开启"))
		_status.text = msg if not msg.is_empty() else "活动未开启"
		_claim_btn.disabled = true
		_claim_btn.text = "领取"
	elif bool(data.get("finished", false)):
		_status.text = "本场奖励已全部领取"
		_claim_btn.disabled = true
		_claim_btn.text = "已领完"
	elif bool(data.get("can_claim", false)):
		_status.text = "今日奖励可领取"
		_claim_btn.disabled = false
		_claim_btn.text = "领取"
	else:
		_status.text = "今天已经领取过了，明天再来"
		_claim_btn.disabled = true
		_claim_btn.text = "明日再来"
	var start_s: = str(data.get("start_text", ""))
	var end_s: = str(data.get("end_text", ""))
	if not start_s.is_empty() and not end_s.is_empty():
		_window_lbl.text = "活动时间：%s 至 %s" % [start_s, end_s]
	else:
		_window_lbl.text = ""
	_rebuild_days(data.get("days", []) if data.get("days") is Array else [])


func _rebuild_days(days: Array) -> void :
	for c in _days_grid.get_children():
		c.queue_free()
	for c in _day7_slot.get_children():
		c.queue_free()
	var d1to6: Array = []
	var d7: Dictionary = {}
	for row in days:
		if not (row is Dictionary):
			continue
		var day: = int(row.get("day", 0))
		if day == 7:
			d7 = row
		elif day >= 1 and day <= 6:
			d1to6.append(row)
	d1to6.sort_custom( func(a, b): return int(a.get("day", 0)) < int(b.get("day", 0)))
	for row in d1to6:
		_days_grid.add_child(_make_day_card(row, false))
	if d7.is_empty():
		d7 = {"day": 7, "name": "第7天", "status": "locked"}
	_day7_slot.add_child(_make_day_card(d7, true))


func _status_text(st: String) -> String:
	match st:
		"claimed":
			return "已领取"
		"claimable":
			return "可领取"
		"waiting":
			return "待领取"
		_:
			return "未解锁"


func _make_panel_style(border: Color, thick: bool) -> StyleBoxFlat:
	var box: = StyleBoxFlat.new()
	box.bg_color = Color(0.066, 0.074, 0.074, 0.88)
	box.border_color = border
	var w: = 3 if thick else 2
	box.set_border_width_all(w)
	box.set_corner_radius_all(0)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _reward_icon(row: Dictionary) -> Texture2D:
	if str(row.get("type", "")) == "gold":
		if ResourceLoader.exists(GOLD_ICON_PATH):
			return load(GOLD_ICON_PATH) as Texture2D
		return InventoryIconHelper.category_icon_for_item_type("material")
	var item_name: = str(row.get("item_id", "")).strip_edges()
	if item_name.is_empty():
		return null
	if item_name.ends_with("礼包"):
		return InventoryIconHelper.category_icon_for_item_type("gift")
	if item_name.ends_with("宠物蛋"):
		return InventoryIconHelper.category_icon_for_item_type("pet_egg")
	if item_name.find("法宝碎片") >= 0 or item_name.begins_with("双倍经验符"):
		var named: = InventoryIconHelper.category_icon_for_inventory_item({"name": item_name})
		if named:
			return named
	return InventoryIconHelper.category_icon_for_item_type("item")


func _make_day_card(row: Dictionary, big: bool) -> Control:
	var st: = str(row.get("status", "locked"))
	var panel: = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if big else Control.SIZE_SHRINK_BEGIN
	if not big:
		panel.custom_minimum_size = Vector2(0, 148)
	var border: = Color(0.072, 0.080, 0.079)
	match st:
		"claimed":
			border = Color(0.35, 0.85, 0.5)
		"claimable":
			border = Color(1.0, 0.84, 0.3)
		"waiting":
			border = Color(0.072, 0.080, 0.079)
	if big and st != "claimed":
		border = Color(1.0, 0.84, 0.3)
	panel.add_theme_stylebox_override("panel", _make_panel_style(border, big))

	var inner: = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner)

	var day_n: = int(row.get("day", 0))
	var day_lbl: = Label.new()
	day_lbl.text = "第%d天" % day_n
	day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_lbl.add_theme_font_size_override("font_size", 18 if big else 15)
	day_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	inner.add_child(day_lbl)

	var icon_sz: = 96 if big else 56
	var tex: = _reward_icon(row)
	if tex:
		var ir: = TextureRect.new()
		ir.texture = tex
		ir.custom_minimum_size = Vector2(icon_sz, icon_sz)
		ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ir.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if st == "claimed" or st == "locked":
			ir.modulate = Color(0.669, 0.649, 0.598, 0.85)
		inner.add_child(ir)

	var name_lbl: = Label.new()
	name_lbl.text = str(row.get("name", ""))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	name_lbl.add_theme_font_size_override("font_size", 14 if big else 12)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	inner.add_child(name_lbl)

	var st_color: = Color(0.072, 0.080, 0.079)
	match st:
		"claimed":
			st_color = Color(0.4, 0.9, 0.5)
		"claimable":
			st_color = Color(1.0, 0.85, 0.35)
		"waiting":
			st_color = Color(0.072, 0.080, 0.079)
	var meta: = Label.new()
	meta.text = _status_text(st)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", st_color)
	inner.add_child(meta)
	return panel


func _apply_claim_rewards(data: Dictionary) -> void :
	if game_manager == null:
		return
	if data.has("newGold") and game_manager.player:
		game_manager.player.gold = int(data.get("newGold", game_manager.player.gold))
		if game_manager.has_signal("gold_changed"):
			game_manager.gold_changed.emit(game_manager.player.gold)
	if data.has("newYuanbao") and game_manager.player:
		game_manager.player.yuanbao_currency = int(data.get("newYuanbao", game_manager.player.yuanbao_currency))
		if game_manager.has_signal("yuanbao_changed"):
			game_manager.yuanbao_changed.emit(game_manager.player.yuanbao_currency)
	if data.get("inventoryData") is Dictionary and game_manager.inventory_manager:
		game_manager.inventory_manager.from_dict(data.get("inventoryData"))
		if game_manager.inventory_manager.has_signal("inventory_changed"):
			game_manager.inventory_manager.inventory_changed.emit()
	elif data.get("itemsGranted") is Array and game_manager.inventory_manager:
		for it in data.get("itemsGranted"):
			if it is Dictionary:
				var nm: = str(it.get("name", ""))
				var cnt: = int(it.get("count", 1))
				if nm != "" and cnt > 0:
					game_manager.inventory_manager.add_item(nm, cnt)
	if data.has("saveRevision") and game_manager.has_method("_set_cloud_save_revision"):
		game_manager._set_cloud_save_revision(int(data.get("saveRevision", -1)))


func _on_claim_pressed() -> void :
	if _busy:
		return
	if game_manager == null or game_manager.network == null:
		return
	_busy = true
	_claim_btn.disabled = true
	var res: Dictionary = await game_manager.network.signin7_claim()
	_busy = false
	if not bool(res.get("ok", false)):
		var msg: = str(res.get("message", ""))
		if msg.is_empty():
			msg = str(res.get("error", "领取失败"))
		ConfirmDialog.show_message(self, "领取失败", msg)
		await _load_info()
		return
	var payload: Variant = res.get("data", {})
	var data: Dictionary = payload if payload is Dictionary else {}
	_apply_claim_rewards(data)
	var ok_msg: = str(data.get("message", "领取成功"))
	if ok_msg.is_empty():
		ok_msg = "领取成功"
	ConfirmDialog.show_message(self, "领取成功", ok_msg)
	_apply_info(data)
