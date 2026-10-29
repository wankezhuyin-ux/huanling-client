class_name SuitDungeonBattle
extends Control

const SuitDatabase = preload("res://scripts/data/suit_database_detailed.gd")
const SuitDungeonMonsters = preload("res://scripts/data/suit_dungeon_monsters.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

signal battle_ended(victory: bool, level: int)

var dungeon_level: int = 1
var game_manager = null
var suit_data: Dictionary = {}


var player_hp: int = 0
var player_max_hp: int = 0
var player_mp: int = 0
var player_max_mp: int = 0
var pet_hp: float = 0
var pet_max_hp: float = 0


var current_wave: int = 1
const MAX_WAVES: int = 10
var current_monsters: Array = []
var monster_hp_bars: Array = []
var monster_sprites: Array = []

var battle_timer: Timer = null
var battle_log: RichTextLabel = null
var is_battling: bool = false


var wave_label: Label = null
var monster_panel: VBoxContainer = null

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)


	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIStyle.create_panel_style())
	add_child(bg)


	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	add_child(vbox)


	var title = UIStyle.create_title_label("🛡️ 套装副本战斗")
	vbox.add_child(title)


	wave_label = Label.new()
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	vbox.add_child(wave_label)


	var info_panel = _create_info_panel()
	vbox.add_child(info_panel)


	var battle_area = _create_battle_area()
	vbox.add_child(battle_area)


	battle_log = RichTextLabel.new()
	battle_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_log.add_theme_font_size_override("normal_font_size", 14)
	battle_log.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	battle_log.bbcode_enabled = true
	battle_log.scroll_following = true
	vbox.add_child(battle_log)


	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)

	var start_btn = _create_action_button("开始战斗", Color(0.2, 0.7, 0.3))
	start_btn.pressed.connect(_on_start_battle)
	btn_hbox.add_child(start_btn)

	var flee_btn = _create_action_button("撤退", Color(0.7, 0.2, 0.2))
	flee_btn.pressed.connect(_on_flee)
	btn_hbox.add_child(flee_btn)


	battle_timer = Timer.new()
	battle_timer.wait_time = 0.5
	battle_timer.one_shot = false
	battle_timer.timeout.connect(_on_battle_tick)
	add_child(battle_timer)

func setup(level: int, gm):
	dungeon_level = level
	game_manager = gm
	suit_data = SuitDatabase.get_suit_data(level)


	player_max_hp = game_manager.player.max_hp
	player_hp = player_max_hp
	player_max_mp = game_manager.player.max_mp
	player_mp = player_max_mp

	var active_pet = game_manager.pet_manager.get_active_pet() if game_manager.pet_manager else null
	if active_pet:
		pet_max_hp = active_pet.max_hp
		pet_hp = pet_max_hp


	current_wave = 1


	_create_wave_monsters()


	_update_ui()

	_log("进入第%d层套装副本！" % level)
	_log("共%d波怪物，击败所有怪物获得胜利！" % MAX_WAVES)

func _create_info_panel() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 10
	hbox.offset_right = -15
	hbox.offset_bottom = -10
	panel.add_child(hbox)


	var player_info = VBoxContainer.new()
	player_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(player_info)

	var player_name = Label.new()
	player_name.text = "玩家: %s" % game_manager.player.player_name
	player_name.add_theme_font_size_override("font_size", 14)
	player_info.add_child(player_name)

	var player_hp_label = Label.new()
	player_hp_label.name = "PlayerHPLabel"
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	player_hp_label.add_theme_font_size_override("font_size", 12)
	player_hp_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.4))
	player_info.add_child(player_hp_label)


	var dungeon_info = VBoxContainer.new()
	dungeon_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(dungeon_info)

	var dungeon_name = Label.new()
	dungeon_name.text = "第%d层 - %s" % [dungeon_level, suit_data.get("name", "")]
	dungeon_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dungeon_name.add_theme_font_size_override("font_size", 14)
	dungeon_name.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	dungeon_info.add_child(dungeon_name)

	var monster_count = Label.new()
	monster_count.name = "MonsterCountLabel"
	monster_count.text = "怪物: 3只"
	monster_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	monster_count.add_theme_font_size_override("font_size", 12)
	dungeon_info.add_child(monster_count)

	return panel

func _create_battle_area() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 200)
	panel.add_theme_stylebox_override("panel", UIStyle.create_item_style())

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_top = 15
	hbox.offset_right = -15
	hbox.offset_bottom = -15
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)


	var player_panel = _create_combatant_panel("玩家", true)
	player_panel.name = "PlayerPanel"
	hbox.add_child(player_panel)


	var vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 24)
	vs_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(vs_label)


	monster_panel = VBoxContainer.new()
	monster_panel.name = "MonsterPanel"
	monster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	monster_panel.add_theme_constant_override("separation", 10)
	hbox.add_child(monster_panel)

	return panel

func _create_combatant_panel(name: String, is_player: bool) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(150, 0)
	vbox.add_theme_constant_override("separation", 5)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(name_label)

	var avatar = Panel.new()
	avatar.custom_minimum_size = Vector2(80, 80)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.072, 0.080, 0.079) if is_player else Color(0.5, 0.3, 0.3)
	avatar_style.corner_radius_top_left = 0
	avatar_style.corner_radius_top_right = 0
	avatar_style.corner_radius_bottom_left = 0
	avatar_style.corner_radius_bottom_right = 0
	avatar.add_theme_stylebox_override("panel", avatar_style)
	vbox.add_child(avatar)

	return vbox

