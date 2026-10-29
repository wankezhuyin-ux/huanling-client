extends Node
class_name BattleSystem


const GameData = preload("res://scripts/game_data.gd")
const Monster = preload("res://scripts/monster.gd")
const PetSkillBattle = preload("res://scripts/pet_skill_battle.gd")
const PetSkillConfig = preload("res://scripts/pet_skill_config.gd")
const MartialArtsManager = preload("res://scripts/martial_arts_manager.gd")
const FabaoStatBonus = preload("res://scripts/fabao/fabao_stat_bonus.gd")


const BATTLE_SKILL_LOG: = "[color=yellow]"


enum BattleState{
	IDLE, 
	IN_PROGRESS, 
	VICTORY, 
	DEFEAT
}

enum AttackTargetMode{
	SEQUENTIAL, 
	RANDOM, 
}

var current_state: BattleState = BattleState.IDLE
var attack_target_mode: AttackTargetMode = AttackTargetMode.SEQUENTIAL
var current_round: int = 0
var max_rounds: int = 20


var player: Player = null
var active_pet: Pet = null
var coop_units: Array = []
var monsters: Array = []

var player_died_in_battle: bool = false
var pet_died_in_battle: bool = false
var _pet_joint_attacked: bool = false
var _monster_acupoint_seal_turns: Dictionary = {}
var drive_by_execute_turn: bool = false

var replay_log_only: bool = false


var suppress_battle_character_exp: bool = false


var battle_log: Array = []
const MAX_LOG_LINES: int = 500
const DEBUG_AUTO_BATTLE_COMBO_LOG: bool = false
# 出手节奏：对齐参考稿录屏实测值。
# 参考稿一次出手 ≈0.25~0.3 秒；3 只怪一场（含「连击追击」再打一次）从「战斗开始」
# 到「战斗胜利 + 结算」≈2 秒。原来一次出手窗口 1.0 秒、冲刺动画还要 0.5 秒，
# 等于每刀有一半时间在干等，玩家体感就是「我们的战斗比参考稿慢一大截」。
const ROUND_WINDOW_SECONDS: float = 0.32
const JOINT_TURN_SECONDS: float = 0.6
const COMBO_TURN_SECONDS: float = 0.24
const COMBO_LUNGE_TIME_SCALE: float = 0.6

const ALLY_LUNGE_CYCLE_SECONDS: float = 0.3
const ATTACK_IMPACT_DELAY: float = 0.16

const MONSTER_WAVE_STAGGER_SECONDS: float = 0.04
const JOINT_PET_IMPACT_EXTRA_DELAY: float = 0.18

const OPENING_SETTLE_SECONDS: float = 0.3

var _exec_round_initialized: bool = false

var _exec_phase: int = 0
var _exec_turn_queue: Array = []
var _exec_turn_index: int = 0
var _exec_can_combo: bool = false
var _combo_guaranteed_hit: bool = false
var _coop_pet_joint_attacked: bool = false
var _coop_exec_can_combo: bool = false
var _coop_combo_guaranteed_hit: bool = false
var _pending_splash_pair_player: bool = false
var _pending_splash_pair_combo: bool = false
var _pending_splash_pair_coop: bool = false
var _pet_skill_battle: PetSkillBattle = null
var _opening_settle_gen: int = 0
var _opening_ready_at_msec: int = 0

var last_execute_wait_seconds: float = ROUND_WINDOW_SECONDS


signal battle_started
signal battle_ended(victory: bool)
signal round_started(round_num: int)
signal unit_turn(unit: Dictionary)
signal damage_dealt(attacker: String, target: String, damage: int, is_critical: bool, hit_target_type: String, hit_target_index: int, element_tag: String, is_armor_pierce: bool, is_counter: bool)
signal unit_died(unit_name: String)
signal acupoint_seal_changed(target_type: String, target_index: int, sealed: bool)

signal unit_hp_synced(hit_target_type: String, hit_target_index: int, hp_after: int)
signal log_added(message: String, highlight: Dictionary)

const HIGHLIGHT_BATTLE_START: = {"type": "battle_start", "text": "战斗开始"}
const HIGHLIGHT_COMBO: = {"type": "combo", "text": "触发连击"}
const HIGHLIGHT_JOINT: = {"type": "joint", "text": "触发合击"}

static func _skill_highlight(skill_name: String, anchor: String = "pet", heal_amount: int = 0, anchor_index: int = -1) -> Dictionary:

	var hl: Dictionary = {
		"type": "skill", 
		"text": skill_name, 
		"anchor": anchor, 
		"anchor_index": anchor_index, 
	}
	if heal_amount > 0:
		hl["heal_amount"] = heal_amount
	return hl

static func _attach_splash_hit_fx(hl: Dictionary, monster_index: int) -> Dictionary:
	var out: Dictionary = hl.duplicate() if not hl.is_empty() else {}
	out["hit_fx"] = "splash"
	out["hit_fx_type"] = "monster"
	out["hit_fx_index"] = monster_index
	return out


func start_battle(p: Player, pet: Pet, monster_group: Array, round_limit: int = 20, silent: bool = false, target_mode: AttackTargetMode = AttackTargetMode.SEQUENTIAL) -> bool:
	print("[BattleSystem] start_battle 被调用, current_state=", current_state, ", monsters=", monster_group.size())

	if current_state == BattleState.IN_PROGRESS:
		add_log("[警告] 检测到战斗状态异常，强制重置...")
		current_state = BattleState.IDLE

	current_state = BattleState.IDLE
	_opening_settle_gen += 1
	_is_starting_round = false
	attack_target_mode = target_mode

	player = p
	active_pet = pet
	monsters = monster_group
	current_round = 0
	max_rounds = maxi(0, round_limit)
	battle_log.clear()

	# 把上一场宠物技能的触发次数留到开战时报出来，然后清零
	_capture_pet_skill_summary()

	player_died_in_battle = false
	pet_died_in_battle = false

	_pet_joint_attacked = false
	_coop_pet_joint_attacked = false
	_monster_acupoint_seal_turns.clear()
	_exec_phase = 0
	_exec_round_initialized = false
	_exec_turn_queue.clear()
	_exec_turn_index = 0
	_exec_can_combo = false
	_combo_guaranteed_hit = false
	_coop_exec_can_combo = false
	_coop_combo_guaranteed_hit = false
	_pending_splash_pair_player = false
	_pending_splash_pair_combo = false
	_pending_splash_pair_coop = false

	if player:
		player.heal_full()
	if active_pet:
		active_pet.heal_full()

	_pet_skill_battle = PetSkillBattle.new()
	if active_pet:
		_pet_skill_battle.reset_for_battle(active_pet)
	for cu in coop_units:
		if cu == null or not cu.has_method("has_battle_pet_skills") or not cu.has_battle_pet_skills():
			continue
		var coop_pet: Pet = cu.get_battle_pet()
		if coop_pet != null:
			_pet_skill_battle.register_pet_for_battle(coop_pet)

	current_state = BattleState.IN_PROGRESS
	_opening_ready_at_msec = Time.get_ticks_msec() + int(OPENING_SETTLE_SECONDS * 1000.0)
	battle_started.emit()
	if not silent:
		add_log("=== 战斗开始 ===", HIGHLIGHT_BATTLE_START)
		if not replay_log_only:
			for monster in monsters:
				var m_name = _get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", "怪物"))
				var m_level = _get_monster_stat(monster, "level", 1)
				var m_hp = _get_monster_stat(monster, "hp", 0)
				var m_atk = _get_monster_stat(monster, "attack", 0)
				var m_def = _get_monster_stat(monster, "defense", 0)
				var m_agi = _get_monster_stat(monster, "agility", 0)
				add_log("遭遇 %s Lv.%d!" % [m_name, m_level])
				add_log("└ 属性 攻:%d 防:%d 敏:%d 血:%d" % [int(m_atk), int(m_def), int(m_agi), int(m_hp)])

	if not drive_by_execute_turn and not replay_log_only:
		_begin_first_round(_opening_settle_gen)
	_log_pet_skill_report(active_pet)
	return true


## 宠物技能的战报信息。
## 1) 整局只报一次「宠物技能：xxx」，让玩家确认客户端有没有认到技能；
## 2) 每场开战时补一行「上一场技能触发：追击×2 反击×1」，触发过就一定看得见，
##    不用靠盯伤害数字去猜。
var _pet_skill_logged: bool = false
var _pet_chase_triggers: int = 0
var _pet_counter_triggers: int = 0
var _prev_pet_skill_summary: String = ""

func _capture_pet_skill_summary() -> void:
	if _pet_chase_triggers <= 0 and _pet_counter_triggers <= 0:
		_prev_pet_skill_summary = ""
	else:
		var parts: Array = []
		if _pet_chase_triggers > 0:
			parts.append("追击×%d" % _pet_chase_triggers)
		if _pet_counter_triggers > 0:
			parts.append("反击×%d" % _pet_counter_triggers)
		_prev_pet_skill_summary = "、".join(parts)
	_pet_chase_triggers = 0
	_pet_counter_triggers = 0

func _log_pet_skill_report(pet: Pet) -> void:
	if not _pet_skill_logged and pet != null:
		_pet_skill_logged = true
		var parts: Array = []
		for entry in PetSkillConfig.get_pet_skill_entries(pet):
			var cfg: Dictionary = entry.get("config", {})
			parts.append("%s lv%d" % [str(cfg.get("skill_name", "?")), int(entry.get("level", 1))])
		var text: String = "、".join(parts) if not parts.is_empty() else "无"
		add_log("[color=#b197fc]宠物技能：%s[/color]" % text)
		print("[BattleSystem] 宠物技能 = ", text)
	if not _prev_pet_skill_summary.is_empty():
		add_log("[color=#b197fc]上一场技能触发：%s[/color]" % _prev_pet_skill_summary)
		_prev_pet_skill_summary = ""

func _begin_first_round(settle_gen: int) -> void :
	if OPENING_SETTLE_SECONDS > 0.0 and get_tree() != null:
		await get_tree().create_timer(OPENING_SETTLE_SECONDS).timeout
	if settle_gen != _opening_settle_gen:
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	if drive_by_execute_turn or replay_log_only:
		return
	_start_round()


var _is_starting_round = false

func _is_stale_battle_gen(gen: int) -> bool:
	return gen != _opening_settle_gen

func _finish_round_loop(round_gen: int) -> void :
	if _is_stale_battle_gen(round_gen):
		return
	_is_starting_round = false

func _start_round():
	if _is_starting_round:
		print("[BattleSystem] _start_round 被重复调用，跳过")
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	var round_gen: = _opening_settle_gen

	_is_starting_round = true
	_pet_joint_attacked = false
	_coop_pet_joint_attacked = false

	_refresh_battle_active_pet()

	print("[BattleSystem] _start_round 开始, current_round=", current_round + 1, ", current_state=", current_state)
	current_round += 1
	round_started.emit(current_round)
	add_log("--- 第 %d 回合 ---" % current_round)

	_exec_can_combo = _check_combo_condition()
	_combo_guaranteed_hit = _exec_can_combo
	if _exec_can_combo:
		add_log("[color=#69db7c]★ 连击触发! 你和宠物的敏捷都高于所有敌人! ★[/color]", HIGHLIGHT_COMBO)
	_refresh_coop_combo_state()

	var round_actions: Array = _build_round_turn_queue()
	for action in round_actions:
		if _is_stale_battle_gen(round_gen):
			return
		if current_state != BattleState.IN_PROGRESS:
			_finish_round_loop(round_gen)
			return
		if _check_battle_end():
			_finish_round_loop(round_gen)
			return
		var action_ms: = Time.get_ticks_msec()
		var ran: = _run_turn_action(action)
		if _is_stale_battle_gen(round_gen):
			return
		if current_state != BattleState.IN_PROGRESS:
			_finish_round_loop(round_gen)
			return
		if _check_battle_end():
			_finish_round_loop(round_gen)
			return
		if ran:
			await _await_action_window_from(action_ms, _action_window_seconds(action))
			if _is_stale_battle_gen(round_gen):
				return

	if _is_stale_battle_gen(round_gen):
		return

	if current_state == BattleState.IN_PROGRESS:
		_try_apply_pet_self_heal_end_of_round()
		if _is_stale_battle_gen(round_gen):
			return

		if max_rounds > 0 and current_round >= max_rounds:
			current_state = BattleState.DEFEAT
			add_log("=== [color=red]战斗失败... (超过最大回合数)[/color] ===")
			battle_ended.emit(false)
			_finish_round_loop(round_gen)
			return
		_finish_round_loop(round_gen)
		_continue_round_if_same_gen.call_deferred(round_gen)
	else:
		_finish_round_loop(round_gen)

func _continue_round_if_same_gen(round_gen: int) -> void :
	if _is_stale_battle_gen(round_gen):
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	_start_round()

func set_coop_units(units: Array) -> void :
	coop_units = units if units is Array else []

func clear_coop_units() -> void :
	coop_units.clear()

func _get_battle_units() -> Array:
	var units = []


	if player and player.is_alive():
		units.append({
			"type": "player", 
			"name": player.player_name, 
			"agility": player.get_agility(), 
			"reference": player
		})


	if active_pet and active_pet.is_alive():
		units.append({
			"type": "pet", 
			"name": active_pet.pet_name, 
			"agility": active_pet.get_final_agility_with_equipment(), 
			"reference": active_pet
		})

	for cu in coop_units:
		if cu == null:
			continue
		if cu.has_method("is_alive") and not cu.is_alive():
			continue
		var cu_type: = str(cu.unit_type if "unit_type" in cu else "coop_player")
		units.append({
			"type": cu_type, 
			"name": str(cu.display_name if "display_name" in cu else "队友"), 
			"agility": int(cu.agility if "agility" in cu else 1), 
			"reference": cu
		})


	for i in range(monsters.size()):
		var monster = monsters[i]
		if is_monster_alive(monster):
			units.append({
				"type": "monster", 
				"name": _get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", "怪物")), 
				"agility": _get_monster_stat(monster, "agility", 0), 
				"reference": monster, 
				"index": i
			})


	units.sort_custom( func(a, b): return a.agility > b.agility)

	return units


func _ally_unit_priority(unit: Dictionary) -> int:
	var t: String = str(unit.get("type", ""))
	if t == "player" or t == "coop_player":
		return 0
	return 1

func _get_ally_units_sorted() -> Array:
	var out: Array = []
	for u in _get_battle_units():
		var t: String = str(u.get("type", ""))
		if t == "player" or t == "pet" or t == "coop_player" or t == "coop_pet":
			out.append(u)
	# 参考稿规则：「按敏捷排序依次行动」。旧实现只是按 player → pet 的固定顺序 append，
	# 所以永远看不到「宠物先手」——参考稿录屏里就有「黄金龙 先攻击，然后言者 攻击」。
	# 这里真按敏捷从高到低排，敏捷相同时人物优先。
	out.sort_custom(func(a, b):
		var aa: = int(a.get("agility", 0))
		var bb: = int(b.get("agility", 0))
		if aa != bb:
			return aa > bb
		return _ally_unit_priority(a) < _ally_unit_priority(b)
	)
	return out


func _get_monster_units_sorted() -> Array:
	var out: Array = []
	for u in _get_battle_units():
		if str(u.get("type", "")) == "monster":
			out.append(u)
	return out

func _should_skip_turn_unit(unit: Dictionary) -> bool:
	if unit.get("type", "") == "monster":
		var m_idx: = int(unit.get("index", -1))
		if m_idx < 0 or m_idx >= monsters.size() or not is_monster_alive(monsters[m_idx]):
			return true
	elif unit.get("type", "") == "player":
		var p_ref = unit.get("reference")
		if p_ref == null or not p_ref.is_alive():
			return true
	elif unit.get("type", "") == "pet":
		var pet_ref = unit.get("reference")
		if pet_ref == null or not pet_ref.is_alive():
			return true
	elif unit.get("type", "") in ["coop_player", "coop_pet"]:
		var coop_ref = unit.get("reference")
		if coop_ref == null or (coop_ref.has_method("is_alive") and not coop_ref.is_alive()):
			return true
	else:
		return true
	if unit.get("type", "") == "pet" and _pet_joint_attacked:
		return true
	if unit.get("type", "") == "coop_pet" and _coop_pet_joint_attacked:
		return true
	return false

func _live_player_for_stance() -> Player:
	var gm = GameManager.instance
	if gm != null and gm.player != null:
		return gm.player
	return player

func _battle_stance_enabled() -> bool:
	var gm = GameManager.instance
	if gm == null or not gm.in_battle:
		return false
	return not gm.is_in_instanced_challenge()

func _is_local_player_defending() -> bool:
	if not _battle_stance_enabled():
		return false
	var p: = _live_player_for_stance()
	return p != null and str(p.battle_stance_player) == Player.BATTLE_STANCE_DEFEND

func _is_local_pet_defending() -> bool:
	if not _battle_stance_enabled():
		return false
	var p: = _live_player_for_stance()
	return p != null and str(p.battle_stance_pet) == Player.BATTLE_STANCE_DEFEND

func _apply_defend_damage_reduction(damage: int) -> int:
	if damage <= 0:
		return damage
	return maxi(1, int(damage * 0.5))


func _apply_pet_armor_pierce_defense(pet: Pet, defense_value, skill_anchor: String = "pet") -> Dictionary:
	var def_f: = float(defense_value)
	if pet == null or _pet_skill_battle == null:
		return {"defense": def_f, "pierced": false}
	var extra: = 0.0
	if skill_anchor != "coop_pet":
		extra = FabaoStatBonus.armor_pierce_bonus_rate()
	var pierce: = _pet_skill_battle.try_trigger_armor_pierce(pet, extra)
	if pierce.is_empty():
		return {"defense": def_f, "pierced": false}
	add_log("%s✦破甲触发![/color] %s 本下忽视对方一半防御" % [BATTLE_SKILL_LOG, pet.pet_name], _skill_highlight("破甲", skill_anchor))
	return {"defense": maxf(0.0, def_f * 0.5), "pierced": true}


func _apply_pet_guard_damage_reduction(pet: Pet, damage: int, skill_anchor: String = "pet") -> Dictionary:
	var out: = {"damage": damage, "guarded": false}
	if pet == null or _pet_skill_battle == null or damage <= 0:
		return out
	var guard: = _pet_skill_battle.try_trigger_guard(pet)
	if guard.is_empty():
		return out
	var ratio: float = clampf(float(guard.get("damage_reduction_ratio", 0.5)), 0.0, 1.0)
	var reduced: = maxi(1, int(float(damage) * (1.0 - ratio)))
	out["damage"] = reduced
	out["guarded"] = reduced != damage
	if bool(out["guarded"]):
		add_log("%s✦格挡触发![/color] %s 减免部分伤害" % [BATTLE_SKILL_LOG, pet.pet_name], _skill_highlight("格挡", skill_anchor))
	return out

func _log_defend_skip(side: String) -> void :
	if str(side) == "pet":
		add_log("[color=#74c0fc]宠物防御，本回合不出手[/color]")
	else:
		add_log("[color=#74c0fc]人物防御，本回合不出手[/color]")

func _target_meta_from_monster(monster) -> Dictionary:
	if monster == null:
		return {}
	return {
		"target_type": "monster", 
		"target_index": _monster_index_of(monster), 
	}

func _target_meta_from_ally(target) -> Dictionary:
	if target == null:
		return {}
	if target is Player:
		return {"target_type": "player", "target_index": 0}
	if target is Pet:
		return {"target_type": "pet", "target_index": -1}
	if "unit_type" in target:
		return {
			"target_type": str(target.unit_type), 
			"target_index": _coop_unit_index(target), 
		}
	return {}

func _martial_has_triple_shot(unit = null) -> bool:
	var art = null
	if unit != null and unit.has_method("find_martial_by_effect"):
		art = unit.find_martial_by_effect("triple_shot")
	else:
		art = _find_equipped_martial_by_effect("triple_shot")
	if art == null:
		return false
	return float(art.get_triple_shot_damage_ratio()) > 0.0

func _pet_has_double_shot_skill(pet: Pet) -> bool:
	if pet == null:
		return false
	return not PetSkillConfig.get_best_skill_by_ids(pet, ["double_shot"]).is_empty()

func _pet_has_splash_skill(pet: Pet) -> bool:
	if pet == null:
		return false
	return not PetSkillConfig.get_best_skill_by_ids(pet, ["splash"]).is_empty()

func _resolve_skip_lunge_battle_pet(unit_type: String, reference) -> Pet:
	if unit_type == "pet" and reference is Pet:
		return reference
	if unit_type == "coop_pet":
		if reference is Pet:
			return reference
		if reference != null and reference.has_method("get_battle_pet"):
			return reference.get_battle_pet()
	return null

func _fill_splash_plan_extras(splash: Dictionary, primary_target) -> Dictionary:
	if splash.is_empty() or not bool(splash.get("triggered", false)):
		return splash
	var extras: Array = splash.get("extras", [])
	if extras.is_empty():
		var exclude: Array = []
		if primary_target != null:
			exclude.append(primary_target)
		extras = _pick_random_alive_monsters(int(splash.get("extra_count", 0)), exclude)
		splash["extras"] = extras
	return splash

func _prepare_pet_attack_splash(pet: Pet, primary_target, allow_pet_attack_skill: bool) -> Dictionary:
	if not allow_pet_attack_skill or pet == null:
		return {}
	return _fill_splash_plan_extras(_preroll_pet_splash_plan(pet), primary_target)

func _splash_plan_has_extra_hits(splash_plan: Dictionary) -> bool:
	if not bool(splash_plan.get("triggered", false)):
		return false
	var extras = splash_plan.get("extras", [])
	return extras is Array and not extras.is_empty()

