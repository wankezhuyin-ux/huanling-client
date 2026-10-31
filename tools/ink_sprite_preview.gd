extends SceneTree

## 立绘立体感并排预览：同一张立绘，左边原图、右边套 ink_volumetric 着色器。
## 用来肉眼比对「纸片感 vs 3D 水墨体积感」，也方便现场调 shader 参数。
##
## 用法（要开窗口渲染，不能 --headless）：
##   godot --path . --script tools/ink_sprite_preview.gd -- \
##       --sprite=nawahuo --out=/tmp/ink_preview.png
##
## 节点用 AnimatedSprite2D + AtlasTexture（跟游戏里完全一致的画法），
## 这样体积图的 UV 对得上：体积图与源图同版式，shader 里直接按 UV 采样即可。
##
## 可调参数：--relief= --light= --rim= --shadow= --spec= --glow= --ao= --sway=

const SHADER_PATH := "res://assets/shaders/ink_volumetric.gdshader"
const VIEW_SIZE := Vector2i(940, 640)

var _out_path: String = "/tmp/ink_preview.png"
var _sprite_id: String = "baiguzhanshi"
var _shader_path: String = SHADER_PATH
var _params: Dictionary = {}
var _display_scale: float = 400.0 / 256.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_path = arg.substr(6)
		elif arg.begins_with("--sprite="):
			_sprite_id = arg.substr(9)
		elif arg.begins_with("--shader="):
			_shader_path = "res://assets/shaders/" + arg.substr(9) + ".gdshader"
		elif arg.begins_with("--relief="):
			_params["relief"] = float(arg.substr(9))
		elif arg.begins_with("--light="):
			_params["shade_gain"] = float(arg.substr(8))
		elif arg.begins_with("--rim="):
			_params["rim_strength"] = float(arg.substr(6))
		elif arg.begins_with("--shadow="):
			_params["shadow_alpha"] = float(arg.substr(9))
		elif arg.begins_with("--spec="):
			_params["spec_strength"] = float(arg.substr(7))
		elif arg.begins_with("--glow="):
			_params["glow_strength"] = float(arg.substr(7))
		elif arg.begins_with("--ao="):
			_params["ao_strength"] = float(arg.substr(5))
		elif arg == "--noglow":
			_params["glow_strength"] = 0.0
		elif arg == "--norim":
			_params["rim_strength"] = 0.0
		elif arg.begins_with("--sway="):
			_params["sway_pixels"] = float(arg.substr(7))
		elif arg.begins_with("--clarity="):
			_params["clarity"] = float(arg.substr(10))
		elif arg.begins_with("--ink="):
			_params["ink_line"] = float(arg.substr(6))
		elif arg.begins_with("--bleed="):
			_params["ink_bleed"] = float(arg.substr(8))
		elif arg.begins_with("--cav="):
			_params["ink_crevice"] = float(arg.substr(6))
		elif arg.begins_with("--grad="):
			_params["grad_step"] = float(arg.substr(7))
		elif arg.begins_with("--key="):
			var v := arg.substr(6).split(",")
			if v.size() == 3:
				_params["key_dir"] = Vector3(float(v[0]), float(v[1]), float(v[2]))
		elif arg.begins_with("--gain="):
			_params["volume_gain"] = float(arg.substr(7))
		elif arg.begins_with("--neutral="):
			_params["key_neutral"] = float(arg.substr(10))
		elif arg.begins_with("--tint="):
			_params["tint_strength"] = float(arg.substr(7))
		elif arg.begins_with("--scale="):
			_display_scale = float(arg.substr(8))
		elif arg.begins_with("--exp="):
			_params["exposure"] = float(arg.substr(6))
		elif arg.begins_with("--probe="):
			_params["probe_mode"] = int(arg.substr(8))
	_run()


func _run() -> void:
	var vp: SubViewport = SubViewport.new()
	vp.size = VIEW_SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	get_root().add_child(vp)

	var root: Control = Control.new()
	root.size = Vector2(VIEW_SIZE)
	vp.add_child(root)

	var bg: ColorRect = ColorRect.new()
	# 用宣纸底色，和战场背景接近，才看得出「影子压暗」和「亮部提亮」是否成立
	bg.color = Color(0.76, 0.74, 0.70)
	bg.size = Vector2(VIEW_SIZE)
	root.add_child(bg)

	var sheet: Texture2D = load("res://assets/sprites/%s_idle.png" % _sprite_id) as Texture2D
	if sheet == null:
		print("找不到立绘：", _sprite_id)
		quit(1)
		return

	var vol: Texture2D = null
	var vol_path := "res://assets/sprites/vol/%s_idle_vol.png" % _sprite_id
	if ResourceLoader.exists(vol_path):
		vol = load(vol_path) as Texture2D
	else:
		print("提示：缺少体积图 ", vol_path, "（先用 bake_volume_maps.py 烘焙）")

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load(_shader_path) as Shader
	for key in _params.keys():
		mat.set_shader_parameter(key, _params[key])
	if vol != null:
		mat.set_shader_parameter("volume_tex", vol)
		mat.set_shader_parameter("use_volume", 1.0)
	else:
		mat.set_shader_parameter("use_volume", 0.0)

	for i in range(2):
		var frames: SpriteFrames = SpriteFrames.new()
		frames.add_animation("idle")
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(0, 0, 256, 256)
		frames.add_frame("idle", at)

		var anim: AnimatedSprite2D = AnimatedSprite2D.new()
		anim.centered = false
		anim.sprite_frames = frames
		anim.play("idle")
		anim.stop()
		anim.frame = 0
		anim.scale = Vector2(_display_scale, _display_scale)
		anim.position = Vector2(60 + i * 440, 60) if _display_scale > 1.0 else Vector2(160 + i * 440, 240)
		if i == 1:
			anim.material = mat
		root.add_child(anim)

		var label: Label = Label.new()
		label.text = "原图（纸片感）" if i == 0 else "3D 水墨体积感"
		label.position = Vector2(60 + i * 440, 500)
		label.size = Vector2(400, 34)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.18, 0.17, 0.16))
		root.add_child(label)

	for i in range(6):
		await process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png(_out_path)
	print("saved: ", _out_path, " ", img.get_size())
	quit(0)
