# 土豆强化

| 项 | 值 |
|-|-|
| Entity ID | `item.metamorph.potato_enhancement` |
| 类型 | item |
| 学派 | 变形学派 |
| 当前配置 | `content/base/items/potato_enhancement.json` |
| 设计状态 | ready |

## 定位

土豆强化是变形学派的长期成长道具。它不提供华丽规则，而是让角色逐步变得更完整。它应该适合堆叠，但必须有限制，否则会吞掉所有属性型道具的设计空间。

## 当前配置值

| 字段 | 当前值 |
|-|-|
| `rarity` | `legendary` |
| `acquire_limit` | 0，无限 |
| `stacking.mode` | `additive` |
| 效果 | 施加永久 `@entities/buffs/potato-enhancement.md` |

当前 buff 每层提供：

- `melee_attack +2`
- `ranged_attack +1`
- `health_regen +2`
- `mana_regen +1`
- `defense +1`
- `max_health +5`
- `max_mana +5`

在无限堆叠时，这个道具过于全面，长期会成为“看到就拿”的答案。

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `rarity` | `rare` | 从传说降为稀有成长道具 |
| `acquire_limit` | 6 | 有上限，便于平衡 |
| `price` | 115 | 道具商店参考价 |
| `stacking.mode` | `permanent_stack` | 永久叠层 |
| `max_stacks` | 6 | 与获取上限一致 |

效果由 `@entities/buffs/potato-enhancement.md` 承载。道具文档只定义品质、价格、获取上限和施加关系；每层属性、里程碑、叠加规则以 buff 档案为准。

## 预算说明

单层约等于 1.5 个普通升级，但它是稀有道具且有 6 层上限。满层提供 +30 生命、+24 法力、+6 三攻、+6 回蓝、+2 防御，是明显成长核心，但不会无限吞掉后期。

## 交互关系

- 与 `@entities/magics/comprehensive-development.md`：土豆强化给永久小数值，全面发展给短窗高适应。
- 与幸运/奖励：如果后续变形学派有奖励质量加成，土豆强化不应过度高频出现。
- 与传说道具：土豆强化不再占传说定位，传说位应留给规则变化。

## 验证目标

- 拿 1 层时玩家感到“全方面小增强”，但不会改变打法。
- 拿 3 层后能明显提高容错和法术循环。
- 满 6 层仍不能替代专精构筑，输出应低于专门近战/法术核心道具组合。

## 后续实现备注

当前 buff 系统没有 `permanent_stack` 和里程碑规则。短期可以继续用 `duration_frames = -1`，但需要把 `max_stacks` 从 999 降到 6，并统一 `stacking_mode` 字段。
