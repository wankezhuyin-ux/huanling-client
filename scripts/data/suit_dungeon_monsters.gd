class_name SuitDungeonMonsters
extends RefCounted

const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const SuitDatabaseDetailed = preload("res://scripts/data/suit_database_detailed.gd")
const PetDatabase = preload("res://scripts/pet_data_complete.gd")








const LEVEL_DESIGN_DATA = {
	1: {"base_attack": 645, "base_defense": 575, "base_hp": 1675, "boss_atk": 2270, "boss_def": 2024, "boss_hp": 5896, "boss_agi": 681, "pet_id": "guguai", "monster_id": "suit_guardian_1"}, 
	2: {"base_attack": 1171, "base_defense": 933, "base_hp": 4365, "boss_atk": 4121, "boss_def": 3284, "boss_hp": 15364, "boss_agi": 1236, "pet_id": "minixiang", "monster_id": "suit_guardian_2"}, 
	3: {"base_attack": 1800, "base_defense": 1250, "base_hp": 9500, "boss_atk": 6336, "boss_def": 4400, "boss_hp": 33440, "boss_agi": 1900, "pet_id": "ciluo", "monster_id": "suit_guardian_3"}, 
	4: {"base_attack": 2535, "base_defense": 1615, "base_hp": 15365, "boss_atk": 8923, "boss_def": 5684, "boss_hp": 54084, "boss_agi": 2676, "pet_id": "lieyanjun", "monster_id": "suit_guardian_4"}, 
	5: {"base_attack": 3925, "base_defense": 2315, "base_hp": 26365, "boss_atk": 13816, "boss_def": 8148, "boss_hp": 92804, "boss_agi": 4144, "pet_id": "wudi", "monster_id": "suit_guardian_5"}, 
	6: {"base_attack": 5835, "base_defense": 3265, "base_hp": 37365, "boss_atk": 20539, "boss_def": 11492, "boss_hp": 131524, "boss_agi": 6161, "pet_id": "xiaoleigong", "monster_id": "suit_guardian_6"}, 
	7: {"base_attack": 8475, "base_defense": 4585, "base_hp": 55700, "boss_atk": 29832, "boss_def": 16139, "boss_hp": 196064, "boss_agi": 8949, "pet_id": "huahua", "monster_id": "suit_guardian_7"}, 
	8: {"base_attack": 11995, "base_defense": 6345, "base_hp": 74035, "boss_atk": 42222, "boss_def": 22334, "boss_hp": 260603, "boss_agi": 12666, "pet_id": "huopozai", "monster_id": "suit_guardian_8"}, 
	9: {"base_attack": 15365, "base_defense": 8035, "base_hp": 99700, "boss_atk": 54084, "boss_def": 28283, "boss_hp": 350944, "boss_agi": 16225, "pet_id": "bianyianu", "monster_id": "suit_guardian_9"}, 
	10: {"base_attack": 18300, "base_defense": 9500, "base_hp": 125365, "boss_atk": 64416, "boss_def": 33440, "boss_hp": 441284, "boss_agi": 19324, "pet_id": "jin_jia_yi", "monster_id": "suit_guardian_10"}, 
	11: {"base_attack": 74748, "base_defense": 10965, "base_hp": 147365, "boss_atk": 74748, "boss_def": 38596, "boss_hp": 518724, "boss_agi": 22424, "pet_id": "haha", "monster_id": "suit_guardian_11"}, 
	12: {"base_attack": 82651, "base_defense": 12800, "base_hp": 173035, "boss_atk": 82651, "boss_def": 45056, "boss_hp": 609083, "boss_agi": 24795, "pet_id": "diandian", "monster_id": "suit_guardian_12"}, 
	13: {"base_attack": 90554, "base_defense": 14635, "base_hp": 198700, "boss_atk": 90554, "boss_def": 51515, "boss_hp": 699424, "boss_agi": 27166, "pet_id": "lijian", "monster_id": "suit_guardian_13"}, 
	14: {"base_attack": 98457, "base_defense": 16100, "base_hp": 220700, "boss_atk": 98457, "boss_def": 56672, "boss_hp": 776864, "boss_agi": 29537, "pet_id": "shandianbaobao", "monster_id": "suit_guardian_14"}, 
	15: {"base_attack": 106361, "base_defense": 17935, "base_hp": 257365, "boss_atk": 106361, "boss_def": 63131, "boss_hp": 905924, "boss_agi": 31908, "pet_id": "fudie", "monster_id": "suit_guardian_15"}, 
	16: {"base_attack": 114264, "base_defense": 20500, "base_hp": 294035, "boss_atk": 114264, "boss_def": 72160, "boss_hp": 1035003, "boss_agi": 34279, "pet_id": "xiaoleishen", "monster_id": "suit_guardian_16"}, 
	17: {"base_attack": 122167, "base_defense": 22700, "base_hp": 330700, "boss_atk": 122167, "boss_def": 79904, "boss_hp": 1164064, "boss_agi": 36650, "pet_id": "biaoshi", "monster_id": "suit_guardian_17"}, 
	18: {"base_attack": 130071, "base_defense": 25265, "base_hp": 367365, "boss_atk": 130071, "boss_def": 88932, "boss_hp": 1293124, "boss_agi": 39021, "pet_id": "paopaotun", "monster_id": "suit_guardian_18"}, 
	19: {"base_attack": 137974, "base_defense": 27835, "base_hp": 404035, "boss_atk": 137974, "boss_def": 97979, "boss_hp": 1422203, "boss_agi": 41392, "pet_id": "dianqiubaobao", "monster_id": "suit_guardian_19"}, 
	20: {"base_attack": 145877, "base_defense": 31500, "base_hp": 440700, "boss_atk": 145877, "boss_def": 110880, "boss_hp": 1551264, "boss_agi": 43763, "pet_id": "chongbeibei", "monster_id": "suit_guardian_20"}, 
	21: {"base_attack": 153781, "base_defense": 37000, "base_hp": 510000, "boss_atk": 153781, "boss_def": 130240, "boss_hp": 1795200, "boss_agi": 46134, "pet_id": "hongdazui", "monster_id": "suit_guardian_21"}, 
}


