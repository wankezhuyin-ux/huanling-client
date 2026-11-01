extends Node
class_name GameManager

const GameData = preload("res://scripts/game_data.gd")
const ChatNetwork = preload("res://scripts/chat_network.gd")
const PetClass = preload("res://scripts/pet.gd")
const PlayerClass = preload("res://scripts/player.gd")
const PetManagerClass = preload("res://scripts/pet_manager.gd")
const PetCollectionManagerClass = preload("res://scripts/pet_collection/pet_collection_manager.gd")
const PetEquipmentManagerClass = preload("res://scripts/pet_equipment/pet_equipment_manager.gd")
const PetSoulManagerClass = preload("res://scripts/pet_soul/pet_soul_manager.gd")
const PetSkillManagerClass = preload("res://scripts/pet_skill_manager.gd")
const MartialSkillManagerClass = preload("res://scripts/martial_skill_manager.gd")
const BattleSystemClass = preload("res://scripts/battle_system.gd")
const CombatReplayPlayerClass = preload("res://scripts/battle_replay/combat_replay_player.gd")
const EquipmentManagerClass = preload("res://scripts/equipment_manager.gd")
const FabaoManagerClass = preload("res://scripts/fabao/fabao_manager.gd")
const FabaoWildStats = preload("res://scripts/fabao/fabao_wild_stats.gd")
const FabaoStatBonus = preload("res://scripts/fabao/fabao_stat_bonus.gd")
const SuitManagerClass = preload("res://scripts/suit_manager.gd")
const MartialArtsManagerClass = preload("res://scripts/martial_arts_manager.gd")
const InventoryManagerClass = preload("res://scripts/inventory_manager.gd")
const CraftingManagerClass = preload("res://scripts/crafting_manager.gd")
const QuestManagerClass = preload("res://scripts/quest_manager.gd")
const MailManagerClass = preload("res://scripts/mail/mail_manager.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")
const EvolutionDataClass = preload("res://scripts/evolution_data.gd")
const XianMoSystemClass = preload("res://scripts/xianmo/xianmo_system.gd")
const XianMoEventClass = preload("res://scripts/xianmo/xianmo_event.gd")
const XianMoRewardClass = preload("res://scripts/xianmo/xianmo_reward.gd")
const XianMoRankingClass = preload("res://scripts/xianmo/xianmo_ranking.gd")
const XianMoShopClass = preload("res://scripts/xianmo/xianmo_shop.gd")
const XianMoChestManagerClass = preload("res://scripts/xianmo/xianmo_chest_manager.gd")
const XianMoBattleProcessorClass = preload("res://scripts/xianmo/xianmo_battle_processor.gd")
const SuitEquipmentEnhanceClass = preload("res://scripts/suit/suit_equipment_enhance.gd")
const TitleManagerClass = preload("res://scripts/title/title_manager.gd")
const GangManagerClass = preload("res://scripts/gang/gang_manager.gd")
const ConfirmDialogClass = preload("res://ui/components/confirm_dialog.gd")
const GangHallUIClass = preload("res://ui/city/gang_hall.gd")

const TowerUI = preload("res://ui/city/tower_ui.gd")

static var instance: GameManager = null


signal world_announcement(message: String)
signal chat_message_received(msg_data: Dictionary)
signal world_event(event_type: String, player_name: String, details: Dictionary)

var player = null
var pet_manager = null
var pet_collection_manager = null
var pet_equipment_manager = null
var pet_soul_manager = null
var pet_skill_manager = null
var martial_skill_manager = null
var battle_system = null
var equipment_manager = null
var fabao_manager = null
var suit_manager = null
var martial_arts_manager = null
var inventory_manager = null
var crafting_manager = null
var chat_network: ChatNetwork = null
var quest_manager: QuestManager = null
var xianmo_system = null
var xianmo_event_processor = null
var xianmo_reward = null
var xianmo_ranking = null
var xianmo_shop = null
var xianmo_chest_manager = null
var xianmo_battle_processor = null
var title_manager = null
var gang_manager = null
var mail_manager: MailManager = null

var network = null
var is_logged_in: bool = false
var _last_broadcast_id: int = 0
var _seen_broadcast_ids: Dictionary = {}
var _broadcast_first_fetch_done: bool = false
var _broadcast_session_anchor_ready: bool = false
var _broadcast_anchor_pending_request: bool = false


var _pending_events: Array = []
var _event_flush_timer: Timer = null
const EVENT_FLUSH_INTERVAL: float = 30.0
const EVENT_FLUSH_MAX_COUNT: int = 30
const BROADCAST_CURSOR_CONFIG_PATH: = "user://broadcast_cursor.cfg"
const BROADCAST_SHOWN_DEDUP_SEC: = 120.0
var _shown_broadcast_fingerprints: Dictionary = {}
var _pending_server_broadcast_text: String = ""


func track_event(event_type: String, event_data: Dictionary = {}) -> void :
	_pending_events.append({
		"eventType": event_type, 
		"eventData": event_data, 
	})
	if _pending_events.size() >= EVENT_FLUSH_MAX_COUNT:
		_flush_pending_events()
	elif _event_flush_timer == null:
		_event_flush_timer = Timer.new()
		_event_flush_timer.name = "event_flush_timer"
		_event_flush_timer.one_shot = false
		_event_flush_timer.wait_time = EVENT_FLUSH_INTERVAL
		_event_flush_timer.timeout.connect(_flush_pending_events)
		add_child(_event_flush_timer)
		_event_flush_timer.start()


func _flush_pending_events() -> void :
	if _pending_events.is_empty():
		return
	var events_to_send = _pending_events.duplicate()
	_pending_events.clear()
	if network and network.has_method("send_events_batch"):
		network.send_events_batch(events_to_send)


func strip_local_after_authoritative_suit_dismantle(equipment_id: String, sealed_item_id: String) -> void :
	if equipment_id != "" and equipment_manager:
		for eq in equipment_manager.inventory:
			if eq.id == equipment_id:
				equipment_manager.inventory.erase(eq)
				equipment_manager.inventory_changed.emit()
				break
	if sealed_item_id != "" and inventory_manager:
		inventory_manager.remove_item(sealed_item_id, 1)



var bgm_player: AudioStreamPlayer = null
var bgm_enabled: bool = true
var bgm_volume: float = 0.5
var current_bgm: String = ""

const BGM_BATTLE = "res://Music/zdyy.mp3"
const BGM_NORMAL = "res://Music/bjyy.mp3"


const BGM_PET_PARK = "res://Music/宠物园.mp3"
const BGM_MARTIAL_HALL = "res://Music/武道馆.mp3"
const BGM_QIANKUN_HALL = "res://Music/乾坤炉.mp3"
const BGM_FORGE_HALL = "res://Music/打造坊.mp3"
const BGM_RANKING_HALL = "res://Music/排行榜.mp3"
const BGM_TOWER = "res://Music/闯天关.mp3"
const BGM_SUIT_DUNGEON = "res://Music/套装副本.mp3"
const BGM_WAREHOUSE = "res://Music/物品仓库.mp3"
const BGM_SETTINGS = "res://Music/设置.mp3"
const BGM_MAIL = "res://Music/邮件.mp3"
const BGM_QUEST = "res://Music/任务.mp3"
const BGM_XIANMO = "res://Music/仙魔战场.mp3"
const BGM_SHOP = "res://Music/商店街.mp3"
const BGM_LUCKY_DRAW = "res://Music/幸运抽奖.mp3"



const ALLOW_LEGACY_PLAINTEXT_JSON_SAVE: bool = false


var current_map: String = "浮影水城外郊（0,0）"
var in_battle: bool = false
var _wild_replay_busy: bool = false
var _wild_replay_token: String = ""

var _wild_replay_map_difficulty: String = ""
var _wild_replay_abort: bool = false

var _wild_replay_gen: int = 0

const FIELD_WILD_RUN_MIN_GAP_MS: = 1000
var _last_wild_run_sent_ms: int = 0
var _tower_replay_busy: bool = false
var _tower_replay_token: String = ""
var _tower_replay_abort: bool = false
var _tower_replay_server_victory: bool = false
var initialized: bool = false
var auto_capture_enabled: bool = true
var min_growth_threshold: float = 0.0
var auto_change_map_enabled: bool = false
var previous_map: String = ""
var auto_change_map_consecutive_wins: int = 0
var auto_change_map_consecutive_deaths: int = 0
var auto_change_map_upgrade_cooldown: float = 0.0


var is_tower_battle: bool = false
var is_tower_settling: bool = false
var current_tower_floor: int = 0
var last_battle_was_tower: bool = false
var last_tower_fail_reason: String = ""
var last_battle_was_world_boss: bool = false
var last_battle_was_arena: bool = false
var last_battle_was_gang_kick: bool = false
var last_battle_was_gang_siege: bool = false
var stop_tower_requested: bool = false

var is_tower_run_active: bool = false
var stop_suit_dungeon_requested: bool = false

var auto_battle_enabled: bool = true

var _field_auto_retry_until_ms: int = 0
var _field_auto_retry_streak: int = 0

var _field_combat_hp_protect_until_ms: int = 0
var _player_attr_authority_guard_until_ms: int = 0
const _PLAYER_ATTR_AUTHORITY_GUARD_MS: = 30000
const _PLAYER_ATTR_BASE_STAT_KEYS: Array = ["vitality", "magic", "attack_base", "defense_base", "agility_base"]
const _PLAYER_ATTR_BASE_STAT_FLOOR: = 10
const _PLAYER_ATTR_MAX_HP_LEVEL0: = 100
const _PLAYER_ATTR_MAX_HP_PER_LEVEL: = 5
const _PLAYER_ATTR_RESET_GUARD_SPAN: = 20
const _PLAYER_ATTR_POINT_POOL_SLACK: = 120
var _realm_transition_duplicate_download_pending: bool = false

func set_auto_battle_enabled(enabled: bool, discard_field_loot_responses: bool = false) -> void :
	auto_battle_enabled = enabled

	_reset_field_auto_retry_progress()
	if enabled:
		var main_ui: = _find_main_ui_node()
		if main_ui:
			main_ui.set("_battle_cooldown_deadline_ms", 0)
			main_ui.set("_battle_countdown_active", false)
		return
	_detach_running_wild_replay()
	clear_field_combat_hp_protection()
	if discard_field_loot_responses:
		_discard_field_battle_loot_responses_on_stop()
	else:
		_flush_field_battle_loot_batch()

func is_auto_battle_enabled() -> bool:
	return auto_battle_enabled

func is_field_combat_hp_merge_blocked() -> bool:
	if in_battle:
		return true
	if is_in_instanced_challenge():
		return true
	return Time.get_ticks_msec() < _field_combat_hp_protect_until_ms

func _should_skip_battle_loot_pet_slice() -> bool:
	return is_in_instanced_challenge()

func begin_pet_merge_exp_block(main_pet_id: String, sub_pet_id: String, duration_ms: int = 90000) -> void :
	_pet_merge_block_ids.clear()
	var main_id: = str(main_pet_id).strip_edges()
	var sub_id: = str(sub_pet_id).strip_edges()
	if not main_id.is_empty():
		_pet_merge_block_ids[main_id] = true
	if not sub_id.is_empty():
		_pet_merge_block_ids[sub_id] = true
	_pet_merge_block_until_ms = maxi(_pet_merge_block_until_ms, Time.get_ticks_msec() + maxi(0, duration_ms))

func clear_pet_merge_exp_block() -> void :
	_pet_merge_block_ids.clear()
	_pet_merge_block_until_ms = 0

var _pet_merge_battle_guard_active: bool = false


func begin_pet_merge_battle_guard(max_wait_ms: int = 75000) -> void :
	_pet_merge_battle_guard_active = true
	block_battle_start_temporarily(maxi(BATTLE_START_BLOCK_ROSTER_REFRESH_MS, max_wait_ms), "pet_merge_in_progress")

func clear_pet_merge_battle_guard() -> void :
	if not _pet_merge_battle_guard_active:
		return
	_pet_merge_battle_guard_active = false
	_clear_battle_start_block_for_field_resume()
	block_battle_start_temporarily(BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "pet_merge_settle")

func finish_pet_merge_operation() -> void :
	clear_pet_merge_exp_block()
	clear_pet_merge_battle_guard()
	refresh_field_battle_after_pet_merge()

func refresh_field_battle_after_pet_merge() -> void :
	if battle_system != null and battle_system.has_method("_refresh_battle_active_pet"):
		battle_system._refresh_battle_active_pet()
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_refresh_battle_ally_labels_after_settlement"):
		main_ui.call_deferred("_refresh_battle_ally_labels_after_settlement")

func is_pet_merge_exp_blocked_for_pet(pet) -> bool:
	if Time.get_ticks_msec() >= _pet_merge_block_until_ms:
		return false
	if pet == null:
		return false
	var pid: = str(pet.id).strip_edges()
	return not pid.is_empty() and _pet_merge_block_ids.has(pid)

func _touch_field_combat_hp_protection(extra_ms: int = 25000) -> void :
	if is_in_instanced_challenge():
		return
	var until_ms: = Time.get_ticks_msec() + maxi(0, extra_ms)
	_field_combat_hp_protect_until_ms = maxi(_field_combat_hp_protect_until_ms, until_ms)

func clear_field_combat_hp_protection() -> void :
	_field_combat_hp_protect_until_ms = 0
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_flush_deferred_attr_authoritative_save"):
		main_ui.call_deferred("_flush_deferred_attr_authoritative_save")
	if main_ui and main_ui.has_method("_maybe_retry_player_attr_auto_allocate"):
		main_ui.call_deferred("_maybe_retry_player_attr_auto_allocate", "post_combat")

func _schedule_field_combat_hp_protection_release(delay_ms: int) -> void :
	if delay_ms <= 0:
		return
	var tree: = get_tree()
	if tree == null:
		return
	var timer: = tree.create_timer(float(delay_ms) / 1000.0)
	timer.timeout.connect( func() -> void :
		if is_auto_battle_enabled():
			return
		if Time.get_ticks_msec() < _field_combat_hp_protect_until_ms:
			return
		clear_field_combat_hp_protection()
	, CONNECT_ONE_SHOT)

func _begin_field_exp_settlement_window() -> void :
	if is_in_instanced_challenge():
		return
	_field_exp_window_until_ms = Time.get_ticks_msec() + FIELD_EXP_SETTLEMENT_WINDOW_MS
	_field_exp_player_granted_in_window = false
	_field_gang_bonus_logged_in_window = false
	_field_newbie_exp_bonus_logged_in_window = false
	_field_catchup_logged_in_window = false
	_field_vip_exp_bonus_logged_in_window = false
	_field_double_exp_bonus_logged_in_window = false
	_field_fabao_exp_bonus_logged_in_window = false
	_field_map_diff_exp_bonus_logged_in_window = false
	_field_noble_exp_bonus_logged_in_window = false
	_field_weekend_exp_bonus_logged_in_window = false
	_field_exp_pet_granted_in_window = false
	_field_exp_level_cap_player = int(player.level) if player else 1
	var ap = pet_manager.get_active_pet() if pet_manager else null
	_field_exp_level_cap_pet = int(ap.level) if ap else 1
	_field_battle_pet_level_at_start = _field_exp_level_cap_pet
	if _field_battle_loot_pending.is_empty():
		_field_battle_loot_slice_batch_budget = 1
		_field_battle_loot_slice_anchor_pet = 0
		_field_battle_loot_slice_anchor_player = 0

func _is_field_pet_level_protection_active() -> bool:
	return _is_field_exp_window_active() or not _field_battle_loot_pending.is_empty() or _field_battle_pet_level_at_start > 0

func _maybe_clear_field_battle_pet_level_guard() -> void :
	if _field_battle_loot_pending.is_empty():
		_field_battle_pet_level_at_start = 0
		_field_battle_loot_slice_anchor_pet = 0
		_field_battle_loot_slice_anchor_player = 0
		_field_battle_loot_slice_batch_budget = 1

func reset_field_battle_pet_level_anchor_on_switch() -> void :
	var ap = pet_manager.get_active_pet() if pet_manager else null
	if ap != null:
		_field_battle_pet_level_at_start = int(ap.level)
		_field_exp_level_cap_pet = int(ap.level)
	_field_battle_loot_slice_anchor_pet = 0
	if _field_battle_loot_pending.is_empty():
		_field_battle_loot_slice_batch_budget = 1

func get_field_battle_pet_level_anchor() -> int:
	if _field_battle_loot_slice_anchor_pet > 0:
		return _field_battle_loot_slice_anchor_pet
	return _field_battle_pet_level_at_start

func get_field_battle_player_level_anchor() -> int:
	if _field_battle_loot_slice_anchor_player > 0:
		return _field_battle_loot_slice_anchor_player
	return _field_exp_level_cap_player

func get_field_catchup_level_ups() -> int:
	if player != null and player.has_method("get_field_max_level_ups"):
		return player.get_field_max_level_ups()
	return 1

func get_field_battle_loot_batch_level_budget() -> int:
	return maxi(1, _field_battle_loot_slice_batch_budget)

func _field_battle_loot_batch_battle_count() -> int:
	return maxi(0, int(_field_battle_loot_batch.get("battle_count", 0)))

func _reset_field_battle_loot_batch() -> void :
	_field_battle_loot_batch = {}

func _summarize_battle_loot_monsters_for_batch(loot_payload: Array, exp_reward: int, g_reward: int) -> Dictionary:
	var max_level: = 1
	var total_exp: = 0
	for m in loot_payload:
		if m is Dictionary:
			max_level = maxi(max_level, int(m.get("level", 1)))
			total_exp += int(m.get("exp_reward", m.get("exp", 0)))
	if total_exp <= 0:
		total_exp = maxi(0, exp_reward)
	return {
		"level": max_level, 
		"exp_reward": total_exp, 
		"gold_reward": maxi(0, g_reward), 
	}

func _accumulate_field_battle_loot_batch(
	loot_payload: Array, 
	exp_reward: int, 
	g_reward: int, 
	player_died: bool, 
	pet_died: bool, 
	capture_candidate: Dictionary, 
	dropped_item: String, 
	active_pet, 
	preview_snapshot: Dictionary = {}, 
) -> void :
	if _field_battle_loot_batch_battle_count() <= 0:
		_field_battle_loot_batch = {
			"anchor_pet_level": _field_battle_pet_level_at_start, 
			"anchor_player_level": _field_exp_level_cap_player, 
			"monsters": [], 
			"total_g_reward": 0, 
			"total_exp_reward": 0, 
			"battle_count": 0, 
			"player_died_any": false, 
			"pet_died_any": false, 
			"last_active_pet": active_pet, 
			"last_capture_candidate": {}, 
			"last_dropped_item": "", 
			"idle_flush_at_ms": 0, 
			"preview_snapshot": preview_snapshot if preview_snapshot is Dictionary else {}, 
		}
	var monsters: Array = _field_battle_loot_batch.get("monsters", [])
	monsters.append(_summarize_battle_loot_monsters_for_batch(loot_payload, exp_reward, g_reward))
	_field_battle_loot_batch["monsters"] = monsters
	_field_battle_loot_batch["battle_count"] = _field_battle_loot_batch_battle_count() + 1
	_field_battle_loot_batch["total_g_reward"] = int(_field_battle_loot_batch.get("total_g_reward", 0)) + g_reward
	_field_battle_loot_batch["total_exp_reward"] = int(_field_battle_loot_batch.get("total_exp_reward", 0)) + exp_reward
	_field_battle_loot_batch["player_died_any"] = (
		bool(_field_battle_loot_batch.get("player_died_any", false)) or player_died
	)
	_field_battle_loot_batch["pet_died_any"] = bool(_field_battle_loot_batch.get("pet_died_any", false)) or pet_died
	_field_battle_loot_batch["last_active_pet"] = active_pet
	_field_battle_loot_batch["last_capture_candidate"] = capture_candidate
	_field_battle_loot_batch["last_dropped_item"] = dropped_item
	_field_battle_loot_batch["idle_flush_at_ms"] = Time.get_ticks_msec() + FIELD_BATTLE_LOOT_BATCH_IDLE_FLUSH_MS

func _should_flush_field_battle_loot_batch_now() -> bool:
	var count: = _field_battle_loot_batch_battle_count()
	if count <= 0:
		return false
	if count >= FIELD_BATTLE_LOOT_BATCH_FLUSH_COUNT:
		return true
	var monsters: Array = _field_battle_loot_batch.get("monsters", [])
	return monsters.size() >= FIELD_BATTLE_LOOT_BATCH_MAX_MONSTERS

func _is_field_battle_speed_throttle_cooldown_active() -> bool:
	return Time.get_ticks_msec() < _battle_speed_throttle_cooldown_until_ms

func _apply_battle_speed_throttle_cooldown() -> void :
	_battle_speed_throttle_cooldown_until_ms = Time.get_ticks_msec() + BATTLE_SPEED_THROTTLE_COOLDOWN_MS
	_end_field_loot_await_next_fight()
	set_auto_battle_enabled(false, false)
	_sync_main_ui_auto_battle_stopped()

func _field_battle_loot_min_send_gap_ms(batch_count: int) -> int:
	return FIELD_BATTLE_LOOT_LEGIT_MS_PER_BATTLE * maxi(1, batch_count)

func _finalize_realm_transition_field_exp_state() -> void :
	_discard_field_battle_loot_responses_on_stop()
	_field_exp_level_cap_player = 1
	_field_battle_loot_slice_anchor_player = 1
	if player == null:
		return
	player.experience = 0
	player.exp_changed.emit(player.experience, player.get_required_exp())

func _discard_field_battle_loot_responses_on_stop() -> void :
	_end_field_loot_await_next_fight()
	_field_battle_loot_stop_epoch += 1
	_field_battle_loot_discard_ids.clear()
	for op_id in _field_battle_loot_pending.keys():
		_field_battle_loot_discard_ids[op_id] = true
	_reset_field_battle_loot_batch()
	if network != null and network.has_method("cancel_pending_economy_battle_loot"):
		network.cancel_pending_economy_battle_loot()
	_maybe_clear_field_battle_pet_level_guard()

func _should_discard_field_battle_loot_result(rid: String, ctx: Dictionary) -> bool:
	if rid.is_empty():
		return false
	if _field_battle_loot_discard_ids.has(rid):
		return true
	return int(ctx.get("loot_stop_epoch", 0)) < _field_battle_loot_stop_epoch

func _field_battle_loot_should_block_dispatch(ctx: Dictionary) -> bool:
	if is_auto_battle_enabled():
		return false
	return not bool(ctx.get("allow_when_auto_off", false))

func _process_field_battle_loot_batch_idle_flush() -> void :
	if _field_battle_loot_batch_battle_count() <= 0:
		return
	var at_ms: = int(_field_battle_loot_batch.get("idle_flush_at_ms", 0))
	if at_ms > 0 and Time.get_ticks_msec() >= at_ms:
		_flush_field_battle_loot_batch()

func _flush_field_battle_loot_batch() -> void :
	var count: = _field_battle_loot_batch_battle_count()
	if count <= 0 or network == null or not network.is_logged_in():
		_reset_field_battle_loot_batch()
		return
	var monsters: Array = _field_battle_loot_batch.get("monsters", [])
	if monsters.is_empty():
		_reset_field_battle_loot_batch()
		return
	var g_reward: = int(_field_battle_loot_batch.get("total_g_reward", 0))
	var exp_reward: = int(_field_battle_loot_batch.get("total_exp_reward", 0))
	var active_pet = _field_battle_loot_batch.get("last_active_pet", null)
	var anchor_pet: = int(_field_battle_loot_batch.get("anchor_pet_level", _field_battle_pet_level_at_start))
	var anchor_player: = int(_field_battle_loot_batch.get("anchor_player_level", _field_exp_level_cap_player))
	var batch_count: = mini(count, FIELD_BATTLE_LOOT_BATCH_MAX_BATTLES)
	var op_id: = "battle_loot_batch_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var loot_extras: = {
		"playerDied": bool(_field_battle_loot_batch.get("player_died_any", false)), 
		"petDied": bool(_field_battle_loot_batch.get("pet_died_any", false)), 
		"batchBattleCount": batch_count, 
	}
	if active_pet:
		loot_extras["activePetId"] = str(active_pet.id)
		loot_extras["clientPetLevel"] = int(active_pet.level)
		loot_extras["clientPetExperience"] = int(active_pet.experience)
		var client_progress: = _build_battle_loot_client_pet_progress_snapshot(active_pet)
		if not client_progress.is_empty():
			loot_extras["clientPetProgress"] = client_progress
	if auto_capture_enabled:
		loot_extras["minGrowthThreshold"] = min_growth_threshold
	_dispatch_field_battle_loot_async(op_id, monsters, "", loot_extras, {
		"previewed_online_rewards": false, 
		"g_reward": g_reward, 
		"exp_reward": exp_reward, 
		"dropped_item": "", 
		"active_pet": active_pet, 
		"batch_battle_count": batch_count, 
		"anchor_pet_level": anchor_pet, 
		"anchor_player_level": anchor_player, 
	}.merged(_field_battle_loot_batch.get("preview_snapshot", {})), 
	)
	_reset_field_battle_loot_batch()

func _dispatch_immediate_field_battle_loot(
	loot_payload: Array, 
	g_reward: int, 
	exp_reward: int, 
	dropped_item: String, 
	loot_extras: Dictionary, 
	ctx: Dictionary, 
) -> void :
	_flush_field_battle_loot_batch()
	var op_id: = "battle_loot_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var batch_count: = maxi(1, int(ctx.get("batch_battle_count", 1)))
	var anchor_pet: = int(ctx.get("anchor_pet_level", _field_battle_pet_level_at_start))
	var anchor_player: = int(ctx.get("anchor_player_level", _field_exp_level_cap_player))
	loot_extras["batchBattleCount"] = batch_count
	ctx["batch_battle_count"] = batch_count
	ctx["anchor_pet_level"] = anchor_pet
	ctx["anchor_player_level"] = anchor_player
	_dispatch_field_battle_loot_async(op_id, loot_payload, dropped_item, loot_extras, ctx)

func _begin_field_loot_await_next_fight() -> void :
	_field_loot_hold_next_fight = true
	_field_loot_hold_until_ms = Time.get_ticks_msec() + FIELD_LOOT_AWAIT_NEXT_FIGHT_MS

func _end_field_loot_await_next_fight() -> void :
	_field_loot_hold_next_fight = false
	_field_loot_hold_until_ms = 0

func _sync_main_ui_auto_battle_stopped() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui == null:
		return
	main_ui.set("auto_battle", false)
	var btn = main_ui.get("stop_battle_btn")
	if btn:
		btn.text = "开始战斗"

func _pause_field_auto_for_loot_fail(msg: String) -> void :
	_end_field_loot_await_next_fight()
	if not msg.is_empty() and battle_system:
		battle_system.add_log("[color=orange]%s[/color]" % msg)
	set_auto_battle_enabled(false, false)
	_sync_main_ui_auto_battle_stopped()

func _reset_field_auto_retry_progress() -> void :
	_field_auto_retry_until_ms = 0
	_field_auto_retry_streak = 0

func _field_auto_retry_delay_ms() -> int:
	var delays: Array = [8000, 15000, 30000, 60000]
	var idx: = clampi(_field_auto_retry_streak, 0, delays.size() - 1)
	return int(delays[idx])

func _is_field_auto_hard_stop_error(data: Dictionary, err: String) -> bool:
	if _is_battle_speed_loot_block_response(data, err):
		return true
	if str(data.get("code", "")) == "WILD_REPLAY_OFF":
		return true
	if err.find("封禁") >= 0 or str(data.get("error", "")).find("封禁") >= 0:
		return true
	return false



func _defer_field_auto_after_transient(reason: String) -> void :
	_end_field_loot_await_next_fight()
	if not is_auto_battle_enabled():
		if battle_system and not reason.is_empty():
			battle_system.add_log("[color=orange]%s[/color]" % reason)
		return
	var delay_ms: = _field_auto_retry_delay_ms()
	_field_auto_retry_streak += 1
	_field_auto_retry_until_ms = Time.get_ticks_msec() + delay_ms
	var main_ui: = _find_main_ui_node()
	if main_ui:
		main_ui.set("_battle_cooldown_deadline_ms", _field_auto_retry_until_ms)
		main_ui.set("_battle_countdown_active", false)
		main_ui.set("battle_cooldown", float(delay_ms) / 1000.0)
	var sec: = maxi(1, int(round(float(delay_ms) / 1000.0)))
	var tail: = "网络不稳，约 %d 秒后自动继续挂机。" % sec
	if battle_system:
		if reason.is_empty():
			battle_system.add_log("[color=orange]%s[/color]" % tail)
		else:
			var head: = reason
			if not head.ends_with("。") and not head.ends_with("，"):
				head += "。"
			battle_system.add_log("[color=orange]%s%s[/color]" % [head, tail])

func _process_field_loot_await_timeout() -> void :
	if not _field_loot_hold_next_fight:
		return
	if Time.get_ticks_msec() < _field_loot_hold_until_ms:
		return
	_end_field_loot_await_next_fight()
	if battle_system:
		battle_system.add_log("[color=orange]战斗结算较慢，先继续战斗。[/color]")

func _try_apply_battle_loot_pet_slice(save_data: Dictionary, force_absolute_exp_sync: bool) -> void :
	if pet_manager == null or _should_skip_battle_loot_pet_slice():
		return
	var ap = pet_manager.get_active_pet()
	if ap == null:
		return
	var pet_slice: = _find_pet_dict_in_save_data(save_data, str(ap.id))
	if pet_slice.is_empty():
		print("[GameManager] battle-loot skip pet slice: saveData missing active pet with growth fields")
		return
	if pet_manager._is_partial_battle_loot_pet_slice(pet_slice):
		print("[GameManager] battle-loot skip partial pet slice without growth in saveData id=%s" % str(ap.id))
		return
	pet_manager.apply_active_pet_battle_loot_slice(pet_slice, force_absolute_exp_sync)

func _build_battle_loot_client_pet_progress_snapshot(pet) -> Dictionary:
	if pet == null:
		return {}
	if pet.has_method("to_dict"):
		return pet.to_dict()
	return {}

func _is_field_exp_window_active() -> bool:
	return Time.get_ticks_msec() < _field_exp_window_until_ms

func _try_consume_field_player_exp_grant_slot() -> bool:
	if not _is_field_exp_window_active():
		return true
	if _field_exp_player_granted_in_window:
		return false
	_field_exp_player_granted_in_window = true
	return true

func _try_consume_field_pet_exp_grant_slot() -> bool:
	if not _is_field_exp_window_active():
		return true
	if _field_exp_pet_granted_in_window:
		return false
	_field_exp_pet_granted_in_window = true
	return true

func _cap_field_progress_exp(level: int, exp_value: int) -> int:
	var req: = GameData.get_required_exp(level)
	return clampi(exp_value, 0, maxi(0, req - 1))

func _cap_field_pet_progress_exp(level: int, exp_value: int) -> int:
	var req: = GameData.get_pet_required_exp(level)
	return clampi(exp_value, 0, maxi(0, req - 1))

func _clamp_field_player_level_after_exp() -> void :
	if not _is_field_exp_window_active() or player == null:
		return
	var max_level: = _field_exp_level_cap_player + get_field_catchup_level_ups()
	if player.level <= max_level:
		return
	player.level = max_level
	player.experience = 0
	player.exp_changed.emit(player.experience, GameData.get_required_exp(player.level))

func _clamp_field_pet_level_after_exp(pet) -> void :
	if not _is_field_pet_level_protection_active() or pet == null:
		return
	if pet.has_method("is_at_max_level") and pet.is_at_max_level():
		return
	var cap_base: = _field_exp_level_cap_pet
	if _field_battle_loot_slice_anchor_pet > 0:
		cap_base = _field_battle_loot_slice_anchor_pet
	elif _field_battle_pet_level_at_start > 0:
		cap_base = _field_battle_pet_level_at_start
	var budget: = maxi(1, _field_battle_loot_slice_batch_budget) * get_field_catchup_level_ups()
	var max_level: = cap_base + budget
	if int(pet.level) <= max_level:
		return
	print(
		"[GameManager] battle-loot clamped pet level id=%s from=%d to=%d capBase=%d"
		%[str(pet.id), int(pet.level), max_level, cap_base]
	)
	pet.level = max_level
	pet.experience = 0
	if pet.has_method("clamp_experience_if_max_level"):
		pet.clamp_experience_if_max_level()

func is_field_battle_loot_upload_blocked() -> bool:
	return not _field_battle_loot_pending.is_empty()

func is_in_instanced_challenge() -> bool:
	return (
		is_tower_battle or is_tower_settling or is_tower_run_active
		or is_suit_dungeon_battle or is_suit_dungeon_settling
		or is_atlas_dungeon_battle or is_atlas_dungeon_settling
		or is_five_elements_battle or is_fe_settling
		or is_brother_tower_battle or is_brother_tower_settling
		or is_world_boss_battle
		or is_arena_battle
		or is_shengsi_tower_replay
		or is_shengsi_replay_result_open
	)

func _is_other_instanced_battle_active(exclude_mode: String) -> bool:
	if exclude_mode != "tower":
		if is_tower_battle or is_tower_settling or is_tower_run_active:
			return true
	if exclude_mode != "suit":
		if is_suit_dungeon_battle or is_suit_dungeon_settling:
			return true
	if exclude_mode != "atlas":
		if is_atlas_dungeon_battle or is_atlas_dungeon_settling:
			return true
	if exclude_mode != "five_elements":
		if is_five_elements_battle or is_fe_settling:
			return true
	if exclude_mode != "brother_tower":
		if is_brother_tower_battle or is_brother_tower_settling:
			return true
	if exclude_mode != "world_boss":
		if is_world_boss_battle:
			return true
	if exclude_mode != "arena":
		if is_arena_battle or is_shengsi_tower_replay or is_shengsi_replay_result_open:
			return true
	return false

const INSTANCED_CHALLENGE_BLOCK_MSG: = "其他挑战正在进行中，请先完成或停止当前挑战后再试"

func get_instanced_challenge_block_message(exclude_mode: String = "") -> String:
	if _is_other_instanced_battle_active(exclude_mode):
		return INSTANCED_CHALLENGE_BLOCK_MSG
	return ""

func is_field_battle_blocking_challenge() -> bool:
	return in_battle and not is_in_instanced_challenge()

func _disconnect_all_battle_ended_handlers() -> void :
	if battle_system == null:
		return
	if battle_system.battle_ended.is_connected(_on_battle_ended):
		battle_system.battle_ended.disconnect(_on_battle_ended)
	if battle_system.battle_ended.is_connected(_on_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_tower_battle_ended)
	if battle_system.battle_ended.is_connected(_on_suit_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_suit_dungeon_battle_ended)
	if battle_system.battle_ended.is_connected(_on_atlas_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_atlas_dungeon_battle_ended)
	if battle_system.battle_ended.is_connected(_on_fe_battle_ended):
		battle_system.battle_ended.disconnect(_on_fe_battle_ended)
	if battle_system.battle_ended.is_connected(_on_brother_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_brother_tower_battle_ended)
	if battle_system.battle_ended.is_connected(_on_world_boss_battle_ended):
		battle_system.battle_ended.disconnect(_on_world_boss_battle_ended)
	if battle_system.battle_ended.is_connected(_on_arena_battle_ended):
		battle_system.battle_ended.disconnect(_on_arena_battle_ended)

func _end_tower_run_session(resume_field_auto: bool = true) -> void :
	is_tower_run_active = false
	if resume_field_auto:
		resume_field_auto_battle_after_instanced_challenge()


func prepare_seamless_pet_switch() -> Dictionary:
	var was_auto: = is_auto_battle_enabled()
	if in_battle and not is_in_instanced_challenge():
		force_stop_field_battle()
	if was_auto:
		set_auto_battle_enabled(false)
	return {"was_auto": was_auto}

func finish_seamless_pet_switch(was_auto: bool) -> void :
	if was_auto:
		set_auto_battle_enabled(true)


var is_suit_dungeon_battle: bool = false
var is_world_boss_battle: bool = false
var world_boss_battle_token: String = ""
var world_boss_damage_dealt: int = 0
var _world_boss_status_refresh_busy: bool = false
var _world_boss_status_refresh_pending: bool = false
var _world_boss_ui_root: WeakRef = null
var _world_boss_challenge_in_flight: bool = false
var _world_boss_last_settle: Dictionary = {}
var world_boss_battle_max_rounds: int = 10
var _world_boss_server_damage: int = 0
var _world_boss_use_server_damage: bool = false
var _world_boss_replay_abort: bool = false
var is_arena_battle: bool = false
var is_shengsi_tower_replay: bool = false
var is_shengsi_replay_result_open: bool = false
var _shengsi_replay_abort: bool = false
var _replay_log_skip: bool = false
var _shengsi_last_replay: Dictionary = {}
var arena_battle_token: String = ""
var arena_battle_max_rounds: int = 20
var arena_battle_character_id: int = 0
var _arena_ui_root: WeakRef = null
var _arena_status_refresh_busy: bool = false
var _arena_status_refresh_pending: bool = false
var _arena_mirror_update_busy: bool = false
var _gang_mirror_update_busy: bool = false
var _treasure_mirror_update_busy: bool = false
var _shengsi_mirror_update_busy: bool = false
var _brother_tower_mirror_update_busy: bool = false
var _shengsi_pin_cooldown_until_ms: int = 0
const SHENGSI_PIN_COOLDOWN_MS: = 3000
const MIRROR_UPDATE_COOLDOWN_MS: = 60000
var _mirror_update_cooldown_until_ms: int = 0
var _gang_kick_battle_result: Dictionary = {}
var _gang_siege_battle_result: Dictionary = {}
var _arena_last_settle: Dictionary = {}
var current_suit_dungeon_level: int = 0
var last_battle_was_suit_dungeon: bool = false
var current_suit_dungeon_wave: int = 1
var suit_dungeon_all_waves: Array = []
var last_suit_dungeon_drops: Dictionary = {}
var last_suit_dungeon_clear_gold: int = -1
var is_suit_dungeon_settling: bool = false


var is_atlas_dungeon_battle: bool = false
var current_atlas_dungeon_tier: String = ""
var current_atlas_dungeon_wave: int = 1
var atlas_dungeon_all_waves: Array = []
var stop_atlas_dungeon_requested: bool = false
var is_atlas_dungeon_settling: bool = false
var current_atlas_dungeon_start_op_id: String = ""
var _atlas_start_wave_count: int = 0
var _atlas_start_monsters_per_wave: int = 0
var _atlas_start_monster_level: int = 0
var atlas_dungeon_defeated_pet_ids: Array = []
var atlas_dungeon_session_captures: int = 0
var atlas_dungeon_session_atlas: int = 0
var atlas_dungeon_session_discarded: int = 0
signal atlas_dungeon_battle_started(tier: String)
signal atlas_dungeon_battle_ended(victory: bool, tier: String)
signal atlas_dungeon_wave_started(tier: String, wave: int, total_waves: int)


var is_brother_tower_battle: bool = false
var is_brother_tower_settling: bool = false
var stop_brother_tower_requested: bool = false
var brother_tower_session_id: int = 0
var brother_tower_battle_seed: int = 0
var brother_tower_current_wave: int = 1
var brother_tower_all_waves: Array = []
var brother_tower_coop_units: Array = []
var brother_tower_local_snapshot: Dictionary = {}
var brother_tower_waiting_reconnect: bool = false
var brother_tower_waiting_partner: bool = false
var brother_tower_role: String = ""
var brother_tower_driver_user_id: int = 0
var brother_tower_viewer_wave_pending: bool = false
var _viewer_wave_restart_in_flight: bool = false
var brother_tower_difficulty: String = "easy"
var brother_tower_dismissed_session_id: int = 0
var brother_tower_last_complete_result: Dictionary = {}
var brother_tower_victory_popup_session_id: int = 0
var _brother_tower_pending_victory_reward: Dictionary = {}
var _brother_tower_victory_finalized: bool = false
var _brother_tower_start_in_flight: bool = false
var _brother_tower_sync: BrotherTowerBattleSync = null
var _viewer_victory_watchdog: Timer = null
var _viewer_watchdog_tick_in_flight: bool = false
var _viewer_wave_pending_watchdog: Timer = null
var _viewer_wave_pending_watchdog_in_flight: bool = false
var _viewer_wave_pending_sync_hint_at_ms: int = 0
var _brother_tower_waiting_reconnect_watchdog: Timer = null
var _brother_tower_waiting_reconnect_watchdog_in_flight: bool = false
var _brother_tower_wave_cleared_watchdog: Timer = null
var _brother_tower_wave_cleared_watchdog_in_flight: bool = false
var _brother_tower_wave_cleared_pending_wave: int = 0
var _brother_tower_wave_cleared_watchdog_retries: int = 0
var _brother_tower_victory_settle_in_flight: bool = false
var _brother_tower_session_poll_in_flight: bool = false
var _brother_tower_friendship_applied_session_id: int = 0
const VIEWER_VICTORY_SETTLE_MAX_WAIT: = 3.0
const VIEWER_VICTORY_WATCHDOG_IDLE_SEC: = 3.0
const VIEWER_VICTORY_WATCHDOG_NEAR_END_SEC: = 1.0
signal brother_tower_battle_started()
signal brother_tower_battle_ended(victory: bool)
signal brother_tower_wave_started(wave: int, total_waves: int)


var gameplay_runtime_config: Dictionary = {}

signal suit_dungeon_battle_started(level: int)
signal suit_dungeon_battle_ended(victory: bool, level: int)
signal suit_dungeon_wave_started(level: int, wave: int)

signal map_changed(map_name: String)
signal gold_changed(amount: int)
signal cultivation_changed(amount: int)
signal player_attr_display_changed()
signal yuanbao_changed(amount: int)
signal game_initialized
signal game_saved
signal game_loaded
signal player_profile_restored
signal battle_ended_ui(victory: bool)
signal tower_battle_started(floor: int)
signal world_boss_battle_started(boss_pet_id: String)
signal arena_battle_started(opponent_name: String)
signal cloud_save_uploaded(success: bool)

signal quit_sync_finished(detail: String)
signal cloud_save_downloaded(success: bool, save_data: Dictionary)
signal post_login_offline_rewards_ready(hours_f: float, exp: int, gold: int, pet_offline_exp: Dictionary, pet_gifts: int, is_vip: bool, level_change: Dictionary)
signal post_login_offline_claim_applied(success: bool)
signal daily_status_synced

var _offline_heartbeat_timer: float = 0.0
const OFFLINE_HEARTBEAT_INTERVAL: float = 8.0
var _brother_tower_hb_timer: float = 0.0
const BROTHER_TOWER_HEARTBEAT_INTERVAL: float = 5.0
var _broadcast_refresh_timer: float = 0.0
const BROADCAST_REFRESH_INTERVAL: float = 30.0
var _festival_runtime_refresh_timer: float = 0.0
const FESTIVAL_RUNTIME_CONFIG_REFRESH_INTERVAL: float = 180.0

const BATTLE_BATCH_SAVE_INTERVAL: float = 30.0
const BATTLE_FULL_SAVE_INTERVAL: float = 600.0

const CLOUD_UPLOAD_MIN_INTERVAL: float = 180.0
var _battle_save_timer: float = 0.0
var _battle_full_save_timer: float = 0.0
var _battle_progress_dirty: bool = false
var _field_battle_loot_pending: Dictionary = {}

var _field_battle_loot_stop_epoch: int = 0
var _field_battle_loot_discard_ids: Dictionary = {}
var _field_battle_loot_result_connected: bool = false
var _field_battle_pet_level_at_start: int = 0

const FIELD_EXP_SETTLEMENT_WINDOW_MS: = 2000
var _field_exp_window_until_ms: int = 0
var _field_exp_player_granted_in_window: bool = false
var _field_gang_bonus_logged_in_window: bool = false
var _field_newbie_exp_bonus_logged_in_window: bool = false
var _field_catchup_logged_in_window: bool = false
var _field_vip_exp_bonus_logged_in_window: bool = false
var _field_double_exp_bonus_logged_in_window: bool = false
var _field_fabao_exp_bonus_logged_in_window: bool = false
var _field_map_diff_exp_bonus_logged_in_window: bool = false
var _field_noble_exp_bonus_logged_in_window: bool = false
var _field_weekend_exp_bonus_logged_in_window: bool = false
var _field_exp_pet_granted_in_window: bool = false
var _field_exp_level_cap_player: int = 1
var _field_exp_level_cap_pet: int = 1

const FIELD_BATTLE_LOOT_BATCH_MAX_BATTLES: = 5
const FIELD_BATTLE_LOOT_BATCH_FLUSH_COUNT: = 4
const FIELD_BATTLE_LOOT_BATCH_IDLE_FLUSH_MS: = 3000
const FIELD_BATTLE_LOOT_BATCH_MAX_MONSTERS: = 12
const BATTLE_SPEED_THROTTLE_COOLDOWN_MS: = 60000
const FIELD_BATTLE_LOOT_LEGIT_MS_PER_BATTLE: = 2000

const FIELD_LOOT_AWAIT_NEXT_FIGHT_MS: = 12000
var _field_loot_hold_next_fight: bool = false
var _field_loot_hold_until_ms: int = 0
var _field_battle_loot_slice_anchor_pet: int = 0
var _field_battle_loot_slice_anchor_player: int = 0
var _field_battle_loot_slice_batch_budget: int = 1
var _field_battle_loot_batch: Dictionary = {}
var _battle_speed_throttle_cooldown_until_ms: int = 0
var _last_field_battle_loot_sent_ms: int = 0

var _pet_merge_block_ids: Dictionary = {}
var _pet_merge_block_until_ms: int = 0
var _last_cloud_upload_time: float = 0.0

var _cloud_upload_dispatched_this_save: bool = false

var _battle_start_block_until_ms: int = 0
const BATTLE_START_BLOCK_MIN_MS: int = 800
const BATTLE_START_BLOCK_CITY_SWITCH_MS: int = 1400
const BATTLE_START_BLOCK_ROSTER_REFRESH_MS: int = 1200

const QUIT_SYNC_SYNC_DONE: = "sync_done"
const QUIT_SYNC_LOCAL_ONLY: = "local_only"
const QUIT_SYNC_GATE_BLOCKED: = "gate_blocked"
const QUIT_SYNC_UPLOAD_FAIL: = "upload_fail"
const QUIT_SYNC_SAVE_FAIL: = "save_fail"


var _defer_rankings_next_upload: bool = false

var _force_compact_authority_next_upload: bool = false

var _omit_pets_next_upload: bool = false

var _suppress_general_cloud_upload_until_ms: int = 0

var _is_applying_cloud_save: bool = false

var _current_map_pending_cloud_sync: bool = false

var _active_pet_pending_cloud_sync: bool = false

var _suit_enhance_pending: Dictionary = {}
var _pet_roster_sync_wait_state: Dictionary = {}

var _pet_bag_op_pending_cloud_sync: bool = false

var _session_server_nickname: String = ""

var _cloud_sync_gate_passed: bool = false

var _post_login_offline_claim_running: bool = false
var _post_login_offline_claim_done: bool = false
# 一次登录只弹一次「离线奖励」：下载存档路径和主界面路径都会领离线收益，
# 两边都 emit 就会叠两个弹窗，这里做一次去重。
var _post_login_offline_rewards_emitted: bool = false
const POST_LOGIN_OFFLINE_UPLOAD_SUPPRESS_MS: int = 30000



var noble_level: int = 0
var noble_pet_damage_bonus: int = 0
var noble_exp_bonus: int = 0
var _noble_info_signal_connected: bool = false


var _martial_create_learn_done: bool = false
var _martial_create_learn_result: Dictionary = {}


const MARTIAL_CREATE_UI_WAIT_MS: = 30000
var _mcreate_flow_active: bool = false
var _mcreate_pending_view: bool = false
var _mcreate_secure_snapshot: Dictionary = {}
var _mcreate_countdown_end_ticks_msec: int = 0
var _mcreate_ui_runner_running: bool = false
var _mcreate_hall_panel_wr = null
var _martial_create_upload_ok: bool = false
var _martial_create_upload_finished: bool = false
var _martial_create_suppress_arts_changed_upload: bool = false

func _init():
	if instance == null:
		instance = self

func _exit_tree() -> void :
	if instance == self:
		instance = null


func initialize(skip_local_disk: bool = false) -> bool:
	if initialized:
		return true

	randomize()
	print("开始初始化游戏系统...")
	_load_broadcast_cursor()

	player = PlayerClass.new()
	add_child(player)

	pet_manager = PetManagerClass.new()
	add_child(pet_manager)

	pet_collection_manager = PetCollectionManagerClass.new()
	add_child(pet_collection_manager)
	pet_collection_manager.collection_updated.connect(_on_pet_collection_updated_for_save)

	pet_equipment_manager = PetEquipmentManagerClass.new()
	add_child(pet_equipment_manager)

	pet_soul_manager = PetSoulManagerClass.new()
	add_child(pet_soul_manager)

	battle_system = BattleSystemClass.new()
	add_child(battle_system)

	equipment_manager = EquipmentManagerClass.new()
	add_child(equipment_manager)
	fabao_manager = FabaoManagerClass.new()
	add_child(fabao_manager)

	suit_manager = SuitManagerClass.new()
	add_child(suit_manager)

	martial_arts_manager = MartialArtsManagerClass.new()
	add_child(martial_arts_manager)


	martial_arts_manager.martial_arts_changed.connect(_on_martial_arts_changed_for_save)
	martial_arts_manager.martial_art_equipped.connect(_on_martial_equip_layout_changed)
	martial_arts_manager.martial_art_unequipped.connect(_on_martial_equip_layout_changed)

	inventory_manager = InventoryManagerClass.new()
	add_child(inventory_manager)

	pet_skill_manager = PetSkillManagerClass.new()
	add_child(pet_skill_manager)

	martial_skill_manager = MartialSkillManagerClass.new()
	add_child(martial_skill_manager)

	crafting_manager = CraftingManagerClass.new()
	add_child(crafting_manager)
	crafting_manager.set_managers(inventory_manager, equipment_manager)

	chat_network = ChatNetwork.new()
	add_child(chat_network)
	chat_network.message_received.connect(_on_chat_message_received)
	chat_network.announcement_received.connect(_on_announcement_received)

	call_deferred("_deferred_start_chat_polling")

	quest_manager = QuestManagerClass.new()
	add_child(quest_manager)
	player.level_up.connect( func(new_level: int): quest_manager.on_level_up(new_level))
	player.realm_changed.connect( func(new_realm: String): quest_manager.on_realm_changed(new_realm))

	mail_manager = MailManagerClass.new()
	mail_manager.name = "MailManager"
	add_child(mail_manager)

	xianmo_system = XianMoSystemClass.new()
	xianmo_system.name = "XianMoSystem"
	add_child(xianmo_system)
	xianmo_system.set_game_manager(self)

	xianmo_event_processor = XianMoEventClass.new()
	xianmo_event_processor.name = "XianMoEventProcessor"
	add_child(xianmo_event_processor)
	xianmo_event_processor.set_managers(self, xianmo_system)

	xianmo_reward = XianMoRewardClass.new()
	xianmo_reward.name = "XianMoReward"
	add_child(xianmo_reward)
	xianmo_reward.set_managers(self, xianmo_system)

	xianmo_ranking = XianMoRankingClass.new()
	xianmo_ranking.name = "XianMoRanking"
	add_child(xianmo_ranking)
	xianmo_ranking.set_managers(self, xianmo_system)

	xianmo_shop = XianMoShopClass.new()
	xianmo_shop.name = "XianMoShop"
	add_child(xianmo_shop)
	xianmo_shop.set_managers(self, xianmo_system)

	xianmo_chest_manager = XianMoChestManagerClass.new()
	xianmo_chest_manager.name = "XianMoChestManager"
	add_child(xianmo_chest_manager)
	xianmo_chest_manager.set_game_manager(self)

	xianmo_battle_processor = XianMoBattleProcessorClass.new()
	xianmo_battle_processor.name = "XianMoBattleProcessor"
	add_child(xianmo_battle_processor)
	xianmo_battle_processor.set_managers(self, xianmo_system)

	title_manager = TitleManagerClass.new()
	title_manager.name = "TitleManager"
	add_child(title_manager)
	title_manager.set_game_manager(self)

	gang_manager = GangManagerClass.new()
	gang_manager.name = "GangManager"
	add_child(gang_manager)
	gang_manager.setup(self)
	if not gang_manager.kick_battle_ready.is_connected(_on_gang_kick_battle_ready):
		gang_manager.kick_battle_ready.connect(_on_gang_kick_battle_ready)
	if not gang_manager.siege_battle_ready.is_connected(_on_gang_siege_battle_ready):
		gang_manager.siege_battle_ready.connect(_on_gang_siege_battle_ready)

	pet_manager.pet_added.connect( func(pet): quest_manager.on_pet_captured(pet.element if pet else ""))


	pet_manager.pet_evolved.connect( func(_pet, _old_form, _new_form): quest_manager.on_pet_evolved())


	pet_manager.pet_merged.connect( func(_new_pet, _main_pet, _sub_pet, _result_type): quest_manager.on_pet_fused())

	if skip_local_disk:
		print("跳过本地磁盘存档加载，等待云存档应用")
	else:
		if has_save():
			print("发现存档，正在加载...")
			if load_game():
				print("存档加载成功！")
				if not player.recent_maps.has(current_map):
					player.add_recent_map(current_map)
				if quest_manager:
					quest_manager.check_capture_quest_completion()
			else:
				print("存档加载失败，创建新游戏...")
				pet_manager.bootstrap_starter_pet_if_needed()
				_init_new_player_resources()
		else:
			print("未发现存档，创建新游戏...")
			pet_manager.bootstrap_starter_pet_if_needed()
			_init_new_player_resources()
			if quest_manager:
				quest_manager.check_capture_quest_completion()


	if mail_manager and network:
		mail_manager.sync_mail_api_base(str(network.server_url))
	if chat_network and network:
		chat_network.sync_from_api_session(str(network.server_url))

	initialized = true
	game_initialized.emit()

	_init_bgm()

	print("游戏系统初始化完成！")
	return true

func _init_new_player_resources() -> void :
	const INITIAL_GOLD: int = 10000
	const INITIAL_YUANBAO: int = 100
	if player.gold == 0 and player.yuanbao_currency == 0:
		player.gold = INITIAL_GOLD
		player.yuanbao_currency = INITIAL_YUANBAO
		print("[GameManager] 新玩家资源初始化: 金币=%d, 元宝=%d" % [INITIAL_GOLD, INITIAL_YUANBAO])


func _init_bgm():
	_load_audio_settings_from_config()
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = linear_to_db(bgm_volume)
	bgm_player.autoplay = false
	add_child(bgm_player)

	play_bgm_normal()

func _load_audio_settings_from_config():
	var config = ConfigFile.new()
	if config.load("user://audio_settings.cfg") == OK:
		bgm_enabled = config.get_value("audio", "bgm_enabled", true)
		bgm_volume = config.get_value("audio", "bgm_volume", 0.5)
	if bgm_player and not bgm_enabled:
		stop_bgm()

func _save_audio_settings_to_config():
	var config = ConfigFile.new()
	config.set_value("audio", "bgm_enabled", bgm_enabled)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.save("user://audio_settings.cfg")

func play_bgm_normal():
	if current_bgm == "normal":
		return
	_load_and_play_bgm(BGM_NORMAL, "normal")

func play_bgm_battle():
	if current_bgm == "battle":
		return
	_load_and_play_bgm(BGM_BATTLE, "battle")


func play_bgm_pet_park():
	if current_bgm == "pet_park":
		return
	_load_and_play_bgm(BGM_PET_PARK, "pet_park")

func play_bgm_martial_hall():
	if current_bgm == "martial_hall":
		return
	_load_and_play_bgm(BGM_MARTIAL_HALL, "martial_hall")


func run_martial_hall_create_pressed_async(panel: Control, create_btn: Button, create_info: Label) -> void :
	if not martial_arts_manager or not player:
		return
	if panel == null or not is_instance_valid(panel):
		return
	var MartialHall = load("res://ui/city/martial_hall.gd")
	if martial_create_ui_pending_view():
		await MartialHall.on_view_martial_create_result(panel, create_btn, create_info, martial_arts_manager, player, self)
		return
	await MartialHall.on_create_btn_pressed(panel, create_btn, create_info, martial_arts_manager, player, self)

func martial_create_ui_flow_active() -> bool:
	return _mcreate_flow_active

func martial_create_ui_pending_view() -> bool:
	return _mcreate_pending_view

func get_martial_create_secure_snapshot() -> Dictionary:
	return _mcreate_secure_snapshot

func register_martial_hall_panel_for_create_ui(panel: Control) -> void :
	if panel != null and is_instance_valid(panel):
		_mcreate_hall_panel_wr = weakref(panel)

func _on_martial_arts_changed_for_save() -> void :
	if _mcreate_flow_active or _martial_create_suppress_arts_changed_upload:
		return
	call_deferred("save_game", false, "martial_arts_changed")

func _on_martial_equip_layout_changed(_art) -> void :
	if _mcreate_flow_active or _martial_create_suppress_arts_changed_upload:
		return
	save_martial_equip_to_cloud()

func is_martial_create_upload_finished() -> bool:
	return _martial_create_upload_finished

func is_martial_create_upload_ok() -> bool:
	return _martial_create_upload_ok

func martial_create_ui_flow_begin(realm: String) -> void :
	if _mcreate_flow_active:
		return
	_mcreate_flow_active = true
	_mcreate_pending_view = false
	_mcreate_secure_snapshot = create_secure_op_snapshot()
	_mcreate_countdown_end_ticks_msec = Time.get_ticks_msec() + MARTIAL_CREATE_UI_WAIT_MS
	_martial_create_upload_ok = false
	_martial_create_upload_finished = false
	_martial_create_suppress_arts_changed_upload = false
	martial_create_start_learn_parallel(realm)
	if not _mcreate_ui_runner_running:
		_mcreate_ui_runner_running = true
		_martial_create_ui_runner_loop()

func martial_create_ui_flow_clear() -> void :
	_mcreate_flow_active = false
	_mcreate_pending_view = false
	_mcreate_secure_snapshot = {}
	_martial_create_upload_ok = false
	_martial_create_upload_finished = false
	_martial_create_suppress_arts_changed_upload = false

func martial_create_ui_get_sync_state() -> Dictionary:
	return {
		"active": _mcreate_flow_active, 
		"pending_view": _mcreate_pending_view, 
		"countdown_end_ticks": _mcreate_countdown_end_ticks_msec, 
		"learn_ready": is_martial_create_learn_ready(), 
		"now_ticks": Time.get_ticks_msec(), 
	}

func _notify_martial_hall_create_ui_refresh() -> void :
	var p: Control = null
	if _mcreate_hall_panel_wr != null:
		p = _mcreate_hall_panel_wr.get_ref() as Control
	if not is_instance_valid(p):
		return
	var MartialHall = load("res://ui/city/martial_hall.gd")
	MartialHall.sync_martial_create_controls_from_game_manager(p, self)

func refresh_martial_hall_panel_if_open() -> void :
	var p: Control = null
	if _mcreate_hall_panel_wr != null:
		p = _mcreate_hall_panel_wr.get_ref() as Control
	if not is_instance_valid(p):
		return
	var MartialHall = load("res://ui/city/martial_hall.gd")
	MartialHall._refresh_martial_view_fullscreen(p)

func align_cloud_save_timestamp_from_player_dict(pd: Variant) -> void :
	if pd == null or not pd is Dictionary:
		return
	var pts: = float((pd as Dictionary).get("timestamp", 0))
	if pts > 0:
		_last_local_save_timestamp = max(_last_local_save_timestamp, pts)

func _martial_create_ui_runner_loop() -> void :
	while _mcreate_flow_active:
		var now = Time.get_ticks_msec()
		if now >= _mcreate_countdown_end_ticks_msec and is_martial_create_learn_ready() and not _mcreate_pending_view:
			_mcreate_pending_view = true
		_notify_martial_hall_create_ui_refresh()
		if not _mcreate_flow_active:
			break
		now = Time.get_ticks_msec()
		if now < _mcreate_countdown_end_ticks_msec:
			await get_tree().create_timer(1.0).timeout
		elif not is_martial_create_learn_ready():
			await get_tree().process_frame
		else:
			await get_tree().create_timer(0.25).timeout
	_mcreate_ui_runner_running = false

func martial_create_start_learn_parallel(realm: String) -> void :
	_martial_create_learn_done = false
	_martial_create_learn_result = {}
	call_deferred("_martial_create_learn_parallel_run", realm)

func _martial_create_learn_parallel_run(realm: String) -> void :
	if not martial_arts_manager:
		_martial_create_learn_result = {"success": false, "message": "武功系统未初始化", "art": null, "poem": ""}
		_martial_create_learn_done = true
		return
	_martial_create_learn_result = await martial_arts_manager.learn_martial_art(realm)
	_martial_create_learn_done = true
	_martial_create_run_background_upload()

func _martial_create_run_background_upload() -> void :

	if not _mcreate_flow_active:
		return
	_martial_create_suppress_arts_changed_upload = true
	_martial_create_upload_finished = true
	_martial_create_upload_ok = true
	_martial_create_suppress_arts_changed_upload = false

	save_game(false)

func is_martial_create_learn_ready() -> bool:
	return _martial_create_learn_done

func get_martial_create_learn_result() -> Dictionary:
	return _martial_create_learn_result

func play_bgm_crafting_hall():
	if current_bgm == "crafting_hall":
		return
	_load_and_play_bgm(BGM_QIANKUN_HALL, "crafting_hall")

func play_bgm_qiankun_hall():
	if current_bgm == "qiankun_hall":
		return
	_load_and_play_bgm(BGM_QIANKUN_HALL, "qiankun_hall")

func play_bgm_forge_hall():
	if current_bgm == "forge_hall":
		return
	_load_and_play_bgm(BGM_FORGE_HALL, "forge_hall")

func play_bgm_ranking_hall():
	if current_bgm == "ranking_hall":
		return
	_load_and_play_bgm(BGM_RANKING_HALL, "ranking_hall")

func play_bgm_tower():
	if current_bgm == "tower":
		return
	_load_and_play_bgm(BGM_TOWER, "tower")

func play_bgm_suit_dungeon():
	if current_bgm == "suit_dungeon":
		return
	_load_and_play_bgm(BGM_SUIT_DUNGEON, "suit_dungeon")

func play_bgm_warehouse():
	if current_bgm == "warehouse":
		return
	_load_and_play_bgm(BGM_WAREHOUSE, "warehouse")

func play_bgm_settings():
	if current_bgm == "settings":
		return
	_load_and_play_bgm(BGM_SETTINGS, "settings")

func play_bgm_mail():
	if current_bgm == "mail":
		return
	_load_and_play_bgm(BGM_MAIL, "mail")

func play_bgm_quest():
	if current_bgm == "quest":
		return
	_load_and_play_bgm(BGM_QUEST, "quest")

func play_bgm_xianmo():
	if current_bgm == "xianmo":
		return
	_load_and_play_bgm(BGM_XIANMO, "xianmo")

func play_bgm_shop():
	if current_bgm == "shop":
		return
	_load_and_play_bgm(BGM_SHOP, "shop")

func play_bgm_lucky_draw():
	if current_bgm == "lucky_draw":
		return
	_load_and_play_bgm(BGM_LUCKY_DRAW, "lucky_draw")

func _load_and_play_bgm(path: String, bgm_type: String):
	if not ResourceLoader.exists(path):
		print("背景音乐文件不存在: ", path)
		return

	var stream = load(path)
	if not stream:
		print("背景音乐加载失败: ", path)
		return

	bgm_player.stream = stream
	bgm_player.stream.loop = true
	current_bgm = bgm_type

	if bgm_enabled:
		bgm_player.play()
	print("背景音乐切换为: ", bgm_type)

func play_bgm():
	if bgm_player and bgm_player.stream:
		if not bgm_player.playing and bgm_enabled:
			bgm_player.play()

func stop_bgm():
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func set_bgm_volume(volume: float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume)
	_save_audio_settings_to_config()

func toggle_bgm():
	bgm_enabled = not bgm_enabled
	_save_audio_settings_to_config()
	if bgm_enabled:
		play_bgm()
	else:
		stop_bgm()
	return bgm_enabled

func _process(delta):

	var logged_in_now: bool = network != null and network.is_logged_in()
	is_logged_in = logged_in_now
	if logged_in_now:
		_offline_heartbeat_timer += delta
		if _offline_heartbeat_timer >= OFFLINE_HEARTBEAT_INTERVAL:
			_offline_heartbeat_timer = 0.0
			network.send_offline_heartbeat()
		_brother_tower_hb_timer += delta
		if _brother_tower_hb_timer >= BROTHER_TOWER_HEARTBEAT_INTERVAL:
			_brother_tower_hb_timer = 0.0
			_send_brother_tower_heartbeat_if_needed()

		_broadcast_refresh_timer += delta
		if _broadcast_refresh_timer >= BROADCAST_REFRESH_INTERVAL:
			_broadcast_refresh_timer = 0.0
			load_server_broadcasts()

		_festival_runtime_refresh_timer += delta
		if _festival_runtime_refresh_timer >= FESTIVAL_RUNTIME_CONFIG_REFRESH_INTERVAL:
			_festival_runtime_refresh_timer = 0.0
			_refresh_festival_runtime_config_from_server()
	else:
		_festival_runtime_refresh_timer = 0.0

	if _battle_progress_dirty:
		_battle_save_timer += delta
		_battle_full_save_timer += delta
		if _battle_save_timer >= BATTLE_BATCH_SAVE_INTERVAL:
			_battle_save_timer = 0.0
			flush_battle_progress_persist()
		elif _battle_full_save_timer >= BATTLE_FULL_SAVE_INTERVAL:
			_battle_full_save_timer = 0.0
			flush_battle_progress_persist()
	_process_field_battle_loot_batch_idle_flush()
	_process_field_loot_await_timeout()

func _send_brother_tower_heartbeat_if_needed() -> void :
	if network == null or not network.is_logged_in():
		return
	if is_brother_tower_battle and brother_tower_session_id > 0:
		network.brother_tower_heartbeat(0, brother_tower_session_id)
		return
	if is_brother_tower_battle:
		return
	var lobby_room_id: int = _bt_ui().get_my_room_id()
	if lobby_room_id > 0:
		network.brother_tower_heartbeat(lobby_room_id, 0)


func get_authoritative_unix_time(allow_local_fallback: bool = false, max_server_time_age_seconds: float = 300.0) -> int:
	if network and network.is_logged_in():
		if network.has_method("has_server_time_sync") and network.has_method("get_server_time_unix"):
			var has_sync: = bool(network.has_server_time_sync(max_server_time_age_seconds))
			if has_sync:
				var server_now: = int(network.get_server_time_unix())
				if server_now > 0:
					return server_now
	if allow_local_fallback:
		return int(Time.get_unix_time_from_system())
	return -1


func _broadcast_fingerprint(text: String) -> String:
	return str(text).strip_edges()

func _prune_shown_broadcast_fingerprints(now_ts: float) -> void :
	if _shown_broadcast_fingerprints.is_empty():
		return
	var stale: Array[String] = []
	for fp in _shown_broadcast_fingerprints.keys():
		if now_ts - float(_shown_broadcast_fingerprints.get(fp, 0.0)) > BROADCAST_SHOWN_DEDUP_SEC:
			stale.append(str(fp))
	for fp in stale:
		_shown_broadcast_fingerprints.erase(fp)

func _mark_broadcast_shown(text: String) -> bool:
	var fp: = _broadcast_fingerprint(text)
	if fp.is_empty():
		return false
	var now_ts: = Time.get_unix_time_from_system()
	_prune_shown_broadcast_fingerprints(now_ts)
	if _shown_broadcast_fingerprints.has(fp):
		return false
	_shown_broadcast_fingerprints[fp] = now_ts
	if _shown_broadcast_fingerprints.size() > 500:
		_shown_broadcast_fingerprints.clear()
		_shown_broadcast_fingerprints[fp] = now_ts
	return true

func broadcast_announcement(message: String):
	if _mark_broadcast_shown(message):
		world_announcement.emit(message)

func broadcast_event(event_type: String, player_name: String, details: Dictionary = {}, custom_message: String = ""):
	world_event.emit(event_type, player_name, details)

	var message = custom_message
	if message.is_empty():
		match event_type:
			"ascend":
				var new_realm = details.get("new_realm", "未知境界")
				message = "🎉 恭喜玩家【%s】成功飞升至【%s】！" % [player_name, new_realm]
			"reincarnate":
				message = "🔄 恭喜玩家【%s】完成转世重修！" % player_name
			"pet_reincarnation":
				var rei_pet_name = details.get("pet_name", "宠物")
				var rei_count = int(details.get("reincarnation_count", 1))
				var rei_bonus_pct = int(details.get("bonus_pct", 0))
				var rei_eff_max = int(details.get("effective_max_level", 0))
				message = "☯️ 恭喜【%s】的【%s】历经轮回，成功完成第 %d 次转生！属性加成 +%d%% ｜ 等级上限 %d 级" % [player_name, rei_pet_name, rei_count, rei_bonus_pct, rei_eff_max]
			"pet_evolve":
				var pet_name = details.get("pet_name", "宠物")
				var new_form = details.get("new_form", "新形态")

				var mutated: = bool(details.get("mutated", false))
				var mut_count: = clampi(int(details.get("mutation_count", details.get("mutationCount", 0))), 0, 2)
				if mutated and mut_count > 0 and not str(pet_name).contains("[变异"):
					pet_name = InventoryManager.format_pet_name_with_mutation(str(pet_name), mut_count)
				if mutated:
					message = "🌟 恭喜玩家【%s】的宠物【%s】变异进化为【%s】！" % [player_name, pet_name, new_form]
				else:
					message = "🌟 恭喜玩家【%s】的宠物【%s】进化为【%s】！" % [player_name, pet_name, new_form]
			"pet_fusion":
				var pet_name = details.get("pet_name", "宠物")
				message = "✨ 恭喜玩家【%s】的宠物【%s】完成幻化！" % [player_name, pet_name]
			"craft_epic":
				var item_name = details.get("item_name", "装备")
				message = "⚔️ 恭喜玩家【%s】打造出极品装备【%s】！" % [player_name, item_name]
			"martial_create":
				var martial_name = details.get("martial_name", "武功")
				message = "📜 恭喜玩家【%s】自创武功【%s】！" % [player_name, martial_name]
			"tower_clear":
				var floor = details.get("floor", 1)
				message = "🏆 恭喜玩家【%s】通关天关第%d层！" % [player_name, floor]
			"tower_gift_pet_egg":
				message = "🎊 恭喜玩家【%s】打开天关锦囊，幸运获得【五阶宠物蛋】！" % player_name
			"tower_gift_egg":
				var floor = details.get("floor", 100)
				message = "🥚 恭喜【%s】打开%d关礼包，获得【五阶宠物蛋】！" % [player_name, floor]
			"tower_gift_element_egg":
				var floor = details.get("floor", 100)
				var egg = details.get("egg", "属性宠物蛋")
				message = "🌟 恭喜【%s】打开%d关礼包，获得稀有的【%s】！" % [player_name, floor, egg]
			"suit_dungeon_clear":
				var level = details.get("level", 1)
				message = "🛡️ 恭喜玩家【%s】通关套装副本第%d层！" % [player_name, level]
			"suit_obtain":
				var suit_name = details.get("suit_name", "套装")
				message = "👑 恭喜玩家【%s】获得套装【%s】！" % [player_name, suit_name]
			"fe_dungeon_clear":
				var element = details.get("element", "")
				var difficulty = details.get("difficulty", "")
				message = "☯️ 恭喜【%s】历经苦战，通过%s难度五行副本(%s)！" % [player_name, difficulty, element]
			"fe_dungeon_fail":
				var element = details.get("element", "")
				var difficulty = details.get("difficulty", "")
				message = "💪 【%s】挑战%s难度五行副本(%s)失败，但勇气可嘉，下次再战！" % [player_name, difficulty, element]
			"pet_egg_high_growth":
				var pet_name = details.get("pet_name", "宠物")
				var growth = float(details.get("growth", 0.0))
				var egg_src: = str(details.get("egg_source", "")).strip_edges()
				var element: = str(details.get("element", "")).strip_edges()
				var batch_total: = int(details.get("batch_total", 0))
				if batch_total > 1:
					if not egg_src.is_empty():
						message = "🎁 恭喜【%s】批量使用【%s】获得：%s 等%d只！" % [player_name, egg_src, pet_name, batch_total]
					else:
						message = "🎁 恭喜【%s】获得：%s 等%d只！" % [player_name, pet_name, batch_total]
				elif not egg_src.is_empty():
					message = "🎁 恭喜【%s】打开【%s】获得宠物【%s】（成长%.2f）！" % [player_name, egg_src, pet_name, growth]
				elif not element.is_empty():
					message = "🥚 恭喜【%s】从%s属性宠物蛋中孵化出【%s】（成长%.2f）！" % [player_name, element, pet_name, growth]
				else:
					message = "🎁 恭喜【%s】获得宠物【%s】（成长%.2f）！" % [player_name, pet_name, growth]
			"tower_gift_100":
				var floor = details.get("floor", 100)
				var pet_name = details.get("pet_name", "宠物")
				var growth = details.get("growth", 0.0)
				message = "🎁 恭喜玩家【%s】打开%d关礼包，获得宠物【%s】（成长%.2f）！" % [player_name, floor, pet_name, growth]
			"tower_gift_pet":
				var floor = details.get("floor", 100)
				var pet_name = details.get("pet_name", "宠物")
				var growth = details.get("growth", 0.0)
				message = "🎁 恭喜【%s】打开%d关礼包，获得宠物【%s】（成长%.2f）！" % [player_name, floor, pet_name, growth]
			"xianmo_divine_pet":
				message = "🐉【%s】在仙魔界捕获了一只神兽！" % player_name
			"xianmo_mutant_pet":
				message = "🌀【%s】在仙魔界捕获了一只变异灵兽！" % player_name
			"xianmo_gold_chest":
				message = "🏆【%s】在仙魔界发现了天宫遗址，获得黄金匣！" % player_name
			"xianmo_pet_master":
				message = "💕【%s】在仙魔界获得灵兽认主！" % player_name
			"treasure_map_jackpot":
				message = "💰【%s】打开藏宝图获得了10亿金币！" % player_name
			"xianmo_week_settled":
				message = ""
			_:
				message = ""

	if not message.is_empty():
		if _mark_broadcast_shown(message):
			world_announcement.emit(message)
		if chat_network:
			var title = ""
			if player and player.player_name == player_name:
				title = player.get_active_title_name()
			chat_network.send_world_message(player_name, message, event_type, false, title)
		if network and network.is_logged_in():
			send_server_broadcast(event_type, message, details)


func _send_drop_items_to_mail(title: String, items: Array, gold: int = 0):
	if MailManager.instance == null:
		print("[GameManager] MailManager不存在，无法发送邮件")
		return

	var mail_items = []
	for item in items:
		if item.get("type", "") == "sealed_suit":
			mail_items.append({
				"name": item.get("name", ""), 
				"count": item.get("count", 1), 
				"type": "sealed_suit", 
				"data": item.get("data", {})
			})
		else:
			mail_items.append({
				"name": item.get("name", ""), 
				"count": item.get("count", 1)
			})

	MailManager.instance.send_item_drop_mail(title, mail_items, gold)

func _deferred_start_chat_polling() -> void :
	if chat_network:
		chat_network.start_polling()

func _on_chat_message_received(msg_data: Dictionary):
	chat_message_received.emit(msg_data)

func _on_announcement_received(announcement_data: Dictionary):
	var title = announcement_data.get("title", "系统公告")
	var content = announcement_data.get("content", "")
	var msg_data = {
		"sender": title, 
		"message": content, 
		"event_type": "announcement"
	}
	chat_message_received.emit(msg_data)


func change_map(map_name: String) -> bool:
	if not GameData.MAPS_DATA.has(map_name):
		return false

	current_map = map_name
	player.add_recent_map(map_name)
	_flush_field_battle_loot_batch()
	block_battle_start_temporarily(BATTLE_START_BLOCK_MIN_MS, "change_map")
	map_changed.emit(map_name)
	if network != null and network.is_logged_in() and _cloud_sync_gate_passed:
		_current_map_pending_cloud_sync = true
		save_game(false)
		_request_set_current_map_authority(map_name)
	else:
		save_game(false)
	return true

func _request_set_current_map_authority(map_name: String) -> void :
	if network == null or not network.is_logged_in():
		return
	var op_id: = "set_map_%s_%d_%d" % [map_name, Time.get_unix_time_from_system(), randi()]
	var on_ok: = func(data: Dictionary):
		if data.has("saveData") and data.get("saveData") is Dictionary:
			apply_cloud_save(data.get("saveData"), {"skip_deferred_cloud_save": true})
		elif data.has("saveRevision"):
			_set_cloud_save_revision(int(data.get("saveRevision", -1)))
		_current_map_pending_cloud_sync = false
		save_game(false)
	var on_fail: = func(err: String):
		push_warning("[GameManager] set-current-map 失败，回退 compact 上传: %s" % err)
		save_local_and_force_cloud_upload_authority_compact_with_reason("change_map")
	if not network.set_current_map_success.is_connected(on_ok):
		network.set_current_map_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not network.set_current_map_failed.is_connected(on_fail):
		network.set_current_map_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.set_current_map(map_name, op_id)


func request_capture_settings_authority(auto_enabled: bool, min_growth: float) -> Dictionary:
	var out: = {"ok": false, "error": "未登录"}
	if network == null or not network.is_logged_in():
		return out
	if not _cloud_sync_gate_passed:
		out["error"] = "云同步未就绪，请稍后再试"
		return out
	var op_id: = "capture_settings_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var done: = {"finished": false, "ok": false, "error": "", "data": {}}
	var on_ok: = func(data: Dictionary):
		done["finished"] = true
		done["ok"] = true
		done["data"] = data if data is Dictionary else {}
	var on_fail: = func(err: String):
		done["finished"] = true
		done["ok"] = false
		done["error"] = str(err)
	if not network.capture_settings_success.is_connected(on_ok):
		network.capture_settings_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not network.capture_settings_failed.is_connected(on_fail):
		network.capture_settings_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.set_capture_settings(auto_enabled, min_growth, op_id)
	var start_ms: = Time.get_ticks_msec()
	while not bool(done["finished"]):
		if (Time.get_ticks_msec() - start_ms) > 15000:
			done["finished"] = true
			done["ok"] = false
			done["error"] = "请求超时，请稍后重试"
			break
		await get_tree().process_frame
	if bool(done["ok"]):
		var data: Dictionary = done["data"] if done["data"] is Dictionary else {}
		if data.has("saveData") and data.get("saveData") is Dictionary:
			apply_cloud_save(data.get("saveData"), {"skip_deferred_cloud_save": true})
		var result: Variant = data.get("result", {})
		if result is Dictionary:
			if result.has("auto_capture_enabled"):
				auto_capture_enabled = bool(result.get("auto_capture_enabled"))
			if result.has("min_growth_threshold"):
				min_growth_threshold = float(result.get("min_growth_threshold"))
		else:
			auto_capture_enabled = auto_enabled
			min_growth_threshold = min_growth
		if data.has("saveRevision"):
			_set_cloud_save_revision(int(data.get("saveRevision", -1)))
		save_game(false)
		return {"ok": true, "error": ""}
	return {"ok": false, "error": str(done.get("error", "保存失败"))}


func request_pet_lock_authority(pet, locked: bool) -> Dictionary:
	var out: = {"ok": false, "error": "未登录"}
	if pet == null:
		return {"ok": false, "error": "未找到该宠物"}
	if network == null or not network.is_logged_in():
		return out
	if not _cloud_sync_gate_passed:
		return {"ok": false, "error": "云同步未就绪，请稍后再试"}
	if pet_manager == null:
		return {"ok": false, "error": "系统未就绪"}
	var pet_id: = str(pet.id).strip_edges()
	if pet_id.is_empty():
		return {"ok": false, "error": "宠物ID无效"}
	var op_id: = "pet_lock_%s_%d_%d" % [pet_id, Time.get_unix_time_from_system(), randi()]
	var done: = {"finished": false, "ok": false, "error": "", "data": {}}
	var on_ok: = func(data: Dictionary):
		done["finished"] = true
		done["ok"] = true
		done["data"] = data if data is Dictionary else {}
	var on_fail: = func(err: String):
		done["finished"] = true
		done["ok"] = false
		done["error"] = str(err)
	if not network.pet_lock_success.is_connected(on_ok):
		network.pet_lock_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not network.pet_lock_failed.is_connected(on_fail):
		network.pet_lock_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.pet_lock(pet_id, locked, op_id)
	var start_ms: = Time.get_ticks_msec()
	while not bool(done["finished"]):
		if (Time.get_ticks_msec() - start_ms) > 15000:
			done["finished"] = true
			done["ok"] = false
			done["error"] = "请求超时，请稍后重试"
			break
		await get_tree().process_frame
	if bool(done["ok"]):
		var data: Dictionary = done["data"] if done["data"] is Dictionary else {}
		if data.has("saveData") and data.get("saveData") is Dictionary:
			apply_cloud_save(data.get("saveData"), {"skip_deferred_cloud_save": true, "pets_authoritative": true})

		_set_live_pet_locked_by_id(pet_id, locked)
		if pet != null:
			pet.locked = locked
		if data.has("saveRevision"):
			_set_cloud_save_revision(int(data.get("saveRevision", -1)))
		save_game(false)
		return {"ok": true, "error": ""}
	return {"ok": false, "error": str(done.get("error", "锁定同步失败"))}

func get_current_map_data() -> Dictionary:
	return GameData.MAPS_DATA.get(current_map, {})

func get_available_maps() -> Array:

	return GameData.MAPS_DATA.keys()


func start_battle() -> bool:

	if _field_auto_retry_until_ms > 0 and Time.get_ticks_msec() < _field_auto_retry_until_ms:
		return false

	if is_tower_battle or is_tower_settling or is_five_elements_battle or is_brother_tower_battle or is_brother_tower_settling:
		return false
	if is_atlas_dungeon_battle or is_atlas_dungeon_settling or is_suit_dungeon_battle or is_suit_dungeon_settling:
		return false
	if is_world_boss_battle:
		return false
	if is_world_boss_battle:
		return false

	if network != null and not network.is_logged_in():
		return false

	if in_battle and battle_system.current_state != battle_system.BattleState.IN_PROGRESS:
		if is_atlas_dungeon_battle or is_atlas_dungeon_settling or is_suit_dungeon_battle or is_suit_dungeon_settling or is_five_elements_battle or is_fe_settling or is_tower_battle or is_tower_settling or is_brother_tower_battle or is_brother_tower_settling:
			return false
		push_warning("检测到战斗状态不一致，强制重置")
		in_battle = false

	if in_battle:
		return false
	if is_battle_start_temporarily_blocked():
		return false

	var pet_guard: = ensure_active_pet_ready_for_battle()
	if not bool(pet_guard.get("ok", false)):
		block_battle_start_temporarily(BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "normal_pet_guard_not_ok")
		return false
	if bool(pet_guard.get("has_pets", false)) and pet_guard.get("pet", null) == null:
		block_battle_start_temporarily(BATTLE_START_BLOCK_ROSTER_REFRESH_MS, "normal_pet_guard_missing_pet")
		return false

	var map_data = get_current_map_data()
	if map_data.is_empty():
		return false


	if _wild_replay_busy:
		return false
	if _last_wild_run_sent_ms > 0 and Time.get_ticks_msec() - _last_wild_run_sent_ms < FIELD_WILD_RUN_MIN_GAP_MS:
		var main_ui: = _find_main_ui_node()
		if main_ui and is_auto_battle_enabled():
			var until_ms: = _last_wild_run_sent_ms + FIELD_WILD_RUN_MIN_GAP_MS
			var current_deadline: = int(main_ui.get("_battle_cooldown_deadline_ms"))
			if current_deadline <= 0 or current_deadline > until_ms:
				main_ui.set("_battle_cooldown_deadline_ms", until_ms)
		return false
	if battle_system:
		battle_system.replay_log_only = true
		battle_system.drive_by_execute_turn = false
	_wild_replay_busy = true
	in_battle = true
	_start_wild_replay_battle_async()
	return true


func wait_economy(request_type: String, emit_request: Callable, _request_id: String = "", timeout_ms: int = -1) -> Dictionary:
	var slot: = {"done": false, "ok": false, "data": {}, "err": ""}
	var cb = func(_rid: String, t: String, success: bool, d: Dictionary, e: String) -> void :
		if t != request_type:
			return
		if bool(slot.get("done", false)):
			return
		call_deferred("_complete_economy_wait_slot", slot, success, d, e)

	if network == null:
		return {"ok": false, "data": {}, "err": "no_network"}
	network.economy_result.connect(cb)
	emit_request.call()
	var wait_ms: int = 45000
	if timeout_ms > 0:
		wait_ms = timeout_ms
	elif request_type == "economy_battle_loot":
		wait_ms = network.get_economy_battle_loot_wait_deadline_ms()
	elif request_type == "economy_tower_clear":

		wait_ms = network.get_economy_tower_clear_wait_deadline_ms()
	elif request_type == "fe_dungeon_start" or request_type == "fe_dungeon_clear":
		wait_ms = network.get_fe_dungeon_wait_deadline_ms()
	elif request_type == "pet_grant_starter" or request_type == "atlas_dungeon_finish":

		wait_ms = 125000
	var deadline_ms: int = Time.get_ticks_msec() + wait_ms
	while not bool(slot.get("done", false)) and Time.get_ticks_msec() < deadline_ms:
		await get_tree().process_frame
	if network.economy_result.is_connected(cb):
		network.economy_result.disconnect(cb)
	if not bool(slot.get("done", false)):
		var timeout_hint: = "等待经济结算超时（服务器无响应或网络极差）"
		if request_type == "economy_battle_loot":
			timeout_hint = "等待经济结算超时（已等待约 %.0f 秒，仍无应答）" % (float(wait_ms) / 1000.0)
		return {"ok": false, "data": {}, "err": timeout_hint}
	var slot_ok: = bool(slot.get("ok", false))
	var slot_data: Dictionary = slot.get("data", {}) if slot.get("data") is Dictionary else {}
	var slot_err: = str(slot.get("err", ""))
	if slot_err.is_empty() and not slot_ok:
		return {"ok": slot_ok, "data": slot_data, "err": "经济结算失败"}
	return {"ok": slot_ok, "data": slot_data, "err": slot_err}

func _bootstrap_starter_pet_async() -> void :
	if pet_manager == null:
		return
	if pet_manager.pets.size() > 0 or pet_manager.pet_bag.size() > 0:
		return
	if network == null or not network.is_logged_in():
		pet_manager.create_initial_pet()
		return
	var op_id: = "starter_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var er: Dictionary = await wait_economy("pet_grant_starter", func():
		network.pet_grant_starter(op_id)
	, op_id)
	if bool(er.get("ok", false)):
		var data_var: Variant = er.get("data", {})
		if data_var is Dictionary:
			var data: Dictionary = data_var
			var save_var: Variant = data.get("saveData", null)
			if save_var is Dictionary and not (save_var as Dictionary).is_empty():
				apply_cloud_save(save_var, {"pets_authoritative": true})
				return
	if pet_manager.pets.size() == 0 and pet_manager.pet_bag.size() == 0:
		pet_manager.create_initial_pet()

func _battle_pet_exp_with_player_multiplier(base_exp: int) -> int:
	if base_exp <= 0:
		return 0
	var mult: float = 1.0
	if player != null and player.has_method("get_total_exp_multiplier"):
		mult = float(player.get_total_exp_multiplier(-1, true))
	return int(round(float(base_exp) * mult))


func wait_treasure_token_validation(tokens: Array) -> Dictionary:
	if network == null:
		return {"ok": false, "data": {}, "err": "网络未初始化"}
	# lambda 按值捕获局部变量：done/ok/data/err 必须放 Dictionary，否则闭包里改了外面读不到，
	# 每次都要等满超时才返回（表现为「藏宝匣校验超时」）。
	var st: = {"done": false, "ok": false, "data": {}, "err": ""}
	var on_ok: = func(d: Dictionary):
		st.ok = true
		st.data = d
		st.done = true
	var on_fail: = func(e: String):
		st.ok = false
		st.err = e
		st.done = true
	network.treasure_tokens_validated.connect(on_ok, CONNECT_ONE_SHOT)
	network.treasure_tokens_validate_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.treasure_validate_tokens(tokens)
	var deadline_ms: int = Time.get_ticks_msec() + 22000
	while not bool(st.done) and Time.get_ticks_msec() < deadline_ms and is_inside_tree():
		await get_tree().process_frame
	if network.treasure_tokens_validated.is_connected(on_ok):
		network.treasure_tokens_validated.disconnect(on_ok)
	if network.treasure_tokens_validate_failed.is_connected(on_fail):
		network.treasure_tokens_validate_failed.disconnect(on_fail)
	if not bool(st.done):
		return {"ok": false, "data": {}, "err": "藏宝匣状态校验超时"}
	if not bool(st.ok):
		return {"ok": false, "data": {}, "err": str(st.err) if not str(st.err).is_empty() else "校验失败"}
	return {"ok": true, "data": st.data}

func _reconcile_treasure_chests_after_cloud_apply() -> void :
	if network == null or not network.is_logged_in() or inventory_manager == null:
		return
	var rs: Dictionary = await inventory_manager.reconcile_treasure_chests_with_server(self)
	if bool(rs.get("ok", false)) and int(rs.get("removed", 0)) > 0:
		print("[TreasureSync] 已自动清理本地无效藏宝匣条目 count=%d" % int(rs.get("removed", 0)))
		save_game(true)


func wait_treasure_chest_open(token: String, operation_id: String) -> Dictionary:
	if token.strip_edges().is_empty():
		return {"ok": false, "data": {}, "err": "宝箱数据异常"}
	if network == null:
		return {"ok": false, "data": {}, "err": "网络未初始化"}
	var st: = {"done": false, "ok": false, "data": {}, "err": ""}
	var on_ok: = func(d: Dictionary):
		st.ok = true
		st.data = d
		st.done = true
	var on_fail: = func(e: String):
		st.ok = false
		st.err = e
		st.done = true
	network.treasure_open_success.connect(on_ok, CONNECT_ONE_SHOT)
	network.treasure_open_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.treasure_open(token.strip_edges(), operation_id)
	var deadline_ms: int = Time.get_ticks_msec() + 12000
	while not bool(st.done) and Time.get_ticks_msec() < deadline_ms and is_inside_tree():
		await get_tree().process_frame
	if network.treasure_open_success.is_connected(on_ok):
		network.treasure_open_success.disconnect(on_ok)
	if network.treasure_open_failed.is_connected(on_fail):
		network.treasure_open_failed.disconnect(on_fail)
	if not bool(st.done):
		var fallback_timeout: Dictionary = await _fallback_treasure_open_state_by_token(token.strip_edges())
		if bool(fallback_timeout.get("ok", false)):
			return fallback_timeout
		return {
			"ok": true, 
			"data": {
				"success": true, 
				"pending": true, 
				"message": "开奖处理中，奖励将自动到账"
			}
		}
	if not bool(st.ok):
		var fallback_fail: Dictionary = await _fallback_treasure_open_state_by_token(token.strip_edges())
		if bool(fallback_fail.get("ok", false)):
			return fallback_fail
		return {"ok": false, "data": {}, "err": str(st.err) if not str(st.err).is_empty() else "开启失败"}
	return {"ok": true, "data": st.data}

func _fallback_treasure_open_state_by_token(token: String) -> Dictionary:
	if token.is_empty():
		return {"ok": false, "data": {}, "err": "宝箱数据异常"}

	const MAX_VALIDATE_ATTEMPTS: = 1
	const RETRY_INTERVAL_SEC: = 0.2
	var last_err: = "开启失败"
	for i in range(MAX_VALIDATE_ATTEMPTS):
		var vr: Dictionary = await wait_treasure_token_validation([token])
		if bool(vr.get("ok", false)):
			var payload: Dictionary = vr.get("data", {}) if vr.get("data") is Dictionary else {}
			var opened_set: = {}
			for tk in payload.get("openedTokens", []):
				opened_set[str(tk).strip_edges()] = true
			if opened_set.has(token):
				return {
					"ok": true, 
					"data": {
						"success": true, 
						"alreadyOpened": true, 
						"message": "藏宝匣已开启（超时后已与服务器对账）", 
						"token": token
					}
				}
			last_err = "服务器处理中，请稍后查看背包同步结果"
		else:
			last_err = str(vr.get("err", "校验失败"))
		if i < MAX_VALIDATE_ATTEMPTS - 1 and is_inside_tree():
			await get_tree().create_timer(RETRY_INTERVAL_SEC).timeout
	return {"ok": false, "data": {}, "err": last_err}

func _complete_economy_wait_slot(slot: Dictionary, success: bool, data: Dictionary, error_msg: String) -> void :
	if bool(slot.get("done", false)):
		return
	slot["ok"] = success
	slot["data"] = data
	slot["err"] = error_msg
	slot["done"] = true


func _find_pet_dict_in_save_data(save_data: Dictionary, instance_id: String) -> Dictionary:
	var pid: = str(instance_id).strip_edges()
	if pid.is_empty() or save_data.is_empty():
		return {}
	var raw: Variant = save_data.get("petsData", null)
	var lists: Array = []
	if raw is Dictionary:
		var pets_arr: Variant = raw.get("pets", [])
		var bag_arr: Variant = raw.get("pet_bag", [])
		if pets_arr is Array:
			lists.append(pets_arr)
		if bag_arr is Array:
			lists.append(bag_arr)
	elif raw is Array:
		lists.append(raw)
	for arr in lists:
		if not arr is Array:
			continue
		for entry in arr:
			if entry is Dictionary and str(entry.get("id", "")).strip_edges() == pid:
				return entry as Dictionary
	return {}


func _apply_battle_loot_exp_and_capture_slice(save_data: Dictionary, pd: Dictionary, granted_list: Array, force_absolute_exp_sync: bool = false) -> void :
	var player_pd: Variant = save_data.get("playerData", null)
	if player_pd is Dictionary and not (player_pd as Dictionary).is_empty():
		apply_field_battle_loot_player_slice(player_pd as Dictionary, force_absolute_exp_sync)
	elif pd.has("playerLevel"):
		apply_field_battle_loot_player_slice({
			"level": pd.get("playerLevel", player.level if player else 1), 
			"experience": pd.get("playerExperience", player.experience if player else 0), 
		}, force_absolute_exp_sync)
	if pet_manager:
		if not _should_skip_battle_loot_pet_slice():
			_try_apply_battle_loot_pet_slice(save_data, force_absolute_exp_sync)
		elif pet_manager.get_active_pet() != null:
			print("[GameManager] 副本/挑战进行中，跳过 battle-loot 出战宠 slice 应用")
		for entry in granted_list:
			if not entry is Dictionary:
				continue
			var instance_id: = str((entry as Dictionary).get("id", "")).strip_edges()
			if instance_id.is_empty():
				continue
			var new_pet_dict: = _find_pet_dict_in_save_data(save_data, instance_id)
			if not new_pet_dict.is_empty():
				pet_manager.inject_server_granted_pet_from_dict(new_pet_dict)
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_refresh_battle_ally_labels_after_settlement"):
		main_ui.call_deferred("_refresh_battle_ally_labels_after_settlement")


func _apply_battle_loot_pet_collection_data(pc: Dictionary) -> void :
	if pet_collection_manager == null or pc.is_empty():
		return
	if not pc.has("progress"):
		return
	var merged_pc: Dictionary = _merge_pet_collection_take_max(pet_collection_manager.to_dict(), pc)
	pet_collection_manager.from_dict(merged_pc)

func _read_pet_collection_dict_from_local_save() -> Dictionary:
	var paths: Array[String] = []
	var active_path: = _get_active_save_file_name()
	if not active_path.is_empty():
		paths.append(active_path)
	var backup_path: = _get_active_save_backup_file_name()
	if not backup_path.is_empty() and backup_path != active_path:
		paths.append(backup_path)
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var save_file: = FileAccess.open(path, FileAccess.READ)
		if save_file == null:
			continue
		var encrypted: = save_file.get_buffer(save_file.get_length())
		save_file.close()
		if encrypted.is_empty():
			continue
		var result = _decrypt_and_validate_save(encrypted)
		if result is Dictionary:
			var pc: Variant = (result as Dictionary).get("pet_collection", {})
			if pc is Dictionary and (pc as Dictionary).has("progress"):
				return pc as Dictionary
	return {}


func refresh_pet_collection_for_ui() -> void :
	if pet_collection_manager == null:
		return
	var memory_pc: Dictionary = pet_collection_manager.to_dict()
	var disk_pc: Dictionary = _read_pet_collection_dict_from_local_save()
	var merged_pc: Dictionary = memory_pc
	if not disk_pc.is_empty():
		merged_pc = _merge_pet_collection_take_max(memory_pc, disk_pc)
	pet_collection_manager.from_dict(merged_pc)

func _apply_battle_loot_authority_response(pd: Dictionary, skip_reward_logs: bool = false, force_absolute_exp_sync: bool = false) -> void :
	if pd.is_empty():
		return
	if in_battle:
		print("[GameManager] battle-loot 回包到达时仍在战斗中，跳过 hp/max_hp 等战中属性云端覆盖")
	elif is_field_combat_hp_merge_blocked():
		print("[GameManager] battle-loot 回包在野外连战 HP 保护窗口内，跳过 hp/max_hp 等属性云端覆盖")
	var save_var: Variant = pd.get("saveData", null)
	var granted: Variant = pd.get("grantedPets", [])
	var granted_list: Array = granted if granted is Array else []
	var has_new_pets: = granted_list.size() > 0
	if save_var is Dictionary and not (save_var as Dictionary).is_empty():
		var save_data: Dictionary = save_var as Dictionary
		if save_data.has("petCollectionData") and pet_collection_manager != null:
			var pc: Variant = save_data.get("petCollectionData", null)
			if pc is Dictionary:
				_apply_battle_loot_pet_collection_data(pc as Dictionary)
		if has_new_pets:
			_apply_battle_loot_exp_and_capture_slice(save_data, pd, granted_list, force_absolute_exp_sync)
		else:
			var player_pd: Variant = save_data.get("playerData", null)
			if player_pd is Dictionary and not (player_pd as Dictionary).is_empty():
				apply_field_battle_loot_player_slice(player_pd as Dictionary, force_absolute_exp_sync)
			else:
				apply_field_battle_loot_player_slice({
					"level": pd.get("playerLevel", player.level if player else 1), 
					"experience": pd.get("playerExperience", player.experience if player else 0), 
				}, force_absolute_exp_sync)
			if pet_manager and not _should_skip_battle_loot_pet_slice():
				_try_apply_battle_loot_pet_slice(save_data, force_absolute_exp_sync)
			elif pet_manager and pet_manager.get_active_pet() != null and _should_skip_battle_loot_pet_slice():
				print("[GameManager] 副本/挑战进行中，跳过 battle-loot 出战宠 slice 应用")
			var main_ui: = _find_main_ui_node()
			if main_ui and main_ui.has_method("_refresh_battle_ally_labels_after_settlement"):
				main_ui.call_deferred("_refresh_battle_ally_labels_after_settlement")
	else:
		apply_field_battle_loot_player_slice({
			"level": pd.get("playerLevel", player.level if player else 1), 
			"experience": pd.get("playerExperience", player.experience if player else 0), 
		}, force_absolute_exp_sync)
		var ap = pet_manager.get_active_pet() if pet_manager else null
		if ap and not _should_skip_battle_loot_pet_slice():
			if pd.has("petLevel") or pd.has("petExperience"):
				pet_manager.apply_active_pet_battle_loot_slice({
					"level": int(pd.get("petLevel", ap.level)), 
					"experience": int(pd.get("petExperience", ap.experience)), 
				}, force_absolute_exp_sync)
		elif ap and _should_skip_battle_loot_pet_slice():
			print("[GameManager] 副本/挑战进行中，跳过 battle-loot 出战宠 slice 应用")
		var main_ui_fallback: = _find_main_ui_node()
		if main_ui_fallback and main_ui_fallback.has_method("_refresh_battle_ally_labels_after_settlement"):
			main_ui_fallback.call_deferred("_refresh_battle_ally_labels_after_settlement")
	if not skip_reward_logs:
		_log_field_battle_exp_bonuses_once(pd)
		var player_exp: = int(pd.get("playerExpGranted", 0))
		if player_exp > 0:
			battle_system.add_log("获得 [color=cyan]%d[/color] 经验！" % player_exp)
		elif battle_system.player_died_in_battle or bool(pd.get("playerDied", false)):
			battle_system.add_log("[color=gray]人物阵亡，本场未获得人物经验[/color]")
		var pet_exp: = int(pd.get("petExpGranted", 0))
		if pet_exp > 0:
			var ap2 = pet_manager.get_active_pet() if pet_manager else null
			if ap2:
				battle_system.add_log("[color=cyan]%s 获得 %d 经验[/color]" % [ap2.pet_name, pet_exp])
	if bool(pd.get("captured", false)):
		var granted_pets: Variant = pd.get("grantedPets", [])
		if granted_pets is Array and granted_pets.size() > 0 and granted_pets[0] is Dictionary:
			var g: Dictionary = granted_pets[0]
			battle_system.add_log("[color=purple]★ 捕捉成功：%s ★[/color]" % str(g.get("name", "神秘宠物")))
	elif auto_capture_enabled and pd.has("captureSkipReason"):
		var skip_reason: = str(pd.get("captureSkipReason", ""))
		var skip_detail: Variant = pd.get("captureSkipDetail", {})
		var detail: Dictionary = skip_detail if skip_detail is Dictionary else {}
		match skip_reason:
			"below_min_growth_to_collection":
				var pet_name_col: = str(detail.get("name", "宠物"))
				var growth_col: = float(detail.get("growth", 0.0))
				var threshold_col: = float(detail.get("minGrowth", min_growth_threshold))
				battle_system.add_log("[color=gray]%s 成长值 %.3f 低于 %.3f，已加入图鉴[/color]" % [pet_name_col, growth_col, threshold_col])
			"below_min_growth_discarded":
				var pet_name_disc: = str(detail.get("name", "宠物"))
				var growth_disc: = float(detail.get("growth", 0.0))
				var threshold_disc: = float(detail.get("minGrowth", min_growth_threshold))
				battle_system.add_log("[color=gray]%s 成长值 %.3f 低于 %.3f，图鉴已满已丢弃[/color]" % [pet_name_disc, growth_disc, threshold_disc])
			"below_min_growth":
				var pet_name: = str(detail.get("name", "宠物"))
				var growth: = float(detail.get("growth", 0.0))
				var threshold: = float(detail.get("minGrowth", min_growth_threshold))
				battle_system.add_log("[color=gray]%s 成长值 %.3f 低于 %.3f，已丢弃[/color]" % [pet_name, growth, threshold])
			"roster_full":
				var full_name: = str(detail.get("name", "宠物"))
				var full_growth: = float(detail.get("growth", 0.0))
				if full_name.is_empty() or full_name == "宠物":
					battle_system.add_log("[color=gray]宠物栏已满，已放生[/color]")
				else:
					battle_system.add_log("[color=gray]宠物栏已满，%s（成长 %.3f）已放生[/color]" % [full_name, full_growth])
			_:
				battle_system.add_log("[color=gray]捕捉失败，怪物逃跑了[/color]")
	elif pd.has("captured") and not bool(pd.get("captured", false)) and auto_capture_enabled:
		battle_system.add_log("[color=gray]捕捉失败，怪物逃跑了[/color]")
	notify_pet_max_level_skill_learned(pd.get("learnedSkill", null))

func notify_pet_max_level_skill_learned(learned: Variant) -> void :
	if not learned is Dictionary:
		return
	var payload: Dictionary = learned as Dictionary
	if payload.is_empty():
		return
	var skill_name: = str(payload.get("skill_name", payload.get("skillName", ""))).strip_edges()
	if skill_name.is_empty() and str(payload.get("skill_key", "")).strip_edges().is_empty():
		return
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("show_pet_max_level_learn_popup"):
		main_ui.call_deferred("show_pet_max_level_learn_popup", payload)

func _wild_monster_drop_pet_id(monster) -> String:
	if monster == null:
		return ""
	if monster is Dictionary:
		var d: Dictionary = monster
		var drop_id: = str(d.get("drop_pet_id", "")).strip_edges()
		if drop_id.is_empty():
			drop_id = str(d.get("monster_id", "")).strip_edges()
		if not drop_id.is_empty() and GameData.PET_DATA.has(drop_id):
			return drop_id
		var nm: = str(d.get("monster_name", d.get("name", ""))).strip_edges()
		if nm.is_empty():
			return ""
		for pid in GameData.PET_DATA:
			var pd = GameData.PET_DATA[pid]
			if pd is Dictionary and str(pd.get("name", "")) == nm:
				return str(pid)
		return ""
	if typeof(monster) != TYPE_OBJECT:
		return ""
	if monster.has_method("get_drop_pet_id"):
		return str(monster.get_drop_pet_id()).strip_edges()
	return ""

func _monster_is_wild_capturable(monster) -> bool:
	if monster == null:
		return false
	var drop_id: = _wild_monster_drop_pet_id(monster)
	if drop_id.is_empty():
		if monster is Dictionary:
			var pet_info = _find_pet_data_by_name(str(monster.get("monster_name", monster.get("name", ""))))
			return not pet_info.is_empty()
		if typeof(monster) == TYPE_OBJECT and not monster.has_method("get_drop_pet_id"):
			var pet_info2 = _find_pet_data_by_name(str(monster.monster_name))
			return not pet_info2.is_empty()
		return false
	if pet_manager != null and pet_manager.is_event_limited_pet_id(drop_id, GameData.PET_DATA.get(drop_id, {})):
		return false
	return GameData.PET_DATA.has(drop_id)

func _build_battle_loot_capture_candidate() -> Dictionary:
	if not auto_capture_enabled:
		return {}
	var capturable: Array = []
	for i in range(battle_system.monsters.size()):
		var monster = battle_system.monsters[i]
		if _monster_is_wild_capturable(monster):
			capturable.append(i)
	if capturable.is_empty():
		return {}
	var target_index: int = capturable[randi() % capturable.size()]
	var monster = battle_system.monsters[target_index]
	var pet_id: = _wild_monster_drop_pet_id(monster)
	if pet_id.is_empty():
		return {}
	return {"petId": pet_id, "minGrowthThreshold": min_growth_threshold}

func _grant_field_battle_exp(exp_reward: int, active_pet) -> void :
	if exp_reward <= 0:
		return
	_log_field_battle_exp_bonuses_once()
	if not battle_system.player_died_in_battle:
		if _try_consume_field_player_exp_grant_slot():
			var messages = player.add_exp(exp_reward, false, true, get_field_catchup_level_ups())
			for msg in messages:
				battle_system.add_log(msg)
			_clamp_field_player_level_after_exp()
		else:
			print("[FieldExp] skip duplicate player exp grant within settlement window")
	else:
		battle_system.add_log("[color=gray]人物本场死亡，无法获得经验[/color]")
	if active_pet:
		if not battle_system.pet_died_in_battle:
			if is_pet_merge_exp_blocked_for_pet(active_pet):
				print("[PetMerge] skip field pet exp during merge lock id=%s" % str(active_pet.id))
			elif _try_consume_field_pet_exp_grant_slot():
				var pet_exp_reward = _battle_pet_exp_with_player_multiplier(exp_reward)
				var pet_result = pet_manager.add_pet_exp(active_pet, pet_exp_reward, false, get_field_catchup_level_ups())
				for msg in pet_result.messages:
					battle_system.add_log("[color=cyan]%s[/color]" % msg)
				if pet_result.leveled_up:
					battle_system.add_log("[color=green]★ %s 升到 %d 级！★[/color]" % [active_pet.pet_name, active_pet.level])
				_clamp_field_pet_level_after_exp(active_pet)
			else:
				print("[FieldExp] skip duplicate pet exp grant within settlement window")
		else:
			battle_system.add_log("[color=gray]宠物本场死亡，无法获得经验[/color]")

func _build_battle_loot_monsters_payload() -> Array:
	var rewards = battle_system.get_battle_rewards()
	var payload: Array = []
	for m in rewards.get("monsters", []):
		if m is Dictionary:
			payload.append({
				"level": int(m.get("level", 1)), 
				"gold_reward": int(m.get("gold_reward", m.get("gold", 0))), 
				"exp_reward": int(m.get("exp_reward", m.get("exp", 0))), 
			})
		else:
			var entry: = {
				"level": int(m.level), 
				"gold_reward": int(m.gold_reward), 
				"exp_reward": int(m.exp_reward), 
			}
			var mid: = str(m.monster_id).strip_edges()
			if not mid.is_empty():
				entry["monster_id"] = mid
			if m.has_meta(Monster.FESTIVAL_EVENT_TAG_META):
				entry["festival_event_tag"] = str(m.get_meta(Monster.FESTIVAL_EVENT_TAG_META, "")).strip_edges()
			payload.append(entry)
	return payload


func _derive_battle_exp_base_from_loot_payload(payload: Array) -> int:
	if payload.is_empty() or payload.size() > 12:
		return 0
	var total: = 0
	var exp_per_level: = maxi(1, Monster.wild_exp_per_level)
	for m in payload:
		if not m is Dictionary:
			return 0
		var lev: = clampi(int(m.get("level", 0)), 1, 20000)
		var has_exp_key: bool = m.has("exp_reward") or m.has("exp")
		var raw: = int(m.get("exp_reward", m.get("exp", lev if not has_exp_key else 0)))
		if raw < 0:
			return 0
		var level_cap: = maxi(1, lev * exp_per_level * 5)
		var capped: int
		if has_exp_key and raw > 0:
			capped = mini(raw, level_cap)
		else:
			capped = maxi(1, lev * exp_per_level)
		total += capped
		if total > 50000000:
			return 0
	return total

func _field_exp_difficulty_tier() -> String:
	var ticket: = _wild_replay_map_difficulty.strip_edges()
	if not ticket.is_empty():
		return ticket
	if fabao_manager:
		return str(fabao_manager.current_difficulty)
	return "normal"

func _apply_field_battle_exp_multipliers(base_exp: int) -> int:
	if base_exp <= 0:
		return 0
	var exp_reward: = base_exp
	if martial_arts_manager:
		var effects = martial_arts_manager.get_equipped_effects()
		exp_reward = int(exp_reward * (1.0 + effects.exp / 100.0))
	var exp_mul: = 0.5
	if has_method("get_wild_battle_runtime_config"):
		var wb_cfg: = get_wild_battle_runtime_config()
		if not wb_cfg.is_empty():
			exp_mul = float(wb_cfg.get("fieldExpMultiplier", 0.5))
	var map_pct: = 0
	if fabao_manager:
		var tier_id: = _field_exp_difficulty_tier()
		map_pct = FabaoConfig.map_exp_bonus_pct(tier_id)
	return int(round(float(exp_reward) * exp_mul * (1.0 + float(map_pct) / 100.0)))

func _compute_preview_field_battle_exp(rewards_exp: int, loot_payload: Array) -> int:
	var base_exp: = rewards_exp
	if base_exp <= 0:
		base_exp = _derive_battle_exp_base_from_loot_payload(loot_payload)
	return _apply_field_battle_exp_multipliers(base_exp)

func _build_field_battle_preview_snapshot() -> Dictionary:
	var snap: = {
		"preview_gold": player.gold if player else 0, 
		"preview_player_level": player.level if player else 1, 
		"preview_player_exp": player.experience if player else 0, 
	}
	var ap = pet_manager.get_active_pet() if pet_manager else null
	if ap:
		snap["preview_pet_id"] = str(ap.id)
		snap["preview_pet_level"] = int(ap.level)
		snap["preview_pet_exp"] = int(ap.experience)
	return snap

func _rollback_field_battle_preview_rewards(ctx: Dictionary, data: Dictionary = {}) -> void :
	if player == null:
		return
	if data is Dictionary and data.has("newGold"):
		player.gold = int(data.get("newGold", player.gold))
	elif ctx.has("preview_gold"):
		player.gold = int(ctx.get("preview_gold", player.gold))
	elif int(ctx.get("g_reward", 0)) > 0:
		player.gold = maxi(0, player.gold - int(ctx.get("g_reward", 0)))
	var player_slice: = {
		"level": int(data.get("playerLevel", ctx.get("preview_player_level", player.level))) if data is Dictionary else int(ctx.get("preview_player_level", player.level)), 
		"experience": int(data.get("playerExperience", ctx.get("preview_player_exp", player.experience))) if data is Dictionary else int(ctx.get("preview_player_exp", player.experience)), 
	}
	sync_player_authoritative_upgrade_dan_slice_from_dict(player_slice, true)
	var active_pet = ctx.get("active_pet", null)
	if active_pet and pet_manager:
		var pet_slice: Dictionary = {}
		if data is Dictionary and (data.has("petLevel") or data.has("petExperience")):
			pet_slice = {
				"level": int(data.get("petLevel", active_pet.level)), 
				"experience": int(data.get("petExperience", active_pet.experience)), 
			}
		elif (
			str(ctx.get("preview_pet_id", "")) == str(active_pet.id)
			and ctx.has("preview_pet_level")
		):
			pet_slice = {
				"level": int(ctx.get("preview_pet_level", active_pet.level)), 
				"experience": int(ctx.get("preview_pet_exp", active_pet.experience)), 
			}
		if not pet_slice.is_empty():
			pet_manager.apply_active_pet_battle_loot_slice(pet_slice, true)
	gold_changed.emit(player.gold)

func _is_battle_speed_loot_block_response(data: Dictionary, err: String) -> bool:
	if data is Dictionary:
		var code: = str(data.get("code", ""))
		if code == "BATTLE_SPEED_ANOMALY_WARNING" or code == "ACCOUNT_SUSPENDED":
			return true
		if bool(data.get("accountSuspended", false)):
			return true
	if err.find("战斗加速") >= 0:
		return true
	return false

func _ensure_field_battle_loot_result_listener() -> void :
	if _field_battle_loot_result_connected or network == null:
		return
	network.economy_result.connect(_on_async_field_battle_loot_result)
	_field_battle_loot_result_connected = true

const FIELD_BATTLE_LOOT_MAX_RETRIES: = 3

func _dispatch_field_battle_loot_async(
	op_id: String, 
	loot_payload: Array, 
	dropped_item: String, 
	loot_extras: Dictionary, 
	ctx: Dictionary, 
) -> void :
	if network == null or not network.is_logged_in() or op_id.is_empty():
		return
	if str(loot_extras.get("fightToken", "")).strip_edges().is_empty():
		_defer_field_auto_after_transient("没有服务器结算票，奖励未入账")
		return
	if _field_battle_loot_should_block_dispatch(ctx):
		return
	var batch_count: = maxi(1, int(ctx.get("batch_battle_count", int(loot_extras.get("batchBattleCount", 1)))))
	var min_gap_ms: = _field_battle_loot_min_send_gap_ms(batch_count)
	var now_ms: = Time.get_ticks_msec()
	if _last_field_battle_loot_sent_ms > 0 and now_ms - _last_field_battle_loot_sent_ms < min_gap_ms:
		var wait_sec: = float(min_gap_ms - (now_ms - _last_field_battle_loot_sent_ms)) / 1000.0
		var deferred_ctx: = ctx.duplicate(true)
		get_tree().create_timer(maxf(0.05, wait_sec)).timeout.connect(
			func():
				_dispatch_field_battle_loot_async(op_id, loot_payload, dropped_item, loot_extras, deferred_ctx), 
			CONNECT_ONE_SHOT
		)
		return
	if _field_battle_loot_should_block_dispatch(ctx):
		return
	_last_field_battle_loot_sent_ms = now_ms
	_ensure_field_battle_loot_result_listener()
	if not ctx.has("retry_count"):
		ctx["retry_count"] = 0
	ctx["op_id"] = op_id
	ctx["loot_payload"] = loot_payload
	ctx["loot_extras"] = loot_extras
	ctx["loot_stop_epoch"] = _field_battle_loot_stop_epoch
	_field_battle_loot_pending[op_id] = ctx
	network.economy_battle_loot(op_id, loot_payload, current_map, dropped_item, loot_extras)

func _on_async_field_battle_loot_result(rid: String, request_type: String, success: bool, data: Dictionary, err: String) -> void :
	if request_type != "economy_battle_loot":
		return
	if not _field_battle_loot_pending.has(rid):
		return
	var ctx: Dictionary = _field_battle_loot_pending[rid]
	_field_battle_loot_pending.erase(rid)
	if _should_discard_field_battle_loot_result(rid, ctx):
		_field_battle_loot_discard_ids.erase(rid)
		_end_field_loot_await_next_fight()
		_maybe_clear_field_battle_pet_level_guard()
		return
	_field_battle_loot_slice_anchor_pet = int(ctx.get("anchor_pet_level", _field_battle_pet_level_at_start))
	_field_battle_loot_slice_anchor_player = int(ctx.get("anchor_player_level", _field_exp_level_cap_player))
	_field_battle_loot_slice_batch_budget = maxi(1, int(ctx.get("batch_battle_count", 1)))
	var previewed_online_rewards: = bool(ctx.get("previewed_online_rewards", false))
	var g_reward: = int(ctx.get("g_reward", 0))
	var dropped_item: = str(ctx.get("dropped_item", ""))
	if success:
		var battle_speed_throttled: = bool(data.get("battleSpeedThrottled", false)) if data is Dictionary else false
		var gold_log: = g_reward
		if data is Dictionary:
			var pd: Dictionary = data
			if pd.has("newGold"):
				player.gold = int(pd.get("newGold", player.gold))
			if pd.has("goldGranted"):
				gold_log = int(pd.get("goldGranted", g_reward))
			var granted_name: = str(pd.get("itemGranted", ""))
			var granted_n: = maxi(1, int(pd.get("itemGrantedCount", 1)))
			var granted_add_ok: = false
			if granted_name != "" and not battle_speed_throttled:
				var add_ir = inventory_manager.add_item(granted_name, granted_n)
				granted_add_ok = bool(add_ir.get("success", false))
				if granted_add_ok:
					if granted_n > 1:
						battle_system.add_log("[color=green]★ 获得物品：%s x%d ★[/color]" % [granted_name, granted_n])
					else:
						battle_system.add_log("[color=green]★ 获得物品：%s ★[/color]" % granted_name)
			var fabao_granted: = str(pd.get("fabaoItemGranted", pd.get("fabao_item_granted", "")))
			var fabao_n: = maxi(1, int(pd.get("fabaoItemGrantedCount", pd.get("fabao_item_granted_count", 1))))
			if fabao_granted != "" and not battle_speed_throttled:
				var fabao_add_ok: = granted_add_ok and fabao_granted == granted_name
				if fabao_granted != granted_name:
					var add_fr = inventory_manager.add_item(fabao_granted, fabao_n)
					fabao_add_ok = bool(add_fr.get("success", false))
				if fabao_add_ok:
					if fabao_granted != granted_name:
						if fabao_n > 1:
							battle_system.add_log("[color=green]★ 获得物品：%s x%d ★[/color]" % [fabao_granted, fabao_n])
						else:
							battle_system.add_log("[color=green]★ 获得物品：%s ★[/color]" % fabao_granted)
				else:
					battle_system.add_log("[color=orange]获得 %s，但背包已满（已记在云端，清理背包后重新登录可见）[/color]" % fabao_granted)
		if data is Dictionary:
			if battle_speed_throttled:
				if previewed_online_rewards:
					_rollback_field_battle_preview_rewards(ctx, data)
			else:
				var skip_reward_logs: = previewed_online_rewards
				_apply_battle_loot_authority_response(data, skip_reward_logs, false)
		if battle_speed_throttled:
			_apply_battle_speed_throttle_cooldown()
			var warn_msg: = str(data.get("battleSpeedWarning", "")).strip_edges() if data is Dictionary else ""
			if warn_msg.is_empty():
				warn_msg = "检测到战斗频率异常，已暂停自动战斗 60 秒。请关闭加速工具，否则账号将被封禁。"
			battle_system.add_log("[color=orange]%s[/color]" % warn_msg)
		else:
			_reset_field_auto_retry_progress()
		gold_changed.emit(player.gold)
		if gold_log > 0 and not previewed_online_rewards and not battle_speed_throttled:
			_log_field_battle_exp_bonuses_once(data if data is Dictionary else {})
			battle_system.add_log("获得 [color=yellow]%d[/color] 金币！" % gold_log)
		_clear_settled_wild_replay_token(str(ctx.get("fight_token", "")))
		_end_field_loot_await_next_fight()
	else:
		var err_code: = str(data.get("code", "")) if data is Dictionary else ""
		var retry_count: = int(ctx.get("retry_count", 0))
		var op_id: = str(ctx.get("op_id", rid))
		var loot_payload: Variant = ctx.get("loot_payload", [])
		var loot_extras: Variant = ctx.get("loot_extras", {})
		if _is_battle_speed_loot_block_response(data if data is Dictionary else {}, err):
			if previewed_online_rewards:
				_rollback_field_battle_preview_rewards(ctx, data if data is Dictionary else {})
			var block_msg: = err
			if block_msg.is_empty() and data is Dictionary:
				block_msg = str(data.get("error", ""))
			if block_msg.is_empty():
				block_msg = "战斗加速异常，本次战斗奖励未入账。请停止使用加速工具，否则账号将被封禁。"
			_pause_field_auto_for_loot_fail(block_msg)
			_maybe_clear_field_battle_pet_level_guard()
			return
		if err_code == "WILD_REPLAY_TOKEN_REQUIRED":
			_clear_settled_wild_replay_token(str(ctx.get("fight_token", "")))
			_defer_field_auto_after_transient("本场结算票无效，奖励未入账")
			_maybe_clear_field_battle_pet_level_guard()
			return
		if retry_count < FIELD_BATTLE_LOOT_MAX_RETRIES and err_code != "BATTLE_SPEED_ANOMALY_WARNING":
			var next_ctx: Dictionary = ctx.duplicate(true)
			next_ctx["retry_count"] = retry_count + 1
			next_ctx["allow_when_auto_off"] = true
			if _field_loot_hold_next_fight:
				_field_loot_hold_until_ms = Time.get_ticks_msec() + FIELD_LOOT_AWAIT_NEXT_FIGHT_MS
			battle_system.add_log("[color=orange]战斗结算同步重试 (%d/%d)...[/color]" % [retry_count + 1, FIELD_BATTLE_LOOT_MAX_RETRIES])
			_dispatch_field_battle_loot_async(
				op_id, 
				loot_payload if loot_payload is Array else [], 
				dropped_item, 
				loot_extras if loot_extras is Dictionary else {}, 
				next_ctx, 
			)
			return
		var why: = err
		if why.is_empty():
			why = "服务端未应答或超时，请稍后再试"
		battle_system.add_log("[color=orange]战斗结算同步失败：%s[/color]" % why)
		_defer_field_auto_after_transient("")
	_maybe_clear_field_battle_pet_level_guard()

func _on_battle_ended(victory: bool) -> void :
	if is_five_elements_battle or is_suit_dungeon_battle or is_atlas_dungeon_battle or is_tower_battle or is_tower_settling or is_brother_tower_battle or is_brother_tower_settling:
		return
	in_battle = false
	if is_auto_battle_enabled():
		_touch_field_combat_hp_protection(30000)
	else:
		_touch_field_combat_hp_protection(8000)
		_schedule_field_combat_hp_protection_release(8000)


	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = false
	last_battle_was_arena = false

	var active_pet = pet_manager.get_active_pet()


	battle_ended_ui.emit(victory)

	if victory:
		var session_active: bool = network != null and network.is_logged_in()
		if not session_active:
			battle_system.add_log("[color=orange]会话已失效，本场战斗奖励未发放[/color]")
		else:

			_begin_field_exp_settlement_window()
			var rewards = battle_system.get_battle_rewards()
			var loot_payload: = _build_battle_loot_monsters_payload()
			var exp_reward: = _compute_preview_field_battle_exp(int(rewards.get("exp", 0)), loot_payload)
			var capture_candidate: Dictionary = {}
			if network and network.is_logged_in():
				capture_candidate = _build_battle_loot_capture_candidate()


			var g_reward: = int(rewards.get("gold", 0))

			var dropped_item: = str(inventory_manager.get_random_drop(player.level))
			var fight_token: = _wild_replay_token.strip_edges()
			if fight_token.is_empty():
				_defer_field_auto_after_transient("本场没有服务器结算票，奖励未入账")
			elif network and network.is_logged_in():

				if loot_payload.is_empty():
					loot_payload = [{"level": player.level, "gold_reward": g_reward}]
				var loot_extras: = {
					"playerDied": battle_system.player_died_in_battle, 
					"petDied": battle_system.pet_died_in_battle, 
					"fightToken": fight_token, 
				}
				if active_pet:
					loot_extras["activePetId"] = str(active_pet.id)
					loot_extras["clientPetLevel"] = int(active_pet.level)
					loot_extras["clientPetExperience"] = int(active_pet.experience)
					var client_progress: = _build_battle_loot_client_pet_progress_snapshot(active_pet)
					if not client_progress.is_empty():
						loot_extras["clientPetProgress"] = client_progress
				if not capture_candidate.is_empty():
					loot_extras["captureCandidate"] = capture_candidate
				if auto_capture_enabled:
					loot_extras["minGrowthThreshold"] = min_growth_threshold
				var loot_ctx: = {
					"previewed_online_rewards": false, 
					"g_reward": g_reward, 
					"exp_reward": exp_reward, 
					"dropped_item": dropped_item, 
					"active_pet": active_pet, 
					"batch_battle_count": 1, 
					"anchor_pet_level": _field_battle_pet_level_at_start, 
					"anchor_player_level": _field_exp_level_cap_player, 
					"allow_when_auto_off": true, 
					"fight_token": fight_token, 
				}
				battle_system.add_log("[color=gray]正在结算经验与金币...[/color]")
				if is_auto_battle_enabled():
					_begin_field_loot_await_next_fight()
				_dispatch_immediate_field_battle_loot(
					loot_payload, 
					g_reward, 
					exp_reward, 
					dropped_item, 
					loot_extras, 
					loot_ctx, 
				)
				var dropped_equipment = equipment_manager.roll_equipment_drop(player.cultivation, player.realm)
				if dropped_equipment:
					battle_system.add_log("[color=purple]★ 获得装备：%s ★[/color]" % dropped_equipment.name)
					if dropped_equipment.is_pet_equipment:
						inventory_manager.add_pet_equipment(dropped_equipment)
					else:
						equipment_manager.add_to_inventory(dropped_equipment)
			else:
				battle_system.add_log("[color=orange]会话已失效，本场战斗奖励未发放[/color]")


		player.heal_full()
		if active_pet:
			active_pet.heal_full()
	else:
		battle_system.add_log("[color=red]你倒下了...但神秘力量让你复活了！[/color]")
		player.heal_full()
		if active_pet:
			active_pet.heal_full()
		battle_system.add_log("[color=green]HP已完全恢复，继续战斗！[/color]")

	mark_battle_progress_dirty("battle_end")


func start_tower_battle(floor: int, monsters: Array) -> bool:
	print("[GameManager] start_tower_battle 被调用, floor=", floor, ", in_battle=", in_battle, ", battle_system.current_state=", battle_system.current_state)
	if is_tower_settling:
		print("[GameManager] 天关结算进行中，延后开启下一场")
		return false
	if _is_other_instanced_battle_active("tower"):
		push_warning("天关：其他玩法战斗进行中，无法开战")
		return false
	if in_battle:
		if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			print("[GameManager] 天关：当前战斗进行中，无法开战")
			return false
		push_warning("检测到战斗状态不一致，强制重置")
		in_battle = false
		if battle_system:
			battle_system.current_state = battle_system.BattleState.IDLE
			battle_system.monsters.clear()
			battle_system.battle_log.clear()
			battle_system.suppress_battle_character_exp = false
		_disconnect_all_battle_ended_handlers()

	is_tower_battle = true
	is_tower_run_active = true
	stop_tower_requested = false
	_tower_replay_abort = false
	_wild_replay_abort = true
	battle_system.suppress_battle_character_exp = false
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = false
	current_tower_floor = floor

	battle_system.max_rounds = 30

	_disconnect_all_battle_ended_handlers()
	battle_system.battle_ended.connect(_on_tower_battle_ended)

	if is_tower_replay_on():
		if network == null or not network.is_logged_in():
			print("[GameManager] 天关录像未登录，开战失败")
			is_tower_battle = false
			_end_tower_run_session(false)
			return false
		if _tower_replay_busy:
			is_tower_battle = false
			_end_tower_run_session(false)
			return false
		_tower_replay_busy = true
		_tower_replay_token = ""
		_tower_replay_server_victory = false
		_tower_replay_abort = false
		in_battle = true
		_start_tower_replay_battle_async(floor)
		return true

	_tower_replay_token = ""
	_tower_replay_server_victory = false
	var active_pet = pet_manager.get_active_pet()
	if battle_system.start_battle(player, active_pet, monsters, 30, false, resolve_attack_target_mode("tower")):
		in_battle = true
		tower_battle_started.emit(floor)
		print("[GameManager] 天关战斗开始成功, floor=", floor)
		return true

	print("[GameManager] 天关战斗开始失败")
	is_tower_battle = false
	_end_tower_run_session(false)
	return false

func force_stop_field_battle():
	if is_tower_battle or is_tower_settling or is_suit_dungeon_battle or is_five_elements_battle or is_atlas_dungeon_battle or is_brother_tower_battle or is_brother_tower_settling or is_world_boss_battle or is_arena_battle:
		_detach_running_wild_replay()
		return
	_detach_running_wild_replay()
	if battle_system and in_battle and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.drive_by_execute_turn = false
		battle_system.force_end_battle(false)
	if not is_in_instanced_challenge():
		in_battle = false


func _detach_running_wild_replay() -> void :
	_wild_replay_gen += 1
	_wild_replay_abort = true
	_wild_replay_busy = false
	var token: = _wild_replay_token.strip_edges()
	_wild_replay_token = ""
	_wild_replay_map_difficulty = ""
	_abandon_wild_fight_token(token)
	if is_in_instanced_challenge():
		return
	if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.drive_by_execute_turn = false
		battle_system.force_end_battle(false)
	in_battle = false

func _abandon_wild_fight_token(token: String) -> void :
	var tk: = token.strip_edges()
	if tk.is_empty() or network == null or not network.is_logged_in():
		return
	if tk == _wild_replay_token.strip_edges():
		_wild_replay_token = ""
	var op_id: = "wildabandon_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	_fire_wild_abandon(tk, op_id)

func _fire_wild_abandon(token: String, op_id: String) -> void :
	await wait_economy("economy_wild_replay_abandon", func():
		network.economy_wild_replay_abandon(token, op_id)
	, op_id, 2500)

func _begin_wild_ticket_release() -> void :
	var token: = _wild_replay_token.strip_edges()
	_wild_replay_token = ""
	_abandon_wild_fight_token(token)

func clear_memory_caches_for_relogin() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_clear_city_ui_session_state"):
		main_ui.call("_clear_city_ui_session_state")

func request_return_to_login() -> void :
	clear_memory_caches_for_relogin()
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_force_return_to_login"):
		main_ui.call("_force_return_to_login")
	elif network:
		network.logout()

func _find_main_ui_node() -> Node:
	var node: Node = self
	while node:
		if node.has_method("halt_field_auto_battle_for_challenge"):
			return node
		node = node.get_parent()
	var tree: = get_tree()
	if tree == null:
		return null
	var root: = tree.root
	var main_ui: = root.get_node_or_null("MainUI")
	if main_ui:
		return main_ui
	var main: = root.get_node_or_null("Main")
	if main:
		main_ui = main.get_node_or_null("MainUI")
		if main_ui:
			return main_ui
		var canvas_layer: = main.get_node_or_null("MainCanvasLayer")
		if canvas_layer:
			main_ui = canvas_layer.get_node_or_null("MainUI")
			if main_ui:
				return main_ui
	return null

func _halt_main_ui_auto_battle() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("halt_field_auto_battle_for_challenge"):
		main_ui.halt_field_auto_battle_for_challenge()

func _clear_instanced_challenge_flags_for_field_resume() -> void :
	is_tower_battle = false
	is_tower_settling = false
	is_tower_run_active = false
	is_suit_dungeon_battle = false
	is_suit_dungeon_settling = false
	is_atlas_dungeon_battle = false
	is_atlas_dungeon_settling = false
	is_five_elements_battle = false
	is_fe_settling = false
	is_brother_tower_battle = false
	is_brother_tower_settling = false
	is_world_boss_battle = false

func _clear_battle_start_block_for_field_resume() -> void :
	_battle_start_block_until_ms = 0

func _prepare_field_battle_after_instanced() -> void :
	if battle_system == null:
		in_battle = false
		return
	battle_system.drive_by_execute_turn = false
	if in_battle and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.force_end_battle(false)
	if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.current_state = battle_system.BattleState.IDLE
		battle_system.monsters.clear()
	in_battle = false

func resume_field_auto_battle_after_instanced_challenge(force_battle_view: bool = true) -> void :
	_clear_instanced_challenge_flags_for_field_resume()
	_clear_battle_start_block_for_field_resume()
	_prepare_field_battle_after_instanced()
	var main_ui: Node = get_parent()
	if main_ui == null or not main_ui.has_method("halt_field_auto_battle_for_challenge"):
		main_ui = _find_main_ui_node()
	if main_ui and main_ui.has_method("resume_field_auto_battle_after_challenge"):
		main_ui.resume_field_auto_battle_after_challenge(force_battle_view)
		print("[Hotfix] resume_field_auto_battle ok force_view=", force_battle_view)
		return
	if main_ui:
		if "auto_battle" in main_ui:
			main_ui.set("auto_battle", true)
		var stop_btn: Node = main_ui.get("stop_battle_btn")
		if stop_btn is Button:
			(stop_btn as Button).text = "停止战斗"
	set_auto_battle_enabled(true)
	print("[Hotfix] resume_field_auto_battle fallback (main_ui method missing)")

func _hard_reset_field_battle_state() -> void :
	if not in_battle or battle_system == null:
		return
	if is_in_instanced_challenge():
		return
	battle_system.drive_by_execute_turn = false
	if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.force_end_battle(false)
	battle_system.current_state = battle_system.BattleState.IDLE
	battle_system.monsters.clear()
	battle_system.battle_log.clear()
	battle_system.suppress_battle_character_exp = false
	if battle_system.battle_ended.is_connected(_on_battle_ended):
		battle_system.battle_ended.disconnect(_on_battle_ended)
	in_battle = false


func prepare_for_instanced_challenge() -> void :
	block_battle_start_temporarily(BATTLE_START_BLOCK_CITY_SWITCH_MS, "instanced_challenge")
	_halt_main_ui_auto_battle()
	set_auto_battle_enabled(false, true)
	_clear_leftover_replay_for_local_combat()
	if is_in_instanced_challenge():
		return
	if in_battle:
		force_stop_field_battle()
	if in_battle:
		_hard_reset_field_battle_state()

func prepare_for_instanced_challenge_async() -> void :
	prepare_for_instanced_challenge()
	await _wait_field_replay_idle_async()

func force_stop_tower_battle():
	if not is_tower_battle and not _tower_replay_busy and not is_tower_run_active and not is_tower_settling:
		return
	stop_tower_requested = true
	_tower_replay_abort = true
	if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.force_end_battle(false)
		return
	var already_over: = false
	if battle_system:
		already_over = battle_system.current_state == battle_system.BattleState.VICTORY or battle_system.current_state == battle_system.BattleState.DEFEAT
	if already_over and is_tower_battle and not is_tower_settling:
		_on_tower_battle_ended(false)

func force_stop_suit_dungeon_battle() -> void :
	if not is_suit_dungeon_battle:
		return
	stop_suit_dungeon_requested = true
	if battle_system:
		battle_system.drive_by_execute_turn = false
		if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			battle_system.force_end_battle(false)
		elif not is_suit_dungeon_settling:
			_end_suit_dungeon_failed()

func _tower_replay_all_monsters_down() -> bool:
	if battle_system == null or battle_system.monsters.is_empty():
		return false
	for monster in battle_system.monsters:
		if battle_system.is_monster_alive(monster):
			return false
	return true

func _query_server_tower_highest() -> int:
	if network == null or not network.is_logged_in() or get_tree() == null:
		return -1
	var slot: = {"done": false, "highest": -1}
	var cb: = func(server_highest: int, _sweep: int, _floor: int) -> void :
		if bool(slot.get("done", false)):
			return
		slot["done"] = true
		slot["highest"] = int(server_highest)
	if not network.tower_info_loaded.is_connected(cb):
		network.tower_info_loaded.connect(cb)
	network.get_tower_info()
	var deadline: = Time.get_ticks_msec() + 8000
	while not bool(slot.get("done", false)) and Time.get_ticks_msec() < deadline:
		if get_tree() == null:
			break
		await get_tree().process_frame
	if network != null and network.tower_info_loaded.is_connected(cb):
		network.tower_info_loaded.disconnect(cb)
	if not bool(slot.get("done", false)):
		return -1
	return int(slot.get("highest", -1))

func _accept_counted_tower_floor(floor: int, highest: int) -> void :
	if player == null:
		return
	if highest > player.tower_highest:
		player.tower_highest = highest
	if player.tower_floor < floor + 1:
		player.tower_floor = floor + 1

func _apply_tower_clear_payload(data: Dictionary, floor: int, gold_reward: int) -> void :
	if data.has("newGold") and player:
		player.gold = int(data.get("newGold", player.gold))
	if battle_system:
		battle_system.add_log("获得 [color=yellow]%d[/color] 金币！" % int(data.get("goldGranted", gold_reward)))
	if player:
		if data.has("towerHighest"):
			player.tower_highest = int(data.get("towerHighest", player.tower_highest))
		if data.has("towerFloor"):
			player.tower_floor = int(data.get("towerFloor", player.tower_floor))
	if battle_system:
		if floor % 10 == 0:
			battle_system.add_log("[color=purple]★ 获得天关奖励（已发送到邮件） ★[/color]")
		if floor % 100 == 0:
			var item_name = "%d关礼包" % floor
			battle_system.add_log("[color=purple]★ 获得%s（已发送到邮件） ★[/color]" % item_name)
	gold_changed.emit(player.gold if player else 0)

func _recover_tower_clear_after_fail(floor: int, clear_token: String, err_msg: String, gold_reward: int) -> bool:
	var highest: = await _query_server_tower_highest()
	if highest >= floor and floor > 0:
		_accept_counted_tower_floor(floor, highest)
		if battle_system:
			battle_system.add_log("[color=green]这一层服务器已经记下，继续下一层。[/color]")
		return true
	if network and network.is_logged_in() and not clear_token.strip_edges().is_empty():
		var retry_op: = "tower_clear_retry_%s_%s_%s" % [str(floor), str(Time.get_unix_time_from_system()), str(randi())]
		var retry: Dictionary = await wait_economy("economy_tower_clear", func():
			network.economy_tower_clear_reward(retry_op, floor, clear_token)
		, retry_op)
		if bool(retry.get("ok", false)):
			var dvar: Variant = retry.get("data", {})
			if dvar is Dictionary:
				_apply_tower_clear_payload(dvar, floor, gold_reward)
			if battle_system:
				battle_system.add_log("[color=green]通关已补记入账。[/color]")
			return true
		err_msg = str(retry.get("err", err_msg))
	highest = await _query_server_tower_highest()
	if highest >= floor and floor > 0:
		_accept_counted_tower_floor(floor, highest)
		if battle_system:
			battle_system.add_log("[color=green]这一层服务器已经记下，继续下一层。[/color]")
		return true
	if battle_system:
		battle_system.add_log("[color=orange]天关通关未入账：%s。这一层需要再打一次。[/color]" % err_msg)
	return false

func _on_tower_battle_ended(victory: bool) -> void :
	print("[GameManager] _on_tower_battle_ended 被调用, victory=", victory, ", floor=", current_tower_floor)
	if not is_tower_battle:
		print("[GameManager] 非天关战斗回调，跳过")
		return
	if is_tower_settling:
		print("[GameManager] 天关结算已在进行，跳过重复调用")
		return
	is_tower_settling = true
	in_battle = false

	var floor = current_tower_floor
	var replay_mode: = is_tower_replay_on() or not _tower_replay_token.is_empty()
	var counted_win: = victory
	if stop_tower_requested:
		counted_win = false
	elif replay_mode and _tower_replay_abort:
		counted_win = false
	if replay_mode:
		counted_win = counted_win and _tower_replay_server_victory and not _tower_replay_token.is_empty()
	if not counted_win:
		_tower_replay_token = ""

	var applied_clear: = false
	if counted_win:
		var gold_reward = 100 * floor
		var active_pet = pet_manager.get_active_pet()

		var tower_ok: = false
		if network and network.is_logged_in():
			var op_id: = "tower_clear_%s_%s_%s" % [str(floor), str(Time.get_unix_time_from_system()), str(randi())]
			var clear_token: = _tower_replay_token
			_tower_replay_token = ""
			var er: Dictionary = await wait_economy("economy_tower_clear", func():
				network.economy_tower_clear_reward(op_id, floor, clear_token)
			, op_id)
			if er.get("ok", false):
				var dvar: Variant = er.get("data", {})
				if dvar is Dictionary:
					var d: Dictionary = dvar
					if d.has("newGold"):
						player.gold = int(d.get("newGold", player.gold))
					battle_system.add_log("获得 [color=yellow]%d[/color] 金币！" % int(d.get("goldGranted", gold_reward)))
					if d.has("towerHighest"):
						player.tower_highest = int(d.get("towerHighest", player.tower_highest))
					if d.has("towerFloor"):
						player.tower_floor = int(d.get("towerFloor", player.tower_floor))
					if floor % 10 == 0:
						battle_system.add_log("[color=purple]★ 获得天关奖励（已发送到邮件） ★[/color]")
					if floor % 100 == 0:
						var item_name = "%d关礼包" % floor
						battle_system.add_log("[color=purple]★ 获得%s（已发送到邮件） ★[/color]" % item_name)
				gold_changed.emit(player.gold)
				tower_ok = true
			else:
				var err_msg = str(er.get("err", "失败"))
				if replay_mode:
					tower_ok = await _recover_tower_clear_after_fail(floor, clear_token, err_msg, gold_reward)
				else:

					player.gold += gold_reward
					gold_changed.emit(player.gold)
					if floor > player.tower_highest:
						player.tower_highest = floor
					player.tower_floor = max(int(player.tower_floor), floor + 1)
					battle_system.add_log("获得 [color=yellow]%d[/color] 金币！（本地兜底）" % gold_reward)
					battle_system.add_log("[color=orange]天关金币/层数暂未与服务器同步：%s，已先本地结算继续挑战[/color]" % err_msg)
					if floor % 10 == 0:
						battle_system.add_log("[color=orange]天关每10关奖励以云端邮件为准，请稍后查收或重试同步[/color]")
					var fallback_gifts = []
					if floor % 100 == 0:
						var fallback_item_name = "%d关礼包" % floor
						fallback_gifts.append({"name": fallback_item_name, "count": 1})
						battle_system.add_log("[color=purple]★ 获得%s（本地邮件兜底） ★[/color]" % fallback_item_name)
					if fallback_gifts.size() > 0:
						_send_drop_items_to_mail("天关奖励", fallback_gifts, 0)
					tower_ok = true
					if network and network.is_logged_in() and err_msg.find("层数与服务器进度不符") != -1:
						network.get_tower_info()
		else:
			player.gold += gold_reward
			gold_changed.emit(player.gold)
			battle_system.add_log("获得 [color=yellow]%d[/color] 金币！" % gold_reward)
			if floor > player.tower_highest:
				player.tower_highest = floor
			player.tower_floor = floor + 1
			if floor % 10 == 0:
				battle_system.add_log("[color=orange]天关每10关奖励需登录后由服务器发放至云端邮件[/color]")
			var offline_gifts = []
			if floor % 100 == 0:
				var offline_item_name = "%d关礼包" % floor
				offline_gifts.append({"name": offline_item_name, "count": 1})
				battle_system.add_log("[color=purple]★ 获得%s（本地邮件） ★[/color]" % offline_item_name)
			if offline_gifts.size() > 0:
				_send_drop_items_to_mail("天关奖励", offline_gifts, 0)
			tower_ok = true


		player.heal_full()
		if active_pet:
			active_pet.heal_full()

		if tower_ok:
			applied_clear = true
			_sync_tower_progress(floor)
			if quest_manager:
				quest_manager.on_tower_completed(floor)
			if floor % 10 == 0:
				var announce_msg = "恭喜【%s】闯过天关第%d层！" % [player.player_name, floor]
				broadcast_event("tower", player.player_name, {"floor": floor}, announce_msg)
	else:

		player.heal_full()
		var active_pet = pet_manager.get_active_pet()
		if active_pet:
			active_pet.heal_full()


	if battle_system.battle_ended.is_connected(_on_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_tower_battle_ended)


	var was_victory = applied_clear if replay_mode else counted_win
	var should_stop = stop_tower_requested
	last_tower_fail_reason = ""
	if not was_victory:
		var fail_round_limit: = 0
		var fail_rounds: = 0
		if battle_system:
			fail_round_limit = int(battle_system.max_rounds)
			fail_rounds = int(battle_system.current_round)
		if should_stop:
			last_tower_fail_reason = "已停止挑战"
		elif counted_win and replay_mode and not applied_clear:
			last_tower_fail_reason = "通关未入账，请稍后重试"
		elif fail_round_limit > 0 and fail_rounds >= fail_round_limit:
			last_tower_fail_reason = "未能在%d回合内击败敌人" % fail_round_limit
		else:
			last_tower_fail_reason = "挑战失败"


	last_battle_was_tower = true
	last_battle_was_suit_dungeon = false


	is_tower_battle = false
	battle_system.max_rounds = -1


	stop_tower_requested = false


	save_game()


	battle_ended_ui.emit(was_victory)
	is_tower_settling = false


	if should_stop or not was_victory:
		_end_tower_run_session()
	elif was_victory and not should_stop:
		_auto_start_next_tower_in_manager(floor + 1)

func _auto_start_next_tower_in_manager(next_floor: int):
	print("[GameManager] _auto_start_next_tower_in_manager 被调用, next_floor=", next_floor)
	var open_cap: = get_tower_open_max_floor()
	if next_floor > open_cap:
		var cfg: = get_tower_runtime_config()
		var tmpl: = str(cfg.get("openMaxFloorAutoBattleMessage", "天关暂只开放至%d层，后续楼层敬请期待！"))
		var msg: = tmpl % open_cap if "%d" in tmpl else tmpl
		battle_system.add_log("[color=yellow]%s[/color]" % msg)
		_end_tower_run_session()
		return
	await get_tree().create_timer(0.6).timeout
	if stop_tower_requested:
		print("[GameManager] 天关连打已停止，不再自动进入下一层")
		_end_tower_run_session()
		return

	var is_cleared = next_floor <= player.tower_highest

	if not is_cleared:
		TowerUI.apply_runtime_config(get_tower_runtime_config())
		var required_rei: = TowerUI._required_reincarnation_for_floor(next_floor)
		if required_rei > 0:
			var player_rei: = int(player.reincarnation)
			if player_rei < required_rei:
				battle_system.add_log("[color=yellow]%s[/color]" % TowerUI._reincarnation_block_message(next_floor, player_rei, required_rei))
				_end_tower_run_session()
				return
		if player.gold < 1000000:
			battle_system.add_log("[color=red]金币不足100万，无法继续挑战！[/color]")
			_end_tower_run_session()
			return
		if not is_tower_replay_on():
			player.gold -= 1000000
			gold_changed.emit(player.gold)
			battle_system.add_log("[color=yellow]扣除100万金币，继续挑战第%d层[/color]" % next_floor)

	var monsters: Array = []
	if not is_tower_replay_on():
		monsters = _create_tower_monsters_for_auto(next_floor)
		print("[GameManager] 创建怪物数量: ", monsters.size(), " for floor ", next_floor)
		if monsters.is_empty():
			_end_tower_run_session()
			return
	var success = start_tower_battle(next_floor, monsters)
	print("[GameManager] start_tower_battle 返回: ", success)
	if not success:
		_end_tower_run_session()



func start_xianmo_mirror_battle(opponent_name: String, opponent_level: int, opponent_stats: Dictionary, score: int, event: Dictionary) -> bool:
	push_warning("[GameManager] start_xianmo_mirror_battle 已停用，仙魔战斗请使用服务端结算链路")
	print("[GameManager] deprecated_xianmo_client_battle_called opponent=", opponent_name, ", level=", opponent_level, ", score=", score, ", event_id=", str(event.get("event_id", "")), ", has_opponent_stats=", not opponent_stats.is_empty())
	return false

func _create_tower_monsters_for_auto(floor: int) -> Array:
	TowerUI.apply_runtime_config(get_tower_runtime_config())
	return TowerUI.create_tower_monsters(floor)


func start_suit_dungeon_battle(level: int, all_waves: Array) -> bool:
	if _is_other_instanced_battle_active("suit"):
		push_warning("套装副本：其他玩法战斗进行中，无法开战")
		return false
	if in_battle:
		if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			print("[GameManager] 套装副本：当前战斗进行中，无法开战")
			return false
		push_warning("检测到战斗状态不一致，强制重置")
		in_battle = false
		if battle_system:
			battle_system.current_state = battle_system.BattleState.IDLE
			battle_system.monsters.clear()
			battle_system.battle_log.clear()
			battle_system.suppress_battle_character_exp = false
		_disconnect_all_battle_ended_handlers()

	await _wait_field_replay_idle_async()


	stop_suit_dungeon_requested = false
	is_suit_dungeon_settling = false
	is_suit_dungeon_battle = true
	battle_system.suppress_battle_character_exp = false
	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	current_suit_dungeon_level = level
	current_suit_dungeon_wave = 1
	suit_dungeon_all_waves = all_waves

	_disconnect_all_battle_ended_handlers()
	battle_system.battle_ended.connect(_on_suit_dungeon_battle_ended)


	return await _start_suit_dungeon_wave(level, 1)


func _start_suit_dungeon_wave(level: int, wave: int) -> bool:
	if not is_suit_dungeon_battle or stop_suit_dungeon_requested:
		return false
	if wave > suit_dungeon_all_waves.size():

		await _on_suit_dungeon_all_waves_cleared()
		return true

	current_suit_dungeon_wave = wave
	var wave_monsters = suit_dungeon_all_waves[wave - 1]


	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	var active_pet = pet_manager.get_active_pet()
	if battle_system.start_battle(player, active_pet, wave_monsters, 20, false, resolve_attack_target_mode("suit_dungeon")):
		in_battle = true

		if wave == 1:
			suit_dungeon_battle_started.emit(level)
		else:
			suit_dungeon_wave_started.emit(level, wave)
		return true

	return false


func _is_server_truthy_suit(v: Variant) -> bool:
	return (typeof(v) == TYPE_BOOL and v) or (typeof(v) == TYPE_INT and int(v) != 0)

func _coerce_suit_drop_name_array(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for el in raw:
			var s: = str(el).strip_edges()
			if not s.is_empty():
				out.append(s)
	return out

func _apply_suit_clear_server_drops(d: Dictionary) -> void :
	last_suit_dungeon_drops = {"sealed_suits": [], "stones": []}
	var sealed: Array = []
	var stones: Array = []
	var drop_items_raw: Variant = null
	if d.has("dropItems"):
		drop_items_raw = d.get("dropItems")
	elif d.has("drop_items"):
		drop_items_raw = d.get("drop_items")
	if drop_items_raw is Array:
		for it in drop_items_raw:
			if it is Dictionary:
				var row: Dictionary = it
				var item_name: = str(row.get("name", "")).strip_edges()
				if item_name.is_empty():
					continue
				var item_type: = str(row.get("type", "")).strip_edges()
				if item_type == "stone" or item_name.ends_with("普通解封石"):
					stones.append(item_name)
				else:
					sealed.append(item_name)
	if sealed.is_empty() and stones.is_empty():
		sealed = _coerce_suit_drop_name_array(d.get("sealedSuitsDropped", d.get("sealed_suits_dropped", [])))
		stones = _coerce_suit_drop_name_array(d.get("stonesDropped", d.get("stones_dropped", [])))
	for suit_name in sealed:
		last_suit_dungeon_drops["sealed_suits"].append(str(suit_name))
		battle_system.add_log("[color=orange]★ 获得封印套装：%s ★[/color]" % str(suit_name))
		broadcast_event("suit_obtain", player.player_name, {"suit_name": str(suit_name)})
	for stone_name in stones:
		last_suit_dungeon_drops["stones"].append(str(stone_name))
		battle_system.add_log("[color=cyan]★ 获得 %s ★[/color]" % str(stone_name))
	if _is_server_truthy_suit(d.get("suitDropMailSent", false)) and MailManager.instance:
		MailManager.instance.refresh_mail_list()

func _on_suit_dungeon_all_waves_cleared() -> void :
	if not is_suit_dungeon_battle or stop_suit_dungeon_requested:
		return
	in_battle = false


	var level = current_suit_dungeon_level
	var exp_reward = 2000 * level


	if not battle_system.player_died_in_battle:
		var messages = player.add_exp(exp_reward)
		for msg in messages:
			battle_system.add_log(msg)
	else:
		battle_system.add_log("[color=gray]人物本场死亡，无法获得经验[/color]")


	var active_pet = pet_manager.get_active_pet()
	if active_pet:
		if not battle_system.pet_died_in_battle:
			var pet_exp_reward = _battle_pet_exp_with_player_multiplier(exp_reward)
			var pet_result = pet_manager.add_pet_exp(active_pet, pet_exp_reward, false)
			if pet_result.leveled_up:
				battle_system.add_log("[color=green]★ %s 升到 %d 级！★[/color]" % [active_pet.pet_name, active_pet.level])
		else:
			battle_system.add_log("[color=gray]宠物本场死亡，无法获得经验[/color]")

	last_suit_dungeon_drops = {"sealed_suits": [], "stones": []}
	last_suit_dungeon_clear_gold = -1
	var suit_ok: = false
	var clear_is_dup: = false
	if network and network.is_logged_in():
		var op_id: = "suit_clear_%s_%s_%s" % [str(level), str(Time.get_unix_time_from_system()), str(randi())]
		var er: Dictionary = await wait_economy("economy_suit_clear", func():
			network.economy_suit_dungeon_clear_reward(op_id, level)
		, op_id)
		if er.get("ok", false):
			var dvar: Variant = er.get("data", {})
			if dvar is Dictionary:
				var d: Dictionary = dvar
				clear_is_dup = _is_server_truthy_suit(d.get("duplicate", false))
				if clear_is_dup:
					battle_system.add_log("[color=gray]套装副本奖励已结算（重复请求）[/color]")
				else:
					if d.has("newGold"):
						player.gold = int(d.get("newGold", player.gold))
					last_suit_dungeon_clear_gold = int(d.get("goldGranted", -1))
					battle_system.add_log("获得 [color=yellow]%d[/color] 金币！" % last_suit_dungeon_clear_gold)
					if d.has("suitDungeonProgress"):
						player.suit_dungeon_progress = int(d.get("suitDungeonProgress", player.suit_dungeon_progress))
					_apply_suit_clear_server_drops(d)
				gold_changed.emit(player.gold)
				suit_ok = true
		else:
			battle_system.add_log("[color=orange]套装副本金币/进度未同步：%s[/color]" % str(er.get("err", "失败")))
	else:
		battle_system.add_log("[color=orange]未登录，套装副本奖励未结算[/color]")

	if suit_ok and not clear_is_dup:
		battle_system.add_log("[color=green]★ 套装副本第%d层通关！★[/color]" % level)
		if level % 5 == 0:
			broadcast_event("suit_dungeon_clear", player.player_name, {"level": level})


	player.heal_full()
	if active_pet:
		active_pet.heal_full()


	if battle_system.battle_ended.is_connected(_on_suit_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_suit_dungeon_battle_ended)


	battle_ended_ui.emit(true)
	suit_dungeon_battle_ended.emit(true, level)


	is_suit_dungeon_battle = false
	battle_system.max_rounds = -1
	suit_dungeon_all_waves.clear()
	resume_field_auto_battle_after_instanced_challenge()

func _end_suit_dungeon_failed() -> void :
	if not is_suit_dungeon_battle:
		stop_suit_dungeon_requested = false
		is_suit_dungeon_settling = false
		return
	var level = current_suit_dungeon_level
	in_battle = false
	stop_suit_dungeon_requested = false
	is_suit_dungeon_settling = false
	battle_system.add_log("[color=red]挑战失败！请提升实力后再来挑战。[/color]")
	player.heal_full()
	var active_pet = pet_manager.get_active_pet()
	if active_pet:
		active_pet.heal_full()
	if battle_system.battle_ended.is_connected(_on_suit_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_suit_dungeon_battle_ended)
	battle_ended_ui.emit(false)
	suit_dungeon_battle_ended.emit(false, level)
	is_suit_dungeon_battle = false
	battle_system.max_rounds = -1
	suit_dungeon_all_waves.clear()
	save_game()
	resume_field_auto_battle_after_instanced_challenge()

func _on_suit_dungeon_battle_ended(victory: bool):
	if not is_suit_dungeon_battle or is_suit_dungeon_settling:
		return
	if not victory:
		_end_suit_dungeon_failed()
		return


	var should_stop = stop_suit_dungeon_requested
	var next_wave = current_suit_dungeon_wave + 1
	if next_wave <= suit_dungeon_all_waves.size():
		if should_stop:
			_end_suit_dungeon_failed()
			return

		is_suit_dungeon_settling = true
		battle_system.add_log("[color=green]★ 第%d波通关！准备进入第%d波... ★[/color]" % [current_suit_dungeon_wave, next_wave])


		player.heal_full()
		var active_pet = pet_manager.get_active_pet()
		if active_pet:
			active_pet.heal_full()


		await get_tree().create_timer(1.0).timeout
		is_suit_dungeon_settling = false
		if not is_suit_dungeon_battle or stop_suit_dungeon_requested or should_stop:
			if is_suit_dungeon_battle:
				_end_suit_dungeon_failed()
			return
		await _start_suit_dungeon_wave(current_suit_dungeon_level, next_wave)
	else:

		if should_stop or stop_suit_dungeon_requested:
			_end_suit_dungeon_failed()
			return
		stop_suit_dungeon_requested = false
		await _on_suit_dungeon_all_waves_cleared()

		save_game()



const ATLAS_DUNGEON_MAP_NAME: = "图鉴副本"
const ATLAS_DUNGEON_TIER_KEYS: = ["basic", "medium", "advanced"]
# 三档兜底波数：服务端回包和运行时配置都拿不到时按档位取，绝不能让中/高档退回 20 波
const ATLAS_DUNGEON_FALLBACK_WAVES: = {"basic": 20, "medium": 100, "advanced": 200}

func sync_atlas_dungeon_start_from_server(data: Dictionary, start_operation_id: String = "") -> void :
	if player == null or data == null or data.is_empty():
		return
	if not start_operation_id.is_empty():
		current_atlas_dungeon_start_op_id = start_operation_id
	# 服务端 /atlas-dungeon/start 回包已带本档 waveCount/monstersPerWave/monsterLevel，优先用它，
	# 避免运行时配置还没落地时按 20 波开打
	var srv_waves: = int(data.get("waveCount", 0))
	var srv_per_wave: = int(data.get("monstersPerWave", 0))
	var srv_level: = int(data.get("monsterLevel", 0))
	_atlas_start_wave_count = srv_waves if srv_waves > 0 else 0
	_atlas_start_monsters_per_wave = srv_per_wave if srv_per_wave > 0 else 0
	_atlas_start_monster_level = srv_level if srv_level > 0 else 0
	if data.has("newGold"):
		player.gold = maxi(0, int(data.get("newGold", player.gold)))
		gold_changed.emit(player.gold)
	var ts: = float(data.get("playerTimestamp", 0))
	if ts > 0.0:
		_last_local_save_timestamp = max(_last_local_save_timestamp, ts)
		_suppress_general_cloud_upload_until_ms = maxi(
			_suppress_general_cloud_upload_until_ms, 
			Time.get_ticks_msec() + 6000
		)
	save_game(false)

func _build_atlas_dungeon_pet_pool() -> Array:
	var pool: Array = []
	if pet_manager == null:
		return pool
	for pet_id in GameData.PET_DATA:
		if pet_manager.is_event_limited_pet_id(str(pet_id)):
			continue
		pool.append(str(pet_id))
	return pool

func create_atlas_dungeon_monsters(tier: String) -> Array:
	var tier_cfg: = get_atlas_dungeon_tier_config(tier)
	var wave_count: = int(tier_cfg.get("waveCount", 0))
	var per_wave: = int(tier_cfg.get("monstersPerWave", 0))
	var monster_level: = int(tier_cfg.get("monsterLevel", 0))
	# 优先级：服务端 start 回包 > 运行时配置 > 按档位兜底（20/100/200）
	if wave_count <= 0:
		wave_count = _atlas_start_wave_count
	if per_wave <= 0:
		per_wave = _atlas_start_monsters_per_wave
	if monster_level <= 0:
		monster_level = _atlas_start_monster_level
	if wave_count <= 0:
		wave_count = int(ATLAS_DUNGEON_FALLBACK_WAVES.get(tier, 20))
	if per_wave <= 0:
		per_wave = 5
	if monster_level <= 0:
		monster_level = 100
	var pool: = _build_atlas_dungeon_pet_pool()
	if pool.is_empty():
		return []
	var cfg: = get_atlas_dungeon_runtime_config()
	var max_rounds: = int(cfg.get("battleMaxRounds", 20))
	max_rounds = maxi(1, max_rounds)
	var all_waves: Array = []
	for _w in range(wave_count):
		var wave_monsters: Array = []
		for _i in range(per_wave):
			var pet_id: String = pool[randi() % pool.size()]
			var gen: Dictionary = MonsterGenerator.generate_monster(pet_id, monster_level)
			if gen.is_empty():
				continue
			gen["exp_reward"] = 0
			gen["gold_reward"] = 0
			var monster = Monster.create_from_template(gen)
			wave_monsters.append(monster)
		if not wave_monsters.is_empty():
			all_waves.append(wave_monsters)
	return all_waves

func start_atlas_dungeon_battle(tier: String, all_waves: Array) -> bool:
	if _is_other_instanced_battle_active("atlas"):
		push_warning("图鉴副本：其他玩法战斗进行中，无法开战")
		return false
	if in_battle:
		if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			print("[GameManager] 图鉴副本：当前战斗进行中，无法开战")
			return false
		push_warning("检测到战斗状态不一致，强制重置")
		in_battle = false
		is_atlas_dungeon_battle = false
		if battle_system:
			battle_system.current_state = battle_system.BattleState.IDLE
			battle_system.monsters.clear()
			battle_system.battle_log.clear()
			battle_system.suppress_battle_character_exp = false
		_disconnect_all_battle_ended_handlers()
	if all_waves.is_empty():
		return false
	await _wait_field_replay_idle_async()
	stop_atlas_dungeon_requested = false
	is_atlas_dungeon_settling = false
	is_atlas_dungeon_battle = true
	atlas_dungeon_defeated_pet_ids.clear()
	battle_system.suppress_battle_character_exp = true
	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	current_atlas_dungeon_tier = tier
	current_atlas_dungeon_wave = 1
	atlas_dungeon_all_waves = all_waves
	atlas_dungeon_session_captures = 0
	atlas_dungeon_session_atlas = 0
	atlas_dungeon_session_discarded = 0
	var cfg: = get_atlas_dungeon_runtime_config()
	var max_rounds: = int(cfg.get("battleMaxRounds", 20))
	battle_system.max_rounds = maxi(1, max_rounds)
	_disconnect_all_battle_ended_handlers()
	battle_system.battle_ended.connect(_on_atlas_dungeon_battle_ended)
	return await _start_atlas_dungeon_wave(1)

func _start_atlas_dungeon_wave(wave: int) -> bool:
	if is_tower_battle or is_tower_settling or is_tower_run_active:
		push_warning("[AtlasDungeon] 天关进行中，中止图鉴下一波")
		_end_atlas_dungeon_failed()
		return false
	if wave > atlas_dungeon_all_waves.size():
		await _on_atlas_dungeon_all_waves_cleared()
		return true
	current_atlas_dungeon_wave = wave
	var wave_monsters = atlas_dungeon_all_waves[wave - 1]
	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	var active_pet = pet_manager.get_active_pet()
	if not active_pet:
		return false
	if battle_system.start_battle(player, active_pet, wave_monsters, battle_system.max_rounds, false, resolve_attack_target_mode("atlas_dungeon")):
		in_battle = true
		var total_waves: = atlas_dungeon_all_waves.size()
		if wave == 1:
			atlas_dungeon_battle_started.emit(current_atlas_dungeon_tier)
		else:
			atlas_dungeon_wave_started.emit(current_atlas_dungeon_tier, wave, total_waves)
		return true
	return false

func _try_atlas_dungeon_wave_captures() -> void :
	for i in range(battle_system.monsters.size()):
		var monster = battle_system.monsters[i]
		if monster == null or monster.hp > 0:
			continue
		var result: = try_capture_monster(i, ATLAS_DUNGEON_MAP_NAME)
		if result.success:
			atlas_dungeon_session_captures += 1
			var msg: String = str(result.get("message", ""))
			if msg.contains("图鉴"):
				atlas_dungeon_session_atlas += 1
			battle_system.add_log("[color=purple]%s[/color]" % msg)
		else:
			var msg2: String = str(result.get("message", ""))
			if msg2.contains("丢弃") or msg2.contains("已满") or msg2.contains("逃跑"):
				atlas_dungeon_session_discarded += 1
			if not msg2.is_empty() and not msg2.contains("逃跑"):
				battle_system.add_log("[color=gray]%s[/color]" % msg2)

func _record_atlas_dungeon_wave_defeats() -> void :
	for monster in battle_system.monsters:
		if monster == null:
			continue
		var pet_id: = str(monster.get_drop_pet_id()).strip_edges()
		if not pet_id.is_empty():
			atlas_dungeon_defeated_pet_ids.append(pet_id)

func _on_atlas_dungeon_all_waves_cleared() -> void :
	in_battle = false
	var tier: = current_atlas_dungeon_tier
	var defeated: = atlas_dungeon_defeated_pet_ids.duplicate()
	var start_op: = current_atlas_dungeon_start_op_id
	if network and network.is_logged_in() and not start_op.is_empty():
		var finish_op: = "%s:finish" % start_op
		var waves_done: = atlas_dungeon_all_waves.size()
		var er: Dictionary = await wait_economy("atlas_dungeon_finish", func():
			network.atlas_dungeon_finish(tier, finish_op, start_op, defeated, min_growth_threshold, waves_done)
		, finish_op)
		if bool(er.get("ok", false)):
			var data_var: Variant = er.get("data", {})
			if data_var is Dictionary:
				var data: Dictionary = data_var
				var save_var: Variant = data.get("saveData", null)
				if save_var is Dictionary and not (save_var as Dictionary).is_empty():
					apply_cloud_save(save_var, {"pets_authoritative": true})
				var summary_var: Variant = data.get("summary", {})
				if summary_var is Dictionary:
					var summary: Dictionary = summary_var
					var roster_n: = int(summary.get("rosterCount", summary.get("successCount", 0)))
					var atlas_n: = int(summary.get("atlasCount", 0))
					var discard_n: = int(summary.get("discardedCount", 0))
					atlas_dungeon_session_captures = roster_n + atlas_n
					atlas_dungeon_session_atlas = atlas_n
					atlas_dungeon_session_discarded = discard_n
	var label: = get_atlas_dungeon_tier_label(tier)
	battle_system.add_log("[color=green]★ 图鉴副本(%s)通关！捕捉 %d 只（图鉴 %d）★[/color]" % [
		label, atlas_dungeon_session_captures, atlas_dungeon_session_atlas
	])
	player.heal_full()
	var active_pet = pet_manager.get_active_pet()
	if active_pet:
		active_pet.heal_full()
	if battle_system.battle_ended.is_connected(_on_atlas_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_atlas_dungeon_battle_ended)
	battle_ended_ui.emit(true)
	atlas_dungeon_battle_ended.emit(true, tier)
	is_atlas_dungeon_battle = false
	is_atlas_dungeon_settling = false
	battle_system.max_rounds = -1
	atlas_dungeon_all_waves.clear()
	save_game()
	resume_field_auto_battle_after_instanced_challenge()

func _end_atlas_dungeon_failed() -> void :
	if not is_atlas_dungeon_battle:
		stop_atlas_dungeon_requested = false
		is_atlas_dungeon_settling = false
		return
	var tier: = current_atlas_dungeon_tier
	in_battle = false
	stop_atlas_dungeon_requested = false
	is_atlas_dungeon_settling = false
	battle_system.add_log("[color=red]图鉴副本挑战失败！金币不退，请提升实力后再来。[/color]")
	player.heal_full()
	var active_pet = pet_manager.get_active_pet()
	if active_pet:
		active_pet.heal_full()
	if battle_system.battle_ended.is_connected(_on_atlas_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_atlas_dungeon_battle_ended)
	battle_ended_ui.emit(false)
	atlas_dungeon_battle_ended.emit(false, tier)
	is_atlas_dungeon_battle = false
	battle_system.max_rounds = -1
	atlas_dungeon_all_waves.clear()
	save_game()
	resume_field_auto_battle_after_instanced_challenge()

func force_stop_atlas_dungeon_battle() -> void :
	if not is_atlas_dungeon_battle:
		return
	stop_atlas_dungeon_requested = true
	if battle_system:
		battle_system.drive_by_execute_turn = false
		if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			battle_system.force_end_battle(false)
		elif not is_atlas_dungeon_settling:
			_end_atlas_dungeon_failed()

func _on_atlas_dungeon_battle_ended(victory: bool) -> void :
	if not is_atlas_dungeon_battle or is_atlas_dungeon_settling:
		return
	if not victory:
		_end_atlas_dungeon_failed()
		return
	_record_atlas_dungeon_wave_defeats()
	var should_stop: = stop_atlas_dungeon_requested
	var next_wave: = current_atlas_dungeon_wave + 1
	if next_wave <= atlas_dungeon_all_waves.size():
		if should_stop:
			_end_atlas_dungeon_failed()
			return
		is_atlas_dungeon_settling = true
		var label: = get_atlas_dungeon_tier_label(current_atlas_dungeon_tier)
		battle_system.add_log("[color=green]★ 图鉴副本(%s) 第%d波通关！准备进入第%d波... ★[/color]" % [
			label, current_atlas_dungeon_wave, next_wave
		])
		player.heal_full()
		var active_pet = pet_manager.get_active_pet()
		if active_pet:
			active_pet.heal_full()
		await get_tree().create_timer(1.0).timeout
		is_atlas_dungeon_settling = false
		if not is_atlas_dungeon_battle or stop_atlas_dungeon_requested or should_stop:
			if is_atlas_dungeon_battle:
				_end_atlas_dungeon_failed()
			return
		if not await _start_atlas_dungeon_wave(next_wave):
			push_warning("[AtlasDungeon] 下一波开始失败 wave=%d tier=%s" % [next_wave, current_atlas_dungeon_tier])
			_end_atlas_dungeon_failed()
	else:
		if should_stop or stop_atlas_dungeon_requested:
			_end_atlas_dungeon_failed()
			return
		stop_atlas_dungeon_requested = false
		await _on_atlas_dungeon_all_waves_cleared()



func _create_five_elements_dungeon_monsters(element: String, difficulty: String) -> Array:
	var monster_element: = str(GameData.ELEMENT_COUNTER.get(element, element))
	var mcfg: = _get_fe_monster_cfg()
	var per_wave: = int(mcfg.get("monstersPerWave", 5))
	var growth: = float(mcfg.get("growth", 100.0))
	var hp_factor: = float(mcfg.get("hpFactor", 2.0))
	per_wave = maxi(1, per_wave)
	var level_list = _get_fe_levels(difficulty)
	var all_waves: Array = []
	var candidates: Array = []
	for pet_id in GameData.PET_DATA:
		var pet = GameData.PET_DATA[pet_id]
		if pet.get("element", "") == monster_element and not pet.get("is_event_limited", false):
			candidates.append({"id": pet_id, "data": pet})
	if candidates.is_empty():
		for pet_id in GameData.PET_DATA:
			var pet = GameData.PET_DATA[pet_id]
			if not pet.get("is_event_limited", false):
				candidates.append({"id": pet_id, "data": pet})

	for wave_level in level_list:
		var wave_monsters: Array = []
		candidates.shuffle()
		for i in range(mini(per_wave, candidates.size())):
			var entry = candidates[i]
			var pet = entry["data"]
			var ratio: Array = pet.get("ratio", [33, 33, 34])
			var monster_data: = {
				"name": str(pet.get("name", "怪物")), 
				"level": wave_level, 
				"element": monster_element, 
				"attack": int(growth * (float(ratio[0]) / 100.0) * wave_level), 
				"defense": int(growth * (float(ratio[1]) / 100.0) * wave_level), 
				"agility": int(growth * (float(ratio[2]) / 100.0) * wave_level), 
				"hp": int(growth * hp_factor * wave_level), 
				"exp_reward": 0, 
				"gold_reward": 0, 
				"pet_id": str(entry["id"]), 
			}
			var monster = Monster.create_from_template(monster_data)
			wave_monsters.append(monster)
		all_waves.append(wave_monsters)
	return all_waves

func _roll_fe_reward_name(difficulty: String, element: String) -> String:
	var limit_equips: = ["极限武器", "极限衣服", "极限鞋子", "极限血佩", "极限内带"]
	var roll: = randf()
	if roll < 0.05: return "%s宠物转生令牌" % element
	roll -= 0.05
	if roll < 0.1: return "%s属性宠物蛋" % element
	roll -= 0.1
	if roll < 0.02: return limit_equips[randi() % 5]
	roll -= 0.02
	if roll < 0.4: return "10亿金币"
	roll -= 0.4
	if roll < 0.42: return "5亿金币"
	roll -= 0.42
	var skills: = ["溅墨lv1技能书", "连击lv1技能书", "反打lv1技能书", "护主lv1技能书"]
	return skills[randi() % 4]

func _fe_default_levels(difficulty: String) -> Array:
	match difficulty:
		"简单": return [500, 800, 1200]
		"困难": return [2500, 3000, 3500]
		"地狱": return [4000, 5000, 6000]
	return [500, 1000, 1500]

func _get_fe_wave_levels_raw(difficulty: String, mcfg: Dictionary) -> Array:
	var wl = mcfg.get("waveLevels", {})
	if wl is Dictionary:
		var key_map: = {"简单": "simple", "困难": "normal", "地狱": "hard"}
		var k: String = str(key_map.get(difficulty, "simple"))
		var levels = wl.get(k, [])
		if levels is Array and levels.size() > 0:
			var out: Array = []
			for lv in levels:
				out.append(maxi(1, int(lv)))
			return out
	return []

func _expand_fe_wave_levels(base_levels: Array, wave_count: int) -> Array:
	var count: = maxi(1, wave_count)
	if base_levels.is_empty():
		return []
	if base_levels.size() == count:
		return base_levels.duplicate()
	if base_levels.size() == 1:
		var single: Array = []
		var lv: = maxi(1, int(base_levels[0]))
		for _i in range(count):
			single.append(lv)
		return single
	var first: = maxi(1, int(base_levels[0]))
	var last: = maxi(1, int(base_levels[base_levels.size() - 1]))
	var out: Array = []
	for i in range(count):
		if count == 1:
			out.append(first)
		else:
			var t: float = float(i) / float(count - 1)
			out.append(int(first + (last - first) * t))
	return out

func _get_fe_levels(difficulty: String) -> Array:
	var mcfg: = _get_fe_monster_cfg()
	var base_levels: = _get_fe_wave_levels_raw(difficulty, mcfg)
	if base_levels.is_empty():
		base_levels = _fe_default_levels(difficulty)
	var wave_count: = int(mcfg.get("waveCount", base_levels.size()))
	return _expand_fe_wave_levels(base_levels, wave_count)

func get_fe_wave_display_text(difficulty: String) -> String:
	var mcfg: = _get_fe_monster_cfg()
	var levels: = _get_fe_levels(difficulty)
	var per_wave: = maxi(1, int(mcfg.get("monstersPerWave", 5)))
	var wave_count: = levels.size()
	if wave_count <= 0:
		return "%d波×%d只" % [maxi(1, int(mcfg.get("waveCount", 3))), per_wave]
	var min_lv: = int(levels[0])
	var max_lv: = int(levels[0])
	for lv in levels:
		min_lv = mini(min_lv, int(lv))
		max_lv = maxi(max_lv, int(lv))
	if min_lv == max_lv:
		return "%d级（%d波×%d只）" % [min_lv, wave_count, per_wave]
	return "%d-%d级（%d波×%d只）" % [min_lv, max_lv, wave_count, per_wave]

var is_five_elements_battle: bool = false
var is_fe_settling: bool = false
var stop_fe_dungeon_requested: bool = false
var current_fe_element: String = ""
var current_fe_difficulty: String = ""
var current_fe_is_yuanbao: bool = false
var current_fe_session_id: String = ""
var fe_dungeon_waves: Array = []
var current_fe_wave: int = 1

signal five_elements_dungeon_battle_started(element: String, difficulty: String)
signal five_elements_dungeon_wave_started(level: int, wave: int)
signal five_elements_dungeon_battle_ended(victory: bool)
var fe_last_reward: String = ""
var fe_last_reward_gold: int = 0
var fe_last_reward_mail_sent: bool = false
var fe_last_clear_duplicate: bool = false
var fe_last_clear_sync_failed: bool = false

func sync_fe_dungeon_start_from_server(data: Dictionary) -> void :
	if player == null or data == null or data.is_empty():
		return
	if data.has("newCultivation"):
		var new_cult: = maxi(0, int(data.get("newCultivation", player.cultivation)))
		if new_cult != player.cultivation:
			player.cultivation = new_cult
			cultivation_changed.emit(player.cultivation)
	if data.has("newYuanbao"):
		player.yuanbao_currency = maxi(0, int(data.get("newYuanbao", player.yuanbao_currency)))
		yuanbao_changed.emit(player.yuanbao_currency)
	if data.has("yuanbaoRemaining") or data.has("yuanbaoMaxAttempts"):
		var max_yb: = maxi(1, int(data.get("yuanbaoMaxAttempts", 1)))
		var yb_rem: = maxi(0, int(data.get("yuanbaoRemaining", max_yb)))
		player.fe_yuanbao_attempts = clampi(max_yb - yb_rem, 0, max_yb)
		player.fe_yuanbao_attempts_date = Time.get_date_string_from_system()
	if data.has("sessionId"):
		current_fe_session_id = str(data.get("sessionId", "")).strip_edges()
	var ts: = float(data.get("playerTimestamp", 0))
	if ts > 0.0:
		_last_local_save_timestamp = max(_last_local_save_timestamp, ts)
	_suppress_general_cloud_upload_until_ms = maxi(
		_suppress_general_cloud_upload_until_ms, 
		Time.get_ticks_msec() + 120000
	)
	save_game(false)

func start_five_elements_dungeon_battle(element: String, difficulty: String, all_waves: Array, is_yuanbao: bool = false) -> bool:
	if _is_other_instanced_battle_active("five_elements"):
		push_warning("五行副本：其他玩法战斗进行中，无法开战")
		return false
	if in_battle:
		if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			return false
		in_battle = false
		if battle_system:
			battle_system.current_state = battle_system.BattleState.IDLE
			battle_system.monsters.clear()
			battle_system.battle_log.clear()
		_disconnect_all_battle_ended_handlers()
	battle_system.suppress_battle_character_exp = true
	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	is_five_elements_battle = true
	is_fe_settling = false
	stop_fe_dungeon_requested = false
	current_fe_element = element
	current_fe_difficulty = difficulty
	current_fe_is_yuanbao = is_yuanbao
	fe_dungeon_waves = all_waves
	current_fe_wave = 1

	_disconnect_all_battle_ended_handlers()
	battle_system.battle_ended.connect(_on_fe_battle_ended)

	five_elements_dungeon_battle_started.emit(element, difficulty)
	return _start_fe_wave(1)

func _start_fe_wave(wave: int) -> bool:
	if wave > fe_dungeon_waves.size():
		_on_fe_all_waves_cleared()
		return true
	current_fe_wave = wave
	var wave_monsters = fe_dungeon_waves[wave - 1]
	var mcfg: = _get_fe_monster_cfg()
	var max_rounds: = int(mcfg.get("battleMaxRounds", 30))
	max_rounds = maxi(1, max_rounds)
	battle_system.max_rounds = max_rounds

	var active_pet = pet_manager.get_active_pet()
	if not active_pet:
		push_warning("[FiveElements] 无出战宠物")
		return false
	_clear_leftover_replay_for_local_combat()
	if battle_system.start_battle(player, active_pet, wave_monsters, max_rounds, false, resolve_attack_target_mode("five_elements")):
		in_battle = true
		five_elements_dungeon_wave_started.emit(wave_monsters[0].level if wave_monsters.size() > 0 else 0, wave)
		return true
	return false

func _on_fe_battle_ended(victory: bool) -> void :
	if not is_five_elements_battle or is_fe_settling:
		return

	if not victory:
		_end_fe_dungeon_failed()
		return

	var next_wave: = current_fe_wave + 1
	if next_wave <= fe_dungeon_waves.size():
		is_fe_settling = true
		battle_system.add_log("[color=green]★ 第%d波通关！准备进入第%d波... ★[/color]" % [current_fe_wave, next_wave])
		var active_pet = pet_manager.get_active_pet()
		if active_pet:
			active_pet.heal_full()
		if player:
			player.heal_full()
		await get_tree().create_timer(1.0).timeout
		is_fe_settling = false
		if not is_five_elements_battle or stop_fe_dungeon_requested:
			if is_five_elements_battle:
				_end_fe_dungeon_failed()
			return
		_start_fe_wave(next_wave)
		return

	if battle_system.battle_ended.is_connected(_on_fe_battle_ended):
		battle_system.battle_ended.disconnect(_on_fe_battle_ended)
	await _on_fe_all_waves_cleared()

func _end_fe_dungeon_failed() -> void :
	if not is_five_elements_battle:
		stop_fe_dungeon_requested = false
		return
	if battle_system.battle_ended.is_connected(_on_fe_battle_ended):
		battle_system.battle_ended.disconnect(_on_fe_battle_ended)
	is_five_elements_battle = false
	is_fe_settling = false
	in_battle = false
	stop_fe_dungeon_requested = false
	fe_last_reward = ""
	fe_last_reward_gold = 0
	fe_last_reward_mail_sent = false
	fe_last_clear_duplicate = false
	fe_last_clear_sync_failed = false
	current_fe_session_id = ""
	var msg: String = "💪 【%s】挑战%s难度五行副本(%s)失败，但勇气可嘉，下次再战！" % [player.player_name, current_fe_difficulty, current_fe_element]
	broadcast_event("fe_dungeon_fail", player.player_name, {"element": current_fe_element, "difficulty": current_fe_difficulty}, msg)
	five_elements_dungeon_battle_ended.emit(false)
	save_game()
	resume_field_auto_battle_after_instanced_challenge()

func force_stop_fe_dungeon_battle() -> void :
	if not is_five_elements_battle:
		return
	stop_fe_dungeon_requested = true
	if battle_system:
		battle_system.drive_by_execute_turn = false
		if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
			battle_system.force_end_battle(false)
		elif not is_fe_settling:
			_end_fe_dungeon_failed()

func _on_fe_all_waves_cleared() -> void :
	is_five_elements_battle = false
	is_fe_settling = true
	stop_fe_dungeon_requested = false
	in_battle = false
	fe_last_reward = ""
	fe_last_reward_gold = 0
	fe_last_reward_mail_sent = false
	fe_last_clear_duplicate = false
	fe_last_clear_sync_failed = false

	var element: = current_fe_element
	var difficulty: = current_fe_difficulty
	var clear_ok: = false

	if network and network.is_logged_in():
		var op_id: = "fe_clear_%s_%d_%d" % [element, Time.get_unix_time_from_system(), randi()]
		var session_id: = current_fe_session_id.strip_edges()
		var er: Dictionary = await wait_economy("fe_dungeon_clear", func():
			network.fe_dungeon_clear_reward(element, difficulty, op_id, current_fe_is_yuanbao, op_id, session_id)
		, op_id)
		if er.get("ok", false):
			var dvar: Variant = er.get("data", {})
			if dvar is Dictionary:
				var d: Dictionary = dvar
				if _is_server_truthy_suit(d.get("duplicate", false)):
					fe_last_clear_duplicate = true
					fe_last_reward = "奖励已领取"
					clear_ok = true
				else:
					var reward_var: Variant = d.get("reward", {})
					if reward_var is Dictionary:
						var reward: Dictionary = reward_var
						fe_last_reward = str(reward.get("name", ""))
						fe_last_reward_gold = int(reward.get("gold", 0))
					fe_last_reward_mail_sent = bool(d.get("mailSent", fe_last_reward_gold == 0))
					if d.has("newGold"):
						player.gold = int(d.get("newGold", player.gold))
					elif fe_last_reward_gold > 0:
						player.gold += fe_last_reward_gold
					gold_changed.emit(player.gold)
					if fe_last_reward_mail_sent and MailManager.instance:
						MailManager.instance.refresh_mail_list()
					var ts: = float(d.get("playerTimestamp", 0))
					if ts > 0.0:
						_last_local_save_timestamp = max(_last_local_save_timestamp, ts)
					clear_ok = true
		else:
			fe_last_clear_sync_failed = true
			if battle_system:
				battle_system.add_log("[color=orange]五行副本通关，但奖励同步失败：%s[/color]" % str(er.get("err", "未知错误")))
	else:
		fe_last_clear_sync_failed = true
		if battle_system:
			battle_system.add_log("[color=orange]未登录，五行副本奖励未结算[/color]")

	if clear_ok and not fe_last_clear_duplicate and not fe_last_reward.is_empty():
		var msg: String = "☯️ 【%s】历经苦战，通过%s难度五行副本(%s)，获得【%s】！" % [player.player_name, difficulty, element, fe_last_reward]
		broadcast_event("fe_dungeon_clear", player.player_name, {"element": element, "difficulty": difficulty}, msg)
		if battle_system:
			if fe_last_reward_gold > 0:
				battle_system.add_log("[color=yellow]★ 五行副本通关！获得 %s 金币已入账 ★[/color]" % fe_last_reward)
			else:
				battle_system.add_log("[color=green]★ 五行副本通关！获得【%s】，请查收邮件 ★[/color]" % fe_last_reward)
	elif fe_last_clear_duplicate and battle_system:
		battle_system.add_log("[color=gray]五行副本奖励已领取（重复请求）[/color]")

	current_fe_session_id = ""
	is_fe_settling = false
	five_elements_dungeon_battle_ended.emit(true)
	save_game()
	resume_field_auto_battle_after_instanced_challenge()

func _sync_tower_progress(floor: int):

	if network and network.is_logged_in():
		network.update_tower_highest(floor)


func _try_auto_capture():

	var capturable_monsters = []
	for i in range(battle_system.monsters.size()):
		var monster = battle_system.monsters[i]
		if _monster_is_wild_capturable(monster):
			capturable_monsters.append(i)

	if capturable_monsters.is_empty():
		battle_system.add_log("[color=gray]没有可捕捉的怪物[/color]")
		return




	var target_index = capturable_monsters[randi() % capturable_monsters.size()]
	var result = try_capture_monster(target_index)

	if result.success:
		battle_system.add_log("[color=purple]%s[/color]" % result.message)
	else:
		battle_system.add_log("[color=gray]%s[/color]" % result.message)

func _find_pet_data_by_name(pet_name: String) -> Dictionary:
	for pet_id in GameData.PET_DATA:
		var pet_data = GameData.PET_DATA[pet_id]
		if pet_data.get("name", "") == pet_name:
			return pet_data
	return {}


func try_capture_monster(monster_index: int, map_name_override: String = "") -> Dictionary:
	var result = {"success": false, "message": ""}

	if monster_index < 0 or monster_index >= battle_system.monsters.size():
		result.message = "无效的怪物索引！"
		return result

	var monster = battle_system.monsters[monster_index]


	var pet_id = monster.get_drop_pet_id()
	if pet_id.is_empty():
		result.message = "该怪物无法被捕捉！(怪物ID: %s)" % monster.monster_id
		return result


	var pet_data = GameData.PET_DATA.get(pet_id, {})
	if pet_data.is_empty():
		result.message = "找不到宠物数据！(宠物ID: %s)" % pet_id
		return result

	var map_name: = map_name_override if not map_name_override.is_empty() else current_map


	var capture_result = pet_manager.capture_from_monster({
		"name": pet_data.get("name", "未知宠物"), 
		"element": pet_data.get("element", "普通"), 
		"type": pet_data.get("type", "普通型"), 
		"pet_id": pet_id
	}, map_name, min_growth_threshold)

	if capture_result.success:
		result.success = true
		result.message = capture_result.message
		result.pet = capture_result.pet
	else:
		result.message = capture_result.message

	return result


func create_offline_pet(map_name: String) -> Dictionary:
	var result = {"success": false, "message": "", "pet_name": "", "growth": 0.0}


	var map_data = GameData.MAPS_DATA.get(map_name, {})
	if map_data.is_empty():
		result.message = "无效的地图：%s" % map_name
		return result


	var monsters = map_data.get("monsters", [])
	if monsters.is_empty():
		result.message = "该地图没有可捕捉的怪物"
		return result


	var random_monster = monsters[randi() % monsters.size()]
	var pet_id = random_monster.get("pet_id", random_monster.get("id", ""))

	if pet_id.is_empty():
		result.message = "无法获取宠物ID"
		return result


	var pet_info = GameData.PET_DATA.get(pet_id, {})
	if pet_info.is_empty():
		result.message = "未找到宠物数据：%s" % pet_id
		return result


	var pet = load("res://scripts/pet.gd").create_from_data(pet_info, map_name, true, pet_id)


	if pet_manager.add_pet(pet):
		result.success = true
		result.pet_name = pet.pet_name
		result.growth = pet.total_growth
	else:
		result.message = "添加宠物失败"
		return result

	return result


var last_save_time: float = 0.0

var _last_local_save_timestamp: float = 0.0
var _cloud_save_revision: int = 0
var save_version: int = 2
const SAVE_HASH_KEY = "huanling_save_2024"
const SAVE_FILE_NAME = "user://save_game.dat"
const SAVE_FILE_BACKUP = "user://save_game_backup.dat"
const SAVE_FILE_TEMPLATE = "user://save_game_u%d.dat"
const SAVE_FILE_BACKUP_TEMPLATE = "user://save_game_backup_u%d.dat"
const SAVE_FILE_TEMP_TEMPLATE = "user://save_game_temp_u%d.dat"

const DEFAULT_VALUES = {
	"current_map": "浮影水城外郊（0,0）", 
	"auto_capture_enabled": true, 
	"min_growth_threshold": 0.0, 
	"auto_change_map_enabled": false, 
	"previous_map": "", 
	"auto_change_map_consecutive_wins": 0, 
	"auto_change_map_consecutive_deaths": 0, 
	"auto_change_map_upgrade_cooldown": 0.0, 
	"bgm_enabled": true, 
	"bgm_volume": 0.5
}

static func _get_save_password() -> String:
	var base_key = "HL2024_SAVE_KEY_"
	var version_part = str(2)
	var hash_part = str("huanling".hash()).substr(0, 8)
	return base_key + version_part + "_" + hash_part

func _get_save_slot_user_id() -> int:
	if network != null:
		var uid_raw = network.get("user_id")
		if uid_raw != null:
			var uid: = int(uid_raw)
			if uid > 0:
				return uid
	return 0

func _get_active_save_file_name() -> String:
	var uid: = _get_save_slot_user_id()
	if uid > 0:
		return SAVE_FILE_TEMPLATE % uid
	return SAVE_FILE_NAME

func _get_active_save_backup_file_name() -> String:
	var uid: = _get_save_slot_user_id()
	if uid > 0:
		return SAVE_FILE_BACKUP_TEMPLATE % uid
	return SAVE_FILE_BACKUP

func _get_active_save_temp_file_name() -> String:
	var uid: = _get_save_slot_user_id()
	if uid > 0:
		return SAVE_FILE_TEMP_TEMPLATE % uid
	return "user://save_game_temp.dat"


func _logged_in_per_user_slot() -> bool:
	return network != null and network.is_logged_in() and _get_save_slot_user_id() > 0

func reset_session_save_state_for_account_switch() -> void :
	_last_local_save_timestamp = 0.0
	_cloud_save_revision = 0
	_cloud_sync_gate_passed = false
	_post_login_offline_claim_running = false
	_post_login_offline_claim_done = false
	_post_login_offline_rewards_emitted = false
	reset_brother_tower_lobby_runtime_for_account_switch()

func reset_brother_tower_lobby_runtime_for_account_switch() -> void :
	is_brother_tower_battle = false
	is_brother_tower_settling = false
	stop_brother_tower_requested = false
	brother_tower_session_id = 0
	brother_tower_local_snapshot = {}
	brother_tower_role = ""
	brother_tower_driver_user_id = 0
	brother_tower_waiting_reconnect = false
	brother_tower_waiting_partner = false
	brother_tower_viewer_wave_pending = false
	brother_tower_dismissed_session_id = 0
	_brother_tower_victory_finalized = false
	_brother_tower_start_in_flight = false
	_brother_tower_session_poll_in_flight = false
	_stop_viewer_brother_tower_wave_pending_watchdog()
	_stop_brother_tower_waiting_reconnect_watchdog()
	_stop_brother_tower_wave_cleared_watchdog()
	_bt_ui().reset_lobby_state_for_account_switch()

func mark_cloud_sync_ready() -> void :
	if network != null and network.is_logged_in():
		_cloud_sync_gate_passed = true

func is_cloud_sync_ready() -> bool:
	return _cloud_sync_gate_passed

func is_active_pet_pending_cloud_sync() -> bool:
	return _active_pet_pending_cloud_sync

func block_battle_start_temporarily(duration_ms: int = BATTLE_START_BLOCK_MIN_MS, reason: String = "") -> void :
	var wait_ms: = maxi(BATTLE_START_BLOCK_MIN_MS, duration_ms)
	var until_ms: = Time.get_ticks_msec() + wait_ms
	if until_ms > _battle_start_block_until_ms:
		_battle_start_block_until_ms = until_ms
	if OS.is_debug_build() and not reason.is_empty():
		print("[BattleGuard] block start %dms reason=%s" % [wait_ms, reason])

func is_battle_start_temporarily_blocked() -> bool:
	if _field_loot_hold_next_fight:
		return true
	return Time.get_ticks_msec() < _battle_start_block_until_ms

func ensure_active_pet_ready_for_battle() -> Dictionary:
	if pet_manager == null:
		return {"ok": true, "pet": null, "has_pets": false, "rebound": false, "reason": "no_pet_manager"}
	return pet_manager.ensure_active_pet_ready_for_battle()

func _set_cloud_save_revision(rev: int) -> void :
	if rev < 0:
		return
	_cloud_save_revision = max(_cloud_save_revision, rev)

func _extract_save_revision_from_save_data(save_data: Dictionary) -> int:
	if save_data == null or not (save_data is Dictionary):
		return -1
	if save_data.has("saveRevision"):
		var direct_rev: = int(save_data.get("saveRevision", -1))
		if direct_rev >= 0:
			return direct_rev
	if save_data.has("gameSettings") and save_data.get("gameSettings") is Dictionary:
		var gs: Dictionary = save_data.get("gameSettings", {})
		if gs.has("save_revision"):
			var gs_rev: = int(gs.get("save_revision", -1))
			if gs_rev >= 0:
				return gs_rev
	return -1

func _on_network_save_revision_updated(revision: int) -> void :
	_set_cloud_save_revision(int(revision))

func _local_save_owner_matches_session(save_data: Dictionary) -> bool:
	if not _logged_in_per_user_slot():
		return true
	var uid: = _get_save_slot_user_id()
	if not save_data.has("save_owner_user_id"):
		return true
	var o: = int(save_data.get("save_owner_user_id", 0))
	if o <= 0:
		return true
	return o == uid

static func _encrypt_save_data(data: Dictionary) -> PackedByteArray:
	var json_string = JSON.stringify(data)
	var password = _get_save_password()
	var data_bytes = json_string.to_utf8_buffer()

	var encrypted = PackedByteArray()
	var key = password.to_utf8_buffer()

	for i in range(data_bytes.size()):
		var key_index = i % key.size()
		encrypted.append(data_bytes[i] ^ key[key_index])

	var checksum = _sha256_hash_static(data_bytes)
	encrypted.append_array(checksum.slice(0, 8))

	return encrypted

static func _decrypt_save_data(encrypted: PackedByteArray) -> Dictionary:
	if encrypted.size() < 8:
		return {}

	var password = _get_save_password()
	var key = password.to_utf8_buffer()

	var data_size = encrypted.size() - 8
	var data_bytes = PackedByteArray()

	for i in range(data_size):
		var key_index = i % key.size()
		data_bytes.append(encrypted[i] ^ key[key_index])

	var stored_checksum = encrypted.slice(data_size, encrypted.size())
	var calculated_checksum = _sha256_hash_static(data_bytes).slice(0, 8)

	if stored_checksum != calculated_checksum:
		print("存档校验失败：数据可能被篡改")
		return {}

	var json_string = data_bytes.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("存档解析失败")
		return {}

	return json.get_data()

static func _sha256_hash_static(data: PackedByteArray) -> PackedByteArray:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()


func _calculate_save_hash(save_data: Dictionary) -> String:
	var json_string = JSON.stringify(save_data)
	var data_bytes = json_string.to_utf8_buffer()
	var key_bytes = SAVE_HASH_KEY.to_utf8_buffer()


	var hash_result = _hmac_sha256(data_bytes, key_bytes)
	return hash_result.hex_encode()


func _hmac_sha256(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var block_size = 64


	var used_key = key
	if key.size() > block_size:
		used_key = _sha256_hash(key)


	var padded_key = PackedByteArray()
	padded_key.resize(block_size)
	for i in range(min(used_key.size(), block_size)):
		padded_key[i] = used_key[i]


	var ipad = PackedByteArray()
	var opad = PackedByteArray()
	ipad.resize(block_size)
	opad.resize(block_size)

	for i in range(block_size):
		ipad[i] = padded_key[i] ^ 54
		opad[i] = padded_key[i] ^ 92


	var inner = ipad
	inner.append_array(data)
	var inner_hash = _sha256_hash(inner)

	var outer = opad
	outer.append_array(inner_hash)
	return _sha256_hash(outer)


func _sha256_hash(data: PackedByteArray) -> PackedByteArray:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()


func _verify_save_hash(save_data: Dictionary) -> bool:
	if not save_data.has("hash"):

		var ver = int(save_data.get("version", 0))
		if ver <= 1:
			print("存档无签名（旧版），允许加载；保存后将写入签名")
			return true
		print("存档缺少签名字段，拒绝加载（可能被手动删改）")
		return false

	var stored_hash = save_data.hash
	var data_without_hash = save_data.duplicate()
	data_without_hash.erase("hash")

	var calculated_hash = _calculate_save_hash(data_without_hash)
	if stored_hash != calculated_hash:
		print("存档签名不匹配，拒绝加载（数据可能被篡改）")
		return false
	return true

func mark_battle_progress_dirty(_reason: String = "") -> void :
	_battle_progress_dirty = true

func flush_battle_progress_persist(force: bool = false) -> bool:
	if not _battle_progress_dirty and not force:
		return false
	var ok = save_game()
	if ok:
		_battle_progress_dirty = false
		_battle_save_timer = 0.0
		_battle_full_save_timer = 0.0
	return ok

func save_game(force_cloud_upload: bool = false, upload_reason: String = "") -> bool:
	if not player or not pet_manager:
		print("存档失败：系统未初始化")
		return false

	var save_data = {
		"version": save_version, 
		"player": player.to_dict(), 
		"pets": pet_manager.to_dict(), 
		"pet_collection": pet_collection_manager.to_dict() if pet_collection_manager else {}, 
		"pet_soul": pet_soul_manager.to_dict() if pet_soul_manager else {}, 
		"pet_equipment": pet_equipment_manager.to_dict() if pet_equipment_manager else {}, 
		"equipment": equipment_manager.to_dict(), 
		"fabao": fabao_manager.to_dict() if fabao_manager else {}, 
		"suit": suit_manager.to_dict() if suit_manager else {}, 
		"martial_arts": martial_arts_manager.to_dict(), 
		"inventory": inventory_manager.to_dict(), 
		"crafting": crafting_manager.to_dict(), 
		"xianmo": xianmo_system.to_dict() if xianmo_system else {}, 
		"xianmo_ranking": xianmo_ranking.to_dict() if xianmo_ranking else {}, 
		"xianmo_chest": xianmo_chest_manager.to_dict() if xianmo_chest_manager else {}, 
		"current_map": current_map, 
		"auto_capture_enabled": auto_capture_enabled, 
		"min_growth_threshold": min_growth_threshold, 
		"auto_change_map_enabled": auto_change_map_enabled, 
		"previous_map": previous_map, 
		"auto_change_map_consecutive_wins": auto_change_map_consecutive_wins, 
		"auto_change_map_consecutive_deaths": auto_change_map_consecutive_deaths, 
		"auto_change_map_upgrade_cooldown": auto_change_map_upgrade_cooldown, 
		"bgm_enabled": bgm_enabled, 
		"bgm_volume": bgm_volume, 
		"last_broadcast_id": _last_broadcast_id, 
		"timestamp": Time.get_unix_time_from_system(), 
		"cloud_save_revision": _cloud_save_revision, 
		"save_count": (last_save_time + 1)
	}
	var slot_uid: = _get_save_slot_user_id()
	if network != null and network.is_logged_in() and slot_uid > 0:
		save_data["save_owner_user_id"] = slot_uid
	elif save_data.has("save_owner_user_id"):
		save_data.erase("save_owner_user_id")
	_last_local_save_timestamp = float(save_data["timestamp"])

	save_data["hash"] = _calculate_save_hash(save_data)

	var encrypted_data = _encrypt_save_data(save_data)
	if encrypted_data.is_empty():
		print("存档失败：加密失败")
		return false

	var active_save_path: = _get_active_save_file_name()
	var active_backup_path: = _get_active_save_backup_file_name()
	var temp_path: = _get_active_save_temp_file_name()
	var temp_file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not temp_file:
		print("存档失败：无法创建临时文件")
		return false

	temp_file.store_buffer(encrypted_data)
	temp_file.close()

	var verify_file = FileAccess.open(temp_path, FileAccess.READ)
	if not verify_file:
		print("存档失败：临时文件验证失败")
		DirAccess.remove_absolute(temp_path)
		return false

	var verify_content = verify_file.get_buffer(encrypted_data.size())
	verify_file.close()

	if verify_content != encrypted_data:
		print("存档失败：写入验证失败")
		DirAccess.remove_absolute(temp_path)
		return false

	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists(active_save_path):
			dir.copy(active_save_path, active_backup_path)

	DirAccess.remove_absolute(active_save_path)
	if dir:
		dir.copy(temp_path, active_save_path)
	DirAccess.remove_absolute(temp_path)

	last_save_time = Time.get_unix_time_from_system()
	game_saved.emit()
	print("游戏已保存（加密存档）")

	if network and network.is_logged_in():
		_cloud_upload_dispatched_this_save = false
		if not _cloud_sync_gate_passed:
			push_warning("[GameManager] 云同步门未通过，跳过本次云上传（避免空档覆盖服务端）")
			return true
		var reason_str: = upload_reason.strip_edges()
		var now_ms: = Time.get_ticks_msec()
		if is_field_battle_loot_upload_blocked() and not (force_cloud_upload and _is_authority_layout_upload_reason(reason_str)):
			print("[SaveThrottle] suppress cloud upload during field battle-loot pending reason=%s force=%s" % [reason_str, str(force_cloud_upload)])
			return true
		if not force_cloud_upload and now_ms < _suppress_general_cloud_upload_until_ms:
			var remain_ms: = _suppress_general_cloud_upload_until_ms - now_ms
			print("[SaveThrottle] suppress cloud upload after apply_cloud_save, remain_ms=%d reason=%s force=%s" % [remain_ms, reason_str, str(force_cloud_upload)])
			return true
		if not force_cloud_upload and (is_five_elements_battle or is_fe_settling):
			print("[SaveThrottle] suppress cloud upload during five elements dungeon reason=%s" % reason_str)
			return true
		if not force_cloud_upload and (is_five_elements_battle or is_fe_settling):
			print("[SaveThrottle] suppress cloud upload during five elements dungeon battle/settle reason=%s" % reason_str)
			return true
		var now_ts = Time.get_unix_time_from_system()
		var min_cloud_interval: = CLOUD_UPLOAD_MIN_INTERVAL
		if _bt_ui().get_my_room_id() > 0 or is_brother_tower_battle or is_brother_tower_settling:
			min_cloud_interval = maxf(min_cloud_interval, 120.0)
		if force_cloud_upload or (_last_cloud_upload_time <= 0.0) or (now_ts - _last_cloud_upload_time >= min_cloud_interval):
			var compact_mode: bool = ( not force_cloud_upload) or _force_compact_authority_next_upload
			var elapsed_since_last = int(now_ts - _last_cloud_upload_time) if _last_cloud_upload_time > 0.0 else -1
			_last_cloud_upload_time = now_ts
			print("[SaveThrottle] trigger cloud upload compact=%s force=%s reason=%s forceCompactAuthority=%s elapsed=%ss minInterval=%ss" % [str(compact_mode), str(force_cloud_upload), reason_str, str(_force_compact_authority_next_upload), str(elapsed_since_last), str(int(min_cloud_interval))])
			_cloud_upload_dispatched_this_save = true
			upload_cloud_save(compact_mode, reason_str)
		else:
			var remain = int(min_cloud_interval - (now_ts - _last_cloud_upload_time))
			print("[SaveThrottle] skip cloud upload, cooldown=%ss" % max(remain, 0))

	return true

func load_game() -> bool:
	var save_data = null
	var loaded_from = ""

	var active_save_path: = _get_active_save_file_name()
	var active_backup_path: = _get_active_save_backup_file_name()
	var forbid_legacy_fallback: = _logged_in_per_user_slot()
	var fallback_to_legacy_slot: = (active_save_path != SAVE_FILE_NAME) and not forbid_legacy_fallback
	var save_file = FileAccess.open(active_save_path, FileAccess.READ)
	if save_file == null and fallback_to_legacy_slot:
		save_file = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
		if save_file:
			print("当前账号分槽存档不存在，回退读取旧通用主存档")
	if save_file:
		var encrypted = save_file.get_buffer(save_file.get_length())
		save_file.close()
		if not encrypted.is_empty():
			var result = _decrypt_and_validate_save(encrypted)
			if result != null:
				if _local_save_owner_matches_session(result):
					save_data = result
					loaded_from = "主存档"
				else:
					push_warning("[GameManager] 主存档 save_owner_user_id 与当前账号不符，已忽略（请从云端同步）")

	if save_data == null:
		print("主存档不存在或损坏，尝试加载备份...")
		var backup_file = FileAccess.open(active_backup_path, FileAccess.READ)
		if backup_file == null and fallback_to_legacy_slot:
			backup_file = FileAccess.open(SAVE_FILE_BACKUP, FileAccess.READ)
			if backup_file:
				print("当前账号分槽备份不存在，回退读取旧通用备份存档")
		if backup_file:
			var encrypted = backup_file.get_buffer(backup_file.get_length())
			backup_file.close()
			if not encrypted.is_empty():
				var result = _decrypt_and_validate_save(encrypted)
				if result != null:
					if _local_save_owner_matches_session(result):
						save_data = result
						loaded_from = "备份存档"
					else:
						push_warning("[GameManager] 备份存档 save_owner_user_id 与当前账号不符，已忽略")

	if save_data == null and ALLOW_LEGACY_PLAINTEXT_JSON_SAVE and not forbid_legacy_fallback:
		save_data = _try_load_old_json_save()
		if save_data != null:
			loaded_from = "旧版存档（已迁移）"

	if save_data == null:
		print("所有存档都不可用")
		return false

	print("成功从 %s 加载存档" % loaded_from)
	_set_cloud_save_revision(int(save_data.get("cloud_save_revision", -1)))

	if save_data.has("player") and player != null:
		player.from_dict(save_data.get("player", {}))
		gold_changed.emit(player.gold)
		yuanbao_changed.emit(player.yuanbao_currency)
	if save_data.has("pets") and pet_manager != null:
		pet_manager.from_dict(save_data.get("pets", {}))
	if player != null and pet_manager != null:
		pet_manager.update_max_pet_bag_for_vip(VipBenefits.tier_from_player(player))
	if save_data.has("pet_collection") and pet_collection_manager != null:
		pet_collection_manager.from_dict(save_data.get("pet_collection", {}))
	if save_data.has("pet_soul") and pet_soul_manager != null:
		pet_soul_manager.from_dict(save_data.get("pet_soul", {}))

	if save_data.has("pet_equipment") and pet_equipment_manager != null:
		pet_equipment_manager.from_dict(save_data.get("pet_equipment", {}))
	if save_data.has("suit") and suit_manager != null:
		suit_manager.from_dict(save_data.get("suit", {}))
	if save_data.has("equipment") and equipment_manager != null:
		equipment_manager.from_dict(save_data.get("equipment", {}))
	if fabao_manager and save_data.has("fabao"):
		fabao_manager.from_dict(save_data.get("fabao", {}))
	if save_data.has("martial_arts") and martial_arts_manager != null:
		martial_arts_manager.from_dict(save_data.get("martial_arts", {}))
	if save_data.has("inventory") and inventory_manager != null:
		var inv_data = save_data.get("inventory", {})
		inventory_manager.from_dict(inv_data)
	if save_data.has("crafting") and crafting_manager != null:
		crafting_manager.from_dict(save_data.get("crafting", {}))

	if save_data.has("xianmo") and xianmo_system != null:
		xianmo_system.from_dict(save_data.get("xianmo", {}))
	if save_data.has("xianmo_ranking") and xianmo_ranking != null:
		xianmo_ranking.from_dict(save_data.get("xianmo_ranking", {}))
	if save_data.has("xianmo_chest") and xianmo_chest_manager != null:
		xianmo_chest_manager.from_dict(save_data.get("xianmo_chest", {}))




	current_map = GameData.migrate_map_id(str(save_data.get("current_map", DEFAULT_VALUES.current_map)))
	auto_capture_enabled = save_data.get("auto_capture_enabled", DEFAULT_VALUES.auto_capture_enabled)
	min_growth_threshold = save_data.get("min_growth_threshold", DEFAULT_VALUES.min_growth_threshold)
	auto_change_map_enabled = save_data.get("auto_change_map_enabled", DEFAULT_VALUES.auto_change_map_enabled)
	previous_map = GameData.migrate_map_id(str(save_data.get("previous_map", DEFAULT_VALUES.previous_map)))
	auto_change_map_consecutive_wins = save_data.get("auto_change_map_consecutive_wins", DEFAULT_VALUES.auto_change_map_consecutive_wins)
	auto_change_map_consecutive_deaths = save_data.get("auto_change_map_consecutive_deaths", DEFAULT_VALUES.auto_change_map_consecutive_deaths)
	auto_change_map_upgrade_cooldown = save_data.get("auto_change_map_upgrade_cooldown", DEFAULT_VALUES.auto_change_map_upgrade_cooldown)
	_last_broadcast_id = max(_last_broadcast_id, int(save_data.get("last_broadcast_id", 0)))
	_save_broadcast_cursor()

	if save_data.has("timestamp"):
		_last_local_save_timestamp = float(save_data.get("timestamp", 0.0))

	migrate_pet_equipment_from_inventory()

	game_loaded.emit()
	print("游戏已加载")
	return true

func _decrypt_and_validate_save(encrypted: PackedByteArray) -> Variant:
	if encrypted.is_empty():
		return null

	var save_data = _decrypt_save_data(encrypted)
	if save_data.is_empty():
		return null

	if not _verify_save_hash(save_data):
		print("存档数据校验失败")
		return null

	_migrate_save_data(save_data)

	return save_data

func _try_load_old_json_save() -> Dictionary:
	var old_paths = ["user://save_game.json", "user://save_game_backup.json"]
	for old_path in old_paths:
		if FileAccess.file_exists(old_path):
			var file = FileAccess.open(old_path, FileAccess.READ)
			if file:
				var json_string = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(json_string) == OK:
					var save_data = json.get_data()
					if save_data is Dictionary and _verify_save_hash(save_data):
						print("检测到旧版JSON存档，正在迁移...")
						_migrate_save_data(save_data)
						var dir = DirAccess.open("user://")
						if dir:
							dir.remove(old_path)
						return save_data
	return {}

func _parse_and_validate_save(json_string: String) -> Variant:
	if json_string.is_empty():
		return null

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("JSON解析失败")
		return null

	var save_data = json.get_data()

	if not save_data is Dictionary:
		print("存档格式错误")
		return null

	if not _verify_save_hash(save_data):
		print("存档数据校验失败")
		return null

	_migrate_save_data(save_data)

	return save_data

func _migrate_save_data(save_data: Dictionary):
	var loaded_version = save_data.get("version", 1)

	if loaded_version < save_version:
		print("[存档迁移] 检测到旧版本存档 v%d，正在迁移到 v%d..." % [loaded_version, save_version])

	for key in DEFAULT_VALUES.keys():
		if not save_data.has(key):
			save_data[key] = DEFAULT_VALUES[key]
			print("[存档迁移] 添加缺失字段: %s = %s" % [key, DEFAULT_VALUES[key]])

	if save_data.has("player"):
		var player_data = save_data.get("player", {})
		if player_data is Dictionary:
			_migrate_player_data(player_data)

	if save_data.has("pets"):
		var pets_data = save_data.get("pets", {})
		if pets_data is Dictionary:
			_migrate_pets_data(pets_data)

	save_data["version"] = save_version
	print("[存档迁移] 迁移完成，当前版本: v%d" % save_version)

func _migrate_player_data(player_data: Dictionary):
	var player_defaults = {
		"name": "江小湖", 
		"level": 1, 
		"experience": 0, 
		"hp": 100, 
		"max_hp": 100, 
		"mp": 100, 
		"max_mp": 100, 
		"vitality": 10, 
		"magic": 10, 
		"attack_base": 10, 
		"defense_base": 10, 
		"agility_base": 10, 
		"realm": "凡人", 
		"cultivation": 0, 
		"reincarnation": 0, 
		"cultivation_pills_used": 0, 
		"points": 20, 
		"permanent_points": 0, 
		"element": "普通", 
		"gold": 0, 
		"yuanbao_currency": 0, 
		"is_vip": false, 
		"vip_level": 0, 
		"vip_expire_time_str": "", 
		"tower_floor": 1, 
		"tower_highest": 0, 
		"tower_sweep_count": 0, 
		"suit_dungeon_progress": 0, 
		"suit_dungeon_sweeps": 3, 
		"auto_allocation_enabled": false, 
		"pending_auto_points": 0, 
		"auto_allocation_plan": {"vitality": 0, "attack": 0, "defense": 0, "magic": 0, "agility": 0}
	}

	for key in player_defaults.keys():
		if key == "permanent_points" and not player_data.has(key):
			continue
		if not player_data.has(key):
			player_data[key] = player_defaults[key]

func _migrate_pets_data(pets_data: Dictionary):
	if not pets_data.has("active_pet_id"):
		pets_data["active_pet_id"] = ""

	if not pets_data.has("pets"):
		pets_data["pets"] = []

	if not pets_data.has("pet_bag"):
		pets_data["pet_bag"] = []

	if pets_data.has("pets"):
		var pets_array = pets_data.get("pets", [])
		if pets_array is Array:
			for pet_dict in pets_array:
				if pet_dict is Dictionary:
					_migrate_pet_data(pet_dict)

	if pets_data.has("pet_bag"):
		var pet_bag_array = pets_data.get("pet_bag", [])
		if pet_bag_array is Array:
			for pet_dict in pet_bag_array:
				if pet_dict is Dictionary:
					_migrate_pet_data(pet_dict)


func _normalize_pets_data_roster_layout(pets_data: Array, pet_bag_data: Array, active_pet_id: String = "", assist_pets_data: Array = []) -> Dictionary:
	var active_id: = str(active_pet_id).strip_edges()

	var assist_src: Array = assist_pets_data if assist_pets_data is Array else []
	var normalized_assist: Array = []
	normalized_assist.resize(10)
	var assist_ids: Dictionary = {}
	var active_in_assist: Dictionary = {}
	for i in range(10):
		normalized_assist[i] = null
		if i >= assist_src.size():
			continue
		var ap: Variant = assist_src[i]
		if ap == null or not (ap is Dictionary) or not ap.has("id"):
			continue
		var apid: = str(ap.id).strip_edges()
		if apid.is_empty() or assist_ids.has(apid):
			continue
		if not active_id.is_empty() and apid == active_id:
			active_in_assist = ap
			continue
		assist_ids[apid] = true
		normalized_assist[i] = ap
	var bag_ids: = {}
	var deduped_bag: Array = []
	for p in pet_bag_data:
		if p is Dictionary and p.has("id"):
			var bag_pid: = str(p.id).strip_edges()
			if bag_pid.is_empty() or bag_ids.has(bag_pid) or assist_ids.has(bag_pid):
				continue
			bag_ids[bag_pid] = p
			deduped_bag.append(p)
		else:
			deduped_bag.append(p)
	var active_in_bag: Dictionary = {}
	if not active_id.is_empty() and bag_ids.has(active_id):
		active_in_bag = bag_ids[active_id]
		deduped_bag = deduped_bag.filter( func(p):
			return not (p is Dictionary and str(p.get("id", "")).strip_edges() == active_id)
		)
		bag_ids.erase(active_id)
	var filtered_pets: Array = []
	var active_in_main: = false
	for p in pets_data:
		if p is Dictionary and p.has("id"):
			var main_pid: = str(p.id).strip_edges()
			if main_pid.is_empty():
				filtered_pets.append(p)
				continue
			if assist_ids.has(main_pid):
				continue
			if not active_id.is_empty() and main_pid == active_id:
				active_in_main = true
				filtered_pets.append(p)
				continue
			if bag_ids.has(main_pid):
				continue
		filtered_pets.append(p)
	if not active_id.is_empty() and not active_in_main:
		if not active_in_bag.is_empty():
			filtered_pets.append(active_in_bag)
		elif not active_in_assist.is_empty():
			filtered_pets.append(active_in_assist)
	return {"pets": filtered_pets, "pet_bag": deduped_bag, "assist_pets": normalized_assist}

func _migrate_pet_data(pet_data: Dictionary):
	var pet_defaults = {
		"id": "", 
		"name": "", 
		"form": "幼年", 
		"level": 1, 
		"experience": 0, 
		"hp": 100, 
		"max_hp": 100, 
		"attack": 10, 
		"defense": 10, 
		"agility": 10, 
		"growth_rate": 1.0, 
		"is_elite": false, 
		"locked": false, 
		"skill_id": "", 
		"skill_level": 1, 
		"skill_exp": 0, 
		"element": "普通", 
		"potential": 0, 
		"base_pet_id": "", 
		"reincarnation_count": 0
	}

	for key in pet_defaults.keys():
		if not pet_data.has(key):
			pet_data[key] = pet_defaults[key]

func _migrate_cloud_save_data(save_data: Dictionary):
	var loaded_version = save_data.get("version", 1)

	if loaded_version < save_version:
		print("[云存档迁移] 检测到旧版本存档 v%d，正在迁移到 v%d..." % [loaded_version, save_version])

	for key in DEFAULT_VALUES.keys():
		if not save_data.has(key):
			save_data[key] = DEFAULT_VALUES[key]

	if save_data.has("playerData"):
		var player_data = save_data.get("playerData", {})
		if player_data is Dictionary:
			_migrate_player_data(player_data)

	if save_data.has("petsData"):
		var pets_data = save_data.get("petsData", {})
		if pets_data is Dictionary:
			_migrate_pets_data(pets_data)

	save_data["version"] = save_version
	print("[云存档迁移] 迁移完成，当前版本: v%d" % save_version)


func migrate_pet_equipment_from_inventory():
	if equipment_manager == null or inventory_manager == null:
		return

	var migrated_count = 0
	var items_to_remove = []

	for equipment in equipment_manager.inventory:
		if equipment.is_pet_equipment:
			items_to_remove.append(equipment)
			inventory_manager.add_pet_equipment(equipment)
			migrated_count += 1

	for equipment in items_to_remove:
		equipment_manager.inventory.erase(equipment)

	if migrated_count > 0:
		print("数据迁移：已将 %d 件宠物装备从人物装备背包移动到宠物装备背包" % migrated_count)
		equipment_manager.inventory_changed.emit()

func has_save() -> bool:
	var active_save_path: = _get_active_save_file_name()
	var active_backup_path: = _get_active_save_backup_file_name()
	var forbid_legacy: = _logged_in_per_user_slot()
	var fallback_to_legacy_slot: = (active_save_path != SAVE_FILE_NAME) and not forbid_legacy
	if FileAccess.file_exists(active_save_path):
		return true
	if FileAccess.file_exists(active_backup_path):
		return true
	if fallback_to_legacy_slot and FileAccess.file_exists(SAVE_FILE_NAME):
		return true
	if fallback_to_legacy_slot and FileAccess.file_exists(SAVE_FILE_BACKUP):
		return true
	if ALLOW_LEGACY_PLAINTEXT_JSON_SAVE:
		if FileAccess.file_exists("user://save_game.json"):
			return true
		if FileAccess.file_exists("user://save_game_backup.json"):
			return true
	return false

func set_session_nickname(name: String) -> void :
	_session_server_nickname = String(name).strip_edges()

func set_network(net):
	network = net
	if network:
		network.save_uploaded.connect(_on_cloud_save_uploaded)
		network.save_downloaded.connect(_on_cloud_save_downloaded)
		if network.has_signal("save_revision_updated") and not network.save_revision_updated.is_connected(_on_network_save_revision_updated):
			network.save_revision_updated.connect(_on_network_save_revision_updated)
		if network.has_method("get_last_server_save_revision"):
			_set_cloud_save_revision(int(network.get_last_server_save_revision()))
		if network.has_method("is_logged_in"):
			is_logged_in = network.is_logged_in()
	if xianmo_system:
		xianmo_system.set_network(network)
	if xianmo_battle_processor:
		xianmo_battle_processor.set_network(network)
	if title_manager:
		title_manager.set_network(network)
	if martial_arts_manager:
		martial_arts_manager.set_network(network)
	if network:
		if not network.xianmo_broadcasts_loaded.is_connected(_on_broadcasts_loaded):
			network.xianmo_broadcasts_loaded.connect(_on_broadcasts_loaded)
		if not network.xianmo_broadcast_sent.is_connected(_on_broadcast_sent):
			network.xianmo_broadcast_sent.connect(_on_broadcast_sent)
		if not network.drop_config_loaded.is_connected(_on_drop_config_loaded):
			network.drop_config_loaded.connect(_on_drop_config_loaded)
		if network.has_signal("festival_runtime_config_loaded") and not network.festival_runtime_config_loaded.is_connected(_on_festival_runtime_config_loaded):
			network.festival_runtime_config_loaded.connect(_on_festival_runtime_config_loaded)
		if network.has_signal("gameplay_runtime_config_loaded") and not network.gameplay_runtime_config_loaded.is_connected(_on_gameplay_runtime_config_loaded):
			network.gameplay_runtime_config_loaded.connect(_on_gameplay_runtime_config_loaded)
		if gang_manager and network.has_signal("gang_buffs_synced") and not network.gang_buffs_synced.is_connected(gang_manager.apply_heartbeat_buffs):
			network.gang_buffs_synced.connect(gang_manager.apply_heartbeat_buffs)
		if network.has_signal("noble_info_loaded") and not _noble_info_signal_connected:
			network.noble_info_loaded.connect(_on_noble_info_loaded_for_cache)
			_noble_info_signal_connected = true
		if network.has_method("is_logged_in") and network.is_logged_in() and network.has_method("get_noble_info"):
			network.get_noble_info()
	if mail_manager:
		mail_manager.sync_mail_api_base(str(network.server_url) if network != null else "")
	if chat_network:
		chat_network.sync_from_api_session(str(network.server_url) if network != null else "")

func _on_drop_config_loaded(drop_rates: Dictionary):
	if drop_rates.is_empty():
		print("[GameManager] 服务端掉落率配置为空，使用本地默认值")
		return
	var count = GameData.apply_drop_config(drop_rates)
	print("[GameManager] 掉落率配置已从服务端同步，覆盖 %d 个物品" % count)

func _refresh_festival_runtime_config_from_server() -> void :
	if network == null or not network.is_logged_in():
		return
	if network.has_method("fetch_festival_runtime_config"):
		network.fetch_festival_runtime_config()

func _on_festival_runtime_config_loaded(config: Dictionary) -> void :
	var payload: Dictionary = config if config is Dictionary else {}
	var count: = FestivalGiftConfig.apply_runtime_config(payload)
	var gift_item_count: = GameData.apply_festival_gift_item_defs(FestivalGiftConfig.list_festival_gift_names())
	print("[GameManager] 节日活动配置已从服务端同步，活动数=%d 礼包道具=%d" % [count, gift_item_count])

func _snake_to_camel_key(k: String) -> String:
	var out: = ""
	var up: = false
	for ch in k:
		if ch == "_":
			up = true
		elif up:
			out += ch.to_upper()
			up = false
		else:
			out += ch
	return out

func _alias_runtime_module_keys(cfg: Dictionary) -> Dictionary:
	# 服务端 /gameplay/runtime-config 的模块键是 snake_case（atlas_dungeon…），
	# 客户端全部按参考稿 camelCase（atlasDungeon…）读取。这里给 snake 键补一个
	# camel 别名，两种风格都认；否则整块配置读空、客户端静默回落本地默认值，
	# 曾经导致图鉴天关三档都是 20 波、兄弟天关 50 波对不上服务端 10 波等。
	for key in cfg.keys():
		var ks: = str(key)
		if not ks.contains("_"):
			continue
		var camel: = _snake_to_camel_key(ks)
		if not camel.is_empty() and not cfg.has(camel):
			cfg[camel] = cfg[key]
	return cfg

func _on_gameplay_runtime_config_loaded(config: Dictionary) -> void :
	if config.is_empty():
		print("[GameManager] 玩法运行时配置为空，使用本地默认值")
		return
	gameplay_runtime_config = _alias_runtime_module_keys(config.duplicate(true))
	var gp: Dictionary = gameplay_runtime_config.get("gameplay", {}) if gameplay_runtime_config.get("gameplay") is Dictionary else {}
	var skill_defs: Variant = gp.get("skillDefinitions", {})
	if skill_defs is Dictionary and not skill_defs.is_empty():
		PetSkillConfig.apply_runtime_definitions(skill_defs)
	var wb: Dictionary = gp.get("wildBattle", {}) if gp.get("wildBattle") is Dictionary else {}
	if not wb.is_empty():
		Monster.apply_wild_battle_runtime(wb)
		print("[GameManager] 野外战斗配置已同步 spawn=%s~%s expMul=%s expPerLv=%s goldPerLv=%s maxRounds=%s" % [
			str(wb.get("spawnMin", 1)), str(wb.get("spawnMax", 5)), str(wb.get("fieldExpMultiplier", 0.5)), 
			str(wb.get("monsterExpPerLevel", 100)), str(wb.get("monsterGoldPerLevel", 5)), str(wb.get("battleMaxRounds", 10))
		])
	var ple: Dictionary = gp.get("playerLevelExp", {}) if gp.get("playerLevelExp") is Dictionary else {}
	if not ple.is_empty():
		GameData.apply_player_level_exp_config(ple)
	var ps: Variant = gameplay_runtime_config.get("petSoul", {})
	if ps is Dictionary and pet_soul_manager:
		pet_soul_manager.apply_runtime_config(ps)
		print("[GameManager] 宠物魂魄玩法配置已同步 rebirthChance=%s" % str(ps.get("rebirthChance", 0.5)))
	var pm: Variant = gameplay_runtime_config.get("petMutation", {})
	if pm is Dictionary and not pm.is_empty():
		print("[GameManager] 宠物变异玩法配置已同步 enabled=%s evolveChance=%s" % [
			str(pm.get("enabled", false)), str(pm.get("evolveMutateChance", 0.01))
		])
	var pa: Variant = gameplay_runtime_config.get("petAssist", {})
	if pa is Dictionary and not pa.is_empty():
		PetAssistBonus.apply_runtime_config(pa)
		print("[GameManager] 助战宠比例已同步 base=%s special=%s custom=%s mut=%s" % [
			str(pa.get("baseRate", 0.01)), 
			str(pa.get("specialTypeRate", 0.02)), 
			str(pa.get("sponsorCustomRate", 0.05)), 
			str(pa.get("mutationRatePerCount", 0.01)), 
		])
	var fb: Variant = gameplay_runtime_config.get("fabao", {})
	if fb is Dictionary and not (fb as Dictionary).is_empty():
		FabaoConfig.apply_runtime_config(fb)
		print("[GameManager] 法宝玩法配置已同步 dropDenom=%s minMap=%s synth=%s" % [
			str(fb.get("dropDenom", 2000)), str(fb.get("minMapLevel", 1000)), str(fb.get("synthFragmentCount", 100))
		])
	var pss: Variant = gameplay_runtime_config.get("petSkillSlots", {})
	if pss is Dictionary:
		var four_ids: Variant = (pss as Dictionary).get("fourSlotPetIds", [])
		var five_ids: Variant = (pss as Dictionary).get("fiveSlotPetIds", [])
		var four_n: = (four_ids as Array).size() if four_ids is Array else 0
		var five_n: = (five_ids as Array).size() if five_ids is Array else 0
		print("[GameManager] 宠物技能槽配置已同步 feature=%s default=%s four=%d five=%d" % [
			str((pss as Dictionary).get("featureEnabled", false)), 
			str((pss as Dictionary).get("defaultSlotCount", 3)), 
			four_n, 
			five_n
		])
		_normalize_all_pet_skill_slots_for_runtime()
	var psl: Variant = gameplay_runtime_config.get("petSkillLearn", {})
	if psl is Dictionary:
		print("[GameManager] 宠物技能领悟配置已同步 feature=%s maxLv=%s" % [
			str((psl as Dictionary).get("featureEnabled", false)), 
			str((psl as Dictionary).get("maxSkillLevel", 3)), 
		])
	var pet_open_cfg: Variant = gameplay_runtime_config.get("petOpenItems", {})
	if pet_open_cfg is Dictionary:
		var pet_open_items: Variant = pet_open_cfg.get("items", [])
		if pet_open_items is Array:
			var auth_n: = InventoryManager.apply_runtime_pet_open_auth_names(pet_open_items)
			var def_n: = GameData.apply_pet_open_item_defs(pet_open_items)
			print("[GameManager] 开宠礼包配置已同步 auth=%d defs=%d" % [auth_n, def_n])
	print("[GameManager] 玩法运行时配置已从服务端同步")
	var tw_cfg: Variant = gameplay_runtime_config.get("tower", {})
	if tw_cfg is Dictionary:
		TowerUI.apply_runtime_config(tw_cfg)
	_refresh_open_brother_tower_ui()

func _normalize_all_pet_skill_slots_for_runtime() -> void :
	if pet_manager == null:
		return
	var lists: Array = []
	if pet_manager.has_method("get_all_pets"):
		lists.append(pet_manager.get_all_pets())
	if pet_manager.has_method("get_all_pets_in_bag"):
		lists.append(pet_manager.get_all_pets_in_bag())
	for list in lists:
		if not (list is Array):
			continue
		for p in list:
			if p != null and p.has_method("normalize_skill_slots"):
				p.normalize_skill_slots()

func is_pet_mutation_feature_enabled() -> bool:
	var pm: Dictionary = _rt_module("petMutation")
	return bool(pm.get("enabled", false))

func get_pet_mutation_runtime_config() -> Dictionary:
	return _rt_module("petMutation")

func get_pet_skill_slots_runtime_config() -> Dictionary:
	return _rt_module("petSkillSlots")

func is_wild_replay_on() -> bool:
	var gp: Variant = gameplay_runtime_config.get("gameplay", {})
	if not (gp is Dictionary):
		return false
	var ca: Variant = (gp as Dictionary).get("combatAuthority", {})
	if not (ca is Dictionary):
		return false
	return str((ca as Dictionary).get("wildReplay", "off")) == "on"

func _mark_wild_replay_off_locally() -> void :
	var gp: Variant = gameplay_runtime_config.get("gameplay", {})
	if not (gp is Dictionary):
		gp = {}
		gameplay_runtime_config["gameplay"] = gp
	var ca: Variant = (gp as Dictionary).get("combatAuthority", {})
	if not (ca is Dictionary):
		ca = {}
		(gp as Dictionary)["combatAuthority"] = ca
	(ca as Dictionary)["wildReplay"] = "off"

func _mark_wild_replay_on_locally() -> void :
	var gp: Variant = gameplay_runtime_config.get("gameplay", {})
	if not (gp is Dictionary):
		gp = {}
		gameplay_runtime_config["gameplay"] = gp
	var ca: Variant = (gp as Dictionary).get("combatAuthority", {})
	if not (ca is Dictionary):
		ca = {}
		(gp as Dictionary)["combatAuthority"] = ca
	(ca as Dictionary)["wildReplay"] = "on"

func is_tower_replay_on() -> bool:
	var gp: Variant = gameplay_runtime_config.get("gameplay", {})
	if not (gp is Dictionary):
		return false
	var ca: Variant = (gp as Dictionary).get("combatAuthority", {})
	if not (ca is Dictionary):
		return false
	return str((ca as Dictionary).get("towerReplay", "off")) == "on"

func is_world_boss_replay_on() -> bool:
	var gp: Variant = gameplay_runtime_config.get("gameplay", {})
	if not (gp is Dictionary):
		return false
	var ca: Variant = (gp as Dictionary).get("combatAuthority", {})
	if not (ca is Dictionary):
		return false
	return str((ca as Dictionary).get("worldBossReplay", "off")) == "on"

func _clear_leftover_replay_for_local_combat() -> void :
	_wild_replay_abort = true
	_tower_replay_abort = true
	if battle_system:
		battle_system.replay_log_only = false

func _wait_field_replay_idle_async() -> void :
	var deadline_ms: = Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline_ms:
		if not _wild_replay_busy and not _tower_replay_busy:
			return
		if get_tree() == null:
			return
		await get_tree().process_frame

func _hydrate_wild_replay_monsters(raw: Array) -> Array:
	var out: Array = []
	for row in raw:
		if row is Monster:
			out.append(row)
			continue
		if not row is Dictionary:
			continue
		var d: Dictionary = row
		var tpl: Dictionary = d.duplicate(true)
		var display_name: = str(tpl.get("monster_name", tpl.get("name", "怪物"))).strip_edges()
		if display_name.is_empty():
			display_name = "怪物"
		tpl["name"] = display_name
		tpl["monster_name"] = display_name
		var pet_id: = str(tpl.get("pet_id", tpl.get("monster_id", tpl.get("id", "")))).strip_edges()
		if pet_id.is_empty():
			pet_id = _wild_monster_drop_pet_id(d)
		if not pet_id.is_empty():
			tpl["pet_id"] = pet_id
			tpl["id"] = pet_id
			tpl["monster_id"] = pet_id
		var m: Monster = Monster.create_from_template(tpl)
		m.monster_name = display_name
		if not pet_id.is_empty():
			m.monster_id = pet_id
		m.level = maxi(1, int(d.get("level", m.level)))
		# 野怪五行以宠物图鉴为准：服端怪物池曾经把水系（赤翅蛾/珍珍/盈盈）标成火、
		# 金系鸟标成木，导致「金打水」这种不存在的克制。图鉴里有元素就以图鉴为准，
		# 只有图鉴查不到的通用怪才用服端下发的元素。
		var catalog_el: = ""
		if not pet_id.is_empty():
			catalog_el = str(GameData.PET_DATA.get(pet_id, {}).get("element", "")).strip_edges()
		if catalog_el.is_empty() or catalog_el == "普通":
			m.element = str(d.get("element", m.element))
		else:
			m.element = catalog_el
		m.attack = maxi(1, int(d.get("attack", m.attack)))
		m.defense = maxi(1, int(d.get("defense", m.defense)))
		m.agility = maxi(1, int(d.get("agility", m.agility)))
		m.max_hp = maxi(1, int(d.get("max_hp", d.get("hp", m.max_hp))))
		m.hp = maxi(1, int(d.get("hp", m.max_hp)))
		m.exp_reward = maxi(0, int(d.get("exp_reward", m.exp_reward)))
		m.gold_reward = maxi(0, int(d.get("gold_reward", m.gold_reward)))
		out.append(m)
	return out

func _log_wild_replay_monster_encounters(monsters: Array) -> void :
	if battle_system == null or monsters.is_empty():
		return
	for monster in monsters:
		var m_name: = str(battle_system._get_monster_stat(monster, "monster_name", battle_system._get_monster_stat(monster, "name", "怪物")))
		var m_level: = int(battle_system._get_monster_stat(monster, "level", 1))
		var m_hp: = int(battle_system._get_monster_stat(monster, "hp", 0))
		var m_atk: = int(battle_system._get_monster_stat(monster, "attack", 0))
		var m_def: = int(battle_system._get_monster_stat(monster, "defense", 0))
		var m_agi: = int(battle_system._get_monster_stat(monster, "agility", 0))
		battle_system.add_log("遭遇 %s Lv.%d!" % [m_name, m_level])
		battle_system.add_log("└ 属性 攻:%d 防:%d 敏:%d 血:%d" % [m_atk, m_def, m_agi, m_hp])

func _tower_has_taken_battle_slot() -> bool:
	return is_tower_battle or _tower_replay_busy

func _release_wild_replay_battle_slot() -> void :
	_wild_replay_busy = false
	if _tower_has_taken_battle_slot():
		return
	in_battle = false

func _wild_replay_should_cancel(gen: int) -> bool:
	return gen != _wild_replay_gen or _wild_replay_abort


func _finish_cancelled_wild_replay(gen: int, late: Dictionary) -> void :
	if gen != _wild_replay_gen:
		var late_token: = str(late.get("fightToken", "")).strip_edges()
		if not late_token.is_empty() and late_token != _wild_replay_token.strip_edges():
			_abandon_wild_fight_token(late_token)
		return
	_release_wild_replay_battle_slot()

func _wild_replay_wait_ms(data: Dictionary, unsettled: bool) -> int:
	var wait_ms: int = int(data.get("retryAfterMs", 200))
	if wait_ms < 50:
		wait_ms = 50
	if unsettled:
		if wait_ms > 1000:
			wait_ms = 1000
		return wait_ms
	if wait_ms > 120000:
		wait_ms = 120000
	return wait_ms

func _release_wild_replay_log_only() -> void :
	if battle_system == null or _tower_has_taken_battle_slot():
		return
	battle_system.replay_log_only = false

func _clear_settled_wild_replay_token(token: String) -> void :
	var tk: = token.strip_edges()
	if tk.is_empty() or tk == _wild_replay_token:
		_wild_replay_token = ""
		_wild_replay_map_difficulty = ""

func _start_wild_replay_battle_async() -> void :
	var gen: = _wild_replay_gen
	_wild_replay_abort = false
	if battle_system:
		battle_system.replay_log_only = true
		battle_system.drive_by_execute_turn = false
	if _field_battle_loot_pending.is_empty():
		_wild_replay_token = ""
	if network == null or not network.is_logged_in():
		_finish_cancelled_wild_replay(gen, {})
		return
	var map_id: = str(current_map)
	var er: Dictionary = {}
	while true:
		if _wild_replay_should_cancel(gen):
			_finish_cancelled_wild_replay(gen, {})
			return
		var op_id: = "wildrun_%d_%d" % [Time.get_unix_time_from_system(), randi()]
		var stance_player: = "attack"
		var stance_pet: = "attack"
		if player:
			player.clamp_battle_stances()
			stance_player = str(player.battle_stance_player)
			stance_pet = str(player.battle_stance_pet)
		_last_wild_run_sent_ms = Time.get_ticks_msec()
		er = await wait_economy("economy_wild_replay_run", func():
			network.economy_wild_replay_run(map_id, op_id, stance_player, stance_pet)
		, op_id)
		var late_data: Dictionary = er.get("data", {}) if er.get("data") is Dictionary else {}
		if _wild_replay_should_cancel(gen):
			_finish_cancelled_wild_replay(gen, late_data)
			return
		if bool(er.get("ok", false)):
			break
		var pace_code: = str(late_data.get("code", ""))
		if pace_code == "WILD_REPLAY_PACE" or pace_code == "WILD_REPLAY_UNSETTLED":
			var unsettled: = pace_code == "WILD_REPLAY_UNSETTLED"
			var wait_ms: = _wild_replay_wait_ms(late_data, unsettled)
			if not unsettled and wait_ms >= 2000 and battle_system:
				var sec: = maxi(1, int(round(float(wait_ms) / 1000.0)))
				battle_system.add_log("[color=orange]打得太快，约 %d 秒后开战。[/color]" % sec)
			var left_ms: = wait_ms
			while left_ms > 0:
				if _wild_replay_should_cancel(gen):
					_finish_cancelled_wild_replay(gen, {})
					return
				var step_ms: = mini(left_ms, 200)
				await get_tree().create_timer(float(step_ms) / 1000.0).timeout
				left_ms -= step_ms
			continue
		if pace_code == "WILD_REPLAY_OFF":
			_release_wild_replay_battle_slot()
			_pause_field_auto_for_loot_fail("服务器未开放野外结算，已暂停自动战斗。")
			return
		var start_err: = str(er.get("err", ""))
		if _is_field_auto_hard_stop_error(late_data, start_err):
			_release_wild_replay_battle_slot()
			var block_msg: = start_err
			if block_msg.is_empty():
				block_msg = str(late_data.get("error", ""))
			if block_msg.is_empty():
				block_msg = "战斗加速异常，已暂停自动战斗。请停止使用加速工具，否则账号将被封禁。"
			_pause_field_auto_for_loot_fail(block_msg)
			return
		_release_wild_replay_battle_slot()
		var why: = start_err.strip_edges()
		if why.is_empty():
			why = str(late_data.get("error", "")).strip_edges()
		if why.is_empty():
			why = "服务器开战失败"
		else:
			why = "服务器开战失败：%s" % why
		_defer_field_auto_after_transient(why)
		return
	var data: Dictionary = er.get("data", {}) if er.get("data") is Dictionary else {}
	_wild_replay_token = str(data.get("fightToken", "")).strip_edges()
	_wild_replay_map_difficulty = str(data.get("mapDifficulty", "")).strip_edges()
	var raw_monsters: Variant = data.get("monsters", [])
	var monsters: Array = _hydrate_wild_replay_monsters(raw_monsters if raw_monsters is Array else [])
	if monsters.is_empty() or _wild_replay_token.is_empty():
		var bad_token: = _wild_replay_token
		_wild_replay_token = ""
		_abandon_wild_fight_token(bad_token)
		_release_wild_replay_battle_slot()
		_defer_field_auto_after_transient("服务器没有给出结算票，奖励未入账")
		return
	var pet_guard: = ensure_active_pet_ready_for_battle()
	var active_pet = pet_guard.get("pet", null)
	var wild_max_rounds: = maxi(1, Monster.wild_battle_max_rounds)
	battle_system.suppress_battle_character_exp = true
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	if battle_system.battle_ended.is_connected(_on_battle_ended):
		battle_system.battle_ended.disconnect(_on_battle_ended)
	battle_system.battle_ended.connect(_on_battle_ended)
	if not battle_system.start_battle(player, active_pet, monsters, wild_max_rounds, false, resolve_attack_target_mode("wild")):
		_wild_replay_token = ""
		_release_wild_replay_log_only()
		_release_wild_replay_battle_slot()
		return
	_reset_field_auto_retry_progress()
	_log_wild_replay_monster_encounters(monsters)
	var replay: = CombatReplayPlayerClass.new()
	replay.battle_system = battle_system
	replay.log_style = "wild"
	var mine: = PackedStringArray()
	if player:
		var pn: = str(player.player_name).strip_edges()
		if not pn.is_empty():
			mine.append(pn)
	if active_pet:
		var petn: = str(active_pet.pet_name).strip_edges()
		if not petn.is_empty():
			mine.append(petn)
	if mine.is_empty():
		var pn2: = str(data.get("playerName", "")).strip_edges()
		if not pn2.is_empty():
			mine.append(pn2)
		var petn2: = str(data.get("petName", "")).strip_edges()
		if not petn2.is_empty():
			mine.append(petn2)
	replay.mine_names = mine
	replay.should_abort = func() -> bool:
		return gen != _wild_replay_gen or _wild_replay_abort or battle_system == null
	var raw_log: Variant = data.get("battleLog", data.get("battle_log", []))
	var battle_log: Array = raw_log if raw_log is Array else []
	var server_victory: = bool(data.get("victory", false))
	await replay.play_async(self, battle_log, server_victory)
	if gen != _wild_replay_gen:
		return
	_release_wild_replay_log_only()
	_release_wild_replay_battle_slot()

func _fail_tower_replay_start(msg: String) -> void :
	_tower_replay_busy = false
	_tower_replay_token = ""
	_tower_replay_server_victory = false
	in_battle = false
	if battle_system:
		battle_system.replay_log_only = false
		if battle_system.battle_ended.is_connected(_on_tower_battle_ended):
			battle_system.battle_ended.disconnect(_on_tower_battle_ended)
		battle_system.add_log("[color=orange]%s[/color]" % msg)
	if is_tower_battle:
		is_tower_battle = false
		_end_tower_run_session()

func _start_tower_replay_battle_async(floor: int) -> void :
	if stop_tower_requested or _tower_replay_abort:
		_fail_tower_replay_start("已停止天关挑战")
		return
	_tower_replay_token = ""
	_tower_replay_server_victory = false
	if network == null or not network.is_logged_in():
		_fail_tower_replay_start("天关开战失败：未登录")
		return
	var er: Dictionary = {}
	var pace_tries: int = 0
	while true:
		if _tower_replay_abort or stop_tower_requested:
			_fail_tower_replay_start("已停止天关挑战")
			return
		var op_id: = "towerrun_%d_%d" % [Time.get_unix_time_from_system(), randi()]
		er = await wait_economy("economy_tower_replay_run", func():
			network.economy_tower_replay_run(floor, op_id)
		, op_id)
		if _tower_replay_abort or stop_tower_requested:
			_fail_tower_replay_start("已停止天关挑战")
			return
		if bool(er.get("ok", false)):
			break
		var pace_data: Dictionary = er.get("data", {}) if er.get("data") is Dictionary else {}
		if str(pace_data.get("code", "")) == "TOWER_REPLAY_PACE":
			pace_tries += 1
			if pace_tries > 12:
				_fail_tower_replay_start("服务器开战失败，已停本场。可后台关闭天关录像开关。")
				return
			var wait_ms: int = int(pace_data.get("retryAfterMs", 200))
			if wait_ms < 50:
				wait_ms = 50
			if wait_ms > 20000:
				wait_ms = 20000
			await get_tree().create_timer(float(wait_ms) / 1000.0).timeout
			continue
		var err_txt: = str(er.get("err", "开战失败"))
		_fail_tower_replay_start("服务器开战失败：%s" % err_txt)
		return
	var data: Dictionary = er.get("data", {}) if er.get("data") is Dictionary else {}
	if data.has("newGold") and data.get("newGold") != null:
		player.gold = int(data.get("newGold", player.gold))
		gold_changed.emit(player.gold)
	_tower_replay_token = str(data.get("fightToken", ""))
	_tower_replay_server_victory = bool(data.get("victory", false))
	var raw_monsters: Variant = data.get("monsters", [])
	var monsters: Array = _hydrate_wild_replay_monsters(raw_monsters if raw_monsters is Array else [])
	if monsters.is_empty() or _tower_replay_token.is_empty():
		_fail_tower_replay_start("服务器开战失败，已停本场。")
		return
	var pet_guard: = ensure_active_pet_ready_for_battle()
	var active_pet = pet_guard.get("pet", null)
	var max_rounds: = maxi(1, int(data.get("battleMaxRounds", 30)))
	battle_system.suppress_battle_character_exp = true
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	if not battle_system.battle_ended.is_connected(_on_tower_battle_ended):
		battle_system.battle_ended.connect(_on_tower_battle_ended)
	if not battle_system.start_battle(player, active_pet, monsters, max_rounds, false, resolve_attack_target_mode("tower")):
		_fail_tower_replay_start("无法开始战斗，请稍后再试")
		return
	tower_battle_started.emit(floor)
	_log_wild_replay_monster_encounters(monsters)
	var replay: = CombatReplayPlayerClass.new()
	replay.battle_system = battle_system
	replay.log_style = "tower"
	var mine: = PackedStringArray()
	if player:
		var pn: = str(player.player_name).strip_edges()
		if not pn.is_empty():
			mine.append(pn)
	if active_pet:
		var petn: = str(active_pet.pet_name).strip_edges()
		if not petn.is_empty():
			mine.append(petn)
	if mine.is_empty():
		var pn2: = str(data.get("playerName", "")).strip_edges()
		if not pn2.is_empty():
			mine.append(pn2)
		var petn2: = str(data.get("petName", "")).strip_edges()
		if not petn2.is_empty():
			mine.append(petn2)
	replay.mine_names = mine
	replay.should_abort = func() -> bool:
		return _tower_replay_abort or stop_tower_requested or battle_system == null
	replay.on_hud_refresh = func() -> void :
		var main_ui: = _find_main_ui_node()
		if main_ui != null and main_ui.has_method("_refresh_active_battle_hud"):
			main_ui.call("_refresh_active_battle_hud")
	var raw_log: Variant = data.get("battleLog", data.get("battle_log", []))
	var battle_log: Array = raw_log if raw_log is Array else []
	var replay_out: Variant = await replay.play_async(self, battle_log, _tower_replay_server_victory)
	var replay_info: Dictionary = replay_out if replay_out is Dictionary else {}
	var need_settle: = is_tower_battle and not is_tower_settling
	if battle_system:
		battle_system.replay_log_only = false
	_tower_replay_busy = false
	if need_settle:
		var aborted: = bool(replay_info.get("aborted", false))
		var log_victory: = bool(replay_info.get("log_victory", false))
		if aborted and log_victory and _tower_replay_all_monsters_down() and not stop_tower_requested and not _tower_replay_abort:
			aborted = false
		var settle_win: = false
		if not aborted and not stop_tower_requested:
			settle_win = _tower_replay_server_victory or log_victory
		_on_tower_battle_ended(settle_win)

func _refresh_open_brother_tower_ui() -> void :
	var bt_ui_script: = _bt_ui()
	if bt_ui_script == null:
		return
	if bt_ui_script.has_method("refresh_active_panel_if_open"):
		bt_ui_script.refresh_active_panel_if_open(self)

func _rt_module_key_candidates(module_name: String) -> Array:
	# 服务端 /gameplay/runtime-config 下发的模块键可能是 camelCase（参考稿口径）
	# 也可能是 snake_case（本服重写后的写法），两种都要认，否则整块配置读不到、
	# 客户端会静默回落到本地默认值（图鉴天关各档都变 20 波就是这么来的）。
	var out: Array = [module_name]
	var snake_key: = ""
	for ch in module_name:
		if ch >= "A" and ch <= "Z":
			snake_key += "_" + ch.to_lower()
		else:
			snake_key += ch
	snake_key = snake_key.lstrip("_")
	if not snake_key.is_empty() and snake_key != module_name:
		out.append(snake_key)
	return out

func _rt_module(module_name: String) -> Dictionary:
	if not (gameplay_runtime_config is Dictionary):
		return {}
	for key in _rt_module_key_candidates(module_name):
		var v: Variant = gameplay_runtime_config.get(key, null)
		if v is Dictionary and not (v as Dictionary).is_empty():
			return v
	return {}

func get_lottery_runtime_config() -> Dictionary:
	var lot: Variant = gameplay_runtime_config.get("lottery", {})
	return lot if lot is Dictionary else {}

func get_tower_runtime_config() -> Dictionary:
	var tw: Variant = gameplay_runtime_config.get("tower", {})
	return tw if tw is Dictionary else {}

func get_treasure_runtime_config() -> Dictionary:
	var tr: Variant = gameplay_runtime_config.get("treasure", {})
	return tr if tr is Dictionary else {}

func get_fe_dungeon_runtime_config() -> Dictionary:
	return _rt_module("fiveElementsDungeon")

func get_brother_tower_runtime_config() -> Dictionary:
	return _rt_module("brotherTower")

func get_pet_soul_runtime_config() -> Dictionary:
	return _rt_module("petSoul")

func get_brother_tower_wave_count() -> int:
	var cfg: = get_brother_tower_runtime_config()
	var wc: = int(cfg.get("waveCount", 0))
	if wc <= 0:
		wc = _bt_mgr().WAVE_COUNT
	return maxi(1, wc)

func get_brother_tower_difficulty_preset(difficulty: String) -> Dictionary:
	var cfg: = get_brother_tower_runtime_config()
	var key: = str(difficulty).strip_edges().to_lower()
	var diffs: Variant = cfg.get("difficulties", [])
	if diffs is Array:
		for row in diffs:
			if row is Dictionary and str(row.get("id", "")) == key:
				return row
	return _bt_mgr().get_difficulty_preset(difficulty, self)

func get_brother_tower_level_range_text(difficulty: String) -> String:
	var preset: = get_brother_tower_difficulty_preset(difficulty)
	var level_start: = int(preset.get("levelStart", 5100))
	var level_end: = int(preset.get("levelEnd", 10000))
	return "%d → %d" % [level_start, level_end]

func get_suit_dungeon_runtime_config() -> Dictionary:
	return _rt_module("suitDungeon")

func get_atlas_dungeon_runtime_config() -> Dictionary:
	return _rt_module("atlasDungeon")

func get_atlas_dungeon_tier_config(tier: String) -> Dictionary:
	var cfg: = get_atlas_dungeon_runtime_config()
	var tiers: Variant = cfg.get("tiers", {})
	if tiers is Dictionary:
		var t: Variant = tiers.get(tier, {})
		return t if t is Dictionary else {}
	return {}

func get_atlas_dungeon_tier_label(tier: String) -> String:
	var tc: = get_atlas_dungeon_tier_config(tier)
	var label: = str(tc.get("label", "")).strip_edges()
	if not label.is_empty():
		return label
	match tier:
		"basic": return "初级"
		"medium": return "中级"
		"advanced": return "高级"
	return tier

func resolve_attack_target_mode(battle_kind: String) -> int:
	match battle_kind:


		_:
			return battle_system.AttackTargetMode.SEQUENTIAL

func get_wild_battle_runtime_config() -> Dictionary:
	var gp: Dictionary = gameplay_runtime_config.get("gameplay", {}) if gameplay_runtime_config.get("gameplay") is Dictionary else {}
	var wb: Variant = gp.get("wildBattle", {})
	return wb if wb is Dictionary else {}

func get_max_tower_floor() -> int:
	var cfg: = get_tower_runtime_config()
	var v: = int(cfg.get("maxFloor", 2000))
	return v if v > 0 else 2000

func get_tower_open_max_floor() -> int:
	var cfg: = get_tower_runtime_config()
	var v: = int(cfg.get("openMaxFloor", 1499))
	return v if v > 0 else 1499


func apply_effective_tower_open_max_floor(open_max: int, bypass: bool = false) -> void :
	var cap: = maxi(1, open_max)
	if not (gameplay_runtime_config is Dictionary):
		gameplay_runtime_config = {}
	var tw: Variant = gameplay_runtime_config.get("tower", {})
	var tower_cfg: Dictionary = tw.duplicate(true) if tw is Dictionary else {}
	tower_cfg["openMaxFloor"] = cap
	tower_cfg["openMaxFloorBypass"] = bypass
	gameplay_runtime_config["tower"] = tower_cfg
	TowerUI.apply_runtime_config(tower_cfg)
	print("[GameManager] 天关有效开放层已同步 openMaxFloor=", cap, " bypass=", bypass)

func _get_fe_monster_cfg() -> Dictionary:
	var cfg: = get_fe_dungeon_runtime_config()
	var m = cfg.get("monsters", {})
	return m if m is Dictionary else {}



func _on_noble_info_loaded_for_cache(data: Dictionary) -> void :
	if data == null or not data is Dictionary:
		return
	var lv: = int(data.get("nobleLevel", 0))
	var benefits = data.get("benefits", {})
	var pet_dmg: = 0
	var exp_b: = 0
	if benefits is Dictionary:
		pet_dmg = int(benefits.get("petDamage", 0))
		exp_b = int(benefits.get("expBonus", 0))
	noble_level = clampi(lv, 0, 15)
	noble_pet_damage_bonus = maxi(0, pet_dmg)
	if exp_b <= 0:
		exp_b = int(NobleBenefits.EXP_BONUS[noble_level])
	noble_exp_bonus = maxi(0, exp_b)
	print("[GameManager] 贵族缓存已更新 level=", noble_level, " pet_stat_bonus=+", noble_pet_damage_bonus, "% exp_bonus=+", noble_exp_bonus, "%")

func sync_broadcast_cursor_from_save(save_data: Dictionary) -> void :
	if save_data == null or not save_data is Dictionary:
		return
	var bumped: = false
	var from_top: = int(save_data.get("last_broadcast_id", 0))
	if from_top > _last_broadcast_id:
		_last_broadcast_id = from_top
		bumped = true
	var settings: Variant = save_data.get("gameSettings", {})
	if settings is Dictionary and settings.has("last_broadcast_id"):
		var from_settings: = int(settings.get("last_broadcast_id", 0))
		if from_settings > _last_broadcast_id:
			_last_broadcast_id = from_settings
			bumped = true
	if bumped:
		_save_broadcast_cursor()


func prepare_broadcast_session_for_login() -> void :
	_broadcast_session_anchor_ready = false
	_broadcast_anchor_pending_request = false


func begin_post_login_broadcast_sync(save_data: Dictionary = {}) -> void :
	sync_broadcast_cursor_from_save(save_data)
	prepare_broadcast_session_for_login()
	load_server_broadcasts()




func note_broadcast_history_watermark(max_id: int, seen_ids: Array = []) -> void :
	var bumped: = false
	if max_id > _last_broadcast_id:
		_last_broadcast_id = max_id
		bumped = true
	for sid in seen_ids:
		var bid: = int(sid)
		if bid > 0:
			_seen_broadcast_ids[bid] = true
	if bumped:
		_save_broadcast_cursor()
	if _seen_broadcast_ids.size() > 2000:
		_seen_broadcast_ids.clear()
		for sid in seen_ids:
			var bid2: = int(sid)
			if bid2 > 0:
				_seen_broadcast_ids[bid2] = true
	print("[GameManager] 广播历史水位: max_id=", max_id, " cursor=", _last_broadcast_id)


func _sort_broadcast_rows(rows: Array) -> Array:
	var sorted_rows: Array = rows.duplicate()
	sorted_rows.sort_custom( func(a, b):
		return int((a if a is Dictionary else {}).get("id", 0)) < int((b if b is Dictionary else {}).get("id", 0))
	)
	return sorted_rows


func _on_broadcasts_loaded(broadcasts: Array):
	var ordered_broadcasts: = _sort_broadcast_rows(broadcasts)
	print("[GameManager] _on_broadcasts_loaded: count=", ordered_broadcasts.size())
	var max_broadcast_id: = _last_broadcast_id
	for broadcast in ordered_broadcasts:
		var msg = broadcast.get("content", "")
		var broadcast_id = int(broadcast.get("id", 0))
		print("[GameManager] broadcast: id=", broadcast_id, " msg=", msg.left(50))
		if broadcast_id > max_broadcast_id:
			max_broadcast_id = broadcast_id
	if _broadcast_anchor_pending_request:

		_broadcast_anchor_pending_request = false
		_broadcast_session_anchor_ready = true
		if max_broadcast_id > _last_broadcast_id:
			_last_broadcast_id = max_broadcast_id
			_save_broadcast_cursor()
		_broadcast_first_fetch_done = true
		print("[GameManager] 广播会话锚点已建立，anchor_id=", _last_broadcast_id)
		return
	for broadcast in ordered_broadcasts:
		var row: Dictionary = broadcast if broadcast is Dictionary else {}
		var msg: String = _bt_mgr().format_clear_broadcast_message(str(row.get("content", "")), row, self)
		var broadcast_id = int(row.get("id", 0))
		var should_emit: = true
		if broadcast_id > 0:
			if _seen_broadcast_ids.has(broadcast_id):
				should_emit = false
			elif broadcast_id <= _last_broadcast_id:
				should_emit = false
			else:
				_seen_broadcast_ids[broadcast_id] = true
		if should_emit and not msg.is_empty():
			if _mark_broadcast_shown(msg):
				world_announcement.emit(msg)
	if max_broadcast_id > _last_broadcast_id:
		_last_broadcast_id = max_broadcast_id
		_save_broadcast_cursor()
	_broadcast_first_fetch_done = true
	if _seen_broadcast_ids.size() > 2000:
		_seen_broadcast_ids.clear()
	print("[GameManager] _last_broadcast_id updated to=", _last_broadcast_id)

func _on_broadcast_sent(success: bool):
	if success:
		var pending: = _pending_server_broadcast_text.strip_edges()
		if not pending.is_empty():
			_mark_broadcast_shown(pending)
			_pending_server_broadcast_text = ""
		print("[GameManager] 广播发送成功")
	else:
		_pending_server_broadcast_text = ""
		print("[GameManager] 广播发送失败")

func load_server_broadcasts():
	if network and network.is_logged_in():
		if not _broadcast_session_anchor_ready:
			if _broadcast_anchor_pending_request:
				return
			_broadcast_anchor_pending_request = true

			print("[GameManager] 建立广播会话锚点(跳最新): prev_cursor=", _last_broadcast_id)
			network.xianmo_get_broadcasts(0, 1)
			return
		print("[GameManager] load_server_broadcasts: last_id=", _last_broadcast_id)
		network.xianmo_get_broadcasts(_last_broadcast_id)

func _load_broadcast_cursor() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(BROADCAST_CURSOR_CONFIG_PATH) != OK:
		return
	var saved_last_id: = int(cfg.get_value("broadcast", "last_id", 0))
	if saved_last_id > _last_broadcast_id:
		_last_broadcast_id = saved_last_id
		print("[GameManager] 加载广播游标成功: ", _last_broadcast_id)

func _save_broadcast_cursor() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("broadcast", "last_id", _last_broadcast_id)
	var save_result: = cfg.save(BROADCAST_CURSOR_CONFIG_PATH)
	if save_result != OK:
		push_warning("[GameManager] 广播游标落盘失败: %s" % str(save_result))

func send_server_broadcast(broadcast_type: String, content: String, extra_data: Dictionary = {}):
	if network and network.is_logged_in():
		_pending_server_broadcast_text = _broadcast_fingerprint(content)
		network.xianmo_send_broadcast(broadcast_type, content, extra_data)

func _build_inventory_upload_data(compact_mode: bool) -> Dictionary:
	var inventory_data = inventory_manager.to_dict() if inventory_manager else {}
	if not compact_mode:
		return inventory_data
	if not (inventory_data is Dictionary):
		return {}
	var sanitized: Dictionary = inventory_data.duplicate(true)
	sanitized.erase("equipment_warehouse")
	# `pet_equipment_items` 以前也在这里被 erase 掉，理由是"服务端有权威副本"。
	# 实际上服务端从来没有真正接管过这份背包（老账号服务端侧一直是空表），
	# 结果就是：/pet-equipment/equip 的回包带着 `pet_equipment_items: []`，
	# 客户端 `inventory_manager.from_dict` 见到空数组就把本地背包清空 ——
	# 玩家点一次「穿戴」，背包里剩下的宠装全没了。
	# 改成照常上传（最大 50 件，体积可忽略），服务端已声明为 restricted 字段，
	# 它那边有内容时以它为准，空表时收下客户端这份，两边自然收敛。
	sanitized.erase("pet_equipment_warehouse")
	return sanitized

func upload_cloud_save(compact_mode: bool = false, reason: String = ""):
	if not network or not network.is_logged_in():
		_defer_rankings_next_upload = false
		_force_compact_authority_next_upload = false
		print("未登录，无法上传云存档")
		return
	if not _cloud_sync_gate_passed:
		push_warning("[GameManager] 云同步门未通过，取消 upload_cloud_save")
		_defer_rankings_next_upload = false
		_force_compact_authority_next_upload = false
		return

	if not player or not pet_manager:
		_defer_rankings_next_upload = false
		_force_compact_authority_next_upload = false
		print("系统未初始化，无法上传")
		return
	var defer_rankings: = _defer_rankings_next_upload
	var force_compact_authority: = _force_compact_authority_next_upload
	var upload_reason: = reason.strip_edges()
	if is_field_battle_loot_upload_blocked() and not _is_authority_layout_upload_reason(upload_reason):
		push_warning("[GameManager] battle-loot 结算中，跳过云上传")
		_defer_rankings_next_upload = false
		_force_compact_authority_next_upload = false
		return
	_defer_rankings_next_upload = false
	_force_compact_authority_next_upload = false
	compact_mode = compact_mode or force_compact_authority
	if upload_reason.is_empty():
		upload_reason = "manual_upload" if not compact_mode else "compact_upload"

	var player_data = player.to_dict()
	player_data["timestamp"] = Time.get_unix_time_from_system()


	var pets_data_with_active: Dictionary = pet_manager.to_dict() if pet_manager else {
		"pets": [], 
		"pet_bag": [], 
		"assist_pets": [], 
		"active_pet_id": "", 
	}

	var inventory_data = _build_inventory_upload_data(compact_mode)
	var equipment_data = {} if compact_mode else (equipment_manager.to_dict() if equipment_manager else {})
	var martial_arts_data = martial_arts_manager.to_dict() if martial_arts_manager else {}
	var crafting_data = crafting_manager.to_dict() if crafting_manager else {}
	var pet_collection_data = pet_collection_manager.to_dict() if pet_collection_manager else {}
	if pet_soul_manager:
		pet_collection_data = pet_collection_data.duplicate(true)
		pet_collection_data["pet_soul_data"] = pet_soul_manager.to_dict()
	var pet_equipment_data = {} if compact_mode else (pet_equipment_manager.to_dict() if pet_equipment_manager else {})
	var suit_data = {} if compact_mode else (suit_manager.to_dict() if suit_manager else {})
	var quest_data = quest_manager.to_dict() if quest_manager else {}

	var game_settings = {
		"current_map": current_map, 
		"previous_map": previous_map, 
		"is_tower_battle": is_tower_battle, 
		"is_suit_dungeon_battle": is_suit_dungeon_battle, 
		"is_tower_settling": is_tower_settling, 
		"auto_capture_enabled": auto_capture_enabled, 
		"min_growth_threshold": min_growth_threshold, 
		"bgm_enabled": bgm_enabled, 
		"bgm_volume": bgm_volume, 
		"last_broadcast_id": _last_broadcast_id, 
		"save_revision": _cloud_save_revision, 
		"compact_mode": compact_mode
	}
	if fabao_manager:
		var diff_for_upload: = str(fabao_manager.map_difficulty_for_upload())
		if not diff_for_upload.is_empty():
			game_settings["current_map_difficulty"] = diff_for_upload
	if compact_mode:
		# `inventoryData.pet_equipment_items` 不在这里声明：这份背包现在照常上传，
		# 服务端按 id 求并集（`_merge_authoritative_progress`）。一旦声明成 restricted，
		# 服务端会用自己那份（老账号是空表/残缺表）把客户端上传的整格覆盖掉，
		# 玩家背包里剩下的宠装就会越来越少。
		game_settings["restricted_authority_fields"] = ["equipmentData", "suitData", "petEquipmentData", "inventoryData.equipment_warehouse", "inventoryData.pet_equipment_warehouse"]
	if defer_rankings:
		game_settings["defer_rankings"] = true
	var omit_pets: = _omit_pets_next_upload or _is_martial_layout_cloud_upload_reason(upload_reason)
	if omit_pets:
		game_settings["omit_pets"] = true
		_omit_pets_next_upload = false
	game_settings["upload_reason"] = upload_reason
	game_settings["operationId"] = "%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]

	network.upload_save(player_data, pets_data_with_active, inventory_data, equipment_data, martial_arts_data, crafting_data, game_settings, pet_collection_data, pet_equipment_data, suit_data, quest_data, compact_mode)
	print("正在上传云存档... reason=%s compact=%s" % [upload_reason, str(compact_mode)])

func _on_cloud_save_uploaded(success: bool):
	if success:
		print("云存档上传成功")
		# 注意：这里**不能**清 `_current_map_pending_cloud_sync`。
		# change_map() 会同时发一个 /save/upload（包里还是旧地图）和一个
		# /player/set-current-map。上传包先回来就把标志清掉的话，随后旧存档
		# 回灌时 apply_cloud_save 会把 current_map 改回旧图 → 自动换图看起来在乱切。
		# 这个标志只由 set_current_map 的 on_ok / on_fail 清。
		_active_pet_pending_cloud_sync = false
		_pet_bag_op_pending_cloud_sync = false
		if pet_manager:
			pet_manager.flush_pending_pet_medal_syncs("")
	else:
		print("云存档上传失败")
	cloud_save_uploaded.emit(success)


func perform_quit_cloud_sync() -> void :
	if not player or not pet_manager:
		quit_sync_finished.emit(QUIT_SYNC_SAVE_FAIL)
		return
	if not network or not network.is_logged_in():
		if save_game(false):
			quit_sync_finished.emit(QUIT_SYNC_LOCAL_ONLY)
		else:
			quit_sync_finished.emit(QUIT_SYNC_SAVE_FAIL)
		return
	if not _cloud_sync_gate_passed:
		if save_game(false):
			quit_sync_finished.emit(QUIT_SYNC_GATE_BLOCKED)
		else:
			quit_sync_finished.emit(QUIT_SYNC_SAVE_FAIL)
		return
	var handler: = func(success: bool):
		if success:
			quit_sync_finished.emit(QUIT_SYNC_SYNC_DONE)
		else:
			quit_sync_finished.emit(QUIT_SYNC_UPLOAD_FAIL)
	cloud_save_uploaded.connect(handler, CONNECT_ONE_SHOT)
	if not save_game(true):
		if cloud_save_uploaded.is_connected(handler):
			cloud_save_uploaded.disconnect(handler)
		quit_sync_finished.emit(QUIT_SYNC_SAVE_FAIL)

func create_secure_op_snapshot() -> Dictionary:
	return {
		"player": player.to_dict() if player else {}, 
		"pets": pet_manager.to_dict() if pet_manager else {}, 
		"inventory": inventory_manager.to_dict() if inventory_manager else {}, 
		"equipment": equipment_manager.to_dict() if equipment_manager else {}, 
		"martial_arts": martial_arts_manager.to_dict() if martial_arts_manager else {}, 
		"crafting": crafting_manager.to_dict() if crafting_manager else {}, 
		"pet_collection": pet_collection_manager.to_dict() if pet_collection_manager else {}, 
		"pet_equipment": pet_equipment_manager.to_dict() if pet_equipment_manager else {}, 
		"pet_soul": pet_soul_manager.to_dict() if pet_soul_manager else {}, 
		"suit": suit_manager.to_dict() if suit_manager else {}, 
		"quest": quest_manager.to_dict() if quest_manager else {}, 
		"xianmo": xianmo_system.to_dict() if xianmo_system else {}, 
		"xianmo_ranking": xianmo_ranking.to_dict() if xianmo_ranking else {}, 
		"xianmo_chest": xianmo_chest_manager.to_dict() if xianmo_chest_manager else {}
	}

func restore_secure_op_snapshot(snapshot: Dictionary) -> void :
	if snapshot.is_empty():
		return
	if player and snapshot.has("player"):
		player.from_dict(snapshot.get("player", {}))
		gold_changed.emit(player.gold)
		yuanbao_changed.emit(player.yuanbao_currency)
	if pet_manager and snapshot.has("pets"):
		pet_manager.from_dict(snapshot.get("pets", {}))
	if inventory_manager and snapshot.has("inventory"):
		inventory_manager.from_dict(snapshot.get("inventory", {}))
	if equipment_manager and snapshot.has("equipment"):
		equipment_manager.from_dict(snapshot.get("equipment", {}))
	if martial_arts_manager and snapshot.has("martial_arts"):
		martial_arts_manager.from_dict(snapshot.get("martial_arts", {}))
	if crafting_manager and snapshot.has("crafting"):
		crafting_manager.from_dict(snapshot.get("crafting", {}))
	if pet_collection_manager and snapshot.has("pet_collection"):
		pet_collection_manager.from_dict(snapshot.get("pet_collection", {}))
	if pet_equipment_manager and snapshot.has("pet_equipment"):
		pet_equipment_manager.from_dict(snapshot.get("pet_equipment", {}))
	if pet_soul_manager and snapshot.has("pet_soul"):
		pet_soul_manager.from_dict(snapshot.get("pet_soul", {}))
	if suit_manager and snapshot.has("suit"):
		suit_manager.from_dict(snapshot.get("suit", {}))
	if quest_manager and snapshot.has("quest"):
		quest_manager.from_dict(snapshot.get("quest", {}))
	if xianmo_system and snapshot.has("xianmo"):
		xianmo_system.from_dict(snapshot.get("xianmo", {}))
	if xianmo_ranking and snapshot.has("xianmo_ranking"):
		xianmo_ranking.from_dict(snapshot.get("xianmo_ranking", {}))
	if xianmo_chest_manager and snapshot.has("xianmo_chest"):
		xianmo_chest_manager.from_dict(snapshot.get("xianmo_chest", {}))
	player_profile_restored.emit()


const COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC: float = 120.0




func save_local_and_force_cloud_upload() -> bool:
	return save_local_and_force_cloud_upload_with_reason("legacy_full_force_upload")

func save_local_and_force_cloud_upload_with_reason(reason: String) -> bool:
	var upload_reason: = reason.strip_edges()
	if upload_reason.is_empty():
		upload_reason = "full_force_upload"
	_suppress_general_cloud_upload_until_ms = 0
	print("[CloudSync] full force upload requested (authority fields included), reason=%s" % upload_reason)
	_force_compact_authority_next_upload = false
	return save_game(true, upload_reason)


func save_local_and_force_cloud_upload_authority_compact() -> bool:
	return save_local_and_force_cloud_upload_authority_compact_with_reason("legacy_authority_compact_force_upload")

func save_local_and_force_cloud_upload_authority_compact_with_reason(reason: String) -> bool:
	var upload_reason: = reason.strip_edges()
	if upload_reason.is_empty():
		upload_reason = "authority_compact_force_upload"
	_suppress_general_cloud_upload_until_ms = 0
	print("[CloudSync] authority-compact force upload requested, reason=%s" % upload_reason)
	_force_compact_authority_next_upload = true
	return save_game(true, upload_reason)

func _build_pet_roster_sync_payload() -> Array:
	var out: Array = []
	if pet_manager == null:
		return out
	for pet in pet_manager.get_all_pets():
		if pet:
			out.append(pet.to_dict())
	return out

func _on_pet_roster_sync_completed(ok: bool, data: Dictionary) -> void :
	_pet_roster_sync_wait_state["done"] = true
	_pet_roster_sync_wait_state["ok"] = ok
	if ok:
		_pet_roster_sync_wait_state["data"] = data
		var srv_rev: = int(data.get("saveRevision", -1))
		if srv_rev >= 0:
			_set_cloud_save_revision(srv_rev)
		_active_pet_pending_cloud_sync = false
		var save_var: Variant = data.get("saveData", null)
		if save_var is Dictionary and not (save_var as Dictionary).is_empty():
			apply_cloud_save(save_var, {"pets_authoritative": true})
	else:
		_pet_roster_sync_wait_state["error"] = str(data.get("error", "主战栏同步失败"))
		_active_pet_pending_cloud_sync = false


func sync_active_pet_roster_to_cloud() -> void :
	if network == null or not network.is_logged_in() or not _cloud_sync_gate_passed:
		return
	if _active_pet_pending_cloud_sync:
		return
	if pet_manager == null or pet_manager.active_pet == null:
		return
	var roster: = _build_pet_roster_sync_payload()
	if roster.is_empty():
		return
	var active_id: = str(pet_manager.active_pet.id)
	var op_id: = "pet_roster_sync_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	_active_pet_pending_cloud_sync = true
	_pet_roster_sync_wait_state = {"started": true, "done": false, "ok": false, "data": {}, "error": ""}
	var on_ok: = func(d: Dictionary):
		_on_pet_roster_sync_completed(true, d)
	var on_fail: = func(err: String):
		_on_pet_roster_sync_completed(false, {"error": err})
	network.pet_roster_sync_success.connect(on_ok, CONNECT_ONE_SHOT)
	network.pet_roster_sync_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.pet_roster_sync(op_id, roster, active_id, _cloud_save_revision)

func sync_active_pet_switch_to_cloud() -> void :
	sync_active_pet_roster_to_cloud()

func await_active_pet_roster_cloud_sync(max_wait_sec: float = 15.0) -> bool:
	if network == null or not network.is_logged_in():
		return true
	if not bool(_pet_roster_sync_wait_state.get("started", false)):
		return true
	if bool(_pet_roster_sync_wait_state.get("done", false)):
		return bool(_pet_roster_sync_wait_state.get("ok", false))
	var start_ms: = Time.get_ticks_msec()
	var max_ms: = int(max_wait_sec * 1000.0)
	while not bool(_pet_roster_sync_wait_state.get("done", false)):
		if Time.get_ticks_msec() - start_ms >= max_ms:
			push_warning("[GameManager] pet roster sync timeout (%.1fs)" % max_wait_sec)
			_active_pet_pending_cloud_sync = false
			return false
		await get_tree().process_frame
	return bool(_pet_roster_sync_wait_state.get("ok", false))


func await_active_pet_switch_cloud_sync(max_wait_sec: float = 15.0) -> bool:
	return await await_active_pet_roster_cloud_sync(max_wait_sec)

func _on_pet_collection_updated_for_save(_pet_id: String, _new_count: int) -> void :
	pass

func _is_martial_layout_cloud_upload_reason(upload_reason: String) -> bool:
	var reason: = upload_reason.strip_edges()
	return (
		reason == "martial_forget" or reason.begins_with("martial_forget:")
		or reason == "martial_equip" or reason.begins_with("martial_equip:")
	)


func _is_authority_layout_upload_reason(upload_reason: String) -> bool:
	var reason: = upload_reason.strip_edges()
	if reason == "change_map" or reason.begins_with("change_map:"):
		return true
	if reason == "pet_park_auto_capture_settings" or reason.begins_with("pet_park_auto_capture_settings:"):
		return true
	if reason == "pet_lock_toggle" or reason.begins_with("pet_lock_toggle:"):
		return true
	if reason == "martial_learn_result" or reason.begins_with("martial_learn_result:"):
		return true
	if reason == "martial_create_sync" or reason.begins_with("martial_create"):
		return true
	return _is_martial_layout_cloud_upload_reason(reason)

func save_martial_forget_to_cloud(art_id: String = "") -> void :
	_omit_pets_next_upload = true
	if network != null and network.is_logged_in() and _cloud_sync_gate_passed and not art_id.strip_edges().is_empty():
		_request_martial_forget_authority(art_id.strip_edges())
		return
	save_local_and_force_cloud_upload_authority_compact_with_reason("martial_forget")
	_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 5000)

func save_martial_equip_to_cloud() -> void :
	_omit_pets_next_upload = true
	if network != null and network.is_logged_in() and _cloud_sync_gate_passed and martial_arts_manager != null:
		_request_martial_sync_layout_authority()
		return
	save_local_and_force_cloud_upload_authority_compact_with_reason("martial_equip")
	_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 5000)

func _apply_martial_layout_authority_ack(data: Dictionary) -> void :


	if data.has("saveRevision"):
		_set_cloud_save_revision(int(data.get("saveRevision", -1)))
	var sd: Variant = data.get("saveData", null)
	if sd is Dictionary:
		var gs: Variant = (sd as Dictionary).get("gameSettings", {})
		if gs is Dictionary and (gs as Dictionary).has("save_revision"):
			_set_cloud_save_revision(int((gs as Dictionary).get("save_revision", -1)))
		if (sd as Dictionary).has("saveRevision"):
			_set_cloud_save_revision(int((sd as Dictionary).get("saveRevision", -1)))
	save_game(false)
	_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 5000)

func _request_martial_sync_layout_authority() -> void :
	if network == null or martial_arts_manager == null:
		return
	var snapshot: Dictionary = martial_arts_manager.to_dict()
	var op_id: = "martial_sync_layout_%d_%d" % [Time.get_unix_time_from_system(), randi()]
	var on_ok: = func(data: Dictionary):
		_apply_martial_layout_authority_ack(data if data is Dictionary else {})
	var on_fail: = func(err: String):
		push_warning("[GameManager] martial/sync-layout 失败，回退 compact 上传: %s" % err)
		save_local_and_force_cloud_upload_authority_compact_with_reason("martial_equip")
		_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 5000)
	if not network.martial_sync_layout_success.is_connected(on_ok):
		network.martial_sync_layout_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not network.martial_sync_layout_failed.is_connected(on_fail):
		network.martial_sync_layout_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.martial_sync_layout(snapshot, op_id)

func _request_martial_forget_authority(art_id: String) -> void :
	if network == null:
		return
	var op_id: = "martial_forget_%s_%d_%d" % [art_id, Time.get_unix_time_from_system(), randi()]
	var on_ok: = func(data: Dictionary):
		_apply_martial_layout_authority_ack(data if data is Dictionary else {})
	var on_fail: = func(err: String):
		push_warning("[GameManager] martial/forget 失败，回退 compact 上传: %s" % err)
		save_local_and_force_cloud_upload_authority_compact_with_reason("martial_forget")
		_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 5000)
	if not network.martial_forget_success.is_connected(on_ok):
		network.martial_forget_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not network.martial_forget_failed.is_connected(on_fail):
		network.martial_forget_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.martial_forget(art_id, op_id)

func _await_cloud_revision_sync_if_needed(max_wait_sec: float) -> void :
	if not network or not network.is_upload_revision_sync_in_progress():
		return
	var dl_state: = {"done": false}
	var on_dl: = func(_success: bool, _sd: Dictionary):
		dl_state["done"] = true
	if not cloud_save_downloaded.is_connected(on_dl):
		cloud_save_downloaded.connect(on_dl, CONNECT_ONE_SHOT)
	var dl_start: = Time.get_ticks_msec()
	while not bool(dl_state.get("done", false)):
		if (Time.get_ticks_msec() - dl_start) / 1000.0 >= max_wait_sec:
			break
		await get_tree().process_frame

func _await_field_battle_loot_drain(max_sec: float = 15.0) -> void :
	if _field_battle_loot_pending.is_empty():
		return
	var start_ms: = Time.get_ticks_msec()
	while not _field_battle_loot_pending.is_empty():
		if (Time.get_ticks_msec() - start_ms) / 1000.0 >= max_sec:
			push_warning("[GameManager] battle-loot drain 超时 (%.1fs)，仍有 %d 笔 pending" % [max_sec, _field_battle_loot_pending.size()])
			break
		await get_tree().process_frame

func _mark_secure_upload_wait_skipped(st: Dictionary, on_upload: Callable, reason: String) -> void :
	push_warning("[CloudSync] 强制上传未发起：%s" % reason)
	if on_upload.is_valid() and cloud_save_uploaded.is_connected(on_upload):
		cloud_save_uploaded.disconnect(on_upload)
	st["valid"] = false
	st["finished"] = true
	st["upload_ok"] = false

func start_force_cloud_upload_wait(reason: String, compact_authority: bool, max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> Dictionary:
	if not network or not network.is_logged_in():
		return {"valid": false, "finished": true, "upload_ok": false}
	var upload_reason: = reason.strip_edges()
	if upload_reason.is_empty():
		upload_reason = "force_cloud_upload_wait"
	var st: Dictionary = {
		"valid": true, 
		"finished": false, 
		"upload_ok": false, 
		"max_wait_sec": max_wait_sec, 
		"start_ms": Time.get_ticks_msec(), 
	}
	var on_upload = func(success: bool):
		st["upload_ok"] = success
		st["finished"] = true
		print("[CloudSync] force upload wait finished success=%s reason=%s" % [str(success), upload_reason])
	st["on_upload"] = on_upload
	cloud_save_uploaded.connect(on_upload, CONNECT_ONE_SHOT)
	var save_ok: = false
	if compact_authority:
		save_ok = save_local_and_force_cloud_upload_authority_compact_with_reason(upload_reason)
	else:
		save_ok = save_local_and_force_cloud_upload_with_reason(upload_reason)
	if not save_ok:
		_mark_secure_upload_wait_skipped(st, on_upload, "save_game 返回 false reason=%s" % upload_reason)
		return st
	if not _cloud_upload_dispatched_this_save:
		_mark_secure_upload_wait_skipped(st, on_upload, "云上传被门控跳过 reason=%s" % upload_reason)
	return st

func force_cloud_upload_and_wait(reason: String, compact_authority: bool, max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> bool:
	if network:
		network.reset_upload_revision_retry_slot()
	var drain_sec: = minf(max_wait_sec, 15.0)
	await _await_field_battle_loot_drain(drain_sec)
	var st = start_force_cloud_upload_wait(reason, compact_authority, max_wait_sec)
	var ok: = await wait_commit_secure_op(st)
	if ok:
		return true
	await _await_cloud_revision_sync_if_needed(max_wait_sec)
	if network and network.consume_upload_revision_retry_slot():
		await _await_field_battle_loot_drain(drain_sec)
		st = start_force_cloud_upload_wait(reason, compact_authority, max_wait_sec)
		return await wait_commit_secure_op(st)
	return false


func align_cloud_save_on_navigation(tag: String) -> void :
	if not player or not pet_manager:
		return
	if not network or not network.is_logged_in():
		return
	print("[CloudSync] align tag=%s" % tag)
	save_game(false, "navigation_align:%s" % tag)



func start_commit_secure_op(max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> Dictionary:
	if not network or not network.is_logged_in():
		print("[CloudSync] commit_secure_op 跳过：未登录")
		return {"valid": false}
	var st: Dictionary = {
		"valid": true, 
		"finished": false, 
		"upload_ok": false, 
		"max_wait_sec": max_wait_sec, 
		"start_ms": Time.get_ticks_msec(), 
	}
	var on_upload = func(success: bool):
		st["upload_ok"] = success
		st["finished"] = true
		print("[CloudSync] commit_secure_op 收到 cloud_save_uploaded success=%s" % str(success))
	st["on_upload"] = on_upload
	cloud_save_uploaded.connect(on_upload, CONNECT_ONE_SHOT)
	print("[CloudSync] commit_secure_op 开始 save_game(true)，最长等待 %.1fs" % max_wait_sec)
	if not save_game(true):
		_mark_secure_upload_wait_skipped(st, on_upload, "save_game 返回 false")
		print("[CloudSync] commit_secure_op 失败：save_game 返回 false")
		return st
	if not _cloud_upload_dispatched_this_save:
		_mark_secure_upload_wait_skipped(st, on_upload, "云上传被门控跳过")
		print("[CloudSync] commit_secure_op 失败：未发起云上传")
	return st



func wait_commit_secure_op(st: Dictionary) -> bool:
	if not bool(st.get("valid", false)):
		return false
	var max_wait_sec: float = float(st.get("max_wait_sec", COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC))
	var start_ms: int = int(st.get("start_ms", 0))
	var on_upload: Callable = st.get("on_upload", Callable())
	while not bool(st.get("finished", false)):
		if (Time.get_ticks_msec() - start_ms) / 1000.0 >= max_wait_sec:
			if on_upload.is_valid() and cloud_save_uploaded.is_connected(on_upload):
				cloud_save_uploaded.disconnect(on_upload)
			push_warning("[GameManager] commit_secure_op 等待云端确认超时 (%.1fs)" % max_wait_sec)
			return false
		if network and network.is_upload_revision_sync_in_progress():
			await _await_cloud_revision_sync_if_needed(max_wait_sec)
		await get_tree().process_frame
	print("[CloudSync] commit_secure_op 完成 upload_ok=%s" % str(st.get("upload_ok", false)))
	return bool(st.get("upload_ok", false))



func commit_secure_op(max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> bool:
	if network:
		network.reset_upload_revision_retry_slot()
	var st = start_commit_secure_op(max_wait_sec)
	var ok: = await wait_commit_secure_op(st)
	if ok:
		return true
	await _await_cloud_revision_sync_if_needed(max_wait_sec)
	if network and network.consume_upload_revision_retry_slot():
		st = start_commit_secure_op(max_wait_sec)
		return await wait_commit_secure_op(st)
	return false

func _force_pull_cloud_after_transition_failure(timeout_sec: float = 20.0) -> bool:
	if not network or not network.is_logged_in():
		return false
	var state: = {"done": false, "ok": false}
	var on_downloaded: = func(success: bool, _save_data: Dictionary):
		state["done"] = true
		state["ok"] = bool(success)
	if not cloud_save_downloaded.is_connected(on_downloaded):
		cloud_save_downloaded.connect(on_downloaded, CONNECT_ONE_SHOT)
	download_cloud_save()
	var start_ms: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if (Time.get_ticks_msec() - start_ms) / 1000.0 >= timeout_sec:
			break
		await get_tree().process_frame
	return bool(state.get("ok", false))




func commit_realm_transition(snapshot: Dictionary, action_name: String = "关键操作", apply_transition: Callable = Callable(), max_wait_sec: float = COMMIT_SECURE_OP_DEFAULT_MAX_WAIT_SEC) -> Dictionary:
	var transition_result: Dictionary = {}
	_clear_deferred_attr_authoritative_save()
	if network and network.is_logged_in():
		if pet_manager:
			pet_manager.flush_pending_pet_medal_syncs("max_level_reward")
		if apply_transition.is_valid():
			var local_result: Variant = apply_transition.call()
			if local_result is Dictionary:
				transition_result = (local_result as Dictionary).duplicate(true)
			if not (local_result is Dictionary) or not bool(transition_result.get("success", false)):
				restore_secure_op_snapshot(snapshot)
				var fail_msg: = str(transition_result.get("message", "")) if local_result is Dictionary else ""
				if fail_msg.is_empty():
					fail_msg = "%s失败" % action_name
				return {"success": false, "message": fail_msg, "transition_result": transition_result}
		var transition_type: = "ascend"
		if String(action_name) == "投胎":
			transition_type = "reincarnate"
		var op_id: = "realm_%s_%s_%s" % [transition_type, str(Time.get_unix_time_from_system()), str(randi())]
		_suppress_general_cloud_upload_until_ms = maxi(
			_suppress_general_cloud_upload_until_ms, 
			Time.get_ticks_msec() + 15000
		)
		var player_data: Dictionary = player.to_dict() if player else {}
		var state: = {"done": false, "ok": false, "payload": {}}
		var on_success = func(data: Dictionary):
			state["done"] = true
			state["ok"] = true
			state["payload"] = data
		var on_failed = func(err_msg: String):
			state["done"] = true
			state["ok"] = false
			state["payload"] = {"error": err_msg}
		network.realm_transition_success.connect(on_success, CONNECT_ONE_SHOT)
		network.realm_transition_failed.connect(on_failed, CONNECT_ONE_SHOT)
		await get_tree().process_frame
		network.realm_transition(transition_type, player_data, op_id)
		var start_ms: = Time.get_ticks_msec()
		while not bool(state.get("done", false)):
			if (Time.get_ticks_msec() - start_ms) / 1000.0 >= max_wait_sec:
				state["done"] = true
				state["ok"] = false
				state["payload"] = {"error": "服务器响应超时，请稍后重试"}
				break
			await get_tree().process_frame
		if bool(state.get("ok", false)):
			var payload: Dictionary = state.get("payload", {})
			if payload.get("duplicate", false):
				_finalize_realm_transition_field_exp_state()
				_realm_transition_duplicate_download_pending = true
				await _force_pull_cloud_after_transition_failure(20.0)
				_realm_transition_duplicate_download_pending = false
				return {"success": true, "message": "", "transition_result": transition_result}
			var save_data = payload.get("saveData", {})
			if save_data is Dictionary and not save_data.is_empty():
				apply_cloud_save(save_data, {
					"realm_transition_slice": true, 
					"preserve_local_pets_not_in_cloud": true, 
					"skip_pet_collection_trim": true, 
					"skip_deferred_cloud_save": true, 
				})
			_finalize_realm_transition_field_exp_state()
			# 服务端 /player/realm/transition 是个只回 {success, reincarnation} 的桩：
			# 不回存档，也不会替我们落库。新境界只活在本地内存里，
			# 不主动推一次的话，玩家一退出重登就回到旧境界（飞升白做）。
			if not (save_data is Dictionary) or (save_data as Dictionary).is_empty():
				var realm_push_ok: bool = await force_cloud_upload_and_wait("realm_transition_result", true, 30.0)
				print("[CloudSync] 境界转换：结果上传%s" % ("成功" if realm_push_ok else "失败"))
			_suppress_general_cloud_upload_until_ms = maxi(
				_suppress_general_cloud_upload_until_ms, 
				Time.get_ticks_msec() + 15000
			)
			if payload.has("saveRevision"):
				_set_cloud_save_revision(int(payload.get("saveRevision", -1)))
			return {"success": true, "message": "", "transition_result": transition_result}
		restore_secure_op_snapshot(snapshot)
		var pulled = await _force_pull_cloud_after_transition_failure(20.0)
		var fail_payload: Dictionary = state.get("payload", {})
		var err_text = str(fail_payload.get("error", "同步失败"))
		if pulled:
			return {"success": false, "message": "%s结果未提交到服务端，已回滚并同步最新云档。%s" % [action_name, err_text], "transition_result": transition_result}
		return {"success": false, "message": "%s结果未提交到服务端，已回滚。请检查网络后重试。%s" % [action_name, err_text], "transition_result": transition_result}
	if apply_transition.is_valid():
		var offline_result: Variant = apply_transition.call()
		if offline_result is Dictionary:
			transition_result = (offline_result as Dictionary).duplicate(true)
		if not (offline_result is Dictionary) or not bool(transition_result.get("success", false)):
			restore_secure_op_snapshot(snapshot)
			var offline_fail: = str(transition_result.get("message", "")) if offline_result is Dictionary else ""
			if offline_fail.is_empty():
				offline_fail = "%s失败" % action_name
			return {"success": false, "message": offline_fail, "transition_result": transition_result}
	var persisted_ok = save_game()
	if not persisted_ok:
		restore_secure_op_snapshot(snapshot)
		return {"success": false, "message": "%s结果未能写入本地存档，已回滚。" % action_name, "transition_result": transition_result}
	_finalize_realm_transition_field_exp_state()
	return {"success": true, "message": "", "transition_result": transition_result}

func download_cloud_save():
	if not network or not network.is_logged_in():
		print("未登录，无法下载云存档")
		cloud_save_downloaded.emit(false, {})
		return

	network.download_save()
	print("正在下载云存档...")

func _merge_offline_claim_response_into_save_data(save_data: Dictionary, d: Dictionary) -> void :
	var srv: Variant = d.get("playerData", {})
	if srv is Dictionary and not (srv as Dictionary).is_empty():
		save_data["playerData"] = (srv as Dictionary).duplicate(true)
	else:
		var pd: Variant = save_data.get("playerData", {})
		if not pd is Dictionary:
			pd = {}
		if d.has("newGold"):
			pd["gold"] = int(d.get("newGold", pd.get("gold", 0)))
		pd["timestamp"] = int(Time.get_unix_time_from_system())
		save_data["playerData"] = pd
	var inv: Variant = d.get("inventoryData", {})
	if inv is Dictionary:
		save_data["inventoryData"] = (inv as Dictionary).duplicate(true)
	var srv_pets: Variant = d.get("petsData", {})
	var used_server_pets: = false
	if srv_pets is Dictionary and not (srv_pets as Dictionary).is_empty():
		save_data["petsData"] = (srv_pets as Dictionary).duplicate(true)
		used_server_pets = true
	var eff: = int(d.get("effectiveSeconds", 0))
	if eff <= 60:
		return
	var pet_offline: Variant = d.get("petOfflineExp", {})
	if pet_offline is Dictionary and not pet_offline.is_empty() and not used_server_pets:
		save_data["pet_offline_exp"] = pet_offline.duplicate(true)

func _on_cloud_save_downloaded(save_data):
	if network and network.has_method("consume_duplicate_resync_skip_download_handler") and network.consume_duplicate_resync_skip_download_handler():
		return
	if save_data == null:
		print("没有云存档")
		cloud_save_downloaded.emit(false, {})
		return

	print("云存档下载成功")

	if network and network.is_logged_in():
		var op_id: = "offline_claim_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
		var er: Dictionary = await wait_economy("economy_offline_claim", func(): network.economy_offline_claim(op_id), op_id)
		if er.get("ok", false):
			var dv: Variant = er.get("data", {})
			if dv is Dictionary and bool(dv.get("success", false)):
				_merge_offline_claim_response_into_save_data(save_data, dv)
				if network:
					network.merge_pending_into_downloaded_save(save_data)
				var download_apply_opts: = {
					"offline_claim_authoritative": true, 
					"pets_authoritative": true, 
				}
				if _realm_transition_duplicate_download_pending:
					download_apply_opts["realm_transition_slice"] = true
					download_apply_opts["skip_deferred_cloud_save"] = true
					download_apply_opts["preserve_local_pets_not_in_cloud"] = true
					download_apply_opts["skip_pet_collection_trim"] = true
					_realm_transition_duplicate_download_pending = false
				apply_cloud_save(save_data, download_apply_opts)
				sync_server_daily_status()
				# 这条路径原来完全不发弹窗信号 —— 从「下载存档」进入游戏时
				# 玩家永远看不到离线奖励，只能等主界面那条路径再领一次，
				# 但那时 offlinePending 已被消费掉、算出 0 秒。两边都补上。
				_emit_post_login_offline_rewards(dv)
				cloud_save_downloaded.emit(true, save_data)
				return
		push_warning("[GameManager] offline_claim 失败，未应用云存档（需联网成功后重试下载）")
		cloud_save_downloaded.emit(false, {})
	else:
		push_warning("[GameManager] 未登录，已取消云存档同步（需联网登录）")
		cloud_save_downloaded.emit(false, {})

func _emit_post_login_offline_rewards(d: Dictionary) -> void :
	"""把 /economy/offline-claim 的回包转成「离线奖励」弹窗信号（一次登录只发一次）。"""
	if _post_login_offline_rewards_emitted:
		return
	var eff: = int(d.get("effectiveSeconds", 0))
	print("[STARTUP] emit_offline_rewards effectiveSeconds=", eff)
	if eff <= 60:
		return
	_post_login_offline_rewards_emitted = true
	var hours_f: = float(eff) / 3600.0
	var exp_v: = int(d.get("exp", 0))
	var gold_v: = int(d.get("gold", 0))
	var pet_gifts: = int(d.get("petGifts", 0))
	var pet_offline: Variant = d.get("petOfflineExp", {})
	var pet_offline_d: Dictionary = pet_offline if pet_offline is Dictionary else {}
	var is_vip: = int(d.get("vipTier", 0)) > 0
	var level_change: = {
		"playerLevelBefore": int(d.get("playerLevelBefore", 0)), 
		"playerLevelAfter": int(d.get("playerLevelAfter", 0)), 
		"petLevelBefore": int(d.get("petLevelBefore", 0)), 
		"petLevelAfter": int(d.get("petLevelAfter", 0)), 
		"petName": str(d.get("petName", "")), 
	}
	post_login_offline_rewards_ready.emit(hours_f, exp_v, gold_v, pet_offline_d, pet_gifts, is_vip, level_change)

func run_post_login_offline_claim_async(source_save: Dictionary) -> void :
	print("[STARTUP] run_offline_claim done=%s running=%s save_empty=%s" % [str(_post_login_offline_claim_done), str(_post_login_offline_claim_running), str(source_save.is_empty())])
	if _post_login_offline_claim_done or _post_login_offline_claim_running:
		# 已经结算过 / 正在结算：这里**必须**把 applied 发出去，不能静默 return。
		# 主界面是先把 HUD 藏起来等这个信号的（_startup_offline_pending），
		# 静默 return 就等于信号永远不来 → 玩家看到的就是「一直黑屏、没有弹窗」。
		# （重登、场景重建、或者上一轮已经结算完再走一遍登录流程，都会命中这条分支。）
		post_login_offline_claim_applied.emit(false)
		return
	if network == null or not network.is_logged_in():
		post_login_offline_claim_applied.emit(false)
		return
	_post_login_offline_claim_running = true
	var suppress_until: = Time.get_ticks_msec() + POST_LOGIN_OFFLINE_UPLOAD_SUPPRESS_MS
	_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, suppress_until)
	var save_data: Dictionary = source_save.duplicate(true) if not source_save.is_empty() else {}
	var claim_ok: = false
	if not save_data.is_empty():
		var op_id: = "offline_claim_%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
		var er: Dictionary = await wait_economy("economy_offline_claim", func(): network.economy_offline_claim(op_id), op_id)
		if er.get("ok", false):
			var dv: Variant = er.get("data", {})
			if dv is Dictionary and bool(dv.get("success", false)):
				var d: Dictionary = (dv as Dictionary).duplicate(true)
				_merge_offline_claim_response_into_save_data(save_data, d)
				if network:
					network.merge_pending_into_downloaded_save(save_data)
				apply_cloud_save(save_data, {"offline_claim_authoritative": true, "pets_authoritative": true})
				claim_ok = true
				_emit_post_login_offline_rewards(d)
		if not claim_ok:
			print("[STARTUP] offline_claim 失败: err=%s data=%s" % [str(er.get("err", "")), str(er.get("data", {}))])
			push_warning("[GameManager] post_login offline_claim 失败（已进入游戏）: %s" % str(er.get("err", "网络或服务异常")))
	else:
		push_warning("[GameManager] post_login offline_claim 跳过：source_save 为空")
	_post_login_offline_claim_running = false
	_post_login_offline_claim_done = true
	if not claim_ok:
		_suppress_general_cloud_upload_until_ms = mini(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec())
	post_login_offline_claim_applied.emit(claim_ok)

func sync_server_daily_status():
	print("[GAME_MANAGER] sync_server_daily_status called")
	print("[GAME_MANAGER] network exists: ", network != null)
	if network:
		print("[GAME_MANAGER] network.is_logged_in(): ", network.is_logged_in())
	if network and network.is_logged_in():
		print("[DAILY] 开始同步服务器每日状态...")

		var responses_received = 0
		var total_requests = 3

		var tower_connected = network.tower_info_loaded.connect( func(server_highest: int, sweep_count: int, server_floor: int):
			print("[DAILY] 收到服务器响应: server_highest=", server_highest, ", sweep_count=", sweep_count)
			print("[DAILY] 同步前本地 tower_sweep_count=", player.tower_sweep_count)
			player.tower_sweep_count = sweep_count
			if server_highest > player.tower_highest:
				player.tower_highest = server_highest
			if server_floor > 0:
				player.tower_floor = server_floor
			elif player.tower_floor <= 0:
				player.tower_floor = max(1, player.tower_highest + 1)
			print("[DAILY] 同步后本地 tower_sweep_count=", player.tower_sweep_count)
			responses_received += 1
			print("[DAILY] responses_received=", responses_received)
			if responses_received >= total_requests:
				daily_status_synced.emit()
		, CONNECT_ONE_SHOT)
		print("[DAILY] tower signal connect result: ", tower_connected)

		var martial_connected = network.martial_info_loaded.connect( func(create_count: int, is_today: bool):
			print("[DAILY] 收到自创次数响应: create_count=", create_count, ", is_today=", is_today)
			if martial_arts_manager:
				if is_today:
					martial_arts_manager.daily_create_count = create_count
				else:
					martial_arts_manager.daily_create_count = 0
				print("[DAILY] 同步后本地 daily_create_count=", martial_arts_manager.daily_create_count)
			responses_received += 1
			print("[DAILY] responses_received=", responses_received)
			if responses_received >= total_requests:
				daily_status_synced.emit()
		, CONNECT_ONE_SHOT)
		print("[DAILY] martial signal connect result: ", martial_connected)

		var martial_fail_connected = network.martial_info_failed.connect( func(_err: String):
			print("[DAILY] 自创次数同步失败: ", _err)
			responses_received += 1
			if responses_received >= total_requests:
				daily_status_synced.emit()
		, CONNECT_ONE_SHOT)
		print("[DAILY] martial_info_failed connect result: ", martial_fail_connected)

		var suit_connected = network.suit_dungeon_info_loaded.connect( func(sweeps_left: int, max_sweeps: int):
			print("[DAILY] 收到套装副本扫荡次数: sweeps_left=", sweeps_left, ", max_sweeps=", max_sweeps)
			player.suit_dungeon_sweeps = sweeps_left
			responses_received += 1
			print("[DAILY] responses_received=", responses_received)
			if responses_received >= total_requests:
				daily_status_synced.emit()
		, CONNECT_ONE_SHOT)
		print("[DAILY] suit_dungeon signal connect result: ", suit_connected)

		network.get_tower_info()
		network.get_martial_info()
		network.get_suit_dungeon_info()
		load_server_broadcasts()
		network.fetch_drop_config()
		if network.has_method("fetch_festival_runtime_config"):
			network.fetch_festival_runtime_config()
		if network.has_method("fetch_gameplay_runtime_config"):
			network.fetch_gameplay_runtime_config()

		if network.has_method("get_noble_info"):
			network.get_noble_info()
		print("[DAILY] API调用完成")
	else:
		print("[DAILY] network未登录或不存在，跳过同步")


func _enforce_server_nickname_matches_player(save_data: Dictionary) -> void :
	if player == null or network == null or not network.is_logged_in():
		return
	var server_name: String = _session_server_nickname.strip_edges()
	if server_name.is_empty():
		server_name = str(network.nickname).strip_edges()
	if server_name.is_empty():
		return
	if player.player_name == server_name:
		return
	push_warning("[GameManager] 角色名与服务器昵称不一致，已纠正: '%s' -> '%s'" % [player.player_name, server_name])
	player.player_name = server_name
	if save_data.has("playerData") and save_data["playerData"] is Dictionary:
		save_data["playerData"]["name"] = server_name
	call_deferred("save_game", true)


func _cloud_player_data_newer_than_local(pd: Dictionary) -> bool:
	var cloud_ts = float(pd.get("timestamp", 0))
	var local_ts = _last_local_save_timestamp
	if cloud_ts > 0 and local_ts > 0:
		return cloud_ts > local_ts
	if local_ts > 0 and cloud_ts <= 0:
		return false
	if cloud_ts > 0 and local_ts <= 0:
		return true
	return true

func _is_legitimate_player_state_transition(local_pd: Dictionary, cloud_pd: Dictionary) -> bool:
	var local_rei: = int(local_pd.get("reincarnation", 0))
	var cloud_rei: = int(cloud_pd.get("reincarnation", 0))
	if cloud_rei > local_rei:
		return true
	var local_realm: = str(local_pd.get("realm", "")).strip_edges()
	var cloud_realm: = str(cloud_pd.get("realm", "")).strip_edges()
	if not cloud_realm.is_empty() and cloud_realm != local_realm:
		return true
	return false


func _should_apply_cloud_player_over_local(pd: Dictionary) -> bool:
	if player == null or pd == null or not pd is Dictionary:
		return false
	if is_player_attr_authority_guard_active():
		return false
	var local_pd: Dictionary = player.to_dict()
	if _is_legitimate_player_state_transition(local_pd, pd):
		return true
	if not _cloud_player_data_newer_than_local(pd):
		return false
	var cloud_level: = int(pd.get("level", 0))
	var local_level: = int(local_pd.get("level", 0))
	var local_rei: = int(local_pd.get("reincarnation", 0))
	var cloud_rei: = int(pd.get("reincarnation", 0))
	var cloud_realm: = str(pd.get("realm", local_pd.get("realm", ""))).strip_edges()
	var local_realm: = str(local_pd.get("realm", "")).strip_edges()
	if cloud_rei == local_rei and cloud_realm == local_realm and cloud_level < local_level:
		return false
	return true

func _prefer_local_martial_arts_over_cloud(local_n: int, cloud_n: int, cloud_pd: Dictionary) -> bool:
	if local_n > cloud_n:
		return true
	if local_n > 0 and not _cloud_player_data_newer_than_local(cloud_pd):
		return true
	return false

func _sync_martial_daily_create_count_from_cloud(local_data: Dictionary, cloud_data: Dictionary) -> Dictionary:
	var out: Dictionary = local_data.duplicate(true)
	if cloud_data.has("daily_create_count"):
		out["daily_create_count"] = cloud_data["daily_create_count"]
	return out


const _CLOUD_EQ_NAMED_SLOTS: Array = ["weapon", "armor", "helmet", "boots", "accessory"]

func _equipment_named_equipped_slot_count(eq: Variant) -> int:
	if eq == null or not eq is Dictionary:
		return 0
	var equipped: Variant = eq.get("equipped", {})
	if equipped == null or not equipped is Dictionary:
		return 0
	var n: = 0
	for slot in _CLOUD_EQ_NAMED_SLOTS:
		var it: Variant = equipped.get(slot)
		if it is Dictionary:
			var nm: = str(it.get("name", "")).strip_edges()
			if not nm.is_empty():
				n += 1
	return n



func apply_granted_pets_from_reward_result(_result: Dictionary) -> void :
	pass



func sync_player_authoritative_cultivation_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("cultivation_pills_used"):
		var cloud_used: = clampi(int(d.get("cultivation_pills_used", 0)), 0, player.MAX_CULTIVATION_PILLS_PER_LIFE)
		player.cultivation_pills_used = maxi(player.cultivation_pills_used, cloud_used)
	if d.has("cultivation"):
		player.cultivation = maxi(player.cultivation, maxi(0, int(d.get("cultivation", 0))))

func _should_skip_combat_stat_cloud_merge() -> bool:
	return is_field_combat_hp_merge_blocked()

func _sum_player_base_invested_from_dict(pd: Dictionary) -> int:
	var total: = 0
	for key in _PLAYER_ATTR_BASE_STAT_KEYS:
		total += maxi(0, int(pd.get(key, 0)) - _PLAYER_ATTR_BASE_STAT_FLOOR)
	return total

func _hp_add_points_from_max_hp_dict(pd: Dictionary, level: int) -> int:
	var lv: = maxi(1, level)
	var floor_hp: = _PLAYER_ATTR_MAX_HP_LEVEL0 + _PLAYER_ATTR_MAX_HP_PER_LEVEL * maxi(0, lv - 1)
	var extra: = maxi(0, int(pd.get("max_hp", 0)) - floor_hp)
	return int(extra / 10)

func _get_points_per_level_for_realm(realm: String) -> int:
	var r: = str(realm).strip_edges()
	if r == "凡人" or r == "散仙":
		return 3
	if r == "地仙" or r == "天仙":
		return 4
	if r == "大罗金仙" or r == "幻灵天神":
		return 5
	return 3

func _compute_player_attr_point_budget(pd: Dictionary) -> int:
	var rei: = maxi(0, int(pd.get("reincarnation", 0)))
	var perm: = GameData.permanent_points_floor(rei)
	var lv: = maxi(1, int(pd.get("level", 1)))
	var ppl: = _get_points_per_level_for_realm(str(pd.get("realm", "凡人")))
	return 20 + perm + maxi(0, lv - 1) * ppl

func _player_attr_total_point_accounting(pd: Dictionary) -> int:
	var lv: = maxi(1, int(pd.get("level", 1)))
	var pool: = int(pd.get("points", 0)) + int(pd.get("pending_auto_points", 0))
	return pool + _sum_player_base_invested_from_dict(pd) + _hp_add_points_from_max_hp_dict(pd, lv)

func _normalize_attr_reset_guard_in_pd(pd: Dictionary) -> Dictionary:
	var out: Dictionary = pd.duplicate(true)
	if not out.has("attr_reset_guard_level"):
		return out
	var guard: = int(out.get("attr_reset_guard_level", 0))
	if guard <= 0:
		out.erase("attr_reset_guard_level")
		return out
	var lv: = maxi(1, int(out.get("level", 1)))
	if lv > guard:
		out.erase("attr_reset_guard_level")
	return out

func _is_player_attr_reset_guard_active(pd: Dictionary) -> bool:
	if not pd.has("attr_reset_guard_level"):
		return false
	var guard: = int(pd.get("attr_reset_guard_level", 0))
	if guard <= 0:
		return false
	var lv: = maxi(1, int(pd.get("level", 1)))
	return lv <= guard

func _apply_allocated_stat_reset_for_level_in_pd(pd: Dictionary) -> Dictionary:
	var out: Dictionary = pd.duplicate(true)
	var lv: = maxi(1, int(out.get("level", 1)))
	var rei: = maxi(0, int(out.get("reincarnation", 0)))
	var perm: = GameData.permanent_points_floor(rei)
	out["permanent_points"] = perm
	for key in _PLAYER_ATTR_BASE_STAT_KEYS:
		out[key] = _PLAYER_ATTR_BASE_STAT_FLOOR
	var floor_hp: = _PLAYER_ATTR_MAX_HP_LEVEL0 + _PLAYER_ATTR_MAX_HP_PER_LEVEL * maxi(0, lv - 1)
	out["max_hp"] = floor_hp
	out["hp"] = floor_hp
	out["pending_auto_points"] = 0
	var budget: = _compute_player_attr_point_budget(out)
	out["points"] = budget
	if bool(out.get("auto_allocation_enabled", false)) and int(out.get("points", 0)) > 0:
		out["pending_auto_points"] = int(out.get("points", 0))
		out["points"] = 0
	return out

func _repair_player_attr_if_overspent(pd: Dictionary) -> Dictionary:
	var out: Dictionary = _normalize_attr_reset_guard_in_pd(pd)
	if not _is_player_attr_reset_guard_active(out):
		return out
	var budget: = _compute_player_attr_point_budget(out)
	var total: = _player_attr_total_point_accounting(out)
	if total <= budget + _PLAYER_ATTR_POINT_POOL_SLACK:
		return out
	print("[GameManager] 属性点保护窗口内总账超标，强制清零已分配五维 level=%s budget=%s total=%s" % [
		str(out.get("level", 1)), str(budget), str(total)
	])
	return _apply_allocated_stat_reset_for_level_in_pd(out)

func _clear_deferred_attr_authoritative_save() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("clear_deferred_attr_authoritative_save"):
		main_ui.clear_deferred_attr_authoritative_save()

func preserve_local_player_attr_over_stale_cloud(local_pd: Dictionary, cloud_pd: Dictionary) -> Dictionary:
	if local_pd.is_empty() or cloud_pd.is_empty():
		return cloud_pd.duplicate(true)
	var out: Dictionary = cloud_pd.duplicate(true)
	var local_level: = int(local_pd.get("level", 1))
	var cloud_level: = int(cloud_pd.get("level", 1))
	var local_rei: = int(local_pd.get("reincarnation", 0))
	var cloud_rei: = int(cloud_pd.get("reincarnation", 0))
	var local_realm: = str(local_pd.get("realm", "")).strip_edges()
	var cloud_realm: = str(cloud_pd.get("realm", "")).strip_edges()
	if local_rei != cloud_rei or local_level != cloud_level:
		return _repair_player_attr_if_overspent(out)
	if local_realm != cloud_realm:
		out["permanent_points"] = GameData.permanent_points_floor(maxi(0, cloud_rei))
		var guard: = maxi(int(local_pd.get("attr_reset_guard_level", 0)), int(cloud_pd.get("attr_reset_guard_level", 0)))
		if guard > 0:
			out["attr_reset_guard_level"] = guard
		return _repair_player_attr_if_overspent(out)

	var sum_local: = _sum_player_base_invested_from_dict(local_pd)
	var sum_cloud: = _sum_player_base_invested_from_dict(cloud_pd)
	var pool_local: = int(local_pd.get("points", 0)) + int(local_pd.get("pending_auto_points", 0))
	var pool_cloud: = int(cloud_pd.get("points", 0)) + int(cloud_pd.get("pending_auto_points", 0))
	var prefer_local: = false
	if sum_local > sum_cloud:
		prefer_local = true
	elif sum_local < sum_cloud:
		prefer_local = false
	elif pool_local < pool_cloud:
		prefer_local = true
	else:
		prefer_local = false
	var src: Dictionary = local_pd if prefer_local else cloud_pd
	for key in _PLAYER_ATTR_BASE_STAT_KEYS:
		out[key] = int(src.get(key, _PLAYER_ATTR_BASE_STAT_FLOOR))
	out["points"] = maxi(0, int(src.get("points", 0)))
	out["pending_auto_points"] = maxi(0, int(src.get("pending_auto_points", 0)))

	out["max_hp"] = maxi(int(cloud_pd.get("max_hp", 0)), int(local_pd.get("max_hp", 0)))
	out["permanent_points"] = GameData.permanent_points_floor(maxi(0, cloud_rei))
	var guard_same: = maxi(int(local_pd.get("attr_reset_guard_level", 0)), int(cloud_pd.get("attr_reset_guard_level", 0)))
	if guard_same > 0:
		out["attr_reset_guard_level"] = guard_same
	return _repair_player_attr_if_overspent(out)

func _merge_monotonic_permanent_points_into_cloud_pd(_local_pd: Dictionary, cloud_pd: Dictionary) -> Dictionary:
	if cloud_pd.is_empty():
		return cloud_pd
	var out: Dictionary = cloud_pd.duplicate(true)
	var cloud_rei: = int(cloud_pd.get("reincarnation", 0))
	out["permanent_points"] = GameData.permanent_points_floor(maxi(0, cloud_rei))
	return out

func _player_data_slice_skip_full_merge(opts: Dictionary) -> bool:
	if bool(opts.get("skip_player_data_merge", false)):
		return true
	for key in ["economy_cultivation_pill_slice", "reward_inventory_slice", "realm_transition_slice", 
			"attr_authoritative_slice", "double_exp_slice", "cosmetic_slice", "lottery_pity_slice", "upgrade_dan_slice"]:
		if bool(opts.get(key, false)):
			return true
	return false

func _apply_player_data_slices_from_opts(pd: Dictionary, opts: Dictionary, local_pd: Dictionary) -> void :
	if player == null or pd.is_empty():
		return
	var d: Dictionary = _merge_monotonic_permanent_points_into_cloud_pd(local_pd, pd)
	player.merge_xianmo_titles_from_cloud_player_dict(d)
	if bool(opts.get("realm_transition_slice", false)):
		sync_player_authoritative_realm_transition_from_dict(d)
	if bool(opts.get("attr_authoritative_slice", false)):
		sync_player_authoritative_attr_slice_from_dict(d, bool(opts.get("force_base_stats", true)))
	if bool(opts.get("upgrade_dan_slice", false)):
		sync_player_authoritative_upgrade_dan_slice_from_dict(d)
	if bool(opts.get("double_exp_slice", false)):
		sync_player_authoritative_vip_double_exp_from_dict(d)
	if bool(opts.get("cosmetic_slice", false)):
		sync_player_authoritative_cosmetic_from_dict(d)
	if bool(opts.get("lottery_pity_slice", false)):
		sync_player_authoritative_lottery_pity_from_dict(d)
	if bool(opts.get("economy_cultivation_pill_slice", false)):
		sync_player_authoritative_cultivation_from_dict(d)
	if bool(opts.get("reward_inventory_slice", false)) or bool(opts.get("currency_slice", false)):
		sync_player_authoritative_currency_from_dict(d)

func mark_player_attr_authority_applied() -> void :
	_player_attr_authority_guard_until_ms = Time.get_ticks_msec() + _PLAYER_ATTR_AUTHORITY_GUARD_MS

func is_player_attr_authority_guard_active() -> bool:
	return Time.get_ticks_msec() < _player_attr_authority_guard_until_ms

func persist_player_attr_authoritative_after_rpc(save_rev: int) -> void :
	mark_battle_progress_dirty("attr_allocate")
	if save_rev >= 0:
		_set_cloud_save_revision(save_rev)
	save_game(false)

func _is_full_player_data_dict(pd: Dictionary) -> bool:
	if pd.is_empty():
		return false
	if not pd.has("name") or str(pd.get("name", "")).is_empty():
		return false
	return int(pd.get("level", 0)) >= 1


func apply_player_attr_authoritative_from_rpc(save_data: Dictionary, pd: Dictionary, save_rev: int, battle_light: bool) -> void :
	if player == null or pd.is_empty():
		return
	sync_player_authoritative_attr_slice_from_dict(pd, true)
	mark_player_attr_authority_applied()
	persist_player_attr_authoritative_after_rpc(save_rev)
	if battle_light:
		return
	if not _is_full_player_data_dict(pd):
		return
	var attr_opts: = {
		"attr_authoritative_slice": true, 
		"force_base_stats": true, 
		"skip_deferred_cloud_save": true, 
	}
	var sd: Dictionary = save_data.duplicate(true) if not save_data.is_empty() else {"playerData": pd}
	if save_rev >= 0:
		sd["saveRevision"] = save_rev
	apply_cloud_save(sd, attr_opts)


func apply_field_battle_loot_player_slice(pd: Dictionary, force_absolute: bool = false) -> void :
	if player == null or pd == null or pd.is_empty():
		return
	var old_level: int = int(player.level)
	var d: Dictionary = pd.duplicate(true)
	if force_absolute:
		sync_player_authoritative_upgrade_dan_slice_from_dict(d, true)
		_apply_battle_loot_attr_slice_if_present(d)
		_schedule_player_attr_auto_allocate_after_battle_loot()
		_emit_player_level_up_if_raised(old_level)
		return
	var incoming_level: int = clampi(int(d.get("level", old_level)), 1, GameData.MAX_LEVEL_EVOLUTION)
	var auth_exp: = maxi(0, int(d.get("experience", d.get("exp", player.experience))))
	if incoming_level < old_level:
		incoming_level = old_level
		auth_exp = maxi(player.experience, auth_exp)
	elif incoming_level == old_level:
		auth_exp = maxi(player.experience, auth_exp)
	else:
		auth_exp = _cap_field_progress_exp(incoming_level, auth_exp)
	d["level"] = incoming_level
	d["experience"] = auth_exp
	sync_player_authoritative_upgrade_dan_slice_from_dict(d, false)
	_apply_battle_loot_attr_slice_if_present(d)
	_schedule_player_attr_auto_allocate_after_battle_loot()
	_emit_player_level_up_if_raised(old_level)

func _emit_player_level_up_if_raised(old_level: int) -> void :
	if player == null:
		return
	if int(player.level) > old_level:
		player.level_up.emit(player.level)

func _apply_battle_loot_attr_slice_if_present(player_pd: Dictionary) -> void :
	if player == null or player_pd.is_empty():
		return
	var has_base: = false
	for key in _PLAYER_ATTR_BASE_STAT_KEYS:
		if player_pd.has(key):
			has_base = true
			break
	if not has_base:
		return

	if not player_pd.has("points") and not player_pd.has("pending_auto_points"):
		return
	var merged: Dictionary = {}
	for key in _PLAYER_ATTR_BASE_STAT_KEYS:
		if player_pd.has(key):
			merged[key] = maxi(0, int(player_pd.get(key, 0)))
	if player_pd.has("points"):
		merged["points"] = maxi(0, int(player_pd.get("points", 0)))
	if player_pd.has("pending_auto_points"):
		merged["pending_auto_points"] = maxi(0, int(player_pd.get("pending_auto_points", 0)))

	if player_pd.has("max_hp"):
		merged["max_hp"] = maxi(1, int(player_pd.get("max_hp", 0)))
	if player_pd.has("hp"):
		merged["hp"] = maxi(0, int(player_pd.get("hp", 0)))
	sync_player_authoritative_attr_slice_from_dict(merged, true)

func _schedule_player_attr_auto_allocate_after_battle_loot() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_schedule_player_attr_auto_allocate_check"):
		main_ui.call_deferred("_schedule_player_attr_auto_allocate_check", "battle_loot")

func sync_player_authoritative_upgrade_dan_slice_from_dict(pd: Variant, force_absolute_exp: bool = false) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	var prev_level: int = player.level
	var prev_exp: int = player.experience
	var incoming_level: int = prev_level
	if d.has("level"):
		incoming_level = clampi(int(d.get("level", 1)), 1, GameData.MAX_LEVEL_EVOLUTION)
	player.level = incoming_level
	if d.has("experience") or d.has("exp"):
		var auth_exp: = maxi(0, int(d.get("experience", d.get("exp", 0))))
		if force_absolute_exp:
			player.experience = auth_exp
		elif incoming_level == prev_level:
			player.experience = maxi(prev_exp, auth_exp)
		else:
			player.experience = auth_exp
	if d.has("points"):
		var incoming_pts: = maxi(0, int(d.get("points", 0)))
		if is_player_attr_authority_guard_active():
			player.points = mini(player.points, incoming_pts)
		else:
			player.points = incoming_pts
	if d.has("pending_auto_points"):
		var incoming_pend: = maxi(0, int(d.get("pending_auto_points", 0)))
		if is_player_attr_authority_guard_active():
			player.pending_auto_points = mini(player.pending_auto_points, incoming_pend)
		else:
			player.pending_auto_points = incoming_pend
	if d.has("auto_allocation_enabled"):
		player.auto_allocation_enabled = bool(d.get("auto_allocation_enabled", false))
	if not _should_skip_combat_stat_cloud_merge():
		if d.has("max_hp"):
			player.max_hp = maxi(1, int(d.get("max_hp", player.max_hp)))
		if d.has("hp"):
			player.hp = clampi(int(d.get("hp", player.hp)), 0, player.get_max_hp())
	elif incoming_level > prev_level:

		var level_delta: = incoming_level - prev_level
		var old_cap: int = player.get_max_hp()
		player.max_hp += level_delta * _PLAYER_ATTR_MAX_HP_PER_LEVEL
		var new_cap: int = player.get_max_hp()
		player.hp = clampi(player.hp + (new_cap - old_cap), 0, new_cap)
	if d.has("cultivation"):
		player.cultivation = maxi(0, int(d.get("cultivation", 0)))
	# 五维基础值必须跟着一起同步。服务端 `_apply_player_upgrade_dan()` 是按等级
	# 给点数并立刻 auto_allocate 到五维的，如果这里只回 level/points/pending，
	# 客户端五维还是加之前的值：界面看不出成长，而且客户端下一次整包上传
	# 会把服务端刚加好的五维冲回旧值 —— 玩家看到的就是「升级丹吃了没属性点」。
	# （2026-10-29 玩家实测：1200 级五维全 10、可用属性点 0）
	if d.has("vitality"):
		player.vitality = maxi(0, int(d.get("vitality", player.vitality)))
	if d.has("magic"):
		player.magic = maxi(0, int(d.get("magic", player.magic)))
	if d.has("attack_base"):
		player.attack_base = maxi(0, int(d.get("attack_base", player.attack_base)))
	if d.has("defense_base"):
		player.defense_base = maxi(0, int(d.get("defense_base", player.defense_base)))
	if d.has("agility_base"):
		player.agility_base = maxi(0, int(d.get("agility_base", player.agility_base)))
	player.update_derived_stats()
	player.exp_changed.emit(player.experience, GameData.get_required_exp(player.level))
	player_attr_display_changed.emit()
	if force_absolute_exp:
		_clamp_field_player_level_after_exp()


func sync_player_authoritative_attr_slice_from_dict(pd: Variant, force_base_stats: bool = false) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("points"):
		player.points = maxi(0, int(d.get("points", 0)))
	if d.has("pending_auto_points"):
		player.pending_auto_points = maxi(0, int(d.get("pending_auto_points", 0)))
	if d.has("auto_allocation_enabled"):
		player.auto_allocation_enabled = bool(d.get("auto_allocation_enabled", false))
	if d.has("auto_allocation_plan") and d.get("auto_allocation_plan") is Dictionary:
		var plan: Dictionary = d.get("auto_allocation_plan")
		for key in ["vitality", "attack", "defense", "magic", "agility"]:
			if plan.has(key):
				player.auto_allocation_plan[key] = maxi(0, int(plan.get(key, 0)))
	if d.has("permanent_points"):
		player.permanent_points = maxi(0, int(d.get("permanent_points", 0)))
	player.repair_permanent_points_from_reincarnation()
	if d.has("talent_attack") or d.has("talent_defense") or d.has("talent_agility") or d.has("talent_hp"):
		if d.has("talent_attack"):
			player.talent_attack = clampi(int(d.get("talent_attack", 0)), 0, GameData.TALENT_MAX_PER_STAT)
		if d.has("talent_defense"):
			player.talent_defense = clampi(int(d.get("talent_defense", 0)), 0, GameData.TALENT_MAX_PER_STAT)
		if d.has("talent_agility"):
			player.talent_agility = clampi(int(d.get("talent_agility", 0)), 0, GameData.TALENT_MAX_PER_STAT)
		if d.has("talent_hp"):
			player.talent_hp = clampi(int(d.get("talent_hp", 0)), 0, GameData.TALENT_MAX_PER_STAT)
		player.clamp_talent_allocation_to_earned()
	if d.has("yuanbao_currency") or d.has("yuanbao"):
		player.yuanbao_currency = maxi(0, int(d.get("yuanbao_currency", d.get("yuanbao", player.yuanbao_currency))))
	if force_base_stats:
		player.vitality = maxi(0, int(d.get("vitality", player.vitality)))
		player.magic = maxi(0, int(d.get("magic", player.magic)))
		player.attack_base = maxi(0, int(d.get("attack_base", player.attack_base)))
		player.defense_base = maxi(0, int(d.get("defense_base", player.defense_base)))
		player.agility_base = maxi(0, int(d.get("agility_base", player.agility_base)))

		if not _should_skip_combat_stat_cloud_merge():
			if d.has("max_hp"):
				player.max_hp = maxi(1, int(d.get("max_hp", player.max_hp)))
			if d.has("hp"):
				player.hp = clampi(int(d.get("hp", player.hp)), 0, player.get_max_hp())
		player.update_derived_stats()
		player_attr_display_changed.emit()
		return
	var apply_base_stats: = not _should_skip_combat_stat_cloud_merge()
	if apply_base_stats:
		if d.has("vitality"):
			player.vitality = maxi(0, int(d.get("vitality", 0)))
		if d.has("magic"):
			player.magic = maxi(0, int(d.get("magic", 0)))
		if d.has("attack_base"):
			player.attack_base = maxi(0, int(d.get("attack_base", 0)))
		if d.has("defense_base"):
			player.defense_base = maxi(0, int(d.get("defense_base", 0)))
		if d.has("agility_base"):
			player.agility_base = maxi(0, int(d.get("agility_base", 0)))
		if d.has("max_hp"):
			player.max_hp = maxi(1, int(d.get("max_hp", player.max_hp)))
		if d.has("hp"):
			player.hp = clampi(int(d.get("hp", player.hp)), 0, player.get_max_hp())
		player.update_derived_stats()
	player_attr_display_changed.emit()

func sync_player_authoritative_reward_gold_from_dict(pd: Variant) -> void :
	sync_player_authoritative_currency_from_dict(pd)

func sync_player_authoritative_currency_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("gold"):
		player.gold = maxi(player.gold, maxi(0, int(d.get("gold", 0))))
		gold_changed.emit(player.gold)
	if d.has("yuanbao_currency"):
		player.yuanbao_currency = maxi(player.yuanbao_currency, maxi(0, int(d.get("yuanbao_currency", 0))))
		yuanbao_changed.emit(player.yuanbao_currency)
	if d.has("friendship_points"):
		player.friendship_points = maxi(player.friendship_points, maxi(0, int(d.get("friendship_points", 0))))

func sync_player_authoritative_lottery_pity_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("lottery_yuanbao_pity_count"):
		player.set_meta("lottery_yuanbao_pity_count", maxi(0, int(d.get("lottery_yuanbao_pity_count", 0))))

func sync_player_authoritative_realm_transition_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("realm"):
		player.realm = str(d.get("realm", player.realm))
	if d.has("level"):
		player.level = clampi(int(d.get("level", 1)), 1, GameData.MAX_LEVEL_EVOLUTION)

	player.experience = 0
	if d.has("reincarnation"):
		player.reincarnation = maxi(0, int(d.get("reincarnation", 0)))
	if d.has("cultivation_pills_used"):
		player.cultivation_pills_used = clampi(int(d.get("cultivation_pills_used", 0)), 0, player.MAX_CULTIVATION_PILLS_PER_LIFE)
	if d.has("permanent_points"):
		player.permanent_points = maxi(0, int(d.get("permanent_points", 0)))
	if d.has("points"):
		player.points = maxi(0, int(d.get("points", 0)))
	if d.has("pending_auto_points"):
		player.pending_auto_points = maxi(0, int(d.get("pending_auto_points", 0)))
	if d.has("auto_allocation_enabled"):
		player.auto_allocation_enabled = bool(d.get("auto_allocation_enabled", false))
	if d.has("vitality"):
		player.vitality = maxi(0, int(d.get("vitality", 0)))
	if d.has("magic"):
		player.magic = maxi(0, int(d.get("magic", 0)))
	if d.has("attack_base"):
		player.attack_base = maxi(0, int(d.get("attack_base", 0)))
	if d.has("defense_base"):
		player.defense_base = maxi(0, int(d.get("defense_base", 0)))
	if d.has("agility_base"):
		player.agility_base = maxi(0, int(d.get("agility_base", 0)))
	if d.has("attr_reset_guard_level"):
		player.attr_reset_guard_level = maxi(0, int(d.get("attr_reset_guard_level", 0)))
	elif player.attr_reset_guard_level <= 0:
		player.attr_reset_guard_level = 1 + _PLAYER_ATTR_RESET_GUARD_SPAN
	if player.attr_reset_guard_level > 0 and player.level > player.attr_reset_guard_level:
		player.attr_reset_guard_level = 0
	if d.has("max_hp"):
		player.max_hp = maxi(1, int(d.get("max_hp", player.max_hp)))
	if d.has("hp"):
		player.hp = clampi(int(d.get("hp", player.hp)), 0, player.get_max_hp())
	if d.has("max_mp"):
		player.max_mp = maxi(1, int(d.get("max_mp", player.max_mp)))
	if d.has("mp"):
		player.mp = clampi(int(d.get("mp", player.mp)), 0, player.max_mp)
	player.repair_permanent_points_from_reincarnation()
	player.clamp_talent_allocation_to_earned()
	player.update_derived_stats()
	player.realm_changed.emit(player.realm)
	player.exp_changed.emit(player.experience, GameData.get_required_exp(player.level))

func sync_player_authoritative_vip_double_exp_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("double_exp_until"):
		player.double_exp_until = maxi(player.double_exp_until, int(d.get("double_exp_until", 0)))
	if d.has("double_exp_channels") and d.get("double_exp_channels") is Dictionary:
		var incoming_channels: Dictionary = d.get("double_exp_channels")
		if player.double_exp_channels.is_empty():
			player.double_exp_channels = incoming_channels.duplicate(true)
		else:
			for key in incoming_channels.keys():
				var key_name: = str(key)
				var prev: = int(player.double_exp_channels.get(key_name, 0))
				player.double_exp_channels[key_name] = maxi(prev, int(incoming_channels[key]))
	if d.has("double_exp_auto_realm_enabled"):
		player.double_exp_auto_realm_enabled = bool(d.get("double_exp_auto_realm_enabled", false))

func sync_player_authoritative_cosmetic_from_dict(pd: Variant) -> void :
	if player == null or pd == null or not pd is Dictionary:
		return
	var d: Dictionary = pd as Dictionary
	if d.has("player_character_id"):
		var cid: = int(d.get("player_character_id", 0))
		player.player_character_id = clampi(cid, 0, 6)

func build_authority_reward_apply_opts(reward_result: Dictionary, base_opts: Dictionary = {}) -> Dictionary:
	var opts: Dictionary = base_opts.duplicate(true)
	opts["clamp_inventory_local_consumption"] = true
	opts["reward_inventory_slice"] = true
	var granted_names: Array = []
	if reward_result is Dictionary:
		var granted_items: Variant = reward_result.get("grantedItems", [])
		if granted_items is Array:
			for granted_item in granted_items:
				if granted_item is Dictionary:
					var gn: = str(granted_item.get("name", "")).strip_edges()
					if not gn.is_empty() and not granted_names.has(gn):
						granted_names.append(gn)
	opts["granted_item_names"] = granted_names
	return opts

func _count_inventory_items_by_name(inv: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if inv == null or not inv is Dictionary:
		return out
	for list_key in ["items", "warehouse_items"]:
		var list: Variant = inv.get(list_key, [])
		if list is Array:
			for it in list:
				if it is Dictionary:
					var n: = str(it.get("name", "")).strip_edges()
					if n.is_empty():
						continue
					out[n] = int(out.get(n, 0)) + maxi(0, int(it.get("count", 1)))
	return out

func _reduce_named_item_count_in_list(list: Array, item_name: String, need_reduce: int) -> int:
	if need_reduce <= 0:
		return 0
	var remain: = need_reduce
	for i in range(list.size() - 1, -1, -1):
		if remain <= 0:
			break
		var it: Variant = list[i]
		if not it is Dictionary:
			continue
		if str(it.get("name", "")).strip_edges() != item_name:
			continue
		var cnt: = maxi(0, int(it.get("count", 1)))
		if cnt <= 0:
			continue
		var cut: = mini(cnt, remain)
		var next: = cnt - cut
		if next > 0:
			(it as Dictionary)["count"] = next
		else:
			list.remove_at(i)
		remain -= cut
	return remain

func _reduce_inventory_named_count_in_lists(items: Array, warehouse: Array, item_name: String, need_reduce: int) -> int:
	var remain: = need_reduce
	remain = _reduce_named_item_count_in_list(items, item_name, remain)
	if remain > 0:
		remain = _reduce_named_item_count_in_list(warehouse, item_name, remain)
	return remain

func _clamp_cloud_inventory_local_consumption(cloud_inv: Dictionary, local_inv: Dictionary, granted_names: Array) -> Dictionary:
	if cloud_inv == null or not cloud_inv is Dictionary:
		return {} if cloud_inv == null else (cloud_inv as Dictionary).duplicate(true)
	var out: Dictionary = cloud_inv.duplicate(true)
	var granted_set: Dictionary = {}
	for gn in granted_names:
		var gs: = str(gn).strip_edges()
		if not gs.is_empty():
			granted_set[gs] = true
	var local_counts: Dictionary = _count_inventory_items_by_name(local_inv)
	var cloud_counts: Dictionary = _count_inventory_items_by_name(out)
	var items: Array = out.get("items", []) if out.get("items") is Array else []
	var warehouse: Array = out.get("warehouse_items", []) if out.get("warehouse_items") is Array else []
	out["items"] = items
	out["warehouse_items"] = warehouse
	for name in cloud_counts.keys():
		if granted_set.has(name):
			continue
		var lc: int = int(local_counts.get(name, 0))
		var cc: int = int(cloud_counts.get(name, 0))
		if cc > lc:
			var reduce_by: int = cc - lc
			var remain: int = _reduce_inventory_named_count_in_lists(items, warehouse, name, reduce_by)
			if remain > 0:
				push_warning("[GameManager] clamp inventory consumption incomplete name=%s remain=%d" % [name, remain])
	return out















func _merge_pet_collection_take_max(local_pc: Dictionary, cloud_pc: Dictionary) -> Dictionary:
	var merged: Dictionary = cloud_pc.duplicate(true) if cloud_pc is Dictionary else {}
	if not merged.has("progress") or not (merged.get("progress") is Dictionary):
		merged["progress"] = {}
	var local_progress: Dictionary = {}
	if local_pc is Dictionary and local_pc.get("progress") is Dictionary:
		local_progress = local_pc.get("progress", {})
	var cloud_progress: Dictionary = merged.get("progress", {})
	var all_ids: = {}
	for k in local_progress.keys():
		all_ids[str(k)] = true
	for k in cloud_progress.keys():
		all_ids[str(k)] = true
	var next_progress: Dictionary = {}
	for species_id in all_ids.keys():
		var local_count: = int(local_progress.get(species_id, 0))
		var cloud_count: = int(cloud_progress.get(species_id, 0))
		next_progress[species_id] = maxi(local_count, cloud_count)
	merged["progress"] = next_progress
	if not merged.has("mutation_progress") or not (merged.get("mutation_progress") is Dictionary):
		merged["mutation_progress"] = {}
	var local_mut: Dictionary = {}
	if local_pc is Dictionary and local_pc.get("mutation_progress") is Dictionary:
		local_mut = local_pc.get("mutation_progress", {})
	var cloud_mut: Dictionary = merged.get("mutation_progress", {})
	var mut_ids: = {}
	for k in local_mut.keys():
		mut_ids[str(k)] = true
	for k in cloud_mut.keys():
		mut_ids[str(k)] = true
	var next_mut: Dictionary = {}
	for species_id in mut_ids.keys():
		var lc: = int(local_mut.get(species_id, 0))
		var cc: = int(cloud_mut.get(species_id, 0))
		var m: = maxi(lc, cc)
		if m > 0:
			next_mut[species_id] = mini(m, 20)
	merged["mutation_progress"] = next_mut
	return merged


func _build_pet_locked_index_from_roster_dict(pet_data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if pet_data == null or not pet_data is Dictionary:
		return out
	for roster_key in ["pets", "pet_bag", "assist_pets"]:
		var roster: Variant = pet_data.get(roster_key, [])
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				out[str(p.id)] = bool(p.get("locked", false))
	return out

const _PET_PROGRESS_UPLOAD_GUARD_FIELDS: Array = [
	"level", "experience", "exp", "growth_rates", "total_growth", 
	"attack", "defense", "agility", "max_hp", "hp", "base_stats", "stat_ratio", 
	"lineage_seed_growth", "initial_total_growth", "medal_counts", 
]

const _PET_EVOLUTION_FORM_LABELS: Array = ["幼年", "一进", "二进", "终极"]

func _resolve_authoritative_evolution_stage_from_dict(pet_dict: Dictionary) -> int:
	if pet_dict == null or not pet_dict is Dictionary:
		return 0
	var raw_stage: = int(pet_dict.get("evolution_stage", 0))
	var pet_id: = str(pet_dict.get("pet_id", "")).strip_edges()
	var is_mutant: = bool(pet_dict.get("is_mutant", false))
	var origin: = str(pet_dict.get("evolution_origin", "")).strip_edges()
	if origin.is_empty() and not pet_id.is_empty():
		origin = EvolutionDataClass.get_evolution_origin(pet_id)
	var chain: Array = []
	if not origin.is_empty():
		chain = EvolutionDataClass.get_evolution_chain_by_origin(origin, is_mutant)
	var candidates: Array[int] = []
	if raw_stage >= 0:
		candidates.append(raw_stage)
	if not chain.is_empty() and not pet_id.is_empty():
		var pid_stage: = EvolutionDataClass.get_evolution_stage(pet_id, chain)
		if pid_stage >= 0:
			candidates.append(pid_stage)
	var form_str: = str(pet_dict.get("form", "")).strip_edges()
	var form_idx: = _PET_EVOLUTION_FORM_LABELS.find(form_str)
	if form_idx >= 0:
		candidates.append(form_idx)
	if candidates.is_empty():
		return maxi(0, raw_stage)
	var resolved: = 0
	for c in candidates:
		resolved = maxi(resolved, int(c))
	if chain.is_empty():
		return maxi(0, raw_stage)
	return clampi(resolved, 0, chain.size() - 1)

func _is_same_pet_lifecycle_for_upload_guard(local_pet: Dictionary, cloud_pet: Dictionary) -> bool:
	var local_gen: = maxi(0, int(local_pet.get("generation", 0)))
	var cloud_gen: = maxi(0, int(cloud_pet.get("generation", 0)))
	var local_stage: = _resolve_authoritative_evolution_stage_from_dict(local_pet)
	var cloud_stage: = _resolve_authoritative_evolution_stage_from_dict(cloud_pet)
	var local_rei: = maxi(0, int(local_pet.get("reincarnation_count", 0)))
	var cloud_rei: = maxi(0, int(cloud_pet.get("reincarnation_count", 0)))
	return local_gen == cloud_gen and local_stage == cloud_stage and local_rei == cloud_rei

func _cloud_pet_lifecycle_ahead_of_local(local_pet: Dictionary, cloud_pet: Dictionary) -> bool:
	var local_gen: = maxi(0, int(local_pet.get("generation", 0)))
	var cloud_gen: = maxi(0, int(cloud_pet.get("generation", 0)))
	if cloud_gen > local_gen:
		return true
	var local_stage: = _resolve_authoritative_evolution_stage_from_dict(local_pet)
	var cloud_stage: = _resolve_authoritative_evolution_stage_from_dict(cloud_pet)
	return cloud_stage > local_stage

func _local_pet_lifecycle_ahead_of_cloud(local_pet: Dictionary, cloud_pet: Dictionary) -> bool:
	var local_gen: = maxi(0, int(local_pet.get("generation", 0)))
	var cloud_gen: = maxi(0, int(cloud_pet.get("generation", 0)))
	if local_gen > cloud_gen:
		return true
	var local_stage: = _resolve_authoritative_evolution_stage_from_dict(local_pet)
	var cloud_stage: = _resolve_authoritative_evolution_stage_from_dict(cloud_pet)
	return local_stage > cloud_stage

func _copy_pet_progress_guard_fields_to_dict(target: Dictionary, source: Dictionary) -> void :
	if target == null or not target is Dictionary or source == null or not source is Dictionary:
		return
	for field in _PET_PROGRESS_UPLOAD_GUARD_FIELDS:
		if source.has(field):
			target[field] = source[field]

func _build_pet_progress_index_from_roster_dict(pet_data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if pet_data == null or not pet_data is Dictionary:
		return out
	for roster_key in ["pets", "pet_bag", "assist_pets"]:
		var roster: Variant = pet_data.get(roster_key, [])
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				out[str(p.id)] = p
	return out

func _pet_progress_level_for_merge_guard(pet_dict: Dictionary) -> int:
	return maxi(1, int(pet_dict.get("level", 1)))

func _pet_progress_growth_for_merge_guard(pet_dict: Dictionary) -> float:
	return float(pet_dict.get("total_growth", pet_dict.get("growth", 0.0)))

const _PET_MERGE_SNAPSHOT_EPS: = 0.02

func _pet_exp_for_merge_guard(pet_dict: Dictionary) -> int:
	return maxi(0, int(pet_dict.get("experience", pet_dict.get("exp", 0))))

func _pet_lineage_for_merge_guard(pet_dict: Dictionary) -> float:
	if pet_dict.has("lineage_seed_growth"):
		return float(pet_dict.get("lineage_seed_growth", 3.0))
	if pet_dict.has("initial_total_growth"):
		return float(pet_dict.get("initial_total_growth", 3.0))
	return 3.0

func _pet_snapshot_self_consistent(pet_dict: Dictionary) -> bool:
	if pet_dict == null or not pet_dict is Dictionary:
		return false
	var lv: = int(pet_dict.get("level", 0))
	if lv < 1:
		return false
	var total: = _pet_progress_growth_for_merge_guard(pet_dict)
	if total <= 0.0:
		return false
	var gr: Variant = pet_dict.get("growth_rates", null)
	if gr is Dictionary:
		var grd: Dictionary = gr
		var sum: = float(grd.get("attack", 0)) + float(grd.get("defense", 0)) + float(grd.get("agility", 0))
		if sum > 0.001 and absf(sum - total) > _PET_MERGE_SNAPSHOT_EPS:
			return false
	if lv > 1:
		var lineage: = _pet_lineage_for_merge_guard(pet_dict)
		if total + _PET_MERGE_SNAPSHOT_EPS < lineage:
			return false
	return true

func _pet_progress_score(pet_dict: Dictionary) -> int:
	var lv: = _pet_progress_level_for_merge_guard(pet_dict)
	var total: = _pet_progress_growth_for_merge_guard(pet_dict)
	var exp: = _pet_exp_for_merge_guard(pet_dict)
	return lv * 1000000 + int(total * 1000.0) + exp

func _pet_merge_picked_from_local(local_pet: Dictionary, incoming_pet: Dictionary) -> bool:
	var local_ok: = _pet_snapshot_self_consistent(local_pet)
	var incoming_ok: = _pet_snapshot_self_consistent(incoming_pet)
	if local_ok and not incoming_ok:
		return true
	if incoming_ok and not local_ok:
		return false
	return _pet_progress_score(local_pet) >= _pet_progress_score(incoming_pet)

func _pick_higher_pet_progress_dict(a: Dictionary, b: Dictionary) -> Dictionary:
	if a == null or not a is Dictionary:
		return b.duplicate(true) if b is Dictionary else {}
	if b == null or not b is Dictionary:
		return a.duplicate(true)
	var a_ok: = _pet_snapshot_self_consistent(a)
	var b_ok: = _pet_snapshot_self_consistent(b)
	if not a_ok and not b_ok:
		var pid: = str(a.get("id", b.get("id", "")))
		push_warning("[GameManager] pet merge both snapshots inconsistent id=%s, level-first fallback" % pid)
		var a_lv: = _pet_progress_level_for_merge_guard(a)
		var b_lv: = _pet_progress_level_for_merge_guard(b)
		if a_lv != b_lv:
			return a.duplicate(true) if a_lv > b_lv else b.duplicate(true)
		var a_g: = _pet_progress_growth_for_merge_guard(a)
		var b_g: = _pet_progress_growth_for_merge_guard(b)
		return a.duplicate(true) if a_g + 0.001 >= b_g else b.duplicate(true)
	if not a_ok:
		push_warning("[GameManager] pet merge drop inconsistent snapshot id=%s side=local" % str(a.get("id", "")))
		return b.duplicate(true)
	if not b_ok:
		push_warning("[GameManager] pet merge drop inconsistent snapshot id=%s side=cloud" % str(b.get("id", "")))
		return a.duplicate(true)
	var a_score: = _pet_progress_score(a)
	var b_score: = _pet_progress_score(b)
	if a_score >= b_score:
		return a.duplicate(true)
	return b.duplicate(true)

func _merge_pet_progress_roster_dicts(primary: Dictionary, secondary: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if primary is Dictionary:
		out = primary.duplicate(true)
	for roster_key in ["pets", "pet_bag", "assist_pets"]:
		if not out.has(roster_key) or not out.get(roster_key) is Array:
			out[roster_key] = []
	var index: = _build_pet_progress_index_from_roster_dict(out)
	var secondary_index: = _build_pet_progress_index_from_roster_dict(secondary if secondary is Dictionary else {})
	for pid in secondary_index.keys():
		var sec_pet: Dictionary = secondary_index[pid]
		if not index.has(pid):
			index[pid] = sec_pet
			if _pet_dict_in_roster_list(secondary.get("assist_pets", []), pid):
				var assist_out: Array = out.get("assist_pets", [])
				while assist_out.size() < 10:
					assist_out.append(null)
				var placed: = false
				var sec_assist: Variant = secondary.get("assist_pets", [])
				if sec_assist is Array:
					for si in range(mini(10, sec_assist.size())):
						var sp: Variant = sec_assist[si]
						if sp is Dictionary and str(sp.get("id", "")) == pid:
							assist_out[si] = sec_pet
							placed = true
							break
				if not placed:
					for si in range(10):
						if assist_out[si] == null:
							assist_out[si] = sec_pet
							break
				out["assist_pets"] = assist_out
			else:
				var bag_key: = "pet_bag" if _pet_dict_in_roster_list(secondary.get("pet_bag", []), pid) else "pets"
				out[bag_key].append(sec_pet)
			continue
		index[pid] = _pick_higher_pet_progress_dict(index[pid], sec_pet)
	for roster_key in ["pets", "pet_bag", "assist_pets"]:
		var roster: Array = out.get(roster_key, [])
		for i in range(roster.size()):
			var p: Variant = roster[i]
			if p is Dictionary and p.has("id"):
				var pid: = str(p.id)
				if index.has(pid):
					roster[i] = index[pid]
	return out

func _pet_dict_in_roster_list(roster: Variant, pet_id: String) -> bool:
	if not roster is Array:
		return false
	for p in roster:
		if p is Dictionary and str(p.get("id", "")) == pet_id:
			return true
	return false


func _peek_local_pet_roster_dict_for_merge_guard() -> Dictionary:
	if not _logged_in_per_user_slot():
		return {}
	var active_save_path: = _get_active_save_file_name()
	var active_backup_path: = _get_active_save_backup_file_name()
	var save_data: Variant = null
	var save_file: = FileAccess.open(active_save_path, FileAccess.READ)
	if save_file:
		var encrypted: = save_file.get_buffer(save_file.get_length())
		save_file.close()
		if not encrypted.is_empty():
			save_data = _decrypt_and_validate_save(encrypted)
			if save_data is Dictionary and not _local_save_owner_matches_session(save_data):
				save_data = null
	if save_data == null:
		var backup_file: = FileAccess.open(active_backup_path, FileAccess.READ)
		if backup_file:
			var encrypted_b: = backup_file.get_buffer(backup_file.get_length())
			backup_file.close()
			if not encrypted_b.is_empty():
				save_data = _decrypt_and_validate_save(encrypted_b)
				if save_data is Dictionary and not _local_save_owner_matches_session(save_data):
					save_data = null
	if save_data == null or not save_data is Dictionary:
		return {}
	var pets_var: Variant = (save_data as Dictionary).get("pets", {})
	return pets_var if pets_var is Dictionary else {}

func _build_pet_progress_merge_source(local_pet_data: Dictionary) -> Dictionary:
	var merged: = local_pet_data if local_pet_data is Dictionary else {}
	var disk_pets: = _peek_local_pet_roster_dict_for_merge_guard()
	if disk_pets.is_empty():
		return merged
	return _merge_pet_progress_roster_dicts(merged, disk_pets)

func _should_defer_non_authoritative_pets_merge(opts: Dictionary) -> bool:
	if bool(opts.get("pets_authoritative", false)):
		return false
	return _active_pet_pending_cloud_sync or _current_map_pending_cloud_sync or _pet_bag_op_pending_cloud_sync

func merge_pets_data_roster_whole_snapshot(base: Dictionary, overlay: Dictionary) -> Dictionary:

	return _merge_pet_progress_roster_dicts(base if base is Dictionary else {}, overlay if overlay is Dictionary else {})

func _merge_cloud_pets_preserve_local_progress(pets_data: Array, pet_bag_data: Array, local_pet_data: Dictionary, opts: Dictionary, assist_pets_data: Array = []) -> void :
	if bool(opts.get("skip_pet_progress_merge", false)):
		return
	if bool(opts.get("allow_pet_progress_downgrade", false)):
		return
	var local_by_id: Dictionary = _build_pet_progress_index_from_roster_dict(
		_build_pet_progress_merge_source(local_pet_data)
	)
	if local_by_id.is_empty():
		return
	var merged: = 0
	for roster in [pets_data, pet_bag_data, assist_pets_data]:
		if not roster is Array:
			continue
		for i in range(roster.size()):
			var incoming: Variant = roster[i]
			if not incoming is Dictionary:
				continue
			var incoming_pet: Dictionary = incoming
			var pid: = str(incoming_pet.get("id", "")).strip_edges()
			if pid.is_empty() or not local_by_id.has(pid):
				continue
			var local_pet: Dictionary = local_by_id[pid]
			var cloud_lv: = int(incoming_pet.get("level", 1))
			var local_lv: = int(local_pet.get("level", 1))
			if bool(local_pet.get("is_elite", false)) and not bool(incoming_pet.get("is_elite", false)):
				incoming_pet["is_elite"] = true
				roster[i] = incoming_pet
				merged += 1
				print("[GameManager] pet is_elite downgrade blocked id=%s" % pid)
			var pick_source: Dictionary = incoming_pet
			var pick_label: = "cloud"
			var merge_reason: = "cloud_default"
			if _is_same_pet_lifecycle_for_upload_guard(local_pet, incoming_pet):
				pick_source = _pick_higher_pet_progress_dict(local_pet, incoming_pet)
				pick_label = "local" if _pet_merge_picked_from_local(local_pet, incoming_pet) else "cloud"
				merge_reason = "higher_progress_same_lifecycle"
			elif local_lv > cloud_lv and not _cloud_pet_lifecycle_ahead_of_local(local_pet, incoming_pet):
				pick_source = local_pet
				pick_label = "local"
				merge_reason = "local_progress_lifecycle_mismatch"
				push_warning(
					"[GameManager] pet merge lifecycle mismatch keep local id=%s localLv=%d cloudLv=%d localGen=%d cloudGen=%d"
					%[
						pid, 
						local_lv, 
						cloud_lv, 
						maxi(0, int(local_pet.get("generation", 0))), 
						maxi(0, int(incoming_pet.get("generation", 0))), 
					]
				)
			elif _cloud_pet_lifecycle_ahead_of_local(local_pet, incoming_pet):
				pick_source = incoming_pet
				pick_label = "cloud"
				merge_reason = "evolution_forward"
			elif _local_pet_lifecycle_ahead_of_cloud(local_pet, incoming_pet):
				pick_source = local_pet
				pick_label = "local"
				merge_reason = "local_evolution_forward"
			else:
				pick_source = _pick_higher_pet_progress_dict(local_pet, incoming_pet)
				pick_label = "local" if _pet_merge_picked_from_local(local_pet, incoming_pet) else "cloud"
				merge_reason = "higher_progress"
			if pick_source != incoming_pet:
				var snapshot: = pick_source.duplicate(true)
				if incoming_pet.has("id"):
					snapshot["id"] = incoming_pet["id"]
				roster[i] = snapshot
				merged += 1
				print(
					"[GameManager] pet whole-snapshot merge id=%s pick=%s reason=%s localLv=%d cloudLv=%d outLv=%d"
					%[
						pid, 
						pick_label, 
						merge_reason, 
						local_lv, 
						cloud_lv, 
						int(snapshot.get("level", 1)), 
					]
				)
	if merged > 0:
		print("[GameManager] pet progress merge count=%d" % merged)

func _patch_cloud_pet_roster_locked_from_local(pets_data: Array, pet_bag_data: Array, local_pet_data: Dictionary, assist_pets_data: Array = []) -> void :
	var local_locked: Dictionary = _build_pet_locked_index_from_roster_dict(local_pet_data)
	if local_locked.is_empty():
		return
	_apply_pet_locked_index_to_roster_arrays(pets_data, pet_bag_data, assist_pets_data, local_locked)

func _build_pet_locked_index_from_roster_arrays(pets_data: Array, pet_bag_data: Array, assist_pets_data: Array = []) -> Dictionary:
	var out: Dictionary = {}
	for roster in [pets_data, pet_bag_data, assist_pets_data]:
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				var pid: = str(p.id).strip_edges()
				if not pid.is_empty():
					out[pid] = bool(p.get("locked", false))
	return out

func _apply_pet_locked_index_to_roster_arrays(pets_data: Array, pet_bag_data: Array, assist_pets_data: Array, locked_index: Dictionary) -> void :
	if locked_index.is_empty():
		return
	for roster in [pets_data, pet_bag_data, assist_pets_data]:
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				var pid: = str(p.id)
				if locked_index.has(pid):
					p["locked"] = locked_index[pid]

func _coerce_pet_raise_race_used_flag(v: Variant) -> bool:
	if v == null:
		return false
	match typeof(v):
		TYPE_BOOL:
			return v
		TYPE_INT:
			return int(v) != 0
		TYPE_FLOAT:
			return int(round(float(v))) != 0
		TYPE_STRING:
			var s: = str(v).strip_edges().to_lower()
			if s.is_empty() or s in ["0", "false", "no", "off", "n"]:
				return false
			if s in ["1", "true", "yes", "on", "y"]:
				return true
			return false
		_:
			return false

func _pet_dict_raise_race_used(p: Dictionary) -> bool:
	if p.has("pet_raise_race_used"):
		return _coerce_pet_raise_race_used_flag(p.get("pet_raise_race_used"))
	if p.has("petRaiseRaceUsed"):
		return _coerce_pet_raise_race_used_flag(p.get("petRaiseRaceUsed"))
	return false

func _build_pet_raise_race_used_index_from_roster_dict(pet_data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if pet_data == null or not pet_data is Dictionary:
		return out
	for roster_key in ["pets", "pet_bag", "assist_pets"]:
		var roster: Variant = pet_data.get(roster_key, [])
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				var pid: = str(p.id).strip_edges()
				if not pid.is_empty() and _pet_dict_raise_race_used(p):
					out[pid] = true
	return out

func _build_pet_raise_race_used_index_from_roster_arrays(pets_data: Array, pet_bag_data: Array, assist_pets_data: Array = []) -> Dictionary:
	var out: Dictionary = {}
	for roster in [pets_data, pet_bag_data, assist_pets_data]:
		if not roster is Array:
			continue
		for p in roster:
			if p is Dictionary and p.has("id"):
				var pid: = str(p.id).strip_edges()
				if not pid.is_empty() and _pet_dict_raise_race_used(p):
					out[pid] = true
	return out

func _or_pet_raise_race_used_into_rosters(pets_data: Array, pet_bag_data: Array, assist_pets_data: Array, local_pet_data: Dictionary, cloud_used: Dictionary) -> void :
	var local_used: Dictionary = _build_pet_raise_race_used_index_from_roster_dict(local_pet_data)
	if local_used.is_empty() and cloud_used.is_empty():
		return
	for roster in [pets_data, pet_bag_data, assist_pets_data]:
		if not roster is Array:
			continue
		for p in roster:
			if not (p is Dictionary) or not p.has("id"):
				continue
			var pid: = str(p.id).strip_edges()
			if pid.is_empty():
				continue
			if bool(cloud_used.get(pid, false)) or bool(local_used.get(pid, false)):
				p["pet_raise_race_used"] = true

func _set_live_pet_locked_by_id(pet_id: String, locked: bool) -> void :
	var pid: = pet_id.strip_edges()
	if pid.is_empty() or pet_manager == null:
		return
	var changed: = false
	for roster in [pet_manager.pets, pet_manager.pet_bag]:
		if not roster is Array:
			continue
		for p in roster:
			if p != null and str(p.id).strip_edges() == pid:
				p.locked = locked
				changed = true
	if pet_manager.assist_pets is Array:
		for p in pet_manager.assist_pets:
			if p != null and str(p.id).strip_edges() == pid:
				p.locked = locked
				changed = true
	if changed:
		pet_manager.pet_list_changed.emit()

func _assist_roster_has_any_pet(assist_pets_data: Variant) -> bool:
	if not assist_pets_data is Array:
		return false
	for ap in assist_pets_data:
		if ap is Dictionary and ap.has("id"):
			return true
	return false

func _notify_authoritative_equipment_applied() -> void :
	if equipment_manager == null:
		return


	var sample = null
	for slot in ["weapon", "armor", "helmet", "boots", "accessory"]:
		var eq_item = equipment_manager.equipped.get(slot, null)
		if eq_item != null:
			sample = eq_item
			break
	equipment_manager.equipment_changed.emit("weapon", sample)

func begin_pet_bag_op_cloud_sync() -> void :
	if network != null and network.is_logged_in() and _cloud_sync_gate_passed:
		_pet_bag_op_pending_cloud_sync = true

func end_pet_bag_op_cloud_sync() -> void :
	_pet_bag_op_pending_cloud_sync = false

func get_suit_enhance_pending() -> Dictionary:
	return _suit_enhance_pending.duplicate(true) if _suit_enhance_pending is Dictionary else {}

func clear_suit_enhance_pending() -> void :
	_suit_enhance_pending = {}

func _is_suit_enhance_pending_active(pending: Dictionary) -> bool:
	if pending.is_empty():
		return false
	var token: = str(pending.get("token", "")).strip_edges()
	if token.is_empty():
		return false
	var now_ms: = Time.get_unix_time_from_system() * 1000
	var expires_at: = int(pending.get("expiresAt", pending.get("expires_at", 0)))
	if expires_at > 0:
		return now_ms < expires_at
	var created_at: = int(pending.get("createdAt", pending.get("created_at", 0)))
	if created_at > 0:
		return now_ms < created_at + SuitEquipmentEnhanceClass.PENDING_EXPIRE_SEC * 1000
	return false

func _sync_suit_enhance_pending_from_settings(settings: Dictionary) -> void :
	if settings.is_empty():
		return
	if not settings.has("pending_suit_enhance"):
		_suit_enhance_pending = {}
		return
	var raw: Variant = settings.get("pending_suit_enhance")
	if raw is Dictionary and _is_suit_enhance_pending_active(raw):
		_suit_enhance_pending = (raw as Dictionary).duplicate(true)
	else:
		_suit_enhance_pending = {}

func apply_cloud_save(save_data: Dictionary, opts: Dictionary = {}):
	if save_data == null or not save_data is Dictionary:
		print("[GameManager] 云存档数据无效，保持本地数据")
		return

	if save_data.keys().size() == 0:
		print("[GameManager] 云存档为空对象，保持本地数据")
		return
	var now_apply_ms: = Time.get_ticks_msec()
	_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, now_apply_ms + 2000)
	_is_applying_cloud_save = true
	var incoming_revision: = _extract_save_revision_from_save_data(save_data)
	if incoming_revision >= 0:
		_set_cloud_save_revision(incoming_revision)

	_migrate_cloud_save_data(save_data)
	var pending_offline_rewards: Dictionary = _consume_pending_offline_player_rewards(save_data)

	_apply_offline_rewards(save_data)

	var is_valid_player_data = func(pd) -> bool:
		if pd == null or not pd is Dictionary:
			return false
		if not pd.has("name") or not pd.has("level"):
			return false
		if pd.get("name", "") == "":
			return false
		if pd.get("level", 0) < 1:
			return false
		return true

	var economy_cultivation_pill_slice: bool = bool(opts.get("economy_cultivation_pill_slice", false))
	var reward_inventory_slice: bool = bool(opts.get("reward_inventory_slice", false))
	var authoritative_equipment_inventory: bool = bool(opts.get("authoritative_equipment_inventory", false))
	var authoritative_martial_arts: bool = bool(opts.get("authoritative_martial_arts", false))
	var clamp_inventory_local_consumption: bool = bool(opts.get("clamp_inventory_local_consumption", false))
	var granted_item_names: Array = opts.get("granted_item_names", []) if opts.get("granted_item_names") is Array else []
	var offline_claim_authoritative_player: bool = bool(opts.get("offline_claim_authoritative", false))

	if player != null:
		var local_player_data = player.to_dict()

		if save_data.has("playerData"):
			var pd = save_data.get("playerData", {})
			if is_valid_player_data.call(pd):
				# 双倍经验通道是服务端权威、且单调只涨不跌（合并取 max），
				# 所以不管下面走哪个分支都要先合并一次。
				# 之前只在 double_exp_slice 分支里合并 → 登录时若判定「云端快照较旧」
				# 跳过整包 from_dict，本地 double_exp_channels 就是空的，
				# 战报会按 1 种播报（三丹齐开也只显示 +100%）。
				sync_player_authoritative_vip_double_exp_from_dict(pd)
				if _player_data_slice_skip_full_merge(opts):
					if economy_cultivation_pill_slice:
						print("[GameManager] 修行丹经济回包：跳过 playerData 整包合并，保留本地等级/经验")
					elif reward_inventory_slice:
						print("[GameManager] 礼包奖励回包：跳过 playerData 整包合并，仅对齐货币等奖励字段")
					elif bool(opts.get("realm_transition_slice", false)):
						print("[GameManager] 飞升/投胎回包：realm_transition slice，跳过 playerData 整包")
					elif bool(opts.get("attr_authoritative_slice", false)):
						print("[GameManager] 属性点权威回包：attr slice，跳过 playerData 整包")
					elif bool(opts.get("double_exp_slice", false)):
						print("[GameManager] 双倍经验回包：double_exp slice，跳过 playerData 整包")
					elif bool(opts.get("cosmetic_slice", false)):
						print("[GameManager] 换造型回包：cosmetic slice，跳过 playerData 整包")
					else:
						print("[GameManager] 权威回包 playerData slice 合并，跳过整包 from_dict")
					_apply_player_data_slices_from_opts(pd, opts, local_player_data)
				elif offline_claim_authoritative_player or _should_apply_cloud_player_over_local(pd):
					pd = preserve_local_player_attr_over_stale_cloud(local_player_data, pd)
					pd = _merge_monotonic_permanent_points_into_cloud_pd(local_player_data, pd)
					pd = _repair_player_attr_if_overspent(pd)
					if is_field_combat_hp_merge_blocked():
						sync_player_authoritative_upgrade_dan_slice_from_dict(pd)
						sync_player_authoritative_attr_slice_from_dict(pd, true)
						player.merge_xianmo_titles_from_cloud_player_dict(pd)
						sync_player_authoritative_reward_gold_from_dict(pd)
						print("[GameManager] 野外连战 HP 保护：权威回包仅合并等级/经验/属性点，跳过 hp/max_hp 整包")
					else:
						player.from_dict(pd)
						gold_changed.emit(player.gold)
						yuanbao_changed.emit(player.yuanbao_currency)
						var pts = float(pd.get("timestamp", 0))
						if pts > 0:
							_last_local_save_timestamp = max(_last_local_save_timestamp, pts)
						if offline_claim_authoritative_player:
							print("[GameManager] 登录离线结算：playerData 权威合并成功")
						else:
							print("[GameManager] 玩家数据从云存档恢复成功")
				else:
					print("[GameManager] 云端玩家快照较旧，跳过覆盖本地 (cloud_ts=%s local_ts=%s)" % [str(pd.get("timestamp", 0)), str(_last_local_save_timestamp)])

					player.merge_xianmo_titles_from_cloud_player_dict(pd)
					call_deferred("save_game", true)
			else:
				if local_player_data.has("name") and local_player_data.has("level"):
					player.from_dict(local_player_data)
					print("[GameManager] 云存档玩家数据无效，保持本地数据")
		else:
			if local_player_data.has("name"):
				player.from_dict(local_player_data)
				print("[GameManager] 云存档无玩家数据，保持本地数据")

		if pending_offline_rewards.get("exp", 0) > 0:
			var pending_exp = int(pending_offline_rewards.get("exp", 0))
			var exp_messages: Array = player.add_exp(pending_exp)
			for msg in exp_messages:
				print("[OfflineRewards] %s" % msg)
			print("[OfflineRewards] 已通过 Player.add_exp 发放离线经验: %d" % pending_exp)

		if pending_offline_rewards.get("gold", 0) > 0:
			var pending_gold = int(pending_offline_rewards.get("gold", 0))
			player.gold += pending_gold
			gold_changed.emit(player.gold)
			print("[OfflineRewards] 已发放离线金币: %d" % pending_gold)

	if pet_manager != null:

		var local_pet_data = _build_pet_progress_merge_source(pet_manager.to_dict())
		var pets_authoritative: bool = bool(opts.get("pets_authoritative", false))
		var preserve_local_pets: bool = bool(opts.get("preserve_local_pets_not_in_cloud", false))
		var offline_claim_authoritative: bool = bool(opts.get("offline_claim_authoritative", false))
		var offline_active_old_level: int = -1
		var offline_active_old_medals: int = -1
		if offline_claim_authoritative:
			var lap = pet_manager.get_active_pet()
			if lap != null and int(lap.reincarnation_count) <= 0:
				offline_active_old_level = int(lap.level)
				offline_active_old_medals = PetManager.sum_medal_counts_for_pet(lap)

		if save_data.has("petsData"):
			var active_pet_id = ""
			var pets_data = []
			var pet_bag_data = []
			var assist_pets_data: Array = []
			var cloud_has_assist_key: = false

			var pets_data_raw = save_data.get("petsData", [])
			if pets_data_raw == null:
				pets_data_raw = []
			if pets_data_raw is Dictionary:
				active_pet_id = pets_data_raw.get("active_pet_id", "")
				pets_data = pets_data_raw.get("pets", [])
				pet_bag_data = pets_data_raw.get("pet_bag", [])
				if pets_data_raw.has("assist_pets"):
					cloud_has_assist_key = true
					var raw_assist = pets_data_raw.get("assist_pets", [])
					if raw_assist is Array:
						assist_pets_data = raw_assist
			else:
				pets_data = pets_data_raw



			if pets_authoritative:
				if not cloud_has_assist_key:
					assist_pets_data = []
			elif not cloud_has_assist_key:
				var local_assist = local_pet_data.get("assist_pets", [])
				if local_assist is Array:
					assist_pets_data = local_assist


			if pets_data.size() > 0 or pet_bag_data.size() > 0 or _assist_roster_has_any_pet(assist_pets_data):
				var defer_pets_merge: = _should_defer_non_authoritative_pets_merge(opts)
				if is_field_battle_loot_upload_blocked() and not bool(opts.get("pets_authoritative", false)):
					defer_pets_merge = true
					print("[GameManager] battle-loot pending，暂缓非权威 petsData 整栏合并")
				if defer_pets_merge:
					print("[GameManager] 宠物相关上传未完成，暂缓非权威 petsData 合并")
				else:
					if preserve_local_pets:

						var cloud_ids: = {}
						for p in pets_data:
							if p is Dictionary and p.has("id"):
								cloud_ids[str(p.id)] = true
						for p in pet_bag_data:
							if p is Dictionary and p.has("id"):
								cloud_ids[str(p.id)] = true
						for ap in assist_pets_data:
							if ap is Dictionary and ap.has("id"):
								cloud_ids[str(ap.id)] = true
						var local_pets: Array = local_pet_data.get("pets", [])
						var local_bag: Array = local_pet_data.get("pet_bag", [])
						var local_assist_raw: Variant = local_pet_data.get("assist_pets", [])
						var local_assist_arr: Array = local_assist_raw if local_assist_raw is Array else []
						for p in local_pets:
							if p is Dictionary and p.has("id") and not cloud_ids.has(str(p.id)):
								pets_data.append(p)
						for p in local_bag:
							if p is Dictionary and p.has("id") and not cloud_ids.has(str(p.id)):
								pet_bag_data.append(p)

						var local_bag_ids: Dictionary = {}
						for p in local_bag:
							if p is Dictionary and p.has("id"):
								local_bag_ids[str(p.id)] = p
						if local_bag_ids.size() > 0:
							var filtered_pets: Array = []
							for p in pets_data:
								if p is Dictionary and p.has("id"):
									var bag_pid: = str(p.id)
									if local_bag_ids.has(bag_pid):
										var already_in_bag: = false
										for bp in pet_bag_data:
											if bp is Dictionary and str(bp.get("id", "")) == bag_pid:
												already_in_bag = true
												break
										if not already_in_bag:
											pet_bag_data.append(local_bag_ids[bag_pid])
										continue
								filtered_pets.append(p)
							pets_data = filtered_pets
						var local_pet_ids: Dictionary = {}
						for p in local_pets:
							if p is Dictionary and p.has("id"):
								local_pet_ids[str(p.id)] = p
						if local_pet_ids.size() > 0:
							var filtered_bag: Array = []
							for p in pet_bag_data:
								if p is Dictionary and p.has("id"):
									var main_pid: = str(p.id)
									if local_pet_ids.has(main_pid):
										var already_in_pets: = false
										for mp in pets_data:
											if mp is Dictionary and str(mp.get("id", "")) == main_pid:
												already_in_pets = true
												break
										if not already_in_pets:
											pets_data.append(local_pet_ids[main_pid])
										continue
								filtered_bag.append(p)
							pet_bag_data = filtered_bag

						if not pets_authoritative and not cloud_has_assist_key and local_assist_arr.size() > 0:
							assist_pets_data = local_assist_arr

					var cloud_locked_before_merge: Dictionary = {}
					var cloud_raise_race_used_before_merge: Dictionary = {}
					if pets_authoritative:
						cloud_locked_before_merge = _build_pet_locked_index_from_roster_arrays(pets_data, pet_bag_data, assist_pets_data)
					else:
						_patch_cloud_pet_roster_locked_from_local(pets_data, pet_bag_data, local_pet_data, assist_pets_data)
					cloud_raise_race_used_before_merge = _build_pet_raise_race_used_index_from_roster_arrays(pets_data, pet_bag_data, assist_pets_data)
					_merge_cloud_pets_preserve_local_progress(pets_data, pet_bag_data, local_pet_data, opts, assist_pets_data)
					if pets_authoritative:
						_apply_pet_locked_index_to_roster_arrays(pets_data, pet_bag_data, assist_pets_data, cloud_locked_before_merge)
						print("[GameManager] pets_authoritative 回包，已合并本地宠物进度（只升不降），locked 以云端为准")
					_or_pet_raise_race_used_into_rosters(pets_data, pet_bag_data, assist_pets_data, local_pet_data, cloud_raise_race_used_before_merge)
					if _active_pet_pending_cloud_sync:
						var local_active_id: = str(local_pet_data.get("active_pet_id", "")).strip_edges()
						var cloud_active_id: = str(active_pet_id).strip_edges()
						if not local_active_id.is_empty() and local_active_id != cloud_active_id:
							print("[GameManager] 出战宠切换上传未完成，保留本地 active_pet_id=%s（云端=%s）" % [local_active_id, cloud_active_id])
							active_pet_id = local_active_id
					var normalized_roster: = _normalize_pets_data_roster_layout(pets_data, pet_bag_data, active_pet_id, assist_pets_data)
					pets_data = normalized_roster.get("pets", pets_data)
					pet_bag_data = normalized_roster.get("pet_bag", pet_bag_data)
					assist_pets_data = normalized_roster.get("assist_pets", assist_pets_data)
					pet_manager.from_dict({"pets": pets_data, "pet_bag": pet_bag_data, "assist_pets": assist_pets_data, "active_pet_id": active_pet_id})
					if offline_claim_authoritative and offline_active_old_level >= 0:
						var ap = pet_manager.get_active_pet()
						if ap != null and int(ap.reincarnation_count) <= 0:
							var eff_max: int = int(ap.get_effective_max_level())
							var medal_now: int = PetManager.sum_medal_counts_for_pet(ap)
							if offline_active_old_level < eff_max and int(ap.level) >= eff_max and medal_now == offline_active_old_medals:
								var medal_msg: String = pet_manager.grant_max_level_medal_if_needed(ap, offline_active_old_level)
								if not medal_msg.is_empty():
									print("[OfflineRewards] %s" % medal_msg)
								pet_manager.flush_pending_pet_medal_syncs("max_level_reward")
			else:

				if local_pet_data.has("pets") and local_pet_data["pets"].size() > 0:
					pet_manager.from_dict(local_pet_data)
				else:

					pet_manager.bootstrap_starter_pet_if_needed()
		else:

			if local_pet_data.has("pets") and local_pet_data["pets"].size() > 0:
				pet_manager.from_dict(local_pet_data)
			else:

				pet_manager.bootstrap_starter_pet_if_needed()

	if inventory_manager != null:

		var local_inventory_data = inventory_manager.to_dict()

		if save_data.has("inventoryData"):
			var inv = save_data.get("inventoryData", {})
			if inv != null and inv is Dictionary and (inv.has("items") or inv.has("warehouse_items")):
				if clamp_inventory_local_consumption and not authoritative_equipment_inventory:
					inv = _clamp_cloud_inventory_local_consumption(inv, local_inventory_data, granted_item_names)
					save_data["inventoryData"] = inv
				inventory_manager.from_dict(inv)
				inventory_manager.inventory_changed.emit()
			else:

				if local_inventory_data.has("items") and local_inventory_data["items"].size() > 0:
					inventory_manager.from_dict(local_inventory_data)
		else:

			if local_inventory_data.has("items") and local_inventory_data["items"].size() > 0:
				inventory_manager.from_dict(local_inventory_data)

	if equipment_manager != null:

		var local_equipment_data = equipment_manager.to_dict()

		if save_data.has("equipmentData"):
			var eq = save_data.get("equipmentData", {})
			if eq != null and eq is Dictionary and (eq.has("equipped") or eq.has("inventory")):
				if authoritative_equipment_inventory:
					equipment_manager.from_dict(eq.duplicate(true))
					_notify_authoritative_equipment_applied()
				else:
					var cloud_n: = _equipment_named_equipped_slot_count(eq)
					var local_n: = _equipment_named_equipped_slot_count(local_equipment_data)

					if cloud_n > 0:
						equipment_manager.from_dict(eq)
					elif local_n > 0:
						equipment_manager.from_dict(local_equipment_data)
					else:
						equipment_manager.from_dict(eq)
			else:

				if local_equipment_data.has("equipped") and local_equipment_data["equipped"].size() > 0:
					equipment_manager.from_dict(local_equipment_data)
		else:

			if local_equipment_data.has("equipped") and local_equipment_data["equipped"].size() > 0:
				equipment_manager.from_dict(local_equipment_data)

	if martial_arts_manager != null:

		var local_martial_arts_data = martial_arts_manager.to_dict()

		if save_data.has("martialArtsData"):
			var ma = save_data.get("martialArtsData", {})
			if ma != null and ma is Dictionary and ma.has("martial_arts"):
				if authoritative_martial_arts:
					martial_arts_manager.from_dict(ma)
					print("[GameManager] 武功数据已从权威回包合并（跳过本地优先逻辑）")
				else:
					var cloud_arts = ma.get("martial_arts", [])
					var local_arts = local_martial_arts_data.get("martial_arts", [])
					var cloud_n: int = cloud_arts.size() if cloud_arts is Array else 0
					var local_n: int = local_arts.size() if local_arts is Array else 0
					var cloud_pd: Dictionary = save_data.get("playerData", {}) if save_data.get("playerData") is Dictionary else {}


					if _prefer_local_martial_arts_over_cloud(local_n, cloud_n, cloud_pd):
						martial_arts_manager.from_dict(_sync_martial_daily_create_count_from_cloud(local_martial_arts_data, ma))
					elif cloud_n > 0:
						martial_arts_manager.from_dict(ma)
					elif local_n > 0:
						martial_arts_manager.from_dict(_sync_martial_daily_create_count_from_cloud(local_martial_arts_data, ma))
					else:
						martial_arts_manager.from_dict(ma)
			else:

				if local_martial_arts_data.has("martial_arts") and local_martial_arts_data["martial_arts"].size() > 0:
					martial_arts_manager.from_dict(local_martial_arts_data)
		else:

			if local_martial_arts_data.has("martial_arts") and local_martial_arts_data["martial_arts"].size() > 0:
				martial_arts_manager.from_dict(local_martial_arts_data)

	if crafting_manager != null:
		if save_data.has("craftingData"):
			var cr = save_data.get("craftingData", {})
			if cr != null and cr is Dictionary:
				crafting_manager.from_dict(cr)

	if suit_manager != null:

		var local_suit_data = suit_manager.to_dict()

		if save_data.has("suitData"):
			var sd = save_data.get("suitData", {})
			if sd != null and sd is Dictionary and (sd.has("equipped_suits") or sd.has("dungeon_progress")):
				suit_manager.from_dict(sd)

				if equipment_manager != null:
					equipment_manager._sync_equipped_suits_to_manager()
			else:

				if local_suit_data.has("equipped_suits") and local_suit_data["equipped_suits"].size() > 0:
					suit_manager.from_dict(local_suit_data)
		else:

			if local_suit_data.has("equipped_suits") and local_suit_data["equipped_suits"].size() > 0:
				suit_manager.from_dict(local_suit_data)

	if pet_collection_manager != null:

		var local_collection_data = pet_collection_manager.to_dict()
		var preserve_collection_ahead: bool = bool(opts.get("preserve_local_pet_collection_if_ahead", false))
		var skip_collection_trim: bool = bool(opts.get("skip_pet_collection_trim", false))
		var should_merge_collection: bool = preserve_collection_ahead or skip_collection_trim

		if save_data.has("petCollectionData"):
			var pc = save_data.get("petCollectionData", {})
			if pc != null and pc is Dictionary and pc.has("progress"):
				pc = _merge_pet_collection_take_max(local_collection_data, pc)
				pet_collection_manager.from_dict(pc)
			else:

				if local_collection_data.has("progress") and local_collection_data["progress"].size() > 0:
					pet_collection_manager.from_dict(local_collection_data)
		else:

			if local_collection_data.has("progress") and local_collection_data["progress"].size() > 0:
				pet_collection_manager.from_dict(local_collection_data)

	if pet_soul_manager != null:
		var local_pet_soul_data = pet_soul_manager.to_dict()
		var soul_loaded: = false
		if save_data.has("petCollectionData"):
			var pc_soul = save_data.get("petCollectionData", {})
			if pc_soul is Dictionary and pc_soul.has("pet_soul_data"):
				var soul_data = pc_soul.get("pet_soul_data", {})
				if soul_data is Dictionary:
					pet_soul_manager.from_dict(soul_data)
					soul_loaded = true
		if not soul_loaded:
			pet_soul_manager.from_dict(local_pet_soul_data)



	var local_pet_equipment_data = pet_equipment_manager.to_dict() if pet_equipment_manager else {}

	if pet_equipment_manager != null:
		if save_data.has("petEquipmentData"):
			var pe = save_data.get("petEquipmentData", {})
			if pe != null and pe is Dictionary and pe.has("equipped"):
				pet_equipment_manager.from_dict(pe)
			else:
				if local_pet_equipment_data.has("equipped") and local_pet_equipment_data["equipped"].size() > 0:
					pet_equipment_manager.from_dict(local_pet_equipment_data)
		else:
			if local_pet_equipment_data.has("equipped") and local_pet_equipment_data["equipped"].size() > 0:
				pet_equipment_manager.from_dict(local_pet_equipment_data)

	if save_data.has("gameSettings"):
		var settings = save_data.gameSettings
		if settings is Dictionary:
			if settings.has("save_revision"):
				_set_cloud_save_revision(int(settings.get("save_revision", -1)))
			if settings.has("current_map"):
				var cloud_map: = str(settings.get("current_map", "")).strip_edges()
				if _current_map_pending_cloud_sync and cloud_map != "" and cloud_map != str(current_map):
					print("[GameManager] 换图上传未完成，保留本地 current_map=%s（云端=%s）" % [current_map, cloud_map])
				elif cloud_map != "" and GameData.MAPS_DATA.has(cloud_map):
					current_map = cloud_map
				else:
					# 云端地图为空或不在表里（例如新建档的种子字段没填），
					# 直接赋值会让 MAPS_DATA.get() 取不到 → 主界面「地图数据加载失败」、
					# 不刷怪也没有人物。保留本地默认/上一张有效地图。
					push_warning("[GameManager] 云端 current_map 无效(%s)，保留本地 %s" % [cloud_map, current_map])
			if settings.has("auto_capture_enabled"):
				auto_capture_enabled = settings.auto_capture_enabled
			if settings.has("min_growth_threshold"):
				min_growth_threshold = settings.min_growth_threshold
			if settings.has("last_broadcast_id"):
				_last_broadcast_id = max(_last_broadcast_id, int(settings.get("last_broadcast_id", 0)))
				_save_broadcast_cursor()
			_sync_suit_enhance_pending_from_settings(settings)
			if fabao_manager:
				fabao_manager.apply_from_game_settings(settings)
	_save_audio_settings_to_config()


	if quest_manager != null:
		if save_data.has("questData"):
			var qd = save_data.get("questData", {})
			if qd != null and qd is Dictionary and qd.has("quests"):
				quest_manager.from_dict(qd)
			else:

				quest_manager.from_dict({"quests": {}, "daily_reset_time": 0})
		else:

			quest_manager.from_dict({"quests": {}, "daily_reset_time": 0})



	if not bool(opts.get("skip_title_gang_refresh", false)):
		if network and network.is_logged_in() and title_manager:
			title_manager.load_server_titles()
		if network and network.is_logged_in() and gang_manager:
			gang_manager.refresh_buffs()
			gang_manager.refresh_overview()
			gang_manager.refresh_titles()

	if player:
		var xianmo_titles_count: = 0
		for t in player.titles:
			if t and str(t.source) == "xianmo" and not t.is_expired():
				xianmo_titles_count += 1
	if player != null and pet_manager != null:
		pet_manager.update_max_pet_bag_for_vip(VipBenefits.tier_from_player(player))
	_enforce_server_nickname_matches_player(save_data)
	if network != null:
		network.discard_pending_saves_after_cloud_applied()
	if network != null and network.is_logged_in():
		mark_cloud_sync_ready()
		if bool(opts.get("skip_deferred_cloud_save", false)):

			_suppress_general_cloud_upload_until_ms = maxi(_suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 15000)
			call_deferred("save_game", false)
		else:
			call_deferred("save_game", true)

	if bool(opts.get("reconcile_treasure_chests", true)):
		call_deferred("_reconcile_treasure_chests_after_cloud_apply")

	_is_applying_cloud_save = false
	game_loaded.emit()
	print("云存档已应用")

func get_game_stats() -> Dictionary:
	return {
		"player_level": player.level if player else 1, 
		"player_realm": player.realm if player else "凡人", 
		"pet_count": pet_manager.get_pet_count() if pet_manager else 0, 
		"total_gold": player.gold if player else 0, 
		"current_map": current_map
	}

func get_gang_exp_bonus_percent() -> float:
	if gang_manager:
		return gang_manager.get_buff_percent("exp")
	return 0.0

func get_noble_exp_bonus_percent() -> float:
	return float(maxi(0, noble_exp_bonus))

func get_gang_gold_drop_bonus_percent() -> float:
	if gang_manager:
		return gang_manager.get_buff_percent("gold_drop")
	return 0.0

func _log_field_battle_exp_bonuses_once(loot_pd: Dictionary = {}) -> void :
	# 优先用服务端 battle-loot 回包里的权威倍率明细。
	# 客户端本地算的通道数不可靠：登录时若跳过云端 playerData 整包合并
	# （_should_apply_cloud_player_over_local 判云端快照较旧），
	# player.double_exp_channels 就是空的，三丹齐开也只播 +100%。
	var srv_channels: int = -1
	var srv_vip_mult: float = -1.0
	if loot_pd is Dictionary and not loot_pd.is_empty():
		if loot_pd.has("activeDoubleExpChannels"):
			srv_channels = int(loot_pd.get("activeDoubleExpChannels", -1))
		if loot_pd.has("vipExpMultiplier"):
			srv_vip_mult = float(loot_pd.get("vipExpMultiplier", -1.0))
		# 兜底：有些回包（或旧服务端）没带 activeDoubleExpChannels，
		# 但一定带着 saveData.playerData.double_exp_channels —— 直接数生效通道，
		# 这就是服务端 exp_multiplier() 里加的那个数，比本地缓存可靠。
		if srv_channels < 0:
			var sd: Variant = loot_pd.get("saveData", null)
			if sd is Dictionary:
				var ppd: Variant = (sd as Dictionary).get("playerData", null)
				if ppd is Dictionary:
					var ch_var: Variant = (ppd as Dictionary).get("double_exp_channels", null)
					if ch_var is Dictionary:
						var now_ch: int = int(Time.get_unix_time_from_system())
						var active_n: int = 0
						for k in (ch_var as Dictionary).keys():
							if int((ch_var as Dictionary)[k]) > now_ch:
								active_n += 1
						srv_channels = active_n
						sync_player_authoritative_vip_double_exp_from_dict(ppd as Dictionary)
	print("[DoubleExpLog] 服务端通道数=%d 服务端VIP倍率=%.2f" % [srv_channels, srv_vip_mult])
	_log_vip_field_exp_bonus_once(srv_vip_mult)
	_log_double_exp_field_bonus_once(srv_channels)
	_log_weekend_field_exp_bonus_once(float(loot_pd.get("weekendExpBonus", -1.0)))
	_log_newbie_field_exp_bonus_once()
	_log_catchup_field_level_ups_once()
	_log_gang_field_battle_bonus_once()
	_log_noble_field_exp_bonus_once()
	_log_fabao_field_exp_bonus_once()
	_log_map_difficulty_field_exp_bonus_once()

func _log_vip_field_exp_bonus_once(server_vip_mult: float = -1.0) -> void :
	if _field_vip_exp_bonus_logged_in_window or battle_system == null or player == null:
		return
	var vip_mult: = server_vip_mult
	if vip_mult <= 0.0:
		vip_mult = VipBenefits.exp_multiplier(VipBenefits.tier_from_player(player))
	var vip_pct: = int(round((vip_mult - 1.0) * 100.0))
	if vip_pct <= 0:
		return
	_field_vip_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=gold]VIP加成：经验 +%d%%![/color]" % vip_pct)

func _log_double_exp_field_bonus_once(server_count: int = -1) -> void :
	if _field_double_exp_bonus_logged_in_window or battle_system == null or player == null:
		return
	# 服务端权威值优先；没拿到才退回本地通道数；再不行按 double_exp_until 兜 1 种。
	var count: = server_count
	if count < 0:
		if player.has_method("get_double_exp_channel_count"):
			count = int(player.get_double_exp_channel_count())
		else:
			count = 0
	if count <= 0:
		if player.has_method("is_double_exp_active") and player.is_double_exp_active():
			count = 1
		else:
			return
	_field_double_exp_bonus_logged_in_window = true
	# 一种 +100%、两种 +200%、三种 +300%（服务端 exp_multiplier 里每多一种就 +1.0）。
	var suffix: = ""
	if count > 1:
		suffix = "（%d种叠加）" % count
	battle_system.add_log("[color=orange]双倍经验符生效：经验 +%d%%!%s[/color]" % [count * 100, suffix])

func _log_weekend_field_exp_bonus_once(server_bonus: float = -1.0) -> void :
	if _field_weekend_exp_bonus_logged_in_window or battle_system == null:
		return
	# 服务端 battle-loot 回包的 weekendExpBonus 是唯一权威来源（0.0 = 今天没有加成）。
	# 只有旧服务端不回这个字段时才退回本机星期兜底：
	# Godot 的 weekday 是 0=周日、1=周一…6=周六，和 isoweekday（周一=1、周日=7）差一位。
	var bonus: = server_bonus
	if bonus < 0.0:
		var wd: = int(Time.get_datetime_dict_from_system().get("weekday", 0))
		bonus = 1.0 if (wd == 6 or wd == 0) else 0.0
	if bonus <= 0.01:
		return
	_field_weekend_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=#7fe3b0]周末双倍经验：野外经验 +%d%%（全服生效）[/color]" % int(round(bonus * 100.0)))

func _log_gang_field_battle_bonus_once() -> void :
	if _field_gang_bonus_logged_in_window or battle_system == null:
		return
	var parts: PackedStringArray = []
	var exp_pct: = get_gang_exp_bonus_percent()
	if exp_pct > 0.01:
		parts.append("经验 +%.0f%%" % exp_pct)
	var gold_pct: = get_gang_gold_drop_bonus_percent()
	if gold_pct > 0.01:
		parts.append("金币 +%.0f%%" % gold_pct)
	if parts.is_empty():
		return
	_field_gang_bonus_logged_in_window = true
	battle_system.add_log("[color=#7eb8ff]帮派加成：%s[/color]" % ", ".join(parts))

func _log_noble_field_exp_bonus_once() -> void :
	if _field_noble_exp_bonus_logged_in_window or battle_system == null:
		return
	var exp_pct: = get_noble_exp_bonus_percent()
	if exp_pct <= 0.01:
		return
	_field_noble_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=#ffd27a]贵族加成：经验 +%.0f%%[/color]" % exp_pct)

func _log_newbie_field_exp_bonus_once() -> void :
	if _field_newbie_exp_bonus_logged_in_window or battle_system == null:
		return
	if player == null or not player.has_method("is_newbie_exp_active"):
		return
	if not player.is_newbie_exp_active():
		return
	_field_newbie_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=#ffd27a]新人经验加成：经验 +100%[/color]")

func _log_catchup_field_level_ups_once() -> void :
	if _field_catchup_logged_in_window or battle_system == null or player == null:
		return
	var ups: = get_field_catchup_level_ups()
	if ups <= 1:
		return
	_field_catchup_logged_in_window = true
	battle_system.add_log("[color=#ffd27a]投胎追赶：本场最多连升 %d 级[/color]" % ups)

func _log_fabao_field_exp_bonus_once() -> void :
	if _field_fabao_exp_bonus_logged_in_window or battle_system == null:
		return
	var exp_mul: = FabaoStatBonus.exp_multiplier()
	var fabao_pct: = (exp_mul - 1.0) * 100.0
	if fabao_pct <= 0.01:
		return
	_field_fabao_exp_bonus_logged_in_window = true
	battle_system.add_log("[color=#ffd24d]法宝加成：经验 +%.1f%%![/color]" % fabao_pct)

func _log_map_difficulty_field_exp_bonus_once() -> void :
	if _field_map_diff_exp_bonus_logged_in_window or battle_system == null:
		return
	if fabao_manager == null and _wild_replay_map_difficulty.strip_edges().is_empty():
		return
	var tier_id: = _field_exp_difficulty_tier()
	var map_pct: = FabaoConfig.map_exp_bonus_pct(tier_id)
	if map_pct <= 0:
		return
	_field_map_diff_exp_bonus_logged_in_window = true
	var tier_name: = FabaoConfig.display_name(tier_id)
	battle_system.add_log("[color=#ff8a5c]难度加成：%s 经验 +%d%%[/color]" % [tier_name, map_pct])

func _offline_exp_multiplier_from_player_dict(player_data: Dictionary) -> float:
	var now_ts: = int(Time.get_unix_time_from_system())
	var tier: = VipBenefits.tier_from_player_data(player_data, now_ts)
	var vip_mult: = VipBenefits.exp_multiplier(tier)
	var double_exp_until: = int(player_data.get("double_exp_until", 0))
	var gang_bonus: = get_gang_exp_bonus_percent() / 100.0
	var noble_bonus: = get_noble_exp_bonus_percent() / 100.0
	var mult: = vip_mult + gang_bonus + noble_bonus
	if double_exp_until > now_ts:
		mult += 1.0

	if player != null and player.has_method("is_newbie_exp_active") and player.is_newbie_exp_active(now_ts):
		mult += 1.0
	return mult

func _consume_pending_offline_player_rewards(save_data: Dictionary) -> Dictionary:
	var consumed_rewards: = {
		"exp": 0, 
		"gold": 0
	}


	var pending_exp = int(save_data.get("pending_offline_exp", 0))
	var pending_gold = int(save_data.get("pending_offline_gold", 0))
	if pending_exp > 0:
		consumed_rewards["exp"] = pending_exp
	if pending_gold > 0:
		consumed_rewards["gold"] = pending_gold
	if save_data.has("pending_offline_exp"):
		save_data.erase("pending_offline_exp")
	if save_data.has("pending_offline_gold"):
		save_data.erase("pending_offline_gold")


	if save_data.has("playerData"):
		var player_data = save_data.get("playerData", {})
		if player_data is Dictionary:
			if player_data.has("offline_exp"):
				print("[OfflineRewards] 检测到旧字段 playerData.offline_exp，已清理避免重复结算")
				player_data.erase("offline_exp")
			if player_data.has("offline_gold"):
				print("[OfflineRewards] 检测到旧字段 playerData.offline_gold，已清理避免重复结算")
				player_data.erase("offline_gold")

	return consumed_rewards

func _apply_offline_rewards(save_data: Dictionary):
	if not save_data.has("playerData"):
		return

	var player_data = save_data.get("playerData", {})
	if not player_data is Dictionary:
		return




	if save_data.has("pet_offline_exp"):
		var pet_offline_exp = save_data.get("pet_offline_exp", {})
		var pets_data = save_data.get("petsData", [])
		var active_pet_id = ""

		if pets_data is Dictionary:
			active_pet_id = pets_data.get("active_pet_id", "")
			pets_data = pets_data.get("pets", [])

		if pets_data is Array and active_pet_id != "":
			for pet in pets_data:
				if pet is Dictionary:
					var pet_id = pet.get("id", "")

					if pet_id == active_pet_id and pet_offline_exp.has(pet_id):
						var exp_to_add = int(pet_offline_exp[pet_id])
						PetManagerClass.apply_offline_exp_to_pet_dictionary(pet, exp_to_add)


		save_data.erase("pet_offline_exp")


func request_world_boss_challenge_from_ui(root: Control) -> void :
	_request_world_boss_challenge_from_ui_async(root)

func _request_world_boss_challenge_from_ui_async(root: Control) -> void :
	if _world_boss_challenge_in_flight:
		return
	_world_boss_challenge_in_flight = true
	if root != null:
		_world_boss_ui_root = weakref(root)
	var block_msg: = get_instanced_challenge_block_message("world_boss")
	if not block_msg.is_empty():
		WorldBossUI.set_challenge_result(root, false, block_msg)
		_world_boss_challenge_in_flight = false
		return
	WorldBossUI.set_challenge_pending(root, true)
	var err: String = await _start_world_boss_battle_async()
	if root != null and is_instance_valid(root):
		if not err.is_empty():
			WorldBossUI.set_challenge_result(root, false, err)
		else:
			WorldBossUI.set_challenge_result(root, true)
	_world_boss_challenge_in_flight = false

func start_world_boss_battle() -> void :
	_start_world_boss_battle_async()

func start_world_boss_battle_and_return_error() -> String:
	return await _start_world_boss_battle_async()

func _start_world_boss_battle_async() -> String:
	var block_msg: = get_instanced_challenge_block_message("world_boss")
	if not block_msg.is_empty():
		return block_msg
	if network == null or network.auth_token == "":
		return "未登录"
	if pet_manager == null or pet_manager.get_active_pet() == null:
		return "请先设置出战宠物"
	await prepare_for_instanced_challenge_async()
	var start_res: Dictionary = await network.request_world_boss_battle_start()
	if not bool(start_res.get("ok", false)) and not bool(start_res.get("success", false)):
		resume_field_auto_battle_after_instanced_challenge()
		return str(start_res.get("error", "世界boss开战失败"))
	await _wait_field_replay_idle_async()
	world_boss_battle_token = str(start_res.get("battleToken", start_res.get("battle_token", "")))
	var boss_pet_id: = str(start_res.get("bossPetId", start_res.get("boss_pet_id", "")))
	var boss_stats: Dictionary = start_res.get("boss", {}) if start_res.get("boss") is Dictionary else {}
	world_boss_battle_max_rounds = int(start_res.get("battleMaxRounds", start_res.get("battle_max_rounds", 10)))
	var pdata: Dictionary = GameData.PET_DATA.get(boss_pet_id, {})
	var boss_hp: = int(boss_stats.get("hp", 100000000))
	var monster = Monster.create_from_template({
		"name": str(pdata.get("name", boss_pet_id)), 
		"pet_id": boss_pet_id, 
		"level": 1, 
		"element": str(pdata.get("element", "火")), 
		"attack": int(boss_stats.get("attack", 10000)), 
		"defense": int(boss_stats.get("defense", 30000)), 
		"agility": int(boss_stats.get("agility", 10000)), 
		"hp": boss_hp, 
		"max_hp": boss_hp, 
	})
	world_boss_damage_dealt = 0
	_world_boss_server_damage = int(start_res.get("damageDealt", start_res.get("damage_dealt", 0)))
	_world_boss_use_server_damage = bool(start_res.get("replay", false)) and is_world_boss_replay_on()
	_world_boss_replay_abort = false
	is_world_boss_battle = true
	_disconnect_all_battle_ended_handlers()
	if not battle_system.damage_dealt.is_connected(_on_world_boss_damage_dealt):
		battle_system.damage_dealt.connect(_on_world_boss_damage_dealt)
	battle_system.battle_ended.connect(_on_world_boss_battle_ended)
	battle_system.drive_by_execute_turn = false
	battle_system.suppress_battle_character_exp = true
	var active_pet = pet_manager.get_active_pet()
	var raw_monsters: Variant = start_res.get("monsters", [])
	var replay_monsters: Array = _hydrate_wild_replay_monsters(raw_monsters if raw_monsters is Array else [])
	var use_replay: = _world_boss_use_server_damage
	var raw_log: Variant = start_res.get("battleLog", start_res.get("battle_log", []))
	var battle_log: Array = raw_log if raw_log is Array else []
	if use_replay and (battle_log.is_empty() or replay_monsters.is_empty()):
		use_replay = false
		_world_boss_use_server_damage = false
	if use_replay:
		return await _play_world_boss_replay(start_res, boss_pet_id, replay_monsters, battle_log, active_pet)
	battle_system.replay_log_only = false
	if battle_system.start_battle(player, active_pet, [monster], world_boss_battle_max_rounds, false, resolve_attack_target_mode("world_boss")):
		last_battle_was_tower = false
		last_battle_was_suit_dungeon = false
		last_battle_was_world_boss = true
		last_battle_was_arena = false
		in_battle = true
		world_boss_battle_started.emit(boss_pet_id)
		_switch_to_battle_view_for_world_boss(boss_pet_id)
		return ""
	_cleanup_world_boss_battle_hooks()
	is_world_boss_battle = false
	resume_field_auto_battle_after_instanced_challenge()
	return "战斗启动失败"

func _play_world_boss_replay(start_res: Dictionary, boss_pet_id: String, monsters: Array, battle_log: Array, active_pet) -> String:
	battle_system.replay_log_only = true
	if not battle_system.start_battle(player, active_pet, monsters, world_boss_battle_max_rounds, false, resolve_attack_target_mode("world_boss")):
		_cleanup_world_boss_battle_hooks()
		battle_system.replay_log_only = false
		is_world_boss_battle = false
		resume_field_auto_battle_after_instanced_challenge()
		return "战斗启动失败"
	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = true
	last_battle_was_arena = false
	in_battle = true
	world_boss_battle_started.emit(boss_pet_id)
	_switch_to_battle_view_for_world_boss(boss_pet_id)
	_log_wild_replay_monster_encounters(monsters)
	var replay: = CombatReplayPlayerClass.new()
	replay.battle_system = battle_system
	replay.log_style = "wild"
	var mine: = PackedStringArray()
	if player:
		var pn: = str(player.player_name).strip_edges()
		if not pn.is_empty():
			mine.append(pn)
	if active_pet:
		var petn: = str(active_pet.pet_name).strip_edges()
		if not petn.is_empty():
			mine.append(petn)
	if mine.is_empty():
		var pn2: = str(start_res.get("playerName", "")).strip_edges()
		if not pn2.is_empty():
			mine.append(pn2)
		var petn2: = str(start_res.get("petName", "")).strip_edges()
		if not petn2.is_empty():
			mine.append(petn2)
	replay.mine_names = mine
	replay.should_abort = func() -> bool:
		return _world_boss_replay_abort or not is_world_boss_battle or battle_system == null
	var server_victory: = bool(start_res.get("victory", false))
	await replay.play_async(self, battle_log, server_victory)
	if is_world_boss_battle and battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.apply_replay_battle_state(server_victory)
	return ""

func _switch_to_battle_view_for_world_boss(boss_pet_id: String) -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_on_world_boss_battle_started"):
		main_ui.call("_on_world_boss_battle_started", boss_pet_id)

func _on_world_boss_damage_dealt(_attacker: String, _target: String, damage: int, _is_critical: bool = false, hit_target_type: String = "", _hit_target_index: int = -1, _element_tag: String = "", _is_armor_pierce: bool = false, _is_counter: bool = false, _target_element: String = "") -> void :
	if not is_world_boss_battle:
		return
	if hit_target_type == "monster":
		world_boss_damage_dealt += max(0, int(damage))

func _cleanup_world_boss_battle_hooks() -> void :
	if battle_system.damage_dealt.is_connected(_on_world_boss_damage_dealt):
		battle_system.damage_dealt.disconnect(_on_world_boss_damage_dealt)
	if battle_system.battle_ended.is_connected(_on_world_boss_battle_ended):
		battle_system.battle_ended.disconnect(_on_world_boss_battle_ended)
	battle_system.suppress_battle_character_exp = false
	battle_system.replay_log_only = false

func _on_world_boss_battle_ended(_victory: bool) -> void :
	if not is_world_boss_battle:
		return
	var token: = world_boss_battle_token
	var damage: = world_boss_damage_dealt
	if _world_boss_use_server_damage:
		damage = _world_boss_server_damage
	_world_boss_use_server_damage = false
	_world_boss_server_damage = 0
	_world_boss_replay_abort = true
	var pet_snapshot: Dictionary = {}
	var active_pet = pet_manager.get_active_pet()
	if active_pet:
		pet_snapshot = active_pet.to_dict() if active_pet.has_method("to_dict") else {}
	is_world_boss_battle = false
	world_boss_battle_token = ""
	in_battle = false
	_cleanup_world_boss_battle_hooks()
	player.heal_full()
	if active_pet:
		active_pet.heal_full()
	var report_ok: = false
	var report: Dictionary = {}
	if network != null and token != "":
		var report_res: Dictionary = await network.request_world_boss_battle_report(token, damage, pet_snapshot)
		report_ok = bool(report_res.get("ok", false)) or bool(report_res.get("success", false))
		if not report_ok:
			push_warning(str(report_res.get("error", "世界boss伤害上报失败")))
		else:
			report = report_res
			_refresh_world_boss_ui_if_open()
	_world_boss_last_settle = {
		"damage_reported": damage, 
		"report_ok": report_ok, 
		"my_total_damage": int(report.get("myTotalDamage", report.get("my_total_damage", 0))), 
		"my_rank": int(report.get("myRank", report.get("my_rank", 0))), 
		"remaining_attempts": int(report.get("remainingAttempts", report.get("remaining_attempts", -1))), 
	}
	last_battle_was_world_boss = true
	battle_ended_ui.emit(_victory)
	resume_field_auto_battle_after_instanced_challenge()
	battle_system.max_rounds = -1

func get_world_boss_last_settle() -> Dictionary:
	return _world_boss_last_settle.duplicate(true)

func refresh_world_boss_ui_panel(root: Control) -> void :
	if root != null:
		_world_boss_ui_root = weakref(root)
	if _world_boss_status_refresh_busy:
		_world_boss_status_refresh_pending = true
		return
	if network != null and network.has_method("prepare_world_boss_channels"):
		network.prepare_world_boss_channels()
	_refresh_world_boss_ui_panel_async(root)

func _refresh_world_boss_ui_if_open() -> void :
	if _world_boss_ui_root == null:
		return
	var root: Control = _world_boss_ui_root.get_ref() as Control
	if root != null and is_instance_valid(root):
		_refresh_world_boss_ui_panel_async(root)

func _refresh_world_boss_ui_panel_async(root: Control) -> void :
	if network == null:
		return
	if _world_boss_status_refresh_busy:
		_world_boss_status_refresh_pending = true
		return
	_world_boss_status_refresh_busy = true
	var result: Dictionary = await network.request_world_boss_status()
	_world_boss_status_refresh_busy = false
	if root == null or not is_instance_valid(root):
		return
	WorldBossUI.apply_status_to_root(root, result)
	if _world_boss_status_refresh_pending:
		_world_boss_status_refresh_pending = false
		call_deferred("refresh_world_boss_ui_panel", root)


const ArenaUIClass = preload("res://ui/city/arena_ui.gd")

func get_mirror_update_cooldown_remaining_ms() -> int:
	return maxi(0, _mirror_update_cooldown_until_ms - Time.get_ticks_msec())

func is_mirror_update_on_cooldown() -> bool:
	return get_mirror_update_cooldown_remaining_ms() > 0

func mark_mirror_update_cooldown() -> void :
	_mirror_update_cooldown_until_ms = Time.get_ticks_msec() + MIRROR_UPDATE_COOLDOWN_MS

func get_mirror_update_cooldown_label() -> String:
	var remain_ms: = get_mirror_update_cooldown_remaining_ms()
	if remain_ms <= 0:
		return ""
	var total_sec: = int(ceil(float(remain_ms) / 1000.0))
	return "%d:%02d" % [total_sec / 60, total_sec % 60]

func _mirror_update_cooldown_message() -> String:
	var label: = get_mirror_update_cooldown_label()
	if label.is_empty():
		return "更新冷却中，请稍后再试"
	return "更新冷却中，请 %s 后再试" % label

func open_arena_mirror_popup_from_ui(root: Control) -> void :
	_open_arena_mirror_popup_async(root)

func _open_arena_mirror_popup_async(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	if network == null or network.auth_token == "":
		ArenaUIClass.set_mirror_result(root, false, "未登录")
		return
	var res: Dictionary = await network.request_arena_mirror_info()
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		ArenaUIClass.set_mirror_result(root, false, str(res.get("error", "读取镜像失败")))
		return
	ArenaUIClass.show_mirror_popup(self, root, res)

func request_arena_mirror_update_from_ui(root: Control) -> void :
	_request_arena_mirror_update_async(root)

func _request_arena_mirror_update_async(root: Control) -> void :
	if _arena_mirror_update_busy:
		return
	if is_mirror_update_on_cooldown():
		ArenaUIClass.set_mirror_result(root, false, _mirror_update_cooldown_message())
		return
	if network == null or network.auth_token == "":
		ArenaUIClass.set_mirror_result(root, false, "未登录")
		return
	_arena_mirror_update_busy = true
	ArenaUIClass.set_mirror_popup_pending(root, true)
	if root != null:
		_arena_ui_root = weakref(root)
	var res: Dictionary = await network.request_arena_mirror_update()
	_arena_mirror_update_busy = false
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		ArenaUIClass.set_mirror_result(root, false, str(res.get("error", "更新镜像失败")))
		return
	mark_mirror_update_cooldown()
	ArenaUIClass.set_mirror_result(root, true, "", res)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)
	refresh_arena_ui_panel(root)

func open_treasure_mirror_popup_from_ui(root: Control) -> void :
	_open_treasure_mirror_popup_async(root)

func _open_treasure_mirror_popup_async(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	if network == null or network.auth_token == "":
		ArenaUIClass.set_mirror_result(root, false, "未登录")
		return
	var loading_data: = {
		"hasMirror": false, 
		"mirrorMode": "treasure", 
		"mirrorTitle": "当前藏宝洞镜像", 
	}
	ArenaUIClass.show_mirror_popup(self, root, loading_data)
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var res: Dictionary = await network.request_treasure_mirror_info()
	ArenaUIClass.set_mirror_popup_pending(root, false)
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		var read_err: = str(res.get("error", "读取镜像失败"))
		ArenaUIClass.set_mirror_result(root, false, read_err)
		return
	res["mirrorMode"] = "treasure"
	res["mirrorTitle"] = "当前藏宝洞镜像"
	ArenaUIClass.refresh_mirror_popup(root, res)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func request_treasure_mirror_update_from_ui(root: Control) -> void :
	_request_treasure_mirror_update_async(root)

func _request_treasure_mirror_update_async(root: Control) -> void :
	if _treasure_mirror_update_busy:
		return
	if is_mirror_update_on_cooldown():
		ArenaUIClass.set_mirror_result(root, false, _mirror_update_cooldown_message())
		return
	if network == null or network.auth_token == "":
		ArenaUIClass.set_mirror_result(root, false, "未登录")
		return
	_treasure_mirror_update_busy = true
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var res: Dictionary = await network.request_treasure_mirror_update()
	_treasure_mirror_update_busy = false
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("ok", false)) and not bool(res.get("success", false)):
		ArenaUIClass.set_mirror_result(root, false, str(res.get("error", "更新镜像失败")))
		return
	mark_mirror_update_cooldown()
	res["mirrorMode"] = "treasure"
	res["mirrorTitle"] = "当前藏宝洞镜像"
	ArenaUIClass.set_mirror_result(root, true, "", res)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func open_gang_mirror_popup_from_ui(root: Control) -> void :
	_open_gang_mirror_popup_async(root)

func _notify_gang_ui_message(root: Control, message: String, is_success: bool) -> void :
	if root == null or not is_instance_valid(root):
		return
	if root.has_method("_show_gang_message"):
		root.call("_show_gang_message", message, is_success)

func _gang_mirror_network() -> GangNetwork:
	if gang_manager == null:
		return null
	return gang_manager.gang_network as GangNetwork

func _open_gang_mirror_popup_async(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	var gang_net: = _gang_mirror_network()
	if gang_net == null:
		var err_msg: = "帮派模块未就绪"
		ArenaUIClass.set_mirror_result(root, false, err_msg)
		_notify_gang_ui_message(root, err_msg, false)
		return
	var loading_data: = {
		"hasMirror": false, 
		"mirrorMode": "gang", 
		"mirrorTitle": "当前帮派镜像", 
	}
	ArenaUIClass.show_mirror_popup(self, root, loading_data)
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var res: Dictionary = await gang_net.fetch_gang_mirror_await()
	ArenaUIClass.set_mirror_popup_pending(root, false)
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("success", false)):
		var read_err: = str(res.get("error", "读取镜像失败"))
		ArenaUIClass.set_mirror_result(root, false, read_err)
		_notify_gang_ui_message(root, read_err, false)
		return
	if gang_manager:
		gang_manager.apply_gang_mirror_preview(res)
	res["mirrorMode"] = "gang"
	res["mirrorTitle"] = "当前帮派镜像"
	ArenaUIClass.refresh_mirror_popup(root, res)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func request_gang_mirror_update_from_ui(root: Control) -> void :
	_request_gang_mirror_update_async(root)

func _request_gang_mirror_update_async(root: Control) -> void :
	if _gang_mirror_update_busy:
		return
	if is_mirror_update_on_cooldown():
		var cd_msg: = _mirror_update_cooldown_message()
		ArenaUIClass.set_mirror_result(root, false, cd_msg)
		_notify_gang_ui_message(root, cd_msg, false)
		return
	var gang_net: = _gang_mirror_network()
	if gang_net == null:
		ArenaUIClass.set_mirror_result(root, false, "帮派模块未就绪")
		return
	_gang_mirror_update_busy = true
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var res: Dictionary = await gang_net.update_gang_mirror_await()
	_gang_mirror_update_busy = false
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("success", false)):
		var update_err: = str(res.get("error", "更新镜像失败"))
		ArenaUIClass.set_mirror_result(root, false, update_err)
		_notify_gang_ui_message(root, update_err, false)
		return
	if gang_manager:
		gang_manager.apply_gang_mirror_preview(res)
	mark_mirror_update_cooldown()
	res["mirrorMode"] = "gang"
	res["mirrorTitle"] = "当前帮派镜像"
	ArenaUIClass.set_mirror_result(root, true, "", res)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func is_shengsi_mirror_on_cooldown() -> bool:
	return Time.get_ticks_msec() < _shengsi_pin_cooldown_until_ms

func get_shengsi_mirror_cooldown_label() -> String:
	var remain_ms: = _shengsi_pin_cooldown_until_ms - Time.get_ticks_msec()
	if remain_ms <= 0:
		return ""
	var sec: = ceili(remain_ms / 1000.0)
	return "%d秒" % maxi(1, sec)

func _shengsi_pin_to_mirror_preview(summary: Dictionary) -> Dictionary:
	var out: Dictionary = summary.duplicate() if not summary.is_empty() else {}
	out["mirrorMode"] = "shengsi"
	out["mirrorTitle"] = "当前生死塔出战快照"
	out["hasMirror"] = bool(summary.get("hasPinned", false))
	if str(out.get("updatedAt", "")).is_empty():
		out["updatedAt"] = str(summary.get("pinnedAt", ""))
	if int(out.get("characterId", out.get("character_id", 0))) <= 0 and player:
		out["characterId"] = int(player.player_character_id)
	if str(out.get("playerRealm", "")).is_empty() and player:
		out["playerRealm"] = str(player.realm)
	if not out.has("playerReincarnation") and player:
		out["playerReincarnation"] = int(player.reincarnation)
	if str(out.get("petId", "")).is_empty() and pet_manager:
		var pet = pet_manager.get_active_pet()
		if pet:
			out["petId"] = str(pet.pet_id)
	return out

func open_shengsi_mirror_popup_from_ui(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	var loading_data: = {
		"hasMirror": false, 
		"mirrorMode": "shengsi", 
		"mirrorTitle": "当前生死塔出战快照", 
	}
	ArenaUIClass.show_mirror_popup(self, root, loading_data)
	var preview: Dictionary = {}
	if root.has_method("get_shengsi_mirror_preview"):
		preview = root.get_shengsi_mirror_preview()
	if preview.is_empty():
		preview = loading_data
	else:
		preview["mirrorMode"] = "shengsi"
		preview["mirrorTitle"] = "当前生死塔出战快照"
	ArenaUIClass.refresh_mirror_popup(root, preview)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func request_shengsi_mirror_update_from_ui(root: Control) -> void :
	_request_shengsi_mirror_update_async(root)

func _request_shengsi_mirror_update_async(root: Control) -> void :
	if _shengsi_mirror_update_busy:
		return
	if is_shengsi_mirror_on_cooldown():
		ArenaUIClass.set_mirror_result(root, false, "更新冷却中，请 %s 后再试" % get_shengsi_mirror_cooldown_label())
		return
	if player == null:
		ArenaUIClass.set_mirror_result(root, false, "人物数据未加载，请稍后再试")
		return
	if pet_manager == null or pet_manager.get_active_pet() == null:
		ArenaUIClass.set_mirror_result(root, false, "请先选择出战宠物后再更新快照")
		return
	if network == null or not network.has_method("shengsi_tower_pin_snapshot"):
		ArenaUIClass.set_mirror_result(root, false, "网络未就绪")
		return
	_shengsi_mirror_update_busy = true
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var snap: Dictionary = BrotherTowerManager.build_local_snapshot(self)
	var op: = "st_pin_%d" % Time.get_unix_time_from_system()
	var res: Dictionary = await _await_shengsi_pin_snapshot(snap, op)
	_shengsi_mirror_update_busy = false
	if root == null or not is_instance_valid(root):
		return
	if not bool(res.get("success", false)):
		ArenaUIClass.set_mirror_result(root, false, str(res.get("error", "更新镜像失败")))
		return
	_shengsi_pin_cooldown_until_ms = Time.get_ticks_msec() + SHENGSI_PIN_COOLDOWN_MS
	var data = res.get("data", {})
	var summary: Dictionary = {}
	if data is Dictionary:
		var raw_sum = data.get("summary", {})
		if raw_sum is Dictionary:
			summary = raw_sum
	var preview: = _shengsi_pin_to_mirror_preview(summary)
	if root.has_method("apply_shengsi_pinned_summary") and not summary.is_empty():
		root.apply_shengsi_pinned_summary(summary)
	ArenaUIClass.set_mirror_result(root, true, "", preview)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func _await_shengsi_pin_snapshot(snap: Dictionary, op: String) -> Dictionary:
	var box: = {"done": false, "out": {"success": false, "error": "更新失败"}}
	if network == null:
		return box["out"]
	var on_ok: = func(kind: String, data: Dictionary):
		if bool(box.get("done", false)) or kind != "pin_snapshot":
			return
		box["done"] = true
		box["out"] = {"success": true, "data": data if data else {}}
	var on_fail: = func(kind: String, err: String):
		if bool(box.get("done", false)) or kind != "pin_snapshot":
			return
		box["done"] = true
		box["out"] = {"success": false, "error": err}
	if not network.shengsi_tower_action_success.is_connected(on_ok):
		network.shengsi_tower_action_success.connect(on_ok)
	if not network.shengsi_tower_action_failed.is_connected(on_fail):
		network.shengsi_tower_action_failed.connect(on_fail)
	network.shengsi_tower_pin_snapshot(snap, op)
	var t0: = Time.get_ticks_msec()
	while not bool(box.get("done", false)) and Time.get_ticks_msec() - t0 < 12000:
		await get_tree().process_frame
	if network.shengsi_tower_action_success.is_connected(on_ok):
		network.shengsi_tower_action_success.disconnect(on_ok)
	if network.shengsi_tower_action_failed.is_connected(on_fail):
		network.shengsi_tower_action_failed.disconnect(on_fail)
	if not bool(box.get("done", false)):
		return {"success": false, "error": "更新超时，请稍后再试"}
	return box["out"]

func is_brother_tower_mirror_on_cooldown() -> bool:
	var bt_ui = _bt_ui()
	return bt_ui != null and bt_ui.has_method("is_mirror_on_cooldown") and bool(bt_ui.is_mirror_on_cooldown())

func get_brother_tower_mirror_cooldown_label() -> String:
	var bt_ui = _bt_ui()
	if bt_ui != null and bt_ui.has_method("get_mirror_cooldown_label"):
		return str(bt_ui.get_mirror_cooldown_label())
	return ""

func _brother_tower_pin_to_mirror_preview(summary: Dictionary) -> Dictionary:
	var bt_ui = _bt_ui()
	if bt_ui != null and bt_ui.has_method("apply_pinned_summary") and not summary.is_empty():
		bt_ui.apply_pinned_summary(summary)
	if bt_ui != null and bt_ui.has_method("get_mirror_preview"):
		var preview: Dictionary = bt_ui.get_mirror_preview(self)
		preview["mirrorMode"] = "brother_tower"
		preview["mirrorTitle"] = "当前兄弟天关出战快照"
		return preview
	var out: Dictionary = summary.duplicate() if not summary.is_empty() else {}
	out["mirrorMode"] = "brother_tower"
	out["mirrorTitle"] = "当前兄弟天关出战快照"
	out["hasMirror"] = bool(summary.get("hasPinned", false))
	if str(out.get("updatedAt", "")).is_empty():
		out["updatedAt"] = str(summary.get("pinnedAt", ""))
	return out

func open_brother_tower_mirror_popup_from_ui(root: Control) -> void :
	if root == null or not is_instance_valid(root):
		return
	var loading_data: = {
		"hasMirror": false, 
		"mirrorMode": "brother_tower", 
		"mirrorTitle": "当前兄弟天关出战快照", 
	}
	ArenaUIClass.show_mirror_popup(self, root, loading_data)
	var preview: Dictionary = loading_data.duplicate()
	var bt_ui = _bt_ui()
	if bt_ui != null and bt_ui.has_method("get_mirror_preview"):
		preview = bt_ui.get_mirror_preview(self)
	preview["mirrorMode"] = "brother_tower"
	preview["mirrorTitle"] = "当前兄弟天关出战快照"
	ArenaUIClass.refresh_mirror_popup(root, preview)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func request_brother_tower_mirror_update_from_ui(root: Control) -> void :
	_request_brother_tower_mirror_update_async(root)

func _request_brother_tower_mirror_update_async(root: Control) -> void :
	if _brother_tower_mirror_update_busy:
		return
	if is_brother_tower_mirror_on_cooldown():
		ArenaUIClass.set_mirror_result(root, false, "更新冷却中，请 %s 后再试" % get_brother_tower_mirror_cooldown_label())
		return
	if player == null:
		ArenaUIClass.set_mirror_result(root, false, "人物数据未加载，请稍后再试")
		return
	if pet_manager == null or pet_manager.get_active_pet() == null:
		ArenaUIClass.set_mirror_result(root, false, "请先选择出战宠物后再更新快照")
		return
	if network == null or not network.has_method("brother_tower_pin_snapshot"):
		ArenaUIClass.set_mirror_result(root, false, "网络未就绪")
		return
	_brother_tower_mirror_update_busy = true
	var bt_ui = _bt_ui()
	if bt_ui != null and bt_ui.has_method("set_mirror_update_pending"):
		bt_ui.set_mirror_update_pending(true)
	ArenaUIClass.set_mirror_popup_pending(root, true)
	var snap: Dictionary = BrotherTowerManager.build_local_snapshot(self)
	var op: = "bt_pin_%d" % Time.get_unix_time_from_system()
	var res: Dictionary = await _await_brother_tower_pin_snapshot(snap, op)
	_brother_tower_mirror_update_busy = false
	if not bool(res.get("success", false)):
		if bt_ui != null and bt_ui.has_method("set_mirror_update_pending"):
			bt_ui.set_mirror_update_pending(false)
		if root == null or not is_instance_valid(root):
			return
		ArenaUIClass.set_mirror_result(root, false, str(res.get("error", "更新镜像失败")))
		return
	if root == null or not is_instance_valid(root):
		return
	var data = res.get("data", {})
	var summary: Dictionary = {}
	if data is Dictionary:
		var raw_sum = data.get("summary", {})
		if raw_sum is Dictionary:
			summary = raw_sum
			if str(summary.get("pinnedAt", "")).is_empty():
				summary["pinnedAt"] = str(data.get("pinnedAt", ""))
	var preview: = _brother_tower_pin_to_mirror_preview(summary)
	ArenaUIClass.set_mirror_result(root, true, "", preview)
	ArenaUIClass.refresh_mirror_update_cooldown_ui(root, self)

func _await_brother_tower_pin_snapshot(snap: Dictionary, op: String) -> Dictionary:
	var box: = {"done": false, "out": {"success": false, "error": "更新失败"}}
	if network == null:
		return box["out"]
	var on_ok: = func(data: Dictionary):
		if bool(box.get("done", false)):
			return
		box["done"] = true
		box["out"] = {"success": true, "data": data if data else {}}
	var on_fail: = func(err: String):
		if bool(box.get("done", false)):
			return
		box["done"] = true
		box["out"] = {"success": false, "error": err}
	if not network.brother_tower_pin_snapshot_success.is_connected(on_ok):
		network.brother_tower_pin_snapshot_success.connect(on_ok)
	if not network.brother_tower_pin_snapshot_failed.is_connected(on_fail):
		network.brother_tower_pin_snapshot_failed.connect(on_fail)
	network.brother_tower_pin_snapshot(snap, op)
	var t0: = Time.get_ticks_msec()
	while not bool(box.get("done", false)) and Time.get_ticks_msec() - t0 < 12000:
		await get_tree().process_frame
	if network.brother_tower_pin_snapshot_success.is_connected(on_ok):
		network.brother_tower_pin_snapshot_success.disconnect(on_ok)
	if network.brother_tower_pin_snapshot_failed.is_connected(on_fail):
		network.brother_tower_pin_snapshot_failed.disconnect(on_fail)
	if not bool(box.get("done", false)):
		return {"success": false, "error": "更新超时，请稍后再试"}
	return box["out"]

func _on_gang_kick_battle_ready(data: Dictionary) -> void :
	start_gang_kick_battle(data)

func _on_gang_siege_battle_ready(data: Dictionary) -> void :
	start_gang_siege_battle(data)

func start_gang_kick_battle(battle_data: Dictionary) -> void :
	_start_gang_kick_battle_async(battle_data)

func start_gang_siege_battle(battle_data: Dictionary) -> void :
	_start_gang_siege_battle_async(battle_data)

func _resolve_gang_dialog_host() -> Control:
	if gang_manager:
		var host: Control = gang_manager.get_dialog_host()
		if host != null:
			return host
	var stack: Array = [get_tree().root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is GangHallUIClass:
			return node as Control
		for child in node.get_children():
			stack.append(child)
	if get_tree().current_scene is Control:
		return get_tree().current_scene as Control
	return null

func _show_gang_kick_auto_win_dialog(battle_data: Dictionary) -> void :
	var host: = _resolve_gang_dialog_host()
	if host == null:
		_finish_gang_kick_after_battle(battle_data)
		return
	ConfirmDialogClass.show_message(
		host, 
		"帮战进攻", 
		"对方帮派无人防守或防守槽已耗尽，直接获胜！", 
		"确定", 
		func():
			_finish_gang_kick_after_battle(battle_data)
	)

func _return_to_gang_kick_after_battle(_data: Dictionary) -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui == null or not main_ui.has_method("_show_city_ui_with_gang_hall"):
		return
	await main_ui.call("_show_city_ui_with_gang_hall", true, true)

func _finish_gang_kick_after_battle(battle_data: Dictionary) -> void :
	_finish_gang_kick_after_battle_async(battle_data)

func _finish_gang_kick_after_battle_async(battle_data: Dictionary) -> void :
	await _return_to_gang_kick_after_battle(battle_data)
	if gang_manager:
		gang_manager.notify_kick_attack_result(battle_data)

func _start_gang_kick_battle_async(battle_data: Dictionary) -> void :
	if bool(battle_data.get("autoWin", battle_data.get("auto_win", false))):
		_show_gang_kick_auto_win_dialog(battle_data)
		return
	var block_msg: = get_instanced_challenge_block_message("arena")
	if not block_msg.is_empty():
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		push_warning(block_msg)
		return
	if network == null or network.auth_token == "":
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		return
	_gang_kick_battle_result = battle_data.duplicate(true)
	await prepare_for_instanced_challenge_async()
	var battle_log: Array = []
	var raw_log: Variant = battle_data.get("battleLog", battle_data.get("battle_log", []))
	if raw_log is Array:
		battle_log = raw_log
	var server_victory: = bool(battle_data.get("won", false))
	var opponent_name: = str(battle_data.get("defenderName", battle_data.get("defender_name", "防守成员")))
	var defender_snapshot: Dictionary = battle_data.get("defenderSnapshot", battle_data.get("defender_snapshot", {}))
	var attacker_snapshot: Dictionary = battle_data.get("attackerSnapshot", battle_data.get("attacker_snapshot", {}))
	if attacker_snapshot.is_empty():
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		_restore_after_gang_kick_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	var battle_player: = _build_arena_battle_player_from_snapshot(attacker_snapshot)
	if battle_player == null:
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		_restore_after_gang_kick_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	var battle_pet: = _build_arena_battle_pet_from_snapshot(attacker_snapshot)
	var monsters: = _build_arena_opponent_monsters(defender_snapshot, {}, opponent_name, battle_log)
	if monsters.is_empty():
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		_restore_after_gang_kick_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	is_arena_battle = true
	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = false
	last_battle_was_arena = false
	last_battle_was_gang_kick = true
	_disconnect_all_battle_ended_handlers()
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	battle_system.suppress_battle_character_exp = true
	if not battle_system.start_battle(battle_player, battle_pet, monsters, 20, false, resolve_attack_target_mode("arena")):
		is_arena_battle = false
		last_battle_was_gang_kick = false
		if gang_manager:
			gang_manager.notify_kick_attack_result(battle_data)
		_restore_after_gang_kick_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	in_battle = true
	arena_battle_started.emit(opponent_name)
	_switch_to_battle_view_for_arena(opponent_name)
	await _replay_arena_battle_log(battle_log, server_victory)
	_on_gang_kick_battle_ended(server_victory)

func _restore_after_gang_kick_without_field_resume() -> void :
	battle_system.replay_log_only = false
	battle_system.suppress_battle_character_exp = false
	_clear_battle_start_block_for_field_resume()

func _hide_replay_skip_button() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_cancel_replay_skip_wait"):
		main_ui.call("_cancel_replay_skip_wait")

func _on_gang_kick_battle_ended(server_victory: bool) -> void :
	_hide_replay_skip_button()
	is_arena_battle = false
	in_battle = false
	_cleanup_arena_battle_hooks()
	battle_system.max_rounds = -1
	_restore_after_gang_kick_without_field_resume()
	var result: = _gang_kick_battle_result.duplicate(true)
	_gang_kick_battle_result = {}
	if not result.is_empty():
		await _return_to_gang_kick_after_battle(result)
		if gang_manager:
			gang_manager.notify_kick_attack_result(result)
	battle_ended_ui.emit(server_victory)
	last_battle_was_gang_kick = false

	resume_field_auto_battle_after_instanced_challenge(false)

func _start_gang_siege_battle_async(battle_data: Dictionary) -> void :
	if bool(battle_data.get("autoWin", battle_data.get("auto_win", false))):
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(battle_data)
		return
	var block_msg: = get_instanced_challenge_block_message("arena")
	if not block_msg.is_empty():
		push_warning(block_msg)
		return
	if network == null or network.auth_token == "":
		return
	_gang_siege_battle_result = battle_data.duplicate(true)
	await prepare_for_instanced_challenge_async()
	var battle_log: Array = []
	var raw_log: Variant = battle_data.get("battleLog", battle_data.get("battle_log", []))
	if raw_log is Array:
		battle_log = raw_log
	var server_victory: = bool(battle_data.get("won", false))
	var opponent_name: = str(battle_data.get("defenderName", battle_data.get("defender_name", "防守成员")))
	var defender_snapshot: Dictionary = battle_data.get("defenderSnapshot", battle_data.get("defender_snapshot", {}))
	var attacker_snapshot: Dictionary = battle_data.get("attackerSnapshot", battle_data.get("attacker_snapshot", {}))
	if attacker_snapshot.is_empty() or battle_log.is_empty():
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(battle_data)
		_restore_after_gang_siege_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	var battle_player: = _build_arena_battle_player_from_snapshot(attacker_snapshot)
	if battle_player == null:
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(battle_data)
		_restore_after_gang_siege_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	var battle_pet: = _build_arena_battle_pet_from_snapshot(attacker_snapshot)
	var monsters: = _build_arena_opponent_monsters(defender_snapshot, {}, opponent_name, battle_log)
	if monsters.is_empty():
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(battle_data)
		_restore_after_gang_siege_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	is_arena_battle = true
	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = false
	last_battle_was_arena = false
	last_battle_was_gang_kick = false
	last_battle_was_gang_siege = true
	_disconnect_all_battle_ended_handlers()
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	battle_system.suppress_battle_character_exp = true
	if not battle_system.start_battle(battle_player, battle_pet, monsters, 20, false, resolve_attack_target_mode("arena")):
		is_arena_battle = false
		last_battle_was_gang_siege = false
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(battle_data)
		_restore_after_gang_siege_without_field_resume()
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	in_battle = true
	arena_battle_started.emit(opponent_name)
	_switch_to_battle_view_for_arena(opponent_name)
	await _replay_arena_battle_log(battle_log, server_victory)
	_on_gang_siege_battle_ended(server_victory)

func _resolve_siege_territory_id_from_battle(_data: Dictionary) -> String:
	if gang_manager == null:
		return ""
	return gang_manager.get_territory_id_for_siege_round()

func _return_to_gang_siege_after_battle(_data: Dictionary) -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui == null or not main_ui.has_method("_show_city_ui_with_gang_siege"):
		return

	await main_ui.call("_show_city_ui_with_gang_siege", true, "")

func _restore_after_gang_siege_without_field_resume() -> void :
	if battle_system:
		battle_system.replay_log_only = false
		battle_system.suppress_battle_character_exp = false
	_clear_battle_start_block_for_field_resume()

func _on_gang_siege_battle_ended(server_victory: bool) -> void :
	_hide_replay_skip_button()
	is_arena_battle = false
	in_battle = false
	_cleanup_arena_battle_hooks()
	battle_system.max_rounds = -1
	_restore_after_gang_siege_without_field_resume()
	var result: = _gang_siege_battle_result.duplicate(true)
	_gang_siege_battle_result = {}
	if not result.is_empty():
		await _return_to_gang_siege_after_battle(result)
		if gang_manager:
			gang_manager.notify_siege_battle_replay_finished(result)
	battle_ended_ui.emit(server_victory)
	last_battle_was_gang_siege = false

	resume_field_auto_battle_after_instanced_challenge(false)

func start_arena_battle(battle_data: Dictionary) -> void :
	_start_arena_battle_async(battle_data)

func start_shengsi_tower_replay(battle_data: Dictionary) -> void :
	_start_shengsi_tower_replay_async(battle_data)

func abort_shengsi_tower_replay() -> void :
	if not is_shengsi_tower_replay:
		return
	_shengsi_replay_abort = true
	in_battle = false

func _character_id_from_unit_snap(snap: Dictionary) -> int:
	if snap.is_empty():
		return 0
	var p = snap.get("player")
	if p is Dictionary:
		return int(p.get("player_character_id", p.get("playerCharacterId", 0)))
	return int(snap.get("player_character_id", snap.get("playerCharacterId", 0)))

func _shengsi_names_from_snap(snap: Dictionary) -> PackedStringArray:
	var names: PackedStringArray = []
	if snap.is_empty():
		return names
	var p = snap.get("player")
	if p is Dictionary:
		var n: = str(p.get("name", snap.get("nickname", ""))).strip_edges()
		if not n.is_empty():
			names.append(n)
	var pet = snap.get("pet")
	if pet is Dictionary:
		var pn: = str(pet.get("name", pet.get("pet_name", ""))).strip_edges()
		if not pn.is_empty():
			names.append(pn)
	return names

func _shengsi_unit_id(side: String, role: String, kind: String) -> String:
	return "%s_%s_%s" % [side, role, kind]

func _build_shengsi_unit_id_map(viewer_side: String, viewer_role: String, _enemy_side: String, monsters: Array) -> Dictionary:
	var m: Dictionary = {}
	m[_shengsi_unit_id(viewer_side, viewer_role, "player")] = {"type": "player", "index": -1}
	m[_shengsi_unit_id(viewer_side, viewer_role, "pet")] = {"type": "pet", "index": -1}
	var partner_role: = "member" if viewer_role == "leader" else "leader"
	if battle_system:
		for i in range(battle_system.coop_units.size()):
			var cu = battle_system.coop_units[i]
			if cu == null:
				continue
			var ut: = str(cu.unit_type)
			if ut == "coop_player":
				m[_shengsi_unit_id(viewer_side, partner_role, "player")] = {"type": "coop_player", "index": i}
			elif ut == "coop_pet":
				m[_shengsi_unit_id(viewer_side, partner_role, "pet")] = {"type": "coop_pet", "index": i}
	for i in range(monsters.size()):
		var mon = monsters[i]
		if not (mon is Dictionary):
			continue
		var rid: = str(mon.get("replay_unit_id", "")).strip_edges()
		if not rid.is_empty():
			m[rid] = {"type": "monster", "index": i}
	return m

func _apply_shengsi_unit_info_to_monsters(monsters: Array, battle_log: Array) -> void :
	for raw in battle_log:
		if not (raw is Dictionary):
			continue
		if str(raw.get("type", "")) != "unit_info":
			continue
		var id: = str(raw.get("id", "")).strip_edges()
		if id.is_empty():
			continue
		for mon in monsters:
			if not (mon is Dictionary):
				continue
			if str(mon.get("replay_unit_id", "")) != id:
				continue
			var atk: = int(raw.get("attack", 0))
			var df: = int(raw.get("defense", 0))
			var agi: = int(raw.get("agility", 0))
			var hp: = int(raw.get("maxHp", raw.get("hp", 0)))
			if atk > 0:
				mon["attack"] = atk
			if df > 0:
				mon["defense"] = df
			if agi > 0:
				mon["agility"] = agi
			if hp > 0:
				mon["hp"] = hp
				mon["max_hp"] = hp

func _apply_shengsi_unit_info_from_log(battle_log: Array, unit_map: Dictionary) -> void :
	if battle_system == null:
		return
	for raw in battle_log:
		if not (raw is Dictionary):
			continue
		if str(raw.get("type", "")) != "unit_info":
			continue
		var id: = str(raw.get("id", "")).strip_edges()
		var slot = unit_map.get(id, {})
		if not (slot is Dictionary) or (slot as Dictionary).is_empty():
			continue
		var hp: = int(raw.get("maxHp", raw.get("hp", -1)))
		if hp > 0:
			battle_system.set_replay_unit_hp(str(slot.get("type", "")), int(slot.get("index", -1)), hp)

func _shengsi_name_is_mine(unit_name: String, mine: PackedStringArray) -> bool:
	var n: = unit_name.strip_edges()
	if n.is_empty():
		return false
	for x in mine:
		if n == x or n.ends_with(x) or x.ends_with(n):
			return true
	return false

func _normalize_shengsi_replay_log(raw: Array, mine_names: PackedStringArray) -> Array:
	var out: Array = []
	for e in raw:
		if not (e is Dictionary):
			continue
		var n: Dictionary = e.duplicate(true)
		var t: = str(n.get("type", ""))
		if t == "round_start":
			n["type"] = "round"
			n["round"] = int(n.get("round", 0))
		elif t == "battle_start":
			n["type"] = "info"
			n["message"] = str(n.get("text", "生死塔对决开始"))
		elif t == "attack":
			n["attacker"] = str(n.get("attackerName", n.get("attacker", "")))
			n["target"] = str(n.get("targetName", n.get("target", "")))
			n["isEnemyAttack"] = not _shengsi_name_is_mine(str(n.get("attacker", "")), mine_names)
		elif t == "defeat":
			var nm: = str(n.get("targetName", n.get("name", "")))
			n["name"] = nm
			n["type"] = "player_dead" if _shengsi_name_is_mine(nm, mine_names) else "enemy_dead"
		elif t == "battle_end":
			n["type"] = "info"
			n["message"] = str(n.get("text", "对决结束"))
		out.append(n)
	return out

func _start_shengsi_tower_replay_async(battle_data: Dictionary) -> void :
	var block_msg: = get_instanced_challenge_block_message("arena")
	if not block_msg.is_empty():
		push_warning(block_msg)
		return
	await prepare_for_instanced_challenge_async()
	_shengsi_last_replay = battle_data.duplicate(true)
	is_shengsi_replay_result_open = false
	var raw_log: Variant = battle_data.get("battleLog", battle_data.get("battle_log", []))
	var battle_log: Array = raw_log if raw_log is Array else []
	var my_snap: Dictionary = battle_data.get("mySnapshot", {}) if battle_data.get("mySnapshot") is Dictionary else {}
	var battle_player: = _build_arena_battle_player_from_snapshot(my_snap)
	if battle_player == null:
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	var battle_pet: = _build_arena_battle_pet_from_snapshot(my_snap)
	var opponent_name: = str(battle_data.get("opponentName", "对手"))
	var viewer_side: = str(battle_data.get("viewerSide", "A")).strip_edges()
	if viewer_side != "A" and viewer_side != "B":
		viewer_side = "A"
	var viewer_role: = str(battle_data.get("viewerRole", "leader")).strip_edges()
	if viewer_role != "member":
		viewer_role = "leader"
	var enemy_side: = "B" if viewer_side == "A" else "A"
	var monsters: Array = []
	var el = battle_data.get("enemyLeader")
	var em = battle_data.get("enemyMember")
	if el is Dictionary and not el.is_empty():
		monsters.append_array(_build_arena_opponent_monsters(el, {"characterId": _character_id_from_unit_snap(el)}, str(el.get("nickname", "对手")), [], "%s_leader_pet" % enemy_side, "%s_leader_player" % enemy_side))
	if em is Dictionary and not em.is_empty():
		monsters.append_array(_build_arena_opponent_monsters(em, {"characterId": _character_id_from_unit_snap(em)}, str(em.get("nickname", "对手")), [], "%s_member_pet" % enemy_side, "%s_member_player" % enemy_side))
	if monsters.is_empty():
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	_apply_shengsi_unit_info_to_monsters(monsters, battle_log)
	var partner_snap: Dictionary = battle_data.get("allyPartner", {}) if battle_data.get("allyPartner") is Dictionary else {}
	var coop_units: Array = []
	if not partner_snap.is_empty():
		coop_units = CoopBattleUnit.build_from_session_snapshot(partner_snap)
	if battle_system.has_method("set_coop_units"):
		battle_system.set_coop_units(coop_units)
	else:
		battle_system.coop_units = coop_units
	var mine_names: = _shengsi_names_from_snap(my_snap)
	for extra in _shengsi_names_from_snap(partner_snap):
		mine_names.append(extra)
	arena_battle_character_id = _character_id_from_unit_snap(my_snap)
	_shengsi_replay_abort = false
	is_shengsi_tower_replay = true
	is_arena_battle = true
	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = false
	last_battle_was_arena = false
	_disconnect_all_battle_ended_handlers()
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	battle_system.suppress_battle_character_exp = true
	if not battle_system.start_battle(battle_player, battle_pet, monsters, 20, false, resolve_attack_target_mode("arena")):
		is_shengsi_tower_replay = false
		is_arena_battle = false
		arena_battle_character_id = 0
		if battle_system.has_method("clear_coop_units"):
			battle_system.clear_coop_units()
		battle_system.replay_log_only = false
		battle_system.suppress_battle_character_exp = false
		resume_field_auto_battle_after_instanced_challenge(false)
		return
	in_battle = true
	var server_victory: = bool(battle_data.get("victory", false))
	arena_battle_started.emit(opponent_name)
	_switch_to_battle_view_for_arena(opponent_name)
	var replay: = CombatReplayPlayerClass.new()
	replay.battle_system = battle_system
	replay.mine_names = mine_names
	replay.viewer_side = viewer_side
	replay.unit_id_map = _build_shengsi_unit_id_map(viewer_side, viewer_role, enemy_side, monsters)
	_apply_shengsi_unit_info_from_log(battle_log, replay.unit_id_map)
	replay.should_abort = func() -> bool:
		return _shengsi_replay_abort or not is_arena_battle or not in_battle
	replay.on_hud_refresh = func() -> void :
		call_deferred("_refresh_arena_battle_hud")
	await replay.play_async(self, battle_log, server_victory)
	_on_shengsi_tower_replay_ended(server_victory)

func _on_shengsi_tower_replay_ended(server_victory: bool) -> void :
	if not is_shengsi_tower_replay and not is_arena_battle and not is_shengsi_replay_result_open:
		return
	_shengsi_replay_abort = false
	is_shengsi_tower_replay = false
	is_arena_battle = false
	in_battle = false
	if battle_system and battle_system.has_method("clear_coop_units"):
		battle_system.clear_coop_units()
	_cleanup_arena_battle_hooks()
	battle_system.max_rounds = -1
	arena_battle_character_id = 0
	is_shengsi_replay_result_open = true
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_clear_brother_tower_coop_battle_ui"):
		main_ui.call("_clear_brother_tower_coop_battle_ui")
	if main_ui and main_ui.has_method("_refresh_shengsi_end_replay_button"):
		main_ui.call("_refresh_shengsi_end_replay_button")
	if main_ui and main_ui.has_method("_show_shengsi_replay_result"):
		main_ui.call("_show_shengsi_replay_result", _shengsi_replay_result_summary(server_victory))
		return
	finish_shengsi_replay_result()

func _shengsi_nick_from_snap(snap, fallback: String) -> String:
	if snap is Dictionary:
		var p = snap.get("player")
		if p is Dictionary:
			var n: = str(p.get("name", "")).strip_edges()
			if not n.is_empty():
				return n
		var nick: = str(snap.get("nickname", "")).strip_edges()
		if not nick.is_empty():
			return nick
	return fallback

func _shengsi_replay_result_summary(victory: bool) -> Dictionary:
	var d: Dictionary = _shengsi_last_replay
	var ally: = str(d.get("allyName", "")).strip_edges()
	if ally.is_empty() or ally == "/":
		ally = "%s / %s" % [
			_shengsi_nick_from_snap(d.get("allyLeader"), "己方"), 
			_shengsi_nick_from_snap(d.get("allyMember"), ""), 
		]
	var enemy: = str(d.get("opponentName", "")).strip_edges()
	if enemy.is_empty() or enemy == "/":
		enemy = "%s / %s" % [
			_shengsi_nick_from_snap(d.get("enemyLeader"), "对手"), 
			_shengsi_nick_from_snap(d.get("enemyMember"), ""), 
		]
	return {
		"victory": victory, 
		"allyName": ally.replace("/", " / "), 
		"enemyName": enemy.replace("/", " / "), 
		"round": int(d.get("round", 0)), 
		"canReplay": d.get("battleLog") is Array and not (d.get("battleLog") as Array).is_empty(), 
	}

func finish_shengsi_replay_result() -> void :
	is_shengsi_replay_result_open = false
	is_shengsi_tower_replay = false
	is_arena_battle = false
	in_battle = false
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_hide_shengsi_replay_result"):
		main_ui.call("_hide_shengsi_replay_result")
	resume_field_auto_battle_after_instanced_challenge(false)
	call_deferred("_reopen_shengsi_tower_ui")

func replay_shengsi_last_battle() -> void :
	is_shengsi_replay_result_open = false
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_hide_shengsi_replay_result"):
		main_ui.call("_hide_shengsi_replay_result")
	if _shengsi_last_replay.is_empty():
		finish_shengsi_replay_result()
		return
	start_shengsi_tower_replay(_shengsi_last_replay)

func _reopen_shengsi_tower_ui() -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui == null:
		return
	if main_ui.has_method("_show_view"):
		main_ui.call("_show_view", "city")
	var city = main_ui.get("_current_city_ui")
	if city and is_instance_valid(city) and city.has_method("_on_shengsi_tower_btn_pressed"):
		city.call_deferred("_on_shengsi_tower_btn_pressed")

func _snapshot_stat_positive(d: Dictionary, key: String) -> int:
	if d.is_empty() or key.is_empty() or not d.has(key):
		return 0
	var v = d.get(key)
	var n: = 0
	match typeof(v):
		TYPE_INT:
			n = int(v)
		TYPE_FLOAT:
			n = int(round(float(v)))
		TYPE_STRING:
			n = int(str(v).strip_edges())
		_:
			n = int(v)
	return n if n > 0 else 0

func _snapshot_combat_stat_int(d: Dictionary, final_key: String, base_key: String, fallback: int) -> int:
	var fv: = _snapshot_stat_positive(d, final_key)
	if fv > 0:
		return fv
	if final_key == "final_attack":
		fv = _snapshot_stat_positive(d, "finalAttack")
		if fv > 0:
			return fv
	elif final_key == "final_defense":
		fv = _snapshot_stat_positive(d, "finalDefense")
		if fv > 0:
			return fv
	elif final_key == "final_agility":
		fv = _snapshot_stat_positive(d, "finalAgility")
		if fv > 0:
			return fv
	elif final_key == "final_max_hp":
		fv = _snapshot_stat_positive(d, "finalMaxHp")
		if fv > 0:
			return fv
	var bv: = _snapshot_stat_positive(d, base_key)
	if bv > 0:
		return bv
	return fallback

func _apply_arena_snapshot_stats_to_player(p: Player, pdata: Dictionary) -> void :
	BrotherTowerManager._apply_bt_snapshot_stats_to_player(p, pdata)

func _build_arena_battle_player_from_snapshot(snapshot: Dictionary) -> Player:
	if snapshot.is_empty():
		return null
	var player_raw = snapshot.get("player")
	if not player_raw is Dictionary or player_raw.is_empty():
		return null
	var pdata: Dictionary = player_raw.duplicate(true)
	var battle_player: = Player.new()
	battle_player.from_dict(pdata)
	_apply_arena_snapshot_stats_to_player(battle_player, pdata)
	var raw_name: = str(pdata.get("name", battle_player.player_name)).strip_edges()
	raw_name = raw_name.replace("我方·", "")
	if raw_name.is_empty():
		raw_name = "你"
	battle_player.player_name = "我方·%s" % raw_name
	battle_player.level = int(pdata.get("level", battle_player.level))
	var snap_max_hp: = _snapshot_combat_stat_int(pdata, "final_max_hp", "max_hp", int(pdata.get("hp", battle_player.get_max_hp())))
	battle_player.max_hp = snap_max_hp
	battle_player.hp = mini(int(pdata.get("hp", snap_max_hp)), snap_max_hp)
	if pdata.has("mp"):
		battle_player.mp = int(pdata.get("mp", battle_player.mp))
	if pdata.has("max_mp"):
		battle_player.max_mp = int(pdata.get("max_mp", battle_player.get_max_mp()))
	if pdata.has("element"):
		battle_player.element = str(pdata.get("element", battle_player.element))
	return battle_player

func _build_arena_battle_pet_from_snapshot(snapshot: Dictionary) -> Pet:
	if snapshot.is_empty():
		return null
	var pet_raw = snapshot.get("pet")
	if not pet_raw is Dictionary or pet_raw.is_empty():
		return null
	var pdata: Dictionary = pet_raw.duplicate(true)
	var raw_name: = str(pdata.get("name", pdata.get("pet_name", ""))).strip_edges()
	raw_name = raw_name.replace("敌方灵兽·", "").replace("我方灵兽·", "")
	if raw_name.is_empty():
		raw_name = "灵兽"
	pdata["name"] = raw_name
	pdata["pet_name"] = raw_name
	var battle_pet: = Pet.new()
	battle_pet.from_dict(pdata)
	battle_pet.pet_name = "我方灵兽·%s" % raw_name
	battle_pet.level = int(pdata.get("level", battle_pet.level))
	BrotherTowerManager._apply_bt_snapshot_stats_to_pet(battle_pet, pdata, snapshot)
	if battle_pet.hp > battle_pet.max_hp:
		battle_pet.hp = battle_pet.max_hp
	return battle_pet

func _start_arena_battle_async(battle_data: Dictionary) -> void :
	var block_msg: = get_instanced_challenge_block_message("arena")
	if not block_msg.is_empty():
		push_warning(block_msg)
		return
	if network == null or network.auth_token == "":
		return
	await prepare_for_instanced_challenge_async()
	arena_battle_token = str(battle_data.get("battleToken", battle_data.get("battle_token", "")))
	var battle_log: Array = []
	var raw_log: Variant = battle_data.get("battleLog", battle_data.get("battle_log", []))
	if raw_log is Array:
		battle_log = raw_log
	var server_victory: = bool(battle_data.get("victory", false))
	arena_battle_max_rounds = int(battle_data.get("battleMaxRounds", battle_data.get("battle_max_rounds", 20)))
	var opponent_name: = str(battle_data.get("opponentName", battle_data.get("opponent_name", "对手")))
	var match_data: Dictionary = battle_data.get("match", {}) if battle_data.get("match") is Dictionary else {}
	var opp_info: Dictionary = match_data.get("opponent", {}) if match_data.get("opponent") is Dictionary else {}
	var defender_snapshot: Dictionary = battle_data.get("defenderSnapshot", battle_data.get("defender_snapshot", {}))
	if defender_snapshot.is_empty() and battle_data.get("defender") is Dictionary:
		defender_snapshot = battle_data.get("defender")
	var attacker_snapshot: Dictionary = battle_data.get("attackerSnapshot", battle_data.get("attacker_snapshot", {}))
	if attacker_snapshot.is_empty():
		push_warning("竞技场：缺少攻击方镜像数据")
		resume_field_auto_battle_after_instanced_challenge()
		return
	var battle_player: = _build_arena_battle_player_from_snapshot(attacker_snapshot)
	if battle_player == null:
		push_error("竞技场：攻击方镜像人物无效")
		resume_field_auto_battle_after_instanced_challenge()
		return
	var battle_pet: = _build_arena_battle_pet_from_snapshot(attacker_snapshot)
	var self_info: Dictionary = match_data.get("self", {}) if match_data.get("self") is Dictionary else {}
	arena_battle_character_id = int(
		battle_data.get("attackerCharacterId", battle_data.get("attacker_character_id", 
		self_info.get("characterId", self_info.get("character_id", 0))))
	)
	var monsters: = _build_arena_opponent_monsters(defender_snapshot, opp_info, opponent_name, battle_log)
	if monsters.is_empty():
		resume_field_auto_battle_after_instanced_challenge()
		return
	is_arena_battle = true
	is_world_boss_battle = false
	last_battle_was_tower = false
	last_battle_was_suit_dungeon = false
	last_battle_was_world_boss = false
	last_battle_was_arena = true
	_disconnect_all_battle_ended_handlers()
	battle_system.drive_by_execute_turn = false
	battle_system.replay_log_only = true
	battle_system.suppress_battle_character_exp = true
	if not battle_system.start_battle(battle_player, battle_pet, monsters, arena_battle_max_rounds, false, resolve_attack_target_mode("arena")):
		is_arena_battle = false
		last_battle_was_arena = false
		arena_battle_character_id = 0
		battle_system.replay_log_only = false
		battle_system.suppress_battle_character_exp = false
		resume_field_auto_battle_after_instanced_challenge()
		return
	in_battle = true
	arena_battle_started.emit(opponent_name)
	_switch_to_battle_view_for_arena(opponent_name)
	await _replay_arena_battle_log(battle_log, server_victory)
	_on_arena_battle_ended(server_victory)

func _find_arena_log_entry(battle_log: Array, entry_type: String) -> Dictionary:
	for entry in battle_log:
		if entry is Dictionary and str(entry.get("type", "")) == entry_type:
			return entry
	return {}

func _resolve_pet_id_by_display_name(pet_display_name: String) -> String:
	var target: = pet_display_name.strip_edges()
	if target.is_empty():
		return ""
	for pet_id in GameData.PET_DATA:
		var pet_data = GameData.PET_DATA[pet_id]
		if str(pet_data.get("name", "")) == target:
			return str(pet_id)
	return ""

func _apply_arena_log_stats(base: Dictionary, log_entry: Dictionary) -> Dictionary:
	if log_entry.is_empty():
		return base
	var out: = base.duplicate(true)
	out["hp"] = int(log_entry.get("hp", log_entry.get("maxHp", log_entry.get("max_hp", out.get("hp", 1000)))))
	out["max_hp"] = int(log_entry.get("maxHp", log_entry.get("max_hp", log_entry.get("hp", out.get("max_hp", 1000)))))
	out["attack"] = int(log_entry.get("attack", out.get("attack", 50)))
	out["defense"] = int(log_entry.get("defense", out.get("defense", 30)))
	out["agility"] = int(log_entry.get("agility", out.get("agility", 20)))
	out["element"] = str(log_entry.get("element", out.get("element", "金")))
	if log_entry.has("level"):
		out["level"] = int(log_entry.get("level", out.get("level", 1)))
	var log_name: = str(log_entry.get("name", "")).strip_edges()
	if not log_name.is_empty():
		out["name"] = log_name
		out["monster_name"] = log_name
	return out

func _build_arena_opponent_monsters(defender_snapshot: Dictionary, opp_info: Dictionary, opponent_name: String, battle_log: Array = [], pet_replay_id: String = "", player_replay_id: String = "") -> Array:
	var snap: Dictionary = defender_snapshot if defender_snapshot is Dictionary else {}
	var opp_player: Dictionary = snap.get("player", {}) if snap.get("player") is Dictionary else {}
	var opp_pet: Dictionary = snap.get("pet", {}) if snap.get("pet") is Dictionary else {}
	var display_name: = opponent_name.strip_edges()
	if display_name.is_empty():
		display_name = str(opp_info.get("playerName", opp_info.get("player_name", "对手"))).strip_edges()
	var character_id: = int(opp_info.get("characterId", opp_info.get("character_id", 0)))
	if character_id <= 0 and not opp_player.is_empty():
		character_id = int(opp_player.get("player_character_id", opp_player.get("playerCharacterId", 0)))
	var player_log: = _find_arena_log_entry(battle_log, "enemy_info")
	var pet_log: = _find_arena_log_entry(battle_log, "enemy_pet_info")

	var player_name: = display_name
	if not player_log.is_empty():
		player_name = str(player_log.get("name", display_name))
	elif not opp_player.is_empty():
		player_name = str(opp_player.get("name", display_name)).replace("我方·", "")
	if player_name.is_empty():
		player_name = "对手"

	var atk_fb: = 0 if not player_replay_id.is_empty() else 50
	var def_fb: = 0 if not player_replay_id.is_empty() else 30
	var agi_fb: = 0 if not player_replay_id.is_empty() else 20
	var hp_fb: = int(opp_player.get("hp", 0))
	if hp_fb <= 0:
		hp_fb = 0 if not player_replay_id.is_empty() else 1000
	var player_monster: = {
		"name": player_name, 
		"monster_name": player_name, 
		"level": int(opp_player.get("level", 1)), 
		"hp": _snapshot_combat_stat_int(opp_player, "final_max_hp", "max_hp", hp_fb), 
		"max_hp": _snapshot_combat_stat_int(opp_player, "final_max_hp", "max_hp", hp_fb), 
		"attack": _snapshot_combat_stat_int(opp_player, "final_attack", "attack", atk_fb), 
		"defense": _snapshot_combat_stat_int(opp_player, "final_defense", "defense", def_fb), 
		"agility": _snapshot_combat_stat_int(opp_player, "final_agility", "agility", agi_fb), 
		"element": str(opp_player.get("element", "金")), 
		"texture_id": "player_mirror", 
		"character_id": character_id, 
		"arena_role": "player", 
	}
	if not player_replay_id.is_empty():
		player_monster["replay_unit_id"] = player_replay_id
	player_monster = _apply_arena_log_stats(player_monster, player_log)

	var monsters: Array = []
	var pet_monster: Dictionary = {}
	if not pet_log.is_empty() or not str(opp_pet.get("name", "")).is_empty():
		var pet_display: = ""
		if not pet_log.is_empty():
			pet_display = str(pet_log.get("name", ""))
		elif not str(opp_pet.get("name", "")).is_empty():
			pet_display = "敌方灵兽·%s" % str(opp_pet.get("name", "灵兽"))
		var pet_base_name: = pet_display
		if pet_base_name.begins_with("敌方灵兽·"):
			pet_base_name = pet_base_name.substr("敌方灵兽·".length())
		var pet_id: = str(opp_pet.get("pet_id", opp_pet.get("petId", ""))).strip_edges()
		if pet_id.is_empty() and not pet_base_name.is_empty():
			pet_id = _resolve_pet_id_by_display_name(pet_base_name)
		if pet_display.is_empty() and not pet_base_name.is_empty():
			pet_display = "敌方灵兽·%s" % pet_base_name
		pet_monster = {
			"name": pet_display if not pet_display.is_empty() else "敌方灵兽", 
			"monster_name": pet_display if not pet_display.is_empty() else "敌方灵兽", 
			"level": int(opp_pet.get("level", 1)), 
			"hp": _snapshot_combat_stat_int(opp_pet, "final_max_hp", "max_hp", int(opp_pet.get("hp", 500))), 
			"max_hp": _snapshot_combat_stat_int(opp_pet, "final_max_hp", "max_hp", int(opp_pet.get("hp", 500))), 
			"attack": _snapshot_combat_stat_int(opp_pet, "final_attack", "attack", 30), 
			"defense": _snapshot_combat_stat_int(opp_pet, "final_defense", "defense", 20), 
			"agility": _snapshot_combat_stat_int(opp_pet, "final_agility", "agility", 15), 
			"element": str(opp_pet.get("element", "金")), 
			"texture_id": "pet_mirror", 
			"pet_id": pet_id, 
			"arena_role": "pet", 
		}
		if not pet_replay_id.is_empty():
			pet_monster["replay_unit_id"] = pet_replay_id
		pet_monster = _apply_arena_log_stats(pet_monster, pet_log)

	if not pet_monster.is_empty():
		monsters.append(pet_monster)
	monsters.append(player_monster)
	return monsters

func request_skip_server_replay() -> bool:
	if is_shengsi_tower_replay or is_shengsi_replay_result_open:
		return false
	if not is_arena_battle or not in_battle:
		return false
	if not (last_battle_was_arena or last_battle_was_gang_kick or last_battle_was_gang_siege):
		return false
	_replay_log_skip = true
	return true

func _replay_arena_battle_log(battle_log: Array, server_victory: bool) -> void :
	if battle_system == null:
		return
	_replay_log_skip = false
	for entry in battle_log:
		if _replay_log_should_stop():
			break
		if entry is Dictionary:
			_apply_arena_log_entry(entry)
			await _await_replay_step(_arena_replay_step_delay(str(entry.get("type", ""))))
		else:
			await _await_replay_step(0.12)
	battle_system.apply_replay_battle_state(server_victory)
	call_deferred("_refresh_arena_battle_hud")

func _replay_log_should_stop() -> bool:
	return _shengsi_replay_abort or _replay_log_skip or not is_arena_battle or not in_battle

func _await_replay_step(seconds: float) -> void :
	if seconds <= 0.0:
		return
	var timer: = get_tree().create_timer(seconds)
	while timer.time_left > 0.0:
		if _replay_log_should_stop():
			return
		await get_tree().process_frame

func _arena_replay_step_delay(entry_type: String) -> float:
	if entry_type in [
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", 
		"skill_counter_attack", "skill_armor_pierce", "skill_guard", "miss", "dodge"
	]:
		return 1.0
	return 0.12

func _format_arena_battle_log_message(entry: Dictionary) -> String:
	var entry_type: = str(entry.get("type", ""))
	var preset: = str(entry.get("message", "")).strip_edges()
	var crit_mark: = "（暴击）" if bool(entry.get("isCritical", entry.get("is_critical", false))) else ""
	match entry_type:
		"round":
			return "[color=#88ccff]—— 第 %d 回合 ——[/color]" % int(entry.get("round", 0))
		"combo_trigger":
			if preset.is_empty():
				preset = "★ 连击触发! 你和宠物的敏捷都高于所有敌人! ★"
			return "[color=#ffd43b]%s[/color]" % preset
		"combo_attack":
			return "[color=#ffd43b]  ⚡ 【%s】连击！[/color]" % str(entry.get("attacker", "?"))
		"joint_attack":
			return "[color=#4dd0e1]  🔗 ★ 合击触发！【%s】和【%s】联手攻击【%s】！[/color]" % [
				str(entry.get("player", "你")), 
				str(entry.get("pet", "灵兽")), 
				str(entry.get("target", "敌人")), 
			]
		"kuihua_point_success":
			if preset.is_empty():
				var base_chance: = float(entry.get("baseChance", 0.0)) * 100.0
				var bonus_pct: = float(entry.get("bonusPct", 0.0))
				var final_chance: = float(entry.get("finalChance", 0.0)) * 100.0
				preset = "点穴手得手！%s 接下来两回合无法行动（基础%.1f%% + 加成%.1f%% = %.1f%%）" % [
					str(entry.get("target", "敌人")), base_chance, bonus_pct, final_chance
				]
			return "[color=#e6f35a]  ✨ 【%s】对【%s】施展点穴成功！%s[/color]" % [
				str(entry.get("attacker", "我方")), 
				str(entry.get("target", "敌人")), 
				preset, 
			]
		"kuihua_point_fail":
			if preset.is_empty():
				var base_chance2: = float(entry.get("baseChance", 0.0)) * 100.0
				var bonus_pct2: = float(entry.get("bonusPct", 0.0))
				var final_chance2: = float(entry.get("finalChance", 0.0)) * 100.0
				preset = "点穴手未生效（基础%.1f%% + 加成%.1f%% = %.1f%%）" % [base_chance2, bonus_pct2, final_chance2]
			return "[color=#bfbfcc]  ⚪ 【%s】对【%s】施展点穴失败。%s[/color]" % [
				str(entry.get("attacker", "我方")), 
				str(entry.get("target", "敌人")), 
				preset, 
			]
		"acupoint_skip":
			return "[color=#ffcc66]  ⛔ 【%s】被点穴封脉，本回合无法行动（剩余%d回合）[/color]" % [
				str(entry.get("target", "目标")), 
				int(entry.get("remain", 0)), 
			]
		"miss", "dodge":
			var atk: = str(entry.get("attacker", "?"))
			var tgt: = str(entry.get("target", "?"))
			var is_enemy: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
			var color: = "#ff9999" if is_enemy else "#66ff66"
			var action: = "被闪避" if entry_type == "dodge" else "未命中"
			return "[color=%s]  💨 【%s】攻击【%s】，%s！[/color]" % [color, atk, tgt, action]
		"attack", "triple_shot_hit", "kuihua_hit":
			if not preset.is_empty():
				if not crit_mark.is_empty() and preset.find("暴击") < 0:
					preset += " %s" % crit_mark
				return preset
			var attacker: = str(entry.get("attacker", "?"))
			var target: = str(entry.get("target", "?"))
			var damage: = int(entry.get("damage", 0))
			var target_hp: = int(entry.get("targetHp", entry.get("target_hp", 0)))
			var target_max_hp: = int(entry.get("targetMaxHp", entry.get("target_max_hp", 100)))
			var hp_percent: = float(target_hp) / float(maxi(target_max_hp, 1)) * 100.0
			var element_msg: = str(entry.get("elementMsg", entry.get("element_msg", "")))
			var soul_bonus: = int(entry.get("petSoulBonusPercent", entry.get("pet_soul_bonus_percent", 0)))
			if soul_bonus > 0 and element_msg.find("魂魄+") < 0:
				element_msg = ("%s （魂魄+%d%%）" % [element_msg, soul_bonus]).strip_edges()
			var noble_bonus: = int(entry.get("noblePetBonusPercent", entry.get("noble_pet_bonus_percent", 0)))
			if noble_bonus > 0 and bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))) and element_msg.find("贵族+") < 0:
				element_msg = ("%s （贵族+%d%%）" % [element_msg, noble_bonus]).strip_edges()
			var combo_text: = " 连击！" if bool(entry.get("isCombo", entry.get("is_combo", false))) else ""
			var joint_text: = " 合击！" if bool(entry.get("isJointAttack", entry.get("is_joint_attack", false))) else ""
			var is_enemy2: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
			var color2: = "#ff9999" if is_enemy2 else "#66ff66"
			var prefix: = "  "
			if entry_type == "triple_shot_hit":
				prefix = "  🏹 "
			elif entry_type == "kuihua_hit":
				prefix = "  【点穴手】"
			var crit_text: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			var base_text: = "%s【%s】攻击【%s】，造成 %d 伤害！%s%s%s(HP: %d/%d %.1f%%)" % [
				prefix, attacker, target, damage, combo_text, joint_text, crit_text, target_hp, target_max_hp, hp_percent
			]
			if not element_msg.is_empty():
				base_text += " 【%s】" % element_msg
			return "[color=%s]%s[/color]" % [color2, base_text]
		"skill_splash":
			if not preset.is_empty():
				if not crit_mark.is_empty() and preset.find("暴击") < 0:
					preset += " %s" % crit_mark
				return "[color=#8ce0ff]  💧 %s[/color]" % preset
			var sa: = str(entry.get("attacker", "?"))
			var st: = str(entry.get("target", "?"))
			var sd: = int(entry.get("damage", 0))
			var sthp: = int(entry.get("targetHp", entry.get("target_hp", 0)))
			var stmh: = int(entry.get("targetMaxHp", entry.get("target_max_hp", 1)))
			var spct: = float(sthp) / float(maxi(stmh, 1)) * 100.0
			var splash_crit: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			return "[color=#8ce0ff]  💧 【溅墨】【%s】波及【%s】，造成 %d 伤害%s（目标剩余 HP %d/%d，约 %.0f%%）[/color]" % [
				sa, st, sd, splash_crit, sthp, stmh, spct
			]
		"skill_double_shot":
			if not preset.is_empty():
				if not crit_mark.is_empty() and preset.find("暴击") < 0:
					preset += " %s" % crit_mark
				return "[color=#ffd173]  🎯 %s[/color]" % preset
			var da: = str(entry.get("attacker", "?"))
			var dt: = str(entry.get("target", "?"))
			var dd: = int(entry.get("damage", 0))
			var di: = int(entry.get("hitIndex", entry.get("hit_index", 0)))
			var ds_crit: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			return "[color=#ffd173]  🎯 【连击】第 %d 段：【%s】命中【%s】，%d 伤害%s[/color]" % [di, da, dt, dd, ds_crit]
		"skill_divine_protect":
			if not preset.is_empty():
				return "[color=#bfff8c]  ✨ %s[/color]" % preset
			var dname: = str(entry.get("target", "灵兽"))
			var dh: = int(entry.get("hpRestored", entry.get("hp_restored", 0)))
			return "[color=#bfff8c]  ✨ 【护主】【%s】触发，恢复生命约 %d[/color]" % [dname, dh]
		"skill_counter_attack":
			if not preset.is_empty():
				if not crit_mark.is_empty() and preset.find("暴击") < 0:
					preset += " %s" % crit_mark
				return "[color=#ffa673]  ⚡ %s[/color]" % preset
			var ca: = str(entry.get("attacker", "?"))
			var ct: = str(entry.get("target", "?"))
			var cd: = int(entry.get("damage", 0))
			var ca_crit: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			return "[color=#ffa673]  ⚡ 【反打】【%s】反击【%s】，%d 伤害%s[/color]" % [ca, ct, cd, ca_crit]
		"skill_chase":
			if not preset.is_empty():
				if not crit_mark.is_empty() and preset.find("暴击") < 0:
					preset += " %s" % crit_mark
				return "[color=#ffa673]  ⚡ %s[/color]" % preset
			var cha: = str(entry.get("attacker", "?"))
			var cht: = str(entry.get("target", "?"))
			var chd: = int(entry.get("damage", 0))
			var ch_crit: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			return "[color=#ffa673]  ⚡ 【追杀】【%s】追击【%s】，%d 伤害%s[/color]" % [cha, cht, chd, ch_crit]
		"skill_armor_pierce":
			if not preset.is_empty():
				return "[color=#ffd173]  ⚔ %s[/color]" % preset
			var ap_name: = str(entry.get("attacker", entry.get("petName", "灵兽")))
			return "[color=#ffd173]  ⚔ 【破防】【%s】本下忽视对方一半防御[/color]" % ap_name
		"skill_guard":
			if not preset.is_empty():
				return "[color=#74c0fc]  🛡 %s[/color]" % preset
			var gd_name: = str(entry.get("target", entry.get("petName", "灵兽")))
			return "[color=#74c0fc]  🛡 【挡伤】【%s】减免部分伤害[/color]" % gd_name
		"enemy_dead", "pet_dead", "player_dead":
			return "[color=#ffd43b]  💀 【%s】被击败！[/color]" % str(entry.get("name", "单位"))
		"victory":
			if preset.is_empty():
				preset = "★ 战斗胜利! ★"
			return "[color=#51cf66]%s[/color]" % preset
		"defeat":
			if preset.is_empty():
				preset = "战斗失败..."
			return "[color=#ff6b6b]%s[/color]" % preset
		"start", "info":
			return preset
		_:
			return preset

func _apply_arena_log_entry(entry: Dictionary) -> void :
	var bs = battle_system
	var entry_type: = str(entry.get("type", ""))
	match entry_type:
		"round", "start", "info", "combo_trigger", "combo_attack", "joint_attack", "kuihua_point_success", "kuihua_point_fail", "acupoint_skip", "skill_armor_pierce", "skill_guard":
			var msg: = _format_arena_battle_log_message(entry)
			if not msg.is_empty():
				bs.apply_replay_log(msg)
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", "skill_counter_attack", "skill_chase":
			_apply_arena_attack_entry(entry)
		"skill_divine_protect":
			_apply_arena_divine_protect_entry(entry)
		"miss", "dodge":
			_apply_arena_attacker_anim(entry)
			var miss_msg: = _format_arena_battle_log_message(entry)
			if not miss_msg.is_empty():
				bs.apply_replay_log(miss_msg)
		"enemy_dead", "pet_dead", "player_dead":
			bs.apply_replay_unit_died(str(entry.get("name", "")), true)
			var dead_msg: = _format_arena_battle_log_message(entry)
			if not dead_msg.is_empty():
				bs.apply_replay_log(dead_msg)
			if entry_type == "player_dead":
				bs.apply_replay_log("[color=#ff9966]⚠ 修士已力竭，仅灵兽继续作战[/color]")
		"victory", "defeat":
			var end_msg: = _format_arena_battle_log_message(entry)
			if not end_msg.is_empty():
				bs.apply_replay_log(end_msg)
		_:
			var fallback: = _format_arena_battle_log_message(entry)
			if fallback.is_empty():
				fallback = str(entry.get("message", "")).strip_edges()
			if not fallback.is_empty():
				bs.apply_replay_log(fallback)
	if entry_type in [
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", "skill_counter_attack", "skill_chase", 
		"skill_divine_protect", "skill_armor_pierce", "skill_guard", "enemy_dead", "pet_dead", "player_dead"
	]:
		call_deferred("_refresh_arena_battle_hud")

func _apply_arena_divine_protect_entry(entry: Dictionary) -> void :
	var bs = battle_system
	var msg: = _format_arena_battle_log_message(entry)
	if not msg.is_empty():
		bs.apply_replay_log(msg)
	var target_name: = str(entry.get("target", ""))
	var is_enemy: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
	var hit: = _resolve_arena_unit_hit_auto(target_name, is_enemy)
	if hit.is_empty():
		push_warning("竞技场回放：无法解析神佑目标 '%s'" % target_name)
		return
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	var hp_after: = int(entry.get("hpRestored", entry.get("hp_restored", entry.get("targetHp", entry.get("target_hp", -1)))))
	if hp_after >= 0:
		bs.set_replay_unit_hp(hit_type, hit_idx, hp_after)

func _apply_arena_attack_entry(entry: Dictionary) -> void :
	var bs = battle_system
	_apply_arena_attacker_anim(entry)
	var target_name: = str(entry.get("target", ""))
	var is_enemy_attack: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
	var hit: = _resolve_arena_unit_hit_auto(target_name, is_enemy_attack)
	if hit.is_empty():
		push_warning("竞技场回放：无法解析攻击目标 '%s'" % target_name)
		return
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	if bs.get_replay_unit_hp(hit_type, hit_idx) <= 0:
		return
	var log_msg: = _format_arena_battle_log_message(entry)
	if not log_msg.is_empty():
		bs.apply_replay_log(log_msg)
	var damage: = int(entry.get("damage", 0))
	var target_hp: = int(entry.get("targetHp", entry.get("target_hp", -1)))
	bs.apply_replay_damage_event({
		"attacker": str(entry.get("attacker", "")), 
		"target": target_name, 
		"damage": damage, 
		"is_critical": bool(entry.get("isCritical", entry.get("is_critical", false))), 
		"hit_target_type": hit_type, 
		"hit_target_index": hit_idx, 
		"target_hp_after": target_hp, 
		"element_tag": str(entry.get("elementMsg", entry.get("element_msg", ""))), 
		"is_armor_pierce": bool(entry.get("isArmorPierce", entry.get("is_armor_pierce", false))), 
		"is_counter": bool(entry.get("isCounter", entry.get("is_counter", false))) or str(entry.get("type", "")) == "skill_counter_attack", 
	})

func _apply_arena_attacker_anim(entry: Dictionary) -> void :
	var attacker_unit: = _resolve_arena_unit_attacker(entry)
	if attacker_unit.is_empty() or battle_system == null:
		return
	var target_name: = str(entry.get("target", "")).strip_edges()
	if not target_name.is_empty():
		var is_enemy_attack: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
		var hit: = _resolve_arena_unit_hit_auto(target_name, is_enemy_attack)
		if not hit.is_empty():
			attacker_unit["target_type"] = str(hit.get("type", ""))
			attacker_unit["target_index"] = int(hit.get("index", -1))
	var skill_name: = str(entry.get("skill", "")).strip_edges().to_lower()
	if str(entry.get("type", "")) == "kuihua_hit" or skill_name == "kuihua":
		attacker_unit["skip_lunge"] = true
	battle_system.apply_replay_unit_turn(attacker_unit)

func _resolve_arena_unit_attacker(entry: Dictionary) -> Dictionary:
	var attacker_name: = str(entry.get("attacker", "")).strip_edges()
	if attacker_name.is_empty():
		return {}
	var is_enemy: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
	if is_enemy:
		var hit: = _resolve_arena_unit_hit_auto(attacker_name, false)
		if hit.is_empty():
			return {}
		return {
			"type": str(hit.get("type", "")), 
			"index": int(hit.get("index", -1)), 
			"name": attacker_name, 
		}
	if bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))) or attacker_name.begins_with("我方灵兽·"):
		return {"type": "pet", "index": -1, "name": attacker_name}
	if attacker_name.begins_with("我方·"):
		return {"type": "player", "index": -1, "name": attacker_name}
	var bs = battle_system
	if bs and bs.player and bs._replay_ally_unit_name_matches(attacker_name, str(bs.player.player_name)):
		return {"type": "player", "index": -1, "name": attacker_name}
	if bs and bs.active_pet and bs._replay_ally_unit_name_matches(attacker_name, str(bs.active_pet.pet_name)):
		return {"type": "pet", "index": -1, "name": attacker_name}
	return {}

func _resolve_arena_unit_hit(unit_name: String, is_enemy_attack: bool) -> Dictionary:
	var bs = battle_system
	var name_str: = unit_name.strip_edges()
	if name_str.is_empty():
		return {}
	if is_enemy_attack:
		if bs.player and bs._replay_ally_unit_name_matches(name_str, str(bs.player.player_name)):
			return {"type": "player", "index": -1}
		if bs.active_pet and bs._replay_ally_unit_name_matches(name_str, str(bs.active_pet.pet_name)):
			return {"type": "pet", "index": -1}
	else:
		var want_pet: = name_str.begins_with("敌方灵兽·")
		for i in range(bs.monsters.size()):
			var m = bs.monsters[i]
			var role: = ""
			if m is Dictionary:
				role = str(m.get("arena_role", "")).strip_edges()
			if want_pet and role == "player":
				continue
			if not want_pet and role == "pet":
				continue
			if bs._replay_monster_name_matches_strict(name_str, m):
				return {"type": "monster", "index": i}
		for i in range(bs.monsters.size()):
			if bs._replay_monster_name_matches_strict(name_str, bs.monsters[i]):
				return {"type": "monster", "index": i}
	return {}

func _resolve_arena_unit_hit_auto(unit_name: String, is_enemy_attack_hint: bool = false) -> Dictionary:
	var hit: = _resolve_arena_unit_hit(unit_name, is_enemy_attack_hint)
	if not hit.is_empty():
		return hit
	return _resolve_arena_unit_hit(unit_name, not is_enemy_attack_hint)

func _switch_to_battle_view_for_arena(opponent_name: String) -> void :
	var main_ui: = _find_main_ui_node()
	if main_ui and main_ui.has_method("_on_arena_battle_started"):
		main_ui.call("_on_arena_battle_started", opponent_name)

func _cleanup_arena_battle_hooks() -> void :
	battle_system.suppress_battle_character_exp = false
	battle_system.replay_log_only = false
	arena_battle_character_id = 0



func release_stale_arena_match_lock() -> void :
	if is_shengsi_tower_replay or is_shengsi_replay_result_open:
		return
	if not is_arena_battle:
		return
	if _arena_battle_screen_in_progress():
		return

	if battle_system != null and battle_system.battle_ended.is_connected(_on_arena_battle_ended):
		var battle_state: int = battle_system.current_state
		if battle_state == battle_system.BattleState.VICTORY or battle_state == battle_system.BattleState.DEFEAT:
			return
	is_arena_battle = false
	arena_battle_token = ""
	if battle_system != null:
		if battle_system.battle_ended.is_connected(_on_arena_battle_ended):
			battle_system.battle_ended.disconnect(_on_arena_battle_ended)
		_cleanup_arena_battle_hooks()
		battle_system.max_rounds = -1
	if not is_in_instanced_challenge() and not _arena_battle_screen_in_progress():
		in_battle = false

func _arena_battle_screen_in_progress() -> bool:
	if battle_system == null:
		return false
	return in_battle and battle_system.current_state == battle_system.BattleState.IN_PROGRESS

func _refresh_arena_battle_hud() -> void :
	if not is_arena_battle or not in_battle or battle_system == null:
		return
	var main_ui: = _find_main_ui_node()
	if main_ui != null and main_ui.has_method("_refresh_active_battle_hud"):
		main_ui.call("_refresh_active_battle_hud")

func _on_arena_battle_ended(_victory: bool) -> void :
	_hide_replay_skip_button()
	if is_shengsi_tower_replay:
		return
	if not is_arena_battle and arena_battle_token.is_empty():
		return
	var token: = arena_battle_token
	var server_victory: = _victory
	is_arena_battle = false
	arena_battle_token = ""
	in_battle = false
	_cleanup_arena_battle_hooks()
	var confirm_ok: = false
	var confirm: Dictionary = {}
	if network != null and not token.is_empty():
		confirm = await network.request_arena_challenge_confirm(token, token)
		confirm_ok = bool(confirm.get("ok", false)) or bool(confirm.get("success", false))
	_refresh_arena_ui_if_open()
	_arena_last_settle = {
		"victory": server_victory, 
		"confirm_ok": confirm_ok, 
		"score_delta": int(confirm.get("scoreDelta", confirm.get("score_delta", 0))), 
		"weekly_arena_points": int(confirm.get("weeklyArenaPoints", confirm.get("weekly_arena_points", 0))), 
		"balance_arena_points": int(confirm.get("balanceArenaPoints", confirm.get("balance_arena_points", confirm.get("spendableArenaPoints", confirm.get("spendable_arena_points", 0))))), 
		"spendable_arena_points": int(confirm.get("spendableArenaPoints", confirm.get("spendable_arena_points", confirm.get("balanceArenaPoints", confirm.get("balance_arena_points", 0))))), 
		"my_rank": int(confirm.get("myRank", confirm.get("my_rank", 0))), 
		"win_streak": int(confirm.get("winStreak", confirm.get("win_streak", 0))), 
		"remaining_attempts": int(confirm.get("remainingAttempts", confirm.get("remaining_attempts", -1))), 
		"error": str(confirm.get("error", "")), 
	}
	last_battle_was_arena = true
	battle_ended_ui.emit(server_victory)
	resume_field_auto_battle_after_instanced_challenge()
	battle_system.max_rounds = -1

func get_arena_last_settle() -> Dictionary:
	return _arena_last_settle.duplicate(true)

func refresh_arena_ui_panel(root: Control) -> void :
	if root != null:
		_arena_ui_root = weakref(root)
	if _arena_status_refresh_busy:
		_arena_status_refresh_pending = true
		return
	if network != null and network.has_method("prepare_arena_channels"):
		network.prepare_arena_channels()
	_refresh_arena_ui_panel_async(root)

func _refresh_arena_ui_if_open() -> void :
	if _arena_ui_root == null:
		return
	var root: Control = _arena_ui_root.get_ref() as Control
	if root != null and is_instance_valid(root):
		_refresh_arena_ui_panel_async(root)

func _refresh_arena_ui_panel_async(root: Control) -> void :
	if network == null:
		return
	if _arena_status_refresh_busy:
		_arena_status_refresh_pending = true
		return
	_arena_status_refresh_busy = true
	var result: Dictionary = await network.request_arena_status()
	_arena_status_refresh_busy = false
	if root == null or not is_instance_valid(root):
		return
	ArenaUIClass.apply_status_to_root(root, result)
	if _arena_status_refresh_pending:
		_arena_status_refresh_pending = false
		call_deferred("refresh_arena_ui_panel", root)


const BROTHER_TOWER_UI_SCRIPT_PATH: = "res://ui/city/brother_tower_ui.gd"
const BROTHER_TOWER_MGR_SCRIPT_PATH: = "res://scripts/brother_tower/brother_tower_manager.gd"
const BrotherTowerBattleSync = preload("res://scripts/brother_tower/brother_tower_battle_sync.gd")

func _bt_ui() -> GDScript:
	return load(BROTHER_TOWER_UI_SCRIPT_PATH) as GDScript

func _bt_mgr() -> GDScript:
	return load(BROTHER_TOWER_MGR_SCRIPT_PATH) as GDScript

func _apply_brother_tower_difficulty_from_payload(data: Dictionary) -> void :
	if data.is_empty():
		return
	brother_tower_difficulty = _bt_mgr().normalize_difficulty(data.get("difficulty", _bt_mgr().DIFFICULTY_EASY))

func _reset_brother_tower_difficulty() -> void :
	brother_tower_difficulty = _bt_mgr().DIFFICULTY_EASY

func handle_brother_tower_start_response(data: Dictionary) -> void :
	call_deferred("_begin_brother_tower_start_from_network", data)

func request_brother_tower_start(room_id: int) -> void :
	_request_brother_tower_start_async(room_id)

func _try_recover_brother_tower_start_after_timeout() -> bool:
	if network == null:
		return false
	var sess: Dictionary = await _wait_brother_tower_session_fetch(8.0)
	if sess.is_empty():
		return false
	var status: = str(sess.get("status", ""))
	if status not in ["in_battle", "waiting_reconnect"]:
		return false
	var session_id: = int(sess.get("sessionId", 0))
	if session_id <= 0:
		return false
	if session_id == brother_tower_dismissed_session_id:
		return false
	var start_data: = sess.duplicate(true)
	start_data["success"] = true
	print("[GameManager] 兄弟天关开战超时后恢复 session=%d status=%s" % [session_id, status])
	var ok: = await _enter_brother_tower_from_session(sess)
	return ok

func _request_brother_tower_start_async(room_id: int) -> void :
	if _brother_tower_start_in_flight:
		return
	print("[GameManager] 兄弟天关：点击开始挑战 room=", room_id)
	if not network:
		_bt_ui().notify_start_error("网络未初始化")
		return
	if not _bt_ui()._has_pinned_snapshot():
		_bt_ui().notify_start_error(_bt_ui().PIN_SNAPSHOT_REQUIRED_MSG)
		return
	if inventory_manager == null or not inventory_manager.has_item(_bt_ui().TOKEN_NAME, 1):
		_bt_ui().notify_start_error("需要【%s】，队长开战时消耗 1 个" % _bt_ui().TOKEN_NAME)
		return
	_brother_tower_start_in_flight = true
	_bt_ui().set_start_pending(true)
	var op: = "bt_start_%d_%d" % [room_id, Time.get_unix_time_from_system()]
	var resp: Dictionary = await network.wait_brother_tower_start(op)
	_brother_tower_start_in_flight = false
	_bt_ui().set_start_pending(false)
	if not bool(resp.get("ok", false)):
		if is_brother_tower_battle:
			return
		var recovered: = await _try_recover_brother_tower_start_after_timeout()
		if recovered:
			return
		var err: = str(resp.get("err", "开始失败"))
		if "没有可开始的队伍" in err:
			network.get_brother_tower_session()
		_bt_ui().notify_start_error(err if not err.is_empty() else "开始失败")
		return
	var data: Dictionary = resp.get("data", {})
	if data.is_empty():
		if is_brother_tower_battle:
			return
		_bt_ui().notify_start_error("开战数据异常")
		return
	await _handle_brother_tower_start_response_async(data)

func _begin_brother_tower_start_from_network(data: Dictionary) -> void :
	await _handle_brother_tower_start_response_async(data)

func _handle_brother_tower_start_response_async(data: Dictionary) -> void :
	if is_brother_tower_battle:
		return
	print("[GameManager] 兄弟天关：收到开战数据 keys=", data.keys())
	var session_id: = int(data.get("sessionId", 0))
	var seed: = int(data.get("battleSeed", 0))
	if session_id > 0 and session_id == brother_tower_dismissed_session_id:
		if network:
			network.brother_tower_forfeit(session_id)
		_bt_ui().notify_start_error("上一局已结束，请重新开战")
		_bt_ui().set_start_pending(false)
		return
	if bool(data.get("resumed", false)) and brother_tower_dismissed_session_id > 0 and session_id > 0:
		if network:
			network.brother_tower_forfeit(session_id)
		_bt_ui().notify_start_error("上一局已结束，请重新开战")
		_bt_ui().set_start_pending(false)
		return
	if session_id <= 0 or seed <= 0:
		var recovered: = await _try_recover_brother_tower_start_after_timeout()
		if not recovered:
			_bt_ui().notify_start_error("正在同步战斗数据，请稍候…")
		return
	if not _bt_ui()._has_pinned_snapshot():
		_bt_ui().notify_start_error(_bt_ui().PIN_SNAPSHOT_REQUIRED_MSG)
		return
	var members: Array = data.get("members", [])
	if members == null or not members is Array:
		members = []
	var local_snap: Dictionary = _bt_mgr().find_member_snapshot(members, network.user_id if network else -1)
	if _bt_mgr().build_battle_pet_from_snapshot(local_snap) == null:
		_bt_ui().notify_start_error("出战快照无效，请重新更新人物与出战宠快照")
		_bt_ui().set_start_pending(false)
		return
	if _bt_mgr().build_battle_player_from_snapshot(local_snap) == null:
		_bt_ui().notify_start_error("人物快照无效，请重新更新人物与出战宠快照")
		_bt_ui().set_start_pending(false)
		return
	var coop: Array = _bt_mgr().resolve_coop_units(self, members, network.user_id if network else -1)
	var start_wave: = maxi(1, int(data.get("currentWave", 1)))
	_apply_brother_tower_difficulty_from_payload(data)
	if _bt_mgr().build_pet_pool(pet_manager).is_empty():
		_bt_ui().notify_start_error("怪物配置加载失败，无法开战")
		return
	if _bt_mgr().build_wave(pet_manager, seed, start_wave, brother_tower_difficulty, self).is_empty():
		_bt_ui().notify_start_error("怪物配置加载失败，无法开战")
		return
	print("[GameManager] 兄弟天关开战 session=%d seed=%d wave=%d" % [session_id, seed, start_wave])
	var driver_uid: = int(data.get("driverUserId", network.user_id if network else 0))
	var ok: bool = await start_brother_tower_battle(session_id, seed, coop, start_wave, driver_uid, str(data.get("role", "")), members)
	_bt_ui().set_start_pending(false)
	if not ok:
		var recovered: = await _try_recover_brother_tower_start_after_timeout()
		if not recovered:
			_bt_ui().notify_start_error("无法进入战斗，请稍候再试")

func _prepare_for_brother_tower_battle_start() -> void :
	if is_tower_battle or is_tower_settling or is_suit_dungeon_battle or is_suit_dungeon_settling or is_five_elements_battle or is_fe_settling or is_atlas_dungeon_battle or is_atlas_dungeon_settling or is_world_boss_battle or is_arena_battle:
		return
	prepare_for_instanced_challenge()
	await _wait_field_replay_idle_async()
	is_brother_tower_battle = false

func _switch_to_battle_view_for_brother_tower() -> void :
	var node: Node = self
	while node:
		if node is Control and node.has_method("_show_view"):
			node._show_view("battle")
			return
		node = node.get_parent()

func _resolve_brother_tower_role(driver_user_id: int, session_role: String = "") -> void :
	brother_tower_driver_user_id = driver_user_id
	var normalized_role: = session_role.strip_edges().to_lower()
	if normalized_role == "driver" or normalized_role == "viewer":
		brother_tower_role = normalized_role
		return
	if network and driver_user_id > 0 and network.user_id == driver_user_id:
		brother_tower_role = "driver"
	elif driver_user_id > 0:
		brother_tower_role = "viewer"
	else:
		brother_tower_role = "viewer"

func _teardown_brother_tower_sync() -> void :
	if _brother_tower_sync != null:
		_brother_tower_sync.teardown()
		_brother_tower_sync.queue_free()
		_brother_tower_sync = null

func _setup_brother_tower_sync() -> void :
	_teardown_brother_tower_sync()
	if brother_tower_session_id <= 0:
		return
	_brother_tower_sync = BrotherTowerBattleSync.new()
	add_child(_brother_tower_sync)
	_brother_tower_sync.setup(self, brother_tower_session_id, brother_tower_role == "driver", brother_tower_current_wave)

func start_brother_tower_battle(session_id: int, battle_seed: int, coop_units: Array, start_wave: int = 1, driver_user_id: int = 0, session_role: String = "", members: Array = []) -> bool:
	_resolve_brother_tower_role(driver_user_id, session_role)
	var local_uid: int = network.user_id if network else -1
	print("[GameManager] 兄弟天关角色 session=%d role=%s driverUid=%d localUid=%d" % [session_id, brother_tower_role, driver_user_id, local_uid])
	await _prepare_for_brother_tower_battle_start()
	if is_tower_battle or is_tower_settling or is_suit_dungeon_battle or is_suit_dungeon_settling or is_five_elements_battle or is_fe_settling or is_atlas_dungeon_battle or is_atlas_dungeon_settling:
		push_warning("兄弟天关：其他玩法战斗进行中，无法开战")
		return false
	if in_battle:
		push_warning("兄弟天关：检测到战斗状态不一致，强制重置")
		in_battle = false
		is_brother_tower_battle = false
	stop_brother_tower_requested = false
	is_brother_tower_settling = false
	brother_tower_waiting_reconnect = false
	brother_tower_waiting_partner = false
	brother_tower_viewer_wave_pending = false
	_viewer_wave_restart_in_flight = false
	_brother_tower_victory_finalized = false
	_brother_tower_victory_settle_in_flight = false
	_brother_tower_friendship_applied_session_id = 0
	brother_tower_last_complete_result = {}
	brother_tower_victory_popup_session_id = 0
	_brother_tower_pending_victory_reward = {}
	is_brother_tower_battle = true
	brother_tower_session_id = session_id
	brother_tower_battle_seed = battle_seed
	brother_tower_all_waves.clear()
	brother_tower_coop_units = coop_units
	brother_tower_local_snapshot = _bt_mgr().find_member_snapshot(members, local_uid)
	brother_tower_current_wave = maxi(1, start_wave)
	battle_system.suppress_battle_character_exp = true
	battle_system.drive_by_execute_turn = false
	_clear_leftover_replay_for_local_combat()
	if battle_system.battle_ended.is_connected(_on_battle_ended):
		battle_system.battle_ended.disconnect(_on_battle_ended)
	if battle_system.battle_ended.is_connected(_on_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_tower_battle_ended)
	if battle_system.battle_ended.is_connected(_on_suit_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_suit_dungeon_battle_ended)
	if battle_system.battle_ended.is_connected(_on_atlas_dungeon_battle_ended):
		battle_system.battle_ended.disconnect(_on_atlas_dungeon_battle_ended)
	if battle_system.battle_ended.is_connected(_on_fe_battle_ended):
		battle_system.battle_ended.disconnect(_on_fe_battle_ended)
	if battle_system.battle_ended.is_connected(_on_brother_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_brother_tower_battle_ended)
	battle_system.battle_ended.connect(_on_brother_tower_battle_ended)
	_setup_brother_tower_sync()
	var ok: = await _start_brother_tower_wave(brother_tower_current_wave)
	if ok and session_id != brother_tower_dismissed_session_id:
		brother_tower_dismissed_session_id = 0
	if not ok:
		is_brother_tower_battle = false
		brother_tower_session_id = 0
		brother_tower_all_waves.clear()
		brother_tower_coop_units.clear()
		brother_tower_local_snapshot = {}
		_bt_mgr().clear_coop_units(self)
		_teardown_brother_tower_sync()
		if battle_system.battle_ended.is_connected(_on_brother_tower_battle_ended):
			battle_system.battle_ended.disconnect(_on_brother_tower_battle_ended)
	return ok

func _start_brother_tower_wave(wave: int) -> bool:
	if wave < 1:
		push_error("兄弟天关：波次无效")
		return false
	if wave > get_brother_tower_wave_count():
		await _on_brother_tower_all_cleared()
		return true
	brother_tower_current_wave = wave
	_bt_mgr().heal_all_battle_allies(self)
	var wave_monsters: Array = _bt_mgr().build_wave(pet_manager, brother_tower_battle_seed, wave, brother_tower_difficulty, self)
	if wave_monsters.is_empty():
		if wave >= get_brother_tower_wave_count():
			await _on_brother_tower_all_cleared()
			return true
		push_error("兄弟天关：第%d波怪物为空" % wave)
		return false
	_bt_mgr().apply_coop_units_to_battle(self, brother_tower_coop_units)
	battle_system.max_rounds = _bt_mgr().battle_max_rounds(self)
	var active_pet: Pet = _bt_mgr().build_battle_pet_from_snapshot(brother_tower_local_snapshot)
	if not active_pet:
		push_error("兄弟天关：开战快照缺少出战宠")
		return false
	var battle_player: Player = _bt_mgr().build_battle_player_from_snapshot(brother_tower_local_snapshot)
	if not battle_player:
		push_error("兄弟天关：开战快照缺少人物")
		return false
	var is_viewer: = brother_tower_role == "viewer"
	_clear_leftover_replay_for_local_combat()
	battle_system.drive_by_execute_turn = is_viewer
	if _brother_tower_sync != null:
		_brother_tower_sync.set_wave(wave)
		if not is_viewer:
			_brother_tower_sync.push_wave_start(wave)
	if battle_system.start_battle(battle_player, active_pet, wave_monsters, battle_system.max_rounds, is_viewer, resolve_attack_target_mode("brother_tower")):
		in_battle = true
		battle_system.drive_by_execute_turn = false if not is_viewer else true
		if wave == 1:
			brother_tower_battle_started.emit()
		else:
			brother_tower_wave_started.emit(wave, get_brother_tower_wave_count())
		_switch_to_battle_view_for_brother_tower()
		if is_viewer and _brother_tower_sync != null:
			_brother_tower_sync.request_poll_now()
			_start_viewer_brother_tower_victory_watchdog()
		return true
	return false

func _on_brother_tower_battle_ended(victory: bool) -> void :
	if not is_brother_tower_battle or is_brother_tower_settling:
		return
	if brother_tower_role == "viewer":
		return
	if not victory:
		if _brother_tower_sync != null:
			_brother_tower_sync.push_battle_end(false)
			_brother_tower_sync.flush_now()
		_end_brother_tower_failed("挑战失败")
		return
	if brother_tower_waiting_reconnect:
		return
	var wave: = brother_tower_current_wave
	if _brother_tower_sync != null:
		_brother_tower_sync.push_battle_end(true)
		_brother_tower_sync.push_wave_end(wave)
		await _brother_tower_sync.flush_now()
	if network and brother_tower_session_id > 0:
		_brother_tower_wave_cleared_watchdog_retries = 0
		_start_brother_tower_wave_cleared_watchdog(wave)
		network.brother_tower_wave_cleared(brother_tower_session_id, wave)
		return
	await _continue_brother_tower_after_wave({"success": true, "status": "in_battle", "currentWave": wave + 1})

func on_brother_tower_wave_cleared_response(data: Dictionary) -> void :
	call_deferred("_begin_brother_tower_wave_cleared", data)

func _begin_brother_tower_wave_cleared(data: Dictionary) -> void :
	await _on_brother_tower_wave_cleared_async(data)

func _on_brother_tower_wave_cleared_async(data: Dictionary) -> void :
	if not is_brother_tower_battle:
		return
	_stop_brother_tower_wave_cleared_watchdog()
	await _continue_brother_tower_after_wave(data)

func _continue_brother_tower_after_wave(data: Dictionary) -> void :
	if not is_brother_tower_battle or is_brother_tower_settling:
		return
	var status: = str(data.get("status", ""))
	if status == "failed" or status == "forfeit":
		_stop_brother_tower_wave_cleared_watchdog()
		_stop_brother_tower_waiting_reconnect_watchdog()
		var reason: = str(data.get("failReason", "forfeit"))
		if reason == "forfeit":
			_end_brother_tower_failed("队友已退出，挑战失败")
		else:
			_end_brother_tower_failed("挑战失败")
		return
	if status == "waiting_reconnect":
		_stop_brother_tower_wave_cleared_watchdog()
		brother_tower_waiting_reconnect = true
		brother_tower_waiting_partner = false
		brother_tower_viewer_wave_pending = false
		is_brother_tower_settling = true
		var wait_sec: = int(data.get("waitSec", 60))
		battle_system.add_log("[color=yellow]等待队友重连… %d 秒[/color]" % wait_sec)
		_bt_mgr().heal_all_battle_allies(self)
		_start_brother_tower_waiting_reconnect_watchdog(wait_sec)
		await get_tree().create_timer(float(wait_sec)).timeout
		is_brother_tower_settling = false
		if not is_brother_tower_battle:
			return
		if brother_tower_waiting_reconnect and network:
			network.get_brother_tower_session()
		return
	if status == "waiting_partner" or status == "sync_wave":
		var sync_wave: = int(data.get("currentWave", brother_tower_current_wave))
		if sync_wave > get_brother_tower_wave_count():
			await _on_brother_tower_all_cleared()
			return

		brother_tower_viewer_wave_pending = true
		if network:
			network.get_brother_tower_session()
		return
	if status == "cleared":
		_stop_brother_tower_wave_cleared_watchdog()
		_stop_brother_tower_waiting_reconnect_watchdog()
		var victory_reward = data.get("victoryReward", {})
		if victory_reward is Dictionary and not victory_reward.is_empty():
			_brother_tower_pending_victory_reward = victory_reward.duplicate(true)
		if _brother_tower_sync != null and brother_tower_role == "driver":
			_brother_tower_sync.push_all_cleared()
			await _brother_tower_sync.flush_now()
		await _on_brother_tower_all_cleared()
		return
	if stop_brother_tower_requested:
		_end_brother_tower_failed("挑战已停止")
		return
	var next_wave: = int(data.get("currentWave", brother_tower_current_wave + 1))
	var wave_count: = get_brother_tower_wave_count()
	if next_wave > wave_count:
		await _on_brother_tower_all_cleared()
		return
	brother_tower_waiting_partner = false
	brother_tower_viewer_wave_pending = false
	_stop_brother_tower_wave_cleared_watchdog()
	_stop_brother_tower_waiting_reconnect_watchdog()
	is_brother_tower_settling = true
	battle_system.add_log("[color=green]★ 兄弟天关 第%d波通关！进入第%d波… ★[/color]" % [brother_tower_current_wave, next_wave])
	_bt_mgr().heal_all_battle_allies(self)
	await get_tree().create_timer(0.8).timeout
	is_brother_tower_settling = false
	if not is_brother_tower_battle or stop_brother_tower_requested:
		if is_brother_tower_battle:
			_end_brother_tower_failed("挑战已停止")
		return
	var started: = await _start_brother_tower_wave(next_wave)
	if not started and next_wave >= get_brother_tower_wave_count():
		await _on_brother_tower_all_cleared()

func on_brother_tower_session_polled(session: Dictionary) -> void :
	_begin_brother_tower_session_polled(session)

func _begin_brother_tower_session_polled(session: Dictionary) -> void :
	if _brother_tower_session_poll_in_flight:
		return
	_brother_tower_session_poll_in_flight = true
	await _on_brother_tower_session_polled_async(session)
	_brother_tower_session_poll_in_flight = false

func _auto_forfeit_stale_brother_tower_session(session_id: int) -> void :
	if session_id <= 0 or is_brother_tower_battle:
		return
	if session_id == brother_tower_dismissed_session_id:
		return
	brother_tower_dismissed_session_id = session_id
	brother_tower_waiting_reconnect = false
	brother_tower_waiting_partner = false
	brother_tower_viewer_wave_pending = false
	_viewer_wave_restart_in_flight = false
	if network:
		network.brother_tower_forfeit(session_id)
	print("[GameManager] auto forfeit stale brother tower session=%d" % session_id)

func _is_local_user_in_brother_tower_session(session: Dictionary) -> bool:
	if network == null:
		return false
	var local_uid: = int(network.user_id)
	var members = session.get("members", [])
	if members == null or not members is Array:
		return false
	for entry in members:
		if entry is Dictionary and int(entry.get("userId", entry.get("user_id", -1))) == local_uid:
			return true
	return false

func _should_auto_forfeit_stale_brother_tower_session(session: Dictionary) -> bool:
	if _brother_tower_start_in_flight:
		return false
	var session_id: = int(session.get("sessionId", 0))
	if session_id > 0 and session_id == brother_tower_dismissed_session_id:
		return true
	if _bt_ui().get_my_room_id() > 0:
		return false
	if _is_local_user_in_brother_tower_session(session):
		return false
	return true

func _enter_brother_tower_from_session(session: Dictionary) -> bool:
	if is_brother_tower_battle:
		return true
	var session_id: = int(session.get("sessionId", 0))
	var seed: = int(session.get("battleSeed", 0))
	var wave: = maxi(1, int(session.get("currentWave", 1)))
	if session_id <= 0 or seed <= 0:
		push_error("兄弟天关：会话恢复失败，波次或种子无效")
		return false
	if not _bt_ui()._has_pinned_snapshot():
		_bt_ui().notify_start_error(_bt_ui().PIN_SNAPSHOT_REQUIRED_MSG)
		return false
	var members: Array = session.get("members", [])
	if members == null or not members is Array:
		members = []
	var local_snap: Dictionary = _bt_mgr().find_member_snapshot(members, network.user_id if network else -1)
	if _bt_mgr().build_battle_pet_from_snapshot(local_snap) == null:
		_bt_ui().notify_start_error("出战快照无效，请重新更新人物与出战宠快照")
		return false
	if _bt_mgr().build_battle_player_from_snapshot(local_snap) == null:
		_bt_ui().notify_start_error("人物快照无效，请重新更新人物与出战宠快照")
		return false
	var coop: Array = _bt_mgr().resolve_coop_units(self, members, network.user_id if network else -1)
	_apply_brother_tower_difficulty_from_payload(session)
	if _bt_mgr().build_pet_pool(pet_manager).is_empty():
		push_error("兄弟天关：会话恢复失败，怪物池为空")
		return false
	if _bt_mgr().build_wave(pet_manager, seed, wave, brother_tower_difficulty, self).is_empty():
		push_error("兄弟天关：会话恢复失败，怪物生成失败")
		return false
	var driver_uid: = int(session.get("driverUserId", network.user_id if network else 0))
	return await start_brother_tower_battle(session_id, seed, coop, wave, driver_uid, str(session.get("role", "")), members)

func _on_brother_tower_session_polled_async(session: Dictionary) -> void :
	if session.is_empty():
		return
	var status: = str(session.get("status", ""))
	if not is_brother_tower_battle and status in ["in_battle", "waiting_reconnect"]:
		var session_id: = int(session.get("sessionId", 0))
		if session_id > 0 and session_id == brother_tower_dismissed_session_id:
			if network:
				network.brother_tower_forfeit(session_id)
			return
		if _should_auto_forfeit_stale_brother_tower_session(session):
			if session_id > 0:
				_auto_forfeit_stale_brother_tower_session(session_id)
			return
		await _enter_brother_tower_from_session(session)
		return
	if status == "cleared":
		if is_brother_tower_battle and not _is_matching_brother_tower_session(session):
			return
		if brother_tower_role == "viewer":
			_settle_viewer_on_session_cleared(session, "session_polled" if is_brother_tower_battle else "session_recovery")
			return
		if is_brother_tower_battle:
			while is_brother_tower_settling:
				await get_tree().create_timer(0.1).timeout
				if not is_brother_tower_battle:
					return
			await _on_brother_tower_all_cleared()
		return
	if status == "failed":
		if is_brother_tower_battle:
			if not _is_matching_brother_tower_session(session):
				return
			_stop_viewer_brother_tower_victory_watchdog()
			_end_brother_tower_failed(_brother_tower_forfeit_fail_message(session))
		return
	if brother_tower_viewer_wave_pending and status == "in_battle":
		var server_wave_pending: = int(session.get("currentWave", brother_tower_current_wave))
		if server_wave_pending > brother_tower_current_wave:
			brother_tower_viewer_wave_pending = false
			_stop_viewer_brother_tower_wave_pending_watchdog()
			await _start_brother_tower_wave(server_wave_pending)
			return
		if brother_tower_current_wave >= get_brother_tower_wave_count():
			if network:
				network.get_brother_tower_session()
		return
	if brother_tower_waiting_reconnect and status == "in_battle":
		brother_tower_waiting_reconnect = false
		brother_tower_waiting_partner = false
		_stop_brother_tower_waiting_reconnect_watchdog()
		_stop_brother_tower_wave_cleared_watchdog()
		is_brother_tower_settling = false
		var wave2: = int(session.get("currentWave", brother_tower_current_wave))
		await _start_brother_tower_wave(wave2)
	elif brother_tower_waiting_partner and status == "in_battle":
		var server_wave: = int(session.get("currentWave", brother_tower_current_wave))
		if server_wave > brother_tower_current_wave:
			brother_tower_waiting_partner = false
			brother_tower_viewer_wave_pending = false
			is_brother_tower_settling = true
			battle_system.add_log("[color=green]队友已就绪，进入第%d波…[/color]" % server_wave)
			_bt_mgr().heal_all_battle_allies(self)
			await get_tree().create_timer(0.5).timeout
			is_brother_tower_settling = false
			await _start_brother_tower_wave(server_wave)

func _wait_brother_tower_session_fetch(timeout_sec: float = 5.0) -> Dictionary:
	if network == null:
		return {}
	# 闭包里给 `captured` 重新赋值只是改副本，外面永远拿到 {}（兄弟天关会话一直取不到）。
	# 统一放 Dictionary 里按下标写。
	var st: = {"done": false, "session": {}}
	var handler: = func(data: Dictionary) -> void :
		if bool(st.done):
			return
		st.done = true
		var sess = data.get("session", {})
		if sess is Dictionary:
			st.session = sess
	network.brother_tower_session_loaded.connect(handler, CONNECT_ONE_SHOT)
	network.get_brother_tower_session()
	var elapsed: = 0.0
	while not bool(st.done) and elapsed < timeout_sec:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return st.session

func _ensure_brother_tower_session_cleared_for_complete(max_wait: float = 12.0) -> bool:
	if brother_tower_session_id <= 0:
		return false
	var elapsed: = 0.0
	var poll_interval: = 0.5
	while elapsed < max_wait:
		var session: = await _wait_brother_tower_session_fetch(5.0)
		if session.is_empty():
			await get_tree().create_timer(poll_interval).timeout
			elapsed += poll_interval
			continue
		var status: = str(session.get("status", ""))
		if status == "cleared":
			return true
		if status == "failed" or status == "forfeit":
			return false
		await get_tree().create_timer(poll_interval).timeout
		elapsed += poll_interval
	return false

func _start_viewer_brother_tower_victory_watchdog() -> void :
	_stop_viewer_brother_tower_victory_watchdog()
	if brother_tower_role != "viewer":
		return
	var timer: = Timer.new()
	timer.name = "ViewerVictoryWatchdog"

	timer.wait_time = VIEWER_VICTORY_WATCHDOG_IDLE_SEC
	timer.one_shot = false
	timer.timeout.connect(_on_viewer_victory_watchdog_timeout)
	add_child(timer)
	timer.start()
	_viewer_victory_watchdog = timer
	print("[GameManager] viewer 通关看门狗已启动 session=%d interval=%.1f" % [brother_tower_session_id, VIEWER_VICTORY_WATCHDOG_IDLE_SEC])

func _stop_viewer_brother_tower_victory_watchdog() -> void :
	if _viewer_victory_watchdog != null and is_instance_valid(_viewer_victory_watchdog):
		_viewer_victory_watchdog.stop()
		_viewer_victory_watchdog.queue_free()
	_viewer_victory_watchdog = null
	_viewer_watchdog_tick_in_flight = false

func _start_viewer_brother_tower_wave_pending_watchdog() -> void :
	_stop_viewer_brother_tower_wave_pending_watchdog()
	if brother_tower_role != "viewer" or not brother_tower_viewer_wave_pending:
		return
	var timer: = Timer.new()
	timer.name = "ViewerWavePendingWatchdog"
	timer.wait_time = 1.5
	timer.one_shot = false
	timer.timeout.connect(_on_viewer_wave_pending_watchdog_timeout)
	add_child(timer)
	timer.start()
	_viewer_wave_pending_watchdog = timer
	_viewer_wave_pending_sync_hint_at_ms = 0
	print("[GameManager] viewer 波间看门狗已启动 session=%d wave=%d" % [brother_tower_session_id, brother_tower_current_wave])

func _stop_viewer_brother_tower_wave_pending_watchdog() -> void :
	if _viewer_wave_pending_watchdog != null and is_instance_valid(_viewer_wave_pending_watchdog):
		_viewer_wave_pending_watchdog.stop()
		_viewer_wave_pending_watchdog.queue_free()
	_viewer_wave_pending_watchdog = null
	_viewer_wave_pending_watchdog_in_flight = false
	_viewer_wave_pending_sync_hint_at_ms = 0

func _on_viewer_wave_pending_watchdog_timeout() -> void :
	if _viewer_wave_pending_watchdog_in_flight:
		return
	_viewer_wave_pending_watchdog_tick()

func _viewer_wave_pending_watchdog_tick() -> void :
	if brother_tower_role != "viewer" or not is_brother_tower_battle or not brother_tower_viewer_wave_pending:
		_stop_viewer_brother_tower_wave_pending_watchdog()
		return
	if _brother_tower_victory_finalized or _viewer_wave_restart_in_flight:
		return
	_viewer_wave_pending_watchdog_in_flight = true
	var now_ms: = Time.get_ticks_msec()
	if _viewer_wave_pending_sync_hint_at_ms <= 0 or now_ms - _viewer_wave_pending_sync_hint_at_ms >= 8000:
		_viewer_wave_pending_sync_hint_at_ms = now_ms
		if battle_system:
			battle_system.add_log("[color=yellow]同步中，正在重试进入下一波…[/color]")
	var session: = await _wait_brother_tower_session_fetch(3.0)
	_viewer_wave_pending_watchdog_in_flight = false
	if brother_tower_role != "viewer" or not is_brother_tower_battle or not brother_tower_viewer_wave_pending:
		return
	if session.is_empty() or not _is_matching_brother_tower_session(session):
		return

	await _on_brother_tower_session_polled_async(session)

func _start_brother_tower_waiting_reconnect_watchdog(wait_sec: int) -> void :
	_stop_brother_tower_waiting_reconnect_watchdog()
	var timer: = Timer.new()
	timer.name = "BrotherTowerWaitingReconnectWatchdog"
	timer.wait_time = 2.0
	timer.one_shot = false
	timer.timeout.connect(_on_brother_tower_waiting_reconnect_watchdog_timeout)
	add_child(timer)
	timer.start()
	_brother_tower_waiting_reconnect_watchdog = timer

	var clear_after: = maxf(5.0, float(wait_sec) + 5.0)
	var clear_timer: = get_tree().create_timer(clear_after)
	clear_timer.timeout.connect( func() -> void :
		if not brother_tower_waiting_reconnect:
			return
		push_warning("[GameManager] waiting_reconnect flag 超时清除 session=%d" % brother_tower_session_id)
		brother_tower_waiting_reconnect = false
		is_brother_tower_settling = false
		_stop_brother_tower_waiting_reconnect_watchdog()
		if network and is_brother_tower_battle:
			network.get_brother_tower_session()
	, CONNECT_ONE_SHOT)
	print("[GameManager] 重连看门狗已启动 wait=%d session=%d" % [wait_sec, brother_tower_session_id])

func _stop_brother_tower_waiting_reconnect_watchdog() -> void :
	if _brother_tower_waiting_reconnect_watchdog != null and is_instance_valid(_brother_tower_waiting_reconnect_watchdog):
		_brother_tower_waiting_reconnect_watchdog.stop()
		_brother_tower_waiting_reconnect_watchdog.queue_free()
	_brother_tower_waiting_reconnect_watchdog = null
	_brother_tower_waiting_reconnect_watchdog_in_flight = false

func _on_brother_tower_waiting_reconnect_watchdog_timeout() -> void :
	if _brother_tower_waiting_reconnect_watchdog_in_flight:
		return
	if not is_brother_tower_battle or not brother_tower_waiting_reconnect:
		_stop_brother_tower_waiting_reconnect_watchdog()
		return
	_brother_tower_waiting_reconnect_watchdog_in_flight = true
	var session: = await _wait_brother_tower_session_fetch(3.0)
	_brother_tower_waiting_reconnect_watchdog_in_flight = false
	if not is_brother_tower_battle or not brother_tower_waiting_reconnect:
		return
	if session.is_empty() or not _is_matching_brother_tower_session(session):
		return
	await _on_brother_tower_session_polled_async(session)

func _start_brother_tower_wave_cleared_watchdog(wave: int) -> void :
	var keep_retries: = _brother_tower_wave_cleared_watchdog_retries
	_stop_brother_tower_wave_cleared_watchdog()
	_brother_tower_wave_cleared_pending_wave = wave
	_brother_tower_wave_cleared_watchdog_retries = keep_retries
	var timer: = Timer.new()
	timer.name = "BrotherTowerWaveClearedWatchdog"
	timer.wait_time = 6.0
	timer.one_shot = true
	timer.timeout.connect(_on_brother_tower_wave_cleared_watchdog_timeout)
	add_child(timer)
	timer.start()
	_brother_tower_wave_cleared_watchdog = timer

func _stop_brother_tower_wave_cleared_watchdog() -> void :
	if _brother_tower_wave_cleared_watchdog != null and is_instance_valid(_brother_tower_wave_cleared_watchdog):
		_brother_tower_wave_cleared_watchdog.stop()
		_brother_tower_wave_cleared_watchdog.queue_free()
	_brother_tower_wave_cleared_watchdog = null
	_brother_tower_wave_cleared_watchdog_in_flight = false
	_brother_tower_wave_cleared_pending_wave = 0
	_brother_tower_wave_cleared_watchdog_retries = 0

func _on_brother_tower_wave_cleared_watchdog_timeout() -> void :
	if _brother_tower_wave_cleared_watchdog_in_flight:
		return
	if not is_brother_tower_battle or brother_tower_role == "viewer":
		_stop_brother_tower_wave_cleared_watchdog()
		return
	if is_brother_tower_settling and not brother_tower_waiting_reconnect:

		_stop_brother_tower_wave_cleared_watchdog()
		return
	_brother_tower_wave_cleared_watchdog_in_flight = true
	if battle_system:
		battle_system.add_log("[color=yellow]波次上报较慢，正在同步会话…[/color]")
	var pending_wave: = _brother_tower_wave_cleared_pending_wave
	var session: = await _wait_brother_tower_session_fetch(4.0)
	_brother_tower_wave_cleared_watchdog_in_flight = false
	if not is_brother_tower_battle:
		_stop_brother_tower_wave_cleared_watchdog()
		return
	if session.is_empty() or not _is_matching_brother_tower_session(session):
		_brother_tower_wave_cleared_watchdog_retries += 1
		if _brother_tower_wave_cleared_watchdog_retries <= 2 and pending_wave > 0:
			_start_brother_tower_wave_cleared_watchdog(pending_wave)
		else:
			_stop_brother_tower_wave_cleared_watchdog()
		return
	var status: = str(session.get("status", ""))
	var server_wave: = int(session.get("currentWave", brother_tower_current_wave))
	_stop_brother_tower_wave_cleared_watchdog()
	if status in ["in_battle", "waiting_reconnect", "cleared", "failed"]:

		if status == "in_battle" and server_wave > brother_tower_current_wave and not is_brother_tower_settling:
			await _continue_brother_tower_after_wave({
				"success": true, 
				"status": "in_battle", 
				"currentWave": server_wave, 
			})
		else:
			await _on_brother_tower_session_polled_async(session)


func _on_viewer_victory_watchdog_timeout() -> void :
	if _viewer_watchdog_tick_in_flight:
		return
	_viewer_victory_watchdog_tick()

func _viewer_victory_watchdog_tick() -> void :
	if brother_tower_role != "viewer" or not is_brother_tower_battle or _brother_tower_victory_finalized:
		_stop_viewer_brother_tower_victory_watchdog()
		return

	if _viewer_victory_watchdog != null and is_instance_valid(_viewer_victory_watchdog):
		var near_end: = brother_tower_current_wave >= maxi(1, get_brother_tower_wave_count() - 1)
		var want: = VIEWER_VICTORY_WATCHDOG_NEAR_END_SEC if near_end else VIEWER_VICTORY_WATCHDOG_IDLE_SEC
		if absf(_viewer_victory_watchdog.wait_time - want) > 0.05:
			_viewer_victory_watchdog.wait_time = want
	_viewer_watchdog_tick_in_flight = true
	var session: = await _wait_brother_tower_session_fetch(3.0)
	_viewer_watchdog_tick_in_flight = false
	if brother_tower_role != "viewer" or not is_brother_tower_battle or _brother_tower_victory_finalized:
		return
	if session.is_empty():
		return
	if not _is_matching_brother_tower_session(session):
		return
	var status: = str(session.get("status", ""))
	var wave_count: = get_brother_tower_wave_count()
	var server_wave: = int(session.get("currentWave", 0))
	if status == "failed":
		_stop_viewer_brother_tower_victory_watchdog()
		_end_brother_tower_failed(_brother_tower_forfeit_fail_message(session))
		return
	if status == "cleared":
		_settle_viewer_on_session_cleared(session, "watchdog")
		return
	if status == "in_battle" and server_wave >= wave_count and brother_tower_current_wave >= wave_count:
		if network:
			network.get_brother_tower_session()

func _is_matching_brother_tower_session(session: Dictionary) -> bool:
	if session.is_empty():
		return false
	var polled_id: = int(session.get("sessionId", 0))
	if polled_id <= 0 or brother_tower_session_id <= 0:
		return false
	return polled_id == brother_tower_session_id

func _brother_tower_forfeit_fail_message(session: Dictionary) -> String:
	var fail_reason: = str(session.get("failReason", session.get("fail_reason", "")))
	if fail_reason != "forfeit":
		return "挑战失败"
	var forfeit_by: = int(session.get("forfeitBy", session.get("forfeit_by", 0)))
	var local_uid: int = int(network.user_id) if network else 0
	if forfeit_by > 0 and local_uid > 0 and forfeit_by != local_uid:
		if brother_tower_role == "viewer" or int(brother_tower_driver_user_id) == forfeit_by:
			return "队长已停止战斗，挑战失败"
		return "队友已退出，挑战失败"
	return "挑战失败"

func _peek_brother_tower_settlement_reward(session_id: int, session: Dictionary = {}) -> Dictionary:
	if bool(brother_tower_last_complete_result.get("ok", false)):
		var cached = brother_tower_last_complete_result.get("data", {})
		if cached is Dictionary and not cached.is_empty():
			return cached.duplicate(true)
	if session_id > 0 and (
		session_id == brother_tower_session_id
		or session_id == brother_tower_dismissed_session_id
	) and not _brother_tower_pending_victory_reward.is_empty():
		return _brother_tower_pending_victory_reward.duplicate(true)
	var victory_reward = session.get("victoryReward", {})
	if victory_reward is Dictionary and not victory_reward.is_empty():
		return victory_reward.duplicate(true)
	return {}

func _prepare_brother_tower_settlement_from_peek(session_id: int, session: Dictionary = {}) -> Dictionary:
	var reward_data: = _peek_brother_tower_settlement_reward(session_id, session)
	if reward_data.is_empty():
		reward_data = _resolve_brother_tower_victory_reward_data()
	if not reward_data.is_empty():
		_brother_tower_pending_victory_reward = reward_data.duplicate(true)
		brother_tower_last_complete_result = {"ok": true, "data": reward_data, "err": ""}
	return reward_data

func _kick_brother_tower_complete_refresh(session_id: int) -> void :
	if network == null or session_id <= 0:
		return
	var op_id: = "bt_complete_%d_%d" % [session_id, int(network.user_id)]
	var on_ok: = func(data: Dictionary) -> void :
		if data is Dictionary and not data.is_empty():
			brother_tower_last_complete_result = {"ok": true, "data": data, "err": ""}
			_apply_brother_tower_complete_reward_to_player(data, session_id)
	var on_fail: = func(err: String) -> void :
		push_warning("[GameManager] 兄弟天关 complete 后台刷新失败 session=%d err=%s" % [session_id, err])
		call_deferred("_begin_brother_tower_complete_retry_monitor", session_id, op_id)
	network.brother_tower_complete_success.connect(on_ok, CONNECT_ONE_SHOT)
	network.brother_tower_complete_failed.connect(on_fail, CONNECT_ONE_SHOT)
	network.brother_tower_complete(session_id, op_id)

func _settle_viewer_on_session_cleared(session: Dictionary, source: String) -> void :
	if brother_tower_role != "viewer" or _brother_tower_victory_finalized or _brother_tower_victory_settle_in_flight:
		return
	if not _is_matching_brother_tower_session(session):
		return
	var session_id: = int(session.get("sessionId", brother_tower_session_id))
	if session_id > 0 and session_id == brother_tower_victory_popup_session_id:
		return
	if str(session.get("status", "")) != "cleared":
		return
	call_deferred("_begin_settle_viewer_on_session_cleared", session, source)

func _begin_settle_viewer_on_session_cleared(session: Dictionary, source: String) -> void :
	await _settle_viewer_on_session_cleared_async(session, source)

func _settle_viewer_on_session_cleared_async(session: Dictionary, source: String) -> void :
	if brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	var session_id: = int(session.get("sessionId", brother_tower_session_id))
	if session_id <= 0 or not _is_matching_brother_tower_session(session):
		return
	if session_id == brother_tower_victory_popup_session_id:
		return
	print("[BT-Settle] viewer cleared source=%s session=%d" % [source, session_id])
	_stop_viewer_brother_tower_victory_watchdog()
	if is_brother_tower_battle:
		_abort_viewer_brother_tower_replay()
		brother_tower_viewer_wave_pending = false
		brother_tower_current_wave = maxi(brother_tower_current_wave, get_brother_tower_wave_count())
	_prepare_brother_tower_settlement_from_peek(session_id, session)
	await _finalize_brother_tower_victory_common(session_id)
	_kick_brother_tower_complete_refresh(session_id)

func _resolve_brother_tower_victory_reward_data() -> Dictionary:
	if not _brother_tower_pending_victory_reward.is_empty():
		return _brother_tower_pending_victory_reward.duplicate(true)
	var cached = brother_tower_last_complete_result.get("data", {})
	if cached is Dictionary and not cached.is_empty():
		return cached
	return {}

func _apply_brother_tower_complete_reward_to_player(reward_data: Dictionary, session_id: int = 0) -> void :
	if reward_data.is_empty() or player == null:
		return
	var friendship_gain: = maxi(0, int(reward_data.get("friendshipGain", 0)))
	if friendship_gain <= 0:
		return
	var sid: = session_id if session_id > 0 else brother_tower_victory_popup_session_id
	if sid > 0 and sid == _brother_tower_friendship_applied_session_id:
		return
	player.friendship_points += friendship_gain
	if sid > 0:
		_brother_tower_friendship_applied_session_id = sid

func _finalize_brother_tower_victory_common(settling_session_id: int) -> void :
	if _brother_tower_victory_finalized:
		return
	is_brother_tower_settling = true
	in_battle = false
	if battle_system:
		battle_system.add_log("[color=gold]★ 兄弟天关%d层联手通关！ ★[/color]" % get_brother_tower_wave_count())
	if player:
		player.heal_full()
	var active_pet = pet_manager.get_active_pet() if pet_manager else null
	if active_pet:
		active_pet.heal_full()
	if battle_system and battle_system.battle_ended.is_connected(_on_brother_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_brother_tower_battle_ended)
	_bt_mgr().clear_coop_units(self)
	_teardown_brother_tower_sync()
	var reward_data: = _resolve_brother_tower_victory_reward_data()
	if not reward_data.is_empty():
		_apply_brother_tower_complete_reward_to_player(reward_data, settling_session_id)
		brother_tower_last_complete_result = {"ok": true, "data": reward_data, "err": ""}
	brother_tower_dismissed_session_id = settling_session_id
	brother_tower_victory_popup_session_id = settling_session_id
	_stop_viewer_brother_tower_victory_watchdog()
	_stop_viewer_brother_tower_wave_pending_watchdog()
	_stop_brother_tower_waiting_reconnect_watchdog()
	_stop_brother_tower_wave_cleared_watchdog()
	brother_tower_battle_ended.emit(true)
	is_brother_tower_battle = false
	is_brother_tower_settling = false
	brother_tower_all_waves.clear()
	brother_tower_session_id = 0
	brother_tower_local_snapshot = {}
	brother_tower_role = ""
	brother_tower_driver_user_id = 0
	brother_tower_viewer_wave_pending = false
	_brother_tower_victory_finalized = true
	_brother_tower_pending_victory_reward = {}
	_reset_brother_tower_difficulty()
	save_game()
	_bt_ui().clear_lobby_after_battle_end(self)
	resume_field_auto_battle_after_instanced_challenge()

func _is_viewer_final_victory_battle_end(victory: bool, wave: int) -> bool:
	if not victory:
		return false
	var payload_wave: = wave if wave > 0 else brother_tower_current_wave
	var wave_count: = get_brother_tower_wave_count()
	return payload_wave >= wave_count or brother_tower_current_wave >= wave_count

func _begin_viewer_wave_from_sync(wave: int) -> void :
	if not is_brother_tower_battle or brother_tower_role != "viewer":
		return
	if _viewer_wave_restart_in_flight:
		return
	if wave < brother_tower_current_wave:
		return
	_viewer_wave_restart_in_flight = true
	brother_tower_current_wave = wave
	brother_tower_viewer_wave_pending = false
	_stop_viewer_brother_tower_wave_pending_watchdog()
	is_brother_tower_settling = true
	_bt_mgr().heal_all_battle_allies(self)
	await get_tree().create_timer(0.3).timeout
	is_brother_tower_settling = false
	if not is_brother_tower_battle:
		_viewer_wave_restart_in_flight = false
		return
	await _start_brother_tower_wave(wave)
	_viewer_wave_restart_in_flight = false

func _abort_viewer_brother_tower_replay() -> void :
	if brother_tower_role != "viewer" or battle_system == null:
		return
	battle_system.drive_by_execute_turn = false
	if battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.current_state = battle_system.BattleState.VICTORY
	in_battle = false

func _await_brother_tower_settling_clear(max_wait: float = VIEWER_VICTORY_SETTLE_MAX_WAIT) -> bool:
	var elapsed: = 0.0
	while is_brother_tower_settling and elapsed < max_wait:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		if not is_brother_tower_battle:
			return false
	return not is_brother_tower_settling

func _await_brother_tower_victory_settle_idle(max_wait: float = VIEWER_VICTORY_SETTLE_MAX_WAIT) -> bool:
	var elapsed: = 0.0
	while _brother_tower_victory_settle_in_flight and elapsed < max_wait:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		if not is_brother_tower_battle:
			return false
	return not _brother_tower_victory_settle_in_flight

func _ensure_viewer_brother_tower_victory_settle_async() -> void :
	if not is_brother_tower_battle or brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	if not await _await_brother_tower_victory_settle_idle():
		return
	if not is_brother_tower_battle or brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	if _brother_tower_victory_settle_in_flight:
		return
	await _await_brother_tower_settling_clear()
	if not is_brother_tower_battle or brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	if _brother_tower_victory_settle_in_flight:
		return
	_brother_tower_victory_settle_in_flight = true
	_stop_viewer_brother_tower_victory_watchdog()
	_abort_viewer_brother_tower_replay()
	brother_tower_viewer_wave_pending = false
	brother_tower_current_wave = maxi(brother_tower_current_wave, get_brother_tower_wave_count())
	await _on_brother_tower_all_cleared_async(true)
	if _brother_tower_victory_settle_in_flight:
		_brother_tower_victory_settle_in_flight = false

func _begin_viewer_brother_tower_victory_settle() -> void :
	await _ensure_viewer_brother_tower_victory_settle_async()

func _viewer_victory_settle_fallback_async() -> void :
	await get_tree().create_timer(0.3).timeout
	if not is_brother_tower_battle or brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	await _ensure_viewer_brother_tower_victory_settle_async()

func _on_viewer_all_cleared_from_sync() -> void :
	call_deferred("_begin_viewer_all_cleared_from_sync")

func _begin_viewer_all_cleared_from_sync() -> void :
	await _on_viewer_all_cleared_from_sync_async()

func _on_viewer_all_cleared_from_sync_async() -> void :
	if not is_brother_tower_battle or brother_tower_role != "viewer" or _brother_tower_victory_finalized:
		return
	print("[GameManager] viewer 收到 all_cleared 同步，立即结算 session=%d" % brother_tower_session_id)
	await _ensure_viewer_brother_tower_victory_settle_async()

func _on_viewer_battle_end_from_sync(victory: bool, wave: int = 0) -> void :
	call_deferred("_begin_viewer_battle_end_from_sync", victory, wave)

func _begin_viewer_battle_end_from_sync(victory: bool, wave: int = 0) -> void :
	await _on_viewer_battle_end_from_sync_async(victory, wave)

func _on_viewer_battle_end_from_sync_async(victory: bool, wave: int = 0) -> void :
	if not is_brother_tower_battle or brother_tower_role != "viewer":
		return
	if not victory:
		in_battle = false
		_end_brother_tower_failed("挑战失败")
		return
	var payload_wave: = wave if wave > 0 else brother_tower_current_wave
	if payload_wave >= get_brother_tower_wave_count():
		brother_tower_viewer_wave_pending = false
		brother_tower_current_wave = maxi(brother_tower_current_wave, payload_wave)
		battle_system.add_log("[color=green]★ 队长已通关，正在结算奖励… ★[/color]")
		call_deferred("_viewer_victory_settle_fallback_async")
		await _ensure_viewer_brother_tower_victory_settle_async()
		return
	in_battle = false
	brother_tower_viewer_wave_pending = true
	battle_system.add_log("[color=green]★ 第%d波通关，等待进入下一波… ★[/color]" % brother_tower_current_wave)
	_bt_mgr().heal_all_battle_allies(self)
	_start_viewer_brother_tower_wave_pending_watchdog()
	if network:
		network.get_brother_tower_session()

func _on_brother_tower_all_cleared(force_clear: bool = false) -> void :
	call_deferred("_begin_brother_tower_all_cleared", force_clear)

func _begin_brother_tower_all_cleared(force_clear: bool = false) -> void :
	await _on_brother_tower_all_cleared_async(force_clear)

func _on_brother_tower_all_cleared_async(force_clear: bool = false) -> void :
	if _brother_tower_victory_finalized:
		return
	if not is_brother_tower_battle or (is_brother_tower_settling and not force_clear):
		return
	is_brother_tower_settling = true
	in_battle = false
	var settling_session_id: = brother_tower_session_id
	_prepare_brother_tower_settlement_from_peek(settling_session_id, {})
	await _finalize_brother_tower_victory_common(settling_session_id)
	_kick_brother_tower_complete_refresh(settling_session_id)

func _begin_brother_tower_complete_retry_monitor(session_id: int, op_id: String) -> void :
	await _brother_tower_complete_retry_monitor_async(session_id, op_id)

func _brother_tower_complete_retry_monitor_async(session_id: int, op_id: String) -> void :
	if network == null or session_id <= 0 or op_id.is_empty():
		return
	var state: = {"done": false, "ok": false}
	var on_ok: = func(_data: Dictionary) -> void :
		state.done = true
		state.ok = true
	var on_fail: = func(_err: String) -> void :
		state.done = true
		state.ok = false
	network.brother_tower_complete_success.connect(on_ok, CONNECT_ONE_SHOT)
	network.brother_tower_complete_failed.connect(on_fail, CONNECT_ONE_SHOT)
	var deadline_ms: = Time.get_ticks_msec() + 2000
	while not bool(state.done) and Time.get_ticks_msec() < deadline_ms:
		await get_tree().create_timer(0.1).timeout
	if network.brother_tower_complete_success.is_connected(on_ok):
		network.brother_tower_complete_success.disconnect(on_ok)
	if network.brother_tower_complete_failed.is_connected(on_fail):
		network.brother_tower_complete_failed.disconnect(on_fail)
	if bool(state.ok):
		return
	if await _ensure_brother_tower_session_cleared_for_complete(8.0):
		print("[GameManager] complete 首次未成功，session 已 cleared，重试 op=%s" % op_id)
		var on_retry_ok: = func(data: Dictionary) -> void :
			if data is Dictionary and not data.is_empty():
				brother_tower_last_complete_result = {"ok": true, "data": data, "err": ""}
				_apply_brother_tower_complete_reward_to_player(data, session_id)
		network.brother_tower_complete_success.connect(on_retry_ok, CONNECT_ONE_SHOT)
		network.brother_tower_complete(session_id, op_id)

func _end_brother_tower_failed(msg: String) -> void :
	if not is_brother_tower_battle:
		stop_brother_tower_requested = false
		is_brother_tower_settling = false
		return
	in_battle = false
	var failing_sid: = brother_tower_session_id
	var already_forfeited: = stop_brother_tower_requested
	stop_brother_tower_requested = false
	is_brother_tower_settling = false
	brother_tower_waiting_reconnect = false
	_viewer_wave_restart_in_flight = false
	_brother_tower_victory_settle_in_flight = false
	if battle_system:
		battle_system.add_log("[color=red]%s[/color]" % msg)
	if player:
		player.heal_full()
	var active_pet = pet_manager.get_active_pet() if pet_manager else null
	if active_pet:
		active_pet.heal_full()
	if battle_system and battle_system.battle_ended.is_connected(_on_brother_tower_battle_ended):
		battle_system.battle_ended.disconnect(_on_brother_tower_battle_ended)
	_bt_mgr().clear_coop_units(self)
	_teardown_brother_tower_sync()
	_stop_viewer_brother_tower_victory_watchdog()
	_stop_viewer_brother_tower_wave_pending_watchdog()
	_stop_brother_tower_waiting_reconnect_watchdog()
	_stop_brother_tower_wave_cleared_watchdog()
	brother_tower_dismissed_session_id = failing_sid
	brother_tower_battle_ended.emit(false)
	is_brother_tower_battle = false
	brother_tower_all_waves.clear()
	if network and failing_sid > 0 and not already_forfeited:
		network.brother_tower_forfeit(failing_sid)
	brother_tower_session_id = 0
	brother_tower_local_snapshot = {}
	brother_tower_role = ""
	brother_tower_driver_user_id = 0
	brother_tower_viewer_wave_pending = false
	_reset_brother_tower_difficulty()
	save_game()
	_bt_ui().clear_lobby_after_battle_end(self)
	resume_field_auto_battle_after_instanced_challenge()

func force_stop_brother_tower_battle() -> void :
	if not is_brother_tower_battle:
		return
	_stop_viewer_brother_tower_victory_watchdog()
	stop_brother_tower_requested = true
	if network and brother_tower_session_id > 0:
		network.brother_tower_forfeit(brother_tower_session_id)
	if battle_system and battle_system.current_state == battle_system.BattleState.IN_PROGRESS:
		battle_system.force_end_battle(false)
	elif not is_brother_tower_settling:
		_end_brother_tower_failed("挑战已停止")
