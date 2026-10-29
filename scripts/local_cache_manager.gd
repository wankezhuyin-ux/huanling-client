class_name LocalCacheManager
extends RefCounted



const PATH_ANNOUNCEMENT_CURSOR: = "user://announcement_cursor.cfg"
const PATH_BROADCAST_CURSOR: = "user://broadcast_cursor.cfg"
const PATH_QUEST_DATA: = "user://quest_data.json"
const XIANMO_LOG_PREFIX: = "xianmo_event_logs_"


static func clear_safe_local_cache(user_id: int = 0) -> Dictionary:
	var removed: Array[String] = []
	var patch_cleared: = HotfixBootstrap.clear_local_patch_files(true)
	if patch_cleared:
		removed.append("user://patches/hotfix.pck")
		removed.append("user://patches/hotfix.pck.download")
		removed.append("user://patch_version.txt")
	for path in [
		PATH_ANNOUNCEMENT_CURSOR, 
		PATH_BROADCAST_CURSOR, 
		PATH_QUEST_DATA, 
	]:
		if _remove_file_if_exists(path):
			removed.append(path)
	var xianmo_removed: = _remove_xianmo_event_logs(user_id)
	removed.append_array(xianmo_removed)
	return {
		"ok": true, 
		"removed_paths": removed, 
		"patch_cleared": patch_cleared, 
		"removed_count": removed.size(), 
	}


static func _remove_file_if_exists(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK


static func _remove_xianmo_event_logs(user_id: int) -> Array[String]:
	var removed: Array[String] = []
	var dir: = DirAccess.open("user://")
	if dir == null:
		return removed
	dir.list_dir_begin()
	while true:
		var name: = dir.get_next()
		if name == "":
			break
		if dir.current_is_dir():
			continue
		if not name.begins_with(XIANMO_LOG_PREFIX) or not name.ends_with(".json"):
			continue
		if user_id > 0 and not name.ends_with("_%d.json" % user_id):
			continue
		var full_path: = "user://%s" % name
		if _remove_file_if_exists(full_path):
			removed.append(full_path)
	dir.list_dir_end()
	return removed
