extends Node
class_name MartialArtsManager

const GameData = preload("res://scripts/game_data.gd")
const VipBenefits = preload("res://scripts/vip_benefits.gd")

var martial_arts: Array = []
var equipped_arts: Array = []

const MAX_MARTIAL_ARTS = 15
const MAX_EQUIPPED = 3
const MAX_EQUIPPED_PASSIVE = 3
const MAX_EQUIPPED_ACTIVE = 1
const CREATE_GOLD_COST = 1000000

const ACTIVE_EFFECT_TYPES: = ["acupoint_seal", "triple_shot", "life_steal"]
const DEFAULT_CRIT_MULTIPLIER: = 1.5
const BASE_CRIT_RATE: = 0.05
const LIFE_STEAL_TRIGGER_RATE: = 0.5

const TRIPLE_SHOT_BOOK_TEMPLATE: = {
	"name": "一箭三雕", 
	"effect_type": "triple_shot", 
	"base_value": 80.0, 
	"desc": "装备后普攻最多同时攻击3个目标；每箭伤害1层80%、9层120%", 
	"realm": "技能书", 
}

const LIFE_STEAL_BOOK_TEMPLATE: = {
	"name": "以战养战", 
	"effect_type": "life_steal", 
	"base_value": 5.0, 
	"desc": "装备后普攻有50%概率按伤害吸血回血（1层5%，9层20%）", 
	"realm": "技能书", 
}


const MARTIAL_EFFECT_TYPE_LABEL_ZH: = {
	"attack": "攻击", 
	"defense": "防御", 
	"hp": "生命", 
	"agility": "敏捷", 
	"crit_rate": "暴击率", 
	"crit_damage": "暴击伤害", 
	"mp_max": "内力", 
	"all_stats": "全属性", 
	"exp": "经验获取", 
	"acupoint_seal": "点穴成功率", 
	"triple_shot": "一箭三雕", 
	"life_steal": "以战养战", 
}

static func is_active_effect_type(effect_type: String) -> bool:
	return String(effect_type).strip_edges() in ACTIVE_EFFECT_TYPES

static func effect_type_label_zh(effect_type: String) -> String:
	var k: = String(effect_type).strip_edges()
	return MARTIAL_EFFECT_TYPE_LABEL_ZH.get(k, "武学效果")

var daily_create_count: int = 0
var _server_count_loaded: bool = false
var _server_success_rate: float = 0.3
var _server_noble_bonus: int = 0

func get_daily_create_limit() -> int:
	var tier: = 0
	if GameManager.instance and GameManager.instance.player:
		tier = VipBenefits.tier_from_player(GameManager.instance.player)
	return VipBenefits.martial_daily_limit(tier)

signal martial_art_learned(art: MartialArt)
signal martial_art_equipped(art: MartialArt)
signal martial_art_unequipped(art: MartialArt)
signal martial_arts_changed
signal daily_count_changed(count: int, max_count: int)
signal martial_create_server_failed(error: String)

func _ready():
	pass

func set_network(net):
	if net:
		net.martial_info_loaded.connect(_on_martial_info_loaded)
		net.martial_info_failed.connect(_on_martial_info_failed)
		net.martial_create_success.connect(_on_martial_create_success)
		net.martial_create_failed.connect(_on_martial_create_failed)

func _on_martial_info_loaded(create_count: int, is_today: bool, server_success_rate: float = 0.3, noble_bonus: int = 0):
	if is_today:
		daily_create_count = create_count
	else:
		daily_create_count = 0
	_server_success_rate = clampf(server_success_rate, 0.0, 1.0)
	_server_noble_bonus = maxi(0, noble_bonus)
	_server_count_loaded = true
	daily_count_changed.emit(daily_create_count, get_daily_create_limit())

func _on_martial_info_failed(_error: String):
	_server_count_loaded = false
	daily_count_changed.emit(daily_create_count, get_daily_create_limit())

func _on_martial_create_success(create_count: int, remaining: int, _new_gold: int = -1, _rolled_success: bool = false, server_success_rate: float = 0.3, noble_bonus: int = 0):
	daily_create_count = create_count
	_server_success_rate = clampf(server_success_rate, 0.0, 1.0)
	_server_noble_bonus = maxi(0, noble_bonus)
	daily_count_changed.emit(daily_create_count, get_daily_create_limit())

