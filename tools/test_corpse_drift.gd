extends SceneTree

## 校验怪物阵亡的「向右上飘走 + 淡出」：
##   1) 开始飘散后，wrap 向右位移、透明度下降（不是原地定格）；
##   2) 0.35 秒时还看得见（透明度在 0.15~1 之间），不是一死就消失；
##   3) 播完（>1.0 秒）后完全透明、位置在目标点、is_drifted 为真；
##   4) clear() 之后标记清掉，调用方可以把位置/透明度复位（下一波开场走这条）；
##   5) 复位后再 play 一次仍然正常（同一只怪反复死不粘状态）。
## 用法：godot --headless --path . --script res://tools/test_corpse_drift.gd

const BattleCorpseDriftLib = preload("res://scripts/ui/battle_corpse_drift.gd")
const HOME := Vector2(500.0, 300.0)


func _initialize() -> void:
	var fails: int = 0
	var wrap: Control = Control.new()
	wrap.name = "FakeMonsterWrap"
	wrap.size = Vector2(140.0, 140.0)
	wrap.position = HOME
	get_root().add_child(wrap)

	# 1) 起手
	BattleCorpseDriftLib.play(wrap, HOME)
	var started_ok: bool = absf(wrap.position.x - HOME.x) < 0.01 and wrap.modulate.a > 0.99
	print("开始飘散：位置=原位、透明度=1: ", "OK" if started_ok else "FAIL")
	if not started_ok:
		fails += 1

	await create_timer(0.35).timeout
	var mid_x: float = wrap.position.x
	var mid_a: float = wrap.modulate.a
	var direction_ok: bool = mid_x > HOME.x + 60.0
	var visible_ok: bool = mid_a > 0.12 and mid_a < 0.95
	print("0.35 秒：向右 %.0fpx（应 >60）、透明度 %.2f（应在 0.12~0.95）: %s" %
		[mid_x - HOME.x, mid_a, "OK" if (direction_ok and visible_ok) else "FAIL"])
	if not (direction_ok and visible_ok):
		fails += 1

	# 2) 播完
	await create_timer(0.8).timeout
	var end_ok: bool = wrap.modulate.a < 0.02 \
		and absf(wrap.position.x - (HOME.x + BattleCorpseDriftLib.OFFSET.x)) < 2.0 \
		and BattleCorpseDriftLib.is_drifted(wrap) \
		and not BattleCorpseDriftLib.is_playing(wrap)
	print("播完：透明度=%.2f 位置x=%.0f（应 %.0f） drifted=%s: %s" %
		[wrap.modulate.a, wrap.position.x, HOME.x + BattleCorpseDriftLib.OFFSET.x,
		str(BattleCorpseDriftLib.is_drifted(wrap)), "OK" if end_ok else "FAIL"])
	if not end_ok:
		fails += 1

	# 3) 下一波复位
	BattleCorpseDriftLib.clear(wrap)
	wrap.position = HOME
	wrap.modulate = Color.WHITE
	var reset_ok: bool = not BattleCorpseDriftLib.is_drifted(wrap) and absf(wrap.modulate.a - 1.0) < 0.01
	print("clear 后可以复位（不残留「已飘走」标记）: ", "OK" if reset_ok else "FAIL")
	if not reset_ok:
		fails += 1

	# 4) 同一只怪再死一次
	BattleCorpseDriftLib.play(wrap, HOME)
	await create_timer(0.2).timeout
	var again_ok: bool = wrap.position.x > HOME.x + 20.0 and wrap.modulate.a < 1.0
	print("同一只怪再飘一次仍然生效: ", "OK" if again_ok else "FAIL")
	if not again_ok:
		fails += 1

	# 5) 飘散中途被 clear（比如战斗结束时统一复位）
	BattleCorpseDriftLib.clear(wrap)
	var interrupted_ok: bool = not BattleCorpseDriftLib.is_playing(wrap) and not BattleCorpseDriftLib.is_drifted(wrap)
	print("飘散中途 clear 能立刻停住: ", "OK" if interrupted_ok else "FAIL")
	if not interrupted_ok:
		fails += 1

	print("FAIL_COUNT=", fails)
	print("DONE")
	quit(0 if fails == 0 else 1)
