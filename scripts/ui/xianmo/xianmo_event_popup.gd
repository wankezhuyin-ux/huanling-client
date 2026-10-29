extends Control

signal closed

var event_data: Dictionary = {}
var result_data: Dictionary = {}
var game_manager = null

@onready var panel = $Panel
@onready var background = $Background
@onready var event_name_label = $Panel / VBoxContainer / Header / EventNameLabel
@onready var loading_indicator = $Panel / VBoxContainer / Content / VBoxContainer / LoadingIndicator
@onready var event_desc_label = $Panel / VBoxContainer / Content / VBoxContainer / EventDescLabel
@onready var result_label = $Panel / VBoxContainer / Content / VBoxContainer / ResultLabel
@onready var rewards_container = $Panel / VBoxContainer / Content / VBoxContainer / RewardsContainer
@onready var score_label = $Panel / VBoxContainer / Footer / ScoreLabel
@onready var confirm_btn = $Panel / VBoxContainer / Footer / ButtonContainer / ConfirmBtn

func _ready():
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_btn_pressed)
		_setup_button_style()
	if background:
		background.gui_input.connect(_on_background_input)
	_setup_style()

	if event_data.size() > 0:
		_update_ui()

func _setup_button_style():
	if not confirm_btn:
		return

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.6, 0.9)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.5, 0.75, 1.0)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10

	confirm_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.4, 0.7, 1.0)
	confirm_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.5, 0.8)
	confirm_btn.add_theme_stylebox_override("pressed", pressed_style)

	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	confirm_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _setup_style():
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.5, 0.4, 0.7)
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 15
		style.corner_radius_bottom_right = 15
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 5)
		panel.add_theme_stylebox_override("panel", style)

func setup(event: Dictionary, result: Dictionary, gm):
	event_data = event
	result_data = result
	game_manager = gm
	if is_inside_tree():
		_update_ui()

func _update_ui():
	if event_name_label:
		event_name_label.text = event_data.get("name", "未知事件")
		event_name_label.add_theme_font_size_override("font_size", 22)

	if loading_indicator:
		loading_indicator.visible = false

	if event_desc_label:
		event_desc_label.text = event_data.get("description", event_data.get("desc", "你遇到了一个事件..."))
		event_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		event_desc_label.add_theme_font_size_override("font_size", 18)

	if result_label:
		result_label.text = result_data.get("message", "事件处理完成")
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		result_label.add_theme_font_size_override("font_size", 18)

	if score_label:
		var score = result_data.get("score", 0)
		var faction_score_change = result_data.get("factionScoreChange", 0)
		var enemy_faction = result_data.get("enemyFaction", "")
		var faction_name = "仙道" if enemy_faction == "xian" else "魔道" if enemy_faction == "mo" else ""

		score_label.add_theme_font_size_override("font_size", 20)

		var score_text = ""
		if score > 0:
			score_text = "积分 +%d" % score
			score_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		elif score < 0:
			score_text = "积分 %d" % score
			score_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		else:
			score_text = "积分不变"
			score_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		if faction_score_change > 0 and faction_name != "":
			score_text += "  |  %s阵营 -%d" % [faction_name, faction_score_change]

		score_label.text = score_text

	_update_rewards()
	_check_battle_replay()

func _update_rewards():
	if not rewards_container:
		return

	for child in rewards_container.get_children():
		child.queue_free()

	var rewards = result_data.get("rewards", [])

	if rewards.is_empty():
		var no_reward = Label.new()
		no_reward.text = "本次没有获得奖励"
		no_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_reward.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		no_reward.add_theme_font_size_override("font_size", 18)
		rewards_container.add_child(no_reward)
		return

	for reward in rewards:
		if reward.type == "fortune" and reward.has("rewards"):
			for sub_reward in reward.rewards:
				var reward_label = _create_reward_label(sub_reward)
				rewards_container.add_child(reward_label)
		else:
			var reward_label = _create_reward_label(reward)
			rewards_container.add_child(reward_label)

