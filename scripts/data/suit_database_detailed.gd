class_name SuitDatabaseDetailed
extends RefCounted





const SLOT_STAT_DISTRIBUTION = {
	"weapon": {"attack": 1.0, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
	"helmet": {"attack": 0, "defense": 0, "hp": 1.0, "mp": 0, "agility": 0}, 
	"armor": {"attack": 0, "defense": 1.0, "hp": 0, "mp": 0, "agility": 0}, 
	"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 1.0}, 
	"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 1.0, "agility": 0}
}


const SLOT_NAMES = {
	"weapon": "武器", 
	"helmet": "头盔", 
	"armor": "衣服", 
	"boots": "鞋子", 
	"accessory": "饰品"
}



const SUIT_DATA = {
	1: {
		"name": "青云套装", 
		"required_cultivation": 5000, 
		"base_stats": {"attack": 420, "defense": 420, "agility": 385, "hp": 770, "mp": 420}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "玄灵升级石", 
		"upgrade_gold": 10000, 
		"next_suit_id": 2, 
		"dungeon_element": "金", 
		"monster": {"attack": 290, "defense": 150, "hp": 2350, "agility": 87, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 420, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 770, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 420, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 385}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 420, "agility": 0}
		}
	}, 
	2: {
		"name": "玄灵套装", 
		"required_cultivation": 50000, 
		"base_stats": {"attack": 665, "defense": 595, "agility": 560, "hp": 1785, "mp": 595}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "玄灵升级石", 
		"upgrade_gold": 20000, 
		"next_suit_id": 3, 
		"dungeon_element": "木", 
		"monster": {"attack": 942, "defense": 466, "hp": 7330, "agility": 283, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 665, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 1785, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 595, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 560}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 595, "agility": 0}
		}
	}, 
	3: {
		"name": "地脉套装", 
		"required_cultivation": 100000, 
		"base_stats": {"attack": 875, "defense": 700, "agility": 630, "hp": 2048, "mp": 700}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "地脉升级石", 
		"upgrade_gold": 30000, 
		"next_suit_id": 4, 
		"dungeon_element": "水", 
		"monster": {"attack": 2200, "defense": 1100, "hp": 17600, "agility": 660, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 875, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 2048, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 700, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 630}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 700, "agility": 0}
		}
	}, 
	4: {
		"name": "天羽套装", 
		"required_cultivation": 150000, 
		"base_stats": {"attack": 1155, "defense": 840, "agility": 700, "hp": 3063, "mp": 840}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "天羽升级石", 
		"upgrade_gold": 40000, 
		"next_suit_id": 5, 
		"dungeon_element": "火", 
		"monster": {"attack": 3670, "defense": 1830, "hp": 29330, "agility": 1101, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 1155, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 3063, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 840, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 700}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 840, "agility": 0}
		}
	}, 
	5: {
		"name": "金罡套装", 
		"required_cultivation": 200000, 
		"base_stats": {"attack": 1645, "defense": 1085, "agility": 840, "hp": 4988, "mp": 1085}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "金罡升级石", 
		"upgrade_gold": 50000, 
		"next_suit_id": 6, 
		"dungeon_element": "土", 
		"monster": {"attack": 6450, "defense": 3230, "hp": 51330, "agility": 1935, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 1645, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 4988, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 1085, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 840}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 1085, "agility": 0}
		}
	}, 
	6: {
		"name": "大罗套装", 
		"required_cultivation": 250000, 
		"base_stats": {"attack": 2310, "defense": 1400, "agility": 1050, "hp": 6913, "mp": 1400}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "大罗升级石", 
		"upgrade_gold": 60000, 
		"next_suit_id": 7, 
		"dungeon_element": "金", 
		"monster": {"attack": 10270, "defense": 5130, "hp": 73330, "agility": 3081, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 2310, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 6913, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 1400, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 1050}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 1400, "agility": 0}
		}
	}, 
	7: {
		"name": "神威套装", 
		"required_cultivation": 300000, 
		"base_stats": {"attack": 3220, "defense": 1855, "agility": 1330, "hp": 10133, "mp": 1855}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "神威升级石", 
		"upgrade_gold": 70000, 
		"next_suit_id": 8, 
		"dungeon_element": "木", 
		"monster": {"attack": 15550, "defense": 7770, "hp": 110000, "agility": 4665, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 3220, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 10133, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 1855, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 1330}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 1855, "agility": 0}
		}
	}, 
	8: {
		"name": "至尊套装", 
		"required_cultivation": 350000, 
		"base_stats": {"attack": 4445, "defense": 2485, "agility": 1680, "hp": 13335, "mp": 2485}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "至尊升级石", 
		"upgrade_gold": 80000, 
		"next_suit_id": 9, 
		"dungeon_element": "水", 
		"monster": {"attack": 22590, "defense": 11290, "hp": 146670, "agility": 6777, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 4445, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 13335, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 2485, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 1680}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 2485, "agility": 0}
		}
	}, 
	9: {
		"name": "混沌套装", 
		"required_cultivation": 400000, 
		"base_stats": {"attack": 5635, "defense": 3080, "agility": 2065, "hp": 17833, "mp": 3080}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "混沌升级石", 
		"upgrade_gold": 90000, 
		"next_suit_id": 10, 
		"dungeon_element": "火", 
		"monster": {"attack": 29330, "defense": 14670, "hp": 198000, "agility": 8799, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 5635, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 17833, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 3080, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 2065}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 3080, "agility": 0}
		}
	}, 
	10: {
		"name": "无极套装", 
		"required_cultivation": 450000, 
		"base_stats": {"attack": 6685, "defense": 3605, "agility": 2345, "hp": 22313, "mp": 3605}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "无极升级石", 
		"upgrade_gold": 100000, 
		"next_suit_id": 11, 
		"dungeon_element": "土", 
		"monster": {"attack": 35200, "defense": 17600, "hp": 249330, "agility": 10560, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 6685, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 22313, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 3605, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 2345}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 3605, "agility": 0}
		}
	}, 
	11: {
		"name": "太虚套装", 
		"required_cultivation": 500000, 
		"base_stats": {"attack": 7700, "defense": 4095, "agility": 2660, "hp": 26163, "mp": 4095}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "太虚升级石", 
		"upgrade_gold": 110000, 
		"next_suit_id": 12, 
		"dungeon_element": "金", 
		"monster": {"attack": 41070, "defense": 20530, "hp": 293330, "agility": 12321, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 7700, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 26163, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 4095, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 2660}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 4095, "agility": 0}
		}
	}, 
	12: {
		"name": "玄黄套装", 
		"required_cultivation": 550000, 
		"base_stats": {"attack": 8995, "defense": 4760, "agility": 3045, "hp": 30660, "mp": 4760}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "鸿蒙升级石", 
		"upgrade_gold": 120000, 
		"next_suit_id": 13, 
		"dungeon_element": "木", 
		"monster": {"attack": 48400, "defense": 24200, "hp": 344670, "agility": 14520, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 8995, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 30660, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 4760, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 3045}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 4760, "agility": 0}
		}
	}, 
	13: {
		"name": "盘古套装", 
		"required_cultivation": 600000, 
		"base_stats": {"attack": 10255, "defense": 5390, "agility": 3430, "hp": 35158, "mp": 5390}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "盘古升级石", 
		"upgrade_gold": 130000, 
		"next_suit_id": 14, 
		"dungeon_element": "水", 
		"monster": {"attack": 55730, "defense": 27870, "hp": 396000, "agility": 16719, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 10255, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 35158, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 5390, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 3430}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 5390, "agility": 0}
		}
	}, 
	14: {
		"name": "女娲套装", 
		"required_cultivation": 650000, 
		"base_stats": {"attack": 11305, "defense": 5915, "agility": 3745, "hp": 39008, "mp": 5915}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "女娲升级石", 
		"upgrade_gold": 140000, 
		"next_suit_id": 15, 
		"dungeon_element": "火", 
		"monster": {"attack": 61600, "defense": 30800, "hp": 440000, "agility": 18480, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 11305, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 39008, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 5915, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 3745}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 5915, "agility": 0}
		}
	}, 
	15: {
		"name": "伏羲套装", 
		"required_cultivation": 700000, 
		"base_stats": {"attack": 12565, "defense": 6545, "agility": 4130, "hp": 45413, "mp": 6545}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "伏羲升级石", 
		"upgrade_gold": 150000, 
		"next_suit_id": 16, 
		"dungeon_element": "土", 
		"monster": {"attack": 68930, "defense": 34470, "hp": 513330, "agility": 20679, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 12565, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 45413, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 6545, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 4130}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 6545, "agility": 0}
		}
	}, 
	16: {
		"name": "轩辕套装", 
		"required_cultivation": 750000, 
		"base_stats": {"attack": 14385, "defense": 7455, "agility": 4655, "hp": 51835, "mp": 7455}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "轩辕升级石", 
		"upgrade_gold": 160000, 
		"next_suit_id": 17, 
		"dungeon_element": "金", 
		"monster": {"attack": 79200, "defense": 39600, "hp": 586670, "agility": 23760, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 14385, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 51835, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 7455, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 4655}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 7455, "agility": 0}
		}
	}, 
	17: {
		"name": "蚩尤套装", 
		"required_cultivation": 800000, 
		"base_stats": {"attack": 15925, "defense": 8225, "agility": 5145, "hp": 58258, "mp": 8225}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "蚩尤升级石", 
		"upgrade_gold": 170000, 
		"next_suit_id": 18, 
		"dungeon_element": "木", 
		"monster": {"attack": 88000, "defense": 44000, "hp": 660000, "agility": 26400, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 15925, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 58258, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 8225, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 5145}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 8225, "agility": 0}
		}
	}, 
	18: {
		"name": "刑天套装", 
		"required_cultivation": 850000, 
		"base_stats": {"attack": 17710, "defense": 9100, "agility": 5670, "hp": 64663, "mp": 9100}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "刑天升级石", 
		"upgrade_gold": 180000, 
		"next_suit_id": 19, 
		"dungeon_element": "水", 
		"monster": {"attack": 98270, "defense": 49130, "hp": 733330, "agility": 29481, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 17710, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 64663, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 9100, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 5670}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 9100, "agility": 0}
		}
	}, 
	19: {
		"name": "共工套装", 
		"required_cultivation": 900000, 
		"base_stats": {"attack": 19495, "defense": 10010, "agility": 6195, "hp": 71085, "mp": 10010}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "共工升级石", 
		"upgrade_gold": 190000, 
		"next_suit_id": 20, 
		"dungeon_element": "火", 
		"monster": {"attack": 108530, "defense": 54270, "hp": 806670, "agility": 32559, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 19495, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 71085, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 10010, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 6195}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 10010, "agility": 0}
		}
	}, 
	20: {
		"name": "永恒套装", 
		"required_cultivation": 950000, 
		"base_stats": {"attack": 22085, "defense": 11305, "agility": 6965, "hp": 77508, "mp": 11305}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "永恒升级石", 
		"upgrade_gold": 200000, 
		"next_suit_id": 21, 
		"dungeon_element": "土", 
		"monster": {"attack": 123200, "defense": 61600, "hp": 880000, "agility": 36960, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 22085, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 77508, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 11305, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 6965}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 11305, "agility": 0}
		}
	}, 
	21: {
		"name": "无上套装", 
		"required_cultivation": 1000000, 
		"base_stats": {"attack": 26000, "defense": 13500, "agility": 8300, "hp": 90000, "mp": 13500}, 
		"set_bonus_percent": 0.3, 
		"upgrade_item": "无上升级石", 
		"upgrade_gold": 210000, 
		"next_suit_id": 0, 
		"dungeon_element": "金", 
		"monster": {"attack": 73000, "defense": 37000, "hp": 510000, "agility": 21900, "count": 3}, 
		"piece_stats": {
			"weapon": {"attack": 26000, "defense": 0, "hp": 0, "mp": 0, "agility": 0}, 
			"helmet": {"attack": 0, "defense": 0, "hp": 90000, "mp": 0, "agility": 0}, 
			"armor": {"attack": 0, "defense": 13500, "hp": 0, "mp": 0, "agility": 0}, 
			"boots": {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 8300}, 
			"accessory": {"attack": 0, "defense": 0, "hp": 0, "mp": 13500, "agility": 0}
		}
	}
}


