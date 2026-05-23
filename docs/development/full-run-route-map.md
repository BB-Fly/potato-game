# Full-Run Route Map Runtime

## Files

- `content/base/maps/demo_map.json`: full-run map data, canvas, art layer paths, floor areas, reward slots.
- `src/domain/map/map_flow.gd`: starts the map, realizes randomized reward slots, tracks current and previous area index.
- `src/app/playable/route_map_scene.gd`: renders the scrollable full map, node buttons, route hotspots, state overlays, and foreground parallax.
- `src/app/playable/playable_map_controller.gd`: enforces collect-all vs choose-one-route reward rules.
- `src/app/main.gd`: records claimed reward history and advances floors after combat.

## Runtime Flow

1. `MapFlow.start_map("map.demo")` duplicates the map config and resolves every node's `reward_options` with the run RNG.
2. `RouteMapScene.setup(...)` creates configured layered runtime controls:
   - background
   - back effect atmosphere
   - state underlay
   - route/node content
   - future fog
   - front effects
   - foreground overlay
3. The scene focuses the current floor but keeps the whole 1280x6480 map scrollable.
4. Only nodes on the current floor can be clicked.
5. Floor 1 uses `selection_mode: collect_all`, so both start reward nodes are active.
6. Floors 2-9 use `selection_mode: choose_one_route`, so clicking a lane locks the other lane.
7. Claimed rewards are stored in `run_context.reward_history` so passed floors render as dark read-only history.

## Authoring Notes

- Keep full-run runtime art at `1280x6480` for the current 3-act, 9-floor demo.
- Keep each floor band at `720` px high; floor 1 is the bottom band and floor 9 is the top band.
- Current runtime art uses `assets/art/source/full_run_route_map_v03_clean/`.
- The base background is intentionally clean and foundation-only. Put reward icons, shops, interactables, buildings, heavy props, foreground occluders, and animated effects on separate runtime layers or future prop layers.
- Store runtime-controlled reward icons and state markers as separate assets. Do not paint icons, labels, selected states, or locked states into the background.
- To add a new floor, update `presentation.canvas.height`, add an `areas[]` entry, and regenerate or extend the full-run background and foreground art.
- To vary a reward position without changing the art, edit the node `position_hint`.
- To vary the generated reward type, edit `reward_options` and weights.
- To add another visual layer, add it to `presentation.art_layers.layers[]` and choose one of the render layers supported by `RouteMapScene`: `background`, `back_effect`, `state`, `content`, `fog`, `front_effect`, or `foreground`.

## Controls

- Mouse wheel: scroll the whole run map.
- Middle mouse drag: pan the map.
- Gamepad right stick Y: scroll.
- PageUp/PageDown: snap between floor bands.

## Validation

```powershell
python tools\validate_art_assets.py
godot --headless --path . --script res://tools/validate_route_map_runtime.gd
godot --headless --path . --quit
```
