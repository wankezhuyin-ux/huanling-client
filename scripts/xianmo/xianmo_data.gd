class_name XianMoData

var faction: String = ""
var join_time: int = 0
var action_points: int = 24
var last_recover_time: int = 0
var total_score: int = 0
var weekly_score: int = 0
var events_completed: int = 0
var battles_won: int = 0
var battles_lost: int = 0
var pets_captured: int = 0
var chests_opened: int = 0
var weekly_rewards_claimed: bool = false
var treasure_fragments: int = 0
var buff_next_event_score: int = 0
var buff_attack_percent: int = 0
var week_number: int = 0

func to_dict() -> Dictionary:
	return {
		"faction": faction, 
		"join_time": join_time, 
		"action_points": action_points, 
		"last_recover_time": last_recover_time, 
		"total_score": total_score, 
		"weekly_score": weekly_score, 
		"events_completed": events_completed, 
		"battles_won": battles_won, 
		"battles_lost": battles_lost, 
		"pets_captured": pets_captured, 
		"chests_opened": chests_opened, 
		"weekly_rewards_claimed": weekly_rewards_claimed, 
		"treasure_fragments": treasure_fragments, 
		"buff_next_event_score": buff_next_event_score, 
		"buff_attack_percent": buff_attack_percent, 
		"week_number": week_number
	}

func from_dict(data: Dictionary):
	faction = data.get("faction", "")
	join_time = data.get("join_time", 0)
	action_points = data.get("action_points", 24)
	last_recover_time = data.get("last_recover_time", 0)
	total_score = data.get("total_score", 0)
	weekly_score = data.get("weekly_score", 0)
	events_completed = data.get("events_completed", 0)
	battles_won = data.get("battles_won", 0)
	battles_lost = data.get("battles_lost", 0)
	pets_captured = data.get("pets_captured", 0)
	chests_opened = data.get("chests_opened", 0)
	weekly_rewards_claimed = data.get("weekly_rewards_claimed", false)
	treasure_fragments = data.get("treasure_fragments", 0)
	buff_next_event_score = data.get("buff_next_event_score", 0)
	buff_attack_percent = data.get("buff_attack_percent", 0)
	week_number = data.get("week_number", 0)

func is_joined() -> bool:
	return not faction.is_empty()

func reset_weekly():
	weekly_score = 0
	events_completed = 0
	battles_won = 0
	battles_lost = 0
	pets_captured = 0
	chests_opened = 0
	weekly_rewards_claimed = false
	buff_next_event_score = 0
