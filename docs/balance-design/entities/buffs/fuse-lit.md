# 引线着了

| 项 | 值 |
|-|-|
| Entity ID | `buff.fuse_lit` |
| 类型 | buff |
| 目标 | monster |
| 当前配置 | `content/base/buffs/base_buffs.json` |
| 设计状态 | implemented |

## 定位

`buff.fuse_lit` 是 `@entities/monsters/bomb-fruitling.md` 的专用引线状态。它让炸弹果苗醒来后逐秒变快，同时持续自伤，形成“越拖越危险，但也会自己烧死”的倒计时。

## 当前配置值

| 字段 | 当前值 | 说明 |
|-|-:|-|
| `stacking_mode` | `permanent_stack` | 醒来后持续叠层，不自然消退 |
| `max_stacks` | 15 | 配合 60 初速和每层 +4，最高 120 |
| `duration_frames` | -1 | 永久，直到怪物死亡 |
| `tick_interval_frames` | 60 | 每秒触发一次 |
| `move_speed` | +4 / stack | 每秒额外提高 4 点速度 |
| `periodic deal_damage` | 1 | 每秒自伤 1，忽略防御 |
| `asset_refs.icon` | `buff.burning.icon` | 复用燃烧图标 |

## 行为说明

初次唤醒时，炸弹果苗获得 1 层 `buff.fuse_lit`。之后每次周期 tick 会先造成 1 点自伤，再向自身追加 1 层同名 buff，直到 15 层上限。战斗场景会把炸弹果苗最终速度额外限制在 `fuse_exploder.max_move_speed`，避免未来数值成长突破上限。

## 验证目标

- 炸弹果苗被唤醒后立即拥有 1 层引线 buff。
- 每秒生命减少 1 点。
- 每秒速度提高 4 点，最高不超过 120。
- 引线自伤导致死亡时，炸弹果苗仍会触发死亡爆炸。
