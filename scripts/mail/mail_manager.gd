extends Node
class_name MailManager

const GameData = preload("res://scripts/game_data.gd")

static var instance: MailManager = null

signal mail_list_updated(mails: Array[MailData])
signal unread_count_changed(count: int)
signal new_mail_received(mail: MailData)
signal attachment_claimed_success(mail_id: int, attachments: Dictionary)

signal all_attachments_claimed_success(claimed_list: Array, partial_warning: String)
signal attachment_claim_failed(error: String)
signal claimed_mails_deleted(deleted_count: int)
signal mail_deleted(mail_id: int, server_deleted_count: int)
signal error_occurred(error: String)
signal pet_overflow_mail_sent(success: bool, message: String)


var _mails: Array[MailData] = []


var unread_count: int = 0:
	get:
		return unread_count
	set(value):
		if unread_count != value:
			unread_count = value
			unread_count_changed.emit(value)


var _api: MailAPI


var _refresh_timer: Timer


const REFRESH_INTERVAL: float = 60.0


const EXPIRE_CHECK_INTERVAL: float = 300.0


var _auth_token: String = ""


var _expire_check_timer: Timer


var _pending_delete_mail_id: int = 0

var _pending_finalize_single: Dictionary = {}

var _pending_finalize_batch: Array = []

var _pending_finalize_warning: String = ""

var _pending_claim_all_local_claimed: Array = []
var _pending_claim_all_local_warning: String = ""

var _pending_finalize_mail_ids: Array[int] = []
const PENDING_FINALIZE_CACHE_PATH: = "user://mail_pending_finalize.cfg"
const LOCAL_MAIL_CACHE_PATH: = "user://local_mails_cache.cfg"
const MSG_PET_ROSTER_FULL_FOR_MAIL: = "宠物栏已满，无法领取邮件中的宠物。请先腾出主战栏空位（可将不用的宠物放入宠物袋）后再试。"
const MSG_SEALED_SUIT_CLAIM_SYNC_FAILED: = "领取确认失败，封印套装未同步到背包，请稍后重试"

func _ready():
	instance = self


	_api = MailAPI.new()
	_api.setup_http_request(self)


	_api.mail_list_received.connect(_on_mail_list_received)
	_api.mail_detail_received.connect(_on_mail_detail_received)
	_api.attachment_claimed.connect(_on_attachment_claimed)
	_api.all_attachments_claimed.connect(_on_all_attachments_claimed)
	_api.unread_count_received.connect(_on_unread_count_received)
	_api.claimed_mails_deleted.connect(_on_claimed_mails_deleted)
	_api.mail_delete_done.connect(_on_mail_delete_done)
	_api.error_occurred.connect(_on_api_error)
	_api.finalize_claims_done.connect(_on_finalize_claims_done)


	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = REFRESH_INTERVAL
	_refresh_timer.timeout.connect(_on_refresh_timer)
	add_child(_refresh_timer)


	_expire_check_timer = Timer.new()
	_expire_check_timer.wait_time = EXPIRE_CHECK_INTERVAL
	_expire_check_timer.timeout.connect(_on_expire_check_timer)
	add_child(_expire_check_timer)

	_load_pending_finalize_cache()
	_load_local_mail_cache()
	call_deferred("_retry_pending_finalize_claims")
	call_deferred("_connect_network_mail_list_signal")

func _connect_network_mail_list_signal() -> void :
	var gm = GameManager.instance
	if gm == null or gm.network == null:
		return
	if gm.network.mail_list_via_network_response.is_connected(_on_mail_list_via_network):
		return
	gm.network.mail_list_via_network_response.connect(_on_mail_list_via_network)

func _on_mail_list_via_network(result: int, response_code: int, body: PackedByteArray) -> void :
	if _api:
		_api.process_mail_list_http_response(result, response_code, body, PackedStringArray())


func get_mails() -> Array[MailData]:
	return _mails.duplicate()


func get_mail_by_id(mail_id: int) -> MailData:
	for mail in _mails:
		if mail.id == mail_id:
			return mail
	return null


func get_unread_mails() -> Array[MailData]:
	var result: Array[MailData] = []
	for mail in _mails:
		if not mail.is_read:
			result.append(mail)
	return result


func get_mails_with_attachments() -> Array[MailData]:
	var result: Array[MailData] = []
	for mail in _mails:
		if mail.has_attachments():
			result.append(mail)
	return result


func get_claimable_mails() -> Array[MailData]:
	var result: Array[MailData] = []
	for mail in _mails:
		if (
			mail.has_attachments()
			and not mail.is_claimed
			and not _is_mail_pending_finalize(mail.id)
			and mail.get_treasure_token().is_empty()
		):
			result.append(mail)
	return result




func refresh_mail_list() -> void :
	var token = _get_auth_token()
	if token.is_empty():
		error_occurred.emit("未登录")
		return
	_sync_mail_api_base_from_network()
	var gm = GameManager.instance
	if gm != null and gm.network != null:
		_connect_network_mail_list_signal()
		gm.network.request_mail_list()
		return
	_api.fetch_mail_list(token)


func fetch_mail_detail(mail_id: int) -> void :
	var token = _get_auth_token()
	if token.is_empty():
		error_occurred.emit("未登录")
		return
	_sync_mail_api_base_from_network()
	_api.fetch_mail_detail(mail_id, token)


func claim_attachment(mail_id: int) -> void :
	_reconcile_pending_finalize_ids_with_mail_list()
	if _is_mail_pending_finalize(mail_id):
		_retry_pending_finalize_claims()
		attachment_claim_failed.emit("该邮件正在确认领取中，请稍后再试")
		return
	var token = _get_auth_token()
	if token.is_empty():
		error_occurred.emit("未登录")
		return

	var mail = get_mail_by_id(mail_id)
	if mail == null:
		attachment_claim_failed.emit("邮件不存在")
		return

	if not mail.has_attachments():
		attachment_claim_failed.emit("该邮件没有附件")
		return

	if mail.is_claimed:
		attachment_claim_failed.emit("附件已领取")
		return


	var space_check = _check_space_for_attachments(mail.attachments)
	if not space_check.success:
		attachment_claim_failed.emit(space_check.reason)
		return


	if mail.id < 0:
		var local_apply_result = _add_attachments_to_game(mail.attachments)
		if not bool(local_apply_result.get("success", false)):
			attachment_claim_failed.emit("附件添加失败：\n%s" % _format_attachment_failures(local_apply_result.get("failures", [])))
			return
		mail.is_claimed = true
		_save_local_mail_cache()
		attachment_claimed_success.emit(mail_id, mail.attachments)
		mail_list_updated.emit(_mails)
		_trigger_post_claim_cloud_sync([{"mail_id": mail_id, "attachments": mail.attachments.duplicate(true)}])
		return

	_sync_mail_api_base_from_network()
	_api.claim_attachment(mail_id, token)


func claim_all_attachments() -> void :
	_reconcile_pending_finalize_ids_with_mail_list()
	var cum = _check_cumulative_space_for_claim_all()
	if not cum.success:
		attachment_claim_failed.emit(cum.reason)
		return
	var claimable = get_claimable_mails()
	if claimable.is_empty():
		attachment_claim_failed.emit("没有可领取的邮件")
		return
	var local_mails: Array[MailData] = []
	var server_mails: Array[MailData] = []
	for mail in claimable:
		if mail.id < 0:
			local_mails.append(mail)
		else:
			server_mails.append(mail)

	var local_result: = _claim_local_mails_for_claim_all(local_mails)
	_pending_claim_all_local_claimed = local_result.get("claimed", [])
	_pending_claim_all_local_warning = str(local_result.get("warning", ""))

	if server_mails.is_empty():
		var local_warn: = _pending_claim_all_local_warning
		var local_claimed: = _pending_claim_all_local_claimed.duplicate()
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
		if local_claimed.is_empty():
			if local_warn.is_empty():
				local_warn = "没有可领取的邮件"
			attachment_claim_failed.emit(local_warn)
			return
		_trigger_post_claim_cloud_sync(local_claimed.duplicate(true))
		all_attachments_claimed_success.emit(local_claimed, local_warn)
		return

	var token = _get_auth_token()
	if token.is_empty():

		var fallback_claimed: = _pending_claim_all_local_claimed.duplicate()
		var fallback_warn: = _pending_claim_all_local_warning
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
		if not fallback_claimed.is_empty():
			var append_warn = "服务端邮件需登录后再领取。"
			var merged_warn = append_warn if fallback_warn.is_empty() else (fallback_warn + "\n" + append_warn)
			all_attachments_claimed_success.emit(fallback_claimed, merged_warn)
		else:
			attachment_claim_failed.emit("未登录")
		return
	_sync_mail_api_base_from_network()
	_api.claim_all_attachments(token)


func request_pet_overflow_mail(pet_payload: Dictionary, operation_id: String) -> bool:
	var token = _get_auth_token()
	if token.is_empty():
		return false
	if _api == null:
		return false
	_sync_mail_api_base_from_network()
	var on_done: Callable
	on_done = func(success: bool, error_message: String, _payload: Dictionary):
		if _api and _api.pet_overflow_mail_done.is_connected(on_done):
			_api.pet_overflow_mail_done.disconnect(on_done)
		if success:
			refresh_mail_list()
			pet_overflow_mail_sent.emit(true, "")
		else:
			var msg = error_message if not error_message.is_empty() else "宠物补发邮件失败"
			pet_overflow_mail_sent.emit(false, msg)
			error_occurred.emit(msg)
	_api.pet_overflow_mail_done.connect(on_done, CONNECT_ONE_SHOT)
	_api.send_pet_overflow_mail(token, pet_payload, operation_id)
	return true


func _mail_claim_requires_full_authority_upload(claimed_entries: Array) -> bool:
	for entry in claimed_entries:
		if not (entry is Dictionary):
			continue
		var attachments: Dictionary = entry.get("attachments", {}) if entry.has("attachments") else {}
		if _attachments_require_full_authority_upload(attachments):
			return true
	return false

