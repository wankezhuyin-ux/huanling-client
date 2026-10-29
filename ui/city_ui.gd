extends Control
class_name CityUI

signal city_closed
signal chat_channel_cache_restore_requested(channel: String, gang_id: int)
signal chat_channel_history_fetched(channel: String, gang_id: int, messages: Array)

const UIStyle = preload("res://scripts/ui_style.gd")
const TOWER_HUB_UI_SCRIPT_PATH: = "res://ui/city/tower_hub_ui.gd"
const LUCKY_DRAW_UI_SCRIPT_PATH: = "res://ui/city/lucky_draw_ui.gd"
const SCRIPT_RANKING_HALL: = "res://ui/city/ranking_hall.gd"
const SCRIPT_SUIT_DUNGEON_UI: = "res://ui/city/suit_dungeon_ui.gd"
const SCRIPT_DUNGEON_HUB_UI: = "res://ui/city/dungeon_hub_ui.gd"
const SCRIPT_MARTIAL_HALL: = "res://ui/city/martial_hall.gd"
const SCRIPT_QIANKUN_HALL: = "res://ui/city/qiankun_hall.gd"
const SCRIPT_PET_PARK: = "res://ui/city/pet_park.gd"
const SCRIPT_SHOP_UI: = "res://ui/city/shop_ui.gd"
const SCRIPT_WAREHOUSE_UI: = "res://ui/city/warehouse_ui.gd"
const SCRIPT_SETTINGS_HALL: = "res://ui/city/settings_hall.gd"
const SCRIPT_QUEST_UI: = "res://ui/quest_ui.gd"
const SCRIPT_ARENA_HUB_UI: = "res://ui/city/arena_hub_ui.gd"
const SCRIPT_CRAFTING_MAIN_UI: = "res://ui/forge/crafting_main_ui.gd"
const SCRIPT_TREASURE_CAVE_UI: = "res://ui/city/treasure_cave_ui.gd"
const SCRIPT_GANG_HALL: = "res://ui/city/gang_hall.gd"
const SCRIPT_SIGNIN7_UI: = "res://ui/city/signin7_ui.gd"
const SCRIPT_SHENGSI_TOWER_UI: = "res://ui/city/shengsi_tower_ui.gd"
const SIGNIN7_ICON_PATH: = "res://assets/ui/city/qrqd.png"
const SHENGSI_ICON_PATH: = "res://assets/ui/shengsi_tower/icon_entry.png"
const XianMoMain = preload("res://ui/xianmo/xianmo_main.tscn")
const VipBenefits = preload("res://scripts/vip_benefits.gd")

static func _call_script_static(script_path: String, method: String, args: Array = []) -> Variant:
	var script_res: = load(script_path) as GDScript
	if script_res == null:
		push_error("[CityUI] 脚本加载失败: %s" % script_path)
		return null
	return script_res.callv(method, args)

## 水墨主城：把左列 16 个矩形按钮换成场景里的竖吊牌 + 右上圆钮。
## 置 false 可退回原来的矩形按钮布局（旧代码全部保留）。
const INK_UI: = true
var _ink: CityInkLayer = null
## 内页统一底板（主城水墨景虚化 + 墨青罩 + 主题光晕 + 纸纹），全静态绘制。
var _backdrop: InkPageBackdrop = null
var _forge_btn: Button = null

const FEATURE_GRID_PATH: = "VBoxContainer/MainContent/FeaturePanel/FeatureVBox/FeatureScroll/GridContainer"
const FEATURE_BTN_TEX_PATH: = "res://assets/city/blue_button.png"

@onready var ranking_btn = get_node_or_null(FEATURE_GRID_PATH + "/RankingBtn")
@onready var tower_btn = get_node_or_null(FEATURE_GRID_PATH + "/TowerBtn")
@onready var suit_dungeon_btn = get_node_or_null(FEATURE_GRID_PATH + "/SuitDungeonBtn")
@onready var martial_btn = get_node_or_null(FEATURE_GRID_PATH + "/MartialBtn")
@onready var crafting_btn = get_node_or_null(FEATURE_GRID_PATH + "/CraftingBtn")
@onready var pet_btn = get_node_or_null(FEATURE_GRID_PATH + "/PetBtn")
@onready var warehouse_btn = get_node_or_null(FEATURE_GRID_PATH + "/WarehouseBtn")
@onready var quest_btn = get_node_or_null(FEATURE_GRID_PATH + "/QuestBtn")
@onready var shop_btn = get_node_or_null(FEATURE_GRID_PATH + "/ShopBtn")
@onready var mail_btn = get_node_or_null(FEATURE_GRID_PATH + "/MailBtn")
@onready var settings_btn = get_node_or_null(FEATURE_GRID_PATH + "/SettingsBtn")
@onready var lucky_draw_btn = get_node_or_null(FEATURE_GRID_PATH + "/LuckyDrawBtn")
@onready var more_btn = get_node_or_null(FEATURE_GRID_PATH + "/MoreBtn")
@onready var xianmo_btn = get_node_or_null(FEATURE_GRID_PATH + "/XianMoBtn")
@onready var treasure_cave_btn = get_node_or_null(FEATURE_GRID_PATH + "/TreasureCaveBtn")


var mail_unread_label: Label = null

@onready var back_btn = $VBoxContainer / MainContent / BackButton
@onready var feature_panel = $VBoxContainer / MainContent / FeaturePanel
@onready var home_gap_spacer = $VBoxContainer / MainContent / HomeGapSpacer
@onready var grid_container = get_node_or_null(FEATURE_GRID_PATH)
@onready var chat_panel = $VBoxContainer / MainContent / ChatPanel
@onready var content_container = $VBoxContainer / MainContent / ContentContainer


@onready var chat_scroll = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / ChatMessagesPanel / ChatScroll
@onready var chat_content = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / ChatMessagesPanel / ChatScroll / ChatContent
@onready var chat_input = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / InputHBox / ChatInput
@onready var send_btn = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / InputHBox / SendBtn
@onready var announcement_label = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / ChatHeader / AnnouncementLabel
@onready var chat_title_label = $VBoxContainer / MainContent / ChatPanel / VBoxContainer / ChatHeader / ChatTitle

var game_manager = null
var chat_messages: Array = []
var current_content: Control = null
var xianmo_panel: Control = null
var content_cache: Dictionary = {}
var _warned_null_gm: bool = false
var _last_failed_message: String = ""
var _last_send_error_text: String = ""
var _last_send_error_time: float = 0.0
var _recent_announcement_at: Dictionary = {}
const ANNOUNCEMENT_DEDUP_WINDOW_SEC: = 120.0

const CHAT_INITIAL_DISPLAY_COUNT: = 10
const CHAT_DEFERRED_BATCH_SIZE: = 8
var _displayed_feed_keys: Dictionary = {}
var _chat_batch_pending: Array = []
var _chat_batch_running: bool = false
var _chat_channel_world_btn: Button = null
var _chat_channel_gang_btn: Button = null
var _active_chat_channel: String = "world"
var _active_chat_gang_id: int = 0
var _signin7_wrap: Control = null
var _signin7_dot: Control = null
var _signin7_refreshing: bool = false
var _signin7_can_claim: bool = false
var _signin7_logged_in: bool = false
## 红点：key → 小圆点节点。是否显示完全由游戏状态决定（见 _red_dot_flags），
## 美术资源里不再烘死任何红点。
var _red_dots: Dictionary = {}
var _dot_tex: Texture2D = null
var _dot_timer: Timer = null
var _shengsi_tower_wrap: Control = null
var _shengsi_tower_btn: Button = null

func _require_game_manager() -> bool:
	if game_manager != null:
		return true
	if not _warned_null_gm:
		_warned_null_gm = true
		push_warning("[CityUI] game_manager 未注入，主城格子不可用（应由 MainUI 调用 set_game_manager）")
	return false

func _ready():
	var bg = get_node_or_null("Background")
	if bg is Control:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_signals()
	_setup_chat_scroll()
	_setup_chat_channel_tabs()
	_add_forge_button()
	if INK_UI:
		_build_ink_city()
		_setup_page_backdrop()
		_setup_signin7_entry()
		_setup_red_dot_timer()
		_hide_content()
		_ink_finish()
		return
	_reorder_top_grid_buttons()
	_apply_feature_button_textures()
	_build_feature_columns_88()
	_setup_feature_fold()
	if suit_dungeon_btn:
		suit_dungeon_btn.text = "副本挑战"
	if more_btn:
		more_btn.text = "帮派"
	_setup_signin7_entry()

	_hide_content()

func _make_feature_button_style(tex: Texture2D, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var style: = StyleBoxTexture.new()
	style.texture = tex
	style.modulate_color = modulate

	style.texture_margin_left = 0
	style.texture_margin_top = 0
	style.texture_margin_right = 0
	style.texture_margin_bottom = 0
	return style

func _feature_button_size_for_texture(tex: Texture2D) -> Vector2:

	var aspect: = 1.94
	if tex != null and tex.get_height() > 0:
		aspect = float(tex.get_width()) / float(tex.get_height())
	var w: = 120.0
	var h: = snappedf(w / aspect, 1.0)
	return Vector2(w, h)

func _apply_feature_button_style(btn: Button, tex: Texture2D = null) -> void :
	if btn == null:
		return
	if tex == null:
		tex = load(FEATURE_BTN_TEX_PATH) as Texture2D
	if tex == null:
		push_warning("[CityUI] 功能格底图加载失败: %s" % FEATURE_BTN_TEX_PATH)
		return
	btn.add_theme_stylebox_override("normal", _make_feature_button_style(tex))
	btn.add_theme_stylebox_override("hover", _make_feature_button_style(tex, Color(1.08, 1.08, 1.12, 1)))
	btn.add_theme_stylebox_override("pressed", _make_feature_button_style(tex, Color(0.88, 0.88, 0.92, 1)))

	btn.custom_minimum_size = _feature_button_size_for_texture(tex)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)

	btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.7, 1))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.02, 0.95))
	btn.add_theme_constant_override("outline_size", 4)
	btn.clip_text = false

func _apply_feature_button_textures() -> void :
	if not grid_container:
		return
	var tex: = load(FEATURE_BTN_TEX_PATH) as Texture2D
	if tex == null:
		push_warning("[CityUI] 功能格底图加载失败: %s" % FEATURE_BTN_TEX_PATH)
		return
	for child in grid_container.get_children():
		if child is Button:
			_apply_feature_button_style(child, tex)

func _build_feature_columns_88() -> void :

	if grid_container == null or not is_instance_valid(grid_container):
		return
	var scroll: = grid_container.get_parent() as ScrollContainer
	if scroll == null:
		return
	var buttons: Array = []
	for child in grid_container.get_children():
		if child is Button:
			buttons.append(child)
	if buttons.is_empty():
		return
	var counts: = [8, 8]
	var columns: = HBoxContainer.new()
	columns.name = "FeatureColumns"
	columns.add_theme_constant_override("separation", 2)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var idx: = 0
	for count in counts:
		var col: = VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for _i in range(int(count)):
			if idx >= buttons.size():
				break
			var btn: Button = buttons[idx]
			idx += 1
			grid_container.remove_child(btn)
			col.add_child(btn)
		columns.add_child(col)
	var old_grid: Node = grid_container
	scroll.remove_child(old_grid)
	old_grid.queue_free()
	scroll.add_child(columns)
	grid_container = columns

const FEATURE_COLLAPSED_ROWS: = 5
const FEATURE_EXPANDED_ROWS: = 8
const FEATURE_ROW_SEP: = 4

var _feature_expanded: bool = true
var _feature_scroll: ScrollContainer = null
var _feature_expand_btn: Button = null

func _setup_feature_fold() -> void :

	_feature_scroll = get_node_or_null("VBoxContainer/MainContent/FeaturePanel/FeatureVBox/FeatureScroll") as ScrollContainer
	if _feature_scroll == null:
		return
	_feature_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_feature_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_feature_scroll.clip_contents = true
	_feature_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var feature_vbox: = _feature_scroll.get_parent() as VBoxContainer
	if feature_vbox == null:
		return
	_feature_expand_btn = feature_vbox.get_node_or_null("FeatureExpandBtn") as Button
	if _feature_expand_btn == null:
		_feature_expand_btn = Button.new()
		_feature_expand_btn.name = "FeatureExpandBtn"
		feature_vbox.add_child(_feature_expand_btn)
	_feature_expand_btn.focus_mode = Control.FOCUS_NONE
	_feature_expand_btn.custom_minimum_size = Vector2(0, 38)
	_feature_expand_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feature_expand_btn.add_theme_font_size_override("font_size", 18)
	_feature_expand_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1))
	_feature_expand_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.75, 1))
	_feature_expand_btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.4, 1))
	_feature_expand_btn.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.02, 0.9))
	_feature_expand_btn.add_theme_constant_override("outline_size", 3)
	_feature_expand_btn.add_theme_stylebox_override("normal", _make_feature_expand_btn_style(false))
	_feature_expand_btn.add_theme_stylebox_override("hover", _make_feature_expand_btn_style(true))
	_feature_expand_btn.add_theme_stylebox_override("pressed", _make_feature_expand_btn_style(false, true))
	if not _feature_expand_btn.pressed.is_connected(_on_feature_expand_pressed):
		_feature_expand_btn.pressed.connect(_on_feature_expand_pressed)
	_apply_feature_fold_state(true)

