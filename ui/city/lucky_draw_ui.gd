extends Control
class_name LuckyDrawUI

const GOLD_DRAW_COST: = 500000000
const YUANBAO_DRAW_COST: = 100
const YUANBAO_PITY_THRESHOLD: = 100
const YUANBAO_PITY_OPTIONS: = [
	"11+不可进化宠礼包", 
	"11+可进化宠礼包", 
	"连笔lv1技能书", 
	"逆锋lv1技能书", 
	"护墨lv1技能书", 
	"溅墨lv1技能书", 
]
const SHOWCASE_ITEMS = {
	"gold": [
		"10亿金币", 
		"极限装备之一", 
		"7+可进化宠礼包", 
		"6+可进化宠礼包", 
		"5+宠物礼包", 
		"五行属性宠物蛋", 
		"高级解封石", 
		"黄金宝箱", 
		"固色lv1技能书"
	], 
	"yuanbao": [
		"2026纪念法宝碎片", 
		"10亿金币", 
		"11+可进化宠礼包", 
		"11+不可进化宠礼包", 
		"10+可进化宠礼包", 
		"连笔lv1技能书", 
		"极限装备之一", 
		"逆锋lv1技能书", 
		"溅墨lv1技能书", 
		"护墨lv1技能书"
	]
}
const PROBABILITY_TEXT = {
	"gold": "金币池（5亿金币/次）\n\n1亿金币: 34.51%\n2亿金币: 12%\n5亿金币: 约0.57%\n10亿金币: 约0.14%\n普通解封石: 约11.35%\n高级解封石: 约4.26%\n青铜宝箱: 约7.09%\n白银宝箱: 约2.84%\n黄金宝箱: 约1.13%\n极限装备之一: 5%\n5+宠物礼包: 约11.13%\n五行属性宠物蛋: 约1.28%\n6+可进化宠礼包: 约5.57%\n7+可进化宠礼包: 约2.14%\n固色lv1技能书: 约1.00%", 
	"yuanbao": "元宝池（100元宝/次）\n\n5亿金币: 16%\n2026纪念法宝碎片: 12%\n6+可进化宠礼包: 10%\n7+可进化宠礼包: 10%\n7+不可进化宠礼包: 10%\n黄金宝箱: 6.7%\n普通解封石: 4.3%\n极限装备（随机一件）: 2%\n10亿金币: 4%\n五行属性宠物蛋: 4%\n高级解封石: 3.6%\n人物升级丹: 2%\n宠物升级丹: 2%\n8+可进化宠礼包: 1.5%\n8+不可进化宠礼包: 1.5%\n9+不可进化宠礼包: 1%\n9+可进化宠礼包: 1%\n7-9水晶儿礼包: 1%\n7-9梦晶儿礼包: 1%\n7-9阿弟达斯礼包: 1%\n10+不可进化宠礼包: 0.7%\n10+可进化宠礼包: 0.7%\n11+可进化宠礼包: 0.5%\n11+不可进化宠礼包: 0.5%\n稀有技能书之一: 1%\n  - 溅射/反击/神佑/连射/吸血 lv1（池内均分）\n普通技能书之一: 2%\n  - 自愈/迅捷/坚固/长寿/强壮/凶猛/必杀/追击/忠心/嘲讽 lv1（池内均分）\n\n【100次保底】\n元宝抽奖累计达到100次后，可在以下奖励中【六选一】领取1份（仅可领取其中1份，邮件发放）：\n- 11+不可进化宠礼包\n- 11+可进化宠礼包\n- 连笔lv1技能书\n- 逆锋lv1技能书\n- 护墨lv1技能书\n- 溅墨lv1技能书"
}
const ITEM_META = {
	"5亿金币": {"icon": "💰", "color": Color(0.92, 0.78, 0.22, 0.26)}, 
	"1亿金币": {"icon": "💰", "color": Color(0.88, 0.76, 0.28, 0.24)}, 
	"10亿金币": {"icon": "💰", "color": Color(0.95, 0.8, 0.25, 0.28)}, 
	"普通解封石": {"icon": "💎", "color": Color(0.072, 0.080, 0.079, 0.22)}, 
	"极限装备之一": {"icon": "⚔", "color": Color(0.85, 0.5, 0.2, 0.28)}, 
	"7+可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.28)}, 
	"6+可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"5+宠物礼包": {"icon": "🎁", "color": Color(0.5, 0.85, 0.65, 0.24)}, 
	"五行属性宠物蛋": {"icon": "🥚", "color": Color(0.7, 0.9, 0.45, 0.24)}, 
	"高级解封石": {"icon": "💎", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"黄金宝箱": {"icon": "🧰", "color": Color(0.95, 0.75, 0.3, 0.24)}, 
	"白银宝箱": {"icon": "🧰", "color": Color(0.072, 0.080, 0.079, 0.2)}, 
	"人物升级丹": {"icon": "🧪", "color": Color(0.95, 0.62, 0.3, 0.24)}, 
	"宠物升级丹": {"icon": "🧪", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"溅墨lv1技能书": {"icon": "📘", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"7-9阿弟达斯礼包": {"icon": "🌟", "color": Color(0.95, 0.5, 0.5, 0.26)}, 
	"7-9梦晶儿礼包": {"icon": "🌟", "color": Color(0.072, 0.080, 0.079, 0.26)}, 
	"7-9水晶儿礼包": {"icon": "🌟", "color": Color(0.072, 0.080, 0.079, 0.26)}, 
	"9+可进化宠礼包": {"icon": "🐉", "color": Color(0.95, 0.42, 0.35, 0.24)}, 
	"8+可进化宠礼包": {"icon": "🐉", "color": Color(0.95, 0.55, 0.35, 0.2)}, 
	"7+不可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"8+不可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"9+不可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"10+不可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"11+不可进化宠礼包": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"10+可进化宠礼包": {"icon": "🐉", "color": Color(0.92, 0.48, 0.38, 0.24)}, 
	"11+可进化宠礼包": {"icon": "🐉", "color": Color(0.9, 0.4, 0.36, 0.26)}, 
	"连笔lv1技能书": {"icon": "📘", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"逆锋lv1技能书": {"icon": "📘", "color": Color(0.95, 0.72, 0.45, 0.24)}, 
	"护墨lv1技能书": {"icon": "📘", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"固色lv1技能书": {"icon": "📘", "color": Color(0.55, 0.78, 0.72, 0.24)}, 
	"2026纪念法宝碎片": {"icon": "✨", "color": Color(0.95, 0.72, 0.28, 0.28)}
}
const SHOWCASE_ICON_STYLES: = {
	"gold": {"icon": "💰", "color": Color(0.95, 0.8, 0.25, 0.28)}, 
	"gift": {"icon": "🎁", "color": Color(0.5, 0.85, 0.65, 0.24)}, 
	"pet": {"icon": "🐾", "color": Color(0.072, 0.080, 0.079, 0.28)}, 
	"skill": {"icon": "📘", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"equip": {"icon": "⚔", "color": Color(0.85, 0.5, 0.2, 0.28)}, 
	"egg": {"icon": "🥚", "color": Color(0.7, 0.9, 0.45, 0.24)}, 
	"box": {"icon": "🧰", "color": Color(0.95, 0.75, 0.3, 0.24)}, 
	"gem": {"icon": "💎", "color": Color(0.072, 0.080, 0.079, 0.24)}, 
	"potion": {"icon": "🧪", "color": Color(0.95, 0.62, 0.3, 0.24)}, 
	"star": {"icon": "🌟", "color": Color(0.95, 0.72, 0.45, 0.26)}, 
}

var game_manager = null
var result_label: RichTextLabel = null
var tab_container: TabContainer = null
var draw_buttons: Dictionary = {}
var pity_progress_bar: ProgressBar = null
var pity_progress_text_in_bar: Label = null
var pity_claim_btn: Button = null
var pity_reward_options: Array = YUANBAO_PITY_OPTIONS.duplicate()
var pity_count: int = 0

var pity_sync_done: bool = false
var pity_claiming: bool = false
var _popup_overlay: ColorRect = null
var _draw_overlay: ColorRect = null
var _draw_anim_label: Label = null
var _draw_anim_active: bool = false
var _draw_result_ready: bool = false
var _draw_result_data: Dictionary = {}
var _draw_error_msg: String = ""
var _draw_pool_type: String = ""
var _lottery_runtime: Dictionary = {}
var _lottery_config_loaded: bool = false
var _showcase_grids: Dictionary = {}

static func create_fullscreen(manager) -> LuckyDrawUI:
	var ui: = LuckyDrawUI.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.offset_left = 0
	ui.offset_top = 0
	ui.offset_right = 0
	ui.offset_bottom = 0
	ui.set_game_manager(manager)
	return ui

func set_game_manager(manager) -> void :
	game_manager = manager

func _ready() -> void :
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build_ui()
	_refresh_currency_text()
	_bind_pity_signals()
	call_deferred("_request_pity_status")
	call_deferred("_apply_lottery_runtime_config")

func _apply_lottery_runtime_config() -> void :
	if game_manager == null:
		return
	var cfg: Dictionary = game_manager.get_lottery_runtime_config()
	if not cfg.is_empty():
		_merge_lottery_runtime_config(cfg)
	if game_manager.network and game_manager.network.is_logged_in():
		if not game_manager.network.gameplay_runtime_config_loaded.is_connected(_on_gameplay_runtime_config_for_lottery):
			game_manager.network.gameplay_runtime_config_loaded.connect(_on_gameplay_runtime_config_for_lottery, CONNECT_ONE_SHOT)
		game_manager.network.fetch_gameplay_runtime_config()

func _on_gameplay_runtime_config_for_lottery(config: Dictionary) -> void :
	if game_manager:
		game_manager._on_gameplay_runtime_config_loaded(config)
	_merge_lottery_runtime_config(game_manager.get_lottery_runtime_config() if game_manager else {})

func _merge_lottery_runtime_config(cfg: Dictionary) -> void :
	if cfg.is_empty():
		return
	_lottery_runtime = cfg.duplicate(true)
	_lottery_config_loaded = true
	var display: Dictionary = cfg.get("display", {}) if cfg.get("display") is Dictionary else {}
	var pity: Dictionary = cfg.get("pity", {}) if cfg.get("pity") is Dictionary else {}
	if pity.has("options") and pity["options"] is Array:
		pity_reward_options = (pity["options"] as Array).duplicate()
	if pity.has("threshold"):
		var th: = int(pity.get("threshold", YUANBAO_PITY_THRESHOLD))
		if pity_progress_bar:
			pity_progress_bar.max_value = th
	var tab_labels: Dictionary = display.get("tabLabels", {}) if display.get("tabLabels") is Dictionary else {}
	if tab_container:
		if tab_labels.has("gold"):
			tab_container.set_tab_title(0, str(tab_labels.get("gold")))
		if tab_labels.has("yuanbao"):
			tab_container.set_tab_title(1, str(tab_labels.get("yuanbao")))
	_refresh_showcase_grids()

func _refresh_showcase_grids() -> void :
	for pool_type in ["gold", "yuanbao"]:
		var grid: GridContainer = _showcase_grids.get(pool_type)
		if grid == null or not is_instance_valid(grid):
			continue
		for child in grid.get_children():
			child.queue_free()
		for item_entry in _get_showcase_items(pool_type):
			grid.add_child(_create_showcase_card(item_entry))

func _get_pool_cost(pool_type: String) -> int:
	var pools: Dictionary = _lottery_runtime.get("pools", {}) if _lottery_runtime.get("pools") is Dictionary else {}
	var pool: Dictionary = pools.get(pool_type, {}) if pools.get(pool_type) is Dictionary else {}
	var cost: Dictionary = pool.get("cost", {}) if pool.get("cost") is Dictionary else {}
	var amt: = int(cost.get("amount", 0))
	if amt > 0:
		return amt
	return GOLD_DRAW_COST if pool_type == "gold" else YUANBAO_DRAW_COST

func _get_showcase_items(pool_type: String) -> Array:
	var display: Dictionary = _lottery_runtime.get("display", {}) if _lottery_runtime.get("display") is Dictionary else {}
	var showcase: Dictionary = display.get("showcaseItems", {}) if display.get("showcaseItems") is Dictionary else {}
	if showcase.has(pool_type) and showcase[pool_type] is Array:
		var out: Array = []
		for entry in showcase[pool_type]:
			var norm: = _normalize_showcase_entry(entry)
			if not str(norm.get("name", "")).is_empty():
				out.append(norm)
		if not out.is_empty():
			return out
	var fallback: Array = []
	for name in SHOWCASE_ITEMS.get(pool_type, []):
		fallback.append(_normalize_showcase_entry(name))
	return fallback

func _normalize_showcase_entry(entry: Variant) -> Dictionary:
	if entry is Dictionary:
		var name_text: = str(entry.get("name", "")).strip_edges()
		var icon_key: = str(entry.get("icon", "")).strip_edges()
		if icon_key.is_empty():
			icon_key = _guess_showcase_icon_key(name_text)
		return {"name": name_text, "icon": icon_key}
	var name_only: = str(entry).strip_edges()
	return {"name": name_only, "icon": _guess_showcase_icon_key(name_only)}

func _guess_showcase_icon_key(name_text: String) -> String:
	var n: = name_text.strip_edges()
	if n.is_empty():
		return "gift"
	if "金币" in n:
		return "gold"
	if "技能书" in n:
		return "skill"
	if "极限装备" in n or "极限武器" in n or "极限衣服" in n:
		return "equip"
	if "宠物蛋" in n or "属性蛋" in n:
		return "egg"
	if "宝箱" in n:
		return "box"
	if "解封石" in n:
		return "gem"
	if "升级丹" in n or "仙丹" in n:
		return "potion"
	if "礼包" in n and "宠" in n:
		return "pet"
	if "礼包" in n:
		return "gift"
	if "可进化" in n or "不可进化" in n or "+可" in n or "+不可" in n:
		return "pet"
	return "gift"

func _resolve_showcase_meta(item_name: String, icon_key: String) -> Dictionary:
	if icon_key != "" and SHOWCASE_ICON_STYLES.has(icon_key):
		return SHOWCASE_ICON_STYLES[icon_key]
	if ITEM_META.has(item_name):
		return ITEM_META[item_name]
	return SHOWCASE_ICON_STYLES.get(_guess_showcase_icon_key(item_name), {"icon": "🎁", "color": Color(0.072, 0.080, 0.079, 0.22)})

func _get_probability_text(pool_type: String) -> String:
	if game_manager:
		var live: Dictionary = game_manager.get_lottery_runtime_config()
		if not live.is_empty():
			_lottery_runtime = live.duplicate(true)
	var display: Dictionary = _lottery_runtime.get("display", {}) if _lottery_runtime.get("display") is Dictionary else {}
	var prob: Dictionary = display.get("probabilityText", {}) if display.get("probabilityText") is Dictionary else {}
	if prob.has(pool_type) and str(prob.get(pool_type, "")).strip_edges() != "":
		return str(prob.get(pool_type))
	var text: String = PROBABILITY_TEXT.get(pool_type, "暂无概率信息")
	if game_manager != null and game_manager.has_method("local_lottery_draw"):
		text += "\n\n本地测试：按原客户端展示的相对权重换算。金币池展示约数合计100.01%，精确服务端概率待核对；奖励直接入背包/余额。"
	return text

func _build_ui() -> void :
	var panel: = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var root: = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 24
	root.offset_right = -24
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)
	root.clip_contents = true

	var title: = Label.new()
	title.text = "🎰 幸运抽奖"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	root.add_child(title)

	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.tab_alignment = TabBar.ALIGNMENT_CENTER
	root.add_child(tab_container)
	_style_tab_bar()
	_add_pool_tab("gold", "金币抽奖（5亿金币/次）")
	_add_pool_tab("yuanbao", "元宝抽奖（100元宝/次）")

	result_label = RichTextLabel.new()
	result_label.bbcode_enabled = true
	result_label.fit_content = false
	result_label.custom_minimum_size = Vector2(0, 76)
	result_label.size_flags_vertical = Control.SIZE_SHRINK_END
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.scroll_active = true
	result_label.text = ""
	root.add_child(result_label)

func _refresh_currency_text() -> void :

	return

func _add_pool_tab(pool_type: String, tab_title: String) -> void :
	var tab: = VBoxContainer.new()
	tab.name = tab_title
	tab.add_theme_constant_override("separation", 10)
	tab_container.add_child(tab)

	var top_spacer: = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 10)
	tab.add_child(top_spacer)

	var subtitle: = Label.new()
	subtitle.text = "重要奖品展示"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	tab.add_child(subtitle)

	var center_grid: = CenterContainer.new()
	center_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(center_grid)

	var grid: = GridContainer.new()
	grid.name = "showcase_grid_%s" % pool_type
	grid.columns = 3
	grid.custom_minimum_size = Vector2(540, 0)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	center_grid.add_child(grid)
	_showcase_grids[pool_type] = grid

	for item_entry in _get_showcase_items(pool_type):
		grid.add_child(_create_showcase_card(item_entry))

	var action_center: = CenterContainer.new()
	action_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_child(action_center)

	var action_col: = VBoxContainer.new()
	action_col.custom_minimum_size = Vector2(230, 0)
	action_col.add_theme_constant_override("separation", 8)
	action_center.add_child(action_col)

	var draw_btn: = Button.new()
	draw_btn.text = "开始抽奖"
	draw_btn.custom_minimum_size = Vector2(230, 54)
	draw_btn.add_theme_font_size_override("font_size", 24)
	draw_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var draw_style: = StyleBoxFlat.new()
	draw_style.bg_color = Color(0.072, 0.062, 0.045, 0.95)
	draw_style.corner_radius_top_left = 0
	draw_style.corner_radius_top_right = 0
	draw_style.corner_radius_bottom_left = 0
	draw_style.corner_radius_bottom_right = 0
	draw_style.border_width_left = 1
	draw_style.border_width_top = 1
	draw_style.border_width_right = 1
	draw_style.border_width_bottom = 1
	draw_style.border_color = Color(1, 0.8, 0.4, 0.9)
	draw_btn.add_theme_stylebox_override("normal", draw_style)
	var draw_hover: = draw_style.duplicate()
	draw_hover.bg_color = Color(0.118, 0.100, 0.058, 1.0)
	draw_btn.add_theme_stylebox_override("hover", draw_hover)
	draw_btn.pressed.connect( func(): _request_draw(pool_type))
	action_col.add_child(draw_btn)
	draw_buttons[pool_type] = draw_btn

	var prob_btn: = Button.new()
	prob_btn.text = "抽奖概率"
	prob_btn.custom_minimum_size = Vector2(230, 32)
	prob_btn.add_theme_font_size_override("font_size", 15)
	prob_btn.add_theme_color_override("font_color", Color(0.924, 0.893, 0.831))
	var prob_style: = StyleBoxFlat.new()
	prob_style.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	prob_style.corner_radius_top_left = 0
	prob_style.corner_radius_top_right = 0
	prob_style.corner_radius_bottom_left = 0
	prob_style.corner_radius_bottom_right = 0
	prob_btn.add_theme_stylebox_override("normal", prob_style)
	prob_btn.pressed.connect( func(): _show_probability(pool_type))
	action_col.add_child(prob_btn)

	if pool_type == "yuanbao":
		var pity_panel: = PanelContainer.new()
		pity_panel.custom_minimum_size = Vector2(230, 102)
		var pity_style: = StyleBoxFlat.new()
		pity_style.bg_color = Color(0.072, 0.080, 0.079, 0.9)
		pity_style.border_width_left = 1
		pity_style.border_width_top = 1
		pity_style.border_width_right = 1
		pity_style.border_width_bottom = 1
		pity_style.border_color = Color(0.873, 0.743, 0.432, 0.92)
		pity_style.corner_radius_top_left = 0
		pity_style.corner_radius_top_right = 0
		pity_style.corner_radius_bottom_left = 0
		pity_style.corner_radius_bottom_right = 0
		pity_panel.add_theme_stylebox_override("panel", pity_style)
		action_col.add_child(pity_panel)

		var pity_vb: = VBoxContainer.new()
		pity_vb.add_theme_constant_override("separation", 6)
		pity_panel.add_child(pity_vb)

		var pity_title: = Label.new()
		pity_title.text = "保底进度（元宝池）"
		pity_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pity_title.add_theme_font_size_override("font_size", 16)
		pity_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68, 1.0))
		pity_vb.add_child(pity_title)

		pity_progress_bar = ProgressBar.new()
		pity_progress_bar.max_value = YUANBAO_PITY_THRESHOLD
		pity_progress_bar.value = 0
		pity_progress_bar.custom_minimum_size = Vector2(210, 18)
		pity_progress_bar.show_percentage = false
		var bar_wrap: = MarginContainer.new()
		bar_wrap.add_theme_constant_override("margin_left", 8)
		bar_wrap.add_theme_constant_override("margin_right", 8)
		bar_wrap.custom_minimum_size = Vector2(210, 24)
		pity_vb.add_child(bar_wrap)
		bar_wrap.add_child(pity_progress_bar)
		pity_progress_text_in_bar = Label.new()
		pity_progress_text_in_bar.text = "同步中…"
		pity_progress_text_in_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pity_progress_text_in_bar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pity_progress_text_in_bar.add_theme_font_size_override("font_size", 13)
		pity_progress_text_in_bar.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850, 0.95))
		pity_progress_text_in_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
		pity_progress_bar.add_child(pity_progress_text_in_bar)

		pity_claim_btn = Button.new()
		pity_claim_btn.text = "领取保底"
		pity_claim_btn.custom_minimum_size = Vector2(210, 36)
		pity_claim_btn.disabled = true
		pity_claim_btn.add_theme_font_size_override("font_size", 16)
		var pity_claim_style: = StyleBoxFlat.new()
		pity_claim_style.bg_color = Color(0.072, 0.062, 0.045, 0.95)
		pity_claim_style.corner_radius_top_left = 0
		pity_claim_style.corner_radius_top_right = 0
		pity_claim_style.corner_radius_bottom_left = 0
		pity_claim_style.corner_radius_bottom_right = 0
		pity_claim_btn.add_theme_stylebox_override("normal", pity_claim_style)
		pity_claim_btn.pressed.connect(_on_pity_claim_pressed)
		pity_vb.add_child(pity_claim_btn)

