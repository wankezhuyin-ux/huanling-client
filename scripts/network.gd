extends Node

const WorldBossHttp = preload("res://scripts/world_boss/world_boss_http.gd")
const ArenaHttp = preload("res://scripts/arena/arena_http.gd")
const PetRaiseRaceHttp = preload("res://scripts/pet_raise_race/pet_raise_race_http.gd")

signal login_success(user_id, nickname, token)
signal login_failed(error)
signal register_success(user_id, nickname, token)
signal register_failed(error)

signal save_uploaded(success)
signal save_downloaded(save_data)

signal save_upload_authority_conflict(error: String, code: String)
signal ranking_loaded(rankings)
signal ranking_players_loaded(rankings)
signal ranking_pets_loaded(rankings, category)
signal ranking_suit_dungeon_loaded(rankings)
signal vip_info_loaded(is_vip: bool, vip_level: int, daily_yuanbao_granted: int, vip_expire_time_str: String)
signal vip_daily_mutation_egg_mailed(item_name: String)
signal vip_info_failed(error: String)
signal tower_info_loaded(tower_highest: int, sweep_count: int, tower_floor: int)
signal tower_sweep_success()
signal tower_sweep_failed(error: String)
signal suit_dungeon_info_loaded(sweeps_left: int, max_sweeps: int)
signal suit_dungeon_sweep_success(sweeps_left: int)
signal suit_dungeon_sweep_failed(error: String)
signal fe_dungeon_status_loaded(data: Dictionary)
signal fe_dungeon_status_failed(error: String)
signal fe_dungeon_start_success(data: Dictionary)
signal fe_dungeon_start_failed(error: String)
signal atlas_dungeon_status_loaded(data: Dictionary)
signal atlas_dungeon_status_failed(error: String)
signal atlas_dungeon_start_success(data: Dictionary)
signal atlas_dungeon_start_failed(error: String)
signal brother_tower_list_loaded(data: Dictionary)
signal brother_tower_list_failed(error: String)
signal brother_tower_status_loaded(data: Dictionary)
signal brother_tower_poll_loaded(data: Dictionary)
signal brother_tower_poll_failed(error: String)
signal brother_tower_create_success(data: Dictionary)
signal brother_tower_create_failed(error: String)
signal brother_tower_join_success(data: Dictionary)
signal brother_tower_join_failed(error: String)
signal brother_tower_application_decide_success(data: Dictionary)
signal brother_tower_application_decide_failed(error: String)
signal brother_tower_leave_success(data: Dictionary)
signal brother_tower_leave_failed(error: String)
signal brother_tower_disband_success(data: Dictionary)
signal brother_tower_disband_failed(error: String)
signal brother_tower_ready_success(data: Dictionary)
signal brother_tower_ready_failed(error: String)
signal brother_tower_pin_snapshot_success(data: Dictionary)
signal brother_tower_pin_snapshot_failed(error: String)
signal brother_tower_start_success(data: Dictionary)
signal brother_tower_start_failed(error: String)
signal brother_tower_wave_cleared_success(data: Dictionary)
signal brother_tower_wave_cleared_failed(error: String)
signal brother_tower_session_loaded(data: Dictionary)
signal brother_tower_complete_success(data: Dictionary)
signal brother_tower_complete_failed(error: String)
signal brother_tower_battle_events_pushed(data: Dictionary)
signal brother_tower_battle_events_fetched(data: Dictionary)

signal shengsi_tower_overview_loaded(data: Dictionary)
signal shengsi_tower_overview_failed(error: String)
signal shengsi_tower_window_loaded(data: Dictionary)
signal shengsi_tower_window_failed(error: String)
signal shengsi_tower_floor_loaded(data: Dictionary)
signal shengsi_tower_floor_failed(error: String)
signal shengsi_tower_feed_loaded(data: Dictionary)
signal shengsi_tower_feed_failed(error: String)
signal shengsi_tower_room_list_loaded(data: Dictionary)
signal shengsi_tower_room_list_failed(error: String)
signal shengsi_tower_matchup_loaded(data: Dictionary)
signal shengsi_tower_matchup_failed(error: String)
signal shengsi_tower_my_battles_loaded(data: Dictionary)
signal shengsi_tower_my_battles_failed(error: String)
signal shengsi_tower_floor_battles_loaded(data: Dictionary)
signal shengsi_tower_floor_battles_failed(error: String)
signal shengsi_tower_match_loaded(data: Dictionary)
signal shengsi_tower_match_failed(error: String)
signal shengsi_tower_action_success(kind: String, data: Dictionary)
signal shengsi_tower_action_failed(kind: String, error: String)
signal fe_dungeon_clear_success(data: Dictionary)
signal fe_dungeon_clear_failed(error: String)
signal martial_info_loaded(create_count: int, is_today: bool, server_success_rate: float, noble_bonus: int)
signal martial_info_failed(error: String)
signal martial_create_success(create_count: int, remaining: int, new_gold: int, rolled_success: bool, server_success_rate: float, noble_bonus: int)
signal martial_create_failed(error: String)

var last_martial_create_payload: Dictionary = {}
signal martial_skill_book_success(data: Dictionary)
signal martial_skill_book_failed(error: String)
signal offline_info_loaded(offline_seconds: int, is_first_login: bool, vip_tier: int)
signal offline_heartbeat_success()
signal kicked_out(reason, should_save)
signal version_checked(need_update: bool, force_update: bool, update_info: Dictionary)
signal force_update_required(update_info: Dictionary)

signal xianmo_join_success(faction: String, nickname: String, new_gold: int)
signal xianmo_join_failed(error: String)
signal xianmo_info_loaded(data: Dictionary)
signal xianmo_faction_stats_loaded(data: Dictionary)
signal xianmo_ranking_loaded(rankings: Array, week_number: int, faction: String)
signal xianmo_adventure_success(data: Dictionary)
signal xianmo_adventure_failed(error: String)
signal xianmo_shop_items_loaded(items: Array)
signal xianmo_shop_buy_success(data: Dictionary)
signal xianmo_shop_buy_failed(error: String)
signal shop_buy_success(data: Dictionary)
signal shop_buy_failed(error: String)
signal main_shop_catalog_loaded(data: Dictionary)
signal main_shop_catalog_failed(error: String)
signal xianmo_week_info_loaded(data: Dictionary)
signal xianmo_chest_open_success(rewards: Dictionary)
signal xianmo_chest_open_failed(error: String)
signal xianmo_chest_open_batch_success(data: Dictionary)
signal xianmo_chest_open_batch_failed(error: String)
signal xianmo_chest_deposit_success(data: Dictionary)
signal xianmo_chest_deposit_failed(error: String)
signal xianmo_treasure_exchange_success(data: Dictionary)
signal xianmo_treasure_exchange_failed(error: String)
signal xianmo_treasure_use_success(data: Dictionary)
signal xianmo_treasure_use_failed(error: String)
signal xianmo_mirror_loaded(mirror: Dictionary)
signal xianmo_titles_loaded(titles: Array)
signal xianmo_battle_result_success(data: Dictionary)
signal xianmo_battle_result_failed(error: String)
signal xianmo_title_activated(data: Dictionary)
signal xianmo_title_deactivated(data: Dictionary)
signal xianmo_broadcasts_loaded(broadcasts: Array)
signal xianmo_broadcast_sent(success: bool)
signal treasure_status_loaded(data: Dictionary)
signal treasure_join_success(data: Dictionary)
signal treasure_join_failed(error: String)
signal treasure_participants_loaded(participants: Array)
signal treasure_battle_log_loaded(data: Dictionary)
signal arena_status_loaded(data: Dictionary)
signal arena_mirror_updated(data: Dictionary)
signal arena_match_started(data: Dictionary)
signal arena_challenge_started(data: Dictionary)
signal arena_challenge_confirmed(data: Dictionary)
signal arena_shop_items_loaded(data: Dictionary)
signal arena_shop_bought(data: Dictionary)
signal arena_titles_loaded(titles: Array)
signal arena_title_activated(data: Dictionary)
signal arena_request_failed(channel: String, error: String)
signal treasure_open_success(data: Dictionary)
signal treasure_open_failed(error: String)
signal treasure_tokens_validated(data: Dictionary)
signal treasure_tokens_validate_failed(error: String)
signal pet_merge_success(data: Dictionary)
signal pet_merge_failed(error: String)

signal pet_skill_synthetic_success(data: Dictionary)
signal pet_skill_synthetic_failed(error: String)
signal pet_skill_split_success(data: Dictionary)
signal pet_skill_split_failed(error: String)
signal pet_skill_learn_success(data: Dictionary)
signal pet_skill_learn_failed(error: String)
signal pet_skill_unlearn_success(data: Dictionary)
signal pet_skill_unlearn_failed(error: String)
signal pet_skill_slot_lock_success(data: Dictionary)
signal pet_skill_slot_lock_failed(error: String)

signal pet_skill_sync_success(data: Dictionary)
signal pet_skill_sync_failed(error: String)
signal pet_skill_level_up_success(data: Dictionary)
signal pet_skill_level_up_failed(error: String)
signal pet_evolve_success(data: Dictionary)
signal pet_evolve_failed(error: String)
signal pet_release_success(data: Dictionary)
signal pet_release_failed(error: String)
signal pet_release_batch_success(data: Dictionary)
signal pet_release_batch_failed(error: String)
signal pet_bag_store_success(data: Dictionary)
signal pet_bag_store_failed(error: String)
signal pet_bag_store_batch_success(data: Dictionary)
signal pet_bag_store_batch_failed(error: String)
signal pet_bag_retrieve_success(data: Dictionary)
signal pet_bag_retrieve_failed(error: String)
signal pet_bag_retrieve_batch_success(data: Dictionary)
signal pet_bag_retrieve_batch_failed(error: String)
signal pet_assist_equip_success(data: Dictionary)
signal pet_assist_equip_failed(error: String)
signal pet_assist_unequip_success(data: Dictionary)
signal pet_assist_unequip_failed(error: String)
signal set_current_map_success(data: Dictionary)
signal set_current_map_failed(error: String)
signal capture_settings_success(data: Dictionary)
signal capture_settings_failed(error: String)
signal pet_lock_success(data: Dictionary)
signal pet_lock_failed(error: String)
signal martial_sync_layout_success(data: Dictionary)
signal martial_sync_layout_failed(error: String)
signal martial_forget_success(data: Dictionary)
signal martial_forget_failed(error: String)
signal pet_refine_validate_done(data: Dictionary)
signal pet_roster_sync_success(data: Dictionary)
signal pet_roster_sync_failed(error: String)
signal pet_refine_success(data: Dictionary)
signal pet_refine_failed(error: String)
signal player_attr_auto_allocate_success(data: Dictionary)
signal player_attr_auto_allocate_failed(error: String)
signal player_attr_spend_success(data: Dictionary)
signal player_attr_spend_failed(error: String)
signal player_talent_allocate_success(data: Dictionary)
signal player_talent_allocate_failed(error: String)
signal player_talent_reset_success(data: Dictionary)
signal player_talent_reset_failed(error: String)
signal player_attr_plan_success(data: Dictionary)
signal player_attr_plan_failed(error: String)
signal pet_collection_invest_success(data: Dictionary)
signal pet_collection_invest_failed(error: String)
signal pet_soul_commit_success(data: Dictionary)
signal pet_soul_commit_failed(error: String)
signal pet_soul_commit_batch_success(data: Dictionary)
signal pet_soul_commit_batch_failed(error: String)
signal pet_soul_use_item_success(data: Dictionary)
signal pet_soul_use_item_failed(error: String)
signal equipment_equip_success(data: Dictionary)
signal equipment_equip_failed(error: String)
signal equipment_unequip_success(data: Dictionary)
signal equipment_unequip_failed(error: String)
signal equipment_unseal_suit_success(data: Dictionary)
signal equipment_unseal_suit_failed(error: String)
signal equipment_suit_convert_success(data: Dictionary)
signal equipment_suit_convert_failed(error: String)
signal equipment_dismantle_suit_success(data: Dictionary)
signal equipment_dismantle_suit_failed(error: String)
signal equipment_dismantle_suit_batch_success(data: Dictionary)
signal equipment_dismantle_suit_batch_failed(error: String)
signal equipment_store_warehouse_success(data: Dictionary)
signal equipment_store_warehouse_failed(error: String)
signal equipment_retrieve_warehouse_success(data: Dictionary)
signal equipment_retrieve_warehouse_failed(error: String)
signal pet_equipment_equip_success(data: Dictionary)
signal pet_equipment_equip_failed(error: String)
signal pet_equipment_unequip_success(data: Dictionary)
signal pet_equipment_unequip_failed(error: String)
signal pet_equipment_store_warehouse_success(data: Dictionary)
signal pet_equipment_store_warehouse_failed(error: String)
signal pet_equipment_retrieve_warehouse_success(data: Dictionary)
signal pet_equipment_retrieve_warehouse_failed(error: String)
signal pet_equipment_dismantle_success(data: Dictionary)
signal pet_equipment_dismantle_failed(error: String)
signal pet_equipment_dismantle_batch_success(data: Dictionary)
signal pet_equipment_dismantle_batch_failed(error: String)
signal pet_equipment_drop_success(data: Dictionary)
signal pet_equipment_drop_failed(error: String)
signal pet_equipment_enhance_success(data: Dictionary)
signal pet_equipment_enhance_failed(error: String)
signal pet_equipment_synthesize_fragments_success(data: Dictionary)
signal pet_equipment_synthesize_fragments_failed(error: String)
signal inventory_synthesize_seal_stone_success(data: Dictionary)
signal inventory_synthesize_seal_stone_failed(error: String)
signal suit_equipment_enhance_success(data: Dictionary)
signal suit_equipment_enhance_failed(error: String)
signal suit_equipment_enhance_confirm_success(data: Dictionary)
signal suit_equipment_enhance_confirm_failed(error: String)
signal pill_craft_success(data: Dictionary)
signal pill_craft_failed(error: String)
signal pet_equipment_grant_success(data: Dictionary)
signal pet_equipment_grant_failed(error: String)
signal pet_reincarnation_success(data: Dictionary)
signal pet_reincarnation_failed(error: String)
signal pet_reincarnation_inherit_success(data: Dictionary)
signal pet_reincarnation_inherit_failed(error: String)
signal player_buffs_loaded(data: Dictionary)
signal pet_instance_level_fetched(data: Dictionary)

signal equipment_grant_success(data: Dictionary)
signal equipment_grant_failed(error: String)
signal equipment_drop_success(data: Dictionary)
signal equipment_drop_failed(error: String)
signal inventory_drop_success(data: Dictionary)
signal inventory_drop_failed(error: String)
signal inventory_store_warehouse_success(data: Dictionary)
signal inventory_store_warehouse_failed(error: String)
signal inventory_store_warehouse_batch_success(data: Dictionary)
signal inventory_store_warehouse_batch_failed(error: String)
signal equipment_retrieve_warehouse_batch_success(data: Dictionary)
signal equipment_retrieve_warehouse_batch_failed(error: String)
signal frontier_gift_use_success(data: Dictionary)
signal frontier_gift_use_failed(error: String)
signal pet_egg_open_success(data: Dictionary)
signal pet_egg_open_failed(error: String)
signal pet_gift_open_success(data: Dictionary)
signal pet_gift_open_failed(error: String)
signal pet_medal_use_success(data: Dictionary)
signal pet_medal_use_failed(error: String)
signal pet_medal_use_batch_success(data: Dictionary)
signal pet_medal_use_batch_failed(error: String)
signal pet_grant_medal_success(data: Dictionary)
signal pet_grant_medal_failed(error: String)
signal pet_max_level_learn_success(data: Dictionary)
signal pet_max_level_learn_failed(error: String)
signal forge_preview_success(data: Dictionary)
signal forge_preview_failed(error: String)
signal forge_execute_success(data: Dictionary)
signal forge_execute_failed(error: String)
signal realm_transition_success(data: Dictionary)
signal realm_transition_failed(error: String)
signal save_revision_updated(revision: int)

signal server_time_synced(server_unix_time: int)

signal sync_health_changed(is_degraded: bool, message: String)

signal sync_heartbeat_ok()

signal gang_buffs_synced(buffs: Dictionary)
signal lottery_draw_success(data: Dictionary)
signal lottery_draw_failed(error: String)
signal lottery_pity_status_loaded(data: Dictionary)
signal lottery_pity_status_failed(error: String)
signal drop_config_loaded(drop_rates: Dictionary)
signal festival_runtime_config_loaded(config: Dictionary)
signal gameplay_runtime_config_loaded(config: Dictionary)
signal lottery_pity_claim_success(data: Dictionary)
signal lottery_pity_claim_failed(error: String)

signal noble_info_loaded(data: Dictionary)
signal noble_info_failed(error: String)
signal noble_claim_success(data: Dictionary)
signal noble_claim_failed(error: String)


signal economy_result(request_id: String, kind: String, ok: bool, data: Dictionary, err: String)

signal mail_list_via_network_response(result: int, response_code: int, body: PackedByteArray)

const _GameServerConfig = preload("res://scripts/game_server_config.gd")
const _PetEquipmentData = preload("res://scripts/pet_equipment/pet_equipment_data.gd")
var _primary_api_base: String = _GameServerConfig.api_base()
var server_url: = _primary_api_base
var _pending_login_username: String = ""
var _pending_login_password: String = ""
var _pending_register_username: String = ""
var _pending_register_password: String = ""
var _pending_register_nickname: String = ""
var auth_token: = ""
var user_id: = 0
var nickname: = ""
var server_wipe_id: = ""
const SAVE_SCHEMA_VERSION: = 2

var http_request: HTTPRequest
var action_request: HTTPRequest
var heartbeat_request: HTTPRequest
var brother_tower_heartbeat_request: HTTPRequest

var shengsi_window_request: HTTPRequest
var _shengsi_get_kind: String = ""
var _shengsi_overview_pending: bool = false

var shengsi_room_list_request: HTTPRequest
var _shengsi_room_list_floor: int = 0
var _shengsi_room_list_pending_floor: int = -1
var shengsi_feed_request: HTTPRequest
var _shengsi_feed_floor: int = 0
var _shengsi_feed_pending_floor: int = -1

var shengsi_floor_request: HTTPRequest
var _shengsi_floor_num: int = 0
var _shengsi_floor_pending: int = -1
var shengsi_matchup_request: HTTPRequest
var _shengsi_matchup_pending: bool = false
var _shengsi_matchup_pending_include_log: bool = false
var _shengsi_matchup_include_log: bool = false

var shengsi_floor_battles_request: HTTPRequest
var _shengsi_floor_battles_num: int = 0
var _shengsi_floor_battles_pending: int = -1
var shengsi_match_request: HTTPRequest
var _shengsi_match_id: int = 0
var _shengsi_match_pending: int = 0

var shengsi_action_request: HTTPRequest
var _shengsi_action_queue: Array = []
var _shengsi_action_busy: bool = false
var _shengsi_action_kind: String = ""
var version_check_request: HTTPRequest

var xianmo_chest_request: HTTPRequest

var shop_buy_request: HTTPRequest

var pet_max_level_learn_request: HTTPRequest

var economy_battle_loot_request: HTTPRequest
var events_batch_request: HTTPRequest

var economy_tower_clear_request: HTTPRequest

var brother_tower_complete_request: HTTPRequest

var brother_tower_battle_sync_request: HTTPRequest
var _brother_tower_battle_sync_queue: Array = []
var _brother_tower_battle_sync_watchdog: Timer
var _brother_tower_battle_sync_pump_scheduled: bool = false
var _brother_tower_battle_sync_request_gen: int = 0
var _bt_waiter_token_seq: int = 0

var fe_dungeon_request: HTTPRequest
var _fe_dungeon_queue: Array = []

var treasure_status_request: HTTPRequest
var _treasure_status_defer_attempts: int = 0

var _treasure_status_429_round: int = 0
const TREASURE_STATUS_429_MAX_ROUNDS: int = 4

var treasure_join_request: HTTPRequest
var _treasure_join_defer_attempts: int = 0

var treasure_mirror_request: HTTPRequest
var _treasure_mirror_busy: bool = false

var treasure_open_request: HTTPRequest
var _treasure_open_defer_attempts: int = 0

var treasure_token_validate_request: HTTPRequest

var _broadcast_hist_snap_http: HTTPRequest
var _broadcast_hist_snap_busy: bool = false
var _economy_battle_loot_queue: Array = []
var _economy_tower_clear_queue: Array = []
var _brother_tower_complete_queue: Array = []

var _duplicate_resync_ctx: Dictionary = {}
var _duplicate_resync_skip_standard_download_handler: bool = false

var _suit_enhance_resync_baseline: Dictionary = {}
var _last_brother_tower_poll_scope: String = "lobby"
var brother_tower_start_request: HTTPRequest
var _brother_tower_start_queue: Array = []
var _world_boss_http: WorldBossHttp
var _arena_http: ArenaHttp
var _pet_raise_race_http: PetRaiseRaceHttp
var _shop_buy_queue: Array = []

const ECONOMY_BATTLE_LOOT_HTTP_TIMEOUT_SEC: float = 120.0
const ECONOMY_TOWER_CLEAR_HTTP_TIMEOUT_SEC: float = 5.0
const BROTHER_TOWER_COMPLETE_HTTP_TIMEOUT_SEC: float = 45.0
const BROTHER_TOWER_START_HTTP_TIMEOUT_SEC: float = 45.0
const BROTHER_TOWER_BATTLE_SYNC_HTTP_TIMEOUT_SEC: float = 12.0
const FE_DUNGEON_HTTP_TIMEOUT_SEC: float = 45.0

const ECONOMY_BL_MAX_ERR_BUSY_DEFERS: int = 360
const ECONOMY_BL_MAX_NOT_DISCONNECTED_DEFERS: int = 7200
var _economy_bl_err_busy_defers: int = 0
var _economy_bl_disc_defers: int = 0

var _economy_bl_watchdog: Timer
var _heartbeat_timer: float = 0.0
var _heartbeat_interval: float = 8.0
const SYNC_HEALTH_FAIL_THRESHOLD: int = 5
const SYNC_HEALTH_STALE_SECONDS: float = 60.0
const SYNC_HEALTH_RECOVERY_SUCCESS_THRESHOLD: int = 2
var _sync_last_success_tick_ms: int = 0
var _sync_consecutive_failures: int = 0
var _sync_consecutive_successes: int = 0
var _sync_is_degraded: bool = false
var _sync_last_error_message: String = ""

var _request_queue: Array = []
var _is_processing_request: bool = false
var _current_request_info: Dictionary = {}
var _bt_fetch_waiters: Array = []
var _bt_push_waiters: Array = []


const MAX_RETRY_COUNT: int = 5
const RETRY_DELAYS: Array = [1, 2, 5, 10, 30]
const PENDING_SAVE_DIR: String = "user://pending_saves/"

var _pending_upload_data: Dictionary = {}
var _pending_upload_path: String = ""
var _pending_upload_timestamp: int = 0
var _server_time_base_unix: float = 0.0
var _server_time_synced_at_ticks_msec: int = 0
var _has_server_time_sync: bool = false
var _upload_retry_count: int = 0
var _retry_timer: float = 0.0
var _is_retrying: bool = false

var _discard_inflight_upload_callback: bool = false
var _current_action_type: String = ""

var _last_pet_direct_op: String = ""
var _last_server_save_revision: int = 0
var _upload_revision_sync_retry_available: bool = true
var _upload_revision_sync_in_progress: bool = false
var _last_save_upload_throttled_at_ms: int = 0
var client_version_header: String = "1.3.3"

func _is_save_upload_persisted_success(data: Dictionary) -> bool:
	if not bool(data.get("success", false)):
		return false

	if bool(data.get("throttled", false)):
		_last_save_upload_throttled_at_ms = Time.get_ticks_msec()
		return false

	if bool(data.get("deduped", false)) or bool(data.get("duplicate", false)):
		var rev: = _extract_save_revision(data)
		if rev < 0:
			return false

		if rev <= _last_server_save_revision:
			_last_save_upload_throttled_at_ms = Time.get_ticks_msec()
			return false

		if _last_save_upload_throttled_at_ms > 0 and Time.get_ticks_msec() - _last_save_upload_throttled_at_ms < 5000:
			return false
	_last_save_upload_throttled_at_ms = 0
	return true

func reset_upload_revision_retry_slot() -> void :
	_upload_revision_sync_retry_available = true

func consume_upload_revision_retry_slot() -> bool:
	if not _upload_revision_sync_retry_available:
		return false
	_upload_revision_sync_retry_available = false
	return true

func is_upload_revision_sync_in_progress() -> bool:
	return _upload_revision_sync_in_progress

func _finish_upload_revision_sync() -> void :
	_upload_revision_sync_in_progress = false

func _begin_upload_revision_sync_from_reject(data: Dictionary) -> void :
	var srv: = int(data.get("serverRevision", -1))
	if srv >= 0:
		_apply_server_save_revision({"saveRevision": srv})
	var gm: = GameManager.instance
	if gm and gm.has_method("_set_cloud_save_revision"):
		gm._set_cloud_save_revision(srv)
	_upload_revision_sync_in_progress = true
	if is_logged_in():
		call_deferred("download_save")

func _extract_save_revision(payload: Variant) -> int:
	if payload == null or not (payload is Dictionary):
		return -1
	var data: Dictionary = payload
	if data.has("saveRevision"):
		var direct = int(data.get("saveRevision", -1))
		if direct >= 0:
			return direct
	if data.has("saveData") and data.get("saveData") is Dictionary:
		var from_save_data = _extract_save_revision(data.get("saveData"))
		if from_save_data >= 0:
			return from_save_data
	if data.has("gameSettings") and data.get("gameSettings") is Dictionary:
		var gs: Dictionary = data.get("gameSettings")
		if gs.has("save_revision"):
			var gs_rev = int(gs.get("save_revision", -1))
			if gs_rev >= 0:
				return gs_rev
	return -1

func _apply_server_save_revision(payload: Variant) -> void :
	var rev = _extract_save_revision(payload)
	if rev < 0:
		return
	if rev > _last_server_save_revision:
		_last_server_save_revision = rev
	save_revision_updated.emit(_last_server_save_revision)

func get_last_server_save_revision() -> int:
	return _last_server_save_revision

func _ensure_action_request_ready() -> bool:
	if action_request == null:
		action_request = HTTPRequest.new()
		action_request.timeout = 45.0
		add_child(action_request)
	if not action_request.request_completed.is_connected(_on_action_request_completed):
		action_request.request_completed.connect(_on_action_request_completed)
	return true

signal pending_uploads_found(count: int)
signal upload_retrying(attempt: int, max_attempts: int)

func _ready():
	http_request = HTTPRequest.new()

	http_request.timeout = 120.0
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	treasure_status_request = HTTPRequest.new()
	treasure_status_request.timeout = 45.0
	add_child(treasure_status_request)
	treasure_status_request.request_completed.connect(_on_treasure_status_request_completed)

	treasure_open_request = HTTPRequest.new()

	treasure_open_request.timeout = 12.0
	add_child(treasure_open_request)
	treasure_open_request.request_completed.connect(_on_treasure_open_request_completed)

	treasure_join_request = HTTPRequest.new()
	treasure_join_request.timeout = 18.0
	add_child(treasure_join_request)
	treasure_join_request.request_completed.connect(_on_treasure_join_request_completed)

	treasure_mirror_request = HTTPRequest.new()
	treasure_mirror_request.timeout = 18.0
	add_child(treasure_mirror_request)

	treasure_token_validate_request = HTTPRequest.new()
	treasure_token_validate_request.timeout = 20.0
	add_child(treasure_token_validate_request)
	treasure_token_validate_request.request_completed.connect(_on_treasure_token_validate_completed)

	action_request = HTTPRequest.new()

	action_request.timeout = 45.0
	add_child(action_request)
	action_request.request_completed.connect(_on_action_request_completed)

	heartbeat_request = HTTPRequest.new()
	heartbeat_request.timeout = 15.0
	add_child(heartbeat_request)
	heartbeat_request.request_completed.connect(_on_heartbeat_completed)

	brother_tower_heartbeat_request = HTTPRequest.new()
	brother_tower_heartbeat_request.timeout = 8.0
	add_child(brother_tower_heartbeat_request)
	brother_tower_heartbeat_request.request_completed.connect(_on_brother_tower_heartbeat_dedicated_completed)

	shengsi_window_request = HTTPRequest.new()
	shengsi_window_request.timeout = 8.0
	add_child(shengsi_window_request)
	shengsi_window_request.request_completed.connect(_on_shengsi_window_dedicated_completed)

	shengsi_room_list_request = HTTPRequest.new()
	shengsi_room_list_request.timeout = 10.0
	add_child(shengsi_room_list_request)
	shengsi_room_list_request.request_completed.connect(_on_shengsi_room_list_dedicated_completed)

	shengsi_feed_request = HTTPRequest.new()
	shengsi_feed_request.timeout = 10.0
	add_child(shengsi_feed_request)
	shengsi_feed_request.request_completed.connect(_on_shengsi_feed_dedicated_completed)

	shengsi_floor_request = HTTPRequest.new()
	shengsi_floor_request.timeout = 10.0
	add_child(shengsi_floor_request)
	shengsi_floor_request.request_completed.connect(_on_shengsi_floor_dedicated_completed)

	shengsi_matchup_request = HTTPRequest.new()
	shengsi_matchup_request.timeout = 10.0
	add_child(shengsi_matchup_request)
	shengsi_matchup_request.request_completed.connect(_on_shengsi_matchup_dedicated_completed)

	shengsi_floor_battles_request = HTTPRequest.new()
	shengsi_floor_battles_request.timeout = 10.0
	add_child(shengsi_floor_battles_request)
	shengsi_floor_battles_request.request_completed.connect(_on_shengsi_floor_battles_dedicated_completed)

	shengsi_match_request = HTTPRequest.new()
	shengsi_match_request.timeout = 20.0
	add_child(shengsi_match_request)
	shengsi_match_request.request_completed.connect(_on_shengsi_match_dedicated_completed)

	shengsi_action_request = HTTPRequest.new()
	shengsi_action_request.timeout = 18.0
	add_child(shengsi_action_request)
	shengsi_action_request.request_completed.connect(_on_shengsi_action_dedicated_completed)

	version_check_request = HTTPRequest.new()
	version_check_request.timeout = 10.0
	add_child(version_check_request)
	version_check_request.request_completed.connect(_on_version_check_completed)

	xianmo_chest_request = HTTPRequest.new()
	xianmo_chest_request.timeout = 45.0
	add_child(xianmo_chest_request)
	xianmo_chest_request.request_completed.connect(_on_xianmo_chest_dedicated_completed)

	shop_buy_request = HTTPRequest.new()

	shop_buy_request.timeout = 25.0
	add_child(shop_buy_request)
	shop_buy_request.request_completed.connect(_on_shop_buy_dedicated_completed)

	pet_max_level_learn_request = HTTPRequest.new()
	pet_max_level_learn_request.timeout = 45.0
	add_child(pet_max_level_learn_request)
	pet_max_level_learn_request.request_completed.connect(_on_pet_max_level_learn_dedicated_completed)

	economy_battle_loot_request = HTTPRequest.new()
	events_batch_request = HTTPRequest.new()
	events_batch_request.name = "events_batch_request"
	add_child(events_batch_request)
	economy_battle_loot_request.timeout = ECONOMY_BATTLE_LOOT_HTTP_TIMEOUT_SEC
	add_child(economy_battle_loot_request)
	economy_battle_loot_request.request_completed.connect(_on_economy_battle_loot_dedicated_completed)

	economy_tower_clear_request = HTTPRequest.new()
	economy_tower_clear_request.timeout = ECONOMY_TOWER_CLEAR_HTTP_TIMEOUT_SEC
	add_child(economy_tower_clear_request)
	economy_tower_clear_request.request_completed.connect(_on_economy_tower_clear_dedicated_completed)

	brother_tower_complete_request = HTTPRequest.new()
	brother_tower_complete_request.timeout = BROTHER_TOWER_COMPLETE_HTTP_TIMEOUT_SEC
	add_child(brother_tower_complete_request)
	brother_tower_complete_request.request_completed.connect(_on_brother_tower_complete_dedicated_completed)

	brother_tower_battle_sync_request = HTTPRequest.new()
	brother_tower_battle_sync_request.timeout = BROTHER_TOWER_BATTLE_SYNC_HTTP_TIMEOUT_SEC
	brother_tower_battle_sync_request.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(brother_tower_battle_sync_request)
	brother_tower_battle_sync_request.request_completed.connect(_on_brother_tower_battle_sync_dedicated_completed)
	_brother_tower_battle_sync_watchdog = Timer.new()
	_brother_tower_battle_sync_watchdog.name = "BrotherTowerBattleSyncWatchdog"
	_brother_tower_battle_sync_watchdog.one_shot = true
	_brother_tower_battle_sync_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_brother_tower_battle_sync_watchdog)
	_brother_tower_battle_sync_watchdog.timeout.connect(_on_brother_tower_battle_sync_watchdog_timeout)

	brother_tower_start_request = HTTPRequest.new()
	brother_tower_start_request.timeout = BROTHER_TOWER_START_HTTP_TIMEOUT_SEC
	add_child(brother_tower_start_request)
	brother_tower_start_request.request_completed.connect(_on_brother_tower_start_dedicated_completed)

	fe_dungeon_request = HTTPRequest.new()
	fe_dungeon_request.timeout = FE_DUNGEON_HTTP_TIMEOUT_SEC
	add_child(fe_dungeon_request)
	fe_dungeon_request.request_completed.connect(_on_fe_dungeon_dedicated_completed)

	_world_boss_http = WorldBossHttp.new()
	_world_boss_http.name = "WorldBossHttp"
	add_child(_world_boss_http)
	_world_boss_http.setup(self)
	_arena_http = ArenaHttp.new()
	_arena_http.name = "ArenaHttp"
	add_child(_arena_http)
	_arena_http.setup(self)
	_arena_http.status_loaded.connect( func(data): arena_status_loaded.emit(data))
	_arena_http.mirror_updated.connect( func(data): arena_mirror_updated.emit(data))
	_arena_http.match_started.connect( func(data): arena_match_started.emit(data))
	_arena_http.challenge_started.connect( func(data): arena_challenge_started.emit(data))
	_arena_http.challenge_confirmed.connect( func(data): arena_challenge_confirmed.emit(data))
	_arena_http.shop_items_loaded.connect( func(data): arena_shop_items_loaded.emit(data))
	_arena_http.shop_bought.connect( func(data): arena_shop_bought.emit(data))
	_arena_http.arena_request_failed.connect( func(channel, err): arena_request_failed.emit(channel, err))
	_pet_raise_race_http = PetRaiseRaceHttp.new()
	_pet_raise_race_http.name = "PetRaiseRaceHttp"
	add_child(_pet_raise_race_http)
	_pet_raise_race_http.setup(self)

	_broadcast_hist_snap_http = HTTPRequest.new()
	_broadcast_hist_snap_http.timeout = 15.0
	add_child(_broadcast_hist_snap_http)

	_economy_bl_watchdog = Timer.new()
	_economy_bl_watchdog.one_shot = true
	_economy_bl_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_economy_bl_watchdog)
	_economy_bl_watchdog.timeout.connect(_on_economy_battle_loot_watchdog_timeout)

func _process(delta):
	if auth_token != "":
		_heartbeat_timer += delta
		if _heartbeat_timer >= _heartbeat_interval:
			_heartbeat_timer = 0.0
			_send_heartbeat()
		if _sync_last_success_tick_ms > 0 and not _sync_is_degraded:
			var age_ms: int = int(max(0, Time.get_ticks_msec() - _sync_last_success_tick_ms))
			if age_ms >= int(SYNC_HEALTH_STALE_SECONDS * 1000.0):
				_set_sync_degraded(true, "与服务器心跳中断，请检查网络。")

	if _is_retrying and not _pending_upload_data.is_empty():
		_retry_timer += delta
		var delay = RETRY_DELAYS[min(_upload_retry_count, RETRY_DELAYS.size() - 1)]
		if _retry_timer >= delay:
			_retry_timer = 0.0
			_do_upload_save()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if auth_token != "":
			_send_heartbeat()

func _send_heartbeat():
	if auth_token == "":
		return
	if heartbeat_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	heartbeat_request.request(server_url + "/user/info", headers, HTTPClient.METHOD_GET)

func _on_heartbeat_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		_mark_sync_heartbeat_failure("心跳请求失败，请检查网络连接。")
		return
	if response_code != 200:
		_mark_sync_heartbeat_failure("心跳响应异常(HTTP %d)" % response_code)
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if data is Dictionary:
				if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
					_emit_force_update(data)
					return
				if str(data.get("code", "")) == "ACCOUNT_SUSPENDED" or bool(data.get("accountSuspended", false)):
					kicked_out.emit(_format_account_suspended_message(data), true)
					logout()
					return
				if data.has("error") and data.error == "Account logged in elsewhere":
					kicked_out.emit("登录已失效，请重新登录。", true)
					logout()
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_mark_sync_heartbeat_failure("心跳响应解析失败，请稍后重试。")
		return
	var payload: Variant = json.data
	if payload is Dictionary:
		_update_server_time_from_response_data(payload)
		_apply_newbie_exp_until_from_dict(payload)
		var raw_gang_buffs: Variant = payload.get("gangBuffs", null)
		if raw_gang_buffs is Dictionary:
			gang_buffs_synced.emit(raw_gang_buffs)
	_mark_sync_heartbeat_success()

func _mark_sync_heartbeat_success() -> void :
	_sync_last_success_tick_ms = Time.get_ticks_msec()
	_sync_consecutive_failures = 0
	_sync_last_error_message = ""
	_sync_consecutive_successes += 1
	if _sync_is_degraded:
		if _sync_consecutive_successes >= SYNC_HEALTH_RECOVERY_SUCCESS_THRESHOLD:
			_set_sync_degraded(false, "")
	else:
		_set_sync_degraded(false, "")
	sync_heartbeat_ok.emit()

func _mark_sync_heartbeat_failure(reason: String) -> void :
	if auth_token == "":
		return
	_sync_consecutive_successes = 0
	_sync_consecutive_failures += 1
	_sync_last_error_message = reason
	if _sync_consecutive_failures >= SYNC_HEALTH_FAIL_THRESHOLD:
		_set_sync_degraded(true, reason)

func _set_sync_degraded(degraded: bool, reason: String) -> void :
	if _sync_is_degraded == degraded:
		if degraded and reason != "":
			_sync_last_error_message = reason
		return
	_sync_is_degraded = degraded
	if degraded:
		_sync_consecutive_successes = 0
	else:
		_sync_last_error_message = ""
		_sync_consecutive_failures = 0
	sync_health_changed.emit(_sync_is_degraded, get_sync_status_message())

func is_sync_degraded() -> bool:
	return _sync_is_degraded

func get_sync_status_message() -> String:
	if not is_logged_in():
		return "未登录，当前仅本地存档。"
	if not _sync_is_degraded:
		return "同步正常"
	if _sync_last_error_message.strip_edges() != "":
		return "同步异常：" + _sync_last_error_message
	return "同步异常：当前无法保证云端实时同步。"

func can_commit_critical_op() -> bool:
	return is_logged_in() and not is_sync_degraded()

func _update_server_time_from_response_data(data: Dictionary) -> void :
	if data.is_empty():
		return
	var has_explicit_time: = data.has("serverUnixTime")
	var server_unix: = int(data.get("serverUnixTime", 0))
	if not has_explicit_time:

		has_explicit_time = data.has("serverTime")
		server_unix = int(data.get("serverTime", 0))
	if has_explicit_time and server_unix > 0:
		_set_server_time_sync(server_unix)

func _set_server_time_sync(server_unix_time: int) -> void :
	if server_unix_time <= 0:
		return
	_server_time_base_unix = float(server_unix_time)
	_server_time_synced_at_ticks_msec = Time.get_ticks_msec()
	_has_server_time_sync = true
	server_time_synced.emit(server_unix_time)

func has_server_time_sync(max_age_seconds: float = 300.0) -> bool:
	if not _has_server_time_sync:
		return false
	if max_age_seconds <= 0.0:
		return true
	var age_seconds: = float(max(0, Time.get_ticks_msec() - _server_time_synced_at_ticks_msec)) / 1000.0
	return age_seconds <= max_age_seconds

func get_server_time_unix() -> int:
	if not _has_server_time_sync:
		return -1
	var elapsed_seconds: = float(max(0, Time.get_ticks_msec() - _server_time_synced_at_ticks_msec)) / 1000.0
	return int(floor(_server_time_base_unix + elapsed_seconds))



func _localize_auth_error_message(msg: String) -> String:
	var t: = msg.strip_edges()
	match t:
		"Invalid credentials":
			return "用户名或密码错误"
		"Username and password required":
			return "用户名和密码不能为空"
		"Username 3-20 chars":
			return "用户名需要3-20个字符"
		"Password min 6 chars":
			return "密码至少6个字符"
		"Username exists":
			return "该用户名已被注册"
		"Nickname exists":
			return "该角色名已被占用"
		"Server error":
			return "服务器异常，请稍后重试"
		"Access denied":
			return "当前网络无法访问"
		_:
			return t

func _emit_login_failed(msg: String) -> void :
	login_failed.emit(_localize_auth_error_message(msg))

func _emit_register_failed(msg: String) -> void :
	register_failed.emit(_localize_auth_error_message(msg))

func _format_account_suspended_message(data: Dictionary) -> String:
	var er: = str(data.get("error", "")).strip_edges()
	var br: = str(data.get("banReason", "")).strip_edges()
	var bc: = str(data.get("banCode", "")).strip_edges()
	var lines: Array[String] = []
	if er != "":
		lines.append(er)
	if br != "" and br != er:
		if lines.size() > 0:
			lines.append("")
		lines.append("详情：" + br)
	if bc != "":
		if lines.size() > 0:
			lines.append("")
		lines.append("代码：" + bc)
	if lines.is_empty():
		return "账号已暂停"
	return "\n".join(lines)

func set_server_url(url: String):
	server_url = url
	_primary_api_base = url

func set_client_version(version: String):
	var ver = String(version).strip_edges()
	if ver != "":
		client_version_header = ver

func _build_headers(require_auth: bool = false, content_type: bool = true) -> PackedStringArray:
	var headers: PackedStringArray = []
	if content_type:
		headers.append("Content-Type: application/json")
	if require_auth and auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	headers.append("X-Client-Version: " + client_version_header)
	return headers

func _is_transport_failure_for_api_fallback(result: int) -> bool:
	return result == HTTPRequest.RESULT_CANT_CONNECT\
	or result == HTTPRequest.RESULT_CANT_RESOLVE\
	or result == HTTPRequest.RESULT_CONNECTION_ERROR\
	or result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR\
	or result == HTTPRequest.RESULT_NO_RESPONSE\
	or result == HTTPRequest.RESULT_TIMEOUT

func _try_dispatch_auth_on_http_fallback(current_type: String) -> bool:
	server_url = _GameServerConfig.api_http_fallback_base()
	var headers: = _build_headers(false, true)
	var path: = "/login" if current_type == "login" else "/register"
	var json: = ""
	if current_type == "login":
		json = JSON.stringify({
			"username": _pending_login_username, 
			"password": _pending_login_password, 
			"clientVersion": client_version_header
		})
	else:
		var reg_body: = {
			"username": _pending_register_username, 
			"password": _pending_register_password, 
			"clientVersion": client_version_header
		}
		if _pending_register_nickname != "":
			reg_body["nickname"] = _pending_register_nickname
		json = JSON.stringify(reg_body)
	var err: = http_request.request(server_url + path, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		server_url = _primary_api_base
		return false
	return true

func _maybe_retry_auth_with_http_fallback(current_type: String, result: int) -> bool:
	if current_type != "login" and current_type != "register":
		return false
	if not _is_transport_failure_for_api_fallback(result):
		return false
	if server_url != _primary_api_base:
		return false
	print("[Network] ", current_type, " transport failure (result=", result, "); retrying via HTTP API fallback")
	return _try_dispatch_auth_on_http_fallback(current_type)

func _emit_force_update(data: Dictionary) -> void :
	var update_info = {
		"latestVersion": String(data.get("latestVersion", "")), 
		"minimumVersion": String(data.get("minimumVersion", "")), 
		"currentVersion": String(data.get("currentVersion", client_version_header)), 
		"updateUrl": String(data.get("updateUrl", "")), 
		"message": String(data.get("error", "客户端版本过低，请更新后继续游戏")), 
		"releaseNotes": ""
	}
	force_update_required.emit(update_info)
	logout()

func _is_high_priority_request(request_type: String) -> bool:
	return request_type == "download_save" or request_type == "login" or request_type == "register" or request_type.begins_with("economy_") or request_type == "fe_dungeon_start" or request_type == "fe_dungeon_clear" or request_type == "fe_dungeon_status" or request_type == "atlas_dungeon_start" or request_type == "atlas_dungeon_finish" or request_type == "pet_refine" or request_type == "pet_grant_starter" or request_type == "brother_tower_start" or request_type == "brother_tower_wave_cleared" or request_type == "brother_tower_session" or request_type == "brother_tower_battle_events_fetch" or request_type == "brother_tower_battle_events_push" or request_type == "brother_tower_poll" or request_type == "brother_tower_list" or request_type == "brother_tower_complete"

func _enqueue_request(request_type: String, request_func: Callable, request_id: String = ""):
	print("[Network] _enqueue_request: type=", request_type, " queue_size=", _request_queue.size(), " is_processing=", _is_processing_request)
	var entry: = {"type": request_type, "func": request_func, "request_id": request_id}

	if request_type == "economy_offline_claim":
		# 离线结算必须真正排在最前面。登录后客户端会立刻自动开打，而战斗结算
		# （economy_battle_loot）同样插队到队首，一茬接一茬 —— 如果大家平等插队，
		# offline-claim 会被无限往后挤（饥饿），45 秒超时都轮不上，玩家看到的
		# 就是「登录后一直纯背景、既没有离线面板也没有人物面板」。
		_request_queue.insert(0, entry)
	elif _is_high_priority_request(request_type):
		# 其它高优先级请求插队时，**不要插到待发的 offline-claim 前面**。
		var insert_at: int = 0
		while insert_at < _request_queue.size() and str(_request_queue[insert_at].get("type", "")) == "economy_offline_claim":
			insert_at += 1
		_request_queue.insert(insert_at, entry)
	else:
		_request_queue.append(entry)
	_process_next_request()

func _process_next_request():
	if _is_processing_request or _request_queue.is_empty():
		print("[Network] _process_next_request: skipped, is_processing=", _is_processing_request, " queue_empty=", _request_queue.is_empty())
		return
	_is_processing_request = true
	_current_request_info = _request_queue.pop_front()
	print("[Network] _process_next_request: processing type=", _current_request_info.get("type", "unknown"))
	_current_request_info. func .call()

func _complete_request():
	_is_processing_request = false
	_process_next_request()

func register(username: String, password: String, nickname: String = ""):
	_enqueue_request("register", func():
		server_url = _primary_api_base
		_pending_register_username = username
		_pending_register_password = password
		_pending_register_nickname = str(nickname).strip_edges()
		var body = {
			"username": username, 
			"password": password, 
			"clientVersion": client_version_header
		}
		# 角色名改为「登录后创建角色」时再填：这里留空就不传，服务端会存成空名，
		# 客户端据此在进入游戏时弹出创建角色面板
		if _pending_register_nickname != "":
			body["nickname"] = _pending_register_nickname
		var json = JSON.stringify(body)
		var headers = _build_headers(false, true)
		print("[Network] Sending register request to: ", server_url + "/register")
		print("[Network] Request body: ", json)
		var err = http_request.request(server_url + "/register", headers, HTTPClient.METHOD_POST, json)
		print("[Network] Request error code: ", err)
		if err != OK:
			_emit_register_failed("网络请求失败")
			_complete_request()
	)

func login(username: String, password: String):
	_enqueue_request("login", func():
		server_url = _primary_api_base
		_pending_login_username = username
		_pending_login_password = password
		var body = {
			"username": username, 
			"password": password, 
			"clientVersion": client_version_header
		}
		var json = JSON.stringify(body)
		var headers = _build_headers(false, true)
		var err = http_request.request(server_url + "/login", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			_emit_login_failed("网络请求失败")
			_complete_request()
	)

func get_user_info():
	if auth_token == "":
		return
	_enqueue_request("user_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/user/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			_complete_request()
	)


func request_mail_list() -> void :
	if auth_token == "":
		mail_list_via_network_response.emit(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())
		return
	_enqueue_request("mail_list", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/mail/list", headers, HTTPClient.METHOD_GET)
		if err != OK:
			mail_list_via_network_response.emit(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())
			_complete_request()
	)

func download_save():
	if auth_token == "":

		call_deferred("emit_signal", "save_downloaded", null)
		return
	_enqueue_request("download_save", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/save/download", headers, HTTPClient.METHOD_GET)
		if err != OK:

			call_deferred("emit_signal", "save_downloaded", null)
			_complete_request()
	)

func get_ranking():
	_enqueue_request("ranking", func():
		var err = http_request.request(server_url + "/ranking", ["Content-Type: application/json"], HTTPClient.METHOD_GET)
		if err != OK:
			ranking_loaded.emit([])
			_complete_request()
	)

func get_ranking_players():
	_enqueue_request("ranking_players", func():
		var err = http_request.request(server_url + "/ranking/players", ["Content-Type: application/json"], HTTPClient.METHOD_GET)
		if err != OK:
			ranking_players_loaded.emit([])
			_complete_request()
	)

func get_ranking_pets():
	get_ranking_pets_evolution()

func get_ranking_pets_evolution():
	_enqueue_request("ranking_pets_evolution", func():
		var err = http_request.request(server_url + "/ranking/pets/evolution", ["Content-Type: application/json"], HTTPClient.METHOD_GET)
		if err != OK:
			ranking_pets_loaded.emit([], "pets_evolution")
			_complete_request()
	)

func get_ranking_pets_non_evolution():
	_enqueue_request("ranking_pets_non_evolution", func():
		var err = http_request.request(server_url + "/ranking/pets/non-evolution", ["Content-Type: application/json"], HTTPClient.METHOD_GET)
		if err != OK:
			ranking_pets_loaded.emit([], "pets_non_evolution")
			_complete_request()
	)

func get_tower_ranking():
	if auth_token == "":
		ranking_loaded.emit([])
		return
	_enqueue_request("ranking_tower", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var url = server_url + "/tower/ranking"
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			ranking_loaded.emit([])
			_complete_request()
	)

func get_suit_dungeon_ranking():
	if auth_token == "":
		ranking_suit_dungeon_loaded.emit([])
		return
	_enqueue_request("ranking_suit_dungeon", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var url = server_url + "/suit-dungeon/ranking"
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			ranking_suit_dungeon_loaded.emit([])
			_complete_request()
	)

func get_vip_info():
	print("[Network] get_vip_info() 被调用")
	if auth_token == "":
		print("[Network] 未登录，跳过VIP信息获取")
		vip_info_failed.emit("未登录，无法获取VIP信息")
		return
	_enqueue_request("vip_info", func():
		print("[Network] 发送VIP信息请求到 /user/info")
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/user/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			print("[Network] VIP信息请求失败，错误码:", err)
			vip_info_failed.emit("VIP信息请求失败")
			_complete_request()
	)

func get_tower_info():
	if auth_token == "":
		tower_info_loaded.emit(0, 0, 0)
		return
	_enqueue_request("tower_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/tower/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			tower_info_loaded.emit(0, 0, 0)
			_complete_request()
	)

func update_tower_highest(highest_floor: int):
	if auth_token == "":
		return
	_enqueue_request("tower_update", func():
		var body = {"highestFloor": highest_floor}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/tower/update", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			_complete_request()
	)

func mark_tower_sweep():
	if auth_token == "":
		tower_sweep_failed.emit("未登录")
		return
	_enqueue_request("tower_sweep", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/tower/sweep", headers, HTTPClient.METHOD_POST)
		if err != OK:
			_complete_request()
	)

func get_suit_dungeon_info():
	if auth_token == "":
		suit_dungeon_info_loaded.emit(0, 3)
		return
	_enqueue_request("suit_dungeon_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/suit-dungeon/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			suit_dungeon_info_loaded.emit(0, 3)
			_complete_request()
	)

func use_suit_dungeon_sweep():
	if auth_token == "":
		suit_dungeon_sweep_failed.emit("未登录")
		return
	_enqueue_request("suit_dungeon_sweep", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/suit-dungeon/sweep", headers, HTTPClient.METHOD_POST)
		if err != OK:
			_complete_request()
	)

func get_fe_dungeon_status():
	if auth_token == "":
		fe_dungeon_status_failed.emit("未登录")
		return
	_enqueue_request("fe_dungeon_status", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/five-elements-dungeon/status", headers, HTTPClient.METHOD_GET)
		if err != OK:
			fe_dungeon_status_failed.emit("请求失败")
			_complete_request()
	)

func start_fe_dungeon(element: String, difficulty: String, operation_id: String, is_yuanbao: bool = false):
	var rid: = str(operation_id)
	if auth_token == "":
		fe_dungeon_start_failed.emit("未登录")
		economy_result.emit(rid, "fe_dungeon_start", false, {}, "未登录")
		return
	var body = JSON.stringify({"element": element, "difficulty": difficulty, "operationId": operation_id, "yuanbao": is_yuanbao})
	_enqueue_fe_dungeon_dedicated("fe_dungeon_start", "/five-elements-dungeon/start", body, rid)

func get_atlas_dungeon_status():
	if auth_token == "":
		atlas_dungeon_status_failed.emit("未登录")
		return
	_enqueue_request("atlas_dungeon_status", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/atlas-dungeon/status", headers, HTTPClient.METHOD_GET)
		if err != OK:
			atlas_dungeon_status_failed.emit("请求失败")
			_complete_request()
	)

func start_atlas_dungeon(tier: String, operation_id: String):
	if auth_token == "":
		atlas_dungeon_start_failed.emit("未登录")
		return
	var body = JSON.stringify({"tier": tier, "operationId": operation_id})
	_enqueue_request("atlas_dungeon_start", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/atlas-dungeon/start", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			atlas_dungeon_start_failed.emit("请求失败")
			_complete_request()
	)

func get_brother_tower_poll(scope: String = "lobby"):
	if auth_token == "":
		brother_tower_poll_failed.emit("未登录")
		return
	var safe_scope: = scope.strip_edges().to_lower()
	if safe_scope != "lobby" and safe_scope != "in_room" and safe_scope != "battle":
		safe_scope = "lobby"
	_last_brother_tower_poll_scope = safe_scope
	_enqueue_request("brother_tower_poll", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var url: = server_url + "/brother-tower/poll?scope=" + safe_scope.uri_encode()
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			brother_tower_poll_failed.emit("请求失败")
			_complete_request()
	)

func get_brother_tower_list():
	if auth_token == "":
		brother_tower_list_failed.emit("未登录")
		return
	_enqueue_request("brother_tower_list", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/list", headers, HTTPClient.METHOD_GET)
		if err != OK:
			brother_tower_list_failed.emit("请求失败")
			_complete_request()
	)

func get_brother_tower_status():
	if auth_token == "":
		return
	_enqueue_request("brother_tower_status", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		http_request.request(server_url + "/brother-tower/status", headers, HTTPClient.METHOD_GET)
	)

func brother_tower_create(operation_id: String, difficulty: String = "easy", join_mode: String = "auto"):
	if auth_token == "":
		brother_tower_create_failed.emit("未登录")
		return
	var mode: = str(join_mode).strip_edges().to_lower()
	if mode != "review":
		mode = "auto"
	var body = JSON.stringify({"operationId": operation_id, "difficulty": difficulty, "joinMode": mode})
	_enqueue_request("brother_tower_create", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/create", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			brother_tower_create_failed.emit("请求失败")
			_complete_request()
	)

func brother_tower_join(room_id: int, operation_id: String, local_snapshot: Dictionary = {}):
	if auth_token == "":
		brother_tower_join_failed.emit("未登录")
		return
	var payload: = {"roomId": room_id, "operationId": operation_id}
	if local_snapshot is Dictionary and not local_snapshot.is_empty():
		payload["localSnapshot"] = local_snapshot
	var body = JSON.stringify(payload)
	_enqueue_request("brother_tower_join", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/join", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			brother_tower_join_failed.emit("请求失败")
			_complete_request()
	)

func brother_tower_decide_application(room_id: int, user_id: int, approve: bool):
	if auth_token == "":
		brother_tower_application_decide_failed.emit("未登录")
		return
	var payload: = {"roomId": room_id, "userId": user_id, "approve": approve}
	var body = JSON.stringify(payload)
	_enqueue_request("brother_tower_application_decide", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/application/decide", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			brother_tower_application_decide_failed.emit("请求失败")
			_complete_request()
	)

func brother_tower_leave():
	if auth_token == "":
		return
	_enqueue_request("brother_tower_leave", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		http_request.request(server_url + "/brother-tower/leave", headers, HTTPClient.METHOD_POST, "{}")
	)

func brother_tower_disband():
	if auth_token == "":
		return
	_enqueue_request("brother_tower_disband", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		http_request.request(server_url + "/brother-tower/disband", headers, HTTPClient.METHOD_POST, "{}")
	)

func get_shengsi_tower_window():
	if auth_token == "":
		shengsi_tower_window_failed.emit("未登录")
		return
	_shengsi_start_get("window")

func get_shengsi_tower_overview():
	if auth_token == "":
		shengsi_tower_overview_failed.emit("未登录")
		return
	_shengsi_start_get("overview")

func _shengsi_window_busy() -> bool:
	return shengsi_window_request != null and shengsi_window_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED

func _shengsi_start_get(kind: String) -> void :
	if shengsi_window_request == null:
		if kind == "overview":
			shengsi_tower_overview_failed.emit("请求失败")
		else:
			shengsi_tower_window_failed.emit("请求失败")
		return
	if _shengsi_window_busy():
		if kind == "overview":
			_shengsi_overview_pending = true
		return
	_shengsi_fire_get(kind)

func _shengsi_fire_get(kind: String) -> void :
	_shengsi_get_kind = kind
	var headers: = _build_headers(true, true)
	var path: = "/shengsi-tower/window" if kind == "window" else "/shengsi-tower/overview"
	var err: = shengsi_window_request.request(server_url + path, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_get_kind = ""
		if kind == "overview":
			shengsi_tower_overview_failed.emit("请求失败")
		else:
			shengsi_tower_window_failed.emit("请求失败")

func _on_shengsi_window_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var kind: = _shengsi_get_kind
	_shengsi_get_kind = ""
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if not ok:
		if kind == "overview":
			shengsi_tower_overview_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		else:
			shengsi_tower_window_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	else:
		if kind == "overview":
			shengsi_tower_overview_loaded.emit(data)
		else:
			shengsi_tower_window_loaded.emit(data)
	if _shengsi_overview_pending:
		_shengsi_overview_pending = false
		_shengsi_fire_get("overview")

func _shengsi_parse_http_body(body: PackedByteArray) -> Dictionary:
	var text: = body.get_string_from_utf8()
	if text.strip_edges().is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

func _shengsi_action_post(kind: String, path: String, body: String) -> void :
	if auth_token == "":
		shengsi_tower_action_failed.emit(kind, "未登录")
		return
	if shengsi_action_request == null:
		shengsi_tower_action_failed.emit(kind, "请求失败")
		return
	_shengsi_action_queue.append({"kind": kind, "path": path, "body": body})
	if _shengsi_action_queue.size() > 8:
		_shengsi_action_queue.pop_front()
	_shengsi_pump_action()

func _shengsi_pump_action() -> void :
	if _shengsi_action_busy or _shengsi_action_queue.is_empty() or shengsi_action_request == null:
		return
	if shengsi_action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var job: Dictionary = _shengsi_action_queue.pop_front()
	_shengsi_action_busy = true
	_shengsi_action_kind = str(job.get("kind", ""))
	var headers: = _build_headers(true, true)
	var err: = shengsi_action_request.request(server_url + str(job.get("path", "")), headers, HTTPClient.METHOD_POST, str(job.get("body", "{}")))
	if err != OK:
		_shengsi_action_busy = false
		shengsi_tower_action_failed.emit(_shengsi_action_kind, "请求失败")
		_shengsi_action_kind = ""
		_shengsi_pump_action()

func _on_shengsi_action_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var kind: = _shengsi_action_kind
	_shengsi_action_kind = ""
	_shengsi_action_busy = false
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or not bool(data.get("success", false)):
		shengsi_tower_action_failed.emit(kind, err_msg if not err_msg.is_empty() else "操作失败")
	else:
		shengsi_tower_action_success.emit(kind, data)
	_shengsi_pump_action()

func get_shengsi_tower_floor(floor: int):
	if auth_token == "":
		shengsi_tower_floor_failed.emit("未登录")
		return
	if shengsi_floor_request == null:
		shengsi_tower_floor_failed.emit("请求失败")
		return
	var fl: = int(floor)
	if shengsi_floor_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_floor_pending = fl
		return
	_shengsi_fire_floor(fl)

func _shengsi_fire_floor(floor: int) -> void :
	_shengsi_floor_num = floor
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/floor?floor=" + str(floor)
	var err: = shengsi_floor_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_floor_num = 0
		shengsi_tower_floor_failed.emit("请求失败")

func _on_shengsi_floor_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_floor_loaded.emit(data)
	else:
		shengsi_tower_floor_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	var pending: = _shengsi_floor_pending
	_shengsi_floor_pending = -1
	if pending >= 1:
		_shengsi_fire_floor(pending)

func get_shengsi_tower_feed(since_id: int = 0, floor: int = 0):
	if auth_token == "":
		shengsi_tower_feed_failed.emit("未登录")
		return
	if shengsi_feed_request == null:
		shengsi_tower_feed_failed.emit("请求失败")
		return
	var fl: = int(floor)
	if fl <= 0:
		fl = int(since_id) if int(since_id) >= 1 and int(since_id) <= 5 else 0
	if shengsi_feed_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_feed_pending_floor = fl
		return
	_shengsi_fire_feed(fl)

func _shengsi_fire_feed(floor: int) -> void :
	_shengsi_feed_floor = floor
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/feed"
	if floor > 0:
		url += "?floor=" + str(floor)
	var err: = shengsi_feed_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_feed_floor = 0
		shengsi_tower_feed_failed.emit("请求失败")

func _on_shengsi_feed_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_feed_loaded.emit(data)
	else:
		shengsi_tower_feed_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	var pending: = _shengsi_feed_pending_floor
	_shengsi_feed_pending_floor = -1
	if pending >= 0:
		_shengsi_fire_feed(pending)

func get_shengsi_tower_room_list(floor: int = 0):
	if auth_token == "":
		shengsi_tower_room_list_failed.emit("未登录")
		return
	if shengsi_room_list_request == null:
		shengsi_tower_room_list_failed.emit("请求失败")
		return
	var fl: = int(floor)
	if shengsi_room_list_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_room_list_pending_floor = fl
		return
	_shengsi_fire_room_list(fl)

func _shengsi_fire_room_list(floor: int) -> void :
	_shengsi_room_list_floor = floor
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/room/list"
	if floor > 0:
		url += "?floor=" + str(floor)
	var err: = shengsi_room_list_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_room_list_floor = 0
		shengsi_tower_room_list_failed.emit("请求失败")

func _on_shengsi_room_list_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_room_list_loaded.emit(data)
	else:
		shengsi_tower_room_list_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	var pending: = _shengsi_room_list_pending_floor
	_shengsi_room_list_pending_floor = -1
	if pending >= 0:
		_shengsi_fire_room_list(pending)

func shengsi_tower_room_create(snapshot: Dictionary = {}):
	if auth_token == "":
		shengsi_tower_action_failed.emit("room_create", "未登录")
		return
	var payload: = {}
	if snapshot is Dictionary and not snapshot.is_empty():
		payload["snapshot"] = snapshot
	_shengsi_action_post("room_create", "/shengsi-tower/room/create", JSON.stringify(payload))

func shengsi_tower_room_join(room_id: int, snapshot: Dictionary = {}):
	if auth_token == "":
		shengsi_tower_action_failed.emit("room_join", "未登录")
		return
	var payload: = {"roomId": room_id}
	if snapshot is Dictionary and not snapshot.is_empty():
		payload["snapshot"] = snapshot
	_shengsi_action_post("room_join", "/shengsi-tower/room/join", JSON.stringify(payload))

func shengsi_tower_room_leave():
	_shengsi_action_post("room_leave", "/shengsi-tower/room/leave", "{}")

func shengsi_tower_room_disband():
	_shengsi_action_post("room_disband", "/shengsi-tower/room/disband", "{}")

func shengsi_tower_room_heartbeat():
	if auth_token == "":
		return
	_enqueue_request("shengsi_tower_room_heartbeat", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		http_request.request(server_url + "/shengsi-tower/room/heartbeat", headers, HTTPClient.METHOD_POST, "{}")
	)

func shengsi_tower_register():
	_shengsi_action_post("register", "/shengsi-tower/register", "{}")

func shengsi_tower_pin_snapshot(local_snapshot: Dictionary, operation_id: String):
	if operation_id.strip_edges().is_empty():
		shengsi_tower_action_failed.emit("pin_snapshot", "参数无效")
		return
	var payload: = {
		"operationId": operation_id, 
		"localSnapshot": local_snapshot if local_snapshot is Dictionary else {}, 
	}
	_shengsi_action_post("pin_snapshot", "/shengsi-tower/pin-snapshot", JSON.stringify(payload))

func shengsi_tower_unregister():
	_shengsi_action_post("unregister", "/shengsi-tower/unregister", "{}")

func get_shengsi_tower_round_matchup(include_log: bool = false):
	if auth_token == "":
		shengsi_tower_matchup_failed.emit("未登录")
		return
	if shengsi_matchup_request == null:
		shengsi_tower_matchup_failed.emit("请求失败")
		return
	if shengsi_matchup_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_matchup_pending = true
		if include_log:
			_shengsi_matchup_pending_include_log = true
		return
	_shengsi_fire_matchup(include_log)

func _shengsi_fire_matchup(include_log: bool = false) -> void :
	_shengsi_matchup_include_log = include_log
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/round/matchup"
	if include_log:
		url += "?includeLog=1"
	var err: = shengsi_matchup_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_matchup_include_log = false
		shengsi_tower_matchup_failed.emit("请求失败")

func _on_shengsi_matchup_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_matchup_loaded.emit(data)
	else:
		shengsi_tower_matchup_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	if _shengsi_matchup_pending:
		_shengsi_matchup_pending = false
		var want_log: = _shengsi_matchup_pending_include_log
		_shengsi_matchup_pending_include_log = false
		_shengsi_fire_matchup(want_log)

func shengsi_tower_round_stance(stance: String):
	if auth_token == "":
		shengsi_tower_action_failed.emit("stance", "未登录")
		return
	var body = JSON.stringify({"stance": stance})
	_enqueue_request("shengsi_tower_stance", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/shengsi-tower/round/stance", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			shengsi_tower_action_failed.emit("stance", "请求失败")
			_complete_request()
	)

func shengsi_tower_round_ready():
	if auth_token == "":
		shengsi_tower_action_failed.emit("ready", "未登录")
		return
	_enqueue_request("shengsi_tower_ready", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/shengsi-tower/round/ready", headers, HTTPClient.METHOD_POST, "{}")
		if err != OK:
			shengsi_tower_action_failed.emit("ready", "请求失败")
			_complete_request()
	)

func get_shengsi_tower_my_battles():
	if auth_token == "":
		shengsi_tower_my_battles_failed.emit("未登录")
		return
	_enqueue_request("shengsi_tower_my_battles", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/shengsi-tower/my-battles", headers, HTTPClient.METHOD_GET)
		if err != OK:
			shengsi_tower_my_battles_failed.emit("请求失败")
			_complete_request()
	)

func get_shengsi_tower_floor_battles(floor: int):
	if auth_token == "":
		shengsi_tower_floor_battles_failed.emit("未登录")
		return
	if shengsi_floor_battles_request == null:
		shengsi_tower_floor_battles_failed.emit("请求失败")
		return
	var fl: = int(floor)
	if fl < 1 or fl > 5:
		shengsi_tower_floor_battles_failed.emit("层号无效")
		return
	if shengsi_floor_battles_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_floor_battles_pending = fl
		return
	_shengsi_fire_floor_battles(fl)

func _shengsi_fire_floor_battles(floor: int) -> void :
	_shengsi_floor_battles_num = floor
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/floor/battles?floor=" + str(floor)
	var err: = shengsi_floor_battles_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_floor_battles_num = 0
		shengsi_tower_floor_battles_failed.emit("请求失败")

func _on_shengsi_floor_battles_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_floor_battles_loaded.emit(data)
	else:
		shengsi_tower_floor_battles_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	var pending: = _shengsi_floor_battles_pending
	_shengsi_floor_battles_pending = -1
	if pending >= 1:
		_shengsi_fire_floor_battles(pending)

func get_shengsi_tower_match(match_id: int):
	if auth_token == "":
		shengsi_tower_match_failed.emit("未登录")
		return
	if shengsi_match_request == null:
		shengsi_tower_match_failed.emit("请求失败")
		return
	var mid: = int(match_id)
	if mid <= 0:
		shengsi_tower_match_failed.emit("场次无效")
		return
	if shengsi_match_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_shengsi_match_pending = mid
		return
	_shengsi_fire_match(mid)

func _shengsi_fire_match(match_id: int) -> void :
	_shengsi_match_id = match_id
	var headers: = _build_headers(true, true)
	var url: = server_url + "/shengsi-tower/match?matchId=" + str(match_id)
	var err: = shengsi_match_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_shengsi_match_id = 0
		shengsi_tower_match_failed.emit("请求失败")

func _on_shengsi_match_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var data: = _shengsi_parse_http_body(body)
	var err_msg: = str(data.get("error", ""))
	var ok: = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and bool(data.get("success", true))
	if ok:
		shengsi_tower_match_loaded.emit(data)
	else:
		shengsi_tower_match_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
	var pending: = _shengsi_match_pending
	_shengsi_match_pending = 0
	if pending > 0:
		_shengsi_fire_match(pending)

func brother_tower_ready(local_snapshot: Dictionary = {}):
	if auth_token == "":
		brother_tower_ready_failed.emit("未登录")
		return
	var body = JSON.stringify({})
	_enqueue_request("brother_tower_ready", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/ready", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			brother_tower_ready_failed.emit("请求失败")
			_complete_request()
	)

func brother_tower_pin_snapshot(local_snapshot: Dictionary, operation_id: String):
	if auth_token == "":
		brother_tower_pin_snapshot_failed.emit("未登录")
		return
	if operation_id.strip_edges().is_empty():
		brother_tower_pin_snapshot_failed.emit("参数无效")
		return
	var body = JSON.stringify({
		"operationId": operation_id, 
		"localSnapshot": local_snapshot if local_snapshot is Dictionary else {}, 
	})
	_enqueue_request("brother_tower_pin_snapshot", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/brother-tower/pin-snapshot", headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			brother_tower_pin_snapshot_failed.emit("请求失败")
			_complete_request()
	)

func brother_tower_start(operation_id: String, local_snapshot: Dictionary = {}):
	if auth_token == "":
		brother_tower_start_failed.emit("未登录")
		return
	var body = JSON.stringify({"operationId": operation_id, "localSnapshot": local_snapshot if local_snapshot is Dictionary else {}})
	_enqueue_brother_tower_start_dedicated(body, operation_id)

func _enqueue_brother_tower_start_dedicated(json_body: String, request_id: String = "") -> void :
	_brother_tower_start_queue.append({"json": json_body, "request_id": request_id})
	_pump_brother_tower_start_dedicated()

func _pump_brother_tower_start_dedicated() -> void :
	if _brother_tower_start_queue.is_empty():
		return
	if brother_tower_start_request == null:
		return
	if brother_tower_start_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		call_deferred("_pump_brother_tower_start_dedicated")
		return
	if auth_token == "":
		_brother_tower_start_queue.pop_front()
		brother_tower_start_failed.emit("未登录")
		call_deferred("_pump_brother_tower_start_dedicated")
		return
	var item: Dictionary = _brother_tower_start_queue[0]
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var err: = brother_tower_start_request.request(
		server_url + "/brother-tower/start", 
		headers, 
		HTTPClient.METHOD_POST, 
		String(item.get("json", ""))
	)
	if err != OK:
		_brother_tower_start_queue.pop_front()
		brother_tower_start_failed.emit("请求失败")
		call_deferred("_pump_brother_tower_start_dedicated")

func _emit_brother_tower_start_parsed(data: Dictionary) -> void :
	if data.get("success", false) and int(data.get("sessionId", 0)) > 0:
		brother_tower_start_success.emit(data)
	else:
		var err_msg: = str(data.get("error", ""))
		brother_tower_start_failed.emit(err_msg if not err_msg.is_empty() else "开始失败")

func _on_brother_tower_start_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if not _brother_tower_start_queue.is_empty():
		_brother_tower_start_queue.pop_front()
	var text: = body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var error_msg: = "网络错误(%d)" % response_code
		if text != "":
			var parsed_err = JSON.parse_string(text)
			if parsed_err is Dictionary and parsed_err.has("error"):
				error_msg = str(parsed_err.get("error", error_msg))
		brother_tower_start_failed.emit(error_msg)
		call_deferred("_pump_brother_tower_start_dedicated")
		return
	var data = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		brother_tower_start_failed.emit("JSON解析失败")
		call_deferred("_pump_brother_tower_start_dedicated")
		return
	_emit_brother_tower_start_parsed(data)
	call_deferred("_pump_brother_tower_start_dedicated")

func wait_brother_tower_start(operation_id: String, local_snapshot: Dictionary = {}) -> Dictionary:
	# lambda 按值捕获局部变量，done/ok/data/err 必须放进 Dictionary 才能跨闭包写回
	var st: = {"done": false, "ok": false, "data": {}, "err": ""}
	var on_ok: = func(d: Dictionary) -> void :
		st.ok = true
		st.data = d if d is Dictionary else {}
		st.done = true
	var on_fail: = func(e: String) -> void :
		st.ok = false
		st.err = e
		st.done = true
	brother_tower_start_success.connect(on_ok, CONNECT_ONE_SHOT)
	brother_tower_start_failed.connect(on_fail, CONNECT_ONE_SHOT)
	brother_tower_start(operation_id, local_snapshot)
	var wait_ms: = int(BROTHER_TOWER_START_HTTP_TIMEOUT_SEC * 1000.0) + 5000
	var deadline_ms: = Time.get_ticks_msec() + wait_ms
	var scene_tree: = Engine.get_main_loop() as SceneTree
	while not bool(st.done) and Time.get_ticks_msec() < deadline_ms:
		if GameManager.instance and GameManager.instance.is_brother_tower_battle:
			return {"ok": true, "data": st.data, "err": ""}
		if scene_tree:
			await scene_tree.process_frame
		elif get_tree():
			await get_tree().process_frame
		else:
			break
	if brother_tower_start_success.is_connected(on_ok):
		brother_tower_start_success.disconnect(on_ok)
	if brother_tower_start_failed.is_connected(on_fail):
		brother_tower_start_failed.disconnect(on_fail)
	if not bool(st.done):
		return {"ok": false, "data": {}, "err": "开始挑战超时，请检查网络后重试"}
	if not bool(st.ok):
		return {"ok": false, "data": st.data, "err": str(st.err) if not str(st.err).is_empty() else "开始失败"}
	return {"ok": true, "data": st.data, "err": ""}

func get_brother_tower_session(lite: bool = false):
	if auth_token == "":
		return
	var url: = server_url + "/brother-tower/session"
	if lite:
		url += "?lite=1"
	_enqueue_brother_tower_battle_sync_dedicated({
		"kind": "session", 
		"method": HTTPClient.METHOD_GET, 
		"url": url, 
		"body": "", 
	})

func brother_tower_heartbeat(room_id: int, session_id: int):
	if auth_token == "":
		return
	if brother_tower_heartbeat_request == null:
		return
	if brother_tower_heartbeat_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var body = JSON.stringify({"roomId": room_id, "sessionId": session_id})
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	brother_tower_heartbeat_request.request(server_url + "/brother-tower/heartbeat", headers, HTTPClient.METHOD_POST, body)

func _on_brother_tower_heartbeat_dedicated_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var data = json.data
	if data is Dictionary:
		_dispatch_brother_tower_response("brother_tower_heartbeat", data)

func brother_tower_wave_cleared(session_id: int, wave: int):
	if auth_token == "":
		brother_tower_wave_cleared_failed.emit("未登录")
		return
	var body = JSON.stringify({"sessionId": session_id, "wave": wave})
	_enqueue_brother_tower_battle_sync_dedicated({
		"kind": "wave_cleared", 
		"method": HTTPClient.METHOD_POST, 
		"url": server_url + "/brother-tower/wave-cleared", 
		"body": body, 
	})

func brother_tower_forfeit(session_id: int):
	if auth_token == "":
		return
	var body = JSON.stringify({"sessionId": session_id})
	_enqueue_request("brother_tower_forfeit", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		http_request.request(server_url + "/brother-tower/forfeit", headers, HTTPClient.METHOD_POST, body)
	)

func brother_tower_complete(session_id: int, operation_id: String):
	if auth_token == "":
		brother_tower_complete_failed.emit("未登录")
		return
	var body = JSON.stringify({"sessionId": session_id, "operationId": operation_id})
	_enqueue_brother_tower_complete_dedicated(body, operation_id)

func _enqueue_brother_tower_complete_dedicated(json_body: String, request_id: String = "") -> void :
	_brother_tower_complete_queue.append({"json": json_body, "request_id": request_id})
	_pump_brother_tower_complete_dedicated()

func _pump_brother_tower_complete_dedicated() -> void :
	if _brother_tower_complete_queue.is_empty():
		return
	if brother_tower_complete_request == null:
		return
	if brother_tower_complete_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		call_deferred("_pump_brother_tower_complete_dedicated")
		return
	if auth_token == "":
		var fail_item: Dictionary = _brother_tower_complete_queue.pop_front()
		brother_tower_complete_failed.emit("未登录")
		call_deferred("_pump_brother_tower_complete_dedicated")
		return
	var item: Dictionary = _brother_tower_complete_queue[0]
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var err: = brother_tower_complete_request.request(
		server_url + "/brother-tower/complete", 
		headers, 
		HTTPClient.METHOD_POST, 
		String(item.get("json", ""))
	)
	if err != OK:
		_brother_tower_complete_queue.pop_front()
		brother_tower_complete_failed.emit("请求失败")
		call_deferred("_pump_brother_tower_complete_dedicated")

func _emit_brother_tower_complete_parsed(data: Dictionary) -> void :
	if data.get("success", false):
		if GameManager.instance and GameManager.instance.player and not bool(data.get("duplicate", false)):
			var fg: = int(data.get("friendshipGain", 0))
			if fg > 0:
				GameManager.instance.player.friendship_points += fg
		brother_tower_complete_success.emit(data)
	else:
		var err_msg: = str(data.get("error", "结算失败"))
		brother_tower_complete_failed.emit(err_msg)

func _on_brother_tower_complete_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if not _brother_tower_complete_queue.is_empty():
		_brother_tower_complete_queue.pop_front()
	var text: = body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var error_msg: = "网络错误(%d)" % response_code
		if text != "":
			var parsed_err = JSON.parse_string(text)
			if parsed_err is Dictionary and parsed_err.has("error"):
				error_msg = str(parsed_err.get("error", error_msg))
		brother_tower_complete_failed.emit(error_msg)
		call_deferred("_pump_brother_tower_complete_dedicated")
		return
	var data = JSON.parse_string(text)
	if data == null:
		brother_tower_complete_failed.emit("JSON解析失败")
		call_deferred("_pump_brother_tower_complete_dedicated")
		return
	if not data is Dictionary:
		brother_tower_complete_failed.emit("服务器返回数据格式错误")
		call_deferred("_pump_brother_tower_complete_dedicated")
		return
	_emit_brother_tower_complete_parsed(data)
	call_deferred("_pump_brother_tower_complete_dedicated")

func wait_brother_tower_complete(session_id: int, operation_id: String, max_wait_sec: float = -1.0) -> Dictionary:
	var st: = {"done": false, "ok": false, "data": {}, "err": ""}
	var on_ok: = func(d: Dictionary) -> void :
		st.ok = true
		st.data = d if d is Dictionary else {}
		st.done = true
	var on_fail: = func(e: String) -> void :
		st.ok = false
		st.err = e
		st.done = true
	brother_tower_complete_success.connect(on_ok, CONNECT_ONE_SHOT)
	brother_tower_complete_failed.connect(on_fail, CONNECT_ONE_SHOT)
	brother_tower_complete(session_id, operation_id)
	var wait_budget_sec: = BROTHER_TOWER_COMPLETE_HTTP_TIMEOUT_SEC if max_wait_sec <= 0.0 else maxf(0.5, max_wait_sec)
	var wait_ms: = int(wait_budget_sec * 1000.0) + (500 if max_wait_sec <= 0.0 else 200)
	var deadline_ms: = Time.get_ticks_msec() + wait_ms
	var scene_tree: = Engine.get_main_loop() as SceneTree
	while not bool(st.done) and Time.get_ticks_msec() < deadline_ms:
		if scene_tree:
			await scene_tree.process_frame
		elif get_tree():
			await get_tree().process_frame
		else:
			break
	if brother_tower_complete_success.is_connected(on_ok):
		brother_tower_complete_success.disconnect(on_ok)
	if brother_tower_complete_failed.is_connected(on_fail):
		brother_tower_complete_failed.disconnect(on_fail)
	if not bool(st.done):
		var timeout_err: = "兄弟天关结算超时，请检查网络后重试"
		brother_tower_complete_failed.emit(timeout_err)
		return {"ok": false, "data": {}, "err": timeout_err}
	if not bool(st.ok):
		return {"ok": false, "data": st.data, "err": str(st.err) if not str(st.err).is_empty() else "结算失败"}
	return {"ok": true, "data": st.data, "err": ""}

func _enqueue_brother_tower_battle_sync_dedicated(entry: Dictionary) -> void :
	_brother_tower_battle_sync_queue.append(entry)
	_schedule_brother_tower_battle_sync_pump()

func _schedule_brother_tower_battle_sync_pump() -> void :
	if _brother_tower_battle_sync_pump_scheduled:
		return
	_brother_tower_battle_sync_pump_scheduled = true
	call_deferred("_pump_brother_tower_battle_sync_dedicated")

func _arm_brother_tower_battle_sync_watchdog() -> void :
	if _brother_tower_battle_sync_watchdog == null:
		return
	_brother_tower_battle_sync_watchdog.stop()
	_brother_tower_battle_sync_watchdog.wait_time = BROTHER_TOWER_BATTLE_SYNC_HTTP_TIMEOUT_SEC + 1.0
	_brother_tower_battle_sync_watchdog.start()

func _stop_brother_tower_battle_sync_watchdog() -> void :
	if _brother_tower_battle_sync_watchdog != null and is_instance_valid(_brother_tower_battle_sync_watchdog):
		_brother_tower_battle_sync_watchdog.stop()

func _on_brother_tower_battle_sync_watchdog_timeout() -> void :
	if brother_tower_battle_sync_request == null:
		return
	if brother_tower_battle_sync_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		return
	var stuck_gen: = _brother_tower_battle_sync_request_gen
	print("[Network] BT battle-sync watchdog cancel stuck request gen=%d" % stuck_gen)
	brother_tower_battle_sync_request.cancel_request()

	var tree: = get_tree()
	if tree:
		var t: = tree.create_timer(0.6)
		t.timeout.connect( func() -> void :
			if stuck_gen != _brother_tower_battle_sync_request_gen:
				return
			if brother_tower_battle_sync_request == null:
				return
			if brother_tower_battle_sync_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
				return
			if _brother_tower_battle_sync_queue.is_empty():
				return
			var item: Dictionary = _brother_tower_battle_sync_queue.pop_front()
			_brother_tower_battle_sync_request_gen += 1
			_fail_brother_tower_battle_sync_item(item, "请求超时")
			_schedule_brother_tower_battle_sync_pump()
		, CONNECT_ONE_SHOT)

func _pump_brother_tower_battle_sync_dedicated() -> void :
	_brother_tower_battle_sync_pump_scheduled = false
	if _brother_tower_battle_sync_queue.is_empty():
		return
	if brother_tower_battle_sync_request == null:
		return

	if brother_tower_battle_sync_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	if auth_token == "":
		var fail_item: Dictionary = _brother_tower_battle_sync_queue.pop_front()
		_fail_brother_tower_battle_sync_item(fail_item, "未登录")
		_schedule_brother_tower_battle_sync_pump()
		return
	var item: Dictionary = _brother_tower_battle_sync_queue[0]
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var method: = int(item.get("method", HTTPClient.METHOD_GET))
	var url: = str(item.get("url", ""))
	var body: = str(item.get("body", ""))
	var err: = brother_tower_battle_sync_request.request(url, headers, method, body)
	if err != OK:
		_brother_tower_battle_sync_queue.pop_front()
		_fail_brother_tower_battle_sync_item(item, "请求失败")
		_schedule_brother_tower_battle_sync_pump()
		return
	_arm_brother_tower_battle_sync_watchdog()

func _fail_brother_tower_battle_sync_item(item: Dictionary, err_msg: String) -> void :
	var kind: = str(item.get("kind", ""))
	match kind:
		"session":
			brother_tower_session_loaded.emit({"success": false, "error": err_msg, "session": {}})
		"wave_cleared":
			brother_tower_wave_cleared_failed.emit(err_msg)

		"push":
			_dispatch_bt_push_result({"success": false, "error": err_msg})
		"fetch":
			_dispatch_bt_fetch_result({"success": false, "error": err_msg, "events": []})

func _on_brother_tower_battle_sync_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	_stop_brother_tower_battle_sync_watchdog()
	_brother_tower_battle_sync_request_gen += 1
	var item: Dictionary = {}
	if not _brother_tower_battle_sync_queue.is_empty():
		item = _brother_tower_battle_sync_queue.pop_front()
	var kind: = str(item.get("kind", ""))
	var text: = body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var error_msg: = "网络错误(%d)" % response_code
		if text != "":
			var parsed_err = JSON.parse_string(text)
			if parsed_err is Dictionary and parsed_err.has("error"):
				error_msg = str(parsed_err.get("error", error_msg))
		_fail_brother_tower_battle_sync_item(item, error_msg)
		_schedule_brother_tower_battle_sync_pump()
		return
	var data = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		_fail_brother_tower_battle_sync_item(item, "JSON解析失败")
		_schedule_brother_tower_battle_sync_pump()
		return
	match kind:
		"session":
			_dispatch_brother_tower_response("brother_tower_session", data)
		"wave_cleared":
			_dispatch_brother_tower_response("brother_tower_wave_cleared", data)
		"push":
			_dispatch_brother_tower_response("brother_tower_battle_events_push", data)
		"fetch":
			_dispatch_brother_tower_response("brother_tower_battle_events_fetch", data)
		_:
			push_warning("[Network] BT battle-sync unknown kind=%s" % kind)
	_schedule_brother_tower_battle_sync_pump()

func brother_tower_push_battle_events(session_id: int, operation_id: String, events: Array):
	if auth_token == "":
		return
	var body = JSON.stringify({"sessionId": session_id, "operationId": operation_id, "events": events})
	_enqueue_brother_tower_battle_sync_dedicated({
		"kind": "push", 
		"method": HTTPClient.METHOD_POST, 
		"url": server_url + "/brother-tower/battle-events", 
		"body": body, 
	})

func _next_bt_waiter_token() -> int:
	_bt_waiter_token_seq += 1
	return _bt_waiter_token_seq

func wait_brother_tower_push_battle_events(session_id: int, operation_id: String, events: Array) -> Dictionary:
	if auth_token == "":
		return {"ok": false, "data": {}, "err": "未登录"}
	var token: = _next_bt_waiter_token()
	var waiter: = {"done": false, "data": {}, "token": token, "cancelled": false}
	_bt_push_waiters.append(waiter)
	brother_tower_push_battle_events(session_id, operation_id, events)
	var elapsed: = 0.0
	var wait_budget: = BROTHER_TOWER_BATTLE_SYNC_HTTP_TIMEOUT_SEC + 1.0
	while not bool(waiter.get("done", false)) and elapsed < wait_budget:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	if not bool(waiter.get("done", false)):
		waiter["cancelled"] = true
		_remove_bt_push_waiter(waiter)
		return {"ok": false, "data": {}, "err": "上报超时"}
	var data: Dictionary = waiter.get("data", {}) if waiter.get("data") is Dictionary else {}
	if not data.get("success", false):
		return {"ok": false, "data": data, "err": str(data.get("error", ""))}
	return {"ok": true, "data": data, "err": ""}

func brother_tower_fetch_battle_events(session_id: int, since_seq: int):
	if auth_token == "":
		return
	var url: = server_url + "/brother-tower/battle-events?sessionId=%d&sinceSeq=%d" % [session_id, since_seq]
	print("[Network] BT fetch 入队(专用通道) session=%d since=%d" % [session_id, since_seq])
	_enqueue_brother_tower_battle_sync_dedicated({
		"kind": "fetch", 
		"method": HTTPClient.METHOD_GET, 
		"url": url, 
		"body": "", 
	})

func _dispatch_bt_fetch_result(data: Dictionary) -> void :
	brother_tower_battle_events_fetched.emit(data)
	while not _bt_fetch_waiters.is_empty():
		var waiter: Dictionary = _bt_fetch_waiters.pop_front()
		if bool(waiter.get("cancelled", false)):
			continue
		waiter["done"] = true
		waiter["data"] = data
		return

func _dispatch_bt_push_result(data: Dictionary) -> void :
	brother_tower_battle_events_pushed.emit(data)
	while not _bt_push_waiters.is_empty():
		var waiter: Dictionary = _bt_push_waiters.pop_front()
		if bool(waiter.get("cancelled", false)):
			continue
		waiter["done"] = true
		waiter["data"] = data
		return

func _remove_bt_fetch_waiter(waiter: Dictionary) -> void :
	var idx: = _bt_fetch_waiters.find(waiter)
	if idx >= 0:
		_bt_fetch_waiters.remove_at(idx)

func _remove_bt_push_waiter(waiter: Dictionary) -> void :
	var idx: = _bt_push_waiters.find(waiter)
	if idx >= 0:
		_bt_push_waiters.remove_at(idx)

func wait_brother_tower_fetch_battle_events(session_id: int, since_seq: int) -> Dictionary:
	if auth_token == "":
		return {"ok": false, "data": {}, "err": "未登录", "events": []}
	var token: = _next_bt_waiter_token()
	var waiter: = {"done": false, "data": {}, "token": token, "cancelled": false}
	_bt_fetch_waiters.append(waiter)
	brother_tower_fetch_battle_events(session_id, since_seq)
	var elapsed: = 0.0
	var wait_budget: = BROTHER_TOWER_BATTLE_SYNC_HTTP_TIMEOUT_SEC + 1.0
	while not bool(waiter.get("done", false)) and elapsed < wait_budget:
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	if not bool(waiter.get("done", false)):
		waiter["cancelled"] = true
		_remove_bt_fetch_waiter(waiter)
		return {"ok": false, "data": {}, "err": "拉取超时", "events": []}
	var data: Dictionary = waiter.get("data", {}) if waiter.get("data") is Dictionary else {}
	if not data.get("success", false):
		return {"ok": false, "data": data, "err": str(data.get("error", "拉取失败")), "events": []}
	return {"ok": true, "data": data, "err": "", "events": data.get("events", [])}

func fe_dungeon_clear_reward(element: String, difficulty: String, operation_id: String, is_yuanbao: bool = false, request_id: String = "", session_id: String = ""):
	var rid: = request_id if request_id != "" else operation_id
	if auth_token == "":
		fe_dungeon_clear_failed.emit("未登录")
		economy_result.emit(rid, "fe_dungeon_clear", false, {}, "未登录")
		return
	var body = JSON.stringify({
		"element": element, 
		"difficulty": difficulty, 
		"operationId": operation_id, 
		"yuanbao": is_yuanbao, 
		"sessionId": session_id, 
	})
	_enqueue_fe_dungeon_dedicated("fe_dungeon_clear", "/five-elements-dungeon/clear", body, rid)

func get_martial_info():
	if auth_token == "":
		martial_info_failed.emit("未登录")
		return
	_enqueue_request("martial_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/martial/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			martial_info_failed.emit("网络请求失败")
			_complete_request()
	)

func create_martial_art(operation_id: String = ""):
	if auth_token == "":
		martial_create_failed.emit("未登录")
		return
	_enqueue_request("martial_create", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var body = {}
		if operation_id != "":
			body["operationId"] = operation_id
		var json = JSON.stringify(body)
		var err = http_request.request(server_url + "/martial/create", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			martial_create_failed.emit("网络请求失败")
			_complete_request()
	)

func request_martial_skill_book_use(book_name: String, operation_id: String) -> void :
	if auth_token == "":
		martial_skill_book_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		martial_skill_book_failed.emit("请求通道初始化失败")
		return
	_enqueue_request("martial_skill_book_use", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var body = {
			"bookName": book_name, 
			"operationId": operation_id, 
		}
		var json = JSON.stringify(body)
		var err = http_request.request(server_url + "/martial/skill_book_use", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			martial_skill_book_failed.emit("网络请求失败")
			_complete_request()
	)

func pet_merge(main_pet_id: String, sub_pet_id: String, operation_id: String, use_transform_charm: bool = false):
	if auth_token == "":
		pet_merge_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_merge_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_merge_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"mainPetId": main_pet_id, 
		"subPetId": sub_pet_id, 
		"operationId": operation_id, 
		"useTransformCharm": use_transform_charm, 
	}
	_current_action_type = "pet_merge"
	_last_pet_direct_op = "pet_merge"
	var err = action_request.request(server_url + "/pet/merge", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_merge_failed.emit("网络请求失败")

## 把服务端的扁平宠物结果（pet / saveData 摊在顶层）翻译成界面层认识的 result。
## 「成长」在客户端一直是 攻+防+速 三项之和（见 Pet.total_growth），不含气血，
## 所以这里也按同样口径算，界面上显示的成长才会和列表里那个数对得上。
static func _build_flat_pet_result(data: Dictionary) -> Dictionary:
	var pet: Dictionary = data.get("pet", {})
	var gr: Dictionary = pet.get("growth_rates", {})
	var total_growth: float = float(gr.get("attack", 0.0)) + float(gr.get("defense", 0.0)) + float(gr.get("agility", 0.0))
	var out: = {
		"petId": String(pet.get("id", "")), 
		"petName": String(pet.get("name", "")), 
		"newPetName": String(pet.get("name", "")), 
		"newForm": String(pet.get("form", "")), 
		"newGrowth": total_growth, 
		"newGeneration": int(pet.get("generation", 0)), 
		"level": int(pet.get("level", 1)), 
		"mutated": bool(pet.get("is_mutant", false)), 
		"mutation_count": int(pet.get("mutation_count", 0)), 
		"evolution_stage": int(pet.get("evolution_stage", 0)), 
		"learnedSkill": data.get("learnedSkill", null), 
	}
	if data.has("poem"):
		out["poem"] = str(data.get("poem", ""))
	return out


func pet_evolve(pet_id: String, use_mutant: bool, operation_id: String):
	if auth_token == "":
		pet_evolve_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_evolve_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_evolve_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"petId": pet_id, 
		"useMutant": use_mutant, 
		"operationId": operation_id
	}
	_current_action_type = "pet_evolve"
	_last_pet_direct_op = "pet_evolve"
	var err = action_request.request(server_url + "/pet/evolve", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_evolve_failed.emit("网络请求失败")
	else:
		print("[CloudSync] pet_evolve 请求已发出（独立 HTTP，不在主队列），op=", operation_id)

func pet_reincarnate(pet_id: String, element: String, operation_id: String):
	if auth_token == "":
		pet_reincarnation_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_reincarnation_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_reincarnation_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {"petId": pet_id, "element": element, "operationId": operation_id}
	_current_action_type = "pet_reincarnation"
	var err = action_request.request(server_url + "/pet/reincarnate", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_reincarnation_failed.emit("网络请求失败")
	else:
		print("[CloudSync] pet_reincarnate 请求已发出，op=", operation_id)

func pet_reincarnate_inherit(source_id: String, target_id: String, operation_id: String):
	if auth_token == "":
		pet_reincarnation_inherit_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_reincarnation_inherit_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_reincarnation_inherit_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {"sourcePetId": source_id, "targetPetId": target_id, "operationId": operation_id}
	_current_action_type = "pet_reincarnation_inherit"
	var err = action_request.request(server_url + "/pet/reincarnate-inherit", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_reincarnation_inherit_failed.emit("网络请求失败")
	else:
		print("[CloudSync] pet_reincarnate_inherit 请求已发出，op=", operation_id)

func get_player_buffs():
	if auth_token == "":
		player_buffs_loaded.emit({"error": "未登录"})
		return
	var http: = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect( func(_result, _code, _headers, body):
		var data: Dictionary = {}
		if _code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
				_update_server_time_from_response_data(data)
				_apply_newbie_exp_until_from_dict(data)
		else:
			data = {"error": "请求失败(code=%d)" % _code}
		player_buffs_loaded.emit(data)
		http.queue_free()
	)
	var headers = ["Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var err = http.request(server_url + "/api/player/buffs", headers, HTTPClient.METHOD_GET)
	if err != OK:
		player_buffs_loaded.emit({"error": "请求发送失败"})
		http.queue_free()


func _apply_newbie_exp_until_from_dict(data: Dictionary) -> void :
	if data.is_empty() or data.has("error"):
		return
	if GameManager.instance == null or GameManager.instance.player == null:
		return
	var p = GameManager.instance.player
	if data.has("newbie_exp_until"):
		p.newbie_exp_until = maxi(0, int(data.get("newbie_exp_until", 0)))
	if data.has("catchup_enabled"):
		p.catchup_enabled = Player.coerce_bool(data.get("catchup_enabled", false), false)
	if data.has("catchup_first_reincarnation"):
		p.catchup_first_reincarnation = maxi(0, int(data.get("catchup_first_reincarnation", 0)))
	if data.has("catchup_gap"):
		p.catchup_gap = maxi(0, int(data.get("catchup_gap", 0)))
	if data.has("catchup_field_max_level_ups"):
		p.catchup_field_max_level_ups = clampi(int(data.get("catchup_field_max_level_ups", 1)), 1, 10)
	if data.has("catchup_day"):
		p.catchup_day = str(data.get("catchup_day", ""))

func fetch_pet_instance_level(pet_id: String) -> void :
	if auth_token == "":
		pet_instance_level_fetched.emit({"success": false, "error": "未登录"})
		return
	var http: = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect( func(_result, response_code, _headers, body):
		var data: Dictionary = {"success": false, "error": "请求失败(code=%d)" % response_code}
		if response_code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
				data = parsed
		elif response_code == 404:
			data = {"success": false, "error": "接口不存在(404)，请确认服务端已更新"}
		pet_instance_level_fetched.emit(data)
		http.queue_free()
	)
	var headers = ["Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var url: = server_url + "/pet/instance-level?petId=" + str(pet_id).uri_encode()
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		pet_instance_level_fetched.emit({"success": false, "error": "请求发送失败"})
		http.queue_free()

func pet_release(pet_id: String, operation_id: String):
	if auth_token == "":
		pet_release_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_release_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_release_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petId": pet_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_release"
	_last_pet_direct_op = "pet_release"
	var err = action_request.request(server_url + "/pet/release", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_release_failed.emit("网络请求失败")

func request_pet_release_batch(pet_ids: Array, operation_id: String) -> void :
	if auth_token == "":
		pet_release_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_release_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_release_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_ids: Array = []
	var seen: Dictionary = {}
	for raw_id in pet_ids:
		var sid: = str(raw_id).strip_edges()
		if sid.is_empty() or seen.has(sid):
			continue
		seen[sid] = true
		normalized_ids.append(sid)
	if normalized_ids.is_empty():
		pet_release_batch_failed.emit("请选择要放生的宠物")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petIds": normalized_ids, 
		"operationId": operation_id, 
	}
	_current_action_type = "pet_release_batch"
	_last_pet_direct_op = "pet_release_batch"
	var err = action_request.request(server_url + "/pet/release-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_release_batch_failed.emit("网络请求失败")

func pet_bag_store(pet_id: String, operation_id: String):
	if auth_token == "":
		pet_bag_store_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_bag_store_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_bag_store_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petId": pet_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_bag_store"
	_last_pet_direct_op = "pet_bag_store"
	var err = action_request.request(server_url + "/pet/bag/store", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_bag_store_failed.emit("网络请求失败")

func pet_bag_retrieve(pet_id: String, operation_id: String):
	if auth_token == "":
		pet_bag_retrieve_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_bag_retrieve_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_bag_retrieve_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petId": pet_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_bag_retrieve"
	_last_pet_direct_op = "pet_bag_retrieve"
	var err = action_request.request(server_url + "/pet/bag/retrieve", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_bag_retrieve_failed.emit("网络请求失败")

func request_pet_bag_store_batch(pet_ids: Array, operation_id: String) -> void :
	if auth_token == "":
		pet_bag_store_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_bag_store_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_bag_store_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_ids: Array = []
	var seen: Dictionary = {}
	for raw_id in pet_ids:
		var sid: = str(raw_id).strip_edges()
		if sid.is_empty() or seen.has(sid):
			continue
		seen[sid] = true
		normalized_ids.append(sid)
	if normalized_ids.is_empty():
		pet_bag_store_batch_failed.emit("请选择要存入的宠物")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petIds": normalized_ids, 
		"operationId": operation_id, 
	}
	_current_action_type = "pet_bag_store_batch"
	_last_pet_direct_op = "pet_bag_store_batch"
	var err = action_request.request(server_url + "/pet/bag/store-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_bag_store_batch_failed.emit("网络请求失败")

func request_pet_bag_retrieve_batch(pet_ids: Array, operation_id: String) -> void :
	if auth_token == "":
		pet_bag_retrieve_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_bag_retrieve_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_bag_retrieve_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_ids: Array = []
	var seen: Dictionary = {}
	for raw_id in pet_ids:
		var sid: = str(raw_id).strip_edges()
		if sid.is_empty() or seen.has(sid):
			continue
		seen[sid] = true
		normalized_ids.append(sid)
	if normalized_ids.is_empty():
		pet_bag_retrieve_batch_failed.emit("请选择要取出的宠物")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petIds": normalized_ids, 
		"operationId": operation_id, 
	}
	_current_action_type = "pet_bag_retrieve_batch"
	_last_pet_direct_op = "pet_bag_retrieve_batch"
	var err = action_request.request(server_url + "/pet/bag/retrieve-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_bag_retrieve_batch_failed.emit("网络请求失败")

func pet_assist_equip(pet_id: String, slot_index: int, operation_id: String):
	if auth_token == "":
		pet_assist_equip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_assist_equip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_assist_equip_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petId": pet_id, 
		"slotIndex": slot_index, 
		"operationId": operation_id
	}
	_current_action_type = "pet_assist_equip"
	_last_pet_direct_op = "pet_assist_equip"
	var err = action_request.request(server_url + "/pet/assist/equip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_assist_equip_failed.emit("网络请求失败")

func pet_assist_unequip(slot_index: int, operation_id: String, pet_id: String = ""):
	if auth_token == "":
		pet_assist_unequip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_assist_unequip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_assist_unequip_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"slotIndex": slot_index, 
		"operationId": operation_id
	}
	if not pet_id.is_empty():
		body["petId"] = pet_id
	_current_action_type = "pet_assist_unequip"
	_last_pet_direct_op = "pet_assist_unequip"
	var err = action_request.request(server_url + "/pet/assist/unequip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_assist_unequip_failed.emit("网络请求失败")

func set_current_map(map_name: String, operation_id: String):
	if auth_token == "":
		set_current_map_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		set_current_map_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		set_current_map_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"mapName": map_name, 
		"operationId": operation_id
	}
	_current_action_type = "set_current_map"
	var err = action_request.request(server_url + "/player/set-current-map", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		set_current_map_failed.emit("网络请求失败")

func set_capture_settings(auto_capture_enabled: bool, min_growth_threshold: float, operation_id: String):
	if auth_token == "":
		capture_settings_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		capture_settings_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		capture_settings_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"autoCaptureEnabled": auto_capture_enabled, 
		"minGrowthThreshold": min_growth_threshold, 
		"operationId": operation_id
	}
	_current_action_type = "capture_settings"
	var err = action_request.request(server_url + "/player/capture-settings", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		capture_settings_failed.emit("网络请求失败")

func pet_lock(pet_id: String, locked: bool, operation_id: String):
	if auth_token == "":
		pet_lock_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_lock_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_lock_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petId": pet_id, 
		"locked": locked, 
		"operationId": operation_id
	}
	_current_action_type = "pet_lock"
	var err = action_request.request(server_url + "/pet/lock", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_lock_failed.emit("网络请求失败")

func martial_sync_layout(martial_arts_data: Dictionary, operation_id: String):
	if auth_token == "":
		martial_sync_layout_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		martial_sync_layout_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		martial_sync_layout_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"martialArtsData": martial_arts_data, 
		"operationId": operation_id
	}
	_current_action_type = "martial_sync_layout"
	var err = action_request.request(server_url + "/martial/sync-layout", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		martial_sync_layout_failed.emit("网络请求失败")

func martial_forget(art_id: String, operation_id: String):
	if auth_token == "":
		martial_forget_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		martial_forget_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		martial_forget_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"artId": art_id, 
		"operationId": operation_id
	}
	_current_action_type = "martial_forget"
	var err = action_request.request(server_url + "/martial/forget", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		martial_forget_failed.emit("网络请求失败")

func pet_collection_invest(pet_instance_id: String, operation_id: String, species_id: String = "", invest_kind: String = ""):
	if auth_token == "":
		pet_collection_invest_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_collection_invest_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_collection_invest_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"petInstanceId": pet_instance_id, 
		"operationId": operation_id
	}
	# 服务端要靠这两个字段把图鉴进度记到正确的物种上（尤其是「服务端这份档里
	# 暂时没有这只宠」的情况：客户端本地捕获还没同步上去，只能靠 speciesId）。
	if not species_id.is_empty():
		body["speciesId"] = species_id
	if not invest_kind.is_empty():
		body["investKind"] = invest_kind
	_current_action_type = "pet_collection_invest"
	_last_pet_direct_op = "pet_collection_invest"
	var err = action_request.request(server_url + "/pet/collection/invest", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_collection_invest_failed.emit("网络请求失败")

func pet_soul_commit(pet_id: String, operation_id: String, inventory_data: Variant = null, equipment_data: Variant = null):
	if auth_token == "":
		pet_soul_commit_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_soul_commit_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_soul_commit_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"petId": pet_id, 
		"operationId": operation_id, 
	}
	if inventory_data != null and inventory_data is Dictionary:
		body["inventoryData"] = inventory_data
	if equipment_data != null and equipment_data is Dictionary:
		body["equipmentData"] = equipment_data
	_current_action_type = "pet_soul_commit"
	_last_pet_direct_op = "pet_soul_commit"
	var err = action_request.request(server_url + "/pet/soul/commit", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_soul_commit_failed.emit("网络请求失败")

func pet_soul_commit_batch(pet_ids: Array, operation_id: String, inventory_data: Variant = null, equipment_data: Variant = null):
	if auth_token == "":
		pet_soul_commit_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_soul_commit_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_soul_commit_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_ids: Array = []
	var seen: Dictionary = {}
	for raw_id in pet_ids:
		var sid: = str(raw_id).strip_edges()
		if sid.is_empty() or seen.has(sid):
			continue
		seen[sid] = true
		normalized_ids.append(sid)
	if normalized_ids.is_empty():
		pet_soul_commit_batch_failed.emit("请选择要投入的宠物")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"petIds": normalized_ids, 
		"operationId": operation_id, 
	}
	if inventory_data != null and inventory_data is Dictionary:
		body["inventoryData"] = inventory_data
	if equipment_data != null and equipment_data is Dictionary:
		body["equipmentData"] = equipment_data
	_current_action_type = "pet_soul_commit_batch"
	_last_pet_direct_op = "pet_soul_commit_batch"
	var err = action_request.request(server_url + "/pet/soul/commit-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_soul_commit_batch_failed.emit("网络请求失败")

func pet_soul_use_item(item_name: String, operation_id: String):
	if auth_token == "":
		pet_soul_use_item_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_soul_use_item_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_soul_use_item_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"itemName": item_name, 
		"operationId": operation_id, 
	}
	_current_action_type = "pet_soul_use_item"
	_last_pet_direct_op = "pet_soul_use_item"
	var err = action_request.request(server_url + "/pet/soul/use-item", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_soul_use_item_failed.emit("网络请求失败")



func _ensure_pet_skill_operation_id(operation_id: String) -> String:
	var s: = str(operation_id).strip_edges()
	if s.is_empty():
		return "pet_skill_auto_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	return s

func request_pet_skill_synthetic(book_name: String, book_count: int, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_synthetic_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_synthetic_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_synthetic_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "synthetic", 
		"params": {
			"book_name": book_name, 
			"book_count": book_count, 
			"operation_id": oid
		}
	}
	_current_action_type = "pet_skill_synthetic"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_synthetic_failed.emit("网络请求失败")

func request_pet_skill_split(book_name: String, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_split_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_split_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_split_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "split", 
		"params": {
			"book_name": book_name, 
			"operation_id": oid
		}
	}
	_current_action_type = "pet_skill_split"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_split_failed.emit("网络请求失败")

func request_pet_skill_learn(book_name: String, pet_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_learn_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_learn_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_learn_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid2: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "learn_skill", 
		"params": {
			"book_name": book_name, 
			"pet_id": str(pet_id).strip_edges(), 
			"operation_id": oid2
		}
	}
	_current_action_type = "pet_skill_learn"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_learn_failed.emit("网络请求失败")

func request_pet_skill_unlearn(pet_id: String, slot_index: int, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_unlearn_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_unlearn_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_unlearn_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid3: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "unlearn_skill", 
		"params": {
			"pet_id": str(pet_id).strip_edges(), 
			"slot_index": slot_index, 
			"operation_id": oid3
		}
	}
	_current_action_type = "pet_skill_unlearn"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_unlearn_failed.emit("网络请求失败")

func request_pet_skill_slot_lock(pet_id: String, slot_index: int, locked: bool, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_slot_lock_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_slot_lock_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_slot_lock_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid_lock: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "lock_skill_slot" if locked else "unlock_skill_slot", 
		"params": {
			"pet_id": str(pet_id).strip_edges(), 
			"slot_index": slot_index, 
			"operation_id": oid_lock
		}
	}
	_current_action_type = "pet_skill_slot_lock"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_slot_lock_failed.emit("网络请求失败")

func request_pet_skill_sync(pet_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_sync_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_sync_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_sync_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"action": "sync_pet_skills", 
		"params": {
			"pet_id": str(pet_id).strip_edges(), 
			"operation_id": operation_id
		}
	}
	_current_action_type = "pet_skill_sync"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_sync_failed.emit("网络请求失败")

func request_pet_skill_level_up(book_name: String, pet_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_skill_level_up_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_skill_level_up_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_skill_level_up_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var oid4: = _ensure_pet_skill_operation_id(operation_id)
	var body = {
		"action": "level_up_skill", 
		"params": {
			"book_name": book_name, 
			"pet_id": str(pet_id).strip_edges(), 
			"operation_id": oid4
		}
	}
	_current_action_type = "pet_skill_level_up"
	var err = action_request.request(server_url + "/pet_skill/action", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_skill_level_up_failed.emit("网络请求失败")

func request_equipment_equip(equipment_id: String, slot: String, operation_id: String, equipment_snapshot: Dictionary = {}) -> void :
	if auth_token == "":
		equipment_equip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_equip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_equip_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"slot": slot, 
		"operationId": operation_id
	}
	# 带上完整装备快照：服务端这份装备如果被旧的紧凑存档上传清空过，
	# 它可以用快照补登再穿戴，玩家不会遇到「背包里有、点装备提示不存在」。
	if not equipment_snapshot.is_empty():
		body["equipment"] = equipment_snapshot
	_current_action_type = "equipment_equip"
	var err = action_request.request(server_url + "/equipment/equip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_equip_failed.emit("网络请求失败")

func request_equipment_unequip(slot: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_unequip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_unequip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_unequip_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"slot": slot, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_unequip"
	var err = action_request.request(server_url + "/equipment/unequip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_unequip_failed.emit("网络请求失败")

func request_equipment_unseal_suit(equipment_id: String, sealed_item_id: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_unseal_suit_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_unseal_suit_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_unseal_suit_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: = {"operationId": operation_id}
	var eid: = equipment_id.strip_edges()
	var sid: = sealed_item_id.strip_edges()
	if not eid.is_empty():
		body["equipmentId"] = eid
	if not sid.is_empty():
		body["sealedItemId"] = sid
	_current_action_type = "equipment_unseal_suit"
	var err = action_request.request(server_url + "/equipment/unseal-suit", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_unseal_suit_failed.emit("网络请求失败")

func request_equipment_suit_convert(equipment_ids: Array, operation_id: String) -> void :
	if auth_token == "":
		equipment_suit_convert_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_suit_convert_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_suit_convert_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var ids: Array = []
	for raw_id in equipment_ids:
		var eid: = str(raw_id).strip_edges()
		if not eid.is_empty():
			ids.append(eid)
	var body = {
		"equipmentIds": ids, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_suit_convert"
	var err = action_request.request(server_url + "/equipment/suit-convert", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_suit_convert_failed.emit("网络请求失败")



func request_equipment_dismantle_suit(equipment_id: String, sealed_item_id: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_dismantle_suit_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_dismantle_suit_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_dismantle_suit_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"sealedItemId": sealed_item_id, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_dismantle_suit"
	var err = action_request.request(server_url + "/equipment/dismantle-suit", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_dismantle_suit_failed.emit("网络请求失败")

func request_equipment_dismantle_suit_batch(targets: Array, operation_id: String) -> void :
	if auth_token == "":
		equipment_dismantle_suit_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_dismantle_suit_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_dismantle_suit_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_targets: Array = []
	var seen: Dictionary = {}
	for raw in targets:
		if not raw is Dictionary:
			continue
		var equipment_id: = str(raw.get("equipmentId", raw.get("equipment_id", ""))).strip_edges()
		var sealed_item_id: = str(raw.get("sealedItemId", raw.get("sealed_item_id", ""))).strip_edges()
		if equipment_id.is_empty() and sealed_item_id.is_empty():
			continue
		var key: = ("s:%s" % sealed_item_id) if not sealed_item_id.is_empty() else ("e:%s" % equipment_id)
		if seen.has(key):
			continue
		seen[key] = true
		normalized_targets.append({
			"equipmentId": equipment_id, 
			"sealedItemId": sealed_item_id, 
		})
	if normalized_targets.is_empty():
		equipment_dismantle_suit_batch_failed.emit("请选择要分解的套装")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"targets": normalized_targets, 
		"operationId": operation_id, 
	}
	_current_action_type = "equipment_dismantle_suit_batch"
	var err = action_request.request(server_url + "/equipment/dismantle-suit-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_dismantle_suit_batch_failed.emit("网络请求失败")

func request_equipment_store_warehouse(equipment_id: String, sealed_item_id: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_store_warehouse_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_store_warehouse_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_store_warehouse_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: = {"operationId": operation_id}
	var eid: = equipment_id.strip_edges()
	var sid: = sealed_item_id.strip_edges()
	if not eid.is_empty():
		body["equipmentId"] = eid
	if not sid.is_empty():
		body["sealedItemId"] = sid
	_current_action_type = "equipment_store_warehouse"
	var err = action_request.request(server_url + "/equipment/store-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_store_warehouse_failed.emit("网络请求失败")

func request_equipment_retrieve_warehouse(equipment_id: String, warehouse_type: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_retrieve_warehouse_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_retrieve_warehouse_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_retrieve_warehouse_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"warehouseType": warehouse_type, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_retrieve_warehouse"
	var err = action_request.request(server_url + "/equipment/retrieve-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_retrieve_warehouse_failed.emit("网络请求失败")

func request_pet_equipment_equip(equipment_id: String, slot: String, operation_id: String, equipment_snapshot: Dictionary = {}, pet_id: String = "") -> void :
	if auth_token == "":
		pet_equipment_equip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_equip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_equip_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"slot": slot, 
		"operationId": operation_id
	}
	# 宠装穿戴以前完全不发 petId，服务端 `_find_pet(state, "")` 永远是 None
	# → 每次点「穿戴」都弹「灵兽不存在」。这里补上当前出战宠 id。
	if not pet_id.strip_edges().is_empty():
		body["petId"] = pet_id.strip_edges()
	if not equipment_snapshot.is_empty():
		body["equipment"] = equipment_snapshot
	_current_action_type = "pet_equipment_equip"
	var err = action_request.request(server_url + "/pet-equipment/equip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_equip_failed.emit("网络请求失败")

func request_pet_equipment_unequip(slot: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_unequip_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_unequip_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_unequip_failed.emit("操作繁忙，请稍后重试")
		return
	var api_slot: = str(slot).strip_edges()
	var mapped_slot: = _PetEquipmentData.get_equipment_slot_from_pet_slot(api_slot)
	if not mapped_slot.is_empty():
		api_slot = mapped_slot
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"slot": api_slot, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_unequip"
	var err = action_request.request(server_url + "/pet-equipment/unequip", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_unequip_failed.emit("网络请求失败")

func request_pet_equipment_store_warehouse(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_store_warehouse_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_store_warehouse_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_store_warehouse_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_store_warehouse"
	var err = action_request.request(server_url + "/pet-equipment/store-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_store_warehouse_failed.emit("网络请求失败")

func request_pet_equipment_retrieve_warehouse(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_retrieve_warehouse_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_retrieve_warehouse_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_retrieve_warehouse_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_retrieve_warehouse"
	var err = action_request.request(server_url + "/pet-equipment/retrieve-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_retrieve_warehouse_failed.emit("网络请求失败")

func request_pet_equipment_dismantle(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_dismantle_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_dismantle_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_dismantle_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_dismantle"
	var err = action_request.request(server_url + "/pet-equipment/dismantle", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_dismantle_failed.emit("网络请求失败")

func request_pet_equipment_dismantle_batch(equipment_ids: Array, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_dismantle_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_dismantle_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_dismantle_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var normalized_ids: Array = []
	var seen: Dictionary = {}
	for raw_id in equipment_ids:
		var sid: = str(raw_id).strip_edges()
		if sid.is_empty() or seen.has(sid):
			continue
		seen[sid] = true
		normalized_ids.append(sid)
	if normalized_ids.is_empty():
		pet_equipment_dismantle_batch_failed.emit("请选择要分解的宠物装备")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentIds": normalized_ids, 
		"operationId": operation_id, 
	}
	_current_action_type = "pet_equipment_dismantle_batch"
	var err = action_request.request(server_url + "/pet-equipment/dismantle-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_dismantle_batch_failed.emit("网络请求失败")

func request_pet_equipment_drop(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_drop_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_drop_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_drop_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_drop"
	var err = action_request.request(server_url + "/pet-equipment/drop", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_drop_failed.emit("网络请求失败")

func request_pet_equipment_enhance(equipment_id: String, stone_item_id: String, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_enhance_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_enhance_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_enhance_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"stoneItemId": stone_item_id, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_enhance"
	var err = action_request.request(server_url + "/pet-equipment/enhance", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_enhance_failed.emit("网络请求失败")

func request_pet_equipment_synthesize_fragments(fragment_count: int, operation_id: String, batch_count: int = 1) -> void :
	if auth_token == "":
		pet_equipment_synthesize_fragments_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_synthesize_fragments_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_synthesize_fragments_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var bc: int = clampi(batch_count, 1, 50)
	var frag: int = maxi(fragment_count, bc * 10)
	var body = {
		"fragmentCount": frag, 
		"batchCount": bc, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_synthesize_fragments"
	var err = action_request.request(server_url + "/pet-equipment/synthesize-fragments", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_synthesize_fragments_failed.emit("网络请求失败")

func request_inventory_synthesize_seal_stone(batch_count: int, operation_id: String) -> void :
	if auth_token == "":
		inventory_synthesize_seal_stone_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		inventory_synthesize_seal_stone_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		inventory_synthesize_seal_stone_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var bc: int = clampi(batch_count, 1, 50)
	var body = {
		"batchCount": bc, 
		"operationId": operation_id
	}
	_current_action_type = "inventory_synthesize_seal_stone"
	var err = action_request.request(server_url + "/inventory/synthesize-seal-stone", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		inventory_synthesize_seal_stone_failed.emit("网络请求失败")

func request_suit_equipment_enhance(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		suit_equipment_enhance_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		suit_equipment_enhance_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		suit_equipment_enhance_failed.emit("上一笔操作处理中，请稍候")
		return
	_capture_suit_enhance_resync_baseline("suit_equipment_enhance")
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "suit_equipment_enhance"
	var err = action_request.request(server_url + "/suit-equipment/enhance", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		suit_equipment_enhance_failed.emit("网络请求失败")

func request_pill_craft(recipe_key: String, batch_count: int, operation_id: String) -> void :
	if auth_token == "":
		pill_craft_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pill_craft_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pill_craft_failed.emit("操作繁忙，请稍后重试")
		return
	var key: = recipe_key.strip_edges()
	if key.is_empty():
		pill_craft_failed.emit("配方无效")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"recipeKey": key, 
		"batchCount": maxi(1, batch_count), 
		"operationId": operation_id
	}
	_current_action_type = "pill_craft"
	var err = action_request.request(server_url + "/crafting/pill-craft", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pill_craft_failed.emit("网络请求失败")

func request_suit_equipment_enhance_confirm(pending_token: String, accept: bool, operation_id: String) -> void :
	if auth_token == "":
		suit_equipment_enhance_confirm_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		suit_equipment_enhance_confirm_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		suit_equipment_enhance_confirm_failed.emit("上一笔操作处理中，请稍候")
		return
	_capture_suit_enhance_resync_baseline("suit_equipment_enhance_confirm")
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"pendingToken": pending_token, 
		"accept": accept, 
		"operationId": operation_id
	}
	_current_action_type = "suit_equipment_enhance_confirm"
	var err = action_request.request(server_url + "/suit-equipment/enhance/confirm", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		suit_equipment_enhance_confirm_failed.emit("网络请求失败")

func request_equipment_grant(source_type: String, source_id: String, count: int, operation_id: String) -> void :
	if auth_token == "":
		equipment_grant_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_grant_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_grant_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"sourceType": source_type, 
		"sourceId": source_id, 
		"count": count, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_grant"
	var err = action_request.request(server_url + "/equipment/grant", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_grant_failed.emit("网络请求失败")

func request_pet_equipment_grant(source_type: String, source_id: String, count: int, operation_id: String) -> void :
	if auth_token == "":
		pet_equipment_grant_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_equipment_grant_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_equipment_grant_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"sourceType": source_type, 
		"sourceId": source_id, 
		"count": count, 
		"operationId": operation_id
	}
	_current_action_type = "pet_equipment_grant"
	var err = action_request.request(server_url + "/pet-equipment/grant", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_equipment_grant_failed.emit("网络请求失败")

func request_frontier_gift_use(operation_id: String) -> void :
	if auth_token == "":
		frontier_gift_use_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		frontier_gift_use_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		frontier_gift_use_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id
	}
	_current_action_type = "frontier_gift_use"
	var err = action_request.request(server_url + "/gift/frontier/use", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		frontier_gift_use_failed.emit("网络请求失败")

func request_equipment_drop(equipment_id: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_drop_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_drop_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_drop_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentId": equipment_id, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_drop"
	var err = action_request.request(server_url + "/equipment/drop", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_drop_failed.emit("网络请求失败")

func request_inventory_drop(item_id: String, count: int, operation_id: String) -> void :
	if auth_token == "":
		inventory_drop_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		inventory_drop_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		inventory_drop_failed.emit("操作繁忙，请稍后重试")
		return
	var safe_count: = maxi(1, count)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"itemId": item_id, 
		"count": safe_count, 
		"operationId": operation_id
	}
	_current_action_type = "inventory_drop"
	var err = action_request.request(server_url + "/inventory/drop", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		inventory_drop_failed.emit("网络请求失败")

func request_inventory_store_warehouse(item_id: String, count: int, operation_id: String, item_name: String = "", item_type: String = "") -> void :
	if auth_token == "":
		inventory_store_warehouse_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		inventory_store_warehouse_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		inventory_store_warehouse_failed.emit("操作繁忙，请稍后重试")
		return
	var safe_count: = maxi(1, count)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"itemId": item_id, 
		"count": safe_count, 
		"operationId": operation_id, 
	}
	var nm: = item_name.strip_edges()
	if nm != "":
		body["itemName"] = nm
	var tp: = item_type.strip_edges()
	if tp != "":
		body["itemType"] = tp
	_current_action_type = "inventory_store_warehouse"
	var err = action_request.request(server_url + "/inventory/store-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		inventory_store_warehouse_failed.emit("网络请求失败")

func request_inventory_store_warehouse_batch(item_ids: Array, operation_id: String, item_name: String = "", item_type: String = "") -> void :
	if auth_token == "":
		inventory_store_warehouse_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		inventory_store_warehouse_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		inventory_store_warehouse_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var cleaned_ids: Array = []
	for raw_id in item_ids:
		var sid: = str(raw_id).strip_edges()
		if sid != "":
			cleaned_ids.append(sid)
	if cleaned_ids.is_empty():
		inventory_store_warehouse_batch_failed.emit("缺少批量物品ID")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"itemIds": cleaned_ids, 
		"operationId": operation_id, 
	}
	var nm: = item_name.strip_edges()
	if nm != "":
		body["itemName"] = nm
	var tp: = item_type.strip_edges()
	if tp != "":
		body["itemType"] = tp
	_current_action_type = "inventory_store_warehouse_batch"
	var err = action_request.request(server_url + "/inventory/store-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		inventory_store_warehouse_batch_failed.emit("网络请求失败")

func request_equipment_retrieve_warehouse_batch(equipment_ids: Array, warehouse_type: String, operation_id: String) -> void :
	if auth_token == "":
		equipment_retrieve_warehouse_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		equipment_retrieve_warehouse_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		equipment_retrieve_warehouse_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var cleaned_ids: Array = []
	for raw_id in equipment_ids:
		var sid: = str(raw_id).strip_edges()
		if sid != "":
			cleaned_ids.append(sid)
	if cleaned_ids.is_empty():
		equipment_retrieve_warehouse_batch_failed.emit("缺少批量仓库物品ID")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"equipmentIds": cleaned_ids, 
		"warehouseType": warehouse_type, 
		"operationId": operation_id
	}
	_current_action_type = "equipment_retrieve_warehouse_batch"
	var err = action_request.request(server_url + "/equipment/retrieve-warehouse", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		equipment_retrieve_warehouse_batch_failed.emit("网络请求失败")

func request_pet_egg_open(egg_name: String, operation_id: String, extra_payload: Dictionary = {}) -> void :
	if auth_token == "":
		pet_egg_open_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_egg_open_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_egg_open_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: Dictionary = {
		"eggName": str(egg_name).strip_edges(), 
		"operationId": operation_id
	}
	var safe_payload: Dictionary = InventoryManager.sanitize_pet_batch_extra_payload(extra_payload)
	for key in safe_payload.keys():
		body[key] = safe_payload[key]
	_current_action_type = "pet_egg_open"
	var err = action_request.request(server_url + "/pet/open-egg", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_egg_open_failed.emit("网络请求失败")

func request_pet_gift_open(gift_name: String, operation_id: String, extra_payload: Dictionary = {}) -> void :
	if auth_token == "":
		pet_gift_open_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_gift_open_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_gift_open_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: Dictionary = {
		"giftName": str(gift_name).strip_edges(), 
		"operationId": operation_id
	}
	var safe_payload: Dictionary = InventoryManager.sanitize_pet_batch_extra_payload(extra_payload)
	for key in safe_payload.keys():
		body[key] = safe_payload[key]
	_current_action_type = "pet_gift_open"
	var err = action_request.request(server_url + "/gift/open-pet", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_gift_open_failed.emit("网络请求失败")

func request_pet_medal_use(operation_id: String) -> void :
	if auth_token == "":
		pet_medal_use_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_medal_use_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_medal_use_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: Dictionary = {"operationId": operation_id}
	_current_action_type = "pet_medal_use"
	var err = action_request.request(server_url + "/gift/use-medal", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_medal_use_failed.emit("网络请求失败")

func request_pet_medal_use_batch(operation_id: String, batch_count: int) -> void :
	if auth_token == "":
		pet_medal_use_batch_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_medal_use_batch_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_medal_use_batch_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: Dictionary = {
		"operationId": operation_id, 
		"batchCount": maxi(1, batch_count), 
	}
	_current_action_type = "pet_medal_use_batch"
	var err_batch = action_request.request(server_url + "/gift/use-medal-batch", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err_batch != OK:
		_current_action_type = ""
		pet_medal_use_batch_failed.emit("网络请求失败")

func request_pet_grant_medal(operation_id: String, pet_id: String, medal_counts: Dictionary, reason: String = "", pet_level: int = -1) -> void :
	if auth_token == "":
		pet_grant_medal_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_grant_medal_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_grant_medal_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id, 
		"petId": pet_id, 
		"medalCounts": medal_counts, 
	}
	var sync_reason: = reason.strip_edges()
	if not sync_reason.is_empty():
		body["reason"] = sync_reason
	if pet_level >= 1:
		body["petLevel"] = pet_level
	_current_action_type = "pet_grant_medal"
	var err = action_request.request(server_url + "/pet/grant-medal", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_grant_medal_failed.emit("网络请求失败")

func _ensure_pet_max_level_learn_request_ready() -> bool:
	if pet_max_level_learn_request == null:
		pet_max_level_learn_request = HTTPRequest.new()
		pet_max_level_learn_request.timeout = 45.0
		add_child(pet_max_level_learn_request)
	if not pet_max_level_learn_request.request_completed.is_connected(_on_pet_max_level_learn_dedicated_completed):
		pet_max_level_learn_request.request_completed.connect(_on_pet_max_level_learn_dedicated_completed)
	return pet_max_level_learn_request != null


func request_pet_max_level_learn(operation_id: String, pet_id: String, previous_level: int, pet_level: int = -1) -> bool:
	if auth_token == "":
		pet_max_level_learn_failed.emit("未登录")
		return false
	if not _ensure_pet_max_level_learn_request_ready():
		pet_max_level_learn_failed.emit("请求通道初始化失败")
		return false
	if pet_max_level_learn_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:

		return false
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id, 
		"petId": pet_id, 
		"previousLevel": previous_level, 
	}
	if pet_level >= 1:
		body["petLevel"] = pet_level
	var err = pet_max_level_learn_request.request(server_url + "/pet/max-level-learn", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		pet_max_level_learn_failed.emit("网络请求失败")
		return false
	return true

func _on_pet_max_level_learn_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg: = "网络请求失败"
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析服务器地址"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS握手失败"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "服务器无响应"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "请求超时，请稍后重试"
		pet_max_level_learn_failed.emit(error_msg)
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		var detail: = "响应解析失败"
		if response_code == 404:
			detail = "接口不存在(404)，请确认服务端已更新"
		elif response_code >= 500:
			detail = "服务器内部错误(HTTP %d)" % response_code
		elif response_code > 0:
			detail = "响应解析失败(HTTP %d)" % response_code
		pet_max_level_learn_failed.emit(detail)
		return
	var data: Dictionary = json.data
	_apply_server_save_revision(data)
	_update_server_time_from_response_data(data)
	if response_code == 200 and bool(data.get("success", false)):
		pet_max_level_learn_success.emit(data)
		return
	if response_code == 200 and bool(data.get("duplicate", false)):
		pet_max_level_learn_success.emit(data)
		return
	var err_msg: = str(data.get("error", data.get("message", "满级领悟失败")))
	if response_code == 409:
		err_msg = "操作繁忙，请稍后重试"
	elif response_code == 503:
		err_msg = str(data.get("error", "数据库繁忙，请稍后重试"))
	elif response_code != 200 and err_msg.is_empty():
		err_msg = "服务器错误 (HTTP %d)" % response_code
	pet_max_level_learn_failed.emit(err_msg)

func request_forge_preview(main_equipment_id: String, sub_material_id: String, target_attr: String) -> void :
	if auth_token == "":
		forge_preview_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		forge_preview_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		forge_preview_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"mainEquipmentId": main_equipment_id, 
		"subMaterialId": sub_material_id, 
		"targetAttr": target_attr
	}
	_current_action_type = "forge_preview"
	_last_pet_direct_op = "forge_preview"
	var err = action_request.request(server_url + "/forge/preview", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		forge_preview_failed.emit("网络请求失败")

func execute_forge(main_equipment_id: String, sub_material_id: String, target_attr: String, operation_id: String) -> void :
	if auth_token == "":
		forge_execute_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		forge_execute_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		forge_execute_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"mainEquipmentId": main_equipment_id, 
		"subMaterialId": sub_material_id, 
		"targetAttr": target_attr, 
		"operationId": operation_id
	}
	_current_action_type = "forge_execute"
	_last_pet_direct_op = "forge_execute"
	var err = action_request.request(server_url + "/forge/execute", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		forge_execute_failed.emit("网络请求失败")

func realm_transition(transition_type: String, player_data: Dictionary, operation_id: String):
	if auth_token == "":
		realm_transition_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		realm_transition_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		realm_transition_failed.emit("操作繁忙，请稍后重试")
		return
	var t = transition_type.strip_edges()
	if t.is_empty():
		realm_transition_failed.emit("参数缺失")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	var body = {
		"transitionType": t, 
		"playerData": player_data, 
		"operationId": operation_id
	}
	_current_action_type = "realm_transition"
	var err = action_request.request(server_url + "/player/realm/transition", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		realm_transition_failed.emit("网络请求失败")

func _emit_layout_authority_failed(action_type: String, msg: String) -> void :
	match action_type:
		"set_current_map":
			set_current_map_failed.emit(msg)
		"capture_settings":
			capture_settings_failed.emit(msg)
		"pet_lock":
			pet_lock_failed.emit(msg)
		"martial_sync_layout":
			martial_sync_layout_failed.emit(msg)
		"martial_forget":
			martial_forget_failed.emit(msg)
		_:
			push_warning("[Network] unknown layout authority fail type=%s msg=%s" % [action_type, msg])

func _emit_layout_authority_success(action_type: String, data: Dictionary) -> void :
	match action_type:
		"set_current_map":
			set_current_map_success.emit(data)
		"capture_settings":
			capture_settings_success.emit(data)
		"pet_lock":
			pet_lock_success.emit(data)
		"martial_sync_layout":
			martial_sync_layout_success.emit(data)
		"martial_forget":
			martial_forget_success.emit(data)
		_:
			push_warning("[Network] unknown layout authority success type=%s" % action_type)

func _on_layout_authority_action_completed(action_type: String, result: int, response_code: int, body: PackedByteArray) -> void :
	print("[CloudSync] layout_authority 完成 type=%s result=%s http=%s" % [action_type, str(result), str(response_code)])
	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_layout_authority_failed(action_type, "网络请求失败")
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		var detail: = "响应解析失败"
		if response_code == 404:
			detail = "接口不存在(404)，请确认服务端已更新"
		elif response_code >= 500:
			detail = "服务器内部错误(HTTP %d)" % response_code
		_emit_layout_authority_failed(action_type, detail)
		return
	var data: Dictionary = json.data
	if response_code == 409:
		_emit_layout_authority_failed(action_type, str(data.get("error", "操作繁忙，请稍后重试")))
		return
	if response_code >= 400:
		var err_msg: = str(data.get("error", data.get("message", "操作失败"))).strip_edges()
		if err_msg.is_empty():
			err_msg = "操作失败(HTTP %d)" % response_code
		_emit_layout_authority_failed(action_type, err_msg)
		return
	if bool(data.get("duplicate", false)) and not data.has("saveData"):

		data["success"] = true
		_emit_layout_authority_success(action_type, data)
		return
	if not bool(data.get("success", false)) and not data.has("saveData"):
		var fail_msg: = str(data.get("error", data.get("message", "操作失败"))).strip_edges()
		if fail_msg.is_empty():
			fail_msg = "操作失败"
		_emit_layout_authority_failed(action_type, fail_msg)
		return
	data["success"] = true
	_emit_layout_authority_success(action_type, data)

func _on_action_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	var action_type = _current_action_type
	_current_action_type = ""
	if action_type == "set_current_map" or action_type == "capture_settings" or action_type == "pet_lock" or action_type == "martial_sync_layout" or action_type == "martial_forget":
		_on_layout_authority_action_completed(action_type, result, response_code, body)
		return
	if action_type == "pet_evolve" or action_type == "pet_merge" or action_type == "pet_release" or action_type == "pet_release_batch" or action_type == "pet_bag_store" or action_type == "pet_bag_store_batch" or action_type == "pet_bag_retrieve" or action_type == "pet_bag_retrieve_batch" or action_type == "pet_assist_equip" or action_type == "pet_assist_unequip" or action_type == "pet_refine_validate" or action_type == "pet_roster_sync" or action_type == "pet_refine" or action_type == "player_attr_auto_allocate" or action_type == "player_attr_spend_points" or action_type == "player_attr_auto_plan" or action_type == "player_talent_allocate" or action_type == "player_talent_reset" or action_type == "pet_collection_invest" or action_type == "pet_soul_commit" or action_type == "pet_soul_commit_batch" or action_type == "pet_soul_use_item" or action_type == "equipment_equip" or action_type == "equipment_unequip" or action_type == "equipment_unseal_suit" or action_type == "equipment_suit_convert" or action_type == "equipment_dismantle_suit" or action_type == "equipment_dismantle_suit_batch" or action_type == "equipment_store_warehouse" or action_type == "equipment_retrieve_warehouse" or action_type == "equipment_retrieve_warehouse_batch" or action_type == "equipment_drop" or action_type == "inventory_drop" or action_type == "inventory_store_warehouse" or action_type == "inventory_store_warehouse_batch" or action_type == "pet_equipment_equip" or action_type == "pet_equipment_unequip" or action_type == "pet_equipment_store_warehouse" or action_type == "pet_equipment_retrieve_warehouse" or action_type == "pet_equipment_dismantle" or action_type == "pet_equipment_dismantle_batch" or action_type == "pet_equipment_drop" or action_type == "pet_equipment_enhance" or action_type == "pet_equipment_synthesize_fragments" or action_type == "inventory_synthesize_seal_stone" or action_type == "pill_craft" or action_type == "suit_equipment_enhance" or action_type == "suit_equipment_enhance_confirm" or action_type == "pet_equipment_grant" or action_type == "equipment_grant" or action_type == "frontier_gift_use" or action_type == "forge_preview" or action_type == "forge_execute" or action_type == "pet_egg_open" or action_type == "pet_gift_open" or action_type == "pet_reincarnation" or action_type == "pet_reincarnation_inherit" or action_type == "pet_medal_use" or action_type == "pet_medal_use_batch":
		print("[CloudSync] action_request 完成 type=%s result=%s http=%s" % [action_type, str(result), str(response_code)])
	if result != HTTPRequest.RESULT_SUCCESS:
		if action_type == "pet_merge":
			pet_merge_failed.emit("网络请求失败")
		elif action_type == "pet_reincarnation":
			pet_reincarnation_failed.emit("网络请求失败")
		elif action_type == "pet_reincarnation_inherit":
			pet_reincarnation_inherit_failed.emit("网络请求失败")
		elif action_type == "pet_evolve":
			pet_evolve_failed.emit("网络请求失败")
		elif action_type == "pet_release":
			pet_release_failed.emit("网络请求失败")
		elif action_type == "pet_release_batch":
			pet_release_batch_failed.emit("网络请求失败")
		elif action_type == "pet_bag_store":
			pet_bag_store_failed.emit("网络请求失败")
		elif action_type == "pet_bag_store_batch":
			pet_bag_store_batch_failed.emit("网络请求失败")
		elif action_type == "pet_bag_retrieve":
			pet_bag_retrieve_failed.emit("网络请求失败")
		elif action_type == "pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_failed.emit("网络请求失败")
		elif action_type == "pet_assist_equip":
			pet_assist_equip_failed.emit("网络请求失败")
		elif action_type == "pet_assist_unequip":
			pet_assist_unequip_failed.emit("网络请求失败")
		elif action_type == "pet_refine_validate":
			pet_refine_validate_done.emit({"success": false, "error": "网络请求失败"})
		elif action_type == "pet_roster_sync":
			pet_roster_sync_failed.emit("网络请求失败")
		elif action_type == "pet_refine":
			pet_refine_failed.emit("网络请求失败")
		elif action_type == "player_attr_auto_allocate":
			player_attr_auto_allocate_failed.emit("网络请求失败")
		elif action_type == "player_attr_spend_points":
			player_attr_spend_failed.emit("网络请求失败")
		elif action_type == "player_talent_allocate":
			player_talent_allocate_failed.emit("网络请求失败")
		elif action_type == "player_talent_reset":
			player_talent_reset_failed.emit("网络请求失败")
		elif action_type == "player_attr_auto_plan":
			player_attr_plan_failed.emit("网络请求失败")
		elif action_type == "pet_collection_invest":
			pet_collection_invest_failed.emit("网络请求失败")
		elif action_type == "pet_soul_commit":
			pet_soul_commit_failed.emit("网络请求失败")
		elif action_type == "pet_soul_commit_batch":
			pet_soul_commit_batch_failed.emit("网络请求失败")
		elif action_type == "pet_soul_use_item":
			pet_soul_use_item_failed.emit("网络请求失败")
		elif action_type == "equipment_equip":
			equipment_equip_failed.emit("网络请求失败")
		elif action_type == "equipment_unequip":
			equipment_unequip_failed.emit("网络请求失败")
		elif action_type == "equipment_unseal_suit":
			equipment_unseal_suit_failed.emit("网络请求失败")
		elif action_type == "equipment_suit_convert":
			equipment_suit_convert_failed.emit("网络请求失败")
		elif action_type == "equipment_dismantle_suit":
			equipment_dismantle_suit_failed.emit("网络请求失败")
		elif action_type == "equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_equip":
			pet_equipment_equip_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_unequip":
			pet_equipment_unequip_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_dismantle":
			pet_equipment_dismantle_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_drop":
			pet_equipment_drop_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_enhance":
			pet_equipment_enhance_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_failed.emit("网络请求失败")
		elif action_type == "inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_failed.emit("网络请求失败")
		elif action_type == "pill_craft":
			pill_craft_failed.emit("网络请求失败")
		elif action_type == "suit_equipment_enhance":
			if _try_begin_suit_enhance_ambiguous_resync(action_type, {}):
				return
			_suit_enhance_resync_baseline = {}
			suit_equipment_enhance_failed.emit("网络请求失败")
		elif action_type == "suit_equipment_enhance_confirm":
			if _try_begin_suit_enhance_ambiguous_resync(action_type, {}):
				return
			_suit_enhance_resync_baseline = {}
			suit_equipment_enhance_confirm_failed.emit("网络请求失败")
		elif action_type == "pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_failed_deferred", "网络请求失败")
		elif action_type == "equipment_grant":
			equipment_grant_failed.emit("网络请求失败")
		elif action_type == "equipment_drop":
			equipment_drop_failed.emit("网络请求失败")
		elif action_type == "inventory_drop":
			inventory_drop_failed.emit("网络请求失败")
		elif action_type == "inventory_store_warehouse":
			inventory_store_warehouse_failed.emit("网络请求失败")
		elif action_type == "inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_failed.emit("网络请求失败")
		elif action_type == "equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_failed.emit("网络请求失败")
		elif action_type == "frontier_gift_use":
			frontier_gift_use_failed.emit("网络请求失败")
		elif action_type == "pet_medal_use":
			pet_medal_use_failed.emit("网络请求失败")
		elif action_type == "pet_medal_use_batch":
			pet_medal_use_batch_failed.emit("网络请求失败")
		elif action_type == "pet_skill_synthetic":
			pet_skill_synthetic_failed.emit("网络请求失败")
		elif action_type == "pet_skill_split":
			pet_skill_split_failed.emit("网络请求失败")
		elif action_type == "pet_skill_learn":
			pet_skill_learn_failed.emit("网络请求失败")
		elif action_type == "pet_skill_unlearn":
			pet_skill_unlearn_failed.emit("网络请求失败")
		elif action_type == "pet_skill_slot_lock":
			pet_skill_slot_lock_failed.emit("网络请求失败")
		elif action_type == "pet_skill_sync":
			pet_skill_sync_failed.emit("网络请求失败")
		elif action_type == "pet_skill_level_up":
			pet_skill_level_up_failed.emit("网络请求失败")
		elif action_type == "pet_max_level_learn":
			pet_max_level_learn_failed.emit("网络请求失败")
		elif action_type == "pet_grant_medal":
			pet_grant_medal_failed.emit("网络请求失败")
		elif action_type == "forge_preview":
			forge_preview_failed.emit("网络请求失败")
		elif action_type == "forge_execute":
			forge_execute_failed.emit("网络请求失败")
		elif action_type == "realm_transition":
			realm_transition_failed.emit("网络请求失败")
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not (json.data is Dictionary):
		var raw_text: String = body.get_string_from_utf8()
		var detail: String = "响应解析失败"
		if response_code == 404:
			detail = "接口不存在(404)，请确认服务端已更新"
		elif response_code >= 500:
			detail = "服务器内部错误(HTTP %d)" % response_code
		elif not raw_text.strip_edges().is_empty():
			detail = "响应解析失败(HTTP %d)" % response_code
		if action_type == "pet_merge":
			pet_merge_failed.emit("响应解析失败")
		elif action_type == "pet_evolve":
			pet_evolve_failed.emit("响应解析失败")
		elif action_type == "pet_release":
			pet_release_failed.emit(detail)
		elif action_type == "pet_release_batch":
			pet_release_batch_failed.emit(detail)
		elif action_type == "pet_bag_store":
			pet_bag_store_failed.emit(detail)
		elif action_type == "pet_bag_store_batch":
			pet_bag_store_batch_failed.emit(detail)
		elif action_type == "pet_bag_retrieve":
			pet_bag_retrieve_failed.emit(detail)
		elif action_type == "pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_failed.emit(detail)
		elif action_type == "pet_assist_equip":
			pet_assist_equip_failed.emit(detail)
		elif action_type == "pet_assist_unequip":
			pet_assist_unequip_failed.emit(detail)
		elif action_type == "pet_refine_validate":
			pet_refine_validate_done.emit({"success": false, "error": detail})
		elif action_type == "pet_roster_sync":
			pet_roster_sync_failed.emit(detail)
		elif action_type == "pet_refine":
			pet_refine_failed.emit(detail)
		elif action_type == "player_attr_auto_allocate":
			player_attr_auto_allocate_failed.emit(detail)
		elif action_type == "player_attr_spend_points":
			player_attr_spend_failed.emit(detail)
		elif action_type == "player_talent_allocate":
			player_talent_allocate_failed.emit(detail)
		elif action_type == "player_talent_reset":
			player_talent_reset_failed.emit(detail)
		elif action_type == "player_attr_auto_plan":
			player_attr_plan_failed.emit(detail)
		elif action_type == "pet_collection_invest":
			pet_collection_invest_failed.emit(detail)
		elif action_type == "pet_soul_commit":
			pet_soul_commit_failed.emit(detail)
		elif action_type == "pet_soul_commit_batch":
			pet_soul_commit_batch_failed.emit(detail)
		elif action_type == "pet_soul_use_item":
			pet_soul_use_item_failed.emit(detail)
		elif action_type == "equipment_equip":
			equipment_equip_failed.emit(detail)
		elif action_type == "equipment_unequip":
			equipment_unequip_failed.emit(detail)
		elif action_type == "equipment_unseal_suit":
			equipment_unseal_suit_failed.emit(detail)
		elif action_type == "equipment_suit_convert":
			equipment_suit_convert_failed.emit(detail)
		elif action_type == "equipment_dismantle_suit":
			equipment_dismantle_suit_failed.emit(detail)
		elif action_type == "equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_failed.emit(detail)
		elif action_type == "pet_equipment_equip":
			pet_equipment_equip_failed.emit(detail)
		elif action_type == "pet_equipment_unequip":
			pet_equipment_unequip_failed.emit(detail)
		elif action_type == "pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_failed.emit(detail)
		elif action_type == "pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_failed.emit(detail)
		elif action_type == "pet_equipment_dismantle":
			pet_equipment_dismantle_failed.emit(detail)
		elif action_type == "pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_failed.emit(detail)
		elif action_type == "pet_equipment_drop":
			pet_equipment_drop_failed.emit(detail)
		elif action_type == "pet_equipment_enhance":
			pet_equipment_enhance_failed.emit(detail)
		elif action_type == "pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_failed.emit(detail)
		elif action_type == "inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_failed.emit(detail)
		elif action_type == "pill_craft":
			pill_craft_failed.emit(detail)
		elif action_type == "suit_equipment_enhance":
			suit_equipment_enhance_failed.emit(detail)
		elif action_type == "suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_failed.emit(detail)
		elif action_type == "pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_failed_deferred", str(detail))
		elif action_type == "equipment_grant":
			equipment_grant_failed.emit(detail)
		elif action_type == "equipment_drop":
			equipment_drop_failed.emit(detail)
		elif action_type == "inventory_drop":
			inventory_drop_failed.emit(detail)
		elif action_type == "inventory_store_warehouse":
			inventory_store_warehouse_failed.emit(detail)
		elif action_type == "inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_failed.emit(detail)
		elif action_type == "equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_failed.emit(detail)
		elif action_type == "frontier_gift_use":
			frontier_gift_use_failed.emit(detail)
		elif action_type == "pet_medal_use":
			pet_medal_use_failed.emit(detail)
		elif action_type == "pet_medal_use_batch":
			pet_medal_use_batch_failed.emit(detail)
		elif action_type == "pet_skill_synthetic":
			pet_skill_synthetic_failed.emit(detail)
		elif action_type == "pet_skill_split":
			pet_skill_split_failed.emit(detail)
		elif action_type == "pet_skill_learn":
			pet_skill_learn_failed.emit(detail)
		elif action_type == "pet_skill_unlearn":
			pet_skill_unlearn_failed.emit(detail)
		elif action_type == "pet_skill_slot_lock":
			pet_skill_slot_lock_failed.emit(detail)
		elif action_type == "pet_skill_sync":
			pet_skill_sync_failed.emit(detail)
		elif action_type == "pet_skill_level_up":
			pet_skill_level_up_failed.emit(detail)
		elif action_type == "pet_max_level_learn":
			pet_max_level_learn_failed.emit(detail)
		elif action_type == "pet_grant_medal":
			pet_grant_medal_failed.emit(detail)
		elif action_type == "equipment_store_warehouse":
			equipment_store_warehouse_failed.emit(detail)
		elif action_type == "equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_failed.emit(detail)
		elif action_type == "forge_preview":
			forge_preview_failed.emit(detail)
		elif action_type == "forge_execute":
			forge_execute_failed.emit(detail)
		elif action_type == "realm_transition":
			realm_transition_failed.emit("响应解析失败")
		return
	var data: Dictionary = json.data
	_apply_server_save_revision(data)
	if action_type == "pet_refine_validate":
		if response_code == 200 and bool(data.get("success", false)):
			pet_refine_validate_done.emit(data)
		else:
			pet_refine_validate_done.emit({"success": false, "error": str(data.get("error", "校验失败(HTTP %d)" % response_code))})
		return
	if action_type == "pet_roster_sync":
		if response_code == 200 and bool(data.get("success", false)):
			pet_roster_sync_success.emit(data)
		else:
			pet_roster_sync_failed.emit(str(data.get("error", "主战栏同步失败(HTTP %d)" % response_code)))
		return
	if action_type == "player_attr_auto_allocate":
		if response_code == 200 and bool(data.get("success", false)):
			player_attr_auto_allocate_success.emit(data)
		else:
			player_attr_auto_allocate_failed.emit(str(data.get("error", "自动分配失败(HTTP %d)" % response_code)))
		return
	if action_type == "player_attr_spend_points":
		if response_code == 200 and bool(data.get("success", false)):
			player_attr_spend_success.emit(data)
		else:
			player_attr_spend_failed.emit(str(data.get("error", "手动加点失败(HTTP %d)" % response_code)))
		return
	if action_type == "player_talent_allocate":
		if response_code == 200 and bool(data.get("success", false)):
			player_talent_allocate_success.emit(data)
		else:
			player_talent_allocate_failed.emit(str(data.get("error", "天赋分配失败(HTTP %d)" % response_code)))
		return
	if action_type == "player_talent_reset":
		if response_code == 200 and bool(data.get("success", false)):
			player_talent_reset_success.emit(data)
		else:
			player_talent_reset_failed.emit(str(data.get("error", "天赋重置失败(HTTP %d)" % response_code)))
		return
	if action_type == "player_attr_auto_plan":
		if response_code == 200 and bool(data.get("success", false)):
			player_attr_plan_success.emit(data)
		else:
			player_attr_plan_failed.emit(str(data.get("error", "方案保存失败(HTTP %d)" % response_code)))
		return
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		var lock_msg: = "当前客户端版本过低，请更新后继续游戏"
		if action_type == "pet_merge":
			pet_merge_failed.emit(lock_msg)
		elif action_type == "pet_reincarnation":
			pet_reincarnation_failed.emit(lock_msg)
		elif action_type == "pet_reincarnation_inherit":
			pet_reincarnation_inherit_failed.emit(lock_msg)
		elif action_type == "pet_evolve":
			pet_evolve_failed.emit(lock_msg)
		elif action_type == "pet_release":
			pet_release_failed.emit(lock_msg)
		elif action_type == "pet_release_batch":
			pet_release_batch_failed.emit(lock_msg)
		elif action_type == "pet_bag_store":
			pet_bag_store_failed.emit(lock_msg)
		elif action_type == "pet_bag_store_batch":
			pet_bag_store_batch_failed.emit(lock_msg)
		elif action_type == "pet_bag_retrieve":
			pet_bag_retrieve_failed.emit(lock_msg)
		elif action_type == "pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_failed.emit(lock_msg)
		elif action_type == "pet_assist_equip":
			pet_assist_equip_failed.emit(lock_msg)
		elif action_type == "pet_assist_unequip":
			pet_assist_unequip_failed.emit(lock_msg)
		elif action_type == "pet_refine_validate":
			pet_refine_validate_done.emit({"success": false, "error": lock_msg})
		elif action_type == "pet_roster_sync":
			pet_roster_sync_failed.emit(lock_msg)
		elif action_type == "pet_refine":
			pet_refine_failed.emit(lock_msg)
		elif action_type == "player_attr_auto_allocate":
			player_attr_auto_allocate_failed.emit(lock_msg)
		elif action_type == "player_attr_spend_points":
			player_attr_spend_failed.emit(lock_msg)
		elif action_type == "player_talent_allocate":
			player_talent_allocate_failed.emit(lock_msg)
		elif action_type == "player_talent_reset":
			player_talent_reset_failed.emit(lock_msg)
		elif action_type == "player_attr_auto_plan":
			player_attr_plan_failed.emit(lock_msg)
		elif action_type == "pet_collection_invest":
			pet_collection_invest_failed.emit(lock_msg)
		elif action_type == "pet_soul_commit":
			pet_soul_commit_failed.emit(lock_msg)
		elif action_type == "pet_soul_commit_batch":
			pet_soul_commit_batch_failed.emit(lock_msg)
		elif action_type == "pet_soul_use_item":
			pet_soul_use_item_failed.emit(lock_msg)
		elif action_type == "equipment_equip":
			equipment_equip_failed.emit(lock_msg)
		elif action_type == "equipment_unequip":
			equipment_unequip_failed.emit(lock_msg)
		elif action_type == "equipment_unseal_suit":
			equipment_unseal_suit_failed.emit(lock_msg)
		elif action_type == "equipment_suit_convert":
			equipment_suit_convert_failed.emit(lock_msg)
		elif action_type == "equipment_dismantle_suit":
			equipment_dismantle_suit_failed.emit(lock_msg)
		elif action_type == "equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_failed.emit(lock_msg)
		elif action_type == "pet_equipment_equip":
			pet_equipment_equip_failed.emit(lock_msg)
		elif action_type == "pet_equipment_unequip":
			pet_equipment_unequip_failed.emit(lock_msg)
		elif action_type == "pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_failed.emit(lock_msg)
		elif action_type == "pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_failed.emit(lock_msg)
		elif action_type == "pet_equipment_dismantle":
			pet_equipment_dismantle_failed.emit(lock_msg)
		elif action_type == "pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_failed.emit(lock_msg)
		elif action_type == "pet_equipment_drop":
			pet_equipment_drop_failed.emit(lock_msg)
		elif action_type == "pet_equipment_enhance":
			pet_equipment_enhance_failed.emit(lock_msg)
		elif action_type == "pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_failed.emit(lock_msg)
		elif action_type == "inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_failed.emit(lock_msg)
		elif action_type == "pill_craft":
			pill_craft_failed.emit(lock_msg)
		elif action_type == "suit_equipment_enhance":
			suit_equipment_enhance_failed.emit(lock_msg)
		elif action_type == "suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_failed.emit(lock_msg)
		elif action_type == "pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_failed_deferred", lock_msg)
		elif action_type == "equipment_grant":
			equipment_grant_failed.emit(lock_msg)
		elif action_type == "equipment_drop":
			equipment_drop_failed.emit(lock_msg)
		elif action_type == "inventory_drop":
			inventory_drop_failed.emit(lock_msg)
		elif action_type == "inventory_store_warehouse":
			inventory_store_warehouse_failed.emit(lock_msg)
		elif action_type == "inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_failed.emit(lock_msg)
		elif action_type == "equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_failed.emit(lock_msg)
		elif action_type == "equipment_store_warehouse":
			equipment_store_warehouse_failed.emit(lock_msg)
		elif action_type == "equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_failed.emit(lock_msg)
		elif action_type == "forge_preview":
			forge_preview_failed.emit(lock_msg)
		elif action_type == "pet_skill_synthetic":
			pet_skill_synthetic_failed.emit(lock_msg)
		elif action_type == "pet_skill_split":
			pet_skill_split_failed.emit(lock_msg)
		elif action_type == "pet_skill_learn":
			pet_skill_learn_failed.emit(lock_msg)
		elif action_type == "pet_skill_unlearn":
			pet_skill_unlearn_failed.emit(lock_msg)
		elif action_type == "pet_skill_slot_lock":
			pet_skill_slot_lock_failed.emit(lock_msg)
		elif action_type == "pet_skill_sync":
			pet_skill_sync_failed.emit(lock_msg)
		elif action_type == "pet_skill_level_up":
			pet_skill_level_up_failed.emit(lock_msg)
		elif action_type == "pet_max_level_learn":
			pet_max_level_learn_failed.emit(lock_msg)
		elif action_type == "forge_execute":
			forge_execute_failed.emit(lock_msg)
		elif action_type == "realm_transition":
			realm_transition_failed.emit(lock_msg)
		return
	if response_code == 200 and data.get("success", false):
		# 进化/幻化这几个接口服务端是「扁平返回」：{success, pet, saveData, saveRevision}，
		# 没有 result 包一层。原来会直接跌到函数末尾的兜底分支 emit failed，
		# 弹窗就成了「进化失败 / 请求成功」（msg 取不到 message 时的默认文案），
		# 而且因为提前 return，服务端算好的 saveData 根本没被应用 —— 表现就是进化不生效。
		# 这里按客户端约定补出 result，后面的界面逻辑不用改。
		if not data.has("result") and data.has("pet") and (action_type == "pet_evolve" or action_type == "pet_merge"):
			data["result"] = _build_flat_pet_result(data)
		if data.has("result"):
			if action_type == "pet_merge":
				pet_merge_success.emit(data)
				return
			elif action_type == "pet_reincarnation":
				pet_reincarnation_success.emit(data)
				return
			elif action_type == "pet_reincarnation_inherit":
				pet_reincarnation_inherit_success.emit(data)
				return
			elif action_type == "pet_evolve":
				pet_evolve_success.emit(data)
				return
			elif action_type == "pet_refine":
				pet_refine_success.emit(data)
				return
			elif action_type == "pet_release":
				pet_release_success.emit(data)
				return
			elif action_type == "pet_release_batch":
				pet_release_batch_success.emit(data)
				return
			elif action_type == "pet_bag_store":
				pet_bag_store_success.emit(data)
				return
			elif action_type == "pet_bag_store_batch":
				pet_bag_store_batch_success.emit(data)
				return
			elif action_type == "pet_bag_retrieve":
				pet_bag_retrieve_success.emit(data)
				return
			elif action_type == "pet_bag_retrieve_batch":
				pet_bag_retrieve_batch_success.emit(data)
				return
			elif action_type == "pet_assist_equip":
				pet_assist_equip_success.emit(data)
				return
			elif action_type == "pet_assist_unequip":
				pet_assist_unequip_success.emit(data)
				return
			elif action_type == "pet_collection_invest":
				pet_collection_invest_success.emit(data)
				return
			elif action_type == "pet_soul_commit":
				pet_soul_commit_success.emit(data)
				return
			elif action_type == "pet_soul_commit_batch":
				pet_soul_commit_batch_success.emit(data)
				return
			elif action_type == "pet_soul_use_item":
				pet_soul_use_item_success.emit(data)
				return
			elif action_type == "equipment_equip":
				equipment_equip_success.emit(data)
				return
			elif action_type == "equipment_unequip":
				equipment_unequip_success.emit(data)
				return
			elif action_type == "equipment_unseal_suit":
				equipment_unseal_suit_success.emit(data)
				return
			elif action_type == "equipment_suit_convert":
				equipment_suit_convert_success.emit(data)
				return
			elif action_type == "equipment_dismantle_suit":
				equipment_dismantle_suit_success.emit(data)
				return
			elif action_type == "equipment_dismantle_suit_batch":
				equipment_dismantle_suit_batch_success.emit(data)
				return
			elif action_type == "equipment_store_warehouse":
				equipment_store_warehouse_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse":
				equipment_retrieve_warehouse_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse_batch":
				inventory_store_warehouse_batch_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse_batch":
				equipment_retrieve_warehouse_batch_success.emit(data)
				return
			elif action_type == "pet_equipment_equip":
				pet_equipment_equip_success.emit(data)
				return
			elif action_type == "pet_equipment_unequip":
				pet_equipment_unequip_success.emit(data)
				return
			elif action_type == "pet_equipment_store_warehouse":
				pet_equipment_store_warehouse_success.emit(data)
				return
			elif action_type == "pet_equipment_retrieve_warehouse":
				pet_equipment_retrieve_warehouse_success.emit(data)
				return
			elif action_type == "pet_equipment_dismantle":
				pet_equipment_dismantle_success.emit(data)
				return
			elif action_type == "pet_equipment_dismantle_batch":
				pet_equipment_dismantle_batch_success.emit(data)
				return
			elif action_type == "pet_equipment_drop":
				pet_equipment_drop_success.emit(data)
				return
			elif action_type == "pet_equipment_enhance":
				pet_equipment_enhance_success.emit(data)
				return
			elif action_type == "pet_equipment_synthesize_fragments":
				pet_equipment_synthesize_fragments_success.emit(data)
				return
			elif action_type == "inventory_synthesize_seal_stone":
				inventory_synthesize_seal_stone_success.emit(data)
				return
			elif action_type == "pill_craft":
				pill_craft_success.emit(data)
				return
			elif action_type == "suit_equipment_enhance":
				suit_equipment_enhance_success.emit(data)
				return
			elif action_type == "suit_equipment_enhance_confirm":
				suit_equipment_enhance_confirm_success.emit(data)
				return
			elif action_type == "pet_equipment_grant":
				call_deferred("_emit_pet_equipment_grant_success_deferred", data)
				return
			elif action_type == "equipment_grant":
				equipment_grant_success.emit(data)
				return
			elif action_type == "equipment_drop":
				equipment_drop_success.emit(data)
				return
			elif action_type == "inventory_drop":
				inventory_drop_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse":
				inventory_store_warehouse_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse_batch":
				inventory_store_warehouse_batch_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse_batch":
				equipment_retrieve_warehouse_batch_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse_batch":
				inventory_store_warehouse_batch_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse_batch":
				equipment_retrieve_warehouse_batch_success.emit(data)
				return
			elif action_type == "frontier_gift_use":
				frontier_gift_use_success.emit(data)
				return
			elif action_type == "pet_egg_open":
				pet_egg_open_success.emit(data)
				return
			elif action_type == "pet_gift_open":
				pet_gift_open_success.emit(data)
				return
			elif action_type == "pet_medal_use":
				pet_medal_use_success.emit(data)
				return
			elif action_type == "pet_medal_use_batch":
				pet_medal_use_batch_success.emit(data)
				return
			elif action_type == "pet_skill_synthetic":
				pet_skill_synthetic_success.emit(data)
				return
			elif action_type == "pet_skill_split":
				pet_skill_split_success.emit(data)
				return
			elif action_type == "pet_skill_learn":
				pet_skill_learn_success.emit(data)
				return
			elif action_type == "pet_skill_unlearn":
				pet_skill_unlearn_success.emit(data)
				return
			elif action_type == "pet_skill_slot_lock":
				pet_skill_slot_lock_success.emit(data)
				return
			elif action_type == "pet_skill_sync":
				pet_skill_sync_success.emit(data)
				return
			elif action_type == "pet_skill_level_up":
				pet_skill_level_up_success.emit(data)
				return
			elif action_type == "pet_max_level_learn":
				pet_max_level_learn_success.emit(data)
				return
			elif action_type == "forge_execute":
				forge_execute_success.emit(data)
				return
			else:
				push_error("[Network] action_request: 响应含 result 但 action_type 非 merge/evolve，type=%s last=%s" % [action_type, _last_pet_direct_op])
				var which: String = str(action_type if action_type != "" else _last_pet_direct_op)
				if which == "pet_merge":
					pet_merge_failed.emit("网络状态异常，请重试")
				elif which == "pet_soul_commit":
					pet_soul_commit_failed.emit("网络状态异常，请重试")
				elif which == "pet_soul_commit_batch":
					pet_soul_commit_batch_failed.emit("网络状态异常，请重试")
				elif which == "pet_release_batch":
					pet_release_batch_failed.emit("网络状态异常，请重试")
				elif which == "pet_soul_use_item":
					pet_soul_use_item_failed.emit("网络状态异常，请重试")
				elif which == "equipment_unseal_suit":
					equipment_unseal_suit_failed.emit("网络状态异常，请重试")
				elif which == "equipment_suit_convert":
					equipment_suit_convert_failed.emit("网络状态异常，请重试")
				elif which == "equipment_dismantle_suit":
					equipment_dismantle_suit_failed.emit("网络状态异常，请重试")
				elif which == "equipment_dismantle_suit_batch":
					equipment_dismantle_suit_batch_failed.emit("网络状态异常，请重试")
				elif which == "equipment_store_warehouse":
					equipment_store_warehouse_failed.emit("网络状态异常，请重试")
				elif which == "equipment_retrieve_warehouse":
					equipment_retrieve_warehouse_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_equip":
					pet_equipment_equip_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_unequip":
					pet_equipment_unequip_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_store_warehouse":
					pet_equipment_store_warehouse_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_retrieve_warehouse":
					pet_equipment_retrieve_warehouse_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_dismantle":
					pet_equipment_dismantle_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_dismantle_batch":
					pet_equipment_dismantle_batch_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_drop":
					pet_equipment_drop_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_enhance":
					pet_equipment_enhance_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_synthesize_fragments":
					pet_equipment_synthesize_fragments_failed.emit("网络状态异常，请重试")
				elif which == "inventory_synthesize_seal_stone":
					inventory_synthesize_seal_stone_failed.emit("网络状态异常，请重试")
				elif which == "pill_craft":
					pill_craft_failed.emit("网络状态异常，请重试")
				elif which == "suit_equipment_enhance":
					suit_equipment_enhance_failed.emit("网络状态异常，请重试")
				elif which == "suit_equipment_enhance_confirm":
					suit_equipment_enhance_confirm_failed.emit("网络状态异常，请重试")
				elif which == "pet_equipment_grant":
					call_deferred("_emit_pet_equipment_grant_failed_deferred", "网络状态异常，请重试")
				elif which == "pet_egg_open":
					pet_egg_open_failed.emit("网络状态异常，请重试")
				elif which == "pet_gift_open":
					pet_gift_open_failed.emit("网络状态异常，请重试")
				elif which == "forge_preview":
					forge_preview_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_synthetic":
					pet_skill_synthetic_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_split":
					pet_skill_split_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_learn":
					pet_skill_learn_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_unlearn":
					pet_skill_unlearn_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_slot_lock":
					pet_skill_slot_lock_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_sync":
					pet_skill_sync_failed.emit("网络状态异常，请重试")
				elif which == "pet_skill_level_up":
					pet_skill_level_up_failed.emit("网络状态异常，请重试")
				elif which == "pet_max_level_learn":
					pet_max_level_learn_failed.emit("网络状态异常，请重试")
				elif which == "forge_execute":
					forge_execute_failed.emit("网络状态异常，请重试")
				else:
					pet_evolve_failed.emit("网络状态异常，请重试")
				return
		if action_type == "pet_release":
			pet_release_success.emit(data)
			return
		if action_type == "pet_release_batch":
			pet_release_batch_success.emit(data)
			return
		if action_type == "pet_refine":
			pet_refine_success.emit(data)
			return
		if action_type == "player_attr_auto_allocate":
			player_attr_auto_allocate_success.emit(data)
			return
		if action_type == "player_attr_spend_points":
			player_attr_spend_success.emit(data)
			return
		if action_type == "player_talent_allocate":
			player_talent_allocate_success.emit(data)
			return
		if action_type == "player_talent_reset":
			player_talent_reset_success.emit(data)
			return
		if action_type == "player_attr_auto_plan":
			player_attr_plan_success.emit(data)
			return
		if action_type == "pet_bag_store":
			pet_bag_store_success.emit(data)
			return
		if action_type == "pet_bag_store_batch":
			pet_bag_store_batch_success.emit(data)
			return
		if action_type == "pet_bag_retrieve":
			pet_bag_retrieve_success.emit(data)
			return
		if action_type == "pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_success.emit(data)
			return
		if action_type == "pet_assist_equip":
			pet_assist_equip_success.emit(data)
			return
		if action_type == "pet_assist_unequip":
			pet_assist_unequip_success.emit(data)
			return
		if action_type == "pet_collection_invest":
			pet_collection_invest_success.emit(data)
			return
		if action_type == "equipment_equip":
			equipment_equip_success.emit(data)
			return
		if action_type == "equipment_unequip":
			equipment_unequip_success.emit(data)
			return
		if action_type == "pet_equipment_equip":
			pet_equipment_equip_success.emit(data)
			return
		if action_type == "pet_equipment_unequip":
			pet_equipment_unequip_success.emit(data)
			return
		if action_type == "equipment_unseal_suit":
			equipment_unseal_suit_success.emit(data)
			return
		if action_type == "equipment_suit_convert":
			equipment_suit_convert_success.emit(data)
			return
		if action_type == "equipment_dismantle_suit":
			equipment_dismantle_suit_success.emit(data)
			return
		if action_type == "equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_success.emit(data)
			return
		if action_type == "equipment_store_warehouse":
			equipment_store_warehouse_success.emit(data)
			return
		if action_type == "equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_success.emit(data)
			return
		if action_type == "pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_success.emit(data)
			return
		if action_type == "pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_success.emit(data)
			return
		if action_type == "pet_equipment_dismantle":
			pet_equipment_dismantle_success.emit(data)
			return
		if action_type == "pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_success.emit(data)
			return
		if action_type == "pet_equipment_drop":
			pet_equipment_drop_success.emit(data)
			return
		if action_type == "pet_equipment_enhance":
			pet_equipment_enhance_success.emit(data)
			return
		if action_type == "pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_success.emit(data)
			return
		if action_type == "inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_success.emit(data)
			return
		if action_type == "pill_craft":
			pill_craft_success.emit(data)
			return
		if action_type == "suit_equipment_enhance":
			suit_equipment_enhance_success.emit(data)
			return
		if action_type == "suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_success.emit(data)
			return
		if action_type == "pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_success_deferred", data)
			return
		if action_type == "equipment_grant":
			equipment_grant_success.emit(data)
			return
		if action_type == "equipment_drop":
			equipment_drop_success.emit(data)
			return
		if action_type == "inventory_drop":
			inventory_drop_success.emit(data)
			return
		if action_type == "inventory_store_warehouse":
			inventory_store_warehouse_success.emit(data)
			return
		if action_type == "inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_success.emit(data)
			return
		if action_type == "equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_success.emit(data)
			return
		if action_type == "frontier_gift_use":
			frontier_gift_use_success.emit(data)
			return
		if action_type == "pet_egg_open":
			pet_egg_open_success.emit(data)
			return
		if action_type == "pet_gift_open":
			pet_gift_open_success.emit(data)
			return
		if action_type == "pet_medal_use":
			pet_medal_use_success.emit(data)
			return
		if action_type == "pet_medal_use_batch":
			pet_medal_use_batch_success.emit(data)
			return
		if action_type == "pet_skill_synthetic":
			pet_skill_synthetic_success.emit(data)
			return
		if action_type == "pet_skill_split":
			pet_skill_split_success.emit(data)
			return
		if action_type == "pet_skill_learn":
			pet_skill_learn_success.emit(data)
			return
		if action_type == "pet_skill_unlearn":
			pet_skill_unlearn_success.emit(data)
			return
		if action_type == "pet_skill_slot_lock":
			pet_skill_slot_lock_success.emit(data)
			return
		if action_type == "pet_skill_sync":
			pet_skill_sync_success.emit(data)
			return
		if action_type == "pet_skill_level_up":
			pet_skill_level_up_success.emit(data)
			return
		if action_type == "pet_grant_medal":
			pet_grant_medal_success.emit(data)
			return
		if action_type == "pet_max_level_learn":
			pet_max_level_learn_success.emit(data)
			return
		if action_type == "forge_preview":
			forge_preview_success.emit(data)
			return
		if action_type == "forge_execute":
			forge_execute_success.emit(data)
			return
		if action_type == "realm_transition":
			realm_transition_success.emit(data)
			return

		if data.get("duplicate"):
			if not _authority_response_has_save_data(data):
				if _duplicate_resync_supports_action_type(action_type):
					_begin_duplicate_resync_download(action_type, data)
					return
			if action_type == "pet_merge":
				pet_merge_success.emit(data)
				return
			elif action_type == "pet_reincarnation":
				pet_reincarnation_success.emit(data)
				return
			elif action_type == "pet_reincarnation_inherit":
				pet_reincarnation_inherit_success.emit(data)
				return
			elif action_type == "pet_evolve":
				pet_evolve_success.emit(data)
				return
			elif action_type == "pet_refine":
				pet_refine_success.emit(data)
				return
			elif action_type == "pet_release":
				pet_release_success.emit(data)
				return
			elif action_type == "pet_release_batch":
				pet_release_batch_success.emit(data)
				return
			elif action_type == "pet_bag_store":
				pet_bag_store_success.emit(data)
				return
			elif action_type == "pet_bag_store_batch":
				pet_bag_store_batch_success.emit(data)
				return
			elif action_type == "pet_bag_retrieve":
				pet_bag_retrieve_success.emit(data)
				return
			elif action_type == "pet_bag_retrieve_batch":
				pet_bag_retrieve_batch_success.emit(data)
				return
			elif action_type == "pet_assist_equip":
				pet_assist_equip_success.emit(data)
				return
			elif action_type == "pet_assist_unequip":
				pet_assist_unequip_success.emit(data)
				return
			elif action_type == "pet_collection_invest":
				pet_collection_invest_success.emit(data)
				return
			elif action_type == "pet_soul_commit":
				pet_soul_commit_success.emit(data)
				return
			elif action_type == "pet_soul_commit_batch":
				pet_soul_commit_batch_success.emit(data)
				return
			elif action_type == "pet_soul_use_item":
				pet_soul_use_item_success.emit(data)
				return
			elif action_type == "equipment_equip":
				equipment_equip_success.emit(data)
				return
			elif action_type == "equipment_unequip":
				equipment_unequip_success.emit(data)
				return
			elif action_type == "equipment_unseal_suit":
				equipment_unseal_suit_success.emit(data)
				return
			elif action_type == "equipment_suit_convert":
				equipment_suit_convert_success.emit(data)
				return
			elif action_type == "equipment_dismantle_suit":
				equipment_dismantle_suit_success.emit(data)
				return
			elif action_type == "equipment_dismantle_suit_batch":
				equipment_dismantle_suit_batch_success.emit(data)
				return
			elif action_type == "equipment_store_warehouse":
				equipment_store_warehouse_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse":
				equipment_retrieve_warehouse_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse_batch":
				inventory_store_warehouse_batch_success.emit(data)
				return
			elif action_type == "equipment_retrieve_warehouse_batch":
				equipment_retrieve_warehouse_batch_success.emit(data)
				return
			elif action_type == "pet_equipment_equip":
				pet_equipment_equip_success.emit(data)
				return
			elif action_type == "pet_equipment_unequip":
				pet_equipment_unequip_success.emit(data)
				return
			elif action_type == "pet_equipment_store_warehouse":
				pet_equipment_store_warehouse_success.emit(data)
				return
			elif action_type == "pet_equipment_retrieve_warehouse":
				pet_equipment_retrieve_warehouse_success.emit(data)
				return
			elif action_type == "pet_equipment_dismantle":
				pet_equipment_dismantle_success.emit(data)
				return
			elif action_type == "pet_equipment_dismantle_batch":
				pet_equipment_dismantle_batch_success.emit(data)
				return
			elif action_type == "pet_equipment_drop":
				pet_equipment_drop_success.emit(data)
				return
			elif action_type == "pet_equipment_enhance":
				pet_equipment_enhance_success.emit(data)
				return
			elif action_type == "pet_equipment_synthesize_fragments":
				pet_equipment_synthesize_fragments_success.emit(data)
				return
			elif action_type == "inventory_synthesize_seal_stone":
				inventory_synthesize_seal_stone_success.emit(data)
				return
			elif action_type == "pill_craft":
				pill_craft_success.emit(data)
				return
			elif action_type == "suit_equipment_enhance":
				suit_equipment_enhance_success.emit(data)
				return
			elif action_type == "suit_equipment_enhance_confirm":
				suit_equipment_enhance_confirm_success.emit(data)
				return
			elif action_type == "pet_equipment_grant":
				call_deferred("_emit_pet_equipment_grant_success_deferred", data)
				return
			elif action_type == "equipment_drop":
				equipment_drop_success.emit(data)
				return
			elif action_type == "inventory_drop":
				inventory_drop_success.emit(data)
				return
			elif action_type == "inventory_store_warehouse":
				inventory_store_warehouse_success.emit(data)
				return
			elif action_type == "frontier_gift_use":
				frontier_gift_use_success.emit(data)
				return
			elif action_type == "pet_egg_open":
				pet_egg_open_success.emit(data)
				return
			elif action_type == "pet_gift_open":
				pet_gift_open_success.emit(data)
				return
			elif action_type == "pet_medal_use":
				pet_medal_use_success.emit(data)
				return
			elif action_type == "pet_medal_use_batch":
				pet_medal_use_batch_success.emit(data)
				return
			elif action_type == "forge_preview":
				forge_preview_success.emit(data)
				return
			elif action_type == "pet_skill_synthetic":
				pet_skill_synthetic_success.emit(data)
				return
			elif action_type == "pet_skill_split":
				pet_skill_split_success.emit(data)
				return
			elif action_type == "pet_skill_learn":
				pet_skill_learn_success.emit(data)
				return
			elif action_type == "pet_skill_unlearn":
				pet_skill_unlearn_success.emit(data)
				return
			elif action_type == "pet_skill_slot_lock":
				pet_skill_slot_lock_success.emit(data)
				return
			elif action_type == "pet_skill_sync":
				pet_skill_sync_success.emit(data)
				return
			elif action_type == "forge_execute":
				forge_execute_success.emit(data)
				return
			elif action_type == "realm_transition":
				realm_transition_success.emit(data)
				return
		var msg = String(data.get("message", "请求成功"))
		if action_type == "pet_merge":
			pet_merge_failed.emit(msg)
		elif action_type == "pet_reincarnation":
			pet_reincarnation_failed.emit(msg)
		elif action_type == "pet_reincarnation_inherit":
			pet_reincarnation_inherit_failed.emit(msg)
		elif action_type == "pet_evolve":
			pet_evolve_failed.emit(msg)
		elif action_type == "pet_release":
			pet_release_failed.emit(msg)
		elif action_type == "pet_release_batch":
			pet_release_batch_failed.emit(msg)
		elif action_type == "pet_refine_validate":
			pet_refine_validate_done.emit({"success": false, "error": msg})
		elif action_type == "pet_roster_sync":
			pet_roster_sync_failed.emit(msg)
		elif action_type == "pet_refine":
			pet_refine_failed.emit(msg)
		elif action_type == "player_attr_auto_allocate":
			player_attr_auto_allocate_failed.emit(msg)
		elif action_type == "player_attr_spend_points":
			player_attr_spend_failed.emit(msg)
		elif action_type == "player_talent_allocate":
			player_talent_allocate_failed.emit(msg)
		elif action_type == "player_talent_reset":
			player_talent_reset_failed.emit(msg)
		elif action_type == "player_attr_auto_plan":
			player_attr_plan_failed.emit(msg)
		elif action_type == "pet_bag_store":
			pet_bag_store_failed.emit(msg)
		elif action_type == "pet_bag_store_batch":
			pet_bag_store_batch_failed.emit(msg)
		elif action_type == "pet_bag_retrieve":
			pet_bag_retrieve_failed.emit(msg)
		elif action_type == "pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_failed.emit(msg)
		elif action_type == "pet_assist_equip":
			pet_assist_equip_failed.emit(msg)
		elif action_type == "pet_assist_unequip":
			pet_assist_unequip_failed.emit(msg)
		elif action_type == "pet_collection_invest":
			pet_collection_invest_failed.emit(msg)
		elif action_type == "pet_soul_commit":
			pet_soul_commit_failed.emit(msg)
		elif action_type == "pet_soul_commit_batch":
			pet_soul_commit_batch_failed.emit(msg)
		elif action_type == "pet_soul_use_item":
			pet_soul_use_item_failed.emit(msg)
		elif action_type == "equipment_equip":
			equipment_equip_failed.emit(msg)
		elif action_type == "equipment_unequip":
			equipment_unequip_failed.emit(msg)
		elif action_type == "equipment_unseal_suit":
			equipment_unseal_suit_failed.emit(msg)
		elif action_type == "equipment_suit_convert":
			equipment_suit_convert_failed.emit(msg)
		elif action_type == "equipment_dismantle_suit":
			equipment_dismantle_suit_failed.emit(msg)
		elif action_type == "equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_failed.emit(msg)
		elif action_type == "pet_equipment_equip":
			pet_equipment_equip_failed.emit(msg)
		elif action_type == "pet_equipment_unequip":
			pet_equipment_unequip_failed.emit(msg)
		elif action_type == "pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_failed.emit(msg)
		elif action_type == "pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_failed.emit(msg)
		elif action_type == "pet_equipment_dismantle":
			pet_equipment_dismantle_failed.emit(msg)
		elif action_type == "pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_failed.emit(msg)
		elif action_type == "pet_equipment_drop":
			pet_equipment_drop_failed.emit(msg)
		elif action_type == "pet_equipment_enhance":
			pet_equipment_enhance_failed.emit(msg)
		elif action_type == "pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_failed.emit(msg)
		elif action_type == "inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_failed.emit(msg)
		elif action_type == "pill_craft":
			pill_craft_failed.emit(msg)
		elif action_type == "suit_equipment_enhance":
			suit_equipment_enhance_failed.emit(msg)
		elif action_type == "suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_failed.emit(msg)
		elif action_type == "pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_failed_deferred", str(msg))
		elif action_type == "equipment_grant":
			equipment_grant_failed.emit(msg)
		elif action_type == "equipment_drop":
			equipment_drop_failed.emit(msg)
		elif action_type == "inventory_drop":
			inventory_drop_failed.emit(msg)
		elif action_type == "inventory_store_warehouse":
			inventory_store_warehouse_failed.emit(msg)
		elif action_type == "frontier_gift_use":
			frontier_gift_use_failed.emit(msg)
		elif action_type == "pet_egg_open":
			pet_egg_open_failed.emit(msg)
		elif action_type == "pet_gift_open":
			pet_gift_open_failed.emit(msg)
		elif action_type == "pet_medal_use":
			pet_medal_use_failed.emit(msg)
		elif action_type == "pet_medal_use_batch":
			pet_medal_use_batch_failed.emit(msg)
		elif action_type == "equipment_store_warehouse":
			equipment_store_warehouse_failed.emit(msg)
		elif action_type == "equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_failed.emit(msg)
		elif action_type == "forge_preview":
			forge_preview_failed.emit(msg)
		elif action_type == "pet_skill_synthetic":
			pet_skill_synthetic_failed.emit(msg)
		elif action_type == "pet_skill_split":
			pet_skill_split_failed.emit(msg)
		elif action_type == "pet_skill_learn":
			pet_skill_learn_failed.emit(msg)
		elif action_type == "pet_skill_unlearn":
			pet_skill_unlearn_failed.emit(msg)
		elif action_type == "pet_skill_slot_lock":
			pet_skill_slot_lock_failed.emit(msg)
		elif action_type == "pet_skill_sync":
			pet_skill_sync_failed.emit(msg)
		elif action_type == "pet_skill_level_up":
			pet_skill_level_up_failed.emit(msg)
		elif action_type == "pet_max_level_learn":
			pet_max_level_learn_failed.emit(msg)
		elif action_type == "forge_execute":
			forge_execute_failed.emit(msg)
		elif action_type == "realm_transition":
			realm_transition_failed.emit(msg)
		return

	if response_code == 200 and action_type == "suit_equipment_enhance" and data.get("saveData") is Dictionary:
		suit_equipment_enhance_success.emit(data)
		return

	if action_type == "suit_equipment_enhance" and response_code == 409 and data.get("saveData") is Dictionary:
		var pending_payload: = _suit_enhance_success_payload_from_save_data(data)
		if not pending_payload.is_empty():
			suit_equipment_enhance_success.emit(pending_payload)
			return
	var err_part: = str(data.get("error", "")).strip_edges()
	var msg_part: = str(data.get("message", "")).strip_edges()
	var err_msg: = err_part if not err_part.is_empty() else (msg_part if not msg_part.is_empty() else "服务器错误")
	if action_type == "pet_merge":
		pet_merge_failed.emit(err_msg)
	elif action_type == "pet_reincarnation":
		pet_reincarnation_failed.emit(err_msg)
	elif action_type == "pet_reincarnation_inherit":
		pet_reincarnation_inherit_failed.emit(err_msg)
	elif action_type == "pet_evolve":
		pet_evolve_failed.emit(err_msg)
	elif action_type == "pet_release":
		pet_release_failed.emit(err_msg)
	elif action_type == "pet_release_batch":
		pet_release_batch_failed.emit(err_msg)
	elif action_type == "pet_refine_validate":
		pet_refine_validate_done.emit({"success": false, "error": err_msg})
	elif action_type == "pet_roster_sync":
		pet_roster_sync_failed.emit(err_msg)
	elif action_type == "pet_refine":
		pet_refine_failed.emit(err_msg)
	elif action_type == "player_attr_auto_allocate":
		player_attr_auto_allocate_failed.emit(err_msg)
	elif action_type == "player_attr_spend_points":
		player_attr_spend_failed.emit(err_msg)
	elif action_type == "player_talent_allocate":
		player_talent_allocate_failed.emit(err_msg)
	elif action_type == "player_talent_reset":
		player_talent_reset_failed.emit(err_msg)
	elif action_type == "player_attr_auto_plan":
		player_attr_plan_failed.emit(err_msg)
	elif action_type == "pet_bag_store":
		pet_bag_store_failed.emit(err_msg)
	elif action_type == "pet_bag_store_batch":
		pet_bag_store_batch_failed.emit(err_msg)
	elif action_type == "pet_bag_retrieve":
		pet_bag_retrieve_failed.emit(err_msg)
	elif action_type == "pet_bag_retrieve_batch":
		pet_bag_retrieve_batch_failed.emit(err_msg)
	elif action_type == "pet_assist_equip":
		pet_assist_equip_failed.emit(err_msg)
	elif action_type == "pet_assist_unequip":
		pet_assist_unequip_failed.emit(err_msg)
	elif action_type == "pet_collection_invest":
		pet_collection_invest_failed.emit(err_msg)
	elif action_type == "pet_soul_commit":
		pet_soul_commit_failed.emit(err_msg)
	elif action_type == "pet_soul_commit_batch":
		pet_soul_commit_batch_failed.emit(err_msg)
	elif action_type == "pet_soul_use_item":
		pet_soul_use_item_failed.emit(err_msg)
	elif action_type == "equipment_equip":
		equipment_equip_failed.emit(err_msg)
	elif action_type == "equipment_unequip":
		equipment_unequip_failed.emit(err_msg)
	elif action_type == "equipment_unseal_suit":
		equipment_unseal_suit_failed.emit(err_msg)
	elif action_type == "equipment_suit_convert":
		equipment_suit_convert_failed.emit(err_msg)
	elif action_type == "equipment_dismantle_suit":
		equipment_dismantle_suit_failed.emit(err_msg)
	elif action_type == "equipment_dismantle_suit_batch":
		equipment_dismantle_suit_batch_failed.emit(err_msg)
	elif action_type == "equipment_store_warehouse":
		equipment_store_warehouse_failed.emit(err_msg)
	elif action_type == "equipment_retrieve_warehouse":
		equipment_retrieve_warehouse_failed.emit(err_msg)
	elif action_type == "pet_equipment_equip":
		pet_equipment_equip_failed.emit(err_msg)
	elif action_type == "pet_equipment_unequip":
		pet_equipment_unequip_failed.emit(err_msg)
	elif action_type == "pet_equipment_store_warehouse":
		pet_equipment_store_warehouse_failed.emit(err_msg)
	elif action_type == "pet_equipment_retrieve_warehouse":
		pet_equipment_retrieve_warehouse_failed.emit(err_msg)
	elif action_type == "pet_egg_open":
		pet_egg_open_failed.emit(err_msg)
	elif action_type == "pet_gift_open":
		pet_gift_open_failed.emit(err_msg)
	elif action_type == "pet_medal_use":
		pet_medal_use_failed.emit(err_msg)
	elif action_type == "pet_medal_use_batch":
		pet_medal_use_batch_failed.emit(err_msg)
	elif action_type == "pet_equipment_dismantle":
		pet_equipment_dismantle_failed.emit(err_msg)
	elif action_type == "pet_equipment_dismantle_batch":
		pet_equipment_dismantle_batch_failed.emit(err_msg)
	elif action_type == "pet_equipment_drop":
		pet_equipment_drop_failed.emit(err_msg)
	elif action_type == "pet_equipment_enhance":
		pet_equipment_enhance_failed.emit(err_msg)
	elif action_type == "pet_equipment_synthesize_fragments":
		pet_equipment_synthesize_fragments_failed.emit(err_msg)
	elif action_type == "inventory_synthesize_seal_stone":
		inventory_synthesize_seal_stone_failed.emit(err_msg)
	elif action_type == "pill_craft":
		pill_craft_failed.emit(err_msg)
	elif action_type == "suit_equipment_enhance":
		if err_msg.find("请先处理上次套装强化") >= 0 and _try_begin_suit_enhance_ambiguous_resync(action_type, data, "pending_recovery"):
			return
		suit_equipment_enhance_failed.emit(err_msg)
	elif action_type == "suit_equipment_enhance_confirm":
		suit_equipment_enhance_confirm_failed.emit(err_msg)
	elif action_type == "pet_equipment_grant":
		call_deferred("_emit_pet_equipment_grant_failed_deferred", err_msg)
	elif action_type == "equipment_grant":
		equipment_grant_failed.emit(err_msg)
	elif action_type == "equipment_drop":
		equipment_drop_failed.emit(err_msg)
	elif action_type == "inventory_drop":
		inventory_drop_failed.emit(err_msg)
	elif action_type == "inventory_store_warehouse":
		inventory_store_warehouse_failed.emit(err_msg)
	elif action_type == "frontier_gift_use":
		frontier_gift_use_failed.emit(err_msg)
	elif action_type == "forge_preview":
		forge_preview_failed.emit(err_msg)
	elif action_type == "pet_skill_synthetic":
		pet_skill_synthetic_failed.emit(err_msg)
	elif action_type == "pet_skill_split":
		pet_skill_split_failed.emit(err_msg)
	elif action_type == "pet_skill_learn":
		pet_skill_learn_failed.emit(err_msg)
	elif action_type == "pet_skill_unlearn":
		pet_skill_unlearn_failed.emit(err_msg)
	elif action_type == "pet_skill_slot_lock":
		pet_skill_slot_lock_failed.emit(err_msg)
	elif action_type == "pet_skill_sync":
		pet_skill_sync_failed.emit(err_msg)
	elif action_type == "pet_skill_level_up":
		pet_skill_level_up_failed.emit(err_msg)
	elif action_type == "pet_max_level_learn":
		pet_max_level_learn_failed.emit(err_msg)
	elif action_type == "forge_execute":
		forge_execute_failed.emit(err_msg)
	elif action_type == "realm_transition":
		realm_transition_failed.emit(err_msg)

func _on_xianmo_chest_dedicated_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		xianmo_chest_deposit_failed.emit("网络请求失败")
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		xianmo_chest_deposit_failed.emit("服务器返回数据格式错误")
		return
	var data = json.data
	if not data is Dictionary:
		xianmo_chest_deposit_failed.emit("服务器返回数据格式错误")
		return
	_apply_server_save_revision(data)
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		xianmo_chest_deposit_failed.emit("当前客户端版本过低，请更新后继续游戏")
		return
	var s = data.get("success", false)

	var ok_success: bool = (typeof(s) == TYPE_BOOL and s) or (typeof(s) == TYPE_INT and int(s) != 0)
	var dup = data.get("duplicate", false)
	var is_dup: bool = (typeof(dup) == TYPE_BOOL and dup) or (typeof(dup) == TYPE_INT and int(dup) != 0)
	if response_code == 200 and (ok_success or is_dup):

		call_deferred("_emit_xianmo_deposit_success_deferred", data)
		return
	var err_msg: String = str(data.get("error", "同步失败"))
	call_deferred("_emit_xianmo_deposit_failed_deferred", err_msg)

func _emit_xianmo_deposit_success_deferred(data: Dictionary) -> void :
	xianmo_chest_deposit_success.emit(data)

func _emit_xianmo_deposit_failed_deferred(err_msg: String) -> void :
	xianmo_chest_deposit_failed.emit(err_msg)

func _emit_pet_equipment_grant_success_deferred(data: Dictionary) -> void :
	pet_equipment_grant_success.emit(data)

func _emit_pet_equipment_grant_failed_deferred(error: String) -> void :
	pet_equipment_grant_failed.emit(error)


func wait_until_xianmo_chest_http_idle(max_wait_ms: int) -> void :
	var tree = get_tree()
	if tree == null:
		return
	var t0: int = Time.get_ticks_msec()
	while xianmo_chest_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if Time.get_ticks_msec() - t0 >= max_wait_ms:
			return
		await tree.process_frame


func get_economy_battle_loot_wait_deadline_ms() -> int:
	if economy_battle_loot_request == null:
		return int(ECONOMY_BATTLE_LOOT_HTTP_TIMEOUT_SEC * 1000.0) + 35000

	return int(economy_battle_loot_request.timeout * 1000.0) + 35000

func get_economy_tower_clear_wait_deadline_ms() -> int:
	if economy_tower_clear_request == null:
		return int(ECONOMY_TOWER_CLEAR_HTTP_TIMEOUT_SEC * 1000.0) + 3000

	return int(economy_tower_clear_request.timeout * 1000.0) + 3000

func get_fe_dungeon_wait_deadline_ms() -> int:
	if fe_dungeon_request == null:
		return int(FE_DUNGEON_HTTP_TIMEOUT_SEC * 1000.0) + 3000
	return int(fe_dungeon_request.timeout * 1000.0) + 3000

func _economy_battle_loot_stop_watchdog() -> void :
	if _economy_bl_watchdog:
		_economy_bl_watchdog.stop()

func _on_economy_battle_loot_watchdog_timeout() -> void :
	print("[Network] economy_battle_loot watchdog: cancel_request (no timely request_completed)")
	if economy_battle_loot_request:
		economy_battle_loot_request.cancel_request()

func _enqueue_economy_battle_loot_dedicated(json_body: String, request_id: String = "") -> void :
	_economy_battle_loot_queue.append({"json": json_body, "request_id": request_id})
	_pump_economy_battle_loot_dedicated()


func cancel_pending_economy_battle_loot(reason: String = "战斗已停止") -> void :
	var why: = reason.strip_edges()
	if why.is_empty():
		why = "战斗已停止"
	var in_flight: = (
		economy_battle_loot_request != null
		and economy_battle_loot_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED
	)
	if in_flight:
		while _economy_battle_loot_queue.size() > 1:
			var item: Variant = _economy_battle_loot_queue.pop_back()
			var rid: = str(item.get("request_id", "")) if item is Dictionary else ""
			if not rid.is_empty():
				economy_result.emit(rid, "economy_battle_loot", false, {"code": "BATTLE_LOOT_CANCELLED"}, why)
	else:
		while not _economy_battle_loot_queue.is_empty():
			var item: Variant = _economy_battle_loot_queue.pop_front()
			var rid: = str(item.get("request_id", "")) if item is Dictionary else ""
			if not rid.is_empty():
				economy_result.emit(rid, "economy_battle_loot", false, {"code": "BATTLE_LOOT_CANCELLED"}, why)
	_economy_battle_loot_stop_watchdog()
	_economy_bl_disc_defers = 0
	_economy_bl_err_busy_defers = 0

func _pump_economy_battle_loot_dedicated() -> void :
	if _economy_battle_loot_queue.is_empty():
		_economy_bl_disc_defers = 0
		_economy_bl_err_busy_defers = 0
		return
	if economy_battle_loot_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_economy_bl_disc_defers += 1
		if _economy_bl_disc_defers > ECONOMY_BL_MAX_NOT_DISCONNECTED_DEFERS:
			_economy_bl_disc_defers = 0
			push_warning("[Network] economy_battle_loot: client stuck not DISCONNECTED, cancel_request")
			economy_battle_loot_request.cancel_request()
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	_economy_bl_disc_defers = 0
	if auth_token == "":
		_economy_battle_loot_stop_watchdog()
		var req_item = _economy_battle_loot_queue.pop_front()
		var rid = str(req_item.get("request_id", "")) if req_item is Dictionary else ""
		economy_result.emit(rid, "economy_battle_loot", false, {}, "未登录")
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	var item: Dictionary = _economy_battle_loot_queue[0]
	var headers: = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var err: = economy_battle_loot_request.request(server_url + "/economy/battle-loot", headers, HTTPClient.METHOD_POST, String(item.get("json", "")))
	if err != OK:
		if err == ERR_BUSY:
			_economy_bl_err_busy_defers += 1
			if _economy_bl_err_busy_defers > ECONOMY_BL_MAX_ERR_BUSY_DEFERS:
				_economy_bl_err_busy_defers = 0
				var busy_item = _economy_battle_loot_queue.pop_front()
				var busy_rid = str(busy_item.get("request_id", "")) if busy_item is Dictionary else ""
				economy_result.emit(busy_rid, "economy_battle_loot", false, {}, "打怪结算通道忙（ERR_BUSY），请稍后重试")
				call_deferred("_pump_economy_battle_loot_dedicated")
				return
			call_deferred("_pump_economy_battle_loot_dedicated")
			return
		_economy_bl_err_busy_defers = 0
		_economy_battle_loot_stop_watchdog()
		var fail_item = _economy_battle_loot_queue.pop_front()
		var fail_rid = str(fail_item.get("request_id", "")) if fail_item is Dictionary else ""
		economy_result.emit(fail_rid, "economy_battle_loot", false, {}, "网络请求失败")
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	_economy_bl_err_busy_defers = 0
	if _economy_bl_watchdog:
		_economy_bl_watchdog.wait_time = economy_battle_loot_request.timeout + 30.0
		_economy_bl_watchdog.start()

func _on_economy_battle_loot_dedicated_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
	_economy_battle_loot_stop_watchdog()
	if _economy_battle_loot_queue.is_empty():
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		var front_item = _economy_battle_loot_queue.pop_front()
		var completed_rid: = str(front_item.get("request_id", "")) if front_item is Dictionary else ""
		var error_msg: = "网络请求失败"
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析服务器地址"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS握手失败"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "服务器无响应"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "请求超时（网络慢或服务器繁忙，可稍后再试）"
		economy_result.emit(completed_rid, "economy_battle_loot", false, {}, error_msg)
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		var front_item2 = _economy_battle_loot_queue.pop_front()
		var bad_rid: = str(front_item2.get("request_id", "")) if front_item2 is Dictionary else ""
		economy_result.emit(bad_rid, "economy_battle_loot", false, {}, "JSON解析失败")
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	var data = json.data
	if data == null:
		var front_item3 = _economy_battle_loot_queue.pop_front()
		var null_rid: = str(front_item3.get("request_id", "")) if front_item3 is Dictionary else ""
		economy_result.emit(null_rid, "economy_battle_loot", false, {}, "服务器返回数据为空")
		call_deferred("_pump_economy_battle_loot_dedicated")
		return
	if not data is Dictionary:
		var front_item4 = _economy_battle_loot_queue.pop_front()
		var bad2_rid: = str(front_item4.get("request_id", "")) if front_item4 is Dictionary else ""
		economy_result.emit(bad2_rid, "economy_battle_loot", false, {}, "服务器返回数据格式错误")
		call_deferred("_pump_economy_battle_loot_dedicated")
		return

	if response_code == 429:
		var t: = get_tree().create_timer(2.0, true)
		t.timeout.connect(_pump_economy_battle_loot_dedicated, CONNECT_ONE_SHOT)
		return
	if response_code == 200:
		var front_ok = _economy_battle_loot_queue.pop_front()
		var ok_rid: = str(front_ok.get("request_id", "")) if front_ok is Dictionary else ""
		if data.get("success", false):
			economy_result.emit(ok_rid, "economy_battle_loot", true, data, "")
		else:
			var econ_err: = str(data.get("error", data.get("message", "经济结算失败")))
			if econ_err.is_empty():
				econ_err = "经济结算失败"
			economy_result.emit(ok_rid, "economy_battle_loot", false, data, econ_err)
	else:
		var front_fail = _economy_battle_loot_queue.pop_front()
		var fail_rid: = str(front_fail.get("request_id", "")) if front_fail is Dictionary else ""
		var error_msg: = str(data.get("error", "服务器错误 (HTTP %d)" % response_code))
		economy_result.emit(fail_rid, "economy_battle_loot", false, data, error_msg)
	call_deferred("_pump_economy_battle_loot_dedicated")

func _enqueue_economy_tower_clear_dedicated(json_body: String, request_id: String = "") -> void :
	_economy_tower_clear_queue.append({"json": json_body, "request_id": request_id})
	_pump_economy_tower_clear_dedicated()

func _pump_economy_tower_clear_dedicated() -> void :
	if _economy_tower_clear_queue.is_empty():
		return
	if economy_tower_clear_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	if auth_token == "":
		var req_item = _economy_tower_clear_queue.pop_front()
		var rid = str(req_item.get("request_id", "")) if req_item is Dictionary else ""
		economy_result.emit(rid, "economy_tower_clear", false, {}, "未登录")
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	var item: Dictionary = _economy_tower_clear_queue[0]
	var headers: = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var err: = economy_tower_clear_request.request(server_url + "/economy/tower-clear-reward", headers, HTTPClient.METHOD_POST, String(item.get("json", "")))
	if err != OK:
		var fail_item = _economy_tower_clear_queue.pop_front()
		var fail_rid = str(fail_item.get("request_id", "")) if fail_item is Dictionary else ""
		var err_msg: = "网络请求失败"
		if err == ERR_BUSY:
			err_msg = "天关结算通道忙，请稍后重试"
		economy_result.emit(fail_rid, "economy_tower_clear", false, {}, err_msg)
		call_deferred("_pump_economy_tower_clear_dedicated")

func _on_economy_tower_clear_dedicated_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
	var completed_rid: = ""
	if not _economy_tower_clear_queue.is_empty():
		var front_item = _economy_tower_clear_queue.pop_front()
		completed_rid = str(front_item.get("request_id", "")) if front_item is Dictionary else ""
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg: = "网络请求失败"
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析服务器地址"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS握手失败"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "服务器无响应"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "请求超时（天关结算稍后重试）"
		economy_result.emit(completed_rid, "economy_tower_clear", false, {}, error_msg)
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		economy_result.emit(completed_rid, "economy_tower_clear", false, {}, "JSON解析失败")
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	var data = json.data
	if data == null:
		economy_result.emit(completed_rid, "economy_tower_clear", false, {}, "服务器返回数据为空")
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	if not data is Dictionary:
		economy_result.emit(completed_rid, "economy_tower_clear", false, {}, "服务器返回数据格式错误")
		call_deferred("_pump_economy_tower_clear_dedicated")
		return
	if response_code == 200:
		if data.get("success", false):
			economy_result.emit(completed_rid, "economy_tower_clear", true, data, "")
		else:
			var econ_err: = str(data.get("error", data.get("message", "经济结算失败")))
			if econ_err.is_empty():
				econ_err = "经济结算失败"
			economy_result.emit(completed_rid, "economy_tower_clear", false, data, econ_err)
	else:
		var error_msg: = str(data.get("error", "服务器错误 (HTTP %d)" % response_code))
		economy_result.emit(completed_rid, "economy_tower_clear", false, {}, error_msg)
	call_deferred("_pump_economy_tower_clear_dedicated")

func _enqueue_fe_dungeon_dedicated(op_type: String, path_suffix: String, json_body: String, request_id: String = "") -> void :
	_fe_dungeon_queue.append({
		"op_type": op_type, 
		"path": path_suffix, 
		"json": json_body, 
		"request_id": request_id, 
	})
	_pump_fe_dungeon_dedicated()

func _pump_fe_dungeon_dedicated() -> void :
	if _fe_dungeon_queue.is_empty():
		return
	if fe_dungeon_request == null:
		var bad_item = _fe_dungeon_queue.pop_front()
		_emit_fe_dungeon_dedicated_failure(bad_item, "五行副本通道未初始化")
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	if fe_dungeon_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	if auth_token == "":
		var req_item = _fe_dungeon_queue.pop_front()
		_emit_fe_dungeon_dedicated_failure(req_item, "未登录")
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	var item: Dictionary = _fe_dungeon_queue[0]
	var headers: = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var path_suffix: = str(item.get("path", ""))
	var err: = fe_dungeon_request.request(server_url + path_suffix, headers, HTTPClient.METHOD_POST, String(item.get("json", "")))
	if err != OK:
		var fail_item = _fe_dungeon_queue.pop_front()
		var err_msg: = "网络请求失败"
		if err == ERR_BUSY:
			err_msg = "五行副本通道忙，请稍后重试"
		_emit_fe_dungeon_dedicated_failure(fail_item, err_msg)
		call_deferred("_pump_fe_dungeon_dedicated")

func _fe_dungeon_http_error_msg(result: int, op_type: String) -> String:
	var label: = "五行副本开始失败" if op_type == "fe_dungeon_start" else "五行副本奖励失败"
	match result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "无法连接到服务器"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "无法解析服务器地址"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "连接错误"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS握手失败"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "服务器无响应"
		HTTPRequest.RESULT_TIMEOUT:
			return "请求超时（%s）" % label
	return "网络请求失败"

func _emit_fe_dungeon_dedicated_failure(item: Variant, err_msg: String) -> void :
	if not item is Dictionary:
		return
	var op_type: = str(item.get("op_type", ""))
	var rid: = str(item.get("request_id", ""))
	if op_type == "fe_dungeon_start":
		fe_dungeon_start_failed.emit(err_msg)
		economy_result.emit(rid, "fe_dungeon_start", false, {}, err_msg)
	elif op_type == "fe_dungeon_clear":
		fe_dungeon_clear_failed.emit(err_msg)
		economy_result.emit(rid, "fe_dungeon_clear", false, {}, err_msg)

func _emit_fe_dungeon_dedicated_result(op_type: String, rid: String, success: bool, data: Dictionary, err_msg: String) -> void :
	if op_type == "fe_dungeon_start":
		if success:
			fe_dungeon_start_success.emit(data)
			economy_result.emit(rid, "fe_dungeon_start", true, data, "")
		else:
			var fe_err: = err_msg
			if fe_err.is_empty():
				fe_err = "五行副本开始失败"
			fe_dungeon_start_failed.emit(fe_err)
			economy_result.emit(rid, "fe_dungeon_start", false, data, fe_err)
	elif op_type == "fe_dungeon_clear":
		if success:
			fe_dungeon_clear_success.emit(data)
			economy_result.emit(rid, "fe_dungeon_clear", true, data, "")
		else:
			var clear_err: = err_msg
			if clear_err.is_empty():
				clear_err = "五行副本奖励失败"
			fe_dungeon_clear_failed.emit(clear_err)
			economy_result.emit(rid, "fe_dungeon_clear", false, data, clear_err)

func _on_fe_dungeon_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	var completed_rid: = ""
	var op_type: = ""
	if not _fe_dungeon_queue.is_empty():
		var front_item = _fe_dungeon_queue.pop_front()
		if front_item is Dictionary:
			completed_rid = str(front_item.get("request_id", ""))
			op_type = str(front_item.get("op_type", ""))
	if op_type.is_empty():
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, {}, _fe_dungeon_http_error_msg(result, op_type))
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, {}, "JSON解析失败")
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	var data = json.data
	if data == null:
		_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, {}, "服务器返回数据为空")
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	if not data is Dictionary:
		_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, {}, "服务器返回数据格式错误")
		call_deferred("_pump_fe_dungeon_dedicated")
		return
	if response_code == 200:
		if data.get("success", false):
			_emit_fe_dungeon_dedicated_result(op_type, completed_rid, true, data, "")
		else:
			var econ_err: = str(data.get("error", data.get("message", "")))
			if econ_err.is_empty():
				econ_err = "五行副本开始失败" if op_type == "fe_dungeon_start" else "五行副本奖励失败"
			_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, data, econ_err)
	else:
		var http_err: = str(data.get("error", "服务器错误 (HTTP %d)" % response_code))
		_emit_fe_dungeon_dedicated_result(op_type, completed_rid, false, data, http_err)
	call_deferred("_pump_fe_dungeon_dedicated")

func _enqueue_shop_buy_dedicated(json_body: String, request_id: String = "") -> void :
	_shop_buy_queue.append({"json": json_body, "request_id": request_id})
	_pump_shop_buy_dedicated()

func _pump_shop_buy_dedicated() -> void :
	if _shop_buy_queue.is_empty():
		return
	if shop_buy_request == null:
		_shop_buy_queue.pop_front()
		shop_buy_failed.emit("购买通道未初始化")
		return
	if shop_buy_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		call_deferred("_pump_shop_buy_dedicated")
		return
	if auth_token == "":
		_shop_buy_queue.pop_front()
		shop_buy_failed.emit("未登录")
		call_deferred("_pump_shop_buy_dedicated")
		return
	var item: Dictionary = _shop_buy_queue[0]
	var headers: = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var err: = shop_buy_request.request(server_url + "/shop/buy", headers, HTTPClient.METHOD_POST, String(item.get("json", "")))
	if err != OK:
		_shop_buy_queue.pop_front()
		if err == ERR_BUSY:
			shop_buy_failed.emit("购买通道忙，请稍后再试")
		else:
			shop_buy_failed.emit("网络请求失败")
		call_deferred("_pump_shop_buy_dedicated")

func _on_shop_buy_dedicated_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if _shop_buy_queue.is_empty():
		return
	_shop_buy_queue.pop_front()
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg: = "网络请求失败"
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析服务器地址"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS握手失败"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "服务器无响应"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "请求超时，请稍后重试"
		shop_buy_failed.emit(error_msg)
		call_deferred("_pump_shop_buy_dedicated")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		shop_buy_failed.emit("JSON解析失败")
		call_deferred("_pump_shop_buy_dedicated")
		return
	var data = json.data
	if data == null or not (data is Dictionary):
		shop_buy_failed.emit("服务器返回数据格式错误")
		call_deferred("_pump_shop_buy_dedicated")
		return
	var payload: Dictionary = data
	if payload is Dictionary:
		_update_server_time_from_response_data(payload)
	if response_code == 200:
		if payload.get("success", false) or payload.get("duplicate", false):
			shop_buy_success.emit(payload)
		else:
			shop_buy_failed.emit(str(payload.get("error", payload.get("message", "购买失败"))))
	else:
		shop_buy_failed.emit(str(payload.get("error", "服务器错误 (HTTP %d)" % response_code)))
	call_deferred("_pump_shop_buy_dedicated")

func get_offline_info():
	if auth_token == "":
		offline_info_loaded.emit(0, true, 0)
		return
	_enqueue_request("offline_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/offline/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			offline_info_loaded.emit(0, true, 0)
			_complete_request()
	)

func send_offline_heartbeat():
	if auth_token == "":
		return
	_enqueue_request("offline_heartbeat", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/offline/heartbeat", headers, HTTPClient.METHOD_POST)
		if err != OK:
			_complete_request()
	)

func _emit_failure_signal(current_type: String, error_msg: String):
	if current_type.begins_with("economy_") or current_type == "fe_dungeon_start" or current_type == "fe_dungeon_clear" or current_type == "atlas_dungeon_start" or current_type == "atlas_dungeon_finish" or current_type == "pet_refine" or current_type == "pet_grant_starter":
		var fail_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
		if current_type == "fe_dungeon_start":
			fe_dungeon_start_failed.emit(error_msg)
		elif current_type == "fe_dungeon_clear":
			fe_dungeon_clear_failed.emit(error_msg)
		elif current_type == "atlas_dungeon_start":
			atlas_dungeon_start_failed.emit(error_msg)
		economy_result.emit(fail_rid, current_type, false, {}, error_msg)
		return
	match current_type:
		"register":
			_emit_register_failed(error_msg)
		"login":
			_emit_login_failed(error_msg)
		"download_save":
			save_downloaded.emit({"_download_error": true, "error_msg": error_msg})
		"upload_save":
			_handle_upload_failure()
		"vip_info":
			vip_info_failed.emit(error_msg)
		"ranking":
			ranking_loaded.emit([])
		"ranking_players":
			ranking_players_loaded.emit([])
		"ranking_pets":
			ranking_pets_loaded.emit([], "pets_evolution")
		"ranking_pets_evolution":
			ranking_pets_loaded.emit([], "pets_evolution")
		"ranking_pets_non_evolution":
			ranking_pets_loaded.emit([], "pets_non_evolution")
		"ranking_tower":
			ranking_loaded.emit([])
		"ranking_suit_dungeon":
			ranking_suit_dungeon_loaded.emit([])
		"tower_info":
			tower_info_loaded.emit(0, 0, 0)
		"martial_info":
			martial_info_failed.emit(error_msg)
		"martial_create":
			martial_create_failed.emit(error_msg)
		"martial_skill_book_use":
			martial_skill_book_failed.emit(error_msg)
		"pet_merge":
			pet_merge_failed.emit(error_msg)
		"pet_reincarnation":
			pet_reincarnation_failed.emit(error_msg)
		"pet_reincarnation_inherit":
			pet_reincarnation_inherit_failed.emit(error_msg)
		"pet_evolve":
			pet_evolve_failed.emit(error_msg)
		"offline_info":
			offline_info_loaded.emit(0, true, 0)
		"offline_heartbeat":
			pass
		"suit_dungeon_info":
			suit_dungeon_info_loaded.emit(0, 3)
		"suit_dungeon_sweep":
			suit_dungeon_sweep_failed.emit(error_msg)
		"fe_dungeon_status":
			fe_dungeon_status_failed.emit(error_msg)
		"fe_dungeon_start":
			fe_dungeon_start_failed.emit(error_msg)
		"fe_dungeon_clear":
			fe_dungeon_clear_failed.emit(error_msg)
		"atlas_dungeon_status":
			atlas_dungeon_status_failed.emit(error_msg)
		"atlas_dungeon_start":
			atlas_dungeon_start_failed.emit(error_msg)
		"xianmo_info":
			xianmo_info_loaded.emit({"joined": false})
		"xianmo_faction_stats":
			xianmo_faction_stats_loaded.emit({})
		"xianmo_ranking":
			xianmo_ranking_loaded.emit([], 0, "")
		"xianmo_adventure":
			xianmo_adventure_failed.emit(error_msg)
		"xianmo_shop_items":
			xianmo_shop_items_loaded.emit([])
		"xianmo_shop_buy":
			xianmo_shop_buy_failed.emit(error_msg)
		"shop_buy":
			shop_buy_failed.emit(error_msg)
		"main_shop_catalog":
			main_shop_catalog_failed.emit(error_msg)
		"xianmo_week_info":
			xianmo_week_info_loaded.emit({})
		"xianmo_chest_open":
			xianmo_chest_open_failed.emit(error_msg)
		"xianmo_chest_open_batch":
			xianmo_chest_open_batch_failed.emit(error_msg)
		"xianmo_chest_deposit":
			xianmo_chest_deposit_failed.emit(error_msg)
		"xianmo_treasure_exchange":
			xianmo_treasure_exchange_failed.emit(error_msg)
		"xianmo_treasure_use":
			xianmo_treasure_use_failed.emit(error_msg)
		"xianmo_mirror":
			xianmo_mirror_loaded.emit({})
		"xianmo_titles":
			xianmo_titles_loaded.emit([])
		"xianmo_title_activate":
			xianmo_title_activated.emit({"success": false})
		"xianmo_title_deactivate":
			xianmo_title_deactivated.emit({"success": false})
		"xianmo_broadcasts":
			xianmo_broadcasts_loaded.emit([])
		"xianmo_broadcast":
			xianmo_broadcast_sent.emit(false)
		"treasure_status":
			treasure_status_loaded.emit({})
		"treasure_join":
			treasure_join_failed.emit(error_msg)
		"treasure_participants":
			treasure_participants_loaded.emit([])
		"treasure_battle_log":
			treasure_battle_log_loaded.emit({})
		"treasure_open":
			treasure_open_failed.emit(error_msg)
		"xianmo_join":
			xianmo_join_failed.emit(error_msg)
		"lottery_draw":
			lottery_draw_failed.emit(error_msg)
		"lottery_pity_status":
			lottery_pity_status_failed.emit(error_msg)
		"lottery_pity_claim":
			lottery_pity_claim_failed.emit(error_msg)
		"noble_info":
			noble_info_failed.emit(error_msg)
		"noble_claim":
			noble_claim_failed.emit(error_msg)
		"brother_tower_start":
			brother_tower_start_failed.emit(error_msg)
		"brother_tower_create":
			brother_tower_create_failed.emit(error_msg)
		"brother_tower_join":
			brother_tower_join_failed.emit(error_msg)
		"brother_tower_application_decide":
			brother_tower_application_decide_failed.emit(error_msg)
		"brother_tower_ready":
			brother_tower_ready_failed.emit(error_msg)
		"brother_tower_pin_snapshot":
			brother_tower_pin_snapshot_failed.emit(error_msg)
		"brother_tower_list":
			brother_tower_list_failed.emit(error_msg)
		"brother_tower_wave_cleared":
			brother_tower_wave_cleared_failed.emit(error_msg)
		"brother_tower_complete":
			brother_tower_complete_failed.emit(error_msg)
		"brother_tower_battle_events_push":
			_dispatch_bt_push_result({"success": false, "error": error_msg})
		"brother_tower_battle_events_fetch":
			_dispatch_bt_fetch_result({"success": false, "error": error_msg, "events": []})
		"shengsi_tower_overview":
			shengsi_tower_overview_failed.emit(error_msg)
		"shengsi_tower_floor":
			shengsi_tower_floor_failed.emit(error_msg)
		"shengsi_tower_feed":
			shengsi_tower_feed_failed.emit(error_msg)
		"shengsi_tower_room_list":
			shengsi_tower_room_list_failed.emit(error_msg)
		"shengsi_tower_matchup":
			shengsi_tower_matchup_failed.emit(error_msg)
		"shengsi_tower_my_battles":
			shengsi_tower_my_battles_failed.emit(error_msg)
		"shengsi_tower_floor_battles":
			shengsi_tower_floor_battles_failed.emit(error_msg)
		"shengsi_tower_match":
			shengsi_tower_match_failed.emit(error_msg)
		"shengsi_tower_room_create", "shengsi_tower_room_join", "shengsi_tower_room_leave", "shengsi_tower_room_disband", "shengsi_tower_register", "shengsi_tower_unregister", "shengsi_tower_stance", "shengsi_tower_ready":
			shengsi_tower_action_failed.emit(current_type.replace("shengsi_tower_", ""), error_msg)

func _on_request_completed(result, response_code, headers, body):
	var current_type = _current_request_info.get("type", "") if _current_request_info else ""
	print("[Network] _on_request_completed: type=", current_type, " result=", result, " response_code=", response_code)
	if current_type == "upload_save" and _discard_inflight_upload_callback:
		print("[Network] 已放弃进行中的存档上传，忽略本次回调")
		_discard_inflight_upload_callback = false
		_is_retrying = false
		_pending_upload_data = {}
		_pending_upload_path = ""
		_pending_upload_timestamp = 0
		_is_processing_request = false
		_current_request_info = {}
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		if current_type == "mail_list":
			mail_list_via_network_response.emit(result, response_code, body)
			_complete_request()
			return
		if _maybe_retry_auth_with_http_fallback(current_type, result):
			return
		var error_msg = "网络请求失败"
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "无法连接到服务器"
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_msg = "无法解析服务器地址"
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_msg = "连接错误"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS握手失败"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "服务器无响应"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "请求超时，请检查网络后重试"

		if current_type.begins_with("economy_") or current_type == "fe_dungeon_start" or current_type == "fe_dungeon_clear" or current_type == "atlas_dungeon_start" or current_type == "atlas_dungeon_finish" or current_type == "pet_refine" or current_type == "pet_grant_starter":
			var http_fail_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			economy_result.emit(http_fail_rid, current_type, false, {}, error_msg)
			if current_type == "fe_dungeon_start":
				fe_dungeon_start_failed.emit(error_msg)
			elif current_type == "fe_dungeon_clear":
				fe_dungeon_clear_failed.emit(error_msg)
			elif current_type == "atlas_dungeon_start":
				atlas_dungeon_start_failed.emit(error_msg)
			elif current_type == "fe_dungeon_clear":
				fe_dungeon_clear_failed.emit(error_msg)
			_complete_request()
			return
		match current_type:
			"register":
				_emit_register_failed(error_msg)
			"login":
				_emit_login_failed(error_msg)
			"upload_save":
				_handle_upload_failure()
			"download_save":
				save_downloaded.emit({"_download_error": true, "error_msg": error_msg})
			"vip_info":
				vip_info_failed.emit(error_msg)
			"ranking":
				ranking_loaded.emit([])
			"ranking_players":
				ranking_players_loaded.emit([])
			"ranking_pets":
				ranking_pets_loaded.emit([], "pets_evolution")
			"ranking_pets_evolution":
				ranking_pets_loaded.emit([], "pets_evolution")
			"ranking_pets_non_evolution":
				ranking_pets_loaded.emit([], "pets_non_evolution")
			"ranking_tower":
				ranking_loaded.emit([])
			"ranking_suit_dungeon":
				ranking_suit_dungeon_loaded.emit([])
			"tower_info":
				tower_info_loaded.emit(0, 0, 0)
			"martial_info":
				martial_info_failed.emit(error_msg)
			"martial_create":
				martial_create_failed.emit("网络请求失败")
			"martial_skill_book_use":
				martial_skill_book_failed.emit("网络请求失败")
			"offline_info":
				offline_info_loaded.emit(0, true, 0)
			"offline_heartbeat":
				pass
			"lottery_draw":
				lottery_draw_failed.emit(error_msg)
			"shop_buy":
				shop_buy_failed.emit(error_msg)
			"main_shop_catalog":
				main_shop_catalog_failed.emit(error_msg)
			"xianmo_chest_deposit":
				xianmo_chest_deposit_failed.emit(error_msg)
			"drop_config":
				drop_config_loaded.emit({})
			"festival_runtime_config":
				festival_runtime_config_loaded.emit({})
			"gameplay_runtime_config":
				gameplay_runtime_config_loaded.emit({})
			"fe_dungeon_status":
				fe_dungeon_status_failed.emit(error_msg)
			"brother_tower_start":
				brother_tower_start_failed.emit(error_msg)

		_complete_request()
		return


	if current_type == "mail_list":
		print("[Network] mail_list raw: code=", response_code, " body_len=", body.size())
		mail_list_via_network_response.emit(result, response_code, body)
		_complete_request()
		return

	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		print("[Network] JSON parse error: ", err)
		if current_type == "lottery_pity_status":
			_emit_failure_signal(current_type, "保底功能暂不可用")
		elif current_type == "lottery_pity_claim":
			_emit_failure_signal(current_type, "保底领取失败，请稍后重试")
		elif current_type == "noble_info":
			var body_preview: String = (body as PackedByteArray).get_string_from_utf8()
			if body_preview.length() > 200:
				body_preview = body_preview.substr(0, 200) + "…"
			print("[Network] noble_info JSON parse failed: code=", response_code, " url=", server_url, "/noble/info body_len=", body.size(), " preview=", body_preview)
			_emit_failure_signal(current_type, "贵族数据格式异常（响应非 JSON）。请确认服务端已部署贵族接口，且与登录使用同一 API 基址")
		elif current_type == "noble_claim":
			_emit_failure_signal(current_type, "领取奖励失败")
		else:
			_emit_failure_signal(current_type, "JSON解析失败")
		_complete_request()
		return

	var data = json.data
	if data is Dictionary:
		_update_server_time_from_response_data(data)

	if data == null:
		print("[Network] JSON data is null")
		_emit_failure_signal(current_type, "服务器返回数据为空")
		_complete_request()
		return

	if not data is Dictionary:
		print("[Network] JSON data is not Dictionary: ", data)
		_emit_failure_signal(current_type, "服务器返回数据格式错误")
		_complete_request()
		return
	_apply_server_save_revision(data)

	print("[Network] Response data keys: ", data.keys() if data is Dictionary else "not dict")

	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		_complete_request()
		return

	if response_code == 200:
		if data.has("token"):
			var tok: String = String(data.get("token", "")).strip_edges()
			if tok.is_empty():
				if current_type == "register":
					_emit_register_failed("注册响应无效（令牌为空）")
				elif current_type == "login":
					_emit_login_failed("登录响应无效（令牌为空）")
				else:
					_emit_failure_signal(current_type, "授权令牌无效")
				_complete_request()
				return
			auth_token = tok
			user_id = int(data.get("userId", 0))
			nickname = String(data.get("nickname", ""))
			server_wipe_id = str(data.get("wipeId", ""))
			if current_type == "register":
				register_success.emit(user_id, nickname, auth_token)
			else:
				login_success.emit(user_id, nickname, auth_token)
			_complete_request()
			return
		elif current_type == "pet_merge" and data.has("result"):
			pet_merge_success.emit(data)
			_complete_request()
			return
		elif current_type == "pet_reincarnation" and data.has("result"):
			pet_reincarnation_success.emit(data)
			_complete_request()
			return
		elif current_type == "pet_reincarnation_inherit" and data.has("result"):
			pet_reincarnation_inherit_success.emit(data)
			_complete_request()
			return
		elif current_type == "pet_evolve" and data.has("result"):
			pet_evolve_success.emit(data)
			_complete_request()
			return
		elif current_type == "download_save":
			_set_sync_degraded(false, "")
			_sync_consecutive_failures = 0
			_sync_last_success_tick_ms = Time.get_ticks_msec()
			_finish_upload_revision_sync()
			if data.has("saveData"):
				save_downloaded.emit(data.saveData)
			else:
				save_downloaded.emit({"_download_error": true, "error_msg": "下载存档失败：服务端返回缺少 saveData"})
			_complete_request()
			return
		elif data.has("rankings") and current_type != "xianmo_ranking":
			match current_type:
				"ranking_players":
					ranking_players_loaded.emit(data.rankings)
				"ranking_pets":
					ranking_pets_loaded.emit(data.rankings, "pets_evolution")
				"ranking_pets_evolution":
					ranking_pets_loaded.emit(data.rankings, "pets_evolution")
				"ranking_pets_non_evolution":
					ranking_pets_loaded.emit(data.rankings, "pets_non_evolution")
				"ranking_tower":
					ranking_loaded.emit(data.rankings)
				"ranking_suit_dungeon":
					ranking_suit_dungeon_loaded.emit(data.rankings)
				_:
					ranking_loaded.emit(data.rankings)
			_complete_request()
			return
		elif data.has("towerHighest"):
			var tower_highest = data.get("towerHighest", 0)
			var sweep_count = data.get("sweepCount", 0)
			var tower_floor = int(data.get("towerFloor", 0))
			if sweep_count == 0 and data.get("sweepUsed", false):
				sweep_count = 1
			if data.has("openMaxFloor") and GameManager.instance and GameManager.instance.has_method("apply_effective_tower_open_max_floor"):
				var open_cap: = int(data.get("openMaxFloor", 0))
				if open_cap > 0:
					GameManager.instance.apply_effective_tower_open_max_floor(open_cap, bool(data.get("openMaxFloorBypass", false)))
			tower_info_loaded.emit(tower_highest, sweep_count, tower_floor)
			_complete_request()
			return


		elif current_type == "fe_dungeon_status" and data.has("remainingAttempts"):
			fe_dungeon_status_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "atlas_dungeon_status" and data is Dictionary:
			atlas_dungeon_status_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "atlas_dungeon_start" and data is Dictionary:
			var atlas_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			if data.get("success", false):
				atlas_dungeon_start_success.emit(data)
				economy_result.emit(atlas_rid, "atlas_dungeon_start", true, data, "")
			else:
				var atlas_err: = str(data.get("error", data.get("message", "图鉴副本挑战失败")))
				if atlas_err.is_empty():
					atlas_err = "图鉴副本挑战失败"
				atlas_dungeon_start_failed.emit(atlas_err)
				economy_result.emit(atlas_rid, "atlas_dungeon_start", false, data, atlas_err)
			_complete_request()
			return
		elif (current_type == "atlas_dungeon_finish" or current_type == "pet_refine" or current_type == "pet_grant_starter" or current_type == "economy_offline_claim") and data is Dictionary:
			# 离线结算必须在这里回 economy_result：`wait_economy("economy_offline_claim", ...)`
			# 是 await 这个信号的，漏了这条分支它就只能等满 45 秒超时 ——
			# 而登录后的启动界面正卡在「等离线结算回来再弹面板」，
			# 表现出来就是「点登录后一直纯背景，既没有离线面板也没有人物面板」。
			var auth_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			if data.get("success", false) or data.get("duplicate", false):
				economy_result.emit(auth_rid, current_type, true, data, "")
			else:
				var auth_err: = str(data.get("error", data.get("message", "请求失败")))
				if auth_err.is_empty():
					auth_err = "请求失败"
				economy_result.emit(auth_rid, current_type, false, data, auth_err)
			_complete_request()
			return
		elif current_type.begins_with("brother_tower_") and data is Dictionary:
			_dispatch_brother_tower_response(current_type, data)
			_complete_request()
			return
		elif current_type == "fe_dungeon_start" and data is Dictionary:
			var fe_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			if data.get("success", false):
				fe_dungeon_start_success.emit(data)
				economy_result.emit(fe_rid, "fe_dungeon_start", true, data, "")
			else:
				var fe_err: = str(data.get("error", data.get("message", "五行副本挑战失败")))
				if fe_err.is_empty():
					fe_err = "五行副本挑战失败"
				fe_dungeon_start_failed.emit(fe_err)
				economy_result.emit(fe_rid, "fe_dungeon_start", false, data, fe_err)
			_complete_request()
			return
		elif current_type == "xianmo_adventure" and (data.has("eventId") or data.has("eventType")):
			xianmo_adventure_success.emit(data)
			_complete_request()
			return
		elif current_type == "fe_dungeon_clear" and data is Dictionary:
			var fe_clear_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			if data.get("success", false):
				fe_dungeon_clear_success.emit(data)
				economy_result.emit(fe_clear_rid, "fe_dungeon_clear", true, data, "")
			else:
				var fe_clear_err: = str(data.get("error", data.get("message", "五行副本奖励失败")))
				if fe_clear_err.is_empty():
					fe_clear_err = "五行副本奖励失败"
				fe_dungeon_clear_failed.emit(fe_clear_err)
				economy_result.emit(fe_clear_rid, "fe_dungeon_clear", false, data, fe_clear_err)
			_complete_request()
			return
		elif data.has("sweepsLeft") and current_type != "economy_suit_sweep":
			var sweeps_left = data.get("sweepsLeft", 0)
			var max_sweeps = data.get("maxSweeps", 3)
			if current_type == "suit_dungeon_info":
				suit_dungeon_info_loaded.emit(sweeps_left, max_sweeps)
			elif current_type == "suit_dungeon_sweep":
				suit_dungeon_sweep_success.emit(sweeps_left)
			_complete_request()
			return
		elif data.has("createCount"):
			var create_count = data.get("createCount", 0)
			var is_today = data.get("isToday", false)
			var server_success_rate = float(data.get("serverSuccessRate", 0.3))
			var noble_bonus = int(data.get("nobleBonus", 0))
			if current_type == "martial_info":
				martial_info_loaded.emit(create_count, is_today, server_success_rate, noble_bonus)
			elif current_type == "martial_create":
				var remaining = data.get("remaining", 0)
				var new_gold = int(data.get("newGold", -1))
				var rolled_success = bool(data.get("rolledSuccess", false))
				last_martial_create_payload = data if data is Dictionary else {}
				martial_create_success.emit(create_count, remaining, new_gold, rolled_success, server_success_rate, noble_bonus)
			_complete_request()
			return
		elif current_type == "martial_skill_book_use" and bool(data.get("success", false)):
			martial_skill_book_success.emit(data)
			_complete_request()
			return
		elif data.has("offlineSeconds"):
			var offline_seconds = data.get("offlineSeconds", 0)
			var is_first_login = data.get("isFirstLogin", false)
			var vip_tier = int(data.get("vipTier", 0))
			offline_info_loaded.emit(offline_seconds, is_first_login, vip_tier)
			_complete_request()
			return
		elif current_type == "offline_heartbeat":
			offline_heartbeat_success.emit()
			_complete_request()
			return
		elif data.has("joined"):
			xianmo_info_loaded.emit(data)
			_complete_request()
			return
		elif data.has("xian") and data.has("mo"):
			xianmo_faction_stats_loaded.emit(data)
			_complete_request()
			return
		elif data.has("weekNumber") and data.has("rankings"):
			var faction = _current_request_info.get("faction", "")
			print("[Network] xianmo_ranking_loaded: faction=", faction, " count=", data.rankings.size(), " weekNumber=", data.weekNumber)
			print("[Network] _current_request_info=", _current_request_info)
			xianmo_ranking_loaded.emit(data.rankings, data.weekNumber, faction)
			_complete_request()
			return
		elif data.has("eventId") or data.has("eventType"):
			xianmo_adventure_success.emit(data)
			_complete_request()
			return
		elif current_type == "main_shop_catalog" and data.has("items"):
			main_shop_catalog_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "xianmo_shop_items" and data.has("items"):
			# 必须限定 current_type：原来这里只判 data.has("items")，
			# 任何带 items 字段的回包（商店购买、抽奖、野外结算、邮件领取、分解…）
			# 都会被这里截胡 → 对应的 success/failed 信号永远不发，
			# 表现就是「买到了但没到账」「抽奖卡死」「打怪不结算」。
			xianmo_shop_items_loaded.emit(data.items)
			_complete_request()
			return
		elif data.has("newTotalScore") and current_type == "xianmo_shop_buy":
			xianmo_shop_buy_success.emit(data)
			_complete_request()
			return
		elif current_type == "shop_buy" and data.has("itemName"):
			shop_buy_success.emit(data)
			_complete_request()
			return
		elif data.has("startTime") and data.has("endTime"):
			xianmo_week_info_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "xianmo_chest_open" and data.has("rewards"):
			xianmo_chest_open_success.emit(data.rewards)
			_complete_request()
			return
		elif current_type == "xianmo_chest_open_batch" and data.get("success", false) == true:
			xianmo_chest_open_batch_success.emit(data)
			_complete_request()
			return
		elif current_type == "xianmo_chest_deposit" and data.get("success", false) == true:
			xianmo_chest_deposit_success.emit(data)
			_complete_request()
			return
		elif data.has("equipment") and current_type == "xianmo_chest_open":
			xianmo_chest_open_success.emit(data)
			_complete_request()
			return
		elif data.has("goldReward") and current_type == "xianmo_treasure_exchange":
			xianmo_treasure_exchange_success.emit(data)
			_complete_request()
			return
		elif data.has("scoreGain") and current_type == "xianmo_treasure_use":
			xianmo_treasure_use_success.emit(data)
			_complete_request()
			return
		elif data.has("mirror"):
			xianmo_mirror_loaded.emit(data.mirror)
			_complete_request()
			return
		elif current_type == "xianmo_titles" and data.has("titles"):
			xianmo_titles_loaded.emit(data.titles)
			_complete_request()
			return
		elif data.has("broadcasts"):
			print("[Network] broadcasts response received, count=", data.broadcasts.size() if data.broadcasts is Array else "not array")
			xianmo_broadcasts_loaded.emit(data.broadcasts)
			_complete_request()
			return
		elif data.has("faction") and current_type == "xianmo_join":
			print("[Network] xianmo_join success, faction=", data.faction, ", nickname=", data.get("nickname", ""))
			xianmo_join_success.emit(data.faction, data.get("nickname", ""), int(data.get("newGold", -1)))
			_complete_request()
			return
		elif current_type == "treasure_status" and data is Dictionary:
			treasure_status_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "treasure_join" and data.get("success", false):
			treasure_join_success.emit(data)
			_complete_request()
			return
		elif current_type == "treasure_participants" and data.has("participants"):
			treasure_participants_loaded.emit(data.participants)
			_complete_request()
			return
		elif current_type == "treasure_battle_log" and data.has("matches"):
			treasure_battle_log_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "treasure_open" and data.get("success", false):
			treasure_open_success.emit(data)
			_complete_request()
			return
		elif current_type.begins_with("economy_") and data is Dictionary:

			var econ_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			if data.get("success", false):
				economy_result.emit(econ_rid, current_type, true, data, "")
			else:
				var econ_err: = str(data.get("error", data.get("message", "经济结算失败")))
				if econ_err.is_empty():
					econ_err = "经济结算失败"
				economy_result.emit(econ_rid, current_type, false, data, econ_err)
			_complete_request()
			return
		elif data.has("user"):
			var user_data = data.user
			var is_vip = false
			var vip_level = 0
			if user_data is Dictionary and user_data.has("vip_level") and user_data.vip_level > 0:
				is_vip = true
				vip_level = user_data.vip_level
			var daily_yb = 0
			if user_data is Dictionary and user_data.has("vip_daily_yuanbao_granted"):
				daily_yb = int(user_data.vip_daily_yuanbao_granted)
			var mutation_egg: = ""
			if user_data is Dictionary and user_data.has("vip_daily_mutation_egg"):
				mutation_egg = str(user_data.vip_daily_mutation_egg).strip_edges()
			var vip_expire_str: = ""
			if user_data is Dictionary and user_data.has("vip_expire_time"):
				var ve = user_data.vip_expire_time
				if ve != null:
					vip_expire_str = str(ve).strip_edges()
			if current_type == "vip_info":
				print("[Network] VIP信息响应: is_vip=%s, vip_level=%d, daily_yuanbao=%d, mutation_egg=%s, vip_expire=%s" % [is_vip, vip_level, daily_yb, mutation_egg, vip_expire_str])
				print("[Network] 用户数据: ", user_data)
				_apply_newbie_exp_until_from_dict(data)
				vip_info_loaded.emit(is_vip, vip_level, daily_yb, vip_expire_str)
				if not mutation_egg.is_empty():
					vip_daily_mutation_egg_mailed.emit(mutation_egg)
			_complete_request()
			return
		elif current_type == "lottery_draw":
			_emit_lottery_draw_result(data)
			_complete_request()
			return
		elif current_type == "lottery_pity_status":
			lottery_pity_status_loaded.emit(data)
			_complete_request()
			return
		elif current_type == "lottery_pity_claim":
			lottery_pity_claim_success.emit(data)
			_complete_request()
			return
		elif current_type == "noble_info":
			noble_info_loaded.emit(data.get("data", {}))
			_complete_request()
			return
		elif current_type == "noble_claim":
			noble_claim_success.emit(data)
			_complete_request()
			return
		elif current_type == "drop_config":
			var rates: Dictionary = data.get("dropRates", {}) if data is Dictionary else {}
			drop_config_loaded.emit(rates if rates is Dictionary else {})
			_complete_request()
			return
		elif current_type == "festival_runtime_config":
			var fest_events: Variant = data.get("events", {}) if data is Dictionary else {}
			festival_runtime_config_loaded.emit({"events": fest_events if fest_events is Dictionary else {}})
			_complete_request()
			return
		elif current_type == "gameplay_runtime_config":
			gameplay_runtime_config_loaded.emit(data if data is Dictionary else {})
			_complete_request()
			return
		elif data.has("success") and data.success:
			print("[Network] 收到 success 响应，current_type=", current_type)
			match current_type:
				"login":
					_emit_login_failed("登录响应异常（缺少有效令牌），请稍后重试")
				"register":
					_emit_register_failed("注册响应异常（缺少有效令牌），请稍后重试")
				"xianmo_chest_deposit":
					xianmo_chest_deposit_success.emit(data)
				"upload_save":
					if _is_save_upload_persisted_success(data):
						print("[Network] 存档上传成功")
						print("[CloudSync] upload_save 主队列 HTTP 成功，将触发 save_uploaded → commit_secure_op")
						_handle_upload_success()
						save_uploaded.emit(true)
					else:
						if bool(data.get("throttled", false)) or bool(data.get("deduped", false)) or bool(data.get("duplicate", false)):
							push_warning("[Network] upload_save 未落库(节流/去重)，将延迟重试")
							_is_retrying = true
							_complete_request()
							return
						push_warning("[Network] upload_save 未落库，视为失败")
						_is_retrying = false
						_upload_retry_count = MAX_RETRY_COUNT
						if not _pending_upload_path.is_empty():
							_remove_local_cache(_pending_upload_path)
						_pending_upload_data = {}
						_pending_upload_path = ""
						_pending_upload_timestamp = 0
						save_uploaded.emit(false)
				"xianmo_shop_buy":
					xianmo_shop_buy_success.emit(data)
				"shop_buy":
					shop_buy_success.emit(data)
				"xianmo_treasure_exchange":
					xianmo_treasure_exchange_success.emit(data)
				"pet_merge":
					pet_merge_success.emit(data)
				"pet_reincarnation":
					pet_reincarnation_success.emit(data)
				"pet_reincarnation_inherit":
					pet_reincarnation_inherit_success.emit(data)
				"pet_evolve":
					pet_evolve_success.emit(data)
				"tower_sweep":
					tower_sweep_success.emit()
				"xianmo_title_activate":
					xianmo_title_activated.emit(data)
				"xianmo_title_deactivate":
					xianmo_title_deactivated.emit(data)
				"xianmo_broadcast":
					xianmo_broadcast_sent.emit(true)
				"xianmo_battle_result":
					xianmo_battle_result_success.emit(data)
				"xianmo_pet_exchange":
					xianmo_pet_exchange_success.emit(data)
				"lottery_draw":
					_emit_lottery_draw_result(data)
				"lottery_pity_status":
					lottery_pity_status_loaded.emit(data)
				"lottery_pity_claim":
					lottery_pity_claim_success.emit(data)
				"fe_dungeon_start":
					var fe_fb_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
					fe_dungeon_start_success.emit(data)
					economy_result.emit(fe_fb_rid, "fe_dungeon_start", true, data, "")
				"fe_dungeon_clear":
					var fe_clear_fb_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
					fe_dungeon_clear_success.emit(data)
					economy_result.emit(fe_clear_fb_rid, "fe_dungeon_clear", true, data, "")
				"noble_info":
					noble_info_loaded.emit(data.get("data", {}))
				"noble_claim":
					noble_claim_success.emit(data)
			_complete_request()
			return
		else:
			print("[Network] 未匹配的响应格式，current_type=", current_type, " data keys=", data.keys() if data is Dictionary else "not dict")
			if current_type == "upload_save" and data is Dictionary and data.has("success") and data.get("success") == false:
				push_warning("[Network] 存档上传 success=false，不作为成功处理（避免领奖前 commit 误判已同步）")
				_handle_upload_failure()
				_complete_request()
				return
			match current_type:
				"ranking":
					ranking_loaded.emit([])
				"upload_save":
					if _is_save_upload_persisted_success(data):
						print("[Network] 存档上传成功 - fallback")
						print("[CloudSync] upload_save 主队列 HTTP 成功(fallback)，将触发 save_uploaded")
						_handle_upload_success()
						save_uploaded.emit(true)
					else:
						if bool(data.get("throttled", false)) or bool(data.get("deduped", false)) or bool(data.get("duplicate", false)):
							push_warning("[Network] upload_save fallback 未落库(节流/去重)，将延迟重试")
							_is_retrying = true
						else:
							push_warning("[Network] upload_save fallback 未落库，视为失败")
							_is_retrying = false
							_upload_retry_count = MAX_RETRY_COUNT
							if not _pending_upload_path.is_empty():
								_remove_local_cache(_pending_upload_path)
							_pending_upload_data = {}
							_pending_upload_path = ""
							_pending_upload_timestamp = 0
							save_uploaded.emit(false)
				"xianmo_adventure":
					print("[Network] xianmo_adventure fallback, data=", data)
					xianmo_adventure_success.emit(data)
				"login":
					_emit_login_failed("登录响应格式错误")
				"download_save":
					save_downloaded.emit({"_download_error": true, "error_msg": "存档数据格式错误"})
				_:
					print("[Network] 未处理的 current_type: ", current_type)
			_complete_request()
			return
	elif response_code != 200:
		var error_msg = data.get("error", "服务器错误 (HTTP %d)" % response_code)
		if current_type.begins_with("economy_") or current_type == "fe_dungeon_start" or current_type == "fe_dungeon_clear" or current_type == "atlas_dungeon_start" or current_type == "atlas_dungeon_finish" or current_type == "pet_refine" or current_type == "pet_grant_starter":
			var http_err_rid: = str(_current_request_info.get("request_id", "")) if _current_request_info is Dictionary else ""
			var err_payload: Dictionary = data if data is Dictionary else {}
			economy_result.emit(http_err_rid, current_type, false, err_payload, str(error_msg))
			if current_type == "fe_dungeon_start":
				fe_dungeon_start_failed.emit(str(error_msg))
			elif current_type == "fe_dungeon_clear":
				fe_dungeon_clear_failed.emit(str(error_msg))
			elif current_type == "atlas_dungeon_start":
				atlas_dungeon_start_failed.emit(str(error_msg))
			_complete_request()
			return
		if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
			_emit_force_update(data)
			_complete_request()
			return
		print("[Network] Error response, current_type=", current_type, " response_code=", response_code, " error=", error_msg)
		var upload_ban_codes: = ["SAVE_REJECTED_ANTICHEAT", "SAVE_REJECTED_LEVEL_TAMPER", "SAVE_REJECTED_ATTR_TAMPER"]
		if current_type == "upload_save" and str(data.get("code", "")) in upload_ban_codes:
			_is_retrying = false
			_upload_retry_count = MAX_RETRY_COUNT
			_pending_upload_data = {}
			_pending_upload_path = ""
			_pending_upload_timestamp = 0
			logout()
			kicked_out.emit(_format_account_suspended_message(data), true)
			save_uploaded.emit(false)
			_complete_request()
			return
		if current_type == "upload_save" and str(data.get("code", "")) in [
			"SAVE_REJECTED_DOWNGRADE", 
			"SAVE_REJECTED_EQUIPMENT_CORRUPT", 
			"SAVE_REJECTED_STALE_REVISION", 
			"SAVE_REJECTED_REVISION_CONFLICT", 
			"SAVE_REVISION_REQUIRED"
		]:
			_is_retrying = false
			_upload_retry_count = MAX_RETRY_COUNT
			if not _pending_upload_path.is_empty():
				_remove_local_cache(_pending_upload_path)
			_pending_upload_data = {}
			_pending_upload_path = ""
			_pending_upload_timestamp = 0
			if str(data.get("code", "")) in ["SAVE_REJECTED_STALE_REVISION", "SAVE_REJECTED_REVISION_CONFLICT", "SAVE_REVISION_REQUIRED"]:
				_begin_upload_revision_sync_from_reject(data)
			save_uploaded.emit(false)
			_complete_request()
			return
		if current_type == "upload_save" and str(data.get("code", "")) == "SAVE_REJECTED_AUTHORITY_FIELDS_CONFLICT":
			_is_retrying = false
			_upload_retry_count = MAX_RETRY_COUNT
			if not _pending_upload_path.is_empty():
				_remove_local_cache(_pending_upload_path)
			discard_pending_saves_after_cloud_applied()
			_pending_upload_data = {}
			_pending_upload_path = ""
			_pending_upload_timestamp = 0
			save_upload_authority_conflict.emit(str(data.get("error", error_msg)), str(data.get("code", "SAVE_REJECTED_AUTHORITY_FIELDS_CONFLICT")))
			if is_logged_in():
				call_deferred("download_save")
			save_uploaded.emit(false)
			_complete_request()
			return
		var err_text: String = str(error_msg)
		if data is Dictionary and str(data.get("detail", "")).strip_edges() != "":
			if current_type == "noble_info" or current_type == "noble_claim":
				err_text = "%s — %s" % [err_text, str(data.get("detail"))]
		var auth_invalid: bool = response_code == 401 and (
			err_text == "Account logged out elsewhere" or 
			err_text == "User not found" or 
			err_text == "Login expired"
		)
		if auth_invalid:
			_is_retrying = false
			_upload_retry_count = MAX_RETRY_COUNT
			_pending_upload_data = {}
			_pending_upload_path = ""
			_pending_upload_timestamp = 0
			kicked_out.emit("登录已失效，请重新登录。", true)
			logout()
		else:
			match current_type:
				"register":
					if response_code == 403 and (str(data.get("code", "")) == "ACCOUNT_SUSPENDED" or bool(data.get("accountSuspended", false))):
						_emit_register_failed(_format_account_suspended_message(data))
					else:
						_emit_register_failed(error_msg)
				"login":
					if response_code == 403 and (str(data.get("code", "")) == "ACCOUNT_SUSPENDED" or bool(data.get("accountSuspended", false))):
						_emit_login_failed(_format_account_suspended_message(data))
					else:
						_emit_login_failed(error_msg)
				"download_save":
					save_downloaded.emit({"_download_error": true, "error_msg": error_msg})
				"upload_save":
					_handle_upload_failure()
				"tower_sweep":
					tower_sweep_failed.emit(error_msg)
				"martial_create":
					martial_create_failed.emit(error_msg)
				"martial_skill_book_use":
					martial_skill_book_failed.emit(error_msg)
				"pet_merge":
					pet_merge_failed.emit(error_msg)
				"pet_reincarnation":
					pet_reincarnation_failed.emit(error_msg)
				"pet_reincarnation_inherit":
					pet_reincarnation_inherit_failed.emit(error_msg)
				"pet_evolve":
					pet_evolve_failed.emit(error_msg)
				"vip_info":
					vip_info_failed.emit(error_msg)
				"tower_info":
					tower_info_loaded.emit(0, 0, 0)
				"martial_info":
					martial_info_failed.emit(error_msg)
				"offline_info":
					offline_info_loaded.emit(0, true, 0)
				"ranking_pets_evolution":
					ranking_pets_loaded.emit([], "pets_evolution")
				"ranking_pets_non_evolution":
					ranking_pets_loaded.emit([], "pets_non_evolution")
				"ranking_pets":
					ranking_pets_loaded.emit([], "pets_evolution")
				"ranking", "ranking_players", "ranking_tower":
					ranking_loaded.emit([])
				"suit_dungeon_sweep":
					suit_dungeon_sweep_failed.emit(error_msg)
				"suit_dungeon_info":
					suit_dungeon_info_loaded.emit(0, 3)
				"fe_dungeon_status":
					fe_dungeon_status_failed.emit(error_msg)
				"fe_dungeon_start":
					fe_dungeon_start_failed.emit(error_msg)
				"fe_dungeon_clear":
					fe_dungeon_clear_failed.emit(error_msg)
				"atlas_dungeon_status":
					atlas_dungeon_status_failed.emit(error_msg)
				"atlas_dungeon_start":
					atlas_dungeon_start_failed.emit(error_msg)
				"xianmo_join":
					xianmo_join_failed.emit(error_msg)
				"xianmo_info":
					xianmo_info_loaded.emit({"joined": false})
				"xianmo_faction_stats":
					xianmo_faction_stats_loaded.emit({})
				"xianmo_ranking":
					xianmo_ranking_loaded.emit([], 0, "")
				"xianmo_adventure":
					xianmo_adventure_failed.emit(error_msg)
				"xianmo_shop_items":
					xianmo_shop_items_loaded.emit([])
				"xianmo_shop_buy":
					xianmo_shop_buy_failed.emit(error_msg)
				"shop_buy":
					shop_buy_failed.emit(error_msg)
				"xianmo_week_info":
					xianmo_week_info_loaded.emit({})
				"xianmo_chest_open":
					xianmo_chest_open_failed.emit(error_msg)
				"xianmo_chest_open_batch":
					xianmo_chest_open_batch_failed.emit(error_msg)
				"xianmo_chest_deposit":
					xianmo_chest_deposit_failed.emit(error_msg)
				"xianmo_treasure_exchange":
					xianmo_treasure_exchange_failed.emit(error_msg)
				"xianmo_treasure_use":
					xianmo_treasure_use_failed.emit(error_msg)
				"xianmo_mirror":
					xianmo_mirror_loaded.emit({})
				"xianmo_titles":
					xianmo_titles_loaded.emit([])
				"xianmo_title_activate":
					xianmo_title_activated.emit({"success": false})
				"xianmo_title_deactivate":
					xianmo_title_deactivated.emit({"success": false})
				"xianmo_broadcasts":
					xianmo_broadcasts_loaded.emit([])
				"xianmo_broadcast":
					xianmo_broadcast_sent.emit(false)
				"treasure_status":
					treasure_status_loaded.emit({})
				"treasure_join":
					treasure_join_failed.emit(error_msg)
				"treasure_participants":
					treasure_participants_loaded.emit([])
				"treasure_battle_log":
					treasure_battle_log_loaded.emit({})
				"treasure_open":
					treasure_open_failed.emit(error_msg)
				"lottery_draw":
					lottery_draw_failed.emit(error_msg)
				"lottery_pity_status":
					lottery_pity_status_failed.emit(error_msg)
				"lottery_pity_claim":
					lottery_pity_claim_failed.emit(error_msg)
				"noble_info":
					noble_info_failed.emit(error_msg)
				"noble_claim":
					noble_claim_failed.emit(error_msg)
				"brother_tower_start":
					brother_tower_start_failed.emit(err_text)
				"brother_tower_create":
					brother_tower_create_failed.emit(err_text)
				"brother_tower_join":
					brother_tower_join_failed.emit(err_text)
				"brother_tower_application_decide":
					brother_tower_application_decide_failed.emit(err_text)
				"brother_tower_ready":
					brother_tower_ready_failed.emit(err_text)
				"brother_tower_pin_snapshot":
					brother_tower_pin_snapshot_failed.emit(err_text)
				"brother_tower_list":
					brother_tower_list_failed.emit(err_text)
				"brother_tower_wave_cleared":
					if data is Dictionary and data.has("currentWave") and GameManager.instance:
						GameManager.instance.call_deferred("_begin_brother_tower_wave_cleared", {
							"success": true, 
							"status": "sync_wave", 
							"currentWave": int(data.get("currentWave", 0)), 
						})
					else:
						brother_tower_wave_cleared_failed.emit(err_text)
				"brother_tower_complete":
					brother_tower_complete_failed.emit(err_text)
				"brother_tower_battle_events_push":
					_dispatch_bt_push_result({"success": false, "error": err_text})
				"brother_tower_battle_events_fetch":
					_dispatch_bt_fetch_result({"success": false, "error": err_text, "events": []})
				"shengsi_tower_overview":
					shengsi_tower_overview_failed.emit(err_text)
				"shengsi_tower_floor":
					shengsi_tower_floor_failed.emit(err_text)
				"shengsi_tower_feed":
					shengsi_tower_feed_failed.emit(err_text)
				"shengsi_tower_room_list":
					shengsi_tower_room_list_failed.emit(err_text)
				"shengsi_tower_matchup":
					shengsi_tower_matchup_failed.emit(err_text)
				"shengsi_tower_my_battles":
					shengsi_tower_my_battles_failed.emit(err_text)
				"shengsi_tower_floor_battles":
					shengsi_tower_floor_battles_failed.emit(err_text)
				"shengsi_tower_match":
					shengsi_tower_match_failed.emit(err_text)
				"shengsi_tower_room_create", "shengsi_tower_room_join", "shengsi_tower_room_leave", "shengsi_tower_room_disband", "shengsi_tower_register", "shengsi_tower_unregister", "shengsi_tower_stance", "shengsi_tower_ready":
					shengsi_tower_action_failed.emit(str(current_type).replace("shengsi_tower_", ""), err_text)
		_complete_request()

func is_logged_in() -> bool:
	return auth_token != ""

func signin7_info() -> Dictionary:
	return await _signin7_http_post("/signin7/info", {})

func signin7_claim() -> Dictionary:
	return await _signin7_http_post("/signin7/claim", {})

func _signin7_http_post(path: String, body: Dictionary) -> Dictionary:
	if auth_token == "":
		return {"ok": false, "success": false, "error": "未登录", "message": "未登录"}
	var http: = HTTPRequest.new()
	add_child(http)
	http.timeout = 30.0
	var err: = http.request(server_url + path, _build_headers(true, true), HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"ok": false, "success": false, "error": "网络请求失败", "message": "网络请求失败"}
	var completed: Array = await http.request_completed
	http.queue_free()
	var result: int = int(completed[0])
	var response_code: int = int(completed[1])
	var response_body: PackedByteArray = completed[3]
	var data: Dictionary = {}
	if response_body.size() > 0:
		var parsed = JSON.parse_string(response_body.get_string_from_utf8())
		if parsed is Dictionary:
			data = parsed
	var msg: = str(data.get("message", data.get("error", "")))
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if msg.is_empty():
			msg = "请求失败(%d)" % response_code
		data["ok"] = false
		data["success"] = false
		data["error"] = str(data.get("error", msg))
		data["message"] = msg
		return data
	if not data.has("ok"):
		data["ok"] = bool(data.get("success", true))
	if not data.has("success"):
		data["success"] = bool(data.get("ok", true))
	if msg.is_empty() and data.get("data") is Dictionary:
		msg = str((data.get("data") as Dictionary).get("message", ""))
		if not msg.is_empty():
			data["message"] = msg
	return data



func abort_stuck_primary_request_for_login_ui(kind: String) -> void :
	var k: = kind.strip_edges()
	if k != "login" and k != "register" and k != "download_save":
		return
	if not _is_processing_request:
		return
	if str(_current_request_info.get("type", "")) != k:
		return
	http_request.cancel_request()
	var tr: = get_tree().create_timer(0.5, true)
	tr.timeout.connect(
		func():
			if not _is_processing_request:
				return
			if str(_current_request_info.get("type", "")) != k:
				return
			if k == "login":
				_emit_login_failed("登录超时，请检查网络后重试")
			elif k == "download_save":
				save_downloaded.emit({"_download_error": true, "error_msg": "下载存档超时，请检查网络后重试"})
			else:
				_emit_register_failed("注册超时，请检查网络后重试")
			_complete_request()
	, 
		CONNECT_ONE_SHOT
	)

func abandon_inflight_save_upload() -> void :
	_is_retrying = false
	_retry_timer = 0.0
	_upload_retry_count = 0

	_pending_upload_data = {}
	_pending_upload_path = ""
	_pending_upload_timestamp = 0
	var kept: Array = []
	for entry in _request_queue:
		if typeof(entry) != TYPE_DICTIONARY or str(entry.get("type", "")) != "upload_save":
			kept.append(entry)
	_request_queue = kept

	if _discard_inflight_upload_callback:
		return
	var current_type: = ""
	if _current_request_info is Dictionary:
		current_type = str(_current_request_info.get("type", ""))
	if not _is_processing_request or current_type != "upload_save":
		return
	_discard_inflight_upload_callback = true
	if http_request != null and is_instance_valid(http_request) and http_request.is_inside_tree():
		if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
			http_request.cancel_request()
			return
	_discard_inflight_upload_callback = false
	_is_processing_request = false
	_current_request_info = {}

func resume_request_queue_if_idle() -> void :
	if _is_processing_request:
		return
	_process_next_request()

func logout():
	abandon_inflight_save_upload()
	auth_token = ""
	user_id = 0
	nickname = ""
	_heartbeat_timer = 0.0
	_sync_last_success_tick_ms = 0
	_sync_consecutive_failures = 0
	_set_sync_degraded(false, "")
	_has_server_time_sync = false
	_server_time_base_unix = 0.0
	_server_time_synced_at_ticks_msec = 0

func get_auth_token() -> String:
	return auth_token

func get_server_wipe_id() -> String:
	return server_wipe_id

func set_auth_token(token: String, uid: int, name: String):
	auth_token = token
	user_id = uid
	nickname = name
	_sync_last_success_tick_ms = Time.get_ticks_msec()
	_sync_consecutive_failures = 0
	_set_sync_degraded(false, "")

func check_version(client_version: String):
	var url = server_url + "/version/check?version=" + client_version.uri_encode()
	var err = version_check_request.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		version_checked.emit(false, false, {})

func _on_version_check_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		version_checked.emit(false, false, {})
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		version_checked.emit(false, false, {})
		return

	var data = json.data
	if not data is Dictionary:
		version_checked.emit(false, false, {})
		return

	var need_update = data.get("needUpdate", false)
	var force_update = data.get("forceUpdate", false)
	var update_info = {
		"latestVersion": data.get("latestVersion", ""), 
		"currentVersion": data.get("currentVersion", ""), 
		"updateUrl": data.get("updateUrl", ""), 
		"message": data.get("message", ""), 
		"releaseNotes": data.get("releaseNotes", "")
	}

	version_checked.emit(need_update, force_update, update_info)



func _ensure_pending_dir():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("pending_saves"):
		dir.make_dir("pending_saves")

func _save_to_local_cache(save_data: Dictionary) -> Dictionary:
	_ensure_pending_dir()
	var timestamp = Time.get_unix_time_from_system()
	var file_path = PENDING_SAVE_DIR + "save_%d.json" % timestamp
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[Network] 无法创建本地缓存文件")
		return {"ok": false, "path": "", "timestamp": timestamp}
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("[Network] 存档已保存到本地缓存: ", file_path)
	return {"ok": true, "path": file_path, "timestamp": timestamp}

func _load_pending_uploads() -> Array:
	var pending = []
	var dir = DirAccess.open(PENDING_SAVE_DIR)
	if dir == null:
		return pending
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = PENDING_SAVE_DIR + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				file.close()
				var json = JSON.new()
				if json.parse(content) == OK:
					var save_data = json.data if json.data is Dictionary else {}
					var pd = save_data.get("playerData", {}) if save_data is Dictionary else {}
					var player_ts = int(pd.get("timestamp", 0)) if pd is Dictionary else 0
					var file_ts = int(file_name.trim_prefix("save_").trim_suffix(".json").to_int())
					var sort_ts = player_ts if player_ts > 0 else file_ts
					pending.append({
						"path": file_path, 
						"name": file_name, 
						"data": save_data, 
						"player_ts": player_ts, 
						"file_ts": file_ts, 
						"sort_ts": sort_ts
					})
		file_name = dir.get_next()
	return pending

func _pick_latest_pending(pending: Array) -> Dictionary:
	var latest: Dictionary = {}
	for entry in pending:
		if latest.is_empty():
			latest = entry
			continue
		var entry_ts = int(entry.get("sort_ts", 0))
		var latest_ts = int(latest.get("sort_ts", 0))
		if entry_ts > latest_ts:
			latest = entry
	return latest

func _cleanup_confirmed_pending(success_ts: int, success_path: String) -> void :
	var pending = _load_pending_uploads()
	for entry in pending:
		var path = String(entry.get("path", ""))
		var ts = int(entry.get("sort_ts", 0))
		if path == success_path:
			_remove_local_cache(path)
		elif success_ts > 0 and ts > 0 and ts <= success_ts:
			_remove_local_cache(path)

func _remove_local_cache(file_path: String):
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(file_path)
		print("[Network] 已删除本地缓存: ", file_path)



func check_pending_uploads(auto_upload: bool = true):
	var pending = _load_pending_uploads()
	if pending.size() > 0:
		print("[Network] 发现 %d 个未同步存档" % pending.size())
		pending_uploads_found.emit(pending.size())
		if not auto_upload:
			return
		var latest = _pick_latest_pending(pending)
		if latest.is_empty():
			return
		_pending_upload_data = latest.data
		_pending_upload_path = String(latest.get("path", ""))
		_pending_upload_timestamp = int(latest.get("sort_ts", 0))

		if auth_token != "":
			_upload_retry_count = 0
			_is_retrying = true
			_retry_timer = 0.0
			_do_upload_save()


func discard_pending_saves_after_cloud_applied() -> void :
	var dir = DirAccess.open(PENDING_SAVE_DIR)
	var removed: = 0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var fp: String = PENDING_SAVE_DIR + str(file_name)
				if DirAccess.remove_absolute(fp) == OK:
					removed += 1
			file_name = dir.get_next()
	_pending_upload_data = {}
	_pending_upload_path = ""
	_pending_upload_timestamp = 0
	_is_retrying = false
	if removed > 0:
		print("[Network] 云存档已合并，已删除 %d 个 pending 快照，避免旧档回写服务端" % removed)


const _MERGE_EQ_SLOTS: Array = ["weapon", "armor", "helmet", "boots", "accessory"]


func _merge_player_ts(pd: Variant) -> float:
	if pd == null or not pd is Dictionary:
		return 0.0
	return float(pd.get("timestamp", 0))


func _merge_eq_named_slot_count(eq: Variant) -> int:
	if eq == null or not eq is Dictionary:
		return 0
	var equipped: Variant = eq.get("equipped", {})
	if equipped == null or not equipped is Dictionary:
		return 0
	var n: = 0
	for slot in _MERGE_EQ_SLOTS:
		var it: Variant = equipped.get(slot)
		if it is Dictionary:
			var nm: = str(it.get("name", "")).strip_edges()
			if not nm.is_empty():
				n += 1
	return n


func _merge_eq_ghost_corrupt(eq: Variant) -> bool:
	if eq == null or not eq is Dictionary:
		return false
	var equipped: Variant = eq.get("equipped", {})
	if equipped == null or not equipped is Dictionary:
		return false
	for slot in _MERGE_EQ_SLOTS:
		var it: Variant = equipped.get(slot)
		if it is Dictionary:
			var id_s: = str(it.get("id", "")).strip_edges()
			var nm: = str(it.get("name", "")).strip_edges()
			if not id_s.is_empty() and nm.is_empty():
				return true
	return false


func _merge_eq_total_count(raw: Variant) -> int:
	if raw == null or not raw is Dictionary:
		return 0
	var total: = _merge_eq_named_slot_count(raw)
	var inv: Variant = raw.get("inventory", [])
	if inv is Array:
		for it in inv:
			if it is Dictionary and not bool(it.get("is_pet_equipment", false)):
				var nm: = str(it.get("name", "")).strip_edges()
				if not nm.is_empty():
					total += 1
	return total


func _merge_use_pending_equipment(p_eq: Variant, c_eq: Variant) -> bool:
	if p_eq == null or not p_eq is Dictionary:
		return false
	if c_eq == null or not c_eq is Dictionary:
		return true
	var pt: = _merge_eq_total_count(p_eq)
	var ct: = _merge_eq_total_count(c_eq)
	if pt > ct:
		return true
	if ct > pt:
		return false
	var pn: = _merge_eq_named_slot_count(p_eq)
	var cn: = _merge_eq_named_slot_count(c_eq)
	if pn > cn:
		return true
	if cn > pn:
		return false
	var pg: = _merge_eq_ghost_corrupt(p_eq)
	var cg: = _merge_eq_ghost_corrupt(c_eq)
	if pg and not cg:
		return false
	if cg and not pg:
		return true
	return false



func _merge_preserve_suit_enhance_item_dict(pending_item: Dictionary, cloud_item: Dictionary) -> Dictionary:
	var p_id: = str(pending_item.get("id", "")).strip_edges()
	var c_id: = str(cloud_item.get("id", "")).strip_edges()
	if p_id.is_empty() or c_id.is_empty() or p_id != c_id:
		return pending_item
	var cloud_lv: = clampi(int(cloud_item.get("suit_enhance_level", 0)), 0, 9)
	var pending_lv: = clampi(int(pending_item.get("suit_enhance_level", 0)), 0, 9)
	if cloud_lv > pending_lv:
		return cloud_item.duplicate(true)
	if cloud_lv == pending_lv and cloud_lv > 0:
		var out: = pending_item.duplicate(true)
		for stat_key in ["attack", "defense", "agility", "hp", "mp"]:
			var p_val: = int(pending_item.get(stat_key, 0))
			var c_val: = int(cloud_item.get(stat_key, 0))
			out[stat_key] = maxi(p_val, c_val)
		var p_rolls: Variant = out.get("suit_enhance_rolls", [])
		var c_rolls: Variant = cloud_item.get("suit_enhance_rolls", [])
		if c_rolls is Array and not c_rolls.is_empty():
			if not p_rolls is Array or (p_rolls as Array).size() < (c_rolls as Array).size():
				out["suit_enhance_rolls"] = c_rolls.duplicate(true)
		elif ( not p_rolls is Array or p_rolls.is_empty()) and c_rolls is Array and not c_rolls.is_empty():
			out["suit_enhance_rolls"] = c_rolls.duplicate(true)
		return out
	return pending_item


func _merge_preserve_suit_enhance_from_cloud(merged_eq: Dictionary, cloud_eq: Variant) -> void :
	if cloud_eq == null or not cloud_eq is Dictionary:
		return
	var cloud: Dictionary = cloud_eq
	var cloud_equipped: Variant = cloud.get("equipped", {})
	var merged_equipped: Variant = merged_eq.get("equipped", {})
	if cloud_equipped is Dictionary and merged_equipped is Dictionary:
		var me: Dictionary = merged_equipped
		var ce: Dictionary = cloud_equipped
		for slot in _MERGE_EQ_SLOTS:
			var p_it: Variant = me.get(slot)
			var c_it: Variant = ce.get(slot)
			if p_it is Dictionary and c_it is Dictionary:
				me[slot] = _merge_preserve_suit_enhance_item_dict(p_it as Dictionary, c_it as Dictionary)
	var cloud_inv: Variant = cloud.get("inventory", [])
	var merged_inv: Variant = merged_eq.get("inventory", [])
	if not cloud_inv is Array or not merged_inv is Array:
		return
	var cloud_by_id: = {}
	for raw_c in cloud_inv:
		if raw_c is Dictionary:
			var cid: = str((raw_c as Dictionary).get("id", "")).strip_edges()
			if not cid.is_empty():
				cloud_by_id[cid] = raw_c
	var out_inv: Array = []
	for raw_p in merged_inv:
		if raw_p is Dictionary:
			var pd: Dictionary = raw_p
			var pid: = str(pd.get("id", "")).strip_edges()
			if not pid.is_empty() and cloud_by_id.has(pid):
				out_inv.append(_merge_preserve_suit_enhance_item_dict(pd, cloud_by_id[pid] as Dictionary))
			else:
				out_inv.append(pd.duplicate(true))
		else:
			out_inv.append(raw_p)
	merged_eq["inventory"] = out_inv


func _merge_pets_nonempty_count(raw: Variant) -> int:
	if raw == null:
		return 0
	if raw is Dictionary:
		var pets: Variant = raw.get("pets", [])
		var bag: Variant = raw.get("pet_bag", [])
		var assist: Variant = raw.get("assist_pets", [])
		var n: = 0
		if pets is Array:
			n += pets.size()
		if bag is Array:
			n += bag.size()
		if assist is Array:
			for ap in assist:
				if ap is Dictionary and (ap as Dictionary).has("id"):
					n += 1
		return n
	if raw is Array:
		return raw.size()
	return 0


func _merge_pet_bag_count(raw: Variant) -> int:
	if raw == null or not raw is Dictionary:
		return 0
	var bag: Variant = raw.get("pet_bag", [])
	if bag is Array:
		return bag.size()
	return 0


func _merge_use_pending_pets(p_raw: Variant, c_raw: Variant) -> bool:
	var p_n: = _merge_pets_nonempty_count(p_raw)
	var c_n: = _merge_pets_nonempty_count(c_raw)
	if p_n > c_n:
		return true
	if p_n == c_n:
		var p_bag: = _merge_pet_bag_count(p_raw)
		var c_bag: = _merge_pet_bag_count(c_raw)
		if p_bag != c_bag:
			return true
	return p_n >= c_n


func _pet_instance_ids_from_pets_data_blob(pd: Variant) -> Dictionary:
	var ids: = {}
	if pd == null or not pd is Dictionary:
		return ids
	var d: Dictionary = pd
	for key in ["pets", "pet_bag", "assist_pets"]:
		var arr: Variant = d.get(key, [])
		if arr is Array:
			for entry in arr:
				if entry is Dictionary:
					var sid: = str((entry as Dictionary).get("id", "")).strip_edges()
					if not sid.is_empty():
						ids[sid] = true
	return ids



func _merge_active_pet_id_pending_over_cloud(pending_dict: Dictionary, cloud_raw: Variant) -> void :
	var roster: = _pet_instance_ids_from_pets_data_blob(pending_dict)
	if roster.is_empty():
		return
	var p_aid: = str(pending_dict.get("active_pet_id", "")).strip_edges()
	if not p_aid.is_empty() and roster.has(p_aid):
		return
	var c_aid: = ""
	if cloud_raw is Dictionary:
		var cd: Dictionary = cloud_raw
		c_aid = str(cd.get("active_pet_id", "")).strip_edges()
		if c_aid.is_empty():
			c_aid = str(cd.get("activePetId", "")).strip_edges()
	if not c_aid.is_empty() and roster.has(c_aid):
		pending_dict["active_pet_id"] = c_aid


func _merge_inv_item_sum(raw: Variant) -> int:
	if raw == null or not raw is Dictionary:
		return 0
	var n: = 0
	for key in ["items", "warehouse_items", "pet_equipment_items", "pet_equipment_warehouse"]:
		var arr: Variant = raw.get(key, [])
		if arr is Array:
			for it in arr:
				if it is Dictionary:
					n += maxi(1, int(it.get("count", 1)))
	return n


func _merge_use_pending_inventory(p_inv: Variant, c_inv: Variant) -> bool:
	return _merge_inv_item_sum(p_inv) >= _merge_inv_item_sum(c_inv)


func _merge_ma_list_size(raw: Variant) -> int:
	if raw == null or not raw is Dictionary:
		return 0
	var ma: Variant = raw.get("martial_arts", [])
	if ma is Array:
		return ma.size()
	return 0



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




func merge_pending_into_downloaded_save(save_data: Dictionary) -> void :
	var pending_list: = _load_pending_uploads()
	if pending_list.is_empty():
		return
	var latest: = _pick_latest_pending(pending_list)
	if latest.is_empty():
		return
	var p: Variant = latest.get("data", {})
	if p == null or not p is Dictionary:
		return
	var pd_p: Variant = p.get("playerData", {})
	var pd_c: Variant = save_data.get("playerData", {})
	pd_p = pd_p if pd_p is Dictionary else {}
	pd_c = pd_c if pd_c is Dictionary else {}
	var ts_p: = _merge_player_ts(pd_p)
	var ts_c: = _merge_player_ts(pd_c)
	if ts_p <= ts_c:
		print("[Network] pending_ts=%s <= cloud_ts=%s，跳过 pending 字段合并" % [str(ts_p), str(ts_c)])
		return
	var rev_p: = _extract_save_revision(p)
	var rev_c: = _extract_save_revision(save_data)
	if rev_p >= 0 and rev_c >= 0 and rev_p <= rev_c:
		print("[Network] pending_revision=%s <= cloud_revision=%s，跳过 pending 字段合并" % [str(rev_p), str(rev_c)])
		return
	print("[Network] pending_ts=%s > cloud_ts=%s，合并 pending 区块到云快照" % [str(ts_p), str(ts_c)])
	if not pd_p.is_empty():
		save_data["playerData"] = pd_p.duplicate(true)
	if p.has("petsData"):
		var cloud_pets_raw: Variant = save_data.get("petsData", null)
		var cloud_assist_snapshot: Array = []
		var cloud_has_assist: = false
		if cloud_pets_raw is Dictionary and (cloud_pets_raw as Dictionary).has("assist_pets"):
			var ca: Variant = (cloud_pets_raw as Dictionary).get("assist_pets", [])
			if ca is Array:
				cloud_assist_snapshot = (ca as Array).duplicate(true)
				cloud_has_assist = true
		if _merge_use_pending_pets(p["petsData"], cloud_pets_raw):
			var pv: Variant = p["petsData"]
			if pv is Dictionary:
				var cloud_pd: Dictionary = cloud_pets_raw if cloud_pets_raw is Dictionary else {}
				var pending_pd: Dictionary = pv as Dictionary
				var merged_pd: Dictionary
				if GameManager.instance:
					merged_pd = GameManager.instance.merge_pets_data_roster_whole_snapshot(cloud_pd, pending_pd)
				else:
					merged_pd = pending_pd.duplicate(true)
				_merge_active_pet_id_pending_over_cloud(merged_pd, cloud_pets_raw)

				merged_pd["assist_pets"] = cloud_assist_snapshot if cloud_has_assist else []
				save_data["petsData"] = merged_pd
			else:
				save_data["petsData"] = pv
				if save_data.get("petsData") is Dictionary:
					var forced: Dictionary = save_data.get("petsData")
					forced["assist_pets"] = cloud_assist_snapshot if cloud_has_assist else []
					save_data["petsData"] = forced
	var inventory_merged_from_pending: = false
	if p.has("inventoryData"):
		if _merge_use_pending_inventory(p["inventoryData"], save_data.get("inventoryData", null)):
			save_data["inventoryData"] = p["inventoryData"].duplicate(true)
			inventory_merged_from_pending = true
	if p.has("equipmentData"):
		if _merge_use_pending_equipment(p["equipmentData"], save_data.get("equipmentData", null)):
			var merged_eq: Dictionary = p["equipmentData"].duplicate(true)
			_merge_preserve_suit_enhance_from_cloud(merged_eq, save_data.get("equipmentData", null))
			save_data["equipmentData"] = merged_eq
	if p.has("martialArtsData"):

		print("[Network] pending 含 martialArtsData，保留云端武功布局（不以 pending 覆盖）")


	if inventory_merged_from_pending:
		if p.has("petEquipmentData"):
			var v_pe: Variant = p["petEquipmentData"]
			if v_pe is Dictionary and v_pe.has("equipped"):
				save_data["petEquipmentData"] = v_pe.duplicate(true)
			else:
				save_data["petEquipmentData"] = {"equipped": {}}
		else:
			save_data["petEquipmentData"] = {"equipped": {}}
	for key in ["craftingData", "petCollectionData", "suitData"]:
		if p.has(key):
			var v: Variant = p[key]
			if key == "petCollectionData" and v is Dictionary:
				var cloud_pc: Variant = save_data.get("petCollectionData", {})
				var cloud_dict: Dictionary = cloud_pc if cloud_pc is Dictionary else {}
				save_data["petCollectionData"] = _merge_pet_collection_take_max(v as Dictionary, cloud_dict)
			elif v is Dictionary:
				save_data[key] = v.duplicate(true)
			else:
				save_data[key] = v
	if p.has("questData"):
		var p_q: Variant = p["questData"]
		if p_q is Dictionary and p_q.has("quests"):
			save_data["questData"] = p_q.duplicate(true)
	if p.has("gameSettings") and p["gameSettings"] is Dictionary:
		var cloud_gs: Dictionary = save_data.get("gameSettings", {}) if save_data.get("gameSettings") is Dictionary else {}
		var pending_gs: Dictionary = (p["gameSettings"] as Dictionary).duplicate(true)

		var cloud_map: = str(cloud_gs.get("current_map", "")).strip_edges()
		var cloud_prev: = str(cloud_gs.get("previous_map", "")).strip_edges()
		if cloud_map != "":
			pending_gs["current_map"] = cloud_map
		if cloud_gs.has("previous_map"):
			pending_gs["previous_map"] = cloud_prev
		if cloud_gs.has("save_revision"):
			pending_gs["save_revision"] = cloud_gs.get("save_revision")
		if cloud_gs.has("auto_capture_enabled"):
			pending_gs["auto_capture_enabled"] = cloud_gs.get("auto_capture_enabled")
		if cloud_gs.has("min_growth_threshold"):
			pending_gs["min_growth_threshold"] = cloud_gs.get("min_growth_threshold")
		save_data["gameSettings"] = pending_gs
		print("[Network] pending gameSettings 已合并，current_map/捕捉设置保留云端 map=%s" % cloud_map)



func xianmo_join(faction: String):
	print("[Network] xianmo_join called, faction=", faction)
	if auth_token == "":
		xianmo_join_failed.emit("未登录")
		return
	_enqueue_request("xianmo_join", func():
		var body = {"faction": faction}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/join", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			print("[Network] xianmo_join request failed, err=", err)
			xianmo_join_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_get_info():
	if auth_token == "":
		xianmo_info_loaded.emit({"joined": false})
		return
	_enqueue_request("xianmo_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_info_loaded.emit({"joined": false})
			_complete_request()
	)

func xianmo_get_faction_stats():
	_enqueue_request("xianmo_faction_stats", func():
		# 这条原来只发了 Content-Type，服务端一律 401 → 阵营人数/积分永远是 0。
		# 服务端现在把这条放进公开白名单了，但带上令牌更稳妥（联调/多账号时不会串）。
		var headers = ["Content-Type: application/json"]
		if auth_token != "":
			headers.append("Authorization: Bearer " + auth_token)
		var err = http_request.request(server_url + "/xianmo/faction/stats", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_faction_stats_loaded.emit({})
			_complete_request()
	)

func xianmo_get_ranking(faction: String = ""):
	var url = server_url + "/xianmo/ranking"
	if faction != "":
		url += "?faction=" + faction
	print("[Network] xianmo_get_ranking: url=", url)
	_enqueue_request("xianmo_ranking", func():
		var headers = ["Content-Type: application/json"]
		if auth_token != "":
			headers.append("Authorization: Bearer " + auth_token)
		_current_request_info["faction"] = faction
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			print("[Network] xianmo_get_ranking request failed: err=", err)
			xianmo_ranking_loaded.emit([], 0, faction)
			_complete_request()
	)

func xianmo_adventure(points: int = 1):
	if auth_token == "":
		xianmo_adventure_failed.emit("未登录")
		return
	_enqueue_request("xianmo_adventure", func():
		var body = {"points": points}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/adventure", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_adventure_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_report_battle_result(event_id: String, victory: bool, score_gain: int, opponent: String, operation_id: String = ""):
	if auth_token == "":
		xianmo_battle_result_failed.emit("未登录")
		return
	_enqueue_request("xianmo_battle_result", func():
		var op_id: = operation_id.strip_edges()
		if op_id == "":
			op_id = "xianmo_battle_%s_%s_%s" % [str(user_id), str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
		var body = {"eventId": event_id, "victory": victory, "scoreGain": score_gain, "opponent": opponent, "operationId": op_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/battle/result", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_battle_result_failed.emit("网络请求失败")
			_complete_request()
	)

signal xianmo_pet_exchange_success(data: Dictionary)
signal xianmo_pet_exchange_failed(error: String)

func xianmo_pet_exchange():
	if auth_token == "":
		xianmo_pet_exchange_failed.emit("未登录")
		return
	_enqueue_request("xianmo_pet_exchange", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/pet/exchange", headers, HTTPClient.METHOD_POST, "")
		if err != OK:
			xianmo_pet_exchange_failed.emit("网络请求失败")
			_complete_request()
	)

func consume_duplicate_resync_skip_download_handler() -> bool:
	var skip: = _duplicate_resync_skip_standard_download_handler
	_duplicate_resync_skip_standard_download_handler = false
	return skip

func _authority_response_has_save_data(data: Dictionary) -> bool:
	var save_data: Variant = data.get("saveData", null)
	return save_data is Dictionary and not (save_data as Dictionary).is_empty()

func _capture_suit_enhance_resync_baseline(action_type: String) -> void :
	var stones: = -1
	if GameManager.instance and GameManager.instance.inventory_manager:
		stones = int(GameManager.instance.inventory_manager.get_item_count(SuitEquipmentEnhance.STONE_ITEM))
	_suit_enhance_resync_baseline = {
		"action_type": action_type, 
		"save_revision": get_last_server_save_revision(), 
		"stone_count": stones, 
	}

func _try_begin_suit_enhance_ambiguous_resync(action_type: String, orig_data: Dictionary, reason: String = "transport_failure") -> bool:
	if action_type != "suit_equipment_enhance" and action_type != "suit_equipment_enhance_confirm":
		return false
	if not _duplicate_resync_supports_action_type(action_type):
		return false
	_duplicate_resync_ctx = {
		"action_type": action_type, 
		"data": orig_data.duplicate(true), 
		"reason": reason, 
	}
	_duplicate_resync_skip_standard_download_handler = true
	save_downloaded.connect(_on_duplicate_resync_save_downloaded, CONNECT_ONE_SHOT)
	print("[CloudSync] 套装强化模糊失败，拉档同步 type=%s reason=%s" % [action_type, reason])
	download_save()
	return true

func _save_revision_from_download_save(sd: Dictionary) -> int:
	var gs: Variant = sd.get("gameSettings", null)
	if gs is Dictionary:
		var gs_rev: = int((gs as Dictionary).get("save_revision", -1))
		if gs_rev >= 0:
			return gs_rev
	return int(sd.get("save_revision", sd.get("saveRevision", -1)))

func _suit_enhance_stone_count_from_save(sd: Dictionary) -> int:
	var inv: Variant = sd.get("inventoryData", null)
	if not inv is Dictionary:
		return -1
	var items: Variant = (inv as Dictionary).get("items", [])
	if not items is Array:
		return 0
	var total: = 0
	for it in items:
		if it is Dictionary and str((it as Dictionary).get("name", "")) == SuitEquipmentEnhance.STONE_ITEM:
			total += int((it as Dictionary).get("count", 0))
	return total

func _is_suit_pending_active_in_save(sd: Dictionary) -> bool:
	var gs: Variant = sd.get("gameSettings", null)
	if not gs is Dictionary:
		return false
	var pending: Variant = (gs as Dictionary).get("pending_suit_enhance", null)
	if not pending is Dictionary or (pending as Dictionary).is_empty():
		return false
	var token: = str((pending as Dictionary).get("token", "")).strip_edges()
	if token.is_empty():
		return false
	var now_ms: = Time.get_unix_time_from_system() * 1000
	var expires_at: = int((pending as Dictionary).get("expiresAt", (pending as Dictionary).get("expires_at", 0)))
	if expires_at > 0:
		return now_ms < expires_at
	var created_at: = int((pending as Dictionary).get("createdAt", (pending as Dictionary).get("created_at", 0)))
	if created_at > 0:
		return now_ms < created_at + SuitEquipmentEnhance.PENDING_EXPIRE_SEC * 1000
	return false

func _suit_enhance_result_from_pending(pending: Dictionary) -> Dictionary:
	var current_level: = int(pending.get("currentLevel", pending.get("current_level", 0)))
	return {
		"success": true, 
		"needsConfirm": true, 
		"pendingToken": str(pending.get("token", "")), 
		"equipmentId": str(pending.get("equipmentId", pending.get("equipment_id", ""))), 
		"name": "套装", 
		"boostPercent": float(pending.get("boostPercent", pending.get("boost_percent", 0))), 
		"currentStats": pending.get("currentStats", pending.get("current_stats", {})), 
		"previewStats": pending.get("previewStats", pending.get("preview_stats", {})), 
		"currentLevel": current_level, 
		"nextLevel": int(pending.get("nextLevel", pending.get("next_level", current_level + 1))), 
	}

func _suit_enhance_success_payload_from_save_data(data: Dictionary) -> Dictionary:
	var sd: Variant = data.get("saveData", null)
	if not sd is Dictionary:
		return {}
	if not _is_suit_pending_active_in_save(sd as Dictionary):
		return {}
	var gs: Dictionary = (sd as Dictionary).get("gameSettings", {}) if (sd as Dictionary).get("gameSettings") is Dictionary else {}
	var pending: Dictionary = gs.get("pending_suit_enhance", {}) if gs.get("pending_suit_enhance") is Dictionary else {}
	var out: = data.duplicate(true)
	out["success"] = true
	out["needsConfirm"] = true
	out["result"] = _suit_enhance_result_from_pending(pending)
	var msg: = str(out.get("message", "")).strip_edges()
	if msg.is_empty():
		out["message"] = "强化已成功，请选择是否应用属性"
	return out

func _finish_suit_enhance_transport_resync(action_type: String, sd: Dictionary, orig: Dictionary) -> void :
	var baseline: = _suit_enhance_resync_baseline
	_suit_enhance_resync_baseline = {}
	var baseline_rev: = int(baseline.get("save_revision", -1))
	var baseline_stones: = int(baseline.get("stone_count", -1))
	var new_rev: = _save_revision_from_download_save(sd)
	var new_stones: = _suit_enhance_stone_count_from_save(sd)
	var server_changed: = (baseline_rev >= 0 and new_rev > baseline_rev)\
	or (baseline_stones >= 0 and new_stones >= 0 and new_stones < baseline_stones)
	if _is_suit_pending_active_in_save(sd) and action_type == "suit_equipment_enhance":
		var gs: Dictionary = sd.get("gameSettings", {}) if sd.get("gameSettings") is Dictionary else {}
		var pending: Dictionary = gs.get("pending_suit_enhance", {}) if gs.get("pending_suit_enhance") is Dictionary else {}
		var enriched: = orig.duplicate(true)
		enriched["saveData"] = sd.duplicate(true)
		enriched["success"] = true
		enriched["needsConfirm"] = true
		enriched["transport_resync"] = true
		enriched["result"] = _suit_enhance_result_from_pending(pending)
		enriched["message"] = "强化已成功，请选择是否应用属性"
		_emit_duplicate_resync_success(action_type, enriched)
		return
	if server_changed:
		var enriched: = orig.duplicate(true)
		enriched["saveData"] = sd.duplicate(true)
		enriched["success"] = true
		enriched["transport_resync"] = true
		if action_type == "suit_equipment_enhance_confirm":
			enriched["message"] = "已同步云端强化确认结果"
		else:
			enriched["message"] = "已同步云端强化结果"
		_emit_duplicate_resync_success(action_type, enriched)
		return
	_emit_duplicate_resync_failed(action_type, "网络异常，未能确认是否扣石，请重新打开背包或重登查看")

func _duplicate_resync_supports_action_type(action_type: String) -> bool:
	match action_type:
		"pet_merge", "pet_reincarnation", "pet_reincarnation_inherit", "pet_evolve", \
		"pet_refine", "pet_release", "pet_release_batch", "pet_bag_store", "pet_bag_store_batch", "pet_bag_retrieve", "pet_bag_retrieve_batch", "pet_assist_equip", "pet_assist_unequip", \
		"pet_collection_invest", "pet_soul_commit", "pet_soul_commit_batch", "pet_soul_use_item", \
		"equipment_equip", "equipment_unequip", "equipment_unseal_suit", "equipment_suit_convert", \
		"equipment_dismantle_suit", "equipment_dismantle_suit_batch", "equipment_store_warehouse", "equipment_retrieve_warehouse", \
		"inventory_store_warehouse_batch", "equipment_retrieve_warehouse_batch", \
		"pet_equipment_equip", "pet_equipment_unequip", "pet_equipment_store_warehouse", \
		"pet_equipment_retrieve_warehouse", "pet_equipment_dismantle", "pet_equipment_dismantle_batch", "pet_equipment_drop", \
		"pet_equipment_enhance", "pet_equipment_synthesize_fragments", "inventory_synthesize_seal_stone", "pill_craft", \
		"suit_equipment_enhance", "suit_equipment_enhance_confirm", "pet_equipment_grant", \
		"equipment_drop", "inventory_drop", "inventory_store_warehouse", "frontier_gift_use", \
		"pet_egg_open", "pet_gift_open", "pet_medal_use", "pet_medal_use_batch", "forge_preview", \
		"pet_skill_synthetic", "pet_skill_split", "pet_skill_learn", "pet_skill_unlearn", "pet_skill_slot_lock", "pet_skill_sync", \
		"pet_max_level_learn", "pet_grant_medal", \
		"forge_execute", "realm_transition":
			return true
		_:
			return false

func _begin_duplicate_resync_download(action_type: String, data: Dictionary) -> void :
	_duplicate_resync_ctx = {
		"action_type": action_type, 
		"data": data.duplicate(true), 
	}
	_duplicate_resync_skip_standard_download_handler = true
	save_downloaded.connect(_on_duplicate_resync_save_downloaded, CONNECT_ONE_SHOT)
	print("[CloudSync] duplicate 无 saveData，拉档同步 type=%s" % action_type)
	download_save()

func _on_duplicate_resync_save_downloaded(save_data) -> void :
	var ctx: = _duplicate_resync_ctx
	_duplicate_resync_ctx = {}
	var action_type: = str(ctx.get("action_type", "")).strip_edges()
	var orig: Dictionary = ctx.get("data", {}) if ctx.get("data") is Dictionary else {}
	if action_type.is_empty():
		push_warning("[CloudSync] duplicate resync 缺少 action_type，忽略")
		return
	if save_data == null or not save_data is Dictionary:
		_emit_duplicate_resync_failed(action_type, "操作已完成，但同步云端失败，请稍后重试")
		return
	var sd: Dictionary = save_data
	if bool(sd.get("_download_error", false)):
		var err_msg: = str(sd.get("error_msg", "")).strip_edges()
		if err_msg.is_empty():
			err_msg = "操作已完成，但同步云端失败，请稍后重试"
		_emit_duplicate_resync_failed(action_type, err_msg)
		return
	var reason: = str(ctx.get("reason", "duplicate")).strip_edges()
	if reason == "transport_failure" or reason == "pending_recovery":
		if action_type == "suit_equipment_enhance" or action_type == "suit_equipment_enhance_confirm":
			_finish_suit_enhance_transport_resync(action_type, sd, orig)
			return
	var enriched: = orig.duplicate(true)
	enriched["saveData"] = sd.duplicate(true)
	enriched["duplicate"] = true
	enriched["duplicate_resync"] = true
	var msg: = str(enriched.get("message", "")).strip_edges()
	if msg.is_empty():
		enriched["message"] = "操作已完成，已同步云端"
	_emit_duplicate_resync_success(action_type, enriched)

func _emit_duplicate_resync_success(action_type: String, data: Dictionary) -> void :
	match action_type:
		"pet_merge":
			pet_merge_success.emit(data)
		"pet_reincarnation":
			pet_reincarnation_success.emit(data)
		"pet_reincarnation_inherit":
			pet_reincarnation_inherit_success.emit(data)
		"pet_evolve":
			pet_evolve_success.emit(data)
		"pet_refine":
			pet_refine_success.emit(data)
		"pet_release":
			pet_release_success.emit(data)
		"pet_release_batch":
			pet_release_batch_success.emit(data)
		"pet_bag_store":
			pet_bag_store_success.emit(data)
		"pet_bag_store_batch":
			pet_bag_store_batch_success.emit(data)
		"pet_bag_retrieve":
			pet_bag_retrieve_success.emit(data)
		"pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_success.emit(data)
		"pet_assist_equip":
			pet_assist_equip_success.emit(data)
		"pet_assist_unequip":
			pet_assist_unequip_success.emit(data)
		"pet_collection_invest":
			pet_collection_invest_success.emit(data)
		"pet_soul_commit":
			pet_soul_commit_success.emit(data)
		"pet_soul_commit_batch":
			pet_soul_commit_batch_success.emit(data)
		"pet_soul_use_item":
			pet_soul_use_item_success.emit(data)
		"equipment_equip":
			equipment_equip_success.emit(data)
		"equipment_unequip":
			equipment_unequip_success.emit(data)
		"equipment_unseal_suit":
			equipment_unseal_suit_success.emit(data)
		"equipment_suit_convert":
			equipment_suit_convert_success.emit(data)
		"equipment_dismantle_suit":
			equipment_dismantle_suit_success.emit(data)
		"equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_success.emit(data)
		"equipment_store_warehouse":
			equipment_store_warehouse_success.emit(data)
		"equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_success.emit(data)
		"inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_success.emit(data)
		"equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_success.emit(data)
		"pet_equipment_equip":
			pet_equipment_equip_success.emit(data)
		"pet_equipment_unequip":
			pet_equipment_unequip_success.emit(data)
		"pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_success.emit(data)
		"pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_success.emit(data)
		"pet_equipment_dismantle":
			pet_equipment_dismantle_success.emit(data)
		"pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_success.emit(data)
		"pet_equipment_drop":
			pet_equipment_drop_success.emit(data)
		"pet_equipment_enhance":
			pet_equipment_enhance_success.emit(data)
		"pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_success.emit(data)
		"inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_success.emit(data)
		"pill_craft":
			pill_craft_success.emit(data)
		"suit_equipment_enhance":
			suit_equipment_enhance_success.emit(data)
		"suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_success.emit(data)
		"pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_success_deferred", data)
		"equipment_drop":
			equipment_drop_success.emit(data)
		"inventory_drop":
			inventory_drop_success.emit(data)
		"inventory_store_warehouse":
			inventory_store_warehouse_success.emit(data)
		"frontier_gift_use":
			frontier_gift_use_success.emit(data)
		"pet_egg_open":
			pet_egg_open_success.emit(data)
		"pet_gift_open":
			pet_gift_open_success.emit(data)
		"pet_medal_use":
			pet_medal_use_success.emit(data)
		"pet_medal_use_batch":
			pet_medal_use_batch_success.emit(data)
		"forge_preview":
			forge_preview_success.emit(data)
		"pet_skill_synthetic":
			pet_skill_synthetic_success.emit(data)
		"pet_skill_split":
			pet_skill_split_success.emit(data)
		"pet_skill_learn":
			pet_skill_learn_success.emit(data)
		"pet_skill_unlearn":
			pet_skill_unlearn_success.emit(data)
		"pet_skill_slot_lock":
			pet_skill_slot_lock_success.emit(data)
		"pet_skill_sync":
			pet_skill_sync_success.emit(data)
		"pet_max_level_learn":
			pet_max_level_learn_success.emit(data)
		"forge_execute":
			forge_execute_success.emit(data)
		"realm_transition":
			realm_transition_success.emit(data)
		_:
			push_warning("[CloudSync] duplicate resync success 未映射 type=%s" % action_type)

func _emit_duplicate_resync_failed(action_type: String, err_msg: String) -> void :
	match action_type:
		"pet_merge":
			pet_merge_failed.emit(err_msg)
		"pet_reincarnation":
			pet_reincarnation_failed.emit(err_msg)
		"pet_reincarnation_inherit":
			pet_reincarnation_inherit_failed.emit(err_msg)
		"pet_evolve":
			pet_evolve_failed.emit(err_msg)
		"pet_refine":
			pet_refine_failed.emit(err_msg)
		"pet_release":
			pet_release_failed.emit(err_msg)
		"pet_release_batch":
			pet_release_batch_failed.emit(err_msg)
		"pet_bag_store":
			pet_bag_store_failed.emit(err_msg)
		"pet_bag_store_batch":
			pet_bag_store_batch_failed.emit(err_msg)
		"pet_bag_retrieve":
			pet_bag_retrieve_failed.emit(err_msg)
		"pet_bag_retrieve_batch":
			pet_bag_retrieve_batch_failed.emit(err_msg)
		"pet_assist_equip":
			pet_assist_equip_failed.emit(err_msg)
		"pet_assist_unequip":
			pet_assist_unequip_failed.emit(err_msg)
		"pet_collection_invest":
			pet_collection_invest_failed.emit(err_msg)
		"pet_soul_commit":
			pet_soul_commit_failed.emit(err_msg)
		"pet_soul_commit_batch":
			pet_soul_commit_batch_failed.emit(err_msg)
		"pet_soul_use_item":
			pet_soul_use_item_failed.emit(err_msg)
		"equipment_equip":
			equipment_equip_failed.emit(err_msg)
		"equipment_unequip":
			equipment_unequip_failed.emit(err_msg)
		"equipment_unseal_suit":
			equipment_unseal_suit_failed.emit(err_msg)
		"equipment_suit_convert":
			equipment_suit_convert_failed.emit(err_msg)
		"equipment_dismantle_suit":
			equipment_dismantle_suit_failed.emit(err_msg)
		"equipment_dismantle_suit_batch":
			equipment_dismantle_suit_batch_failed.emit(err_msg)
		"equipment_store_warehouse":
			equipment_store_warehouse_failed.emit(err_msg)
		"equipment_retrieve_warehouse":
			equipment_retrieve_warehouse_failed.emit(err_msg)
		"inventory_store_warehouse_batch":
			inventory_store_warehouse_batch_failed.emit(err_msg)
		"equipment_retrieve_warehouse_batch":
			equipment_retrieve_warehouse_batch_failed.emit(err_msg)
		"pet_equipment_equip":
			pet_equipment_equip_failed.emit(err_msg)
		"pet_equipment_unequip":
			pet_equipment_unequip_failed.emit(err_msg)
		"pet_equipment_store_warehouse":
			pet_equipment_store_warehouse_failed.emit(err_msg)
		"pet_equipment_retrieve_warehouse":
			pet_equipment_retrieve_warehouse_failed.emit(err_msg)
		"pet_equipment_dismantle":
			pet_equipment_dismantle_failed.emit(err_msg)
		"pet_equipment_dismantle_batch":
			pet_equipment_dismantle_batch_failed.emit(err_msg)
		"pet_equipment_drop":
			pet_equipment_drop_failed.emit(err_msg)
		"pet_equipment_enhance":
			pet_equipment_enhance_failed.emit(err_msg)
		"pet_equipment_synthesize_fragments":
			pet_equipment_synthesize_fragments_failed.emit(err_msg)
		"inventory_synthesize_seal_stone":
			inventory_synthesize_seal_stone_failed.emit(err_msg)
		"pill_craft":
			pill_craft_failed.emit(err_msg)
		"suit_equipment_enhance":
			suit_equipment_enhance_failed.emit(err_msg)
		"suit_equipment_enhance_confirm":
			suit_equipment_enhance_confirm_failed.emit(err_msg)
		"pet_equipment_grant":
			call_deferred("_emit_pet_equipment_grant_failed_deferred", err_msg)
		"equipment_drop":
			equipment_drop_failed.emit(err_msg)
		"inventory_drop":
			inventory_drop_failed.emit(err_msg)
		"inventory_store_warehouse":
			inventory_store_warehouse_failed.emit(err_msg)
		"frontier_gift_use":
			frontier_gift_use_failed.emit(err_msg)
		"pet_egg_open":
			pet_egg_open_failed.emit(err_msg)
		"pet_gift_open":
			pet_gift_open_failed.emit(err_msg)
		"pet_medal_use":
			pet_medal_use_failed.emit(err_msg)
		"pet_medal_use_batch":
			pet_medal_use_batch_failed.emit(err_msg)
		"forge_preview":
			forge_preview_failed.emit(err_msg)
		"pet_skill_synthetic":
			pet_skill_synthetic_failed.emit(err_msg)
		"pet_skill_split":
			pet_skill_split_failed.emit(err_msg)
		"pet_skill_learn":
			pet_skill_learn_failed.emit(err_msg)
		"pet_skill_unlearn":
			pet_skill_unlearn_failed.emit(err_msg)
		"pet_skill_slot_lock":
			pet_skill_slot_lock_failed.emit(err_msg)
		"pet_skill_sync":
			pet_skill_sync_failed.emit(err_msg)
		"pet_max_level_learn":
			pet_max_level_learn_failed.emit(err_msg)
		"forge_execute":
			forge_execute_failed.emit(err_msg)
		"realm_transition":
			realm_transition_failed.emit(err_msg)
		_:
			push_warning("[CloudSync] duplicate resync failed 未映射 type=%s msg=%s" % [action_type, err_msg])

func _lottery_draw_response_ok(data: Dictionary) -> bool:
	if not bool(data.get("success", false)):
		return false
	if bool(data.get("duplicate", false)):
		if not _authority_response_has_save_data(data):
			return false
	return true

func _emit_lottery_draw_result(data: Dictionary) -> void :
	if _lottery_draw_response_ok(data):
		lottery_draw_success.emit(data)
		return
	var err_msg: = "抽奖响应无效"
	if bool(data.get("duplicate", false)):
		err_msg = "抽奖重复确认失败，请重试"
	elif data.has("error"):
		err_msg = str(data.get("error"))
	lottery_draw_failed.emit(err_msg)

func lottery_draw(pool_type: String, operation_id: String = ""):
	if auth_token == "":
		lottery_draw_failed.emit("未登录")
		return
	_enqueue_request("lottery_draw", func():
		var body = {"pool": pool_type}
		if operation_id != "":
			body["client_op_id"] = operation_id
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/lottery/draw", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			lottery_draw_failed.emit("网络请求失败")
			_complete_request()
	)

func lottery_get_pity_status():
	if auth_token == "":
		lottery_pity_status_failed.emit("未登录")
		return
	_enqueue_request("lottery_pity_status", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/lottery/pity/status", headers, HTTPClient.METHOD_GET)
		if err != OK:
			lottery_pity_status_failed.emit("网络请求失败")
			_complete_request()
	)

func lottery_claim_pity_reward(reward_name: String, operation_id: String = ""):
	if auth_token == "":
		lottery_pity_claim_failed.emit("未登录")
		return
	var trimmed = reward_name.strip_edges()
	if trimmed.is_empty():
		lottery_pity_claim_failed.emit("请选择保底奖励")
		return
	_enqueue_request("lottery_pity_claim", func():
		var body = {"rewardName": trimmed}
		if operation_id != "":
			body["operationId"] = operation_id
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/lottery/pity/claim", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			lottery_pity_claim_failed.emit("网络请求失败")
			_complete_request()
	)


func get_noble_info():
	if auth_token == "":
		noble_info_failed.emit("未登录")
		return
	_enqueue_request("noble_info", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/noble/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			noble_info_failed.emit("网络请求失败")
			_complete_request()
	)


func claim_noble_reward(claim_type: String, claim_level: int = 0):
	if auth_token == "":
		noble_claim_failed.emit("未登录")
		return
	var trimmed = claim_type.strip_edges()
	if trimmed.is_empty():
		noble_claim_failed.emit("请选择要领取的奖励")
		return
	_enqueue_request("noble_claim", func():
		var operation_id = "noble_claim_%s_%s_%s" % [str(user_id), str(Time.get_unix_time_from_system()), str(randi())]
		var body = {"claimType": trimmed, "operationId": operation_id}
		if trimmed == "extreme_equip" and claim_level > 0:
			body["claimLevel"] = claim_level
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/noble/claim", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			noble_claim_failed.emit("网络请求失败")
			_complete_request()
	)

func shop_buy(item_name: String, operation_id: String = "", currency: String = "", quantity: int = 1):
	if auth_token == "":
		shop_buy_failed.emit("未登录")
		return
	if item_name.strip_edges().is_empty():
		shop_buy_failed.emit("商品名不能为空")
		return
	var qty: = clampi(quantity, 1, 999)
	var body = {"itemName": item_name, "quantity": qty}
	if operation_id != "":
		body["operationId"] = operation_id
	var cur: = currency.strip_edges()
	if not cur.is_empty():
		body["currency"] = cur
	var json = JSON.stringify(body)
	_enqueue_shop_buy_dedicated(json, operation_id)

func get_main_shop_catalog() -> void :
	if auth_token == "":
		main_shop_catalog_failed.emit("未登录")
		return
	_enqueue_request("main_shop_catalog", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/shop/catalog", headers, HTTPClient.METHOD_GET)
		if err != OK:
			main_shop_catalog_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_get_shop_items():
	_enqueue_request("xianmo_shop_items", func():
		var headers = ["Content-Type: application/json"]
		if auth_token != "":
			headers.append("Authorization: Bearer " + auth_token)
		var err = http_request.request(server_url + "/xianmo/shop/items", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_shop_items_loaded.emit([])
			_complete_request()
	)

func xianmo_shop_buy(item_id: String, operation_id: String = ""):
	if auth_token == "":
		xianmo_shop_buy_failed.emit("未登录")
		return
	_enqueue_request("xianmo_shop_buy", func():
		var body = {"itemId": item_id}
		if operation_id != "":
			body["operationId"] = operation_id
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/shop/buy", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_shop_buy_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_treasure_exchange(operation_id: String = ""):
	if auth_token == "":
		xianmo_treasure_exchange_failed.emit("未登录")
		return
	_enqueue_request("xianmo_treasure_exchange", func():
		var body = {}
		if operation_id != "":
			body["operationId"] = operation_id
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/treasure/exchange", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_treasure_exchange_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_get_week_info():
	_enqueue_request("xianmo_week_info", func():
		var headers = ["Content-Type: application/json"]
		if auth_token != "":
			headers.append("Authorization: Bearer " + auth_token)
		var err = http_request.request(server_url + "/xianmo/week/info", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_week_info_loaded.emit({})
			_complete_request()
	)

func xianmo_open_chest(chest_type: String):
	if auth_token == "":
		xianmo_chest_open_failed.emit("未登录")
		return
	_enqueue_request("xianmo_chest_open", func():
		var body = {"chestType": chest_type}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/chest/open", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_chest_open_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_open_chest_batch(chest_type: String, count: int, operation_id: String):
	if auth_token == "":
		xianmo_chest_open_batch_failed.emit("未登录")
		return
	var open_count: = clampi(count, 1, 10)
	var op_id: = operation_id.strip_edges()
	if op_id == "":
		op_id = "xianmo_chest_open_batch_%s_%s_%s" % [str(user_id), str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
	_enqueue_request("xianmo_chest_open_batch", func():
		var body = {"chestType": chest_type, "count": open_count, "operationId": op_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/xianmo/chest/open-batch", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_chest_open_batch_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_chest_deposit(chest_type: String, operation_id: String):
	if auth_token == "":
		xianmo_chest_deposit_failed.emit("未登录")
		return
	var body = {"chestType": chest_type, "operationId": operation_id}
	var json = JSON.stringify(body)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var err = xianmo_chest_request.request(server_url + "/xianmo/chest/deposit", headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		if err == ERR_BUSY:
			xianmo_chest_deposit_failed.emit("网络繁忙，请稍后再试")
		else:
			xianmo_chest_deposit_failed.emit("网络请求失败")

func xianmo_use_treasure_map(map_id: String, operation_id: String = ""):
	if auth_token == "":
		xianmo_treasure_use_failed.emit("未登录")
		return
	_enqueue_request("xianmo_treasure_use", func():
		var op_id: = operation_id.strip_edges()
		if op_id == "":
			op_id = "xianmo_treasure_use_%s_%s_%s" % [str(user_id), str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
		var body = {"mapId": map_id, "operationId": op_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/treasure/use", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_treasure_use_failed.emit("网络请求失败")
			_complete_request()
	)

func xianmo_get_mirror():
	if auth_token == "":
		xianmo_mirror_loaded.emit({})
		return
	_enqueue_request("xianmo_mirror", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/mirror", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_mirror_loaded.emit({})
			_complete_request()
	)

func xianmo_get_titles():
	if auth_token == "":
		xianmo_titles_loaded.emit([])
		return
	_enqueue_request("xianmo_titles", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/titles", headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_titles_loaded.emit([])
			_complete_request()
	)

func xianmo_activate_title(title_id: Variant):
	if auth_token == "":
		xianmo_title_activated.emit({"success": false})
		return
	_enqueue_request("xianmo_title_activate", func():
		var body = {"titleId": str(title_id)}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/titles/activate", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_title_activated.emit({"success": false})
			_complete_request()
	)

func xianmo_deactivate_title():
	if auth_token == "":
		xianmo_title_deactivated.emit({"success": false})
		return
	_enqueue_request("xianmo_title_deactivate", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/titles/deactivate", headers, HTTPClient.METHOD_POST, "{}")
		if err != OK:
			xianmo_title_deactivated.emit({"success": false})
			_complete_request()
	)

func xianmo_get_broadcasts(last_id: int = 0, limit: int = 20):
	if auth_token == "":
		xianmo_broadcasts_loaded.emit([])
		return
	var safe_limit: int = max(1, limit)
	var url = server_url + "/xianmo/broadcasts?lastId=" + str(last_id) + "&limit=" + str(safe_limit)
	_enqueue_request("xianmo_broadcasts", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			xianmo_broadcasts_loaded.emit([])
			_complete_request()
	)


func fetch_xianmo_broadcast_history_snapshot(last_id: int = 0, limit: int = 30) -> Array:
	var out: Array = []
	if auth_token.strip_edges().is_empty() or not is_instance_valid(_broadcast_hist_snap_http):
		return out
	if _broadcast_hist_snap_busy:
		return out
	_broadcast_hist_snap_busy = true
	var cap: = clampi(limit, 1, 50)
	var url: = server_url + "/xianmo/broadcasts?lastId=" + str(last_id) + "&limit=" + str(cap)
	var headers: = PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + auth_token])
	var err: = _broadcast_hist_snap_http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_broadcast_hist_snap_busy = false
		return out
	var args = await _broadcast_hist_snap_http.request_completed
	_broadcast_hist_snap_busy = false
	var result: int = args[0]
	var response_code: int = args[1]
	var body: PackedByteArray = args[3]
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return out
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return out
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return out
	var arr: Variant = (data as Dictionary).get("broadcasts", [])
	if arr is Array:
		out = arr as Array
	return out

func xianmo_send_broadcast(broadcast_type: String, content: String, extra_data: Dictionary = {}):
	if auth_token == "":
		xianmo_broadcast_sent.emit(false)
		return
	_enqueue_request("xianmo_broadcast", func():
		var body = {"broadcastType": broadcast_type, "content": content, "extraData": extra_data}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var err = http_request.request(server_url + "/xianmo/broadcast", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			xianmo_broadcast_sent.emit(false)
			_complete_request()
	)

func treasure_get_status():
	if auth_token == "":
		treasure_status_loaded.emit({})
		return
	if treasure_status_request == null:
		treasure_status_loaded.emit({})
		return
	if treasure_status_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		treasure_status_request.cancel_request()
	_treasure_status_defer_attempts = 0
	call_deferred("_treasure_status_try_request_deferred")

func _treasure_status_try_request_deferred() -> void :
	if treasure_status_request == null or auth_token == "":
		treasure_status_loaded.emit({})
		return
	if treasure_status_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_treasure_status_defer_attempts += 1
		if _treasure_status_defer_attempts > 45:
			_treasure_status_defer_attempts = 0
			treasure_status_loaded.emit({})
			return
		call_deferred("_treasure_status_try_request_deferred")
		return
	_treasure_status_defer_attempts = 0
	var headers: = _build_headers(true, false)
	var err: = treasure_status_request.request(server_url + "/treasure/status", headers, HTTPClient.METHOD_GET)
	if err != OK:
		treasure_status_loaded.emit({})

func _on_treasure_status_request_completed(result, response_code, _headers, body) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		_treasure_status_429_round = 0
		treasure_status_loaded.emit({})
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_treasure_status_429_round = 0
		treasure_status_loaded.emit({})
		return
	var data = json.data
	if not data is Dictionary:
		_treasure_status_429_round = 0
		treasure_status_loaded.emit({})
		return
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_treasure_status_429_round = 0
		_emit_force_update(data)
		treasure_status_loaded.emit({})
		return
	if response_code == 429:
		if _treasure_status_429_round < TREASURE_STATUS_429_MAX_ROUNDS:
			_treasure_status_429_round += 1
			var tw: = get_tree().create_timer(2.5 + float(_treasure_status_429_round) * 0.5, true)
			tw.timeout.connect(treasure_get_status, CONNECT_ONE_SHOT)
			return
		_treasure_status_429_round = 0
		treasure_status_loaded.emit({})
		return
	_treasure_status_429_round = 0
	if response_code == 200:
		treasure_status_loaded.emit(data)
	else:
		treasure_status_loaded.emit({})

func treasure_join(chest_id: int):
	if auth_token == "":
		treasure_join_failed.emit("未登录")
		return
	if treasure_join_request == null:
		treasure_join_failed.emit("网络未初始化")
		return
	if treasure_join_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		treasure_join_failed.emit("正在提交入阵请求，请稍候")
		return
	_treasure_join_defer_attempts = 0
	call_deferred("_treasure_join_try_request_deferred", chest_id)

func _treasure_join_try_request_deferred(chest_id: int) -> void :
	if treasure_join_request == null or auth_token == "":
		treasure_join_failed.emit("网络未初始化")
		return
	if treasure_join_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_treasure_join_defer_attempts += 1
		if _treasure_join_defer_attempts > 45:
			_treasure_join_defer_attempts = 0
			treasure_join_failed.emit("入阵请求繁忙，请稍后重试")
			return
		call_deferred("_treasure_join_try_request_deferred", chest_id)
		return
	_treasure_join_defer_attempts = 0
	var body: = {"chestId": chest_id}
	var headers: = _build_headers(true, true)
	var err: = treasure_join_request.request(server_url + "/treasure/join", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		treasure_join_failed.emit("网络请求失败")

func _on_treasure_join_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		treasure_join_failed.emit("网络请求失败")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		treasure_join_failed.emit("服务器返回数据格式错误")
		return
	var data = json.data
	if not data is Dictionary:
		treasure_join_failed.emit("服务器返回数据格式错误")
		return
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		treasure_join_failed.emit("当前客户端版本过低，请更新后继续游戏")
		return
	if response_code == 200 and bool(data.get("success", false)):
		treasure_join_success.emit(data)
		return
	treasure_join_failed.emit(str(data.get("error", "入阵失败")))

func request_treasure_mirror_info() -> Dictionary:
	return await _request_treasure_mirror(HTTPClient.METHOD_GET, "/treasure/mirror", "")

func request_treasure_mirror_update() -> Dictionary:
	return await _request_treasure_mirror(HTTPClient.METHOD_POST, "/treasure/mirror/update", "{}")

func _request_treasure_mirror(method: int, path: String, body: String) -> Dictionary:
	if auth_token == "":
		return {"success": false, "ok": false, "error": "未登录"}
	if treasure_mirror_request == null:
		return {"success": false, "ok": false, "error": "网络未初始化"}
	if _treasure_mirror_busy:
		return {"success": false, "ok": false, "error": "镜像请求进行中"}
	_treasure_mirror_busy = true
	var err: = OK
	if method == HTTPClient.METHOD_POST:
		err = treasure_mirror_request.request(server_url + path, _build_headers(true, true), method, body)
	else:
		err = treasure_mirror_request.request(server_url + path, _build_headers(true, false), method)
	if err != OK:
		_treasure_mirror_busy = false
		return {"success": false, "ok": false, "error": "网络请求失败"}
	var completed: Array = await treasure_mirror_request.request_completed
	_treasure_mirror_busy = false
	var result: int = int(completed[0])
	var response_code: int = int(completed[1])
	var response_body: PackedByteArray = completed[3]
	var data: Dictionary = {}
	if response_body.size() > 0:
		var parsed = JSON.parse_string(response_body.get_string_from_utf8())
		if parsed is Dictionary:
			data = parsed
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if not data.has("error"):
			data["error"] = "请求失败(%d)" % response_code
		data["success"] = false
		data["ok"] = false
		return data
	data["success"] = true
	data["ok"] = true
	return data

func treasure_get_participants(chest_id: int):
	if auth_token == "":
		treasure_participants_loaded.emit([])
		return
	_enqueue_request("treasure_participants", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var url = server_url + "/treasure/participants?chestId=" + str(chest_id)
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			treasure_participants_loaded.emit([])
			_complete_request()
	)

func treasure_get_battle_log(chest_id: int, page: int = 1, page_size: int = 10):
	if auth_token == "":
		treasure_battle_log_loaded.emit({})
		return
	_enqueue_request("treasure_battle_log", func():
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
		var url = server_url + "/treasure/battle-log?chestId=%d&page=%d&pageSize=%d" % [chest_id, page, page_size]
		var err = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if err != OK:
			treasure_battle_log_loaded.emit({})
			_complete_request()
	)

func treasure_open(token: String, operation_id: String):
	if auth_token == "":
		treasure_open_failed.emit("未登录")
		return
	if treasure_open_request == null:
		treasure_open_failed.emit("网络未初始化")
		return
	if treasure_open_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:

		treasure_open_failed.emit("藏宝匣正在开启中，请稍候")
		return
	_treasure_open_defer_attempts = 0
	call_deferred("_treasure_open_try_request_deferred", token, operation_id)

func _treasure_open_try_request_deferred(token: String, operation_id: String) -> void :
	if treasure_open_request == null or auth_token == "":
		treasure_open_failed.emit("网络未初始化")
		return
	if treasure_open_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_treasure_open_defer_attempts += 1
		if _treasure_open_defer_attempts > 45:
			_treasure_open_defer_attempts = 0
			treasure_open_failed.emit("开启藏宝匣请求繁忙，请稍后重试")
			return
		call_deferred("_treasure_open_try_request_deferred", token, operation_id)
		return
	_treasure_open_defer_attempts = 0
	var body: = {"token": token, "operationId": operation_id}
	var headers: = _build_headers(true, true)
	var err: = treasure_open_request.request(server_url + "/treasure/chest/open", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		treasure_open_failed.emit("网络请求失败")

func _on_treasure_open_request_completed(result, response_code, _headers, body) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		treasure_open_failed.emit("网络请求失败")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		treasure_open_failed.emit("服务器返回数据格式错误")
		return
	var data = json.data
	if not data is Dictionary:
		treasure_open_failed.emit("服务器返回数据格式错误")
		return
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		treasure_open_failed.emit("当前客户端版本过低，请更新后继续游戏")
		return
	var ok_s: Variant = data.get("success", false)
	var ok_dup: Variant = data.get("duplicate", false)
	var is_ok: bool = (typeof(ok_s) == TYPE_BOOL and ok_s) or (typeof(ok_s) == TYPE_INT and int(ok_s) != 0)
	var is_dup: bool = (typeof(ok_dup) == TYPE_BOOL and ok_dup) or (typeof(ok_dup) == TYPE_INT and int(ok_dup) != 0)
	if response_code == 200 and (is_ok or is_dup):
		treasure_open_success.emit(data)
		return
	var err_msg: = str(data.get("error", "开启失败"))
	treasure_open_failed.emit(err_msg)

func treasure_validate_tokens(tokens: Array) -> void :
	if auth_token == "":
		treasure_tokens_validate_failed.emit("未登录")
		return
	if treasure_token_validate_request == null:
		treasure_tokens_validate_failed.emit("网络未初始化")
		return
	if treasure_token_validate_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		treasure_token_validate_request.cancel_request()
	var payload_tokens: Array = []
	var seen: Dictionary = {}
	for t in tokens:
		var tk: = str(t).strip_edges()
		if tk.is_empty():
			continue
		if seen.has(tk):
			continue
		seen[tk] = true
		payload_tokens.append(tk)
		if payload_tokens.size() >= 200:
			break
	var body: = {"tokens": payload_tokens}
	var headers: = _build_headers(true, true)
	var err: = treasure_token_validate_request.request(
		server_url + "/treasure/chest/validate-tokens", 
		headers, 
		HTTPClient.METHOD_POST, 
		JSON.stringify(body)
	)
	if err != OK:
		treasure_tokens_validate_failed.emit("网络请求失败")

func _on_treasure_token_validate_completed(result, response_code, _headers, body) -> void :
	if result != HTTPRequest.RESULT_SUCCESS:
		treasure_tokens_validate_failed.emit("网络请求失败")
		return
	var json: = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		treasure_tokens_validate_failed.emit("服务器返回数据格式错误")
		return
	var data = json.data
	if not (data is Dictionary):
		treasure_tokens_validate_failed.emit("服务器返回数据格式错误")
		return
	if str(data.get("code", "")) == "FORCE_UPDATE_REQUIRED":
		_emit_force_update(data)
		treasure_tokens_validate_failed.emit("当前客户端版本过低，请更新后继续游戏")
		return
	if response_code == 200 and bool(data.get("success", false)):
		treasure_tokens_validated.emit(data)
		return
	treasure_tokens_validate_failed.emit(str(data.get("error", "校验失败")))

func economy_tower_clear_reward(operation_id: String, floor: int, fight_token: String = "") -> void :
	if auth_token == "":
		economy_result.emit("", "economy_tower_clear", false, {}, "未登录")
		return
	var body = {"operationId": operation_id, "floor": floor}
	var tk: = fight_token.strip_edges()
	if not tk.is_empty():
		body["fightToken"] = tk
	var json = JSON.stringify(body)
	_enqueue_economy_tower_clear_dedicated(json, operation_id)

func economy_tower_sweep_reward(operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_tower_sweep", false, {}, "未登录")
		return
	var tower_sweep_fn: = func():
		var body = {"operationId": operation_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/tower-sweep-reward", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_tower_sweep", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_tower_sweep", tower_sweep_fn, operation_id)

func economy_suit_dungeon_clear_reward(operation_id: String, level: int) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_suit_clear", false, {}, "未登录")
		return
	var suit_clear_fn: = func():
		var body = {"operationId": operation_id, "level": level}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/suit-dungeon-clear-reward", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_suit_clear", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_suit_clear", suit_clear_fn, operation_id)

func economy_suit_dungeon_sweep_reward(operation_id: String, level: int) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_suit_sweep", false, {}, "未登录")
		return
	var suit_sweep_fn: = func():
		var body = {"operationId": operation_id, "level": level}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/suit-dungeon-sweep-reward", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_suit_sweep", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_suit_sweep", suit_sweep_fn, operation_id)

func economy_quest_claim(operation_id: String, quest_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_quest_claim", false, {}, "未登录")
		return
	var quest_claim_fn: = func():
		var body = {"operationId": operation_id, "questId": quest_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/quest-claim", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_quest_claim", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_quest_claim", quest_claim_fn, operation_id)
func send_events_batch(events: Array) -> void :
	if events.is_empty():
		return
	var body = JSON.stringify({"events": events})
	var error = events_batch_request.request(
		server_url + "/api/events/batch", 
		["Content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		body
	)
	if error != OK:
		push_warning("[GameEvents] send_events_batch request error: %d" % error)
		events_batch_request.cancel_request()


func economy_battle_loot(operation_id: String, monsters: Array, map_id: String = "", item_drop: String = "", extras: Dictionary = {}) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_battle_loot", false, {}, "未登录")
		return
	var body = {"operationId": operation_id, "monsters": monsters}
	if map_id != "":
		body["mapId"] = map_id
	if item_drop.strip_edges() != "":
		body["itemDrop"] = item_drop.strip_edges()
	if extras is Dictionary:
		if extras.has("activePetId"):
			body["activePetId"] = str(extras.get("activePetId", ""))
		if extras.has("playerDied"):
			body["playerDied"] = bool(extras.get("playerDied", false))
		if extras.has("petDied"):
			body["petDied"] = bool(extras.get("petDied", false))
		if extras.has("minGrowthThreshold"):
			body["minGrowthThreshold"] = float(extras.get("minGrowthThreshold", 0.0))
		if extras.has("clientPetLevel"):
			body["clientPetLevel"] = int(extras.get("clientPetLevel", 0))
		if extras.has("clientPetExperience"):
			body["clientPetExperience"] = int(extras.get("clientPetExperience", 0))
		if extras.has("batchBattleCount"):
			body["batchBattleCount"] = maxi(1, int(extras.get("batchBattleCount", 1)))
		if extras.has("fightToken"):
			body["fightToken"] = str(extras.get("fightToken", ""))
		var client_progress: Variant = extras.get("clientPetProgress", null)
		if client_progress is Dictionary and not (client_progress as Dictionary).is_empty():
			body["clientPetProgress"] = client_progress
		var cap: Variant = extras.get("captureCandidate", null)
		if cap is Dictionary and not cap.is_empty():
			body["captureCandidate"] = cap
	var json = JSON.stringify(body)
	_enqueue_economy_battle_loot_dedicated(json, operation_id)

func pet_refine_validate(material_instance_ids: Array) -> void :
	if auth_token == "":
		pet_refine_validate_done.emit({"success": false, "error": "未登录"})
		return
	if not _ensure_action_request_ready():
		pet_refine_validate_done.emit({"success": false, "error": "请求通道初始化失败"})
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_refine_validate_done.emit({"success": false, "error": "操作繁忙，请稍后重试"})
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {"materialInstanceIds": material_instance_ids}
	_current_action_type = "pet_refine_validate"
	_last_pet_direct_op = "pet_refine_validate"
	var err = action_request.request(server_url + "/pet/refine/validate", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_refine_validate_done.emit({"success": false, "error": "网络请求失败"})

func pet_roster_sync(operation_id: String, pets_roster: Array, active_pet_id: String, save_revision: int) -> void :
	if auth_token == "":
		pet_roster_sync_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_roster_sync_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_roster_sync_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id, 
		"pets": pets_roster, 
		"activePetId": active_pet_id, 
		"saveRevision": save_revision, 
	}
	_current_action_type = "pet_roster_sync"
	_last_pet_direct_op = "pet_roster_sync"
	var err = action_request.request(server_url + "/pet/roster/sync", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_roster_sync_failed.emit("网络请求失败")

func pet_refine(operation_id: String, material_instance_ids: Array) -> void :
	if auth_token == "":
		pet_refine_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		pet_refine_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		pet_refine_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {"operationId": operation_id, "materialInstanceIds": material_instance_ids}
	_current_action_type = "pet_refine"
	_last_pet_direct_op = "pet_refine"
	var err = action_request.request(server_url + "/pet/refine", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		pet_refine_failed.emit("网络请求失败")

func player_attr_auto_allocate(operation_id: String, client_hint: Dictionary = {}) -> void :
	if auth_token == "":
		player_attr_auto_allocate_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		player_attr_auto_allocate_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		player_attr_auto_allocate_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body: Dictionary = {"operationId": operation_id}
	if client_hint is Dictionary and not client_hint.is_empty():
		if client_hint.has("clientLevel"):
			body["clientLevel"] = int(client_hint.get("clientLevel", 0))
		if client_hint.has("clientExperience"):
			body["clientExperience"] = int(client_hint.get("clientExperience", 0))
		if client_hint.has("clientReincarnation"):
			body["clientReincarnation"] = int(client_hint.get("clientReincarnation", 0))
	_current_action_type = "player_attr_auto_allocate"
	var err = action_request.request(server_url + "/player/attr/auto-allocate", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		player_attr_auto_allocate_failed.emit("网络请求失败")

func player_attr_spend_points(operation_id: String, stat: String, count: int) -> void :
	if auth_token == "":
		player_attr_spend_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		player_attr_spend_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		player_attr_spend_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {"operationId": operation_id, "stat": stat, "count": count}
	_current_action_type = "player_attr_spend_points"
	var err = action_request.request(server_url + "/player/attr/spend-points", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		player_attr_spend_failed.emit("网络请求失败")

func player_talent_allocate(operation_id: String, attack_v: int, defense_v: int, agility_v: int, hp_v: int) -> void :
	if auth_token == "":
		player_talent_allocate_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		player_talent_allocate_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		player_talent_allocate_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id, 
		"attack": attack_v, 
		"defense": defense_v, 
		"agility": agility_v, 
		"hp": hp_v, 
	}
	_current_action_type = "player_talent_allocate"
	var err = action_request.request(server_url + "/player/talent/allocate", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		player_talent_allocate_failed.emit("网络请求失败")

func player_talent_reset(operation_id: String) -> void :
	if auth_token == "":
		player_talent_reset_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		player_talent_reset_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		player_talent_reset_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {"operationId": operation_id}
	_current_action_type = "player_talent_reset"
	var err = action_request.request(server_url + "/player/talent/reset", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		player_talent_reset_failed.emit("网络请求失败")

func player_attr_save_auto_plan(operation_id: String, enabled: bool, plan: Dictionary) -> void :
	if auth_token == "":
		player_attr_plan_failed.emit("未登录")
		return
	if not _ensure_action_request_ready():
		player_attr_plan_failed.emit("请求通道初始化失败")
		return
	if action_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		player_attr_plan_failed.emit("操作繁忙，请稍后重试")
		return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
	var body = {
		"operationId": operation_id, 
		"enabled": enabled, 
		"plan": plan, 
	}
	_current_action_type = "player_attr_auto_plan"
	var err = action_request.request(server_url + "/player/attr/auto-plan", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_current_action_type = ""
		player_attr_plan_failed.emit("网络请求失败")

func pet_grant_starter(operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "pet_grant_starter", false, {}, "未登录")
		return
	var starter_fn: = func():
		var body = {"operationId": operation_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/pet/grant-starter", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "pet_grant_starter", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("pet_grant_starter", starter_fn, operation_id)

func economy_tower_replay_run(floor: int, operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_tower_replay_run", false, {}, "未登录")
		return
	var run_fn: = func():
		var body = {"operationId": operation_id, "floor": floor}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/battle/tower-run", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_tower_replay_run", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_tower_replay_run", run_fn, operation_id)

func economy_wild_replay_run(map_id: String, operation_id: String, player_stance: String = "attack", pet_stance: String = "attack") -> void :
	if auth_token == "":
		economy_result.emit("", "economy_wild_replay_run", false, {}, "未登录")
		return
	var run_fn: = func():
		var stance_player: = "defend" if str(player_stance) == "defend" else "attack"
		var stance_pet: = "defend" if str(pet_stance) == "defend" else "attack"
		if stance_player == "defend" and stance_pet == "defend":
			stance_pet = "attack"
		var body = {
			"operationId": operation_id, 
			"mapId": map_id, 
			"battleStancePlayer": stance_player, 
			"battleStancePet": stance_pet, 
		}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/battle/wild-run", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_wild_replay_run", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_wild_replay_run", run_fn, operation_id)

func economy_wild_replay_abandon(fight_token: String, operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_wild_replay_abandon", false, {}, "未登录")
		return
	var abandon_fn: = func():
		var body = {"operationId": operation_id, "fightToken": fight_token}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/battle/wild-abandon", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_wild_replay_abandon", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_wild_replay_abandon", abandon_fn, operation_id)

func atlas_dungeon_finish(tier: String, operation_id: String, start_operation_id: String, defeated_pet_ids: Array, min_growth_threshold: float = 0.0, waves_cleared: int = 0) -> void :
	if auth_token == "":
		economy_result.emit("", "atlas_dungeon_finish", false, {}, "未登录")
		return
	var finish_fn: = func():
		var body = {
			"tier": tier, 
			"operationId": operation_id, 
			"startOperationId": start_operation_id, 
			"defeatedPetIds": defeated_pet_ids, 
			"minGrowthThreshold": min_growth_threshold, 
			"wavesCleared": maxi(0, waves_cleared), 
		}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/atlas-dungeon/finish", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "atlas_dungeon_finish", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("atlas_dungeon_finish", finish_fn, operation_id)

func economy_offline_gold(operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_offline_gold", false, {}, "未登录")
		return
	var offline_gold_fn: = func():
		var body = {"operationId": operation_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/offline-gold", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_offline_gold", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_offline_gold", offline_gold_fn, operation_id)

func economy_offline_claim(operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_offline_claim", false, {}, "未登录")
		return
	var offline_claim_fn: = func():
		var body = {"operationId": operation_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/offline-claim", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_offline_claim", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_offline_claim", offline_claim_fn, operation_id)

func economy_whitelist_gold(operation_id: String, grant_key: String, amount: int = 0, consume_count: int = 0) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_whitelist_gold", false, {}, "未登录")
		return
	var whitelist_fn: = func():
		var body = {"operationId": operation_id, "grantKey": grant_key}
		if amount > 0:
			body["amount"] = amount
		if consume_count > 0:
			body["consumeCount"] = consume_count
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/whitelist-gold", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_whitelist_gold", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_whitelist_gold", whitelist_fn, operation_id)

func economy_whitelist_item_consume(operation_id: String, consume_key: String, batch_count: int = 1, extras: Dictionary = {}) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_whitelist_item_consume", false, {}, "未登录")
		return
	var consume_fn: = func():
		var body = {"operationId": operation_id, "consumeKey": consume_key}
		var bc: = maxi(1, batch_count)
		body["batchCount"] = bc
		if extras is Dictionary:
			for k in extras.keys():
				body[k] = extras[k]
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/whitelist-item-consume", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_whitelist_item_consume", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_whitelist_item_consume", consume_fn, operation_id)

func economy_xianmo_misc_gold(operation_id: String, amount: int, context: Dictionary = {}) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_xianmo_misc_gold", false, {}, "未登录")
		return
	var xianmo_fn: = func():
		var body = {"operationId": operation_id, "amount": amount}
		if context is Dictionary and not context.is_empty():
			body["context"] = context
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/xianmo-misc-gold", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_xianmo_misc_gold", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_xianmo_misc_gold", xianmo_fn, operation_id)

func economy_pet_refine_gold(operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_pet_refine_gold", false, {}, "未登录")
		return
	var refine_fn: = func():
		var body = {"operationId": operation_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/pet-refine-gold", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_pet_refine_gold", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_pet_refine_gold", refine_fn, operation_id)

func economy_player_switch_character(character_id: int, operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_player_switch_character", false, {}, "未登录")
		return
	var switch_fn: = func():
		var body = {"operationId": operation_id, "characterId": character_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/player/switch-character", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_player_switch_character", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_player_switch_character", switch_fn, operation_id)

func economy_player_name_available(nickname: String, operation_id: String = "") -> void :
	# kind 用 economy_ 前缀：回包走通用的经济结算分支，直接拿到
	# economy_result(request_id, "economy_player_name_available", ok, data, err)
	if auth_token == "":
		economy_result.emit("", "economy_player_name_available", false, {}, "未登录")
		return
	var check_fn: = func():
		var body = {"nickname": nickname}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/player/name-available", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_player_name_available", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_player_name_available", check_fn, operation_id)

func economy_player_create_character(nickname: String, character_id: int, operation_id: String) -> void :
	if auth_token == "":
		economy_result.emit("", "economy_player_create_character", false, {}, "未登录")
		return
	var create_fn: = func():
		var body = {"operationId": operation_id, "nickname": nickname, "characterId": character_id}
		var json = JSON.stringify(body)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/player/create-character", headers, HTTPClient.METHOD_POST, json)
		if err != OK:
			economy_result.emit(operation_id, "economy_player_create_character", false, {}, "网络请求失败")
			_complete_request()
	_enqueue_request("economy_player_create_character", create_fn, operation_id)

func fetch_drop_config() -> void :
	var fn: = func():
		var headers = ["Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/economy/drop-config", headers, HTTPClient.METHOD_GET)
		if err != OK:
			drop_config_loaded.emit({})
	_enqueue_request("drop_config", fn)

func fetch_festival_runtime_config() -> void :
	var fn: = func():
		var headers = ["Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/festival/runtime-config", headers, HTTPClient.METHOD_GET)
		if err != OK:
			festival_runtime_config_loaded.emit({})
	_enqueue_request("festival_runtime_config", fn)

func fetch_gameplay_runtime_config() -> void :
	var fn: = func():
		var headers = ["Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		var err = http_request.request(server_url + "/gameplay/runtime-config", headers, HTTPClient.METHOD_GET)
		if err != OK:
			gameplay_runtime_config_loaded.emit({})
	_enqueue_request("gameplay_runtime_config", fn)

func upload_save(player_data: Dictionary, pets_data: Variant, inventory_data: Dictionary, equipment_data: Dictionary = {}, martial_arts_data: Dictionary = {}, crafting_data: Dictionary = {}, game_settings: Dictionary = {}, pet_collection_data: Dictionary = {}, pet_equipment_data: Dictionary = {}, suit_data: Dictionary = {}, quest_data: Dictionary = {}, compact_mode: bool = false):
	print("[Network] upload_save 被调用")
	print("[Network] auth_token = ", auth_token)
	var normalized_game_settings: = game_settings.duplicate(true)
	var op_id: = String(normalized_game_settings.get("operationId", "")).strip_edges()
	if op_id == "":
		op_id = String(normalized_game_settings.get("operation_id", "")).strip_edges()
	if op_id == "":
		op_id = "%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
	normalized_game_settings["operationId"] = op_id

	normalized_game_settings["operation_id"] = op_id

	var save_data = {
		"schema_version": SAVE_SCHEMA_VERSION, 
		"playerData": player_data, 
		"petsData": pets_data, 
		"inventoryData": inventory_data, 
		"equipmentData": equipment_data, 
		"gameSettings": normalized_game_settings, 
	}

	save_data["martialArtsData"] = martial_arts_data

	save_data["petEquipmentData"] = pet_equipment_data


	save_data["questData"] = quest_data

	save_data["petCollectionData"] = pet_collection_data
	if not compact_mode:
		save_data["craftingData"] = crafting_data
		save_data["suitData"] = suit_data

	var cache_result = _save_to_local_cache(save_data)
	if bool(cache_result.get("ok", false)):
		_pending_upload_path = String(cache_result.get("path", ""))
		_pending_upload_timestamp = int(cache_result.get("timestamp", 0))

	if auth_token == "":
		print("[Network] auth_token 为空，存档已保存到本地，登录后重试")
		call_deferred("emit_signal", "save_uploaded", false)
		return

	_pending_upload_data = save_data
	_upload_retry_count = 0
	_is_retrying = true
	_retry_timer = 0.0
	_do_upload_save()

func _do_upload_save():
	if _pending_upload_data.is_empty() or auth_token == "":
		return

	_upload_retry_count += 1
	print("[Network] 上传存档尝试 %d/%d" % [_upload_retry_count, MAX_RETRY_COUNT])
	upload_retrying.emit(_upload_retry_count, MAX_RETRY_COUNT)

	_enqueue_request("upload_save", func():
		var json = JSON.stringify(_pending_upload_data)
		var payload_bytes = json.to_utf8_buffer().size()
		var compact_mode = false
		if _pending_upload_data.has("gameSettings") and _pending_upload_data.gameSettings is Dictionary:
			# gameSettings 里的值来自本地存档，可能是历史脏类型；裸 bool() 遇到
			# Dictionary/Array 会抛 "Nonexistent 'bool' constructor"，把整个上传流程打断。
			compact_mode = Player.coerce_bool(_pending_upload_data.gameSettings.get("compact_mode", false), false)
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token, "X-Client-Version: " + client_version_header]
		print("[Network] 发送上传存档请求... compact=%s payload=%dB" % [str(compact_mode), payload_bytes])
		var err = http_request.request(server_url + "/save/upload", headers, HTTPClient.METHOD_POST, json)
		print("[Network] 请求错误码: ", err)
		if err != OK:
			print("[Network] 请求失败，将重试")
			_handle_upload_failure()

			_complete_request()
	)

func _handle_upload_failure():
	if _discard_inflight_upload_callback:
		return
	if _upload_retry_count >= MAX_RETRY_COUNT:
		print("[Network] 达到最大重试次数，存档保留在本地")
		_is_retrying = false
		save_uploaded.emit(false)
		return

	_is_retrying = true
	_retry_timer = 0.0
	print("[Network] 将在 %d 秒后重试" % RETRY_DELAYS[min(_upload_retry_count, RETRY_DELAYS.size() - 1)])

func _dispatch_brother_tower_response(current_type: String, data: Dictionary) -> void :
	var err_msg: = str(data.get("error", ""))
	match current_type:
		"brother_tower_list":
			if data.get("success", true):
				brother_tower_list_loaded.emit(data)
			else:
				brother_tower_list_failed.emit(err_msg if not err_msg.is_empty() else "列表加载失败")
		"brother_tower_poll":
			if data.get("success", true):
				brother_tower_poll_loaded.emit(data)
				var list_payload: Dictionary = {}
				if data.has("rooms"):
					list_payload["rooms"] = data.get("rooms")
				if data.has("myRoom"):
					list_payload["myRoom"] = data.get("myRoom")
				elif list_payload.has("rooms"):
					list_payload["myRoom"] = null
				if data.has("myPendingApplicationRoomIds"):
					list_payload["myPendingApplicationRoomIds"] = data.get("myPendingApplicationRoomIds")
				if not list_payload.is_empty():
					list_payload["success"] = true
					brother_tower_list_loaded.emit(list_payload)
				var status_payload = data.get("status", {})
				if status_payload is Dictionary and not status_payload.is_empty():
					brother_tower_status_loaded.emit(status_payload)
				var poll_sess = data.get("session", {})
				if poll_sess is Dictionary and not poll_sess.is_empty():
					brother_tower_session_loaded.emit({"success": true, "session": poll_sess})
					if GameManager.instance:
						var poll_scope: = _last_brother_tower_poll_scope
						var poll_status: = str(poll_sess.get("status", ""))
						if poll_scope != "lobby" and poll_status in ["in_battle", "waiting_reconnect", "cleared"]:
							var gm = GameManager.instance
							if poll_status == "cleared" and gm.brother_tower_role == "viewer":
								gm._settle_viewer_on_session_cleared(poll_sess, "poll")
							else:
								gm._begin_brother_tower_session_polled(poll_sess)
			else:
				brother_tower_poll_failed.emit(err_msg if not err_msg.is_empty() else "刷新失败")
		"brother_tower_status":
			if data.get("success", true):
				brother_tower_status_loaded.emit(data)
		"brother_tower_create":
			if data.get("success", false):
				brother_tower_create_success.emit(data)
			else:
				brother_tower_create_failed.emit(err_msg if not err_msg.is_empty() else "创建失败")
		"brother_tower_join":
			if data.get("success", false):
				brother_tower_join_success.emit(data)
			else:
				brother_tower_join_failed.emit(err_msg if not err_msg.is_empty() else "加入失败")
		"brother_tower_application_decide":
			if data.get("success", false):
				brother_tower_application_decide_success.emit(data)
			else:
				brother_tower_application_decide_failed.emit(err_msg if not err_msg.is_empty() else "处理申请失败")
		"brother_tower_ready":
			if data.get("success", false):
				brother_tower_ready_success.emit(data)
			else:
				brother_tower_ready_failed.emit(err_msg if not err_msg.is_empty() else "准备失败")
		"brother_tower_pin_snapshot":
			if data.get("success", false):
				brother_tower_pin_snapshot_success.emit(data)
			else:
				brother_tower_pin_snapshot_failed.emit(err_msg if not err_msg.is_empty() else "更新出战快照失败")
		"brother_tower_start":
			if data.get("success", false):
				brother_tower_start_success.emit(data)
			else:
				brother_tower_start_failed.emit(err_msg if not err_msg.is_empty() else "开始失败")
		"brother_tower_wave_cleared":
			if data.get("success", false):
				brother_tower_wave_cleared_success.emit(data)
				if GameManager.instance:
					GameManager.instance.call_deferred("_begin_brother_tower_wave_cleared", data)
			else:
				brother_tower_wave_cleared_failed.emit(err_msg)
				if GameManager.instance and GameManager.instance.is_brother_tower_battle:
					GameManager.instance._end_brother_tower_failed(err_msg if not err_msg.is_empty() else "挑战失败")
		"brother_tower_session":
			if data.get("success", true):
				brother_tower_session_loaded.emit(data)
				var sess = data.get("session", {})
				if GameManager.instance and sess is Dictionary and not sess.is_empty():
					var gm = GameManager.instance
					var sess_status: = str(sess.get("status", ""))
					if sess_status == "cleared" and gm.brother_tower_role == "viewer":
						gm._settle_viewer_on_session_cleared(sess, "session")
					else:
						gm._begin_brother_tower_session_polled(sess)
		"brother_tower_complete":
			if data.get("success", false):
				if GameManager.instance and GameManager.instance.player:
					var fg: = int(data.get("friendshipGain", 0))
					if fg > 0:
						GameManager.instance.player.friendship_points += fg
				brother_tower_complete_success.emit(data)
			else:
				brother_tower_complete_failed.emit(err_msg)
		"brother_tower_heartbeat":
			if data.get("success", true):
				var hb_sess = data.get("session")
				if GameManager.instance and hb_sess is Dictionary:
					var hb_status: = str(hb_sess.get("status", ""))
					var gm = GameManager.instance
					if hb_status == "cleared" and gm.brother_tower_role == "viewer":
						gm._settle_viewer_on_session_cleared(hb_sess, "heartbeat")
					elif hb_status == "failed" and gm.is_brother_tower_battle:
						var hb_fr: = str(hb_sess.get("fail_reason", hb_sess.get("failReason", "")))
						if hb_fr == "forfeit":
							gm._end_brother_tower_failed("队友已退出，挑战失败")
						else:
							gm._end_brother_tower_failed("挑战失败")
					elif gm.is_brother_tower_battle and hb_status in ["in_battle", "waiting_reconnect"]:

						if gm.brother_tower_viewer_wave_pending or gm.brother_tower_waiting_reconnect:
							gm._begin_brother_tower_session_polled(hb_sess)
		"brother_tower_leave":
			if data.get("success", false):
				brother_tower_leave_success.emit(data)
			else:
				brother_tower_leave_failed.emit(err_msg if not err_msg.is_empty() else "退出失败")
		"brother_tower_disband":
			if data.get("success", false):
				brother_tower_disband_success.emit(data)
			else:
				brother_tower_disband_failed.emit(err_msg if not err_msg.is_empty() else "解散失败")
		"shengsi_tower_overview":
			if data.get("success", true):
				shengsi_tower_overview_loaded.emit(data)
			else:
				shengsi_tower_overview_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_floor":
			if data.get("success", true):
				shengsi_tower_floor_loaded.emit(data)
			else:
				shengsi_tower_floor_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_feed":
			if data.get("success", true):
				shengsi_tower_feed_loaded.emit(data)
			else:
				shengsi_tower_feed_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_room_list":
			if data.get("success", true):
				shengsi_tower_room_list_loaded.emit(data)
			else:
				shengsi_tower_room_list_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_matchup":
			if data.get("success", true):
				shengsi_tower_matchup_loaded.emit(data)
			else:
				shengsi_tower_matchup_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_my_battles":
			if data.get("success", true):
				shengsi_tower_my_battles_loaded.emit(data)
			else:
				shengsi_tower_my_battles_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_floor_battles":
			if data.get("success", true):
				shengsi_tower_floor_battles_loaded.emit(data)
			else:
				shengsi_tower_floor_battles_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_match":
			if data.get("success", true):
				shengsi_tower_match_loaded.emit(data)
			else:
				shengsi_tower_match_failed.emit(err_msg if not err_msg.is_empty() else "加载失败")
		"shengsi_tower_room_create":
			if data.get("success", false):
				shengsi_tower_action_success.emit("room_create", data)
			else:
				shengsi_tower_action_failed.emit("room_create", err_msg if not err_msg.is_empty() else "创建失败")
		"shengsi_tower_room_join":
			if data.get("success", false):
				shengsi_tower_action_success.emit("room_join", data)
			else:
				shengsi_tower_action_failed.emit("room_join", err_msg if not err_msg.is_empty() else "加入失败")
		"shengsi_tower_room_leave":
			if data.get("success", false):
				shengsi_tower_action_success.emit("room_leave", data)
			else:
				shengsi_tower_action_failed.emit("room_leave", err_msg if not err_msg.is_empty() else "退出失败")
		"shengsi_tower_room_disband":
			if data.get("success", false):
				shengsi_tower_action_success.emit("room_disband", data)
			else:
				shengsi_tower_action_failed.emit("room_disband", err_msg if not err_msg.is_empty() else "解散失败")
		"shengsi_tower_room_heartbeat":
			pass
		"shengsi_tower_register":
			if data.get("success", false):
				shengsi_tower_action_success.emit("register", data)
			else:
				shengsi_tower_action_failed.emit("register", err_msg if not err_msg.is_empty() else "报名失败")
		"shengsi_tower_unregister":
			if data.get("success", false):
				shengsi_tower_action_success.emit("unregister", data)
			else:
				shengsi_tower_action_failed.emit("unregister", err_msg if not err_msg.is_empty() else "取消失败")
		"shengsi_tower_stance":
			if data.get("success", false):
				shengsi_tower_action_success.emit("stance", data)
			else:
				shengsi_tower_action_failed.emit("stance", err_msg if not err_msg.is_empty() else "策略失败")
		"shengsi_tower_ready":
			if data.get("success", false):
				shengsi_tower_action_success.emit("ready", data)
			else:
				shengsi_tower_action_failed.emit("ready", err_msg if not err_msg.is_empty() else "就绪失败")
		"brother_tower_forfeit":
			pass
		"brother_tower_battle_events_push":
			_dispatch_bt_push_result(data)
		"brother_tower_battle_events_fetch":
			_dispatch_bt_fetch_result(data)

func _handle_upload_success():
	print("[Network] 存档上传成功，清理本地缓存")
	_is_retrying = false
	var success_ts = _pending_upload_timestamp
	if success_ts <= 0 and _pending_upload_data.has("playerData") and _pending_upload_data.playerData is Dictionary:
		success_ts = int(_pending_upload_data.playerData.get("timestamp", 0))
	var success_path = _pending_upload_path
	_pending_upload_data = {}
	_pending_upload_path = ""
	_pending_upload_timestamp = 0
	_upload_retry_count = 0
	_cleanup_confirmed_pending(success_ts, success_path)


func prepare_world_boss_channels() -> void :
	if _world_boss_http:
		_world_boss_http.prepare_channels()


func request_world_boss_status() -> Dictionary:
	if _world_boss_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _world_boss_http.fetch_status()


func request_world_boss_ranking(limit: int = 100) -> Dictionary:
	if _world_boss_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _world_boss_http.fetch_ranking(limit)


func request_world_boss_battle_start() -> Dictionary:
	if _world_boss_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _world_boss_http.start_battle()


func request_world_boss_battle_report(battle_token: String, damage: int, pet_snapshot: Dictionary) -> Dictionary:
	if _world_boss_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _world_boss_http.report_damage(battle_token, damage, pet_snapshot)



func prepare_arena_channels() -> void :
	if _arena_http:
		_arena_http.prepare_channels()


func request_arena_status() -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.fetch_status()


func request_arena_ranking(limit: int = 100) -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.fetch_ranking(limit)


func request_arena_mirror_info() -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.fetch_mirror()


func request_arena_mirror_update() -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.update_mirror()


func request_arena_match_start() -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.start_match()


func request_arena_challenge_start(battle_token: String) -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.start_challenge(battle_token)


func request_arena_challenge_confirm(battle_token: String, operation_id: String = "") -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.confirm_challenge(battle_token, operation_id)


func request_arena_challenge_history(limit: int = 20) -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.fetch_challenge_history(limit)


func request_arena_shop_items() -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.fetch_shop_items()


func request_arena_shop_buy(item_id: String, operation_id: String = "", quantity: int = 1) -> Dictionary:
	if _arena_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _arena_http.buy_shop_item(item_id, operation_id, quantity)


func arena_get_titles() -> void :
	_arena_get_titles_async()


func _arena_get_titles_async() -> void :
	if _arena_http == null:
		arena_titles_loaded.emit([])
		return
	var res: Dictionary = await _arena_http.fetch_titles()
	var titles: Array = res.get("titles", []) if res.get("titles") is Array else []
	arena_titles_loaded.emit(titles)


func arena_activate_title(title_id: Variant) -> void :
	_arena_activate_title_async(title_id)


func _arena_activate_title_async(title_id: Variant) -> void :
	if _arena_http == null:
		arena_title_activated.emit({"success": false})
		return
	var res: Dictionary = await _arena_http.activate_title(title_id)
	if res.is_empty():
		arena_title_activated.emit({"success": false})
	else:
		arena_title_activated.emit(res)



func prepare_pet_raise_race_channels() -> void :
	if _pet_raise_race_http:
		_pet_raise_race_http.prepare_channels()


func request_pet_raise_race_status() -> Dictionary:
	if _pet_raise_race_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _pet_raise_race_http.fetch_status()


func request_pet_raise_race_ranking(limit: int = 100) -> Dictionary:
	if _pet_raise_race_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _pet_raise_race_http.fetch_ranking(limit)


func request_pet_raise_race_submit(pet_id: String, operation_id: String = "") -> Dictionary:
	if _pet_raise_race_http == null:
		return {"ok": false, "error": "网络未初始化"}
	return await _pet_raise_race_http.submit_pet(pet_id, operation_id)
