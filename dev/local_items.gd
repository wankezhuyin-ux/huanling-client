extends RefCounted

const GameData = preload("res://scripts/game_data.gd")
const DOUBLE_HOURS := {"双倍经验符": 24, "双倍经验符·周": 168, "双倍经验符·月": 720}

static func use_item(gm, item_id: String, quantity: int = 1) -> Dictionary:
	var inv = gm.inventory_manager
	var item = inv.get_item_by_id(item_id)
	if gm._local_shop_busy or item == null or quantity < 1 or quantity > 999:
		return {"success": false, "message": "物品不存在、数量无效或交易处理中"}
	if quantity > int(item.count) or not item.can_use():
		return {"success": false, "message": "道具数量不足或该物品需要在对应功能中使用"}
	if gm.in_battle:
		return {"success": false, "message": "请先停止战斗，再使用道具"}
	var snapshot: Dictionary = gm.create_secure_op_snapshot()
	gm._local_shop_busy = true
	var messages: Array = []
	var used := 0
	for i in range(quantity):
		var effect: Dictionary = await _apply_one(gm, item)
		if not bool(effect.get("success", false)):
			gm.restore_secure_op_snapshot(snapshot)
			gm._local_shop_busy = false
			return effect
		messages.append(str(effect.get("message", "使用成功")))
		used += 1
	# Effects do not consume the source item; all consumption occurs here once.
	var removed: Dictionary = inv.remove_item(item_id, used)
	gm._local_shop_busy = false
	if not bool(removed.get("success", false)) or not gm.save_game():
		gm._local_shop_busy = true
		gm.restore_secure_op_snapshot(snapshot)
		gm._local_shop_busy = false
		return {"success": false, "message": "存档失败，效果和道具均已回滚"}
	inv.inventory_changed.emit()
	gm.gold_changed.emit(gm.player.gold)
	gm.yuanbao_changed.emit(gm.player.yuanbao_currency)
	return {"success": true, "message": "\n".join(messages), "local_save_applied": true, "consumed": used}

