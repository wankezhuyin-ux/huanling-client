extends SceneTree
# 连击/合击机制探针（开发期用，tools/* 不随包导出）
#
# 目的：不跑完整战斗，只验证
#   ① 触发判定（连击要求人宠敏捷都高于所有怪；合击要求都低于所有怪）
#   ② 一回合内的行动队列到底排了什么（宠物会出手几次）
#
# 用法：Godot --headless --path . --script tools/_combo_probe.gd

const BS := "res://scripts/battle_system.gd"
const PL := "res://scripts/player.gd"
const PT := "res://scripts/pet.gd"


func _mk(player_agi: int, pet_agi: int, monster_agi: int) -> BattleSystem:
	var bs: BattleSystem = load(BS).new()
	var p = load(PL).new()
	p.hp = 100
	p.max_hp = 100
	p.player_name = "言者"
	p.set_meta("bt_snapshot_stats", {"agility": player_agi, "attack": 100, "defense": 50, "max_hp": 100})
	var pet = load(PT).new()
	pet.hp = 100
	pet.pet_name = "宠物"
	pet.set_meta("bt_pet_snapshot_stats", {"agility": pet_agi, "attack": 80, "max_hp": 100})
	bs.player = p
	bs.active_pet = pet
	bs.monsters = [{
		"hp": 9999, "max_hp": 9999, "agility": monster_agi, "attack": 10,
		"defense": 5, "monster_name": "测试怪", "element": "普通",
	}]
	return bs


func _describe(actions: Array) -> String:
	var parts: Array = []
	for a in actions:
		var k: String = str(a.get("kind", "?"))
		if k == "unit":
			parts.append("unit:" + str(a.get("unit", {}).get("type", "?")) + "(" + str(a.get("unit", {}).get("agility", "?")) + ")")
		else:
			parts.append(k)
	return " → ".join(parts)


func _case(title: String, player_agi: int, pet_agi: int, monster_agi: int) -> void:
	var bs := _mk(player_agi, pet_agi, monster_agi)
	var combo: bool = bs._check_combo_condition()
	var joint: bool = bs._check_joint_attack_condition()
	bs._exec_can_combo = combo
	bs._combo_guaranteed_hit = combo
	print("\n===== %s （人敏 %d / 宠敏 %d / 怪敏 %d）=====" % [title, player_agi, pet_agi, monster_agi])
	print("  连击条件=", combo, "  合击条件=", joint)
	var actions: Array = []
	bs._append_local_ally_turn_actions(actions)
	print("  行动队列: ", _describe(actions))
	var pet_hits: int = 0
	var player_hits: int = 0
	for a in actions:
		var k := str(a.get("kind", ""))
		if k == "combo_pet":
			pet_hits += 1
		elif k == "local_joint":
			pet_hits += 1
			player_hits += 1
		elif k == "unit":
			var ut := str(a.get("unit", {}).get("type", ""))
			if ut == "pet":
				pet_hits += 1
			elif ut == "player":
				player_hits += 1
	print("  → 本回合出手次数: 人物 %d 次, 宠物 %d 次" % [player_hits, pet_hits])
	bs.free()


func _initialize() -> void:
	_case("宠物敏捷低于人物（人物先手）", 500, 400, 10)
	_case("宠物敏捷高于人物（宠物先手）", 500, 900, 10)
	_case("合击：人宠都低于怪", 10, 8, 500)
	_case("都不满足（人物高、宠物低）", 500, 8, 10)
	quit(0)