func _make_feature_expand_btn_style(hover: bool = false, pressed: bool = false) -> StyleBoxFlat:

	var style: = StyleBoxFlat.new()
	if pressed:
		style.bg_color = Color(0.12, 0.16, 0.28, 0.92)
		style.border_color = Color(0.85, 0.68, 0.28, 1)
	elif hover:
		style.bg_color = Color(0.18, 0.24, 0.4, 0.95)
		style.border_color = Color(1.0, 0.88, 0.45, 1)
	else:
		style.bg_color = Color(0.1, 0.14, 0.26, 0.9)
		style.border_color = Color(0.95, 0.78, 0.35, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style

func _feature_row_height() -> float:
	if grid_container and grid_container.get_child_count() > 0:
		var col = grid_container.get_child(0)
		if col is Container and col.get_child_count() > 0:
			var first = col.get_child(0)
			if first is Control:
				var h: float = (first as Control).custom_minimum_size.y
				if h > 0.0:
					return h
	return 62.0

func _apply_feature_fold_state(expanded: bool) -> void :
	_feature_expanded = expanded
	var rows: = FEATURE_EXPANDED_ROWS if expanded else FEATURE_COLLAPSED_ROWS
	var row_h: = _feature_row_height()
	var height: = rows * row_h + float(maxi(0, rows - 1)) * float(FEATURE_ROW_SEP)
	if _feature_scroll:
		_feature_scroll.custom_minimum_size = Vector2(0, height)
		_feature_scroll.size.y = height
	if grid_container:
		for col in grid_container.get_children():
			if not (col is Container):
				continue
			var i: = 0
			for child in col.get_children():
				if child is CanvasItem:
					(child as CanvasItem).visible = expanded or i < FEATURE_COLLAPSED_ROWS
				i += 1
	if _feature_expand_btn:
		_feature_expand_btn.text = "▲  收起功能" if expanded else "▼  展开更多"

func _on_feature_expand_pressed() -> void :
	_apply_feature_fold_state( not _feature_expanded)

func _reorder_top_grid_buttons() -> void :
	if not grid_container:
		return
	if not is_instance_valid(settings_btn) or not is_instance_valid(more_btn):
		return

	var child_count: = grid_container.get_child_count()
	if child_count < 2:
		return
	grid_container.move_child(settings_btn, child_count - 1)
	grid_container.move_child(more_btn, grid_container.get_child_count() - 2)

const CHAT_TAB_WORLD_TEX_PATH: = "res://assets/city/chat_tab_world.png"
const CHAT_TAB_GANG_TEX_PATH: = "res://assets/city/chat_tab_gang.png"

func _setup_chat_channel_tabs() -> void :
	if not chat_panel:
		return
	var header = chat_panel.get_node_or_null("VBoxContainer/ChatHeader")
	if not header:
		return
	var tabs: = HBoxContainer.new()
	tabs.name = "ChannelTabs"
	tabs.add_theme_constant_override("separation", 8)
	_chat_channel_world_btn = _create_chat_channel_tab_button(CHAT_TAB_WORLD_TEX_PATH)
	_chat_channel_gang_btn = _create_chat_channel_tab_button(CHAT_TAB_GANG_TEX_PATH)

	tabs.add_child(_chat_channel_world_btn)
	tabs.add_child(_chat_channel_gang_btn)
	header.add_child(tabs)
	_chat_channel_world_btn.pressed.connect(_on_chat_world_channel)
	_chat_channel_gang_btn.pressed.connect(_on_chat_gang_channel)
	_apply_chat_channel_ui("world")

func _create_chat_channel_tab_button(tex_path: String) -> Button:
	var btn: = Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	_apply_chat_tab_button_texture(btn, tex_path)
	return btn


## 频道签水墨化：丢掉那张「蓝红渐变 + 金框」的旧贴图，改成淡墨底 + 细金边，
## 选中的那枚底色压深、字提亮成金色，未选中只留一层更淡的墨。
func _ink_style_chat_tabs() -> void:
	var s: float = _ink.s if _ink != null else 1.0
	var ink_font: = maxi(11, int(round(19.0 * s)))
	var tab_h: = 42.0 * s
	var items: = [[_chat_channel_world_btn, "世界"], [_chat_channel_gang_btn, "帮派"]]
	for it in items:
		var b: Button = it[0]
		if b == null:
			continue
		b.set_meta("ink_tab", true)
		b.remove_meta("chat_tab_tex")
		b.text = String(it[1])
		b.add_theme_font_size_override("font_size", ink_font)
		b.custom_minimum_size = Vector2(96.0 * s, tab_h)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_chat_channel_ui(_active_chat_channel)


func _ink_chat_tab_box(active: bool) -> StyleBoxFlat:
	var s: float = _ink.s if _ink != null else 1.0
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.078, 0.063, 0.035, 0.82) if active else Color(0.055, 0.059, 0.063, 0.34)
	b.border_color = Color(0.788, 0.635, 0.294, 0.70) if active else Color(0.62, 0.58, 0.48, 0.26)
	b.set_border_width_all(1)
	b.set_corner_radius_all(int(round(4.0 * s)))
	b.content_margin_left = 8.0 * s
	b.content_margin_right = 8.0 * s
	b.content_margin_top = 2.0 * s
	b.content_margin_bottom = 2.0 * s
	return b

func get_active_chat_channel() -> String:
	return _active_chat_channel

func get_active_chat_gang_id() -> int:
	return _active_chat_gang_id

func _message_channel_type(msg_data: Dictionary) -> String:
	var channel_type: = str(msg_data.get("channel_type", msg_data.get("channelType", ""))).strip_edges()
	return channel_type if not channel_type.is_empty() else "world"

func _message_gang_id(msg_data: Dictionary) -> int:
	return int(msg_data.get("gang_id", msg_data.get("gangId", 0)))

func _message_matches_active_channel(msg_data: Dictionary) -> bool:
	if _active_chat_channel == "gang":
		return _message_channel_type(msg_data) == "gang" and _message_gang_id(msg_data) == _active_chat_gang_id
	return _message_channel_type(msg_data) != "gang"

func _make_chat_tab_style(tex: Texture2D, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var style: = StyleBoxTexture.new()
	style.texture = tex
	style.modulate_color = modulate

	style.texture_margin_left = 0
	style.texture_margin_top = 0
	style.texture_margin_right = 0
	style.texture_margin_bottom = 0
	return style

func _apply_chat_tab_button_texture(btn: Button, tex_path: String) -> void :
	if btn == null:
		return
	var tex: = load(tex_path) as Texture2D
	if tex == null:
		push_warning("[CityUI] 频道按钮素材加载失败: %s" % tex_path)
		return

	var tab_size: = Vector2(120, 56)
	if tex.get_height() > 0:
		var aspect: = float(tex.get_width()) / float(tex.get_height())
		tab_size = Vector2(snappedf(56.0 * aspect, 1.0), 56)
	btn.custom_minimum_size = tab_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_stylebox_override("normal", _make_chat_tab_style(tex))
	btn.add_theme_stylebox_override("hover", _make_chat_tab_style(tex, Color(1.06, 1.06, 1.1, 1)))
	btn.add_theme_stylebox_override("pressed", _make_chat_tab_style(tex, Color(0.9, 0.9, 0.94, 1)))
	btn.set_meta("chat_tab_tex", tex)
	btn.set_meta("chat_tab_base_size", tab_size)

func _apply_chat_channel_ui(channel: String) -> void :
	_active_chat_channel = channel
	if channel != "gang":
		_active_chat_gang_id = 0
	_set_chat_tab_active(_chat_channel_world_btn, channel == "world")
	_set_chat_tab_active(_chat_channel_gang_btn, channel == "gang")

func _set_chat_tab_active(btn: Button, active: bool) -> void :
	if btn == null:
		return
	if btn.has_meta("ink_tab"):
		var on := _ink_chat_tab_box(true)
		var off := _ink_chat_tab_box(false)
		btn.add_theme_stylebox_override("normal", on if active else off)
		btn.add_theme_stylebox_override("hover", on if active else off)
		btn.add_theme_stylebox_override("pressed", on)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("disabled", off)
		btn.add_theme_color_override("font_color",
				Color(0.949, 0.847, 0.588) if active else Color(0.78, 0.78, 0.745))
		btn.add_theme_color_override("font_hover_color",
				Color(1.0, 0.914, 0.69) if active else Color(0.90, 0.88, 0.82))
		btn.add_theme_color_override("font_pressed_color", Color(0.949, 0.847, 0.588))
		btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
		btn.add_theme_constant_override("shadow_offset_x", 1)
		btn.add_theme_constant_override("shadow_offset_y", 1)
		return
	var tex: Texture2D = btn.get_meta("chat_tab_tex", null)
	if tex == null:
		UIStyle.apply_tab_style(btn, active)
		return

	var modulate: = Color(1.08, 1.05, 0.95, 1.0) if active else Color(0.45, 0.45, 0.5, 0.72)
	var hover: = Color(1.14, 1.1, 1.0, 1.0) if active else Color(0.6, 0.6, 0.65, 0.85)
	btn.add_theme_stylebox_override("normal", _make_chat_tab_style(tex, modulate))
	btn.add_theme_stylebox_override("hover", _make_chat_tab_style(tex, hover))
	btn.add_theme_stylebox_override("pressed", _make_chat_tab_style(tex, Color(0.92, 0.9, 0.88, 1)))
	var base_size: Vector2 = btn.get_meta("chat_tab_base_size", btn.custom_minimum_size)

	btn.custom_minimum_size = base_size * (1.06 if active else 1.0)

func _clear_chat_display() -> void :
	if chat_content == null or not is_instance_valid(chat_content):
		return
	while chat_content.get_child_count() > 0:
		var ch: Node = chat_content.get_child(0)
		chat_content.remove_child(ch)
		ch.free()
	_displayed_feed_keys.clear()
	_recent_announcement_at.clear()
	_chat_batch_pending.clear()
	_chat_batch_running = false
	if chat_scroll != null and is_instance_valid(chat_scroll):
		chat_scroll.scroll_vertical = 0

func _on_chat_world_channel() -> void :
	_switch_chat_channel("world", 0)

func _on_chat_gang_channel() -> void :
	var gid: = 0
	if game_manager and game_manager.gang_manager:
		var ov: Dictionary = game_manager.gang_manager.overview
		if bool(ov.get("hasGang", false)):
			gid = int(ov.get("gang", {}).get("id", 0))
	if gid <= 0:
		add_announcement("加入帮派后可使用帮派频道")
		return
	_switch_chat_channel("gang", gid)

func _switch_chat_channel(channel: String, gang_id: int) -> void :
	if game_manager and game_manager.chat_network:
		if channel == "gang":
			game_manager.chat_network.set_gang_channel(gang_id)
		else:
			game_manager.chat_network.set_world_channel()
	_apply_chat_channel_ui(channel)
	if channel == "gang":
		_active_chat_gang_id = gang_id
	_clear_chat_display()
	_restore_channel_cache_from_host(channel, gang_id)
	if channel == "gang" and gang_id > 0:
		_load_channel_history_async(channel, gang_id)

func _restore_channel_cache_from_host(channel: String, gang_id: int) -> void :
	chat_channel_cache_restore_requested.emit(channel, gang_id)

func _load_channel_history_async(channel: String, gang_id: int) -> void :
	if game_manager == null or game_manager.chat_network == null:
		return
	if channel != "gang" or gang_id <= 0:
		return
	var hist: Array = await game_manager.chat_network.fetch_gang_chat_history(gang_id, 30)
	if _active_chat_channel != channel:
		return
	if channel == "gang" and _active_chat_gang_id != gang_id:
		return
	if not hist.is_empty():
		chat_channel_history_fetched.emit(channel, gang_id, hist)
	else:
		chat_channel_cache_restore_requested.emit(channel, gang_id)
	game_manager.chat_network.poll_messages_now()

func _setup_chat_scroll():
	chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	chat_scroll.scroll_deadzone = 20
	if chat_content:
		chat_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chat_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		chat_content.offset_left = 5
		chat_content.offset_top = 5
		chat_content.offset_right = -5
		chat_content.offset_bottom = -5
		chat_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in chat_content.get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_signals():
	ranking_btn.pressed.connect(_on_ranking_btn_pressed)
	tower_btn.pressed.connect(_on_tower_btn_pressed)
	suit_dungeon_btn.pressed.connect(on_suit_dungeon_btn_pressed)
	martial_btn.pressed.connect(_on_martial_btn_pressed)
	crafting_btn.pressed.connect(_on_crafting_btn_pressed)
	pet_btn.pressed.connect(_on_pet_btn_pressed)
	warehouse_btn.pressed.connect(_on_warehouse_btn_pressed)
	settings_btn.pressed.connect(_on_settings_btn_pressed)
	more_btn.pressed.connect(_on_more_btn_pressed)
	quest_btn.pressed.connect(_on_quest_btn_pressed)
	shop_btn.pressed.connect(_on_shop_btn_pressed)
	mail_btn.pressed.connect(_on_mail_btn_pressed)
	lucky_draw_btn.pressed.connect(_on_lucky_draw_btn_pressed)
	xianmo_btn.pressed.connect(_on_xianmo_btn_pressed)
	treasure_cave_btn.pressed.connect(_on_treasure_cave_btn_pressed)
	_ensure_shengsi_tower_float_btn()

	back_btn.pressed.connect(_on_back_btn_pressed)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.custom_minimum_size = Vector2(148, 45)


	send_btn.pressed.connect(_on_send_btn_pressed)
	chat_input.text_submitted.connect(_on_chat_input_submitted)


	if MailManager.instance:
		MailManager.instance.unread_count_changed.connect(_on_mail_unread_count_changed)

func set_game_manager(manager):
	var old_manager = game_manager
	if old_manager and old_manager.chat_network and old_manager.chat_network.message_send_failed.is_connected(_on_chat_send_failed):
		old_manager.chat_network.message_send_failed.disconnect(_on_chat_send_failed)
	game_manager = manager
	_warned_null_gm = false
	if game_manager:
		if game_manager.world_announcement.is_connected(_on_world_announcement):
			game_manager.world_announcement.disconnect(_on_world_announcement)
		game_manager.world_announcement.connect(_on_world_announcement)

		if game_manager.chat_message_received.is_connected(_on_chat_msg_received):
			game_manager.chat_message_received.disconnect(_on_chat_msg_received)
		game_manager.chat_message_received.connect(_on_chat_msg_received)
		if game_manager.chat_network and not game_manager.chat_network.message_send_failed.is_connected(_on_chat_send_failed):
			game_manager.chat_network.message_send_failed.connect(_on_chat_send_failed)
		call_deferred("_refresh_signin7_entry")
		call_deferred("_refresh_shengsi_tower_entry")

func _show_content(content: Control, navigation_tag: String = ""):
	print("[CityUI] _show_content called, content=", content, ", content_container=", content_container)

	if not content_container:
		push_warning("[CityUI] _show_content called but content_container is null")
		return

	if not is_instance_valid(content_container):
		push_warning("[CityUI] _show_content called but content_container is not valid")
		return

	if current_content and is_instance_valid(current_content):
		if bool(current_content.get_meta("cacheable", false)):
			current_content.visible = false
		else:
			print("[CityUI] freeing current_content: ", current_content.name)
			current_content.queue_free()

	current_content = content
	print("[CityUI] adding content to content_container...")
	content_container.add_child(content)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)

	content.visible = true

	if feature_panel:
		feature_panel.visible = false
	elif grid_container:
		grid_container.visible = false
	if home_gap_spacer:
		home_gap_spacer.visible = false
	chat_panel.visible = false
	# 进功能页时面板被强制收起，遮罩必须跟着撤，否则它会吃掉页面上的所有点击
	if _chat_dismiss_layer != null and is_instance_valid(_chat_dismiss_layer):
		_chat_dismiss_layer.visible = false
	content_container.visible = true
	content_container.mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn.visible = true
	if _ink != null and is_instance_valid(_ink):
		_ink.set_ui_visible(false)
		# 功能页是全屏不透明面板，主城的环境动效（云 / 瀑布 / 人群 / 仙鹤 / 雾）
		# 一点都看不到却还在逐帧模拟，是手机上最大的那笔无效开销；顺带也杜绝
		# 装饰的 z_index 压到页面上。回主城时在 _hide_content 里恢复。
		_ink.set_ambient_active(false)
	# 底板垫在主城下面（主城已隐藏），给内页一个"还在城里"的静态景深。
	if _backdrop != null and is_instance_valid(_backdrop):
		_backdrop.open_for(navigation_tag)
	if _signin7_wrap:
		_signin7_wrap.visible = false
	if _signin7_dot:
		_signin7_dot.visible = false
	if _shengsi_tower_wrap:
		_shengsi_tower_wrap.visible = false
	print("[CityUI] _show_content completed")