func _create_reward_label(reward: Dictionary) -> Label:
	var label = Label.new()
	var text = ""
	var color = Color(1, 1, 1)

	match reward.type:
		"pet":
			if reward.has("captured") and reward.captured == false:
				text = "🐾 灵兽逃脱了..."
				color = Color(0.6, 0.6, 0.6)
			else:
				var growth = reward.get("growth", 5.0)
				text = "🐾 灵兽: 灵兽 (%.2f成长)" % growth
				color = Color(1, 0.8, 0.2)
		"chest":
			var chest_name = _get_chest_name(reward.get("chest_type", reward.get("chestType", "bronze")))
			text = "📦 宝箱: %s宝箱" % chest_name
			color = Color(0.9, 0.7, 0.3) if reward.get("chest_type", reward.get("chestType")) == "gold" else Color(0.7, 0.7, 0.8)
		"item":
			var item_key = str(reward.get("itemId", reward.get("item_id", reward.get("itemName", "unknown"))))
			text = "💊 物品: %s x%d" % [_get_item_name(item_key), reward.get("count", 1)]
			color = Color(0.6, 0.8, 1.0)
		"gold":
			text = "💰 金币: %d" % reward.get("amount", 0)
			color = Color(1, 0.85, 0.0)
		"exp":
			text = "✨ 经验: %d" % reward.get("amount", 0)
			color = Color(0.5, 1.0, 0.5)
		"cultivation":
			text = "🌟 修行值: %d" % reward.get("amount", 0)
			color = Color(0.8, 0.6, 1.0)
		"fragment":
			text = "🗺️ 藏宝图残片: %d" % reward.get("count", 1)
			color = Color(0.9, 0.7, 0.5)
		"score":
			text = "📊 积分: +%d" % reward.get("amount", 0)
			color = Color(0.4, 0.9, 0.4)
		"action_points":
			text = "⚡ 行动力: +%d" % reward.get("amount", 0)
			color = Color(0.3, 0.9, 0.9)
		"action_points_loss", "action_points_cost":
			text = "⚡ 行动力: -%d" % reward.get("amount", 0)
			color = Color(0.95, 0.55, 0.55)
		"buff":
			var buff_type = reward.get("buff_type", "")
			match buff_type:
				"next_event_score":
					text = "💪 增益: 下次探索积分+%d" % reward.get("value", 0)
				"attack":
					text = "💪 增益: 攻击力+%d%%" % reward.get("value", 0)
				_:
					text = "💪 增益效果"
			color = Color(1, 0.5, 0.5)
		"battle":
			var won = reward.get("won", false)
			var opponent = reward.get("opponent", "未知")
			if won:
				text = "⚔️ 战斗: 击败【%s】" % opponent
				color = Color(0.4, 0.9, 0.4)
			else:
				text = "⚔️ 战斗: 败于【%s】" % opponent
				color = Color(0.9, 0.4, 0.4)
		"fortune":
			text = "🍀 机缘: 获得了好运"
			color = Color(0.9, 0.8, 0.3)
		"training":
			text = "🧘 修炼: 修为有所提升"
			color = Color(0.6, 0.8, 0.9)
		"trap":
			if reward.get("action_points_cost", 0) > 0:
				text = "⚠️ 陷阱: 消耗%d行动力脱困" % reward.get("action_points_cost", 0)
			elif reward.get("action_points_loss", 0) > 0:
				text = "⚠️ 陷阱: 损失%d行动力" % reward.get("action_points_loss", 0)
			elif reward.get("rewards", []).size() > 0:
				var trap_reward = reward.get("rewards", [])[0]
				var trap_type = str(trap_reward.get("type", ""))
				if trap_type == "action_points_loss" or trap_type == "action_points_cost":
					text = "⚠️ 陷阱: 损失%d行动力" % int(trap_reward.get("amount", 0))
				else:
					text = "⚠️ 陷阱: 遭遇危机"
			elif reward.get("score_loss", false):
				text = "⚠️ 陷阱: 积分减少"
			elif reward.get("no_reward", false):
				text = "🌫️ 迷雾: 一无所获"
			elif reward.get("requires_battle", false):
				text = "⚔️ 遭遇: 灵兽袭击"
			else:
				text = "⚠️ 陷阱: 遭遇危机"
			color = Color(0.9, 0.5, 0.5)
		"empty":
			text = "💨 空手而归"
			color = Color(0.6, 0.6, 0.6)
		_:
			text = "奖励"

	if reward.get("sent_via_mail", false):
		text += " [已发送到邮件]"

	label.text = text
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	return label

