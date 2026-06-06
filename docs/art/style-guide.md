# Puritato Art Style Guide

This guide is the source of truth for runtime art direction after the hand-drawn replacement pass. Keep future generated, painted, or edited assets aligned with these constraints before they are installed into `assets/art/`.

## Core Direction

- Use an original hand-drawn cel-animation style: thick ink outlines, confident curved silhouettes, clean painted fills, and light brush texture.
- The target feel is simple, lively, and readable: close to vintage rubber-hose animation energy, with a darker whimsical survival-game edge for maps and monsters.
- Keep characters and monsters compact and toy-like. They should remain closer to simple potato-survivor mascots than complex humanoid creatures.
- Avoid pixel art for new runtime assets unless a task explicitly asks for a pixel-art experiment. The current runtime baseline is hand-drawn, not pixel.
- Do not copy specific characters, UI compositions, palettes, poses, or proportions from any reference game. References are mood and craft direction only.

## Shape Language

- Prioritize bold silhouettes that read at gameplay scale.
- Use thick dark outlines around the primary subject. Interior detail should use thinner ink lines and should not compete with the silhouette.
- Use squash-and-stretch poses for animation frames, but keep body volume consistent.
- Player, mob, boss, weapon, and VFX assets must remain distinguishable when overlapping on a busy arena.
- Runtime combat bodies should stay simple. The potato hero can use small feet, sprout, scarf, and facial expression as identity markers; avoid complex hands or full humanoid anatomy on the body sprite.

## Color And Rendering

- Use warm potato yellows, earthy browns, olive greens, teal mushroom tones, tomato reds, toxic yellow-greens, and dark purple corruption as recurring families.
- Use cel-style highlight blocks plus subtle painterly texture. Avoid noisy texture that makes icons muddy at 32 px or 64 px.
- Use rim highlights sparingly to separate shapes from dark backgrounds.
- Keep transparent assets clean: no colored chroma-key fringe, no accidental background pixels, and transparent corners unless the asset is meant to be a full background.
- Full route backgrounds should be RGB and fully opaque; icon, UI, sprite, and VFX assets should be RGBA with useful alpha.

## Characters And Creatures

- Preserve the established identities:
  - Potato hero: golden potato body, small green sprout, green scarf or bandana, dot eyes, tiny feet, friendly determined expression.
  - Sprouting potato monster: squat brown potato lump, angry face, green toxic sprouts or nubs, root feet.
  - Mushroom spore: teal cap, pale mint body, yellow-green spots, one sly glowing eye, root feet.
  - Bomb fruitling: round red fruit-bomb body, angry face, dark curled fuse, tiny feet.
  - Pollution boss: dark purple corrupted mass, green cracks or eye accents, tentacle-like edges.
- Animation sheets should keep each frame centered, with stable scale and stable feet or bottom anchor.
- Keep wide weapon trails, projectiles, impact bursts, and detached effects in VFX sheets rather than shrinking the body sprite to fit them.

## Weapons And VFX

- Weapon sprites should use simple, iconic props with thick outlines and readable materials.
- `weapon.fries` should remain one long golden fry staff or cudgel, not a fan of fries, sword, or blade.
- VFX should use clear arcs, spirals, bursts, and strong color separation. Prefer a few readable shapes over many tiny particles.
- VFX sheets may include detached sparks or glow particles, but the final runtime PNG must keep all visible pixels inside the sheet edge.

## UI And Icons

- UI should feel hand-inked and game-native: wood planks, paper cards, framed slots, simple arrows, hand-painted badges, and clear symbolic icons.
- Avoid modern flat UI, glossy mobile-game chrome, photo-real materials, or tiny ornamental details.
- Icons must remain legible at 32 px and 64 px. If a concept cannot read at those sizes, simplify the symbol.
- Reuse established visual metaphors:
  - health: heart or red life badge;
  - mana or magic: green crystal, potion, spiral, or leaf-magic motif;
  - rewards: coin stack, trophy, clover, reroll medallion, upgrade hammer;
  - shops: weapon, magic crystal, backpack, or master-tool symbols.
- Card and slot frames should keep transparent interiors where the UI expects content to appear.

## Route Maps And Backgrounds

- Route backgrounds use a 3/4 top-down hand-painted board layout with clear circular pads, readable branching paths, and decorative biome edges.
- Chapter 1 direction: lush potato garden, stone walls, vines, warm greens and yellows.
- Chapter 2 direction: darker mushroom/crystal corruption, teal mushrooms, purple crystals, thorny vines, cooler lighting.
- Backgrounds can be detailed, but gameplay pads and paths must stay readable and not be covered by decorative clutter.
- Map node icons should remain separate transparent assets, not baked into backgrounds.

## Asset Pipeline Rules

- Keep runtime file paths and configured asset IDs stable unless a feature explicitly requires a registry migration.
- Preserve the original runtime image dimensions when replacing an existing asset.
- Keep generated source material, prompts, metadata, review images, and discarded variants outside the runtime art tree; only promote final demo-ready PNGs into `assets/art/` and register them in `content/base/assets/base_assets.json`.
- Before committing an art pass, run:

```powershell
python tools\validate_art_assets.py
godot --headless --path . --quit
```

- Do not bulk-commit Godot `.import` churn unless import settings themselves are part of the task.