func _attachments_require_full_authority_upload(attachments: Dictionary) -> bool:
	if not (attachments is Dictionary):
		return false
	for item_data in attachments.get("items", []):
		if item_data is Dictionary:
			var item_type: = str(item_data.get("type", ""))
			if item_type == "sealed_suit":
				return true
			var item_name: = str(item_data.get("name", item_data.get("id", item_data.get("item_id", ""))))
			var suit_probe: = _try_add_suit_equipment_by_display_name(item_name, 0)
			if bool(suit_probe.get("handled", false)):
				return true
		elif item_data is String:
			var suit_probe_s: = _try_add_suit_equipment_by_display_name(str(item_data), 0)
			if bool(suit_probe_s.get("handled", false)):
				return true
	if attachments.has("type"):
		var attachment_type: = str(attachments.get("type", ""))
		if attachment_type == "sealed_suit":
			return true
		if attachment_type == "item":
			var flat_item_name: = str(attachments.get("item_id", attachments.get("name", "")))
			var flat_probe: = _try_add_suit_equipment_by_display_name(flat_item_name, 0)
			if bool(flat_probe.get("handled", false)):
				return true
	return false



func _count_sealed_suits_in_attachments(attachments: Dictionary) -> int:
	var total: = 0
	if attachments.is_empty():
		return 0
	for item_data in attachments.get("items", []):
		if item_data is Dictionary:
			var item_type = str(item_data.get("type", ""))
			if item_type == "sealed_suit":
				total += max(1, int(item_data.get("count", item_data.get("quantity", 1))))
	if str(attachments.get("type", "")) == "sealed_suit":
		total += max(1, int(attachments.get("quantity", attachments.get("count", 1))))
	return total


func _count_sealed_suits_in_claimed_entries(claimed_entries: Array) -> int:
	var total: = 0
	for entry in claimed_entries:
		if entry is Dictionary:
			var att: Variant = entry.get("attachments", {})
			if att is Dictionary:
				total += _count_sealed_suits_in_attachments(att as Dictionary)
	return total


func _count_sealed_suits_in_save_data(save_data: Dictionary) -> int:
	if not save_data.has("inventoryData"):
		return 0
	var inv: Variant = save_data.get("inventoryData", {})
	if not inv is Dictionary:
		return 0
	var items: Variant = (inv as Dictionary).get("items", [])
	if not items is Array:
		return 0
	var n: = 0
	for row in items:
		if row is Dictionary and str((row as Dictionary).get("item_type", "")) == "sealed_suit":
			n += 1
	return n

func _save_data_contains_sealed_suits(save_data: Dictionary) -> bool:
	if not save_data.has("inventoryData"):
		return false
	var inv: Variant = save_data.get("inventoryData", {})
	if not inv is Dictionary:
		return false
	var items: Variant = (inv as Dictionary).get("items", [])
	if not items is Array:
		return false
	for row in items:
		if row is Dictionary and str((row as Dictionary).get("item_type", "")) == "sealed_suit":
			return true
	return false


func _claim_local_mails_for_claim_all(local_mails: Array[MailData]) -> Dictionary:
	var out: = {"claimed": [], "warning": ""}
	if local_mails.is_empty():
		return out
	var claimed: Array = []
	var failed_lines: Array[String] = []
	for mail in local_mails:
		if mail == null or not mail.has_attachments() or mail.is_claimed:
			continue
		var apply_result = _add_attachments_to_game(mail.attachments, true)
		if bool(apply_result.get("success", false)):
			mail.is_claimed = true
			mail.is_read = true
			claimed.append({"mail_id": mail.id, "attachments": mail.attachments.duplicate()})
		else:
			var fail_msg: = _format_attachment_failures(apply_result.get("failures", []))
			failed_lines.append("本地邮件#%d: %s" % [mail.id, fail_msg])
	if not claimed.is_empty():
		_save_local_mail_cache()
		mail_list_updated.emit(_mails)
		var unread: = 0
		for m in _mails:
			if not m.is_read:
				unread += 1
		unread_count = unread
	if not failed_lines.is_empty():
		out["warning"] = "部分本地邮件领取失败：\n%s" % "\n".join(failed_lines)
	out["claimed"] = claimed
	return out


func delete_claimed_mails() -> void :
	var token = _get_auth_token()
	if token.is_empty():
		error_occurred.emit("未登录")
		return
	_sync_mail_api_base_from_network()
	_api.delete_claimed_mails(token)


func delete_mail_by_id(mail_id: int) -> void :
	if mail_id < 0:
		_remove_local_mail(mail_id)
		return
	var token: = _get_auth_token()
	if token.is_empty():
		error_occurred.emit("未登录")
		return
	_sync_mail_api_base_from_network()
	_pending_delete_mail_id = mail_id
	_api.delete_mails_by_ids([mail_id], token)

func _remove_local_mail(mail_id: int) -> void :
	var idx: = -1
	for i in range(_mails.size()):
		if _mails[i].id == mail_id:
			idx = i
			break
	if idx < 0:
		error_occurred.emit("邮件不存在")
		return
	_mails.remove_at(idx)
	_save_local_mail_cache()
	if mail_id > 0:
		_clear_pending_finalize_ids([mail_id])
	mail_list_updated.emit(_mails)
	var count: = 0
	for m in _mails:
		if not m.is_read:
			count += 1
	unread_count = count
	mail_deleted.emit(mail_id, 1)


func refresh_unread_count() -> void :
	var token = _get_auth_token()
	if token.is_empty():
		return
	_sync_mail_api_base_from_network()
	_api.fetch_unread_count(token)


func start_auto_refresh() -> void :
	_refresh_timer.start()
	refresh_mail_list()
	refresh_unread_count()
	start_expire_check()


func stop_auto_refresh() -> void :
	_refresh_timer.stop()
	stop_expire_check()



func _on_mail_list_received(mails: Array) -> void :

	var local_mails = []
	for mail in _mails:
		if mail.id < 0:
			if not mail.is_expired():
				local_mails.append(mail)

	var valid_mails: Array[MailData] = []
	for mail in mails:
		if mail is MailData and not mail.is_expired():
			valid_mails.append(mail)

	_mails = valid_mails
	for local_mail in local_mails:
		_mails.insert(0, local_mail)
	_reconcile_pending_finalize_ids_with_mail_list()
	_save_local_mail_cache()

	mail_list_updated.emit(_mails)

	var count = 0
	for mail in _mails:
		if not mail.is_read:
			count += 1
	unread_count = count

func _on_mail_detail_received(mail: MailData) -> void :

	for i in range(_mails.size()):
		if _mails[i].id == mail.id:
			_mails[i] = mail
			break

	mail_list_updated.emit(_mails)


	var count = 0
	for m in _mails:
		if not m.is_read:
			count += 1
	unread_count = count

func _on_attachment_claimed(mail_id: int, attachments: Dictionary) -> void :

	_pending_finalize_batch = []
	_pending_finalize_warning = ""
	var apply_result = _add_attachments_to_game(attachments, true, true, true)
	var had_local_apply: = bool(apply_result.get("local_inventory_touched", false))
	if not bool(apply_result.get("success", false)):
		var fail_message = _format_attachment_failures(apply_result.get("failures", []))
		attachment_claim_failed.emit("附件添加失败：\n%s" % fail_message)
		return
	var token = _get_auth_token()
	if token.is_empty():
		attachment_claim_failed.emit("会话已过期，请重新登录")
		return
	_pending_finalize_single = {"mail_id": mail_id, "attachments": attachments.duplicate(), "had_local_apply": had_local_apply}
	_set_pending_finalize_ids([mail_id])
	_sync_mail_api_base_from_network()
	_api.finalize_claims([mail_id], token, _build_mail_finalize_operation_id())

func _on_all_attachments_claimed(claimed_list: Array) -> void :
	if claimed_list.is_empty():

		refresh_mail_list()
		return
	_pending_finalize_single = {}
	_pending_finalize_warning = ""
	var finalize_batch: Array = []
	var failed_entries: Array = []
	for item in claimed_list:
		var attachments = item.get("attachments", {})
		var apply_result = _add_attachments_to_game(attachments, true, true, true)
		if bool(apply_result.get("success", false)):
			var batch_item = item.duplicate() if item is Dictionary else item
			if batch_item is Dictionary:
				batch_item["had_local_apply"] = bool(apply_result.get("local_inventory_touched", false))
			finalize_batch.append(batch_item)
		else:
			failed_entries.append({
				"mail_id": int(item.get("mail_id", 0)), 
				"failures": apply_result.get("failures", [])
			})
	if finalize_batch.is_empty():
		attachment_claim_failed.emit("所有附件添加失败：\n%s" % _format_batch_apply_failures(failed_entries))
		return
	var mail_ids: Array = []
	for item in finalize_batch:
		mail_ids.append(int(item.get("mail_id", 0)))
	var token = _get_auth_token()
	if token.is_empty():
		attachment_claim_failed.emit("会话已过期，请重新登录")
		return
	_pending_finalize_batch = finalize_batch.duplicate()
	_set_pending_finalize_ids(mail_ids)
	if not failed_entries.is_empty():
		_pending_finalize_warning = "部分附件添加失败：\n%s" % _format_batch_apply_failures(failed_entries)
	_sync_mail_api_base_from_network()
	_api.finalize_claims(mail_ids, token, _build_mail_finalize_operation_id())

func _apply_finalize_wallet_from_payload(payload: Dictionary) -> void :
	var gm = GameManager.instance
	if gm == null or gm.player == null:
		return
	if payload.has("new_gold"):
		gm.player.gold = int(payload["new_gold"])
		gm.gold_changed.emit(gm.player.gold)
	if payload.has("new_yuanbao"):
		gm.player.yuanbao_currency = int(payload["new_yuanbao"])
		gm.yuanbao_changed.emit(gm.player.yuanbao_currency)
	if payload.has("new_xianmo_total_score") and gm.xianmo_system and gm.xianmo_system.xianmo_data:
		var xm_data = gm.xianmo_system.xianmo_data
		xm_data.total_score = int(payload["new_xianmo_total_score"])
		gm.xianmo_system.score_changed.emit(int(xm_data.weekly_score), int(xm_data.total_score))


