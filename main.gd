extends Node2D

var login_ui: Control
var main_ui: Control
var network: Node

var login_bgm_player: AudioStreamPlayer = null
const LOGIN_BGM = "res://Music/bjyy.mp3"

const CLIENT_VERSION: = preload("res://scripts/client_version.gd").VALUE
const MAIN_UI_SCENE_PATH: = "res://ui/ink_home.tscn"
## 启动首屏底图：和登录页/主城同一张水墨大图（原来是旧版蓝紫 key art）
const LOADING_BG_PATH: = "res://assets/city_ink/bg_ink.jpg"
## 启动页 logo（阴鱼阳鱼墨像）
const LOGO_MARK: = preload("res://assets/icon/logo_mark_256.png")
## 加载中 logo 的自转速度：2.4 秒一圈。太快像风扇，太慢又看不出在转
const LOADING_SPIN_SPEED: = TAU / 2.4
const HOTFIX_PATCH_FILE: = "user://patches/hotfix.pck"
const _GameServerConfig = preload("res://scripts/game_server_config.gd")
const _HOTFIX_UPDATE_MANAGER_SCRIPT: = "res://scripts/update_manager.gd"
const _UPDATE_DIALOG_SCRIPT: = "res://scripts/update_dialog.gd"
const UIStyle = preload("res://scripts/ui_style.gd")

var _loading_overlay: CanvasLayer = null
var _loading_progress_bar: ProgressBar = null
var _loading_logo: TextureRect = null
var _loading_main_ui_active: bool = false
var _pending_user_id: int = 0
var _pending_nickname: String = ""
var _pending_save_data = null
var _pending_token: String = ""
var _pending_network: Node = null
var _force_update_dialog: Window = null


var _boot_started: bool = false
const WINDOW_LAYOUT_PATH: = "user://window_layout.cfg"
var _desktop_window_applying: bool = false
var _desktop_window_save_timer: Timer = null

func _ready():
	_apply_desktop_window_on_boot()
	_setup_desktop_window_persist()
	print("游戏启动...")
	print("当前版本: ", CLIENT_VERSION)
	_load_saved_patch_if_any()
	var reach_ok: bool = await _probe_server_reachable()
	if not reach_ok:
		# 网页版把实际尝试的服务器地址也带出来：手机上没法看控制台，
		# 报障时截个图就能判断是域名错了还是网络不通。
		var detail: String = ""
		if OS.has_feature("web"):
			detail = "\n\n服务器：%s" % _GameServerConfig.main_service_root()
		_show_startup_network_quit_dialog("无法连接游戏服务器，本游戏需联网运行。\n请检查网络后重新启动。" + detail)
		return
	var hotfix_boot: = _create_hotfix_manager()
	if hotfix_boot:
		hotfix_boot.try_load_saved_patch()
	var hotfix_restart: = await _try_apply_hotfix_patch()
	if hotfix_restart:
		call_deferred("_reload_after_hotfix")
		return
	_start_game()
	call_deferred("_check_version")



func _fit_desktop_window_to_usable_screen() -> void :
	fit_desktop_window_to_usable_screen()


func _is_desktop_window() -> bool:
	return not OS.has_feature("android") and not OS.has_feature("ios") and not OS.has_feature("mobile")


func _apply_desktop_content_scale_expand() -> void :
	var root_win: = get_tree().root
	if root_win:
		root_win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


func _desktop_decoration_size() -> Vector2i:
	var client: Vector2i = DisplayServer.window_get_size()
	var outer: Vector2i = DisplayServer.window_get_size_with_decorations()
	var deco_w: int = maxi(0, outer.x - client.x)
	var deco_h: int = maxi(0, outer.y - client.y)
	if deco_h <= 0:
		deco_h = 40
	return Vector2i(deco_w, deco_h)


func _clamp_desktop_window_position(outer_size: Vector2i, usable: Rect2i) -> Vector2i:
	var pos: Vector2i = DisplayServer.window_get_position()
	var max_x: int = usable.position.x + usable.size.x - outer_size.x
	var max_y: int = usable.position.y + usable.size.y - outer_size.y
	if max_x < usable.position.x:
		max_x = usable.position.x
	if max_y < usable.position.y:
		max_y = usable.position.y
	pos.x = clampi(pos.x, usable.position.x, max_x)
	pos.y = clampi(pos.y, usable.position.y, max_y)
	return pos


