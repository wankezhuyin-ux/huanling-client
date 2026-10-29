extends Control
class_name GangHallUI

const UIStyle = preload("res://scripts/ui_style.gd")
const GangConfig = preload("res://scripts/gang/gang_config.gd")
const PlayerCharacterConfig = preload("res://scripts/player_character_config.gd")
const ConfirmDialog = preload("res://ui/components/confirm_dialog.gd")
const GangWarLogPanel = preload("res://ui/city/gang_war_log_panel.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")

const TAB_DEFS: Array = [
	{"key": "overview", "label": "概览"}, 
	{"key": "members", "label": "成员"}, 
	{"key": "donate", "label": "捐献"}, 
	{"key": "shop", "label": "商店"}, 
	{"key": "war", "label": "领地"}, 
	{"key": "others", "label": "帮战"}, 
]

const KICK_UNLOCK_LEVEL: = 5
const MEMBER_ROW_HEIGHT: = 108
const MEMBER_AVATAR_SIZE: = Vector2(72, 72)
const GANG_ROW_ACTION_BTN_SIZE: = Vector2(112, 34)
const GANG_PAIR_ACTION_BTN_SIZE: = Vector2(88, 32)
const GANG_PRIMARY_BTN_SIZE: = Vector2(148, 42)
const KICK_WAR_ROW_HEIGHT: = 120
const KICK_WAR_ROW_LEADER_LINE_HEIGHT: = 20
const KICK_WAR_ROW_NOTICE_LINE_HEIGHT: = 24
const KICK_WAR_TARGET_ROW_HEIGHT: = KICK_WAR_ROW_HEIGHT + KICK_WAR_ROW_LEADER_LINE_HEIGHT + KICK_WAR_ROW_NOTICE_LINE_HEIGHT
const KICK_WAR_ROW_FONT_SIZE: = 18
const KICK_WAR_ROW_NOTICE_FONT_SIZE: = 15
const KICK_WAR_ROW_STATUS_FONT_SIZE: = 14
const KICK_WAR_EMBLEM_SIZE: = 80
const KICK_PAIR_EMBLEM_SIZE: = 56
const OVERVIEW_EMBLEM_SIZE: = 200

const TERRITORY_GRID_ORDER: Array = [
	"sky_city", "fuying_water", "banyan_city", 
	"ninglu_mountain", "ruitian_snow", "deep_blue", 
	"wofu_sand", "jianchi_gu", "bugui_haian", 
	"chilechuan", "qiyue_valley", "huishou_ting", 
	"huashan_ding", "huangzhi_gu", "dong_matou", 
]


const BEIJING_OFFSET_SEC: = 28800

const TERRITORY_BUFF_LABELS: Dictionary = {
	"attack": "攻击", 
	"defense": "防御", 
	"hp": "生命", 
	"exp": "经验", 
	"agility": "敏捷", 
	"allStat": "全属性", 
	"goldDrop": "金币掉落", 
}

const TERRITORY_TIER_COLORS: Dictionary = {
	"唯一": {
		"bg": Color(0.128, 0.088, 0.052, 0.95), 
		"bg_hover": Color(0.163, 0.112, 0.067, 0.98), 
		"bg_pressed": Color(0.102, 0.068, 0.042, 0.98), 
		"border": Color(0.798, 0.580, 0.362, 1.00), 
		"icon_bg": Color(0.185, 0.129, 0.075, 1.00), 
		"tier_text": Color(0.884, 0.819, 0.716, 1.00), 
	}, 
	"高级": {
		"bg": Color(0.090, 0.052, 0.128, 0.95), 
		"bg_hover": Color(0.115, 0.067, 0.163, 0.98), 
		"bg_pressed": Color(0.072, 0.042, 0.102, 0.98), 
		"border": Color(0.604, 0.362, 0.798, 1.00), 
		"icon_bg": Color(0.132, 0.075, 0.185, 1.00), 
		"tier_text": Color(0.812, 0.716, 0.884, 1.00), 
	}, 
	"中级": {
		"bg": Color(0.052, 0.076, 0.128, 0.95), 
		"bg_hover": Color(0.067, 0.099, 0.163, 0.98), 
		"bg_pressed": Color(0.042, 0.060, 0.102, 0.98), 
		"border": Color(0.362, 0.520, 0.798, 1.00), 
		"icon_bg": Color(0.075, 0.116, 0.185, 1.00), 
		"tier_text": Color(0.716, 0.788, 0.884, 1.00), 
	}, 
	"初级": {
		"bg": Color(0.052, 0.128, 0.075, 0.95), 
		"bg_hover": Color(0.067, 0.163, 0.093, 0.98), 
		"bg_pressed": Color(0.042, 0.102, 0.057, 0.98), 
		"border": Color(0.362, 0.798, 0.416, 1.00), 
		"icon_bg": Color(0.075, 0.185, 0.103, 1.00), 
		"tier_text": Color(0.716, 0.884, 0.729, 1.00), 
	}, 
}

const TERRITORY_CELL_HEIGHT: = 92
const TERRITORY_CELL_ICON_INSET: = 8
const TERR_DETAIL_POPUP_MAX_WIDTH: = 500.0
const TERR_DETAIL_ICON_SIZE: = 72
const SIEGE_ACTION_COOLDOWN_MS: = 1000
const BID_FUND_UNIT: = 10000

var game_manager = null
var _tab: = "overview"
var _content: VBoxContainer
var _tab_bar: HBoxContainer
var _tab_scroll: ScrollContainer
var _content_scroll: ScrollContainer
var _tab_buttons: Dictionary = {}
var _status_label: Label
var _gang_mgr = null
var _load_error: = ""
var _draft_name: = ""
var _selected_emblem_id: = 1
var _show_member_tabs: = false
var _rendering: = false
var _render_pending: = false
var _no_gang_view: = "list"
var _list_fetch_scheduled: = false
var _shop_fetch_started: = false
var _shop_week_key_anchor: = ""
var _shop_week_poll_sec: = 0.0
const SHOP_WEEK_POLL_INTERVAL: = 30.0
var _others_fetch_started: = false
var _message_overlay: Control = null
var _members_sub_tab: = "list"
var _members_sub_tab_buttons: Dictionary = {}
var _siege_status_refresh_pending: = false
var _siege_status_sync_error: = ""
var _siege_challenge_prep_refresh_until_ms: Dictionary = {}
var _focus_war_territory_id: = ""
var _siege_action_cooldown_until_ms: Dictionary = {}

static func create_fullscreen(manager) -> GangHallUI:
	var ui: = GangHallUI.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.game_manager = manager
	ui._build_shell()
	if manager and manager.get("gang_manager"):
		var gm = manager.gang_manager
		if gm:
			gm.set_dialog_host(ui)
			ui.tree_exiting.connect( func():
				if gm.get_dialog_host() == ui:
					gm.set_dialog_host(null)
			)
	if ui._gang_mgr:
		if ui._gang_mgr.overview.is_empty():
			ui._status_label.text = "加载中..."
		else:
			ui._call_deferred_render()
		ui._request_overview()
	return ui

func _build_shell() -> void :
	if game_manager:
		_gang_mgr = game_manager.get("gang_manager")
		if _gang_mgr:
			if not _gang_mgr.overview_updated.is_connected(_on_overview_updated):
				_gang_mgr.overview_updated.connect(_on_overview_updated)
			if not _gang_mgr.overview_failed.is_connected(_on_overview_failed):
				_gang_mgr.overview_failed.connect(_on_overview_failed)
			if not _gang_mgr.war_reports_updated.is_connected(_on_war_reports_updated):
				_gang_mgr.war_reports_updated.connect(_on_war_reports_updated)
			if not _gang_mgr.gang_toast.is_connected(_on_gang_toast):
				_gang_mgr.gang_toast.connect(_on_gang_toast)
			if _gang_mgr.gang_network and not _gang_mgr.gang_network.request_finished.is_connected(_on_gang_request_finished):
				_gang_mgr.gang_network.request_finished.connect(_on_gang_request_finished)
	var root: = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 8
	root.offset_top = 8
	root.offset_right = -8
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.add_child(UIStyle.create_title_label("🏯 帮派"))
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	root.add_child(_status_label)
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.custom_minimum_size = Vector2(0, 42)
	_tab_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_tab_scroll.visible = false
	root.add_child(_tab_scroll)
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 6)
	_tab_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tab_scroll.add_child(_tab_bar)
	_build_persistent_tabs()
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.scroll_deadzone = 20
	root.add_child(_content_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_content.add_theme_constant_override("separation", 10)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_scroll.add_child(_content)
	set_process(false)

func _build_persistent_tabs() -> void :
	_tab_buttons.clear()
	for td in TAB_DEFS:
		var key: String = str(td.get("key", ""))
		var label: String = str(td.get("label", ""))
		var btn: = Button.new()
		btn.text = label
		btn.custom_minimum_size = Vector2(maxi(64, label.length() * 16 + 12), 36)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect( func(): _on_tab_pressed(key))
		_tab_bar.add_child(btn)
		_tab_buttons[key] = btn
	_update_tab_styles()

func _on_tab_pressed(key: String) -> void :
	if _tab == key:
		return
	if key == "members":
		_members_sub_tab = "list"
	_tab = key
	_update_tab_styles()
	set_process(key == "shop")
	if key == "shop":
		_shop_week_poll_sec = 0.0
		_maybe_refresh_shop_for_new_beijing_week()
	_fetch_tab_data_if_needed(key)
	_render_tab_content()

func focus_others_tab(refresh: bool = true) -> void :
	if _tab != "others":
		_tab = "others"
		_update_tab_styles()
	if refresh:
		_others_fetch_started = false
		if _gang_mgr:
			_gang_mgr.refresh_other_gangs()
			_gang_mgr.refresh_kick_active()
			_gang_mgr.refresh_kick_defending()
	_render_tab_content()

func focus_war_tab(refresh: bool = true, territory_id: String = "") -> void :
	_focus_war_territory_id = str(territory_id).strip_edges()
	if _focus_war_territory_id.is_empty():
		var existing: = get_node_or_null("TerritoryDetailLayer")
		if existing:
			existing.queue_free()
	if _tab != "war":
		_tab = "war"
		_update_tab_styles()
	if refresh and _gang_mgr:
		_gang_mgr.refresh_territories()
		_gang_mgr.refresh_war_reports()
		_gang_mgr.refresh_siege_status()
		_gang_mgr.refresh_gang_mirror()
	_render_tab_content()
	if not _focus_war_territory_id.is_empty():
		_try_open_focus_war_territory_popup()

func _try_open_focus_war_territory_popup() -> void :
	var tid: = _focus_war_territory_id
	if tid.is_empty() or _gang_mgr == null:
		return
	for item in _gang_mgr.territories:
		if item is Dictionary and str(item.get("id", "")) == tid:
			_focus_war_territory_id = ""
			_show_territory_detail_popup(item, false)
			return

func _fetch_tab_data_if_needed(key: String) -> void :
	if _gang_mgr == null:
		return
	match key:
		"members":
			_gang_mgr.refresh_members(true)
		"shop":
			if _gang_mgr and _gang_mgr.shop_data.is_empty():
				_shop_fetch_started = false
			_gang_mgr.refresh_shop()
		"war":
			_gang_mgr.refresh_territories()
			_gang_mgr.refresh_war_reports()
			_gang_mgr.refresh_siege_status()
			_gang_mgr.refresh_gang_mirror()
			if _gang_mgr.gang_network:
				_gang_mgr.gang_network.fetch_territory_claim_status()
		"others":
			_others_fetch_started = false
			_gang_mgr.refresh_other_gangs()
			_gang_mgr.refresh_kick_active()
			_gang_mgr.refresh_kick_defending()
		"overview":
			_gang_mgr.refresh_gang_mirror()

func _update_tab_styles() -> void :
	for key in _tab_buttons.keys():
		var btn: Button = _tab_buttons[key]
		if btn:
			UIStyle.apply_tab_style(btn, key == _tab)

func _set_member_tabs_visible(show_tabs: bool) -> void :
	_show_member_tabs = show_tabs
	if _tab_scroll:
		_tab_scroll.visible = show_tabs
	if show_tabs:
		_update_tab_styles()

func _on_overview_updated(_data: Dictionary) -> void :
	_load_error = ""
	_call_deferred_render()

func _on_war_reports_updated() -> void :
	if _tab == "war":
		_call_deferred_render()

func _on_overview_failed(error: String) -> void :
	_load_error = error if not error.is_empty() else "加载失败"
	_call_deferred_render()

func _on_gang_toast(message: String, is_success: bool) -> void :
	_show_gang_message(message, is_success)
	_call_deferred_restore_action_ui()

func _on_gang_request_finished(action: String, success: bool, data: Dictionary) -> void :
	if action in ["create", "donate", "shop_buy"] and not success:
		_call_deferred_restore_action_ui()
		return
	if not success:
		if action in ["siege_attack", "siege_buy_attack_contribution", "siege_buy_attack", "siege_repair", "siege_buy_defense", "siege_apply", "siege_bid", "siege_forfeit", "kick_buy_attack_contribution", "kick_buy_attack", "kick_buy_defense", "kick_repair"] and _tab == "war":
			_call_deferred_render()
			_call_deferred_refresh_territory_popup()
		return
	if action == "siege_status":
		_siege_status_refresh_pending = false
		if success:
			_siege_status_sync_error = ""
			if _tab == "war":
				if _gang_mgr and not _gang_mgr.war_reports_loading and _gang_mgr.war_reports.is_empty():
					if _participation_logs_have_capture():
						_gang_mgr.refresh_war_reports()
				_call_deferred_render()
		else:
			_siege_status_sync_error = str(data.get("error", "领地战状态同步失败"))
		_call_deferred_refresh_territory_popup()
		if success and not _focus_war_territory_id.is_empty():
			call_deferred("_try_open_focus_war_territory_popup")
		call_deferred("_try_show_pending_siege_attack_result")
		return
	match action:
		"members":
			if _tab == "members":
				_call_deferred_render()
		"shop":
			_shop_week_key_anchor = _beijing_gang_week_key()
			if _tab == "shop":
				_call_deferred_render()
		"territories", "war_reports", "territory_claim_status":
			if _tab == "war":
				_call_deferred_render()
		"siege_guards":
			_call_deferred_refresh_territory_popup()
		"siege_guard_set", "siege_guard_clear", "siege_guard_join":
			if _tab == "war":
				_call_deferred_render()
				_call_deferred_refresh_territory_popup()
		"siege_apply", "siege_bid", "siege_forfeit", "siege_attack", "siege_buy_attack_contribution", "siege_buy_attack", "siege_repair", "siege_buy_defense":
			if _tab == "war":
				_call_deferred_render()
		"territory_claim_daily_all", "gang_settings":
			if _tab == "war":
				_call_deferred_render()
			if action == "gang_settings" and _tab == "overview":
				_call_deferred_render()
		"other_gangs", "kick_active", "kick_defending", "gang_mirror_get", "gang_mirror_update":
			if _tab in ["others", "overview", "war"]:
				_call_deferred_render()
		"kick_repair", "kick_buy_attack_contribution", "kick_buy_attack", "kick_buy_defense":
			if _tab in ["others", "overview", "war"]:
				_call_deferred_render()
		"kick_start":
			if _tab == "others":
				_call_deferred_render()
		"list":
			_call_deferred_render()
		"create", "donate", "shop_buy":
			_call_deferred_restore_action_ui()
		"kick", "set_role", "transfer", "approve":
			if _tab == "members":
				_call_deferred_render()
		"apply":
			if success and bool(data.get("joined", false)):
				_show_join_success_loading()
		"create", "leave":
			if success:
				_call_deferred_render()

func _show_join_success_loading() -> void :
	_load_error = ""
	_set_member_tabs_visible(false)
	_status_label.text = "加入成功，加载中..."
	_clear_content()

func _notification(what: int) -> void :
	if what != NOTIFICATION_VISIBILITY_CHANGED or not is_visible_in_tree():
		return
	if _gang_mgr == null:
		return
	_request_overview()
	if _tab == "members" and _get_viewer_role() <= 3:
		_gang_mgr.refresh_members(true)
	if _tab == "war":
		_gang_mgr.refresh_siege_status()

func _request_overview() -> void :
	if _gang_mgr:
		_gang_mgr.refresh_overview()

func _call_deferred_render() -> void :
	call_deferred("_render")

func _call_deferred_restore_action_ui() -> void :
	call_deferred("_restore_action_ui")

func _call_deferred_refresh_territory_popup() -> void :
	call_deferred("_refresh_territory_detail_popup_if_open")

func _restore_action_ui() -> void :
	if _gang_mgr == null or _gang_mgr.overview.is_empty():
		return
	if bool(_gang_mgr.overview.get("hasGang", false)):
		if _tab in ["donate", "shop"]:
			_render_tab_content()
		return
	if _no_gang_view == "create":
		_clear_content()
		_render_no_gang_create()
		_apply_content_scroll_touch_passthrough()

func _clear_content() -> void :
	for c in _content.get_children():
		c.queue_free()

func _finish_render() -> void :
	_rendering = false
	if _render_pending:
		_render_pending = false
		call_deferred("_render")

func _render() -> void :
	if _rendering:
		_render_pending = true
		return
	_rendering = true
	_render_pending = false
	_clear_content()
	if _gang_mgr == null:
		_set_member_tabs_visible(false)
		_status_label.text = "帮派模块未就绪"
		_add_retry_button()
		_apply_content_scroll_touch_passthrough()
		_finish_render()
		return
	var ov: Dictionary = _gang_mgr.overview
	if ov.is_empty():
		_set_member_tabs_visible(false)
		if not _load_error.is_empty():
			_status_label.text = "加载失败：%s" % _load_error
			_add_retry_button()
		else:
			_status_label.text = "加载中..."
		_apply_content_scroll_touch_passthrough()
		_finish_render()
		return
	_load_error = ""
	if bool(ov.get("hasGang", false)):
		if not _show_member_tabs:
			_tab = "overview"
		_set_member_tabs_visible(true)
		_update_status_for_member()
		_render_tab_content()
	else:
		if _show_member_tabs:
			_no_gang_view = "list"
			_list_fetch_scheduled = false
		_set_member_tabs_visible(false)
		_render_no_gang()
	_apply_content_scroll_touch_passthrough()
	_finish_render()

func _render_tab_content() -> void :
	_clear_content()
	if _gang_mgr == null:
		_add_info_line(_content, "帮派模块未就绪", true)
		_apply_content_scroll_touch_passthrough()
		return
	if _gang_mgr.overview.is_empty():
		_add_info_line(_content, "帮派数据加载中…", true)
		_request_overview()
		_apply_content_scroll_touch_passthrough()
		return
	if not bool(_gang_mgr.overview.get("hasGang", false)):
		_render_no_gang()
		_apply_content_scroll_touch_passthrough()
		return
	_update_status_for_member()
	match _tab:
		"members":
			_render_members()
		"donate":
			_render_donate()
		"shop":
			_render_shop()
		"war":
			_render_war()
		"others":
			_render_other_gangs()
		_:
			_render_overview()
	_apply_content_scroll_touch_passthrough()

func _enable_touch_drag_passthrough(root: Control) -> void :
	var root_keep_input: = (root is BaseButton) or (root is LineEdit) or (root is TextEdit) or (root is OptionButton) or (root is ScrollContainer) or (root is CheckBox)
	if not root_keep_input:
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if not (child is Control):
			continue
		_enable_touch_drag_passthrough(child as Control)

func _apply_content_scroll_touch_passthrough() -> void :
	if _content == null:
		return
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enable_touch_drag_passthrough(_content)

func _update_status_for_member() -> void :
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var mem: Dictionary = _gang_mgr.overview.get("membership", {})
	_status_label.text = "%s  %s  职位：%s  我的帮贡：%d · 本周捐献：%d · 今日捐献：%d" % [
		str(gang.get("name", "")), 
		_get_my_player_name(), 
		str(mem.get("roleName", "成员")), 
		int(mem.get("contribution", 0)), 
		_member_weekly_donation(mem), 
		_member_daily_donation(mem), 
	]

func _add_card(title: String = "", rules_pressed: Callable = Callable(), subtitle: String = "", extra_header_buttons: Array = [], war_interface_buttons: bool = false) -> PanelContainer:
	var panel: = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box: = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	if not title.is_empty():
		if rules_pressed.is_valid():
			var hdr_row: = HBoxContainer.new()
			hdr_row.add_theme_constant_override("separation", 8)
			var hdr: = Label.new()
			hdr.text = title
			hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hdr.add_theme_font_size_override("font_size", 16)
			hdr.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			hdr_row.add_child(hdr)
			var rules_btn: = Button.new()
			rules_btn.text = "规则说明"
			rules_btn.custom_minimum_size = Vector2(88, 28)
			rules_btn.add_theme_font_size_override("font_size", 13)
			if war_interface_buttons:
				_style_war_interface_button(rules_btn)
			else:
				UIStyle.apply_action_button_style(rules_btn)
			rules_btn.pressed.connect(rules_pressed)
			hdr_row.add_child(rules_btn)
			for spec in extra_header_buttons:
				if not spec is Dictionary:
					continue
				var extra_btn: = Button.new()
				extra_btn.text = str(spec.get("text", ""))
				extra_btn.custom_minimum_size = Vector2(112, 28)
				extra_btn.add_theme_font_size_override("font_size", 13)
				extra_btn.disabled = bool(spec.get("disabled", false))
				if war_interface_buttons:
					_style_war_interface_button(extra_btn)
				else:
					UIStyle.apply_action_button_style(extra_btn)
				var cb: Callable = spec.get("callback", Callable())
				if cb.is_valid():
					extra_btn.pressed.connect(cb)
				hdr_row.add_child(extra_btn)
			box.add_child(hdr_row)
		else:
			var hdr: = Label.new()
			hdr.text = title
			hdr.add_theme_font_size_override("font_size", 16)
			hdr.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
			box.add_child(hdr)
	if not subtitle.is_empty():
		_add_info_line(box, subtitle, true)
	panel.set_meta("inner_box", box)
	_content.add_child(panel)
	return panel

func _card_box(card: PanelContainer) -> VBoxContainer:
	return card.get_meta("inner_box") as VBoxContainer

func _add_info_line(parent: Node, text: String, dim: bool = false, custom_color: Variant = null) -> void :
	var lbl: = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	var font_color: Color
	if custom_color is Color:
		font_color = custom_color as Color
	else:
		font_color = Color(0.760, 0.740, 0.680) if dim else Color(0.945, 0.912, 0.850)
	lbl.add_theme_color_override("font_color", font_color)
	parent.add_child(lbl)

func _add_buff_highlight_line(parent: Node, text: String) -> void :
	var lbl: = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	parent.add_child(lbl)

func _add_territory_section_title(parent: Node, text: String) -> void :
	var lbl: = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	parent.add_child(lbl)

func _add_territory_hint_line(parent: Node, text: String) -> void :
	var lbl: = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.760, 0.740, 0.680))
	parent.add_child(lbl)

