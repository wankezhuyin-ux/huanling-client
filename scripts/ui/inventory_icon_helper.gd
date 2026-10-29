extends RefCounted
class_name InventoryIconHelper



const GameData = preload("res://scripts/game_data.gd")
const FabaoIcons = preload("res://scripts/fabao/fabao_icons.gd")

const CATEGORY_DIR: = "res://assets/items/category/"
const NORMAL_DIR: = "res://assets/items/equip_normal/"
const SUIT_DIR: = "res://assets/items/suits/"
const PET_EQUIP_DIR: = "res://assets/items/pet_equip/"
const SEALED_MODULATE: = Color(0.45, 0.45, 0.5, 1.0)


const SPECIFIC_ICON_BY_NAME: = {
	"金魂魄": "icon_soul_jin.png", 
	"木魂魄": "icon_soul_mu.png", 
	"水魂魄": "icon_soul_shui.png", 
	"火魂魄": "icon_soul_huo.png", 
	"土魂魄": "icon_soul_tu.png", 
	"定神丹": "icon_pill_ningshen.png", 
	"开悟丹": "icon_pill_wudao.png", 
	"人物经验丹": "icon_pill_player_level.png", 
	"宠物经验丹": "icon_pill_pet_level.png", 
	"双倍经验符": "icon_pill_double_exp.png", 
	"双倍经验符·周": "icon_pill_double_exp.png", 
	"双倍经验符·月": "icon_pill_double_exp.png", 
	"宠物补章器": "icon_pet_medal_tool.png", 
	"墨草": "icon_herb_lingcao.png", 
	"墨芝": "icon_herb_lingzhi.png", 
	"雪莲": "icon_herb_xuelian.png", 
	"还魂草": "icon_herb_jiuzhuan.png", 
	"墨涎草": "icon_herb_longxian.png", 
	"强化石": "icon_stone_enhance.png", 
	"套装强化石": "icon_stone_suit.png", 
	"宠装碎片": "icon_frag_pet_equip.png", 
	"宠装强化石": "icon_stone_pet_equip.png", 
	"法宝洗练石": "icon_stone_fabao_reroll.png", 
	"法宝重置石": "icon_stone_fabao_reset.png", 
	"建设材料": "icon_build_mat.png", 
	"解封石": "icon_unseal_normal.png", 
	"高级解封石": "icon_unseal_high.png", 
	"幻化符": "icon_huanhua_fu.png", 
	"天关锦囊": "icon_gift_tower.png", 
	"天关组队锦囊": "icon_gift_brother.png", 
	"开荒锦囊": "icon_gift_pioneer.png", 
	"开荒宠装锦囊": "icon_gift_pioneer_pet_equip.png", 
	"新手锦囊": "icon_gift_newbie.png", 
	"极限装备锦囊": "icon_gift_limit_equip.png", 
	"离线宠物锦囊": "icon_gift_offline_pet.png", 
}

static var _tex_cache: Dictionary = {}

static func clear_tex_cache() -> void :
	_tex_cache.clear()


static func _load_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img: = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_tex_cache[path] = tex
	return tex


static func _load_category(file_name: String) -> Texture2D:
	if file_name.is_empty():
		return null
	return _load_tex(CATEGORY_DIR + file_name)


static func category_icon_for_item_type(item_type: String, force_material: bool = false) -> Texture2D:
	if force_material:
		return _load_tex(CATEGORY_DIR + "icon_material.png")
	var t: = item_type.strip_edges().to_lower()
	var file: = "icon_item.png"
	match t:
		"pill":
			file = "icon_pill.png"
		"cultivation_pill":
			file = "icon_cultivation_pill.png"
		"herb":
			file = "icon_herb.png"
		"material":
			file = "icon_material.png"
		"gift":
			file = "icon_gift.png"
		"martial_skill_book":
			file = "icon_martial_book.png"
		"pet_skill_book":
			file = "icon_pet_book.png"
		"pet_egg":
			file = "icon_egg.png"
		"pet_soul_item":
			file = "icon_soul.png"
		"treasure_chest", "chest":
			file = "icon_chest.png"
		"sealed_suit":
			file = "icon_item.png"
		_:
			file = "icon_item.png"
	var tex: = _load_tex(CATEGORY_DIR + file)
	if tex == null and file == "icon_herb.png":
		return _load_tex(CATEGORY_DIR + "icon_material.png")
	return tex


static func _item_name_of(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("name", "")).strip_edges()
	if "name" in item:
		return str(item.name).strip_edges()
	return ""