func _show_cached_content(cache_key: String, builder: Callable):
	if game_manager and game_manager.has_method("local_feature_action") and cache_key in ["warehouse", "qiankun", "forge_main", "martial", "ranking", "signin7", "gang_hall"]:
		_show_content(load("res://dev/local_feature_ui.gd").create_fullscreen(game_manager, cache_key), "city:local_" + cache_key)
		return
	if not builder.is_valid():
		return
	if not content_container or not is_instance_valid(content_container):
		return

	var target: Control = null
	if content_cache.has(cache_key):
		var cached = content_cache[cache_key]
		if is_instance_valid(cached) and cached is Control:
			target = cached
		else:
			content_cache.erase(cache_key)

	var was_cached: = target != null
	if target == null:
		target = builder.call()
		if target == null:
			return
		if not (target is Control):
			push_warning("[CityUI] 缓存页构建失败：%s 不是 Control，已忽略本次切换" % cache_key)
			return
		target.set_meta("cacheable", true)
		content_cache[cache_key] = target

	_show_content(target, "city:%s" % cache_key)
	if was_cached and cache_key == "signin7" and target.has_method("on_feature_shown"):
		target.on_feature_shown(game_manager)

func reset_for_show() -> void :
	_hide_content()
	_active_chat_channel = "world"
	_active_chat_gang_id = 0
	_apply_chat_channel_ui("world")
	if game_manager and game_manager.chat_network:
		game_manager.chat_network.set_world_channel()
	if MailManager.instance:
		_update_mail_unread_label(MailManager.instance.unread_count)

func clear_content_cache_on_logout() -> void :
	clear_world_feed_display()
	_clear_content_cache()

func _clear_content_cache() -> void :
	for key in content_cache.keys():
		var cached = content_cache[key]
		if is_instance_valid(cached) and cached is Control:
			cached.queue_free()
	content_cache.clear()
	if xianmo_panel and is_instance_valid(xianmo_panel):
		xianmo_panel.queue_free()
		xianmo_panel = null
	current_content = null

func _announcement_text_fingerprint(message: String) -> String:
	return str(message).strip_edges()

func _announcement_feed_key(message: String) -> String:
	var fp: = _announcement_text_fingerprint(message)
	if fp.is_empty():
		return ""
	return "t:%s" % fp

func _feed_message_key(msg_data: Dictionary) -> String:
	var bid: = int(msg_data.get("broadcast_id", 0))
	if bid > 0:
		return "b:%d" % bid
	var mid: = int(msg_data.get("id", 0))
	if mid > 0:
		return "m:%d" % mid
	var pn: = str(msg_data.get("player_name", msg_data.get("sender", "")))
	var ms: = str(msg_data.get("message", ""))
	var ev: = str(msg_data.get("event_type", "chat"))
	return "f:%s|%s|%s" % [ev, pn, ms]

func sync_cached_messages(messages: Array) -> void :
	if chat_content == null or not is_instance_valid(chat_content):
		return
	var pending: Array = []
	for msg in messages:
		if not msg is Dictionary:
			continue
		if not _message_matches_active_channel(msg as Dictionary):
			continue
		var key: = _feed_message_key(msg)
		if _displayed_feed_keys.has(key):
			continue
		var ev: = str((msg as Dictionary).get("event_type", "chat"))
		if ev != "chat" and ev != "announcement":
			var text_key: = _announcement_feed_key(str((msg as Dictionary).get("message", "")))
			if not text_key.is_empty() and _displayed_feed_keys.has(text_key):
				continue
		pending.append(msg)
	if pending.is_empty():
		if chat_content.get_child_count() > 0:
			_scroll_chat_to_bottom_deferred()
		return
	var immediate_count: = mini(CHAT_INITIAL_DISPLAY_COUNT, pending.size())
	for i in range(immediate_count):
		_render_cached_message_row(pending[i])
	if immediate_count < pending.size():
		_chat_batch_pending.append_array(pending.slice(immediate_count))
		_start_chat_batch_if_needed()
	else:
		_scroll_chat_to_bottom_deferred()

func _render_cached_message_row(msg_data: Dictionary) -> void :
	# 历史回放也喂预览：进主城时光是公告就能先滚出来，不用等新消息
	_push_chat_preview(msg_data)
	var key: = _feed_message_key(msg_data)
	if _displayed_feed_keys.has(key):
		return
	var event_type: = str(msg_data.get("event_type", "chat"))
	var message: = str(msg_data.get("message", ""))
	if event_type != "chat" and event_type != "announcement":
		var text_key: = _announcement_feed_key(message)
		if not text_key.is_empty() and _displayed_feed_keys.has(text_key):
			return
	_displayed_feed_keys[key] = true
	display_cached_message(msg_data)

func _start_chat_batch_if_needed() -> void :
	if _chat_batch_running or _chat_batch_pending.is_empty():
		return
	_chat_batch_running = true
	call_deferred("_process_chat_batch_step")

func _process_chat_batch_step() -> void :
	if _chat_batch_pending.is_empty():
		_chat_batch_running = false
		_scroll_chat_to_bottom_deferred()
		return
	var batch: = mini(CHAT_DEFERRED_BATCH_SIZE, _chat_batch_pending.size())
	for _i in range(batch):
		_render_cached_message_row(_chat_batch_pending.pop_front())
	if _chat_batch_pending.is_empty():
		_chat_batch_running = false
		_scroll_chat_to_bottom_deferred()
	else:
		call_deferred("_process_chat_batch_step")

func _scroll_chat_to_bottom_deferred() -> void :
	call_deferred("_scroll_chat_to_bottom")

func _apply_chat_scroll_to_bottom() -> void :
	if chat_scroll == null or not is_instance_valid(chat_scroll):
		return
	var bar: VScrollBar = chat_scroll.get_v_scroll_bar()
	if bar != null:
		chat_scroll.scroll_vertical = int(bar.max_value)

func _scroll_chat_to_bottom() -> void :
	if chat_scroll == null or not is_instance_valid(chat_scroll):
		return

	for _i in range(3):
		await get_tree().process_frame
		if chat_scroll == null or not is_instance_valid(chat_scroll):
			return
		_apply_chat_scroll_to_bottom()
	call_deferred("_apply_chat_scroll_to_bottom")

	get_tree().create_timer(0.05).timeout.connect(_apply_chat_scroll_to_bottom, CONNECT_ONE_SHOT)

func _hide_content():
	if current_content:
		if bool(current_content.get_meta("cacheable", false)):
			current_content.visible = false
		else:
			current_content.queue_free()
		current_content = null

	if feature_panel:
		feature_panel.visible = not INK_UI
	elif grid_container:
		grid_container.visible = not INK_UI
	if home_gap_spacer:
		home_gap_spacer.visible = true
	chat_panel.visible = _chat_open
	content_container.visible = false
	content_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_btn.visible = false
	if _ink != null and is_instance_valid(_ink):
		_ink.set_ui_visible(true)
		_ink.set_ambient_active(true)
		# set_ui_visible(true) 会把所有带 ink_pos 的节点一起显示，
		# 聊天面板是否可见由玩家上次的开合状态决定，所以放在它之后收口。
		_ink_restore_chat()
	if _backdrop != null and is_instance_valid(_backdrop):
		_backdrop.close()

	if _feature_expand_btn != null:
		_apply_feature_fold_state(true)
	_apply_signin7_entry()
	_apply_red_dots()
	_refresh_signin7_entry()
	_refresh_shengsi_tower_entry()

func show_content(content: Control, navigation_tag: String = ""):
	_show_content(content, navigation_tag)

func on_back_btn_pressed():
	_on_back_btn_pressed()

func _on_back_btn_pressed():
	_hide_content()

	if game_manager:
		game_manager.play_bgm_normal()

func _on_ranking_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "ranking"})
	game_manager.play_bgm_ranking_hall()
	_show_cached_content("ranking", func(): return _call_script_static(SCRIPT_RANKING_HALL, "create_fullscreen", [game_manager]))

func on_tower_btn_pressed(target_floor: int = -1):
	if not _require_game_manager():
		return
	if game_manager.player == null:
		add_announcement("玩家数据未加载，请稍后再试")
		return
	game_manager.play_bgm_tower()

	if content_cache.has("tower"):
		var cached = content_cache.get("tower")
		if is_instance_valid(cached) and cached is Control:
			cached.queue_free()
		content_cache.erase("tower")
	_show_cached_content("tower", func():
		var script_res: GDScript = load(TOWER_HUB_UI_SCRIPT_PATH) as GDScript
		if script_res == null:
			push_error("[CityUI] 天关脚本加载失败: %s" % TOWER_HUB_UI_SCRIPT_PATH)
			add_announcement("天关界面加载失败，请重启游戏后再试")
			return null
		var panel: Control = script_res.call("create_fullscreen", game_manager, target_floor) as Control
		if panel == null:
			push_error("[CityUI] 天关面板创建返回空")
			add_announcement("天关界面创建失败，请重启游戏后再试")
			return null
		return panel
	)


func _on_tower_btn_pressed():
	on_tower_btn_pressed()

