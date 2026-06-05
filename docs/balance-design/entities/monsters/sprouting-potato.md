# 发芽土豆

| 项 | 值 |
|-|-|
| Entity ID | `monster.metamorph.sprouting_potato` |
| 类型 | monster |
| 学派 | 变形学派 |
| 当前配置 | `content/base/monsters/sprouting_potato.json` |
| 设计状态 | ready |

## 定位

发芽土豆是最基础的追击怪，用来建立战斗节奏和击杀反馈。它应该成群出现、行为简单、血量低，让玩家清楚理解武器攻击、击退和瘀伤。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `max_health` | 10 |
| `attack` | 4 |
| `move_speed` | 100 |
| `knockback_resistance` | 0.2 |
| `toughness` | 10 |
| `max_health_per_floor` | 5 |
| `attack_per_floor` | 2 |
| `spawn.weight` | 1.0 |

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `max_health` | 12 | 第 1 层被薯条 1 次命中接近击杀，留少量成长空间 |
| `attack` | 4 | 保持基础伤害 |
| `move_speed` | 125 | 更像小型追击怪 |
| `knockback_resistance` | 0.10 | 容易被击退，强化打击感 |
| `toughness` | 8 | 容易破韧 |
| `growth.mode` | `global_floor_multiplier` | 使用全局层数倍率 |
| `spawn.weight` | 1.4 | 作为基础怪高频出现 |
| `first_floor` | 1 | 开局出现 |
| `max_simultaneous_bias` | 高 | 可作为填充怪 |

若短期继续使用线性成长：

| 字段 | 建议值 |
|-|-:|
| `max_health_per_floor` | 3 |
| `attack_per_floor` | 0.8 |

## 预算说明

它的压力来自数量和速度，不来自单体血量。生命不应太高，否则开局武器会显得钝；攻击也不应太高，否则玩家会把它误解为精英压力。

## 交互关系

- `@entities/weapons/fries.md` 应能快速清理发芽土豆。
- 瘀伤对它不是主要价值，因为它通常很快死亡。
- 适合被爆炸、穿透、弹跳等机制作为清群展示目标。

## 验证目标

- 第 1 层裸薯条命中 1-2 次击杀。
- 5 只以内围住玩家时有压力，但可通过移动脱身。
- 第 4 层后逐渐退居杂兵，主要由数量形成背景压力。

## 后续实现备注

建议怪物成长最终统一使用全局层倍率，减少每个怪单独线性成长导致的调参噪音。
