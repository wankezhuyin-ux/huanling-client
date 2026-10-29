extends Node



func _apply_pet_skill_save_data_if_present(data: Dictionary) -> void :
	var gm: = GameManager.instance
	if gm == null:
		return
	var sd: Variant = data.get("saveData", null)
	if sd is Dictionary and not (sd as Dictionary).is_empty():

		gm.apply_cloud_save(sd as Dictionary, {
			"pets_authoritative": true, 
			"preserve_local_pets_not_in_cloud": true, 
			"skip_pet_collection_trim": true, 
			"skip_pet_progress_merge": true, 
		})


func _apply_skill_slots_to_pet_by_id(pet_id: String, skill_slots: Array, clear_all_slots: bool = false) -> void :
	var gm: = GameManager.instance
	if gm == null or gm.pet_manager == null:
		return
	var sid: = str(pet_id).strip_edges()
	if sid.is_empty():
		return
	var target = gm.pet_manager.get_pet_by_stable_id(sid)
	if target == null:
		return
	var slot_count: = 3
	if target.has_method("get_skill_slot_count"):
		slot_count = int(target.get_skill_slot_count())
	slot_count = clampi(slot_count, 1, 5)
	if target.has_method("normalize_skill_slots"):
		target.normalize_skill_slots()
	var limit: = slot_count if clear_all_slots else mini(slot_count, skill_slots.size())
	if limit <= 0 and not clear_all_slots:
		return
	for k in range(slot_count if clear_all_slots else limit):
		var slot: Variant = null
		if k < skill_slots.size():
			slot = skill_slots[k]
		if slot != null and slot is Dictionary:
			var d: = slot as Dictionary
			if not str(d.get("skill_key", "")).strip_edges().is_empty():
				target.set_skill_to_slot(k, d)
			elif bool(d.get("slot_locked", false)):

				target.set_skill_to_slot(k, {"slot_locked": true})
			elif clear_all_slots:
				target.set_skill_to_slot(k, {})
		elif clear_all_slots:
			target.set_skill_to_slot(k, {})


func _sync_yuanbao_from_pet_skill_response(data: Dictionary) -> void :
	var gm: = GameManager.instance
	if gm == null or gm.player == null:
		return
	var server_yb: = -1
	var sd: Variant = data.get("saveData", null)
	if sd is Dictionary:
		var pd: Variant = (sd as Dictionary).get("playerData", null)
		if pd is Dictionary and (pd as Dictionary).has("yuanbao_currency"):
			server_yb = maxi(0, int((pd as Dictionary).get("yuanbao_currency", 0)))
	if server_yb < 0 and data.has("deducted_yuanbao"):
		server_yb = maxi(0, int(gm.player.yuanbao_currency) - maxi(0, int(data.get("deducted_yuanbao", 0))))
	if server_yb < 0:
		return
	if int(gm.player.yuanbao_currency) == server_yb:
		return
	gm.player.yuanbao_currency = server_yb
	gm.yuanbao_changed.emit(gm.player.yuanbao_currency)

func _should_defer_restore_on_duplicate_or_idem(err: String) -> bool:
	var es: = str(err)
	return es.find("已执行") >= 0 or es.find("重复") >= 0 or es.find("请勿重复") >= 0




















































signal synthetic_success(data: Dictionary)



signal synthetic_failed(error_msg: String)











signal learn_success(data: Dictionary)



signal learn_failed(error_msg: String)











signal unlearn_success(data: Dictionary)



signal unlearn_failed(error_msg: String)



signal slot_lock_success(data: Dictionary)



signal slot_lock_failed(error_msg: String)











signal sync_success(data: Dictionary)



signal sync_failed(error_msg: String)







signal level_up_success(data: Dictionary)



signal level_up_failed(error_msg: String)























const ACTION_TYPE = {



	"synthetic": "synthetic", 



	"learn": "learn", 



	"unlearn": "unlearn", 



	"level_up": "level_up"



}























func request_synthetic_book(book_name: String, book_count: int) -> void :



	if not GameManager.instance or not GameManager.instance.network:



		print("[PetSkillManager] 网络层不存在，无法发送合成请求")



		return







	var network = GameManager.instance.network

	var operation_id: = "pet_skill_synthetic_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

	network.pet_skill_synthetic_success.connect(_on_synthetic_success, CONNECT_ONE_SHOT)



	network.pet_skill_synthetic_failed.connect(_on_synthetic_failed, CONNECT_ONE_SHOT)







	network.request_pet_skill_synthetic(book_name, book_count, operation_id)























