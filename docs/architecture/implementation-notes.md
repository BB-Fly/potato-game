# Current Implementation Notes

This document describes the current playable Godot prototype, not the final target architecture. Use it as a handoff guide for new work sessions and future agents.

## Snapshot

- Current stable checkpoint: `d6ea0ca Restore playable Godot prototype`.
- Godot version used locally: `4.6.2 stable Mono`.
- Main scene: `scenes/main.tscn`.
- Main runtime script: `src/app/main.gd`.
- The prototype intentionally keeps presentation and gameplay in `main.gd` for speed. The domain folders under `src/domain/` are still the intended long-term architecture, but many combat and UI behaviors are currently implemented directly in the playable slice.

## Startup Flow

`scenes/main.tscn` contains one `Node` with `src/app/main.gd` attached.

On `_ready()`, `main.gd` must:

1. Set fixed physics tick rate.
2. Register input actions.
3. Bootstrap domain services and load `content/base`.
4. Create `ui_root`.
5. Call `_show_starter_screen()`.

Healthy startup prints:

```text
Puritato playable slice ready. Registered types: [...]
```

If startup prints only architecture bootstrap text, or if `_show_starter_screen()` is not called, the game may launch to an empty gray window. That was the cause of the May 16 gray-screen regression.

## Runtime Screens

The active screen is tracked by `screen` in `src/app/main.gd`.

- `starter`: starting equipment choice.
- `map`: route selection and reward nodes.
- `reward`: reward choice overlay.
- `shop`: shop choice overlay.
- `combat`: survivor-style combat.
- `defeat`: retry screen.
- `victory`: run clear screen.

`_clear_screen()` removes children from `ui_root` and clears transient combat arrays. New screens rebuild their UI from scratch.

## Scaling Model

The prototype uses a logical canvas:

```gdscript
const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)
```

`_update_ui_root_transform()` scales and centers `ui_root` inside the actual Godot viewport. Gameplay coordinates, click hotspots, reward nodes, and combat bounds all use logical 1280x720 coordinates. Do not place interactive UI directly under the scene root unless it also follows this scaling model.

## Current Gameplay Loop

1. Start at `starter`.
2. Pick one starting weapon by clicking its card/icon.
3. Enter `map`.
4. Click left or right route.
5. Reward nodes become interactable only on the selected route.
6. Claim all selected-route rewards.
7. Click the combat node.
8. Survive the mob phase.
9. Fight the boss.
10. On boss defeat, advance to the next map area.

Route data comes from `content/base/maps/demo_map.json` through `MapFlow`.

## Equipment Rules

`RunContext` currently has:

```gdscript
equipped_weapons.resize(4)
equipped_magics.resize(4)
```

Important rule: weapons are capped at 4 equipped slots. `RunContext.add_weapon()` appends every acquired weapon to `inventory["weapons"]`, then `_auto_equip()` fills only empty equipment slots. Once the 4 slots are full, later weapons remain in inventory and should not affect combat until a backpack/equip UI is implemented.

`main.gd` also counts only equipped weapon slots through `_equipped_weapon_count()`.

## Combat Implementation

Combat is currently implemented in `main.gd`, not in `CombatRuntime`.

Main state:

- `player_pos`, `player_hp`, `player_mana`
- `enemies`
- `boss_enemy`
- `boss_projectiles`
- `combat_weapon_sprites`
- `magic_cooldowns`

Combat update order in `_update_combat(delta)`:

1. Update timers, mana, and movement.
2. Update automatic weapon attacks.
3. Process magic input.
4. Update magic cooldowns.
5. Spawn mobs or boss.
6. Update enemies.
7. Update boss ability.
8. Update boss projectiles.
9. Update visuals and HUD.

Collisions are simple shapes:

- Enemy contact uses distance checks against `ENEMY_TOUCH_RADIUS`.
- Player projectile/boss projectile contact uses circle distance checks.
- Combat bounds use `COMBAT_ARENA_RECT`.

No runtime collision is expected to match texture silhouettes.

## Player, Weapon, And Magic Controls

Movement:

- `WASD`
- Arrow keys

Magic slots:

- Slot 1: `Q`
- Slot 2: `E`
- Slot 3: `R`
- Slot 4: `F`

