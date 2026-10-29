extends SceneTree

# 线上校准包自检（headless）：
# godot --headless --path <project> --script res://dev/_calib_check.gd

func _init() -> void:
	var snap = load("res://dev/local_snapshot.gd")
	print("SNAP_KEYS=", snap.data().keys())
	print("CAPTURED_AT=", snap.captured_at())
	print("RULES=", snap.rules().keys())
	var t: Dictionary = snap.rules_key("tower")
	print("TOWER=", t)
	print("SHOP_COUNT=", snap.shop_items().size())
	print("DROP_COUNT=", snap.drop_rates().size())
	var p: Dictionary = snap.reference_player()
	print("PLAYER_LEVEL=", p.get("level"), " REALM=", p.get("realm"), " GOLD=", p.get("gold"))
	print("PETS_REF=", snap.reference_pets().size(), " PET_RANK=", snap.pet_ranking().size())
	print("META=", snap.save_meta())
	# --- 2026-10-23 主城 21 个玩法模块 ---
	var mods: Array = snap.rules_module_names()
	print("RULES_MODULES=", mods.size(), " ", mods)
	var expectations := {
		"world_boss|bossHp": 1000000000.0,
		"arena|dailyMaxAttempts": 10.0,
		"shengsi_tower|teamMaxMembers": 2.0,
		"brother_tower|waveCount": 10.0,
		"fabao|tiers.normal.mul": 1.0,
		"tower|maxFloor": 2000.0,
		"atlas_dungeon|tiers.basic.waveCount": 20.0,
		"treasure|rewards.0.percent": 0.25,
		"weekly_buff|weekday": 5.0,
	}
	var bad: Array = []
	for probe in expectations.keys():
		var parts: PackedStringArray = str(probe).split("|")
		var got: Variant = snap.module_value(parts[0], parts[1], -1.0)
		# Godot 解析 JSON 后所有数字都是 float，按数值比较而不是字符串。
		if not is_equal_approx(float(got), float(expectations[probe])):
			bad.append("%s expect=%s got=%s" % [probe, expectations[probe], got])
	print("MODULE_PROBES=", expectations.size() - bad.size(), "/", expectations.size(), "" if bad.is_empty() else bad)
	print("SKILLS=", snap.skills().size())
	print("SKILL_SAMPLE=", snap.skill("splash_lv1"))
	print("PET_OPEN_ITEMS=", snap.pet_open_items().size())
	print("CAMEL_ALIAS=", snap.rules_module("worldBoss").size(), " SNAKE=", snap.rules_module("world_boss").size())
	var ui = load("res://dev/local_feature_ui.gd")
	print("UI_SCRIPT_LOADED=", ui != null)
	print("CALIB_CHECK_OK" if bad.is_empty() else "CALIB_CHECK_FAILED")
	quit()
