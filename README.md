# Puritato

Puritato is a Godot 4 survivor roguelike prototype. The current checked-in build is a playable vertical slice: choose starting gear, pick a route, claim reward nodes, enter combat, survive mobs, and fight the demo boss.

## Current Playable Checkpoint

- Stable commit: `d6ea0ca Restore playable Godot prototype`
- Main scene: `res://scenes/main.tscn`
- Runtime entry script: `src/app/main.gd`
- Shared run state: `src/domain/run/run_context.gd`
- Base content: `content/base/`
- Runtime art: `assets/art/`

## Run Locally

Godot is installed locally at:

```text
C:\Program Files\Godot
```

Useful commands:

```powershell
& 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\LYZ\Desktop\work\potato-game' --quit
```

Expected healthy startup log:

```text
Puritato playable slice ready. Registered types: ["school", "character", "weapon", "magic", "item", "buff", "monster", "boss", "map", "reward_table", "shop", "audio", "asset"]
```

To launch the visible game window:

```powershell
Start-Process -FilePath 'C:\Program Files\Godot\Godot_v4.6.2-stable_mono_win64.exe' -ArgumentList @('--path','C:\Users\LYZ\Desktop\work\potato-game') -WindowStyle Normal
```

## Documentation Map

- `docs/gameplay-design/`: source gameplay rules and intended systems.
- `docs/architecture/game-architecture.md`: long-form target architecture.
- `docs/architecture/implementation-notes.md`: current prototype implementation notes and handoff guide.
- `docs/art/asset-list.md`: art asset registry, generated asset notes, and runtime asset conventions.

## Before Changing Runtime Code

1. Run Godot headless before and after edits.
2. Keep `src/app/main.gd` visibly creating UI from `_ready()`. If startup only prints architecture bootstrap text and creates no UI, the game will appear as a gray screen.
3. Do not auto-equip more than 4 weapons. Extra weapons belong in inventory until a backpack/equip UI exists.
4. Treat `.import` files produced by Godot as generated noise unless a specific import setting needs to be versioned.
