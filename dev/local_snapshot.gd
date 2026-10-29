extends RefCounted

# 线上数据快照（只读）。
# 由 local-server/tools/build_snapshot.py 生成 dev/local_snapshot.json。
# 用途：本地联调时展示与线上一致的内容（排行榜、传闻、七日签到、节日配置），
# 不用虚构数据冒充真实玩家。快照过期就重新抓一份并重跑生成脚本。

const SNAPSHOT_PATH := "res://dev/local_snapshot.json"

static var _cache: Dictionary = {}
static var _loaded := false

static func data() -> Dictionary:
	if _loaded:
		return _cache
	_loaded = true
	_cache = {}
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		push_warning("[LocalSnapshot] 缺少线上数据快照: %s" % SNAPSHOT_PATH)
		return _cache
	var text := FileAccess.get_file_as_string(SNAPSHOT_PATH)
	if text.is_empty():
		return _cache
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_cache = parsed
	return _cache

static func available() -> bool:
	return not data().is_empty()

static func captured_at() -> String:
	return str(data().get("captured_at", "未知时间"))

static func server() -> String:
	return str(data().get("server", ""))

static func ranking() -> Array:
	var rows: Variant = data().get("ranking", [])
	return rows if rows is Array else []

static func broadcasts() -> Array:
	var rows: Variant = data().get("broadcasts", [])
	return rows if rows is Array else []

static func signin7() -> Dictionary:
	var value: Variant = data().get("signin7", {})
	return value if value is Dictionary else {}

static func festival() -> Dictionary:
	var value: Variant = data().get("festival", {})
	return value if value is Dictionary else {}

# ---------- 2026-10-23 扩展：线上规则硬数字 / 商店 / 掉落 / 真实数值样本 ----------
# 数据来自对线上服只读端点重放（37 个端点），由 replay/build_calibration.py 合并生成。

static func rules() -> Dictionary:
	var value: Variant = data().get("rules", {})
	return value if value is Dictionary else {}

static func rules_key(key: String) -> Dictionary:
	var value: Variant = rules().get(key, {})
	return value if value is Dictionary else {}

static func shop_items() -> Array:
	var value: Variant = data().get("shop_items", [])
	return value if value is Array else []

static func drop_rates() -> Dictionary:
	var value: Variant = rules_key("drop_rates")
	return value

static func reference_player() -> Dictionary:
	var value: Variant = data().get("player_reference", {})
	return value if value is Dictionary else {}

static func reference_pets() -> Array:
	var value: Variant = data().get("pets_reference", [])
	return value if value is Array else []

static func pet_ranking() -> Array:
	var value: Variant = data().get("pet_ranking", [])
	return value if value is Array else []

static func save_meta() -> Dictionary:
	var value: Variant = data().get("save_meta", {})
	return value if value is Dictionary else {}

static func has_rules() -> bool:
	return not rules().is_empty()

# ---------- 2026-10-23 二次扩展：主城 21 个玩法模块的全量配置 ----------
# 来源：GET /api/gameplay/runtime-config（73.7 KB，一次返回全部模块）
# 由 replay/build_rules_modules.py 写入 local_snapshot.json 的 rules_modules 段。
# 与 rules 段的区别：rules 是"当前账号此刻的状态数字"（如塔 602 层、次数剩几次），
# rules_modules 是"玩法本身的静态配置"（如塔上限 2000、投胎门槛表、掉落权重）。
# 模块 key 为 snake_case，模块内字段名保持与服务端一致（camelCase），不要改名。

const RULES_MODULES_KEY := "rules_modules"

static func rules_modules() -> Dictionary:
	var value: Variant = data().get(RULES_MODULES_KEY, {})
	return value if value is Dictionary else {}

static func rules_modules_meta() -> Dictionary:
	var value: Variant = rules_modules().get("_meta", {})
	return value if value is Dictionary else {}

static func rules_module_names() -> Array:
	var names: Array = []
	for key in rules_modules().keys():
		if str(key) != "_meta":
			names.append(str(key))
	return names

# 同时接受 camelCase（服务端原名）与 snake_case，少一次心智负担。
static func rules_module(module_name: String) -> Dictionary:
	var modules := rules_modules()
	if modules.is_empty():
		return {}
	var key := to_snake(module_name)
	if modules.has(key):
		var value: Variant = modules[key]
		return value if value is Dictionary else {}
	if modules.has(module_name):
		var raw: Variant = modules[module_name]
		return raw if raw is Dictionary else {}
	push_warning("[LocalSnapshot] 未知玩法模块: %s" % module_name)
	return {}

static func has_rules_module(module_name: String) -> bool:
	return not rules_module(module_name).is_empty()