func on_suit_dungeon_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.play_bgm_suit_dungeon()
	var had_cache: = content_cache.has("dungeon_hub") and is_instance_valid(content_cache.get("dungeon_hub"))
	_show_cached_content("dungeon_hub", func(): return _call_script_static(SCRIPT_DUNGEON_HUB_UI, "create_fullscreen", [game_manager]))
	if had_cache:
		refresh_suit_dungeon_hub()

func refresh_suit_dungeon_hub() -> void :
	if game_manager == null:
		return
	var hub = content_cache.get("dungeon_hub")
	if hub == null or not is_instance_valid(hub):
		return
	var suit_content: = hub.find_child("suit_content", true, false) as Control
	if suit_content:
		_call_script_static(SCRIPT_SUIT_DUNGEON_UI, "refresh_panel", [game_manager, suit_content])

func _on_martial_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "martial"})
	game_manager.play_bgm_martial_hall()
	_show_cached_content("martial", func(): return _call_script_static(SCRIPT_MARTIAL_HALL, "create_fullscreen", [game_manager]))

func _on_crafting_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "crafting"})
	game_manager.play_bgm_qiankun_hall()
	_show_cached_content("qiankun", func(): return _call_script_static(SCRIPT_QIANKUN_HALL, "create_fullscreen", [game_manager]))

func _on_pet_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "pet_park"})
	game_manager.play_bgm_pet_park()
	_show_cached_content("pet_park", func(): return _call_script_static(SCRIPT_PET_PARK, "create_fullscreen", [game_manager]))

func _on_shop_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "shop"})
	game_manager.play_bgm_shop()
	_show_cached_content("shop", func(): return _call_script_static(SCRIPT_SHOP_UI, "create_fullscreen", [game_manager]))

func _on_lucky_draw_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "lucky_draw"})
	game_manager.play_bgm_lucky_draw()
	_show_cached_content("lucky_draw", func(): return _build_lucky_draw_content())

func _setup_signin7_entry() -> void :
	if _signin7_wrap != null and is_instance_valid(_signin7_wrap):
		return
	var wrap: = Control.new()
	wrap.name = "Signin7Entry"
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.custom_minimum_size = Vector2(96, 96)
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.anchor_left = 1.0
	wrap.anchor_right = 1.0
	wrap.anchor_top = 0.0
	wrap.anchor_bottom = 0.0

	wrap.offset_left = -222.0
	wrap.offset_right = -122.0
	wrap.offset_top = 86.0
	wrap.offset_bottom = 182.0
	wrap.visible = false
	add_child(wrap)
	_signin7_wrap = wrap
	var tex: = _load_city_png_texture(SIGNIN7_ICON_PATH)
	var btn: = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true
	btn.text = ""
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 0
	btn.offset_top = 0
	btn.offset_right = 0
	btn.offset_bottom = 0
	var icon_node: Control = null
	if tex:
		var icon: = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = tex
		wrap.add_child(icon)
		icon_node = icon
	else:
		btn.text = "签到"
	TouchScrollUtils.bind_tap(btn, _on_signin7_pressed)
	wrap.add_child(btn)
	_ink_bind_press_with(btn, icon_node)
	var dot := TextureRect.new()
	dot.name = "SigninDot"
	dot.texture = _get_dot_tex()
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_SCALE
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.anchor_left = 1.0
	dot.anchor_right = 1.0
	dot.offset_left = -26.0
	dot.offset_right = -2.0
	dot.offset_top = 2.0
	dot.offset_bottom = 26.0
	dot.visible = false
	wrap.add_child(dot)
	_signin7_dot = dot

func _on_signin7_pressed() -> void :
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "signin7"})
	_show_cached_content("signin7", func(): return _call_script_static(SCRIPT_SIGNIN7_UI, "create_fullscreen", [game_manager]))

## 七日签到是常驻入口：登录后一直挂在主城左上角，只有「进功能页」时才收起。
## 之前是按服务端返回的 show_entry 决定显隐，而这个值是异步回来的——
## 于是从功能页返回时，节点先被 set_ui_visible(true) 打开、0.2 秒后又被关掉，
## 看起来就是「闪一下就没了」。现在显隐只跟登录态/是否在看功能页有关。
func _apply_signin7_entry() -> void :
	if _signin7_wrap == null or not is_instance_valid(_signin7_wrap):
		return
	var has_content := current_content != null and is_instance_valid(current_content)
	_signin7_wrap.visible = _signin7_logged_in and not has_content
	if _signin7_dot != null and is_instance_valid(_signin7_dot):
		_signin7_dot.visible = _signin7_wrap.visible and _signin7_can_claim

func _refresh_signin7_entry() -> void :
	if _signin7_wrap == null or not is_instance_valid(_signin7_wrap):
		return
	if not _require_game_manager() or game_manager.network == null or not game_manager.network.is_logged_in():
		_signin7_logged_in = false
		_apply_signin7_entry()
		return
	_signin7_logged_in = true
	_apply_signin7_entry()
	if _signin7_refreshing:
		return
	_signin7_refreshing = true
	var res: Dictionary = await game_manager.network.signin7_info()
	_signin7_refreshing = false
	if not is_instance_valid(_signin7_wrap):
		return
	if bool(res.get("ok", false)):
		var data: Dictionary = res.get("data", {}) if res.get("data") is Dictionary else {}
		_signin7_can_claim = bool(data.get("can_claim", false))
	else:
		_signin7_can_claim = false
	_apply_signin7_entry()
	_apply_red_dots()

func _build_lucky_draw_content() -> Control:
	var script_res: Resource = load(LUCKY_DRAW_UI_SCRIPT_PATH)
	if script_res == null:
		push_warning("[CityUI] LuckyDrawUI 脚本加载失败：%s" % LUCKY_DRAW_UI_SCRIPT_PATH)
		return null
	if script_res is Script:
		if script_res.has_method("create_fullscreen"):
			var created: Variant = script_res.call("create_fullscreen", game_manager)
			if created is Control:
				return created
		if script_res.can_instantiate():
			var ui = script_res.new()
			if ui and ui.has_method("set_game_manager"):
				ui.call("set_game_manager", game_manager)
			if ui is Control:
				ui.set_anchors_preset(Control.PRESET_FULL_RECT)
				ui.offset_left = 0
				ui.offset_top = 0
				ui.offset_right = 0
				ui.offset_bottom = 0
				return ui
	push_warning("[CityUI] LuckyDrawUI 创建失败：脚本不可实例化或返回类型不是 Control")
	return null

func _on_warehouse_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "warehouse"})
	game_manager.play_bgm_warehouse()
	_show_cached_content("warehouse", func(): return _call_script_static(SCRIPT_WAREHOUSE_UI, "create_fullscreen", [game_manager]))

func _on_settings_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "settings"})
	game_manager.play_bgm_settings()
	_show_cached_content("settings", func(): return _call_script_static(SCRIPT_SETTINGS_HALL, "create_fullscreen", [game_manager]))

func _on_quest_btn_pressed():
	show_arena_hub_world_boss(false)

func show_arena_hub_world_boss(refresh_only: bool = false) -> void :
	if not _require_game_manager():
		return
	if not refresh_only:
		game_manager.track_event("feature_open", {"feature": "arena"})
		game_manager.play_bgm_quest()
	_show_cached_content("arena_hub", func():
		return _call_script_static(SCRIPT_ARENA_HUB_UI, "create_fullscreen", [game_manager])
	)
	_switch_arena_hub_to_world_boss()

func show_arena_hub_arena(refresh_only: bool = false) -> void :
	if not _require_game_manager():
		return
	if not refresh_only:
		game_manager.track_event("feature_open", {"feature": "arena_tab"})
		game_manager.play_bgm_quest()
	_show_cached_content("arena_hub", func():
		return _call_script_static(SCRIPT_ARENA_HUB_UI, "create_fullscreen", [game_manager])
	)
	_switch_arena_hub_to_arena(refresh_only)

func show_gang_hall(refresh_only: bool = false, focus_kick_tab: bool = false) -> void :
	if not _require_game_manager():
		return
	if not refresh_only:
		game_manager.track_event("feature_open", {"feature": "gang"})
		game_manager.play_bgm_normal()
	_show_cached_content("gang_hall", func(): return _call_script_static(SCRIPT_GANG_HALL, "create_fullscreen", [game_manager]))
	if focus_kick_tab:
		_focus_gang_hall_kick_tab(refresh_only)
	if content_container and is_instance_valid(content_container) and content_container.visible:
		if current_content == null or not is_instance_valid(current_content):
			reset_for_show()

func show_gang_siege(refresh_only: bool = true, territory_id: String = "") -> void :
	if not _require_game_manager():
		return
	if not refresh_only:
		game_manager.track_event("feature_open", {"feature": "gang"})
		game_manager.play_bgm_normal()
	_show_cached_content("gang_hall", func(): return _call_script_static(SCRIPT_GANG_HALL, "create_fullscreen", [game_manager]))
	_focus_gang_hall_war_tab(refresh_only, territory_id)
	if content_container and is_instance_valid(content_container) and content_container.visible:
		if current_content == null or not is_instance_valid(current_content):
			reset_for_show()

func _focus_gang_hall_war_tab(refresh_only: bool, territory_id: String) -> void :
	var hall = content_cache.get("gang_hall")
	if hall == null or not is_instance_valid(hall):
		return
	if hall.has_method("focus_war_tab"):
		hall.call("focus_war_tab", refresh_only, territory_id)

func _focus_gang_hall_kick_tab(refresh_only: bool) -> void :
	var hall = content_cache.get("gang_hall")
	if hall == null or not is_instance_valid(hall):
		return
	if hall.has_method("focus_others_tab"):
		hall.call("focus_others_tab", refresh_only)

func _switch_arena_hub_to_arena(refresh_only: bool = false) -> void :
	var hub = content_cache.get("arena_hub")
	if hub == null or not is_instance_valid(hub):
		return
	var switch_fn: Variant = hub.get_meta("switch_arena_tab", null)
	if switch_fn is Callable:
		switch_fn.call(1)
		return
	var arena_content: = hub.find_child("arena_content", true, false) as Control
	if arena_content != null and game_manager.has_method("refresh_arena_ui_panel"):
		game_manager.refresh_arena_ui_panel(arena_content)

func _switch_arena_hub_to_world_boss() -> void :
	var hub = content_cache.get("arena_hub")
	if hub == null or not is_instance_valid(hub):
		return
	var switch_fn: Variant = hub.get_meta("switch_arena_tab", null)
	if switch_fn is Callable:
		switch_fn.call(0)
		return
	var wb_content: = hub.find_child("world_boss_content", true, false) as Control
	if wb_content != null and game_manager.has_method("refresh_world_boss_ui_panel"):
		game_manager.refresh_world_boss_ui_panel(wb_content)

func _on_quest_teleport_to_battle():
	_hide_content()
	city_closed.emit()

func _on_more_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "gang"})
	_show_cached_content("gang_hall", func(): return _call_script_static(SCRIPT_GANG_HALL, "create_fullscreen", [game_manager]))

func _on_xianmo_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "xianmo"})

	if not content_container:
		push_warning("[CityUI] _on_xianmo_btn_pressed called but content_container is null")
		return

	var content = XianMoMain.instantiate()
	if not content:
		push_warning("[CityUI] Failed to instantiate XianMoMain")
		return

	if content.has_method("set_game_manager"):
		content.call("set_game_manager", game_manager)
	else:
		push_error("[CityUI] XianMoMain 根节点未挂载含 set_game_manager 的脚本")
		return
	content.connect("back_pressed", _on_back_btn_pressed)
	xianmo_panel = content
	_show_content(content, "city:xianmo")

func _on_treasure_cave_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "treasure_cave"})
	_show_cached_content("treasure_cave", func(): return _call_script_static(SCRIPT_TREASURE_CAVE_UI, "create_fullscreen", [game_manager]))

func _load_city_png_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded: = load(path) as Texture2D
		if loaded != null:
			return loaded
	if FileAccess.file_exists(path):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _ensure_shengsi_tower_float_btn() -> void :
	if _shengsi_tower_wrap and is_instance_valid(_shengsi_tower_wrap):
		return
	var wrap: = Control.new()
	wrap.name = "ShengsiTowerEntry"
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.custom_minimum_size = Vector2(96, 96)
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.anchor_left = 1.0
	wrap.anchor_right = 1.0
	wrap.anchor_top = 0.0
	wrap.anchor_bottom = 0.0

	wrap.offset_left = -110.0
	wrap.offset_right = -10.0
	wrap.offset_top = 86.0
	wrap.offset_bottom = 182.0
	wrap.z_index = 20
	add_child(wrap)
	_shengsi_tower_wrap = wrap
	var tex: = _load_city_png_texture(SHENGSI_ICON_PATH)
	var btn: = Button.new()
	btn.name = "ShengsiTowerFloatBtn"
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true
	btn.text = ""
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.offset_left = 0
	btn.offset_top = 0
	btn.offset_right = 0
	btn.offset_bottom = 0
	if tex:
		var icon: = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = tex
		wrap.add_child(icon)
	else:
		btn.text = "生死塔"
	TouchScrollUtils.bind_tap(btn, _on_shengsi_tower_btn_pressed)
	wrap.add_child(btn)
	_shengsi_tower_btn = btn