func _begin_post_finalize_claim_sync(claimed_entries: Array, payload: Dictionary) -> void :
	var reconcile_ok: bool = await _reconcile_finalize_claim_save(claimed_entries, payload)
	if reconcile_ok:
		_trigger_post_claim_cloud_sync(claimed_entries)

func _attachments_include_pets(attachments: Variant) -> bool:
	if not attachments is Dictionary:
		return false
	var att: Dictionary = attachments
	if not att.get("pets", []).is_empty():
		return true
	if str(att.get("type", "")).strip_edges() == "pet":
		return att.has("pet_id") or att.has("petId")
	return false

func _claimed_entries_include_pets(claimed_entries: Array) -> bool:
	for entry in claimed_entries:
		if entry is Dictionary and _attachments_include_pets(entry.get("attachments", {})):
			return true
	return false

func _refresh_main_ui_pet_roster_after_mail_claim() -> void :
	var gm: = GameManager.instance
	if gm == null or not gm.has_method("_find_main_ui_node"):
		return
	var main_ui: Node = gm._find_main_ui_node()
	if main_ui != null and main_ui.has_method("_refresh_pet_roster_after_authority_reward"):
		main_ui.call_deferred("_refresh_pet_roster_after_authority_reward")

func _reconcile_finalize_claim_save(claimed_entries: Array, payload: Dictionary) -> bool:
	if bool(payload.get("duplicate", false)):
		return true
	var gm = GameManager.instance
	if gm == null:
		return false
	var expected_sealed: = _count_sealed_suits_in_claimed_entries(claimed_entries)
	var needs_sealed_authority: = expected_sealed > 0 or _mail_claim_requires_full_authority_upload(claimed_entries)
	var sd: Variant = payload.get("saveData", payload.get("save_data", null))
	if sd is Dictionary and not (sd as Dictionary).is_empty():
		var sealed_before: int = 0
		var inv_mgr: InventoryManager = gm.inventory_manager as InventoryManager
		if inv_mgr != null:
			sealed_before = inv_mgr.count_sealed_suit_item_rows()
		if needs_sealed_authority and expected_sealed > 0:
			var sealed_in_save: int = _count_sealed_suits_in_save_data(sd as Dictionary)
			if sealed_in_save < sealed_before + expected_sealed:
				push_warning("[MailManager] finalize 回包封印套装数量不足 expected=%d before=%d in_save=%d" % [expected_sealed, sealed_before, sealed_in_save])
				return false
		if gm.has_method("apply_cloud_save"):
			var apply_opts: = {
				"preserve_local_pet_collection_if_ahead": true, 
				"preserve_local_pets_not_in_cloud": true, 
				"skip_pet_collection_trim": true, 
				"reward_inventory_slice": true, 
			}
			if _claimed_entries_include_pets(claimed_entries):
				apply_opts["pets_authoritative"] = true
				apply_opts["skip_pet_progress_merge"] = true
			gm.apply_cloud_save(sd as Dictionary, apply_opts)
			if _claimed_entries_include_pets(claimed_entries):
				_refresh_main_ui_pet_roster_after_mail_claim()
		if needs_sealed_authority and expected_sealed > 0 and inv_mgr != null:
			var sealed_after: int = inv_mgr.count_sealed_suit_item_rows()
			if sealed_after < sealed_before + expected_sealed:
				push_warning("[MailManager] apply 后封印套装数量不足 expected=%d before=%d after=%d" % [expected_sealed, sealed_before, sealed_after])
				return false
		return true
	if needs_sealed_authority:
		push_warning("[MailManager] 封印套装领取无 saveData，禁止云档 fallback 覆盖")
		return false
	return true

func _pull_cloud_save_and_apply_fallback(gm: GameManager) -> void :
	if gm == null or gm.network == null:
		return
	var tree = get_tree()
	if tree == null:
		return
	var state: = {"done": false, "data": {}}
	var on_dl = func(save_data):
		state["done"] = true
		if save_data is Dictionary:
			state["data"] = save_data
	gm.network.save_downloaded.connect(on_dl, CONNECT_ONE_SHOT)
	gm.download_cloud_save()
	var frames: = 0
	while not bool(state["done"]) and frames < 600:
		await tree.process_frame
		frames += 1
	var downloaded: Dictionary = state["data"] as Dictionary
	if downloaded.is_empty() or bool(downloaded.get("_download_error", false)):
		return
	if not downloaded.has("playerData"):
		return
	if gm.network.has_method("merge_pending_into_downloaded_save"):
		gm.network.merge_pending_into_downloaded_save(downloaded)
	if gm.has_method("apply_cloud_save"):
		gm.apply_cloud_save(downloaded, {
			"preserve_local_pet_collection_if_ahead": true, 
			"preserve_local_pets_not_in_cloud": true, 
			"skip_pet_collection_trim": true, 
		})

func _on_finalize_claims_done(success: bool, error_message: String, payload: Dictionary) -> void :
	var updated_count: int = int(payload.get("updated", 0))
	var duplicate_finalize: bool = bool(payload.get("duplicate", false))
	if not _pending_finalize_single.is_empty():
		var mail_id = int(_pending_finalize_single.get("mail_id", 0))
		var attachments = _pending_finalize_single.get("attachments", {})
		var had_local_apply_single: = bool(_pending_finalize_single.get("had_local_apply", false))
		_pending_finalize_single = {}
		if not success:
			push_warning("[MailManager][FinalizeClaimsFailed][Single] " + String(error_message))
			_handle_finalize_failure([mail_id], error_message, had_local_apply_single, true)
			return
		if updated_count <= 0 and not duplicate_finalize:
			_clear_pending_finalize_ids([mail_id])
			attachment_claim_failed.emit("该邮件已失效，请刷新列表后重试")
			refresh_mail_list()
			return
		_apply_finalize_wallet_from_payload(payload)
		var single_claimed_entry: = {"mail_id": mail_id, "attachments": attachments}
		if not await _reconcile_finalize_claim_save([single_claimed_entry], payload):
			_handle_finalize_failure([mail_id], MSG_SEALED_SUIT_CLAIM_SYNC_FAILED, had_local_apply_single, true, true)
			return
		for mail in _mails:
			if mail.id == mail_id:
				mail.is_claimed = true
				mail.is_read = true
				break
		attachment_claimed_success.emit(mail_id, attachments)
		mail_list_updated.emit(_mails)
		refresh_mail_list()
		var count = 0
		for m in _mails:
			if not m.is_read:
				count += 1
		unread_count = count
		call_deferred("_begin_post_finalize_claim_sync", [single_claimed_entry], payload)
		return
	if not _pending_finalize_batch.is_empty():
		var batch = _pending_finalize_batch
		_pending_finalize_batch = []
		var warning_message = _pending_finalize_warning
		_pending_finalize_warning = ""
		if not success:
			push_warning("[MailManager][FinalizeClaimsFailed][Batch] " + String(error_message))
			var failed_batch_ids: Array = []
			for item in batch:
				failed_batch_ids.append(int(item.get("mail_id", 0)))
			var batch_had_local: = false
			for item in batch:
				if bool(item.get("had_local_apply", false)):
					batch_had_local = true
					break
			_handle_finalize_failure(failed_batch_ids, error_message, batch_had_local, true)
			return
		if updated_count <= 0 and not duplicate_finalize:
			var _done_ids: Array[int] = []
			for item in batch:
				_done_ids.append(int(item.get("mail_id", 0)))
			_clear_pending_finalize_ids(_done_ids)
			attachment_claim_failed.emit("领取状态未确认，请稍后刷新邮件后重试")
			refresh_mail_list()
			return
		_apply_finalize_wallet_from_payload(payload)
		var server_batch: Array = batch.duplicate()
		if not await _reconcile_finalize_claim_save(server_batch, payload):
			var failed_reconcile_ids: Array = []
			for item in batch:
				failed_reconcile_ids.append(int(item.get("mail_id", 0)))
			var batch_had_local_reconcile: = false
			for item in batch:
				if bool(item.get("had_local_apply", false)):
					batch_had_local_reconcile = true
					break
			_handle_finalize_failure(failed_reconcile_ids, MSG_SEALED_SUIT_CLAIM_SYNC_FAILED, batch_had_local_reconcile, true, true)
			return
		for item in batch:
			var mail_id = int(item.get("mail_id", 0))
			for mail in _mails:
				if mail.id == mail_id:
					mail.is_claimed = true
					mail.is_read = true
					break

		var merged_batch: Array = batch.duplicate()
		if not _pending_claim_all_local_claimed.is_empty():
			merged_batch.append_array(_pending_claim_all_local_claimed)
		var warn_parts: Array[String] = []
		var warn_t: String = str(warning_message).strip_edges()
		if not warn_t.is_empty():
			warn_parts.append(warn_t)
		var local_warn_t: String = str(_pending_claim_all_local_warning).strip_edges()
		if not local_warn_t.is_empty():
			warn_parts.append(local_warn_t)
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
		var merged_warn: = "\n".join(warn_parts)
		all_attachments_claimed_success.emit(merged_batch, merged_warn)
		mail_list_updated.emit(_mails)
		var count2 = 0
		for m in _mails:
			if not m.is_read:
				count2 += 1
		unread_count = count2
		call_deferred("_begin_post_finalize_claim_sync", merged_batch, payload)
		return

	if not _pending_finalize_mail_ids.is_empty():
		if success:
			_pending_finalize_mail_ids.clear()
			_save_pending_finalize_cache()
			refresh_mail_list()
		else:
			push_warning("[MailManager][FinalizeClaimsFailed][Recovery] " + String(error_message))
			_handle_finalize_failure([], error_message, false, false)

func _on_unread_count_received(count: int) -> void :
	unread_count = count

func _on_claimed_mails_deleted(deleted_count: int) -> void :

	var remaining_mails: Array[MailData] = []
	for mail in _mails:
		if not mail.is_claimed and mail.has_attachments():
			remaining_mails.append(mail)
		elif not mail.has_attachments() and not mail.is_read:
			remaining_mails.append(mail)
		else:
			pass

	_mails = remaining_mails
	_save_local_mail_cache()
	mail_list_updated.emit(_mails)


	var count = 0
	for m in _mails:
		if not m.is_read:
			count += 1
	unread_count = count

	claimed_mails_deleted.emit(deleted_count)