func _add_territory_kv_row(parent: Node, label: String, value: String, value_accent: bool = false, value_warn: bool = false) -> void :
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label_lbl: = Label.new()
	label_lbl.text = "%s：" % label
	label_lbl.add_theme_font_size_override("font_size", 15)
	label_lbl.add_theme_color_override("font_color", Color(0.734, 0.714, 0.657))
	label_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(label_lbl)
	var value_lbl: = Label.new()
	value_lbl.text = value
	value_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_lbl.add_theme_font_size_override("font_size", 15)
	var value_color: = Color(0.072, 0.080, 0.079)
	if value_accent:
		value_color = Color(0.55, 0.95, 0.65)
	elif value_warn:
		value_color = Color(1.0, 0.78, 0.38)
	value_lbl.add_theme_color_override("font_color", value_color)
	row.add_child(value_lbl)
	parent.add_child(row)

func _build_territory_detail_header(parent: Node, t: Dictionary) -> void :
	var tid: = str(t.get("id", ""))
	var terr_name: = str(t.get("name", tid))
	if terr_name.is_empty():
		terr_name = tid
	var tier: = str(t.get("tier", ""))
	if tier.is_empty() and tid == "sky_city":
		tier = "唯一"
	var tier_key: = _territory_tier_key(t, tid)
	var palette: Dictionary = TERRITORY_TIER_COLORS.get(tier_key, TERRITORY_TIER_COLORS["中级"])
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_wrap: = Panel.new()
	icon_wrap.custom_minimum_size = Vector2(TERR_DETAIL_ICON_SIZE, TERR_DETAIL_ICON_SIZE)
	var icon_style: = StyleBoxFlat.new()
	icon_style.bg_color = palette.get("icon_bg", Color(0.072, 0.080, 0.079))
	icon_style.border_color = palette.get("border", Color(1.000, 0.905, 0.640))
	icon_style.set_border_width_all(2)
	icon_style.corner_radius_top_left = 0
	icon_style.corner_radius_top_right = 0
	icon_style.corner_radius_bottom_left = 0
	icon_style.corner_radius_bottom_right = 0
	icon_wrap.add_theme_stylebox_override("panel", icon_style)
	var icon_margin: = MarginContainer.new()
	icon_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_margin.add_theme_constant_override("margin_left", 5)
	icon_margin.add_theme_constant_override("margin_right", 5)
	icon_margin.add_theme_constant_override("margin_top", 5)
	icon_margin.add_theme_constant_override("margin_bottom", 5)
	icon_wrap.add_child(icon_margin)
	var icon_holder: = Control.new()
	icon_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_margin.add_child(icon_holder)
	icon_holder.add_child(_create_territory_icon(tid, terr_name, palette))
	row.add_child(icon_wrap)
	var title_box: = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 4)
	var name_lbl: = Label.new()
	name_lbl.text = terr_name
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title_box.add_child(name_lbl)
	var tier_lbl: = Label.new()
	tier_lbl.text = tier if not tier.is_empty() else tier_key
	tier_lbl.add_theme_font_size_override("font_size", 14)
	tier_lbl.add_theme_color_override("font_color", palette.get("tier_text", Color(0.945, 0.912, 0.850)))
	title_box.add_child(tier_lbl)
	row.add_child(title_box)
	parent.add_child(row)

func _resolve_territory_detail_popup_size(host_size: Vector2) -> Vector2:
	var popup_w: = minf(host_size.x * 0.92, TERR_DETAIL_POPUP_MAX_WIDTH)
	var popup_h: = clampf(host_size.y * 0.72, 520.0, 640.0)
	return Vector2(popup_w, popup_h)

func _style_line_edit(edit: LineEdit) -> void :
	edit.custom_minimum_size = Vector2(0, 40)
	edit.add_theme_font_size_override("font_size", 16)
	edit.focus_mode = Control.FOCUS_ALL
	edit.text_changed.connect( func(t): _draft_name = t)

func _add_centered_button_row(parent: Node, btn: Button) -> void :
	var row: = CenterContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	row.add_child(btn)

func _add_row_action_button(parent: HBoxContainer, text: String) -> Button:
	var btn: = Button.new()
	btn.text = text
	btn.custom_minimum_size = GANG_ROW_ACTION_BTN_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.add_theme_font_size_override("font_size", 13)
	UIStyle.apply_action_button_style(btn)
	parent.add_child(btn)
	return btn

func _add_action_list_row(parent: Node, desc: String, btn_text: String) -> Button:
	var row: = Panel.new()
	row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	row.custom_minimum_size = Vector2(0, 48)
	var h: = HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_top = 6
	h.offset_right = -10
	h.offset_bottom = -6
	row.add_child(h)
	var lbl: = Label.new()
	lbl.text = desc
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	h.add_child(lbl)
	var btn: = _add_row_action_button(h, btn_text)
	parent.add_child(row)
	return btn

func _get_backpack_material_count() -> int:
	if game_manager == null or game_manager.inventory_manager == null:
		return 0
	return int(game_manager.inventory_manager.get_item_count(GangConfig.MATERIAL_ITEM))

func _try_donate_material(donate_type: String, btn: Button) -> void :
	if _gang_mgr == null or _gang_mgr.gang_network == null:
		return
	var cfg: Dictionary = _gang_mgr.overview.get("config", {}) if _gang_mgr else {}
	var donations: Dictionary = cfg.get("donations", {})
	if donate_type == "material":
		var owned: = _get_backpack_material_count()
		if owned < 1:
			ConfirmDialog.show_message(
				self, 
				"建设材料不足", 
				"「捐献建设材料」需消耗背包中的道具【建设材料】。\n金币/元宝捐献获得的是帮派建设材料，不能直接用于此项捐献。"
			)
			return
	elif donate_type == "yuanbao":
		var cost: = int((donations.get("yuanbao", {}) as Dictionary).get("costYuanbao", 100))
		var cur: = int(game_manager.player.yuanbao_currency) if game_manager and game_manager.player else 0
		if cur < cost:
			ConfirmDialog.show_message(
				self, 
				"元宝不足", 
				"每次捐献需要 %d 元宝，当前仅有 %d 元宝。" % [cost, cur]
			)
			return
	elif donate_type == "gold":
		var cost: = int((donations.get("gold", {}) as Dictionary).get("costGold", 10000000))
		var cur: = int(game_manager.player.gold) if game_manager and game_manager.player else 0
		if cur < cost:
			ConfirmDialog.show_message(
				self, 
				"金币不足", 
				"每次捐献需要 %s 金币，当前仅有 %s 金币。" % [_format_big_number(cost), _format_big_number(cur)]
			)
			return
	btn.disabled = true
	btn.text = "处理中…"
	_gang_mgr.gang_network.donate(donate_type)

func _confirm_gang_action(title: String, message: String, on_confirm: Callable, confirm_text: String = "确认", dialog_host: Node = null) -> void :
	var host: = dialog_host if dialog_host != null else self
	ConfirmDialog.show(host, title, message, on_confirm, confirm_text, "取消")

func _add_styled_button(parent: Node, text: String, golden: bool = false) -> Button:
	var btn: = Button.new()
	btn.text = text
	btn.custom_minimum_size = GANG_PRIMARY_BTN_SIZE
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	if golden:
		UIStyle.apply_golden_button_style(btn)
		UIStyle.setup_button_animation(btn)
	else:
		UIStyle.apply_action_button_style(btn)
	_add_centered_button_row(parent, btn)
	return btn

func _get_my_user_id() -> int:
	if game_manager and game_manager.network:
		return int(game_manager.network.get("user_id") if game_manager.network.get("user_id") else 0)
	return 0

func _get_my_player_name() -> String:
	if game_manager and game_manager.player:
		var name: = str(game_manager.player.player_name).strip_edges()
		if not name.is_empty():
			return name
	if game_manager and game_manager.network:
		var nickname: = str(game_manager.network.get("nickname")).strip_edges()
		if not nickname.is_empty():
			return nickname
	return "未知"

func _get_viewer_role() -> int:
	if _gang_mgr == null:
		return 4
	if bool(_gang_mgr.overview.get("hasGang", false)):
		var role: = int(_gang_mgr.overview.get("membership", {}).get("role", 0))
		if role >= 1 and role <= 4:
			return role
	if _gang_mgr.viewer_role >= 1 and _gang_mgr.viewer_role <= 4:
		return _gang_mgr.viewer_role
	return 4

func _role_name_from_id(role: int) -> String:
	match role:
		1:
			return "帮主"
		2:
			return "副帮主"
		3:
			return "精英"
		_:
			return "成员"

func _member_display_name(m: Dictionary) -> String:
	var name: = str(m.get("playerName", m.get("nickname", m.get("playerName", "")))).strip_edges()
	if not name.is_empty():
		return name
	return "未知"

func _member_role_name(m: Dictionary) -> String:
	var name: = str(m.get("roleName", "")).strip_edges()
	if not name.is_empty():
		return name
	return _role_name_from_id(int(m.get("role", 4)))

func _find_next_level_row(current_level: int) -> Dictionary:
	if _gang_mgr == null:
		return {}
	var cfg: Dictionary = _gang_mgr.overview.get("config", {})
	var levels: Array = cfg.get("levels", [])
	for row in levels:
		if row is Dictionary and int(row.get("level", 0)) == current_level + 1:
			return row
	return {}

func _add_small_button(parent: Node, label: String, callback: Callable, golden: bool = false, btn_size: Vector2 = GANG_ROW_ACTION_BTN_SIZE) -> Button:
	var btn: = Button.new()
	btn.text = label
	btn.custom_minimum_size = btn_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	if golden:
		UIStyle.apply_golden_button_style(btn)
		UIStyle.setup_button_animation(btn)
	else:
		UIStyle.apply_action_button_style(btn)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _get_gang_member_count() -> int:
	if _gang_mgr == null:
		return 0
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var from_overview: = int(gang.get("memberCount", gang.get("member_count", 0)))
	if from_overview > 0:
		return from_overview
	return _gang_mgr.members.size()

func _prompt_upgrade_gang(next_lv: int, need_funds: int, need_mats: int, need_rep: int = 0) -> void :
	if _gang_mgr == null or _gang_mgr.gang_network == null:
		return
	var msg: = "确认消耗帮派资金 %s 与帮派建设材料 %d，将帮派升至 Lv.%d？" % [
		_format_big_number(need_funds), 
		need_mats, 
		next_lv, 
	]
	if need_rep > 0:
		msg = "确认消耗帮派资金 %s、帮派建设材料 %d、帮派声望 %d，将帮派升至 Lv.%d？" % [
			_format_big_number(need_funds), 
			need_mats, 
			need_rep, 
			next_lv, 
		]
	_confirm_gang_action("升级帮派", msg, func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.upgrade_gang()
	, "确认升级")

func _prompt_leave_gang() -> void :
	if _gang_mgr == null:
		return
	var role: = _get_viewer_role()
	var member_count: = _get_gang_member_count()
	var cfg: Dictionary = _gang_mgr.overview.get("config", {})
	var cooldown_h: = int(cfg.get("leaveCooldownHours", 24))
	if role == 1 and member_count > 1:
		_show_gang_message("帮主请先禅让给其他成员后再退出帮派", false)
		return
	var msg: = ""
	if role == 1 and member_count <= 1:
		msg = "你是帮主且帮派仅你一人，退出后帮派将解散"
		if _owns_any_territory():
			msg += "，本帮占领的领地将变为中立并清除保护期"
		msg += "。确定退出？"
	else:
		msg = "退出后将离开当前帮派，并在 %d 小时内无法申请加入其它帮派（仍可创建新帮派）。确定退出？" % cooldown_h
	_confirm_gang_action("退出帮派", msg, func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.leave_gang()
	, "确认退出")

func _prompt_kick_member(m: Dictionary, target_id: int) -> void :
	var name: = _member_display_name(m)
	_confirm_gang_action("踢出成员", "确定将 %s 踢出帮派？" % name, func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.kick_member(target_id)
	, "确认踢出")

func _prompt_transfer_leadership(m: Dictionary, target_id: int) -> void :
	var name: = _member_display_name(m)
	_confirm_gang_action("禅让帮主", "将把帮主职位移交给 %s，此操作不可撤销。确定禅让？" % name, func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.transfer_leadership(target_id)
	, "确认禅让")

func _create_gang_emblem_icon(emblem_id: int, size: int = 48) -> TextureRect:
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: = load(GangConfig.emblem_path(emblem_id)) as Texture2D
	if tex:
		icon.texture = tex
	return icon

func _render_overview() -> void :
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var mem: Dictionary = _gang_mgr.overview.get("membership", {})
	var gang_level_buffs: Dictionary = _gang_mgr.overview.get("gangLevelBuffs", {})
	var total_buffs: Dictionary = _gang_mgr.overview.get("buffs", {})
	var card: = _add_card("帮派概览")
	var box: = _card_box(card)
	var emblem_id: = int(gang.get("emblemId", gang.get("emblem_id", 1)))
	var body: = HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var info_col: = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 8)
	_add_info_line(info_col, "帮派名称：%s" % str(gang.get("name", "")))
	_add_info_line(info_col, "帮派等级：Lv.%d" % int(gang.get("level", 1)))
	_add_info_line(info_col, "帮派人数 %d/%d" % [
		int(gang.get("memberCount", 0)), 
		int(gang.get("memberCap", 30)), 
	])
	var funds: = int(gang.get("funds", 0))
	var gang_level: = int(gang.get("level", 1))
	var fee_coeff: = int(_gang_mgr.overview.get("config", {}).get("maintenanceFeePerLevelSq", 500))
	var weekly_maint_fee: = gang_level * gang_level * maxi(0, fee_coeff)
	_add_info_line(info_col, "帮派资金：%d" % funds)
	if funds < weekly_maint_fee:
		_add_info_line(info_col, "每周维护费：%d" % weekly_maint_fee, false, Color(1.0, 0.45, 0.42))
	else:
		_add_info_line(info_col, "每周维护费：%d" % weekly_maint_fee)
	_add_info_line(info_col, "每周一 0 点从帮派资金扣除；资金不足时帮派降 1 级", true)
	_add_info_line(info_col, "帮派建设材料：%d" % int(gang.get("materials", 0)))
	var rep_max: = int(gang.get("reputationMax", _gang_mgr.overview.get("config", {}).get("reputationMax", 150)))
	_add_info_line(info_col, "帮派声望：%d / %d" % [int(gang.get("reputation", 0)), rep_max])
	_add_info_line(info_col, "帮主：%s" % str(gang.get("leaderName", "未知")))
	var notice_text: = str(gang.get("notice", "")).strip_edges()
	_add_info_line(info_col, "公告：%s" % (notice_text if not notice_text.is_empty() else "暂无"))
	var info_h: = int(info_col.get_combined_minimum_size().y)
	var row_h: = maxi(OVERVIEW_EMBLEM_SIZE, info_h)
	body.custom_minimum_size = Vector2(0, row_h)
	var info_wrap: = MarginContainer.new()
	info_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_wrap.custom_minimum_size = Vector2(0, row_h)
	var pad_v: = maxi(0, (row_h - info_h) / 2)
	info_wrap.add_theme_constant_override("margin_top", pad_v)
	info_wrap.add_theme_constant_override("margin_bottom", maxi(0, row_h - info_h - pad_v))
	info_wrap.add_child(info_col)
	body.add_child(info_wrap)
	var emblem_wrap: = CenterContainer.new()
	emblem_wrap.custom_minimum_size = Vector2(OVERVIEW_EMBLEM_SIZE, row_h)
	emblem_wrap.size_flags_horizontal = Control.SIZE_SHRINK_END
	emblem_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var emblem: = _create_gang_emblem_icon(emblem_id, OVERVIEW_EMBLEM_SIZE)
	emblem_wrap.add_child(emblem)
	body.add_child(emblem_wrap)
	box.add_child(body)
	var buff_card: = _add_card("帮派增益", Callable(), "属性加成对人和宠物同时生效")
	var buff_box: = _card_box(buff_card)
	_add_info_line(buff_box, "帮派固定增益：%s" % _format_gang_buff_line(gang_level_buffs, false), true)
	_add_info_line(buff_box, "领地增益：", true)
	var breakdown: Array = _gang_mgr.overview.get("ownedTerritoryBuffBreakdown", [])
	if breakdown.is_empty():
		_add_info_line(buff_box, "  无占领领地", true)
	else:
		for entry in breakdown:
			if entry is Dictionary:
				_add_info_line(buff_box, _format_owned_territory_buff_line(entry), true)
	_add_buff_highlight_line(buff_box, "总增益：%s" % _format_gang_buff_line(total_buffs, true))
	var act_card: = _add_card("操作")
	var act_box: = _card_box(act_card)
	var current_lv: = int(gang.get("level", 1))
	if int(mem.get("role", 4)) <= 2:
		var next_row: = _find_next_level_row(current_lv)
		if next_row.is_empty():
			_add_info_line(act_box, "已达最高等级", true)
		else:
			var next_lv: = int(next_row.get("level", current_lv + 1))
			var need_funds: = int(next_row.get("funds", 0))
			var need_mats: = int(next_row.get("materials", 0))
			var need_rep: = int(next_row.get("reputation", 0))
			var cur_funds: = int(gang.get("funds", 0))
			var cur_mats: = int(gang.get("materials", 0))
			var cur_rep: = int(gang.get("reputation", 0))
			var req_line: = "升级至 Lv.%d 需要：帮派资金 %s（当前 %s）· 帮派建设材料 %d（当前 %d）" % [
				next_lv, 
				_format_big_number(need_funds), 
				_format_big_number(cur_funds), 
				need_mats, 
				cur_mats, 
			]
			if need_rep > 0:
				req_line += " · 帮派声望 %d（当前 %d）" % [need_rep, cur_rep]
			_add_info_line(act_box, req_line)
			var unlock: = str(next_row.get("unlock", "")).strip_edges()
			if unlock == "踢馆":
				unlock = "帮战"
			if not unlock.is_empty():
				_add_info_line(act_box, "解锁：%s" % unlock, true)
			var up_btn: = _add_styled_button(act_box, "升级帮派")
			up_btn.disabled = cur_funds < need_funds or cur_mats < need_mats or cur_rep < need_rep
			up_btn.pressed.connect( func():
				_prompt_upgrade_gang(next_lv, need_funds, need_mats, need_rep)
			)
	if _get_viewer_role() in [1, 2]:
		var settings_card: = _add_card("帮派设置（帮主/副帮主）")
		_render_gang_settings_section(_card_box(settings_card), gang)

