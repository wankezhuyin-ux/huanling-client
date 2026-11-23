extends Node
class_name MonsterDatabase





const MONSTER_DATA = {

	"tongbao": {
		"name": "通宝", 
		"pet_id": "tongbao", 
		"level": 1, 
		"element": "金", 
		"attack": 7, 
		"defense": 10, 
		"agility": 7, 
		"hp": 48, 
		"exp_reward": 100, 
		"gold_reward": 50, 
		"growth": 3.8, 
		"hp_growth": 2.9
	}, 
	"nawahuo": {
		"name": "纳瓦霍", 
		"pet_id": "nawahuo", 
		"level": 3, 
		"element": "木", 
		"attack": 14, 
		"defense": 10, 
		"agility": 6, 
		"hp": 62, 
		"exp_reward": 300, 
		"gold_reward": 160, 
		"growth": 3.8, 
		"hp_growth": 2.9
	}, 
	"feicuilong": {
		"name": "翡翠龙", 
		"pet_id": "feicuilong", 
		"level": 1, 
		"element": "水", 
		"attack": 8, 
		"defense": 6, 
		"agility": 8, 
		"hp": 50, 
		"exp_reward": 120, 
		"gold_reward": 60, 
		"growth": 3.6, 
		"hp_growth": 3.6
	}, 
	"bianyianu": {
		"name": "变异阿努", 
		"pet_id": "bianyianu", 
		"level": 1, 
		"element": "火", 
		"attack": 9, 
		"defense": 9, 
		"agility": 9, 
		"hp": 65, 
		"exp_reward": 120, 
		"gold_reward": 60, 
		"growth": 3.5, 
		"hp_growth": 3.5
	}, 
	"linlin": {
		"name": "琳琳", 
		"pet_id": "linlin", 
		"level": 4, 
		"element": "水", 
		"attack": 10, 
		"defense": 10, 
		"agility": 9, 
		"hp": 54, 
		"exp_reward": 400, 
		"gold_reward": 220, 
		"growth": 3.5, 
		"hp_growth": 2.7
	}, 
	"duxing": {
		"name": "独行", 
		"pet_id": "duxing", 
		"level": 4, 
		"element": "金", 
		"attack": 12, 
		"defense": 8, 
		"agility": 17, 
		"hp": 56, 
		"exp_reward": 400, 
		"gold_reward": 220, 
		"growth": 3.8, 
		"hp_growth": 2.9
	}, 
	"yùlíntù": {
		"name": "御林兔", 
		"pet_id": "yùlíntù", 
		"level": 5, 
		"element": "土", 
		"attack": 12, 
		"defense": 6, 
		"agility": 19, 
		"hp": 56, 
		"exp_reward": 500, 
		"gold_reward": 280, 
		"growth": 4.0, 
		"hp_growth": 2.9
	}, 
	"tiějiǎgūi": {
		"name": "铁甲龟", 
		"pet_id": "tiějiǎgūi", 
		"level": 9, 
		"element": "水", 
		"attack": 12, 
		"defense": 19, 
		"agility": 6, 
		"hp": 44, 
		"exp_reward": 900, 
		"gold_reward": 550, 
		"growth": 3.8, 
		"hp_growth": 2.9
	}, 
	"kuiluo": {
		"name": "盔螺", 
		"pet_id": "kuiluo", 
		"level": 10, 
		"element": "普通", 
		"attack": 13, 
		"defense": 20, 
		"agility": 7, 
		"hp": 54, 
		"exp_reward": 1000, 
		"gold_reward": 620, 
		"growth": 3.8, 
		"hp_growth": 2.9
	}
}


static func get_monster(monster_id: String) -> Dictionary:
	return MONSTER_DATA.get(monster_id, {})


static func get_monster_name(monster_id: String) -> String:
	var data = MONSTER_DATA.get(monster_id, {})
	return data.get("name", "未知怪物")


static func get_pet_id(monster_id: String) -> String:
	var data = MONSTER_DATA.get(monster_id, {})
	return data.get("pet_id", "")


static func has_monster(monster_id: String) -> bool:
	return MONSTER_DATA.has(monster_id)


static func get_all_monster_ids() -> Array:
	return MONSTER_DATA.keys()


const MAPS = {
	"浮光水城外郊（0,0）": {
		"min_level": 4, 
		"monsters": ["纳瓦霍", "琳琳"]
	}, 
	"盘桓林（0,0）": {
		"min_level": 5, 
		"monsters": ["独行", "御林兔"]
	}, 
	"盘桓林（39,54）": {
		"min_level": 5, 
		"monsters": ["御林兔"]
	}, 
	"浮光水城外郊（48,44）": {
		"min_level": 10, 
		"monsters": ["铁甲龟", "盔螺"]
	}
}


const MONSTERS = {
	"通宝": {
		"level": 1, 
		"element": "金"
	}, 
	"纳瓦霍": {
		"level": 3, 
		"element": "木"
	}, 
	"变异阿努": {
		"level": 1, 
		"element": "火"
	}, 
	"琳琳": {
		"level": 4, 
		"element": "水"
	}, 
	"独行": {
		"level": 4, 
		"element": "金"
	}, 
	"御林兔": {
		"level": 5, 
		"element": "土"
	}, 
	"铁甲龟": {
		"level": 9, 
		"element": "水"
	}, 
	"盔螺": {
		"level": 10, 
		"element": "普通"
	}
}