const WAVE_MULTIPLIERS = {
	1: 1.0, 
	2: 1.15, 
	3: 1.32, 
	4: 1.52, 
	5: 1.75, 
	6: 2.01, 
	7: 2.31, 
	8: 2.66, 
	9: 3.06, 
	10: 3.52
}


const SUIT_1_10_NONBOSS_TO_BOSS_SCALE: float = 0.32
const SUIT_11P_NONBOSS_TO_BOSS_SCALE: float = 0.32
const SUIT_NONBOSS_WAVE_MONSTER_COUNT: int = 3


const MONSTER_TEXTURES = {
	"suit_guardian_1": "res://assets/pets/guguai.png", 
	"suit_guardian_2": "res://assets/pets/minixiang.png", 
	"suit_guardian_3": "res://assets/pets/ciluo.png", 
	"suit_guardian_4": "res://assets/pets/lieyanjun.png", 
	"suit_guardian_5": "res://assets/pets/wudi.png", 
	"suit_guardian_6": "res://assets/pets/xiaoleigong.png", 
	"suit_guardian_7": "res://assets/pets/huahua.png", 
	"suit_guardian_8": "res://assets/pets/huopozai.png", 
	"suit_guardian_9": "res://assets/pets/bianyianu.png", 
	"suit_guardian_10": "res://assets/pets/jin_jia_yi.png", 
	"suit_guardian_11": "res://assets/pets/haha.png", 
	"suit_guardian_12": "res://assets/pets/diandian.png", 
	"suit_guardian_13": "res://assets/pets/lijian.png", 
	"suit_guardian_14": "res://assets/pets/shandianbaobao.png", 
	"suit_guardian_15": "res://assets/pets/fudie.png", 
	"suit_guardian_16": "res://assets/pets/xiaoleishen.png", 
	"suit_guardian_17": "res://assets/pets/biaoshi.png", 
	"suit_guardian_18": "res://assets/pets/paopaotun.png", 
	"suit_guardian_19": "res://assets/pets/dianqiubaobao.png", 
	"suit_guardian_20": "res://assets/pets/chongbeibei.png", 
	"suit_guardian_21": "res://assets/pets/hongdazui.png"
}


static var _generated_monsters: Dictionary = {}


