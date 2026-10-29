extends RefCounted
class_name BattleRealmHalo

const DriverScript = preload("res://scripts/ui/battle_realm_halo_driver.gd")

const HALO_FRAME_HEIGHT: = 160
const HALO_ANIM_NAME: = "play"

const HALO_DEFAULT_OFFSET: = Vector2(128.0, 256.0)
const HALO_DEFAULT_DISPLAY_SIZE: = 160.0
const HALO_Z_INDEX_ABOVE: = 25
const HALO_Z_INDEX_BELOW: = 15
const HALO_PLAYER_SPRITE_Z_INDEX: = 20
const HALO_PLAY_INTERVAL_SEC: = 2.0

const HALO_REALM_OFFSET: = {
	"散仙": Vector2(128.0, 126.0), 
	"地仙": Vector2(128.0, 151.0), 
	"天仙": Vector2(128.0, 116.0), 
	"大罗金仙": Vector2(128.0, 116.0), 
	"幻灵天神": Vector2(128.0, 136.0), 
}

const HALO_REALM_Z_INDEX: = {
	"散仙": HALO_Z_INDEX_ABOVE, 
	"地仙": HALO_Z_INDEX_ABOVE, 
	"天仙": HALO_Z_INDEX_ABOVE, 
}

const HALO_REALM_DISPLAY_SIZE: = {
	"散仙": 200.0, 
	"地仙": 200.0, 
	"天仙": 250.0, 
	"大罗金仙": 200.0, 
	"幻灵天神": 200.0, 
}

const HALO_REALM_PLAY_INTERVAL: = {
	"散仙": 4.0, 
	"地仙": 4.0, 
	"天仙": 4.0, 
	"大罗金仙": 4.0, 
	"幻灵天神": 4.0, 
}

const REALM_SHEET_PATHS: = {
	"散仙": "res://assets/guanghuan/sanxiangh.png", 
	"地仙": "res://assets/guanghuan/dixiangh.png", 
	"天仙": "res://assets/guanghuan/tianxiangh.png", 
	"大罗金仙": "res://assets/guanghuan/daluojinxiangh.png", 
	"幻灵天神": "res://assets/guanghuan/tianshengh.png", 
}

const HALO_FRAME_COUNTS: = {
	"散仙": 7, 
	"地仙": 8, 
	"天仙": 4, 
	"大罗金仙": 10, 
	"幻灵天神": 11, 
}

const HALO_FRAME_WIDTH: = {
	"幻灵天神": 160, 
}

const HALO_PLAY_DURATION: = {
	"散仙": 0.2, 
	"地仙": 0.2, 
	"天仙": 0.5, 
	"大罗金仙": 1.0, 
	"幻灵天神": 2.0, 
}

static var _next_play_allowed_msec: int = 0


static func reset_play_schedule() -> void :
	_next_play_allowed_msec = 0


static func mark_play_cycle_finished(interval_sec: float) -> void :
	_next_play_allowed_msec = Time.get_ticks_msec() + int(maxf(interval_sec, 0.0) * 1000.0)


static func get_wait_seconds_before_play() -> float:
	var remain_ms: = _next_play_allowed_msec - Time.get_ticks_msec()
	if remain_ms <= 0:
		return 0.0
	return float(remain_ms) / 1000.0


static func normalize_realm(realm: String) -> String:
	return realm.strip_edges()


static func get_halo_z_index(realm: String) -> int:
	var realm_key: = normalize_realm(realm)
	if HALO_REALM_Z_INDEX.has(realm_key):
		return int(HALO_REALM_Z_INDEX[realm_key])
	return HALO_Z_INDEX_ABOVE


static func is_halo_below_character(realm: String) -> bool:
	return get_halo_z_index(realm) < HALO_PLAYER_SPRITE_Z_INDEX


static func get_halo_offset(realm: String) -> Vector2:
	var realm_key: = normalize_realm(realm)
	if HALO_REALM_OFFSET.has(realm_key):
		return HALO_REALM_OFFSET[realm_key]
	return HALO_DEFAULT_OFFSET


