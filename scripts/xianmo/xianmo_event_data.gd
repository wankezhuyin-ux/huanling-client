class_name XianMoEventData

const EVENTS = {
	"spirit_beast": {
		"type": "pet", 
		"name": "灵兽现身", 
		"weight": 3, 
		"score": 1, 
		"capture_rate": 0.5, 
		"growth_range": [5.0, 6.0], 
		"broadcast": false
	}, 
	"spirit_beast_cub": {
		"type": "pet", 
		"name": "灵兽幼崽", 
		"weight": 3, 
		"score": 1, 
		"capture_rate": 0.7, 
		"growth_range": [5.0, 5.5], 
		"broadcast": false
	}, 
	"divine_beast_trace": {
		"type": "pet", 
		"name": "神兽踪迹", 
		"weight": 2, 
		"score": 2, 
		"capture_rate": 0.1, 
		"growth_range": [6.2, 6.8], 
		"broadcast": true
	}, 
	"mutant_beast": {
		"type": "pet", 
		"name": "变异灵兽", 
		"weight": 2, 
		"score": 2, 
		"capture_rate": 0.2, 
		"growth_range": [6.0, 6.5], 
		"broadcast": true
	}, 
	"spirit_beast_guardian": {
		"type": "pet", 
		"name": "灵兽守护者", 
		"weight": 3, 
		"score": 2, 
		"capture_rate": 1.0, 
		"growth_range": [5.5, 6.5], 
		"broadcast": false, 
		"requires_battle": true
	}, 
	"spirit_beast_market": {
		"type": "fortune", 
		"name": "建设材料", 
		"weight": 2, 
		"score": 1, 
		"broadcast": true, 
		"item_reward": {"name": "建设材料", "count": 1}
	}, 
	"ancient_cave": {
		"type": "treasure", 
		"name": "远古洞窟", 
		"weight": 4, 
		"score": 1, 
		"chest_type": "bronze", 
		"broadcast": true
	}, 
	"immortal_relic": {
		"type": "treasure", 
		"name": "仙府遗迹", 
		"weight": 2, 
		"score": 2, 
		"chest_type": "silver", 
		"broadcast": true
	}, 
	"heavenly_palace": {
		"type": "treasure", 
		"name": "天宫遗址", 
		"weight": 1, 
		"score": 3, 
		"chest_type": "gold", 
		"broadcast": true
	}, 
	"medicine_garden": {
		"type": "treasure", 
		"name": "药园秘境", 
		"weight": 5, 
		"score": 1, 
		"broadcast": false, 
		"items": ["cultivation_pill"]
	}, 
	"spirit_mine": {
		"type": "treasure", 
		"name": "灵矿脉", 
		"weight": 4, 
		"score": 1, 
		"broadcast": false, 
		"gold_range": [100000, 500000]
	}, 
	"scattered_relics": {
		"type": "treasure", 
		"name": "散修遗物", 
		"weight": 2, 
		"score": 1, 
		"broadcast": false, 
		"random_item": true
	}, 
	"xianmo_battlefield": {
		"type": "treasure", 
		"name": "仙魔战场", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"chest_type": "random"
	}, 
	"treasure_fragment": {
		"type": "treasure", 
		"name": "藏宝图残片", 
		"weight": 1, 
		"score": 2, 
		"broadcast": false, 
		"fragment": true
	}, 
	"faction_confrontation": {
		"type": "battle", 
		"name": "阵营对峙", 
		"weight": 14, 
		"score_win": 4, 
		"score_lose": 1, 
		"broadcast": false, 
		"mirror_battle": true
	}, 
	"demon_attack": {
		"type": "battle", 
		"name": "魔修来袭", 
		"weight": 6, 
		"score_win": 3, 
		"score_lose": 0, 
		"broadcast": false, 
		"difficulty": "hard"
	}, 
	"immortal_guidance": {
		"type": "fortune", 
		"name": "仙人指路", 
		"weight": 2, 
		"score": 3, 
		"broadcast": false, 
		"action_points_bonus": 3
	}, 
	"enlightenment": {
		"type": "fortune", 
		"name": "悟道机缘", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"cultivation_bonus": 100
	}, 
	"technique_inheritance": {
		"type": "fortune", 
		"name": "功法传承", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"exp_bonus": 10000
	}, 
	"immortal_fate": {
		"type": "fortune", 
		"name": "仙缘际会", 
		"weight": 2, 
		"score": 4, 
		"broadcast": false, 
		"direct_score": true
	}, 
	"heavenly_blessing": {
		"type": "fortune", 
		"name": "天降祥瑞", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"rare_item": true
	}, 
	"formation_treasure": {
		"type": "fortune", 
		"name": "破阵得宝", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"chest_type": "random"
	}, 
	"pet_recognition": {
		"type": "fortune", 
		"name": "灵兽认主", 
		"weight": 1, 
		"score": 3, 
		"capture_rate": 1.0, 
		"growth_range": [5.5, 6.5], 
		"broadcast": true, 
		"no_capture_roll": true
	}, 
	"inheritance_memory": {
		"type": "fortune", 
		"name": "兄弟天关遗址", 
		"weight": 2, 
		"score": 2, 
		"broadcast": true, 
		"item_reward": {"name": "天关令牌", "count": 1}
	}, 
	"spirit_vein_training": {
		"type": "training", 
		"name": "灵脉修炼", 
		"weight": 3, 
		"score": 1, 
		"broadcast": false, 
		"cultivation_bonus": 30
	}, 
	"enlightenment_stone": {
		"type": "training", 
		"name": "悟道石", 
		"weight": 2, 
		"score": 2, 
		"broadcast": false, 
		"cultivation_bonus": 50
	}, 
	"abundant_spirit_energy": {
		"type": "training", 
		"name": "灵气充沛", 
		"weight": 3, 
		"score": 1, 
		"broadcast": false, 
		"cultivation_bonus": 10
	}, 
	"meditation": {
		"type": "training", 
		"name": "打坐冥想", 
		"weight": 2, 
		"score": 1, 
		"broadcast": false, 
		"exp_bonus": 500
	}, 
	"illusion_trap": {
		"type": "trap", 
		"name": "幻阵困局", 
		"weight": 3, 
		"score": 0, 
		"broadcast": false, 
		"action_points_cost": 1
	}, 
	"beast_attack": {
		"type": "trap", 
		"name": "灵兽袭击", 
		"weight": 2, 
		"score": 0, 
		"broadcast": false, 
		"requires_battle": true, 
		"no_score_on_lose": true
	}, 
	"mist_forest": {
		"type": "trap", 
		"name": "迷雾森林", 
		"weight": 2, 
		"score": 0, 
		"broadcast": false, 
		"no_reward": true
	}, 
	"trap_mechanism": {
		"type": "trap", 
		"name": "陷阱机关", 
		"weight": 2, 
		"score": 0, 
		"broadcast": false, 
		"action_points_loss": 1
	}, 
	"demon_erosion": {
		"type": "trap", 
		"name": "魔气侵蚀", 
		"weight": 1, 
		"score": -1, 
		"broadcast": false, 
		"score_loss": true
	}, 
	"nothing_happened": {
		"type": "empty", 
		"name": "无事发生", 
		"weight": 5, 
		"score": 0, 
		"broadcast": false
	}, 
	"mysterious_fragment": {
		"type": "fragment", 
		"name": "神秘残片", 
		"weight": 4, 
		"score": 2, 
		"broadcast": false, 
		"fragment_count": 1
	}
}

