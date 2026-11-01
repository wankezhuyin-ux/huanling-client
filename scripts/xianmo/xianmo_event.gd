extends Node
class_name XianMoEventProcessor

const XianMoEventDataClass = preload("res://scripts/xianmo/xianmo_event_data.gd")
const PetDataComplete = preload("res://scripts/pet_data_complete.gd")
const PetClass = preload("res://scripts/pet.gd")

var game_manager = null
var xianmo_system = null

func set_managers(gm, xm):
	game_manager = gm
	xianmo_system = xm

func process_event(event: Dictionary, choice: String = "") -> Dictionary:
	var event_type = event.get("type", "")

	match event_type:
		"pet":
			return process_pet_event(event, choice)
		"pet_battle":
			return process_pet_event(event, choice)
		"treasure":
			return process_treasure_event(event)
		"battle":
			return process_battle_event(event)
		"fortune":
			return process_fortune_event(event)
		"training":
			return process_training_event(event)
		"trap":
			return process_trap_event(event)
		"trap_battle":
			return process_trap_event(event)
		"empty":
			return process_empty_event(event)
		"fragment":
			return process_fragment_event(event)
		_:
			return {"success": true, "rewards": [], "message": "事件处理完成"}

func process_pet_event(event: Dictionary, choice: String = "") -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": false}

	if event.get("type", "") == "pet_battle":
		var won = event.get("won", false)
		result.won = won
		result.message = event.get("message", "战斗结束")
		result.score = event.get("score", 0)
		result.rounds = event.get("rounds", 0)
		result.battleLog = event.get("battleLog", [])

		if won:
			var score = event.get("score", 2)
			result.rewards.append({"type": "score", "amount": score})
			if event.has("growth"):
				result.rewards.append({"type": "pet_gift", "giftName": event.get("giftName", "仙魔变异礼包"), "growth": event.growth})
		return result

	if event.get("no_capture_roll", false):
		var pet_data = create_pet_from_event(event.growth_range[0], event.growth_range[1])
		result.rewards.append({"type": "pet", "data": pet_data})
		result.message = "灵兽主动认你为主！成长率：%.2f" % pet_data.growth
		result.won = true
		return result

	var capture_rate = event.get("capture_rate", 0.5)
	var growth_range = event.get("growth_range", [5.0, 6.0])

	if choice == "capture":
		var roll = randf()
		if roll < capture_rate:
			var pet_data = create_pet_from_event(growth_range[0], growth_range[1])
			result.rewards.append({"type": "pet", "data": pet_data})
			result.message = "成功捕捉到灵兽！成长率：%.2f" % pet_data.growth
			result.won = true
		else:
			result.message = "灵兽逃跑了..."
			result.won = false
		return result

	result.message = "发现了一只灵兽！是否尝试捕捉？"
	result.requires_choice = true
	result.choices = [
		{"id": "capture", "text": "尝试捕捉（成功率%.0f%%）" % (capture_rate * 100)}, 
		{"id": "leave", "text": "离开"}
	]
	return result

func create_pet_from_event(min_growth: float, max_growth: float) -> Dictionary:
	var growth = randf_range(min_growth, max_growth)
	var elements = ["金", "木", "水", "火", "土"]
	var element = elements[randi() % elements.size()]

	var pet_names = {
		"金": ["金灵", "玄金兽", "金翅雕", "金刚狮"], 
		"木": ["木灵", "青木猿", "翠竹蛇", "墨木鹿"], 
		"水": ["水灵", "玄冰龟", "碧波鱼", "水月狐"], 
		"火": ["火灵", "烈焰虎", "赤焰鸟", "火云豹"], 
		"土": ["土灵", "岩石熊", "大地龟", "山岳象"]
	}

	var names = pet_names.get(element, ["灵兽"])
	var pet_name = names[randi() % names.size()]

	return {
		"name": pet_name, 
		"element": element, 
		"growth": growth, 
		"level": 1, 
		"exp": 0, 
		"species": "linlin"
	}

