extends Node
class_name Player

const GameData = preload("res://scripts/game_data.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")
const TitleDataClass = preload("res://scripts/title/title_data.gd")
const FabaoStatBonus = preload("res://scripts/fabao/fabao_stat_bonus.gd")


var player_name: String = "江小湖"
var level: int = 1
var experience: int = 0
var max_hp: int = 100
var hp: int = 100
var max_mp: int = 100
var mp: int = 100


var vitality: int = 10
var magic: int = 10
var attack_base: int = 10
var defense_base: int = 10
var agility_base: int = 10


var realm: String = "凡人"
var cultivation: int = 0
var reincarnation: int = 0
var friendship_points: int = 0
var cultivation_pills_used: int = 0
const MAX_CULTIVATION_PILLS_PER_LIFE: int = 5


var points: int = 20
var permanent_points: int = 0


var talent_attack: int = 0
var talent_defense: int = 0
var talent_agility: int = 0
var talent_hp: int = 0


var auto_allocation_enabled: bool = false
var pending_auto_points: int = 0
var auto_allocation_plan: Dictionary = {
	"vitality": 0, 
	"attack": 0, 
	"defense": 0, 
	"magic": 0, 
	"agility": 0
}
const AUTO_ALLOCATE_THRESHOLD: int = 100
const ATTR_RESET_GUARD_SPAN: int = 20
var attr_reset_guard_level: int = 0


var element: String = "普通"

var use_fabao_player_element: bool = true


const BATTLE_STANCE_ATTACK: = "attack"
const BATTLE_STANCE_DEFEND: = "defend"
var battle_stance_player: String = BATTLE_STANCE_ATTACK
var battle_stance_pet: String = BATTLE_STANCE_ATTACK


var player_character_id: int = 0


var gold: int = 0
var yuanbao_currency: int = 0


var is_vip: bool = false
var vip_level: int = 0
var vip_expire_time_str: String = ""
var double_exp_until: int = 0

# 三种双倍经验丹各自独立计时（服务端权威）：{"双倍经验丹": ts, "双倍经验丹(周)": ts, "双倍经验丹(月)": ts}
# 参考稿是「三种可以同时生效、时效分开算」，每多一种生效再加 100% 经验。
# 老存档 / 老服务端没有这个字段时回退到 double_exp_until 的单通道口径。
var double_exp_channels: Dictionary = {}

var double_exp_auto_realm_enabled: bool = false

## 本次会话里玩家是否亲手勾/取消过「双倍经验丹权益（自动飞升/投胎）」。
##
## 这个开关是**纯客户端偏好**：服务端既不用它结算、也没有校验逻辑，
## 只是跟着整包存档原样存、原样回（见 handlers_account.save_upload）。
## 于是回包里带的经常是「玩家勾选之前那一版快照」的 false ——
## player.from_dict / sync_player_authoritative_vip_double_exp_from_dict
## 一覆盖，面板上刚打上的勾几秒就自己弹回去，自动飞升/投胎永远走不到。
## 玩家亲手改过之后就以本地为准，本次会话内不再接受云端回写。
var _auto_realm_pref_edited: bool = false
## 这一项是否已经从存档里取过初值。
## 取过之后就锁住：运行期所有整包 from_dict（云端权威回包、离线结算、
## 战斗结算回包）都只当它是噪声，不再覆盖 —— 否则玩家每次登录都会被
## 服务端那份「还没收到新偏好」的旧快照打回 false。
var _auto_realm_pref_loaded: bool = false

func mark_auto_realm_pref_edited() -> void:
	_auto_realm_pref_edited = true
	_auto_realm_pref_loaded = true

func is_auto_realm_pref_locked() -> bool:
	return _auto_realm_pref_edited or _auto_realm_pref_loaded

## 存档里的 double_exp_auto_realm_enabled 只在「首次加载」时采纳。
## 返回 true 表示这次采纳了。
##
## raw 为 null 表示这份存档**根本没有这一项**（服务端自己重建的 playerData
## 就没有它，只有客户端整包上传过的存档才有）。这时既不能拿默认 false 覆盖
## 本地已有的 true，也不能把闸门锁死 —— 否则登录时先来一份精简云端数据，
## 玩家上次勾好的开关就被当成「没开过」。
func apply_auto_realm_pref_once(raw: Variant) -> bool:
	if _auto_realm_pref_edited or _auto_realm_pref_loaded:
		return false
	if raw == null:
		return false
	double_exp_auto_realm_enabled = coerce_bool(raw, false)
	_auto_realm_pref_loaded = true
	return true

var newbie_exp_until: int = 0

var catchup_first_reincarnation: int = 0
var catchup_gap: int = 0
var catchup_field_max_level_ups: int = 1
var catchup_day: String = ""
var catchup_enabled: bool = false


var titles: Array = []
var active_title_id: String = ""


var tower_floor: int = 1
var tower_highest: int = 0
var tower_sweep_count: int = 0


var suit_dungeon_progress: int = 0
var suit_dungeon_sweeps: int = 3
var five_elements_dungeon_attempts: int = 0
var fe_yuanbao_attempts: int = 0
var fe_yuanbao_attempts_date: String = ""


var recent_maps: Array = []
const MAX_RECENT_MAPS: int = 16


func get_max_suit_dungeon_sweeps() -> int:
	var tier: = VipBenefits.tier_from_player(self)
	return VipBenefits.suit_sweeps_max(tier)


signal level_up(new_level: int)
signal exp_changed(new_exp: int, required_exp: int)
signal hp_changed(new_hp: int, max_hp: int)
signal realm_changed(new_realm: String)

func _init():
	update_derived_stats()

