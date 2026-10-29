extends RefCounted
class_name FabaoConfig



const TIER_IDS: PackedStringArray = [
	"normal", "hard", "hell", "epic", "legend", "supreme", "chaos", "wushang"
]
const TIER_NAMES: PackedStringArray = [
	"普通", "困难", "地狱", "史诗", "传说", "至尊", "混沌", "无上"
]

const SPECIAL_ID: = "memorial_2026"
const SPECIAL_NAME: = "2026纪念"
const SPECIAL_EXP_PCT: = 30.0
const SPECIAL_COMBAT_CAP: = 40
const SPECIAL_CRIT_RATE_CAP: = 15
const SPECIAL_ARMOR_PIERCE_CAP: = 5
const ARMOR_PIERCE_RATE_GROUP: = "armor_pierce_rate"

static var STAT_MUL: PackedInt32Array = [1, 2, 4, 6, 8, 10, 12, 14]
static var REINC_NEED: PackedInt32Array = [0, 100, 200, 300, 400, 500, 700, 1000]

static var NOBLE_NEED: PackedInt32Array = [0, 5, 10, 15, 0, 0, 0, 0]
static var EXP_PCT: PackedFloat32Array = [2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0]
static var COMBAT_CAP: PackedInt32Array = [5, 8, 12, 16, 20, 24, 27, 30]
static var CRIT_RATE_CAP: PackedInt32Array = [2, 3, 4, 5, 6, 7, 8, 10]

static var SYNTH_FRAGMENT_COUNT: = 100
static var DISMANTLE_FRAGMENT_COUNT: = 50
static var REROLL_STONE_NAME: = "法宝洗练石"
static var RESET_STONE_NAME: = "法宝重置石"
static var MAX_WAREHOUSE: = 100
static var DEFAULT_DROP_DENOM: = 2000
static var MIN_FRAGMENT_MAP_LEVEL: = 1000
static var RANDOM_AFFIX_COUNT: = 5
static var COMMON_AFFIX_WEIGHT: = 5
static var RARE_AFFIX_WEIGHT: = 1

const AFFIX_GROUPS: PackedStringArray = [
	"player_atk", "pet_atk", "player_def", "pet_def", 
	"player_agi", "pet_agi", "player_hp", "pet_hp", 
	"player_crit_rate", "pet_crit_rate", "player_crit_dmg", "pet_crit_dmg", 
	"evolve_mutate", "player_element", "armor_pierce_rate"
]
const ELEMENTS: PackedStringArray = ["金", "木", "水", "火", "土"]
const AFFIX_LOCK_COST_STEP: = 100


static func is_lockable_affix_group(group: String) -> bool:
	var g: = group.strip_edges()
	if g.is_empty() or g == "evolve_mutate":
		return false
	return AFFIX_GROUPS.find(g) >= 0


static func normalize_locked_groups(inst: Dictionary) -> PackedStringArray:
	var allowed: Dictionary = {}
	var affixes: Variant = inst.get("affixes", [])
	if affixes is Array:
		for row in affixes:
			if row is Dictionary:
				var g: = str((row as Dictionary).get("group", "")).strip_edges()
				if not g.is_empty():
					allowed[g] = true
	var raw: Variant = inst.get("lockedGroups", inst.get("locked_groups", []))
	var out: PackedStringArray = []
	var seen: Dictionary = {}
	if raw is Array:
		for item in raw:
			var g2: = str(item).strip_edges()
			if not is_lockable_affix_group(g2) or not allowed.has(g2) or seen.has(g2):
				continue
			seen[g2] = true
			out.append(g2)
	return out


static func lock_cost_for_next(locked_count: int) -> int:
	return (maxi(0, locked_count) + 1) * AFFIX_LOCK_COST_STEP


