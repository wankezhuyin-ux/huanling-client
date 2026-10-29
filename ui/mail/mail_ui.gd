extends Control

const UIStyle = preload("res://scripts/ui_style.gd")
const GameData = preload("res://scripts/game_data.gd")

var game_manager = null


@onready var mail_list_container: VBoxContainer = $Panel / MarginContainer / VBoxContainer / ScrollContainer / MailListContainer


@onready var unread_label: Label = $Panel / MarginContainer / VBoxContainer / Header / UnreadLabel


@onready var claim_all_btn: Button = $Panel / MarginContainer / VBoxContainer / Header / ClaimAllBtn


var delete_claimed_btn: Button = null


# 邮件页左上角已经有全局「← 返回主城」，右上角再放一个 ✕ 是重复的，已删除。
# 保留这个空引用只为兼容可能存在的旧场景文件（存在才连信号）。
var close_btn: Button = null


var _detail_popup: Control = null


var _selected_mail: MailData = null
var _claim_all_submitting: bool = false
var _claim_single_submitting_mail_id: int = 0

func _find_existing_window_popup(popup_key: String) -> Window:
	for child in get_children():
		if child is Window and str(child.get_meta("popup_key", "")) == popup_key:
			return child
	return null

func _focus_existing_popup(popup_key: String) -> bool:
	var existing = _find_existing_window_popup(popup_key)
	if existing and is_instance_valid(existing):
		existing.show()
		existing.grab_focus()
		return true
	return false

func _mark_popup_key(popup: Window, popup_key: String) -> void :
	popup.set_meta("popup_key", popup_key)

func _ready():

	var panel = $Panel
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	panel.add_theme_stylebox_override("panel", UIStyle.create_panel_style())

	# 右上角 ✕ 已删除（左上角有全局返回）；旧场景里若还留着这个节点就藏起来
	close_btn = get_node_or_null("Panel/MarginContainer/VBoxContainer/Header/CloseBtn") as Button
	if close_btn != null:
		close_btn.visible = false
		close_btn.queue_free()
		close_btn = null
	claim_all_btn.pressed.connect(_on_claim_all_pressed)


	_create_delete_button()


	if MailManager.instance:
		MailManager.instance.mail_list_updated.connect(_on_mail_list_updated)
		MailManager.instance.unread_count_changed.connect(_on_unread_count_changed)
		MailManager.instance.attachment_claimed_success.connect(_on_attachment_claimed)
		MailManager.instance.all_attachments_claimed_success.connect(_on_all_attachments_claimed)
		MailManager.instance.attachment_claim_failed.connect(_on_attachment_claim_failed)
		MailManager.instance.claimed_mails_deleted.connect(_on_claimed_mails_deleted)
		MailManager.instance.mail_deleted.connect(_on_mail_deleted_from_manager)
		MailManager.instance.error_occurred.connect(_on_error)

	var mail_scroll: = mail_list_container.get_parent() as ScrollContainer
	if mail_scroll:
		TouchScrollUtils.configure_scroll(mail_scroll)

	_refresh_mail_list()

func _create_delete_button():
	var header = $Panel / MarginContainer / VBoxContainer / Header

	delete_claimed_btn = Button.new()
	delete_claimed_btn.text = "清理邮件"
	delete_claimed_btn.add_theme_font_size_override("font_size", 16)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.6, 0.2, 0.2)
	btn_style.set_corner_radius_all(0)
	delete_claimed_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.7, 0.3, 0.3)
	hover_style.set_corner_radius_all(0)
	delete_claimed_btn.add_theme_stylebox_override("hover", hover_style)

	delete_claimed_btn.pressed.connect(_on_delete_claimed_pressed)
	header.add_child(delete_claimed_btn)
	header.move_child(delete_claimed_btn, header.get_child_count() - 2)

func set_game_manager(manager):
	game_manager = manager


func _refresh_mail_list():
	if MailManager.instance:
		MailManager.instance.refresh_mail_list()