func _style_tab_bar() -> void :
	var tab_bar: = tab_container.get_tab_bar()
	if tab_bar == null:
		return
	tab_bar.add_theme_font_size_override("font_size", 18)
	tab_bar.add_theme_color_override("font_selected_color", Color(0.2, 0.12, 0.03, 1.0))
	tab_bar.add_theme_color_override("font_unselected_color", Color(0.894, 0.864, 0.803, 1.0))
	tab_bar.add_theme_color_override("font_hovered_color", Color(1.0, 0.95, 0.72, 1.0))

	var selected_style: = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.118, 0.100, 0.058, 0.98)
	selected_style.border_width_left = 1
	selected_style.border_width_top = 1
	selected_style.border_width_right = 1
	selected_style.border_width_bottom = 1
	selected_style.border_color = Color(1.0, 0.92, 0.66, 1.0)
	selected_style.corner_radius_top_left = 0
	selected_style.corner_radius_top_right = 0
	selected_style.corner_radius_bottom_left = 0
	selected_style.corner_radius_bottom_right = 0
	tab_bar.add_theme_stylebox_override("tab_selected", selected_style)

	var unselected_style: = StyleBoxFlat.new()
	unselected_style.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	unselected_style.border_width_left = 1
	unselected_style.border_width_top = 1
	unselected_style.border_width_right = 1
	unselected_style.border_width_bottom = 1
	unselected_style.border_color = Color(0.684, 0.554, 0.256, 0.9)
	unselected_style.corner_radius_top_left = 0
	unselected_style.corner_radius_top_right = 0
	unselected_style.corner_radius_bottom_left = 0
	unselected_style.corner_radius_bottom_right = 0
	tab_bar.add_theme_stylebox_override("tab_unselected", unselected_style)

	var hover_style: = unselected_style.duplicate()
	hover_style.bg_color = Color(0.072, 0.080, 0.079, 0.96)
	tab_bar.add_theme_stylebox_override("tab_hovered", hover_style)

