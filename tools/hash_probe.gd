extends SceneTree

## 临时探针：打印 PetCollectionData.get_bonus_type 依赖的 hash 结果，
## 用于让服务端 Python 复现 Godot 的 String.hash() % 4。

const IDS := [
	"ouou", "linlin", "duduniao", "fengwu", "xiaozhufente", "bianyianu",
	"cong_cong", "kubixiang", "dàdāo", "jiéquándào", "luluniao", "mimi",
	"shuaidaixiang", "wang_wang", "xi_pi", "zhaicitou", "kuiluo", "tiějiǎgūi",
	"duduniao_868026803", "xianmo_pet", "atlas_pet", "a", "abc", "", "灵兽",
]

const BONUS_TYPES := ["attack", "defense", "agility", "hp"]

func _init() -> void:
	var lines: PackedStringArray = []
	for pid in IDS:
		var h: int = pid.hash()
		var idx: int = abs(h) % 4
		lines.append("%s\t%d\t%d\t%s" % [pid if not pid.is_empty() else "<empty>", h, idx, BONUS_TYPES[idx]])
	print("=== HASH PROBE ===")
	for l in lines:
		print(l)
	print("=== END ===")
	quit(0)
