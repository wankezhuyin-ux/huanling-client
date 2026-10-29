extends SceneTree

func _initialize() -> void:
	var ok := true
	ok = _pack("res://art/source/deer-idle.png", "res://art/runtime/deer-hero.res", 768, true) and ok
	ok = _pack("res://art/source/deer-idle.png", "res://art/runtime/deer-idle.res", 256, true) and ok
	ok = _pack("res://art/source/deer-attack.png", "res://art/runtime/deer-attack.res", 256, true) and ok
	ok = _pack("res://art/source/deer-portrait.png", "res://art/runtime/deer-portrait.res", 128, true) and ok
	ok = _pack("res://art/source/ink-home.png", "res://art/runtime/ink-home.res", 0, false) and ok
	print("ART_PACK_OK=" + str(ok))
	quit(0 if ok else 1)

func _pack(src: String, dest: String, cell: int, transparent: bool) -> bool:
	var image := Image.load_from_file(src)
	if image == null or image.is_empty():
		push_error("Cannot load art: " + src)
		return false
	image.convert(Image.FORMAT_RGBA8)
	if transparent:
		var used := image.get_used_rect()
		if used.has_area():
			image = image.get_region(used)
		var usable := cell - 24
		var scale_factor := minf(float(usable) / image.get_width(), float(usable) / image.get_height())
		var size := Vector2i(maxi(1, roundi(image.get_width() * scale_factor)), maxi(1, roundi(image.get_height() * scale_factor)))
		image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(cell, cell, false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		canvas.blend_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i((cell - size.x) / 2, cell - size.y - 12))
		image = canvas
	else:
		image.resize(720, 1280, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(image)
	var err := ResourceSaver.save(tex, dest)
	if err != OK:
		push_error("Cannot save art: " + dest)
	return err == OK