func _on_mail_delete_done(success: bool, deleted_count: int, error_message: String) -> void :
	var mid: = _pending_delete_mail_id
	_pending_delete_mail_id = 0
	if not success:
		var msg: = error_message.strip_edges()
		if msg.is_empty():
			msg = "删除邮件失败"
		error_occurred.emit(msg)
		return
	if mid > 0:
		_clear_pending_finalize_ids([mid])
	if deleted_count <= 0:

		error_occurred.emit("未能删除该邮件（可能已不存在）")
	refresh_mail_list()
	mail_deleted.emit(mid, deleted_count)

func _on_api_error(error: String) -> void :

	if error == "没有可领取的邮件" and not _pending_claim_all_local_claimed.is_empty():
		var local_claimed: = _pending_claim_all_local_claimed.duplicate()
		var local_warn: = str(_pending_claim_all_local_warning).strip_edges()
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
		_trigger_post_claim_cloud_sync(local_claimed.duplicate(true))
		all_attachments_claimed_success.emit(local_claimed, local_warn)
		return

	if not _pending_claim_all_local_claimed.is_empty():
		var local_claimed2: = _pending_claim_all_local_claimed.duplicate()
		var local_warn2: = str(_pending_claim_all_local_warning).strip_edges()
		var merged_warn: = "服务端邮件领取失败：%s" % error
		if not local_warn2.is_empty():
			merged_warn = "%s\n%s" % [local_warn2, merged_warn]
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
		_trigger_post_claim_cloud_sync(local_claimed2.duplicate(true))
		all_attachments_claimed_success.emit(local_claimed2, merged_warn)
		return
	error_occurred.emit(error)

func _on_refresh_timer() -> void :
	refresh_mail_list()
	refresh_unread_count()




func sync_mail_api_base(server_url: String) -> void :
	var u: = String(server_url).strip_edges()
	if u.is_empty():
		_api.set_api_base_override("")
	else:
		_api.set_api_base_override(u)
	var gm = GameManager.instance
	if gm != null and gm.network != null:
		var ver = gm.network.client_version_header
		var vs: = String(ver).strip_edges()
		if not vs.is_empty():
			_api.set_client_version_header(vs)


func _sync_mail_api_base_from_network() -> void :
	var gm = GameManager.instance
	if gm == null or gm.network == null:
		return
	var su: = str(gm.network.server_url).strip_edges()
	if su.is_empty():
		return
	sync_mail_api_base(su)
	var ver = gm.network.client_version_header
	var vs2: = String(ver).strip_edges()
	if not vs2.is_empty():
		_api.set_client_version_header(vs2)


func set_auth_token(token: String) -> void :
	_auth_token = token
	_retry_pending_finalize_claims()

func _get_auth_token() -> String:
	if not _auth_token.is_empty():
		return _auth_token
	if GameManager.instance:
		if GameManager.instance.network and "auth_token" in GameManager.instance.network:
			return GameManager.instance.network.auth_token
		if "auth_token" in GameManager.instance:
			return GameManager.instance.auth_token
	return ""

func has_pending_finalize_claims() -> bool:
	return not _pending_finalize_mail_ids.is_empty()

func _is_mail_pending_finalize(mail_id: int) -> bool:
	return _pending_finalize_mail_ids.has(int(mail_id))

func _set_pending_finalize_ids(mail_ids: Array) -> void :
	for idv in mail_ids:
		var mid = int(idv)
		if mid > 0 and not _pending_finalize_mail_ids.has(mid):
			_pending_finalize_mail_ids.append(mid)
	_save_pending_finalize_cache()

func _clear_pending_finalize_ids(mail_ids: Array) -> void :
	for idv in mail_ids:
		var mid = int(idv)
		_pending_finalize_mail_ids.erase(mid)
	_save_pending_finalize_cache()

func _save_pending_finalize_cache() -> void :
	var cfg: = ConfigFile.new()
	cfg.set_value("mail", "pending_finalize_mail_ids", _pending_finalize_mail_ids)
	var err = cfg.save(PENDING_FINALIZE_CACHE_PATH)
	if err != OK:
		push_warning("[MailManager] 保存待确认领取缓存失败: %s" % str(err))

func _load_pending_finalize_cache() -> void :
	_pending_finalize_mail_ids.clear()
	var cfg: = ConfigFile.new()
	var err = cfg.load(PENDING_FINALIZE_CACHE_PATH)
	if err != OK:
		return
	var arr: Variant = cfg.get_value("mail", "pending_finalize_mail_ids", [])
	if arr is Array:
		for idv in arr:
			var mid: = int(idv)
			if mid > 0 and not _pending_finalize_mail_ids.has(mid):
				_pending_finalize_mail_ids.append(mid)

func _reconcile_pending_finalize_ids_with_mail_list() -> void :
	if _pending_finalize_mail_ids.is_empty():
		return
	var keep_ids: Array[int] = []
	for mid in _pending_finalize_mail_ids:
		var found_mail: = false
		for mail in _mails:
			if mail == null or mail.id != int(mid):
				continue
			found_mail = true
			if not mail.is_claimed:
				keep_ids.append(int(mid))
			break
	if keep_ids.size() == _pending_finalize_mail_ids.size():
		return
	_pending_finalize_mail_ids = keep_ids
	_save_pending_finalize_cache()

func _retry_pending_finalize_claims() -> void :
	if _pending_finalize_mail_ids.is_empty():
		return
	if not _pending_finalize_single.is_empty() or not _pending_finalize_batch.is_empty():
		return
	var token = _get_auth_token()
	if token.is_empty():
		return
	_sync_mail_api_base_from_network()
	var mail_ids: Array = []
	for mid in _pending_finalize_mail_ids:
		mail_ids.append(int(mid))
	_api.finalize_claims(mail_ids, token, _build_mail_finalize_operation_id())

func _build_mail_finalize_operation_id() -> String:
	return "mail_finalize_%d_%d" % [Time.get_unix_time_from_system(), randi()]

func _is_finalize_error_permanent(error_message: String) -> bool:
	var err: = str(error_message).strip_edges()
	if err.is_empty():
		return false
	if err.contains("宠物栏") or err.contains("空间不足") or err.contains("装备背包已满") or err.contains("已达最大叠加") or err.contains("背包空间"):
		return true
	return false

func _format_finalize_failure_message(error_message: String) -> String:
	var err: = str(error_message).strip_edges()
	if err.is_empty():
		return "确认领取失败，请稍后重试"
	if _is_finalize_error_permanent(err):
		return MSG_PET_ROSTER_FULL_FOR_MAIL
	return err

func _handle_finalize_failure(mail_ids: Array, error_message: String, had_local_apply: bool, emit_to_ui: bool, keep_pending: bool = false) -> void :
	var ids_to_clear: Array = []
	if mail_ids.is_empty():
		for mid in _pending_finalize_mail_ids:
			ids_to_clear.append(int(mid))
	else:
		for idv in mail_ids:
			ids_to_clear.append(int(idv))
	if not keep_pending and not ids_to_clear.is_empty():
		_clear_pending_finalize_ids(ids_to_clear)
	_pending_finalize_single = {}
	_pending_finalize_batch = []
	_pending_finalize_warning = ""
	if emit_to_ui:
		_pending_claim_all_local_claimed.clear()
		_pending_claim_all_local_warning = ""
	if had_local_apply:
		call_deferred("_rollback_local_claim_after_finalize_failure")
	if emit_to_ui:
		attachment_claim_failed.emit(_format_finalize_failure_message(error_message))

func _rollback_local_claim_after_finalize_failure() -> void :
	var gm = GameManager.instance
	if gm == null:
		return
	await _pull_cloud_save_and_apply_fallback(gm)

func _is_tower_family_gift_item(item_name: String) -> bool:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return false
	if n == "天关礼包":
		return true
	return n.ends_with("关礼包")


func _collect_attachment_demand_for_simulation(attachments: Dictionary, inv_manager) -> Dictionary:
	var stack_additions: Array = []
	var sealed_suits: = 0
	var direct_suit_equipment: = 0
	var pets_need: = 0
	for item_data in attachments.get("items", []):
		if item_data is Dictionary:
			var item_type = str(item_data.get("type", ""))
			if item_type == "sealed_suit":
				sealed_suits += max(1, int(item_data.get("count", item_data.get("quantity", 1))))
			else:
				var item_name = str(item_data.get("name", item_data.get("id", item_data.get("item_id", ""))))
				if item_name.is_empty():
					continue
				var item_count = max(1, int(item_data.get("count", item_data.get("quantity", 1))))
				var suit_probe: = _try_add_suit_equipment_by_display_name(item_name, 0)
				if bool(suit_probe.get("handled", false)):
					direct_suit_equipment += item_count
					continue
				var category = inv_manager.resolve_bag_category(item_name, item_type)
				stack_additions.append({"name": item_name, "category": category, "count": item_count})
		elif item_data is String:
			var str_item_name = str(item_data)
			if str_item_name.is_empty():
				continue
			var suit_probe_str: = _try_add_suit_equipment_by_display_name(str_item_name, 0)
			if bool(suit_probe_str.get("handled", false)):
				direct_suit_equipment += 1
				continue
			var str_category = inv_manager.resolve_bag_category(str_item_name, "")
			stack_additions.append({"name": str_item_name, "category": str_category, "count": 1})
	pets_need += attachments.get("pets", []).size()
	if attachments.has("type"):
		var flat_type = str(attachments.get("type", ""))
		if flat_type == "sealed_suit":
			sealed_suits += max(1, int(attachments.get("quantity", attachments.get("count", 1))))
		elif flat_type == "item" and attachments.has("item_id"):
			var flat_item_name = str(attachments.get("item_id", ""))
			if not flat_item_name.is_empty():
				var flat_count = max(1, int(attachments.get("quantity", 1)))
				var flat_suit_probe: = _try_add_suit_equipment_by_display_name(flat_item_name, 0)
				if bool(flat_suit_probe.get("handled", false)):
					direct_suit_equipment += flat_count
				else:
					var flat_category = inv_manager.resolve_bag_category(flat_item_name, "")
					stack_additions.append({"name": flat_item_name, "category": flat_category, "count": flat_count})
		elif flat_type == "pet" and attachments.has("pet_id"):
			pets_need += max(1, int(attachments.get("quantity", 1)))
	return {
		"stack_additions": stack_additions, 
		"sealed_suits": sealed_suits, 
		"direct_suit_equipment": direct_suit_equipment, 
		"pets": pets_need
	}



