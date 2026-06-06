# Buff 系统设计

## 定位

Buff 系统承载 Puritato 的临时增益、永久增益、减益、持续伤害、控制、光环、Boss 阶段、区域效果和触发规则。当前项目已有 `@entities/buffs/bruise.md`、`@entities/buffs/stun.md`、`@entities/buffs/comprehensive-development.md`、`@entities/buffs/potato-enhancement.md` 四个基础 buff 档案。

本文只写设计，不实现代码。

## Buff 分类

| 分类 | 目标 | 示例 | 设计重点 |
|-|-|-|-|
| 属性增益 | 玩家、武器、魔法、怪物 | 全面发展、土豆强化 | 与属性公式兼容 |
| 属性减益 | 怪物、Boss、玩家 | 破甲、虚弱、迟缓 | 上限和驱散规则 |
| 持续伤害 | 怪物、Boss、玩家 | 中毒、燃烧、流血 | tick 频率和叠层 |
| 持续治疗 | 玩家、友方召唤物 | 药剂恢复、再生 | 不要超过伤害压力 |
| 护盾 | 玩家、怪物、Boss | 药剂护盾、树皮 | 消耗顺序 |
| 控制 | 怪物、Boss、玩家 | 眩晕、冻结、沉默 | 抗性和免疫 |
| 光环 | 区域、实体 | 毒雾、天气场 | 进入/离开处理 |
| 触发器 | 任意 | 受击反击、击杀回蓝 | 事件优先级 |
| Boss 状态 | Boss | 狂暴、污染外壳 | 阶段与演出 |

## 数据字段

建议每个 buff 定义至少包含：

| 字段 | 说明 |
|-|-|
| `id` | 唯一 ID |
| `target_types` | 可作用目标 |
| `tags` | `buff`、`debuff`、`control`、`dot`、`aura`、`boss` 等 |
| `stacking_mode` | 叠加模式 |
| `max_stacks` | 最大层数 |
| `duration_frames` | 持续时间，-1 表示永久 |
| `tick_interval_frames` | tick 间隔，0 表示无周期 tick |
| `modifiers` | 属性修正 |
| `periodic_effects` | 周期效果，如伤害、治疗、回蓝 |
| `event_triggers` | 事件触发 |
| `behavior_locks` | 行为锁，如移动、攻击、施法 |
| `resistance_tags` | 受哪些抗性影响 |
| `dispellable` | 是否可驱散 |
| `unique_group` | 互斥组 |
| `priority` | 同帧结算顺序 |
| `asset_refs` | 图标、特效 |

## 叠加模式

| 模式 | 规则 | 适用 |
|-|-|-|
| `refresh_duration` | 不叠层，只刷新时间 | 眩晕、短 buff |
| `stack_refresh_duration` | 加层并刷新总时间 | 中毒、瘀伤 |
| `independent_timers` | 每层独立计时 | 多来源临时增益 |
| `permanent_stack` | 永久叠层 | 土豆强化、成长道具 |
| `replace_if_stronger` | 强者覆盖弱者 | 护盾、光环 |
| `unique_by_source` | 每个来源独立一份 | 多个光环或召唤物 |

运行时代码已统一读取 `stacking_mode`。新增 buff 不应再写旧字段 `stack_mode`。

## 持续时间

建议以固定 tick 或帧为内部单位，但文档和配置要能读出秒数：

```text
duration_seconds = duration_frames / 60
tick_seconds = tick_interval_frames / 60
```

推荐时间：

| 类型 | 持续时间 | tick |
|-|-:|-:|
| 短控制 | 0.4-2.0 秒 | 无 |
| 普通减益 | 4-10 秒 | 无或 1 秒 |
| DOT | 3-8 秒 | 0.5 或 1 秒 |
| 普通增益 | 6-15 秒 | 无 |
| 强爆发增益 | 3-6 秒 | 无 |
| 光环 | 常驻或区域存在 | 0.25-1 秒检测 |
| 永久道具 | -1 | 无 |

## 结算顺序

同一帧建议按固定顺序：

1. 移除过期 buff。
2. 应用新 buff 的叠层和刷新。
3. 重建属性修正。
4. 处理行为锁。
5. 处理周期 tick。
6. 处理事件触发。
7. 结算死亡、破韧、掉落和奖励。

事件优先级：

```text
character_passive
> item_passive
> weapon_passive
> magic_passive
> buff_event_trigger
> monster_or_boss_passive
```

同类按获得顺序或装备槽顺序结算，保证可预测。

## 护盾与伤害处理

受击流程：

```text
raw_damage
-> 攻击者增伤
-> 目标减伤/防御
-> 目标护盾吸收
-> 生命扣除
-> 受击事件
-> 死亡检查
```

护盾建议作为 buff：

- `shield_value` 当前护盾量。
- `shield_max` 可选上限。
- `replace_if_stronger` 或 `stack_refresh_duration` 由具体护盾决定。
- 护盾被打破可以触发事件，例如爆炸、治疗、眩晕周围敌人。

## DOT 设计

### 中毒

感染学派核心。适合叠层、刷新时间。

```text
poison_tick_damage =
  (base_damage + spell_power * ratio)
  * stacks
  * (1 + poison_damage_percent)
```

推荐：

- tick：1 秒。
- 持续：5 秒。
- 最大层数：20 起步，感染学派可突破到 50。
- 每层基础伤害：1-3。
- Boss 对中毒层数可不减免，但可减免控制，不要让 DOT 构筑打 Boss 完全失效。