func request_learn_skill(book_name: String, pet_id: String) -> void :



	if not GameManager.instance or not GameManager.instance.network:



		print("[PetSkillManager] 网络层不存在，无法发送学习请求")



		return







	var network = GameManager.instance.network

	var operation_id: = "pet_skill_learn_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

	network.pet_skill_learn_success.connect(_on_learn_success, CONNECT_ONE_SHOT)



	network.pet_skill_learn_failed.connect(_on_learn_failed, CONNECT_ONE_SHOT)







	network.request_pet_skill_learn(book_name, pet_id, operation_id)























func request_level_up_skill(book_name: String, pet_id: String) -> void :



	if not GameManager.instance or not GameManager.instance.network:



		print("[PetSkillManager] 网络层不存在，无法发送升级请求")



		return







	var network = GameManager.instance.network

	var operation_id: = "pet_skill_level_up_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

	network.pet_skill_level_up_success.connect(_on_level_up_success, CONNECT_ONE_SHOT)



	network.pet_skill_level_up_failed.connect(_on_level_up_failed, CONNECT_ONE_SHOT)







	network.request_pet_skill_level_up(book_name, pet_id, operation_id)



















func request_unlearn_skill(pet_id: String, slot_index: int) -> void :



	if not GameManager.instance or not GameManager.instance.network:



		print("[PetSkillManager] 网络层不存在，无法发送卸载请求")



		return







	var network = GameManager.instance.network

	var operation_id: = "pet_skill_unlearn_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

	network.pet_skill_unlearn_success.connect(_on_unlearn_success, CONNECT_ONE_SHOT)



	network.pet_skill_unlearn_failed.connect(_on_unlearn_failed, CONNECT_ONE_SHOT)







	network.request_pet_skill_unlearn(pet_id, slot_index, operation_id)



func request_lock_skill_slot(pet_id: String, slot_index: int, locked: bool) -> void :
	if not GameManager.instance or not GameManager.instance.network:
		print("[PetSkillManager] network missing, cannot lock skill slot")
		return
	var network = GameManager.instance.network
	var operation_id: = "pet_skill_slot_lock_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	network.pet_skill_slot_lock_success.connect(_on_slot_lock_success, CONNECT_ONE_SHOT)
	network.pet_skill_slot_lock_failed.connect(_on_slot_lock_failed, CONNECT_ONE_SHOT)
	network.request_pet_skill_slot_lock(pet_id, slot_index, locked, operation_id)
























func request_sync_pet_skills(pet_id: String) -> void :



	if not GameManager.instance or not GameManager.instance.network:



		print("[PetSkillManager] 网络层不存在，无法同步技能数据")



		return







	var network = GameManager.instance.network



	var operation_id = "pet_skill_sync_%d" % Time.get_ticks_msec()







	network.pet_skill_sync_success.connect(_on_sync_success, CONNECT_ONE_SHOT)



	network.pet_skill_sync_failed.connect(_on_sync_failed, CONNECT_ONE_SHOT)







	network.request_pet_skill_sync(pet_id, operation_id)



































func _on_synthetic_success(data: Dictionary) -> void :
	print("[PetSkillManager] 合成技能书成功: ", data)
	_apply_pet_skill_save_data_if_present(data)
	synthetic_success.emit(data)















func _on_synthetic_failed(error_msg: String) -> void :



	print("[PetSkillManager] 合成技能书失败: ", error_msg)



	synthetic_failed.emit(error_msg)















func _on_learn_success(data: Dictionary) -> void :
	print("[PetSkillManager] 学习技能成功: ", data)
	_apply_pet_skill_save_data_if_present(data)
	var sid: = str(data.get("pet_id", "")).strip_edges()
	var skill_slots_raw: Variant = data.get("skill_slots", [])
	var skill_slots: Array = skill_slots_raw if skill_slots_raw is Array else []
	_apply_skill_slots_to_pet_by_id(sid, skill_slots, false)
	learn_success.emit(data)







