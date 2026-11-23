#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成《墨境》命名对照全表 v2（Markdown + HTML）+ 同步地图骨架文档。

命名原则（v2，按"普通玩家看得懂"重定）：
1. 字都在常用字范围内，不用生僻字（舣 / 碛 / 甸 / 霓 / 枰 / 楫 / 趾 / 枢 / 蜃 / 蟠 一律不用）。
2. 水墨感靠**意象**，不靠术语：墨、砚、宣、青、白、霜、雪、烟、月、寒、枯、断、残、旧、孤。
3. 玩家熟悉的结构保留（原 / 谷 / 洞 / 桥 / 亭 / 坡 / 路 / 台 / 城 / 门 / 渊 / 锦囊 / X墨）。
4. 只换玩家看得见的显示名，存档 id 一律不动。

用法：
  python3 tools/build_name_table.py            # 只生成对照表
  python3 tools/build_name_table.py --sync-md  # 顺便把地图新名写回骨架文档
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ---------------------------------------------------------------- 已落地
ARTS = [
    ("凡人", [("基础吐纳术", "吐纳功", "全属性"), ("强身健体", "强身术", "生命"),
              ("铁布衫", "铁布衫", "防御·保留原名"), ("疾风步", "疾风步", "敏捷·保留原名"),
              ("蛮牛劲", "蛮牛劲", "攻击·保留原名"), ("蓄灵诀", "蓄墨诀", "内力"),
              ("养生诀", "养生诀", "经验·保留原名")]),
    ("散仙", [("仙鹤吐纳", "仙鹤功", "全属性"), ("金刚不坏", "金刚身", "防御"),
              ("凌波微步", "踏水步", "敏捷"), ("降龙掌", "破山掌", "攻击"),
              ("行气诀", "行墨诀", "内力"), ("长生诀", "长春功", "生命")]),
    ("地仙", [("紫霞神功", "紫云功", "全属性"), ("不动明王", "不动身", "防御"),
              ("踏雪无痕", "踏雪步", "敏捷"), ("乾坤大挪移", "移山劲", "攻击"),
              ("归真诀", "归真诀", "内力·保留原名"), ("九阳神功", "烈阳功", "生命")]),
    ("天仙", [("太玄经", "无字经", "全属性"), ("不灭金身", "不坏身", "防御"),
              ("缩地成寸", "缩地功", "敏捷"), ("万剑归宗", "万剑归一", "攻击"),
              ("凝神诀", "凝墨诀", "内力"), ("不死神功", "不死身", "生命")]),
    ("大罗金仙", [("混元一气", "混元劲", "全属性"), ("万劫不灭", "万劫身", "防御"),
                  ("瞬息万里", "瞬息千里", "敏捷"), ("开天辟地", "开天劲", "攻击"),
                  ("玄罡诀", "玄罡诀", "内力·保留原名"), ("永恒生命", "长生身", "生命")]),
    ("幻灵天神", [("天地同寿", "同寿功", "全属性"), ("绝对防御", "铁壁功", "防御"),
                  ("超越时空", "破空行", "敏捷"), ("毁灭之力", "破灭劲", "攻击"),
                  ("造化玄罡", "造化功", "内力"), ("无限生命", "生生不息", "生命"),
                  ("葵花点穴", "点穴手", "点穴"), ("破军劲", "破军劲", "暴击率·保留原名"),
                  ("重创诀", "重击诀", "暴击伤害")]),
]

ARTS_KEEP = ("保留原名的 6 条（铁布衫、疾风步、蛮牛劲、养生诀、归真诀、玄罡诀）是通用武术词，"
             "玩家一眼懂作用，也不撞任何作品。必须换的是金庸系：凌波微步、降龙掌、紫霞神功、"
             "九阳神功、乾坤大挪移、太玄经、葵花点穴、长生诀、万剑归宗。")

BOOKS = [("一箭三雕", "一击三伤", "普攻最多同时打 3 个目标"),
         ("以战养战", "以血养血", "普攻 50% 概率吸血")]

PET_SKILLS = [
    ("溅射", "溅墨", "一击带到旁边的目标"), ("连射", "连击", "一笔连写，追加多段"),
    ("神佑", "护主", "阵亡时概率回血复生"), ("反击", "反打", "被攻击后反手一记"),
    ("坚固", "硬皮", "基础防御提升"), ("吸血", "饮血", "伤害转化回血"),
    ("迅捷", "轻身", "敏捷提升"), ("长寿", "长命", "生命上限提升"),
    ("强壮", "力壮", "攻击提升"), ("凶猛", "凶性", "暴击伤害提升"),
    ("必杀", "致命", "暴击率提升"), ("自愈", "自复", "每回合自行回血"),
    ("追击", "追杀", "击杀后接着打下一个"), ("忠心", "守主", "概率格挡伤害"),
    ("嘲讽", "挑衅", "把攻击引到自己身上"), ("破甲", "破防", "忽视对方部分防御"),
    ("格挡", "挡伤", "减免本次伤害"),
]

