# 由 tools/export_godot.py 自动生成，请勿手改。
# 设计基准 1024x1536；运行期按 s = area.x/1024 宽度贴合、纵向居中。
class_name CityInkData

const DIR := "res://assets/city_ink/"
const DESIGN := Vector2(1024, 1536)
const BG_PAD := 232.0
const BG_SIZE := Vector2(1024, 2000)
const TITLE_RECT := Vector2(0, 0)  # size Vector2(1024, 360)
const TITLE_SIZE := Vector2(1024, 360)
const WING_RECT_R := Vector2(632.75, -74)
const WING_RECT_L := Vector2(31.25, -74)
const WING_SIZE := Vector2(360, 360)

const SIGNS := {
    "tower": {"label": "生死塔", "pos": Vector2(634, 272), "size": Vector2(72, 151.09)},
    "war": {"label": "仙魔挑战", "pos": Vector2(798, 358), "size": Vector2(72, 179.09)},
    "dungeon": {"label": "副本挑战", "pos": Vector2(158, 530), "size": Vector2(72, 179.09)},
    "treasure": {"label": "藏宝洞", "pos": Vector2(894, 678), "size": Vector2(72, 151.09)},
    "sect": {"label": "帮派", "pos": Vector2(738, 948), "size": Vector2(72, 123.09)},
    "martial": {"label": "武道馆", "pos": Vector2(32, 716), "size": Vector2(72, 151.09)},
    "challenge": {"label": "闯天关", "pos": Vector2(198, 234), "size": Vector2(72, 151.09)},
    "furnace": {"label": "乾坤炉", "pos": Vector2(574, 674), "size": Vector2(72, 151.09)},
    "forge": {"label": "打造坊", "pos": Vector2(104, 1108), "size": Vector2(72, 151.09)},
    "shop": {"label": "商店街", "pos": Vector2(810, 1162), "size": Vector2(72, 151.09)},
    "arena": {"label": "竞技", "pos": Vector2(269, 958), "size": Vector2(72, 123.09)},
}

const ROUNDS := {
    "rank": {"label": "排行榜", "pos": Vector2(895.12, 135.12), "size": Vector2(133.76, 133.76)},
    "lucky": {"label": "幸运抽奖", "pos": Vector2(895.12, 235.12), "size": Vector2(133.76, 133.76)},
    "mail": {"label": "邮箱", "pos": Vector2(895.12, 335.12), "size": Vector2(133.76, 133.76)},
    "pet": {"label": "宠物园", "pos": Vector2(895.12, 435.12), "size": Vector2(133.76, 133.76)},
    "store": {"label": "仓库", "pos": Vector2(895.12, 535.12), "size": Vector2(133.76, 133.76)},
}

const GEAR := {"pos": Vector2(903.0, 15.0), "size": Vector2(90.0, 90.0)}

## 底栏：5 枚徽章（战斗/角色/主城/宠物/背包）+ 渐变条
const NAV_W := 142.0
const NAV_H := 130.64
const NAV_STEP := 160.0
const NAV_X0 := 121.0
const NAV_Y := 1352.0
const NAV_LABEL_DY := 146.0
const DOCK_BAR_H := 208.0
const NAV := [
    {"key": "secret", "label": "战斗", "pos": Vector2(121.0, 1352.0), "size": Vector2(142.0, 130.64), "sel": false},
    {"key": "hero", "label": "角色", "pos": Vector2(281.0, 1352.0), "size": Vector2(142.0, 130.64), "sel": false},
    {"key": "sect", "label": "主城", "pos": Vector2(441.0, 1352.0), "size": Vector2(142.0, 130.64), "sel": true},
    {"key": "pet", "label": "宠物", "pos": Vector2(601.0, 1352.0), "size": Vector2(142.0, 130.64), "sel": false},
    {"key": "bag", "label": "背包", "pos": Vector2(761.0, 1352.0), "size": Vector2(142.0, 130.64), "sel": false},
]

## 聊天：左下喇叭 + 水墨面板
const HORN := {"pos": Vector2(17.16, 1351.16), "size": Vector2(89.68, 89.68)}
const CHAT := {"pos": Vector2(20.0, 986.0), "size": Vector2(700.0, 330.0)}
