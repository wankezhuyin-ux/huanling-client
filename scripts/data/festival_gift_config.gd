class_name FestivalGiftConfig
extends RefCounted




const FESTIVAL_FIVE_ELEMENT_EGGS: = [
	"金属性宠物蛋", "木属性宠物蛋", "水属性宠物蛋", "火属性宠物蛋", "土属性宠物蛋"
]

const FESTIVAL_GOLD_REWARDS: = {
	"gold_50m": {"amount": 50000000, "grant_key": "event_mayday_50m"}, 
	"gold_200m": {"amount": 200000000, "grant_key": "event_mayday_200m"}, 
	"gold_500m": {"amount": 500000000, "grant_key": "event_mayday_500m"}, 
	"gold_1000m": {"amount": 1000000000, "grant_key": "event_mayday_1000m"}, 
}

static func _build_reward_pool(pet_reward_code: String) -> Array:
	return [
		{"code": "gold_50m", "weight": 4550}, 
		{"code": pet_reward_code, "weight": 1000}, 
		{"code": "gold_200m", "weight": 1200}, 
		{"code": "gold_500m", "weight": 57}, 
		{"code": "gold_1000m", "weight": 14}, 
		{"code": "normal_seal_stone", "weight": 1135}, 
		{"code": "advanced_seal_stone", "weight": 426}, 
		{"code": "bronze_chest", "weight": 709}, 
		{"code": "silver_chest", "weight": 284}, 
		{"code": "golden_chest", "weight": 113}, 
		{"code": "limit_equip_one", "weight": 200}, 
		{"code": "gift_5plus", "weight": 113}, 
		{"code": "five_element_egg", "weight": 128}, 
		{"code": "gift_6plus_evo", "weight": 57}, 
		{"code": "gift_7plus_evo", "weight": 14}, 
	]

static func _get_festival_gift_event_bases() -> Array:
	return [
	{
		"id": "mayday_2026", 
		"gift_name": "五一活动礼包", 
		"broadcast_event": "mayday_gift_open", 
		"reward_pool": _build_reward_pool("pet_mutant_anu"), 
		"pet_reward": {
			"code": "pet_mutant_anu", 
			"pet_id": "bianyianu", 
			"pet_name": "变异阿努", 
			"growth_min": 4.0, 
			"growth_max": 6.0, 
			"preset_skill": "splash_lv1", 
		}, 
		"gold_rewards": FESTIVAL_GOLD_REWARDS, 
		"shop_sale": {
			"banner_text": "五一限时：元宝商店全场8折", 
			"start_unix": 1777564800, 
			"end_unix": 1777996800, 
			"discount_rate": 0.8, 
		}, 
		"wild_spawn": {
			"pet_id": "bianyianu", 
			"min_map_level": 500, 
			"spawn_rate": 0.02, 
			"event_tag": "event_mayday_mutant_anu", 
		}, 
		"battle_gift_drop_rate": 1.0, 
		"high_value_priority": ["变异阿努", "10亿金币", "5亿金币", "极限装备", "五行属性宠物蛋", "7+可进化宠礼包"], 
	}, 
	{
		"id": "duanwu_2026", 
		"gift_name": "端午节礼包", 
		"broadcast_event": "duanwu_gift_open", 
		"reward_pool": _build_reward_pool("pet_feicuilong"), 
		"pet_reward": {
			"code": "pet_feicuilong", 
			"pet_id": "feicuilong", 
			"pet_name": "翡翠龙", 
			"growth_min": 4.0, 
			"growth_max": 6.0, 
			"preset_skill": "splash_lv1", 
		}, 
		"gold_rewards": FESTIVAL_GOLD_REWARDS, 
		"shop_sale": {
			"banner_text": "端午限时：元宝商店全场8折", 
			"start_unix": 1781798400, 
			"end_unix": 1782057600, 
			"discount_rate": 0.8, 
		}, 
		"wild_spawn": {
			"pet_id": "feicuilong", 
			"min_map_level": 500, 
			"spawn_rate": 0.000666667, 
			"event_tag": "event_duanwu_feicuilong", 
		}, 
		"battle_gift_drop_rate": 1.0, 
		"high_value_priority": ["翡翠龙", "10亿金币", "5亿金币", "极限装备", "五行属性宠物蛋", "7+可进化宠礼包"], 
	}, 
	{
		"id": "qixi_2026", 
		"gift_name": "七夕节礼包", 
		"broadcast_event": "qixi_gift_open", 
		"reward_pool": _build_reward_pool("pet_qixitu"), 
		"pet_reward": {
			"code": "pet_qixitu", 
			"pet_id": "qixitu", 
			"pet_name": "七夕兔", 
			"growth_min": 4.0, 
			"growth_max": 6.0, 
			"preset_skill": "splash_lv1", 
		}, 
		"gold_rewards": FESTIVAL_GOLD_REWARDS, 
		"shop_sale": {
			"banner_text": "七夕限时：元宝商店全场8折", 
			"start_unix": 1787068800, 
			"end_unix": 1787328000, 
			"discount_rate": 0.8, 
		}, 
		"wild_spawn": {
			"pet_id": "qixitu", 
			"min_map_level": 500, 
			"spawn_rate": 0.000666667, 
			"event_tag": "event_qixi_qixitu", 
		}, 
		"battle_gift_drop_rate": 1.0, 
		"high_value_priority": ["七夕兔", "10亿金币", "5亿金币", "极限装备", "五行属性宠物蛋", "7+可进化宠礼包"], 
	}, 
	]

