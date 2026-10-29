# AGENTS.md — 本项目的协作约定（Codex 必读）

> 项目：`recovered-godot-project`（水墨灵兽本地联调，Godot 4.6 恢复工程）
> 本文件由 WorkBuddy 于 2026-10-23 写入，记录**本地化改造的边界和最近一次外部改动**。
> 修改本文件前先看 `../online-snapshot/docs/服务端缺口清单.md`。

## 1. 工程结构（不要随意移动）

| 路径 | 作用 |
|---|---|
| `main.tscn` / `main.gd` | 原版入口（登录 → 主界面），`MAIN_UI_SCENE_PATH` 已指向 `ui/ink_home.tscn` |
| `dev/local_preview.tscn` / `dev/local_preview.gd` | 离线联调入口（`local-preview/project.godot` 用作 `run/main_scene`） |
| `dev/local_battle_manager.gd` | `extends GameManager`，本地模式的**唯一权威实现**（存档/商店/抽奖/装备/境界/战斗结算） |
| `dev/local_features.gd` / `dev/local_items.gd` / `dev/local_lottery.gd` | 本地事务、道具、抽奖服务 |
| `dev/local_feature_ui.gd` | 主城里那些"本地模拟"页面的统一 UI |
| `dev/local_snapshot.gd` + `dev/local_snapshot.json` | **新增**：线上真实数据快照的只读访问层 |
| `ui/ink_home.gd` | 水墨风主界面（`extends ui/main_ui.gd`，只做表现层与本地分支） |
| `scripts/game_server_config.gd` | 服务器地址（`API_PUBLIC_HOST` 已改为 `127.0.0.1`，可被 `local_server_override.json` 覆盖） |

## 2. 本地模式的判定方式

`ui/ink_home.gd` 的 `_ink_is_local_preview()` 用 `ProjectSettings.get_setting("application/run/main_scene") == "res://dev/local_preview.tscn"` 判定。
所有本地行为都挂在这个判定下（`_create_game_manager()` 返回 `LocalBattleManager`）。
**不要**用在 `game_manager.gd` 里加 `if local` 分支的方式扩展本地功能——恢复出来的 `scripts/*.gd` 尽量保持原样，方便后续与原版对比。

## 3. 2026-10-23 外部改动（WorkBuddy）

已改动文件（都在本地化层，未触碰 `scripts/game_manager.gd` 等恢复文件）：

1. **`dev/local_snapshot.json`（新增）** — 线上服真实抓包快照：100 条排行榜、6 条系统传闻、七日签到配置、4 个节日活动配置。
   由 `../online-snapshot/tools/build_snapshot.py` 生成，重新抓包后可一键重建。
2. **`dev/local_snapshot.gd`（新增）** — 快照只读加载器（`ranking()` / `broadcasts()` / `signin7()` / `festival()` / `header_note()`）。
3. **`dev/local_feature_ui.gd`（改）**
   - `TITLES` 新增 `world`（世界传闻）；`ranking` / `signin7` / `activity` 标题改为「线上快照」。
   - 排行榜页：本机数据保留，下面追加**线上真实榜单**（前 50 条，标注抓取时间，不做虚构补全）。
   - 签到页：显示线上真实活动标题/周期/状态与 7 天奖励表，本地测试发奖按钮保留且明确标注不写入线上进度。
   - 活动页：显示线上 4 个节日活动的礼包名、商城折扣文案、野外稀有刷新参数。
   - 新增世界传闻页：显示线上真实系统广播（`/api/xianmo/broadcasts`）。
4. **`ui/ink_home.gd`（改）** — 首页信息结构对齐线上：
   - 名字右侧增加**境界**（如「凡人」）。
   - 新增 **HP / MP 两条状态条**（`ProgressBar` + 居中数值），在 `_ink_refresh_vitals()` 里刷新，战斗页也生效。
   - 新增 **飞升 / 投胎** 按钮，直接复用已有的本地实现 `_on_character_realm_ascend_pressed` / `_on_character_realm_reincarnate_pressed`。
   - 未加"同步:正常"字样：本地是纯离线存档，不做假同步状态。
