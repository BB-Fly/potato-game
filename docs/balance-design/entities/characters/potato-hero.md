# 土豆少侠

| 项 | 值 |
|-|-|
| Entity ID | `character.potato_hero` |
| 类型 | character |
| 学派 | 变形学派 |
| 当前配置 | `content/base/characters/potato_hero.json` |
| 设计状态 | ready |

## 定位

土豆少侠是默认角色和新手基准角色。定位是均衡、耐玩、容易理解：没有明显输出专精，但通过稳定生命、法力和商店首购折扣，让玩家更容易尝试武器、法术、道具三条成长线。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `max_health` | 110 |
| `max_mana` | 80 |
| `max_energy` | 0 |
| `melee_attack` | 0 |
| `ranged_attack` | 0 |
| `attack_range` | 0 |
| `move_speed` | 220 |
| `defense` | 0 |
| `attack_speed` | 0 |
| `crit_damage` | 0 |
| `execute_damage` | 0 |
| `attack_multiplier` | 0 |
| `damage_reduction` | 0 |
| `health_regen` | 2 |
| `mana_regen` | 12 |
| 被动 | 每个商店第一次购买半价 |

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `max_health` | 115 | 比标准均衡角色略高，降低新手失误惩罚 |
| `max_mana` | 80 | 保持现值，支持 2-3 次连续施法 |
| `max_energy` | 0 | Demo 暂不启用能量 |
| `melee_attack` | 0 | 不偏近战 |
| `ranged_attack` | 0 | 不偏远程 |
| `spell_power` | 0 | 新增建议字段，不偏法术 |
| `move_speed` | 220 | 保持均衡速度 |
| `defense` | 1 | 给默认角色轻微有效生命，体感更稳 |
| `attack_speed` | 0 | 不提供隐藏输出 |
| `cooldown_reduction` | 0 | 不提供隐藏法术循环 |
| `crit_chance` | 0 | 用新字段替代旧 `crit_damage` 的歧义 |
| `crit_multiplier` | 2.0 | 默认暴击倍率 |
| `health_regen` | 2 | 每秒恢复 2 生命，详见 `@balance-design/stat-calculation-reference.md` |
| `mana_regen` | 10 | 每秒恢复 10 法力，从 12 微降，避免法术过早无限循环 |
| `luck` | 0 | 默认奖励质量 |

被动建议保留：

```text
passive.chivalrous_discount
每个商店节点第一次购买商品价格 * 0.5。
不影响刷新、融合、强化等服务价格。
```

## 预算说明

首购半价是中强被动，长期收益高于单个普通道具。因此角色本体不应再给输出倾向。`defense +1` 是为了让默认角色在第 1-2 层更稳定，不应继续叠加攻击或幸运。

`mana_regen` 从 12 调到 10，是为了配合“全面发展”法力消耗下调后的循环：玩家可以常用法术，但仍需要考虑时机。

## 交互关系

- 与 `@entities/weapons/fries.md`：没有近战加成，薯条表现代表武器自身基准。
- 与 `@entities/magics/comprehensive-development.md`：全面发展会施加 `@entities/buffs/comprehensive-development.md`，临时补齐近战、远程和法术强度。
- 与 `@entities/items/potato-enhancement.md`：土豆强化提供长期小幅成长，弥补默认角色无专精的问题。

## 验证目标

- 第 1 层玩家在只持有薯条时，允许 3-5 次普通怪接触失误仍有恢复空间。
- 第 2 层如果购买 1 件商品，首购半价应让玩家明显感到路线奖励有用，但不能让每层稳定买空商店。
- 不拿任何输出道具时，第 4 层开始应明显感到击杀效率不足，推动玩家选择构筑方向。

## 后续实现备注

当前 JSON 中没有 `spell_power`、`cooldown_reduction`、`crit_chance`、`crit_multiplier`、`luck` 字段。下一轮实现属性系统时应补齐，或建立默认值表。
