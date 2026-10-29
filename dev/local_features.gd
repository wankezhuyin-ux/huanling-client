extends RefCounted

# Local services have their own namespace and never claim a cloud login.
static func action(gm, kind: String, args: Dictionary = {}) -> Dictionary:
	if gm.in_battle or gm._local_shop_busy:
		return {"success": false, "message": "请先停止战斗或等待当前操作完成"}
	var before: Dictionary = gm.create_secure_op_snapshot()
	gm._local_shop_busy = true
	var result: Dictionary = _apply(gm, kind, args)
	gm._local_shop_busy = false
	if not bool(result.get("commit", result.get("success", false))):
		gm.restore_secure_op_snapshot(before)
		return result
	if not gm.save_game():
		gm._local_shop_busy = true
		gm.restore_secure_op_snapshot(before)
		gm._local_shop_busy = false
		return {"success": false, "message": "存档失败，操作已回滚"}
	gm.gold_changed.emit(gm.player.gold)
	gm.inventory_manager.inventory_changed.emit()
	return result

static func _apply(gm, kind: String, args: Dictionary) -> Dictionary:
	var inv = gm.inventory_manager
	var p = gm.player
	match kind:
		"claim_pending_battle_item":
			var pending: Array = gm._local_metadata.get("pending_battle_items", [])
			var index: int = int(args.get("index", -1))
			if index < 0 or index >= pending.size():
				return {"success": false, "message": "待领取物品不存在"}
			var added: Dictionary = inv.add_item(str(pending[index]), 1)
			if bool(added.get("success", false)):
				pending.remove_at(index)
				gm._local_metadata.pending_battle_items = pending
			return added
		"store_item":
			return inv.move_to_warehouse(str(args.id))
		"withdraw_item":
			return inv.move_from_warehouse(str(args.id))
		"store_pet_equipment":
			return inv.move_pet_equipment_to_warehouse(str(args.id))
		"withdraw_pet_equipment":
			return inv.move_pet_equipment_from_warehouse(str(args.id))
		"store_equipment":
			var equipment = gm.equipment_manager.get_equipment_by_id(str(args.id))
			if equipment == null:
				return {"success": false, "message": "装备不存在"}
			var stored: Dictionary = inv.store_equipment_to_warehouse(equipment)
			if bool(stored.get("success", false)):
				gm.equipment_manager.inventory.erase(equipment)
			return stored
		"withdraw_equipment":
			if gm.equipment_manager.inventory.size() >= gm.equipment_manager.max_inventory:
				return {"success": false, "message": "装备背包已满"}
			var got: Dictionary = inv.retrieve_equipment_from_warehouse(str(args.id))
			if bool(got.get("success", false)):
				gm.equipment_manager.add_to_inventory(gm.equipment_manager.create_equipment_from_data(got.equipment))
			return got
		"craft":
			var check: Dictionary = gm.crafting_manager.can_craft(str(args.id), p.realm)
			if not bool(check.can_craft):
				return {"success": false, "message": str(check.message)}
			var result: Dictionary = gm.crafting_manager.craft(str(args.id), p.realm, p.level, p.cultivation)
			# An original-rule crafting failure still consumes its materials.
			result["commit"] = true
			return result
		"martial_equip", "martial_unequip", "martial_forget":
			for art in gm.martial_arts_manager.martial_arts:
				if str(art.id) == str(args.id):
					var ok := false
					if kind == "martial_equip":
						ok = gm.martial_arts_manager.equip_martial_art(art)
					elif kind == "martial_unequip":
						ok = gm.martial_arts_manager.unequip_martial_art(art)
					else:
						ok = gm.martial_arts_manager.forget_martial_art(art)
					return {"success": ok, "message": "武功操作已保存" if ok else "武功操作条件不满足"}
		"pet_active":
			for pet in gm.pet_manager.pets:
				if str(pet.id) == str(args.id):
					gm.pet_manager.active_pet = pet
					gm.pet_manager.active_pet_changed.emit(pet)
					return {"success": true, "message": "已切换出战灵兽"}
		"pet_lock":
			for pet in gm.pet_manager.pets:
				if str(pet.id) == str(args.id):
					pet.locked = not pet.locked
					return {"success": true, "message": "灵兽锁定状态已保存"}
		"pet_evolve", "pet_merge":
			var pm = gm.pet_manager
			var main_pet = pm.get_pet_by_stable_id(str(args.get("id", "")))
			if main_pet == null:
				return {"success": false, "message": "请选择宠物"}
			if kind == "pet_evolve":
				var check: Dictionary = pm.can_evolve(main_pet)
				if not bool(check.can):
					return {"success": false, "message": str(check.message)}
				var evolution = load("res://scripts/evolution_data.gd")
				var next_id: String = evolution.get_next_evolution(main_pet.pet_id, main_pet.is_mutant, main_pet.mutation_count)
				if next_id.is_empty():
					return {"success": false, "message": "进化链缺失"}
				var park = load("res://ui/city/pet_park.gd")
				var predicted: Dictionary = park._predict_evolve_growth_range(main_pet, gm)
				var grown: float = snapped(randf_range(float(predicted.min), float(predicted.max)), 0.001)
				for stat in ["attack", "defense", "agility"]:
					main_pet.growth_rates[stat] = snapped(grown * float(main_pet.stat_ratio.get(stat, 33.33)) / 100.0, 0.001)
				main_pet.total_growth = grown
				main_pet.growth_rates.hp = grown
				main_pet.pet_id = next_id
				main_pet.evolution_stage += 1
				main_pet.level = 1
				main_pet.experience = 0
				pm._sync_evolution_pet_identity_from_stage(main_pet)
				main_pet.recalculate_stats()
				return {"success": true, "message": "进化完成，等级重置为1级、经验清零；再次进化须重新达到500级。成长已按阶段、满级状态、代数及血统公式增加"}
			var sub_pet = pm.get_pet_by_stable_id(str(args.get("sub_id", "")))
			if sub_pet == null:
				return {"success": false, "message": "请选择副宠"}
			var check: Dictionary = pm.can_merge(main_pet, sub_pet, gm.player.realm)
			if not bool(check.can):
				return {"success": false, "message": str(check.message)}
			var tier: int = load("res://scripts/vip_benefits.gd").tier_from_player(gm.player)
			var weights: Array = [[5, 15, 30, 50], [15, 20, 30, 35], [20, 30, 40, 10], [30, 60, 10, 0]][clampi(tier, 0, 3)]
			var roll := randi_range(1, 100)
			var quality := 0
			var cumulative := 0
			for i in range(4):
				cumulative += int(weights[i])
				if roll <= cumulative:
					quality = i
					break
			var high: float = maxf(main_pet.total_growth, sub_pet.total_growth)
			var low: float = minf(main_pet.total_growth, sub_pet.total_growth)
			var totals: Array = [high, high * 0.8 + low * 0.2, high * 0.7 + low * 0.3, (high + low) * 0.5]
			var total: float = snapped(float(totals[quality]), 0.001)
			for stat in ["attack", "defense", "agility"]:
				main_pet.growth_rates[stat] = snapped(total * float(main_pet.stat_ratio.get(stat, 33.33)) / 100.0, 0.001)
			main_pet.total_growth = total
			main_pet.growth_rates.hp = total
			main_pet.locked = false
			main_pet.generation += 1
			main_pet.level = 1
			main_pet.experience = 0
			pm.pets.erase(sub_pet)
			if pm.active_pet == sub_pet:
				pm.active_pet = main_pet
			pm.remove_child(sub_pet)
			sub_pet.queue_free()
			main_pet.recalculate_stats()
			pm.pet_list_changed.emit()
			return {"success": true, "message": "本地模拟幻化完成：代数+1、回到1级、消耗副宠；成长已按指南H/L权重和VIP概率结算，血统仍继承主宠"}
		"pet_refine":
			var pets: Array = []
			for id in args.get("ids", []):
				for pet in gm.pet_manager.pets:
					if str(pet.id) == str(id):
						pets.append(pet)
			return gm.pet_manager.refine_pets(pets)
		"sim_signin", "sim_activity", "sim_guild", "sim_mail_send", "sim_mail_claim", "sim_trade_list", "sim_trade_cancel", "sim_trade_npc_buy":
			return _simulate(gm, kind, args)
	return {"success": false, "message": "操作目标不存在"}