func get_title_bonus(stat_type: String) -> int:
	if active_title_id.is_empty():
		return 0
	for title in titles:
		if title is TitleDataClass and title.title_id == active_title_id and not title.is_expired():
			return title.get_bonus(stat_type)
	return 0

func get_active_title():
	if active_title_id.is_empty():
		return null
	for title in titles:
		if title is TitleDataClass and title.title_id == active_title_id and not title.is_expired():
			return title
	return null

func get_active_title_name() -> String:
	var title = get_active_title()
	if title:
		return title.title_name
	return ""


func repair_active_title_reference_after_load() -> void :
	if get_active_title() != null:
		return

	if active_title_id.is_empty():
		return
	active_title_id = ""
	for t in titles:
		if t is TitleDataClass and str(t.source) == "xianmo" and not t.is_expired():
			active_title_id = t.title_id
			return
	for t in titles:
		if t is TitleDataClass and not t.is_expired():
			active_title_id = t.title_id
			return

func add_title(title):
	for existing in titles:
		if existing is TitleDataClass and existing.title_id == title.title_id:
			existing.expire_time = title.expire_time
			return
	titles.append(title)

func remove_expired_titles():
	var valid_titles = []
	for title in titles:
		if title is TitleDataClass and not title.is_expired():
			valid_titles.append(title)
		elif title is TitleDataClass and title.title_id == active_title_id:
			active_title_id = ""
	titles = valid_titles

func activate_title(title_id: String) -> bool:
	for title in titles:
		if title is TitleDataClass and title.title_id == title_id and not title.is_expired():
			active_title_id = title_id
			return true
	return false

func deactivate_title():
	active_title_id = ""


func merge_xianmo_titles_from_cloud_player_dict(pd: Dictionary) -> void :
	if pd == null or not pd is Dictionary:
		return
	if not pd.has("titles"):
		return
	var cloud_titles_raw = pd.get("titles", [])
	if not cloud_titles_raw is Array:
		return
	var kept: Array = []
	for t in titles:
		if t is TitleDataClass and t.source != "xianmo":
			kept.append(t)
	titles = kept
	for td in cloud_titles_raw:
		if not td is Dictionary:
			continue
		if str(td.get("source", "")) != "xianmo":
			continue
		var title = TitleDataClass.new()
		title.from_dict(td)
		if not title.is_expired():
			add_title(title)
	var aid = str(pd.get("active_title_id", "")).strip_edges()
	if not aid.is_empty():
		activate_title(aid)
	if active_title_id.is_empty():
		for t in titles:
			if t is TitleDataClass and t.source == "xianmo" and not t.is_expired():
				activate_title(t.title_id)
				break
	remove_expired_titles()
	repair_active_title_reference_after_load()
	update_derived_stats()
	if GameManager.instance and GameManager.instance.title_manager:
		GameManager.instance.title_manager.titles_updated.emit()


func _get_bt_snapshot_stat(key: String) -> int:
	if not has_meta("bt_snapshot_stats"):
		return -1
	var stats = get_meta("bt_snapshot_stats")
	if stats is Dictionary and stats.has(key):
		return int(stats[key])
	return -1

func get_attack() -> int:
	var snap_atk: = _get_bt_snapshot_stat("attack")
	if snap_atk >= 0:
		return snap_atk
	var base = 10 + attack_base

	if GameManager.instance and GameManager.instance.equipment_manager:
		var equip_stats = GameManager.instance.equipment_manager.get_total_stats()
		base += equip_stats.attack

	if GameManager.instance and GameManager.instance.suit_manager:
		var set_bonus = GameManager.instance.suit_manager.calculate_total_set_bonus()
		base += set_bonus.attack

	var pct: float = 0.0
	if GameManager.instance and GameManager.instance.martial_arts_manager:
		var effects = GameManager.instance.martial_arts_manager.get_equipped_effects()
		pct += effects.all_stats / 100.0
		pct += effects.attack / 100.0
	if GameManager.instance and GameManager.instance.gang_manager:
		pct += GameManager.instance.gang_manager.get_buff_percent("attack") / 100.0
	pct += FabaoStatBonus.player_pct("atk") / 100.0
	base = int(base * (1.0 + pct))
	base += get_title_bonus("attack")
	return base

func get_defense() -> int:
	var snap_def: = _get_bt_snapshot_stat("defense")
	if snap_def >= 0:
		return snap_def
	var base = 10 + defense_base

	if GameManager.instance and GameManager.instance.equipment_manager:
		var equip_stats = GameManager.instance.equipment_manager.get_total_stats()
		base += equip_stats.defense

	if GameManager.instance and GameManager.instance.suit_manager:
		var set_bonus = GameManager.instance.suit_manager.calculate_total_set_bonus()
		base += set_bonus.defense

	var pct: float = 0.0
	if GameManager.instance and GameManager.instance.martial_arts_manager:
		var effects = GameManager.instance.martial_arts_manager.get_equipped_effects()
		pct += effects.all_stats / 100.0
		pct += effects.defense / 100.0
	if GameManager.instance and GameManager.instance.gang_manager:
		pct += GameManager.instance.gang_manager.get_buff_percent("defense") / 100.0
	pct += FabaoStatBonus.player_pct("def") / 100.0
	base = int(base * (1.0 + pct))
	base += get_title_bonus("defense")
	return base

