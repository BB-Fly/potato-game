# Route Map Art Redesign

## Direction

The route selection map should use an original vertical rail-board composition with the same usability goals as modern roguelike route maps, without copying Monster Train 2 assets, UI, icons, palettes, or exact proportions.

Core layout:

- Player enters each floor from the bottom center.
- The map splits into two readable routes: left lane and right lane.
- Each route can place reward nodes on both sides of the lane, using `side: inner` and `side: outer` metadata.
- Both routes converge into one shared combat gate near the top center.
- After combat victory, the camera scrolls upward to the next floor map.
- Mouse wheel and gamepad right stick can scroll back to revealed floors for read-only inspection.

## Visual Language

- Perspective: 3/4 top-down route board, readable on a 1920x1080 screen.
- Chapter 1: overgrown potato-field ruins, green growth, stone retaining walls, mild purple pollution mist at the edges.
- Chapter 2: deeper corrupted greenhouse/underground garden, stronger blue-purple crystals, darker soil, sharper magical highlights.
- Route lanes: rail-like or root-like tracks embedded in terrain, clearly branching from bottom and joining at top.
- Reward pads: small circular or shield-like platforms beside the lanes; leave enough negative space for node icons.
- Shared combat gate: larger top-center gate/emblem/pad that reads as the mandatory fight.

## Runtime Split

Route backgrounds are scenery and lane foundation only. Runtime-controlled node icons, selected markers, route arrows, tooltips, and completed/locked states stay separate UI/object layers.

The background may include:

- terrain, walls, rails/roots, decorative non-interactive plants, mist, lighting;
- empty reward pads and the shared combat gate base;
- bottom entrance and top continuation hint.

The background must not bake in:

- actual reward icons;
- text labels;
- selected/completed/locked states;
- player character, enemies, boss, or combat actors;
- UI counters or HUD.

## Suggested Image Prompts

Runtime source folders:

- `assets/art/source/route_map_chapter_1_vertical/`
- `assets/art/source/route_map_chapter_2_vertical/`

Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `map.chapter_1_route.background` | `assets/art/map/backgrounds/chapter_1_route_background.png` | overgrown potato-field route board |
| `map.chapter_2_route.background` | `assets/art/map/backgrounds/chapter_2_route_background.png` | corrupted greenhouse route board |

Chapter 1 route background:

```text
Original 3/4 top-down fantasy roguelike route selection map background for a vegetable-themed survivor game, 1920x1080. Bottom-center entrance gate, two branching rail-like root tracks curving upward through overgrown potato-field ruins, small empty circular reward pads on both sides of each route, both routes converge into one larger top-center combat gate. Green moss, potato leaves, stone retaining walls, subtle purple pollution mist at the edges, clean HD hand-painted game asset, sharp readable silhouettes, no text, no UI, no characters, no icons.
```

Chapter 2 route background:

```text
Original 3/4 top-down fantasy roguelike route selection map background for a vegetable-themed survivor game, 1920x1080. Bottom-center entrance, two branching rail-like root tracks through a corrupted underground greenhouse, empty reward pads beside both lanes, both routes join at a large top-center combat gate. Dark fertile soil, blue-purple crystals, strange vines, broken stone rails, magical fog around the edges, clean HD hand-painted game asset, sharp readable silhouettes, no text, no UI, no characters, no icons.
```
