extends Node
class_name InventoryManager

const GameData = preload("res://scripts/game_data.gd")
const PetClass = preload("res://scripts/pet.gd")
const EvolutionData = preload("res://scripts/evolution_data.gd")
const ForgeData = preload("res://scripts/forge/forge_data.gd")
const PetEquipmentEnhance = preload("res://scripts/pet_equipment/pet_equipment_enhance.gd")
const FestivalGiftManager = preload("res://scripts/festival_gift_manager.gd")
const WorldBossConfig = preload("res://scripts/world_boss/world_boss_config.gd")
const NORMAL_SEAL_STONE_ITEM: = "普通解封石"
const ADVANCED_SEAL_STONE_ITEM: = "高级解封石"
const NORMAL_PER_ADVANCED_SEAL_STONE: = 10
const ITEM_NAME_ALIASES: = {
	"修行丹": "悟道仙丹", 
	"普通解封石": NORMAL_SEAL_STONE_ITEM, 
	"溅墨lv1": "溅墨lv1技能书", 
	"溅墨 lv1": "溅墨lv1技能书", 
	"溅墨1": "溅墨lv1技能书", 
	"溅墨lv2": "溅墨lv2技能书", 
	"溅墨 lv2": "溅墨lv2技能书", 
	"溅墨2": "溅墨lv2技能书", 
	"溅墨lv3": "溅墨lv3技能书", 
	"溅墨 lv3": "溅墨lv3技能书", 
	"溅墨3": "溅墨lv3技能书", 
	"饮血lv1": "饮血lv1技能书", 
	"饮血 lv1": "饮血lv1技能书", 
	"饮血1": "饮血lv1技能书", 
	"饮血lv2": "饮血lv2技能书", 
	"饮血 lv2": "饮血lv2技能书", 
	"饮血2": "饮血lv2技能书", 
	"饮血lv3": "饮血lv3技能书", 
	"饮血 lv3": "饮血lv3技能书", 
	"饮血3": "饮血lv3技能书", 
	"连击lv1": "连击lv1技能书", 
	"连击 lv1": "连击lv1技能书", 
	"连击1": "连击lv1技能书", 
	"连击lv2": "连击lv2技能书", 
	"连击 lv2": "连击lv2技能书", 
	"连击2": "连击lv2技能书", 
	"连击lv3": "连击lv3技能书", 
	"连击 lv3": "连击lv3技能书", 
	"连击3": "连击lv3技能书", 
	"护主lv1": "护主lv1技能书", 
	"护主 lv1": "护主lv1技能书", 
	"护主1": "护主lv1技能书", 
	"护主lv2": "护主lv2技能书", 
	"护主 lv2": "护主lv2技能书", 
	"护主2": "护主lv2技能书", 
	"护主lv3": "护主lv3技能书", 
	"护主 lv3": "护主lv3技能书", 
	"护主3": "护主lv3技能书", 
	"反打lv1": "反打lv1技能书", 
	"反打 lv1": "反打lv1技能书", 
	"反打1": "反打lv1技能书", 
	"反打lv2": "反打lv2技能书", 
	"反打 lv2": "反打lv2技能书", 
	"反打2": "反打lv2技能书", 
	"反打lv3": "反打lv3技能书", 
	"反打 lv3": "反打lv3技能书", 
	"反打3": "反打lv3技能书", 
}

const MAX_ITEM_BAG_SIZE = 100
const MAX_MATERIAL_BAG_SIZE = 100
const MAX_INVENTORY_SIZE = 100
const MAX_WAREHOUSE_SIZE = 200
const MAX_STACK_SIZE = 999
const REWARD_SYNC_NONE: = 0
const REWARD_SYNC_LOCAL_SAVE: = 1
const REWARD_SYNC_AUTHORITY_COMPACT_UPLOAD: = 2
const REWARD_SYNC_FULL_AUTHORITY_UPLOAD: = 3
const ROLLBACK_SCOPE_NONE: = "none"
const ROLLBACK_SCOPE_INVENTORY_ITEM_ONLY: = "inventory_item_only"
const ROLLBACK_SCOPE_PLAYER_GOLD_ONLY: = "player_gold_only"
const ROLLBACK_SCOPE_PETS_GRANTED_ONLY: = "pets_granted_only"

static func mark_server_authority_use_result(result: Dictionary) -> Dictionary:
	result["rollback_scope"] = ROLLBACK_SCOPE_NONE
	result["rollback_on_sync_failure"] = false
	result.erase("rollback_pet_snapshot")
	result.erase("rollback_inventory_snapshot")
	result.erase("rollback_equipment_snapshot")
	result.erase("rollback_pet_collection_snapshot")
	result.erase("rollback_player_gold")
	result.erase("rollback_granted_pet_ids")
	return result

static func mark_local_item_sync_result(result: Dictionary) -> Dictionary:
	result["rollback_scope"] = ROLLBACK_SCOPE_INVENTORY_ITEM_ONLY
	result["rollback_on_sync_failure"] = true
	return result

static func build_server_auth_pet_reward_apply_opts(gm, reward_result: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var base: = {
		"pets_authoritative": true, 
		"skip_pet_collection_trim": true, 
		"skip_deferred_cloud_save": true, 
	}
	for k in extra:
		base[k] = extra[k]
	var granted_items: Variant = reward_result.get("grantedItems", [])
	if granted_items is Array:
		for granted_item in granted_items:
			if granted_item is Dictionary and str(granted_item.get("slot", "")).strip_edges() != "":
				base["authoritative_equipment_inventory"] = true
				break
	return gm.build_authority_reward_apply_opts(reward_result, base)

static func apply_server_auth_pet_reward_save(gm, save_data: Dictionary, reward_result: Dictionary = {}, extra_opts: Dictionary = {}) -> void :
	if gm == null or save_data == null or not save_data is Dictionary:
		return
	gm.apply_cloud_save(save_data, build_server_auth_pet_reward_apply_opts(gm, reward_result, extra_opts))
	gm.apply_granted_pets_from_reward_result(reward_result)

static func extract_economy_authority_save_data(payload: Dictionary) -> Dictionary:
	if payload == null or not payload is Dictionary:
		return {}
	var sd: Variant = payload.get("saveData", payload.get("save_data", null))
	if sd is Dictionary:
		return (sd as Dictionary).duplicate(true)
	if sd is String:
		var stripped: = str(sd).strip_edges()
		if not stripped.is_empty():
			var parsed: Variant = JSON.parse_string(stripped)
			if parsed is Dictionary:
				return (parsed as Dictionary).duplicate(true)
	if payload.get("inventoryData") is Dictionary:
		var out: Dictionary = {
			"inventoryData": (payload.get("inventoryData") as Dictionary).duplicate(true), 
		}
		var pd: Variant = payload.get("playerData", null)
		out["playerData"] = pd if pd is Dictionary else {}
		var pets: Variant = payload.get("petsData", null)
		if pets is Dictionary:
			out["petsData"] = pets
		return out
	return {}

func _await_cloud_save_download(game_manager: GameManager) -> Dictionary:
	if game_manager == null or game_manager.network == null:
		return {}
	var tree = game_manager.get_tree()
	if tree == null:
		return {}
	var state: = {"done": false, "data": {}}
	var on_dl = func(save_data):
		state.done = true
		if save_data is Dictionary:
			state.data = save_data
	game_manager.network.save_downloaded.connect(on_dl, CONNECT_ONE_SHOT)
	game_manager.network.download_save()
	var frames: = 0
	while not bool(state.done) and frames < 600:
		await tree.process_frame
		frames += 1
	var downloaded: Dictionary = state.data if state.data is Dictionary else {}
	if downloaded.is_empty() or bool(downloaded.get("_download_error", false)):
		return {}
	if game_manager.network.has_method("merge_pending_into_downloaded_save"):
		game_manager.network.merge_pending_into_downloaded_save(downloaded)
	return downloaded

const SINGLE_ATTR_SLOT_CONFIG = [
	{"slot": "weapon", "attr": "attack", "name_suffix": "武器"}, 
	{"slot": "armor", "attr": "defense", "name_suffix": "衣服"}, 
	{"slot": "helmet", "attr": "agility", "name_suffix": "帽子"}, 
	{"slot": "boots", "attr": "hp", "name_suffix": "鞋子"}, 
	{"slot": "accessory", "attr": "mp", "name_suffix": "饰品"}
]

const GOLD_BAG_CONFIG: = {
	# 2026-10 起所有旧版钱袋合并成「钱币袋」一种（10 万金币/个）。
	# 旧名识别放在 InventoryBagSort.LEGACY_GOLD_BAG_HASHES（按名称指纹）。
	"钱币袋": {
		"amount": 100000, 
		"server_key": "coin_bag", 
	}, 
}
const HIGH_RISK_LOCAL_ONLY_PET_GIFTS: = ["6+可进化宠礼包", "7+可进化宠礼包", "8+可进化宠礼包", "9+可进化宠礼包", "10+可进化宠礼包", "11+可进化宠礼包", "12+可进化宠礼包", "13+可进化宠礼包", "6+可进化宠礼包(可能变异)", "7+可进化宠礼包(可能变异)", "8+可进化宠礼包(可能变异)", "9+可进化宠礼包(可能变异)", "10+可进化宠礼包(可能变异)", "11+可进化宠礼包(可能变异)", "12+可进化宠礼包(可能变异)", "13+可进化宠礼包(可能变异)", "6+不可进化宠礼包", "6+不可进化宠礼包(可能变异)", "7+不可进化宠礼包(可能变异)", "8+不可进化宠礼包(可能变异)", "9+不可进化宠礼包(可能变异)", "10+不可进化宠礼包(可能变异)", "11+不可进化宠礼包(可能变异)", "12+不可进化宠礼包(可能变异)", "13+不可进化宠礼包(可能变异)", "10-13变异可进化宠礼包", "7-9水晶儿礼包", "7-9梦晶儿礼包", "7-9阿弟达斯礼包", "仙魔灵兽礼包", "仙魔神兽礼包", "仙魔变异礼包", "仙魔野生礼包", "天关礼包", "塔1礼包", "塔2礼包", "塔3礼包", "塔4礼包", "塔5礼包", "生死塔参与礼包"]
const HIGH_RISK_LOCAL_ONLY_PET_EGGS: = ["5+宠物蛋", "火属性宠物蛋", "水属性宠物蛋", "木属性宠物蛋", "金属性宠物蛋", "土属性宠物蛋", "金变异宠物蛋", "木变异宠物蛋", "水变异宠物蛋", "火变异宠物蛋", "土变异宠物蛋"]
const SERVER_AUTH_PET_EGG_NAMES: = ["5+宠物蛋", "火属性宠物蛋", "水属性宠物蛋", "木属性宠物蛋", "金属性宠物蛋", "土属性宠物蛋", "金变异宠物蛋", "木变异宠物蛋", "水变异宠物蛋", "火变异宠物蛋", "土变异宠物蛋"]
const SERVER_AUTH_PET_GIFT_NAMES: = ["5+宠物礼包", "6+可进化宠礼包", "7+可进化宠礼包", "6+不可进化宠礼包", "7+不可进化宠礼包", "8+不可进化宠礼包", "8+可进化宠礼包", "9+可进化宠礼包", "9+不可进化宠礼包", "10+不可进化宠礼包", "11+不可进化宠礼包", "10+可进化宠礼包", "11+可进化宠礼包", "12+不可进化宠礼包", "12+可进化宠礼包", "13+不可进化宠礼包", "13+可进化宠礼包", "6+可进化宠礼包(可能变异)", "7+可进化宠礼包(可能变异)", "8+可进化宠礼包(可能变异)", "9+可进化宠礼包(可能变异)", "10+可进化宠礼包(可能变异)", "11+可进化宠礼包(可能变异)", "12+可进化宠礼包(可能变异)", "13+可进化宠礼包(可能变异)", "6+不可进化宠礼包(可能变异)", "7+不可进化宠礼包(可能变异)", "8+不可进化宠礼包(可能变异)", "9+不可进化宠礼包(可能变异)", "10+不可进化宠礼包(可能变异)", "11+不可进化宠礼包(可能变异)", "12+不可进化宠礼包(可能变异)", "13+不可进化宠礼包(可能变异)", "10-13变异不可进化宠礼包", "10-13变异可进化宠礼包", "7-9水晶儿礼包", "7-9梦晶儿礼包", "7-9阿弟达斯礼包", "仙魔灵兽礼包", "仙魔神兽礼包", "仙魔变异礼包", "仙魔野生礼包", "天关礼包", "兄弟天关礼包", "塔1礼包", "塔2礼包", "塔3礼包", "塔4礼包", "塔5礼包", "生死塔参与礼包", "世界boss礼包", "冠军礼包", "亚军礼包", "季军礼包", "十强礼包", "100关礼包", "200关礼包", "300关礼包", "400关礼包", "500关礼包", "600关礼包", "700关礼包", "800关礼包", "900关礼包", "1000关礼包", "1100关礼包", "1200关礼包", "1300关礼包", "1400关礼包", "1500关礼包", "1600关礼包", "1700关礼包", "1800关礼包", "1900关礼包", "2000关礼包"]
const PET_BATCH_USE_MAX: = 20
const PET_MEDAL_BATCH_MAX: = 15

static var _runtime_auth_pet_gift_names: Dictionary = {}
static var _runtime_auth_pet_egg_names: Dictionary = {}

static func clear_runtime_pet_open_auth_names() -> void :
	_runtime_auth_pet_gift_names.clear()
	_runtime_auth_pet_egg_names.clear()

static func apply_runtime_pet_open_auth_names(items: Array) -> int:
	clear_runtime_pet_open_auth_names()
	var applied: = 0
	for row_v in items:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v
		var n: = str(row.get("itemName", row.get("name", ""))).strip_edges()
		if n.is_empty():
			continue
		var route: = str(row.get("route", "open-pet")).strip_edges()
		if route == "open-egg":
			_runtime_auth_pet_egg_names[n] = true
		else:
			_runtime_auth_pet_gift_names[n] = true
		applied += 1
	return applied

static func is_server_auth_pet_gift_name(item_name: String) -> bool:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return false
	if SERVER_AUTH_PET_GIFT_NAMES.has(n):
		return true
	return _runtime_auth_pet_gift_names.has(n)

static func is_server_auth_pet_egg_name(item_name: String) -> bool:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return false
	if SERVER_AUTH_PET_EGG_NAMES.has(n):
		return true
	return _runtime_auth_pet_egg_names.has(n)

static func get_active_pet_medal_room() -> int:
	var gm: = GameManager.instance
	if gm == null or gm.pet_manager == null:
		return PET_MEDAL_BATCH_MAX
	var ap = gm.pet_manager.get_active_pet()
	if ap == null:
		return PET_MEDAL_BATCH_MAX
	return maxi(0, PET_MEDAL_BATCH_MAX - PetManager.sum_medal_counts_for_pet(ap))

static func clamp_medal_batch_use_count(requested: int, owned: int) -> int:
	if owned <= 0:
		return 0
	var room: = get_active_pet_medal_room()
	if room <= 0:
		return 0
	var max_allowed: = mini(mini(owned, PET_MEDAL_BATCH_MAX), room)
	return clampi(requested, 1, max_allowed)

static func item_uses_pet_batch_cap(item_name: String) -> bool:
	var n: = str(item_name).strip_edges()
	if InventoryManager.is_server_auth_pet_egg_name(n):
		return true
	if InventoryManager.is_server_auth_pet_gift_name(n):
		return true
	if n == "离线宠物礼包" or FestivalGiftManager.is_festival_gift(n):
		return true
	return false

static func clamp_pet_batch_use_count(requested: int, owned: int) -> int:
	var max_allowed: = mini(maxi(owned, 0), PET_BATCH_USE_MAX)
	return clampi(requested, 1, maxi(1, max_allowed))

const BROTHER_TOWER_GIFT_NAME: = "兄弟天关礼包"

static func is_tower_family_gift_name(gift_name: String) -> bool:
	var name_s: = str(gift_name).strip_edges()
	return name_s == "天关礼包" or (name_s.ends_with("关礼包") and name_s != BROTHER_TOWER_GIFT_NAME)

static func _build_brother_tower_reward_display_fallback(reward_result: Dictionary) -> String:
	var parts: Array[String] = []
	var gold: = int(reward_result.get("grantedGold", 0))
	if gold > 0:
		if gold >= 100000000 and gold % 100000000 == 0:
			parts.append("%d亿金币" % (gold / 100000000))
		elif gold >= 10000 and gold % 10000 == 0:
			parts.append("%d万金币" % (gold / 10000))
		else:
			parts.append("%d金币" % gold)
	var granted_items: Array = reward_result.get("grantedItems", []) if reward_result.get("grantedItems") is Array else []
	var counter: = {}
	for entry in granted_items:
		if not (entry is Dictionary):
			continue
		var item_label: = str(entry.get("name", "")).strip_edges()
		var item_count: = maxi(1, int(entry.get("count", 1)))
		if item_label.is_empty():
			continue
		counter[item_label] = int(counter.get(item_label, 0)) + item_count
	for item_label in counter.keys():
		var item_count: = int(counter[item_label])
		if item_count > 1:
			parts.append("%sx%d" % [item_label, item_count])
		else:
			parts.append(item_label)
	return "、".join(parts) if not parts.is_empty() else "神秘奖励"

static func broadcast_brother_tower_gift_open(reward_display: String, batch_count: int = 0) -> void :
	var gm: = GameManager.instance
	if gm == null or gm.player == null:
		return
	var player_name: = str(gm.player.player_name).strip_edges()
	if player_name.is_empty():
		return
	var cleaned: = str(reward_display).strip_edges()
	if cleaned.is_empty():
		cleaned = "神秘奖励"
	var msg: String
	if batch_count > 1:
		msg = "🎁 恭喜玩家【%s】批量开启%d个【天关组队锦囊】，获得【%s】！" % [player_name, batch_count, cleaned]
	else:
		msg = "🎁 恭喜玩家【%s】开启【天关组队锦囊】，获得【%s】！" % [player_name, cleaned]
	gm.broadcast_event("brother_tower_gift_open", player_name, {
		"gift_name": BROTHER_TOWER_GIFT_NAME, 
		"reward": cleaned, 
	}, msg)

static func broadcast_world_boss_gift_open(reward_display: String, batch_count: int = 0) -> void :
	var gm: = GameManager.instance
	if gm == null or gm.player == null:
		return
	var player_name: = str(gm.player.player_name).strip_edges()
	if player_name.is_empty():
		return
	var cleaned: = str(reward_display).strip_edges()
	if cleaned.is_empty():
		cleaned = "神秘奖励"
	var gift_name: = WorldBossConfig.GIFT_ITEM_NAME
	var msg: String
	if batch_count > 1:
		msg = "🎁 恭喜玩家【%s】批量开启%d个【%s】，获得【%s】！" % [player_name, batch_count, gift_name, cleaned]
	else:
		msg = "🎁 恭喜玩家【%s】开启【%s】，获得【%s】！" % [player_name, gift_name, cleaned]
	gm.broadcast_event("world_boss_gift_open", player_name, {
		"gift_name": gift_name, 
		"reward": cleaned, 
	}, msg)

static func build_opened_pets_from_granted(reward_result: Dictionary) -> Array:
	var opened_pets: Array = []
	var granted_pets: Array = reward_result.get("grantedPets", []) if reward_result.get("grantedPets") is Array else []
	for pet_info in granted_pets:
		if pet_info is Dictionary:
			opened_pets.append(InventoryManager._opened_pet_entry_from_dict(pet_info))
	return opened_pets


static func get_pet_mutation_count_from_info(pet_info: Dictionary) -> int:
	return clampi(int(pet_info.get("mutation_count", pet_info.get("mutationCount", 0))), 0, 2)


static func format_pet_name_with_mutation(pet_name: String, mutation_count: int = 0) -> String:
	var n: = str(pet_name).strip_edges()
	var mc: = clampi(mutation_count, 0, 2)
	if mc > 0:
		return "%s[变异%d]" % [n, mc]
	return n

static func format_pet_name_with_mutation_from_info(pet_info: Dictionary) -> String:
	return InventoryManager.format_pet_name_with_mutation(
		str(pet_info.get("name", pet_info.get("petName", "神秘宠物"))), 
		InventoryManager.get_pet_mutation_count_from_info(pet_info)
	)

static func _opened_pet_entry_from_dict(pet_info: Dictionary) -> Dictionary:
	var entry: = {
		"name": str(pet_info.get("name", pet_info.get("petName", "神秘宠物"))), 
		"growth": float(pet_info.get("growth", pet_info.get("totalGrowth", 0.0))), 
		"mailed": bool(pet_info.get("mailed", false)), 
	}
	var mc: = InventoryManager.get_pet_mutation_count_from_info(pet_info)
	if mc > 0:
		entry["mutation_count"] = mc
	return entry

static func _opened_pet_entry_from_instance(pet_inst) -> Dictionary:
	var entry: = {
		"name": str(pet_inst.pet_name), 
		"growth": float(pet_inst.total_growth), 
		"mailed": false, 
	}
	var mc: = 0
	if "mutation_count" in pet_inst:
		mc = clampi(int(pet_inst.mutation_count), 0, 2)
	if mc > 0:
		entry["mutation_count"] = mc
	return entry

static func capture_pet_roster_snapshot(gm) -> Dictionary:
	var pets_before: Dictionary = {}
	if gm == null or gm.pet_manager == null:
		return pets_before
	for pet_inst in gm.pet_manager.pets:
		if pet_inst:
			pets_before[str(pet_inst.id)] = true
	for pet_inst in gm.pet_manager.pet_bag:
		if pet_inst:
			pets_before[str(pet_inst.id)] = true
	return pets_before

static func build_opened_pets_for_broadcast(gm, reward_result: Dictionary, pets_before: Dictionary = {}) -> Array:
	var opened_pets: = InventoryManager.build_opened_pets_from_granted(reward_result)
	if not opened_pets.is_empty() or gm == null or gm.pet_manager == null:
		return opened_pets
	for pet_inst in gm.pet_manager.pets:
		if pet_inst == null:
			continue
		var pet_id: = str(pet_inst.id)
		if pets_before.has(pet_id):
			continue
		opened_pets.append(InventoryManager._opened_pet_entry_from_instance(pet_inst))
	for pet_inst in gm.pet_manager.pet_bag:
		if pet_inst == null:
			continue
		var pet_id_bag: = str(pet_inst.id)
		if pets_before.has(pet_id_bag):
			continue
		opened_pets.append(InventoryManager._opened_pet_entry_from_instance(pet_inst))
	return opened_pets

static func emit_server_auth_pet_reward_broadcast(
	kind: String, 
	reward_name: String, 
	response_data: Dictionary, 
	opened_pets: Array, 
	batch_count: int = 0, 
) -> void :
	var gm = GameManager.instance
	if gm == null or gm.player == null:
		return
	var player_name: = str(gm.player.player_name).strip_edges()
	if player_name.is_empty():
		return
	var reward_result: Dictionary = response_data.get("result", {}) if response_data.get("result") is Dictionary else {}
	if kind == "egg":
		if opened_pets.is_empty():
			return
		var first_pet: Dictionary = opened_pets[0] if opened_pets[0] is Dictionary else {}
		var pet_name: = InventoryManager.format_pet_name_with_mutation_from_info(first_pet)
		var growth: = float(first_pet.get("growth", 0.0))
		var min_growth_for_broadcast: = 6.0
		if reward_name == "5+宠物蛋":
			min_growth_for_broadcast = 5.0
		elif reward_name.ends_with("属性宠物蛋") or reward_name.ends_with("变异宠物蛋"):
			min_growth_for_broadcast = 6.0
		if pet_name.is_empty() or growth < min_growth_for_broadcast:
			return
		var egg_src: = reward_name
		if reward_name == "5+宠物蛋":
			egg_src = "5+宠物蛋"
		elif reward_name.ends_with("属性宠物蛋"):
			var elem_char: = str(reward_name.replace("属性宠物蛋", "")).strip_edges()
			egg_src = "五行属性宠物蛋·%s" % elem_char
		gm.broadcast_event("pet_egg_high_growth", player_name, {
			"pet_name": pet_name, 
			"growth": growth, 
			"egg_source": egg_src, 
			"mutation_count": InventoryManager.get_pet_mutation_count_from_info(first_pet), 
		})
		return
	if FestivalGiftManager.is_festival_gift(reward_name):
		var reward_display: = str(response_data.get("rewardDisplay", "神秘奖励")).strip_edges()
		var reward_code: = str(response_data.get("rewardCode", "")).strip_edges()
		if reward_display.is_empty():
			reward_display = "神秘奖励"
		var festival_batch: = batch_count if batch_count > 1 else 0
		FestivalGiftManager.broadcast_festival_gift_open(reward_name, reward_display, reward_code, festival_batch)
		return
	if reward_name == BROTHER_TOWER_GIFT_NAME:
		var reward_display_bt: = str(response_data.get("rewardDisplay", "")).strip_edges()
		if reward_display_bt.is_empty():
			reward_display_bt = InventoryManager._build_brother_tower_reward_display_fallback(reward_result)
		var opened_count: = int(reward_result.get("opened", batch_count if batch_count > 0 else 1))
		InventoryManager.broadcast_brother_tower_gift_open(reward_display_bt, opened_count if opened_count > 1 else 0)
		return
	if reward_name == WorldBossConfig.GIFT_ITEM_NAME:
		var reward_display_wb: = str(response_data.get("rewardDisplay", "")).strip_edges()
		if reward_display_wb.is_empty():
			reward_display_wb = InventoryManager._build_brother_tower_reward_display_fallback(reward_result)
		var opened_count_wb: = int(reward_result.get("opened", batch_count if batch_count > 0 else 1))
		InventoryManager.broadcast_world_boss_gift_open(reward_display_wb, opened_count_wb if opened_count_wb > 1 else 0)
		return
	if reward_name == "天关礼包":
		var granted_items: Array = reward_result.get("grantedItems", []) if reward_result.get("grantedItems") is Array else []
		for entry in granted_items:
			if not (entry is Dictionary):
				continue
			var item_key: = str(entry.get("name", ""))
			if item_key == "5+宠物蛋" or item_key == "5+宠物礼包":
				gm.broadcast_event("tower_gift_pet_egg", player_name, {})
				return
		return
	if reward_name == "5+宠物礼包":
		if not opened_pets.is_empty():
			var fp_5p: Dictionary = opened_pets[0] if opened_pets[0] is Dictionary else {}
			var pn_5p: = InventoryManager.format_pet_name_with_mutation_from_info(fp_5p)
			var gr_5p: = float(fp_5p.get("growth", 0.0))
			if not pn_5p.is_empty() and gr_5p >= 5.0:
				gm.broadcast_event("pet_egg_high_growth", player_name, {
					"pet_name": pn_5p, 
					"growth": gr_5p, 
					"egg_source": "5+宠物礼包", 
					"mutation_count": InventoryManager.get_pet_mutation_count_from_info(fp_5p), 
				})
		return
	if reward_name == "6+不可进化宠礼包" or reward_name == "7+不可进化宠礼包" or reward_name == "8+不可进化宠礼包" or reward_name == "9+不可进化宠礼包" or reward_name == "10+不可进化宠礼包" or reward_name == "11+不可进化宠礼包" or reward_name == "12+不可进化宠礼包" or reward_name == "13+不可进化宠礼包" or reward_name == "10-13变异不可进化宠礼包":
		if not opened_pets.is_empty():
			var fp_ne: Dictionary = opened_pets[0] if opened_pets[0] is Dictionary else {}
			var pn_ne: = InventoryManager.format_pet_name_with_mutation_from_info(fp_ne)
			var gr_ne: = float(fp_ne.get("growth", 0.0))
			if not pn_ne.is_empty() and gr_ne >= 6.0:
				gm.broadcast_event("pet_egg_high_growth", player_name, {
					"pet_name": pn_ne, 
					"growth": gr_ne, 
					"egg_source": reward_name, 
					"mutation_count": InventoryManager.get_pet_mutation_count_from_info(fp_ne), 
				})
		return
	const _floor_gift_suffix: = "关礼包"
	var floor_prefix: = reward_name.trim_suffix(_floor_gift_suffix) if reward_name.ends_with(_floor_gift_suffix) else ""
	if floor_prefix.is_valid_int() and int(floor_prefix) > 0:
		var floor: = int(floor_prefix)
		var granted_items2: Array = reward_result.get("grantedItems", []) if reward_result.get("grantedItems") is Array else []
		if not opened_pets.is_empty():
			if batch_count > 1:
				var cap: = mini(opened_pets.size(), 5)
				var name_parts: Array[String] = []
				for i in range(cap):
					if opened_pets[i] is Dictionary:
						var op: Dictionary = opened_pets[i]
						var pn_floor: = InventoryManager.format_pet_name_with_mutation_from_info(op)
						if pn_floor.is_empty():
							continue
						name_parts.append("【%s】（成长%.2f）" % [pn_floor, float(op.get("growth", 0.0))])
				if name_parts.is_empty():
					return
				var batch_names: = "、".join(name_parts)
				var total_pets: = opened_pets.size()
				var first_pet2: Dictionary = opened_pets[0] if opened_pets[0] is Dictionary else {}
				var growth2: = float(first_pet2.get("growth", 0.0))
				var custom_msg: String
				if total_pets > 1:
					custom_msg = "🎁 恭喜【%s】批量开启%d个【%s】，获得%s等%d只！" % [player_name, batch_count, reward_name, batch_names, total_pets]
				else:
					custom_msg = "🎁 恭喜【%s】批量开启%d个【%s】，获得%s！" % [player_name, batch_count, reward_name, batch_names]
				gm.broadcast_event("tower_gift_pet", player_name, {
					"floor": floor, 
					"pet_name": batch_names, 
					"growth": growth2, 
					"batch_total": total_pets, 
					"mutation_count": InventoryManager.get_pet_mutation_count_from_info(first_pet2), 
				}, custom_msg)
			else:
				var first_pet2: Dictionary = opened_pets[0] if opened_pets[0] is Dictionary else {}
				var pet_name2: = InventoryManager.format_pet_name_with_mutation_from_info(first_pet2)
				var growth2: = float(first_pet2.get("growth", 0.0))
				gm.broadcast_event("tower_gift_pet", player_name, {
					"floor": floor, 
					"pet_name": pet_name2, 
					"growth": growth2, 
					"mutation_count": InventoryManager.get_pet_mutation_count_from_info(first_pet2), 
				})
			return
		for entry2 in granted_items2:
			if not (entry2 is Dictionary):
				continue
			var item_name: = str(entry2.get("name", ""))
			if item_name == "5+宠物蛋":
				gm.broadcast_event("tower_gift_egg", player_name, {"floor": floor})
				return
			if item_name.ends_with("属性宠物蛋"):
				gm.broadcast_event("tower_gift_element_egg", player_name, {"floor": floor, "egg": item_name})
				return
		return
	if kind == "gift" and not opened_pets.is_empty():
		var min_growth_fb: = 6.0
		if reward_name == "5+宠物礼包":
			min_growth_fb = 5.0
		var qualified: Array = []
		for pet_info in opened_pets:
			if not (pet_info is Dictionary):
				continue
			var pn: = InventoryManager.format_pet_name_with_mutation_from_info(pet_info)
			var pg: = float(pet_info.get("growth", 0.0))
			if not pn.is_empty() and pg >= min_growth_fb:
				qualified.append({
					"name": pn, 
					"growth": pg, 
					"mutation_count": InventoryManager.get_pet_mutation_count_from_info(pet_info), 
				})
		if qualified.is_empty():
			return
		if qualified.size() > 1 or batch_count > 1:
			var cap: = mini(qualified.size(), 5)
			var name_parts: Array[String] = []
			for i in range(cap):
				if qualified[i] is Dictionary:
					name_parts.append("【%s】（成长%.2f）" % [str(qualified[i].get("name", "")), float(qualified[i].get("growth", 0.0))])
			var batch_names: = "、".join(name_parts)
			var details: = {
				"pet_name": batch_names, 
				"growth": float(qualified[0].get("growth", 0.0)), 
				"egg_source": reward_name, 
				"mutation_count": int(qualified[0].get("mutation_count", 0)), 
			}
			if qualified.size() > 1 or batch_count > 1:
				details["batch_names"] = batch_names
				details["batch_total"] = qualified.size()
			gm.broadcast_event("pet_egg_high_growth", player_name, details)
			return
		var fp_fb: Dictionary = qualified[0] if qualified[0] is Dictionary else {}
		var pn_fb: = str(fp_fb.get("name", "")).strip_edges()
		var gr_fb: = float(fp_fb.get("growth", 0.0))
		gm.broadcast_event("pet_egg_high_growth", player_name, {
			"pet_name": pn_fb, 
			"growth": gr_fb, 
			"egg_source": reward_name, 
			"mutation_count": int(fp_fb.get("mutation_count", 0)), 
		})

static func require_logged_in_for_item_use() -> Dictionary:
	var result: = {"ok": true, "message": ""}
	var gm: = GameManager.instance
	if gm == null or gm.network == null or not gm.network.is_logged_in():
		result.ok = false
		result.message = "使用道具需登录并联网，请先登录后再试"
	return result

static func sanitize_pet_batch_extra_payload(extra_payload: Dictionary) -> Dictionary:
	var out: Dictionary = extra_payload.duplicate(true)
	if out.has("batchCount") or out.has("batch_count"):
		var raw: = int(out.get("batchCount", out.get("batch_count", 1)))
		out["batchCount"] = clampi(raw, 1, PET_BATCH_USE_MAX)
		out.erase("batch_count")
	return out



var items: Array = []

var warehouse_items: Array = []


var pet_equipment_items: Array = []
var pet_equipment_warehouse: Array = []
const MAX_PET_EQUIPMENT_INVENTORY = 56
const MAX_PET_EQUIPMENT_WAREHOUSE = 100

signal inventory_changed
signal warehouse_changed
signal pet_equipment_inventory_changed
signal pet_equipment_warehouse_changed
signal item_used(item, message: String)
var _limit_material_migrated: bool = false
var _skip_next_item_used_save: bool = false

func consume_skip_item_used_save_flag() -> bool:
	var skip: = _skip_next_item_used_save
	_skip_next_item_used_save = false
	return skip

func _mark_skip_next_item_used_save() -> void :
	_skip_next_item_used_save = true

func _safe_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}