func _style_gang_checkbox(cb: CheckBox) -> void :
	cb.custom_minimum_size = Vector2(0, 42)
	cb.add_theme_font_size_override("font_size", 16)
	cb.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	cb.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.7))
	cb.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.7))
	cb.add_theme_color_override("font_disabled_color", Color(0.631, 0.611, 0.564))
	cb.add_theme_color_override("icon_normal_color", Color(1.0, 0.85, 0.35))
	cb.add_theme_color_override("icon_hover_color", Color(1.0, 0.92, 0.5))
	cb.add_theme_color_override("icon_pressed_color", Color(1.0, 0.95, 0.65))
	cb.add_theme_color_override("icon_disabled_color", Color(0.631, 0.611, 0.564))
	var checkbox_normal: = StyleBoxFlat.new()
	checkbox_normal.bg_color = Color(0.072, 0.080, 0.079, 0.85)
	checkbox_normal.border_width_left = 1
	checkbox_normal.border_width_top = 1
	checkbox_normal.border_width_right = 1
	checkbox_normal.border_width_bottom = 1
	checkbox_normal.border_color = Color(0.95, 0.75, 0.25, 0.65)
	checkbox_normal.corner_radius_top_left = 0
	checkbox_normal.corner_radius_top_right = 0
	checkbox_normal.corner_radius_bottom_left = 0
	checkbox_normal.corner_radius_bottom_right = 0
	cb.add_theme_stylebox_override("normal", checkbox_normal)
	var checkbox_hover: = checkbox_normal.duplicate()
	checkbox_hover.bg_color = Color(0.072, 0.080, 0.079, 0.95)
	checkbox_hover.border_color = Color(1.0, 0.82, 0.3, 0.9)
	cb.add_theme_stylebox_override("hover", checkbox_hover)
	cb.add_theme_stylebox_override("pressed", checkbox_hover.duplicate())
	cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _render_gang_settings_section(parent: Node, gang: Dictionary) -> void :
	var notice_edit: = LineEdit.new()
	notice_edit.text = str(gang.get("notice", ""))
	notice_edit.placeholder_text = "公告（最多100字）"
	notice_edit.max_length = 100
	notice_edit.custom_minimum_size = Vector2(0, 38)
	_style_line_edit(notice_edit)
	parent.add_child(notice_edit)
	var auto_toggle: = CheckBox.new()
	auto_toggle.text = "自由加入"
	auto_toggle.button_pressed = bool(gang.get("autoJoin", false))
	_style_gang_checkbox(auto_toggle)
	parent.add_child(auto_toggle)
	_add_info_line(parent, "开启后玩家可直接入帮，无需审批", true)
	var save_btn: = Button.new()
	save_btn.text = "保存设置"
	save_btn.custom_minimum_size = Vector2(0, 38)
	_style_gang_popup_button(save_btn, true)
	save_btn.pressed.connect( func():
		if _gang_mgr == null or _gang_mgr.gang_network == null:
			return
		_gang_mgr.gang_network.update_settings(notice_edit.text.strip_edges(), auto_toggle.button_pressed)
	)
	parent.add_child(save_btn)

func _lookup_other_gang_emblem_id(gang_id: int) -> int:
	if _gang_mgr == null:
		return 1
	for g in _gang_mgr.other_gangs:
		if g is Dictionary and int(g.get("id", 0)) == gang_id:
			return int(g.get("emblem_id", g.get("emblemId", 1)))
	return 1

func _build_kick_pair_header(parent: Node, our_name: String, our_emblem_id: int, middle_text: String, opp_name: String, opp_emblem_id: int) -> void :
	var row: = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var our_col: = VBoxContainer.new()
	our_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	our_col.alignment = BoxContainer.ALIGNMENT_CENTER
	our_col.add_child(_create_gang_emblem_icon(our_emblem_id, KICK_PAIR_EMBLEM_SIZE))
	var our_lbl: = Label.new()
	our_lbl.text = our_name
	our_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	our_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	our_lbl.add_theme_font_size_override("font_size", 14)
	our_col.add_child(our_lbl)
	row.add_child(our_col)
	var mid: = Label.new()
	mid.text = middle_text
	mid.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_theme_font_size_override("font_size", 15)
	mid.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	row.add_child(mid)
	var opp_col: = VBoxContainer.new()
	opp_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_col.alignment = BoxContainer.ALIGNMENT_CENTER
	opp_col.add_child(_create_gang_emblem_icon(opp_emblem_id, KICK_PAIR_EMBLEM_SIZE))
	var opp_lbl: = Label.new()
	opp_lbl.text = opp_name
	opp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opp_lbl.add_theme_font_size_override("font_size", 14)
	opp_col.add_child(opp_lbl)
	row.add_child(opp_col)
	parent.add_child(row)

func _render_kick_attacking_cards() -> void :
	if _gang_mgr == null:
		return
	var sessions: Array = _gang_mgr.kick_active_sessions
	if sessions.is_empty():
		return
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var cfg: Dictionary = _gang_mgr.overview.get("config", {})
	var our_name: = str(gang.get("name", "我方"))
	var our_emblem: = int(gang.get("emblem_id", gang.get("emblemId", 1)))
	var atk_contrib_cost: = int(cfg.get("kickAttackContributionCost", 200))
	var atk_contrib_limit: = int(cfg.get("kickAttackContributionLimit", 3))
	var atk_yb_cost: = int(cfg.get("kickYuanbaoAttackCost", 100))
	var atk_yb_limit: = int(cfg.get("kickYuanbaoAttackLimit", 3))
	for s in sessions:
		if not s is Dictionary:
			continue
		var session_id: = int(s.get("sessionId", s.get("session_id", 0)))
		var defender_gid: = int(s.get("defenderGangId", s.get("defender_gang_id", 0)))
		var defender_name: = str(s.get("defenderName", s.get("defender_name", "守方")))
		var defender_emblem: = _lookup_other_gang_emblem_id(defender_gid)
		var card: = _add_card("进攻中")
		var box: = _card_box(card)
		_build_kick_pair_header(box, our_name, our_emblem, "VS", defender_name, defender_emblem)
		var aq: Dictionary = s.get("attackQuota", {})
		var attacks_left: = int(aq.get("attacksLeft", s.get("todayAttacksLeft", 0)))
		var phase: = str(s.get("phase", "battle"))
		var prep_left: = int(s.get("prepSecondsLeft", 0))
		var attack_cd: = int(s.get("attackCooldownSecondsLeft", 0))
		var time_line: = ""
		if phase == "prep" or prep_left > 0:
			time_line = "准备中 · %s后开战 · 结束 %s" % [
				_format_seconds_left(prep_left), 
				_format_kick_time_left(s.get("endsAt", s.get("ends_at", ""))), 
			]
		elif attack_cd > 0:
			time_line = "进攻冷却 %s · 剩余 %d 次 · %s" % [
				_format_seconds_left(attack_cd), 
				attacks_left, 
				_format_kick_time_left(s.get("endsAt", s.get("ends_at", ""))), 
			]
		else:
			time_line = "剩余进攻 %d 次 · %s" % [
				attacks_left, _format_kick_time_left(s.get("endsAt", s.get("ends_at", "")))
			]
		_add_info_line(box, time_line, true)
		var btn_row: = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		var has_mirror: bool = bool(_gang_mgr.has_gang_mirror)
		var attack: = Button.new()
		if phase == "prep" or prep_left > 0:
			attack.text = "准备中"
		elif attack_cd > 0:
			attack.text = "冷却(%ds)" % attack_cd
		else:
			attack.text = "进攻(%d)" % attacks_left
		attack.custom_minimum_size = Vector2(88, 34)
		attack.disabled = attacks_left <= 0 or not has_mirror or phase == "prep" or prep_left > 0 or attack_cd > 0
		_style_war_interface_button(attack, "kick")
		_bind_siege_action_button(attack, "kick_attack:%d" % session_id, func():
			if _gang_mgr == null or _gang_mgr.gang_network == null:
				return
			if not _gang_mgr.has_gang_mirror:
				_show_gang_message("请先在成员列表更新帮派镜像", false)
				return
			_gang_mgr.gang_network.kick_attack(session_id)
		)
		btn_row.add_child(attack)
		var contrib_left: = int(aq.get("contributionBoughtLeft", 0))
		var buy_contrib: = Button.new()
		buy_contrib.text = "%d帮贡加次(%d/%d)" % [atk_contrib_cost, atk_contrib_limit - contrib_left, atk_contrib_limit]
		buy_contrib.custom_minimum_size = Vector2(130, 34)
		buy_contrib.disabled = contrib_left <= 0
		_style_war_interface_button(buy_contrib, "kick")
		_bind_siege_action_button(buy_contrib, "kick_contrib:%d" % session_id, func():
			if _gang_mgr and _gang_mgr.gang_network:
				_gang_mgr.gang_network.kick_buy_attack_contribution(session_id)
		)
		btn_row.add_child(buy_contrib)
		var yb_left: = int(aq.get("yuanbaoBoughtLeft", 0))
		var buy_yb: = Button.new()
		buy_yb.text = "%d元宝加次(%d/%d)" % [atk_yb_cost, atk_yb_limit - yb_left, atk_yb_limit]
		buy_yb.custom_minimum_size = Vector2(120, 34)
		buy_yb.disabled = yb_left <= 0
		_style_war_interface_button(buy_yb, "kick")
		_bind_siege_action_button(buy_yb, "kick_yuanbao_atk:%d" % session_id, func():
			if _gang_mgr and _gang_mgr.gang_network:
				_gang_mgr.gang_network.kick_buy_attack(session_id)
		)
		btn_row.add_child(buy_yb)
		box.add_child(btn_row)

func _render_kick_defending_cards() -> void :
	if _gang_mgr == null:
		return
	var sessions: Array = _gang_mgr.kick_defending_sessions
	if sessions.is_empty():
		return
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var cfg: Dictionary = _gang_mgr.overview.get("config", {})
	var our_name: = str(gang.get("name", "我方"))
	var our_emblem: = int(gang.get("emblem_id", gang.get("emblemId", 1)))
	var repair_cost: = int(cfg.get("kickRepairContribution", 500))
	var repair_max: = int(cfg.get("kickRepairMaxPerSession", 3))
	var def_yb_cost: = int(cfg.get("kickYuanbaoDefenseCost", 100))
	var def_yb_limit: = int(cfg.get("kickYuanbaoDefenseLimit", 3))
	for s in sessions:
		if not s is Dictionary:
			continue
		var session_id: = int(s.get("sessionId", s.get("session_id", 0)))
		var attacker_gid: = int(s.get("attackerGangId", s.get("attacker_gang_id", 0)))
		var attacker_name: = str(s.get("attackerName", s.get("attacker_name", "攻方")))
		var attacker_emblem: = _lookup_other_gang_emblem_id(attacker_gid)
		var card: = _add_card("防守中")
		var box: = _card_box(card)
		_build_kick_pair_header(box, our_name, our_emblem, "← 来袭", attacker_name, attacker_emblem)
		var dq: Dictionary = s.get("defenseQuota", {})
		var repairs_left: = int(s.get("repairsLeft", dq.get("repairLeft", 0)))
		var repairs_used: = int(s.get("repairsUsed", dq.get("repairUsed", 0)))
		var phase: = str(s.get("phase", "battle"))
		var prep_left: = int(s.get("prepSecondsLeft", 0))
		var repair_cd: = int(s.get("repairCooldownSecondsLeft", 0))
		var status_extra: = ""
		if phase == "prep" or prep_left > 0:
			status_extra = " · 准备中 %s后开战" % _format_seconds_left(prep_left)
		elif repair_cd > 0:
			status_extra = " · 补防冷却 %s" % _format_seconds_left(repair_cd)
		_add_info_line(
			box, 
			"我方耐久 %d/%d · 剩余防守槽 %d · %s%s" % [
				int(s.get("durability", 0)), 
				int(s.get("durabilityMax", s.get("durability_max", 0))), 
				int(s.get("defenseSlotsLeft", 0)), 
				_format_kick_time_left(s.get("endsAt", s.get("ends_at", ""))), 
				status_extra, 
			], 
			true
		)
		_add_info_line(box, "帮贡补防 %d/次 · 每人每场次最多 %d 次（准备期可补防）" % [repair_cost, repair_max], true)
		var btn_row: = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		var repair_btn: = Button.new()
		if repair_cd > 0:
			repair_btn.text = "冷却(%ds)" % repair_cd
		else:
			repair_btn.text = "%d帮贡补防(%d/%d)" % [repair_cost, repairs_used, repair_max]
		repair_btn.custom_minimum_size = Vector2(130, 34)
		repair_btn.disabled = repairs_left <= 0 or repair_cd > 0
		_style_war_interface_button(repair_btn, "kick")
		_bind_siege_action_button(repair_btn, "kick_repair:%d" % session_id, func():
			if _gang_mgr and _gang_mgr.gang_network:
				_gang_mgr.gang_network.kick_repair(session_id)
		)
		btn_row.add_child(repair_btn)
		var yb_def_left: = int(dq.get("yuanbaoDefenseBoughtLeft", 0))
		var buy_def: = Button.new()
		if repair_cd > 0:
			buy_def.text = "冷却(%ds)" % repair_cd
		else:
			buy_def.text = "%d元宝补防(%d/%d)" % [def_yb_cost, def_yb_limit - yb_def_left, def_yb_limit]
		buy_def.custom_minimum_size = Vector2(120, 34)
		buy_def.disabled = yb_def_left <= 0 or repair_cd > 0
		_style_war_interface_button(buy_def, "kick")
		_bind_siege_action_button(buy_def, "kick_yuanbao_def:%d" % session_id, func():
			if _gang_mgr and _gang_mgr.gang_network:
				_gang_mgr.gang_network.kick_buy_defense(session_id)
		)
		btn_row.add_child(buy_def)
		box.add_child(btn_row)

func _render_members() -> void :
	if _gang_mgr == null:
		return
	var can_manage: = _get_viewer_role() <= 3
	if can_manage:
		_add_members_sub_tab_bar()
		if _members_sub_tab == "apply":
			_render_applications_list()
		else:
			_render_members_list()
	else:
		_render_members_list()

func _add_members_sub_tab_bar() -> void :
	_members_sub_tab_buttons.clear()
	var wrap: = HBoxContainer.new()
	wrap.add_theme_constant_override("separation", 6)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var app_count: int = _gang_mgr.applications.size() if _gang_mgr else 0
	var apply_label: = "入帮申请"
	if app_count > 0:
		apply_label = "入帮申请(%d)" % app_count
	for def in [{"key": "list", "label": "成员列表"}, {"key": "apply", "label": apply_label}]:
		var sub_key: String = str(def.get("key", ""))
		var label: String = str(def.get("label", ""))
		var btn: = Button.new()
		btn.text = label
		btn.custom_minimum_size = Vector2(maxi(72, label.length() * 14 + 12), 34)
		btn.add_theme_font_size_override("font_size", 13)
		var picked_key: = sub_key
		btn.pressed.connect( func():
			_on_members_sub_tab_pressed(picked_key)
		)
		wrap.add_child(btn)
		_members_sub_tab_buttons[sub_key] = btn
	_content.add_child(wrap)
	_update_members_sub_tab_styles()

func _on_members_sub_tab_pressed(key: String) -> void :
	if _members_sub_tab == key:
		return
	_members_sub_tab = key
	if key == "apply" and _gang_mgr:
		_gang_mgr.refresh_members(true)
	_render_tab_content()

func _update_members_sub_tab_styles() -> void :
	for key in _members_sub_tab_buttons.keys():
		var btn: Button = _members_sub_tab_buttons[key]
		if btn:
			UIStyle.apply_tab_style(btn, key == _members_sub_tab)

func _render_members_list() -> void :
	if _gang_mgr == null:
		return
	var viewer_role: = _get_viewer_role()
	var my_id: = _get_my_user_id()
	var can_kick: = viewer_role <= 2
	var is_leader: = viewer_role == 1
	var card: = _add_card("成员列表")
	var box: = _card_box(card)
	var members: Array = _gang_mgr.members
	if members.is_empty():
		_add_info_line(box, "暂无成员数据，请稍候或切换 Tab 重试", true)
		return
	for m in members:
		if m is Dictionary:
			_render_member_row(box, m, my_id, is_leader, can_kick)

func _render_applications_list() -> void :
	var card: = _add_card("待审批")
	var box: = _card_box(card)
	var apps: Array = _gang_mgr.applications if _gang_mgr else []
	if apps.is_empty():
		_add_info_line(box, "暂无待审批申请", true)
		return
	for app_row in apps:
		if app_row is Dictionary:
			_render_application_row(box, app_row)

func _format_application_time(iso_str: String) -> String:
	var raw: = str(iso_str).strip_edges()
	if raw.is_empty():
		return "—"
	if raw.contains("T"):
		raw = raw.replace("T", " ")
	if raw.ends_with("Z"):
		raw = raw.substr(0, raw.length() - 1)
	if raw.contains("."):
		raw = raw.substr(0, raw.find("."))
	if raw.length() >= 16:
		return raw.substr(0, 16)
	return raw


func _format_member_activity(m: Dictionary) -> String:
	if bool(m.get("isOnline", m.get("is_online", false))):
		return "在线"
	var offline_sec: = int(m.get("offlineSeconds", m.get("offline_seconds", -1)))
	if offline_sec < 0:
		return "暂无活跃记录"
	if offline_sec < 60:
		return "离线不到1分钟"
	var mins: = offline_sec / 60
	if mins < 60:
		return "离线%d分钟" % maxi(mins, 1)
	var hours: = mins / 60
	if hours < 24:
		return "离线%d小时" % maxi(hours, 1)
	var days: = hours / 24
	return "离线%d天" % maxi(days, 1)

func _member_activity_color(m: Dictionary) -> Color:
	if bool(m.get("isOnline", m.get("is_online", false))):
		return Color(0.45, 0.9, 0.55)
	var offline_sec: = int(m.get("offlineSeconds", m.get("offline_seconds", -1)))
	if offline_sec < 0:
		return Color(0.072, 0.080, 0.079)
	if offline_sec < 3600:
		return Color(0.072, 0.080, 0.079)
	return Color(0.072, 0.080, 0.079)

func _prompt_approve_application(app_row: Dictionary, app_id: int, approve: bool) -> void :
	var name: = _member_display_name(app_row)
	var title: = "批准入帮" if approve else "拒绝申请"
	var msg: = "确定批准 %s 加入帮派？" % name if approve else "确定拒绝 %s 的入帮申请？" % name
	var btn: = "确认批准" if approve else "确认拒绝"
	_confirm_gang_action(title, msg, func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.approve_application(app_id, approve)
	, btn)

func _render_application_row(parent: Node, app_row: Dictionary) -> void :
	var character_id: = int(app_row.get("characterId", app_row.get("character_id", 0)))
	var app_id: = int(app_row.get("id", 0))
	var row: = Panel.new()
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	row.custom_minimum_size = Vector2(0, MEMBER_ROW_HEIGHT)
	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)
	var outer: = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	outer.add_child(_create_member_avatar(character_id))
	outer.add_child(_create_application_info_col(app_row))
	outer.add_child(_create_member_action_col([
		{
			"text": "批准", 
			"callback": func():
				_prompt_approve_application(app_row, app_id, true), 
		}, 
		{
			"text": "拒绝", 
			"callback": func():
				_prompt_approve_application(app_row, app_id, false), 
		}, 
	]))
	parent.add_child(row)

func _create_member_avatar(character_id: int) -> Control:
	var frame: = Panel.new()
	frame.custom_minimum_size = MEMBER_AVATAR_SIZE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var holder: = Control.new()
	holder.name = "PortraitHolder"
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(holder)
	var cid: = PlayerCharacterConfig.normalize_id(character_id)
	var path: = PlayerCharacterConfig.get_avatar_tx_path(cid)
	if not ResourceLoader.exists(path):
		path = PlayerCharacterConfig.get_avatar_tx_path(0)
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		var avatar: = TextureRect.new()
		avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
		avatar.texture = tex
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(avatar)
	return frame

func _member_profile_line(m: Dictionary) -> String:
	var level: = int(m.get("level", 1))
	var realm: = str(m.get("realm", "—")).strip_edges()
	if realm.is_empty():
		realm = "—"
	var reinc: = int(m.get("reincarnation", m.get("reincarnation_count", 0)))
	var parts: PackedStringArray = PackedStringArray(["Lv.%d" % maxi(1, level), realm])
	if reinc > 0:
		parts.append("投胎%d" % reinc)
	return " · ".join(parts)

func _member_name_role_line(m: Dictionary) -> String:
	return "%s（%s）" % [_member_display_name(m), _member_role_name(m)]

func _member_weekly_donation(m: Dictionary) -> int:
	return int(m.get("weekly_donation", m.get("weeklyDonation", 0)))

func _member_daily_donation(m: Dictionary) -> int:
	return int(m.get("daily_donation", m.get("dailyDonation", 0)))

func _create_member_info_col(m: Dictionary) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	var name_lbl: = Label.new()
	name_lbl.text = _member_name_role_line(m)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	col.add_child(name_lbl)
	var donation_lbl: = Label.new()
	donation_lbl.text = "本周捐献 %d  今日捐献 %d" % [_member_weekly_donation(m), _member_daily_donation(m)]
	donation_lbl.clip_text = true
	donation_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	donation_lbl.add_theme_font_size_override("font_size", 13)
	donation_lbl.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	col.add_child(donation_lbl)
	var profile_lbl: = Label.new()
	profile_lbl.text = _member_profile_line(m)
	profile_lbl.clip_text = true
	profile_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	profile_lbl.add_theme_font_size_override("font_size", 13)
	profile_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	col.add_child(profile_lbl)
	var activity_lbl: = Label.new()
	activity_lbl.text = _format_member_activity(m)
	activity_lbl.clip_text = true
	activity_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	activity_lbl.add_theme_font_size_override("font_size", 12)
	activity_lbl.add_theme_color_override("font_color", _member_activity_color(m))
	col.add_child(activity_lbl)
	return col

