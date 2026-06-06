# Route Map Runtime

The old full-run long-map art pass has been removed from the runtime asset set. The current demo uses scrollable floor bands backed by chapter route backgrounds.

## Files

- `content/base/maps/demo_map.json`: map areas, reward slots, and route metadata.
- `src/domain/map/map_flow.gd`: starts the map, realizes randomized reward slots, tracks current and previous area index.
- `src/app/playable/route_map_scene.gd`: renders route bands, node buttons, route hotspots, state overlays, and scroll focus.
- `src/app/playable/playable_map_controller.gd`: enforces collect-all vs choose-one-route reward rules.
- `src/app/main.gd`: records claimed reward history and advances floors after combat.

## Runtime Flow

1. `MapFlow.start_map("map.demo")` duplicates the map config and resolves every node's `reward_options`.
2. `RouteMapScene.setup(...)` creates runtime layers for background, state, content, fog, and foreground controls.
3. If no custom art layer is configured, each area uses its chapter background.
4. Only nodes on the current floor can be clicked.
5. Floor 1 uses `selection_mode: collect_all`.
6. Later floors use `selection_mode: choose_one_route`.
7. Claimed rewards are stored in `run_context.reward_history` so passed floors can render as read-only history.

## Authoring Notes

- Keep chapter backgrounds in `assets/art/map/backgrounds/`.
- Store route node icons and state markers as separate assets under `assets/art/map/nodes/`.
- Do not paint icons, labels, selected states, or locked states into the background.
- To vary a reward position without changing art, edit the node `position_hint`.
- To vary generated reward type, edit `reward_options` and weights.

## Validation

```powershell
python tools\validate_art_assets.py
godot --headless --path . --script res://tools/validate_route_map_runtime.gd
godot --headless --path . --quit
```
