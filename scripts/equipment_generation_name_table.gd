extends RefCounted
class_name EquipmentGenerationNameTable





static func get_table() -> Dictionary:
	return {
		"weapon": {
			"common": ["新手木剑", "铁剑", "铜剑"], 
			"uncommon": ["玄铁剑", "寒冰剑", "烈火剑"], 
			"rare": ["天雷剑", "星辰剑", "破军剑"], 
			"epic": ["龙鳞剑", "凤羽剑", "神威剑"], 
			"legendary": ["混沌神剑", "仙灵剑", "天道剑"], 
			"mythic": ["大罗神剑", "金仙剑", "太虚剑"], 
			"divine": ["幻灵神剑", "天神剑", "至尊剑"]
		}, 
		"armor": {
			"common": ["布衣", "皮甲", "铁甲"], 
			"uncommon": ["玄铁甲", "寒冰甲", "烈火甲"], 
			"rare": ["天雷甲", "星辰甲", "破军甲"], 
			"epic": ["龙鳞甲", "凤羽甲", "神威甲"], 
			"legendary": ["混沌神甲", "仙灵甲", "天道甲"], 
			"mythic": ["大罗神甲", "金仙甲", "太虚甲"], 
			"divine": ["幻灵神甲", "天神甲", "至尊甲"]
		}, 
		"helmet": {
			"common": ["布帽", "皮帽", "铁盔"], 
			"uncommon": ["玄铁盔", "寒冰盔", "烈火盔"], 
			"rare": ["天雷盔", "星辰盔", "破军盔"], 
			"epic": ["龙鳞盔", "凤羽盔", "神威盔"], 
			"legendary": ["混沌神盔", "仙灵盔", "天道盔"], 
			"mythic": ["大罗神盔", "金仙盔", "太虚盔"], 
			"divine": ["幻灵神盔", "天神盔", "至尊盔"]
		}, 
		"boots": {
			"common": ["布鞋", "皮靴", "铁靴"], 
			"uncommon": ["玄铁靴", "寒冰靴", "烈火靴"], 
			"rare": ["天雷靴", "星辰靴", "破军靴"], 
			"epic": ["龙鳞靴", "凤羽靴", "神威靴"], 
			"legendary": ["混沌神靴", "仙灵靴", "天道靴"], 
			"mythic": ["大罗神靴", "金仙靴", "太虚靴"], 
			"divine": ["幻灵神靴", "天神靴", "至尊靴"]
		}, 
		"accessory": {
			"common": ["铜戒指", "铁戒指", "木项链"], 
			"uncommon": ["玄铁戒指", "寒冰玉佩", "烈火项链"], 
			"rare": ["天雷戒指", "星辰项链", "破军玉佩"], 
			"epic": ["凤羽项链", "神威玉佩", "天罚戒指"], 
			"legendary": ["混沌戒指", "仙灵项链", "天道玉佩"], 
			"mythic": ["大罗戒指", "金仙项链", "太虚玉佩"], 
			"divine": ["幻灵戒指", "天神项链", "至尊玉佩"]
		}
	}


static func pick_random_name(equip_slot: String, equip_rarity: String) -> String:
	var names: Dictionary = get_table()
	var slot_names: Dictionary = names.get(equip_slot, names["weapon"])
	var rarity_names: Array = slot_names.get(equip_rarity, slot_names["common"])
	if rarity_names.is_empty():
		rarity_names = slot_names["common"]
	return str(rarity_names[randi() % rarity_names.size()])
