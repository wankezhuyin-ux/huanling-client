extends RefCounted



static func has_summary(summary: Dictionary, has_key: String = "hasPinned") -> bool:
	if summary.is_empty():
		return false
	return bool(summary.get(has_key, false))


static func format_summary(
	summary: Dictionary, 
	has_key: String = "hasPinned", 
	empty_text: String = "尚未设置人物与出战宠快照，请先更新"
) -> String:
	if not has_summary(summary, has_key):
		return empty_text
	var player_name: = str(summary.get("playerName", "玩家"))
	var player_level: = _safe_int(summary.get("playerLevel"), 1)
	var player_realm: = str(summary.get("playerRealm", "凡人"))
	var pet_name: = str(summary.get("petName", "宠物"))
	var pet_level: = _safe_int(summary.get("petLevel"), 1)
	var time_raw: = str(summary.get("pinnedAt", summary.get("updatedAt", ""))).strip_edges()
	var date_text: = time_raw.substr(0, 10) if time_raw.length() >= 10 else "已设置"
	var reincarnation: = _safe_int(summary.get("playerReincarnation"), 0)
	var realm_part: = player_realm
	if reincarnation > 0:
		realm_part = "%s 投:%d" % [player_realm, reincarnation]
	if pet_name.is_empty():
		return "人物：%s Lv.%d %s | 宠物：暂无（%s 更新）" % [
			player_name, player_level, realm_part, date_text
		]
	return "人物：%s Lv.%d %s | 宠物：%s Lv.%d（%s 更新）" % [
		player_name, player_level, realm_part, pet_name, pet_level, date_text
	]


static func _safe_int(value: Variant, default_val: int) -> int:
	if value == null:
		return default_val
	return int(value)
