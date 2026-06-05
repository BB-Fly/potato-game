# 瘀伤

| 项 | 值 |
|-|-|
| Entity ID | `buff.bruise` |
| 类型 | buff |
| 当前配置 | `content/base/buffs/base_buffs.json` |
| 设计状态 | ready |

## 定位

瘀伤是武器连击型减益。它让持续命中同一目标变得更有价值，尤其服务薯条这类近战武器。它应该对普通怪不太重要，对精英和 Boss 有可见收益。

## 当前配置值

| 字段 | 当前值 |
|-|-:|
| `target_types` | monster, boss |
| `stacking_mode` | `stack_refresh_duration` |
| `max_stacks` | 20 |
| `duration_frames` | 600 |
| `tick_interval_frames` | 0 |
| `weapon_damage_taken_flat` | +1/层 |

## 建议重设计值

| 字段 | 建议值 | 说明 |
|-|-:|-|
| `stacking_mode` | `stack_refresh_duration` | 保留 |
| `max_stacks` | 16 | 降低满层爆发 |
| `duration_frames` | 480 | 8 秒，要求持续接战 |
| `boss_duration_frames` | 300 | 设计预留，Boss 上持续 5 秒 |
| `weapon_damage_taken_flat` | +1/层 | 保留清晰效果 |
| `tags` | `debuff`, `injury`, `weapon_taken` | 便于驱散/免疫 |

## 具体作用数值

瘀伤只影响武器伤害，不影响法术伤害、持续伤害、护盾或治疗。

```text
weapon_damage_taken_flat = current_bruise_stacks * 1
final_weapon_damage =
  ceil(max(1, damage_after_crit + weapon_damage_taken_flat))
```

示例：

| 瘀伤层数 | 额外最终武器伤害 |
|-:|-:|
| 1 | +1 |
| 4 | +4 |
| 8 | +8 |
| 16 | +16 |

如果 `@entities/weapons/fries.md` 在全面发展期间造成 20 点暴击前伤害，目标有 6 层瘀伤且未暴击，则最终伤害为：

```text
ceil(20 + 6) = 26
```

如果发生 200% 暴击，则先暴击再加瘀伤：

```text
ceil(20 * 2.0 + 6) = 46
```

## 预算说明

满层 +16 最终武器伤害对高频武器非常强，因此需要降低薯条攻速并限制最大层数。Boss 上持续时间更短，可以让玩家需要维持进攻，而不是开场叠满后永久收益。

## 交互关系

- 薯条每次命中施加 1 层。
- 多段武器和高攻速武器需要触发系数，否则会过快叠满。
- 不影响法术伤害，避免成为所有构筑通用最优。

## 验证目标

- 薯条打普通怪时，目标通常在 1-4 层内死亡。
- 打 Boss 时，稳定输出 8-10 秒可接近满层。
- 满层时 Boss 血条下降应明显变快，但不是瞬间融化。

## 后续实现备注

当前系统未区分 Boss 持续时间。短期可以统一 480 帧；Boss 专属衰减留到后续。