func _check_cumulative_space_for_claim_all() -> Dictionary:
	var result = {"success": true, "reason": ""}
	if GameManager.instance == null:
		result.success = false
		result.reason = "游戏管理器未初始化"
		return result
	var gm = GameManager.instance
	if gm.inventory_manager == null or gm.pet_manager == null:
		result.success = false
		result.reason = "背包或宠物管理器未初始化"
		return result
	var inv_manager = gm.inventory_manager
	var stack_max: int = int(inv_manager.MAX_STACK_SIZE)
	var item_max_slots: int = int(inv_manager.get_max_slots_by_category("item"))
	var material_max_slots: int = int(inv_manager.get_max_slots_by_category("material"))
	var item_used_slots: int = int(inv_manager.get_used_slots_by_category("item"))
	var material_used_slots: int = int(inv_manager.get_used_slots_by_category("material"))
	var virtual_counts: Dictionary = {}
	for inv_item in inv_manager.items:
		if inv_item == null:
			continue
		var inv_item_name = str(inv_item.name)
		if inv_item_name.is_empty():
			continue
		virtual_counts[inv_item_name] = int(virtual_counts.get(inv_item_name, 0)) + max(0, int(inv_item.count))
	var pet_rem: int = gm.pet_manager.get_available_slots()
	var equip_rem: int = 0
	if gm.equipment_manager:
		equip_rem = max(0, int(gm.equipment_manager.max_inventory) - int(gm.equipment_manager.inventory.size()))
	var sealed_inv_slot_rem: int = int(inv_manager.get_combined_equipment_free_slots())
	for mail in get_claimable_mails():
		if not mail.has_attachments():
			continue
		var d = _collect_attachment_demand_for_simulation(mail.attachments, inv_manager)
		var need_seal: int = int(d.get("sealed_suits", 0))
		var need_direct_suit: int = int(d.get("direct_suit_equipment", 0))
		var need_pet: int = int(d.get("pets", 0))
		if need_pet > pet_rem:
			result.success = false
			result.reason = "宠物栏不足：需要 %d 个主战栏空位，当前仅剩 %d 个。可将不用的宠物放入宠物袋后再试。" % [need_pet, pet_rem]
			return result
		pet_rem -= need_pet
		if need_seal > sealed_inv_slot_rem:
			result.success = false
			result.reason = "装备背包已满（含封印套装）：需要 %d 格，剩余 %d 格" % [need_seal, sealed_inv_slot_rem]
			return result
		sealed_inv_slot_rem -= need_seal
		for add in d.stack_additions:
			var item_name = str(add.get("name", ""))
			if item_name.is_empty():
				continue
			var category = str(add.get("category", "item"))
			var add_count: int = max(1, int(add.get("count", 1)))
			var prev_count: int = int(virtual_counts.get(item_name, 0))
			var old_slots: int = int(ceil(float(prev_count) / float(stack_max))) if prev_count > 0 else 0
			var new_total: int = prev_count + add_count
			var new_slots: int = int(ceil(float(new_total) / float(stack_max)))
			var delta_slots: int = max(0, new_slots - old_slots)
			if category == "material":
				material_used_slots += delta_slots
				if material_used_slots > material_max_slots:
					var remain_material = max(0, material_max_slots - (material_used_slots - delta_slots))
					result.success = false
					result.reason = "材料栏不足：需要 %d 格，剩余 %d 格" % [delta_slots, remain_material]
					return result
			else:
				item_used_slots += delta_slots
				if item_used_slots > item_max_slots:
					var remain_item = max(0, item_max_slots - (item_used_slots - delta_slots))
					result.success = false
					result.reason = "物品栏不足：需要 %d 格，剩余 %d 格" % [delta_slots, remain_item]
					return result
			virtual_counts[item_name] = new_total
		if need_direct_suit > equip_rem:
			result.success = false
			result.reason = "装备栏不足：需要 %d 格，剩余 %d 格" % [need_direct_suit, equip_rem]
			return result
		equip_rem -= need_direct_suit
	return result



func _check_space_for_attachments(attachments: Dictionary) -> Dictionary:
	var result = {
		"success": true, 
		"reason": ""
	}

	var items = attachments.get("items", [])
	if not items.is_empty():
		if GameManager.instance and GameManager.instance.inventory_manager:
			var inventory = GameManager.instance.inventory_manager
			var gm = GameManager.instance

			var sealed_suit_count: = 0
			var direct_suit_count: = 0
			var item_slot_count: = 0
			var material_slot_count: = 0
			for item_data in items:
				if item_data is Dictionary:
					var item_type = item_data.get("type", "")
					if item_type == "sealed_suit":
						sealed_suit_count += max(1, int(item_data.get("count", item_data.get("quantity", 1))))
					else:
						var item_name = str(item_data.get("name", item_data.get("id", item_data.get("item_id", ""))))
						var item_count = max(1, int(item_data.get("count", item_data.get("quantity", 1))))
						var suit_probe: = _try_add_suit_equipment_by_display_name(item_name, 0)
						if bool(suit_probe.get("handled", false)):
							direct_suit_count += item_count
							continue
						var category = inventory.resolve_bag_category(item_name, str(item_type))
						if category == "material":
							material_slot_count += 1
						else:
							item_slot_count += 1
				elif item_data is String:
					var str_suit_probe: = _try_add_suit_equipment_by_display_name(str(item_data), 0)
					if bool(str_suit_probe.get("handled", false)):
						direct_suit_count += 1
						continue
					var str_category = inventory.resolve_bag_category(str(item_data), "")
					if str_category == "material":
						material_slot_count += 1
					else:
						item_slot_count += 1

			var available_item_space: int = int(inventory.get_available_space_by_category("item"))
			if available_item_space < item_slot_count:
				result.success = false
				result.reason = "物品栏空间不足：需要%d格，剩余%d格" % [item_slot_count, available_item_space]
				return result
			var available_material_space: int = int(inventory.get_available_space_by_category("material"))
			if available_material_space < material_slot_count:
				result.success = false
				result.reason = "材料栏空间不足：需要%d格，剩余%d格" % [material_slot_count, available_material_space]
				return result


			if sealed_suit_count > 0:
				var sealed_slot_avail: int = int(inventory.get_combined_equipment_free_slots())
				if sealed_slot_avail < sealed_suit_count:
					result.success = false
					result.reason = "装备背包已满（含封印套装）：需要%d格，剩余%d格" % [sealed_suit_count, sealed_slot_avail]
					return result

			if direct_suit_count > 0:
				if gm.equipment_manager == null:
					result.success = false
					result.reason = "装备管理器未初始化"
					return result
				var equip_manager = gm.equipment_manager
				var equip_available = max(0, int(equip_manager.max_inventory) - int(equip_manager.inventory.size()))
				if equip_available < direct_suit_count:
					result.success = false
					result.reason = "装备栏空间不足：需要%d格，剩余%d格" % [direct_suit_count, equip_available]
					return result

	var pets = attachments.get("pets", [])
	if not pets.is_empty():
		if GameManager.instance and GameManager.instance.pet_manager:
			var pet_manager = GameManager.instance.pet_manager
			var available_slots = pet_manager.get_available_slots()
			if available_slots < pets.size():
				result.success = false
				result.reason = "宠物栏不足：需要 %d 个主战栏空位，当前仅剩 %d 个。可将不用的宠物放入宠物袋后再试。" % [pets.size(), available_slots]
				return result

	if attachments.has("type"):
		var item_type = attachments.get("type", "")
		if item_type == "pet" and attachments.has("pet_id"):
			if GameManager.instance and GameManager.instance.pet_manager:
				var pet_manager = GameManager.instance.pet_manager
				var available_slots = pet_manager.get_available_slots()
				if available_slots < 1:
					result.success = false
					result.reason = MSG_PET_ROSTER_FULL_FOR_MAIL
					return result
		elif item_type == "item" and attachments.has("item_id"):
			if GameManager.instance and GameManager.instance.inventory_manager:
				var inventory = GameManager.instance.inventory_manager
				var item_id = str(attachments.get("item_id", ""))
				var quantity = int(attachments.get("quantity", 1))
				var category: String = str(inventory.resolve_bag_category(item_id, ""))
				var available_space: int = int(inventory.get_available_space_by_category(category))
				if available_space < 1:
					result.success = false
					result.reason = "%s栏已满，无法领取物品" % ("材料" if category == "material" else "物品")
					return result
		elif str(attachments.get("type", "")) == "sealed_suit":
			if GameManager.instance and GameManager.instance.inventory_manager:
				var inv_flat = GameManager.instance.inventory_manager
				var seal_n: int = max(1, int(attachments.get("quantity", attachments.get("count", 1))))
				var seal_avail: int = int(inv_flat.get_combined_equipment_free_slots())
				if seal_avail < seal_n:
					result.success = false
					result.reason = "装备背包已满（含封印套装）：需要%d格，剩余%d格" % [seal_n, seal_avail]
					return result

	return result



