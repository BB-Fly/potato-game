# Map, Routes, And Rewards

This document describes the current route map and reward flow for the playable demo.

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
assets/art/map/backgrounds/chapter_1_route_background.png
assets/art/map/backgrounds/chapter_2_route_background.png
assets/art/map/nodes/
```

`scenes/route_map_scene.tscn` remains the Godot scene entry point. Route data comes from `demo_map.json`; the scene can fall back to chapter band backgrounds when no custom art layer is configured.

## Map Structure

The demo map uses a scrollable chapter-band layout:

```json
"layout_style": "chapter_band_scroll_route_map",
"canvas": {"width": 1280, "floor_height": 720}
```

Floors are stacked as bands. Floors 1-3 use `chapter_1`; floors 4-6 use `chapter_2`; later floor data may exist for balancing, but the current runtime art set only keeps the chapter backgrounds above.

## Reward Flow

1. `MapFlow.start_map("map.demo")` duplicates the map config and realizes each node's `reward_options` with the run RNG.
2. `RouteMapScene.setup(...)` renders route bands, node buttons, route hotspots, and basic state overlays.
3. Only current-floor reward nodes are interactive.
4. Floor 1 uses `selection_mode: collect_all`, so both start reward nodes are active.
5. Later floors use `selection_mode: choose_one_route`, so clicking a lane locks the other lane.
6. Claimed rewards are stored in `run_context.reward_history`.

## Validation

```powershell
python tools\validate_art_assets.py
godot --headless --path . --script res://tools/validate_route_map_runtime.gd
godot --headless --path . --quit
```
