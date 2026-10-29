class_name ArenaConfig
extends RefCounted

const BEIJING_OFFSET_SEC: = 28800

const FALLBACK_CHALLENGE_START_HOUR: = 8
const FALLBACK_CHALLENGE_START_MINUTE: = 30
const FALLBACK_CHALLENGE_END_HOUR: = 23
const FALLBACK_CHALLENGE_END_MINUTE: = 30
const FALLBACK_SETTLE_HOUR: = 23
const FALLBACK_SETTLE_MINUTE: = 35
const FALLBACK_DAILY_MAX_ATTEMPTS: = 10
const FALLBACK_BATTLE_MAX_ROUNDS: = 20
const FALLBACK_WIN_SCORE_DELTA: = 10

const FALLBACK_LOSE_SCORE_DELTA: = 2
const FALLBACK_MATCH_SCORE_BAND: = 80
const FALLBACK_RANKING_DISPLAY_LIMIT: = 100

const FALLBACK_SHOP_ITEMS: Array = [
	{"id": "limit_equip_gift", "itemName": "极限装备锦囊", "cost": 1500}, 
]

const FALLBACK_TITLE_NAMES: = [
	"天下无敌", "一骑当千", "以一敌百", 
]

const FALLBACK_TITLE_CONFIGS: Array = [
	{"rank": 1, "name": "天下无敌", "attack": 2000, "defense": 2000, "agility": 2000, "hp": 10000}, 
	{"rank": 2, "name": "一骑当千", "attack": 1500, "defense": 1500, "agility": 1500, "hp": 6000}, 
	{"rank": 3, "name": "以一敌百", "attack": 1000, "defense": 1000, "agility": 1000, "hp": 3000}, 
]

const FALLBACK_GIFT_PACKS: Dictionary = {
	"champion": {"itemName": "冠军锦囊", "items": [{"name": "极限装备锦囊", "count": 3}], "gold": 5000000000}, 
	"runner_up": {"itemName": "亚军锦囊", "items": [{"name": "极限装备锦囊", "count": 2}], "gold": 3000000000}, 
	"third": {"itemName": "季军锦囊", "items": [{"name": "极限装备锦囊", "count": 1}], "gold": 1000000000}, 
	"top10": {"itemName": "十强锦囊", "items": [{"name": "极限装备之一", "count": 1}], "gold": 500000000}, 
}

const FALLBACK_RANK_GOLD_TIERS: Array = [
	{"rankFrom": 11, "rankTo": 30, "gold": 500000000}, 
	{"rankFrom": 31, "rankTo": 50, "gold": 200000000}, 
	{"rankFrom": 51, "rankTo": 100, "gold": 100000000}, 
]


static func compute_spendable_points(total: int, weekly: int) -> int:
	var t: = maxi(0, int(total))
	var w: = maxi(0, int(weekly))
	return maxi(0, t - w)


static func resolve_balance_points(data: Dictionary) -> int:
	if data.has("balanceArenaPoints") or data.has("balance_arena_points"):
		return maxi(0, int(data.get("balanceArenaPoints", data.get("balance_arena_points", 0))))
	if data.has("spendableArenaPoints") or data.has("spendable_arena_points"):
		return maxi(0, int(data.get("spendableArenaPoints", data.get("spendable_arena_points", 0))))
	var total: = int(data.get("totalArenaPoints", data.get("total_arena_points", 0)))
	var weekly: = int(data.get("weeklyArenaPoints", data.get("weekly_arena_points", 0)))
	return compute_spendable_points(total, weekly)


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


static func build_rules_text(cfg: Dictionary = {}) -> String:
	var desc: = str(cfg.get("descriptionText", cfg.get("description_text", ""))).strip_edges()
	if not desc.is_empty():
		return desc
	return _build_fallback_rules_text(cfg)


static func _fmt_gold_short(n: int) -> String:
	if n >= 100000000 and n % 100000000 == 0:
		return "%d亿" % (n / 100000000)
	if n >= 10000:
		return "%d万" % int(float(n) / 10000.0)
	return str(n)


