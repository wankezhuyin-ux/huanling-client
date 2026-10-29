extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const FestivalGiftConfig = preload("res://scripts/data/festival_gift_config.gd")
const ArenaConfig = preload("res://scripts/arena/arena_config.gd")
const YUANBAO_ICON = preload("res://assets/items/jinyuanbao.png")
const YUANBAO_SALE_DISCOUNT_RATE: float = 0.8
static var _shop_buy_in_flight: bool = false
static var _shop_click_cooldown_until_ms: int = 0
static var _active_shop_popup = null
static var _shop_loading_timer: Timer = null
static var _shop_loading_anim_label = null
static var _shop_loading_spinner_label = null
static var _shop_loading_tween = null
static var _main_shop_catalog_loaded: bool = false
static var _main_shop_catalog_inflight: bool = false
static var _main_shop_catalog_items: Array = []
static var _main_shop_sale_active: bool = false
static var _main_shop_sale_end_unix: int = 0
static var _main_shop_vip_tier: int = 0
static var _main_shop_catalog_waiters: Array = []

static func _shop_item_data(item_name: String) -> Dictionary:
	var resolved: Variant = GameData.resolve_item_def(str(item_name).strip_edges())
	if resolved is Dictionary:
		return resolved
	return {}

static func _enable_touch_drag_passthrough(root: Control) -> void :
	var root_keep_input: = (root is BaseButton) or (root is LineEdit) or (root is TextEdit) or (root is OptionButton) or (root is ScrollContainer)
	if not root_keep_input:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if not (child is Control):
			continue
		var c: = child as Control
		var keep_input: = (c is BaseButton) or (c is LineEdit) or (c is TextEdit) or (c is OptionButton) or (c is ScrollContainer)
		if not keep_input:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enable_touch_drag_passthrough(c)

static func _get_authoritative_shop_time(game_manager) -> int:
	if game_manager and game_manager.has_method("get_authoritative_unix_time"):
		var now_u: = int(game_manager.get_authoritative_unix_time(true))
		if now_u > 0:
			return now_u
	return -1

static func _get_local_festival_shop_sale(now_u: int) -> Dictionary:
	return FestivalGiftConfig.get_active_shop_sale(now_u)

static func _is_yuanbao_half_sale_active(game_manager) -> bool:
	var now_u: = _get_authoritative_shop_time(game_manager)
	if now_u <= 0:
		return false
	return not _get_local_festival_shop_sale(now_u).is_empty()

static func _resolve_buy_price(base_price: int, currency: String, game_manager) -> int:
	var safe_base: = maxi(0, int(base_price))
	if currency == "yuanbao" and _is_yuanbao_half_sale_active(game_manager):
		var now_u: = _get_authoritative_shop_time(game_manager)
		var sale: = _get_local_festival_shop_sale(now_u)
		var rate: = float(sale.get("discount_rate", YUANBAO_SALE_DISCOUNT_RATE))
		return maxi(1, int(floor(float(safe_base) * rate)))
	return safe_base

static func _format_seconds_compact(total_seconds: int) -> String:
	var remain: = maxi(0, int(total_seconds))
	var days: = remain / 86400
	remain -= days * 86400
	var hours: = remain / 3600
	remain -= hours * 3600
	var mins: = remain / 60
	var secs: = remain - mins * 60
	if days > 0:
		return "%d天%02d时%02d分%02d秒" % [days, hours, mins, secs]
	return "%02d时%02d分%02d秒" % [hours, mins, secs]

static func _get_yuanbao_items_cfg_fallback() -> Array:
	return [
		{"name": "开荒锦囊", "price": 500, "base_price": 500, "currency": "yuanbao"}, 
		{"name": "开荒宠装锦囊", "price": 500, "base_price": 500, "currency": "yuanbao"}, 
		{"name": "开悟丹锦囊", "price": 200, "base_price": 200, "currency": "yuanbao"}, 
		{
			"name": "宠物经验丹", 
			"price": 200, 
			"base_price": 200, 
			"currency": "yuanbao", 
			"hint": "需VIP3，今日剩余1/1", 
			"vip_required_tier": 3, 
			"daily_limit": 1, 
			"daily_remaining": 1, 
		}, 
		{"name": "双倍经验符", "price": 100, "base_price": 100, "currency": "yuanbao"}, 
		{"name": "双倍经验符·月", "price": 2900, "base_price": 2900, "currency": "yuanbao"}, 
		{"name": "双倍经验符·周", "price": 700, "base_price": 700, "currency": "yuanbao"}, 
		{"name": "六阶可进化宠锦囊", "price": 50, "base_price": 50, "currency": "yuanbao"}, 
		{"name": "七阶可进化宠锦囊", "price": 150, "base_price": 150, "currency": "yuanbao"}, 
		{"name": "八阶可进化宠锦囊", "price": 600, "base_price": 600, "currency": "yuanbao"}, 
		{"name": "七阶不可进化宠锦囊", "price": 150, "base_price": 150, "currency": "yuanbao"}, 
		{"name": "八阶不可进化宠锦囊", "price": 450, "base_price": 450, "currency": "yuanbao"}, 
		{"name": "宠物补章器", "price": 50, "base_price": 50, "currency": "yuanbao"}, 
	]

static func _get_yuanbao_items_cfg() -> Array:
	if not _main_shop_catalog_loaded or _main_shop_catalog_items.is_empty():
		return _get_yuanbao_items_cfg_fallback()
	var out: Array = []
	for it in _main_shop_catalog_items:
		if not (it is Dictionary):
			continue
		var d: Dictionary = it
		if String(d.get("currency", "")) != "yuanbao":
			continue
		var name: = String(d.get("itemName", "")).strip_edges()
		if name.is_empty():
			continue
		var base_price: = int(d.get("basePrice", 0))
		var final_price: = int(d.get("finalPrice", base_price))
		var hint: = ""
		var vip_req: = int(d.get("vipRequiredTier", 0))
		var daily_limit: = int(d.get("dailyLimit", 0))
		if vip_req > 0:
			hint = "需VIP%d" % vip_req
		if daily_limit > 0:
			var remain: = int(d.get("dailyRemaining", daily_limit))
			var limit_text: = "今日剩余%d/%d" % [maxi(0, remain), daily_limit]
			hint = "%s，%s" % [hint, limit_text] if not hint.is_empty() else "今日限购：%s" % limit_text
		out.append({
			"name": name, 
			"price": final_price, 
			"base_price": base_price, 
			"currency": "yuanbao", 
			"hint": hint, 
			"vip_required_tier": vip_req, 
			"daily_limit": daily_limit, 
			"daily_remaining": int(d.get("dailyRemaining", daily_limit)), 
		})
	return out

static func _get_gold_items_cfg_fallback() -> Array:
	return [
		{"name": "新手锦囊", "price": 1000, "base_price": 1000, "currency": "gold"}, 
	]

static func _get_gold_items_cfg() -> Array:
	if not _main_shop_catalog_loaded or _main_shop_catalog_items.is_empty():
		return _get_gold_items_cfg_fallback()
	var out: Array = []
	for it in _main_shop_catalog_items:
		if not (it is Dictionary):
			continue
		var d: Dictionary = it
		if String(d.get("currency", "")) != "gold":
			continue
		var name: = String(d.get("itemName", "")).strip_edges()
		if name.is_empty():
			continue
		var base_price: = int(d.get("basePrice", 0))
		var final_price: = int(d.get("finalPrice", base_price))
		out.append({
			"name": name, 
			"price": final_price, 
			"base_price": base_price, 
			"currency": "gold", 
		})
	return out

