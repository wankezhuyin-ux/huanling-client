class_name BattleLogReport
extends RefCounted

const UIStyle = preload("res://scripts/ui_style.gd")

static func show_arena_history_list_dialog(parent: Control, records: Array) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var dialog: = Window.new()
	dialog.title = ""
	dialog.size = Vector2i(620, 560)
	dialog.transparent = true
	dialog.borderless = true
	dialog.unresizable = true
	dialog.close_requested.connect( func(): dialog.queue_free())
	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dialog.add_child(main_panel)
	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = "挑战记录"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var hint: = Label.new()
	if records.is_empty():
		hint.text = "暂无挑战记录"
	else:
		hint.text = "共 %d 场" % records.size()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
	vbox.add_child(hint)
	var scroll: = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var list_vb: = VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.custom_minimum_size = Vector2(560, 0)
	list_vb.add_theme_constant_override("separation", 8)
	scroll.add_child(list_vb)
	for rec in records:
		if not (rec is Dictionary):
			continue
		var md: = rec as Dictionary
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var lab: = Label.new()
		lab.text = format_arena_record_summary(md)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_font_size_override("font_size", 14)
		lab.add_theme_color_override("font_color", Color(0.894, 0.864, 0.803))
		row.add_child(lab)
		var log_arr: = parse_battle_log_array(md.get("battleLog", md.get("battle_log", [])))
		if log_has_combat_steps(log_arr):
			var rb: = Button.new()
			rb.text = "查看战报"
			rb.custom_minimum_size = Vector2(118, 32)
			rb.add_theme_font_size_override("font_size", 13)
			_style_small_card_button(rb)
			var title: = build_arena_replay_title(md)
			rb.pressed.connect( func():
				dialog.queue_free()
				show_replay_dialog(parent, title, log_arr)
			)
			row.add_child(rb)
		list_vb.add_child(row)
	var ok_btn: = Button.new()
	ok_btn.text = "关闭"
	UIStyle.style_popup_button(ok_btn, true)
	ok_btn.pressed.connect( func(): dialog.queue_free())
	vbox.add_child(ok_btn)
	parent.add_child(dialog)
	dialog.popup_centered()


static func show_replay_dialog(parent: Control, title_text: String, log_arr: Array) -> void :
	if parent == null or not is_instance_valid(parent):
		return
	var popup: = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect( func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			popup.queue_free()
	)
	popup.add_child(bg)
	var panel: = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 500)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -250
	panel.offset_right = 300
	panel.offset_bottom = 250
	popup.add_child(panel)
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.057, 0.066, 0.067, 0.98)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.6, 0.5, 0.3)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	var main_margin: = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 15)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(main_margin)
	var vbox: = VBoxContainer.new()
	main_margin.add_child(vbox)
	var title_label: = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title_label)
	var sc: = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(sc)
	var log_margin: = MarginContainer.new()
	log_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.add_theme_constant_override("margin_left", 10)
	log_margin.add_theme_constant_override("margin_right", 10)
	log_margin.add_theme_constant_override("margin_top", 5)
	log_margin.add_theme_constant_override("margin_bottom", 5)
	sc.add_child(log_margin)
	var log_container: = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 2)
	log_margin.add_child(log_container)
	var side_map: = build_side_map(log_arr)
	if log_arr.is_empty():
		var empty_label: = Label.new()
		empty_label.text = "（战报为空或无法解析）"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		log_container.add_child(empty_label)
	else:
		for entry in log_arr:
			if not (entry is Dictionary):
				continue
			var entry_label: = Label.new()
			entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry_label.add_theme_font_size_override("font_size", 15)
			var entry_dict: = entry as Dictionary
			var formatted: = format_log_line(entry_dict, side_map)
			entry_label.text = strip_bbcode(formatted)
			entry_label.add_theme_color_override("font_color", entry_color(entry_dict, side_map))
			var entry_type: = str(entry_dict.get("type", ""))
			if entry_type in ["start", "round", "combo_trigger", "victory", "defeat", "info"]:
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			log_container.add_child(entry_label)
	var btn_row: = HBoxContainer.new()
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_row)
	var ok_btn: = Button.new()
	ok_btn.text = "关闭"
	ok_btn.custom_minimum_size = Vector2(150, 45)
	ok_btn.add_theme_font_size_override("font_size", 18)
	ok_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var btn_normal: = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.072, 0.080, 0.079)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(0.714, 0.578, 0.267)
	btn_normal.corner_radius_top_left = 10
	btn_normal.corner_radius_top_right = 10
	btn_normal.corner_radius_bottom_left = 10
	btn_normal.corner_radius_bottom_right = 10
	ok_btn.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover: = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.072, 0.080, 0.079)
	ok_btn.add_theme_stylebox_override("hover", btn_hover)
	ok_btn.pressed.connect( func(): popup.queue_free())
	btn_row.add_child(ok_btn)
	parent.add_child(popup)