func _refresh_shengsi_tower_entry() -> void :
	if _shengsi_tower_wrap == null or not is_instance_valid(_shengsi_tower_wrap):
		return
	var in_sub: = current_content != null and is_instance_valid(current_content)
	_shengsi_tower_wrap.visible = not in_sub

func _on_shengsi_tower_btn_pressed() -> void :
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "shengsi_tower"})
	_show_cached_content("shengsi_tower", func(): return _call_script_static(SCRIPT_SHENGSI_TOWER_UI, "create_fullscreen", [game_manager]))

func show_xianmo_panel():
	if xianmo_panel and is_instance_valid(xianmo_panel):
		xianmo_panel.show()
		xianmo_panel.update_ui()
		return true
	return false

func _show_more_menu():
	var menu_panel = Panel.new()
	menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 50
	vbox.offset_top = 50
	vbox.offset_right = -50
	vbox.offset_bottom = -50
	vbox.add_theme_constant_override("separation", 15)
	menu_panel.add_child(vbox)

	var title = UIStyle.create_title_label("📋 更多功能")
	vbox.add_child(title)

	var empty_label = Label.new()
	empty_label.text = "暂无更多功能"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 18)
	empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(empty_label)

	var close_btn = _create_menu_button("✖️ 关闭", Color(0.5, 0.3, 0.3))
	close_btn.pressed.connect( func(): menu_panel.queue_free())
	vbox.add_child(close_btn)

	add_child(menu_panel)

func _create_menu_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 80)
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", normal_style)

	return btn



func _append_chat_message_ui(sender: String, message: String, msg_color: Color = Color(1, 1, 1), title: String = "", vip_level: int = 0, legacy_is_vip: bool = false) -> void :
	if chat_content == null or not is_instance_valid(chat_content):
		return
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.y = 20
	var color_hex: String = msg_color.to_html(false)
	var vip_tag: String = VipBenefits.chat_vip_prefix_bbcode(vip_level, legacy_is_vip)
	var normalized_title: = String(title).strip_edges()
	var vip_title: = "VIP%s" % str(vip_level)
	var show_title: = not normalized_title.is_empty()
	if show_title and vip_level > 0 and normalized_title.to_upper() == vip_title.to_upper():
		show_title = false
	var title_tag: String = "[color=#9B30FF][%s][/color] " % normalized_title if show_title else ""
	label.text = "%s%s[color=#%s][%s][/color] [color=#%s]%s[/color]" % [vip_tag, title_tag, color_hex, sender, color_hex, message]
	label.add_theme_font_size_override("normal_font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_content.add_child(label)

func add_chat_message(sender: String, message: String, msg_color: Color = Color(1, 1, 1), title: String = "", vip_level: int = 0, legacy_is_vip: bool = false):
	_append_chat_message_ui(sender, message, msg_color, title, vip_level, legacy_is_vip)
	await get_tree().process_frame
	_scroll_chat_to_bottom()

func add_announcement(message: String):
	if _append_announcement_ui(message):
		_scroll_chat_to_bottom_deferred()

func _highlight_all_player_names(message: String) -> String:
	var result = message
	var regex: RegEx = RegEx.new()
	regex.compile("【([^】]+)】")
	result = regex.sub(result, "[color=#FFD700]【$1】[/color]", true)
	regex.compile("「([^」]+)」")
	result = regex.sub(result, "[color=#FFD700]「$1」[/color]", true)
	regex.compile("(?<!\\[color=)\\[([^\\]]+)\\](?!\\[/color\\])")
	result = regex.sub(result, "[color=#FFD700][$1][/color]", true)
	regex.compile("(\\d+)(?=连胜)")
	result = regex.sub(result, "[color=#FFD700]$1[/color]", true)
	return result

func _on_send_btn_pressed():
	_send_chat_message()

func _on_chat_input_submitted(text: String):
	_send_chat_message()

func _send_chat_message():
	var text = chat_input.text.strip_edges()
	if text.is_empty():
		return

	var player_name = "修仙者"
	var title = ""
	if game_manager and game_manager.player:
		player_name = game_manager.player.player_name
		title = game_manager.player.get_active_title_name()

	var is_vip = game_manager and game_manager.player and game_manager.player.is_vip
	var vip_level: = 0
	if game_manager and game_manager.player and is_vip:
		vip_level = clampi(int(game_manager.player.vip_level), 0, 3)
	_last_failed_message = text
	chat_input.clear()
	if game_manager and game_manager.chat_network:
		game_manager.chat_network.send_message(player_name, text, "chat", is_vip, title, vip_level)
	else:
		add_announcement("聊天发送失败：聊天服务未就绪")
		if not _last_failed_message.is_empty():
			chat_input.text = _last_failed_message

func _on_chat_send_failed(error_code: int, error_message: String, payload: Dictionary) -> void :
	var raw_reason: = String(error_message).strip_edges()
	var msg: = "聊天发送失败"
	if error_code == 401 or error_code == 403:
		msg = "聊天发送失败：登录状态失效，请重新登录"
	elif raw_reason == "聊天鉴权配置缺失":
		msg = "聊天发送失败：聊天服务鉴权配置缺失"
	elif error_code == 429 or raw_reason == "too-fast":
		# 服务端防刷屏：1.5 秒内连发会被拒，别把 "too-fast" 这种内部代号甩给玩家
		msg = "聊天发送失败：发言太频繁，缓一缓再发"
	elif raw_reason == "数据库错误":
		msg = "聊天发送失败：聊天服务数据库异常"
	elif raw_reason == "server-stub":
		# 旧版服务端的聊天接口是空桩（收到就回成功但不存），升级服务端前必然走到这里
		msg = "聊天发送失败：服务端聊天功能未更新，请联系管理员部署新版服务端"
	elif raw_reason == "请先登录" or raw_reason == "登录已过期" or raw_reason == "登录信息无效":
		msg = "聊天发送失败：登录状态失效，请重新登录"
	elif not raw_reason.is_empty() and not raw_reason.begins_with("http_") and not raw_reason.begins_with("network_result_"):
		msg = "聊天发送失败：%s" % raw_reason
	elif error_code >= 500:
		msg = "聊天发送失败：服务器繁忙，请稍后重试"
	elif error_code == 0:
		msg = "聊天发送失败：网络连接异常"
	var now_ts: float = Time.get_unix_time_from_system()

	if msg != _last_send_error_text or now_ts - _last_send_error_time >= 2.0:
		add_announcement(msg)
		_last_send_error_text = msg
		_last_send_error_time = now_ts
	if _last_failed_message.is_empty():
		_last_failed_message = String(payload.get("message", "")).strip_edges()
	if not _last_failed_message.is_empty() and chat_input.text.strip_edges().is_empty():
		chat_input.text = _last_failed_message



func _on_world_announcement(message: String):
	if _active_chat_channel != "world":
		return
	var text_key: = _announcement_feed_key(message)
	if not text_key.is_empty() and _displayed_feed_keys.has(text_key):
		return
	add_announcement(message)

func _on_chat_msg_received(msg_data: Dictionary):
	# 预览只认世界频道，放在频道过滤之前喂，切到帮派频道时世界消息也不会漏
	_push_chat_preview(msg_data)
	if not _message_matches_active_channel(msg_data):
		return
	var feed_key: = _feed_message_key(msg_data)
	if _displayed_feed_keys.has(feed_key):
		return
	var event_type = msg_data.get("event_type", "chat")
	var player_name = msg_data.get("sender", msg_data.get("player_name", "修仙者"))
	var message = msg_data.get("message", "")
	if event_type != "chat" and event_type != "announcement":
		var text_key: = _announcement_feed_key(message)
		if not text_key.is_empty() and _displayed_feed_keys.has(text_key):
			return
	_displayed_feed_keys[feed_key] = true
	var is_vip = bool(msg_data.get("is_vip", false))
	var vip_level: = clampi(int(msg_data.get("vip_level", 0)), 0, 3)
	var legacy_vip: = vip_level < 1 and is_vip
	var title = msg_data.get("title", "")

	if event_type == "chat":
		var is_self = game_manager and game_manager.player and player_name == game_manager.player.player_name
		if is_self:
			_last_failed_message = ""
		var msg_color = Color(0.4, 0.9, 0.4) if is_self else Color(0.6, 0.8, 1.0)
		add_chat_message(player_name, message, msg_color, title, vip_level, legacy_vip)
	elif event_type == "announcement":
		add_chat_message(player_name, message, Color(1, 0, 0), title, 0, false)
	else:
		add_announcement(message)


func clear_world_feed_display() -> void :
	_clear_chat_display()

func display_cached_messages(messages: Array):
	sync_cached_messages(messages)

func display_cached_message(msg_data: Dictionary):
	var event_type = msg_data.get("event_type", "chat")
	var player_name = msg_data.get("sender", msg_data.get("player_name", "修仙者"))
	var message = msg_data.get("message", "")
	var is_vip = bool(msg_data.get("is_vip", false))
	var vip_level: = clampi(int(msg_data.get("vip_level", 0)), 0, 3)
	var legacy_vip: = vip_level < 1 and is_vip
	var title = msg_data.get("title", "")

	if event_type == "chat":
		var is_self = game_manager and game_manager.player and player_name == game_manager.player.player_name
		var msg_color = Color(0.4, 0.9, 0.4) if is_self else Color(0.6, 0.8, 1.0)
		_append_chat_message_ui(player_name, message, msg_color, title, vip_level, legacy_vip)
	elif event_type == "announcement":
		_append_chat_message_ui(player_name, message, Color(1, 0, 0), title, 0, false)
	else:
		_append_announcement_ui(message)

func _append_announcement_ui(message: String) -> bool:
	var text_key: = _announcement_feed_key(message)
	if text_key.is_empty():
		return false
	if _displayed_feed_keys.has(text_key):
		return false
	var key: = _announcement_text_fingerprint(message)
	var now_ts: float = Time.get_unix_time_from_system()
	var prev_ts: float = float(_recent_announcement_at.get(key, 0.0))
	if prev_ts > 0.0 and now_ts - prev_ts <= ANNOUNCEMENT_DEDUP_WINDOW_SEC:
		return false
	_recent_announcement_at[key] = now_ts
	if _recent_announcement_at.size() > 300:
		_recent_announcement_at.clear()
	if chat_content == null or not is_instance_valid(chat_content):
		return false
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.y = 20
	var colored_message = _highlight_all_player_names(message)
	colored_message = colored_message.replace("\n", "[br]")
	label.text = "📢 " + colored_message
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_color_override("default_color", Color(1, 0.5, 0.3))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_content.add_child(label)
	_displayed_feed_keys[text_key] = true
	return true

func show_fly_announcement(player_name: String):
	add_announcement("恭喜玩家【%s】成功飞升仙界！" % player_name)

func show_pet_evolve_announcement(player_name: String, pet_name: String):
	add_announcement("恭喜玩家【%s】的宠物【%s】成功进化！" % [player_name, pet_name])

func show_pet_merge_announcement(player_name: String, pet_name: String):
	add_announcement("恭喜玩家【%s】的宠物【%s】完成幻化！" % [player_name, pet_name])



func _on_mail_btn_pressed():
	_show_mail_ui()

func _on_mail_unread_count_changed(count: int):

	_update_mail_unread_label(count)

func _update_mail_unread_label(count: int):
	if mail_unread_label:
		mail_unread_label.visible = count > 0
		mail_unread_label.text = str(count)

func _show_mail_ui():
	if game_manager and game_manager.has_method("local_feature_action"):
		_show_content(load("res://dev/local_feature_ui.gd").create_fullscreen(game_manager, "mail"), "city:local_mail")
		return
	if not _require_game_manager():
		return
	game_manager.play_bgm_mail()
	var mail_ui = preload("res://ui/mail/mail_ui.tscn").instantiate()
	if mail_ui.has_method("set_game_manager"):
		mail_ui.call("set_game_manager", game_manager)
	_show_content(mail_ui, "city:mail")

func _add_forge_button():
	if not grid_container:
		return
	var forge_btn = Button.new()
	forge_btn.name = "ForgeBtn"
	forge_btn.text = "打造坊"
	forge_btn.focus_mode = Control.FOCUS_NONE
	forge_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	forge_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	forge_btn.add_theme_font_size_override("font_size", 22)
	_apply_feature_button_style(forge_btn)
	forge_btn.pressed.connect(_on_forge_btn_pressed)
	grid_container.add_child(forge_btn)
	_forge_btn = forge_btn

func _on_forge_btn_pressed():
	if not _require_game_manager():
		return
	game_manager.track_event("feature_open", {"feature": "forge"})
	game_manager.play_bgm_forge_hall()
	_show_cached_content("forge_main", func(): return _call_script_static(SCRIPT_CRAFTING_MAIN_UI, "create_fullscreen", [game_manager]))


# =====================================================================
#  水墨主城（INK_UI）
#  设计坐标 1024×1536，换算全部交给 CityInkLayer。
#  Button 只当「命中框」用（全透明 stylebox），视觉是子节点 Art(TextureRect)，
#  这样按钮尺寸能精确等于设计值，不会被 StyleBoxTexture 的最小尺寸顶大。
# =====================================================================
	
const INK_CHAT_W := 1000.0       # 设计像素（1024 宽设计稿里几乎占满，只留 INK_EDGE 边距）
const INK_CHAT_H := 1060.0       # 700×330 那版在手机上只有半屏宽、太挤，按用户红线放大到近全宽大半屏
## 喇叭底边距底栏顶：原来 14 设计 px，在 iOS「添加到主屏幕」（414×852、逻辑视口
## 720×1482）上只剩 9 个逻辑像素，圆盘压进底栏渐隐区里，看着像被按钮条切掉半截。
## 底栏图 dock_bar.png 是 208 设计高、但 BottomNav 面板只有 140 逻辑高，
## 视觉顶比 panel 顶又高出约 6 逻辑像素，两边一挤就贴住了。给到 72 才真正留出空隙。
const INK_CHAT_GAP := 72.0
const INK_HORN_D := 104.0        # = 88 设计直径的圆盘 + 9% 柔光边
const INK_EDGE := 12.0           # 距内容区左边
const INK_CHAT_BOTTOM_PAD := 8.0 # 面板底边距内容区底：几乎贴住底栏，面板盖住喇叭
## 收起态的世界频道预览：条数、行高、由新到旧的透明度
const INK_PREVIEW_COUNT := 5
const INK_PREVIEW_LINE_H := 40.0
const INK_PREVIEW_W := 780.0
const INK_PREVIEW_ALPHA := [1.0, 0.88, 0.76, 0.64, 0.52]

var _horn_btn: Button = null
var _chat_open := false
var _chat_tween: Tween = null
var _chat_close_btn: Button = null
var _chat_dismiss_layer: CanvasLayer = null   # 「点外部关闭」遮罩层
var _chat_dismiss_rects: Array = []           # 遮罩的 4 块矩形（顶/底/左/右）
var _chat_preview_box: VBoxContainer = null
var _chat_preview_msgs: Array = []
var _chat_preview_keys: Dictionary = {}
var _ink_bold_font: Font = null


## 聊天从「底部常驻」改成「左下角喇叭按钮 + 半透明水墨面板收放」。
## 面板贴着内容区底边往上弹，喇叭始终在面板左下方，再点一次收回。
## 收起时在喇叭上方滚出最近 5 条世界消息（无底框、越旧越淡），不漏消息。
func _ink_setup_chat() -> void:
	if chat_panel == null or not is_instance_valid(chat_panel):
		return
	_ink_prepare_chat_panel()
	_ink_make_chat_dismiss()
	_ink_make_chat_horn()
	_ink_make_chat_close()
	_ink_make_chat_preview()
	_ink_layout_chat()
	_ink_set_chat_open(false, true)
	# 切到战斗/角色/背包页时 CityView 整块 visible=false，但 CanvasLayer 不受父级
	# Control 可见性影响 —— 不手动收掉，遮罩会继续盖在其它页面上吃掉所有点击。
	if not visibility_changed.is_connected(_on_city_visibility_changed):
		visibility_changed.connect(_on_city_visibility_changed)


func _on_city_visibility_changed() -> void:
	if _chat_dismiss_layer == null or not is_instance_valid(_chat_dismiss_layer):
		return
	_chat_dismiss_layer.visible = _chat_open and is_visible_in_tree()


func _ink_prepare_chat_panel() -> void:
	if chat_panel.get_parent() != _ink:
		chat_panel.reparent(_ink)
	chat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	chat_panel.anchor_left = 0.0
	chat_panel.anchor_top = 0.0
	chat_panel.anchor_right = 0.0
	chat_panel.anchor_bottom = 0.0
	chat_panel.custom_minimum_size = Vector2.ZERO
	chat_panel.clip_contents = false
	# ① 半透明水墨底板（9 宫格：中间拉伸，四角花纹不糊）
	var sb := StyleBoxTexture.new()
	sb.texture = load(CityInkData.DIR + "chat_panel.png") as Texture2D
	sb.texture_margin_left = 30.0
	sb.texture_margin_top = 30.0
	sb.texture_margin_right = 30.0
	sb.texture_margin_bottom = 30.0
	chat_panel.add_theme_stylebox_override("panel", sb)

	# ①' 面板不透明度 ≈ 80%（用户要的「80% 透明」）：
	# chat_panel.png 中间区域 alpha 实测 0.82，九宫格直接铺就是 ~82% 不透明，
	# 背后主城隐约可见、字仍然压得住，不需要再叠任何实底。
	# 历史上这里垫过一层 alpha 1.0 的深色 veil 去压「人物剪影浮在面板上」，
	# 但那个问题的真因是 CityFx 人群的 z_index 高于面板（已由 z_index=3000 解决），
	# 实底只是把面板做成死黑。现在撤掉，并清掉可能残留的旧 veil 节点。
	var s: = _ink.s
	var stale_veil: = chat_panel.get_node_or_null("InkChatVeil")
	if stale_veil != null:
		stale_veil.queue_free()

	var vb: = chat_panel.get_node_or_null("VBoxContainer") as Control
	if vb:
		vb.offset_left = 18.0 * s
		vb.offset_right = -18.0 * s
		# 面板按用户红线放大到近半屏后，九宫格木框的 30 设计 px 边距会把
		# 「江湖传闻」标题压到边框线上，所以顶部让出边框的厚度
		vb.offset_top = 26.0 * s
		vb.offset_bottom = -12.0 * s

	# ② 标题行：换掉那张繁复的「江湖传闻」木框，改成水墨金字
	var title: = chat_panel.get_node_or_null("VBoxContainer/ChatHeader/ChatTitle") as CanvasItem
	if title:
		title.visible = false
	var header: = chat_panel.get_node_or_null("VBoxContainer/ChatHeader") as Control
	if header:
		header.custom_minimum_size = Vector2(0, 54.0 * s)
		var lab: = header.get_node_or_null("InkChatTitle") as Label
		# 标题原来贴着面板左内边距，视觉上顶到九宫格边框线上（用户反馈偏左），
		# 前面垫一个透明占位把它整体往右推一点点。
		var pad: = header.get_node_or_null("InkChatTitlePad") as Control
		if pad == null:
			pad = Control.new()
			pad.name = "InkChatTitlePad"
			pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header.add_child(pad)
			header.move_child(pad, 0)
		pad.custom_minimum_size = Vector2(16.0 * s, 0)
		if lab == null:
			lab = Label.new()
			lab.name = "InkChatTitle"
			header.add_child(lab)
			header.move_child(lab, 1)
		lab.text = "江 湖 传 闻"
		lab.add_theme_font_size_override("font_size", maxi(11, int(round(20.0 * s))))
		lab.add_theme_color_override("font_color", Color(0.925, 0.804, 0.518))
		lab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lab.add_theme_constant_override("shadow_offset_x", 1)
		lab.add_theme_constant_override("shadow_offset_y", 1)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sep: = chat_panel.get_node_or_null("VBoxContainer/ChatHeader/HSeparator") as Control
	if sep:
		sep.custom_minimum_size = Vector2(0, 0)

	# ③ 消息区：压一层更深的墨，让白字压得住
	# 面板放大到近半屏后背后全是主城细节，0.26 太透、字和建筑糊在一起，加深到 0.55
	var msgs: = chat_panel.get_node_or_null("VBoxContainer/ChatMessagesPanel") as Panel
	if msgs:
		var inner := StyleBoxFlat.new()
		inner.bg_color = Color(0.0, 0.0, 0.0, 0.55)
		inner.set_corner_radius_all(int(round(6.0 * s)))
		inner.content_margin_left = 6.0 * s
		inner.content_margin_right = 6.0 * s
		inner.content_margin_top = 4.0 * s
		inner.content_margin_bottom = 4.0 * s
		msgs.add_theme_stylebox_override("panel", inner)

	# ④ 输入框 / 发送键
	var inp: = chat_panel.get_node_or_null("VBoxContainer/InputHBox") as Control
	if inp:
		inp.custom_minimum_size = Vector2(0, 54.0 * s)
		inp.add_theme_constant_override("separation", int(round(8.0 * s)))
	var line: = chat_panel.get_node_or_null("VBoxContainer/InputHBox/ChatInput") as LineEdit
	if line:
		# 这里原来乘了 _ink.s（设计 19 → 720 宽实机只有 13px），
		# 而消息列表是写死 18 的，输入框反而比正文小一圈。
		# 输入框是玩家自己盯得最久的地方，固定 20 让它和正文同量级、略大一点。
		line.add_theme_font_size_override("font_size", 20)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.052, 0.044, 0.032, 0.62)
		st.border_color = Color(0.788, 0.635, 0.294, 0.42)
		st.set_border_width_all(1)
		st.set_corner_radius_all(int(round(22.0 * s)))
		st.content_margin_left = 14.0 * s
		st.content_margin_right = 10.0 * s
		line.add_theme_stylebox_override("normal", st)
		var stf := st.duplicate() as StyleBoxFlat
		stf.border_color = Color(0.925, 0.804, 0.518, 0.78)
		line.add_theme_stylebox_override("focus", stf)
		line.add_theme_color_override("font_color", Color(0.945, 0.945, 0.925))
		line.add_theme_color_override("font_placeholder_color", Color(0.72, 0.75, 0.76, 0.62))
		line.add_theme_color_override("caret_color", Color(0.925, 0.804, 0.518))
	var send: = chat_panel.get_node_or_null("VBoxContainer/InputHBox/SendBtn") as Button
	if send:
		send.custom_minimum_size = Vector2(112.0 * s, 0)
		# 发送键字号同样固定在正文量级，不再跟着 s 缩到看不清
		send.add_theme_font_size_override("font_size", 18)
		send.add_theme_color_override("font_color", Color(0.976, 0.878, 0.639))
		for st_name in ["normal", "hover", "pressed", "focus", "disabled"]:
			var b := StyleBoxFlat.new()
			b.bg_color = Color(0.118, 0.098, 0.043, 0.78) if st_name != "pressed" \
					else Color(0.216, 0.169, 0.059, 0.92)
			b.border_color = Color(0.788, 0.635, 0.294, 0.72)
			b.set_border_width_all(1)
			b.set_corner_radius_all(int(round(22.0 * s)))
			send.add_theme_stylebox_override(st_name, b)

	# ⑤ 频道签（世界 / 帮派）也换成水墨：旧素材是蓝红渐变 + 金框的贴图，
	#    和半透明水墨面板放一起很跳。这里必须等 _ink 建好再调，否则换算比例是错的。
	if _ink != null:
		_ink_style_chat_tabs()