const EVENT_DESCRIPTIONS = {
	"spirit_beast": [
		"你在仙魔界中遇到了一只灵兽...", 
		"前方出现了一只灵兽的身影...", 
		"一阵灵气波动传来，你发现了一只灵兽！", 
		"灵兽的咆哮声从远处传来，你循声而去...", 
		"一道灵光闪过，灵兽出现在你的视野中！"
	], 
	"spirit_beast_cub": [
		"你发现了一只灵兽幼崽，它看起来很温顺...", 
		"草丛中传来细微的声响，原来是一只灵兽幼崽！", 
		"一只幼小的灵兽正在玩耍，它似乎不怕人...", 
		"灵兽幼崽好奇地打量着你，眼神清澈..."
	], 
	"divine_beast_trace": [
		"神兽的气息！你追踪到了神兽的踪迹...", 
		"天地异象显现，这是神兽出没的征兆！", 
		"神兽的威压从远处传来，你的心跳加速...", 
		"传说中神兽的足迹，竟然出现在你面前！"
	], 
	"mutant_beast": [
		"一只散发着奇异光芒的变异灵兽出现了！", 
		"这只灵兽的形态与众不同，竟是变异灵兽！", 
		"变异灵兽！它的身上流淌着不凡的气息...", 
		"罕见的变异灵兽，它的力量非同寻常！"
	], 
	"spirit_beast_guardian": [
		"守护灵兽挡住了你的去路，必须击败它才能获得奖励！", 
		"强大的灵兽守护者出现在你面前...", 
		"守护灵兽发出警告的吼声，它不会轻易让路！", 
		"灵兽守护者守护着宝物，你必须战胜它！"
	], 
	"spirit_beast_market": [
		"你在仙魔界发现了一批建设材料，收入囊中。", 
		"路边散落着可用的建设材料，你拾取了一份。", 
		"一处废弃营地里留下了建设材料，你带走一份。", 
		"机缘巧合，你获得了建设材料。"
	], 
	"ancient_cave": [
		"你发现了一个远古洞窟，里面似乎有宝物...", 
		"洞穴深处传来微弱的光芒，你决定一探究竟。", 
		"古老的洞窟入口被藤蔓遮蔽，里面暗藏玄机...", 
		"远古修士的洞府，或许留有珍贵的遗物..."
	], 
	"immortal_relic": [
		"一座仙府遗迹出现在眼前，宝物就在其中！", 
		"仙人的洞府遗迹，不知留下了什么宝物...", 
		"仙府的残垣断壁中，隐约可见宝光闪烁...", 
		"传说中的仙府遗址，机缘就在眼前！"
	], 
	"heavenly_palace": [
		"天宫遗址！这是传说中的天宫遗址！", 
		"金光万丈，你发现了天宫遗址的入口！", 
		"天宫的废墟中，神器的气息若隐若现...", 
		"上古天宫的遗址，无数宝物等待有缘人！"
	], 
	"medicine_garden": [
		"一片药园秘境展现在你面前，灵药遍地！", 
		"仙气缭绕的药园中，生长着珍贵的灵药...", 
		"药园中的灵药散发着浓郁的香气...", 
		"灵药园！这里种植着各种珍稀药材..."
	], 
	"spirit_mine": [
		"灵矿脉！这里蕴含着大量灵石！", 
		"你发现了一处灵矿脉，可以挖掘大量金币！", 
		"灵矿中闪烁着灵石的光芒，收获颇丰！", 
		"灵矿脉的入口就在眼前，里面宝光闪闪..."
	], 
	"scattered_relics": [
		"散修的遗物散落在此处...", 
		"前辈修士的遗物，不知留下了什么...", 
		"一位散修的遗物，或许有意外收获...", 
		"散修的储物袋被遗弃在这里..."
	], 
	"xianmo_battlefield": [
		"仙魔战场的遗迹，地上散落着宝物...", 
		"曾经的仙魔大战之地，遗留着无数宝物...", 
		"仙魔战场的废墟中，宝物随处可见...", 
		"大战的遗迹中，散落着前人的遗物..."
	], 
	"treasure_fragment": [
		"你发现了一张藏宝图残片！", 
		"古老的羊皮纸残片，似乎是藏宝图的一部分...", 
		"藏宝图的残片！收集齐了或许能找到宝藏...", 
		"神秘的残片上绘有奇怪的图案..."
	], 
	"faction_confrontation": [
		"敌对阵营的修士出现在你面前！", 
		"一场遭遇战不可避免！敌对阵营的修士挡住了你的去路...", 
		"敌对阵营的修士向你发起挑战！", 
		"狭路相逢！敌对阵营的修士不愿让路..."
	], 
	"demon_attack": [
		"魔修来袭！这是一场艰难的战斗！", 
		"强大的魔修盯上了你，危险！", 
		"魔修的气息扑面而来，战斗一触即发！", 
		"邪恶的魔修挡住了你的去路！"
	], 
	"immortal_guidance": [
		"仙人指路，你获得了额外的行动力！", 
		"一位仙人为你指明了方向，你感到精力充沛！", 
		"仙人的指点让你豁然开朗，精力倍增！", 
		"仙缘降临！仙人赐予你额外的行动力..."
	], 
	"enlightenment": [
		"你顿悟了！修行值大幅提升！", 
		"悟道机缘降临，你对修行有了新的领悟...", 
		"灵光一闪，你对修行之道有了更深的理解...", 
		"顿悟！修行的瓶颈似乎松动了..."
	], 
	"technique_inheritance": [
		"你获得了功法传承，下次战斗攻击力提升！", 
		"古老的功法传承进入你的脑海...", 
		"功法传承的符文在眼前浮现...", 
		"上古功法的传承之力注入你的体内..."
	], 
	"immortal_fate": [
		"仙缘际会！你获得了大量积分！", 
		"天降仙缘，你获得了意外的收获！", 
		"仙缘降临！好运连连！", 
		"仙人的馈赠！你获得了丰厚的奖励..."
	], 
	"heavenly_blessing": [
		"天降祥瑞！你获得了珍稀道具！", 
		"祥瑞之兆，你获得了珍贵的宝物！", 
		"天降祥瑞，宝物从天而降！", 
		"祥云笼罩，你获得了意外之喜..."
	], 
	"formation_treasure": [
		"你破解了阵法，获得了宝物！", 
		"复杂的阵法被你破解，宝物显现！", 
		"阵法的禁制被解除，宝物显露真容...", 
		"你成功破解了上古阵法！"
	], 
	"pet_recognition": [
		"一只灵兽主动向你示好，它愿意认你为主！", 
		"灵兽感受到了你的气息，决定追随你！", 
		"灵兽似乎对你一见如故，主动靠近...", 
		"缘分使然！灵兽愿意成为你的伙伴..."
	], 
	"inheritance_memory": [
		"你发现了一处兄弟天关远古遗址，残垣断壁间隐约可见宝光……", 
		"仙魔战场深处，一座尘封已久的兄弟天关祭坛出现在眼前！", 
		"拨开蔓草，兄弟天关遗址的石门缓缓开启，里面似乎有遗物……", 
		"古老的兄弟天关遗址静立于此，石匣中封存着一枚令牌……"
	], 
	"spirit_vein_training": [
		"你在灵脉上修炼，修行值提升！", 
		"灵脉汇聚天地灵气，你的修行事半功倍！", 
		"灵脉的灵气浓郁，修炼效果显著！", 
		"灵脉之上，你的修为稳步提升..."
	], 
	"enlightenment_stone": [
		"悟道石前，你静心感悟，修行值提升！", 
		"古老的悟道石散发着智慧的光芒...", 
		"悟道石的灵韵让你有所感悟...", 
		"悟道石前静坐，修行值自然增长..."
	], 
	"abundant_spirit_energy": [
		"此处灵气充沛，你感到精神焕发！", 
		"灵气浓郁之地，你的下次探索将获得额外积分！", 
		"灵气充沛的环境让你精力旺盛！", 
		"此地灵气浓郁，下次闯荡将事半功倍！"
	], 
	"meditation": [
		"你静心打坐冥想，经验值提升！", 
		"冥想中，你的心境更加澄明...", 
		"打坐冥想，经验自然增长...", 
		"静心冥想，你的修为有所提升..."
	], 
	"illusion_trap": [
		"你陷入了幻阵之中！", 
		"幻阵困局！你需要消耗行动力才能脱困...", 
		"幻阵的迷雾让你迷失了方向...", 
		"阵法的幻象将你困住，必须消耗行动力脱困！"
	], 
	"beast_attack": [
		"一只凶猛的灵兽向你发起攻击！", 
		"野生灵兽的袭击！你必须战斗！", 
		"灵兽突然发起攻击，措手不及！", 
		"野生灵兽将你视为猎物！"
	], 
	"mist_forest": [
		"迷雾森林！你迷失了方向...", 
		"浓雾弥漫，你迷失在森林中...", 
		"迷雾笼罩的森林让你分不清方向...", 
		"森林的迷雾太浓，你只能原路返回..."
	], 
	"trap_mechanism": [
		"你触发了陷阱机关！", 
		"机关启动！你受到了伤害...", 
		"陷阱机关被触发，行动力受损！", 
		"隐藏的机关让你措手不及..."
	], 
	"demon_erosion": [
		"魔气侵蚀！你的积分受到了损失！", 
		"邪恶的魔气侵入你的身体...", 
		"魔气侵蚀，积分减少！", 
		"魔气的侵蚀让你损失了积分..."
	], 
	"nothing_happened": [
		"你在仙魔界中探索了一番，什么也没发现...", 
		"四处搜寻，却一无所获...", 
		"探索了许久，却没有发现任何有价值的东西...", 
		"仙魔界中空空如也，今天运气不佳..."
	], 
	"mysterious_fragment": [
		"你发现了一张神秘的藏宝图残片！", 
		"古老的残片上绘有神秘的图案...", 
		"神秘的残片散发着微弱的光芒...", 
		"藏宝图残片！收集齐了或许能找到宝藏..."
	]
}