static func get_wave_monsters(level: int, wave: int) -> Array:
	var cache_key = "suit_el_v8_%d_wave_%d" % [level, wave]

	if _generated_monsters.has(cache_key):
		return _generated_monsters[cache_key].duplicate(true)

	var design_data = LEVEL_DESIGN_DATA.get(level, {})
	if design_data.is_empty():
		push_warning("未找到第%d层的怪物设计数据" % level)
		return []

	var is_boss = (wave == 10)

	var design_pet_id: String = str(design_data.get("pet_id", "")).strip_edges()
	var pet_info: Dictionary = PetDatabase.PET_DATA.get(design_pet_id, {})
	var monster_name: String = str(pet_info.get("name", "未知"))

	var element: String = str(SuitDatabaseDetailed.get_suit_data(level).get("dungeon_element", "无"))
	var pet_el: String = str(pet_info.get("element", ""))
	if not pet_el.is_empty() and pet_el != element and element != "无":
		push_warning("SuitDungeonMonsters L%d: 宠物库五行 %s 与副本层 dungeon_element %s 不一致" % [level, pet_el, element])
	var monster_id = str(design_data.get("monster_id", ""))

	var ref_atk: int
	var ref_agi: int
	var ref_def: int
	var ref_hp: int
	if design_data.has("boss_atk") and design_data.has("boss_def") and design_data.has("boss_hp") and design_data.has("boss_agi"):
		ref_atk = int(design_data["boss_atk"])
		ref_def = int(design_data["boss_def"])
		ref_hp = int(design_data["boss_hp"])
		ref_agi = int(design_data["boss_agi"])
	else:

		var boss_mult: float = WAVE_MULTIPLIERS[10]
		var base_attack: int = int(design_data["base_attack"])
		var base_defense: int = int(design_data["base_defense"])
		var base_hp: int = int(design_data["base_hp"])
		if level >= 11:
			ref_atk = base_attack
			ref_agi = int(float(base_attack) * 0.3)
		else:
			ref_atk = int(float(base_attack) * boss_mult)
			ref_agi = int(float(base_attack) * boss_mult * 0.3)
		ref_def = int(float(base_defense) * boss_mult)
		ref_hp = int(float(base_hp) * boss_mult)

	var is_evo_pet: = true
	if not design_pet_id.is_empty():
		is_evo_pet = EvolutionDataClass.is_evolution_pet(design_pet_id)
	if is_evo_pet:
		push_error("SuitDungeonMonsters: pet_id=%s 为可进化宠，套装副本应使用不可进化宠，五行伤害会按 30%% 生克" % design_pet_id)

	var tx_path: String = MONSTER_TEXTURES.get(monster_id, "res://assets/pets/%s.png" % design_pet_id)

	var monsters: Array = []
	var monster_count = 3 if not is_boss else 1

	for i in range(monster_count):
		var out_attack: int
		var out_defense: int
		var out_hp: int
		var out_agility: int
		if is_boss:
			out_attack = ref_atk
			out_defense = ref_def
			out_hp = ref_hp
			out_agility = ref_agi
		else:
			var g_wave: float = 0.1 + 0.9 * float(wave - 1) / 8.0
			var to_boss: float
			if level <= 10:
				to_boss = SUIT_1_10_NONBOSS_TO_BOSS_SCALE
			else:
				to_boss = SUIT_11P_NONBOSS_TO_BOSS_SCALE
			var s_split: float = g_wave * to_boss / float(SUIT_NONBOSS_WAVE_MONSTER_COUNT)
			out_attack = maxi(1, int(float(ref_atk) * s_split))
			out_defense = maxi(1, int(float(ref_def) * s_split))
			out_hp = maxi(1, int(float(ref_hp) * s_split))
			out_agility = maxi(1, int(float(ref_agi) * s_split))
		var monster: Dictionary = {
			"name": monster_name + ("(BOSS)" if is_boss else ""), 
			"monster_id": monster_id, 
			"pet_id": design_pet_id, 
			"element": element, 
			"level": level * 100 + wave * 10, 
			"hp": out_hp, 
			"max_hp": out_hp, 
			"attack": out_attack, 
			"defense": out_defense, 
			"agility": out_agility, 
			"texture": tx_path, 
			"monster_name": monster_name + ("(BOSS)" if is_boss else ""), 
			"is_boss": is_boss, 
			"is_evolution_pet": is_evo_pet
		}
		monsters.append(monster)

	_generated_monsters[cache_key] = monsters.duplicate(true)

	return monsters


static func get_level_monsters(level: int) -> Array:
	var all_monsters: Array = []
	for w in range(1, 11):
		var wave_monsters: Array = get_wave_monsters(level, w)
		all_monsters.append_array(wave_monsters)
	return all_monsters


static func get_monster_texture(monster_id: String) -> String:
	return MONSTER_TEXTURES.get(monster_id, "")


static func clear_cache() -> void :
	_generated_monsters.clear()