func _create_wave_monsters():
	current_monsters.clear()
	monster_hp_bars.clear()
	monster_sprites.clear()

	# 数据层已按「层 + 波」生成整组怪物（第 10 波是 BOSS），别再自己乘倍率。
	# 旧代码调的 get_monster_id_for_level()/get_monster_data() 在数据层早就不存在了，
	# 会让这个脚本整体解析失败（副本战斗直接进不去）。
	var wave_list: Array = SuitDungeonMonsters.get_wave_monsters(dungeon_level, current_wave)
	for m in wave_list:
		if m is Dictionary:
			current_monsters.append((m as Dictionary).duplicate(true))

	_update_monster_ui()
	_update_ui()

	_log("第 %d/%d 波怪物出现！" % [current_wave, MAX_WAVES])


func _update_monster_ui():
	if not monster_panel:
		return


	for child in monster_panel.get_children():
		child.queue_free()
	monster_hp_bars.clear()
	monster_sprites.clear()


	for i in range(current_monsters.size()):
		var monster_ui = _create_monster_ui_with_sprite(current_monsters[i], i)
		monster_panel.add_child(monster_ui)

func _create_monster_ui_with_sprite(monster: Dictionary, index: int) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)


	var sprite_container = Panel.new()
	sprite_container.custom_minimum_size = Vector2(50, 50)
	sprite_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sprite_style = StyleBoxFlat.new()
	sprite_style.bg_color = Color(0.072, 0.080, 0.079)
	sprite_style.corner_radius_top_left = 0
	sprite_style.corner_radius_top_right = 0
	sprite_style.corner_radius_bottom_left = 0
	sprite_style.corner_radius_bottom_right = 0
	sprite_container.add_theme_stylebox_override("panel", sprite_style)


	var texture_path = monster.get("texture", "")
	if texture_path != "":
		var texture = load(texture_path)
		if texture:
			var sprite = TextureRect.new()
			sprite.texture = texture
			sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
			sprite_container.add_child(sprite)
			monster_sprites.append(sprite)

	hbox.add_child(sprite_container)


	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = monster.name
	name_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(name_label)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 20)
	hp_bar.max_value = monster.max_hp
	hp_bar.value = monster.hp
	hp_bar.add_theme_stylebox_override("fill", _create_hp_style())
	info_vbox.add_child(hp_bar)
	monster_hp_bars.append(hp_bar)

	var hp_label = Label.new()
	hp_label.name = "MonsterHPLabel_%d" % index
	hp_label.text = "%d/%d" % [monster.hp, monster.max_hp]
	hp_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(hp_label)

	return hbox

func _create_hp_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.2, 0.2)
	return style

func _create_action_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 45)
	btn.text = text
	btn.add_theme_font_size_override("font_size", 16)

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.corner_radius_top_left = 0
	normal_style.corner_radius_top_right = 0
	normal_style.corner_radius_bottom_left = 0
	normal_style.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("normal", normal_style)

	return btn

func _update_ui():

	if wave_label:
		wave_label.text = "第 %d/%d 波" % [current_wave, MAX_WAVES]


	var player_hp_label = get_node_or_null("PlayerHPLabel")
	if player_hp_label:
		player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]


	var monster_count_label = get_node_or_null("MonsterCountLabel")
	if monster_count_label:
		monster_count_label.text = "怪物: %d只" % current_monsters.size()


	for i in range(min(current_monsters.size(), monster_hp_bars.size())):
		var monster = current_monsters[i]
		var hp_bar = monster_hp_bars[i]
		hp_bar.max_value = monster.max_hp
		hp_bar.value = monster.hp

		var hp_label = get_node_or_null("MonsterHPLabel_%d" % i)
		if hp_label:
			hp_label.text = "%d/%d" % [monster.hp, monster.max_hp]

func _on_start_battle():
	if is_battling:
		return

	is_battling = true
	_log("战斗开始！")
	battle_timer.start()

func _on_flee():
	_log("撤退了...")
	battle_ended.emit(false, dungeon_level)
	queue_free()

func _on_battle_tick():
	if not is_battling:
		return


	_player_attack()


	var all_dead = true
	for monster in current_monsters:
		if monster.hp > 0:
			all_dead = false
			break

	if all_dead:
		if current_wave >= MAX_WAVES:
			_log("所有波次完成！胜利！")
			battle_ended.emit(true, dungeon_level)
			queue_free()
			return
		else:
			current_wave += 1
			_log("第%d波怪物被击败！" % (current_wave - 1))
			_create_wave_monsters()
			return


	_monsters_attack()


	_update_ui()

func _player_attack():
	var player_attack = game_manager.player.get_attack()


	for monster in current_monsters:
		if monster.hp > 0:
			var damage = max(1, player_attack - monster.defense)
			monster.hp = max(0, monster.hp - damage)
			_log("对 %s 造成 %d 点伤害！" % [monster.name, damage])
			break

func _monsters_attack():
	for monster in current_monsters:
		if monster.hp <= 0:
			continue

		var damage = max(1, monster.attack - game_manager.player.get_defense())
		player_hp = max(0, player_hp - damage)
		_log("%s 对你造成 %d 点伤害！" % [monster.name, damage])

		if player_hp <= 0:
			_log("你被击败了...")
			battle_ended.emit(false, dungeon_level)
			queue_free()
			return

func _log(message: String):
	if battle_log:
		battle_log.append_text(message + "\n")
