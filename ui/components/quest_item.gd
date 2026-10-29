extends PanelContainer

class_name QuestItem

const QuestDatabase = preload("res://scripts/data/quest_database.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

var quest_data: Dictionary = {}
var quest_status: int = 0
var quest_progress: Dictionary = {}
var quest_ui = null

var name_label: Label
var status_label: Label
var desc_label: Label
var rewards_label: Label
var btn_container: HBoxContainer
var teleport_btn: Button
var reward_btn: Button

func _ready():
	custom_minimum_size = Vector2(0, 90)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 15
	style.content_margin_top = 10
	style.content_margin_right = 15
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 15)
	add_child(main_hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	main_hbox.add_child(info_vbox)

	var name_row = HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(name_row)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 20)
	name_row.add_child(name_label)

	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 16)
	name_row.add_child(status_label)

	desc_label = Label.new()
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	info_vbox.add_child(desc_label)

	rewards_label = Label.new()
	rewards_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_label.add_theme_font_size_override("font_size", 14)
	rewards_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	info_vbox.add_child(rewards_label)

	btn_container = HBoxContainer.new()
	btn_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 8)
	main_hbox.add_child(btn_container)

	teleport_btn = Button.new()
	teleport_btn.text = "前往"
	teleport_btn.custom_minimum_size = Vector2(80, 40)
	teleport_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_button_style(teleport_btn)
	UIStyle.setup_button_animation(teleport_btn)
	btn_container.add_child(teleport_btn)

	reward_btn = Button.new()
	reward_btn.text = "领取"
	reward_btn.custom_minimum_size = Vector2(80, 40)
	reward_btn.add_theme_font_size_override("font_size", 18)
	UIStyle.apply_golden_button_style(reward_btn)
	UIStyle.setup_button_animation(reward_btn)
	btn_container.add_child(reward_btn)



	teleport_btn.pressed.connect(_on_teleport_pressed)
	reward_btn.pressed.connect(_on_reward_pressed)

func setup(quest_info: Dictionary, ui):
	quest_data = quest_info.data
	quest_status = quest_info.status
	quest_progress = quest_info.progress
	quest_ui = ui

	_update_ui()

func _update_ui():
	name_label.text = quest_data.get("name", "未知任务")

	var style = get_theme_stylebox("panel") as StyleBoxFlat
	if not style:
		return

	match quest_status:
		QuestDatabase.QuestStatus.LOCKED:
			status_label.text = "🔒 未解锁"
			status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			style.bg_color = Color(0.1, 0.1, 0.12, 0.7)
			style.border_color = Color(0.3, 0.3, 0.35, 0.6)
		QuestDatabase.QuestStatus.ACTIVE, QuestDatabase.QuestStatus.IN_PROGRESS:
			status_label.text = "⚔️ 进行中"
			status_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			name_label.text = "⚔ " + name_label.text
			name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
			desc_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
			rewards_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
			style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
			style.border_color = Color(0.8, 0.6, 0.2, 1)
		QuestDatabase.QuestStatus.COMPLETED:
			status_label.text = "✨ 可领取"
			status_label.add_theme_color_override("font_color", Color(0.3, 1, 0.4))
			name_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
			style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
			style.border_color = Color(0.3, 0.8, 0.4, 1)
		QuestDatabase.QuestStatus.FINISHED:
			status_label.text = "✓ 已完成"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
			name_label.text = "✓ " + name_label.text
			name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
			desc_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.45))
			rewards_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.45))
			style.bg_color = Color(0.1, 0.2, 0.15, 0.8)
			style.border_color = Color(0.3, 0.6, 0.4, 1)

	if quest_status == QuestDatabase.QuestStatus.LOCKED:
		desc_label.text = _get_unlock_condition_text()
	else:
		desc_label.text = quest_data.get("description", "")

	rewards_label.text = _get_rewards_text()

	btn_container.visible = (quest_status == QuestDatabase.QuestStatus.ACTIVE or 
		quest_status == QuestDatabase.QuestStatus.COMPLETED)

	var objectives = quest_data.get("objectives", [])
	if quest_status == QuestDatabase.QuestStatus.ACTIVE:
		var can_teleport = false
		if quest_data.has("teleport_map"):
			can_teleport = true
		else:
			for objective in objectives:
				var obj_type = objective.get("type", -1)
				if obj_type == QuestDatabase.QuestConditionType.KILL_MONSTER or obj_type == QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE:
					if objective.has("map"):
						can_teleport = true
						break
		teleport_btn.visible = can_teleport
		reward_btn.visible = false
	elif quest_status == QuestDatabase.QuestStatus.COMPLETED:
		teleport_btn.visible = false
		reward_btn.visible = true
	else:
		teleport_btn.visible = false
		reward_btn.visible = false