func _save_desktop_window_layout() -> void :
	if not _is_desktop_window() or _desktop_window_applying:
		return
	var sz: Vector2i = DisplayServer.window_get_size()
	var pos: Vector2i = DisplayServer.window_get_position()
	if sz.x < 200 or sz.y < 200:
		return
	var config: = ConfigFile.new()
	config.set_value("window", "size_x", sz.x)
	config.set_value("window", "size_y", sz.y)
	config.set_value("window", "pos_x", pos.x)
	config.set_value("window", "pos_y", pos.y)
	config.save(WINDOW_LAYOUT_PATH)


func _schedule_save_desktop_window_layout() -> void :
	if not _is_desktop_window() or _desktop_window_applying:
		return
	if _desktop_window_save_timer == null:
		return
	_desktop_window_save_timer.start()


func _try_restore_desktop_window_layout() -> bool:
	if not _is_desktop_window():
		return false
	var config: = ConfigFile.new()
	if config.load(WINDOW_LAYOUT_PATH) != OK:
		return false
	var win_w: int = int(config.get_value("window", "size_x", 0))
	var win_h: int = int(config.get_value("window", "size_y", 0))
	var pos_x: int = int(config.get_value("window", "pos_x", 0))
	var pos_y: int = int(config.get_value("window", "pos_y", 0))
	if win_w < 200 or win_h < 200:
		return false
	var usable: Rect2i = DisplayServer.screen_get_usable_rect()
	if usable.size.x <= 0 or usable.size.y <= 0:
		return false
	var deco: Vector2i = _desktop_decoration_size()
	var max_client_w: int = maxi(1, usable.size.x - deco.x)
	var max_client_h: int = maxi(1, usable.size.y - deco.y)
	if win_w > max_client_w or win_h > max_client_h:
		return false
	_desktop_window_applying = true
	DisplayServer.window_set_size(Vector2i(win_w, win_h))
	DisplayServer.window_set_position(Vector2i(pos_x, pos_y))
	var outer2: Vector2i = DisplayServer.window_get_size_with_decorations()
	if outer2.x <= 0 or outer2.y <= 0:
		outer2 = Vector2i(win_w + deco.x, win_h + deco.y)
	DisplayServer.window_set_position(_clamp_desktop_window_position(outer2, usable))
	_apply_desktop_content_scale_expand()
	_desktop_window_applying = false
	return true


func _apply_desktop_window_on_boot() -> void :
	if not _is_desktop_window():
		return
	if _try_restore_desktop_window_layout():
		return
	fit_desktop_window_to_usable_screen()


func _setup_desktop_window_persist() -> void :
	if not _is_desktop_window():
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	_apply_desktop_content_scale_expand()
	_desktop_window_save_timer = Timer.new()
	_desktop_window_save_timer.wait_time = 0.4
	_desktop_window_save_timer.one_shot = true
	_desktop_window_save_timer.timeout.connect(_save_desktop_window_layout)
	add_child(_desktop_window_save_timer)
	var root_win: = get_tree().root
	if root_win and not root_win.size_changed.is_connected(_on_desktop_window_size_changed):
		root_win.size_changed.connect(_on_desktop_window_size_changed)


func _on_desktop_window_size_changed() -> void :
	_schedule_save_desktop_window_layout()


func _notification(what: int) -> void :
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_desktop_window_layout()


func fit_desktop_window_to_usable_screen() -> void :
	if not _is_desktop_window():
		return
	var screen: Vector2i = DisplayServer.screen_get_size()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect()
	if screen.x <= 0 or screen.y <= 0 or usable.size.x <= 0 or usable.size.y <= 0:
		return
	const DESIGN_W: = 720
	const DESIGN_H: = 1280
	const MAX_SCREEN_H_RATIO: = 0.9
	var deco: Vector2i = _desktop_decoration_size()
	var max_outer_h: int = int(floor(float(screen.y) * MAX_SCREEN_H_RATIO))
	max_outer_h = mini(max_outer_h, usable.size.y)
	var max_client_h: int = maxi(1, max_outer_h - deco.y)
	var max_client_w: int = maxi(1, usable.size.x - deco.x)
	var scale: float = minf(
		float(max_client_w) / float(DESIGN_W), 
		float(max_client_h) / float(DESIGN_H)
	)
	scale = minf(scale, 1.0)
	var win_w: int = maxi(1, int(floor(float(DESIGN_W) * scale)))
	var win_h: int = maxi(1, int(floor(float(DESIGN_H) * scale)))
	_desktop_window_applying = true
	DisplayServer.window_set_size(Vector2i(win_w, win_h))
	var outer2: Vector2i = DisplayServer.window_get_size_with_decorations()
	if outer2.x <= 0 or outer2.y <= 0:
		outer2 = Vector2i(win_w + deco.x, win_h + deco.y)
	var pos_x: int = usable.position.x + (usable.size.x - outer2.x) / 2
	var pos_y: int = usable.position.y + (usable.size.y - outer2.y) / 2
	DisplayServer.window_set_position(Vector2i(pos_x, pos_y))
	DisplayServer.window_set_position(_clamp_desktop_window_position(outer2, usable))
	_apply_desktop_content_scale_expand()
	_desktop_window_applying = false
	_save_desktop_window_layout()


