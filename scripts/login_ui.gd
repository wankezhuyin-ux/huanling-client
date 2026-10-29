extends Control

signal login_success(user_id, nickname, save_data, token)
signal switch_to_main

const UIStyle = preload("res://scripts/ui_style.gd")
## 登录页/启动页底图：原来用的是旧版蓝紫 key art（灵兽传说 logo 烧在图里）。
## 换成主城那张水墨大图（和游戏内主城同一张），整包视觉才是一套语言。
## 注意：换图之后画面里不再带游戏名，所以标题改成下面 _build_login_title() 里用字排出来。
const LOADING_BG: = preload("res://assets/city_ink/bg_ink.jpg")
const TITLE_FONT: = preload("res://assets/fonts/ink_serif_bold.otf")
## 游戏名标题：用户手绘的毛笔书法「幻灵归虚」（原图白底，已抠成透明 PNG）。
## 位图比字体重：笔画里的飞白、墨点、金色渐变都是画出来的，字体复现不了。
const TITLE_ART: = preload("res://assets/icon/title_calligraphy.png")
## 原图裁切后的宽高比，用来按宽度算高度（TextureRect 不会自己撑开）
const TITLE_ART_ASPECT: = 1400.0 / 418.0
const PetClass = preload("res://scripts/pet.gd")
const PetManagerClass = preload("res://scripts/pet_manager.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")
const WIPE_STATE_PATH: = "user://wipe_state.cfg"
const SAVE_FILE_TEMPLATE: = "user://save_game_u%d.dat"
const SAVE_FILE_BACKUP_TEMPLATE: = "user://save_game_backup_u%d.dat"
const SAVE_FILE_TEMP_TEMPLATE: = "user://save_game_temp_u%d.dat"

const LOGIN_PANEL_SCALE: = 1.25

const OFFLINE_ACTIVE_PET_EXP_SHARE: = 1.0

const REGISTRATION_TEMPORARILY_DISABLED: = false

func _offline_exp_multiplier_from_player_data(player_data: Dictionary) -> float:
	var now_ts: = int(Time.get_unix_time_from_system())
	var tier: = VipBenefits.tier_from_player_data(player_data, now_ts)
	var vip_mult: = VipBenefits.exp_multiplier(tier)
	var double_exp_until: = int(player_data.get("double_exp_until", 0))
	if double_exp_until > now_ts:
		return vip_mult + 1.0
	return vip_mult

func _login_dim(base: float) -> int:
	return int(round(base * LOGIN_PANEL_SCALE))

func _styled_dim(style_scale: float, base: float) -> int:
	return int(round(base * style_scale))


func _login_tabbar_stylebox(bg: Color) -> StyleBoxFlat:
	var sb: = StyleBoxFlat.new()
	var margin_v: = _login_dim(11)
	var margin_h: = _login_dim(32)
	var r: = 0
	sb.bg_color = bg
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.content_margin_left = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_right = margin_h
	sb.content_margin_bottom = margin_v
	return sb

var network: Node = null

var tab_container: TabContainer
var login_container: VBoxContainer
var register_container: VBoxContainer

var login_username: LineEdit
var login_password: LineEdit
var login_btn: Button
var login_error: Label
var remember_check: CheckBox

var reg_username: LineEdit
var reg_password: LineEdit
var reg_password2: LineEdit
var register_btn: Button
var reg_error: Label
## 注册页已不填角色名（挪到登录后的「创建角色」弹窗），这里只记住刚注册的账号，
## 注册成功就替玩家填进登录页的用户名栏。
var _last_registered_username: String = ""

var loading_label: Label
var version_label: Label


var _logged_in_user_id: int = 0
var _logged_in_nickname: String = ""
var _logged_in_token: String = ""


var _download_save_timer: float = 0.0
var _download_save_timeout: float = 120.0
var _is_downloading_save: bool = false
var _download_slow_hint_shown: bool = false
var _version_check_done: bool = false
var _version_allows_login: bool = false


var _login_http_watch_timer: float = 0.0
var _awaiting_login_http: bool = false
var _register_http_watch_timer: float = 0.0
var _awaiting_register_http: bool = false
const _AUTH_HTTP_WATCHDOG_SEC: float = 118.0

const _GameServerConfig = preload("res://scripts/game_server_config.gd")
const PATCH_VERSION_FILE: = "user://patch_version.txt"

const HOTFIX_VERSION_LABEL_REV: = "diag_2084"

var main_node: Node2D = null
var _force_update_locked: bool = false
var _force_update_overlay: ColorRect = null
var _force_update_overlay_layer: CanvasLayer = null
var _login_form_center: CenterContainer = null
var _android_ime_layout_enabled: bool = false
var _android_ime_field_focused: bool = false
var _android_focused_line_edit: LineEdit = null
var _android_vk_fallback_pending: bool = false
var _android_vk_fallback_timer: float = 0.0
var _android_vk_fallback_tried: bool = false
const _ANDROID_VK_FALLBACK_DELAY_SEC: = 0.4

func _set_force_update_lock(active: bool, message: String = "") -> void :
	_force_update_locked = active

	if is_instance_valid(login_btn):
		login_btn.disabled = active
	if is_instance_valid(register_btn):
		register_btn.disabled = active
	if is_instance_valid(login_username):
		login_username.editable = not active
	if is_instance_valid(login_password):
		login_password.editable = not active
	if is_instance_valid(reg_username):
		reg_username.editable = not active
	if is_instance_valid(reg_password):
		reg_password.editable = not active
	if is_instance_valid(reg_password2):
		reg_password2.editable = not active

	if active:
		if not is_instance_valid(_force_update_overlay_layer):
			_force_update_overlay_layer = CanvasLayer.new()
			_force_update_overlay_layer.name = "ForceUpdateOverlayLayer"
			_force_update_overlay_layer.layer = 90
			var host: Node = self
			var tree: = get_tree()
			if tree and tree.root:
				host = tree.root
			host.add_child(_force_update_overlay_layer)
		if not is_instance_valid(_force_update_overlay):
			_force_update_overlay = ColorRect.new()
			_force_update_overlay.name = "ForceUpdateInputBlocker"
			_force_update_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_force_update_overlay.offset_left = 0
			_force_update_overlay.offset_top = 0
			_force_update_overlay.offset_right = 0
			_force_update_overlay.offset_bottom = 0
			_force_update_overlay.color = Color(0, 0, 0, 0.01)
			_force_update_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
			_force_update_overlay_layer.add_child(_force_update_overlay)
		else:
			_force_update_overlay.visible = true
		if message != "" and is_instance_valid(login_error):
			login_error.text = message
	else:
		if is_instance_valid(_force_update_overlay):
			_force_update_overlay.queue_free()
			_force_update_overlay = null
		if is_instance_valid(_force_update_overlay_layer):
			_force_update_overlay_layer.queue_free()
			_force_update_overlay_layer = null