func _on_martial_create_failed(error: String):
	martial_create_server_failed.emit(error)

func refresh_server_count():
	if GameManager.instance and GameManager.instance.network:
		GameManager.instance.network.get_martial_info()

func get_remaining_create_count() -> int:
	return get_daily_create_limit() - daily_create_count

func can_create_martial_art() -> bool:
	return _server_count_loaded and daily_create_count < get_daily_create_limit()

func is_server_martial_count_ready() -> bool:
	return _server_count_loaded

func get_server_martial_success_rate() -> float:
	return _server_success_rate

func get_server_martial_noble_bonus() -> int:
	return _server_noble_bonus

func _wait_martial_create_response(net) -> Dictionary:
	# 状态一律放 Dictionary：GDScript 的 lambda 是按值捕获局部变量的，
	# 原来写的是 `var resolved = false` 然后在闭包里 `resolved = true`，
	# 改的只是闭包自己的副本，外层 `while not resolved` 永远看不到，
	# 只能干等满 20 秒超时才返回 —— 玩家点一次「自创武功」就要卡 20 秒。
	var out = {"ok": false, "error": "", "newGold": -1, "rolledSuccess": false,
		"payload": {}, "done": false}
	net.last_martial_create_payload = {}
	var on_ok = func(_c: int, _r: int, new_gold: int = -1, rolled_success: bool = false, _server_success_rate: float = 0.3, _noble_bonus: int = 0):
		if bool(out.done):
			return
		out.done = true
		out.ok = true
		out.newGold = int(new_gold)
		out.rolledSuccess = bool(rolled_success)
		var payload: Dictionary = {}
		if net.last_martial_create_payload is Dictionary:
			payload = net.last_martial_create_payload
		out.payload = payload
	var on_fail = func(err: String):
		if bool(out.done):
			return
		out.done = true
		out.error = err
	net.martial_create_success.connect(on_ok, CONNECT_ONE_SHOT)
	net.martial_create_failed.connect(on_fail, CONNECT_ONE_SHOT)
	var op_id: = "martial_create_%s_%s_%s" % [
		str(net.user_id), 
		str(Time.get_unix_time_from_system()), 
		str(randi())
	]
	net.create_martial_art(op_id)
	var deadline_ms = Time.get_ticks_msec() + 15000
	while not bool(out.done) and Time.get_ticks_msec() < deadline_ms:
		await get_tree().process_frame
	if net.martial_create_success.is_connected(on_ok):
		net.martial_create_success.disconnect(on_ok)
	if net.martial_create_failed.is_connected(on_fail):
		net.martial_create_failed.disconnect(on_fail)
	if not bool(out.done):
		out.error = "服务器响应超时，请勿重复点击；若已扣次以武馆显示为准。"
	return out