func _create_showcase_card(entry: Variant) -> PanelContainer:
	var data: = _normalize_showcase_entry(entry)
	var item_name: = str(data.get("name", ""))
	var icon_key: = str(data.get("icon", ""))
	var card: = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 96)
	var meta: Dictionary = _resolve_showcase_meta(item_name, icon_key)
	var style: = StyleBoxFlat.new()
	# 奖品格子统一墨底 + 金线：原来每种奖品按类别刷一层彩色半透底
	#（金/绿/棕），九宫格里像九种材质拼贴；类别信息交给图标表达就够了。
	style.bg_color = Color(0.040, 0.048, 0.050, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.947, 0.837, 0.553, 0.38)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	card.add_theme_stylebox_override("panel", style)
	var vb: = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vb)
	var icon: = Label.new()
	icon.text = str(meta.get("icon", "•"))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	vb.add_child(icon)
	var name_label: = Label.new()
	name_label.text = _ellipsis_text(item_name, 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.add_theme_font_size_override("font_size", 16)
	vb.add_child(name_label)

	return card

func _ellipsis_text(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars - 1) + "…"

func _request_draw(pool_type: String) -> void :
	if game_manager != null and game_manager.has_method("local_lottery_draw"):
		if _draw_anim_active:
			return
		_set_buttons_disabled(true)
		_draw_anim_active = true
		_draw_result_ready = false
		_draw_result_data = {}
		_draw_error_msg = ""
		_draw_pool_type = pool_type
		_create_draw_overlay(pool_type)
		var op_id := "local_lottery_%s_%d_%s" % [pool_type, Time.get_ticks_usec(), str(randi())]
		var outcome: Dictionary = game_manager.local_lottery_draw(pool_type, op_id)
		if bool(outcome.get("ok", false)):
			_draw_result_data = outcome
		else:
			_draw_error_msg = str(outcome.get("message", "本地抽奖失败"))
		_draw_result_ready = true
		_play_draw_ceremony(pool_type)
		return
	if _draw_anim_active:
		return
	if not game_manager or not game_manager.network:
		_set_result_text("[color=red]网络未初始化，无法抽奖[/color]")
		return
	if not game_manager.player:
		_set_result_text("[color=red]玩家数据未初始化[/color]")
		return

	if pool_type == "gold" and game_manager.player.gold < _get_pool_cost("gold"):
		_set_result_text("[color=red]金币不足，金币抽奖需要5亿金币[/color]")
		return
	if pool_type == "yuanbao" and game_manager.player.yuanbao_currency < _get_pool_cost("yuanbao"):
		_set_result_text("[color=red]元宝不足，元宝抽奖需要100元宝[/color]")
		return

	_set_buttons_disabled(true)
	_draw_anim_active = true
	_draw_result_ready = false
	_draw_result_data = {}
	_draw_error_msg = ""
	_draw_pool_type = pool_type
	_create_draw_overlay(pool_type)

	var op_id: = "lottery_%s_%s_%s" % [pool_type, str(Time.get_unix_time_from_system()), str(randi())]
	game_manager.network.lottery_draw_success.connect( func(data: Dictionary):
		_draw_result_data = data
		_draw_result_ready = true
		_try_resolve_draw_outcome()
	, CONNECT_ONE_SHOT)
	game_manager.network.lottery_draw_failed.connect( func(error: String):
		_draw_error_msg = error
		_draw_result_ready = true
		_try_resolve_draw_outcome()
	, CONNECT_ONE_SHOT)
	game_manager.network.lottery_draw(pool_type, op_id)
	_play_draw_ceremony(pool_type)
	_start_draw_watchdog()


# 兜底：结算遮罩是全屏 ColorRect（吃掉所有点击），一旦回包没被正确分发
# （历史 bug：带 items 字段的回包被 network.gd 的 xianmo_shop_items 分支截胡），
# 界面会永久停在「正在结算」。这里超时后强制收掉遮罩并给出可读提示。
func _start_draw_watchdog() -> void :
	var waited: = 0.0
	while waited < 20.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5
		if _draw_result_ready:
			return
	if _draw_result_ready:
		return
	_draw_error_msg = "服务器结算超时，请稍后重试（若元宝已扣，奖励会通过邮件补发）"
	_draw_result_ready = true
	_draw_anim_active = false
	_try_resolve_draw_outcome()

func _on_draw_success(pool_type: String, data: Dictionary) -> void :
	_set_buttons_disabled(false)
	_apply_save_data(data)
	_refresh_currency_text()
	if pool_type == "yuanbao":
		var pity_status = data.get("pityStatus", {})
		if pity_status is Dictionary and not pity_status.is_empty():
			_apply_pity_status(pity_status)
		else:

			var threshold: int = int(pity_progress_bar.max_value) if pity_progress_bar else YUANBAO_PITY_THRESHOLD
			var next_count: int = pity_count + 1
			_apply_pity_status({"count": next_count, "threshold": threshold, "canClaim": next_count >= threshold, "options": YUANBAO_PITY_OPTIONS})

		_request_pity_status()

	var reward_name: = str(data.get("rewardName", "未知奖励"))
	var reward_desc: = str(data.get("rewardDesc", ""))
	var text: = "[color=green]抽奖成功：[/color]\n获得物品%s（已发送到邮件）" % reward_name
	if bool(data.get("local_save_applied", false)):
		text = "[color=green]本地抽奖成功：[/color]\n获得%s（已存入背包或金币余额）" % reward_name
	_set_result_text(text)
	var cost_text: String = (str(data.get("cost", 0)) + ("金币" if pool_type == "gold" else "元宝")) if bool(data.get("local_save_applied", false)) else ""
	_show_result_popup(pool_type, reward_name, reward_desc, cost_text)

func _apply_save_data(data: Dictionary) -> void :
	if not data is Dictionary or game_manager == null:
		return
	# 货币要先落，别等 saveData：服务端 /lottery/draw 的成功回包**不带 saveData**
	# （只带 newGold / newYuanbao，见 handlers_growth.lottery_draw 的注释），
	# 原来这里先判 saveData 就直接 return 了，下面两段永远走不到 ——
	# 玩家看到的现象就是「元宝抽奖不即时扣」，回到主城余额还是老数字，
	# 重登一次才变；期间余额不足还会反复点、被服务端「元宝不足」打回。
	if game_manager.player:
		if data.has("newGold"):
			game_manager.player.gold = int(data.get("newGold", game_manager.player.gold))
			game_manager.gold_changed.emit(game_manager.player.gold)
		if data.has("newYuanbao"):
			game_manager.player.yuanbao_currency = int(data.get("newYuanbao", game_manager.player.yuanbao_currency))
			game_manager.yuanbao_changed.emit(game_manager.player.yuanbao_currency)
	var save_data: Variant = data.get("saveData", null)
	if not save_data is Dictionary:
		return
	game_manager.apply_cloud_save(save_data, {
		"preserve_local_pets_not_in_cloud": true, 
		"skip_pet_collection_trim": true, 
		"clamp_inventory_local_consumption": true, 
		"reward_inventory_slice": true, 
		"currency_slice": true, 
		"lottery_pity_slice": true, 
		"debug_tag": "lucky_draw", 
	})
	# apply_cloud_save 可能因为「云端快照较旧」整包跳过，货币上面已经落过了，
	# 这里再对齐一次服务端回包里的权威值（幂等）。
	if game_manager.player and data.has("newYuanbao"):
		game_manager.player.yuanbao_currency = int(data.get("newYuanbao", game_manager.player.yuanbao_currency))
		game_manager.yuanbao_changed.emit(game_manager.player.yuanbao_currency)

func _set_result_text(text: String) -> void :
	if result_label:
		result_label.text = text

func _set_buttons_disabled(disabled: bool) -> void :
	for btn in draw_buttons.values():
		if btn:
			btn.disabled = disabled

func _create_modal_shell(title_text: String, width: float, height: float) -> Dictionary:

	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	var overlay: = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)

	var center: = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, height)
	center.add_child(panel)

	var panel_style: = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.060, 0.068, 0.069, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.947, 0.837, 0.553, 0.95)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 10

	panel_style.content_margin_left = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)

	var root: = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var title: = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.78, 1))
	root.add_child(title)

	var body: = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)

	return {"overlay": overlay, "root": root, "body": body}

