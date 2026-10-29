class_name MailData
extends RefCounted

const GameData = preload("res://scripts/game_data.gd")


var id: int = 0


var title: String = ""


var content: String = ""


var sender: String = "系统"


var is_read: bool = false


var is_claimed: bool = false


var created_at: int = 0


var expire_at: int = 0


var attachments: Dictionary = {}

const TREASURE_TOKEN_TYPE: = "treasure_token"


static func from_server_data(data: Dictionary) -> MailData:
	var mail = MailData.new()
	mail.id = data.get("id", 0)
	mail.title = data.get("title", "")
	mail.content = data.get("content", "")
	mail.sender = data.get("sender", "系统")
	mail.is_read = data.get("is_read", false)
	mail.is_claimed = data.get("is_claimed", false)


	var created_raw = data.get("created_at", null)
	if created_raw != null:
		if typeof(created_raw) == TYPE_INT or typeof(created_raw) == TYPE_FLOAT:
			mail.created_at = int(created_raw)
		else:
			var created_str: = str(created_raw).strip_edges()
			if not created_str.is_empty():
				mail.created_at = _parse_datetime(created_str)

	var expire_raw = data.get("expire_at", null)
	if expire_raw != null:
		if typeof(expire_raw) == TYPE_INT or typeof(expire_raw) == TYPE_FLOAT:
			mail.expire_at = int(expire_raw)
		else:
			var expire_str: = str(expire_raw).strip_edges()
			if not expire_str.is_empty():
				mail.expire_at = _parse_datetime(expire_str)


	var attach_str = data.get("attachments", "")
	if attach_str and attach_str is String and not attach_str.is_empty():
		var json = JSON.new()
		var error = json.parse(attach_str)
		if error == OK:
			mail.attachments = _normalize_attachments(json.data)
		else:
			print("[MailData] 附件JSON解析失败: ", attach_str)
	elif data.get("attachments") is Dictionary:
		mail.attachments = _normalize_attachments(data.get("attachments"))
	elif data.get("attachments") is Array:
		mail.attachments = _normalize_attachments(data.get("attachments"))

	print("[MailData] 邮件解析完成: id=", mail.id, ", title=", mail.title, ", attachments=", mail.attachments)
	return mail


func has_expire_time() -> bool:
	return expire_at > 0


func is_expired() -> bool:
	if expire_at == 0:
		return false
	return Time.get_unix_time_from_system() > expire_at


func get_remaining_days() -> int:
	if expire_at == 0:
		return -1
	var remaining = expire_at - Time.get_unix_time_from_system()
	if remaining <= 0:
		return 0
	return int(remaining / 86400)


func has_attachments() -> bool:
	if attachments.is_empty():
		return false
	var has_gold = attachments.get("gold", 0) > 0
	var has_yuanbao = attachments.get("yuanbao", 0) > 0
	var has_exp = attachments.get("exp", 0) > 0
	var has_items = not attachments.get("items", []).is_empty()
	var has_pets = not attachments.get("pets", []).is_empty()
	var server_type = str(attachments.get("type", ""))
	var has_server_type = attachments.has("type") and (
		attachments.has("item_id")
		or attachments.has("pet_id")
		or (server_type == "gold" and int(attachments.get("amount", 0)) > 0)
		or (server_type == "yuanbao" and int(attachments.get("amount", 0)) > 0)
		or (server_type == TREASURE_TOKEN_TYPE and not str(attachments.get("token", "")).is_empty())
		or server_type == "fabao"
	)
	return has_gold or has_yuanbao or has_exp or has_items or has_pets or has_server_type

