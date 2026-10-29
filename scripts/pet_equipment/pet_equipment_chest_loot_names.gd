extends RefCounted
class_name PetEquipmentChestLootNames

const PetEquipment = preload("res://scripts/xianmo/pet_equipment.gd")



static var _fragment_by_base_name: Dictionary = {}


static func _ensure_lookup() -> void :
	if not _fragment_by_base_name.is_empty():
		return
	var tier_frag: = {"bronze": 1, "silver": 2, "gold": 3}
	var templates: Dictionary = PetEquipment.EQUIPMENT_TEMPLATES
	for tier_key in tier_frag.keys():
		var frag: int = int(tier_frag[tier_key])
		var per_quality: Variant = templates.get(tier_key)
		if not per_quality is Dictionary:
			continue
		for slot_enum in per_quality.keys():
			var piece: Variant = per_quality[slot_enum]
			if piece is Dictionary:
				var nm: = str(piece.get("name", "")).strip_edges()
				if not nm.is_empty():
					_fragment_by_base_name[nm] = frag


static func normalize_base_name(stored_name: String) -> String:
	var s: = str(stored_name).strip_edges()
	const suf: = "（宠）"
	if s.ends_with(suf):
		s = s.substr(0, s.length() - suf.length()).strip_edges()
	return s


static func fragment_count_by_base_name(base_name: String) -> int:
	_ensure_lookup()
	var k: = str(base_name).strip_edges()
	if _fragment_by_base_name.has(k):
		return int(_fragment_by_base_name[k])
	return -1