func _should_skip_lunge(unit_type: String, reference = null, allow_pet_attack_skill: bool = true, splash_plan: Dictionary = {}, include_kuihua: bool = true) -> bool:
	match unit_type:
		"player":
			if include_kuihua and _local_kuihua_attack_active():
				return true
			return _martial_has_triple_shot()
		"coop_player":
			if include_kuihua and _coop_kuihua_attack_active(reference):
				return true
			return _martial_has_triple_shot(reference)
		"pet", "coop_pet":
			if not allow_pet_attack_skill:
				return false
			if _splash_plan_has_extra_hits(splash_plan):
				return true
			return _pet_has_double_shot_skill(_resolve_skip_lunge_battle_pet(unit_type, reference))
	return false

func _emit_unit_turn_with_target(unit: Dictionary, target_meta: Dictionary, skip_lunge: bool = false, lunge_time_scale: float = 1.0, lunge_start_delay: float = 0.0) -> void :
	var payload: = unit.duplicate()
	if not target_meta.is_empty():
		payload["target_type"] = str(target_meta.get("target_type", ""))
		payload["target_index"] = int(target_meta.get("target_index", -1))
	payload["skip_lunge"] = skip_lunge
	payload["lunge_time_scale"] = lunge_time_scale
	payload["lunge_start_delay"] = maxf(0.0, lunge_start_delay)
	unit_turn.emit(payload)

func _pick_player_attack_targets() -> Array:
	var triple_art = _find_equipped_martial_by_effect("triple_shot")
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var target_count: = 3 if (_local_kuihua_attack_active() or triple_ratio > 0.0) else 1
	return _pick_random_alive_monsters(target_count)

func _pick_coop_player_attack_targets(unit) -> Array:
	if unit == null:
		return []
	var triple_art = unit.find_martial_by_effect("triple_shot") if unit.has_method("find_martial_by_effect") else null
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var target_count: = 3 if (_coop_kuihua_attack_active(unit) or triple_ratio > 0.0) else 1
	return _pick_random_alive_monsters(target_count)

func _append_unique_ref(arr: Array, item) -> void :
	if item == null or arr.has(item):
		return
	arr.append(item)

func _estimate_mid_hit_damage(attack_value: int, monster, element: String, is_evo: bool, soul_bonus: int = 0) -> int:
	if monster == null:
		return 1
	var target_defense = _get_monster_stat(monster, "defense", 0)
	var target_element = _get_monster_stat(monster, "element", "普通")
	var base_damage = max(1, int(attack_value) - int(target_defense) / 2)
	var element_result = GameData.calculate_damage_with_element(base_damage, element, target_element, is_evo)
	var damage: int = int(element_result.damage)
	if soul_bonus > 0 and _is_element_counter_or_countered(element, target_element):
		damage = max(1, int(damage * (1.0 + float(soul_bonus) / 100.0)))
	return maxi(1, damage)

func _estimate_can_kill(damage: int, monster) -> bool:
	if monster == null:
		return false
	return int(damage) >= int(_get_monster_stat(monster, "hp", 0))

func _estimate_player_hit_damage(monster, coop_unit = null) -> int:
	var atk: = 1
	var el: = "普通"
	var triple_ratio: = 0.0
	if coop_unit != null:
		atk = int(coop_unit.attack if "attack" in coop_unit else 1)
		el = str(coop_unit.element if "element" in coop_unit else "普通")
		var art = coop_unit.find_martial_by_effect("triple_shot") if coop_unit.has_method("find_martial_by_effect") else null
		if art != null:
			triple_ratio = art.get_triple_shot_damage_ratio()
	elif player != null:
		atk = int(player.get_attack())
		el = _local_player_battle_element(player.element)
		var local_art = _find_equipped_martial_by_effect("triple_shot")
		if local_art != null:
			triple_ratio = local_art.get_triple_shot_damage_ratio()
	if triple_ratio > 0.0:
		atk = maxi(1, int(float(atk) * triple_ratio))
	return _estimate_mid_hit_damage(atk, monster, el, false, 0)

func _estimate_pet_hit_damage(pet: Pet, monster, coop_unit = null, ratio: float = 1.0) -> int:
	if pet == null or monster == null:
		return 1
	var atk: = _coop_pet_attack_value(coop_unit, pet)
	var soul: = _coop_soul_bonus(coop_unit, pet.element, pet, str(_get_monster_stat(monster, "element", "普通")))
	var damage: = _estimate_mid_hit_damage(atk, monster, pet.element, pet.is_evolution_pet, soul)
	return maxi(1, int(float(damage) * maxf(0.0, ratio)))

func _pick_pair_pet_target(player_targets: Array, battle_pet: Pet, coop_player = null, coop_pet = null):
	var local_manager = GameManager.instance
	if coop_player == null and local_manager != null and local_manager.has_method("local_pair_primary_target"):
		return local_manager.local_pair_primary_target(player_targets)
	if battle_pet == null:
		return _pick_random_alive_monster()
	var exclude: Array = []
	for t in player_targets:
		if t == null or not is_monster_alive(t):
			continue
		var player_kills: = _estimate_can_kill(_estimate_player_hit_damage(t, coop_player), t)
		var pet_kills: = _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, t, coop_pet, 1.0), t)
		if player_kills or pet_kills:
			_append_unique_ref(exclude, t)
	var pet_target = _pick_random_alive_monster(exclude)
	if pet_target != null:
		return pet_target
	return _pick_random_alive_monster()

func _preroll_pet_splash_plan(pet: Pet) -> Dictionary:
	if pet == null:
		return {}
	var best: Dictionary = PetSkillConfig.get_best_skill_by_ids(pet, ["splash"])
	if best.is_empty():
		return {}
	var skill_key: = str(best.get("skill_key", ""))
	var config: Dictionary = best.get("config", {})
	var plan: = {
		"rolled": true, 
		"triggered": false, 
		"skill_key": skill_key, 
		"ratio": maxf(0.0, float(config.get("damage_ratio", 1.0))), 
		"extra_count": 0, 
		"extras": [], 
	}
	var rate: = clampf(float(config.get("trigger_rate", 0.0)), 0.0, 1.0)
	if rate <= 0.0:
		var skill_cfg: Dictionary = GameData.PET_SKILLS.get(skill_key, {})
		rate = clampf(float(skill_cfg.get("trigger_chance", 0.0)), 0.0, 1.0)
	if rate <= 0.0 or randf() >= rate:
		return plan
	plan["triggered"] = true
	plan["extra_count"] = maxi(0, int(config.get("target_count", 2)) - 1)
	plan["ratio"] = maxf(0.0, float(config.get("damage_ratio", 1.0)))
	return plan

func _plan_combo_pair_targets(coop_player = null, coop_pet = null) -> Dictionary:
	var is_coop: = coop_player != null
	var battle_pet: Pet = null
	if is_coop:
		if coop_pet != null and coop_pet.has_method("get_battle_pet"):
			battle_pet = coop_pet.get_battle_pet()
	else:
		battle_pet = active_pet
	var splash: Dictionary = _preroll_pet_splash_plan(battle_pet)
	var has_triple: = _martial_has_triple_shot(coop_player if is_coop else null)
	var out: = {
		"player_targets": [], 
		"pet_primary": null, 
		"combo_target": null, 
		"splash": splash, 
	}
	var killed: Array = []
	var coop_u = coop_pet if is_coop else null
	if has_triple:
		out["player_targets"] = _pick_coop_player_attack_targets(coop_player) if is_coop else _pick_player_attack_targets()
		for t in out["player_targets"]:
			if t != null and _estimate_can_kill(_estimate_player_hit_damage(t, coop_player if is_coop else null), t):
				_append_unique_ref(killed, t)
		out["pet_primary"] = _pick_random_alive_monster(out["player_targets"])
		if bool(splash.get("triggered", false)) and out["pet_primary"] != null:
			var exclude_splash: Array = out["player_targets"].duplicate()
			exclude_splash.append(out["pet_primary"])
			splash["extras"] = _pick_random_alive_monsters(int(splash.get("extra_count", 0)), exclude_splash)
		if out["pet_primary"] != null and battle_pet != null and _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, out["pet_primary"], coop_u, 1.0), out["pet_primary"]):
			_append_unique_ref(killed, out["pet_primary"])
		for extra in splash.get("extras", []):
			if extra != null and battle_pet != null and _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, extra, coop_u, float(splash.get("ratio", 1.0))), extra):
				_append_unique_ref(killed, extra)
		out["combo_target"] = _pick_random_alive_monster(killed)
		if out["combo_target"] == null:
			out["combo_target"] = out["pet_primary"]
		return out
	out["pet_primary"] = _pick_random_alive_monster()
	if bool(splash.get("triggered", false)) and out["pet_primary"] != null:
		splash["extras"] = _pick_random_alive_monsters(int(splash.get("extra_count", 0)), [out["pet_primary"]])
		if battle_pet != null and _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, out["pet_primary"], coop_u, 1.0), out["pet_primary"]):
			_append_unique_ref(killed, out["pet_primary"])
		for extra in splash.get("extras", []):
			if extra != null and battle_pet != null and _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, extra, coop_u, float(splash.get("ratio", 1.0))), extra):
				_append_unique_ref(killed, extra)
	elif out["pet_primary"] != null and battle_pet != null and _estimate_can_kill(_estimate_pet_hit_damage(battle_pet, out["pet_primary"], coop_u, 1.0), out["pet_primary"]):
		_append_unique_ref(killed, out["pet_primary"])
	var player_t = _pick_random_alive_monster(killed)
	if player_t == null:
		player_t = out["pet_primary"]
	out["player_targets"] = [player_t] if player_t != null else []
	if player_t != null and _estimate_can_kill(_estimate_player_hit_damage(player_t, coop_player if is_coop else null), player_t):
		_append_unique_ref(killed, player_t)
	out["combo_target"] = _pick_random_alive_monster(killed)
	if out["combo_target"] == null:
		out["combo_target"] = out["pet_primary"]
	return out

func _pick_monster_ally_target():
	var taunt_pet = _pick_taunt_pet_target()
	if taunt_pet != null:
		return taunt_pet
	var targets = []
	if player and player.is_alive():
		targets.append(player)
	if active_pet and active_pet.is_alive():
		targets.append(active_pet)
	for cu in coop_units:
		if cu != null and cu.has_method("is_alive") and cu.is_alive():
			targets.append(cu)
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]

func _pick_taunt_pet_target():
	if _pet_skill_battle == null:
		return null
	if active_pet != null and active_pet.is_alive():
		var taunt: = _pet_skill_battle.try_trigger_taunt(active_pet)
		if not taunt.is_empty():
			add_log("%s%s 触发【嘲讽】，吸引了怪物注意![/color]" % [BATTLE_SKILL_LOG, active_pet.pet_name], _skill_highlight("嘲讽", "pet"))
			return active_pet
	for cu in coop_units:
		if cu == null or not cu.has_method("is_alive") or not cu.is_alive():
			continue
		if not cu.has_method("get_battle_pet"):
			continue
		var bp: Pet = cu.get_battle_pet()
		if bp == null or not bp.is_alive():
			continue
		var coop_taunt: = _pet_skill_battle.try_trigger_taunt(bp)
		if not coop_taunt.is_empty():
			add_log("%s%s 触发【嘲讽】，吸引了怪物注意![/color]" % [BATTLE_SKILL_LOG, bp.pet_name], _skill_highlight("嘲讽", "coop_pet"))
			return cu
	return null

func _local_player_unit_dict() -> Dictionary:
	if player == null:
		return {}
	return {
		"type": "player", 
		"name": player.player_name, 
		"agility": player.get_agility(), 
		"reference": player, 
	}

func _local_pet_unit_dict() -> Dictionary:
	if active_pet == null:
		return {}
	return {
		"type": "pet", 
		"name": active_pet.pet_name, 
		"agility": active_pet.get_final_agility_with_equipment(), 
		"reference": active_pet, 
	}

func _coop_unit_dict(coop_unit) -> Dictionary:
	if coop_unit == null:
		return {}
	return {
		"type": str(coop_unit.unit_type if "unit_type" in coop_unit else "coop_player"), 
		"name": str(coop_unit.display_name if "display_name" in coop_unit else "队友"), 
		"agility": int(coop_unit.agility if "agility" in coop_unit else 1), 
		"reference": coop_unit, 
	}

func _append_local_ally_turn_actions(actions: Array) -> void :
	if _find_first_alive_monster() == null:
		return
	var player_alive: = player != null and player.is_alive()
	var pet_alive: = active_pet != null and active_pet.is_alive()
	# 合击：人和宠的敏捷都低于全部怪物 → 联手打同一个目标，宠物不再单独行动
	# （参考稿说明：「触发合击时宠物不会再独立行动，只在人物回合一起出手」）。
	if player_alive and pet_alive and _check_joint_attack_condition():
		actions.append({"kind": "local_joint"})
		return
	# 其余情况一律「按敏捷先后依次行动」（参考稿说明：按敏捷排序依次行动），
	# 不再把人宠合成 local_pair 同时出手。参考稿录屏的日志顺序就是：
	#   宠物攻击 → 言者攻击 → 言者 连击追击 宠物 → 宠物再打一次
	# 旧写法会变成「人宠同一瞬间两行」，顺序和参考稿对不上。
	var combo_follow_done: = false
	for unit in _get_ally_units_sorted():
		if _should_skip_turn_unit(unit):
			continue
		var unit_type: String = str(unit.get("type", ""))
		if unit_type in ["coop_player", "coop_pet"]:
			continue
		actions.append({"kind": "unit", "unit": unit})
		# 连击：人物出手后，宠物紧跟一次追加攻击（全段必中）。
		if unit_type == "player":
			if _exec_can_combo and pet_alive and not combo_follow_done and not _is_local_pet_defending():
				combo_follow_done = true
				actions.append({"kind": "combo_pet"})

func _append_coop_ally_turn_actions(actions: Array) -> void :
	if _find_first_alive_monster() == null:
		return
	var pair: = _find_coop_pair()
	var cp = pair.get("player")
	var cpet = pair.get("pet")
	var cp_alive: bool = cp != null and cp.has_method("is_alive") and cp.is_alive()
	var cpet_alive: bool = cpet != null and cpet.has_method("is_alive") and cpet.is_alive()
	if cp_alive and cpet_alive and _check_coop_joint_attack_condition(cp, cpet):
		actions.append({"kind": "coop_joint"})
		return
	# 队友（协同单位）同理：按敏捷依次行动，连击时队友宠追加一次。
	var coop_combo_follow_done: bool = false
	for unit in _get_ally_units_sorted():
		if _should_skip_turn_unit(unit):
			continue
		var unit_type: String = str(unit.get("type", ""))
		if unit_type not in ["coop_player", "coop_pet"]:
			continue
		actions.append({"kind": "unit", "unit": unit})
		if unit_type == "coop_player":
			if _coop_exec_can_combo and cpet_alive and not coop_combo_follow_done:
				coop_combo_follow_done = true
				actions.append({"kind": "coop_combo_pet"})

func _append_monster_turn_actions(actions: Array) -> void :
	var units: Array = _get_monster_units_sorted()
	if units.is_empty():
		return
	actions.append({"kind": "monster_wave", "units": units})

func _build_round_turn_queue() -> Array:
	var actions: Array = []
	_append_local_ally_turn_actions(actions)
	_append_coop_ally_turn_actions(actions)
	_append_monster_turn_actions(actions)
	return actions

func _execute_local_pair_action() -> bool:
	var player_alive: = player != null and player.is_alive()
	var pet_alive: = active_pet != null and active_pet.is_alive()
	if not player_alive and not pet_alive:
		return false
	var player_acts: = player_alive and not _is_local_player_defending()
	var pet_acts: = pet_alive and not _is_local_pet_defending()
	if player_alive and not player_acts:
		_log_defend_skip("player")
	if pet_alive and not pet_acts:
		_log_defend_skip("pet")
	if not player_acts and not pet_acts:
		return false
	if player_acts and pet_acts and _pet_has_splash_skill(active_pet):
		return _execute_splash_first_local_pair()
	var player_targets2: Array = _pick_player_attack_targets() if player_acts else []
	var pet_target2 = _pick_pair_pet_target(player_targets2, active_pet) if pet_acts else null
	if player_targets2.is_empty() and pet_target2 == null:
		return false
	print("[BattleSystem] 执行回合(人宠同出): ", player.player_name if player_acts else "-", " + ", active_pet.pet_name if pet_acts else "-")
	var pair_splash: Dictionary = {}
	if player_acts and not player_targets2.is_empty():
		_emit_unit_turn_with_target(
			_local_player_unit_dict(), 
			_target_meta_from_monster(player_targets2[0]), 
			_should_skip_lunge("player")
		)
	if pet_acts and pet_target2 != null:
		pair_splash = _prepare_pet_attack_splash(active_pet, pet_target2, true)
		_emit_unit_turn_with_target(
			_local_pet_unit_dict(), 
			_target_meta_from_monster(pet_target2), 
			_should_skip_lunge("pet", active_pet, true, pair_splash)
		)
	if player_acts and not player_targets2.is_empty():
		_player_turn(player, player_targets2)
	if pet_acts and pet_target2 != null:
		_pet_turn(active_pet, true, pet_target2, pair_splash)
	return true

func _execute_splash_first_local_pair() -> bool:
	var pet_target = _pick_random_alive_monster()
	if pet_target == null:
		return false
	var splash: Dictionary = _fill_splash_plan_extras(_preroll_pet_splash_plan(active_pet), pet_target)
	print("[BattleSystem] 执行回合(溅射先手): ", player.player_name, " + ", active_pet.pet_name)
	_pending_splash_pair_player = true
	_pending_splash_pair_combo = false
	_pending_splash_pair_coop = false
	_emit_unit_turn_with_target(
		_local_pet_unit_dict(), 
		_target_meta_from_monster(pet_target), 
		_should_skip_lunge("pet", active_pet, true, splash)
	)
	if not _pet_turn(active_pet, true, pet_target, splash):
		_run_pending_splash_pair_player()
	return true

func _coop_battle_pet_has_splash(cpet) -> bool:
	if cpet == null:
		return false
	var battle_pet: Pet = cpet.get_battle_pet() if cpet.has_method("get_battle_pet") else null
	return _pet_has_splash_skill(battle_pet)

func _execute_splash_first_coop_pair(cp, cpet) -> bool:
	var pet_target = _pick_random_alive_monster()
	if pet_target == null:
		return false
	var battle_pet: Pet = cpet.get_battle_pet() if cpet.has_method("get_battle_pet") else null
	var splash: Dictionary = _fill_splash_plan_extras(_preroll_pet_splash_plan(battle_pet), pet_target)
	var cp_name: = str(cp.display_name if "display_name" in cp else "队友")
	var cpet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
	print("[BattleSystem] 执行回合(队友溅射先手): ", cp_name, " + ", cpet_name)
	_pending_splash_pair_player = true
	_pending_splash_pair_combo = false
	_pending_splash_pair_coop = true
	_emit_unit_turn_with_target(
		_coop_unit_dict(cpet), 
		_target_meta_from_monster(pet_target), 
		_should_skip_lunge("coop_pet", cpet, true, splash)
	)
	if not _coop_pet_turn(cpet, true, pet_target, splash):
		_run_pending_splash_pair_player()
	return true

func _run_pending_splash_pair_player() -> void :
	if not _pending_splash_pair_player:
		return
	var want_combo: = _pending_splash_pair_combo
	var is_coop: = _pending_splash_pair_coop
	_pending_splash_pair_player = false
	if current_state != BattleState.IN_PROGRESS:
		_pending_splash_pair_combo = false
		_pending_splash_pair_coop = false
		return
	if _check_battle_end() or _find_first_alive_monster() == null:
		_pending_splash_pair_combo = false
		_pending_splash_pair_coop = false
		return
	if is_coop:
		var pair: = _find_coop_pair()
		var cp = pair.get("player")
		if cp == null or (cp.has_method("is_alive") and not cp.is_alive()):
			if want_combo:
				_run_pending_splash_pair_combo()
			else:
				_pending_splash_pair_combo = false
				_pending_splash_pair_coop = false
			return
		var player_targets: Array = _pick_coop_player_attack_targets(cp)
		if player_targets.is_empty():
			if want_combo:
				_run_pending_splash_pair_combo()
			else:
				_pending_splash_pair_combo = false
				_pending_splash_pair_coop = false
			return
		_emit_unit_turn_with_target(
			_coop_unit_dict(cp), 
			_target_meta_from_monster(player_targets[0]), 
			_should_skip_lunge("coop_player", cp)
		)
		_schedule_attack_impact(_resolve_coop_player_attack.bind(cp, null, player_targets))
		return
	if player == null or not player.is_alive():
		if want_combo:
			_run_pending_splash_pair_combo()
		else:
			_pending_splash_pair_combo = false
		return
	if _is_local_player_defending():
		_log_defend_skip("player")
		if want_combo:
			_run_pending_splash_pair_combo()
		else:
			_pending_splash_pair_combo = false
		return
	var player_targets: Array = _pick_player_attack_targets()
	if player_targets.is_empty():
		if want_combo:
			_run_pending_splash_pair_combo()
		else:
			_pending_splash_pair_combo = false
		return
	_emit_unit_turn_with_target(
		_local_player_unit_dict(), 
		_target_meta_from_monster(player_targets[0]), 
		_should_skip_lunge("player")
	)
	_player_turn(player, player_targets)