func get_attachment_summary() -> String:
	if not has_attachments():
		return ""

	var parts: Array[String] = []

	if attachments.get("gold", 0) > 0:
		parts.append("金币x%d" % attachments.gold)

	if attachments.get("yuanbao", 0) > 0:
		parts.append("元宝x%d" % attachments.yuanbao)

	if attachments.get("exp", 0) > 0:
		parts.append("经验x%d" % attachments.exp)

	var items = attachments.get("items", [])
	if items is Array and not items.is_empty():
		for label in format_item_attachment_labels(items):
			parts.append(label)

	var pets = attachments.get("pets", [])
	if not pets.is_empty():
		parts.append("宠物x%d" % pets.size())

	if attachments.has("type"):
		var item_type = attachments.get("type", "")
		if item_type == "item" and attachments.has("item_id"):
			var raw_id: String = str(attachments.get("item_id", "未知物品"))
			var quantity = attachments.get("quantity", 1)
			var disp_name: String = "藏宝箱" if raw_id == "藏宝箱" else raw_id
			parts.append("%sx%d" % [disp_name, quantity])
		elif item_type == "pet" and attachments.has("pet_id"):
			var pet_name = _resolve_pet_display_name(attachments)
			var pq = maxi(1, int(attachments.get("quantity", 1)))
			if pq > 1:
				parts.append("宠物[%s]x%d" % [pet_name, pq])
			else:
				parts.append("宠物[%s]" % pet_name)
		elif item_type == "gold":
			var gold_amount = attachments.get("amount", 0)
			if gold_amount > 0:
				parts.append("金币x%d" % gold_amount)
		elif item_type == "yuanbao":
			var yuanbao_amount = attachments.get("amount", 0)
			if yuanbao_amount > 0:
				parts.append("元宝x%d" % yuanbao_amount)
		elif item_type == TREASURE_TOKEN_TYPE and attachments.has("token"):
			parts.append("藏宝箱口令x1")
		elif item_type == "fabao":
			var fb_name: = str(attachments.get("name", ""))
			if fb_name.is_empty():
				fb_name = str(attachments.get("tier", "法宝"))
			parts.append("法宝[%s]" % fb_name)

	return ", ".join(parts)

static func format_item_attachment_labels(items: Array) -> PackedStringArray:
	var labels: = PackedStringArray()
	for entry in items:
		var item_name: = "物品"
		var qty: = 1
		if entry is Dictionary:
			var d: Dictionary = entry
			item_name = str(d.get("name", d.get("id", d.get("item_id", "")))).strip_edges()
			if item_name.is_empty():
				item_name = "物品"
			qty = maxi(1, int(d.get("count", d.get("quantity", 1))))
		elif entry is String:
			var raw: = str(entry).strip_edges()
			if not raw.is_empty():
				item_name = raw
		labels.append("%sx%d" % [item_name, qty])
	return labels

func get_treasure_token() -> String:
	var item_type = str(attachments.get("type", ""))
	if item_type == TREASURE_TOKEN_TYPE:
		return str(attachments.get("token", ""))
	return ""

static func _normalize_attachments(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		return raw
	if raw is Array:
		for entry in raw:
			if entry is Dictionary:
				return entry
	return {}

static func _resolve_pet_display_name(attachments: Dictionary) -> String:
	if not (attachments is Dictionary):
		return "未知宠物"
	var by_name: String = str(attachments.get("petName", attachments.get("name", ""))).strip_edges()
	if not by_name.is_empty():
		return by_name
	var pid: String = str(attachments.get("pet_id", attachments.get("petId", attachments.get("id", "")))).strip_edges()
	if pid.is_empty() or pid == "unknown":
		return "未知宠物"
	var pd: Dictionary = GameData.PET_DATA.get(pid, {})
	var mapped_name: String = str(pd.get("name", "")).strip_edges()
	if not mapped_name.is_empty():
		return mapped_name
	return "未知宠物"


static func _parse_datetime(datetime_str: String) -> int:
	if datetime_str.is_empty():
		return 0


	var iso_regex = RegEx.new()
	iso_regex.compile("^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})")
	var iso_result = iso_regex.search(datetime_str)

	if iso_result:
		var year = iso_result.get_string(1).to_int()
		var month = iso_result.get_string(2).to_int()
		var day = iso_result.get_string(3).to_int()
		var hour = iso_result.get_string(4).to_int()
		var minute = iso_result.get_string(5).to_int()
		var second = iso_result.get_string(6).to_int()

		var dict = {
			"year": year, 
			"month": month, 
			"day": day, 
			"hour": hour, 
			"minute": minute, 
			"second": second
		}
		return int(Time.get_unix_time_from_datetime_dict(dict))


	var mysql_regex = RegEx.new()
	mysql_regex.compile("^(\\d{4})-(\\d{2})-(\\d{2}) (\\d{2}):(\\d{2}):(\\d{2})")
	var mysql_result = mysql_regex.search(datetime_str)

	if mysql_result:
		var year = mysql_result.get_string(1).to_int()
		var month = mysql_result.get_string(2).to_int()
		var day = mysql_result.get_string(3).to_int()
		var hour = mysql_result.get_string(4).to_int()
		var minute = mysql_result.get_string(5).to_int()
		var second = mysql_result.get_string(6).to_int()

		var dict = {
			"year": year, 
			"month": month, 
			"day": day, 
			"hour": hour, 
			"minute": minute, 
			"second": second
		}
		return int(Time.get_unix_time_from_datetime_dict(dict))

	return 0
