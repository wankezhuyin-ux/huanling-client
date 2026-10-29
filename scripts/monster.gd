extends Node
class_name Monster

const MonsterDatabase = preload("res://scripts/data/monster_database.gd")
const GameDataRef = preload("res://scripts/game_data.gd")
const MonsterGeneratorRef = preload("res://scripts/monster_generator.gd")
const PetDatabase = preload("res://scripts/pet_data_complete.gd")
const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const FestivalGiftConfig = preload("res://scripts/data/festival_gift_config.gd")
const MAYDAY_EVENT_TAG_META: = "event_mayday_mutant_anu"
const FESTIVAL_EVENT_TAG_META: = "festival_event_tag"
const FESTIVAL_GIFT_DROP_META: = "festival_gift_drop"
const EVENT_NO_CAPTURE_META: = "event_no_capture"

func _get_monster_data(monster_id: String) -> Dictionary:
	return MonsterDatabase.get_monster(monster_id)

func _get_pet_id(monster_id: String) -> String:
	return MonsterDatabase.get_pet_id(monster_id)


var id: String
var monster_name: String
var level: int = 1
var element: String = "普通"


var attack: int = 5
var defense: int = 3
var agility: int = 2
var hp: int = 20
var max_hp: int = 20


var exp_reward: int = 10
var gold_reward: int = 5
var monster_id: String = ""

var is_evolution_pet: bool = true


signal died

func _init():
	id = _generate_id()

func _generate_id() -> String:
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(8):
		result += chars[randi() % chars.length()]
	return result


func take_damage(damage: int) -> int:
	var actual_damage = max(1, damage - defense / 2)
	hp = max(0, hp - actual_damage)

	if hp <= 0:
		died.emit()

	return actual_damage

func is_alive() -> bool:
	return hp > 0

func get_hp_percent() -> float:
	return float(hp) / max_hp


static func create_from_template(monster_data: Dictionary) -> Monster:
	var monster = Monster.new()

	if monster_data.is_empty():
		push_error("怪物数据为空")
		monster.monster_name = "未知怪物"
		return monster

	var monster_id = monster_data.get("id", "")
	var pet_id = monster_data.get("pet_id", "")
	var level = monster_data.get("level", 1)

	if monster_data.has("name") and monster_data.get("name", "") != "":
		var pet_id_val = monster_data.get("pet_id", "")
		monster.monster_id = pet_id_val if not pet_id_val.is_empty() else monster_id
		monster.monster_name = monster_data.get("name", "未知怪物")
		monster.level = monster_data.get("level", 1)
		monster.element = monster_data.get("element", "普通")
		monster.attack = monster_data.get("attack", 5)
		monster.defense = monster_data.get("defense", 3)
		monster.agility = monster_data.get("agility", 2)
		monster.max_hp = monster_data.get("hp", 20)
		monster.hp = monster.max_hp
		var base_exp = monster_data.get("exp_reward", 0)
		if base_exp == 0:
			base_exp = monster.level * wild_exp_per_level
		monster.exp_reward = base_exp
		monster.gold_reward = monster_data.get("gold_reward", monster.level * wild_gold_per_level)
	elif pet_id != "" and level > 0:
		var generated = MonsterGeneratorRef.generate_monster(pet_id, level)
		if generated.is_empty():
			push_error("无法生成怪物: pet_id=" + pet_id + ", level=" + str(level))
			monster.monster_name = "未知怪物"
			if monster_data.has("is_evolution_pet"):
				monster.is_evolution_pet = bool(monster_data.get("is_evolution_pet", true))
			else:
				monster.is_evolution_pet = EvolutionDataClass.is_evolution_pet(str(pet_id)) if not str(pet_id).is_empty() else true
			return monster
		monster.monster_id = pet_id
		monster.monster_name = generated.get("name", "未知怪物")
		monster.level = generated.get("level", 1)
		monster.element = generated.get("element", "普通")
		monster.attack = generated.get("attack", 5)
		monster.defense = generated.get("defense", 3)
		monster.agility = generated.get("agility", 2)
		monster.max_hp = generated.get("hp", 20)
		monster.hp = monster.max_hp
		monster.exp_reward = generated.get("exp_reward", monster.level * wild_exp_per_level)
		monster.gold_reward = generated.get("gold_reward", monster.level * wild_gold_per_level)
	else:
		var db_data = MonsterDatabase.get_monster(monster_id)
		if not db_data.is_empty():
			monster.monster_id = monster_id
			monster.monster_name = db_data.get("name", "未知怪物")
			monster.level = db_data.get("level", 1)
			monster.element = element_from_map_monster_entry(monster_data)
			monster.attack = db_data.get("attack", 5)
			monster.defense = db_data.get("defense", 3)
			monster.agility = db_data.get("agility", 2)
			monster.max_hp = db_data.get("hp", 20)
			monster.hp = monster.max_hp
			monster.exp_reward = db_data.get("exp_reward", 10)
			monster.gold_reward = db_data.get("gold_reward", 5)
		else:
			push_error("找不到怪物数据: " + monster_id)
			monster.monster_name = "未知怪物"

	if monster_data.has("is_evolution_pet"):
		monster.is_evolution_pet = bool(monster_data.get("is_evolution_pet", true))
	else:
		var evo_id: String = str(monster_data.get("pet_id", "")).strip_edges()
		if evo_id.is_empty():
			evo_id = str(monster.monster_id).strip_edges()
		if not evo_id.is_empty():
			monster.is_evolution_pet = EvolutionDataClass.is_evolution_pet(evo_id)
		else:
			monster.is_evolution_pet = true

	return monster


