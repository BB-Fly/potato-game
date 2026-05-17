# 内容配置与注册表

本文档说明 `content/base` 如何被加载，以及新增内容时应该改哪些文件。

## 加载入口

加载器：

```text
src/config/content_config_loader.gd
```

注册表：

```text
src/core/registry.gd
```

资源解析：

```text
src/config/asset_catalog.gd
```

`main.gd` 的 `_bootstrap_architecture()` 会创建 `ContentConfigLoader`，把 `content/base` 下的配置加载进 `ContentRegistry`。

## 当前注册类型

健康启动时注册类型为：

```text
school
character
weapon
magic
item
buff
monster
boss
map
reward_table
shop
audio
asset
```

`content/base/scene_art` 当前存在，但恢复后的可运行切片不依赖 `scene_art` 注册类型启动。

## 内容目录

```text
content/base/
  assets/       asset id 到资源路径的映射
  audio/        music state 和音频状态
  bosses/       Boss 配置
  buffs/        buff 配置
  characters/   角色配置
  items/        道具配置
  magics/       魔法配置
  maps/         地图、路线、节点
  monsters/     怪物配置
  rewards/      奖励表
  scene_art/    场景美术规划
  schools/      学派
  shops/        商店
  weapons/      武器
```

## JSON 结构约定

配置文件支持两种形态：

单条内容：

```json
{
  "id": "weapon.metamorph.fries",
  "enabled": true
}
```

多条内容：

```json
{
  "entries": [
    { "id": "school.metamorph" },
    { "id": "school.combat" }
  ]
}
```

加载后由 `registry.register(content_type, entry)` 存入注册表。`content_type` 来自 `ContentConfigLoader.CONTENT_DIRS`。

## 常用字段

多数内容会包含：

| 字段 | 说明 |
| --- | --- |
| `id` | 稳定内容 ID |
| `display_name_key` | 本地化显示名 key |
| `description_key` | 本地化描述 key |
| `school_ids` | 所属学派 |
| `primary_school_id` | 主学派 |
| `rarity` | 稀有度 |
| `enabled` | 是否进入内容池 |
| `asset_refs` | 资源 ID 引用 |
| `audio_refs` | 音频 ID 引用 |
| `stats` | 属性 |
| `effects` | 效果描述，当前多为目标设计字段 |

## 资源引用

玩法内容不要直接引用图片路径，优先引用 `asset_refs`。

示例：

```json
"asset_refs": {
  "icon": "weapon.fries.icon",
  "sprite": "weapon.fries.sprite"
}
```

`AssetCatalog.resolve_asset_path()` 会通过 `content/base/assets/base_assets.json` 把资源 ID 转成 `res://...` 路径。

当前 `main.gd` 中仍有一些硬编码资源路径，用于快速恢复可玩切片。后续整理时可以逐步迁回 `asset_refs`。

## 新增武器流程

1. 在 `content/base/weapons/` 新增 JSON。
2. 确认 `id` 以 `weapon.` 开头。
3. 填写 `school_ids`、`primary_school_id`、`rarity`、`asset_refs`。
4. 在 `content/base/assets/base_assets.json` 增加 icon、sprite、VFX、SFX 映射。
5. 如果需要进入奖励或商店，确认 `ItemPoolService` 的过滤规则能选中它。
6. 跑 headless 启动检查。

## 新增魔法流程

1. 在 `content/base/magics/` 新增 JSON。
2. 确认 `id` 以 `magic.` 开头。
3. 填写 `asset_refs.icon` 和需要的 VFX。
4. 确认 `RunContext.equipped_magics` 仍为 4 个槽。
5. 当前原型的魔法释放逻辑在 `main.gd::_try_cast_magic()`，新增魔法如果需要不同行为，需要在那里扩展或抽到 `MagicRuntime`。

## 新增道具流程

1. 在 `content/base/items/` 新增 JSON。
2. 确认 `id` 以 `item.` 开头。
3. 道具当前获得后进入 `inventory["items"]`，原型里没有完整被动效果结算。
4. 如需影响战斗，短期可在 `main.gd` 中读取库存数量；长期应接入 `item_effect_applier.gd`、buff 或 stats 系统。

## 新增怪物或 Boss

怪物：

- 配置在 `content/base/monsters/`。
- 当前 `main.gd::_spawn_mob()` 仍硬编码了可刷怪物 ID 列表。
- 新增怪物后需要把 ID 加进该列表，或重构成数据驱动刷怪池。

Boss：

- 配置在 `content/base/bosses/`。
- 当前 Demo Boss ID 固定为 `boss.demo_pollution_source`。
- Boss 技能当前在 `main.gd` 中硬编码，长期应迁到 Boss 配置时间轴。

## 内容池和学派过滤

物品池服务：

```text
src/domain/reward/item_pool_service.gd
```

主要过滤：

- `enabled`
- `rarity`
- `school_ids`
- `acquire_limit`
- `required_school_id`
- `duplicate_policy`

当前初始奖励和路线奖励会使用 `guarantees`，保证第一个候选来自角色主学派。

## 常见问题

### 新内容不出现

检查：

- `enabled` 是否为 `true`。
- `school_ids` 是否被当前 `SchoolState` 覆盖。
- `acquire_limit` 是否已经达到。
- `id` 前缀是否和内容类型一致。
- 奖励表或商店是否请求了正确的 `content_type`。

### 图标不显示

检查：

- 内容配置的 `asset_refs.icon`。
- `base_assets.json` 中是否存在对应 asset ID。
- `path` 指向的文件是否存在。
- Godot 是否已导入该图片。

### `scene_art` 不生效

当前可运行切片没有依赖 `scene_art`。如果后续要使用，需要先把 `scene_art` 加回 `ContentConfigLoader.CONTENT_DIRS`，并让表现层读取它。