func _on_mail_list_updated(mails: Array[MailData]):

	for child in mail_list_container.get_children():
		child.queue_free()


	_update_unread_count()


	var claimable_count = MailManager.instance.get_claimable_mails().size()
	claim_all_btn.disabled = claimable_count == 0
	claim_all_btn.text = "一键领取(%d)" % claimable_count


	var claimed_count = 0
	for mail in mails:
		if mail.is_claimed or ( not mail.has_attachments() and mail.is_read):
			claimed_count += 1
	if delete_claimed_btn:
		delete_claimed_btn.disabled = claimed_count == 0
		delete_claimed_btn.text = "清理邮件(%d)" % claimed_count


	if mails.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无邮件"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		mail_list_container.add_child(empty_label)
		return

	var mail_scroll: = mail_list_container.get_parent() as ScrollContainer
	if mail_scroll:
		TouchScrollUtils.configure_scroll(mail_scroll)

	for mail in mails:
		var item = _create_mail_list_item(mail)
		mail_list_container.add_child(item)

func _style_mail_row_button(btn: Button, bg: Color, hover: Color, pressed: Color, border: Color) -> void :
	var st: = StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(0)
	st.set_border_width_all(1)
	st.border_color = border
	btn.add_theme_stylebox_override("normal", st)
	var st_hover: = st.duplicate() as StyleBoxFlat
	st_hover.bg_color = hover
	btn.add_theme_stylebox_override("hover", st_hover)
	var st_pressed: = st.duplicate() as StyleBoxFlat
	st_pressed.bg_color = pressed
	btn.add_theme_stylebox_override("pressed", st_pressed)


func _create_mail_list_item(mail: MailData) -> Control:
	var card = Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 88)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var style = StyleBoxFlat.new()
	# 未读/已读：原来一个偏蓝一个纯黑，在同一列里像两种材质；
	# 改成同一墨色，用左侧细金条 + 标题字色区分未读（见下方 unread 处理）。
	if not mail.is_read:
		style.bg_color = Color(0.080, 0.070, 0.052, 0.86)
	else:
		style.bg_color = Color(0.032, 0.038, 0.038, 0.72)
	style.set_corner_radius_all(0)
	card.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 8
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(row)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(vbox)

	var title_hbox = HBoxContainer.new()
	title_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_hbox)

	if not mail.is_read:
		var unread_icon = Label.new()
		unread_icon.text = "●"
		unread_icon.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		unread_icon.add_theme_font_size_override("font_size", 16)
		title_hbox.add_child(unread_icon)

	var title_label = Label.new()
	title_label.text = mail.title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", 18)
	if not mail.is_read:
		title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	else:
		title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_hbox.add_child(title_label)

	if mail.has_attachments():
		var attach_icon = Label.new()
		attach_icon.text = "📎"
		attach_icon.add_theme_font_size_override("font_size", 16)
		title_hbox.add_child(attach_icon)

		if not mail.is_claimed:
			var claimable_icon = Label.new()
			claimable_icon.text = "✨"
			claimable_icon.add_theme_font_size_override("font_size", 16)
			title_hbox.add_child(claimable_icon)

	var info_label = Label.new()
	var time_text = _format_time(mail.created_at)
	var expire_text = ""
	if MailManager.instance and mail.has_expire_time():
		expire_text = "  |  " + MailManager.instance.get_mail_expire_description(mail)
	info_label.text = "来自: %s  |  %s%s" % [mail.sender, time_text, expire_text]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info_label)

	if mail.has_expire_time():
		var remaining_days = mail.get_remaining_days()
		if remaining_days >= 0 and remaining_days <= 1:
			info_label.add_theme_color_override("font_color", Color(1, 0.5, 0.3))

	if mail.has_attachments() and not mail.is_claimed:
		var attach_label = Label.new()
		attach_label.text = "附件: " + mail.get_attachment_summary()
		attach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		attach_label.add_theme_font_size_override("font_size", 14)
		attach_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
		vbox.add_child(attach_label)

	var btn_box = HBoxContainer.new()
	btn_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_box.add_theme_constant_override("separation", 8)
	row.add_child(btn_box)

	var open_btn = Button.new()
	open_btn.text = "打开"
	open_btn.custom_minimum_size = Vector2(70, 44)
	open_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open_btn.add_theme_font_size_override("font_size", 16)
	open_btn.add_theme_color_override("font_color", Color(0.925, 0.898, 0.840))
	_style_mail_row_button(open_btn, Color(0.032, 0.039, 0.042, 0.72), Color(0.788, 0.635, 0.294, 0.24), Color(0.788, 0.635, 0.294, 0.34), Color(0.788, 0.635, 0.294, 0.62))
	TouchScrollUtils.bind_tap(open_btn, func(): _on_mail_clicked(mail))
	btn_box.add_child(open_btn)

	var delete_btn = Button.new()
	delete_btn.text = "删除"
	delete_btn.custom_minimum_size = Vector2(56, 44)
	delete_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	delete_btn.add_theme_font_size_override("font_size", 15)
	delete_btn.add_theme_color_override("font_color", Color(0.925, 0.898, 0.840))
	# 删除用朱砂线，不当主色块用（红底白字在墨纸底上最扎眼）
	_style_mail_row_button(delete_btn, Color(0.055, 0.045, 0.043, 0.72), Color(0.660, 0.260, 0.220, 0.28), Color(0.660, 0.260, 0.220, 0.40), Color(0.660, 0.260, 0.220, 0.62))
	TouchScrollUtils.bind_tap(delete_btn, func(): _on_delete_mail_row_pressed(mail))
	btn_box.add_child(delete_btn)

	return card



