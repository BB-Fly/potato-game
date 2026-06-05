# 数值计算定义

本文是 Puritato 数值计算的统一定义文档。其他文档涉及具体属性时，优先引用本文件，避免在各处重复解释单位和公式。

引用约定：本文档可以写作 `@balance-design/stat-calculation-reference.md`。具体 entity 文档使用 `@entities/...` 形式互相引用，例如 `@entities/buffs/bruise.md`。

## 基础约定

| 项 | 定义 |
|-|-|
| 帧率基准 | 60 FPS |
| 1 秒 | 60 帧 |
| 位置单位 | Godot 2D 像素 |
| 速度单位 | 像素/秒 |
| 百分比字段 | 文档中写作 `+10%`，配置中建议用 `0.10` |
| 整数伤害 | 最终扣血前向上取整，最低 1 |
| 层数 | `floor`，跨章节累计的小关进度，从 1 开始 |

## 属性修正通用公式

项目现有 `StatBlock` 支持四类修正。建议所有属性遵循同一顺序：

```text
final_stat =
  ((base + flat_add) * (1 + additive_percent))
  * multiplicative
  + final_add
```

字段含义：

- `base`：角色、怪物、武器、法术或 Boss 的基础值。
- `flat_add`：升级、常驻道具、常规 buff 提供的加算值。
- `additive_percent`：同类百分比加成相加后进入该乘区。
- `multiplicative`：难度、阶段、特殊规则等独立乘区相乘。
- `final_add`：最终加算，主要用于保底和少数易读效果，例如 `weapon_damage_taken_flat`。

示例：

```text
base melee_attack = 0
土豆强化 3 层 = +3
全面发展 Buff = +4
final melee_attack = 7
```

## 生命

### `max_health`

最大生命决定玩家或敌人的生命上限。生命上限变化时：

- 增加最大生命：当前生命同步增加相同数值，避免拿到生命道具却不回血。
- 降低最大生命：当前生命不能高于新的最大生命。
- 最低最大生命建议为 1。

```text
max_health_final = stat_final("max_health")
current_health = clamp(current_health, 0, max_health_final)
```

### 受伤

```text
incoming_damage =
  ceil(max(1, raw_damage * damage_taken_multiplier))
```

玩家受击后建议有两类无敌：

- 通用受击无敌：0.25-0.35 秒。
- 单伤害源无敌：0.7-1.0 秒，用于避免同一怪物接触或同一持续伤害源连续刷伤害。

## 生命恢复

### `health_regen`

`health_regen` 定义为每秒恢复生命。它不是每 5 秒，也不是每波结算。

```text
health_regen_per_second = max(0, stat_final("health_regen"))
health_regen_per_tick = health_regen_per_second / 60
```

实现上建议使用小数累积器：

```text
regen_accumulator += health_regen_per_second * delta_seconds
heal = floor(regen_accumulator)
regen_accumulator -= heal
current_health = min(max_health, current_health + heal)
```

示例：

- `health_regen = 2`：每秒 2 点，5 秒恢复 10 点。
- `health_regen = 0.5`：每 2 秒约恢复 1 点。
- `health_regen < 0`：默认按 0 处理；若后续需要流血，应使用 buff 周期伤害，不用负恢复表达。

## 法力

### `max_mana`

最大法力决定魔法资源池。最大法力变化规则与最大生命一致：

- 增加最大法力：当前法力同步增加相同数值。
- 降低最大法力：当前法力不能高于新的最大法力。

### `mana_regen`

`mana_regen` 定义为每秒恢复法力。

```text
mana_regen_per_second = max(0, stat_final("mana_regen"))
```

示例：

- 土豆少侠建议 `mana_regen = 10`，每秒恢复 10 法力。
- 全面发展建议消耗 24 法力，土豆少侠约 2.4 秒回满一次施法成本，但仍受 8 秒冷却限制。

## 能量

`max_energy` 是稀缺强技能资源上限。Demo 版本建议暂不启用自然恢复：

```text
energy_regen_per_second = 0
```

能量只通过道具、击杀、Boss 阶段、奇遇或特定法术恢复。若某个魔法 `energy_cost = 0`，表示它不参与能量系统。

## 移动速度

### `move_speed`

`move_speed` 定义为每秒移动像素数。

```text
move_speed_final =
  stat_final("move_speed")
  * (1 + move_speed_percent_from_buffs)
  * slow_multiplier

movement_delta = normalized_input * move_speed_final * delta_seconds
```

建议范围：

| 对象 | 常见速度 |
|-|-:|
| 玩家慢速角色 | 175-205 |
| 玩家均衡角色 | 210-230 |
| 玩家高速角色 | 245-280 |
| 慢速怪 | 55-85 |
| 基础追击怪 | 110-150 |
| 高速威胁怪 | 150-210 |
| Boss | 60-95 |

速度类减益默认乘算：

```text
slow_multiplier = product(1 - slow_percent)
```

最低速度建议：

- 玩家：不低于 80，避免完全不能操作。
- 普通怪：不低于 20，避免路径卡死。
- Boss：不低于 0，允许某些阶段固定不动。

## 攻击速度

### `attack_speed`

`attack_speed` 是百分比修正。配置中建议 `0.20` 表示 +20% 攻速。

```text
attack_speed_multiplier =
  clamp(1 + stat_final("attack_speed"), 0.35, 3.0)

attack_interval_seconds =
  max(base_interval_seconds / attack_speed_multiplier, weapon_min_interval_seconds)

attack_interval_frames =
  ceil(attack_interval_seconds * 60)
```

示例：

