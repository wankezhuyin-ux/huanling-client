#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把前 3 张图那 5 只怪的显示名换成新名。

名字是玩家可见层，撒在好几张表里（宠物图鉴、怪物库、地图刷怪表、礼包文案）。
只改一处会出现「地图上叫铁嘴鸦、收进宠物栏叫独行」的割裂，所以一次扫全。

「独行」只改带引号的形式 —— 代码注释里有「单独行动」，裸替换会把它改坏。
用法：python3 tools/rename_pets.py [--check]
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

OLD_TO_NEW = {
    "琳琳": "赤翅蛾",
    "愣头青": "苔背兽",
    "御林兔": "沙耳兔",
    "小叮咚": "滴水蛙",
}
# 会被别的词包含的名字，必须连同引号一起匹配
QUOTED_ONLY = {
    '"独行"': '"铁嘴鸦"',
}

TARGETS = [
    "scripts/game_data.gd",
    "scripts/pet_data_complete.gd",
    "scripts/evolution_data.gd",
    "scripts/maps_data_complete.gd",
    "scripts/data/monster_database.gd",
    "scripts/inventory_manager.gd",
    "scripts/pet_manager.gd",
    "scripts/game_manager.gd",
    "ui/city/settings_hall.gd",
    "dev/local_maps.json",
    "dev/local_items.gd",
    "dev/local_snapshot.json",
    "dev/local_runtime_config.json",
]


def main() -> int:
    check = "--check" in sys.argv
    total = 0
    for rel in TARGETS:
        path = ROOT / rel
        if not path.exists():
            print(f"跳过（不存在）：{rel}")
            continue
        text = path.read_text(encoding="utf-8")
        hits = 0
        for old, new in OLD_TO_NEW.items():
            n = text.count(old)
            if n:
                hits += n
                text = text.replace(old, new)
        for old, new in QUOTED_ONLY.items():
            n = text.count(old)
            if n:
                hits += n
                text = text.replace(old, new)
        if hits:
            total += hits
            print(f"{'待改' if check else '已改'} {hits:>3} 处：{rel}")
            if not check:
                path.write_text(text, encoding="utf-8")
    print(f"合计 {total} 处")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