5. **`dev/local_preview.gd`（改）** — 新增可选检查入口 `--snapshot-audit`（headless 打印面板文字）与 `outputs/snapshot-visual.request`（有窗口时截图 `线上快照-*.png`）。

> 注意：`dev/local_preview.gd` 里原有的 `_local_output_path("../work/*.request")` 写法在**用 godot 二进制直跑**（非 .app）时会因为 `..` 未简化而失效；新加的检查入口改用 `outputs/` 下的文件名，两种运行方式都可用。

## 4. 验证方式（改完必须跑）

```bash
G=../work/godot-kernel/godot
P=../outputs/local-preview
cd ../work && TMPDIR=$PWD "$G" --headless --path "$P" --quit-after 900 -- --smoke --snapshot-audit
```

判定标准：
- 日志出现 `INK_LAYOUT=... "nav_inside_viewport":true`
- 出现 `SNAPSHOT_PANEL=ranking|labels=…`、`world`、`signin7` 三段
- 无 `SCRIPT ERROR` / `Parse Error`

窗口截图（验证视觉）：
```bash
touch ../outputs/snapshot-visual.request
"$G" --path "$P" -- --smoke      # 生成后会一直运行，需要手动关闭
```

## 5. 剩余 backlog（按优先级）

完整 178 个端点的分层清单在 `../online-snapshot/docs/服务端缺口清单.md`。优先级建议：

1. **战斗结算走服务端同构**：`/battle/wild-run` + `/economy/battle-loot` 的请求体已抓到（见 `../online-snapshot/data/samples/`），
   目前本地是复用客户端结算函数，数值可信；若要做真·服务器，需要把经验表、掉落表搬到服务端。
2. **重度玩法完全缺失**：仙魔战场(18)、兄弟天关(16)、生死塔(10)、天关、套装/五行/图鉴副本、藏宝、世界Boss、竞技场。
3. **灵兽装备/人物装备的强化、分解、套装转换**（约 20 个端点）只有穿脱。
4. **灵兽蛋/助战/碎片合成/转生继承**。
5. **服务端下发配置**：`/gameplay/runtime-config`、`/economy/drop-config` 目前是客户端兜底值。

## 6. 约束

- 抓包数据里有真实玩家昵称与账号信息：**任何对外提交前必须脱敏**，`data/samples/` 不进公开仓库。
- 恢复工程的原始美术/音乐仅用于分析定位，发布前需完成原创替换（见 `README-开发前必读.md`）。
- 本地存档在 `../outputs/local-state/`，`preview-slot.json` 是用户正在用的档，**不要拿它做破坏性测试**；测试请用 `--shop-test` / `--item-test` 等独立槽位。

## 7. 线上数值校准包（2026-10-23 新增，已落地）

线上服 `101.42.200.***:3000` 的 37 个只读端点已重放成功，真实数值全部并入 `dev/local_snapshot.json`。
生成脚本：`<workbuddy>/replay/build_calibration.py`（重跑会保留 ranking/broadcasts/signin7/festival，只覆盖 rules 等新键）。
报告：`<workbuddy>/replay/ONLINE-DATA.md`。

### 7.1 新增的读取入口（`dev/local_snapshot.gd`）

```gdscript
var snap = load("res://dev/local_snapshot.gd")
snap.rules()                 # 全部硬数字（tower/suit_dungeon/five_elements/atlas_dungeon/...）
snap.rules_key("tower")      # 单项
snap.shop_items()            # 48 件真实商品（itemName/currency/basePrice/finalPrice/dailyLimit/vipRequiredTier）
snap.drop_rates()            # 18 条真实掉落率
snap.reference_player()      # 线上真实角色数值（level/cultivation/final_attack/...）
snap.reference_pets()        # 线上 10 只真实灵兽（42 字段/含 growth_rates、medal_counts）
snap.pet_ranking()           # 进化宠排行榜前 40（成长分布参考）
snap.save_meta()             # 存档规模：灵兽10/袋17/物品36类/任务88类/当前地图
snap.has_rules()             # 快照是否含 rules 段
```

### 7.2 已核对的硬数字（直接照抄，不要再猜）

