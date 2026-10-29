extends Panel

const UIStyle = preload("res://scripts/ui_style.gd")
const RankingHall = preload("res://ui/city/ranking_hall.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")


const RANKING_FETCH_COOLDOWN_MS: int = 5 * 60 * 1000

var _player_rankings = []
var _pet_evolution_rankings = []
var _pet_non_evolution_rankings = []
var _tower_rankings = []
var _suit_dungeon_rankings = []
var _gang_rankings = []
var _last_ranking_fetch_msec_by_type: Dictionary = {}

func _ready():
	var game_manager = get_meta("game_manager")
	if game_manager and game_manager.network:
		if not game_manager.network.ranking_players_loaded.is_connected(_on_players_loaded):
			game_manager.network.ranking_players_loaded.connect(_on_players_loaded)
		if not game_manager.network.ranking_pets_loaded.is_connected(_on_pets_loaded):
			game_manager.network.ranking_pets_loaded.connect(_on_pets_loaded)
		if not game_manager.network.ranking_loaded.is_connected(_on_tower_loaded):
			game_manager.network.ranking_loaded.connect(_on_tower_loaded)
		if not game_manager.network.ranking_suit_dungeon_loaded.is_connected(_on_suit_dungeon_loaded):
			game_manager.network.ranking_suit_dungeon_loaded.connect(_on_suit_dungeon_loaded)
	if game_manager and game_manager.gang_manager:
		if not game_manager.gang_manager.ranking_updated.is_connected(_on_gang_ranking_loaded):
			game_manager.gang_manager.ranking_updated.connect(_on_gang_ranking_loaded)

	load_rankings("players")

func _ranking_cached_array(ranking_type: String) -> Array:
	match ranking_type:
		"players":
			return _player_rankings
		"pets_evolution":
			return _pet_evolution_rankings
		"pets_non_evolution":
			return _pet_non_evolution_rankings
		"tower":
			return _tower_rankings
		"suit_dungeon":
			return _suit_dungeon_rankings
		"gang":
			return _gang_rankings
		_:
			return []


func _ranking_should_use_cache(ranking_type: String) -> bool:
	if not _last_ranking_fetch_msec_by_type.has(ranking_type):
		return false
	var elapsed: = Time.get_ticks_msec() - int(_last_ranking_fetch_msec_by_type[ranking_type])
	return elapsed < RANKING_FETCH_COOLDOWN_MS


func load_rankings(ranking_type: String):
	set_meta("current_type", ranking_type)
	var content_container = get_meta("content_container") as VBoxContainer
	var game_manager = get_meta("game_manager")

	for child in content_container.get_children():
		child.queue_free()

	if game_manager and game_manager.network and game_manager.network.is_logged_in():
		if ranking_type == "gang":
			if _ranking_should_use_cache(ranking_type):
				_display_rankings(_ranking_cached_array(ranking_type), ranking_type)
				return
		elif _ranking_should_use_cache(ranking_type):
			_display_rankings(_ranking_cached_array(ranking_type), ranking_type)
			return

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.offset_left = 10
	list.offset_top = 10
	list.offset_right = -10
	list.offset_bottom = -10
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	if game_manager and game_manager.network and game_manager.network.is_logged_in():
		if ranking_type == "gang" and game_manager.gang_manager:
			game_manager.gang_manager.refresh_ranking()
		elif ranking_type == "players":
			game_manager.network.get_ranking_players()
		elif ranking_type == "tower":
			game_manager.network.get_tower_ranking()
		elif ranking_type == "suit_dungeon":
			game_manager.network.get_suit_dungeon_ranking()
		elif ranking_type == "pets_non_evolution":
			game_manager.network.get_ranking_pets_non_evolution()
		else:
			game_manager.network.get_ranking_pets_evolution()
		var loading_label = Label.new()
		loading_label.text = "加载中..."
		loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loading_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list.add_child(loading_label)
	else:
		_show_test_data(list, ranking_type)

func _on_players_loaded(rankings):
	_player_rankings = rankings
	_last_ranking_fetch_msec_by_type["players"] = Time.get_ticks_msec()
	var current_type = get_meta("current_type")
	if current_type == "players":
		_display_rankings(rankings, "players")

func _on_pets_loaded(rankings, category: String = "pets_evolution"):
	if category == "pets_non_evolution":
		_pet_non_evolution_rankings = rankings
		_last_ranking_fetch_msec_by_type["pets_non_evolution"] = Time.get_ticks_msec()
		if get_meta("current_type") == "pets_non_evolution":
			_display_rankings(rankings, "pets_non_evolution")
	else:
		_pet_evolution_rankings = rankings
		_last_ranking_fetch_msec_by_type["pets_evolution"] = Time.get_ticks_msec()
		if get_meta("current_type") == "pets_evolution":
			_display_rankings(rankings, "pets_evolution")