func _format_time(timestamp: int) -> String:
	if timestamp == 0:
		return "未知时间"

	var now = Time.get_unix_time_from_system()
	var diff = now - timestamp

	if diff < 60:
		return "刚刚"
	elif diff < 3600:
		return "%d分钟前" % int(diff / 60)
	elif diff < 86400:
		return "%d小时前" % int(diff / 3600)
	elif diff < 604800:
		return "%d天前" % int(diff / 86400)
	else:
		var dict = Time.get_datetime_dict_from_unix_time(timestamp)
		return "%d-%02d-%02d" % [dict.year, dict.month, dict.day]


func _update_unread_count():
	if MailManager.instance:
		var count = MailManager.instance.unread_count
		if count > 0:
			unread_label.text = "未读: %d" % count
			unread_label.show()
		else:
			unread_label.hide()


func _on_mail_clicked(mail: MailData):
	_selected_mail = mail
	_show_mail_detail(mail)

func _on_mail_deleted_from_manager(mail_id: int, _deleted_count: int) -> void :
	if _detail_popup and is_instance_valid(_detail_popup) and _selected_mail != null and _selected_mail.id == mail_id:
		_detail_popup.queue_free()
		_detail_popup = null
		_selected_mail = null

func _on_delete_mail_row_pressed(mail: MailData) -> void :
	if mail == null or not is_instance_valid(self):
		return
	var warn_attach: = mail.has_attachments() and not mail.is_claimed
	var msg: String
	if warn_attach:
		msg = "该邮件仍有未领取附件，删除后将无法领取，确定删除？\n\n「%s」" % mail.title
	else:
		msg = "确定删除该邮件？\n\n「%s」" % mail.title
	_show_delete_single_confirm(mail, msg)

func _show_delete_single_confirm(mail: MailData, message: String) -> void :
	var popup_key = "mail_delete_single_%d" % mail.id
	if _focus_existing_popup(popup_key):
		return
	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	popup.size = Vector2i(420, 340)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true
	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 22
	vbox.offset_top = 22
	vbox.offset_right = -22
	vbox.offset_bottom = -22
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	main_panel.add_child(vbox)
	var title_label = Label.new()
	title_label.text = "删除邮件"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
	vbox.add_child(title_label)
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 15)
	msg_label.add_theme_color_override("font_color", Color(0.863, 0.836, 0.774))
	vbox.add_child(msg_label)
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_hbox)
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(100, 42)
	cancel_btn.add_theme_font_size_override("font_size", 17)
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_hbox.add_child(cancel_btn)
	var ok_btn = Button.new()
	ok_btn.text = "删除"
	ok_btn.custom_minimum_size = Vector2(100, 42)
	ok_btn.add_theme_font_size_override("font_size", 17)
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func():
		popup.queue_free()
		if MailManager.instance:
			MailManager.instance.delete_mail_by_id(mail.id)
	)
	btn_hbox.add_child(ok_btn)
	add_child(popup)
	popup.popup_centered()