func _run_pending_splash_pair_combo() -> void :
	if not _pending_splash_pair_combo:
		return
	var is_coop: = _pending_splash_pair_coop
	_pending_splash_pair_combo = false
	_pending_splash_pair_coop = false
	if current_state != BattleState.IN_PROGRESS:
		return
	if _check_battle_end() or _find_first_alive_monster() == null:
		return
	var combo_target = _pick_random_alive_monster()
	if combo_target == null:
		return
	if is_coop:
		var pair: = _find_coop_pair()
		var cpet = pair.get("pet")
		if cpet == null or (cpet.has_method("is_alive") and not cpet.is_alive()):
			return
		_coop_pet_turn(cpet, false, combo_target, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)
		return
	if active_pet == null or not active_pet.is_alive():
		return
	if _is_local_pet_defending():
		_log_defend_skip("pet")
		return
	_pet_turn(active_pet, false, combo_target, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)

func _execute_coop_pair_action() -> bool:
	var pair: = _find_coop_pair()
	var cp = pair.get("player")
	var cpet = pair.get("pet")
	var cp_alive: bool = cp != null and ( not cp.has_method("is_alive") or cp.is_alive())
	var cpet_alive: bool = cpet != null and ( not cpet.has_method("is_alive") or cpet.is_alive())
	if not cp_alive and not cpet_alive:
		return false
	if cp_alive and cpet_alive and _coop_battle_pet_has_splash(cpet):
		return _execute_splash_first_coop_pair(cp, cpet)
	var coop_player_target = _pick_random_alive_monster() if cp_alive else null
	var coop_player_targets: Array = [coop_player_target] if coop_player_target != null else []
	var coop_battle_pet: Pet = null
	if cpet != null and cpet.has_method("get_battle_pet"):
		coop_battle_pet = cpet.get_battle_pet()
	var coop_pet_target = _pick_pair_pet_target(coop_player_targets, coop_battle_pet, cp, cpet) if cpet_alive else null
	if coop_player_target == null and coop_pet_target == null:
		return false
	print("[BattleSystem] 执行回合(队友同出): ", str(cp.display_name) if cp_alive else "-", " + ", str(cpet.display_name) if cpet_alive else "-")
	var coop_pair_splash: Dictionary = {}
	if cp_alive and coop_player_target != null:
		_emit_unit_turn_with_target(
			_coop_unit_dict(cp), 
			_target_meta_from_monster(coop_player_target), 
			_should_skip_lunge("coop_player", cp)
		)
	if cpet_alive and coop_pet_target != null:
		coop_pair_splash = _prepare_pet_attack_splash(coop_battle_pet, coop_pet_target, true)
		_emit_unit_turn_with_target(
			_coop_unit_dict(cpet), 
			_target_meta_from_monster(coop_pet_target), 
			_should_skip_lunge("coop_pet", cpet, true, coop_pair_splash)
		)
	if cp_alive and coop_player_target != null:
		_coop_unit_turn(cp, coop_player_target)
	if cpet_alive and coop_pet_target != null:
		_coop_pet_turn(cpet, true, coop_pet_target, coop_pair_splash)
	return true

func _execute_monster_wave_action(action: Dictionary) -> bool:
	var units = action.get("units", [])
	if not (units is Array) or units.is_empty():
		return false
	var ran: = false
	var stagger_i: = 0
	for unit in units:
		if current_state != BattleState.IN_PROGRESS:
			break
		if _check_battle_end():
			break
		if typeof(unit) != TYPE_DICTIONARY:
			continue
		if _should_skip_turn_unit(unit):
			continue
		var monster_idx: = int(unit.get("index", -1))
		if monster_idx < 0 or monster_idx >= monsters.size():
			continue
		var current_monster = monsters[monster_idx]
		if not is_monster_alive(current_monster):
			continue
		if _consume_monster_acupoint_skip(monster_idx, unit.get("name", "怪物")):
			continue
		var ally_target = _pick_monster_ally_target()
		if ally_target == null:
			break
		print("[BattleSystem] 执行回合(同波): ", unit.get("name", "未知"), ", type=monster")
		_emit_unit_turn_with_target(unit, _target_meta_from_ally(ally_target))
		var impact_delay: = ATTACK_IMPACT_DELAY + float(stagger_i) * MONSTER_WAVE_STAGGER_SECONDS
		_monster_turn(current_monster, monster_idx, ally_target, impact_delay)
		ran = true
		stagger_i += 1
	return ran

func _run_turn_action(action: Dictionary) -> bool:
	if current_state != BattleState.IN_PROGRESS:
		return false
	var kind: = str(action.get("kind", ""))
	if kind == "local_joint":
		if player == null or not player.is_alive() or active_pet == null or not active_pet.is_alive():
			return false
		if _is_local_player_defending() or _is_local_pet_defending():
			return _execute_local_pair_action()
		var joint_target = _pick_random_alive_monster()
		if joint_target == null:
			return false
		print("[BattleSystem] 执行回合(合击): ", player.player_name, " + ", active_pet.pet_name)
		var joint_meta: = _target_meta_from_monster(joint_target)
		_emit_unit_turn_with_target(
			_local_player_unit_dict(), 
			joint_meta, 
			_should_skip_lunge("player", null, true, {}, false)
		)
		_emit_unit_turn_with_target(
			_local_pet_unit_dict(), 
			joint_meta, 
			_should_skip_lunge("pet", active_pet, false)
		)
		_joint_attack(player, active_pet, joint_target)
		return true
	if kind == "local_pair":
		return _execute_local_pair_action()
	if kind == "coop_joint":
		var pair: = _find_coop_pair()
		var cp = pair.get("player")
		var cpet = pair.get("pet")
		if cp == null or cpet == null:
			return false
		if cp.has_method("is_alive") and not cp.is_alive():
			return false
		if cpet.has_method("is_alive") and not cpet.is_alive():
			return false
		var coop_joint_target = _pick_random_alive_monster()
		if coop_joint_target == null:
			return false
		print("[BattleSystem] 执行回合(队友合击): ", cp.display_name, " + ", cpet.display_name)
		var coop_joint_meta: = _target_meta_from_monster(coop_joint_target)
		_emit_unit_turn_with_target(
			_coop_unit_dict(cp), 
			coop_joint_meta, 
			_should_skip_lunge("coop_player", cp, true, {}, false)
		)
		_emit_unit_turn_with_target(
			_coop_unit_dict(cpet), 
			coop_joint_meta, 
			_should_skip_lunge("coop_pet", cpet, false)
		)
		_coop_joint_attack(cp, cpet, coop_joint_target)
		return true
	if kind == "coop_pair":
		return _execute_coop_pair_action()
	if kind == "combo_pet":
		if active_pet == null or not active_pet.is_alive():
			return false
		if _is_local_pet_defending():
			_log_defend_skip("pet")
			return false
		var combo_target = _pick_random_alive_monster()
		if combo_target == null:
			return false
		if player:
			add_log("[color=#69db7c]%s 连击追击 %s![/color]" % [player.player_name, active_pet.pet_name])
		_emit_unit_turn_with_target(
			_local_pet_unit_dict(), 
			_target_meta_from_monster(combo_target), 
			_should_skip_lunge("pet", active_pet, false), 
			COMBO_LUNGE_TIME_SCALE
		)
		_pet_turn(active_pet, false, combo_target, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)
		return true
	if kind == "monster_wave":
		return _execute_monster_wave_action(action)
	if kind == "coop_combo_pet":
		var pair2: = _find_coop_pair()
		var cp2 = pair2.get("player")
		var cpet2 = pair2.get("pet")
		if cpet2 == null or (cpet2.has_method("is_alive") and not cpet2.is_alive()):
			return false
		var coop_combo_target = _pick_random_alive_monster()
		if coop_combo_target == null:
			return false
		var combo_cp_name: = str(cp2.display_name if cp2 != null and "display_name" in cp2 else "队友")
		var combo_pet_name: = str(cpet2.display_name if "display_name" in cpet2 else "队友宠")
		add_log("[color=#69db7c]%s 连击追击 %s![/color]" % [combo_cp_name, combo_pet_name])
		_emit_unit_turn_with_target(
			_coop_unit_dict(cpet2), 
			_target_meta_from_monster(coop_combo_target), 
			_should_skip_lunge("coop_pet", cpet2, false), 
			COMBO_LUNGE_TIME_SCALE
		)
		_coop_pet_turn(cpet2, false, coop_combo_target, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)
		return true
	if kind != "unit":
		return false
	var unit: Dictionary = action.get("unit", {})
	if unit.is_empty() or _should_skip_turn_unit(unit):
		return false
	var unit_type: String = str(unit.get("type", ""))
	print("[BattleSystem] 执行回合: ", unit.get("name", "未知"), ", type=", unit_type)
	match unit_type:
		"player":
			if _is_local_player_defending():
				_log_defend_skip("player")
				return false
			var targets: Array = _pick_player_attack_targets()
			var meta: = _target_meta_from_monster(targets[0]) if not targets.is_empty() else {}
			_emit_unit_turn_with_target(unit, meta, _should_skip_lunge("player"))
			_player_turn(unit.get("reference"), targets)
			return true
		"pet":
			if _is_local_pet_defending():
				_log_defend_skip("pet")
				return false
			var pet_target = _pick_random_alive_monster()
			if pet_target == null:
				return false
			var unit_pet = unit.get("reference")
			var unit_splash: Dictionary = _prepare_pet_attack_splash(unit_pet, pet_target, true)
			_emit_unit_turn_with_target(unit, _target_meta_from_monster(pet_target), _should_skip_lunge("pet", unit_pet, true, unit_splash))
			_pet_turn(unit_pet, true, pet_target, unit_splash)
			return true
		"coop_player", "coop_pet":
			var coop_target = _pick_random_alive_monster()
			if coop_target == null:
				return false
			var coop_splash: Dictionary = {}
			if unit_type == "coop_pet":
				coop_splash = _prepare_pet_attack_splash(_resolve_skip_lunge_battle_pet(unit_type, unit.get("reference")), coop_target, true)
			_emit_unit_turn_with_target(
				unit, 
				_target_meta_from_monster(coop_target), 
				_should_skip_lunge(unit_type, unit.get("reference"), true, coop_splash)
			)
			if unit_type == "coop_pet":
				_coop_pet_turn(unit.get("reference"), true, coop_target, coop_splash)
			else:
				_coop_unit_turn(unit.get("reference"), coop_target)
			return true
		"monster":
			var monster_idx: = int(unit.get("index", -1))
			if monster_idx < 0 or monster_idx >= monsters.size():
				return false
			var current_monster = monsters[monster_idx]
			if not is_monster_alive(current_monster):
				return false
			if _consume_monster_acupoint_skip(monster_idx, unit.get("name", "怪物")):
				return false
			var ally_target = _pick_monster_ally_target()
			if ally_target == null:
				return false
			_emit_unit_turn_with_target(unit, _target_meta_from_ally(ally_target))
			_monster_turn(current_monster, monster_idx, ally_target)
			return true
	return false

func _pair_leads_into_combo(kind: String) -> bool:
	if kind == "local_pair":
		if _pet_has_splash_skill(active_pet):
			return false
		return _exec_can_combo and not _is_local_pet_defending()
	if kind == "coop_pair":
		var pair: = _find_coop_pair()
		if _coop_battle_pet_has_splash(pair.get("pet")):
			return false
		return _coop_exec_can_combo
	return false

func _action_window_seconds(action: Dictionary) -> float:
	var kind: = str(action.get("kind", ""))
	if kind == "combo_pet" or kind == "coop_combo_pet":
		return COMBO_TURN_SECONDS
	if kind == "monster_wave":
		return ROUND_WINDOW_SECONDS
	if kind in ["local_joint", "coop_joint"]:
		return JOINT_TURN_SECONDS
	if kind == "local_pair" and _pet_has_splash_skill(active_pet):
		return JOINT_TURN_SECONDS
	if kind == "coop_pair":
		var pair: = _find_coop_pair()
		if _coop_battle_pet_has_splash(pair.get("pet")):
			return JOINT_TURN_SECONDS
	if _pair_leads_into_combo(kind):
		return ALLY_LUNGE_CYCLE_SECONDS
	return ROUND_WINDOW_SECONDS


func _await_action_window_from(segment_start_ms: int, window_seconds: float = ROUND_WINDOW_SECONDS) -> void :
	var elapsed_sec: float = float(Time.get_ticks_msec() - segment_start_ms) / 1000.0
	var remain_sec: float = maxf(0.0, window_seconds - elapsed_sec)
	if remain_sec > 0.0:
		await get_tree().create_timer(remain_sec).timeout

func _defer_battle_action(delay_sec: float, action: Callable) -> void :
	var gen: = _opening_settle_gen
	var wrapped: = func():
		if _is_stale_battle_gen(gen):
			return
		if current_state != BattleState.IN_PROGRESS:
			return
		action.call()
	if not is_inside_tree():
		wrapped.call()
		return
	get_tree().create_timer(maxf(0.0, delay_sec)).timeout.connect(wrapped, CONNECT_ONE_SHOT)

func _schedule_attack_impact(action: Callable) -> void :
	_defer_battle_action(ATTACK_IMPACT_DELAY, action)

func _resolve_battle_pet(pet: Variant, coop_unit: Variant = null) -> Pet:

	if pet != null and is_instance_valid(pet) and pet is Pet:
		return pet
	if coop_unit != null:
		if is_instance_valid(coop_unit) and coop_unit.has_method("get_battle_pet"):
			var bp = coop_unit.get_battle_pet()
			if bp != null and is_instance_valid(bp) and bp is Pet:
				return bp
		return null
	_refresh_battle_active_pet()
	if active_pet != null and is_instance_valid(active_pet):
		return active_pet
	return null

func _refresh_battle_active_pet() -> void :
	if active_pet == null:
		return
	var gm = GameManager.instance
	if gm == null:
		return

	if gm.is_brother_tower_battle or gm.is_arena_battle:
		return
	if is_instance_valid(active_pet) and gm.pet_manager:
		for p in gm.pet_manager.pets:
			if p is Object and p == active_pet:
				return
	print("[BattleSystem] active_pet 已被重建，重新绑定")
	active_pet = null
	gm.ensure_active_pet_ready_for_battle()
	if gm.pet_manager:
		active_pet = gm.pet_manager.active_pet
	elif gm.pet_bag_manager:
		active_pet = gm.pet_bag_manager.active_pet

func _dispatch_coop_ally_turns() -> void :
	if _find_first_alive_monster() == null:
		return
	var pair: = _find_coop_pair()
	var cp = pair.get("player")
	var cpet = pair.get("pet")
	var cp_alive: bool = cp != null and cp.has_method("is_alive") and cp.is_alive()
	var cpet_alive: bool = cpet != null and cpet.has_method("is_alive") and cpet.is_alive()
	if cp_alive and cpet_alive and _check_coop_joint_attack_condition(cp, cpet):
		var joint_target = _pick_random_alive_monster()
		if joint_target == null:
			return
		var cp_name: = str(cp.display_name if "display_name" in cp else "队友")
		var cpet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
		print("[BattleSystem] 执行回合(我方段-队友合击): ", cp_name, " + ", cpet_name)
		unit_turn.emit({
			"type": "coop_player", 
			"name": cp_name, 
			"agility": int(cp.agility if "agility" in cp else 1), 
			"reference": cp, 
			"skip_lunge": _should_skip_lunge("coop_player", cp, true, {}, false), 
		})
		_coop_joint_attack(cp, cpet, joint_target)
		return
	var pet_acted_before_player: = false
	var combo_follow_done: = false
	for unit in _get_ally_units_sorted():
		if _should_skip_turn_unit(unit):
			continue
		var unit_type: String = str(unit.get("type", ""))
		if unit_type not in ["coop_player", "coop_pet"]:
			continue
		if unit_type == "coop_pet" and _coop_exec_can_combo and combo_follow_done and pet_acted_before_player:
			continue
		print("[BattleSystem] 执行回合(我方段-队友): ", unit.get("name", "未知"), ", type=", unit_type)
		var coop_payload: Dictionary = (unit as Dictionary).duplicate()
		var coop_ref = unit.get("reference")
		var coop_splash: Dictionary = {}
		var coop_target = null
		if unit_type == "coop_pet":
			coop_target = _pick_random_alive_monster()
			coop_splash = _prepare_pet_attack_splash(_resolve_skip_lunge_battle_pet(unit_type, coop_ref), coop_target, true)
			coop_payload["skip_lunge"] = _should_skip_lunge(unit_type, coop_ref, true, coop_splash)
			var coop_meta: = _target_meta_from_monster(coop_target)
			if not coop_meta.is_empty():
				coop_payload["target_type"] = str(coop_meta.get("target_type", ""))
				coop_payload["target_index"] = int(coop_meta.get("target_index", -1))
		else:
			coop_payload["skip_lunge"] = _should_skip_lunge(unit_type, coop_ref, true)
		unit_turn.emit(coop_payload)
		if unit_type == "coop_player":
			_coop_unit_turn(coop_ref)
			if _coop_exec_can_combo and cpet_alive and not combo_follow_done:
				combo_follow_done = true
				if cpet != null and cpet.has_method("is_alive") and cpet.is_alive():
					var combo_cp_name: = str(cp.display_name if cp != null and "display_name" in cp else "队友")
					var combo_pet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
					add_log("[color=#69db7c]%s 连击追击 %s![/color]" % [combo_cp_name, combo_pet_name])
					unit_turn.emit({
						"type": "coop_pet", 
						"name": combo_pet_name, 
						"agility": int(cpet.agility if "agility" in cpet else 1), 
						"reference": cpet, 
						"skip_lunge": _should_skip_lunge("coop_pet", cpet, false), 
						"lunge_time_scale": COMBO_LUNGE_TIME_SCALE, 
					})
					_coop_pet_turn(cpet, false, null, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)
					if _check_battle_end():
						return
		elif unit_type == "coop_pet":
			pet_acted_before_player = true
			_coop_pet_turn(coop_ref, true, coop_target, coop_splash)

func _dispatch_ally_phase_sync() -> void :
	if _find_first_alive_monster() == null:
		return
	var player_alive: = player != null and player.is_alive()
	var pet_alive: = active_pet != null and active_pet.is_alive()
	if player_alive and pet_alive and _check_joint_attack_condition():
		var joint_target = _pick_random_alive_monster()
		if joint_target == null:
			return
		print("[BattleSystem] 执行回合(我方段-合击): ", player.player_name, " + ", active_pet.pet_name)
		unit_turn.emit({
			"type": "player", 
			"name": player.player_name, 
			"agility": player.get_agility(), 
			"reference": player, 
			"skip_lunge": _should_skip_lunge("player", null, true, {}, false), 
		})
		_joint_attack(player, active_pet, joint_target)
	else:
		var pet_acted_before_player: = false
		var combo_follow_done: = false
		for unit in _get_ally_units_sorted():
			if _should_skip_turn_unit(unit):
				continue
			var unit_type: String = str(unit.get("type", ""))
			if unit_type in ["coop_player", "coop_pet"]:
				continue

			if unit_type == "pet" and _exec_can_combo and combo_follow_done and pet_acted_before_player:
				continue
			print("[BattleSystem] 执行回合(我方段): ", unit.get("name", "未知"), ", type=", unit_type)
			var ally_payload: Dictionary = (unit as Dictionary).duplicate()
			var ally_splash: Dictionary = {}
			var ally_pet_target = null
			if unit_type == "pet":
				ally_pet_target = _pick_random_alive_monster()
				ally_splash = _prepare_pet_attack_splash(unit.get("reference"), ally_pet_target, true)
				ally_payload["skip_lunge"] = _should_skip_lunge(unit_type, unit.get("reference"), true, ally_splash)
				var ally_meta: = _target_meta_from_monster(ally_pet_target)
				if not ally_meta.is_empty():
					ally_payload["target_type"] = str(ally_meta.get("target_type", ""))
					ally_payload["target_index"] = int(ally_meta.get("target_index", -1))
			else:
				ally_payload["skip_lunge"] = _should_skip_lunge(unit_type, unit.get("reference"), true)
			unit_turn.emit(ally_payload)
			match unit_type:
				"player":
					_player_turn(unit.get("reference"))
					if _exec_can_combo and pet_alive and not combo_follow_done:
						combo_follow_done = true
						if active_pet and active_pet.is_alive():
							add_log("[color=#69db7c]%s 连击追击 %s![/color]" % [player.player_name, active_pet.pet_name])
							unit_turn.emit({
								"type": "pet", 
								"name": active_pet.pet_name, 
								"agility": active_pet.get_final_agility_with_equipment(), 
								"reference": active_pet, 
								"skip_lunge": _should_skip_lunge("pet", active_pet, false), 
								"lunge_time_scale": COMBO_LUNGE_TIME_SCALE, 
							})
							_pet_turn(active_pet, false, null, {}, ATTACK_IMPACT_DELAY * COMBO_LUNGE_TIME_SCALE)
							if _check_battle_end():
								return
				"pet":
					pet_acted_before_player = true
					_pet_turn(unit.get("reference"), true, ally_pet_target, ally_splash)
	if _check_battle_end():
		return
	_dispatch_coop_ally_turns()

func _dispatch_enemy_phase_sync() -> void :
	for unit in _get_monster_units_sorted():
		if current_state != BattleState.IN_PROGRESS:
			return
		if _should_skip_turn_unit(unit):
			continue
		print("[BattleSystem] 执行回合(敌方段): ", unit.get("name", "未知"), ", type=", unit.get("type", "未知"))
		_dispatch_unit_turn_sync(unit)