func get_agility() -> int:
	var snap_agi: = _get_bt_snapshot_stat("agility")
	if snap_agi >= 0:
		return snap_agi
	var base = 10 + agility_base

	if GameManager.instance and GameManager.instance.equipment_manager:
		var equip_stats = GameManager.instance.equipment_manager.get_total_stats()
		base += equip_stats.agility

	if GameManager.instance and GameManager.instance.suit_manager:
		var set_bonus = GameManager.instance.suit_manager.calculate_total_set_bonus()
		base += set_bonus.agility

	var pct: float = 0.0
	if GameManager.instance and GameManager.instance.martial_arts_manager:
		var effects = GameManager.instance.martial_arts_manager.get_equipped_effects()
		pct += effects.all_stats / 100.0
		pct += effects.agility / 100.0
	if GameManager.instance and GameManager.instance.gang_manager:
		pct += GameManager.instance.gang_manager.get_buff_percent("agility") / 100.0
	pct += FabaoStatBonus.player_pct("agi") / 100.0
	base = int(base * (1.0 + pct))
	base += get_title_bonus("agility")
	return base

func get_max_hp() -> int:
	var snap_hp: = _get_bt_snapshot_stat("max_hp")
	if snap_hp >= 0:
		return maxi(1, snap_hp)
	var base = max_hp + (vitality * 10)

	if GameManager.instance and GameManager.instance.equipment_manager:
		var equip_stats = GameManager.instance.equipment_manager.get_total_stats()
		base += equip_stats.hp

	if GameManager.instance and GameManager.instance.suit_manager:
		var set_bonus = GameManager.instance.suit_manager.calculate_total_set_bonus()
		base += set_bonus.hp

	var pct: float = 0.0
	if GameManager.instance and GameManager.instance.martial_arts_manager:
		var effects = GameManager.instance.martial_arts_manager.get_equipped_effects()
		pct += effects.hp / 100.0
	if GameManager.instance and GameManager.instance.gang_manager:
		pct += GameManager.instance.gang_manager.get_buff_percent("hp") / 100.0
	pct += FabaoStatBonus.player_pct("hp") / 100.0
	base = int(base * (1.0 + pct))
	base += get_title_bonus("hp")
	return max(1, base)

func get_max_mp() -> int:
	var snap_mp: = _get_bt_snapshot_stat("max_mp")
	if snap_mp >= 0:
		return maxi(0, snap_mp)
	var base = max_mp + (magic * 10)


	if GameManager.instance and GameManager.instance.equipment_manager:
		var equip_stats = GameManager.instance.equipment_manager.get_total_stats()
		base += equip_stats.mp


	if GameManager.instance and GameManager.instance.suit_manager:
		var set_bonus = GameManager.instance.suit_manager.calculate_total_set_bonus()
		base += set_bonus.mp


	if GameManager.instance and GameManager.instance.martial_arts_manager:
		var effects = GameManager.instance.martial_arts_manager.get_equipped_effects()
		var mp_percent = effects.mp / 100.0
		base = int(base * (1 + mp_percent))
	return max(0, base)

func update_derived_stats():
	pass


func get_points_per_level() -> int:
	match realm:
		"凡人", "散仙":
			return 3
		"地仙", "天仙":
			return 4
		"大罗金仙", "幻灵天神":
			return 5
		_:
			return 3


func is_double_exp_active(current_time: int = -1) -> bool:
	var now_ts: = current_time if current_time >= 0 else int(Time.get_unix_time_from_system())
	if double_exp_until > now_ts:
		return true
	# 多通道（日/周/月丹）生效时只看 double_exp_until 会漏判：那条字段是
	# 「最晚到期时间」的缓存，本地/老存档里可能还没同步，通道里其实是有丹的。
	for key in double_exp_channels.keys():
		if int(double_exp_channels[key]) > now_ts:
			return true
	return false

func get_double_exp_channel_count(current_time: int = -1) -> int:
	var now_ts: = current_time if current_time >= 0 else int(Time.get_unix_time_from_system())
	if not double_exp_channels.is_empty():
		var active: = 0
		for key in double_exp_channels.keys():
			if int(double_exp_channels[key]) > now_ts:
				active += 1
		return active
	return 1 if double_exp_until > now_ts else 0

func is_newbie_exp_active(current_time: int = -1) -> bool:
	var now_ts: = current_time if current_time >= 0 else int(Time.get_unix_time_from_system())
	return newbie_exp_until > now_ts

func get_field_max_level_ups() -> int:
	if not catchup_enabled:
		return 1
	return clampi(catchup_field_max_level_ups, 1, 10)


func get_total_exp_multiplier(current_time: int = -1, include_newbie: bool = false) -> float:
	var tier: = VipBenefits.tier_from_player(self)
	var vip_mult: = VipBenefits.exp_multiplier(tier)
	var gang_bonus: = 0.0
	var noble_bonus: = 0.0
	if GameManager.instance:
		gang_bonus = GameManager.instance.get_gang_exp_bonus_percent() / 100.0
		if GameManager.instance.has_method("get_noble_exp_bonus_percent"):
			noble_bonus = GameManager.instance.get_noble_exp_bonus_percent() / 100.0
	var mult: = vip_mult + gang_bonus + noble_bonus
	if GameManager.instance != null and GameManager.instance.has_method("local_double_exp_count"):
		mult += float(GameManager.instance.local_double_exp_count(current_time))
	else:
		mult += float(get_double_exp_channel_count(current_time))
	if include_newbie and is_newbie_exp_active(current_time):
		mult += 1.0
	return mult * FabaoStatBonus.exp_multiplier()