func _create_application_info_col(app_row: Dictionary) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	var top: = HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_constant_override("separation", 10)
	var name_lbl: = Label.new()
	name_lbl.text = _member_display_name(app_row)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	top.add_child(name_lbl)
	var time_lbl: = Label.new()
	time_lbl.text = _format_application_time(str(app_row.get("created_at", "")))
	time_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.add_theme_font_size_override("font_size", 14)
	time_lbl.add_theme_color_override("font_color", Color(0.760, 0.740, 0.680))
	top.add_child(time_lbl)
	col.add_child(top)
	var profile_lbl: = Label.new()
	profile_lbl.text = _member_profile_line(app_row)
	profile_lbl.clip_text = true
	profile_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	profile_lbl.add_theme_font_size_override("font_size", 13)
	profile_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	col.add_child(profile_lbl)
	return col

func _create_member_action_col(button_specs: Array) -> VBoxContainer:
	var col: = VBoxContainer.new()
	col.custom_minimum_size.x = GANG_ROW_ACTION_BTN_SIZE.x
	col.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	for spec in button_specs:
		if not spec is Dictionary:
			continue
		var btn_size: Vector2 = spec.get("size", GANG_ROW_ACTION_BTN_SIZE)
		_add_small_button(
			col, 
			str(spec.get("text", "")), 
			spec.get("callback", Callable()), 
			bool(spec.get("golden", false)), 
			btn_size
		)
	return col

func _close_member_action_layer(layer: Control) -> void :
	if layer != null and is_instance_valid(layer):
		layer.queue_free()

func _style_gang_popup_button(btn: Button, is_confirm: bool = true) -> void :
	ConfirmDialog.style_button(btn, is_confirm)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _show_member_manage_popup(m: Dictionary, target_id: int, is_leader: bool, can_kick: bool, target_role: int) -> void :
	var layer: = Control.new()
	layer.name = "MemberActionLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 200
	add_child(layer)
	var dim: = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.631, 0.611, 0.564, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var popup: = Panel.new()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.custom_minimum_size = Vector2(ConfirmDialog.POPUP_WIDTH, 0)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(popup)
	var host_size: = size if size.x > 1.0 and size.y > 1.0 else get_viewport_rect().size
	popup.position = Vector2(
		maxf(8.0, (host_size.x - float(ConfirmDialog.POPUP_WIDTH)) * 0.5), 
		maxf(8.0, (host_size.y - 360.0) * 0.5)
	)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 18
	vbox.offset_right = -20
	vbox.offset_bottom = -18
	vbox.add_theme_constant_override("separation", 10)
	popup.add_child(vbox)
	var title: = Label.new()
	title.text = _member_name_role_line(m)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(title)
	var subtitle: = Label.new()
	subtitle.text = _member_profile_line(m)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	vbox.add_child(subtitle)
	vbox.add_child(HSeparator.new())
	var close_popup: = func(): _close_member_action_layer(layer)
	dim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close_popup.call()
	)
	if is_leader and target_role != 1:
		var role_actions: Array = [
			{"label": "设副帮主", "role": 2}, 
			{"label": "设精英", "role": 3}, 
			{"label": "设成员", "role": 4}, 
		]
		for action in role_actions:
			var btn: = Button.new()
			btn.text = str(action.get("label", ""))
			btn.custom_minimum_size = Vector2(0, 40)
			_style_gang_popup_button(btn, true)
			var role_id: = int(action.get("role", 4))
			btn.pressed.connect( func():
				close_popup.call()
				if _gang_mgr and _gang_mgr.gang_network:
					_gang_mgr.gang_network.set_member_role(target_id, role_id)
			)
			vbox.add_child(btn)
		var transfer_btn: = Button.new()
		transfer_btn.text = "禅让帮主"
		transfer_btn.custom_minimum_size = Vector2(0, 40)
		_style_gang_popup_button(transfer_btn, true)
		transfer_btn.pressed.connect( func():
			close_popup.call()
			_prompt_transfer_leadership(m, target_id)
		)
		vbox.add_child(transfer_btn)
	if can_kick and target_role != 1:
		var kick_btn: = Button.new()
		kick_btn.text = "踢出帮派"
		kick_btn.custom_minimum_size = Vector2(0, 40)
		_style_gang_popup_button(kick_btn, false)
		kick_btn.pressed.connect( func():
			close_popup.call()
			_prompt_kick_member(m, target_id)
		)
		vbox.add_child(kick_btn)
	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	_style_gang_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect(close_popup)
	vbox.add_child(cancel_btn)
	var content_h: = 18.0 + 18.0 + 28.0 + 18.0 + 12.0 + 10.0
	for child in vbox.get_children():
		if child is Button:
			content_h += 42.0 + 10.0
		elif child is HSeparator:
			content_h += 12.0
	content_h += 40.0
	popup.custom_minimum_size.y = content_h
	popup.size.y = content_h
	popup.position.y = maxf(8.0, (host_size.y - content_h) * 0.5)

func _render_member_row(parent: Node, m: Dictionary, my_id: int, is_leader: bool, can_kick: bool) -> void :
	var target_id: = int(m.get("user_id", m.get("userId", 0)))
	var target_role: = int(m.get("role", 4))
	var character_id: = int(m.get("characterId", m.get("character_id", 0)))
	var row: = Panel.new()
	row.clip_contents = true
	row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	row.custom_minimum_size = Vector2(0, MEMBER_ROW_HEIGHT)
	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)
	var outer: = HBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	outer.add_child(_create_member_avatar(character_id))
	outer.add_child(_create_member_info_col(m))
	if target_id <= 0 or target_id == my_id:
		outer.add_child(_create_member_action_col([
			{
				"text": "更新/查看镜像", 
				"golden": true, 
				"callback": func():
					if game_manager and game_manager.has_method("open_gang_mirror_popup_from_ui"):
						game_manager.open_gang_mirror_popup_from_ui(self), 
			}, 
			{
				"text": "退出帮派", 
				"callback": _prompt_leave_gang, 
			}, 
		]))
	elif (is_leader or can_kick) and target_role != 1:
		outer.add_child(_create_member_action_col([
			{
				"text": "点击操作", 
				"callback": func():
					_show_member_manage_popup(m, target_id, is_leader, can_kick, target_role), 
			}, 
		]))
	parent.add_child(row)

func _render_donate() -> void :
	var cfg: Dictionary = _gang_mgr.overview.get("config", {}) if _gang_mgr else {}
	var donations: Dictionary = cfg.get("donations", {})
	var remain_line: = _format_donate_remain_line(donations)
	var card: = _add_card("每日捐献", Callable(), remain_line)
	var box: = _card_box(card)
	var donate_defs: Array = [
		{
			"type": "gold", 
			"label": "捐献金币", 
			"hint": "每次 %s 金币 · 帮贡 +%d · 帮派建设材料 +%d · 每日最多 %d 次" % [
				_format_big_number(int((donations.get("gold", {}) as Dictionary).get("costGold", 10000000))), 
				int((donations.get("gold", {}) as Dictionary).get("contribution", 100)), 
				int((donations.get("gold", {}) as Dictionary).get("materialsGained", 1)), 
				int((donations.get("gold", {}) as Dictionary).get("dailyLimit", 3)), 
			], 
		}, 
		{
			"type": "yuanbao", 
			"label": "捐献元宝", 
			"hint": "每次 %d 元宝 · 帮贡 +%d · 帮派建设材料 +%d · 每日最多 %d 次" % [
				int((donations.get("yuanbao", {}) as Dictionary).get("costYuanbao", 100)), 
				int((donations.get("yuanbao", {}) as Dictionary).get("contribution", 200)), 
				int((donations.get("yuanbao", {}) as Dictionary).get("materialsGained", 2)), 
				int((donations.get("yuanbao", {}) as Dictionary).get("dailyLimit", 3)), 
			], 
		}, 
		{
			"type": "material", 
			"label": "捐献建设材料", 
			"hint": "消耗背包道具【建设材料】×1 · 帮贡 +%d · 帮派建设材料 +%d · 每日最多 %d 次" % [
				int((donations.get("material", {}) as Dictionary).get("contribution", 10)), 
				int((donations.get("material", {}) as Dictionary).get("materialsGained", 1)), 
				int((donations.get("material", {}) as Dictionary).get("dailyLimit", 50)), 
			], 
		}, 
	]
	for def in donate_defs:
		if not def is Dictionary:
			continue
		var donate_type: String = str(def.get("type", ""))
		var btn: = _add_action_list_row(box, str(def.get("hint", "")), str(def.get("label", "捐献")))
		btn.pressed.connect( func():
			_try_donate_material(donate_type, btn)
		)

func _format_donate_remain_line(donations: Dictionary) -> String:
	var mem: Dictionary = _gang_mgr.overview.get("membership", {}) if _gang_mgr else {}
	var used: Dictionary = mem.get("dailyDonateUsed", mem.get("daily_donate_used", {}))
	if not used is Dictionary:
		used = {}
	var gold_limit: = int((donations.get("gold", {}) as Dictionary).get("dailyLimit", 3))
	var yuanbao_limit: = int((donations.get("yuanbao", {}) as Dictionary).get("dailyLimit", 3))
	var material_limit: = int((donations.get("material", {}) as Dictionary).get("dailyLimit", 50))
	var gold_left: = maxi(0, gold_limit - int(used.get("gold", 0)))
	var yuanbao_left: = maxi(0, yuanbao_limit - int(used.get("yuanbao", 0)))
	var material_left: = maxi(0, material_limit - int(used.get("material", 0)))
	return "剩余捐献次数 金币 %d 元宝 %d 建设材料 %d" % [gold_left, yuanbao_left, material_left]

func _format_big_number(value: int) -> String:
	if value >= 100000000:
		if value % 100000000 == 0:
			return "%d亿" % int(value / 100000000)
		return "%.1f亿" % (value / 100000000.0)
	if value >= 10000:
		if value % 10000 == 0:
			return "%d万" % int(value / 10000)
		return "%.1f万" % (value / 10000.0)
	return str(value)

func _bid_fund_step(cfg: Dictionary) -> int:
	return maxi(1, int(cfg.get("siegeMinBidIncrement", BID_FUND_UNIT)))

func _bid_wan_min(cfg: Dictionary, base_bid: int) -> int:
	var step: = _bid_fund_step(cfg)
	return maxi(1, int(ceil(float(base_bid) / float(step))))

func _bid_wan_default_text(cfg: Dictionary, base_bid: int) -> String:
	return str(_bid_wan_min(cfg, base_bid))

func _parse_bid_wan_amount(text: String, base_bid: int, cfg: Dictionary) -> Dictionary:
	var step: = _bid_fund_step(cfg)
	var trimmed: = text.strip_edges()
	if trimmed.is_empty():
		return {"ok": false, "error": "请输入出价（万）"}
	if not trimmed.is_valid_int():
		return {"ok": false, "error": "出价须为整数（万）"}
	var wan: = int(trimmed)
	if wan <= 0:
		return {"ok": false, "error": "出价须大于 0 万"}
	var amount: = wan * step
	if amount < base_bid:
		return {"ok": false, "error": "出价不得低于底价 %s" % _format_big_number(base_bid)}
	if amount % step != 0:
		return {"ok": false, "error": "出价须为整万（1万的整数倍）"}
	return {"ok": true, "amount": amount, "wan": wan}

func _add_bid_wan_input_row(parent: Node, cfg: Dictionary, base_bid: int) -> LineEdit:
	var bid_wan_min: = _bid_wan_min(cfg, base_bid)
	_add_territory_hint_line(parent, "出价单位：万（1万 = 帮派资金 %s）" % _format_big_number(BID_FUND_UNIT))
	_add_territory_hint_line(parent, "底价 %d 万，请输入整数" % bid_wan_min)
	var row: = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var bid_edit: = LineEdit.new()
	bid_edit.text = _bid_wan_default_text(cfg, base_bid)
	bid_edit.custom_minimum_size = Vector2(0, 38)
	bid_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bid_edit.placeholder_text = str(bid_wan_min)
	bid_edit.add_theme_font_size_override("font_size", 16)
	row.add_child(bid_edit)
	var unit_lbl: = Label.new()
	unit_lbl.text = "万"
	unit_lbl.custom_minimum_size = Vector2(32, 38)
	unit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unit_lbl.add_theme_font_size_override("font_size", 18)
	unit_lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	row.add_child(unit_lbl)
	return bid_edit

func _process(delta: float) -> void :
	if _tab != "shop" or _gang_mgr == null:
		return
	_shop_week_poll_sec += delta
	if _shop_week_poll_sec < SHOP_WEEK_POLL_INTERVAL:
		return
	_shop_week_poll_sec = 0.0
	_maybe_refresh_shop_for_new_beijing_week()

func _beijing_gang_week_key(now_unix: int = -1) -> String:
	var unix_ts: = now_unix
	if unix_ts < 0:
		unix_ts = int(Time.get_unix_time_from_system())
		if game_manager and game_manager.has_method("get_authoritative_unix_time"):
			var auth: = int(game_manager.get_authoritative_unix_time(true))
			if auth > 0:
				unix_ts = auth
	var bj_unix: = unix_ts + BEIJING_OFFSET_SEC
	var dt: = Time.get_datetime_dict_from_unix_time(bj_unix)
	var wd: int = int(dt.get("weekday", 1))
	var days_back: = wd - 1
	var sec_of_day: = int(dt.hour) * 3600 + int(dt.minute) * 60 + int(dt.second)
	var noon_unix: = bj_unix - sec_of_day + 12 * 3600
	var mon_unix: = noon_unix - days_back * 86400
	var mon: = Time.get_datetime_dict_from_unix_time(mon_unix)
	return "%04d-%02d-%02d" % [int(mon.year), int(mon.month), int(mon.day)]

func _maybe_refresh_shop_for_new_beijing_week() -> void :
	if _gang_mgr == null:
		return
	var key: = _beijing_gang_week_key()
	if key.is_empty():
		return
	if _shop_week_key_anchor.is_empty():
		_shop_week_key_anchor = key
		return
	if key == _shop_week_key_anchor:
		return
	_shop_week_key_anchor = key
	_shop_fetch_started = false
	_gang_mgr.refresh_shop()

func _render_shop() -> void :
	var card: = _add_card("帮贡商店")
	var box: = _card_box(card)
	if _gang_mgr == null:
		_add_info_line(box, "帮派模块未就绪", true)
		return
	if _gang_mgr.shop_data.is_empty():
		if not _shop_fetch_started:
			_shop_fetch_started = true
			_add_info_line(box, "商店加载中…", true)
			_gang_mgr.refresh_shop()
		else:
			_add_info_line(box, "商店加载失败，请切换 Tab 重试", true)
		return
	var items: Array = _gang_mgr.shop_data.get("items", [])
	if items.is_empty():
		_add_info_line(box, "暂无商品配置", true)
		return
	for it in items:
		if not it is Dictionary:
			continue
		var row: = Panel.new()
		row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		row.custom_minimum_size = Vector2(0, 48)
		var h: = HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 10
		h.offset_top = 6
		h.offset_right = -10
		h.offset_bottom = -6
		row.add_child(h)
		var locked: = bool(it.get("locked", false))
		var min_lv: = int(it.get("minGangLevel", 1))
		var lbl: = Label.new()
		var label_text: = "%s  ·  %d 帮贡  ·  本周剩 %d" % [
			str(it.get("itemName", "")), 
			int(it.get("cost", 0)), 
			int(it.get("remaining", 0)), 
		]
		if locked:
			label_text += "  ·  需帮派 Lv.%d" % min_lv
		lbl.text = label_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 15)
		if locked:
			lbl.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		h.add_child(lbl)
		var buy: = _add_row_action_button(h, "兑换")
		buy.disabled = locked or int(it.get("remaining", 0)) <= 0
		var shop_id: String = str(it.get("id", ""))
		buy.pressed.connect( func():
			if _gang_mgr and _gang_mgr.gang_network:
				buy.disabled = true
				buy.text = "…"
				_gang_mgr.gang_network.buy_shop_item(shop_id)
		)
		box.add_child(row)

func _render_war() -> void :
	var cfg: Dictionary = _merged_siege_rules_cfg()
	var siege: Dictionary = _gang_mgr.siege_status if _gang_mgr else {}
	var claim_btn_spec: Array = []
	if _gang_mgr and _owns_any_territory():
		var claimable: = bool(_gang_mgr.territory_claim_status.get("claimable", false))
		claim_btn_spec.append({
			"text": "一键领取领地收益" if claimable else "今日已领取", 
			"disabled": not claimable, 
			"callback": Callable(self, "_on_claim_territory_daily_pressed"), 
		})
	claim_btn_spec.insert(0, {
		"text": "领地战记录", 
		"callback": Callable(self, "_on_siege_history_pressed"), 
	})
	var map_card: = _add_card(
		"领土地图", 
		func(): _show_gang_rules_popup("领地争夺战规则", GangConfig.build_territory_siege_rules_text(cfg)), 
		"", 
		claim_btn_spec, 
		true
	)
	var map_box: = _card_box(map_card)
	if not bool(siege.get("siegeWarOpen", true)):
		_add_info_line(map_box, "服务器帮派数量不足 3 个，领地战暂未开放", true)
	var territories: Array = _gang_mgr.territories if _gang_mgr else {}
	if territories.is_empty():
		_add_info_line(map_box, "领地数据加载中…", true)
	else:
		map_box.add_child(_build_territory_grid(territories, siege))
		var phase: = str(siege.get("phase", ""))
		if not phase.is_empty():
			_add_info_line(map_box, _format_siege_phase_hint(siege), true)
	if bool(siege.get("siegeWarOpen", true)):
		var siege_card: = _add_card("领地挑战")
		var siege_box: = _card_box(siege_card)
		if _render_siege_active_sessions(siege_box) <= 0:
			_add_info_line(siege_box, "暂无进行中的领地挑战", true)
	var log_card: = _add_card("参与日志")
	var log_box: = _card_box(log_card)
	var logs: Array = _gang_mgr.participation_logs if _gang_mgr else siege.get("participationLogs", [])
	if logs.is_empty():
		_add_info_line(log_box, "暂无参与记录", true)
	else:
		var panel: = GangWarLogPanel.new()
		panel.custom_minimum_size = Vector2(0, 180)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.set_entries(_normalize_participation_logs(logs))
		log_box.add_child(panel)
	var rep_card: = _add_card("战报")
	var rep_box: = _card_box(rep_card)
	_render_war_reports_section(rep_box)

func _owns_any_territory() -> bool:
	if _gang_mgr == null:
		return false
	var my_gang_id: = _get_my_gang_id()
	if my_gang_id <= 0:
		return false
	for t in _gang_mgr.territories:
		if t is Dictionary and int(t.get("ownerGangId", t.get("owner_gang_id", 0))) == my_gang_id:
			return true
	return false

func _on_claim_territory_daily_pressed() -> void :
	if _gang_mgr == null or _gang_mgr.gang_network == null:
		return
	_gang_mgr.gang_network.claim_territory_daily_all()

func _normalize_participation_logs(logs: Array) -> Array:
	var out: Array = []
	for entry in logs:
		if not entry is Dictionary:
			continue
		var row: Dictionary = entry.duplicate(true)
		if not row.has("message") and row.has("text"):
			row["message"] = str(row.get("text", ""))
		out.append(row)
	return out

func _normalize_kick_activity_logs(logs: Array) -> Array:
	var out: Array = []
	for entry in logs:
		if not entry is Dictionary:
			continue
		var row: Dictionary = entry.duplicate(true)
		var raw_type: = str(row.get("type", row.get("log_type", "")))
		if raw_type.begins_with("kick_"):
			raw_type = raw_type.substr(5)
		row["type"] = raw_type
		if not row.has("message") and row.has("text"):
			row["message"] = str(row.get("text", ""))
		out.append(row)
	return out

func _render_kick_activity_feed() -> void :
	var feed_card: = _add_card("帮战动态")
	var feed_box: = _card_box(feed_card)
	var logs: Array = _gang_mgr.kick_activity_logs if _gang_mgr else []
	if logs.is_empty():
		_add_info_line(feed_box, "暂无帮战动态", true)
		return
	var panel: = GangWarLogPanel.new()
	panel.custom_minimum_size = Vector2(0, 180)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_entries(_normalize_kick_activity_logs(logs))
	feed_box.add_child(panel)

func _on_kick_history_pressed() -> void :
	if _gang_mgr == null:
		return
	_show_war_history_popup("帮战记录", "kick")
	_gang_mgr.refresh_kick_history()

func _on_siege_history_pressed() -> void :
	if _gang_mgr == null:
		return
	_show_war_history_popup("领地战记录", "siege")
	_gang_mgr.refresh_siege_history()

func _format_history_delta(v: int, empty_dash: bool = true) -> String:
	if v == 0:
		return "—" if empty_dash else "0"
	return "+%d" % v if v > 0 else str(v)

func _format_kick_history_line(rec: Dictionary) -> String:
	var created: = str(rec.get("createdAt", rec.get("created_at", "")))
	var date_part: = created
	if created.length() >= 16:
		date_part = created.substr(0, 16).replace("T", " ")
	elif created.length() >= 10:
		date_part = created.substr(0, 10)
	var role: = str(rec.get("role", ""))
	var role_label: = "进攻" if role == "attacker" else ("防守" if role == "defender" else "—")
	var opp: = str(rec.get("opponentName", ""))
	if opp.is_empty():
		opp = "对方"
	var result: = str(rec.get("result", ""))
	var result_label: = "胜利" if result == "win" else ("失败" if result == "lose" else str(rec.get("title", "结果")))
	var rep: = _format_history_delta(int(rec.get("reputationDelta", 0)))
	var fund: = _format_history_delta(int(rec.get("fundDelta", 0)))
	var mat: = _format_history_delta(int(rec.get("materialDelta", 0)))
	return "%s · %s · 对【%s】 · %s · 声望%s · 资金%s · 材料%s" % [
		date_part, role_label, opp, result_label, rep, fund, mat
	]

