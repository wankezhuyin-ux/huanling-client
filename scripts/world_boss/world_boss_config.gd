class_name WorldBossConfig
extends RefCounted

const UIConstants = preload("res://scripts/ui_constants.gd")
const GameData = preload("res://scripts/game_data.gd")


const GIFT_ITEM_NAME: = "世界首领锦囊"

const BOSS_PET_IDS: Array[String] = [
	"huozhiyizhi", 
	"jinzhizhuzai", 
	"muzhiguize", 
	"tuzhixianjie", 
	"shuizhizhangkong", 
]

const BOSS_DISPLAY_NAMES: Dictionary = {
	"huozhiyizhi": "火之意志", 
	"jinzhizhuzai": "金之主宰", 
	"muzhiguize": "木之规则", 
	"tuzhixianjie": "土之限界", 
	"shuizhizhangkong": "水之掌控", 
}


const FALLBACK_CHALLENGE_START_HOUR: = 11
const FALLBACK_CHALLENGE_START_MINUTE: = 30
const FALLBACK_CHALLENGE_END_HOUR: = 20
const FALLBACK_CHALLENGE_END_MINUTE: = 30
const FALLBACK_DAILY_MAX_ATTEMPTS: = 3
const FALLBACK_BATTLE_MAX_ROUNDS: = 10
const FALLBACK_RANK31_GOLD: = 100000000

const FALLBACK_RANK_REWARD_TIERS: Array = [
	{"rankFrom": 1, "rankTo": 1, "giftCount": 5}, 
	{"rankFrom": 2, "rankTo": 2, "giftCount": 4}, 
	{"rankFrom": 3, "rankTo": 3, "giftCount": 3}, 
	{"rankFrom": 4, "rankTo": 10, "giftCount": 2}, 
	{"rankFrom": 11, "rankTo": 30, "giftCount": 1}, 
]


const BEIJING_OFFSET_SEC: = 28800

static func get_shanghai_date_str(unix_sec: int = -1) -> String:
	var t: = unix_sec if unix_sec >= 0 else int(Time.get_unix_time_from_system())
	t += BEIJING_OFFSET_SEC
	var dt: = Time.get_datetime_dict_from_unix_time(t)
	return "%04d-%02d-%02d" % [int(dt.get("year", 1970)), int(dt.get("month", 1)), int(dt.get("day", 1))]

static func pick_daily_boss_pet_id(event_date: String = "", cfg: Dictionary = {}) -> String:
	var ids: Array[String] = []
	var raw_ids: Variant = cfg.get("bossPetIds", cfg.get("boss_pet_ids", null))
	if raw_ids is Array:
		for entry in raw_ids:
			var sid: = str(entry).strip_edges()
			if not sid.is_empty():
				ids.append(sid)
	if ids.is_empty():
		ids = BOSS_PET_IDS.duplicate()
	if ids.is_empty():
		return ""
	var date_str: = event_date.strip_edges()
	if date_str.is_empty():
		date_str = get_shanghai_date_str()
	var hash_val: int = 0
	for i in range(date_str.length()):
		hash_val = int((hash_val * 31 + date_str.unicode_at(i)) & 4294967295)
	return ids[hash_val % ids.size()]

static func boss_element(boss_id: String) -> String:
	if boss_id.is_empty():
		return ""
	var lib: Dictionary = GameData.WORLD_BOSS_PET_LIBRARY
	if not lib.has(boss_id):
		return ""
	var entry: Variant = lib[boss_id]
	if entry is Dictionary:
		return str(entry.get("element", "")).strip_edges()
	return ""

static func boss_element_color(boss_id: String) -> Color:
	var elem: = boss_element(boss_id)
	var colors: Dictionary = UIConstants.ELEMENT_COLORS
	if colors.has(elem):
		return colors[elem]
	return Color(1.0, 0.88, 0.45)

static func gift_loot_display_names() -> PackedStringArray:
	return PackedStringArray([
		"金币", 
		"极限装备", 
		"套装强化石", 
		"宠物技能书", 
		"世界boss宠", 
	])