func add_exp(amount: int, allow_multiple_levels: bool = true, include_newbie_bonus: bool = false, max_level_ups: int = 1, apply_multiplier: bool = true) -> Array:
	var messages = []
	var final_exp = amount
	var now_ts: = int(Time.get_unix_time_from_system())
	var tier: = VipBenefits.tier_from_player(self)
	var vip_mult: = VipBenefits.exp_multiplier(tier)
	var mult: = get_total_exp_multiplier(now_ts, include_newbie_bonus)
	if apply_multiplier and mult > 1.0001:
		final_exp = int(round(amount * mult))
		var vip_pct: = int(round((vip_mult - 1.0) * 100.0))
		if is_double_exp_active(now_ts):
			if vip_pct > 0:
				messages.append("[color=gold]VIP加成：经验 +%d%%![/color]" % vip_pct)
			# 一种丹 +100%、两种 +200%、三种 +300%（与服务端 exp_multiplier 同口径）。
			var pill_count: = 0
			if GameManager.instance != null and GameManager.instance.has_method("local_double_exp_count"):
				pill_count = int(GameManager.instance.local_double_exp_count(now_ts))
			else:
				pill_count = int(get_double_exp_channel_count(now_ts))
			pill_count = maxi(1, pill_count)
			var pill_suffix: String = ""
			if pill_count > 1:
				pill_suffix = "（%d种叠加）" % pill_count
			messages.append("[color=orange]双倍经验丹生效：经验 +%d%%!%s[/color]" % [pill_count * 100, pill_suffix])
		elif vip_pct > 0:
			messages.append("[color=gold]VIP加成：经验 +%d%%![/color]" % vip_pct)


	messages.append("获得 [color=cyan]%d[/color] 点经验！" % final_exp)
	experience += final_exp

	var required = GameData.get_required_exp(level)
	exp_changed.emit(experience, required)


	if allow_multiple_levels:

		while level < GameData.MAX_LEVEL_EVOLUTION and experience >= required:
			experience -= required
			level += 1

			var points_per_level = get_points_per_level()


			if auto_allocation_enabled:
				pending_auto_points += points_per_level
			else:
				points += points_per_level


			var _old_hp_cap: = get_max_hp()
			max_hp += 5
			var _new_hp_cap: = get_max_hp()
			hp = clampi(hp + (_new_hp_cap - _old_hp_cap), 0, _new_hp_cap)


			if realm in ["地仙", "天仙", "大罗金仙", "幻灵天神"]:
				cultivation += 1
				messages.append("获得1点修行值！当前修行值：%d" % cultivation)

			messages.append("你升级到 %d 级！获得%d点属性点！" % [level, points_per_level])
			level_up.emit(level)
			required = GameData.get_required_exp(level)
			exp_changed.emit(experience, required)
			update_derived_stats()
	else:

		var field_cap: = clampi(max_level_ups, 1, 10)
		var ups: = 0
		while level < GameData.MAX_LEVEL_EVOLUTION and experience >= required and ups < field_cap:
			experience -= required
			level += 1
			ups += 1
			var points_per_level = get_points_per_level()
			if auto_allocation_enabled:
				pending_auto_points += points_per_level
			else:
				points += points_per_level
			var _old_hp_cap2: = get_max_hp()
			max_hp += 5
			var _new_hp_cap2: = get_max_hp()
			hp = clampi(hp + (_new_hp_cap2 - _old_hp_cap2), 0, _new_hp_cap2)
			if realm in ["地仙", "天仙", "大罗金仙", "幻灵天神"]:
				cultivation += 1
				messages.append("获得1点修行值！当前修行值：%d" % cultivation)
			messages.append("你升级到 %d 级！获得%d点属性点！" % [level, points_per_level])
			level_up.emit(level)
			required = GameData.get_required_exp(level)
			exp_changed.emit(experience, required)
			update_derived_stats()
		if ups > 0:
			experience = 0
			exp_changed.emit(experience, required)
		else:
			var cap: = maxi(0, required - 1)
			if experience > cap:
				experience = cap
				exp_changed.emit(experience, required)

	_clamp_experience_at_max_level()
	return messages

func _clamp_experience_at_max_level() -> void :
	if level < GameData.MAX_LEVEL_EVOLUTION:
		return
	var cap: = GameData.get_required_exp(level)
	if cap < 1:
		return
	if experience > cap:
		experience = cap
		exp_changed.emit(experience, cap)

func get_required_exp() -> int:
	return GameData.get_required_exp(level)

func get_exp_percent() -> float:
	var req: = get_required_exp()
	if req < 1:
		return 1.0
	return clampf(float(experience) / float(req), 0.0, 1.0)


var _attr_mutation_allowed: bool = false

func set_attr_mutation_allowed(allowed: bool) -> void :
	_attr_mutation_allowed = allowed

func add_vitality() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		vitality += 1
		return true
	return false

func add_magic() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		magic += 1
		return true
	return false

func add_attack() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		attack_base += 1
		return true
	return false

func add_defense() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		defense_base += 1
		return true
	return false

func add_agility() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		agility_base += 1
		return true
	return false

func add_hp() -> bool:
	if not _attr_mutation_allowed:
		return false
	if points > 0:
		points -= 1
		max_hp += 10
		hp += 10
		return true
	return false


func _route_points_to_pending_auto_if_enabled() -> void :
	"自动加点开启时，将当前可用点并入待自动分配池"
	if not auto_allocation_enabled or points <= 0:
		return
	pending_auto_points += points
	points = 0

func on_level_up_for_auto_allocate() -> Array:
	"升级时调用，检查是否达到阈值执行批量加点"
	var messages = []
	if not auto_allocation_enabled or pending_auto_points == 0:
		return messages

	if pending_auto_points >= AUTO_ALLOCATE_THRESHOLD:
		return auto_allocate_pending_points()

	return messages

func _auto_allocation_plan_total() -> int:
	return int(auto_allocation_plan.get("vitality", 0)) + int(auto_allocation_plan.get("attack", 0)) + \
	int(auto_allocation_plan.get("defense", 0)) + int(auto_allocation_plan.get("magic", 0)) + \
	int(auto_allocation_plan.get("agility", 0))

