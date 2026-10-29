extends RefCounted
class_name GangConfig

const DOUBLE_EXP_ITEM: = "双倍经验丹"
const MATERIAL_ITEM: = "建设材料"


const TERRITORY_TIER_MIN_GANG_LEVEL: = {
	"初级": 5, 
	"中级": 7, 
	"高级": 8, 
	"唯一": 10, 
}
const TERRITORY_WAR_UNLOCK_LEVEL: = 5

static func min_gang_level_for_territory_tier(tier: String) -> int:
	var key: = str(tier).strip_edges()
	if TERRITORY_TIER_MIN_GANG_LEVEL.has(key):
		return int(TERRITORY_TIER_MIN_GANG_LEVEL[key])
	return int(TERRITORY_TIER_MIN_GANG_LEVEL["初级"])

static func emblem_path(emblem_id: int) -> String:
	var id: = clampi(emblem_id, 1, 32)
	return "res://assets/gang_emblems/emblem_%02d_%s.png" % [id, _emblem_suffix(id)]

static func _emblem_suffix(id: int) -> String:
	var names: = {
		1: "dragon_flame", 2: "sword_cross", 3: "phoenix_fire", 4: "iron_shield", 
		5: "tiger_fang", 6: "lotus_grace", 7: "mountain_peak", 8: "flame_rage", 
		9: "star_celestial", 10: "thunder_strike", 11: "gear_iron", 12: "moon_shadow", 
		13: "wolf_howl", 14: "eagle_soar", 15: "snake_coil", 16: "bull_charge", 
		17: "turtle_steadfast", 18: "crane_grace", 19: "fox_cunning", 20: "bear_fury", 
		21: "shark_jaw", 22: "ape_fist", 23: "shenlong", 24: "tiger_roar", 
		25: "leopard_strike", 26: "lion_majestic", 27: "qilin", 28: "pixiu", 
		29: "xuanwu", 30: "baihu", 31: "zhuque", 32: "taotie", 
	}
	return str(names.get(id, "dragon_flame"))

static func territory_icon_path(territory_id: String) -> String:
	var tid: = str(territory_id).strip_edges()
	var files: = {
		"sky_city": "tiankongzhichengtb.png", 
		"fuying_water": "fuyingshuichengtb.png", 
		"banyan_city": "rongshuzhichengtb.png", 
		"ninglu_mountain": "ninglushanchengtb.png", 
		"ruitian_snow": "ruitianxuechengtb.png", 
		"deep_blue": "shenlanhaichengtb.png", 
		"wofu_sand": "wofoshachengtb.png", 
		"chilechuan": "chilechuantb.png", 
		"qiyue_valley": "qiyuegutb.png", 
		"huishou_ting": "huishoutingtb.png", 
		"huashan_ding": "huashandingtb.png", 
		"huangzhi_gu": "huangzhigutb.png", 
		"dong_matou": "dongmatoutb.png", 
		"jianchi_gu": "jianchigutb.png", 
		"bugui_haian": "buguihaiantb.png", 
	}
	var file_name: String = str(files.get(tid, ""))
	if file_name.is_empty():
		return ""
	return "res://assets/citytb/%s" % file_name