func _try_add_suit_equipment_by_display_name(item_name: String, count: int) -> Dictionary:
	var out: = {"handled": false, "success": false, "message": ""}
	if item_name.is_empty() or not item_name.contains("·"):
		return out
	const SEP: = "·"
	var sep_idx: = item_name.find(SEP)
	if sep_idx <= 0:
		return out
	var suit_name: = item_name.substr(0, sep_idx).strip_edges()
	var slot_cn: = item_name.substr(sep_idx + SEP.length()).strip_edges()
	if suit_name.is_empty() or slot_cn.is_empty():
		return out
	var cn_to_en: Dictionary = {}
	for sk in SuitDatabaseDetailed.SLOT_NAMES.keys():
		cn_to_en[str(SuitDatabaseDetailed.SLOT_NAMES[sk])] = sk
	cn_to_en["帽子"] = "helmet"
	var matched_slot: String = str(cn_to_en.get(slot_cn, ""))
	if matched_slot.is_empty():
		return out
	var suit_level: = -1
	for lvl in SuitDatabaseDetailed.get_all_suit_levels():
		if SuitDatabaseDetailed.get_suit_name(int(lvl)) == suit_name:
			suit_level = int(lvl)
			break
	if suit_level < 1:
		return out
	out["handled"] = true
	var gm = GameManager.instance
	var em = gm.equipment_manager if gm else null
	if em == null:
		out["message"] = "装备管理器未初始化"
		return out
	var n: = maxi(1, int(count))
	var failed: = 0
	for _i in n:
		var eq = em.create_suit_equipment(suit_level, matched_slot)
		if eq == null or not em.add_to_inventory(eq):
			failed += 1
	if failed > 0:
		out["message"] = "装备栏可能已满"
		return out
	out["success"] = true
	return out




func _add_attachments_to_game(attachments: Dictionary, skip_server_currency: bool = false, defer_pets_to_finalize: bool = false, defer_sealed_suits_to_finalize: bool = false, defer_tower_gifts_to_finalize: bool = false) -> Dictionary:
	var result: = {"success": true, "failures": [], "local_inventory_touched": false}
	var gm = GameManager.instance
	if gm == null:
		result.success = false
		result.failures.append("游戏管理器未初始化")
		return result
	var player = gm.player
	var inventory_manager = gm.inventory_manager
	var pet_manager = gm.pet_manager

	print("[MailManager] _add_attachments_to_game: attachments=", attachments)


	if not skip_server_currency:
		var gold = attachments.get("gold", 0)
		if gold > 0:
			if player:
				player.gold += gold
				print("[MailManager] 添加金币: ", gold)
			else:
				result.failures.append("玩家对象不存在，无法添加金币")


	if not skip_server_currency:
		var yuanbao = attachments.get("yuanbao", 0)
		if yuanbao > 0:
			if player:
				player.yuanbao_currency += int(yuanbao)
				print("[MailManager] 添加元宝: ", yuanbao)
			else:
				result.failures.append("玩家对象不存在，无法添加元宝")


	var exp = attachments.get("exp", 0)
	if exp > 0:
		if player:
			player.add_exp(exp)
			print("[MailManager] 添加经验: ", exp)
		else:
			result.failures.append("玩家对象不存在，无法添加经验")


	var items = attachments.get("items", [])
	for item_data in items:
		if inventory_manager == null:
			result.failures.append("背包管理器未初始化，无法添加物品")
			break
		if item_data is Dictionary:
			var item_name = item_data.get("name", item_data.get("id", item_data.get("item_id", "")))

			var item_name_compat: = {
				"神佑lv1": "神佑lv1技能书", 
			}
			if item_name in item_name_compat:
				item_name = item_name_compat[item_name]
			var item_count = item_data.get("count", item_data.get("quantity", 1))
			var item_type = item_data.get("type", "")
			print("[MailManager] 添加物品: name=", item_name, ", count=", item_count, ", type=", item_type)
			if defer_tower_gifts_to_finalize and _is_tower_family_gift_item(str(item_name)):
				pass
			elif defer_sealed_suits_to_finalize and str(item_type) == "sealed_suit":
				pass
			elif item_type == "sealed_suit" and item_data.has("data"):
				var seal_result = _add_sealed_suit_from_mail(item_data.data, max(1, int(item_count)))
				if int(seal_result.get("failed", 0)) > 0:
					result.failures.append("封印套装 x%d 添加失败（背包封印套装栏位可能已满）" % int(seal_result.get("failed", 0)))
			elif item_type == "sealed_suit" and not item_name.is_empty():
				var parsed = _parse_sealed_suit_by_name(item_name)
				if parsed.success:
					var parsed_seal_result = _add_sealed_suit_from_mail(parsed.data, max(1, int(item_count)))
					if int(parsed_seal_result.get("failed", 0)) > 0:
						result.failures.append("封印套装 x%d 添加失败（背包封印套装栏位可能已满）" % int(parsed_seal_result.get("failed", 0)))
				else:
					print("[MailManager] 无法解析封印套装名称: ", item_name)
					result.failures.append("未知物品：%s" % item_name)
			elif item_name != "":
				var extra_data: Dictionary = {}
				var raw_custom: Variant = item_data.get("custom_data", {})
				if raw_custom is Dictionary:
					extra_data = (raw_custom as Dictionary).duplicate(true)

				if item_name in ["仙魔灵兽礼包", "仙魔神兽礼包", "仙魔变异礼包", "仙魔野生礼包"] and item_data.has("growth") and not extra_data.has("xianmo_gift_growth"):
					extra_data["xianmo_gift_growth"] = float(item_data.get("growth", 0.0))
				if item_name == "藏宝箱" and item_data.has("treasure_token"):
					extra_data["treasure_token"] = str(item_data.get("treasure_token", ""))
				var suit_try: = _try_add_suit_equipment_by_display_name(item_name, item_count)
				if suit_try.get("handled", false):
					if not suit_try.get("success", false):
						result.failures.append("%s x%d 添加失败：%s" % [item_name, int(item_count), str(suit_try.get("message", "装备栏已满"))])
				else:
					var add_res = inventory_manager.add_item(item_name, item_count, extra_data)
					if bool(add_res.get("success", false)):
						result["local_inventory_touched"] = true
					if not bool(add_res.get("success", false)):
						result.failures.append("%s x%d 添加失败：%s" % [item_name, int(item_count), str(add_res.get("message", "未知错误"))])
			else:
				result.failures.append("物品数据异常：缺少 name/item_id 字段")
		elif item_data is String:
			var suit_str: = _try_add_suit_equipment_by_display_name(item_data, 1)
			if suit_str.get("handled", false):
				if not suit_str.get("success", false):
					result.failures.append("%s 添加失败：%s" % [item_data, str(suit_str.get("message", "装备栏已满"))])
			else:
				var add_str_res = inventory_manager.add_item(item_data, 1)
				if bool(add_str_res.get("success", false)):
					result["local_inventory_touched"] = true
				if not bool(add_str_res.get("success", false)):
					result.failures.append("%s 添加失败：%s" % [item_data, str(add_str_res.get("message", "未知错误"))])
		else:
			result.failures.append("物品数据格式异常")


	var chests = attachments.get("chests", [])
	for chest_data in chests:
		if chest_data is Dictionary:
			var chest_type = chest_data.get("type", "bronze")
			print("[MailManager] 添加宝箱: type=", chest_type)
			if gm and gm.xianmo_chest_manager:
				gm.xianmo_chest_manager.add_chest(str(chest_type), 1)
			elif inventory_manager:
				inventory_manager.add_xianmo_chest(str(chest_type), 1)
			else:
				result.failures.append("玩家对象不存在，无法添加宝箱")
		else:
			result.failures.append("宝箱数据格式异常")


	if not defer_pets_to_finalize:
		var pets = attachments.get("pets", [])
		for pet_data in pets:
			if pet_manager:
				print("[MailManager] 添加宠物: ", pet_data)
				var normalized_pet_data: Dictionary = {}
				if pet_data is Dictionary:
					normalized_pet_data = (pet_data as Dictionary).duplicate(true)
					if not normalized_pet_data.has("pet_id") and normalized_pet_data.has("petId"):
						normalized_pet_data["pet_id"] = normalized_pet_data.get("petId", "")
					if not normalized_pet_data.has("name") and normalized_pet_data.has("petName"):
						normalized_pet_data["name"] = normalized_pet_data.get("petName", "")
					if not normalized_pet_data.has("growth_rate"):
						if normalized_pet_data.has("growth"):
							normalized_pet_data["growth_rate"] = normalized_pet_data.get("growth", 3.0)
						elif normalized_pet_data.has("level"):
							normalized_pet_data["growth_rate"] = normalized_pet_data.get("level", 3.0)
				var pet_id_n: String = str(normalized_pet_data.get("pet_id", normalized_pet_data.get("id", ""))).strip_edges()
				var pet_name_n: String = str(normalized_pet_data.get("name", normalized_pet_data.get("petName", ""))).strip_edges()
				var pet_level_n: int = int(normalized_pet_data.get("level", 1))
				var pet_growth_n: float = float(normalized_pet_data.get("growth_rate", normalized_pet_data.get("growth", 3.0)))
				var pet_generation_n: int = int(normalized_pet_data.get("generation", 0))
				var pet_stage_n: int = int(normalized_pet_data.get("evolution_stage", -1))
				var pet_skill_slots_n: Array = _build_mail_pet_skill_slots(normalized_pet_data)
				var pet_medals_n: Dictionary = _mail_pet_medal_counts(normalized_pet_data)
				var add_pet_ok: bool = false
				if not pet_id_n.is_empty():
					add_pet_ok = pet_manager.create_pet_from_mail(
						pet_id_n, 
						pet_level_n, 
						pet_growth_n, 
						pet_generation_n, 
						pet_stage_n, 
						pet_skill_slots_n, 
						pet_medals_n
					)

				if not add_pet_ok and not pet_name_n.is_empty():
					add_pet_ok = pet_manager.create_pet_from_mail(
						pet_name_n, 
						pet_level_n, 
						pet_growth_n, 
						pet_generation_n, 
						pet_stage_n, 
						pet_skill_slots_n, 
						pet_medals_n
					)
				if not add_pet_ok:
					add_pet_ok = pet_manager.add_pet_from_data(normalized_pet_data)
				if not add_pet_ok:
					result.failures.append("宠物添加失败（可能宠物栏已满或数据异常）")
			else:
				result.failures.append("宠物管理器未初始化，无法添加宠物")
				break

	if attachments.has("type"):
		var item_type = attachments.get("type", "")

		if item_type == "item" and attachments.has("item_id"):
			var item_id = attachments.get("item_id", "")
			var quantity = attachments.get("quantity", 1)
			var flat_extra: Dictionary = {}
			if str(item_id) == "藏宝箱" and attachments.has("treasure_token"):
				flat_extra["treasure_token"] = str(attachments.get("treasure_token", ""))
			if defer_tower_gifts_to_finalize and _is_tower_family_gift_item(str(item_id)):
				pass
			elif inventory_manager:
				var suit_flat: = _try_add_suit_equipment_by_display_name(str(item_id), int(quantity))
				var add_flat_res: Dictionary
				if suit_flat.get("handled", false):
					add_flat_res = {"success": suit_flat.get("success", false), "message": suit_flat.get("message", "")}
				else:
					add_flat_res = inventory_manager.add_item(item_id, quantity, flat_extra)
					if bool(add_flat_res.get("success", false)):
						result["local_inventory_touched"] = true
				if not bool(add_flat_res.get("success", false)):
					result.failures.append("%s x%d 添加失败：%s" % [item_id, int(quantity), str(add_flat_res.get("message", "未知错误"))])
			else:
				result.failures.append("背包管理器未初始化，无法添加物品")

		elif str(item_type) == "sealed_suit":
			if defer_sealed_suits_to_finalize:
				pass
			else:
				var seal_qty: int = max(1, int(attachments.get("quantity", attachments.get("count", 1))))
				if inventory_manager == null:
					result.failures.append("背包管理器未初始化，无法添加封印套装")
				else:
					var raw_seal: Variant = attachments.get("data", null)
					if raw_seal is Dictionary:
						var seal_apply: Dictionary = _add_sealed_suit_from_mail((raw_seal as Dictionary).duplicate(true), seal_qty)
						if int(seal_apply.get("failed", 0)) > 0:
							result.failures.append("封印套装 x%d 添加失败（背包封印套装栏位可能已满）" % int(seal_apply.get("failed", 0)))
					elif attachments.has("name"):
						var parsed_seal_flat: Dictionary = _parse_sealed_suit_by_name(str(attachments.get("name", "")))
						if bool(parsed_seal_flat.get("success", false)):
							var seal_apply2: Dictionary = _add_sealed_suit_from_mail(parsed_seal_flat["data"] as Dictionary, seal_qty)
							if int(seal_apply2.get("failed", 0)) > 0:
								result.failures.append("封印套装 x%d 添加失败（背包封印套装栏位可能已满）" % int(seal_apply2.get("failed", 0)))
						else:
							result.failures.append("无法解析封印套装附件名称")
					else:
						result.failures.append("封印套装附件缺少 data 或 name")

		elif not defer_pets_to_finalize and item_type == "pet" and attachments.has("pet_id"):
			var pet_id = attachments.get("pet_id", "")
			var pet_level = attachments.get("level", 1)
			var pet_growth = attachments.get("growth_rate", 1.0)
			var pet_generation = int(attachments.get("generation", 0))
			var pet_stage = int(attachments.get("evolution_stage", -1))
			var pet_skill_slots = _build_mail_pet_skill_slots(attachments)
			var pet_medals = _mail_pet_medal_counts(attachments)
			if pet_manager:
				if not pet_manager.create_pet_from_mail(pet_id, pet_level, pet_growth, pet_generation, pet_stage, pet_skill_slots, pet_medals):
					result.failures.append("宠物创建失败（可能宠物栏已满或数据异常）")
			else:
				result.failures.append("宠物管理器未初始化，无法添加宠物")
		elif not defer_pets_to_finalize and item_type == "pet" and attachments.has("petId"):
			var pet_id2 = str(attachments.get("petId", ""))
			var pet_level2 = int(attachments.get("level", 1))
			var pet_growth2 = float(attachments.get("growth_rate", attachments.get("growth", pet_level2)))
			var pet_generation2 = int(attachments.get("generation", 0))
			var pet_stage2 = int(attachments.get("evolution_stage", -1))
			var pet_skill_slots2 = _build_mail_pet_skill_slots(attachments)
			var pet_medals2 = _mail_pet_medal_counts(attachments)
			if pet_manager:
				if not pet_manager.create_pet_from_mail(pet_id2, pet_level2, pet_growth2, pet_generation2, pet_stage2, pet_skill_slots2, pet_medals2):
					result.failures.append("宠物创建失败（可能宠物栏已满或数据异常）")
			else:
				result.failures.append("宠物管理器未初始化，无法添加宠物")

		elif item_type == "gold":
			if not skip_server_currency:
				var gold_amount = attachments.get("amount", 0)
				if gold_amount > 0 and player:
					player.gold += gold_amount
				elif gold_amount > 0:
					result.failures.append("玩家对象不存在，无法添加金币")

		elif item_type == "yuanbao":
			if not skip_server_currency:
				var yuanbao_amount = attachments.get("amount", 0)
				if yuanbao_amount > 0 and player:
					player.yuanbao_currency += int(yuanbao_amount)
				elif yuanbao_amount > 0:
					result.failures.append("玩家对象不存在，无法添加元宝")

		elif item_type == "xianmo_total_score":
			if not skip_server_currency:
				var score_amount = int(attachments.get("amount", 0))
				if score_amount > 0 and gm.xianmo_system and gm.xianmo_system.xianmo_data:
					var xm_data = gm.xianmo_system.xianmo_data
					xm_data.total_score += score_amount
					gm.xianmo_system.score_changed.emit(int(xm_data.weekly_score), int(xm_data.total_score))
				elif score_amount > 0:
					result.failures.append("仙魔战场数据未初始化，无法添加总积分")

		elif item_type == "fabao":
			pass

	result.success = result.failures.is_empty()
	return result

