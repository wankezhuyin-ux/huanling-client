@tool
extends EditorScript

func _run():
	var manifest = {
		"icons": [], 
		"portraits": [], 
		"pets": [], 
		"items": [], 
		"buttons": []
	}

	_scan_directory("res://assets/icons/", manifest.icons)
	_scan_directory("res://assets/portraits/", manifest.portraits)
	_scan_directory("res://assets/pets/", manifest.pets)
	_scan_directory("res://assets/items/", manifest.items)
	_scan_directory("res://assets/buttons/", manifest.buttons)

	var file = FileAccess.open("res://assets/asset_manifest.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()
		print("[AssetManifest] 资源清单已生成!")
		print("  icons: %d" % manifest.icons.size())
		print("  portraits: %d" % manifest.portraits.size())
		print("  pets: %d" % manifest.pets.size())
		print("  items: %d" % manifest.items.size())
		print("  buttons: %d" % manifest.buttons.size())
	else:
		push_error("[AssetManifest] 无法写入资源清单文件")

func _scan_directory(path: String, target_list: Array):
	var dir = DirAccess.open(path)
	if dir == null:
		print("[AssetManifest] 无法打开目录: ", path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".webp"):
				var asset_name = file_name.get_basename().to_lower()
				var full_path = path + file_name
				target_list.append({"name": asset_name, "path": full_path})
		file_name = dir.get_next()
	dir.list_dir_end()