func _ensure_item_custom_data(item) -> Dictionary:
	if item == null:
		return {}
	if not (item.custom_data is Dictionary):
		item.custom_data = {}
	return item.custom_data

func _normalize_item_type(raw_type: String) -> String:
	var item_type = raw_type.strip_edges().to_lower()
	if item_type.is_empty() or item_type == "limit_equip" or item_type == "herb":
		return "material"
	return item_type

func resolve_bag_category(item_name: String, item_type: String, custom_data: Dictionary = {}) -> String:
	var cd: Dictionary = _safe_dict(custom_data)
	if cd.get("is_limit_equip", false):
		return "material"
	var normalized = _normalize_item_type(item_type)
	if normalized == "sealed_suit":
		return "equipment"
	if normalized == "material":
		return "material"
	if normalized.is_empty() and not item_name.is_empty():
		var cfg = GameData.ALL_ITEMS.get(item_name, {})
		if cfg is Dictionary:
			return resolve_bag_category(item_name, str(cfg.get("type", "material")), cd)
	return "item"

func _is_non_stackable_item_instance(item_name: String, item_type: String) -> bool:
	var t: = _normalize_item_type(item_type)
	return t == "sealed_suit" or t == "treasure_chest" or item_name == "藏宝箱"


func _is_limit_forge_material_inventory_row(item) -> bool:
	if item == null:
		return false
	var cd: = _ensure_item_custom_data(item)
	if bool(cd.get("is_limit_equip", false)):
		return true
	var nm: = ForgeData.normalize_limit_material_name(str(item.name))
	return ForgeData.is_limit_forge_material_name(nm)

func _build_limit_material_aggregate_entries(source_items: Array, source_key: String) -> Array:
	var ordered_names: Array = []
	var grouped: = {}
	for entry in source_items:
		var item = entry
		if item == null:
			continue
		if not _is_limit_forge_material_inventory_row(item):
			continue
		var canonical_name: = ForgeData.normalize_limit_material_name(str(item.name))
		if canonical_name.is_empty():
			canonical_name = str(item.name)
		if not grouped.has(canonical_name):
			grouped[canonical_name] = {
				"entry_kind": "limit_material_aggregate", 
				"name": canonical_name, 
				"item_type": "material", 
				"count": 0, 
				"source_key": source_key, 
				"source_items": [], 
				"representative_item": item, 
			}
			ordered_names.append(canonical_name)
		var row: Dictionary = grouped[canonical_name]
		row["count"] = int(row.get("count", 0)) + max(1, int(item.count))
		var bucket: Array = row.get("source_items", [])
		bucket.append(item)
		row["source_items"] = bucket
		grouped[canonical_name] = row
	var out: Array = []
	for canonical_name in ordered_names:
		out.append(grouped.get(canonical_name, {}))
	return out

func get_limit_material_bag_aggregates() -> Array:
	return _build_limit_material_aggregate_entries(items, "bag")

func get_limit_material_warehouse_aggregates() -> Array:
	return _build_limit_material_aggregate_entries(warehouse_items, "warehouse")

func get_limit_material_aggregate_items(aggregate_entry: Dictionary) -> Array:
	if not (aggregate_entry is Dictionary):
		return []
	var raw_items: Array = aggregate_entry.get("source_items", []) as Array
	var out: Array = []
	for entry in raw_items:
		var item = entry
		if item == null:
			continue
		out.append(item)
	return out

func get_limit_material_aggregate_pick_items(aggregate_entry: Dictionary, amount: int) -> Array:
	var wanted: int = max(0, amount)
	if wanted <= 0:
		return []
	var source_items: Array = get_limit_material_aggregate_items(aggregate_entry)
	var picked: Array = []
	var remaining: int = wanted
	for entry in source_items:
		var item = entry
		if item == null:
			continue
		var stack_count: int = max(1, int(item.count))
		for _i in range(stack_count):
			if remaining <= 0:
				break
			picked.append(item)
			remaining -= 1
		if remaining <= 0:
			break
	return picked

func get_material_bag_display_entries() -> Array:
	var out: Array = []
	for item in items:
		if item == null:
			continue
		if resolve_bag_category(item.name, item.item_type, item.custom_data) != "material":
			continue
		if _is_limit_forge_material_inventory_row(item):
			continue
		out.append(item)

	for aggregate in get_limit_material_bag_aggregates():
		out.append(aggregate)
	return out

func get_material_warehouse_display_entries() -> Array:
	var out: Array = []
	for item in warehouse_items:
		if item == null:
			continue
		if resolve_bag_category(item.name, item.item_type, item.custom_data) != "material":
			continue
		if _is_limit_forge_material_inventory_row(item):
			continue
		out.append(item)
	for aggregate in get_limit_material_warehouse_aggregates():
		out.append(aggregate)
	return out

func get_max_slots_by_category(category: String) -> int:
	return MAX_MATERIAL_BAG_SIZE if category == "material" else MAX_ITEM_BAG_SIZE

func get_used_slots_by_category(category: String) -> int:
	var used: = 0
	var limit_names_counted: Dictionary = {}
	for item in items:
		if item == null:
			continue
		var bag_category: = resolve_bag_category(item.name, item.item_type, item.custom_data)
		if bag_category != category:
			continue
		if _is_limit_forge_material_inventory_row(item):
			var canonical_name: = ForgeData.normalize_limit_material_name(str(item.name))
			if canonical_name.is_empty():
				canonical_name = str(item.name)
			if limit_names_counted.has(canonical_name):
				continue
			limit_names_counted[canonical_name] = true
			used += 1
		else:
			used += 1
	return used

func get_available_space_by_category(category: String) -> int:
	return max(0, get_max_slots_by_category(category) - get_used_slots_by_category(category))

func get_available_space_for_item(item_name: String, item_type: String, custom_data: Dictionary = {}) -> int:
	var category = resolve_bag_category(item_name, item_type, custom_data)
	return get_available_space_by_category(category)

func count_sealed_suit_item_rows() -> int:
	var n: = 0
	for item in items:
		if item != null and item.item_type == "sealed_suit":
			n += 1
	return n


func get_combined_equipment_usage() -> int:
	var usage: = count_sealed_suit_item_rows()
	var gm = GameManager.instance
	if gm != null and gm.equipment_manager != null:
		for eq in gm.equipment_manager.inventory:
			if eq != null and not eq.is_pet_equipment:
				usage += 1
	return usage

func get_combined_equipment_free_slots() -> int:
	var cap: = 15
	var gm = GameManager.instance
	if gm != null and gm.equipment_manager != null:
		cap = int(gm.equipment_manager.max_inventory)
	return max(0, cap - get_combined_equipment_usage())

func add_item(item_name: String, count: int = 1, extra_data: Dictionary = {}) -> Dictionary:
	var result = {"success": false, "message": "", "item": null}
	if ITEM_NAME_ALIASES.has(item_name):
		item_name = str(ITEM_NAME_ALIASES[item_name])


	if item_name == "sealed_suit":
		if get_combined_equipment_free_slots() <= 0:
			result.message = "装备背包已满（含封印套装），请先清理背包"
			return result

		var new_item = InventoryItem.new(item_name, "sealed_suit", 1)
		new_item.custom_data = extra_data.duplicate(true)
		_align_sealed_suit_item_instance_id(new_item)
		items.append(new_item)

		result.success = true
		result.message = "获得封印套装: %s" % extra_data.get("name", "未知")
		result.item = new_item
		inventory_changed.emit()
		return result


	if item_name == "藏宝箱":
		var cb_data = GameData.ALL_ITEMS.get(item_name, null)
		if cb_data == null:
			result.message = "未知物品: %s" % item_name
			return result
		var cb_resolved: = _normalize_item_type(str(cb_data.get("type", "material")))
		var cb_cat: = resolve_bag_category(item_name, cb_resolved, extra_data)
		if get_available_space_by_category(cb_cat) <= 0:
			result.message = "道具背包已满！" if cb_cat == "item" else "材料背包已满！"
			return result
		var cb_new: = InventoryItem.new(item_name, cb_resolved, mini(count, MAX_STACK_SIZE))
		cb_new.custom_data = extra_data.duplicate()
		items.append(cb_new)
		result.success = true
		result.message = "获得 %s x%d" % [item_name, mini(count, MAX_STACK_SIZE)]
		result.item = cb_new
		inventory_changed.emit()
		return result

	var item_data = GameData.resolve_item_def(item_name)
	if item_data == null:
		result.message = "未知物品: %s" % item_name
		return result
	if count <= 0:
		result.message = "数量无效"
		return result

	var resolved_type: = _normalize_item_type(str(item_data.get("type", "material")))
	var category = resolve_bag_category(item_name, resolved_type, extra_data)
	var stackable: Array = []
	for item in items:
		if item == null or str(item.name) != item_name:
			continue
		var item_cd: = _ensure_item_custom_data(item)
		if item.item_type != resolved_type and item.item_type != "sealed_suit" and not item_cd.get("is_limit_equip", false):

			item.item_type = resolved_type
		var ex_tok: = str(extra_data.get("treasure_reward_token", "")).strip_edges()
		var it_tok: = str(item_cd.get("treasure_reward_token", "")).strip_edges()
		if not ex_tok.is_empty():
			if not it_tok.is_empty() and it_tok != ex_tok:
				continue
		elif not it_tok.is_empty():
			continue
		var ex_xianmo_growth: = ""
		var it_xianmo_growth: = ""
		if extra_data.has("xianmo_gift_growth"):
			ex_xianmo_growth = "%.2f" % float(extra_data.get("xianmo_gift_growth", 0.0))
		if item_cd.has("xianmo_gift_growth"):
			it_xianmo_growth = "%.2f" % float(item_cd.get("xianmo_gift_growth", 0.0))
		if not ex_xianmo_growth.is_empty():
			if not it_xianmo_growth.is_empty() and it_xianmo_growth != ex_xianmo_growth:
				continue
		elif not it_xianmo_growth.is_empty():
			continue
		stackable.append(item)
	var room: = 0
	for item in stackable:
		room += maxi(0, MAX_STACK_SIZE - int(item.count))
	var leftover: = maxi(0, count - room)
	var slots_needed: = 0
	if leftover > 0:
		slots_needed = int(ceil(float(leftover) / float(MAX_STACK_SIZE)))
	if slots_needed > get_available_space_by_category(category):
		result.message = "道具背包已满！" if category == "item" else "材料背包已满！"
		return result
	var remaining: = count
	var last_item = null
	for item in stackable:
		if remaining <= 0:
			break
		var space: = MAX_STACK_SIZE - int(item.count)
		if space <= 0:
			continue
		var take: = mini(remaining, space)
		_try_patch_limit_material_custom_data(item, extra_data)
		var filled_cd: = _ensure_item_custom_data(item)
		if not extra_data.is_empty():
			for k in extra_data:
				filled_cd[k] = extra_data[k]
		item.count += take
		remaining -= take
		last_item = item
	while remaining > 0:
		var chunk: = mini(remaining, MAX_STACK_SIZE)
		var new_item = InventoryItem.new(item_name, resolved_type, chunk)
		if not extra_data.is_empty():
			new_item.custom_data = extra_data.duplicate()
		items.append(new_item)
		remaining -= chunk
		last_item = new_item
	result.success = true
	result.message = "获得 %s x%d" % [item_name, count]
	result.item = last_item
	inventory_changed.emit()
	return result

func remove_item(item_id: String, count: int = 1) -> Dictionary:
	var result = {"success": false, "message": ""}

	for i in range(items.size()):
		var item = items[i]
		if item.id == item_id:
			if item.count <= count:
				items.remove_at(i)
				result.success = true
				result.message = "已使用 %s" % item.name
			else:
				item.count -= count
				result.success = true
				result.message = "已使用 %s x%d" % [item.name, count]
			GameManager.instance.track_event("item_consume", {"itemName": item.name, "count": count, "reason": "use"})
			inventory_changed.emit()
			return result

	result.message = "物品不存在"
	return result

func add_limit_equip(item_info: Dictionary) -> Dictionary:
	var result = {"success": false, "message": "", "item": null}

	var item_name = item_info.get("name", "")

	for item in items:
		if item.name == item_name and item.item_type == "material":
			var old_count = item.count
			item.count = min(item.count + 1, MAX_STACK_SIZE)
			if item.count > old_count:
				result.success = true
				result.message = "获得 %s x%d" % [item_name, item.count - old_count]
				result.item = item
				inventory_changed.emit()
				return result
			else:
				result.message = "%s已达最大叠加数量" % item_name
				return result

	if get_available_space_by_category("material") <= 0:
		result.message = "材料背包已满！"
		return result

	var new_item = InventoryItem.new(item_name, "material", 1)
	new_item.custom_data = {
		"slot": item_info.get("slot", ""), 
		"attr": item_info.get("attr", ""), 
		"desc": item_info.get("desc", ""), 
		"is_limit_equip": true, 
	}
	items.append(new_item)

	result.success = true
	result.message = "获得 %s x1" % item_name
	result.item = new_item
	inventory_changed.emit()
	return result

func get_limit_equips() -> Array:
	_repair_limit_material_marks_once()
	var limit_items = []
	for item in items:
		if item.item_type != "material":
			continue
		var item_cd: = _ensure_item_custom_data(item)
		if item_cd.get("is_limit_equip", false):
			limit_items.append(item)
			continue
		if _try_patch_limit_material_custom_data(item):
			limit_items.append(item)
	return limit_items

func _try_patch_limit_material_custom_data(item, incoming_extra: Dictionary = {}) -> bool:
	if item == null:
		return false
	if item.item_type != "material":
		return false
	var item_cd: = _ensure_item_custom_data(item)
	var normalized_name = ForgeData.normalize_limit_material_name(str(item.name))
	if not ForgeData.is_limit_forge_material_name(normalized_name):
		return false
	var changed: = false
	if item.name != normalized_name:
		item.name = normalized_name
		changed = true
	if not item_cd.get("is_limit_equip", false):
		item_cd["is_limit_equip"] = true
		changed = true
	var meta: = ForgeData.limit_material_slot_attr(normalized_name)
	if meta is Dictionary and not meta.is_empty():
		if str(item_cd.get("slot", "")).is_empty():
			item_cd["slot"] = str(meta.get("slot", ""))
			changed = true
		if str(item_cd.get("attr", "")).is_empty():
			item_cd["attr"] = str(meta.get("attr", ""))
			changed = true
	if incoming_extra is Dictionary and incoming_extra.get("is_limit_equip", false):
		if str(item_cd.get("slot", "")).is_empty():
			item_cd["slot"] = str(incoming_extra.get("slot", item_cd.get("slot", "")))
			changed = true
		if str(item_cd.get("attr", "")).is_empty():
			item_cd["attr"] = str(incoming_extra.get("attr", item_cd.get("attr", "")))
			changed = true
	return changed

func _repair_limit_material_marks_once() -> void :
	if _limit_material_migrated:
		return
	_limit_material_migrated = true
	var changed: = false
	for item in items:
		if _try_patch_limit_material_custom_data(item):
			changed = true
	if changed:
		inventory_changed.emit()

func has_item(item_name: String, count: int = 1) -> bool:
	for item in items:
		if item.name == item_name:
			return item.count >= count
	return false

func remove_item_by_name(item_name: String, count: int = 1) -> Dictionary:
	var result = {"success": false, "message": ""}

	for i in range(items.size()):
		var item = items[i]
		if item.name == item_name:
			if item.count <= count:
				items.remove_at(i)
				result.success = true
				result.message = "已消耗 %s" % item.name
			else:
				item.count -= count
				result.success = true
				result.message = "已消耗 %s x%d" % [item.name, count]
			inventory_changed.emit()
			return result

	result.message = "物品不存在"
	return result

func get_item_by_id(item_id: String):
	for item in items:
		if item.id == item_id:
			return item
	return null

func get_available_space() -> int:
	return get_available_space_by_category("item") + get_available_space_by_category("material")

func get_item_count(item_name: String) -> int:
	for item in items:
		if item.name == item_name:
			return item.count
	return 0

func count_item_total_in_bag_and_warehouse(item_name: String) -> int:
	var name_key: = str(item_name).strip_edges()
	if name_key.is_empty():
		return 0
	var n: = 0
	for it in items:
		if it != null and str(it.name) == name_key:
			n += int(it.count)
	for it in warehouse_items:
		if it != null and str(it.name) == name_key:
			n += int(it.count)
	return n


func reconcile_item_total_count_by_name(item_name: String, target_total: int) -> void :
	var name_key: = str(item_name).strip_edges()
	if name_key.is_empty():
		return
	var cap: int = maxi(0, target_total)
	var total: int = count_item_total_in_bag_and_warehouse(name_key)
	if total == cap:
		return
	if total < cap:
		push_warning("[Inventory] reconcile '%s': local total %d < authoritative %d（跳过自动补齐）" % [name_key, total, cap])
		return
	var need_remove: int = total - cap
	for arr in [items, warehouse_items]:
		var idx: int = 0
		while need_remove > 0 and idx < arr.size():
			var inv_it = arr[idx]
			if inv_it == null:
				idx += 1
				continue
			if str(inv_it.name) != name_key:
				idx += 1
				continue
			var c: int = int(inv_it.count)
			if c <= 0:
				arr.remove_at(idx)
				continue
			var cut: int = mini(c, need_remove)
			inv_it.count = c - cut
			need_remove -= cut
			if inv_it.count <= 0:
				arr.remove_at(idx)
			else:
				idx += 1
	inventory_changed.emit()

func _await_xianmo_chest_deposit(network, chest_type: String, op_id: String) -> Dictionary:
	var tree = get_tree()
	if tree == null:
		return {"ok": false, "error": "场景树不可用"}

	var st: Dictionary = {"ok": false, "err": "", "data": {}}
	for attempt in range(2):
		st["ok"] = false
		st["err"] = ""
		st["data"] = {}
		var fn_ok = func(d):
			st["ok"] = true
			st["data"] = d if d is Dictionary else {}
		var fn_fail = func(e: String): st["err"] = str(e)
		network.xianmo_chest_deposit_success.connect(fn_ok, CONNECT_ONE_SHOT)
		network.xianmo_chest_deposit_failed.connect(fn_fail, CONNECT_ONE_SHOT)
		network.xianmo_chest_deposit(chest_type, op_id)
		var deadline_ms: int = Time.get_ticks_msec() + 28000
		while not st["ok"] and str(st["err"]) == "" and Time.get_ticks_msec() < deadline_ms:
			await tree.process_frame
		if st["ok"]:
			return {"ok": true, "data": st["data"]}
		if str(st["err"]) != "":
			return {"ok": false, "error": str(st["err"])}
		if attempt == 0:
			await network.wait_until_xianmo_chest_http_idle(22000)
	return {"ok": false, "error": "同步仙魔宝箱超时"}

