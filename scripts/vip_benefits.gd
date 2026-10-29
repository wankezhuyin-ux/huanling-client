class_name VipBenefits
extends RefCounted

const GameData = preload("res://scripts/game_data.gd")




static func parse_expire_unix(raw: String) -> int:
	var s0: = raw.strip_edges()
	if s0.is_empty():
		return -1
	var variants: = PackedStringArray([s0])
	if not s0.contains("T") and s0.contains(" "):
		var iso_mid: = s0.replace(" ", "T")
		variants.append(iso_mid)
		variants.append(iso_mid + "Z")
	for i in variants.size():
		var s: String = variants[i]
		var u: int = int(Time.get_unix_time_from_datetime_string(s))
		if u > 946684800:
			return u
	return -1


static func is_vip_active(player: Player, current_time: int = -1) -> bool:
	if player == null or not player.is_vip or player.vip_level <= 0:
		return false
	var exp_unix: = parse_expire_unix(player.vip_expire_time_str)
	if exp_unix < 0:
		return false
	var now_ts: = current_time if current_time >= 0 else int(Time.get_unix_time_from_system())
	return exp_unix > now_ts

static func tier_from_player_data(player_data: Dictionary, current_time: int = -1) -> int:
	if player_data.is_empty():
		return 0
	var is_vip: = bool(player_data.get("is_vip", false))
	var vip_level: = int(player_data.get("vip_level", 0))
	if not is_vip or vip_level <= 0:
		return 0
	var exp_unix: = parse_expire_unix(str(player_data.get("vip_expire_time_str", "")))
	if exp_unix < 0:
		return 0
	var now_ts: = current_time if current_time >= 0 else int(Time.get_unix_time_from_system())
	if exp_unix <= now_ts:
		return 0
	return clampi(vip_level, 0, 3)

static func tier_from_player(player: Player) -> int:
	if not is_vip_active(player):
		return 0
	return clampi(player.vip_level, 0, 3)

static func exp_multiplier(tier: int) -> float:
	var t: = clampi(tier, 0, 3)
	return [1.0, 1.3, 1.6, 2.0][t]

static func elite_permille(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [5, 10, 15, 20][t]

static func max_offline_hours(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [8, 12, 16, 24][t]

static func offline_gift_chance(tier: int) -> float:
	var t: = clampi(tier, 0, 3)
	return [0.25, 0.4, 0.45, 0.5][t]

static func tower_sweep_limit(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [1, 2, 2, 3][t]

static func suit_sweeps_max(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [2, 3, 4, 5][t]

static func martial_daily_limit(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [3, 4, 5, 6][t]

static func xianmo_max_action_points(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [24, 30, 40, 48][t]


static func xianmo_recover_interval_seconds(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [60, 50, 40, 30][t] * 60

static func pet_bag_base() -> int:
	return GameData.MAX_PET_BAG

static func pet_bag_bonus(tier: int) -> int:
	var t: = clampi(tier, 0, 3)
	return [0, 0, 20, 50][t]

static func effective_pet_bag_cap(tier: int) -> int:
	return pet_bag_base() + pet_bag_bonus(tier)

static func tier_display_name(tier: int) -> String:
	match clampi(tier, 0, 3):
		1:
			return "青铜VIP"
		2:
			return "白银VIP"
		3:
			return "黄金VIP"
		_:
			return "非VIP"



static func chat_vip_prefix_bbcode(vip_level: int, legacy_is_vip: bool = false) -> String:
	var t: = clampi(vip_level, 0, 3)
	if t >= 1 and t <= 3:
		return "[color=gold]VIP%d[/color] " % t
	if legacy_is_vip:
		return "[color=gold]VIP1[/color] "
	return ""