# ---------------------------------------------------------------- 丹药（统一「X墨」）
PILLS = [
    ("小还丹", "小还墨", "小回血"),
    ("中还丹", "中还墨", "中回血"),
    ("大还丹", "大还墨", "大回血"),
    ("回血丹", "回血墨", "持续回血"),
    ("疗伤丹", "疗伤墨", "解除受伤状态"),
    ("金刚药", "金刚墨", "短时防御"),
    ("聚气丹", "聚气墨", "回内力"),
    ("仙露丹", "仙露墨", "回内力（大）"),
    ("神灵丹", "通灵墨", "宠物相关"),
    ("长生丹", "长生墨", "生命上限"),
    ("造化丹", "造化墨", "洗点/重塑"),
]

# 修炼丹用「丹」结尾，和回血药「墨」分开，玩家不会混
CULTIVATION = [
    ("聚灵丹", "蓄灵丹", "修为经验"),
    ("凝神丹", "定神丹", "修为经验（大）"),
    ("悟道仙丹", "开悟丹", "突破境界"),
]

HERBS = [
    ("灵草", "墨草", "最基础药草"),
    ("灵芝", "墨芝", "回血药材"),
    ("天山雪莲", "雪莲", "稀有药材，生于雪岭"),
    ("九转还魂草", "还魂草", "复活类药材"),
    ("龙涎草", "墨涎草", "生津益气"),
]

# ---------------------------------------------------------------- 材料（只改必须改的）
MATERIALS = [
    ("玄铁", "黑铁", "最黑的铁，更好懂"),
    ("灵木", "墨木", "做笔杆的木头"),
    ("寒冰精", "寒冰石", "带寒气的石头"),
    ("仙晶", "墨晶", "灵石一类"),
    ("兄弟天关令牌", "天关令牌", "删掉奇怪的前缀"),
    ("金宠物转生令牌", "金系转生令", "宠物转生"),
    ("木宠物转生令牌", "木系转生令", "宠物转生"),
    ("水宠物转生令牌", "水系转生令", "宠物转生"),
    ("火宠物转生令牌", "火系转生令", "宠物转生"),
    ("土宠物转生令牌", "土系转生令", "宠物转生"),
    ("普通法宝碎片", "一阶法宝碎片", "改成一二三阶，一眼分大小"),
    ("困难法宝碎片", "二阶法宝碎片", "同上"),
    ("地狱法宝碎片", "三阶法宝碎片", "同上"),
    ("史诗法宝碎片", "四阶法宝碎片", "同上"),
    ("传说法宝碎片", "五阶法宝碎片", "同上"),
    ("至尊法宝碎片", "六阶法宝碎片", "同上"),
    ("混沌法宝碎片", "七阶法宝碎片", "同上"),
    ("无上法宝碎片", "八阶法宝碎片", "同上"),
    ("2026纪念法宝碎片", "周年法宝碎片", "带年份会过期"),
    ("普通解封石", "解封石", "去掉多余的「普通」"),
]

KEEP_NAMES = (
    "精铁 金刚石 烈火石 天雷石 星辰砂 龙鳞 凤羽 混沌石 建设材料 套装强化石 幻化符 强化石 "
    "宠装碎片 法宝洗练石 法宝重置石 宠装强化石 高级解封石 宠物补章器 钱币袋 "
    "金之精华 木之精华 水之精华 火之精华 土之精华 风之精华 "
    "金之灵石 木之灵石 水之灵石 火之灵石 土之灵石 风之灵石 "
    "极限武器 极限衣服 极限鞋子 极限血佩 极限内带"
).split() + [
    "%s%s" % (q, p) for q in ("普通", "优秀", "稀有", "史诗", "传说")
    for p in ("武器", "衣服", "帽子", "鞋子", "饰品")
] + [
    "%s套装" % n for n in ("青云", "玄灵", "地脉", "天羽", "金罡", "大罗", "神威", "至尊",
                          "混沌", "无极", "太虚", "盘古", "女娲", "伏羲", "轩辕", "蚩尤",
                          "刑天", "共工", "永恒", "无上", "未知")
]

MAT_KEEP = ("以下保留原名：精铁、金刚石、烈火石、天雷石、星辰砂、龙鳞、凤羽、混沌石、建设材料、"
            "套装强化石、幻化符、强化石、宠装碎片、法宝洗练石、法宝重置石、宠装强化石、"
            "五行精华、五行灵石、高级解封石、极限系列（武器/衣服/鞋子/血佩/内带）。"
            "这些名字玩家本来就懂，也不含任何原游戏特征。")

