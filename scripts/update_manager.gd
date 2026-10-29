class_name HotfixUpdateManager
extends RefCounted

const PATCH_DIR: = "user://patches"
const PATCH_FILE: = "user://patches/hotfix.pck"
const PATCH_DOWNLOAD_FILE: = "user://patches/hotfix.pck.download"
const PATCH_VERSION_FILE: = "user://patch_version.txt"
const DOWNLOAD_MAX_ATTEMPTS: = 3
const DOWNLOAD_WATCHDOG_SEC: = 300.0

const _GameServerConfig = preload("res://scripts/game_server_config.gd")

signal progress_changed(fraction: float, status_text: String)
signal failed(error_text: String)


var editor_download_only: bool = false


func get_local_patch_version() -> String:
	if not FileAccess.file_exists(PATCH_VERSION_FILE):
		return ""
	var f: = FileAccess.open(PATCH_VERSION_FILE, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()


func save_local_patch_version(version: String) -> void :
	var f: = FileAccess.open(PATCH_VERSION_FILE, FileAccess.WRITE)
	if f == null:
		push_warning("[Hotfix] 无法写入 patch 版本: %s" % PATCH_VERSION_FILE)
		return
	f.store_string(version.strip_edges())



func try_load_saved_patch() -> bool:
	if OS.has_feature("editor"):
		return false
	if not FileAccess.file_exists(PATCH_FILE):
		return false
	var local_ver: = get_local_patch_version()
	var loaded: = ProjectSettings.load_resource_pack(PATCH_FILE, true)
	if loaded:
		print("[Hotfix] 已加载本地 patch 版本=%s" % (local_ver if not local_ver.is_empty() else "(unknown)"))
	else:
		push_warning("[Hotfix] 本地 patch 文件存在但加载失败: %s" % PATCH_FILE)
		_clear_broken_local_patch()
	return loaded


func _clear_broken_local_patch() -> void :
	if FileAccess.file_exists(PATCH_FILE):
		DirAccess.remove_absolute(PATCH_FILE)
	if FileAccess.file_exists(PATCH_VERSION_FILE):
		DirAccess.remove_absolute(PATCH_VERSION_FILE)
	print("[Hotfix] 已清理无效本地 patch，将重新下载")


func _local_patch_file_valid(expected_sha: String) -> bool:
	if not FileAccess.file_exists(PATCH_FILE):
		return false
	if not expected_sha.is_empty():
		var f: = FileAccess.open(PATCH_FILE, FileAccess.READ)
		if f == null:
			return false
		var body: = f.get_buffer(f.get_length())
		f.close()
		if _sha256_hex(body) != expected_sha:
			return false
	if OS.has_feature("editor"):

		return true
	return ProjectSettings.load_resource_pack(PATCH_FILE, true)


func get_platform_key() -> String:
	var os_name: = OS.get_name()
	if os_name == "Android":
		return "android"
	if os_name == "Windows":
		return "windows"
	if os_name == "macOS":
		return "macos"
	if os_name == "Linux":
		return "linux"
	return os_name.to_lower()


func check_hotfix_available(host: Node, base_version: String) -> Dictionary:
	if host == null:
		return {}
	var manifest: = await _fetch_manifest(host)
	return _build_hotfix_info_from_manifest(manifest, base_version)


func _build_hotfix_info_from_manifest(manifest: Dictionary, base_version: String) -> Dictionary:
	if manifest.is_empty():
		return {}

	var remote_base: = str(manifest.get("base_version", manifest.get("version", ""))).strip_edges()
	if remote_base.is_empty():
		remote_base = base_version
	var minimum_base: = str(manifest.get("minimum_base_version", remote_base)).strip_edges()
	if _version_compare(base_version, minimum_base) < 0:
		print("[Hotfix] 安装包版本过低，需重装，跳过热更 patch")
		return {}

	var remote_patch: = str(manifest.get("patch_version", "")).strip_edges()
	if remote_patch.is_empty():
		print("[Hotfix] manifest 无 patch_version，跳过热更")
		return {}

	var patch_base: = _extract_base_version(remote_patch)
	if _version_compare(base_version, remote_base) > 0 or _version_compare(base_version, patch_base) > 0:
		print("[Hotfix] 底包 %s 已新于热更目标(manifest=%s patch=%s)，跳过热更" % [base_version, remote_base, remote_patch])
		return {}

	var platforms: Variant = manifest.get("platforms", {})
	if not platforms is Dictionary:
		print("[Hotfix] platforms 无效")
		return {}
	var platform_key: = get_platform_key()
	if not platforms.has(platform_key):
		print("[Hotfix] manifest 无当前平台: %s" % platform_key)
		return {}
	var entry: Variant = platforms[platform_key]
	if not entry is Dictionary:
		return {}
	var expected_sha_early: = str(entry.get("sha256", "")).strip_edges().to_lower()

	var local_patch: = get_local_patch_version()
	if _version_compare(remote_patch, local_patch) <= 0:
		if not _local_patch_file_valid(expected_sha_early):
			print("[Hotfix] 版本已是 %s 但本地 patch 无效，将重新下载" % local_patch)
		else:
			print("[Hotfix] 已是最新 patch 本地=%s 远程=%s" % [local_patch, remote_patch])
			return {}

	var url: = str(entry.get("url", "")).strip_edges()
	if url.is_empty():
		print("[Hotfix] 平台 %s 缺少 url" % platform_key)
		return {}

	var release_notes: = str(manifest.get("releaseNotes", "")).strip_edges()
	if release_notes.is_empty():
		release_notes = "优化游戏体验"

	return {
		"patch_version": remote_patch, 
		"releaseNotes": release_notes, 
		"size": int(entry.get("size", 0)), 
		"url": url, 
		"sha256": str(entry.get("sha256", "")).strip_edges().to_lower(), 
		"platform_key": platform_key, 
	}


func apply_hotfix(host: Node, info: Dictionary) -> bool:
	if host == null or info.is_empty():
		return false

	editor_download_only = false
	var url: = str(info.get("url", "")).strip_edges()
	var expected_size: = int(info.get("size", 0))
	var expected_sha: = str(info.get("sha256", "")).strip_edges().to_lower()
	var remote_patch: = str(info.get("patch_version", "")).strip_edges()
	if url.is_empty() or remote_patch.is_empty():
		failed.emit("更新信息无效")
		return false

	if not _ensure_patch_dir():
		failed.emit("无法创建更新目录")
		return false

	if FileAccess.file_exists(PATCH_FILE):
		DirAccess.remove_absolute(PATCH_FILE)
	if FileAccess.file_exists(PATCH_DOWNLOAD_FILE):
		DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)

	# 空间预检：下载本体要占 expected_size，兜底的复制还要再留一份余量
	if expected_size > 0:
		var user_dir: = DirAccess.open("user://")
		var free_bytes: int = user_dir.get_space_left() if user_dir else 0
		if free_bytes > 0 and free_bytes < int(expected_size * 1.2):
			failed.emit("手机存储空间不足（需要约 %.0f MB，请清理后重试）" % (expected_size / 1048576.0 * 1.2))
			return false

	progress_changed.emit(0.05, "正在下载更新…")
	var downloaded: = await _download_to_file(host, url, PATCH_DOWNLOAD_FILE, expected_size)
	if not downloaded:
		failed.emit("下载失败，请换 WiFi 或稍后重试")
		return false

	progress_changed.emit(0.88, "下载完成，正在校验更新包…")
	await host.get_tree().process_frame

	var actual_size: = _file_size(PATCH_DOWNLOAD_FILE)
	if expected_size > 0 and actual_size != expected_size:
		DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)
		failed.emit("更新包大小不匹配")
		return false

	if not expected_sha.is_empty():
		progress_changed.emit(0.9, "正在校验更新包完整性…")
		await host.get_tree().process_frame
		var actual_sha: = _sha256_hex_file(PATCH_DOWNLOAD_FILE)
		if actual_sha != expected_sha:
			DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)
			failed.emit("更新包校验失败")
			return false

	progress_changed.emit(0.94, "校验通过，正在写入更新包…")
	await host.get_tree().process_frame
	# 再等一帧，确保 HTTPRequest 已彻底释放对临时文件的句柄
	await host.get_tree().process_frame

	var rename_err: = DirAccess.rename_absolute(PATCH_DOWNLOAD_FILE, PATCH_FILE)
	if rename_err != OK:
		# 兜底：部分 Android 机型的文件系统不允许直接挪动刚下载完的文件
		# （句柄未完全释放、或临时文件与目标不在同一挂载点）。
		# 退化为「复制 + 删除源文件」，多一次 IO，但对百兆级补丁可接受。
		push_warning("[Hotfix] rename 失败 err=%s，改用复制方式写入" % str(rename_err))
		if FileAccess.file_exists(PATCH_FILE):
			DirAccess.remove_absolute(PATCH_FILE)
		var user_dir: = DirAccess.open("user://")
		var free_bytes: int = user_dir.get_space_left() if user_dir else 0
		if free_bytes > 0 and expected_size > 0 and free_bytes < expected_size:
			DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)
			failed.emit("手机存储空间不足，请清理后再更新")
			return false
		var copy_err: = DirAccess.copy_absolute(PATCH_DOWNLOAD_FILE, PATCH_FILE)
		if copy_err != OK:
			if FileAccess.file_exists(PATCH_FILE):
				DirAccess.remove_absolute(PATCH_FILE)
			DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)
			failed.emit("无法写入更新包（存储空间或权限异常）")
			return false
		DirAccess.remove_absolute(PATCH_DOWNLOAD_FILE)
		if expected_size > 0 and _file_size(PATCH_FILE) != expected_size:
			DirAccess.remove_absolute(PATCH_FILE)
			failed.emit("更新包写入不完整，请重试")
			return false
		print("[Hotfix] 已通过复制方式写入补丁（%d 字节）" % _file_size(PATCH_FILE))

	save_local_patch_version(remote_patch)

	if OS.has_feature("editor"):
		editor_download_only = true
		print("[Hotfix] 编辑器模式：patch 已下载且校验通过，跳过 load（加密包请在导出底包验收）")
		progress_changed.emit(1.0, "下载完成（请用导出底包验收热更）")
		return true



	var platform_key: = str(info.get("platform_key", get_platform_key()))
	print("[Hotfix] 热更包已就绪 patch=%s 平台=%s，等待重启后加载" % [remote_patch, platform_key])
	progress_changed.emit(1.0, "更新完成！正在重启游戏…")
	await host.get_tree().process_frame
	return true