func _dispatch_unit_turn_sync(unit: Dictionary) -> void :
	print("[BattleSystem] _dispatch_unit_turn_sync: ", unit.get("name", "未知"), ", type=", unit.get("type", "未知"))
	var sync_payload: Dictionary = unit.duplicate()
	var sync_type: = str(unit.get("type", ""))
	var sync_splash: Dictionary = {}
	var sync_pet_target = null
	if sync_type == "pet" or sync_type == "coop_pet":
		sync_pet_target = _pick_random_alive_monster()
		sync_splash = _prepare_pet_attack_splash(_resolve_skip_lunge_battle_pet(sync_type, unit.get("reference")), sync_pet_target, true)
		var sync_meta: = _target_meta_from_monster(sync_pet_target)
		if not sync_meta.is_empty():
			sync_payload["target_type"] = str(sync_meta.get("target_type", ""))
			sync_payload["target_index"] = int(sync_meta.get("target_index", -1))
	sync_payload["skip_lunge"] = _should_skip_lunge(sync_type, unit.get("reference"), true, sync_splash)
	unit_turn.emit(sync_payload)
	match unit.get("type", ""):
		"player":
			_player_turn(unit.get("reference"))
		"pet":
			_pet_turn(unit.get("reference"), true, sync_pet_target, sync_splash)
		"coop_player":
			_coop_unit_turn(unit.get("reference"))
		"coop_pet":
			_coop_pet_turn(unit.get("reference"), true, sync_pet_target, sync_splash)
		"monster":
			var monster_idx: = int(unit.get("index", -1))
			if monster_idx < 0 or monster_idx >= monsters.size():
				return
			var current_monster = monsters[monster_idx]
			if not is_monster_alive(current_monster):
				return
			if _consume_monster_acupoint_skip(monster_idx, unit.get("name", "怪物")):
				return
			_monster_turn(current_monster, monster_idx)


func is_monster_alive(monster) -> bool:
	if monster is Dictionary:
		return monster.get("hp", 0) > 0
	elif monster.has_method("is_alive"):
		return monster.is_alive()
	return false

func _is_same_monster_ref(a, b) -> bool:
	if a == null or b == null:
		return false
	if is_same(a, b):
		return true
	var ia: = _monster_index_of(a)
	var ib: = _monster_index_of(b)
	return ia >= 0 and ia == ib

func _monster_list_has(arr: Array, monster) -> bool:
	if monster == null:
		return false
	for item in arr:
		if _is_same_monster_ref(item, monster):
			return true
	return false

func _check_combo_condition() -> bool:
	if not player or not active_pet:
		return false
	if not player.is_alive() or not active_pet.is_alive():
		return false

	if monsters.is_empty():
		return false

	var player_agility = player.get_agility()
	var pet_agility = active_pet.get_final_agility_with_equipment() if active_pet else 0

	for monster in monsters:
		if is_monster_alive(monster):
			var monster_agility = _get_monster_stat(monster, "agility", 0)
			if player_agility <= monster_agility or pet_agility <= monster_agility:
				return false

	return true

func _check_joint_attack_condition() -> bool:
	if not player or not active_pet:
		return false
	if not player.is_alive() or not active_pet.is_alive():
		return false
	if _is_local_player_defending() or _is_local_pet_defending():
		return false
	if monsters.is_empty():
		return false
	var player_agility = player.get_agility()
	var pet_agility = active_pet.get_final_agility_with_equipment()
	var has_alive: = false
	for monster in monsters:
		if not is_monster_alive(monster):
			continue
		has_alive = true
		var monster_agility = _get_monster_stat(monster, "agility", 0)
		if player_agility >= monster_agility or pet_agility >= monster_agility:
			return false
	return has_alive

func _find_coop_pair() -> Dictionary:
	var cp = null
	var cpet = null
	for cu in coop_units:
		if cu == null:
			continue
		var cu_type: = str(cu.unit_type if "unit_type" in cu else "")
		if cu_type == "coop_player" and cu.has_method("is_alive") and cu.is_alive():
			cp = cu
		elif cu_type == "coop_pet" and cu.has_method("is_alive") and cu.is_alive():
			cpet = cu
	return {"player": cp, "pet": cpet}

func _check_coop_joint_attack_condition(cp, cpet) -> bool:
	if cp == null or cpet == null:
		return false
	if cp.has_method("is_alive") and not cp.is_alive():
		return false
	if cpet.has_method("is_alive") and not cpet.is_alive():
		return false
	if monsters.is_empty():
		return false
	var player_agility: = int(cp.agility if "agility" in cp else 1)
	var pet_agility: = int(cpet.agility if "agility" in cpet else 1)
	var has_alive: = false
	for monster in monsters:
		if not is_monster_alive(monster):
			continue
		has_alive = true
		var monster_agility = _get_monster_stat(monster, "agility", 0)
		if player_agility >= monster_agility or pet_agility >= monster_agility:
			return false
	return has_alive

func _check_coop_combo_condition(cp, cpet) -> bool:
	if cp == null or cpet == null:
		return false
	if cp.has_method("is_alive") and not cp.is_alive():
		return false
	if cpet.has_method("is_alive") and not cpet.is_alive():
		return false
	if monsters.is_empty():
		return false
	var player_agility: = int(cp.agility if "agility" in cp else 1)
	var pet_agility: = int(cpet.agility if "agility" in cpet else 1)
	for monster in monsters:
		if is_monster_alive(monster):
			var monster_agility = _get_monster_stat(monster, "agility", 0)
			if player_agility <= monster_agility or pet_agility <= monster_agility:
				return false
	return true

func _refresh_coop_combo_state() -> void :
	var pair: = _find_coop_pair()
	var cp = pair.get("player")
	var cpet = pair.get("pet")
	_coop_exec_can_combo = _check_coop_combo_condition(cp, cpet)
	_coop_combo_guaranteed_hit = _coop_exec_can_combo
	if not _coop_exec_can_combo or cp == null or cpet == null:
		return
	var cp_name: = str(cp.display_name if "display_name" in cp else "队友")
	var cpet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
	add_log("[color=#69db7c]★ 连击触发! %s 和 %s 的敏捷都高于所有敌人! ★[/color]" % [cp_name, cpet_name], HIGHLIGHT_COMBO)

func _local_player_battle_element(fallback: String) -> String:
	return FabaoStatBonus.wild_player_element(fallback)

func _joint_attack(p: Player, pet: Pet, target) -> void :
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	add_log("[color=#69db7c]★ 合击触发! %s 和 %s 联手攻击 %s! ★[/color]" % [p.player_name, pet.pet_name, target_name], HIGHLIGHT_JOINT)
	_schedule_attack_impact(_resolve_joint_player_strike.bind(p, pet, target))

