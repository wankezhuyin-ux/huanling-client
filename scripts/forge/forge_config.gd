extends RefCounted
class_name ForgeConfig

const LIMIT_VALUES = {
	"attack": 3168, 
	"defense": 3168, 
	"agility": 3168, 
	"hp": 12510, 
	"mp": 12510, 
}

const COST_RATE = 0.5
const MATERIAL_COST_RATE = {
	"hp": 0.1, 
	"mp": 0.1, 
}
const FORGE_REQ_STEP_CULTIVATION = 5000
const FORGE_MIN_SUCCESS_RATE = 0.1

const TRANSFER_CONFIG = {
	"weapon": {
		"defense": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "mp", "priority": 1}, 
		"agility": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "hp", "priority": 2}, 
		"hp": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "defense", "priority": 3}, 
		"mp": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "attack", "priority": 4}, 
		"attack": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "agility", "priority": 5}, 
	}, 
	"armor": {
		"agility": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "hp", "priority": 1}, 
		"mp": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "attack", "priority": 2}, 
		"attack": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "agility", "priority": 3}, 
		"defense": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "mp", "priority": 4}, 
		"hp": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "defense", "priority": 5}, 
	}, 
	"boots": {
		"mp": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "attack", "priority": 1}, 
		"attack": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "agility", "priority": 2}, 
		"defense": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "mp", "priority": 3}, 
		"hp": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "defense", "priority": 4}, 
		"agility": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "hp", "priority": 5}, 
	}, 
	"helmet": {
		"attack": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "agility", "priority": 1}, 
		"hp": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "defense", "priority": 2}, 
		"agility": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "hp", "priority": 3}, 
		"defense": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "mp", "priority": 4}, 
		"mp": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "attack", "priority": 5}, 
	}, 
	"accessory": {
		"hp": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "defense", "priority": 1}, 
		"defense": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "mp", "priority": 2}, 
		"mp": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "attack", "priority": 3}, 
		"attack": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "agility", "priority": 4}, 
		"agility": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "hp", "priority": 5}, 
	}, 
	"shoes": {
		"mp": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "attack", "priority": 1}, 
		"attack": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "agility", "priority": 2}, 
		"defense": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "mp", "priority": 3}, 
		"hp": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "defense", "priority": 4}, 
		"agility": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "hp", "priority": 5}, 
	}, 
	"belt": {
		"attack": {"max_rate": 0.7, "per_transfer": [0.1, 0.2], "cost_attr": "agility", "priority": 1}, 
		"hp": {"max_rate": 0.5, "per_transfer": [0.08, 0.15], "cost_attr": "defense", "priority": 2}, 
		"agility": {"max_rate": 0.3, "per_transfer": [0.05, 0.1], "cost_attr": "hp", "priority": 3}, 
		"defense": {"max_rate": 0.2, "per_transfer": [0.03, 0.08], "cost_attr": "mp", "priority": 4}, 
		"mp": {"max_rate": 0.1, "per_transfer": [0.02, 0.05], "cost_attr": "attack", "priority": 5}, 
	}, 
}

const MATERIAL_MAIN_ATTR = {
	"weapon": "attack", 
	"armor": "defense", 
	"boots": "agility", 
	"shoes": "agility", 
	"helmet": "hp", 
	"accessory": "mp", 
	"belt": "mp", 
}

const ATTR_NAMES = {
	"attack": "攻击", 
	"defense": "防御", 
	"agility": "敏捷", 
	"hp": "生命", 
	"mp": "内力", 
}

const SLOT_NAMES = {
	"weapon": "武器", 
	"armor": "衣服", 
	"boots": "鞋子", 
	"shoes": "鞋子", 
	"helmet": "头饰", 
	"accessory": "身饰", 
	"belt": "腰带", 
}

const ANIMATION_STAGES = [
	{
		"title": "🔥 点燃炉火 🔥", 
		"desc": "五行灵气开始汇聚...", 
		"progress": 25, 
		"duration": 0.8, 
	}, 
	{
		"title": "🔥 熔炼材料 🔥", 
		"desc": "极限装备化为精华...", 
		"progress": 50, 
		"duration": 0.8, 
	}, 
	{
		"title": "🔥 属性转移 🔥", 
		"desc": "五行相生，属性融合...", 
		"progress": 75, 
		"duration": 0.8, 
	}, 
	{
		"title": "✨ 锻造完成 ✨", 
		"desc": "装备焕然一新！", 
		"progress": 100, 
		"duration": 0.6, 
	}, 
]

static func get_attr_name(attr: String) -> String:
	return ATTR_NAMES.get(attr, attr)

static func get_limit_value(attr: String) -> int:
	return LIMIT_VALUES.get(attr, 0)

static func get_transfer_config(equipment_type: String, attr: String) -> Dictionary:
	return TRANSFER_CONFIG.get(equipment_type, {}).get(attr, {})

static func get_slot_name(slot: String) -> String:
	return SLOT_NAMES.get(slot, slot)

static func get_material_main_attr(slot: String) -> String:
	return MATERIAL_MAIN_ATTR.get(slot, "")

static func get_cost_rate_by_material_attr(attr: String) -> float:
	var key: = str(attr).strip_edges().to_lower()
	if MATERIAL_COST_RATE.has(key):
		return float(MATERIAL_COST_RATE[key])
	return COST_RATE

static func calc_success_rate(forge_count: int, progress: float) -> float:
	if forge_count <= 0:
		return 1.0



	var remaining_ratio = clamp(1.0 - progress, 0.0, 1.0)
	var rate = remaining_ratio
	return clamp(rate, FORGE_MIN_SUCCESS_RATE, 1.0)