func _on_tower_loaded(rankings):
	_tower_rankings = rankings
	_last_ranking_fetch_msec_by_type["tower"] = Time.get_ticks_msec()
	var current_type = get_meta("current_type")
	if current_type == "tower":
		_display_rankings(rankings, "tower")

func _on_gang_ranking_loaded(rankings: Array) -> void :
	_gang_rankings = rankings
	_last_ranking_fetch_msec_by_type["gang"] = Time.get_ticks_msec()
	if get_meta("current_type") == "gang":
		_display_rankings(rankings, "gang")

func _on_suit_dungeon_loaded(rankings):
	_suit_dungeon_rankings = rankings
	_last_ranking_fetch_msec_by_type["suit_dungeon"] = Time.get_ticks_msec()
	var current_type = get_meta("current_type")
	if current_type == "suit_dungeon":
		_display_rankings(rankings, "suit_dungeon")

func _display_rankings(rankings, ranking_type: String):
	var content_container = get_meta("content_container") as VBoxContainer

	for child in content_container.get_children():
		child.queue_free()

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(scroll)
	TouchScrollUtils.configure_scroll(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	list.offset_left = 10
	list.offset_top = 10
	list.offset_right = -10
	list.offset_bottom = -10
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)

	if rankings.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "暂无排行数据"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list.add_child(empty_label)
	else:
		if ranking_type == "players":
			_display_player_rankings(list, rankings)
		elif ranking_type == "tower":
			_display_tower_rankings(list, rankings)
		elif ranking_type == "suit_dungeon":
			_display_suit_dungeon_rankings(list, rankings)
		elif ranking_type == "gang":
			_display_gang_rankings(list, rankings)
		elif ranking_type == "pets_evolution" or ranking_type == "pets_non_evolution":
			_display_pet_rankings(list, rankings)
		else:
			_display_pet_rankings(list, rankings)
	TouchScrollUtils.enable_touch_drag_passthrough(list)

func _show_test_data(list: VBoxContainer, ranking_type: String):
	if ranking_type == "players":
		var test_data = [
			{"nickname": "大佬", "level": 99, "realm": "大成", "cultivation": 9999999, "reincarnation": 5}, 
			{"nickname": "剑仙", "level": 88, "realm": "合体", "cultivation": 8888888, "reincarnation": 3}, 
			{"nickname": "魔道", "level": 85, "realm": "合体", "cultivation": 7777777, "reincarnation": 2}, 
			{"nickname": "散修", "level": 72, "realm": "炼虚", "cultivation": 5555555, "reincarnation": 1}, 
			{"nickname": "小道", "level": 65, "realm": "化神", "cultivation": 3333333, "reincarnation": 0}, 
		]
		_display_player_rankings(list, test_data)
	elif ranking_type == "tower":
		var test_data = [
			{"nickname": "大佬", "tower_highest": 450}, 
			{"nickname": "剑仙", "tower_highest": 380}, 
			{"nickname": "魔道", "tower_highest": 320}, 
			{"nickname": "散修", "tower_highest": 250}, 
			{"nickname": "小道", "tower_highest": 180}, 
		]
		_display_tower_rankings(list, test_data)
	elif ranking_type == "suit_dungeon":
		var test_data = [
			{"nickname": "大佬", "suit_dungeon_progress": 50}, 
			{"nickname": "剑仙", "suit_dungeon_progress": 42}, 
			{"nickname": "魔道", "suit_dungeon_progress": 35}, 
			{"nickname": "散修", "suit_dungeon_progress": 28}, 
			{"nickname": "小道", "suit_dungeon_progress": 15}, 
		]
		_display_suit_dungeon_rankings(list, test_data)
	else:
		var test_data = [
			{"pet_name": "九尾", "nickname": "大佬", "level": 50, "growth_rate": 5.5, "form": "九尾", "generation": 3, "element": "火"}, 
			{"pet_name": "金翅", "nickname": "剑仙", "level": 45, "growth_rate": 5.2, "form": "金翅", "generation": 2, "element": "金"}, 
			{"pet_name": "玄武", "nickname": "魔道", "level": 42, "growth_rate": 4.8, "form": "真武", "generation": 2, "element": "水"}, 
		]
		_display_pet_rankings(list, test_data)

func _format_ranking_reincarnation(value) -> int:
	return mini(99, maxi(0, int(value)))