static func _get_friendship_items_cfg_fallback() -> Array:
	return [
		{"name": "金魂魄", "price": 50, "base_price": 50, "currency": "friendship"}, 
		{"name": "木魂魄", "price": 50, "base_price": 50, "currency": "friendship"}, 
		{"name": "水魂魄", "price": 50, "base_price": 50, "currency": "friendship"}, 
		{"name": "火魂魄", "price": 50, "base_price": 50, "currency": "friendship"}, 
		{"name": "土魂魄", "price": 50, "base_price": 50, "currency": "friendship"}, 
		{"name": "幻化符", "price": 100, "base_price": 100, "currency": "friendship"}, 
		{"name": "法宝洗练石", "price": 100, "base_price": 100, "currency": "friendship"}, 
		{"name": "极限武器", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "极限衣服", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "极限血佩", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "极限鞋子", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "极限内带", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "七阶可进化宠锦囊", "price": 100, "base_price": 100, "currency": "friendship"}, 
		{"name": "八阶可进化宠锦囊", "price": 300, "base_price": 300, "currency": "friendship"}, 
		{"name": "九阶可进化宠锦囊", "price": 500, "base_price": 500, "currency": "friendship"}, 
		{"name": "十阶可进化宠锦囊", "price": 900, "base_price": 900, "currency": "friendship"}, 
		{"name": "七阶不可进化宠锦囊", "price": 100, "base_price": 100, "currency": "friendship"}, 
		{"name": "八阶不可进化宠锦囊", "price": 250, "base_price": 250, "currency": "friendship"}, 
	]

static func _get_friendship_items_cfg() -> Array:
	if not _main_shop_catalog_loaded or _main_shop_catalog_items.is_empty():
		return _get_friendship_items_cfg_fallback()
	var out: Array = []
	for it in _main_shop_catalog_items:
		if not (it is Dictionary):
			continue
		var d: Dictionary = it
		if String(d.get("currency", "")) != "friendship":
			continue
		var name: = String(d.get("itemName", "")).strip_edges()
		if name.is_empty():
			continue
		var base_price: = int(d.get("basePrice", 0))
		var final_price: = int(d.get("finalPrice", base_price))
		out.append({
			"name": name, 
			"price": final_price, 
			"base_price": base_price, 
			"currency": "friendship", 
		})
	return out

static func _request_main_shop_catalog(game_manager, on_done: Callable = Callable()) -> void :
	if game_manager != null and game_manager.has_method("local_shop_catalog"):
		_main_shop_catalog_loaded = true
		_main_shop_catalog_items = game_manager.local_shop_catalog()
		_main_shop_vip_tier = load("res://scripts/vip_benefits.gd").tier_from_player(game_manager.player)
		if on_done.is_valid():
			on_done.call()
		return
	if _main_shop_catalog_inflight:
		if on_done.is_valid():
			_main_shop_catalog_waiters.append(on_done)
		return
	if game_manager == null or game_manager.network == null:
		return
	if not game_manager.network.has_method("get_main_shop_catalog"):
		return
	_main_shop_catalog_inflight = true
	var on_loaded: Callable
	var on_failed: Callable
	on_loaded = func(data: Dictionary):
		_main_shop_catalog_inflight = false
		_main_shop_catalog_loaded = true
		_main_shop_catalog_items = data.get("items", [])
		_main_shop_sale_active = bool(data.get("saleActive", false))
		_main_shop_sale_end_unix = int(data.get("saleEndUnix", _main_shop_sale_end_unix))
		_main_shop_vip_tier = int(data.get("vipTier", 0))
		if game_manager.network.main_shop_catalog_failed.is_connected(on_failed):
			game_manager.network.main_shop_catalog_failed.disconnect(on_failed)
		if on_done.is_valid():
			on_done.call()
		_flush_main_shop_catalog_waiters()
	on_failed = func(_err: String):
		_main_shop_catalog_inflight = false
		if game_manager.network.main_shop_catalog_loaded.is_connected(on_loaded):
			game_manager.network.main_shop_catalog_loaded.disconnect(on_loaded)
		if on_done.is_valid():
			on_done.call()
		_flush_main_shop_catalog_waiters()
	game_manager.network.main_shop_catalog_loaded.connect(on_loaded, CONNECT_ONE_SHOT)
	game_manager.network.main_shop_catalog_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.get_main_shop_catalog()

static func _flush_main_shop_catalog_waiters() -> void :
	var pending: Array = _main_shop_catalog_waiters.duplicate()
	_main_shop_catalog_waiters.clear()
	for cb in pending:
		if cb is Callable and (cb as Callable).is_valid():
			(cb as Callable).call()

static func _create_yuanbao_icon(size: Vector2 = Vector2(14, 14)) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = YUANBAO_ICON
	icon.custom_minimum_size = size
	icon.size = size
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


static func _create_item_icon(item_or_name, size: Vector2 = Vector2(72, 72)) -> TextureRect:
	var icon = TextureRect.new()
	var tex: Texture2D = null
	if item_or_name is String:
		tex = InventoryIconHelper.category_icon_for_inventory_item({"name": item_or_name})
	else:
		tex = InventoryIconHelper.category_icon_for_inventory_item(item_or_name)
	icon.texture = tex
	icon.custom_minimum_size = size
	icon.size = size
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