func _mail_pet_medal_counts(pet_data: Dictionary) -> Dictionary:
	var raw: Variant = pet_data.get("medal_counts", {}) if pet_data is Dictionary else {}
	if not (raw is Dictionary):
		return {"brave": 0, "calm": 0, "bold": 0}
	var src: Dictionary = raw
	return {
		"brave": clampi(int(src.get("brave", 0)), 0, 5), 
		"calm": clampi(int(src.get("calm", 0)), 0, 5), 
		"bold": clampi(int(src.get("bold", 0)), 0, 5), 
	}

func _build_mail_pet_skill_slots(pet_data: Dictionary) -> Array:
	var out: Array = []
	if not (pet_data is Dictionary):
		return out
	var raw_skills: Variant = pet_data.get("skills", pet_data.get("skill_slots", []))
	if not (raw_skills is Array):
		return out
	var slot_cap: = 5
	var idx: int = 0
	for one in raw_skills:
		if idx >= slot_cap:
			break
		if not (one is Dictionary):
			continue
		var sd: Dictionary = one as Dictionary
		var lv: int = maxi(1, int(sd.get("level", 1)))
		var skill_key: String = str(sd.get("skill_key", "")).strip_edges()
		if skill_key.is_empty():
			skill_key = str(sd.get("key", "")).strip_edges()
		if skill_key.is_empty():
			var n: String = str(sd.get("name", sd.get("skill_name", ""))).strip_edges()
			if n == "溅射":
				skill_key = "splash_lv2" if lv >= 2 else "splash_lv1"
		var cfg: Dictionary = {}
		if not skill_key.is_empty():
			cfg = GameData.PET_SKILLS.get(skill_key, {})
		var skill_id: String = str(sd.get("skill_id", sd.get("id", cfg.get("skill_id", "")))).strip_edges()
		var skill_name: String = str(sd.get("skill_name", sd.get("name", cfg.get("name", "")))).strip_edges()
		if skill_key.is_empty() and skill_id.is_empty() and skill_name.is_empty():
			continue
		out.append({
			"slot": idx + 1, 
			"skill_key": skill_key, 
			"skill_id": skill_id, 
			"skill_name": skill_name, 
			"level": lv
		})
		idx += 1
	return out

func _parse_sealed_suit_by_name(item_name: String) -> Dictionary:
	var result = {"success": false, "data": {}}
	if item_name.is_empty():
		return result


	const TAG_FW: = "（封印）"
	const TAG_ASC: = "(封印)"
	var clean_name: = item_name.replace(TAG_FW, TAG_ASC)
	if not clean_name.ends_with(TAG_ASC):
		return result

	var core_name: = clean_name.replace(TAG_ASC, "")
	var slot_map: Dictionary = {}
	for slot_en in ["weapon", "helmet", "armor", "boots", "accessory"]:
		slot_map[SuitDatabaseDetailed.get_slot_name(slot_en)] = slot_en

	var matched_slot_cn = ""
	var matched_slot = ""
	for slot_cn in slot_map.keys():
		if core_name.ends_with(slot_cn):
			matched_slot_cn = slot_cn
			matched_slot = slot_map[slot_cn]
			break
	if matched_slot.is_empty():
		return result

	var suit_name = core_name.substr(0, core_name.length() - matched_slot_cn.length())
	if suit_name.is_empty():
		return result

	var SuitDatabaseDetailed = load("res://scripts/data/suit_database_detailed.gd")
	if SuitDatabaseDetailed == null:
		return result

	for suit_level in SuitDatabaseDetailed.get_all_suit_levels():
		if SuitDatabaseDetailed.get_suit_name(suit_level) == suit_name:
			var sealed_data = SuitDatabaseDetailed.generate_sealed_suit(suit_level, matched_slot)
			sealed_data["name"] = clean_name
			result.success = true
			result.data = sealed_data
			return result

	return result

func _add_sealed_suit_from_mail(sealed_data: Dictionary, count: int = 1) -> Dictionary:
	var result: = {"success": true, "added": 0, "failed": 0}
	var gm = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.success = false
		result.failed = max(1, count)
		return result
	var inv = gm.inventory_manager
	var add_count = max(1, count)
	var data_copy: Dictionary = sealed_data.duplicate(true)
	for _i in range(add_count):
		var add_res: Dictionary = inv.add_item("sealed_suit", 1, data_copy)
		if bool(add_res.get("success", false)):
			result.added += 1
		else:
			push_warning("[MailManager] 封印套装添加失败：%s" % str(add_res.get("message", "背包已满")))
			result.failed += 1
	result.success = result.failed == 0
	return result

func _get_sealed_suit_display_name_from_data(sealed_data: Dictionary) -> String:
	var suit_level = int(sealed_data.get("suit_level", -1))
	var slot = String(sealed_data.get("slot", ""))
	var suit_db = load("res://scripts/data/suit_database_detailed.gd")
	if suit_db != null and suit_level > 0 and slot != "":
		return suit_db.get_sealed_suit_display_name(suit_level, slot)
	return String(sealed_data.get("name", "未知封印套装"))