func _load_saved_patch_if_any() -> void :
	if OS.has_feature("editor"):
		return
	if not FileAccess.file_exists(HOTFIX_PATCH_FILE):
		return
	# 换了底包（覆盖安装新版 APK）后，手机里残留的旧补丁会覆盖新代码，
	# 造成"装的是新版、跑的却是旧逻辑"这种极难排查的问题。
	# 补丁版本号的前三段记录了它适配的底包版本，对不上就直接丢弃。
	if _drop_patch_if_base_mismatch():
		return
	var loaded: = ProjectSettings.load_resource_pack(HOTFIX_PATCH_FILE, true)
	if loaded:
		print("[Main] 冷启动已加载本地 patch: %s" % HOTFIX_PATCH_FILE)
	else:
		push_warning("[Main] 本地 patch 存在但加载失败: %s" % HOTFIX_PATCH_FILE)


func _drop_patch_if_base_mismatch() -> bool:
	var mgr: = _create_hotfix_manager()
	if mgr == null:
		return false
	var patch_ver: String = mgr.get_local_patch_version()
	if patch_ver.is_empty():
		return false
	var parts: PackedStringArray = patch_ver.split(".")
	if parts.size() < 3:
		return false
	var patch_base: String = parts[0] + "." + parts[1] + "." + parts[2]
	if patch_base == CLIENT_VERSION:
		return false
	print("[Main] 本地补丁 %s 属于底包 %s，与当前底包 %s 不符，已丢弃" % [patch_ver, patch_base, CLIENT_VERSION])
	DirAccess.remove_absolute(HOTFIX_PATCH_FILE)
	DirAccess.remove_absolute("user://patch_version.txt")
	return true


func _reload_after_hotfix() -> void :
	print("[Hotfix] 热更完成，整进程重启以加载新脚本…")
	if OS.has_feature("editor"):
		var err: = get_tree().reload_current_scene()
		if err != OK:
			push_warning("[Hotfix] reload_current_scene 失败 err=%s，改用 change_scene" % str(err))
			get_tree().change_scene_to_file("res://main.tscn")
		return
	OS.set_restart_on_exit(true)
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _create_hotfix_manager() -> HotfixUpdateManager:
	var script: GDScript = load(_HOTFIX_UPDATE_MANAGER_SCRIPT) as GDScript
	if script == null:
		push_error("[Main] 无法加载 update_manager.gd")
		return null
	return script.new() as HotfixUpdateManager


func _create_update_dialog() -> Control:
	var script: GDScript = load(_UPDATE_DIALOG_SCRIPT) as GDScript
	if script == null:
		push_error("[Main] 无法加载 update_dialog.gd")
		return null
	return script.new() as Control

func _try_apply_hotfix_patch() -> bool:
	var manager: = _create_hotfix_manager()
	if manager == null:
		return false
	var info: Dictionary = await manager.check_hotfix_available(self, CLIENT_VERSION)
	if info.is_empty():
		return false

	var dialog: Control = _create_update_dialog()
	if dialog == null:
		return false
	add_child(dialog)
	dialog.setup(info)

	while true:
		var action: = await _await_hotfix_dialog_action(dialog)
		if action == "quit":
			get_tree().quit()
			return false
		if action != "download":
			continue

		var on_progress: = func(fraction: float, status_text: String) -> void :
			dialog.set_progress(fraction, status_text)
		var on_failed: = func(err: String) -> void :
			dialog.show_failure(err)
		if not manager.progress_changed.is_connected(on_progress):
			manager.progress_changed.connect(on_progress)
		if not manager.failed.is_connected(on_failed):
			manager.failed.connect(on_failed)

		var ok: bool = await manager.apply_hotfix(self, info)
		if manager.progress_changed.is_connected(on_progress):
			manager.progress_changed.disconnect(on_progress)
		if manager.failed.is_connected(on_failed):
			manager.failed.disconnect(on_failed)

		if ok:
			if OS.has_feature("editor") and manager.editor_download_only:
				await dialog.show_success_and_wait(
					"下载并校验成功！\n加密 patch 无法在编辑器加载，\n请用已导出的 2.0.9 底包验收。"
				)
				dialog.queue_free()
				return false
			await dialog.show_success_and_wait()
			dialog.queue_free()
			return true

	return false