func _show_mail_detail(mail: MailData):

	if _detail_popup:
		_detail_popup.queue_free()


	_detail_popup = _create_detail_popup(mail)
	add_child(_detail_popup)


	if mail.id > 0 and not mail.is_read and MailManager.instance:
		MailManager.instance.fetch_mail_detail(mail.id)


func _create_detail_popup(mail: MailData) -> Control:
	var popup = Panel.new()
	popup.custom_minimum_size = Vector2(500, 500)
	popup.clip_contents = true

	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -250
	popup.offset_top = -250
	popup.offset_right = 250
	popup.offset_bottom = 250

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.057, 0.066, 0.067)
	style.set_corner_radius_all(0)
	style.set_border_width_all(2)
	style.border_color = Color(0.655, 0.531, 0.245)
	popup.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)


	var title_label = Label.new()
	title_label.text = mail.title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	vbox.add_child(title_label)


	var info_label = Label.new()
	info_label.text = "来自: %s  |  %s" % [mail.sender, _format_time(mail.created_at)]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info_label)


	var separator = HSeparator.new()
	vbox.add_child(separator)


	var content_scroll = ScrollContainer.new()
	content_scroll.custom_minimum_size = Vector2(0, 60)
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var content_label = Label.new()
	content_label.text = mail.content if not mail.content.is_empty() else "（无内容）"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("font_size", 16)
	content_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content_scroll.add_child(content_label)
	vbox.add_child(content_scroll)


	if mail.has_attachments():
		var attach_separator = HSeparator.new()
		vbox.add_child(attach_separator)

		var attach_title = Label.new()
		attach_title.text = "附件:"
		attach_title.add_theme_font_size_override("font_size", 16)
		attach_title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
		vbox.add_child(attach_title)

		var attach_label = Label.new()
		attach_label.text = mail.get_attachment_summary()
		attach_label.add_theme_font_size_override("font_size", 16)
		attach_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		vbox.add_child(attach_label)


		if not mail.is_claimed:
			var claim_btn = Button.new()
			claim_btn.text = "领取附件"
			claim_btn.custom_minimum_size = Vector2(150, 45)
			claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.2, 0.6, 0.3)
			btn_style.set_corner_radius_all(0)
			claim_btn.add_theme_stylebox_override("normal", btn_style)
			claim_btn.add_theme_font_size_override("font_size", 18)

			claim_btn.pressed.connect( func(): _on_claim_attachment(mail.id))
			vbox.add_child(claim_btn)
		else:
			var claimed_label = Label.new()
			claimed_label.text = "✓ 已领取"
			claimed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			claimed_label.add_theme_font_size_override("font_size", 16)
			claimed_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			vbox.add_child(claimed_label)


	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIStyle.apply_button_style(close_btn)
	close_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(close_btn)

	return popup


func _on_claim_attachment(mail_id: int):
	if _claim_single_submitting_mail_id == mail_id:
		return
	_claim_single_submitting_mail_id = mail_id
	if MailManager.instance:
		MailManager.instance.claim_attachment(mail_id)
	else:
		_claim_single_submitting_mail_id = 0