static func _format_gift_pack_items(pack: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var items: Variant = pack.get("items", [])
	if items is Array:
		for it in items:
			if typeof(it) != TYPE_DICTIONARY:
				continue
			var name_str: = str(it.get("name", "")).strip_edges()
			var count: = maxi(1, int(it.get("count", 1)))
			if not name_str.is_empty():
				parts.append("%s×%d" % [name_str, count])
	var gold: = int(pack.get("gold", 0))
	if gold > 0:
		parts.append("%s金币" % _fmt_gold_short(gold))
	return "、".join(parts)


static func _format_title_stats(title_cfg: Dictionary) -> String:
	return "攻+%d 防+%d 敏+%d 血+%d" % [
		int(title_cfg.get("attack", 0)), 
		int(title_cfg.get("defense", 0)), 
		int(title_cfg.get("agility", 0)), 
		int(title_cfg.get("hp", 0)), 
	]


static func _build_fallback_rules_text(cfg: Dictionary = {}) -> String:
	var start_h: = int(cfg.get("challengeStartHour", FALLBACK_CHALLENGE_START_HOUR))
	var start_m: = int(cfg.get("challengeStartMinute", FALLBACK_CHALLENGE_START_MINUTE))
	var end_h: = int(cfg.get("challengeEndHour", FALLBACK_CHALLENGE_END_HOUR))
	var end_m: = int(cfg.get("challengeEndMinute", FALLBACK_CHALLENGE_END_MINUTE))
	var settle_h: = int(cfg.get("settleHour", FALLBACK_SETTLE_HOUR))
	var settle_m: = int(cfg.get("settleMinute", FALLBACK_SETTLE_MINUTE))
	var daily_max: = int(cfg.get("dailyMaxAttempts", FALLBACK_DAILY_MAX_ATTEMPTS))
	var rounds: = int(cfg.get("battleMaxRounds", FALLBACK_BATTLE_MAX_ROUNDS))
	var win_d: = int(cfg.get("winScoreDelta", FALLBACK_WIN_SCORE_DELTA))
	var lose_d: = int(cfg.get("loseScoreDelta", FALLBACK_LOSE_SCORE_DELTA))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("开放时间：每日 %02d:%02d–%02d:%02d（北京时间，周日 23:30 截止挑战）" % [start_h, start_m, end_h, end_m])
	lines.append("每周日 %02d:%02d 按当周竞技点排名邮件发奖" % [settle_h, settle_m])
	lines.append("每日最多挑战 %d 次；胜 +%d / 负 +%d 仅影响当周竞技点（周榜排名）" % [daily_max, win_d, lose_d])
	lines.append("上周结余竞技点用于商店兑换；新周开始时上周当周分自动转入结余；当周胜负不影响上周结余")
	lines.append("战斗最多 %d 回合，超时判负" % rounds)
	lines.append("")
	lines.append("周榜奖励：")

	var gift_keys: = {1: "champion", 2: "runner_up", 3: "third"}
	for title_cfg in FALLBACK_TITLE_CONFIGS:
		if typeof(title_cfg) != TYPE_DICTIONARY:
			continue
		var rank: = int(title_cfg.get("rank", 0))
		if rank <= 0:
			continue
		var pack_key: String = str(gift_keys.get(rank, ""))
		var pack: Dictionary = FALLBACK_GIFT_PACKS.get(pack_key, {}) if not pack_key.is_empty() else {}
		var line: = "第%d名：称号「%s」（%s）" % [rank, str(title_cfg.get("name", "")), _format_title_stats(title_cfg)]
		if not pack.is_empty():
			line += " + %s（%s）" % [str(pack.get("itemName", "")), _format_gift_pack_items(pack)]
		lines.append(line)

	var top10: Dictionary = FALLBACK_GIFT_PACKS.get("top10", {})
	if not top10.is_empty():
		lines.append("第4–10名：%s（%s）" % [str(top10.get("itemName", "十强锦囊")), _format_gift_pack_items(top10)])

	for tier in FALLBACK_RANK_GOLD_TIERS:
		if typeof(tier) != TYPE_DICTIONARY:
			continue
		var from_r: = int(tier.get("rankFrom", 0))
		var to_r: = int(tier.get("rankTo", from_r))
		if from_r <= 0:
			continue
		var gold_text: = _fmt_gold_short(int(tier.get("gold", 0)))
		if from_r == to_r:
			lines.append("第%d名：%s金币" % [from_r, gold_text])
		else:
			lines.append("第%d–%d名：%s金币" % [from_r, to_r, gold_text])

	lines.append("未进前100名：无奖励")
	return "\n".join(lines)


static func merge_player_config(status_data: Dictionary) -> Dictionary:
	var cfg: Dictionary = status_data.get("config", {}) if status_data.get("config") is Dictionary else {}
	if cfg.is_empty():
		cfg = {}
	cfg["featureEnabled"] = bool(status_data.get("featureEnabled", status_data.get("feature_enabled", cfg.get("featureEnabled", false))))
	return cfg