static func create_fullscreen(game_manager) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = UIStyle.create_base_vbox()
	panel.add_child(vbox)

	var title = UIStyle.create_title_label("🏪 商店街")
	vbox.add_child(title)

	var gold_label = Label.new()
	gold_label.text = "💰 金币: %d" % game_manager.player.gold
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(gold_label)

	var yuanbao_row = HBoxContainer.new()
	yuanbao_row.alignment = BoxContainer.ALIGNMENT_CENTER
	yuanbao_row.add_theme_constant_override("separation", 6)
	vbox.add_child(yuanbao_row)
	var yuanbao_icon = _create_yuanbao_icon(Vector2(14, 14))
	yuanbao_row.add_child(yuanbao_icon)
	var yuanbao_label = Label.new()
	yuanbao_label.text = "元宝: %d" % game_manager.player.yuanbao_currency
	yuanbao_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yuanbao_label.add_theme_font_size_override("font_size", 18)
	yuanbao_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
	yuanbao_row.add_child(yuanbao_label)

	var friendship_label = Label.new()
	friendship_label.text = "❤️ 友情点: %d" % int(game_manager.player.friendship_points)
	friendship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friendship_label.add_theme_font_size_override("font_size", 18)
	friendship_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.72))
	vbox.add_child(friendship_label)

	var arena_points_label = Label.new()
	arena_points_label.text = "⚔️ 上周结余竞技点: 0"
	arena_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arena_points_label.add_theme_font_size_override("font_size", 18)
	arena_points_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	arena_points_label.visible = false
	vbox.add_child(arena_points_label)
	panel.set_meta("arena_points_label", arena_points_label)
	var sale_countdown_label = Label.new()
	sale_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sale_countdown_label.add_theme_font_size_override("font_size", 16)
	sale_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	sale_countdown_label.visible = false
	vbox.add_child(sale_countdown_label)

	var tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 10)
	vbox.add_child(tab_container)

	var buy_tab_btn = Button.new()
	buy_tab_btn.text = "购买"
	buy_tab_btn.custom_minimum_size = Vector2(100, 40)
	buy_tab_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_tab_style(buy_tab_btn, true)
	tab_container.add_child(buy_tab_btn)

	var sell_tab_btn = Button.new()
	sell_tab_btn.text = "出售"
	sell_tab_btn.custom_minimum_size = Vector2(100, 40)
	sell_tab_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_tab_style(sell_tab_btn, false)
	tab_container.add_child(sell_tab_btn)


	var content_container = VBoxContainer.new()
	content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	vbox.add_child(content_container)

	var category_container = HBoxContainer.new()
	category_container.add_theme_constant_override("separation", 8)
	content_container.add_child(category_container)

	var current_category = {"value": "yuanbao_shop"}
	var current_mode = {"value": "buy"}
	var category_btns = []

	var categories = [
		{"id": "yuanbao_shop", "name": "元宝商店"}, 
		{"id": "gold_shop", "name": "金币商店"}, 
		{"id": "friendship_shop", "name": "友情点商店"}, 
		{"id": "arena_points_shop", "name": "竞技点商店"}, 
	]

	var refresh_sale_countdown = func():
		var now_u: = _get_authoritative_shop_time(game_manager)
		if now_u <= 0:
			sale_countdown_label.visible = false
			return
		var local_sale: = _get_local_festival_shop_sale(now_u)
		var sale_end_unix: = _main_shop_sale_end_unix if _main_shop_catalog_loaded else int(local_sale.get("end_unix", 0))
		var is_active: bool = _main_shop_sale_active if _main_shop_catalog_loaded else ( not local_sale.is_empty())
		var should_show: bool = is_active and String(current_mode.value) == "buy" and String(current_category.value) == "yuanbao_shop"
		sale_countdown_label.visible = should_show
		if not should_show:
			return
		var remain: = maxi(0, sale_end_unix - now_u)
		var banner_text: = str(local_sale.get("banner_text", "节日限时：元宝商店全场8折"))
		sale_countdown_label.text = "%s  剩余 %s" % [banner_text, _format_seconds_compact(remain)]

	for cat in categories:
		var cat_btn = Button.new()
		cat_btn.text = cat.name
		cat_btn.custom_minimum_size = Vector2(80, 35)
		cat_btn.add_theme_font_size_override("font_size", 16)
		UIStyle.apply_tab_style(cat_btn, cat.id == current_category.value)
		cat_btn.pressed.connect( func():
			current_category.value = cat.id
			for btn in category_btns:
				UIStyle.apply_tab_style(btn, btn.text == cat.name)
			if arena_points_label != null:
				arena_points_label.visible = (String(current_mode.value) == "buy" and String(current_category.value) == "arena_points_shop")
			_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
				current_mode.value, gold_label, yuanbao_label, friendship_label, panel)
			refresh_sale_countdown.call()
		)
		category_container.add_child(cat_btn)
		category_btns.append(cat_btn)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.name = "ScrollContainer"
	content_container.add_child(scroll)

	var items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	items_container.offset_left = 10
	items_container.offset_top = 10
	items_container.offset_right = -10
	items_container.offset_bottom = -10
	items_container.add_theme_constant_override("separation", 6)
	items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	items_container.name = "ItemsContainer"
	scroll.add_child(items_container)

	buy_tab_btn.pressed.connect( func():
		current_mode.value = "buy"
		UIStyle.apply_tab_style(buy_tab_btn, true)
		UIStyle.apply_tab_style(sell_tab_btn, false)
		_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
			current_mode.value, gold_label, yuanbao_label, friendship_label, panel)
		refresh_sale_countdown.call()
	)

	sell_tab_btn.pressed.connect( func():
		current_mode.value = "sell"
		UIStyle.apply_tab_style(sell_tab_btn, true)
		UIStyle.apply_tab_style(buy_tab_btn, false)
		_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
			current_mode.value, gold_label, yuanbao_label, friendship_label, panel)
		refresh_sale_countdown.call()
	)

	_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
		current_mode.value, gold_label, yuanbao_label, friendship_label, panel)

	var sale_countdown_timer: = Timer.new()
	sale_countdown_timer.wait_time = 1.0
	sale_countdown_timer.one_shot = false
	sale_countdown_timer.autostart = true
	panel.add_child(sale_countdown_timer)
	sale_countdown_timer.timeout.connect( func():
		refresh_sale_countdown.call()
	)
	refresh_sale_countdown.call()
	_request_main_shop_catalog(game_manager, func():
		_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
			current_mode.value, gold_label, yuanbao_label, friendship_label, panel)
		refresh_sale_countdown.call()
	)
	panel.visibility_changed.connect( func():
		if not panel.visible:
			return
		_refresh_content_fullscreen(content_container, game_manager, current_category.value, 
			current_mode.value, gold_label, yuanbao_label, friendship_label, panel)
		refresh_sale_countdown.call()
	)

	return panel

static func _refresh_content_fullscreen(content_container: VBoxContainer, game_manager, 
		category: String, mode: String, gold_label: Label, yuanbao_label: Label, friendship_label: Label, panel: Control):

	var scroll = content_container.get_node_or_null("ScrollContainer")
	if scroll == null:
		return

	var items_container = scroll.get_node_or_null("ItemsContainer")
	if items_container == null:
		return

	for child in items_container.get_children():
		child.queue_free()

	if is_instance_valid(panel):
		panel.set_meta("shop_list_category", category)
		panel.set_meta("shop_list_mode", mode)

	if mode == "buy":
		var refresh_buy_list: = func():
			if not is_instance_valid(content_container) or not is_instance_valid(panel):
				return
			var live_category: = str(panel.get_meta("shop_list_category", category))
			var live_mode: = str(panel.get_meta("shop_list_mode", mode))
			_refresh_content_fullscreen(content_container, game_manager, live_category, live_mode, gold_label, yuanbao_label, friendship_label, panel)
		_show_buy_items(items_container, game_manager, category, gold_label, yuanbao_label, friendship_label, panel, refresh_buy_list)
	else:
		_show_sell_items(items_container, game_manager, category, gold_label, yuanbao_label, friendship_label, panel)

static func _show_buy_items(container: VBoxContainer, game_manager, 
		category: String, gold_label: Label, yuanbao_label: Label, friendship_label: Label, parent_control: Control, 
		on_bought: Callable = Callable()):

	if category == "gold_shop":
		_show_configured_shop(
			container, 
			game_manager, 
			_get_gold_items_cfg(), 
			gold_label, 
			yuanbao_label, 
			friendship_label, 
			parent_control, 
			on_bought
		)
	elif category == "yuanbao_shop":
		_show_configured_shop(
			container, 
			game_manager, 
			_get_yuanbao_items_cfg(), 
			gold_label, 
			yuanbao_label, 
			friendship_label, 
			parent_control, 
			on_bought
		)
	elif category == "friendship_shop":
		_show_configured_shop(
			container, 
			game_manager, 
			_get_friendship_items_cfg(), 
			gold_label, 
			yuanbao_label, 
			friendship_label, 
			parent_control, 
			on_bought
		)
	elif category == "arena_points_shop":
		_show_arena_points_shop(container, game_manager, parent_control)

static func _show_arena_points_shop(container: VBoxContainer, game_manager, parent_control: Control) -> void :
	if game_manager == null or game_manager.network == null:
		var err: = Label.new()
		err.text = "未登录，无法打开竞技点商店"
		container.add_child(err)
		return
	var loading: = Label.new()
	loading.text = "加载竞技点商店..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(loading)
	_load_arena_points_shop_async(container, game_manager, parent_control, loading)