func _on_claim_all_pressed():
	if MailManager.instance:
		if _claim_all_submitting:
			return
		var claimable_mails = MailManager.instance.get_claimable_mails()
		if claimable_mails.is_empty():
			_show_alert("提示", "没有可领取的附件")
			return


		var total_gold: int = 0
		var total_yuanbao: int = 0
		var total_exp: int = 0
		var total_items: Dictionary = {}
		var total_pets: Dictionary = {}

		for mail in claimable_mails:
			if mail.has_attachments():
				var attachments = mail.attachments

				if attachments.get("gold", 0) > 0:
					total_gold += attachments.gold
				if attachments.get("yuanbao", 0) > 0:
					total_yuanbao += attachments.yuanbao
				if attachments.get("exp", 0) > 0:
					total_exp += attachments.exp
				for item in attachments.get("items", []):
					var parsed_item = _parse_attachment_item_entry(item)
					if not parsed_item.is_empty():
						var item_id = parsed_item.get("item_id", "未命名物品")
						var quantity = int(parsed_item.get("quantity", 1))
						if total_items.has(item_id):
							total_items[item_id] += quantity
						else:
							total_items[item_id] = quantity
				for pet in attachments.get("pets", []):
					var pet_id = _parse_attachment_pet_entry(pet)
					if not pet_id.is_empty():
						if total_pets.has(pet_id):
							total_pets[pet_id] += 1
						else:
							total_pets[pet_id] = 1

				if attachments.has("type"):
					var item_type = attachments.get("type", "")
					if item_type == "item" and attachments.has("item_id"):
						var item_id = attachments.get("item_id", "未命名物品")
						var quantity = attachments.get("quantity", 1)
						if total_items.has(item_id):
							total_items[item_id] += quantity
						else:
							total_items[item_id] = quantity
					elif item_type == "pet" and attachments.has("pet_id"):
						var pet_id2: String = _parse_attachment_pet_entry(attachments)
						if pet_id2.is_empty():
							pet_id2 = "未知宠物"
						if total_pets.has(pet_id2):
							total_pets[pet_id2] += 1
						else:
							total_pets[pet_id2] = 1
					elif item_type == "gold":
						total_gold += attachments.get("amount", 0)
					elif item_type == "yuanbao":
						total_yuanbao += attachments.get("amount", 0)


		_show_claim_confirm_popup(claimable_mails.size(), total_gold, total_yuanbao, total_exp, total_items, total_pets)


func _show_claim_confirm_popup(mail_count: int, total_gold: int, total_yuanbao: int, total_exp: int, total_items: Dictionary, total_pets: Dictionary):
	var popup_key = "mail_claim_confirm"
	if _focus_existing_popup(popup_key):
		return
	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	popup.size = Vector2i(450, 520)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_vbox.offset_left = 20
	outer_vbox.offset_top = 15
	outer_vbox.offset_right = -20
	outer_vbox.offset_bottom = -15
	outer_vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(outer_vbox)

	var title_label = Label.new()
	title_label.text = "一键领取确认"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	outer_vbox.add_child(title_label)

	var info_label = Label.new()
	info_label.text = "将领取 %d 封邮件的附件" % mail_count
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	outer_vbox.add_child(info_label)


	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(scroll_vbox)


	var summary_parts: Array[String] = []
	if total_gold > 0:
		summary_parts.append("金币 x%d" % total_gold)
	if total_yuanbao > 0:
		summary_parts.append("元宝 x%d" % total_yuanbao)
	if total_exp > 0:
		summary_parts.append("经验 x%d" % total_exp)
	for item_id in total_items:
		summary_parts.append("%s x%d" % [item_id, total_items[item_id]])
	for pet_id in total_pets:
		summary_parts.append("宠物[%s] x%d" % [pet_id, total_pets[pet_id]])

	var summary_text = "获得: " + ", ".join(summary_parts) if not summary_parts.is_empty() else "无附件"
	var summary_label = Label.new()
	summary_label.text = summary_text
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 16)
	summary_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	scroll_vbox.add_child(summary_label)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	outer_vbox.add_child(btn_hbox)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_hbox.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认领取"
	confirm_btn.custom_minimum_size = Vector2(120, 45)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect( func():
		if _claim_all_submitting:
			return
		_claim_all_submitting = true
		confirm_btn.disabled = true
		cancel_btn.disabled = true
		popup.queue_free()
		MailManager.instance.claim_all_attachments()
	)
	btn_hbox.add_child(confirm_btn)

	add_child(popup)
	popup.popup_centered()


