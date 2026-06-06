# Assets And Art

This document describes the current runtime art layout after the temporary art cleanup.

## Registry

Runtime content should resolve art through stable asset IDs:

```text
content config -> asset_refs -> asset id -> content/base/assets/base_assets.json -> res:// path
```

The resolver lives in:

```text
src/config/asset_catalog.gd
```

Some UI shells still use direct `res://assets/art/...` paths for fixed HUD or background pieces. New content-facing art should prefer `asset_refs`.

## Runtime Layout

```text
assets/art/
  icons/             item, buff, reward, character, monster, boss, and utility icons
  sprites/           runtime spritesheets and weapon sprites
  map/backgrounds/   chapter route backgrounds
  map/nodes/         route node icons and markers
  music_states/      music/debug state icons
  ui/                HUD, slot, panel, card, button, shop, and reward UI pieces
  vfx/               combat VFX spritesheets
```

Temporary generation sources, prompts, processed frames, preview composites, style previews, and production candidates are no longer part of the repo. Keep future source material outside the runtime asset tree unless it is intentionally promoted to a stable runtime PNG.

## Current Key Assets

Route backgrounds:
- `assets/art/map/backgrounds/chapter_1_route_background.png`
- `assets/art/map/backgrounds/chapter_2_route_background.png`

Player:
- `assets/art/sprites/characters/potato_hero.png`
- `assets/art/sprites/characters/potato_hero_walk.png`

Monsters and boss:
- `assets/art/sprites/monsters/sprouting_potato.png`
- `assets/art/sprites/monsters/mushroom_spore.png`
- `assets/art/sprites/monsters/bomb_fruitling.png`
- `assets/art/sprites/bosses/demo_pollution_source.png`

Weapon and VFX:
- `assets/art/sprites/weapons/fries.png`
- `assets/art/vfx/weapon_fries_slash.png`
- `assets/art/vfx/comprehensive_development.png`

Map nodes:
- `assets/art/map/nodes/`

## Future Art Tasks

Dedicated menu, settings, and arena backgrounds are intentionally not present in the runtime tree yet. Generate or edit those assets outside the repo first, then promote only final PNGs and register them.

## Godot `.import` Files

Godot can regenerate `.import` files. Do not commit them unless import settings are the explicit purpose of the change.

## Authoring Notes

1. Check the current runtime folders first.
2. Generate or edit art outside the runtime tree while experimenting.
3. Promote only final PNGs into `assets/art/...`.
4. Add or update the asset ID mapping in `content/base/assets/base_assets.json`.
5. Reference the asset ID from content `asset_refs`.
6. Run the asset validation and Godot headless checks.