static func _load_arena_points_shop_async(container: VBoxContainer, game_manager, parent_control: Control, loading: Label) -> void :
	var res: Dictionary = await game_manager.network.request_arena_shop_items()
	if loading != null and is_instance_valid(loading):
		loading.queue_free()
	if container == null or not is_instance_valid(container):
		return
	var arena_label: Label = null
	if parent_control != null and parent_control.has_meta("arena_points_label"):
		arena_label = parent_control.get_meta("arena_points_label") as Label
	var balance: = ArenaConfig.resolve_balance_points(res)
	if arena_label != null:
		arena_label.text = "⚔️ 上周结余竞技点: %d" % balance
		arena_label.visible = true
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		var fail: = Label.new()
		fail.text = str(res.get("error", "加载竞技点商店失败"))
		container.add_child(fail)
		return
	var items: Array = res.get("items", []) if res.get("items") is Array else []
	if items.is_empty():
		items = ArenaConfig.FALLBACK_SHOP_ITEMS
	for cfg in items:
		if typeof(cfg) != TYPE_DICTIONARY:
			continue
		var item_id: = str(cfg.get("id", "")).strip_edges()
		var item_name: = str(cfg.get("itemName", cfg.get("item_name", ""))).strip_edges()
		var cost: = int(cfg.get("cost", 0))
		if item_id.is_empty() or item_name.is_empty() or cost <= 0:
			continue
		var item_data: Dictionary = _shop_item_data(item_name)
		if item_data.is_empty():
			continue
		var item_panel = Panel.new()
		item_panel.custom_minimum_size = Vector2(0, 120)
		var panel_style = UIStyle.create_item_style()
		item_panel.add_theme_stylebox_override("panel", panel_style)
		container.add_child(item_panel)
		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)

		hbox.offset_left = 10
		hbox.offset_top = 5
		hbox.offset_right = -10
		hbox.offset_bottom = -5
		hbox.add_theme_constant_override("separation", 8)
		item_panel.add_child(hbox)
		hbox.add_child(_create_item_icon(item_name, Vector2(102, 102)))
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		var name_label = Label.new()
		name_label.text = item_name
		name_label.add_theme_font_size_override("font_size", 22)
		info_vbox.add_child(name_label)
		var price_label = Label.new()
		price_label.text = "消耗上周结余竞技点: %d" % cost
		price_label.add_theme_font_size_override("font_size", 17)
		price_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		info_vbox.add_child(price_label)
		var captured_id: = item_id
		var captured_name: = item_name
		var captured_cost: = cost
		var captured_balance: = balance
		var actions: = _create_buy_batch_column("兑换")
		var buy_btn: = actions.get_child(0) as Button
		var batch_btn: = actions.get_child(1) as Button
		var cannot_afford: = captured_balance < captured_cost
		buy_btn.disabled = cannot_afford
		batch_btn.disabled = cannot_afford
		buy_btn.pressed.connect( func():
			_buy_arena_shop_item(game_manager, container, parent_control, captured_id, captured_name, captured_cost, 1)
		)
		batch_btn.pressed.connect( func():
			var max_count: = _max_count_by_balance(captured_balance, captured_cost, 0, 0)
			if max_count < 1:
				_safe_show_message(parent_control, "上周结余竞技点不足，无法兑换。")
				return
			_show_quantity_cost_dialog(parent_control, "批量购买", max_count, captured_cost, "上周结余竞技点", func(buy_count: int):
				_buy_arena_shop_item(game_manager, container, parent_control, captured_id, captured_name, captured_cost, buy_count)
			)
		)
		hbox.add_child(actions)

static func _buy_arena_shop_item(game_manager, container: VBoxContainer, parent_control: Control, item_id: String, item_name: String, cost: int, quantity: int = 1) -> void :
	if game_manager == null or game_manager.network == null:
		return
	if _shop_buy_in_flight:
		_safe_show_message(parent_control, "有一笔购买正在处理中，请稍候。")
		return
	var qty: = clampi(quantity, 1, 999)
	_shop_buy_in_flight = true
	var op_id: = "arena_shop_%s_%d_%d" % [item_id, qty, Time.get_unix_time_from_system()]
	var res: Dictionary = await game_manager.network.request_arena_shop_buy(item_id, op_id, qty)
	_shop_buy_in_flight = false
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		_show_message(parent_control, str(res.get("error", "兑换失败")))
		return
	if game_manager.inventory_manager:
		game_manager.inventory_manager.add_item(item_name, qty)
	if qty > 1:
		_show_message(parent_control, "兑换成功：%s x%d" % [item_name, qty])
	else:
		_show_message(parent_control, "兑换成功：%s" % item_name)
	_show_arena_points_shop(container, game_manager, parent_control)

static func _show_configured_shop(container: VBoxContainer, game_manager, items_cfg: Array, 
		gold_label: Label, yuanbao_label: Label, friendship_label: Label, parent_control: Control, 
		on_bought: Callable = Callable()):
	for cfg in items_cfg:
		var item_name: = str(cfg.get("name", ""))
		var base_price: = int(cfg.get("base_price", cfg.get("price", 0)))
		var price: = int(cfg.get("price", base_price))
		var currency: = str(cfg.get("currency", "gold"))
		var final_price: = int(price if price > 0 else _resolve_buy_price(base_price, currency, game_manager))
		var hint_text: = String(cfg.get("hint", "")).strip_edges()
		var vip_required_tier: = int(cfg.get("vip_required_tier", 0))
		var daily_limit: = int(cfg.get("daily_limit", 0))
		var daily_remaining: = int(cfg.get("daily_remaining", daily_limit))
		if item_name.is_empty() or price <= 0:
			continue
		var item_data: Dictionary = _shop_item_data(item_name)
		if item_data.is_empty():
			continue

		var item_panel = Panel.new()

		item_panel.custom_minimum_size = Vector2(0, 156)
		item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		container.add_child(item_panel)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 5
		hbox.offset_right = -10
		hbox.offset_bottom = -5
		hbox.add_theme_constant_override("separation", 8)
		item_panel.add_child(hbox)

		hbox.add_child(_create_item_icon(item_name, Vector2(102, 102)))

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(info_vbox)

		var name_label = Label.new()
		name_label.text = item_name
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		var desc_text: = str(item_data.get("desc", ""))
		desc_label.text = desc_text
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		desc_label.custom_minimum_size = Vector2(0, 66)
		desc_label.add_theme_font_size_override("font_size", 17)
		desc_label.add_theme_color_override("font_color", Color(0.669, 0.649, 0.598))
		info_vbox.add_child(desc_label)

		if not hint_text.is_empty():
			var hint_label = Label.new()
			hint_label.text = hint_text
			hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			hint_label.add_theme_font_size_override("font_size", 15)

			hint_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
			info_vbox.add_child(hint_label)

		if currency == "yuanbao":
			var price_box = HBoxContainer.new()
			price_box.alignment = BoxContainer.ALIGNMENT_CENTER
			price_box.add_theme_constant_override("separation", 4)
			var price_icon = _create_yuanbao_icon(Vector2(18, 18))
			price_box.add_child(price_icon)
			var price_label = Label.new()
			price_label.text = "%d" % final_price
			if final_price < price:
				price_label.text = "%d (原价%d)" % [final_price, price]
			price_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
			price_label.add_theme_font_size_override("font_size", 18)
			price_box.add_child(price_label)
			hbox.add_child(price_box)
		elif currency == "friendship":
			var fp_label = Label.new()
			fp_label.text = "❤️ %d 友情点" % final_price
			fp_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.72))
			fp_label.add_theme_font_size_override("font_size", 18)
			hbox.add_child(fp_label)
		else:
			var price_label = Label.new()
			price_label.text = "💰 %d" % final_price
			price_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			price_label.add_theme_font_size_override("font_size", 18)
			hbox.add_child(price_label)

		var captured_name: = item_name
		var captured_base: = base_price
		var captured_currency: = currency
		var captured_final: = final_price
		var captured_hint: = hint_text
		var captured_vip: = vip_required_tier
		var captured_limit: = daily_limit
		var captured_remain: = daily_remaining
		var actions: = _create_buy_batch_column("购买")
		var buy_btn: = actions.get_child(0) as Button
		var batch_btn: = actions.get_child(1) as Button
		buy_btn.pressed.connect( func():
			if not _begin_shop_click():
				return
			if not _guard_configured_buy(parent_control, captured_vip, captured_limit, captured_remain):
				return
			var latest_price: = captured_final
			var price_text: = "%d %s" % [latest_price, _currency_unit_name(captured_currency)]
			if captured_currency == "yuanbao" and latest_price < captured_base:
				price_text = "%d 元宝（原价%d）" % [latest_price, captured_base]
			var confirm_msg: = "确定购买【%s】吗？\n将消耗：%s" % [captured_name, price_text]
			if not captured_hint.is_empty():
				confirm_msg += "\n购买条件：%s" % captured_hint
			_show_confirm(
				parent_control, 
				confirm_msg, 
				func():
					_buy_configured_item(game_manager, captured_name, captured_base, captured_currency, gold_label, yuanbao_label, friendship_label, parent_control, latest_price, 1, on_bought), 
				"确认购买"
			)
		)
		batch_btn.pressed.connect( func():
			if not _begin_shop_click():
				return
			if not _guard_configured_buy(parent_control, captured_vip, captured_limit, captured_remain):
				return
			var max_count: = _max_affordable_buy_count(game_manager, captured_currency, captured_final, captured_limit, captured_remain)
			if max_count < 1:
				_safe_show_message(parent_control, _insufficient_currency_text(captured_currency))
				return
			_show_quantity_cost_dialog(parent_control, "批量购买", max_count, captured_final, _currency_unit_name(captured_currency), func(buy_count: int):
				_buy_configured_item(game_manager, captured_name, captured_base, captured_currency, gold_label, yuanbao_label, friendship_label, parent_control, captured_final, buy_count, on_bought)
			)
		)
		hbox.add_child(actions)
		_enable_touch_drag_passthrough(item_panel)

