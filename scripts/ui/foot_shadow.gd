extends RefCounted
class_name FootShadow



const NODE_NAME: = "FootShadow"
const TEX_SIZE: = Vector2i(128, 64)

const UNDER_SPRITE_FEET_NUDGE_Y: = 3.0

enum Style{SPRITE2D, TEXTURE_RECT}

static var _foot_shadow_tex: ImageTexture = null
static var _opaque_rect_cache: Dictionary = {}


static func clear_texture_cache() -> void :
	_foot_shadow_tex = null
	_opaque_rect_cache.clear()


static func get_texture() -> ImageTexture:
	if _foot_shadow_tex != null:
		return _foot_shadow_tex
	var img: = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	var max_a: float = UIConstants.FOOT_SHADOW_MAX_ALPHA
	var cx: = float(TEX_SIZE.x - 1) * 0.5
	var cy: = float(TEX_SIZE.y - 1) * 0.5
	var rx: = maxf(cx, 1.0)
	var ry: = maxf(cy, 1.0)
	for y in range(TEX_SIZE.y):
		for x in range(TEX_SIZE.x):
			var nx: = (float(x) - cx) / rx
			var ny: = (float(y) - cy) / ry
			var d: = sqrt(nx * nx + ny * ny)
			if d >= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var t: = 1.0 - d
				var a: = max_a * pow(t, 0.75)
				img.set_pixel(x, y, Color(0, 0, 0, a))
	_foot_shadow_tex = ImageTexture.create_from_image(img)
	return _foot_shadow_tex


static func calc_shadow_size(display_size: Vector2) -> Vector2:
	return Vector2(
		display_size.x * UIConstants.FOOT_SHADOW_WIDTH_RATIO, 
		display_size.y * UIConstants.FOOT_SHADOW_HEIGHT_RATIO
	)


static func calc_center(display_size: Vector2, body_offset_y: float = UIConstants.FOOT_SHADOW_BODY_OFFSET_Y) -> Vector2:
	var center: = display_size * 0.5
	return Vector2(
		center.x, 
		center.y + display_size.y * UIConstants.FOOT_SHADOW_Y_DOWN_RATIO + body_offset_y
	)


static func _opaque_cache_key(tex: Texture2D) -> String:
	if tex is AtlasTexture:
		var at: = tex as AtlasTexture
		var atlas: = at.atlas
		var atlas_key: = ""
		if atlas != null:
			atlas_key = atlas.resource_path if atlas.resource_path != "" else str(atlas.get_instance_id())
		return "atlas:%s:%s" % [atlas_key, str(at.region)]
	var path: = tex.resource_path
	return "tex:%s" % (path if path != "" else str(tex.get_instance_id()))