static var _runtime_overrides: Dictionary = {}
static var _gift_name_index: Dictionary = {}

static func clear_runtime_overrides() -> void :
	_runtime_overrides = {}
	_gift_name_index.clear()

static func apply_runtime_config(payload: Dictionary) -> int:
	clear_runtime_overrides()
	var events_variant: Variant = payload.get("events", {})
	if not events_variant is Dictionary:
		return 0
	var events: Dictionary = events_variant
	for event_id in events.keys():
		var row_variant: Variant = events[event_id]
		if row_variant is Dictionary:
			_runtime_overrides[str(event_id)] = (row_variant as Dictionary).duplicate(true)
	return _runtime_overrides.size()

static func _deep_merge_dict(base: Dictionary, override: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key in override.keys():
		var val: Variant = override[key]
		if val is Dictionary and out.get(key) is Dictionary:
			out[key] = _deep_merge_dict(out[key] as Dictionary, val as Dictionary)
		else:
			out[key] = val
	return out

static func _merge_event_row(base_row: Dictionary) -> Dictionary:
	var event_id: = str(base_row.get("id", "")).strip_edges()
	if event_id.is_empty() or not _runtime_overrides.has(event_id):
		return base_row.duplicate(true)
	return _deep_merge_dict(base_row, _runtime_overrides[event_id] as Dictionary)

static func _runtime_row_to_extra_event(event_id: String, row: Dictionary) -> Dictionary:
	var gift_name: = str(row.get("gift_name", "")).strip_edges()
	if gift_name.is_empty():
		return {}
	var sale: Dictionary = row.get("shop_sale", {}) if row.get("shop_sale") is Dictionary else {}
	var wild: Dictionary = row.get("wild_spawn", {}) if row.get("wild_spawn") is Dictionary else {}
	return {
		"id": event_id, 
		"gift_name": gift_name, 
		"broadcast_event": "%s_gift_open" % event_id, 
		"shop_sale": sale.duplicate(true), 
		"wild_spawn": wild.duplicate(true), 
		"battle_gift_drop_rate": float(row.get("battle_gift_drop_rate", 1.0)), 
	}

static func get_merged_festival_events() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for row in _get_festival_gift_event_bases():
		if row is Dictionary:
			var merged: Dictionary = _merge_event_row(row as Dictionary)
			var eid: = str(merged.get("id", "")).strip_edges()
			out.append(merged)
			if not eid.is_empty():
				seen[eid] = true
	for event_id in _runtime_overrides.keys():
		var eid: = str(event_id).strip_edges()
		if eid.is_empty() or seen.has(eid):
			continue
		var row_variant: Variant = _runtime_overrides[event_id]
		if not (row_variant is Dictionary):
			continue
		var extra: Dictionary = _runtime_row_to_extra_event(eid, row_variant as Dictionary)
		if extra.is_empty():
			continue
		out.append(extra)
	return out

static func _sha256_bytes(text: String) -> PackedByteArray:
	var ctx: = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish()

static func roll_festival_battle_gift_drop(operation_id: String, user_id: String, festival_id: String, rate: float) -> bool:
	var r: = clampf(float(rate), 0.0, 1.0)
	if r >= 1.0:
		return true
	if r <= 0.0:
		return false
	var key: = "%s:%s:%s:fest_battle_gift" % [str(operation_id), str(user_id), str(festival_id)]
	var hash_bytes: PackedByteArray = _sha256_bytes(key)
	var unit: = float((int(hash_bytes[0]) << 24) | (int(hash_bytes[1]) << 16) | (int(hash_bytes[2]) << 8) | int(hash_bytes[3])) / 4294967295.0
	return unit < r

static func resolve_battle_gift_drop_from_defeated(defeated_monsters: Array, operation_id: String, user_id: String) -> String:
	for m in defeated_monsters:
		if m is Dictionary:
			continue
		if not m.has_meta("festival_gift_drop"):
			continue
		var gift: = str(m.get_meta("festival_gift_drop", "")).strip_edges()
		if gift.is_empty():
			continue
		var cfg: = get_festival_config(gift)
		var festival_id: = str(cfg.get("id", "")).strip_edges()
		var rate: = float(cfg.get("battle_gift_drop_rate", 1.0))
		if operation_id.strip_edges().is_empty():
			if randf() >= rate:
				continue
			return gift
		if roll_festival_battle_gift_drop(operation_id, user_id, festival_id, rate):
			return gift
	return ""

static func _ensure_index() -> void :
	if not _gift_name_index.is_empty():
		return
	for row in get_merged_festival_events():
		if row is Dictionary:
			var gift_name: = str(row.get("gift_name", "")).strip_edges()
			if not gift_name.is_empty():
				_gift_name_index[gift_name] = row

static func is_festival_gift(gift_name: String) -> bool:
	_ensure_index()
	return _gift_name_index.has(str(gift_name).strip_edges())

static func get_festival_config(gift_name: String) -> Dictionary:
	_ensure_index()
	var key: = str(gift_name).strip_edges()
	if _gift_name_index.has(key):
		return (_gift_name_index[key] as Dictionary).duplicate(true)
	return {}

static func list_festival_gift_names() -> Array:
	_ensure_index()
	return _gift_name_index.keys()

static func get_active_shop_sale(now_unix: int) -> Dictionary:
	if now_unix <= 0:
		return {}
	for row in get_merged_festival_events():
		if not (row is Dictionary):
			continue
		var sale: Dictionary = row.get("shop_sale", {}) if row.get("shop_sale") is Dictionary else {}
		if sale.is_empty():
			continue
		var start_u: = int(sale.get("start_unix", 0))
		var end_u: = int(sale.get("end_unix", 0))
		if start_u > 0 and end_u > start_u and now_unix >= start_u and now_unix < end_u:
			return {
				"festival_id": str(row.get("id", "")), 
				"gift_name": str(row.get("gift_name", "")), 
				"banner_text": str(sale.get("banner_text", "节日限时：元宝商店全场8折")), 
				"start_unix": start_u, 
				"end_unix": end_u, 
				"discount_rate": float(sale.get("discount_rate", 0.8)), 
			}
	return {}

static func get_active_festival_wild_spawn(now_unix: int) -> Dictionary:
	if now_unix <= 0:
		return {}
	for row in get_merged_festival_events():
		if not (row is Dictionary):
			continue
		var sale: Dictionary = row.get("shop_sale", {}) if row.get("shop_sale") is Dictionary else {}
		var wild: Dictionary = row.get("wild_spawn", {}) if row.get("wild_spawn") is Dictionary else {}
		if sale.is_empty() or wild.is_empty():
			continue
		var start_u: = int(sale.get("start_unix", 0))
		var end_u: = int(sale.get("end_unix", 0))
		if start_u > 0 and end_u > start_u and now_unix >= start_u and now_unix < end_u:
			return {
				"festival_id": str(row.get("id", "")), 
				"gift_name": str(row.get("gift_name", "")), 
				"pet_id": str(wild.get("pet_id", "")).strip_edges(), 
				"min_map_level": maxi(1, int(wild.get("min_map_level", 500))), 
				"spawn_rate": clampf(float(wild.get("spawn_rate", 0.0)), 0.0, 1.0), 
				"event_tag": str(wild.get("event_tag", "")).strip_edges(), 
				"battle_gift_drop_rate": clampf(float(row.get("battle_gift_drop_rate", 1.0)), 0.0, 1.0), 
				"start_unix": start_u, 
				"end_unix": end_u, 
			}
	return {}

static func is_festival_activity_active(now_unix: int) -> bool:
	return not get_active_festival_wild_spawn(now_unix).is_empty()
