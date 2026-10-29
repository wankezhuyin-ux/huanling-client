class_name BrotherTowerManager
extends RefCounted

const CoopBattleUnit = preload("res://scripts/brother_tower/coop_battle_unit.gd")
const Player = preload("res://scripts/player.gd")
const Pet = preload("res://scripts/pet.gd")
const Monster = preload("res://scripts/monster.gd")
const MonsterGenerator = preload("res://scripts/monster_generator.gd")
const GameData = preload("res://scripts/game_data.gd")
const PetDatabase = preload("res://scripts/pet_data_complete.gd")

const WAVE_COUNT: = 50
const MONSTERS_PER_WAVE: = 8
const LEVEL_START: = 5100
const LEVEL_END: = 10000
const BATTLE_MAX_ROUNDS: = 30
const DIFFICULTY_EASY: = "easy"
const DIFFICULTY_HARD: = "hard"
const DIFFICULTY_HELL: = "hell"
const DIFFICULTY_EPIC: = "epic"

const DIFFICULTY_PRESETS: = {
	DIFFICULTY_EASY: {"label": "简单", "levelStart": 5100, "levelEnd": 10000, "giftCount": 1, "friendshipGain": 4}, 
	DIFFICULTY_HARD: {"label": "困难", "levelStart": 15100, "levelEnd": 20000, "giftCount": 2, "friendshipGain": 5}, 
	DIFFICULTY_HELL: {"label": "地狱", "levelStart": 25100, "levelEnd": 30000, "giftCount": 3, "friendshipGain": 5}, 
	DIFFICULTY_EPIC: {"label": "史诗", "levelStart": 35200, "levelEnd": 40000, "giftCount": 4, "friendshipGain": 6}, 
}

static func _runtime_cfg(game_manager = null) -> Dictionary:
	if game_manager != null and game_manager.has_method("get_brother_tower_runtime_config"):
		var cfg: Variant = game_manager.get_brother_tower_runtime_config()
		if cfg is Dictionary and not cfg.is_empty():
			return cfg
	return {}

static func _difficulty_row_from_cfg(cfg: Dictionary, difficulty: String) -> Dictionary:
	var key: = str(difficulty).strip_edges().to_lower()
	var diffs: Variant = cfg.get("difficulties", [])
	if diffs is Array:
		for row in diffs:
			if row is Dictionary and str(row.get("id", "")) == key:
				return row
	return DIFFICULTY_PRESETS.get(key, DIFFICULTY_PRESETS[DIFFICULTY_EASY])

static func list_difficulties(game_manager = null) -> Array:
	var cfg: = _runtime_cfg(game_manager)
	var out: Array = []
	var diffs: Variant = cfg.get("difficulties", [])
	if diffs is Array:
		for row in diffs:
			if not (row is Dictionary):
				continue
			var did: = str(row.get("id", "")).strip_edges().to_lower()
			if did.is_empty():
				continue
			out.append(row)
	if out.is_empty():
		for k in DIFFICULTY_PRESETS.keys():
			var preset: Dictionary = DIFFICULTY_PRESETS[k].duplicate()
			preset["id"] = k
			out.append(preset)
	return out

static func normalize_difficulty(value, game_manager = null) -> String:
	var key: = str(value).strip_edges().to_lower()
	for row in list_difficulties(game_manager):
		if str(row.get("id", "")) == key:
			return key
	if DIFFICULTY_PRESETS.has(key):
		return key
	return DIFFICULTY_EASY

static func wave_count(game_manager = null) -> int:
	var cfg: = _runtime_cfg(game_manager)
	var wc: = int(cfg.get("waveCount", 0))
	return WAVE_COUNT if wc <= 0 else maxi(1, wc)

static func monsters_per_wave(game_manager = null) -> int:
	var cfg: = _runtime_cfg(game_manager)
	var n: = int(cfg.get("monstersPerWave", 0))
	return MONSTERS_PER_WAVE if n <= 0 else maxi(1, n)

static func battle_max_rounds(game_manager = null) -> int:
	var cfg: = _runtime_cfg(game_manager)
	var n: = int(cfg.get("battleMaxRounds", 0))
	return BATTLE_MAX_ROUNDS if n <= 0 else maxi(1, n)