| 项 | 线上真实值 |
|---|---|
| 训练塔 | 当前 602 层，历史最高 601，开放上限 1899，总上限 2000 |
| 套装副本扫荡 | 每日 2 次 |
| 五行副本 | 每日 10 次 + 元宝 1 次 |
| 图鉴副本 | 初/中/高 = 20/100/200 波，各 30 次，入场 1e8/5e8/1e9 金币 |
| 兄弟天关 | 每日通关 6 次、领奖 1 次 |
| 藏宝 | 每日参团 2 次 |
| 抽奖保底 | 100 次，17 种可选奖励（见 rules.lottery_pity.options） |
| 贵族 | 三等贵族：累计消耗 5490，下一档 8000；合并+6%、武学+10% |
| 武学成功率 | 基础 0.3 / 服务端 0.4 / 贵族加成 10 |
| 投胎追赶 | 开启，差距 774 世，单场最多升 4 级 |
| 掉落率 | 17 种 1%（装备类）、灵草/灵芝 0.05%、天山雪莲 0.02%、九转还魂草/龙涎草 0.01% |

### 7.3 新增 UI 页

`dev/local_feature_ui.gd` 增加 `online_rules`（标题「线上数值 · 抓包校准」），
从任意本地页面的顶部导航即可进入；`dev/local_preview.gd` 的 `--snapshot-audit` 已覆盖该页。

## 8. 主城 21 个玩法模块的完整配置（2026-10-23 第二次落地）

线上 `GET /api/gameplay/runtime-config`（73.7 KB）一次返回**全部玩法静态配置**，
现已并入 `dev/local_snapshot.json` 的 `rules_modules` 段（快照 78 KB → 154 KB，`schema` 升到 3）。

> 与 `rules` 段的区别：
> **`rules` = 当前账号此刻的状态**（塔 602 层、次数还剩几次、贵族 5490/8000）；
> **`rules_modules` = 玩法本身的规则常量**（塔上限 2000、投胎门槛表、掉落权重、85 个技能定义）。

生成脚本：`<workbuddy>/replay/build_rules_modules.py`（可重跑，幂等，只覆盖 `rules_modules` 段）。
改动前的快照备份：`<workbuddy>/replay/local_snapshot.backup-20261023.json`。
模块 → 本地落点对照表：`<workbuddy>/outputs/maincity/module-map.json`。

### 8.1 读取接口（`dev/local_snapshot.gd`）

```gdscript
var snap = load("res://dev/local_snapshot.gd")
snap.rules_module_names()                    # 21 个模块 key（已剔除 _meta）
snap.rules_module("world_boss")              # 整个模块；传 "worldBoss" 也认（自动转 snake_case）
snap.has_rules_module("arena")               # 是否存在
snap.module_value("arena", "dailyMaxAttempts", 0)   # 点路径取值，第三参是兜底
snap.module_count("arena", "streakMilestones")      # 长度：数组/字典/字符串都安全
snap.module_list("tower", "reincarnationGates")     # 安全取数组，取不到返回 []
snap.module_dict("fabao", "tiers")                  # 安全取字典，取不到返回 {}
snap.skills()                                # 85 个技能（key/name/triggerRate/damageRatio）
snap.skill("splash_lv1")                     # 单个技能
snap.pet_open_items()                        # 44 个开箱道具
snap.world_boss_config() / snap.arena_config() / snap.shengsi_tower_config() / … # 21 个语义化入口
```

### 8.2 模块清单