func _create_draw_overlay(pool_type: String) -> void :
	if _draw_overlay and is_instance_valid(_draw_overlay):
		_draw_overlay.queue_free()
	var shell: = _create_modal_shell("抽奖进行中", 450.0, 220.0)
	_draw_overlay = shell.get("overlay") as ColorRect
	var body: = shell.get("body") as VBoxContainer

	var subtitle: = Label.new()
	subtitle.text = "金光流转，天机浮现" if pool_type == "gold" else "元宝凝辉，气运汇聚"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850, 1))
	body.add_child(subtitle)

	_draw_anim_label = Label.new()
	_draw_anim_label.text = "正在推演奖池..."
	_draw_anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_draw_anim_label.add_theme_font_size_override("font_size", 18)
	body.add_child(_draw_anim_label)

	var hint: = Label.new()
	hint.text = "请稍候，约1-2秒"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.791, 0.769, 0.708, 0.95))
	body.add_child(hint)

func _play_draw_ceremony(pool_type: String) -> void :
	_run_draw_ceremony_async(pool_type)

func _run_draw_ceremony_async(pool_type: String) -> void :
	var steps: Array = [
		"命盘旋转中", 
		"灵纹共鸣中", 
		"奖池推演中", 
		"气运正在汇聚"
	]
	if pool_type == "yuanbao":
		steps = ["元宝灵气注入", "秘宝气息显化", "稀有轨迹锁定", "吉运即将揭晓"]
	for i in range(7):
		if _draw_anim_label:
			var dots = ".".repeat((i % 3) + 1)
			_draw_anim_label.text = "%s%s" % [steps[i % steps.size()], dots]
		await get_tree().create_timer(0.22).timeout

	if _draw_anim_label:
		_draw_anim_label.text = "天机已定，正在揭晓..."
	await get_tree().create_timer(0.18).timeout

	_draw_anim_active = false
	_try_resolve_draw_outcome()

