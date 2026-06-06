# 战斗原型实现

本文档说明当前战斗切片的实际代码位置、更新顺序、输入、敌人、Boss 和碰撞规则。

## 当前边界

目标架构中存在：

```text
src/domain/combat/combat_runtime.gd
```

但当前可运行战斗主要仍在：

```text
scenes/combat_scene.tscn
src/app/combat/playable_combat_scene.gd
```

`src/app/main.gd` 负责局外流程和场景切换：进入战斗时实例化 `combat_scene.tscn`，监听 `combat_finished(result)`，战斗结束后销毁战斗场景，再回到地图或失败界面。

`CombatRuntime` 目前更像长期目标的占位和固定 tick 系统接入点。不要误以为所有战斗逻辑都在 `src/domain/combat/`。

## 战斗入口

```text
_start_combat()
```

`main.gd::_start_combat()` 做：

- 清空界面。
- 实例化 `CombatScenePacked`。
- 连接 `combat_finished` 信号。
- 调用 `combat_scene.setup(registry, run_context, asset_catalog)`。

`PlayableCombatScene.setup()` 做：

- 添加背景、overlay、`combat_layer` 和 `combat_fx_layer`。
- 初始化玩家生命、法力、位置。
- 重置攻击计时、刷怪计时、Boss 状态和魔法冷却。
- 创建玩家 sprite。
- 创建武器 sprite。
- 创建 HUD。

## 更新顺序

`PlayableCombatScene._process(delta)` 调用 `_update_combat(delta)`。

当前顺序：

```text
_update_combat(delta)
  -> _update_player_movement(delta)
  -> _update_player_attack(delta)
  -> _update_magic_input()
  -> _update_magic_cooldowns(delta)
  -> _update_spawning(delta)
  -> _update_enemies(delta)
  -> _update_boss_ability(delta)
  -> _update_boss_projectiles(delta)
  -> _update_player_visual()
  -> _update_weapon_visuals()
  -> _update_combat_hud()
```

这不是最终架构，只是当前原型顺序。未来迁移到固定 tick 时，要明确哪些是逻辑、哪些是表现。

## 生命周期边界

每场战斗都是独立的 `PlayableCombatScene` 实例。

战斗内状态只保存在战斗场景中：

- `enemies`
- `boss_projectiles`
- `floating_texts`
- `magic_cooldowns`
- `combat_weapon_sprites`
- `magic_slot_nodes`

战斗结束时：

```text
PlayableCombatScene._end_combat(victory)
  -> combat_finished.emit(result)
  -> main.gd::_on_combat_finished(result)
  -> combat_scene.cleanup()
  -> combat_scene.queue_free()
```

因此，局内实体、局内 buff、弹幕、特效和 HUD 都应该挂在 `PlayableCombatScene` 下面。跨战斗状态只能写回 `RunContext`，例如金币、武器、魔法、背包和地图进度。

## 玩家

核心变量：

- `player_pos`
- `player_hp`
- `player_max_hp`
- `player_mana`
- `player_max_mana`
- `player_mana_regen`
- `facing_direction`
- `is_player_moving`

移动输入：

- `move_left`
- `move_right`
- `move_up`
- `move_down`

绑定按键：

- `WASD`
- 方向键

玩家位置被限制在：

```gdscript
const COMBAT_ARENA_RECT = Rect2(Vector2(48, 118), Vector2(1184, 560))
```

## 武器

当前武器是自动攻击。

关键常量：

```gdscript
const WEAPON_RANGE = 285.0
const WEAPON_ATTACK_SECONDS = 0.72
```

流程：

```text
_update_player_attack(delta)
  -> _nearest_enemy()
  -> 判断距离
  -> 扣血
  -> _flash_attack()
  -> _kill_enemy()
```

武器视觉：

- `_build_weapon_sprites()`
- `_update_weapon_visuals()`
- `_weapon_layout_offsets()`

武器显示数量必须来自 `_equipped_weapon_count()`，不能来自库存数量。

## 魔法

当前有 4 个魔法槽。

按键：

- `Q` -> `cast_magic_0`
- `E` -> `cast_magic_1`
- `R` -> `cast_magic_2`
- `F` -> `cast_magic_3`

