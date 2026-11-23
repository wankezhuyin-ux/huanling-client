# 水墨灵兽（Huanling）— 工程总览 / Project Map

> 本文件给「新接手的 AI 智能体」看，目标是让对方在不问人的情况下理解整个工程的文件布局、前端/后端边界、联调方式与红线约束。
> 最后更新视角：2026-11-11。

---

## 0. 一句话定位

这是一款用 **Godot 4 恢复出来的国风水墨修仙放置/RPG 手游《水墨灵兽》** 的本地联调工程。包含：
- **前端**：Godot 4 客户端（169 个 GDScript、1714 个导入资源，由 GDRETools 从 APK 恢复）
- **后端**：Python 本地服务端（177 个 HTTP 端点全部实现，替代原线上服 `101.42.200.***:3000`）
- **Web 分发**：落地页 / APK / 商店资源
- **美术重绘管线**：AI 生图源 + 重绘预览版本
- **抓包快照与审计文档**：线上真实数据、服务端缺口清单、版权脱敏台账

---

## 1. 工程根目录（最关键）

**所有产物都在同一个父目录下：**

```
/Users/a1111/Documents/Codex/2026-10-21/n/outputs/
```

其下有这些并列子工程（按重要度排序）：

| 目录 | 角色 | 说明 |
|---|---|---|
| `recovered-godot-project/` | **前端（主交付物）** | Godot 4 客户端，**带 git 仓库**（branch: main），是当前真正在改的工程 |
| `local-server/` | **后端** | Python 3 本地服务端，177 端点 100% 实现 |
| `web/` | Web 分发 | 落地页 `index.html`、APK、Google Play 资源 |
| `art-pilot/` | 美术重绘工作区 | AI 生图源图 + 各版 preview（细节母本在 `art-pilot/map01/preview-v4/`） |
| `deploy/` | 发布/部署 | `install.sh`、nginx 配置、keystore、服务器包 `lingyun-server.tar.gz`、`update_server*.sh` |
| `online-snapshot/` | 线上快照 | 真实抓包数据 + `docs/服务端缺口清单.md` |
| `build/`、`backup/`、`assets_backup*/` | 构建产物与备份 | 编译/打包/资源备份 |
| `tools/` | 顶层工具 | 审计脚本（`audit_*.py`）、打包 shell（`build_*.sh`） |
| `原始恢复工程.zip` | 原样恢复归档 | 恢复前 APK 逆向成果，253 MB |

---

## 2. 前端（客户端）— `recovered-godot-project/`

- **引擎**：Godot 4.6.1（GDRETools 恢复，字节码归到兼容的 4.5.0-stable）
- **入口**：`main.tscn` / `main.gd` → 已指向 `ui/ink_home.tscn`（水墨风主界面）
- **本地联调入口**：`dev/local_preview.tscn` + `dev/local_preview.gd`（`run/main_scene` 指向它时进入本地模式）

### 核心目录
| 目录 | 数量/作用 |
|---|---|
| `scripts/` | **104 个 .gd**：战斗/背包/装备/炼器/法宝/宗门/竞技场/聊天… 网络层 `scripts/network.gd` 约 10083 行、178 个 `server_url` 端点 |
| `ui/` | **52 个**：主界面 `main_ui.gd`、水墨首页 `ink_home.gd`、城市/邮件/武学/背包/商店/战斗 UI 等 |
| `assets/` | 美术资源：`sprites/`(精灵帧表)、`pets/`、`portraits/`、`shaders/`(水墨体积 `ink_volumetric.gdshader`)、`backgrounds/`、`city/`、`items/`、`icons/` |
| `dev/` | **本地模式权威实现层**（不碰原始恢复文件）：`local_battle_manager.gd`(extends GameManager)、`local_features/local_items/local_lottery.gd`、`local_snapshot.gd`+`local_snapshot.json`(线上快照只读层) |
| `tools/` | **186 个**：美术/地图/体积图烘焙（`bake_volume_maps.py`）、帧合成（`assemble_frames.py`）、调色/一致性检查等 |
| `Music/` | 音频资源 |

### 关键约定（改前端必知）
- 服务器地址在 `scripts/game_server_config.gd`（`API_PUBLIC_HOST` 已改 `127.0.0.1`），可被根目录 `local_server_override.json` 覆盖（默认 `127.0.0.1:3000` / chat `3001`）。
- 本地模式判定：`ui/ink_home.gd` 的 `_ink_is_local_preview()` 看 `run/main_scene == res://dev/local_preview.tscn`。
- **不要**在 `scripts/game_manager.gd` 等恢复文件里加 `if local` 分支——本地功能都挂在 `dev/` 层，方便后续与原版对比。

---

## 3. 后端（服务端）— `local-server/`

- **语言**：Python 3，单进程 HTTP（**3000** API / **3001** 聊天）
- **启动**：`python3 server.py`
- **回归测试**：`python3 tools/conformance.py` —— **177/177 端点通过**（HTTP 200 + 合法 JSON，无 5xx）
- **覆盖**：177/177 端点实现、100% 一致性测试