static func resolve_limit_material_icon(item_name: String) -> Texture2D:
	var n: = ForgeData.normalize_limit_material_name(item_name) if item_name else ""
	if n.is_empty():
		n = item_name
	var meta: Dictionary = ForgeData.limit_material_slot_attr(n)
	var slot: = str(meta.get("slot", ""))
	if slot.is_empty():
		if n.contains("衣") or n.contains("甲"):
			slot = "armor"
		elif n.contains("鞋"):
			slot = "boots"
		elif n.contains("血") or n.contains("帽") or n.contains("头"):
			slot = "helmet"
		elif n.contains("内") or n.contains("饰"):
			slot = "accessory"
		else:
			slot = "weapon"
	var path: = CATEGORY_DIR + "icon_limit_%s.png" % slot
	var tex: = _load_tex(path)
	if tex:
		return tex

	for fallback in ["weapon", "armor", "helmet", "boots", "accessory"]:
		tex = _load_tex(CATEGORY_DIR + "icon_limit_%s.png" % fallback)
		if tex:
			return tex
	return _load_tex(CATEGORY_DIR + "icon_material.png")


static func _resolve_gift_or_egg_icon(item_name: String, catalog_t: String) -> Texture2D:

	if catalog_t == "pet_egg" or item_name.ends_with("宠物蛋") or item_name.contains("宠物蛋"):
		var egg: = _load_category("icon_egg.png")
		if egg:
			return egg

	if SPECIFIC_ICON_BY_NAME.has(item_name):
		var exact: = _load_category(str(SPECIFIC_ICON_BY_NAME[item_name]))
		if exact:
			return exact

	if item_name.ends_with("关礼包") or item_name == "天关锦囊":
		var tower: = _load_category("icon_gift_tower.png")
		if tower:
			return tower

	if item_name.contains("礼包") and (item_name.contains("+") or item_name.contains("可进化") or item_name.contains("不可进化")):
		if item_name.contains("变异"):
			var mut: = _load_category("icon_gift_pet_mutant.png")
			if mut:
				return mut
		var growth: = _load_category("icon_gift_growth.png")
		if growth:
			return growth
	if item_name.contains("离线") and item_name.contains("礼包"):
		var off: = _load_category("icon_gift_offline_pet.png")
		if off:
			return off
	if item_name.contains("开荒") and item_name.contains("宠装"):
		var pe: = _load_category("icon_gift_pioneer_pet_equip.png")
		if pe:
			return pe
	if item_name.contains("开荒") and item_name.contains("礼包"):
		var pio: = _load_category("icon_gift_pioneer.png")
		if pio:
			return pio
	if item_name.contains("兄弟") and item_name.contains("天关") and item_name.contains("礼包"):
		var bro: = _load_category("icon_gift_brother.png")
		if bro:
			return bro
	if (item_name.contains("新手") or item_name.contains("新人")) and item_name.contains("礼包"):
		var nb: = _load_category("icon_gift_newbie.png")
		if nb:
			return nb
	if item_name.contains("极限") and item_name.contains("礼包"):
		var lim: = _load_category("icon_gift_limit_equip.png")
		if lim:
			return lim
	if item_name.contains("宠物") and item_name.contains("礼包"):
		var petg: = _load_category("icon_gift_pet.png")
		if petg:
			return petg
	return null


static func category_icon_for_inventory_item(item) -> Texture2D:
	if item == null:
		return category_icon_for_item_type("item")
	var item_name: = _item_name_of(item)
	var fabao_tex: = FabaoIcons.tex_for_item_name(item_name)
	if fabao_tex:
		return fabao_tex
	if item is Dictionary and str(item.get("entry_kind", "")) == "limit_material_aggregate":
		return resolve_limit_material_icon(item_name)
	if ForgeData.is_limit_forge_material_name(item_name):
		return resolve_limit_material_icon(item_name)

	var catalog_t: = ""
	if GameData.ALL_ITEMS.has(item_name):
		var cfg = GameData.ALL_ITEMS[item_name]
		if cfg is Dictionary:
			catalog_t = str(cfg.get("type", "")).strip_edges().to_lower()

	var item_type: = ""
	if item is Dictionary:
		item_type = str(item.get("item_type", item.get("type", "")))
	elif "item_type" in item:
		item_type = str(item.item_type)
	item_type = item_type.strip_edges().to_lower()
	if item_type.is_empty():
		item_type = catalog_t


	if SPECIFIC_ICON_BY_NAME.has(item_name):
		var specific: = _load_category(str(SPECIFIC_ICON_BY_NAME[item_name]))
		if specific:
			return specific

	if item_name.contains("令牌"):
		var tok: = _load_category("icon_token.png")
		if tok:
			return tok
	if InventoryBagSort.is_gold_bag_name(_item_name_of(item)):
		var gold: = _load_category("icon_gold_bag.png")
		if gold:
			return gold


	if item_type == "pet_skill_book" or catalog_t == "pet_skill_book":
		var pbook: = _load_category("icon_pet_book.png")
		if pbook:
			return pbook
	if item_type == "martial_skill_book" or catalog_t == "martial_skill_book":
		var mbook: = _load_category("icon_martial_book.png")
		if mbook:
			return mbook
	if item_name.contains("技能书"):

		if item_name.findn("lv") >= 0:
			var pb2: = _load_category("icon_pet_book.png")
			if pb2:
				return pb2
		var mb2: = _load_category("icon_martial_book.png")
		if mb2:
			return mb2

	var gift_or_egg: = _resolve_gift_or_egg_icon(item_name, catalog_t if not catalog_t.is_empty() else item_type)
	if gift_or_egg:
		return gift_or_egg

	if catalog_t == "herb" or item_type == "herb":
		var herb: = _load_category("icon_herb.png")
		if herb:
			return herb

	return category_icon_for_item_type(item_type if not item_type.is_empty() else "item")


