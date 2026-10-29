extends Node
class_name PetSoulManager

signal soul_data_changed

const ELEMENT_KEYS: = ["金", "木", "水", "火", "土"]
const BONUS_CAP_PERCENT: = 100
const BONUS_FIRST_LEVEL_COST: = 10
const BONUS_LEVEL_STEP_COST: = 20

var _runtime_bonus_cap_percent: = BONUS_CAP_PERCENT
var _runtime_bonus_first_level_cost: = BONUS_FIRST_LEVEL_COST
var _runtime_growth_to_points_offset: = 5

var element_points: Dictionary = {
	"金": 0, 
	"木": 0, 
	"水": 0, 
	"火": 0, 
	"土": 0
}

func _normalize_element(element: String) -> String:
	var e: = str(element).strip_edges()
	if ELEMENT_KEYS.has(e):
		return e
	return "金"

func _normalize_points(points: Dictionary) -> Dictionary:
	var normalized: = {
		"金": 0, 
		"木": 0, 
		"水": 0, 
		"火": 0, 
		"土": 0
	}
	for key in normalized.keys():
		normalized[key] = maxi(0, int(points.get(key, 0)))
	return normalized

func growth_to_points(growth: float) -> int:
	var n: = int(floor(growth))
	return maxi(0, n - _runtime_growth_to_points_offset)

func apply_runtime_config(cfg: Variant) -> void :
	if cfg == null or not (cfg is Dictionary):
		return
	var d: Dictionary = cfg
	_runtime_bonus_cap_percent = maxi(1, int(d.get("bonusCapPercent", BONUS_CAP_PERCENT)))
	_runtime_bonus_first_level_cost = maxi(1, int(d.get("bonusFirstLevelCost", BONUS_FIRST_LEVEL_COST)))
	_runtime_growth_to_points_offset = maxi(0, int(d.get("growthToPointsOffset", 5)))
	soul_data_changed.emit()

func add_points(element: String, points: int) -> int:
	var e: = _normalize_element(element)
	var safe_points: = maxi(0, int(points))
	if safe_points <= 0:
		return 0
	element_points[e] = int(element_points.get(e, 0)) + safe_points
	soul_data_changed.emit()
	return safe_points

func add_points_from_pet(pet) -> Dictionary:
	var result: = {"success": false, "element": "", "added_points": 0}
	if pet == null:
		return result
	var added: = growth_to_points(float(pet.total_growth))
	if added <= 0:
		return result
	var e: = _normalize_element(str(pet.element))
	add_points(e, added)
	result.success = true
	result.element = e
	result.added_points = added
	return result

func get_points(element: String) -> int:
	return int(element_points.get(_normalize_element(element), 0))

func _required_total_points_for_percent(percent: int) -> int:



	var p: = maxi(0, percent)
	return int(_runtime_bonus_first_level_cost * p * p)

func get_bonus_percent(element: String) -> int:
	var points: = get_points(element)
	var bonus: = 0
	for p in range(1, _runtime_bonus_cap_percent + 1):
		if points >= _required_total_points_for_percent(p):
			bonus = p
		else:
			break
	return bonus

func get_progress(element: String) -> Dictionary:
	var e: = _normalize_element(element)
	var points: = get_points(e)
	var bonus: = get_bonus_percent(e)
	if bonus >= _runtime_bonus_cap_percent:
		return {
			"element": e, 
			"total_points": points, 
			"bonus_percent": _runtime_bonus_cap_percent, 
			"current_level_points": 0, 
			"next_level_points": 0, 
			"is_max": true
		}
	var current_required: = _required_total_points_for_percent(bonus)
	var next_required: = _required_total_points_for_percent(bonus + 1)
	return {
		"element": e, 
		"total_points": points, 
		"bonus_percent": bonus, 
		"current_level_points": maxi(0, points - current_required), 
		"next_level_points": maxi(1, next_required - current_required), 
		"is_max": false
	}

func get_bonus_for_pet(pet) -> int:
	if pet == null:
		return 0
	return get_bonus_percent(str(pet.element))

func to_dict() -> Dictionary:
	return {
		"element_points": _normalize_points(element_points)
	}

func from_dict(data: Variant) -> void :
	if data == null or not (data is Dictionary):
		element_points = _normalize_points({})
		return
	var d: Dictionary = data
	var raw_points: Dictionary = d.get("element_points", {}) if d.get("element_points", {}) is Dictionary else {}
	element_points = _normalize_points(raw_points)
	soul_data_changed.emit()