static func _create_buy_batch_column(primary_text: String) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 6)
	var primary: = Button.new()
	primary.text = primary_text
	primary.custom_minimum_size = Vector2(88, 48)
	primary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	primary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	primary.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_golden_button_style(primary)
	col.add_child(primary)
	var batch: = Button.new()
	batch.text = "批量"
	batch.custom_minimum_size = Vector2(88, 48)
	batch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	batch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	batch.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(batch)
	col.add_child(batch)
	return col

static func _begin_shop_click() -> bool:
	var now_ms: = Time.get_ticks_msec()
	if now_ms < _shop_click_cooldown_until_ms:
		return false
	_shop_click_cooldown_until_ms = now_ms + 1000
	return true

static func _guard_configured_buy(parent_control: Control, vip_required_tier: int, daily_limit: int, daily_remaining: int) -> bool:
	if vip_required_tier > 0 and _main_shop_vip_tier < vip_required_tier:
		_safe_show_message(parent_control, "仅VIP%d可购买该商品。" % vip_required_tier)
		return false
	if daily_limit > 0 and daily_remaining <= 0:
		_safe_show_message(parent_control, "该商品今日购买次数已满，请明日再来。")
		return false
	return true

static func _currency_unit_name(currency: String) -> String:
	if currency == "yuanbao":
		return "元宝"
	if currency == "friendship":
		return "友情点"
	return "金币"

static func _insufficient_currency_text(currency: String) -> String:
	if currency == "yuanbao":
		return "元宝不足，无法购买。"
	if currency == "friendship":
		return "友情点不足，无法购买。"
	return "金币不足，无法购买。"

static func _max_count_by_balance(balance: int, unit_price: int, daily_limit: int, daily_remaining: int) -> int:
	var price: = maxi(1, unit_price)
	var by_money: = int(maxi(0, balance) / price)
	var cap: = 999
	if daily_limit > 0:
		cap = mini(cap, maxi(0, daily_remaining))
	return clampi(mini(by_money, cap), 0, 999)

static func _max_affordable_buy_count(game_manager, currency: String, unit_price: int, daily_limit: int, daily_remaining: int) -> int:
	var balance: = 0
	if game_manager != null and game_manager.player != null:
		if currency == "yuanbao":
			balance = int(game_manager.player.yuanbao_currency)
		elif currency == "friendship":
			balance = int(game_manager.player.friendship_points)
		else:
			balance = int(game_manager.player.gold)
	return _max_count_by_balance(balance, unit_price, daily_limit, daily_remaining)

static func _show_quantity_cost_dialog(parent_control: Control, title: String, max_count: int, unit_price: int, unit_name: String, on_confirm: Callable) -> void :
	if parent_control == null or not is_instance_valid(parent_control):
		return
	var safe_max: = maxi(1, max_count)
	var popup: = Panel.new()
	popup.custom_minimum_size = Vector2(500, 360)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	parent_control.add_child(popup)
	popup.reset_size()
	popup.global_position = (parent_control.size - popup.size) / 2
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24
	vbox.offset_top = 24
	vbox.offset_right = -24
	vbox.offset_bottom = -24
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	vbox.add_child(title_label)
	var hint_label: = Label.new()
	hint_label.text = "请输入购买数量（1-%d）" % safe_max
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	vbox.add_child(hint_label)
	var count_edit: = LineEdit.new()
	count_edit.text = "1"
	count_edit.placeholder_text = "购买数量"
	count_edit.add_theme_font_size_override("font_size", 18)
	count_edit.custom_minimum_size = Vector2(220, 44)
	count_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(count_edit)
	var estimate_label: = Label.new()
	estimate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estimate_label.add_theme_font_size_override("font_size", 16)
	estimate_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(estimate_label)
	var refresh_estimate: = func():
		var parsed: = clampi(int(count_edit.text), 1, safe_max)
		estimate_label.text = "预计消耗：%d %s" % [parsed * unit_price, unit_name]
	refresh_estimate.call()
	count_edit.text_changed.connect( func(_t: String): refresh_estimate.call())
	var btn_row: = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)
	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	UIStyle.style_popup_button(cancel_btn, false, Vector2(140, 48))
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_row.add_child(cancel_btn)
	var confirm_btn: = Button.new()
	confirm_btn.text = "确认购买"
	UIStyle.style_popup_button(confirm_btn, true, Vector2(160, 48))
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.pressed.connect( func():
		var buy_count: = clampi(int(count_edit.text), 1, safe_max)
		popup.queue_free()
		if on_confirm.is_valid():
			on_confirm.call(buy_count)
	)
	btn_row.add_child(confirm_btn)

