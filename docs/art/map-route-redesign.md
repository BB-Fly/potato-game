# Full-Run Route Map Redesign

## Direction

The route map is now a single scrollable run map instead of one small map slice per floor. The player can inspect the entire bottom-to-top route, while only the current floor accepts route, reward, and combat input.

Core layout:

- Floor 1 begins near the bottom of the full map with two start reward nodes. Both can be claimed before the first combat gate.
- Floors 2 and later split into left and right lanes. The player chooses one lane, then claims only the reward nodes on that lane before the shared combat gate unlocks.
- All floors are visible on the same 1280x4320 canvas. The camera scrolls to the current floor and can be manually moved with mouse wheel, middle-drag, right stick, or PageUp/PageDown.
- Passed floors are darkened read-only history. The current floor remains bright. Future floors are covered by pollution fog and locked.

## Visual Language

- Perspective: 3/4 top-down hand-painted route board, readable at a 1280x720 viewport.
- Style: Puritato hand-drawn cel-animation map style, thick ink silhouettes, readable pads, warm garden colors shifting into toxic purple corruption.
- Chapter 1: lush potato garden ruins, moss, stone walls, curly vines, warm leaves, mild purple mist.
- Chapter 2: corrupted greenhouse and mushroom-crystal growth, darker soil, teal mushrooms, blue-purple crystals, heavier fog.
- Small floor differences are produced by the assembled full-run background: each band has slightly different brightness, contrast, purple tint, and foreground haze.
- Route lanes and reward pads are baked into the background as scenery foundations. Runtime icons, selected markers, claimed state, lock state, route hotspots, and tooltips stay separate.

## Runtime Assets

Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `map.full_run_route.background` | `assets/art/map/backgrounds/full_run_route_background.png` | 1280x4320 full route map base |
| `map.full_run_route.foreground` | `assets/art/map/backgrounds/full_run_route_foreground.png` | 1280x4320 transparent edge foliage/fog layer |
| preview only | `assets/art/map/previews/full_run_route_preview.png` | QA composite of background + foreground |

Source and metadata:

```text
assets/art/source/full_run_route_map_v01/
  full_run_route_background.prompt.txt
  manifest.json
```

The current full-run art is assembled from the approved chapter route backgrounds:

```text
assets/art/map/backgrounds/chapter_1_route_background.png
assets/art/map/backgrounds/chapter_2_route_background.png
```

Future higher-fidelity passes can replace `full_run_route_background.png` and `full_run_route_foreground.png` directly as long as the canvas stays 1280x4320 and the floor bands remain 720 px tall.

## Data Contract

Map data lives in:

```text
content/base/maps/demo_map.json
```

Important fields:

- `presentation.layout_style = "full_run_scroll_route_map"`
- `presentation.canvas.width = 1280`
- `presentation.canvas.floor_height = 720`
- `presentation.canvas.height = 4320`
- `presentation.art_layers.background_path`
- `presentation.art_layers.foreground_path`
- `areas[].selection_mode`

Selection modes:

- `collect_all`: used by Floor 1. Every reward node on every route can be claimed before combat.
- `choose_one_route`: used by later floors. The player chooses one lane, then only that lane's reward nodes can be claimed.

Reward node positions are fixed through `position_hint` in normalized floor coordinates. Reward type and reward payload can be randomized with `reward_options`:

```json
{
  "id": "floor_3_left_outer_upper",
  "side": "outer",
  "position_hint": {"x": 0.23, "y": 0.32},
  "reward_options": [
    {"type": "random_item", "reward_table_id": "reward.random_item.chapter_1", "weight": 3},
    {"type": "coin", "gold": 315, "weight": 2},
    {"type": "weapon_master", "shop_id": "shop.weapon_master.default", "weight": 1}
  ]
}
```

`MapFlow.start_map()` realizes these slots once per run using the deterministic run RNG, so the full map can show the run's generated reward layout immediately.