func _confirm_skill_book_use(book_name: String) -> bool:
	var gm: = GameManager.instance
	var active_pet = gm.pet_manager.active_pet if gm and gm.pet_manager else null
	var pet_name: = "未知宠物"
	if active_pet:
		pet_name = active_pet.pet_name

	var skill_lines: Array[String] = []
	var skill_slot_n: = 3
	if active_pet and active_pet.has_method("get_skill_slot_count"):
		skill_slot_n = clampi(int(active_pet.get_skill_slot_count()), 1, 5)
	for i in range(skill_slot_n):
		var slot_text: = "无"
		if active_pet and active_pet.has_method("get_skill_slot"):
			var slot: Dictionary = active_pet.get_skill_slot(i)
			var sname: = str(slot.get("skill_name", "")).strip_edges()
			var lv: = int(slot.get("level", 0))
			if not sname.is_empty() and sname != "无" and lv > 0:
				slot_text = "%s lv%d" % [sname, lv]
		skill_lines.append("  槽位%d：%s" % [i + 1, slot_text])

	var msg: = "确定要让 [%s] 学习 [%s] 吗？\n当前技能：\n%s\n学习后将绑定到对应槽位" % [pet_name, book_name, "\n".join(skill_lines)]

	var popup: = Window.new()
	popup.title = ""
	popup.size = Vector2i(420, 400)
	popup.transparent = true
	popup.borderless = true
	popup.unresizable = true

	var main_panel: = Panel.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style: = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.16, 0.97)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.45, 0.7, 0.9)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	main_panel.add_theme_stylebox_override("panel", panel_style)
	popup.add_child(main_panel)

	var vbox: = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	main_panel.add_child(vbox)

	var title_label: = Label.new()
	title_label.text = "技能学习确认"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(title_label)

	var msg_label: = Label.new()
	msg_label.text = msg
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(msg_label)

	var btn_hbox: = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var confirm_btn: = Button.new()
	confirm_btn.text = "确定学习"
	confirm_btn.custom_minimum_size = Vector2(110, 40)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.pressed.connect( func():
		popup.set_meta("confirmed", true)
		popup.hide()
	)
	btn_hbox.add_child(confirm_btn)

	var cancel_btn: = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(110, 40)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect( func(): popup.hide())
	btn_hbox.add_child(cancel_btn)

	popup.set_meta("confirmed", false)
	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
	else:
		add_child(popup)
	popup.popup_centered()
	while popup.visible:
		await popup.visibility_changed
	var confirmed: bool = bool(popup.get_meta("confirmed", false))
	popup.queue_free()
	return confirmed

func use_item(item_id: String, player: Node) -> Dictionary:
	var local_manager = GameManager.instance
	if local_manager != null and local_manager.has_method("local_use_item"):
		return await local_manager.local_use_item(item_id, 1)
	var result = {"success": false, "message": ""}

	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result

	if not item.can_use():
		result.message = "该物品无法使用"
		return result

	var login_guard: = InventoryManager.require_logged_in_for_item_use()
	if not bool(login_guard.get("ok", false)):
		result.message = str(login_guard.get("message", "使用道具需登录并联网，请先登录后再试"))
		return result


	if item.item_type == "martial_skill_book":
		var gm_martial: = GameManager.instance
		if gm_martial == null or gm_martial.martial_arts_manager == null:
			result.message = "武功系统未初始化，请稍后再试"
			return result
		if gm_martial.network == null or not gm_martial.network.is_logged_in():
			result.message = "人物技能书需联网使用，请登录后重试"
			return result
		var pre: Dictionary = gm_martial.martial_arts_manager.can_learn_from_skill_book()
		if not bool(pre.get("ok", false)):
			result.message = str(pre.get("message", "武功栏已满！"))
			return result
		if gm_martial.martial_skill_manager == null:
			result.message = "技能书系统未初始化"
			return result
		gm_martial.martial_skill_manager.request_use_skill_book(item.name)
		result["suppress_item_use_success_dialog"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		result.success = true
		result.message = "正在领悟武功，请稍候…"
		return result

	if item.item_type == "pet_skill_book":
		var gm_pre: = GameManager.instance
		if gm_pre == null or gm_pre.pet_manager == null:
			result.message = "宠物管理器未初始化，请稍后再试"
			return result
		if gm_pre.network == null or not gm_pre.network.is_logged_in():
			result.message = "宠物技能书需联网使用，请登录后重试"
			return result
		if not bool(gm_pre.is_cloud_sync_ready()):
			result.message = "出战宠物状态同步中，请稍后再试"
			return result

		if not await _confirm_skill_book_use(item.name):
			result.message = "已取消学习"
			return result
		if bool(gm_pre.is_active_pet_pending_cloud_sync()):
			if not await gm_pre.await_active_pet_switch_cloud_sync(15.0):
				result.message = "出战宠物状态同步失败，请稍后重试"
				return result

	var use_result: Dictionary = await item.use(player)
	if use_result.get("needs_xianmo_deposit", false):
		var gm = GameManager.instance
		if gm == null or gm.network == null or not gm.network.is_logged_in():
			return {"success": false, "message": "需要登录后才能将宝箱同步至仙魔战场"}
		var chest_t = str(use_result.get("chest_type", ""))
		if chest_t.is_empty():
			return {"success": false, "message": "宝箱类型无效"}
		var op_id = "xianmo_chest_bag_%d_%d_%d" % [Time.get_unix_time_from_system(), randi(), abs(hash(item_id))]
		var deposit_out = await _await_xianmo_chest_deposit(gm.network, chest_t, op_id)
		if not deposit_out.get("ok", false):
			return {"success": false, "message": str(deposit_out.get("error", "同步仙魔宝箱失败"))}
		var deposit_data: Dictionary = deposit_out.get("data", {}) if deposit_out.get("data") is Dictionary else {}
		if deposit_data.has("saveData") and deposit_data.get("saveData") is Dictionary:
			gm.apply_cloud_save(deposit_data.get("saveData"), {"reward_inventory_slice": true})
		else:
			item.count -= 1
			if item.count <= 0:
				items.erase(item)
		if gm.xianmo_chest_manager:
			gm.xianmo_chest_manager.add_chest(chest_t, 1)
		inventory_changed.emit()
		var msg = str(use_result.get("deposit_message", "已放入仙魔宝箱栏"))
		_mark_skip_next_item_used_save()
		item_used.emit(item, msg)
		return {
			"success": true, 
			"message": msg, 
			"authoritative_save_applied": true, 
			"reward_sync_policy": REWARD_SYNC_NONE, 
		}
	if use_result.success:
		var gm_sync: = GameManager.instance
		var authoritative_already_applied: = bool(use_result.get("authoritative_save_applied", false))
		var has_sync_policy: = use_result.has("reward_sync_policy")
		var sync_policy_val: = int(use_result.get("reward_sync_policy", -1))
		if authoritative_already_applied or sync_policy_val == REWARD_SYNC_NONE:
			InventoryManager.mark_server_authority_use_result(use_result)
		elif gm_sync and gm_sync.network and gm_sync.network.is_logged_in() and not has_sync_policy:
			use_result["reward_sync_policy"] = REWARD_SYNC_AUTHORITY_COMPACT_UPLOAD
			InventoryManager.mark_local_item_sync_result(use_result)
		if item.count <= 0:
			items.erase(item)
		inventory_changed.emit()
		if authoritative_already_applied or sync_policy_val == REWARD_SYNC_NONE:
			_mark_skip_next_item_used_save()
		item_used.emit(item, use_result.message)

	return use_result


const CULTIVATION_PILL_WHITELIST_KEYS: = {
	"聚灵丹": "cultivation_pill_juling", 
	"凝神丹": "cultivation_pill_ningshen", 
	"悟道仙丹": "cultivation_pill_wudao", 
}

const DOUBLE_EXP_WHITELIST_KEYS: = {
	"双倍经验丹": "double_exp_day", 
	"双倍经验丹(周)": "double_exp_week", 
	"双倍经验丹(月)": "double_exp_month", 
}

const LIMIT_EQUIPMENT_GIFT_NAME: = "极限装备礼包"
const LIMIT_EQUIPMENT_GIFT_KEY: = "limit_equipment_gift"
const LIMIT_EQUIPMENT_GIFT_MATERIAL_SLOTS_PER: = 5
const LIMIT_EQUIPMENT_GIFT_BATCH_MAX: = 5
const LIMIT_EQUIPMENT_GIFT_GRANTED_NAMES: = [
	"极限武器", "极限衣服", "极限鞋子", "极限血佩", "极限内带", "极限装备礼包", 
]
const WUDAO_PILL_GIFT_GRANTED_NAMES: = ["悟道仙丹", "悟道仙丹礼包"]

const PET_SOUL_ITEM_NAMES: = {
	"金魂魄50": true, 
	"木魂魄50": true, 
	"水魂魄50": true, 
	"火魂魄50": true, 
	"土魂魄50": true, 
}

func use_pet_soul_item(player: Node, item_name: String) -> Dictionary:
	var soul_name: = str(item_name).strip_edges()
	var result: = {"success": false, "message": "", "source_item_name": soul_name, "source_item_type": "pet_soul_item"}
	if not PET_SOUL_ITEM_NAMES.has(soul_name):
		result.message = "无效魂魄道具"
		return result
	var gm_soul: = GameManager.instance
	if gm_soul == null or gm_soul.network == null or not gm_soul.network.is_logged_in():
		result.message = "魂魄道具需联网并由服务器确认，请登录后重试"
		return result
	if player == null:
		result.message = "玩家数据未初始化"
		return result
	var op_id: = "pet_soul_use_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "payload": {}}
	var on_ok: = func(data: Dictionary):
		state["done"] = true
		state["ok"] = true
		state["payload"] = data
	var on_fail: = func(err: String):
		state["done"] = true
		state["ok"] = false
		state["payload"] = {"error": err}
	if not gm_soul.network.pet_soul_use_item_success.is_connected(on_ok):
		gm_soul.network.pet_soul_use_item_success.connect(on_ok, CONNECT_ONE_SHOT)
	if not gm_soul.network.pet_soul_use_item_failed.is_connected(on_fail):
		gm_soul.network.pet_soul_use_item_failed.connect(on_fail, CONNECT_ONE_SHOT)
	gm_soul.network.pet_soul_use_item(soul_name, op_id)
	# 60s 太长：魂魄道具是"点一下就生效"的小操作，网络不通时玩家要干等一分钟。
	# 和服务端其它道具使用接口统一成 15s。
	var wait_start: = Time.get_ticks_msec()
	while not bool(state.get("done", false)):
		if Time.get_ticks_msec() - wait_start > 15000:
			state["done"] = true
			state["ok"] = false
			state["payload"] = {"error": "网络响应超时，请稍后重试"}
			break
		await gm_soul.get_tree().process_frame
	if not bool(state.get("ok", false)):
		result.message = str(state.get("payload", {}).get("error", "魂魄道具使用失败"))
		return result
	var payload: Dictionary = state.get("payload", {})
	if payload.has("saveData") and payload.get("saveData") is Dictionary:
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		gm_soul.apply_cloud_save(payload.get("saveData"), {"reward_inventory_slice": true})
	var added: = int(payload.get("result", {}).get("addedPoints", 0))
	var element: = str(payload.get("result", {}).get("element", ""))
	result.success = true
	result.message = "获得%s属性魂魄%d点" % [element, added] if added > 0 else "魂魄道具使用成功"
	return result

func use_wudao_batch(player: Node, batch_count: int) -> Dictionary:
	return await use_cultivation_pill_batch(player, "悟道仙丹", batch_count)

func use_cultivation_pill_batch(player: Node, pill_name: String, batch_count: int) -> Dictionary:
	var pill_key: = str(pill_name).strip_edges()
	var consume_key: String = String(CULTIVATION_PILL_WHITELIST_KEYS.get(pill_key, ""))
	var result: = {"success": false, "message": "", "source_item_name": pill_key, "source_item_type": "cultivation_pill"}
	if consume_key.is_empty():
		result.message = "该修行丹暂未接入服务端权威，请联系管理员"
		return result
	var gm_cult: = GameManager.instance
	if gm_cult == null or gm_cult.network == null or not gm_cult.network.is_logged_in():
		result.message = "高价值修行丹需联网并由服务器确认，请登录后重试"
		return result
	if player == null:
		result.message = "玩家数据未初始化"
		return result
	var n: = maxi(1, batch_count)
	var rem_quota: = maxi(0, int(player.MAX_CULTIVATION_PILLS_PER_LIFE) - int(player.cultivation_pills_used))
	n = mini(n, rem_quota)
	if n < 1:
		result.message = "本世修行丹药已用完，投胎后可再次使用"
		return result
	var cfg_pill: Variant = GameData.ALL_ITEMS.get(pill_key, {})
	var bonus_per: int = int(cfg_pill.get("cultivation_bonus", 0)) if cfg_pill is Dictionary else 0
	if bonus_per <= 0:
		bonus_per = 500 if pill_key == "悟道仙丹" else (200 if pill_key == "凝神丹" else 100)
	var op_cult: = "consume_%s_%d_%s" % [consume_key, Time.get_ticks_usec(), str(randi())]
	var er_cult: Dictionary = await gm_cult.wait_economy("economy_whitelist_item_consume", func():
		gm_cult.network.economy_whitelist_item_consume(op_cult, consume_key, n)
	)
	if not bool(er_cult.get("ok", false)):
		result.message = str(er_cult.get("err", "修行丹使用失败，请稍后重试"))
		return result
	var er_cult_data: Variant = er_cult.get("data", {})
	var cult_payload: Dictionary = er_cult_data if er_cult_data is Dictionary else {}
	var consumed_n: int = maxi(0, int(cult_payload.get("consumed", 0)))
	var is_dup_cult: bool = bool(cult_payload.get("duplicate", false))
	var pills_before_sync: int = gm_cult.player.cultivation_pills_used
	var cult_before_sync: int = gm_cult.player.cultivation
	result["cultivation_pill_stock_consumed"] = ( not is_dup_cult) and consumed_n > 0
	result["cultivation_pill_consumed_amount"] = consumed_n if bool(result["cultivation_pill_stock_consumed"]) else 0
	if cult_payload.has("saveData") and cult_payload.get("saveData") is Dictionary:
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		var sd_wudao: Dictionary = cult_payload.get("saveData")
		gm_cult.apply_cloud_save(sd_wudao, {
			"economy_cultivation_pill_slice": true, 
		})
		gm_cult.sync_player_authoritative_cultivation_from_dict(sd_wudao.get("playerData"))
	var inventory_reconciled: = true
	var auth_remaining: int = -1
	if cult_payload.has("remaining"):
		auth_remaining = int(cult_payload.get("remaining", -1))
		if auth_remaining >= 0:
			reconcile_item_total_count_by_name(pill_key, auth_remaining)
			if count_item_total_in_bag_and_warehouse(pill_key) != auth_remaining:
				inventory_reconciled = false
	if not inventory_reconciled:
		result.success = false
		result.message = "修行丹已与服务器结算，但背包数量同步异常，请完全退出重登后再试。"
		if bool(result.get("authoritative_save_applied", false)):
			InventoryManager.mark_server_authority_use_result(result)
		return result
	if bool(result["cultivation_pill_stock_consumed"]):
		var pills_after_sync: int = gm_cult.player.cultivation_pills_used
		var pill_delta: int = pills_after_sync - pills_before_sync
		if pill_delta > 0:
			var expected_cult: int = cult_before_sync + pill_delta * bonus_per
			if gm_cult.player.cultivation < expected_cult:
				gm_cult.player.cultivation = expected_cult
	var messages: Array = []
	if is_dup_cult or consumed_n <= 0:
		messages.append("修行丹状态已与服务器同步（重复请求未重复扣道具）")
	else:
		var cult_gain_show: int = gm_cult.player.cultivation - cult_before_sync
		if cult_gain_show <= 0:
			cult_gain_show = bonus_per * maxi(1, consumed_n)
		messages.append("修行值+%d（本世已用%d/%d颗）" % [cult_gain_show, int(gm_cult.player.cultivation_pills_used), int(gm_cult.player.MAX_CULTIVATION_PILLS_PER_LIFE)])
	result.success = true
	result.message = "、".join(messages)
	if bool(result.get("authoritative_save_applied", false)):
		InventoryManager.mark_server_authority_use_result(result)
	return result

static func build_double_exp_activated_message(gm, now_ts: int, added_hours: int) -> String:
	# 三种双倍丹各自独立计时、叠加生效：每多一种 +100% 经验。
	# 以前这里写「已叠加X小时，总剩余约X小时」，X 取的是**最晚那条通道**，
	# 日+周会显示 168 小时，玩家会以为日丹那 24 小时被吞了。
	# 现在改成：先讲清楚当前是几种丹在叠、总加成多少，再说本次加了多少、到什么时候结束。
	if gm == null or gm.player == null:
		return "双倍经验已激活：野外战斗和离线经验 +%d%%" % 100
	var count: = 1
	if gm.player.has_method("get_double_exp_channel_count"):
		count = maxi(1, int(gm.player.get_double_exp_channel_count(now_ts)))
	var left_seconds: int = maxi(0, int(gm.player.double_exp_until) - now_ts)
	var left_hours: int = int(ceil(float(left_seconds) / 3600.0))
	var stack_text: = ""
	if count > 1:
		stack_text = "，%d种丹药同时叠加" % count
	return "双倍经验已激活：野外战斗和离线经验 +%d%%%s（本次+%d小时，最晚约%d小时后结束）" % [
		count * 100, stack_text, added_hours, left_hours]


func use_double_exp_batch(player: Node, item_name: String, batch_count: int) -> Dictionary:
	var pill_key: = str(item_name).strip_edges()
	var consume_key: String = String(DOUBLE_EXP_WHITELIST_KEYS.get(pill_key, ""))
	var result: = {"success": false, "message": "", "source_item_name": pill_key, "source_item_type": "gift"}
	if consume_key.is_empty():
		result.message = "双倍经验丹配置异常"
		return result
	var gm_de: = GameManager.instance
	if gm_de == null or gm_de.network == null or not gm_de.network.is_logged_in():
		result.message = "高价值双倍经验丹需联网并由服务器确认，请登录后重试"
		return result
	if player == null:
		result.message = "玩家数据未初始化"
		return result
	var n: = maxi(1, batch_count)
	var stacked_hours_per: = 24
	if pill_key == "双倍经验丹(月)":
		stacked_hours_per = 30 * 24
	elif pill_key == "双倍经验丹(周)":
		stacked_hours_per = 7 * 24
	var op_de: = "consume_%s_%d_%s" % [consume_key, Time.get_ticks_usec(), str(randi())]
	var er_de: Dictionary = await gm_de.wait_economy("economy_whitelist_item_consume", func():
		gm_de.network.economy_whitelist_item_consume(op_de, consume_key, n)
	)
	if not bool(er_de.get("ok", false)):
		result.message = str(er_de.get("err", "双倍经验丹使用失败，请稍后重试"))
		return result
	var er_de_data: Variant = er_de.get("data", {})
	var de_payload: Dictionary = er_de_data if er_de_data is Dictionary else {}
	var consumed_n: int = maxi(0, int(de_payload.get("consumed", 0)))
	var is_dup_de: bool = bool(de_payload.get("duplicate", false))
	if de_payload.has("saveData") and de_payload.get("saveData") is Dictionary:
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		gm_de.apply_cloud_save(de_payload.get("saveData"), {"double_exp_slice": true})
	if de_payload.has("remaining"):
		var rem_de: int = int(de_payload.get("remaining", -1))
		if rem_de >= 0:
			reconcile_item_total_count_by_name(pill_key, rem_de)
	var now_ts_de: int = int(Time.get_unix_time_from_system())
	var total_stacked_hours: = stacked_hours_per * maxi(1, consumed_n)
	if is_dup_de or consumed_n <= 0:
		result.message = "双倍经验状态已与服务器同步（重复请求未重复扣道具）"
	else:
		result.message = InventoryManager.build_double_exp_activated_message(gm_de, now_ts_de, total_stacked_hours)
	result.success = true
	if bool(result.get("authoritative_save_applied", false)):
		InventoryManager.mark_server_authority_use_result(result)
	return result

const _PET_MEDAL_AUTHORITY_SAVE_OPTS: = {
	"pets_authoritative": true, 
	"preserve_local_pets_not_in_cloud": true, 
	"skip_pet_collection_trim": true, 
	"skip_pet_progress_merge": true, 
}

func _refresh_main_ui_pet_roster_after_authority() -> void :
	var gm: = GameManager.instance
	if gm == null or not gm.has_method("_find_main_ui_node"):
		return
	var main_ui: Node = gm._find_main_ui_node()
	if main_ui != null and main_ui.has_method("_refresh_pet_roster_after_authority_reward"):
		main_ui.call_deferred("_refresh_pet_roster_after_authority_reward")

func _await_pet_medal_use_prechecks(gm: GameManager) -> Dictionary:
	var out: = {"ok": false, "message": ""}
	if gm == null or gm.pet_manager == null:
		out.message = "宠物管理器未初始化，请稍后再试"
		return out
	if gm.network == null or not gm.network.is_logged_in():
		out.message = "宠物补章器需联网使用，请登录后重试"
		return out
	if not bool(gm.is_cloud_sync_ready()):
		out.message = "出战宠物状态同步中，请稍后再试"
		return out
	if bool(gm.is_active_pet_pending_cloud_sync()):
		if not await gm.await_active_pet_switch_cloud_sync(15.0):
			out.message = "出战宠物状态同步失败，请稍后重试"
			return out
	out.ok = true
	return out

func _apply_pet_medal_authority_save(gm: GameManager, medal_data: Dictionary) -> bool:
	if gm == null or not (medal_data.get("saveData") is Dictionary):
		return false
	gm.apply_cloud_save(medal_data.get("saveData"), _PET_MEDAL_AUTHORITY_SAVE_OPTS.duplicate(true))
	_refresh_main_ui_pet_roster_after_authority()
	return true

static func _snapshot_pet_medal_counts(pet) -> Dictionary:
	var mc: Dictionary = {}
	if pet != null and pet.medal_counts is Dictionary:
		mc = pet.medal_counts
	return {
		"brave": int(mc.get("brave", 0)), 
		"calm": int(mc.get("calm", 0)), 
		"bold": int(mc.get("bold", 0)), 
	}

static func _sum_pet_medal_snapshot(counts: Dictionary) -> int:
	return int(counts.get("brave", 0)) + int(counts.get("calm", 0)) + int(counts.get("bold", 0))

static func _pet_medal_slots_full(pet) -> bool:
	if pet == null or not (pet.medal_counts is Dictionary):
		return false
	for medal_type in PetManager.MEDAL_TYPES:
		if int(pet.medal_counts.get(medal_type, 0)) < PetManager.MEDAL_MAX_PER_TYPE:
			return false
	return true

static func _pet_medal_gain_names(before: Dictionary, pet) -> String:
	if pet == null or not (pet.medal_counts is Dictionary):
		return ""
	var parts: Array = []
	for medal_type in PetManager.MEDAL_TYPES:
		if int(pet.medal_counts.get(medal_type, 0)) > int(before.get(medal_type, 0)):
			parts.append(str(PetManager.MEDAL_DISPLAY_NAMES.get(medal_type, "勋章")))
	return "、".join(parts)

static func _pet_upgrade_dan_medal_skip_reason(pet) -> String:
	if pet == null:
		return ""
	if int(pet.reincarnation_count) > 0:
		return "已转生宠物满级不再发放勋章"
	var cap: = 0
	if pet.has_method("get_effective_max_level"):
		cap = int(pet.get_effective_max_level())
	if cap > 0 and int(pet.last_max_level_medal_cap) >= cap:
		return "这一档满级勋章已经领过"
	if _pet_medal_slots_full(pet):
		return "满级奖励：勋章槽已满"
	return ""


static func _finish_pet_upgrade_dan_medal_message(pet_manager, pet, old_level: int, before: Dictionary) -> String:
	if pet_manager == null or pet == null:
		return ""
	var gained: = _pet_medal_gain_names(before, pet)
	if _sum_pet_medal_snapshot(_snapshot_pet_medal_counts(pet)) > _sum_pet_medal_snapshot(before) and not gained.is_empty():
		if pet_manager.has_method("queue_max_level_skill_learn_if_needed"):
			pet_manager.queue_max_level_skill_learn_if_needed(pet, old_level)
		return "满级奖励：%s" % gained
	var server_sum: = _sum_pet_medal_snapshot(_snapshot_pet_medal_counts(pet))
	var backup: = ""
	if pet_manager.has_method("grant_max_level_medal_if_needed"):
		backup = str(pet_manager.grant_max_level_medal_if_needed(pet, old_level))
	var after_sum: = _sum_pet_medal_snapshot(_snapshot_pet_medal_counts(pet))
	if after_sum > server_sum:
		if pet_manager.has_method("flush_pending_pet_medal_syncs"):
			pet_manager.flush_pending_pet_medal_syncs("max_level_reward")
		if not backup.is_empty() and backup != "满级奖励：勋章槽已满":
			return backup
		var backup_names: = _pet_medal_gain_names(before, pet)
		if not backup_names.is_empty():
			return "满级奖励：%s" % backup_names
	if not backup.is_empty():
		return backup
	return _pet_upgrade_dan_medal_skip_reason(pet)

func use_pet_medal_batch(batch_count: int) -> Dictionary:
	var result: = {"success": false, "message": ""}
	var gm: = GameManager.instance
	var pre: = await _await_pet_medal_use_prechecks(gm)
	if not bool(pre.get("ok", false)):
		result.message = str(pre.get("message", "宠物补章失败"))
		return result
	var owned: = 0
	for item in items:
		if item != null and str(item.name).strip_edges() == "宠物补章器":
			owned = int(item.count)
			break
	var n: = clamp_medal_batch_use_count(batch_count, owned)
	if n <= 0:
		result.message = "当前出战宠物勋章槽已满或补章器不足"
		return result
	var op_medal: = "pet_medal_use_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var medal_state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var on_medal_success = func(data: Dictionary):
		medal_state.done = true
		medal_state.ok = true
		medal_state.data = data if data is Dictionary else {}
		medal_state.message = str(medal_state.data.get("message", "批量补章成功"))
	var on_medal_failed = func(error: String):
		medal_state.done = true
		medal_state.ok = false
		medal_state.message = error
	gm.network.pet_medal_use_batch_success.connect(on_medal_success, CONNECT_ONE_SHOT)
	gm.network.pet_medal_use_batch_failed.connect(on_medal_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_medal_use_batch(op_medal, n)
	while not bool(medal_state.done):
		await gm.get_tree().process_frame
	if not bool(medal_state.ok):
		result.message = str(medal_state.message if medal_state.message != "" else "批量补章失败")
		return result
	var medal_data: Dictionary = medal_state.data if medal_state.data is Dictionary else {}
	if not _apply_pet_medal_authority_save(gm, medal_data):
		result.message = "服务端已处理，本地同步失败，请重新登录确认"
		return result
	result["authoritative_save_applied"] = true
	result["reward_sync_policy"] = REWARD_SYNC_NONE
	result.success = true
	result.message = str(medal_data.get("message", medal_state.message if medal_state.message != "" else "批量补章成功"))
	return result

func _count_distinct_limit_material_types_in_bag() -> int:
	var seen: Dictionary = {}
	for item in items:
		if item == null or not _is_limit_forge_material_inventory_row(item):
			continue
		var canonical_name: = ForgeData.normalize_limit_material_name(str(item.name))
		if canonical_name.is_empty():
			canonical_name = str(item.name)
		seen[canonical_name] = true
	return seen.size()

func _check_limit_equipment_gift_material_capacity(_gift_count: int) -> Dictionary:

	var existing_types: = _count_distinct_limit_material_types_in_bag()
	var slots_needed: = maxi(0, LIMIT_EQUIPMENT_GIFT_MATERIAL_SLOTS_PER - existing_types)
	if slots_needed <= 0:
		return {"ok": true}
	var material_free: = get_available_space_by_category("material")
	if material_free < slots_needed:
		var block: = _build_capacity_block_result(
			"极限装备锦囊开启失败：材料背包空位不足（需要%d格，当前%d格）。" % [slots_needed, material_free]
		)
		block["ok"] = false
		return block
	return {"ok": true}

func use_limit_equipment_gift_batch(player: Node, batch_count: int) -> Dictionary:
	var result: = {
		"success": false, 
		"message": "", 
		"source_item_name": LIMIT_EQUIPMENT_GIFT_NAME, 
		"source_item_type": "gift", 
	}
	var n: = maxi(1, batch_count)
	if n > LIMIT_EQUIPMENT_GIFT_BATCH_MAX:
		result.message = "极限装备锦囊单次最多开启%d个，请分批使用" % LIMIT_EQUIPMENT_GIFT_BATCH_MAX
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "该礼包包含高价值极限材料，需联网使用，请登录后重试"
		return result
	if player == null:
		result.message = "玩家数据未初始化"
		return result
	if get_item_count(LIMIT_EQUIPMENT_GIFT_NAME) < n:
		result.message = "物品数量不足（需要%d，拥有%d）" % [n, get_item_count(LIMIT_EQUIPMENT_GIFT_NAME)]
		return result
	var cap_block: Dictionary = _check_limit_equipment_gift_material_capacity(n)
	if not bool(cap_block.get("ok", false)):
		result.message = str(cap_block.get("message", "材料背包空位不足"))
		if cap_block.has("show_dialog"):
			result["show_dialog"] = cap_block.get("show_dialog")
			result["dialog_title"] = cap_block.get("dialog_title")
			result["dialog_message"] = cap_block.get("dialog_message")
		return result
	var op_limit: = "consume_limit_gift_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var er_limit: Dictionary = await gm.wait_economy("economy_whitelist_item_consume", func():
		gm.network.economy_whitelist_item_consume(op_limit, LIMIT_EQUIPMENT_GIFT_KEY, n)
	)
	if not bool(er_limit.get("ok", false)):
		result.message = str(er_limit.get("err", "极限装备锦囊校验失败，请稍后重试"))
		return result
	var limit_payload: Dictionary = er_limit.get("data", {}) if er_limit.get("data") is Dictionary else {}
	var dup_limit: bool = bool(limit_payload.get("duplicate", false))
	var consumed_limit: int = maxi(0, int(limit_payload.get("consumed", 0)))
	var sd_limit: Variant = limit_payload.get("saveData", null)
	if not (sd_limit is Dictionary):
		result.message = "服务器返回异常，礼包开启未完成，请重新登录查看背包"
		return result
	result["authoritative_save_applied"] = true
	result["reward_sync_policy"] = REWARD_SYNC_NONE
	var limit_apply_opts: Dictionary = gm.build_authority_reward_apply_opts({}, {
		"preserve_local_pets_not_in_cloud": true, 
		"skip_pet_collection_trim": true, 
	})
	var limit_granted: Array = limit_apply_opts.get("granted_item_names", [])
	for limit_name in LIMIT_EQUIPMENT_GIFT_GRANTED_NAMES:
		if not limit_granted.has(limit_name):
			limit_granted.append(limit_name)
	limit_apply_opts["granted_item_names"] = limit_granted
	gm.apply_cloud_save(sd_limit as Dictionary, limit_apply_opts)
	if dup_limit or consumed_limit <= 0:
		result.message = "极限装备锦囊状态已与服务器同步（重复请求未重复扣道具）"
	else:
		var opened_n: = maxi(1, consumed_limit)
		if opened_n <= 1:
			result.message = "获得极限装备全套（武器、衣服、鞋子、血佩、内带）"
		else:
			result.message = "获得极限装备全套 x%d（武器、衣服、鞋子、血佩、内带）" % opened_n
	result.success = true
	InventoryManager.mark_server_authority_use_result(result)
	return result

func rollback_used_item_reward_failure(item_id: String, use_result: Dictionary) -> void :
	if not bool(use_result.get("success", false)):
		return
	if not bool(use_result.get("rollback_on_sync_failure", false)):
		return
	var scope: = str(use_result.get("rollback_scope", ROLLBACK_SCOPE_INVENTORY_ITEM_ONLY))
	if scope == ROLLBACK_SCOPE_NONE:
		return
	match scope:
		ROLLBACK_SCOPE_INVENTORY_ITEM_ONLY:
			var item = get_item_by_id(item_id)
			if item != null:
				item.count += 1
			else:
				var rollback_name: = str(use_result.get("source_item_name", "")).strip_edges()
				var rollback_type: = str(use_result.get("source_item_type", "gift")).strip_edges()
				if rollback_name.is_empty():
					return
				var restored = InventoryItem.new(rollback_name, rollback_type, 1)
				items.append(restored)
		ROLLBACK_SCOPE_PLAYER_GOLD_ONLY:
			var gm_gold: = GameManager.instance
			if gm_gold and gm_gold.player and use_result.has("rollback_player_gold"):
				gm_gold.player.gold = int(use_result.get("rollback_player_gold", gm_gold.player.gold))
				gm_gold.gold_changed.emit(gm_gold.player.gold)
		ROLLBACK_SCOPE_PETS_GRANTED_ONLY:
			push_warning("[InventoryManager] pets_granted_only rollback not implemented; server authority items should use scope none")
	inventory_changed.emit()

func use_gold_bag_batch(item_id: String, player: Node, count: int) -> Dictionary:
	var result = {"success": false, "message": ""}
	var login_guard: = InventoryManager.require_logged_in_for_item_use()
	if not bool(login_guard.get("ok", false)):
		result.message = str(login_guard.get("message", "使用道具需登录并联网，请先登录后再试"))
		return result
	if count <= 0:
		result.message = "数量无效"
		return result
	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	if item.count < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, item.count]
		return result
	var item_name: = str(item.name) if item else ""
	var bag_cfg = GOLD_BAG_CONFIG.get(item_name)
	if bag_cfg == null:
		result.message = "该道具不支持批量使用"
		return result
	var amount: int = int(bag_cfg.get("amount", 0))
	var server_key: String = str(bag_cfg.get("server_key", ""))
	var sponsor: String = str(bag_cfg.get("sponsor", ""))
	var item_name_for_emit: = item_name
	var gm: = GameManager.instance
	var total_gold: = count * amount
	var op_batch: = "gold_bag_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var er_batch = await gm.wait_economy("economy_whitelist_gold", func():
		gm.network.economy_whitelist_gold(op_batch, server_key, total_gold, count)
	)
	if not er_batch.get("ok", false):
		result.message = str(er_batch.get("err", "在线发放失败，请稍后重试"))
		return result
	var batch_data = er_batch.get("data", {})
	var server_applied: = false
	if batch_data is Dictionary:
		if batch_data.has("saveData") and batch_data.get("saveData") is Dictionary and gm.has_method("apply_cloud_save"):
			var gb_batch_opts: Dictionary = {
				"reward_inventory_slice": true, 
				"clamp_inventory_local_consumption": true, 
				"granted_item_names": [item_name], 
			}
			gm.apply_cloud_save(batch_data.get("saveData"), gb_batch_opts)
			server_applied = true
			result["authoritative_save_applied"] = true
		if batch_data.has("newGold"):
			player.gold = int(batch_data.get("newGold", player.gold))
	gm.gold_changed.emit(player.gold)
	if not server_applied:
		result.message = "服务器返回异常，金币袋使用未完成，请重新登录查看背包"
		return result
	inventory_changed.emit()
	_mark_skip_next_item_used_save()
	item_used.emit(item, "")
	result.success = true
	if sponsor.is_empty():
		result.message = "批量使用了 %d 个%s\n获得%d金币！x%d" % [count, item_name, amount, count]
	else:
		result.message = "批量使用了 %d 个%s\n获得%s大佬赞助的%d金币！x%d" % [count, item_name, sponsor, amount, count]
	InventoryManager.mark_server_authority_use_result(result)
	return result