func _format_attachment_failures(failures: Array) -> String:
	if failures.is_empty():
		return "无失败项"
	var lines: Array = []
	var max_lines = min(5, failures.size())
	for i in range(max_lines):
		lines.append("- %s" % str(failures[i]))
	if failures.size() > max_lines:
		lines.append("- ... 还有 %d 项" % int(failures.size() - max_lines))
	return "\n".join(lines)

func _format_batch_apply_failures(entries: Array) -> String:
	if entries.is_empty():
		return "无失败项"
	var lines: Array = []
	var shown = 0
	for entry in entries:
		if shown >= 5:
			break
		var mail_id = int(entry.get("mail_id", 0))
		var failures = entry.get("failures", [])
		var first_reason = "未知错误"
		if failures is Array and not failures.is_empty():
			first_reason = str(failures[0])
		lines.append("邮件#%d: %s" % [mail_id, first_reason])
		shown += 1
	if entries.size() > shown:
		lines.append("... 还有 %d 封邮件" % int(entries.size() - shown))
	return "\n".join(lines)

func start_expire_check() -> void :
	_expire_check_timer.start()

func stop_expire_check() -> void :
	_expire_check_timer.stop()

func _on_expire_check_timer() -> void :
	var expired_ids = []
	for i in range(_mails.size() - 1, -1, -1):
		if _mails[i].is_expired():
			expired_ids.append(_mails[i].id)
			_mails.remove_at(i)
	if not expired_ids.is_empty():
		print("[MailManager] 已移除 %d 封过期邮件" % expired_ids.size())
		mail_list_updated.emit(_mails.duplicate())


func _trigger_post_claim_cloud_sync(claimed_entries: Array = []) -> void :
	var gm = GameManager.instance
	if gm == null:
		return
	if gm.has_method("save_game"):
		gm.call("save_game", false, "mail_claim_local_persist")
	await get_tree().create_timer(0.5).timeout
	if gm == null:
		return
	var need_full_authority_upload: = _mail_claim_requires_full_authority_upload(claimed_entries)
	if need_full_authority_upload:
		if gm.has_method("force_cloud_upload_and_wait"):
			await gm.force_cloud_upload_and_wait("mail_claim_finalize_full_sync", false)
		elif gm.has_method("save_local_and_force_cloud_upload_with_reason"):
			gm.call("save_local_and_force_cloud_upload_with_reason", "mail_claim_finalize_full_sync")
		elif gm.has_method("save_local_and_force_cloud_upload"):
			gm.call("save_local_and_force_cloud_upload")
		elif gm.has_method("upload_cloud_save"):
			gm.call("upload_cloud_save", true)
	else:
		if gm.has_method("save_local_and_force_cloud_upload_authority_compact_with_reason"):
			gm.call("save_local_and_force_cloud_upload_authority_compact_with_reason", "mail_claim_finalize_compact_sync")
		elif gm.has_method("save_local_and_force_cloud_upload_authority_compact"):
			gm.call("save_local_and_force_cloud_upload_authority_compact")
		elif gm.has_method("upload_cloud_save"):
			gm.call("upload_cloud_save", true)



func create_local_mail(title: String, content: String, attachments: Dictionary = {}, expire_days: int = 7) -> void :
	var normalized_attachments: Dictionary = attachments.duplicate(true) if attachments is Dictionary else {}
	if _attachments_contain_authority_sensitive_pet_reward(normalized_attachments):
		push_warning("[AuthorityGuard] 阻止创建包含宠物奖励的本地邮件：" + title)
		return
	var mail = MailData.new()
	mail.id = _generate_local_mail_id()
	mail.title = title
	mail.content = content
	mail.sender = "系统"
	mail.is_read = false
	mail.is_claimed = false
	mail.created_at = int(Time.get_unix_time_from_system())
	if expire_days > 0:
		mail.expire_at = mail.created_at + expire_days * 86400
	mail.attachments = normalized_attachments

	_mails.insert(0, mail)
	_save_local_mail_cache()
	mail_list_updated.emit(_mails)
	unread_count += 1
	new_mail_received.emit(mail)
	print("[MailManager] 创建本地邮件: ", title)

var _local_mail_id_counter: int = -1

func _attachments_contain_authority_sensitive_pet_reward(attachments: Dictionary) -> bool:
	if attachments.is_empty():
		return false
	if str(attachments.get("type", "")) == "pet":
		return true
	if attachments.has("pet_id") or attachments.has("petId"):
		return true
	var items_variant: Variant = attachments.get("items", [])
	if items_variant is Array:
		for raw_item in items_variant:
			if not (raw_item is Dictionary):
				continue
			var item_dict: Dictionary = raw_item
			if str(item_dict.get("type", "")) == "pet":
				return true
			if item_dict.has("pet_id") or item_dict.has("petId"):
				return true
	return false

func _generate_local_mail_id() -> int:
	_local_mail_id_counter -= 1
	return _local_mail_id_counter

func _save_local_mail_cache() -> void :
	var rows: Array = []
	for m in _mails:
		if m == null or m.id >= 0:
			continue
		rows.append({
			"id": int(m.id), 
			"title": String(m.title), 
			"content": String(m.content), 
			"sender": String(m.sender), 
			"is_read": bool(m.is_read), 
			"is_claimed": bool(m.is_claimed), 
			"created_at": int(m.created_at), 
			"expire_at": int(m.expire_at), 
			"attachments": (m.attachments.duplicate(true) if m.attachments is Dictionary else {}), 
		})
	var cfg: = ConfigFile.new()
	cfg.set_value("mail", "local_mails", rows)
	var err = cfg.save(LOCAL_MAIL_CACHE_PATH)
	if err != OK:
		push_warning("[MailManager] 保存本地邮件缓存失败: %s" % str(err))

func _load_local_mail_cache() -> void :
	var cfg: = ConfigFile.new()
	var err = cfg.load(LOCAL_MAIL_CACHE_PATH)
	if err != OK:
		return
	var rows: Variant = cfg.get_value("mail", "local_mails", [])
	if not (rows is Array):
		return
	var loaded: Array[MailData] = []
	var min_local_id: = -1
	for one in rows:
		if not (one is Dictionary):
			continue
		var d: Dictionary = one
		var mail: = MailData.new()
		mail.id = int(d.get("id", 0))
		if mail.id >= 0:
			continue
		mail.title = String(d.get("title", ""))
		mail.content = String(d.get("content", ""))
		mail.sender = String(d.get("sender", "系统"))
		mail.is_read = bool(d.get("is_read", false))
		mail.is_claimed = bool(d.get("is_claimed", false))
		mail.created_at = int(d.get("created_at", int(Time.get_unix_time_from_system())))
		mail.expire_at = int(d.get("expire_at", 0))
		var at = d.get("attachments", {})
		mail.attachments = at.duplicate(true) if at is Dictionary else {}
		if mail.is_expired():
			continue
		if mail.id < min_local_id:
			min_local_id = mail.id
		loaded.append(mail)

	if not loaded.is_empty():
		for lm in loaded:
			_mails.append(lm)
		_local_mail_id_counter = min(_local_mail_id_counter, min_local_id - 1)


func send_item_drop_mail(title: String, items: Array, gold: int = 0) -> void :
	print("[MailManager] send_item_drop_mail 调用, title=", title, ", items=", items.size())
	var content = "您在战斗中获得了以下奖励"
	var attachments: Dictionary = {}

	if gold > 0:
		attachments["gold"] = gold
		content += "\n金币: %s" % _format_number(gold)

	if items.size() > 0:
		attachments["items"] = items
		for item in items:
			if item is Dictionary:
				content += "\n%s x%d" % [item.get("name", "未知物品"), item.get("count", 1)]

	print("[MailManager] 创建本地邮件")
	create_local_mail(title, content, attachments, 7)


func _send_server_mail(title: String, content: String, attachments: Dictionary, expire_days: int = 0) -> void :
	_sync_mail_api_base_from_network()
	var http = HTTPRequest.new()
	var http_parent = _api.get_http_parent()
	if http_parent:
		http_parent.add_child(http)
	else:
		return

	var body = {
		"title": title, 
		"content": content, 
		"attachments": attachments, 
		"expire_days": expire_days
	}

	var headers = [
		"Content-Type: application/json", 
		"Authorization: Bearer " + _get_auth_token(), 
		"X-Client-Version: %s" % _api.get_resolved_client_version_header(), 
	]

	var url = _api.get_effective_api_base() + "/mail/self"
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

	http.request_completed.connect( func(result, response_code, headers, body):
		if response_code == 200:
			print("[MailManager] 服务器邮件发送成功，刷新列表: ", title)
			refresh_mail_list()
		else:
			print("[MailManager] 服务器邮件发送失败，回退到本地邮件")
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.data
				var error = data.get("error", "未知错误")
				print("[MailManager] 错误: ", error)
			create_local_mail(title, content, attachments, expire_days)
		http.queue_free()
	, CONNECT_ONE_SHOT)

func _format_number(num: int) -> String:
	if num >= 100000000:
		return "%.1f亿" % (num / 100000000.0)
	elif num >= 10000:
		return "%.1f万" % (num / 10000.0)
	return str(num)



func get_mail_expire_description(mail: MailData) -> String:
	if not mail.has_expire_time():
		return ""

	var remaining = mail.expire_at - int(Time.get_unix_time_from_system())
	if remaining <= 0:
		return "已过期"

	var days = remaining / 86400
	var hours = (remaining % 86400) / 3600
	var minutes = (remaining % 3600) / 60

	if days > 0:
		return "%d天后过期" % days
	elif hours > 0:
		return "%d小时后过期" % hours
	else:
		return "%d分钟后过期" % minutes


func extend_mail_expire(mail_id: int, extend_days: int) -> bool:
	var mail = get_mail_by_id(mail_id)
	if mail == null:
		return false

	if mail.expire_at == 0:
		mail.expire_at = int(Time.get_unix_time_from_system()) + extend_days * 86400
	else:
		mail.expire_at += extend_days * 86400

	mail_list_updated.emit(_mails)
	return true
