extends Node
class_name QuestDatabase


enum QuestStatus{
	LOCKED, 
	AVAILABLE, 
	ACTIVE, 
	IN_PROGRESS, 
	COMPLETED, 
	FINISHED
}


enum QuestType{
	MAIN, 
	ELEMENT, 
	REALM, 
	DAILY, 
	ACHIEVEMENT, 
	TOWER, 
	PET, 
	SUIT
}


enum QuestConditionType{
	REACH_LEVEL, 
	REACH_REALM, 
	CLEAR_TOWER, 
	COMPLETE_TOWER, 
	CLEAR_SUIT_DUNGEON, 
	COMPLETE_SUIT_DUNGEON, 
	CAPTURE_PET, 
	EVOLVE_PET, 
	FUSE_PET, 
	KILL_MONSTER, 
	KILL_MONSTER_TYPE, 
	COMPLETE_MAP, 
	BATTLE_COUNT, 
	USE_ITEM, 
	COLLECT_ITEM, 
	EQUIP_ITEM, 
	REACH_PET_LEVEL, 
	COMPLETE_QUEST, 
	UNLOCK_PET_COLLECTION, 
	JOIN_XIANMO_BATTLE
}


enum ElementType{
	FIRE, 
	WATER, 
	WOOD, 
	EARTH, 
	METAL
}