func use_tower_gift_batch(item_id: String, player: Node, count: int) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "summary_lines": [], "total_gold": 0, "opened": 0, "pet_gift_count": 0}
	if count <= 0:
		result.message = "数量无效"
		return result
	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	var gift_name: = str(item.name).strip_edges()
	count = clamp_pet_batch_use_count(count, int(item.count))
	if not InventoryManager.is_tower_family_gift_name(gift_name):
		result.message = "该道具不支持此批量方式"
		return result
	if int(item.count) < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, int(item.count)]
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "当前网络不可用，已阻止批量使用。"
		return result
	var op_id: = "tower_gift_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var success_message: = "%s批量开启成功" % gift_name
	var fail_message: = "%s批量开启失败，请稍后重试" % gift_name
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", success_message))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	var pets_before: = InventoryManager.capture_pet_roster_snapshot(gm)
	gm.network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_gift_open(gift_name, op_id, {"batchCount": count})
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else fail_message)
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		InventoryManager.mark_server_authority_use_result(result)
	var opened_pets_tower: = InventoryManager.build_opened_pets_for_broadcast(gm, reward_result, pets_before)
	InventoryManager.emit_server_auth_pet_reward_broadcast("gift", gift_name, data, opened_pets_tower, count)
	var summary_lines: Array = []
	var summary_variant: Variant = data.get("summaryLines", data.get("towerGiftSummaryLines", []))
	if summary_variant is Array:
		for line in summary_variant:
			summary_lines.append(str(line))
	if summary_lines.is_empty():
		summary_lines.append(str(data.get("message", state.message if state.message != "" else success_message)))
	result.success = true
	result.opened = int(reward_result.get("opened", count))
	result.total_gold = int(reward_result.get("grantedGold", 0))
	var granted_items_variant: Variant = reward_result.get("grantedItems", [])
	if granted_items_variant is Array:
		for entry_variant in granted_items_variant:
			if entry_variant is Dictionary:
				var entry: Dictionary = entry_variant
				if str(entry.get("name", "")) == "5+宠物礼包":
					result.pet_gift_count += int(entry.get("count", 0))
	result.summary_lines = summary_lines
	result.message = "\n".join(summary_lines)
	return result

func use_pet_egg_batch(item_id: String, player: Node, count: int) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "summary_lines": [], "opened": 0}
	if count <= 0:
		result.message = "数量无效"
		return result
	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	var egg_name: = str(item.name).strip_edges()
	count = clamp_pet_batch_use_count(count, int(item.count))
	if not InventoryManager.is_server_auth_pet_egg_name(egg_name):
		result.message = "该宠物蛋不支持批量孵化"
		return result
	if int(item.count) < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, int(item.count)]
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "当前网络不可用，已阻止批量使用。"
		return result
	var op_id: = "pet_egg_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var success_message: = "%s批量孵化成功" % egg_name
	var fail_message: = "%s批量孵化失败，请稍后重试" % egg_name
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", success_message))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	gm.network.pet_egg_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_egg_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_egg_open(egg_name, op_id, {"batchCount": count})
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else fail_message)
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
	var granted_pets: Array = reward_result.get("grantedPets", [])
	var opened_pets: Array = []
	if granted_pets is Array:
		for pet_info in granted_pets:
			if pet_info is Dictionary:
				opened_pets.append(InventoryManager._opened_pet_entry_from_dict(pet_info))
	if not opened_pets.is_empty() and gm.player != null:
		var player_name: = str(gm.player.player_name).strip_edges()
		if not player_name.is_empty():
			var min_growth: = 6.0
			if egg_name == "5+宠物蛋":
				min_growth = 5.0
			var egg_src: = egg_name
			if egg_name.ends_with("属性宠物蛋"):
				egg_src = "五行属性宠物蛋·" + egg_name.replace("属性宠物蛋", "")
			var qualified: Array = []
			for pet_info in opened_pets:
				var pn: = InventoryManager.format_pet_name_with_mutation_from_info(pet_info)
				var pg: = float(pet_info.get("growth", 0.0))
				if not pn.is_empty() and pg >= min_growth:
					qualified.append({
						"name": pn, 
						"growth": pg, 
						"mutation_count": InventoryManager.get_pet_mutation_count_from_info(pet_info), 
					})
			if not qualified.is_empty():
				var cap: = mini(qualified.size(), 5)
				var name_parts: Array[String] = []
				for i in range(cap):
					if qualified[i] is Dictionary:
						name_parts.append("【%s】（成长%.2f）" % [str(qualified[i].get("name", "")), float(qualified[i].get("growth", 0.0))])
				var batch_names: = "、".join(name_parts)
				var details: = {
					"pet_name": batch_names, 
					"growth": float(qualified[0].get("growth", 0.0)), 
					"egg_source": egg_src, 
					"mutation_count": int(qualified[0].get("mutation_count", 0)), 
				}
				if qualified.size() > 1 or count > 1:
					details["batch_names"] = batch_names
					details["batch_total"] = qualified.size()
				gm.broadcast_event("pet_egg_high_growth", player_name, details)
	var summary_lines: Array = []
	if count <= 1 and not opened_pets.is_empty():
		for pet_info in opened_pets:
			var pet_name: = InventoryManager.format_pet_name_with_mutation_from_info(pet_info)
			var pet_growth: = float(pet_info.get("growth", 0.0))
			var mailed: = bool(pet_info.get("mailed", false))
			var line: = "获得【%s】" % pet_name
			if pet_growth > 0.0:
				line += "（成长%.3f）" % pet_growth
			if mailed:
				line += "，已发送到邮件"
			summary_lines.append(line)
	else:
		if str(data.get("message", "")).strip_edges() != "":
			summary_lines.append(str(data.get("message", "")))
	result.success = true
	result.opened = granted_pets.size() if granted_pets is Array else count
	result.summary_lines = summary_lines
	result.message = "\n".join(summary_lines) if not summary_lines.is_empty() else success_message
	return result

func use_server_gift_batch(item_id: String, player: Node, count: int) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "summary_lines": [], "opened": 0}
	if count <= 0:
		result.message = "数量无效"
		return result
	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	var gift_name: = str(item.name).strip_edges()
	count = clamp_pet_batch_use_count(count, int(item.count))
	if not InventoryManager.is_server_auth_pet_gift_name(gift_name):
		result.message = "该礼包不支持批量开启"
		return result
	if int(item.count) < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, int(item.count)]
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "当前网络不可用，已阻止批量使用。"
		return result
	var op_id: = "server_gift_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var success_message: = "%s批量开启成功" % gift_name
	var fail_message: = "%s批量开启失败，请稍后重试" % gift_name
	var batch_payload: Dictionary = {"batchCount": count}
	if gift_name.begins_with("仙魔"):
		var item_custom: Dictionary = item.custom_data if item.custom_data is Dictionary else {}
		if item_custom.has("xianmo_gift_growth"):
			var growth_hint: float = float(item_custom.get("xianmo_gift_growth", 0.0))
			if growth_hint > 0.0:
				batch_payload["xianmo_gift_growth"] = growth_hint
				var growths: Array = []
				for _i in range(count):
					growths.append(growth_hint)
				batch_payload["xianmo_gift_growths"] = growths
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", success_message))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	gm.network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_gift_open(gift_name, op_id, batch_payload)
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else fail_message)
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	if bool(data.get("duplicate", false)):
		var has_auth_save: bool = data.has("saveData") and data.get("saveData") is Dictionary
		if not has_auth_save:
			result.message = "服务器判定为重复请求，未附带最新存档。请重新登录或同步云端后再查看背包与宠物。"
			if gm.has_method("download_cloud_save"):
				gm.call_deferred("download_cloud_save")
			return result
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
	var opened_pets: = InventoryManager.build_opened_pets_from_granted(reward_result)
	InventoryManager.emit_server_auth_pet_reward_broadcast("gift", gift_name, data, opened_pets, count)
	var summary_lines: Array = []
	if count <= 1 and not opened_pets.is_empty():
		for pet_info in opened_pets:
			var pet_name: = InventoryManager.format_pet_name_with_mutation_from_info(pet_info)
			var pet_growth: = float(pet_info.get("growth", 0.0))
			var mailed: = bool(pet_info.get("mailed", false))
			var line: = "获得【%s】" % pet_name
			if pet_growth > 0.0:
				line += "（成长%.3f）" % pet_growth
			if mailed:
				line += "，已发送到邮件"
			summary_lines.append(line)
	else:
		if str(data.get("message", "")).strip_edges() != "":
			summary_lines.append(str(data.get("message", "")))
	result.success = true
	result.opened = opened_pets.size() if not opened_pets.is_empty() else int(reward_result.get("opened", count))
	result.summary_lines = summary_lines
	result.message = "\n".join(summary_lines) if not summary_lines.is_empty() else success_message
	return result

func use_offline_pet_gift_batch(item_id: String, player: Node, count: int) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "summary_lines": [], "opened": 0}
	if count <= 0:
		result.message = "数量无效"
		return result
	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result
	if str(item.name).strip_edges() != "离线宠物礼包":
		result.message = "该道具不支持此批量方式"
		return result
	count = clamp_pet_batch_use_count(count, int(item.count))
	if int(item.count) < count:
		result.message = "物品数量不足（需要%d，拥有%d）" % [count, int(item.count)]
		return result
	var gm: = GameManager.instance
	if gm == null or gm.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if gm.network == null or not gm.network.is_logged_in():
		result.message = "当前网络不可用，已阻止批量使用。"
		return result
	var offline_payload: Dictionary = {"batchCount": count}
	if gm != null:
		offline_payload["current_map"] = str(gm.current_map)
		offline_payload["previous_map"] = str(gm.previous_map)
		offline_payload["is_tower_battle"] = bool(gm.is_tower_battle)
		offline_payload["is_suit_dungeon_battle"] = bool(gm.is_suit_dungeon_battle)
		if gm.has_method("get"):
			offline_payload["is_tower_settling"] = bool(gm.get("is_tower_settling"))
	var op_id: = "offline_pet_gift_batch_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var state: = {"done": false, "ok": false, "data": {}, "message": ""}
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data if data is Dictionary else {}
		state.message = str(state.data.get("message", "离线宠物锦囊批量开启成功"))
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	gm.network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
	gm.network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
	gm.network.request_pet_gift_open("离线宠物礼包", op_id, offline_payload)
	while not bool(state.done):
		await gm.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message if state.message != "" else "离线宠物锦囊批量开启失败，请稍后重试")
		return result
	var data: Dictionary = state.data if state.data is Dictionary else {}
	var reward_result: Dictionary = data.get("result", {}) if data.get("result") is Dictionary else {}
	if data.has("saveData") and data.get("saveData") is Dictionary:
		InventoryManager.apply_server_auth_pet_reward_save(gm, data.get("saveData"), reward_result)
		result["authoritative_save_applied"] = true
		result["reward_sync_policy"] = REWARD_SYNC_NONE
		InventoryManager.mark_server_authority_use_result(result)
	var summary_lines: Array = []
	var summary_variant: Variant = data.get("summaryLines", data.get("offlineGiftSummaryLines", []))
	if summary_variant is Array:
		for line in summary_variant:
			summary_lines.append(str(line))
	if summary_lines.is_empty():
		summary_lines.append(str(data.get("message", state.message if state.message != "" else "离线宠物锦囊批量开启成功")))
	result.success = true
	result.opened = int(reward_result.get("opened", count))
	result.summary_lines = summary_lines
	result.message = "\n".join(summary_lines)
	return result

func reconcile_treasure_chests_with_server(game_manager, current_token: String = "") -> Dictionary:
	var result: = {"ok": false, "removed": 0, "current_token_valid": true, "message": ""}
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.ok = true
		return result
	var token_rows: Array = []
	for it in items:
		if it == null:
			continue
		if str(it.name) != "藏宝箱":
			continue
		var tk: = str((it.custom_data if it.custom_data is Dictionary else {}).get("treasure_token", "")).strip_edges()
		if tk.is_empty():
			continue
		token_rows.append({"item": it, "token": tk})
	if token_rows.is_empty():
		result.ok = true
		return result
	var tokens: Array = []
	var seen_local: = {}
	for row in token_rows:
		var tk: = str(row.get("token", ""))
		if seen_local.has(tk):
			continue
		seen_local[tk] = true
		tokens.append(tk)
	var vr: Dictionary = await game_manager.wait_treasure_token_validation(tokens)
	if not bool(vr.get("ok", false)):
		result.ok = false
		result.message = str(vr.get("err", "藏宝匣状态校验失败"))
		return result
	var payload: Dictionary = vr.get("data", {}) if vr.get("data") is Dictionary else {}
	var valid_set: = {}
	for tk in payload.get("validTokens", []):
		valid_set[str(tk).strip_edges()] = true
	var removed: = 0
	var changed: = false
	for i in range(items.size() - 1, -1, -1):
		var it = items[i]
		if it == null or str(it.name) != "藏宝箱":
			continue
		var tk: = str((it.custom_data if it.custom_data is Dictionary else {}).get("treasure_token", "")).strip_edges()
		if tk.is_empty() or not valid_set.has(tk):
			items.remove_at(i)
			removed += max(1, int(it.count))
			changed = true
	if changed:
		inventory_changed.emit()
	result.ok = true
	result.removed = removed
	if not current_token.strip_edges().is_empty():
		result.current_token_valid = valid_set.has(current_token.strip_edges())
	return result

func get_items_by_type(item_type: String) -> Array:
	var result = []
	for item in items:
		if item.item_type == item_type:
			result.append(item)
	return result

func get_total_count() -> int:
	var total = 0
	for item in items:
		total += item.count
	return total

func get_random_drop(monster_level: int = 1) -> String:
	var all_drops = []
	for item_name in GameData.ALL_ITEMS.keys():
		var drop_rate = GameData.get_item_drop_rate(item_name)
		if drop_rate > 0:
			all_drops.append({"name": item_name, "rate": drop_rate})

	for drop_info in all_drops:
		if randf() < drop_info.rate:
			return drop_info.name

	return ""

var xianmo_chests: Dictionary = {
	"bronze": 0, 
	"silver": 0, 
	"gold": 0
}

signal xianmo_chests_changed

func add_xianmo_chest(chest_type: String, count: int = 1):
	if xianmo_chests.has(chest_type):
		xianmo_chests[chest_type] += count
		xianmo_chests_changed.emit()

func remove_xianmo_chest(chest_type: String, count: int = 1) -> bool:
	if xianmo_chests.has(chest_type) and xianmo_chests[chest_type] >= count:
		xianmo_chests[chest_type] -= count
		xianmo_chests_changed.emit()
		return true
	return false

func get_xianmo_chest_count(chest_type: String) -> int:
	return xianmo_chests.get(chest_type, 0)

func has_xianmo_chest(chest_type: String) -> bool:
	return get_xianmo_chest_count(chest_type) > 0

func to_dict() -> Dictionary:
	var items_data = []
	for item in items:
		items_data.append(item.to_dict())

	var warehouse_data = []
	for item in warehouse_items:
		warehouse_data.append(item.to_dict())

	return {
		"items": items_data, 
		"warehouse_items": warehouse_data, 
		"equipment_warehouse": equipment_warehouse.duplicate(), 
		"pet_equipment_items": pet_equipment_items.duplicate(), 
		"pet_equipment_warehouse": pet_equipment_warehouse.duplicate(), 
		"xianmo_chests": xianmo_chests.duplicate()
	}


func _align_sealed_suit_item_instance_id(item) -> void :
	if item == null or item.item_type != "sealed_suit":
		return
	var cd: Dictionary = item.custom_data if item.custom_data is Dictionary else {}
	item.custom_data = cd
	var inv_inst: = str(cd.get("_inv_inst_id", "")).strip_edges()
	var cur_id: = str(item.id).strip_edges()
	if not inv_inst.is_empty() and inv_inst != "null":
		item.id = inv_inst
	else:
		if cur_id.is_empty() or cur_id == "null":
			item.id = item._generate_id()
	cd["_inv_inst_id"] = str(item.id)

func _sync_reincarnation_token_item_types(target_items: Array) -> void :
	for item in target_items:
		if item == null:
			continue
		var item_name: = str(item.name)
		if not item_name.ends_with("宠物转生令牌"):
			continue
		var cfg: Variant = GameData.ALL_ITEMS.get(item_name, null)
		if cfg == null or not cfg is Dictionary:
			continue
		var d: = cfg as Dictionary
		item.item_type = _normalize_item_type(str(d.get("type", "material")))
		item.data = d.duplicate()

func _migrate_legacy_xiuxingdan_items(target_items: Array) -> void :

	for item in target_items:
		if item == null:
			continue
		if str(item.name) != "修行丹":
			continue
		var cfg: Variant = GameData.ALL_ITEMS.get("悟道仙丹", null)
		if cfg == null or not cfg is Dictionary:
			continue
		var d: = cfg as Dictionary
		item.name = "悟道仙丹"
		item.item_type = str(d.get("type", "cultivation_pill"))
		item.data = d.duplicate()

## 2026-10 钱袋合并：旧存档里的 14 种赞助钱袋统一并入「钱币袋」（每个仍是 10 万金币）。
## 服务端 core.State._migrate_coin_bags 做同一件事，两边必须同步，否则会出现
## 「背包里显示钱币袋 x52，点使用提示道具数量不足」。
func _migrate_gold_bags_to_coin_bag(target_items: Array) -> void :
	var coin_name: = InventoryBagSort.COIN_BAG_ITEM_NAME
	var total: = 0
	var hit: = false
	var coin_item = null
	for item in target_items.duplicate():
		if item == null:
			continue
		var n: = str(item.name).strip_edges()
		if n == coin_name:
			coin_item = item
			total += maxi(0, int(item.count))
			continue
		if not InventoryBagSort.is_gold_bag_name(n):
			continue
		total += maxi(0, int(item.count))
		target_items.erase(item)
		hit = true
	if not hit:
		return
	if total <= 0:
		if coin_item != null:
			target_items.erase(coin_item)
		return
	if coin_item != null:
		coin_item.count = total
		return
	var cfg: Variant = GameData.ALL_ITEMS.get(coin_name, null)
	if cfg == null or not cfg is Dictionary:
		return
	var coin_dict: = {
		"name": coin_name, 
		"count": total, 
		"item_type": "gift", 
		"data": (cfg as Dictionary).duplicate(), 
	}
	target_items.append(InventoryItem.from_dict(coin_dict))