static func is_in_challenge_window(cfg: Dictionary = {}) -> bool:
	var start_h: = int(cfg.get("challengeStartHour", FALLBACK_CHALLENGE_START_HOUR))
	var start_m: = int(cfg.get("challengeStartMinute", FALLBACK_CHALLENGE_START_MINUTE))
	var end_h: = int(cfg.get("challengeEndHour", FALLBACK_CHALLENGE_END_HOUR))
	var end_m: = int(cfg.get("challengeEndMinute", FALLBACK_CHALLENGE_END_MINUTE))
	var start_min: = start_h * 60 + start_m
	var end_min: = end_h * 60 + end_m
	var now: = Time.get_datetime_dict_from_system()
	var cur: = int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
	return cur >= start_min and cur < end_min

static func gift_showcase_text(cfg: Dictionary = {}) -> String:
	var names: PackedStringArray = PackedStringArray()
	var raw: Variant = cfg.get("giftLootDisplay", null)
	if raw is Array:
		for entry in raw:
			var n: = str(entry).strip_edges()
			if not n.is_empty():
				names.append(n)
	if not names.is_empty():
		return "、".join(names)
	return "、".join(gift_loot_display_names())

static func build_rules_text(cfg: Dictionary = {}) -> String:
	var start_h: = int(cfg.get("challengeStartHour", FALLBACK_CHALLENGE_START_HOUR))
	var start_m: = int(cfg.get("challengeStartMinute", FALLBACK_CHALLENGE_START_MINUTE))
	var end_h: = int(cfg.get("challengeEndHour", FALLBACK_CHALLENGE_END_HOUR))
	var end_m: = int(cfg.get("challengeEndMinute", FALLBACK_CHALLENGE_END_MINUTE))
	var settle_h: = int(cfg.get("settleHour", 20))
	var settle_m: = int(cfg.get("settleMinute", 35))
	var daily_max: = int(cfg.get("dailyMaxAttempts", FALLBACK_DAILY_MAX_ATTEMPTS))
	var rounds: = int(cfg.get("battleMaxRounds", FALLBACK_BATTLE_MAX_ROUNDS))
	var gold31: = int(cfg.get("rank31to100Gold", FALLBACK_RANK31_GOLD))

	var lines: PackedStringArray = PackedStringArray()
	lines.append("活动时间：每日 %02d:%02d–%02d:%02d（北京时间）" % [start_h, start_m, end_h, end_m])
	lines.append("每日最多挑战 %d 次；出战宠单挑 Boss, %d 回合内输出越高排名越高" % [daily_max, rounds])
	lines.append("当日 %02d:%02d 邮件发放排名奖励；同分先达到该伤害者靠前" % [settle_h, settle_m])
	lines.append("")
	lines.append("排名奖励：")
	var tiers: Variant = cfg.get("rankRewardTiers", FALLBACK_RANK_REWARD_TIERS)
	if tiers is Array:
		for tier in tiers:
			if typeof(tier) != TYPE_DICTIONARY:
				continue
			var from_r: = int(tier.get("rankFrom", 0))
			var to_r: = int(tier.get("rankTo", from_r))
			var gift_n: = int(tier.get("giftCount", 0))
			if gift_n <= 0:
				continue
			if from_r == to_r:
				lines.append("第%d名：%d个%s" % [from_r, gift_n, GIFT_ITEM_NAME])
			else:
				lines.append("第%d–%d名：各%d个%s" % [from_r, to_r, gift_n, GIFT_ITEM_NAME])
	lines.append("第31–100名：各%s金币" % _fmt_gold_short(gold31))
	lines.append("未进前100名：无奖励")
	return "\n".join(lines)

static func _fmt_gold_short(n: int) -> String:
	if n >= 100000000 and n % 100000000 == 0:
		return "%d亿" % (n / 100000000)
	if n >= 10000:
		return "%.0f万" % (float(n) / 10000.0)
	return str(n)