static func _apply_one(gm, item) -> Dictionary:
	var p = gm.player
	var inv = gm.inventory_manager
	var name: String = str(item.name)
	var cfg: Dictionary = GameData.resolve_item_def(name)
	if item.item_type in ["chest", "treasure_chest"]:
		var gold: int = {"青铜匣": 10000, "白银匣": 50000, "黄金匣": 100000}.get(name, 100000)
		p.gold += gold
		return {"success": true, "message": "本地模拟宝箱奖励：金币+%d；线上奖池待校准" % gold}
	if item.item_type == "pet_skill_book":
		return gm.pet_manager.learn_skill_book_from_active_pet(name)
	if item.item_type == "martial_skill_book":
		var pre: Dictionary = gm.martial_arts_manager.can_learn_from_skill_book()
		if not bool(pre.get("ok", false)):
			return {"success": false, "message": str(pre.get("message", "武功栏已满"))}
		# Client describes 1–9 layers but does not preserve the server distribution.
		var art = gm.martial_arts_manager.learn_from_skill_book_local(randi_range(1, 9), name)
		return {"success": true, "message": "本地模拟层数（1–9层均匀抽取）：%s，第%d层；效果使用原客户端公式" % [art.name, art.layer]}
	if name == "人物经验丹":
		if p.level >= GameData.MAX_LEVEL_EVOLUTION:
			return {"success": false, "message": "人物已满级，道具未消耗"}
		var required := -int(p.experience)
		for level in range(p.level, GameData.MAX_LEVEL_EVOLUTION):
			required += GameData.get_required_exp(level)
		# The item grants levels, so experience boosts must not multiply this amount.
		p.add_exp(required, true, false, 1, false)
		gm.local_auto_allocate()
		return {"success": true, "message": "已按原升级经验表升至%d级，属性点已生效" % p.level}
	if name in ["先锋锦囊", "新人扶持锦囊"]:
		var capacity: Dictionary = inv._check_gift_capacity(gm, name, 5, 1, [])
		if not bool(capacity.get("ok", false)):
			return {"success": false, "message": str(capacity.get("message", "空间不足"))}
		var result: Dictionary = gm.pet_manager.create_pet_from_tower("linlin", "琳琳", 6.0)
		if not bool(result.get("success", false)):
			return result
		var messages: Array = []
		inv._grant_single_attr_set(gm.equipment_manager, "扶持·", 100, messages)
		p.gold += 100000000
		return {"success": true, "message": "获得1亿金币、成长6.0琳琳、单属性+100装备一套（原道具说明）"}
	if name == "极限装备锦囊":
		for material in ["极限武器", "极限衣服", "极限鞋子", "极限血佩", "极限内带"]:
			var added: Dictionary = inv.add_item(material, 1)
			if not bool(added.get("success", false)):
				return added
		return {"success": true, "message": "获得五种极限装备材料各1件（原客户端说明）"}
	if name.ends_with("+不可进化宠礼包"):
		if gm.pet_manager.get_available_slots() < 1:
			return {"success": false, "message": "宠物栏已满，道具未消耗"}
		var evolution = load("res://scripts/evolution_data.gd")
		var candidates: Array = []
		for id in GameData.PET_DATA:
			if not evolution.is_evolution_pet(str(id)) and not gm.pet_manager._is_blocked_from_refine_pool(str(id)):
				candidates.append(id)
		if candidates.is_empty():
			return {"success": false, "message": "无可用宠物候选，道具未消耗"}
		var id: String = str(candidates.pick_random())
		var growth_min: float = float(name.get_slice("+", 0))
		var growth: float = snapped(randf_range(growth_min, growth_min + 0.5), 0.001)
		var result: Dictionary = gm.pet_manager.create_pet_from_tower(id, str(GameData.PET_DATA[id].name), growth)
		result.message = "本地模拟奖池分布（均匀抽取非进化且非活动限定宠物）；成长按道具说明：%s %.3f" % [GameData.PET_DATA[id].name, growth]
		return result
	if name.ends_with("+可进化宠礼包"):
		if gm.pet_manager.get_available_slots() < 1:
			return {"success": false, "message": "宠物栏已满，道具未消耗"}
		return item._open_evolution_pet_gift(name)
	if name in ["七至九阶晶儿锦囊", "七至九阶梦晶锦囊", "七至九阶阿弟锦囊"]:
		if gm.pet_manager.get_available_slots() < 1:
			return {"success": false, "message": "宠物栏已满，道具未消耗"}
		return item._open_fixed_pet_gift(name)
	if item.item_type == "pet_egg" and (name.ends_with("属性宠物蛋") or name == "五阶宠物蛋"):
		if gm.pet_manager.get_available_slots() < 1:
			return {"success": false, "message": "宠物栏已满，道具未消耗"}
		return item._open_pet_egg(gm.pet_manager, name.trim_suffix("属性宠物蛋") if name != "五阶宠物蛋" else "")
	if name == "五阶宠物锦囊":
		if gm.pet_manager.get_available_slots() < 1:
			return {"success": false, "message": "宠物栏已满，道具未消耗"}
		return item._open_pet_egg(gm.pet_manager, "")
	if inv.GOLD_BAG_CONFIG.has(name):
		var gold: int = int(inv.GOLD_BAG_CONFIG[name].amount)
		p.gold += gold
		return {"success": true, "message": "金币+%d" % gold}
	if DOUBLE_HOURS.has(name):
		return {"success": true, "message": gm.local_extend_double_exp(name)}
	if item.item_type == "cultivation_pill":
		if int(p.cultivation_pills_used) >= int(p.MAX_CULTIVATION_PILLS_PER_LIFE):
			return {"success": false, "message": "本世修行丹额度已用尽（每世最多%d颗），道具未消耗" % int(p.MAX_CULTIVATION_PILLS_PER_LIFE)}
		var bonus: int = int(cfg.get("cultivation_bonus", 0))
		if bonus <= 0:
			return {"success": false, "message": "缺少原客户端丹药配置，道具未消耗"}
		p.cultivation += bonus
		p.cultivation_pills_used += 1
		return {"success": true, "message": "修行值+%d（本世已用%d/%d颗）" % [bonus, p.cultivation_pills_used, p.MAX_CULTIVATION_PILLS_PER_LIFE]}
	if item.item_type == "pet_soul_item":
		var element: String = str(cfg.get("soul_element", ""))
		var points: int = int(cfg.get("soul_points", 0))
		if element.is_empty() or points <= 0:
			return {"success": false, "message": "魂魄配置缺失，道具未消耗"}
		gm.pet_soul_manager.add_points(element, points)
		return {"success": true, "message": "%s魂魄+%d" % [element, points]}
	if name == "开悟丹锦囊":
		return inv.add_item("开悟丹", 50)
	if name == "新手锦囊" or name == "开荒锦囊":
		var needed_pets := 7 if name == "开荒锦囊" else 0
		var capacity: Dictionary = inv._check_gift_capacity(gm, name, 5, needed_pets, [])
		if not bool(capacity.get("ok", false)):
			return {"success": false, "message": str(capacity.get("message", "背包空间不足"))}
		var messages: Array = []
		inv._grant_single_attr_set(gm.equipment_manager, "开荒·" if needed_pets > 0 else "新手·", 400 if needed_pets > 0 else 50, messages)
		if needed_pets > 0:
			for i in range(needed_pets):
				var pet_result: Dictionary = gm.pet_manager.create_pet_from_tower("linlin", "琳琳", 6.0)
				if not bool(pet_result.get("success", false)):
					return {"success": false, "message": str(pet_result.get("message", "发放宠物失败"))}
			p.gold += 500000000
			messages.append("金币+500000000，获得7只成长6.0的琳琳")
		return {"success": true, "message": "\n".join(messages)}
	if name == "开荒宠装锦囊":
		if inv.pet_equipment_items.size() + 5 > inv.MAX_PET_EQUIPMENT_INVENTORY:
			return {"success": false, "message": "宠装背包需要5个空位，道具未消耗"}
		for row in [["weapon", "开荒武器"], ["armor", "开荒护甲"], ["boots", "开荒鞋子"], ["helmet", "开荒头盔"], ["accessory", "开荒饰品"]]:
			inv.pet_equipment_items.append(inv._create_test_pet_equipment(row[0], row[1], 500))
		inv.pet_equipment_inventory_changed.emit()
		return {"success": true, "message": "获得一套单属性+500的开荒宠物装备"}
	if name == "宠物补章器":
		return gm.pet_manager.grant_random_medal_from_active_pet()
	if name == "宠物经验丹":
		var pet = gm.pet_manager.get_active_pet()
		if pet == null or pet.is_at_max_level():
			return {"success": false, "message": "没有出战宠物或宠物已满级，道具未消耗"}
		var old_level: int = pet.level
		var before: Dictionary = inv._snapshot_pet_medal_counts(pet)
		while pet.level < pet.get_effective_max_level():
			pet.level += 1
			var delta: float = gm.pet_manager._roll_level_growth_delta_for_pet(pet)
			for stat in ["attack", "defense", "agility"]:
				pet.growth_rates[stat] = snapped(float(pet.growth_rates[stat]) + delta * float(pet.stat_ratio.get(stat, 33.33)) / 100.0, 0.001)
		pet.total_growth = snapped(pet.growth_rates.attack + pet.growth_rates.defense + pet.growth_rates.agility, 0.001)
		pet.recalculate_stats()
		pet.hp = pet.max_hp
		pet.experience = 0
		pet.level_up.emit(pet.level)
		var medal_message: String = inv._finish_pet_upgrade_dan_medal_message(gm.pet_manager, pet, old_level, before)
		return {"success": true, "message": "宠物升至%d级（原客户端成长规则）\n%s" % [pet.level, medal_message]}
	if item.item_type == "pill":
		p.hp = mini(p.get_max_hp(), p.hp + int(cfg.get("hp_restore", 0)))
		p.mp = mini(p.get_max_mp(), p.mp + int(cfg.get("mp_restore", 0)))
		return {"success": true, "message": "已恢复生命/内力"}
	return {"success": false, "message": "此道具的奖励或使用规则由线上务器提供，当前缺少可核实配置；本次未消耗道具。材料请到对应锻造/洗练功能使用。"}
