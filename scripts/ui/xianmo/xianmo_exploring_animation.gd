extends Control

signal exploration_completed

var _event_type: String = ""
var _event_data: Dictionary = {}

@onready var background = $Background
@onready var panel = $CenterContainer / Panel
@onready var stage_label = $CenterContainer / Panel / VBoxContainer / StageLabel
@onready var desc_label = $CenterContainer / Panel / VBoxContainer / DescLabel
@onready var hint_label = $CenterContainer / Panel / VBoxContainer / HintLabel

const EXPLORATION_SCENES = {
	"battle": {
		"stage1": "探险中...", 
		"stage2": "前方传来强大的气息...", 
		"stage3": "敌对阵营的修士！战斗一触即发！"
	}, 
	"treasure": {
		"stage1": "探险中...", 
		"stage2": "发现一处隐蔽的角落...", 
		"stage3": "宝藏！里面有宝物！"
	}, 
	"discovery": {
		"stage1": "探险中...", 
		"stage2": "探索这片神秘的区域...", 
		"stage3": "发现了什么！"
	}, 
	"rescue": {
		"stage1": "探险中...", 
		"stage2": "远处传来求救声...", 
		"stage3": "一位落难的修士需要帮助！"
	}, 
	"empty": {
		"stage1": "探险中...", 
		"stage2": "四处搜寻...", 
		"stage3": "这里空无一物..."
	}, 
	"trap": {
		"stage1": "探险中...", 
		"stage2": "小心前行...", 
		"stage3": "触发了陷阱！"
	}, 
	"spirit_beast": {
		"stage1": "探险中...", 
		"stage2": "灵气波动传来，你循着气息追踪...", 
		"stage3": "发现了一只灵兽的身影！"
	}, 
	"spirit_beast_cub": {
		"stage1": "探险中...", 
		"stage2": "草丛中传来细微的声响...", 
		"stage3": "是一只灵兽幼崽！"
	}, 
	"divine_beast_trace": {
		"stage1": "探险中...", 
		"stage2": "天地异象显现，神兽的气息越来越浓...", 
		"stage3": "神兽的踪迹就在眼前！"
	}, 
	"mutant_beast": {
		"stage1": "探险中...", 
		"stage2": "前方传来奇异的能量波动...", 
		"stage3": "变异灵兽！它的气息与众不同！"
	}, 
	"spirit_beast_guardian": {
		"stage1": "探险中...", 
		"stage2": "古老的遗迹中传来低沉的咆哮...", 
		"stage3": "守护灵兽挡住了去路！"
	}, 
	"spirit_beast_market": {
		"stage1": "探险中...", 
		"stage2": "前方发现一处材料堆放处...", 
		"stage3": "获得建设材料！"
	}, 
	"ancient_cave": {
		"stage1": "探险中...", 
		"stage2": "发现一处被藤蔓遮蔽的洞口...", 
		"stage3": "远古洞窟！里面似乎有宝物！"
	}, 
	"immortal_relic": {
		"stage1": "探险中...", 
		"stage2": "残垣断壁间隐约可见仙气缭绕...", 
		"stage3": "仙府遗迹！宝光闪烁！"
	}, 
	"heavenly_palace": {
		"stage1": "探险中...", 
		"stage2": "金光万丈，祥云缭绕...", 
		"stage3": "天宫遗址！传说中的宝地！"
	}, 
	"medicine_garden": {
		"stage1": "探险中...", 
		"stage2": "浓郁的药香扑面而来...", 
		"stage3": "药园秘境！灵药遍地！"
	}, 
	"spirit_mine": {
		"stage1": "探险中...", 
		"stage2": "灵石的光芒在黑暗中闪烁...", 
		"stage3": "灵矿脉！大量灵石等待开采！"
	}, 
	"scattered_relics": {
		"stage1": "探险中...", 
		"stage2": "路边散落着一些遗物...", 
		"stage3": "散修的遗物！不知留下了什么..."
	}, 
	"xianmo_battlefield": {
		"stage1": "探险中...", 
		"stage2": "战场遗迹，空气中弥漫着肃杀之气...", 
		"stage3": "仙魔战场！地上散落着宝物！"
	}, 
	"treasure_fragment": {
		"stage1": "探险中...", 
		"stage2": "石缝中似乎有什么东西...", 
		"stage3": "藏宝图残片！"
	}, 
	"mysterious_fragment": {
		"stage1": "探险中...", 
		"stage2": "神秘的气息从远处传来...", 
		"stage3": "发现神秘残片！"
	}, 
	"faction_confrontation": {
		"stage1": "探险中...", 
		"stage2": "前方有人影闪动...", 
		"stage3": "敌对阵营的修士！战斗一触即发！"
	}, 
	"demon_attack": {
		"stage1": "探险中...", 
		"stage2": "邪恶的气息突然逼近...", 
		"stage3": "魔修来袭！危险！"
	}, 
	"immortal_guidance": {
		"stage1": "探险中...", 
		"stage2": "一道祥光从天而降...", 
		"stage3": "仙人指路！你感到精力充沛！"
	}, 
	"enlightenment": {
		"stage1": "探险中...", 
		"stage2": "灵气汇聚，心境澄明...", 
		"stage3": "顿悟！对修行有了新的领悟！"
	}, 
	"technique_inheritance": {
		"stage1": "探险中...", 
		"stage2": "古老的符文在眼前浮现...", 
		"stage3": "功法传承！力量涌入体内！"
	}, 
	"immortal_fate": {
		"stage1": "探险中...", 
		"stage2": "祥云笼罩，仙气环绕...", 
		"stage3": "仙缘际会！好运降临！"
	}, 
	"heavenly_blessing": {
		"stage1": "探险中...", 
		"stage2": "天降祥瑞，光芒万丈...", 
		"stage3": "天降祥瑞！宝物从天而降！"
	}, 
	"formation_treasure": {
		"stage1": "探险中...", 
		"stage2": "复杂的阵法纹路显现...", 
		"stage3": "阵法破解！宝物显现！"
	}, 
	"pet_recognition": {
		"stage1": "探险中...", 
		"stage2": "一只灵兽向你靠近...", 
		"stage3": "灵兽愿意认你为主！"
	}, 
	"inheritance_memory": {
		"stage1": "探险中...", 
		"stage2": "前方出现一处古老的遗址遗迹……", 
		"stage3": "兄弟天关遗址！发现尘封已久的【天关令牌】！"
	}, 
	"spirit_vein_training": {
		"stage1": "探险中...", 
		"stage2": "灵脉汇聚，灵气浓郁...", 
		"stage3": "灵脉修炼！修为提升！"
	}, 
	"enlightenment_stone": {
		"stage1": "探险中...", 
		"stage2": "悟道石散发着智慧的光芒...", 
		"stage3": "静心感悟，修行值提升！"
	}, 
	"abundant_spirit_energy": {
		"stage1": "探险中...", 
		"stage2": "此处灵气异常充沛...", 
		"stage3": "灵气充沛！精神焕发！"
	}, 
	"meditation": {
		"stage1": "探险中...", 
		"stage2": "寻一处清净之地打坐...", 
		"stage3": "冥想完成，经验提升！"
	}, 
	"illusion_trap": {
		"stage1": "探险中...", 
		"stage2": "四周景色开始扭曲...", 
		"stage3": "幻阵！被困住了！"
	}, 
	"beast_attack": {
		"stage1": "探险中...", 
		"stage2": "灌木丛中传来低沉的咆哮...", 
		"stage3": "野生灵兽发起攻击！"
	}, 
	"mist_forest": {
		"stage1": "探险中...", 
		"stage2": "浓雾弥漫，能见度骤降...", 
		"stage3": "迷雾森林！迷失了方向..."
	}, 
	"trap_mechanism": {
		"stage1": "探险中...", 
		"stage2": "脚下传来机关启动的声音...", 
		"stage3": "触发陷阱！"
	}, 
	"demon_erosion": {
		"stage1": "探险中...", 
		"stage2": "邪恶的魔气开始侵蚀...", 
		"stage3": "魔气侵蚀！积分受损！"
	}, 
	"nothing_happened": {
		"stage1": "探险中...", 
		"stage2": "四处搜寻，一无所获...", 
		"stage3": "什么也没发现..."
	}
}

