class_name TitleData

var title_id: String = ""
var title_name: String = ""
var attack_bonus: int = 0
var defense_bonus: int = 0
var agility_bonus: int = 0
var hp_bonus: int = 0
var source: String = ""
var expire_time: int = 0
var week_number: int = 0

func to_dict() -> Dictionary:
	return {
		"title_id": title_id, 
		"title_name": title_name, 
		"attack_bonus": attack_bonus, 
		"defense_bonus": defense_bonus, 
		"agility_bonus": agility_bonus, 
		"hp_bonus": hp_bonus, 
		"source": source, 
		"expire_time": expire_time, 
		"week_number": week_number
	}

func from_dict(data: Dictionary):
	title_id = str(data.get("title_id", ""))
	title_name = data.get("title_name", "")
	attack_bonus = data.get("attack_bonus", 0)
	defense_bonus = data.get("defense_bonus", 0)
	agility_bonus = data.get("agility_bonus", 0)
	hp_bonus = data.get("hp_bonus", 0)
	source = data.get("source", "")
	var expire_raw = data.get("expire_time_unix", null)
	if expire_raw == null:
		expire_raw = data.get("expire_time", 0)
	expire_time = _coerce_expire_time_to_unix(expire_raw)
	week_number = data.get("week_number", 0)

static func _coerce_expire_time_to_unix(raw: Variant) -> int:
	if raw is int:
		return raw
	if raw is float:
		return int(raw)
	if raw is String:
		var s = raw.strip_edges()
		if s.is_empty():
			return 0
		var re = RegEx.new()
		re.compile("^(\\d{4})-(\\d{2})-(\\d{2})[ T](\\d{2}):(\\d{2}):(\\d{2})")
		var m = re.search(s)
		if m:
			var dt = {
				"year": int(m.get_string(1)), 
				"month": int(m.get_string(2)), 
				"day": int(m.get_string(3)), 
				"hour": int(m.get_string(4)), 
				"minute": int(m.get_string(5)), 
				"second": int(m.get_string(6)), 
			}
			return int(Time.get_unix_time_from_datetime_dict(dt))
		var iso = s.replace(" ", "T") if not s.contains("T") else s
		var u = Time.get_unix_time_from_datetime_string(iso)
		if u < 0.0 and not iso.ends_with("Z") and not ("+" in iso):
			u = Time.get_unix_time_from_datetime_string(iso + "Z")
		return int(u) if u >= 0.0 else 0
	return 0

func is_expired() -> bool:
	if expire_time == 0:
		return false
	return Time.get_unix_time_from_system() > expire_time

func get_remaining_time() -> int:
	if expire_time == 0:
		return -1
	var remaining = expire_time - int(Time.get_unix_time_from_system())
	return max(0, remaining)

func get_remaining_time_string() -> String:
	var remaining = get_remaining_time()
	if remaining < 0:
		return "永久"
	if remaining == 0:
		return "已过期"

	var days = remaining / 86400
	var hours = (remaining % 86400) / 3600
	var minutes = (remaining % 3600) / 60

	if days > 0:
		return "%d天%d小时" % [days, hours]
	elif hours > 0:
		return "%d小时%d分" % [hours, minutes]
	else:
		return "%d分钟" % minutes

func get_bonus(stat_type: String) -> int:
	match stat_type:
		"attack": return attack_bonus
		"defense": return defense_bonus
		"agility": return agility_bonus
		"hp": return hp_bonus
		_: return 0

static func create_xianmo_title(faction: String, rank: int, is_winner: bool, week_num: int):
	var title = TitleData.new()
	title.source = "xianmo"
	title.week_number = week_num
	title.expire_time = int(Time.get_unix_time_from_system()) + 604800

	var title_info = _get_title_info(faction, rank, is_winner)
	title.title_id = title_info.id
	title.title_name = title_info.name
	title.attack_bonus = title_info.attack
	title.defense_bonus = title_info.defense
	title.agility_bonus = title_info.agility
	title.hp_bonus = title_info.hp

	return title

static func _get_title_info(faction: String, rank: int, is_winner: bool) -> Dictionary:
	var titles = {
		"xian": {
			"winner": {
				1: {"id": "xian_zhizun", "name": "仙道至尊", "attack": 1000, "defense": 1000, "agility": 1000, "hp": 1000}, 
				2: {"id": "xian_shengzhe", "name": "仙道圣者", "attack": 800, "defense": 800, "agility": 800, "hp": 800}, 
				3: {"id": "xian_zhenren", "name": "仙道真人", "attack": 500, "defense": 500, "agility": 500, "hp": 500}
			}, 
			"loser": {
				1: {"id": "xian_xianfeng", "name": "仙道先锋", "attack": 800, "defense": 800, "agility": 800, "hp": 800}, 
				2: {"id": "xian_yongshi", "name": "仙道勇士", "attack": 500, "defense": 500, "agility": 500, "hp": 500}, 
				3: {"id": "xian_qiangzhe", "name": "仙道强者", "attack": 300, "defense": 300, "agility": 300, "hp": 300}
			}
		}, 
		"mo": {
			"winner": {
				1: {"id": "mo_bazhu", "name": "魔道霸主", "attack": 1000, "defense": 1000, "agility": 1000, "hp": 1000}, 
				2: {"id": "mo_tongling", "name": "魔道统领", "attack": 800, "defense": 800, "agility": 800, "hp": 800}, 
				3: {"id": "mo_mojiang", "name": "魔道魔将", "attack": 500, "defense": 500, "agility": 500, "hp": 500}
			}, 
			"loser": {
				1: {"id": "mo_xianfeng", "name": "魔道先锋", "attack": 800, "defense": 800, "agility": 800, "hp": 800}, 
				2: {"id": "mo_yongshi", "name": "魔道勇士", "attack": 500, "defense": 500, "agility": 500, "hp": 500}, 
				3: {"id": "mo_qiangzhe", "name": "魔道强者", "attack": 300, "defense": 300, "agility": 300, "hp": 300}
			}
		}
	}

	var result_type = "winner" if is_winner else "loser"
	if titles.has(faction) and titles[faction].has(result_type) and titles[faction][result_type].has(rank):
		return titles[faction][result_type][rank]

	return {"id": "", "name": "", "attack": 0, "defense": 0, "agility": 0, "hp": 0}