func _on_learn_failed(error_msg: String) -> void :
	print("[PetSkillManager] 学习技能失败: ", error_msg)
	if _should_defer_restore_on_duplicate_or_idem(error_msg):
		var gm: = GameManager.instance
		if gm and gm.has_method("download_cloud_save"):
			gm.call_deferred("download_cloud_save")
	learn_failed.emit(error_msg)















func _on_unlearn_success(data: Dictionary) -> void :
	print("[PetSkillManager] 卸载技能成功: ", data)
	_apply_pet_skill_save_data_if_present(data)
	var sid: = str(data.get("pet_id", "")).strip_edges()
	var gm = GameManager.instance
	var skill_slots_raw: Variant = data.get("skill_slots", null)

	if skill_slots_raw is Array and (skill_slots_raw as Array).size() >= 1:
		var skill_slots: Array = skill_slots_raw
		var occupied: = 0
		for s in skill_slots:
			if s != null and s is Dictionary and not str((s as Dictionary).get("skill_key", "")).strip_edges().is_empty():
				occupied += 1

		var slot_capacity: = 3
		var target_for_cap = gm.pet_manager.get_pet_by_stable_id(sid) if gm and gm.pet_manager else null
		if target_for_cap != null and target_for_cap.has_method("get_skill_slot_count"):
			slot_capacity = clampi(int(target_for_cap.get_skill_slot_count()), 1, 5)
		if skill_slots.size() >= slot_capacity:
			_apply_skill_slots_to_pet_by_id(sid, skill_slots, true)
		elif occupied > 0:
			_apply_skill_slots_to_pet_by_id(sid, skill_slots, false)
	_sync_yuanbao_from_pet_skill_response(data)
	if gm and gm.inventory_manager:
		gm.inventory_manager.inventory_changed.emit()
	unlearn_success.emit(data)















func _on_unlearn_failed(error_msg: String) -> void :



	print("[PetSkillManager] 卸载技能失败: ", error_msg)



	unlearn_failed.emit(error_msg)













func _on_slot_lock_success(data: Dictionary) -> void :
	print("[PetSkillManager] skill slot lock ok: ", data)
	_apply_pet_skill_save_data_if_present(data)
	var sid: = str(data.get("pet_id", "")).strip_edges()
	var skill_slots_raw: Variant = data.get("skill_slots", null)
	if skill_slots_raw is Array and (skill_slots_raw as Array).size() >= 1:
		var skill_slots: Array = skill_slots_raw
		var gm = GameManager.instance
		var slot_capacity: = 3
		var target_for_cap = gm.pet_manager.get_pet_by_stable_id(sid) if gm and gm.pet_manager else null
		if target_for_cap != null and target_for_cap.has_method("get_skill_slot_count"):
			slot_capacity = clampi(int(target_for_cap.get_skill_slot_count()), 1, 5)
		if skill_slots.size() >= slot_capacity:
			_apply_skill_slots_to_pet_by_id(sid, skill_slots, true)
		else:
			_apply_skill_slots_to_pet_by_id(sid, skill_slots, false)
	slot_lock_success.emit(data)

func _on_slot_lock_failed(error_msg: String) -> void :
	print("[PetSkillManager] skill slot lock failed: ", error_msg)
	slot_lock_failed.emit(error_msg)







func _on_sync_success(data: Dictionary) -> void :



	print("[PetSkillManager] 同步宠物技能成功: ", data)



	sync_success.emit(data)















func _on_sync_failed(error_msg: String) -> void :



	print("[PetSkillManager] 同步宠物技能失败: ", error_msg)



	sync_failed.emit(error_msg)















func _on_level_up_success(data: Dictionary) -> void :
	print("[PetSkillManager] 升级技能成功: ", data)
	_apply_pet_skill_save_data_if_present(data)
	var sid: = str(data.get("pet_id", "")).strip_edges()
	var skill_slots_raw: Variant = data.get("skill_slots", [])
	var skill_slots: Array = skill_slots_raw if skill_slots_raw is Array else []
	_apply_skill_slots_to_pet_by_id(sid, skill_slots, false)
	level_up_success.emit(data)







func _on_level_up_failed(error_msg: String) -> void :
	print("[PetSkillManager] 升级技能失败: ", error_msg)
	if _should_defer_restore_on_duplicate_or_idem(error_msg):
		var gm: = GameManager.instance
		if gm and gm.has_method("download_cloud_save"):
			gm.call_deferred("download_cloud_save")
	level_up_failed.emit(error_msg)