const DEFAULT_SCENE = {
	"stage1": "探险中...", 
	"stage2": "探索仙魔界的深处...", 
	"stage3": "似乎发现了什么..."
}

func _ready():
	_setup_style()
	modulate.a = 0

func _setup_style():
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.35, 0.6)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 10
		panel.add_theme_stylebox_override("panel", style)

func setup(event_type: String, event_data: Dictionary = {}):
	_event_type = event_type
	_event_data = event_data

func start_exploration():
	_play_enter_animation()
	await get_tree().create_timer(0.2).timeout

	var scene = EXPLORATION_SCENES.get(_event_type, DEFAULT_SCENE)

	await _show_stage(scene.stage1, 0.5)
	await _show_stage(scene.stage2, 1.0)
	await _show_stage(scene.stage3, 0.5)

	_play_exit_animation()
	await get_tree().create_timer(0.15).timeout
	exploration_completed.emit()

func _show_stage(text: String, duration: float):
	if stage_label:
		stage_label.text = text
		stage_label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(stage_label, "modulate:a", 1.0, 0.15)

	await get_tree().create_timer(duration).timeout

func _play_enter_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	if panel:
		panel.scale = Vector2(0.9, 0.9)
		var tween2 = create_tween()
		tween2.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_exit_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)

static func create_animation(event_type: String, event_data: Dictionary = {}) -> Control:
	var anim = preload("res://ui/xianmo/xianmo_exploring_animation.tscn").instantiate()
	anim.setup(event_type, event_data)
	return anim
