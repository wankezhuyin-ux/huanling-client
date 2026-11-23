extends "res://ui/main_ui.gd"

# Presentation layer only. Every destination uses the existing MainUI routes.
var _ink_home: Control
var _ink_back: Button
var _ink_name: Label
var _ink_resources: Label
var _ink_pet_name: Label
var _ink_map: Label
var _ink_pet: TextureRect
var _ink_last_pet: String = ""
var _ink_realm: Label
var _ink_hp_bar: ProgressBar
var _ink_mp_bar: ProgressBar
var _ink_hud_watch: Timer
var _ink_hud_watch_ticks: int = 0
var _ink_hud_seen_blocked: bool = false
var _ink_hud_idle_ticks: int = 0

# 首页皮（洞府那层：角色名 · 境界 · 洞府 · 金币元宝 · HP/MP · 飞升/投胎）当前该不该显示。
# 这是一份**唯一权威**的状态：所有地方都只改这个布尔，再由 _ink_apply_home_visibility()
# 统一落到 _ink_home.visible 上。
# 之所以要这样：之前 _ink_sync_startup_hud 每 0.1 秒无脑写 _ink_home.visible = true，
# 玩家切到战斗页后它又被铺回来，于是战斗页左上角叠出一层
# 「emutest · Lv.399 / 凡人 / 飞升 / 投胎 / 金币 1756066」压在顶栏上 —— 就是玩家说的"乱七八糟"。
var _ink_home_wanted: bool = true
# _ready 里的首次 _show_view("battle") 是在铺首页，不算"离开洞府"，用这个标记区分。
var _ink_boot_done: bool = false
# _ink_show_home() 内部会调 _ink_enter("battle")，这条路不能把首页皮收掉。
var _ink_showing_home: bool = false

# 兜底：最多盯 5 分钟。启动弹窗关掉后 3 秒也会自动收工，不会长期空转。
const INK_HUD_WATCH_MAX_TICKS: int = 3000
const INK_HUD_IDLE_STOP_TICKS: int = 30


func _ready():
	_ink_apply_viewport()
	# main_ui 是父类。热更时只有本文件（ink_home.gd）能真正被 pck 覆盖，
	# 父类那份会命中启动早期建立的资源缓存、仍然是底包里的旧脚本，
	# 所以这里把它的运行时状态打出来，线上排查一眼就能看出用的是哪一份。
	print("[INK] main_ui_state has_pending_member=%s has_game_started=%s"
		% [str(get("_startup_offline_pending") != null), str(get("_game_started") != null)])
	super._ready()
	_ink_build()
	var refresh := Timer.new()
	refresh.wait_time = 0.5
	refresh.timeout.connect(_ink_refresh)
	add_child(refresh)
	refresh.start()
	# 必须在这里就开始盯：_start_game() 要等玩家点「进入游戏」才触发，
	# 而离线奖励面板在那之前就弹出来了，晚一步就是「面板背后一堆按钮」。
	_ink_watch_startup_hud()
	_ink_boot_done = true

func _start_game():
	await super._start_game()
	# 玩家点完「进入游戏」：这一刻起界面才算真正进主城，
	# 但启动弹窗也可能刚关，交给轮询对账即可，这里只补一次立即同步。
	_ink_sync_startup_hud()


func _ink_watch_startup_hud() -> void:
	if _ink_hud_watch != null and is_instance_valid(_ink_hud_watch):
		_ink_hud_watch.start()
		return
	_ink_hud_watch_ticks = 0
	_ink_hud_seen_blocked = false
	_ink_hud_idle_ticks = 0
	_ink_hud_watch = Timer.new()
	_ink_hud_watch.wait_time = 0.1
	_ink_hud_watch.timeout.connect(_ink_sync_startup_hud)
	add_child(_ink_hud_watch)
	_ink_hud_watch.start()


