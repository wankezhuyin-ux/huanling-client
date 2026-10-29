extends RefCounted
class_name FabaoWildStats

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")


static func current_tier() -> String:
	if GameManager.instance == null or GameManager.instance.fabao_manager == null:
		return "normal"
	return FabaoConfigRef.normalize_map_tier(GameManager.instance.fabao_manager.current_difficulty)


static func apply_to_monsters(monsters: Array) -> Array:
	var mul: = FabaoConfigRef.stat_mul(current_tier())
	if mul <= 1:
		return monsters
	for i in range(monsters.size()):
		var m = monsters[i]
		if m is Dictionary:
			_mul_dict(m, mul)
			monsters[i] = m
		elif m != null:
			_mul_obj(m, mul)
	return monsters


static func _mul_dict(m: Dictionary, mul: int) -> void :
	m["attack"] = int(m.get("attack", 0)) * mul
	m["defense"] = int(m.get("defense", 0)) * mul
	m["agility"] = int(m.get("agility", 0)) * mul
	m["hp"] = int(m.get("hp", 0)) * mul
	m["max_hp"] = int(m.get("max_hp", m.get("hp", 0))) * mul


static func _mul_obj(m, mul: int) -> void :
	if "attack" in m:
		m.attack = int(m.attack) * mul
	if "defense" in m:
		m.defense = int(m.defense) * mul
	if "agility" in m:
		m.agility = int(m.agility) * mul
	if "hp" in m:
		m.hp = int(m.hp) * mul
	if "max_hp" in m:
		m.max_hp = int(m.max_hp) * mul