func _resolve_joint_player_strike(p: Player, pet: Variant, target: Variant) -> void :
	if current_state != BattleState.IN_PROGRESS:
		return
	if not is_monster_alive(target):
		_pet_joint_attacked = true
		_check_battle_end()
		return
	var triple_art = _find_equipped_martial_by_effect("triple_shot")
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var targets: Array
	if triple_ratio > 0.0:
		targets = _build_joint_triple_shot_targets(target, 3)
	else:
		targets = [target]
	if targets.is_empty():
		_pet_joint_attacked = true
		_check_battle_end()
		return
	var effective_attack: = p.get_attack()
	if triple_ratio > 0.0:
		effective_attack = maxi(1, int(float(effective_attack) * triple_ratio))
	var crit_stats: Dictionary = _get_player_crit_stats()
	var total_dealt: = 0
	var triple_banner_shown: = false
	for ti in range(targets.size()):
		var strike_target = targets[ti]
		if strike_target == null or not is_monster_alive(strike_target):
			continue
		var target_defense = _get_monster_stat(strike_target, "defense", 0)
		var target_element = _get_monster_stat(strike_target, "element", "普通")
		var target_name = _get_monster_stat(strike_target, "monster_name", _get_monster_stat(strike_target, "name", "怪物"))
		var player_base_damage = max(1, effective_attack - target_defense / 2)
		player_base_damage = int(player_base_damage * (0.8 + randf() * 0.4))
		var wild_el: = _local_player_battle_element(p.element)
		var player_element_result = GameData.calculate_damage_with_element(player_base_damage, wild_el, target_element, false)
		var player_damage = player_element_result.damage
		var crit_result: Dictionary = _apply_crit_to_damage(player_damage, crit_stats)
		player_damage = int(crit_result.get("damage", player_damage))
		var is_crit: bool = bool(crit_result.get("is_critical", false))
		_apply_damage_to_monster(strike_target, player_damage)
		total_dealt += player_damage
		var player_msg: = ""
		if triple_ratio > 0.0 and ti > 0:
			player_msg = "%s【三锋齐下】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [p.player_name, target_name, player_damage]
		else:
			player_msg = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [p.player_name, target_name, player_damage]
		if is_crit:
			player_msg += " [color=#ff922b]（暴击）[/color]"
		if player_element_result.message:
			player_msg += _format_element_effect_message(player_element_result.message)
		var log_hl: Dictionary = {}
		if triple_ratio > 0.0 and not triple_banner_shown:
			log_hl = _skill_highlight("三锋齐下", "player")
			triple_banner_shown = true
		add_log(player_msg, log_hl)
		_emit_damage_dealt(p.player_name, target_name, player_damage, is_crit, "monster", _monster_index_of(strike_target), wild_el, target_element)
		if not is_monster_alive(strike_target):
			add_log("[color=yellow]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	_try_trigger_player_life_steal(p, total_dealt)
	_check_battle_end()
	if current_state != BattleState.IN_PROGRESS:
		return
	if not is_monster_alive(target):
		_pet_joint_attacked = true
		_check_battle_end()
		return
	_defer_battle_action(JOINT_PET_IMPACT_EXTRA_DELAY, _resolve_joint_pet_strike.bind(p, pet, target))

func _resolve_joint_pet_strike(p: Player, pet: Variant, target: Variant) -> void :
	if current_state != BattleState.IN_PROGRESS:
		return
	pet = _resolve_battle_pet(pet)
	if pet == null:
		_pet_joint_attacked = true
		_check_battle_end()
		return
	if not is_monster_alive(target):
		_pet_joint_attacked = true
		_check_battle_end()
		return
	var target_defense = _get_monster_stat(target, "defense", 0)
	var target_element = _get_monster_stat(target, "element", "普通")
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	var pierce_res: Dictionary = _apply_pet_armor_pierce_defense(pet, target_defense, "pet")
	target_defense = float(pierce_res.get("defense", target_defense))
	var armor_pierced: bool = bool(pierce_res.get("pierced", false))
	var pet_base_damage = max(1, pet.get_final_attack_with_equipment() - target_defense / 2)
	pet_base_damage = int(pet_base_damage * (0.8 + randf() * 0.4))
	var pet_element_result = GameData.calculate_damage_with_element(pet_base_damage, pet.element, target_element, pet.is_evolution_pet)
	var pet_damage = pet_element_result.damage
	var pet_soul_bonus: = _get_pet_soul_bonus_percent(pet, target_element)
	var pet_soul_applies: = _is_element_counter_or_countered(pet.element, target_element)
	if pet_soul_applies and pet_soul_bonus > 0:
		pet_damage = max(1, int(pet_damage * (1.0 + pet_soul_bonus / 100.0)))
	var pet_crit_res: Dictionary = _apply_crit_to_damage(pet_damage, _get_pet_crit_stats(pet))
	pet_damage = int(pet_crit_res.get("damage", pet_damage))
	var pet_is_crit: bool = bool(pet_crit_res.get("is_critical", false))
	_apply_damage_to_monster(target, pet_damage)
	var pet_msg = "[color=green]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [pet.pet_name, target_name, pet_damage]
	if pet_is_crit:
		pet_msg += " [color=#ff922b]（暴击）[/color]"
	if pet_element_result.message:
		pet_msg += _format_element_effect_message(pet_element_result.message)
	if pet_soul_applies:
		pet_msg += " [color=#b197fc]（魂魄+%d%%）[/color]" % pet_soul_bonus
	add_log(pet_msg)
	_emit_damage_dealt(pet.pet_name, target_name, pet_damage, pet_is_crit, "monster", _monster_index_of(target), pet.element, target_element, armor_pierced)
	if not is_monster_alive(target):
		add_log("[color=yellow]%s 被击败了![/color]" % target_name)
		unit_died.emit(target_name)
	_try_trigger_pet_life_steal(pet, pet_damage, "pet")
	_pet_joint_attacked = true
	_check_battle_end()

func _coop_joint_attack(cp, cpet, target) -> void :
	var cp_name: = str(cp.display_name if "display_name" in cp else "队友")
	var cpet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	add_log("[color=#69db7c]★ 合击触发! %s 和 %s 联手攻击 %s! ★[/color]" % [cp_name, cpet_name, target_name], HIGHLIGHT_JOINT)
	_schedule_attack_impact(_resolve_coop_joint_player_strike.bind(cp, cpet, target))

func _resolve_coop_joint_player_strike(cp, cpet, target) -> void :
	if current_state != BattleState.IN_PROGRESS:
		return
	if not is_monster_alive(target):
		_coop_pet_joint_attacked = true
		_check_battle_end()
		return
	var cp_name: = str(cp.display_name if "display_name" in cp else "队友")
	var cp_element: = str(cp.element if "element" in cp else "普通")
	var triple_art = cp.find_martial_by_effect("triple_shot") if cp.has_method("find_martial_by_effect") else null
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var targets: Array
	if triple_ratio > 0.0:
		targets = _build_joint_triple_shot_targets(target, 3)
	else:
		targets = [target]
	if targets.is_empty():
		_coop_pet_joint_attacked = true
		_check_battle_end()
		return
	var effective_attack: = int(cp.attack if "attack" in cp else 1)
	if triple_ratio > 0.0:
		effective_attack = maxi(1, int(float(effective_attack) * triple_ratio))
	var crit_stats: Dictionary = _get_coop_crit_stats(cp)
	var total_dealt: = 0
	var triple_banner_shown: = false
	for ti in range(targets.size()):
		var strike_target = targets[ti]
		if strike_target == null or not is_monster_alive(strike_target):
			continue
		var target_defense = _get_monster_stat(strike_target, "defense", 0)
		var target_element = _get_monster_stat(strike_target, "element", "普通")
		var target_name = _get_monster_stat(strike_target, "monster_name", _get_monster_stat(strike_target, "name", "怪物"))
		var player_base_damage = max(1, effective_attack - target_defense / 2)
		player_base_damage = int(player_base_damage * (0.8 + randf() * 0.4))
		var player_element_result = GameData.calculate_damage_with_element(player_base_damage, cp_element, target_element, false)
		var player_damage = player_element_result.damage
		var crit_result: Dictionary = _apply_crit_to_damage(player_damage, crit_stats)
		player_damage = int(crit_result.get("damage", player_damage))
		var is_crit: bool = bool(crit_result.get("is_critical", false))
		_apply_damage_to_monster(strike_target, player_damage)
		total_dealt += player_damage
		var player_msg: = ""
		if triple_ratio > 0.0 and ti > 0:
			player_msg = "%s【三锋齐下】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [cp_name, target_name, player_damage]
		else:
			player_msg = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [cp_name, target_name, player_damage]
		if is_crit:
			player_msg += " [color=#ff922b]（暴击）[/color]"
		if player_element_result.message:
			player_msg += _format_element_effect_message(player_element_result.message)
		var log_hl: Dictionary = {}
		if triple_ratio > 0.0 and not triple_banner_shown:
			log_hl = _skill_highlight("三锋齐下", "coop_player")
			triple_banner_shown = true
		add_log(player_msg, log_hl)
		_emit_damage_dealt(cp_name, target_name, player_damage, is_crit, "monster", _monster_index_of(strike_target), cp_element, target_element)
		if not is_monster_alive(strike_target):
			add_log("[color=yellow]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	_try_trigger_coop_life_steal(cp, total_dealt)
	_check_battle_end()
	if current_state != BattleState.IN_PROGRESS:
		return
	if not is_monster_alive(target):
		_coop_pet_joint_attacked = true
		_check_battle_end()
		return
	_defer_battle_action(JOINT_PET_IMPACT_EXTRA_DELAY, _resolve_coop_joint_pet_strike.bind(cp, cpet, target))

func _resolve_coop_joint_pet_strike(cp, cpet, target) -> void :
	if current_state != BattleState.IN_PROGRESS:
		return
	if cpet == null or (cpet.has_method("is_alive") and not cpet.is_alive()):
		_coop_pet_joint_attacked = true
		_check_battle_end()
		return
	if not is_monster_alive(target):
		_coop_pet_joint_attacked = true
		_check_battle_end()
		return
	var cpet_name: = str(cpet.display_name if "display_name" in cpet else "队友宠")
	var target_defense = _get_monster_stat(target, "defense", 0)
	var target_element = _get_monster_stat(target, "element", "普通")
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	var battle_pet: Pet = cpet.get_battle_pet() if cpet.has_method("get_battle_pet") else null
	var pet_element: = str(cpet.element if "element" in cpet else "普通")
	var is_evo: = bool(cpet.is_evolution_pet if "is_evolution_pet" in cpet else false)
	var armor_pierced: = false
	if battle_pet != null:
		pet_element = battle_pet.element
		is_evo = battle_pet.is_evolution_pet
		var pierce_res: Dictionary = _apply_pet_armor_pierce_defense(battle_pet, target_defense, "coop_pet")
		target_defense = float(pierce_res.get("defense", target_defense))
		armor_pierced = bool(pierce_res.get("pierced", false))
	var pet_base_damage = max(1, _coop_pet_attack_value(cpet, battle_pet) - target_defense / 2)
	pet_base_damage = int(pet_base_damage * (0.8 + randf() * 0.4))
	var pet_element_result = GameData.calculate_damage_with_element(pet_base_damage, pet_element, target_element, is_evo)
	var pet_damage = pet_element_result.damage
	var pet_soul_bonus: = _coop_soul_bonus(cpet, pet_element, battle_pet, target_element)
	var pet_soul_applies: = _is_element_counter_or_countered(pet_element, target_element)
	if pet_soul_applies and pet_soul_bonus > 0:
		pet_damage = max(1, int(pet_damage * (1.0 + pet_soul_bonus / 100.0)))
	var coop_joint_crit_pet: Pet = battle_pet if battle_pet != null else null
	var coop_joint_crit_res: Dictionary = _apply_crit_to_damage(pet_damage, _get_pet_crit_stats(coop_joint_crit_pet))
	pet_damage = int(coop_joint_crit_res.get("damage", pet_damage))
	var coop_joint_is_crit: bool = bool(coop_joint_crit_res.get("is_critical", false))
	_apply_damage_to_monster(target, pet_damage)
	var pet_msg = "[color=green]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [cpet_name, target_name, pet_damage]
	if coop_joint_is_crit:
		pet_msg += " [color=#ff922b]（暴击）[/color]"
	if pet_element_result.message:
		pet_msg += _format_element_effect_message(pet_element_result.message)
	if pet_soul_applies:
		pet_msg += " [color=#b197fc]（魂魄+%d%%）[/color]" % pet_soul_bonus
	add_log(pet_msg)
	_emit_damage_dealt(cpet_name, target_name, pet_damage, coop_joint_is_crit, "monster", _monster_index_of(target), pet_element, target_element, armor_pierced)
	if not is_monster_alive(target):
		add_log("[color=yellow]%s 被击败了![/color]" % target_name)
		unit_died.emit(target_name)
	_coop_pet_joint_attacked = true
	_check_battle_end()

func _process_turn(unit: Dictionary):
	print("[BattleSystem] _process_turn: ", unit.get("name", "未知"), ", type=", unit.get("type", "未知"))
	var process_payload: Dictionary = unit.duplicate()
	var process_type: = str(unit.get("type", ""))
	var process_splash: Dictionary = {}
	var process_pet_target = null
	if process_type == "pet" or process_type == "coop_pet":
		process_pet_target = _pick_random_alive_monster()
		process_splash = _prepare_pet_attack_splash(_resolve_skip_lunge_battle_pet(process_type, unit.get("reference")), process_pet_target, true)
		var process_meta: = _target_meta_from_monster(process_pet_target)
		if not process_meta.is_empty():
			process_payload["target_type"] = str(process_meta.get("target_type", ""))
			process_payload["target_index"] = int(process_meta.get("target_index", -1))
	process_payload["skip_lunge"] = _should_skip_lunge(process_type, unit.get("reference"), true, process_splash)
	unit_turn.emit(process_payload)

	match unit.get("type", ""):
		"player":
			await _player_turn(unit.get("reference"))
		"pet":
			await _pet_turn(unit.get("reference"), true, process_pet_target, process_splash)
		"monster":
			var monster_idx: = int(unit.get("index", -1))
			if monster_idx < 0 or monster_idx >= monsters.size():
				return
			var current_monster = monsters[monster_idx]
			if not is_monster_alive(current_monster):
				return
			if _consume_monster_acupoint_skip(monster_idx, unit.get("name", "怪物")):
				return
			await _monster_turn(current_monster, monster_idx)
		"coop_player":
			await _coop_unit_turn(unit.get("reference"))
		"coop_pet":
			await _coop_pet_turn(unit.get("reference"), true, process_pet_target, process_splash)


func _coop_unit_turn(unit, pre_picked_target = null) -> void :
	if unit == null:
		return
	var target = pre_picked_target if pre_picked_target != null else _pick_random_alive_monster()
	if target == null:
		return
	_schedule_attack_impact(_resolve_coop_attack.bind(unit, target))

func _resolve_coop_attack(unit, pre_picked_target = null) -> void :
	if unit == null or current_state != BattleState.IN_PROGRESS:
		return
	if unit.has_method("is_alive") and not unit.is_alive():
		return
	if str(unit.unit_type) == "coop_player":
		_resolve_coop_player_attack(unit, pre_picked_target)
		return
	if unit.has_method("has_battle_pet_skills") and unit.has_battle_pet_skills():
		var battle_pet: Pet = unit.get_battle_pet()
		if battle_pet != null:
			_resolve_pet_attack(battle_pet, true, "coop_pet", unit, pre_picked_target)
			return
	var target = pre_picked_target if pre_picked_target != null else _pick_random_alive_monster()
	if not target:
		return
	var target_defense = _get_monster_stat(target, "defense", 0)
	var target_element = _get_monster_stat(target, "element", "普通")
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	var atk: = int(unit.attack)
	var base_damage = max(1, atk - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))
	var is_evo: = str(unit.unit_type) == "coop_pet" and bool(unit.is_evolution_pet)
	var element_result = GameData.calculate_damage_with_element(base_damage, str(unit.element), target_element, is_evo)
	var damage = element_result.damage
	if str(unit.unit_type) == "coop_pet":
		var soul_applies: = _is_element_counter_or_countered(str(unit.element), target_element)
		var soul_bonus: = _coop_soul_bonus(unit, str(unit.element), null, target_element)
		if soul_applies and soul_bonus > 0:
			damage = max(1, int(damage * (1.0 + soul_bonus / 100.0)))
	var msg: = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [unit.display_name, target_name, damage]
	if str(unit.unit_type) == "coop_pet":
		var soul_applies_log: = _is_element_counter_or_countered(str(unit.element), target_element)
		var soul_bonus_log: = _coop_soul_bonus(unit, str(unit.element), null, target_element)
		if soul_applies_log and soul_bonus_log > 0:
			msg += " [color=#b197fc]（魂魄+%d%%）[/color]" % soul_bonus_log
	add_log(msg)
	_apply_damage_to_monster(target, damage)
	_emit_damage_dealt(unit.display_name, target_name, damage, false, "monster", _monster_index_of(target), str(unit.element), target_element)
	if not is_monster_alive(target):
		add_log("[color=yellow]%s 被击败了![/color]" % target_name)
		unit_died.emit(target_name)
	_check_battle_end()

func _resolve_coop_player_attack(unit, pre_picked_target = null, pre_picked_targets: Array = []) -> void :
	if unit == null or current_state != BattleState.IN_PROGRESS:
		return
	if unit.has_method("is_alive") and not unit.is_alive():
		return
	var triple_art = unit.find_martial_by_effect("triple_shot") if unit.has_method("find_martial_by_effect") else null
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var target_count: = 3 if (_coop_kuihua_attack_active(unit) or triple_ratio > 0.0) else 1
	var targets: Array = []
	if not pre_picked_targets.is_empty():
		for t in pre_picked_targets:
			if t != null and is_monster_alive(t) and not targets.has(t):
				targets.append(t)
		if targets.is_empty() and pre_picked_targets.size() == 1:
			var alt = _pick_random_alive_monster()
			if alt != null:
				targets.append(alt)
	else:
		targets = _pick_random_alive_monsters(target_count)
		if pre_picked_target != null and is_monster_alive(pre_picked_target):
			if targets.has(pre_picked_target):
				targets.erase(pre_picked_target)
			targets.insert(0, pre_picked_target)
			while targets.size() > target_count:
				targets.pop_back()
	if targets.is_empty():
		_run_pending_splash_pair_combo()
		return
	var primary = targets[0]
	var primary_agility = _get_monster_stat(primary, "agility", 10)
	var primary_name = _get_monster_stat(primary, "monster_name", _get_monster_stat(primary, "name", "怪物"))
	var unit_agility: = int(unit.agility if "agility" in unit else 1)
	if not _coop_combo_guaranteed_hit and not _check_hit(unit_agility, primary_agility):
		add_log("%s 攻击 %s, [color=gray]但是未命中![/color]" % [unit.display_name, primary_name])
		_emit_damage_dealt(unit.display_name, primary_name, 0, false, "monster", _monster_index_of(primary))
		_check_battle_end()
		_run_pending_splash_pair_combo()
		return
	if _coop_kuihua_attack_active(unit):
		if targets.size() < 3:
			for extra in _pick_random_alive_monsters(3 - targets.size(), targets):
				targets.append(extra)
		var kuihua_total: = 0
		var kuihua_banner_shown: = false
		var struck: Array = []
		var skill_anchor: = str(unit.unit_type) if "unit_type" in unit else "coop_player"
		var kuihua_hl: Dictionary = _skill_highlight("葵花点穴", skill_anchor)
		for ti in range(targets.size()):
			var target = targets[ti]
			if target == null or not is_monster_alive(target):
				continue
			var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
			var damage: = 1
			_apply_damage_to_monster(target, damage)
			kuihua_total += damage
			var msg: = "%s【葵花点穴】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [unit.display_name, target_name, damage]
			var log_hl: Dictionary = {}
			if not kuihua_banner_shown:
				log_hl = kuihua_hl
				kuihua_banner_shown = true
			add_log(msg, log_hl)
			_emit_damage_dealt(unit.display_name, target_name, damage, false, "monster", _monster_index_of(target))
			if is_monster_alive(target):
				struck.append(target)
			else:
				add_log("[color=yellow]%s 被击败了![/color]" % target_name)
				unit_died.emit(target_name)
		_try_trigger_kuihua_acupoint_coop(unit, struck)
		_try_trigger_coop_life_steal(unit, kuihua_total)
		_check_battle_end()
		_run_pending_splash_pair_combo()
		return
	var effective_attack: = int(unit.attack)
	if triple_ratio > 0.0:
		effective_attack = maxi(1, int(float(effective_attack) * triple_ratio))
	var crit_stats: Dictionary = _get_coop_crit_stats(unit)
	var total_dealt: = 0
	var triple_banner_shown: = false
	for ti in range(targets.size()):
		var target = targets[ti]
		if target == null or not is_monster_alive(target):
			continue
		var target_defense = _get_monster_stat(target, "defense", 0)
		var target_element = _get_monster_stat(target, "element", "普通")
		var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
		var base_damage = max(1, effective_attack - target_defense / 2)
		base_damage = int(base_damage * (0.8 + randf() * 0.4))
		var element_result = GameData.calculate_damage_with_element(
			base_damage, 
			str(unit.element), 
			target_element, 
			false
		)
		var damage = element_result.damage
		var crit_result: Dictionary = _apply_crit_to_damage(damage, crit_stats)
		damage = int(crit_result.get("damage", damage))
		var is_crit: bool = bool(crit_result.get("is_critical", false))
		_apply_damage_to_monster(target, damage)
		total_dealt += damage
		var msg: = ""
		if triple_ratio > 0.0:
			msg = "%s【三锋齐下】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [unit.display_name, target_name, damage]
		else:
			msg = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [unit.display_name, target_name, damage]
		if is_crit:
			msg += " [color=#ff922b]（暴击）[/color]"
		if element_result.message:
			msg += _format_element_effect_message(element_result.message)
		var skill_anchor: = str(unit.unit_type) if "unit_type" in unit else "coop_player"
		var log_hl: Dictionary = {}
		if triple_ratio > 0.0 and not triple_banner_shown:
			log_hl = _skill_highlight("三锋齐下", skill_anchor)
			triple_banner_shown = true
		add_log(msg, log_hl)
		_emit_damage_dealt(unit.display_name, target_name, damage, is_crit, "monster", _monster_index_of(target), str(unit.element), target_element)
		if not is_monster_alive(target):
			add_log("[color=yellow]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	_try_trigger_coop_life_steal(unit, total_dealt)
	_check_battle_end()
	_run_pending_splash_pair_combo()

func _player_turn(p: Player, pre_picked_targets: Array = []) -> void :
	if _is_local_player_defending():
		_log_defend_skip("player")
		_run_pending_splash_pair_combo()
		return
	if _find_first_alive_monster() == null:
		_run_pending_splash_pair_combo()
		return
	if _check_joint_attack_condition():
		var joint_target = _pick_random_alive_monster()
		if joint_target:
			_joint_attack(p, active_pet, joint_target)
		_run_pending_splash_pair_combo()
		return
	var targets: Array = pre_picked_targets if not pre_picked_targets.is_empty() else _pick_player_attack_targets()
	if targets.is_empty():
		_run_pending_splash_pair_combo()
		return
	_schedule_attack_impact(_resolve_player_attack.bind(p, targets))

func _resolve_player_attack(p: Player, pre_picked_targets: Array = []) -> void :
	if p == null or not is_instance_valid(p):
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	var triple_art = _find_equipped_martial_by_effect("triple_shot")
	var triple_ratio: = 0.0
	if triple_art != null:
		triple_ratio = triple_art.get_triple_shot_damage_ratio()
	var targets: Array = pre_picked_targets if not pre_picked_targets.is_empty() else _pick_player_attack_targets()
	if targets.size() == 1 and (targets[0] == null or not is_monster_alive(targets[0])):
		var alt = _pick_random_alive_monster()
		targets = [alt] if alt != null else []
	if targets.is_empty():
		_run_pending_splash_pair_combo()
		return
	var primary = targets[0]
	var primary_agility = _get_monster_stat(primary, "agility", 10)
	var primary_name = _get_monster_stat(primary, "monster_name", _get_monster_stat(primary, "name", "怪物"))
	if not _combo_guaranteed_hit and not _check_hit(p.get_agility(), primary_agility):
		add_log("%s 攻击 %s, [color=gray]但是未命中![/color]" % [p.player_name, primary_name])
		_emit_damage_dealt(p.player_name, primary_name, 0, false, "monster", _monster_index_of(primary))
		_check_battle_end()
		_run_pending_splash_pair_combo()
		return
	if _local_kuihua_attack_active():
		if targets.size() < 3:
			for extra in _pick_random_alive_monsters(3 - targets.size(), targets):
				targets.append(extra)
		var kuihua_total: = 0
		var kuihua_banner_shown: = false
		var struck: Array = []
		var kuihua_hl: Dictionary = _skill_highlight("葵花点穴", "player")
		for ti in range(targets.size()):
			var target = targets[ti]
			if target == null or not is_monster_alive(target):
				continue
			var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
			var damage: = 1
			_apply_damage_to_monster(target, damage)
			kuihua_total += damage
			var msg: = "%s【葵花点穴】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [p.player_name, target_name, damage]
			var log_hl: Dictionary = {}
			if not kuihua_banner_shown:
				log_hl = kuihua_hl
				kuihua_banner_shown = true
			add_log(msg, log_hl)
			_emit_damage_dealt(p.player_name, target_name, damage, false, "monster", _monster_index_of(target))
			if is_monster_alive(target):
				struck.append(target)
			else:
				add_log("[color=yellow]%s 被击败了![/color]" % target_name)
				unit_died.emit(target_name)
		_try_trigger_kuihua_acupoint(p, struck)
		_try_trigger_player_life_steal(p, kuihua_total)
		_check_battle_end()
		_run_pending_splash_pair_combo()
		return
	var effective_attack: = p.get_attack()
	if triple_ratio > 0.0:
		effective_attack = maxi(1, int(float(effective_attack) * triple_ratio))
	var crit_stats: Dictionary = _get_player_crit_stats()
	var total_dealt: = 0
	var triple_banner_shown: = false
	for ti in range(targets.size()):
		var target = targets[ti]
		if target == null or not is_monster_alive(target):
			continue
		var target_defense = _get_monster_stat(target, "defense", 0)
		var target_element = _get_monster_stat(target, "element", "普通")
		var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
		var base_damage = max(1, effective_attack - target_defense / 2)
		base_damage = int(base_damage * (0.8 + randf() * 0.4))
		var wild_el: = _local_player_battle_element(p.element)
		var element_result = GameData.calculate_damage_with_element(
			base_damage, 
			wild_el, 
			target_element, 
			false
		)
		var damage = element_result.damage
		var crit_result: Dictionary = _apply_crit_to_damage(damage, crit_stats)
		damage = int(crit_result.get("damage", damage))
		var is_crit: bool = bool(crit_result.get("is_critical", false))
		_apply_damage_to_monster(target, damage)
		total_dealt += damage
		var msg: = ""
		if triple_ratio > 0.0 and ti > 0:
			msg = "%s【三锋齐下】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [p.player_name, target_name, damage]
		else:
			msg = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [p.player_name, target_name, damage]
		if is_crit:
			msg += " [color=#ff922b]（暴击）[/color]"
		if element_result.message:
			msg += _format_element_effect_message(element_result.message)
		var log_hl: Dictionary = {}
		if triple_ratio > 0.0 and not triple_banner_shown:
			log_hl = _skill_highlight("三锋齐下", "player")
			triple_banner_shown = true
		add_log(msg, log_hl)
		_emit_damage_dealt(p.player_name, target_name, damage, is_crit, "monster", _monster_index_of(target), wild_el, target_element)
		if not is_monster_alive(target):
			add_log("[color=yellow]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	_try_trigger_player_life_steal(p, total_dealt)
	_check_battle_end()
	_run_pending_splash_pair_combo()

func _pet_turn(pet: Pet, allow_pet_splash: bool = true, pre_picked_target = null, splash_plan: Dictionary = {}, impact_delay: float = -1.0) -> bool:
	if pet == null or not is_instance_valid(pet):
		return false
	if _is_local_pet_defending():
		_log_defend_skip("pet")
		return false
	if _pet_joint_attacked:
		return false
	if _check_joint_attack_condition():
		return false
	var target = pre_picked_target if pre_picked_target != null else _pick_random_alive_monster()
	if not target:
		return false
	var delay: = ATTACK_IMPACT_DELAY if impact_delay < 0.0 else impact_delay
	_defer_battle_action(delay, _resolve_pet_attack.bind(pet, allow_pet_splash, "pet", null, target, splash_plan))
	return true

func _coop_pet_turn(coop_unit, allow_pet_splash: bool = true, pre_picked_target = null, splash_plan: Dictionary = {}, impact_delay: float = -1.0) -> bool:
	if coop_unit == null:
		return false
	if coop_unit.has_method("is_alive") and not coop_unit.is_alive():
		return false
	if _coop_pet_joint_attacked:
		return false
	var pair: = _find_coop_pair()
	if _check_coop_joint_attack_condition(pair.get("player"), pair.get("pet")):
		return false
	var target = pre_picked_target if pre_picked_target != null else _pick_random_alive_monster()
	if target == null:
		return false
	var delay: = ATTACK_IMPACT_DELAY if impact_delay < 0.0 else impact_delay
	if coop_unit.has_method("has_battle_pet_skills") and coop_unit.has_battle_pet_skills():
		var battle_pet: Pet = coop_unit.get_battle_pet()
		if battle_pet != null:
			_defer_battle_action(delay, _resolve_pet_attack.bind(battle_pet, allow_pet_splash, "coop_pet", coop_unit, target, splash_plan))
			return true
	_defer_battle_action(delay, _resolve_coop_attack.bind(coop_unit, target))
	return true

func _resolve_pet_attack(pet: Variant, allow_pet_splash: bool, skill_anchor: String = "pet", coop_unit: Variant = null, pre_picked_target: Variant = null, splash_plan: Dictionary = {}) -> void :
	pet = _resolve_battle_pet(pet, coop_unit)
	if pet == null:
		return
	_resolve_pet_attack_body(pet, allow_pet_splash, skill_anchor, coop_unit, pre_picked_target, splash_plan)
	_run_pending_splash_pair_player()

func _resolve_pet_attack_body(pet: Pet, allow_pet_splash: bool, skill_anchor: String = "pet", coop_unit = null, pre_picked_target = null, splash_plan: Dictionary = {}) -> void :
	pet = _resolve_battle_pet(pet, coop_unit)
	if pet == null:
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	if _pet_joint_attacked:
		return
	var target = pre_picked_target if pre_picked_target != null else _pick_random_alive_monster()
	if target != null and not is_monster_alive(target):
		target = _pick_random_alive_monster()
	if not target:
		return
	var target_defense = _get_monster_stat(target, "defense", 0)
	var target_element = _get_monster_stat(target, "element", "普通")
	var target_agility = _get_monster_stat(target, "agility", 10)
	var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
	var combo_hit: = _coop_combo_guaranteed_hit if coop_unit != null else _combo_guaranteed_hit
	if not combo_hit and not _check_hit(_coop_pet_agility_value(coop_unit, pet), target_agility):
		add_log("[color=green]%s[/color] 攻击 %s, [color=gray]但是未命中![/color]" % [pet.pet_name, target_name])
		_emit_damage_dealt(pet.pet_name, target_name, 0, false, "monster", _monster_index_of(target))
		_check_battle_end()
		return
	var attack_with_equipment: = _coop_pet_attack_value(coop_unit, pet)
	var pierce_res: Dictionary = _apply_pet_armor_pierce_defense(pet, target_defense, skill_anchor)
	target_defense = float(pierce_res.get("defense", target_defense))
	var armor_pierced: bool = bool(pierce_res.get("pierced", false))
	var base_damage = max(1, attack_with_equipment - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))
	var element_result = GameData.calculate_damage_with_element(
		base_damage, 
		pet.element, 
		target_element, 
		pet.is_evolution_pet
	)
	var damage = element_result.damage
	var pet_soul_bonus: = _coop_soul_bonus(coop_unit, pet.element, pet, target_element)
	var pet_soul_applies: = _is_element_counter_or_countered(pet.element, target_element)
	if pet_soul_applies and pet_soul_bonus > 0:
		damage = max(1, int(damage * (1.0 + pet_soul_bonus / 100.0)))
	var pet_crit: = _get_pet_crit_stats(pet)
	var pet_crit_res: Dictionary = _apply_crit_to_damage(damage, pet_crit)
	damage = int(pet_crit_res.get("damage", damage))
	var pet_is_crit: bool = bool(pet_crit_res.get("is_critical", false))
	_apply_damage_to_monster(target, damage)
	var msg = "[color=green]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [pet.pet_name, target_name, damage]
	if element_result.message:
		msg += _format_element_effect_message(element_result.message)
	if pet_soul_applies:
		msg += " [color=#b197fc]（魂魄+%d%%）[/color]" % pet_soul_bonus
	if pet_is_crit:
		msg += " [color=#ff922b]（暴击）[/color]"
	add_log(msg)
	_emit_damage_dealt(pet.pet_name, target_name, damage, pet_is_crit, "monster", _monster_index_of(target), pet.element, target_element, armor_pierced)
	var pet_total_dealt: int = int(damage)
	if not is_monster_alive(target):
		add_log("[color=#ffd43b]%s 被击败了![/color]" % target_name)
		unit_died.emit(target_name)
	var splash_did_trigger: = false
	if allow_pet_splash:
		var splash_rolled: = bool(splash_plan.get("rolled", false))
		if splash_rolled:
			if bool(splash_plan.get("triggered", false)):
				splash_did_trigger = true
				pet_total_dealt += _apply_prepicked_splash_hits(pet, splash_plan, target, skill_anchor, coop_unit)
		else:
			var splash_dealt: = _try_trigger_pet_splash(pet, target, skill_anchor, coop_unit)
			if splash_dealt > 0:
				splash_did_trigger = true
				pet_total_dealt += splash_dealt
			if splash_dealt <= 0 and _pet_skill_battle:
				var skill_trigger: = _pet_skill_battle.get_attack_skill_trigger(pet)
				if not skill_trigger.is_empty():
					var sk_config: Dictionary = skill_trigger.get("config", {})
					var sk_id: String = str(skill_trigger.get("skill_id", ""))
					if sk_id == "splash":
						var extra_n: = maxi(0, int(sk_config.get("target_count", 2)) - 1)
						if extra_n > 0:
							splash_did_trigger = true
							var ratio: float = float(sk_config.get("damage_ratio", 1.0))
							var splash_targets: Array = _pick_random_alive_monsters(extra_n, [target])
							for extra_idx in range(splash_targets.size()):
								var next_target = splash_targets[extra_idx]
								if next_target == null:
									continue
								var splash_calc: Dictionary = _calc_pet_splash_damage_to_monster(pet, next_target, ratio, coop_unit)
								var splash_dmg: = int(splash_calc.get("damage", 1))
								var splash_pierced: bool = bool(splash_calc.get("pierced", false))
								var splash_crit: Dictionary = _apply_crit_to_damage(splash_dmg, _get_pet_crit_stats(pet))
								splash_dmg = int(splash_crit.get("damage", splash_dmg))
								var splash_is_crit: bool = bool(splash_crit.get("is_critical", false))
								var tname = _get_monster_stat(next_target, "monster_name", _get_monster_stat(next_target, "name", "怪物"))
								var splash_hl: Dictionary = _skill_highlight("溅射", skill_anchor) if extra_idx == 0 else {}
								splash_hl = _attach_splash_hit_fx(splash_hl, _monster_index_of(next_target))
								var splash_msg: = "%s✦溅射触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点溅射伤害" % [BATTLE_SKILL_LOG, pet.pet_name, tname, splash_dmg]
								if splash_is_crit:
									splash_msg += " [color=#ff922b]（暴击）[/color]"
								add_log(splash_msg, splash_hl)
								_apply_damage_to_monster(next_target, splash_dmg)
								pet_total_dealt += splash_dmg
								_emit_damage_dealt(pet.pet_name, tname, splash_dmg, splash_is_crit, "monster", _monster_index_of(next_target), pet.element, _get_monster_stat(next_target, "element", "普通"), splash_pierced)
								if not is_monster_alive(next_target):
									add_log("[color=#ffd43b]%s 被击败了![/color]" % tname)
									unit_died.emit(tname)
					elif sk_id == "double_shot":
						var ratio2: float = float(sk_config.get("damage_ratio_per_hit", 1.0))
						var extra_swings: int = maxi(0, int(sk_config.get("hit_count", 3)) - 1)
						if extra_swings > 0 and is_monster_alive(target):
							add_log("%s✦连射触发![/color] %s 对 %s 追加 [color=gray]%d[/color] 段连击" % [BATTLE_SKILL_LOG, pet.pet_name, target_name, extra_swings], _skill_highlight("连射", skill_anchor))
						for seg_idx in range(extra_swings):
							if not is_monster_alive(target):
								break
							var extra_dmg: = maxi(1, int(damage * ratio2))
							var extra_crit: Dictionary = _apply_crit_to_damage(extra_dmg, _get_pet_crit_stats(pet))
							extra_dmg = int(extra_crit.get("damage", extra_dmg))
							var extra_is_crit: bool = bool(extra_crit.get("is_critical", false))
							var extra_msg: = "  %s连击 %d/%d[/color] %s → %s [color=red]%d[/color]" % [BATTLE_SKILL_LOG, seg_idx + 1, extra_swings, pet.pet_name, target_name, extra_dmg]
							if extra_is_crit:
								extra_msg += " [color=#ff922b]（暴击）[/color]"
							add_log(extra_msg)
							_apply_damage_to_monster(target, extra_dmg)
							pet_total_dealt += extra_dmg
							_emit_damage_dealt(pet.pet_name, target_name, extra_dmg, extra_is_crit, "monster", _monster_index_of(target), pet.element, target_element)
							if not is_monster_alive(target):
								add_log("[color=#ffd43b]%s 被击败了![/color]" % target_name)
								unit_died.emit(target_name)
	if splash_did_trigger:
		add_log("", _attach_splash_hit_fx({}, _monster_index_of(target)))
	if not splash_did_trigger:
		pet_total_dealt += _try_trigger_pet_chase(pet, target, damage, skill_anchor, coop_unit)

	_try_trigger_pet_life_steal(pet, pet_total_dealt, skill_anchor)
	_check_battle_end()


func _compute_pet_counter_strike_value(pet: Pet, monster, coop_unit = null) -> Dictionary:
	pet = _resolve_battle_pet(pet)
	if pet == null:
		return {"strike": 0, "pierced": false}
	var target_defense = _get_monster_stat(monster, "defense", 0)
	var target_element = _get_monster_stat(monster, "element", "普通")
	var attack_with_equipment: = _coop_pet_attack_value(coop_unit, pet)
	var pierce_res: Dictionary = _apply_pet_armor_pierce_defense(pet, target_defense, "pet" if coop_unit == null else "coop_pet")
	target_defense = float(pierce_res.get("defense", target_defense))
	var armor_pierced: bool = bool(pierce_res.get("pierced", false))
	var base_damage = max(1, attack_with_equipment - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))
	var element_result = GameData.calculate_damage_with_element(
		base_damage, 
		pet.element, 
		target_element, 
		pet.is_evolution_pet
	)
	var strike = element_result.damage
	var pet_soul_bonus: = _coop_soul_bonus(coop_unit, pet.element, pet, target_element)
	var pet_soul_applies: = _is_element_counter_or_countered(pet.element, target_element)
	if pet_soul_applies and pet_soul_bonus > 0:
		strike = max(1, int(strike * (1.0 + pet_soul_bonus / 100.0)))
	return {"strike": strike, "pierced": armor_pierced}


func _try_pet_counter_after_being_attacked(pet: Pet, monster, skill_anchor: String = "pet", coop_unit = null) -> void :
	if pet == null or not pet.is_alive() or _pet_skill_battle == null:
		return
	if coop_unit == null and _is_local_pet_defending():
		return
	var counter: = _pet_skill_battle.try_trigger_counter_attack(pet)
	if counter.is_empty():
		return
	_pet_counter_triggers += 1
	var cfg: Dictionary = counter.get("config", {})
	var ratio: float = float(cfg.get("damage_ratio", 0.5))
	var strike_res: Dictionary = _compute_pet_counter_strike_value(pet, monster, coop_unit)
	var pet_strike: = int(strike_res.get("strike", 0))
	var armor_pierced: bool = bool(strike_res.get("pierced", false))
	var c_dmg: = maxi(1, int(pet_strike * ratio))
	var counter_crit: Dictionary = _apply_crit_to_damage(c_dmg, _get_pet_crit_stats(pet))
	c_dmg = int(counter_crit.get("damage", c_dmg))
	var counter_is_crit: bool = bool(counter_crit.get("is_critical", false))
	var monster_name: String = str(_get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", "怪物")))
	var counter_type: = "coop_pet" if skill_anchor == "coop_pet" else "pet"
	var counter_name: = pet.pet_name
	if coop_unit != null and "display_name" in coop_unit:
		counter_name = str(coop_unit.display_name)
	unit_turn.emit({
		"type": counter_type, 
		"name": counter_name, 
		"reference": coop_unit if counter_type == "coop_pet" else pet, 
		"target_type": "monster", 
		"target_index": _monster_index_of(monster), 
		"skip_lunge": true, 
	})
	var m_hp_after: = maxi(0, int(_get_monster_stat(monster, "hp", 0)) - c_dmg)
	if monster is Dictionary:
		monster["hp"] = m_hp_after
	else:
		monster.hp = m_hp_after
		if m_hp_after <= 0 and monster.has_method("died"):
			monster.died.emit()
	var counter_msg: = "%s%s 触发【反击】，对 %s 造成 [color=red]%d[/color] 点伤害![/color]" % [BATTLE_SKILL_LOG, pet.pet_name, monster_name, c_dmg]
	if counter_is_crit:
		counter_msg += " [color=#ff922b]（暴击）[/color]"
	add_log(counter_msg, _skill_highlight("反击", skill_anchor))
	_emit_damage_dealt(pet.pet_name, monster_name, c_dmg, counter_is_crit, "monster", _monster_index_of(monster), pet.element, _get_monster_stat(monster, "element", "普通"), armor_pierced, true)
	if m_hp_after <= 0:
		add_log("[color=red]%s 被反击击败![/color]" % monster_name)
		unit_died.emit(monster_name)


func _sync_coop_unit_hp_from_pet(coop_unit, pet: Pet) -> void :
	if coop_unit != null and coop_unit.has_method("sync_hp_from_battle_pet"):
		coop_unit.sync_hp_from_battle_pet(pet)

func _pet_hit_emit_type(skill_anchor: String, coop_unit = null) -> Dictionary:
	if skill_anchor == "coop_pet" and coop_unit != null:
		return {"hit_target_type": "coop_pet", "hit_target_index": _coop_unit_index(coop_unit)}
	return {"hit_target_type": "pet", "hit_target_index": 0}

func _monster_attack_pet_target(pet: Pet, monster, skill_anchor: String = "pet", coop_unit = null) -> void :
	var monster_attack = _get_monster_stat(monster, "attack", 0)
	var monster_element = _get_monster_stat(monster, "element", "普通")
	var monster_agility = _get_monster_stat(monster, "agility", 10)
	var monster_name = _get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", "怪物"))
	var target_name: = pet.pet_name

	var target_defense: float = _coop_pet_defense_value(coop_unit, pet)
	var target_agility: float = _coop_pet_agility_value(coop_unit, pet)
	var target_element = pet.element
	var hit_meta: = _pet_hit_emit_type(skill_anchor, coop_unit)
	if not _check_hit(monster_agility, target_agility):
		add_log("[color=orange]%s[/color] 攻击 %s, [color=cyan]被闪避了![/color]" % [monster_name, target_name])
		_emit_damage_dealt(
			monster_name, 
			target_name, 
			0, 
			false, 
			str(hit_meta.get("hit_target_type", "pet")), 
			int(hit_meta.get("hit_target_index", 0))
		)
		_try_pet_counter_after_being_attacked(pet, monster, skill_anchor, coop_unit)
		return
	var base_damage = max(1, monster_attack - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))
	var element_result = GameData.calculate_damage_with_element(
		base_damage, 
		monster_element, 
		target_element, 
		Monster.attacker_uses_evolution_pet_element_rate(monster)
	)
	var damage = element_result.damage
	var defend_cut: = false
	var pet_defending: = coop_unit == null and _is_local_pet_defending()
	if pet_defending:
		var reduced: = _apply_defend_damage_reduction(damage)
		defend_cut = reduced != damage
		damage = reduced
	var guard_cut: = false
	if not pet_defending:
		var guard_res: = _apply_pet_guard_damage_reduction(pet, damage, skill_anchor)
		if bool(guard_res.get("guarded", false)):
			guard_cut = true
			damage = int(guard_res.get("damage", damage))
	var atk_msg: = "[color=orange]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [monster_name, target_name, damage]
	if element_result.message:
		atk_msg += _format_element_effect_message(element_result.message)
	if defend_cut:
		atk_msg += " [color=#74c0fc]（防御减伤）[/color]"
	if guard_cut:
		atk_msg += " [color=#74c0fc]（格挡减伤）[/color]"
	pet.hp = max(0.0, pet.hp - damage)
	_sync_coop_unit_hp_from_pet(coop_unit, pet)
	add_log(atk_msg)
	_emit_damage_dealt(
		monster_name, 
		target_name, 
		damage, 
		false, 
		str(hit_meta.get("hit_target_type", "pet")), 
		int(hit_meta.get("hit_target_index", 0)), 
		monster_element, 
		target_element
	)
	if not pet.is_alive():
		var divine: = {}
		if _pet_skill_battle:
			divine = _pet_skill_battle.try_trigger_divine_protect(pet)
		if not divine.is_empty():
			var cfg = divine.get("config", {})
			var restore = maxf(1.0, pet.get_max_hp() * float(cfg.get("hp_restore_ratio", 0.5)))
			pet.hp = restore
			_sync_coop_unit_hp_from_pet(coop_unit, pet)
			add_log("%s%s 触发【神佑】，复生恢复 %.0f 点生命![/color]" % [BATTLE_SKILL_LOG, target_name, restore], _skill_highlight("神佑", skill_anchor))
			_emit_unit_hp_synced(str(hit_meta.get("hit_target_type", "pet")), int(hit_meta.get("hit_target_index", 0)))
		else:
			if skill_anchor != "coop_pet":
				pet_died_in_battle = true
			add_log("[color=red]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	elif not pet_defending:
		_try_pet_counter_after_being_attacked(pet, monster, skill_anchor, coop_unit)


func _monster_turn(monster, _monster_index: int = -1, pre_picked_target = null, impact_delay: float = -1.0):
	var target = pre_picked_target if pre_picked_target != null else _pick_monster_ally_target()
	if target == null:
		return
	var delay: = ATTACK_IMPACT_DELAY if impact_delay < 0.0 else impact_delay
	_defer_battle_action(delay, _resolve_monster_attack.bind(monster, _monster_index, target))

func _resolve_monster_attack(monster, _monster_index: int, target) -> void :
	if current_state != BattleState.IN_PROGRESS:
		return
	if not is_monster_alive(monster):
		return
	if target == null:
		return
	if target is Player and not target.is_alive():
		return
	if target is Pet and not target.is_alive():
		return
	if target != null and target.has_method("is_alive") and not (target is Player) and not (target is Pet) and not target.is_alive():
		return

	if target != null and target.has_method("has_battle_pet_skills") and target.has_battle_pet_skills():
		var coop_battle_pet: Pet = target.get_battle_pet()
		if coop_battle_pet != null:
			_monster_attack_pet_target(coop_battle_pet, monster, "coop_pet", target)
			_check_battle_end()
			return
	if target is Pet:
		_monster_attack_pet_target(target, monster, "pet")
		_check_battle_end()
		return

	var monster_attack = _get_monster_stat(monster, "attack", 0)
	var monster_element = _get_monster_stat(monster, "element", "普通")
	var monster_agility = _get_monster_stat(monster, "agility", 10)
	var monster_name = _get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", "怪物"))

	var target_defense = 0
	var target_agility = 0
	var target_name = ""

	if target is Player:
		if _try_loyal_intercept(monster, target):
			_check_battle_end()
			return
		target_defense = target.get_defense()
		target_agility = target.get_agility()
		target_name = target.player_name
	elif target != null and target.has_method("is_alive"):
		target_defense = int(target.defense)
		target_agility = int(target.agility)
		target_name = str(target.display_name)
	else:
		target_defense = target.defense
		target_agility = target.agility
		target_name = target.name

	if not _check_hit(monster_agility, target_agility):
		add_log("[color=orange]%s[/color] 攻击 %s, [color=cyan]被闪避了![/color]" % [monster_name, target_name])
		if target is Player:
			_emit_damage_dealt(monster_name, target_name, 0, false, "player", 0)
		elif target != null and target.has_method("is_alive") and "unit_type" in target:
			var coop_miss_type: = str(target.unit_type)
			if coop_miss_type in ["coop_player", "coop_pet"]:
				_emit_damage_dealt(monster_name, target_name, 0, false, coop_miss_type, _coop_unit_index(target))
			else:
				_emit_damage_dealt(monster_name, target_name, 0, false, "", -1)
		else:
			_emit_damage_dealt(monster_name, target_name, 0, false, "", -1)
		_check_battle_end()
		return

	var base_damage = max(1, monster_attack - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))

	var target_element = target.element if (target is Player or target is Pet) else str(target.element)
	if target is Player:
		target_element = _local_player_battle_element(str(target.element))
	var element_result = GameData.calculate_damage_with_element(
		base_damage, 
		monster_element, 
		target_element, 
		Monster.attacker_uses_evolution_pet_element_rate(monster)
	)

	var damage = element_result.damage
	var defend_cut: = false
	if target is Player and _is_local_player_defending():
		var reduced: = _apply_defend_damage_reduction(damage)
		defend_cut = reduced != damage
		damage = reduced
	var atk_msg: = "[color=orange]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [monster_name, target_name, damage]
	if element_result.message:
		atk_msg += _format_element_effect_message(element_result.message)
	if defend_cut:
		atk_msg += " [color=#74c0fc]（防御减伤）[/color]"

	if target is Player:
		target.hp = max(0, target.hp - damage)
		target.hp_changed.emit(target.hp, target.get_max_hp())
		if not target.is_alive():
			player_died_in_battle = true
			add_log("[color=red]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
		add_log(atk_msg)
		_emit_damage_dealt(monster_name, target_name, damage, false, "player", 0, monster_element, target_element)
	elif target != null and target.has_method("is_alive"):
		target.hp = max(0.0, float(target.hp) - damage)
		add_log(atk_msg)
		var coop_hit_type: = str(target.unit_type) if "unit_type" in target else ""
		var coop_hit_idx: = _coop_unit_index(target)
		if coop_hit_type in ["coop_player", "coop_pet"]:
			_emit_damage_dealt(monster_name, target_name, damage, false, coop_hit_type, coop_hit_idx, monster_element, target_element)
		if not target.is_alive():
			add_log("[color=red]%s 被击败了![/color]" % target_name)
			unit_died.emit(target_name)
	_check_battle_end()

func _coop_unit_index(unit) -> int:
	if unit == null:
		return -1
	for i in range(coop_units.size()):
		if coop_units[i] == unit:
			return i
	return -1

func _element_tag(attacker_element: String, defender_element: String, damage: int) -> String:
	if damage <= 0:
		return ""
	return GameData.get_element_relation_label(attacker_element, defender_element)

func _emit_damage_dealt(
	attacker: String, 
	target: String, 
	damage: int, 
	is_critical: bool, 
	hit_target_type: String, 
	hit_target_index: int, 
	attacker_element: String = "普通", 
	defender_element: String = "普通", 
	is_armor_pierce: bool = false, 
	is_counter: bool = false
) -> void :
	var element_tag: = _element_tag(attacker_element, defender_element, damage)
	damage_dealt.emit(attacker, target, damage, is_critical, hit_target_type, hit_target_index, element_tag, is_armor_pierce, is_counter)

func _emit_unit_hp_synced(hit_target_type: String, hit_target_index: int) -> void :
	var hp_after: = get_replay_unit_hp(hit_target_type, hit_target_index)
	if hp_after < 0:
		return
	unit_hp_synced.emit(hit_target_type, hit_target_index, hp_after)




func _get_bt_local_combat_bonuses_state() -> Dictionary:
	var gm = GameManager.instance
	if gm == null or not gm.is_brother_tower_battle:
		return {"ok": false, "bonuses": {}}
	var snap = gm.brother_tower_local_snapshot
	if snap is Dictionary:
		var cb = snap.get("combat_bonuses", {})
		if cb is Dictionary:
			return {"ok": true, "bonuses": cb}
	return {"ok": true, "bonuses": {}}

func _coop_noble_bonus(coop_unit) -> int:
	if coop_unit != null and coop_unit.has_method("get_noble_pet_damage_bonus"):
		return coop_unit.get_noble_pet_damage_bonus()
	return _get_noble_pet_damage_bonus()

func _coop_soul_bonus(coop_unit, element: String, pet: Pet = null, defender_element: String = "") -> int:
	var soul_el: = GameData.get_pet_soul_lookup_element(element, defender_element)
	if soul_el.is_empty():
		return 0
	if coop_unit != null and coop_unit.has_method("get_pet_soul_bonus_percent"):
		return coop_unit.get_pet_soul_bonus_percent(soul_el)
	if pet != null:
		return _get_pet_soul_bonus_percent(pet, defender_element)
	return 0

func _coop_pet_attack_value(coop_unit, pet: Pet) -> int:

	if coop_unit != null:
		return int(coop_unit.attack)
	if pet != null:
		return int(pet.get_final_attack_with_equipment())
	return 1

func _coop_pet_defense_value(coop_unit, pet: Pet) -> float:
	if coop_unit != null:
		return float(coop_unit.defense)
	if pet != null:
		return float(pet.get_final_defense_with_equipment())
	return 1.0

func _coop_pet_agility_value(coop_unit, pet: Pet) -> float:
	if coop_unit != null:
		return float(coop_unit.agility)
	if pet != null:
		return pet.get_final_agility_with_equipment()
	return 1.0


func _get_noble_pet_damage_bonus() -> int:
	var st: = _get_bt_local_combat_bonuses_state()
	if bool(st.get("ok", false)):
		var bt_bonuses: Dictionary = st.get("bonuses", {})
		return clampi(int(bt_bonuses.get("noble_pet_damage_bonus", 0)), 0, 30)
	if GameManager.instance == null:
		return 0
	var bonus: = int(GameManager.instance.noble_pet_damage_bonus)
	return clampi(bonus, 0, 30)



func _get_pet_soul_bonus_percent(pet: Pet, defender_element: String = "") -> int:
	if pet == null:
		return 0
	var soul_el: = GameData.get_pet_soul_lookup_element(str(pet.element), defender_element)
	if soul_el.is_empty():
		return 0
	var st: = _get_bt_local_combat_bonuses_state()
	if bool(st.get("ok", false)):
		var bt_bonuses: Dictionary = st.get("bonuses", {})
		var points = bt_bonuses.get("pet_soul_element_points", {})
		if points is Dictionary:
			return CoopBattleUnit._soul_bonus_percent_from_points(points, soul_el)
		return 0
	if GameManager.instance == null:
		return 0
	if GameManager.instance.pet_soul_manager == null:
		return 0
	return int(GameManager.instance.pet_soul_manager.get_bonus_percent(soul_el))

func _check_hit(attacker_agility: float, target_agility: float) -> bool:


	var min_hit: float = 5.0
	var max_hit: float = 95.0
	var a: float = maxf(attacker_agility, 0.0)
	var d: float = maxf(target_agility, 1.0)
	var hit_chance: float = max_hit
	if a < d:
		hit_chance = max_hit * (a / d)
	hit_chance = clampf(hit_chance, min_hit, max_hit)
	return randf() * 100.0 < hit_chance

func _format_element_effect_message(effect_message: String) -> String:
	if effect_message.is_empty():
		return ""
	if effect_message.find("伤害提升") != -1:
		return " [color=#69db7c]%s[/color]" % effect_message
	if effect_message.find("伤害降低") != -1:
		return " [color=#ff8787]%s[/color]" % effect_message
	return " [color=yellow]%s[/color]" % effect_message

func _is_element_counter_or_countered(attacker_element: String, defender_element: String) -> bool:
	var atk: = str(attacker_element).strip_edges()
	var deff: = str(defender_element).strip_edges()
	if atk == "普通" or deff == "普通":
		return false
	if atk == GameData.ELEMENT_SKY and deff == GameData.ELEMENT_SKY:
		return false
	if GameData.is_sky_vs_five_element(atk, deff):
		return true
	return (
		GameData.ELEMENT_COUNTER.get(atk) == deff
		or GameData.ELEMENT_COUNTER.get(deff) == atk
	)


func _build_joint_triple_shot_targets(primary_target, max_count: int = 3) -> Array:
	var targets: Array = []
	if primary_target != null and is_monster_alive(primary_target):
		targets.append(primary_target)
	if targets.size() >= max_count:
		return targets
	for extra in _pick_random_alive_monsters(max_count - targets.size(), targets):
		if extra != null and not targets.has(extra):
			targets.append(extra)
	return targets

func _pick_random_alive_monsters(count: int, exclude: Array = []) -> Array:
	if attack_target_mode == AttackTargetMode.SEQUENTIAL:
		return _pick_sequential_alive_monsters(count, exclude)
	var n: = maxi(0, int(count))
	if n <= 0:
		return []
	var pool: Array = []
	for monster in monsters:
		if not is_monster_alive(monster):
			continue
		if _monster_list_has(exclude, monster):
			continue
		pool.append(monster)
	var picked: Array = []
	while picked.size() < n and not pool.is_empty():
		var idx: = randi() % pool.size()
		picked.append(pool[idx])
		pool.remove_at(idx)
	return picked

func _pick_sequential_alive_monsters(count: int, exclude: Array = []) -> Array:
	var n: = maxi(0, int(count))
	if n <= 0:
		return []
	var picked: Array = []
	for monster in monsters:
		if picked.size() >= n:
			break
		if not is_monster_alive(monster):
			continue
		if _monster_list_has(exclude, monster):
			continue
		picked.append(monster)
	return picked

func _pick_random_alive_monster(exclude: Array = []):
	var picks: Array = _pick_random_alive_monsters(1, exclude)
	return picks[0] if picks.size() > 0 else null

func _find_first_alive_monster():
	for monster in monsters:
		if is_monster_alive(monster):
			return monster
	return null

func _check_battle_end() -> bool:

	if current_state == BattleState.VICTORY or current_state == BattleState.DEFEAT:
		return true
	if replay_log_only:
		return false


	var alive_count = 0
	for monster in monsters:
		if is_monster_alive(monster):
			alive_count += 1

	if alive_count == 0:
		current_state = BattleState.VICTORY
		add_log("=== [color=yellow]★ 战斗胜利! ★[/color] ===")
		battle_ended.emit(true)
		return true

	var player_dead = not player or not player.is_alive()
	var pet_dead = not active_pet or not active_pet.is_alive()
	if coop_units.is_empty():
		if player_dead and pet_dead:
			current_state = BattleState.DEFEAT
			add_log("=== [color=red]战斗失败...[/color] ===")
			battle_ended.emit(false)
			return true
	else:
		var any_ally_alive: = false
		if player and player.is_alive():
			any_ally_alive = true
		if active_pet and active_pet.is_alive():
			any_ally_alive = true
		for cu in coop_units:
			if cu != null and cu.has_method("is_alive") and cu.is_alive():
				any_ally_alive = true
		if not any_ally_alive:
			current_state = BattleState.DEFEAT
			add_log("=== [color=red]战斗失败...[/color] ===")
			battle_ended.emit(false)
			return true

	return false

func force_end_battle(victory: bool = false):
	if current_state != BattleState.IN_PROGRESS:
		return
	_opening_settle_gen += 1
	_is_starting_round = false
	_exec_turn_queue.clear()
	_exec_turn_index = 0
	_exec_round_initialized = false
	_exec_can_combo = false
	_combo_guaranteed_hit = false
	_coop_exec_can_combo = false
	_coop_combo_guaranteed_hit = false
	_pending_splash_pair_player = false
	_pending_splash_pair_combo = false
	_pending_splash_pair_coop = false

	if victory:
		current_state = BattleState.VICTORY
		add_log("=== [color=yellow]★ 战斗胜利! ★[/color] ===")
	else:
		current_state = BattleState.DEFEAT
		add_log("=== [color=red]战斗被强制结束...[/color] ===")
	battle_ended.emit(victory)


func get_battle_rewards() -> Dictionary:
	var total_exp = 0
	var total_gold = 0
	var defeated_monsters = []

	for monster in monsters:
		if not is_monster_alive(monster):

			if monster is Dictionary:
				total_exp += int(monster.get("exp_reward", monster.get("exp", 0)))
				total_gold += int(monster.get("gold_reward", monster.get("gold", 0)))
			else:
				total_exp += monster.exp_reward
				total_gold += monster.gold_reward
			defeated_monsters.append(monster)

	if suppress_battle_character_exp:
		total_exp = 0

	return {
		"exp": total_exp, 
		"gold": total_gold, 
		"monsters": defeated_monsters
	}


func add_log(message: String, highlight: Dictionary = {}) -> void :
	if not message.is_empty():
		battle_log.append(message)
		if battle_log.size() > MAX_LOG_LINES:
			battle_log = battle_log.slice( - MAX_LOG_LINES)
		print(message)
	if not message.is_empty() or not highlight.is_empty():
		log_added.emit(message, highlight)

func get_battle_log() -> Array:
	return battle_log.duplicate()

func clear_log():
	battle_log.clear()


func is_in_battle() -> bool:
	return current_state == BattleState.IN_PROGRESS

func get_state() -> BattleState:
	return current_state

func _auto_finish_current_execute_round() -> void :
	_try_apply_pet_self_heal_end_of_round()
	_exec_round_initialized = false
	_exec_phase = 0
	_exec_turn_queue.clear()
	_exec_turn_index = 0
	if current_state != BattleState.IN_PROGRESS:
		return
	if max_rounds > 0 and current_round >= max_rounds:
		current_state = BattleState.DEFEAT
		add_log("=== [color=red]战斗失败... (超过最大回合数)[/color] ===")
		battle_ended.emit(false)


func execute_turn(rollover_budget: int = 1):
	last_execute_wait_seconds = ROUND_WINDOW_SECONDS
	if replay_log_only:
		return
	if current_state != BattleState.IN_PROGRESS:
		return
	if Time.get_ticks_msec() < _opening_ready_at_msec:
		return

	if monsters.is_empty():
		current_state = BattleState.VICTORY
		battle_ended.emit(true)
		return

	if not _exec_round_initialized:
		current_round += 1
		round_started.emit(current_round)
		add_log("--- 第 %d 回合 ---" % current_round)
		_refresh_battle_active_pet()
		_pet_joint_attacked = false
		_coop_pet_joint_attacked = false
		_exec_can_combo = _check_combo_condition()
		_combo_guaranteed_hit = _exec_can_combo
		if _exec_can_combo:
			add_log("[color=#69db7c]★ 连击触发! 你和宠物的敏捷都高于所有敌人! ★[/color]", HIGHLIGHT_COMBO)
		_refresh_coop_combo_state()
		if DEBUG_AUTO_BATTLE_COMBO_LOG and player and active_pet:
			var player_agility: = int(player.get_agility())
			var pet_agility: = int(active_pet.get_final_agility_with_equipment())
			var max_monster_agility: = 0
			for monster in monsters:
				if is_monster_alive(monster):
					max_monster_agility = max(max_monster_agility, int(_get_monster_stat(monster, "agility", 0)))
			add_log("[color=#8898aa][调试] 自动战斗判定：人敏%d 宠敏%d 怪物最高敏%d 连击=%s[/color]" % [player_agility, pet_agility, max_monster_agility, "是" if _exec_can_combo else "否"])
		_exec_round_initialized = true
		_exec_phase = 0
		_exec_turn_queue = _build_round_turn_queue()
		_exec_turn_index = 0
		if _exec_turn_queue.is_empty():
			if _check_battle_end():
				_auto_finish_current_execute_round()
				return
			_auto_finish_current_execute_round()
			return

	while _exec_turn_index < _exec_turn_queue.size():
		if current_state != BattleState.IN_PROGRESS:
			_auto_finish_current_execute_round()
			return
		var action = _exec_turn_queue[_exec_turn_index]
		_exec_turn_index += 1
		var ran: = _run_turn_action(action)
		if _check_battle_end():
			_auto_finish_current_execute_round()
			return
		if ran:
			var kind: = str(action.get("kind", ""))
			if kind == "combo_pet" or kind == "coop_combo_pet":
				last_execute_wait_seconds = COMBO_TURN_SECONDS
			elif _pair_leads_into_combo(kind):
				last_execute_wait_seconds = ALLY_LUNGE_CYCLE_SECONDS
			else:
				last_execute_wait_seconds = ROUND_WINDOW_SECONDS
			return
	_auto_finish_current_execute_round()
	if rollover_budget > 0 and current_state == BattleState.IN_PROGRESS:
		execute_turn(rollover_budget - 1)


func _get_monster_stat(monster, stat_name: String, default_value = null):
	if monster is Dictionary:
		return monster.get(stat_name, default_value)
	elif monster.has_method("get"):
		return monster.get(stat_name) if monster.get(stat_name) != null else default_value
	elif monster.get(stat_name) != null:
		return monster.get(stat_name)
	return default_value


func _apply_damage_to_monster(monster, damage: int):
	if monster is Dictionary:
		var current_hp = monster.get("hp", 0)
		monster["hp"] = max(0, current_hp - damage)
	else:
		monster.hp = max(0, monster.hp - damage)
		if monster.hp <= 0 and monster.has_method("died"):
			monster.died.emit()
	if not is_monster_alive(monster):
		_clear_monster_acupoint_seal(_monster_index_of(monster))

func _monster_index_of(monster) -> int:
	if monster == null:
		return -1
	for i in range(monsters.size()):
		if is_same(monsters[i], monster):
			return i
	return -1
func _consume_monster_acupoint_skip(monster_index: int, monster_name: String = "怪物") -> bool:
	if monster_index < 0:
		return false
	var remain: = int(_monster_acupoint_seal_turns.get(monster_index, 0))
	if remain <= 0:
		return false
	remain -= 1
	if remain > 0:
		_monster_acupoint_seal_turns[monster_index] = remain
	else:
		_monster_acupoint_seal_turns.erase(monster_index)
		acupoint_seal_changed.emit("monster", monster_index, false)
	add_log("%s%s 被葵花点穴封住经脉，本回合无法行动（剩余%d回合）[/color]" % [BATTLE_SKILL_LOG, monster_name, remain])
	return true

func _find_equipped_martial_by_effect(effect_type: String):
	var gm = GameManager.instance
	if gm != null and gm.is_brother_tower_battle:
		var snap: Dictionary = gm.brother_tower_local_snapshot
		var player_raw = snap.get("player", {})
		if player_raw is Dictionary:
			var arts_raw = player_raw.get("martial_arts_active", [])
			if arts_raw is Array:
				var key: = str(effect_type).strip_edges()
				for raw in arts_raw:
					if raw is Dictionary and str(raw.get("effect_type", "")) == key:
						return MartialArtsManager.MartialArt.from_dict(raw)
	if gm == null or gm.martial_arts_manager == null:
		return null
	for art in gm.martial_arts_manager.equipped_arts:
		if art == null:
			continue
		if str(art.effect_type) == effect_type:
			return art
	return null

func _get_player_crit_stats() -> Dictionary:
	var rate: = MartialArtsManager.BASE_CRIT_RATE
	var bonus: = 0.0
	var rate_art = _find_equipped_martial_by_effect("crit_rate")
	var dmg_art = _find_equipped_martial_by_effect("crit_damage")
	if rate_art != null:
		rate += clampf(float(rate_art.get_effect_value()) / 100.0, 0.0, 1.0)
	if dmg_art != null:
		bonus = float(dmg_art.get_effect_value())
	rate += FabaoStatBonus.player_pct("crit_rate") / 100.0
	bonus += FabaoStatBonus.player_pct("crit_dmg")
	return {"rate": clampf(rate, 0.0, 1.0), "mult": MartialArtsManager.DEFAULT_CRIT_MULTIPLIER + bonus / 100.0}

func _get_pet_crit_stats(pet: Pet) -> Dictionary:
	var rate: = MartialArtsManager.BASE_CRIT_RATE + FabaoStatBonus.pet_pct("crit_rate") / 100.0
	var bonus: = FabaoStatBonus.pet_pct("crit_dmg")
	if _pet_skill_battle != null and pet != null:
		rate += _pet_skill_battle.get_crit_rate_bonus(pet)
		bonus += _pet_skill_battle.get_crit_damage_bonus(pet) * 100.0
	return {"rate": clampf(rate, 0.0, 1.0), "mult": MartialArtsManager.DEFAULT_CRIT_MULTIPLIER + bonus / 100.0}

func _get_coop_crit_stats(unit) -> Dictionary:
	var rate: = MartialArtsManager.BASE_CRIT_RATE
	var bonus: = 0.0
	if unit != null and unit.has_method("find_martial_by_effect"):
		var rate_art = unit.find_martial_by_effect("crit_rate")
		var dmg_art = unit.find_martial_by_effect("crit_damage")
		if rate_art != null:
			rate += clampf(float(rate_art.get_effect_value()) / 100.0, 0.0, 1.0)
		if dmg_art != null:
			bonus = float(dmg_art.get_effect_value())
	return {"rate": clampf(rate, 0.0, 1.0), "mult": MartialArtsManager.DEFAULT_CRIT_MULTIPLIER + bonus / 100.0}

func _apply_crit_to_damage(damage: int, crit_stats: Dictionary) -> Dictionary:
	var rate: = clampf(float(crit_stats.get("rate", 0.0)), 0.0, 1.0)
	var mult: = float(crit_stats.get("mult", MartialArtsManager.DEFAULT_CRIT_MULTIPLIER))
	if rate > 0.0 and randf() < rate:
		return {"damage": maxi(1, int(floor(float(damage) * mult))), "is_critical": true}
	return {"damage": damage, "is_critical": false}

func _try_trigger_player_life_steal(attacker: Player, total_damage: int) -> void :
	if attacker == null or total_damage <= 0:
		return
	if attacker.hp <= 0:
		return
	var art = _find_equipped_martial_by_effect("life_steal")
	if art == null:
		return
	if randf() >= MartialArtsManager.LIFE_STEAL_TRIGGER_RATE:
		return
	var ratio: float = clampf(art.get_life_steal_ratio(), 0.0, 1.0)
	var heal_amount: int = maxi(1, int(floor(float(total_damage) * ratio)))
	attacker.heal(heal_amount)
	add_log("%s%s【以墨养墨】吸血回复 [color=#69db7c]%d[/color] 点生命[/color]" % [BATTLE_SKILL_LOG, attacker.player_name, heal_amount], _skill_highlight("以墨养墨", "player", heal_amount))
	_emit_unit_hp_synced("player", 0)

func _try_trigger_coop_life_steal(unit, total_damage: int) -> void :
	if unit == null or total_damage <= 0:
		return
	if unit.has_method("is_alive") and not unit.is_alive():
		return
	var art = unit.find_martial_by_effect("life_steal") if unit.has_method("find_martial_by_effect") else null
	if art == null:
		return
	if randf() >= MartialArtsManager.LIFE_STEAL_TRIGGER_RATE:
		return
	var ratio: float = clampf(art.get_life_steal_ratio() if art.has_method("get_life_steal_ratio") else float(art.get_effect_value()) / 100.0, 0.0, 1.0)
	var heal_amount: int = maxi(1, int(floor(float(total_damage) * ratio)))
	if unit.has_method("heal_hp"):
		unit.heal_hp(heal_amount)
	elif "hp" in unit and "max_hp" in unit:
		unit.hp = mini(int(unit.max_hp), int(unit.hp) + heal_amount)
	var uname: = str(unit.display_name if "display_name" in unit else "队友")
	var skill_anchor: = str(unit.unit_type) if "unit_type" in unit else "coop_player"
	add_log("%s%s【以墨养墨】吸血回复 [color=#69db7c]%d[/color] 点生命[/color]" % [BATTLE_SKILL_LOG, uname, heal_amount], _skill_highlight("以墨养墨", skill_anchor, heal_amount))
	if skill_anchor in ["coop_player", "coop_pet"]:
		_emit_unit_hp_synced(skill_anchor, _coop_unit_index(unit))

func _try_trigger_pet_life_steal(pet: Pet, total_damage: int, skill_anchor: String = "pet") -> void :
	pet = _resolve_battle_pet(pet)
	if pet == null or total_damage <= 0:
		return
	if pet.hp <= 0:
		return
	if _pet_skill_battle == null:
		return
	var result: Dictionary = _pet_skill_battle.try_trigger_life_steal(pet, total_damage)
	if result.is_empty():
		return
	var heal_amount: int = maxi(1, int(result.get("heal_amount", 0)))
	pet.heal(float(heal_amount))
	add_log("%s✦吸血触发![/color] %s 回复 [color=#69db7c]%d[/color] 点生命" % [BATTLE_SKILL_LOG, pet.pet_name, heal_amount], _skill_highlight("吸血", skill_anchor, heal_amount))
	var hit_type: = "pet"
	var hit_idx: = 0
	if skill_anchor == "coop_pet":
		hit_type = "coop_pet"
		hit_idx = -1
		for i in range(coop_units.size()):
			var cu = coop_units[i]
			if cu != null and cu.has_method("get_battle_pet") and cu.get_battle_pet() == pet:
				hit_idx = i
				break
		if hit_idx < 0:
			hit_idx = 0
		_sync_coop_unit_hp_from_pet(coop_units[hit_idx] if hit_idx < coop_units.size() else null, pet)
	_emit_unit_hp_synced(hit_type, hit_idx)

func _try_trigger_pet_chase(pet: Pet, killed_target, base_damage: int, skill_anchor: String = "pet", coop_unit = null) -> int:
	if pet == null or _pet_skill_battle == null:
		return 0
	if is_monster_alive(killed_target):
		return 0
	var chase: = _pet_skill_battle.try_trigger_chase(pet)
	if chase.is_empty():
		return 0
	_pet_chase_triggers += 1
	var next_targets: Array = _pick_random_alive_monsters(1, [killed_target])
	if next_targets.is_empty():
		return 0
	var next_target = next_targets[0]
	var ratio: = maxf(0.0, float(chase.get("chase_ratio", 1.0)))
	var chase_dmg: = maxi(1, int(float(base_damage) * ratio))
	var chase_crit: Dictionary = _apply_crit_to_damage(chase_dmg, _get_pet_crit_stats(pet))
	chase_dmg = int(chase_crit.get("damage", chase_dmg))
	var chase_is_crit: bool = bool(chase_crit.get("is_critical", false))
	var tname = _get_monster_stat(next_target, "monster_name", _get_monster_stat(next_target, "name", "怪物"))
	var chase_msg: = "%s✦追击触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点追击伤害" % [BATTLE_SKILL_LOG, pet.pet_name, tname, chase_dmg]
	if chase_is_crit:
		chase_msg += " [color=#ff922b]（暴击）[/color]"
	add_log(chase_msg, _skill_highlight("追击", skill_anchor))
	_apply_damage_to_monster(next_target, chase_dmg)
	_emit_damage_dealt(pet.pet_name, tname, chase_dmg, chase_is_crit, "monster", _monster_index_of(next_target), pet.element, _get_monster_stat(next_target, "element", "普通"))
	if not is_monster_alive(next_target):
		add_log("[color=#ffd43b]%s 被击败了![/color]" % tname)
		unit_died.emit(tname)
	return chase_dmg

func _try_loyal_intercept(monster, player_target) -> bool:
	if player_target == null or not (player_target is Player):
		return false
	if active_pet == null or not active_pet.is_alive() or _pet_skill_battle == null:
		return false
	var loyal: = _pet_skill_battle.try_trigger_loyal(active_pet)
	if loyal.is_empty():
		return false
	add_log("%s%s 触发【忠心】，替主人承受攻击![/color]" % [BATTLE_SKILL_LOG, active_pet.pet_name], _skill_highlight("忠心", "pet"))
	_monster_attack_pet_target(active_pet, monster, "pet")
	return true

func _try_apply_pet_self_heal_end_of_round() -> void :
	if current_state != BattleState.IN_PROGRESS or _pet_skill_battle == null:
		return
	if active_pet != null and active_pet.is_alive():
		var heal: = _pet_skill_battle.try_trigger_self_heal(active_pet)
		if not heal.is_empty():
			var amt: = int(heal.get("heal_amount", 0))
			active_pet.heal(float(amt))
			add_log("%s✦自愈触发![/color] %s 回复 [color=#69db7c]%d[/color] 点生命" % [BATTLE_SKILL_LOG, active_pet.pet_name, amt], _skill_highlight("自愈", "pet", amt))
			_emit_unit_hp_synced("pet", 0)
	for cu in coop_units:
		if cu == null or not cu.has_method("get_battle_pet"):
			continue
		var bp: Pet = cu.get_battle_pet()
		if bp == null or not bp.is_alive():
			continue
		var coop_heal: = _pet_skill_battle.try_trigger_self_heal(bp)
		if coop_heal.is_empty():
			continue
		var camt: = int(coop_heal.get("heal_amount", 0))
		bp.heal(float(camt))
		_sync_coop_unit_hp_from_pet(cu, bp)
		add_log("%s✦自愈触发![/color] %s 回复 [color=#69db7c]%d[/color] 点生命" % [BATTLE_SKILL_LOG, bp.pet_name, camt], _skill_highlight("自愈", "coop_pet", camt))

func _find_monster_index(monster) -> int:
	return _monster_index_of(monster)

func _clear_monster_acupoint_seal(monster_index: int) -> void :
	if monster_index < 0:
		return
	if int(_monster_acupoint_seal_turns.get(monster_index, 0)) <= 0:
		return
	_monster_acupoint_seal_turns.erase(monster_index)
	acupoint_seal_changed.emit("monster", monster_index, false)

func _local_kuihua_attack_active() -> bool:
	if player == null or int(player.mp) <= 0:
		return false
	return _find_equipped_martial_by_effect("acupoint_seal") != null

func _coop_kuihua_attack_active(unit) -> bool:
	if unit == null or not unit.has_method("get_current_mp_value") or unit.get_current_mp_value() <= 0:
		return false
	if not unit.has_method("find_martial_by_effect"):
		return false
	return unit.find_martial_by_effect("acupoint_seal") != null

func _kuihua_struck_unsealed(preferred: Array) -> Array:
	var picked: Array = []
	for monster in preferred:
		if picked.size() >= 3:
			break
		if monster == null or not is_monster_alive(monster) or picked.has(monster):
			continue
		var idx: = _monster_index_of(monster)
		if idx < 0 or int(_monster_acupoint_seal_turns.get(idx, 0)) > 0:
			continue
		picked.append(monster)
	return picked

func _collect_kuihua_monster_targets(preferred: Array) -> Array:
	var picked: Array = []
	var seen: = {}
	for monster in preferred:
		_consider_kuihua_monster(picked, seen, monster)
	for monster in monsters:
		_consider_kuihua_monster(picked, seen, monster)
	return picked

func _consider_kuihua_monster(picked: Array, seen: Dictionary, monster) -> void :
	if monster == null or picked.size() >= 3:
		return
	if not is_monster_alive(monster):
		return
	var idx: = _monster_index_of(monster)
	if idx < 0 or seen.has(idx):
		return
	if int(_monster_acupoint_seal_turns.get(idx, 0)) > 0:
		return
	seen[idx] = true
	picked.append(monster)

func _try_trigger_kuihua_acupoint(attacker: Player, preferred: Array) -> void :
	if attacker == null:
		return

	if int(attacker.mp) <= 0:
		return
	var art = _find_equipped_martial_by_effect("acupoint_seal")
	if art == null:
		return
	var victims: Array = _kuihua_struck_unsealed(preferred)
	if victims.is_empty():
		return
	var attacker_max_mp_snapshot: int = max(0, int(attacker.get_max_mp()))
	var base_chance: float = clampf(float(art.get_effect_value()) / 100.0, 0.0, 1.0)
	var any_success: = false
	for target in victims:
		if not is_monster_alive(target):
			continue
		var monster_index: int = _find_monster_index(target)
		if monster_index < 0:
			continue
		var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))

		var target_mp: int = 0
		var bonus_pct_steps: int = max(0, int(floor(float(attacker_max_mp_snapshot - target_mp) / 1000.0)))
		var final_chance: float = clampf(base_chance + float(bonus_pct_steps) * 0.01, 0.0, 1.0)
		if randf() < final_chance:
			_monster_acupoint_seal_turns[monster_index] = 2
			any_success = true
			add_log("%s%s 施展【葵花点穴】得手！%s 接下来两回合无法行动（基础%.1f%% + 加成%d%% = %.1f%%）[/color]" % [BATTLE_SKILL_LOG, attacker.player_name, target_name, base_chance * 100.0, bonus_pct_steps, final_chance * 100.0])
			acupoint_seal_changed.emit("monster", monster_index, true)
		else:
			add_log("%s%s 施展【葵花点穴】未能封住 %s 经脉（基础%.1f%% + 加成%d%% = %.1f%%）[/color]" % [BATTLE_SKILL_LOG, attacker.player_name, target_name, base_chance * 100.0, bonus_pct_steps, final_chance * 100.0])
	if any_success:
		attacker.mp = 0