- 薯条建议基础 `attack_interval_frames = 36`，即 0.6 秒一次。
- 若 `attack_speed = +20%`，间隔为 `36 / 1.2 = 30` 帧。
- 若 `attack_speed = -50%`，倍率为 0.5，间隔为 `36 / 0.5 = 72` 帧。

触发型效果需要触发系数：

```text
on_hit_trigger_power =
  min(1.0, base_interval_seconds / actual_interval_seconds_reference)
```

短期可以先不用该字段，但高频武器必须避免过快叠满 `@entities/buffs/bruise.md` 这类 on-hit buff。

## 冷却

### `cooldown_reduction`

`cooldown_reduction` 是百分比，基础上限 50%。

```text
cooldown_seconds =
  base_cooldown_seconds
  * (1 - clamp(cooldown_reduction, 0, 0.5))
```

示例：

- 全面发展建议基础冷却 8 秒。
- 若 `cooldown_reduction = 25%`，实际冷却 6 秒。

特殊传说道具可以临时把上限提高到 65%，但必须在 entity 文档中明确代价。

## 武器伤害

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
  damage_after_crit = damage_before_crit * crit_multiplier
else:
  damage_after_crit = damage_before_crit

final_damage =
  ceil(max(1, damage_after_crit + target.weapon_damage_taken_flat))
```

`weapon_damage_taken_flat` 是最终加算，当前主要由 `@entities/buffs/bruise.md` 提供。

示例：

```text
薯条建议伤害 = 16 + 100% melee_attack
土豆少侠 melee_attack = 0
全面发展 Buff melee_attack = +4
目标瘀伤 6 层 = weapon_damage_taken_flat +6

基础伤害 = 16 + 4 = 20
无暴击最终伤害 = ceil(20 + 6) = 26
```

## 法术伤害、治疗和护盾

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

不同法术可以把 `spell_final` 用于：

- 伤害。
- 治疗。
- 护盾值。
- 持续伤害 tick。
- 持续时间加成。
- 范围加成。

治疗默认不暴击；如果某个构筑允许治疗暴击，必须在对应 entity 文档中说明。

## 防御

`defense` 使用有效生命线性成长公式：

```text
if defense >= 0:
  damage_taken_multiplier = 100 / (100 + defense * 6)
else:
  damage_taken_multiplier = 1 + abs(defense) * 0.04

incoming_damage =
  ceil(raw_damage * damage_taken_multiplier * other_taken_multiplier)
```

示例：

| 防御 | 承伤倍率 | 约等效生命提升 |
|-:|-:|-:|
| 0 | 100% | 0% |
| 5 | 76.9% | +30% |
| 10 | 62.5% | +60% |
| 20 | 45.5% | +120% |
| 30 | 35.7% | +180% |

## 暴击

```text
crit_chance_final = clamp(base_crit_chance + stat_final("crit_chance"), 0, crit_cap)
crit_multiplier_final = max(1.5, base_crit_multiplier + crit_multiplier_bonus)
```

建议：

- 默认暴击倍率为 200%，即 `2.0`。
- 普通构筑暴击率上限 75%。
- 刺杀学派或特殊 buff 可把上限提高到 100%。

## 韧性、破韧和控制

```text
toughness_damage_final =
  base_toughness_damage
  * (1 + toughness_damage_percent)
  * (1 - target.control_resistance)

target.toughness_current -= toughness_damage_final
```

目标韧性归零时进入破韧：

- 普通怪：眩晕 0.8 秒。
- 精英：眩晕 0.4 秒，并获得 5 秒破韧抗性。
- Boss：打断当前动作，不强制长眩晕。

控制持续时间：

```text
control_duration_final =
  base_duration
  * (1 + attacker.control_duration_percent)
  * (1 - target.control_resistance)
  * repeated_control_decay
```

Boss 最短硬直可单独保底，例如 `@entities/buffs/stun.md` 建议 Boss 最短 15 帧。

## 击退

```text
knockback_distance =
  attack_knockback
  * (1 - target.knockback_resistance)
  * knockback_multiplier
```

建议：

- 普通怪击退抗性 0%-20%。
- 肉盾怪 15%-35%。
- Boss 通常 80%-100%，多数时候不被普通击退移动。

击退方向默认为从攻击来源指向目标；范围攻击可以使用从爆心指向目标。

## 敌人成长

普通敌人优先使用全局层数倍率：

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

如果短期仍使用线性成长：

```text
enemy_health = base_health + max_health_per_floor * (floor - 1)
enemy_attack = base_attack + attack_per_floor * (floor - 1)
```

同一项目中不要同时长期混用两套成长模型。推荐最终统一到全局层倍率。

## 金币与价格

```text
reward_gold = 150 + 75 * (floor - 1)
shop_price = rarity_price_roll + 10 * (floor - 1)
master_upgrade_price = 40 + 5 * (floor - 1)
reroll_price = base_reroll_price * (1 + 0.15 * reroll_count) + 5 * (floor - 1)
```

价格修正顺序：

```text
final_price =
  round_to_int(
    base_price
    * character_discount_multiplier
    * (1 + item_price_percent)
    * event_price_multiplier
  )
```

土豆少侠首购半价只影响商品，不影响刷新、融合和强化服务。

## 幸运与稀有度

```text
rare_weight = base_rare_weight * (1 + luck / 150)
legendary_weight = base_legendary_weight * (1 + luck / 200)
common_weight = base_common_weight
```

调整后重新归一化。幸运不应保证一定出传说；传说保底应由章节、Boss、奇遇或难度规则明确提供。