static func get_random_event() -> Dictionary:
	var total_weight = 0
	var event_weights = []

	for event_id in EVENTS.keys():
		var event_data = EVENTS[event_id]
		total_weight += event_data.weight
		event_weights.append({"id": event_id, "cumulative": total_weight})

	var roll = randi() % total_weight

	for event_weight in event_weights:
		if roll < event_weight.cumulative:
			var event_id = event_weight.id
			var result = EVENTS[event_id].duplicate()
			result["event_id"] = event_id
			return result

	return {}

static func get_event_descriptions(event_id: String) -> Array:
	if EVENT_DESCRIPTIONS.has(event_id):
		return EVENT_DESCRIPTIONS[event_id]
	return ["你遇到了一个事件..."]

static func get_random_description(event_id: String) -> String:
	var descriptions = get_event_descriptions(event_id)
	if descriptions.is_empty():
		return "你遇到了一个事件..."
	return descriptions[randi() % descriptions.size()]

static func get_events_by_type(event_type: String) -> Array:
	var result = []
	for event_id in EVENTS.keys():
		if EVENTS[event_id].type == event_type:
			var event_data = EVENTS[event_id].duplicate()
			event_data["event_id"] = event_id
			result.append(event_data)
	return result

static func get_event(event_id: String) -> Dictionary:
	if EVENTS.has(event_id):
		var result = EVENTS[event_id].duplicate()
		result["event_id"] = event_id
		return result
	return {}

static func get_total_weight() -> int:
	var total = 0
	for event_id in EVENTS.keys():
		total += EVENTS[event_id].weight
	return total
