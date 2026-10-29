extends RefCounted
class_name BattleMonsterDefeatEffect

const DIZZY_SHEET_PATH: = "res://assets/guanghuan/xuanyunxx.png"
const DIZZY_ANIM_NAME: = "spin"
const DIZZY_FRAME_COUNT: = 3
const DIZZY_FRAME_WIDTH: = 100
const DIZZY_FRAME_HEIGHT: = 100
const DIZZY_ANIM_FPS: = 16.0
const DIZZY_DISPLAY_WIDTH: = 100.0
const DEFEATED_SCALE_FACTOR: = 0.5
const DIZZY_NODE_NAME: = "MonsterDizzyEffect"
const DEFEATED_STATIC_NAME: = "MonsterDefeatedStatic"
const BASE_SCALE_META: = "battle_base_scale"


static func remember_base_scale(sprite: CanvasItem) -> void :
	if sprite == null:
		return
	sprite.set_meta(BASE_SCALE_META, sprite.scale)


static func apply_defeated(monster_ui: Control) -> void :
	if monster_ui == null:
		return
	var slot: = monster_ui.get_node_or_null("MonsterSpriteSlot") as Control
	if slot == null:
		return
	var sprite: = slot.get_node_or_null("MonsterSprite")
	if not is_instance_valid(sprite) or not sprite is CanvasItem:
		return
	apply_defeated_on(monster_ui, slot, sprite as CanvasItem, {})


static func clear_defeated(monster_ui: Control) -> void :
	if monster_ui == null:
		return
	var slot: = monster_ui.get_node_or_null("MonsterSpriteSlot") as Control
	var sprite: = slot.get_node_or_null("MonsterSprite") if slot else null
	clear_defeated_on(
		monster_ui, 
		slot, 
		sprite as CanvasItem if is_instance_valid(sprite) and sprite is CanvasItem else null
	)


static func apply_defeated_on(
	parent_ui: Control, 
	slot: Control, 
	sprite: CanvasItem, 
	opts: Dictionary = {}
) -> void :
	if parent_ui == null or slot == null or sprite == null:
		return
	if parent_ui.get_node_or_null(DIZZY_NODE_NAME) != null:
		return
	var flip_horizontal: bool = opts.get("flip_horizontal", false)
	var static_position: Variant = opts.get("static_position", null)
	var static_center: Variant = opts.get("static_center", null)
	var dizzy_position: Variant = opts.get("dizzy_position", null)
	var static_parent: Control = slot
	if opts.get("static_parent") is Control:
		static_parent = opts["static_parent"] as Control
	var static_tex: Texture2D = null
	if opts.get("override_texture") is Texture2D:
		static_tex = opts["override_texture"] as Texture2D
	else:
		static_tex = _extract_static_texture(sprite)
	if static_tex == null:
		return
	remember_base_scale(sprite)
	sprite.visible = false
	FootShadow.set_visible_on(slot, false)
	FootShadow.set_visible_on(parent_ui, false)
	var defeated_static: = _create_defeated_static_sprite(
		static_parent, static_tex, sprite, flip_horizontal, static_position, static_center
	)
	if defeated_static == null:
		sprite.visible = true
		FootShadow.set_visible_on(slot, true)
		FootShadow.set_visible_on(parent_ui, true)
		return
	defeated_static.z_index = maxi(defeated_static.z_index, 22)
	static_parent.add_child(defeated_static)
	var dizzy: = _create_dizzy_anim()
	if dizzy == null:
		return
	dizzy.name = DIZZY_NODE_NAME
	dizzy.z_index = 25
	if dizzy_position is Vector2:
		dizzy.position = dizzy_position
	else:
		dizzy.position = slot.position + _calc_dizzy_position(slot, defeated_static)
	parent_ui.add_child(dizzy)
	parent_ui.move_child(dizzy, -1)


static func clear_defeated_on(parent_ui: Control, slot: Control, sprite: CanvasItem = null) -> void :
	if parent_ui != null:
		var dizzy = parent_ui.get_node_or_null(DIZZY_NODE_NAME)
		if dizzy:
			dizzy.queue_free()
	var defeated_static = null
	if parent_ui != null:
		defeated_static = parent_ui.get_node_or_null(DEFEATED_STATIC_NAME)
	if defeated_static == null and slot != null:
		defeated_static = slot.get_node_or_null(DEFEATED_STATIC_NAME)
	if defeated_static:
		defeated_static.queue_free()
	if slot == null:
		FootShadow.set_visible_on(parent_ui, true)
		return
	if sprite == null or not is_instance_valid(sprite):
		for child_name in ["PetBattleSprite", "PlayerBattleAnim", "MonsterSprite", "CoopPetBattleSprite", "CoopPlayerBattleAnim"]:
			var found = slot.get_node_or_null(child_name)
			if found == null and parent_ui != null:
				found = parent_ui.get_node_or_null(child_name)
			if is_instance_valid(found) and found is CanvasItem:
				sprite = found as CanvasItem
				break
	if is_instance_valid(sprite) and sprite is CanvasItem:
		var sprite_node: = sprite as CanvasItem
		sprite_node.visible = true
		if sprite_node.has_meta(BASE_SCALE_META):
			sprite_node.scale = sprite_node.get_meta(BASE_SCALE_META) as Vector2
	FootShadow.set_visible_on(slot, true)
	FootShadow.set_visible_on(parent_ui, true)