func _await_hotfix_dialog_action(dialog: Control) -> String:
	var state: = {"value": ""}
	var on_download: = func() -> void :
		state["value"] = "download"
	var on_quit: = func() -> void :
		state["value"] = "quit"
	dialog.download_requested.connect(on_download, CONNECT_ONE_SHOT)
	dialog.quit_requested.connect(on_quit, CONNECT_ONE_SHOT)
	while state["value"] == "":
		await get_tree().process_frame
	return str(state["value"])


func _probe_server_reachable() -> bool:
	var primary: = _GameServerConfig.updates_manifest_url()
	if await _probe_single_url(primary):
		return true
	var fallback_url: = _GameServerConfig.connectivity_fallback_url()
	push_warning("[Main] 热更清单检测失败，尝试备用直连: %s" % fallback_url)
	return await _probe_single_url(fallback_url)


func _probe_single_url(url: String) -> bool:
	var http: = HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var req_err: = http.request(url, [], HTTPClient.METHOD_GET)
	if req_err != OK:
		push_warning("[Main] 联网检测请求未发出 url=%s err=%s" % [url, str(req_err)])
		http.queue_free()
		return false
	var res: Array = await http.request_completed
	http.queue_free()
	var result: int = int(res[0])
	var code: int = int(res[1])
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("[Main] 联网检测失败 url=%s result=%s code=%s" % [url, str(result), str(code)])
		return false
	return true

func _show_startup_network_quit_dialog(message: String) -> void :
	var dlg: = Window.new()
	dlg.title = ""
	dlg.size = Vector2i(520, 400)
	dlg.transparent = true
	dlg.borderless = true
	dlg.unresizable = true
	var quit_game: = func() -> void :
		# Web 导出里 get_tree().quit() 是空操作（浏览器不允许脚本关标签页），
		# 所以网页版点「退出」原来毫无反应。改成重新加载页面，至少能回到干净状态。
		if OS.has_feature("web"):
			var js_bridge: Object = Engine.get_singleton("JavaScriptBridge")
			if js_bridge != null:
				js_bridge.call("eval", "window.location.reload()")
				return
		get_tree().quit()
	dlg.close_requested.connect(quit_game)

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dlg.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label: = Label.new()
	title_label.text = "需要网络"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var message_label: = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
	vbox.add_child(message_label)

	var btn_container: = CenterContainer.new()
	btn_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_container)

	var btn_row: = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_container.add_child(btn_row)

	# 网络刚恢复时不用重启整个游戏：网页版重新加载页面（顺带重下 pck），
	# 其它平台重载当前场景，都会重新走一遍启动探活。
	var retry_btn: = Button.new()
	retry_btn.text = "重试"
	UIStyle.style_popup_button(retry_btn, true, Vector2(140, 50))
	retry_btn.pressed.connect(func() -> void:
		if OS.has_feature("web"):
			var js_bridge: Object = Engine.get_singleton("JavaScriptBridge")
			if js_bridge != null:
				js_bridge.call("eval", "window.location.reload()")
				return
		get_tree().reload_current_scene()
	)
	btn_row.add_child(retry_btn)

	var quit_btn: = Button.new()
	quit_btn.text = "退出"
	UIStyle.style_popup_button(quit_btn, false, Vector2(140, 50))
	quit_btn.pressed.connect(quit_game)
	btn_row.add_child(quit_btn)

	add_child(dlg)
	dlg.popup_centered()
	UIStyle.animate_window_popup(dlg)

func _check_version() -> void :
	print("检查版本 - 当前版本: ", CLIENT_VERSION)


	var urls: Array[String] = _GameServerConfig.updates_manifest_url_candidates()
	for url in urls:
		print("请求URL: ", url)
		var http_request: = HTTPRequest.new()
		http_request.timeout = 10.0
		http_request.accept_gzip = true
		add_child(http_request)
		var err: = http_request.request(url, [], HTTPClient.METHOD_GET)
		if err != OK:
			push_warning("[Main] 版本检查请求未发出 url=%s err=%s" % [url, str(err)])
			http_request.queue_free()
			continue
		var res: Array = await http_request.request_completed
		http_request.queue_free()
		var result: int = int(res[0])
		var response_code: int = int(res[1])
		var body: PackedByteArray = res[3]
		print("版本检查完成 - result: ", result, " response_code: ", response_code, " url=", url)
		if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
			print("版本检查请求失败（将尝试下一备用地址）")
			continue
		if _apply_manifest_version_check(body):
			return
		var _snip: = body.get_string_from_utf8()
		push_warning("[Main] 热更清单非 JSON 或解析失败，将尝试下一备用地址。正文开头: %s" % _snip.substr(0, min(160, _snip.length())).replace("\n", " "))
	print("版本检查请求失败（已尝试 HTTPS 与 HTTP 备用 manifest 地址）")

