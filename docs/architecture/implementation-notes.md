# 当前实现说明

本文档描述的是当前可运行的 Godot 原型，而不是长期目标架构。新窗口或后续 Agent 接手时，可以先读这份文档，再决定是否下钻到代码。

## 快照

- 当前稳定恢复点：`d6ea0ca Restore playable Godot prototype`。
- 本机使用的 Godot 版本：`4.6.2 stable Mono`。
- 主场景：`scenes/main.tscn`。
- 运行入口脚本：`src/app/main.gd`。
- 当前原型为了快速形成可玩闭环，把大量表现层和战斗逻辑集中在 `main.gd`。`src/domain/` 下的模块仍然代表长期架构方向，但当前很多战斗、UI、地图交互行为还没有完全迁移进去。

## 启动流程

`scenes/main.tscn` 里只有一个挂载了 `src/app/main.gd` 的 `Node`。

`main.gd` 的 `_ready()` 必须完成这些事：

1. 设置固定物理 tick。
2. 注册输入 action。
3. 初始化领域服务并加载 `content/base`。
4. 创建 `ui_root`。
5. 调用 `_show_starter_screen()`。

健康启动日志应该包含：

```text
Puritato playable slice ready. Registered types: [...]
```

如果启动时只打印旧的 architecture bootstrap 文本，或者 `_show_starter_screen()` 没有被调用，游戏可能会启动成空白灰屏。2026-05-16 的灰屏问题就是因为 `main.gd` 被覆盖回了旧的架构初始化脚本。

## 运行时界面

当前界面状态由 `src/app/main.gd` 中的 `screen` 字符串记录。

- `starter`：初始装备选择。
- `map`：路线选择和奖励节点。
- `reward`：奖励选择界面。
- `shop`：商店购买界面。
- `combat`：生存战斗。
- `defeat`：失败重试界面。
- `victory`：通关界面。

`_clear_screen()` 会清空 `ui_root` 的子节点，并清理临时战斗数组。每个界面切换时都会重新构建 UI。

## 缩放模型

当前原型使用固定逻辑画布：

```gdscript
const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)
```

`_update_ui_root_transform()` 会把 `ui_root` 等比缩放并居中放进真实 Godot viewport。玩法坐标、点击热点、奖励节点、战斗区域都使用 1280x720 的逻辑坐标。新增交互 UI 时应放在 `ui_root` 下，避免全屏或窗口缩放后点击判定错位。

## 当前玩法闭环

1. 从 `starter` 开始。
2. 点击卡片/图标选择一把初始武器。
3. 进入 `map`。
4. 点击左路线或右路线。
5. 只有已选择路线上的奖励节点可交互，另一侧只做预览。
6. 领取当前路线全部奖励。
7. 点击战斗节点。
8. 进入小怪阶段。
9. Boss 出现并进入 Boss 阶段。
10. 击败 Boss 后推进到下一层地图。

路线数据来自 `content/base/maps/demo_map.json`，通过 `MapFlow` 读取。

## 装备规则

`RunContext` 当前初始化为：

```gdscript
equipped_weapons.resize(4)
equipped_magics.resize(4)
```

重要规则：武器最多 4 个自动装备槽。`RunContext.add_weapon()` 会把所有获得的武器加入 `inventory["weapons"]`，然后 `_auto_equip()` 只填充空的装备槽。4 个槽满后，后续武器只留在库存里，在背包和装备 UI 做出来之前，不应该参与战斗生效。

`main.gd` 中也必须通过 `_equipped_weapon_count()` 统计已装备武器，而不是直接使用库存数量。

## 战斗实现

当前战斗主要在 `main.gd` 中实现，还没有完全使用 `CombatRuntime`。

主要状态包括：

- `player_pos`、`player_hp`、`player_mana`
- `enemies`
- `boss_enemy`
- `boss_projectiles`
- `combat_weapon_sprites`
- `magic_cooldowns`

`_update_combat(delta)` 的更新顺序：

1. 更新计时器、法力和移动。
2. 更新武器自动攻击。
3. 处理魔法输入。
4. 更新魔法冷却。
5. 刷小怪或 Boss。
6. 更新敌人。
7. 更新 Boss 技能。
8. 更新 Boss 子弹。
9. 更新角色、武器、HUD 表现。

碰撞都使用简单图形：

- 敌人接触伤害使用 `ENEMY_TOUCH_RADIUS` 做距离判定。
- 玩家和 Boss 子弹使用圆形距离判定。
- 战斗边界使用 `COMBAT_ARENA_RECT`。

运行时碰撞不需要和贴图轮廓一致。