func _try_resolve_draw_outcome() -> void :
	if _draw_anim_active:
		return
	if not _draw_result_ready:
		if _draw_anim_label:
			_draw_anim_label.text = "正在结算，请稍候..."
		return
	if _draw_overlay and is_instance_valid(_draw_overlay):
		_draw_overlay.queue_free()
		_draw_overlay = null
	_draw_anim_label = null
	_set_buttons_disabled(false)
	if not _draw_error_msg.is_empty():
		var display_error = _draw_error_msg
		if _draw_pool_type == "yuanbao" and _draw_error_msg.find("元宝不足") >= 0 and game_manager and game_manager.player and game_manager.player.yuanbao_currency >= YUANBAO_DRAW_COST:
			display_error += "（本地元宝已变更，但云端余额尚未同步，请稍后重试或重新登录）"
		_set_result_text("[color=red]%s[/color]" % display_error)
		return
	if not _draw_result_data.is_empty():
		_on_draw_success(_draw_pool_type, _draw_result_data)

func _show_probability(pool_type: String) -> void :
	if _popup_overlay and is_instance_valid(_popup_overlay):
		_popup_overlay.queue_free()
	var vsize: = get_viewport_rect().size
	var pw: float = minf(560.0, vsize.x - 40.0)
	var ph: float = minf(620.0, vsize.y - 80.0)
	var shell: = _create_modal_shell("抽奖概率 - %s" % ("金币池" if pool_type == "gold" else "元宝池"), pw, ph)
	_popup_overlay = shell.get("overlay") as ColorRect
	var root: = shell.get("root") as VBoxContainer
	var body: = shell.get("body") as VBoxContainer

	var text_margin: = MarginContainer.new()
	text_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_margin.add_theme_constant_override("margin_left", 14)
	text_margin.add_theme_constant_override("margin_top", 8)
	text_margin.add_theme_constant_override("margin_right", 14)
	text_margin.add_theme_constant_override("margin_bottom", 8)
	body.add_child(text_margin)

	var text: = RichTextLabel.new()
	text.bbcode_enabled = false
	text.fit_content = false
	text.scroll_active = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(maxf(260.0, pw - 90.0), maxf(260.0, ph - 180.0))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("normal_font_size", 20)
	text.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95, 1))
	text.text = _get_probability_text(pool_type)
	text_margin.add_child(text)

	var close_btn: = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(160, 46)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect( func():
		if _popup_overlay and is_instance_valid(_popup_overlay):
			_popup_overlay.queue_free()
			_popup_overlay = null
	)
	root.add_child(close_btn)