static func attacker_uses_evolution_pet_element_rate(m) -> bool:
	if m is Dictionary:
		if m.has("is_evolution_pet"):
			return bool(m.get("is_evolution_pet", true))
		var pid: String = str(m.get("pet_id", "")).strip_edges()
		if not pid.is_empty():
			return EvolutionDataClass.is_evolution_pet(pid)
		var mid: String = str(m.get("monster_id", "")).strip_edges()
		if not mid.is_empty():
			var dbp: String = MonsterDatabase.get_pet_id(mid)
			if not dbp.is_empty():
				return EvolutionDataClass.is_evolution_pet(dbp)
		return true
	return m.is_evolution_pet


static var wild_spawn_min: int = 1
static var wild_spawn_max: int = 5
static var wild_exp_per_level: int = 100
static var wild_gold_per_level: int = 1
static var wild_battle_max_rounds: int = 10

static func set_wild_spawn_range(min_count: int, max_count: int) -> void :
	wild_spawn_min = maxi(1, min_count)
	wild_spawn_max = maxi(wild_spawn_min, max_count)

static func apply_wild_battle_runtime(wb: Dictionary) -> void :
	if wb.is_empty():
		return
	set_wild_spawn_range(int(wb.get("spawnMin", wild_spawn_min)), int(wb.get("spawnMax", wild_spawn_max)))
	wild_exp_per_level = maxi(1, int(wb.get("monsterExpPerLevel", wild_exp_per_level)))
	wild_gold_per_level = maxi(0, int(wb.get("monsterGoldPerLevel", wild_gold_per_level)))
	wild_battle_max_rounds = maxi(1, int(wb.get("battleMaxRounds", wild_battle_max_rounds)))

static func create_group(map_data: Dictionary, count: int = -1) -> Array:
	var monsters = []
	var monster_templates = map_data.get("monsters", [])

	if monster_templates.is_empty():
		return monsters


	if count < 1:
		var min_c: = wild_spawn_min
		var max_c: = wild_spawn_max
		if map_data.has("spawn_min"):
			min_c = maxi(1, int(map_data.get("spawn_min", min_c)))
		if map_data.has("spawn_max"):
			max_c = maxi(min_c, int(map_data.get("spawn_max", max_c)))
		var span: = maxi(1, max_c - min_c + 1)
		count = min_c + randi() % span

	for i in range(count):
		var template = monster_templates[randi() % monster_templates.size()]

		if template.is_empty():
			continue


		var monster = create_from_template(template)
		monsters.append(monster)

	return monsters


static func create_festival_wild_monster(pet_id: String, map_level: int, event_tag: String, gift_name: String) -> Monster:
	var generated = MonsterGeneratorRef.generate_monster(pet_id, maxi(1, map_level))
	var monster = Monster.new()
	var lvl: = maxi(1, map_level)
	monster.monster_id = pet_id
	if generated.is_empty():
		push_error("无法生成节日活动怪物: pet_id=" + pet_id)
		var pd: Dictionary = PetDatabase.PET_DATA.get(pet_id, {})
		var display_name: = str(pd.get("name", "")).strip_edges()
		if display_name.is_empty():
			display_name = MonsterDatabase.get_monster_name(pet_id)
		monster.monster_name = display_name if not display_name.is_empty() else pet_id
		monster.level = lvl
		var db_data: = MonsterDatabase.get_monster(pet_id)
		if not db_data.is_empty():
			monster.element = str(db_data.get("element", "普通"))
			monster.attack = int(db_data.get("attack", 5))
			monster.defense = int(db_data.get("defense", 3))
			monster.agility = int(db_data.get("agility", 2))
			monster.max_hp = int(db_data.get("hp", 20))
		else:
			monster.element = "普通"
			monster.attack = 5
			monster.defense = 3
			monster.agility = 2
			monster.max_hp = 20
		monster.hp = monster.max_hp
		monster.exp_reward = lvl * 100
		monster.gold_reward = lvl
	else:
		monster.monster_name = str(generated.get("name", pet_id))
		monster.level = int(generated.get("level", lvl))
		monster.element = str(generated.get("element", "普通"))
		monster.attack = int(generated.get("attack", 5))
		monster.defense = int(generated.get("defense", 3))
		monster.agility = int(generated.get("agility", 2))
		monster.max_hp = int(generated.get("hp", 20))
		monster.hp = monster.max_hp
		monster.exp_reward = int(generated.get("exp_reward", monster.level * 100))
		monster.gold_reward = int(generated.get("gold_reward", monster.level))
	monster.is_evolution_pet = false
	monster.set_meta(FESTIVAL_EVENT_TAG_META, event_tag)
	monster.set_meta(FESTIVAL_GIFT_DROP_META, gift_name)
	monster.set_meta(EVENT_NO_CAPTURE_META, true)
	return monster