static func build_territory_siege_rules_text(cfg: Dictionary = {}) -> String:
	var max_territories: = int(cfg.get("maxTerritoriesPerGang", 3))
	var base_bid: = int(cfg.get("siegeBaseBid", 100000))
	var weekly_attempts: = int(cfg.get("weeklySiegeAttempts", 3))
	var protect_days: = int(cfg.get("siegeTerritoryProtectDays", 7))
	var free_atk: = int(cfg.get("siegeFreeAttackLimit", 3))
	var atk_contrib_cost: = int(cfg.get("siegeAttackContributionCost", 200))
	var atk_contrib_limit: = int(cfg.get("siegeAttackContributionLimit", 3))
	var atk_yb_cost: = int(cfg.get("siegeYuanbaoAttackCost", 100))
	var atk_yb_limit: = int(cfg.get("siegeYuanbaoAttackLimit", 3))
	var def_contrib_cost: = int(cfg.get("siegeRepairContribution", 200))
	var def_contrib_limit: = int(cfg.get("siegeRepairMaxPerRound", 3))
	var def_yb_cost: = int(cfg.get("siegeYuanbaoDefenseCost", 100))
	var def_yb_limit: = int(cfg.get("siegeYuanbaoDefenseLimit", 3))
	var schedule: Dictionary = cfg.get("siegeSchedule", {})
	var battle_day: = _weekday_label(int(schedule.get("battleWeekday", 0)))
	var schedule_lines: = _build_siege_schedule_lines(schedule)
	var round_count: = int(schedule.get("rounds", []).size())
	if round_count <= 0:
		round_count = 4
	var test_hint: = ""
	if bool(schedule.get("ignoreWeekdayForTest", false)):
		test_hint = "\n（当前为测试模式：任意日期均按下方时间表推进阶段）\n"
	return (
		"【开放时间】\n"
		+ "每周 %s 开放领地争夺战，共 %d 轮：\n" % [battle_day, round_count]
		+ schedule_lines
		+ test_hint
		+ "\n【流程说明】\n"
		+ "1. 申请攻占：帮主在申请窗口内选择目标领地并冻结帮派资金；可选购买攻城增益（额外消耗帮派资金）。\n"
		+ "2. 盲盒竞价：申请截止后进入竞价，出价对外保密。\n"
		+ "3. 公布竞价：竞价截止后公布最高价，最高出价帮派获得本轮挑战资格；若多人同价，以先登记该出价的时间为准（先出价者优先）。\n"
		+ "4. 驻守配置：占领方帮主可在申请截止前配置成员镜像驻守；截止后锁定。\n"
		+ "5. 挑战阶段：帮战式镜像对决，攻方消耗防守槽；耐久归零则攻方立即占领。\n"
		+ "6. 占领收益：占领后每日产出建设材料与帮派资金。\n\n"
		+ "【占领等级】\n"
		+ "· 帮派达到 Lv.5 即可参与领地战；不同档位领地所需帮派等级不同：\n"
		+ "· 初级领地（敕勒川、栖月谷、回首亭、华山顶、凰之谷、东码头）：需帮派 Lv.5\n"
		+ "· 中级领地（瑞天雪城、深蓝海城、卧佛沙城、剑池谷、不归海岸）：需帮派 Lv.7\n"
		+ "· 高级领地（浮影水城、榕树之城、凝露山城）：需帮派 Lv.8\n"
		+ "· 天空之城：需帮派 Lv.10\n"
		+ "· 等级不足时不可申请/竞价对应档位领地。\n\n"
		+ "【挑战规则】\n"
		+ "· 各领地攻城耐久不同，以领地详情为准；提前打至 0 则本场立即结束（下轮时间不变，休整期相应变长）。\n"
		+ "· 攻方每人每轮：免费进攻 %d 次；帮贡 %d 可再买 %d 次；元宝 %d 可再买 %d 次（最多 %d 次）。\n" % [
			free_atk, atk_contrib_cost, atk_contrib_limit, atk_yb_cost, atk_yb_limit, 
			free_atk + atk_contrib_limit + atk_yb_limit, 
		]
		+ "· 守方每人每轮：帮贡 %d 加固 %d 次；元宝 %d 加固 %d 次（每次 +1 耐久并 +1 防守槽）。\n" % [
			def_contrib_cost, def_contrib_limit, def_yb_cost, def_yb_limit, 
		]
		+ "· 进攻前须更新帮派镜像；不足驻守由固定 NPC「领地守军」（哪吒镜像）补位，强度按领地配置。\n"
		+ "· 挑战窗口内未攻破则守方守住；超时视同守方胜利。\n\n"
		+ "【占领上限】\n"
		+ "每个帮派最多同时占领 %d 块领地；每周最多发起 %d 次攻城。\n\n" % [max_territories, weekly_attempts]
		+ "【保护期】\n"
		+ "新占领领地保护 %d 天，保护期内不可被其他帮派申请攻占。\n\n" % protect_days
		+ "【竞价参考】\n"
		+ "申请出价与盲盒竞价均以万为单位（1万 = 帮派资金 10000），须为 1 万的整数倍。\n"
		+ "竞价阶段仅可提交一次出价；出价不得低于底价 %s（即 %d 万）。\n" % [_format_rule_number(base_bid), maxi(1, int(base_bid / 10000))]
		+ "· 同价并列时，先登记出价的帮派获得挑战资格，其余全额退款。\n\n"
		+ "【加成说明】\n"
		+ "· 攻击、防御、生命、敏捷、全属性、经验：人物与出战宠物同时生效。\n"
		+ "· 金币掉落：仅人物生效。\n"
		+ "· 多块领地加成叠加，与帮派等级固定增益一并计入总增益。\n"
		+ "· 占领天空之城后，本帮其它领地的加成效果翻倍（天空之城自身加成不变）。"
	)

