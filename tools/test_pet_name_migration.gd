extends SceneTree

# 宠物名自检（改名回滚后的版本）
#
# 背景：10-29 那轮给 5 只怪改过名（琳琳→赤翅蛾、独行→铁嘴鸦、愣头青→苔背兽、
# 御林兔→沙耳兔、小叮咚→滴水蛙）。用户要求「所有名称改回原版」，
# 所以现在显示名就是原版名，改名迁移表已清空。
#
# 这个自检锁两件事：
#   1. 原版名直接通过归一（不会被二次改写）；
#   2. 老存档（只有 name、没有 pet_id）读档后仍能靠名字反查回图鉴键。
#
# 跑法：Godot --headless --path . --script tools/test_pet_name_migration.gd

const GameData = preload("res://scripts/game_data.gd")
const PetClass = preload("res://scripts/pet.gd")

## 原版名 → 该怪的 pet_id（反查靠这个）
const CASES := {
	"琳琳": "linlin",
	"独行": "duxing",
	"愣头青": "lèngtóuqīng",
	"御林兔": "yùlíntù",
	"小叮咚": "xiǎodīngdōng",
}


func _init() -> void:
	var fail := 0
	# 1) 原版名归一后应保持原样（改名表已清空，不再有任何转换）
	for name in CASES.keys():
		var got: String = GameData.migrate_pet_name(str(name))
		if got != str(name):
			print("FAIL 归一改动了原版名：", name, " -> ", got)
			fail += 1
	# 2) 老存档：只有 name、没有 pet_id，靠名字反查图鉴键
	for name in CASES.keys():
		var pet: Pet = PetClass.new()
		pet.from_dict({"name": str(name), "level": 5})
		if pet.pet_name != str(name):
			print("FAIL 读档后名字被改了：", name, " -> ", pet.pet_name)
			fail += 1
		if pet.pet_id != str(CASES[name]):
			print("FAIL 读档后 pet_id 反查错：", name, " -> ", pet.pet_id, "（应为 ", CASES[name], "）")
			fail += 1
	print("结果：", "通过" if fail == 0 else ("失败 %d 项" % fail))
	quit(0 if fail == 0 else 1)