func _on_attachment_claimed(mail_id: int, attachments: Dictionary):
	_claim_all_submitting = false
	if _claim_single_submitting_mail_id == mail_id:
		_claim_single_submitting_mail_id = 0

	if _detail_popup:
		_detail_popup.queue_free()
		_detail_popup = null


	var summary = []


	if attachments.get("gold", 0) > 0:
		summary.append("金币x%d" % attachments.gold)
	if attachments.get("yuanbao", 0) > 0:
		summary.append("元宝x%d" % attachments.yuanbao)
	if attachments.get("exp", 0) > 0:
		summary.append("经验x%d" % attachments.exp)
	var claimed_items: Variant = attachments.get("items", [])
	if claimed_items is Array and not claimed_items.is_empty():
		for label in MailData.format_item_attachment_labels(claimed_items):
			summary.append(label)
	if not attachments.get("pets", []).is_empty():
		summary.append("宠物x%d" % attachments.pets.size())


	if attachments.has("type"):
		var attachment_type = attachments.get("type", "")
		if attachment_type == "item" and attachments.has("item_id"):
			var item_name = attachments.get("item_id", "未知物品")
			var quantity = attachments.get("quantity", 1)
			summary.append("%sx%d" % [item_name, quantity])
		elif attachment_type == "pet":
			var pet_name = _parse_attachment_pet_entry(attachments)
			if pet_name.is_empty():
				pet_name = "未知宠物"
			summary.append("宠物[%s]" % pet_name)
		elif attachment_type == "gold":
			var gold_amount = attachments.get("amount", 0)
			if gold_amount > 0:
				summary.append("金币x%d" % gold_amount)
		elif attachment_type == "yuanbao":
			var yuanbao_amount = attachments.get("amount", 0)
			if yuanbao_amount > 0:
				summary.append("元宝x%d" % yuanbao_amount)

	var has_sealed_suit: = false
	for item_data in attachments.get("items", []):
		if item_data is Dictionary and str(item_data.get("type", "")) == "sealed_suit":
			has_sealed_suit = true
			break
	if attachments.get("type", "") == "sealed_suit":
		has_sealed_suit = true
	var message = "获得: " + ", ".join(summary) if not summary.is_empty() else "领取成功"
	if has_sealed_suit:
		message += "\n\n封印套装请在【背包 → 装备】分页查看。"
	_show_alert("领取成功", message)
	_refresh_pet_list_after_mail_claim_if_needed(attachments)

func _refresh_pet_list_after_mail_claim_if_needed(attachments_or_claimed) -> void :
	var has_pets: = false
	if attachments_or_claimed is Dictionary:
		var att: Dictionary = attachments_or_claimed
		if not att.get("pets", []).is_empty():
			has_pets = true
		elif str(att.get("type", "")).strip_edges() == "pet":
			has_pets = att.has("pet_id") or att.has("petId")
	elif attachments_or_claimed is Array:
		for entry in attachments_or_claimed:
			if entry is Dictionary and _mail_claim_entry_has_pets(entry):
				has_pets = true
				break
	if not has_pets:
		return
	var gm: = GameManager.instance
	if gm == null or not gm.has_method("_find_main_ui_node"):
		return
	var main_ui: Node = gm._find_main_ui_node()
	if main_ui != null and main_ui.has_method("_refresh_pet_roster_after_authority_reward"):
		main_ui.call_deferred("_refresh_pet_roster_after_authority_reward")

func _mail_claim_entry_has_pets(entry: Dictionary) -> bool:
	var attachments = entry.get("attachments", {})
	if not attachments is Dictionary:
		return false
	if not attachments.get("pets", []).is_empty():
		return true
	return str(attachments.get("type", "")).strip_edges() == "pet" and (attachments.has("pet_id") or attachments.has("petId"))