func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return

	if data.has("items"):
		items.clear()
		var items_array = data.get("items", [])
		for item_dict in items_array:
			var item = InventoryItem.from_dict(item_dict)
			items.append(item)
		for item in items:
			_align_sealed_suit_item_instance_id(item)
		_migrate_legacy_xiuxingdan_items(items)
		_migrate_gold_bags_to_coin_bag(items)
		_sync_reincarnation_token_item_types(items)
		_normalize_sealed_suit_items(items)
		_dedupe_sealed_suit_duplicate_ids(items)
		_merge_duplicate_items()
		_limit_material_migrated = false
		_repair_limit_material_marks_once()

	if data.has("warehouse_items"):
		warehouse_items.clear()
		var warehouse_array = data.get("warehouse_items", [])
		for item_dict in warehouse_array:
			var item = InventoryItem.from_dict(item_dict)
			warehouse_items.append(item)
		for item in warehouse_items:
			_align_sealed_suit_item_instance_id(item)
		_migrate_legacy_xiuxingdan_items(warehouse_items)
		_migrate_gold_bags_to_coin_bag(warehouse_items)
		_sync_reincarnation_token_item_types(warehouse_items)
		_normalize_sealed_suit_items(warehouse_items)
		_dedupe_sealed_suit_duplicate_ids(warehouse_items)
		_merge_duplicate_warehouse_items()

	if data.has("equipment_warehouse"):
		equipment_warehouse.clear()
		var equip_warehouse = data.get("equipment_warehouse", [])
		if equip_warehouse is Array:
			equipment_warehouse = equip_warehouse.duplicate()

	var _pet_equipment_items_changed: = false
	var _pet_equipment_warehouse_changed: = false
	if data.has("pet_equipment_items"):
		pet_equipment_items.clear()
		var pet_equip_items = data.get("pet_equipment_items", [])
		if pet_equip_items is Array:
			pet_equipment_items = pet_equip_items.duplicate()
			_normalize_pet_equipment_array_names(pet_equipment_items)
		_pet_equipment_items_changed = true

	if data.has("pet_equipment_warehouse"):
		pet_equipment_warehouse.clear()
		var pet_equip_warehouse = data.get("pet_equipment_warehouse", [])
		if pet_equip_warehouse is Array:
			pet_equipment_warehouse = pet_equip_warehouse.duplicate()
			_normalize_pet_equipment_array_names(pet_equipment_warehouse)
		_pet_equipment_warehouse_changed = true

	if data.has("xianmo_chests"):
		var chests_data = data.get("xianmo_chests", {})
		if chests_data is Dictionary:
			for chest_type in chests_data:
				xianmo_chests[chest_type] = chests_data[chest_type]

	if _pet_equipment_items_changed:
		pet_equipment_inventory_changed.emit()
	if _pet_equipment_warehouse_changed:
		pet_equipment_warehouse_changed.emit()

func _merge_duplicate_items():
	_merge_duplicate_item_array(items, false)

func _merge_duplicate_warehouse_items():
	_merge_duplicate_item_array(warehouse_items, true)

func _merge_duplicate_item_array(target_items: Array, is_warehouse: bool) -> void :
	var merged: = {}
	var rebuilt: Array = []
	var merged_count: = 0

	for item in target_items:
		if item == null:
			continue

		if item.item_type == "sealed_suit" or item.name == "藏宝箱" or _is_non_stackable_item_instance(item.name, item.item_type):
			rebuilt.append(item)
			continue
		if _is_limit_forge_material_inventory_row(item):
			rebuilt.append(item)
			continue
		var merge_key: = "%s|%s" % [item.name, item.item_type]
		if not merged.has(merge_key):
			merged[merge_key] = []
		var stack_list: Array = merged[merge_key]
		var remaining: int = max(0, int(item.count))
		for existing in stack_list:
			if remaining <= 0:
				break
			if existing == null:
				continue
			if int(existing.count) >= MAX_STACK_SIZE:
				continue
			var move_count: = mini(MAX_STACK_SIZE - int(existing.count), remaining)
			if move_count <= 0:
				continue
			existing.count += move_count
			remaining -= move_count
			merged_count += 1
		while remaining > 0:
			var new_stack_count: = mini(remaining, MAX_STACK_SIZE)
			var stack_item = item
			if rebuilt.has(item) or new_stack_count != int(item.count):
				stack_item = InventoryItem.new(item.name, item.item_type, new_stack_count)
				stack_item.custom_data = item.custom_data.duplicate()
			else:
				stack_item.count = new_stack_count
			stack_list.append(stack_item)
			rebuilt.append(stack_item)
			remaining -= new_stack_count

	target_items.clear()
	for rebuilt_item in rebuilt:
		target_items.append(rebuilt_item)
	if merged_count > 0:
		if is_warehouse:
			print("[InventoryManager] 合并并规范了 %d 个仓库重复物品" % merged_count)
		else:
			print("[InventoryManager] 合并并规范了 %d 个重复物品" % merged_count)

func _normalize_sealed_suit_items(target_items: Array):
	var rebuilt: Array = []
	var normalized_count = 0

	for item in target_items:
		if item == null:
			continue
		if item.item_type != "sealed_suit":
			rebuilt.append(item)
			continue

		var split_count = max(1, int(item.count))
		for i in range(split_count):
			if i == 0:
				item.count = 1
				rebuilt.append(item)
			else:
				var clone = InventoryItem.new(item.name, item.item_type, 1)
				clone.custom_data = item.custom_data.duplicate(true)
				clone.custom_data["_inv_inst_id"] = clone.id
				rebuilt.append(clone)
			normalized_count += 1

	target_items.clear()
	for item in rebuilt:
		target_items.append(item)

	if normalized_count > 0:
		print("[InventoryManager] 已规范封印套装堆叠数据，共处理 %d 条" % normalized_count)

func _dedupe_sealed_suit_duplicate_ids(target_items: Array) -> void :
	var seen: = {}
	var out: Array = []
	for item in target_items:
		if item == null:
			continue
		if item.item_type != "sealed_suit":
			out.append(item)
			continue
		var sid: = str(item.id).strip_edges()
		if sid.is_empty():
			_align_sealed_suit_item_instance_id(item)
			sid = str(item.id).strip_edges()
		if seen.has(sid):
			push_warning("[InventoryManager] 封印套装重复 id=%s，已重生实例 id" % sid)
			item.id = item._generate_id()
			if item.custom_data is Dictionary:
				item.custom_data["_inv_inst_id"] = str(item.id)
			sid = str(item.id).strip_edges()
		seen[sid] = true
		out.append(item)
	target_items.clear()
	for x in out:
		target_items.append(x)

