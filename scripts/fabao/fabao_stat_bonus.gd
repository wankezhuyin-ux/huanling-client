extends RefCounted
class_name FabaoStatBonus

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")


static func _equipped() -> Dictionary:
	if GameManager.instance == null or GameManager.instance.fabao_manager == null:
		return {}
	var inst = GameManager.instance.fabao_manager.equipped_fabao
	if inst == null or not (inst is Dictionary):
		return {}
	return inst


static func player_pct(stat_key: String) -> float:
	return _sum_pct("player_" + stat_key)


static func pet_pct(stat_key: String) -> float:
	return _sum_pct("pet_" + stat_key)


static func exp_multiplier() -> float:
	var inst: = _equipped()
	if inst.is_empty():
		return 1.0
	var pct: = float(inst.get("exp_pct", FabaoConfigRef.exp_pct(str(inst.get("tier", "normal")))))
	return 1.0 + pct / 100.0


static func evolve_mutate_bonus() -> float:
	var inst: = _equipped()
	if inst.is_empty():
		return 0.0
	for aff in inst.get("affixes", []):
		if aff is Dictionary and str(aff.get("group", "")) == "evolve_mutate":
			return 0.01
	return 0.0


static func armor_pierce_bonus_rate() -> float:
	var inst: = _equipped()
	if inst.is_empty():
		return 0.0
	for aff in inst.get("affixes", []):
		if aff is Dictionary and str(aff.get("group", "")) == "armor_pierce_rate":
			var pct: = clampi(int(aff.get("value", 0)), 0, FabaoConfigRef.SPECIAL_ARMOR_PIERCE_CAP)
			return float(pct) / 100.0
	return 0.0


static func equipped_player_element() -> String:
	var inst: = _equipped()
	if inst.is_empty():
		return ""
	for aff in inst.get("affixes", []):
		if aff is Dictionary and str(aff.get("group", "")) == "player_element":
			var el: = str(aff.get("element", "")).strip_edges()
			if el in ["金", "木", "水", "火", "土"]:
				return el
	return ""


static func has_equipped_player_element() -> bool:
	return not equipped_player_element().is_empty()


static func is_player_element_enabled() -> bool:
	if GameManager.instance == null or GameManager.instance.player == null:
		return true
	return bool(GameManager.instance.player.use_fabao_player_element)


static func wild_player_element(fallback: String) -> String:
	if not is_player_element_enabled():
		return "普通"
	var el: = equipped_player_element()
	if not el.is_empty():
		return el
	var fb: = str(fallback).strip_edges()
	if fb.is_empty():
		return "普通"
	return fb


static func _sum_pct(group_id: String) -> float:
	var inst: = _equipped()
	if inst.is_empty():
		return 0.0
	for aff in inst.get("affixes", []):
		if aff is Dictionary and str(aff.get("group", "")) == group_id:
			return float(aff.get("value", 0.0))
	return 0.0


static func apply_player_base(base: int, stat_key: String) -> int:
	var pct: = player_pct(stat_key)
	if pct <= 0.0:
		return base
	return int(round(float(base) * (1.0 + pct / 100.0)))


static func apply_pet_base(base: float, stat_key: String) -> float:
	var pct: = pet_pct(stat_key)
	if pct <= 0.0:
		return base
	return base * (1.0 + pct / 100.0)
