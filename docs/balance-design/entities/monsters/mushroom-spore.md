# 蘑菇孢子

| 项 | 值 |
|-|-|
| Entity ID | `monster.metamorph.mushroom_spore` |
| 类型 | monster |
| 学派 | 变形学派，未来可迁到感染学派 |
| 当前配置 | `content/base/monsters/mushroom_spore.json` |
| 设计状态 | ready |

## 定位

蘑菇孢子是慢速压力怪。短期在代码未实现远程/毒雾前，它可以作为慢速肉盾；长期应转为感染学派入门怪，通过毒雾或减益迫使玩家移动。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `max_health` | 40 |
| `attack` | 5 |
| `move_speed` | 65 |
| `knockback_resistance` | 0.1 |
| `toughness` | 8 |
| `max_health_per_floor` | 4 |
| `attack_per_floor` | 1 |
| `spawn.weight` | 1.0 |

## 建议重设计值

短期可实现版本：

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `max_health` | 28 | 比基础怪肉，但不拖 |
| `attack` | 5 | 接触伤害中等 |
| `move_speed` | 75 | 慢速压空间 |
| `knockback_resistance` | 0.15 | 稍抗击退 |
| `toughness` | 14 | 比基础怪更难破韧 |
| `spawn.weight` | 0.8 | 中频出现 |
| `first_floor` | 2 | 第 2 层开始出现 |
| `role` | `slow_pressure` | 设计标签 |

未来完整版本：

| 字段 | 建议值 |
|-|-:|
| `spore_cloud_cooldown_seconds` | 5 |
| `spore_cloud_radius` | 72 |
| `spore_cloud_duration_seconds` | 3 |
| `spore_cloud_tick_seconds` | 1 |
| `spore_cloud_effect` | 施加 1 层未来的 poison buff 或 `move_speed -15%` |

## 预算说明

当前 40 生命、65 速度容易变成“慢但烦的血袋”。重设计降低生命、提高一点速度和韧性，让它更像节奏变化。未来毒雾实现后，生命还可以再降到 22-26，把预算让给区域压力。

## 交互关系

- 与爆破/范围武器：慢速聚集，适合被范围伤害清理。
- 与移动速度：玩家速度低时，毒雾会显著提高压力。
- 与感染学派：未来可作为 poison 教学敌人。

## 验证目标

- 第 2 层出现时，玩家能明显感觉它比发芽土豆更耐打。
- 单只蘑菇孢子不应造成威胁，2-3 只与追击怪混合时形成走位压力。
- 若未来启用毒雾，玩家必须愿意离开原地，但不应被毒雾瞬间击杀。

## 后续实现备注

当前怪物行为只配置 `move_toward_player` 和 `contact_damage`。毒雾、远程和减速都属于未来字段。