func _display_player_rankings(list: VBoxContainer, rankings: Array):
	for i in range(rankings.size()):
		var r = rankings[i]
		var rank_panel = Panel.new()
		rank_panel.custom_minimum_size = Vector2(0, 50)
		rank_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
		list.add_child(rank_panel)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 10
		hbox.offset_right = -10
		hbox.offset_bottom = -10
		hbox.add_theme_constant_override("separation", 15)
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_child(hbox)

		var rank_label = Label.new()
		var rank_text = str(i + 1)
		if i == 0:
			rank_text = "🥇"
		elif i == 1:
			rank_text = "🥈"
		elif i == 2:
			rank_text = "🥉"
		rank_label.text = rank_text
		rank_label.custom_minimum_size = Vector2(40, 0)
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(rank_label)

		var name_label = Label.new()
		name_label.text = r.get("nickname", r.get("username", "未知"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		hbox.add_child(name_label)

		var level_label = Label.new()
		level_label.text = "Lv." + str(int(r.get("level", 1)))
		level_label.custom_minimum_size = Vector2(60, 0)
		level_label.add_theme_font_size_override("font_size", 16)
		level_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		hbox.add_child(level_label)

		var realm_label = Label.new()
		realm_label.text = str(r.get("realm", "凡人"))
		realm_label.custom_minimum_size = Vector2(70, 0)
		realm_label.add_theme_font_size_override("font_size", 16)
		realm_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		hbox.add_child(realm_label)

		var cultivation_label = Label.new()
		cultivation_label.text = "修:" + str(int(r.get("cultivation", 0)))
		cultivation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cultivation_label.add_theme_font_size_override("font_size", 18)
		cultivation_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		cultivation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(cultivation_label)

		var reincarnation_label = Label.new()
		reincarnation_label.text = "投:" + str(_format_ranking_reincarnation(r.get("reincarnation", 0)))
		reincarnation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reincarnation_label.add_theme_font_size_override("font_size", 18)
		reincarnation_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.5))
		reincarnation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(reincarnation_label)

func _display_pet_rankings(list: VBoxContainer, rankings: Array):
	for i in range(rankings.size()):
		var r = rankings[i]
		var rank_panel = Panel.new()
		rank_panel.custom_minimum_size = Vector2(0, 60)
		rank_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
		list.add_child(rank_panel)

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.offset_left = 10
		vbox.offset_top = 5
		vbox.offset_right = -10
		vbox.offset_bottom = -5
		vbox.add_theme_constant_override("separation", 2)
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_child(vbox)

		var hbox1 = HBoxContainer.new()
		hbox1.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.add_child(hbox1)

		var rank_label = Label.new()
		var rank_text = str(i + 1)
		if i == 0:
			rank_text = "🥇"
		elif i == 1:
			rank_text = "🥈"
		elif i == 2:
			rank_text = "🥉"
		rank_label.text = rank_text
		rank_label.custom_minimum_size = Vector2(40, 0)
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox1.add_child(rank_label)

		var pet_name_label = Label.new()
		var rn2: = str(r.get("pet_name", "未知宠物"))
		var rc2: = int(r.get("reincarnation_count", 0))
		pet_name_label.text = rn2 + (("(%d)" % rc2) if rc2 > 0 else "")
		pet_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pet_name_label.add_theme_font_size_override("font_size", 18)
		var mut_count: = int(r.get("mutation_count", 0))
		if mut_count > 0:
			pet_name_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		else:
			pet_name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		hbox1.add_child(pet_name_label)

		var owner_label = Label.new()
		owner_label.text = "主人: " + str(r.get("nickname", r.get("username", "未知")))
		owner_label.add_theme_font_size_override("font_size", 18)
		owner_label.add_theme_color_override("font_color", Color(0.631, 0.611, 0.564))
		hbox1.add_child(owner_label)

		var hbox2 = HBoxContainer.new()
		hbox2.add_theme_constant_override("separation", 15)
		vbox.add_child(hbox2)

		var level_label = Label.new()
		level_label.text = "Lv." + str(int(r.get("level", 1)))
		level_label.add_theme_font_size_override("font_size", 18)
		level_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		hbox2.add_child(level_label)

		var growth_label = Label.new()
		growth_label.text = "总成长:" + str(r.get("growth_rate", 3.0))
		growth_label.add_theme_font_size_override("font_size", 18)
		growth_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		hbox2.add_child(growth_label)

		var form_label = Label.new()
		form_label.text = str(r.get("form", "初始形态"))
		form_label.add_theme_font_size_override("font_size", 18)
		form_label.add_theme_color_override("font_color", Color(1.000, 0.905, 0.640))
		hbox2.add_child(form_label)

		var gen_label = Label.new()
		gen_label.text = "代数:" + str(r.get("generation", 0))
		gen_label.add_theme_font_size_override("font_size", 18)
		gen_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
		hbox2.add_child(gen_label)

		var element_label = Label.new()
		element_label.text = str(r.get("element", "无"))
		element_label.add_theme_font_size_override("font_size", 18)
		element_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		hbox2.add_child(element_label)