static func get_difficulty_preset(difficulty: String, game_manager = null) -> Dictionary:
	var cfg: = _runtime_cfg(game_manager)
	if not cfg.is_empty():
		return _difficulty_row_from_cfg(cfg, difficulty)
	return DIFFICULTY_PRESETS.get(normalize_difficulty(difficulty), DIFFICULTY_PRESETS[DIFFICULTY_EASY])

static func difficulty_label(difficulty: String, game_manager = null) -> String:
	return str(get_difficulty_preset(difficulty, game_manager).get("label", "简单"))

static func difficulty_level_range_text(difficulty: String, game_manager = null) -> String:
	var preset: = get_difficulty_preset(difficulty, game_manager)
	return "%d → %d" % [int(preset.get("levelStart", LEVEL_START)), int(preset.get("levelEnd", LEVEL_END))]

static func wave_level(wave: int, level_start: int = LEVEL_START, level_end: int = LEVEL_END, wave_count_val: int = -1) -> int:
	var w: = maxi(1, wave)
	var wc: = WAVE_COUNT if wave_count_val <= 0 else maxi(1, wave_count_val)
	if wc <= 1:
		return level_end
	return level_start + int((level_end - level_start) * float(w - 1) / float(wc - 1))

static func wave_level_for_difficulty(wave: int, difficulty: String, game_manager = null) -> int:
	var preset: = get_difficulty_preset(difficulty, game_manager)
	return wave_level(
		wave, 
		int(preset.get("levelStart", LEVEL_START)), 
		int(preset.get("levelEnd", LEVEL_END)), 
		wave_count(game_manager)
	)

static func build_pet_pool(pet_manager) -> Array:
	var pool: Array = []
	if pet_manager == null:
		return pool
	for pet_id in GameData.PET_DATA:
		var pid: = str(pet_id)
		if pet_manager.is_event_limited_pet_id(pid):
			continue
		if not PetDatabase.PET_DATA.has(pid):
			continue
		pool.append(pid)
	return pool

static func _generate_wave_monsters(pool: Array, rng: RandomNumberGenerator, wave: int, difficulty: String = DIFFICULTY_EASY, game_manager = null) -> Array:
	var lvl: = wave_level_for_difficulty(wave, difficulty, game_manager)
	var wave_monsters: Array = []
	for _i in range(monsters_per_wave(game_manager)):
		var gen: Dictionary = {}
		for _attempt in range(8):
			var pet_id: String = pool[rng.randi_range(0, pool.size() - 1)]
			gen = MonsterGenerator.generate_monster(pet_id, lvl)
			if not gen.is_empty():
				break
		if gen.is_empty():
			continue
		gen["exp_reward"] = 0
		gen["gold_reward"] = 0
		wave_monsters.append(Monster.create_from_template(gen))
	return wave_monsters

static func build_wave(pet_manager, battle_seed: int, wave: int, difficulty: String = DIFFICULTY_EASY, game_manager = null) -> Array:
	var wc: = wave_count(game_manager)
	if wave < 1 or wave > wc:
		return []
	var pool: = build_pet_pool(pet_manager)
	if pool.is_empty():
		return []
	var rng: = RandomNumberGenerator.new()
	rng.seed = battle_seed
	for w in range(1, wave + 1):
		var wave_monsters: = _generate_wave_monsters(pool, rng, w, difficulty, game_manager)
		if wave_monsters.is_empty():
			return []
		if w == wave:
			return wave_monsters
	return []

static func build_all_waves(pet_manager, battle_seed: int, difficulty: String = DIFFICULTY_EASY, game_manager = null) -> Array:
	var pool: = build_pet_pool(pet_manager)
	if pool.is_empty():
		return []
	var rng: = RandomNumberGenerator.new()
	rng.seed = battle_seed
	var all_waves: Array = []
	var wc: = wave_count(game_manager)
	for w in range(1, wc + 1):
		var wave_monsters: = _generate_wave_monsters(pool, rng, w, difficulty, game_manager)
		if wave_monsters.is_empty():
			push_error("兄弟天关：第%d波怪物生成失败" % w)
			return []
		all_waves.append(wave_monsters)
	return all_waves