static func format_arena_record_summary(record: Dictionary) -> String:
	var opponent: = str(record.get("opponentName", record.get("opponent_name", "对手"))).strip_edges()
	if opponent.is_empty():
		opponent = "对手"
	var victory: = bool(record.get("victory", false))
	var score_delta: = int(record.get("scoreDelta", record.get("score_delta", 0)))
	var time_text: = format_record_time(str(record.get("createdAt", record.get("created_at", ""))))
	var result_text: = "胜利" if victory else "失败"
	var points_text: = "竞技点 %+d" % score_delta
	if not _arena_record_points_settled(record):
		points_text = "未结算"
	return "%s · vs %s · %s · %s" % [time_text, opponent, result_text, points_text]


static func build_arena_replay_title(record: Dictionary) -> String:
	var opponent: = str(record.get("opponentName", record.get("opponent_name", "对手"))).strip_edges()
	if opponent.is_empty():
		opponent = "对手"
	var victory: = bool(record.get("victory", false))
	var score_delta: = int(record.get("scoreDelta", record.get("score_delta", 0)))
	var result_text: = "胜利" if victory else "失败"
	var points_text: = "竞技点 %+d" % score_delta
	if not _arena_record_points_settled(record):
		points_text = "未结算"
	return "战斗战报 · vs %s · %s · %s" % [opponent, result_text, points_text]


static func _arena_record_points_settled(record: Dictionary) -> bool:
	var status: = str(record.get("status", "")).strip_edges()
	if status.is_empty():
		return true
	return status == "confirmed"


static func format_record_time(raw: String) -> String:
	var s: = raw.strip_edges()
	if s.is_empty():
		return "--:--"

	if s.ends_with("Z") or s.ends_with("z"):
		var t_idx: = s.find("T")
		if t_idx > 0 and s.length() >= t_idx + 6 and s.length() >= 10 and s[4] == "-" and s[7] == "-":
			var hh: = int(s.substr(t_idx + 1, 2))
			var mi: = int(s.substr(t_idx + 4, 2))
			var bj_h: = int((hh + 8) % 24)
			return "%s-%s %02d:%02d" % [s.substr(5, 2), s.substr(8, 2), bj_h, mi]
	if s.length() >= 16 and s[4] == "-" and s[7] == "-":
		return "%s-%s %s" % [s.substr(5, 2), s.substr(8, 2), s.substr(11, 5)]
	return s


static func parse_battle_log_array(raw: Variant) -> Array:
	if raw is Array:
		return raw
	if raw == null:
		return []
	var text: = str(raw).strip_edges()
	if text.is_empty():
		return []
	var json: = JSON.new()
	if json.parse(text) == OK and json.data is Array:
		return json.data
	return []


static func log_has_combat_steps(log: Array) -> bool:
	for e in log:
		if not (e is Dictionary):
			continue
		var t: = str((e as Dictionary).get("type", ""))
		if t == "round" or t == "attack":
			return true
	return false


static func build_side_map(log: Array) -> Dictionary:
	var out: = {}
	for e in log:
		if not (e is Dictionary):
			continue
		var d: = e as Dictionary
		var t: = str(d.get("type", ""))
		var side: = ""
		if t == "player_info" or t == "pet_info":
			side = "ally"
		elif t == "enemy_info" or t == "enemy_pet_info":
			side = "enemy"
		if side.is_empty():
			continue
		var name_raw: = str(d.get("name", "")).strip_edges()
		if name_raw.is_empty():
			continue
		out[name_raw] = side
		var norm: = normalize_actor_name(name_raw)
		if not norm.is_empty():
			out[norm] = side
	return out


static func strip_bbcode(bbcode_text: String) -> String:
	var result: = ""
	var in_tag: = false
	for ch in bbcode_text:
		if ch == "[":
			in_tag = true
		elif ch == "]":
			in_tag = false
		elif not in_tag:
			result += ch
	return result