func try_apply_hotfix(host: Node, base_version: String) -> bool:
	var info: = await check_hotfix_available(host, base_version)
	if info.is_empty():
		return false
	return await apply_hotfix(host, info)


func _fetch_manifest(host: Node) -> Dictionary:
	var urls: Array[String] = _GameServerConfig.updates_manifest_url_candidates()
	for url in urls:
		var body: = await _http_get(host, url)
		if body.is_empty():
			continue
		var parsed: = _parse_manifest_json(body)
		if not parsed.is_empty():
			return parsed
	return {}


func _parse_manifest_json(body: PackedByteArray) -> Dictionary:
	var raw: = body.get_string_from_utf8()
	var json: = JSON.new()
	var parse_result: = json.parse(raw)
	if parse_result != OK:
		var t: = raw.strip_edges()
		var i: = t.find("{")
		if i > 0:
			parse_result = json.parse(t.substr(i))
	if parse_result != OK:
		return {}
	var data: Variant = json.data
	if data is Dictionary:
		return data
	return {}


func _http_get(host: Node, url: String) -> PackedByteArray:
	var http: = HTTPRequest.new()
	http.timeout = 30.0
	http.accept_gzip = true
	host.add_child(http)
	var err: = http.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return PackedByteArray()
	var res: Array = await http.request_completed
	http.queue_free()
	if int(res[0]) != HTTPRequest.RESULT_SUCCESS or int(res[1]) != 200:
		return PackedByteArray()
	return res[3]