func _spend_points_by_auto_plan(budget: int) -> int:
	var total_plan: int = _auto_allocation_plan_total()
	if total_plan <= 0 or total_plan > 10 or budget <= 0:
		return 0

	var spent: int = 0
	var cycles: int = int(budget / total_plan)
	for _i in range(cycles):
		for _j in range(auto_allocation_plan.vitality):
			if add_vitality():
				spent += 1
		for _j in range(auto_allocation_plan.attack):
			if add_attack():
				spent += 1
		for _j in range(auto_allocation_plan.defense):
			if add_defense():
				spent += 1
		for _j in range(auto_allocation_plan.magic):
			if add_magic():
				spent += 1
		for _j in range(auto_allocation_plan.agility):
			if add_agility():
				spent += 1
	return spent

func auto_allocate_pending_points() -> Array:
	"执行批量加点（仅服务端 slice 写回或离线调试；UI 须走 RPC）"
	var messages = []
	if not _attr_mutation_allowed:
		return messages
	if not auto_allocation_enabled or pending_auto_points == 0:
		return messages

	var total_plan: int = _auto_allocation_plan_total()


	if total_plan == 0 or total_plan > 10:
		return messages

	var points_to_allocate: int = pending_auto_points
	var full_budget: int = int(points_to_allocate / total_plan) * total_plan
	if full_budget <= 0:
		return messages

	pending_auto_points = points_to_allocate - full_budget
	points += full_budget

	var allocated_count: int = _spend_points_by_auto_plan(full_budget)
	var unspent: int = full_budget - allocated_count
	if unspent > 0:
		pending_auto_points += unspent
		points -= unspent

	if allocated_count > 0:
		var cycles: int = int(full_budget / total_plan)
		messages.append("[color=green]自动分配了 %d 点属性（%d轮方案）[/color]" % [allocated_count, cycles])

	return messages


func _reset_allocated_stats_for_level_one(options: Dictionary = {}) -> void :
	var permanent_delta: int = int(options.get("permanent_delta", 0))
	var reset_cultivation_pills: bool = coerce_bool(options.get("reset_cultivation_pills", false), false)
	if permanent_delta > 0:
		permanent_points += permanent_delta
	level = 1
	experience = 0
	if reset_cultivation_pills:
		cultivation_pills_used = 0
	points = 20 + permanent_points
	pending_auto_points = 0
	_route_points_to_pending_auto_if_enabled()
	vitality = 10
	magic = 10
	attack_base = 10
	defense_base = 10
	agility_base = 10
	max_hp = 100
	hp = max_hp
	max_mp = 100
	mp = max_mp
	attr_reset_guard_level = 1 + ATTR_RESET_GUARD_SPAN
	exp_changed.emit(experience, GameData.get_required_exp(level))

func _attr_point_total_accounting() -> int:
	var invested: int = points + pending_auto_points
	for key in ["vitality", "magic", "attack_base", "defense_base", "agility_base"]:
		invested += maxi(0, int(get(key)) - 10)
	var floor_hp: int = 100 + 5 * maxi(0, level - 1)
	invested += int(maxi(0, max_hp - floor_hp) / 10)
	return invested

func _reset_allocated_stats_for_current_level() -> void :
	var perm: int = GameData.permanent_points_floor(reincarnation)
	permanent_points = perm
	vitality = 10
	magic = 10
	attack_base = 10
	defense_base = 10
	agility_base = 10
	var floor_hp: int = 100 + 5 * maxi(0, level - 1)
	max_hp = floor_hp
	hp = mini(hp, max_hp)
	pending_auto_points = 0
	points = 20 + perm + maxi(0, level - 1) * get_points_per_level()
	_route_points_to_pending_auto_if_enabled()


func repair_permanent_points_from_reincarnation() -> int:
	var rei_floor: int = GameData.permanent_points_floor(reincarnation)
	if permanent_points == rei_floor:
		return 0
	var old_perm: int = permanent_points
	if permanent_points < rei_floor:
		var delta: int = rei_floor - permanent_points
		permanent_points = rei_floor
		var budget_floor: int = 20 + rei_floor + maxi(0, level - 1) * get_points_per_level()
		var pool_invested: int = _attr_point_total_accounting()
		if pool_invested >= budget_floor - 5:
			return delta
		points += delta
		_route_points_to_pending_auto_if_enabled()
		return delta
	permanent_points = rei_floor
	var remain: int = old_perm - rei_floor
	if pending_auto_points > 0 and remain > 0:
		var cut_p: int = mini(pending_auto_points, remain)
		pending_auto_points -= cut_p
		remain -= cut_p
	if points > 0 and remain > 0:
		var cut_u: int = mini(points, remain)
		points -= cut_u
		remain -= cut_u
	var budget_after: int = 20 + rei_floor + maxi(0, level - 1) * get_points_per_level()
	if _attr_point_total_accounting() > budget_after + 5:
		_reset_allocated_stats_for_current_level()
	return rei_floor - old_perm

func get_talent_points_earned() -> int:
	return GameData.talent_points_earned(reincarnation)

func get_talent_allocated_sum() -> int:
	return talent_attack + talent_defense + talent_agility + talent_hp

func get_talent_points_unspent() -> int:
	return maxi(0, get_talent_points_earned() - get_talent_allocated_sum())

func get_talent_percent(stat_key: String) -> float:
	var k: = str(stat_key).strip_edges().to_lower()
	var pts: = 0
	match k:
		"attack":
			pts = talent_attack
		"defense":
			pts = talent_defense
		"agility":
			pts = talent_agility
		"hp", "max_hp":
			pts = talent_hp
		_:
			pts = 0
	return float(clampi(pts, 0, GameData.TALENT_MAX_PER_STAT)) / 100.0

