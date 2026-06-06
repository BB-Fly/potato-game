# Route Map Art Direction

## Direction

The current playable demo uses scrollable floor bands with chapter-specific route backgrounds. Runtime-controlled rewards, selected states, claimed states, locks, route hotspots, icons, and tooltips stay separate from the background.

## Visual Language

- Perspective: readable 3/4 top-down route board for a 1280x720 logical viewport.
- Style: Puritato watercolor/cel-animation map style, soft ink silhouettes, readable roads and pads, clean background color fields.
- Background contract: foundation-only. The base image may contain terrain, roads, low floor marks, empty circular socket pads, cracks, stains, puddles, and pollution washes.
- Do not bake in buildings, shops, chests, characters, monsters, reward icons, large props, walls, factories, signs, labels, or foreground occluders.
- Chapter 1: clean rear potato fields, warm soil, pale stone roads, flat crop-field markings, irrigation curves.
- Chapter 2: abandoned greenhouse wetland, teal ground washes, shallow puddles, low violet crystal stains.

## Runtime Assets

| Asset ID | Path | Notes |
| --- | --- | --- |
| `map.chapter_1_route.background` | `assets/art/map/backgrounds/chapter_1_route_background.png` | Chapter 1 route backdrop |
| `map.chapter_2_route.background` | `assets/art/map/backgrounds/chapter_2_route_background.png` | Chapter 2 route backdrop |
| `map.node.*.icon` | `assets/art/map/nodes/*.png` | Runtime-controlled node icons and markers |

## Data Contract

Map data lives in:

```text
content/base/maps/demo_map.json
```

The map scene should keep reward icons, selected states, claimed states, locks, route hotspots, and labels as runtime UI or node assets rather than painting them into backgrounds.