func _show_result_popup(pool_type: String, reward_name: String, reward_desc: String, cost_desc: String) -> void :
	var shell: = _create_modal_shell("抽奖结果", 460.0, 380.0)
	var overlay: = shell.get("overlay") as ColorRect
	var root: = shell.get("root") as VBoxContainer
	var body: = shell.get("body") as VBoxContainer

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	var content_width: = 400.0
	var icon: = Label.new()
	icon.text = "🎉" if pool_type == "gold" else "✨"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.custom_minimum_size = Vector2(content_width, 0)
	icon.add_theme_font_size_override("font_size", 36)
	content.add_child(icon)

	var reward_label: = Label.new()
	reward_label.text = "获得：%s" % reward_name
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.custom_minimum_size = Vector2(content_width, 0)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.add_theme_font_size_override("font_size", 24)
	reward_label.add_theme_color_override("font_color", Color(1, 0.92, 0.6, 1))
	content.add_child(reward_label)

	var detail: = Label.new()
	var detail_lines: Array[String] = []
	if not cost_desc.is_empty():
		detail_lines.append("消耗：%s" % cost_desc)
	detail_lines.append(reward_desc if not reward_desc.is_empty() else "请到邮件查收奖励。")
	detail.text = "\n".join(detail_lines)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.custom_minimum_size = Vector2(content_width, 0)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 17)
	detail.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850, 0.95))
	content.add_child(detail)

	var close_btn: = Button.new()
	close_btn.text = "收下奖励"
	close_btn.custom_minimum_size = Vector2(160, 48)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var close_style: = StyleBoxFlat.new()
	close_style.bg_color = Color(0.118, 0.100, 0.058, 0.98)
	close_style.corner_radius_top_left = 0
	close_style.corner_radius_top_right = 0
	close_style.corner_radius_bottom_left = 0
	close_style.corner_radius_bottom_right = 0
	close_style.border_width_left = 1
	close_style.border_width_top = 1
	close_style.border_width_right = 1
	close_style.border_width_bottom = 1
	close_style.border_color = Color(1, 0.82, 0.45, 0.95)
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_hover: = close_style.duplicate()
	close_hover.bg_color = Color(0.118, 0.100, 0.058, 1.0)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.pressed.connect( func():
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
	)
	root.add_child(close_btn)

