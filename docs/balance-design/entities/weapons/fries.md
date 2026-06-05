# 薯条

| 项 | 值 |
|-|-|
| Entity ID | `weapon.metamorph.fries` |
| 类型 | weapon |
| 学派 | 变形学派 |
| 当前配置 | `content/base/weapons/fries.json` |
| 设计状态 | ready |

## 定位

薯条是默认近战武器，承担第 1 层的基础清怪能力。它应该稳定、可读、能展示破韧和瘀伤机制，但不应该同时拥有高频、高伤害、大范围和强控制。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `rarity` | `common` |
| `damage.base` | 22 |
| `damage.scales` | `melee_attack * 1.0` |
| `attack_interval_frames` | 25 |
| `range` | 188 |
| `crit_chance` | 0 |
| `crit_multiplier` | 2.0 |
| `toughness_damage` | 4 |
| `execute_damage_multiplier` | 2.0 |
| `knockback` | 15 |
| 普攻被动 | 命中施加 1 层 `@entities/buffs/bruise.md` |
| 武器技能 | 900 帧充能，40 伤害，眩晕 120 帧 |

按 60 FPS 估算，当前攻速约 0.42 秒一次。以 22 基础伤害计算，裸装基础 DPS 约 52.8，不含瘀伤和技能，作为开局 common 武器偏高。

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `rarity` | `common` | 开局基础武器 |
| `damage.base` | 16 | 降低裸装 DPS |
| `damage.scales` | `melee_attack * 1.0` | 保留清晰缩放 |
| `attack_interval_frames` | 36 | 0.6 秒一次，稳定但不过载触发 |
| `range` | 150 | 仍有棍类优势，但不覆盖太大安全区 |
| `crit_chance` | 0.03 | 给少量惊喜，不作为核心 |
| `crit_multiplier` | 2.0 | 默认 |
| `toughness_damage` | 5 | 战斗学派味道的轻破韧 |
| `execute_damage_multiplier` | 1.75 | 普通武器处决不宜过高 |
| `knockback` | 12 | 保留手感，降低控场强度 |
| 普攻被动 | 命中施加 1 层 `@entities/buffs/bruise.md` | 最大价值来自持续敲打，具体加伤数值由 buff 档案定义 |
| 技能充能 | 900 帧 | 15 秒一次 |
| 技能伤害 | 48 + `melee_attack * 1.5` | 随构筑成长 |
| 技能控制 | 对小怪眩晕 60 帧；对 Boss 只打断或 15 帧硬直 | 避免 Boss 长控 |

## 预算说明

重设计后裸装基础 DPS 约 26.7，瘀伤叠满前不会爆炸增长。薯条的价值从“纯数值强”转向“稳定命中 + 破韧 + 瘀伤铺垫”。这更适合作为默认 common 武器，也为后续战斗学派武器留出空间。

## 交互关系

- 与 `@entities/buffs/bruise.md`：薯条是瘀伤教学入口。高频降低后，瘀伤层数需要持续接战才能叠高。
- 与 `@entities/characters/potato-hero.md`：土豆少侠无近战加成，因此薯条裸强度必须足够通过第 1 层。
- 与强化：攻击速度、范围、韧性伤害都是可读强化方向。

## 验证目标

- 第 1 层基础追击怪应被 1-2 次命中击杀。
- 第 2 层慢速肉盾怪应需要 3-5 次命中，迫使玩家走位。
- 技能每场战斗触发 3-6 次，玩家能看到它但不会完全依赖它。

## 后续实现备注

当前技能效果 `deal_damage.amount` 是固定值，不支持属性缩放。下一轮实现武器技能时建议复用普通伤害结构，支持 `base + scales`。
