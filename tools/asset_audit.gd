extends SceneTree
## 视觉素材覆盖审计：遍历游戏数据，统计每一类内容实际解析到的图片文件，
## 找出仍然回落到通用占位图（icon_item / icon_material）的部分。
## 用法：Godot --headless --path . --script tools/asset_audit.gd

const GameData = preload("res://scripts/game_data.gd")
const IconHelper = preload("res://scripts/ui/inventory_icon_helper.gd")

func _init() -> void:
	print("=== ASSET AUDIT ===")

	# ---------- 1. 道具 ----------
	var items: Dictionary = GameData.ALL_ITEMS if GameData.ALL_ITEMS is Dictionary else {}
	print("[items] total=", items.size())
	var by_icon: Dictionary = {}
	var generic: Array = []
	for name in items.keys():
		var cfg = items[name]
		var tex = IconHelper.category_icon_for_inventory_item({"name": name})
		var path := "<null>"
		if tex != null:
			path = str(tex.resource_path) if not str(tex.resource_path).is_empty() else "<runtime>"
		by_icon[path] = int(by_icon.get(path, 0)) + 1
		if path.contains("icon_item.png") or path == "<null>":
			generic.append(str(name))
	var sorted_icons: Array = by_icon.keys()
	sorted_icons.sort_custom(func(a, b): return int(by_icon[a]) > int(by_icon[b]))
	print("[items] 落到通用占位 icon_item 的道具数=", generic.size())
	for p in sorted_icons:
		print("    ", int(by_icon[p]), "  ", p)
	if generic.size() > 0:
		print("[items] 占位道具样例：", generic.slice(0, 40))

	# ---------- 2. 地图背景 ----------
	var maps = GameData.MAPS_DATA if GameData.MAPS_DATA is Dictionary else {}
	print("[maps] total=", maps.size())
	var missing_bg: Array = []
	for k in maps.keys():
		var m = maps[k]
		var bg := ""
		if m is Dictionary:
			bg = str(m.get("background", m.get("bg", m.get("background_path", ""))))
		if bg.is_empty():
			missing_bg.append(str(k) + "(no-bg-field)")
			continue
		var cand: Array = [bg]
		if not bg.begins_with("res://"):
			cand = ["res://assets/backgrounds/%s.jpg" % bg, "res://assets/backgrounds/%s.png" % bg, "res://assets/background/%s.jpg" % bg]
		var found := false
		for c in cand:
			if ResourceLoader.exists(c) or FileAccess.file_exists(c):
				found = true
				break
		if not found:
			missing_bg.append(str(k) + " -> " + bg)
	print("[maps] 背景缺失/无字段=", missing_bg.size())
	if missing_bg.size() > 0:
		print("    ", missing_bg.slice(0, 40))

	# ---------- 3. 宠物 ----------
	var pets = GameData.PET_DATA if GameData.PET_DATA is Dictionary else {}
	print("[pets] GameData.PET_DATA total=", pets.size())
	var miss_pet: Array = []
	for k in pets.keys():
		var n := str(k).split("_")[0]
		var ok := false
		for c in ["res://assets/pets/%s.png" % k, "res://assets/pets/%s.png" % n]:
			if ResourceLoader.exists(c):
				ok = true
				break
		if not ok:
			miss_pet.append(str(k))
	print("[pets] 立绘缺失=", miss_pet.size(), " ", miss_pet.slice(0, 30))

	# ---------- 4. 技能 ----------
	print("[PET_SKILLS] total=", GameData.PET_SKILLS.size())
	print("[MARTIAL_ARTS_POOL] total=", GameData.MARTIAL_ARTS_POOL.size())
	print("[MARTIAL_SKILL_BOOKS] total=", GameData.MARTIAL_SKILL_BOOKS.size())
	print("[PET_SKILL_BOOKS] total=", GameData.PET_SKILL_BOOKS.size())

	print("=== END ===")
	quit(0)