# ---------------------------------------------------------------- 装备（只改「测试」）
GEAR = [("%s%s" % (q, p), "%s%s" % (n, p), "保留部位词，玩家靠名字认部位")
        for q, n in [("测试", "试炼")] for p in ["武器", "衣服", "帽子", "鞋子", "饰品"]]

GEAR_KEEP = ("普通 / 优秀 / 稀有 / 史诗 / 传说 五档共 25 件保留原名。"
             "这五个词玩家天天见，换成素/染/皴/泼/焦反而认不出强弱，而且它们不含任何原游戏特征。")

EGGS = [
    ("5+宠物蛋", "五阶宠物蛋", "五阶宠物"),
    ("火属性宠物蛋", "火纹蛋", "火"),
    ("水属性宠物蛋", "水纹蛋", "水"),
    ("木属性宠物蛋", "木纹蛋", "木"),
    ("金属性宠物蛋", "金纹蛋", "金"),
    ("土属性宠物蛋", "土纹蛋", "土"),
    ("金变异宠物蛋", "金纹异蛋", "金 · 变异"),
    ("木变异宠物蛋", "木纹异蛋", "木 · 变异"),
    ("水变异宠物蛋", "水纹异蛋", "水 · 变异"),
    ("火变异宠物蛋", "火纹异蛋", "火 · 变异"),
    ("土变异宠物蛋", "土纹异蛋", "土 · 变异"),
]

SOULS = [("金魂魄50", "金魂魄", "去掉数字后缀"),
         ("木魂魄50", "木魂魄", "同上"),
         ("水魂魄50", "水魂魄", "同上"),
         ("火魂魄50", "火魂魄", "同上"),
         ("土魂魄50", "土魂魄", "同上")]

CHESTS = [("青铜宝箱", "青铜匣", "低阶宝箱"),
          ("白银宝箱", "白银匣", "中阶宝箱"),
          ("黄金宝箱", "黄金匣", "高阶宝箱"),
          ("藏宝箱", "藏宝匣", "藏宝图奖励")]

# ---------------------------------------------------------------- 礼包（「礼包」→「锦囊」，其余原词不动）
_CN = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
       "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]

GIFTS = [
    ("双倍经验丹", "双倍经验符", "双倍收益"),
    ("双倍经验丹(月)", "双倍经验符·月", "月卡"),
    ("双倍经验丹(周)", "双倍经验符·周", "周卡"),
    ("天关礼包", "天关锦囊", "天关奖励"),
    ("兄弟天关礼包", "天关组队锦囊", "组队天关"),
    ("生死塔参与礼包", "生死塔参与锦囊", "生死塔参与奖"),
    ("世界boss礼包", "世界首领锦囊", "世界首领奖励"),
    ("冠军礼包", "冠军锦囊", "比武第一"),
    ("亚军礼包", "亚军锦囊", "比武第二"),
    ("季军礼包", "季军锦囊", "比武第三"),
    ("十强礼包", "十强锦囊", "比武十强"),
    ("新手礼包", "新手锦囊", "新手"),
    ("内测先锋礼包", "先锋锦囊", "先行测试奖励"),
    ("新人扶持礼包", "新人扶持锦囊", "新人扶持"),
    ("开荒礼包", "开荒锦囊", "开服开荒"),
    ("五一活动礼包", "五一锦囊", "五一活动"),
    ("端午节礼包", "端午锦囊", "端午活动"),
    ("七夕节礼包", "七夕锦囊", "七夕活动"),
    ("极限装备礼包", "极限装备锦囊", "极限装备"),
    ("悟道仙丹礼包", "开悟丹锦囊", "突破丹"),
    ("离线宠物礼包", "离线宠物锦囊", "离线收益"),
    ("人物升级丹", "人物经验丹", "人物经验"),
    ("宠物升级丹", "宠物经验丹", "宠物经验"),
    ("5+宠物礼包", "五阶宠物锦囊", "五阶宠物"),
    ("10-13变异不可进化宠礼包", "十至十三阶变异宠锦囊", "10-13 阶变异"),
    ("10-13变异可进化宠礼包", "十至十三阶变异可进化锦囊", "10-13 阶变异可进化"),
    ("测试礼包", "测试锦囊", "开发用"),
    ("开荒宠装礼包", "开荒宠装锦囊", "开荒宠物装备"),
    ("仙魔灵兽礼包", "仙魔灵兽锦囊", "仙魔玩法"),
    ("仙魔神兽礼包", "仙魔神兽锦囊", "仙魔玩法"),
    ("仙魔变异礼包", "仙魔变异锦囊", "仙魔玩法"),
    ("仙魔野生礼包", "仙魔野生锦囊", "仙魔玩法"),
]
GIFTS += [("塔%d礼包" % i, "试炼塔锦囊·%s" % "一二三四五"[i - 1], "试炼塔第 %d 层" % i)
          for i in range(1, 6)]