func _download_to_file(host: Node, url: String, dest_path: String, expected_size: int) -> bool:
	for attempt in range(1, DOWNLOAD_MAX_ATTEMPTS + 1):
		if attempt > 1:
			progress_changed.emit(0.05, "下载中断，正在重试（%d/%d）…" % [attempt, DOWNLOAD_MAX_ATTEMPTS])
			await host.get_tree().create_timer(1.5 * float(attempt)).timeout
		if await _download_to_file_once(host, url, dest_path, expected_size):
			return true
		if FileAccess.file_exists(dest_path):
			DirAccess.remove_absolute(dest_path)
	return false


func _download_to_file_once(host: Node, url: String, dest_path: String, expected_size: int) -> bool:
	if FileAccess.file_exists(dest_path):
		DirAccess.remove_absolute(dest_path)

	var http: = HTTPRequest.new()
	http.use_threads = false
	http.timeout = 0.0
	http.download_file = dest_path
	http.download_chunk_size = 65536
	host.add_child(http)

	var emit_progress: = func(bytes_received: int, body_size: int, phase_hint: String = "") -> void :
		var total_bytes: = body_size if body_size > 0 else expected_size
		var frac: = 0.05
		if total_bytes > 0:
			var ratio: = clampf(float(bytes_received) / float(total_bytes), 0.0, 1.0)
			frac = 0.05 + 0.8 * ratio
		var status: = phase_hint if not phase_hint.is_empty() else "正在下载更新…"
		if phase_hint.is_empty() and total_bytes > 0:
			status = "正在下载更新… %.2f / %.2f MB" % [
				float(bytes_received) / (1024.0 * 1024.0), 
				float(total_bytes) / (1024.0 * 1024.0), 
			]
			if bytes_received >= total_bytes:
				status = "下载完成，正在确认文件…"
				frac = 0.86
		progress_changed.emit(frac, status)

	var err: = http.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		http.queue_free()
		return false

	var done: = false
	var res: Array = []
	http.request_completed.connect( func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void :
		res = [result, response_code]
		done = true
	, CONNECT_ONE_SHOT)

	var watchdog: = Time.get_ticks_msec() + int(DOWNLOAD_WATCHDOG_SEC * 1000.0)
	var disk_complete_since_ms: = -1
	while not done:
		if Time.get_ticks_msec() > watchdog:
			push_warning("[Hotfix] 下载看门狗超时 url=%s" % url)
			http.cancel_request()
			http.queue_free()
			return false
		var bytes_received: = http.get_downloaded_bytes()
		var body_size: = http.get_body_size()
		var total_bytes: = body_size if body_size > 0 else expected_size
		emit_progress.call(bytes_received, body_size)
		if total_bytes > 0:
			var on_disk: = _file_size(dest_path)
			if on_disk >= total_bytes or (expected_size > 0 and on_disk >= expected_size):
				if disk_complete_since_ms < 0:
					disk_complete_since_ms = Time.get_ticks_msec()
				elif Time.get_ticks_msec() - disk_complete_since_ms >= 800:
					if not done:
						push_warning("[Hotfix] 文件已落盘但 request_completed 未回调，继续校验")
						res = [HTTPRequest.RESULT_SUCCESS, 200]
						done = true
						break
		await host.get_tree().process_frame

	if not done:
		emit_progress.call(http.get_downloaded_bytes(), http.get_body_size())
	http.queue_free()
	# 等一帧让 HTTPRequest 真正释放，否则下游 rename 可能因句柄未关而失败
	await host.get_tree().process_frame
	if res.is_empty():
		return false
	if int(res[0]) != HTTPRequest.RESULT_SUCCESS or int(res[1]) != 200:
		return false
	if expected_size > 0 and _file_size(dest_path) != expected_size:
		return false
	return FileAccess.file_exists(dest_path) and _file_size(dest_path) > 0