class InventoryItem:
	var id: String
	var name: String
	var item_type: String
	var count: int = 1
	var data: Dictionary = {}
	var custom_data: Dictionary = {}

	func _init(p_name: String = "", p_type: String = "material", p_count: int = 1):
		id = _generate_id()
		# 老存档里的物品名可能已经被换皮改过，落库前先归一到现用名
		name = GameData.migrate_item_name(p_name)
		item_type = p_type
		count = p_count
		var resolved: Variant = GameData.resolve_item_def(name)
		data = resolved if resolved is Dictionary else {}

	func _generate_id() -> String:
		var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
		var result = ""
		for i in range(8):
			result += chars[randi() % chars.length()]
		return result

	func get_rarity() -> String:
		return data.get("rarity", "common")

	func get_rarity_name() -> String:
		return GameData.ITEM_RARITY.get(get_rarity(), {}).get("name", "普通")

	func get_rarity_color() -> Color:
		return GameData.ITEM_RARITY.get(get_rarity(), {}).get("color", Color.WHITE)

	func get_desc() -> String:
		var live: Variant = GameData.resolve_item_def(name)
		if live is Dictionary:
			var live_desc: = str((live as Dictionary).get("desc", "")).strip_edges()
			if not live_desc.is_empty():
				return live_desc
		return data.get("desc", "未知物品")

	func can_use() -> bool:
		return item_type in ["pill", "level_item", "cultivation_pill", "gift", "pet_egg", "chest", "treasure_chest", "pet_skill_book", "martial_skill_book", "pet_soul_item"]

	func use(player: Node) -> Dictionary:
		var result = {"success": false, "message": "", "source_item_name": name, "source_item_type": item_type}
		if not can_use():
			result.message = "该物品无法使用"
			return result

		var messages = []

		if item_type == "pill":
			var hp_restore = data.get("hp_restore", 0)
			var mp_restore = data.get("mp_restore", 0)

			if hp_restore > 0:
				player.hp = min(player.hp + hp_restore, player.get_max_hp())
				messages.append("恢复%d点生命" % hp_restore)
			if mp_restore > 0:
				player.mp = min(player.mp + mp_restore, player.get_max_mp())
				messages.append("恢复%d点内力" % mp_restore)

		elif item_type == "cultivation_pill":
			var gm_inv: = GameManager.instance
			if gm_inv == null or gm_inv.inventory_manager == null:
				result.message = "游戏管理器未初始化，请稍后再试"
				return result
			var inv_outer: InventoryManager = gm_inv.inventory_manager as InventoryManager
			return await inv_outer.use_cultivation_pill_batch(player, str(name), 1)

		elif item_type == "pet_soul_item":
			var gm_soul: = GameManager.instance
			if gm_soul == null or gm_soul.inventory_manager == null:
				result.message = "游戏管理器未初始化，请稍后再试"
				return result
			var inv_soul: InventoryManager = gm_soul.inventory_manager as InventoryManager
			return await inv_soul.use_pet_soul_item(player, str(name))

		elif item_type == "chest":
			var gm = GameManager.instance
			if gm == null:
				result.message = "游戏管理器未初始化，请稍后再试"
				return result
			if gm.xianmo_chest_manager == null:
				result.message = "仙魔宝箱系统未初始化，请稍后再试"
				return result
			var chest_type_map = {
				"青铜宝箱": "bronze", 
				"白银宝箱": "silver", 
				"黄金宝箱": "gold"
			}
			var chest_type = str(chest_type_map.get(name, ""))
			if chest_type.is_empty():
				result.message = "未知宝箱类型"
				return result
			if gm.network and gm.network.is_logged_in():
				return {
					"success": false, 
					"needs_xianmo_deposit": true, 
					"chest_type": chest_type, 
					"deposit_message": "已放入仙魔宝箱栏：%s x1" % name
				}
			gm.xianmo_chest_manager.add_chest(chest_type, 1)
			messages.append("已放入仙魔宝箱栏：%s x1" % name)

		elif item_type == "treasure_chest":
			var cd: Dictionary = custom_data if custom_data is Dictionary else {}
			var token_s: = str(cd.get("treasure_token", "")).strip_edges()
			if token_s.is_empty():
				result.message = "藏宝匣数据异常"
				return result
			var gm3: = GameManager.instance
			if gm3 == null or gm3.network == null or not gm3.network.is_logged_in():
				result.message = "需要登录后才能开启藏宝匣"
				return result
			var opid: = "inv_treasure_%d_%s" % [Time.get_ticks_usec(), id]
			var tw_raw: Variant = await gm3.wait_treasure_chest_open(token_s, opid)
			var tw: Dictionary = tw_raw if tw_raw is Dictionary else {"ok": false, "data": {}, "err": "开启失败"}
			var d: Dictionary = tw.get("data", {}) if tw.get("data") is Dictionary else {}
			var pending_open: = bool(d.get("pending", false))
			var already_opened: = bool(d.get("alreadyOpened", false))
			if bool(d.get("duplicate", false)) and not already_opened:
				result.message = str(d.get("message", "重复操作已忽略"))
				return result
			if not bool(tw.get("ok", false)):
				var err_msg: = str(tw.get("err", "开启失败"))
				if err_msg.find("已开启") >= 0:
					messages.append("藏宝匣已开启（结果已同步）")
				else:
					result.message = err_msg
					return result
			if d.has("saveData") and d.get("saveData") is Dictionary:
				gm3.apply_cloud_save(d.get("saveData"), {"reward_inventory_slice": true})
				if gm3.inventory_manager:
					gm3.inventory_manager.inventory_changed.emit()
					gm3.inventory_manager.pet_equipment_inventory_changed.emit()
					gm3.inventory_manager.pet_equipment_warehouse_changed.emit()
				if gm3.xianmo_system and gm3.xianmo_system.has_method("load_from_server"):
					gm3.xianmo_system.load_from_server()
				result["authoritative_save_applied"] = true
				result["reward_sync_policy"] = REWARD_SYNC_NONE
			if pending_open:
				messages.append(str(d.get("message", "开奖处理中，奖励将自动到账")))
				result.show_dialog = true
				result.dialog_title = "已提交开奖"
				result.dialog_message = "藏宝匣已提交服务器处理，奖励将自动到账。\n若网络波动，请稍后重新登录查看。"
				count -= 1
				result.success = true
				result.message = "、".join(messages)
				return result
			var rew: Variant = d.get("reward", {})
			if already_opened:
				messages.append(str(d.get("message", "藏宝匣已开启（结果已同步）")))
			elif rew is Dictionary:
				var rtype: = str((rew as Dictionary).get("type", ""))
				if rtype == "gold":
					messages.append("获得 %s" % str((rew as Dictionary).get("name", "金币")))
				elif rtype == "item":
					var iname: = str((rew as Dictionary).get("name", ""))
					var icnt: = maxi(1, int((rew as Dictionary).get("count", 1)))
					if iname.is_empty():
						result.message = "奖励数据异常"
						return result
					messages.append("获得 %s x%d" % [iname, icnt])
				else:
					messages.append("藏宝匣已开启")
			else:
				messages.append("藏宝匣已开启")

		elif item_type == "pet_skill_book":
			var gm_skill: = GameManager.instance
			if gm_skill == null or gm_skill.pet_manager == null:
				result.message = "宠物管理器未初始化，请稍后再试"
				return result
			if gm_skill.network == null or not gm_skill.network.is_logged_in():
				result.message = "宠物技能书需联网使用，请登录后重试"
				return result
			if not bool(gm_skill.is_cloud_sync_ready()):
				result.message = "出战宠物状态同步中，请稍后再试"
				return result
			var learn_result: Dictionary = gm_skill.pet_manager.learn_skill_book_from_active_pet(name)
			if not bool(learn_result.get("success", false)):
				result.message = str(learn_result.get("message", "学习技能失败"))
				return result
			result["suppress_item_use_success_dialog"] = true
			result["reward_sync_policy"] = REWARD_SYNC_NONE
			result.success = true
			result.message = str(learn_result.get("message", "已提交学习请求"))

			return result

		elif item_type == "gift":
			var gold_bag_cfg = GOLD_BAG_CONFIG.get(name)
			if gold_bag_cfg != null:
				var gb_amount: int = int(gold_bag_cfg.get("amount", 0))
				var gb_server_key: String = str(gold_bag_cfg.get("server_key", ""))
				var gb_sponsor: String = str(gold_bag_cfg.get("sponsor", ""))
				var gm_gb: = GameManager.instance
				if gm_gb == null:
					result.message = "游戏管理器未初始化，请稍后再试"
					return result
				var op_gb: = "gold_bag_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				var er_gb: Dictionary = await gm_gb.wait_economy("economy_whitelist_gold", func():
					gm_gb.network.economy_whitelist_gold(op_gb, gb_server_key, gb_amount, 1)
				)
				if not er_gb.get("ok", false):
					result.message = str(er_gb.get("err", "在线发放失败，请稍后重试"))
					return result
				var gbd: Variant = er_gb.get("data", {})
				var gb_server_applied: = false
				if gbd is Dictionary:
					var gbd_dict: Dictionary = gbd as Dictionary
					if gbd_dict.has("saveData") and gbd_dict.get("saveData") is Dictionary:
						var gb_apply_opts: Dictionary = {
							"reward_inventory_slice": true, 
							"clamp_inventory_local_consumption": true, 
							"granted_item_names": [name], 
						}
						gm_gb.apply_cloud_save(gbd_dict.get("saveData"), gb_apply_opts)
						gb_server_applied = true
						result["authoritative_save_applied"] = true
						result["reward_sync_policy"] = REWARD_SYNC_NONE
						InventoryManager.mark_server_authority_use_result(result)
					if gbd_dict.has("newGold"):
						player.gold = int(gbd_dict.get("newGold", player.gold))
				if not gb_server_applied:
					result.message = "服务器返回异常，金币袋使用未完成，请重新登录查看背包"
					return result
				gm_gb.gold_changed.emit(player.gold)
				if str(gb_sponsor).is_empty():
					messages.append("打开%s，获得%d金币！" % [name, gb_amount])
				else:
					messages.append("打开%s，获得%s大佬赞助的%d金币！" % [name, gb_sponsor, gb_amount])
			elif name == "天关礼包":
				var tower_reward_result: Dictionary = await _request_server_auth_pet_reward_open("gift", name)
				if not bool(tower_reward_result.get("success", false)):
					result.message = str(tower_reward_result.get("message", "天关锦囊需要服务端权威开启"))
					return result
				return tower_reward_result
			elif name.ends_with("关礼包") and name != "天关礼包":
				var floor_reward_result: Dictionary = await _request_server_auth_pet_reward_open("gift", name)
				if not bool(floor_reward_result.get("success", false)):
					result.message = str(floor_reward_result.get("message", "关卡礼包需要服务端权威开启"))
					return result
				return floor_reward_result
			elif name == "离线宠物礼包":
				var gm_offline = GameManager.instance
				var offline_payload: Dictionary = {}
				if gm_offline != null:
					offline_payload["current_map"] = str(gm_offline.current_map)
					offline_payload["previous_map"] = str(gm_offline.previous_map)
					offline_payload["is_tower_battle"] = bool(gm_offline.is_tower_battle)
					offline_payload["is_suit_dungeon_battle"] = bool(gm_offline.is_suit_dungeon_battle)
					if gm_offline.has_method("get"):
						offline_payload["is_tower_settling"] = bool(gm_offline.get("is_tower_settling"))
				var offline_reward_result: Dictionary = await _request_server_auth_pet_reward_open("gift", name, offline_payload)
				if not bool(offline_reward_result.get("success", false)):
					result.message = str(offline_reward_result.get("message", "离线宠物锦囊需要服务端权威开启"))
					return result
				return offline_reward_result
			elif name == "新手礼包":
				var game_manager = GameManager.instance
				if game_manager == null or game_manager.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				var inv_manager = game_manager.inventory_manager
				var cap_newbie: Dictionary = inv_manager._check_gift_capacity(game_manager, name, 5, 0, [])
				if not bool(cap_newbie.get("ok", false)):
					return inv_manager._build_capacity_block_result(str(cap_newbie.get("message", "背包空间不足")))
				if game_manager == null or game_manager.equipment_manager == null:
					result.message = "装备管理器未初始化，请稍后再试"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "新手锦囊包含人物装备，需联网使用，请登录后重试"
					return result
				var newbie_grant_result: Dictionary = await inv_manager._grant_single_attr_set_via_server(game_manager, "新手礼包")
				if not bool(newbie_grant_result.get("success", false)):
					result.message = str(newbie_grant_result.get("message", "新手锦囊开启失败，请稍后重试"))
					return result
				var newbie_data: Dictionary = newbie_grant_result.get("data", {}) if newbie_grant_result.get("data") is Dictionary else {}
				var newbie_result: Dictionary = newbie_data.get("result", {}) if newbie_data.get("result") is Dictionary else {}
				var granted_items: Array = newbie_result.get("grantedItems", []) if newbie_result.get("grantedItems") is Array else []
				for granted in granted_items:
					if granted is Dictionary:
						messages.append("获得【%s】" % str(granted.get("name", "新手装备")))
				if messages.is_empty():
					messages.append(str(newbie_grant_result.get("message", "新手锦囊开启成功")))
				result["authoritative_save_applied"] = true
				result["reward_sync_policy"] = REWARD_SYNC_NONE
			elif name == "内测先锋礼包":
				var game_manager_pioneer = GameManager.instance
				if game_manager_pioneer == null or game_manager_pioneer.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				if game_manager_pioneer.network == null or not game_manager_pioneer.network.is_logged_in():
					result.message = "该礼包需联网使用，请登录后重试"
					return result
				var cap_pioneer_gift: Dictionary = game_manager_pioneer.inventory_manager._check_gift_capacity(game_manager_pioneer, name, 5, 1, [])
				if not bool(cap_pioneer_gift.get("ok", false)):
					result.message = str(cap_pioneer_gift.get("message", "背包空间不足"))
					return result
				var pioneer_reward_result: Dictionary = await _request_server_auth_pet_reward_open("gift", name)
				if not bool(pioneer_reward_result.get("success", false)):
					result.message = str(pioneer_reward_result.get("message", "先锋锦囊需要服务端权威开启"))
					return result
				return pioneer_reward_result
			elif name == "新人扶持礼包":
				var game_manager_newbie = GameManager.instance
				if game_manager_newbie == null or game_manager_newbie.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				if game_manager_newbie.network == null or not game_manager_newbie.network.is_logged_in():
					result.message = "该礼包需联网使用，请登录后重试"
					return result
				var cap_newbie_gift: Dictionary = game_manager_newbie.inventory_manager._check_gift_capacity(game_manager_newbie, name, 5, 1, [])
				if not bool(cap_newbie_gift.get("ok", false)):
					result.message = str(cap_newbie_gift.get("message", "背包空间不足"))
					return result
				var newbie_reward_result: Dictionary = await _request_server_auth_pet_reward_open("gift", name)
				if not bool(newbie_reward_result.get("success", false)):
					result.message = str(newbie_reward_result.get("message", "新人扶持锦囊需要服务端权威开启"))
					return result
				return newbie_reward_result
			elif name == "开荒礼包":
				var game_manager = GameManager.instance
				if game_manager == null or game_manager.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "该礼包需联网使用，请登录后重试"
					return result
				var inv_manager = game_manager.inventory_manager
				var cap_pioneer: Dictionary = inv_manager._check_gift_capacity(game_manager, name, 5, 7, [])
				if not bool(cap_pioneer.get("ok", false)):
					return inv_manager._build_capacity_block_result(str(cap_pioneer.get("message", "背包空间不足")))
				var state: = {"done": false, "ok": false, "message": "", "data": {}}
				var frontier_op_id: = "frontier_gift_use_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				var on_frontier_success = func(data: Dictionary):
					state.done = true
					state.data = data if data is Dictionary else {}
					if state.data.get("success") == false:
						state.ok = false
						state.message = str(state.data.get("message", "开荒锦囊使用失败"))
						return
					state.ok = true
					state.message = str(state.data.get("message", "开荒锦囊使用成功"))
					if state.data.has("saveData") and state.data.get("saveData") is Dictionary:
						game_manager.apply_cloud_save(state.data.get("saveData"), {
							"reward_inventory_slice": true, 
							"preserve_local_pets_not_in_cloud": true, 
							"skip_pet_collection_trim": true, 
						})
				var on_frontier_failed = func(error: String):
					state.done = true
					state.ok = false
					state.message = error
				game_manager.network.frontier_gift_use_success.connect(on_frontier_success, CONNECT_ONE_SHOT)
				game_manager.network.frontier_gift_use_failed.connect(on_frontier_failed, CONNECT_ONE_SHOT)
				game_manager.network.request_frontier_gift_use(frontier_op_id)
				var frontier_deadline: = Time.get_ticks_msec() + 4000
				while not bool(state.done) and Time.get_ticks_msec() < frontier_deadline:
					await game_manager.get_tree().process_frame
				if not bool(state.done):
					var pull_state: = {"done": false, "ok": false, "save_data": {}}
					var on_pull_done = func(success: bool, save_data: Dictionary):
						pull_state.done = true
						pull_state.ok = success
						pull_state.save_data = save_data if save_data is Dictionary else {}
					game_manager.cloud_save_downloaded.connect(on_pull_done, CONNECT_ONE_SHOT)
					game_manager.download_cloud_save()
					var pull_deadline: = Time.get_ticks_msec() + 12000
					while not bool(pull_state.done) and Time.get_ticks_msec() < pull_deadline:
						await game_manager.get_tree().process_frame
					if bool(pull_state.ok):
						state.done = true
						state.ok = true
						state.data = {"message": "开荒锦囊使用成功", "saveData": pull_state.save_data, "result": {}}
						state.message = "开荒锦囊使用成功"
						if pull_state.save_data is Dictionary and not pull_state.save_data.is_empty():
							game_manager.apply_cloud_save(pull_state.save_data, {
								"preserve_local_pets_not_in_cloud": true, 
								"skip_pet_collection_trim": true, 
								"clamp_inventory_local_consumption": true, 
							})
				if not bool(state.ok):
					result.message = str(state.message if state.message != "" else "开荒锦囊请求超时，请重新登录查看结果")
					return result
				messages.append("获得5亿金币")
				var granted_items: = []
				var granted_pets: = []
				var mailed_pets: = []
				var frontier_data = state.data if state.data is Dictionary else {}
				var frontier_result = frontier_data.get("result", {})
				if frontier_result is Dictionary:
					granted_items = frontier_result.get("grantedItems", [])
					granted_pets = frontier_result.get("grantedPets", [])
					mailed_pets = frontier_result.get("mailedPets", [])
				if granted_items.is_empty() and game_manager and game_manager.equipment_manager:
					for equip in game_manager.equipment_manager.inventory:
						if equip and String(equip.name).find("内测先锋·") == 0:
							granted_items.append({"name": str(equip.name)})
				if granted_pets.is_empty() and game_manager and game_manager.pet_manager:
					for pet_inst in game_manager.pet_manager.pets:
						if pet_inst and str(pet_inst.pet_name) == "琳琳" and int(pet_inst.level) == 1 and int(pet_inst.generation) == 0:
							granted_pets.append({"name": str(pet_inst.pet_name)})
				for granted in granted_items:
					if granted is Dictionary:
						messages.append("获得【%s】" % str(granted.get("name", "人物装备")))
				if granted_pets.size() > 0:
					messages.append("获得%d只【赤翅蛾】（成长6.0）" % granted_pets.size())
				if mailed_pets.size() > 0:
					messages.append("%d只【赤翅蛾】因宠物栏已满，已发送到邮件" % mailed_pets.size())
				count -= 1
				result["authoritative_save_applied"] = true
				result["reward_sync_policy"] = REWARD_SYNC_NONE
				result.success = true
				result.message = "\n".join(messages)
			elif name == "极限装备礼包":
				var game_manager = GameManager.instance
				if game_manager == null or game_manager.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				return await game_manager.inventory_manager.use_limit_equipment_gift_batch(player, 1)
			elif name == "悟道仙丹礼包":
				var game_manager = GameManager.instance
				if game_manager == null or game_manager.inventory_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "该礼包包含高价值修行材料，需联网使用，请登录后重试"
					return result
				var cap_wudao: Dictionary = game_manager.inventory_manager._check_gift_capacity(
					game_manager, name, 0, 0, 
					[{"name": "悟道仙丹", "item_type": "cultivation_pill", "count": 50}]
				)
				if not bool(cap_wudao.get("ok", false)):
					return game_manager.inventory_manager._build_capacity_block_result(str(cap_wudao.get("message", "背包空间不足")))
				var op_wudao: = "consume_wudao_gift_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				var er_wudao: Dictionary = await game_manager.wait_economy("economy_whitelist_item_consume", func():
					game_manager.network.economy_whitelist_item_consume(op_wudao, "wudao_pill_gift")
				)
				if not bool(er_wudao.get("ok", false)):
					result.message = str(er_wudao.get("err", "开悟丹锦囊校验失败，请稍后重试"))
					return result
				var er_wudao_data: Variant = er_wudao.get("data", {})
				var wudao_payload: Dictionary = er_wudao_data if er_wudao_data is Dictionary else {}
				var dup_wudao: bool = bool(wudao_payload.get("duplicate", false))
				var consumed_wudao: int = maxi(0, int(wudao_payload.get("consumed", 0)))
				var sd_wudao: Dictionary = InventoryManager.extract_economy_authority_save_data(wudao_payload)
				if sd_wudao.is_empty():
					sd_wudao = await game_manager.inventory_manager._await_cloud_save_download(game_manager)
				if sd_wudao.is_empty():
					result.message = "服务器返回异常，礼包开启未完成，请重新登录查看背包"
					return result
				result["authoritative_save_applied"] = true
				result["reward_sync_policy"] = REWARD_SYNC_NONE
				var wudao_apply_opts: Dictionary = game_manager.build_authority_reward_apply_opts({}, {
					"preserve_local_pets_not_in_cloud": true, 
					"skip_pet_collection_trim": true, 
				})
				var wudao_granted: Array = wudao_apply_opts.get("granted_item_names", [])
				for wudao_grant_name in WUDAO_PILL_GIFT_GRANTED_NAMES:
					if not wudao_granted.has(wudao_grant_name):
						wudao_granted.append(wudao_grant_name)
				wudao_apply_opts["granted_item_names"] = wudao_granted
				game_manager.apply_cloud_save(sd_wudao, wudao_apply_opts)
				if dup_wudao or consumed_wudao <= 0:
					messages.append("开悟丹锦囊状态已与服务器同步（重复请求未重复扣道具）")
				else:
					messages.append("获得开悟丹 x50")
				result.success = true
				result.message = "\n".join(messages)
				return result
			elif name == "双倍经验丹" or name == "双倍经验丹(月)" or name == "双倍经验丹(周)":
				var gm_exp = GameManager.instance
				if gm_exp == null or gm_exp.player == null:
					result.message = "玩家数据未初始化"
					return result
				if gm_exp.network == null or not gm_exp.network.is_logged_in():
					result.message = "高价值双倍经验丹需联网并由服务器确认，请登录后重试"
					return result
				var consume_key: = "double_exp_day"
				var stacked_hours: = 24
				if name == "双倍经验丹(月)":
					consume_key = "double_exp_month"
					stacked_hours = 30 * 24
				elif name == "双倍经验丹(周)":
					consume_key = "double_exp_week"
					stacked_hours = 7 * 24
				var op_double: = "consume_%s_%d_%s" % [consume_key, Time.get_ticks_usec(), str(randi())]
				var er_double: Dictionary = await gm_exp.wait_economy("economy_whitelist_item_consume", func():
					gm_exp.network.economy_whitelist_item_consume(op_double, consume_key)
				)
				if not bool(er_double.get("ok", false)):
					result.message = str(er_double.get("err", "双倍经验丹使用失败，请稍后重试"))
					return result
				var er_double_data: Variant = er_double.get("data", {})
				var consumed_double: int = 0
				var dup_double: bool = false
				if er_double_data is Dictionary:
					consumed_double = maxi(0, int((er_double_data as Dictionary).get("consumed", 0)))
					dup_double = bool((er_double_data as Dictionary).get("duplicate", false))
				if er_double_data is Dictionary and (er_double_data as Dictionary).has("saveData") and (er_double_data as Dictionary).get("saveData") is Dictionary:
					result["authoritative_save_applied"] = true
					result["reward_sync_policy"] = REWARD_SYNC_NONE
					gm_exp.apply_cloud_save((er_double_data as Dictionary).get("saveData"), {"double_exp_slice": true})
				var now_ts: int = int(Time.get_unix_time_from_system())
				if dup_double or consumed_double <= 0:
					messages.append("双倍经验状态已与服务器同步（重复请求未重复扣道具）")
				else:
					messages.append(InventoryManager.build_double_exp_activated_message(gm_exp, now_ts, stacked_hours))
			elif name == "宠物补章器":
				var gm_medal = GameManager.instance
				if gm_medal == null or gm_medal.inventory_manager == null:
					result.message = "宠物管理器未初始化，请稍后再试"
					return result
				var inv_medal: InventoryManager = gm_medal.inventory_manager as InventoryManager
				var medal_res: Dictionary = await inv_medal.use_pet_medal_batch(1)
				if not bool(medal_res.get("success", false)):
					result.message = str(medal_res.get("message", "宠物补章失败"))
					return result
				if bool(medal_res.get("authoritative_save_applied", false)):
					result["authoritative_save_applied"] = true
					result["reward_sync_policy"] = REWARD_SYNC_NONE
				messages.append(str(medal_res.get("message", "宠物补章成功")))
			elif name == "人物升级丹":
				var game_manager = GameManager.instance
				if game_manager == null:
					result.message = "游戏管理器未初始化，请稍后再试"
					return result

				if player == null:
					result.message = "玩家数据未初始化"
					return result


				if player.level >= GameData.MAX_LEVEL_EVOLUTION:
					result.message = "您已经达到满级（1200级），无法再使用升级丹"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "该道具需联网使用，请登录后重试"
					return result
				var op_player_dan: = "consume_player_dan_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				var er_player_dan: Dictionary = await game_manager.wait_economy("economy_whitelist_item_consume", func():
					game_manager.network.economy_whitelist_item_consume(op_player_dan, "player_upgrade_dan")
				)
				if not bool(er_player_dan.get("ok", false)):
					result.message = str(er_player_dan.get("err", "升级丹消耗失败，请稍后重试"))
					return result
				var er_player_dan_data: Variant = er_player_dan.get("data", {})
				if er_player_dan_data is Dictionary and (er_player_dan_data as Dictionary).has("saveData") and (er_player_dan_data as Dictionary).get("saveData") is Dictionary:
					result["authoritative_save_applied"] = true
					result["reward_sync_policy"] = REWARD_SYNC_NONE
					var plr_upgrade: Player = player as Player
					var pts_before: int = plr_upgrade.points
					var pend_before: int = plr_upgrade.pending_auto_points
					# 服务端是「按等级补点 + 立刻 auto_allocate 到五维」，
					# 光看 points/pending 差值会是 0，提示就成了「本次新增 0 点」，
					# 玩家以为升级丹白吃了。这里把五维增量一起算进总收益。
					var attr_before: int = int(plr_upgrade.vitality) + int(plr_upgrade.magic) \
						+ int(plr_upgrade.attack_base) + int(plr_upgrade.defense_base) + int(plr_upgrade.agility_base)
					var sd_player: Dictionary = (er_player_dan_data as Dictionary).get("saveData")
					game_manager.apply_cloud_save(sd_player, {
						"preserve_local_pets_not_in_cloud": true, 
						"skip_pet_collection_trim": true, 
						"reward_inventory_slice": true, 
						"upgrade_dan_slice": true, 
					})
					game_manager.sync_player_authoritative_upgrade_dan_slice_from_dict(sd_player.get("playerData"))
					messages.append("恭喜！您已升级到 %d 级（满级）！" % int(game_manager.player.level))
					var d_pts: int = game_manager.player.points - pts_before
					var d_pend: int = game_manager.player.pending_auto_points - pend_before
					var attr_after: int = int(game_manager.player.vitality) + int(game_manager.player.magic) \
						+ int(game_manager.player.attack_base) + int(game_manager.player.defense_base) + int(game_manager.player.agility_base)
					var d_allocated: int = attr_after - attr_before
					if d_allocated > 0 or d_pend > 0 or d_pts > 0:
						var parts: Array[String] = []
						if d_allocated > 0:
							parts.append("已自动分配 %d 点" % d_allocated)
						if d_pend > 0:
							parts.append("待自动分配 %d 点" % d_pend)
						if d_pts > 0:
							parts.append("可分配 %d 点" % d_pts)
						messages.append("本次升级共获得 %d 点属性（%s）" % [d_allocated + d_pend + d_pts, "，".join(parts)])
					else:
						messages.append("当前可分配属性点 %d，待自动分配 %d" % [int(game_manager.player.points), int(game_manager.player.pending_auto_points)])
					if int(game_manager.player.cultivation) > 0:
						messages.append("当前修行值：%d" % int(game_manager.player.cultivation))
					return {"success": true, "message": "\n".join(messages), "authoritative_save_applied": true, "reward_sync_policy": REWARD_SYNC_NONE}


				result.message = "服务器返回异常，宠物升级未完成，请稍后重试。道具不会扣除。"
				return result

			elif name == "宠物升级丹":
				var game_manager = GameManager.instance
				if game_manager == null:
					result.message = "游戏管理器未初始化，请稍后再试"
					return result

				var pet_manager = game_manager.pet_manager
				if pet_manager == null:
					result.message = "宠物管理器未初始化，请稍后再试"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "该道具需联网使用，请登录后重试"
					return result
				if not bool(game_manager.is_cloud_sync_ready()):
					result.message = "出战宠物状态同步中，请稍后再试"
					return result
				pet_manager = game_manager.pet_manager
				var active_pet = pet_manager.active_pet
				if active_pet == null:
					result.message = "请先设置一只出战宠物"
					return result

				if int(active_pet.generation) >= 3 and active_pet.is_at_max_level():
					result.message = "三代满级成品宠无法使用宠物经验丹"
					return result
				if active_pet.level >= active_pet.get_effective_max_level():
					result.message = "您的出战宠物已经达到满级（%d级），无法再使用升级丹" % active_pet.get_effective_max_level()
					return result
				game_manager.sync_active_pet_roster_to_cloud()
				if not await game_manager.await_active_pet_roster_cloud_sync(15.0):
					result.message = "主战栏同步失败，请稍后重试"
					return result
				active_pet = pet_manager.active_pet
				if active_pet == null:
					result.message = "请先设置一只出战宠物"
					return result
				var target_pet_id: = str(active_pet.id)
				var old_pet_level: int = int(active_pet.level)
				var medals_before: = InventoryManager._snapshot_pet_medal_counts(active_pet)
				var op_pet_dan: = "consume_pet_dan_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				var dan_extras: = {
					"activePetId": target_pet_id, 
					"clientPetLevel": int(active_pet.level), 
				}
				var er_pet_dan: Dictionary = await game_manager.wait_economy("economy_whitelist_item_consume", func():
					game_manager.network.economy_whitelist_item_consume(op_pet_dan, "pet_upgrade_dan", 1, dan_extras)
				)
				if not bool(er_pet_dan.get("ok", false)):
					result.message = str(er_pet_dan.get("err", "升级丹消耗失败，请稍后重试"))
					return result
				var er_pet_dan_data: Variant = er_pet_dan.get("data", {})
				if er_pet_dan_data is Dictionary and (er_pet_dan_data as Dictionary).has("saveData") and (er_pet_dan_data as Dictionary).get("saveData") is Dictionary:
					result["authoritative_save_applied"] = true
					result["reward_sync_policy"] = REWARD_SYNC_NONE
					game_manager.apply_cloud_save((er_pet_dan_data as Dictionary).get("saveData"), {
						"preserve_local_pets_not_in_cloud": true, 
						"skip_pet_collection_trim": true, 
						"pets_authoritative": true, 
						"reward_inventory_slice": true, 
					})
					var synced_pet = game_manager.pet_manager.active_pet if game_manager.pet_manager else null
					if synced_pet == null or str(synced_pet.id) != target_pet_id:
						push_error("[InventoryManager] pet_upgrade_dan active pet mismatch expected=%s got=%s" % [target_pet_id, str(synced_pet.id) if synced_pet else "null"])
						result.message = "同步异常，升级结果未确认，请重新登录后查看宠物状态"
						return result
					if synced_pet.level < synced_pet.get_effective_max_level():
						push_error("[InventoryManager] pet_upgrade_dan level not max after consume id=%s level=%d" % [target_pet_id, int(synced_pet.level)])
						result.message = "同步异常，升级结果未确认，请重新登录后查看宠物状态"
						return result
					var synced_name: String = str(synced_pet.pet_name)
					var synced_level: int = int(synced_pet.level)
					var synced_reward_message: = InventoryManager._finish_pet_upgrade_dan_medal_message(game_manager.pet_manager, synced_pet, old_pet_level, medals_before)
					messages.append("恭喜！您的出战宠物【%s】已升级到 %d 级（满级）！" % [synced_name, synced_level])
					messages.append("最终成长：%.3f" % float(synced_pet.total_growth))
					if not synced_reward_message.is_empty():
						messages.append(synced_reward_message)
					var learned_dan: Variant = (er_pet_dan_data as Dictionary).get("learnedSkill", null)
					if learned_dan is Dictionary and not (learned_dan as Dictionary).is_empty():
						var learn_name: = str((learned_dan as Dictionary).get("skill_name", (learned_dan as Dictionary).get("skillName", "新技能"))).strip_edges()
						if learn_name.is_empty():
							learn_name = "新技能"
						var learn_lv: = maxi(1, int((learned_dan as Dictionary).get("level", 1)))
						messages.append("宠物领悟了【%slv%d】！" % [learn_name, learn_lv])
						if game_manager.has_method("notify_pet_max_level_skill_learned"):
							game_manager.notify_pet_max_level_skill_learned(learned_dan)
					return {"success": true, "message": "\n".join(messages), "authoritative_save_applied": true, "reward_sync_policy": REWARD_SYNC_NONE}


				var target_level = active_pet.get_effective_max_level()
				var levels_to_gain = target_level - active_pet.level
				var old_level = active_pet.level
				var medals_before_local: = InventoryManager._snapshot_pet_medal_counts(active_pet)


				for i in range(levels_to_gain):
					active_pet.level += 1

					var total_change = pet_manager._roll_level_growth_delta_for_pet(active_pet)

					for stat in ["attack", "defense", "agility"]:
						var stat_change = total_change * (active_pet.stat_ratio.get(stat, 33.33) / 100.0)
						active_pet.growth_rates[stat] = snapped(active_pet.growth_rates[stat] + stat_change, 0.001)

					active_pet.attack = snapped(active_pet.base_stats.attack + (active_pet.level - 1) * active_pet.growth_rates.attack, 0.01)
					active_pet.defense = snapped(active_pet.base_stats.defense + (active_pet.level - 1) * active_pet.growth_rates.defense, 0.01)
					active_pet.agility = snapped(active_pet.base_stats.agility + (active_pet.level - 1) * active_pet.growth_rates.agility, 0.01)

					active_pet.total_growth = snapped(active_pet.growth_rates.attack + active_pet.growth_rates.defense + active_pet.growth_rates.agility, 0.001)
					# 生命成长走物种 hp_growth（参考稿口径）
					active_pet.growth_rates["hp"] = PetClass.resolve_hp_growth(str(active_pet.pet_id), active_pet.total_growth)
					active_pet.max_hp = snapped(active_pet.base_stats.hp + (active_pet.level - 1) * float(active_pet.growth_rates["hp"]), 0.01)
					active_pet.hp = active_pet.max_hp

					active_pet.level_up.emit(active_pet.level)


				active_pet.experience = 0
				var max_level_reward_message: String = InventoryManager._finish_pet_upgrade_dan_medal_message(pet_manager, active_pet, old_level, medals_before_local)

				var pet_type_desc = "可进化" if active_pet.is_evolution_pet else "不可进化"
				messages.append("恭喜！您的出战宠物【%s】已升级到 %d 级（满级）！" % [active_pet.pet_name, active_pet.level])
				messages.append("宠物类型：%s" % pet_type_desc)
				messages.append("最终成长：%.3f" % active_pet.total_growth)
				if not max_level_reward_message.is_empty():
					messages.append(max_level_reward_message)
			elif name == "测试礼包":
				var game_manager = GameManager.instance
				if game_manager == null:
					result.message = "游戏管理器未初始化，请稍后再试"
					return result
				var inv_manager = game_manager.inventory_manager
				if inv_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				var gift_result = await inv_manager.open_test_gift(player, game_manager)
				if gift_result.success:
					count -= 1
				return gift_result
			elif name == "开荒宠装礼包" or name == "测试宠物装备礼包":
				var game_manager = GameManager.instance
				if game_manager == null:
					result.message = "游戏管理器未初始化，请稍后再试"
					return result
				var inv_manager = game_manager.inventory_manager
				if inv_manager == null:
					result.message = "背包管理器未初始化，请稍后再试"
					return result
				if game_manager.network == null or not game_manager.network.is_logged_in():
					result.message = "该礼包包含高价值宠装，需联网使用，请登录后重试"
					return result
				if inv_manager.pet_equipment_items.size() + 5 > inv_manager.MAX_PET_EQUIPMENT_INVENTORY:
					result.message = "宠物装备背包空间不足！开启需要5个空位（当前%d/%d）" % [inv_manager.pet_equipment_items.size(), inv_manager.MAX_PET_EQUIPMENT_INVENTORY]
					return result
				# 注意：GDScript 的 lambda 是按值捕获局部变量的 —— 这里必须用 Dictionary
				# 存状态。原来写成 `var done := false` + `done = true`，闭包改的是自己的副本，
				# 外层 while 永远等不满，只能靠 90s 超时兜底，这就是「使用失败要等很久」。
				var st: = {"done": false, "ok": false, "message": "", "granted": []}
				var on_success = func(data: Dictionary):
					if bool(st.done):
						return
					st.done = true
					# 业务失败（success=false）也走 success 信号 → 先把真实原因抛出去
					if data.get("success") == false:
						st.ok = false
						st.message = str(data.get("message", "宠装礼包开启失败"))
						return
					st.ok = true
					var granted_rows: Array = data.get("grantedItems", []) if data.get("grantedItems") is Array else []
					st.granted = granted_rows
					var dup: = bool(data.get("duplicate", false))
					st.message = str(data.get("message", "宠装礼包发放成功"))
					if not dup and data.has("saveData") and data.get("saveData") is Dictionary:
						game_manager.apply_cloud_save(data.get("saveData"), {
							"reward_inventory_slice": true, 
							"authoritative_equipment_inventory": true, 
						})
					elif dup:
						if game_manager:
							game_manager.call_deferred("download_cloud_save")
					else:
						st.ok = false
						st.message = "服务器没有返回权威存档，本次开启未生效，请稍后重试"
				var on_failed = func(error: String):
					if bool(st.done):
						return
					st.done = true
					st.ok = false
					st.message = error
				var nw: Node = game_manager.network
				# 幂等用的 operationId（原来这里直接引用了不存在的 op_id，整个脚本解析就报
				# Parse Error: Identifier "op_id" not declared —— 编译都过不去）
				var pet_equip_op_id: = "pet_equipment_grant_%d_%s" % [Time.get_ticks_usec(), str(randi())]
				nw.pet_equipment_grant_success.connect(on_success, CONNECT_ONE_SHOT)
				nw.pet_equipment_grant_failed.connect(on_failed, CONNECT_ONE_SHOT)
				nw.request_pet_equipment_grant("gift", str(name), 5, pet_equip_op_id)
				var grant_deadline_ms: int = Time.get_ticks_msec() + 15000
				while not bool(st.done) and Time.get_ticks_msec() < grant_deadline_ms:
					await game_manager.get_tree().process_frame
				if nw.pet_equipment_grant_success.is_connected(on_success):
					nw.pet_equipment_grant_success.disconnect(on_success)
				if nw.pet_equipment_grant_failed.is_connected(on_failed):
					nw.pet_equipment_grant_failed.disconnect(on_failed)
				if not bool(st.done):
					result.message = "网络超时，礼包未扣除。请检查网络后重试。"
					return result
				if not bool(st.ok):
					result.message = str(st.message if st.message != "" else "宠装礼包开启失败，请稍后重试")
					return result
				var granted_msgs: Array = []
				for row in st.granted:
					if row is Dictionary:
						granted_msgs.append("获得【%s】" % str(row.get("name", "宠装")))
				if granted_msgs.is_empty():
					granted_msgs.append(str(st.message))
				var grant_result: Dictionary = {
					"success": true, 
					"message": "\n".join(granted_msgs), 
					"authoritative_save_applied": true, 
					"reward_sync_policy": REWARD_SYNC_NONE, 
				}
				count -= 1
				return grant_result
			elif FestivalGiftManager.is_festival_gift(str(name)):
				var festival_result: Dictionary = await FestivalGiftManager.use_festival_gift_single(str(name))
				if not bool(festival_result.get("success", false)):
					result.message = str(festival_result.get("message", "节日礼包开启失败"))
					return result
				if festival_result.has("authoritative_save_applied"):
					result["authoritative_save_applied"] = festival_result.get("authoritative_save_applied")
				if festival_result.has("reward_sync_policy"):
					result["reward_sync_policy"] = festival_result.get("reward_sync_policy")
				messages.append(str(festival_result.get("message", "节日礼包开启成功")))
				if bool(festival_result.get("show_dialog", false)):
					result.show_dialog = true
					result.dialog_title = str(festival_result.get("dialog_title", "礼包开启成功"))
					result.dialog_message = str(festival_result.get("dialog_message", festival_result.get("message", "")))
			elif InventoryManager.is_server_auth_pet_gift_name(str(name).strip_edges()):
				var gift_name_s: = str(name).strip_edges()
				var auth_extra_payload: Dictionary = {}
				if gift_name_s.begins_with("仙魔"):
					var item_custom: Dictionary = custom_data if custom_data is Dictionary else {}
					if item_custom.has("xianmo_gift_growth"):
						auth_extra_payload["xianmo_gift_growth"] = float(item_custom.get("xianmo_gift_growth", 0.0))
				return await _request_server_auth_pet_reward_open("gift", gift_name_s, auth_extra_payload)
			else:
				result.message = "未知的礼包类型"
				return result

		elif item_type == "pet_egg":
			var game_manager = GameManager.instance
			if game_manager == null:
				result.message = "游戏管理器未初始化，请稍后再试"
				return result

			var pet_manager = game_manager.pet_manager
			if pet_manager == null:
				result.message = "宠物管理器未初始化，请稍后再试"
				return result

			var egg_name_s: = str(name).strip_edges()
			if InventoryManager.is_server_auth_pet_egg_name(egg_name_s):
				return await _request_server_auth_pet_reward_open("egg", egg_name_s)
			else:
				result.message = "未知的宠物蛋类型"
				return result

		if not bool(result.get("authoritative_save_applied", false)):
			count -= 1
		result.success = true
		result.message = "、".join(messages)
		return result

	func _request_server_auth_pet_reward_open(kind: String, reward_name: String, extra_payload: Dictionary = {}) -> Dictionary:
		var result: = {"success": false, "message": "", "meta": {}}
		var gm = GameManager.instance
		if gm == null:
			result.message = "游戏管理器未初始化，请稍后再试"
			return result
		if gm.network == null or not gm.network.is_logged_in():
			if kind == "egg":
				result.message = "该宠物蛋需要联网并由服务器权威孵化，当前未登录或网络不可用。"
			else:
				result.message = "该礼包的宠物奖励需要联网并由服务器确认，当前未登录或网络不可用。"
			return result
		var request_result: = await _await_server_auth_pet_reward_open(gm, kind, reward_name, extra_payload)
		if bool(request_result.get("request_started", false)):
			return request_result
		result.message = str(request_result.get("message", "服务器接口暂未开放"))
		result.meta = request_result.get("meta", {})
		return result

	func _await_server_auth_pet_reward_open(gm, kind: String, reward_name: String, extra_payload: Dictionary = {}) -> Dictionary:
		var result: = {
			"success": false, 
			"request_started": false, 
			"message": "", 
			"meta": {
				"phase2_blocked": true, 
				"kind": kind, 
				"reward_name": reward_name
			}
		}
		if gm == null or gm.network == null:
			result.message = "网络模块未初始化"
			return result
		var network = gm.network
		var reward_name_s: = str(reward_name).strip_edges()
		var op_id: = "pet_reward_open_%s_%d_%d_%d_%s" % [kind, Time.get_unix_time_from_system(), Time.get_ticks_msec(), Time.get_ticks_usec(), str(randi())]
		result.request_started = true
		var payload: Dictionary = InventoryManager.sanitize_pet_batch_extra_payload(extra_payload.duplicate(true))
		if kind == "egg":
			result.meta["expected_server_api"] = "/pet/open-egg"
			result.meta["egg_name"] = reward_name
			if not network.has_method("request_pet_egg_open"):
				result.request_started = false
				result.message = "客户端尚未集成宠物蛋服务端接口"
				return result
		else:
			result.meta["expected_server_api"] = "/gift/open-pet"
			result.meta["gift_name"] = reward_name
			if not network.has_method("request_pet_gift_open"):
				result.request_started = false
				result.message = "客户端尚未集成发宠礼包服务端接口"
				return result
		var state: = {"done": false, "ok": false, "message": "", "data": {}}
		var pets_before: Dictionary = {}
		var inventory_before: Dictionary = {}
		if gm.pet_manager:
			for pet_inst in gm.pet_manager.pets:
				if pet_inst:
					pets_before[str(pet_inst.id)] = {
						"name": str(pet_inst.pet_name), 
						"growth": float(pet_inst.total_growth), 
						"level": int(pet_inst.level), 
						"generation": int(pet_inst.generation)
					}
			for pet_inst in gm.pet_manager.pet_bag:
				if pet_inst:
					pets_before[str(pet_inst.id)] = {
						"name": str(pet_inst.pet_name), 
						"growth": float(pet_inst.total_growth), 
						"level": int(pet_inst.level), 
						"generation": int(pet_inst.generation)
					}
		if gm.inventory_manager:
			for inv_item in gm.inventory_manager.items:
				if inv_item:
					inventory_before[str(inv_item.id)] = int(inv_item.count)
		var on_success = func(data: Dictionary):
			state.done = true
			state.ok = true
			state.data = data if data is Dictionary else {}
			state.message = str(state.data.get("message", "操作成功"))
		var on_failed = func(error: String):
			state.done = true
			state.ok = false
			state.message = error
		gm._suppress_general_cloud_upload_until_ms = maxi(gm._suppress_general_cloud_upload_until_ms, Time.get_ticks_msec() + 6000)
		if kind == "egg":
			network.pet_egg_open_success.connect(on_success, CONNECT_ONE_SHOT)
			network.pet_egg_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
			network.request_pet_egg_open(reward_name_s, op_id, payload)
		else:
			network.pet_gift_open_success.connect(on_success, CONNECT_ONE_SHOT)
			network.pet_gift_open_failed.connect(on_failed, CONNECT_ONE_SHOT)
			network.request_pet_gift_open(reward_name_s, op_id, payload)
		var deadline: = Time.get_ticks_msec() + 20000
		while not bool(state.done) and Time.get_ticks_msec() < deadline and gm.is_inside_tree():
			await gm.get_tree().process_frame
		if kind == "egg":
			if network.pet_egg_open_success.is_connected(on_success):
				network.pet_egg_open_success.disconnect(on_success)
			if network.pet_egg_open_failed.is_connected(on_failed):
				network.pet_egg_open_failed.disconnect(on_failed)
		else:
			if network.pet_gift_open_success.is_connected(on_success):
				network.pet_gift_open_success.disconnect(on_success)
			if network.pet_gift_open_failed.is_connected(on_failed):
				network.pet_gift_open_failed.disconnect(on_failed)
		if not bool(state.done):
			var inv_mgr_timeout: InventoryManager = gm.inventory_manager as InventoryManager if gm.inventory_manager != null else null
			if inv_mgr_timeout != null:
				var downloaded_timeout: Dictionary = await inv_mgr_timeout._await_cloud_save_download(gm)
				if not downloaded_timeout.is_empty():
					state.done = true
					state.ok = true
					state.data = {
						"saveData": downloaded_timeout, 
						"result": {}, 
						"message": "开包请求可能已完成，已从云端同步最新数据。", 
					}
					state.message = str(state.data.get("message", ""))
				else:
					result.request_started = false
					result.message = "开包请求可能已完成，但云端同步失败，请稍后重新登录查看。"
					return result
			else:
				result.request_started = false
				result.message = "开包请求可能已完成，正在同步云端数据…请稍后重新登录查看。"
				if gm.has_method("download_cloud_save"):
					gm.call_deferred("download_cloud_save")
				return result
		if not bool(state.ok):
			result.request_started = false
			result.message = str(state.message)
			return result
		var response_data: Dictionary = state.data if state.data is Dictionary else {}
		if bool(response_data.get("duplicate", false)):
			var _has_auth_save: = response_data.has("saveData") and response_data.get("saveData") is Dictionary
			if not _has_auth_save:
				var inv_mgr_dup: InventoryManager = gm.inventory_manager as InventoryManager if gm.inventory_manager != null else null
				if inv_mgr_dup != null:
					var downloaded_dup: Dictionary = await inv_mgr_dup._await_cloud_save_download(gm)
					if not downloaded_dup.is_empty():
						response_data = {
							"duplicate": true, 
							"saveData": downloaded_dup, 
							"result": response_data.get("result", {}) if response_data.get("result") is Dictionary else {}, 
							"message": "重复请求已从云端同步最新数据。", 
						}
					else:
						result.request_started = false
						result.success = false
						result.message = "服务器判定为重复请求，云端同步失败，请重新登录后再查看背包与宠物。"
						return result
				else:
					result.request_started = false
					result.success = false
					result.message = "服务器判定为重复请求（operationId 已处理），未附带最新存档。请重新登录或同步云端后再查看背包与宠物。"
					if gm.has_method("download_cloud_save"):
						gm.call_deferred("download_cloud_save")
					return result
		var reward_result_for_apply: Dictionary = response_data.get("result", {}) if response_data.get("result") is Dictionary else {}
		var authoritative_save_applied: = false
		if response_data.has("saveData") and response_data.get("saveData") is Dictionary:
			InventoryManager.apply_server_auth_pet_reward_save(gm, response_data.get("saveData"), reward_result_for_apply)
			authoritative_save_applied = true
		var opened_pets: Array = []
		if response_data.has("result") and response_data.get("result") is Dictionary:
			var reward_result: Dictionary = response_data.get("result")
			var granted_pets = reward_result.get("grantedPets", [])
			if granted_pets is Array:
				for pet_info in granted_pets:
					if pet_info is Dictionary:
						opened_pets.append(InventoryManager._opened_pet_entry_from_dict(pet_info))
		if opened_pets.is_empty() and gm.pet_manager:
			for pet_inst in gm.pet_manager.pets:
				if pet_inst == null:
					continue
				var pet_id: = str(pet_inst.id)
				if pets_before.has(pet_id):
					continue
				opened_pets.append(InventoryManager._opened_pet_entry_from_instance(pet_inst))
		var reward_lines: Array[String] = []
		var opened_label: = "宠物蛋孵化成功" if kind == "egg" else "礼包开启成功"
		var reward_result: Dictionary = response_data.get("result", {}) if response_data.get("result") is Dictionary else {}
		var granted_gold: = int(reward_result.get("grantedGold", 0))
		if granted_gold > 0:
			reward_lines.append("获得金币：%s" % _format_reward_gold(granted_gold))
		var granted_items = reward_result.get("grantedItems", [])
		if granted_items is Array:
			for granted_item in granted_items:
				if granted_item is Dictionary:
					var item_name: = str(granted_item.get("name", "")).strip_edges()
					if item_name != "":
						reward_lines.append("获得【%s】" % item_name)
		if not opened_pets.is_empty():
			for pet_info in opened_pets:
				var pet_name: = InventoryManager.format_pet_name_with_mutation_from_info(pet_info)
				var pet_growth: = float(pet_info.get("growth", 0.0))
				var mailed: = bool(pet_info.get("mailed", false))
				var line: = "获得【%s】" % pet_name
				if pet_growth > 0.0:
					line += "（成长%.3f）" % pet_growth
				if mailed:
					line += "，已发送到邮件"
				reward_lines.append(line)
		var authoritative_message: = str(state.message).strip_edges()
		if reward_lines.is_empty() and not authoritative_message.is_empty():
			reward_lines.append(authoritative_message)
		InventoryManager.emit_server_auth_pet_reward_broadcast(kind, reward_name, response_data, opened_pets, 0)
		result.success = true
		result.message = "\n".join(reward_lines) if not reward_lines.is_empty() else authoritative_message
		result.data = response_data
		result["authoritative_save_applied"] = authoritative_save_applied
		result["reward_sync_policy"] = REWARD_SYNC_NONE if bool(result.get("authoritative_save_applied", false)) else REWARD_SYNC_LOCAL_SAVE
		if bool(result.get("authoritative_save_applied", false)):
			InventoryManager.mark_server_authority_use_result(result)
		result["show_dialog"] = true
		result["dialog_title"] = opened_label
		result["dialog_message"] = result.message if str(result.message).strip_edges() != "" else authoritative_message
		return result

	func _format_reward_gold(amount: int) -> String:
		var value: = maxi(0, int(amount))
		if value >= 100000000 and value % 100000000 == 0:
			return "%d亿" % (value / 100000000)
		if value >= 10000 and value % 10000 == 0:
			return "%d万" % (value / 10000)
		return str(value)

	func _open_evolution_pet_gift(gift_name: String) -> Dictionary:
		var result = {"success": false, "message": "", "sent_to_mail": false, "pet_name": "", "growth": 0.0}
		var authority_owner = GameManager.instance.inventory_manager if GameManager.instance else null
		var guard: Dictionary = authority_owner._reject_legacy_local_pet_authority("可进化宠礼包本地开宠") if authority_owner != null else {"success": false, "message": "背包管理器未初始化"}
		if not bool(guard.get("success", false)):
			result.message = str(guard.get("message", "该礼包已切换为服务端权威"))
			return result
		var gm = GameManager.instance
		if gm == null or gm.pet_manager == null:
			result.message = "宠物系统未初始化"
			return result
		var pet_manager = gm.pet_manager
		var growth_range = _get_evo_gift_growth_range(gift_name)
		var growth = snapped(growth_range.min + randf() * (growth_range.max - growth_range.min), 0.001)
		var rare_ids = ["shuijinger", "mengjinger", "a_di_da_si"]
		rare_ids = rare_ids.filter( func(pid): return not pet_manager.is_event_limited_pet_id(str(pid)))
		var normal_ids: Array = []
		for origin_id in EvolutionData.EVOLUTION_DATA.keys():
			if pet_manager.is_event_limited_pet_id(str(origin_id)):
				continue
			if not rare_ids.has(origin_id):
				normal_ids.append(origin_id)
		var selected_pet_id = ""
		if randf() < 0.01:
			if rare_ids.is_empty():
				result.message = "礼包奖池配置异常：稀有宠物池为空"
				return result
			selected_pet_id = rare_ids[randi() % rare_ids.size()]
		elif normal_ids.size() > 0:
			selected_pet_id = normal_ids[randi() % normal_ids.size()]
		else:
			if rare_ids.is_empty():
				result.message = "礼包奖池配置异常：候选宠物池为空"
				return result
			selected_pet_id = rare_ids[randi() % rare_ids.size()]
		var pet_data = GameData.PET_DATA.get(selected_pet_id, {})
		var pet_name = pet_data.get("name", selected_pet_id)
		var pet_result = pet_manager.create_pet_from_tower(selected_pet_id, pet_name, growth)
		result.success = bool(pet_result.get("success", false) or pet_result.get("sent_to_mail", false))
		result.sent_to_mail = bool(pet_result.get("sent_to_mail", false))
		result.pet_name = pet_name
		result.growth = growth
		result.message = "打开%s获得【%s】（成长%.3f）" % [gift_name, pet_name, growth]
		if not result.success:
			result.message = pet_result.get("message", "礼包开启失败")
		return result

	func _open_fixed_pet_gift(gift_name: String) -> Dictionary:
		var result = {"success": false, "message": "", "sent_to_mail": false, "pet_name": "", "growth": 0.0}
		var authority_owner = GameManager.instance.inventory_manager if GameManager.instance else null
		var guard: Dictionary = authority_owner._reject_legacy_local_pet_authority("固定宠礼包本地开宠") if authority_owner != null else {"success": false, "message": "背包管理器未初始化"}
		if not bool(guard.get("success", false)):
			result.message = str(guard.get("message", "该礼包已切换为服务端权威"))
			return result
		var gm = GameManager.instance
		if gm == null or gm.pet_manager == null:
			result.message = "宠物系统未初始化"
			return result
		var gift_pet_map = {
			"7-9水晶儿礼包": "shuijinger", 
			"7-9梦晶儿礼包": "mengjinger", 
			"7-9阿弟达斯礼包": "a_di_da_si"
		}
		var pet_id = gift_pet_map.get(gift_name, "")
		if pet_id.is_empty():
			result.message = "未知礼包类型"
			return result
		var growth = snapped(7.0 + randf() * 2.9, 0.001)
		var pet_data = GameData.PET_DATA.get(pet_id, {})
		var pet_name = pet_data.get("name", pet_id)
		var pet_result = gm.pet_manager.create_pet_from_tower(pet_id, pet_name, growth)
		result.success = bool(pet_result.get("success", false) or pet_result.get("sent_to_mail", false))
		result.sent_to_mail = bool(pet_result.get("sent_to_mail", false))
		result.pet_name = pet_name
		result.growth = growth
		result.message = "打开%s获得【%s】（成长%.3f）" % [gift_name, pet_name, growth]
		if not result.success:
			result.message = pet_result.get("message", "礼包开启失败")
		return result

	func _broadcast_lucky_draw_gift_high_growth(pet_name: String, growth: float) -> void :
		var game_manager = GameManager.instance
		if game_manager == null:
			return
		if game_manager.player == null:
			return
		if pet_name.is_empty():
			return
		game_manager.broadcast_event("pet_egg_high_growth", game_manager.player.player_name, {
			"pet_name": pet_name, 
			"growth": growth, 
			"egg_source": "幸运抽奖（宠物蛋）"
		})

	func _get_evo_gift_growth_range(gift_name: String) -> Dictionary:
		match gift_name:
			"6+可进化宠礼包":
				return {"min": 6.0, "max": 6.9}
			"7+可进化宠礼包":
				return {"min": 7.0, "max": 7.3}
			"8+可进化宠礼包":
				return {"min": 8.0, "max": 8.9}
			"9+可进化宠礼包":
				return {"min": 9.0, "max": 9.9}
			"10+可进化宠礼包":
				return {"min": 10.0, "max": 10.9}
			"11+可进化宠礼包":
				return {"min": 11.0, "max": 11.9}
			"12+可进化宠礼包":
				return {"min": 12.0, "max": 12.99}
			"13+可进化宠礼包":
				return {"min": 13.0, "max": 13.99}
			"10-13变异可进化宠礼包":
				return {"min": 10.0, "max": 13.99}
			_:
				return {"min": 6.0, "max": 6.9}

	func _open_pet_egg(pet_manager, target_element: String) -> Dictionary:
		var result = {"success": false, "message": "", "pet_name": "", "growth": 0.0, "sent_to_mail": false}
		var authority_owner = GameManager.instance.inventory_manager if GameManager.instance else null
		var guard: Dictionary = authority_owner._reject_legacy_local_pet_authority("宠物蛋本地孵化") if authority_owner != null else {"success": false, "message": "背包管理器未初始化"}
		if not bool(guard.get("success", false)):
			result.message = str(guard.get("message", "宠物蛋已切换为服务端权威"))
			return result

		var roll_pet = pet_manager.roll_pet_id_from_refine_pools(target_element)
		var selected_id = roll_pet.get("pet_id", "")
		if selected_id == "":
			result.message = "没有找到%s属性的宠物或宠物池配置异常" % target_element
			return result

		var pet_data = GameData.PET_DATA.get(selected_id, {})
		var pet_name = pet_data.get("name", "未知宠物")

		var growth: float
		if str(target_element).strip_edges().is_empty():
			growth = snapped(5.0 + randf() * 1.0, 0.001)
		else:
			growth = snapped(4.0 + randf() * 3.0, 0.001)

		var pet_result = pet_manager.create_pet_from_tower(selected_id, pet_name, growth)

		result.success = pet_result.success
		result.sent_to_mail = pet_result.sent_to_mail
		result.message = pet_result.message
		result.pet_name = pet_name
		result.growth = growth
		return result

	func to_dict() -> Dictionary:
		return {
			"id": id, 
			"name": name, 
			"item_type": item_type, 
			"count": count, 
			"custom_data": custom_data if custom_data is Dictionary else {}
		}

	static func from_dict(data: Dictionary):
		var item_type = data.get("item_type", "material")
		var custom_data = data.get("custom_data", {})
		if not (custom_data is Dictionary):
			custom_data = {}

		if item_type == "limit_equip":
			item_type = "material"
			custom_data["is_limit_equip"] = true
		elif item_type == "herb":
			item_type = "material"

		var item_name = str(data.get("name", ""))
		if item_type != "sealed_suit" and not custom_data.get("is_limit_equip", false):
			var item_cfg = GameData.ALL_ITEMS.get(item_name, null)
			if item_cfg is Dictionary:
				item_type = str(item_cfg.get("type", item_type))
		if item_type == "herb":
			item_type = "material"

		var item = InventoryItem.new(
			item_name, 
			item_type, 
			data.get("count", 1)
		)
		item.custom_data = custom_data
		var raw_id: Variant = data.get("id", null)
		var sid: = ""
		if raw_id != null:
			sid = str(raw_id).strip_edges()
		if sid.is_empty() or sid == "null":
			if not custom_data.has("_inv_inst_id"):
				custom_data["_inv_inst_id"] = item._generate_id()
			sid = str(custom_data["_inv_inst_id"]).strip_edges()
		if sid.is_empty():
			sid = item.id
		item.id = sid
		item.custom_data = custom_data
		return item