static func build_combat_bonuses(game_manager) -> Dictionary:
	var out: = {
		"noble_pet_damage_bonus": 0, 
		"collection_bonuses": {"attack": 0.0, "defense": 0.0, "agility": 0.0, "hp": 0.0}, 
		"pet_soul_element_points": {"金": 0, "木": 0, "水": 0, "火": 0, "土": 0}, 
	}
	if game_manager == null:
		return out
	out["noble_pet_damage_bonus"] = clampi(int(game_manager.noble_pet_damage_bonus), 0, 30)
	if game_manager.pet_collection_manager:
		var bonuses = game_manager.pet_collection_manager.get_total_bonuses()
		if bonuses is Dictionary:
			out["collection_bonuses"] = bonuses.duplicate(true)
	if game_manager.pet_soul_manager:
		var soul_data = game_manager.pet_soul_manager.to_dict()
		if soul_data is Dictionary:
			var points = soul_data.get("element_points", {})
			if points is Dictionary:
				out["pet_soul_element_points"] = points.duplicate(true)
	return out

static func build_local_snapshot(game_manager) -> Dictionary:
	if game_manager == null or game_manager.player == null:
		return {}
	var pdict: Dictionary = game_manager.player.to_dict()
	pdict["element"] = FabaoStatBonus.wild_player_element("普通")
	var active_arts: Array = []
	if game_manager.martial_arts_manager:

		for art in game_manager.martial_arts_manager.get_equipped_arts():
			if art != null:
				active_arts.append(art.to_dict())
	if active_arts.is_empty():
		var cached = pdict.get("martial_arts_active", [])
		if cached is Array:
			for raw in cached:
				if raw is Dictionary:
					active_arts.append(raw.duplicate(true))
	if not active_arts.is_empty():
		pdict["martial_arts_active"] = active_arts
	var snap: = {"player": pdict}
	var pet = game_manager.pet_manager.get_active_pet() if game_manager.pet_manager else null
	if pet:
		snap["pet"] = pet.to_dict()
	snap["combat_bonuses"] = build_combat_bonuses(game_manager)
	return snap

static func _log_coop_player_martial(uid: int, u: CoopBattleUnit) -> void :
	var has_triple: = false
	var has_acupoint: = false
	for raw in u.martial_arts_active:
		if raw is Dictionary:
			var effect_type: = str(raw.get("effect_type", ""))
			if effect_type == "triple_shot":
				has_triple = true
			elif effect_type == "acupoint_seal":
				has_acupoint = true
	print(
		"[BrotherTower] coop uid=%d player atk=%d martial=%d triple_shot=%s acupoint_seal=%s"
		%[uid, u.attack, u.martial_arts_active.size(), has_triple, has_acupoint]
	)

static func find_member_snapshot(session_members: Array, user_id: int) -> Dictionary:
	if session_members.is_empty() or user_id <= 0:
		return {}
	for entry in session_members:
		if not entry is Dictionary:
			continue
		var uid: = int(entry.get("userId", entry.get("user_id", -1)))
		if uid != user_id:
			continue
		var snapshot: Dictionary = entry.get("snapshot", {})
		return snapshot if snapshot is Dictionary else {}
	return {}

static func build_battle_pet_from_snapshot(snapshot: Dictionary) -> Pet:
	if snapshot.is_empty():
		return null
	var pet_data: Dictionary = CoopBattleUnit._resolve_pet_data_from_snapshot(snapshot)
	if pet_data.is_empty():
		return null
	var pet: = Pet.new()
	pet.from_dict(pet_data.duplicate(true))
	_apply_bt_snapshot_stats_to_pet(pet, pet_data, snapshot)
	return pet