func _format_siege_history_line(rec: Dictionary) -> String:
	var created: = str(rec.get("createdAt", rec.get("created_at", "")))
	var date_part: = created
	if created.length() >= 16:
		date_part = created.substr(0, 16).replace("T", " ")
	elif created.length() >= 10:
		date_part = created.substr(0, 10)
	var role: = str(rec.get("role", ""))
	var role_label: = "进攻" if role == "attacker" else ("防守" if role == "defender" else "—")
	var opp: = str(rec.get("opponentName", ""))
	if opp.is_empty():
		opp = "中立/系统"
	var terr: = str(rec.get("territoryName", ""))
	if terr.is_empty():
		terr = "领地"
	var result: = str(rec.get("result", ""))
	var result_label: = "胜利"
	match result:
		"win":
			result_label = "胜利"
		"lose":
			result_label = "失败"
		"cap_blocked":
			result_label = "击破未占"
		_:
			result_label = str(rec.get("title", "结果"))
	var rep: = _format_history_delta(int(rec.get("reputationDelta", 0)))
	var fund: = _format_history_delta(int(rec.get("fundDelta", 0)))
	var mat: = _format_history_delta(int(rec.get("materialDelta", 0)))
	return "%s · %s · 对【%s】 · 【%s】%s · 声望%s · 资金%s · 材料%s" % [
		date_part, role_label, opp, terr, result_label, rep, fund, mat
	]

func _show_war_history_popup(title: String, kind: String) -> void :
	var existing: = get_node_or_null("WarHistoryLayer")
	if existing:
		existing.queue_free()
	var layer: = Control.new()
	layer.name = "WarHistoryLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 210
	add_child(layer)
	var dim: = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.631, 0.611, 0.564, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var popup: = Panel.new()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	layer.add_child(popup)
	var host_size: = size if size.x > 1.0 and size.y > 1.0 else get_viewport_rect().size
	var popup_w: = minf(560.0, host_size.x - 24.0)
	var popup_h: = clampf(host_size.y * 0.68, 360.0, 580.0)
	popup.custom_minimum_size = Vector2(popup_w, popup_h)
	popup.size = Vector2(popup_w, popup_h)
	popup.position = Vector2(
		maxf(8.0, (host_size.x - popup_w) * 0.5), 
		maxf(8.0, (host_size.y - popup_h) * 0.5)
	)
	var outer: = VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 16
	outer.offset_top = 14
	outer.offset_right = -16
	outer.offset_bottom = -14
	outer.add_theme_constant_override("separation", 10)
	popup.add_child(outer)
	var title_lbl: = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	outer.add_child(title_lbl)
	var status_lbl: = Label.new()
	status_lbl.name = "HistoryStatus"
	status_lbl.text = "加载中…"
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_lbl.add_theme_font_size_override("font_size", 14)
	status_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	outer.add_child(status_lbl)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list: = VBoxContainer.new()
	list.name = "HistoryList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	var ok_btn: = Button.new()
	ok_btn.text = "关闭"
	ok_btn.custom_minimum_size = Vector2(140, 42)
	ok_btn.add_theme_font_size_override("font_size", 16)
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): layer.queue_free())
	outer.add_child(ok_btn)
	dim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			layer.queue_free()
	)
	var refresh_ui: = func():
		if not is_instance_valid(layer) or _gang_mgr == null:
			return
		var st: Label = layer.find_child("HistoryStatus", true, false) as Label
		var lst: VBoxContainer = layer.find_child("HistoryList", true, false) as VBoxContainer
		if st == null or lst == null:
			return
		for c in lst.get_children():
			c.queue_free()
		var loading: = false
		var err: = ""
		var records: Array = []
		if kind == "kick":
			loading = _gang_mgr.kick_history_loading
			err = _gang_mgr.kick_history_error
			records = _gang_mgr.kick_history
		else:
			loading = _gang_mgr.siege_history_loading
			err = _gang_mgr.siege_history_error
			records = _gang_mgr.siege_history
		if loading:
			st.text = "加载中…"
			return
		if not err.is_empty():
			st.text = "加载失败：%s" % err
			return
		if records.is_empty():
			st.text = "暂无记录（上线后新结算的场次会出现在这里）"
			return
		st.text = "共 %d 条" % records.size()
		for rec in records:
			if not rec is Dictionary:
				continue
			var line: = Label.new()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_theme_font_size_override("font_size", 14)
			line.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
			if kind == "kick":
				line.text = _format_kick_history_line(rec)
			else:
				line.text = _format_siege_history_line(rec)
			lst.add_child(line)
	if _gang_mgr:
		if kind == "kick":
			if not _gang_mgr.kick_history_updated.is_connected(refresh_ui):
				_gang_mgr.kick_history_updated.connect(refresh_ui)
		else:
			if not _gang_mgr.siege_history_updated.is_connected(refresh_ui):
				_gang_mgr.siege_history_updated.connect(refresh_ui)
	refresh_ui.call()
	layer.tree_exiting.connect( func():
		if _gang_mgr == null:
			return
		if kind == "kick" and _gang_mgr.kick_history_updated.is_connected(refresh_ui):
			_gang_mgr.kick_history_updated.disconnect(refresh_ui)
		elif kind == "siege" and _gang_mgr.siege_history_updated.is_connected(refresh_ui):
			_gang_mgr.siege_history_updated.disconnect(refresh_ui)
	)

func _report_has_battle_replay(log_entries: Array) -> bool:
	for entry in log_entries:
		if not entry is Dictionary:
			continue
		var battle_log: Variant = entry.get("battleLog", entry.get("battle_log", []))
		if battle_log is Array and not battle_log.is_empty():
			return true
	return false

func _war_report_type_label(report_type: String) -> String:
	match report_type:
		"siege_win":
			return "攻占"
		"siege_loss":
			return "失守"
		"siege_defense":
			return "防守"
		"siege_fail":
			return "失败"
		"siege_win_cap":
			return "击破"
		_:
			return report_type if not report_type.is_empty() else "战报"

func _format_war_report_summary(report: Dictionary) -> String:
	var summary_text: = str(report.get("summary", report.get("title", "")))
	if summary_text.is_empty():
		return "领地战结果"
	return summary_text

func _participation_logs_have_capture() -> bool:
	if _gang_mgr == null:
		return false
	for entry in _gang_mgr.participation_logs:
		if not entry is Dictionary:
			continue
		if _is_siege_capture_log_entry(entry):
			return true
	return false

func _is_siege_capture_log_entry(entry: Dictionary) -> bool:
	if bool(entry.get("captured", false)):
		return true
	var extra = entry.get("extra", entry.get("extra_json", {}))
	if extra is Dictionary and bool(extra.get("captured", false)):
		return true
	var text: = str(entry.get("message", entry.get("text", "")))
	return _is_siege_capture_log_text(text)

func _is_siege_capture_log_text(text: String) -> bool:
	if text.contains("成功占领"):
		return true
	return text.contains("耐久 0/") or text.contains("耐久0/")

func _extract_territory_name_from_log(text: String) -> String:

	var last_start: = text.rfind("【")
	if last_start < 0:
		return ""
	var sub: = text.substr(last_start + 1)
	var end: = sub.find("】")
	if end < 0:
		return ""
	return sub.substr(0, end)

func _build_capture_reports_from_participation_logs() -> Array:
	var out: Array = []
	if _gang_mgr == null:
		return out
	var seen: Dictionary = {}
	for entry in _gang_mgr.participation_logs:
		if not entry is Dictionary:
			continue
		var text: = str(entry.get("message", entry.get("text", "")))
		if not _is_siege_capture_log_entry(entry):
			continue
		var round_id: = int(entry.get("roundId", entry.get("round_id", 0)))
		var extra = entry.get("extra", {})
		if round_id <= 0 and extra is Dictionary:
			round_id = int(extra.get("roundId", extra.get("round_id", 0)))
		var key: = str(round_id) if round_id > 0 else text
		if seen.has(key):
			continue
		seen[key] = true
		var terr_name: = ""
		if extra is Dictionary:
			terr_name = str(extra.get("territoryName", extra.get("territory_name", "")))
		if terr_name.is_empty():
			terr_name = _extract_territory_name_from_log(text)
		if terr_name.is_empty():
			terr_name = "领地"
		out.append({
			"reportType": "siege_win", 
			"summary": "成功占领【%s】" % terr_name, 
			"log": [], 
		})
	return out

func _render_war_reports_section(parent: Node) -> void :
	if _gang_mgr == null:
		_add_info_line(parent, "暂无战报", true)
		return
	if _gang_mgr.war_reports_loading:
		_add_info_line(parent, "战报加载中…", true)
		return
	if not _gang_mgr.war_reports_error.is_empty():
		_add_info_line(parent, "战报加载失败，请重试", true)
		var retry_btn: = _add_styled_button(parent, "重新加载战报")
		retry_btn.pressed.connect( func():
			if _gang_mgr:
				_gang_mgr.refresh_war_reports()
		)
		return
	var reports: Array = []
	for r in _gang_mgr.war_reports:
		if r is Dictionary:
			reports.append(r)
	if reports.is_empty():
		reports = _build_capture_reports_from_participation_logs()
	if reports.is_empty():
		_add_info_line(parent, "暂无战报", true)
		return
	var scroll: = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var list: = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for r in reports:
		if not r is Dictionary:
			continue
		var row_panel: = Panel.new()
		row_panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		row_panel.clip_contents = true
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(row_panel)
		var margin: = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		row_panel.add_child(margin)
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(row)
		var summary_lbl: = Label.new()
		var report_type: = str(r.get("reportType", r.get("report_type", "")))
		var type_label: = _war_report_type_label(report_type)
		var summary_text: = _format_war_report_summary(r)
		summary_lbl.text = "[%s] %s" % [type_label, summary_text]
		summary_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_lbl.size_flags_stretch_ratio = 1.0
		summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_lbl.max_lines_visible = 3
		summary_lbl.add_theme_font_size_override("font_size", 14)
		summary_lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		row.add_child(summary_lbl)
		var log_entries: Array = r.get("log", [])
		if _report_has_battle_replay(log_entries):
			var replay_btn: = Button.new()
			replay_btn.text = "查看战报"
			replay_btn.custom_minimum_size = Vector2(96, 32)
			replay_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
			_style_war_interface_button(replay_btn)
			var report_copy: Dictionary = r.duplicate(true)
			replay_btn.pressed.connect( func(): _replay_war_report_battle(report_copy))
			row.add_child(replay_btn)

func _replay_war_report_battle(report: Dictionary) -> void :
	if game_manager == null or not game_manager.has_method("start_gang_siege_battle"):
		return
	for entry in report.get("log", []):
		if not entry is Dictionary:
			continue
		var battle_log: Variant = entry.get("battleLog", entry.get("battle_log", []))
		if not battle_log is Array or battle_log.is_empty():
			continue
		game_manager.start_gang_siege_battle({
			"won": bool(entry.get("won", false)), 
			"battleLog": battle_log, 
			"attackerSnapshot": entry.get("attackerSnapshot", entry.get("attacker_snapshot", {})), 
			"defenderSnapshot": entry.get("defenderSnapshot", entry.get("defender_snapshot", {})), 
			"defenderName": str(entry.get("defenderName", entry.get("defender_name", "防守成员"))), 
			"autoWin": bool(entry.get("autoWin", entry.get("auto_win", false))), 
		})
		return

func _my_siege_round_territory_id(siege: Dictionary) -> String:
	var preset: = str(siege.get("myRoundAppliedTerritoryId", "")).strip_edges()
	if not preset.is_empty():
		return preset
	var my_gang_id: = _get_my_gang_id()
	var round_no: = int(siege.get("currentRound", 0))
	for b in siege.get("bids", []):
		if not b is Dictionary:
			continue
		if int(b.get("gangId", 0)) != my_gang_id:
			continue
		if bool(b.get("forfeited", false)):
			continue
		if round_no > 0 and int(b.get("roundNo", round_no)) != round_no:
			continue
		return str(b.get("territoryId", ""))
	return ""

func _format_member_daily_reward_text(t: Dictionary, siege: Dictionary) -> String:
	var tier_key: = _territory_tier_key(t, str(t.get("id", "")))
	var cfg: Dictionary = siege.get("config", {})
	var table: Dictionary = cfg.get("territoryMemberDailyByTier", {})
	var row: Dictionary = table.get(tier_key, {})
	var gold: = int(row.get("gold", 0))
	var materials: = int(row.get("materials", 0))
	var parts: PackedStringArray = []
	if gold > 0:
		parts.append("金币 %s" % _format_big_number(gold))
	if materials > 0:
		parts.append("建设材料×%d" % materials)
	if parts.is_empty():
		return "成员日收益：无"
	return "成员日收益：%s" % " + ".join(parts)

func _territory_has_challenge_entry(siege: Dictionary, territory_id: String) -> bool:
	if not _siege_session_for_territory(territory_id).is_empty():
		return true
	if not _territory_winner_for(territory_id, siege).is_empty():
		return true
	for s in siege.get("activeSessions", []):
		if s is Dictionary and str(s.get("territoryId", "")) == territory_id:
			return true
	for r in siege.get("rounds", []):
		if not r is Dictionary:
			continue
		var tid: = str(r.get("territoryId", r.get("territory_id", "")))
		if tid != territory_id:
			continue
		var st: = str(r.get("status", ""))
		if st in ["active", "challenge"]:
			return true
	return false

func _maybe_refresh_siege_for_challenge_prep(territory_id: String) -> void :
	var key: = territory_id if not territory_id.is_empty() else "_global"
	var now: = Time.get_ticks_msec()
	if now < int(_siege_challenge_prep_refresh_until_ms.get(key, 0)):
		return
	_siege_challenge_prep_refresh_until_ms[key] = now + 8000
	if _gang_mgr:
		_gang_mgr.refresh_siege_status()

func _siege_session_for_territory(territory_id: String) -> Dictionary:
	if _gang_mgr == null:
		return {}
	for s in _gang_mgr.siege_active_sessions:
		if s is Dictionary and str(s.get("territoryId", "")) == territory_id:
			return s
	for s in _gang_mgr.siege_status.get("activeSessions", []):
		if s is Dictionary and str(s.get("territoryId", "")) == territory_id:
			return s
	return {}

func _territory_siege_garrison(territory_id: String, siege: Dictionary, territory_data: Dictionary = {}) -> Dictionary:
	var session: = _siege_session_for_territory(territory_id)
	var default_max: = int(territory_data.get("durabilityMax", territory_data.get("durability_max", 0)))
	if default_max <= 0 and _gang_mgr:
		for item in _gang_mgr.territories:
			if item is Dictionary and str(item.get("id", "")) == territory_id:
				default_max = int(item.get("durabilityMax", item.get("durability_max", 0)))
				break
	if default_max <= 0:
		default_max = 120
	if not session.is_empty():
		return {
			"current": int(session.get("durability", default_max)), 
			"max": int(session.get("durabilityMax", default_max)), 
		}
	return {"current": default_max, "max": default_max}

func _territory_siege_npc_level(territory_data: Dictionary) -> int:
	var power: = int(territory_data.get("npcPower", territory_data.get("npc_power", 0)))
	if power <= 0:
		return 1000
	return power

func _refresh_territory_detail_popup_if_open() -> void :
	var layer: = get_node_or_null("TerritoryDetailLayer")
	if layer == null:
		return
	var tid: = str(layer.get_meta("territory_id", ""))
	if tid.is_empty():
		return
	var t: Dictionary = {}
	if _gang_mgr:
		for item in _gang_mgr.territories:
			if item is Dictionary and str(item.get("id", "")) == tid:
				t = item
				break
	if t.is_empty():
		t = layer.get_meta("territory_data", {})
	layer.queue_free()
	if not t.is_empty():
		_show_territory_detail_popup(t, true)

func _current_siege_status() -> Dictionary:
	return _gang_mgr.siege_status if _gang_mgr else {}

func _siege_phase_label(phase: String) -> String:
	match phase:
		"apply_open":
			return "申请阶段"
		"apply_closed":
			return "申请截止"
		"blind_bidding":
			return "盲盒竞价"
		"bid_revealed":
			return "竞价公布"
		"challenge":
			return "挑战阶段"
		"rest":
			return "休整阶段"
		_:
			return "领地战"

func _siege_bid_forfeit_reason(b: Dictionary) -> String:
	var reason: = str(b.get("forfeitReason", "")).strip_edges()
	if not reason.is_empty():
		return reason
	var code: = int(b.get("forfeitedCode", 0))
	if code == 2:
		return "outbid"
	if code == 1:
		return "manual"
	if bool(b.get("forfeited", false)):
		return "manual"
	return "none"

func _render_territory_bid_row(parent: Node, b: Dictionary, reveal: bool) -> void :
	var gname: = str(b.get("gangName", ""))
	if gname.is_empty():
		gname = "帮派#%d" % int(b.get("gangId", 0))
	if not bool(b.get("forfeited", false)):
		var amount_text: = "保密"
		if reveal and b.get("bidAmount") != null:
			amount_text = _format_big_number(int(b.get("bidAmount", 0)))
		_add_territory_kv_row(parent, gname, amount_text, true)
		return
	var reason: = _siege_bid_forfeit_reason(b)
	var status: = "已放弃，资金已退还"
	match reason:
		"outbid":
			status = "未中选，资金已退还"
		"manual":
			status = "已主动放弃，资金已退还"
	var show_amount: = b.get("bidAmount") != null and (reveal or bool(b.get("bidRevealed", false)))
	if show_amount:
		_add_territory_kv_row(
			parent, 
			gname, 
			"%s（%s）" % [_format_big_number(int(b.get("bidAmount", 0))), status], 
			true
		)
	else:
		_add_territory_hint_line(parent, "%s（%s）" % [gname, status])

func _has_siege_attack_mirror(siege: Dictionary = {}) -> bool:
	if _gang_mgr and _gang_mgr.has_gang_mirror:
		return true
	var s: = siege if not siege.is_empty() else _current_siege_status()
	return bool(s.get("hasMirror", false))

func _siege_authoritative_now_unix() -> int:
	var now_unix: = int(Time.get_unix_time_from_system())
	if game_manager and game_manager.has_method("get_authoritative_unix_time"):
		var auth: = int(game_manager.get_authoritative_unix_time(true))
		if auth > 0:
			now_unix = auth
	return now_unix


func _is_siege_session_combat_open(siege: Dictionary, session: Dictionary) -> bool:
	if str(siege.get("phase", "")) == "challenge":
		return true
	if session.is_empty():
		return false
	if str(session.get("status", "active")) != "active":
		return false
	var start_raw: = str(session.get("startsAt", session.get("starts_at", ""))).strip_edges()
	var end_raw: = str(session.get("endsAt", session.get("ends_at", ""))).strip_edges()
	var start_unix: = _parse_beijing_datetime_to_unix(start_raw)
	var end_unix: = _parse_beijing_datetime_to_unix(end_raw)
	if start_unix <= 0 or end_unix <= 0:
		return false
	var now_unix: = _siege_authoritative_now_unix()
	return now_unix >= start_unix and now_unix < end_unix

func _format_siege_combat_countdown(siege: Dictionary, session: Dictionary, for_defender: bool = false) -> String:
	var left_text: = ""
	var start_raw: = str(session.get("startsAt", session.get("starts_at", ""))).strip_edges()
	if not start_raw.is_empty():
		var start_unix: = _parse_beijing_datetime_to_unix(start_raw)
		if start_unix > 0:
			var delta: = start_unix - _siege_authoritative_now_unix()
			if delta > 0:
				left_text = _format_seconds_left(delta)
	if left_text.is_empty():
		var rs_raw = siege.get("phaseRemainingSeconds")
		if rs_raw != null and int(rs_raw) >= 0:
			left_text = _format_seconds_left(int(rs_raw))
	if left_text.is_empty():
		var phase_ends: = str(siege.get("phaseEndsAt", "")).strip_edges()
		if not phase_ends.is_empty():
			left_text = _format_kick_time_left(phase_ends)
	if left_text.is_empty():
		return "挑战尚未开始，请等待开战" if for_defender else "已获得挑战资格，等待挑战开始"
	if for_defender:
		return "挑战尚未开始，离开战还有 %s" % left_text
	return "已获得挑战资格，离开战还有 %s" % left_text

func _can_siege_attack_for_session(siege: Dictionary, session: Dictionary) -> bool:
	return _is_siege_session_combat_open(siege, session)

func _is_siege_attack_btn_disabled(siege: Dictionary, aq: Dictionary, session: Dictionary = {}) -> bool:
	if int(aq.get("attacksLeft", 0)) <= 0:
		return true
	if not _has_siege_attack_mirror(siege):
		return true
	if not _can_siege_attack_for_session(siege, session):
		return true
	return false