func _ink_sync_startup_hud() -> void:
	_ink_hud_watch_ticks += 1
	var blocked: bool = _ink_startup_blocked()
	if blocked:
		_ink_hud_seen_blocked = true
		_ink_hud_idle_ticks = 0
	else:
		_ink_hud_idle_ticks += 1
	# 只做"对账"，不自己做决定：首页皮该不该显示完全由 _ink_home_wanted 说了算。
	_ink_apply_home_visibility()
	if is_instance_valid(_ink_back) and _ink_back.visible:
		_ink_back.visible = false
	var stop_now: bool = _ink_hud_watch_ticks >= INK_HUD_WATCH_MAX_TICKS
	if not stop_now and _ink_hud_seen_blocked and _ink_hud_idle_ticks >= INK_HUD_IDLE_STOP_TICKS:
		stop_now = true
	if stop_now:
		# 收工这一拍**不能**再调 _ink_show_home()：玩家早就切到别的界面了，
		# 那一下会把首页皮强行盖回来（正是本轮修掉的左上角重影）。
		_ink_apply_home_visibility()
		if _ink_hud_watch != null and is_instance_valid(_ink_hud_watch):
			_ink_hud_watch.stop()


# 首页皮可见性的唯一落地口：wanted 且不在启动弹窗里 → 显示，否则一律收起。
func _ink_apply_home_visibility() -> void:
	if not is_instance_valid(_ink_home):
		return
	var should_show: bool = _ink_home_wanted and not _ink_startup_blocked()
	if _ink_home.visible != should_show:
		_ink_home.visible = should_show


func _ink_startup_blocked() -> bool:
	# 这里**绝对不能**直接写 `_startup_offline_pending`。
	# 热更包里的脚本是二进制 token（script_export_mode=2），子类引用父类成员是
	# 编译期绑定；父类那份一旦在目标机上解析不到，整个 ink_home.gd 就
	#   Compile Error: Identifier not found: _startup_offline_pending
	# 直接编译失败 → main_ui 建不出来 → 只剩清屏色 = 黑屏。
	# （2026-10-25 手机登录黑屏就是这个）
	# 改成动态取值：拿不到就当 false，永远不会在编译期炸。
	if is_instance_valid(startup_dialog):
		return true
	# 兜底：启动期的几个面板（离线奖励 / 欢迎回来 / 建角色）都是 Window，
	# 直接看有没有可见的 Window，不依赖父类成员名是否存在——
	# 手机上跑的是底包那份旧 main_ui，成员名可能对不上，但 Window 一定有。
	for child in get_children():
		if child is Window and (child as Window).visible:
			return true
	var pending: Variant = get("_startup_offline_pending")
	if pending is bool:
		return pending
	if pending is int or pending is float:
		return float(pending) != 0.0
	return false


func _hide_game_hud_for_startup_dialog() -> void:
	super._hide_game_hud_for_startup_dialog()
	# 首页皮的头部（角色名·境界·洞府 / 金币元宝 / HP MP / 飞升投胎 / 竞技 / 邮件）
	# 不是 top_bar 的子节点，必须单独藏，否则会从弹窗背后露出来。
	_ink_apply_home_visibility()
	if is_instance_valid(_ink_back):
		_ink_back.visible = false

func _restore_game_hud_after_startup() -> void:
	super._restore_game_hud_after_startup()
	# 启动弹窗流程异常超时后，把首页皮也铺回来（否则只剩底部导航，一片空）。
	# 走统一判定：玩家已经切走了就不再铺回来。
	_ink_apply_home_visibility()
	if is_instance_valid(_ink_back):
		_ink_back.visible = false

func _ink_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _ink_button(text_value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(110, 62)
	var ink := Color("29463c")
	var paper := Color("f3ecdd")
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", paper if primary else ink)
	button.add_theme_color_override("font_hover_color", paper if primary else ink)
	button.add_theme_color_override("font_pressed_color", paper if primary else ink)
	button.add_theme_stylebox_override("normal", _ink_style(Color(0.15, 0.28, 0.23, 0.94) if primary else Color(0.97, 0.94, 0.87, 0.91), Color(0.34, 0.45, 0.35, 0.60)))
	button.add_theme_stylebox_override("hover", _ink_style(Color(0.20, 0.38, 0.30, 0.98) if primary else Color(1.0, 0.98, 0.91, 0.98), Color("617d65")))
	button.add_theme_stylebox_override("pressed", _ink_style(Color(0.12, 0.24, 0.19, 1.0) if primary else Color(0.85, 0.87, 0.77, 0.98), ink))
	button.pressed.connect(action)
	return button

func _ink_label(text_value: String, font_size: int, color: Color = Color("29463c")) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# 与线上客户端一致的血量/法力条：底层 ProgressBar + 居中数值文字
func _ink_bar(parent: Control, fill_color: Color, caption: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 34)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.max_value = 100
	bar.value = 100
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.10, 0.14, 0.12, 0.50)
	background.border_color = Color(0.36, 0.46, 0.34, 0.55)
	background.set_border_width_all(1)
	background.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	var label := _ink_label(caption, 17, Color("f3ecdd"))
	label.name = "Caption"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)
	parent.add_child(bar)
	return bar

