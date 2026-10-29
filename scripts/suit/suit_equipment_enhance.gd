extends RefCounted
class_name SuitEquipmentEnhance

const STONE_ITEM: = "套装强化石"
const MAX_LEVEL: = 9
const STONE_COST: = 1
const PENDING_EXPIRE_SEC: = 600


const SET_BONUS_EXTRA_BY_MIN_LEVEL: = [
	0.0, 
	0.01, 
	0.034, 
	0.058, 
	0.081, 
	0.105, 
	0.129, 
	0.153, 
	0.176, 
	0.2, 
]

const BASE_SET_BONUS_PERCENT: = 0.3

static func stone_cost_for_next_level(_current_level: int) -> int:
	return STONE_COST

static func success_rate_for_next_level(current_level: int) -> float:
	if current_level < 0 or current_level >= MAX_LEVEL:
		return 0.0
	var lv: = float(current_level)
	return maxf(0.0, 1.0 - (0.9 * lv) / 8.0)

static func roll_boost_percent() -> float:
	return randf_range(0.01, 0.09)

static func boosted_stats_from_current(stats: Dictionary, boost: float) -> Dictionary:
	var out: = {
		"attack": int(stats.get("attack", 0)), 
		"defense": int(stats.get("defense", 0)), 
		"agility": int(stats.get("agility", 0)), 
		"hp": int(stats.get("hp", 0)), 
		"mp": int(stats.get("mp", 0)), 
	}
	var mult: = 1.0 + float(boost)
	for key in out.keys():
		var v: = int(out[key])
		if v > 0:
			out[key] = int(round(float(v) * mult))
	return out

static func set_bonus_extra_percent(min_level: int) -> float:
	var lv: = clampi(min_level, 0, MAX_LEVEL)
	return float(SET_BONUS_EXTRA_BY_MIN_LEVEL[lv])

static func total_set_bonus_percent(min_level: int) -> float:
	return BASE_SET_BONUS_PERCENT + set_bonus_extra_percent(min_level)

static func format_display_name(base_name: String, level: int) -> String:
	var lv: = clampi(level, 0, MAX_LEVEL)
	var n: = str(base_name).strip_edges()
	if lv <= 0:
		return n
	return "%s+%d" % [n, lv]

static func get_level_from_dict(d: Dictionary) -> int:
	return clampi(int(d.get("suit_enhance_level", 0)), 0, MAX_LEVEL)

static func get_level_from_equipment(eq) -> int:
	if eq == null:
		return 0
	if eq is Dictionary:
		return get_level_from_dict(eq)
	if "suit_enhance_level" in eq:
		return clampi(int(eq.suit_enhance_level), 0, MAX_LEVEL)
	return 0

static func stats_dict_from_equipment(eq) -> Dictionary:
	if eq is Dictionary:
		return {
			"attack": int(eq.get("attack", 0)), 
			"defense": int(eq.get("defense", 0)), 
			"agility": int(eq.get("agility", 0)), 
			"hp": int(eq.get("hp", 0)), 
			"mp": int(eq.get("mp", 0)), 
		}
	if eq != null:
		return {
			"attack": int(eq.attack), 
			"defense": int(eq.defense), 
			"agility": int(eq.agility), 
			"hp": int(eq.hp), 
			"mp": int(eq.mp), 
		}
	return {"attack": 0, "defense": 0, "agility": 0, "hp": 0, "mp": 0}

static func unseal_roll_cap(base: int) -> int:
	if base <= 0:
		return 0
	return int(floor(float(base) * float(SuitDatabaseDetailed.STAT_VARIATION.max)))

static func _eq_bool(eq, key: String) -> bool:
	if eq == null:
		return false
	if eq is Dictionary:
		return bool(eq.get(key, false))
	return bool(eq.get(key)) if eq is Object and key in eq else false

static func _eq_int(eq, key: String) -> int:
	if eq == null:
		return 0
	if eq is Dictionary:
		return int(eq.get(key, 0))
	if eq is Object and key in eq:
		return int(eq.get(key))
	return 0

static func _eq_str(eq, key: String) -> String:
	if eq == null:
		return ""
	if eq is Dictionary:
		return str(eq.get(key, "")).strip_edges()
	if eq is Object and key in eq:
		return str(eq.get(key)).strip_edges()
	return ""

static func caps_for_unenhanced_suit(eq) -> Dictionary:
	var empty: Dictionary = {}
	if eq == null:
		return empty
	if get_level_from_equipment(eq) > 0:
		return empty
	if _eq_bool(eq, "is_sealed"):
		return empty
	var is_suit: = _eq_bool(eq, "is_suit")
	if not is_suit and str(_eq_str(eq, "rarity")).to_lower() != "suit":
		return empty
	var suit_level: = _eq_int(eq, "suit_id")
	if suit_level <= 0:
		suit_level = _eq_int(eq, "suit_level")
	var slot: = _eq_str(eq, "suit_slot")
	if slot.is_empty():
		slot = _eq_str(eq, "slot")
	if suit_level <= 0 or slot.is_empty():
		return empty
	var piece: Dictionary = SuitDatabaseDetailed.get_piece_stats(suit_level, slot)
	var out: Dictionary = {}
	for key in ["attack", "defense", "agility", "hp", "mp"]:
		var cap: = unseal_roll_cap(int(piece.get(key, 0)))
		if cap > 0:
			out[key] = cap
	return out

static func format_stat_with_cap(label: String, current: int, cap: int = 0) -> String:
	if current <= 0:
		return ""
	if cap > 0:
		return "%s+%d（上限%d）" % [label, current, maxi(cap, current)]
	return "%s+%d" % [label, current]

static func format_stats_line(stats: Dictionary, caps: Dictionary = {}) -> String:
	var parts: Array[String] = []
	var atk: = int(stats.get("attack", 0))
	var def: = int(stats.get("defense", 0))
	var agi: = int(stats.get("agility", 0))
	var hp: = int(stats.get("hp", 0))
	var mp: = int(stats.get("mp", 0))
	var atk_s: = format_stat_with_cap("攻击", atk, int(caps.get("attack", 0)))
	var def_s: = format_stat_with_cap("防御", def, int(caps.get("defense", 0)))
	var agi_s: = format_stat_with_cap("敏捷", agi, int(caps.get("agility", 0)))
	var hp_s: = format_stat_with_cap("生命", hp, int(caps.get("hp", 0)))
	var mp_s: = format_stat_with_cap("内力", mp, int(caps.get("mp", 0)))
	if not atk_s.is_empty():
		parts.append(atk_s)
	if not def_s.is_empty():
		parts.append(def_s)
	if not agi_s.is_empty():
		parts.append(agi_s)
	if not hp_s.is_empty():
		parts.append(hp_s)
	if not mp_s.is_empty():
		parts.append(mp_s)
	return " ".join(parts)

static func format_equipment_stats_line(eq) -> String:
	return format_stats_line(stats_dict_from_equipment(eq), caps_for_unenhanced_suit(eq))