static func estimate_defeated_display_size(
	texture: Texture2D, 
	reference: CanvasItem, 
	flip_horizontal: bool = false
) -> Vector2:
	var tex_size: = _texture_display_size(texture)
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2.ZERO
	var base_scale: Vector2 = (
		reference.get_meta(BASE_SCALE_META) as Vector2
		if reference.has_meta(BASE_SCALE_META) else reference.scale
	)
	var defeated_scale: = base_scale * DEFEATED_SCALE_FACTOR
	if flip_horizontal:
		defeated_scale.x = - absf(defeated_scale.x)
	return Vector2(absf(tex_size.x * defeated_scale.x), absf(tex_size.y * defeated_scale.y))


static func build_ally_defeat_opts_from_anchor(
	sprite: CanvasItem, 
	parent_ui: Control, 
	anchor_in_parent: Vector2, 
	static_offset: Vector2, 
	dizzy_offset: Vector2, 
	flip_horizontal: bool = true, 
	override_texture: Texture2D = null
) -> Dictionary:
	if sprite == null or parent_ui == null:
		return {}
	var static_tex: Texture2D = override_texture if override_texture != null else _extract_static_texture(sprite)
	if static_tex == null:
		return {}
	var display_size: = estimate_defeated_display_size(static_tex, sprite, flip_horizontal)
	if display_size.x <= 0.0 or display_size.y <= 0.0:
		return {}
	var bottom_center: = anchor_in_parent + static_offset
	var static_center: = Vector2(
		bottom_center.x, 
		bottom_center.y - display_size.y * 0.5
	)
	var dizzy_pos: = Vector2(
		bottom_center.x + dizzy_offset.x, 
		bottom_center.y - display_size.y + dizzy_offset.y
	)
	var result: = {
		"flip_horizontal": flip_horizontal, 
		"static_center": static_center, 
		"dizzy_position": dizzy_pos, 
		"static_parent": parent_ui, 
		"display_size": display_size, 
	}
	if override_texture != null:
		result["override_texture"] = override_texture
	return result



static func align_ally_defeat_center_y(
	opts: Dictionary, 
	center_y_in_parent: float, 
	dizzy_offset: Vector2
) -> Dictionary:
	if opts.is_empty():
		return opts
	var display_size: Vector2 = opts.get("display_size", Vector2.ZERO)
	if display_size.y <= 0.0:
		return opts
	var static_center: Vector2 = opts["static_center"]
	var bottom_center_y: = center_y_in_parent + display_size.y * 0.5
	opts["static_center"] = Vector2(static_center.x, center_y_in_parent)
	opts["dizzy_position"] = Vector2(
		static_center.x + dizzy_offset.x, 
		bottom_center_y - display_size.y + dizzy_offset.y
	)
	return opts

static func _extract_static_texture(sprite: CanvasItem) -> Texture2D:
	if sprite is AnimatedSprite2D:
		var spr: = sprite as AnimatedSprite2D
		if spr.sprite_frames == null:
			return null
		for anim_name in ["idle", "attack"]:
			if spr.sprite_frames.has_animation(anim_name):
				var frame_tex: Texture2D = spr.sprite_frames.get_frame_texture(anim_name, 0) as Texture2D
				if frame_tex != null:
					return frame_tex
		var anim_names: = spr.sprite_frames.get_animation_names()
		if not anim_names.is_empty():
			return spr.sprite_frames.get_frame_texture(anim_names[0], 0) as Texture2D
	elif sprite is TextureRect:
		return (sprite as TextureRect).texture
	return null


static func _texture_display_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	if texture is AtlasTexture:
		var atlas_tex: = texture as AtlasTexture
		return atlas_tex.region.size
	return texture.get_size()


