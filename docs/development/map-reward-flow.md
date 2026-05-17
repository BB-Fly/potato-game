# 地图、路线与奖励

本文档说明当前地图路线、奖励节点、商店和战斗入口的实现方式。

## 数据来源

地图配置：

```text
content/base/maps/demo_map.json
```

地图运行时：

```text
src/domain/map/map_flow.gd
```

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

当前地图 UI 和交互主要在 `src/app/main.gd` 中实现。

## 地图结构

`map.demo` 包含多个 `areas`。每个 area 对应一层或一个小关区域。

每个 area 主要包含：

- `id`
- `chapter_id`
- `floor`
- `entry_node`
- `routes`
- `shared_exit_nodes`

`routes` 当前固定为左右两条路线。每条路线包含多个奖励节点。

## 路线选择流程

当前代码流程：

```text
_show_map_screen()
  -> _add_route_hotspot()
  -> _add_route_reward_nodes()
  -> _add_combat_node()

点击路线
  -> _choose_route(route_id)
  -> map_flow.choose_route(route_id)
  -> active_route = route
  -> selected_route_id = route_id
  -> _show_map_screen()
```

表现规则：

- 进入地图后，两边奖励节点都可预览。
- 未选择路线时，奖励节点不可点击。
- 选择一条路线后，该路线高亮。
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
claimed_route_nodes[node_index] = true
```

然后回到地图。

## 奖励选择

入口函数：

```text
_show_reward_choices(reward_id, on_done)
```

当前实现：

- 根据 `reward_id` 粗略判断 `content_type`。
- 使用 `ItemPoolService.roll_offer()` 抽取 3 个候选。
- 如果候选不足，`_fill_offer_choices()` 会重复已有候选填满。
- 玩家点击卡片或图标后调用 `_grant_content_and_continue()`。

注意：当前没有单独的“选择”按钮，卡片整体可点击。

## 商店

入口函数：

```text
_show_shop_screen(node_data, on_done)
```

当前是简化版本：

- 根据节点类型判断 `content_type`。
- 展示 3 个候选。
- 点击卡片直接购买。
- 当前价格逻辑在 `main.gd::_buy_content()` 中简化为 `120 + floor * 35`。

长期应改回读取 `EconomyService` 和 `content/base/shops/default_shops.json` 的正式价格表。

## 战斗入口

战斗节点通过 `_add_combat_node()` 创建。

解锁条件：

```text
selected_route_id 不为空
并且 _route_rewards_complete() 为 true
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

短期可以在 `_click_route_reward_node()` 中新增 `match` 分支。

长期建议：

- 把节点行为抽成 command 或 handler。
- 让节点配置声明 `node_behavior_id`。
- 地图 UI 只负责展示和发送点击事件。
- 奖励、商店、奇遇各自拥有独立运行时。

## 常见问题

### 奖励节点看不到

检查：

- `position_hint.x/y` 是否在 `0..1` 范围内。
- `_add_route_reward_nodes()` 是否被调用。
- 节点 icon 的 asset ID 是否存在。

### 奖励节点不能点击

检查：

- 是否已经选择路线。
- 该节点是否属于选中路线。
- `claimed_route_nodes` 是否已经包含该节点 index。

### 战斗入口不能点击

检查：

- `selected_route_id` 是否为空。
- 当前路线奖励是否全部领取。
- `shared_exit_nodes` 是否存在。