func _reject_local_authority_mutation_when_online(action_name: String) -> Dictionary:
	if GameManager.instance != null and GameManager.instance.has_method("local_use_item"):
		return {"success": true, "message": "本地测试"}
	var result: = {"success": false, "message": ""}
	var game_manager = GameManager.instance
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "请先登录账号后再进行此操作。"
		return result
	result.message = "%s已切换为服务端权威，在线状态下禁止走本地旧逻辑。" % action_name
	push_warning("[AuthorityGuard] %s" % result.message)
	return result

func _reject_legacy_local_pet_authority(action_name: String) -> Dictionary:
	if GameManager.instance != null and GameManager.instance.has_method("local_use_item"):
		return {"success": true, "message": "本地测试"}
	var online_guard: = _reject_local_authority_mutation_when_online(action_name)
	if not bool(online_guard.get("success", false)):
		return online_guard
	if not OS.is_debug_build():
		var result: = {"success": false, "message": "%s旧本地逻辑仅允许调试环境使用，正式环境已禁用。" % action_name}
		push_warning("[AuthorityGuard] %s" % result.message)
		return result
	return {"success": true, "message": ""}

func move_to_warehouse(item_id: String, count: int = -1) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("普通道具存仓")
	if not bool(guard.get("success", false)):
		return guard

	var item = get_item_by_id(item_id)
	if item == null:
		result.message = "物品不存在"
		return result

	var move_count = count if count > 0 else item.count
	move_count = min(move_count, item.count)
	if item.item_type == "sealed_suit":
		move_count = 1

	if warehouse_items.size() >= MAX_WAREHOUSE_SIZE:
		result.message = "仓库已满！"
		return result


	if not _is_non_stackable_item_instance(item.name, item.item_type):
		for w_item in warehouse_items:
			if w_item.name == item.name and not _is_non_stackable_item_instance(w_item.name, w_item.item_type):
				var old_count = w_item.count
				w_item.count = min(w_item.count + move_count, MAX_STACK_SIZE)
				var added = w_item.count - old_count

				if item.count <= added:
					items.erase(item)
				else:
					item.count -= added

				result.success = true
				result.message = "已将 %s x%d 存入仓库" % [item.name, added]
				inventory_changed.emit()
				warehouse_changed.emit()
				return result

	var new_item = InventoryItem.new(item.name, item.item_type, move_count)
	new_item.custom_data = item.custom_data.duplicate()
	warehouse_items.append(new_item)

	if item.count <= move_count:
		items.erase(item)
	else:
		item.count -= move_count

	result.success = true
	result.message = "已将 %s x%d 存入仓库" % [item.name, move_count]
	inventory_changed.emit()
	warehouse_changed.emit()
	return result

func move_from_warehouse(item_id: String, count: int = -1) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("普通道具取仓")
	if not bool(guard.get("success", false)):
		return guard

	var item = _get_warehouse_item_by_id(item_id)
	if item == null:
		result.message = "仓库中不存在该物品"
		return result

	var move_count = count if count > 0 else item.count
	move_count = min(move_count, item.count)
	if item.item_type == "sealed_suit":
		move_count = 1


	if not _is_non_stackable_item_instance(item.name, item.item_type):
		for b_item in items:
			if b_item.name == item.name and not _is_non_stackable_item_instance(b_item.name, b_item.item_type):
				var old_count = b_item.count
				b_item.count = min(b_item.count + move_count, MAX_STACK_SIZE)
				var added = b_item.count - old_count

				if item.count <= added:
					warehouse_items.erase(item)
				else:
					item.count -= added

				result.success = true
				result.message = "已从仓库取出 %s x%d" % [item.name, added]
				inventory_changed.emit()
				warehouse_changed.emit()
				return result
	var target_category = resolve_bag_category(item.name, item.item_type, item.custom_data)
	if get_available_space_by_category(target_category) <= 0:
		result.message = "道具背包已满！" if target_category == "item" else "材料背包已满！"
		return result

	var new_item = InventoryItem.new(item.name, item.item_type, move_count)
	new_item.custom_data = item.custom_data.duplicate()
	items.append(new_item)

	if item.count <= move_count:
		warehouse_items.erase(item)
	else:
		item.count -= move_count

	result.success = true
	result.message = "已从仓库取出 %s x%d" % [item.name, move_count]
	inventory_changed.emit()
	warehouse_changed.emit()
	return result

func get_warehouse_item_by_id(item_id: String):
	return _get_warehouse_item_by_id(item_id)

func _get_warehouse_item_by_id(item_id: String):
	for item in warehouse_items:
		if item.id == item_id:
			return item
	return null

func get_warehouse_item_count(item_name: String) -> int:
	for item in warehouse_items:
		if item.name == item_name:
			return item.count
	return 0

func get_warehouse_items_by_type(item_type: String) -> Array:
	var result = []
	for item in warehouse_items:
		if item.item_type == item_type:
			result.append(item)
	return result

func get_warehouse_total_count() -> int:
	var total = 0
	for item in warehouse_items:
		total += item.count
	return total


var equipment_warehouse: Array = []
const MAX_EQUIPMENT_WAREHOUSE_SIZE = 100
signal equipment_warehouse_changed

func store_equipment_to_warehouse(equipment) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("人物装备存仓")
	if not bool(guard.get("success", false)):
		return guard

	if equipment_warehouse.size() >= MAX_EQUIPMENT_WAREHOUSE_SIZE:
		result.message = "装备仓库已满！"
		return result

	var equip_data = {
		"id": equipment.id, 
		"name": equipment.name, 
		"slot": equipment.slot, 
		"rarity": equipment.rarity, 
		"attack": equipment.attack, 
		"defense": equipment.defense, 
		"hp": equipment.hp, 
		"mp": equipment.mp, 
		"agility": equipment.agility, 
		"cultivation_req": equipment.cultivation_req, 
		"locked": equipment.locked, 
		"is_suit": equipment.is_suit if "is_suit" in equipment else false, 
		"suit_id": equipment.suit_id if "suit_id" in equipment else 0, 
		"suit_slot": equipment.suit_slot if "suit_slot" in equipment else "", 
		"is_sealed": equipment.is_sealed if "is_sealed" in equipment else false, 
		"sealed_data": equipment.sealed_data if "sealed_data" in equipment else {}
	}
	equipment_warehouse.append(equip_data)
	equipment_warehouse_changed.emit()

	result.success = true
	result.message = "已将 %s 存入装备仓库" % equipment.name
	return result

func retrieve_equipment_from_warehouse(equip_id: String) -> Dictionary:
	var result = {"success": false, "message": "", "equipment": null}
	var guard: = _reject_local_authority_mutation_when_online("人物装备取仓")
	if not bool(guard.get("success", false)):
		return guard

	for i in range(equipment_warehouse.size()):
		var equip_data = equipment_warehouse[i]
		if equip_data.id == equip_id:
			result.equipment = equip_data
			result.success = true
			result.message = "已从仓库取出 %s" % equip_data.name
			equipment_warehouse.remove_at(i)
			equipment_warehouse_changed.emit()
			return result

	result.message = "装备不存在"
	return result

func get_equipment_warehouse() -> Array:
	return equipment_warehouse.duplicate()

func open_xianmo_chest(chest_type: String, game_manager) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"equipment": null
	}

	if not has_xianmo_chest(chest_type):
		result.message = "没有%s宝箱" % _get_chest_name(chest_type)
		return result

	if pet_equipment_items.size() >= MAX_PET_EQUIPMENT_INVENTORY:
		result.message = "宠物装备背包已满！"
		return result

	if not game_manager or not game_manager.equipment_manager:
		result.message = "系统错误"
		return result

	remove_xianmo_chest(chest_type)

	var gen_result = game_manager.equipment_manager.generate_xianmo_chest_equipment(chest_type)
	if not gen_result.success:
		result.message = gen_result.message
		return result

	var add_result = add_pet_equipment(gen_result.equipment)
	if not add_result.success:
		add_xianmo_chest(chest_type, 1)
		result.message = add_result.message
		return result

	result.success = true
	result.message = gen_result.message
	result.equipment = gen_result.equipment
	return result

func _get_chest_name(chest_type: String) -> String:
	match chest_type:
		"bronze": return "青铜"
		"silver": return "白银"
		"gold": return "黄金"
		_: return "未知"

func _ensure_pet_equipment_suffix(name: String) -> String:
	var n: = String(name).strip_edges()
	if n.is_empty():
		return "未知宠物装备（宠）"
	if n.ends_with("（宠）"):
		return n
	return n + "（宠）"

func _normalize_pet_equipment_name_fields(equip_dict: Dictionary) -> void :
	var normalized: = _ensure_pet_equipment_suffix(str(equip_dict.get("name", equip_dict.get("equip_name", ""))))
	equip_dict["name"] = normalized
	equip_dict["equip_name"] = normalized

func _normalize_pet_equipment_array_names(arr: Array) -> void :
	for i in range(arr.size()):
		var entry = arr[i]
		if entry is Dictionary:
			var d: Dictionary = (entry as Dictionary).duplicate()
			_normalize_pet_equipment_name_fields(d)
			arr[i] = d

func add_pet_equipment(equipment_data) -> Dictionary:
	var result = {"success": false, "message": ""}

	if pet_equipment_items.size() >= MAX_PET_EQUIPMENT_INVENTORY:
		result.message = "宠物装备背包已满！"
		return result

	var equip_dict: Dictionary

	if equipment_data is Dictionary:
		equip_dict = equipment_data.duplicate()
		if equip_dict.has("equip_id") and not equip_dict.has("id"):
			equip_dict["id"] = equip_dict["equip_id"]
		if equip_dict.has("equip_name") and not equip_dict.has("name"):
			equip_dict["name"] = equip_dict["equip_name"]
		if equip_dict.has("quality") and not equip_dict.has("rarity"):
			equip_dict["rarity"] = equip_dict["quality"]
		if not equip_dict.has("is_pet_equipment"):
			equip_dict["is_pet_equipment"] = true
	else:
		var equip_obj = equipment_data
		equip_dict = {
			"id": equip_obj.id, 
			"name": equip_obj.name, 
			"slot": equip_obj.slot, 
			"rarity": equip_obj.rarity, 
			"attack": equip_obj.attack, 
			"defense": equip_obj.defense, 
			"hp": equip_obj.hp, 
			"mp": equip_obj.mp, 
			"agility": equip_obj.agility, 
			"is_pet_equipment": true, 
			"pet_enhance_level": equip_obj.pet_enhance_level, 
			"pet_loot_source": equip_obj.pet_loot_source, 
			"pet_chest_tier": equip_obj.pet_chest_tier
		}
	_normalize_pet_equipment_name_fields(equip_dict)

	pet_equipment_items.append(equip_dict)
	pet_equipment_inventory_changed.emit()

	result.success = true
	result.message = "获得宠物装备：%s" % equip_dict.get("name", "未知")
	return result

