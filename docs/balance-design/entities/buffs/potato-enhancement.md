# 土豆强化 Buff

| 项 | 值 |
|-|-|
| Entity ID | `buff.potato_enhancement` |
| 类型 | buff |
| 当前配置 | `content/base/buffs/base_buffs.json` |
| 设计状态 | ready |

## 定位

土豆强化 Buff 是道具 `@entities/items/potato-enhancement.md` 的永久属性承载。它应该可堆叠、有上限、每层都能看懂。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `stacking_mode` | `independent_timers` |
| `max_stacks` | 999 |
| `duration_frames` | -1 |
| `melee_attack` | +2/层 |
| `ranged_attack` | +1/层 |
| `health_regen` | +2/层 |
| `mana_regen` | +1/层 |
| `defense` | +1/层 |
| `max_health` | +5/层 |
| `max_mana` | +5/层 |

`independent_timers` 与永久持续不匹配，且 999 层过高。

## 建议重设计值

| 字段 | 建议值 |
|-|-:|
| `stacking_mode` | `permanent_stack` |
| `max_stacks` | 6 |
| `duration_frames` | -1 |
| `max_health` | +5/层 |
| `max_mana` | +4/层 |
| `melee_attack` | +1/层 |
| `ranged_attack` | +1/层 |
| `spell_power` | +1/层 |
| `mana_regen` | +1/层 |

里程碑：

```text
3 层：defense +1
6 层：额外 defense +1，reward_rarity_percent +5%
```

如果里程碑暂不实现：

```text
defense +0.35/层
```

## 具体作用数值

土豆强化 Buff 永久存在，最多 6 层。每层属性：

| 属性 | 每层 | 6 层合计 |
|-|-:|-:|
| `max_health` | +5 | +30 |
| `max_mana` | +4 | +24 |
| `melee_attack` | +1 | +6 |
| `ranged_attack` | +1 | +6 |
| `spell_power` | +1 | +6 |
| `mana_regen` | +1 | +6 |

里程碑完整实现后：

| 层数 | 额外效果 |
|-:|-|
| 3 | `defense +1` |
| 6 | 额外 `defense +1`，`reward_rarity_percent +5%` |

短期未实现里程碑时，使用 `defense +0.35/层` 近似：

| 层数 | 近似防御 |
|-:|-:|
| 1 | +0.35 |
| 3 | +1.05 |
| 6 | +2.10 |

## 预算说明

满层后是一个强成长包，但需要多次获取同一道具。它的目标是帮助变形学派变得全面，而不是在第 1 次获取时立刻变强太多。

## 交互关系

- 只由 `@entities/items/potato-enhancement.md` 施加。
- 与 `@entities/buffs/comprehensive-development.md` 可叠加。
- 不应被常规驱散影响。

## 验证目标

- 1 层时提升温和。
- 3 层时玩家能感到法力循环和容错提高。
- 6 层时成为构筑核心之一，但仍需要武器/法术输出来源。

## 后续实现备注

当前 `BuffInstance.initialize` 使用了 `stack_mode` 字段检查独立计时，而配置使用 `stacking_mode`。后续实现 `permanent_stack` 时需要统一字段名。
