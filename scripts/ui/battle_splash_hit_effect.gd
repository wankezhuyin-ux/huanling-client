extends RefCounted
class_name BattleSplashHitEffect

const SHEET_PATH: = "res://assets/guanghuan/splash_hit.png"
const ANIM_NAME: = "play"
const EFFECT_NODE_NAME: = "SplashHitEffect"
const FRAME_HEIGHT: = 160
const FRAME_WIDTH: = 160
const FRAME_COUNT: = 3
const DISPLAY_SIZE: = 128.0
const EFFECT_Z_INDEX: = 28
const PLAY_DURATION_SEC: = 0.38

static var _cached_sprite_frames: SpriteFrames = null
static var _cached_play_duration: float = -1.0


static func play_on_wrap(wrap: Control, halo_offset: Vector2 = Vector2.ZERO) -> void :
	if wrap == null:
		return
	var existing = wrap.get_node_or_null(EFFECT_NODE_NAME)
	if existing:
		existing.queue_free()
	var effect: = _create_effect_node(halo_offset)
	if effect == null:
		return
	effect.name = EFFECT_NODE_NAME
	effect.z_index = EFFECT_Z_INDEX
	effect.z_as_relative = true
	wrap.add_child(effect)
	wrap.move_child(effect, -1)
	effect.visible = true
	effect.frame = 0
	effect.play(ANIM_NAME)
	effect.animation_finished.connect(_on_effect_finished.bind(effect), CONNECT_ONE_SHOT)
	var safety: = Timer.new()
	safety.name = "SplashHitEffectSafetyTimer"
	safety.one_shot = true
	safety.wait_time = PLAY_DURATION_SEC * 1.5
	safety.process_callback = Timer.TIMER_PROCESS_IDLE
	safety.timeout.connect(_on_safety_timeout.bind(effect, safety), CONNECT_ONE_SHOT)
	effect.add_child(safety)
	safety.start()


static func _create_effect_node(halo_offset: Vector2) -> AnimatedSprite2D:
	var sprite_frames: = build_sprite_frames(PLAY_DURATION_SEC)
	if sprite_frames == null:
		return null
	var effect: = AnimatedSprite2D.new()
	effect.centered = true
	effect.position = halo_offset
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var frame_height: = float(FRAME_HEIGHT)
	if sprite_frames.get_frame_count(ANIM_NAME) > 0:
		var first_tex = sprite_frames.get_frame_texture(ANIM_NAME, 0)
		if first_tex != null:
			frame_height = float(first_tex.get_height())
	var scale_val: = DISPLAY_SIZE / frame_height if frame_height > 0.0 else 1.0
	effect.scale = Vector2(scale_val, scale_val)
	effect.sprite_frames = sprite_frames
	return effect


static func build_sprite_frames(play_duration_sec: float) -> SpriteFrames:
	if _cached_sprite_frames != null and absf(_cached_play_duration - play_duration_sec) < 0.001:
		return _cached_sprite_frames
	var sheet: Texture2D = load(SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var frame_count: = FRAME_COUNT
	if frame_count <= 0:
		return null
	var sheet_width: = sheet.get_width()
	if sheet_width < frame_count * FRAME_WIDTH:
		return null
	var frame_height: = float(mini(sheet.get_height(), FRAME_HEIGHT))
	var frames: = SpriteFrames.new()
	frames.add_animation(ANIM_NAME)
	for fi in range(frame_count):
		var atlas: = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.filter_clip = true
		atlas.region = Rect2(float(fi * FRAME_WIDTH), 0.0, float(FRAME_WIDTH), frame_height)
		frames.add_frame(ANIM_NAME, atlas)
	frames.set_animation_loop(ANIM_NAME, false)
	if play_duration_sec > 0.0:
		frames.set_animation_speed(ANIM_NAME, float(frame_count) / play_duration_sec)
	_cached_sprite_frames = frames
	_cached_play_duration = play_duration_sec
	return frames


static func _on_effect_finished(effect: AnimatedSprite2D) -> void :
	_remove_effect(effect)


static func _on_safety_timeout(effect: AnimatedSprite2D, safety: Timer) -> void :
	if is_instance_valid(safety):
		safety.queue_free()
	_remove_effect(effect)


static func _remove_effect(effect: AnimatedSprite2D) -> void :
	if not is_instance_valid(effect):
		return
	effect.queue_free()