static func _simulate(gm, kind: String, args: Dictionary) -> Dictionary:
	var state: Dictionary = gm._local_metadata.get("simulation", {"claims": {}, "mail": [], "listings": [], "guild": ""})
	gm._local_metadata.simulation = state
	var today := Time.get_date_string_from_system(true)
	match kind:
		"sim_signin", "sim_activity":
			var key := kind + "|" + today
			if state.claims.has(key):
				return {"success": false, "message": "本地模拟：今日已领取"}
			state.claims[key] = true
			gm.player.gold += 10000
			return {"success": true, "message": "本地模拟：获得测试奖励10000金币，原服奖励表待校准"}
		"sim_guild":
			state.guild = "水墨测试帮派" if str(state.guild).is_empty() else ""
			return {"success": true, "message": "本地模拟帮派：" + (str(state.guild) if not str(state.guild).is_empty() else "已退出")}
		"sim_mail_send":
			state.mail.append({"id": str(Time.get_ticks_usec()), "gold": 1000, "claimed": false})
			return {"success": true, "message": "本地模拟：测试邮件已送达，附件1000金币"}
		"sim_mail_claim":
			for mail in state.mail:
				if str(mail.id) == str(args.id) and not bool(mail.claimed):
					mail.claimed = true
					gm.player.gold += int(mail.gold)
					return {"success": true, "message": "本地模拟：邮件附件已领取"}
		"sim_trade_list":
			var item = gm.inventory_manager.get_item_by_id(str(args.id))
			var price: int = int(args.get("price", 10000))
			if item == null or price < 1 or not item.custom_data.is_empty() or item.item_type == "sealed_suit":
				return {"success": false, "message": "本地模拟：物品或价格无效"}
			var listing := {"id": str(Time.get_ticks_usec()), "name": item.name, "price": price, "data": item.to_dict()}
			var removed: Dictionary = gm.inventory_manager.remove_item(str(item.id), 1)
			if not bool(removed.get("success", false)):
				return removed
			state.listings.append(listing)
			return {"success": true, "message": "本地模拟：已上架1件，物品进入本地交易托管"}
		"sim_trade_cancel", "sim_trade_npc_buy":
			for i in range(state.listings.size()):
				var row: Dictionary = state.listings[i]
				if str(row.id) != str(args.id):
					continue
				if kind == "sim_trade_cancel":
					var added: Dictionary = gm.inventory_manager.add_item(str(row.name), 1)
					if not bool(added.get("success", false)):
						return added
					var item = added.item
					item.custom_data = row.data.get("custom_data", {}).duplicate(true)
				else:
					gm.player.gold += int(row.price)
				state.listings.remove_at(i)
				return {"success": true, "message": "本地模拟：已撤回物品" if kind == "sim_trade_cancel" else "本地模拟：NPC成交，金币已到账（无税费模拟）"}
	return {"success": false, "message": "本地模拟：目标不存在或已处理，未重复发奖"}
