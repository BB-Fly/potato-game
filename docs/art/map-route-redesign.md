# Full-Run Route Map Redesign

## Direction

The route map is a single scrollable run map instead of one small map slice per floor. The player can inspect the entire bottom-to-top route, while only the current floor accepts route, reward, and combat input.

Core layout:

- The full demo run contains 3 major acts and 9 small stages on one 1280x6480 canvas.
- Floor 1 begins near the bottom of the full map with two start reward nodes. Both can be claimed before the first combat gate.
- Floors 2-9 split into left and right lanes. The player chooses one lane, then claims only the reward nodes on that lane before the shared combat gate unlocks.
- Passed floors are darkened read-only history. The current floor remains bright. Future floors are covered by pollution fog and locked.
- Runtime-controlled rewards, selected states, claimed states, locks, route hotspots, icons, and tooltips stay separate from the background.

## Visual Language

- Perspective: 3/4 top-down hand-painted route board, readable at a 1280x720 viewport.
- Style: Puritato watercolor/cel-animation map style, soft ink silhouettes, readable roads and pads, clean background color fields.
- Background contract: foundation-only. The base image may contain terrain, roads, low floor marks, empty circular socket pads, cracks, stains, puddles, and pollution washes. It must not bake in buildings, shops, chests, characters, monsters, reward icons, large props, walls, factories, signs, labels, or foreground occluders.
- Act 1, floors 1-3: clean rear potato fields, warm soil, pale stone roads, flat crop-field markings, irrigation curves.
- Act 2, floors 4-6: abandoned greenhouse wetland, teal ground washes, shallow puddles, low violet crystal stains.
- Act 3, floors 7-9: polluted front-line wasteland, ash-gray ground, industrial floor scars as flat markings, toxic purple-green contamination.
- Pollution increases toward the front line, but the playable route remains open and readable.

## Runtime Assets

Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `map.full_run_route.v03_clean.background` | `assets/art/map/backgrounds/full_run_route_background_v03_clean.png` | 1280x6480 foundation-only full route map |
| `map.full_run_route.v03_clean.atmosphere` | `assets/art/map/backgrounds/full_run_route_atmosphere_v03_clean.png` | 1280x6480 subtle pollution atmosphere |
| `map.full_run_route.v03_clean.foreground` | `assets/art/map/backgrounds/full_run_route_foreground_v03_clean.png` | 1280x6480 transparent edge haze layer |
| `map.effect.future_pollution_fog.v03_clean` | `assets/art/map/effects/future_pollution_fog_v03_clean.png` | 1280x720 future-floor obstruction |
| `map.effect.past_shadow.v03_clean` | `assets/art/map/effects/past_shadow_vignette_v03_clean.png` | 1280x720 passed-floor darkening |
| `map.effect.current_spotlight.v03_clean` | `assets/art/map/effects/current_floor_spotlight_v03_clean.png` | 1280x720 current-floor focus |
| `map.effect.node_socket_glow.v03_clean` | `assets/art/map/effects/node_socket_glow_v03_clean.png` | reusable node socket glow |
| preview only | `assets/art/map/previews/full_run_route_preview_v03_clean.png` | QA composite of runtime layers |

Source and metadata:

```text
assets/art/source/full_run_route_map_v03_clean/
  act_1_garden_raw.png
  act_2_greenhouse_raw.png
  act_3_frontline_raw.png
  act_*_1280x2160.png
  floor_01_band_1280x720.png ... floor_09_band_1280x720.png
  *.prompt.txt
  manifest.json
```

The runtime consumes the complete 1280x6480 long map, not the individual source bands. The source bands are retained for review and future art replacement.

## Data Contract

Map data lives in:

```text
content/base/maps/demo_map.json
```

Important fields:

- `presentation.layout_style = "full_run_scroll_route_map"`
- `presentation.canvas.width = 1280`
- `presentation.canvas.floor_height = 720`
- `presentation.canvas.height = 6480`
- `presentation.art_layers.layers[]`
- `presentation.state_effects`
- `presentation.node_visual`
- `areas[].chapter_id`
- `areas[].selection_mode`

Selection modes:

- `collect_all`: used by Floor 1. Every reward node on every route can be claimed before combat.
- `choose_one_route`: used by Floors 2-9. The player chooses one lane, then only that lane's reward nodes can be claimed.

Reward node positions are fixed through `position_hint` in normalized floor coordinates. Reward type and reward payload can be randomized with `reward_options`:

```json
{
  "id": "floor_7_left_outer_upper",
  "side": "outer",
  "position_hint": {"x": 0.24, "y": 0.24},
  "reward_options": [
    {"type": "weapon_shop", "shop_id": "shop.weapon.default", "weight": 3},
    {"type": "weapon_master", "shop_id": "shop.weapon_master.default", "weight": 1},
    {"type": "coin", "gold": 630, "weight": 1}
  ]
}
```

`MapFlow.start_map()` realizes these slots once per run using the deterministic run RNG, so the full map can show the run's generated reward layout immediately.
