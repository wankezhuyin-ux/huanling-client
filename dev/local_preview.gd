extends Node

func _ready() -> void:
	var ui_scene := load("res://ui/ink_home.tscn") as PackedScene
	if ui_scene == null:
		push_error("LOCAL_PREVIEW: main UI failed to load")
		get_tree().quit(1)
		return
	var ui = ui_scene.instantiate()
	add_child(ui)
	await get_tree().process_frame
	if ui.game_manager == null:
		push_error("LOCAL_PREVIEW: game manager failed")
		get_tree().quit(1)
		return
	var gm = ui.game_manager
	if not gm.initialize(true):
		get_tree().quit(1)
		return
	var isolated_qa: bool = "--auto-entry-test" in OS.get_cmdline_user_args() or "--full-audit-test" in OS.get_cmdline_user_args() or "--smoke" in OS.get_cmdline_user_args() or "--save-write-test" in OS.get_cmdline_user_args() or "--shop-test" in OS.get_cmdline_user_args() or "--item-test" in OS.get_cmdline_user_args() or "--buff-test" in OS.get_cmdline_user_args() or "--lottery-test" in OS.get_cmdline_user_args()
	if not isolated_qa and gm.has_local_slot():
		if not gm.load_game():
			push_error("本地存档及备份均无法读取，已保留文件，停止启动以避免覆盖")
			get_tree().quit(1)
			return
	else:
		gm.pet_manager.create_initial_pet()
		gm._init_new_player_resources()
		gm.player.player_name = "本地联调"
	gm.enable_local_saving()
	if "--apply-local-credit" in OS.get_cmdline_user_args():
		print("LOCAL_CREDIT=" + JSON.stringify({"gold": gm.player.gold, "yuanbao": gm.player.yuanbao_currency, "saved": gm.save_game()}))
		get_tree().quit()
		return
	ui.auto_battle = false
	gm.set_auto_battle_enabled(false)
	await ui._start_game()
	if "--auto-entry-test" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var started: bool = ui.auto_battle and gm.in_battle and not gm.battle_system.monsters.is_empty()
		print("AUTO_ENTRY_TEST=" + str(started))
		get_tree().quit(0 if started else 1)
		return
	if "--full-audit-test" in OS.get_cmdline_user_args():
		await load("res://dev/full_audit_test.gd").run(ui, gm)
		return
	if "--lottery-test" in OS.get_cmdline_user_args() or "--lottery-read-test" in OS.get_cmdline_user_args():
		await _run_lottery_test(ui, gm)
		return
	if "--buff-test" in OS.get_cmdline_user_args() or "--buff-read-test" in OS.get_cmdline_user_args():
		await _run_buff_test(ui, gm)
		return
	if "--item-test" in OS.get_cmdline_user_args() or "--item-read-test" in OS.get_cmdline_user_args():
		await _run_item_test(ui, gm)
		return
	if "--shop-test" in OS.get_cmdline_user_args() or "--shop-read-test" in OS.get_cmdline_user_args():
		await _run_shop_test(ui, gm)
		return
	if "--save-write-test" in OS.get_cmdline_user_args() or "--save-read-test" in OS.get_cmdline_user_args():
		await _run_local_save_test(ui, gm)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var report: Dictionary = ui._ink_layout_report()
	print("INK_LAYOUT=" + JSON.stringify(report))
	if not report.nav_inside_viewport:
		push_error("INK_LAYOUT: navigation overflows viewport")
	var check_file := FileAccess.open(_local_output_path("界面布局检查.json"), FileAccess.WRITE)
	if check_file:
		check_file.store_string(JSON.stringify(report, "  "))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture := get_viewport().get_texture().get_image()
		capture.save_png(_local_output_path("本地主界面运行截图.png"))
	print("LOCAL_PREVIEW_READY starter=" + str(gm.pet_manager.active_pet.pet_id if gm.pet_manager.active_pet != null else "none"))
	if DisplayServer.get_name() != "headless" and FileAccess.file_exists(_local_output_path("../work/audit-visual.request")):
		await ui._ink_open_city_detail("_on_warehouse_btn_pressed")
		for i in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_local_output_path("本地功能测试界面.png"))
		var state := {"level": gm.player.level, "gold": gm.player.gold, "yuanbao": gm.player.yuanbao_currency, "pending_auto_points": gm.player.pending_auto_points, "auto_plan": gm.player.auto_allocation_plan, "attack": gm.player.get_attack(), "defense": gm.player.get_defense(), "double_exp": gm.local_double_exp_count()}
		FileAccess.open(_local_output_path("修复版真实存档启动检查.json"), FileAccess.WRITE).store_string(JSON.stringify(state, "  "))
		DirAccess.remove_absolute(_local_output_path("../work/audit-visual.request"))
	if DisplayServer.get_name() != "headless" and FileAccess.file_exists(_local_output_path("../work/lottery-visual.request")):
		await ui._ink_open_city_detail("_on_lucky_draw_btn_pressed")
		for i in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_local_output_path("幸运抽奖本地界面.png"))
		DirAccess.remove_absolute(_local_output_path("../work/lottery-visual.request"))
	if DisplayServer.get_name() != "headless" and FileAccess.file_exists(_local_output_path("../work/buff-visual.request")):
		ui._ink_enter("battle")
		ui._ink_refresh()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_local_output_path("经验丹四倍效果界面.png"))
		DirAccess.remove_absolute(_local_output_path("../work/buff-visual.request"))
	if DisplayServer.get_name() != "headless" and FileAccess.file_exists(_local_output_path("../work/item-visual.request")):
		ui._ink_enter("bag")
		await get_tree().process_frame
		for entry in gm.inventory_manager.items:
			if entry.name == "双倍经验丹(周)":
				ui._show_item_action_popup(entry)
				break
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_local_output_path("本地道具使用界面.png"))
		DirAccess.remove_absolute(_local_output_path("../work/item-visual.request"))
	if DisplayServer.get_name() != "headless" and FileAccess.file_exists(_local_output_path("../work/shop-visual.request")):
		await ui._ink_open_city_detail("_on_shop_btn_pressed")
		for i in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_local_output_path("本地商城运行截图.png"))
		DirAccess.remove_absolute(_local_output_path("../work/shop-visual.request"))

	if FileAccess.file_exists(_local_output_path("snapshot-visual.request")) or "--snapshot-audit" in OS.get_cmdline_user_args():
		# 线上数据快照页面检查：排行榜 / 世界传闻 / 七日签到
		# headless 下把面板文字打进日志（便于无窗口校验），有窗口时另存截图
		for key in ["ranking", "world", "signin7", "online_rules", "online_modules"]:
			var panel = load("res://dev/local_feature_ui.gd").create_fullscreen(gm, key)
			ui.add_child(panel)
			for i in range(3):
				await get_tree().process_frame
			if DisplayServer.get_name() == "headless":
				var texts: Array = []
				for node in panel.find_children("*", "Label", true, false):
					texts.append(str(node.text))
				print("SNAPSHOT_PANEL=" + key + "|labels=" + str(texts.size()))
				var show_max := 48 if key == "online_rules" else (26 if key == "online_modules" else 10)
				for i in range(mini(show_max, texts.size())):
					print("  [" + key + "] " + str(texts[i]))
			else:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(_local_output_path("线上快照-%s.png" % key))
			panel.queue_free()
			await get_tree().process_frame
		DirAccess.remove_absolute(_local_output_path("snapshot-visual.request"))
	if "--smoke" in OS.get_cmdline_user_args() or FileAccess.file_exists(_local_output_path("../work/layout-qa.request")):
		for tab in ["character", "pet", "bag", "battle"]:
			ui._ink_enter(tab)
			await get_tree().process_frame
			print("LOCAL_TAB_OK=" + tab)
			if DisplayServer.get_name() != "headless" and tab == "battle":
				await RenderingServer.frame_post_draw
				var battle_capture := get_viewport().get_texture().get_image()
				battle_capture.save_png(_local_output_path("本地历练页面截图.png"))
		if "--battle-smoke" in OS.get_cmdline_user_args():
			ui._ink_enter("battle")
			var progression_test: bool = "--progression-smoke" in OS.get_cmdline_user_args()
			var pet = gm.pet_manager.get_active_pet()
			if progression_test:
				gm.player.experience = gm.player.get_required_exp() - 1
				pet.experience = gm.pet_manager._get_pet_max_exp(pet.level) - 1
			var started: bool = ui._start_auto_battle()
			if progression_test:
				# Low-HP fixture tests real kill -> settlement -> threshold crossing.
				for enemy in gm.battle_system.monsters:
					enemy.hp = 1
			await get_tree().process_frame
			var actors: bool = is_instance_valid(ui._battle_player_wrap) and is_instance_valid(ui._battle_pet_wrap)
			var deer_facing_right: bool = ui._battle_pet_sprite != null and ui._battle_pet_sprite.scale.x > 0
			var hp_before: int = gm.battle_system.monsters[0].hp if not gm.battle_system.monsters.is_empty() else 0
			var hp_changed := false
			var deadline := Time.get_ticks_msec() + 60000
			while gm.in_battle and Time.get_ticks_msec() < deadline:
				gm.battle_system.execute_turn()
				for enemy in gm.battle_system.monsters:
					if enemy.hp < enemy.max_hp:
						hp_changed = true
				await get_tree().create_timer(0.05).timeout
			var result := {"started": started, "ally_actors": actors, "enemies": gm.battle_system.monsters.size(), "enemy_initial_hp": hp_before, "damage_observed": hp_changed, "rounds": gm.battle_system.current_round, "finished": not gm.in_battle}
			if progression_test:
				result["player_level"] = gm.player.level
				result["pet_level"] = pet.level
				var before_repeat := [gm.player.level, gm.player.experience, pet.level, pet.experience]
				gm._local_battle_finished(true)
				result["no_duplicate_exp"] = before_repeat == [gm.player.level, gm.player.experience, pet.level, pet.experience]
				var sprite = ui._battle_pet_sprite
				result["deer_faces_right"] = deer_facing_right
				result["progression_ok"] = gm.player.level > 1 and pet.level > 1 and result["no_duplicate_exp"] and result["deer_faces_right"]
			print("LOCAL_BATTLE_QA=" + JSON.stringify(result))
			var report_file := FileAccess.open(_local_output_path("本地战斗检查.json"), FileAccess.WRITE)
			report_file.store_string(JSON.stringify(result, "  "))
			get_tree().quit(0 if started and actors and hp_changed and not gm.in_battle and (not progression_test or result["progression_ok"]) else 1)
		ui._ink_show_home()
		await get_tree().process_frame
		print("LOCAL_HOME_RETURN_OK=" + str(ui.get_node("InkHome").visible))
		DirAccess.remove_absolute(_local_output_path("../work/layout-qa.request"))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var screenshot := get_viewport().get_texture().get_image()
			var result := screenshot.save_png(_local_output_path("本地主界面运行截图.png"))
			print("LOCAL_SCREENSHOT_OK=" + str(result == OK))

