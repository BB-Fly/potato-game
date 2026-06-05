# Puritato 整体数值系统与算法

## 定位

Puritato 是路线图推进的自动攻击生存 roguelike。它不是每一波后进商店的 Brotato 结构，而是玩家先在路线节点拿奖励，再进入一场较短但有 Boss 检查的战斗。因此数值节奏应围绕“层”设计：

- 一层 = 一个小关区域 + 一场战斗。
- Demo 基准 = 6 层。
- 成长来源 = 路线奖励、商店、战斗奖励、武器/魔法强化、融合、奇遇、角色被动。
- 压力来源 = 小怪阶段时长、刷怪频率、敌人种类、精英/Boss、难度倍率。

## 属性体系

属性单位、恢复频率、移动速度、攻速、冷却、伤害、防御、暴击、韧性、击退、金币和稀有度的详细计算，以 `@balance-design/stat-calculation-reference.md` 为准。本文只保留系统层面的摘要。

### 一级属性

一级属性是角色面板主干，建议所有角色、升级、常规道具都围绕这些属性设计。

| 属性 ID | 中文名 | 默认范围 | 说明 |
|-|-|-:|-|
| `max_health` | 最大生命 | 70-160 | 生存基础 |
| `max_mana` | 最大法力 | 40-130 | 魔法资源池 |
| `melee_attack` | 近战攻击 | -20 到 120 | 近战武器缩放 |
| `ranged_attack` | 远程攻击 | -20 到 120 | 远程武器缩放 |
| `spell_power` | 法术强度 | -20 到 120 | 法术伤害、治疗、护盾缩放 |
| `defense` | 防御 | -10 到 45 | 承伤效率 |
| `attack_speed` | 攻击速度 | -50% 到 150% | 武器攻击间隔修正 |
| `cooldown_reduction` | 冷却缩减 | 0% 到 50% | 魔法和主动技能 |
| `crit_chance` | 暴击率 | 0% 到 75% | 基础上限低于 100%，特殊构筑可突破 |
| `crit_multiplier` | 暴击倍率 | 150%-300% | 默认 200% |
| `move_speed` | 移动速度 | 120-340 | 当前土豆少侠 220 可保留 |
| `health_regen` | 生命恢复 | 0-35 | 每秒恢复生命，详见 `@balance-design/stat-calculation-reference.md` |
| `mana_regen` | 法力恢复 | 0-40 | 每秒恢复法力，详见 `@balance-design/stat-calculation-reference.md` |
| `luck` | 幸运 | -30 到 150 | 奖励质量、掉落、标签池 |

### 二级属性

二级属性用于构筑特色，不强求显示在基础面板第一屏。

| 属性 ID | 用途 |
|-|-|
| `pickup_range` | 拾取范围 |
| `enemy_count_percent` | 敌人数量修正 |
| `enemy_speed_percent` | 敌人速度修正 |
| `boss_damage_percent` | 对 Boss/精英增伤 |
| `pierce_count` | 投射物穿透 |
| `pierce_damage_percent` | 穿透后伤害保留 |
| `bounce_count` | 投射物弹跳 |
| `explosion_damage_percent` | 爆炸伤害 |
| `explosion_radius_percent` | 爆炸范围 |
| `burn_damage_percent` | 燃烧伤害 |
| `poison_damage_percent` | 中毒伤害 |
| `healing_effect_percent` | 治疗效果 |
| `shield_effect_percent` | 护盾效果 |
| `toughness_damage_percent` | 韧性伤害 |
| `control_duration_percent` | 控制时长 |
| `item_price_percent` | 商店价格 |
| `reroll_price_percent` | 刷新价格 |
| `gold_gain_percent` | 金币收益 |
| `reward_rarity_percent` | 奖励稀有度 |

## 结算公式

项目现有 `StatBlock` 已支持 `add`、`add_percent`、`multiply`、`final_add` 四类修正。文档建议沿用该顺序：

```text
final = ((base + flat) * (1 + additive_percent)) * multiplicative + final_add
```

推荐语义：

- `base`：角色基础、怪物基础、武器/魔法定义。
- `add`：升级、常驻道具、普通 buff。
- `add_percent`：同类百分比加成，适合装备和常规增益。
- `multiply`：稀有规则、难度、Boss 阶段、特殊事件。
- `final_add`：保底或最终修正，谨慎使用。

## 伤害公式

