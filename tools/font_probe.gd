extends SceneTree
# 字体探针（开发期自检）：确认底栏标签运行时到底用的哪个字体文件。
# 用法：Godot --path . --script tools/font_probe.gd


func _initialize() -> void:
	var pt: Theme = ThemeDB.get_project_theme()
	print("[probe] project_theme = ", pt)
	if pt != null:
		var df: Font = pt.default_font
		print("[probe] theme.default_font = ", df, "  path = ", (df.resource_path if df != null else "(null)"))
	var ps: Variant = ProjectSettings.get_setting("gui/theme/custom", "")
	print("[probe] gui/theme/custom = ", ps)

	var scene: PackedScene = load("res://ui/main_ui.tscn")
	if scene == null:
		printerr("[probe] 载入 ui/main_ui.tscn 失败")
		quit(1)
		return
	var node: Node = scene.instantiate()
	get_root().add_child(node)
	await process_frame
	await process_frame
	for nm in ["BattleLabel", "CharacterLabel", "CityLabel", "PetLabel", "BagLabel"]:
		var lab: Label = node.find_child(nm, true, false) as Label
		if lab == null:
			print("[probe] %s 找不到" % nm)
			continue
		var f: Font = lab.get_theme_font("font")
		var fs: int = lab.get_theme_font_size("font_size")
		print("[probe] %s font=%s path=%s size=%d" % [
			nm, str(f), (f.resource_path if f != null else "(null)"), fs])
		_dump_font(f, "    ")
	quit(0)


func _dump_font(f: Font, pad: String) -> void:
	if f == null:
		print(pad, "font 为 null")
		return
	if f is FontVariation:
		var fv := f as FontVariation
		print(pad, "FontVariation.base_font = ", fv.base_font,
			"   path = ", (fv.base_font.resource_path if fv.base_font != null else "(null)"))
		print(pad, "FontVariation.fallbacks = ", fv.fallbacks)
		_dump_font(fv.base_font, pad + "  ")
	elif f is FontFile:
		var ff := f as FontFile
		print(pad, "FontFile name=", ff.font_name, " style=", ff.font_style)
		# 直接看它有没有这几个字的字形
		for ch in ["战", "斗", "主", "城"]:
			print(pad, "   has ", ch, " = ", ff.has_char(ch.unicode_at(0)))

