extends RefCounted

const RARE_BOOKS := ["溅墨lv1技能书", "反打lv1技能书", "护主lv1技能书", "连击lv1技能书", "饮血lv1技能书"]
const COMMON_BOOKS := ["自复lv1技能书", "轻身lv1技能书", "硬皮lv1技能书", "长命lv1技能书", "力壮lv1技能书", "凶性lv1技能书", "致命lv1技能书", "追杀lv1技能书", "守主lv1技能书", "挑衅lv1技能书"]
const ELEMENT_EGGS := ["金纹蛋", "木纹蛋", "水纹蛋", "火纹蛋", "土纹蛋"]
const LIMIT_ITEMS := ["极限武器", "极限衣服", "极限血佩", "极限鞋子", "极限内带"]

static func pool_entries(pool: String) -> Array:
	var ui = load("res://ui/city/lucky_draw_ui.gd")
	var text: String = str(ui.PROBABILITY_TEXT.get(pool, ""))
	var regex := RegEx.new()
	regex.compile("^([^:]+): (?:约)?([0-9.]+)%$")
	var entries: Array = []
	for line in text.split("\n"):
		var match_result := regex.search(line.strip_edges())
		if match_result:
			entries.append({"name": match_result.get_string(1), "weight": int(round(float(match_result.get_string(2)) * 100.0))})
	return entries

static func pick_ticket(entries: Array, ticket: int) -> String:
	for row in entries:
		if ticket < int(row.weight):
			return str(row.name)
		ticket -= int(row.weight)
	return ""

static func pity_status(gm) -> Dictionary:
	var ui = load("res://ui/city/lucky_draw_ui.gd")
	var count: int = int(gm._local_metadata.get("lottery_pity_count", 0))
	return {"count": count, "threshold": ui.YUANBAO_PITY_THRESHOLD, "canClaim": count >= ui.YUANBAO_PITY_THRESHOLD, "options": ui.YUANBAO_PITY_OPTIONS.duplicate()}

static func draw(gm, pool: String, operation_id: String) -> Dictionary:
	var ui = load("res://ui/city/lucky_draw_ui.gd")
	var key := "draw|" + operation_id
	var history: Dictionary = gm._local_metadata.get("lottery_operations", {})
	if history.has(key):
		return history[key].duplicate(true)
	if gm._local_shop_busy or operation_id.is_empty() or pool not in ["gold", "yuanbao"]:
		return {"ok": false, "message": "奖池无效或交易处理中"}
	var cost: int = ui.GOLD_DRAW_COST if pool == "gold" else ui.YUANBAO_DRAW_COST
	var field := "gold" if pool == "gold" else "yuanbao_currency"
	if int(gm.player.get(field)) < cost:
		return {"ok": false, "message": "金币不足，需要5亿金币" if pool == "gold" else "元宝不足，需要100元宝"}
	var entries := pool_entries(pool)
	var total := 0
	for entry in entries:
		total += int(entry.weight)
	if total <= 0:
		return {"ok": false, "message": "奖池配置缺失，未扣费"}
	var snapshot: Dictionary = gm.create_secure_op_snapshot()
	gm._local_shop_busy = true
	var name := pick_ticket(entries, randi_range(0, total - 1))
	var grant: Dictionary = grant_reward(gm, name)
	if not bool(grant.get("ok", false)):
		gm.restore_secure_op_snapshot(snapshot)
		gm._local_shop_busy = false
		return grant
	gm.player.set(field, int(gm.player.get(field)) - cost)
	if pool == "yuanbao":
		gm._local_metadata.lottery_pity_count = int(gm._local_metadata.get("lottery_pity_count", 0)) + 1
	var result := {"ok": true, "rewardName": grant.get("name", name), "rewardDesc": "本地奖励已存入背包或金币余额。", "cost": cost, "pityStatus": pity_status(gm), "local_save_applied": true}
	history = gm._local_metadata.get("lottery_operations", {})
	history[key] = result.duplicate(true)
	gm._local_metadata.lottery_operations = history
	gm._local_shop_busy = false
	if not gm.save_game():
		gm._local_shop_busy = true
		gm.restore_secure_op_snapshot(snapshot)
		gm._local_shop_busy = false
		return {"ok": false, "message": "本地保存失败，扣费、奖励和保底进度均已回滚"}
	gm.gold_changed.emit(gm.player.gold)
	gm.yuanbao_changed.emit(gm.player.yuanbao_currency)
	return result

static func grant_reward(gm, raw_name: String) -> Dictionary:
	var name := raw_name
	if name.ends_with("亿金币"):
		var amount: int = int(name.trim_suffix("亿金币")) * 100000000
		if amount <= 0:
			return {"ok": false, "message": "金币奖励配置异常"}
		gm.player.gold += amount
		return {"ok": true, "name": name}
	if name == "五行属性宠物蛋":
		name = ELEMENT_EGGS.pick_random()
	elif name == "稀有技能书之一":
		name = RARE_BOOKS.pick_random()
	elif name == "普通技能书之一":
		name = COMMON_BOOKS.pick_random()
	elif name in ["极限装备之一", "极限装备（随机一件）"]:
		name = LIMIT_ITEMS.pick_random()
	var before: int = gm.inventory_manager.get_item_count(name)
	var result: Dictionary = gm.inventory_manager.add_item(name, 1)
	if not bool(result.get("success", false)) or gm.inventory_manager.get_item_count(name) != before + 1:
		return {"ok": false, "message": str(result.get("message", "背包空间不足，未扣费"))}
	for item in gm.inventory_manager.items:
		if item.name == name:
			gm.inventory_manager._try_patch_limit_material_custom_data(item)
	return {"ok": true, "name": name}

static func claim(gm, name: String, operation_id: String) -> Dictionary:
	var history: Dictionary = gm._local_metadata.get("lottery_operations", {})
	var key := "claim|" + operation_id
	if history.has(key):
		return history[key].duplicate(true)
	var status := pity_status(gm)
	if gm._local_shop_busy or operation_id.is_empty() or name not in status.options or not bool(status.canClaim):
		return {"ok": false, "message": "保底次数不足、选项无效或交易处理中"}
	var snapshot: Dictionary = gm.create_secure_op_snapshot()
	gm._local_shop_busy = true
	var granted := grant_reward(gm, name)
	if not bool(granted.get("ok", false)):
		gm.restore_secure_op_snapshot(snapshot)
		gm._local_shop_busy = false
		return granted
	gm._local_metadata.lottery_pity_count = int(status.count) - int(status.threshold)
	var result := {"ok": true, "rewardName": name, "pityStatus": pity_status(gm), "local_save_applied": true}
	history = gm._local_metadata.get("lottery_operations", {})
	history[key] = result.duplicate(true)
	gm._local_metadata.lottery_operations = history
	gm._local_shop_busy = false
	if not gm.save_game():
		gm._local_shop_busy = true
		gm.restore_secure_op_snapshot(snapshot)
		gm._local_shop_busy = false
		return {"ok": false, "message": "存档失败，保底领取已回滚"}
	return result
