extends SceneTree

func _init():
	var pck: String = OS.get_environment("PCK_PATH")
	if pck.is_empty():
		pck = "/Users/a1111/Documents/Codex/2026-10-21/n/outputs/local-server/state/patches/hotfix-android.pck"
	print("[Dump] load pack: ", pck)
	var okload: bool = ProjectSettings.load_resource_pack(pck, true)
	print("[Dump] loaded=", okload)
	for p in ["res://ui/main_ui.gdc", "res://scripts/game_manager.gdc", "res://scripts/player.gdc"]:
		if FileAccess.file_exists(p):
			var f: = FileAccess.open(p, FileAccess.READ)
			if f:
				var n: int = f.get_length()
				var body: = f.get_buffer(n)
				var ctx: = HashingContext.new()
				ctx.start(HashingContext.HASH_SHA256)
				ctx.update(body)
				print("[Dump] ", p, " size=", n, " sha=", ctx.finish().hex_encode().substr(0, 16))
		else:
			print("[Dump] MISSING ", p)
	quit()
