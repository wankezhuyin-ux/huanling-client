extends Control

class_name QuestUI

signal teleport_to_battle_requested

const QuestDatabase = preload("res://scripts/data/quest_database.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

@onready var btn_main = $Panel / TopContainer / TabsRow1 / BtnMain
@onready var btn_element = $Panel / TopContainer / TabsRow1 / BtnElement
@onready var btn_realm = $Panel / TopContainer / TabsRow1 / BtnRealm
@onready var btn_daily = $Panel / TopContainer / TabsRow1 / BtnDaily
@onready var btn_achievement = $Panel / TopContainer / TabsRow2 / BtnAchievement
@onready var btn_tower = $Panel / TopContainer / TabsRow2 / BtnTower
@onready var btn_pet = $Panel / TopContainer / TabsRow2 / BtnPet
@onready var btn_suit = $Panel / TopContainer / TabsRow2 / BtnSuit

@onready var content_main = $Panel / TopContainer / ContentContainer / MainContent
@onready var content_element = $Panel / TopContainer / ContentContainer / ElementContent
@onready var content_realm = $Panel / TopContainer / ContentContainer / RealmContent
@onready var content_daily = $Panel / TopContainer / ContentContainer / DailyContent
@onready var content_achievement = $Panel / TopContainer / ContentContainer / AchievementContent
@onready var content_tower = $Panel / TopContainer / ContentContainer / TowerContent
@onready var content_pet = $Panel / TopContainer / ContentContainer / PetContent
@onready var content_suit = $Panel / TopContainer / ContentContainer / SuitContent

@onready var main_quest_list = $Panel / TopContainer / ContentContainer / MainContent / ScrollContainer / VBoxContainer
@onready var element_quest_list = $Panel / TopContainer / ContentContainer / ElementContent / ScrollContainer / VBoxContainer
@onready var realm_quest_list = $Panel / TopContainer / ContentContainer / RealmContent / ScrollContainer / VBoxContainer
@onready var daily_quest_list = $Panel / TopContainer / ContentContainer / DailyContent / ScrollContainer / VBoxContainer
@onready var achievement_quest_list = $Panel / TopContainer / ContentContainer / AchievementContent / ScrollContainer / VBoxContainer
@onready var tower_quest_list = $Panel / TopContainer / ContentContainer / TowerContent / ScrollContainer / VBoxContainer
@onready var pet_quest_list = $Panel / TopContainer / ContentContainer / PetContent / ScrollContainer / VBoxContainer
@onready var suit_quest_list = $Panel / TopContainer / ContentContainer / SuitContent / ScrollContainer / VBoxContainer

var quest_manager: QuestManager = null
var quest_item_scene = preload("res://ui/components/quest_item.tscn")

var current_tab: int = 0
var all_buttons: Array = []
var all_contents: Array = []
var tab_normal_style = null
var tab_active_style = null

func _ready():
	if GameManager.instance:
		quest_manager = GameManager.instance.quest_manager
	if quest_manager:
		quest_manager.quest_updated.connect(_on_quest_updated)
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.daily_quests_reset.connect(_on_daily_reset)

	all_buttons = [btn_main, btn_element, btn_realm, btn_daily, btn_achievement, btn_tower, btn_pet, btn_suit]
	all_contents = [content_main, content_element, content_realm, content_daily, content_achievement, content_tower, content_pet, content_suit]

	tab_normal_style = btn_main.get_theme_stylebox("normal")
	tab_active_style = btn_main.get_theme_stylebox("hover")

	btn_main.pressed.connect( func(): _switch_tab(0))
	btn_element.pressed.connect( func(): _switch_tab(1))
	btn_realm.pressed.connect( func(): _switch_tab(2))
	btn_daily.pressed.connect( func(): _switch_tab(3))
	btn_achievement.pressed.connect( func(): _switch_tab(4))
	btn_tower.pressed.connect( func(): _switch_tab(5))
	btn_pet.pressed.connect( func(): _switch_tab(6))
	btn_suit.pressed.connect( func(): _switch_tab(7))

	refresh_all_quests()
	_switch_tab(0)

func _switch_tab(tab_index: int):
	current_tab = tab_index

	for i in range(all_buttons.size()):
		var btn = all_buttons[i]
		if i == tab_index:
			btn.add_theme_stylebox_override("normal", tab_active_style)
		else:
			btn.add_theme_stylebox_override("normal", tab_normal_style)

	for i in range(all_contents.size()):
		all_contents[i].visible = (i == tab_index)

func refresh_all_quests():
	refresh_main_quests()
	refresh_element_quests()
	refresh_realm_quests()
	refresh_daily_quests()
	refresh_achievement_quests()
	refresh_tower_quests()
	refresh_pet_quests()
	refresh_suit_quests()

func refresh_main_quests():
	_clear_quest_list(main_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.MAIN)
	_add_quests_to_list(quests, main_quest_list)

func refresh_element_quests():
	_clear_quest_list(element_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.ELEMENT)
	_add_quests_to_list(quests, element_quest_list)

func refresh_realm_quests():
	_clear_quest_list(realm_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.REALM)
	_add_quests_to_list(quests, realm_quest_list)

func refresh_daily_quests():
	_clear_quest_list(daily_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.DAILY)
	_add_quests_to_list(quests, daily_quest_list)

func refresh_achievement_quests():
	_clear_quest_list(achievement_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.ACHIEVEMENT)
	_add_quests_to_list(quests, achievement_quest_list)

func refresh_tower_quests():
	_clear_quest_list(tower_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.TOWER)
	_add_quests_to_list(quests, tower_quest_list)

func refresh_pet_quests():
	_clear_quest_list(pet_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.PET)
	_add_quests_to_list(quests, pet_quest_list)

func refresh_suit_quests():
	_clear_quest_list(suit_quest_list)
	var quests = quest_manager.get_quests_by_type(QuestDatabase.QuestType.SUIT)
	_add_quests_to_list(quests, suit_quest_list)

func _clear_quest_list(container: VBoxContainer):

	var kids: = container.get_children()
	for child in kids:
		child.queue_free()

func _get_sort_weight(status) -> int:
	match status:
		QuestDatabase.QuestStatus.ACTIVE, QuestDatabase.QuestStatus.IN_PROGRESS:
			return 0
		QuestDatabase.QuestStatus.COMPLETED:
			return 1
		QuestDatabase.QuestStatus.FINISHED:
			return 2
		QuestDatabase.QuestStatus.AVAILABLE:
			return 3
		QuestDatabase.QuestStatus.LOCKED:
			return 4
		_:
			return 5

func _get_progress_percent(quest_info) -> float:
	var quest_data = quest_info.data
	var quest_progress = quest_info.progress
	if not quest_data.has("objectives") or quest_data.objectives.size() == 0:
		return 0.0

	var first_objective = quest_data.objectives[0]
	var target = first_objective.get("target", first_objective.get("count", 1))
	if target <= 0:
		return 0.0

	var objective_type = first_objective.get("type", -1)
	if objective_type == QuestDatabase.QuestConditionType.CLEAR_TOWER:
		objective_type = QuestDatabase.QuestConditionType.COMPLETE_TOWER
	elif objective_type == QuestDatabase.QuestConditionType.CLEAR_SUIT_DUNGEON:
		objective_type = QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON

	var objective_key = ""
	match objective_type:
		QuestDatabase.QuestConditionType.KILL_MONSTER:
			if first_objective.has("monster_id"):
				objective_key = "kill_" + str(first_objective.monster_id)
			elif first_objective.has("map"):
				objective_key = "kill_map_" + str(first_objective.map)
			else:
				objective_key = "kill_any"
		QuestDatabase.QuestConditionType.KILL_MONSTER_TYPE:
			objective_key = "kill_type_" + first_objective.get("element", "any")
		QuestDatabase.QuestConditionType.COMPLETE_MAP:
			objective_key = "complete_map_" + str(first_objective.target)
		QuestDatabase.QuestConditionType.CAPTURE_PET:
			if first_objective.get("require_owned_pet", false):
				objective_key = "has_pet_" + first_objective.get("pet_element", "any")
			else:
				objective_key = "capture_pet"
		QuestDatabase.QuestConditionType.REACH_LEVEL:
			objective_key = "reach_level"
		QuestDatabase.QuestConditionType.REACH_REALM:
			objective_key = "reach_realm"
		QuestDatabase.QuestConditionType.COMPLETE_TOWER:
			objective_key = "complete_tower"
		QuestDatabase.QuestConditionType.COMPLETE_SUIT_DUNGEON:
			objective_key = "complete_suit_dungeon"
		QuestDatabase.QuestConditionType.BATTLE_COUNT:
			objective_key = "battle_count"
		QuestDatabase.QuestConditionType.USE_ITEM:
			objective_key = "use_item_" + first_objective.get("item_type", "any")
		QuestDatabase.QuestConditionType.EQUIP_ITEM:
			objective_key = "equip_" + first_objective.get("rarity", "any")
		QuestDatabase.QuestConditionType.REACH_PET_LEVEL:
			objective_key = "reach_pet_level_" + first_objective.get("pet_element", "any")
		QuestDatabase.QuestConditionType.EVOLVE_PET:
			objective_key = "evolve_pet"
		QuestDatabase.QuestConditionType.FUSE_PET:
			objective_key = "fuse_pet"
		QuestDatabase.QuestConditionType.COLLECT_ITEM:
			objective_key = "collect_" + first_objective.get("item", "any")
		QuestDatabase.QuestConditionType.COMPLETE_QUEST:
			objective_key = "complete_quest_" + first_objective.get("quest_id", "any")
		_:
			objective_key = str(objective_type)

	var current = quest_progress.get(objective_key, 0)
	return float(current) / float(target)

func _add_quests_to_list(quests: Array, container: VBoxContainer):
	quests.sort_custom( func(a, b):
		var weight_a = _get_sort_weight(a.status)
		var weight_b = _get_sort_weight(b.status)
		if weight_a != weight_b:
			return weight_a < weight_b

		if a.status == QuestDatabase.QuestStatus.ACTIVE or a.status == QuestDatabase.QuestStatus.IN_PROGRESS:
			var progress_a = _get_progress_percent(a)
			var progress_b = _get_progress_percent(b)
			if progress_a != progress_b:
				return progress_a > progress_b

		return a.data.id < b.data.id
	)

	for quest_info in quests:
		var quest_item = quest_item_scene.instantiate()
		container.add_child(quest_item)
		quest_item.setup(quest_info, self)

func _on_quest_updated(quest_id: String, progress: Dictionary):
	refresh_all_quests()

func _on_quest_completed(quest_id: String):
	refresh_all_quests()
	var quest_data = QuestDatabase.get_quest(quest_id)
	if GameManager.instance and GameManager.instance.has_method("show_message"):
		GameManager.instance.show_message("任务完成：" + quest_data.name)

func _on_daily_reset():
	refresh_daily_quests()
	if GameManager.instance and GameManager.instance.has_method("show_message"):
		GameManager.instance.show_message("日常任务已重置")

func show_ui():
	refresh_all_quests()
	show()

func _present_quest_dialog(title: String, message: String) -> void :
	var dlg: = AcceptDialog.new()
	dlg.title = title
	dlg.borderless = true
	dlg.transparent = true
	dlg.unresizable = true
	dlg.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	dlg.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
	dlg.dialog_text = message
	dlg.ok_button_text = "确定"
	add_child(dlg)
	var close: = func():
		if is_instance_valid(dlg):
			dlg.queue_free()
	dlg.confirmed.connect(close)
	dlg.canceled.connect(close)
	dlg.close_requested.connect(close)
	dlg.popup_centered()

func claim_reward(quest_id: String) -> void :
	var result = await quest_manager.claim_quest_reward(quest_id)
	if result.get("ok", false):
		refresh_all_quests()
		var rewards: Dictionary = {}
		var raw_rewards: Variant = result.get("rewards", {})
		if raw_rewards is Dictionary:
			rewards = raw_rewards
		_show_reward_dialog(quest_id, rewards)
	else:
		refresh_all_quests()
		var err_msg: = str(result.get("err", "领取失败，请稍后重试或同步存档"))
		push_warning("[QuestUI] 领取失败: %s" % err_msg)
		if GameManager.instance and GameManager.instance.has_method("show_message"):
			GameManager.instance.show_message(err_msg)
		_present_quest_dialog("领取失败", err_msg)

func teleport_to_map(quest_id: String):
	var success = quest_manager.teleport_to_quest_map(quest_id)
	if success:
		hide()
		teleport_to_battle_requested.emit()

func _show_reward_dialog(quest_id: String, rewards: Dictionary):
	var quest_data = QuestDatabase.get_quest(quest_id)
	var quest_name = quest_data.get("name", "任务")
	QuestRewardDialog.show_reward(self, quest_name, rewards, func(): refresh_all_quests())

static func create_fullscreen(game_manager) -> QuestUI:
	var quest_ui = load("res://ui/quest_ui.tscn").instantiate()
	quest_ui.quest_manager = game_manager.quest_manager
	return quest_ui
