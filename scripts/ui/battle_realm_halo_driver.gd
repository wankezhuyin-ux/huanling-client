extends Node
class_name BattleRealmHaloDriver

const HALO_ANIM_NAME: = "play"
const MAX_BEGIN_PLAY_RETRIES: = 4

var _halo: AnimatedSprite2D = null
var _play_duration_sec: = 0.5
var _play_interval_sec: = 2.0
var _wait_timer: Timer = null
var _safety_timer: Timer = null
var _is_playing: = false
var _battle_paused: = false
var _begin_play_retries: = 0


func configure(halo: AnimatedSprite2D, play_duration_sec: float, play_interval_sec: float) -> void :
	_halo = halo
	_play_duration_sec = maxf(play_duration_sec, 0.01)
	_play_interval_sec = maxf(play_interval_sec, 0.0)


func resume_or_start_playback() -> void :
	_setup_timers()
	var wait_sec: = BattleRealmHalo.get_wait_seconds_before_play()
	if wait_sec > 0.0:
		_hide_halo()
		_wait_timer.wait_time = wait_sec
		_wait_timer.start()
	else:
		_play_cycle()


func _setup_timers() -> void :
	if _wait_timer == null:
		_wait_timer = Timer.new()
		_wait_timer.name = "RealmHaloWaitTimer"
		_wait_timer.one_shot = true
		_wait_timer.process_callback = Timer.TIMER_PROCESS_IDLE
		_wait_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		_wait_timer.timeout.connect(_on_wait_finished)
		add_child(_wait_timer)
	if _safety_timer == null:
		_safety_timer = Timer.new()
		_safety_timer.name = "RealmHaloSafetyTimer"
		_safety_timer.one_shot = true
		_safety_timer.process_callback = Timer.TIMER_PROCESS_IDLE
		_safety_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		_safety_timer.timeout.connect(_on_safety_timeout)
		add_child(_safety_timer)


func resume_if_stalled() -> void :
	if _battle_paused:
		return
	if _is_playing:
		if is_instance_valid(_halo) and not _halo.is_playing():
			_begin_halo_animation()
		return
	if _wait_timer != null and not _wait_timer.is_stopped():
		return
	if is_instance_valid(_halo) and _halo.visible and not _halo.is_playing():
		_play_cycle()
		return
	resume_or_start_playback()


func _play_cycle() -> void :
	if not is_instance_valid(_halo) or _halo.sprite_frames == null:
		return
	if _wait_timer != null:
		_wait_timer.stop()
	if _safety_timer != null:
		_safety_timer.stop()
	if _halo.animation_finished.is_connected(_on_animation_finished):
		_halo.animation_finished.disconnect(_on_animation_finished)
	_is_playing = true
	_begin_play_retries = 0
	_hide_halo()
	if _halo.sprite_frames.has_animation(HALO_ANIM_NAME):
		var frame_count: = _halo.sprite_frames.get_frame_count(HALO_ANIM_NAME)
		if frame_count > 0:
			_halo.sprite_frames.set_animation_speed(HALO_ANIM_NAME, float(frame_count) / _play_duration_sec)
	_safety_timer.wait_time = _play_duration_sec * 1.5
	_safety_timer.start()
	call_deferred("_begin_halo_animation")


func _begin_halo_animation() -> void :
	if not _is_playing or not is_instance_valid(_halo) or _halo.sprite_frames == null:
		return
	if not _halo.sprite_frames.has_animation(HALO_ANIM_NAME):
		return
	if _halo.animation_finished.is_connected(_on_animation_finished):
		_halo.animation_finished.disconnect(_on_animation_finished)
	_halo.frame = 0
	_halo.play(HALO_ANIM_NAME)
	if not _halo.is_playing():
		if _begin_play_retries < MAX_BEGIN_PLAY_RETRIES:
			_begin_play_retries += 1
			call_deferred("_begin_halo_animation")
		return
	_begin_play_retries = 0
	_halo.visible = true
	_halo.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_animation_finished() -> void :
	_finish_play_phase()


func _on_safety_timeout() -> void :
	if _is_playing:
		_finish_play_phase()


func _finish_play_phase() -> void :
	if not _is_playing:
		return
	_is_playing = false
	_begin_play_retries = 0
	if _safety_timer != null:
		_safety_timer.stop()
	if is_instance_valid(_halo):
		if _halo.animation_finished.is_connected(_on_animation_finished):
			_halo.animation_finished.disconnect(_on_animation_finished)
		_halo.stop()
		_hide_halo()
	BattleRealmHalo.mark_play_cycle_finished(_play_interval_sec)
	if _play_interval_sec <= 0.0:
		_play_cycle()
		return
	_wait_timer.wait_time = _play_interval_sec
	_wait_timer.start()


func _hide_halo() -> void :
	if not is_instance_valid(_halo):
		return
	_halo.stop()
	_halo.frame = 0
	_halo.visible = false


func _on_wait_finished() -> void :
	_play_cycle()


func set_battle_paused(paused: bool) -> void :
	_battle_paused = paused
	if paused:
		if _wait_timer != null:
			_wait_timer.stop()
		if _safety_timer != null:
			_safety_timer.stop()
		_is_playing = false
		_begin_play_retries = 0
		_hide_halo()
	else:
		resume_or_start_playback()

func _exit_tree() -> void :
	if _wait_timer != null:
		_wait_timer.stop()
	if _safety_timer != null:
		_safety_timer.stop()
	if _is_playing:
		_is_playing = false
		BattleRealmHalo.mark_play_cycle_finished(_play_interval_sec)
	_hide_halo()