| key | 内容要点 |
|---|---|
| `lottery` | 金币池 5 亿/抽 15 档；元宝池 100/抽 39 档；100 次保底 13 选 1 |
| `tower` | 上限 2000 层、开放 1899、30 回合、20 条投胎门槛、层礼/里程碑间隔 |
| `treasure` | 12 档奖励权重、报名/战斗各 10 分、开放 9-24 点、VIP 入阵 2/4/5/8 |
| `five_elements_dungeon` | 每日 10 次 + 元宝 1 次、难度映射、怪物与奖励 |
| `suit_dungeon` | 等级上限、入场费、扫荡金币公式、掉落率 |
| `atlas_dungeon` | 三档波次 20/100/200、入场 1e8/5e8/1e9、捕捉率 |
| `brother_tower` | 10 波 × 8 只、每日通关 3、领奖 1、四档难度区间 |
| `pet_soul` / `pet_mutation` / `pet_assist` / `pet_skill_slots` / `pet_skill_learn` | 转生概率与成长区间、三路变异、助战概率、技能格数量、学习/继承概率 |
| `martial_create` | 自创武学是否服务端裁决 |
| `world_boss` | HP 1e9 / 攻 1e4 / 防 3e4 / 敏 1e4、每日 3 次 10 回合、掉落表、排名奖励 |
| `arena` | 每日 10 次 20 回合、胜 +10 负 +2、匹配 ±30、8 条连胜档、竞技点商店、称号 |
| `shengsi_tower` | 5 层（`floors` 是**数组**）、每队 2 人、20:30 报名 20:40 开赛、回放参数 |
| `pet_raise_race` | 提交/结算时间、目标成长 20-44.999、奖励蛋 |
| `gameplay` | 野外 1-5 只/经验 ×0.5/每级 90 经验/10 回合、等级经验表（500 级突破）、投胎追赶、战斗权威、85 技能 |
| `pet_open_items` | 44 个开箱道具 |
| `fabao` | 8 阶倍率 1/2/4/6/8/10/12/14、投胎门槛、掉落 1/2000、5 条随机词条 |
| `weekly_buff` | 7 天轮换与每日用量上限 |

### 8.3 踩过的坑（务必照做）

1. **不要写 `(x as Dictionary).size()`**。cast 失败返回 `null`，对 `null` 调 `size()` 会让这个
   Godot 构建（4.8.dev）**直接段错误退出（exit 139）**，且 stdout 缓冲会一起丢失，看起来像"没有任何输出"。
   统一用 `module_count()` / `module_list()` / `module_dict()`。
2. 同一字段在不同模块里类型可能不同：`shengsi_tower.floors` 是**数组**，`fabao.tiers` 是**字典**；
   `tower.reincarnationGates` 是数组（元素 `{floor, required}`）。
3. Godot 解析 JSON 后所有数字都是 **float**，日志里会看到 `2000.0`；比较要用 `is_equal_approx`，
   不要拿字符串比。
4. 模块内字段名保持服务端 camelCase，**不要重命名**，否则和抓包对不上。

### 8.4 验证命令

```bash
G=<godot>/godot
cd <work>   # TMPDIR 必须可写，否则 JSON/日志落盘会失败
# 1) 数据层：21 模块 + 9 个数值探针 + 技能/开箱道具
TMPDIR=$PWD "$G" --headless --path ../outputs/local-preview --script res://dev/_calib_check.gd
#   期望：RULES_MODULES=21 … MODULE_PROBES=9/9 … CALIB_CHECK_OK
# 2) 渲染层：5 个快照页面板
TMPDIR=$PWD "$G" --headless --path ../outputs/local-preview --quit-after 1200 -- --smoke --snapshot-audit
#   期望：SNAPSHOT_PANEL=ranking|59 / world|17 / signin7|16 / online_rules|69 / online_modules|39
```

新增 UI 页 `online_modules`（标题「玩法配置 · 线上模块」）已在 `--snapshot-audit` 覆盖范围内，
逐模块列出字段数与说明首行，可直接对照实现进度。


## 9. 本地服务端（2026-10-23 新增，替代线上 101.42.200.***:3000）

线上服务端的 177 个端点已在本机复刻：`../local-server/`。
客户端 `scripts/game_server_config.gd` 的 API 地址本来就是 `127.0.0.1:3000`，
所以**不需要改任何客户端代码**，起进程即可用原版登录流程玩本地服。

```bash
cd ../local-server
python3 server.py                # 3000=API，3001=聊天
python3 tools/conformance.py     # 回归：177/177
```

### 9.1 它替代了什么