func move_pet_equipment_to_warehouse(equip_id: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("宠物装备存仓")
	if not bool(guard.get("success", false)):
		return guard

	if pet_equipment_warehouse.size() >= MAX_PET_EQUIPMENT_WAREHOUSE:
		result.message = "宠物装备仓库已满！"
		return result

	for i in range(pet_equipment_items.size()):
		var equip = pet_equipment_items[i]
		if equip.get("id", "") == equip_id:
			pet_equipment_warehouse.append(equip)
			pet_equipment_items.remove_at(i)
			pet_equipment_inventory_changed.emit()
			pet_equipment_warehouse_changed.emit()
			result.success = true
			result.message = "已将宠物装备存入仓库"
			return result

	result.message = "未找到该宠物装备"
	return result

func move_pet_equipment_from_warehouse(equip_id: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("宠物装备取仓")
	if not bool(guard.get("success", false)):
		return guard

	if pet_equipment_items.size() >= MAX_PET_EQUIPMENT_INVENTORY:
		result.message = "宠物装备背包已满！"
		return result

	for i in range(pet_equipment_warehouse.size()):
		var equip = pet_equipment_warehouse[i]
		if equip.get("id", "") == equip_id:
			pet_equipment_items.append(equip)
			pet_equipment_warehouse.remove_at(i)
			pet_equipment_inventory_changed.emit()
			pet_equipment_warehouse_changed.emit()
			result.success = true
			result.message = "已从仓库取出宠物装备"
			return result

	result.message = "未找到该宠物装备"
	return result

func retrieve_pet_equipment_from_warehouse(equip_id: String) -> Dictionary:
	return move_pet_equipment_from_warehouse(equip_id)

func discard_pet_equipment(equip_id: String) -> Dictionary:
	var result = {"success": false, "message": ""}
	var guard: = _reject_local_authority_mutation_when_online("宠物装备丢弃")
	if not bool(guard.get("success", false)):
		return guard

	for i in range(pet_equipment_items.size()):
		var equip = pet_equipment_items[i]
		if equip.get("id", "") == equip_id:
			pet_equipment_items.remove_at(i)
			pet_equipment_inventory_changed.emit()
			pet_equipment_warehouse_changed.emit()
			result.success = true
			result.message = "已丢弃宠物装备"
			return result

	result.message = "未找到该宠物装备"
	return result

func remove_pet_equipment(equip_id: String) -> Dictionary:
	var result = {"success": false, "message": ""}

	for i in range(pet_equipment_items.size()):
		var equip = pet_equipment_items[i]
		if equip.get("id", "") == equip_id:
			pet_equipment_items.remove_at(i)
			pet_equipment_inventory_changed.emit()
			result.success = true
			result.message = "已移除宠物装备"
			return result

	result.message = "未找到该宠物装备"
	return result

func get_pet_equipment_by_id(equip_id: String) -> Dictionary:
	for equip in pet_equipment_items:
		if equip.get("id", "") == equip_id:
			return equip
	return {}

func get_pet_equipment_warehouse() -> Array:
	return pet_equipment_warehouse.duplicate()

func convert_to_equipment_object(equipment_data) -> RefCounted:
	if equipment_data is RefCounted:
		return equipment_data

	var equipment_class = load("res://scripts/equipment_manager.gd").Equipment
	var equipment = equipment_class.new()
	equipment.id = equipment_data.get("id", equipment.id)
	equipment.name = equipment_data.get("name", "")
	equipment.slot = equipment_data.get("slot", "")
	equipment.rarity = equipment_data.get("rarity", "common")
	equipment.attack = equipment_data.get("attack", 0)
	equipment.defense = equipment_data.get("defense", 0)
	equipment.hp = equipment_data.get("hp", 0)
	equipment.mp = equipment_data.get("mp", 0)
	equipment.agility = equipment_data.get("agility", 0)
	equipment.is_pet_equipment = true
	equipment.pet_enhance_level = int(equipment_data.get("pet_enhance_level", 0))
	equipment.pet_loot_source = str(equipment_data.get("pet_loot_source", ""))
	equipment.pet_chest_tier = str(equipment_data.get("pet_chest_tier", ""))
	return equipment

func _resolve_suit_level_from_sealed_data(sealed_data: Dictionary) -> int:
	if sealed_data.is_empty():
		return 0
	if sealed_data.has("suit_level"):
		return int(sealed_data.get("suit_level", 0))
	return int(sealed_data.get("suit_id", 0))

func get_suit_dismantle_reward(suit_level: int, is_sealed: bool) -> Dictionary:
	var result: = {"success": false, "message": "", "stone_name": "", "count": 0, "suit_level": suit_level}
	if suit_level < 1 or suit_level > 21:
		result.message = "套装层级无效，无法分解"
		return result
	var stone_name: String = NORMAL_SEAL_STONE_ITEM
	if suit_level > 10:
		stone_name = ADVANCED_SEAL_STONE_ITEM
	var count: int = 1
	if not is_sealed:
		count = 2
	result.success = true
	result.stone_name = stone_name
	result.count = count
	return result

func get_sealed_suit_item_dismantle_reward(item_id: String) -> Dictionary:
	for item in items:
		if item.id != item_id:
			continue
		if item.item_type != "sealed_suit":
			return {"success": false, "message": "该道具不是封印套装"}
		var sealed_data: Dictionary = {}
		if item.custom_data is Dictionary:
			sealed_data = item.custom_data
		var suit_level: int = _resolve_suit_level_from_sealed_data(sealed_data)
		return get_suit_dismantle_reward(suit_level, true)
	return {"success": false, "message": "未找到封印套装道具"}

func get_suit_equipment_dismantle_reward(equipment) -> Dictionary:
	if equipment == null:
		return {"success": false, "message": "未找到套装装备"}
	if not bool(equipment.is_suit):
		return {"success": false, "message": "仅套装可分解"}
	var is_sealed: bool = bool(equipment.is_sealed)
	var suit_level: int = int(equipment.suit_id)
	if is_sealed:
		var sealed_data: Dictionary = {}
		if equipment.sealed_data is Dictionary:
			sealed_data = equipment.sealed_data
		var sealed_level: int = _resolve_suit_level_from_sealed_data(sealed_data)
		if sealed_level > 0:
			suit_level = sealed_level
	return get_suit_dismantle_reward(suit_level, is_sealed)

func dismantle_sealed_suit_item(item_id: String) -> Dictionary:
	var result: = {"success": false, "message": ""}
	for i in range(items.size()):
		var item = items[i]
		if item.id != item_id:
			continue
		if item.item_type != "sealed_suit":
			result.message = "该道具不是封印套装"
			return result
		var reward: = get_sealed_suit_item_dismantle_reward(item_id)
		if not reward.get("success", false):
			result.message = str(reward.get("message", "该封印套装不可分解"))
			return result
		items.remove_at(i)
		var stone_name: = str(reward.get("stone_name", ""))
		var stone_count: = int(reward.get("count", 0))
		var add_result: = add_item(stone_name, stone_count)
		if not add_result.get("success", false):
			items.insert(i, item)
			result.message = str(add_result.get("message", "材料背包已满，无法获得解封石"))
			return result
		result.success = true
		result.message = "分解成功，获得%s x%d" % [stone_name, stone_count]
		return result
	result.message = "未找到封印套装道具"
	return result

func dismantle_suit_equipment(equip_id: String) -> Dictionary:
	var result: = {"success": false, "message": ""}
	var game_manager = GameManager.instance
	if not game_manager or not game_manager.equipment_manager:
		result.message = "系统错误：装备管理器未初始化"
		return result
	var equip_manager = game_manager.equipment_manager
	for i in range(equip_manager.inventory.size()):
		var equipment = equip_manager.inventory[i]
		if str(equipment.id) != equip_id:
			continue
		var reward: = get_suit_equipment_dismantle_reward(equipment)
		if not reward.get("success", false):
			result.message = str(reward.get("message", "该套装不可分解"))
			return result
		equip_manager.inventory.remove_at(i)
		equip_manager.inventory_changed.emit()
		var stone_name: = str(reward.get("stone_name", ""))
		var stone_count: = int(reward.get("count", 0))
		var add_result: = add_item(stone_name, stone_count)
		if not add_result.get("success", false):
			equip_manager.inventory.insert(i, equipment)
			equip_manager.inventory_changed.emit()
			result.message = str(add_result.get("message", "材料背包已满，无法获得解封石"))
			return result
		result.success = true
		result.message = "分解成功，获得%s x%d" % [stone_name, stone_count]
		return result
	result.message = "未找到该套装装备"
	return result

func dismantle_pet_equipment(equip_id: String) -> Dictionary:
	var result: = {"success": false, "message": ""}
	var game_manager = GameManager.instance
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，已阻止分解。"
		return result
	for i in range(pet_equipment_items.size()):
		var eq = pet_equipment_items[i]
		if str(eq.get("id", "")) != equip_id:
			continue
		if not PetEquipmentEnhance.can_dismantle(eq):
			result.message = "该宠物装备不可分解（仅青铜/白银/黄金类宝箱产出的宠装可分解）"
			return result
		pet_equipment_items.remove_at(i)
		var frag_n: = PetEquipmentEnhance.dismantle_fragment_count(eq)
		var add_frag: = add_item(PetEquipmentEnhance.FRAGMENT_ITEM, frag_n)
		if not add_frag.get("success", false):
			pet_equipment_items.insert(i, eq)
			result.message = add_frag.get("message", "材料背包已满，无法获得碎片")
			return result
		pet_equipment_inventory_changed.emit()
		result.success = true
		result.message = "分解成功，获得宠装碎片 x%d" % frag_n
		return result
	result.message = "未找到宠物装备"
	return result

func synthesize_pet_fragments_to_stone() -> Dictionary:
	var result: = {"success": false, "message": ""}
	var game_manager = GameManager.instance
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，已阻止合成。"
		return result
	var need: = PetEquipmentEnhance.FRAGMENTS_PER_STONE
	if get_item_count(PetEquipmentEnhance.FRAGMENT_ITEM) < need:
		result.message = "宠装碎片不足（需要%d个）" % need
		return result
	var rm: = remove_item_by_name(PetEquipmentEnhance.FRAGMENT_ITEM, need)
	if not rm.get("success", false):
		result.message = "扣除碎片失败"
		return result
	var add_st: = add_item(PetEquipmentEnhance.STONE_ITEM, 1)
	if not add_st.get("success", false):
		add_item(PetEquipmentEnhance.FRAGMENT_ITEM, need)
		result.message = add_st.get("message", "材料背包已满")
		return result
	result.success = true
	result.message = "合成成功：宠装强化石 x1"
	return result

func synthesize_pet_fragments_to_stone_batch(max_count: int = -1) -> Dictionary:
	var result: Dictionary = {"success": false, "message": "", "crafted": 0}
	var need: int = PetEquipmentEnhance.FRAGMENTS_PER_STONE
	var frag_count: int = get_item_count(PetEquipmentEnhance.FRAGMENT_ITEM)
	var can_by_frag: int = frag_count / need
	if max_count > 0:
		can_by_frag = mini(can_by_frag, max_count)
	if can_by_frag <= 0:
		result.message = "宠装碎片不足（需要%d个）" % need
		return result
	var crafted: int = 0
	for i in range(can_by_frag):
		var one: Dictionary = synthesize_pet_fragments_to_stone()
		if not one.get("success", false):
			if crafted > 0:
				result.success = true
				result.crafted = crafted
				result.message = "批量合成完成：宠装强化石 x%d（提前停止：%s）" % [crafted, str(one.get("message", "材料背包已满"))]
				return result
			result.message = str(one.get("message", "批量合成失败"))
			return result
		crafted += 1
	if crafted <= 0:
		result.message = "批量合成失败"
		return result
	result.success = true
	result.crafted = crafted
	result.message = "批量合成成功：宠装强化石 x%d" % crafted
	return result

func attempt_pet_equipment_enhance(game_manager, equip_id: String) -> Dictionary:
	var result: Dictionary = {"success": false, "message": ""}
	if game_manager == null:
		result.message = "系统错误"
		return result
	if game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，已阻止强化。"
		return result
	var pem = game_manager.pet_equipment_manager
	var inv = game_manager.inventory_manager
	if pem == null or inv == null:
		result.message = "系统错误"
		return result

	for slot in pem.equipped.keys():
		var eq = pem.equipped[slot]
		if eq == null or str(eq.id) != equip_id:
			continue
		var lv2: int = clampi(eq.pet_enhance_level, 0, PetEquipmentEnhance.MAX_LEVEL)
		if lv2 >= PetEquipmentEnhance.MAX_LEVEL:
			result.message = "已达最高强化等级"
			return result
		var cost2: int = PetEquipmentEnhance.stone_cost_for_next_level(lv2)
		var rate2: float = PetEquipmentEnhance.success_rate_for_next_level(lv2)
		if inv.get_item_count(PetEquipmentEnhance.STONE_ITEM) < cost2:
			result.message = "宠装强化石不足（需要%d个）" % cost2
			return result
		var rm2: Dictionary = inv.remove_item_by_name(PetEquipmentEnhance.STONE_ITEM, cost2)
		if not rm2.get("success", false):
			result.message = "扣除材料失败"
			return result
		if randf() > rate2:
			result.success = true
			result.message = "强化失败，材料已消耗"
			pem.bonus_changed.emit(pem.get_all_bonus())
			return result
		eq.pet_enhance_level = lv2 + 1
		pem.equipment_changed.emit(slot, eq)
		pem.bonus_changed.emit(pem.get_all_bonus())

		pet_equipment_inventory_changed.emit()
		result.success = true
		result.message = "强化成功！当前强化+%d" % (lv2 + 1)
		return result

	result.message = "仅可强化已穿戴的宠物装备"
	return result

func _build_capacity_block_result(message: String) -> Dictionary:
	return {
		"success": false, 
		"message": message, 
		"show_dialog": true, 
		"dialog_title": "背包空间不足", 
		"dialog_message": message
	}

func _remaining_stack_space_for_item(item_name: String, item_type: String) -> int:
	if _is_non_stackable_item_instance(item_name, item_type):
		return 0
	var free_space: = 0
	for item in items:
		if item.name == item_name and item.count < MAX_STACK_SIZE:
			free_space += (MAX_STACK_SIZE - item.count)
	return free_space

func _check_reward_item_capacity(reward_items: Array) -> Dictionary:
	var category_new_slots: = {"item": 0, "material": 0}
	var used_existing_stack_space: = {}
	for reward in reward_items:
		if not (reward is Dictionary):
			continue
		var item_name: = str((reward as Dictionary).get("name", "")).strip_edges()
		var item_type: = str((reward as Dictionary).get("item_type", "")).strip_edges()
		var custom_data: Dictionary = ((reward as Dictionary).get("custom_data", {}) as Dictionary).duplicate()
		var count_needed: = maxi(0, int((reward as Dictionary).get("count", 0)))
		if item_name.is_empty() or item_type.is_empty() or count_needed <= 0:
			continue
		var category: = resolve_bag_category(item_name, item_type, custom_data)
		var remaining: = count_needed
		if not _is_non_stackable_item_instance(item_name, item_type):
			var stack_key: = "%s|%s" % [item_name, item_type]
			var total_existing: = _remaining_stack_space_for_item(item_name, item_type)
			var consumed_existing: = int(used_existing_stack_space.get(stack_key, 0))
			var can_use_existing: = maxi(0, total_existing - consumed_existing)
			var consume_now: = mini(remaining, can_use_existing)
			if consume_now > 0:
				used_existing_stack_space[stack_key] = consumed_existing + consume_now
				remaining -= consume_now
		if remaining > 0:
			category_new_slots[category] = int(category_new_slots.get(category, 0)) + int(ceil(float(remaining) / float(MAX_STACK_SIZE)))
	var item_need: = int(category_new_slots.get("item", 0))
	var material_need: = int(category_new_slots.get("material", 0))
	var item_free: = get_available_space_by_category("item")
	var material_free: = get_available_space_by_category("material")
	if item_need > item_free:
		return {"ok": false, "message": "道具背包空位不足！需要%d格，当前仅剩%d格。" % [item_need, item_free]}
	if material_need > material_free:
		return {"ok": false, "message": "材料背包空位不足！需要%d格，当前仅剩%d格。" % [material_need, material_free]}
	return {"ok": true}

func _check_gift_capacity(game_manager, gift_name: String, equip_need: int, pet_need: int, reward_items: Array) -> Dictionary:
	if game_manager == null:
		return {"ok": false, "message": "游戏管理器未初始化，请稍后再试"}
	var equipment_manager = game_manager.equipment_manager
	if equip_need > 0:
		if equipment_manager == null:
			return {"ok": false, "message": "装备管理器未初始化，请稍后再试"}
		var equip_free: = int(equipment_manager.max_inventory - equipment_manager.inventory.size())
		if equip_free < equip_need:
			return {"ok": false, "message": "%s开启失败：装备背包空位不足（需要%d格，当前%d格）。" % [gift_name, equip_need, equip_free]}
	if pet_need > 0:
		var pet_manager = game_manager.pet_manager
		if pet_manager == null:
			return {"ok": false, "message": "宠物管理器未初始化，请稍后再试"}
		var pet_free: = int(pet_manager.get_available_slots())
		if pet_free < pet_need:
			return {"ok": false, "message": "%s开启失败：宠物栏空位不足（需要%d格，当前%d格）。" % [gift_name, pet_need, pet_free]}
	var reward_capacity: = _check_reward_item_capacity(reward_items)
	if not bool(reward_capacity.get("ok", false)):
		return {"ok": false, "message": "%s开启失败：%s" % [gift_name, str(reward_capacity.get("message", "背包空位不足"))]}
	return {"ok": true}

func _create_single_attr_equipment(slot: String, display_name: String, attr: String, value: int):
	var equipment_class = load("res://scripts/equipment_manager.gd").Equipment
	var equipment = equipment_class.new()
	equipment.name = display_name
	equipment.slot = slot
	equipment.rarity = "divine"
	equipment.cultivation_req = 1
	equipment.attack = 0
	equipment.defense = 0
	equipment.agility = 0
	equipment.hp = 0
	equipment.mp = 0
	match attr:
		"attack":
			equipment.attack = value
		"defense":
			equipment.defense = value
		"agility":
			equipment.agility = value
		"hp":
			equipment.hp = value
		"mp":
			equipment.mp = value
	return equipment

func _grant_single_attr_set(equipment_manager, prefix: String, value: int, messages: Array) -> void :
	for cfg in SINGLE_ATTR_SLOT_CONFIG:
		var eq_name: = "%s%s" % [prefix, str(cfg.get("name_suffix", ""))]
		var attr_key: = str(cfg.get("attr", ""))
		var attr_cn: = "属性"
		match attr_key:
			"attack":
				attr_cn = "攻击"
			"defense":
				attr_cn = "防御"
			"agility":
				attr_cn = "敏捷"
			"hp":
				attr_cn = "生命"
			"mp":
				attr_cn = "内力"
		var equipment = _create_single_attr_equipment(str(cfg.get("slot", "")), eq_name, attr_key, value)
		equipment_manager.add_to_inventory(equipment)
		messages.append("获得【%s】（%s+%d）" % [eq_name, attr_cn, value])

func _grant_single_attr_set_via_server(game_manager, source_id: String) -> Dictionary:
	var result: = {"success": false, "message": "", "data": {}}
	if game_manager == null or game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "当前网络不可用，请登录后重试"
		return result
	# 状态必须放 Dictionary（lambda 按值捕获局部变量，bool 改了外面看不到），
	# 同时给一个硬超时：原来 `while not state.done` 没有上限，网络卡住就永久卡在「处理中…」。
	var state: = {"done": false, "ok": false, "message": "", "data": {}, "applied": false}
	var op_id: = "equipment_grant_%s_%d_%s" % [source_id, Time.get_ticks_usec(), str(randi())]
	var on_success = func(data: Dictionary):
		if bool(state.done):
			return
		state.done = true
		state.data = data if data is Dictionary else {}
		# HTTP 200 但 success=false 的业务失败也会走 success 信号，
		# 不先判一次的话真实原因（"背包里没有【新手锦囊】"）会被吞掉，
		# 玩家看到的是一句莫名的"服务器没有返回权威存档"。
		if state.data.get("success") == false:
			state.ok = false
			state.message = str(state.data.get("message", "人物装备发放失败"))
			return
		state.ok = true
		state.message = str(state.data.get("message", "人物装备发放成功"))
		if bool(state.data.get("duplicate", false)):
			state.applied = true
			if game_manager:
				game_manager.call_deferred("download_cloud_save")
		elif state.data.has("saveData") and state.data.get("saveData") is Dictionary:
			game_manager.apply_cloud_save(state.data.get("saveData"), {
				"authoritative_equipment_inventory": true, 
				"reward_inventory_slice": true, 
			})
			state.applied = true
	var on_failed = func(error: String):
		if bool(state.done):
			return
		state.done = true
		state.ok = false
		state.message = error
	var nw: Node = game_manager.network
	nw.equipment_grant_success.connect(on_success, CONNECT_ONE_SHOT)
	nw.equipment_grant_failed.connect(on_failed, CONNECT_ONE_SHOT)
	nw.request_equipment_grant("gift", source_id, 1, op_id)
	var deadline_ms: int = Time.get_ticks_msec() + 15000
	while not bool(state.done) and Time.get_ticks_msec() < deadline_ms:
		await game_manager.get_tree().process_frame
	if nw.equipment_grant_success.is_connected(on_success):
		nw.equipment_grant_success.disconnect(on_success)
	if nw.equipment_grant_failed.is_connected(on_failed):
		nw.equipment_grant_failed.disconnect(on_failed)
	if not bool(state.done):
		result.message = "网络超时，礼包未扣除。请检查网络后重试。"
		return result
	if bool(state.ok) and not bool(state.applied):
		result.message = "服务器没有返回权威存档，本次开启未生效，请稍后重试"
		return result
	result.success = bool(state.ok)
	result.message = str(state.message)
	result.data = state.data if state.data is Dictionary else {}
	return result


func open_test_gift(player: Node, game_manager) -> Dictionary:
	var result = {"success": false, "message": ""}
	if not OS.is_debug_build():
		result.message = "测试锦囊仅允许调试环境使用，正式环境已禁用。"
		return result
	var online_guard_test_gift: = _reject_legacy_local_pet_authority("测试锦囊本地发宠")
	if not bool(online_guard_test_gift.get("success", false)):
		result.message = str(online_guard_test_gift.get("message", "测试锦囊已禁止在线本地发宠"))
		return result
	var messages = []

	var equipment_manager = game_manager.equipment_manager
	var available_equip_slots = equipment_manager.max_inventory - equipment_manager.inventory.size()
	if available_equip_slots < 5:
		result.message = "装备背包空位不足！需要5个空位存放测试装备，当前只有%d个空位。\n\n请先清理装备背包，然后再打开测试锦囊。" % available_equip_slots
		return result

	var pet_manager = game_manager.pet_manager
	var available_pet_slots = GameData.MAX_PETS - pet_manager.get_pet_count()
	if available_pet_slots < 8:
		result.message = "宠物栏空位不足！需要8个空位存放赤翅蛾，当前只有%d个空位。\n\n请先清理宠物栏，然后再打开测试锦囊。" % available_pet_slots
		return result


	if game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "请登录后再使用测试锦囊"
		return result
	var op_tg: = "test_gift_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var er_tg: Dictionary = await game_manager.wait_economy("economy_whitelist_gold", func():
		game_manager.network.economy_whitelist_gold(op_tg, "test_gift_100m")
	)
	if not er_tg.get("ok", false):
		result.message = str(er_tg.get("err", "在线发放测试锦囊金币失败，请稍后重试"))
		return result
	var tgd: Variant = er_tg.get("data", {})
	if tgd is Dictionary and (tgd as Dictionary).has("newGold"):
		player.gold = int((tgd as Dictionary).get("newGold", player.gold))
	game_manager.gold_changed.emit(player.gold)
	messages.append("获得1亿金币")

	var test_equipment_stats = [
		{"name": "测试武器", "slot": "weapon", "attack": 500}, 
		{"name": "测试衣服", "slot": "armor", "defense": 500}, 
		{"name": "测试帽子", "slot": "helmet", "agility": 500}, 
		{"name": "测试鞋子", "slot": "boots", "hp": 500}, 
		{"name": "测试饰品", "slot": "accessory", "mp": 500}
	]

	for equip_data in test_equipment_stats:
		var equipment = _create_test_equipment(equip_data)
		equipment_manager.add_to_inventory(equipment)
		messages.append("获得测试装备：%s" % equip_data.name)
		print("[TestGift] 添加装备: ", equip_data.name, ", 装备背包数量: ", equipment_manager.inventory.size())

	for i in range(8):
		pet_manager.create_pet_from_tower("linlin", "琳琳", 6.0)
	messages.append("获得8只【赤翅蛾】（成长6.0）")

	result.success = true
	result.message = "\n".join(messages)
	print("[TestGift] 发放完成，共", items.size(), "个物品")
	inventory_changed.emit()
	return result

func _create_test_equipment(equip_data: Dictionary):
	var equipment_class = load("res://scripts/equipment_manager.gd").Equipment
	var equipment = equipment_class.new()
	equipment.name = equip_data.name
	equipment.slot = equip_data.slot
	equipment.rarity = "divine"
	equipment.cultivation_req = 1
	equipment.attack = equip_data.get("attack", 0)
	equipment.defense = equip_data.get("defense", 0)
	equipment.agility = equip_data.get("agility", 0)
	equipment.hp = equip_data.get("hp", 0)
	equipment.mp = equip_data.get("mp", 0)
	return equipment


func open_frontier_pet_equipment_gift(game_manager) -> Dictionary:
	var result = {"success": false, "message": ""}
	if game_manager == null or game_manager.inventory_manager == null:
		result.message = "背包管理器未初始化，请稍后再试"
		return result
	if game_manager.network == null or not game_manager.network.is_logged_in():
		result.message = "该礼包包含高价值宠装，需联网使用，请登录后重试"
		return result
	if pet_equipment_items.size() + 5 > MAX_PET_EQUIPMENT_INVENTORY:
		result.message = "宠物装备背包空间不足！开启需要5个空位（当前%d/%d）" % [pet_equipment_items.size(), MAX_PET_EQUIPMENT_INVENTORY]
		return result

	var state: = {"done": false, "ok": false, "message": "", "data": {}}
	var op_id: = "pet_equipment_grant_frontier_gift_%d_%s" % [Time.get_ticks_usec(), str(randi())]
	var on_success = func(data: Dictionary):
		state.done = true
		state.ok = true
		state.data = data
		state.message = str(data.get("message", "获得开荒宠装锦囊奖励"))
		if bool(data.get("duplicate", false)) and game_manager:
			game_manager.call_deferred("download_cloud_save")
	var on_failed = func(error: String):
		state.done = true
		state.ok = false
		state.message = error
	game_manager.network.pet_equipment_grant_success.connect(on_success, CONNECT_ONE_SHOT)
	game_manager.network.pet_equipment_grant_failed.connect(on_failed, CONNECT_ONE_SHOT)
	game_manager.network.request_pet_equipment_grant("gift", "frontier_pet_equipment_gift", 1, op_id)
	var frontier_grant_deadline_ms: int = Time.get_ticks_msec() + 15000
	while not bool(state.done):
		if Time.get_ticks_msec() >= frontier_grant_deadline_ms:
			var nw_of = game_manager.network
			if nw_of != null:
				if nw_of.pet_equipment_grant_success.is_connected(on_success):
					nw_of.pet_equipment_grant_success.disconnect(on_success)
				if nw_of.pet_equipment_grant_failed.is_connected(on_failed):
					nw_of.pet_equipment_grant_failed.disconnect(on_failed)
			result.message = "网络超时，礼包未扣除。请检查网络后重试。"
			return result
		await game_manager.get_tree().process_frame
	if not bool(state.ok):
		result.message = str(state.message)
		return result
	var response: Dictionary = state.data if state.data is Dictionary else {}
	if not bool(response.get("duplicate", false)) and response.has("saveData") and response.get("saveData") is Dictionary:
		game_manager.apply_cloud_save(response.get("saveData"), {
			"authoritative_equipment_inventory": true, 
			"reward_inventory_slice": true, 
		})
	result.success = true
	result.message = str(state.message)
	return result

func _create_test_pet_equipment(slot: String, name: String, attribute_value: int) -> Dictionary:
	var id = "pet_equip_" + str(randi() % 100000)

	var equip_name = name
	if not equip_name.ends_with("（宠）"):
		equip_name = equip_name + "（宠）"

	var equip_data = {
		"id": id, 
		"name": equip_name, 
		"slot": slot, 
		"rarity": "divine", 
		"attack": 0, 
		"defense": 0, 
		"hp": 0, 
		"mp": 0, 
		"agility": 0, 
		"is_pet_equipment": true
	}

	match slot:
		"weapon":
			equip_data.attack = attribute_value
		"armor":
			equip_data.defense = attribute_value
		"boots":
			equip_data.agility = attribute_value
		"helmet":
			equip_data.hp = attribute_value
		"accessory":
			equip_data.hp = attribute_value

	return equip_data