const QUESTS = {

	"quest_001": {
		"id": "quest_001", 
		"name": "初入幻灵", 
		"description": "欢迎来到幻灵世界！在墨影城郊进行战斗，熟悉战斗系统。", 
		"type": QuestType.MAIN, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER, 
				"description": "在墨影城郊战斗", 
				"target": 3, 
				"current": 0, 
				"map": "浮光水城外郊（0,0）"
			}
		], 
		"rewards": {
			"exp": 500, 
			"gold": 10000, 
			"items": []
		}, 
		"next_quest": "quest_002"
	}, 
	"quest_002": {
		"id": "quest_002", 
		"name": "捕捉第一只宠物", 
		"description": "在战斗中捕捉一只宠物，它将成为你的战斗伙伴。", 
		"type": QuestType.MAIN, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉宠物", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 800, 
			"gold": 10000, 
			"items": []
		}, 
		"next_quest": "quest_003"
	}, 
	"quest_003": {
		"id": "quest_003", 
		"name": "提升实力", 
		"description": "通过战斗获得经验，将角色等级提升到10级。", 
		"type": QuestType.MAIN, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_LEVEL, 
				"description": "角色达到10级", 
				"target": 10, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 1000, 
			"gold": 20000, 
			"items": []
		}, 
		"next_quest": "quest_004"
	}, 
	"quest_004": {
		"id": "quest_004", 
		"name": "探索迷踪林", 
		"description": "前往迷踪林，挑战更强的怪物。", 
		"type": QuestType.MAIN, 
		"unlock_level": 5, 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER, 
				"description": "在迷踪林战斗", 
				"target": 5, 
				"current": 0, 
				"map": "盘桓林（0,0）"
			}
		], 
		"rewards": {
			"exp": 1500, 
			"gold": 30000, 
			"items": []
		}, 
		"next_quest": "quest_005"
	}, 
	"quest_005": {
		"id": "quest_005", 
		"name": "穿上装备", 
		"description": "穿戴任意一件装备，熟悉装备系统并提升战斗力。", 
		"type": QuestType.MAIN, 
		"unlock_level": 10, 
		"objectives": [
			{
				"type": QuestConditionType.EQUIP_ITEM, 
				"description": "装备任意一件装备", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 2000, 
			"gold": 50000, 
			"items": []
		}, 
		"next_quest": "quest_006"
	}, 
	"quest_006": {
		"id": "quest_006", 
		"name": "解锁宠物图鉴", 
		"description": "在宠物图鉴中激活一只宠物，获得属性加成。", 
		"type": QuestType.MAIN, 
		"unlock_level": 50, 
		"objectives": [
			{
				"type": QuestConditionType.UNLOCK_PET_COLLECTION, 
				"description": "激活宠物图鉴", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 3000, 
			"gold": 80000, 
			"items": ["悟道仙丹 x1"]
		}, 
		"next_quest": "quest_007"
	}, 
	"quest_007": {
		"id": "quest_007", 
		"name": "宠物进化", 
		"description": "将宠物培养到500级，为进化做准备。", 
		"type": QuestType.MAIN, 
		"unlock_level": 50, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "宠物达到500级", 
				"target": 500, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 5000, 
			"gold": 100000, 
			"items": []
		}, 
		"next_quest": "quest_008"
	}, 
	"quest_008": {
		"id": "quest_008", 
		"name": "挑战天关", 
		"description": "前往天关，挑战第5层，获得丰厚奖励。", 
		"type": QuestType.MAIN, 
		"unlock_level": 30, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第5层", 
				"target": 5, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 8000, 
			"gold": 200000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "quest_011"
	}, 
	"quest_009": {
		"id": "quest_009", 
		"name": "收集套装", 
		"description": "挑战套装副本，获得强力套装装备。", 
		"type": QuestType.MAIN, 
		"unlock_level": 40, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第1层", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 10000, 
			"gold": 300000, 
			"items": ["解封石 x2"]
		}, 
		"next_quest": null
	}, 
	"quest_010": {
		"id": "quest_010", 
		"name": "仙魔战场", 
		"description": "修行值达到1000后，参与仙魔战场，体验阵营对抗。", 
		"type": QuestType.MAIN, 
		"unlock_realm": "天仙", 
		"objectives": [
			{
				"type": QuestConditionType.JOIN_XIANMO_BATTLE, 
				"description": "参与仙魔战场", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 15000, 
			"gold": 400000, 
			"items": ["青铜匣 x1"]
		}, 
		"next_quest": "quest_009"
	}, 
	"quest_011": {
		"id": "quest_011", 
		"name": "飞升准备", 
		"description": "将角色等级提升到800级，达到飞升条件。", 
		"type": QuestType.MAIN, 
		"unlock_level": 800, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_LEVEL, 
				"description": "角色达到800级", 
				"target": 800, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 20000, 
			"gold": 500000, 
			"items": []
		}, 
		"next_quest": "quest_010"
	}, 


	"fire_001": {
		"id": "fire_001", 
		"name": "火焰初现", 
		"description": "火之试炼开始！在暮归路击败20只火系怪物，感受火焰的力量。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.FIRE, 
		"unlock_realm": "散仙", 
		"teleport_map": "暮还道（14,42）", 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER_TYPE, 
				"description": "击败火系怪物", 
				"target": 20, 
				"current": 0, 
				"element": "火"
			}
		], 
		"rewards": {
			"exp": 10000, 
			"gold": 50000, 
			"items": []
		}, 
		"next_quest": "fire_002"
	}, 
	"fire_002": {
		"id": "fire_002", 
		"name": "烈焰收集", 
		"description": "拥有一只火系宠物，这是修炼火系功法的关键助力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.FIRE, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "背包中拥有1只火系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "火", 
				"require_owned_pet": true
			}
		], 
		"rewards": {
			"exp": 15000, 
			"gold": 80000, 
			"items": []
		}, 
		"next_quest": "fire_003"
	}, 
	"fire_003": {
		"id": "fire_003", 
		"name": "火之宠物", 
		"description": "捕捉一只火系宠物，它将成为你火之试炼的伙伴！", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.FIRE, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉火系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "火"
			}
		], 
		"rewards": {
			"exp": 20000, 
			"gold": 100000, 
			"items": ["火纹蛋 x1"]
		}, 
		"next_quest": "fire_004"
	}, 
	"fire_004": {
		"id": "fire_004", 
		"name": "火之掌控", 
		"description": "将火系宠物培养到500级，完全掌控火焰之力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.FIRE, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "火系宠物达到500级", 
				"target": 500, 
				"current": 0, 
				"pet_element": "火"
			}
		], 
		"rewards": {
			"exp": 30000, 
			"gold": 150000, 
			"items": ["火纹蛋 x1"]
		}, 
		"next_quest": null
	}, 


	"water_001": {
		"id": "water_001", 
		"name": "流水初现", 
		"description": "水之试炼开始！在月影桥击败20只水系怪物，感受流水的柔和。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WATER, 
		"unlock_tower": 50, 
		"teleport_map": "明月桥（0,0）", 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER_TYPE, 
				"description": "击败水系怪物", 
				"target": 20, 
				"current": 0, 
				"element": "水"
			}
		], 
		"rewards": {
			"exp": 15000, 
			"gold": 80000, 
			"items": []
		}, 
		"next_quest": "water_002"
	}, 
	"water_002": {
		"id": "water_002", 
		"name": "寒冰收集", 
		"description": "拥有一只水系宠物，这是修炼水系功法的关键助力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WATER, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "背包中拥有1只水系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "水", 
				"require_owned_pet": true
			}
		], 
		"rewards": {
			"exp": 20000, 
			"gold": 100000, 
			"items": []
		}, 
		"next_quest": "water_003"
	}, 
	"water_003": {
		"id": "water_003", 
		"name": "水之宠物", 
		"description": "捕捉一只水系宠物，它将成为你水之试炼的伙伴！", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WATER, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉水系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "水"
			}
		], 
		"rewards": {
			"exp": 30000, 
			"gold": 150000, 
			"items": ["水纹蛋 x1"]
		}, 
		"next_quest": "water_004"
	}, 
	"water_004": {
		"id": "water_004", 
		"name": "水之掌控", 
		"description": "将水系宠物培养到500级，完全掌控流水之力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WATER, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "水系宠物达到500级", 
				"target": 500, 
				"current": 0, 
				"pet_element": "水"
			}
		], 
		"rewards": {
			"exp": 50000, 
			"gold": 250000, 
			"items": ["水纹蛋 x1"]
		}, 
		"next_quest": null
	}, 


	"wood_001": {
		"id": "wood_001", 
		"name": "翠木初现", 
		"description": "木之试炼开始！在青风野击败20只木系怪物，感受翠木的生机。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WOOD, 
		"unlock_realm": "地仙", 
		"teleport_map": "青岚原（52,36）", 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER_TYPE, 
				"description": "击败木系怪物", 
				"target": 20, 
				"current": 0, 
				"element": "木"
			}
		], 
		"rewards": {
			"exp": 20000, 
			"gold": 100000, 
			"items": []
		}, 
		"next_quest": "wood_002"
	}, 
	"wood_002": {
		"id": "wood_002", 
		"name": "墨木收集", 
		"description": "拥有一只木系宠物，这是修炼木系功法的关键助力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WOOD, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "背包中拥有1只木系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "木", 
				"require_owned_pet": true
			}
		], 
		"rewards": {
			"exp": 30000, 
			"gold": 150000, 
			"items": []
		}, 
		"next_quest": "wood_003"
	}, 
	"wood_003": {
		"id": "wood_003", 
		"name": "木之宠物", 
		"description": "捕捉一只木系宠物，它将成为你木之试炼的伙伴！", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WOOD, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉木系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "木"
			}
		], 
		"rewards": {
			"exp": 50000, 
			"gold": 250000, 
			"items": ["木纹蛋 x1"]
		}, 
		"next_quest": "wood_004"
	}, 
	"wood_004": {
		"id": "wood_004", 
		"name": "木之掌控", 
		"description": "将木系宠物培养到500级，完全掌控翠木之力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.WOOD, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "木系宠物达到500级", 
				"target": 500, 
				"current": 0, 
				"pet_element": "木"
			}
		], 
		"rewards": {
			"exp": 80000, 
			"gold": 400000, 
			"items": ["木纹蛋 x1"]
		}, 
		"next_quest": null
	}, 


	"earth_001": {
		"id": "earth_001", 
		"name": "大地初现", 
		"description": "土之试炼开始！在枯井野击败20只土系怪物，感受大地的厚重。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.EARTH, 
		"unlock_suit_dungeon": 1, 
		"teleport_map": "废井原（13,22）", 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER_TYPE, 
				"description": "击败土系怪物", 
				"target": 20, 
				"current": 0, 
				"element": "土"
			}
		], 
		"rewards": {
			"exp": 25000, 
			"gold": 150000, 
			"items": []
		}, 
		"next_quest": "earth_002"
	}, 
	"earth_002": {
		"id": "earth_002", 
		"name": "矿石收集", 
		"description": "拥有一只土系宠物，这是修炼土系功法的关键助力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.EARTH, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "背包中拥有1只土系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "土", 
				"require_owned_pet": true
			}
		], 
		"rewards": {
			"exp": 40000, 
			"gold": 200000, 
			"items": []
		}, 
		"next_quest": "earth_003"
	}, 
	"earth_003": {
		"id": "earth_003", 
		"name": "土之宠物", 
		"description": "捕捉一只土系宠物，它将成为你土之试炼的伙伴！", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.EARTH, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉土系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "土"
			}
		], 
		"rewards": {
			"exp": 60000, 
			"gold": 300000, 
			"items": ["土纹蛋 x1"]
		}, 
		"next_quest": "earth_004"
	}, 
	"earth_004": {
		"id": "earth_004", 
		"name": "土之掌控", 
		"description": "将土系宠物培养到500级，完全掌控大地之力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.EARTH, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "土系宠物达到500级", 
				"target": 500, 
				"current": 0, 
				"pet_element": "土"
			}
		], 
		"rewards": {
			"exp": 100000, 
			"gold": 500000, 
			"items": ["土纹蛋 x1"]
		}, 
		"next_quest": null
	}, 


	"metal_001": {
		"id": "metal_001", 
		"name": "金铁初现", 
		"description": "金之试炼开始！在望日桥头击败20只金系怪物，感受金铁的坚硬。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.METAL, 
		"unlock_realm": "天仙", 
		"teleport_map": "望日桥头（37,51）", 
		"objectives": [
			{
				"type": QuestConditionType.KILL_MONSTER_TYPE, 
				"description": "击败金系怪物", 
				"target": 20, 
				"current": 0, 
				"element": "金"
			}
		], 
		"rewards": {
			"exp": 30000, 
			"gold": 200000, 
			"items": []
		}, 
		"next_quest": "metal_002"
	}, 
	"metal_002": {
		"id": "metal_002", 
		"name": "黑铁收集", 
		"description": "拥有一只金系宠物，这是修炼金系功法的关键助力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.METAL, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "背包中拥有1只金系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "金", 
				"require_owned_pet": true
			}
		], 
		"rewards": {
			"exp": 50000, 
			"gold": 300000, 
			"items": []
		}, 
		"next_quest": "metal_003"
	}, 
	"metal_003": {
		"id": "metal_003", 
		"name": "金之宠物", 
		"description": "捕捉一只金系宠物，它将成为你金之试炼的伙伴！", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.METAL, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "捕捉金系宠物", 
				"target": 1, 
				"current": 0, 
				"pet_element": "金"
			}
		], 
		"rewards": {
			"exp": 80000, 
			"gold": 400000, 
			"items": ["金纹蛋 x1"]
		}, 
		"next_quest": "metal_004"
	}, 
	"metal_004": {
		"id": "metal_004", 
		"name": "金之掌控", 
		"description": "将金系宠物培养到500级，完全掌控金铁之力。", 
		"type": QuestType.ELEMENT, 
		"element": ElementType.METAL, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_PET_LEVEL, 
				"description": "金系宠物达到500级", 
				"target": 500, 
				"current": 0, 
				"pet_element": "金"
			}
		], 
		"rewards": {
			"exp": 150000, 
			"gold": 800000, 
			"items": ["金纹蛋 x1"]
		}, 
		"next_quest": null
	}, 


	"realm_001": {
		"id": "realm_001", 
		"name": "飞升成仙", 
		"description": "达到800级并飞升，成为散仙。", 
		"type": QuestType.REALM, 
		"unlock_level": 800, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_REALM, 
				"description": "达到散仙境界", 
				"target": 1, 
				"current": 0, 
				"realm": "散仙"
			}
		], 
		"rewards": {
			"exp": 50000, 
			"gold": 1000000, 
			"items": ["悟道仙丹 x5"]
		}, 
		"next_quest": "realm_002"
	}, 
	"realm_002": {
		"id": "realm_002", 
		"name": "地仙之路", 
		"description": "继续修炼，晋升地仙。", 
		"type": QuestType.REALM, 
		"unlock_realm": "散仙", 
		"objectives": [
			{
				"type": QuestConditionType.REACH_REALM, 
				"description": "达到地仙境界", 
				"target": 1, 
				"current": 0, 
				"realm": "地仙"
			}
		], 
		"rewards": {
			"exp": 100000, 
			"gold": 2000000, 
			"items": ["悟道仙丹 x5"]
		}, 
		"next_quest": "realm_003"
	}, 
	"realm_003": {
		"id": "realm_003", 
		"name": "天仙之境", 
		"description": "修为精进，晋升天仙。", 
		"type": QuestType.REALM, 
		"unlock_realm": "地仙", 
		"objectives": [
			{
				"type": QuestConditionType.REACH_REALM, 
				"description": "达到天仙境界", 
				"target": 1, 
				"current": 0, 
				"realm": "天仙"
			}
		], 
		"rewards": {
			"exp": 200000, 
			"gold": 5000000, 
			"items": ["悟道仙丹 x5"]
		}, 
		"next_quest": "realm_004"
	}, 
	"realm_004": {
		"id": "realm_004", 
		"name": "大罗金仙", 
		"description": "突破极限，成为大罗金仙。", 
		"type": QuestType.REALM, 
		"unlock_realm": "天仙", 
		"objectives": [
			{
				"type": QuestConditionType.REACH_REALM, 
				"description": "达到大罗金仙境界", 
				"target": 1, 
				"current": 0, 
				"realm": "大罗金仙"
			}
		], 
		"rewards": {
			"exp": 500000, 
			"gold": 10000000, 
			"items": ["悟道仙丹 x5"]
		}, 
		"next_quest": "realm_005"
	}, 
	"realm_005": {
		"id": "realm_005", 
		"name": "幻灵天神", 
		"description": "达到最高境界，成为幻灵天神。", 
		"type": QuestType.REALM, 
		"unlock_realm": "大罗金仙", 
		"objectives": [
			{
				"type": QuestConditionType.REACH_REALM, 
				"description": "达到幻灵天神境界", 
				"target": 1, 
				"current": 0, 
				"realm": "幻灵天神"
			}
		], 
		"rewards": {
			"exp": 1000000, 
			"gold": 20000000, 
			"items": ["悟道仙丹 x5", "百关锦囊·一 x1"]
		}, 
		"next_quest": null
	}, 


	"daily_001": {
		"id": "daily_001", 
		"name": "每日修炼", 
		"description": "进行10场战斗，提升战斗经验。", 
		"type": QuestType.DAILY, 
		"unlock_level": 5, 
		"objectives": [
			{
				"type": QuestConditionType.BATTLE_COUNT, 
				"description": "完成10场战斗", 
				"target": 10, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 0, 
			"gold": 20000000, 
			"items": ["天关锦囊 x1"]
		}
	}, 
	"daily_002": {
		"id": "daily_002", 
		"name": "天关挑战", 
		"description": "挑战天关5次，突破自我极限。", 
		"type": QuestType.DAILY, 
		"unlock_level": 20, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "挑战天关5次", 
				"target": 5, 
				"count_mode": true, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 0, 
			"gold": 20000000, 
			"items": ["天关锦囊 x1"]
		}
	}, 
	"daily_003": {
		"id": "daily_003", 
		"name": "宠物训练", 
		"description": "让宠物参与5场战斗，提升宠物实力。", 
		"type": QuestType.DAILY, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.BATTLE_COUNT, 
				"description": "宠物参与5场战斗", 
				"target": 5, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 0, 
			"gold": 20000000, 
			"items": ["天关锦囊 x1"]
		}
	}, 
	"daily_004": {
		"id": "daily_004", 
		"name": "套装收集", 
		"description": "通关套装副本3次，收集强力装备。", 
		"type": QuestType.DAILY, 
		"unlock_level": 50, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本3次", 
				"target": 3, 
				"count_mode": true, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 0, 
			"gold": 20000000, 
			"items": ["天关锦囊 x1"]
		}
	}, 


	"achievement_001": {
		"id": "achievement_001", 
		"name": "百战成名", 
		"description": "累计完成100场战斗，成为战斗达人。", 
		"type": QuestType.ACHIEVEMENT, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.BATTLE_COUNT, 
				"description": "累计完成100场战斗", 
				"target": 100, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 10000, 
			"gold": 200000, 
			"items": []
		}
	}, 
	"achievement_002": {
		"id": "achievement_002", 
		"name": "宠物大师", 
		"description": "累计捕捉50只宠物，成为宠物收集大师。", 
		"type": QuestType.ACHIEVEMENT, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.CAPTURE_PET, 
				"description": "累计捕捉50只宠物", 
				"target": 50, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 15000, 
			"gold": 300000, 
			"items": ["天关锦囊 x5"]
		}
	}, 
	"achievement_003": {
		"id": "achievement_003", 
		"name": "天关霸主", 
		"description": "通关天关达到100层，成为天关霸主。", 
		"type": QuestType.ACHIEVEMENT, 
		"unlock_level": 20, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关100层", 
				"target": 100, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 50000, 
			"gold": 1000000, 
			"items": ["百关锦囊·一 x1"]
		}
	}, 
	"achievement_005": {
		"id": "achievement_005", 
		"name": "登峰造极", 
		"description": "角色等级达到1000级，登峰造极。", 
		"type": QuestType.ACHIEVEMENT, 
		"unlock_level": 1, 
		"objectives": [
			{
				"type": QuestConditionType.REACH_LEVEL, 
				"description": "角色等级达到1000级", 
				"target": 1000, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 100000, 
			"gold": 2000000, 
			"items": ["高级解封石 x3"]
		}
	}, 


	"tower_001": {
		"id": "tower_001", 
		"name": "初探天关", 
		"description": "挑战天关，通关第10层，获得首次天关奖励。", 
		"type": QuestType.TOWER, 
		"unlock_level": 20, 
		"objectives": [
			{
				"type": QuestConditionType.CLEAR_TOWER, 
				"description": "通关天关第10层", 
				"target": 10, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 5000, 
			"gold": 10000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_002"
	}, 
	"tower_002": {
		"id": "tower_002", 
		"name": "天关进阶", 
		"description": "继续挑战天关，通关第50层。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第50层", 
				"target": 50, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 15000, 
			"gold": 30000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_003"
	}, 
	"tower_003": {
		"id": "tower_003", 
		"name": "天关勇士", 
		"description": "挑战天关第100层，成为天关勇士。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第100层", 
				"target": 100, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 30000, 
			"gold": 50000, 
			"items": ["百关锦囊·一 x1"]
		}, 
		"next_quest": "tower_004"
	}, 
	"tower_004": {
		"id": "tower_004", 
		"name": "天关精英", 
		"description": "挑战天关第150层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第150层", 
				"target": 150, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 45000, 
			"gold": 75000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_005"
	}, 
	"tower_005": {
		"id": "tower_005", 
		"name": "天关高手", 
		"description": "挑战天关第200层，成为天关高手。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第200层", 
				"target": 200, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 60000, 
			"gold": 100000, 
			"items": ["百关锦囊·二 x1"]
		}, 
		"next_quest": "tower_006"
	}, 
	"tower_006": {
		"id": "tower_006", 
		"name": "天关达人", 
		"description": "挑战天关第250层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第250层", 
				"target": 250, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 75000, 
			"gold": 125000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_007"
	}, 
	"tower_007": {
		"id": "tower_007", 
		"name": "天关大师", 
		"description": "挑战天关第300层，成为天关大师。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第300层", 
				"target": 300, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 90000, 
			"gold": 150000, 
			"items": ["百关锦囊·三 x1"]
		}, 
		"next_quest": "tower_008"
	}, 
	"tower_008": {
		"id": "tower_008", 
		"name": "天关宗师", 
		"description": "挑战天关第350层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第350层", 
				"target": 350, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 105000, 
			"gold": 175000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_009"
	}, 
	"tower_009": {
		"id": "tower_009", 
		"name": "天关王者", 
		"description": "挑战天关第400层，成为天关王者。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第400层", 
				"target": 400, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 120000, 
			"gold": 200000, 
			"items": ["百关锦囊·四 x1"]
		}, 
		"next_quest": "tower_010"
	}, 
	"tower_010": {
		"id": "tower_010", 
		"name": "天关霸主", 
		"description": "挑战天关第450层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第450层", 
				"target": 450, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 135000, 
			"gold": 225000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_011"
	}, 
	"tower_011": {
		"id": "tower_011", 
		"name": "天关至尊", 
		"description": "挑战天关第500层，成为天关至尊。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第500层", 
				"target": 500, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 150000, 
			"gold": 250000, 
			"items": ["百关锦囊·五 x1"]
		}, 
		"next_quest": "tower_012"
	}, 
	"tower_012": {
		"id": "tower_012", 
		"name": "天关圣者", 
		"description": "挑战天关第550层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第550层", 
				"target": 550, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 165000, 
			"gold": 275000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_013"
	}, 
	"tower_013": {
		"id": "tower_013", 
		"name": "天关神将", 
		"description": "挑战天关第600层，成为天关神将。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第600层", 
				"target": 600, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 180000, 
			"gold": 300000, 
			"items": ["百关锦囊·六 x1"]
		}, 
		"next_quest": "tower_014"
	}, 
	"tower_014": {
		"id": "tower_014", 
		"name": "天关仙尊", 
		"description": "挑战天关第650层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第650层", 
				"target": 650, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 195000, 
			"gold": 325000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_015"
	}, 
	"tower_015": {
		"id": "tower_015", 
		"name": "天关帝皇", 
		"description": "挑战天关第700层，成为天关帝皇。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第700层", 
				"target": 700, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 210000, 
			"gold": 350000, 
			"items": ["百关锦囊·七 x1"]
		}, 
		"next_quest": "tower_016"
	}, 
	"tower_016": {
		"id": "tower_016", 
		"name": "天关天尊", 
		"description": "挑战天关第750层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第750层", 
				"target": 750, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 225000, 
			"gold": 375000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_017"
	}, 
	"tower_017": {
		"id": "tower_017", 
		"name": "天关神王", 
		"description": "挑战天关第800层，成为天关神王。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第800层", 
				"target": 800, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 240000, 
			"gold": 400000, 
			"items": ["百关锦囊·八 x1"]
		}, 
		"next_quest": "tower_018"
	}, 
	"tower_018": {
		"id": "tower_018", 
		"name": "天关圣王", 
		"description": "挑战天关第850层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第850层", 
				"target": 850, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 255000, 
			"gold": 425000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_019"
	}, 
	"tower_019": {
		"id": "tower_019", 
		"name": "天关神皇", 
		"description": "挑战天关第900层，成为天关神皇。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第900层", 
				"target": 900, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 270000, 
			"gold": 450000, 
			"items": ["百关锦囊·九 x1"]
		}, 
		"next_quest": "tower_020"
	}, 
	"tower_020": {
		"id": "tower_020", 
		"name": "天关至尊王", 
		"description": "挑战天关第950层，证明你的实力。", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第950层", 
				"target": 950, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 285000, 
			"gold": 475000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "tower_021"
	}, 
	"tower_021": {
		"id": "tower_021", 
		"name": "天关传说", 
		"description": "挑战天关第2000层，成为天关传说！", 
		"type": QuestType.TOWER, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_TOWER, 
				"description": "通关天关第2000层", 
				"target": 2000, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 300000, 
			"gold": 500000, 
			"items": ["百关锦囊·二十 x1"]
		}
	}, 


	"pet_001": {
		"id": "pet_001", 
		"name": "宠物进化师", 
		"description": "将一只宠物进化到一进形态，提升宠物实力。", 
		"type": QuestType.PET, 
		"unlock_level": 500, 
		"objectives": [
			{
				"type": QuestConditionType.EVOLVE_PET, 
				"description": "进化宠物到成年期", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 10000, 
			"gold": 20000, 
			"items": ["天关锦囊 x1"]
		}, 
		"next_quest": "pet_002"
	}, 
	"pet_002": {
		"id": "pet_002", 
		"name": "宠物幻化师", 
		"description": "成功幻化一只宠物，获得更强的属性。", 
		"type": QuestType.PET, 
		"unlock_level": 800, 
		"objectives": [
			{
				"type": QuestConditionType.FUSE_PET, 
				"description": "幻化宠物", 
				"target": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"exp": 20000, 
			"gold": 40000, 
			"items": ["天关锦囊 x1"]
		}
	}, 


	"suit_001": {
		"id": "suit_001", 
		"name": "套装入门", 
		"description": "通关套装副本第1层，获得第一件套装装备。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第1层", 
				"floor": 1, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 1500000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_002"
	}, 
	"suit_002": {
		"id": "suit_002", 
		"name": "套装探索", 
		"description": "通关套装副本第2层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第2层", 
				"floor": 2, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 1950000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_003"
	}, 
	"suit_003": {
		"id": "suit_003", 
		"name": "套装收集", 
		"description": "通关套装副本第3层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第3层", 
				"floor": 3, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 2400000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_004"
	}, 
	"suit_004": {
		"id": "suit_004", 
		"name": "套装积累", 
		"description": "通关套装副本第4层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第4层", 
				"floor": 4, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 2850000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_005"
	}, 
	"suit_005": {
		"id": "suit_005", 
		"name": "套装强化", 
		"description": "通关套装副本第5层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第5层", 
				"floor": 5, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 3300000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_006"
	}, 
	"suit_006": {
		"id": "suit_006", 
		"name": "套装进阶", 
		"description": "通关套装副本第6层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第6层", 
				"floor": 6, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 3750000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_007"
	}, 
	"suit_007": {
		"id": "suit_007", 
		"name": "套装精通", 
		"description": "通关套装副本第7层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第7层", 
				"floor": 7, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 4200000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_008"
	}, 
	"suit_008": {
		"id": "suit_008", 
		"name": "套装大师", 
		"description": "通关套装副本第8层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第8层", 
				"floor": 8, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 4650000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_009"
	}, 
	"suit_009": {
		"id": "suit_009", 
		"name": "套装专家", 
		"description": "通关套装副本第9层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第9层", 
				"floor": 9, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 5100000, 
			"items": ["解封石 x1"]
		}, 
		"next_quest": "suit_010"
	}, 
	"suit_010": {
		"id": "suit_010", 
		"name": "套装收藏家", 
		"description": "通关套装副本第10层，收集更多套装部件。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第10层", 
				"floor": 10, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 5550000, 
			"items": ["解封石 x2"]
		}, 
		"next_quest": "suit_011"
	}, 
	"suit_011": {
		"id": "suit_011", 
		"name": "套装精英", 
		"description": "通关套装副本第11层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第11层", 
				"floor": 11, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 6000000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_012"
	}, 
	"suit_012": {
		"id": "suit_012", 
		"name": "套装勇士", 
		"description": "通关套装副本第12层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第12层", 
				"floor": 12, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 6450000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_013"
	}, 
	"suit_013": {
		"id": "suit_013", 
		"name": "套装英雄", 
		"description": "通关套装副本第13层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第13层", 
				"floor": 13, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 6900000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_014"
	}, 
	"suit_014": {
		"id": "suit_014", 
		"name": "套装传说", 
		"description": "通关套装副本第14层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第14层", 
				"floor": 14, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 7350000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_015"
	}, 
	"suit_015": {
		"id": "suit_015", 
		"name": "套装神话", 
		"description": "通关套装副本第15层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第15层", 
				"floor": 15, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 7800000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_016"
	}, 
	"suit_016": {
		"id": "suit_016", 
		"name": "套装至尊", 
		"description": "通关套装副本第16层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第16层", 
				"floor": 16, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 8250000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_017"
	}, 
	"suit_017": {
		"id": "suit_017", 
		"name": "套装圣者", 
		"description": "通关套装副本第17层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第17层", 
				"floor": 17, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 8700000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_018"
	}, 
	"suit_018": {
		"id": "suit_018", 
		"name": "套装王者", 
		"description": "通关套装副本第18层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第18层", 
				"floor": 18, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 9150000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_019"
	}, 
	"suit_019": {
		"id": "suit_019", 
		"name": "套装帝皇", 
		"description": "通关套装副本第19层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第19层", 
				"floor": 19, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 9600000, 
			"items": ["高级解封石 x1"]
		}, 
		"next_quest": "suit_020"
	}, 
	"suit_020": {
		"id": "suit_020", 
		"name": "套装天尊", 
		"description": "通关套装副本第20层，挑战更高难度。", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第20层", 
				"floor": 20, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 10050000, 
			"items": ["高级解封石 x2"]
		}, 
		"next_quest": "suit_021"
	}, 
	"suit_021": {
		"id": "suit_021", 
		"name": "套装巅峰", 
		"description": "通关套装副本第21层，登顶套装副本！", 
		"type": QuestType.SUIT, 
		"objectives": [
			{
				"type": QuestConditionType.COMPLETE_SUIT_DUNGEON, 
				"description": "通关套装副本第21层", 
				"floor": 21, 
				"current": 0
			}
		], 
		"rewards": {
			"gold": 10500000, 
			"items": ["高级解封石 x3"]
		}
	}
}