### 关键文件
| 文件 | 作用 |
|---|---|
| `server.py` | HTTP 入口、路由、鉴权、`/api` 前缀归一化、请求日志 |
| `core.py` | 全局配置(Rules)、玩家状态(State)、上下文(Ctx)、路由注册 |
| `combat.py` | 战斗逐回合结算，输出 14 种事件流（字段结构与线上抓包逐字段对齐） |
| `handlers_account.py` | 注册登录、存档上传/下载、用户、邮件、公告、离线、排行榜 |
| `handlers_battle.py` | 野外/天关战斗、战斗结算掉落、扫荡 |
| `handlers_play.py` | 天关/副本/竞技场/世界Boss/生死塔/藏宝/兄弟天关/仙魔战场/签到/贵族/养宠赛 |
| `handlers_growth.py` | 商店、抽奖保底、经济、灵兽、装备、宠装、属性、武学、打造、礼包 |
| `handlers_extra.py` / `handlers_arena.py` / `handlers_boss_tower.py` / `handlers_fabao.py` / `handlers_gang.py` / `handlers_mail.py` | 其余玩法域 |
| `contract.json` | 从 `network.gd` 静态抽出的 177 端点契约（方法/请求字段/响应字段） |
| `data/` | 线上真实下发配置：`runtime-config.json`(73.7KB/21玩法模块)、`drop-config.json`、`shop-catalog.json`、`ranking*.json`、`save_seed.json`、`monsters.json`、**`maps.json`（279 张野外图刷怪表，837 场实测）**、节日/邮件种子 |
| `state/` | 运行期：`state.json`(存档+计数)、`requests.log`、`conformance.json`、`coverage.json` |

### 机制要点
- **存档权威在服务端**：`/save/upload` 收整份 `saveData`，`/save/download` 发回（带 revision 递增）；沿用客户端存档结构，老档可用。
- **时间闸门**：`core.State.daily_try()` 统一管每日次数，跨天（北京时间 00:00）归零。
- **战斗近似复刻**：伤害公式按样本反推（`atk - def×0.5`，8% 暴击 ×1.6），胜负/经验/金币口径已与真实样本对齐。
- **已知边界**：单账号（只存一个玩家）；无反外挂；数据含真实玩家昵称（仅本机自用，勿外发）。

> ⚠️ 注意：前端 `dev/` 里另有一套「客户端内置本地模式」（`LocalBattleManager`），与这个独立 Python 服务端是**两套可二选一的本地后端方案**；Python 服务端是完整版（177 端点），`dev/` 是轻量离线模拟层。

---

## 4. Web 分发 — `web/`
- `index.html` 落地页、`apk/`(APK 包)、`play/`(Google Play 素材)、`icon_512.png`、`huanling.mobileconfig`(iOS 描述文件)

---

## 5. 美术重绘管线 — `art-pilot/`
- 按地图分目录（如 `map01/`），存放 AI 生图**源图**（如 `tiějiǎgūi.png` 铁甲龟源生图）与各版 **preview**（如 `preview-v4/compare.png` 是「细节丰富」母本，右列 NEW 版）。
- 当前宠物精灵重绘的阶段成果已写回前端 `assets/sprites/` 与 `assets/sprites/vol/`。
- **当前宠物改版状态（2026-11-11）**：
  - 铁甲龟 `assets/sprites/tiějiǎgūi_idle.png` 已整体放大 ×1.28（帧0 主体 221×135，宽占 86%），attack 同步放大；体积图已重烤。放大前备份在 `/tmp/turtle_scaleup_bak/`。
  - 仍处**单帧形象阶段**，idle/attack 表仅帧0 有内容、帧1/2 留白（预期，未开始帧动画）。
  - 质量基准：保持 `preview-v4` 右列的细节丰富度；尺寸约定按原版 ×1.15（纠正高度塌缩）。

---

## 6. 联调 / 验证方式
- **前端无头校验**（详见 `recovered-godot-project/AGENTS.md` 第4节）：
  ```bash
  G=../work/godot-kernel/godot
  P=../outputs/local-preview
  cd ../work && TMPDIR=$PWD "$G" --headless --path "$P" --quit-after 900 -- --smoke --snapshot-audit
  ```
  判定：日志出现 `INK_LAYOUT=... "nav_inside_viewport":true` 与 `SNAPSHOT_PANEL=ranking|world|signin7` 三段，无 `SCRIPT ERROR`。
- **后端一致性测试**：`cd local-server && python3 tools/conformance.py`
- **本地存档**：`outputs/local-state/`（`preview-slot.json` 是用户正在用的档，**不可破坏性测试**；测试用 `--shop-test`/`--item-test` 独立槽位）。

---

## 7. 红线约束（其他 AI 必读，违反会导致法律风险）
1. **原始美术/音乐仅用于分析定位**，发布前必须完成原创替代并留存来源记录（`README-开发前必读.md`）。
2. **抓包数据含真实玩家昵称与账号**（`local-server/data/ranking*.json`、`save_seed.json`、`online-snapshot/`）：任何对外提交前必须脱敏，**不进公开仓库**。
3. **授权范围需随项目保存**：代码授权由用户确认，范围文件随项目留存。
4. 当前全部为**本地试点**，未出热更、未部署线上；线上版本号 `2.12.0.31`。

---

## 8. 新 AI 上手「先看这 3 个文件」
1. `recovered-godot-project/AGENTS.md` —— 本地化改造边界、目录结构、最近改动、验证方式
2. `recovered-godot-project/README-开发前必读.md` —— 恢复工程说明、引擎版本、待办与法律红线
3. `local-server/README.md` —— 后端架构、端点清单、数据来源、扩展三步法

读完这 3 个，再按需进 `online-snapshot/docs/服务端缺口清单.md`（178 端点分层 backlog）与 `版权与脱敏审计台账-2026-11-09.md`（合规台账）。