func _get_chest_name(chest_type: String) -> String:
	match chest_type:
		"bronze": return "青铜"
		"silver": return "白银"
		"gold": return "黄金"
		_: return "未知"

func _get_item_name(item_id: String) -> String:
	match item_id:
		"cultivation_pill": return "悟道仙丹"
		_: return item_id

func _on_confirm_btn_pressed():
	closed.emit()
	queue_free()

func _on_background_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_confirm_btn_pressed()

func _check_battle_replay():
	var battle_log = result_data.get("battleLog", [])
	if battle_log.is_empty():
		return

	if not confirm_btn:
		return

	var parent_container = confirm_btn.get_parent()
	if not parent_container:
		return

	var replay_btn = Button.new()
	replay_btn.text = "战斗回放"
	replay_btn.custom_minimum_size = Vector2(120, 40)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.6, 0.4, 0.2)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.8, 0.6, 0.3)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10

	replay_btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.7, 0.5, 0.3)
	replay_btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = Color(0.5, 0.3, 0.1)
	replay_btn.add_theme_stylebox_override("pressed", pressed_style)

	replay_btn.add_theme_font_size_override("font_size", 16)
	replay_btn.add_theme_color_override("font_color", Color(1, 1, 1))

	replay_btn.pressed.connect(_show_battle_replay)

	parent_container.add_child(replay_btn)
	if parent_container is HBoxContainer:
		parent_container.move_child(replay_btn, 0)

func _show_battle_replay():
	var battle_log = result_data.get("battleLog", [])
	if battle_log.is_empty():
		return

	var replay_popup = _create_battle_replay_popup()
	add_child(replay_popup)