### 武器伤害

```text
weapon_base_damage =
  weapon.damage.base
  + melee_attack * melee_ratio
  + ranged_attack * ranged_ratio
  + spell_power * spell_ratio
  + defense * defense_ratio

damage_before_crit =
  max(1, weapon_base_damage)
  * (1 + global_damage_percent)
  * school_multiplier
  * target_type_multiplier
  * difficulty_outgoing_multiplier

if crit:
  final_damage = damage_before_crit * crit_multiplier
else:
  final_damage = damage_before_crit

final_damage = round(max(1, final_damage + target.weapon_damage_taken_flat))
```

说明：

- `global_damage_percent` 可作为后续属性加入，但不要让它过早泛滥。
- `target.weapon_damage_taken_flat` 对应 `@entities/buffs/bruise.md`，适合放在最终加算。
- 快速武器建议低基础、低缩放；慢速武器高基础、高缩放。

### 魔法伤害/治疗

```text
spell_value =
  spell.base_value
  + spell_power * spell_power_ratio
  + related_stat * related_ratio

spell_final =
  spell_value
  * (1 + spell_effect_percent)
  * school_multiplier
  * target_type_multiplier
```

魔法可以同时造成伤害和施加 buff。若魔法主要是 buff，`spell_power` 可影响持续时间、护盾量、治疗量、伤害 tick 或范围，不一定直接加伤害。

### 防御公式

推荐使用有效生命线性成长的防御公式：

```text
damage_taken_multiplier =
  if defense >= 0:
    100 / (100 + defense * 6)
  else:
    1 + abs(defense) * 0.04

incoming_damage = ceil(raw_damage * damage_taken_multiplier * other_taken_multiplier)
```

效果示例：

| 防御 | 承伤倍率 | 约等效生命提升 |
|-:|-:|-:|
| 0 | 100% | 0% |
| 5 | 76.9% | +30% |
| 10 | 62.5% | +60% |
| 20 | 45.5% | +120% |
| 30 | 35.7% | +180% |

这样每点防御都接近固定有效生命收益，适合长期扩展。

## 攻速与冷却

武器攻击间隔：

```text
interval = base_interval / clamp(1 + attack_speed_percent, 0.35, 3.0)
interval = max(interval, weapon_min_interval)
```

建议：

- 普通武器最短间隔不低于 0.25 秒。
- 高频武器触发 on-hit 时需要内置触发冷却或触发系数。
- 负攻速不要让玩家完全失效，最低攻速倍率为 0.35。

魔法冷却：

```text
cooldown = base_cooldown * (1 - clamp(cooldown_reduction, 0, 0.5))
```

冷却缩减基础上限 50%，特殊传说道具可以临时突破到 65%，但必须有代价。

## 暴击

```text
crit_chance_final = clamp(base_crit + crit_chance, 0, crit_cap)
crit_multiplier_final = max(1.5, base_crit_multiplier + crit_multiplier_bonus)
```

建议基础上限：

- 普通构筑：75%。
- 刺杀学派或特殊 buff：可到 100%。
- 超过 100% 的部分不要默认转化为伤害，除非某件传说道具专门定义。

## 韧性与控制

每个敌人有 `toughness`。武器/魔法造成 `toughness_damage`，归零后进入破韧。

```text
toughness_damage_final =
  base_toughness_damage
  * (1 + toughness_damage_percent)
  * (1 - target.control_resistance)
```

破韧建议：

- 普通怪：破韧后眩晕 0.8 秒。
- 精英：破韧后眩晕 0.4 秒，并获得 5 秒破韧抗性。
- Boss：破韧后打断当前动作，不强制长眩晕；可开放处决窗口。

## 层数成长

Demo 6 层推荐目标：

| 层 | 小怪阶段 | Boss/精英 | 玩家预期强度 | 设计目标 |
|-:|-:|-|-|-|
| 1 | 45 秒 | 基础 Boss | 1 武器 + 1-2 奖励 | 验证开局 |
| 2 | 50 秒 | 基础 Boss | 2 武器或 1 武器+1 魔法 | 引导分支 |
| 3 | 60 秒 | 强化 Boss | 3-4 件核心内容 | 第一次压力检查 |
| 4 | 70 秒 | 新敌人 + Boss | 构筑方向明确 | 第二章提压 |
| 5 | 80 秒 | 精英或 Boss 技能增强 | 有强化/融合 | 构筑检查 |
| 6 | 90 秒 | 章节 Boss 二阶段 | 基本成型 | Demo 终局 |