static func _buy_configured_item(game_manager, item_name: String, price: int, currency: String, 
		gold_label: Label, yuanbao_label: Label, friendship_label: Label, parent_control: Control, expected_price: int = -1, 
		quantity: int = 1, on_bought: Callable = Callable()):
	if _shop_buy_in_flight:
		_safe_show_message(parent_control, "有一笔购买正在处理中，请稍候。")
		return
	if game_manager.has_method("local_shop_buy"):
		_shop_buy_in_flight = true
		var local_result: Dictionary = game_manager.local_shop_buy(item_name, currency, quantity)
		_shop_buy_in_flight = false
		_safe_refresh_money_labels(gold_label, yuanbao_label, friendship_label, game_manager)
		_safe_show_message(parent_control, str(local_result.get("message", "本地交易失败")))
		if bool(local_result.get("ok", false)):
			_request_main_shop_catalog(game_manager, on_bought)
		return
	if not game_manager.network or not game_manager.network.is_logged_in():
		_safe_show_message(parent_control, "当前网络不可用，购买已阻止。\n为防止断网SL，商店交易需联网并完成云端确认。")
		return
	var qty: = clampi(quantity, 1, 999)

	var price_for_check: = expected_price if expected_price > 0 else _resolve_buy_price(price, currency, game_manager)
	var total_cost: = price_for_check * qty
	if currency == "yuanbao":
		var now_u: = _get_authoritative_shop_time(game_manager)
		if now_u > 0 and int(game_manager.player.yuanbao_currency) < total_cost:
			_safe_show_message(parent_control, "元宝不足，无法购买。")
			return
	elif currency == "friendship":
		if int(game_manager.player.friendship_points) < total_cost:
			_safe_show_message(parent_control, "友情点不足，无法购买。")
			return
	else:
		if int(game_manager.player.gold) < total_cost:
			_safe_show_message(parent_control, "金币不足，无法购买。")
			return

	var op_id: = "shop_buy_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var done: = false
	var ok: = false
	var err_msg: = ""
	var resp: Dictionary = {}
	var start_ms: = Time.get_ticks_msec()

	const SHOP_BUY_WAIT_TIMEOUT_MS: = 2500
	const SHOP_BUY_RETRY_INTERVAL_MS: = 1000
	const SHOP_BUY_MAX_RETRY: = 0
	var retried_count: = 0
	var next_retry_at_ms: = SHOP_BUY_RETRY_INTERVAL_MS
	var loading_popup = _show_loading_message(parent_control, "请稍后，正在给您打包货物...")

	var on_success: Callable
	var on_failed: Callable
	var _is_uncertain_buy_error: = func(err: String) -> bool:
		var msg: = String(err)
		return msg.contains("超时") or msg.contains("无响应")
	on_success = func(data: Dictionary):
		if done:
			return
		done = true
		ok = true
		resp = data
		if game_manager.network.shop_buy_failed.is_connected(on_failed):
			game_manager.network.shop_buy_failed.disconnect(on_failed)
	on_failed = func(err: String):
		if done:
			return
		done = true
		ok = false
		err_msg = "__PENDING_MAIL_CHECK__" if _is_uncertain_buy_error.call(err) else err
		if game_manager.network.shop_buy_success.is_connected(on_success):
			game_manager.network.shop_buy_success.disconnect(on_success)

	game_manager.network.shop_buy_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.shop_buy_failed.connect(on_failed, CONNECT_ONE_SHOT)
	_shop_buy_in_flight = true
	game_manager.network.shop_buy(item_name, op_id, currency, qty)

	while not done:
		var elapsed_ms: = Time.get_ticks_msec() - start_ms
		if retried_count < SHOP_BUY_MAX_RETRY and elapsed_ms >= next_retry_at_ms:
			retried_count += 1
			next_retry_at_ms += SHOP_BUY_RETRY_INTERVAL_MS

			game_manager.network.shop_buy(item_name, op_id, currency, qty)
		if elapsed_ms >= SHOP_BUY_WAIT_TIMEOUT_MS:
			done = true
			ok = false
			err_msg = "__PENDING_MAIL_CHECK__"
			if game_manager.network.shop_buy_success.is_connected(on_success):
				game_manager.network.shop_buy_success.disconnect(on_success)
			if game_manager.network.shop_buy_failed.is_connected(on_failed):
				game_manager.network.shop_buy_failed.disconnect(on_failed)
			break
		await game_manager.get_tree().process_frame
	_shop_buy_in_flight = false
	_close_popup_safely(loading_popup)

	var success_text: = "恭喜购买成功\n请到邮件查收货物"
	if qty > 1:
		success_text = "恭喜购买成功\n共%d个，请到邮件查收货物" % qty
	var refresh_after_buy: = func():
		if on_bought.is_valid():
			on_bought.call()
	if not ok:
		if err_msg == "__PENDING_MAIL_CHECK__":
			_trigger_mail_refresh()
			_async_sync_shop_buy_balance(game_manager, item_name, op_id, currency, gold_label, yuanbao_label, friendship_label, qty)
			_request_main_shop_catalog(game_manager, refresh_after_buy)
			_safe_show_message(parent_control, success_text)
			return
		_safe_refresh_money_labels(gold_label, yuanbao_label, friendship_label, game_manager)
		_safe_show_message(parent_control, "购买失败：%s" % (err_msg if not err_msg.is_empty() else "未知错误"))
		return

	if resp.has("newGold"):
		game_manager.player.gold = int(resp.get("newGold", game_manager.player.gold))
	if resp.has("newYuanbao"):
		game_manager.player.yuanbao_currency = int(resp.get("newYuanbao", game_manager.player.yuanbao_currency))
	if resp.has("newFriendshipPoints"):
		game_manager.player.friendship_points = int(resp.get("newFriendshipPoints", game_manager.player.friendship_points))
	_safe_refresh_money_labels(gold_label, yuanbao_label, friendship_label, game_manager)
	_request_main_shop_catalog(game_manager, refresh_after_buy)

	if bool(resp.get("duplicate", false)):
		_trigger_mail_refresh()
		_safe_show_message(parent_control, success_text)
		return

	_trigger_mail_refresh()
	_safe_show_message(parent_control, success_text)

static func _safe_refresh_money_labels(gold_label, yuanbao_label, friendship_label, game_manager) -> void :
	if is_instance_valid(gold_label):
		gold_label.text = "💰 金币: %d" % game_manager.player.gold
	if is_instance_valid(yuanbao_label):
		yuanbao_label.text = "元宝: %d" % game_manager.player.yuanbao_currency
	if is_instance_valid(friendship_label):
		friendship_label.text = "❤️ 友情点: %d" % int(game_manager.player.friendship_points)

static func _safe_show_message(parent_control, message: String) -> void :
	if is_instance_valid(parent_control):
		_show_message(parent_control, message)

static func _show_loading_message(parent_control, message: String):
	if not is_instance_valid(parent_control):
		return null
	_close_active_popup()
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.color = Color(0.631, 0.611, 0.564, 0.62)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_control.add_child(overlay)

	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(460, 220)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(popup)
	popup.reset_size()
	popup.position = (overlay.size - popup.size) / 2
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var spinner_label = Label.new()
	spinner_label.text = "✦"
	spinner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spinner_label.add_theme_font_size_override("font_size", 30)
	spinner_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45, 0.95))
	vbox.add_child(spinner_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_label)

	var anim_label = Label.new()
	anim_label.text = "商队正在清点货物."
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 17)
	anim_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850, 0.95))
	anim_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(anim_label)

	var hint = Label.new()
	hint.text = "预计1-2秒内完成"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.781, 0.759, 0.699, 0.92))
	vbox.add_child(hint)

	_start_shop_loading_animation(overlay, anim_label, spinner_label)
	_set_active_popup(overlay)
	return overlay

static func _close_popup_safely(popup) -> void :
	if is_instance_valid(popup):
		if popup == _active_shop_popup:
			_stop_shop_loading_animation()
		popup.queue_free()
	_clear_active_popup_if_match(popup)

static func _close_active_popup() -> void :
	if is_instance_valid(_active_shop_popup):
		_stop_shop_loading_animation()
		_active_shop_popup.queue_free()
	_active_shop_popup = null

static func _set_active_popup(popup) -> void :
	_active_shop_popup = popup

static func _clear_active_popup_if_match(popup) -> void :
	if _active_shop_popup == popup:
		_active_shop_popup = null

static func _trigger_mail_refresh() -> void :
	if MailManager.instance:
		MailManager.instance.refresh_mail_list()