func clamp_talent_allocation_to_earned() -> void :
	var earned: = get_talent_points_earned()
	talent_attack = clampi(talent_attack, 0, GameData.TALENT_MAX_PER_STAT)
	talent_defense = clampi(talent_defense, 0, GameData.TALENT_MAX_PER_STAT)
	talent_agility = clampi(talent_agility, 0, GameData.TALENT_MAX_PER_STAT)
	talent_hp = clampi(talent_hp, 0, GameData.TALENT_MAX_PER_STAT)
	var over: = get_talent_allocated_sum() - earned
	if over <= 0:
		return
	for key in ["talent_hp", "talent_agility", "talent_defense", "talent_attack"]:
		if over <= 0:
			break
		var cur: int = int(get(key))
		var cut: int = mini(cur, over)
		set(key, cur - cut)
		over -= cut

func apply_talent_allocation(attack_v: int, defense_v: int, agility_v: int, hp_v: int) -> Dictionary:
	var next_atk: = clampi(attack_v, 0, GameData.TALENT_MAX_PER_STAT)
	var next_def: = clampi(defense_v, 0, GameData.TALENT_MAX_PER_STAT)
	var next_agi: = clampi(agility_v, 0, GameData.TALENT_MAX_PER_STAT)
	var next_hp: = clampi(hp_v, 0, GameData.TALENT_MAX_PER_STAT)
	var need: = next_atk + next_def + next_agi + next_hp
	var earned: = get_talent_points_earned()
	if need > earned:
		return {"ok": false, "error": "天赋点不足（已获%d，需要%d）" % [earned, need]}
	talent_attack = next_atk
	talent_defense = next_def
	talent_agility = next_agi
	talent_hp = next_hp
	return {"ok": true, "earned": earned, "unspent": earned - need}

func reset_talent_allocation() -> void :
	talent_attack = 0
	talent_defense = 0
	talent_agility = 0
	talent_hp = 0

func get_total_pending_points() -> int:
	"获取待分配的总点数（可用点数 + 待自动分配点数）"
	return points + pending_auto_points


func can_ascend(element_collection: Dictionary = {}) -> Dictionary:
	return GameData.can_ascend(realm, level, element_collection)

func ascend(element_collection: Dictionary = {}) -> Dictionary:
	var result = {"success": false, "message": "", "poem": ""}

	var ascend_check = can_ascend(element_collection)
	if not ascend_check.can_ascend:
		if ascend_check.missing_elements.size() > 0:
			var msg = "五行图鉴不足，飞升大罗金仙需要每个属性至少10个图鉴：\n"
			for m in ascend_check.missing_elements:
				msg += "  %s属性: %d/%d\n" % [m.element, m.current, m.required]
			result.message = msg
		else:
			result.message = ascend_check.reason
		return result

	var next_realm = GameData.get_next_realm(realm)
	if next_realm.is_empty():
		result.message = "已经达到最高境界！"
		return result

	var old_realm = realm
	realm = next_realm
	_reset_allocated_stats_for_level_one()
	update_derived_stats()
	realm_changed.emit(realm)

	var ascension_poems = {
		"散仙": "道，可道，非恒道。名，可名，非恒名。\n无名，天地之始；有名，万物之母。故常无欲，以观其妙；常有欲，以观其徼。此两者同出而异名，同谓之玄。玄之又玄，众妙之门。", 
		"地仙": "受天地之气，得日月之精，历岁久远，化而为人。\n放大智光明，照十方世界，地涌金莲华，丈六金身，能变能化，无大无不大，无通无不通，普度众生，号作地仙。", 
		"天仙": "克纯克纯，无地非天，常真真常，玄之又玄。\n绵绵密密，道无不圆，功造其极，我即佛仙。", 
		"大罗金仙": "悉除一切恶道苦，等与一切众生乐，如是经於刹尘劫，十方利益恒无尽。", 
		"幻灵天神": "SPECIAL"
	}

	result.success = true
	if realm == "幻灵天神":
		result.poem = "SPECIAL"
		result.message = player_name
	else:
		result.poem = ascension_poems.get(realm, "")
		result.message = ""
	return result

func can_reincarnate() -> bool:
	return realm == "幻灵天神" and level >= GameData.MAX_LEVEL_EVOLUTION and reincarnation < GameData.MAX_PLAYER_REINCARNATION

func reincarnate() -> Dictionary:
	var result = {"success": false, "message": "", "poem": ""}

	if realm != "幻灵天神":
		result.message = "只有幻灵天神才能投胎！"
		return result

	if level < GameData.MAX_LEVEL_EVOLUTION:
		result.message = "等级不足，需要达到%d级才能投胎！" % GameData.MAX_LEVEL_EVOLUTION
		return result

	if reincarnation >= GameData.MAX_PLAYER_REINCARNATION:
		result.message = "已经达到最大投胎次数！"
		return result

	reincarnation += 1
	realm = "凡人"

	var perm_delta: int = GameData.permanent_delta_on_reincarnate(reincarnation)
	_reset_allocated_stats_for_level_one({"permanent_delta": perm_delta, "reset_cultivation_pills": true})
	update_derived_stats()
	realm_changed.emit(realm)

	result.success = true
	result.poem = "SPECIAL"
	result.message = player_name
	result.permanent_delta = perm_delta
	return result


func take_damage(damage: int) -> int:
	var actual_damage = max(1, damage - get_defense() / 2)
	hp = max(0, hp - actual_damage)
	hp_changed.emit(hp, get_max_hp())
	return actual_damage