static func _apply_bt_snapshot_stats_to_pet(p: Pet, pdata: Dictionary, snapshot: Dictionary = {}) -> void :
	if p == null or pdata.is_empty():
		return

	var atk: = _bt_pet_stat_from_pdata(pdata, "final_attack", "attack", 10.0)
	var def: = _bt_pet_stat_from_pdata(pdata, "final_defense", "defense", 5.0)
	var agi: = _bt_pet_stat_from_pdata(pdata, "final_agility", "agility", 5.0)
	var mhp: = _bt_pet_stat_from_pdata(pdata, "final_max_hp", "max_hp", 50.0)
	if mhp <= 0.0 and pdata.has("hp"):
		mhp = maxf(1.0, float(pdata.get("hp", 50)))

	var bonuses_raw = snapshot.get("combat_bonuses", {}) if snapshot is Dictionary else {}
	if bonuses_raw is Dictionary:
		var coll = bonuses_raw.get("collection_bonuses", {})
		if not (coll is Dictionary):
			coll = {}
		var noble_frac: = float(clampi(int(bonuses_raw.get("noble_pet_damage_bonus", 0)), 0, 30)) / 100.0
		var atk_pct: = maxf(0.0, float(coll.get("attack", 0))) + noble_frac
		var def_pct: = maxf(0.0, float(coll.get("defense", 0))) + noble_frac
		var agi_pct: = maxf(0.0, float(coll.get("agility", 0))) + noble_frac
		var hp_pct: = maxf(0.0, float(coll.get("hp", 0)))
		if atk_pct > 0.0 and pdata.has("attack"):
			var base_atk: = float(pdata.get("attack", 0))
			if base_atk > 0.0:
				atk = maxf(atk, base_atk * (1.0 + atk_pct))
		if def_pct > 0.0 and pdata.has("defense"):
			var base_def: = float(pdata.get("defense", 0))
			if base_def > 0.0:
				def = maxf(def, base_def * (1.0 + def_pct))
		if agi_pct > 0.0 and pdata.has("agility"):
			var base_agi: = float(pdata.get("agility", 0))
			if base_agi > 0.0:
				agi = maxf(agi, base_agi * (1.0 + agi_pct))
		if hp_pct > 0.0:
			var base_hp: = 0.0
			if pdata.has("max_hp"):
				base_hp = float(pdata.get("max_hp", 0))
			elif pdata.has("hp"):
				base_hp = float(pdata.get("hp", 0))
			if base_hp > 0.0:
				mhp = maxf(mhp, base_hp * (1.0 + hp_pct))
	var stats: = {
		"attack": atk, 
		"defense": def, 
		"agility": agi, 
		"max_hp": mhp, 
	}
	p.set_meta(Pet.BT_PET_SNAPSHOT_META, stats)
	p.max_hp = mhp
	if p.hp > mhp:
		p.hp = mhp

static func _bt_pet_stat_from_pdata(pdata: Dictionary, final_key: String, base_key: String, fallback: float) -> float:
	if pdata.has(final_key):
		var fv: = float(pdata.get(final_key, 0))
		if fv > 0.0:
			return fv
	if pdata.has(base_key):
		var bv: = float(pdata.get(base_key, 0))
		if bv > 0.0:
			return bv
	push_warning("[BrotherTower] pet snapshot missing %s/%s, fallback=%.0f" % [final_key, base_key, fallback])
	return fallback

static func _apply_bt_snapshot_stats_to_player(p: Player, pdata: Dictionary) -> void :
	if p == null or pdata.is_empty():
		return
	var stats: = {
		"attack": int(pdata.get("final_attack", pdata.get("attack", 10))), 
		"defense": int(pdata.get("final_defense", pdata.get("defense", 5))), 
		"agility": int(pdata.get("final_agility", pdata.get("agility", 5))), 
		"max_hp": int(pdata.get("final_max_hp", pdata.get("max_hp", 100))), 
		"max_mp": int(pdata.get("final_max_mp", pdata.get("max_mp", 100))), 
	}
	p.set_meta("bt_snapshot_stats", stats)

static func build_battle_player_from_snapshot(snapshot: Dictionary) -> Player:
	if snapshot.is_empty():
		return null
	var player_raw = snapshot.get("player")
	if not player_raw is Dictionary or player_raw.is_empty():
		return null
	var pdata: Dictionary = player_raw.duplicate(true)
	var battle_player: = Player.new()
	battle_player.from_dict(pdata)
	_apply_bt_snapshot_stats_to_player(battle_player, pdata)
	return battle_player