static func _async_sync_shop_buy_balance(game_manager, item_name: String, op_id: String, currency: String, gold_label, yuanbao_label, friendship_label, quantity: int = 1) -> void :
	if game_manager == null or game_manager.network == null:
		return
	var done: = false
	var on_success: Callable
	var on_failed: Callable
	on_success = func(data: Dictionary):
		if done:
			return
		done = true
		if data.has("newGold"):
			game_manager.player.gold = int(data.get("newGold", game_manager.player.gold))
		if data.has("newYuanbao"):
			game_manager.player.yuanbao_currency = int(data.get("newYuanbao", game_manager.player.yuanbao_currency))
		if data.has("newFriendshipPoints"):
			game_manager.player.friendship_points = int(data.get("newFriendshipPoints", game_manager.player.friendship_points))
		_safe_refresh_money_labels(gold_label, yuanbao_label, friendship_label, game_manager)
		if game_manager.network.shop_buy_failed.is_connected(on_failed):
			game_manager.network.shop_buy_failed.disconnect(on_failed)
	on_failed = func(_err: String):
		if done:
			return
		done = true
		if game_manager.network.shop_buy_success.is_connected(on_success):
			game_manager.network.shop_buy_success.disconnect(on_success)
	game_manager.network.shop_buy_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.shop_buy_failed.connect(on_failed, CONNECT_ONE_SHOT)

	game_manager.network.shop_buy(item_name, op_id, currency, quantity)

static func _start_shop_loading_animation(popup, anim_label, spinner_label) -> void :
	_stop_shop_loading_animation()
	_shop_loading_anim_label = anim_label
	_shop_loading_spinner_label = spinner_label
	_shop_loading_timer = Timer.new()
	_shop_loading_timer.wait_time = 0.22
	_shop_loading_timer.one_shot = false
	popup.add_child(_shop_loading_timer)
	var steps: Array = [
		"商队正在清点货物", 
		"库房正在打包装箱", 
		"驿站正在核对单号", 
		"飞舟即将发往邮箱"
	]
	var i: = 0
	_shop_loading_timer.timeout.connect( func():
		if not is_instance_valid(_shop_loading_anim_label):
			return
		var dots = ".".repeat((i % 3) + 1)
		_shop_loading_anim_label.text = "%s%s" % [steps[i % steps.size()], dots]
		i += 1
	)
	_shop_loading_timer.start()
	if is_instance_valid(_shop_loading_spinner_label):
		_shop_loading_tween = popup.create_tween()
		_shop_loading_tween.set_loops()
		_shop_loading_tween.tween_property(_shop_loading_spinner_label, "scale", Vector2(1.18, 1.18), 0.36)
		_shop_loading_tween.tween_property(_shop_loading_spinner_label, "scale", Vector2(1.0, 1.0), 0.36)

static func _stop_shop_loading_animation() -> void :
	if is_instance_valid(_shop_loading_timer):
		_shop_loading_timer.stop()
		_shop_loading_timer.queue_free()
	_shop_loading_timer = null
	if _shop_loading_tween:
		_shop_loading_tween.kill()
	_shop_loading_tween = null
	_shop_loading_anim_label = null
	_shop_loading_spinner_label = null

static func _show_sell_items(container: VBoxContainer, game_manager, 
		category: String, gold_label: Label, yuanbao_label: Label, _friendship_label: Label, parent_control: Control):

	var inventory_manager = game_manager.inventory_manager
	if inventory_manager == null:
		var empty_label = Label.new()
		empty_label.text = "背包系统未初始化"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		container.add_child(empty_label)
		return

	var items = []
	if category in ["gold_shop", "yuanbao_shop", "friendship_shop", "all"]:
		items = inventory_manager.items
	else:
		items = inventory_manager.get_items_by_type(category)

	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "背包中没有该类型物品"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		container.add_child(empty_label)
		return

	for item in items:
		var item_name = item.name
		var item_data = _shop_item_data(item_name)

		var price_info = GameData.SHOP_PRICES.get(item_name, {"buy": 100, "sell": 40})
		var sell_price = price_info.get("sell", 40)

		var item_panel = Panel.new()
		item_panel.custom_minimum_size = Vector2(0, 100)
		item_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		container.add_child(item_panel)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 5
		hbox.offset_right = -10
		hbox.offset_bottom = -5
		hbox.add_theme_constant_override("separation", 8)
		item_panel.add_child(hbox)

		hbox.add_child(_create_item_icon(item, Vector2(64, 64)))

		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(info_vbox)

		var name_label = Label.new()
		var rarity = item.get_rarity()
		var rarity_color = item.get_rarity_color()
		name_label.text = "%s x%d" % [item_name, item.count]
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", rarity_color)
		info_vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = item.get_desc()
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		desc_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		desc_label.add_theme_font_size_override("font_size", 17)
		desc_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		info_vbox.add_child(desc_label)

		var price_label = Label.new()
		price_label.text = "💰 %d" % sell_price
		price_label.add_theme_font_size_override("font_size", 18)
		price_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		hbox.add_child(price_label)

		var sell_btn = Button.new()
		sell_btn.text = "出售"
		sell_btn.custom_minimum_size = Vector2(76, 48)
		sell_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sell_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sell_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(sell_btn)
		sell_btn.pressed.connect( func():
			_sell_item(game_manager, item, sell_price, gold_label, container, 
				category, yuanbao_label, parent_control)
		)
		hbox.add_child(sell_btn)

		var batch_sell_btn = Button.new()
		batch_sell_btn.text = "批量出售"
		batch_sell_btn.custom_minimum_size = Vector2(112, 48)
		batch_sell_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		batch_sell_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		batch_sell_btn.add_theme_font_size_override("font_size", 18)
		UIStyle.apply_button_style(batch_sell_btn)
		batch_sell_btn.pressed.connect( func():
			_sell_item_batch(game_manager, item, sell_price, gold_label, container, category, yuanbao_label, parent_control)
		)
		hbox.add_child(batch_sell_btn)
		_enable_touch_drag_passthrough(item_panel)

static func _buy_item(game_manager, item_name: String, price: int, 
		gold_label: Label, parent_control: Control):
	if not game_manager.has_method("local_shop_buy") and (not game_manager.network or not game_manager.network.is_logged_in()):
		_show_message(parent_control, "当前网络不可用，购买已阻止。\n为防止断网SL，商店交易需联网并完成云端确认。")
		return

	if game_manager.player.gold < price:
		print("[ShopUI] 购买失败(金币不足): ", item_name)
		return

	var snapshot = game_manager.create_secure_op_snapshot()
	game_manager.player.gold -= price

	var result = game_manager.inventory_manager.add_item(item_name, 1)
	if result.success:
		var commit_ok = await game_manager.commit_secure_op()
		if commit_ok:
			gold_label.text = "💰 金币: %d" % game_manager.player.gold
			print("[ShopUI] 购买成功: ", item_name)
		else:
			game_manager.restore_secure_op_snapshot(snapshot)
			gold_label.text = "💰 金币: %d" % game_manager.player.gold
			_show_message(parent_control, "云端确认失败，本次购买已回滚。")
	else:
		game_manager.player.gold += price
		print("[ShopUI] 购买失败: ", result.message)

