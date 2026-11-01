extends Node
class_name XianMoShop

const SHOP_ITEMS = {
	"bronze_chest": {"cost": 150, "name": "青铜宝箱", "description": "随机获得一件青铜套装部件"}, 
	"silver_chest": {"cost": 300, "name": "白银宝箱", "description": "随机获得一件白银套装部件"}, 
	"gold_chest": {"cost": 450, "name": "黄金宝箱", "description": "随机获得一件黄金套装部件"}, 
	"fortify_lv1_book": {"cost": 5000, "name": "硬皮lv1技能书", "description": "宠物技能书，可学习硬皮lv1技能，提升宠物基础防御70%"}
}

var game_manager = null
var xianmo_system = null

signal exchange_success(item_id: String, rewards: Dictionary)
signal exchange_failed(reason: String)

func set_managers(gm, xm):
	game_manager = gm
	xianmo_system = xm

func get_shop_items() -> Array:
	var result = []
	for item_id in SHOP_ITEMS.keys():
		var item = SHOP_ITEMS[item_id].duplicate()
		item["item_id"] = item_id
		result.append(item)
	return result

func can_exchange(item_id: String) -> bool:
	if not SHOP_ITEMS.has(item_id):
		return false

	if not xianmo_system or not xianmo_system.xianmo_data:
		return false

	var cost = SHOP_ITEMS[item_id].cost
	return xianmo_system.xianmo_data.total_score >= cost

func exchange(item_id: String) -> Dictionary:
	var result = {"success": false, "message": "", "rewards": {}}

	if not SHOP_ITEMS.has(item_id):
		result.message = "无效的商品ID"
		exchange_failed.emit(result.message)
		return result

	if not game_manager or not game_manager.network or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，请联网后通过服务端兑换"
		exchange_failed.emit(result.message)
		return result
	result.message = "请使用服务端兑换接口"
	exchange_failed.emit(result.message)
	return result

func exchange_treasure_map() -> Dictionary:
	var result = {"success": false, "message": "", "gold": 0, "broadcast": false}
	result.message = "请使用服务端藏宝图兑换接口"
	return result

func get_fragment_count() -> int:
	if not xianmo_system or not xianmo_system.xianmo_data:
		return 0
	return xianmo_system.xianmo_data.treasure_fragments

func can_exchange_treasure_map() -> bool:
	return get_fragment_count() >= 10

func _get_chest_type_from_item_id(item_id: String) -> String:
	match item_id:
		"bronze_chest": return "bronze"
		"silver_chest": return "silver"
		"gold_chest": return "gold"
		_: return "bronze"