func learn_martial_art(realm: String) -> Dictionary:
	var result = {"success": false, "message": "", "art": null, "poem": ""}

	if not _server_count_loaded:
		result.message = "正在同步今日自创次数，请稍候再试。"
		return result

	if daily_create_count >= get_daily_create_limit():
		result.message = "今日自创次数已用完，请明天再来！"
		return result

	if martial_arts.size() >= MAX_MARTIAL_ARTS:
		result.message = "武功栏已满！"
		return result


	if GameManager.instance and GameManager.instance.player:
		var player = GameManager.instance.player
		if player.gold < CREATE_GOLD_COST:
			result.message = "金币不足！自创武功需要%d金币，当前只有%d金币。" % [CREATE_GOLD_COST, player.gold]
			return result

	var net = GameManager.instance.network if GameManager.instance else null
	if not net:
		result.message = "网络不可用。"
		return result

	var server_result = await _wait_martial_create_response(net)
	if not server_result.ok:
		result.message = str(server_result.get("error", "云端验证失败"))
		return result


	if GameManager.instance and GameManager.instance.player:
		var synced_gold: = int(server_result.get("newGold", -1))
		if synced_gold >= 0:
			GameManager.instance.player.gold = synced_gold
		GameManager.instance.gold_changed.emit(GameManager.instance.player.gold)

	if not bool(server_result.get("rolledSuccess", false)):
		result.message = "参悟失败，未能领悟新的武功..."
		return result

	var martial_poems = [
		"灵光一闪，武道真谛显现，顿悟神功！", 
		"心若止水，意如明镜，武道大成！", 
		"参悟天地，感悟玄机，自创绝学！", 
		"气贯长虹，神通自生，武功大成！", 
		"道法自然，武道通神，绝学现世！"
	]
	var poem: String = martial_poems[randi() % martial_poems.size()]


	var payload: Dictionary = server_result.get("payload", {}) if server_result.get("payload", {}) is Dictionary else {}
	var save_data: Variant = payload.get("saveData", null)
	var art_raw: Variant = payload.get("art", null)
	var use_server_art: = bool(payload.get("serverAuthority", false)) and (art_raw is Dictionary or save_data is Dictionary)
	if use_server_art:
		var art: MartialArt = null
		if save_data is Dictionary and not (save_data as Dictionary).is_empty():
			var save_dict: Dictionary = save_data as Dictionary
			GameManager.instance.apply_cloud_save(save_dict, {"authoritative_martial_arts": true})
			GameManager.instance.align_cloud_save_timestamp_from_player_dict(save_dict.get("playerData", null))
			if art_raw is Dictionary:
				art = MartialArt.from_dict(art_raw as Dictionary)
			elif martial_arts.size() > 0:
				art = martial_arts[martial_arts.size() - 1]
		elif art_raw is Dictionary:
			art = MartialArt.from_dict(art_raw as Dictionary)
			if art:
				martial_arts.append(art)
		if art == null:
			result.message = "服务端领悟数据异常，请重新登录同步。"
			return result
		result.success = true
		result.message = "领悟武功：[%s] %s！" % [art.name, art.desc]
		result.art = art
		result.poem = poem
		result["server_persisted"] = true
		martial_art_learned.emit(art)
		martial_arts_changed.emit()
		return result


	result.message = "服务端未返回武功数据，请稍后重试或重新登录同步。"
	return result

func get_equipped_active_count() -> int:
	var n: = 0
	for art in equipped_arts:
		if art != null and is_active_effect_type(art.effect_type):
			n += 1
	return n

func get_equipped_passive_count() -> int:
	var n: = 0
	for art in equipped_arts:
		if art != null and not is_active_effect_type(art.effect_type):
			n += 1
	return n

func get_equipped_active_arts() -> Array:
	var result: Array = []
	for art in equipped_arts:
		if art != null and is_active_effect_type(art.effect_type):
			result.append(art)
	return result

func get_equipped_passive_arts() -> Array:
	var result: Array = []
	for art in equipped_arts:
		if art != null and not is_active_effect_type(art.effect_type):
			result.append(art)
	return result

func get_equip_reject_reason(art: MartialArt) -> String:
	if art == null or not martial_arts.has(art):
		return "武功不存在"
	if art in equipped_arts:
		return "已装备"
	for equipped in equipped_arts:
		if equipped.name == art.name:
			return "same_name"
		if (
			not is_active_effect_type(art.effect_type)
			and not is_active_effect_type(equipped.effect_type)
			and equipped.effect_type == art.effect_type
		):
			return "same_effect_type"
	if is_active_effect_type(art.effect_type):
		if get_equipped_active_count() >= MAX_EQUIPPED_ACTIVE:
			return "active_full"
	else:
		if get_equipped_passive_count() >= MAX_EQUIPPED_PASSIVE:
			return "passive_full"
	return ""

func get_martial_art_by_id(art_id: String) -> MartialArt:
	var target: = String(art_id).strip_edges()
	if target.is_empty():
		return null
	for art in martial_arts:
		if art != null and String(art.id) == target:
			return art
	return null