# 境界与 HP/MP 需要脱离首页可见性刷新：战斗界面里也要跟着变
func _ink_refresh_vitals() -> void:
	if game_manager == null or game_manager.player == null:
		return
	var p = game_manager.player
	if is_instance_valid(_ink_realm):
		_ink_realm.text = str(p.realm)
	if is_instance_valid(_ink_hp_bar):
		var max_hp: int = maxi(1, p.get_max_hp())
		_ink_hp_bar.max_value = max_hp
		_ink_hp_bar.value = clampi(int(p.hp), 0, max_hp)
		var hp_caption := _ink_hp_bar.get_node_or_null("Caption") as Label
		if hp_caption != null:
			hp_caption.text = "HP %d/%d" % [int(p.hp), max_hp]
	if is_instance_valid(_ink_mp_bar):
		var max_mp: int = maxi(1, p.get_max_mp())
		_ink_mp_bar.max_value = max_mp
		_ink_mp_bar.value = clampi(int(p.mp), 0, max_mp)
		var mp_caption := _ink_mp_bar.get_node_or_null("Caption") as Label
		if mp_caption != null:
			mp_caption.text = "MP %d/%d" % [int(p.mp), max_mp]

func _open_mist_ferry() -> void:
	if _ink_home.has_node("MistFerry"):
		return
	var ferry := preload("res://ui/mist_ferry.gd").new()
	ferry.name = "MistFerry"
	_ink_home.add_child(ferry)
	ferry.z_index = 1
	ferry.lanterns[0].grab_focus()