Weapons auto-target the nearest enemy and attack on a timer. The current fries weapon is represented by up to 4 floating weapon sprites around the player. Weapon visuals are capped to equipped weapon count, not inventory count.

## Boss Ability

The demo boss spawns after the mob phase.

Current boss special:

- Cooldown: 8 seconds.
- Telegraph/cast duration: roughly 0.65 seconds.
- Projectile count: 16.
- Shape: radial circle.
- Projectile damage: same as boss contact damage.
- Projectile art: `res://assets/art/source/magic_vfx/magic_vfx-2.png`.
- Cast warning art: `res://assets/art/source/enemy_pack_01/boss_pollution_source_warning/boss_pollution_source_warning-1.png`.

Implementation entry points:

- `_update_boss_ability(delta)`
- `_play_boss_cast_motion()`
- `_spawn_boss_radial_projectiles()`
- `_update_boss_projectiles(delta)`

## Animation Notes

The current runtime uses existing frame folders directly:

- Player idle: `assets/art/source/potato_hero_idle_handless/`
- Player walk: `assets/art/source/potato_hero_walk_handless/`
- Sprouting potato: `assets/art/source/sprouting_potato/`
- Mushroom spore: `assets/art/source/enemy_pack_01/mushroom_spore/`
- Bomb fruitling: `assets/art/source/enemy_pack_01/bomb_fruitling/`
- Boss: `assets/art/source/boss_pollution_source/`

Character and monster movement should use frame cycling and squash/stretch. Avoid rotating characters for idle motion; rotation made the sprites feel unstable.

## Asset Fallbacks

The current playable slice uses route backgrounds directly:

- `res://assets/art/map/backgrounds/chapter_1_route_background.png`
- `res://assets/art/map/backgrounds/chapter_2_route_background.png`

Some documented future screen assets are missing, including:

- `assets/art/screens/main_menu_background.png`
- `assets/art/map/arenas/chapter_1_arena.png`
- `assets/art/map/arenas/chapter_2_arena.png`

Do not assume those missing files are fatal. The restored prototype deliberately avoids depending on them at startup.

## Content Loading

Content is loaded by `ContentConfigLoader` into `ContentRegistry`.

Current registered content types on healthy startup:

- `school`
- `character`
- `weapon`
- `magic`
- `item`
- `buff`
- `monster`
- `boss`
- `map`
- `reward_table`
- `shop`
- `audio`
- `asset`

`scene_art` files exist in `content/base/scene_art`, but the current restored playable slice does not require a `scene_art` registry entry to start.

## Common Failure Modes

### Gray Screen On Startup

Likely cause: `src/app/main.gd` was replaced with the old architecture-only bootstrap.

Check:

```powershell
rg -n "playable slice ready|_show_starter_screen|LOGICAL_VIEWPORT_SIZE" src\app\main.gd
```

Expected:

- `LOGICAL_VIEWPORT_SIZE` exists.
- `_ready()` calls `_show_starter_screen()`.
- startup prints `Puritato playable slice ready`.

### Weapon Count Looks Wrong

Check whether UI/combat is counting inventory instead of equipped slots. Gameplay should use `_equipped_weapon_count()` and `run_context.equipped_weapons`, capped at 4.

### Fullscreen Clicks Are Offset

Check whether new UI was added outside `ui_root`. Anything interactive in the playable slice should be positioned in logical coordinates under `ui_root`.

### Missing Background Looks Like Gray Screen

Missing optional screen art should fall back to existing route backgrounds. Do not reintroduce a hard dependency on `assets/art/screens/main_menu_background.png` unless that file is committed.

## Validation Checklist

Before committing gameplay changes:

```powershell
git -c safe.directory=C:/Users/LYZ/Desktop/work/potato-game diff --check
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

Expected Godot output includes:

```text
Puritato playable slice ready.
```

Launching a visible window:

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

## Git Hygiene

The repository may contain many untracked Godot `.import` files after launching the editor or game. Do not commit them blindly. Prefer committing only the files directly required by the task.

If saving a known-good runtime state, commit at least:

- `src/app/main.gd`
- `src/domain/run/run_context.gd`
- any content or asset registry files that the runtime now requires

Use the known stable checkpoint `d6ea0ca` as a recovery reference.
