extends Node
class_name ForgeManager

const ForgeConfig = preload("res://scripts/forge/forge_config.gd")
const ForgeData = preload("res://scripts/forge/forge_data.gd")
const ForgeRecord = preload("res://scripts/forge/forge_record.gd")

signal forge_success(result: Dictionary)
signal forge_failed(message: String)

var forge_data: ForgeData
var forge_history: Array = []

func _get_attr_forge_count(equipment: Dictionary, target_attr: String) -> int:
	var attr_counts = equipment.get("forge_attr_counts", {})
	if not (attr_counts is Dictionary):
		return 0
	return int(attr_counts.get(target_attr, 0))

func _set_attr_forge_count(equipment: Dictionary, target_attr: String, count: int):
	var attr_counts = equipment.get("forge_attr_counts", {})
	if not (attr_counts is Dictionary):
		attr_counts = {}
	attr_counts[target_attr] = max(0, count)
	equipment["forge_attr_counts"] = attr_counts

func _get_base_cultivation_req(equipment: Dictionary) -> int:

	if equipment.has("base_cultivation_req"):

		if not bool(equipment.get("is_suit", false)):
			return 0
		return max(0, int(equipment.get("base_cultivation_req", 0)))


	if bool(equipment.get("is_suit", false)):
		return max(0, int(equipment.get("cultivation_req", 0)))
	if equipment.has("cultivation_req"):
		return 0
	return 0

func _get_max_attr_forge_count(equipment: Dictionary) -> int:
	var attr_counts = equipment.get("forge_attr_counts", {})
	if not (attr_counts is Dictionary):
		return 0
	var max_count = 0
	for key in attr_counts.keys():
		max_count = max(max_count, int(attr_counts.get(key, 0)))
	return max_count

func _refresh_equipment_cultivation_req(equipment: Dictionary):
	var base_req = _get_base_cultivation_req(equipment)
	var max_count = _get_max_attr_forge_count(equipment)
	equipment["base_cultivation_req"] = base_req
	equipment["cultivation_req"] = base_req + max_count * ForgeConfig.FORGE_REQ_STEP_CULTIVATION

func _ready():
	forge_data = ForgeData.new()

func get_transferable_attributes(equipment_type: String) -> Array:
	var config = ForgeConfig.TRANSFER_CONFIG.get(equipment_type, {})
	var attrs = []
	for attr in config.keys():
		var attr_config = config[attr]
		attrs.append({
			"attribute": attr, 
			"attr_name": ForgeConfig.get_attr_name(attr), 
			"max_rate": attr_config.max_rate, 
			"per_transfer_min": attr_config.per_transfer[0], 
			"per_transfer_max": attr_config.per_transfer[1], 
			"cost_attr": attr_config.cost_attr, 
			"cost_attr_name": ForgeConfig.get_attr_name(attr_config.cost_attr), 
			"priority": attr_config.priority, 
		})
	attrs.sort_custom( func(a, b): return a.priority < b.priority)
	return attrs

func can_transfer(main_equipment: Dictionary, sub_equipment: Dictionary, target_attr: String) -> Dictionary:
	var result = {"can_transfer": false, "message": "", "info": {}}

	var main_type = main_equipment.get("slot", "")
	var sub_type = sub_equipment.get("slot", "")

	if main_type.is_empty() or sub_type.is_empty():
		result.message = "装备类型无效"
		return result

	var config = ForgeConfig.get_transfer_config(main_type, target_attr)
	if config.is_empty():
		result.message = "该装备不支持转移此属性"
		return result

	var material_attr = ForgeConfig.get_material_main_attr(sub_type)
	if material_attr != target_attr:
		result.message = "材料装备的主属性与目标属性不匹配"
		return result

	var current_value = main_equipment.get(target_attr, 0)
	var limit = ForgeConfig.get_limit_value(target_attr)
	var max_value = int(limit * config.max_rate)

	if current_value >= max_value:
		result.message = "该属性已达转移上限 (%d)" % max_value
		return result

	result.can_transfer = true
	result.info = {
		"current": current_value, 
		"limit": limit, 
		"max_rate": config.max_rate, 
		"max_value": max_value, 
		"per_transfer": config.per_transfer, 
		"cost_attr": config.cost_attr, 
		"remaining": max_value - current_value, 
	}

	return result

