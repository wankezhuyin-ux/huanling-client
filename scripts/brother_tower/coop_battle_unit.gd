class_name CoopBattleUnit
extends RefCounted



var unit_type: String = "coop_player"
var display_name: String = ""
var hp: float = 1.0
var max_hp: float = 1.0
var attack: int = 1
var defense: int = 1
var agility: int = 1
var element: String = "普通"
var is_evolution_pet: bool = false
var pet_id: String = ""
var player_character_id: int = 0
var level: int = 1
var pet_data: Dictionary = {}

var noble_pet_damage_bonus: int = 0
var pet_soul_element_points: Dictionary = {}
var martial_arts_active: Array = []
var mp: float = 0.0
var max_mp: float = 100.0

var _battle_pet: Pet = null

func is_alive() -> bool:
	return hp > 0.0

func heal_full() -> void :
	hp = max_hp
	if unit_type == "coop_player":
		mp = max_mp
	elif unit_type == "coop_pet":
		var bp: = get_battle_pet()
		if bp != null:
			bp.hp = hp
			bp.max_hp = max_hp

func get_battle_pet() -> Pet:
	if unit_type != "coop_pet" or pet_data.is_empty():
		return null
	if _battle_pet == null or not is_instance_valid(_battle_pet):
		_battle_pet = Pet.new()
		_battle_pet.from_dict(pet_data.duplicate(true))

	_battle_pet.set_meta(Pet.BT_PET_SNAPSHOT_META, {
		"attack": float(attack), 
		"defense": float(defense), 
		"agility": float(agility), 
		"max_hp": float(max_hp), 
	})
	_battle_pet.hp = hp
	_battle_pet.max_hp = max_hp
	return _battle_pet

func sync_hp_from_battle_pet(battle_pet: Pet) -> void :
	if battle_pet == null:
		return
	hp = maxf(0.0, float(battle_pet.hp))

func has_battle_pet_skills() -> bool:
	return unit_type == "coop_pet" and not pet_data.is_empty()

func find_martial_by_effect(effect_type: String):
	var key: = str(effect_type).strip_edges()
	if key.is_empty():
		return null
	for raw in martial_arts_active:
		if raw is Dictionary and str(raw.get("effect_type", "")) == key:
			return MartialArtsManager.MartialArt.from_dict(raw)
	return null

func get_max_mp_value() -> int:
	return maxi(0, int(max_mp))

func get_current_mp_value() -> int:
	return maxi(0, int(mp))

func consume_mp_all() -> void :
	mp = 0.0

func heal_hp(amount: int) -> void :
	if amount <= 0:
		return
	hp = minf(max_hp, hp + float(amount))
	if unit_type == "coop_pet":
		var bp: = get_battle_pet()
		if bp != null:
			bp.hp = hp

static func from_player_snapshot(data: Dictionary) -> CoopBattleUnit:
	var u: = CoopBattleUnit.new()
	u.unit_type = "coop_player"
	u.display_name = str(data.get("player_name", data.get("name", "队友")))
	u.max_hp = float(data.get("final_max_hp", data.get("max_hp", data.get("hp", 100))))
	u.hp = u.max_hp
	u.attack = int(data.get("final_attack", data.get("attack", 10)))
	u.defense = int(data.get("final_defense", data.get("defense", 5)))
	u.agility = int(data.get("final_agility", data.get("agility", 5)))
	u.element = str(data.get("element", "普通"))
	u.player_character_id = int(data.get("player_character_id", 0))
	u.level = int(data.get("level", 1))
	u.max_mp = float(data.get("final_max_mp", data.get("max_mp", 100)))
	u.mp = u.max_mp
	var ma_raw = data.get("martial_arts_active", [])
	if ma_raw is Array:
		u.martial_arts_active = ma_raw.duplicate(true)
	return u

static func _normalize_soul_element(element: String) -> String:
	var e: = str(element).strip_edges()
	if e in ["金", "木", "水", "火", "土"]:
		return e
	return "金"

static func _soul_bonus_percent_from_points(points: Dictionary, element: String) -> int:
	var e: = _normalize_soul_element(element)
	var pts: = maxi(0, int(points.get(e, 0)))
	var bonus: = 0
	for p in range(1, 101):
		var need: = 10 * p * p
		if pts >= need:
			bonus = p
		else:
			break
	return bonus

static func _apply_collection_bonuses_to_unit(u: CoopBattleUnit, collection: Dictionary, noble_pct: int = 0) -> void :
	if u == null:
		return

	if u.unit_type != "coop_pet":
		return
	var noble_frac: = float(clampi(noble_pct, 0, 30)) / 100.0
	var coll: = collection if collection is Dictionary else {}
	var atk_pct: = maxf(0.0, float(coll.get("attack", 0))) + noble_frac
	if atk_pct > 0.0 and not u.pet_data.is_empty() and u.pet_data.has("attack"):
		var base_atk: = float(u.pet_data.get("attack", 0))
		if base_atk > 0.0:
			var boosted_atk: = int(base_atk * (1.0 + atk_pct))
			if boosted_atk > u.attack:
				u.attack = boosted_atk
	var def_pct: = maxf(0.0, float(coll.get("defense", 0))) + noble_frac
	if def_pct > 0.0 and not u.pet_data.is_empty() and u.pet_data.has("defense"):
		var base_def: = float(u.pet_data.get("defense", 0))
		if base_def > 0.0:
			var boosted_def: = int(base_def * (1.0 + def_pct))
			if boosted_def > u.defense:
				u.defense = boosted_def
	var agi_pct: = maxf(0.0, float(coll.get("agility", 0))) + noble_frac
	if agi_pct > 0.0 and not u.pet_data.is_empty() and u.pet_data.has("agility"):
		var base_agi: = float(u.pet_data.get("agility", 0))
		if base_agi > 0.0:
			var boosted_agi: = int(base_agi * (1.0 + agi_pct))
			if boosted_agi > u.agility:
				u.agility = boosted_agi
	var hp_pct: = maxf(0.0, float(coll.get("hp", 0)))
	if hp_pct > 0.0 and not u.pet_data.is_empty():
		var base_hp: = 0.0
		if u.pet_data.has("max_hp"):
			base_hp = float(u.pet_data.get("max_hp", 0))
		elif u.pet_data.has("hp"):
			base_hp = float(u.pet_data.get("hp", 0))
		if base_hp > 0.0:
			var boosted_hp: = maxf(1.0, base_hp * (1.0 + hp_pct))
			if boosted_hp > u.max_hp:
				u.max_hp = boosted_hp
				u.hp = u.max_hp

