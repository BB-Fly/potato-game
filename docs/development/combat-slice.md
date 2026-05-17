# 战斗原型实现

本文档说明当前战斗切片的实际代码位置、更新顺序、输入、敌人、Boss 和碰撞规则。

## 当前边界

目标架构中存在：

```text
src/domain/combat/combat_runtime.gd
```

但当前可运行战斗主要仍在：

```text
src/app/main.gd
```

`CombatRuntime` 目前更像长期目标的占位和固定 tick 系统接入点。不要误以为所有战斗逻辑都在 `src/domain/combat/`。

## 战斗入口

```text
_start_combat()
```

主要初始化：

- 清空界面。
- 添加背景、overlay、`combat_layer` 和 `combat_fx_layer`。
- 初始化玩家生命、法力、位置。
- 重置攻击计时、刷怪计时、Boss 状态和魔法冷却。
- 创建玩家 sprite。
- 创建武器 sprite。
- 创建 HUD。

## 更新顺序

`_process(delta)` 在 `screen == "combat"` 时调用 `_update_combat(delta)`。

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

Boss 使用 `content/base/bosses/demo_pollution_source.json` 的基础属性，但技能行为仍硬编码在 `main.gd`。

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
- `bomb_fruitling`

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

不要为了贴合贴图轮廓引入复杂碰撞。当前设计要求所有物品和角色碰撞箱都使用简单图形。

## 迁移建议

后续要把战斗从 `main.gd` 拆出去时，建议顺序：

1. 提取只读 combat view model，先不改玩法。
2. 提取 spawn 系统。
3. 提取 weapon attack 系统。
4. 提取 magic cast 系统。
5. 提取 boss ability 系统。
6. 最后让 `CombatRuntime` 接管逻辑 tick，`main.gd` 只保留表现和输入桥接。