func _set_version_gate_ready(ready: bool, allow_login: bool, waiting_msg: String = "") -> void :
	_version_check_done = ready
	_version_allows_login = allow_login
	if _force_update_locked:
		return
	if is_instance_valid(login_btn):
		login_btn.disabled = not (ready and allow_login)
	if is_instance_valid(register_btn):
		register_btn.disabled = not (ready and allow_login)
	if not ready and waiting_msg != "" and is_instance_valid(loading_label):
		loading_label.text = waiting_msg

func get_client_version() -> String:
	if main_node:
		return main_node.CLIENT_VERSION
	return "1.0.0"

func _get_local_patch_version() -> String:
	if not FileAccess.file_exists(PATCH_VERSION_FILE):
		return ""
	var f: = FileAccess.open(PATCH_VERSION_FILE, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()

func _format_version_label_text() -> String:
	var base_ver: = get_client_version()
	var patch_ver: = _get_local_patch_version()
	if patch_ver.is_empty():
		return "底包 %s" % base_ver
	return "底包 %s · 热更 %s" % [base_ver, patch_ver]

func _refresh_version_label() -> void :
	if version_label == null or not is_instance_valid(version_label):
		return
	version_label.text = _format_version_label_text()

func _ready():

	network = get_node_or_null("Network")
	if network == null:
		print("[LoginUI] 错误: Network 节点不存在!")
		return
	print("[LoginUI] Network 节点已获取: ", network)

	network.login_success.connect(_on_login_success)
	network.login_failed.connect(_on_login_failed)
	network.register_success.connect(_on_register_success)
	network.register_failed.connect(_on_register_failed)
	network.save_downloaded.connect(_on_save_downloaded)
	network.version_checked.connect(_on_version_checked)
	network.force_update_required.connect(_on_force_update_required)
	network.set_server_url(_GameServerConfig.api_base())
	network.set_client_version(get_client_version())
	_build_ui()
	_android_ime_layout_enabled = OS.get_name() == "Android"
	_refresh_version_label()
	call_deferred("_fit_to_viewport")
	_fit_to_viewport()
	if not get_viewport().size_changed.is_connected(_fit_to_viewport):
		get_viewport().size_changed.connect(_fit_to_viewport)
	_load_account()
	_set_version_gate_ready(false, false, "正在检查版本...")
	_check_version()



func _fit_to_viewport() -> void :
	var vp: = get_viewport()
	if vp == null:
		return
	var r: = vp.get_visible_rect()
	position = r.position
	size = r.size


## 登录页顶部标题：书法「幻灵归虚」+ 双金线夹菱形 + 「养 宠 修 仙」。
## 用绝对定位贴在页面顶部，不参与中间登录卡的垂直居中（卡片位置一个像素都不动）。
## 注意：这里不再放圆形 logo —— 启动闪屏、桌面图标已经有 logo 了，
## 标题区再来一个会在同一屏里出现两次同一个图形，反而抢戏。
func _build_login_title() -> Control:
	var box: = VBoxContainer.new()
	box.name = "LoginTitle"
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = 0.0
	box.offset_right = 0.0
	box.offset_top = float(_login_dim(58))
	box.offset_bottom = float(_login_dim(230))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", _login_dim(10))

	# 标题改用用户给的书法图（透明 PNG）。宽度按 290 设计像素算，高度由宽高比推出，
	# 和原来的 62 号字排版宽度基本一致，只是笔锋更放得开。
	var title_w: = float(_login_dim(290))
	var title: = TextureRect.new()
	title.texture = TITLE_ART
	title.custom_minimum_size = Vector2(title_w, round(title_w / TITLE_ART_ASPECT))
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 图里自带奶油色描边，浅宣纸底上会糊；压一点亮度让金边压得住背景
	title.modulate = Color(1.0, 0.985, 0.96, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	# 金线 + 菱形 + 金线：水墨皮里标题下那道分隔的固定写法
	var rule: = HBoxContainer.new()
	rule.alignment = BoxContainer.ALIGNMENT_CENTER
	rule.add_theme_constant_override("separation", _login_dim(10))
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(3):
		if i == 1:
			var dot: = ColorRect.new()
			var d: = maxf(5.0, float(_login_dim(5)))
			dot.color = Color(0.478, 0.353, 0.129, 0.95)
			dot.custom_minimum_size = Vector2(d, d)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.pivot_offset = Vector2(d, d) * 0.5
			dot.rotation = PI * 0.25
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rule.add_child(dot)
		else:
			var line: = ColorRect.new()
			# 书法图自带暖金边，细线太浅会被宣纸底吃掉，压深一档、加粗到 2
			line.color = Color(0.478, 0.353, 0.129, 0.85)
			line.custom_minimum_size = Vector2(float(_login_dim(62)), maxf(2.0, float(_login_dim(2))))
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rule.add_child(line)
	box.add_child(rule)

	var sub: = Label.new()
	sub.text = "养 宠 修 仙"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", TITLE_FONT)
	# 副标题原来 14：在书法标题下面小到像注脚，放大到 19，靠字距撑开气韵
	sub.add_theme_font_size_override("font_size", _login_dim(19))
	sub.add_theme_constant_override("extra_character_spacing", _login_dim(2))
	sub.add_theme_color_override("font_color", Color(0.914, 0.855, 0.729))
	sub.add_theme_color_override("font_outline_color", Color(0.043, 0.034, 0.018, 0.92))
	sub.add_theme_constant_override("outline_size", _login_dim(4))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sub)
	return box


func _build_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fullscreen_bg: = TextureRect.new()
	fullscreen_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	fullscreen_bg.offset_left = 0.0
	fullscreen_bg.offset_top = 0.0
	fullscreen_bg.offset_right = 0.0
	fullscreen_bg.offset_bottom = 0.0
	fullscreen_bg.texture = LOADING_BG
	fullscreen_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fullscreen_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fullscreen_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 水墨化：旧底图是蓝紫发光 key art，单靠叠半透明色块压不干净色相，
	# 所以用 shader 去饱和 + 暖墨重上色。现在底图换成了主城水墨大图（本身就是暖墨），
	# 参数要大幅调轻：只做「压暗 + 轻暗角」，让金框面板和白字压得住，
	# 不能按旧图那套 0.74 去饱和 —— 那样会把水墨大图的青绿/朱砂全洗掉。
	var bg_mat: = ShaderMaterial.new()
	bg_mat.shader = load("res://assets/shaders/login_ink_bg.gdshader")
	# 只压到黄昏亮度（0.34 会把水墨画的宣纸底色压成灰浆，青绿/朱砂全没了），
	# 页面级文字（标题/版本号/声明）靠各自的深墨描边保证可读性，不靠把整张图压黑
	bg_mat.set_shader_parameter("desaturate", 0.06)
	bg_mat.set_shader_parameter("tone_mix", 0.06)
	bg_mat.set_shader_parameter("darken", 0.10)
	bg_mat.set_shader_parameter("vignette", 0.40)
	fullscreen_bg.material = bg_mat
	add_child(fullscreen_bg)

	# 再补一层极淡的暖墨，把 shader 之后的残余高光压到内页亮度量级
	var veil_ink: = ColorRect.new()
	veil_ink.color = Color(0.045, 0.038, 0.028, 0.12)
	veil_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil_ink.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil_ink)
	# 标题：旧底图把「灵兽传说」烧在画里，换成主城大图后画面没有游戏名了，
	# 这里用包内的粗宋排一个，金色 + 深墨描边，压在水墨画上也能看清。
	add_child(_build_login_title())


	var root_col: = VBoxContainer.new()
	root_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_col)
	var top_push: = Control.new()
	top_push.custom_minimum_size = Vector2(0, _login_dim(96))
	top_push.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_col.add_child(top_push)
	_login_form_center = CenterContainer.new()
	_login_form_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_login_form_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_login_form_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_login_form_center.mouse_filter = Control.MOUSE_FILTER_STOP
	root_col.add_child(_login_form_center)

	var bottom_spacer: = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, _login_dim(8))
	bottom_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_col.add_child(bottom_spacer)
	var disc_margin: = MarginContainer.new()
	disc_margin.add_theme_constant_override("margin_left", _login_dim(24))
	disc_margin.add_theme_constant_override("margin_right", _login_dim(24))
	disc_margin.add_theme_constant_override("margin_bottom", _login_dim(8))
	disc_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disc_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var disclaimer: = Label.new()
	disclaimer.text = "⚠️ 重要声明：本游戏为完全原创游戏，仅限内部小范围交流、个人娱乐使用，完全免费、非商用、禁止外传/公开/上架。"
	disclaimer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer.add_theme_font_size_override("font_size", _login_dim(11))
	disclaimer.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	disclaimer.add_theme_color_override("font_outline_color", Color(0.043, 0.034, 0.018, 0.88))
	disclaimer.add_theme_constant_override("outline_size", _login_dim(4))
	disclaimer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclaimer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	disc_margin.add_child(disclaimer)
	root_col.add_child(disc_margin)

	var card: = MarginContainer.new()
	card.custom_minimum_size = Vector2(_login_dim(360), _login_dim(480))
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_login_form_center.add_child(card)

	var outer: = VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = float(_login_dim(8))
	outer.offset_top = float(_login_dim(8))
	outer.offset_right = - float(_login_dim(8))
	outer.offset_bottom = - float(_login_dim(8))
	outer.add_theme_constant_override("separation", 0)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(outer)

	var top_spacer: = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, _login_dim(48))
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(top_spacer)

	var form_panel: = Panel.new()
	form_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style = StyleBoxFlat.new()
	# 底板 70%：让背后的主城水墨透一点出来，面板不显得像一块实心黑板
	panel_style.bg_color = Color(0.055, 0.047, 0.035, 0.70)
	panel_style.border_width_left = _login_dim(2)
	panel_style.border_width_top = _login_dim(2)
	panel_style.border_width_right = _login_dim(2)
	panel_style.border_width_bottom = _login_dim(2)
	panel_style.border_color = Color(0.788, 0.635, 0.294, 0.62)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	# 投影收薄：6 设计 px / 黑 0.28 / 下移 2
	panel_style.shadow_color = Color(0, 0, 0, 0.28)
	panel_style.shadow_size = _login_dim(6)
	panel_style.shadow_offset = Vector2(0, float(_login_dim(2)))
	form_panel.add_theme_stylebox_override("panel", panel_style)
	outer.add_child(form_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = float(_login_dim(14))
	main_vbox.offset_right = - float(_login_dim(14))
	main_vbox.offset_top = float(_login_dim(12))
	main_vbox.offset_bottom = - float(_login_dim(22))
	main_vbox.add_theme_constant_override("separation", _login_dim(8))
	form_panel.add_child(main_vbox)

	tab_container = TabContainer.new()

	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.tab_alignment = TabBar.ALIGNMENT_LEFT
	tab_container.clip_tabs = false
	tab_container.add_theme_constant_override("separation", 0)
	tab_container.add_theme_font_size_override("font_size", _login_dim(16))
	tab_container.add_theme_constant_override("tab_separation", _login_dim(12))
	tab_container.add_theme_color_override("font_selected_color", Color(0.937, 0.843, 0.608))
	tab_container.add_theme_color_override("font_unselected_color", Color(0.62, 0.58, 0.48))
	tab_container.add_theme_stylebox_override("tab_unselected", _login_tabbar_stylebox(Color(0.05, 0.045, 0.035, 0.70)))
	tab_container.add_theme_stylebox_override("tab_selected", _login_tabbar_stylebox(Color(0.13, 0.105, 0.06, 0.86)))
	tab_container.add_theme_stylebox_override("tab_hovered", _login_tabbar_stylebox(Color(0.085, 0.07, 0.05, 0.80)))
	var tab_style = StyleBoxFlat.new()
	# 全透明：这一层铺满面板内部，若再叠一层同色底会把面板压回实心黑（透不出背后的水墨）
	tab_style.bg_color = Color(0.045, 0.04, 0.03, 0.0)
	tab_style.corner_radius_top_left = 0
	tab_style.corner_radius_top_right = 0
	tab_style.corner_radius_bottom_left = 0
	tab_style.corner_radius_bottom_right = 0
	tab_container.add_theme_stylebox_override("panel", tab_style)
	main_vbox.add_child(tab_container)

	_build_login_tab()
	_build_register_tab()

	if REGISTRATION_TEMPORARILY_DISABLED:
		tab_container.set_tab_hidden(1, true)
		var reg_closed_notice: = Label.new()
		reg_closed_notice.text = "新用户注册暂时关闭"
		reg_closed_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reg_closed_notice.add_theme_font_size_override("font_size", _login_dim(13))
		reg_closed_notice.add_theme_color_override("font_color", Color(0.85, 0.7, 0.45))
		login_container.add_child(reg_closed_notice)
		login_container.move_child(reg_closed_notice, login_btn.get_index())

	var tab_bar: = tab_container.get_tab_bar()
	if tab_bar:
		tab_bar.clip_tabs = false
		tab_bar.add_theme_constant_override("h_separation", _login_dim(6))
		tab_bar.custom_minimum_size = Vector2(0, _login_dim(44))

	loading_label = Label.new()
	loading_label.text = ""
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_font_size_override("font_size", _login_dim(16))
	loading_label.add_theme_color_override("font_color", Color(0.937, 0.843, 0.608))
	main_vbox.add_child(loading_label)

	var version_gap: = Control.new()
	# 4 太贴：版本号会卡着面板下边框，像被切掉一截；留出一行字的呼吸
	version_gap.custom_minimum_size = Vector2(0, _login_dim(12))
	version_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(version_gap)
	version_label = Label.new()
	version_label.text = _format_version_label_text()
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", _login_dim(13))
	version_label.add_theme_color_override("font_color", Color(0.878, 0.839, 0.741))
	version_label.add_theme_color_override("font_outline_color", Color(0.043, 0.034, 0.018, 0.85))
	version_label.add_theme_constant_override("outline_size", _login_dim(4))
	version_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	version_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	outer.add_child(version_label)

func _build_login_tab():
	var login_scroll: = ScrollContainer.new()
	login_scroll.name = "登录"
	login_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	login_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	login_container = VBoxContainer.new()
	login_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_container.add_theme_constant_override("separation", _login_dim(8))
	login_scroll.add_child(login_container)
	tab_container.add_child(login_scroll)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, _login_dim(6))
	login_container.add_child(spacer1)

	var username_vbox = VBoxContainer.new()
	username_vbox.add_theme_constant_override("separation", _login_dim(6))
	login_container.add_child(username_vbox)

	var username_label = Label.new()
	username_label.text = "用户名"
	username_label.add_theme_font_size_override("font_size", _login_dim(14))
	username_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	username_vbox.add_child(username_label)

	login_username = LineEdit.new()
	login_username.placeholder_text = "请输入用户名"
	login_username.custom_minimum_size = Vector2(0, _login_dim(32))
	login_username.add_theme_font_size_override("font_size", _login_dim(14))
	_apply_input_style(login_username, LOGIN_PANEL_SCALE)
	_configure_login_line_edit(login_username, false)
	username_vbox.add_child(login_username)

	var password_vbox = VBoxContainer.new()
	password_vbox.add_theme_constant_override("separation", _login_dim(6))
	login_container.add_child(password_vbox)

	var password_label = Label.new()
	password_label.text = "密码"
	password_label.add_theme_font_size_override("font_size", _login_dim(14))
	password_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	password_vbox.add_child(password_label)

	login_password = LineEdit.new()
	login_password.placeholder_text = "请输入密码"
	login_password.custom_minimum_size = Vector2(0, _login_dim(32))
	login_password.add_theme_font_size_override("font_size", _login_dim(14))
	_apply_input_style(login_password, LOGIN_PANEL_SCALE)
	_configure_login_line_edit(login_password, true)
	password_vbox.add_child(login_password)

	login_error = Label.new()
	login_error.text = ""
	login_error.add_theme_font_size_override("font_size", _login_dim(14))
	login_error.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
	login_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	login_error.custom_minimum_size = Vector2(_login_dim(280), 0)
	login_container.add_child(login_error)

	var remember_hbox = HBoxContainer.new()
	remember_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	login_container.add_child(remember_hbox)

	remember_check = CheckBox.new()
	remember_check.text = "记住账号密码"
	remember_check.button_pressed = true
	remember_check.add_theme_font_size_override("font_size", _login_dim(14))
	remember_check.add_theme_color_override("font_color", Color(0.62, 0.58, 0.48))
	remember_hbox.add_child(remember_check)

	login_btn = Button.new()
	login_btn.text = "登 录"
	login_btn.custom_minimum_size = Vector2(0, _login_dim(36))
	login_btn.add_theme_font_size_override("font_size", _login_dim(16))
	_apply_primary_button_style(login_btn, LOGIN_PANEL_SCALE)
	login_btn.pressed.connect(_on_login_pressed)
	login_container.add_child(login_btn)

