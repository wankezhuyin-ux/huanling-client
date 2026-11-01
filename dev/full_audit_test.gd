extends RefCounted

static func run(ui, gm) -> void:
	var checks: Dictionary = {}
	var p = gm.player
	var pet = gm.pet_manager.get_active_pet()
	p.newbie_exp_until = 0
	p.is_vip = false
	p.auto_allocation_enabled = false
	gm._local_metadata.double_exp_channels = {}
	p.double_exp_until = 0
	var rows: Array = []
	for count in range(4):
		if count > 0:
			gm.local_extend_double_exp(["双倍经验丹", "双倍经验丹(周)", "双倍经验丹(月)"][count - 1])
		p.level = 1
		p.experience = 0
		pet.level = 1
		pet.experience = 0
		gm.battle_system.player_died_in_battle = false
		gm.battle_system.pet_died_in_battle = false
		gm._grant_field_battle_exp(1000, pet)
		var total: int = p.experience
		for level in range(1, p.level):
			total += gm.GameData.get_required_exp(level)
		var pet_total: int = pet.experience
		for level in range(1, pet.level):
			pet_total += gm.pet_manager._get_pet_max_exp(level)
		rows.append({"multiplier": count + 1, "level": p.level, "remaining": p.experience, "player_total": total, "pet_total": pet_total, "ok": total == 1000 * (count + 1) and pet_total == 1000 * (count + 1)})
	checks.exp_across_multiple_levels = rows
	p.auto_allocation_enabled = true
	p.auto_allocation_plan = {"vitality": 0, "attack": 5, "defense": 5, "magic": 0, "agility": 0}
	p.pending_auto_points = 9
	var attack: int = p.get_attack()
	var base: int = p.attack_base
	var below: bool = not gm.local_auto_allocate() and p.pending_auto_points == 9
	p.pending_auto_points = 10
	var at_ten: bool = gm.local_auto_allocate() and p.pending_auto_points == 0 and p.attack_base == base + 5 and p.get_attack() > attack
	var no_repeat: bool = not gm.local_auto_allocate() and p.attack_base == base + 5
	checks.auto_allocate = {"below_ten_waits": below, "ten_applies_stats": at_ten, "no_duplicate": no_repeat}
	var growth: Dictionary = pet.growth_rates.duplicate(true)
	for i in range(5):
		pet.recalculate_stats()
	checks.pet_recalculation_no_extra_growth = pet.growth_rates == growth
	var added: Dictionary = gm.inventory_manager.add_item("十一阶可进化宠锦囊", 1)
	var before: int = gm.pet_manager.pets.size()
	var gift: Dictionary = await gm.local_use_item(str(added.item.id), 1)
	var new_pet = gm.pet_manager.pets.back()
	checks.evolution_gift = {"success": gift.get("success", false), "message": gift.get("message", ""), "one_pet": gm.pet_manager.pets.size() == before + 1, "growth": new_pet.total_growth, "range_ok": new_pet.total_growth >= 11.0 and new_pet.total_growth <= 11.9, "consumed_once": gm.inventory_manager.get_item_count("十一阶可进化宠锦囊") == 0}
	gm.prepare_local_encounter()
	var enemies: Array = gm.battle_system.monsters
	checks.shared_primary_target = not enemies.is_empty() and gm.battle_system._pick_pair_pet_target([enemies[0]], pet) == enemies[0]
	# Exercise the real damage resolver against durable, neutral test enemies.
	ui.auto_battle = false
	var bs = gm.battle_system
	bs.player = p
	bs.active_pet = pet
	bs.current_state = bs.BattleState.IN_PROGRESS
	bs.is_battle_active = true
	p.element = "普通"
	var target = enemies[0]
	target.max_hp = 1000000
	target.hp = 1000000
	target.defense = 0
	target.agility = 0
	target.element = "普通"
	p.agility_base = 100000
	p.attack_base = 100
	seed(12345)
	bs._resolve_player_attack(p, [target])
	var first_damage: int = 1000000 - target.hp
	target.hp = 1000000
	p.attack_base = 110
	seed(12345)
	bs._resolve_player_attack(p, [target])
	var second_damage: int = 1000000 - target.hp
	checks.actual_damage_changes_with_attack = {"before": first_damage, "after": second_damage, "ok": second_damage > first_damage}
	var hits: Array = []
	var on_hit: Callable = func(attacker, _target, damage, _critical, target_type, index, _element, _pierce, _counter):
		if target_type == "monster":
			hits.append({"attacker": attacker, "damage": damage, "index": index})
	bs.damage_dealt.connect(on_hit)
	target.hp = 1000000
	bs._resolve_joint_player_strike(p, pet, target)
	await ui.get_tree().create_timer(0.8).timeout
	bs.damage_dealt.disconnect(on_hit)
	var damage_sum := 0
	for hit in hits:
		damage_sum += int(hit.damage)
	checks.joint_attack = {"hits": hits, "hp_lost": 1000000 - target.hp, "same_target_and_real_hp": hits.size() == 2 and hits[0].index == hits[1].index and damage_sum == 1000000 - target.hp}
	bs.current_state = bs.BattleState.DEFEAT
	checks.services = await _services(ui, gm)
	pet = gm.pet_manager.get_active_pet()
	var expected := {"level": p.level, "exp": p.experience, "attack": p.attack_base, "pending": p.pending_auto_points, "growth": pet.growth_rates, "pets": gm.pet_manager.pets.size(), "channels": gm._local_metadata.double_exp_channels}
	checks.saved = gm.save_game()
	checks.reloaded = gm.load_game()
	pet = gm.pet_manager.get_active_pet()
	var actual := {"level": p.level, "exp": p.experience, "attack": p.attack_base, "pending": p.pending_auto_points, "growth": pet.growth_rates, "pets": gm.pet_manager.pets.size(), "channels": gm._local_metadata.double_exp_channels}
	checks.persistence = JSON.parse_string(JSON.stringify(expected)) == JSON.parse_string(JSON.stringify(actual))
	checks.expected = expected
	checks.actual = actual
	var passed: bool = below and at_ten and no_repeat and checks.pet_recalculation_no_extra_growth and checks.shared_primary_target and checks.persistence and gift.get("success", false) and checks.evolution_gift.range_ok
	for row in rows:
		passed = passed and row.ok
	passed = passed and checks.services.passed and checks.actual_damage_changes_with_attack.ok and checks.joint_attack.same_target_and_real_hp
	checks.passed = passed
	var out := FileAccess.open(gm.local_slot_path().get_base_dir().get_base_dir().path_join("核心数值完整检查.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify(checks, "  "))
	print("FULL_AUDIT=" + JSON.stringify(checks))
	ui.get_tree().quit(0 if passed else 1)

static func _services(ui, gm) -> Dictionary:
	var checks: Dictionary = {}
	var added: Dictionary = gm.inventory_manager.add_item("回血墨", 3)
	var store: Dictionary = gm.local_feature_action("store_item", {"id": str(added.item.id)})
	var warehouse_item = gm.inventory_manager.warehouse_items.back()
	var take: Dictionary = gm.local_feature_action("withdraw_item", {"id": str(warehouse_item.id)})
	checks.warehouse_roundtrip = store.get("success", false) and take.get("success", false) and gm.inventory_manager.get_item_count("回血墨") == 3
	added = gm.inventory_manager.add_item("一击三伤", 1)
	var learned: Dictionary = await gm.local_use_item(str(added.item.id), 1)
	checks.martial_book = learned.get("success", false)
	if checks.martial_book:
		var art = gm.martial_arts_manager.martial_arts.back()
		var equip: Dictionary = gm.local_feature_action("martial_equip", {"id": art.id})
		var unequip: Dictionary = gm.local_feature_action("martial_unequip", {"id": art.id})
		checks.martial_equipment = equip.get("success", false) and unequip.get("success", false)
	added = gm.inventory_manager.add_item("力壮lv1技能书", 1)
	var skill: Dictionary = await gm.local_use_item(str(added.item.id), 1)
	checks.pet_skill_book = skill.get("success", false)
	gm._local_metadata.simulation = {"claims": {}, "mail": [], "listings": [], "guild": ""}
	var gold: int = gm.player.gold
	var claim: Dictionary = gm.local_feature_action("sim_signin")
	var repeat: Dictionary = gm.local_feature_action("sim_signin")
	checks.signin_once = claim.get("success", false) and not repeat.get("success", false) and gm.player.gold == gold + 10000
	gm.local_feature_action("sim_mail_send")
	var mail_id: String = gm._local_metadata.simulation.mail[0].id
	gold = gm.player.gold
	claim = gm.local_feature_action("sim_mail_claim", {"id": mail_id})
	repeat = gm.local_feature_action("sim_mail_claim", {"id": mail_id})
	checks.mail_once = claim.get("success", false) and not repeat.get("success", false) and gm.player.gold == gold + 1000
	added = gm.inventory_manager.add_item("回血墨", 1)
	var count: int = gm.inventory_manager.get_item_count("回血墨")
	var listing: Dictionary = gm.local_feature_action("sim_trade_list", {"id": str(added.item.id), "price": 10000})
	var listing_id: String = gm._local_metadata.simulation.listings[0].id
	var escrow: bool = gm.inventory_manager.get_item_count("回血墨") == count - 1
	var cancel: Dictionary = gm.local_feature_action("sim_trade_cancel", {"id": listing_id})
	checks.trade_escrow_cancel = listing.get("success", false) and escrow and cancel.get("success", false) and gm.inventory_manager.get_item_count("回血墨") == count
	var gift_add: Dictionary = gm.inventory_manager.add_item("新手锦囊", 1)
	var gift_used: Dictionary = await gm.local_use_item(str(gift_add.item.id), 1)
	var non_evo_add: Dictionary = gm.inventory_manager.add_item("七阶不可进化宠锦囊", 1)
	var non_evo: Dictionary = await gm.local_use_item(str(non_evo_add.item.id), 1)
	checks.non_evolution_gift = non_evo.get("success", false)
	checks.body_equipment = false
	if bool(gift_used.get("success", false)):
		var equipment = gm.equipment_manager.inventory.back()
		var equip: Dictionary = gm.local_equipment_op(false, "equip", str(equipment.id))
		var unequip: Dictionary = gm.local_equipment_op(false, "unequip", str(equipment.id), str(equipment.slot))
		checks.body_equipment = equip.get("success", false) and unequip.get("success", false)
	gift_add = gm.inventory_manager.add_item("开荒宠装锦囊", 1)
	gift_used = await gm.local_use_item(str(gift_add.item.id), 1)
	checks.pet_equipment = false
	if bool(gift_used.get("success", false)):
		var equipment: Dictionary = gm.inventory_manager.pet_equipment_items.back()
		var equip: Dictionary = gm.local_equipment_op(true, "equip", str(equipment.id))
		var slot: String = gm.pet_equipment_manager.PetEquipmentData.get_pet_slot_from_equipment_slot(str(equipment.slot))
		var unequip: Dictionary = gm.local_equipment_op(true, "unequip", str(equipment.id), slot)
		checks.pet_equipment = equip.get("success", false) and unequip.get("success", false)
	var pet_count: int = gm.pet_manager.pets.size()
	var max_pets: int = gm.pet_manager.max_pets
	gm.pet_manager.max_pets = pet_count
	gift_add = gm.inventory_manager.add_item("十一阶可进化宠锦囊", 1)
	gift_used = await gm.local_use_item(str(gift_add.item.id), 1)
	checks.full_pet_bag_no_consumption = not gift_used.get("success", false) and gm.inventory_manager.get_item_count("十一阶可进化宠锦囊") == 1 and gm.pet_manager.pets.size() == pet_count
	gm.pet_manager.max_pets = max_pets
	gm.pet_manager.create_pet_from_tower("wen_di_long", "纹地龙", 7.0)
	var dragon = gm.pet_manager.pets.back()
	var dragon_id: String = dragon.id
	dragon.level = 500
	dragon.experience = 123
	var evolved: Dictionary = gm.local_feature_action("pet_evolve", {"id": dragon_id})
	var first_ok: bool = evolved.get("success", false) and dragon.pet_id == "huang_jin_long" and dragon.level == 1 and dragon.experience == 0
	var evolve_repeat: Dictionary = gm.local_feature_action("pet_evolve", {"id": dragon_id})
	dragon = gm.pet_manager.get_pet_by_stable_id(dragon_id)
	var blocked: bool = not evolve_repeat.get("success", false) and dragon.pet_id == "huang_jin_long" and dragon.level == 1
	dragon.level = 499
	var below: Dictionary = gm.local_feature_action("pet_evolve", {"id": dragon_id})
	dragon = gm.pet_manager.get_pet_by_stable_id(dragon_id)
	dragon.level = 500
	var second: Dictionary = gm.local_feature_action("pet_evolve", {"id": dragon_id})
	checks.evolution_level_reset = first_ok and blocked and not below.get("success", false) and second.get("success", false) and dragon.pet_id == "huang_long_shi" and dragon.level == 1 and dragon.experience == 0
	checks.ui_pages = true
	for key in ["warehouse", "qiankun", "martial", "pet_park", "ranking", "signin7", "gang_hall", "mail", "trade", "activity", "world"]:
		var panel = load("res://dev/local_feature_ui.gd").create_fullscreen(gm, key)
		ui.add_child(panel)
		await ui.get_tree().process_frame
		checks.ui_pages = checks.ui_pages and panel.body != null and panel.body.get_child_count() > 3
		ui.remove_child(panel)
		panel.queue_free()
	checks.passed = true
	for key in checks:
		if key != "passed":
			checks.passed = checks.passed and bool(checks[key])
	return checks
