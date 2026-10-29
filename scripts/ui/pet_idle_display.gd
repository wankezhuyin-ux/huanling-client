extends RefCounted
class_name PetIdleDisplay

const IDLE_FRAME_SIZE: = 256
const IDLE_ANIM_FPS: = 8.0

static func get_idle_sprite_sheet_path(pet_id: String) -> String:
	# Art-only replacement; keep original pet ID and gameplay data.
	if pet_id.to_lower() == "kǔxínggūi":
		return "res://art/runtime/deer-idle.res"
	return "res://assets/sprites/%s_idle.png" % pet_id.to_lower()

static func try_load_idle_sprite_sheet(pet_id: String) -> Texture2D:
	var path: = get_idle_sprite_sheet_path(pet_id)
	var tex: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if tex == null:
		tex = load(path) as Texture2D
	return tex

static func create_static_image(display_size: Vector2, pet_id: String, static_texture: Texture2D = null) -> TextureRect:
	var texture_rect: = TextureRect.new()
	texture_rect.name = "PetStaticImage"
	texture_rect.custom_minimum_size = display_size
	texture_rect.size = display_size
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if static_texture != null:
		texture_rect.texture = static_texture
	else:
		var am = AssetManager.get_instance()
		if am:
			var tex = am.get_pet_texture(pet_id)
			if tex:
				texture_rect.texture = tex
	return texture_rect

static func create_idle_anim_view(display_size: Vector2, idle_sheet: Texture2D, subject_scale: float = 1.0) -> SubViewportContainer:
	if idle_sheet == null:
		return null
	var anim: = _build_idle_anim_from_sheet(idle_sheet, display_size, subject_scale)
	if anim == null:
		return null
	var viewport_container: = SubViewportContainer.new()
	viewport_container.name = "PetIdleAnimView"
	viewport_container.custom_minimum_size = display_size
	viewport_container.size = display_size
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport: = SubViewport.new()
	viewport.size = Vector2i(display_size)
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	anim.position = display_size * 0.5
	viewport.add_child(anim)
	return viewport_container

static func create_avatar_widget(pet_id: String, display_size: Vector2, static_texture: Texture2D = null, subject_scale: float = 1.0) -> Control:
	var inner: Control = null
	var idle_sheet: = try_load_idle_sprite_sheet(pet_id)
	if idle_sheet != null:
		var anim_view: = create_idle_anim_view(display_size, idle_sheet, subject_scale)
		if anim_view != null:
			inner = anim_view
	if inner == null:
		inner = create_static_image(display_size, pet_id, static_texture)

		if inner and subject_scale > 1.0:
			inner.stretch_mode = TextureRect.STRETCH_SCALE
	return _wrap_with_foot_shadow(inner, display_size)

static func _wrap_with_foot_shadow(inner: Control, display_size: Vector2) -> Control:
	if inner == null:
		return null
	var root: = Control.new()
	root.name = "PetAvatarRoot"
	root.custom_minimum_size = display_size
	root.size = display_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = false
	FootShadow.ensure_on_parent(
		root, 
		display_size, 
		UIConstants.FOOT_SHADOW_BODY_OFFSET_Y, 
		FootShadow.Style.TEXTURE_RECT
	)
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inner)
	return root

static func _build_idle_anim_from_sheet(sprite_sheet: Texture2D, display_size: Vector2, subject_scale: float = 1.0) -> AnimatedSprite2D:
	if sprite_sheet == null:
		return null
	var frame_count: = maxi(1, int(sprite_sheet.get_width() / IDLE_FRAME_SIZE))
	if frame_count <= 0:
		return null
	var anim: = AnimatedSprite2D.new()
	anim.centered = true

	var scale_val: = (display_size.x / float(IDLE_FRAME_SIZE)) * subject_scale
	anim.scale = Vector2(scale_val, scale_val)
	var frames: = SpriteFrames.new()
	frames.add_animation("idle")
	for fi in range(frame_count):
		var atlas: = AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(fi * IDLE_FRAME_SIZE, 0, IDLE_FRAME_SIZE, IDLE_FRAME_SIZE)
		frames.add_frame("idle", atlas)
	frames.set_animation_speed("idle", IDLE_ANIM_FPS)
	frames.set_animation_loop("idle", true)
	anim.sprite_frames = frames
	anim.play("idle")
	return anim
