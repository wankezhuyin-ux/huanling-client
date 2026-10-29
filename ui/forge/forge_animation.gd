extends RefCounted
class_name ForgeAnimation

const ForgeConfig = preload("res://scripts/forge/forge_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")

static func play(parent: Control, callback: Callable) -> void :
	var popup = _create_animation_popup(parent)
	var scene_root = Engine.get_main_loop().current_scene
	if scene_root:
		scene_root.add_child(popup)
		popup.popup_centered()
	else:
		parent.add_child(popup)
		popup.popup_centered()

	var anim_label = popup.get_meta("anim_label") as Label
	var desc_label = popup.get_meta("desc_label") as Label
	var progress_bar = popup.get_meta("progress_bar") as ProgressBar

	var stages = ForgeConfig.ANIMATION_STAGES

	for stage in stages:
		if anim_label and is_instance_valid(anim_label):
			anim_label.text = stage.title
		if desc_label and is_instance_valid(desc_label):
			desc_label.text = stage.desc
		if progress_bar and is_instance_valid(progress_bar):
			var tween = parent.create_tween()
			tween.tween_property(progress_bar, "value", stage.progress, stage.duration - 0.1)

		await parent.get_tree().create_timer(stage.duration).timeout

	if is_instance_valid(popup):
		popup.queue_free()

	if callback.is_valid():
		callback.call()

static func _create_animation_popup(parent: Control) -> Window:
	var popup = Window.new()
	popup.title = ""
	popup.borderless = true
	popup.transparent = true
	popup.unresizable = true
	popup.min_size = Vector2(400, 200)
	popup.size = Vector2(400, 200)

	var bg_panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(1, 0.6, 0.2, 1)
	bg_style.corner_radius_top_left = 15
	bg_style.corner_radius_top_right = 15
	bg_style.corner_radius_bottom_left = 15
	bg_style.corner_radius_bottom_right = 15
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	popup.add_child(bg_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 30
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	bg_panel.add_child(vbox)

	var anim_label = Label.new()
	anim_label.text = "🔥 锻造中... 🔥"
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 22)
	anim_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	vbox.add_child(anim_label)

	var desc_label = Label.new()
	desc_label.text = "点燃炉火，五行灵气开始汇聚..."
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(desc_label)

	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(300, 20)
	progress_bar.show_percentage = false
	vbox.add_child(progress_bar)

	popup.set_meta("anim_label", anim_label)
	popup.set_meta("desc_label", desc_label)
	popup.set_meta("progress_bar", progress_bar)

	return popup