func _try_trigger_kuihua_acupoint_coop(unit, preferred: Array) -> void :
	if unit == null:
		return
	if not unit.has_method("get_current_mp_value") or unit.get_current_mp_value() <= 0:
		return
	var art = unit.find_martial_by_effect("acupoint_seal") if unit.has_method("find_martial_by_effect") else null
	if art == null:
		return
	var victims: Array = _kuihua_struck_unsealed(preferred)
	if victims.is_empty():
		return
	var attacker_name: = str(unit.display_name if "display_name" in unit else "队友")
	var attacker_max_mp_snapshot: int = unit.get_max_mp_value() if unit.has_method("get_max_mp_value") else 0
	var base_chance: float = clampf(float(art.get_effect_value()) / 100.0, 0.0, 1.0)
	var any_success: = false
	for target in victims:
		if not is_monster_alive(target):
			continue
		var monster_index: int = _find_monster_index(target)
		if monster_index < 0:
			continue
		var target_name = _get_monster_stat(target, "monster_name", _get_monster_stat(target, "name", "怪物"))
		var target_mp: int = 0
		var bonus_pct_steps: int = max(0, int(floor(float(attacker_max_mp_snapshot - target_mp) / 1000.0)))
		var final_chance: float = clampf(base_chance + float(bonus_pct_steps) * 0.01, 0.0, 1.0)
		if randf() < final_chance:
			_monster_acupoint_seal_turns[monster_index] = 2
			any_success = true
			add_log("%s%s 施展【葵花点穴】得手！%s 接下来两回合无法行动（基础%.1f%% + 加成%d%% = %.1f%%）[/color]" % [BATTLE_SKILL_LOG, attacker_name, target_name, base_chance * 100.0, bonus_pct_steps, final_chance * 100.0])
			acupoint_seal_changed.emit("monster", monster_index, true)
		else:
			add_log("%s%s 施展【葵花点穴】未能封住 %s 经脉（基础%.1f%% + 加成%d%% = %.1f%%）[/color]" % [BATTLE_SKILL_LOG, attacker_name, target_name, base_chance * 100.0, bonus_pct_steps, final_chance * 100.0])
	if any_success and unit.has_method("consume_mp_all"):
		unit.consume_mp_all()