func _build_register_tab():
	var register_root: = VBoxContainer.new()
	register_root.name = "注册"
	register_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	register_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	register_root.add_theme_constant_override("separation", _login_dim(6))
	tab_container.add_child(register_root)

	var register_scroll: = ScrollContainer.new()
	register_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	register_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	register_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	register_container = VBoxContainer.new()
	register_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	register_container.add_theme_constant_override("separation", _login_dim(7))
	register_scroll.add_child(register_container)
	register_root.add_child(register_scroll)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 0)
	register_container.add_child(spacer1)

	var username_vbox = VBoxContainer.new()
	username_vbox.add_theme_constant_override("separation", _login_dim(2))
	register_container.add_child(username_vbox)

	var username_label = Label.new()
	username_label.text = "用户名 (3-20个字符)"
	username_label.add_theme_font_size_override("font_size", _login_dim(14))
	username_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	username_vbox.add_child(username_label)

	reg_username = LineEdit.new()
	reg_username.placeholder_text = "请输入用户名"
	reg_username.custom_minimum_size = Vector2(0, _login_dim(28))
	reg_username.add_theme_font_size_override("font_size", _login_dim(14))
	_apply_input_style(reg_username, LOGIN_PANEL_SCALE)
	_configure_login_line_edit(reg_username, false)
	username_vbox.add_child(reg_username)

	var password_vbox = VBoxContainer.new()
	password_vbox.add_theme_constant_override("separation", _login_dim(2))
	register_container.add_child(password_vbox)

	var password_label = Label.new()
	password_label.text = "密码 (至少6个字符)"
	password_label.add_theme_font_size_override("font_size", _login_dim(14))
	password_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	password_vbox.add_child(password_label)

	reg_password = LineEdit.new()
	reg_password.placeholder_text = "请输入密码"
	reg_password.custom_minimum_size = Vector2(0, _login_dim(28))
	reg_password.add_theme_font_size_override("font_size", _login_dim(14))
	_apply_input_style(reg_password, LOGIN_PANEL_SCALE)
	_configure_login_line_edit(reg_password, true)
	password_vbox.add_child(reg_password)

	var password2_vbox = VBoxContainer.new()
	password2_vbox.add_theme_constant_override("separation", _login_dim(2))
	register_container.add_child(password2_vbox)

	var password2_label = Label.new()
	password2_label.text = "确认密码"
	password2_label.add_theme_font_size_override("font_size", _login_dim(14))
	password2_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.58))
	password2_vbox.add_child(password2_label)

	reg_password2 = LineEdit.new()
	reg_password2.placeholder_text = "再次输入密码"
	reg_password2.custom_minimum_size = Vector2(0, _login_dim(28))
	reg_password2.add_theme_font_size_override("font_size", _login_dim(14))
	_apply_input_style(reg_password2, LOGIN_PANEL_SCALE)
	_configure_login_line_edit(reg_password2, true)
	password2_vbox.add_child(reg_password2)

	# 角色名不在注册页填了：注册只管账号密码，角色名和形象放到登录后的
	# 「创建角色」弹窗里（那里能顺手选形象，也方便实时跟服务器核对重名）。
	reg_error = Label.new()
	reg_error.text = ""
	reg_error.add_theme_font_size_override("font_size", _login_dim(13))
	reg_error.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
	reg_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reg_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reg_error.custom_minimum_size = Vector2(_login_dim(280), _login_dim(24))
	register_container.add_child(reg_error)

	var reg_btn_wrap: = MarginContainer.new()
	reg_btn_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reg_btn_wrap.size_flags_vertical = Control.SIZE_SHRINK_END
	reg_btn_wrap.custom_minimum_size = Vector2(0, _login_dim(44))
	reg_btn_wrap.add_theme_constant_override("margin_top", _login_dim(2))
	reg_btn_wrap.add_theme_constant_override("margin_bottom", _login_dim(4))
	register_btn = Button.new()
	register_btn.text = "注 册"
	register_btn.custom_minimum_size = Vector2(0, _login_dim(34))
	register_btn.add_theme_font_size_override("font_size", _login_dim(15))
	_apply_primary_button_style(register_btn, LOGIN_PANEL_SCALE)
	register_btn.pressed.connect(_on_register_pressed)
	reg_btn_wrap.add_child(register_btn)
	register_root.add_child(reg_btn_wrap)

