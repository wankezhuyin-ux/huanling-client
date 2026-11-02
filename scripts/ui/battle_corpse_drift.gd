extends RefCounted
class_name BattleCorpseDrift

## 怪物阵亡后「飘着退场」：向右上方滑一段并淡出，而不是原地留一具缩小尸体。
##
## 为什么单独拆出来：这是纯表现层的补间，跟战斗数值、布局坐标都无关，
## 但难点在「谁来收尾」——战斗结束、下一波开场、复活，三方都会去复位同一个 wrap，
## 收尾没收干净就会看到尸体闪回原位、或者怪物透明度卡在 0 再也不出现。
## 把这些状态收进这个小模块（和 BattleMonsterDefeatEffect 一个路子），
## 就能用 tools/test_corpse_drift.gd 直接把位移/透明度跑出来验，不用靠录屏肉眼看。
##
## 只动 wrap 的 position 与 modulate：名字条、血条、尸体、眩晕圈会一起飘，
## 因为它们是 wrap 的子节点。原位与不透明度由
## main_ui 的 _snap_monster_ui_to_battle_home / _restore_monster_ui_home_pose 兜底复位。

## 往右上方飘：我方在左、敌方在右，倒下的怪朝自己那一侧退场，不横穿整个战场。
const OFFSET := Vector2(168.0, -26.0)
const DURATION: float = 0.9
const FADE_DELAY: float = 0.16
const FADE_DURATION: float = 0.68
const TWEEN_META := "_corpse_drift_tween"
const DRIFTED_META := "_corpse_drifted"


## 开始飘散。home 是被动 wrap 的原位（不传就取当前位置）。
static func play(wrap: Control, home: Variant = null) -> void :
	if wrap == null or not is_instance_valid(wrap):
		return
	stop(wrap)
	wrap.remove_meta(DRIFTED_META)
	var from: Vector2 = home if home is Vector2 else wrap.position
	wrap.position = from
	wrap.modulate = Color.WHITE
	var target: Vector2 = from + OFFSET
	var tween: Tween = wrap.create_tween()
	wrap.set_meta(TWEEN_META, tween)
	tween.tween_property(wrap, "position", target, DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 先让人看清「倒下了」，再开始淡——一死就透会像被删掉。
	tween.parallel().tween_property(wrap, "modulate:a", 0.0, FADE_DURATION) \
		.set_delay(FADE_DELAY).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if not is_instance_valid(wrap):
			return
		wrap.remove_meta(TWEEN_META)
		wrap.set_meta(DRIFTED_META, true))


## 只杀补间，不改位置和透明度（给「要自己接管」的调用方用）。
static func stop(wrap: Control) -> void :
	if wrap == null or not is_instance_valid(wrap):
		return
	if wrap.has_meta(TWEEN_META):
		var tw = wrap.get_meta(TWEEN_META)
		if tw is Tween and is_instance_valid(tw):
			(tw as Tween).kill()
		wrap.remove_meta(TWEEN_META)


## 完全收干净：杀补间 + 清「已飘走」标记，交给调用方复位位置和 alpha。
static func clear(wrap: Control) -> void :
	if wrap == null or not is_instance_valid(wrap):
		return
	stop(wrap)
	wrap.remove_meta(DRIFTED_META)


## 是否已经飘完（此时 wrap 是透明的，别再把它设回 alpha=1，否则尸体会闪一下）。
static func is_drifted(wrap: Control) -> bool :
	return wrap != null and is_instance_valid(wrap) and wrap.has_meta(DRIFTED_META)


static func is_playing(wrap: Control) -> bool :
	if wrap == null or not is_instance_valid(wrap) or not wrap.has_meta(TWEEN_META):
		return false
	var tw = wrap.get_meta(TWEEN_META)
	return tw is Tween and is_instance_valid(tw) and (tw as Tween).is_running()