GIFTS += [("%d关礼包" % (i * 100), "百关锦囊·%s" % _CN[i - 1], "通关 %d 关" % (i * 100))
          for i in range(1, 21)]
for _n in range(6, 14):
    _cn = _CN[_n - 1]
    GIFTS.append(("%d+可进化宠礼包" % _n, "%s阶可进化宠锦囊" % _cn, "%d 阶，可进化" % _n))
    GIFTS.append(("%d+不可进化宠礼包" % _n, "%s阶不可进化宠锦囊" % _cn, "%d 阶，不可进化" % _n))
    GIFTS.append(("%d+可进化宠礼包(可能变异)" % _n, "%s阶可进化宠锦囊（变异）" % _cn, "%d 阶，带变异" % _n))
    GIFTS.append(("%d+不可进化宠礼包(可能变异)" % _n, "%s阶不可进化宠锦囊（变异）" % _cn, "%d 阶，带变异" % _n))

GIFTS_HOLD = [("7-9水晶儿礼包", "七至九阶晶儿锦囊", "含宠物「水晶儿」，等宠物改名同步"),
              ("7-9梦晶儿礼包", "七至九阶梦晶锦囊", "含宠物「梦晶儿」，等宠物改名同步"),
              ("7-9冥狼崽礼包", "七至九阶冥狼锦囊", "含宠物「冥狼崽」，2026-11-09 已随宠物改名落地")]

# ---------------------------------------------------------------- 套装（只改一个必须改的）
SUITS = [("鸿蒙套装", "玄黄套装", "「鸿蒙」是华为系统名，必须换；玄黄取自「天地玄黄」")]

SUITS_KEEP = ("其余 21 套保留原名：青云、玄灵、地脉、天羽、金罡、大罗、神威、至尊、混沌、无极、"
              "太虚、盘古、女娲、伏羲、轩辕、蚩尤、刑天、共工、永恒、无上、未知。"
              "这些词玩家一眼认得出档次；盘古女娲是上古神话、公有领域，不构成侵权。")

