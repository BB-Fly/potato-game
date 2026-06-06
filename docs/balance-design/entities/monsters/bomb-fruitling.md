# 炸弹果苗

| 项 | 值 |
|-|-|
| Entity ID | `monster.metamorph.bomb_fruitling` |
| 类型 | monster |
| 学派 | 变形学派，未来可迁到爆破学派 |
| 当前配置 | `content/base/monsters/bomb_fruitling.json` |
| 设计状态 | implemented |

## 定位

炸弹果苗是延迟爆发威胁。它刚生成时睡着不动，玩家靠近或攻击它后才进入追击状态。醒来后尾巴引线着火，速度逐秒升高，同时被引线烧伤；死亡或撞到角色时会爆成果汁，对中等范围内的玩家、怪物和 Boss 造成伤害。

这个怪的压力来自“要不要叫醒它”和“叫醒后要不要把它引爆到怪群里”，而不是普通接触伤害。

## 当前配置值

| 字段 | 当前值 | 说明 |
|-|-:|-|
| `max_health` | 22 | 低血量，可被提前点杀 |
| `attack` | 0 | 接触本身不造成普通伤害，威胁转移到爆炸 |
| `move_speed` | 60 | 睡醒后的初始追击速度 |
| `fuse_exploder.max_move_speed` | 120 | 引线叠满后的速度上限 |
| `knockback_resistance` | 0.02 | 击退抗性很低 |
| `toughness` | 6 | 中低韧性 |
| `wake_distance` | 296 | 约为当前横向战斗区域的四分之一 |
| `explosion_damage` | 20 | 爆炸固定伤害，忽略防御 |
| `explosion_radius` | 96 | 中等范围果汁飞溅 |
| `enemy_bump_radius` | 28 | 醒后撞到其他敌方角色也会爆炸 |
| `spawn.weight` | 0.55 | 低频爆点 |
| `first_floor` | 1 | 第 1 层开始少量出现 |
| `max_simultaneous` | 4 | 避免同时铺满 |
| `presentation.sprite_size` | 96 x 96 | 放大显示，确保睡眠 ZZZ、奔跑烟尘和泪水可读 |
| `asleep_frame_seconds` | 0.30 | 慢速睡眠循环，避免像剧烈摇晃 |
| `waking_frame_seconds` | 0.10 | 点燃过程较快 |
| `awake_frame_seconds` | 0.075 | 奔跑循环更快，强化步态感 |
| `fire_wheel_vfx` | `monster.bomb_fruitling.fire_wheel_vfx` | 醒后奔跑使用前后两层风火轮特效替代脚步循环 |
| `sleep_zzz_vfx` | `monster.bomb_fruitling.sleep_zzz_vfx` | 睡眠 ZZZ 独立生成，上飘、放大、破裂 |
| `run_dust_vfx` | `monster.bomb_fruitling.run_dust_vfx` | 奔跑尘土独立留在原地并淡出 |

## 状态机

1. `asleep`：生成后默认状态。播放睡觉张嘴流口水帧，不移动、不接触攻击。
2. `waking`：玩家进入 `wake_distance` 或受到伤害后触发。播放点燃帧，施加 1 层 `@entities/buffs/fuse-lit.md`。
3. `awake`：追向玩家，使用奔跑哭泣帧。`buff.fuse_lit` 每秒自伤 1 点，并继续叠层提高速度。
4. `explode`：死亡、贴近玩家、或醒后撞到其他敌方角色时触发。播放 `monster.bomb_fruitling.explosion_vfx`，对范围内所有角色造成 20 点伤害。

## 美术规格

- 主体是红色浆果，茎是后方尾巴/引线，不再是头顶炸弹引线。
- 睡眠帧：闭眼、张嘴、流口水，只做轻微呼吸变化。`zzz` 由独立 VFX 生成。
- 点燃帧：尾巴末端起火，表情惊醒。
- 奔跑帧：尾巴持续燃烧，眼泪向后飞溅。本体下方叠加风火轮特效，后轮在身体后层，前轮在身体前层。
- 奔跑尘土：独立 VFX，生成在脚后并停留在原地，逐帧破碎、淡出。
- 睡眠 `zzz`：独立 VFX，周期性出现，上飘、变大，最后破裂成小星星。
- 爆炸 VFX：红色果汁、种子、橙黄色中心爆点。
- Runtime 资产：
  - `assets/art/sprites/monsters/bomb_fruitling.png`，4x3，256 px 每格，三行分别为睡眠、点燃、奔跑。
  - `assets/art/icons/monster_bomb_fruitling.png`。
  - `assets/art/vfx/bomb_fruitling_explosion.png`，2x2，256 px 每格。
  - `assets/art/vfx/bomb_fruitling_fire_wheel.png`，4x1，128 px 每格。
  - `assets/art/vfx/bomb_fruitling_run_dust.png`，4x1，128 px 每格。
  - `assets/art/vfx/bomb_fruitling_sleep_zzz.png`，4x1，128 px 每格。

## 交互关系

- 与 `@entities/weapons/fries.md`：薯条命中睡眠炸弹果苗会把它打醒；低击退抗性让玩家可以调整爆点位置。
- 与 `@entities/buffs/fuse-lit.md`：引线 buff 负责每秒自伤和逐秒加速。
- 与 `@entities/bosses/demo-pollution-source.md`：Boss 战低频加入时可制造走位压力，但 `max_simultaneous` 需要继续限制。

## 验证目标

- 刷出后应明显处于睡眠状态，不会立即追击玩家。
- 玩家进入约四分之一个横屏距离，或攻击它后，应点燃并开始追击。
- 引线每秒扣 1 点生命，并以每秒 4 点速度加速，最高不超过 120。
- 爆炸应对范围内玩家、普通怪和 Boss 都造成 20 点伤害。
- 单个炸弹果苗是可控爆点；多个同时出现时才形成较高压力。