func preview_forge(main_equipment: Dictionary, sub_equipment: Dictionary, target_attr: String, player_cultivation: int = -1) -> Dictionary:
	_refresh_equipment_cultivation_req(main_equipment)
	var check = can_transfer(main_equipment, sub_equipment, target_attr)
	if not check.can_transfer:
		return {"valid": false, "message": check.message}

	var config = check.info
	var material_value = sub_equipment.get(target_attr, 0)

	var min_transfer = int(material_value * config.per_transfer[0])
	var max_transfer = int(material_value * config.per_transfer[1])

	max_transfer = min(max_transfer, config.remaining)
	min_transfer = min(min_transfer, config.remaining)

	var material_cost_rate: float = ForgeConfig.get_cost_rate_by_material_attr(target_attr)
	var min_cost = int(min_transfer * material_cost_rate)
	var max_cost = int(max_transfer * material_cost_rate)
	var forge_count = _get_attr_forge_count(main_equipment, target_attr)
	var progress = float(config.current) / float(config.max_value) if config.max_value > 0 else 0.0
	var success_rate = ForgeConfig.calc_success_rate(forge_count, progress)
	var base_req = _get_base_cultivation_req(main_equipment)
	var required_cultivation = base_req + forge_count * ForgeConfig.FORGE_REQ_STEP_CULTIVATION
	var next_required_cultivation = base_req + (forge_count + 1) * ForgeConfig.FORGE_REQ_STEP_CULTIVATION
	var can_forge = true
	var cultivation_message = ""
	if player_cultivation >= 0 and next_required_cultivation > player_cultivation:
		can_forge = false
		cultivation_message = "本次锻造后需求修行为%d，超过当前修行%d" % [next_required_cultivation, player_cultivation]

	return {
		"valid": true, 
		"min_transfer": min_transfer, 
		"max_transfer": max_transfer, 
		"min_cost": min_cost, 
		"max_cost": max_cost, 
		"cost_attr": config.cost_attr, 
		"remaining": config.remaining, 
		"success_rate": success_rate, 
		"required_cultivation": required_cultivation, 
		"next_required_cultivation": next_required_cultivation, 
		"forge_count": forge_count, 
		"can_forge": can_forge, 
		"cultivation_message": cultivation_message, 
	}