static func _weekday_label(weekday: int) -> String:
	var labels: = ["日", "一", "二", "三", "四", "五", "六"]
	var idx: = clampi(weekday, 0, 6)
	return "周%s" % labels[idx]

static func _build_siege_schedule_lines(schedule: Dictionary) -> String:
	var rounds: Array = schedule.get("rounds", [])
	if rounds.is_empty():
		return (
			"第1轮：申请至 10:20 → 盲盒竞价 10:20~10:30 → 挑战 10:30~12:30\n"
			+ "第2轮：申请至 13:20 → 盲盒竞价 13:20~13:30 → 挑战 13:30~15:30\n"
			+ "第3轮：申请至 16:20 → 盲盒竞价 16:20~16:30 → 挑战 16:30~18:30\n"
			+ "第4轮：申请至 19:20 → 盲盒竞价 19:20~19:30 → 挑战 19:30~21:30\n"
		)
	var out: = ""
	for r in rounds:
		if not r is Dictionary:
			continue
		var n: = int(r.get("roundNo", 0))
		var apply_end: = str(r.get("applyEnd", ""))
		var bid_start: = str(r.get("bidStart", apply_end))
		var bid_end: = str(r.get("bidEnd", bid_start))
		var ch_start: = str(r.get("challengeStart", bid_end))
		var ch_end: = str(r.get("challengeEnd", ch_start))
		out += "第%d轮：申请至 %s → 盲盒竞价 %s~%s → 挑战 %s~%s\n" % [
			n if n > 0 else 1, apply_end, bid_start, bid_end, ch_start, ch_end, 
		]
	return out

static func is_kick_start_blocked(cfg: Dictionary = {}, now_unix: int = -1) -> bool:
	var end_hour: = clampi(int(cfg.get("kickStartBlockEndHour", 8)), 0, 24)
	var unix_ts: = now_unix
	if unix_ts < 0:
		unix_ts = int(Time.get_unix_time_from_system())
	var bj_unix: = unix_ts + 8 * 3600
	var dt: = Time.get_datetime_dict_from_unix_time(bj_unix)
	return int(dt.get("hour", 0)) < end_hour