func process_treasure_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": true}

	if event.has("chest_type"):
		var chest_type = event.chest_type
		if chest_type == "random":
			var types = ["bronze", "silver", "gold"]
			var weights = [60, 30, 10]
			var roll = randi() % 100
			var cumulative = 0
			for i in range(types.size()):
				cumulative += weights[i]
				if roll < cumulative:
					chest_type = types[i]
					break

		result.rewards.append({"type": "chest", "chest_type": chest_type})
		result.message = "获得了%s宝箱！" % _get_chest_name(chest_type)
		return result

	if event.has("items"):
		var items = event.items
		var item = items[randi() % items.size()]
		result.rewards.append({"type": "item", "item_id": item, "count": 1})
		result.message = "获得了%s！" % _get_item_name(item)
		return result

	if event.has("gold_range"):
		var gold = randi_range(event.gold_range[0], event.gold_range[1])
		result.rewards.append({"type": "gold", "amount": gold})
		result.message = "获得了%d金币！" % gold
		return result

	if event.get("random_item", false):
		var items = ["cultivation_pill", "gold"]
		var item = items[randi() % items.size()]
		if item == "gold":
			var gold = randi_range(100000, 500000)
			result.rewards.append({"type": "gold", "amount": gold})
			result.message = "获得了%d金币！" % gold
		else:
			result.rewards.append({"type": "item", "item_id": item, "count": 1})
			result.message = "获得了%s！" % _get_item_name(item)
		return result

	if event.get("fragment", false):
		result.rewards.append({"type": "fragment", "count": 1})
		result.message = "获得了藏宝图残片×1！"
		return result

	result.message = "探索完成，但没有发现宝物..."
	return result

func process_battle_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": false}

	var won = event.get("won", false)
	result.won = won
	result.message = event.get("message", "战斗结束")
	result.score = event.get("score", 0)
	result.rounds = event.get("rounds", 0)
	result.battleLog = event.get("battleLog", [])
	result.opponent = event.get("opponent", "未知")

	if won:
		var score = event.get("score", 4)
		result.rewards.append({"type": "score", "amount": score})

	return result

func process_fortune_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": true}

	if event.has("action_points_bonus"):
		var bonus = event.action_points_bonus
		result.rewards.append({"type": "action_points", "amount": bonus})
		result.message = "仙人指路！获得%d点行动力！" % bonus
		return result

	if event.has("cultivation_bonus"):
		var bonus = event.cultivation_bonus
		result.rewards.append({"type": "cultivation", "amount": bonus})
		result.message = "悟道机缘！获得%d修行值！" % bonus
		return result

	if event.has("buff_type"):
		result.rewards.append({"type": "buff", "buff_type": event.buff_type, "value": event.buff_value})
		result.message = "功法传承！下次战斗攻击力+%d%%！" % event.buff_value
		return result

	if event.get("direct_score", false):
		var score = event.get("score", 4)
		result.rewards.append({"type": "score", "amount": score})
		result.message = "仙缘际会！直接获得%d积分！" % score
		return result

	if event.get("rare_item", false):
		var items = ["cultivation_pill", "gold_chest"]
		var item = items[randi() % items.size()]
		if item == "gold_chest":
			result.rewards.append({"type": "chest", "chest_type": "gold"})
			result.message = "天降祥瑞！获得黄金匣！"
		else:
			result.rewards.append({"type": "item", "item_id": item, "count": 1})
			result.message = "天降祥瑞！获得%s！" % _get_item_name(item)
		return result

	if event.has("item_reward"):
		var ir = event.item_reward
		if ir is Dictionary and ir.has("name"):
			var item_name: = str(ir.get("name", ""))
			var count: = int(ir.get("count", 1))
			result.rewards.append({"type": "item", "item_id": item_name, "count": count})
			result.message = "获得【%s】×%d！" % [item_name, count]
			return result

	if event.has("exp_bonus"):
		var bonus = event.exp_bonus
		result.rewards.append({"type": "exp", "amount": bonus})
		result.message = "传承记忆！获得%d经验值！" % bonus
		return result

	result.message = "好运降临！"
	return result

func process_training_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": true}

	if event.has("cultivation_bonus"):
		var bonus = event.cultivation_bonus
		result.rewards.append({"type": "cultivation", "amount": bonus})
		result.message = "修炼有成！获得%d修行值！" % bonus
		return result

	if event.has("next_event_score_bonus"):
		result.rewards.append({"type": "score_buff", "amount": event.next_event_score_bonus})
		result.message = "灵气充沛！下次事件积分+%d！" % event.next_event_score_bonus
		return result

	if event.has("exp_bonus"):
		var bonus = event.exp_bonus
		result.rewards.append({"type": "exp", "amount": bonus})
		result.message = "打坐冥想！获得%d经验值！" % bonus
		return result

	result.message = "修炼完成！"
	return result

