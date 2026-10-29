extends SceneTree

# 打击反馈自检：受击位移会归位、连续挨打不漂移、震屏不留残位移。
# 跑法：Godot --headless --path . --script res://tools/test_hit_reaction.gd
#
# 注意：headless 下补间的中间帧不保证逐帧推进，中间那一瞬间的位置读不准，
# 所以这里只断「动画已排上」和「演完精确回原位」——真正会出事的也正是后者：
# 连续战斗几十场后位置越飘越远，战场上人和怪会慢慢挪出格子。

const HitReaction = preload("res://scripts/ui/battle_hit_reaction.gd")
const BattleSystem = preload("res://scripts/battle_system.gd")
const PLAYER_ATTACK_DURATION: = 0.3
const LUNGE_APPROACH: = 0.15
const LUNGE_RETURN: = 0.15
const META_TWEEN: = "_hit_reaction_tween"


func _initialize() -> void:
	_run()


func _run() -> void:
	var fail: = 0
	var field: = Control.new()
	get_root().add_child(field)
	field.position = Vector2(12.0, 34.0)
	var sprite: = Node2D.new()
	field.add_child(sprite)
	sprite.position = Vector2(100.0, 50.0)
	var home: = sprite.position
	var field_home: = field.position

	# 1) 受击要真的起一段补间，演完必须精确回原位
	HitReaction.knock(sprite, 1.0, 7.0)
	if not sprite.has_meta(META_TWEEN):
		print("FAIL 受击没有排上补间")
		fail += 1
	else:
		var tw = sprite.get_meta(META_TWEEN)
		if not (tw is Tween and is_instance_valid(tw) and (tw as Tween).is_running()):
			print("FAIL 受击补间没在跑")
			fail += 1
	await create_timer(0.55).timeout
	if not sprite.position.is_equal_approx(home):
		print("FAIL 受击后没归位：", sprite.position, "（应回到 ", home, "）")
		fail += 1
	if sprite.has_meta(META_TWEEN):
		print("FAIL 受击补间结束后没清标记")
		fail += 1

	# 2) 连续挨打：上一段没演完就来下一段，不能越打越远
	for i in range(5):
		HitReaction.knock(sprite, 1.0, 13.0)
		await create_timer(0.04).timeout
	await create_timer(0.6).timeout
	if not sprite.position.is_equal_approx(home):
		print("FAIL 连续受击后漂移：", sprite.position, "（应回到 ", home, "）")
		fail += 1

	# 3) 闪红结束要还原成原来的颜色（有的单位本身带色调，不能一律刷白）
	sprite.modulate = Color(0.9, 0.8, 0.7, 1.0)
	var base: Color = sprite.modulate
	HitReaction.flash(sprite)
	await create_timer(0.45).timeout
	if not sprite.modulate.is_equal_approx(base):
		print("FAIL 闪红后没还原：", sprite.modulate, "（应为 ", base, "）")
		fail += 1

	# 4) 震屏结束要精确回到原位，否则战场会一场一场往下沉
	HitReaction.shake(field, 4.0, 0.14)
	await create_timer(0.6).timeout
	if not field.position.is_equal_approx(field_home):
		print("FAIL 震屏后没归位：", field.position, "（应为 ", field_home, "）")
		fail += 1

	# 5) 出手窗口必须装得下「突进 + 顶住 + 收招」，否则下一刀会打断上一刀的动作
	var lunge_total: float = LUNGE_APPROACH + (PLAYER_ATTACK_DURATION - LUNGE_APPROACH) + LUNGE_RETURN
	if BattleSystem.ROUND_WINDOW_SECONDS + 0.001 < lunge_total:
		print("FAIL 出手窗口(", BattleSystem.ROUND_WINDOW_SECONDS, "秒) 装不下突进动作(", lunge_total, "秒)")
		fail += 1
	# 命中判定要落在「已经冲到位、还没开始收回」那一段
	if BattleSystem.ATTACK_IMPACT_DELAY < LUNGE_APPROACH:
		print("FAIL 命中判定早于突进到位：", BattleSystem.ATTACK_IMPACT_DELAY)
		fail += 1
	if BattleSystem.ATTACK_IMPACT_DELAY > PLAYER_ATTACK_DURATION:
		print("FAIL 命中判定晚于收招：", BattleSystem.ATTACK_IMPACT_DELAY)
		fail += 1

	print("节奏：窗口 %.2f 秒，突进 %.2f 秒，命中 %.2f 秒" % [
		BattleSystem.ROUND_WINDOW_SECONDS, lunge_total, BattleSystem.ATTACK_IMPACT_DELAY])
	print("结果：通过" if fail == 0 else "结果：失败 %d 项" % fail)
	quit(0 if fail == 0 else 1)