static func build_kick_war_rules_text(cfg: Dictionary = {}) -> String:
	var kick_cost: = int(cfg.get("kickHallCost", 50000))
	var repair_cost: = int(cfg.get("kickRepairContribution", 500))
	var weekly_start: = int(cfg.get("kickWeeklyStartLimit", 2))
	var weekly_defend: = int(cfg.get("kickWeeklyDefendLimit", 3))
	var protect_hours: = int(cfg.get("kickProtectHours", 24))
	var repair_max: = int(cfg.get("kickRepairMaxPerSession", 3))
	var mat_pct: = int(round(float(cfg.get("kickWinMaterialStealPct", 0.1)) * 100.0))
	var fund_pct: = int(round(float(cfg.get("kickWinFundStealPct", 0.1)) * 100.0))
	var free_atk: = int(cfg.get("kickDailyAttackLimit", 3))
	var atk_contrib_limit: = int(cfg.get("kickAttackContributionLimit", 3))
	var atk_contrib_cost: = int(cfg.get("kickAttackContributionCost", 200))
	var atk_yb_limit: = int(cfg.get("kickYuanbaoAttackLimit", 3))
	var atk_yb_cost: = int(cfg.get("kickYuanbaoAttackCost", 100))
	var def_yb_limit: = int(cfg.get("kickYuanbaoDefenseLimit", 3))
	var def_yb_cost: = int(cfg.get("kickYuanbaoDefenseCost", 100))
	var block_end_hour: = int(cfg.get("kickStartBlockEndHour", 8))
	var prep_m: = int(cfg.get("kickPrepMinutes", 30))
	var battle_h: = int(cfg.get("kickBattleHours", 2))
	var atk_cd: = int(cfg.get("kickAttackCooldownSeconds", 120))
	var repair_cd: = int(cfg.get("kickRepairCooldownSeconds", 60))
	return (
		"【解锁条件】\n"
		+ "帮派达到 Lv.5 后解锁帮战。\n\n"
		+ "【宣战】\n"
		+ "· 仅帮主/副帮主可发起宣战。\n"
		+ "· 每日北京时间 %d:00 前不可发起宣战。\n" % block_end_hour
		+ "· 消耗帮派资金 %s。\n" % _format_rule_number(kick_cost)
		+ "· 对方处于保护期内不可宣战（被宣战后保护 %d 小时）。\n" % protect_hours
		+ "· 不能对低于 Lv.5 的帮派宣战。\n\n"
		+ "【准备期】\n"
		+ "· 宣战后进入 %d 分钟准备期；系统广播并邮件通知双方成员。\n" % prep_m
		+ "· 准备期内攻方不可进攻；守方可提前补防。\n"
		+ "· 准备结束后正式开战，开战时长 %d 小时。\n\n" % battle_h
		+ "【次数限制】\n"
		+ "· 本周主动宣战上限：%d 次。\n" % weekly_start
		+ "· 本周被宣战上限：%d 次。\n\n" % weekly_defend
		+ "【帮派镜像】\n"
		+ "进攻前须在成员页更新帮派镜像，否则无法发起进攻。\n\n"
		+ "【战斗】\n"
		+ "· 正式开战后方可进攻；攻方成员消耗本场参战次数进攻。\n"
		+ "· 每人每次进攻后冷却 %d 秒（免费/帮贡/元宝次数共用冷却）。\n" % atk_cd
		+ "· 每人每场次免费进攻 %d 次；可用帮贡（%d/次，上限 %d）或元宝（%d/次，上限 %d）购买额外次数。\n" % [
			free_atk, atk_contrib_cost, atk_contrib_limit, atk_yb_cost, atk_yb_limit
		]
		+ "· 守方耐久归零则攻方胜利。\n\n"
		+ "【补防】\n"
		+ "守方帮众消耗帮贡 %d 补防，每次 +1 耐久并增加独立防守槽。\n" % repair_cost
		+ "每人每场次帮贡补防最多 %d 次；可用元宝（%d/次，上限 %d）额外补防。\n" % [repair_max, def_yb_cost, def_yb_limit]
		+ "准备期即可补防；每人补防冷却 %d 秒（帮贡/元宝补防共用）。\n\n" % repair_cd
		+ "【胜利奖励】\n"
		+ "攻方胜利可夺取守方部分建设材料（%d%%）与帮派资金（%d%%）。\n\n" % [mat_pct, fund_pct]
		+ "【帮派声望】\n"
		+ "· 仅通过帮战（宣战）获得，领地战不计入。\n"
		+ "· 攻方胜利：帮派声望 +5；攻方失败：-2。\n"
		+ "· 守方胜利：帮派声望 +2；守方失败：-1。\n"
		+ "· 声望范围 0~150；升到 Lv.6 起每次升级需消耗对应声望（6级10、7级20，依次类推）。\n\n"
		+ "【与领地战区别】\n"
		+ "帮战是帮派对帮派的资源争夺；领地战是周日领地争夺，二者独立进行。"
	)

static func _format_rule_number(n: int) -> String:
	if n >= 100000000:
		return "%.1f亿" % (float(n) / 100000000.0)
	if n >= 10000:
		return "%.1f万" % (float(n) / 10000.0)
	return str(n)
