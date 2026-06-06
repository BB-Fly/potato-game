# 数值与 Buff 运行时接手说明

本文记录本次从 demo 结算改成配置驱动运行时后的代码入口。

## 核心入口

```text
content/base/balance/playable_combat.json
```

该配置现在包含：

- `stat_rules`：属性默认值和上下限。
- `operation_aliases`：属性修正操作别名。
- `formulas`：攻速、冷却、暴击、防御、最低伤害等公式常量。
- `scaling.floor_multipliers`：1-6 层普通敌人的生命、攻击、速度、数量倍率。
- `scaling.boss.health_per_floor`：Boss 生命成长曲线。

运行时代码入口：

```text
src/domain/stats/stat_block.gd
src/domain/buff/buff_instance.gd
src/domain/buff/buff_container.gd
src/domain/combat/combat_actor.gd
src/domain/combat/combat_formula.gd
src/domain/effect/effect_runner.gd
src/app/combat/playable_combat_scene.gd
```

## 运行时模型

`CombatActor` 是玩家、普通怪和 Boss 的统一运行时实体，持有：

- `StatBlock`：基础属性和各来源修正。
- `BuffContainer`：buff 叠层、持续时间、周期效果、行为锁和属性修正重建。
- 当前生命、法力、能量和护盾值。

`PlayableCombatScene` 仍负责输入、简单碰撞、VFX 和 HUD，但数值结算已经改为通过 `CombatActor` 和 `CombatFormula`。

## 已接入的配置能力

- 角色基础属性从 `content/base/characters/*.json` 读取。
- 道具的 `effects` 会在战斗开始时应用到玩家 actor。
- 武器支持多槽独立攻击计时，伤害走 `damage.base + damage.scales`。
- 武器 `passive_effects` 的 `on_hit` 会执行，例如薯条命中施加 `buff.bruise`。
- 魔法消耗、冷却缩减、范围和伤害走配置；`effects` 会执行，例如全面发展施加 buff。
- 魔法 `auto_cast_interval_frames` 已接入，会按槽位自动触发。
- Buff 支持 `refresh_duration`、`stack_refresh_duration`、`independent_timers`、`permanent_stack`、`replace_if_stronger`、`unique_by_source`。
- Buff 的 `modifiers` 会按层数重建到目标 `StatBlock`。
- Buff 的 `periodic_effects` 可通过 `EffectRunner` 执行 `deal_damage`、`heal`、`restore_mana` 等效果。
- 怪物生成读取 `spawn.weight`、`first_floor`、`max_simultaneous`。

## 内容作者约定

属性百分比在 JSON 中使用小数，例如 `0.10` 表示 +10%。

属性修正格式：

```json
{"stat": "melee_attack", "operation": "add", "value": 4}
{"stat": "weapon_damage_taken_flat", "operation": "add", "value_per_stack": 1}
```

伤害缩放格式：

```json
{
  "base": 34,
  "scales": [
    {"stat": "spell_power", "ratio": 0.8}
  ]
}
```

秒数字段可以直接写在任意配置层级，加载器会补帧字段：

```json
{"duration_seconds": 8}
{"cooldown_seconds": 6}
{"tick_seconds": 1}
```

## 仍待扩展

- 武器技能尚未接入充能和主动释放。
- Boss 阶段时间轴仍是配置雏形，当前只使用基础弹幕技能。
- 护盾字段已有公式预留，但还没有完整 shield buff 当前值初始化。
- 里程碑类 buff 例如土豆强化 3/6 层额外奖励还没有专用 DSL。
