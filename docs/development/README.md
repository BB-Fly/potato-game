# 开发接手总览

本文档是当前项目的开发入口。它不重复完整玩法设计，而是回答“接下来要改代码时先看哪里、怎么验证、哪些规则不能破坏”。

## 当前项目形态

Puritato 当前是一个 Godot 4 原型项目，已经有一条可运行闭环：

```text
启动 -> 初始装备三选一 -> 选择路线 -> 领取路线奖励 -> 进入战斗 -> 小怪阶段 -> Boss 阶段 -> 胜利后推进地图
```

这个闭环主要由 `src/app/main.gd` 驱动。`src/domain/` 里已经有长期架构雏形，但当前原型为了快跑通，大量 UI、战斗表现和战斗逻辑还集中在 `main.gd`。

## 目录职责

```text
scenes/
  main.tscn                 Godot 主场景，挂载 src/app/main.gd

src/
  app/
    main.gd                 当前可运行原型入口和表现层核心
  core/
    fixed_tick_loop.gd      固定 tick 循环
    event_bus.gd            事件总线
    registry.gd             内容注册表
    deterministic_rng.gd    确定性随机
  config/
    content_config_loader.gd  加载 content/base
    asset_catalog.gd          根据 asset id 解析资源路径
  domain/
    run/                    单局状态
    map/                    地图推进
    reward/                 物品池和奖励
    economy/                商店价格
    combat/                 目标战斗运行时雏形
    weapon/ magic/ item/    目标领域模块雏形

content/
  base/                     当前 Demo 内容配置

assets/
  art/                      运行时美术和生成源文件

docs/
  development/              当前实现文档
  gameplay-design/          玩法设计
  architecture/             长期架构
  art/                      美术资源
```

## 当前实现边界

已经接入当前可玩切片：

- 初始装备选择。
- 双路线地图。
- 选中路线高亮。
- 未选中路线奖励节点预览。
- 路线奖励节点领取。
- 简化商店。
- 自动武器攻击。
- 4 个魔法槽。
- 小怪刷怪、追踪和接触伤害。
- Boss 出场和 16 向弹幕。
- 简单图形碰撞。
- 逻辑画布缩放适配。

尚未完整实现或仍是原型：

- 背包 UI 和手动装备管理。
- 正式 `CombatRuntime` 接管战斗。
- 完整 buff、道具、武器技能 DSL。
- 商店服务项、刷新、强化、融合。
- 正式场景美术背景，例如 `main_menu_background.png` 和 arena 背景。
- 存档。
- 自动化测试。

## 新增功能时先看哪里

| 任务 | 优先阅读 |
| --- | --- |
| 启动、灰屏、界面切换 | `runtime-flow.md` |
| 新增武器、道具、魔法、怪物配置 | `content-config.md` |
| 修改属性公式、层数成长、buff 运行时 | `combat-balance-runtime.md` |
| 修改地图路线或节点 | `map-reward-flow.md` |
| 修改小怪、Boss、战斗输入、碰撞 | `combat-slice.md` |
| 调整图片、图标、像素资源 | `assets-and-art.md` |
| 拆分 `main.gd` 或新增运行时模块 | `module-splitting.md` |
| 提交前验证、Git、常见故障 | `debugging-and-git.md` |

## 不要轻易破坏的规则

- `main.gd` 的 `_ready()` 必须最终进入 `_show_starter_screen()`。
- UI 和点击热点必须挂在 `ui_root` 下，使用 1280x720 逻辑坐标。
- 武器最多自动装备 4 个。
- 魔法槽当前为 4 个，按键为 `Q`、`E`、`R`、`F`。
- 碰撞使用简单圆形或矩形，不追求贴图轮廓。
- 缺失规划资源时要有 fallback，不要让启动依赖未提交图片。
- 不要批量提交 Godot 自动生成的 `.import` 文件。

## 快速验证

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game diff --check
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

健康日志应包含：

```text
Puritato playable slice ready.
```
