extends SceneTree
## 切地图实测：模拟「换地图 → 解析背景路径 → 加载贴图」，看每张地图解析出的
## 背景是不是同一张；顺带查每张地图的怪物 pet_id 能不能找到立绘。
##
## 用法：Godot --headless --path . --script tools/probe_map_switch.gd [--apk=../build/xxx.apk]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--apk="):
			var p = a.substr(6)
			print("挂载 APK: ", p)
			if ProjectSettings.load_resource_pack(p, true) == null:
				print("!! 挂载失败"); quit(1); return

	var MD = load("res://scripts/maps_data_complete.gd")
	var data = MD.get("MAPS_DATA")
	if not (data is Dictionary):
		print("!! MAPS_DATA 不是字典"); quit(1); return
	var keys := (data as Dictionary).keys()
	print("地图总数 %d" % keys.size())

	var DEFAULT_BG := "res://assets/backgrounds/morenzhandoubj.jpg"
	var seen := {}
	var no_pet_id := 0
	var pet_missing := {}
	var n := 0
	for k in keys:
		if n >= 30: break
		n += 1
		var full := str(k).strip_edges()
		var idx := full.rfind("（")
		var title := full
		if idx >= 0:
			var cs := full.substr(idx)
			if cs.ends_with("）"):
				title = full.substr(0, idx).strip_edges()
		var jpg := "res://assets/backgrounds/%s.jpg" % title
		var path := jpg
		if not ResourceLoader.exists(jpg):
			path = "res://assets/backgrounds/%s.png" % title
		if not ResourceLoader.exists(path):
			path = DEFAULT_BG + " (回退)"
		seen[path] = int(seen.get(path, 0)) + 1
		print("  %-22s → %s" % [title, path])
		# 怪物 pet_id 检查
		var mons: Array = (data[k] as Dictionary).get("monsters", [])
		for m in mons:
			var pid := str((m as Dictionary).get("pet_id", "")).strip_edges()
			if pid == "":
				no_pet_id += 1
				continue
			var sp := "res://assets/sprites/%s_idle.png" % pid
			if not ResourceLoader.exists(sp):
				pet_missing[pid] = int(pet_missing.get(pid, 0)) + 1
	print("\n不同背景贴图: %d 种 / %d 张地图" % [seen.size(), n])
	print("怪物缺 pet_id: %d 个" % no_pet_id)
	print("怪物 pet_id 找不到立绘: %s" % str(pet_missing))
	quit(0)
