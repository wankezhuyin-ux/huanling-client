extends SceneTree
# 把原游戏 APK 里的 .ctex 反解成 PNG，用来恢复原版素材。
#
# 用法：
#   Godot --headless --path . --script tools/export_orig_ctex.gd -- \
#     --manifest=tools/orig_map/manifest.json --out=/abs/path/to/out
#
# 关键点：Godot 只能加载 res:// 下的资源。所以脚本先把原包的
# .godot/imported 整个复制到工程内的 res://orig_imported/，
# 再按 manifest 里的映射把 ctex 读回来存成 PNG。
# 跑完这个目录可以删。

const SRC_IMPORTED := "/Users/a1111/Documents/Codex/2026-10-21/n/work/apk-inspection/unpacked/assets/.godot/imported"
const DST_IMPORTED := "res://orig_imported"

var _manifest: Dictionary = {}


func _initialize() -> void:
	var manifest_path: String = ""
	var out_root: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--manifest="):
			manifest_path = a.substr(11)
		elif a.begins_with("--out="):
			out_root = a.substr(6)
	if manifest_path == "" or out_root == "":
		printerr("[export_orig] 需要 --manifest= 和 --out=")
		quit(2)
		return

	# 1) 复制原包导入缓存进工程（res:// 下才能被 ResourceLoader 读到）
	if not DirAccess.dir_exists_absolute(DST_IMPORTED):
		print("[export_orig] 复制原包 imported 缓存…")
		_copy_dir(SRC_IMPORTED, ProjectSettings.globalize_path(DST_IMPORTED))
	print("[export_orig] 缓存就绪：", DirAccess.get_files_at(DST_IMPORTED).size(), " 个文件")

	# 2) 读映射
	var mf := FileAccess.open(manifest_path, FileAccess.READ)
	if mf == null:
		printerr("[export_orig] 读不到 manifest: %s" % manifest_path)
		quit(2)
		return
	var parsed = JSON.parse_string(mf.get_as_text())
	mf.close()
	if not (parsed is Dictionary):
		printerr("[export_orig] manifest 格式不对")
		quit(2)
		return
	_manifest = parsed

	# 3) 逐张反解
	DirAccess.make_dir_recursive_absolute(out_root)
	var total := 0
	var ok := 0
	var fail := 0
	for rel_v in _manifest.keys():
		var rel: String = str(rel_v)
		var ctex: String = str(_manifest[rel_v])
		total += 1
		# rel 形如 pets/linlin.png.import -> 目标 assets/pets/linlin.png
		var stem: String = rel.substr(0, rel.length() - 7)  # 去掉 ".import"
		var sub: String = stem.get_base_dir()
		var fname: String = stem.get_file()
		var dst_dir: String = out_root.path_join(sub)
		DirAccess.make_dir_recursive_absolute(dst_dir)
		if _export_one(ctex, dst_dir.path_join(fname)):
			ok += 1
		else:
			fail += 1

	print("[export_orig] 总计 %d，成功 %d，失败 %d" % [total, ok, fail])
	print("DONE")
	quit(0)


func _copy_dir(src: String, dst: String) -> void:
	DirAccess.make_dir_recursive_absolute(dst)
	var d := DirAccess.open(src)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if not d.current_is_dir():
			var from := src.path_join(name)
			var to := dst.path_join(name)
			var sf := FileAccess.open(from, FileAccess.READ)
			if sf != null:
				var df := FileAccess.open(to, FileAccess.WRITE)
				if df != null:
					df.store_buffer(sf.get_buffer(sf.get_length()))
					df.close()
				sf.close()
		name = d.get_next()
	d.list_dir_end()


func _export_one(ctex_name: String, out_path: String) -> bool:
	var res_path: String = DST_IMPORTED.path_join(ctex_name)
	if not ResourceLoader.exists(res_path):
		return false
	var res: Resource = ResourceLoader.load(res_path)
	if res == null or not (res is CompressedTexture2D):
		return false
	var img: Image = (res as CompressedTexture2D).get_image()
	if img == null:
		return false
	if img.is_compressed():
		if img.decompress() != OK:
			return false
	return img.save_png(out_path) == OK
