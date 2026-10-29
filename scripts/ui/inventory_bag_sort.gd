extends RefCounted
class_name InventoryBagSort



const GameData = preload("res://scripts/game_data.gd")


const RARE_PET_SKILL_NAMES: = [
	"溅射", "反击", "神佑", "连射", "吸血", "破甲", "格挡", "必杀", "嘲讽", 
]


# 钱币袋（原「金币袋」）在 2026-10 合并成一种道具：单个 10 万金币，归到「其它」分页。
# 旧存档里还可能有下面这些赞助者命名的钱袋，读档时会被 from_dict 合并成「钱币袋」，
# 这里保留名单是为了图标 / 兼容判断（迁移前的一帧、或服务端老存档回包）。
const COIN_BAG_ITEM_NAME: = "钱币袋"
const LEGACY_GOLD_BAG_NAMES: = [
	"醉剑", "1万金币袋（醉）", "神的遗愿", "风歌夜曲", "摆烂松", "人间大炮", 
	"我的理想", "板砖", "立羽", "铭大大", "长空秋雁", "大橘大利", "人间事", "思念", 
]


static func is_gold_bag_name(item_name: String) -> bool:
	var n: = item_name.strip_edges()
	if n.is_empty():
		return false
	if n == COIN_BAG_ITEM_NAME:
		return true
	if LEGACY_GOLD_BAG_NAMES.has(n):
		return true
	return n.contains("金币袋")


static func _item_name(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("name", "")).strip_edges()
	if "name" in item:
		return str(item.name).strip_edges()
	return ""


static func _item_type(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("item_type", item.get("type", ""))).strip_edges().to_lower()
	if "item_type" in item:
		return str(item.item_type).strip_edges().to_lower()
	return ""


static func _catalog_type(item_name: String) -> String:
	if item_name.is_empty() or not GameData.ALL_ITEMS.has(item_name):
		return ""
	var cfg = GameData.ALL_ITEMS[item_name]
	if cfg is Dictionary:
		return str(cfg.get("type", "")).strip_edges().to_lower()
	return ""


static func _catalog_desc(item_name: String) -> String:
	if item_name.is_empty() or not GameData.ALL_ITEMS.has(item_name):
		return ""
	var cfg = GameData.ALL_ITEMS[item_name]
	if cfg is Dictionary:
		return str(cfg.get("desc", ""))
	return ""


static func _is_gold_bag_item(item) -> bool:
	var n: = _item_name(item)
	if is_gold_bag_name(n):
		return true
	# 名单外的老钱袋：描述里同时出现「赞助」和「金币」的也算（读档时一起并入钱币袋）
	if n.is_empty():
		return false
	var desc: = _catalog_desc(n)
	return desc.contains("赞助") and desc.contains("金币")


static func _is_pet_related_gift_name(item_name: String) -> bool:
	return item_name.contains("宠物")


static func _is_level_up_pill_name(item_name: String) -> bool:
	var name_s: = item_name.strip_edges()
	return name_s == "人物升级丹" or name_s == "宠物升级丹" or name_s.ends_with("升级丹")


static func _is_double_exp_pill_name(item_name: String) -> bool:

	return item_name.strip_edges().begins_with("双倍经验丹")


static func _is_pet_medal_tool_name(item_name: String) -> bool:
	return item_name.strip_edges() == "宠物补章器"


static func is_rare_pet_skill_book_name(item_name: String) -> bool:
	for skill_name in RARE_PET_SKILL_NAMES:
		if item_name.begins_with(str(skill_name)):
			return true
	return false


static func item_filter_category(item) -> String:
	# 钱币袋统一归到「其它」（原来单独一个「金币袋」分页，已被合并去掉）
	if _is_gold_bag_item(item):
		return "other"

	var name_for_pill: = _item_name(item)
	if _is_level_up_pill_name(name_for_pill) or _is_double_exp_pill_name(name_for_pill):
		return "pill"

	if _is_pet_medal_tool_name(name_for_pill):
		return "other"
	var t: = _item_type(item)
	if t.is_empty():
		t = _catalog_type(_item_name(item))
	match t:
		"gift":
			return "gift"
		"martial_skill_book", "pet_skill_book":
			return "skill_book"
		"pill", "cultivation_pill":
			return "pill"
		"pet_egg":
			return "pet_egg"
		"pet_soul_item":
			return "pet_soul"
		"treasure_chest", "chest":
			return "chest"
		_:
			return "other"


