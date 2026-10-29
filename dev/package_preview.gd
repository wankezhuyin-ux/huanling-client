extends SceneTree

var count := 0
func _initialize() -> void:
	var base := ProjectSettings.globalize_path("res://")
	var destination := base.path_join("../../outputs/水墨灵兽修正版.app/Contents/Resources/Game.pck").simplify_path()
	var pack := PCKPacker.new()
	if pack.pck_start(destination) != OK:
		quit(1)
		return
	var config := base.path_join("../../outputs/local-preview/project.godot").simplify_path()
	if pack.add_file("res://project.godot", config) != OK:
		quit(1)
		return
	if not _append(pack, base, ""):
		quit(1)
		return
	var status := pack.flush()
	print("NATIVE_PREVIEW_PACK_OK=" + str(status == OK) + " files=" + str(count))
	quit(0 if status == OK else 1)

func _append(pack: PCKPacker, base: String, relative: String) -> bool:
	var directory := DirAccess.open(base.path_join(relative))
	if directory == null:
		return false
	directory.include_hidden = true
	for name in directory.get_files():
		var rel := relative.path_join(name)
		if name == "project.godot" or name.ends_with(".log") or name.ends_with(".md"):
			continue
		if pack.add_file("res://" + rel, base.path_join(rel)) != OK:
			return false
		count += 1
	for name in directory.get_directories():
		var rel := relative.path_join(name)
		if rel in ["art/source", ".godot/editor", ".godot/shader_cache"]:
			continue
		if not _append(pack, base, rel):
			return false
	return true