func heal(amount: int):
	hp = min(get_max_hp(), hp + amount)
	hp_changed.emit(hp, get_max_hp())

func heal_percent(percent: float):
	heal(int(get_max_hp() * percent))

func heal_full():
	hp = get_max_hp()
	mp = get_max_mp()
	hp_changed.emit(hp, get_max_hp())

func is_alive() -> bool:
	return hp > 0

func get_hp_percent() -> float:
	return float(hp) / max_hp

func normalize_battle_stance(v) -> String:
	return BATTLE_STANCE_DEFEND if str(v) == BATTLE_STANCE_DEFEND else BATTLE_STANCE_ATTACK

func clamp_battle_stances() -> void :
	battle_stance_player = normalize_battle_stance(battle_stance_player)
	battle_stance_pet = normalize_battle_stance(battle_stance_pet)
	if battle_stance_player == BATTLE_STANCE_DEFEND and battle_stance_pet == BATTLE_STANCE_DEFEND:
		battle_stance_pet = BATTLE_STANCE_ATTACK


func set_battle_stance(side: String, stance: String) -> bool:
	var next_stance: = normalize_battle_stance(stance)
	var switched_other: = false
	if str(side) == "pet":
		if next_stance == BATTLE_STANCE_DEFEND and battle_stance_player == BATTLE_STANCE_DEFEND:
			battle_stance_player = BATTLE_STANCE_ATTACK
			switched_other = true
		battle_stance_pet = next_stance
	else:
		if next_stance == BATTLE_STANCE_DEFEND and battle_stance_pet == BATTLE_STANCE_DEFEND:
			battle_stance_pet = BATTLE_STANCE_ATTACK
			switched_other = true
		battle_stance_player = next_stance
	clamp_battle_stances()
	return switched_other


func to_dict() -> Dictionary:
	clamp_battle_stances()
	var result: = {
		"name": player_name, 
		"level": level, 
		"experience": experience, 
		"hp": hp, 
		"max_hp": max_hp, 
		"mp": mp, 
		"max_mp": max_mp, 
		"vitality": vitality, 
		"magic": magic, 
		"attack_base": attack_base, 
		"defense_base": defense_base, 
		"agility_base": agility_base, 
		"final_attack": get_attack(), 
		"final_defense": get_defense(), 
		"final_agility": get_agility(), 
		"final_max_hp": get_max_hp(), 
		"final_max_mp": get_max_mp(), 
		"realm": realm, 
		"cultivation": cultivation, 
		"reincarnation": reincarnation, 
		"friendship_points": friendship_points, 
		"cultivation_pills_used": cultivation_pills_used, 
		"points": points, 
		"permanent_points": permanent_points, 
		"talent_attack": talent_attack, 
		"talent_defense": talent_defense, 
		"talent_agility": talent_agility, 
		"talent_hp": talent_hp, 
		"element": element, 
		"use_fabao_player_element": use_fabao_player_element, 
		"battle_stance_player": battle_stance_player, 
		"battle_stance_pet": battle_stance_pet, 
		"gold": gold, 
		"yuanbao_currency": yuanbao_currency, 
		"is_vip": is_vip, 
		"vip_level": vip_level, 
		"vip_expire_time_str": vip_expire_time_str, 
		"double_exp_until": double_exp_until, 
		"double_exp_channels": double_exp_channels, 
		"double_exp_auto_realm_enabled": double_exp_auto_realm_enabled, 
		"tower_floor": tower_floor, 
		"tower_highest": tower_highest, 
		"tower_sweep_count": tower_sweep_count, 
		"suit_dungeon_progress": suit_dungeon_progress, 
		"suit_dungeon_sweeps": suit_dungeon_sweeps, 
		"five_elements_dungeon_attempts": five_elements_dungeon_attempts, 
		"fe_yuanbao_attempts": fe_yuanbao_attempts, 
		"fe_yuanbao_attempts_date": fe_yuanbao_attempts_date, 
		"auto_allocation_enabled": auto_allocation_enabled, 
		"pending_auto_points": pending_auto_points, 
		"auto_allocation_plan": auto_allocation_plan, 
		"titles": _serialize_titles(), 
		"active_title_id": active_title_id, 
		"recent_maps": recent_maps, 
		"player_character_id": player_character_id, 
	}
	if attr_reset_guard_level > 0:
		result["attr_reset_guard_level"] = attr_reset_guard_level
	return result

func _serialize_titles() -> Array:
	var result = []
	for title in titles:
		if title is TitleDataClass:
			result.append(title.to_dict())
	return result

static func coerce_bool(value: Variant, default_value: bool) -> bool:
	# 存档字段是外部数据（服务端/旧版本/本地 pending 合并都可能是脏的），
	# 裸 bool(v) 遇到 Dictionary/Array 会直接抛 "Nonexistent 'bool' constructor"，
	# 那个错误会打断整个登录初始化（黑屏），所以统一走这个安全转换。
	if value is bool:
		return value
	if value is int:
		return int(value) != 0
	if value is float:
		return float(value) != 0.0
	if value is String:
		var text: = str(value).strip_edges().to_lower()
		return text == "true" or text == "1"
	if value == null:
		return default_value
	push_warning("[Player] coerce_bool 收到无法识别的类型 %d，使用默认值 %s" % [typeof(value), str(default_value)])
	return default_value