func forge(main_equipment: Dictionary, sub_equipment: Dictionary, target_attr: String, player_cultivation: int = -1) -> Dictionary:
	var result = {
		"success": false, 
		"message": "", 
		"equipment": null, 
		"details": {}, 
		"record": null, 
	}
	_refresh_equipment_cultivation_req(main_equipment)

	var check = can_transfer(main_equipment, sub_equipment, target_attr)
	if not check.can_transfer:
		result.message = check.message
		forge_failed.emit(result.message)
		return result

	var config = check.info
	var material_value = sub_equipment.get(target_attr, 0)
	var forge_count = _get_attr_forge_count(main_equipment, target_attr)
	var base_req = _get_base_cultivation_req(main_equipment)
	var required_cultivation = base_req + forge_count * ForgeConfig.FORGE_REQ_STEP_CULTIVATION
	var next_required = base_req + (forge_count + 1) * ForgeConfig.FORGE_REQ_STEP_CULTIVATION
	if player_cultivation >= 0 and next_required > player_cultivation:
		result.message = "锻造后装备修行需求%d，超过当前修行%d，无法锻造" % [next_required, player_cultivation]
		forge_failed.emit(result.message)
		return result

	if material_value <= 0:
		result.message = "材料装备属性不足"
		forge_failed.emit(result.message)
		return result

	var transfer_min = config.per_transfer[0]
	var transfer_max = config.per_transfer[1]
	var random_rate = randf_range(transfer_min, transfer_max)

	var transfer_value = int(material_value * random_rate)
	transfer_value = min(transfer_value, config.remaining)

	var cost_attr = config.cost_attr
	var material_cost_rate: float = ForgeConfig.get_cost_rate_by_material_attr(target_attr)
	var cost_value = int(transfer_value * material_cost_rate)
	var progress = float(config.current) / float(config.max_value) if config.max_value > 0 else 0.0
	var success_rate = ForgeConfig.calc_success_rate(forge_count, progress)
	var roll = randf()
	if roll > success_rate:
		result.message = "锻造失败！成功率%.1f%%（保底10%%）" % (success_rate * 100.0)
		result.details = {
			"success_rate": success_rate, 
			"required_cultivation": required_cultivation, 
			"forge_count": forge_count, 
			"is_first_forge": forge_count == 0, 
		}
		forge_failed.emit(result.message)
		return result

	main_equipment[target_attr] = config.current + transfer_value
	main_equipment[cost_attr] = main_equipment.get(cost_attr, 0) - cost_value
	main_equipment["base_cultivation_req"] = base_req
	_set_attr_forge_count(main_equipment, target_attr, forge_count + 1)
	_refresh_equipment_cultivation_req(main_equipment)

	var record = ForgeRecord.new({
		"main_equipment_id": main_equipment.get("id", ""), 
		"main_equipment_name": main_equipment.get("name", ""), 
		"sub_equipment_id": sub_equipment.get("id", ""), 
		"sub_equipment_name": sub_equipment.get("name", ""), 
		"transfer_attr": target_attr, 
		"transfer_value": transfer_value, 
		"cost_attr": cost_attr, 
		"cost_value": cost_value, 
		"random_rate": random_rate, 
		"success_rate": success_rate, 
		"required_cultivation": required_cultivation, 
		"forge_count": forge_count + 1, 
		"forge_attr": target_attr, 
	})
	forge_history.append(record)

	result.success = true
	result.equipment = main_equipment
	result.message = "锻造成功！%s +%d (%.1f%%)，%s -%d" % [
		ForgeConfig.get_attr_name(target_attr), transfer_value, random_rate * 100, 
		ForgeConfig.get_attr_name(cost_attr), cost_value
	]
	result.details = {
		"transfer_attr": target_attr, 
		"transfer_value": transfer_value, 
		"transfer_rate": random_rate, 
		"success_rate": success_rate, 
		"cost_attr": cost_attr, 
		"cost_value": cost_value, 
		"remaining_space": config.remaining - transfer_value, 
		"required_cultivation": required_cultivation, 
		"next_required_cultivation": next_required, 
		"forge_count": forge_count + 1, 
		"forge_attr": target_attr, 
	}
	result.record = record

	forge_success.emit(result)
	return result

func get_progress_info(main_equipment: Dictionary, target_attr: String) -> Dictionary:
	var main_type = main_equipment.get("slot", "")
	var config = ForgeConfig.get_transfer_config(main_type, target_attr)

	if config.is_empty():
		return {}

	var current = main_equipment.get(target_attr, 0)
	var limit = ForgeConfig.get_limit_value(target_attr)
	var max_value = int(limit * config.max_rate)
	var progress = float(current) / float(max_value) if max_value > 0 else 0.0

	var avg_transfer = int(limit * (config.per_transfer[0] + config.per_transfer[1]) / 2)
	var remaining_transfers = ceil(float(max_value - current) / avg_transfer) if avg_transfer > 0 else 0

	return {
		"current": current, 
		"max_value": max_value, 
		"progress": progress, 
		"remaining": max_value - current, 
		"avg_transfers_needed": remaining_transfers, 
	}

func get_forge_history() -> Array:
	return forge_history.duplicate()

func clear_history():
	forge_history.clear()

func get_limit_equipment_data() -> ForgeData:
	return forge_data