func _apply_manifest_version_check(body: PackedByteArray) -> bool:
	var raw: = body.get_string_from_utf8()
	var json: = JSON.new()
	var parse_result: = json.parse(raw)
	if parse_result != OK:
		var t: = raw.strip_edges()
		var i: = t.find("{")
		if i > 0:
			parse_result = json.parse(t.substr(i))
		elif not t.begins_with("{") and (t.begins_with("\"success\"") or t.begins_with("'success'")):
			parse_result = json.parse("{" + t)
	if parse_result != OK:
		print("JSON解析失败")
		return false
	var manifest: Variant = json.data
	if not manifest is Dictionary:
		print("热更清单格式错误")
		return false
	var server_version: String = str(manifest.get("version", "1.0.0"))
	var release_notes: String = str(manifest.get("releaseNotes", ""))
	print("服务器最新版本: ", server_version)
	print("本地当前版本: ", CLIENT_VERSION)
	if _version_compare(server_version, CLIENT_VERSION) > 0:
		print("需要更新！")
		_show_force_update_dialog(server_version, release_notes)
	else:
		print("无需更新")
	return true

func _version_token_int(token: String) -> int:
	var t: = token.strip_edges()
	if t.is_empty():
		return 0
	if t.is_valid_int():
		return int(t)
	var acc: = ""
	for i in t.length():
		var ch: = t[i]
		if ch >= "0" and ch <= "9":
			acc += ch
		else:
			break
	if acc.is_empty() or not acc.is_valid_int():
		return 0
	return int(acc)

func _version_compare(v1: String, v2: String) -> int:
	var parts1 = v1.split(".")
	var parts2 = v2.split(".")

	for i in range(max(parts1.size(), parts2.size())):
		var n1: = 0
		var n2: = 0
		if i < parts1.size():
			n1 = _version_token_int(parts1[i])
		if i < parts2.size():
			n2 = _version_token_int(parts2[i])
		if n1 > n2:
			return 1
		elif n1 < n2:
			return -1

	return 0

func _show_force_update_dialog(server_version: String, release_notes: String):
	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2(450, 350)
	dialog.borderless = true
	dialog.transparent = true
	dialog.unresizable = true

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.2, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.5, 0.8, 1)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "必须更新"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	vbox.add_child(title)

	var version_info = Label.new()
	version_info.text = "当前版本: v" + CLIENT_VERSION + "  →  最新版本: v" + server_version
	version_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_info.add_theme_font_size_override("font_size", 16)
	version_info.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(version_info)

	var message = Label.new()
	message.text = "请到群文件下载最新版游戏"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(message)

	if release_notes != "":
		var notes_title = Label.new()
		notes_title.text = "更新内容:"
		notes_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		notes_title.add_theme_font_size_override("font_size", 14)
		notes_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		vbox.add_child(notes_title)

		var notes = Label.new()
		notes.text = release_notes
		notes.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		notes.add_theme_font_size_override("font_size", 14)
		notes.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		notes.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(notes)

	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(150, 50)
	quit_btn.add_theme_font_size_override("font_size", 20)
	_apply_primary_button_style(quit_btn)
	quit_btn.pressed.connect( func():
		get_tree().quit()
	)
	btn_container.add_child(quit_btn)

	add_child(dialog)
	dialog.popup_centered()

func _apply_primary_button_style(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.5, 0.9)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.6, 1.0)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", style_hover)

func _start_game():
	if _boot_started:
		return
	_boot_started = true
	print("启动游戏...")
	# 开发用：命令行带 --skip-login 时跳过登录，直接用本地存档进主城。
	# 正式包启动时不会有这个参数，线上流程完全不受影响。
	if OS.get_cmdline_user_args().has("--skip-login"):
		print("[DEV] --skip-login：跳过登录界面，用本地存档直接进主城")
		_on_login_success(0, "dev", null, "")
		_dev_force_city()
		return
	_init_login_bgm()
	_show_login()