static func try_inject_festival_wild_spawn(map_data: Dictionary, monsters: Array, skip_for_online: bool = false) -> Array:

	if skip_for_online:
		return monsters
	var spawn_cfg: = FestivalGiftConfig.get_active_festival_wild_spawn(Time.get_unix_time_from_system())
	if spawn_cfg.is_empty():
		return monsters
	for existing in monsters:
		if existing is Dictionary:
			continue
		if existing.has_meta(FESTIVAL_EVENT_TAG_META):
			return monsters
	var map_level: = int(map_data.get("level", 1))
	if map_level < int(spawn_cfg.get("min_map_level", 500)):
		return monsters
	if randf() >= float(spawn_cfg.get("spawn_rate", 0.0)):
		return monsters
	var pet_id: = str(spawn_cfg.get("pet_id", "")).strip_edges()
	var event_tag: = str(spawn_cfg.get("event_tag", "")).strip_edges()
	var gift_name: = str(spawn_cfg.get("gift_name", "")).strip_edges()
	if pet_id.is_empty() or event_tag.is_empty() or gift_name.is_empty():
		return monsters
	var event_monster = create_festival_wild_monster(pet_id, map_level, event_tag, gift_name)
	if monsters.is_empty():
		return [event_monster]
	var replace_idx: = randi() % monsters.size()
	monsters[replace_idx] = event_monster
	return monsters

static func get_festival_gift_drop_from_defeated(defeated_monsters: Array) -> String:
	for m in defeated_monsters:
		if m is Dictionary:
			continue
		if not m.has_meta(FESTIVAL_GIFT_DROP_META):
			continue
		var gift: = str(m.get_meta(FESTIVAL_GIFT_DROP_META, "")).strip_edges()
		if not gift.is_empty():
			return gift
	return ""

static func create_mayday_mutant_anu() -> Monster:
	return create_festival_wild_monster("bianyianu", 1, MAYDAY_EVENT_TAG_META, "五一活动礼包")


static func element_from_map_monster_entry(entry: Dictionary) -> String:
	var entry_pet_id: String = str(entry.get("pet_id", ""))
	if not entry_pet_id.is_empty():
		var pd: Dictionary = PetDatabase.PET_DATA.get(entry_pet_id, {})
		return str(pd.get("element", "普通"))
	var mid: String = str(entry.get("id", ""))
	if mid.is_empty():
		return "普通"
	var db: Dictionary = MonsterDatabase.get_monster(mid)
	var pid: String = str(db.get("pet_id", ""))
	if pid.is_empty():
		pid = mid
	var pet_row: Dictionary = PetDatabase.PET_DATA.get(pid, {})
	if not pet_row.is_empty():
		return str(pet_row.get("element", "普通"))
	if not db.is_empty():
		return str(db.get("element", "普通"))
	var pet_by_mid: Dictionary = PetDatabase.PET_DATA.get(mid, {})
	if not pet_by_mid.is_empty():
		return str(pet_by_mid.get("element", "普通"))
	return "普通"

static func sorted_unique_map_elements(map_data: Dictionary) -> Array:
	var uniq: Dictionary = {}
	for entry in map_data.get("monsters", []):
		if entry is Dictionary:
			var el: String = element_from_map_monster_entry(entry)
			uniq[el] = true
	var result: Array = []
	for fe in GameDataRef.FIVE_ELEMENTS:
		if uniq.has(fe):
			result.append(fe)
	var others: Array = []
	for el in uniq:
		if not GameDataRef.FIVE_ELEMENTS.has(el):
			others.append(el)
	others.sort()
	result.append_array(others)
	return result


func get_drop_pet_id() -> String:
	if has_meta(EVENT_NO_CAPTURE_META) and bool(get_meta(EVENT_NO_CAPTURE_META)):
		return ""
	if not monster_id.is_empty():
		var pet_id = _get_pet_id(monster_id)
		if not pet_id.is_empty():
			return pet_id
		if GameDataRef.PET_DATA.has(monster_id):
			return monster_id
	return ""