func _local_output_path(filename: String) -> String:
	var executable := OS.get_executable_path()
	if executable.contains(".app/Contents/MacOS/"):
		return executable.get_base_dir().path_join("../../..").simplify_path().path_join(filename)
	return ProjectSettings.globalize_path("res://../../outputs/" + filename)


func _save_test_snapshot(gm) -> Dictionary:
	var p = gm.player
	var pet = gm.pet_manager.get_active_pet()
	return {"level": p.level, "exp": p.experience, "attack": p.attack_base, "points": p.points, "pending": p.pending_auto_points, "plan": p.auto_allocation_plan, "auto": p.auto_allocation_enabled, "pet_id": pet.id, "pet_level": pet.level, "pet_exp": pet.experience, "items": gm.inventory_manager.get_item_count("解封石"), "gold": p.gold, "map": gm.current_map}

func _run_local_save_test(ui, gm) -> void:
	var expected_path: String = gm.local_slot_path() + ".expected"
	if "--save-write-test" in OS.get_cmdline_user_args():
		var attack_before: int = gm.player.attack_base
		var points_before: int = gm.player.points
		await ui._player_attr_spend_async("add_attack", 3)
		var valid_spend: bool = gm.player.attack_base == attack_before + 3 and gm.player.points == points_before - 3
		await ui._player_attr_spend_async("add_attack", 999999)
		var rejects_overspend: bool = gm.player.attack_base == attack_before + 3
		gm.player.add_exp(gm.player.get_required_exp(), false)
		gm.pet_manager.add_pet_exp(gm.pet_manager.get_active_pet(), gm.pet_manager._get_pet_max_exp(1), false)
		gm.inventory_manager.add_item("解封石", 3)
		await ui._player_attr_save_auto_plan_async(true, {"vitality": 1, "attack": 2, "defense": 1, "magic": 0, "agility": 1}, null)
		await ui._player_attr_auto_allocate_async()
		var saved: bool = gm.save_game()
		var expected := FileAccess.open(expected_path, FileAccess.WRITE)
		expected.store_string(JSON.stringify(_save_test_snapshot(gm)))
		expected.close()
		print("LOCAL_SAVE_WRITE=" + JSON.stringify({"saved": saved, "manual_points_ok": valid_spend, "overspend_rejected": rejects_overspend, "snapshot": _save_test_snapshot(gm)}))
		get_tree().quit(0 if saved and valid_spend and rejects_overspend else 1)
	else:
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		var actual := _save_test_snapshot(gm)
		var same: bool = expected == JSON.parse_string(JSON.stringify(actual))
		print("LOCAL_SAVE_RESTART=" + JSON.stringify({"matches": same, "snapshot": actual}))
		var report := FileAccess.open(_local_output_path("本地存档重启检查.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify({"restart_matches": same, "actual": actual, "expected": expected}, "  "))
		get_tree().quit(0 if same else 1)

func _shop_test_snapshot(gm) -> Dictionary:
	return {"gold": gm.player.gold, "yuanbao": gm.player.yuanbao_currency, "items": gm.inventory_manager.to_dict(), "shop_counts": gm._local_metadata.shop_counts}

func _run_shop_test(ui, gm) -> void:
	var expected_path: String = gm.local_slot_path() + ".expected"
	if "--shop-read-test" in OS.get_cmdline_user_args():
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		var same: bool = expected == JSON.parse_string(JSON.stringify(_shop_test_snapshot(gm)))
		var diff := FileAccess.open(_local_output_path("本地商城重启检查.json"), FileAccess.WRITE)
		diff.store_string(JSON.stringify({"passed": same, "expected": expected, "actual": _shop_test_snapshot(gm)}, "  "))
		print("LOCAL_SHOP_RESTART=" + str(same))
		get_tree().quit(0 if same else 1)
		return
	gm.player.gold = 100000000
	gm.player.yuanbao_currency = 10000000
	gm.player.friendship_points = 100000
	var shop = load("res://ui/city/shop_ui.gd")
	var panel: Control = shop.create_fullscreen(gm)
	ui.add_child(panel)
	await get_tree().process_frame
	var gold_label := Label.new()
	var yuanbao_label := Label.new()
	var friendship_label := Label.new()
	panel.add_child(gold_label)
	panel.add_child(yuanbao_label)
	panel.add_child(friendship_label)
	var gold_before: int = gm.player.gold
	await shop._buy_configured_item(gm, "新手锦囊", 1000, "gold", gold_label, yuanbao_label, friendship_label, panel, 1, 2)
	var gold_ui_ok: bool = gm.player.gold == gold_before - 2000 and gm.inventory_manager.get_item_count("新手锦囊") == 2
	var y_before: int = gm.player.yuanbao_currency
	var y_result: Dictionary = gm.local_shop_buy("双倍经验丹", "yuanbao", 3)
	var yuanbao_ok: bool = y_result.get("ok", false) and gm.player.yuanbao_currency == y_before - 300 and gm.inventory_manager.get_item_count("双倍经验丹") == 3
	gm.player.gold = 0
	var insufficient: Dictionary = gm.local_shop_buy("新手锦囊", "gold", 1)
	var balance_ok: bool = not insufficient.get("ok", true) and gm.player.gold == 0 and gm.inventory_manager.get_item_count("新手锦囊") == 2
	gm.player.gold = gold_before - 2000
	var bad_quantity: bool = not gm.local_shop_buy("新手锦囊", "gold", 0).get("ok", true) and not gm.local_shop_buy("新手锦囊", "gold", 1000).get("ok", true)
	var unknown: bool = not gm.local_shop_buy("不存在的物品", "gold", 1).get("ok", true)
	var vip_blocked: bool = not gm.local_shop_buy("宠物经验丹", "yuanbao", 1).get("ok", true)
	var rollback_before := JSON.stringify(_shop_test_snapshot(gm))
	gm._local_save_ready = false
	var disk_failure: Dictionary = gm.local_shop_buy("双倍经验丹", "yuanbao", 1)
	gm._local_save_ready = true
	var rollback_ok: bool = not disk_failure.get("ok", true) and JSON.parse_string(rollback_before) == JSON.parse_string(JSON.stringify(_shop_test_snapshot(gm)))
	gm.player.is_vip = true
	gm.player.vip_level = 3
	gm.player.vip_expire_time_str = "2099-01-01T00:00:00Z"
	var first_limited: Dictionary = gm.local_shop_buy("宠物经验丹", "yuanbao", 1)
	var second_limited: Dictionary = gm.local_shop_buy("宠物经验丹", "yuanbao", 1)
	var daily_ok: bool = first_limited.get("ok", false) and not second_limited.get("ok", true)
	var catalog_checks: Array = []
	var catalog_ok := true
	for row in gm.local_shop_catalog():
		if row.itemName == "宠物经验丹":
			continue
		var purchased: Dictionary = gm.local_shop_buy(row.itemName, row.currency, 1)
		catalog_checks.append({"item": row.itemName, "currency": row.currency, "price": row.basePrice, "ok": purchased.get("ok", false), "message": purchased.get("message", "")})
		catalog_ok = catalog_ok and bool(purchased.get("ok", false))
	var checks := {"ui_gold_purchase": gold_ui_ok, "yuanbao_batch": yuanbao_ok, "insufficient_balance": balance_ok, "invalid_quantity": bad_quantity, "unknown_item": unknown, "vip_guard": vip_blocked, "save_failure_rollback": rollback_ok, "daily_limit": daily_ok, "catalog_all_buyable": catalog_ok, "catalog": catalog_checks}
	var ok: bool = gold_ui_ok and yuanbao_ok and balance_ok and bad_quantity and unknown and vip_blocked and rollback_ok and daily_ok and catalog_ok
	checks["passed"] = ok
	gm.save_game()
	var expected := FileAccess.open(expected_path, FileAccess.WRITE)
	expected.store_string(JSON.stringify(_shop_test_snapshot(gm)))
	expected.close()
	var report := FileAccess.open(_local_output_path("本地商城检查.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(checks, "  "))
	print("LOCAL_SHOP_QA=" + JSON.stringify(checks))
	get_tree().quit(0 if ok else 1)


func _item_snapshot(gm) -> Dictionary:
	return {"double_exp_until": gm.player.double_exp_until, "cultivation": gm.player.cultivation, "pill_count": gm.player.cultivation_pills_used, "inventory": gm.inventory_manager.to_dict(), "equipment": gm.equipment_manager.to_dict(), "pet_count": gm.pet_manager.get_pet_count(), "pet_level": gm.pet_manager.get_active_pet().level, "pet_growth": gm.pet_manager.get_active_pet().total_growth, "souls": gm.pet_soul_manager.to_dict()}

func _run_item_test(ui, gm) -> void:
	var expected_path: String = gm.local_slot_path() + ".expected"
	if "--item-read-test" in OS.get_cmdline_user_args():
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		var same: bool = expected == JSON.parse_string(JSON.stringify(_item_snapshot(gm)))
		print("LOCAL_ITEM_RESTART=" + str(same))
		var report := FileAccess.open(_local_output_path("本地道具重启检查.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify({"passed": same, "actual": _item_snapshot(gm), "expected": expected}, "  "))
		get_tree().quit(0 if same else 1)
		return
	var inv = gm.inventory_manager
	inv.add_item("双倍经验丹(周)", 3)
	var week = inv.get_items_by_name("双倍经验丹(周)")[0] if inv.has_method("get_items_by_name") else null
	for entry in inv.items:
		if entry.name == "双倍经验丹(周)":
			week = entry
	ui._ink_enter("bag")
	ui._show_item_action_popup(week)
	await get_tree().process_frame
	var use_button_ok := false
	for button in get_tree().root.find_children("*", "Button", true, false):
		if button.text == "使用" and not button.disabled:
			use_button_ok = true
	var now: int = int(Time.get_unix_time_from_system())
	var single: Dictionary = await inv.use_item(week.id, gm.player)
	var week_ok: bool = single.get("success", false) and abs(gm.player.double_exp_until - now - 604800) <= 2 and week.count == 2 and gm.player.is_double_exp_active()
	var until: int = gm.player.double_exp_until
	var batch: Dictionary = await gm.local_use_item(week.id, 2)
	var batch_ok: bool = batch.get("success", false) and gm.player.double_exp_until == until + 2 * 604800 and inv.get_item_count("双倍经验丹(周)") == 0
	var duplicate: Dictionary = await gm.local_use_item(week.id, 1)
	var duplicate_ok: bool = not duplicate.get("success", true) and gm.player.double_exp_until == until + 2 * 604800
	var gift_checks: Array = []
	var gifts_ok := true
	for name in ["开悟丹锦囊", "新手锦囊", "开荒宠装锦囊", "开荒锦囊", "金魂魄", "宠物补章器"]:
		inv.add_item(name, 1)
		var id := ""
		for entry in inv.items:
			if entry.name == name:
				id = entry.id
		var result: Dictionary = await gm.local_use_item(id, 1)
		gifts_ok = gifts_ok and bool(result.get("success", false))
		gift_checks.append({"item": name, "success": result.get("success", false), "message": result.get("message", "")})
	var pill_id := ""
	for entry in inv.items:
		if entry.name == "开悟丹":
			pill_id = entry.id
	var cultivation_before: int = gm.player.cultivation
	var pills: Dictionary = await gm.local_use_item(pill_id, 5)
	var pill_limit: Dictionary = await gm.local_use_item(pill_id, 1)
	var pills_ok: bool = pills.get("success", false) and not pill_limit.get("success", true) and gm.player.cultivation == cultivation_before + 2500 and inv.get_item_count("开悟丹") == 45
	inv.add_item("双倍经验丹", 1)
	var day_id := ""
	for entry in inv.items:
		if entry.name == "双倍经验丹":
			day_id = entry.id
	var rollback_until: int = gm.player.double_exp_until
	gm._local_save_ready = false
	var failed: Dictionary = await gm.local_use_item(day_id, 1)
	gm._local_save_ready = true
	var rollback_ok: bool = not failed.get("success", true) and gm.player.double_exp_until == rollback_until and inv.get_item_count("双倍经验丹") == 1
	inv.add_item("宠物经验丹", 1)
	var upgrade_id := ""
	for entry in inv.items:
		if entry.name == "宠物经验丹":
			upgrade_id = entry.id
	var upgrade: Dictionary = await gm.local_use_item(upgrade_id, 1)
	var upgrade_ok: bool = upgrade.get("success", false) and gm.pet_manager.get_active_pet().level == gm.pet_manager.get_active_pet().get_effective_max_level()
	var checks := {"use_button_enabled": use_button_ok, "pet_upgrade": upgrade_ok, "week_duration": week_ok, "batch_stack": batch_ok, "no_duplicate_use": duplicate_ok, "gifts": gift_checks, "gifts_ok": gifts_ok, "cultivation_limit": pills_ok, "save_failure_rollback": rollback_ok}
	checks["passed"] = use_button_ok and upgrade_ok and week_ok and batch_ok and duplicate_ok and gifts_ok and pills_ok and rollback_ok
	gm.save_game()
	var expected := FileAccess.open(expected_path, FileAccess.WRITE)
	expected.store_string(JSON.stringify(_item_snapshot(gm)))
	var report := FileAccess.open(_local_output_path("本地道具使用检查.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(checks, "  "))
	print("LOCAL_ITEM_QA=" + JSON.stringify(checks))
	get_tree().quit(0 if checks.passed else 1)


func _buff_snapshot(gm) -> Dictionary:
	return {"channels": gm._local_metadata.get("double_exp_channels", {}), "until": gm.player.double_exp_until, "count": gm.local_double_exp_count(), "multiplier": gm.player.get_total_exp_multiplier()}

func _run_buff_test(ui, gm) -> void:
	var expected_path: String = gm.local_slot_path() + ".expected"
	if "--buff-read-test" in OS.get_cmdline_user_args():
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		var same: bool = expected == JSON.parse_string(JSON.stringify(_buff_snapshot(gm)))
		print("LOCAL_BUFF_RESTART=" + str(same))
		get_tree().quit(0 if same else 1)
		return
	gm._local_metadata.double_exp_channels = {}
	gm.player.double_exp_until = 0
	gm.player.newbie_exp_until = 0
	gm.player.is_vip = false
	ui._ink_enter("battle")
	var rows: Array = []
	var names: Array = ["双倍经验丹", "双倍经验丹(周)", "双倍经验丹(月)"]
	var buffs_ok := true
	for step in range(4):
		if step > 0:
			var added: Dictionary = gm.inventory_manager.add_item(names[step - 1], 1)
			var used: Dictionary = await gm.local_use_item(str(added.item.id), 1)
			buffs_ok = buffs_ok and bool(used.get("success", false))
		gm.player.level = 100
		gm.player.experience = 0
		gm.player.attack_base = 1000000
		gm.player.agility_base = 1000000
		var pet = gm.pet_manager.get_active_pet()
		pet.level = 100
		pet.experience = 0
		seed(424242)
		var started: bool = gm.start_battle()
		for enemy in gm.battle_system.monsters:
			enemy.hp = 1
		var deadline: int = Time.get_ticks_msec() + 30000
		while gm.in_battle and Time.get_ticks_msec() < deadline:
			gm.battle_system.execute_turn()
			await get_tree().create_timer(0.05).timeout
		rows.append({"active": gm.local_double_exp_count(), "multiplier": gm.player.get_total_exp_multiplier(), "player_exp": gm.player.experience, "pet_exp": pet.experience, "finished": not gm.in_battle, "started": started})
	var ratios_ok := true
	for step in range(4):
		ratios_ok = ratios_ok and rows[step].finished and rows[step].started and int(rows[step].player_exp) == int(rows[0].player_exp) * (step + 1) and int(rows[step].pet_exp) == int(rows[0].pet_exp) * (step + 1) and int(rows[step].active) == step
	var channels_before: Dictionary = gm._local_metadata.double_exp_channels.duplicate(true)
	var extra: Dictionary = gm.inventory_manager.add_item("双倍经验丹", 1)
	await gm.local_use_item(str(extra.item.id), 1)
	var same_type_ok: bool = gm.local_double_exp_count() == 3 and int(gm._local_metadata.double_exp_channels["双倍经验丹"]) == int(channels_before["双倍经验丹"]) + 86400 and gm._local_metadata.double_exp_channels["双倍经验丹(周)"] == channels_before["双倍经验丹(周)"]
	var now: int = int(Time.get_unix_time_from_system())
	var expiry_ok: bool = gm.local_double_exp_count(now + 3 * 86400) == 2 and gm.local_double_exp_count(now + 8 * 86400) == 1 and gm.local_double_exp_count(now + 31 * 86400) == 0
	var metadata_before: Dictionary = gm._local_metadata.duplicate(true)
	gm._local_metadata.erase("double_exp_channels")
	gm._local_metadata.shop_counts = {}
	for name in names:
		gm._local_metadata.shop_counts["test|" + name] = 1
	gm.player.double_exp_until = now + 38 * 86400
	gm._migrate_local_double_exp()
	var migration_ok: bool = gm.local_double_exp_count() == 3 and int(gm._local_metadata.double_exp_channels["双倍经验丹"]) == now + 86400 and int(gm._local_metadata.double_exp_channels["双倍经验丹(月)"]) == now + 30 * 86400
	gm._local_metadata = metadata_before
	gm._sync_local_double_exp_until()
	var saved: bool = gm.save_game()
	var checks := {"battles": rows, "actual_exp_ratios_1_2_3_4": ratios_ok, "items_used": buffs_ok, "same_type_extends_only_its_duration": same_type_ok, "independent_expiry": expiry_ok, "previous_consumption_migration": migration_ok, "saved": saved}
	checks["passed"] = ratios_ok and buffs_ok and same_type_ok and expiry_ok and migration_ok and saved
	var report := FileAccess.open(_local_output_path("经验丹叠加检查.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(checks, "  "))
	var expected := FileAccess.open(expected_path, FileAccess.WRITE)
	expected.store_string(JSON.stringify(_buff_snapshot(gm)))
	print("LOCAL_BUFF_QA=" + JSON.stringify(checks))
	get_tree().quit(0 if checks.passed else 1)


func _lottery_snapshot(gm) -> Dictionary:
	return {"gold": gm.player.gold, "yuanbao": gm.player.yuanbao_currency, "inventory": gm.inventory_manager.to_dict(), "metadata": gm._local_metadata}

func _run_lottery_test(ui, gm) -> void:
	var expected_path: String = gm.local_slot_path() + ".expected"
	if "--lottery-read-test" in OS.get_cmdline_user_args():
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		var same: bool = expected == JSON.parse_string(JSON.stringify(_lottery_snapshot(gm)))
		var report := FileAccess.open(_local_output_path("幸运抽奖重启检查.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify({"passed": same, "pity": gm.local_lottery_pity_status()}, "  "))
		print("LOCAL_LOTTERY_RESTART=" + str(same))
		get_tree().quit(0 if same else 1)
		return
	gm.player.gold = 10000000000
	gm.player.yuanbao_currency = 100000
	var service = load("res://dev/local_lottery.gd")
	var pool_ok := true
	var pools: Dictionary = {}
	var all_rewards_ok := true
	var reward_checks: Array = []
	for pool in ["gold", "yuanbao"]:
		var total := 0
		var entries: Array = service.pool_entries(pool)
		for row in entries:
			pool_ok = pool_ok and service.pick_ticket(entries, total) == row.name and service.pick_ticket(entries, total + int(row.weight) - 1) == row.name
			total += int(row.weight)
			var result: Dictionary = service.grant_reward(gm, row.name)
			all_rewards_ok = all_rewards_ok and bool(result.get("ok", false))
			reward_checks.append({"name": row.name, "ok": result.get("ok", false), "message": result.get("message", "")})
		pools[pool] = {"entries": entries.size(), "weight_total": total}
	pool_ok = pool_ok and int(pools.gold.weight_total) == 10001 and int(pools.yuanbao.weight_total) == 10000
	var early_claim: bool = not gm.local_lottery_claim("十一阶可进化宠锦囊", "early").get("ok", true)
	var y_before: int = gm.player.yuanbao_currency
	var first: Dictionary = gm.local_lottery_draw("yuanbao", "first")
	var first_ok: bool = first.get("ok", false) and gm.player.yuanbao_currency == y_before - 100 and gm.local_lottery_pity_status().count == 1
	var before_repeat := JSON.stringify(_lottery_snapshot(gm))
	var repeat: Dictionary = gm.local_lottery_draw("yuanbao", "first")
	var duplicate_ok: bool = repeat.get("ok", false) and JSON.parse_string(before_repeat) == JSON.parse_string(JSON.stringify(_lottery_snapshot(gm)))
	gm.player.yuanbao_currency = 0
	var insufficient_y: bool = not gm.local_lottery_draw("yuanbao", "poor-y").get("ok", true)
	gm.player.yuanbao_currency = y_before - 100
	var g_before: int = gm.player.gold
	gm.player.gold = 0
	var insufficient_g: bool = not gm.local_lottery_draw("gold", "poor-g").get("ok", true)
	gm.player.gold = g_before
	var gold_draw: Dictionary = gm.local_lottery_draw("gold", "gold-first")
	var reward_gold: int = int(str(gold_draw.get("rewardName", "")).trim_suffix("亿金币")) * 100000000 if str(gold_draw.get("rewardName", "")).ends_with("亿金币") else 0
	var gold_ok: bool = gold_draw.get("ok", false) and gm.player.gold == g_before - 500000000 + reward_gold and gm.local_lottery_pity_status().count == 1
	var rollback_snapshot := JSON.stringify(_lottery_snapshot(gm))
	gm._local_save_ready = false
	var failed: Dictionary = gm.local_lottery_draw("yuanbao", "disk-fail")
	gm._local_save_ready = true
	var rollback_ok: bool = not failed.get("ok", true) and JSON.parse_string(rollback_snapshot) == JSON.parse_string(JSON.stringify(_lottery_snapshot(gm)))
	var draws_ok := true
	for i in range(98):
		var result: Dictionary = gm.local_lottery_draw("yuanbao", "draw-%d" % i)
		draws_ok = draws_ok and bool(result.get("ok", false))
	var lottery_ui = load("res://ui/city/lucky_draw_ui.gd").create_fullscreen(gm)
	ui.add_child(lottery_ui)
	await get_tree().process_frame
	lottery_ui._request_draw("yuanbao")
	await get_tree().create_timer(2.0).timeout
	var ui_ok: bool = not lottery_ui._draw_anim_active and gm.local_lottery_pity_status().count == 100 and lottery_ui.result_label.text.contains("本地抽奖成功")
	var before_claim: int = gm.inventory_manager.get_item_count("十一阶可进化宠锦囊")
	var claimed: Dictionary = gm.local_lottery_claim("十一阶可进化宠锦囊", "claim-100")
	var claim_ok: bool = claimed.get("ok", false) and gm.local_lottery_pity_status().count == 0 and gm.inventory_manager.get_item_count("十一阶可进化宠锦囊") == before_claim + 1
	var repeated_claim: Dictionary = gm.local_lottery_claim("十一阶可进化宠锦囊", "claim-100")
	var claim_once: bool = repeated_claim.get("ok", false) and gm.inventory_manager.get_item_count("十一阶可进化宠锦囊") == before_claim + 1 and not gm.local_lottery_claim("十一阶可进化宠锦囊", "claim-again").get("ok", true)
	var invalid: bool = not gm.local_lottery_draw("other", "unknown-pool").get("ok", true) and not gm.local_lottery_claim("未知奖励", "unknown-reward").get("ok", true)
	gm.save_game()
	var checks := {"pool_boundaries": pool_ok, "pools": pools, "all_reward_entries": all_rewards_ok, "rewards": reward_checks, "yuanbao_cost": first_ok, "gold_cost": gold_ok, "insufficient_currency": insufficient_y and insufficient_g, "duplicate_draw": duplicate_ok, "save_failure_rollback": rollback_ok, "draws_succeeded": draws_ok, "ui_ceremony_and_100_pity": ui_ok, "claim_100": claim_ok, "claim_once": claim_once, "early_claim_rejected": early_claim, "invalid_request": invalid}
	checks["passed"] = pool_ok and all_rewards_ok and first_ok and gold_ok and insufficient_y and insufficient_g and duplicate_ok and rollback_ok and draws_ok and ui_ok and claim_ok and claim_once and early_claim and invalid
	var report := FileAccess.open(_local_output_path("幸运抽奖本地检查.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(checks, "  "))
	var expected := FileAccess.open(expected_path, FileAccess.WRITE)
	expected.store_string(JSON.stringify(_lottery_snapshot(gm)))
	print("LOCAL_LOTTERY_QA=" + JSON.stringify(checks))
	get_tree().quit(0 if checks.passed else 1)