func _find_next_alive_monster_after(anchor):
	if monsters.is_empty():
		return null
	var anchor_index: = -1
	for i in range(monsters.size()):
		if monsters[i] == anchor:
			anchor_index = i
			break
	if anchor_index < 0:
		return null
	for i in range(anchor_index + 1, monsters.size()):
		var candidate = monsters[i]
		if is_monster_alive(candidate):
			return candidate
	return null


func _calc_pet_splash_damage_to_monster(pet: Pet, splash_target, ratio: float, coop_unit = null) -> Dictionary:
	if pet == null or splash_target == null:
		return {"damage": 1, "pierced": false}
	var target_defense = _get_monster_stat(splash_target, "defense", 0)
	var target_element = _get_monster_stat(splash_target, "element", "普通")
	var attack_with_equipment: = _coop_pet_attack_value(coop_unit, pet)
	var splash_anchor: = "coop_pet" if coop_unit != null else "pet"
	var pierce_res: Dictionary = _apply_pet_armor_pierce_defense(pet, target_defense, splash_anchor)
	target_defense = float(pierce_res.get("defense", target_defense))
	var armor_pierced: bool = bool(pierce_res.get("pierced", false))
	var base_damage = max(1, attack_with_equipment - target_defense / 2)
	base_damage = int(base_damage * (0.8 + randf() * 0.4))
	var element_result = GameData.calculate_damage_with_element(
		base_damage, 
		pet.element, 
		target_element, 
		pet.is_evolution_pet
	)
	var damage: int = int(element_result.damage)
	var pet_soul_bonus: = _coop_soul_bonus(coop_unit, pet.element, pet, target_element)
	var pet_soul_applies: = _is_element_counter_or_countered(pet.element, target_element)
	if pet_soul_applies and pet_soul_bonus > 0:
		damage = max(1, int(damage * (1.0 + pet_soul_bonus / 100.0)))
	return {"damage": maxi(1, int(float(damage) * maxf(0.0, ratio))), "pierced": armor_pierced}