static func entry_color(entry: Dictionary, side_map: Dictionary) -> Color:
	var entry_type: String = str(entry.get("type", ""))
	var is_mine: = false
	var attacker: = str(entry.get("attacker", ""))
	var target: = str(entry.get("target", ""))
	if attacker != "" and side_map.has(attacker):
		is_mine = str(side_map.get(attacker, "")) == "ally"
	elif target != "" and side_map.has(target):
		is_mine = str(side_map.get(target, "")) == "ally"
	match entry_type:
		"start", "combo_trigger":
			return Color(1, 0.9, 0.5)
		"player_info", "pet_info":
			return Color(0.4, 1.0, 0.4)
		"enemy_info", "enemy_pet_info":
			return Color(1.0, 0.4, 0.4)
		"info":
			return Color(0.072, 0.080, 0.079)
		"round":
			return Color(0.9, 0.85, 0.6)
		"combo_attack":
			return Color(1, 0.85, 0.4)
		"joint_attack":
			return Color(0.072, 0.080, 0.079)
		"miss", "dodge":
			return Color(1, 0.6, 0.6) if not is_mine else Color(0.4, 1.0, 0.4)
		"attack", "triple_shot_hit", "kuihua_hit":
			if entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)):
				return Color(1, 0.6, 0.6)
			return Color(0.4, 1.0, 0.4)
		"enemy_dead", "pet_dead", "player_dead":
			return Color(1, 0.85, 0.3)
		"victory":
			return Color(0.3, 1.0, 0.3)
		"defeat":
			return Color(1.0, 0.3, 0.3)
		"skill_splash":
			return Color(0.072, 0.080, 0.079)
		"skill_double_shot":
			return Color(1.0, 0.82, 0.45)
		"skill_divine_protect":
			return Color(0.75, 1.0, 0.55)
		"skill_counter_attack":
			return Color(1.0, 0.65, 0.45)
		_:
			return Color(0.7, 0.7, 0.7)