static func has_rerollable_unlocked_affix(inst: Dictionary) -> bool:
	var locked: = normalize_locked_groups(inst)
	var lock_set: Dictionary = {}
	for g in locked:
		lock_set[g] = true
	var affixes: Variant = inst.get("affixes", [])
	if not (affixes is Array):
		return false
	for row in affixes:
		if not (row is Dictionary):
			continue
		var g: = str((row as Dictionary).get("group", "")).strip_edges()
		if g.is_empty() or g == "evolve_mutate":
			continue
		if not lock_set.has(g):
			return true
	return false


static func is_memorial_protected_group(tier_id: String, group: String) -> bool:
	return tier_id.strip_edges() == SPECIAL_ID and (group == "evolve_mutate" or group == "player_element" or group == ARMOR_PIERCE_RATE_GROUP)


static func should_keep_affix_on_reset(inst: Dictionary, group: String) -> bool:
	var g: = group.strip_edges()
	if g.is_empty():
		return true
	var locked: = normalize_locked_groups(inst)
	for lg in locked:
		if lg == g:
			return true
	return is_memorial_protected_group(str(inst.get("tier", "")), g)


static func has_resettable_unlocked_affix(inst: Dictionary) -> bool:
	var affixes: Variant = inst.get("affixes", [])
	if not (affixes is Array):
		return false
	for row in affixes:
		if not (row is Dictionary):
			continue
		var g: = str((row as Dictionary).get("group", "")).strip_edges()
		if g.is_empty():
			continue
		if not should_keep_affix_on_reset(inst, g):
			return true
	return false


static func apply_runtime_config(cfg: Dictionary) -> void :
	if cfg == null or cfg.is_empty():
		return
	if cfg.has("dropDenom"):
		DEFAULT_DROP_DENOM = maxi(1, int(cfg.get("dropDenom", 2000)))
	if cfg.has("minMapLevel"):
		MIN_FRAGMENT_MAP_LEVEL = maxi(0, int(cfg.get("minMapLevel", 1000)))
	if cfg.has("synthFragmentCount"):
		SYNTH_FRAGMENT_COUNT = maxi(1, int(cfg.get("synthFragmentCount", 100)))
	if cfg.has("randomAffixCount"):
		RANDOM_AFFIX_COUNT = clampi(int(cfg.get("randomAffixCount", 5)), 1, 14)
	if cfg.has("commonWeight"):
		COMMON_AFFIX_WEIGHT = maxi(1, int(cfg.get("commonWeight", 5)))
	if cfg.has("rareWeight"):
		RARE_AFFIX_WEIGHT = maxi(1, int(cfg.get("rareWeight", 1)))
	var tiers: Variant = cfg.get("tiers", {})
	if not (tiers is Dictionary):
		return
	var td: Dictionary = tiers
	var mul: PackedInt32Array = STAT_MUL.duplicate()
	var reinc: PackedInt32Array = REINC_NEED.duplicate()
	var expa: PackedFloat32Array = EXP_PCT.duplicate()
	var cap: PackedInt32Array = COMBAT_CAP.duplicate()
	var crit: PackedInt32Array = CRIT_RATE_CAP.duplicate()
	for i in range(TIER_IDS.size()):
		var id: = String(TIER_IDS[i])
		if not td.has(id):
			continue
		var row: Variant = td[id]
		if not (row is Dictionary):
			continue
		var r: Dictionary = row
		mul[i] = maxi(1, int(r.get("mul", mul[i])))
		reinc[i] = maxi(0, int(r.get("reinc", reinc[i])))
		expa[i] = maxf(0.0, float(r.get("expPct", expa[i])))
		cap[i] = maxi(1, int(r.get("combatCap", cap[i])))
		crit[i] = maxi(1, int(r.get("critRateCap", crit[i])))
	STAT_MUL = mul
	REINC_NEED = reinc
	EXP_PCT = expa
	COMBAT_CAP = cap
	CRIT_RATE_CAP = crit


static func tier_index(tier_id: String) -> int:
	var i: = TIER_IDS.find(tier_id)
	return i if i >= 0 else 0


static func is_special_template(tier_id: String) -> bool:
	return tier_id.strip_edges() == SPECIAL_ID