func process_trap_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": false}

	if event.get("type", "") == "trap_battle":
		var won = event.get("won", false)
		result.won = won
		result.message = event.get("message", "战斗结束")
		result.score = event.get("score", 0)
		result.rounds = event.get("rounds", 0)
		result.battleLog = event.get("battleLog", [])

		if won:
			var score = event.get("score", 1)
			result.rewards.append({"type": "score", "amount": score})
		else:
			result.no_score_on_lose = true
		return result

	if event.has("action_points_cost"):
		result.rewards.append({"type": "action_points_cost", "amount": event.action_points_cost})
		result.message = "幻阵困局！消耗%d点行动力脱困！" % event.action_points_cost
		return result

	if event.get("no_reward", false):
		result.message = "迷雾森林！你迷失了方向..."
		return result

	if event.has("action_points_loss"):
		result.rewards.append({"type": "action_points_loss", "amount": event.action_points_loss})
		result.message = "陷阱机关！损失%d点行动力！" % event.action_points_loss
		return result

	if event.get("score_loss", false):
		result.rewards.append({"type": "score_loss", "amount": 1})
		result.message = "魔气侵蚀！损失1点积分！"
		return result

	result.message = "遇到了麻烦..."
	return result

func process_empty_event(_event: Dictionary) -> Dictionary:
	return {
		"success": true, 
		"rewards": [], 
		"message": "你在仙魔界中探索了一番，什么也没发现...", 
		"won": true
	}

func process_fragment_event(event: Dictionary) -> Dictionary:
	var result = {"success": true, "rewards": [], "message": "", "won": true}

	var count = event.get("fragment_count", 1)
	result.rewards.append({"type": "fragment", "count": count})
	result.message = "发现神秘残片！获得藏宝图残片×%d！" % count

	return result

func apply_rewards(rewards: Array) -> Dictionary:
	var result = {"messages": [], "gold": 0, "exp": 0, "cultivation": 0, "score": 0}

	for reward in rewards:
		match reward.type:
			"gold":
				if game_manager and game_manager.player:
					if game_manager.network and game_manager.network.is_logged_in():
						push_warning("[XianMoEvent] apply_rewards: online gold must use server adventure/economy path")
					else:
						game_manager.player.gold += reward.amount
					result.gold = reward.amount
					result.messages.append("获得%d金币" % reward.amount)
			"exp":
				if game_manager and game_manager.player:
					game_manager.player.add_exp(reward.amount)
					result.exp = reward.amount
					result.messages.append("获得%d经验" % reward.amount)
			"cultivation":
				if game_manager and game_manager.player:
					game_manager.player.cultivation += reward.amount
					result.cultivation = reward.amount
					result.messages.append("获得%d修行值" % reward.amount)
			"action_points":
				if xianmo_system:
					xianmo_system.xianmo_data.action_points += reward.amount
					result.messages.append("获得%d行动力" % reward.amount)
			"action_points_cost", "action_points_loss":
				if xianmo_system:
					xianmo_system.xianmo_data.action_points = max(0, xianmo_system.xianmo_data.action_points - reward.amount)
					result.messages.append("损失%d行动力" % reward.amount)
			"score":
				result.score = reward.amount
				result.messages.append("获得%d积分" % reward.amount)
			"score_loss":
				if xianmo_system:
					xianmo_system.xianmo_data.weekly_score = max(0, xianmo_system.xianmo_data.weekly_score - reward.amount)
					result.messages.append("损失%d积分" % reward.amount)
			"fragment":
				if xianmo_system:
					xianmo_system.add_fragments(reward.count)
					result.messages.append("获得%d藏宝图残片" % reward.count)
			"chest":
				result.messages.append("获得%s宝箱" % _get_chest_name(reward.chest_type))
			"item":
				result.messages.append("获得%s" % _get_item_name(reward.item_id))
			"pet":
				if game_manager and game_manager.pet_manager:
					var pet_data = reward.data
					var pet = PetClass.new()
					pet.pet_name = pet_data.name
					pet.element = pet_data.element
					pet.growth = pet_data.growth
					pet.level = pet_data.level
					game_manager.pet_manager.add_pet(pet)
					result.messages.append("捕捉到灵兽：%s（成长%.2f）" % [pet_data.name, pet_data.growth])
			"score_buff":
				if xianmo_system:
					xianmo_system.xianmo_data.buff_next_event_score = reward.amount
					result.messages.append("下次事件积分+%d" % reward.amount)

	return result

func _get_chest_name(chest_type: String) -> String:
	match chest_type:
		"bronze": return "青铜"
		"silver": return "白银"
		"gold": return "黄金"
		_: return "未知"

func _get_item_name(item_id: String) -> String:
	match item_id:
		"cultivation_pill": return "悟道仙丹"
		_: return item_id

func broadcast_event(event_type: String, details: Dictionary):
	if game_manager:
		game_manager.broadcast_event(event_type, game_manager.player.player_name, details)
