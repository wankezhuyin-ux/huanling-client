extends RefCounted
class_name ForgeRecord

var timestamp: int
var main_equipment_id: String
var main_equipment_name: String
var sub_equipment_id: String
var sub_equipment_name: String
var transfer_attr: String
var transfer_value: int
var cost_attr: String
var cost_value: int
var random_rate: float

func _init(data: Dictionary = {}):
	timestamp = data.get("timestamp", Time.get_unix_time_from_system())
	main_equipment_id = data.get("main_equipment_id", "")
	main_equipment_name = data.get("main_equipment_name", "")
	sub_equipment_id = data.get("sub_equipment_id", "")
	sub_equipment_name = data.get("sub_equipment_name", "")
	transfer_attr = data.get("transfer_attr", "")
	transfer_value = data.get("transfer_value", 0)
	cost_attr = data.get("cost_attr", "")
	cost_value = data.get("cost_value", 0)
	random_rate = data.get("random_rate", 0.0)

func to_dict() -> Dictionary:
	return {
		"timestamp": timestamp, 
		"main_equipment_id": main_equipment_id, 
		"main_equipment_name": main_equipment_name, 
		"sub_equipment_id": sub_equipment_id, 
		"sub_equipment_name": sub_equipment_name, 
		"transfer_attr": transfer_attr, 
		"transfer_value": transfer_value, 
		"cost_attr": cost_attr, 
		"cost_value": cost_value, 
		"random_rate": random_rate, 
	}

static func from_dict(data: Dictionary) -> ForgeRecord:
	return ForgeRecord.new(data)

func get_summary() -> String:
	return "[%s] %s +%d (%.1f%%), %s -%d" % [
		main_equipment_name, 
		transfer_attr, 
		transfer_value, 
		random_rate * 100, 
		cost_attr, 
		cost_value
	]
