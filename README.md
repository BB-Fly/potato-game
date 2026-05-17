# Puritato

Puritato 是一个 Godot 4 自动攻击生存 roguelike 原型。当前仓库里的版本已经是一个可运行的纵向切片：领取初始装备、选择路线、领取奖励节点、进入战斗、经历小怪阶段，并挑战 Demo Boss。

## 当前可运行节点

- 稳定提交：`d6ea0ca Restore playable Godot prototype`
- 主场景：`res://scenes/main.tscn`
- 运行入口脚本：`src/app/main.gd`
- 可编辑路线地图场景：`res://scenes/route_map_scene.tscn`
- 战斗场景：`res://scenes/combat_scene.tscn`
- 单局共享状态：`src/domain/run/run_context.gd`
- 基础内容配置：`content/base/`
- 运行时美术资源：`assets/art/`

## 本地运行

本机 Godot 安装目录：

```text
C:\Program Files\Godot
```

提交前后建议先跑 headless 启动检查：

```powershell
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

当前机器也配置了 `godot` 命令入口，可以在仓库根目录直接运行：

```powershell
godot --headless --path . --quit
```

健康启动时应该看到：

```text
Puritato playable slice ready. Registered types: ["school", "character", "weapon", "magic", "item", "buff", "monster", "boss", "map", "reward_table", "shop", "audio", "asset", "balance"]
```

启动可见游戏窗口：

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

## 文档导航

- `docs/README.md`：完整文档入口，按玩法、架构、开发实现、美术资源分层导航。
- `docs/gameplay-design/`：玩法规则和目标系统设计。
- `docs/architecture/game-architecture.md`：长期目标架构文档。
- `docs/development/`：当前项目的分模块开发说明，后续新窗口优先阅读。
- `docs/architecture/implementation-notes.md`：当前可运行原型的技术实现和交接说明，已被 `docs/development/` 拆分扩展。
- `docs/art/asset-list.md`：美术资源清单、生成资源记录和运行时资源约定。

## 修改运行时代码前

1. 修改前后都运行一次 Godot headless 检查。
2. 保持 `src/app/main.gd` 在 `_ready()` 中创建可见 UI。如果启动只打印架构初始化日志、没有调用 `_show_starter_screen()`，游戏窗口会变成灰屏。
3. 地图路线、奖励节点和战斗节点以 `scenes/route_map_scene.tscn` 为准；调整地图布局时优先改该场景的 `AreaDefinitions`，不要只改 JSON 的 `position_hint`。
4. 武器最多自动装备 4 个。多余武器进入 `inventory["weapons"]`，在背包/装备 UI 实现前不能自动生效。
5. Godot 生成的 `.import` 文件默认视为自动生成噪声，除非确实改了导入设置，不要批量提交。