## 开发用：等主界面加载完，自动切到主城视图（只服务于 --skip-login）
func _dev_force_city() -> void:
	for i in range(240):
		await get_tree().process_frame
		if main_ui != null and is_instance_valid(main_ui):
			break
	if main_ui == null or not is_instance_valid(main_ui):
		print("[DEV] 主界面没加载出来")
		return
	await get_tree().create_timer(1.0).timeout
	# 本地存档带「离线奖励待领」时主界面会把 HUD 藏起来等弹窗，
	# 录制需要干净的完整界面 → 这里强制掀开，并补一次水墨皮肤。
	for n in ["top_bar", "main_content", "bottom_nav"]:
		var node = main_ui.get(n)
		if node is CanvasItem:
			(node as CanvasItem).visible = true
	if main_ui.has_method("_add_qq_group_label"):
		main_ui.call("_add_qq_group_label")
	if main_ui.has_method("_show_view"):
		main_ui.call("_show_view", "city")
		print("[DEV] 已切到主城")

func _init_login_bgm():
	var settings = _load_audio_settings()
	if settings["bgm_enabled"]:
		login_bgm_player = AudioStreamPlayer.new()
		login_bgm_player.volume_db = linear_to_db(settings["bgm_volume"])
		add_child(login_bgm_player)
		if ResourceLoader.exists(LOGIN_BGM):
			var stream = load(LOGIN_BGM)
			if stream:
				login_bgm_player.stream = stream

func _load_audio_settings() -> Dictionary:
	var default_settings = {
		"bgm_enabled": true, 
		"bgm_volume": 0.5, 
		"sfx_enabled": true, 
		"sfx_volume": 0.7
	}

	var config = ConfigFile.new()
	if config.load("user://audio_settings.cfg") == OK:
		default_settings["bgm_enabled"] = config.get_value("audio", "bgm_enabled", true)
		default_settings["bgm_volume"] = config.get_value("audio", "bgm_volume", 0.5)

	return default_settings

func _show_login():
	print("创建登录界面...")


	if not ResourceLoader.exists("res://scripts/login_ui.gd"):
		print("错误: login_ui.gd 不存在")
		return

	var LoginUIScript = load("res://scripts/login_ui.gd")
	if LoginUIScript == null:
		print("错误: 无法加载 login_ui.gd!")
		return

	login_ui = LoginUIScript.new()
	if login_ui == null:
		print("错误: 无法创建 login_ui 实例!")
		return

	print("login_ui 创建成功")


	if ResourceLoader.exists("res://scripts/network.gd"):
		var NetworkScript = load("res://scripts/network.gd")
		if NetworkScript != null:
			var network_node = NetworkScript.new()
			network_node.name = "Network"
			login_ui.add_child(network_node)
			_bind_network_signals(network_node)
			print("Network 节点已创建")


	login_ui.main_node = self


	if login_ui.has_signal("login_success"):
		login_ui.login_success.connect(_on_login_success)
		print("login_success 信号已连接")

		var connections = login_ui.get_signal_connection_list("login_success")
		print("login_success 连接数: ", connections.size())
		for conn in connections:
			print("  - 连接到: ", conn.callable)
	else:
		print("警告: login_ui 没有 login_success 信号")

	if login_ui.has_signal("switch_to_main"):
		login_ui.switch_to_main.connect(_on_switch_to_main)
		print("switch_to_main 信号已连接")
	else:
		print("警告: login_ui 没有 switch_to_main 信号")

	add_child(login_ui)
	print("登录界面已添加到场景")

