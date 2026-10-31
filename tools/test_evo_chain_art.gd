extends SceneTree

## 进化宠物「链专属立绘」自检
##
## 形态 id 在不同链之间是复用的：yu_yi 既是盈盈（紫蝶）的普通形态，
## 也是赤翅蛾的变异形态。共用一张图 = 「蝴蝶进化成蛾子」，所以必须按
## 「原物种 + 形态」找图。这条自检锁住三件事：
##   1. 有链专属图时，优先用链专属的；
##   2. 没有链专属图时，安全退回共用的形态图（不会开天窗）；
##   3. 链专属图的 idle / attack / 体积图 / 图标 四件套齐全，缺一件就报错。
##
## 用法：Godot --headless --path . --script tools/test_evo_chain_art.gd

const EVO_DIR := "res://assets/sprites/evo/"
const VOL_DIR := "res://assets/sprites/vol/evo/"
const ICON_DIR := "res://assets/pets/evo/"


func _initialize() -> void:
	var fails: int = 0
	var chains: Array = []
	var dir := DirAccess.open(EVO_DIR)
	if dir == null:
		print("FAIL 没有 evo 立绘目录：", EVO_DIR)
		quit(1)
		return
	for f in dir.get_files():
		if f.ends_with("_idle.png"):
			chains.append(f.substr(0, f.length() - len("_idle.png")))
	print("链专属形态 %d 组" % chains.size())

	for base in chains:
		# base 形如 yingying_yu_yi → 原物种 yingying / 形态 yu_yi
		var idx: int = base.rfind("_")
		var origin: String = base.substr(0, idx)
		var form: String = base.substr(idx + 1)
		var need: Array[String] = [
			"%s%s_idle.png" % [EVO_DIR, base],
			"%s%s_attack.png" % [EVO_DIR, base],
			"%s%s_idle_vol.png" % [VOL_DIR, base],
			"%s%s_attack_vol.png" % [VOL_DIR, base],
			"%s%s.png" % [ICON_DIR, base],
		]
		var missing: Array[String] = []
		for p in need:
			if not ResourceLoader.exists(p) and not FileAccess.file_exists(p):
				missing.append(p.get_file())
		var ok: bool = missing.is_empty()
		print("  %-28s [%s/%s] %s" % [base, origin, form, "OK" if ok else ("缺 " + ", ".join(missing))])
		if not ok:
			fails += 1

	# 查图优先级：链专属优先，缺则退回共用形态图
	var main_script: = load("res://ui/main_ui.gd")
	if main_script == null:
		print("FAIL 读不到 main_ui.gd")
		quit(1)
		return
	var probe: Object = main_script.new()
	var chain_id: String = str(probe.call("_evo_chain_sprite_id", "yu_yi", "yingying"))
	var fallback_id: String = str(probe.call("_evo_chain_sprite_id", "yu_yi", "not_exists_origin"))
	var p1: bool = chain_id == "evo/yingying_yu_yi"
	var p2: bool = fallback_id == "yu_yi"
	print("链专属优先: %s（%s）" % ["OK" if p1 else "FAIL", chain_id])
	print("缺图退回共用形态图: %s（%s）" % ["OK" if p2 else "FAIL", fallback_id])
	if not p1 or not p2:
		fails += 1
	probe.free()

	print("FAIL_COUNT=", fails)
	print("DONE")
	quit(0 if fails == 0 else 1)