static func resolve_coop_units(game_manager, session_members: Array, local_user_id: int) -> Array:
	var units: Array = []
	if session_members.is_empty():
		return units
	for entry in session_members:
		if not entry is Dictionary:
			continue
		var uid: = int(entry.get("userId", entry.get("user_id", -1)))
		if uid == local_user_id:
			continue
		var snapshot: Dictionary = entry.get("snapshot", {})
		if snapshot.is_empty():
			continue
		for u in CoopBattleUnit.build_from_session_snapshot(snapshot):
			if u is CoopBattleUnit:
				if u.unit_type == "coop_pet":
					print("[BrotherTower] coop uid=%d pet atk=%d noble=+%d%%" % [uid, u.attack, u.get_noble_pet_damage_bonus()])
				elif u.unit_type == "coop_player":
					_log_coop_player_martial(uid, u)
			units.append(u)
	return units

static func apply_coop_units_to_battle(game_manager, coop_units: Array) -> void :
	if game_manager == null or game_manager.battle_system == null:
		return
	if game_manager.battle_system.has_method("set_coop_units"):
		game_manager.battle_system.set_coop_units(coop_units)
	else:
		game_manager.battle_system.coop_units = coop_units

static func clear_coop_units(game_manager) -> void :
	if game_manager == null or game_manager.battle_system == null:
		return
	if game_manager.battle_system.has_method("clear_coop_units"):
		game_manager.battle_system.clear_coop_units()
	else:
		game_manager.battle_system.coop_units = []

static func heal_all_battle_allies(game_manager) -> void :
	if game_manager == null:
		return
	if game_manager.is_brother_tower_battle and game_manager.battle_system and game_manager.battle_system.player:
		game_manager.battle_system.player.heal_full()
	elif not game_manager.is_brother_tower_battle and game_manager.player:
		game_manager.player.heal_full()
	var battle_pet: Pet = null
	if game_manager.is_brother_tower_battle and game_manager.battle_system:
		battle_pet = game_manager.battle_system.active_pet
	if battle_pet:
		battle_pet.heal_full()
	else:
		var active_pet = game_manager.pet_manager.get_active_pet() if game_manager.pet_manager else null
		if active_pet:
			active_pet.heal_full()
	if game_manager.battle_system == null:
		return
	for u in game_manager.battle_system.coop_units:
		if u == null:
			continue
		if u.has_method("heal_full"):
			u.heal_full()
		else:
			u.hp = u.max_hp

static func format_clear_broadcast_message(content: String, broadcast_row: Dictionary = {}, game_manager = null) -> String:
	var msg: = str(content).strip_edges()
	if msg.is_empty():
		return msg
	var wc: = wave_count(game_manager)
	if msg.contains("\n") and msg.contains("【"):
		return msg
	var names: Array = []
	var extra_raw = broadcast_row.get("extra_data", broadcast_row.get("extraData", null))
	if extra_raw is Dictionary:
		var arr = extra_raw.get("playerNames", [])
		if arr is Array:
			names = arr
	elif extra_raw is String and not extra_raw.is_empty():
		var parsed = JSON.parse_string(extra_raw)
		if parsed is Dictionary:
			var arr2 = parsed.get("playerNames", [])
			if arr2 is Array:
				names = arr2
	if names.size() >= 2:
		return "情比金坚，风雨同舟！\n恭喜【%s】与【%s】经过一番苦战联手通关兄弟天关%d层！" % [str(names[0]).strip_edges(), str(names[1]).strip_edges(), wc]
	var body: = msg
	if body.begins_with("情比金坚，风雨同舟！"):
		body = body.substr("情比金坚，风雨同舟！".length()).strip_edges()
	var regex: = RegEx.new()
	if regex.compile("恭喜(.+?)与(.+?)经过一番苦战联手通关兄弟天关(\\d+)层!?") == OK:
		var m = regex.search(body)
		if m:
			return "情比金坚，风雨同舟！\n恭喜【%s】与【%s】经过一番苦战联手通关兄弟天关%d层！" % [m.get_string(1).strip_edges(), m.get_string(2).strip_edges(), wc]
	return msg
