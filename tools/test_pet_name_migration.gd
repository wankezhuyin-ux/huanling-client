extends SceneTree

# 宠物改名自检：名字归一 + 老存档读档后 pet_id 还能不能反查回图鉴键。
# 跑法：Godot --headless --path . --script res://tools/test_pet_name_migration.gd

const GameData = preload("res://scripts/game_data.gd")
const PetClass = preload("res://scripts/pet.gd")

const CASES := {
	"琳琳": "赤翅蛾",
	"独行": "铁嘴鸦",
	"愣头青": "苔背兽",
	"御林兔": "沙耳兔",
	"小叮咚": "滴水蛙",
}


func _init() -> void:
	var fail := 0
	for old in CASES.keys():
		var got: String = GameData.migrate_pet_name(str(old))
		if got != CASES[old]:
			print("FAIL 名字归一：", old, " -> ", got, "（应为 ", CASES[old], "）")
			fail += 1
	# 新名再归一不应被改动
	for fresh in CASES.values():
		if GameData.migrate_pet_name(str(fresh)) != str(fresh):
			print("FAIL 新名被二次改写：", fresh)
			fail += 1
	# 老存档：只有 name、没有 pet_id，靠名字反查图鉴键
	var pet: Pet = PetClass.new()
	pet.from_dict({"name": "琳琳", "level": 5})
	print("老存档读档 → name=", pet.pet_name, " pet_id=", pet.pet_id)
	if pet.pet_name != "赤翅蛾":
		print("FAIL 读档后名字没归一")
		fail += 1
	if pet.pet_id != "linlin":
		print("FAIL 读档后 pet_id 没反查到 linlin")
		fail += 1
	pet.free()
	print("结果：通过" if fail == 0 else "结果：失败 %d 项" % fail)
	quit(0 if fail == 0 else 1)
