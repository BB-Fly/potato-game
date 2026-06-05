# 全面发展

| 项 | 值 |
|-|-|
| Entity ID | `magic.metamorph.comprehensive_development` |
| 类型 | magic |
| 学派 | 变形学派 |
| 当前配置 | `content/base/magics/comprehensive_development.json` |
| 设计状态 | ready |

## 定位

全面发展是变形学派的代表法术：短时间补齐多个方向，让玩家在关键窗口内输出、防御和资源循环都更顺。它不应是高伤害法术，而应是“通用构筑润滑剂”。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `rarity` | `common` |
| `mana_cost` | 28 |
| `energy_cost` | 15 |
| `cooldown_frames` | 300 |
| `combat_effect.damage` | 52 |
| `combat_effect.range` | 240 |
| `auto_cast_interval_frames` | 900 |
| `auto_cast_is_free` | true |
| 施加 buff | `@entities/buffs/comprehensive-development.md`，600 帧 |

当前配置同时拥有 5 秒冷却、较高伤害、10 秒强 buff、15 秒免费自动施放，作为 common 法术预算过高。

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `rarity` | `common` | 保留开局可见 |
| `mana_cost` | 24 | 比当前略低，鼓励使用 |
| `energy_cost` | 0 | Demo 暂不启用能量成本 |
| `cooldown_frames` | 480 | 8 秒冷却，减少常驻覆盖 |
| `combat_effect.damage` | 34 + `spell_power * 0.8` | 附带小伤害，不是主输出 |
| `combat_effect.range` | 220 | 稍低于当前 |
| `auto_cast_interval_frames` | 1080 | 18 秒免费一次 |
| `auto_cast_is_free` | true | 保留变形学派特色 |
| 施加 buff | `@entities/buffs/comprehensive-development.md`，480 帧 | 8 秒短窗，具体属性加成由 buff 档案定义 |

## Buff 引用

全面发展施加 `@entities/buffs/comprehensive-development.md`。本法术文档只定义施法成本、冷却、附带伤害、自动施放间隔和施加关系；buff 的具体属性加成、持续时间、叠加规则和验证目标以 buff 档案为准。

## 预算说明

重设计后，如果玩家手动施放，最多接近 100% 覆盖，但需要消耗法力；免费自动施放只能提供偶发窗口。它给全构筑一点帮助，但每项都不超过一个稀有升级，避免成为所有流派必拿的最优法术。

## 交互关系

- 与 `@entities/characters/potato-hero.md`：土豆少侠无专精，全面发展提供短时间专精。
- 与 `@entities/weapons/fries.md`：全面发展 buff 中的近战加成会提高薯条击杀效率，但不是永久收益。
- 与 `@entities/items/potato-enhancement.md`：土豆强化提供长期小成长，全面发展提供短窗爆发，两者互补。

## 验证目标

- 第 1-2 层玩家能感到施放后击杀更快。
- 第 3 层后，全面发展单独不能解决 DPS 检查，仍需武器/道具成长。
- 自动施放每场战斗出现 2-5 次，起到惊喜和教学作用。

## 后续实现备注

当前 `combat_effect.damage` 只支持固定数值，建议后续改为与武器一致的 `base + scales` 结构。