# ---------------------------------------------------------------- 地图 148 张（全部常用字）
MAP_NEW = {
    # 清域 27
    "浮影水城外郊": "墨影城郊", "东码头": "东渡口", "西码头": "西渡口",
    "九曲回廊": "九曲廊", "青风原": "青风野", "四桥原": "四桥野",
    "枯井原": "枯井野", "犁春原": "犁春野", "独木原": "独木野",
    "净沙原": "净沙野", "流沙原": "流沙滩", "遗恨原": "遗恨野",
    "坠泪岗": "落泪岗", "黄泥岗": "泥泞岗", "暮归道": "暮归路",
    "羊肠道": "羊肠路", "情思坡": "相思坡", "回首亭": "回望亭",
    "斑鸠小舍": "斑鸠小屋", "闲情园": "荒园", "明月桥": "月影桥",
    "春水桥": "解冻桥", "彩虹桥": "断虹桥", "青之绿洲": "青草洲",
    "绿洲东郊": "青草东滩", "沙盗洞口": "劫沙洞口", "羁马谷": "拴马谷",
    # 重域 43
    "徘徊林": "迷踪林", "松竹林": "松竹坡", "晚枫林": "红枫林",
    "守望林场": "守林屋", "剑池谷": "断剑潭", "情人谷": "双生谷",
    "赏月谷": "望月谷", "银罐谷": "陶瓮谷", "将军碑谷": "断碑谷",
    "落雁谷": "落雁滩", "双印谷": "印痕谷", "凰之谷": "石卵谷",
    "炊烟谷": "烟村谷", "金轮谷": "石轮谷", "斧青谷": "斧痕谷",
    "鸟鸣谷": "听鸟谷", "榕盘谷": "盘根谷", "栖月谷": "宿月谷",
    "碧水丹心谷": "红溪谷", "独孤亭": "独坐亭", "猎人洞窟": "猎户洞",
    "怨灵洞": "怨魂洞", "怨灵洞口": "怨魂洞口", "石壁洞口": "石壁洞",
    "吓死人洞窟1": "惊魂洞·上", "吓死人洞窟2": "惊魂洞·下",
    "巨菇洞": "菇王洞", "青灵洞": "青磷洞", "绿幽洞": "萤火洞",
    "清幽古洞": "冷泉洞", "清幽古洞二区": "冷泉洞·二层",
    "清幽古洞三区": "冷泉洞·三层", "清幽古洞四区": "冷泉洞·四层",
    "清幽洞": "冷泉洞口", "金钟洞窟": "铜钟洞", "古铜洞窟": "铜锈洞·甲",
    "古铜洞窟2": "铜锈洞·乙", "青铜洞窟": "铜锈洞·丙", "黄铜洞窟2": "铜锈洞·丁",
    "紫苔洞窟": "紫苔洞·上", "紫苔洞窟2": "紫苔洞·下",
    "石笋洞窟": "石笋洞", "碧水洞窟": "碧水潭",
    # 浓域 28
    "孤独亭": "孤亭", "踏雪原": "深雪原", "镜雪原": "冰镜原",
    "西雪岭": "雪岭西坡", "冰封雪地": "冻土原", "松雪野": "雪松林",
    "雪融谷": "融雪谷", "冰清桥": "霜桥", "玉洁桥": "白玉桥",
    "观日桥": "望日桥", "观日桥头": "望日桥头", "观云桥": "云海桥",
    "不归海岸": "断桨滩", "华山瀑布": "断崖瀑", "华山脚": "乱石坡",
    "华山腰道": "半山路", "华山顶": "云顶", "华山亭": "半山亭",
    "悬台": "悬空台", "碧野云天": "云上坪", "翔云台": "云中台",
    "衡天台": "石秤台", "降尘台": "旧祭坛", "御风台": "迎风台",
    "寒井台": "霜井台", "盈露台看守区": "接露台", "寒月台": "望月台",
    "断魂涯": "断魂崖",
    # 墨域 19
    "副本": "墨源洞", "空灵园": "空院", "深蓝海城": "沉海城",
    "深蓝海底": "沉海城底", "沉没的城市": "水淹城", "紫阳门": "朱漆门",
    "宣武门": "黑石门", "晋阳门": "西城门", "天关": "天关城",
    "翔云幻城": "云中城", "古城遗址": "旧城废墟", "断壁": "断墙",
    "宝洞": "藏墨洞", "盘龙洞窟": "龙骨洞·上", "盘龙洞窟2": "龙骨洞·下",
    "最后的房间": "尽头石室", "逆之往事": "倒流境", "逆之心情": "心象境",
    "逆之虚幻": "虚实境",
    # 焦域 30
    "魔界之森": "黑瘴林", "铜人殿": "铜像殿", "地牢": "石牢",
    "监狱第五层": "石牢五层", "小小房间": "小石室", "小房间": "侧石室",
    "过道": "长过道", "窄窄的过道": "窄过道", "很窄的过道": "极窄过道",
    "酒鬼冢": "酒瓮冢", "传说中的英雄冢": "无名冢", "冰封地狱": "寒冰渊",
    "暴走地狱": "狂奔渊", "聋耳地狱": "无声渊", "钉板地狱": "钉板渊",
    "绞肉地狱": "绞轮渊", "碾肢地狱": "石碾渊", "辗肢地狱": "石碾渊·下",
    "炮烙地狱": "铜柱渊", "油锅地狱": "滚油渊", "炉烧地狱": "巨炉渊",
    "旋割地狱": "刀轮渊", "吊烤地狱": "铁钩渊", "钉床地狱": "铁棘渊",
    "剥皮地狱": "剥壁渊", "磨骨地狱": "石磨渊", "铡头地狱": "巨铡渊",
    "污秽地狱": "黑沼渊", "天灯地狱": "青灯渊", "焰浆地狱": "岩浆渊",
    # 其他
    "morenzhandoubj": "默认战场",
}

MAP_RULE = ("五域对应进度，后缀全用玩家熟的地形词：原 / 野 / 谷 / 林 / 洞 / 桥 / 亭 / 坡 / 路 / 台 / 城 / 门 / 渊。"
            "生僻字全部弃用：东舣→东渡口、流沙碛→流沙滩、青风甸→青风野、断霓桥→断虹桥。"
            "「XX地狱」统一改成「XX渊」，玩家一听就是深层，也更有终局感。")


def load_maps():
    path = os.path.join(ROOT, "docs", "地图命名骨架-v1.md")
    text = io.open(path, encoding="utf-8").read()
    rows, zone = [], ""
    for line in text.splitlines():
        if line.startswith("## "):
            zone = re.sub(r"\s*—.*$", "", line[3:]).strip()
            zone = re.sub(r"\s*\(.*\)$", "", zone)
        m = re.match(r"^\|\s*([^|]+?)\s*\|\s*\*{0,2}([^|*]+?)\*{0,2}\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|", line)
        if m and not m.group(1).strip().startswith("---") and m.group(1).strip() != "原版名":
            rows.append([m.group(1).strip(), m.group(2).strip(), m.group(3).strip(), zone])
    return rows, text