func _try_siege_action_cooldown(key: String) -> bool:
	var now: = Time.get_ticks_msec()
	var until: = int(_siege_action_cooldown_until_ms.get(key, 0))
	if now < until:
		return false
	_siege_action_cooldown_until_ms[key] = now + SIEGE_ACTION_COOLDOWN_MS
	return true

func _bind_siege_action_button(btn: Button, key: String, on_press: Callable) -> void :
	btn.pressed.connect( func(): _on_siege_action_button_pressed(btn, key, on_press))

func _on_siege_action_button_pressed(btn: Button, key: String, on_press: Callable) -> void :
	if not _try_siege_action_cooldown(key):
		return
	btn.disabled = true
	if on_press.is_valid():
		on_press.call()
	await get_tree().create_timer(float(SIEGE_ACTION_COOLDOWN_MS) / 1000.0).timeout
	if is_instance_valid(btn):
		btn.disabled = false

func _render_siege_active_sessions(parent: Node) -> int:
	if _gang_mgr == null:
		return 0
	var sessions: Array = _gang_mgr.siege_active_sessions
	if sessions.is_empty():
		sessions = _gang_mgr.siege_status.get("activeSessions", [])
	if sessions.is_empty():
		return 0
	var siege_cfg: Dictionary = _gang_mgr.siege_status.get("config", {})
	var repair_cost: = int(siege_cfg.get("siegeRepairContribution", 200))
	var atk_contrib_cost: = int(siege_cfg.get("siegeAttackContributionCost", 200))
	var atk_yb_cost: = int(siege_cfg.get("siegeYuanbaoAttackCost", 100))
	var def_yb_cost: = int(siege_cfg.get("siegeYuanbaoDefenseCost", 100))
	var siege: = _current_siege_status()
	var phase: = str(siege.get("phase", ""))
	var phase_label: = _siege_phase_label(phase)
	var phase_left: = ""
	var rs_raw = siege.get("phaseRemainingSeconds")
	if rs_raw != null:
		var rs: int = int(rs_raw)
		if rs >= 0:
			phase_left = _format_seconds_left(rs)
	if phase_left.is_empty() and not str(siege.get("phaseEndsAt", "")).is_empty():
		phase_left = _format_kick_time_left(str(siege.get("phaseEndsAt", "")))
	var header: = "%s · 帮贡加固 %d/次 · 元宝加固 %d/次" % [phase_label, repair_cost, def_yb_cost]
	if not phase_left.is_empty():
		header += " · %s" % phase_left
	_add_info_line(parent, header, true)
	var rendered: = 0
	for s in sessions:
		if not s is Dictionary:
			continue
		rendered += 1
		var session_tier: = _siege_session_tier_key(s)
		var round_id: = int(s.get("roundId", 0))
		var role: = str(s.get("role", "spectator"))
		var row: = PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
		var margin: = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		row.add_child(margin)
		var outer: = VBoxContainer.new()
		outer.add_theme_constant_override("separation", 4)
		margin.add_child(outer)
		var terr_name: = str(s.get("territoryId", ""))
		for t in (_gang_mgr.territories if _gang_mgr else []):
			if t is Dictionary and str(t.get("id", "")) == terr_name:
				terr_name = str(t.get("name", terr_name))
				break
		var lbl: = Label.new()
		if role == "defender" and s.has("durability"):
			lbl.text = "%s · %s vs %s · 耐久 %d/%d · 防守槽 %d · %s" % [
				terr_name, 
				str(s.get("attackerName", "攻方")), 
				str(s.get("defenderName", "守方/NPC")), 
				int(s.get("durability", 0)), 
				int(s.get("durabilityMax", 120)), 
				int(s.get("defenseSlotsLeft", 0)), 
				_format_kick_time_left(str(s.get("endsAt", ""))), 
			]
		else:
			lbl.text = "%s · %s vs %s · 防守槽 %d · %s" % [
				terr_name, 
				str(s.get("attackerName", "攻方")), 
				str(s.get("defenderName", "守方/NPC")), 
				int(s.get("defenseSlotsLeft", 0)), 
				_format_kick_time_left(str(s.get("endsAt", ""))), 
			]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 14)
		outer.add_child(lbl)
		var btn_row: HBoxContainer = null
		if role == "attacker":
			var aq: Dictionary = s.get("attackQuota", {})
			var siege_state: = _current_siege_status()
			if not _is_siege_session_combat_open(siege_state, s):
				_add_territory_hint_line(outer, _format_siege_combat_countdown(siege_state, s, false))
			else:
				btn_row = HBoxContainer.new()
				btn_row.add_theme_constant_override("separation", 6)
				var atk_contrib_limit: = int(aq.get("contributionBoughtLimit", siege_cfg.get("siegeAttackContributionLimit", 3)))
				var atk_contrib_used: = int(aq.get("contributionBought", maxi(0, atk_contrib_limit - int(aq.get("contributionBoughtLeft", 0)))))
				var atk_yb_limit: = int(aq.get("yuanbaoBoughtLimit", siege_cfg.get("siegeYuanbaoAttackLimit", 3)))
				var atk_yb_used: = int(aq.get("yuanbaoBought", maxi(0, atk_yb_limit - int(aq.get("yuanbaoBoughtLeft", 0)))))
				var attack_btn: = Button.new()
				attack_btn.text = "进攻(%d)" % int(aq.get("attacksLeft", 0))
				attack_btn.custom_minimum_size = Vector2(88, 34)
				attack_btn.disabled = _is_siege_attack_btn_disabled(siege_state, aq, s)
				_style_war_interface_button(attack_btn, session_tier)
				_bind_siege_action_button(attack_btn, "attack:%d" % round_id, func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_attack(round_id)
				)
				btn_row.add_child(attack_btn)
				var contrib_left: = int(aq.get("contributionBoughtLeft", 0))
				var buy_contrib: = Button.new()
				buy_contrib.text = "%d帮贡加次(%d/%d)" % [atk_contrib_cost, atk_contrib_used, atk_contrib_limit]
				buy_contrib.custom_minimum_size = Vector2(130, 34)
				buy_contrib.disabled = contrib_left <= 0
				_style_war_interface_button(buy_contrib, session_tier)
				_bind_siege_action_button(buy_contrib, "contrib:%d" % round_id, func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_buy_attack_contribution(round_id)
				)
				btn_row.add_child(buy_contrib)
				var yb_left: = int(aq.get("yuanbaoBoughtLeft", 0))
				var buy_yb: = Button.new()
				buy_yb.text = "%d元宝加次(%d/%d)" % [atk_yb_cost, atk_yb_used, atk_yb_limit]
				buy_yb.custom_minimum_size = Vector2(120, 34)
				buy_yb.disabled = yb_left <= 0
				_style_war_interface_button(buy_yb, session_tier)
				_bind_siege_action_button(buy_yb, "yuanbao_atk:%d" % round_id, func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_buy_attack(round_id)
				)
				btn_row.add_child(buy_yb)
		elif role == "defender":
			var dq: Dictionary = s.get("defenseQuota", {})
			var siege_state: = _current_siege_status()
			if not _is_siege_session_combat_open(siege_state, s):
				_add_territory_hint_line(outer, _format_siege_combat_countdown(siege_state, s, true))
			else:
				btn_row = HBoxContainer.new()
				btn_row.add_theme_constant_override("separation", 6)
				var repair_limit: = int(dq.get("repairLimit", siege_cfg.get("siegeRepairMaxPerRound", 3)))
				var yb_def_limit: = int(dq.get("yuanbaoDefenseLimit", siege_cfg.get("siegeYuanbaoDefenseLimit", 3)))
				var yb_def_used: = int(dq.get("yuanbaoDefenseBought", maxi(0, yb_def_limit - int(dq.get("yuanbaoDefenseBoughtLeft", 0)))))
				var repair_btn: = Button.new()
				repair_btn.text = "%d帮贡加固(%d/%d)" % [repair_cost, int(dq.get("repairUsed", 0)), repair_limit]
				repair_btn.custom_minimum_size = Vector2(130, 34)
				repair_btn.disabled = int(dq.get("repairLeft", 0)) <= 0
				_style_war_interface_button(repair_btn, session_tier)
				_bind_siege_action_button(repair_btn, "repair:%d" % round_id, func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_repair(round_id)
				)
				btn_row.add_child(repair_btn)
				var yb_def_left: = int(dq.get("yuanbaoDefenseBoughtLeft", 0))
				var buy_def: = Button.new()
				buy_def.text = "%d元宝加固(%d/%d)" % [def_yb_cost, yb_def_used, yb_def_limit]
				buy_def.custom_minimum_size = Vector2(120, 34)
				buy_def.disabled = yb_def_left <= 0
				_style_war_interface_button(buy_def, session_tier)
				_bind_siege_action_button(buy_def, "yuanbao_def:%d" % round_id, func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_buy_defense(round_id)
				)
				btn_row.add_child(buy_def)
		else:
			_add_territory_hint_line(outer, "观战中")
		if btn_row != null:
			outer.add_child(btn_row)
		parent.add_child(row)
	return rendered

func _render_territory_guard_section(parent: Node, t: Dictionary) -> void :
	if _gang_mgr == null:
		return
	var my_gang_id: = _get_my_gang_id()
	if int(t.get("ownerGangId", t.get("owner_gang_id", 0))) != my_gang_id:
		return
	var territory_id: = str(t.get("id", ""))
	var siege: = _current_siege_status()
	var locked: = bool(_gang_mgr.siege_status.get("guardConfigLocked", false))
	var battle_day: = _siege_battle_day_active(siege)
	var max_slots: = int(t.get("garrisonMax", t.get("garrison_max", 0)))
	if max_slots <= 0:
		var cache_slots: Dictionary = _gang_mgr.siege_guards_cache.get(territory_id, {})
		max_slots = int(cache_slots.get("maxSlots", 10))
	if max_slots <= 0:
		max_slots = 10
	_add_territory_section_title(parent, "领地驻守")
	if locked:
		_add_territory_hint_line(parent, "周日每轮申请截止后锁定 · 每领地最多 %d 人 · 每人最多 1 块领地" % max_slots)
		_add_territory_hint_line(parent, "当前轮驻守已锁定")
		_add_territory_hint_line(parent, "请于周一至周六，或下周日各轮申请截止前（如 10:20 前）点击下方「驻守此领地」")
	elif not battle_day:
		_add_territory_hint_line(parent, "当前可配置驻守 · 每领地最多 %d 人 · 每人最多 1 块领地" % max_slots)
	else:
		_add_territory_hint_line(parent, "申请截止前可驻守（如第1轮 10:20 前）· 每领地最多 %d 人 · 每人最多 1 块领地" % max_slots)
		_add_territory_hint_line(parent, "当前可配置驻守，截止后锁定")
	var load_btn: = Button.new()
	load_btn.text = "刷新驻守槽位"
	load_btn.custom_minimum_size = Vector2(0, 36)
	_style_war_interface_button(load_btn, _territory_tier_key(t, territory_id))
	load_btn.pressed.connect( func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.fetch_siege_guards(territory_id)
			_show_gang_message("正在加载驻守信息…", true)
	)
	parent.add_child(load_btn)
	var cache: Dictionary = _gang_mgr.siege_guards_cache.get(territory_id, {})
	if cache.is_empty() and _gang_mgr.gang_network:
		_gang_mgr.gang_network.fetch_siege_guards(territory_id)
		return
	var guards: Array = cache.get("guards", [])
	var slots_box: = GridContainer.new()
	slots_box.columns = 2
	slots_box.add_theme_constant_override("h_separation", 6)
	slots_box.add_theme_constant_override("v_separation", 4)
	for i in range(max_slots):
		var slot_lbl: = Label.new()
		slot_lbl.add_theme_font_size_override("font_size", 13)
		if i < guards.size() and guards[i] is Dictionary:
			var g: Dictionary = guards[i]
			slot_lbl.text = "%d. %s" % [i + 1, str(g.get("mirrorName", g.get("memberName", "成员")))]
		else:
			if locked:
				slot_lbl.text = "%d. 空槽（已锁定）" % (i + 1)
				slot_lbl.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
			else:
				slot_lbl.text = "%d. 可驻守" % (i + 1)
				slot_lbl.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708))
		slots_box.add_child(slot_lbl)
	parent.add_child(slots_box)
	if locked:
		return
	var my_user_id: = _get_my_user_id()
	var already_guard: = false
	for g in guards:
		if g is Dictionary and int(g.get("userId", 0)) == my_user_id:
			already_guard = true
			break
	if already_guard:
		_add_territory_hint_line(parent, "你已驻守此领地")
		return
	if guards.size() >= max_slots:
		_add_territory_hint_line(parent, "驻守名额已满")
		return
	var join_btn: = Button.new()
	join_btn.text = "驻守此领地"
	join_btn.custom_minimum_size = Vector2(0, 38)
	_style_war_interface_button(join_btn, _territory_tier_key(t, territory_id))
	join_btn.pressed.connect( func():
		if _gang_mgr == null or _gang_mgr.gang_network == null:
			return
		if not _gang_mgr.has_gang_mirror:
			_show_gang_message("请先更新帮派镜像后再驻守", false)
			return
		_gang_mgr.gang_network.siege_guard_join(territory_id)
	)
	parent.add_child(join_btn)

func _territory_map(territories: Array) -> Dictionary:
	var out: Dictionary = {}
	for t in territories:
		if t is Dictionary:
			out[str(t.get("id", ""))] = t
	return out

func _build_territory_grid(territories: Array, siege: Dictionary) -> GridContainer:
	var grid: = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tmap: = _territory_map(territories)
	var my_gang_id: = _get_my_gang_id()
	for tid in TERRITORY_GRID_ORDER:
		var t: Dictionary = tmap.get(str(tid), {})
		grid.add_child(_make_territory_cell(t, tid, siege, my_gang_id))
	return grid

func _get_my_gang_id() -> int:
	if _gang_mgr == null:
		return 0
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	return int(gang.get("id", 0))

func _territory_bids_for(territory_id: String, siege: Dictionary) -> Array:
	var out: Array = []
	var round_no: = int(siege.get("currentRound", 0))
	var phase: = str(siege.get("phase", ""))
	if round_no <= 0 or phase == "idle":
		return out
	for b in siege.get("bids", []):
		if not b is Dictionary:
			continue
		if str(b.get("territoryId", "")) != territory_id:
			continue
		if int(b.get("roundNo", round_no)) != round_no:
			continue
		if phase == "rest" and bool(b.get("forfeited", false)):
			continue
		out.append(b)
	return out

func _territory_winner_for(territory_id: String, siege: Dictionary) -> Dictionary:
	for w in siege.get("roundWinners", []):
		if not w is Dictionary:
			continue
		if str(w.get("territoryId", "")) == territory_id:
			return w
	return {}

func _is_territory_protected(t: Dictionary) -> bool:
	var until: = str(t.get("protectedUntil", "")).strip_edges()
	if until.is_empty():
		return false
	var unix: = Time.get_unix_time_from_datetime_string(until.replace("T", " ").replace("Z", ""))
	return unix > Time.get_unix_time_from_system()

func _territory_tier_key(t: Dictionary, tid: String) -> String:
	if str(tid) == "sky_city":
		return "唯一"
	var tier: = str(t.get("tier", "")).strip_edges()
	if tier.is_empty():
		return "中级"
	if TERRITORY_TIER_COLORS.has(tier):
		return tier
	return "中级"

func _territory_first_char(name: String) -> String:
	var trimmed: = name.strip_edges()
	if trimmed.is_empty():
		return "?"
	return trimmed.substr(0, 1)

func _create_territory_icon(tid: String, name: String, palette: Dictionary) -> Control:
	var icon_path: = GangConfig.territory_icon_path(tid)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var tex: = load(icon_path) as Texture2D
		if tex:
			var icon: = TextureRect.new()
			icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			return icon
	var icon_panel: = Panel.new()
	icon_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_style: = StyleBoxFlat.new()
	icon_style.bg_color = palette.get("icon_bg")
	icon_style.corner_radius_top_left = 0
	icon_style.corner_radius_top_right = 0
	icon_style.corner_radius_bottom_left = 0
	icon_style.corner_radius_bottom_right = 0
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	var icon_char: = Label.new()
	icon_char.text = _territory_first_char(name)
	icon_char.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_char.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_char.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_char.add_theme_font_size_override("font_size", 32)
	icon_char.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	icon_char.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon_char)
	return icon_panel

func _create_territory_cell_style(tier_key: String, variant: String = "normal") -> StyleBoxFlat:
	var palette: Dictionary = TERRITORY_TIER_COLORS.get(tier_key, TERRITORY_TIER_COLORS["中级"])
	var style: = StyleBoxFlat.new()
	match variant:
		"hover":
			style.bg_color = palette.get("bg_hover", palette.get("bg"))
		"pressed":
			style.bg_color = palette.get("bg_pressed", palette.get("bg"))
		_:
			style.bg_color = palette.get("bg")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = palette.get("border")
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 2
	style.content_margin_top = 2
	style.content_margin_right = 2
	style.content_margin_bottom = 2
	return style

func _apply_territory_cell_button_style(btn: Button, tier_key: String) -> void :
	btn.add_theme_stylebox_override("normal", _create_territory_cell_style(tier_key, "normal"))
	btn.add_theme_stylebox_override("hover", _create_territory_cell_style(tier_key, "hover"))
	btn.add_theme_stylebox_override("pressed", _create_territory_cell_style(tier_key, "pressed"))
	btn.add_theme_stylebox_override("focus", _create_territory_cell_style(tier_key, "normal"))
	btn.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.924, 0.893, 0.831))

func _style_war_interface_button(btn: Button, tier_key: String = "中级") -> void :
	var key: = tier_key if TERRITORY_TIER_COLORS.has(tier_key) else "中级"
	_apply_territory_cell_button_style(btn, key)
	if not btn.has_theme_font_size_override("font_size"):
		btn.add_theme_font_size_override("font_size", 13)

func _siege_session_tier_key(s: Dictionary) -> String:
	var tid: = str(s.get("territoryId", ""))
	if _gang_mgr:
		for t in _gang_mgr.territories:
			if t is Dictionary and str(t.get("id", "")) == tid:
				return _territory_tier_key(t, tid)
	return "中级"

func _make_territory_cell(t: Dictionary, tid: String, siege: Dictionary, my_gang_id: int) -> Control:
	var name: = str(t.get("name", tid))
	if name.is_empty():
		name = tid
	var owner: = str(t.get("ownerName", ""))
	if owner.is_empty():
		owner = "中立"
	var tier: = str(t.get("tier", ""))
	if tier.is_empty() and str(tid) == "sky_city":
		tier = "唯一"
	var tier_key: = _territory_tier_key(t, tid)
	var palette: Dictionary = TERRITORY_TIER_COLORS.get(tier_key, TERRITORY_TIER_COLORS["中级"])
	var badges: Array = []
	if _is_territory_protected(t):
		badges.append("保护")
	var phase: = str(siege.get("phase", ""))
	if phase == "blind_bidding":
		badges.append("竞价中")
	elif phase == "challenge":
		var winner: = _territory_winner_for(tid, siege)
		if not winner.is_empty() and str(winner.get("territoryId", "")) == tid:
			badges.append("挑战中")
	elif phase == "apply_open":
		badges.append("申请中")
	for b in _territory_bids_for(tid, siege):
		if int(b.get("gangId", 0)) == my_gang_id and not bool(b.get("forfeited", false)):
			badges.append("已参与")
			break
	if badges.size() > 2:
		badges = badges.slice(0, 2)
		badges.append("…")
	var status_text: = owner
	if not badges.is_empty():
		status_text += " · " + " · ".join(badges)
	var popup_data: Dictionary = t if not t.is_empty() else {"id": tid, "name": name}

	var btn: = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(118, TERRITORY_CELL_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	_apply_territory_cell_button_style(btn, tier_key)

	TouchScrollUtils.bind_tap(btn, func(): _show_territory_detail_popup(popup_data))

	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var icon_side: = maxi(48, TERRITORY_CELL_HEIGHT - TERRITORY_CELL_ICON_INSET)
	var icon_wrap: = AspectRatioContainer.new()
	icon_wrap.ratio = 1.0
	icon_wrap.custom_minimum_size = Vector2(icon_side, icon_side)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_wrap.stretch_mode = AspectRatioContainer.STRETCH_FIT
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_wrap)
	icon_wrap.add_child(_create_territory_icon(tid, name, palette))

	var info: = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var name_lbl: = Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var tier_lbl: = Label.new()
	tier_lbl.text = tier if not tier.is_empty() else tier_key
	tier_lbl.add_theme_font_size_override("font_size", 12)
	tier_lbl.add_theme_color_override("font_color", palette.get("tier_text"))
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(tier_lbl)

	var status_lbl: = Label.new()
	status_lbl.text = status_text
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color(0.822, 0.797, 0.737))
	status_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_lbl.max_lines_visible = 1
	status_lbl.clip_text = true
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(status_lbl)

	return btn