static func _create_defeated_static_sprite(
	_slot: Control, 
	texture: Texture2D, 
	reference: CanvasItem, 
	flip_horizontal: bool = false, 
	static_position_override: Variant = null, 
	static_center_override: Variant = null
) -> TextureRect:
	var tex_size: = _texture_display_size(texture)
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return null
	var base_scale: Vector2 = (
		reference.get_meta(BASE_SCALE_META) as Vector2
		if reference.has_meta(BASE_SCALE_META) else reference.scale
	)
	var abs_scale: = Vector2(
		absf(base_scale.x) * DEFEATED_SCALE_FACTOR, 
		absf(base_scale.y) * DEFEATED_SCALE_FACTOR
	)
	var want_neg_x: = flip_horizontal or base_scale.x < 0.0
	var defeated_scale: = Vector2( - abs_scale.x if want_neg_x else abs_scale.x, abs_scale.y)
	var tr: = TextureRect.new()
	tr.name = DEFEATED_STATIC_NAME
	tr.texture = texture
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.size = tex_size
	tr.custom_minimum_size = tex_size
	tr.scale = defeated_scale
	tr.z_index = reference.z_index
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var display_size: = Vector2(absf(tex_size.x * abs_scale.x), absf(tex_size.y * abs_scale.y))
	if static_center_override is Vector2:
		var center: = static_center_override as Vector2
		tr.pivot_offset = tex_size * 0.5
		tr.position = center - tr.pivot_offset
	elif static_position_override is Vector2:
		var pos: = static_position_override as Vector2
		if flip_horizontal:
			tr.position = pos + Vector2(display_size.x, 0.0)
		else:
			tr.position = pos
	elif reference is AnimatedSprite2D and (reference as AnimatedSprite2D).centered:
		tr.position = reference.position - display_size * 0.5
	elif reference is TextureRect:
		var src: = reference as TextureRect
		var src_display: = Vector2(absf(src.size.x * base_scale.x), absf(src.size.y * base_scale.y))
		var src_origin: = src.position
		tr.position = src_origin + (src_display - display_size) * 0.5
	else:
		tr.position = reference.position - display_size * 0.5
	return tr


static func _create_dizzy_anim() -> AnimatedSprite2D:
	var sheet: Texture2D = load(DIZZY_SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var frame_count: = DIZZY_FRAME_COUNT
	var frame_width: = DIZZY_FRAME_WIDTH
	var frame_height: = mini(sheet.get_height(), DIZZY_FRAME_HEIGHT)
	if frame_count <= 0 or frame_width <= 0 or frame_height <= 0:
		return null
	var start_x: = float(sheet.get_width() - frame_count * frame_width) / 2.0
	if start_x < 0.0:
		frame_width = int(float(sheet.get_width()) / float(frame_count))
		start_x = 0.0
	if frame_width <= 0:
		return null
	var scale_val: = DIZZY_DISPLAY_WIDTH / float(frame_width)
	var anim: = AnimatedSprite2D.new()
	anim.centered = true
	anim.offset = Vector2.ZERO
	anim.scale = Vector2(scale_val, scale_val)
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames: = SpriteFrames.new()
	frames.add_animation(DIZZY_ANIM_NAME)
	for fi in range(frame_count):
		var atlas: = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.filter_clip = true
		atlas.region = Rect2(start_x + fi * frame_width, 0, frame_width, frame_height)
		frames.add_frame(DIZZY_ANIM_NAME, atlas)
	frames.set_animation_loop(DIZZY_ANIM_NAME, true)
	frames.set_animation_speed(DIZZY_ANIM_NAME, DIZZY_ANIM_FPS)
	anim.sprite_frames = frames
	anim.play(DIZZY_ANIM_NAME)
	return anim


static func _calc_dizzy_position(slot: Control, sprite: CanvasItem) -> Vector2:
	if sprite is AnimatedSprite2D:
		var spr: = sprite as AnimatedSprite2D
		var tex_size: = Vector2(256.0, 256.0)
		if spr.sprite_frames != null:
			var anim_names: = spr.sprite_frames.get_animation_names()
			if not anim_names.is_empty():
				var anim_name: String = spr.animation if spr.animation != "" else String(anim_names[0])
				var frame_tex: Texture2D = spr.sprite_frames.get_frame_texture(anim_name, 0) as Texture2D
				if frame_tex != null:
					tex_size = _texture_display_size(frame_tex)
		var display_size: = Vector2(absf(tex_size.x * spr.scale.x), absf(tex_size.y * spr.scale.y))
		if spr.centered:
			return Vector2(spr.position.x, spr.position.y - display_size.y * 0.5 - 6.0)
		return Vector2(spr.position.x + display_size.x * 0.5, spr.position.y - 6.0)
	if sprite is TextureRect:
		var tr: = sprite as TextureRect
		var display_size: = Vector2(absf(tr.size.x * tr.scale.x), absf(tr.size.y * tr.scale.y))
		return Vector2(tr.position.x + display_size.x * 0.5, tr.position.y - 6.0)
	return slot.size * 0.5 + Vector2(0.0, -24.0)