func _apply_input_style(line_edit: LineEdit, style_scale: float = 1.0) -> void :
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.03, 0.022, 0.62)
	style.border_width_left = _styled_dim(style_scale, 1)
	style.border_width_top = _styled_dim(style_scale, 1)
	style.border_width_right = _styled_dim(style_scale, 1)
	style.border_width_bottom = _styled_dim(style_scale, 1)
	style.border_color = Color(0.788, 0.635, 0.294, 0.45)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = _styled_dim(style_scale, 10)
	style.content_margin_top = _styled_dim(style_scale, 5)
	style.content_margin_right = _styled_dim(style_scale, 10)
	style.content_margin_bottom = _styled_dim(style_scale, 5)
	line_edit.add_theme_stylebox_override("normal", style)

	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.05, 0.043, 0.03, 0.72)
	focus_style.border_width_left = _styled_dim(style_scale, 2)
	focus_style.border_width_top = _styled_dim(style_scale, 2)
	focus_style.border_width_right = _styled_dim(style_scale, 2)
	focus_style.border_width_bottom = _styled_dim(style_scale, 2)
	focus_style.border_color = Color(0.937, 0.843, 0.608, 1)
	focus_style.corner_radius_top_left = 0
	focus_style.corner_radius_top_right = 0
	focus_style.corner_radius_bottom_left = 0
	focus_style.corner_radius_bottom_right = 0
	focus_style.content_margin_left = _styled_dim(style_scale, 10)
	focus_style.content_margin_top = _styled_dim(style_scale, 5)
	focus_style.content_margin_right = _styled_dim(style_scale, 10)
	focus_style.content_margin_bottom = _styled_dim(style_scale, 5)
	line_edit.add_theme_stylebox_override("focus", focus_style)

	line_edit.add_theme_color_override("font_color", Color(0.93, 0.89, 0.80))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.42, 0.36))
	line_edit.add_theme_color_override("caret_color", Color(0.937, 0.843, 0.608))

