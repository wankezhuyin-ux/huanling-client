"""清除原服玩家昵称痕迹。

原版有 14 个「赞助钱袋」，道具名直接用原服玩家的网名（醉剑、神的遗愿…），
描述里还写着「XXX 大佬赞助的 10 万金币」，另有 17 处宠物图鉴文案是
「XXX 私人定制」。这些都会被玩家直接看到。

本脚本：
  1. game_data.gd         删除 14 个赞助袋条目；图鉴文案改为中性词
  2. inventory_manager.gd 钱袋配置只保留「钱币袋」
  3. inventory_bag_sort.gd 旧名名单换成 md5 指纹（保留迁移能力，不留明文）
  4. settings_hall.gd     帮助文本删掉「金币袋（大佬赞助）」名单
  5. client-item-names.json 白名单移除 13 个旧名

用法：
  python3 tools/purge_sponsor_traces.py            # 预览
  python3 tools/purge_sponsor_traces.py --apply    # 执行
"""
import argparse
import hashlib
import json
import re
import shutil
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRV = ROOT.parent / "deploy" / "server"

BAG_NAMES = [
    "醉剑", "1万金币袋（醉）", "神的遗愿", "风歌夜曲", "摆烂松", "人间大炮",
    "我的理想", "板砖", "立羽", "铭大大", "长空秋雁", "大橘大利", "人间事", "思念",
]


def h8(s: str) -> str:
    return hashlib.md5(s.encode("utf-8")).hexdigest()[:8]


def backup(path: Path) -> None:
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dst = ROOT / ".restyle-backup" / f"sponsor-{stamp}" / path.relative_to(ROOT.parent)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dst)


def patch_game_data(apply: bool) -> None:
    p = ROOT / "scripts" / "game_data.gd"
    s = p.read_text(encoding="utf-8")
    orig = s
    removed = []
    for n in BAG_NAMES:
        pat = re.compile(r'\n\t"%s":\s*\{[^\n]*\},' % re.escape(n))
        s, k = pat.subn("", s)
        if k:
            removed.append(f"{n}x{k}")
    n_flavor = len(re.findall(r'"[^"]*私人定制"', s))
    s = re.sub(r'"[^"]*私人定制"', '"旧岁遗珍"', s)
    print(f"  game_data.gd: 删赞助袋 {len(removed)} 类 / 图鉴文案改 {n_flavor} 处")
    if apply and s != orig:
        backup(p)
        p.write_text(s, encoding="utf-8")


def patch_inventory_manager(apply: bool) -> None:
    p = ROOT / "scripts" / "inventory_manager.gd"
    s = p.read_text(encoding="utf-8")
    start = s.index("const GOLD_BAG_CONFIG: = {")
    end = s.index("\n}", s.index('"思念"')) + 2
    new_cfg = (
        "const GOLD_BAG_CONFIG: = {\n"
        "\t# 2026-10 起所有旧版钱袋合并成「钱币袋」一种（10 万金币/个）。\n"
        "\t# 旧名识别放在 InventoryBagSort.LEGACY_GOLD_BAG_HASHES（按名称指纹）。\n"
        "\t\"钱币袋\": {\n"
        "\t\t\"amount\": 100000, \n"
        "\t\t\"server_key\": \"coin_bag\", \n"
        "\t}, \n"
        "}"
    )
    s2 = s[:start] + new_cfg + s[end:]
    print(f"  inventory_manager.gd: 钱袋配置 {start}-{end} 收缩为单一条目")
    if apply:
        backup(p)
        p.write_text(s2, encoding="utf-8")