func _process(_delta: float) -> void :
	# 启动页的 logo 要「转起来」：一张不动的图 + 底部进度条，玩家会觉得卡住了。
	# 这里在每一帧自转（绕自身中心），旋转速度与进度无关是有意的 ——
	# 进度条本身是分段的（0.95 之前一直是估算值），跟进度绑死会出现「一顿一顿」。
	if _loading_logo != null and is_instance_valid(_loading_logo):
		_loading_logo.pivot_offset = _loading_logo.size * 0.5
		_loading_logo.rotation = fmod(_loading_logo.rotation + _delta * LOADING_SPIN_SPEED, TAU)
	if not _loading_main_ui_active:
		return
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(MAIN_UI_SCENE_PATH, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_loading_main_ui_active = false
		if _loading_progress_bar:
			_loading_progress_bar.value = 0.95
		var packed: Resource = ResourceLoader.load_threaded_get(MAIN_UI_SCENE_PATH)
		if packed == null or not (packed is PackedScene):
			push_error("main: load_threaded_get 未返回 PackedScene")
			_hide_loading_overlay()
			return
		_complete_main_ui_from_packed(packed as PackedScene)
		if _loading_progress_bar:
			_loading_progress_bar.value = 1.0
		call_deferred("_hide_loading_overlay")
		return
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		_loading_main_ui_active = false
		push_error("主界面场景线程加载失败")
		_hide_loading_overlay()
		return
	if progress.size() > 0 and _loading_progress_bar:
		_loading_progress_bar.value = clampf(float(progress[0]), 0.0, 0.95)

func _show_loading_overlay() -> void :
	if _loading_overlay:
		return
	var layer: = CanvasLayer.new()
	layer.layer = 128
	layer.name = "LoadingOverlay"
	var root: = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var tex: = TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(LOADING_BG_PATH):
		tex.texture = load(LOADING_BG_PATH) as Texture2D
		# 启动首屏的 key art 是蓝紫发光图，和内页的墨底金线完全两套语言。
		# 复用登录页那个去饱和 + 暖墨重上色的 shader，首屏就和整包统一了。
		var shader_path: = "res://assets/shaders/login_ink_bg.gdshader"
		if ResourceLoader.exists(shader_path):
			var mat: = ShaderMaterial.new()
			mat.shader = load(shader_path)
			# 底图换成主城水墨大图后，去饱和要调轻（旧图是蓝紫 key art 才需要 0.8）
			mat.set_shader_parameter("desaturate", 0.06)
			mat.set_shader_parameter("tone_mix", 0.06)
			mat.set_shader_parameter("darken", 0.10)
			mat.set_shader_parameter("vignette", 0.40)
			tex.material = mat
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tex)
	# 启动 logo：阴鱼阳鱼墨像，压在背景正中偏上；进度条还在最底部
	var logo: = TextureRect.new()
	logo.texture = LOGO_MARK
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.offset_left = -110.0
	logo.offset_right = 110.0
	logo.offset_top = -230.0
	logo.offset_bottom = -10.0
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 自转轴心在画面里会随布局变化，统一在 _process 里按 size 重新取中心
	logo.pivot_offset = Vector2(110.0, 110.0)
	root.add_child(logo)
	_loading_logo = logo

	var bottom: = MarginContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -100.0
	bottom.offset_bottom = -28.0
	bottom.add_theme_constant_override("margin_left", 40)
	bottom.add_theme_constant_override("margin_right", 40)
	var bar: = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 28)
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 进度条也别用主题默认的蓝：墨底 + 金填充，和整包一条线
	var bar_bg: = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.055, 0.047, 0.035, 0.85)
	bar_bg.border_width_left = 1
	bar_bg.border_width_top = 1
	bar_bg.border_width_right = 1
	bar_bg.border_width_bottom = 1
	bar_bg.border_color = Color(0.788, 0.635, 0.294, 0.35)
	bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill: = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.788, 0.635, 0.294, 0.85)
	bar.add_theme_stylebox_override("fill", bar_fill)
	bottom.add_child(bar)
	root.add_child(bottom)
	layer.add_child(root)
	add_child(layer)
	_loading_overlay = layer
	_loading_progress_bar = bar

func _hide_loading_overlay() -> void :
	if _loading_overlay:
		_loading_overlay.queue_free()
	_loading_overlay = null
	_loading_progress_bar = null
	_loading_logo = null

func _on_login_success(user_id: int, nickname: String, save_data, token: String):
	print("========== _on_login_success 被调用 ==========")
	print("登录成功: ", nickname)
	print("user_id: ", user_id)
	print("token: ", token)
	print("save_data 是否为 null: ", save_data == null)

	var network_node = null
	if login_ui and login_ui.has_node("Network"):
		network_node = login_ui.get_node("Network")
		print("获取 Network 节点: ", network_node)
		_bind_network_signals(network_node)
		network_node.get_parent().remove_child(network_node)

	_pending_user_id = user_id
	_pending_nickname = nickname
	_pending_save_data = save_data
	_pending_token = token
	_pending_network = network_node

	_show_loading_overlay()

	if login_ui:
		print("释放 login_ui...")
		login_ui.queue_free()
		login_ui = null
		print("login_ui 已释放")
	else:
		print("login_ui 已经是 null")

	if not ResourceLoader.exists(MAIN_UI_SCENE_PATH):
		push_error("错误: main_ui.tscn 不存在")
		_hide_loading_overlay()
		return

	var req_err: Error = ResourceLoader.load_threaded_request(MAIN_UI_SCENE_PATH)
	if req_err != OK:
		push_warning("线程加载启动失败，改用同步加载: ", req_err)
		var main_ui_scene = load(MAIN_UI_SCENE_PATH)
		if main_ui_scene == null:
			_hide_loading_overlay()
			return
		if _loading_progress_bar:
			_loading_progress_bar.value = 1.0
		_complete_main_ui_from_packed(main_ui_scene as PackedScene)
		call_deferred("_hide_loading_overlay")
		return

	_loading_main_ui_active = true
	print("已开始线程加载 main_ui.tscn")