## 点「面板以外」也能关：用独立 CanvasLayer(layer=30) 铺 4 块透明遮罩，
## 把聊天面板四周（顶/底/左/右）围起来，中间给面板留洞。
## 为什么不用一整块：① InkLayer 只铺主城场景区，底栏在其外；
## ② GUI 输入按树序/层级走，不是 z_index —— 普通子节点拦不住底栏。
## CanvasLayer 的输入优先级高于默认层，点面板外任何地方（含底栏）都会先落到
## 遮罩上 → 只负责关面板，不会误触底层按钮；点面板内部则没有任何遮罩，正常操作。
func _ink_make_chat_dismiss() -> void:
	if _chat_dismiss_layer != null and is_instance_valid(_chat_dismiss_layer):
		return
	var layer := CanvasLayer.new()
	layer.name = "InkChatDismissLayer"
	layer.layer = 30
	layer.visible = false
	for i in range(4):
		var rect := Control.new()
		rect.name = "Dismiss%d" % i
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		rect.gui_input.connect(_on_chat_dismiss_input)
		layer.add_child(rect)
		_chat_dismiss_rects.append(rect)
	add_child(layer)
	_chat_dismiss_layer = layer


## 按面板当前的全局矩形重算 4 块遮罩（打开时 / 布局变化时调用）
func _ink_update_chat_dismiss() -> void:
	if _chat_dismiss_layer == null or not is_instance_valid(_chat_dismiss_layer):
		return
	var vp: Vector2 = get_viewport_rect().size
	var pr := Rect2()
	if chat_panel != null and is_instance_valid(chat_panel):
		# 不看 visible：开面板那一刻先算遮罩、后设 visible，按可见与否会算成全屏
		pr = chat_panel.get_global_rect()
		pr.position = pr.position.max(Vector2.ZERO)
		pr.size = pr.size.min(vp)
	var edges := [
		Rect2(0.0, 0.0, vp.x, maxf(0.0, pr.position.y)),                                    # 顶
		Rect2(0.0, pr.end.y, vp.x, maxf(0.0, vp.y - pr.end.y)),                             # 底
		Rect2(0.0, pr.position.y, maxf(0.0, pr.position.x), pr.size.y),                     # 左
		Rect2(pr.end.x, pr.position.y, maxf(0.0, vp.x - pr.end.x), pr.size.y),              # 右
	]
	for i in range(4):
		var rect := _chat_dismiss_rects[i] as Control
		if rect == null:
			continue
		var r: Rect2 = edges[i]
		rect.position = r.position
		rect.size = r.size