static func get_suit_data(suit_level: int) -> Dictionary:
	if SUIT_DATA.has(suit_level):
		return SUIT_DATA[suit_level]
	return {}


static func get_slot_name(slot: String) -> String:
	return SLOT_NAMES.get(slot, "未知部位")


static func get_piece_stats(suit_level: int, slot: String) -> Dictionary:
	var data = get_suit_data(suit_level)
	var piece_stats = data.get("piece_stats", {})
	return piece_stats.get(slot, {"attack": 0, "defense": 0, "hp": 0, "mp": 0, "agility": 0})


static func get_suit_name(suit_level: int) -> String:
	var data = get_suit_data(suit_level)
	return data.get("name", "未知套装")


static func get_base_stats(suit_level: int) -> Dictionary:
	var data = get_suit_data(suit_level)
	return data.get("base_stats", {})


static func get_set_bonus(suit_level: int) -> Dictionary:
	var data = get_suit_data(suit_level)
	var base_stats = data.get("base_stats", {})
	var bonus_percent = data.get("set_bonus_percent", 0.3)

	var bonus = {}
	for stat in base_stats.keys():
		bonus[stat] = int(base_stats[stat] * bonus_percent)
	return bonus


static func get_dungeon_element(suit_level: int) -> String:
	var data = get_suit_data(suit_level)
	return data.get("dungeon_element", "无")