func create_art_from_skill_book_template(layer: int, book_name: String = "一箭三雕") -> MartialArt:
	var tpl: Dictionary = TRIPLE_SHOT_BOOK_TEMPLATE
	var bn: = String(book_name).strip_edges()
	if bn == "以战养战":
		tpl = LIFE_STEAL_BOOK_TEMPLATE
	elif GameData.MARTIAL_SKILL_BOOKS.has(bn):
		var cfg: Dictionary = GameData.MARTIAL_SKILL_BOOKS[bn]
		tpl = {
			"name": str(cfg.get("martial_name", cfg.get("name", bn))), 
			"effect_type": str(cfg.get("effect_type", "triple_shot")), 
			"base_value": float(cfg.get("base_value", 80.0)), 
			"desc": str(cfg.get("desc", "")), 
			"realm": str(cfg.get("realm", "技能书")), 
		}
	return MartialArt.new(
		str(tpl.get("name", "一箭三雕")), 
		str(tpl.get("effect_type", "triple_shot")), 
		float(tpl.get("base_value", 80.0)), 
		str(tpl.get("desc", "")), 
		clampi(layer, 1, 9), 
		str(tpl.get("realm", "技能书"))
	)

func learn_from_skill_book_local(layer: int, book_name: String = "一箭三雕") -> MartialArt:
	var art: = create_art_from_skill_book_template(layer, book_name)
	martial_arts.append(art)
	martial_art_learned.emit(art)
	martial_arts_changed.emit()
	return art

func can_learn_from_skill_book() -> Dictionary:
	var out: = {"ok": false, "message": ""}
	if martial_arts.size() >= MAX_MARTIAL_ARTS:
		out.message = "武功栏已满！"
		return out
	out.ok = true
	return out


func equip_martial_art(art: MartialArt) -> bool:
	if get_equip_reject_reason(art) != "":
		return false
	equipped_arts.append(art)
	art.equipped = true
	martial_art_equipped.emit(art)
	martial_arts_changed.emit()
	return true

func unequip_martial_art(art: MartialArt) -> bool:
	if not (art in equipped_arts):
		return false

	equipped_arts.erase(art)
	art.equipped = false

	martial_art_unequipped.emit(art)
	martial_arts_changed.emit()
	return true

func forget_martial_art(art: MartialArt) -> bool:
	if not martial_arts.has(art):
		return false

	if art in equipped_arts:
		return false

	martial_arts.erase(art)

	martial_arts_changed.emit()
	return true


func get_equipped_effects() -> Dictionary:
	var effects = {
		"attack": 0, 
		"defense": 0, 
		"agility": 0, 
		"hp": 0, 
		"mp": 0, 
		"all_stats": 0, 
		"exp": 0, 
		"crit_rate": 0.0, 
		"crit_damage": 0.0, 
	}

	for art in equipped_arts:
		if is_active_effect_type(art.effect_type):
			continue
		var value = art.get_effect_value()
		match art.effect_type:
			"attack":
				effects.attack += value
			"defense":
				effects.defense += value
			"agility":
				effects.agility += value
			"hp":
				effects.hp += value
			"mp_max":
				effects.mp += value
			"all_stats":
				effects.all_stats += value
			"exp":
				effects.exp += value
			"crit_rate":
				effects.crit_rate += value
			"crit_damage":
				effects.crit_damage += value

	return effects


func get_battle_crit_stats() -> Dictionary:
	var effects: = get_equipped_effects()
	var rate: = clampf(BASE_CRIT_RATE + float(effects.get("crit_rate", 0.0)) / 100.0, 0.0, 1.0)
	var bonus: = float(effects.get("crit_damage", 0.0))
	var mult: = DEFAULT_CRIT_MULTIPLIER + bonus / 100.0
	return {"rate": rate, "mult": mult}

func get_equipped_life_steal_art() -> MartialArt:
	for art in equipped_arts:
		if art != null and art.effect_type == "life_steal":
			return art
	return null


func get_all_arts() -> Array:
	return martial_arts.duplicate()

func get_equipped_arts() -> Array:
	return equipped_arts.duplicate()

func get_unequipped_arts() -> Array:
	var result = []
	for art in martial_arts:
		if not art.equipped:
			result.append(art)
	return result


func to_dict() -> Dictionary:
	var arts_data = []
	for art in martial_arts:
		arts_data.append(art.to_dict())

	var equipped_ids = []
	for art in equipped_arts:
		equipped_ids.append(art.id)

	return {
		"martial_arts": arts_data, 
		"equipped_ids": equipped_ids, 
		"daily_create_count": daily_create_count
	}