func _file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var size: = int(f.get_length())
	f.close()
	return size


func _sha256_hex_file(path: String) -> String:
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var ctx: = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var chunk_size: = 65536
	while f.get_position() < f.get_length():
		var remain: = int(f.get_length() - f.get_position())
		var chunk: = f.get_buffer(mini(chunk_size, remain))
		if chunk.is_empty():
			break
		ctx.update(chunk)
	f.close()
	return ctx.finish().hex_encode()


func _ensure_patch_dir() -> bool:
	if DirAccess.dir_exists_absolute(PATCH_DIR):
		return true
	var err: = DirAccess.make_dir_recursive_absolute(PATCH_DIR)
	return err == OK


func _sha256_hex(data: PackedByteArray) -> String:
	var ctx: = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()


func _version_token_int(token: String) -> int:
	var t: = token.strip_edges()
	if t.is_empty():
		return 0
	if t.is_valid_int():
		return int(t)
	var acc: = ""
	for i in t.length():
		var ch: = t[i]
		if ch >= "0" and ch <= "9":
			acc += ch
		else:
			break
	if acc.is_empty() or not acc.is_valid_int():
		return 0
	return int(acc)


func _extract_base_version(version: String) -> String:
	var parts: PackedStringArray = version.strip_edges().split(".")
	if parts.size() >= 3:
		return parts[0] + "." + parts[1] + "." + parts[2]
	return version.strip_edges()


func _version_compare(v1: String, v2: String) -> int:
	var parts1 = v1.split(".")
	var parts2 = v2.split(".")
	for i in range(maxi(parts1.size(), parts2.size())):
		var n1: = 0
		var n2: = 0
		if i < parts1.size():
			n1 = _version_token_int(parts1[i])
		if i < parts2.size():
			n2 = _version_token_int(parts2[i])
		if n1 > n2:
			return 1
		elif n1 < n2:
			return -1
	return 0
