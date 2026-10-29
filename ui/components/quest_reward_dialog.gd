extends Control

class_name QuestRewardDialog

const UIStyle = preload("res://scripts/ui_style.gd")

var on_confirm: Callable = Callable()
var _pending_quest_name: String = ""
var _pending_rewards: Dictionary = {}
var _is_ready: bool = false
var _dialog_size: Vector2 = Vector2(380, 420)

var _quest_name_label: Label = null
var _exp_label: Label = null
var _gold_label: Label = null
var _items_container: VBoxContainer = null
var _main_panel: Panel = null

func _ready():
	_is_ready = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000

	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_main_panel = Panel.new()
	_main_panel.name = "Panel"
	_main_panel.custom_minimum_size = _dialog_size
	_main_panel.size = _dialog_size
	_main_panel.add_theme_stylebox_override("panel", UIStyle.create_popup_style())
	add_child(_main_panel)
	_recenter_panel()
	if get_viewport():
		get_viewport().size_changed.connect(_recenter_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "🎉 任务完成"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	vbox.add_child(title_label)

	_quest_name_label = Label.new()
	_quest_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_name_label.add_theme_font_size_override("font_size", 20)
	_quest_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(_quest_name_label)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer1)

	var rewards_title = Label.new()
	rewards_title.text = "获得奖励"
	rewards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_title.add_theme_font_size_override("font_size", 16)
	rewards_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(rewards_title)

	_exp_label = Label.new()
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_label.add_theme_font_size_override("font_size", 18)
	_exp_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))
	vbox.add_child(_exp_label)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.92, 0.4, 1))
	vbox.add_child(_gold_label)

	_items_container = VBoxContainer.new()
	_items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_items_container)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	var confirm_btn = Button.new()
	confirm_btn.text = "领取奖励"
	UIStyle.style_popup_button(confirm_btn, true)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	vbox.add_child(confirm_btn)

	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer3)

	if _pending_quest_name != "":
		_apply_setup(_pending_quest_name, _pending_rewards)

func _recenter_panel() -> void :
	if _main_panel == null:
		return
	var view_size: Vector2 = get_viewport_rect().size
	_main_panel.position = (view_size - _dialog_size) * 0.5
	_main_panel.size = _dialog_size

func setup(quest_name: String, rewards: Dictionary, confirm_callback: Callable = Callable()):
	on_confirm = confirm_callback

	if _is_ready:
		_apply_setup(quest_name, rewards)
	else:
		_pending_quest_name = quest_name
		_pending_rewards = rewards

func _apply_setup(quest_name: String, rewards: Dictionary):
	if _quest_name_label:
		_quest_name_label.text = quest_name

	var has_any_reward: = false
	if int(rewards.get("exp", 0)) > 0:
		has_any_reward = true
	if int(rewards.get("gold", 0)) > 0:
		has_any_reward = true
	if rewards.has("items") and rewards.items is Array and rewards.items.size() > 0:
		has_any_reward = true

	if _exp_label:
		if rewards.has("exp") and rewards.exp > 0:
			_exp_label.text = "✨ 经验：%d" % rewards.exp
			_exp_label.visible = true
		else:
			_exp_label.visible = false

	if _gold_label:
		if rewards.has("gold") and rewards.gold > 0:
			_gold_label.text = "💰 金币：%d" % rewards.gold
			_gold_label.visible = true
		else:
			_gold_label.visible = false

	if _items_container:
		for child in _items_container.get_children():
			child.queue_free()

		if rewards.has("items") and rewards.items.size() > 0:
			for item_entry in rewards.items:
				var item_label = Label.new()
				item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				item_label.add_theme_font_size_override("font_size", 18)
				item_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1, 1))
				item_label.text = "🎁 %s" % item_entry
				_items_container.add_child(item_label)
		elif not has_any_reward:
			var hint_label = Label.new()
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_label.add_theme_font_size_override("font_size", 16)
			hint_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9, 1))
			hint_label.text = "奖励已发放，请留意背包与属性变化"
			_items_container.add_child(hint_label)

func _on_confirm_pressed():
	if on_confirm.is_valid():
		on_confirm.call()
	queue_free()

static func show_reward(parent: Node, quest_name: String, rewards: Dictionary, confirm_callback: Callable = Callable()):
	var dialog = QuestRewardDialog.new()
	var item_count: = 0
	if rewards.has("items") and rewards.items is Array:
		item_count = rewards.items.size()

	var dialog_height: = float(clampi(420 + item_count * 36, 420, 620))
	dialog._dialog_size = Vector2(380, dialog_height)

	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.get_tree().root.add_child(dialog)
		dialog.call_deferred("setup", quest_name, rewards, confirm_callback)
	return dialog