func _display_tower_rankings(list: VBoxContainer, rankings: Array):
	for i in range(rankings.size()):
		var r = rankings[i]
		var rank_panel = Panel.new()
		rank_panel.custom_minimum_size = Vector2(0, 50)
		rank_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
		list.add_child(rank_panel)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 10
		hbox.offset_right = -10
		hbox.offset_bottom = -10
		hbox.add_theme_constant_override("separation", 15)
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_child(hbox)

		var rank_label = Label.new()
		var rank_text = str(i + 1)
		if i == 0:
			rank_text = "🥇"
		elif i == 1:
			rank_text = "🥈"
		elif i == 2:
			rank_text = "🥉"
		rank_label.text = rank_text
		rank_label.custom_minimum_size = Vector2(40, 0)
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(rank_label)

		var name_label = Label.new()
		name_label.text = r.get("nickname", r.get("username", "未知"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		hbox.add_child(name_label)

		var floor_label = Label.new()
		floor_label.text = "第 %d 层" % int(r.get("tower_highest", 0))
		floor_label.custom_minimum_size = Vector2(100, 0)
		floor_label.add_theme_font_size_override("font_size", 18)
		floor_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(floor_label)

func _display_suit_dungeon_rankings(list: VBoxContainer, rankings: Array):
	for i in range(rankings.size()):
		var r = rankings[i]
		var rank_panel = Panel.new()
		rank_panel.custom_minimum_size = Vector2(0, 50)
		rank_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
		list.add_child(rank_panel)

		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 10
		hbox.offset_right = -10
		hbox.offset_bottom = -10
		hbox.add_theme_constant_override("separation", 15)
		hbox.mouse_filter = Control.MOUSE_FILTER_PASS
		rank_panel.add_child(hbox)

		var rank_label = Label.new()
		var rank_text = str(i + 1)
		if i == 0:
			rank_text = "🥇"
		elif i == 1:
			rank_text = "🥈"
		elif i == 2:
			rank_text = "🥉"
		rank_label.text = rank_text
		rank_label.custom_minimum_size = Vector2(40, 0)
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(rank_label)

		var name_label = Label.new()
		name_label.text = r.get("nickname", r.get("username", "未知"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color(0.945, 0.912, 0.850))
		hbox.add_child(name_label)

		var level_label = Label.new()
		level_label.text = "第 %d 层" % int(r.get("suit_dungeon_progress", 0))
		level_label.custom_minimum_size = Vector2(100, 0)
		level_label.add_theme_font_size_override("font_size", 18)
		level_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.9))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(level_label)

func _display_gang_rankings(list: VBoxContainer, rankings: Array) -> void :
	for i in range(rankings.size()):
		var r = rankings[i]
		if not r is Dictionary:
			continue
		var rank_panel = Panel.new()
		rank_panel.custom_minimum_size = Vector2(0, 50)
		rank_panel.add_theme_stylebox_override("panel", UIStyle.create_rank_style(i))
		list.add_child(rank_panel)
		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 10
		hbox.offset_top = 5
		hbox.offset_right = -10
		hbox.offset_bottom = -5
		rank_panel.add_child(hbox)
		var rank_label = Label.new()
		rank_label.text = str(i + 1)
		rank_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(rank_label)
		var name_label = Label.new()
		name_label.text = str(r.get("name", "未知帮派"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_label)
		var info = Label.new()
		info.text = "Lv.%d  领地%d  成员%d" % [int(r.get("level", 1)), int(r.get("territory_count", 0)), int(r.get("member_count", 0))]
		hbox.add_child(info)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		var game_manager = get_meta("game_manager") if has_meta("game_manager") else null
		if game_manager and game_manager.network:
			if game_manager.network.ranking_players_loaded.is_connected(_on_players_loaded):
				game_manager.network.ranking_players_loaded.disconnect(_on_players_loaded)
			if game_manager.network.ranking_pets_loaded.is_connected(_on_pets_loaded):
				game_manager.network.ranking_pets_loaded.disconnect(_on_pets_loaded)
			if game_manager.network.ranking_loaded.is_connected(_on_tower_loaded):
				game_manager.network.ranking_loaded.disconnect(_on_tower_loaded)
