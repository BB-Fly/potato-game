# Demo 污染源

| 项 | 值 |
|-|-|
| Entity ID | `boss.demo_pollution_source` |
| 类型 | boss |
| 学派 | 变形学派，污染主题 |
| 当前配置 | `content/base/bosses/demo_pollution_source.json` |
| 设计状态 | ready |

## 定位

Demo 污染源是 6 层 Demo 的主检查点。它应该验证玩家是否拥有足够输出、走位、资源循环和 Boss 技能识别能力。它不应该只是高血量木桩，也不应该在第 1 层就展示全部机制。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `max_health` | 300 |
| `attack` | 10 |
| `move_speed` | 80 |
| `toughness` | 100 |
| `radial_projectiles.cooldown_seconds` | 8 |
| `radial_projectiles.cast_duration_seconds` | 0.65 |
| `radial_projectiles.projectile_count` | 16 |
| `radial_projectiles.projectile_speed` | 225 |
| `radial_projectiles.projectile_radius` | 18 |
| `radial_projectiles.projectile_life_seconds` | 5 |
| `continue_mob_spawns` | true |

## 建议重设计值

基础字段：

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `max_health` | 320 | 第 1 层基础 Boss 生命 |
| `attack` | 10 | 接触伤害基准 |
| `move_speed` | 78 | 稍慢，重心放技能 |
| `toughness` | 120 | 可破韧但不频繁 |
| `control_resistance` | 0.85 | 控制主要表现为打断 |
| `continue_mob_spawns` | true | 保留小怪压力，但按阶段限制强度 |

层数生命建议：

| 层 | 生命 | 接触伤害 | 技能伤害 |
|-:|-:|-:|-:|
| 1 | 320 | 10 | 9 |
| 2 | 480 | 12 | 11 |
| 3 | 660 | 14 | 13 |
| 4 | 840 | 16 | 15 |
| 5 | 1020 | 18 | 18 |
| 6 | 1200 | 20 | 22 |

阶段：

| 阶段 | 触发 | 行为 |
|-|-|-|
| phase_1 | 100%-70% HP | 径向弹幕，较长读条 |
| phase_2 | 70%-40% HP 或战斗 30 秒后 | 径向弹幕数量提高，召唤少量 `@entities/monsters/sprouting-potato.md` |
| phase_3 | 40%-0% HP 或战斗 60 秒后 | 径向弹幕 + 污染预警区，`@entities/monsters/bomb-fruitling.md` 低频加入 |

技能建议：

| 技能 | phase_1 | phase_2 | phase_3 |
|-|-:|-:|-:|
| `radial_projectiles.cooldown_seconds` | 8.0 | 7.0 | 6.0 |
| `projectile_count` | 12 | 16 | 20 |
| `projectile_speed` | 210 | 235 | 260 |
| `cast_duration_seconds` | 0.75 | 0.65 | 0.55 |
| `projectile_life_seconds` | 4.5 | 5.0 | 5.0 |

未来技能：

| 技能 | 建议 |
|-|-|
| `pollution_pool` | 在玩家脚下预警 0.7 秒后生成 4 秒污染区，每秒造成技能伤害 35% |
| `summon_sprouts` | phase_2 后每 14 秒召唤 4-6 个 `@entities/monsters/sprouting-potato.md` |
| `unstable_fruit` | phase_3 后每 18 秒召唤 1-2 个 `@entities/monsters/bomb-fruitling.md` |

## 预算说明

Boss 基础生命只略高于当前值，真正成长来自层数倍率和阶段技能。这样第 1 层 Boss 可以作为教学，第 6 层 Boss 才是完整检查。控制抗性避免薯条技能把 Boss 长时间钉住。

## 交互关系

- 与 `@entities/weapons/fries.md`：薯条技能可以打断施法，但不能长控。
- 与 `@entities/magics/comprehensive-development.md`：玩家可以用 buff 窗口抢 Boss 阶段输出。
- 与 `@entities/monsters/bomb-fruitling.md`：phase_3 低频加入炸弹果苗，制造移动压力。
- 与难度：高难优先增加技能频率和敌人组合，再提高生命。

## 验证目标

- 第 1 层 Boss 战总时长 25-45 秒。
- 第 3 层 Boss 战总时长 45-70 秒。
- 第 6 层 Boss 战总时长 75-110 秒。
- 玩家死亡主要来自读招失败或被小怪压位，而不是无法理解的瞬间伤害。

## 后续实现备注

当前 `phases.timeline` 为空。后续应让 Boss 支持血量阈值和时间阈值双触发，避免高 DPS 跳过体验或低 DPS 拖成重复循环。