static func get_opaque_rect(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2()
	var key: = _opaque_cache_key(tex)
	if _opaque_rect_cache.has(key):
		return _opaque_rect_cache[key] as Rect2
	var img: Image = tex.get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		_opaque_rect_cache[key] = Rect2()
		return Rect2()
	var used: Rect2i = img.get_used_rect()
	var result: = Rect2(used)
	_opaque_rect_cache[key] = result
	return result



static func calc_under_animated_sprite_layout(
	anim: AnimatedSprite2D, 
	nudge_y: float = UNDER_SPRITE_FEET_NUDGE_Y
) -> Dictionary:
	if not is_instance_valid(anim) or anim.sprite_frames == null:
		return {}
	var anim_name: = anim.animation
	if anim_name == "" or not anim.sprite_frames.has_animation(anim_name):
		var names: = anim.sprite_frames.get_animation_names()
		if names.is_empty():
			return {}
		anim_name = names[0]
	var frame_idx: = anim.frame
	if frame_idx < 0 or frame_idx >= anim.sprite_frames.get_frame_count(anim_name):
		frame_idx = 0
	var frame_tex: = anim.sprite_frames.get_frame_texture(anim_name, frame_idx)
	if frame_tex == null:
		return {}
	var opaque: = get_opaque_rect(frame_tex)
	if opaque.size.x <= 0.0 or opaque.size.y <= 0.0:
		return {}
	var frame_size: = frame_tex.get_size()
	var bottom_center_tex: = Vector2(
		opaque.position.x + opaque.size.x * 0.5, 
		opaque.position.y + opaque.size.y
	)
	var feet_local: = Vector2.ZERO
	if anim.centered:
		var from_center: = bottom_center_tex - frame_size * 0.5
		feet_local = anim.position + Vector2(from_center.x * anim.scale.x, from_center.y * anim.scale.y)
	else:
		feet_local = anim.position + Vector2(bottom_center_tex.x * anim.scale.x, bottom_center_tex.y * anim.scale.y)
	var opaque_display: = Vector2(
		opaque.size.x * absf(anim.scale.x), 
		opaque.size.y * absf(anim.scale.y)
	)
	return {
		"center": feet_local + Vector2(0.0, nudge_y), 
		"display_size": opaque_display, 
	}


static func find_on(parent: Node) -> CanvasItem:
	if parent == null:
		return null
	var node: = parent.get_node_or_null(NODE_NAME)
	if is_instance_valid(node) and node is CanvasItem:
		return node as CanvasItem
	return null


static func set_visible_on(parent: Node, visible: bool) -> void :
	var shadow: = find_on(parent)
	if shadow != null:
		shadow.visible = visible


static func _apply_shadow_at(
	parent: Node, 
	center: Vector2, 
	shadow_size: Vector2, 
	style: Style
) -> CanvasItem:
	if parent == null or shadow_size.x <= 0.0 or shadow_size.y <= 0.0:
		return null
	var tex: = get_texture()
	var existing: = find_on(parent)
	if style == Style.SPRITE2D:
		var spr: Sprite2D = null
		if existing is Sprite2D:
			spr = existing as Sprite2D
		else:
			if existing != null:
				existing.queue_free()
			spr = Sprite2D.new()
			spr.name = NODE_NAME
			parent.add_child(spr)
			parent.move_child(spr, 0)
		spr.texture = tex
		spr.centered = true
		spr.position = center
		spr.z_index = UIConstants.FOOT_SHADOW_Z_INDEX
		var tex_sz: = Vector2(float(TEX_SIZE.x), float(TEX_SIZE.y))
		spr.scale = Vector2(shadow_size.x / tex_sz.x, shadow_size.y / tex_sz.y)
		spr.visible = true
		return spr
	var tr: TextureRect = null
	if existing is TextureRect:
		tr = existing as TextureRect
	else:
		if existing != null:
			existing.queue_free()
		tr = TextureRect.new()
		tr.name = NODE_NAME
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		parent.add_child(tr)
		parent.move_child(tr, 0)
	tr.texture = tex
	tr.size = shadow_size
	tr.custom_minimum_size = shadow_size
	tr.position = center - shadow_size * 0.5
	tr.z_index = UIConstants.FOOT_SHADOW_Z_INDEX
	tr.visible = true
	return tr


static func ensure_on_parent(
	parent: Node, 
	display_size: Vector2, 
	body_offset_y: float = UIConstants.FOOT_SHADOW_BODY_OFFSET_Y, 
	style: Style = Style.SPRITE2D, 
	origin: Vector2 = Vector2.ZERO
) -> CanvasItem:
	if parent == null or display_size.x <= 0.0 or display_size.y <= 0.0:
		return null
	var shadow_size: = calc_shadow_size(display_size)
	var center: = origin + calc_center(display_size, body_offset_y)
	return _apply_shadow_at(parent, center, shadow_size, style)



static func ensure_under_animated_sprite(
	parent: Node, 
	anim: AnimatedSprite2D, 
	nudge_y: float = UNDER_SPRITE_FEET_NUDGE_Y, 
	fallback_display_size: Vector2 = Vector2(200.0, 220.0), 
	fallback_body_offset_y: float = UIConstants.FOOT_SHADOW_PLAYER_BODY_OFFSET_Y, 
	style: Style = Style.SPRITE2D
) -> CanvasItem:
	var layout: = calc_under_animated_sprite_layout(anim, nudge_y)
	if layout.is_empty():
		return ensure_on_parent(parent, fallback_display_size, fallback_body_offset_y, style)
	var display_size: Vector2 = layout.get("display_size", Vector2.ZERO)
	var center: Vector2 = layout.get("center", Vector2.ZERO)
	if display_size.x <= 0.0 or display_size.y <= 0.0:
		return ensure_on_parent(parent, fallback_display_size, fallback_body_offset_y, style)
	return _apply_shadow_at(parent, center, calc_shadow_size(display_size), style)


static func style_for_unit(unit: Node) -> Style:
	if unit is AnimatedSprite2D or unit is Sprite2D:
		return Style.SPRITE2D
	return Style.TEXTURE_RECT
