extends Node
class_name XianMoReward

const TitleDataClass = preload("res://scripts/title/title_data.gd")

var game_manager = null
var xianmo_system = null

func set_managers(gm, xm):
	game_manager = gm
	xianmo_system = xm

func settle_weekly_rewards(xian_total: int, mo_total: int, xian_rankings: Array, mo_rankings: Array) -> Dictionary:
	var result = {
		"winner": "", 
		"xian_total": xian_total, 
		"mo_total": mo_total, 
		"rewards_sent": []
	}

	if xian_total > mo_total:
		result.winner = "xian"
	elif mo_total > xian_total:
		result.winner = "mo"
	else:
		result.winner = "draw"

	for i in range(min(3, xian_rankings.size())):
		var player_data = xian_rankings[i]
		var is_winner = (result.winner == "xian")
		var rewards = generate_ranking_rewards("xian", i + 1, is_winner)
		send_rewards_via_mail(player_data.player_id, rewards)
		result.rewards_sent.append({"player_id": player_data.player_id, "rank": i + 1, "faction": "xian"})

	for i in range(min(3, mo_rankings.size())):
		var player_data = mo_rankings[i]
		var is_winner = (result.winner == "mo")
		var rewards = generate_ranking_rewards("mo", i + 1, is_winner)
		send_rewards_via_mail(player_data.player_id, rewards)
		result.rewards_sent.append({"player_id": player_data.player_id, "rank": i + 1, "faction": "mo"})

	return result

func generate_ranking_rewards(faction: String, rank: int, is_winner: bool) -> Dictionary:
	var rewards = {
		"title": null, 
		"chests": [], 
		"gold": 0, 
		"cultivation_pills": 0
	}

	var title = TitleDataClass.create_xianmo_title(faction, rank, is_winner, xianmo_system.global_state.week_number)
	rewards.title = title

	if is_winner:
		match rank:
			1:
				rewards.chests = ["gold", "gold"]
				rewards.gold = 500000000
				rewards.cultivation_pills = 5
			2:
				rewards.chests = ["silver", "silver"]
				rewards.gold = 300000000
				rewards.cultivation_pills = 3
			3:
				rewards.chests = ["bronze", "bronze"]
				rewards.gold = 200000000
				rewards.cultivation_pills = 2
	else:
		match rank:
			1:
				rewards.chests = ["gold"]
				rewards.gold = 300000000
				rewards.cultivation_pills = 3
			2:
				rewards.chests = ["silver"]
				rewards.gold = 200000000
				rewards.cultivation_pills = 2
			3:
				rewards.chests = ["bronze"]
				rewards.gold = 100000000
				rewards.cultivation_pills = 1

	return rewards

func generate_participation_rewards() -> Dictionary:
	return {
		"title": null, 
		"chests": ["bronze"], 
		"gold": 100000000, 
		"cultivation_pills": 1
	}

func send_rewards_via_mail(player_id: String, rewards: Dictionary):
	if not game_manager:
		return

	var title_str = ""
	if rewards.title:
		title_str = rewards.title.title_name

	var content = "恭喜你在仙魔战场中获得奖励！\n\n"
	content += "奖励内容：\n"

	if rewards.title:
		content += "- 称号：%s（7天）\n" % rewards.title.title_name
	if rewards.gold > 0:
		content += "- 金币：%d亿\n" % (rewards.gold / 100000000)
	for chest in rewards.chests:
		content += "- %s宝箱×1\n" % _get_chest_name(chest)
	if rewards.cultivation_pills > 0:
		content += "- 开悟丹×%d\n" % rewards.cultivation_pills

	content += "\n请在7天内领取，过期作废。"

	if game_manager.has_node("MailManager"):
		var mail_manager = game_manager.get_node("MailManager")
		if mail_manager.has_method("send_system_mail"):
			var attachments = {
				"gold": rewards.gold, 
				"chests": rewards.chests, 
				"cultivation_pills": rewards.cultivation_pills, 
				"title": rewards.title.to_dict() if rewards.title else null
			}
			mail_manager.send_system_mail(player_id, "仙魔战场奖励", content, attachments)

func apply_rewards_to_player(rewards: Dictionary):
	if not game_manager or not game_manager.player:
		return
	if game_manager.network and game_manager.network.is_logged_in():
		push_warning("[XianMoReward] 在线模式下禁止本地直接发放奖励，请使用服务端结算")
		return

	if rewards.title:
		game_manager.player.add_title(rewards.title)

	if rewards.gold > 0:
		game_manager.player.gold += rewards.gold

	if rewards.cultivation_pills > 0:
		if game_manager.inventory_manager:
			game_manager.inventory_manager.add_item("悟道仙丹", rewards.cultivation_pills)

	for chest in rewards.chests:
		if game_manager.xianmo_chest_manager:
			game_manager.xianmo_chest_manager.add_chest(chest)

func _get_chest_name(chest_type: String) -> String:
	match chest_type:
		"bronze": return "青铜"
		"silver": return "白银"
		"gold": return "黄金"
		_: return "未知"