## 玩家、武器和魔法输入

移动：

- `WASD`
- 方向键

魔法槽：

- 1 号槽：`Q`
- 2 号槽：`E`
- 3 号槽：`R`
- 4 号槽：`F`

武器会自动锁定最近敌人并按冷却攻击。当前薯条武器通过最多 4 个漂浮武器 sprite 围绕玩家展示。武器数量表现必须对应已装备数量，而不是库存数量。

## Boss 技能

Demo Boss 在小怪阶段结束后出现。

当前 Boss 特殊技能：

- 冷却：8 秒。
- 施法/预警时长：约 0.65 秒。
- 子弹数量：16 个。
- 形态：圆形扩散弹幕。
- 子弹伤害：等于 Boss 接触伤害。
- 子弹资源：`res://assets/art/source/magic_vfx/magic_vfx-2.png`。
- 施法预警资源：`res://assets/art/source/enemy_pack_01/boss_pollution_source_warning/boss_pollution_source_warning-1.png`。

相关函数：

- `_update_boss_ability(delta)`
- `_play_boss_cast_motion()`
- `_spawn_boss_radial_projectiles()`
- `_update_boss_projectiles(delta)`

## 动画说明

当前运行时直接使用已有帧目录：

- 玩家 idle：`assets/art/source/potato_hero_idle_handless/`
- 玩家 walk：`assets/art/source/potato_hero_walk_handless/`
- 发芽土豆：`assets/art/source/sprouting_potato/`
- 蘑菇孢子：`assets/art/source/enemy_pack_01/mushroom_spore/`
- 炸弹果苗：`assets/art/source/enemy_pack_01/bomb_fruitling/`
- Boss：`assets/art/source/boss_pollution_source/`

角色和怪物动态优先使用换帧、上下伸缩和左右伸缩。不要用旋转来做 idle 动态，之前的旋转表现显得不稳定。

## 资源兜底

当前可运行切片直接使用路线背景：

- `res://assets/art/map/backgrounds/chapter_1_route_background.png`
- `res://assets/art/map/backgrounds/chapter_2_route_background.png`

部分规划中的界面资源目前缺失：

- `assets/art/screens/main_menu_background.png`
- `assets/art/map/arenas/chapter_1_arena.png`
- `assets/art/map/arenas/chapter_2_arena.png`

不要默认认为这些缺失资源一定会导致启动失败。恢复后的原型已经避免在启动阶段强依赖它们。

## 内容加载

内容由 `ContentConfigLoader` 加载进 `ContentRegistry`。

健康启动时当前注册的内容类型：

- `school`
- `character`
- `weapon`
- `magic`
- `item`
- `buff`
- `monster`
- `boss`
- `map`
- `reward_table`
- `shop`
- `audio`
- `asset`

`content/base/scene_art` 目录存在，但当前恢复后的可玩切片不依赖 `scene_art` 注册类型启动。

## 常见问题

### 启动灰屏

最可能原因：`src/app/main.gd` 被覆盖回旧的 architecture-only bootstrap。

检查：

```powershell
rg -n "playable slice ready|_show_starter_screen|LOGICAL_VIEWPORT_SIZE" src\app\main.gd
```

期望结果：

- 存在 `LOGICAL_VIEWPORT_SIZE`。
- `_ready()` 调用了 `_show_starter_screen()`。
- 启动日志打印 `Puritato playable slice ready`。

### 武器数量显示不对

检查 UI 或战斗逻辑是否错误地使用了库存数量。玩法应使用 `_equipped_weapon_count()` 和 `run_context.equipped_weapons`，最多 4 个。

### 全屏后点击错位

检查新 UI 是否被加到了 `ui_root` 外面。当前可运行切片的交互元素都应该放在 `ui_root` 下，并使用逻辑坐标。

### 缺背景导致疑似灰屏

缺失规划中的屏幕背景时，应优先使用已有路线背景兜底。除非对应文件已经提交，不要重新引入对 `assets/art/screens/main_menu_background.png` 的硬依赖。

## 验证清单

提交玩法改动前建议运行：

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game diff --check
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

Godot 输出中应包含：

```text
Puritato playable slice ready.
```

启动可见窗口：

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

## Git 注意事项

打开 Godot 后，仓库里可能出现大量未跟踪的 `.import` 文件。不要盲目提交它们。优先只提交当前任务真正需要的文件。

保存一个已知可运行状态时，至少关注：

- `src/app/main.gd`
- `src/domain/run/run_context.gd`
- 当前运行所需的内容配置或资源注册文件

遇到严重回退时，可以把稳定提交 `d6ea0ca` 作为恢复参考。
