extends Node


const MAX_LEVEL_EVOLUTION = 1200
const MAX_LEVEL_NORMAL = 1500
const MAX_PLAYER_REINCARNATION = 2000
const MAX_PETS = 10
const MAX_PET_BAG = 50
const TALENT_MAX_PER_STAT = 30
const TALENT_RESET_YUANBAO_COST = 100


static func permanent_points_floor(rei: int) -> int:
	var r: int = maxi(0, rei)
	if r <= 0:
		return 0
	if r <= 999:
		return r * 25
	return 999 * 25 + (r - 999) * 10


static func permanent_delta_on_reincarnate(new_rei: int) -> int:
	if new_rei <= 0:
		return 0
	return 10 if new_rei >= 1000 else 25


static func talent_points_earned(rei: int) -> int:
	var r: int = maxi(0, rei)
	if r < 500:
		return 0
	return int((r - 500) / 50) + 1


const EVENT_PET_LIBRARY = {
	"bianyianu": {
		"name": "变异阿努", 
		"type": "平均型", 
		"element": "火", 
		"attack": 9.0, 
		"defense": 9.0, 
		"agility": 9.0, 
		"hp": 65.0, 
		"growth": 3.5, 
		"hp_growth": 3.5, 
		"ratio": [33, 33, 34], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "五一节日活动宠物"
	}, 
	"feicuilong": {
		"name": "翡翠龙", 
		"type": "平均型", 
		"element": "水", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "端午节活动宠物"
	}, 
	"qixitu": {
		"name": "七夕兔", 
		"type": "平均型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "七夕节活动宠物"
	}, 
	"zhongqiujinhu": {
		"name": "中秋金虎", 
		"type": "平均型", 
		"element": "金", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "中秋节活动宠物"
	}, 
	"nezha": {
		"name": "哪吒", 
		"type": "平均型", 
		"element": "火", 
		"attack": 10.0, 
		"defense": 10.0, 
		"agility": 10.0, 
		"hp": 70.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "贵族10专属奖励"
	}, 

	"huangyidaonan": {
		"name": "刀男", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"maiduo": {
		"name": "麦朵", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shuangyanzhan": {
		"name": "双炎斩", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 12.0, 
		"defense": 18.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [39, 60, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"heicaishen": {
		"name": "黑财神", 
		"type": "攻防型", 
		"element": "天", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"lianyugulong": {
		"name": "炼狱骨龙", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 14.0, 
		"defense": 1.0, 
		"agility": 15.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 1, 54], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"zhusisi": {
		"name": "猪丝丝", 
		"type": "防御型", 
		"element": "木", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shizizuo": {
		"name": "狮子座", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 17.0, 
		"defense": 1.0, 
		"agility": 12.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [58, 1, 41], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"yuzu": {
		"name": "狱卒", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"yizhanmafu": {
		"name": "驿站马夫", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 26.0, 
		"defense": 1.0, 
		"agility": 3.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [90, 1, 9], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"kezhanmeimei": {
		"name": "客栈妹妹", 
		"type": "防御型", 
		"element": "水", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shaiziwangwu": {
		"name": "骰子王五", 
		"type": "防御型", 
		"element": "火", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"songbukuai": {
		"name": "宋捕快", 
		"type": "防御型", 
		"element": "金", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"cailin": {
		"name": "彩鳞", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"goumang": {
		"name": "句芒", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"qingqiujiuwei": {
		"name": "青丘九尾", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 20.0, 
		"defense": 1.0, 
		"agility": 9.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [66, 1, 33], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"longzhanjiang": {
		"name": "龙战将", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
}


const SOUL_REWARD_PET_LIBRARY = {
	"chulong": {
		"name": "雏龙", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"shalongzhiren": {
		"name": "杀龙之刃", 
		"type": "攻敏型", 
		"element": "金", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"xianrenzhang": {
		"name": "仙人掌", 
		"type": "攻敏型", 
		"element": "木", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"yinying": {
		"name": "阴影", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"shitouren": {
		"name": "石头人", 
		"type": "防御型", 
		"element": "土", 
		"attack": 11.0, 
		"defense": 15.0, 
		"agility": 4.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [38, 50, 12], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
}


const WORLD_BOSS_PET_LIBRARY = {
	"huozhiyizhi": {
		"name": "火之意志", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"jinzhizhuzai": {
		"name": "金之主宰", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"muzhiguize": {
		"name": "木之规则", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"tuzhixianjie": {
		"name": "土之限界", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"shuizhizhangkong": {
		"name": "水之掌控", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
}


const PET_REFINE_POOL_WEIGHTS = {
	"common": 80, 
	"rare": 18, 
	"ultra_rare": 2
}
const PET_REFINE_ULTRA_RARE_CHAIN_IDS = [
	"shuijinger", "jingtianshi", "mengjingling", "huanjinggang", 
	"mengjinger", "mengtianshi", "mengjinggang", "liuyitianshi", 
	"a_di_da_si", "a_ge_liu_si", "a_nu_bi_si", "chao_ji_a_nu"
]


const REALMS = ["凡人", "散仙", "地仙", "天仙", "大罗金仙", "幻灵天神"]

const ASCENSION_CONDITIONS = {
	"凡人": {"required_level": 800, "next_realm": "散仙"}, 
	"散仙": {"required_level": 800, "next_realm": "地仙"}, 
	"地仙": {"required_level": 1000, "next_realm": "天仙"}, 
	"天仙": {"required_level": 1000, "next_realm": "大罗金仙"}, 
	"大罗金仙": {"required_level": 1000, "next_realm": "幻灵天神"}
}


const FIVE_ELEMENTS = ["金", "木", "水", "火", "土"]

const ELEMENT_SKY = "天"

const ELEMENT_COUNTER = {
	"金": "木", 
	"木": "土", 
	"土": "水", 
	"水": "火", 
	"火": "金"
}

const ELEMENT_GENERATE = {
	"金": "水", 
	"水": "木", 
	"木": "火", 
	"火": "土", 
	"土": "金"
}


static func get_element_that_counters(target_element: String) -> String:
	var target: = str(target_element).strip_edges()
	if target not in FIVE_ELEMENTS:
		return ""
	for attacker_el in ELEMENT_COUNTER.keys():
		if ELEMENT_COUNTER[attacker_el] == target:
			return str(attacker_el)
	return ""


static func is_sky_vs_five_element(attacker_element: String, defender_element: String) -> bool:
	var atk: = str(attacker_element).strip_edges()
	var deff: = str(defender_element).strip_edges()
	if atk == ELEMENT_SKY and deff in FIVE_ELEMENTS:
		return true
	if deff == ELEMENT_SKY and atk in FIVE_ELEMENTS:
		return true
	return false


static func get_pet_soul_lookup_element(attacker_element: String, defender_element: String) -> String:
	var atk: = str(attacker_element).strip_edges()
	var deff: = str(defender_element).strip_edges()
	if atk == ELEMENT_SKY:
		return get_element_that_counters(deff)
	return atk


const EQUIPMENT_RARITY = {
	"common": {"name": "普通", "color": Color(0.93, 0.94, 0.95), "multiplier": 1.0}, 
	"uncommon": {"name": "优秀", "color": Color(0.15, 0.68, 0.38), "multiplier": 1.5}, 
	"rare": {"name": "稀有", "color": Color(0.2, 0.6, 0.86), "multiplier": 2.0}, 
	"epic": {"name": "史诗", "color": Color(0.61, 0.35, 0.71), "multiplier": 3.0}, 
	"legendary": {"name": "传说", "color": Color(0.95, 0.61, 0.07), "multiplier": 4.0}, 
	"mythic": {"name": "神话", "color": Color(1.0, 0.42, 0.42), "multiplier": 5.0}, 
	"divine": {"name": "至尊", "color": Color(1.0, 0.84, 0.0), "multiplier": 6.25}
}


const EQUIPMENT_SLOTS = {
	"weapon": "武器", 
	"armor": "衣服", 
	"helmet": "帽子", 
	"boots": "鞋子", 
	"accessory": "饰品"
}



const MAPS_DATA = {
	"浮光水城外郊（0,0）": {
		"id": "100014", 
		"name": "浮光水城外郊（0,0）", 
		"level": 4, 
		"description": "浮光水城外郊 - 坐标(0,0)", 
		"spawn_min": 1, 
		"spawn_max": 2, 
		"monsters": [
			{"id": "nawahuo"}, 
			{"id": "linlin"}
		]
	}, 
	"盘桓林（0,0）": {
		"id": "700000", 
		"name": "盘桓林（0,0）", 
		"level": 5, 
		"description": "盘桓林 - 坐标(0,0)", 
		"monsters": [
			{"id": "duxing"}, 
			{"id": "yùlíntù"}
		]
	}, 
	"盘桓林（39,54）": {
		"id": "700000", 
		"name": "盘桓林（39,54）", 
		"level": 5, 
		"description": "盘桓林 - 坐标(39,54)", 
		"monsters": [
			{"pet_id": "yùlíntù", "level": 4}, 
			{"pet_id": "yùlíntù", "level": 5}, 
		]
	}, 
	"浮光水城外郊（48,44）": {
		"id": "100014", 
		"name": "浮光水城外郊（48,44）", 
		"level": 10, 
		"description": "浮光水城外郊 - 坐标(48,44)", 
		"monsters": [
			{"id": "tiějiǎgūi"}, 
			{"id": "kuiluo"}
		]
	}, 
	"紫阳门（0,0）": {
		"id": "500008", 
		"name": "紫阳门（0,0）", 
		"level": 12, 
		"description": "紫阳门 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdōng", "level": 10}, 
			{"pet_id": "lèngtóuqīng", "level": 12}, 
		]
	}, 
	"紫阳门（45,35）": {
		"id": "500008", 
		"name": "紫阳门（45,35）", 
		"level": 12, 
		"description": "紫阳门 - 坐标(45,35)", 
		"monsters": [
			{"pet_id": "xiǎodīngdōng", "level": 10}, 
			{"pet_id": "xiǎodīngdōng", "level": 12}, 
		]
	}, 
	"冰封地狱（0,0）": {
		"id": "600000", 
		"name": "冰封地狱（0,0）", 
		"level": 12, 
		"description": "冰封地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zǐtíxiānshēng", "level": 10}, 
			{"pet_id": "dàdāo", "level": 12}, 
		]
	}, 
	"冰封地狱（34,39）": {
		"id": "600000", 
		"name": "冰封地狱（34,39）", 
		"level": 12, 
		"description": "冰封地狱 - 坐标(34,39)", 
		"monsters": [
			{"pet_id": "zǐtíxiānshēng", "level": 10}, 
			{"pet_id": "zǐtíxiānshēng", "level": 12}, 
		]
	}, 
	"暮还道（0,0）": {
		"id": "700007", 
		"name": "暮还道（0,0）", 
		"level": 15, 
		"description": "暮还道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lányá", "level": 10}, 
			{"pet_id": "daicitou", "level": 15}, 
		]
	}, 
	"暮还道（14,42）": {
		"id": "700007", 
		"name": "暮还道（14,42）", 
		"level": 15, 
		"description": "暮还道 - 坐标(14,42)", 
		"monsters": [
			{"pet_id": "xiǎoyāo", "level": 10}, 
			{"pet_id": "xiǎoyāo", "level": 15}, 
		]
	}, 
	"青岚原（0,0）": {
		"id": "100011", 
		"name": "青岚原（0,0）", 
		"level": 20, 
		"description": "青岚原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 15}, 
			{"pet_id": "tongbao", "level": 20}, 
		]
	}, 
	"青岚原（52,36）": {
		"id": "100011", 
		"name": "青岚原（52,36）", 
		"level": 20, 
		"description": "青岚原 - 坐标(52,36)", 
		"monsters": [
			{"pet_id": "shundi", "level": 15}, 
			{"pet_id": "lu_lu", "level": 20}, 
		]
	}, 
	"浮光水城外郊（43,20）": {
		"id": "100014", 
		"name": "浮光水城外郊（43,20）", 
		"level": 25, 
		"description": "浮光水城外郊 - 坐标(43,20)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 20}, 
			{"pet_id": "yingying", "level": 25}, 
		]
	}, 
	"青岚原（51,80）": {
		"id": "100011", 
		"name": "青岚原（51,80）", 
		"level": 30, 
		"description": "青岚原 - 坐标(51,80)", 
		"monsters": [
			{"pet_id": "hòupíè", "level": 25}, 
			{"pet_id": "zhaicitou", "level": 30}, 
		]
	}, 
	"凝泪岗（0,0）": {
		"id": "100015", 
		"name": "凝泪岗（0,0）", 
		"level": 35, 
		"description": "凝泪岗 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "yingying", "level": 30}, 
			{"pet_id": "qíshìgūi", "level": 35}, 
		]
	}, 
	"凝泪岗（27,18）": {
		"id": "100015", 
		"name": "凝泪岗（27,18）", 
		"level": 35, 
		"description": "凝泪岗 - 坐标(27,18)", 
		"monsters": [
			{"pet_id": "yingying", "level": 30}, 
			{"pet_id": "yingying", "level": 35}, 
		]
	}, 
	"凌云台（0,0）": {
		"id": "500006", 
		"name": "凌云台（0,0）", 
		"level": 35, 
		"description": "凌云台 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiàngpíshǔ", "level": 30}, 
			{"pet_id": "mìmìxióng", "level": 35}, 
		]
	}, 
	"凌云台（47,46）": {
		"id": "500006", 
		"name": "凌云台（47,46）", 
		"level": 35, 
		"description": "凌云台 - 坐标(47,46)", 
		"monsters": [
			{"pet_id": "xiàngpíshǔ", "level": 30}, 
			{"pet_id": "xiàngpíshǔ", "level": 35}, 
		]
	}, 
	"暴走地狱（0,0）": {
		"id": "600004", 
		"name": "暴走地狱（0,0）", 
		"level": 35, 
		"description": "暴走地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 30}, 
			{"pet_id": "yáoyé", "level": 35}, 
		]
	}, 
	"踏雪原（0,0）": {
		"id": "300010", 
		"name": "踏雪原（0,0）", 
		"level": 40, 
		"description": "踏雪原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "huanbiantianlang", "level": 30}, 
			{"pet_id": "tao_tao", "level": 40}, 
		]
	}, 
	"踏雪原（60,36）": {
		"id": "300010", 
		"name": "踏雪原（60,36）", 
		"level": 40, 
		"description": "踏雪原 - 坐标(60,36)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 30}, 
			{"pet_id": "tao_tao", "level": 40}, 
		]
	}, 
	"四津原（0,0）": {
		"id": "100010", 
		"name": "四津原（0,0）", 
		"level": 50, 
		"description": "四津原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "kucitou", "level": 40}, 
			{"pet_id": "nununiao", "level": 50}, 
		]
	}, 
	"明月桥（0,0）": {
		"id": "100016", 
		"name": "明月桥（0,0）", 
		"level": 60, 
		"description": "明月桥 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàzǔiè", "level": 50}, 
			{"pet_id": "tiějiǎgūi", "level": 60}, 
		]
	}, 
	"废井原（0,0）": {
		"id": "100021", 
		"name": "废井原（0,0）", 
		"level": 60, 
		"description": "废井原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhaicitou", "level": 50}, 
			{"pet_id": "duxing", "level": 60}, 
		]
	}, 
	"废井原（38,26）": {
		"id": "100021", 
		"name": "废井原（38,26）", 
		"level": 60, 
		"description": "废井原 - 坐标(38,26)", 
		"monsters": [
			{"pet_id": "duxing", "level": 50}, 
			{"pet_id": "duxing", "level": 60}, 
		]
	}, 
	"四津原（63,42）": {
		"id": "100010", 
		"name": "四津原（63,42）", 
		"level": 65, 
		"description": "四津原 - 坐标(63,42)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 60}, 
			{"pet_id": "lèlèxióng", "level": 65}, 
		]
	}, 
	"望日桥（0,0）": {
		"id": "100020", 
		"name": "望日桥（0,0）", 
		"level": 75, 
		"description": "望日桥 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hòupíè", "level": 60}, 
			{"pet_id": "tiějiǎgūi", "level": 75}, 
		]
	}, 
	"四津原（41,69）": {
		"id": "100010", 
		"name": "四津原（41,69）", 
		"level": 80, 
		"description": "四津原 - 坐标(41,69)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 70}, 
			{"pet_id": "zhaicitou", "level": 80}, 
		]
	}, 
	"聋耳地狱（0,0）": {
		"id": "600003", 
		"name": "聋耳地狱（0,0）", 
		"level": 80, 
		"description": "聋耳地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hóngdāo", "level": 80}, 
			{"pet_id": "tiějiǎgūi", "level": 75}, 
		]
	}, 
	"聋耳地狱（34,22）": {
		"id": "600003", 
		"name": "聋耳地狱（34,22）", 
		"level": 80, 
		"description": "聋耳地狱 - 坐标(34,22)", 
		"monsters": [
			{"pet_id": "hóngdāo", "level": 80}, 
			{"pet_id": "hóngdāo", "level": 75}, 
		]
	}, 
	"耕春原（0,0）": {
		"id": "300013", 
		"name": "耕春原（0,0）", 
		"level": 85, 
		"description": "耕春原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hēitíxiānshēng", "level": 80}, 
			{"pet_id": "kucitou", "level": 85}, 
		]
	}, 
	"耕春原（38,38）": {
		"id": "300013", 
		"name": "耕春原（38,38）", 
		"level": 85, 
		"description": "耕春原 - 坐标(38,38)", 
		"monsters": [
			{"pet_id": "zhaicitou", "level": 80}, 
			{"pet_id": "zhaicitou", "level": 85}, 
		]
	}, 
	"衡霄台（0,0）": {
		"id": "500013", 
		"name": "衡霄台（0,0）", 
		"level": 85, 
		"description": "衡霄台 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hongdazui", "level": 80}, 
			{"pet_id": "fuyejiu", "level": 85}, 
		]
	}, 
	"衡霄台（32,13）": {
		"id": "500013", 
		"name": "衡霄台（32,13）", 
		"level": 85, 
		"description": "衡霄台 - 坐标(32,13)", 
		"monsters": [
			{"pet_id": "hongdazui", "level": 80}, 
			{"pet_id": "hongdazui", "level": 85}, 
		]
	}, 
	"回望亭（0,0）": {
		"id": "700005", 
		"name": "回望亭（0,0）", 
		"level": 85, 
		"description": "回望亭 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 80}, 
			{"pet_id": "daicitou", "level": 85}, 
		]
	}, 
	"回望亭（39,33）": {
		"id": "700005", 
		"name": "回望亭（39,33）", 
		"level": 85, 
		"description": "回望亭 - 坐标(39,33)", 
		"monsters": [
			{"pet_id": "nununiao", "level": 80}, 
			{"pet_id": "nununiao", "level": 85}, 
		]
	}, 
	"废井原（13,22）": {
		"id": "100021", 
		"name": "废井原（13,22）", 
		"level": 87, 
		"description": "废井原 - 坐标(13,22)", 
		"monsters": [
			{"pet_id": "chushane", "level": 83}, 
			{"pet_id": "kucitou", "level": 87}, 
		]
	}, 
	"闲逸园（0,0）": {
		"id": "100017", 
		"name": "闲逸园（0,0）", 
		"level": 90, 
		"description": "闲逸园 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 70}, 
			{"pet_id": "yingying", "level": 90}, 
		]
	}, 
	"明月桥（7,15）": {
		"id": "100016", 
		"name": "明月桥（7,15）", 
		"level": 95, 
		"description": "明月桥 - 坐标(7,15)", 
		"monsters": [
			{"pet_id": "duduniao", "level": 80}, 
			{"pet_id": "duduniao", "level": 95}, 
		]
	}, 
	"望日桥（56,48）": {
		"id": "100020", 
		"name": "望日桥（56,48）", 
		"level": 97, 
		"description": "望日桥 - 坐标(56,48)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 93}, 
			{"pet_id": "duxing", "level": 97}, 
		]
	}, 
	"望日桥头（0,0）": {
		"id": "100019", 
		"name": "望日桥头（0,0）", 
		"level": 105, 
		"description": "望日桥头 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhaicitou", "level": 100}, 
			{"pet_id": "duduniao", "level": 105}, 
		]
	}, 
	"黄泥岗（0,0）": {
		"id": "300014", 
		"name": "黄泥岗（0,0）", 
		"level": 110, 
		"description": "黄泥岗 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "báimáoxiàng", "level": 100}, 
			{"pet_id": "jiéquándào", "level": 110}, 
		]
	}, 
	"黄泥岗（40,11）": {
		"id": "300014", 
		"name": "黄泥岗（40,11）", 
		"level": 110, 
		"description": "黄泥岗 - 坐标(40,11)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 100}, 
			{"pet_id": "jiéquándào", "level": 110}, 
		]
	}, 
	"宣武门（0,0）": {
		"id": "500021", 
		"name": "宣武门（0,0）", 
		"level": 110, 
		"description": "宣武门 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lǎnlǎnxiàng", "level": 100}, 
			{"pet_id": "duxing", "level": 110}, 
		]
	}, 
	"钉板地狱（0,0）": {
		"id": "600002", 
		"name": "钉板地狱（0,0）", 
		"level": 110, 
		"description": "钉板地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 100}, 
			{"pet_id": "yáoyé", "level": 110}, 
		]
	}, 
	"钉板地狱（33,44）": {
		"id": "600002", 
		"name": "钉板地狱（33,44）", 
		"level": 110, 
		"description": "钉板地狱 - 坐标(33,44)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 100}, 
			{"pet_id": "xiǎodīngdāng", "level": 110}, 
		]
	}, 
	"望日桥头（86,100）": {
		"id": "100019", 
		"name": "望日桥头（86,100）", 
		"level": 115, 
		"description": "望日桥头 - 坐标(86,100)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 110}, 
			{"pet_id": "tao_tao", "level": 115}, 
		]
	}, 
	"剑潭谷（0,0）": {
		"id": "100012", 
		"name": "剑潭谷（0,0）", 
		"level": 120, 
		"description": "剑潭谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàzǔiè", "level": 100}, 
			{"pet_id": "linlin", "level": 120}, 
		]
	}, 
	"望日桥头（37,51）": {
		"id": "100019", 
		"name": "望日桥头（37,51）", 
		"level": 135, 
		"description": "望日桥头 - 坐标(37,51)", 
		"monsters": [
			{"pet_id": "zhaicitou", "level": 120}, 
			{"pet_id": "lanmengmeng", "level": 135}, 
		]
	}, 
	"剑潭谷（57,23）": {
		"id": "100012", 
		"name": "剑潭谷（57,23）", 
		"level": 150, 
		"description": "剑潭谷 - 坐标(57,23)", 
		"monsters": [
			{"pet_id": "dàzǔiè", "level": 130}, 
			{"pet_id": "linlin", "level": 150}, 
		]
	}, 
	"剑潭谷（41,37）": {
		"id": "100012", 
		"name": "剑潭谷（41,37）", 
		"level": 160, 
		"description": "剑潭谷 - 坐标(41,37)", 
		"monsters": [
			{"pet_id": "linlin", "level": 150}, 
			{"pet_id": "linlin", "level": 160}, 
		]
	}, 
	"暮枫林（0,0）": {
		"id": "700003", 
		"name": "暮枫林（0,0）", 
		"level": 160, 
		"description": "暮枫林 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 150}, 
			{"pet_id": "dàidāo", "level": 160}, 
		]
	}, 
	"暮枫林（30,20）": {
		"id": "700003", 
		"name": "暮枫林（30,20）", 
		"level": 160, 
		"description": "暮枫林 - 坐标(30,20)", 
		"monsters": [
			{"pet_id": "dàidāo", "level": 150}, 
			{"pet_id": "dàidāo", "level": 160}, 
		]
	}, 
	"闲逸园（38,21）": {
		"id": "100017", 
		"name": "闲逸园（38,21）", 
		"level": 175, 
		"description": "闲逸园 - 坐标(38,21)", 
		"monsters": [
			{"pet_id": "niefengquan", "level": 170}, 
			{"pet_id": "dàzǔiè", "level": 175}, 
		]
	}, 
	"松竹林（0,0）": {
		"id": "100028", 
		"name": "松竹林（0,0）", 
		"level": 190, 
		"description": "松竹林 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "daicitou", "level": 190}, 
			{"pet_id": "duxing", "level": 160}, 
		]
	}, 
	"松竹林（11,21）": {
		"id": "100028", 
		"name": "松竹林（11,21）", 
		"level": 190, 
		"description": "松竹林 - 坐标(11,21)", 
		"monsters": [
			{"pet_id": "dàidāo", "level": 180}, 
			{"pet_id": "tufei", "level": 190}, 
		]
	}, 
	"松竹林（24,10）": {
		"id": "100028", 
		"name": "松竹林（24,10）", 
		"level": 190, 
		"description": "松竹林 - 坐标(24,10)", 
		"monsters": [
			{"pet_id": "daicitou", "level": 190}, 
			{"pet_id": "daicitou", "level": 185}, 
		]
	}, 
	"孤木原（0,0）": {
		"id": "300017", 
		"name": "孤木原（0,0）", 
		"level": 190, 
		"description": "孤木原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "ouou", "level": 180}, 
			{"pet_id": "huanbiantianlang", "level": 190}, 
		]
	}, 
	"孤木原（29,22）": {
		"id": "300017", 
		"name": "孤木原（29,22）", 
		"level": 190, 
		"description": "孤木原 - 坐标(29,22)", 
		"monsters": [
			{"pet_id": "ouou", "level": 180}, 
			{"pet_id": "ouou", "level": 190}, 
		]
	}, 
	"双玺谷（0,0）": {
		"id": "700008", 
		"name": "双玺谷（0,0）", 
		"level": 190, 
		"description": "双玺谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lányá", "level": 180}, 
			{"pet_id": "dàidāo", "level": 190}, 
		]
	}, 
	"双玺谷（48,20）": {
		"id": "700008", 
		"name": "双玺谷（48,20）", 
		"level": 190, 
		"description": "双玺谷 - 坐标(48,20)", 
		"monsters": [
			{"pet_id": "lèlèxióng", "level": 180}, 
			{"pet_id": "lèlèxióng", "level": 190}, 
		]
	}, 
	"绞肉地狱（0,0）": {
		"id": "600006", 
		"name": "绞肉地狱（0,0）", 
		"level": 200, 
		"description": "绞肉地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 200}, 
			{"pet_id": "yáoyé", "level": 190}, 
		]
	}, 
	"松霜野（0,0）": {
		"id": "300009", 
		"name": "松霜野（0,0）", 
		"level": 210, 
		"description": "松霜野 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "báimáoxiàng", "level": 200}, 
			{"pet_id": "lèngtóuqīng", "level": 210}, 
		]
	}, 
	"落尘台（0,0）": {
		"id": "500014", 
		"name": "落尘台（0,0）", 
		"level": 210, 
		"description": "落尘台 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiàngpíshǔ", "level": 200}, 
			{"pet_id": "mìmìxióng", "level": 210}, 
		]
	}, 
	"落尘台（93,77）": {
		"id": "500014", 
		"name": "落尘台（93,77）", 
		"level": 210, 
		"description": "落尘台 - 坐标(93,77)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 200}, 
			{"pet_id": "mìmìxióng", "level": 210}, 
		]
	}, 
	"猎人洞窟（0,0）": {
		"id": "100061", 
		"name": "猎人洞窟（0,0）", 
		"level": 220, 
		"description": "猎人洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 200}, 
			{"pet_id": "nununiao", "level": 220}, 
		]
	}, 
	"碧野云霄（0,0）": {
		"id": "131001", 
		"name": "碧野云霄（0,0）", 
		"level": 220, 
		"description": "碧野云霄 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "huahua", "level": 200}, 
			{"pet_id": "zhenzhen", "level": 220}, 
		]
	}, 
	"东码头（0,0）": {
		"id": "100023", 
		"name": "东码头（0,0）", 
		"level": 225, 
		"description": "东码头 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàidāo", "level": 220}, 
			{"pet_id": "yìnggǔè", "level": 225}, 
		]
	}, 
	"东码头（28,9）": {
		"id": "100023", 
		"name": "东码头（28,9）", 
		"level": 225, 
		"description": "东码头 - 坐标(28,9)", 
		"monsters": [
			{"pet_id": "yìnggǔè", "level": 220}, 
			{"pet_id": "yìnggǔè", "level": 225}, 
		]
	}, 
	"断壁（0,0）": {
		"id": "100026", 
		"name": "断壁（0,0）", 
		"level": 230, 
		"description": "断壁 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "duxing", "level": 220}, 
			{"pet_id": "duduniao", "level": 230}, 
		]
	}, 
	"猎人洞窟（55,52）": {
		"id": "100061", 
		"name": "猎人洞窟（55,52）", 
		"level": 230, 
		"description": "猎人洞窟 - 坐标(55,52)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 220}, 
			{"pet_id": "nununiao", "level": 230}, 
		]
	}, 
	"东码头（58,62）": {
		"id": "100023", 
		"name": "东码头（58,62）", 
		"level": 235, 
		"description": "东码头 - 坐标(58,62)", 
		"monsters": [
			{"pet_id": "dàidāo", "level": 230}, 
			{"pet_id": "yìnggǔè", "level": 235}, 
		]
	}, 
	"断壁（50,62）": {
		"id": "100126", 
		"name": "断壁（50,62）", 
		"level": 240, 
		"description": "断壁 - 坐标(50,62)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 230}, 
			{"pet_id": "linlin", "level": 240}, 
		]
	}, 
	"猎人洞窟（15,33）": {
		"id": "100061", 
		"name": "猎人洞窟（15,33）", 
		"level": 250, 
		"description": "猎人洞窟 - 坐标(15,33)", 
		"monsters": [
			{"pet_id": "aoririquan", "level": 250}, 
			{"pet_id": "luluniao", "level": 230}, 
		]
	}, 
	"宝洞（0,0）": {
		"id": "100079", 
		"name": "宝洞（0,0）", 
		"level": 250, 
		"description": "宝洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "baidazui", "level": 200}, 
			{"pet_id": "baidazui", "level": 250}, 
		]
	}, 
	"春水桥（0,0）": {
		"id": "300018", 
		"name": "春水桥（0,0）", 
		"level": 250, 
		"description": "春水桥 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 220}, 
			{"pet_id": "dàdāo", "level": 250}, 
		]
	}, 
	"春水桥（39,51）": {
		"id": "300018", 
		"name": "春水桥（39,51）", 
		"level": 250, 
		"description": "春水桥 - 坐标(39,51)", 
		"monsters": [
			{"pet_id": "zhōngdāo", "level": 220}, 
			{"pet_id": "zhōngdāo", "level": 250}, 
		]
	}, 
	"逆之心绪（0,0）": {
		"id": "700010", 
		"name": "逆之心绪（0,0）", 
		"level": 250, 
		"description": "逆之心绪 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 220}, 
			{"pet_id": "daicitou", "level": 250}, 
		]
	}, 
	"西码头（0,0）": {
		"id": "100018", 
		"name": "西码头（0,0）", 
		"level": 255, 
		"description": "西码头 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 250}, 
			{"pet_id": "dàzǔiè", "level": 255}, 
		]
	}, 
	"西码头（59,86）": {
		"id": "100018", 
		"name": "西码头（59,86）", 
		"level": 255, 
		"description": "西码头 - 坐标(59,86)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 250}, 
			{"pet_id": "qíshìgūi", "level": 255}, 
		]
	}, 
	"雪霁谷（0,0）": {
		"id": "300019", 
		"name": "雪霁谷（0,0）", 
		"level": 260, 
		"description": "雪霁谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "báimáoxiàng", "level": 250}, 
			{"pet_id": "mìmìxióng", "level": 260}, 
		]
	}, 
	"雪霁谷（45,42）": {
		"id": "300019", 
		"name": "雪霁谷（45,42）", 
		"level": 260, 
		"description": "雪霁谷 - 坐标(45,42)", 
		"monsters": [
			{"pet_id": "lǎnlǎnxiàng", "level": 250}, 
			{"pet_id": "lǎnlǎnxiàng", "level": 260}, 
		]
	}, 
	"逆之往昔（0,0）": {
		"id": "700011", 
		"name": "逆之往昔（0,0）", 
		"level": 260, 
		"description": "逆之往昔 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 250}, 
			{"pet_id": "dàdāo", "level": 260}, 
		]
	}, 
	"西码头（42,57）": {
		"id": "100018", 
		"name": "西码头（42,57）", 
		"level": 270, 
		"description": "西码头 - 坐标(42,57)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 260}, 
			{"pet_id": "lanmengmeng", "level": 270}, 
		]
	}, 
	"忘归海岸（0,0）": {
		"id": "700009", 
		"name": "忘归海岸（0,0）", 
		"level": 270, 
		"description": "忘归海岸 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 260}, 
			{"pet_id": "lányá", "level": 270}, 
		]
	}, 
	"忘归海岸（47,32）": {
		"id": "700009", 
		"name": "忘归海岸（47,32）", 
		"level": 270, 
		"description": "忘归海岸 - 坐标(47,32)", 
		"monsters": [
			{"pet_id": "lányá", "level": 260}, 
			{"pet_id": "lányá", "level": 270}, 
		]
	}, 
	"断魄涯（0,0）": {
		"id": "100025", 
		"name": "断魄涯（0,0）", 
		"level": 280, 
		"description": "断魄涯 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "daicitou", "level": 270}, 
			{"pet_id": "linlin", "level": 280}, 
		]
	}, 
	"羊肠道（0,0）": {
		"id": "300016", 
		"name": "羊肠道（0,0）", 
		"level": 280, 
		"description": "羊肠道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "ātài", "level": 250}, 
			{"pet_id": "báimáoxiàng", "level": 280}, 
		]
	}, 
	"羊肠道（45,38）": {
		"id": "300016", 
		"name": "羊肠道（45,38）", 
		"level": 280, 
		"description": "羊肠道 - 坐标(45,38)", 
		"monsters": [
			{"pet_id": "lv̀jǐnbǎo", "level": 250}, 
			{"pet_id": "lv̀jǐnbǎo", "level": 280}, 
		]
	}, 
	"幽怨洞口（0,0）": {
		"id": "200005", 
		"name": "幽怨洞口（0,0）", 
		"level": 285, 
		"description": "幽怨洞口 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "wudidan", "level": 280}, 
			{"pet_id": "xi_pi", "level": 285}, 
		]
	}, 
	"幽怨洞口（66,58）": {
		"id": "200005", 
		"name": "幽怨洞口（66,58）", 
		"level": 285, 
		"description": "幽怨洞口 - 坐标(66,58)", 
		"monsters": [
			{"pet_id": "xi_pi", "level": 280}, 
			{"pet_id": "xi_pi", "level": 285}, 
		]
	}, 
	"石壁洞口（0,0）": {
		"id": "100027", 
		"name": "石壁洞口（0,0）", 
		"level": 290, 
		"description": "石壁洞口 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 280}, 
			{"pet_id": "fengwu", "level": 290}, 
		]
	}, 
	"石壁洞口（48,28）": {
		"id": "100027", 
		"name": "石壁洞口（48,28）", 
		"level": 290, 
		"description": "石壁洞口 - 坐标(48,28)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 280}, 
			{"pet_id": "fengwu", "level": 290}, 
		]
	}, 
	"幽怨洞口（35,63）": {
		"id": "200005", 
		"name": "幽怨洞口（35,63）", 
		"level": 290, 
		"description": "幽怨洞口 - 坐标(35,63)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 275}, 
			{"pet_id": "xi_pi", "level": 290}, 
		]
	}, 
	"断魄涯（34,40）": {
		"id": "100025", 
		"name": "断魄涯（34,40）", 
		"level": 295, 
		"description": "断魄涯 - 坐标(34,40)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 290}, 
			{"pet_id": "fengwu", "level": 295}, 
		]
	}, 
	"幽怨洞（0,0）": {
		"id": "700090", 
		"name": "幽怨洞（0,0）", 
		"level": 295, 
		"description": "幽怨洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhōngdāo", "level": 290}, 
			{"pet_id": "lèlèxióng", "level": 295}, 
		]
	}, 
	"石壁洞口（25,32）": {
		"id": "100027", 
		"name": "石壁洞口（25,32）", 
		"level": 305, 
		"description": "石壁洞口 - 坐标(25,32)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 300}, 
			{"pet_id": "fengwu", "level": 305}, 
		]
	}, 
	"炉烧地狱（0,0）": {
		"id": "600007", 
		"name": "炉烧地狱（0,0）", 
		"level": 305, 
		"description": "炉烧地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 300}, 
			{"pet_id": "yìnggǔè", "level": 305}, 
		]
	}, 
	"幽怨洞（28,13）": {
		"id": "700090", 
		"name": "幽怨洞（28,13）", 
		"level": 305, 
		"description": "幽怨洞 - 坐标(28,13)", 
		"monsters": [
			{"pet_id": "zhōngdāo", "level": 295}, 
			{"pet_id": "lèlèxióng", "level": 305}, 
		]
	}, 
	"幽怨洞（19,25）": {
		"id": "700090", 
		"name": "幽怨洞（19,25）", 
		"level": 305, 
		"description": "幽怨洞 - 坐标(19,25)", 
		"monsters": [
			{"pet_id": "zhōngdāo", "level": 300}, 
			{"pet_id": "lèlèxióng", "level": 305}, 
		]
	}, 
	"惊魂洞窟2（0,0）": {
		"id": "100087", 
		"name": "惊魂洞窟2（0,0）", 
		"level": 320, 
		"description": "惊魂洞窟2 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 310}, 
			{"pet_id": "zhenzhen", "level": 320}, 
		]
	}, 
	"惊魂洞窟2（38,66）": {
		"id": "100087", 
		"name": "惊魂洞窟2（38,66）", 
		"level": 320, 
		"description": "惊魂洞窟2 - 坐标(38,66)", 
		"monsters": [
			{"pet_id": "zhenzhen", "level": 310}, 
			{"pet_id": "zhenzhen", "level": 320}, 
		]
	}, 
	"凌云幻城（0,0）": {
		"id": "500015", 
		"name": "凌云幻城（0,0）", 
		"level": 320, 
		"description": "凌云幻城 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "gang_lei_fei", "level": 300}, 
			{"pet_id": "ātài", "level": 320}, 
		]
	}, 
	"鸾之谷（0,0）": {
		"id": "700013", 
		"name": "鸾之谷（0,0）", 
		"level": 320, 
		"description": "鸾之谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 300}, 
			{"pet_id": "xuefenghuang", "level": 320}, 
		]
	}, 
	"鸾之谷（31,27）": {
		"id": "700013", 
		"name": "鸾之谷（31,27）", 
		"level": 320, 
		"description": "鸾之谷 - 坐标(31,27)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 300}, 
			{"pet_id": "luluniao", "level": 320}, 
		]
	}, 
	"惊魂洞窟1（0,0）": {
		"id": "100086", 
		"name": "惊魂洞窟1（0,0）", 
		"level": 330, 
		"description": "惊魂洞窟1 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "wen_di_long", "level": 330}, 
			{"pet_id": "tiějiǎgūi", "level": 320}, 
		]
	}, 
	"惊魂洞窟1（43,42）": {
		"id": "100086", 
		"name": "惊魂洞窟1（43,42）", 
		"level": 330, 
		"description": "惊魂洞窟1 - 坐标(43,42)", 
		"monsters": [
			{"pet_id": "wen_di_long", "level": 330}, 
			{"pet_id": "wen_di_long", "level": 320}, 
		]
	}, 
	"惊魂洞窟2（46,38）": {
		"id": "100087", 
		"name": "惊魂洞窟2（46,38）", 
		"level": 330, 
		"description": "惊魂洞窟2 - 坐标(46,38)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 320}, 
			{"pet_id": "zhenzhen", "level": 330}, 
		]
	}, 
	"炊霭谷（0,0）": {
		"id": "300020", 
		"name": "炊霭谷（0,0）", 
		"level": 330, 
		"description": "炊霭谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 300}, 
			{"pet_id": "hēitíxiānshēng", "level": 330}, 
		]
	}, 
	"炊霭谷（42,24）": {
		"id": "300020", 
		"name": "炊霭谷（42,24）", 
		"level": 330, 
		"description": "炊霭谷 - 坐标(42,24)", 
		"monsters": [
			{"pet_id": "hēitíxiānshēng", "level": 300}, 
			{"pet_id": "hēitíxiānshēng", "level": 330}, 
		]
	}, 
	"西霜岭（0,0）": {
		"id": "300036", 
		"name": "西霜岭（0,0）", 
		"level": 330, 
		"description": "西霜岭 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "báimáoxiàng", "level": 300}, 
			{"pet_id": "báimáoxiàng", "level": 330}, 
		]
	}, 
	"情人谷（0,0）": {
		"id": "200019", 
		"name": "情人谷（0,0）", 
		"level": 335, 
		"description": "情人谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "ben_lei_fei", "level": 330}, 
			{"pet_id": "ādá", "level": 335}, 
		]
	}, 
	"情人谷（12,26）": {
		"id": "200019", 
		"name": "情人谷（12,26）", 
		"level": 335, 
		"description": "情人谷 - 坐标(12,26)", 
		"monsters": [
			{"pet_id": "ādá", "level": 330}, 
			{"pet_id": "ādá", "level": 335}, 
		]
	}, 
	"情人谷（30,30）": {
		"id": "200019", 
		"name": "情人谷（30,30）", 
		"level": 340, 
		"description": "情人谷 - 坐标(30,30)", 
		"monsters": [
			{"pet_id": "ben_lei_fei", "level": 335}, 
			{"pet_id": "ādá", "level": 340}, 
		]
	}, 
	"赏月谷（0,0）": {
		"id": "200020", 
		"name": "赏月谷（0,0）", 
		"level": 340, 
		"description": "赏月谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 335}, 
			{"pet_id": "gang_lei_fei", "level": 340}, 
		]
	}, 
	"赏月谷（50,71）": {
		"id": "200020", 
		"name": "赏月谷（50,71）", 
		"level": 340, 
		"description": "赏月谷 - 坐标(50,71)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 335}, 
			{"pet_id": "minixiang", "level": 340}, 
		]
	}, 
	"惊魂洞窟1（34,61）": {
		"id": "100086", 
		"name": "惊魂洞窟1（34,61）", 
		"level": 350, 
		"description": "惊魂洞窟1 - 坐标(34,61)", 
		"monsters": [
			{"pet_id": "wen_di_long", "level": 340}, 
			{"pet_id": "tiějiǎgūi", "level": 350}, 
		]
	}, 
	"赏月谷（30,38）": {
		"id": "200020", 
		"name": "赏月谷（30,38）", 
		"level": 350, 
		"description": "赏月谷 - 坐标(30,38)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 340}, 
			{"pet_id": "gang_lei_fei", "level": 350}, 
		]
	}, 
	"翠幽洞（0,0）": {
		"id": "200040", 
		"name": "翠幽洞（0,0）", 
		"level": 370, 
		"description": "翠幽洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 350}, 
			{"pet_id": "wang_wang", "level": 370}, 
		]
	}, 
	"寒泉台（0,0）": {
		"id": "300037", 
		"name": "寒泉台（0,0）", 
		"level": 370, 
		"description": "寒泉台 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "báimáoxiàng", "level": 350}, 
			{"pet_id": "báimáoxiàng", "level": 370}, 
		]
	}, 
	"碧之绿洲（0,0）": {
		"id": "200039", 
		"name": "碧之绿洲（0,0）", 
		"level": 380, 
		"description": "碧之绿洲 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 360}, 
			{"pet_id": "yingying", "level": 380}, 
		]
	}, 
	"翠幽洞（35,54）": {
		"id": "200040", 
		"name": "翠幽洞（35,54）", 
		"level": 380, 
		"description": "翠幽洞 - 坐标(35,54)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 380}, 
			{"pet_id": "niefengquan", "level": 360}, 
		]
	}, 
	"斧翠谷（0,0）": {
		"id": "300011", 
		"name": "斧翠谷（0,0）", 
		"level": 380, 
		"description": "斧翠谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qíshìgūi", "level": 350}, 
			{"pet_id": "yingying", "level": 380}, 
		]
	}, 
	"鸠鸣小舍（0,0）": {
		"id": "700004", 
		"name": "鸠鸣小舍（0,0）", 
		"level": 380, 
		"description": "鸠鸣小舍 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "yùlíntù", "level": 350}, 
			{"pet_id": "luluniao", "level": 380}, 
		]
	}, 
	"天关第1层（0,0）": {
		"id": "120000", 
		"name": "天关第1层（0,0）", 
		"level": 400, 
		"description": "天关第1层 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "míhuò", "level": 300}, 
			{"pet_id": "tiějiǎgūi", "level": 400}, 
		]
	}, 
	"天关第81层（0,0）": {
		"id": "120080", 
		"name": "天关第81层（0,0）", 
		"level": 400, 
		"description": "天关第81层 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xingyunxing", "level": 300}, 
			{"pet_id": "zhōngdāo", "level": 400}, 
		]
	}, 
	"铜偶殿（57,81）": {
		"id": "200032", 
		"name": "铜偶殿（57,81）", 
		"level": 400, 
		"description": "铜偶殿 - 坐标(57,81)", 
		"monsters": [
			{"pet_id": "cong_cong", "level": 400}, 
			{"pet_id": "wang_wang", "level": 380}, 
		]
	}, 
	"监狱第五层（0,0）": {
		"id": "800004", 
		"name": "监狱第五层（0,0）", 
		"level": 400, 
		"description": "监狱第五层 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "landazui", "level": 200}, 
			{"pet_id": "landazui", "level": 400}, 
		]
	}, 
	"绿洲东郊（0,0）": {
		"id": "200006", 
		"name": "绿洲东郊（0,0）", 
		"level": 410, 
		"description": "绿洲东郊 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 400}, 
			{"pet_id": "wang_wang", "level": 410}, 
		]
	}, 
	"绿洲东郊（41,72）": {
		"id": "200006", 
		"name": "绿洲东郊（41,72）", 
		"level": 410, 
		"description": "绿洲东郊 - 坐标(41,72)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 400}, 
			{"pet_id": "kubixiang", "level": 410}, 
		]
	}, 
	"银瓮谷（0,0）": {
		"id": "200008", 
		"name": "银瓮谷（0,0）", 
		"level": 410, 
		"description": "银瓮谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhuiyingquan", "level": 400}, 
			{"pet_id": "cong_cong", "level": 410}, 
		]
	}, 
	"银瓮谷（41,35）": {
		"id": "200008", 
		"name": "银瓮谷（41,35）", 
		"level": 410, 
		"description": "银瓮谷 - 坐标(41,35)", 
		"monsters": [
			{"pet_id": "cong_cong", "level": 400}, 
			{"pet_id": "cong_cong", "level": 410}, 
		]
	}, 
	"辗肢地狱（0,0）": {
		"id": "600008", 
		"name": "辗肢地狱（0,0）", 
		"level": 410, 
		"description": "辗肢地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 400}, 
			{"pet_id": "yáoyé", "level": 410}, 
		]
	}, 
	"辗肢地狱（33,48）": {
		"id": "600008", 
		"name": "辗肢地狱（33,48）", 
		"level": 410, 
		"description": "辗肢地狱 - 坐标(33,48)", 
		"monsters": [
			{"pet_id": "yáoyé", "level": 400}, 
			{"pet_id": "yáoyé", "level": 410}, 
		]
	}, 
	"碧之绿洲（45,47）": {
		"id": "200039", 
		"name": "碧之绿洲（45,47）", 
		"level": 415, 
		"description": "碧之绿洲 - 坐标(45,47)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 400}, 
			{"pet_id": "linlin", "level": 415}, 
		]
	}, 
	"灵菇洞（0,0）": {
		"id": "200041", 
		"name": "灵菇洞（0,0）", 
		"level": 415, 
		"description": "灵菇洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "shuaidaixiang", "level": 400}, 
			{"pet_id": "xi_pi", "level": 415}, 
		]
	}, 
	"幽思坡（0,0）": {
		"id": "131010", 
		"name": "幽思坡（0,0）", 
		"level": 420, 
		"description": "幽思坡 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "guihuojun", "level": 400}, 
			{"pet_id": "wen_di_long", "level": 420}, 
		]
	}, 
	"银瓮谷（21,21）": {
		"id": "200008", 
		"name": "银瓮谷（21,21）", 
		"level": 420, 
		"description": "银瓮谷 - 坐标(21,21)", 
		"monsters": [
			{"pet_id": "zhuiyingquan", "level": 415}, 
			{"pet_id": "cong_cong", "level": 420}, 
		]
	}, 
	"铜偶殿（0,0）": {
		"id": "200032", 
		"name": "铜偶殿（0,0）", 
		"level": 420, 
		"description": "铜偶殿 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "cong_cong", "level": 420}, 
			{"pet_id": "wang_wang", "level": 410}, 
		]
	}, 
	"铜偶殿（82,45）": {
		"id": "200032", 
		"name": "铜偶殿（82,45）", 
		"level": 420, 
		"description": "铜偶殿 - 坐标(82,45)", 
		"monsters": [
			{"pet_id": "wang_wang", "level": 420}, 
			{"pet_id": "wang_wang", "level": 410}, 
		]
	}, 
	"鸟鸣谷（0,0）": {
		"id": "300015", 
		"name": "鸟鸣谷（0,0）", 
		"level": 420, 
		"description": "鸟鸣谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 400}, 
			{"pet_id": "hēitíxiānshēng", "level": 420}, 
		]
	}, 
	"空明园（0,0）": {
		"id": "500023", 
		"name": "空明园（0,0）", 
		"level": 420, 
		"description": "空明园 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdōng", "level": 400}, 
			{"pet_id": "lèngtóuqīng", "level": 420}, 
		]
	}, 
	"榕根谷（0,0）": {
		"id": "700001", 
		"name": "榕根谷（0,0）", 
		"level": 420, 
		"description": "榕根谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lányá", "level": 400}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 420}, 
		]
	}, 
	"榕根谷（40,28）": {
		"id": "700001", 
		"name": "榕根谷（40,28）", 
		"level": 420, 
		"description": "榕根谷 - 坐标(40,28)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 400}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 420}, 
		]
	}, 
	"逆之幻影（0,0）": {
		"id": "700012", 
		"name": "逆之幻影（0,0）", 
		"level": 420, 
		"description": "逆之幻影 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lv̀jǐnbǎo", "level": 400}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 420}, 
		]
	}, 
	"绿洲东郊（41,35）": {
		"id": "200006", 
		"name": "绿洲东郊（41,35）", 
		"level": 425, 
		"description": "绿洲东郊 - 坐标(41,35)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 415}, 
			{"pet_id": "meng_meng", "level": 425}, 
		]
	}, 
	"镜霜原（0,0）": {
		"id": "300008", 
		"name": "镜霜原（0,0）", 
		"level": 430, 
		"description": "镜霜原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 400}, 
			{"pet_id": "dàzǔiè", "level": 430}, 
		]
	}, 
	"镜霜原（39,55）": {
		"id": "300008", 
		"name": "镜霜原（39,55）", 
		"level": 430, 
		"description": "镜霜原 - 坐标(39,55)", 
		"monsters": [
			{"pet_id": "dàzǔiè", "level": 400}, 
			{"pet_id": "dàzǔiè", "level": 430}, 
		]
	}, 
	"鸠鸣小舍（65,50）": {
		"id": "700004", 
		"name": "鸠鸣小舍（65,50）", 
		"level": 435, 
		"description": "鸠鸣小舍 - 坐标(65,50)", 
		"monsters": [
			{"pet_id": "yùlíntù", "level": 410}, 
			{"pet_id": "nununiao", "level": 435}, 
		]
	}, 
	"碧之绿洲（14,41）": {
		"id": "200039", 
		"name": "碧之绿洲（14,41）", 
		"level": 440, 
		"description": "碧之绿洲 - 坐标(14,41)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 430}, 
			{"pet_id": "yingying", "level": 440}, 
		]
	}, 
	"灵菇洞（26,38）": {
		"id": "200041", 
		"name": "灵菇洞（26,38）", 
		"level": 440, 
		"description": "灵菇洞 - 坐标(26,38)", 
		"monsters": [
			{"pet_id": "shuaidaixiang", "level": 425}, 
			{"pet_id": "xi_pi", "level": 440}, 
		]
	}, 
	"澄沙原（36,38）": {
		"id": "200017", 
		"name": "澄沙原（36,38）", 
		"level": 445, 
		"description": "澄沙原 - 坐标(36,38)", 
		"monsters": [
			{"pet_id": "niefengquan", "level": 445}, 
			{"pet_id": "hòupíè", "level": 435}, 
		]
	}, 
	"澄沙原（0,0）": {
		"id": "200017", 
		"name": "澄沙原（0,0）", 
		"level": 450, 
		"description": "澄沙原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "niefengquan", "level": 450}, 
			{"pet_id": "hòupíè", "level": 445}, 
		]
	}, 
	"澄沙原（58,32）": {
		"id": "200017", 
		"name": "澄沙原（58,32）", 
		"level": 450, 
		"description": "澄沙原 - 坐标(58,32)", 
		"monsters": [
			{"pet_id": "hòupíè", "level": 450}, 
			{"pet_id": "hòupíè", "level": 445}, 
		]
	}, 
	"灵菇洞（47,54）": {
		"id": "200041", 
		"name": "灵菇洞（47,54）", 
		"level": 460, 
		"description": "灵菇洞 - 坐标(47,54)", 
		"monsters": [
			{"pet_id": "shuaidaixiang", "level": 450}, 
			{"pet_id": "xi_pi", "level": 460}, 
		]
	}, 
	"醉客冢（0,0）": {
		"id": "200013", 
		"name": "醉客冢（0,0）", 
		"level": 470, 
		"description": "醉客冢 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 470}, 
			{"pet_id": "ādǒu", "level": 460}, 
		]
	}, 
	"醉客冢（38,23）": {
		"id": "200013", 
		"name": "醉客冢（38,23）", 
		"level": 470, 
		"description": "醉客冢 - 坐标(38,23)", 
		"monsters": [
			{"pet_id": "ādǒu", "level": 470}, 
			{"pet_id": "ādǒu", "level": 460}, 
		]
	}, 
	"青幽洞（0,0）": {
		"id": "200042", 
		"name": "青幽洞（0,0）", 
		"level": 470, 
		"description": "青幽洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 455}, 
			{"pet_id": "cong_cong", "level": 470}, 
		]
	}, 
	"炮烙地狱（0,0）": {
		"id": "600009", 
		"name": "炮烙地狱（0,0）", 
		"level": 470, 
		"description": "炮烙地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hóngdāo", "level": 450}, 
			{"pet_id": "tiějiǎgūi", "level": 470}, 
		]
	}, 
	"炮烙地狱（27,50）": {
		"id": "600009", 
		"name": "炮烙地狱（27,50）", 
		"level": 470, 
		"description": "炮烙地狱 - 坐标(27,50)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 450}, 
			{"pet_id": "tiějiǎgūi", "level": 470}, 
		]
	}, 
	"古城遗址（0,0）": {
		"id": "200056", 
		"name": "古城遗址（0,0）", 
		"level": 480, 
		"description": "古城遗址 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 480}, 
			{"pet_id": "gang_lei_fei", "level": 470}, 
		]
	}, 
	"古城遗址（98,62）": {
		"id": "200056", 
		"name": "古城遗址（98,62）", 
		"level": 480, 
		"description": "古城遗址 - 坐标(98,62)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 480}, 
			{"pet_id": "dàdāo", "level": 470}, 
		]
	}, 
	"莹冰桥（0,0）": {
		"id": "300038", 
		"name": "莹冰桥（0,0）", 
		"level": 480, 
		"description": "莹冰桥 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 450}, 
			{"pet_id": "yáoyé", "level": 480}, 
		]
	}, 
	"望阙林场（0,0）": {
		"id": "700006", 
		"name": "望阙林场（0,0）", 
		"level": 480, 
		"description": "望阙林场 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 460}, 
			{"pet_id": "yùlíntù", "level": 480}, 
		]
	}, 
	"金轮谷（0,0）": {
		"id": "200009", 
		"name": "金轮谷（0,0）", 
		"level": 485, 
		"description": "金轮谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "kōngshǒudào", "level": 460}, 
			{"pet_id": "linlin", "level": 485}, 
		]
	}, 
	"醉客冢（26,28）": {
		"id": "200013", 
		"name": "醉客冢（26,28）", 
		"level": 490, 
		"description": "醉客冢 - 坐标(26,28)", 
		"monsters": [
			{"pet_id": "minixiang", "level": 490}, 
			{"pet_id": "ādǒu", "level": 490}, 
		]
	}, 
	"古城遗址（42,48）": {
		"id": "200056", 
		"name": "古城遗址（42,48）", 
		"level": 490, 
		"description": "古城遗址 - 坐标(42,48)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 460}, 
			{"pet_id": "gang_lei_fei", "level": 490}, 
		]
	}, 
	"沉寂的古城（53,84）": {
		"id": "200057", 
		"name": "沉寂的古城（53,84）", 
		"level": 500, 
		"description": "沉寂的古城 - 坐标(53,84)", 
		"monsters": [
			{"pet_id": "ātài", "level": 500}, 
			{"pet_id": "wang_wang", "level": 480}, 
		]
	}, 
	"青幽洞（43,40）": {
		"id": "200042", 
		"name": "青幽洞（43,40）", 
		"level": 510, 
		"description": "青幽洞 - 坐标(43,40)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 490}, 
			{"pet_id": "cong_cong", "level": 510}, 
		]
	}, 
	"沉寂的古城（0,0）": {
		"id": "200057", 
		"name": "沉寂的古城（0,0）", 
		"level": 510, 
		"description": "沉寂的古城 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "ātài", "level": 510}, 
			{"pet_id": "wang_wang", "level": 500}, 
		]
	}, 
	"沉寂的古城（64,29）": {
		"id": "200057", 
		"name": "沉寂的古城（64,29）", 
		"level": 510, 
		"description": "沉寂的古城 - 坐标(64,29)", 
		"monsters": [
			{"pet_id": "ātài", "level": 510}, 
			{"pet_id": "ātài", "level": 500}, 
		]
	}, 
	"莹冰桥（34,31）": {
		"id": "300038", 
		"name": "莹冰桥（34,31）", 
		"level": 520, 
		"description": "莹冰桥 - 坐标(34,31)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 500}, 
			{"pet_id": "yáoyé", "level": 520}, 
		]
	}, 
	"将军碣谷（0,0）": {
		"id": "100009", 
		"name": "将军碣谷（0,0）", 
		"level": 525, 
		"description": "将军碣谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "cong_cong", "level": 520}, 
			{"pet_id": "yìnggǔè", "level": 525}, 
		]
	}, 
	"将军碣谷（61,44）": {
		"id": "100009", 
		"name": "将军碣谷（61,44）", 
		"level": 525, 
		"description": "将军碣谷 - 坐标(61,44)", 
		"monsters": [
			{"pet_id": "míhuò", "level": 520}, 
			{"pet_id": "míhuò", "level": 525}, 
		]
	}, 
	"金轮谷（50,39）": {
		"id": "200009", 
		"name": "金轮谷（50,39）", 
		"level": 525, 
		"description": "金轮谷 - 坐标(50,39)", 
		"monsters": [
			{"pet_id": "kōngshǒudào", "level": 510}, 
			{"pet_id": "zhenzhen", "level": 525}, 
		]
	}, 
	"望阙林场（58,52）": {
		"id": "700006", 
		"name": "望阙林场（58,52）", 
		"level": 530, 
		"description": "望阙林场 - 坐标(58,52)", 
		"monsters": [
			{"pet_id": "duxing", "level": 510}, 
			{"pet_id": "cǎomǎngtù", "level": 530}, 
		]
	}, 
	"将军碣谷（19,52）": {
		"id": "100009", 
		"name": "将军碣谷（19,52）", 
		"level": 535, 
		"description": "将军碣谷 - 坐标(19,52)", 
		"monsters": [
			{"pet_id": "cong_cong", "level": 530}, 
			{"pet_id": "yìnggǔè", "level": 535}, 
		]
	}, 
	"青幽洞（59,67）": {
		"id": "200042", 
		"name": "青幽洞（59,67）", 
		"level": 550, 
		"description": "青幽洞 - 坐标(59,67)", 
		"monsters": [
			{"pet_id": "kubixiang", "level": 530}, 
			{"pet_id": "cong_cong", "level": 550}, 
		]
	}, 
	"地牢（0,0）": {
		"id": "200058", 
		"name": "地牢（0,0）", 
		"level": 550, 
		"description": "地牢 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "meng_meng", "level": 550}, 
			{"pet_id": "linlin", "level": 540}, 
		]
	}, 
	"地牢（51,53）": {
		"id": "200058", 
		"name": "地牢（51,53）", 
		"level": 550, 
		"description": "地牢 - 坐标(51,53)", 
		"monsters": [
			{"pet_id": "meng_meng", "level": 550}, 
			{"pet_id": "meng_meng", "level": 540}, 
		]
	}, 
	"莹冰桥（28,6）": {
		"id": "300038", 
		"name": "莹冰桥（28,6）", 
		"level": 550, 
		"description": "莹冰桥 - 坐标(28,6)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 535}, 
			{"pet_id": "yáoyé", "level": 550}, 
		]
	}, 
	"地牢（28,34）": {
		"id": "200058", 
		"name": "地牢（28,34）", 
		"level": 570, 
		"description": "地牢 - 坐标(28,34)", 
		"monsters": [
			{"pet_id": "meng_meng", "level": 530}, 
			{"pet_id": "linlin", "level": 570}, 
		]
	}, 
	"落雁谷（0,0）": {
		"id": "200010", 
		"name": "落雁谷（0,0）", 
		"level": 575, 
		"description": "落雁谷 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 550}, 
			{"pet_id": "qíshìgūi", "level": 575}, 
		]
	}, 
	"莹玉桥（0,0）": {
		"id": "300039", 
		"name": "莹玉桥（0,0）", 
		"level": 580, 
		"description": "莹玉桥 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 560}, 
			{"pet_id": "ouou", "level": 580}, 
		]
	}, 
	"旋割地狱（0,0）": {
		"id": "600010", 
		"name": "旋割地狱（0,0）", 
		"level": 580, 
		"description": "旋割地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 550}, 
			{"pet_id": "yáoyé", "level": 580}, 
		]
	}, 
	"独孤独亭（0,0）": {
		"id": "700002", 
		"name": "独孤独亭（0,0）", 
		"level": 580, 
		"description": "独孤独亭 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "cǎomǎngtù", "level": 560}, 
			{"pet_id": "fuyejiu", "level": 580}, 
		]
	}, 
	"悬台（0,0）": {
		"id": "200059", 
		"name": "悬台（0,0）", 
		"level": 590, 
		"description": "悬台 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 580}, 
			{"pet_id": "shuaidaixiang", "level": 590}, 
		]
	}, 
	"悬台（55,55）": {
		"id": "200059", 
		"name": "悬台（55,55）", 
		"level": 590, 
		"description": "悬台 - 坐标(55,55)", 
		"monsters": [
			{"pet_id": "shuaidaixiang", "level": 580}, 
			{"pet_id": "shuaidaixiang", "level": 590}, 
		]
	}, 
	"流沙原（0,0）": {
		"id": "200023", 
		"name": "流沙原（0,0）", 
		"level": 600, 
		"description": "流沙原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 590}, 
			{"pet_id": "mímáng", "level": 600}, 
		]
	}, 
	"流沙原（38,22）": {
		"id": "200023", 
		"name": "流沙原（38,22）", 
		"level": 600, 
		"description": "流沙原 - 坐标(38,22)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 600}, 
			{"pet_id": "mímáng", "level": 598}, 
		]
	}, 
	"流沙原（74,85）": {
		"id": "200023", 
		"name": "流沙原（74,85）", 
		"level": 600, 
		"description": "流沙原 - 坐标(74,85)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 590}, 
			{"pet_id": "lanmengmeng", "level": 600}, 
		]
	}, 
	"落雁谷（24,34）": {
		"id": "200010", 
		"name": "落雁谷（24,34）", 
		"level": 620, 
		"description": "落雁谷 - 坐标(24,34)", 
		"monsters": [
			{"pet_id": "kōngshǒudào", "level": 600}, 
			{"pet_id": "qíshìgūi", "level": 620}, 
		]
	}, 
	"余恨原（0,0）": {
		"id": "200022", 
		"name": "余恨原（0,0）", 
		"level": 620, 
		"description": "余恨原 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "wang_wang", "level": 610}, 
			{"pet_id": "kubixiang", "level": 620}, 
		]
	}, 
	"悬台（40,42）": {
		"id": "200059", 
		"name": "悬台（40,42）", 
		"level": 620, 
		"description": "悬台 - 坐标(40,42)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 600}, 
			{"pet_id": "shuaidaixiang", "level": 620}, 
		]
	}, 
	"莹玉桥（53,33）": {
		"id": "300039", 
		"name": "莹玉桥（53,33）", 
		"level": 620, 
		"description": "莹玉桥 - 坐标(53,33)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 600}, 
			{"pet_id": "ouou", "level": 620}, 
		]
	}, 
	"余恨原（13,20）": {
		"id": "200022", 
		"name": "余恨原（13,20）", 
		"level": 640, 
		"description": "余恨原 - 坐标(13,20)", 
		"monsters": [
			{"pet_id": "wang_wang", "level": 630}, 
			{"pet_id": "yunhu", "level": 640}, 
		]
	}, 
	"落雁谷（64,70）": {
		"id": "200010", 
		"name": "落雁谷（64,70）", 
		"level": 650, 
		"description": "落雁谷 - 坐标(64,70)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 630}, 
			{"pet_id": "qíshìgūi", "level": 650}, 
		]
	}, 
	"莹玉桥（22,15）": {
		"id": "300039", 
		"name": "莹玉桥（22,15）", 
		"level": 650, 
		"description": "莹玉桥 - 坐标(22,15)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 630}, 
			{"pet_id": "ouou", "level": 650}, 
		]
	}, 
	"深碧海城（0,0）": {
		"id": "400001", 
		"name": "深碧海城（0,0）", 
		"level": 650, 
		"description": "深碧海城 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 600}, 
			{"pet_id": "lv̀jiǎ", "level": 650}, 
		]
	}, 
	"独孤独亭（32,19）": {
		"id": "700002", 
		"name": "独孤独亭（32,19）", 
		"level": 650, 
		"description": "独孤独亭 - 坐标(32,19)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 620}, 
			{"pet_id": "cǎomǎngtù", "level": 650}, 
		]
	}, 
	"吊烤地狱（0,0）": {
		"id": "600011", 
		"name": "吊烤地狱（0,0）", 
		"level": 670, 
		"description": "吊烤地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 650}, 
			{"pet_id": "yìnggǔè", "level": 670}, 
		]
	}, 
	"华山脚（0,0）": {
		"id": "100042", 
		"name": "华山脚（0,0）", 
		"level": 740, 
		"description": "华山脚 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 710}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 740}, 
		]
	}, 
	"沙寇洞口（39,39）": {
		"id": "200024", 
		"name": "沙寇洞口（39,39）", 
		"level": 750, 
		"description": "沙寇洞口 - 坐标(39,39)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 750}, 
			{"pet_id": "fengwu", "level": 750}, 
		]
	}, 
	"紫藓洞窟（0,0）": {
		"id": "200044", 
		"name": "紫藓洞窟（0,0）", 
		"level": 770, 
		"description": "紫藓洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhaicitou", "level": 720}, 
			{"pet_id": "lv̀jǐnbǎo", "level": 770}, 
		]
	}, 
	"玄铜洞窟（0,0）": {
		"id": "200043", 
		"name": "玄铜洞窟（0,0）", 
		"level": 780, 
		"description": "玄铜洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèlèxióng", "level": 730}, 
			{"pet_id": "báimáoxiàng", "level": 780}, 
		]
	}, 
	"铜钟洞窟（0,0）": {
		"id": "200045", 
		"name": "铜钟洞窟（0,0）", 
		"level": 780, 
		"description": "铜钟洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "míhuò", "level": 720}, 
			{"pet_id": "zhōngdāo", "level": 780}, 
		]
	}, 
	"深碧海底（0,0）": {
		"id": "400002", 
		"name": "深碧海底（0,0）", 
		"level": 780, 
		"description": "深碧海底 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 720}, 
			{"pet_id": "lv̀jiǎ", "level": 780}, 
		]
	}, 
	"钉床地狱（0,0）": {
		"id": "600012", 
		"name": "钉床地狱（0,0）", 
		"level": 780, 
		"description": "钉床地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 750}, 
			{"pet_id": "yáoyé", "level": 780}, 
		]
	}, 
	"沙寇洞口（0,0）": {
		"id": "200024", 
		"name": "沙寇洞口（0,0）", 
		"level": 800, 
		"description": "沙寇洞口 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 800}, 
			{"pet_id": "fengwu", "level": 795}, 
		]
	}, 
	"沙寇洞口（24,24）": {
		"id": "200024", 
		"name": "沙寇洞口（24,24）", 
		"level": 800, 
		"description": "沙寇洞口 - 坐标(24,24)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 800}, 
			{"pet_id": "mímáng", "level": 795}, 
		]
	}, 
	"华山脚（51,31）": {
		"id": "100042", 
		"name": "华山脚（51,31）", 
		"level": 820, 
		"description": "华山脚 - 坐标(51,31)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 780}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 820}, 
		]
	}, 
	"剥皮地狱（0,0）": {
		"id": "600001", 
		"name": "剥皮地狱（0,0）", 
		"level": 825, 
		"description": "剥皮地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qiāoqiāoshǔ", "level": 800}, 
			{"pet_id": "yìnggǔè", "level": 825}, 
		]
	}, 
	"铜钟洞窟（50,37）": {
		"id": "200045", 
		"name": "铜钟洞窟（50,37）", 
		"level": 850, 
		"description": "铜钟洞窟 - 坐标(50,37)", 
		"monsters": [
			{"pet_id": "míhuò", "level": 820}, 
			{"pet_id": "zhōngdāo", "level": 850}, 
		]
	}, 
	"玄铜洞窟（35,49）": {
		"id": "200043", 
		"name": "玄铜洞窟（35,49）", 
		"level": 870, 
		"description": "玄铜洞窟 - 坐标(35,49)", 
		"monsters": [
			{"pet_id": "lèlèxióng", "level": 820}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 870}, 
		]
	}, 
	"磨骨地狱（0,0）": {
		"id": "600013", 
		"name": "磨骨地狱（0,0）", 
		"level": 870, 
		"description": "磨骨地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zǐtíxiānshēng", "level": 850}, 
			{"pet_id": "dàdāo", "level": 870}, 
		]
	}, 
	"华山脚（35,52）": {
		"id": "100042", 
		"name": "华山脚（35,52）", 
		"level": 880, 
		"description": "华山脚 - 坐标(35,52)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 850}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 880}, 
		]
	}, 
	"紫藓洞窟（32,40）": {
		"id": "200044", 
		"name": "紫藓洞窟（32,40）", 
		"level": 880, 
		"description": "紫藓洞窟 - 坐标(32,40)", 
		"monsters": [
			{"pet_id": "daicitou", "level": 820}, 
			{"pet_id": "lv̀jǐnbǎo", "level": 880}, 
		]
	}, 
	"小小房间（0,0）": {
		"id": "400009", 
		"name": "小小房间（0,0）", 
		"level": 880, 
		"description": "小小房间 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "ouou", "level": 830}, 
			{"pet_id": "lv̀jiǎ", "level": 880}, 
		]
	}, 
	"铜钟洞窟（29,43）": {
		"id": "200045", 
		"name": "铜钟洞窟（29,43）", 
		"level": 900, 
		"description": "铜钟洞窟 - 坐标(29,43)", 
		"monsters": [
			{"pet_id": "míhuò", "level": 870}, 
			{"pet_id": "zhōngdāo", "level": 900}, 
		]
	}, 
	"华山顶（0,0）": {
		"id": "100047", 
		"name": "华山顶（0,0）", 
		"level": 930, 
		"description": "华山顶 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 920}, 
			{"pet_id": "dàidāo", "level": 930}, 
		]
	}, 
	"华山顶（22,23）": {
		"id": "100047", 
		"name": "华山顶（22,23）", 
		"level": 960, 
		"description": "华山顶 - 坐标(22,23)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 940}, 
			{"pet_id": "dàidāo", "level": 960}, 
		]
	}, 
	"华山亭（0,0）": {
		"id": "100043", 
		"name": "华山亭（0,0）", 
		"level": 970, 
		"description": "华山亭 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 930}, 
			{"pet_id": "yìnggǔè", "level": 970}, 
		]
	}, 
	"玄铜洞窟2（0,0）": {
		"id": "200047", 
		"name": "玄铜洞窟2（0,0）", 
		"level": 980, 
		"description": "玄铜洞窟2 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 920}, 
			{"pet_id": "lǎnlǎnxiàng", "level": 980}, 
		]
	}, 
	"青铜洞窟（0,0）": {
		"id": "200048", 
		"name": "青铜洞窟（0,0）", 
		"level": 980, 
		"description": "青铜洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 920}, 
			{"pet_id": "hóngjǐnbǎo", "level": 980}, 
		]
	}, 
	"碧水洞窟（0,0）": {
		"id": "200050", 
		"name": "碧水洞窟（0,0）", 
		"level": 980, 
		"description": "碧水洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 920}, 
			{"pet_id": "lv̀jǐnbǎo", "level": 980}, 
		]
	}, 
	"小房间（0,0）": {
		"id": "400010", 
		"name": "小房间（0,0）", 
		"level": 980, 
		"description": "小房间 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "yáoyé", "level": 930}, 
			{"pet_id": "lv̀jiǎ", "level": 980}, 
		]
	}, 
	"铡头地狱（0,0）": {
		"id": "600014", 
		"name": "铡头地狱（0,0）", 
		"level": 990, 
		"description": "铡头地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 950}, 
			{"pet_id": "yáoyé", "level": 990}, 
		]
	}, 
	"碧水洞窟（29,14）": {
		"id": "200050", 
		"name": "碧水洞窟（29,14）", 
		"level": 1000, 
		"description": "碧水洞窟 - 坐标(29,14)", 
		"monsters": [
			{"pet_id": "meng_meng", "level": 900}, 
			{"pet_id": "mímáng", "level": 1000}, 
		]
	}, 
	"华山腰道（0,0）": {
		"id": "100044", 
		"name": "华山腰道（0,0）", 
		"level": 1050, 
		"description": "华山腰道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "linlin", "level": 1020}, 
			{"pet_id": "lu_lu", "level": 1050}, 
		]
	}, 
	"污秽地狱（0,0）": {
		"id": "600015", 
		"name": "污秽地狱（0,0）", 
		"level": 1050, 
		"description": "污秽地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "hóngdāo", "level": 1050}, 
			{"pet_id": "tiějiǎgūi", "level": 1010}, 
		]
	}, 
	"玄铜洞窟2（49,38）": {
		"id": "200047", 
		"name": "玄铜洞窟2（49,38）", 
		"level": 1060, 
		"description": "玄铜洞窟2 - 坐标(49,38)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 1030}, 
			{"pet_id": "lǎnlǎnxiàng", "level": 1060}, 
		]
	}, 
	"青铜洞窟（51,44）": {
		"id": "200048", 
		"name": "青铜洞窟（51,44）", 
		"level": 1080, 
		"description": "青铜洞窟 - 坐标(51,44)", 
		"monsters": [
			{"pet_id": "duxing", "level": 1020}, 
			{"pet_id": "hóngjǐnbǎo", "level": 1080}, 
		]
	}, 
	"碧水洞窟（28,34）": {
		"id": "200050", 
		"name": "碧水洞窟（28,34）", 
		"level": 1080, 
		"description": "碧水洞窟 - 坐标(28,34)", 
		"monsters": [
			{"pet_id": "mímáng", "level": 1030}, 
			{"pet_id": "dàidāo", "level": 1080}, 
		]
	}, 
	"过道（0,0）": {
		"id": "400011", 
		"name": "过道（0,0）", 
		"level": 1080, 
		"description": "过道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 1030}, 
			{"pet_id": "lányá", "level": 1080}, 
		]
	}, 
	"玄铜洞窟2（30,47）": {
		"id": "200047", 
		"name": "玄铜洞窟2（30,47）", 
		"level": 1100, 
		"description": "玄铜洞窟2 - 坐标(30,47)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 1080}, 
			{"pet_id": "báimáoxiàng", "level": 1100}, 
		]
	}, 
	"青铜洞窟（26,55）": {
		"id": "200048", 
		"name": "青铜洞窟（26,55）", 
		"level": 1100, 
		"description": "青铜洞窟 - 坐标(26,55)", 
		"monsters": [
			{"pet_id": "lanmengmeng", "level": 1090}, 
			{"pet_id": "hóngjǐnbǎo", "level": 1100}, 
		]
	}, 
	"华山腰道（18,49）": {
		"id": "100044", 
		"name": "华山腰道（18,49）", 
		"level": 1120, 
		"description": "华山腰道 - 坐标(18,49)", 
		"monsters": [
			{"pet_id": "lu_lu", "level": 1080}, 
			{"pet_id": "linlin", "level": 1120}, 
		]
	}, 
	"华山腰道（50,26）": {
		"id": "100044", 
		"name": "华山腰道（50,26）", 
		"level": 1180, 
		"description": "华山腰道 - 坐标(50,26)", 
		"monsters": [
			{"pet_id": "linlin", "level": 1150}, 
			{"pet_id": "lu_lu", "level": 1180}, 
		]
	}, 
	"蟠龙洞窟（0,0）": {
		"id": "200051", 
		"name": "蟠龙洞窟（0,0）", 
		"level": 1180, 
		"description": "蟠龙洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèlèxióng", "level": 1150}, 
			{"pet_id": "qiāoqiāoshǔ", "level": 1180}, 
		]
	}, 
	"紫藓洞窟2（0,0）": {
		"id": "200052", 
		"name": "紫藓洞窟2（0,0）", 
		"level": 1180, 
		"description": "紫藓洞窟2 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "fengwu", "level": 1130}, 
			{"pet_id": "lv̀jǐnbǎo", "level": 1180}, 
		]
	}, 
	"黄铜洞窟2（0,0）": {
		"id": "200053", 
		"name": "黄铜洞窟2（0,0）", 
		"level": 1180, 
		"description": "黄铜洞窟2 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhōngdāo", "level": 1130}, 
			{"pet_id": "xiǎoyāo", "level": 1180}, 
		]
	}, 
	"窄窄的过道（0,0）": {
		"id": "400012", 
		"name": "窄窄的过道（0,0）", 
		"level": 1180, 
		"description": "窄窄的过道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 1130}, 
			{"pet_id": "lv̀jiǎ", "level": 1180}, 
		]
	}, 
	"天灯地狱（0,0）": {
		"id": "600016", 
		"name": "天灯地狱（0,0）", 
		"level": 1180, 
		"description": "天灯地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "xiǎodīngdāng", "level": 1150}, 
			{"pet_id": "yáoyé", "level": 1180}, 
		]
	}, 
	"焰浆地狱（0,0）": {
		"id": "600017", 
		"name": "焰浆地狱（0,0）", 
		"level": 1250, 
		"description": "焰浆地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zǐtíxiānshēng", "level": 1200}, 
			{"pet_id": "dàdāo", "level": 1250}, 
		]
	}, 
	"紫藓洞窟2（32,38）": {
		"id": "200052", 
		"name": "紫藓洞窟2（32,38）", 
		"level": 1280, 
		"description": "紫藓洞窟2 - 坐标(32,38)", 
		"monsters": [
			{"pet_id": "duxing", "level": 1220}, 
			{"pet_id": "hóngjǐnbǎo", "level": 1280}, 
		]
	}, 
	"黄铜洞窟2（17,33）": {
		"id": "200053", 
		"name": "黄铜洞窟2（17,33）", 
		"level": 1280, 
		"description": "黄铜洞窟2 - 坐标(17,33)", 
		"monsters": [
			{"pet_id": "xiǎoyāo", "level": 1230}, 
			{"pet_id": "dàidāo", "level": 1280}, 
		]
	}, 
	"很窄的过道（0,0）": {
		"id": "400013", 
		"name": "很窄的过道（0,0）", 
		"level": 1280, 
		"description": "很窄的过道 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiájiá", "level": 1250}, 
			{"pet_id": "lányá", "level": 1280}, 
		]
	}, 
	"华山瀑布（0,0）": {
		"id": "100045", 
		"name": "华山瀑布（0,0）", 
		"level": 1290, 
		"description": "华山瀑布 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 1250}, 
			{"pet_id": "yìnggǔè", "level": 1290}, 
		]
	}, 
	"蟠龙洞窟（46,65）": {
		"id": "200051", 
		"name": "蟠龙洞窟（46,65）", 
		"level": 1300, 
		"description": "蟠龙洞窟 - 坐标(46,65)", 
		"monsters": [
			{"pet_id": "mìmìxióng", "level": 1250}, 
			{"pet_id": "báimáoxiàng", "level": 1300}, 
		]
	}, 
	"幽界之森（0,0）": {
		"id": "600122", 
		"name": "幽界之森（0,0）", 
		"level": 1300, 
		"description": "幽界之森 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "youling", "level": 1300}, 
			{"pet_id": "youling", "level": 1300}, 
		]
	}, 
	"传说中的侠骨冢（0,0）": {
		"id": "300028", 
		"name": "传说中的侠骨冢（0,0）", 
		"level": 1305, 
		"description": "传说中的侠骨冢 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "huángjǐnbǎo", "level": 1300}, 
			{"pet_id": "huángjǐnbǎo", "level": 1305}, 
		]
	}, 
	"华山瀑布（5,14）": {
		"id": "100045", 
		"name": "华山瀑布（5,14）", 
		"level": 1380, 
		"description": "华山瀑布 - 坐标(5,14)", 
		"monsters": [
			{"pet_id": "jiéquándào", "level": 1330}, 
			{"pet_id": "yìnggǔè", "level": 1380}, 
		]
	}, 
	"石笋洞窟（0,0）": {
		"id": "200054", 
		"name": "石笋洞窟（0,0）", 
		"level": 1450, 
		"description": "石笋洞窟 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "duoluotianlang", "level": 1430}, 
			{"pet_id": "zǐtíxiānshēng", "level": 1450}, 
		]
	}, 
	"石笋洞窟（71,27）": {
		"id": "200054", 
		"name": "石笋洞窟（71,27）", 
		"level": 1450, 
		"description": "石笋洞窟 - 坐标(71,27)", 
		"monsters": [
			{"pet_id": "duoluotianlang", "level": 1450}, 
			{"pet_id": "zǐtíxiānshēng", "level": 1430}, 
		]
	}, 
	"蟠龙洞窟2（0,0）": {
		"id": "200055", 
		"name": "蟠龙洞窟2（0,0）", 
		"level": 1450, 
		"description": "蟠龙洞窟2 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "qibiantianlang", "level": 1430}, 
			{"pet_id": "dong_yue_shen_yuan", "level": 1450}, 
		]
	}, 
	"蟠龙洞窟2（25,24）": {
		"id": "200055", 
		"name": "蟠龙洞窟2（25,24）", 
		"level": 1450, 
		"description": "蟠龙洞窟2 - 坐标(25,24)", 
		"monsters": [
			{"pet_id": "qibiantianlang", "level": 1450}, 
			{"pet_id": "dong_yue_shen_yuan", "level": 1430}, 
		]
	}, 
	"盈露台守望区（0,0）": {
		"id": "500016", 
		"name": "盈露台守望区（0,0）", 
		"level": 1500, 
		"description": "盈露台守望区 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "fuyejiu", "level": 1500}, 
			{"pet_id": "fuyejiu", "level": 1500}, 
		]
	}, 
	"盈露台守望区（39,28）": {
		"id": "500016", 
		"name": "盈露台守望区（39,28）", 
		"level": 1500, 
		"description": "盈露台守望区 - 坐标(39,28)", 
		"monsters": [
			{"pet_id": "fuyejiu", "level": 1500}, 
			{"pet_id": "huang_long_shi", "level": 1500}, 
		]
	}, 
	"油锅地狱（0,0）": {
		"id": "600018", 
		"name": "油锅地狱（0,0）", 
		"level": 1500, 
		"description": "油锅地狱 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 1500}, 
			{"pet_id": "dàdāo", "level": 1500}, 
		]
	}, 
	"油锅地狱（31,31）": {
		"id": "600018", 
		"name": "油锅地狱（31,31）", 
		"level": 1500, 
		"description": "油锅地狱 - 坐标(31,31)", 
		"monsters": [
			{"pet_id": "dàdāo", "level": 1500}, 
			{"pet_id": "lv_yi_xian_zi", "level": 1500}, 
		]
	}, 
	"九曲回廊（16,21）": {
		"id": "131007", 
		"name": "九曲回廊（16,21）", 
		"level": 1970, 
		"description": "九曲回廊 - 坐标(16,21)", 
		"monsters": [
			{"pet_id": "xiǎoyāo", "level": 1930}, 
			{"pet_id": "kucitou", "level": 1970}, 
		]
	}, 
	"九曲回廊（0,0）": {
		"id": "131008", 
		"name": "九曲回廊（0,0）", 
		"level": 2235, 
		"description": "九曲回廊 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 2210}, 
			{"pet_id": "cǎomǎngtù", "level": 2235}, 
		]
	}, 
	"九曲回廊（29,39）": {
		"id": "131008", 
		"name": "九曲回廊（29,39）", 
		"level": 2270, 
		"description": "九曲回廊 - 坐标(29,39)", 
		"monsters": [
			{"pet_id": "tao_tao", "level": 2230}, 
			{"pet_id": "nununiao", "level": 2270}, 
		]
	}, 
	"清邃古洞（0,0）": {
		"id": "131009", 
		"name": "清邃古洞（0,0）", 
		"level": 2500, 
		"description": "清邃古洞 - 坐标(0,0)", 
		"monsters": [
			{"pet_id": "zhenzhen", "level": 2500}, 
			{"pet_id": "xi_pi", "level": 2500}, 
		]
	}, 
	"清邃古洞（37,17）": {
		"id": "131009", 
		"name": "清邃古洞（37,17）", 
		"level": 2500, 
		"description": "清邃古洞 - 坐标(37,17)", 
		"monsters": [
			{"pet_id": "luluniao", "level": 2500}, 
			{"pet_id": "wen_di_long", "level": 2500}, 
		]
	}, 
	"九曲回廊（34,39）": {
		"id": "131007", 
		"name": "九曲回廊（34,39）", 
		"level": 2500, 
		"description": "九曲回廊 - 坐标(34,39)", 
		"monsters": [
			{"pet_id": "lèngtóuqīng", "level": 2500}, 
			{"pet_id": "xiǎoyāo", "level": 2500}, 
		]
	}, 
	"九曲回廊（42,29）": {
		"id": "131008", 
		"name": "九曲回廊（42,29）", 
		"level": 2500, 
		"description": "九曲回廊 - 坐标(42,29)", 
		"monsters": [
			{"pet_id": "tiějiǎgūi", "level": 2500}, 
			{"pet_id": "tao_tao", "level": 2500}, 
		]
	}, 
	"清邃古洞（66,44）": {
		"id": "131009", 
		"name": "清邃古洞（66,44）", 
		"level": 2500, 
		"description": "清邃古洞 - 坐标(66,44)", 
		"monsters": [
			{"pet_id": "zhenzhen", "level": 2500}, 
			{"pet_id": "luluniao", "level": 2500}, 
		]
	}, 
}