static func _sell_item(game_manager, item, price: int, gold_label: Label, 
		container: VBoxContainer, category: String, yuanbao_label: Label, parent_control: Control):
	if not game_manager.has_method("local_shop_buy") and (not game_manager.network or not game_manager.network.is_logged_in()):
		_show_message(parent_control, "当前网络不可用，出售已阻止。\n为防止断网SL，商店交易需联网并完成云端确认。")
		return
	var snapshot = game_manager.create_secure_op_snapshot()

	var result = game_manager.inventory_manager.remove_item(item.id, 1)
	if result.success:
		game_manager.player.gold += price
		var commit_ok = await game_manager.commit_secure_op()
		if commit_ok:
			gold_label.text = "💰 金币: %d" % game_manager.player.gold
			if item.count <= 0:
				_refresh_after_sell(container, game_manager, category, gold_label, yuanbao_label, parent_control)
		else:
			game_manager.restore_secure_op_snapshot(snapshot)
			gold_label.text = "💰 金币: %d" % game_manager.player.gold
			_show_message(parent_control, "云端确认失败，本次出售已回滚。")
	else:
		_show_message(parent_control, "出售失败：%s" % result.message)

static func _sell_item_batch(game_manager, item, price: int, gold_label: Label, container: VBoxContainer, 
		category: String, yuanbao_label: Label, parent_control: Control):
	if not game_manager.has_method("local_shop_buy") and (not game_manager.network or not game_manager.network.is_logged_in()):
		_show_message(parent_control, "当前网络不可用，出售已阻止。\n为防止断网SL，商店交易需联网并完成云端确认。")
		return
	if item == null or int(item.count) <= 0:
		_show_message(parent_control, "暂无可出售物品。")
		return

	var total_count = int(item.count)
	var item_name = str(item.name)
	_show_batch_sell_dialog(game_manager, item, max(0, price), total_count, gold_label, container, category, yuanbao_label, parent_control)

static func _show_batch_sell_dialog(game_manager, item, unit_price: int, max_count: int, gold_label: Label, 
		container: VBoxContainer, category: String, yuanbao_label: Label, parent_control: Control):
	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(500, 330)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	parent_control.add_child(popup)
	popup.reset_size()
	popup.global_position = (parent_control.size - popup.size) / 2

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24
	vbox.offset_top = 24
	vbox.offset_right = -24
	vbox.offset_bottom = -24
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "批量出售 %s" % str(item.name)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.45))
	vbox.add_child(title_label)

	var hint_label = Label.new()
	hint_label.text = "请输入出售数量（1-%d），默认全部数量。" % max_count
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
	vbox.add_child(hint_label)

	var count_edit = LineEdit.new()
	count_edit.text = str(max_count)
	count_edit.placeholder_text = "出售数量"
	count_edit.add_theme_font_size_override("font_size", 18)
	count_edit.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(count_edit)

	var estimate_label = Label.new()
	estimate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estimate_label.add_theme_font_size_override("font_size", 16)
	estimate_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(estimate_label)

	var refresh_estimate: Callable = func():
		var parsed = int(count_edit.text)
		parsed = clamp(parsed, 1, max_count)
		estimate_label.text = "预计获得金币：%d" % (parsed * unit_price)
	refresh_estimate.call()
	count_edit.text_changed.connect( func(_t: String): refresh_estimate.call())

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(140, 48)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认出售"
	confirm_btn.custom_minimum_size = Vector2(160, 48)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		var sell_count = clamp(int(count_edit.text), 1, max_count)
		popup.queue_free()
		_execute_batch_sell(game_manager, item, sell_count, unit_price, gold_label, container, category, yuanbao_label, parent_control)
	)
	btn_row.add_child(confirm_btn)

static func _execute_batch_sell(game_manager, item, sell_count: int, unit_price: int, gold_label: Label, 
		container: VBoxContainer, category: String, yuanbao_label: Label, parent_control: Control):
	var snapshot = game_manager.create_secure_op_snapshot()
	var remove_result = game_manager.inventory_manager.remove_item(str(item.id), sell_count)
	if not bool(remove_result.get("success", false)):
		game_manager.restore_secure_op_snapshot(snapshot)
		gold_label.text = "💰 金币: %d" % game_manager.player.gold
		_show_message(parent_control, "批量出售失败：%s" % str(remove_result.get("message", "未知错误")))
		return

	var sold_gold = unit_price * sell_count
	game_manager.player.gold += sold_gold
	var commit_ok = await game_manager.commit_secure_op()
	if not commit_ok:
		game_manager.restore_secure_op_snapshot(snapshot)
		gold_label.text = "💰 金币: %d" % game_manager.player.gold
		_show_message(parent_control, "云端确认失败，本次批量出售已回滚。")
		return

	gold_label.text = "💰 金币: %d" % game_manager.player.gold
	_refresh_after_sell(container, game_manager, category, gold_label, yuanbao_label, parent_control)
	_show_message(parent_control, "批量出售完成：%s x%d，获得 %d 金币。" % [str(item.name), sell_count, sold_gold])

static func _refresh_after_sell(container: VBoxContainer, game_manager, 
		category: String, gold_label: Label, yuanbao_label: Label, parent_control: Control):

	for child in container.get_children():
		child.queue_free()

	_show_sell_items(container, game_manager, category, gold_label, yuanbao_label, null, parent_control)

static func _show_message(parent_control: Control, message: String):
	_close_active_popup()
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.color = Color(0.631, 0.611, 0.564, 0.68)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent_control.add_child(overlay)

	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(460, 380)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(popup)
	popup.position = (overlay.size - popup.custom_minimum_size) / 2

	var panel_style: = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.072, 0.080, 0.079, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.852, 0.716, 0.398, 0.95)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	popup.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 22
	vbox.offset_top = 18
	vbox.offset_right = -22
	vbox.offset_bottom = -28
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var content_width: = 416.0
	var title = Label.new()
	title.text = "订单结果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(content_width, 0)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.76, 1.0))
	content.add_child(title)

	var icon_label = Label.new()
	var success_msg: = message.find("成功") >= 0
	icon_label.text = "🎉" if success_msg else "📦"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(content_width, 0)
	icon_label.add_theme_font_size_override("font_size", 34)
	icon_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1.0))
	content.add_child(icon_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.custom_minimum_size = Vector2(content_width, 0)
	msg_label.add_theme_font_size_override("font_size", 24 if success_msg else 20)
	msg_label.add_theme_color_override("font_color", Color(0.924, 0.893, 0.831, 1.0))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(msg_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	ok_btn.custom_minimum_size = Vector2(160, 56)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.add_theme_font_size_override("font_size", 28)
	ok_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var btn_style: = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.118, 0.100, 0.058, 0.98)
	btn_style.corner_radius_top_left = 0
	btn_style.corner_radius_top_right = 0
	btn_style.corner_radius_bottom_left = 0
	btn_style.corner_radius_bottom_right = 0
	ok_btn.add_theme_stylebox_override("normal", btn_style)
	var hover_style: = btn_style.duplicate()
	hover_style.bg_color = Color(0.118, 0.100, 0.058, 1.0)
	ok_btn.add_theme_stylebox_override("hover", hover_style)
	ok_btn.pressed.connect( func(): _close_popup_safely(overlay))
	vbox.add_child(ok_btn)
	_set_active_popup(overlay)

static func _show_confirm(parent_control: Control, message: String, on_confirm: Callable, confirm_text: String = "确认"):
	_close_active_popup()
	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(460, 360)
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	parent_control.add_child(popup)

	popup.reset_size()
	popup.global_position = (parent_control.size - popup.size) / 2

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -28
	vbox.add_theme_constant_override("separation", 16)
	popup.add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.custom_minimum_size = Vector2(410, 0)
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(msg_label)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(140, 48)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): _close_popup_safely(popup))
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(140, 48)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		_close_popup_safely(popup)
		if on_confirm.is_valid():
			on_confirm.call()
	)
	btn_row.add_child(confirm_btn)
	_set_active_popup(popup)

static func _setup_mouse_filter(container: Control):
	for child in container.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if child is Container:
				_setup_mouse_filter(child)
