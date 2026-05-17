# 地图、路线与奖励

本文档说明当前地图路线、奖励节点、商店和战斗入口的实现方式。当前实现已经把可调地图布局迁移到独立 Godot 场景中，避免文档、JSON 配置和编辑器画面互相打架。

## 数据来源

地图可编辑场景：

```text
scenes/route_map_scene.tscn
```

地图场景脚本：

```text
src/app/playable/route_map_scene.gd
src/app/playable/route_map_area.gd
src/app/playable/route_map_route.gd
src/app/playable/route_map_reward_node.gd
src/app/playable/route_map_combat_node.gd
```

地图运行时推进：

```text
src/domain/map/map_flow.gd
```

`content/base/maps/demo_map.json` 仍会被加载，用于 `MapFlow.start_map("map.demo")`、当前 area index、章节和层数推进的基础数据。但路线结构、奖励节点类型、节点位置、战斗节点位置以 `scenes/route_map_scene.tscn` 中的 `AreaDefinitions` 为准。场景中找不到对应 area 时，代码才回退到 JSON 数据。

奖励池：

```text
content/base/rewards/default_rewards.json
src/domain/reward/item_pool_service.gd
```

商店配置：

```text
content/base/shops/default_shops.json
src/domain/economy/economy_service.gd
```

路线状态、奖励候选和购买发放逻辑：

```text
src/app/playable/playable_map_controller.gd
src/app/playable/playable_reward_controller.gd
```

## 场景结构

`scenes/route_map_scene.tscn` 的关键结构：

```text
RouteMapScene
  Background
  Overlay
  AreaDefinitions
    Chapter1Area1
      Routes
        LeftRoute
          Hotspot
          RewardNodes
        RightRoute
          Hotspot
          RewardNodes
      CombatNodes
    Chapter1Area2
    ...
  Generated
```

每个 `Chapter*Area*` 节点挂载 `RouteMapArea`，导出字段包括：

- `area_id`
- `chapter_id`
- `floor`
- `background_path`
- `run_victory_on_clear`

每条路线节点挂载 `RouteMapRoute`，导出字段包括：

- `route_id`
- `display_lane`

每个奖励节点是 `Marker2D`，挂载 `RouteMapRewardNode`。在 Inspector 中可编辑：

- `node_type`
- `reward_table_id`
- `shop_id`
- `encounter_pool_id`
- `gold`
- `side`

每个战斗节点是 `Marker2D`，挂载 `RouteMapCombatNode`。在 Inspector 中可编辑：

- `node_id`
- `reward_table_id`

运行时绘制出来的按钮、标签、边框放在 `Generated` 下。不要手动编辑 `Generated` 的子节点，它们每次进入地图都会重建。

## 调整地图布局

要根据地图背景调整节点位置，直接在 Godot 编辑器中打开：

```text
scenes/route_map_scene.tscn
```

常用调整点：

- 移动 `RewardNodes` 下的具体 `Marker2D`：改变奖励节点图标和标签位置。
- 调整 `Hotspot` 的位置和大小：改变左右路线可点击区域和高亮框。
- 移动 `CombatNodes/Combat`：改变战斗节点位置。
- 修改奖励节点 Inspector 字段：改变节点类型、金币数量、商店或奖励表。

所有位置都使用当前原型的 1280x720 逻辑坐标，并随 `ui_root` 一起缩放。

## 路线选择流程

当前代码流程：

```text
_show_map_screen()
  -> instantiate scenes/route_map_scene.tscn
  -> route_map_scene.setup(map_flow, route_controller, run_context, asset_catalog)
  -> RouteMapScene.render()
  -> 从 AreaDefinitions 中读取当前 area 的路线、奖励节点和战斗节点

点击路线
  -> RouteMapScene 发出 route_selected(route_id)
  -> main.gd::_choose_route(route_id)
  -> RouteMapScene.choose_route(route_id)
  -> PlayableMapController.choose_route_data(map_flow, route)
  -> MapFlow.record_route_choice(route_id)
  -> _show_map_screen()
```