static func is_map_tier(tier_id: String) -> bool:
	return TIER_IDS.find(tier_id.strip_edges()) >= 0


static func all_template_ids() -> PackedStringArray:
	var ids: = TIER_IDS.duplicate()
	ids.append(SPECIAL_ID)
	return ids


static func normalize_tier(tier_id: String) -> String:
	var t: = tier_id.strip_edges()
	if t == SPECIAL_ID:
		return SPECIAL_ID
	return t if TIER_IDS.find(t) >= 0 else "normal"


static func normalize_map_tier(tier_id: String) -> String:
	var t: = tier_id.strip_edges()
	return t if TIER_IDS.find(t) >= 0 else "normal"


static func display_name(tier_id: String) -> String:
	if is_special_template(tier_id):
		return SPECIAL_NAME
	return TIER_NAMES[tier_index(normalize_map_tier(tier_id))]


static func stat_mul(tier_id: String) -> int:
	if is_special_template(tier_id):
		return 1
	return STAT_MUL[tier_index(normalize_map_tier(tier_id))]


static func reinc_need(tier_id: String) -> int:
	if is_special_template(tier_id):
		return 0
	return REINC_NEED[tier_index(normalize_map_tier(tier_id))]


static func noble_need(tier_id: String) -> int:
	if is_special_template(tier_id):
		return 0
	return NOBLE_NEED[tier_index(normalize_map_tier(tier_id))]


static func player_noble_level() -> int:
	if GameManager.instance:
		return maxi(0, int(GameManager.instance.noble_level))
	return 0


static func map_exp_bonus_pct(tier_id: String) -> int:
	var idx: = tier_index(normalize_map_tier(tier_id))
	if idx <= 0:
		return 0
	return idx * 5


static func exp_pct(tier_id: String) -> float:
	if is_special_template(tier_id):
		return SPECIAL_EXP_PCT
	return EXP_PCT[tier_index(normalize_map_tier(tier_id))]


static func combat_cap(tier_id: String) -> int:
	if is_special_template(tier_id):
		return SPECIAL_COMBAT_CAP
	return COMBAT_CAP[tier_index(normalize_map_tier(tier_id))]


static func crit_rate_cap(tier_id: String) -> int:
	if is_special_template(tier_id):
		return SPECIAL_CRIT_RATE_CAP
	return CRIT_RATE_CAP[tier_index(normalize_map_tier(tier_id))]


static func fragment_item_name(tier_id: String) -> String:
	return "%s法宝碎片" % display_name(tier_id)


static func fabao_item_name(tier_id: String) -> String:
	return "%s法宝" % display_name(tier_id)


static func is_fragment_name(item_name: String) -> bool:
	return item_name.ends_with("法宝碎片")


static func is_fabao_name(item_name: String) -> bool:
	return item_name.ends_with("法宝") and not is_fragment_name(item_name)


static func is_tier_unlocked(tier_id: String, reincarnation: int, noble_level: int = -1) -> bool:
	if reincarnation >= reinc_need(tier_id):
		return true
	var need_n: = noble_need(tier_id)
	if need_n <= 0:
		return false
	var noble: = noble_level if noble_level >= 0 else player_noble_level()
	return noble >= need_n


static func unlock_hint(tier_id: String) -> String:
	var r: = reinc_need(tier_id)
	var n: = noble_need(tier_id)
	var name: = display_name(tier_id)
	if n > 0:
		return "投胎满%d次或贵族等级达到%d可解锁%s" % [r, n, name]
	return "投胎满%d次可解锁%s" % [r, name]


static func clamp_tier_for_reinc(tier_id: String, reincarnation: int, noble_level: int = -1) -> String:
	var want: = normalize_map_tier(tier_id)
	var noble: = noble_level if noble_level >= 0 else player_noble_level()
	if is_tier_unlocked(want, reincarnation, noble):
		return want
	var best: = "normal"
	for i in range(TIER_IDS.size()):
		if is_tier_unlocked(TIER_IDS[i], reincarnation, noble):
			best = TIER_IDS[i]
	return best