static func get_dungeon_monster_data(suit_level: int) -> Dictionary:
	var data = get_suit_data(suit_level)
	return data.get("monster", {"attack": 100, "defense": 50, "hp": 500, "agility": 30, "count": 3})


static func get_required_cultivation(suit_level: int) -> int:
	var data = get_suit_data(suit_level)
	return data.get("required_cultivation", 0)


static func check_cultivation_requirement(suit_level: int, current_cultivation: int) -> bool:
	var required = get_required_cultivation(suit_level)
	return current_cultivation >= required


static func get_all_suit_levels() -> Array:
	return SUIT_DATA.keys()


static func get_suit_count() -> int:
	return SUIT_DATA.size()


static func get_all_slots() -> Array:
	return ["weapon", "helmet", "armor", "boots", "accessory"]


const SLOT_STATS = {
	"weapon": "attack", 
	"helmet": "hp", 
	"armor": "defense", 
	"boots": "agility", 
	"accessory": "mp"
}


static func get_slot_stat_name(slot: String) -> String:
	return SLOT_STATS.get(slot, "")


static func get_suit_piece_stats(suit_level: int, slot: String) -> int:
	var piece_stats = get_piece_stats(suit_level, slot)
	var stat_name = get_slot_stat_name(slot)
	return piece_stats.get(stat_name, 0)