func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return

	player_name = data.get("name", "江小湖")
	level = data.get("level", 1)
	if data.has("experience"):
		experience = data.get("experience", 0)
	else:
		experience = data.get("exp", 0)
	hp = data.get("hp", 100)
	max_hp = data.get("max_hp", 100)
	mp = data.get("mp", 100)
	max_mp = data.get("max_mp", 100)
	vitality = data.get("vitality", data.get("strength", 10))
	magic = data.get("magic", 10)
	attack_base = data.get("attack_base", 10)
	defense_base = data.get("defense_base", 10)
	agility_base = data.get("agility_base", 10)
	realm = data.get("realm", "凡人")
	cultivation = data.get("cultivation", 0)
	reincarnation = data.get("reincarnation", 0)
	friendship_points = int(data.get("friendship_points", 0))
	cultivation_pills_used = data.get("cultivation_pills_used", 0)
	points = data.get("points", 20)
	permanent_points = data.get("permanent_points", 0)
	talent_attack = int(data.get("talent_attack", 0))
	talent_defense = int(data.get("talent_defense", 0))
	talent_agility = int(data.get("talent_agility", 0))
	talent_hp = int(data.get("talent_hp", 0))
	element = data.get("element", "普通")
	# 这里绝对不能用裸 bool(v)：GDScript 的 bool() 只接受 nil / 数字 / 字符串 / Object，
	# 收到 Dictionary 或 Array 会抛 "Invalid call. Nonexistent 'bool' constructor."
	# 一旦抛在这里，from_dict 后面的字段全部不赋值、调用方的后续流程也一起断掉
	# （登录后黑屏卡死就是这么来的：apply_cloud_save → from_dict 报错 →
	#  离线结算的回调发不出去 → 启动弹窗永远不建）。
	var raw_fabao_el: Variant = data.get("use_fabao_player_element", true)
	use_fabao_player_element = coerce_bool(raw_fabao_el, true)
	battle_stance_player = normalize_battle_stance(data.get("battle_stance_player", BATTLE_STANCE_ATTACK))
	battle_stance_pet = normalize_battle_stance(data.get("battle_stance_pet", BATTLE_STANCE_ATTACK))
	clamp_battle_stances()
	gold = data.get("gold", 0)
	yuanbao_currency = data.get("yuanbao_currency", 0)
	is_vip = data.get("is_vip", false)
	vip_level = data.get("vip_level", 0)
	vip_expire_time_str = str(data.get("vip_expire_time_str", ""))
	double_exp_until = int(data.get("double_exp_until", 0))
	var raw_channels: Variant = data.get("double_exp_channels", {})
	if raw_channels is Dictionary:
		var normalized_channels: Dictionary = {}
		for key in (raw_channels as Dictionary).keys():
			var key_name: = str(key)
			if key_name.strip_edges().is_empty():
				continue
			normalized_channels[key_name] = int((raw_channels as Dictionary)[key])
		double_exp_channels = normalized_channels
	else:
		double_exp_channels = {}
	# 玩家本次会话亲手勾过/取消过就以本地为准：权威回包里的这一项通常是
	# 勾选之前的旧快照（默认 false），照抄会让勾选几秒后自动消失。
	# 第二参数 null 表示「这份存档里没有这一项」，见 apply_auto_realm_pref_once。
	apply_auto_realm_pref_once(data.get("double_exp_auto_realm_enabled", null))
	tower_floor = data.get("tower_floor", 1)
	tower_highest = data.get("tower_highest", 0)
	var old_sweep_used = data.get("tower_sweep_used", false)
	tower_sweep_count = data.get("tower_sweep_count", 1 if old_sweep_used else 0)
	suit_dungeon_progress = data.get("suit_dungeon_progress", 0)
	suit_dungeon_sweeps = data.get("suit_dungeon_sweeps", 3)
	five_elements_dungeon_attempts = data.get("five_elements_dungeon_attempts", 0)
	fe_yuanbao_attempts = data.get("fe_yuanbao_attempts", 0)
	fe_yuanbao_attempts_date = data.get("fe_yuanbao_attempts_date", "")
	auto_allocation_enabled = data.get("auto_allocation_enabled", false)
	pending_auto_points = data.get("pending_auto_points", 0)
	if data.has("auto_allocation_plan"):
		auto_allocation_plan = data.get("auto_allocation_plan", {
			"vitality": 0, "attack": 0, "defense": 0, "magic": 0, "agility": 0
		})
	if data.has("attr_reset_guard_level"):
		attr_reset_guard_level = maxi(0, int(data.get("attr_reset_guard_level", 0)))
	else:
		attr_reset_guard_level = 0
	if attr_reset_guard_level > 0 and level > attr_reset_guard_level:
		attr_reset_guard_level = 0
	repair_permanent_points_from_reincarnation()
	clamp_talent_allocation_to_earned()
	_load_titles(data)
	active_title_id = data.get("active_title_id", "")
	recent_maps = data.get("recent_maps", [])
	player_character_id = int(data.get("player_character_id", 0))
	if player_character_id < 0 or player_character_id > 6:
		player_character_id = 0
	remove_expired_titles()
	repair_active_title_reference_after_load()
	update_derived_stats()

	hp = clamp(hp, 0, get_max_hp())
	mp = clamp(mp, 0, get_max_mp())
	gold = max(gold, 0)
	yuanbao_currency = max(yuanbao_currency, 0)
	_clamp_experience_at_max_level()

func add_recent_map(map_name: String):
	if map_name.is_empty():
		return

	var idx = recent_maps.find(map_name)
	if idx >= 0:
		recent_maps.remove_at(idx)

	recent_maps.insert(0, map_name)

	while recent_maps.size() > MAX_RECENT_MAPS:
		recent_maps.pop_back()

func _load_titles(data: Dictionary):
	titles = []
	var titles_data = data.get("titles", [])
	for title_data in titles_data:
		var title = TitleDataClass.new()
		title.from_dict(title_data)
		if not title.is_expired():
			titles.append(title)