func _configure_login_line_edit(line_edit: LineEdit, is_password: bool) -> void :
	line_edit.focus_mode = Control.FOCUS_ALL
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	line_edit.virtual_keyboard_enabled = true
	if is_password:
		line_edit.secret = true
	if OS.get_name() == "Android":
		_wire_android_ime(line_edit, is_password)

func _wire_android_ime(line_edit: LineEdit, is_password: bool) -> void :
	line_edit.focus_entered.connect(_on_android_line_focus_entered.bind(line_edit, is_password))
	line_edit.focus_exited.connect(_on_android_line_focus_exited.bind(line_edit))

func _on_android_line_focus_entered(line_edit: LineEdit, _is_password: bool) -> void :
	_android_ime_field_focused = true
	_android_focused_line_edit = line_edit
	_android_vk_fallback_pending = true
	_android_vk_fallback_timer = 0.0
	_android_vk_fallback_tried = false
	call_deferred("_sync_android_line_edit_after_focus", line_edit)

func _on_android_line_focus_exited(line_edit: LineEdit) -> void :
	_android_ime_field_focused = false
	_android_vk_fallback_pending = false
	if _android_focused_line_edit == line_edit:
		_android_focused_line_edit = null
	_update_android_vk_layout()


func _sync_android_line_edit_after_focus(line_edit: LineEdit) -> void :
	if OS.get_name() != "Android" or not is_instance_valid(line_edit):
		return
	if not line_edit.has_focus() or not line_edit.editable:
		return
	line_edit.deselect()
	var len: = line_edit.text.length()
	line_edit.caret_column = len
	if len <= 0:
		return
	line_edit.insert_text_at_caret(" ")
	line_edit.delete_char_at_caret()

func _try_android_vk_fallback_once(line_edit: LineEdit, is_password: bool) -> void :
	if not is_instance_valid(line_edit) or not line_edit.has_focus() or not line_edit.editable:
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	if DisplayServer.virtual_keyboard_get_height() > 0:
		return
	var kb_type: = DisplayServer.KEYBOARD_TYPE_PASSWORD if is_password else DisplayServer.KEYBOARD_TYPE_DEFAULT
	DisplayServer.virtual_keyboard_show(line_edit.text, line_edit.get_global_rect(), kb_type)

func _tick_android_vk_fallback(delta: float) -> void :
	if not _android_vk_fallback_pending or _android_vk_fallback_tried:
		return
	var line_edit: = _android_focused_line_edit
	if line_edit == null or not is_instance_valid(line_edit) or not line_edit.has_focus():
		_android_vk_fallback_pending = false
		return
	if DisplayServer.virtual_keyboard_get_height() > 0:
		_android_vk_fallback_pending = false
		return
	_android_vk_fallback_timer += delta
	if _android_vk_fallback_timer < _ANDROID_VK_FALLBACK_DELAY_SEC:
		return
	_android_vk_fallback_tried = true
	_android_vk_fallback_pending = false
	var is_password: = bool(line_edit.secret)
	_try_android_vk_fallback_once(line_edit, is_password)