static func _apply_combat_bonuses_to_unit(u: CoopBattleUnit, snapshot: Dictionary) -> void :
	if u == null or snapshot.is_empty():
		return
	var raw = snapshot.get("combat_bonuses", {})
	if raw is Dictionary and not raw.is_empty():
		u.noble_pet_damage_bonus = clampi(int(raw.get("noble_pet_damage_bonus", 0)), 0, 30)
		var soul_raw = raw.get("pet_soul_element_points", {})
		if soul_raw is Dictionary:
			u.pet_soul_element_points = soul_raw.duplicate(true)
		var coll = raw.get("collection_bonuses", {})
		if not (coll is Dictionary):
			coll = {}
		_apply_collection_bonuses_to_unit(u, coll, u.noble_pet_damage_bonus)

func get_noble_pet_damage_bonus() -> int:
	return clampi(noble_pet_damage_bonus, 0, 30)

func get_pet_soul_bonus_percent(element: String) -> int:
	return _soul_bonus_percent_from_points(pet_soul_element_points, element)

static func from_pet_snapshot(data: Dictionary) -> CoopBattleUnit:
	var u: = CoopBattleUnit.new()
	u.unit_type = "coop_pet"
	u.pet_data = data.duplicate(true)
	u.display_name = str(data.get("pet_name", data.get("name", "队友宠")))
	u.max_hp = float(data.get("final_max_hp", data.get("max_hp", data.get("hp", 50))))
	u.hp = u.max_hp
	u.attack = int(data.get("final_attack", data.get("attack", 10)))
	u.defense = int(data.get("final_defense", data.get("defense", 5)))
	u.agility = int(data.get("final_agility", data.get("agility", 5)))
	u.element = str(data.get("element", "普通"))
	u.is_evolution_pet = bool(data.get("is_evolution_pet", false))
	u.pet_id = str(data.get("pet_id", ""))
	u.level = int(data.get("level", 1))
	return u

static func _resolve_pet_data_from_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.has("pet") and snapshot.get("pet") is Dictionary:
		var direct_pet: Dictionary = snapshot.get("pet", {})
		if not direct_pet.is_empty():
			return direct_pet
	if snapshot.has("active_pet") and snapshot.get("active_pet") is Dictionary:
		var active_pet_data: Dictionary = snapshot.get("active_pet", {})
		if not active_pet_data.is_empty():
			return active_pet_data
	if not snapshot.has("pets"):
		return {}
	var active_id: = str(snapshot.get("active_pet_id", snapshot.get("activePetId", ""))).strip_edges()
	var pets_raw = snapshot.get("pets")
	if pets_raw is Array:
		if not active_id.is_empty():
			for item in pets_raw:
				if item is Dictionary and str(item.get("id", "")) == active_id:
					return item
		if pets_raw.size() > 0 and pets_raw[0] is Dictionary:
			return pets_raw[0]
		return {}
	if pets_raw is Dictionary:
		var pets_container: Dictionary = pets_raw
		if pets_container.has("pets"):
			var inner_active: = str(pets_container.get("active_pet_id", active_id)).strip_edges()
			var pet_list = pets_container.get("pets")
			if pet_list is Array:
				if not inner_active.is_empty():
					for item in pet_list:
						if item is Dictionary and str(item.get("id", "")) == inner_active:
							return item
				if pet_list.size() > 0 and pet_list[0] is Dictionary:
					return pet_list[0]
			return {}
		if not active_id.is_empty() and pets_container.has(active_id):
			var by_id = pets_container.get(active_id)
			if by_id is Dictionary:
				return by_id
		for k in pets_container:
			var v = pets_container[k]
			if v is Dictionary and (v.has("pet_name") or v.has("pet_id") or v.has("attack")):
				return v
	return {}

static func build_from_session_snapshot(snapshot: Dictionary) -> Array:
	var out: Array = []
	if snapshot.is_empty():
		return out
	var player_raw = snapshot.get("player")
	if player_raw is Dictionary and not player_raw.is_empty():
		out.append(from_player_snapshot(player_raw))
	var pet_data: = _resolve_pet_data_from_snapshot(snapshot)
	if not pet_data.is_empty():
		out.append(from_pet_snapshot(pet_data))
	for u in out:
		if u is CoopBattleUnit:
			_apply_combat_bonuses_to_unit(u, snapshot)
	return out