static func get_all_quest_ids() -> Array:
	return QUESTS.keys()


static func get_quest(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})


static func get_quests_by_type(quest_type: int) -> Array:
	var result = []
	var quest_ids = []
	for quest_id in QUESTS:
		var quest = QUESTS[quest_id]
		if quest.get("type", -1) == quest_type:
			quest_ids.append(quest_id)

	quest_ids.sort()
	for quest_id in quest_ids:
		result.append(QUESTS[quest_id])

	return result


static func get_quest_type_name(quest_type: int) -> String:
	match quest_type:
		QuestType.MAIN:
			return "主线"
		QuestType.ELEMENT:
			return "元素"
		QuestType.REALM:
			return "境界"
		QuestType.DAILY:
			return "日常"
		QuestType.ACHIEVEMENT:
			return "成就"
		QuestType.TOWER:
			return "天关"
		QuestType.PET:
			return "宠物"
		QuestType.SUIT:
			return "套装"
		_:
			return "未知"


static func get_quest_status_name(status: int) -> String:
	match status:
		QuestStatus.LOCKED:
			return "未解锁"
		QuestStatus.AVAILABLE, QuestStatus.ACTIVE:
			return "进行中"
		QuestStatus.IN_PROGRESS:
			return "进行中"
		QuestStatus.COMPLETED:
			return "已完成"
		QuestStatus.FINISHED:
			return "已结束"
		_:
			return "未知"