static func _item_type_of(item) -> String:
	if item == null:
		return ""
	if item is Dictionary:
		return str(item.get("item_type", item.get("type", ""))).strip_edges().to_lower()
	if "item_type" in item:
		return str(item.item_type).strip_edges().to_lower()
	return ""


static func _is_pet_skill_book_item(item, item_name: String, catalog_t: String) -> bool:
	var item_type: = _item_type_of(item)
	if item_type == "pet_skill_book" or catalog_t == "pet_skill_book":
		return true

	return item_name.contains("技能书") and item_name.findn("lv") >= 0


static func _is_rare_pet_skill_book_name(item_name: String) -> bool:
	return InventoryBagSort.is_rare_pet_skill_book_name(item_name)


static func badge_for_inventory_item(item) -> String:
	if item == null:
		return ""
	var item_name: = _item_name_of(item)
	if item_name.contains("令牌"):
		return "令"
	if InventoryBagSort.is_gold_bag_name(item_name):
		return "金"
	if ForgeData.is_limit_forge_material_name(item_name) or (item is Dictionary and str(item.get("entry_kind", "")) == "limit_material_aggregate"):
		return "极"
	if item_name.contains("人物经验丹"):
		return "人"
	if item_name.contains("宠物经验丹"):
		return "宠"

	if item_name == "双倍经验符·周":
		return "周"
	if item_name == "双倍经验符·月":
		return "月"
	var catalog_t: = ""
	if GameData.ALL_ITEMS.has(item_name):
		var cfg = GameData.ALL_ITEMS[item_name]
		if cfg is Dictionary:
			catalog_t = str(cfg.get("type", "")).strip_edges().to_lower()
	if _is_pet_skill_book_item(item, item_name, catalog_t):
		if _is_rare_pet_skill_book_name(item_name):
			return "稀"
		return ""
	if catalog_t == "pet_egg" or item_name.contains("宠物蛋"):
		return "蛋"
	if item_name.contains("变异") and item_name.contains("礼包"):
		return "变"
	if item_name.contains("礼包") and (item_name.contains("+") or item_name.contains("可进化") or item_name.contains("不可进化")):
		return "宠"
	if item_name.contains("宠物") and item_name.contains("礼包"):
		return "宠"
	if catalog_t == "herb" or InventoryBagSort.material_filter_category(item) == "herb":
		return "草"
	return ""


static func badge_for_equipment(equipment) -> String:
	if is_equipment_sealed(equipment):
		return "封"
	return ""



static func enhance_badge_for_equipment(equipment) -> String:
	if equipment == null:
		return ""
	var lv: = 0
	if _equipment_is_pet(equipment):
		if equipment is Dictionary:
			lv = int(equipment.get("pet_enhance_level", 0))
		elif "pet_enhance_level" in equipment:
			lv = int(equipment.pet_enhance_level)
	else:
		if equipment is Dictionary:
			lv = int(equipment.get("suit_enhance_level", 0))
		elif "suit_enhance_level" in equipment:
			lv = int(equipment.suit_enhance_level)
	if lv <= 0:
		return ""
	return "+%d" % lv


static func normalize_slot(slot: String) -> String:
	var s: = slot.strip_edges().to_lower()
	match s:
		"weapon", "武器", "pet_weapon":
			return "weapon"
		"helmet", "帽子", "头盔", "pet_helmet":
			return "helmet"
		"armor", "防具", "衣服", "pet_armor":
			return "armor"
		"boots", "鞋子", "pet_boots":
			return "boots"
		"accessory", "饰品", "pet_accessory":
			return "accessory"
		_:
			return s if s in ["weapon", "helmet", "armor", "boots", "accessory"] else "weapon"


static func normal_equip_icon(slot: String) -> Texture2D:
	var ns: = normalize_slot(slot)
	return _load_tex(NORMAL_DIR + "equip_normal_%s.png" % ns)