func _update_android_vk_layout() -> void :
	if not _android_ime_layout_enabled or _login_form_center == null:
		return
	var kb_h: = DisplayServer.virtual_keyboard_get_height()
	if kb_h <= 0 or not _android_ime_field_focused:
		_login_form_center.offset_top = 0
		return
	var scale_y: = get_viewport_transform().get_scale().y
	if scale_y <= 0.0:
		scale_y = 1.0
	var shift: = kb_h / scale_y * 0.35
	_login_form_center.offset_top = - int(round(shift))

func _apply_primary_button_style(btn: Button, style_scale: float = 1.0) -> void :
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.09, 0.075, 0.05, 0.95)
	normal_style.border_width_left = _styled_dim(style_scale, 1)
	normal_style.border_width_top = _styled_dim(style_scale, 1)
	normal_style.border_width_right = _styled_dim(style_scale, 1)
	normal_style.border_width_bottom = _styled_dim(style_scale, 1)
	normal_style.border_color = Color(0.937, 0.843, 0.608, 0.9)
	normal_style.corner_radius_top_left = 0
	normal_style.corner_radius_top_right = 0
	normal_style.corner_radius_bottom_left = 0
	normal_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.125, 0.10, 0.065, 0.95)
	hover_style.border_width_left = _styled_dim(style_scale, 1)
	hover_style.border_width_top = _styled_dim(style_scale, 1)
	hover_style.border_width_right = _styled_dim(style_scale, 1)
	hover_style.border_width_bottom = _styled_dim(style_scale, 1)
	hover_style.border_color = Color(0.937, 0.843, 0.608, 1)
	hover_style.corner_radius_top_left = 0
	hover_style.corner_radius_top_right = 0
	hover_style.corner_radius_bottom_left = 0
	hover_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.07, 0.06, 0.04, 1)
	pressed_style.border_width_left = _styled_dim(style_scale, 1)
	pressed_style.border_width_top = _styled_dim(style_scale, 1)
	pressed_style.border_width_right = _styled_dim(style_scale, 1)
	pressed_style.border_width_bottom = _styled_dim(style_scale, 1)
	pressed_style.border_color = Color(0.788, 0.635, 0.294, 0.6)
	pressed_style.corner_radius_top_left = 0
	pressed_style.corner_radius_top_right = 0
	pressed_style.corner_radius_bottom_left = 0
	pressed_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(0.937, 0.843, 0.608))
	btn.add_theme_color_override("font_hover_color", Color(0.97, 0.90, 0.72))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.76, 0.56))

func _apply_secondary_button_style(btn: Button):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.043, 0.032, 0.9)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.788, 0.635, 0.294, 0.45)
	normal_style.corner_radius_top_left = 0
	normal_style.corner_radius_top_right = 0
	normal_style.corner_radius_bottom_left = 0
	normal_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.085, 0.07, 0.05, 0.95)
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color(0.937, 0.843, 0.608, 1)
	hover_style.corner_radius_top_left = 0
	hover_style.corner_radius_top_right = 0
	hover_style.corner_radius_bottom_left = 0
	hover_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.035, 0.03, 0.022, 1)
	pressed_style.border_width_left = 1
	pressed_style.border_width_top = 1
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	pressed_style.border_color = Color(0.788, 0.635, 0.294, 0.5)
	pressed_style.corner_radius_top_left = 0
	pressed_style.corner_radius_top_right = 0
	pressed_style.corner_radius_bottom_left = 0
	pressed_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(0.85, 0.80, 0.68))
	btn.add_theme_color_override("font_hover_color", Color(0.937, 0.843, 0.608))
	btn.add_theme_color_override("font_pressed_color", Color(0.75, 0.68, 0.55))

func _load_account():
	var config = ConfigFile.new()
	if config.load("user://server.cfg") == OK:
		var saved_username = config.get_value("account", "username", "")
		var saved_password = config.get_value("account", "password", "")
		if saved_username != "":
			login_username.text = saved_username
		if saved_password != "":
			login_password.text = saved_password

func _save_account(username: String, password: String):
	var config = ConfigFile.new()
	config.load("user://server.cfg")
	config.set_value("account", "username", username)
	config.set_value("account", "password", password)
	config.save("user://server.cfg")

func _on_login_pressed():
	if not _version_check_done:
		login_error.text = "版本检查中，请稍候..."
		return
	if not _version_allows_login:
		login_error.text = "检测到需要更新，请先更新后再登录"
		return
	if _force_update_locked:
		login_error.text = "当前客户端版本过低，请先更新后再登录"
		return
	var username = login_username.text.strip_edges()
	var password = login_password.text

	if username == "" or password == "":
		login_error.text = "用户名和密码不能为空"
		return

	login_error.text = ""
	loading_label.text = "正在登录..."
	login_btn.disabled = true
	_awaiting_login_http = true
	_login_http_watch_timer = 0.0
	_awaiting_register_http = false

	network.login(username, password)

func _nickname_has_only_allowed_chars(nickname: String) -> bool:
	for i in nickname.length():
		var c: = nickname.unicode_at(i)
		var is_digit: = c >= 48 and c <= 57
		var is_upper: = c >= 65 and c <= 90
		var is_lower: = c >= 97 and c <= 122
		var is_han: = c >= 19968 and c <= 40959
		if not (is_digit or is_upper or is_lower or is_han):
			return false
	return true

func _on_register_pressed():
	if not _version_check_done:
		reg_error.text = "版本检查中，请稍候..."
		return
	if not _version_allows_login:
		reg_error.text = "检测到需要更新，请先更新后再注册/登录"
		return
	if REGISTRATION_TEMPORARILY_DISABLED:
		reg_error.text = "请联系群主获得注册权限"
		return
	if _force_update_locked:
		reg_error.text = "当前客户端版本过低，请先更新后再注册/登录"
		return
	var username = reg_username.text.strip_edges()
	var password = reg_password.text
	var password2 = reg_password2.text

	if username == "" or password == "":
		reg_error.text = "用户名和密码不能为空"
		return

	if username.length() < 3 or username.length() > 20:
		reg_error.text = "用户名需要3-20个字符"
		return

	if password.length() < 6:
		reg_error.text = "密码至少6个字符"
		return

	if password != password2:
		reg_error.text = "两次输入的密码不一致"
		return

	reg_error.text = ""
	loading_label.add_theme_color_override("font_color", Color(0.937, 0.843, 0.608))
	loading_label.text = "正在注册..."
	register_btn.disabled = true
	_awaiting_register_http = true
	_register_http_watch_timer = 0.0
	_awaiting_login_http = false

	# 角色名留空：账号建好后，登录进入游戏时由「创建角色」弹窗补齐
	_last_registered_username = username
	network.register(username, password, "")