func _ink_build() -> void:
	_ink_home = Control.new()
	_ink_home.name = "InkHome"
	_ink_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink_home.z_index = 20
	add_child(_ink_home)
	var background := TextureRect.new()
	background.texture = load("res://art/runtime/ink-home.res")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_home.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.offset_left = 28
	margin.offset_right = -28
	margin.offset_top = 30
	_ink_home.add_child(margin)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	margin.add_child(header)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	_ink_name = _ink_label("道友", 28)
	_ink_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ink_name.clip_text = true
	_ink_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header_row.add_child(_ink_name)
	# 与线上首页一致：名字右侧显示境界
	_ink_realm = _ink_label("凡人", 24, Color("4a6150"))
	header_row.add_child(_ink_realm)
	header_row.add_child(_ink_label("洞 府", 34))
	# 与线上首页一致：货币行（线上此处还有"同步:正常"，本地为纯离线存档，不伪造同步状态）
	var resources_row := HBoxContainer.new()
	header.add_child(resources_row)
	_ink_resources = _ink_label("", 21)
	_ink_resources.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_row.add_child(_ink_resources)
	# 与线上首页一致：HP / MP 两条状态条
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 12)
	header.add_child(bars)
	_ink_hp_bar = _ink_bar(bars, Color("b8433a"), "HP")
	_ink_mp_bar = _ink_bar(bars, Color("c8a13a"), "MP")
	# 与线上首页一致：飞升 / 投胎 入口（本地模式已在 ink_home 里做了本地结算实现）
	var realm_actions := HBoxContainer.new()
	realm_actions.add_theme_constant_override("separation", 10)
	header.add_child(realm_actions)
	var ascend_btn := _ink_button("飞 升", _on_character_realm_ascend_pressed)
	ascend_btn.custom_minimum_size = Vector2(104, 48)
	ascend_btn.add_theme_font_size_override("font_size", 20)
	realm_actions.add_child(ascend_btn)
	var reincarnate_btn := _ink_button("投 胎", _on_character_realm_reincarnate_pressed)
	reincarnate_btn.custom_minimum_size = Vector2(104, 48)
	reincarnate_btn.add_theme_font_size_override("font_size", 20)
	realm_actions.add_child(reincarnate_btn)
	var task := _ink_button("竞技", _ink_open_city_detail.bind("_on_quest_btn_pressed"))
	realm_actions.add_child(task)
	var mail := _ink_button("邮件", _ink_open_city_detail.bind("_on_mail_btn_pressed"))
	realm_actions.add_child(mail)
	var ferry := _ink_button("雾渡引灯", _open_mist_ferry, true)
	realm_actions.add_child(ferry)
	_ink_pet = TextureRect.new()
	_ink_pet.texture = load("res://art/runtime/deer-hero.res")
	_ink_pet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ink_pet.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ink_pet.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_ink_pet.offset_left = -240
	_ink_pet.offset_right = 140
	_ink_pet.offset_top = -90
	_ink_pet.offset_bottom = 290
	_ink_pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_home.add_child(_ink_pet)
	var footer_paper := Panel.new()
	footer_paper.name = "FooterPaper"
	footer_paper.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_paper.offset_left = 16
	footer_paper.offset_right = -16
	footer_paper.offset_top = -305
	footer_paper.offset_bottom = -12
	footer_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_paper.add_theme_stylebox_override("panel", _ink_style(Color(0.97, 0.94, 0.86, 0.88), Color(0.36, 0.46, 0.34, 0.30)))
	_ink_home.add_child(footer_paper)
	var footer := VBoxContainer.new()
	footer.name = "HomeFooter"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 28
	footer.offset_right = -28
	footer.offset_top = -285
	footer.offset_bottom = -22
	footer.add_theme_constant_override("separation", 12)
	_ink_home.add_child(footer)
	_ink_pet_name = _ink_label("随行灵兽", 23)
	footer.add_child(_ink_pet_name)
	_ink_map = _ink_label("", 18, Color("596b58"))
	footer.add_child(_ink_map)
	var explore := _ink_button("出 发 历 练", _ink_enter.bind("battle"), true)
	explore.custom_minimum_size.y = 70
	footer.add_child(explore)
	var nav := HBoxContainer.new()
	nav.name = "HomeNavigation"
	nav.add_theme_constant_override("separation", 9)
	footer.add_child(nav)
	for destination in [["角色", "character"], ["主城", "city"], ["灵兽", "pet"], ["历练", "battle"], ["背包", "bag"]]:
		var button := _ink_button(destination[0], _ink_enter.bind(destination[1]))
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(button)
	_ink_back = _ink_button("返 回 洞 府", _ink_show_home)
	_ink_back.name = "ReturnToInkHome"
	_ink_back.position = Vector2(28, 11)
	_ink_back.custom_minimum_size = Vector2(128, 40)
	_ink_back.add_theme_font_size_override("font_size", 18)
	_ink_back.z_index = 30
	_ink_back.visible = false
	add_child(_ink_back)

func _ink_refresh() -> void:
	if game_manager != null and game_manager.initialized and game_manager.has_method("local_auto_allocate"):
		game_manager.local_auto_allocate()
	if game_manager != null and game_manager.player != null and game_manager.has_method("local_double_exp_count"):
		var title = get_node_or_null("MainContent/BattleView/BattlePanel/BattleTitle")
		if title != null:
			# 参考稿标题就是「⚔️ 战斗区域」（main_ui.tscn 里原本就是这个字面量），
			# 左边那个「✕✕」不是按钮、也不是我们多画的，是 ⚔️ 这个符号在参考稿字体下的长相
			# —— 参考稿截图同一位置也是一样的两把交叉剑。之前我误当成缺字方块把它删了，现在还原。
			# 别往标题上再糊经验丹倍数，经验丹状态挂在 tooltip 上就够了。
			title.text = "⚔ 战斗区域"
			title.tooltip_text = game_manager.local_double_exp_status()
	_ink_refresh_vitals()
	if _ink_home == null or not _ink_home.visible or game_manager == null or game_manager.player == null:
		return
	var player = game_manager.player
	_ink_name.text = "%s · Lv.%d" % [player.player_name, player.level]
	_ink_name.tooltip_text = _ink_name.text
	_ink_resources.text = "金币  %s     ·     元宝  %s" % [str(player.gold), str(player.yuanbao_currency)]
	_ink_map.text = "当前历练 · " + str(game_manager.current_map)
	var pet = game_manager.pet_manager.active_pet if game_manager.pet_manager else null
	if pet == null:
		_ink_pet.visible = false
		_ink_pet_name.text = "暂无出战灵兽"
		return
	_ink_pet.visible = true
	var pet_id := str(pet.pet_id)
	_ink_pet_name.text = "随行灵兽 · %s  Lv.%d" % ["云栖鹿" if pet_id == "kǔxínggūi" else str(pet.pet_name), pet.level]
	if pet_id != _ink_last_pet:
		_ink_last_pet = pet_id
		var texture: Texture2D = load("res://art/runtime/deer-hero.res") if pet_id == "kǔxínggūi" else AssetManager.get_instance().get_pet_texture(pet_id)
		_ink_pet.texture = texture

