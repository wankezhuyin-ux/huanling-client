extends RefCounted
class_name DiscardProtection

const BLOCKED_MESSAGE: = "贵重物品不可丢弃"

const EXACT_NAMES: = {
	"法宝洗练石": true, 
	"法宝重置石": true, 
	"人物升级丹": true, 
	"宠物升级丹": true, 
	"宠物双倍经验丹": true, 
	"悟道仙丹": true, 
	"宠物补章器": true, 
	"极限装备礼包": true, 
	"开荒礼包": true, 
	"开荒宠装礼包": true, 
	"离线宠物礼包": true, 
	"天关礼包": true, 
	"兄弟天关礼包": true, 
}

const LIMIT_MATERIAL_NAMES: = {
	"极限武器": true, 
	"极限衣服": true, 
	"极限鞋子": true, 
	"极限血佩": true, 
	"极限内带": true, 
	"极限血配": true, 
}


static func blocked_message() -> String:
	return BLOCKED_MESSAGE


static func _item_name_of(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("name", "")).strip_edges()
	if "name" in item:
		return str(item.name).strip_edges()
	return ""


static func _item_type_of(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("item_type", item.get("itemType", item.get("type", "")))).strip_edges().to_lower()
	if "item_type" in item:
		return str(item.item_type).strip_edges().to_lower()
	return ""


static func _custom_data_of(item) -> Dictionary:
	if item == null:
		return {}
	if item is Dictionary:
		var cd: Variant = item.get("custom_data", item.get("customData", item.get("data", {})))
		return cd as Dictionary if cd is Dictionary else {}
	if "custom_data" in item and item.custom_data is Dictionary:
		return item.custom_data
	return {}


static func _is_floor_gift_name(name: String) -> bool:
	if name.length() < 4:
		return false
	if not name.ends_with("关礼包"):
		return false
	var prefix: = name.substr(0, name.length() - 3)
	return prefix.is_valid_int()


static func _is_pet_related_gift_or_egg(name: String, type: String) -> bool:
	if name.is_empty():
		return false
	if name.contains("宠物礼包") or name == "离线宠物礼包":
		return true
	if name.contains("可进化宠礼包") or name.contains("不可进化宠礼包"):
		return true
	if name == "天关礼包" or name == "兄弟天关礼包" or _is_floor_gift_name(name):
		return true
	if type == "pet_egg" or name.ends_with("宠物蛋"):
		return true
	return false


static func _is_skill_book(name: String, type: String) -> bool:
	if type == "pet_skill_book" or type == "martial_skill_book":
		return true
	return name.ends_with("技能书")


static func _is_limit_material(name: String, type: String, custom_data: Dictionary) -> bool:
	if type == "limit_equip":
		return true
	if bool(custom_data.get("is_limit_equip", false)):
		return true
	var n: = "极限血佩" if name == "极限血配" else name
	return LIMIT_MATERIAL_NAMES.has(n)


static func cannot_discard_inventory_item(item) -> bool:
	var name: = _item_name_of(item)
	var type: = _item_type_of(item)
	var cd: = _custom_data_of(item)
	if name.is_empty():
		return false
	if EXACT_NAMES.has(name):
		return true
	if name.begins_with("双倍经验丹"):
		return true
	if _is_skill_book(name, type):
		return true
	if _is_limit_material(name, type, cd):
		return true
	if _is_pet_related_gift_or_egg(name, type):
		return true
	return false


static func cannot_discard_equipment(eq) -> bool:
	if eq == null:
		return false
	if eq is Dictionary:
		if bool((eq as Dictionary).get("is_limit", false)):
			return true
		return _is_limit_material(_item_name_of(eq), _item_type_of(eq), _custom_data_of(eq))
	if "is_limit" in eq and bool(eq.is_limit):
		return true
	return _is_limit_material(_item_name_of(eq), _item_type_of(eq), _custom_data_of(eq))


static func cannot_discard_fabao() -> bool:
	return true


static func needs_release_countdown(pet) -> bool:
	if pet == null:
		return false
	return float(pet.total_growth) >= 8.0


static func is_batch_release_pet_allowed(pet) -> bool:
	if pet == null:
		return false
	if int(pet.level) != 1:
		return false
	return float(pet.total_growth) < 6.0