static func format_log_line(entry: Dictionary, side_map: Dictionary = {}) -> String:
	var t: = str(entry.get("type", ""))
	var ally_color: = "#66E08A"
	var enemy_color: = "#FF7FB3"
	var neutral_color: = "#E8E8E8"
	var accent_color: = "#FFD27A"
	match t:
		"start", "info":
			return "[color=%s]%s[/color]" % [neutral_color, bbcode_escape(str(entry.get("message", "")).strip_edges())]
		"player_info":
			return "[color=%s]【我方修士】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				ally_color, 
				bbcode_escape(str(entry.get("name", "?"))), 
				fmt_int(entry.get("hp", "?")), 
				fmt_int(entry.get("maxHp", entry.get("max_hp", "?"))), 
				fmt_int(entry.get("attack", "?")), 
				fmt_int(entry.get("defense", "?")), 
				fmt_int(entry.get("agility", "?")), 
				bbcode_escape(str(entry.get("element", "?"))), 
			]
		"pet_info":
			return "[color=%s]【我方灵兽】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				ally_color, 
				bbcode_escape(str(entry.get("name", "?"))), 
				fmt_int(entry.get("hp", "?")), 
				fmt_int(entry.get("maxHp", entry.get("max_hp", "?"))), 
				fmt_int(entry.get("attack", "?")), 
				fmt_int(entry.get("defense", "?")), 
				fmt_int(entry.get("agility", "?")), 
				bbcode_escape(str(entry.get("element", "?"))), 
			]
		"enemy_info", "enemy_pet_info":
			return "[color=%s]【敌方】%s：HP %s/%s 攻%s 防%s 敏%s 属%s[/color]" % [
				enemy_color, 
				bbcode_escape(str(entry.get("name", "?"))), 
				fmt_int(entry.get("hp", "?")), 
				fmt_int(entry.get("maxHp", entry.get("max_hp", "?"))), 
				fmt_int(entry.get("attack", "?")), 
				fmt_int(entry.get("defense", "?")), 
				fmt_int(entry.get("agility", "?")), 
				bbcode_escape(str(entry.get("element", "?"))), 
			]
		"round":
			return "[color=%s]—— 第 %s 回合 ——[/color]" % [accent_color, bbcode_escape(str(entry.get("round", "?")))]
		"miss":
			var miss_attacker: = str(entry.get("attacker", "?"))
			var miss_color: = side_color(str(entry.get("attackerRole", "")), miss_attacker, ally_color, enemy_color, side_map)
			return "[color=%s]【%s】对【%s】出手未中[/color]" % [miss_color, bbcode_escape(miss_attacker), bbcode_escape(str(entry.get("target", "?")))]
		"dodge":
			var dodge_target: = str(entry.get("target", "?"))
			var dodge_color: = side_color(str(entry.get("targetRole", "")), dodge_target, ally_color, enemy_color, side_map)
			return "[color=%s]【%s】闪过了【%s】的攻势[/color]" % [dodge_color, bbcode_escape(dodge_target), bbcode_escape(str(entry.get("attacker", "?")))]
		"attack", "triple_shot_hit", "kuihua_hit":
			var dmg: = fmt_int(entry.get("damage", 0))
			var attacker: = str(entry.get("attacker", "?"))
			var target: = str(entry.get("target", "?"))
			var atk_color: = side_color(str(entry.get("attackerRole", "")), attacker, ally_color, enemy_color, side_map)
			if entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)):
				atk_color = enemy_color
			elif entry.get("isPetAttack", entry.get("is_pet_attack", false)) or side_map.get(attacker, "") == "ally":
				atk_color = ally_color
			var skill_prefix: = "【葵花点穴】" if str(entry.get("type", "")) == "kuihua_hit" else ""
			var line: = "[color=%s]%s【%s】攻【%s】造成 %s 伤害" % [atk_color, skill_prefix, bbcode_escape(attacker), bbcode_escape(target), dmg]
			if entry.has("targetHp") or entry.has("target_hp"):
				var thp = entry.get("targetHp", entry.get("target_hp"))
				var tmh = entry.get("targetMaxHp", entry.get("target_max_hp", null))
				if tmh != null:
					line += "（目标剩余 HP %s/%s）" % [fmt_int(thp), fmt_int(tmh)]
				else:
					line += "（目标剩余 HP %s）" % fmt_int(thp)
			var em: = str(entry.get("elementMsg", entry.get("element_msg", ""))).strip_edges()
			var soul_bonus: = int(entry.get("petSoulBonusPercent", entry.get("pet_soul_bonus_percent", 0)))
			if soul_bonus > 0 and em.find("魂魄+") < 0:
				em = ("%s （魂魄+%d%%）" % [em, soul_bonus]).strip_edges()
			var noble_bonus: = int(entry.get("noblePetBonusPercent", entry.get("noble_pet_bonus_percent", 0)))
			if noble_bonus > 0 and bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))) and em.find("贵族+") < 0:
				em = ("%s （贵族+%d%%）" % [em, noble_bonus]).strip_edges()
			if not em.is_empty():
				line += " %s" % bbcode_escape(em)
			line += "[/color]"
			return line
		"combo_trigger":
			return "[color=%s]%s[/color]" % [accent_color, bbcode_escape(str(entry.get("message", "连击触发")).strip_edges())]
		"combo_attack":
			var combo_attacker: = str(entry.get("attacker", "?"))
			var combo_color: = side_color(str(entry.get("attackerRole", "")), combo_attacker, ally_color, enemy_color, side_map)
			return "[color=%s]连击追击：【%s】[/color]" % [combo_color, bbcode_escape(combo_attacker)]
		"joint_attack":
			return "[color=%s]合击：【%s】与【%s】齐攻【%s】[/color]" % [
				ally_color, 
				bbcode_escape(str(entry.get("player", "?"))), 
				bbcode_escape(str(entry.get("pet", "?"))), 
				bbcode_escape(str(entry.get("target", "?"))), 
			]
		"enemy_dead":
			return "[color=%s]【%s】败退离场[/color]" % [enemy_color, bbcode_escape(str(entry.get("name", "?")))]
		"pet_dead":
			return "[color=%s]【%s】灵兽力竭[/color]" % [ally_color, bbcode_escape(str(entry.get("name", "?")))]
		"player_dead":
			return "[color=%s]【%s】修士力竭[/color]" % [ally_color, bbcode_escape(str(entry.get("name", "?")))]
		"victory", "defeat":
			return "[color=%s]%s[/color]" % [accent_color, bbcode_escape(str(entry.get("message", t)).strip_edges())]
		"skill_splash":
			var ms: = str(entry.get("message", "")).strip_edges()
			if not ms.is_empty():
				return "[color=#7FD4FF]%s[/color]" % bbcode_escape(ms)
			return "[color=#7FD4FF]【溅射】[color=#E8E8E8]%s[/color] 波及 [color=#E8E8E8]%s[/color]，伤害 [color=#FFB86B]%s[/color]（剩余 HP %s/%s）[/color]" % [
				bbcode_escape(str(entry.get("attacker", "?"))), 
				bbcode_escape(str(entry.get("target", "?"))), 
				fmt_int(entry.get("damage", 0)), 
				fmt_int(entry.get("targetHp", entry.get("target_hp", "?"))), 
				fmt_int(entry.get("targetMaxHp", entry.get("target_max_hp", "?"))), 
			]
		"skill_double_shot":
			var md: = str(entry.get("message", "")).strip_edges()
			if not md.is_empty():
				return "[color=#FFD27A]%s[/color]" % bbcode_escape(md)
			return "[color=#FFD27A]【连射】第 %s 段 [color=#E8E8E8]%s[/color] → [color=#E8E8E8]%s[/color]，伤害 [color=#FFB86B]%s[/color]（剩余 HP %s/%s）[/color]" % [
				bbcode_escape(str(entry.get("hitIndex", entry.get("hit_index", "?")))), 
				bbcode_escape(str(entry.get("attacker", "?"))), 
				bbcode_escape(str(entry.get("target", "?"))), 
				fmt_int(entry.get("damage", 0)), 
				fmt_int(entry.get("targetHp", entry.get("target_hp", "?"))), 
				fmt_int(entry.get("targetMaxHp", entry.get("target_max_hp", "?"))), 
			]
		"skill_divine_protect":
			var mdv: = str(entry.get("message", "")).strip_edges()
			if not mdv.is_empty():
				return "[color=#B8F28A]%s[/color]" % bbcode_escape(mdv)
			return "[color=#B8F28A]【神佑】[color=#E8E8E8]%s[/color] 触发，恢复后生命约 [color=#FFB86B]%s[/color][/color]" % [
				bbcode_escape(str(entry.get("target", "?"))), 
				fmt_int(entry.get("hpRestored", entry.get("hp_restored", "?"))), 
			]
		"skill_counter_attack":
			var mc: = str(entry.get("message", "")).strip_edges()
			if not mc.is_empty():
				return "[color=#FFB86B]%s[/color]" % bbcode_escape(mc)
			return "[color=#FFB86B]【反击】[color=#E8E8E8]%s[/color] 反击 [color=#E8E8E8]%s[/color]，伤害 [color=#FF9F7A]%s[/color]（目标剩余 HP %s/%s）[/color]" % [
				bbcode_escape(str(entry.get("attacker", "?"))), 
				bbcode_escape(str(entry.get("target", "?"))), 
				fmt_int(entry.get("damage", 0)), 
				fmt_int(entry.get("targetHp", entry.get("target_hp", "?"))), 
				fmt_int(entry.get("targetMaxHp", entry.get("target_max_hp", "?"))), 
			]
		_:
			var msg_only: = str(entry.get("message", "")).strip_edges()
			if not msg_only.is_empty():
				return "[color=%s]%s[/color]" % [neutral_color, bbcode_escape(msg_only)]
			return "[color=%s]战斗记录：%s[/color]" % [neutral_color, bbcode_escape(str(entry.get("type", "未知")))]