func _exit_tree() -> void :
	if not game_manager or not game_manager.network:
		return
	var net = game_manager.network
	if net.lottery_pity_status_loaded.is_connected(_on_pity_status_loaded):
		net.lottery_pity_status_loaded.disconnect(_on_pity_status_loaded)
	if net.lottery_pity_status_failed.is_connected(_on_pity_status_failed):
		net.lottery_pity_status_failed.disconnect(_on_pity_status_failed)
	if net.lottery_pity_claim_success.is_connected(_on_pity_claim_success):
		net.lottery_pity_claim_success.disconnect(_on_pity_claim_success)
	if net.lottery_pity_claim_failed.is_connected(_on_pity_claim_failed):
		net.lottery_pity_claim_failed.disconnect(_on_pity_claim_failed)

func _bind_pity_signals() -> void :
	if not game_manager or not game_manager.network:
		return
	var net = game_manager.network
	if not net.lottery_pity_status_loaded.is_connected(_on_pity_status_loaded):
		net.lottery_pity_status_loaded.connect(_on_pity_status_loaded)
	if not net.lottery_pity_status_failed.is_connected(_on_pity_status_failed):
		net.lottery_pity_status_failed.connect(_on_pity_status_failed)
	if not net.lottery_pity_claim_success.is_connected(_on_pity_claim_success):
		net.lottery_pity_claim_success.connect(_on_pity_claim_success)
	if not net.lottery_pity_claim_failed.is_connected(_on_pity_claim_failed):
		net.lottery_pity_claim_failed.connect(_on_pity_claim_failed)

func _request_pity_status() -> void :
	if game_manager != null and game_manager.has_method("local_lottery_pity_status"):
		_apply_pity_status(game_manager.local_lottery_pity_status(), true)
		return
	if not game_manager or not game_manager.network:
		return
	if not pity_sync_done and pity_progress_text_in_bar:
		pity_progress_text_in_bar.text = "同步中…"
	if pity_claim_btn and not pity_sync_done:
		pity_claim_btn.disabled = true
	game_manager.network.lottery_get_pity_status()

func _apply_pity_status(pity_status: Dictionary, allow_decrease: bool = false) -> void :
	pity_sync_done = true
	var next_count: int = int(pity_status.get("count", 0))
	var threshold: int = int(pity_status.get("threshold", YUANBAO_PITY_THRESHOLD))
	if threshold <= 0:
		threshold = YUANBAO_PITY_THRESHOLD
	next_count = maxi(next_count, 0)

	if not allow_decrease and next_count < pity_count:
		return
	pity_count = next_count

	if pity_progress_bar:
		pity_progress_bar.max_value = float(threshold)
		pity_progress_bar.value = float(mini(pity_count, threshold))
	if pity_progress_text_in_bar:
		if pity_count > threshold:
			var claims: int = pity_count / threshold
			pity_progress_text_in_bar.text = "%d（可领%d份）" % [pity_count, claims]
		else:
			pity_progress_text_in_bar.text = "%d/%d" % [pity_count, threshold]

	var options_data: Variant = pity_status.get("options", [])
	if options_data is Array and not options_data.is_empty():
		pity_reward_options = []
		for option_name in options_data:
			pity_reward_options.append(str(option_name))
	if pity_reward_options.is_empty():
		pity_reward_options = YUANBAO_PITY_OPTIONS.duplicate()

	var can_claim: = bool(pity_status.get("canClaim", pity_count >= threshold))
	if pity_claim_btn:
		pity_claim_btn.disabled = ( not can_claim) or pity_claiming
		pity_claim_btn.text = "领取中..." if pity_claiming else "领取保底"

func _on_pity_status_loaded(data: Dictionary) -> void :
	var pity_status = data.get("pityStatus", {})
	if pity_status is Dictionary and not pity_status.is_empty():
		_apply_pity_status(pity_status)
	elif pity_status is Dictionary:

		_apply_pity_status({"count": 0, "threshold": YUANBAO_PITY_THRESHOLD, "canClaim": false, "options": YUANBAO_PITY_OPTIONS})

func _on_pity_status_failed(error: String) -> void :

	var err = error.strip_edges()
	if err.is_empty():
		return
	if err == "保底功能暂不可用":
		return
	if not pity_sync_done and pity_progress_text_in_bar:
		pity_progress_text_in_bar.text = "同步失败，请稍后重试"
	if pity_claim_btn and not pity_sync_done:
		pity_claim_btn.disabled = true
	_set_result_text("[color=yellow]%s[/color]" % err)

func _on_pity_claim_pressed() -> void :
	if pity_claiming:
		return
	var threshold: int = int(pity_progress_bar.max_value) if pity_progress_bar else YUANBAO_PITY_THRESHOLD
	if pity_count < threshold:
		_set_result_text("[color=yellow]保底次数不足，当前 %d/%d[/color]" % [pity_count, threshold])
		return
	if not game_manager or (not game_manager.has_method("local_lottery_claim") and not game_manager.network):
		_set_result_text("[color=red]网络未初始化[/color]")
		return
	_show_pity_claim_popup()

