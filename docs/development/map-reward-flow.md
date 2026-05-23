# Map, Routes, And Rewards

This document describes the current full-run route map and reward flow. The older one-floor-per-screen route slices have been replaced by a single scrollable map for the whole run.

## Data Sources

Map configuration:

```text
content/base/maps/demo_map.json
```

Runtime scripts:

```text
src/domain/map/map_flow.gd
src/app/playable/route_map_scene.gd
src/app/playable/playable_map_controller.gd
src/app/main.gd
```

Runtime art:

```text
assets/art/map/backgrounds/full_run_route_background_v03_clean.png
assets/art/map/backgrounds/full_run_route_atmosphere_v03_clean.png
assets/art/map/backgrounds/full_run_route_foreground_v03_clean.png
assets/art/map/effects/
assets/art/map/previews/full_run_route_preview_v03_clean.png
assets/art/source/full_run_route_map_v03_clean/
```

`scenes/route_map_scene.tscn` is still the Godot scene entry point, but route data now comes from `demo_map.json`. The old `AreaDefinitions` nodes are kept as editor context/fallback scaffolding and should not be treated as the source of truth.

## Map Structure

The demo map uses:

```json
"layout_style": "full_run_scroll_route_map",
"canvas": {"width": 1280, "floor_height": 720, "height": 6480}
```

Floor bands are stacked bottom to top:

- floor 1 at the bottom of the 6480 px canvas
- floor 9 at the top
- floors 1-3: `chapter_1`
- floors 4-6: `chapter_2`
- floors 7-9: `chapter_3`

The map scene renders these layers:

1. full-run clean foundation background
2. subtle pollution atmosphere
3. past/current/future state underlays and textures
4. route hotspots, reward/combat node buttons, and node socket glow
5. future pollution fog
6. foreground edge haze with a slight parallax scroll factor

The foundation background contains only terrain, roads, empty socket pads, and flat ground detail. Runtime reward icons, random rewards, buildings, props, locks, markers, and interaction states stay outside the baked image.

## Reward Slot Realization

Reward positions are fixed in each node with `position_hint`. Reward type and payload can be randomized with `reward_options`.

`MapFlow.start_map()` duplicates the map entry and resolves every `reward_options` list once with the deterministic run RNG. After this step, runtime nodes have concrete `type`, `gold`, `shop_id`, `reward_table_id`, or `encounter_pool_id` fields.

Example:

```json
{
  "id": "floor_8_right_inner_upper",
  "side": "inner",
  "position_hint": {"x": 0.76, "y": 0.24},
  "reward_options": [
    {"type": "magic_master", "shop_id": "shop.magic_master.default", "weight": 3},
    {"type": "coin", "gold": 705, "weight": 2},
    {"type": "random_item", "reward_table_id": "reward.random_item.chapter_3", "weight": 1}
  ]
}
```

## Selection Rules

`selection_mode: collect_all`

- Used by floor 1.
- Both start reward nodes can be claimed.
- Combat unlocks after all start rewards are claimed.

`selection_mode: choose_one_route`

- Used by floors 2-9.
- The player first chooses `left` or `right`.
- Only rewards on the selected route can be claimed.
- Combat unlocks after all rewards on the selected route are claimed.

Claimed nodes are recorded in `run_context.reward_history` so passed floors remain readable as darkened history after the route controller resets for the next floor.

## Controls

- Mouse wheel: scroll the whole run map.
- Middle mouse drag: pan.
- Gamepad right stick Y: scroll.
- PageUp/PageDown: snap between floor bands.

## Validation

```powershell
python tools\validate_art_assets.py
godot --headless --path . --script res://tools/validate_route_map_runtime.gd
godot --headless --path . --quit
```