func _on_chat_dismiss_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	_ink_set_chat_open(false)
	# 吃掉这次点击：玩家点的是"外面"，不该顺带把点到的那块按钮也按了
	get_viewport().set_input_as_handled()


func _ink_make_chat_horn() -> void:
	if _horn_btn != null and is_instance_valid(_horn_btn):
		return
	var tex: = load(CityInkData.DIR + "icon_horn.png") as Texture2D
	_horn_btn = Button.new()
	_horn_btn.name = "ChatHorn"
	_horn_btn.text = ""
	_horn_btn.focus_mode = Control.FOCUS_NONE
	_horn_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_horn_btn.custom_minimum_size = Vector2.ZERO
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		_horn_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_horn_btn.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink.add_child(_horn_btn)
	_horn_btn.pressed.connect(_ink_toggle_chat)
	# 呼吸提示：未读时喇叭轻轻起伏，避免玩家找不到入口
	var tw := create_tween().set_loops()
	tw.tween_property(art, "modulate:a", 0.82, 1.2).set_delay(0.6)
	tw.tween_property(art, "modulate:a", 1.0, 1.2)


## 面板右上角的关闭钮：手机用户习惯「右上角关窗」，别让他们再回去点喇叭。
func _ink_make_chat_close() -> void:
	if _chat_close_btn != null and is_instance_valid(_chat_close_btn):
		return
	var s: = _ink.s
	var btn := Button.new()
	btn.name = "InkChatClose"
	btn.text = "×"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2.ZERO
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var d: = 64.0 * s
	btn.offset_left = -d - 10.0 * s
	btn.offset_top = 10.0 * s
	btn.offset_right = -10.0 * s
	btn.offset_bottom = 10.0 * s + d
	btn.add_theme_font_size_override("font_size", maxi(14, int(round(26.0 * s))))
	btn.add_theme_color_override("font_color", Color(0.976, 0.878, 0.639))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.75, 0.52))
	if _ink_bold_font == null:
		_ink_bold_font = load("res://assets/fonts/ink_serif_bold.otf") as Font
	if _ink_bold_font != null:
		btn.add_theme_font_override("font", _ink_bold_font)
	for st_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var b := StyleBoxFlat.new()
		b.bg_color = Color(0.055, 0.047, 0.035, 0.82) if st_name != "pressed" \
				else Color(0.145, 0.118, 0.055, 0.92)
		b.border_color = Color(0.788, 0.635, 0.294, 0.78)
		b.set_border_width_all(1)
		b.set_corner_radius_all(int(round(32.0 * s)))
		btn.add_theme_stylebox_override(st_name, b)
	chat_panel.add_child(btn)
	btn.pressed.connect(func(): _ink_set_chat_open(false))
	_chat_close_btn = btn
	# 顶栏是 HBox，末尾塞一个空占位把「世界/帮派」签挤开，
	# 否则右上角的关闭钮会压在帮派签上点不到。
	var header: = chat_panel.get_node_or_null("VBoxContainer/ChatHeader") as Control
	if header != null and header.get_node_or_null("CloseSpace") == null:
		var spacer := Control.new()
		spacer.name = "CloseSpace"
		spacer.custom_minimum_size = Vector2(78.0 * s, 0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(spacer)


## 收起态预览：喇叭上方滚 5 条世界消息，无底板，越旧越淡。
func _ink_make_chat_preview() -> void:
	if _chat_preview_box != null and is_instance_valid(_chat_preview_box):
		return
	var box := VBoxContainer.new()
	box.name = "ChatPreview"
	# 只做展示：压在吊牌/建筑上时不能抢点击，否则玩家点不到「宠物园」这些入口
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 底部对齐：不足 5 条时最新那条也要贴着喇叭，不能浮在半空
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", int(round(2.0 * _ink.s)))
	_ink.add_child(box)
	_chat_preview_box = box


## 消息进来时喂给预览。只收「世界频道」的聊天/公告（帮派频道不进预览）。
func _push_chat_preview(msg_data: Dictionary) -> void:
	var event_type: = str(msg_data.get("event_type", "chat"))
	if event_type != "chat" and event_type != "announcement":
		return
	if _message_channel_type(msg_data) == "gang":
		return
	var message: = str(msg_data.get("message", "")).strip_edges()
	if message.is_empty():
		return
	var key: = _feed_message_key(msg_data)
	if _chat_preview_keys.has(key):
		return
	_chat_preview_keys[key] = true
	if _chat_preview_keys.size() > 200:
		_chat_preview_keys.clear()
		_chat_preview_keys[key] = true
	var sender: = str(msg_data.get("sender", msg_data.get("player_name", ""))).strip_edges()
	_chat_preview_msgs.append({"sender": sender, "message": message})
	while _chat_preview_msgs.size() > INK_PREVIEW_COUNT:
		_chat_preview_msgs.pop_front()
	_refresh_chat_preview()


func _refresh_chat_preview() -> void:
	if _chat_preview_box == null or not is_instance_valid(_chat_preview_box):
		return
	for ch in _chat_preview_box.get_children():
		_chat_preview_box.remove_child(ch)
		ch.free()
	var s: = _ink.s
	var n: = _chat_preview_msgs.size()
	for i in range(n):
		var item: Dictionary = _chat_preview_msgs[i]
		# 数组尾部是最新的一条：排在最下面（紧贴喇叭），越往上越旧越淡
		var age: = (n - 1) - i
		var alpha: float = float(INK_PREVIEW_ALPHA[clampi(age, 0, INK_PREVIEW_ALPHA.size() - 1)])
		var lab := Label.new()
		var sender: = str(item.get("sender", ""))
		var body: = str(item.get("message", ""))
		lab.text = "「%s」%s" % [sender, body] if not sender.is_empty() else body
		lab.autowrap_mode = TextServer.AUTOWRAP_OFF
		lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lab.clip_text = true
		lab.custom_minimum_size = Vector2(0, INK_PREVIEW_LINE_H * s)
		lab.add_theme_font_size_override("font_size", maxi(12, int(round(24.0 * s))))
		lab.add_theme_color_override("font_color", Color(0.965, 0.949, 0.886))
		# 无底框，压在浅色水墨画上必须靠描边压住底色
		lab.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.9))
		lab.add_theme_constant_override("outline_size", maxi(2, int(round(5.0 * s))))
		lab.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		lab.add_theme_constant_override("shadow_offset_x", 1)
		lab.add_theme_constant_override("shadow_offset_y", 2)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.modulate.a = alpha
		_chat_preview_box.add_child(lab)
	_chat_preview_box.visible = not _chat_open


func _ink_layout_chat() -> void:
	if _ink == null or not is_instance_valid(_ink):
		return
	if chat_panel == null or not is_instance_valid(chat_panel):
		return
	# 参考线取「底栏顶边」而不是 CityUI 自己的底边：
	# CityUI 是铺满全屏的，它的 size.y 一直到底栏下面，直接用它会把喇叭压进底栏里。
	var vp: = get_viewport_rect().size
	var s: = _ink.s
	# 底栏为 iPhone home 指示条整体上移的高度（逻辑像素，安卓 / 桌面为 0），
	# 由 main_ui.gd 的 _apply_root_layout 写进 Engine meta；喇叭跟着一起抬。
	var safe_b: float = float(Engine.get_meta("hl_safe_bottom")) if Engine.has_meta("hl_safe_bottom") else 0.0
	var dock_h: = 208.0 * s + safe_b
	var y_local: = vp.y - dock_h - _ink.global_position.y
	var bottom: = _ink.to_design_from_local(Vector2(0.0, y_local)).y
	var horn_y: = bottom - INK_CHAT_GAP - INK_HORN_D
	# 面板底边几乎贴住底栏（会盖住喇叭），高度按用户红线放到近半屏，顶部至少留 40 设计 px
	var panel_bottom: = bottom - INK_CHAT_BOTTOM_PAD
	var panel_h: = minf(INK_CHAT_H, panel_bottom - 40.0)
	var panel_y: = panel_bottom - panel_h
	if _horn_btn and is_instance_valid(_horn_btn):
		_ink.bind(_horn_btn, Vector2(INK_EDGE, horn_y), Vector2(INK_HORN_D, INK_HORN_D))
	_ink.bind(chat_panel, Vector2(INK_EDGE, panel_y), Vector2(INK_CHAT_W, panel_h))
	# 收起态预览：喇叭正上方，底边贴着喇叭顶
	if _chat_preview_box != null and is_instance_valid(_chat_preview_box):
		var prev_h: = INK_PREVIEW_LINE_H * float(INK_PREVIEW_COUNT)
		_ink.bind(_chat_preview_box,
				Vector2(INK_EDGE + 4.0, horn_y - 8.0 - prev_h),
				Vector2(INK_PREVIEW_W, prev_h))
	if _chat_open:
		_ink_set_chat_open(true, true)
	# 尺寸变了（横竖屏/分屏）字号要按新的 s 重算
	if _chat_preview_msgs.size() > 0:
		_refresh_chat_preview()
	# 面板矩形变了，遮罩的 4 块也要跟着挪
	_ink_update_chat_dismiss()


func _ink_toggle_chat() -> void:
	_ink_set_chat_open(not _chat_open)


func _ink_set_chat_open(open: bool, instant: bool = false) -> void:
	_chat_open = open
	# 遮罩只在面板打开时存在：点面板以外的任何地方都等于「关」
	if _chat_dismiss_layer != null and is_instance_valid(_chat_dismiss_layer):
		_ink_update_chat_dismiss()
		_chat_dismiss_layer.visible = open
	# 面板开着的时候不重复滚预览，收起才显示最近 5 条（否则文字会从面板边缘透出来）
	if _chat_preview_box != null and is_instance_valid(_chat_preview_box):
		_chat_preview_box.visible = not open
	if chat_panel == null or not is_instance_valid(chat_panel):
		return
	if _chat_tween != null and _chat_tween.is_valid():
		_chat_tween.kill()
	# 面板必须压在所有氛围层之上：CityFx 里人群的 z_index 直接取**设计坐标 y**
	# （1024×2276 设计稿，最下面的人到 2000 上下），仙鹤写死 900，都是全局 z 排序，
	# 光靠 move_to_front 改兄弟顺序压不住，表现为人物剪影浮在面板上、字被透穿。
	# 3000 高于任何设计 y，一次压死。
	chat_panel.z_index = 3000
	chat_panel.move_to_front()
	if instant:
		chat_panel.visible = open
		chat_panel.modulate.a = 1.0
		chat_panel.scale = Vector2.ONE
		return
	chat_panel.pivot_offset = Vector2(0.0, chat_panel.size.y)
	# 面板要盖在所有吊牌 / 圆钮之上：晚于它们被 reparent 进来的节点（打造坊、
	# 七日签到等是在 _ink_finish 里追加的）默认画在更上层，所以每次打开都置顶。
	if open:
		chat_panel.visible = true
		chat_panel.scale = Vector2(1.0, 0.86)
		chat_panel.modulate.a = 0.0
		_chat_tween = create_tween().set_parallel(true)
		_chat_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_chat_tween.tween_property(chat_panel, "scale", Vector2.ONE, 0.20)
		_chat_tween.tween_property(chat_panel, "modulate:a", 1.0, 0.16)
		if chat_scroll and is_instance_valid(chat_scroll):
			get_tree().create_timer(0.22).timeout.connect(_apply_chat_scroll_to_bottom, CONNECT_ONE_SHOT)
	else:
		_chat_tween = create_tween().set_parallel(true)
		_chat_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		_chat_tween.tween_property(chat_panel, "scale", Vector2(1.0, 0.88), 0.16)
		_chat_tween.tween_property(chat_panel, "modulate:a", 0.0, 0.14)
		_chat_tween.chain().tween_callback(func(): chat_panel.visible = false)


## 从功能页回到主城时，恢复玩家上次的聊天开合状态
func _ink_restore_chat() -> void:
	if _ink == null or not is_instance_valid(_ink):
		return
	_ink_set_chat_open(_chat_open, true)


func _build_ink_city() -> void:
	if _ink != null and is_instance_valid(_ink):
		return
	_ink = CityInkLayer.new()
	_ink.name = "InkLayer"
	add_child(_ink)
	move_child(_ink, 0)

	# ① 场景竖吊牌
	var signs := {
		"challenge": tower_btn,
		"war": xianmo_btn,
		"dungeon": suit_dungeon_btn,
		"treasure": treasure_cave_btn,
		"sect": more_btn,
		"martial": martial_btn,
		"arena": quest_btn,
		"furnace": crafting_btn,
		"forge": _forge_btn,
		"shop": shop_btn,
	}
	for key in signs.keys():
		_ink_take_over(signs[key], "plaque_%s.png" % key, _plaque_rect(key), key)

	# ② 右上竖排圆钮（宠物园与仓库已下架：宠物园变成场景吊牌，仓库并进背包分页）
	var rounds := {
		"rank": ranking_btn,
		"lucky": lucky_draw_btn,
		"mail": mail_btn,
	}
	for key in rounds.keys():
		_ink_take_over(rounds[key], "round_%s.png" % key, CityInkData.ROUNDS[key], key)

	# ③ 宠物园：圆钮改成和场景里一样的竖吊牌，接替原来「竞技」的那一格
	_ink_take_over(pet_btn, "plaque_pet.png", PLAQUE_PET_RECT, "pet")

	# ④ 仓库并进背包第三页，场景里不再留入口（节点留着但收起来，避免脏留着旧圆钮）
	if warehouse_btn != null and is_instance_valid(warehouse_btn):
		warehouse_btn.visible = false

	# ⑤ 设置齿轮（顶栏右端）
	_ink_take_over(settings_btn, "icon_gear.png", CityInkData.GEAR)

	# ⑥ 生死塔：浮动态入口，重排 + 换图
	_ink_take_over_tower()

	# ⑦ 聊天框搬到设计坐标的底部中央
	_ink_move_chat()
	if not _ink.resized.is_connected(_ink_layout_chat):
		_ink.resized.connect(_ink_layout_chat)
	_ink_layout_chat()