func _apply_prepicked_splash_hits(pet: Pet, splash_plan: Dictionary, primary_target, skill_anchor: String, coop_unit = null) -> int:
	var extras: Array = splash_plan.get("extras", [])
	var extra_count: = int(splash_plan.get("extra_count", 0))
	if extras.is_empty() and extra_count > 0:
		extras = _pick_random_alive_monsters(extra_count, [primary_target])
		splash_plan["extras"] = extras
	if extras.is_empty():
		return 0
	var ratio: = float(splash_plan.get("ratio", 1.0))
	var skill_key: = str(splash_plan.get("skill_key", ""))
	var total: = 0
	var is_lv3: = skill_key == "splash_lv3"
	for extra_idx in range(extras.size()):
		var next_target = extras[extra_idx]
		if next_target == null:
			continue
		if not is_monster_alive(next_target):
			next_target = _pick_random_alive_monster([primary_target])
		if next_target == null or _is_same_monster_ref(next_target, primary_target):
			continue
		var splash_calc: Dictionary = _calc_pet_splash_damage_to_monster(pet, next_target, ratio, coop_unit)
		var splash_dmg: = int(splash_calc.get("damage", 1))
		var splash_pierced: bool = bool(splash_calc.get("pierced", false))
		var splash_crit: Dictionary = _apply_crit_to_damage(splash_dmg, _get_pet_crit_stats(pet))
		splash_dmg = int(splash_crit.get("damage", splash_dmg))
		var splash_is_crit: bool = bool(splash_crit.get("is_critical", false))
		var tname = _get_monster_stat(next_target, "monster_name", _get_monster_stat(next_target, "name", "怪物"))
		var splash_hl: Dictionary = _skill_highlight("溅射", skill_anchor) if extra_idx == 0 else {}
		splash_hl = _attach_splash_hit_fx(splash_hl, _monster_index_of(next_target))
		var splash_msg: = ""
		if is_lv3:
			splash_msg = "%s✦溅射lv3触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点溅射伤害" % [BATTLE_SKILL_LOG, pet.pet_name, tname, splash_dmg]
			if splash_is_crit:
				splash_msg += " [color=#ff922b]（暴击）[/color]"
			add_log(splash_msg, splash_hl)
		else:
			var auth_cfg: Dictionary = PetSkillConfig.get_skill_definition(skill_key)
			var splash_name: = str(auth_cfg.get("skill_name", "溅射"))
			splash_msg = "%s✦ 溅射触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点溅射伤害" % [BATTLE_SKILL_LOG, pet.pet_name, tname, splash_dmg]
			if splash_is_crit:
				splash_msg += " [color=#ff922b]（暴击）[/color]"
			add_log(splash_msg, _attach_splash_hit_fx(_skill_highlight(splash_name, skill_anchor), _monster_index_of(next_target)))
		_apply_damage_to_monster(next_target, splash_dmg)
		total += splash_dmg
		_emit_damage_dealt(pet.pet_name, tname, splash_dmg, splash_is_crit, "monster", _monster_index_of(next_target), pet.element, _get_monster_stat(next_target, "element", "普通"), splash_pierced)
		if not is_monster_alive(next_target):
			add_log("[color=#ffd43b]%s 被击败了![/color]" % tname)
			unit_died.emit(tname)
	return total

func _try_trigger_pet_splash(pet: Pet, primary_target, skill_anchor: String = "pet", coop_unit = null) -> int:
	if pet == null:
		return 0
	var skill_key: = ""
	var learned: Dictionary = {}

	for cand_key in ["splash_lv2", "splash_lv1"]:
		learned = pet.get_skill_by_key(cand_key)
		if not learned.is_empty():
			skill_key = cand_key
			break
	if learned.is_empty():
		return 0
	var skill_cfg: Dictionary = GameData.PET_SKILLS.get(skill_key, {})
	if skill_cfg.is_empty():
		return 0
	var trigger_chance: = clampf(float(skill_cfg.get("trigger_chance", 0.0)), 0.0, 1.0)
	if trigger_chance <= 0.0 or randf() >= trigger_chance:
		return 0
	var splash_picks: Array = _pick_random_alive_monsters(1, [primary_target])
	if splash_picks.is_empty():
		return 0
	var second_target = splash_picks[0]
	if second_target == null:
		return 0

	var auth_cfg: Dictionary = PetSkillConfig.get_skill_definition(skill_key)
	var ratio: = maxf(0.0, float(auth_cfg.get("damage_ratio", skill_cfg.get("secondary_damage_ratio", 0.8))))
	var splash_calc: Dictionary = _calc_pet_splash_damage_to_monster(pet, second_target, ratio, coop_unit)
	var splash_damage: = int(splash_calc.get("damage", 1))
	var splash_pierced: bool = bool(splash_calc.get("pierced", false))
	var splash_crit: Dictionary = _apply_crit_to_damage(splash_damage, _get_pet_crit_stats(pet))
	splash_damage = int(splash_crit.get("damage", splash_damage))
	var splash_is_crit: bool = bool(splash_crit.get("is_critical", false))
	var second_name = _get_monster_stat(second_target, "monster_name", _get_monster_stat(second_target, "name", "怪物"))
	var splash_name: = str(auth_cfg.get("skill_name", skill_cfg.get("name", "溅射")))
	var splash_msg: = "%s✦ 溅射触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点溅射伤害" % [BATTLE_SKILL_LOG, pet.pet_name, second_name, splash_damage]
	if splash_is_crit:
		splash_msg += " [color=#ff922b]（暴击）[/color]"
	add_log(splash_msg, _attach_splash_hit_fx(_skill_highlight(splash_name, skill_anchor), _monster_index_of(second_target)))
	_apply_damage_to_monster(second_target, splash_damage)
	_emit_damage_dealt(pet.pet_name, second_name, splash_damage, splash_is_crit, "monster", _monster_index_of(second_target), pet.element, _get_monster_stat(second_target, "element", "普通"), splash_pierced)
	if not is_monster_alive(second_target):
		add_log("[color=#ffd43b]%s 被击败了![/color]" % second_name)
		unit_died.emit(second_name)
	return splash_damage


func get_replay_unit_hp(hit_target_type: String, hit_target_index: int) -> int:
	match hit_target_type:
		"player":
			return int(player.hp) if player else 0
		"pet":
			return int(active_pet.hp) if active_pet else 0
		"coop_player", "coop_pet":
			if hit_target_index >= 0 and hit_target_index < coop_units.size():
				var cu = coop_units[hit_target_index]
				return int(cu.hp) if cu else 0
		"monster":
			if hit_target_index >= 0 and hit_target_index < monsters.size():
				return int(_get_monster_stat(monsters[hit_target_index], "hp", 0))
	return -1

func set_replay_unit_hp(hit_target_type: String, hit_target_index: int, hp: int) -> void :
	var hp_f: = float(maxi(0, hp))
	match hit_target_type:
		"player":
			if player:
				var cap: float = float(player.max_hp)
				if player.has_method("get_max_hp"):
					cap = float(player.get_max_hp())
				player.hp = minf(hp_f, maxf(1.0, cap))
		"pet":
			if active_pet:
				var pet_cap: float = float(active_pet.max_hp)
				if active_pet.has_method("get_final_max_hp_with_equipment"):
					pet_cap = float(active_pet.get_final_max_hp_with_equipment())
				active_pet.hp = minf(hp_f, maxf(1.0, pet_cap))
		"coop_player", "coop_pet":
			if hit_target_index >= 0 and hit_target_index < coop_units.size():
				var cu = coop_units[hit_target_index]
				if cu:
					cu.hp = minf(hp_f, cu.max_hp)
					if cu.has_method("get_battle_pet"):
						var bp: Pet = cu.get_battle_pet()
						if bp != null:
							bp.hp = cu.hp
							bp.max_hp = cu.max_hp
		"monster":
			if hit_target_index >= 0 and hit_target_index < monsters.size():
				var m = monsters[hit_target_index]
				if m is Dictionary:
					m["hp"] = int(hp_f)
				elif m != null:
					m.hp = int(hp_f)

func apply_replay_log(message: String, highlight: Dictionary = {}) -> void :
	add_log(message, highlight)

func apply_replay_unit_turn(unit: Dictionary) -> void :
	var t: = str(unit.get("type", ""))
	var idx: = int(unit.get("index", -1))
	var hp: = get_replay_unit_hp(t, idx)
	if hp < 0 and t in ["coop_player", "coop_pet"]:
		var unit_name: = str(unit.get("name", ""))
		for i in range(coop_units.size()):
			var cu = coop_units[i]
			if cu == null or str(cu.unit_type) != t:
				continue
			if unit_name.is_empty() or str(cu.display_name) == unit_name:
				hp = int(cu.hp)
				idx = i
				break
	if t == "pet":
		if active_pet == null:
			return
		if pet_died_in_battle and int(active_pet.hp) <= 0:
			return
	elif hp <= 0:
		return
	var target_type: = str(unit.get("target_type", ""))
	var target_index: = int(unit.get("target_index", -1))

	if target_type != "":
		var target_hp: = get_replay_unit_hp(target_type, target_index)
		if target_hp == 0:
			return
	var safe_unit: = {
		"type": t, 
		"name": str(unit.get("name", "")), 
		"index": idx, 
		"target_type": target_type, 
		"target_index": target_index, 
		"skip_lunge": bool(unit.get("skip_lunge", false)), 
		"lunge_time_scale": float(unit.get("lunge_time_scale", 1.0)), 
		"lunge_start_delay": maxf(0.0, float(unit.get("lunge_start_delay", 0.0))), 
	}
	unit_turn.emit(safe_unit)

func apply_replay_damage_event(payload: Dictionary) -> void :
	var hit_type: = str(payload.get("hit_target_type", ""))
	var hit_idx: = int(payload.get("hit_target_index", -1))
	var damage_amount: = int(payload.get("damage", 0))
	var hp_after: = int(payload.get("target_hp_after", -1))

	if drive_by_execute_turn:
		if hp_after >= 0:
			set_replay_unit_hp(hit_type, hit_idx, hp_after)
		elif damage_amount > 0:
			var current_hp: = get_replay_unit_hp(hit_type, hit_idx)
			if current_hp >= 0:
				set_replay_unit_hp(hit_type, hit_idx, maxi(0, current_hp - damage_amount))
	elif hp_after >= 0:
		set_replay_unit_hp(hit_type, hit_idx, hp_after)
	damage_dealt.emit(
		str(payload.get("attacker", "")), 
		str(payload.get("target", "")), 
		damage_amount, 
		bool(payload.get("is_critical", false)), 
		hit_type, 
		hit_idx, 
		str(payload.get("element_tag", "")), 
		bool(payload.get("is_armor_pierce", payload.get("isArmorPierce", false))), 
		bool(payload.get("is_counter", payload.get("isCounter", false)))
	)

func apply_replay_hp_sync(payload: Dictionary) -> void :
	var hit_type: = str(payload.get("hit_target_type", ""))
	var hit_idx: = int(payload.get("hit_target_index", -1))
	var hp_after: = int(payload.get("target_hp_after", -1))
	if hp_after < 0:
		return
	set_replay_unit_hp(hit_type, hit_idx, hp_after)
	unit_hp_synced.emit(hit_type, hit_idx, hp_after)

func _normalize_arena_replay_unit_name(name: String) -> String:
	var s: = str(name).strip_edges()
	if s.begins_with("敌方灵兽·"):
		s = s.substr("敌方灵兽·".length())
	elif s.begins_with("我方灵兽·"):
		s = s.substr("我方灵兽·".length())
	elif s.begins_with("我方·"):
		s = s.substr("我方·".length())
	return s.strip_edges()

func _replay_ally_unit_name_matches(dead_name: String, unit_name: String) -> bool:
	var dead: = str(dead_name).strip_edges()
	var unit: = str(unit_name).strip_edges()
	if dead.is_empty() or unit.is_empty():
		return false
	if dead == unit:
		return true
	return _normalize_arena_replay_unit_name(dead) == _normalize_arena_replay_unit_name(unit)

func _replay_monster_name_matches_strict(dead_name: String, monster) -> bool:
	var dead: = str(dead_name).strip_edges()
	if dead.is_empty():
		return false
	var mname: = str(_get_monster_stat(monster, "monster_name", _get_monster_stat(monster, "name", ""))).strip_edges()
	if mname.is_empty():
		return false
	if dead == mname:
		return true
	var dead_norm: = _normalize_arena_replay_unit_name(dead)
	var m_norm: = _normalize_arena_replay_unit_name(mname)
	if dead_norm.is_empty() or m_norm.is_empty():
		return false
	if dead_norm != m_norm:
		return false
	var role: = str(_get_monster_stat(monster, "arena_role", "")).strip_edges()
	if dead.begins_with("敌方灵兽·"):
		return role.is_empty() or role == "pet"
	return role.is_empty() or role == "player"

func apply_replay_unit_died(unit_name: String, strict_match: bool = false, hit_target_type: String = "", hit_target_index: int = -1) -> void :
	var dead_name: = str(unit_name)
	var typed: = str(hit_target_type).strip_edges()

	if not typed.is_empty() and typed in ["player", "pet", "coop_player", "coop_pet", "monster"]:
		if typed == "monster":
			if hit_target_index >= 0:
				set_replay_unit_hp("monster", hit_target_index, 0)
			elif not dead_name.is_empty():
				for i in range(monsters.size()):
					var m = monsters[i]
					var mname: = str(_get_monster_stat(m, "monster_name", _get_monster_stat(m, "name", "")))
					var matched: = false
					if strict_match:
						matched = _replay_monster_name_matches_strict(dead_name, m)
					else:
						matched = dead_name == mname or dead_name in mname or mname in dead_name
					if matched:
						set_replay_unit_hp("monster", i, 0)
						if strict_match:
							break
		else:
			var idx: = hit_target_index
			if typed in ["player", "pet"]:
				idx = 0
			elif idx < 0:
				idx = 0
			set_replay_unit_hp(typed, idx, 0)
			if typed == "player":
				player_died_in_battle = true
				if player:
					player.hp_changed.emit(player.hp, player.get_max_hp())
			elif typed == "pet":
				pet_died_in_battle = true
		unit_died.emit(dead_name)
		return
	if player and _replay_ally_unit_name_matches(dead_name, str(player.player_name)):
		player.hp = 0
		player_died_in_battle = true
		player.hp_changed.emit(player.hp, player.get_max_hp())
	if active_pet and _replay_ally_unit_name_matches(dead_name, str(active_pet.pet_name)):
		active_pet.hp = 0.0
		pet_died_in_battle = true
	for cu in coop_units:
		if cu != null and str(cu.display_name) == dead_name:
			cu.hp = 0.0
	for i in range(monsters.size()):
		var m = monsters[i]
		var mname: = str(_get_monster_stat(m, "monster_name", _get_monster_stat(m, "name", "")))
		if dead_name.is_empty():
			continue
		var matched: = false
		if strict_match:
			matched = _replay_monster_name_matches_strict(dead_name, m)
		else:
			matched = dead_name == mname or dead_name in mname or mname in dead_name
		if matched:
			set_replay_unit_hp("monster", i, 0)
			if strict_match:
				break
	unit_died.emit(dead_name)

func apply_replay_battle_state(victory: bool) -> void :
	var already_over: = current_state == BattleState.VICTORY or current_state == BattleState.DEFEAT
	current_state = BattleState.VICTORY if victory else BattleState.DEFEAT
	if replay_log_only and not already_over:
		battle_ended.emit(victory)