func _process(delta):
	if _android_ime_layout_enabled and _android_ime_field_focused:
		_update_android_vk_layout()
		_tick_android_vk_fallback(delta)
	if _awaiting_login_http:
		_login_http_watch_timer += delta
		if _login_http_watch_timer >= _AUTH_HTTP_WATCHDOG_SEC:
			_awaiting_login_http = false
			if network and network.has_method("abort_stuck_primary_request_for_login_ui"):
				network.abort_stuck_primary_request_for_login_ui("login")
	if _awaiting_register_http:
		_register_http_watch_timer += delta
		if _register_http_watch_timer >= _AUTH_HTTP_WATCHDOG_SEC:
			_awaiting_register_http = false
			if network and network.has_method("abort_stuck_primary_request_for_login_ui"):
				network.abort_stuck_primary_request_for_login_ui("register")

	if _is_downloading_save:
		_download_save_timer += delta
		if _download_save_timer >= 8.0 and not _download_slow_hint_shown:
			_download_slow_hint_shown = true
			loading_label.text = "正在下载存档（服务器较忙，请稍候）..."
		if _download_save_timer >= _download_save_timeout:
			_is_downloading_save = false
			if network and network.has_method("abort_stuck_primary_request_for_login_ui"):
				network.abort_stuck_primary_request_for_login_ui("download_save")
			loading_label.text = "下载存档超时，请检查网络后重试"
			loading_label.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
			login_btn.disabled = false
			login_btn.text = "重新登录"

func _on_login_success(user_id: int, nickname: String, token: String):
	_awaiting_login_http = false
	if _force_update_locked:
		loading_label.text = ""
		login_error.text = "检测到强制更新，已阻止进入游戏，请更新客户端"
		login_btn.disabled = true
		return
	loading_label.text = "登录成功！正在检查未同步存档..."
	loading_label.remove_theme_color_override("font_color")
	login_btn.disabled = true

	_logged_in_user_id = user_id
	_logged_in_nickname = nickname
	_logged_in_token = token
	print("[LoginUI] 保存 token: ", token)

	if remember_check.button_pressed:
		_save_account(login_username.text.strip_edges(), login_password.text)

	_enforce_wipe_if_needed(user_id)

	network.check_pending_uploads(false)

	loading_label.text = "正在下载存档..."
	_is_downloading_save = true
	_download_save_timer = 0.0
	_download_slow_hint_shown = false
	network.download_save()

func _enforce_wipe_if_needed(user_id: int) -> void :
	var remote_wipe_id: = ""
	if network and network.has_method("get_server_wipe_id"):
		remote_wipe_id = String(network.get_server_wipe_id()).strip_edges()
	if remote_wipe_id == "":
		return
	var cfg: = ConfigFile.new()
	var local_wipe_id: = ""
	if cfg.load(WIPE_STATE_PATH) == OK:
		local_wipe_id = String(cfg.get_value("wipe", "id", "")).strip_edges()
	if local_wipe_id == remote_wipe_id:
		return
	_clear_local_state_for_wipe(user_id)
	cfg.set_value("wipe", "id", remote_wipe_id)
	var save_err = cfg.save(WIPE_STATE_PATH)
	if save_err != OK:
		push_warning("[LoginUI] wipe_state 落盘失败: %s" % str(save_err))
	print("[LoginUI] 检测到 wipe_id 变更，已清理本地旧状态: %s -> %s" % [local_wipe_id, remote_wipe_id])

func _clear_local_state_for_wipe(user_id: int) -> void :
	var paths: = [
		"user://save_game.dat", 
		"user://save_game_backup.dat", 
		"user://save_game_temp.dat", 
		"user://save_game.json", 
		"user://save_game_backup.json", 
		"user://announcement_cursor.cfg", 
		"user://broadcast_cursor.cfg", 
		"user://mail_pending_finalize.cfg", 
	]
	if user_id > 0:
		paths.append(SAVE_FILE_TEMPLATE % user_id)
		paths.append(SAVE_FILE_BACKUP_TEMPLATE % user_id)
		paths.append(SAVE_FILE_TEMP_TEMPLATE % user_id)
	for p in paths:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	var dir: = DirAccess.open("user://pending_saves")
	if dir:
		dir.list_dir_begin()
		while true:
			var name: = dir.get_next()
			if name == "":
				break
			if dir.current_is_dir():
				continue
			DirAccess.remove_absolute("user://pending_saves/" + name)
		dir.list_dir_end()