static func to_snake(value: String) -> String:
	var out := ""
	for i in value.length():
		var ch := value.substr(i, 1)
		if ch == ch.to_upper() and ch != ch.to_lower():
			if not out.is_empty():
				out += "_"
			out += ch.to_lower()
		else:
			out += ch
	return out

# 点路径取值：module_value("world_boss", "lootTable.0.name")；取不到返回 fallback。
static func module_value(module_name: String, path: String, fallback: Variant = null) -> Variant:
	var current: Variant = rules_module(module_name)
	if current == null:
		return fallback
	if path.is_empty():
		return current
	for token in path.split("."):
		if current is Dictionary:
			var dict_value: Dictionary = current
			if not dict_value.has(token):
				return fallback
			current = dict_value[token]
		elif current is Array:
			var list_value: Array = current
			if not token.is_valid_int():
				return fallback
			var index: int = token.to_int()
			if index < 0 or index >= list_value.size():
				return fallback
			current = list_value[index]
		else:
			return fallback
	return current

# ---------- 各模块的语义化快捷入口（UI 直接调这些，不要再翻字典） ----------

# 注意：服务端同一字段在不同模块里可能是数组或字典（例如 shengsi_tower.floors 是数组，
# fabao.tiers 是字典）。绝不要写 `(value as Dictionary).size()`——cast 失败返回 null，
# 对 null 调 size() 会让引擎直接段错误。统一用下面三个安全函数取容器。
static func module_count(module_name: String, path: String) -> int:
	var value: Variant = module_value(module_name, path)
	if value is Array:
		var list_value: Array = value
		return list_value.size()
	if value is Dictionary:
		var dict_value: Dictionary = value
		return dict_value.size()
	if value is String:
		var text_value: String = value
		return text_value.length()
	return 0

static func module_list(module_name: String, path: String) -> Array:
	var value: Variant = module_value(module_name, path)
	if value is Array:
		var list_value: Array = value
		return list_value
	return []

static func module_dict(module_name: String, path: String) -> Dictionary:
	var value: Variant = module_value(module_name, path)
	if value is Dictionary:
		var dict_value: Dictionary = value
		return dict_value
	return {}

static func lottery_config() -> Dictionary:
	return rules_module("lottery")

static func tower_config() -> Dictionary:
	return rules_module("tower")

static func treasure_config() -> Dictionary:
	return rules_module("treasure")

static func five_elements_config() -> Dictionary:
	return rules_module("five_elements_dungeon")

static func suit_dungeon_config() -> Dictionary:
	return rules_module("suit_dungeon")

static func atlas_dungeon_config() -> Dictionary:
	return rules_module("atlas_dungeon")

static func brother_tower_config() -> Dictionary:
	return rules_module("brother_tower")

static func world_boss_config() -> Dictionary:
	return rules_module("world_boss")

static func arena_config() -> Dictionary:
	return rules_module("arena")

static func shengsi_tower_config() -> Dictionary:
	return rules_module("shengsi_tower")

static func pet_raise_race_config() -> Dictionary:
	return rules_module("pet_raise_race")

static func pet_soul_config() -> Dictionary:
	return rules_module("pet_soul")

static func pet_mutation_config() -> Dictionary:
	return rules_module("pet_mutation")

static func pet_assist_config() -> Dictionary:
	return rules_module("pet_assist")

static func pet_skill_slots_config() -> Dictionary:
	return rules_module("pet_skill_slots")

static func pet_skill_learn_config() -> Dictionary:
	return rules_module("pet_skill_learn")

static func martial_create_config() -> Dictionary:
	return rules_module("martial_create")

static func gameplay_config() -> Dictionary:
	return rules_module("gameplay")

static func fabao_config() -> Dictionary:
	return rules_module("fabao")

static func weekly_buff_config() -> Dictionary:
	return rules_module("weekly_buff")

static func pet_open_items() -> Array:
	var value: Variant = rules_module("pet_open_items").get("items", [])
	return value if value is Array else []

# 85 个技能定义（key / name / triggerRate / damageRatio …）
static func skills() -> Array:
	var value: Variant = gameplay_config().get("skills", [])
	return value if value is Array else []

static func skill(skill_key: String) -> Dictionary:
	for row in skills():
		if row is Dictionary:
			var entry: Dictionary = row
			if str(entry.get("key", entry.get("name", ""))) == skill_key:
				return entry
	return {}

static func header_note() -> String:
	if not available():
		return "线上数据快照缺失（dev/local_snapshot.json）"
	return "线上快照 · %s · 抓取于 %s" % [server(), captured_at()]
