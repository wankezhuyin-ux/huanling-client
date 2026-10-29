extends Control

var gm
var feature := "warehouse"
var body: VBoxContainer
var feedback: Label
const TITLES := {"warehouse": "仓库", "qiankun": "乾坤坊", "forge_main": "打造坊", "martial": "武学堂", "pet_park": "灵兽园", "ranking": "排行榜 · 线上快照", "signin7": "签到 · 线上快照", "gang_hall": "帮派 · 本地模拟", "mail": "邮件 · 本地模拟", "trade": "交易 · 本地模拟", "activity": "活动 · 线上快照", "world": "世界传闻 · 线上快照", "online_rules": "线上数值 · 日志采样校准", "online_modules": "玩法配置 · 线上模块"}

static func create_fullscreen(manager, key: String) -> Control:
	var panel = load("res://dev/local_feature_ui.gd").new()
	panel.gm = manager
	panel.feature = key
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("172d29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 16
	scroll.offset_right = -16
	add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	_refresh()

func _label(value: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	body.add_child(label)
	return label

func _button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	body.add_child(button)

func _operation(kind: String, args: Dictionary = {}) -> void:
	var result: Dictionary = gm.local_feature_action(kind, args)
	var message := str(result.get("message", "操作完成"))
	_refresh()
	feedback.text = message

func _refresh() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	_label(str(TITLES.get(feature, feature)), 28)
	_label("本地测试存档 · 金币%d · 元宝%d" % [gm.player.gold, gm.player.yuanbao_currency], 18)
	var nav := HFlowContainer.new()
	body.add_child(nav)
	for key in TITLES:
		var button := Button.new()
		button.text = str(TITLES[key])
		button.custom_minimum_size.y = 40
		button.pressed.connect(func(): feature = key; _refresh())
		nav.add_child(button)
	feedback = _label("操作会保存到本地；带‘本地模拟’的奖池、奖励与跨玩家数据不代表线上规则。", 18)
	var inv = gm.inventory_manager
	match feature:
		"warehouse":
			var pending: Array = gm._local_metadata.get("pending_battle_items", [])
			for i in range(pending.size()):
				_button("领取背包满时暂存的掉落：" + str(pending[i]), _operation.bind("claim_pending_battle_item", {"index": i}))
			_label("背包 → 仓库", 24)
			for item in inv.items:
				_button("存入 %s ×%d" % [item.name, item.count], _operation.bind("store_item", {"id": item.id}))
			for equipment in gm.equipment_manager.inventory:
				_button("存入人物装备：" + str(equipment.name), _operation.bind("store_equipment", {"id": equipment.id}))
			for equipment in inv.pet_equipment_items:
				_button("存入灵兽装备：" + str(equipment.get("name", "")), _operation.bind("store_pet_equipment", {"id": equipment.id}))
			_label("仓库 → 背包", 24)
			for item in inv.warehouse_items:
				_button("取出 %s ×%d" % [item.name, item.count], _operation.bind("withdraw_item", {"id": item.id}))
			for equipment in inv.equipment_warehouse:
				_button("取出人物装备：" + str(equipment.name), _operation.bind("withdraw_equipment", {"id": equipment.id}))
			for equipment in inv.pet_equipment_warehouse:
				_button("取出灵兽装备：" + str(equipment.name), _operation.bind("withdraw_pet_equipment", {"id": equipment.id}))
		"qiankun", "forge_main":
			_label("原客户端配方、材料、境界与成功率；打造失败按原规则消耗材料。", 18)
			for id in gm.GameData.CRAFTING_RECIPES:
				var recipe: Dictionary = gm.GameData.CRAFTING_RECIPES[id]
				_label("%s · 成功率%.0f%% · 材料%s" % [recipe.get("name", id), float(recipe.get("success_rate", 0.5)) * 100.0, str(recipe.get("materials", {}))], 18)
				_button("打造一次", _operation.bind("craft", {"id": id}))
		"martial":
			_label("使用背包中的人物技能书领悟；效果与装备限制沿用客户端。未知层数分布暂用1–9均匀模拟。", 18)
			for art in gm.martial_arts_manager.martial_arts:
				_label("%s · 第%d层" % [art.name, art.layer])
				var equipped: bool = gm.martial_arts_manager.equipped_arts.has(art)
				_button("卸下" if equipped else "装备", _operation.bind("martial_unequip" if equipped else "martial_equip", {"id": art.id}))
		"pet_park":
			_label("技能书从背包使用；切换出战、锁定在此直接保存。", 18)
			_label("进化/幻化为本地模拟：进化重置为1级、保留成长；幻化消耗副宠、主宠代数+1并回到1级，保留主宠成长技能。线上增益/概率待校准。", 18)
			for pet in gm.pet_manager.pets:
				var evolution_check: Dictionary = gm.pet_manager.can_evolve(pet)
				_button("进化：" + str(pet.pet_name), _operation.bind("pet_evolve", {"id": pet.id}))
				_label("进化条件：" + ("已满足" if evolution_check.can else str(evolution_check.message)), 16)
				_label("%s Lv.%d · 成长%.3f%s" % [pet.pet_name, pet.level, pet.total_growth, " · 出战" if pet == gm.pet_manager.active_pet else ""])
				_button("设为出战", _operation.bind("pet_active", {"id": pet.id}))
				_button("解除锁定" if pet.locked else "锁定", _operation.bind("pet_lock", {"id": pet.id}))
			var main_pick := OptionButton.new()
			var sub_pick := OptionButton.new()
			for pet in gm.pet_manager.pets:
				main_pick.add_item("主宠：%s Lv.%d %d代" % [pet.pet_name, pet.level, pet.generation])
				sub_pick.add_item("副宠：%s Lv.%d %d代" % [pet.pet_name, pet.level, pet.generation])
			body.add_child(main_pick)
			body.add_child(sub_pick)
			_button("幻化（本地模拟）", func():
				if main_pick.selected < 0 or sub_pick.selected < 0:
					return
				var args := {"id": gm.pet_manager.pets[main_pick.selected].id, "sub_id": gm.pet_manager.pets[sub_pick.selected].id}
				var confirm := ConfirmationDialog.new()
				confirm.dialog_text = "本地模拟幻化会消耗所选副宠，主宠代数+1并回到1级。确认所选宠物后继续。"
				confirm.confirmed.connect(func(): _operation("pet_merge", args); confirm.queue_free())
				confirm.canceled.connect(confirm.queue_free)
				add_child(confirm)
				confirm.popup_centered(Vector2i(420, 220))
			)
		"ranking":
			_label("本机数据（不是全服排名）", 22)
			_label("人物：%s Lv.%d · 攻击%d · 防御%d" % [gm.player.player_name, gm.player.level, gm.player.get_attack(), gm.player.get_defense()])
			var rows: Array = gm.pet_manager.pets.duplicate()
			rows.sort_custom(func(a, b): return a.total_growth > b.total_growth)
			for i in range(rows.size()):
				_label("%d. %s Lv.%d · 成长%.3f" % [i + 1, rows[i].pet_name, rows[i].level, rows[i].total_growth])
			_label("", 12)
			var snapshot := load("res://dev/local_snapshot.gd")
			var online: Array = snapshot.ranking()
			_label("全服排行 · " + str(snapshot.header_note()), 18)
			if online.is_empty():
				_label("快照缺失，无法显示全服排行。", 18)
			else:
				_label("以下是线上服真实返回的榜单（共%d条，按线上顺序显示前50条，未做虚构补全）。" % online.size(), 16)
				for i in range(mini(50, online.size())):
					var row: Dictionary = online[i]
					_label("%d. %s · Lv.%d · %s · 修为%d · 投胎%d" % [i + 1, str(row.get("nickname", "")), int(row.get("level", 0)), str(row.get("realm", "")), int(row.get("cultivation", 0)), int(row.get("reincarnation", 0))], 18)
		"signin7", "activity":
			var snapshot7 := load("res://dev/local_snapshot.gd")
			if feature == "signin7":
				var cfg: Dictionary = snapshot7.signin7()
				_label("七日签到 · 线上配置（" + snapshot7.header_note() + "）", 18)
				if cfg.is_empty():
					_label("快照缺失。", 18)
				else:
					_label("活动：%s" % str(cfg.get("title", "")), 22)
					_label("周期：%s ~ %s" % [str(cfg.get("start_text", "")), str(cfg.get("end_text", ""))], 18)
					_label("线上状态：%s（%s）" % [str(cfg.get("message", "")), str(cfg.get("reason", ""))], 18)
					var days: Array = cfg.get("days", [])
					for day in days:
						if day is Dictionary:
							_label("第%d天 · %s" % [int(day.get("day", 0)), str(day.get("name", ""))], 18)
				_label("", 10)
				_label("下面的按钮是本地测试发奖，不写入线上活动进度：", 16)
				_button("领取本地测试奖励（10000金币）", _operation.bind("sim_signin"))
			else:
				var events: Dictionary = snapshot7.festival()
				_label("节日活动 · 线上配置（" + snapshot7.header_note() + "）", 18)
				if events.is_empty():
					_label("快照缺失。", 18)
				else:
					for key in events:
						var ev: Variant = events[key]
						if not ev is Dictionary:
							continue
						_label("%s · %s" % [str(key), str(ev.get("gift_name", ""))], 22)
						var sale: Variant = ev.get("shop_sale", {})
						if sale is Dictionary and not sale.is_empty():
							_label("  商城：%s" % str(sale.get("banner_text", "")), 18)
						var spawn: Variant = ev.get("wild_spawn", {})
						if spawn is Dictionary and not spawn.is_empty():
							_label("  野外稀有：%s（%d级以上地图，万分之%.1f）" % [str(spawn.get("pet_id", "")), int(spawn.get("min_map_level", 0)), float(spawn.get("spawn_rate", 0.0)) * 10000.0], 18)
				_label("", 10)
				_label("下面的按钮是本地测试发奖，不写入线上活动进度：", 16)
				_button("领取本地测试奖励（10000金币）", _operation.bind("sim_activity"))
		"online_rules":
			var snap := load("res://dev/local_snapshot.gd")
			_label("线上数值校准 · " + str(snap.header_note()), 20)
			if not snap.has_rules():
				_label("快照缺少 rules 段，请重跑 replay/build_calibration.py。", 18)
			else:
				var tower: Dictionary = snap.rules_key("tower")
				_label("【训练塔】当前 %d 层 · 历史最高 %d · 开放上限 %d · 总上限 %d" % [int(tower.get("towerFloor", 0)), int(tower.get("towerHighest", 0)), int(tower.get("openMaxFloor", 0)), int(tower.get("maxFloor", 0))], 18)
				var suit: Dictionary = snap.rules_key("suit_dungeon")
				_label("【套装副本】每日扫荡 %d 次" % int(suit.get("maxSweeps", 0)), 18)
				var five: Dictionary = snap.rules_key("five_elements")
				_label("【五行副本】每日 %d 次 + 元宝 %d 次（开启：%s）" % [int(five.get("maxAttempts", 0)), int(five.get("yuanbaoMaxAttempts", 0)), str(five.get("enabled", false))], 18)
				var atlas: Dictionary = snap.rules_key("atlas_dungeon")
				var tiers: Dictionary = atlas.get("tiers", {})
				for key in tiers:
					var tier: Variant = tiers[key]
					if tier is Dictionary:
						_label("【图鉴副本·%s】%d 波 / 每日 %d 次 / 入场 %d 金币" % [str(tier.get("label", key)), int(tier.get("waveCount", 0)), int(tier.get("maxAttempts", 0)), int(tier.get("entryCost", 0))], 18)
				var bro: Dictionary = snap.rules_key("brother_tower")
				_label("【兄弟天关】每日通关 %d 次 · 领奖 %d 次" % [int(bro.get("dailyClearMax", 0)), int(bro.get("dailyRewardMax", 0))], 18)
				var treasure: Dictionary = snap.rules_key("treasure")
				_label("【藏宝】每日参团上限 %d 次" % int(treasure.get("dailyJoinLimit", 0)), 18)
				var pity: Dictionary = snap.rules_key("lottery_pity")
				_label("【抽奖保底】%d 次必出，当前计数 %d" % [int(pity.get("threshold", 0)), int(pity.get("count", 0))], 18)
				var noble: Dictionary = snap.rules_key("noble")
				_label("【贵族】%s · 累计消耗 %d · 下一档 %d" % [str(noble.get("nobleName", "")), int(noble.get("totalConsumed", 0)), int(noble.get("nextThreshold", 0))], 18)
				var martial_rules: Dictionary = snap.rules_key("martial")
				_label("【武学】基础成功率 %.0f%% · 服务端生效 %.0f%% · 贵族加成 %d" % [float(martial_rules.get("baseSuccessRate", 0.0)) * 100.0, float(martial_rules.get("serverSuccessRate", 0.0)) * 100.0, int(martial_rules.get("nobleBonus", 0))], 18)
				var catchup: Dictionary = snap.rules_key("catchup")
				_label("【投胎追赶】开启 %s · 差距 %d 世 · 单场最多升 %d 级" % [str(catchup.get("enabled", false)), int(catchup.get("gap", 0)), int(catchup.get("field_max_level_ups", 0))], 18)
				_label("", 10)
				_label("【真实掉落率】", 22)
				var drops: Dictionary = snap.drop_rates()
				var names: Array = drops.keys()
				names.sort_custom(func(a, b): return float(drops[a]) > float(drops[b]))
				for name in names:
					_label("　%s　%.3f%%" % [str(name), float(drops[name]) * 100.0], 18)
				_label("", 10)
				var pr: Dictionary = snap.reference_player()
				if not pr.is_empty():
					_label("【线上真实角色 vs 本地】", 22)
					_label("　等级　线上 %d ／ 本地 %d" % [int(pr.get("level", 0)), gm.player.level], 18)
					_label("　金币　线上 %d ／ 本地 %d" % [int(pr.get("gold", 0)), gm.player.gold], 18)
					_label("　修为　线上 %d ／ 本地 %d" % [int(pr.get("cultivation", 0)), gm.player.cultivation], 18)
					_label("　攻击　线上 %d ／ 本地 %d" % [int(pr.get("final_attack", 0)), gm.player.get_attack()], 18)
					_label("　防御　线上 %d ／ 本地 %d" % [int(pr.get("final_defense", 0)), gm.player.get_defense()], 18)
					_label("　血上限　线上 %d ／ 本地 %d" % [int(pr.get("final_max_hp", 0)), gm.player.get_max_hp()], 18)
					_label("　境界　线上 %s ／ 本地 %s · 投胎 %d ／ %d" % [str(pr.get("realm", "")), str(gm.player.realm), int(pr.get("reincarnation", 0)), int(gm.player.reincarnation)], 18)
				var growth: Dictionary = snap.data().get("pet_growth_reference", {})
				if not growth.is_empty():
					_label("【灵兽成长率分布】%d 只 · %.3f ~ %.3f · 均值 %.3f" % [int(growth.get("count", 0)), float(growth.get("min", 0.0)), float(growth.get("max", 0.0)), float(growth.get("avg", 0.0))], 18)
				var meta: Dictionary = snap.save_meta()
				if not meta.is_empty():
					_label("【线上存档规模】灵兽 %d 只 · 灵兽袋 %d · 物品 %d 类 · 任务 %d 类 · 当前地图 %s" % [int(meta.get("pet_count", 0)), int(meta.get("pet_bag_count", 0)), int(meta.get("item_kinds", 0)), int(meta.get("quest_kinds", 0)), str(meta.get("current_map", ""))], 18)
				_label("", 10)
				_label("【商城真实价格】共 %d 件，前 20 件：" % snap.shop_items().size(), 22)
				var items: Array = snap.shop_items()
				for i in range(mini(20, items.size())):
					var it: Variant = items[i]
					if it is Dictionary:
						_label("　%s　%s %d（原价 %d）%s" % [str(it.get("itemName", "")), str(it.get("currency", "")), int(it.get("finalPrice", 0)), int(it.get("basePrice", 0)), ("　限购 %d" % int(it.get("dailyLimit", 0))) if int(it.get("dailyLimit", 0)) > 0 else ""], 18)
		"online_modules":
			var snapm := load("res://dev/local_snapshot.gd")
			var module_names: Array = snapm.rules_module_names()
			_label("线上玩法配置 · %d 个模块 · 来源 %s" % [module_names.size(), str(snapm.rules_modules_meta().get("source", "未知"))], 20)
			_label("字段名与服务端一致（camelCase）。取值：snap.rules_module(\"world_boss\") 或 snap.module_value(\"arena\",\"dailyMaxAttempts\")。", 18)
			if module_names.is_empty():
				_label("快照缺少 rules_modules 段，请重跑 replay/build_rules_modules.py。", 18)
			else:
				_label("【世界 Boss】HP %d · 攻 %d · 防 %d · 敏 %d · 每日 %d 次 · %d 回合 · %02d:%02d-%02d:%02d" % [int(snapm.module_value("world_boss", "bossHp", 0)), int(snapm.module_value("world_boss", "bossAttack", 0)), int(snapm.module_value("world_boss", "bossDefense", 0)), int(snapm.module_value("world_boss", "bossAgility", 0)), int(snapm.module_value("world_boss", "dailyMaxAttempts", 0)), int(snapm.module_value("world_boss", "battleMaxRounds", 0)), int(snapm.module_value("world_boss", "challengeStartHour", 0)), int(snapm.module_value("world_boss", "challengeStartMinute", 0)), int(snapm.module_value("world_boss", "challengeEndHour", 0)), int(snapm.module_value("world_boss", "challengeEndMinute", 0))], 18)
				_label("【竞技场】每日 %d 次 · %d 回合 · 胜 +%d 负 +%d · 匹配 ±%d · %02d:%02d-%02d:%02d · 连胜档 %d · 称号 %d" % [int(snapm.module_value("arena", "dailyMaxAttempts", 0)), int(snapm.module_value("arena", "battleMaxRounds", 0)), int(snapm.module_value("arena", "winScoreDelta", 0)), int(snapm.module_value("arena", "loseScoreDelta", 0)), int(snapm.module_value("arena", "matchScoreBand", 0)), int(snapm.module_value("arena", "challengeStartHour", 0)), int(snapm.module_value("arena", "challengeStartMinute", 0)), int(snapm.module_value("arena", "challengeEndHour", 0)), int(snapm.module_value("arena", "challengeEndMinute", 0)), snapm.module_count("arena", "streakMilestones"), snapm.module_count("arena", "titleNames")], 18)
				var floors: Array = snapm.module_list("shengsi_tower", "floors")
				_label("【生死塔】%d 层 · 每队 %d 人 · 每日 %d 次 · 报名 %02d:%02d 开赛 %02d:%02d" % [floors.size(), int(snapm.module_value("shengsi_tower", "teamMaxMembers", 0)), int(snapm.module_value("shengsi_tower", "dailyLimitPerUser", 0)), int(snapm.module_value("shengsi_tower", "signupStartHour", 0)), int(snapm.module_value("shengsi_tower", "signupStartMinute", 0)), int(snapm.module_value("shengsi_tower", "startHour", 0)), int(snapm.module_value("shengsi_tower", "startMinute", 0))], 18)
				_label("【兄弟天关】%d 波 × %d 只 · 每日通关 %d 次 · 领奖 %d 次 · 难度 %d 档" % [int(snapm.module_value("brother_tower", "waveCount", 0)), int(snapm.module_value("brother_tower", "monstersPerWave", 0)), int(snapm.module_value("brother_tower", "dailyClearMax", 0)), int(snapm.module_value("brother_tower", "dailyRewardMax", 0)), snapm.module_count("brother_tower", "difficulties")], 18)
				_label("【无限天关】上限 %d 层 · 当前开放 %d · %d 回合 · 投胎门槛 %d 条" % [int(snapm.module_value("tower", "maxFloor", 0)), int(snapm.module_value("tower", "openMaxFloor", 0)), int(snapm.module_value("tower", "battleMaxRounds", 0)), snapm.module_count("tower", "reincarnationGates")], 18)
				_label("【抽奖】金币池 %d 金币 / %d 档 · 元宝池 %d 元宝 / %d 档 · 保底 %d 次选 %d 项" % [int(snapm.module_value("lottery", "pools.gold.cost.amount", 0)), snapm.module_count("lottery", "pools.gold.rewards"), int(snapm.module_value("lottery", "pools.yuanbao.cost.amount", 0)), snapm.module_count("lottery", "pools.yuanbao.rewards"), int(snapm.module_value("lottery", "pity.threshold", 0)), snapm.module_count("lottery", "pity.options")], 18)
				_label("【藏宝洞】%d 档奖励 · 报名 %d 分 · 战斗 %d 分 · 开放 %d-%d 点" % [snapm.module_count("treasure", "rewards"), int(snapm.module_value("treasure", "signupMinutes", 0)), int(snapm.module_value("treasure", "battleMinutes", 0)), int(snapm.module_value("treasure", "openStartHour", 0)), int(snapm.module_value("treasure", "openEndHourExclusive", 0))], 18)
				_label("【法宝】%d 阶 · 掉落 1/%d · 最低地图 %d · 合成 %d 碎片 · %d 条随机词条" % [snapm.module_count("fabao", "tiers"), int(snapm.module_value("fabao", "dropDenom", 0)), int(snapm.module_value("fabao", "minMapLevel", 0)), int(snapm.module_value("fabao", "synthFragmentCount", 0)), int(snapm.module_value("fabao", "randomAffixCount", 0))], 18)
				_label("【野外战斗】每场 %d-%d 只 · 经验系数 %.2f · 每级经验 %d · 金币 %d · %d 回合" % [int(snapm.module_value("gameplay", "wildBattle.spawnMin", 0)), int(snapm.module_value("gameplay", "wildBattle.spawnMax", 0)), float(snapm.module_value("gameplay", "wildBattle.fieldExpMultiplier", 0.0)), int(snapm.module_value("gameplay", "wildBattle.monsterExpPerLevel", 0)), int(snapm.module_value("gameplay", "wildBattle.monsterGoldPerLevel", 0)), int(snapm.module_value("gameplay", "wildBattle.battleMaxRounds", 0))], 18)
				_label("【等级经验】突破 %d 级 · 突破前系数 %.1f · 突破后 base %d ×%.1f^n" % [int(snapm.module_value("gameplay", "playerLevelExp.breakLevel", 0)), float(snapm.module_value("gameplay", "playerLevelExp.preBreakCoeff", 0.0)), int(snapm.module_value("gameplay", "playerLevelExp.postBreakBase", 0)), float(snapm.module_value("gameplay", "playerLevelExp.postBreakGrowthCoeff", 0.0))], 18)
				_label("【宠物】技能 %d 个 · 开箱道具 %d 种 · 魂魄转生成功率 %.0f%% · 主动技能格 默认 %d 最高 %d" % [snapm.skills().size(), snapm.pet_open_items().size(), float(snapm.module_value("pet_soul", "rebirthChance", 0.0)) * 100.0, int(snapm.module_value("pet_skill_slots", "defaultSlotCount", 0)), int(snapm.module_value("pet_skill_slots", "maxSlotCount", 0))], 18)
				_label("", 10)
				_label("【全部模块】", 22)
				for module_name in module_names:
					var cfg: Dictionary = snapm.rules_module(str(module_name))
					var brief := ""
					if cfg.has("descriptionText"):
						brief = str(cfg["descriptionText"]).replace("\n", " ").substr(0, 40)
					_label("　%s　%d 字段　%s" % [str(module_name), cfg.size(), brief], 18)
		"world":
			var snapshot_world := load("res://dev/local_snapshot.gd")
			var broadcasts: Array = snapshot_world.broadcasts()
			_label("世界传闻 · " + str(snapshot_world.header_note()), 18)
			_label("线上服当前没有可拉取的世界频道消息（/api/messages 返回空列表），以下是同批抓到的系统传闻广播。", 16)
			if broadcasts.is_empty():
				_label("快照缺失。", 18)
			else:
				for b in broadcasts:
					if b is Dictionary:
						_label("[%s] %s" % [str(b.get("type", "")), str(b.get("content", ""))], 20)
						_label("　—— %s · %s" % [str(b.get("nickname", "")), str(b.get("created_at", ""))], 16)
		"gang_hall":
			_label("本地模拟：加入或退出本机测试帮派，不添加未经校准的战斗加成。", 18)
			_label("当前帮派：" + str(gm._local_metadata.get("simulation", {}).get("guild", "无")))
			_button("加入 / 退出测试帮派", _operation.bind("sim_guild"))
		"mail":
			_button("生成一封测试邮件（1000金币附件）", _operation.bind("sim_mail_send"))
			for mail in gm._local_metadata.get("simulation", {}).get("mail", []):
				if not bool(mail.claimed):
					_button("领取测试邮件：1000金币", _operation.bind("sim_mail_claim", {"id": mail.id}))
		"trade":
			_label("本地模拟：每件测试售价10000金币，无税费。上架会暂存真实物品，可撤单或由模拟NPC购买。", 18)
			for item in inv.items:
				if item.custom_data.is_empty() and not item.name.is_empty():
					_button("上架1件：" + str(item.name), _operation.bind("sim_trade_list", {"id": item.id, "price": 10000}))
			for listing in gm._local_metadata.get("simulation", {}).get("listings", []):
				_label("本地在售：" + str(listing.name))
				_button("撤回", _operation.bind("sim_trade_cancel", {"id": listing.id}))
				_button("模拟NPC购买", _operation.bind("sim_trade_npc_buy", {"id": listing.id}))