func _ink_show_home() -> void:
	# "返回洞府" = 明确声明"我现在就在洞府"，所以先立旗再切视图。
	_ink_showing_home = true
	_ink_enter("battle")
	_ink_showing_home = false
	_ink_home_wanted = true
	if is_instance_valid(_ink_back):
		_ink_back.visible = false
	_ink_apply_home_visibility()

func _ink_enter(destination: String) -> void:
	# 从首页皮上点任何一个入口（出发历练 / 角色 / 主城 / 灵兽 / 历练 / 背包 / 竞技 / 邮件）
	# 都算离开洞府：首页皮必须跟着收起来，否则它会一直盖在目标界面上。
	_ink_home_wanted = false
	if _is_challenge_view_locked() and destination != "battle":
		_show_view(destination)
		_ink_apply_home_visibility()
		return
	_show_view(destination)
	# 不管 _show_view 有没有真的切过去，首页皮都要收起来。
	# 之前是「先判断 current_view == destination 再收」，登录流程里 _show_view 会
	# 因为还没 _start_game 完而切不过去，首页皮就一直挂在画面上（弹窗背后那堆信息）。
	_ink_apply_home_visibility()
	if current_view != destination:
		return
	_ink_back.visible = false
	top_bar.visible = true
	main_content.visible = true
	bottom_nav.visible = true
	if destination == "battle" and _ink_is_local_preview() and not game_manager.in_battle:
		game_manager.prepare_local_encounter()
		_setup_battle_sprites()
		_update_monster_ui()

func _ink_open_city_detail(method: String) -> void:
	_ink_enter("city")
	if current_view != "city" or _ink_home.visible:
		return
	await get_tree().process_frame
	if _current_city_ui != null and _current_city_ui.has_method(method):
		_current_city_ui.call(method)

func _ink_apply_viewport() -> void:
	var window := get_tree().root
	window.content_scale_size = Vector2i(720, 1280)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_factor = 1.0
	print("INK_VIEWPORT window=" + str(window.size) + " design=" + str(window.content_scale_size) + " factor=" + str(window.content_scale_factor))

func _add_qq_group_label():
	super._add_qq_group_label()

func _ink_layout_report() -> Dictionary:
	var bounds := get_viewport_rect()
	var navigation := _ink_home.get_node("HomeFooter/HomeNavigation") as Control
	var nav_bounds := navigation.get_global_rect()
	return {
		"viewport": [bounds.size.x, bounds.size.y],
		"design_size": [get_tree().root.content_scale_size.x, get_tree().root.content_scale_size.y],
		"scale_factor": get_tree().root.content_scale_factor,
		"nav": [nav_bounds.position.x, nav_bounds.position.y, nav_bounds.size.x, nav_bounds.size.y],
		"nav_buttons": navigation.get_child_count(),
		"nav_inside_viewport": bounds.encloses(nav_bounds),
		"home_visible": _ink_home.visible,
	}