static func bbcode_escape(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")


static func fmt_int(v: Variant) -> String:
	if v == null:
		return "0"
	match typeof(v):
		TYPE_INT:
			return str(int(v))
		TYPE_FLOAT:
			return str(int(round(float(v))))
		TYPE_STRING:
			var s: = str(v).strip_edges()
			if s.is_valid_int():
				return s
			if s.is_valid_float():
				return str(int(round(float(s))))
			return bbcode_escape(s)
		_:
			return bbcode_escape(str(v))


static func side_color(role_raw: String, actor_name: String, ally_color: String, enemy_color: String, side_map: Dictionary = {}) -> String:
	var role: = role_raw.strip_edges()
	if role == "ally":
		return ally_color
	if role == "enemy":
		return enemy_color
	var n: = actor_name.strip_edges()
	if not n.is_empty():
		if side_map.has(n):
			return ally_color if str(side_map.get(n, "")) == "ally" else enemy_color
		var key: = normalize_actor_name(n)
		if side_map.has(key):
			return ally_color if str(side_map.get(key, "")) == "ally" else enemy_color
	return neutral_default_color()


static func neutral_default_color() -> String:
	return "#E8E8E8"


static func normalize_actor_name(raw_name: String) -> String:
	var n: = raw_name.strip_edges()
	if n.begins_with("我方·"):
		n = n.substr(3).strip_edges()
	return n


static func _style_small_card_button(btn: Button) -> void :
	var n: = StyleBoxFlat.new()
	n.bg_color = Color(0.072, 0.080, 0.079, 0.92)
	n.border_width_left = 1
	n.border_width_right = 1
	n.border_width_top = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.677, 0.549, 0.254, 1)
	n.corner_radius_top_left = 8
	n.corner_radius_top_right = 8
	n.corner_radius_bottom_left = 8
	n.corner_radius_bottom_right = 8
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	var h: = n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.072, 0.080, 0.079, 1)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