const PET_DATA = {
	"tongbao": {
		"name": "通宝", 
		"type": "防敏型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 6.4, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 40, 30]
	}, 
	"yuanbao": {
		"name": "元宝", 
		"type": "防敏型", 
		"element": "金", 
		"attack": 4.0, 
		"defense": 7.2, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 45, 30]
	}, 
	"tianbao": {
		"name": "天宝", 
		"type": "防敏型", 
		"element": "金", 
		"attack": 4.0, 
		"defense": 6.4, 
		"agility": 5.6, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 40, 35]
	}, 
	"bianyianu": {
		"name": "变异阿努", 
		"type": "平均型", 
		"element": "火", 
		"attack": 9.0, 
		"defense": 9.0, 
		"agility": 9.0, 
		"hp": 65.0, 
		"growth": 3.5, 
		"hp_growth": 3.5, 
		"ratio": [33, 33, 34], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "五一节日活动宠物"
	}, 
	"feicuilong": {
		"name": "翡翠龙", 
		"type": "平均型", 
		"element": "水", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "端午节活动宠物"
	}, 
	"qixitu": {
		"name": "七夕兔", 
		"type": "平均型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "七夕节活动宠物"
	}, 
	"zhongqiujinhu": {
		"name": "中秋金虎", 
		"type": "平均型", 
		"element": "金", 
		"attack": 8.0, 
		"defense": 6.0, 
		"agility": 8.0, 
		"hp": 50.0, 
		"growth": 3.6, 
		"hp_growth": 3.6, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"is_festival_pet": true, 
		"collection_flavor": "中秋节活动宠物"
	}, 
	"nezha": {
		"name": "哪吒", 
		"type": "平均型", 
		"element": "火", 
		"attack": 10.0, 
		"defense": 10.0, 
		"agility": 10.0, 
		"hp": 70.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [35, 30, 35], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "贵族10专属奖励"
	}, 

	"huangyidaonan": {
		"name": "刀男", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"maiduo": {
		"name": "麦朵", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shuangyanzhan": {
		"name": "双炎斩", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 12.0, 
		"defense": 18.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [39, 60, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"heicaishen": {
		"name": "黑财神", 
		"type": "攻防型", 
		"element": "天", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"lianyugulong": {
		"name": "炼狱骨龙", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 14.0, 
		"defense": 1.0, 
		"agility": 15.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 1, 54], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"zhusisi": {
		"name": "猪丝丝", 
		"type": "防御型", 
		"element": "木", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shizizuo": {
		"name": "狮子座", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 17.0, 
		"defense": 1.0, 
		"agility": 12.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [58, 1, 41], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"yuzu": {
		"name": "狱卒", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"yizhanmafu": {
		"name": "驿站马夫", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 26.0, 
		"defense": 1.0, 
		"agility": 3.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [90, 1, 9], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"kezhanmeimei": {
		"name": "客栈妹妹", 
		"type": "防御型", 
		"element": "水", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"shaiziwangwu": {
		"name": "骰子王五", 
		"type": "防御型", 
		"element": "火", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"songbukuai": {
		"name": "宋捕快", 
		"type": "防御型", 
		"element": "金", 
		"attack": 1.0, 
		"defense": 28.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [1, 98, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"cailin": {
		"name": "彩鳞", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [45, 54, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"goumang": {
		"name": "句芒", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"qingqiujiuwei": {
		"name": "青丘九尾", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 20.0, 
		"defense": 1.0, 
		"agility": 9.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [66, 1, 33], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"longzhanjiang": {
		"name": "龙战将", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 13.0, 
		"defense": 16.0, 
		"agility": 1.0, 
		"hp": 80.0, 
		"growth": 6.0, 
		"hp_growth": 6.0, 
		"ratio": [44, 55, 1], 
		"is_event_limited": true, 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"event_pool": "limited_event_pets", 
		"collection_flavor": "旧岁遗珍"
	}, 
	"chulong": {
		"name": "雏龙", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"shalongzhiren": {
		"name": "杀龙之刃", 
		"type": "攻敏型", 
		"element": "金", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"xianrenzhang": {
		"name": "仙人掌", 
		"type": "攻敏型", 
		"element": "木", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"yinying": {
		"name": "阴影", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 12.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [42, 16, 42], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"shitouren": {
		"name": "石头人", 
		"type": "防御型", 
		"element": "土", 
		"attack": 11.0, 
		"defense": 15.0, 
		"agility": 4.0, 
		"hp": 56.0, 
		"growth": 3.6, 
		"hp_growth": 6.0, 
		"ratio": [38, 50, 12], 
		"is_soul_reward_pet": true, 
		"soul_reward_pool": "soul_reward_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "宠物魂魄玩法投入成品宠物几率获得"
	}, 
	"huozhiyizhi": {
		"name": "火之意志", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"jinzhizhuzai": {
		"name": "金之主宰", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"muzhiguize": {
		"name": "木之规则", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"tuzhixianjie": {
		"name": "土之限界", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"shuizhizhangkong": {
		"name": "水之掌控", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 9.0, 
		"defense": 12.0, 
		"agility": 3.0, 
		"hp": 60.0, 
		"growth": 4.0, 
		"hp_growth": 6.0, 
		"ratio": [30, 60, 10], 
		"is_world_boss_pet": true, 
		"world_boss_pool": "world_boss_pets", 
		"collection_display_only": true, 
		"collection_disabled": true, 
		"collection_flavor": "参与每日世界boss挑战几率获得"
	}, 
	"wudidan": {
		"name": "无敌蛋", 
		"type": "防御型", 
		"element": "金", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"tianshidan": {
		"name": "天使蛋", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 55, 15]
	}, 
	"yaogundan": {
		"name": "摇滚蛋", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"chuanshanshou": {
		"name": "穿山兽", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"chuandishou": {
		"name": "穿地兽", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"chuanlinshou": {
		"name": "穿林兽", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"shenjia": {
		"name": "神甲", 
		"type": "防御型", 
		"element": "金", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"mojia": {
		"name": "魔甲", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"guguai": {
		"name": "古怪", 
		"type": "攻防型", 
		"element": "金", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"shenqi": {
		"name": "神气", 
		"type": "攻防型", 
		"element": "金", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"haha": {
		"name": "哈哈", 
		"type": "攻防型", 
		"element": "金", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"lingyilong": {
		"name": "灵翼龙", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 6.08, 
		"defense": 2.72, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"fengyilong": {
		"name": "风翼龙", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 3.52, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"qingyilong": {
		"name": "轻翼龙", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 2.72, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"xiaoleigong": {
		"name": "小雷公", 
		"type": "防御型", 
		"element": "金", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"xiaoleishen": {
		"name": "小雷神", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 55, 15]
	}, 
	"xiaopili": {
		"name": "小霹雳", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"shuijinger": {
		"name": "水晶儿", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.9, 
		"defense": 7.0, 
		"agility": 2.1, 
		"hp": 19.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [35, 50, 15]
	}, 
	"jingtianshi": {
		"name": "晶天使", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 6.84, 
		"defense": 8.1, 
		"agility": 3.06, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [38, 45, 17]
	}, 
	"mengjingling": {
		"name": "梦晶灵", 
		"type": "平均型", 
		"element": "金", 
		"attack": 6, 
		"defense": 6, 
		"agility": 6, 
		"hp": 30, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 33, 34]
	}, 
	"huanjinggang": {
		"name": "幻晶刚", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 5, 
		"defense": 8, 
		"agility": 3, 
		"hp": 30, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [35, 48, 17]
	}, 
	"abuluo": {
		"name": "阿波罗", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"qiuzhang": {
		"name": "酋长", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"nawahuo": {
		"name": "纳瓦霍", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"huahua": {
		"name": "花花", 
		"type": "平均型", 
		"element": "木", 
		"attack": 6.24, 
		"defense": 4.8, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"caicai": {
		"name": "采采", 
		"type": "平均型", 
		"element": "木", 
		"attack": 5.44, 
		"defense": 5.6, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"diandian": {
		"name": "点点", 
		"type": "平均型", 
		"element": "木", 
		"attack": 5.44, 
		"defense": 4.8, 
		"agility": 5.76, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"quanshi": {
		"name": "拳师", 
		"type": "攻击型", 
		"element": "木", 
		"attack": 8.8, 
		"defense": 3.52, 
		"agility": 3.68, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [55, 22, 23]
	}, 
	"wushi": {
		"name": "武师", 
		"type": "攻击型", 
		"element": "木", 
		"attack": 8.0, 
		"defense": 4.32, 
		"agility": 3.68, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [50, 27, 23]
	}, 
	"biaoshi": {
		"name": "镖师", 
		"type": "攻击型", 
		"element": "木", 
		"attack": 8.0, 
		"defense": 3.52, 
		"agility": 4.48, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [50, 22, 28]
	}, 
	"shuyao": {
		"name": "树妖", 
		"type": "防御型", 
		"element": "木", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"shujing": {
		"name": "树精", 
		"type": "防御型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 55, 15]
	}, 
	"shuguai": {
		"name": "树怪", 
		"type": "防御型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"tianwenfeng": {
		"name": "天纹蜂", 
		"type": "敏攻型", 
		"element": "木", 
		"attack": 6.08, 
		"defense": 2.72, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"boluomi": {
		"name": "菠萝蜜", 
		"type": "敏攻型", 
		"element": "木", 
		"attack": 5.28, 
		"defense": 3.52, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"dumangfeng": {
		"name": "毒芒蜂", 
		"type": "敏攻型", 
		"element": "木", 
		"attack": 5.28, 
		"defense": 2.72, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"shuntian": {
		"name": "瞬天", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 5.6, 
		"defense": 2.4, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 15, 50]
	}, 
	"shundi": {
		"name": "瞬地", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 3.2, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 20, 50]
	}, 
	"shunfeng": {
		"name": "瞬风", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 2.4, 
		"agility": 8.8, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 15, 55]
	}, 
	"qiangdao": {
		"name": "强盗", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"tufei": {
		"name": "土匪", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"shanzei": {
		"name": "山贼", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"jifengju": {
		"name": "疾风驹", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 5.6, 
		"defense": 2.4, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 15, 50]
	}, 
	"zhuidianju": {
		"name": "追电驹", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 3.2, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 20, 50]
	}, 
	"xunleiju": {
		"name": "迅雷驹", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 2.4, 
		"agility": 8.8, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 15, 55]
	}, 
	"tiaopizai": {
		"name": "调皮仔", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.8, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 30, 40]
	}, 
	"kaixinzai": {
		"name": "开心仔", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 5.6, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 35, 40]
	}, 
	"huopozai": {
		"name": "活泼仔", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 4.8, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 30, 45]
	}, 
	"ciluo": {
		"name": "刺螺", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"kuiluo": {
		"name": "盔螺", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"hailuo": {
		"name": "海螺", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"tailang": {
		"name": "太郎", 
		"type": "平均型", 
		"element": "水", 
		"attack": 6.24, 
		"defense": 4.8, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"cilang": {
		"name": "次郎", 
		"type": "平均型", 
		"element": "水", 
		"attack": 5.44, 
		"defense": 5.6, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"sanlang": {
		"name": "三郎", 
		"type": "平均型", 
		"element": "水", 
		"attack": 5.44, 
		"defense": 4.8, 
		"agility": 5.76, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"paopaotun": {
		"name": "泡泡豚", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 5.6, 
		"defense": 2.4, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 15, 50]
	}, 
	"kukutun": {
		"name": "苦苦豚", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 3.2, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 20, 50]
	}, 
	"xuanxuantun": {
		"name": "玄玄豚", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 2.4, 
		"agility": 8.8, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 15, 55]
	}, 
	"lijian": {
		"name": "利箭", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 8.0, 
		"defense": 2.72, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"zhongjian": {
		"name": "重箭", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 7.2, 
		"defense": 3.52, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 22, 33]
	}, 
	"feijian": {
		"name": "飞箭", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 7.2, 
		"defense": 2.72, 
		"agility": 6.08, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 17, 38]
	}, 
	"changmei": {
		"name": "长眉", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 6.4, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 40, 30]
	}, 
	"zhimei": {
		"name": "智眉", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 7.2, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 45, 30]
	}, 
	"shoumei": {
		"name": "寿眉", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 6.4, 
		"agility": 5.6, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 40, 35]
	}, 
	"doudouyu": {
		"name": "斗斗鱼", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 6.08, 
		"defense": 2.72, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"fandouyu": {
		"name": "反斗鱼", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 5.28, 
		"defense": 3.52, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"xiudouyu": {
		"name": "秀斗鱼", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 5.28, 
		"defense": 2.72, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"shangguhuangshou": {
		"name": "上古荒兽", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 6.4, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 40, 30]
	}, 
	"taiguhuangshou": {
		"name": "太古荒兽", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 7.2, 
		"agility": 4.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 45, 30]
	}, 
	"yuanguhuangshou": {
		"name": "远古荒兽", 
		"type": "防敏型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 6.4, 
		"agility": 5.6, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 40, 35]
	}, 
	"xingyunxing": {
		"name": "幸运星", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.8, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 30, 40]
	}, 
	"jixiangxing": {
		"name": "吉祥星", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 5.6, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 35, 40]
	}, 
	"shouhuxing": {
		"name": "守护星", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 4.8, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 30, 45]
	}, 
	"moguiyu": {
		"name": "魔鬼鱼", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.8, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 30, 40]
	}, 
	"micaiyu": {
		"name": "迷彩鱼", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 5.6, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 35, 40]
	}, 
	"shenxianyu": {
		"name": "神仙鱼", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 4.8, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 30, 45]
	}, 
	"bajiaozi": {
		"name": "八脚仔", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 5.6, 
		"defense": 2.4, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 15, 50]
	}, 
	"modoubao": {
		"name": "墨斗宝", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 3.2, 
		"agility": 8.0, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 20, 50]
	}, 
	"wuyenzi": {
		"name": "乌鱼子", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 2.4, 
		"agility": 8.8, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 15, 55]
	}, 
	"yezixiong": {
		"name": "椰子熊", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"bianzixiong": {
		"name": "辫子熊", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"daizixiong": {
		"name": "带子熊", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"dianqiubaobao": {
		"name": "电球宝宝", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"pilibaobao": {
		"name": "霹雳宝宝", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"shandianbaobao": {
		"name": "闪电宝宝", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"guihuojun": {
		"name": "鬼火君", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 8.8, 
		"defense": 3.52, 
		"agility": 3.68, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [55, 22, 23]
	}, 
	"lieyanjun": {
		"name": "烈焰君", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 8.0, 
		"defense": 4.32, 
		"agility": 3.68, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [50, 27, 23]
	}, 
	"yaolinjun": {
		"name": "妖磷君", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 8.0, 
		"defense": 3.52, 
		"agility": 4.48, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [50, 22, 28]
	}, 
	"kaolaxiong": {
		"name": "考拉熊", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 8.0, 
		"defense": 2.72, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"xiaolanxiong": {
		"name": "小懒熊", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 3.52, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 22, 33]
	}, 
	"bunixiong": {
		"name": "布尼熊", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 2.72, 
		"agility": 6.08, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 17, 38]
	}, 
	"keke": {
		"name": "可可", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"doudou": {
		"name": "豆豆", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"shuaishuai": {
		"name": "帅帅", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"shanling": {
		"name": "闪灵", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"jingling": {
		"name": "精灵", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"youling": {
		"name": "幽灵", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"pilihuhu": {
		"name": "霹雳虎", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"banbanhu": {
		"name": "斑斑虎", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"guaiguaihu": {
		"name": "乖乖虎", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"linghu": {
		"name": "灵狐", 
		"type": "平均型", 
		"element": "火", 
		"attack": 6.24, 
		"defense": 4.8, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"yuehu": {
		"name": "月狐", 
		"type": "平均型", 
		"element": "火", 
		"attack": 5.44, 
		"defense": 5.6, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"yunhu": {
		"name": "云狐", 
		"type": "平均型", 
		"element": "火", 
		"attack": 5.44, 
		"defense": 4.8, 
		"agility": 5.76, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"baiguzhanshi": {
		"name": "白骨战士", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 7.7, 
		"defense": 3.08, 
		"agility": 3.22, 
		"hp": 31.0, 
		"growth": 3.5, 
		"hp_growth": 3.1, 
		"ratio": [55, 22, 23]
	}, 
	"kulouzhanshi": {
		"name": "骷髅战士", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 7.0, 
		"defense": 3.78, 
		"agility": 3.22, 
		"hp": 31.0, 
		"growth": 3.5, 
		"hp_growth": 3.1, 
		"ratio": [50, 27, 23]
	}, 
	"chongshengzhanshi": {
		"name": "重生战士", 
		"type": "攻血型", 
		"element": "火", 
		"attack": 7.0, 
		"defense": 3.08, 
		"agility": 3.92, 
		"hp": 31.0, 
		"growth": 3.5, 
		"hp_growth": 3.1, 
		"ratio": [50, 22, 28]
	}, 
	"wanglingwushi": {
		"name": "亡灵武士", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 6.84, 
		"defense": 8.1, 
		"agility": 3.06, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [38, 45, 17]
	}, 
	"silingwushi": {
		"name": "死灵武士", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.94, 
		"defense": 9.0, 
		"agility": 3.06, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 50, 17]
	}, 
	"zhonglingwushi": {
		"name": "忠灵武士", 
		"type": "防攻型", 
		"element": "火", 
		"attack": 5.94, 
		"defense": 8.1, 
		"agility": 3.96, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 45, 22]
	}, 
	"zhaohunshizhe": {
		"name": "招魂使者", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 12.5, 
		"defense": 8.25, 
		"agility": 4.25, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 33, 17]
	}, 
	"gouhunshizhe": {
		"name": "勾魂使者", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 11.25, 
		"defense": 9.5, 
		"agility": 4.25, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 38, 17]
	}, 
	"shehunshizhe": {
		"name": "摄魂使者", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 11.25, 
		"defense": 8.25, 
		"agility": 5.5, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 33, 22]
	}, 
	"xiaowushi": {
		"name": "小巫师", 
		"type": "敏防型", 
		"element": "火", 
		"attack": 9.0, 
		"defense": 9.0, 
		"agility": 12.0, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [30, 30, 40]
	}, 
	"xiaomoshi": {
		"name": "小魔师", 
		"type": "敏防型", 
		"element": "火", 
		"attack": 7.5, 
		"defense": 10.5, 
		"agility": 12.0, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [25, 35, 40]
	}, 
	"xiaofashi": {
		"name": "小法师", 
		"type": "敏防型", 
		"element": "火", 
		"attack": 7.5, 
		"defense": 9.0, 
		"agility": 13.5, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [25, 30, 45]
	}, 
	"xiaojiangshi": {
		"name": "小僵尸", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"tiaotiaogui": {
		"name": "跳跳鬼", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"munaibi": {
		"name": "木乃伊", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"wudi": {
		"name": "巫帝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 6.08, 
		"defense": 7.2, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"fadi": {
		"name": "法帝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.28, 
		"defense": 8.0, 
		"agility": 2.72, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"modi": {
		"name": "魔帝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.28, 
		"defense": 7.2, 
		"agility": 3.52, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"fengjingzhu": {
		"name": "风经蛛", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 2.72, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"diwenzhu": {
		"name": "地纹蛛", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 3.52, 
		"agility": 5.28, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 22, 33]
	}, 
	"xuanweizhu": {
		"name": "玄纬蛛", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 2.72, 
		"agility": 6.08, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 17, 38]
	}, 
	"chushane": {
		"name": "出山鳄", 
		"type": "防御型", 
		"element": "土", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"fudie": {
		"name": "伏地鳄", 
		"type": "防御型", 
		"element": "土", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 55, 15]
	}, 
	"guoxuee": {
		"name": "过穴鳄", 
		"type": "防御型", 
		"element": "土", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"fushuiqilin": {
		"name": "伏水麒麟", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 5.28, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"jinshuiqilin": {
		"name": "禁水麒麟", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 6.08, 
		"agility": 2.72, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"zhenshuiqilin": {
		"name": "镇水麒麟", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 5.28, 
		"agility": 3.52, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"chongbaobao": {
		"name": "虫宝宝", 
		"type": "平均型", 
		"element": "土", 
		"attack": 6.24, 
		"defense": 4.8, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"chongbeibei": {
		"name": "虫贝贝", 
		"type": "平均型", 
		"element": "土", 
		"attack": 5.44, 
		"defense": 5.6, 
		"agility": 4.96, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"xiaochong": {
		"name": "小虫", 
		"type": "平均型", 
		"element": "土", 
		"attack": 5.44, 
		"defense": 4.8, 
		"agility": 5.76, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"xiaozhubite": {
		"name": "小猪比特", 
		"type": "平均型", 
		"element": "土", 
		"attack": 5.46, 
		"defense": 4.2, 
		"agility": 4.34, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [39, 30, 31]
	}, 
	"xiaozhuanante": {
		"name": "小猪安特", 
		"type": "平均型", 
		"element": "土", 
		"attack": 4.76, 
		"defense": 4.9, 
		"agility": 4.34, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 35, 31]
	}, 
	"xiaozhufente": {
		"name": "小猪芬特", 
		"type": "平均型", 
		"element": "土", 
		"attack": 4.76, 
		"defense": 4.2, 
		"agility": 5.04, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 30, 36]
	}, 
	"zhongshanzhu": {
		"name": "中山猪", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 6.84, 
		"defense": 8.1, 
		"agility": 3.06, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [38, 45, 17]
	}, 
	"ximenzhu": {
		"name": "西门猪", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.94, 
		"defense": 9.0, 
		"agility": 3.06, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 50, 17]
	}, 
	"nangongzhu": {
		"name": "南宫猪", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.94, 
		"defense": 8.1, 
		"agility": 3.96, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 45, 22]
	}, 
	"beibatian": {
		"name": "北霸天", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 12.5, 
		"defense": 8.25, 
		"agility": 4.25, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 33, 17]
	}, 
	"nanbatian": {
		"name": "南霸天", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 11.25, 
		"defense": 9.5, 
		"agility": 4.25, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 38, 17]
	}, 
	"xiaobawang": {
		"name": "小霸王", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 11.25, 
		"defense": 8.25, 
		"agility": 5.5, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 33, 22]
	}, 
	"yijie": {
		"name": "一戒", 
		"type": "敏防型", 
		"element": "土", 
		"attack": 9.0, 
		"defense": 9.0, 
		"agility": 12.0, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [30, 30, 40]
	}, 
	"bajie": {
		"name": "八戒", 
		"type": "敏防型", 
		"element": "土", 
		"attack": 7.5, 
		"defense": 10.5, 
		"agility": 12.0, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [25, 35, 40]
	}, 
	"bujie": {
		"name": "不戒", 
		"type": "敏防型", 
		"element": "土", 
		"attack": 7.5, 
		"defense": 9.0, 
		"agility": 13.5, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [25, 30, 45]
	}, 
	"kucitou": {
		"name": "酷刺头", 
		"type": "防御型", 
		"element": "金", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [35, 50, 15]
	}, 
	"zhaicitou": {
		"name": "拽刺头", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 55, 15]
	}, 
	"daicitou": {
		"name": "呆刺头", 
		"type": "防御型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 26.0, 
		"growth": 4.0, 
		"hp_growth": 2.5, 
		"ratio": [30, 50, 20]
	}, 
	"fengwu": {
		"name": "风舞", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 6.1, 
		"defense": 2.7, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"duxing": {
		"name": "独行", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.3, 
		"defense": 3.5, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"lanmengmeng": {
		"name": "兰萌萌", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.3, 
		"defense": 2.7, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"baidazui": {
		"name": "白大嘴", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 6.08, 
		"defense": 2.72, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"landazui": {
		"name": "蓝大嘴", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 3.52, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"hongdazui": {
		"name": "红大嘴", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.28, 
		"defense": 2.72, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"xiaojingwei": {
		"name": "小精卫", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.25, 
		"defense": 2.25, 
		"agility": 7.5, 
		"hp": 21.0, 
		"growth": 3.9, 
		"hp_growth": 2.3, 
		"ratio": [35, 15, 50]
	}, 
	"luluniao": {
		"name": "露露鸟", 
		"type": "平均型", 
		"element": "金", 
		"attack": 5.5, 
		"defense": 4.2, 
		"agility": 4.3, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [39, 30, 31]
	}, 
	"nununiao": {
		"name": "努努鸟", 
		"type": "平均型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 4.9, 
		"agility": 4.3, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 35, 31]
	}, 
	"duduniao": {
		"name": "嘟嘟鸟", 
		"type": "平均型", 
		"element": "金", 
		"attack": 4.8, 
		"defense": 4.2, 
		"agility": 5.0, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 30, 36]
	}, 
	"fuyejiu": {
		"name": "拂叶鸠", 
		"type": "攻血型", 
		"element": "金", 
		"attack": 9.9, 
		"defense": 4.0, 
		"agility": 4.1, 
		"hp": 43.5, 
		"growth": 3.7, 
		"hp_growth": 3.4, 
		"ratio": [55, 22, 23]
	}, 
	"yulujiu": {
		"name": "浴露鸠", 
		"type": "攻血型", 
		"element": "金", 
		"attack": 9.0, 
		"defense": 4.9, 
		"agility": 4.1, 
		"hp": 43.5, 
		"growth": 3.7, 
		"hp_growth": 3.4, 
		"ratio": [50, 27, 23]
	}, 
	"miwuju": {
		"name": "觅雾鸠", 
		"type": "攻血型", 
		"element": "金", 
		"attack": 9.0, 
		"defense": 4.0, 
		"agility": 5.0, 
		"hp": 43.5, 
		"growth": 3.7, 
		"hp_growth": 3.4, 
		"ratio": [50, 22, 28]
	}, 
	"xuefenghuang": {
		"name": "雪凤凰", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 9.5, 
		"defense": 4.3, 
		"agility": 11.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [38, 17, 45]
	}, 
	"huofenghuang": {
		"name": "火凤凰", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 8.3, 
		"defense": 5.5, 
		"agility": 11.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [33, 22, 45]
	}, 
	"lanfenghuang": {
		"name": "蓝凤凰", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 8.3, 
		"defense": 4.3, 
		"agility": 12.5, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [33, 17, 50]
	}, 
	"feitianshu": {
		"name": "飞天鼠", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 6.84, 
		"defense": 3.06, 
		"agility": 8.1, 
		"hp": 42.0, 
		"growth": 4.2, 
		"hp_growth": 3.3, 
		"ratio": [38, 17, 45]
	}, 
	"qingyishu": {
		"name": "青翼鼠", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.94, 
		"defense": 3.96, 
		"agility": 8.1, 
		"hp": 42.0, 
		"growth": 4.2, 
		"hp_growth": 3.3, 
		"ratio": [33, 22, 45]
	}, 
	"fuyishu": {
		"name": "蝠翼鼠", 
		"type": "敏攻型", 
		"element": "金", 
		"attack": 5.94, 
		"defense": 3.06, 
		"agility": 9.0, 
		"hp": 42.0, 
		"growth": 4.2, 
		"hp_growth": 3.3, 
		"ratio": [33, 17, 50]
	}, 
	"chilong": {
		"name": "赤龙", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 11.4, 
		"defense": 13.5, 
		"agility": 5.1, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [38, 45, 17]
	}, 
	"jinxielong": {
		"name": "金蝎龙", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 9.9, 
		"defense": 15.0, 
		"agility": 5.1, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [33, 50, 17]
	}, 
	"lanmiaolong": {
		"name": "蓝鸟龙", 
		"type": "防攻型", 
		"element": "金", 
		"attack": 9.9, 
		"defense": 13.5, 
		"agility": 6.6, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [33, 45, 22]
	}, 
	"kubixiang": {
		"name": "酷毙象", 
		"type": "防血型", 
		"element": "木", 
		"attack": 5.6, 
		"defense": 8.0, 
		"agility": 2.4, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [35, 50, 15]
	}, 
	"shuaidaixiang": {
		"name": "衰呆象", 
		"type": "防血型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 8.8, 
		"agility": 2.4, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [30, 55, 15]
	}, 
	"minixiang": {
		"name": "迷你象", 
		"type": "防血型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 8.0, 
		"agility": 3.2, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [30, 50, 20]
	}, 
	"hongfenxiang": {
		"name": "红粉象", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 6.1, 
		"defense": 7.2, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 45, 17]
	}, 
	"aoririquan": {
		"name": "嗷日犬", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 8.3, 
		"defense": 5.5, 
		"agility": 11.3, 
		"hp": 56, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [33, 22, 45]
	}, 
	"zhuiyingquan": {
		"name": "追影犬", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 9.5, 
		"defense": 4.3, 
		"agility": 11.3, 
		"hp": 56, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [38, 17, 45]
	}, 
	"niefengquan": {
		"name": "啮风犬", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 8.3, 
		"defense": 4.3, 
		"agility": 12.5, 
		"hp": 56, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [33, 17, 50]
	}, 
	"duoluotianlang": {
		"name": "堕落天狼", 
		"type": "攻击型", 
		"element": "火", 
		"attack": 13.8, 
		"defense": 5.5, 
		"agility": 5.8, 
		"hp": 50.0, 
		"growth": 4.7, 
		"hp_growth": 2.9, 
		"ratio": [55, 22, 23]
	}, 
	"qibiantianlang": {
		"name": "奇变天狼", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 9.5, 
		"defense": 4.3, 
		"agility": 11.3, 
		"hp": 56, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [38, 17, 45]
	}, 
	"huanbiantianlang": {
		"name": "幻变天狼", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 8.3, 
		"defense": 4.3, 
		"agility": 12.5, 
		"hp": 56, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [33, 17, 50]
	}, 
	"ouou": {
		"name": "欧欧", 
		"type": "平均型", 
		"element": "水", 
		"attack": 5.4, 
		"defense": 4.8, 
		"agility": 5.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"yingying": {
		"name": "盈盈", 
		"type": "平均型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.9, 
		"agility": 4.3, 
		"hp": 25, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 35, 31]
	}, 
	"linlin": {
		"name": "琳琳", 
		"type": "平均型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.9, 
		"agility": 4.3, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 35, 31]
	}, 
	"zhenzhen": {
		"name": "珍珍", 
		"type": "平均型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 4.2, 
		"agility": 5.0, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [34, 30, 36]
	}, 
	"dàzǔiè": {
		"name": "大嘴鳄", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 6.1, 
		"defense": 7.2, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 45, 17]
	}, 
	"hòupíè": {
		"name": "厚皮鳄", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.3, 
		"defense": 8.0, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 50, 17]
	}, 
	"yìnggǔè": {
		"name": "硬骨鳄", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.3, 
		"defense": 7.2, 
		"agility": 3.5, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 45, 22]
	}, 
	"qíshìgūi": {
		"name": "骑士龟", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 6.1, 
		"defense": 7.2, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [38, 45, 17]
	}, 
	"tiějiǎgūi": {
		"name": "铁甲龟", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.3, 
		"defense": 8.0, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 50, 17]
	}, 
	"kǔxínggūi": {
		"name": "苦行龟", 
		"type": "防攻型", 
		"element": "水", 
		"attack": 5.3, 
		"defense": 7.2, 
		"agility": 3.5, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.5, 
		"ratio": [33, 45, 22]
	}, 
	"wūlītóu": {
		"name": "乌哩头", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.8, 
		"defense": 6.4, 
		"agility": 4.8, 
		"hp": 29.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [30, 40, 30]
	}, 
	"yáoyé": {
		"name": "摇爷", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 7.2, 
		"agility": 4.8, 
		"hp": 29.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [25, 45, 30]
	}, 
	"lèngtóuqīng": {
		"name": "愣头青", 
		"type": "敏防型", 
		"element": "水", 
		"attack": 4.0, 
		"defense": 6.4, 
		"agility": 5.6, 
		"hp": 29.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [25, 40, 35]
	}, 
	"bǔbǔ": {
		"name": "卜卜", 
		"type": "平均型", 
		"element": "水", 
		"attack": 6.2, 
		"defense": 4.8, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"jiájiá": {
		"name": "戛戛", 
		"type": "平均型", 
		"element": "水", 
		"attack": 5.4, 
		"defense": 5.6, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"hóngdāo": {
		"name": "红刀", 
		"type": "攻防型", 
		"element": "水", 
		"attack": 8.0, 
		"defense": 5.3, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"lv̀jiǎ": {
		"name": "绿甲", 
		"type": "攻防型", 
		"element": "水", 
		"attack": 7.2, 
		"defense": 6.1, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"lányá": {
		"name": "蓝牙", 
		"type": "攻防型", 
		"element": "水", 
		"attack": 7.2, 
		"defense": 5.3, 
		"agility": 3.5, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"kǒudàiyā": {
		"name": "口袋鸭", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 8.0, 
		"defense": 2.7, 
		"agility": 5.3, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"báimáoxiàng": {
		"name": "白毛象", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 5.3, 
		"defense": 8.0, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 50, 17]
	}, 
	"lǎnlǎnxiàng": {
		"name": "懒懒象", 
		"type": "防攻型", 
		"element": "木", 
		"attack": 5.3, 
		"defense": 7.2, 
		"agility": 3.5, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [33, 45, 22]
	}, 
	"qiāoqiāoshǔ": {
		"name": "跷跷鼠", 
		"type": "敏防型", 
		"element": "木", 
		"attack": 4.8, 
		"defense": 4.8, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [30, 30, 40]
	}, 
	"dànhuángshǔ": {
		"name": "弹簧鼠", 
		"type": "敏防型", 
		"element": "木", 
		"attack": 4.0, 
		"defense": 5.6, 
		"agility": 6.4, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 35, 40]
	}, 
	"xiàngpíshǔ": {
		"name": "橡皮鼠", 
		"type": "敏防型", 
		"element": "木", 
		"attack": 4.0, 
		"defense": 4.8, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [25, 30, 45]
	}, 
	"jiéquándào": {
		"name": "截拳道", 
		"type": "平均型", 
		"element": "木", 
		"attack": 10.5, 
		"defense": 9.3, 
		"agility": 11.2, 
		"hp": 62.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"kōngshǒudào": {
		"name": "空手道", 
		"type": "平均型", 
		"element": "木", 
		"attack": 10.5, 
		"defense": 10.9, 
		"agility": 9.6, 
		"hp": 62.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"táiquándào": {
		"name": "跆拳道", 
		"type": "平均型", 
		"element": "木", 
		"attack": 10.5, 
		"defense": 9.3, 
		"agility": 11.2, 
		"hp": 62.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"zǐtíxiānshēng": {
		"name": "紫蹄先生", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 8.0, 
		"defense": 5.3, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 33, 17]
	}, 
	"lántíxiānshēng": {
		"name": "蓝蹄先生", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 6.1, 
		"agility": 2.7, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 38, 17]
	}, 
	"hēitíxiānshēng": {
		"name": "黑蹄先生", 
		"type": "攻防型", 
		"element": "木", 
		"attack": 7.2, 
		"defense": 5.3, 
		"agility": 3.5, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 33, 22]
	}, 
	"lèlèxióng": {
		"name": "乐乐熊", 
		"type": "敏防型", 
		"element": "火", 
		"attack": 6.1, 
		"defense": 2.7, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"huānhuānxióng": {
		"name": "欢欢熊", 
		"type": "敏攻型", 
		"element": "火", 
		"attack": 5.3, 
		"defense": 3.5, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"mìmìxióng": {
		"name": "蜜蜜熊", 
		"type": "敏防型", 
		"element": "火", 
		"attack": 5.3, 
		"defense": 2.7, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"míhuò": {
		"name": "迷惑", 
		"type": "平均型", 
		"element": "火", 
		"attack": 6.2, 
		"defense": 4.8, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.5, 
		"ratio": [35, 15, 50]
	}, 
	"mímáng": {
		"name": "迷茫", 
		"type": "平均型", 
		"element": "火", 
		"attack": 5.4, 
		"defense": 5.6, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.5, 
		"ratio": [30, 20, 50]
	}, 
	"xiǎoyāo": {
		"name": "小妖", 
		"type": "平均型", 
		"element": "火", 
		"attack": 5.4, 
		"defense": 4.8, 
		"agility": 5.8, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.5, 
		"ratio": [34, 30, 36]
	}, 
	"jīnmáoshīwáng": {
		"name": "金毛狮王", 
		"type": "攻敏型", 
		"element": "火", 
		"attack": 10.0, 
		"defense": 3.4, 
		"agility": 6.6, 
		"hp": 40.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"dàdāo": {
		"name": "大刀", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 2.7, 
		"agility": 5.3, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"zhōngdāo": {
		"name": "中刀", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 3.5, 
		"agility": 5.3, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 22, 33]
	}, 
	"dàidāo": {
		"name": "黛刀", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 7.2, 
		"defense": 2.7, 
		"agility": 6.1, 
		"hp": 32.0, 
		"growth": 3.8, 
		"hp_growth": 2.9, 
		"ratio": [45, 17, 38]
	}, 
	"ātài": {
		"name": "阿泰", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.8, 
		"defense": 3.5, 
		"agility": 3.7, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [55, 22, 23]
	}, 
	"ādá": {
		"name": "阿达", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 4.3, 
		"agility": 3.7, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [50, 27, 23]
	}, 
	"ādǒu": {
		"name": "阿斗", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.0, 
		"defense": 3.5, 
		"agility": 4.5, 
		"hp": 38.0, 
		"growth": 3.6, 
		"hp_growth": 3.3, 
		"ratio": [50, 22, 28]
	}, 
	"hóngxīngtù": {
		"name": "洪兴兔", 
		"type": "敏防型", 
		"element": "土", 
		"attack": 6.1, 
		"defense": 2.7, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"cǎomǎngtù": {
		"name": "草莽兔", 
		"type": "敏攻型", 
		"element": "土", 
		"attack": 5.3, 
		"defense": 3.5, 
		"agility": 7.2, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"yùlíntù": {
		"name": "御林兔", 
		"type": "敏防型", 
		"element": "土", 
		"attack": 5.3, 
		"defense": 2.7, 
		"agility": 8.0, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"xiǎodīngdāng": {
		"name": "小丁当", 
		"type": "平均型", 
		"element": "土", 
		"attack": 6.2, 
		"defense": 4.8, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"xiǎolìngdāng": {
		"name": "小令当", 
		"type": "平均型", 
		"element": "土", 
		"attack": 5.4, 
		"defense": 5.6, 
		"agility": 5.0, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [34, 35, 31]
	}, 
	"xiǎodīngdōng": {
		"name": "小叮咚", 
		"type": "平均型", 
		"element": "土", 
		"attack": 5.4, 
		"defense": 4.8, 
		"agility": 5.8, 
		"hp": 32.0, 
		"growth": 4.0, 
		"hp_growth": 2.9, 
		"ratio": [34, 30, 36]
	}, 
	"hóngjǐnbǎo": {
		"name": "红锦宝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 6.1, 
		"defense": 7.2, 
		"agility": 2.7, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [38, 45, 17]
	}, 
	"lv̀jǐnbǎo": {
		"name": "绿锦宝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.3, 
		"defense": 8.0, 
		"agility": 2.7, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 50, 17]
	}, 
	"huángjǐnbǎo": {
		"name": "黄锦宝", 
		"type": "防攻型", 
		"element": "土", 
		"attack": 5.3, 
		"defense": 7.2, 
		"agility": 3.5, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [33, 45, 22]
	}, 
	"gōngbīngyǐ": {
		"name": "工兵蚁", 
		"type": "攻敏型", 
		"element": "土", 
		"attack": 8.8, 
		"defense": 3.5, 
		"agility": 3.7, 
		"hp": 38.0, 
		"growth": 3.8, 
		"hp_growth": 3.3, 
		"ratio": [50, 17, 33]
	}, 
	"lu_lu": {
		"name": "鲁鲁", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.9, 
		"defense": 2.1, 
		"agility": 7.0, 
		"hp": 19.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [35, 15, 50]
	}, 
	"tao_tao": {
		"name": "淘淘", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.2, 
		"defense": 2.8, 
		"agility": 7.0, 
		"hp": 19.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [30, 20, 50]
	}, 
	"meng_meng": {
		"name": "蒙蒙", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 4.2, 
		"defense": 2.1, 
		"agility": 7.7, 
		"hp": 19.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [30, 15, 55]
	}, 
	"gang_lei_fei": {
		"name": "刚雷狒", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 5.9, 
		"defense": 3.1, 
		"agility": 9.0, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 17, 50]
	}, 
	"hou_lei_fei": {
		"name": "吼雷狒", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 5.9, 
		"defense": 4.0, 
		"agility": 8.1, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [33, 22, 45]
	}, 
	"ben_lei_fei": {
		"name": "奔雷狒", 
		"type": "敏捷型", 
		"element": "木", 
		"attack": 6.8, 
		"defense": 3.1, 
		"agility": 8.1, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [38, 17, 45]
	}, 
	"zhong_yue_shen_yuan": {
		"name": "中岳神猿", 
		"type": "攻敏型", 
		"element": "木", 
		"attack": 12.5, 
		"defense": 4.3, 
		"agility": 8.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 17, 33]
	}, 
	"xi_yue_shen_yuan": {
		"name": "西岳神猿", 
		"type": "攻敏型", 
		"element": "木", 
		"attack": 11.3, 
		"defense": 5.5, 
		"agility": 8.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 22, 33]
	}, 
	"dong_yue_shen_yuan": {
		"name": "东岳神猿", 
		"type": "攻敏型", 
		"element": "木", 
		"attack": 11.3, 
		"defense": 4.3, 
		"agility": 9.5, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 17, 38]
	}, 
	"zhi_zun_bao": {
		"name": "齐天宝", 
		"type": "平均型", 
		"element": "木", 
		"attack": 12.1, 
		"defense": 9.3, 
		"agility": 9.6, 
		"hp": 71.0, 
		"growth": 5.1, 
		"hp_growth": 3.5, 
		"ratio": [39, 30, 31]
	}, 
	"zhi_zun_cao": {
		"name": "至尊草", 
		"type": "平均型", 
		"element": "木", 
		"attack": 10.5, 
		"defense": 10.9, 
		"agility": 9.6, 
		"hp": 71.0, 
		"growth": 5.1, 
		"hp_growth": 3.5, 
		"ratio": [34, 35, 31]
	}, 
	"zhi_zun_lin": {
		"name": "至尊林", 
		"type": "平均型", 
		"element": "木", 
		"attack": 10.5, 
		"defense": 9.3, 
		"agility": 11.2, 
		"hp": 71.0, 
		"growth": 5.1, 
		"hp_growth": 3.5, 
		"ratio": [34, 30, 36]
	}, 
	"yu_yi": {
		"name": "羽衣", 
		"type": "平均型", 
		"element": "水", 
		"attack": 7.0, 
		"defense": 5.4, 
		"agility": 5.6, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [39, 30, 31]
	}, 
	"ni_chang": {
		"name": "霓裳", 
		"type": "平均型", 
		"element": "水", 
		"attack": 6.1, 
		"defense": 6.3, 
		"agility": 5.6, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [34, 35, 31]
	}, 
	"ling_shan": {
		"name": "灵衫", 
		"type": "平均型", 
		"element": "水", 
		"attack": 6.1, 
		"defense": 5.4, 
		"agility": 6.5, 
		"hp": 37.5, 
		"growth": 3.9, 
		"hp_growth": 3.0, 
		"ratio": [34, 30, 36]
	}, 
	"fen_yi_xian_zi": {
		"name": "粉衣仙子", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 8.8, 
		"defense": 3.8, 
		"agility": 12.5, 
		"hp": 50.0, 
		"growth": 4.7, 
		"hp_growth": 2.9, 
		"ratio": [35, 15, 50]
	}, 
	"lv_yi_xian_zi": {
		"name": "绿衣仙子", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 7.5, 
		"defense": 5.0, 
		"agility": 12.5, 
		"hp": 50.0, 
		"growth": 4.7, 
		"hp_growth": 2.9, 
		"ratio": [30, 20, 50]
	}, 
	"bai_yi_xian_zi": {
		"name": "白衣仙子", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 7.5, 
		"defense": 3.8, 
		"agility": 13.8, 
		"hp": 50.0, 
		"growth": 4.7, 
		"hp_growth": 2.9, 
		"ratio": [30, 15, 55]
	}, 
	"dan_dan_yu": {
		"name": "蛋蛋鱼", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 5.3, 
		"defense": 2.3, 
		"agility": 7.5, 
		"hp": 21.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [35, 15, 50]
	}, 
	"wan_zi_yu": {
		"name": "丸子鱼", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.5, 
		"defense": 3.0, 
		"agility": 7.5, 
		"hp": 21.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [30, 20, 50]
	}, 
	"ping_pang_yu": {
		"name": "乒乓鱼", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 4.5, 
		"defense": 2.3, 
		"agility": 8.3, 
		"hp": 21.0, 
		"growth": 3.7, 
		"hp_growth": 2.3, 
		"ratio": [30, 15, 55]
	}, 
	"yu_wa_wa": {
		"name": "鱼娃娃", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 6.8, 
		"defense": 3.1, 
		"agility": 8.1, 
		"hp": 36.0, 
		"growth": 3.9, 
		"hp_growth": 2.9, 
		"ratio": [38, 17, 45]
	}, 
	"yu_niu_niu": {
		"name": "鱼妞妞", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 5.9, 
		"defense": 4.0, 
		"agility": 8.1, 
		"hp": 36.0, 
		"growth": 3.9, 
		"hp_growth": 2.9, 
		"ratio": [33, 22, 45]
	}, 
	"yu_mei_mei": {
		"name": "鱼妹妹", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 5.9, 
		"defense": 3.1, 
		"agility": 9.0, 
		"hp": 36.0, 
		"growth": 3.9, 
		"hp_growth": 2.9, 
		"ratio": [33, 17, 50]
	}, 
	"ling_bo_xian_zi": {
		"name": "凌波仙子", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 12.5, 
		"defense": 4.3, 
		"agility": 8.3, 
		"hp": 50.0, 
		"growth": 4.5, 
		"hp_growth": 2.9, 
		"ratio": [50, 17, 33]
	}, 
	"xi_shui_xian_zi": {
		"name": "戏水仙子", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 11.3, 
		"defense": 5.5, 
		"agility": 8.3, 
		"hp": 50.0, 
		"growth": 4.5, 
		"hp_growth": 2.9, 
		"ratio": [45, 22, 33]
	}, 
	"zhu_lang_xian_zi": {
		"name": "逐浪仙子", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 11.3, 
		"defense": 4.3, 
		"agility": 9.5, 
		"hp": 50.0, 
		"growth": 4.5, 
		"hp_growth": 2.9, 
		"ratio": [45, 17, 38]
	}, 
	"huan_yun_shou": {
		"name": "幻云兽", 
		"type": "敏攻型", 
		"element": "水", 
		"attack": 11.4, 
		"defense": 5.1, 
		"agility": 13.5, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [38, 17, 45]
	}, 
	"di_cang_shou": {
		"name": "地藏兽", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 9.9, 
		"defense": 6.6, 
		"agility": 13.5, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [33, 22, 45]
	}, 
	"ao_xue_shou": {
		"name": "敖雪兽", 
		"type": "敏捷型", 
		"element": "水", 
		"attack": 9.9, 
		"defense": 5.1, 
		"agility": 15.0, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [33, 17, 50]
	}, 
	"cong_cong": {
		"name": "匆匆", 
		"type": "防敏型", 
		"element": "火", 
		"attack": 4.2, 
		"defense": 5.6, 
		"agility": 4.2, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [30, 40, 30]
	}, 
	"xi_pi": {
		"name": "西皮", 
		"type": "防敏型", 
		"element": "火", 
		"attack": 3.5, 
		"defense": 6.3, 
		"agility": 4.2, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [25, 45, 30]
	}, 
	"wang_wang": {
		"name": "旺旺", 
		"type": "防敏型", 
		"element": "火", 
		"attack": 3.5, 
		"defense": 5.6, 
		"agility": 4.9, 
		"hp": 25.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [25, 40, 35]
	}, 
	"a_di_da_si": {
		"name": "冥狼崽", 
		"type": "防敏型", 
		"element": "火", 
		"attack": 4.8, 
		"defense": 6.4, 
		"agility": 4.8, 
		"hp": 29.0, 
		"growth": 3.5, 
		"hp_growth": 2.7, 
		"ratio": [30, 40, 30]
	}, 
	"a_ge_liu_si": {
		"name": "阿格留斯", 
		"type": "平均型", 
		"element": "火", 
		"attack": 7.0, 
		"defense": 5.4, 
		"agility": 5.6, 
		"hp": 36.0, 
		"growth": 3.9, 
		"hp_growth": 2.9, 
		"ratio": [39, 30, 31]
	}, 
	"a_nu_bi_si": {
		"name": "阿努比斯", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 12.5, 
		"defense": 8.3, 
		"agility": 4.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 33, 17]
	}, 
	"huo_yao_jing": {
		"name": "火妖精", 
		"type": "攻击型", 
		"element": "火", 
		"attack": 16.5, 
		"defense": 6.6, 
		"agility": 6.9, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [55, 22, 23]
	}, 
	"lv_yao": {
		"name": "绿妖", 
		"type": "攻击型", 
		"element": "火", 
		"attack": 15.0, 
		"defense": 8.1, 
		"agility": 6.9, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [50, 27, 23]
	}, 
	"zi_yi": {
		"name": "紫衣", 
		"type": "攻击型", 
		"element": "火", 
		"attack": 15.0, 
		"defense": 6.6, 
		"agility": 8.4, 
		"hp": 69.0, 
		"growth": 5.0, 
		"hp_growth": 3.5, 
		"ratio": [50, 22, 28]
	}, 
	"fu_di_long": {
		"name": "伏地龙", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 7.7, 
		"defense": 3.1, 
		"agility": 3.2, 
		"hp": 31.0, 
		"growth": 3.3, 
		"hp_growth": 3.1, 
		"ratio": [55, 22, 23]
	}, 
	"wen_di_long": {
		"name": "纹地龙", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 7.0, 
		"defense": 3.8, 
		"agility": 3.2, 
		"hp": 31.0, 
		"growth": 3.3, 
		"hp_growth": 3.1, 
		"ratio": [50, 27, 23]
	}, 
	"shun_di_long": {
		"name": "瞬地龙", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 7.0, 
		"defense": 3.1, 
		"agility": 3.9, 
		"hp": 31.0, 
		"growth": 3.3, 
		"hp_growth": 3.1, 
		"ratio": [50, 22, 28]
	}, 
	"wu_qi_long": {
		"name": "乌漆龙", 
		"type": "攻击型", 
		"element": "土", 
		"attack": 9.9, 
		"defense": 4.0, 
		"agility": 4.1, 
		"hp": 31.5, 
		"growth": 4.1, 
		"hp_growth": 2.6, 
		"ratio": [55, 22, 23]
	}, 
	"bao_lan_long": {
		"name": "暴蓝龙", 
		"type": "攻击型", 
		"element": "土", 
		"attack": 9.0, 
		"defense": 4.0, 
		"agility": 5.0, 
		"hp": 31.5, 
		"growth": 4.1, 
		"hp_growth": 2.6, 
		"ratio": [50, 22, 28]
	}, 
	"hei_long_shi": {
		"name": "黑龙使", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 13.8, 
		"defense": 5.5, 
		"agility": 5.8, 
		"hp": 62.0, 
		"growth": 4.3, 
		"hp_growth": 3.7, 
		"ratio": [55, 22, 23]
	}, 
	"huang_jin_long": {
		"name": "黄金龙", 
		"type": "攻击型", 
		"element": "土", 
		"attack": 9.0, 
		"defense": 4.9, 
		"agility": 4.1, 
		"hp": 31.5, 
		"growth": 4.1, 
		"hp_growth": 2.6, 
		"ratio": [50, 27, 23]
	}, 
	"huang_long_shi": {
		"name": "黄龙使", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 12.5, 
		"defense": 6.8, 
		"agility": 5.8, 
		"hp": 62.0, 
		"growth": 4.3, 
		"hp_growth": 3.7, 
		"ratio": [50, 27, 23]
	}, 
	"qing_long_shi": {
		"name": "青龙使", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 12.5, 
		"defense": 5.5, 
		"agility": 7.0, 
		"hp": 62.0, 
		"growth": 4.3, 
		"hp_growth": 3.7, 
		"ratio": [50, 22, 28]
	}, 
	"huo_lin_yi": {
		"name": "火鳞蜴", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 12.5, 
		"defense": 8.3, 
		"agility": 4.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 33, 17]
	}, 
	"chi_ji_yi": {
		"name": "赤脊蜴", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 11.3, 
		"defense": 9.5, 
		"agility": 4.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 38, 17]
	}, 
	"jin_jia_yi": {
		"name": "金甲蜴", 
		"type": "攻防型", 
		"element": "土", 
		"attack": 11.3, 
		"defense": 8.3, 
		"agility": 5.5, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [45, 33, 22]
	}, 
	"bai_fa_she_ji": {
		"name": "白发蛇姬", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 16.5, 
		"defense": 6.6, 
		"agility": 6.9, 
		"hp": 75.0, 
		"growth": 4.9, 
		"hp_growth": 3.9, 
		"ratio": [55, 22, 23]
	}, 
	"hong_fa_yao_ji": {
		"name": "红发妖姬", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 15.0, 
		"defense": 8.1, 
		"agility": 6.9, 
		"hp": 75.0, 
		"growth": 4.9, 
		"hp_growth": 3.9, 
		"ratio": [50, 27, 23]
	}, 
	"lan_fa_mo_ji": {
		"name": "蓝发魔姬", 
		"type": "攻血型", 
		"element": "土", 
		"attack": 15.0, 
		"defense": 6.6, 
		"agility": 8.4, 
		"hp": 75.0, 
		"growth": 4.9, 
		"hp_growth": 3.9, 
		"ratio": [50, 22, 28]
	}, 
	"cang_ming_shen_nv": {
		"name": "沧溟神女", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 15.0, 
		"defense": 5.2, 
		"agility": 9.0, 
		"hp": 62.0, 
		"growth": 4.8, 
		"hp_growth": 3.2, 
		"ratio": [52, 18, 30]
	}, 
	"yao_shui_ling_zun": {
		"name": "瑶水灵尊", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 14.0, 
		"defense": 6.5, 
		"agility": 8.5, 
		"hp": 65.0, 
		"growth": 4.8, 
		"hp_growth": 3.3, 
		"ratio": [48, 22, 30]
	}, 
	"han_hai_xian_ji": {
		"name": "瀚海仙姬", 
		"type": "攻敏型", 
		"element": "水", 
		"attack": 14.5, 
		"defense": 4.8, 
		"agility": 9.8, 
		"hp": 60.0, 
		"growth": 4.8, 
		"hp_growth": 3.1, 
		"ratio": [50, 16, 34]
	}, 
	"chao_ji_a_nu": {
		"name": "超级阿努", 
		"type": "攻防型", 
		"element": "火", 
		"attack": 12.5, 
		"defense": 8.3, 
		"agility": 4.3, 
		"hp": 56.0, 
		"growth": 4.5, 
		"hp_growth": 3.3, 
		"ratio": [50, 33, 17]
	}, 
	"mengjinger": {
		"name": "梦晶儿", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 9.0, 
		"defense": 4.0, 
		"agility": 4.0, 
		"hp": 48.0, 
		"growth": 3.4, 
		"hp_growth": 3.1, 
		"ratio": [52, 24, 24]
	}, 
	"mengtianshi": {
		"name": "梦天使", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 8.0, 
		"defense": 4.0, 
		"agility": 3.0, 
		"hp": 31.0, 
		"growth": 3.3, 
		"hp_growth": 3.4, 
		"ratio": [53, 26, 21]
	}, 
	"mengjinggang": {
		"name": "梦晶刚", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 12.0, 
		"defense": 6.0, 
		"agility": 5.0, 
		"hp": 62.0, 
		"growth": 3.9, 
		"hp_growth": 4.0, 
		"ratio": [50, 26, 24]
	}, 
	"liuyitianshi": {
		"name": "六翼天使", 
		"type": "攻击型", 
		"element": "金", 
		"attack": 15.0, 
		"defense": 7.0, 
		"agility": 5.0, 
		"hp": 75.0, 
		"growth": 4.8, 
		"hp_growth": 4.3, 
		"ratio": [45, 40, 15]
	}
}


const MARTIAL_ARTS_POOL = {
	"凡人": [
		{"name": "基础吐纳术", "effect_type": "all_stats", "base_value": 2, "desc": "调息匀笔，全属性小幅提升"}, 
		{"name": "强身健体", "effect_type": "hp", "base_value": 5, "desc": "层层积染，生命上限提升"}, 
		{"name": "铁布衫", "effect_type": "defense", "base_value": 3, "desc": "罩一层色护住纸骨，防御提升"}, 
		{"name": "疾风步", "effect_type": "agility", "base_value": 3, "desc": "笔掠留白，身法轻捷"}, 
		{"name": "蛮牛劲", "effect_type": "attack", "base_value": 3, "desc": "重按顿笔，出手沉猛"}, 
		{"name": "蓄灵诀", "effect_type": "mp_max", "base_value": 3, "desc": "含毫蓄墨，内力上限提升"}, 
		{"name": "养生诀", "effect_type": "exp", "base_value": 2, "desc": "日日养砚，阅历渐长"}, 
	], 
	"散仙": [
		{"name": "仙鹤吐纳", "effect_type": "all_stats", "base_value": 4, "desc": "游丝细笔，全属性提升"}, 
		{"name": "金刚不坏", "effect_type": "defense", "base_value": 6, "desc": "重彩多层，防御大幅提升"}, 
		{"name": "凌波微步", "effect_type": "agility", "base_value": 6, "desc": "笔尖掠水，身法迅疾"}, 
		{"name": "降龙掌", "effect_type": "attack", "base_value": 6, "desc": "锋破防面，掌力大增"}, 
		{"name": "行气诀", "effect_type": "mp_max", "base_value": 6, "desc": "行云流水，内力上限大幅提升"}, 
		{"name": "长生诀", "effect_type": "hp", "base_value": 8, "desc": "宿墨醇厚，气血绵长"}, 
	], 
	"地仙": [
		{"name": "紫霞神功", "effect_type": "all_stats", "base_value": 6, "desc": "紫毫落纸，全属性提升"}, 
		{"name": "不动明王", "effect_type": "defense", "base_value": 10, "desc": "铁线绷紧，防御极大提升"}, 
		{"name": "踏雪无痕", "effect_type": "agility", "base_value": 10, "desc": "不着一笔，身法极大提升"}, 
		{"name": "乾坤大挪移", "effect_type": "attack", "base_value": 10, "desc": "泼墨横扫，攻击极大提升"}, 
		{"name": "归真诀", "effect_type": "mp_max", "base_value": 10, "desc": "锋藏画内，内力上限极大提升"}, 
		{"name": "九阳神功", "effect_type": "hp", "base_value": 12, "desc": "朱砂点护，生命极大提升"}, 
	], 
	"天仙": [
		{"name": "太玄经", "effect_type": "all_stats", "base_value": 9, "desc": "永字八法，全属性大幅提升"}, 
		{"name": "不灭金身", "effect_type": "defense", "base_value": 15, "desc": "金碧覆身，防御巨幅提升"}, 
		{"name": "缩地成寸", "effect_type": "agility", "base_value": 15, "desc": "一笔纵贯，敏捷巨幅提升"}, 
		{"name": "万剑归宗", "effect_type": "attack", "base_value": 15, "desc": "万毫并下，攻击巨幅提升"}, 
		{"name": "凝神诀", "effect_type": "mp_max", "base_value": 15, "desc": "毫端凝墨，内力上限巨幅提升"}, 
		{"name": "不死神功", "effect_type": "hp", "base_value": 18, "desc": "青绿长皴，生命巨幅提升"}, 
	], 
	"大罗金仙": [
		{"name": "混元一气", "effect_type": "all_stats", "base_value": 12, "desc": "一笔贯气，全属性巨幅提升"}, 
		{"name": "万劫不灭", "effect_type": "defense", "base_value": 20, "desc": "丹青不坏，防御极大提升"}, 
		{"name": "瞬息万里", "effect_type": "agility", "base_value": 20, "desc": "意到笔到，敏捷极大提升"}, 
		{"name": "开天辟地", "effect_type": "attack", "base_value": 20, "desc": "侧锋劈斫，攻击极大提升"}, 
		{"name": "玄罡诀", "effect_type": "mp_max", "base_value": 20, "desc": "玄墨成渊，内力上限极大提升"}, 
		{"name": "永恒生命", "effect_type": "hp", "base_value": 25, "desc": "绢本不朽，生命极大提升"}, 
	], 
	"幻灵天神": [
		{"name": "天地同寿", "effect_type": "all_stats", "base_value": 15, "desc": "墨与寿齐，全属性极大提升"}, 
		{"name": "绝对防御", "effect_type": "defense", "base_value": 25, "desc": "金刚为色，终极防御提升"}, 
		{"name": "超越时空", "effect_type": "agility", "base_value": 25, "desc": "行出画外，终极敏捷提升"}, 
		{"name": "毁灭之力", "effect_type": "attack", "base_value": 25, "desc": "焦墨起火，终极攻击提升"}, 
		{"name": "造化玄罡", "effect_type": "mp_max", "base_value": 25, "desc": "造化凝于锋端，终极内力提升"}, 
		{"name": "无限生命", "effect_type": "hp", "base_value": 25, "desc": "生宣不蛀，终极生命提升"}, 
		{"name": "葵花点穴", "effect_type": "acupoint_seal", "base_value": 25, "desc": "有内力时普攻打3目标各1点，点中清空内力"}, 
		{"name": "破军劲", "effect_type": "crit_rate", "base_value": 10, "desc": "出锋锐利，暴击率提升（1层10%，9层20%）"}, 
		{"name": "重创诀", "effect_type": "crit_damage", "base_value": 10, "desc": "枯笔重压，暴击伤害提升（1层+10%，9层+50%；默认暴击1.5倍）"}, 
	], 
}


const ITEM_RARITY = {
	"common": {"name": "普通", "color": Color(0.93, 0.94, 0.95)}, 
	"uncommon": {"name": "优秀", "color": Color(0.15, 0.68, 0.38)}, 
	"rare": {"name": "稀有", "color": Color(0.2, 0.6, 0.86)}, 
	"epic": {"name": "史诗", "color": Color(0.61, 0.35, 0.71)}, 
	"legendary": {"name": "传说", "color": Color(0.95, 0.61, 0.07)}
}


const SHOP_PRICES = {
	"小还丹": {"buy": 50, "sell": 20}, 
	"中还丹": {"buy": 150, "sell": 60}, 
	"大还丹": {"buy": 500, "sell": 200}, 
	"回血丹": {"buy": 80, "sell": 30}, 
	"疗伤丹": {"buy": 250, "sell": 100}, 
	"金刚药": {"buy": 800, "sell": 320}, 
	"聚气丹": {"buy": 100, "sell": 40}, 
	"仙露丹": {"buy": 600, "sell": 240}, 
	"神灵丹": {"buy": 2000, "sell": 800}, 
	"长生丹": {"buy": 5000, "sell": 2000}, 
	"造化丹": {"buy": 20000, "sell": 8000}, 
	"玄铁": {"buy": 30, "sell": 10}, 
	"精铁": {"buy": 50, "sell": 20}, 
	"金刚石": {"buy": 200, "sell": 80}, 
	"灵木": {"buy": 40, "sell": 15}, 
	"寒冰精": {"buy": 180, "sell": 70}, 
	"烈火石": {"buy": 180, "sell": 70}, 
	"天雷石": {"buy": 500, "sell": 200}, 
	"星辰砂": {"buy": 800, "sell": 320}, 
	"龙鳞": {"buy": 5000, "sell": 2000}, 
	"凤羽": {"buy": 5000, "sell": 2000}, 
	"混沌石": {"buy": 20000, "sell": 8000}, 
	"仙晶": {"buy": 30000, "sell": 12000}, 
	"灵草": {"buy": 20, "sell": 8}, 
	"灵芝": {"buy": 100, "sell": 40}, 
	"天山雪莲": {"buy": 400, "sell": 160}, 
	"九转还魂草": {"buy": 2000, "sell": 800}, 
	"龙涎草": {"buy": 10000, "sell": 4000}, 
	"聚灵丹": {"buy": 500, "sell": 200}, 
	"凝神丹": {"buy": 1500, "sell": 600}, 
	"悟道仙丹": {"buy": 5000, "sell": 2000}, 
}


const PET_SKILLS = {

	"splash_lv1": {
		"skill_id": "splash", 
		"name": "溅墨", 
		"level": 1, 
		"trigger_chance": 0.5, 
		"secondary_damage_ratio": 0.8
	}, 
	"splash_lv2": {
		"skill_id": "splash", 
		"name": "溅墨", 
		"level": 2, 
		"trigger_chance": 1.0, 
		"secondary_damage_ratio": 1.0
	}, 
	"splash_lv3": {
		"skill_id": "splash", 
		"name": "溅墨", 
		"level": 3, 
		"trigger_chance": 1.0, 
		"secondary_damage_ratio": 1.2
	}, 

	"double_shot_lv1": {
		"skill_id": "double_shot", 
		"name": "连击", 
		"level": 1, 
		"extra_attacks": 2
	}, 
	"double_shot_lv2": {
		"skill_id": "double_shot", 
		"name": "连击", 
		"level": 2, 
		"extra_attacks": 2
	}, 
	"double_shot_lv3": {
		"skill_id": "double_shot", 
		"name": "连击", 
		"level": 3, 
		"extra_attacks": 2
	}, 

	"divine_protect_lv1": {
		"skill_id": "divine_protect", 
		"name": "护主", 
		"level": 1, 
		"survival_hp_ratio": 0.5, 
		"max_use_per_battle": 5
	}, 
	"divine_protect_lv2": {
		"skill_id": "divine_protect", 
		"name": "护主", 
		"level": 2, 
		"survival_hp_ratio": 0.5, 
		"max_use_per_battle": 5
	}, 
	"divine_protect_lv3": {
		"skill_id": "divine_protect", 
		"name": "护主", 
		"level": 3, 
		"survival_hp_ratio": 1.0, 
		"max_use_per_battle": 5
	}, 

	"counter_attack_lv1": {
		"skill_id": "counter_attack", 
		"name": "反打", 
		"level": 1, 
		"counter_damage_ratio": 0.5, 
		"counter_chance": 0.2
	}, 
	"counter_attack_lv2": {
		"skill_id": "counter_attack", 
		"name": "反打", 
		"level": 2, 
		"counter_damage_ratio": 0.8, 
		"counter_chance": 0.3
	}, 
	"counter_attack_lv3": {
		"skill_id": "counter_attack", 
		"name": "反打", 
		"level": 3, 
		"counter_damage_ratio": 1.0, 
		"counter_chance": 0.5
	}, 

	"fortify_lv1": {
		"skill_id": "fortify", 
		"name": "硬皮", 
		"level": 1, 
		"defense_bonus_percent": 70
	}, 
	"fortify_lv2": {
		"skill_id": "fortify", 
		"name": "硬皮", 
		"level": 2, 
		"defense_bonus_percent": 140
	}, 
	"fortify_lv3": {
		"skill_id": "fortify", 
		"name": "硬皮", 
		"level": 3, 
		"defense_bonus_percent": 210
	}, 

	"life_steal_lv1": {
		"skill_id": "life_steal", 
		"name": "饮血", 
		"level": 1, 
		"trigger_chance": 0.1, 
		"lifesteal_ratio": 0.1
	}, 
	"life_steal_lv2": {
		"skill_id": "life_steal", 
		"name": "饮血", 
		"level": 2, 
		"trigger_chance": 0.2, 
		"lifesteal_ratio": 0.15
	}, 
	"life_steal_lv3": {
		"skill_id": "life_steal", 
		"name": "饮血", 
		"level": 3, 
		"trigger_chance": 0.3, 
		"lifesteal_ratio": 0.2
	}, 
	"splash_lv4": {"skill_id": "splash", "name": "溅墨", "level": 4}, 
	"splash_lv5": {"skill_id": "splash", "name": "溅墨", "level": 5}, 
	"double_shot_lv4": {"skill_id": "double_shot", "name": "连击", "level": 4}, 
	"double_shot_lv5": {"skill_id": "double_shot", "name": "连击", "level": 5}, 
	"divine_protect_lv4": {"skill_id": "divine_protect", "name": "护主", "level": 4}, 
	"divine_protect_lv5": {"skill_id": "divine_protect", "name": "护主", "level": 5}, 
	"counter_attack_lv4": {"skill_id": "counter_attack", "name": "反打", "level": 4}, 
	"counter_attack_lv5": {"skill_id": "counter_attack", "name": "反打", "level": 5}, 
	"fortify_lv4": {"skill_id": "fortify", "name": "硬皮", "level": 4, "defense_bonus_percent": 230}, 
	"fortify_lv5": {"skill_id": "fortify", "name": "硬皮", "level": 5, "defense_bonus_percent": 250}, 
	"life_steal_lv4": {"skill_id": "life_steal", "name": "饮血", "level": 4, "trigger_chance": 0.4, "lifesteal_ratio": 0.25}, 
	"life_steal_lv5": {"skill_id": "life_steal", "name": "饮血", "level": 5, "trigger_chance": 0.5, "lifesteal_ratio": 0.3}, 
	"swift_lv1": {"skill_id": "swift", "name": "轻身", "level": 1, "agility_bonus_percent": 5}, 
	"swift_lv2": {"skill_id": "swift", "name": "轻身", "level": 2, "agility_bonus_percent": 10}, 
	"swift_lv3": {"skill_id": "swift", "name": "轻身", "level": 3, "agility_bonus_percent": 15}, 
	"swift_lv4": {"skill_id": "swift", "name": "轻身", "level": 4, "agility_bonus_percent": 20}, 
	"swift_lv5": {"skill_id": "swift", "name": "轻身", "level": 5, "agility_bonus_percent": 25}, 
	"longevity_lv1": {"skill_id": "longevity", "name": "长命", "level": 1, "hp_bonus_percent": 5}, 
	"longevity_lv2": {"skill_id": "longevity", "name": "长命", "level": 2, "hp_bonus_percent": 10}, 
	"longevity_lv3": {"skill_id": "longevity", "name": "长命", "level": 3, "hp_bonus_percent": 15}, 
	"longevity_lv4": {"skill_id": "longevity", "name": "长命", "level": 4, "hp_bonus_percent": 20}, 
	"longevity_lv5": {"skill_id": "longevity", "name": "长命", "level": 5, "hp_bonus_percent": 25}, 
	"mighty_lv1": {"skill_id": "mighty", "name": "力壮", "level": 1, "attack_bonus_percent": 5}, 
	"mighty_lv2": {"skill_id": "mighty", "name": "力壮", "level": 2, "attack_bonus_percent": 10}, 
	"mighty_lv3": {"skill_id": "mighty", "name": "力壮", "level": 3, "attack_bonus_percent": 15}, 
	"mighty_lv4": {"skill_id": "mighty", "name": "力壮", "level": 4, "attack_bonus_percent": 20}, 
	"mighty_lv5": {"skill_id": "mighty", "name": "力壮", "level": 5, "attack_bonus_percent": 25}, 
	"fierce_lv1": {"skill_id": "fierce", "name": "凶性", "level": 1, "crit_damage_bonus_percent": 5}, 
	"fierce_lv2": {"skill_id": "fierce", "name": "凶性", "level": 2, "crit_damage_bonus_percent": 10}, 
	"fierce_lv3": {"skill_id": "fierce", "name": "凶性", "level": 3, "crit_damage_bonus_percent": 15}, 
	"fierce_lv4": {"skill_id": "fierce", "name": "凶性", "level": 4, "crit_damage_bonus_percent": 20}, 
	"fierce_lv5": {"skill_id": "fierce", "name": "凶性", "level": 5, "crit_damage_bonus_percent": 25}, 
	"fatal_lv1": {"skill_id": "fatal", "name": "致命", "level": 1, "crit_rate_bonus_percent": 5}, 
	"fatal_lv2": {"skill_id": "fatal", "name": "致命", "level": 2, "crit_rate_bonus_percent": 10}, 
	"fatal_lv3": {"skill_id": "fatal", "name": "致命", "level": 3, "crit_rate_bonus_percent": 15}, 
	"fatal_lv4": {"skill_id": "fatal", "name": "致命", "level": 4, "crit_rate_bonus_percent": 20}, 
	"fatal_lv5": {"skill_id": "fatal", "name": "致命", "level": 5, "crit_rate_bonus_percent": 25}, 
	"self_heal_lv1": {"skill_id": "self_heal", "name": "自复", "level": 1, "heal_ratio": 0.05}, 
	"self_heal_lv2": {"skill_id": "self_heal", "name": "自复", "level": 2, "heal_ratio": 0.1}, 
	"self_heal_lv3": {"skill_id": "self_heal", "name": "自复", "level": 3, "heal_ratio": 0.15}, 
	"self_heal_lv4": {"skill_id": "self_heal", "name": "自复", "level": 4, "heal_ratio": 0.2}, 
	"self_heal_lv5": {"skill_id": "self_heal", "name": "自复", "level": 5, "heal_ratio": 0.25}, 
	"chase_lv1": {"skill_id": "chase", "name": "追杀", "level": 1}, 
	"chase_lv2": {"skill_id": "chase", "name": "追杀", "level": 2}, 
	"chase_lv3": {"skill_id": "chase", "name": "追杀", "level": 3}, 
	"chase_lv4": {"skill_id": "chase", "name": "追杀", "level": 4}, 
	"chase_lv5": {"skill_id": "chase", "name": "追杀", "level": 5}, 
	"loyal_lv1": {"skill_id": "loyal", "name": "守主", "level": 1}, 
	"loyal_lv2": {"skill_id": "loyal", "name": "守主", "level": 2}, 
	"loyal_lv3": {"skill_id": "loyal", "name": "守主", "level": 3}, 
	"loyal_lv4": {"skill_id": "loyal", "name": "守主", "level": 4}, 
	"loyal_lv5": {"skill_id": "loyal", "name": "守主", "level": 5}, 
	"taunt_lv1": {"skill_id": "taunt", "name": "挑衅", "level": 1}, 
	"taunt_lv2": {"skill_id": "taunt", "name": "挑衅", "level": 2}, 
	"taunt_lv3": {"skill_id": "taunt", "name": "挑衅", "level": 3}, 
	"taunt_lv4": {"skill_id": "taunt", "name": "挑衅", "level": 4}, 
	"taunt_lv5": {"skill_id": "taunt", "name": "挑衅", "level": 5}, 
	"armor_pierce_lv1": {"skill_id": "armor_pierce", "name": "破防", "level": 1}, 
	"armor_pierce_lv2": {"skill_id": "armor_pierce", "name": "破防", "level": 2}, 
	"armor_pierce_lv3": {"skill_id": "armor_pierce", "name": "破防", "level": 3}, 
	"armor_pierce_lv4": {"skill_id": "armor_pierce", "name": "破防", "level": 4}, 
	"armor_pierce_lv5": {"skill_id": "armor_pierce", "name": "破防", "level": 5}, 
	"guard_lv1": {"skill_id": "guard", "name": "挡伤", "level": 1}, 
	"guard_lv2": {"skill_id": "guard", "name": "挡伤", "level": 2}, 
	"guard_lv3": {"skill_id": "guard", "name": "挡伤", "level": 3}, 
	"guard_lv4": {"skill_id": "guard", "name": "挡伤", "level": 4}, 
	"guard_lv5": {"skill_id": "guard", "name": "挡伤", "level": 5}, 
}

const MARTIAL_SKILL_BOOKS = {
	"一箭三雕": {
		"name": "一箭三雕", 
		"martial_name": "一箭三雕", 
		"effect_type": "triple_shot", 
		"base_value": 80.0, 
		"desc": "装备后普攻最多同时攻击3个目标；每箭伤害1层80%、9层120%", 
		"realm": "技能书", 
	}, 
	"以战养战": {
		"name": "以战养战", 
		"martial_name": "以战养战", 
		"effect_type": "life_steal", 
		"base_value": 5.0, 
		"desc": "装备后普攻有50%概率按伤害吸血回血（1层5%，9层20%）", 
		"realm": "技能书", 
	}, 
}

const PET_SKILL_BOOKS = {
	"溅墨lv1技能书": {
		"name": "溅墨lv1技能书", 
		"skill_key": "splash_lv1", 
		"slot": 1
	}, 
	"溅墨lv2技能书": {
		"name": "溅墨lv2技能书", 
		"skill_key": "splash_lv2", 
		"required_skill_key": "splash_lv1", 
		"slot": 1
	}, 
	"溅墨lv3技能书": {
		"name": "溅墨lv3技能书", 
		"skill_key": "splash_lv3", 
		"required_skill_key": "splash_lv2", 
		"slot": 1
	}, 
	"连击lv1技能书": {
		"name": "连击lv1技能书", 
		"skill_key": "double_shot_lv1", 
		"slot": 2
	}, 
	"连击lv2技能书": {
		"name": "连击lv2技能书", 
		"skill_key": "double_shot_lv2", 
		"required_skill_key": "double_shot_lv1", 
		"slot": 2
	}, 
	"连击lv3技能书": {
		"name": "连击lv3技能书", 
		"skill_key": "double_shot_lv3", 
		"required_skill_key": "double_shot_lv2", 
		"slot": 2
	}, 
	"护主lv1技能书": {
		"name": "护主lv1技能书", 
		"skill_key": "divine_protect_lv1", 
		"slot": 3
	}, 
	"护主lv2技能书": {
		"name": "护主lv2技能书", 
		"skill_key": "divine_protect_lv2", 
		"required_skill_key": "divine_protect_lv1", 
		"slot": 3
	}, 
	"护主lv3技能书": {
		"name": "护主lv3技能书", 
		"skill_key": "divine_protect_lv3", 
		"required_skill_key": "divine_protect_lv2", 
		"slot": 3
	}, 
	"反打lv1技能书": {
		"name": "反打lv1技能书", 
		"skill_key": "counter_attack_lv1", 
		"slot": 3
	}, 
	"反打lv2技能书": {
		"name": "反打lv2技能书", 
		"skill_key": "counter_attack_lv2", 
		"required_skill_key": "counter_attack_lv1", 
		"slot": 3
	}, 
	"反打lv3技能书": {
		"name": "反打lv3技能书", 
		"skill_key": "counter_attack_lv3", 
		"required_skill_key": "counter_attack_lv2", 
		"slot": 3
	}, 

	"硬皮lv1技能书": {
		"name": "硬皮lv1技能书", 
		"skill_key": "fortify_lv1", 
		"slot": 3
	}, 
	"硬皮lv2技能书": {
		"name": "硬皮lv2技能书", 
		"skill_key": "fortify_lv2", 
		"required_skill_key": "fortify_lv1", 
		"slot": 3
	}, 
	"硬皮lv3技能书": {
		"name": "硬皮lv3技能书", 
		"skill_key": "fortify_lv3", 
		"required_skill_key": "fortify_lv2", 
		"slot": 3
	}, 

	"饮血lv1技能书": {
		"name": "饮血lv1技能书", 
		"skill_key": "life_steal_lv1", 
		"slot": 3
	}, 
	"饮血lv2技能书": {
		"name": "饮血lv2技能书", 
		"skill_key": "life_steal_lv2", 
		"required_skill_key": "life_steal_lv1", 
		"slot": 3
	}, 
	"饮血lv3技能书": {
		"name": "饮血lv3技能书", 
		"skill_key": "life_steal_lv3", 
		"required_skill_key": "life_steal_lv2", 
		"slot": 3
	}, 
	"溅墨lv4技能书": {"name": "溅墨lv4技能书", "skill_key": "splash_lv4", "required_skill_key": "splash_lv3", "slot": 1}, 
	"溅墨lv5技能书": {"name": "溅墨lv5技能书", "skill_key": "splash_lv5", "required_skill_key": "splash_lv4", "slot": 1}, 
	"连击lv4技能书": {"name": "连击lv4技能书", "skill_key": "double_shot_lv4", "required_skill_key": "double_shot_lv3", "slot": 2}, 
	"连击lv5技能书": {"name": "连击lv5技能书", "skill_key": "double_shot_lv5", "required_skill_key": "double_shot_lv4", "slot": 2}, 
	"护主lv4技能书": {"name": "护主lv4技能书", "skill_key": "divine_protect_lv4", "required_skill_key": "divine_protect_lv3", "slot": 3}, 
	"护主lv5技能书": {"name": "护主lv5技能书", "skill_key": "divine_protect_lv5", "required_skill_key": "divine_protect_lv4", "slot": 3}, 
	"反打lv4技能书": {"name": "反打lv4技能书", "skill_key": "counter_attack_lv4", "required_skill_key": "counter_attack_lv3", "slot": 3}, 
	"反打lv5技能书": {"name": "反打lv5技能书", "skill_key": "counter_attack_lv5", "required_skill_key": "counter_attack_lv4", "slot": 3}, 
	"硬皮lv4技能书": {"name": "硬皮lv4技能书", "skill_key": "fortify_lv4", "required_skill_key": "fortify_lv3", "slot": 3}, 
	"硬皮lv5技能书": {"name": "硬皮lv5技能书", "skill_key": "fortify_lv5", "required_skill_key": "fortify_lv4", "slot": 3}, 
	"饮血lv4技能书": {"name": "饮血lv4技能书", "skill_key": "life_steal_lv4", "required_skill_key": "life_steal_lv3", "slot": 3}, 
	"饮血lv5技能书": {"name": "饮血lv5技能书", "skill_key": "life_steal_lv5", "required_skill_key": "life_steal_lv4", "slot": 3}, 
	"轻身lv1技能书": {"name": "轻身lv1技能书", "skill_key": "swift_lv1", "slot": 3}, 
	"轻身lv2技能书": {"name": "轻身lv2技能书", "skill_key": "swift_lv2", "required_skill_key": "swift_lv1", "slot": 3}, 
	"轻身lv3技能书": {"name": "轻身lv3技能书", "skill_key": "swift_lv3", "required_skill_key": "swift_lv2", "slot": 3}, 
	"轻身lv4技能书": {"name": "轻身lv4技能书", "skill_key": "swift_lv4", "required_skill_key": "swift_lv3", "slot": 3}, 
	"轻身lv5技能书": {"name": "轻身lv5技能书", "skill_key": "swift_lv5", "required_skill_key": "swift_lv4", "slot": 3}, 
	"长命lv1技能书": {"name": "长命lv1技能书", "skill_key": "longevity_lv1", "slot": 3}, 
	"长命lv2技能书": {"name": "长命lv2技能书", "skill_key": "longevity_lv2", "required_skill_key": "longevity_lv1", "slot": 3}, 
	"长命lv3技能书": {"name": "长命lv3技能书", "skill_key": "longevity_lv3", "required_skill_key": "longevity_lv2", "slot": 3}, 
	"长命lv4技能书": {"name": "长命lv4技能书", "skill_key": "longevity_lv4", "required_skill_key": "longevity_lv3", "slot": 3}, 
	"长命lv5技能书": {"name": "长命lv5技能书", "skill_key": "longevity_lv5", "required_skill_key": "longevity_lv4", "slot": 3}, 
	"力壮lv1技能书": {"name": "力壮lv1技能书", "skill_key": "mighty_lv1", "slot": 3}, 
	"力壮lv2技能书": {"name": "力壮lv2技能书", "skill_key": "mighty_lv2", "required_skill_key": "mighty_lv1", "slot": 3}, 
	"力壮lv3技能书": {"name": "力壮lv3技能书", "skill_key": "mighty_lv3", "required_skill_key": "mighty_lv2", "slot": 3}, 
	"力壮lv4技能书": {"name": "力壮lv4技能书", "skill_key": "mighty_lv4", "required_skill_key": "mighty_lv3", "slot": 3}, 
	"力壮lv5技能书": {"name": "力壮lv5技能书", "skill_key": "mighty_lv5", "required_skill_key": "mighty_lv4", "slot": 3}, 
	"凶性lv1技能书": {"name": "凶性lv1技能书", "skill_key": "fierce_lv1", "slot": 3}, 
	"凶性lv2技能书": {"name": "凶性lv2技能书", "skill_key": "fierce_lv2", "required_skill_key": "fierce_lv1", "slot": 3}, 
	"凶性lv3技能书": {"name": "凶性lv3技能书", "skill_key": "fierce_lv3", "required_skill_key": "fierce_lv2", "slot": 3}, 
	"凶性lv4技能书": {"name": "凶性lv4技能书", "skill_key": "fierce_lv4", "required_skill_key": "fierce_lv3", "slot": 3}, 
	"凶性lv5技能书": {"name": "凶性lv5技能书", "skill_key": "fierce_lv5", "required_skill_key": "fierce_lv4", "slot": 3}, 
	"致命lv1技能书": {"name": "致命lv1技能书", "skill_key": "fatal_lv1", "slot": 3}, 
	"致命lv2技能书": {"name": "致命lv2技能书", "skill_key": "fatal_lv2", "required_skill_key": "fatal_lv1", "slot": 3}, 
	"致命lv3技能书": {"name": "致命lv3技能书", "skill_key": "fatal_lv3", "required_skill_key": "fatal_lv2", "slot": 3}, 
	"致命lv4技能书": {"name": "致命lv4技能书", "skill_key": "fatal_lv4", "required_skill_key": "fatal_lv3", "slot": 3}, 
	"致命lv5技能书": {"name": "致命lv5技能书", "skill_key": "fatal_lv5", "required_skill_key": "fatal_lv4", "slot": 3}, 
	"自复lv1技能书": {"name": "自复lv1技能书", "skill_key": "self_heal_lv1", "slot": 3}, 
	"自复lv2技能书": {"name": "自复lv2技能书", "skill_key": "self_heal_lv2", "required_skill_key": "self_heal_lv1", "slot": 3}, 
	"自复lv3技能书": {"name": "自复lv3技能书", "skill_key": "self_heal_lv3", "required_skill_key": "self_heal_lv2", "slot": 3}, 
	"自复lv4技能书": {"name": "自复lv4技能书", "skill_key": "self_heal_lv4", "required_skill_key": "self_heal_lv3", "slot": 3}, 
	"自复lv5技能书": {"name": "自复lv5技能书", "skill_key": "self_heal_lv5", "required_skill_key": "self_heal_lv4", "slot": 3}, 
	"追杀lv1技能书": {"name": "追杀lv1技能书", "skill_key": "chase_lv1", "slot": 3}, 
	"追杀lv2技能书": {"name": "追杀lv2技能书", "skill_key": "chase_lv2", "required_skill_key": "chase_lv1", "slot": 3}, 
	"追杀lv3技能书": {"name": "追杀lv3技能书", "skill_key": "chase_lv3", "required_skill_key": "chase_lv2", "slot": 3}, 
	"追杀lv4技能书": {"name": "追杀lv4技能书", "skill_key": "chase_lv4", "required_skill_key": "chase_lv3", "slot": 3}, 
	"追杀lv5技能书": {"name": "追杀lv5技能书", "skill_key": "chase_lv5", "required_skill_key": "chase_lv4", "slot": 3}, 
	"守主lv1技能书": {"name": "守主lv1技能书", "skill_key": "loyal_lv1", "slot": 3}, 
	"守主lv2技能书": {"name": "守主lv2技能书", "skill_key": "loyal_lv2", "required_skill_key": "loyal_lv1", "slot": 3}, 
	"守主lv3技能书": {"name": "守主lv3技能书", "skill_key": "loyal_lv3", "required_skill_key": "loyal_lv2", "slot": 3}, 
	"守主lv4技能书": {"name": "守主lv4技能书", "skill_key": "loyal_lv4", "required_skill_key": "loyal_lv3", "slot": 3}, 
	"守主lv5技能书": {"name": "守主lv5技能书", "skill_key": "loyal_lv5", "required_skill_key": "loyal_lv4", "slot": 3}, 
	"挑衅lv1技能书": {"name": "挑衅lv1技能书", "skill_key": "taunt_lv1", "slot": 3}, 
	"挑衅lv2技能书": {"name": "挑衅lv2技能书", "skill_key": "taunt_lv2", "required_skill_key": "taunt_lv1", "slot": 3}, 
	"挑衅lv3技能书": {"name": "挑衅lv3技能书", "skill_key": "taunt_lv3", "required_skill_key": "taunt_lv2", "slot": 3}, 
	"挑衅lv4技能书": {"name": "挑衅lv4技能书", "skill_key": "taunt_lv4", "required_skill_key": "taunt_lv3", "slot": 3}, 
	"挑衅lv5技能书": {"name": "挑衅lv5技能书", "skill_key": "taunt_lv5", "required_skill_key": "taunt_lv4", "slot": 3}, 
	"破防lv1技能书": {"name": "破防lv1技能书", "skill_key": "armor_pierce_lv1", "slot": 3}, 
	"破防lv2技能书": {"name": "破防lv2技能书", "skill_key": "armor_pierce_lv2", "required_skill_key": "armor_pierce_lv1", "slot": 3}, 
	"破防lv3技能书": {"name": "破防lv3技能书", "skill_key": "armor_pierce_lv3", "required_skill_key": "armor_pierce_lv2", "slot": 3}, 
	"破防lv4技能书": {"name": "破防lv4技能书", "skill_key": "armor_pierce_lv4", "required_skill_key": "armor_pierce_lv3", "slot": 3}, 
	"破防lv5技能书": {"name": "破防lv5技能书", "skill_key": "armor_pierce_lv5", "required_skill_key": "armor_pierce_lv4", "slot": 3}, 
	"挡伤lv1技能书": {"name": "挡伤lv1技能书", "skill_key": "guard_lv1", "slot": 3}, 
	"挡伤lv2技能书": {"name": "挡伤lv2技能书", "skill_key": "guard_lv2", "required_skill_key": "guard_lv1", "slot": 3}, 
	"挡伤lv3技能书": {"name": "挡伤lv3技能书", "skill_key": "guard_lv3", "required_skill_key": "guard_lv2", "slot": 3}, 
	"挡伤lv4技能书": {"name": "挡伤lv4技能书", "skill_key": "guard_lv4", "required_skill_key": "guard_lv3", "slot": 3}, 
	"挡伤lv5技能书": {"name": "挡伤lv5技能书", "skill_key": "guard_lv5", "required_skill_key": "guard_lv4", "slot": 3}, 
}


# ---------------------------------------------------------------- 宠物技能书命名归一
# 改名前后的技能名一直是几张表各说各话：道具键用新名（硬皮lv4技能书）、技能表还留着旧名、
# 老存档老邮件里甚至有罗马数字写法（坚固IV技能书）。玩家一用就报「未知宠物技能书」，
# 一合成就报「未知技能书」。这里是所有入口的唯一归一闸门，两步：
#   1) 查改名表 ITEM_NAME_MIGRATION（md5 键，包内不留旧名明文）—— 旧族名/宠物蛋新名走这条；
#   2) 按算法把等级写法折成 lvN（IV / 4 / LV4 / 四 都认）—— 新族名 + 罗马数字走这条。
const PET_SKILL_LEVEL_TOKENS := {
	"I": 1, "II": 2, "III": 3, "IIII": 4, "IV": 4, "V": 5, 
	"一": 1, "二": 2, "三": 3, "四": 4, "五": 5
}

# 旧族名（md5 前 8 位）→ 现用族名。族名改过两版，包内只留哈希，解包看不到历史名字。
# 有它以后「坚固 4 技能书」「坚固IV技能书」「固色lv2技能书」这些写法都能直接折成现用键。
const PET_SKILL_FAMILY_HASHES := {
	"061f8752": "反打", "07fb7bdd": "长命", "0b8021d8": "破防", "0f5bb79e": "破防",
	"18a10404": "挑衅", "1df88c7e": "溅墨", "34d310ea": "守主", "3886b60d": "致命",
	"39541a7a": "硬皮", "3afd84b1": "凶性", "3b4f949e": "挑衅", "475818e5": "饮血",
	"4a2e6733": "守主", "4f0599b4": "自复", "539cb8d5": "自复", "54aac617": "连击",
	"6276ce31": "轻身", "672b42dd": "硬皮", "6a910036": "追杀", "7734acaa": "凶性",
	"79b5ac25": "饮血", "7b9763ad": "凶性", "7c1f7e5c": "长命", "7c488084": "连击",
	"85ba598a": "溅墨", "91b12cb9": "长命", "93cfc827": "致命", "93f5b342": "破防",
	"9a7dcd6e": "连击", "9c941a4b": "护主", "9fb0d35f": "自复", "a02f9539": "护主",
	"a353adad": "力壮", "a4830cc9": "反打", "a7551e96": "致命", "b76f6eed": "轻身",
	"b8aef4aa": "力壮", "bfd0de38": "追杀", "c2b9e4a4": "追杀", "c478a468": "挡伤",
	"c88cc146": "饮血", "d29ed5d8": "守主", "d685d4e0": "挡伤", "d8df5520": "反打",
	"dda61bb2": "护主", "f08be825": "挑衅", "f3c03652": "硬皮", "f660ab62": "力壮",
	"f8579faa": "轻身", "fce54e44": "挡伤",
}


static func _migration_lookup_text(item_name: String) -> String:
	var hit: Variant = ITEM_NAME_MIGRATION.get(item_name.md5_text().substr(0, 8), null)
	return "" if hit == null else str(hit)


# 把「硬皮IV技能书」这类写法拆成 [族名, 等级]。等级支持 lv4 / LV4 / 4 / IV / 四。
static func _pet_skill_name_parts(text: String) -> Array:
	var body: = text
	if body.ends_with("技能书"):
		body = body.substr(0, body.length() - 3)
	if body.is_empty():
		return ["", 0]
	var m: = RegEx.create_from_string("(?i)^(.+?)lv(\\d+)$").search(body)
	if m != null:
		return [m.get_string(1), int(m.get_string(2))]
	m = RegEx.create_from_string("^(.+?)(\\d+)$").search(body)
	if m != null:
		return [m.get_string(1), int(m.get_string(2))]
	for token in ["IIII", "III", "IV", "VI", "II", "V", "I", "四", "三", "二", "五", "一"]:
		if not body.ends_with(token):
			continue
		var head: = body.substr(0, body.length() - token.length())
		if head.is_empty():
			return ["", 0]
		return [head, int(PET_SKILL_LEVEL_TOKENS.get(token, 0))]
	return ["", 0]


# 传进任何写法的宠物技能书名字，返回 PET_SKILL_BOOKS 里真实存在的键；不是技能书就返回空串。
static func normalize_pet_skill_book_name(item_name: String) -> String:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return ""
	if PET_SKILL_BOOKS.has(n):
		return n
	var migrated: = _migration_lookup_text(n)
	if not migrated.is_empty() and PET_SKILL_BOOKS.has(migrated):
		return migrated
	n = n.replace(" ", "").replace("　", "").replace("Ｌ", "L").replace("ｌ", "l")
	if PET_SKILL_BOOKS.has(n):
		return n
	migrated = _migration_lookup_text(n)
	if not migrated.is_empty() and PET_SKILL_BOOKS.has(migrated):
		return migrated
	var parts: Array = _pet_skill_name_parts(n)
	var family: = str(parts[0]).strip_edges()
	var level: int = int(parts[1])
	if family.is_empty() or level < 1 or level > 5:
		return ""
	var fam_hash: = family.md5_text().substr(0, 8)
	if PET_SKILL_FAMILY_HASHES.has(fam_hash):
		family = str(PET_SKILL_FAMILY_HASHES[fam_hash])
	var canonical: = "%slv%d技能书" % [family, level]
	return canonical if PET_SKILL_BOOKS.has(canonical) else ""


# 物品名总归一。没命中任何规则就原样返回，所以可以放心挂在所有物品读入路径上。
static func normalize_item_name(item_name: String) -> String:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return n
	var migrated: = _migration_lookup_text(n)
	if not migrated.is_empty():
		return migrated
	var book: = normalize_pet_skill_book_name(n)
	if not book.is_empty():
		return book
	return n


# 技能书等级（1~5）。键名后缀和 skill_key 后缀两处都能拿到，取先命中的那个。
static func pet_skill_book_level(book_name: String) -> int:
	var key: = normalize_pet_skill_book_name(book_name)
	if key.is_empty():
		return 0
	var cfg: Dictionary = PET_SKILL_BOOKS.get(key, {})
	var m: = RegEx.create_from_string("_lv(\\d+)$").search(str(cfg.get("skill_key", "")))
	if m != null:
		return int(m.get_string(1))
	var parts: Array = _pet_skill_name_parts(key)
	return int(parts[1])


# 同一技能线的下一级书名。已满级（lv5）或认不出就返回空串，UI 据此决定要不要出「2合1」。
static func pet_skill_book_next_name(book_name: String) -> String:
	var key: = normalize_pet_skill_book_name(book_name)
	if key.is_empty():
		return ""
	var lv: int = pet_skill_book_level(key)
	if lv <= 0 or lv >= 5:
		return ""
	var parts: Array = _pet_skill_name_parts(key)
	var next_key: = "%slv%d技能书" % [str(parts[0]), lv + 1]
	return next_key if PET_SKILL_BOOKS.has(next_key) else ""


# 同一技能线的 lv1 书名（拆分用）。本身就是 lv1 就返回空串。
static func pet_skill_book_base_name(book_name: String) -> String:
	var key: = normalize_pet_skill_book_name(book_name)
	if key.is_empty():
		return ""
	var lv: int = pet_skill_book_level(key)
	if lv <= 1:
		return ""
	var parts: Array = _pet_skill_name_parts(key)
	var base_key: = "%slv1技能书" % str(parts[0])
	return base_key if PET_SKILL_BOOKS.has(base_key) else ""


const ITEM_NAME_MIGRATION: = {
	"f0780cb3": "7-9冥狼崽礼包",
	"002995bd": "护主lv5技能书", "00a449d8": "护主lv5技能书", "012df4ac": "凶性lv2技能书",
	"018a29eb": "护主lv1技能书", "01a9a3e6": "硬皮lv3技能书", "01f2082c": "反打lv1技能书",
	"02c67054": "硬皮lv2技能书", "030a8652": "力壮lv4技能书", "03587b36": "破防lv1技能书",
	"03a0ce69": "力壮lv2技能书", "03c5f259": "破防lv3技能书", "04379a92": "致命lv2技能书",
	"051e949b": "自复lv2技能书", "05783b5b": "长命lv3技能书", "064e703c": "挡伤lv4技能书",
	"065f1414": "致命lv2技能书", "066c51fa": "长命lv2技能书", "0920d432": "护主lv4技能书",
	"0929896b": "力壮lv2技能书", "095763ff": "反打lv1技能书", "096157d4": "守主lv5技能书",
	"0977c140": "力壮lv5技能书", "09fa5237": "双倍经验丹(月)", "09fcdc17": "追杀lv3技能书",
	"0b052503": "挡伤lv1技能书", "0b308f26": "追杀lv1技能书", "0b4a5b08": "追杀lv1技能书",
	"0b800399": "挡伤lv4技能书", "0c3b60de": "破防lv5技能书", "0c5b3427": "反打lv3技能书",
	"0c7c9648": "轻身lv2技能书", "0ca3fc0f": "凶性lv5技能书", "0ca48917": "反打lv3技能书",
	"0d2f25a2": "力壮lv3技能书", "0d34a9ee": "守主lv1技能书", "0dbe5d33": "力壮lv3技能书",
	"0e1ee419": "挑衅lv4技能书", "0e623fe2": "饮血lv1技能书", "0e685622": "挡伤lv2技能书",
	"0e6fc001": "挑衅lv5技能书", "0ed911ff": "溅墨lv4技能书", "0ed93fd7": "力壮lv3技能书",
	"0ee31ed9": "长命lv5技能书", "0f4c87ac": "连击lv3技能书", "0f664e8e": "守主lv2技能书",
	"0fa6c95e": "守主lv2技能书", "109df1f5": "反打lv5技能书", "10c31e8b": "长命lv3技能书",
	"10d8563a": "溅墨lv3技能书", "10e2014a": "致命lv2技能书", "10e85cbf": "挡伤lv1技能书",
	"11e72d7b": "反打lv3技能书", "11fac243": "守主lv5技能书", "12278fb1": "追杀lv4技能书",
	"12aca0ba": "轻身lv4技能书", "12bdc540": "硬皮lv5技能书", "12d6521a": "长命lv1技能书",
	"14887346": "挡伤lv2技能书", "14c1b59a": "挑衅lv4技能书", "155ff7d1": "力壮lv1技能书",
	"15666cda": "挑衅lv2技能书", "15d79921": "致命lv1技能书", "161a13f9": "护主lv2技能书",
	"162f9aa6": "反打lv4技能书", "174fd3fc": "致命lv3技能书", "17731454": "护主lv2技能书",
	"1789d54a": "致命lv2技能书", "188e4eda": "轻身lv3技能书", "1924e9fb": "自复lv5技能书",
	"19a8e598": "连击lv4技能书", "19ce8c62": "轻身lv3技能书", "1ac10309": "饮血lv4技能书",
	"1b57abdd": "连击lv1技能书", "1c2613b9": "破防lv4技能书", "1c445326": "轻身lv3技能书",
	"1c6b9cae": "挑衅lv3技能书", "1ce7b1dd": "硬皮lv2技能书", "1d20cebb": "追杀lv3技能书",
	"1d311eac": "溅墨lv2技能书", "1d8cbba0": "反打lv5技能书", "1f75b22b": "追杀lv5技能书",
	"201674a9": "力壮lv2技能书", "20a4855e": "自复lv2技能书", "20b18104": "连击lv5技能书",
	"20fb8981": "饮血lv3技能书", "21c88706": "挡伤lv3技能书", "21f67475": "破防lv1技能书",
	"224a0a2c": "长命lv3技能书", "22fc8aba": "长命lv2技能书", "233dcafd": "追杀lv3技能书",
	"23711e10": "护主lv2技能书", "23a2fb68": "自复lv3技能书", "23aa5e09": "守主lv5技能书",
	"24088728": "护主lv4技能书", "24f1675a": "硬皮lv2技能书", "255387a6": "连击lv5技能书",
	"25bc7ce2": "饮血lv4技能书", "2691d42d": "挑衅lv2技能书", "269a733d": "长命lv5技能书",
	"26b29b96": "护主lv3技能书", "26c101bb": "挑衅lv1技能书", "26e3d2bb": "长命lv5技能书",
	"26f1b1d1": "破防lv5技能书", "277951cb": "守主lv4技能书", "27a4b1dd": "护主lv1技能书",
	"2820ad9a": "自复lv2技能书", "282f607f": "致命lv4技能书", "28697566": "守主lv3技能书",
	"28a9a8bb": "挑衅lv1技能书", "28b97a1e": "硬皮lv1技能书", "28e242a9": "连击lv5技能书",
	"292070cd": "护主lv4技能书", "29486859": "追杀lv3技能书", "2ace2bb2": "凶性lv4技能书",
	"2ae8e540": "破防lv5技能书", "2b73f8d6": "追杀lv5技能书", "2bd5210b": "长命lv2技能书",
	"2bfa360a": "凶性lv5技能书", "2c083f8b": "守主lv5技能书", "2c354bcc": "自复lv4技能书",
	"2c35c1b6": "破防lv5技能书", "2c6ecfe1": "自复lv4技能书", "2c8aaa0f": "追杀lv4技能书",
	"2cb9cd02": "挡伤lv5技能书", "2d1b5b9d": "凶性lv3技能书", "2d476a51": "溅墨lv4技能书",
	"2d611f78": "饮血lv2技能书", "2d666e70": "致命lv4技能书", "2dfb5fed": "力壮lv4技能书",
	"2e971337": "饮血lv3技能书", "2ec16291": "长命lv1技能书", "2f2d59b8": "致命lv3技能书",
	"2f49598c": "挑衅lv3技能书", "30336e36": "饮血lv4技能书", "3033bec7": "致命lv1技能书",
	"310f99f4": "凶性lv1技能书", "3115a1bd": "反打lv5技能书", "312bc64a": "力壮lv3技能书",
	"314fb5f8": "水属性宠物蛋", "3188180a": "长命lv4技能书", "31ba2d34": "凶性lv5技能书",
	"31d2380b": "力壮lv4技能书", "31e88d05": "连击lv4技能书", "3213694c": "守主lv3技能书",
	"32b50cc2": "凶性lv1技能书", "32d2ba60": "自复lv3技能书", "32e2b991": "力壮lv5技能书",
	"32ffe063": "反打lv2技能书", "33c1537f": "致命lv5技能书", "34877ed3": "长命lv4技能书",
	"34a495bb": "凶性lv2技能书", "34c2b8d5": "硬皮lv3技能书", "34df4852": "自复lv4技能书",
	"34df9054": "破防lv4技能书", "352cfcc1": "反打lv5技能书", "35597a80": "追杀lv4技能书",
	"3599f823": "破防lv2技能书", "35d07f25": "挡伤lv3技能书", "366bc330": "追杀lv1技能书",
	"36a86ba9": "自复lv4技能书", "37014e72": "轻身lv1技能书", "374f971d": "连击lv3技能书",
	"37bd1a95": "追杀lv2技能书", "37d651ca": "守主lv2技能书", "37fe7461": "挑衅lv1技能书",
	"39a8e55e": "致命lv3技能书", "3baf2ec4": "自复lv1技能书", "3c25de26": "破防lv4技能书",
	"3c6b2079": "饮血lv4技能书", "3cbb007d": "硬皮lv5技能书", "3d2c0b48": "破防lv2技能书",
	"3d9b28b0": "反打lv4技能书", "3e4d47c1": "致命lv3技能书", "3e98b904": "饮血lv3技能书",
	"3fe0e7c6": "自复lv3技能书", "4026fbfd": "溅墨lv2技能书", "406b449c": "追杀lv4技能书",
	"40a2a396": "破防lv1技能书", "41348917": "挑衅lv3技能书", "41770c54": "长命lv5技能书",
	"41823282": "饮血lv3技能书", "418419f1": "护主lv3技能书", "41ba4726": "破防lv2技能书",
	"41f51d07": "反打lv3技能书", "427c0f45": "饮血lv1技能书", "42b14cbb": "护主lv5技能书",
	"42e63996": "致命lv3技能书", "431b129f": "追杀lv4技能书", "43a9d12d": "守主lv3技能书",
	"441b540a": "挡伤lv4技能书", "44cca32e": "饮血lv1技能书", "4500aa86": "致命lv4技能书",
	"463a0f97": "连击lv2技能书", "46a8716d": "守主lv1技能书", "46d54b17": "反打lv2技能书",
	"46fc8965": "双倍经验丹(周)", "47276446": "守主lv2技能书", "482f1541": "轻身lv5技能书",
	"486bcc24": "连击lv4技能书", "48b5e874": "守主lv5技能书", "48bdfeb5": "破防lv4技能书",
	"48f33134": "凶性lv1技能书", "4a2f0e54": "护主lv3技能书", "4a70e142": "挑衅lv4技能书",
	"4aa1b5b8": "力壮lv2技能书", "4aa6dc77": "挡伤lv3技能书", "4b5233ca": "守主lv5技能书",
	"4d1705e3": "反打lv2技能书", "4db4ae79": "轻身lv2技能书", "4dfcd972": "力壮lv1技能书",
	"4e7b2dfe": "饮血lv1技能书", "4ece17c3": "追杀lv1技能书", "4ed91138": "长命lv1技能书",
	"4edeacec": "饮血lv5技能书", "4f1b5e26": "破防lv1技能书", "4f5d67a7": "力壮lv4技能书",
	"4f775c9c": "追杀lv1技能书", "4fa898c3": "凶性lv3技能书", "4fd06b50": "饮血lv2技能书",
	"4fd85ce1": "饮血lv5技能书", "5035e159": "溅墨lv1技能书", "5042acaf": "守主lv4技能书",
	"506a3ff2": "守主lv3技能书", "51387c82": "饮血lv2技能书", "5141e76f": "饮血lv5技能书",
	"51a4d7cd": "力壮lv1技能书", "5233305b": "挡伤lv2技能书", "53262889": "护主lv4技能书",
	"542bd4f6": "挑衅lv5技能书", "546fdf07": "致命lv3技能书", "549c2781": "致命lv2技能书",
	"54f9d7d6": "连击lv2技能书", "5506ac0a": "硬皮lv2技能书", "56924aea": "力壮lv5技能书",
	"58b75274": "凶性lv1技能书", "59d6b73c": "轻身lv1技能书", "5a51578a": "溅墨lv5技能书",
	"5a520654": "破防lv2技能书", "5b6ccb4b": "守主lv3技能书", "5ce374ac": "轻身lv1技能书",
	"5d11bba6": "自复lv4技能书", "5d44f9c7": "凶性lv2技能书", "5da75a33": "长命lv4技能书",
	"5dced12e": "破防lv2技能书", "5dfe6ffd": "连击lv1技能书", "5e067de5": "追杀lv2技能书",
	"5e2fd3f6": "轻身lv4技能书", "5e533fc4": "自复lv3技能书", "5f48acf4": "致命lv1技能书",
	"5f8777f1": "连击lv3技能书", "5ff4da0d": "轻身lv4技能书", "6039d468": "护主lv3技能书",
	"6044cb1c": "护主lv3技能书", "60c523f0": "致命lv4技能书", "60d686c5": "挡伤lv2技能书",
	"61ed41de": "硬皮lv1技能书", "62339fb5": "硬皮lv2技能书", "62a3708f": "连击lv1技能书",
	"632b005d": "连击lv3技能书", "63c0a68c": "土变异宠物蛋", "644c6af2": "饮血lv5技能书",
	"649884e6": "硬皮lv5技能书", "653b9811": "硬皮lv5技能书", "6545a333": "饮血lv2技能书",
	"668b0ad3": "力壮lv1技能书", "6695e6af": "护主lv2技能书", "66f5258e": "硬皮lv4技能书",
	"673b057a": "破防lv5技能书", "67c11894": "护主lv3技能书", "67f3dc72": "护主lv5技能书",
	"680e4eea": "护主lv1技能书", "68acb48f": "挡伤lv5技能书", "68e06259": "致命lv4技能书",
	"69560240": "轻身lv5技能书", "697eb754": "自复lv1技能书", "69a45c90": "硬皮lv1技能书",
	"69abe1f1": "长命lv4技能书", "69cc372f": "破防lv4技能书", "69fd22a5": "溅墨lv5技能书",
	"6a63fd0c": "轻身lv5技能书", "6a7b2ef3": "追杀lv2技能书", "6a8dd2e2": "饮血lv5技能书",
	"6ab9f606": "守主lv2技能书", "6adb5b76": "挡伤lv4技能书", "6b8b53d0": "长命lv3技能书",
	"6b9cb1e5": "追杀lv5技能书", "6bc8e72a": "硬皮lv1技能书", "6bf5fb06": "连击lv5技能书",
	"6bf92df2": "挡伤lv4技能书", "6c192ba8": "力壮lv5技能书", "6c62e243": "致命lv3技能书",
	"6d39be66": "连击lv2技能书", "6d788855": "护主lv3技能书", "6dcadda7": "饮血lv4技能书",
	"6de3d1c9": "硬皮lv4技能书", "6dfe67b5": "轻身lv3技能书", "6e86481a": "致命lv1技能书",
	"6ec5460f": "破防lv4技能书", "6ed01ce8": "反打lv2技能书", "6f252c27": "长命lv3技能书",
	"6f3ce81f": "凶性lv4技能书", "6f7972a6": "凶性lv1技能书", "70489a07": "挡伤lv4技能书",
	"70c476dd": "自复lv5技能书", "713fda4f": "长命lv1技能书", "7421f3a4": "追杀lv4技能书",
	"7424e6ad": "连击lv4技能书", "746a5716": "自复lv1技能书", "74f1a281": "挑衅lv1技能书",
	"754b1bc8": "饮血lv2技能书", "75547039": "溅墨lv5技能书", "755f700e": "挡伤lv5技能书",
	"75b5175c": "自复lv5技能书", "761e0d7b": "轻身lv2技能书", "76253c72": "力壮lv2技能书",
	"76258f97": "硬皮lv4技能书", "763beeeb": "守主lv2技能书", "77300ed6": "凶性lv4技能书",
	"77a3b7f5": "力壮lv1技能书", "77a4a274": "饮血lv4技能书", "78674d1c": "挡伤lv5技能书",
	"787fc7d2": "凶性lv4技能书", "79199c52": "护主lv4技能书", "796c5855": "凶性lv2技能书",
	"7985b7e1": "守主lv4技能书", "7adf25e7": "硬皮lv2技能书", "7b51df09": "溅墨lv4技能书",
	"7c2c5204": "轻身lv1技能书", "7c58aa91": "长命lv1技能书", "7c90ac79": "挑衅lv2技能书",
	"7ccd6c20": "硬皮lv5技能书", "7cd4c65b": "力壮lv1技能书", "7d1bafb9": "硬皮lv3技能书",
	"7da9f56d": "轻身lv3技能书", "7ddbeece": "长命lv3技能书", "7dfc412e": "挑衅lv4技能书",
	"7e8b5ad0": "反打lv4技能书", "7ea1f6d2": "反打lv4技能书", "7fbfaa1b": "长命lv1技能书",
	"801adfeb": "轻身lv4技能书", "8069b773": "力壮lv5技能书", "80f103a5": "饮血lv5技能书",
	"816eaa3b": "土属性宠物蛋", "81d6784e": "追杀lv2技能书", "83029388": "挑衅lv5技能书",
	"8322069e": "硬皮lv5技能书", "83848da0": "破防lv1技能书", "83a96ec6": "致命lv5技能书",
	"840477ec": "硬皮lv1技能书", "84753e28": "长命lv3技能书", "849b15c5": "致命lv5技能书",
	"84e40afb": "破防lv3技能书", "851edb02": "致命lv5技能书", "857c0d00": "连击lv3技能书",
	"873f94cc": "致命lv2技能书", "87c423dd": "硬皮lv2技能书", "87e3ceab": "长命lv2技能书",
	"87f7066e": "挡伤lv2技能书", "8859b3ac": "凶性lv3技能书", "88959a4a": "反打lv5技能书",
	"88dd255a": "饮血lv4技能书", "8a3e77b1": "挑衅lv2技能书", "8a8b154b": "致命lv5技能书",
	"8ad42de9": "力壮lv2技能书", "8b271443": "破防lv3技能书", "8b62331e": "连击lv2技能书",
	"8b8f14e6": "挡伤lv1技能书", "8bbc6e4f": "长命lv2技能书", "8c186e57": "凶性lv3技能书",
	"8c603387": "长命lv4技能书", "8c76482f": "挡伤lv3技能书", "8c9aa53a": "守主lv5技能书",
	"8df6679f": "长命lv1技能书", "8e1d9032": "硬皮lv2技能书", "8e6fc36d": "硬皮lv4技能书",
	"8e7d96e9": "挑衅lv5技能书", "8e964dde": "守主lv1技能书", "8ee3f42f": "追杀lv1技能书",
	"8ee6813d": "凶性lv5技能书", "8f2a0b30": "硬皮lv1技能书", "8fc0b6c4": "破防lv3技能书",
	"8fcda4bf": "护主lv2技能书", "8feb49e8": "挑衅lv4技能书", "90aac394": "连击lv1技能书",
	"90d1d848": "力壮lv3技能书", "90f0e082": "长命lv5技能书", "914e9910": "守主lv1技能书",
	"9154809a": "挑衅lv3技能书", "93096d13": "挑衅lv2技能书", "93201146": "饮血lv5技能书",
	"933241d8": "致命lv3技能书", "93406153": "守主lv2技能书", "938fd0b9": "轻身lv5技能书",
	"93c929d8": "挡伤lv3技能书", "9418cf4e": "追杀lv3技能书", "949a96b3": "反打lv4技能书",
	"94a5aa9b": "追杀lv1技能书", "95a406f5": "追杀lv1技能书", "95ef6479": "力壮lv4技能书",
	"95ff389f": "凶性lv3技能书", "966a3a11": "轻身lv2技能书", "975d0d7a": "长命lv4技能书",
	"9787abdf": "挑衅lv4技能书", "97945df3": "溅墨lv5技能书", "97fada90": "自复lv2技能书",
	"9822e413": "长命lv1技能书", "98889fd6": "连击lv3技能书", "996f9865": "力壮lv4技能书",
	"99891ea1": "自复lv1技能书", "99974253": "饮血lv3技能书", "9998989b": "追杀lv2技能书",
	"999c08a3": "长命lv5技能书", "99ec6edb": "挑衅lv1技能书", "9aaf4885": "凶性lv5技能书",
	"9b3ba5a9": "凶性lv2技能书", "9bfc422e": "饮血lv1技能书", "9c1515ea": "反打lv3技能书",
	"9ca71da6": "饮血lv1技能书", "9d100d05": "金属性宠物蛋", "9d4c13c2": "挡伤lv5技能书",
	"9d71c6a1": "破防lv1技能书", "9e68b6ea": "自复lv2技能书", "9e7fb167": "轻身lv2技能书",
	"9eaac947": "硬皮lv1技能书", "9f0e319d": "自复lv3技能书", "a049e46f": "挑衅lv3技能书",
	"a09f0f43": "护主lv3技能书", "a0ab3d5d": "自复lv3技能书", "a14622fd": "轻身lv3技能书",
	"a24b5269": "挑衅lv4技能书", "a28a962f": "连击lv1技能书", "a2a1c9e6": "护主lv2技能书",
	"a2e9ce6f": "自复lv5技能书", "a2f6e7b2": "反打lv3技能书", "a40eab18": "破防lv5技能书",
	"a421a198": "凶性lv4技能书", "a4330393": "反打lv2技能书", "a482b4f4": "饮血lv4技能书",
	"a4ed989b": "连击lv1技能书", "a50fbe68": "挑衅lv3技能书", "a57c5ed8": "轻身lv5技能书",
	"a57e3832": "致命lv1技能书", "a5da4db8": "轻身lv5技能书", "a5e81a3c": "连击lv3技能书",
	"a5ef04e4": "连击lv1技能书", "a62bac67": "致命lv5技能书", "a6c8f647": "挡伤lv1技能书",
	"a6fc81bb": "溅墨lv1技能书", "a7106ba9": "追杀lv5技能书", "a78d4324": "护主lv4技能书",
	"a8c424f5": "追杀lv5技能书", "aa5b117a": "挑衅lv5技能书", "aaaffc1f": "凶性lv2技能书",
	"aab5f26c": "轻身lv1技能书", "aae73289": "轻身lv3技能书", "ab6ddef2": "硬皮lv5技能书",
	"ab83f87e": "守主lv4技能书", "ab9b3d92": "反打lv1技能书", "ac3d454a": "轻身lv5技能书",
	"acaffffa": "轻身lv4技能书", "acddb82d": "自复lv2技能书", "ad35f9e6": "力壮lv5技能书",
	"adab8d9a": "力壮lv3技能书", "af5428d3": "自复lv4技能书", "affa8064": "火属性宠物蛋",
	"b003d70c": "挑衅lv2技能书", "b06eba77": "追杀lv3技能书", "b09877dd": "护主lv4技能书",
	"b0ba53a6": "自复lv1技能书", "b123a0b9": "反打lv1技能书", "b1f19b33": "挡伤lv5技能书",
	"b1f730ef": "长命lv2技能书", "b2e1f1c5": "自复lv3技能书", "b30b3196": "溅墨lv2技能书",
	"b36610f3": "挡伤lv1技能书", "b3d159e6": "硬皮lv1技能书", "b3df674b": "致命lv1技能书",
	"b40bd2b6": "挡伤lv5技能书", "b4433ec9": "追杀lv5技能书", "b44e255e": "饮血lv3技能书",
	"b5422782": "连击lv4技能书", "b5d9d37a": "凶性lv4技能书", "b6722810": "硬皮lv4技能书",
	"b6c9efbe": "护主lv5技能书", "b7568362": "轻身lv3技能书", "b76e55f8": "致命lv4技能书",
	"b76ee41e": "自复lv2技能书", "b7bb2f5d": "自复lv1技能书", "b8325e90": "金变异宠物蛋",
	"b8afac7b": "木变异宠物蛋", "b8b8d213": "硬皮lv4技能书", "ba08e879": "破防lv4技能书",
	"ba9f731c": "守主lv1技能书", "baa53ec7": "溅墨lv1技能书", "baa92c91": "凶性lv3技能书",
	"baf26852": "力壮lv3技能书", "bb958780": "反打lv3技能书", "bbc3a108": "破防lv5技能书",
	"bc8b3f17": "护主lv5技能书", "bd155520": "挡伤lv2技能书", "bd403edd": "双倍经验丹",
	"bd62270f": "凶性lv4技能书", "becb8350": "长命lv5技能书", "bf5f4a59": "木属性宠物蛋",
	"bf7bd8c7": "力壮lv5技能书", "bfa686f2": "力壮lv1技能书", "c12d6010": "连击lv2技能书",
	"c135d026": "力壮lv1技能书", "c1e3dc5b": "凶性lv2技能书", "c2124213": "反打lv1技能书",
	"c2928d2a": "饮血lv5技能书", "c3480976": "反打lv2技能书", "c35b91bd": "反打lv4技能书",
	"c3d4cafb": "挑衅lv1技能书", "c4579e06": "连击lv5技能书", "c4c85089": "反打lv4技能书",
	"c539aecd": "自复lv3技能书", "c5a75fb5": "致命lv5技能书", "c5ed4e22": "守主lv2技能书",
	"c6310c08": "饮血lv3技能书", "c7488e1e": "自复lv1技能书", "c791f5eb": "反打lv1技能书",
	"c8235b82": "挡伤lv2技能书", "c94e3d36": "轻身lv1技能书", "c95f03fb": "破防lv1技能书",
	"c9a2bd52": "守主lv3技能书", "ca021d0e": "凶性lv5技能书", "ca16f4fc": "守主lv1技能书",
	"ca77d546": "火变异宠物蛋", "cab01b95": "自复lv2技能书", "cabd4a5a": "凶性lv1技能书",
	"cb510b7a": "致命lv2技能书", "cbeee78f": "力壮lv3技能书", "cc99ac49": "护主lv1技能书",
	"cd3efdf9": "饮血lv3技能书", "cdbd82ef": "破防lv2技能书", "cdc14261": "连击lv2技能书",
	"ce89a14b": "反打lv3技能书", "ceab83b3": "追杀lv4技能书", "ceac63fa": "力壮lv5技能书",
	"cefb184f": "挑衅lv5技能书", "cf2dfef2": "凶性lv3技能书", "d0051989": "连击lv3技能书",
	"d12da0fc": "挑衅lv2技能书", "d175ed81": "挡伤lv2技能书", "d1800154": "溅墨lv3技能书",
	"d1b03e7b": "挑衅lv3技能书", "d27b18d6": "守主lv3技能书", "d28a5044": "反打lv5技能书",
	"d2bae8bc": "连击lv1技能书", "d339047c": "守主lv4技能书", "d3c9fb15": "轻身lv4技能书",
	"d3d97d7e": "破防lv4技能书", "d3fc1127": "自复lv5技能书", "d414cb29": "自复lv5技能书",
	"d49edf15": "护主lv4技能书", "d4cb2551": "挡伤lv3技能书", "d4ced04f": "破防lv2技能书",
	"d5b9261d": "自复lv5技能书", "d5bad0e3": "致命lv5技能书", "d5ca209c": "轻身lv4技能书",
	"d5ea141d": "守主lv4技能书", "d60a03bd": "硬皮lv3技能书", "d645f44b": "反打lv4技能书",
	"d68e8c32": "凶性lv4技能书", "d6f2d318": "挑衅lv5技能书", "d70ff00b": "力壮lv2技能书",
	"d7dee275": "轻身lv2技能书", "d804dc96": "破防lv3技能书", "d85faded": "连击lv2技能书",
	"d871490e": "守主lv5技能书", "d87942b6": "挡伤lv5技能书", "d87edc2e": "致命lv2技能书",
	"d8a85e58": "挑衅lv2技能书", "d8deb627": "护主lv1技能书", "d9508cb4": "凶性lv1技能书",
	"d9779da8": "连击lv5技能书", "d9b26169": "挑衅lv4技能书", "da9eb514": "护主lv2技能书",
	"dac76440": "追杀lv5技能书", "dadfa3ed": "长命lv3技能书", "dc4a7c0f": "挡伤lv3技能书",
	"dce90d9a": "凶性lv3技能书", "dcfb9d9f": "追杀lv3技能书", "dde6e8d7": "挡伤lv1技能书",
	"ddf1fbb4": "溅墨lv4技能书", "de843e03": "长命lv5技能书", "df275214": "挑衅lv5技能书",
	"dfb64c14": "挡伤lv3技能书", "e0dc149f": "守主lv1技能书", "e0eb44d9": "破防lv3技能书",
	"e13c1cdc": "凶性lv5技能书", "e140e78e": "反打lv5技能书", "e157535c": "轻身lv1技能书",
	"e1650bbc": "饮血lv1技能书", "e1c5de8a": "连击lv4技能书", "e20c172e": "轻身lv2技能书",
	"e264c84c": "轻身lv5技能书", "e2dc54ee": "追杀lv4技能书", "e30b58aa": "凶性lv5技能书",
	"e35e34e6": "护主lv1技能书", "e4c43204": "反打lv5技能书", "e547261e": "反打lv2技能书",
	"e5f11777": "挡伤lv4技能书", "e6acd52d": "挡伤lv4技能书", "e77306b5": "破防lv2技能书",
	"e80929ec": "致命lv4技能书", "e8824e15": "追杀lv2技能书", "e8a8dbc9": "护主lv5技能书",
	"e91e2d6c": "护主lv5技能书", "e94d526e": "饮血lv2技能书", "ea421907": "守主lv3技能书",
	"eacd16e3": "水变异宠物蛋", "eae91d17": "挑衅lv1技能书", "eb208f2e": "力壮lv4技能书",
	"eb633975": "饮血lv2技能书", "ecfe20d4": "轻身lv4技能书", "ed107c08": "守主lv4技能书",
	"ed7ad01b": "硬皮lv3技能书", "edd96a60": "自复lv4技能书", "ee4f8668": "轻身lv2技能书",
	"ee982b48": "追杀lv3技能书", "eea76bf8": "致命lv4技能书", "eee93f95": "连击lv2技能书",
	"ef90b1ce": "护主lv1技能书", "ef937254": "自复lv5技能书", "efe06826": "长命lv4技能书",
	"efef1551": "溅墨lv1技能书", "f07e0fb4": "追杀lv5技能书", "f08a94c0": "自复lv1技能书",
	"f0d2456d": "长命lv4技能书", "f16b8188": "追杀lv2技能书", "f17303d0": "溅墨lv3技能书",
	"f18ce84f": "凶性lv2技能书", "f27f2c6f": "挑衅lv3技能书", "f41f540f": "溅墨lv2技能书",
	"f4d8209d": "连击lv4技能书", "f58a17a8": "连击lv4技能书", "f5a01d66": "破防lv3技能书",
	"f5bfe3b1": "连击lv5技能书", "f5c35dde": "守主lv1技能书", "f5d2c715": "饮血lv1技能书",
	"f5d5ff1b": "硬皮lv4技能书", "f5f01516": "挡伤lv1技能书", "f613e0da": "力壮lv4技能书",
	"f658a033": "饮血lv2技能书", "f667e148": "挑衅lv1技能书", "f6dc10e6": "硬皮lv3技能书",
	"f77a84cd": "硬皮lv5技能书", "f7f64ffc": "破防lv5技能书", "f8788303": "破防lv3技能书",
	"f9c052a2": "反打lv1技能书", "fa373816": "凶性lv1技能书", "fa7cd09f": "追杀lv2技能书",
	"faa08942": "溅墨lv3技能书", "faba60f0": "硬皮lv3技能书", "fac61ed4": "致命lv1技能书",
	"fb1fde9a": "守主lv4技能书", "fb943b09": "反打lv1技能书", "fc51a29a": "长命lv2技能书",
	"fd2b5373": "硬皮lv4技能书", "fdd7a38b": "破防lv1技能书", "fe06c5c9": "护主lv1技能书",
	"fe6e3d0a": "护主lv2技能书", "fe749230": "自复lv4技能书", "fea1743e": "硬皮lv3技能书",
	"febf0528": "连击lv5技能书", "ff65fe5d": "反打lv2技能书", "ff81ba46": "轻身lv1技能书",
	"ffcbf7aa": "挡伤lv1技能书", "ffebf667": "力壮lv2技能书", "fff095e7": "长命lv2技能书",
	"fffe09cd": "致命lv1技能书",
}


# 老存档、老邮件、老帮派仓库里存的是改名前的物品名。读进来先过这一道：
# 命中就换成现用名，没命中原样返回。这样玩家背包不会冒出一堆「未知物品」。
static func migrate_item_name(item_name: String) -> String:
	var n: = str(item_name).strip_edges()
	if n.is_empty():
		return n
	var hit: Variant = ITEM_NAME_MIGRATION.get(n.md5_text().substr(0, 8), null)
	if hit != null:
		n = str(hit)
	return normalize_item_name(n)


const MAP_NAME_MIGRATION: = {
	"bd81bc63": "凌云幻城", "30a4af24": "凌云台",
	"d15606ae": "浮光水城外郊", "e8c53648": "深碧海城",
	"ef1aee2b": "深碧海底", "47d35101": "沉寂的古城",
	"5614d762": "逆之往昔", "77d0c50b": "逆之心绪",
	"427ae0b1": "逆之幻影", "bcf30262": "传说中的侠骨冢",
	"b041d1e9": "碧之绿洲", "86363ad3": "幽界之森",
	"9919f6c3": "碧野云霄", "5bbceb8a": "忘归海岸",
	"692d9a63": "断魄涯", "2af44e61": "盘桓林",
	"754918d5": "空明园", "351e6036": "衡霄台",
	"e1106991": "落尘台", "2e9e89e0": "余恨原",
	"49f7d308": "凝泪岗", "33ac0836": "回望亭",
	"6668b84d": "幽思坡", "b2745f74": "闲逸园",
	"d0e97723": "暮还道", "ca0fb54b": "孤影亭",
	"0ac97dc3": "醉客冢", "3e6f0b85": "盈露台守望区",
	"9ffab7a1": "莹冰桥", "ab6c8985": "澄沙原",
	"282baa9d": "鸾之谷", "dbdf6ad0": "剑潭谷",
	"95e832d7": "双玺谷", "d39b1d79": "玄铜洞窟",
	"93dba7ae": "玄铜洞窟2", "435fdad0": "惊魂洞窟1",
	"13089d59": "惊魂洞窟2", "52513ec4": "四津原",
	"d5a075db": "寒泉台", "ece2708f": "将军碣谷",
	"8bbc19e0": "灵菇洞", "902441ec": "幽怨洞",
	"0ac307be": "幽怨洞口", "b0eac63b": "鸠鸣小舍",
	"613edcfa": "斧翠谷", "fedb9742": "暮枫林",
	"c5450519": "松霜野", "a6eb0f8d": "废井原",
	"a0eb72d9": "榕根谷", "8c6069bc": "炊霭谷",
	"619aa4d5": "耕春原", "58b83dca": "孤木原",
	"18e4c2c2": "莹玉桥", "d4f78b0a": "蟠龙洞窟",
	"61d30dc0": "蟠龙洞窟2", "7aa0895c": "紫藓洞窟",
	"8072e33d": "紫藓洞窟2", "945ed48d": "翠幽洞",
	"01f7291c": "西霜岭", "4d80ee32": "望日桥",
	"2e51df9b": "望日桥头", "3f2e689e": "铜钟洞窟",
	"d1f4aabb": "铜偶殿", "72d58dc5": "银瓮谷",
	"4ba5e56b": "镜霜原", "8e94b7bd": "雪霁谷",
	"7b23890a": "青幽洞", "1d0aedf6": "青岚原",
	"8e6e9dcd": "望阙林场", "bf24e07c": "沙寇洞口",
	"5b7cdf5c": "清邃古洞", "809638fd": "清邃古洞二区",
	"c88ae8d6": "清邃古洞三区", "d620555b": "清邃古洞四区",
}


static func migrate_map_id(map_id: String) -> String:
	# 地图改名后，老存档里的 mapId 还是旧地名，这里按「名字（x,y）」拆开只换名字部分。
	var s: = str(map_id).strip_edges()
	if s.is_empty():
		return s
	var cut: int = s.rfind("（")
	var head: String = s if cut <= 0 else s.substr(0, cut)
	var tail: String = "" if cut <= 0 else s.substr(cut)
	var hit: Variant = MAP_NAME_MIGRATION.get(head.md5_text().substr(0, 8), null)
	if hit == null:
		return s
	return str(hit) + tail


# 宠物图鉴改名表。老存档里宠物存的是显示名（pet_name），名字一换就会变成未知宠物，
# 而且 pet_id 缺失时还要靠名字反查图鉴键 —— 两头都会断，所以读档时先过这道归一。
# 键同样是 md5 前 8 位，磁盘与包内不留旧名明文。
const PET_NAME_MIGRATION: = {
	"0b6cbb8d": "小猪比特", "0c79a7b4": "哪吒",
	"19600219": "西门吹雪", "354cdebd": "八岐炎君",
	"42b01dcb": "冥狼崽", "6683ed92": "绝情大帝",
	"6a79a030": "齐天宝", "75113599": "阿努比斯",
	"973d625c": "火舞姬", "9c08fd50": "白刃机娘",
	"a50a0308": "九尾炎狐", "be4ab4cb": "星塔智灵",
	"d7e394a6": "青柳仙尊", "d8761a4f": "小猪安特",
	"dd6aad6d": "超级阿努", "df011735": "阿格留斯",
	"fbc691e0": "六道影忍",
	"5f4a1ae8": "阿努比斯", "84e8a484": "哪吒",
	"bdb5d042": "西门吹雪", "96e83632": "阿格留斯",
	"88628a01": "小猪比特", "30346835": "小猪安特",
	"7d291460": "超级阿努",
}


static func migrate_pet_name(pet_name: String) -> String:
	var n: = str(pet_name).strip_edges()
	if n.is_empty():
		return n
	var hit: Variant = PET_NAME_MIGRATION.get(n.md5_text().substr(0, 8), null)
	if hit == null:
		return n
	return str(hit)


const ALL_ITEMS = {
	"小还丹": {"name": "小还丹", "type": "pill", "rarity": "common", "mp_restore": 10, "hp_restore": 0, "desc": "恢复10点内力", "drop_rate": 0}, 
	"中还丹": {"name": "中还丹", "type": "pill", "rarity": "uncommon", "mp_restore": 30, "hp_restore": 0, "desc": "恢复30点内力", "drop_rate": 0}, 
	"大还丹": {"name": "大还丹", "type": "pill", "rarity": "rare", "mp_restore": 100, "hp_restore": 0, "desc": "恢复100点内力", "drop_rate": 0}, 
	"回血丹": {"name": "回血丹", "type": "pill", "rarity": "common", "mp_restore": 0, "hp_restore": 50, "desc": "恢复50点生命", "drop_rate": 0}, 
	"疗伤丹": {"name": "疗伤丹", "type": "pill", "rarity": "uncommon", "mp_restore": 0, "hp_restore": 200, "desc": "恢复200点生命", "drop_rate": 0}, 
	"金刚药": {"name": "金刚药", "type": "pill", "rarity": "rare", "mp_restore": 0, "hp_restore": 500, "desc": "恢复500点生命", "drop_rate": 0}, 
	"聚气丹": {"name": "聚气丹", "type": "pill", "rarity": "common", "mp_restore": 20, "hp_restore": 20, "desc": "恢复20点内力和20点生命", "drop_rate": 0}, 
	"仙露丹": {"name": "仙露丹", "type": "pill", "rarity": "rare", "mp_restore": 50, "hp_restore": 100, "desc": "恢复50点内力和100点生命", "drop_rate": 0}, 
	"神灵丹": {"name": "神灵丹", "type": "pill", "rarity": "epic", "mp_restore": 200, "hp_restore": 300, "desc": "恢复200点内力和300点生命", "drop_rate": 0}, 
	"长生丹": {"name": "长生丹", "type": "pill", "rarity": "epic", "mp_restore": 300, "hp_restore": 500, "desc": "恢复300点内力和500点生命", "drop_rate": 0}, 
	"造化丹": {"name": "造化丹", "type": "pill", "rarity": "legendary", "mp_restore": 800, "hp_restore": 800, "desc": "恢复800点内力和800点生命", "drop_rate": 0}, 
	"玄铁": {"name": "玄铁", "type": "material", "rarity": "common", "desc": "基础锻造材料", "drop_rate": 0}, 
	"精铁": {"name": "精铁", "type": "material", "rarity": "common", "desc": "精炼过的铁块", "drop_rate": 0}, 
	"金刚石": {"name": "金刚石", "type": "material", "rarity": "uncommon", "desc": "坚硬无比的宝石", "drop_rate": 0}, 
	"灵木": {"name": "灵木", "type": "material", "rarity": "common", "desc": "蕴含灵气的木材", "drop_rate": 0}, 
	"寒冰精": {"name": "寒冰精", "type": "material", "rarity": "uncommon", "desc": "蕴含寒冰之力的稀有材料", "drop_rate": 0}, 
	"烈火石": {"name": "烈火石", "type": "material", "rarity": "uncommon", "desc": "蕴含烈火之力的稀有材料", "drop_rate": 0}, 
	"天雷石": {"name": "天雷石", "type": "material", "rarity": "rare", "desc": "蕴含天雷之力的珍贵材料", "drop_rate": 0}, 
	"星辰砂": {"name": "星辰砂", "type": "material", "rarity": "rare", "desc": "来自天外陨石的珍贵材料", "drop_rate": 0}, 
	"龙鳞": {"name": "龙鳞", "type": "material", "rarity": "epic", "desc": "传说中的龙鳞", "drop_rate": 0}, 
	"凤羽": {"name": "凤羽", "type": "material", "rarity": "epic", "desc": "传说中的凤羽", "drop_rate": 0}, 
	"混沌石": {"name": "混沌石", "type": "material", "rarity": "legendary", "desc": "天地初开时的混沌之石", "drop_rate": 0}, 
	"仙晶": {"name": "仙晶", "type": "material", "rarity": "legendary", "desc": "蕴含仙气的晶石", "drop_rate": 0}, 
	"灵草": {"name": "灵草", "type": "herb", "rarity": "common", "desc": "常见的灵气草药", "drop_rate": 0.002}, 
	"灵芝": {"name": "灵芝", "type": "herb", "rarity": "uncommon", "desc": "珍稀的墨芝，蕴含灵气", "drop_rate": 0.001}, 
	"天山雪莲": {"name": "天山雪莲", "type": "herb", "rarity": "rare", "desc": "生长于天山之巅的雪莲", "drop_rate": 0.001}, 
	"九转还魂草": {"name": "九转还魂草", "type": "herb", "rarity": "epic", "desc": "传说中的仙草", "drop_rate": 0.0005}, 
	"龙涎草": {"name": "龙涎草", "type": "herb", "rarity": "legendary", "desc": "龙息孕育的神草", "drop_rate": 0.0001}, 
	"聚灵丹": {"name": "聚灵丹", "type": "cultivation_pill", "rarity": "common", "cultivation_bonus": 100, "desc": "增加100点修行值（每世限用5颗）", "drop_rate": 0}, 
	"凝神丹": {"name": "凝神丹", "type": "cultivation_pill", "rarity": "uncommon", "cultivation_bonus": 200, "desc": "增加200点修行值（每世限用5颗）", "drop_rate": 0}, 
	"悟道仙丹": {"name": "悟道仙丹", "type": "cultivation_pill", "rarity": "rare", "cultivation_bonus": 500, "desc": "增加500点修行值（每世限用5颗）", "drop_rate": 0}, 
	"双倍经验丹": {"name": "双倍经验丹", "type": "gift", "rarity": "legendary", "desc": "使用后野外战斗和离线经验提升100%，持续24小时，可与VIP经验加成叠加", "drop_rate": 0}, 
	"双倍经验丹(月)": {"name": "双倍经验丹(月)", "type": "gift", "rarity": "legendary", "desc": "使用后野外战斗和离线经验提升100%，持续30天，可与VIP经验加成叠加", "drop_rate": 0}, 
	"双倍经验丹(周)": {"name": "双倍经验丹(周)", "type": "gift", "rarity": "legendary", "desc": "使用后野外战斗和离线经验提升100%，持续7天，可与VIP经验加成叠加", "drop_rate": 0}, 
	"宠物双倍经验丹": {"name": "宠物双倍经验丹", "type": "gift", "rarity": "epic", "desc": "使用后出战灵兽获得的经验翻倍（野外/离线都算），持续30分钟；只加灵兽，不影响人物", "drop_rate": 0}, 
	"宠物补章器": {"name": "宠物补章器", "type": "gift", "rarity": "epic", "desc": "使用后为当前出战宠物随机增加1个勋章（总上限15）", "drop_rate": 0}, 
	"天关礼包": {"name": "天关礼包", "type": "gift", "rarity": "rare", "desc": "每10关BOSS掉落的天关锦囊", "drop_rate": 0}, 
	"兄弟天关令牌": {"name": "兄弟天关令牌", "type": "material", "rarity": "rare", "desc": "兄弟天关队长开战消耗，仙魔战场兄弟天关遗址事件产出", "drop_rate": 0}, 
	"建设材料": {"name": "建设材料", "type": "material", "rarity": "uncommon", "desc": "帮派建设捐献材料，可捐献至帮派仓库", "drop_rate": 0}, 
	"兄弟天关礼包": {"name": "兄弟天关礼包", "type": "gift", "rarity": "epic", "desc": "兄弟天关通关奖励礼包，服务端开箱", "drop_rate": 0}, 
	"塔1礼包": {"name": "塔1礼包", "type": "gift", "rarity": "epic", "desc": "生死塔第1层塔主奖励。开箱随机：1亿金币77%、五行变异宠物蛋5%、悟道仙丹5%、6+可进化/不可进化宠礼包各5%、宠物经验丹/人物经验丹/法宝洗练石各1%", "drop_rate": 0}, 
	"塔2礼包": {"name": "塔2礼包", "type": "gift", "rarity": "epic", "desc": "生死塔第2层塔主奖励。开箱随机：2亿金币77%、五行变异宠物蛋5%、悟道仙丹5%、7+可进化/不可进化宠礼包各5%、宠物经验丹/人物经验丹/法宝洗练石各1%", "drop_rate": 0}, 
	"塔3礼包": {"name": "塔3礼包", "type": "gift", "rarity": "legendary", "desc": "生死塔第3层塔主奖励。开箱随机：3亿金币77%、五行变异宠物蛋5%、悟道仙丹5%、8+可进化/不可进化宠礼包各5%、宠物经验丹/人物经验丹/法宝洗练石各1%", "drop_rate": 0}, 
	"塔4礼包": {"name": "塔4礼包", "type": "gift", "rarity": "legendary", "desc": "生死塔第4层塔主奖励。开箱随机：4亿金币76%、五行变异宠物蛋5%、悟道仙丹5%、9+可进化/不可进化宠礼包各5%、宠物经验丹/人物经验丹/法宝洗练石/套装强化石各1%", "drop_rate": 0}, 
	"塔5礼包": {"name": "塔5礼包", "type": "gift", "rarity": "divine", "desc": "生死塔第5层塔主奖励。开箱随机：5亿金币75%、五行变异宠物蛋5%、悟道仙丹5%、10+可进化/不可进化宠礼包各5%、宠物经验丹/人物经验丹/法宝洗练石/法宝重置石/套装强化石各1%", "drop_rate": 0}, 
	"生死塔参与礼包": {"name": "生死塔参与礼包", "type": "gift", "rarity": "epic", "desc": "生死塔开赛参与奖励。开箱随机：1亿金币98.5%、五行变异宠物蛋之一1%、法宝洗练石0.5%", "drop_rate": 0}, 
	"世界boss礼包": {"name": "世界boss礼包", "type": "gift", "rarity": "legendary", "desc": "世界boss排名奖励礼包，服务端开箱", "drop_rate": 0}, 
	"冠军礼包": {"name": "冠军礼包", "type": "gift", "rarity": "divine", "desc": "竞技场周榜冠军奖励礼包，服务端开箱", "drop_rate": 0}, 
	"亚军礼包": {"name": "亚军礼包", "type": "gift", "rarity": "legendary", "desc": "竞技场周榜亚军奖励礼包，服务端开箱", "drop_rate": 0}, 
	"季军礼包": {"name": "季军礼包", "type": "gift", "rarity": "legendary", "desc": "竞技场周榜季军奖励礼包，服务端开箱", "drop_rate": 0}, 
	"十强礼包": {"name": "十强礼包", "type": "gift", "rarity": "epic", "desc": "竞技场周榜4-10名奖励礼包，服务端开箱", "drop_rate": 0}, 
	"一箭三雕": {"name": "一箭三雕", "type": "martial_skill_book", "rarity": "legendary", "desc": "人物技能书，使用后随机领悟1-9层。装备后普攻最多打3个目标，每箭伤害1层80%、9层120%", "drop_rate": 0}, 
	"以战养战": {"name": "以战养战", "type": "martial_skill_book", "rarity": "legendary", "desc": "人物技能书，使用后随机领悟1-9层。装备后普攻50%概率吸血，1层回伤害的5%、9层回20%", "drop_rate": 0}, 
	"套装强化石": {"name": "套装强化石", "type": "material", "rarity": "legendary", "desc": "套装强化道具", "drop_rate": 0}, 
	"新手礼包": {"name": "新手礼包", "type": "gift", "rarity": "rare", "desc": "打开后获得一套单属性+50装备", "drop_rate": 0}, 
	# 2026-11-07：原版 rules.drop_rates 里根本没有「钱币袋」，这里的 0.13 是早期
	# 残留，get_random_drop() 每场战斗都 roll 到它，线上一个号攒到 12 万个 / 121 格 999。
	# 用户定口径改为 0.05（5%）；服务端 /economy/drop-config 也会下发同名值覆盖，
	# 以后调爆率只改 runtime-config.json 的 drop_rate_overrides，不用重新出包。
	"钱币袋": {"name": "钱币袋", "type": "gift", "rarity": "rare", "desc": "打开获得10万金币。所有赞助钱袋已合并为这一种。", "drop_rate": 0.05}, 
	"内测先锋礼包": {"name": "内测先锋礼包", "type": "gift", "rarity": "legendary", "desc": "打开后获得1亿金币、1只成长6.0赤翅蛾和一套单属性+100装备", "drop_rate": 0}, 
	"新人扶持礼包": {"name": "新人扶持礼包", "type": "gift", "rarity": "legendary", "desc": "打开后获得1亿金币、1只成长6.0赤翅蛾和一套单属性+100装备", "drop_rate": 0}, 
	"开荒礼包": {"name": "开荒礼包", "type": "gift", "rarity": "legendary", "desc": "打开后获得5亿金币、7只成长6.0赤翅蛾和一套单属性+400装备", "drop_rate": 0}, 
	"五一活动礼包": {"name": "五一活动礼包", "type": "gift", "rarity": "legendary", "desc": "2026五一活动限定礼包，打开后随机获得节日奖励。", "drop_rate": 0}, 
	"端午节礼包": {"name": "端午节礼包", "type": "gift", "rarity": "legendary", "desc": "2026端午节活动限定礼包，打开后随机获得节日奖励。", "drop_rate": 0}, 
	"七夕节礼包": {"name": "七夕节礼包", "type": "gift", "rarity": "legendary", "desc": "2026七夕节活动限定礼包，打开后随机获得节日奖励。", "drop_rate": 0},               
	"极限装备礼包": {"name": "极限装备礼包", "type": "gift", "rarity": "legendary", "desc": "打开后获得极限武器、极限衣服、极限鞋子、极限血佩和极限内带", "drop_rate": 0}, 
	"悟道仙丹礼包": {"name": "悟道仙丹礼包", "type": "gift", "rarity": "legendary", "desc": "打开后获得悟道仙丹 x50", "drop_rate": 0}, 
	"100关礼包": {"name": "100关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关100层的里程碑奖励", "drop_rate": 0}, 
	"200关礼包": {"name": "200关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关200层的里程碑奖励", "drop_rate": 0}, 
	"300关礼包": {"name": "300关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关300层的里程碑奖励", "drop_rate": 0}, 
	"400关礼包": {"name": "400关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关400层的里程碑奖励", "drop_rate": 0}, 
	"500关礼包": {"name": "500关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关500层的里程碑奖励", "drop_rate": 0}, 
	"600关礼包": {"name": "600关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关600层的里程碑奖励", "drop_rate": 0}, 
	"700关礼包": {"name": "700关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关700层的里程碑奖励", "drop_rate": 0}, 
	"800关礼包": {"name": "800关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关800层的里程碑奖励", "drop_rate": 0}, 
	"900关礼包": {"name": "900关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关900层的里程碑奖励", "drop_rate": 0}, 
	"1000关礼包": {"name": "1000关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1000层的里程碑奖励", "drop_rate": 0}, 
	"1100关礼包": {"name": "1100关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1100层的里程碑奖励", "drop_rate": 0}, 
	"1200关礼包": {"name": "1200关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1200层的里程碑奖励", "drop_rate": 0}, 
	"1300关礼包": {"name": "1300关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1300层的里程碑奖励", "drop_rate": 0}, 
	"1400关礼包": {"name": "1400关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1400层的里程碑奖励", "drop_rate": 0}, 
	"1500关礼包": {"name": "1500关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1500层的里程碑奖励", "drop_rate": 0}, 
	"1600关礼包": {"name": "1600关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1600层的里程碑奖励", "drop_rate": 0}, 
	"1700关礼包": {"name": "1700关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1700层的里程碑奖励", "drop_rate": 0}, 
	"1800关礼包": {"name": "1800关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1800层的里程碑奖励", "drop_rate": 0}, 
	"1900关礼包": {"name": "1900关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关1900层的里程碑奖励", "drop_rate": 0}, 
	"2000关礼包": {"name": "2000关礼包", "type": "gift", "rarity": "legendary", "desc": "闯过天关2000层的里程碑奖励，天关终极挑战！", "drop_rate": 0}, 
	"离线宠物礼包": {"name": "离线宠物礼包", "type": "gift", "rarity": "rare", "desc": "打开可获得一只极品宠物，宠物来自离线挂机地图", "drop_rate": 0}, 
	"人物升级丹": {"name": "人物升级丹", "type": "gift", "rarity": "legendary", "desc": "使用后人物直接提升到1200级（满级），获得所有升级属性", "drop_rate": 0}, 
	"宠物升级丹": {"name": "宠物升级丹", "type": "gift", "rarity": "legendary", "desc": "使用后出战宠物直接升到满级（可进化宠1200级，不可进化宠1500级）", "drop_rate": 0}, 
	"5+宠物礼包": {"name": "5+宠物礼包", "type": "gift", "rarity": "rare", "desc": "打开后随机获得一只成长5.0-6.0的宠物", "drop_rate": 0}, 
	"6+可进化宠礼包": {"name": "6+可进化宠礼包", "type": "gift", "rarity": "epic", "desc": "打开后随机获得一只成长6.0-6.9的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"7+可进化宠礼包": {"name": "7+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长7.0-7.3的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"6+不可进化宠礼包": {"name": "6+不可进化宠礼包", "type": "gift", "rarity": "epic", "desc": "打开后随机获得一只1级0代不可进化宠，成长6.0-6.5；不含活动限定宠物", "drop_rate": 0}, 
	"7+不可进化宠礼包": {"name": "7+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长7.0-7.5；不含活动限定宠物", "drop_rate": 0}, 
	"8+不可进化宠礼包": {"name": "8+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长8.0-8.5；不含活动限定宠物", "drop_rate": 0}, 
	"8+可进化宠礼包": {"name": "8+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长8.0-8.9的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"9+可进化宠礼包": {"name": "9+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长9.0-9.9的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"9+不可进化宠礼包": {"name": "9+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长9.0-9.5；不含活动限定宠物", "drop_rate": 0}, 
	"10+不可进化宠礼包": {"name": "10+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长10.0-10.5；不含活动限定宠物", "drop_rate": 0}, 
	"11+不可进化宠礼包": {"name": "11+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长11.0-11.5；不含活动限定宠物", "drop_rate": 0}, 
	"10+可进化宠礼包": {"name": "10+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长10.0-10.9的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"11+可进化宠礼包": {"name": "11+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长11.0-11.9的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"12+不可进化宠礼包": {"name": "12+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长12.0-12.5；不含活动限定宠物", "drop_rate": 0}, 
	"12+可进化宠礼包": {"name": "12+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长12.0-12.99的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"13+不可进化宠礼包": {"name": "13+不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级0代不可进化宠，成长13.0-13.5；不含活动限定宠物", "drop_rate": 0}, 
	"13+可进化宠礼包": {"name": "13+可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长13.0-13.99的1级初级形态可进化宠（超稀有总概率1%）", "drop_rate": 0}, 
	"6+可进化宠礼包(可能变异)": {"name": "6+可进化宠礼包(可能变异)", "type": "gift", "rarity": "epic", "desc": "打开后随机获得一只成长6.0-6.9的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"7+可进化宠礼包(可能变异)": {"name": "7+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长7.0-7.3的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"8+可进化宠礼包(可能变异)": {"name": "8+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长8.0-8.9的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"9+可进化宠礼包(可能变异)": {"name": "9+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长9.0-9.9的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"10+可进化宠礼包(可能变异)": {"name": "10+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长10.0-10.9的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"11+可进化宠礼包(可能变异)": {"name": "11+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长11.0-11.9的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"12+可进化宠礼包(可能变异)": {"name": "12+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长12.0-12.99的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"13+可进化宠礼包(可能变异)": {"name": "13+可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长13.0-13.99的1级可进化宠，约10%几率获得变异1", "drop_rate": 0}, 
	"6+不可进化宠礼包(可能变异)": {"name": "6+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "epic", "desc": "打开后随机获得一只1级不可进化宠，成长6.0-6.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"7+不可进化宠礼包(可能变异)": {"name": "7+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长7.0-7.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"8+不可进化宠礼包(可能变异)": {"name": "8+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长8.0-8.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"9+不可进化宠礼包(可能变异)": {"name": "9+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长9.0-9.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"10+不可进化宠礼包(可能变异)": {"name": "10+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长10.0-10.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"11+不可进化宠礼包(可能变异)": {"name": "11+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长11.0-11.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"12+不可进化宠礼包(可能变异)": {"name": "12+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长12.0-12.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"13+不可进化宠礼包(可能变异)": {"name": "13+不可进化宠礼包(可能变异)", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级不可进化宠，成长13.0-13.5，约10%几率获得变异1；不含活动限定宠物", "drop_rate": 0}, 
	"10-13变异不可进化宠礼包": {"name": "10-13变异不可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级变异1不可进化宠，成长10.0-13.5；不含活动限定宠物", "drop_rate": 0}, 
	"10-13变异可进化宠礼包": {"name": "10-13变异可进化宠礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只1级幼年形态变异1可进化宠，成长10.0-13.99（超稀有总概率1%）", "drop_rate": 0}, 
	"7-9水晶儿礼包": {"name": "7-9水晶儿礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长7.0-9.9的1级初级形态水晶儿", "drop_rate": 0}, 
	"7-9梦晶儿礼包": {"name": "7-9梦晶儿礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长7.0-9.9的1级初级形态梦晶儿", "drop_rate": 0}, 
	"7-9冥狼崽礼包": {"name": "7-9冥狼崽礼包", "type": "gift", "rarity": "legendary", "desc": "打开后随机获得一只成长7.0-9.9的1级初级形态冥狼崽", "drop_rate": 0}, 
	"金宠物转生令牌": {"name": "金宠物转生令牌", "type": "material", "rarity": "epic", "desc": "金系宠物转生材料", "drop_rate": 0}, 
	"木宠物转生令牌": {"name": "木宠物转生令牌", "type": "material", "rarity": "epic", "desc": "木系宠物转生材料", "drop_rate": 0}, 
	"水宠物转生令牌": {"name": "水宠物转生令牌", "type": "material", "rarity": "epic", "desc": "水系宠物转生材料", "drop_rate": 0}, 
	"火宠物转生令牌": {"name": "火宠物转生令牌", "type": "material", "rarity": "epic", "desc": "火系宠物转生材料", "drop_rate": 0}, 
	"土宠物转生令牌": {"name": "土宠物转生令牌", "type": "material", "rarity": "epic", "desc": "土系宠物转生材料", "drop_rate": 0}, 
	"金魂魄50": {"name": "金魂魄50", "type": "pet_soul_item", "rarity": "rare", "desc": "使用后获得金属性宠物魂魄50点", "soul_element": "金", "soul_points": 50, "drop_rate": 0}, 
	"木魂魄50": {"name": "木魂魄50", "type": "pet_soul_item", "rarity": "rare", "desc": "使用后获得木属性宠物魂魄50点", "soul_element": "木", "soul_points": 50, "drop_rate": 0}, 
	"水魂魄50": {"name": "水魂魄50", "type": "pet_soul_item", "rarity": "rare", "desc": "使用后获得水属性宠物魂魄50点", "soul_element": "水", "soul_points": 50, "drop_rate": 0}, 
	"火魂魄50": {"name": "火魂魄50", "type": "pet_soul_item", "rarity": "rare", "desc": "使用后获得火属性宠物魂魄50点", "soul_element": "火", "soul_points": 50, "drop_rate": 0}, 
	"土魂魄50": {"name": "土魂魄50", "type": "pet_soul_item", "rarity": "rare", "desc": "使用后获得土属性宠物魂魄50点", "soul_element": "土", "soul_points": 50, "drop_rate": 0}, 
	"幻化符": {"name": "幻化符", "type": "material", "rarity": "epic", "desc": "宠物幻化时勾选使用，消耗一张可使本次完美幻化几率提升15%", "drop_rate": 0}, 
	"5+宠物蛋": {"name": "5+宠物蛋", "type": "pet_egg", "rarity": "rare", "desc": "打开后随机获得一只成长约5.0～6.0的宠物（与五行属性宠物蛋不同）", "drop_rate": 0}, 
	"藏宝箱": {"name": "藏宝箱", "type": "treasure_chest", "rarity": "epic", "desc": "藏宝洞争夺获胜所得，在背包中使用可开启并获得随机奖励", "drop_rate": 0}, 
	"青铜宝箱": {"name": "青铜宝箱", "type": "chest", "rarity": "uncommon", "desc": "幸运抽奖奖励物品，可在对应玩法中使用", "drop_rate": 0}, 
	"白银宝箱": {"name": "白银宝箱", "type": "chest", "rarity": "rare", "desc": "幸运抽奖奖励物品，可在对应玩法中使用", "drop_rate": 0}, 
	"黄金宝箱": {"name": "黄金宝箱", "type": "chest", "rarity": "epic", "desc": "幸运抽奖奖励物品，可在对应玩法中使用", "drop_rate": 0}, 
	"极限武器": {"name": "极限武器", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"极限衣服": {"name": "极限衣服", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"极限鞋子": {"name": "极限鞋子", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"极限血佩": {"name": "极限血佩", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"极限血配": {"name": "极限血佩", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"极限内带": {"name": "极限内带", "type": "material", "rarity": "legendary", "desc": "可用于锻造属性转移的极限装备材料", "drop_rate": 0}, 
	"测试礼包": {"name": "测试礼包", "type": "gift", "rarity": "divine", "desc": "GM测试专用礼包，打开获得测试装备、8只赤翅蛾和1亿金币", "drop_rate": 0}, 
	"开荒宠装礼包": {"name": "开荒宠装礼包", "type": "gift", "rarity": "legendary", "desc": "打开获得一套各单属性+500的宠物装备（开荒武器/护甲等，带宠字后缀）", "drop_rate": 0}, 

	"仙魔灵兽礼包": {"name": "仙魔灵兽礼包", "type": "gift", "rarity": "epic", "desc": "仙魔战场获得的灵兽礼包，打开后随机获得一只宠物库中的宠物，成长5.0-6.0", "drop_rate": 0}, 
	"仙魔神兽礼包": {"name": "仙魔神兽礼包", "type": "gift", "rarity": "legendary", "desc": "仙魔战场获得的神兽礼包，打开后随机获得一只宠物库中的宠物，成长6.2-6.8", "drop_rate": 0}, 
	"仙魔变异礼包": {"name": "仙魔变异礼包", "type": "gift", "rarity": "legendary", "desc": "仙魔战场获得的变异灵兽礼包，打开后随机获得一只宠物库中的宠物，成长6.0-6.5", "drop_rate": 0}, 
	"仙魔野生礼包": {"name": "仙魔野生礼包", "type": "gift", "rarity": "rare", "desc": "仙魔战场获得的野生灵兽礼包，打开后随机获得一只宠物库中的宠物，成长4.5-5.5", "drop_rate": 0}, 


	"测试武器": {"name": "测试武器", "type": "equipment", "rarity": "divine", "desc": "GM测试专用武器，攻击+500", "drop_rate": 0}, 
	"测试衣服": {"name": "测试衣服", "type": "equipment", "rarity": "divine", "desc": "GM测试专用衣服，防御+500", "drop_rate": 0}, 
	"测试帽子": {"name": "测试帽子", "type": "equipment", "rarity": "divine", "desc": "GM测试专用帽子，敏捷+500", "drop_rate": 0}, 
	"测试鞋子": {"name": "测试鞋子", "type": "equipment", "rarity": "divine", "desc": "GM测试专用鞋子，生命+500", "drop_rate": 0}, 
	"测试饰品": {"name": "测试饰品", "type": "equipment", "rarity": "divine", "desc": "GM测试专用饰品，法力+500", "drop_rate": 0}, 


	"强化石": {"name": "强化石", "type": "material", "rarity": "uncommon", "desc": "用于强化装备的材料", "drop_rate": 0}, 
	"宠装碎片": {"name": "宠装碎片", "type": "material", "rarity": "uncommon", "desc": "分解由青铜、白银、黄金类宝箱产出的宠物装备可得；按装备档次，青铜系得1片、银月系得2片、金鳞系得3片。集齐10片可合成1枚宠装强化石。", "drop_rate": 0}, 
	"普通法宝碎片": {"name": "普通法宝碎片", "type": "material", "rarity": "common", "desc": "仅1000级及以上野外地图、普通难度掉落，100片可合成普通法宝。", "drop_rate": 0}, 
	"困难法宝碎片": {"name": "困难法宝碎片", "type": "material", "rarity": "uncommon", "desc": "仅1000级及以上野外地图、困难难度掉落，100片可合成困难法宝。", "drop_rate": 0}, 
	"地狱法宝碎片": {"name": "地狱法宝碎片", "type": "material", "rarity": "uncommon", "desc": "仅1000级及以上野外地图、地狱难度掉落，100片可合成地狱法宝。", "drop_rate": 0}, 
	"史诗法宝碎片": {"name": "史诗法宝碎片", "type": "material", "rarity": "rare", "desc": "仅1000级及以上野外地图、史诗难度掉落，100片可合成史诗法宝。", "drop_rate": 0}, 
	"传说法宝碎片": {"name": "传说法宝碎片", "type": "material", "rarity": "rare", "desc": "仅1000级及以上野外地图、传说难度掉落，100片可合成传说法宝。", "drop_rate": 0}, 
	"至尊法宝碎片": {"name": "至尊法宝碎片", "type": "material", "rarity": "epic", "desc": "仅1000级及以上野外地图、至尊难度掉落，100片可合成至尊法宝。", "drop_rate": 0}, 
	"混沌法宝碎片": {"name": "混沌法宝碎片", "type": "material", "rarity": "epic", "desc": "仅1000级及以上野外地图、混沌难度掉落，100片可合成混沌法宝。", "drop_rate": 0}, 
	"无上法宝碎片": {"name": "无上法宝碎片", "type": "material", "rarity": "legendary", "desc": "仅1000级及以上野外地图、无上难度掉落，100片可合成无上法宝。", "drop_rate": 0}, 
	"2026纪念法宝碎片": {"name": "2026纪念法宝碎片", "type": "material", "rarity": "legendary", "desc": "仅元宝抽奖获得，100片可合成2026纪念法宝。", "drop_rate": 0}, 
	"法宝洗练石": {"name": "法宝洗练石", "type": "material", "rarity": "rare", "desc": "用于洗练未穿戴法宝的词条数值（种类不变）。商店街友情点商店可购买。", "drop_rate": 0}, 
	"法宝重置石": {"name": "法宝重置石", "type": "material", "rarity": "rare", "desc": "用于重置未穿戴法宝的未锁定词条种类（锁定条不动，词条不重复）。由邮件发放。", "drop_rate": 0}, 
	"宠装强化石": {"name": "宠装强化石", "type": "material", "rarity": "rare", "desc": "在打造坊宠装强化中使用，可为任意宠物装备提升强化等级（最高+9）", "drop_rate": 0}, 

	"火之精华": {"name": "火之精华", "type": "material", "rarity": "uncommon", "desc": "蕴含火元素力量的精华", "drop_rate": 0}, 
	"火之灵石": {"name": "火之灵石", "type": "material", "rarity": "rare", "desc": "蕴含强大火元素力量的灵石", "drop_rate": 0}, 
	"水之精华": {"name": "水之精华", "type": "material", "rarity": "uncommon", "desc": "蕴含水元素力量的精华", "drop_rate": 0}, 
	"水之灵石": {"name": "水之灵石", "type": "material", "rarity": "rare", "desc": "蕴含强大水元素力量的灵石", "drop_rate": 0}, 
	"风之精华": {"name": "风之精华", "type": "material", "rarity": "uncommon", "desc": "蕴含风元素力量的精华", "drop_rate": 0}, 
	"风之灵石": {"name": "风之灵石", "type": "material", "rarity": "rare", "desc": "蕴含强大风元素力量的灵石", "drop_rate": 0}, 
	"土之精华": {"name": "土之精华", "type": "material", "rarity": "uncommon", "desc": "蕴含土元素力量的精华", "drop_rate": 0}, 
	"土之灵石": {"name": "土之灵石", "type": "material", "rarity": "rare", "desc": "蕴含强大土元素力量的灵石", "drop_rate": 0}, 
	"金之精华": {"name": "金之精华", "type": "material", "rarity": "uncommon", "desc": "蕴含金元素力量的精华", "drop_rate": 0}, 
	"金之灵石": {"name": "金之灵石", "type": "material", "rarity": "rare", "desc": "蕴含强大金元素力量的灵石", "drop_rate": 0}, 



	"普通解封石": {"name": "普通解封石", "type": "material", "rarity": "rare", "desc": "可用于解封1-10层的封印套装；10颗可合成1颗高级解封石", "drop_rate": 0}, 
	"高级解封石": {"name": "高级解封石", "type": "material", "rarity": "epic", "desc": "可用于解封11-21层的封印套装", "drop_rate": 0}, 


	"火属性宠物蛋": {"name": "火属性宠物蛋", "type": "pet_egg", "rarity": "epic", "desc": "五行属性宠物蛋之一，打开随机获得火属性宠物，成长约4.0～7.0", "drop_rate": 0}, 
	"水属性宠物蛋": {"name": "水属性宠物蛋", "type": "pet_egg", "rarity": "epic", "desc": "五行属性宠物蛋之一，打开随机获得水属性宠物，成长约4.0～7.0", "drop_rate": 0}, 
	"木属性宠物蛋": {"name": "木属性宠物蛋", "type": "pet_egg", "rarity": "epic", "desc": "五行属性宠物蛋之一，打开随机获得木属性宠物，成长约4.0～7.0", "drop_rate": 0}, 
	"金属性宠物蛋": {"name": "金属性宠物蛋", "type": "pet_egg", "rarity": "epic", "desc": "五行属性宠物蛋之一，打开随机获得金属性宠物，成长约4.0～7.0", "drop_rate": 0}, 
	"土属性宠物蛋": {"name": "土属性宠物蛋", "type": "pet_egg", "rarity": "epic", "desc": "五行属性宠物蛋之一，打开随机获得土属性宠物，成长约4.0～7.0", "drop_rate": 0}, 
	"金变异宠物蛋": {"name": "金变异宠物蛋", "type": "pet_egg", "rarity": "legendary", "desc": "打开获得一只1级0代变异1金属性宠物，成长约6.0～7.9（不含活动限定/BOSS等特殊宠）", "drop_rate": 0}, 
	"木变异宠物蛋": {"name": "木变异宠物蛋", "type": "pet_egg", "rarity": "legendary", "desc": "打开获得一只1级0代变异1木属性宠物，成长约6.0～7.9（不含活动限定/BOSS等特殊宠）", "drop_rate": 0}, 
	"水变异宠物蛋": {"name": "水变异宠物蛋", "type": "pet_egg", "rarity": "legendary", "desc": "打开获得一只1级0代变异1水属性宠物，成长约6.0～7.9（不含活动限定/BOSS等特殊宠）", "drop_rate": 0}, 
	"火变异宠物蛋": {"name": "火变异宠物蛋", "type": "pet_egg", "rarity": "legendary", "desc": "打开获得一只1级0代变异1火属性宠物，成长约6.0～7.9（不含活动限定/BOSS等特殊宠）", "drop_rate": 0}, 
	"土变异宠物蛋": {"name": "土变异宠物蛋", "type": "pet_egg", "rarity": "legendary", "desc": "打开获得一只1级0代变异1土属性宠物，成长约6.0～7.9（不含活动限定/BOSS等特殊宠）", "drop_rate": 0}, 


	"溅墨lv1技能书": {"name": "溅墨lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习溅墨lv1技能，攻击时50%概率额外打击1个目标，溅射伤害为80%", "drop_rate": 0}, 
	"溅墨lv2技能书": {"name": "溅墨lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习溅墨lv2技能，攻击时必定额外打击1个目标，溅射伤害为100%", "drop_rate": 0}, 
	"溅墨lv3技能书": {"name": "溅墨lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习溅墨lv3技能，攻击时必定共打击3个目标，溅射伤害为100%", "drop_rate": 0}, 
	"连击lv1技能书": {"name": "连击lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习连击lv1技能，攻击时20%概率连打3下，每下伤害60%", "drop_rate": 0}, 
	"连击lv2技能书": {"name": "连击lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习连击lv2技能，攻击时30%概率连打3下，每下伤害80%", "drop_rate": 0}, 
	"连击lv3技能书": {"name": "连击lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习连击lv3技能，攻击时50%概率连打3下，每下伤害100%", "drop_rate": 0}, 
	"护主lv1技能书": {"name": "护主lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习护主lv1技能，被击败时20%概率复活并恢复50%生命，每场最多5次", "drop_rate": 0}, 
	"护主lv2技能书": {"name": "护主lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习护主lv2技能，被击败时30%概率复活并恢复50%生命，每场最多5次", "drop_rate": 0}, 
	"护主lv3技能书": {"name": "护主lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习护主lv3技能，被击败时50%概率复活并恢复100%生命，每场最多5次", "drop_rate": 0}, 
	"反打lv1技能书": {"name": "反打lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习反打lv1技能，被攻击时（打中或闪避）20%概率反击，伤害为50%", "drop_rate": 0}, 
	"反打lv2技能书": {"name": "反打lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习反打lv2技能，被攻击时（打中或闪避）30%概率反击，伤害为80%", "drop_rate": 0}, 
	"反打lv3技能书": {"name": "反打lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习反打lv3技能，被攻击时（打中或闪避）50%概率反击，伤害为100%", "drop_rate": 0}, 

	"硬皮lv1技能书": {"name": "硬皮lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习硬皮lv1技能，提升宠物基础防御70%", "drop_rate": 0}, 
	"硬皮lv2技能书": {"name": "硬皮lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习硬皮lv2技能，提升宠物基础防御140%", "drop_rate": 0}, 
	"硬皮lv3技能书": {"name": "硬皮lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习硬皮lv3技能，提升宠物基础防御210%", "drop_rate": 0}, 
	"饮血lv1技能书": {"name": "饮血lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习饮血lv1技能，出手后10%概率按本下总伤害的10%回血", "drop_rate": 0}, 
	"饮血lv2技能书": {"name": "饮血lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习饮血lv2技能，出手后20%概率按本下总伤害的15%回血", "drop_rate": 0}, 
	"饮血lv3技能书": {"name": "饮血lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习饮血lv3技能，出手后30%概率按本下总伤害的20%回血", "drop_rate": 0}, 
	"溅墨lv4技能书": {"name": "溅墨lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习溅墨lv4技能，攻击时必定共打击4个目标，溅射伤害为100%", "drop_rate": 0}, 
	"溅墨lv5技能书": {"name": "溅墨lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习溅墨lv5技能，攻击时必定共打击5个目标，溅射伤害为100%", "drop_rate": 0}, 
	"连击lv4技能书": {"name": "连击lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习连击lv4技能，攻击时60%概率连打3下，每下伤害100%", "drop_rate": 0}, 
	"连击lv5技能书": {"name": "连击lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习连击lv5技能，攻击时70%概率连打4下，每下伤害100%", "drop_rate": 0}, 
	"护主lv4技能书": {"name": "护主lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习护主lv4技能，被击败时60%概率复活并恢复100%生命，每场最多5次", "drop_rate": 0}, 
	"护主lv5技能书": {"name": "护主lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习护主lv5技能，被击败时70%概率复活并恢复100%生命，每场最多6次", "drop_rate": 0}, 
	"反打lv4技能书": {"name": "反打lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习反打lv4技能，被攻击时（打中或闪避）60%概率反击，伤害为100%", "drop_rate": 0}, 
	"反打lv5技能书": {"name": "反打lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习反打lv5技能，被攻击时（打中或闪避）70%概率反击，伤害为120%", "drop_rate": 0}, 
	"硬皮lv4技能书": {"name": "硬皮lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习硬皮lv4技能，提升宠物基础防御230%", "drop_rate": 0}, 
	"硬皮lv5技能书": {"name": "硬皮lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习硬皮lv5技能，提升宠物基础防御250%", "drop_rate": 0}, 
	"饮血lv4技能书": {"name": "饮血lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习饮血lv4技能，出手后40%概率按本下总伤害的25%回血", "drop_rate": 0}, 
	"饮血lv5技能书": {"name": "饮血lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习饮血lv5技能，出手后50%概率按本下总伤害的30%回血", "drop_rate": 0}, 
	"轻身lv1技能书": {"name": "轻身lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习轻身lv1技能，提升宠物基础敏捷5%", "drop_rate": 0}, 
	"轻身lv2技能书": {"name": "轻身lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习轻身lv2技能，提升宠物基础敏捷10%", "drop_rate": 0}, 
	"轻身lv3技能书": {"name": "轻身lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习轻身lv3技能，提升宠物基础敏捷15%", "drop_rate": 0}, 
	"轻身lv4技能书": {"name": "轻身lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习轻身lv4技能，提升宠物基础敏捷20%", "drop_rate": 0}, 
	"轻身lv5技能书": {"name": "轻身lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习轻身lv5技能，提升宠物基础敏捷25%", "drop_rate": 0}, 
	"长命lv1技能书": {"name": "长命lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习长命lv1技能，提升宠物基础生命5%", "drop_rate": 0}, 
	"长命lv2技能书": {"name": "长命lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习长命lv2技能，提升宠物基础生命10%", "drop_rate": 0}, 
	"长命lv3技能书": {"name": "长命lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习长命lv3技能，提升宠物基础生命15%", "drop_rate": 0}, 
	"长命lv4技能书": {"name": "长命lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习长命lv4技能，提升宠物基础生命20%", "drop_rate": 0}, 
	"长命lv5技能书": {"name": "长命lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习长命lv5技能，提升宠物基础生命25%", "drop_rate": 0}, 
	"力壮lv1技能书": {"name": "力壮lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习力壮lv1技能，提升宠物基础攻击5%", "drop_rate": 0}, 
	"力壮lv2技能书": {"name": "力壮lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习力壮lv2技能，提升宠物基础攻击10%", "drop_rate": 0}, 
	"力壮lv3技能书": {"name": "力壮lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习力壮lv3技能，提升宠物基础攻击15%", "drop_rate": 0}, 
	"力壮lv4技能书": {"name": "力壮lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习力壮lv4技能，提升宠物基础攻击20%", "drop_rate": 0}, 
	"力壮lv5技能书": {"name": "力壮lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习力壮lv5技能，提升宠物基础攻击25%", "drop_rate": 0}, 
	"凶性lv1技能书": {"name": "凶性lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习凶性lv1技能，提升暴击伤害5%", "drop_rate": 0}, 
	"凶性lv2技能书": {"name": "凶性lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习凶性lv2技能，提升暴击伤害10%", "drop_rate": 0}, 
	"凶性lv3技能书": {"name": "凶性lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习凶性lv3技能，提升暴击伤害15%", "drop_rate": 0}, 
	"凶性lv4技能书": {"name": "凶性lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习凶性lv4技能，提升暴击伤害20%", "drop_rate": 0}, 
	"凶性lv5技能书": {"name": "凶性lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习凶性lv5技能，提升暴击伤害25%", "drop_rate": 0}, 
	"致命lv1技能书": {"name": "致命lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习致命lv1技能，提升暴击率5%", "drop_rate": 0}, 
	"致命lv2技能书": {"name": "致命lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习致命lv2技能，提升暴击率10%", "drop_rate": 0}, 
	"致命lv3技能书": {"name": "致命lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习致命lv3技能，提升暴击率15%", "drop_rate": 0}, 
	"致命lv4技能书": {"name": "致命lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习致命lv4技能，提升暴击率20%", "drop_rate": 0}, 
	"致命lv5技能书": {"name": "致命lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习致命lv5技能，提升暴击率25%", "drop_rate": 0}, 
	"自复lv1技能书": {"name": "自复lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习自复lv1技能，每回合结束回复生命上限的5%", "drop_rate": 0}, 
	"自复lv2技能书": {"name": "自复lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习自复lv2技能，每回合结束回复生命上限的10%", "drop_rate": 0}, 
	"自复lv3技能书": {"name": "自复lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习自复lv3技能，每回合结束回复生命上限的15%", "drop_rate": 0}, 
	"自复lv4技能书": {"name": "自复lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习自复lv4技能，每回合结束回复生命上限的20%", "drop_rate": 0}, 
	"自复lv5技能书": {"name": "自复lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习自复lv5技能，每回合结束回复生命上限的25%", "drop_rate": 0}, 
	"追杀lv1技能书": {"name": "追杀lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习追杀lv1技能，击杀后40%概率对另一目标追击，伤害为100%", "drop_rate": 0}, 
	"追杀lv2技能书": {"name": "追杀lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习追杀lv2技能，击杀后70%概率对另一目标追击，伤害为100%", "drop_rate": 0}, 
	"追杀lv3技能书": {"name": "追杀lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习追杀lv3技能，击杀后80%概率对另一目标追击，伤害为100%", "drop_rate": 0}, 
	"追杀lv4技能书": {"name": "追杀lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习追杀lv4技能，击杀后90%概率对另一目标追击，伤害为100%", "drop_rate": 0}, 
	"追杀lv5技能书": {"name": "追杀lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习追杀lv5技能，击杀后必定对另一目标追击，伤害为100%", "drop_rate": 0}, 
	"守主lv1技能书": {"name": "守主lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习守主lv1技能，主人被打时5%概率替主人承受攻击", "drop_rate": 0}, 
	"守主lv2技能书": {"name": "守主lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习守主lv2技能，主人被打时10%概率替主人承受攻击", "drop_rate": 0}, 
	"守主lv3技能书": {"name": "守主lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习守主lv3技能，主人被打时15%概率替主人承受攻击", "drop_rate": 0}, 
	"守主lv4技能书": {"name": "守主lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习守主lv4技能，主人被打时20%概率替主人承受攻击", "drop_rate": 0}, 
	"守主lv5技能书": {"name": "守主lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习守主lv5技能，主人被打时25%概率替主人承受攻击", "drop_rate": 0}, 
	"挑衅lv1技能书": {"name": "挑衅lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习挑衅lv1技能，每回合20%概率吸引敌人攻击自己", "drop_rate": 0}, 
	"挑衅lv2技能书": {"name": "挑衅lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习挑衅lv2技能，每回合40%概率吸引敌人攻击自己", "drop_rate": 0}, 
	"挑衅lv3技能书": {"name": "挑衅lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挑衅lv3技能，每回合60%概率吸引敌人攻击自己", "drop_rate": 0}, 
	"挑衅lv4技能书": {"name": "挑衅lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挑衅lv4技能，每回合80%概率吸引敌人攻击自己", "drop_rate": 0}, 
	"挑衅lv5技能书": {"name": "挑衅lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挑衅lv5技能，每回合必定吸引敌人攻击自己", "drop_rate": 0}, 
	"破防lv1技能书": {"name": "破防lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习破防lv1技能，攻击时1%概率忽视目标一半防御", "drop_rate": 0}, 
	"破防lv2技能书": {"name": "破防lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习破防lv2技能，攻击时2%概率忽视目标一半防御", "drop_rate": 0}, 
	"破防lv3技能书": {"name": "破防lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习破防lv3技能，攻击时3%概率忽视目标一半防御", "drop_rate": 0}, 
	"破防lv4技能书": {"name": "破防lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习破防lv4技能，攻击时4%概率忽视目标一半防御", "drop_rate": 0}, 
	"破防lv5技能书": {"name": "破防lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习破防lv5技能，攻击时5%概率忽视目标一半防御", "drop_rate": 0}, 
	"挡伤lv1技能书": {"name": "挡伤lv1技能书", "type": "pet_skill_book", "rarity": "rare", "desc": "宠物技能书，可学习挡伤lv1技能，受击时10%概率再减伤50%", "drop_rate": 0}, 
	"挡伤lv2技能书": {"name": "挡伤lv2技能书", "type": "pet_skill_book", "rarity": "epic", "desc": "宠物技能书，可学习挡伤lv2技能，受击时20%概率再减伤60%", "drop_rate": 0}, 
	"挡伤lv3技能书": {"name": "挡伤lv3技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挡伤lv3技能，受击时30%概率再减伤70%", "drop_rate": 0}, 
	"挡伤lv4技能书": {"name": "挡伤lv4技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挡伤lv4技能，受击时40%概率再减伤80%", "drop_rate": 0}, 
	"挡伤lv5技能书": {"name": "挡伤lv5技能书", "type": "pet_skill_book", "rarity": "legendary", "desc": "宠物技能书，可学习挡伤lv5技能，受击时50%概率再减伤90%", "drop_rate": 0}, 
}


const CRAFTING_RECIPES = {
	"common_weapon": {"name": "普通武器", "type": "equipment", "slot": "weapon", "rarity": "common", "materials": {"玄铁": 3, "精铁": 2}, "realm_req": "凡人", "success_rate": 0.9}, 
	"common_armor": {"name": "普通衣服", "type": "equipment", "slot": "armor", "rarity": "common", "materials": {"玄铁": 2, "精铁": 3}, "realm_req": "凡人", "success_rate": 0.9}, 
	"common_helmet": {"name": "普通帽子", "type": "equipment", "slot": "helmet", "rarity": "common", "materials": {"玄铁": 2, "精铁": 2}, "realm_req": "凡人", "success_rate": 0.9}, 
	"common_boots": {"name": "普通鞋子", "type": "equipment", "slot": "boots", "rarity": "common", "materials": {"玄铁": 2, "精铁": 2}, "realm_req": "凡人", "success_rate": 0.9}, 
	"common_accessory": {"name": "普通饰品", "type": "equipment", "slot": "accessory", "rarity": "common", "materials": {"精铁": 3, "灵木": 2}, "realm_req": "凡人", "success_rate": 0.9}, 
	"uncommon_weapon": {"name": "优秀武器", "type": "equipment", "slot": "weapon", "rarity": "uncommon", "materials": {"玄铁": 5, "寒冰精": 1, "烈火石": 1}, "realm_req": "凡人", "success_rate": 0.8}, 
	"uncommon_armor": {"name": "优秀衣服", "type": "equipment", "slot": "armor", "rarity": "uncommon", "materials": {"玄铁": 5, "金刚石": 1, "灵木": 2}, "realm_req": "凡人", "success_rate": 0.8}, 
	"uncommon_helmet": {"name": "优秀帽子", "type": "equipment", "slot": "helmet", "rarity": "uncommon", "materials": {"玄铁": 4, "金刚石": 1, "灵木": 1}, "realm_req": "凡人", "success_rate": 0.8}, 
	"uncommon_boots": {"name": "优秀鞋子", "type": "equipment", "slot": "boots", "rarity": "uncommon", "materials": {"玄铁": 4, "寒冰精": 1, "灵木": 1}, "realm_req": "凡人", "success_rate": 0.8}, 
	"uncommon_accessory": {"name": "优秀饰品", "type": "equipment", "slot": "accessory", "rarity": "uncommon", "materials": {"金刚石": 2, "灵木": 3, "寒冰精": 1}, "realm_req": "凡人", "success_rate": 0.8}, 
	"rare_weapon": {"name": "稀有武器", "type": "equipment", "slot": "weapon", "rarity": "rare", "materials": {"寒冰精": 3, "烈火石": 3, "天雷石": 1}, "realm_req": "散仙", "success_rate": 0.6}, 
	"rare_armor": {"name": "稀有衣服", "type": "equipment", "slot": "armor", "rarity": "rare", "materials": {"金刚石": 3, "星辰砂": 2, "天雷石": 1}, "realm_req": "散仙", "success_rate": 0.6}, 
	"rare_helmet": {"name": "稀有帽子", "type": "equipment", "slot": "helmet", "rarity": "rare", "materials": {"金刚石": 2, "天雷石": 1, "星辰砂": 1}, "realm_req": "散仙", "success_rate": 0.6}, 
	"rare_boots": {"name": "稀有鞋子", "type": "equipment", "slot": "boots", "rarity": "rare", "materials": {"寒冰精": 2, "天雷石": 1, "星辰砂": 1}, "realm_req": "散仙", "success_rate": 0.6}, 
	"rare_accessory": {"name": "稀有饰品", "type": "equipment", "slot": "accessory", "rarity": "rare", "materials": {"天雷石": 2, "星辰砂": 2, "灵木": 3}, "realm_req": "散仙", "success_rate": 0.6}, 
	"epic_weapon": {"name": "史诗武器", "type": "equipment", "slot": "weapon", "rarity": "epic", "materials": {"天雷石": 3, "星辰砂": 2, "龙鳞": 1}, "realm_req": "地仙", "success_rate": 0.4}, 
	"epic_armor": {"name": "史诗衣服", "type": "equipment", "slot": "armor", "rarity": "epic", "materials": {"星辰砂": 3, "龙鳞": 1, "凤羽": 1}, "realm_req": "地仙", "success_rate": 0.4}, 
	"epic_helmet": {"name": "史诗帽子", "type": "equipment", "slot": "helmet", "rarity": "epic", "materials": {"天雷石": 2, "龙鳞": 1, "凤羽": 1}, "realm_req": "地仙", "success_rate": 0.4}, 
	"epic_boots": {"name": "史诗鞋子", "type": "equipment", "slot": "boots", "rarity": "epic", "materials": {"星辰砂": 2, "龙鳞": 1, "凤羽": 1}, "realm_req": "地仙", "success_rate": 0.4}, 
	"epic_accessory": {"name": "史诗饰品", "type": "equipment", "slot": "accessory", "rarity": "epic", "materials": {"龙鳞": 2, "凤羽": 2, "星辰砂": 3}, "realm_req": "地仙", "success_rate": 0.4}, 
	"legendary_weapon": {"name": "传说武器", "type": "equipment", "slot": "weapon", "rarity": "legendary", "materials": {"龙鳞": 3, "凤羽": 2, "混沌石": 1}, "realm_req": "天仙", "success_rate": 0.2}, 
	"legendary_armor": {"name": "传说衣服", "type": "equipment", "slot": "armor", "rarity": "legendary", "materials": {"凤羽": 3, "混沌石": 1, "仙晶": 1}, "realm_req": "天仙", "success_rate": 0.2}, 
	"legendary_helmet": {"name": "传说帽子", "type": "equipment", "slot": "helmet", "rarity": "legendary", "materials": {"龙鳞": 2, "混沌石": 1, "仙晶": 1}, "realm_req": "天仙", "success_rate": 0.2}, 
	"legendary_boots": {"name": "传说鞋子", "type": "equipment", "slot": "boots", "rarity": "legendary", "materials": {"凤羽": 2, "混沌石": 1, "仙晶": 1}, "realm_req": "天仙", "success_rate": 0.2}, 
	"legendary_accessory": {"name": "传说饰品", "type": "equipment", "slot": "accessory", "rarity": "legendary", "materials": {"混沌石": 2, "仙晶": 2, "龙鳞": 2}, "realm_req": "天仙", "success_rate": 0.2}, 
	"juling_pill": {"name": "聚灵丹", "type": "cultivation_pill", "result": "聚灵丹", "materials": {"灵草": 5, "灵芝": 1}, "realm_req": "凡人", "success_rate": 0.9}, 
	"ningshen_pill": {"name": "凝神丹", "type": "cultivation_pill", "result": "凝神丹", "materials": {"灵芝": 3, "天山雪莲": 1}, "realm_req": "散仙", "success_rate": 0.9}, 
	"wudao_pill": {"name": "悟道仙丹", "type": "cultivation_pill", "result": "悟道仙丹", "materials": {"天山雪莲": 3, "九转还魂草": 1, "龙涎草": 1}, "realm_req": "地仙", "success_rate": 0.9}, 
}


static var _player_level_exp_runtime: Dictionary = {}

static func apply_player_level_exp_config(cfg: Dictionary) -> void :
	if cfg.is_empty():
		_player_level_exp_runtime = {}
		print("[GameData] playerLevelExp runtime 已清空，使用本地默认 1.7×L²")
		return
	_player_level_exp_runtime = cfg.duplicate(true)
	print("[GameData] playerLevelExp runtime: enabled=%s break=%s base=%s growth=%s" % [
		str(_player_level_exp_runtime.get("enabled", false)), 
		str(_player_level_exp_runtime.get("breakLevel", 500)), 
		str(_player_level_exp_runtime.get("postBreakBase", 0)), 
		str(_player_level_exp_runtime.get("postBreakGrowthCoeff", 0)), 
	])

static func _compute_required_exp_raw(level: int) -> int:
	var lv: = maxi(1, level)
	var enabled: = bool(_player_level_exp_runtime.get("enabled", false))
	var break_lv: = maxi(1, int(_player_level_exp_runtime.get("breakLevel", 500)))
	var pre_coeff: = float(_player_level_exp_runtime.get("preBreakCoeff", 1.7))
	var post_base: = maxi(0, int(_player_level_exp_runtime.get("postBreakBase", 0)))
	var post_growth: = float(_player_level_exp_runtime.get("postBreakGrowthCoeff", 4.6))
	if not enabled or lv < break_lv:
		return int(pre_coeff * pow(float(lv), 2.0))
	var delta: = lv - break_lv
	return int(float(post_base) + post_growth * pow(float(delta), 2.0))

static func get_required_exp(level: int) -> int:
	if level < 1:
		return 0
	var lv: = level
	if lv > MAX_LEVEL_EVOLUTION:
		lv = MAX_LEVEL_EVOLUTION
	if _player_level_exp_runtime.is_empty():
		return int(1.7 * pow(float(lv), 2.0))
	return _compute_required_exp_raw(lv)


static func get_pet_required_exp(level: int) -> int:
	var lv: = maxi(1, level)
	if _player_level_exp_runtime.is_empty():
		return int(1.7 * pow(float(lv), 2.0))
	return _compute_required_exp_raw(lv)


static func calculate_damage_with_element(base_damage: int, attacker_element: String, defender_element: String, attacker_uses_evolution_pet_element_rate: bool = true) -> Dictionary:
	var result = {"damage": base_damage, "message": ""}
	var atk: = str(attacker_element).strip_edges()
	var deff: = str(defender_element).strip_edges()

	if atk == "普通" or deff == "普通":
		return result

	if atk == ELEMENT_SKY and deff == ELEMENT_SKY:
		return result

	var is_advantage: = false
	var is_disadvantage: = false
	if atk == ELEMENT_SKY and deff in FIVE_ELEMENTS:
		is_advantage = true
	elif deff == ELEMENT_SKY and atk in FIVE_ELEMENTS:
		is_disadvantage = true
	elif ELEMENT_COUNTER.get(atk) == deff:
		is_advantage = true
	elif ELEMENT_COUNTER.get(deff) == atk:
		is_disadvantage = true

	if is_advantage:
		if attacker_uses_evolution_pet_element_rate:
			result.damage = int(base_damage * 1.3)
			result.message = "%s克%s，伤害提升30%%！" % [atk, deff]
		else:
			result.damage = int(base_damage * 1.5)
			result.message = "%s克%s，伤害提升50%%！" % [atk, deff]
	elif is_disadvantage:
		if attacker_uses_evolution_pet_element_rate:
			result.damage = int(base_damage * 0.7)
			result.message = "%s被%s克，伤害降低30%%！" % [atk, deff]
		else:
			result.damage = int(base_damage * 0.5)
			result.message = "%s被%s克，伤害降低50%%！" % [atk, deff]

	return result

static func get_element_relation_label(attacker_element: String, defender_element: String) -> String:
	var atk: = str(attacker_element).strip_edges()
	var deff: = str(defender_element).strip_edges()
	if atk == "普通" or deff == "普通":
		return ""
	if atk == ELEMENT_SKY and deff == ELEMENT_SKY:
		return ""
	if atk == ELEMENT_SKY and deff in FIVE_ELEMENTS:
		return "相克"
	if deff == ELEMENT_SKY and atk in FIVE_ELEMENTS:
		return "被克"
	if ELEMENT_COUNTER.get(atk) == deff:
		return "相克"
	if ELEMENT_COUNTER.get(deff) == atk:
		return "被克"
	return ""

static func can_ascend(current_realm: String, current_level: int, element_collection: Dictionary = {}) -> Dictionary:
	var result = {"can_ascend": false, "reason": "", "missing_elements": []}

	if current_realm not in ASCENSION_CONDITIONS:
		result.reason = "未知境界"
		return result

	var required_level = ASCENSION_CONDITIONS[current_realm].required_level
	if current_level < required_level:
		result.reason = "等级不足，需要达到%d级才能飞升！" % required_level
		return result

	var next_realm = get_next_realm(current_realm)
	if next_realm == "大罗金仙":
		var required_count = 10
		var missing = []
		for element in ["金", "木", "水", "火", "土"]:
			var count = element_collection.get(element, 0)
			if count < required_count:
				missing.append({"element": element, "current": count, "required": required_count})

		if missing.size() > 0:
			result.reason = "五行图鉴不足"
			result.missing_elements = missing
			return result

	result.can_ascend = true
	return result

static func get_next_realm(current_realm: String) -> String:
	if current_realm in ASCENSION_CONDITIONS:
		return ASCENSION_CONDITIONS[current_realm].next_realm
	return ""

static func is_max_realm(current_realm: String) -> bool:
	return current_realm == "幻灵天神"

static var _drop_rate_overrides: Dictionary = {}

static var _runtime_item_defs: Dictionary = {}

static var _festival_gift_item_defs: Dictionary = {}

static func clear_runtime_item_defs() -> void :
	_runtime_item_defs.clear()

static func apply_pet_open_item_defs(items: Array) -> int:
	clear_runtime_item_defs()
	var applied: = 0
	for row_v in items:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v
		var item_name: = str(row.get("itemName", row.get("name", ""))).strip_edges()
		if item_name.is_empty():
			continue
		var item_type: = str(row.get("type", "")).strip_edges()
		if item_type.is_empty():
			var route: = str(row.get("route", "open-pet")).strip_edges()
			item_type = "pet_egg" if route == "open-egg" else "gift"
		var rarity: = str(row.get("rarity", "rare")).strip_edges()
		if rarity.is_empty():
			rarity = "rare"
		var desc: = str(row.get("desc", "")).strip_edges()
		if desc.is_empty():
			desc = "打开获得一只宠物"
		_runtime_item_defs[item_name] = {
			"name": item_name, 
			"type": item_type, 
			"rarity": rarity, 
			"desc": desc, 
			"drop_rate": 0, 
		}
		applied += 1
	return applied

static func apply_festival_gift_item_defs(gift_names: Array) -> int:
	_festival_gift_item_defs.clear()
	var applied: = 0
	for name_v in gift_names:
		var item_name: = str(name_v).strip_edges()
		if item_name.is_empty():
			continue
		if ALL_ITEMS.has(item_name) or _runtime_item_defs.has(item_name):
			continue
		_festival_gift_item_defs[item_name] = {
			"name": item_name, 
			"type": "gift", 
			"rarity": "legendary", 
			"desc": "节日活动限定礼包，打开后随机获得节日奖励。", 
			"drop_rate": 0, 
		}
		applied += 1
	return applied

static func resolve_item_def(item_name: String) -> Variant:
	var n: = migrate_item_name(item_name)
	if n.is_empty():
		return null
	if _runtime_item_defs.has(n):
		return _runtime_item_defs[n]
	if _festival_gift_item_defs.has(n):
		return _festival_gift_item_defs[n]
	if ALL_ITEMS.has(n):
		return ALL_ITEMS[n]
	return null

static func apply_drop_config(server_rates: Dictionary) -> int:
	var applied: = 0
	if not server_rates is Dictionary:
		return 0
	for item_name in server_rates:
		if not ALL_ITEMS.has(item_name):
			continue
		var rate = float(server_rates[item_name])
		if rate < 0 or rate > 1:
			continue
		_drop_rate_overrides[item_name] = rate
		applied += 1
	print("[GameData] apply_drop_config: 覆盖了 %d 个物品的掉落率" % applied)
	return applied

static func get_item_drop_rate(item_name: String) -> float:
	if _drop_rate_overrides.has(item_name):
		return float(_drop_rate_overrides[item_name])
	if ALL_ITEMS.has(item_name):
		return float(ALL_ITEMS[item_name].get("drop_rate", 0))
	return 0.0