### 燃烧

爆破/元素方向。适合低层数、高单层伤害、可扩散。

```text
burn_tick_damage =
  max_strongest_burn_damage
  * (1 + burn_damage_percent)
```

推荐：

- 多个燃烧不简单全叠，默认取最强燃烧并刷新时间。
- 特殊道具允许燃烧扩散或多燃烧并存。
- tick：0.5 秒或 1 秒。

### 流血/瘀伤

战斗/刺杀方向。当前瘀伤以 `@entities/buffs/bruise.md` 为准：目标每层受到最终武器伤害 +1，建议最多 16 层，持续 480 帧。它只影响武器伤害，不影响法术伤害。

建议：

- 瘀伤是最终加伤，主要服务高频或多段武器。
- 最大 20 层合理。
- Boss 可完整吃层，但精英/Boss 层数衰减时间可以更短，避免永久堆满后无脑输出。

## 控制与抗性

控制 buff 必须被抗性影响：

```text
control_duration_final =
  base_duration
  * (1 + attacker.control_duration_percent)
  * (1 - target.control_resistance)
  * boss_control_multiplier
```

推荐抗性：

| 目标 | 控制抗性 | 说明 |
|-|-:|-|
| 小怪 | 0%-20% | 大多数可控 |
| 冲锋/精英怪 | 30%-50% | 可打断但不长控 |
| Boss | 70%-90% | 控制变成短打断 |

连续控制递减：

- 目标在 5 秒内每受到一次硬控，后续硬控时长乘 0.7。
- 最低控制时长 0.15 秒。
- 5 秒未受到硬控后递减计数清零。

## Buff 与学派

| 学派 | 代表 buff | 叠加模型 |
|-|-|-|
| 变形 | 全面发展、适应性成长 | 刷新时间或永久叠层 |
| 战斗 | 瘀伤、破甲、格挡 | 叠层刷新 |
| 感染 | 中毒、虚弱、感染扩散 | 叠层刷新 |
| 爆破 | 燃烧、易爆、灼热地面 | 最强覆盖或区域 tick |
| 炼药 | 再生、护盾、兴奋剂 | 独立计时或强者覆盖 |
| 刺杀 | 标记、处决窗口、隐匿 | 唯一标记或短爆发 |
| 占卜 | 预兆、幸运改写、复制 | 事件触发器 |
| 大气 | 减速、顺风、雷暴 | 光环/区域 |
| 自然科学 | 研究、适应上限、召唤强化 | 永久成长或 unique by source |

## 推荐基础 Buff

| ID | 名称 | 效果 | 用途 |
|-|-|-|-|
| `@entities/buffs/bruise.md` | 瘀伤 | 目标受到最终武器伤害 +1/层，16 层，8 秒 | 战斗学派/薯条 |
| `@entities/buffs/stun.md` | 眩晕 | 锁移动和攻击，默认 1 秒，受控制抗性影响 | 控制 |
| `buff.poison` | 中毒 | 每秒毒伤，叠层刷新，20 层 | 感染学派 |
| `buff.burning` | 燃烧 | 周期火伤，默认强者覆盖 | 爆破学派 |
| `buff.fuse_lit` | 引线着了 | 炸弹果苗专用，每秒自伤 1 并提高 4 移速，15 层 | 爆破/怪物专用 |
| `buff.frost` | 霜冻 | 移速 -25%，攻速 -15%，可叠 3 层 | 大气/控制 |
| `buff.shield` | 护盾 | 吸收伤害，强者覆盖 | 炼药学派 |
| `buff.regeneration` | 再生 | 每秒治疗 | 炼药学派 |
| `buff.marked` | 标记 | 暴击率或处决伤害提高 | 刺杀学派 |
| `buff.vulnerable` | 易伤 | 受到所有伤害 +10% | 通用减益 |
| `buff.research` | 研究 | 每层提高某类上限或法强 | 自然科学 |

## 配置示例

```json
{
  "id": "buff.poison",
  "target_types": ["monster", "boss"],
  "tags": ["debuff", "dot", "poison"],
  "stacking_mode": "stack_refresh_duration",
  "max_stacks": 20,
  "duration_frames": 300,
  "tick_interval_frames": 60,
  "periodic_effects": [
    {
      "type": "deal_damage",
      "damage_type": "poison",
      "base": 1,
      "stat": "spell_power",
      "ratio": 0.08,
      "per_stack": true
    }
  ],
  "dispellable": true
}
```

```json
{
  "id": "buff.shield",
  "target_types": ["player", "monster", "boss"],
  "tags": ["buff", "shield"],
  "stacking_mode": "replace_if_stronger",
  "max_stacks": 1,
  "duration_frames": 600,
  "shield": {
    "base": 40,
    "stat": "spell_power",
    "ratio": 1.2
  },
  "dispellable": true
}
```

## 实现注意点

后续写代码时建议把 buff 分成三层：

- `BuffDefinition`：静态配置。
- `BuffInstance`：运行时层数、剩余时间、来源、动态值。
- `BuffSystem` 或 `BuffContainer`：负责叠层、tick、事件、属性修正挂载和移除。

属性型 buff 不应在每帧重复 add modifier。推荐在 buff 变化时重建该目标的 buff 修正，或用 source_id 精确移除后重加。

DOT 和事件触发不要混在 `modifiers` 里。`modifiers` 只改属性，`periodic_effects` 处理 tick，`event_triggers` 处理 on-hit/on-kill/on-damage/on-cast 等事件。