func from_dict(data: Variant = {}):
	if data == null or not data is Dictionary:
		return

	if data.has("martial_arts"):
		martial_arts.clear()
		equipped_arts.clear()

		var arts_array = data.get("martial_arts", [])
		var equipped_ids = data.get("equipped_ids", [])

		for art_dict in arts_array:
			if art_dict is Dictionary:
				var art = MartialArt.from_dict(art_dict)
				martial_arts.append(art)

				if art.id in equipped_ids:
					equipped_arts.append(art)

	if data.has("daily_create_count"):
		daily_create_count = data.get("daily_create_count", 0)


class MartialArt:
	var id: String
	var name: String
	var effect_type: String
	var base_value: float
	var desc: String
	var layer: int = 1
	var realm: String = "凡人"
	var equipped: bool = false

	func _init(p_name: String = "", p_effect: String = "", p_value: float = 0, p_desc: String = "", p_layer: int = 1, p_realm: String = "凡人"):
		id = _generate_id()
		name = p_name
		effect_type = p_effect
		base_value = p_value
		desc = p_desc
		layer = p_layer
		realm = p_realm

	func _generate_id() -> String:
		var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
		var result = ""
		for i in range(8):
			result += chars[randi() % chars.length()]
		return result

	func get_effect_value() -> float:
		var lv: = clampi(layer, 1, 9)

		match effect_type:
			"crit_rate":
				return 10.0 + float(lv - 1) * (10.0 / 8.0)
			"crit_damage":
				return 10.0 + float(lv - 1) * (40.0 / 8.0)
			"life_steal":
				return 5.0 + float(lv - 1) * (15.0 / 8.0)
			_:
				var layer_multiplier = 1.0 + (layer - 1) * 0.025
				return base_value * layer_multiplier

	func get_triple_shot_damage_ratio() -> float:
		var lv: = clampi(layer, 1, 9)
		return 0.8 + float(lv - 1) * 0.05

	func get_life_steal_ratio() -> float:
		return get_effect_value() / 100.0

	func get_effect_description() -> String:
		match effect_type:
			"attack":
				return "攻击力 +%.1f%%" % get_effect_value()
			"defense":
				return "防御力 +%.1f%%" % get_effect_value()
			"agility":
				return "敏捷 +%.1f%%" % get_effect_value()
			"hp":
				return "生命值 +%.1f%%" % get_effect_value()
			"mp_max":
				return "内力 +%.1f%%" % get_effect_value()
			"all_stats":
				return "全属性 +%.1f%%" % get_effect_value()
			"exp":
				return "经验获取 +%.1f%%" % get_effect_value()
			"crit_rate":
				return "暴击率 +%.1f%%" % get_effect_value()
			"crit_damage":
				return "暴击伤害 +%.1f%%（默认暴击1.5倍）" % get_effect_value()
			"acupoint_seal":
				return "点穴成功率 %.1f%%" % get_effect_value()
			"triple_shot":
				return "普攻伤害 %.0f%%（最多3目标）" % (get_triple_shot_damage_ratio() * 100.0)
			"life_steal":
				return "50%%概率吸血，回血为伤害的 %.1f%%" % get_effect_value()
			_:
				return desc

	func to_dict() -> Dictionary:
		return {
			"id": id, 
			"name": name, 
			"effect_type": effect_type, 
			"base_value": base_value, 
			"desc": desc, 
			"layer": layer, 
			"realm": realm, 
			"equipped": equipped
		}

	static func from_dict(data: Dictionary) -> MartialArt:
		var art = MartialArt.new()
		art.id = data.get("id", "")
		art.name = data.get("name", "")
		art.effect_type = data.get("effect_type", "")
		art.base_value = data.get("base_value", 0.0)
		art.desc = data.get("desc", "")
		if str(art.effect_type) == "acupoint_seal":
			art.desc = "有内力时普攻打3目标各1点，点中清空内力"
		art.layer = data.get("layer", 1)
		art.realm = data.get("realm", "凡人")
		art.equipped = data.get("equipped", false)
		return art