static func material_filter_category(item) -> String:
	if item == null:
		return "other"
	if item is Dictionary and str(item.get("entry_kind", "")) == "limit_material_aggregate":
		return "limit"
	var item_name: = _item_name(item)

	if item_name.contains("令牌"):
		return "token"

	if FabaoConfig.is_fragment_name(item_name):
		return "other"
	var cd: Dictionary = {}
	if item is Dictionary:
		var raw_cd = item.get("custom_data", {})
		if raw_cd is Dictionary:
			cd = raw_cd
	elif "custom_data" in item and item.custom_data is Dictionary:
		cd = item.custom_data
	if bool(cd.get("is_limit_equip", false)):
		return "limit"
	if ForgeData.is_limit_forge_material_name(item_name):
		return "limit"

	var catalog_t: = _catalog_type(item_name)
	if catalog_t == "herb":
		return "herb"
	var t: = _item_type(item)
	if t.is_empty():
		t = catalog_t
	match t:
		"herb":
			return "herb"
		"material":
			return "forge"
		"limit_equip":
			return "limit"
		_:
			return "other"


static func _is_tower_family_gift_name(item_name: String) -> bool:
	var name_s: = item_name.strip_edges()
	if name_s.is_empty():
		return false

	return name_s == "天关礼包" or (name_s.ends_with("关礼包") and name_s != "兄弟天关礼包")


static func _tower_gift_floor_order(item_name: String) -> int:
	var name_s: = item_name.strip_edges()
	if name_s == "天关礼包":
		return 0

	var digits: = ""
	for i in range(name_s.length()):
		var ch: = name_s.substr(i, 1)
		if ch >= "0" and ch <= "9":
			digits += ch
		elif not digits.is_empty():
			break
	if digits.is_empty():
		return 99999
	return int(digits)


static func _is_arena_gift_name(item_name: String) -> bool:
	return item_name in ["冠军礼包", "亚军礼包", "季军礼包", "十强礼包"]


static func _is_starter_special_gift_name(item_name: String) -> bool:
	return item_name in ["新手礼包", "内测先锋礼包", "新人扶持礼包", "开荒礼包", "开荒宠装礼包", "测试礼包", "测试宠物装备礼包"]


static func _is_limit_or_wudao_gift_name(item_name: String) -> bool:
	return item_name.contains("极限") or item_name.contains("悟道")


static func _is_pet_gift_family_name(item_name: String) -> bool:
	if item_name.is_empty():
		return false
	if _is_pet_related_gift_name(item_name):
		return true
	if item_name.contains("可进化") or item_name.contains("不可进化"):
		return true
	if item_name.contains("仙魔") or item_name.contains("变异"):
		return true
	if item_name.contains("离线") and item_name.contains("礼包"):
		return true
	return false



static func _gift_family_pri(item_name: String) -> int:
	if _is_tower_family_gift_name(item_name):
		return 0
	if item_name == "兄弟天关礼包":
		return 1
	if item_name == "世界boss礼包":
		return 2
	if _is_arena_gift_name(item_name):
		return 3
	if FestivalGiftManager.is_festival_gift(item_name):
		return 4
	if _is_pet_gift_family_name(item_name):
		return 5
	if _is_starter_special_gift_name(item_name):
		return 6
	if _is_limit_or_wudao_gift_name(item_name):
		return 7
	return 80


static func _item_sort_key(item) -> Array:
	var cat: = item_filter_category(item)
	var pri: = 90
	match cat:
		"gift":
			pri = 0
		"skill_book":
			pri = 10
		"pill":
			pri = 20
		"gold_bag":
			pri = 30
		"pet_egg":
			pri = 40
		"pet_soul":
			pri = 50
		"chest":
			pri = 60
		_:
			pri = 90
	# 钱币袋虽然归「其它」，但仍是高频道具，排在其它分页最前面
	if cat == "other" and is_gold_bag_name(_item_name(item)):
		pri = 30
	var name_s: = _item_name(item)
	var family: = 0
	var family_order: = 0
	if cat == "gift":
		family = _gift_family_pri(name_s)
		if family == 0:
			family_order = _tower_gift_floor_order(name_s)
		elif family == 3:

			match name_s:
				"冠军礼包":
					family_order = 0
				"亚军礼包":
					family_order = 1
				"季军礼包":
					family_order = 2
				"十强礼包":
					family_order = 3
				_:
					family_order = 9
		elif family == 5:

			var is_mutation: = name_s.contains("变异")
			if is_mutation:
				if name_s.contains("可进化") and not name_s.contains("不可进化"):
					family_order = 20
				elif name_s.contains("不可进化"):
					family_order = 21
				else:
					family_order = 22
			elif name_s.contains("可进化") and not name_s.contains("不可进化"):
				family_order = 0
			elif name_s.contains("不可进化"):
				family_order = 1
			elif name_s.contains("仙魔"):
				family_order = 30
			else:
				family_order = 40
	elif cat == "skill_book":
		var t: = _item_type(item)
		if t.is_empty():
			t = _catalog_type(name_s)
		family = 0 if t == "pet_skill_book" else 1
		if family == 0:
			family_order = 0 if is_rare_pet_skill_book_name(name_s) else 1
	return [pri, family, family_order, name_s]