## 内页底板：插在 Background 之上、TitleBanner 之下。
## 内页期间主城（_ink）整体隐藏，所以这一层就是玩家实际看到的"底"。
func _setup_page_backdrop() -> void:
	if _backdrop != null and is_instance_valid(_backdrop):
		return
	_backdrop = InkPageBackdrop.new()
	_backdrop.name = "PageBackdrop"
	add_child(_backdrop)
	move_child(_backdrop, mini(2, get_child_count() - 1))


## 吊牌位置：竞技从原 (269,958) 挪到乾坤炉屋顶左上方（用户指定点），
## 空出来的那一格给宠物园（3 个字，牌子比原来高 28，往下顶齐底边）。
const PLAQUE_PET_RECT := {"pos": Vector2(269.0, 930.0), "size": Vector2(72.0, 151.09)}
const PLAQUE_ARENA_RECT := {"pos": Vector2(395.0, 624.0), "size": Vector2(72.0, 123.09)}


func _plaque_rect(key: String) -> Dictionary:
	if key == "arena":
		return PLAQUE_ARENA_RECT
	return CityInkData.SIGNS[key]


## 把一个旧 Button 变成「透明命中框 + 贴图子节点」，并按设计坐标摆放
func _ink_take_over(btn: Button, tex_name: String, rect: Dictionary, dot_key: String = "") -> void:
	if btn == null or not is_instance_valid(btn):
		push_warning("[CityUI] ink 接管失败（节点为空）: %s" % tex_name)
		return
	var tex: = load(CityInkData.DIR + tex_name) as Texture2D
	if tex == null:
		push_warning("[CityUI] ink 贴图加载失败: %s" % tex_name)
		return

	btn.reparent(_ink)
	btn.text = ""
	btn.flat = false
	btn.clip_text = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.custom_minimum_size = Vector2.ZERO
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())

	var art: = TextureRect.new()
	art.name = "Art"
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_ink.bind(btn, rect["pos"], rect["size"])
	_ink_bind_press(btn)
	if not dot_key.is_empty():
		_make_red_dot(dot_key, rect)


## 按下反馈：整块贴图缩一下再弹回来，同时提亮 —— 透明命中框上唯一能看见的「响应」
func _ink_bind_press(btn: Button) -> void:
	_ink_bind_press_with(btn, null)


func _ink_bind_press_with(btn: BaseButton, art: Control) -> void:
	if btn == null or not is_instance_valid(btn) or btn.has_meta("ink_press"):
		return
	btn.set_meta("ink_press", true)
	if art != null and is_instance_valid(art):
		btn.set_meta("ink_art", art)
	btn.button_down.connect(_on_ink_btn_down.bind(btn))
	btn.button_up.connect(_on_ink_btn_up.bind(btn))
	btn.mouse_exited.connect(_on_ink_btn_up.bind(btn))
	# 有些入口（生死塔、七日签到）走 TouchScrollUtils.bind_tap，靠 gui_input 收事件，
	# 不一定发 button_down —— 这里再挂一条，两路都触发也不会出问题（tween 会被顶替）。
	btn.gui_input.connect(_on_ink_btn_gui_input.bind(btn))


func _on_ink_btn_gui_input(ev: InputEvent, btn: BaseButton) -> void:
	if ev is InputEventScreenTouch:
		_ink_press_anim(btn, (ev as InputEventScreenTouch).pressed)
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_ink_press_anim(btn, mb.pressed)


func _ink_art_of(btn: BaseButton) -> Control:
	var bound = btn.get_meta("ink_art", null)
	if bound is Control and is_instance_valid(bound):
		return bound as Control
	var a: = btn.get_node_or_null("Art")
	if a is Control:
		return a as Control
	for c in btn.get_children():
		if c is TextureRect:
			return c as Control
	return null


func _on_ink_btn_down(btn: BaseButton) -> void:
	_ink_press_anim(btn, true)


func _on_ink_btn_up(btn: BaseButton) -> void:
	_ink_press_anim(btn, false)


func _ink_press_anim(btn: BaseButton, down: bool) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var art := _ink_art_of(btn)
	if art == null or not is_instance_valid(art):
		return
	var old = btn.get_meta("ink_tw", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	# 缩放中心必须每次按当前尺寸算：窗口变了按钮尺寸也会变
	art.pivot_offset = art.size * 0.5
	var tw := create_tween().set_parallel(true)
	if down:
		tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(art, "scale", Vector2(0.93, 0.93), 0.075)
		tw.tween_property(art, "modulate", Color(1.16, 1.16, 1.10, 1.0), 0.075)
	else:
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(art, "scale", Vector2.ONE, 0.20)
		tw.tween_property(art, "modulate", Color.WHITE, 0.14)
	btn.set_meta("ink_tw", tw)


# ---------------------------------------------------------------- 红点
func _get_dot_tex() -> Texture2D:
	if _dot_tex != null:
		return _dot_tex
	# 白描边 + 红心的小圆点，和常见手游的红点一样的读法
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	var r_red := c * 0.72
	var r_ring := c * 0.94
	for y in range(n):
		for x in range(n):
			var d := Vector2(x - c, y - c).length()
			var a_ring := clampf((r_ring - d) / 1.3, 0.0, 1.0)
			var a_red := clampf((r_red - d) / 1.1, 0.0, 1.0)
			if a_ring <= 0.004:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var white := Color(1.0, 0.976, 0.953)
				var red := Color(0.909, 0.196, 0.161)
				var col := white.lerp(red, a_red)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a_ring))
	_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex


func _make_red_dot(key: String, rect: Dictionary) -> void:
	if _ink == null or not is_instance_valid(_ink):
		return
	if _red_dots.has(key):
		return
	var pos: Vector2 = rect["pos"]
	var sz: Vector2 = rect["size"]
	var is_round: bool = absf(sz.x - sz.y) < 1.0
	# 圆钮的红点落在 1 点半方向（和原来的美术位置一致）；竖吊牌落在顶部胶囊的右端
	var rel := Vector2(0.715, 0.275) if is_round else Vector2(0.795, 0.205)
	var dia := 19.0 if is_round else 17.0
	var c := Vector2(pos.x + sz.x * rel.x, pos.y + sz.y * rel.y)
	var d := TextureRect.new()
	d.name = "Dot_%s" % key
	d.texture = _get_dot_tex()
	d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d.stretch_mode = TextureRect.STRETCH_SCALE
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.visible = false
	_ink.add_child(d)
	_ink.bind(d, c - Vector2(dia, dia) * 0.5, Vector2(dia, dia))
	_red_dots[key] = d


func _setup_red_dot_timer() -> void:
	if _dot_timer != null and is_instance_valid(_dot_timer):
		return
	_dot_timer = Timer.new()
	_dot_timer.name = "RedDotTimer"
	_dot_timer.wait_time = 6.0
	_dot_timer.autostart = true
	_dot_timer.timeout.connect(_refresh_red_dots)
	add_child(_dot_timer)


## 红点只由「游戏机制」点亮：有可领的奖励、还有可用次数才亮。
## 接通的状态源：
##   mail    邮箱未读数 > 0
##   lucky   幸运抽奖保底次数已满（≥100 次）
##   war     仙魔挑战：已入阵营且还有行动力
##   signin7 七日签到今日还没领
## 其余入口目前没有可靠的状态源 —— 宁可不亮，也不做假红点。
func _red_dot_flags() -> Dictionary:
	return {
		"mail": MailManager.instance != null and MailManager.instance.unread_count > 0,
		"lucky": _lucky_pity_ready(),
		"war": _xianmo_can_challenge(),
		"signin7": _signin7_can_claim,
	}


func _lucky_pity_ready() -> bool:
	if game_manager == null or not is_instance_valid(game_manager):
		return false
	var p = game_manager.get("player")
	if p == null or not is_instance_valid(p):
		return false
	if not p.has_meta("lottery_yuanbao_pity_count"):
		return false
	return int(p.get_meta("lottery_yuanbao_pity_count")) >= 100


func _xianmo_can_challenge() -> bool:
	if game_manager == null or not is_instance_valid(game_manager):
		return false
	var sys = game_manager.get("xianmo_system")
	if sys == null or not is_instance_valid(sys):
		return false
	var d = sys.get("xianmo_data")
	if d == null:
		return false
	if not bool(d.is_joined()):
		return false
	return int(d.action_points) > 0


func _apply_red_dots() -> void:
	if _red_dots.is_empty():
		return
	# 打开功能页时 _ink.set_ui_visible(false) 已经把它们收起来了；
	# 定时刷新不能在功能页上把它们又点亮。
	var has_content := current_content != null and is_instance_valid(current_content)
	var flags := _red_dot_flags()
	for k in _red_dots.keys():
		var d: Control = _red_dots[k]
		if d == null or not is_instance_valid(d):
			continue
		d.visible = (not has_content) and bool(flags.get(k, false))


func _refresh_red_dots() -> void:
	_apply_red_dots()


func _ink_take_over_tower() -> void:
	var wrap: = _shengsi_tower_wrap
	if wrap == null or not is_instance_valid(wrap):
		return
	wrap.reparent(_ink)
	wrap.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wrap.anchor_left = 0.0
	wrap.anchor_top = 0.0
	wrap.anchor_right = 0.0
	wrap.anchor_bottom = 0.0
	wrap.custom_minimum_size = Vector2.ZERO
	var tex: = load(CityInkData.DIR + "plaque_tower.png") as Texture2D
	var art: Control = null
	for c in wrap.get_children():
		if c is TextureRect and tex != null:
			var tr: = c as TextureRect
			tr.texture = tex
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art = tr
	_ink.bind(wrap, CityInkData.SIGNS["tower"]["pos"], CityInkData.SIGNS["tower"]["size"])
	# 生死塔的贴图和命中框是兄弟节点（贴图在 wrap 上、按钮是子节点），要显式告诉反馈层压哪一张
	if _shengsi_tower_btn != null and is_instance_valid(_shengsi_tower_btn):
		_ink_bind_press_with(_shengsi_tower_btn, art)


func _ink_move_chat() -> void:
	_ink_setup_chat()


func _ink_place_signin7() -> void:
	if _signin7_wrap == null or not is_instance_valid(_signin7_wrap):
		return
	var wrap: = _signin7_wrap
	wrap.reparent(_ink)
	wrap.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wrap.anchor_left = 0.0
	wrap.anchor_top = 0.0
	wrap.anchor_right = 0.0
	wrap.anchor_bottom = 0.0
	wrap.custom_minimum_size = Vector2.ZERO
	_ink.bind(wrap, Vector2(44.0, 168.0), Vector2(104.0, 104.0))


func _ink_finish() -> void:
	# 旧的匾额底板（带云纹框的「幻灵主城」）—— 新标题不需要框
	var banner: = get_node_or_null("TitleBanner")
	if banner is CanvasItem:
		(banner as CanvasItem).visible = false
	# 只关掉旧的功能按钮面板；VBox 里还有 ContentContainer，
	# 功能页（排行榜/商店/背包…）全都挂在它下面，整条关掉会导致点不开。
	var panel: = get_node_or_null("VBoxContainer/MainContent/FeaturePanel")
	if panel is CanvasItem:
		(panel as CanvasItem).visible = false
	# 旧的流式容器现在是「透明但存在」的，它默认 MOUSE_FILTER_STOP 且铺满全屏，
	# 会把水墨层上的吊牌点击全部吃掉。把这些壳设成 IGNORE（子节点照常收事件）。
	for path in ["VBoxContainer", "VBoxContainer/MainContent",
			"VBoxContainer/MainContent/HomeGapSpacer"]:
		var n: = get_node_or_null(path)
		if n is Control:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 功能页容器从流式布局里解放出来，铺满整个主城（原版是挤在左列按钮旁边的）
	if content_container and is_instance_valid(content_container):
		content_container.reparent(self)
		content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_container.offset_left = 0.0
		content_container.offset_top = 44.0
		content_container.offset_right = 0.0
		content_container.offset_bottom = 0.0
	# 返回键挪到左上角，别压在新标题上
	if back_btn and is_instance_valid(back_btn):
		back_btn.reparent(self)
		back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		back_btn.position = Vector2(8.0, 6.0)
		back_btn.size = Vector2(132.0, 34.0)
		back_btn.z_index = 5

	_ink_place_signin7()
	_refresh_signin7_entry()