关键函数：

- `_update_magic_input()`
- `_try_cast_magic(slot_index)`
- `_update_magic_cooldowns(delta)`

当前魔法效果是原型通用效果：消耗法力，对玩家附近敌人造成伤害，并播放 VFX。未来应根据 `magic_id` 分发到不同魔法行为。

## 小怪

刷怪入口：

```text
_update_spawning(delta)
_spawn_mob()
```

当前可刷怪物 ID 硬编码在 `_spawn_mob()`：

- `monster.metamorph.sprouting_potato`
- `monster.metamorph.mushroom_spore`
- `monster.metamorph.bomb_fruitling`

怪物行为：

- 从战斗区域边缘随机生成。
- 向玩家移动。
- 距离足够近时造成接触伤害。
- 使用简单触碰冷却避免每帧扣血。

未来建议把可刷怪物列表、权重、章节限制、数量上限迁到配置。

## Boss

Boss 生成：

```text
_spawn_boss()
```

触发条件：

```gdscript
combat_elapsed >= MOB_PHASE_SECONDS
```

当前 Boss ID：

```text
boss.demo_pollution_source
```

Boss 使用 `content/base/bosses/demo_pollution_source.json` 的基础属性，但技能行为仍硬编码在 `PlayableCombatScene`。

## Boss 16 向弹幕

相关函数：

- `_update_boss_ability(delta)`
- `_play_boss_cast_motion()`
- `_spawn_boss_radial_projectiles()`
- `_update_boss_projectiles(delta)`

规则：

- 冷却 8 秒。
- 施法时播放 Boss 动作和 warning 图标。
- 延迟后生成 16 个子弹。
- 子弹方向为 `TAU * i / 16.0`。
- 子弹伤害等于 Boss 接触伤害。
- 子弹与玩家使用圆形距离判定。

## 动画

玩家：

- idle：`potato_hero_idle_handless`
- walk：`potato_hero_walk_handless`

怪物：

- `sprouting_potato`
- `mushroom_spore`
- `bomb_fruitling`：4x3 状态帧表，第一行 4 帧睡眠呼吸，第二行 4 帧点燃，第三行 4 帧奔跑哭泣。本体不再烘焙 ZZZ、尘土和复杂腿部；睡眠 ZZZ、奔跑尘土是独立 VFX，醒后奔跑使用前后两层风火轮 VFX 贴在身体下缘。

Boss：

- `boss_pollution_source-1.png` 到 `boss_pollution_source-9.png`

表现原则：

- 角色、怪物和 Boss 使用换帧、上下伸缩、左右伸缩。
- 不使用旋转做 idle 动态。
- 武器和 VFX 可以旋转，因为它们不是角色本体。

## 碰撞规则

当前使用简单图形：

- 玩家触碰半径：`PLAYER_TOUCH_RADIUS`
- 敌人触碰半径：`ENEMY_TOUCH_RADIUS`
- Boss 子弹半径：projectile dictionary 中的 `radius`
- 战斗区域：`COMBAT_ARENA_RECT`

`monster.metamorph.bomb_fruitling` 使用同一套圆形距离判定，但醒后接触玩家或撞到其他敌方角色时不走普通接触伤害，而是触发 `monster.bomb_fruitling.explosion_vfx` 并造成范围伤害。睡眠时周期生成 `monster.bomb_fruitling.sleep_zzz_vfx`，奔跑时显示 `monster.bomb_fruitling.fire_wheel_vfx` 并在脚后生成 `monster.bomb_fruitling.run_dust_vfx`，这些独立 VFX 按自身时间线淡出。

不要为了贴合贴图轮廓引入复杂碰撞。当前设计要求所有物品和角色碰撞箱都使用简单图形。

## 迁移建议

后续要继续拆战斗内部时，建议顺序：

1. 从 `PlayableCombatScene` 提取只读 combat view model，先不改玩法。
2. 提取 spawn 系统。
3. 提取 weapon attack 系统。
4. 提取 magic cast 系统。
5. 提取 boss ability 系统。
6. 最后让 `CombatRuntime` 接管逻辑 tick，`main.gd` 只保留表现和输入桥接。
