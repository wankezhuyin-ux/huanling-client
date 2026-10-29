extends RefCounted
class_name BattleFightLogHistory



const HISTORY_MAX: = 5

var _history: Array = []


func archive_if_needed(title: String, lines: Array, victory: bool) -> void :
	if lines.is_empty():
		return
	var result_tag: = "胜利" if victory else "失败"
	var t: = title.strip_edges()
	if t.is_empty():
		t = "战斗"
	var entry: = {
		"title": "%s（%s）" % [t, result_tag], 
		"body": "\n".join(lines), 
		"lines": lines.duplicate(), 
		"victory": victory, 
		"finished": true, 
	}
	_history.push_front(entry)
	while _history.size() > HISTORY_MAX:
		_history.pop_back()


func get_history_count() -> int:
	return _history.size()



func get_view(
	index: int, 
	current_title: String, 
	current_lines: Array, 
	current_finished: bool, 
	current_victory: bool
) -> Dictionary:
	if index <= 0:
		var title: = current_title.strip_edges()
		if title.is_empty():
			title = "当前战斗"
		if current_finished:
			title = "%s（%s）" % [title, "胜利" if current_victory else "失败"]
		return {
			"title": title, 
			"body": "\n".join(current_lines), 
			"finished": current_finished, 
			"victory": current_victory, 
			"index": 0, 
			"label": "当前场", 
		}
	var hi: = index - 1
	if hi < 0 or hi >= _history.size():
		return {
			"title": "", 
			"body": "", 
			"finished": true, 
			"victory": false, 
			"index": index, 
			"label": "", 
		}
	var entry: Dictionary = _history[hi]
	return {
		"title": str(entry.get("title", "历史战斗")), 
		"body": str(entry.get("body", "")), 
		"finished": true, 
		"victory": bool(entry.get("victory", false)), 
		"index": index, 
		"label": "往前第%d/%d场" % [index, _history.size()], 
	}