func _complete_main_ui_from_packed(main_ui_scene: PackedScene) -> void :
	print("========== _complete_main_ui_from_packed ==========")
	main_ui = main_ui_scene.instantiate() as Control
	if main_ui == null:
		push_error("错误: 无法实例化 main_ui!")
		call_deferred("_hide_loading_overlay")
		return
	var typed_main_ui: = main_ui as MainUI
	if typed_main_ui == null:
		push_error("错误: main_ui 脚本类型不匹配（预期 MainUI）")
		call_deferred("_hide_loading_overlay")
		return
	typed_main_ui.user_id = _pending_user_id
	typed_main_ui.nickname = _pending_nickname
	typed_main_ui.save_data = _pending_save_data
	typed_main_ui.auth_token = _pending_token
	if typed_main_ui.has_signal("logout"):
		typed_main_ui.logout.connect(_on_logout)
	add_child(typed_main_ui)
	if _pending_network and typed_main_ui.has_method("set_network"):
		typed_main_ui.set_network(_pending_network, _pending_user_id, _pending_nickname)
	main_ui = typed_main_ui
	_pending_network = null
	print("主界面加载完成")

func _on_logout():
	if main_ui:
		main_ui.queue_free()
		main_ui = null

	_show_login()

func _on_switch_to_main():
	if login_ui:
		login_ui.queue_free()
		login_ui = null

func _bind_network_signals(network_node: Node) -> void :
	if network_node == null:
		return
	if network_node.has_signal("force_update_required"):
		if not network_node.force_update_required.is_connected(_on_force_update_required_global):
			network_node.force_update_required.connect(_on_force_update_required_global)

func _on_force_update_required_global(update_info: Dictionary) -> void :
	var latest_version: = String(update_info.get("latestVersion", ""))
	var release_notes: = String(update_info.get("releaseNotes", ""))

	if main_ui:
		main_ui.queue_free()
		main_ui = null

	if login_ui == null:
		_show_login()

	if login_ui and login_ui.has_method("_set_force_update_lock"):
		login_ui.call("_set_force_update_lock", true, "当前客户端版本过低，请先更新后再登录")

	_show_global_force_update_dialog(latest_version, release_notes)

func _show_global_force_update_dialog(server_version: String, release_notes: String) -> void :
	if _force_update_dialog and is_instance_valid(_force_update_dialog):
		_force_update_dialog.popup_centered()
		return

	var dialog = Window.new()
	dialog.title = ""
	dialog.size = Vector2(450, 350)
	dialog.borderless = true
	dialog.transparent = true
	dialog.unresizable = true
	dialog.exclusive = true

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.2, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.5, 0.8, 1)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	dialog.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "必须更新"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	vbox.add_child(title)

	var latest_text: = server_version if server_version != "" else "未知"
	var version_info = Label.new()
	version_info.text = "当前版本: v" + CLIENT_VERSION + "  →  最新版本: v" + latest_text
	version_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_info.add_theme_font_size_override("font_size", 16)
	version_info.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(version_info)

	var message = Label.new()
	message.text = "请到群文件下载最新版游戏"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(message)

	if release_notes != "":
		var notes_title = Label.new()
		notes_title.text = "更新内容:"
		notes_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		notes_title.add_theme_font_size_override("font_size", 14)
		notes_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		vbox.add_child(notes_title)

		var notes = Label.new()
		notes.text = release_notes
		notes.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		notes.add_theme_font_size_override("font_size", 14)
		notes.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		notes.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(notes)

	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var quit_btn = Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(150, 50)
	quit_btn.add_theme_font_size_override("font_size", 20)
	_apply_primary_button_style(quit_btn)
	quit_btn.pressed.connect( func():
		get_tree().quit()
	)
	btn_container.add_child(quit_btn)

	add_child(dialog)
	dialog.popup_centered()
	_force_update_dialog = dialog
	dialog.tree_exited.connect( func():
		_force_update_dialog = null
	)

func play_login_bgm():
	if login_bgm_player and not login_bgm_player.playing:
		login_bgm_player.play()

func stop_login_bgm():
	if login_bgm_player and login_bgm_player.playing:
		login_bgm_player.stop()
