# 炸弹果苗

| 项 | 值 |
|-|-|
| Entity ID | `monster.metamorph.bomb_fruitling` |
| 类型 | monster |
| 学派 | 变形学派，未来可迁到爆破学派 |
| 当前配置 | `content/base/monsters/bomb_fruitling.json` |
| 设计状态 | ready |

## 定位

炸弹果苗是爆发威胁怪。它应该迫使玩家优先处理或保持距离，而不是作为普通慢速接触怪。短期如果爆炸行为还未实现，可先用更高速度和更高接触伤害表达危险。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `max_health` | 40 |
| `attack` | 5 |
| `move_speed` | 65 |
| `knockback_resistance` | 0.05 |
| `toughness` | 6 |
| `max_health_per_floor` | 4 |
| `attack_per_floor` | 1 |
| `spawn.weight` | 1.0 |

当前与蘑菇孢子过于相似，缺少爆破身份。

## 建议重设计值

短期可实现版本：

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `max_health` | 22 | 可被快速击杀 |
| `attack` | 8 | 接触更痛，代替爆炸威胁 |
| `move_speed` | 115 | 明显快于蘑菇孢子 |
| `knockback_resistance` | 0.05 | 易被击退 |
| `toughness` | 8 | 中低韧性 |
| `spawn.weight` | 0.55 | 低频威胁怪 |
| `first_floor` | 3 | 第 3 层开始出现 |
| `max_simultaneous` | 4 | 避免堆太多瞬间失控 |

未来完整版本：

| 字段 | 建议值 |
|-|-:|
| `explode_on_death` | true |
| `explode_on_contact` | true |
| `explosion_damage` | 14 |
| `explosion_radius` | 88 |
| `explosion_delay_seconds` | 0.45 |
| `warning_duration_seconds` | 0.45 |
| `friendly_fire_to_monsters` | false，默认不炸怪 |

## 预算说明

炸弹果苗的强度来自“必须处理”的优先级，而不是高血量。它低血、较快、低权重，能打乱玩家路线。等爆炸实现后，接触伤害可以降回 5-6，把预算转移到爆炸。

## 交互关系

- 与击退：`@entities/weapons/fries.md` 可以把炸弹果苗推出危险距离。
- 与远程武器：远程构筑能更安全地提前点杀。
- 与 `@entities/bosses/demo-pollution-source.md`：Boss 战继续刷怪时，炸弹果苗数量必须限制，否则会盖过 Boss 技能。

## 验证目标

- 第 3 层首次出现时，玩家能立刻识别它比普通怪危险。
- 单个炸弹果苗应是可处理威胁，多个同时出现才形成爆点。
- Boss 战中每 10 秒出现 1-2 个即可，不宜铺满。

## 后续实现备注

当前无爆炸行为。实现前可以先按短期版本调数值；实现后应降低接触伤害，并加入清晰预警特效。