def sync_md(text):
    """把骨架文档的新名列按 MAP_NEW 重写（幂等）。"""
    out, hit = [], set()
    for line in text.splitlines():
        m = re.match(r"^\|\s*([^|]+?)\s*\|\s*\*{0,2}([^|*]+?)\*{0,2}\s*\|(.*)$", line)
        if m and m.group(1).strip() in MAP_NEW:
            old = m.group(1).strip()
            hit.add(old)
            line = "| %s | **%s** |%s" % (old, MAP_NEW[old], m.group(3))
        out.append(line)
    io.open(os.path.join(ROOT, "docs", "地图命名骨架-v1.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
    miss = [k for k in MAP_NEW if k not in hit]
    if miss:
        print("!! %d 条旧名没在文档里找到：%s" % (len(miss), miss[:10]))
    return hit


def main():
    maps_raw, md_text = load_maps()
    if "--sync-md" in sys.argv:
        print("骨架文档同步 %d 条" % len(sync_md(md_text)))
        maps_raw, md_text = load_maps()

    maps = [(old, MAP_NEW.get(old, cur), terr, zone) for old, cur, terr, zone in maps_raw]

    sections = [
        ("arts", "人物武学", "六境界递进。上一版做成了画法术语（匀息描、罩染功），玩家看不懂，这里换回武功味", None, "refine"),
        ("books", "武学技能书", "两本，随武学一起改", BOOKS, "refine"),
        ("petskill", "宠物技能", "上一版的逆锋/吮墨/守纸看不懂，这里全换成两字大白话", PET_SKILLS, "refine"),
        ("pill", "丹药", "统一「X墨」，一眼知道是墨做的药；和修炼丹的「X丹」分开，不会混", PILLS, "todo"),
        ("cult", "修炼丹", "用「丹」结尾，和回血药区分", CULTIVATION, "todo"),
        ("herb", "灵草", "只去生僻前缀：九转还魂草→还魂草、天山雪莲→雪莲", HERBS, "todo"),
        ("mat", "材料", "只改必须改的：带年份的、等级看不懂的、前缀奇怪的，其余保留", MATERIALS, "todo"),
        ("gear", "装备", "只改「测试」系列，其余五档保留", GEAR, "todo"),
        ("egg", "宠物蛋", "属性 + 纹 + 异蛋，三个字说清楚", EGGS, "todo"),
        ("soul", "魂魄", "去掉数字后缀", SOULS, "todo"),
        ("chest", "宝箱", "只把「箱」换成「匣」", CHESTS, "todo"),
        ("gift", "礼包", "「礼包」统一换「锦囊」，其余原词全保留，玩家零门槛", GIFTS + GIFTS_HOLD, "todo"),
        ("suit", "套装", "只改「鸿蒙」一个", SUITS, "todo"),
        ("map", "地图", MAP_RULE, None, "todo"),
    ]

    LABEL = {"ok": "已落地", "todo": "待改", "refine": "线上是文雅版 · 待换"}
    total_ok = sum(len(i) for _, i in ARTS) + len(BOOKS) + len(PET_SKILLS)
    total_todo = sum(len(r) for _, _, _, r, s in sections if s == "todo" and r)

    # 覆盖校验：ALL_ITEMS 里除技能书外的每个道具都要有新名
    gd = io.open(os.path.join(ROOT, "scripts", "game_data.gd"), encoding="utf-8").read()
    seg = gd[gd.find("const ALL_ITEMS = {"):]
    items = re.findall(r'^\t"([^"]+)": \{"name": "([^"]+)", "type": "([a-z_]+)"', seg, re.M)
    mapped = set()
    for _, _, _, rows, _ in sections:
        for row in (rows or []):
            mapped.add(row[0])
    mapped.update(a for _, i in ARTS for a, _, _ in i)
    mapped.update(a for a, _, _ in BOOKS)
    mapped.update(b for _, b, _ in BOOKS)
    mapped.update(["三锋齐下", "以墨养墨"])  # 上一版落地的键名，待本轮再改
    mapped.update(KEEP_NAMES)
    missing = [n for _, n, t in items if t != "pet_skill_book" and n not in mapped]
    if missing:
        print("!! %d 个道具没给新名：%s" % (len(missing), missing[:20]))

    # ---------------- Markdown
    md = ["# 《墨境》命名对照全表 v2", "",
          "> 改版标准：**用常用字，用玩家听过的词**。水墨感靠意象（墨、霜、雪、断、残、孤），不靠术语。",
          "> 只换玩家看得见的显示名，**存档 id 一律不动**，改名自动迁移，老玩家不丢东西。", "",
          "线上是文雅版、待换 **%d** 条 ｜ 本次新改 **%d** 条 ｜ 地图 **%d** 张 ｜ 故意保留原名约 **60** 条"
          % (total_ok, total_todo, len(maps)), ""]

    for sid, title, note, rows, status in sections:
        md.append("## %s%s" % (title, "（%s）" % LABEL[status] if status != "todo" else ""))
        md.append("")
        md.append(note)
        md.append("")
        if sid == "arts":
            for realm, its in ARTS:
                md.append("### %s" % realm)
                md.append("")
                md.append("| 旧名 | 新名 | 效果 |")
                md.append("|---|---|---|")
                for a, b, c in its:
                    md.append("| %s | **%s** | %s |" % (a, b, c))
                md.append("")
            continue
        if sid == "map":
            md.append("| 原版名 | 新名 | 地形 | 所属 |")
            md.append("|---|---|---|---|")
            for a, b, t, z in maps:
                md.append("| %s | **%s** | %s | %s |" % (a, b, t, z))
            md.append("")
            continue
        md.append("| 旧名 | 新名 | 说明 |")
        md.append("|---|---|---|")
        for a, b, c in rows:
            md.append("| %s | **%s** | %s |" % (a, b, c))
        md.append("")
        keep = {"arts": ARTS_KEEP, "mat": MAT_KEEP, "gear": GEAR_KEEP, "suit": SUITS_KEEP}.get(sid)
        if keep:
            md += ["> " + keep, ""]

    io.open(os.path.join(ROOT, "docs", "命名对照全表.md"), "w", encoding="utf-8").write("\n".join(md))

    # ---------------- HTML
    import html as H

    body = []
    for sid, title, note, rows, status in sections:
        badge = '<span class="badge %s">%s</span>' % (status, LABEL[status])
        cnt = len(maps) if sid == "map" else (sum(len(i) for _, i in ARTS) if sid == "arts" else len(rows))
        body.append('<section class="card" data-s="%s">' % status)
        body.append('<div class="head"><h2>%s</h2>%s<span class="cnt">%d 条</span></div>'
                    % (H.escape(title), badge, cnt))
        body.append('<p class="note">%s</p>' % H.escape(note))
        body.append('<table><thead><tr><th>旧名</th><th>新名</th><th>说明</th></tr></thead><tbody>')
        if sid == "arts":
            for realm, its in ARTS:
                body.append('<tr class="realm"><td colspan="3">%s</td></tr>' % H.escape(realm))
                for a, b, c in its:
                    body.append('<tr><td class="old">%s</td><td class="new">%s</td><td class="d">%s</td></tr>'
                                % (H.escape(a), H.escape(b), H.escape(c)))
        elif sid == "map":
            cur = None
            for a, b, t, z in maps:
                if z != cur:
                    cur = z
                    body.append('<tr class="realm"><td colspan="3">%s</td></tr>' % H.escape(z))
                body.append('<tr><td class="old">%s</td><td class="new">%s</td><td class="d">%s</td></tr>'
                            % (H.escape(a), H.escape(b), H.escape(t)))
        else:
            for a, b, c in rows:
                body.append('<tr><td class="old">%s</td><td class="new">%s</td><td class="d">%s</td></tr>'
                            % (H.escape(a), H.escape(b), H.escape(c)))
        body.append('</tbody></table>')
        keep = {"arts": ARTS_KEEP, "mat": MAT_KEEP, "gear": GEAR_KEEP, "suit": SUITS_KEEP}.get(sid)
        if keep:
            body.append('<p class="keep">%s</p>' % H.escape(keep))
        body.append('</section>')

    tpl = """<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《墨境》命名对照全表 v2</title>
<style>
:root{--bg:#f7f5f0;--card:#fffdf9;--ink:#221f1a;--dim:#6f685c;--line:#e4dfd2;
--accent:#8c2f20;--accent2:#3a6357;--okbg:#e8efe9;--todobg:#f8ecdd;}
@media (prefers-color-scheme: dark){:root{--bg:#141310;--card:#1c1a16;--ink:#ece7dd;--dim:#9b9384;
--line:#2e2a23;--accent:#e0997c;--accent2:#82c4ad;--okbg:#1f2b24;--todobg:#2b2419;}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);
font:15px/1.7 -apple-system,"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif}
.wrap{max-width:1000px;margin:0 auto;padding:40px 20px 80px}
h1{font-size:29px;margin:0 0 8px;letter-spacing:.03em}
.lede{color:var(--dim);margin:0 0 22px;font-size:14px;line-height:1.9}
.lede b{color:var(--accent)}
.bar{position:sticky;top:0;z-index:9;background:var(--bg);padding:10px 0 12px;
border-bottom:1px solid var(--line);margin-bottom:22px;display:flex;gap:10px;align-items:center;flex-wrap:wrap}
input{flex:1;min-width:200px;padding:9px 13px;border:1px solid var(--line);border-radius:8px;
background:var(--card);color:var(--ink);font-size:14px;outline:none}
input:focus{border-color:var(--accent2)}
.tab{padding:7px 14px;border:1px solid var(--line);border-radius:999px;background:var(--card);
color:var(--dim);cursor:pointer;font-size:13px;user-select:none}
.tab.on{background:var(--accent2);border-color:var(--accent2);color:#fff}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:20px 22px;margin-bottom:18px}
.head{display:flex;align-items:baseline;gap:10px}
h2{font-size:19px;margin:0;letter-spacing:.02em}
.cnt{color:var(--dim);font-size:12px;margin-left:auto}
.badge{font-size:11px;padding:2px 8px;border-radius:999px;letter-spacing:.05em}
.badge.ok{background:var(--okbg);color:var(--accent2)}
.badge.refine{background:#f6e7d8;color:#a4551f}
@media (prefers-color-scheme: dark){.badge.refine{background:#33241a;color:#e5a877}}
.badge.todo{background:var(--todobg);color:var(--accent)}
.note{color:var(--dim);font-size:13px;margin:6px 0 14px}
.keep{margin:14px 0 0;padding:10px 13px;background:var(--okbg);border-radius:8px;
font-size:12.5px;color:var(--dim);line-height:1.8}
table{width:100%;border-collapse:collapse;font-size:14px}
th{text-align:left;font-weight:500;color:var(--dim);font-size:12px;letter-spacing:.08em;
padding:0 10px 8px;border-bottom:1px solid var(--line)}
td{padding:7px 10px;border-bottom:1px solid var(--line);vertical-align:top}
tbody tr:last-child td{border-bottom:none}
.old{color:var(--dim);width:32%;text-decoration:line-through;text-decoration-color:var(--line)}
.new{color:var(--accent);font-weight:600;width:26%}
.d{color:var(--dim);font-size:13px}
tr.realm td{color:var(--accent2);font-size:12px;letter-spacing:.12em;padding:18px 10px 7px;
border-bottom:1px solid var(--line);font-weight:600}
tr.realm:first-child td{padding-top:4px}
.foot{color:var(--dim);font-size:12.5px;text-align:center;margin-top:34px;line-height:2}
.hide{display:none}
</style></head><body><div class="wrap">
<h1>《墨境》命名对照全表 <span style="font-size:14px;color:var(--dim)">v2 · 按「玩家看得懂」重做</span></h1>
<p class="lede">上一版太文了（皴、澄浆、舣、碛），玩家会懵。这一版的标准只有两条：<br>
<b>① 字都是常用字　② 词都是玩家听过的词</b>。水墨感靠意象，不靠术语。<br>
只换玩家看得见的显示名，<b>存档 id 一律不动</b>，改名自动迁移，老玩家不丢东西。<br>
<span style="color:#b06020">线上是文雅版、待换 __OK__ 条</span> · <span style="color:var(--accent)">本次改 __TODO__ 条</span> · 地图 __MAP__ 张</p>
<div class="bar"><input id="q" placeholder="搜旧名或新名，例如：还丹、锦囊、灵草、地狱、码头">
<span class="tab on" data-f="all">全部</span><span class="tab" data-f="refine">待降档</span>
<span class="tab" data-f="todo">待改</span></div>
__BODY__
<p class="foot">绿色块里是「故意不改」的部分 —— 不是漏了，是那些名字玩家本来就懂，改了反而添乱。</p>
</div><script>
const q=document.getElementById('q'),cards=[...document.querySelectorAll('.card')];
let filter='all';
function run(){const k=q.value.trim().toLowerCase();
cards.forEach(c=>{const okF=(filter==='all'||c.dataset.s===filter);
const rows=[...c.querySelectorAll('tbody tr:not(.realm)')];
let hit=0;rows.forEach(r=>{const t=r.innerText.toLowerCase();
const m=okF&&(!k||t.includes(k));r.style.display=k&&!m?'none':'';if(m&&k)hit++;});
c.classList.toggle('hide',!(okF&&(!k||hit>0)));});}
q.addEventListener('input',run);
document.querySelectorAll('.tab').forEach(t=>t.addEventListener('click',()=>{
document.querySelectorAll('.tab').forEach(x=>x.classList.remove('on'));
t.classList.add('on');filter=t.dataset.f;run();}));
</script></body></html>"""
    page = (tpl.replace("__BODY__", "\n".join(body))
               .replace("__OK__", str(total_ok))
               .replace("__TODO__", str(total_todo))
               .replace("__MAP__", str(len(maps))))
    io.open(os.path.join(ROOT, "docs", "命名对照全表.html"), "w", encoding="utf-8").write(page)

    print("已落地 %d / 本次改 %d / 地图 %d" % (total_ok, total_todo, len(maps)))


if __name__ == "__main__":
    main()