func _create_battle_replay_popup() -> Control:
	var popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(bg)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 500)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -250
	panel.offset_right = 300
	panel.offset_bottom = 250
	popup.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
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

	var main_margin = MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 20)
	main_margin.add_theme_constant_override("margin_right", 20)
	main_margin.add_theme_constant_override("margin_top", 15)
	main_margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(main_margin)

	var vbox = VBoxContainer.new()
	main_margin.add_child(vbox)

	var title = Label.new()
	title.text = "⚔️ 战斗回放"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var log_margin = MarginContainer.new()
	log_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_margin.add_theme_constant_override("margin_left", 10)
	log_margin.add_theme_constant_override("margin_right", 10)
	log_margin.add_theme_constant_override("margin_top", 5)
	log_margin.add_theme_constant_override("margin_bottom", 5)
	scroll.add_child(log_margin)

	var log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 3)
	log_margin.add_child(log_container)

	var battle_log = result_data.get("battleLog", [])
	for entry in battle_log:
		var entry_label = Label.new()
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_label.add_theme_font_size_override("font_size", 16)

		match entry.get("type", ""):
			"start":
				entry_label.text = entry.get("message", "战斗开始")
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				entry_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
			"player_info":
				var name = entry.get("name", "你")
				var hp = entry.get("hp", 0)
				var attack = entry.get("attack", 0)
				var defense = entry.get("defense", 0)
				var agility = entry.get("agility", 0)
				var element = entry.get("element", "金")
				entry_label.text = "👤 【%s】 HP:%d 攻击:%d 防御:%d 敏捷:%d 五行:%s" % [name, hp, attack, defense, agility, element]
				entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			"pet_info":
				var name = entry.get("name", "灵兽")
				var hp = entry.get("hp", 0)
				var attack = entry.get("attack", 0)
				var defense = entry.get("defense", 0)
				var agility = entry.get("agility", 0)
				var element = entry.get("element", "金")
				entry_label.text = "🐾 【%s】 HP:%d 攻击:%d 防御:%d 敏捷:%d 五行:%s" % [name, hp, attack, defense, agility, element]
				entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			"enemy_info":
				var name = entry.get("name", "敌人")
				var hp = entry.get("hp", 0)
				var attack = entry.get("attack", 0)
				var defense = entry.get("defense", 0)
				var agility = entry.get("agility", 0)
				var element = entry.get("element", "金")
				entry_label.text = "👤 【%s】 HP:%d 攻击:%d 防御:%d 敏捷:%d 五行:%s" % [name, hp, attack, defense, agility, element]
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			"enemy_pet_info":
				var name = entry.get("name", "敌方灵兽")
				var hp = entry.get("hp", 0)
				var attack = entry.get("attack", 0)
				var defense = entry.get("defense", 0)
				var agility = entry.get("agility", 0)
				var element = entry.get("element", "金")
				entry_label.text = "🐾 【%s】 HP:%d 攻击:%d 防御:%d 敏捷:%d 五行:%s" % [name, hp, attack, defense, agility, element]
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			"info":
				entry_label.text = entry.get("message", "")
				entry_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
			"round":
				entry_label.text = "━━━ 第 %d 回合 ━━━" % entry.get("round", 1)
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				entry_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
			"combo_trigger":
				entry_label.text = "★ " + entry.get("message", "连击触发！")
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				entry_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
			"combo_attack":
				entry_label.text = "  ⚡ 【%s】连击！" % entry.get("attacker", "")
				entry_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
			"kuihua_point_success":
				var attacker = entry.get("attacker", "我方")
				var target = entry.get("target", "敌人")
				var message = entry.get("message", "")
				if message == "":
					var base_chance = float(entry.get("baseChance", 0.0)) * 100.0
					var bonus_pct = float(entry.get("bonusPct", 0.0))
					var final_chance = float(entry.get("finalChance", 0.0)) * 100.0
					message = "葵花点穴得手！%s 接下来两回合无法行动（基础%.1f%% + 加成%.1f%% = %.1f%%）" % [target, base_chance, bonus_pct, final_chance]
				entry_label.text = "  ✨ 【%s】对【%s】施展点穴成功！%s" % [attacker, target, message]
				entry_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.35))
			"kuihua_point_fail":
				var attacker = entry.get("attacker", "我方")
				var target = entry.get("target", "敌人")
				var message = entry.get("message", "")
				if message == "":
					var base_chance = float(entry.get("baseChance", 0.0)) * 100.0
					var bonus_pct = float(entry.get("bonusPct", 0.0))
					var final_chance = float(entry.get("finalChance", 0.0)) * 100.0
					message = "葵花点穴未生效（基础%.1f%% + 加成%.1f%% = %.1f%%）" % [base_chance, bonus_pct, final_chance]
				entry_label.text = "  ⚪ 【%s】对【%s】施展点穴失败。%s" % [attacker, target, message]
				entry_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
			"acupoint_skip":
				var target = entry.get("target", "目标")
				var remain = int(entry.get("remain", 0))
				entry_label.text = "  ⛔ 【%s】被点穴封脉，本回合无法行动（剩余%d回合）" % [target, remain]
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
			"joint_attack":
				var player = entry.get("player", "你")
				var pet = entry.get("pet", "灵兽")
				var target = entry.get("target", "敌人")
				entry_label.text = "  🔗 ★ 合击触发！【%s】和【%s】联手攻击【%s】！" % [player, pet, target]
				entry_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
			"miss":
				var attacker = entry.get("attacker", "未知")
				var target = entry.get("target", "未知")
				if entry.get("isEnemyAttack", false):
					entry_label.text = "  💨 【%s】攻击【%s】，未命中！" % [attacker, target]
					entry_label.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
				else:
					entry_label.text = "  💨 【%s】攻击【%s】，未命中！" % [attacker, target]
					entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			"dodge":
				var attacker = entry.get("attacker", "未知")
				var target = entry.get("target", "未知")
				if entry.get("isEnemyAttack", false):
					entry_label.text = "  🏃 【%s】攻击【%s】，被闪避！" % [attacker, target]
					entry_label.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
				else:
					entry_label.text = "  🏃 【%s】攻击【%s】，被闪避！" % [attacker, target]
					entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			"attack", "triple_shot_hit", "kuihua_hit":
				var attacker = entry.get("attacker", "未知")
				var target = entry.get("target", "未知")
				var damage = entry.get("damage", 0)
				var target_hp = entry.get("targetHp", 0)
				var target_max_hp = entry.get("targetMaxHp", 100)
				var hp_percent = float(target_hp) / float(target_max_hp) * 100.0
				var element_msg = entry.get("elementMsg", "")
				var soul_bonus_percent = int(entry.get("petSoulBonusPercent", 0))
				if soul_bonus_percent > 0 and element_msg.find("魂魄+") == -1:
					element_msg = ("%s （魂魄+%d%%）" % [element_msg, soul_bonus_percent]).strip_edges()
				var noble_bonus_pct: = int(entry.get("noblePetBonusPercent", 0))
				if noble_bonus_pct > 0 and bool(entry.get("isPetAttack", false)) and str(element_msg).find("贵族+") < 0:
					element_msg = ("%s （贵族+%d%%）" % [str(element_msg), noble_bonus_pct]).strip_edges()
				var combo_text = " 连击！" if entry.get("isCombo", false) else ""
				var joint_text = " 合击！" if entry.get("isJointAttack", false) else ""
				var skill_name: = str(entry.get("skillName", entry.get("skill_name", ""))).strip_edges()
				if skill_name.is_empty() and str(entry.get("type", "")) == "triple_shot_hit":
					skill_name = "一箭三雕"
				elif skill_name.is_empty() and str(entry.get("type", "")) == "kuihua_hit":
					skill_name = "葵花点穴"
				var skill_text: = ("【%s】" % skill_name) if not skill_name.is_empty() else ""

				var base_text = ""
				if entry.get("isEnemyAttack", false):
					base_text = "  🔴 %s【%s】攻击【%s】，造成 %d 伤害！%s%s(HP: %d/%d %.1f%%)" % [skill_text, attacker, target, damage, combo_text, joint_text, target_hp, target_max_hp, hp_percent]
					entry_label.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
				elif entry.get("isPetAttack", false):
					base_text = "  🟢 %s【%s】攻击【%s】，造成 %d 伤害！%s%s(HP: %d/%d %.1f%%)" % [skill_text, attacker, target, damage, combo_text, joint_text, target_hp, target_max_hp, hp_percent]
					entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
				else:
					base_text = "  🟢 %s【%s】攻击【%s】，造成 %d 伤害！%s%s(HP: %d/%d %.1f%%)" % [skill_text, attacker, target, damage, combo_text, joint_text, target_hp, target_max_hp, hp_percent]
					entry_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))

				if element_msg != "":
					base_text += " 【%s】" % element_msg

				entry_label.text = base_text
			"enemy_dead":
				entry_label.text = "  💀 【%s】被击败！" % entry.get("name", "敌人")
				entry_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			"pet_dead":
				entry_label.text = "  💀 【%s】被击败！" % entry.get("name", "灵兽")
				entry_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			"player_dead":
				entry_label.text = "  💀 【%s】被击败！" % entry.get("name", "你")
				entry_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			"victory":
				entry_label.text = entry.get("message", "战斗胜利！")
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				entry_label.add_theme_font_size_override("font_size", 20)
				entry_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			"defeat":
				entry_label.text = entry.get("message", "战斗失败...")
				entry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				entry_label.add_theme_font_size_override("font_size", 20)
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			"skill_splash":
				var m_splash: = str(entry.get("message", "")).strip_edges()
				if m_splash != "":
					entry_label.text = "  💧 " + m_splash
				else:
					var sa: = str(entry.get("attacker", "?"))
					var st: = str(entry.get("target", "?"))
					var sd: = int(entry.get("damage", 0))
					var sthp: = int(entry.get("targetHp", 0))
					var stmh: = int(entry.get("targetMaxHp", 1))
					var spct: = float(sthp) / float(max(stmh, 1)) * 100.0
					entry_label.text = "  💧 【溅射】【%s】波及【%s】，造成 %d 伤害（目标剩余 HP %d/%d，约 %.0f%%）" % [sa, st, sd, sthp, stmh, spct]
				entry_label.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
			"skill_double_shot":
				var m_ds: = str(entry.get("message", "")).strip_edges()
				if m_ds != "":
					entry_label.text = "  🎯 " + m_ds
				else:
					var da: = str(entry.get("attacker", "?"))
					var dt: = str(entry.get("target", "?"))
					var dd: = int(entry.get("damage", 0))
					var di: = int(entry.get("hitIndex", 0))
					entry_label.text = "  🎯 【连射】第 %d 段：【%s】命中【%s】，%d 伤害" % [di, da, dt, dd]
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.45))
			"skill_divine_protect":
				var m_div: = str(entry.get("message", "")).strip_edges()
				if m_div != "":
					entry_label.text = "  ✨ " + m_div
				else:
					var dname: = str(entry.get("target", "灵兽"))
					var dh: = int(entry.get("hpRestored", 0))
					entry_label.text = "  ✨ 【神佑】【%s】触发，恢复生命约 %d" % [dname, dh]
				entry_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.55))
			"skill_counter_attack":
				var m_ct: = str(entry.get("message", "")).strip_edges()
				if m_ct != "":
					entry_label.text = "  ⚡ " + m_ct
				else:
					var ca: = str(entry.get("attacker", "?"))
					var ct: = str(entry.get("target", "?"))
					var cd: = int(entry.get("damage", 0))
					entry_label.text = "  ⚡ 【反击】【%s】反击【%s】，%d 伤害" % [ca, ct, cd]
				entry_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.45))
			_:
				var fallback_msg = str(entry.get("message", "")).strip_edges()
				if fallback_msg != "":
					entry_label.text = "  ℹ " + fallback_msg
				else:
					var t = str(entry.get("type", "未知事件"))
					entry_label.text = "  ℹ 未识别事件（%s），请联系客服反馈" % t
				entry_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		log_container.add_child(entry_label)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(150, 45)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.4, 0.4, 0.5)
	close_style.border_width_left = 2
	close_style.border_width_right = 2
	close_style.border_width_top = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(0.6, 0.6, 0.7)
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_left = 10
	close_style.corner_radius_bottom_right = 10
	close_btn.add_theme_stylebox_override("normal", close_style)

	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.5, 0.5, 0.6)
	close_btn.add_theme_stylebox_override("hover", close_hover)

	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	close_btn.pressed.connect( func(): popup.queue_free())

	vbox.add_child(close_btn)

	bg.gui_input.connect( func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			popup.queue_free()
	)

	return popup

static func create_popup(event: Dictionary, result: Dictionary, gm) -> Control:
	var popup = preload("res://ui/xianmo/xianmo_event_popup.tscn").instantiate()
	popup.setup(event, result, gm)
	return popup