表现规则：

- 进入地图后，两边奖励节点都可预览。
- 未选择路线时，奖励节点不可点击。
- 选择一条路线后，该路线高亮，另一条路线锁定。
- 只有被选择路线上的奖励节点可点击。
- 领取完当前路线所有奖励后，战斗节点解锁。

## 奖励节点类型

当前 `main.gd::_click_route_reward_node()` 支持：

| 节点类型 | 行为 |
| --- | --- |
| `coin` | 直接获得金币 |
| `free_weapon` | 打开奖励选择 |
| `random_item` | 打开奖励选择 |
| `weapon_shop` | 打开商店 |
| `magic_shop` | 打开商店 |
| `item_shop` | 打开商店 |
| `weapon_master` | 当前走简化商店逻辑 |
| `magic_master` | 当前走简化商店逻辑 |
| `encounter` | 当前简化为获得金币 |

领取奖励后：

```text
route_controller.claim_node(node_index)
```

然后回到地图。

## 奖励选择

入口函数：

```text
_show_reward_choices(reward_id, on_done)
```

当前实现：

- `PlayableRewardController` 根据 `reward_id` 粗略判断 `content_type`。
- `PlayableRewardController` 使用 `ItemPoolService.roll_offer()` 抽取 3 个候选。
- 如果候选不足，会重复已有候选填满。
- 玩家点击卡片或图标后调用 `_grant_content_and_continue()`。

注意：当前没有单独的“选择”按钮，卡片整体可点击。

## 商店

入口函数：

```text
_show_shop_screen(node_data, on_done)
```

当前实现：

- 根据节点类型判断默认商店 ID，或使用场景节点上配置的 `shop_id`。
- 展示商店候选。
- 点击卡片直接购买。
- 价格通过 `EconomyService.price_for_entry(run_context, shop_id, entry)` 计算。

## 战斗入口

战斗节点来自当前 area 的 `CombatNodes`。

解锁条件：

```text
route_controller.combat_locked() 为 false
```

点击后进入：

```text
_start_combat()
```

战斗胜利后：

```text
_finish_combat()
  -> map_flow.advance_area()
  -> _show_map_screen()
```

如果没有下一层，则进入 `_show_victory_screen()`。

## 新增节点类型建议

短期可以：

1. 在 `RouteMapRewardNode.node_type` 的 `@export_enum` 中加入新类型。
2. 在 `PlayableContentPresenter.node_type_name()` 和资源表中补显示名与图标。
3. 在 `main.gd::_click_route_reward_node()` 中新增 `match` 分支。

长期建议：

- 把节点行为抽成 command 或 handler。
- 让节点配置声明 `node_behavior_id`。
- 地图场景只负责展示和发送点击事件。
- 奖励、商店、奇遇各自拥有独立运行时。

## 常见问题

### 奖励节点看不到

检查：

- 当前 `MapFlow.get_current_area().id` 是否能匹配 `AreaDefinitions` 下某个 `RouteMapArea.area_id`。
- 对应路线的 `RewardNodes` 下是否存在奖励 `Marker2D`。
- 节点 icon 的 asset ID 是否存在。
- `Generated` 是否被运行时清空并重建。

### 奖励节点不能点击

检查：

- 是否已经选择路线。
- 该节点是否属于选中路线。
- `claimed_route_nodes` 是否已经包含该节点 index。

### 战斗入口不能点击

检查：

- `selected_route_id` 是否为空。
- 当前路线奖励是否全部领取。
- 当前 area 是否有 `CombatNodes/Combat`。

### 编辑器里改了位置但运行时没变化

检查：

- 是否编辑的是 `scenes/route_map_scene.tscn`，而不是运行时生成的 `Generated` 子节点。
- 是否编辑了当前 floor 对应的 `Chapter*Area*`。
- `area_id` 是否和 `content/base/maps/demo_map.json` 中的 area `id` 保持一致。