static func suit_equip_icon(suit_id: int, slot: String) -> Texture2D:
	if suit_id <= 0:
		return null
	var ns: = normalize_slot(slot)
	var path: = SUIT_DIR + "suit_%02d_%s.png" % [suit_id, ns]
	return _load_tex(path)


static func _equipment_is_pet(equipment) -> bool:
	if equipment == null:
		return false
	if equipment is Dictionary:
		return bool(equipment.get("is_pet_equipment", false))
	if "is_pet_equipment" in equipment:
		return bool(equipment.is_pet_equipment)
	return false


static func _equipment_slot_raw(equipment) -> String:
	if equipment == null:
		return "weapon"
	if "slot" in equipment:
		return str(equipment.slot)
	if equipment is Dictionary:
		return str(equipment.get("slot", "weapon"))
	return "weapon"


static func _equipment_name_raw(equipment) -> String:
	if equipment == null:
		return ""
	if "name" in equipment:
		return str(equipment.name)
	if equipment is Dictionary:
		return str(equipment.get("name", equipment.get("equip_name", "")))
	return ""


static func _equipment_pet_chest_tier(equipment) -> String:
	if equipment == null:
		return ""
	if "pet_chest_tier" in equipment:
		return str(equipment.pet_chest_tier).strip_edges().to_lower()
	if equipment is Dictionary:
		return str(equipment.get("pet_chest_tier", "")).strip_edges().to_lower()
	return ""


static func resolve_pet_equipment_icon(equipment) -> Texture2D:
	var ns: = normalize_slot(_equipment_slot_raw(equipment))
	var tier: = _equipment_pet_chest_tier(equipment)
	if tier in ["bronze", "silver", "gold"]:
		var tier_tex: = _load_tex(PET_EQUIP_DIR + "pet_%s_%s.png" % [tier, ns])
		if tier_tex:
			return tier_tex
	var eq_name: = _equipment_name_raw(equipment)
	if eq_name.contains("青铜"):
		tier = "bronze"
	elif eq_name.contains("银月"):
		tier = "silver"
	elif eq_name.contains("金鳞"):
		tier = "gold"
	else:
		tier = ""
	if tier in ["bronze", "silver", "gold"]:
		var named_tex: = _load_tex(PET_EQUIP_DIR + "pet_%s_%s.png" % [tier, ns])
		if named_tex:
			return named_tex
	var normal_pet: = _load_tex(PET_EQUIP_DIR + "pet_normal_%s.png" % ns)
	if normal_pet:
		return normal_pet
	return normal_equip_icon(ns)


static func resolve_equipment_icon(equipment) -> Texture2D:
	if equipment == null:
		return normal_equip_icon("weapon")
	if _equipment_is_pet(equipment):
		return resolve_pet_equipment_icon(equipment)
	var slot: = _equipment_slot_raw(equipment)
	var suit_id: = 0
	if "suit_id" in equipment:
		suit_id = int(equipment.suit_id)
	elif equipment is Dictionary:
		suit_id = int(equipment.get("suit_id", 0))
	if suit_id <= 0 and "sealed_data" in equipment and equipment.sealed_data is Dictionary:
		suit_id = int(equipment.sealed_data.get("suit_level", equipment.sealed_data.get("suit_id", 0)))
	if suit_id > 0:
		var suit_tex: = suit_equip_icon(suit_id, slot)
		if suit_tex:
			return suit_tex
	return normal_equip_icon(slot)


static func is_equipment_sealed(equipment) -> bool:
	if equipment == null:
		return false
	if equipment is Dictionary:
		if bool(equipment.get("is_sealed", false)):
			return true
		if str(equipment.get("item_type", "")) == "sealed_suit":
			return true
		return false
	if "is_sealed" in equipment and bool(equipment.is_sealed):
		return true
	if "item_type" in equipment and str(equipment.item_type) == "sealed_suit":
		return true
	return false


static func sealed_modulate() -> Color:
	return SEALED_MODULATE


## 品质描边：色相保留（品质要一眼可分），但压饱和、往墨色靠，
## 免得满屏荧光绿/亮蓝盖过水墨底。统一给到接近 0.8 的明度上限。
static func rarity_border_color(rarity: String) -> Color:
	var r: = rarity.strip_edges().to_lower()
	match r:
		"uncommon":
			return Color(0.29, 0.63, 0.44)
		"rare":
			return Color(0.34, 0.57, 0.73)
		"epic":
			return Color(0.56, 0.41, 0.67)
		"legendary":
			return Color(0.85, 0.66, 0.31)
		"divine":
			return Color(0.86, 0.41, 0.33)
		_:
			return Color(0.56, 0.55, 0.51)


static func short_name(text: String, max_chars: int = 6) -> String:
	var t: = text.strip_edges()
	if t.length() <= max_chars:
		return t
	return t.substr(0, max_chars - 1) + "…"