func _ink_is_local_preview() -> bool:
	return str(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://dev/local_preview.tscn"

func _create_game_manager() -> Node:
	if _ink_is_local_preview():
		return load("res://dev/local_battle_manager.gd").new()
	return super._create_game_manager()

func _start_auto_battle() -> bool:
	if _ink_is_local_preview():
		return game_manager.start_battle()
	return super._start_auto_battle()

func _on_stop_or_start_battle_pressed():
	if not _ink_is_local_preview():
		super._on_stop_or_start_battle_pressed()
		return
	if auto_battle:
		auto_battle = false
		game_manager.set_auto_battle_enabled(false)
		if game_manager.in_battle:
			game_manager.cancel_local_battle()
		_refresh_stop_or_start_battle_btn_text()
		return
	auto_battle = true
	game_manager.set_auto_battle_enabled(true)
	_battle_cooldown_deadline_ms = Time.get_ticks_msec() + 1000
	_start_auto_battle()
	_refresh_stop_or_start_battle_btn_text()


# The new deer source faces the opposite way to the original creature sheets.
func _populate_battle_sprite_slot(
	slot: Control, sprite_id: String, mirror_x: bool, fallback_tex: Texture2D,
	slot_size: Vector2 = BATTLE_SPRITE_SLOT_SIZE,
	attack_duration: float = MONSTER_ATTACK_DURATION,
	sprite_node_name: String = "MonsterSprite",
	static_display_size: Vector2 = BATTLE_STATIC_SPRITE_SIZE
) -> Node:
	var corrected_mirror := not mirror_x if sprite_id.to_lower() == "kǔxínggūi" else mirror_x
	var unit: Node = super._populate_battle_sprite_slot(slot, sprite_id, corrected_mirror, fallback_tex, slot_size, attack_duration, sprite_node_name, static_display_size)
	if unit != null:
		unit.set_meta("ink_deer", sprite_id.to_lower() == "kǔxínggūi")
		if sprite_id.to_lower() == "kǔxínggūi" and unit is Node2D:
			var base_scale: Vector2 = unit.scale
			var breathe := unit.create_tween().set_loops()
			breathe.tween_property(unit, "scale", base_scale * Vector2(1.012, 1.025), 1.2).set_trans(Tween.TRANS_SINE)
			breathe.tween_property(unit, "scale", base_scale, 1.2).set_trans(Tween.TRANS_SINE)
	return unit

func _set_ally_pet_sprite_mirror(sprite: Node, slot: Control, mirror_x: bool) -> void:
	var corrected_mirror := not mirror_x if is_instance_valid(sprite) and bool(sprite.get_meta("ink_deer", false)) else mirror_x
	super._set_ally_pet_sprite_mirror(sprite, slot, corrected_mirror)

func _can_spend_player_attr_via_server() -> bool:
	if _ink_is_local_preview():
		return game_manager != null and game_manager.player != null
	return super._can_spend_player_attr_via_server()

func _ink_finish_local_attributes() -> void:
	var saved: bool = game_manager.save_game()
	_add_log("[color=green]属性已保存到本地[/color]" if saved else "[color=red]本地存档写入失败，请检查存档目录[/color]")
	_notify_player_attr_changed("local_attributes")

func _player_attr_spend_async(func_name: String, count: int) -> void:
	if not _ink_is_local_preview():
		await super._player_attr_spend_async(func_name, count)
		return
	if _stat_key_from_add_func(func_name).is_empty() or count <= 0:
		return
	var p = game_manager.player
	if count > p.points:
		_add_log("[color=red]可用属性点不足[/color]")
		return
	p.set_attr_mutation_allowed(true)
	for i in range(count):
		p.call(func_name)
	p.set_attr_mutation_allowed(false)
	_ink_finish_local_attributes()

func _player_attr_save_auto_plan_async(enabled: bool, plan: Dictionary, dialog: Window) -> void:
	if not _ink_is_local_preview():
		await super._player_attr_save_auto_plan_async(enabled, plan, dialog)
		return
	var total := 0
	for key in ["vitality", "attack", "defense", "magic", "agility"]:
		var value := int(plan.get(key, 0))
		if value < 0:
			return
		total += value
	if total > 10 or (enabled and total == 0):
		_add_log("[color=red]加点方案总数须为1至10点[/color]")
		return
	_apply_local_auto_allocation_settings(enabled, plan)
	var p = game_manager.player
	if enabled:
		p._route_points_to_pending_auto_if_enabled()
	else:
		p.points += p.pending_auto_points
		p.pending_auto_points = 0
	game_manager.local_auto_allocate()
	_ink_finish_local_attributes()
	if is_instance_valid(dialog):
		dialog.queue_free()

func _player_attr_auto_allocate_async() -> void:
	if not _ink_is_local_preview():
		await super._player_attr_auto_allocate_async()
		return
	var p = game_manager.player
	p.set_attr_mutation_allowed(true)
	for message in p.auto_allocate_pending_points():
		_add_log(str(message))
	p.set_attr_mutation_allowed(false)
	_ink_finish_local_attributes()

func _player_attr_auto_allocate_after_level_up_async() -> void:
	if not _ink_is_local_preview():
		await super._player_attr_auto_allocate_after_level_up_async()
		return
	if _player_attr_meets_auto_allocate_threshold(game_manager.player):
		await _player_attr_auto_allocate_async()

func _show_batch_use_dialog(item):
	if not _ink_is_local_preview():
		super._show_batch_use_dialog(item)
		return
	if item == null:
		return
	var item_id: String = str(item.id)
	var shop = load("res://ui/city/shop_ui.gd")
	shop._show_quantity_cost_dialog(self, "本地批量使用 " + str(item.name), mini(999, int(item.count)), 0, "", func(quantity: int):
		var result: Dictionary = await game_manager.local_use_item(item_id, quantity)
		_update_bag_view()
		_update_player_ui()
		_update_pet_ui()
		_show_simple_dialog("使用成功" if bool(result.get("success", false)) else "使用失败", str(result.get("message", "")))
	)


func _on_character_realm_ascend_pressed(ascend_btn: Button = null) -> void:
	if not _ink_is_local_preview():
		await super._on_character_realm_ascend_pressed(ascend_btn)
		return
	var result: Dictionary = game_manager.local_realm_transition("ascend")
	_notify_player_attr_changed("local_realm")
	_show_simple_dialog("本地飞升", str(result.get("message", "")))

func _on_character_realm_reincarnate_pressed(reincarnate_btn: Button = null) -> void:
	if not _ink_is_local_preview():
		await super._on_character_realm_reincarnate_pressed(reincarnate_btn)
		return
	var result: Dictionary = game_manager.local_realm_transition("reincarnate")
	_notify_player_attr_changed("local_realm")
	_show_simple_dialog("本地投胎", str(result.get("message", "")))

func _on_ascend_pressed():
	if _ink_is_local_preview():
		await _on_character_realm_ascend_pressed()
	else:
		await super._on_ascend_pressed()

func _on_reincarnate_pressed():
	if _ink_is_local_preview():
		await _on_character_realm_reincarnate_pressed()
	else:
		await super._on_reincarnate_pressed()

# All battle navigation (including the original bottom navigation) starts combat.
func _show_view(view_name: String, city_skip_reset: bool = false):
	# 底部导航（战斗/角色/主城/宠物/背包）绕过 _ink_enter 直接调 _show_view，
	# 所以这里也要把"离开洞府"记下来，否则玩家点底部「战斗」后首页皮还盖在上面。
	# _ready 里铺首页的那一次 _show_view("battle") 发生在 _ink_boot_done 之前，不算离开。
	if _ink_boot_done and not _ink_showing_home:
		_ink_home_wanted = false
	super._show_view(view_name, city_skip_reset)
	call_deferred("_local_restore_original_navigation")
	if view_name == "battle" and _ink_is_local_preview():
		call_deferred("_local_auto_enter_battle")

func _local_auto_enter_battle() -> void:
	if current_view != "battle" or game_manager == null or not game_manager.initialized:
		return
	for arg in OS.get_cmdline_user_args():
		if arg == "--smoke" or (arg.ends_with("-test") and arg != "--auto-entry-test"):
			return
	auto_battle = true
	game_manager.set_auto_battle_enabled(true)
	if not game_manager.in_battle:
		_start_auto_battle()
	_refresh_stop_or_start_battle_btn_text()

func _local_restore_original_navigation() -> void:
	if not is_instance_valid(bottom_nav):
		return
	bottom_nav.visible = true
	bottom_nav.modulate = Color.WHITE
	bottom_nav.z_index = 40
	# 这里以前是"无条件把首页皮收掉"，会跟 _ink_show_home() 打架
	# （返回洞府刚铺上，这一拍 deferred 又给收了）。现在统一走判定。
	_ink_apply_home_visibility()
	if OS.has_feature("web"):
		var bounds := get_viewport_rect().size
		var bottom := bounds.y - global_position.y - 64.0
		bottom_nav.set_anchors_preset(Control.PRESET_TOP_LEFT)
		bottom_nav.position = Vector2(0, bottom - 140.0)
		bottom_nav.size = Vector2(bounds.x, 140.0)
		main_content.set_anchor(SIDE_BOTTOM, 0.0)
		main_content.offset_bottom = bottom - 150.0
	print("ORIGINAL_NAV_VISIBLE=", bottom_nav.visible, " RECT=", bottom_nav.get_global_rect())
