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
- Small floor differences are produced by six distinct generated floor bands, with stronger corruption, denser ruin silhouettes, and heavier purple-green pollution toward the front line.
- Route lanes and reward pads are baked into the background as scenery foundations. Runtime icons, selected markers, claimed state, lock state, route hotspots, and tooltips stay separate.

## Runtime Assets

Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `map.full_run_route.v02.background` | `assets/art/map/backgrounds/full_run_route_background_v02.png` | 1280x4320 full route map base |
| `map.full_run_route.v02.atmosphere` | `assets/art/map/backgrounds/full_run_route_atmosphere_v02.png` | 1280x4320 back-effect pollution atmosphere |
| `map.full_run_route.v02.foreground` | `assets/art/map/backgrounds/full_run_route_foreground_v02.png` | 1280x4320 transparent edge foliage/fog layer |
| `map.effect.future_pollution_fog.v02` | `assets/art/map/effects/future_pollution_fog_v02.png` | 1280x720 future-floor obstruction |
| `map.effect.past_shadow.v02` | `assets/art/map/effects/past_shadow_vignette_v02.png` | 1280x720 passed-floor darkening |
| `map.effect.current_spotlight.v02` | `assets/art/map/effects/current_floor_spotlight_v02.png` | 1280x720 current-floor focus |
| `map.effect.node_socket_glow.v02` | `assets/art/map/effects/node_socket_glow_v02.png` | reusable node socket glow |
| preview only | `assets/art/map/previews/full_run_route_preview_v02.png` | QA composite of runtime layers |

Source and metadata:

```text
assets/art/source/full_run_route_map_v02/
  floor_*.prompt.txt
  floor_*_raw.png
  floor_*_band_1280x720.png
  full_run_route_background_v02.prompt.txt
  manifest.json
```

Future higher-fidelity passes can replace the configured `v02` layers directly as long as the canvas stays 1280x4320 and the floor bands remain 720 px tall.

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
- `presentation.art_layers.layers[]`
- `presentation.state_effects`
- `presentation.node_visual`
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
