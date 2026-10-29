


class_name PetCollectionData
extends RefCounted


const BONUS_TYPES = ["attack", "defense", "agility", "hp"]






const BONUS_VALUES = [
	0.0, 
	0.0008, 
	0.0016, 
	0.0024, 
	0.0032, 
	0.004, 
	0.0048, 
	0.0056, 
	0.0064, 
	0.0072, 
	0.008, 
	0.0084, 
	0.0088, 
	0.0092, 
	0.0096, 
	0.01, 
	0.0104, 
	0.0108, 
	0.0112, 
	0.0116, 
	0.012, 
	0.0124, 
	0.0128, 
	0.0132, 
	0.0136, 
	0.014, 
	0.0144, 
	0.0148, 
	0.0152, 
	0.0156, 
	0.016, 
	0.0161, 
	0.0162, 
	0.0163, 
	0.0164, 
	0.0165, 
	0.0166, 
	0.0167, 
	0.0168, 
	0.0169, 
	0.017, 
	0.0171, 
	0.0172, 
	0.0173, 
	0.0174, 
	0.0175, 
	0.0176, 
	0.0177, 
	0.0178, 
	0.0179, 
	0.018
]


const MUTATION_MAX: = 20
const MUTATION_BONUS_PER: = 0.0005



static func get_bonus_type(pet_id: String) -> String:
	var hash_value = pet_id.hash()
	var type_index = abs(hash_value) % 4
	return BONUS_TYPES[type_index]


static func get_bonus_type_name(bonus_type: String) -> String:
	match bonus_type:
		"attack": return "攻击"
		"defense": return "防御"
		"agility": return "敏捷"
		"hp": return "生命"
		_: return "未知"


static func get_bonus_value(count: int) -> float:
	if count < 0:
		count = 0
	if count > 50:
		count = 50
	return BONUS_VALUES[count]


static func get_next_bonus_value(current_count: int) -> float:
	if current_count >= 50:
		return BONUS_VALUES[50]
	return BONUS_VALUES[current_count + 1]


static func get_bonus_increase(current_count: int) -> float:
	if current_count >= 50:
		return 0.0
	return BONUS_VALUES[current_count + 1] - BONUS_VALUES[current_count]

static func clamp_mutation_count(count: int) -> int:
	return clampi(count, 0, MUTATION_MAX)

static func get_mutation_bonus_value(mutation_count: int) -> float:
	return float(clamp_mutation_count(mutation_count)) * MUTATION_BONUS_PER

static func get_species_total_bonus(normal_count: int, mutation_count: int) -> float:
	return get_bonus_value(normal_count) + get_mutation_bonus_value(mutation_count)


static func format_bonus_percent(bonus_fraction: float) -> String:
	return "%.2f" % (float(bonus_fraction) * 100.0)

static func format_bonus_percent_signed(bonus_fraction: float) -> String:
	return "+%.2f%%" % (float(bonus_fraction) * 100.0)
