# 资源、美术与导入

本文档说明当前资源引用、像素资源目录、缺失资源兜底和 Godot 导入文件处理。

## 资源注册表

主要配置：

```text
content/base/assets/base_assets.json
```

解析器：

```text
src/config/asset_catalog.gd
```

推荐路径：

```text
content config -> asset_refs -> asset id -> base_assets.json -> res:// path -> Texture/Sound
```

当前 `main.gd` 中仍有部分直接 `res://...` 硬编码路径，这是为了快速恢复可运行切片。后续整理时应逐步改为 `asset_refs` 或统一的表现资源表。

## 目录结构

```text
assets/art/
  icons/             通用图标
  sprites/           运行时 sprite
  map/               地图背景和节点图标
  music_states/      音乐状态图标
  source/            生成源图、帧拆分、prompt、处理元数据
  ui/                UI 框、按钮、货币、槽位
  vfx/               战斗特效
```

`assets/art/source/` 中的文件通常用于追溯生成过程或直接取帧。当前原型中，玩家、怪物和 Boss 动画直接使用了一些 source frame。

## 当前运行时直接使用的关键资源

路线背景：

- `assets/art/map/backgrounds/chapter_1_route_background.png`
- `assets/art/map/backgrounds/chapter_2_route_background.png`

玩家：

- `assets/art/source/potato_hero_idle_handless/`
- `assets/art/source/potato_hero_walk_handless/`

怪物：

- `assets/art/source/sprouting_potato/`
- `assets/art/source/enemy_pack_01/mushroom_spore/`
- `assets/art/source/enemy_pack_01/bomb_fruitling/`

Boss：

- `assets/art/source/boss_pollution_source/`
- `assets/art/source/enemy_pack_01/boss_pollution_source_warning/`

武器和 VFX：

- `assets/art/sprites/weapons/fries.png`
- `assets/art/source/fries_slash/`
- `assets/art/source/magic_vfx/`

地图节点：

- `assets/art/map/nodes/`

## 规划中但当前缺失的资源

这些资源在设计或 `scene_art` 文档中出现，但当前可运行切片不依赖它们启动：

- `assets/art/screens/main_menu_background.png`
- `assets/art/screens/settings_background.png`
- `assets/art/map/arenas/chapter_1_arena.png`
- `assets/art/map/arenas/chapter_2_arena.png`

如果要启用这些资源，必须先确保图片文件存在并提交，再修改运行时引用。不要让启动界面依赖未提交资源，否则容易回到灰屏。

## Godot `.import` 文件

打开 Godot 后会生成大量 `.import` 文件。当前约定：

- 默认不要批量提交 `.import`。
- 只有当导入设置本身是任务的一部分时，才提交相关 `.import`。
- 提交前用 `git status --short` 确认不要把自动生成噪声混进功能提交。

## 使用像素美术 skill

当项目缺少像素资源，且无法用现有资源合理复用时，使用 `generate2dsprite` 或 `generate2dmap` skill。

推荐流程：

1. 先查 `assets/art/source/` 和 `assets/art/` 是否已有可用素材。
2. 如果没有，再生成。
3. 生成后保留 source、prompt、处理元数据。
4. 把运行时 PNG 放到合适目录。
5. 在 `content/base/assets/base_assets.json` 中增加 asset ID 映射。
6. 在相关内容配置的 `asset_refs` 中引用该 asset ID。
7. 运行 Godot headless 检查路径。

## 资源命名建议

文件名使用小写 snake case：

```text
weapon_fries.png
boss_pollution_source_warning.png
chapter_1_route_background.png
```

内容 ID 使用点分层：

```text
weapon.fries.icon
boss.demo_pollution_source.sprite
map.node.weapon_shop.icon
```

保持内容 ID 稳定。即使文件移动，也优先只更新 `base_assets.json` 的 `path`。

## 表现原则

- 游戏内角色和怪物以像素帧动画、上下伸缩、左右伸缩为主。
- 角色 idle 不使用旋转。
- 武器、剑气、魔法 VFX 可以旋转和缩放。
- 战斗中碰撞使用简单图形，不追求贴图轮廓。
- 地图节点要在 64px 左右仍能识别。
- 商店和奖励选择应支持点击图标或卡片直接交互。