func _on_save_downloaded(save_data):
	_is_downloading_save = false

	if _force_update_locked:
		loading_label.text = ""
		login_error.text = "检测到强制更新，已阻止进入游戏，请更新客户端"
		login_btn.disabled = true
		return

	if save_data is Dictionary and bool(save_data.get("_download_error", false)):
		var err_text: = String(save_data.get("error_msg", "下载存档失败，请检查网络后重试"))
		_abort_login_requires_retry(err_text)
		return

	if save_data == null or not save_data is Dictionary:
		print("[LoginUI] 无有效存档数据，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	if save_data.keys().size() == 0:
		print("[LoginUI] 存档数据为空对象，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	if not save_data.has("playerData"):
		print("[LoginUI] 存档缺少 playerData，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	var player_data = save_data.get("playerData", {})

	if player_data == null or not player_data is Dictionary:
		print("[LoginUI] playerData 无效，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	var required_fields = ["name", "level"]
	var has_required = true
	for field in required_fields:
		if not player_data.has(field):
			has_required = false
			break

	if not has_required:
		print("[LoginUI] playerData 缺少关键字段，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	if player_data.get("name", "") == "" or player_data.get("level", 0) < 1:
		print("[LoginUI] playerData 数据无效，新用户首次登录")
		login_success.emit(_logged_in_user_id, _logged_in_nickname, null, _logged_in_token)
		switch_to_main.emit()
		return

	print("[LoginUI] 存档数据校验通过，玩家: %s, 等级: %d" % [player_data.get("name", ""), player_data.get("level", 1)])

	var pd_check = save_data.get("playerData", {})
	if pd_check == null or not pd_check.has("name"):
		login_success.emit(_logged_in_user_id, _logged_in_nickname, save_data, _logged_in_token)
		switch_to_main.emit()
		return

	call_deferred("_login_offline_flow_after_valid_save", save_data)

func _abort_login_requires_retry(message: String) -> void :
	if network and network.has_method("logout"):
		network.logout()
	login_error.text = message
	login_error.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
	loading_label.text = ""
	if loading_label.has_theme_color_override("font_color"):
		loading_label.remove_theme_color_override("font_color")
	login_btn.disabled = false
	register_btn.disabled = false

func _login_offline_flow_after_valid_save(save_data: Dictionary) -> void :

	login_success.emit(_logged_in_user_id, _logged_in_nickname, save_data, _logged_in_token)
	switch_to_main.emit()
	loading_label.text = ""

func _on_login_failed(error_msg: String):
	_awaiting_login_http = false
	loading_label.text = ""
	login_error.text = error_msg
	login_btn.disabled = false

func _on_register_success(user_id: int, nickname: String, token: String):
	_awaiting_register_http = false
	reg_error.text = ""
	reg_error.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	reg_error.text = "注册成功！请登录"
	register_btn.disabled = false
	loading_label.text = ""

	reg_username.text = ""
	reg_password.text = ""
	reg_password2.text = ""

	# 注册完直接把人送到登录页，用户名替玩家填好，少一步手动输入
	if is_instance_valid(login_username):
		login_username.text = str(_last_registered_username).strip_edges()

	tab_container.current_tab = 0

func _on_register_failed(error_msg: String):
	_awaiting_register_http = false
	var msg: = error_msg.strip_edges()
	if msg == "":
		msg = "注册失败，请稍后重试"
	reg_error.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
	reg_error.text = msg
	loading_label.add_theme_color_override("font_color", Color(0.85, 0.42, 0.32))
	loading_label.text = msg
	register_btn.disabled = false

func _on_force_update_required(update_info: Dictionary):
	_awaiting_login_http = false
	_awaiting_register_http = false
	loading_label.text = ""
	_set_force_update_lock(true, "当前客户端版本过低，请先更新后再登录")
	var patched_info = update_info.duplicate()
	var msg = String(patched_info.get("message", "")).strip_edges()
	if msg == "":
		patched_info["message"] = "请到群文件下载最新版游戏"
	_show_update_dialog(true, patched_info)

func _check_version():
	loading_label.text = "正在检查版本..."
	network.check_version(get_client_version())

func _on_version_checked(need_update: bool, force_update: bool, update_info: Dictionary):
	_set_version_gate_ready(true, true)
	loading_label.text = ""
	if not need_update and not force_update:
		return


	_set_version_gate_ready(true, false)
	_set_force_update_lock(true, "检测到新版本，必须先更新后再登录")
	var patched_info = update_info.duplicate()
	var msg = String(patched_info.get("message", "")).strip_edges()
	if msg == "":
		patched_info["message"] = "请到群文件下载最新版游戏"
	_show_update_dialog(true, patched_info)

func _show_update_dialog(force_update: bool, update_info: Dictionary):
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2(450, 400)
	dialog.borderless = true
	dialog.transparent = true
	dialog.unresizable = true
	dialog.exclusive = true
	dialog.close_requested.connect( func():
		if force_update:
			_set_force_update_lock(true, "当前客户端版本过低，请先更新后再登录")
			return
		dialog.queue_free()
	)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 25
	vbox.offset_bottom = -25
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "发现新版本" if not force_update else "必须更新"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vbox.add_child(title)

	var version_info = Label.new()
	var latest = update_info.get("latestVersion", "未知")
	var current = update_info.get("currentVersion", get_client_version())
	version_info.text = "当前版本: v" + current + "  →  最新版本: v" + latest
	version_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_info.add_theme_font_size_override("font_size", 16)
	version_info.add_theme_color_override("font_color", Color(0.788, 0.72, 0.58))
	vbox.add_child(version_info)

	var message = Label.new()
	message.text = update_info.get("message", "请到群文件下载最新版游戏")
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color(0.85, 0.80, 0.68))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(message)

	var release_notes = Label.new()
	release_notes.text = update_info.get("releaseNotes", "")
	release_notes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	release_notes.add_theme_font_size_override("font_size", 14)
	release_notes.add_theme_color_override("font_color", Color(0.62, 0.58, 0.48))
	release_notes.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(release_notes)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)

	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var update_btn = Button.new()
	update_btn.text = "立即更新"
	update_btn.custom_minimum_size = Vector2(120, 45)
	update_btn.add_theme_font_size_override("font_size", 18)
	_apply_primary_button_style(update_btn)
	update_btn.pressed.connect( func():
		var tip_dialog = Window.new()
		tip_dialog.title = ""
		tip_dialog.size = Vector2(400, 280)
		tip_dialog.borderless = true
		tip_dialog.transparent = true
		tip_dialog.unresizable = true

		var tip_panel = Panel.new()
		tip_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		tip_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
		tip_dialog.add_child(tip_panel)

		var tip_vbox = VBoxContainer.new()
		tip_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		tip_vbox.offset_left = 25
		tip_vbox.offset_right = -25
		tip_vbox.offset_top = 25
		tip_vbox.offset_bottom = -25
		tip_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		tip_vbox.add_theme_constant_override("separation", 15)
		tip_panel.add_child(tip_vbox)

		var tip_title = Label.new()
		tip_title.text = "提示"
		tip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_title.add_theme_font_size_override("font_size", 24)
		tip_title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		tip_vbox.add_child(tip_title)

		var tip_msg = Label.new()
		tip_msg.text = "请到群文件下载最新版游戏"
		tip_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_msg.add_theme_font_size_override("font_size", 16)
		tip_msg.add_theme_color_override("font_color", Color(0.85, 0.80, 0.68))
		tip_vbox.add_child(tip_msg)

		var tip_spacer = Control.new()
		tip_spacer.custom_minimum_size = Vector2(0, 15)
		tip_vbox.add_child(tip_spacer)

		var ok_btn = Button.new()
		ok_btn.text = "确定"
		ok_btn.custom_minimum_size = Vector2(100, 40)
		ok_btn.add_theme_font_size_override("font_size", 18)
		_apply_primary_button_style(ok_btn)
		ok_btn.pressed.connect( func():
			tip_dialog.queue_free()
			if force_update:
				get_tree().quit()
		)
		tip_vbox.add_child(ok_btn)

		add_child(tip_dialog)
		tip_dialog.popup_centered()

		dialog.queue_free()
	)
	btn_container.add_child(update_btn)

	if force_update:
		_set_force_update_lock(true, "当前客户端版本过低，请先更新后再登录")

	add_child(dialog)
	dialog.popup_centered()