static func get_halo_display_size(realm: String) -> float:
	var realm_key: = normalize_realm(realm)
	if HALO_REALM_DISPLAY_SIZE.has(realm_key):
		return float(HALO_REALM_DISPLAY_SIZE[realm_key])
	return HALO_DEFAULT_DISPLAY_SIZE


static func get_halo_scale(realm: String, frame_height: float) -> Vector2:
	var display_size: = get_halo_display_size(realm)
	var scale_val: = display_size / frame_height if frame_height > 0.0 else 1.0
	return Vector2(scale_val, scale_val)


static func get_play_interval(realm: String) -> float:
	var realm_key: = normalize_realm(realm)
	if HALO_REALM_PLAY_INTERVAL.has(realm_key):
		return float(HALO_REALM_PLAY_INTERVAL[realm_key])
	return HALO_PLAY_INTERVAL_SEC


static func get_play_duration(realm: String) -> float:
	var realm_key: = normalize_realm(realm)
	if HALO_PLAY_DURATION.has(realm_key):
		return float(HALO_PLAY_DURATION[realm_key])
	return 1.0


static func has_halo_for_realm(realm: String) -> bool:
	return REALM_SHEET_PATHS.has(normalize_realm(realm))


static func get_sheet_path(realm: String) -> String:
	return str(REALM_SHEET_PATHS.get(normalize_realm(realm), ""))


static func build_sprite_frames(realm: String, play_duration_sec: float) -> SpriteFrames:
	var realm_key: = normalize_realm(realm)
	if not REALM_SHEET_PATHS.has(realm_key):
		return null
	var path: = get_sheet_path(realm_key)
	var sheet: Texture2D = load(path) as Texture2D
	if sheet == null:
		return null
	var frame_count: int = int(HALO_FRAME_COUNTS.get(realm_key, 1))
	if frame_count <= 0:
		return null
	var frame_height: = float(mini(sheet.get_height(), HALO_FRAME_HEIGHT))
	var frame_width: float = 0.0
	if HALO_FRAME_WIDTH.has(realm_key):
		frame_width = float(HALO_FRAME_WIDTH[realm_key])
	else:
		frame_width = float(sheet.get_width()) / float(frame_count)
	var frames: = SpriteFrames.new()
	frames.add_animation(HALO_ANIM_NAME)
	for fi in range(frame_count):
		var atlas: = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(fi * frame_width, 0.0, frame_width, frame_height)
		frames.add_frame(HALO_ANIM_NAME, atlas)
	frames.set_animation_loop(HALO_ANIM_NAME, false)
	if play_duration_sec > 0.0:
		frames.set_animation_speed(HALO_ANIM_NAME, float(frame_count) / play_duration_sec)
	return frames


static func create_halo_node(realm: String) -> AnimatedSprite2D:
	var realm_key: = normalize_realm(realm)
	var play_duration_sec: = get_play_duration(realm_key)
	var sprite_frames: = build_sprite_frames(realm_key, play_duration_sec)
	if sprite_frames == null:
		return null
	var halo: = AnimatedSprite2D.new()
	halo.name = "RealmHalo"
	halo.centered = true
	var frame_height: = float(HALO_FRAME_HEIGHT)
	if sprite_frames.get_frame_count(HALO_ANIM_NAME) > 0:
		var first_tex = sprite_frames.get_frame_texture(HALO_ANIM_NAME, 0)
		if first_tex != null:
			frame_height = float(first_tex.get_height())
	halo.position = get_halo_offset(realm_key)
	halo.scale = get_halo_scale(realm_key, frame_height)
	halo.sprite_frames = sprite_frames
	halo.visible = false
	return halo


static func attach_periodic_play(halo: AnimatedSprite2D, parent: Node, realm: String) -> Node:
	if halo == null or parent == null:
		return null
	var realm_key: = normalize_realm(realm)
	var play_duration_sec: = get_play_duration(realm_key)
	var play_interval_sec: = get_play_interval(realm_key)
	for child in parent.get_children():
		if child.name == "RealmHaloDriver":
			child.queue_free()
	var driver: BattleRealmHaloDriver = DriverScript.new()
	driver.name = "RealmHaloDriver"
	driver.configure(halo, play_duration_sec, play_interval_sec)
	parent.add_child(driver)
	driver.resume_or_start_playback()
	return driver