敌人数值按层成长：

```text
enemy_health =
  base_health
  * floor_health_multiplier[floor]
  * danger_health_multiplier
  * assist_health_multiplier

enemy_attack =
  base_attack
  * floor_attack_multiplier[floor]
  * danger_attack_multiplier
  * assist_attack_multiplier

enemy_speed =
  base_speed
  * floor_speed_multiplier[floor]
  * danger_speed_multiplier
  * assist_speed_multiplier
```

推荐层倍率：

| 层 | 生命倍率 | 伤害倍率 | 速度倍率 | 数量倍率 |
|-:|-:|-:|-:|-:|
| 1 | 1.00 | 1.00 | 1.00 | 1.00 |
| 2 | 1.25 | 1.10 | 1.00 | 1.10 |
| 3 | 1.55 | 1.20 | 1.02 | 1.20 |
| 4 | 1.95 | 1.35 | 1.04 | 1.35 |
| 5 | 2.45 | 1.50 | 1.06 | 1.50 |
| 6 | 3.10 | 1.70 | 1.08 | 1.70 |

Boss 生命建议单独走更陡曲线：

```text
boss_health = base_boss_health * (1 + 0.55 * (floor - 1)) * danger_health_multiplier
```

以 `@entities/bosses/demo-pollution-source.md` 建议的 `base_boss_health = 320` 为例：

| 层 | Boss 生命 |
|-:|-:|
| 1 | 320 |
| 2 | 496 |
| 3 | 672 |
| 4 | 848 |
| 5 | 1024 |
| 6 | 1200 |

## 经济

当前项目已有战斗金币：第 1 层 150，每层 +75。建议保留，但让商店价格增长更平滑：

```text
reward_gold = 150 + 75 * (floor - 1)
shop_price = rarity_price_roll + 10 * (floor - 1)
master_upgrade_price = 40 + 5 * (floor - 1)
reroll_price = base_reroll_price * (1 + 0.15 * reroll_count) + 5 * (floor - 1)
```

奖励金币与商店价格的关系：

- 玩家每层应能购买 1-2 个普通商品，或攒钱买 1 个高品质商品。
- 战斗奖励不默认给传说道具三选一；传说品质应由层数权重、Boss、章节终点、奇遇或高难度规则提供。
- 第 6 层前玩家大约获得 2025 金币，不计算奇遇和掉落；商店总购买力应控制在 12-18 次有效购买。

## 稀有度权重

Puritato 先使用 3 档品质：common、rare、legendary。

```text
legendary_weight_bonus = luck / 200
rare_weight_bonus = luck / 150
```

推荐基础权重：

| 层 | 普通 | 稀有 | 传说 |
|-:|-:|-:|-:|
| 1 | 85 | 15 | 0 |
| 2 | 75 | 23 | 2 |
| 3 | 65 | 30 | 5 |
| 4 | 52 | 38 | 10 |
| 5 | 42 | 42 | 16 |
| 6 | 32 | 45 | 23 |

幸运调整后重新归一化。传说保底可放在 Boss 战奖励、章节终点、奇遇或高难度。

## 难度

正式难度建议：

| 难度 | 生命 | 伤害 | 速度 | 数量 | 规则变化 |
|-:|-:|-:|-:|-:|-|
| 0 | 1.00 | 1.00 | 1.00 | 1.00 | 默认 |
| 1 | 1.00 | 1.00 | 1.00 | 1.10 | 新敌人提前 1 层出现 |
| 2 | 1.08 | 1.08 | 1.02 | 1.18 | 第 3/5 层出现精英或强化潮 |
| 3 | 1.18 | 1.18 | 1.04 | 1.28 | Boss 增加技能，奖励质量提高 |
| 4 | 1.30 | 1.30 | 1.06 | 1.40 | 精英密度提高，特殊敌人提前 |
| 5 | 1.45 | 1.45 | 1.08 | 1.55 | 终局双 Boss 或 Boss 护卫 |

可访问性倍率独立于正式难度：

```text
effective_health = health * danger_health * assist_health
effective_attack = attack * danger_attack * assist_attack
effective_speed = speed * danger_speed * assist_speed
difficulty_display = cubic_root(assist_health * assist_attack * assist_speed)
```