func _on_all_attachments_claimed(claimed_list: Array, partial_warning: String = ""):
	_claim_all_submitting = false
	_claim_single_submitting_mail_id = 0
	if _detail_popup:
		_detail_popup.queue_free()
		_detail_popup = null

	if claimed_list.is_empty():
		_show_alert("无法领取", "背包、装备背包或宠物栏空间不足，无法领取附件。\n\n请整理后再试。")
		return

	var total_gold: int = 0
	var total_yuanbao: int = 0
	var total_exp: int = 0
	var total_items: Dictionary = {}
	var total_pets: Dictionary = {}

	for item in claimed_list:
		var attachments = item.get("attachments", {})

		if attachments.get("gold", 0) > 0:
			total_gold += attachments.gold
		if attachments.get("yuanbao", 0) > 0:
			total_yuanbao += attachments.yuanbao
		if attachments.get("exp", 0) > 0:
			total_exp += attachments.exp
		for i in attachments.get("items", []):
			var parsed_item = _parse_attachment_item_entry(i)
			if not parsed_item.is_empty():
				var item_id = parsed_item.get("item_id", "未命名物品")
				var quantity = int(parsed_item.get("quantity", 1))
				if total_items.has(item_id):
					total_items[item_id] += quantity
				else:
					total_items[item_id] = quantity
		for p in attachments.get("pets", []):
			var pet_id = _parse_attachment_pet_entry(p)
			if not pet_id.is_empty():
				if total_pets.has(pet_id):
					total_pets[pet_id] += 1
				else:
					total_pets[pet_id] = 1

		if attachments.has("type"):
			var item_type = attachments.get("type", "")
			if item_type == "item" and attachments.has("item_id"):
				var item_id = attachments.get("item_id", "未命名物品")
				var quantity = attachments.get("quantity", 1)
				if total_items.has(item_id):
					total_items[item_id] += quantity
				else:
					total_items[item_id] = quantity
			elif item_type == "pet":
				var pet_name2: String = _parse_attachment_pet_entry(attachments)
				if pet_name2.is_empty():
					pet_name2 = "未知宠物"
				if total_pets.has(pet_name2):
					total_pets[pet_name2] += 1
				else:
					total_pets[pet_name2] = 1
			elif item_type == "gold":
				total_gold += attachments.get("amount", 0)
			elif item_type == "yuanbao":
				total_yuanbao += attachments.get("amount", 0)

	var summary_parts: Array[String] = []
	if total_gold > 0:
		summary_parts.append("金币x%d" % total_gold)
	if total_yuanbao > 0:
		summary_parts.append("元宝x%d" % total_yuanbao)
	if total_exp > 0:
		summary_parts.append("经验x%d" % total_exp)
	for item_id in total_items:
		summary_parts.append("%sx%d" % [item_id, total_items[item_id]])
	for pet_id in total_pets:
		summary_parts.append("宠物[%s]x%d" % [pet_id, total_pets[pet_id]])

	var message: String
	if not summary_parts.is_empty():
		message = "成功领取 %d 封邮件\n获得: " % claimed_list.size() + ", ".join(summary_parts)
	else:
		message = "成功领取 %d 封邮件" % claimed_list.size()
	var warn_t: String = str(partial_warning).strip_edges()
	if not warn_t.is_empty():
		message = message + "\n\n" + warn_t
	var title: = "领取完成" if not warn_t.is_empty() else "领取成功"
	_show_alert(title, message)
	_refresh_pet_list_after_mail_claim_if_needed(claimed_list)

func _parse_attachment_item_entry(entry) -> Dictionary:
	if entry is Dictionary:
		var d: Dictionary = entry
		var name_key: String = str(d.get("name", "")).strip_edges()
		if name_key.is_empty():
			name_key = str(d.get("setName", "")).strip_edges()
		if name_key.is_empty():
			name_key = str(d.get("id", "")).strip_edges()
		if name_key.is_empty():
			name_key = str(d.get("item_id", "")).strip_edges()
		var sub_items: Array = d.get("items", []) as Array
		if name_key.is_empty() and not sub_items.is_empty():
			if sub_items[0] is Dictionary:
				var first: Dictionary = sub_items[0] as Dictionary
				var fn: String = str(first.get("name", "")).strip_edges()
				if not fn.is_empty() and sub_items.size() == 1:
					name_key = fn
					var q0: int = max(1, int(first.get("count", first.get("quantity", 1))))
					return {"item_id": name_key, "quantity": q0}
				if not fn.is_empty() and sub_items.size() > 1:
					name_key = "%s 等（共%d件）" % [fn, sub_items.size()]
		if name_key.is_empty() and d.has("setName"):
			var sn: String = str(d.get("setName", "")).strip_edges()
			if not sn.is_empty() and not sub_items.is_empty():
				name_key = sn + "（%d件）" % sub_items.size()
		if name_key.is_empty() and d.has("setName"):
			name_key = str(d.get("setName", "未命名物品"))
		if name_key.is_empty():
			name_key = "未命名物品"
		var quantity: int = max(1, int(d.get("count", d.get("quantity", 1))))
		if not sub_items.is_empty() and str(d.get("name", "")).strip_edges().is_empty() and not str(d.get("setName", "")).strip_edges().is_empty():
			quantity = 1
		return {"item_id": name_key, "quantity": quantity}
	if entry is String:
		return {"item_id": str(entry), "quantity": 1}
	return {}

