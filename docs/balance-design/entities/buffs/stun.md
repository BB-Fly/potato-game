# 眩晕

| 项 | 值 |
|-|-|
| Entity ID | `buff.stun` |
| 类型 | buff |
| 当前配置 | `content/base/buffs/base_buffs.json` |
| 设计状态 | ready |

## 定位

眩晕是硬控制。它用于打断、创造输出窗口、救急，而不是长期锁死敌人。Boss 和精英必须有明显抗性。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `target_types` | monster, boss |
| `stacking_mode` | `refresh_duration` |
| `max_stacks` | 1 |
| `duration_frames` | 120 |
| `behavior_locks` | movement, attack |

当前 120 帧等于 2 秒。对普通怪合理，对 Boss 过强。

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `duration_frames` | 60 | 默认 1 秒 |
| `stacking_mode` | `refresh_duration` | 不叠层 |
| `max_stacks` | 1 | 保留 |
| `behavior_locks` | movement, attack | 保留 |
| `tags` | `debuff`, `control`, `hard_control` | 抗性识别 |
| `affected_by_control_resistance` | true | 设计预留 |
| `boss_min_duration_frames` | 15 | Boss 最短硬直 |

## 具体作用数值

眩晕锁定目标移动和攻击：

```text
behavior_locks = ["movement", "attack"]
```

默认持续 60 帧，即 1 秒。最终持续时间：

```text
final_duration_frames =
  round(
    base_duration_frames
    * (1 + attacker.control_duration_percent)
    * (1 - target.control_resistance)
    * repeated_control_decay
  )
```

示例：

| 目标 | 控制抗性 | 60 帧基础眩晕的结果 |
|-|-:|-:|
| 普通怪 | 0% | 60 帧 / 1 秒 |
| 强化怪 | 40% | 36 帧 / 0.6 秒 |
| Boss | 85% | 9 帧，按 Boss 保底提升到 15 帧 |

连续控制递减建议：

| 5 秒内硬控次数 | `repeated_control_decay` |
|-:|-:|
| 第 1 次 | 1.00 |
| 第 2 次 | 0.70 |
| 第 3 次 | 0.49 |
| 第 4 次及以后 | 0.35 |

控制公式：

```text
final_duration = base_duration
  * (1 + attacker.control_duration_percent)
  * (1 - target.control_resistance)
  * repeated_control_decay
```

## 预算说明

1 秒足够玩家看见控制效果，也足够打断小怪或技能。Boss 上通过 85% 抗性缩到约 9 帧，再用最短硬直保底到 15 帧，表现为打断而不是定身。

## 交互关系

- `@entities/weapons/fries.md` 的武器技能施加眩晕。
- 破韧也可以施加短眩晕。
- 冰冻、定身、沉默应与眩晕分属不同控制标签，避免规则混乱。

## 验证目标

- 普通怪被眩晕后能明显停住。
- Boss 被眩晕时应中断当前施法或短暂停顿，但不能让玩家连续控制到无法行动。
- 连续控制递减实现后，控制流仍可玩但不能无缝控死。

## 后续实现备注

当前系统没有控制抗性和连续控制递减。后续应在目标状态里记录最近硬控次数。