def patch_bag_sort(apply: bool) -> None:
    p = ROOT / "scripts" / "ui" / "inventory_bag_sort.gd"
    s = p.read_text(encoding="utf-8")
    start = s.index("const LEGACY_GOLD_BAG_NAMES: = [")
    end = s.index("]", start) + 1
    hashes = ",\n\t".join('"%s"' % h8(n) for n in BAG_NAMES)
    new_const = (
        "# 旧版钱袋的识别按「名称 md5 前 8 位」比对，避免把历史遗留的玩家网名写进包体。\n"
        "const LEGACY_GOLD_BAG_HASHES: = [\n\t" + hashes + ", \n]"
    )
    s2 = s[:start] + new_const + s[end:]
    s2 = s2.replace(
        "\tif LEGACY_GOLD_BAG_NAMES.has(n):\n\t\treturn true",
        "\tif LEGACY_GOLD_BAG_HASHES.has(n.md5_text().substr(0, 8)):\n\t\treturn true",
    )
    s2 = s2.replace(
        '\treturn desc.contains("赞助") and desc.contains("金币")',
        '\treturn desc.contains("钱袋") and desc.contains("金币")',
    )
    s2 = s2.replace(
        "# 旧存档里还可能有下面这些赞助者命名的钱袋，读档时会被 from_dict 合并成「钱币袋」，\n"
        "# 这里保留名单是为了图标 / 兼容判断（迁移前的一帧、或服务端老存档回包）。",
        "# 旧存档里可能还有历史遗留的同类钱袋，读档时由 from_dict 合并成「钱币袋」；\n"
        "# 这里保留指纹是为了迁移前那一帧、或服务端老存档回包的兼容判断。",
    )
    print("  inventory_bag_sort.gd: 旧名名单 -> md5 指纹表")
    if apply:
        backup(p)
        p.write_text(s2, encoding="utf-8")


def patch_settings_hall(apply: bool) -> None:
    p = ROOT / "ui" / "city" / "settings_hall.gd"
    s = p.read_text(encoding="utf-8")
    old = (
        "[color=cyan]金币袋（大佬赞助）[/color]\\n\\n"
        "• 醉剑、神的遗愿、风歌夜曲、摆烂松、人间大炮、我的理想、板砖、立羽、铭大大、长空秋雁、大橘大利、人间事、思念\\n"
        "• 每个10万金币，野外战斗掉落"
    )
    new = (
        "[color=cyan]钱币袋[/color]\\n\\n"
        "• 打开获得 10 万金币\\n"
        "• 野外战斗随机掉落"
    )
    if old not in s:
        print("  settings_hall.gd: 未匹配到目标段落（跳过）")
        return
    print("  settings_hall.gd: 赞助名单段落 -> 中性说明")
    if apply:
        backup(p)
        p.write_text(s.replace(old, new), encoding="utf-8")


def patch_names_whitelist(apply: bool) -> None:
    p = SRV / "data" / "client-item-names.json"
    data = json.loads(p.read_text(encoding="utf-8"))
    if isinstance(data, dict) and isinstance(data.get("items"), list):
        before = len(data["items"])
        data["items"] = [x for x in data["items"] if x not in BAG_NAMES]
        data["count"] = len(data["items"])
        print(f"  client-item-names.json: items {before} -> {data['count']}")
    elif isinstance(data, dict):
        before = len(data)
        for n in BAG_NAMES:
            data.pop(n, None)
        print(f"  client-item-names.json(dict): {before} -> {len(data)}")
    else:
        before = len(data)
        data = [x for x in data if x not in BAG_NAMES]
        print(f"  client-item-names.json(list): {before} -> {len(data)}")
    if apply:
        bak = SRV / "data" / ("client-item-names.json.bak-sponsor-%s" % time.strftime("%Y%m%d"))
        shutil.copy2(p, bak)
        p.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    print("== 清除原服玩家昵称痕迹 ==")
    patch_game_data(a.apply)
    patch_inventory_manager(a.apply)
    patch_bag_sort(a.apply)
    patch_settings_hall(a.apply)
    patch_names_whitelist(a.apply)
    print("完成" + ("" if a.apply else "（预览，加 --apply 执行）"))


if __name__ == "__main__":
    main()
