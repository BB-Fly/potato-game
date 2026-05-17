# 模块拆分路线

本文档记录 `src/app/main.gd` 的拆分原则、当前已拆模块，以及后续建议顺序。

## 为什么要拆

当前可运行切片最早为了快速闭环，把启动、地图、奖励、商店、战斗、HUD、动画、资源映射都放进了 `src/app/main.gd`。这让功能验证很快，但随着系统增加，会出现几个问题：

- 单文件过长，定位困难。
- 地图和战斗状态混在一起，改动风险高。
- UI 工具、内容展示、输入注册等纯工具逻辑重复占据主流程空间。
- 后续背包、装备、buff、Boss 技能、商店服务扩展时，`main.gd` 会越来越难维护。

拆分目标不是一次性重写，而是把“稳定可运行”放在第一位，按风险从低到高逐步迁移。

## 第一阶段：已完成的低风险拆分

当前新增目录：

```text
src/app/playable/
  playable_ui_factory.gd
  playable_input_actions.gd
  playable_content_presenter.gd
  playable_map_controller.gd
  playable_reward_controller.gd
```

### `playable_ui_factory.gd`

职责：

- 创建 `Label`
- 创建像素风按钮
- 创建 `ProgressBar`
- 创建 `TextureRect` sprite
- 更新 sprite 坐标
- 创建 `StyleBoxFlat`
- 加载 `Texture2D`

从 `main.gd` 迁出的函数：

- `_make_label`
- `_make_pixel_button`
- `_make_bar`
- `_make_sprite`
- `_update_sprite_position`
- `_style_box`
- `_load_texture`

`main.gd` 暂时保留同名 wrapper，内部委托给 `PlayableUiFactory`。

### `playable_input_actions.gd`

职责：

- 注册移动输入。
- 注册 4 个魔法槽输入。
- 避免重复添加相同按键事件。

从 `main.gd` 迁出的函数：

- `_ensure_input_actions`
- `_ensure_action`

### `playable_content_presenter.gd`

职责：

- 内容 ID 到显示名称。
- 地图节点类型到显示名称。
- 地图节点标签。
- 内容 icon 路径。
- 内容 sprite 路径。
- 敌人和 Boss 动画帧表。
- 稀有度颜色。

从 `main.gd` 迁出的函数：

- `_content_name`
- `_node_label`
- `_node_type_name`
- `_node_icon_path`
- `_content_icon_path`
- `_content_sprite_path`
- `_enemy_frame_paths`
- `_rarity_color`

这些函数暂时仍通过 `main.gd` wrapper 调用。

## 当前仍留在 `main.gd` 的内容

短期仍留在 `main.gd`：

- 应用启动和服务创建。
- `ui_root` 缩放。
- 界面状态切换。
- starter/map/reward/shop/combat screen 构建。
- 地图、奖励、商店 UI 的具体创建。
- 战斗实体数组和更新循环。
- Boss 技能逻辑。
- HUD 更新。

这些逻辑互相引用较多，直接搬走风险较高，需要按功能边界逐步拆。

## 第二阶段：已完成的地图和奖励基础拆分

当前新增：

```text
src/app/playable/playable_map_controller.gd
src/app/playable/playable_reward_controller.gd
```

### `playable_map_controller.gd`

职责：

- 持有 `selected_route_id`。
- 持有 `active_route`。
- 持有 `claimed_route_nodes`。
- 调用 `MapFlow.choose_route()`。
- 判断路线是否选中、锁定、预览。
- 判断奖励节点是否可点击。
- 读取当前路线节点数据。
- 判断路线奖励是否全部领取。
- 判断战斗入口是否锁定。

`main.gd` 仍负责地图画面创建，但路线状态和点击规则已经委托给 `PlayableMapController`。

### `playable_reward_controller.gd`

职责：

- 根据 `reward_id` 判断 `content_type`。
- 根据商店节点类型判断 `content_type`。
- 调用 `ItemPoolService.roll_offer()`。
- 使用填充策略保证三选一数量。
- 生成开局奖励、路线奖励、商店候选。
- 处理内容发放。
- 处理当前简化商店购买逻辑。

`main.gd` 暂时保留 `_grant_content()`、`_fill_offer_choices()` 等 wrapper，内部委托给 `PlayableRewardController`。这样 reward/shop/starter 共用同一套候选生成和发放逻辑。

## 第三阶段建议：拆战斗状态和系统

建议新增：

```text
src/app/playable/combat/
  playable_combat_state.gd
  playable_spawn_system.gd
  playable_weapon_system.gd
  playable_magic_system.gd
  playable_boss_system.gd
  playable_collision.gd
```

拆分顺序建议：

1. `PlayableCombatState`：只搬变量和初始化，不改逻辑。
2. `PlayableCollision`：搬简单圆形/矩形判定。
3. `PlayableSpawnSystem`：搬 `_spawn_mob()` 和 `_spawn_boss()`。
4. `PlayableWeaponSystem`：搬自动攻击和武器布局。
5. `PlayableMagicSystem`：搬魔法输入、冷却和释放。
6. `PlayableBossSystem`：搬 16 向弹幕和施法动作。

每一步都必须跑 Godot headless，确保仍然出现：

```text
Puritato playable slice ready.
```

## 长期目标

当原型稳定后，可以逐步迁回长期领域架构：

- 逻辑结算进入 `src/domain/combat/combat_runtime.gd`。
- UI 和表现留在 `src/app/` 或未来 `src/presentation/`。
- 武器、魔法、buff、Boss 技能改成数据驱动。
- `main.gd` 最终只负责启动、screen orchestration 和表现层桥接。

## 拆分原则

- 一次只拆一个边界。
- 优先拆无状态工具，再拆弱状态服务，最后拆战斗状态机。
- 每次拆分都保持函数名或 wrapper，减少调用点同时变化。
- 不在拆分 PR 中顺手改玩法数值。
- 不在拆分 PR 中批量提交 `.import` 文件。
- 每次拆分后更新本文档。

## 本轮验证

第一阶段和第二阶段拆分后已运行：

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game diff --check -- src/app/main.gd src/app/playable
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

Godot headless 通过，日志包含 `Puritato playable slice ready`。
