extends RefCounted
class_name GangWarReport

const UIStyle = preload("res://scripts/ui_style.gd")

static func activity_line_text(entry: Dictionary) -> String:
	return str(entry.get("message", entry.get("summary", entry.get("text", ""))))

static func activity_line_color(entry: Dictionary) -> Color:
	var t: = str(entry.get("type", entry.get("log_type", "round")))
	match t:
		"highlight", "progress":
			return Color(1.0, 0.843, 0.0)
		"result", "attacker_won":
			return Color(0.486, 0.988, 0.0)
		"attack":
			return Color(1.0, 0.702, 0.278)
		"defense", "repair":
			return Color(0.529, 0.808, 0.98)
		_:
			return Color(0.831, 0.91, 1.0)

static func format_activity_line(entry: Dictionary) -> String:
	var msg: = activity_line_text(entry)
	var hex: = activity_line_color(entry).to_html(false)
	return "[color=%s]%s[/color]" % [hex, msg]

static func build_activity_log_bbcode(entries: Array) -> String:
	var lines: PackedStringArray = []
	for e in entries:
		if e is Dictionary:
			lines.append(format_activity_line(e))
	return "\n".join(lines)

static func format_report_summary(report: Dictionary) -> String:
	return "[%s] %s" % [str(report.get("reportType", "")), str(report.get("summary", report.get("title", "")))]
