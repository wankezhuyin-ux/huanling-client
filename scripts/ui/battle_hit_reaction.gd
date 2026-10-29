extends RefCounted
class_name BattleHitReaction

## 打击反馈：受击后退、受击闪红、战场震屏。
##
## 只动「表现层节点的 position / modulate」，不碰战斗数值、不碰布局坐标，
## 所以任何战斗（野外/塔/比武/回放）都能直接用。
##
## 连续挨打时有个坑：上一段补间还没走完就来了下一段，如果直接拿当前 position 当原位，
## 位置会一刀一刀往外漂。这里把原位记在 meta 里，每次开新的一段前先收干净再复位。

const META_HOME: = "_hit_reaction_home"
const META_TWEEN: = "_hit_reaction_tween"
const META_FLASH_TWEEN: = "_hit_reaction_flash_tween"
const META_SHAKE_HOME: = "_hit_reaction_shake_home"
const META_SHAKE_TWEEN: = "_hit_reaction_shake_tween"

## 后退：0.05 秒弹出 → 定格 0.035 秒 → 0.17 秒带回弹地收回来。
## 中间那 35 毫秒的定格就是「顿帧」——没有它，受击看起来像被风吹了一下。
const RECOIL_OUT_SEC: = 0.05
const RECOIL_HOLD_SEC: = 0.035
const RECOIL_BACK_SEC: = 0.17

const FLASH_IN_SEC: = 0.045
const FLASH_HOLD_SEC: = 0.04
const FLASH_OUT_SEC: = 0.12
const FLASH_TINT: = Color(1.0, 0.36, 0.3, 1.0)


## 受击后退。dir_x = +1 被打得往右退（怪物），-1 往左退（我方）。
static func knock(node: CanvasItem, dir_x: float, distance: float) -> void :
	if node == null or not is_instance_valid(node):
		return
	var home: Vector2 = _take_over(node, META_HOME, META_TWEEN)
	node.position = home
	var target: Vector2 = home + Vector2(signf(dir_x) * distance, 0.0)
	var tween: Tween = node.create_tween()
	node.set_meta(META_TWEEN, tween)
	tween.tween_property(node, "position", target, RECOIL_OUT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(RECOIL_HOLD_SEC)
	tween.tween_property(node, "position", home, RECOIL_BACK_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_knock.bind(node, home))


## 受击闪一下红。亮度靠 modulate 做不出来的（贴图本身已是白色，乘大于 1 也没变化），
## 所以用「压暗 + 偏红」，在任何底色上都看得见，也不破坏水墨调。
static func flash(node: CanvasItem) -> void :
	if node == null or not is_instance_valid(node):
		return
	if node.has_meta(META_FLASH_TWEEN):
		var old = node.get_meta(META_FLASH_TWEEN)
		if old is Tween and is_instance_valid(old):
			(old as Tween).kill()
	var base: Color = node.modulate
	var tinted: = Color(base.r * FLASH_TINT.r, base.g * FLASH_TINT.g, base.b * FLASH_TINT.b, base.a)
	var tween: Tween = node.create_tween()
	node.set_meta(META_FLASH_TWEEN, tween)
	tween.tween_property(node, "modulate", tinted, FLASH_IN_SEC)
	tween.tween_interval(FLASH_HOLD_SEC)
	tween.tween_property(node, "modulate", base, FLASH_OUT_SEC).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_finish_flash.bind(node, base))


## 战场震动。只在重击时用，幅度按屏幕像素给，别超过 5，否则像手机掉了。
static func shake(field: Control, amplitude: float, duration: float = 0.14) -> void :
	if field == null or not is_instance_valid(field):
		return
	if not field.has_meta(META_SHAKE_HOME):
		field.set_meta(META_SHAKE_HOME, field.position)
	var home: Vector2 = field.get_meta(META_SHAKE_HOME)
	if field.has_meta(META_SHAKE_TWEEN):
		var old = field.get_meta(META_SHAKE_TWEEN)
		if old is Tween and is_instance_valid(old):
			(old as Tween).kill()
	field.position = home
	var steps: int = 4
	var step_sec: = maxf(0.02, duration / float(steps))
	var tween: Tween = field.create_tween()
	field.set_meta(META_SHAKE_TWEEN, tween)
	for i in range(steps):
		var falloff: = 1.0 - float(i) / float(steps)
		var sign_x: = 1.0 if i % 2 == 0 else -1.0
		var offset: = Vector2(amplitude * falloff * sign_x, amplitude * 0.32 * falloff * - sign_x)
		tween.tween_property(field, "position", home + offset, step_sec).set_trans(Tween.TRANS_SINE)
	tween.tween_property(field, "position", home, step_sec)
	tween.tween_callback(_finish_shake.bind(field, home))


static func _take_over(node: CanvasItem, home_meta: String, tween_meta: String) -> Vector2:
	var home: Vector2 = node.position
	if node.has_meta(home_meta):
		home = node.get_meta(home_meta)
	if node.has_meta(tween_meta):
		var old = node.get_meta(tween_meta)
		if old is Tween and is_instance_valid(old):
			(old as Tween).kill()
		node.position = home
		node.remove_meta(tween_meta)
	node.set_meta(home_meta, home)
	return home


static func _finish_knock(node: CanvasItem, home: Vector2) -> void :
	if not is_instance_valid(node):
		return
	node.position = home
	if node.has_meta(META_TWEEN):
		node.remove_meta(META_TWEEN)


static func _finish_flash(node: CanvasItem, base: Color) -> void :
	if not is_instance_valid(node):
		return
	node.modulate = base
	if node.has_meta(META_FLASH_TWEEN):
		node.remove_meta(META_FLASH_TWEEN)


static func _finish_shake(field: Control, home: Vector2) -> void :
	if not is_instance_valid(field):
		return
	field.position = home
	if field.has_meta(META_SHAKE_TWEEN):
		field.remove_meta(META_SHAKE_TWEEN)