func _get_rewards_text() -> String:
	var parts = []
	var rewards = quest_data.get("rewards", {})

	if rewards.has("exp") and rewards.get("exp") > 0:
		parts.append("✨经验%d" % rewards.get("exp"))

	if rewards.has("gold") and rewards.get("gold") > 0:
		parts.append("💰金币%d" % rewards.get("gold"))

	if rewards.has("items") and rewards.get("items").size() > 0:
		for item_entry in rewards.get("items"):
			var item_name = item_entry
			var count = 1
			var x_pos = item_entry.find(" x")
			if x_pos > 0:
				item_name = item_entry.substr(0, x_pos)
				var count_str = item_entry.substr(x_pos + 2)
				count = int(count_str)
			if count > 1:
				parts.append("🎁%sx%d" % [item_name, count])
			else:
				parts.append("🎁%s" % item_name)

	return "奖励: " + "  ".join(parts) if parts.size() > 0 else ""

func _get_unlock_condition_text() -> String:
	var conditions = []

	if quest_data.has("unlock_level"):
		conditions.append("等级%d级" % quest_data.get("unlock_level"))

	if quest_data.has("unlock_realm"):
		conditions.append("境界%s" % quest_data.get("unlock_realm"))

	if quest_data.has("unlock_tower"):
		conditions.append("天关%d层" % quest_data.get("unlock_tower"))

	if quest_data.has("unlock_suit_dungeon"):
		conditions.append("套装副本%d层" % quest_data.get("unlock_suit_dungeon"))

	var all_quest_ids = QuestDatabase.get_all_quest_ids()
	for check_quest_id in all_quest_ids:
		var check_quest = QuestDatabase.get_quest(check_quest_id)
		if check_quest.has("next_quest") and check_quest.get("next_quest") == quest_data.get("id"):
			conditions.append("完成「%s」" % check_quest.get("name"))
			break

	if conditions.size() > 0:
		return "解锁条件: " + "、".join(conditions)
	else:
		return "解锁条件: 无"

func _get_objective_key(objective: Dictionary) -> String:
	var objective_type = objective.type
	if objective_type == QuestDatabase.QuestConditionType.CLEAR_TOWER:
		objective_type = QuestDatabase.QuestConditionType.COMPLETE_TOWER
	elif objective_type == QuestDatabase.QuestConditionType.CLEAR_SUIT_DUNGEON:
		objective_type = QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON

	match objective_type:
		QuestDatabase.QuestConditionType.KILL_MONSTER:
			if objective.has("monster_id"):
				return "kill_" + str(objective.monster_id)
			elif objective.has("map"):
				return "kill_map_" + str(objective.map)
			else:
				return "kill_any"
		QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE:
			return "kill_type_" + objective.get("element", "any")
		QuestDatabase.QuestConditionType.COMPLETE_MAP:
			return "complete_map_" + str(objective.target)
		QuestDatabase.QuestConditionType.CAPTURE_PET:
			if objective.get("require_owned_pet", false):
				return "has_pet_" + objective.get("pet_element", "any")
			return "capture_pet"
		QuestDatabase.QuestConditionType.REACH_LEVEL:
			return "reach_level"
		QuestDatabase.QuestConditionType.REACH_REALM:
			return "reach_realm"
		QuestDatabase.QuestConditionType.COMPLETE_TOWER:
			return "complete_tower"
		QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			return "complete_suit_dungeon"
		QuestDatabase.QuestConditionType.BATTLE_COUNT:
			return "battle_count"
		QuestDatabase.QuestConditionType.USE_ITEM:
			return "use_item_" + objective.get("item_type", "any")
		QuestDatabase.QuestConditionType.EQUIP_ITEM:
			return "equip_" + objective.get("rarity", "any")
		QuestDatabase.QuestConditionType.REACH_PET_LEVEL:
			return "reach_pet_level_" + objective.get("pet_element", "any")
		QuestDatabase.QuestConditionType.EVOLVE_PET:
			return "evolve_pet"
		QuestDatabase.QuestConditionType.FUSE_PET:
			return "fuse_pet"
		QuestDatabase.QuestConditionType.COLLECT_ITEM:
			return "collect_" + objective.get("item", "any")
		QuestDatabase.QuestConditionType.COMPLETE_QUEST:
			return "complete_quest_" + objective.get("quest_id", "any")
		_:
			return str(objective.get("type", -1))

func _on_teleport_pressed():
	if quest_ui:
		quest_ui.teleport_to_map(quest_data.get("id"))

func _on_reward_pressed():
	if not quest_ui:
		return
	reward_btn.disabled = true
	var prev_text: = reward_btn.text
	reward_btn.text = "领取中..."
	await quest_ui.claim_reward(quest_data.get("id"))
	if is_instance_valid(reward_btn):
		reward_btn.disabled = false
		reward_btn.text = prev_text