func _format_gang_buff_line(buffs: Dictionary, show_gold: bool) -> String:
	if buffs.is_empty():
		return "无"
	var parts: Array = [
		"攻 +%s%%" % str(buffs.get("attackBonusPercent", 0)), 
		"防 +%s%%" % str(buffs.get("defenseBonusPercent", 0)), 
		"敏 +%s%%" % str(buffs.get("agilityBonusPercent", 0)), 
		"血 +%s%%" % str(buffs.get("hpBonusPercent", 0)), 
		"经验 +%s%%" % str(buffs.get("expBonusPercent", 0)), 
	]
	if show_gold:
		var gold_pct: = float(buffs.get("goldDropBonusPercent", 0))
		if gold_pct > 0.0:
			parts.append("金币 +%s%%" % str(gold_pct))
	return "   ".join(parts)

func _format_owned_territory_buff_line(entry: Dictionary) -> String:
	var name: = str(entry.get("name", "")).strip_edges()
	if name.is_empty():
		name = str(entry.get("territoryId", "领地"))
	var effective: Dictionary = entry.get("effectiveBuffs", {})
	var line: = "  · %s：%s" % [name, _format_gang_buff_line(effective, true)]
	if bool(entry.get("doubled", false)):
		line += "（已翻倍）"
	return line

func _format_territory_buffs(buffs) -> String:
	if not buffs is Dictionary or buffs.is_empty():
		return "无"
	var parts: Array = []
	for key in TERRITORY_BUFF_LABELS.keys():
		if not buffs.has(key):
			continue
		var val: = float(buffs.get(key, 0))
		if val <= 0.0:
			continue
		parts.append("%s+%s%%" % [TERRITORY_BUFF_LABELS[key], str(val)])
	return "、".join(parts) if not parts.is_empty() else "无"

func _format_protection_status(t: Dictionary) -> String:
	if not _is_territory_protected(t):
		return "无保护"
	return "保护中，%s" % _format_kick_time_left(str(t.get("protectedUntil", "")))

func _format_siege_phase_hint(siege: Dictionary) -> String:
	var phase: = str(siege.get("phase", ""))
	var round_no: = int(siege.get("currentRound", 0))
	var ends: = str(siege.get("phaseEndsAt", ""))
	var left: = ""
	var rs_raw = siege.get("phaseRemainingSeconds")
	if rs_raw != null:
		var rs: int = int(rs_raw)
		if rs >= 0:
			left = _format_seconds_left(rs)
	if left.is_empty() and not ends.is_empty():
		left = _format_kick_time_left(ends)
	match phase:
		"apply_open":
			return "第%d轮申请窗口%s" % [round_no, (" · " + left) if not left.is_empty() else ""]
		"apply_closed":
			return "第%d轮申请已截止，即将进入盲盒竞价%s" % [round_no, (" · " + left) if not left.is_empty() else ""]
		"blind_bidding":
			return "第%d轮盲盒竞价中，金额保密%s" % [round_no, (" · " + left) if not left.is_empty() else ""]
		"bid_revealed":
			return "第%d轮已获得挑战资格，离开战还有 %s" % [round_no, left if not left.is_empty() else "即将开始"]
		"challenge":
			return "第%d轮挑战进行中%s" % [round_no, (" · " + left) if not left.is_empty() else ""]
		"rest":
			return "第%d轮已结束，休整中" % round_no
		"idle":
			var sch: Dictionary = _siege_schedule_dict(siege)
			var day: = GangConfig._weekday_label(int(sch.get("battleWeekday", 0)))
			if bool(sch.get("ignoreWeekdayForTest", false)):
				return "领地战当前未在开放时段（测试模式已开，请对照后台时间表）"
			return "领地战仅在每%s开放" % day
		_:
			return ""

func _bid_amounts_visible(siege: Dictionary) -> bool:
	var phase: = str(siege.get("phase", ""))
	return phase in ["bid_revealed", "challenge", "rest"]

func _show_territory_detail_popup(t: Dictionary, skip_siege_refresh: bool = false) -> void :
	if not skip_siege_refresh and _gang_mgr:
		_siege_status_sync_error = ""
		_siege_status_refresh_pending = true
		_gang_mgr.refresh_overview()
		_gang_mgr.refresh_siege_status()
		var open_tid: = str(t.get("id", ""))
		if _gang_mgr.gang_network and not open_tid.is_empty():
			_gang_mgr.gang_network.fetch_siege_guards(open_tid)
	var existing: = get_node_or_null("TerritoryDetailLayer")
	if existing:
		existing.queue_free()
	var layer: = Control.new()
	layer.name = "TerritoryDetailLayer"
	var territory_id: = str(t.get("id", ""))
	layer.set_meta("territory_id", territory_id)
	layer.set_meta("territory_data", t.duplicate(true))
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 200
	add_child(layer)
	var dim: = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.631, 0.611, 0.564, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var host_size: = size if size.x > 1.0 and size.y > 1.0 else get_viewport_rect().size
	var popup_size: = _resolve_territory_detail_popup_size(host_size)
	var popup: = Panel.new()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.custom_minimum_size = popup_size
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(popup)
	popup.position = Vector2(
		maxf(8.0, (host_size.x - popup_size.x) * 0.5), 
		maxf(8.0, (host_size.y - popup_size.y) * 0.5)
	)
	var outer: = VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 18
	outer.offset_top = 16
	outer.offset_right = -18
	outer.offset_bottom = -16
	outer.add_theme_constant_override("separation", 10)
	popup.add_child(outer)
	_build_territory_detail_header(outer, t)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, clampf(popup_size.y - 160.0, 360.0, 400.0))
	outer.add_child(scroll)
	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	var siege: Dictionary = _current_siege_status()
	_add_territory_section_title(content, "基础信息")
	var owner: = str(t.get("ownerName", ""))
	if owner.is_empty():
		owner = "中立"
	_add_territory_kv_row(content, "占领方", owner)
	var garrison: Dictionary = _territory_siege_garrison(territory_id, siege, t)
	var session_for_detail: = _siege_session_for_territory(territory_id)
	var detail_role: = str(session_for_detail.get("role", "spectator"))
	if not session_for_detail.is_empty() and detail_role != "defender":
		_add_territory_kv_row(content, "攻城耐久", "进行中（机密）")
	else:
		_add_territory_kv_row(content, "攻城耐久", "%d / %d" % [int(garrison.get("current", 0)), int(garrison.get("max", 0))])
	_add_territory_kv_row(content, "守军战力", "Lv.%d" % _territory_siege_npc_level(t))
	_add_territory_kv_row(content, "日产出", "建设材料×%d、帮派资金×%s" % [
		int(t.get("dailyMaterials", 0)), 
		_format_big_number(int(t.get("dailyFunds", 0))), 
	], true)
	_add_territory_kv_row(content, "成员日收益", _format_member_daily_reward_text(t, siege).trim_prefix("成员日收益："), true)
	_add_territory_kv_row(content, "领地加成", _format_territory_buffs(t.get("buffs", {})))
	var my_gang_id: = _get_my_gang_id()
	if territory_id == "sky_city" and int(t.get("ownerGangId", t.get("owner_gang_id", 0))) == my_gang_id:
		_add_territory_hint_line(content, "特殊效果：其它领地加成翻倍（已生效）")
	var protected: = _is_territory_protected(t)
	_add_territory_kv_row(content, "保护期", _format_protection_status(t), false, protected)
	content.add_child(HSeparator.new())
	_add_territory_section_title(content, "竞价结果")
	var phase: = str(siege.get("phase", ""))
	var round_no: = int(siege.get("currentRound", 0))
	var reveal: = _bid_amounts_visible(siege)
	if phase == "idle" or round_no <= 0:
		_add_territory_hint_line(content, "本周领地战尚未开始，竞价结果将在开战日公布")
	else:
		var bids: = _territory_bids_for(territory_id, siege)
		var active_bids: Array = []
		for b in bids:
			if b is Dictionary and not bool(b.get("forfeited", false)):
				active_bids.append(b)
		if phase == "blind_bidding":
			_add_territory_kv_row(content, "参与竞价", "%d 个帮派" % active_bids.size(), true)
			_add_territory_hint_line(content, "金额保密 · 截止后公布结果与挑战资格")
		elif phase == "apply_open":
			_add_territory_hint_line(content, "申请窗口内，名单暂未公示")
		elif phase == "apply_closed":
			_add_territory_hint_line(content, "申请帮派（金额暂不公开）")
			for b in active_bids:
				var gname: = str(b.get("gangName", ""))
				if gname.is_empty():
					gname = "帮派#%d" % int(b.get("gangId", 0))
				_add_territory_kv_row(content, gname, "待公布", true)
		else:
			if active_bids.is_empty():
				_add_territory_hint_line(content, "暂无申请/竞价记录")
			else:
				for b in bids:
					if not b is Dictionary:
						continue
					_render_territory_bid_row(content, b, reveal)
	var winner: = _territory_winner_for(territory_id, siege)
	if not winner.is_empty():
		var wname: = str(winner.get("gangName", ""))
		if reveal and winner.get("bidAmount") != null:
			_add_territory_kv_row(content, "挑战资格", "【%s】出价 %s" % [wname, _format_big_number(int(winner.get("bidAmount", 0)))], true)
		else:
			_add_territory_kv_row(content, "挑战资格", "【%s】" % wname, true)
		if str(siege.get("phase", "")) == "challenge":
			_add_territory_hint_line(content, "挑战阶段进行中")
	_render_territory_guard_section(content, t)
	if int(t.get("ownerGangId", t.get("owner_gang_id", 0))) == my_gang_id and _get_viewer_role() == 1:
		content.add_child(HSeparator.new())
		_add_territory_section_title(content, "帮主管理")
		var owner_mgmt_tier: = _territory_tier_key(t, territory_id)
		var challenge_active: = str(siege.get("phase", "")) == "challenge" and not _siege_session_for_territory(territory_id).is_empty()
		if challenge_active:
			_add_territory_hint_line(content, "挑战进行中，暂不可放弃领地")
		else:
			var abandon_btn: = Button.new()
			abandon_btn.text = "放弃领地"
			abandon_btn.custom_minimum_size = Vector2(0, 40)
			_style_war_interface_button(abandon_btn, owner_mgmt_tier)
			abandon_btn.pressed.connect( func():
				_confirm_gang_action(
					"放弃领地", 
					"放弃后该领地变为中立，保护期清除，驻守配置清空。确认放弃？", 
					func():
						if _gang_mgr and _gang_mgr.gang_network:
							_gang_mgr.gang_network.territory_abandon(territory_id)
						layer.queue_free(), 
					"确认放弃", 
					layer
				)
			)
			content.add_child(abandon_btn)
	content.add_child(HSeparator.new())
	_add_territory_section_title(content, "领地操作")
	_populate_territory_action_section(content, t, siege, layer)
	var popup_tier_key: = _territory_tier_key(t, territory_id)
	var close_row: = HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_child(close_row)
	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 40)
	_style_war_interface_button(close_btn, popup_tier_key)
	var close_popup: = func(): layer.queue_free()
	close_btn.pressed.connect(close_popup)
	close_row.add_child(close_btn)
	dim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close_popup.call()
	)

func _populate_territory_action_section(parent: Node, t: Dictionary, siege: Dictionary, layer: Control) -> void :
	var phase: = str(siege.get("phase", ""))
	var territory_id: = str(t.get("id", ""))
	var action_tier_key: = _territory_tier_key(t, territory_id)
	var round_no: = int(siege.get("currentRound", 1))
	var cfg: Dictionary = siege.get("config", {})
	var base_bid: = int(cfg.get("siegeBaseBid", 100000))
	var my_gang_id: = _get_my_gang_id()
	var is_leader: = _get_viewer_role() == 1
	var gang: Dictionary = _gang_mgr.overview.get("gang", {}) if _gang_mgr else {}
	var gang_level: = int(gang.get("level", 1))
	if _siege_status_refresh_pending:
		_add_info_line(parent, "领地战状态同步中，请稍候…", true)
		return
	if not _siege_status_sync_error.is_empty() and not _siege_battle_day_active(siege):
		_add_info_line(parent, _siege_status_sync_error, true)
		return
	if not _siege_battle_day_active(siege):
		var sch: Dictionary = _siege_schedule_dict(siege)
		var day: = GangConfig._weekday_label(int(sch.get("battleWeekday", 0)))
		if bool(sch.get("ignoreWeekdayForTest", false)):
			_add_info_line(parent, "当前不在领地战开放时段", true)
		else:
			_add_info_line(parent, "仅在每%s可进行领地战操作" % day, true)
		return
	if gang_level < GangConfig.TERRITORY_WAR_UNLOCK_LEVEL:
		_add_info_line(parent, "需帮派 Lv.%d 解锁领地战" % GangConfig.TERRITORY_WAR_UNLOCK_LEVEL, true)
		return
	var need_level: = GangConfig.min_gang_level_for_territory_tier(action_tier_key)
	if gang_level < need_level:
		var tier_label: = "天空之城" if action_tier_key == "唯一" else action_tier_key
		_add_info_line(parent, "需帮派 Lv.%d 才能占领【%s】领地" % [need_level, tier_label], true)
		return
	if not bool(siege.get("siegeWarOpen", true)):
		_add_info_line(parent, "服务器帮派数量不足 3 个，领地战暂未开放", true)
		return
	if phase == "challenge":
		_show_territory_challenge_guide(parent, territory_id, siege)
		return
	var applied_tid: = _my_siege_round_territory_id(siege)
	if not applied_tid.is_empty() and applied_tid != territory_id:
		var applied_name: = applied_tid
		if _gang_mgr:
			for tt in _gang_mgr.territories:
				if tt is Dictionary and str(tt.get("id", "")) == applied_tid:
					applied_name = str(tt.get("name", applied_tid))
					break
		_add_info_line(parent, "本帮第 %d 轮已申请【%s】，每轮只能挑战一块领地" % [round_no, applied_name], true)
		return
	var my_bid: Dictionary = {}
	for b in _territory_bids_for(territory_id, siege):
		if int(b.get("gangId", 0)) == my_gang_id:
			my_bid = b
			break
	if phase == "apply_open":
		if not is_leader:
			_add_info_line(parent, "仅帮主可申请/竞价", true)
			return
		if not my_bid.is_empty() and not bool(my_bid.get("forfeited", false)):
			_add_info_line(parent, "本帮已申请该领地，请等待竞价阶段", true)
			return
		var siege_cfg: Dictionary = siege.get("config", {})
		var buffs: Array = siege_cfg.get("siegeBuffs", [])
		var buff_ids: Array = [""]
		var buff_labels: Array = ["无攻城增益"]
		for b in buffs:
			if not b is Dictionary:
				continue
			buff_ids.append(str(b.get("id", "")))
			buff_labels.append("+%d%% · 消耗 %s" % [
				int(b.get("pct", 0)), 
				_format_big_number(int(b.get("cost", 0))), 
			])
		var buff_pick: = OptionButton.new()
		for i in range(buff_labels.size()):
			buff_pick.add_item(str(buff_labels[i]), i)
		buff_pick.custom_minimum_size = Vector2(0, 36)
		parent.add_child(buff_pick)
		var bid_edit: = _add_bid_wan_input_row(parent, cfg, base_bid)
		var apply_btn: = Button.new()
		apply_btn.text = "申请占领"
		apply_btn.custom_minimum_size = Vector2(0, 40)
		_style_war_interface_button(apply_btn, action_tier_key)
		apply_btn.pressed.connect( func():
			var parsed: = _parse_bid_wan_amount(bid_edit.text, base_bid, cfg)
			if not bool(parsed.get("ok", false)):
				_show_gang_message(str(parsed.get("error", "出价无效")), false)
				return
			var amount: = int(parsed.get("amount", 0))
			var buff_idx: = buff_pick.selected
			var buff_id: = str(buff_ids[buff_idx]) if buff_idx >= 0 and buff_idx < buff_ids.size() else ""
			_confirm_gang_action(
				"申请占领", 
				"将冻结帮派资金 %s，确认申请？" % _format_big_number(amount), 
				func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_apply(territory_id, amount, round_no, buff_id)
					layer.queue_free(), 
				"确认申请", 
				layer
			)
		)
		parent.add_child(apply_btn)
	elif phase == "blind_bidding":
		if not is_leader:
			_add_info_line(parent, "仅帮主可申请/竞价", true)
			return
		if my_bid.is_empty() or bool(my_bid.get("forfeited", false)):
			_add_info_line(parent, "本帮未申请该领地，无法参与竞价", true)
			return
		var already_submitted: = bool(my_bid.get("blindBidSubmitted", false))
		if already_submitted:
			_add_info_line(parent, "本帮已提交出价，等待竞价截止公布结果", true)
		else:
			_add_info_line(parent, "盲盒竞价：请填写一次出价（万，金额对外保密）", true)
			var bid_edit: = _add_bid_wan_input_row(parent, cfg, base_bid)
			var bid_btn: = Button.new()
			bid_btn.text = "提交出价"
			bid_btn.custom_minimum_size = Vector2(0, 40)
			_style_war_interface_button(bid_btn, action_tier_key)
			bid_btn.pressed.connect( func():
				var parsed: = _parse_bid_wan_amount(bid_edit.text, base_bid, cfg)
				if not bool(parsed.get("ok", false)):
					_show_gang_message(str(parsed.get("error", "出价无效")), false)
					return
				var amount: = int(parsed.get("amount", 0))
				_confirm_gang_action(
					"盲盒出价", 
					"将调整冻结资金至 %s（对外保密），确认提交？" % _format_big_number(amount), 
					func():
						if _gang_mgr and _gang_mgr.gang_network:
							_gang_mgr.gang_network.siege_bid(territory_id, amount, round_no)
						layer.queue_free(), 
					"确认出价", 
					layer
				)
			)
			parent.add_child(bid_btn)
		var forfeit_btn: = Button.new()
		forfeit_btn.text = "放弃竞价"
		forfeit_btn.custom_minimum_size = Vector2(0, 40)
		_style_war_interface_button(forfeit_btn, action_tier_key)
		forfeit_btn.pressed.connect( func():
			_confirm_gang_action(
				"放弃竞价", 
				"放弃后冻结资金将退还，且本轮失去攻占资格。确认放弃？", 
				func():
					if _gang_mgr and _gang_mgr.gang_network:
						_gang_mgr.gang_network.siege_forfeit(territory_id, round_no)
					layer.queue_free(), 
				"确认放弃", 
				layer
			)
		)
		parent.add_child(forfeit_btn)
	elif phase in ["bid_revealed", "rest", "apply_closed"]:
		_add_info_line(parent, "当前阶段不可操作", true)

func _show_territory_challenge_guide(parent: Node, territory_id: String, siege: Dictionary) -> void :
	var session: = _siege_session_for_territory(territory_id)
	if session.is_empty():
		if not _territory_has_challenge_entry(siege, territory_id):
			_add_info_line(parent, "挑战场次准备中，请稍候…", true)
		else:
			_add_info_line(parent, "挑战数据加载中，请稍候…", true)
		_maybe_refresh_siege_for_challenge_prep(territory_id)
		return
	var role: = str(session.get("role", "spectator"))
	if role == "defender" and session.has("durability"):
		_add_info_line(parent, "耐久 %d/%d · 防守槽 %d" % [
			int(session.get("durability", 0)), 
			int(session.get("durabilityMax", 120)), 
			int(session.get("defenseSlotsLeft", 0)), 
		], true)
	else:
		_add_info_line(parent, "进行中 · 防守槽 %d（耐久机密）" % int(session.get("defenseSlotsLeft", 0)), true)
	match role:
		"attacker":
			_add_info_line(parent, "请在下方「领地挑战」卡片进行进攻", true)
		"defender":
			_add_info_line(parent, "请在下方「领地挑战」卡片进行加固", true)
		_:
			_add_info_line(parent, "本帮非参战方", true)

func _render_other_gangs() -> void :
	if _gang_mgr == null:
		var err_card: = _add_card("帮战")
		_add_info_line(_card_box(err_card), "帮派模块未就绪", true)
		return
	var gang: Dictionary = _gang_mgr.overview.get("gang", {})
	var cfg: Dictionary = _gang_mgr.overview.get("config", {})
	var kick_rules_cb: = func():
		_show_gang_rules_popup("帮战规则", GangConfig.build_kick_war_rules_text(cfg))
	var intro_card: = _add_card("帮战", kick_rules_cb, "", [{
		"text": "帮战记录", 
		"callback": Callable(self, "_on_kick_history_pressed"), 
	}])
	var intro_box: = _card_box(intro_card)
	var gang_level: = int(gang.get("level", 1))
	var kick_unlocked: = gang_level >= KICK_UNLOCK_LEVEL
	var kick_cost: = int(cfg.get("kickHallCost", 50000))
	if not kick_unlocked:
		_add_info_line(intro_box, "帮战需帮派 Lv.%d，当前 Lv.%d" % [KICK_UNLOCK_LEVEL, gang_level], true)
	else:
		_add_info_line(intro_box, "宣战消耗帮派资金 %s · 仅帮主/副帮主可发起" % _format_big_number(kick_cost), true)
	var kick_start_blocked: = GangConfig.is_kick_start_blocked(cfg)
	if kick_start_blocked:
		var block_end: = int(cfg.get("kickStartBlockEndHour", 8))
		_add_info_line(intro_box, "北京时间 %d:00 前不可发起宣战" % block_end, true)
	if not _gang_mgr.has_gang_mirror:
		_add_info_line(intro_box, "请先在成员列表更新帮派镜像后再进攻", true)
	_render_kick_attacking_cards()
	_render_kick_defending_cards()
	_render_kick_activity_feed()
	var my_gang_id: = int(gang.get("id", 0))
	var viewer_role: = _get_viewer_role()
	var can_declare_kick: = kick_unlocked and viewer_role <= 2
	var can_start_kick: = can_declare_kick and not kick_start_blocked
	var target_card: = _add_card("宣战目标")
	var target_box: = _card_box(target_card)
	var gangs: Array = _gang_mgr.other_gangs
	if gangs.is_empty():
		if not _others_fetch_started:
			_others_fetch_started = true
			_add_info_line(target_box, "帮派列表加载中…", true)
			_gang_mgr.refresh_other_gangs()
			_gang_mgr.refresh_kick_active()
			_gang_mgr.refresh_kick_defending()
		else:
			_add_info_line(target_box, "暂无宣战目标或加载失败，请切换 Tab 重试", true)
		return
	var shown: = 0
	for g in gangs:
		if not g is Dictionary:
			continue
		var gid: = int(g.get("id", 0))
		if gid <= 0 or gid == my_gang_id:
			continue
		if _gang_mgr.has_kick_war_with_gang(gid):
			continue
		target_box.add_child(_make_other_gang_row(g, can_start_kick, can_declare_kick, kick_start_blocked))
		shown += 1
	if shown == 0:
		_add_info_line(target_box, "暂无其他宣战目标（进行中的帮战请在上方卡片操作）", true)