| 原服务端职责 | 本地实现 |
|---|---|
| 账号与令牌 | `handlers_account.py`（首次登录自动建号，不卡登录页） |
| 存档权威（rev 递增、上传/下载） | `handlers_account.py` + `core.State` |
| 全局配置下发 | `handlers_growth.py`：runtime-config / drop-config / festival / shop-catalog |
| 每日次数与时间窗 | `core.State.daily_try()` + `in_window()`，跨天自动归零 |
| 战斗结算 | `combat.py`：服务端算 14 种事件，客户端只播放 |
| 发奖（含邮件） | `core.State.add_item/send_mail` |
| 排行榜/竞技场对手/世界 Boss | 用线上真实榜单当机器人 |
| 兄弟天关/生死塔 | 单人 + 事件流（`battle-events` 增量） |

### 9.2 数值口径（已与真实样本核对）

```
玩家经验 = Σ monsters.exp_reward × 0.5（wildBattle.fieldExpMultiplier）
金币     = Σ monsters.gold_reward
怪物经验 = 90 × 等级，金币 = 1 × 等级
```

`dev/local_*` 那套离线逻辑（LocalBattleManager）**继续保留**：打包成单机 App 时用它；
做联调、验证服务端行为时用 local-server。两者共用同一份 `dev/local_snapshot.json` 的配置。

### 9.3 注意

- `../local-server/data/` 与 `state/state.json` 含线上真实玩家数据，**不要提交公开仓库**。
- 本地服不校验客户端上报数值（原服有 `authorityPhase=enforce`），仅用于联调。


## 10. 全地图野外战斗数值（2026-10-23 新增）

线上 279 张野外地图的真实刷怪表已经采集完并接进本地服务端。
**入口文档：`../handoff-2026-10-23/00-交接说明-给Codex.md`**，机器可读清单 `01-修改清单.json`。

### 10.1 数据在哪

| 文件 | 用途 |
|---|---|
| `../local-server/data/maps.json` | **权威**。279 图：`pool[]`（pet_id/name/element/level Min~Max/attack/defense/agility/hp）、`spawnDist`、`spawnMin/Max`、`rewardEnabled`、`rewardCode`、`spawnFallback/fallbackLevel` |
| `../handoff-2026-10-23/data/wild-maps.json` | 聚合统计超集（每图每怪的出现次数、等级 min/max、单场平均收益、掉落统计） |
| `../handoff-2026-10-23/data/全地图战斗数值-2026-10-23.md` | 人读报告（公式校验、特例清单、逐图表格） |
| `../handoff-2026-10-23/data/全地图怪物数值-2026-10-23.csv` | 逐怪明细，方便直接当数值表导入 |
| `../handoff-2026-10-23/raw-samples/` | 6 个代表地图的原始 `wild-run + battle-loot` 响应 |

### 10.2 公式（837/837 实测命中）

```
单怪 exp_reward = 90 × 实际等级
单怪 gold_reward = 1 × 实际等级
单场金币 = Σ 等级；单场玩家经验 = 0.5 × Σ exp_reward
刷怪 1~5 只，按 spawnDist 加权；等级在图内 levelMin~levelMax 浮动
```

### 10.3 三条必须复刻的服务端中断规则

1. `rewardCode == "UNKNOWN_MAP"`（13 图）→ 结算 `success:true, goldGranted:0`，无 `playerExpGranted`。
2. `rewardEnabled == false` 且无 code（8 图，九曲回廊/清幽古洞系列）→ 同样零收益。
3. `spawnFallback == true`（11 图）→ 不用 `pool`，刷通用怪：冰封雪地=狼 Lv1300，清幽古洞二/三/四区=怪物 Lv784。

### 10.4 自检

```bash
cd ../local-server && python3 server.py --port 3000     # 另开终端
python3 ../handoff-2026-10-23/scripts/verify_local_maps.py --maps 8
#   期望：逐图 PASS，末行 VERIFY_OK
```

### 10.5 不要做的事

- 不要给 `UNKNOWN_MAP` / 零收益图「补上」奖励 —— 那是线上真实行为，补了就对不上了。
- 不要用 `pool[].exp_reward` 直接发奖：那是客户端静态表等级算出来的参考值，
  实际发奖必须用**本次刷出的实际等级** × 90 / × 1（`handlers_battle.py` 已这么做）。
- `data/maps.json` 里的 `serverSeen` 是实测出现次数，可用来判断某图某怪是否稀有，不要当权重用。