func _show_pity_claim_popup() -> void :
	var shell: = _create_modal_shell("领取保底奖励", 440.0, 420.0)
	var overlay: = shell.get("overlay") as ColorRect
	var root: = shell.get("root") as VBoxContainer
	var body: = shell.get("body") as VBoxContainer

	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var content: = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	var hint: = Label.new()
	hint.text = "已达100次保底，请点选1份奖励（邮件发放）"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.custom_minimum_size = Vector2(380, 0)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850, 1))
	content.add_child(hint)

	var options_to_show: Array = pity_reward_options if not pity_reward_options.is_empty() else YUANBAO_PITY_OPTIONS
	var selected_name: = {"value": ""}
	var option_buttons: Array = []

	var normal_style: = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.072, 0.080, 0.079, 0.96)
	normal_style.corner_radius_top_left = 0
	normal_style.corner_radius_top_right = 0
	normal_style.corner_radius_bottom_left = 0
	normal_style.corner_radius_bottom_right = 0
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.873, 0.743, 0.432, 0.9)

	var selected_style: = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.118, 0.100, 0.058, 0.98)
	selected_style.corner_radius_top_left = 0
	selected_style.corner_radius_top_right = 0
	selected_style.corner_radius_bottom_left = 0
	selected_style.corner_radius_bottom_right = 0
	selected_style.border_width_left = 1
	selected_style.border_width_top = 1
	selected_style.border_width_right = 1
	selected_style.border_width_bottom = 1
	selected_style.border_color = Color(1, 0.82, 0.45, 0.95)

	var confirm_btn: = Button.new()
	confirm_btn.text = "确认领取"
	confirm_btn.disabled = true
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	confirm_btn.add_theme_font_size_override("font_size", 18)

	var apply_option_visuals: = func() -> void :
		for child in option_buttons:
			if not (child is Button) or not is_instance_valid(child):
				continue
			var b: = child as Button
			var is_sel: = str(b.get_meta("pity_option_name", "")) == str(selected_name.get("value", ""))
			var st: StyleBoxFlat = selected_style if is_sel else normal_style
			b.add_theme_stylebox_override("normal", st)
			b.add_theme_stylebox_override("hover", st)
			b.add_theme_stylebox_override("pressed", selected_style)

	for option_name in options_to_show:
		var opt_text: = str(option_name).strip_edges()
		if opt_text.is_empty():
			continue
		var opt_btn: = Button.new()
		opt_btn.text = opt_text
		opt_btn.focus_mode = Control.FOCUS_NONE
		opt_btn.custom_minimum_size = Vector2(0, 48)
		opt_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opt_btn.add_theme_font_size_override("font_size", 17)
		opt_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		opt_btn.add_theme_stylebox_override("normal", normal_style)
		opt_btn.add_theme_stylebox_override("hover", normal_style)
		opt_btn.add_theme_stylebox_override("pressed", selected_style)
		opt_btn.add_theme_stylebox_override("disabled", normal_style)
		opt_btn.set_meta("pity_option_name", opt_text)

		TouchScrollUtils.bind_tap(opt_btn, func():
			selected_name["value"] = opt_text
			confirm_btn.disabled = false
			apply_option_visuals.call()
		)
		content.add_child(opt_btn)
		option_buttons.append(opt_btn)

	var btn_row: = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	root.add_child(btn_row)

	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	var cancel_style: = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.072, 0.080, 0.079, 0.95)
	cancel_style.corner_radius_top_left = 0
	cancel_style.corner_radius_top_right = 0
	cancel_style.corner_radius_bottom_left = 0
	cancel_style.corner_radius_bottom_right = 0
	cancel_style.border_width_left = 1
	cancel_style.border_width_top = 1
	cancel_style.border_width_right = 1
	cancel_style.border_width_bottom = 1
	cancel_style.border_color = Color(0.915, 0.797, 0.502, 0.95)
	cancel_btn.add_theme_stylebox_override("normal", cancel_style)
	var cancel_hover: = cancel_style.duplicate()
	cancel_hover.bg_color = Color(0.072, 0.080, 0.079, 0.98)
	cancel_btn.add_theme_stylebox_override("hover", cancel_hover)
	cancel_btn.pressed.connect( func():
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
	)
	btn_row.add_child(cancel_btn)

	var confirm_style: = StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.118, 0.100, 0.058, 0.98)
	confirm_style.corner_radius_top_left = 0
	confirm_style.corner_radius_top_right = 0
	confirm_style.corner_radius_bottom_left = 0
	confirm_style.corner_radius_bottom_right = 0
	confirm_style.border_width_left = 1
	confirm_style.border_width_top = 1
	confirm_style.border_width_right = 1
	confirm_style.border_width_bottom = 1
	confirm_style.border_color = Color(1, 0.82, 0.45, 0.95)
	confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	var confirm_hover: = confirm_style.duplicate()
	confirm_hover.bg_color = Color(0.118, 0.100, 0.058, 1.0)
	confirm_btn.add_theme_stylebox_override("hover", confirm_hover)
	confirm_btn.pressed.connect( func():
		if pity_claiming:
			return
		if options_to_show.is_empty():
			_set_result_text("[color=red]暂无可选保底奖励[/color]")
			return
		var reward_name: String = str(selected_name.get("value", "")).strip_edges()
		if reward_name.is_empty():
			_set_result_text("[color=red]请先选择保底奖励[/color]")
			return
		pity_claiming = true
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
		_apply_pity_status({"count": pity_count, "threshold": int(pity_progress_bar.max_value), "canClaim": true, "options": pity_reward_options})
		var op_id: = "lottery_pity_claim_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
		if game_manager.has_method("local_lottery_claim"):
			var outcome: Dictionary = game_manager.local_lottery_claim(reward_name, op_id)
			if bool(outcome.get("ok", false)):
				_on_pity_claim_success(outcome)
			else:
				_on_pity_claim_failed(str(outcome.get("message", "领取失败")))
		else:
			game_manager.network.lottery_claim_pity_reward(reward_name, op_id)
	)
	btn_row.add_child(confirm_btn)

func _on_pity_claim_success(data: Dictionary) -> void :
	pity_claiming = false
	var pity_status = data.get("pityStatus", {})
	if pity_status is Dictionary and not pity_status.is_empty():
		_apply_pity_status(pity_status, true)
	else:
		_request_pity_status()
	var reward_name: = str(data.get("rewardName", "保底奖励"))
	var local: bool = bool(data.get("local_save_applied", false))
	_set_result_text(("[color=green]保底领取成功：%s（已存入本地背包）[/color]" if local else "[color=green]保底领取成功：%s（已通过邮件发放）[/color]") % reward_name)
	_show_result_popup("yuanbao", reward_name, "保底奖励已存入本地背包。" if local else "保底奖励已发放，请到邮件查收。", "保底领取")

func _on_pity_claim_failed(error: String) -> void :
	pity_claiming = false
	_request_pity_status()
	var err = error.strip_edges()
	if err.is_empty():
		err = "保底领取失败"
	_set_result_text("[color=red]%s[/color]" % err)