func _make_other_gang_row(g: Dictionary, can_start_kick: bool, can_declare_kick: bool = false, kick_start_blocked: bool = false) -> Control:
	var row: = Panel.new()
	row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	row.clip_contents = true
	var notice: = str(g.get("notice", "")).strip_edges()
	var leader_name: = _gang_list_leader_name(g)
	row.custom_minimum_size = Vector2(0, KICK_WAR_TARGET_ROW_HEIGHT)
	var margin: = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	var target_gang_id: = int(g.get("id", 0))
	var h: = HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 8)
	margin.add_child(h)
	var emblem_id: = int(g.get("emblem_id", g.get("emblemId", 1)))
	var icon: = _create_gang_emblem_icon(emblem_id, KICK_WAR_EMBLEM_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var title_text: = "%s  Lv.%d  (%d 人)" % [
		str(g.get("name", "")), 
		int(g.get("level", 1)), 
		int(g.get("member_count", g.get("memberCount", 0))), 
	]
	var info: = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	var title: = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", KICK_WAR_ROW_FONT_SIZE)
	info.add_child(title)
	var leader_lbl: = Label.new()
	leader_lbl.text = "帮主：%s" % leader_name if not leader_name.is_empty() else "帮主：—"
	leader_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_lbl.custom_minimum_size = Vector2(0, KICK_WAR_ROW_LEADER_LINE_HEIGHT)
	leader_lbl.add_theme_font_size_override("font_size", KICK_WAR_ROW_NOTICE_FONT_SIZE)
	leader_lbl.add_theme_color_override("font_color", Color(0.863, 0.836, 0.774))
	info.add_child(leader_lbl)
	var notice_lbl: = Label.new()
	notice_lbl.text = notice
	notice_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_lbl.custom_minimum_size = Vector2(0, KICK_WAR_ROW_NOTICE_LINE_HEIGHT)
	notice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_lbl.max_lines_visible = 2
	notice_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	notice_lbl.add_theme_font_size_override("font_size", KICK_WAR_ROW_NOTICE_FONT_SIZE)
	notice_lbl.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
	info.add_child(notice_lbl)
	var target_below_protect: = int(g.get("level", 1)) < KICK_UNLOCK_LEVEL
	if can_start_kick and not target_below_protect:
		var kick_btn: = Button.new()
		kick_btn.text = "宣战"
		kick_btn.custom_minimum_size = Vector2(84, 40)
		kick_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UIStyle.apply_action_button_style(kick_btn)
		kick_btn.pressed.connect( func():
			if _gang_mgr and _gang_mgr.gang_network:
				kick_btn.disabled = true
				kick_btn.text = "…"
				_gang_mgr.gang_network.kick_start(target_gang_id)
		)
		h.add_child(kick_btn)
	else:
		var hint: = Label.new()
		if target_below_protect:
			hint.text = "低于%d级不可宣战" % KICK_UNLOCK_LEVEL
		elif can_declare_kick and kick_start_blocked:
			var block_end: = 8
			if _gang_mgr and _gang_mgr.overview is Dictionary:
				block_end = int(_gang_mgr.overview.get("config", {}).get("kickStartBlockEndHour", 8))
			hint.text = "%d:00 后可宣战" % block_end
		elif _get_viewer_role() > 2:
			hint.text = "仅帮主/副帮主可发起"
		else:
			hint.text = "未解锁"
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", KICK_WAR_ROW_NOTICE_FONT_SIZE)
		hint.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		h.add_child(hint)
	return row

func _parse_beijing_datetime_to_unix(raw: String) -> int:
	var original: = raw.strip_edges()
	if original.is_empty():
		return 0
	var had_beijing_offset: = original.find("+08:00") >= 0 or original.find("+0800") >= 0
	var s: = original
	var dot_idx: = s.find(".")
	if dot_idx > 0:
		s = s.substr(0, dot_idx)
	var plus_idx: = s.find("+")
	if plus_idx > 0:
		s = s.substr(0, plus_idx)
	var z_idx: = s.to_upper().find("Z")
	if z_idx > 0:
		s = s.substr(0, z_idx)
	if s.find("T") < 0 and s.find(" ") >= 0:
		s = s.replace(" ", "T")
	var iso_regex: = RegEx.new()
	iso_regex.compile("^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})$")
	var result: = iso_regex.search(s)
	if result == null:
		return 0
	var dict: = {
		"year": result.get_string(1).to_int(), 
		"month": result.get_string(2).to_int(), 
		"day": result.get_string(3).to_int(), 
		"hour": result.get_string(4).to_int(), 
		"minute": result.get_string(5).to_int(), 
		"second": result.get_string(6).to_int(), 
	}
	var local_unix: = int(Time.get_unix_time_from_datetime_dict(dict))
	if had_beijing_offset:
		var tz: = Time.get_time_zone_from_system()
		var device_offset_sec: = - int(tz.get("bias", 0)) * 60
		return local_unix - BEIJING_OFFSET_SEC + device_offset_sec
	return local_unix

func _format_seconds_left(left_sec: int) -> String:
	if left_sec <= 0:
		return "即将结束"
	var hours: = left_sec / 3600
	var mins: = (left_sec % 3600) / 60
	if hours > 0:
		return "剩余约 %d 小时 %d 分" % [hours, mins]
	return "剩余约 %d 分钟" % max(mins, 1)

func _format_kick_time_left(ends_at) -> String:
	var raw: = str(ends_at).strip_edges()
	if raw.is_empty():
		return "进行中"
	var unix: = _parse_beijing_datetime_to_unix(raw)
	if unix <= 0:
		return "进行中"
	var now_unix: = int(Time.get_unix_time_from_system())
	if game_manager and game_manager.has_method("get_authoritative_unix_time"):
		var auth: = int(game_manager.get_authoritative_unix_time(true))
		if auth > 0:
			now_unix = auth
	var left_sec: = int(unix - now_unix)
	return _format_seconds_left(left_sec)

func _render_no_gang() -> void :
	_status_label.text = "尚未加入帮派"
	if _no_gang_view == "create":
		_render_no_gang_create()
	else:
		_render_no_gang_list()

func _show_no_gang_view(view: String) -> void :
	_no_gang_view = view
	_clear_content()
	if _no_gang_view == "create":
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.fetch_list()
		_render_no_gang_create()
	else:
		_render_no_gang_list()
	_apply_content_scroll_touch_passthrough()

func _get_create_config() -> Dictionary:
	return _gang_mgr.overview.get("config", {}) if _gang_mgr else {}

func _merged_siege_rules_cfg() -> Dictionary:
	var out: Dictionary = {}
	if _gang_mgr:
		var ov_cfg: Dictionary = _gang_mgr.overview.get("config", {})
		out = ov_cfg.duplicate(true)
		var siege_cfg: Dictionary = _gang_mgr.siege_status.get("config", {})
		for k in siege_cfg.keys():
			out[k] = siege_cfg[k]
		if _gang_mgr.siege_status.has("schedule"):
			out["siegeSchedule"] = _gang_mgr.siege_status.get("schedule")
	return out

func _siege_schedule_dict(siege: Dictionary) -> Dictionary:
	return siege.get("schedule", {})

func _siege_battle_day_active(siege: Dictionary) -> bool:
	if _gang_mgr:
		if not _gang_mgr.siege_active_sessions.is_empty():
			return true
		if not siege.get("activeSessions", []).is_empty():
			return true
	var phase: = str(siege.get("phase", ""))
	if phase in ["apply_open", "apply_closed", "blind_bidding", "bid_revealed", "challenge", "rest"]:
		return true
	var sch: Dictionary = _siege_schedule_dict(siege)
	if bool(sch.get("ignoreWeekdayForTest", false)) and not phase.is_empty() and phase != "idle":
		return true
	if siege.has("isBattleDay"):
		return bool(siege.get("isBattleDay", false))
	return bool(siege.get("isSunday", false))

func _render_no_gang_list() -> void :
	var cfg: Dictionary = _get_create_config()
	var yuanbao_cost: = int(cfg.get("createYuanbaoCost", 1000))
	var min_reinc: = int(cfg.get("createMinReincarnation", 99))
	var leader_contrib: = int(cfg.get("createLeaderContribution", 2000))
	var create_card: = _add_card("创建帮派")
	var create_box: = _card_box(create_card)
	_add_info_line(create_box, "创建需 %d 元宝 · 投胎次数 > %d" % [yuanbao_cost, min_reinc], true)
	_add_info_line(create_box, "成功创建后帮主获得 %d 帮贡" % leader_contrib, true)
	var create_btn: = _add_styled_button(create_box, "创建帮派", true)
	create_btn.pressed.connect( func(): _show_no_gang_view("create"))
	var list_card: = _add_card("帮派列表")
	var list_box: = _card_box(list_card)
	var list_inner: = VBoxContainer.new()
	list_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_inner.add_theme_constant_override("separation", 8)
	list_box.add_child(list_inner)
	var rec: Array = (_gang_mgr.overview.get("recommended", []) if _gang_mgr else [])
	if rec.is_empty():
		_add_info_line(list_inner, "暂无帮派，你可以创建第一个帮派", true)
	else:
		for g in rec:
			if not g is Dictionary:
				continue
			list_inner.add_child(_make_recommend_row(g))
	var refresh_btn: = _add_styled_button(list_box, "刷新列表")
	refresh_btn.pressed.connect( func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.fetch_list()
	)
	if not _list_fetch_scheduled:
		_list_fetch_scheduled = true
		call_deferred("_fetch_gang_list_once")

func _fetch_gang_list_once() -> void :
	if _gang_mgr == null or _gang_mgr.gang_network == null:
		return
	if _no_gang_view != "list":
		return
	if bool(_gang_mgr.overview.get("hasGang", false)):
		return
	_gang_mgr.gang_network.fetch_list()

func _render_no_gang_create() -> void :
	var back_btn: = Button.new()
	back_btn.text = "← 返回列表"
	back_btn.custom_minimum_size = Vector2(120, 38)
	back_btn.add_theme_font_size_override("font_size", 15)
	UIStyle.apply_button_style(back_btn)
	back_btn.pressed.connect( func(): _show_no_gang_view("list"))
	_add_centered_button_row(_content, back_btn)
	var cfg: Dictionary = _get_create_config()
	var yuanbao_cost: = int(cfg.get("createYuanbaoCost", 1000))
	var min_reinc: = int(cfg.get("createMinReincarnation", 99))
	var leader_contrib: = int(cfg.get("createLeaderContribution", 2000))
	var create_card: = _add_card("创建帮派")
	var create_box: = _card_box(create_card)
	_add_info_line(create_box, "创建条件：%d 元宝 + 投胎次数 > %d" % [yuanbao_cost, min_reinc], true)
	_add_info_line(create_box, "成功创建后帮主获得 %d 帮贡" % leader_contrib, true)
	_add_info_line(create_box, "名称若创建失败，多为已被占用；支持 2~6 个中文字", true)
	var name_row: = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var name_lbl: = Label.new()
	name_lbl.text = "帮派名称"
	name_lbl.custom_minimum_size = Vector2(72, 0)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_row.add_child(name_lbl)
	var name_edit: = LineEdit.new()
	name_edit.placeholder_text = "2~6 个中文"
	name_edit.text = _draft_name
	_style_line_edit(name_edit)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_edit)
	create_box.add_child(name_row)
	var notice_row: = HBoxContainer.new()
	notice_row.add_theme_constant_override("separation", 8)
	var notice_lbl: = Label.new()
	notice_lbl.text = "帮派公告"
	notice_lbl.custom_minimum_size = Vector2(72, 0)
	notice_lbl.add_theme_font_size_override("font_size", 15)
	notice_row.add_child(notice_lbl)
	var notice_edit: = LineEdit.new()
	notice_edit.placeholder_text = "可选，最多100字"
	notice_edit.max_length = 100
	_style_line_edit(notice_edit)
	notice_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_row.add_child(notice_edit)
	create_box.add_child(notice_row)
	_ensure_selected_emblem_available()
	var available_ids: Array = _get_available_emblem_ids()
	if available_ids.is_empty():
		_add_info_line(create_box, "暂无可用徽记，请稍后再试", true)
		var disabled_btn: = _add_styled_button(create_box, "确认创建", true)
		disabled_btn.disabled = true
		return
	_add_info_line(create_box, "选择帮派徽记（可选 %d 款，已被占用的不显示）" % available_ids.size(), true)
	var grid_wrap: = ScrollContainer.new()
	grid_wrap.custom_minimum_size = Vector2(0, 200)
	grid_wrap.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_wrap.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid_wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	create_box.add_child(grid_wrap)
	var grid: = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_wrap.add_child(grid)
	for emblem_id in available_ids:
		grid.add_child(_make_emblem_pick_btn(int(emblem_id), grid))
	var create_btn: = _add_styled_button(create_box, "确认创建", true)
	create_btn.pressed.connect( func():
		_draft_name = name_edit.text.strip_edges()
		var name_err: = _validate_gang_name(_draft_name)
		if not name_err.is_empty():
			_show_gang_message(name_err, false)
			return
		if _selected_emblem_id <= 0 or _gang_mgr.is_emblem_used(_selected_emblem_id):
			_show_gang_message("所选徽记不可用，请重新选择", false)
			return
		if _gang_mgr and _gang_mgr.gang_network:
			create_btn.disabled = true
			create_btn.text = "创建中…"
			_gang_mgr.gang_network.create_gang(_draft_name, _selected_emblem_id, notice_edit.text.strip_edges())
	)

func _make_emblem_pick_btn(emblem_id: int, grid: GridContainer) -> Button:
	var btn: = Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.focus_mode = Control.FOCUS_NONE
	var tex: = load(GangConfig.emblem_path(emblem_id)) as Texture2D
	if tex:
		btn.icon = tex
		btn.expand_icon = true
	var selected: = emblem_id == _selected_emblem_id
	btn.add_theme_stylebox_override("normal", UIStyle.create_selectable_item_style(selected))
	btn.add_theme_stylebox_override("hover", UIStyle.create_selectable_item_style(selected))
	btn.add_theme_stylebox_override("pressed", UIStyle.create_selectable_item_style(true))
	btn.set_meta("emblem_id", emblem_id)
	var pick_id: int = emblem_id
	btn.pressed.connect( func(): _select_emblem(pick_id, grid))
	return btn

func _select_emblem(emblem_id: int, grid: GridContainer) -> void :
	_selected_emblem_id = emblem_id
	if grid == null:
		return
	for child in grid.get_children():
		if not child is Button:
			continue
		var bid: = int(child.get_meta("emblem_id", 0))
		var selected: = bid == emblem_id
		child.add_theme_stylebox_override("normal", UIStyle.create_selectable_item_style(selected))
		child.add_theme_stylebox_override("hover", UIStyle.create_selectable_item_style(selected))
		child.add_theme_stylebox_override("pressed", UIStyle.create_selectable_item_style(true))

func _gang_list_leader_name(g: Dictionary) -> String:
	return str(g.get("leaderName", g.get("leader_name", ""))).strip_edges()

func _make_recommend_row(g: Dictionary) -> Control:
	var row: = Panel.new()
	row.add_theme_stylebox_override("panel", UIStyle.create_item_style())
	var leader_name: = _gang_list_leader_name(g)
	row.custom_minimum_size = Vector2(0, 72 if not leader_name.is_empty() else 52)
	var h: = HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_top = 6
	h.offset_right = -8
	h.offset_bottom = -6
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	var emblem_id: = int(g.get("emblem_id", g.get("emblemId", 1)))
	var icon: = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex: = load(GangConfig.emblem_path(emblem_id)) as Texture2D
	if tex:
		icon.texture = tex
	h.add_child(icon)
	var info: = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	var lbl: = Label.new()
	lbl.text = "%s  Lv.%d  (%d 人)" % [
		str(g.get("name", "")), 
		int(g.get("level", 1)), 
		int(g.get("member_count", g.get("memberCount", 0))), 
	]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(lbl)
	if not leader_name.is_empty():
		var leader_lbl: = Label.new()
		leader_lbl.text = "帮主：%s" % leader_name
		leader_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		leader_lbl.add_theme_font_size_override("font_size", 13)
		leader_lbl.add_theme_color_override("font_color", Color(0.708, 0.688, 0.633))
		info.add_child(leader_lbl)
	var apply: = Button.new()
	apply.text = "申请"
	apply.custom_minimum_size = Vector2(64, 34)
	UIStyle.apply_action_button_style(apply)
	var apply_gang_id: int = int(g.get("id", 0))
	apply.pressed.connect( func():
		if _gang_mgr and _gang_mgr.gang_network:
			_gang_mgr.gang_network.apply_gang(apply_gang_id)
	)
	h.add_child(apply)
	return row

func _add_retry_button() -> void :
	var btn: = _add_styled_button(_content, "重新加载")
	btn.pressed.connect( func():
		_load_error = ""
		_status_label.text = "加载中..."
		_clear_content()
		_request_overview()
	)

func _get_available_emblem_ids() -> Array:
	var out: Array = []
	for emblem_id in range(1, 33):
		if _gang_mgr == null or not _gang_mgr.is_emblem_used(emblem_id):
			out.append(emblem_id)
	return out

func _ensure_selected_emblem_available() -> void :
	if _gang_mgr == null:
		return
	if not _gang_mgr.is_emblem_used(_selected_emblem_id):
		return
	var available_ids: Array = _get_available_emblem_ids()
	_selected_emblem_id = int(available_ids[0]) if not available_ids.is_empty() else 0

func _validate_gang_name(name: String) -> String:
	var n: = name.strip_edges()
	if n.is_empty():
		return "请输入帮派名称"
	if n.length() < 2 or n.length() > 6:
		return "帮派名称须为 2~6 个中文字符"
	for i in n.length():
		var code: = n.unicode_at(i)
		if code < 19968 or code > 40959:
			return "帮派名称须为 2~6 个中文字符"
	return ""

func _show_gang_rules_popup(title: String, body: String) -> void :
	var layer: = Control.new()
	layer.name = "GangRulesLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 210
	add_child(layer)
	var dim: = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.631, 0.611, 0.564, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var popup: = Panel.new()
	popup.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.custom_minimum_size = Vector2(520, 0)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(popup)
	var host_size: = size if size.x > 1.0 and size.y > 1.0 else get_viewport_rect().size
	var popup_h: = clampf(host_size.y * 0.62, 320.0, 540.0)
	popup.custom_minimum_size = Vector2(520, popup_h)
	popup.size = Vector2(520, popup_h)
	popup.position = Vector2(
		maxf(8.0, (host_size.x - 520.0) * 0.5), 
		maxf(8.0, (host_size.y - popup_h) * 0.5)
	)
	var outer: = VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 16
	outer.offset_top = 14
	outer.offset_right = -16
	outer.offset_bottom = -14
	outer.add_theme_constant_override("separation", 10)
	popup.add_child(outer)
	var title_lbl: = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	outer.add_child(title_lbl)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)
	var body_lbl: = Label.new()
	body_lbl.text = body
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 15)
	body_lbl.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.custom_minimum_size = Vector2(480, 0)
	scroll.add_child(body_lbl)
	var ok_btn: = Button.new()
	ok_btn.text = "知道了"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): layer.queue_free())
	outer.add_child(ok_btn)
	dim.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			layer.queue_free()
	)

func _show_gang_message(message: String, is_success: bool) -> void :
	var title: = "提示" if is_success else "注意"
	ConfirmDialog.show_message(self, title, message)

func _try_show_pending_siege_attack_result() -> void :
	call_deferred("_deferred_show_pending_siege_attack_result")

func _deferred_show_pending_siege_attack_result() -> void :
	if _gang_mgr == null:
		return
	var data: Dictionary = _gang_mgr.consume_pending_siege_attack_result()
	if data.is_empty():
		return
	var msg: String = _gang_mgr.format_siege_attack_result_message(data)
	_show_gang_message(msg, true)