func _parse_attachment_pet_entry(entry) -> String:
	if entry is Dictionary:
		var d: Dictionary = entry
		var by_name: String = str(d.get("petName", d.get("name", ""))).strip_edges()
		if not by_name.is_empty():
			return by_name
		var pid: String = str(d.get("pet_id", d.get("petId", d.get("id", "")))).strip_edges()
		if pid.is_empty() or pid == "unknown":
			return "未知宠物"
		var pd: Dictionary = GameData.PET_DATA.get(pid, {})
		var mapped_name: String = str(pd.get("name", "")).strip_edges()
		if not mapped_name.is_empty():
			return mapped_name
		return "未知宠物"
	if entry is String:
		var sid: = str(entry).strip_edges()
		if sid.is_empty():
			return "未知宠物"
		var pd2: Dictionary = GameData.PET_DATA.get(sid, {})
		var mapped2: String = str(pd2.get("name", "")).strip_edges()
		return mapped2 if not mapped2.is_empty() else "未知宠物"
	return ""


func _on_attachment_claim_failed(error: String):
	_claim_all_submitting = false
	_claim_single_submitting_mail_id = 0
	_show_alert("领取失败", error)


func _on_delete_claimed_pressed():
	if MailManager.instance:
		var mails = MailManager.instance.get_mails()
		var claimed_count = 0
		for mail in mails:
			if mail.is_claimed or ( not mail.has_attachments() and mail.is_read):
				claimed_count += 1

		if claimed_count == 0:
			_show_alert("提示", "没有可清理的邮件")
			return

		_show_delete_confirm_popup(claimed_count)


func _show_delete_confirm_popup(count: int):
	var popup_key = "mail_delete_confirm"
	if _focus_existing_popup(popup_key):
		return
	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	popup.size = Vector2i(400, 280)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "清理邮件"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = "将删除 %d 封已领取附件的邮件\n未领取附件的邮件将保留" % count
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 16)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	vbox.add_child(msg_label)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(100, 45)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.style_popup_button(cancel_btn, false)
	cancel_btn.pressed.connect( func(): popup.queue_free())
	btn_hbox.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "确认删除"
	confirm_btn.custom_minimum_size = Vector2(120, 45)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.6, 0.2, 0.2)
	btn_style.set_corner_radius_all(0)
	confirm_btn.add_theme_stylebox_override("normal", btn_style)
	confirm_btn.pressed.connect( func():
		popup.queue_free()
		MailManager.instance.delete_claimed_mails()
	)
	btn_hbox.add_child(confirm_btn)

	add_child(popup)
	popup.popup_centered()


func _on_claimed_mails_deleted(deleted_count: int):
	_show_alert("清理完成", "已删除 %d 封邮件" % deleted_count)


func _on_error(error: String):
	if error == "获取邮件详情失败" or error.begins_with("获取邮件详情失败（HTTP "):

		return
	if error == "没有可领取的邮件":

		if MailManager.instance:
			MailManager.instance.refresh_mail_list()
		return
	_show_alert("错误", error)


func _show_alert(title: String, message: String):
	var popup_key = "mail_alert:%s:%s" % [title, message]
	if _focus_existing_popup(popup_key):
		return
	var popup = Window.new()
	_mark_popup_key(popup, popup_key)
	popup.title = ""
	popup.size = Vector2i(450, 600)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true

	var main_panel = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	popup.add_child(main_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var msg_container = VBoxContainer.new()
	msg_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(msg_container)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_container.add_child(msg_label)

	var ok_btn = Button.new()
	ok_btn.text = "确定"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): popup.queue_free())
	vbox.add_child(ok_btn)

	add_child(popup)
	popup.popup_centered()


func _on_unread_count_changed(count: int):
	_update_unread_count()


func _on_close_pressed():
	queue_free()
