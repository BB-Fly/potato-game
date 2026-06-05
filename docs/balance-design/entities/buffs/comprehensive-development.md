# 全面发展 Buff

| 项 | 值 |
|-|-|
| Entity ID | `buff.comprehensive_development` |
| 类型 | buff |
| 当前配置 | `content/base/buffs/base_buffs.json` |
| 设计状态 | ready |

## 定位

全面发展 Buff 是变形学派的短窗全能增益。它应该让玩家在 8 秒内更能打、更耐打、更顺畅施法，但不能覆盖全局成长。

## 当前配置值

| 属性 | 当前值 |
|-|-:|
| `melee_attack` | +10 |
| `ranged_attack` | +5 |
| `health_regen` | +5 |
| `mana_regen` | +3 |
| `defense` | +5 |
| `duration_frames` | 600 |
| `stacking_mode` | `refresh_duration` |

当前近战和防御加成很高，且持续 10 秒。配合 5 秒冷却的法术时接近常驻强 buff。

## 建议重设计值

| 属性 | 建议值 |
|-|-:|
| `melee_attack` | +4 |
| `ranged_attack` | +4 |
| `spell_power` | +4 |
| `defense` | +2 |
| `health_regen` | +1 |
| `mana_regen` | +4 |
| `duration_frames` | 480 |
| `stacking_mode` | `refresh_duration` |
| `max_stacks` | 1 |

## 具体作用数值

全面发展 Buff 不叠层，重复获得只刷新持续时间。持续 480 帧，即 8 秒。

| 属性 | 加成 | 说明 |
|-|-:|-|
| `melee_attack` | +4 | 提升近战武器基础伤害 |
| `ranged_attack` | +4 | 提升远程武器基础伤害 |
| `spell_power` | +4 | 提升法术伤害、治疗或护盾 |
| `defense` | +2 | 降低承伤，详见 `@balance-design/stat-calculation-reference.md` |
| `health_regen` | +1 | 每秒额外恢复 1 生命 |
| `mana_regen` | +4 | 每秒额外恢复 4 法力 |

示例：

```text
土豆少侠基础 mana_regen = 10
全面发展 Buff = +4
持续期间 mana_regen = 14 / 秒
8 秒内理论额外恢复 = 4 * 8 = 32 法力
```

## 预算说明

每项加成接近 1-2 个普通升级，但持续时间有限。加入 `spell_power` 后，法术构筑也能受益；降低 `defense` 和 `health_regen`，避免它变成过强防御按钮。

## 交互关系

- 由法术 `@entities/magics/comprehensive-development.md` 施加。
- 与 `@entities/buffs/potato-enhancement.md` 叠加时，形成“永久成长 + 临时适应”的变形学派体验。
- 与所有武器/法术都有一点关系，但不会替代专精道具。

## 验证目标

- 施放后 8 秒内，`@entities/weapons/fries.md` 的击杀效率提高约 20%-30%。
- 防御收益能让玩家多承受 1 次小怪接触，但不能硬吃 Boss 技能。
- 法力恢复提高能帮助接下一次施法，但不能让法力永远满。

## 后续实现备注

当前属性系统未包含 `spell_power`。实现前可先只使用已存在字段；实现后补回。