static func _material_sort_key(item) -> Array:
	var cat: = material_filter_category(item)
	var pri: = 90
	match cat:
		"forge":
			pri = 0
		"herb":
			pri = 10
		"token":
			pri = 20
		"limit":
			pri = 30
		_:
			pri = 90
	return [pri, _item_name(item)]


static func _item_matches_filter(cat: String, filter_key: String) -> bool:
	if filter_key.is_empty() or filter_key == "all":
		return true
	if filter_key == "other":
		return cat in ["other", "pet_egg", "pet_soul", "chest"]
	return cat == filter_key


static func sort_and_filter_items(items: Array, filter_key: String) -> Array:
	var filtered: Array = []
	for item in items:
		var cat: = item_filter_category(item)
		if _item_matches_filter(cat, filter_key):
			filtered.append(item)
	filtered.sort_custom( func(a, b): return _item_sort_key(a) < _item_sort_key(b))
	return filtered


static func sort_and_filter_materials(items: Array, filter_key: String) -> Array:
	var filtered: Array = []
	for item in items:
		var cat: = material_filter_category(item)
		if filter_key.is_empty() or filter_key == "all" or cat == filter_key:
			filtered.append(item)
	filtered.sort_custom( func(a, b): return _material_sort_key(a) < _material_sort_key(b))
	return filtered


static func _equip_field(eq, key: String, default_val = null):
	if eq == null:
		return default_val
	if eq is Dictionary:
		return eq.get(key, default_val)
	if eq is Object and key in eq:
		var v = eq.get(key)
		return default_val if v == null else v
	return default_val


static func _equip_slot_pri(slot: String) -> int:
	match str(slot).strip_edges().to_lower():
		"weapon", "pet_weapon":
			return 0
		"helmet", "pet_helmet":
			return 1
		"armor", "pet_armor":
			return 2
		"boots", "pet_boots":
			return 3
		"accessory", "pet_accessory":
			return 4
		_:
			return 90


static func _pet_rarity_pri(rarity: String) -> int:
	match str(rarity).strip_edges().to_lower():
		"gold", "传说", "legendary":
			return 0
		"silver", "史诗", "epic":
			return 1
		"bronze", "稀有", "rare":
			return 2
		"normal", "common", "普通":
			return 3
		_:
			return 50


static func _is_sealed_equipment(eq) -> bool:
	if eq == null:
		return false
	if eq is Dictionary:
		return bool(eq.get("is_sealed", false)) or str(eq.get("item_type", "")) == "sealed_suit"
	if "is_sealed" in eq and bool(eq.is_sealed):
		return true
	if "item_type" in eq and str(eq.item_type) == "sealed_suit":
		return true
	return false


static func _character_equip_sort_key(eq) -> Array:
	var sealed_pri: = 1 if _is_sealed_equipment(eq) else 0
	var slot: = str(_equip_field(eq, "slot", _equip_field(eq, "suit_slot", "")))
	var suit_id: = int(_equip_field(eq, "suit_id", 0))
	var rarity: = str(_equip_field(eq, "rarity", "common"))
	var nm: = str(_equip_field(eq, "name", ""))
	var enh: = int(_equip_field(eq, "enhance_level", _equip_field(eq, "enhancement_level", 0)))
	return [sealed_pri, _equip_slot_pri(slot), suit_id, rarity, nm, - enh]


static func _pet_equip_sort_key(eq) -> Array:
	var rarity: = str(_equip_field(eq, "rarity", "normal"))
	var slot: = str(_equip_field(eq, "slot", _equip_field(eq, "pet_slot", "")))
	var nm: = str(_equip_field(eq, "name", ""))
	var enh: = int(_equip_field(eq, "pet_enhance_level", _equip_field(eq, "enhance_level", 0)))
	return [_pet_rarity_pri(rarity), _equip_slot_pri(slot), nm, - enh]


static func sort_character_equipments(items: Array) -> Array:
	var out: Array = items.duplicate()
	out.sort_custom( func(a, b): return _character_equip_sort_key(a) < _character_equip_sort_key(b))
	return out


static func sort_pet_equipments(items: Array) -> Array:
	var out: Array = items.duplicate()
	out.sort_custom( func(a, b): return _pet_equip_sort_key(a) < _pet_equip_sort_key(b))
	return out



static func sort_warehouse_bag_items(items: Array) -> Array:
	var out: Array = items.duplicate()
	out.sort_custom( func(a, b):
		var an: = _item_name(a)
		var bn: = _item_name(b)
		var a_mat: = material_filter_category(a) != "other" or _catalog_type(an) in ["herb", "material"]
		var b_mat: = material_filter_category(b) != "other" or _catalog_type(bn) in ["herb", "material"]

		var a_bag: = 0 if a_mat else 1
		var b_bag: = 0 if b_mat else 1
		if a_bag != b_bag:
			return a_bag < b_bag
		if a_bag == 0:
			return _material_sort_key(a) < _material_sort_key(b)
		return _item_sort_key(a) < _item_sort_key(b)
	)
	return out