const SEALED_STONES = {
	"normal": {
		"name": "解封石", 
		"description": "可用于解封1-10层的封印套装", 
		"min_level": 1, 
		"max_level": 10
	}, 
	"advanced": {
		"name": "高级解封石", 
		"description": "可用于解封11-21层的封印套装", 
		"min_level": 11, 
		"max_level": 21
	}
}


const UNSEAL_COST = {
	"gold": 10000000, 
	"success_rate": 0.5
}


const STAT_VARIATION = {
	"min": 0.9, 
	"max": 1.1
}


const DROP_CONFIG = {
	"sealed_suit_rate": 0.05, 
	"sealed_stone_rate": 0.05, 
	"slots": ["weapon", "helmet", "armor", "boots", "accessory"]
}


static func get_seal_stone_type(suit_level: int) -> String:
	if suit_level <= 10:
		return "normal"
	else:
		return "advanced"


static func get_seal_stone_name(suit_level: int) -> String:
	var stone_type = get_seal_stone_type(suit_level)
	return SEALED_STONES[stone_type]["name"]


static func can_use_seal_stone(stone_type: String, suit_level: int) -> bool:
	if not SEALED_STONES.has(stone_type):
		return false
	var stone_data = SEALED_STONES[stone_type]
	return suit_level >= stone_data["min_level"] and suit_level <= stone_data["max_level"]

static func get_sealed_suit_display_name(suit_level: int, slot: String) -> String:
	return "%s%s（封印）" % [get_suit_name(suit_level), get_slot_name(slot)]


static func generate_sealed_suit(suit_level: int, slot: String) -> Dictionary:
	var suit_data = get_suit_data(suit_level)
	var piece_stats = get_piece_stats(suit_level, slot)

	return {
		"name": get_sealed_suit_display_name(suit_level, slot), 
		"suit_level": suit_level, 
		"slot": slot, 
		"is_sealed": true, 
		"base_stats": piece_stats, 
		"element": suit_data.get("dungeon_element", "无")
	}


static func unseal_suit(sealed_suit: Dictionary) -> Dictionary:
	if not sealed_suit.get("is_sealed", false):
		return sealed_suit

	var result = sealed_suit.duplicate(true)
	result["is_sealed"] = false


	result["name"] = result["name"].replace("(封印)", "").replace("（封印）", "")


	var base_stats = result.get("base_stats", {})
	var varied_stats = {}
	for stat in base_stats.keys():
		var base_value = base_stats[stat]
		var variation = randf() * (STAT_VARIATION["max"] - STAT_VARIATION["min"]) + STAT_VARIATION["min"]
		varied_stats[stat] = int(base_value * variation)
	result["base_stats"] = varied_stats
	result["varied_stats"] = varied_stats
	return result


static func get_unseal_cost() -> Dictionary:
	return {
		"gold": UNSEAL_COST["gold"], 
		"success_rate": UNSEAL_COST["success_rate"]
	}
