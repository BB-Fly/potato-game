# Demo Art Asset List

This list is a production checklist for the current Demo content pack. It is based on `docs/architecture/game-architecture.md` and the active files under `content/base`, including `content/base/assets/base_assets.json`.

Scope for this pass:
- document required asset IDs and file conventions only;
- do not add placeholder art, generated images, or code-drawn fallbacks;
- keep gameplay/domain code untouched.

Current implementation note:
- this pass generated and installed the Demo-critical pixel art for the player, first monster, Demo Boss, fries weapon, comprehensive development magic VFX, potato enhancement item, map nodes, shop/UI icons, and basic UI skin pieces;
- source sheets, processed frames, GIF previews, prompts, and QC metadata are kept under `assets/art/source/`;
- runtime-ready PNGs are mapped through `content/base/assets/base_assets.json`.

## Style Constraints

- Visual direction: top-down survivor arena readability, chunky silhouettes, clear rarity/status icon language, and fast recognition at small sizes.
- Inspiration boundary: may share the broad genre ergonomics of Brotato, but must be original. Do not copy its character shapes, enemy designs, UI frames, icon compositions, palettes, or exact proportions.
- Potato theme: use playful vegetable/fried-food motifs, but keep outlines, facial details, weapons, and effects unique to Puritato.
- Combat readability: player, mob, boss, weapon hit area, magic VFX, and pickups must stay distinguishable under motion and overlapping effects.
- UI readability: icons should remain legible at 32 px and 64 px. Prefer strong silhouettes over fine texture.

## Path Conventions

Runtime configs should continue to reference stable asset IDs such as `weapon.fries.icon`. Art packs resolve those IDs to files.

Current registry layout:

```text
assets/
  art/
    icons/<asset_name>.png
    sprites/weapons/<asset_name>.png
    sprites/monsters/<asset_name>.png
    vfx/<asset_name>.png
    map/nodes/<node-type>.png
    ui/{button_*.png,panel_*.png,currency_gold.png,slot_*.png}
    music_states/<music-state-id>.png
  audio/
    music/<track-ref>.wav
    sfx/<asset-id>.wav
```

Use lower snake/kebab segments for filenames. Keep the configured IDs stable even if files move. If a specialized folder is later introduced for characters, bosses, or buffs, update only the asset registry mapping and keep the IDs unchanged.

## Required IDs From Current Content

### Character

Current config: `content/base/characters/potato_hero.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `character.potato_hero.icon` | character select / HUD icon | `res://assets/art/icons/character_potato_hero.png` | needed, not yet referenced in config |
| `character.potato_hero.sprite` | player sprite / animation source | `res://assets/art/sprites/characters/potato_hero.png` | needed, not yet referenced in config |

### Monster And Boss

Current config: `content/base/monsters/sprouting_potato.json`, `content/base/bosses/demo_pollution_source.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `monster.sprouting_potato.sprite` | mob sprite | `res://assets/art/sprites/monsters/sprouting_potato.png` | referenced by config and asset registry |
| `boss.demo_pollution_source.sprite` | boss sprite | `res://assets/art/sprites/bosses/demo_pollution_source.png` | needed, not yet referenced in config |
| `boss.demo_pollution_source.icon` | map / boss warning icon | `res://assets/art/icons/boss_demo_pollution_source.png` | needed, not yet referenced in config |

### Weapon

Current config: `content/base/weapons/fries.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `weapon.fries.icon` | inventory/shop icon | `res://assets/art/icons/weapon_fries.png` | referenced by config and asset registry |
| `weapon.fries.sprite` | held / attack sprite | `res://assets/art/sprites/weapons/fries.png` | referenced by config and asset registry |
| `weapon_skill.heavy_fries_slam.icon` | active/charged skill icon | `res://assets/art/icons/weapon_skill_heavy_fries_slam.png` | needed for UI clarity |
| `weapon.fries.slash_vfx` | melee swing VFX | `res://assets/art/vfx/weapon_fries_slash.png` | needed for combat feedback |

### Magic

Current config: `content/base/magics/comprehensive_development.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `magic.comprehensive_development.icon` | magic slot/shop icon | `res://assets/art/icons/magic_comprehensive_development.png` | referenced by config and asset registry |
| `magic.comprehensive_development.vfx` | cast / buff VFX | `res://assets/art/vfx/comprehensive_development.png` | referenced by config and asset registry |

### Item And Buffs

Current config: `content/base/items/potato_enhancement.json`, `content/base/buffs/base_buffs.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `item.potato_enhancement.icon` | item/shop/reward icon | `res://assets/art/icons/item_potato_enhancement.png` | referenced by config and asset registry |
| `buff.bruise.icon` | status icon | `res://assets/art/icons/buff_bruise.png` | needed for status UI |
| `buff.stun.icon` | status icon | `res://assets/art/icons/buff_stun.png` | needed for status UI |
| `buff.comprehensive_development.icon` | status icon | `res://assets/art/icons/buff_comprehensive_development.png` | needed for status UI |
| `buff.potato_enhancement.icon` | status icon | `res://assets/art/icons/buff_potato_enhancement.png` | needed for status UI |

### Map Nodes

Current config: `content/base/maps/demo_map.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `map.node.free_weapon.icon` | map node icon | `res://assets/art/map/nodes/free_weapon.png` | needed |
| `map.node.random_item.icon` | map node icon | `res://assets/art/map/nodes/random_item.png` | needed |
| `map.node.combat.icon` | map node icon | `res://assets/art/map/nodes/combat.png` | needed |
| `map.node.weapon_shop.icon` | map node icon | `res://assets/art/map/nodes/weapon_shop.png` | needed |
| `map.node.magic_shop.icon` | map node icon | `res://assets/art/map/nodes/magic_shop.png` | needed |
| `map.node.item_shop.icon` | map node icon | `res://assets/art/map/nodes/item_shop.png` | needed |
| `map.node.weapon_master.icon` | map node icon | `res://assets/art/map/nodes/weapon_master.png` | needed |
| `map.node.magic_master.icon` | map node icon | `res://assets/art/map/nodes/magic_master.png` | needed |
| `map.node.coin.icon` | map node icon / reward | `res://assets/art/map/nodes/coin.png` | needed |
| `map.node.encounter.icon` | map node icon | `res://assets/art/map/nodes/encounter.png` | needed |

### Shops And UI

Current config: `content/base/shops/default_shops.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `shop.weapon.default.icon` | shop header/map detail icon | `res://assets/art/ui/shop_weapon.png` | needed |
| `shop.magic.default.icon` | shop header/map detail icon | `res://assets/art/ui/shop_magic.png` | needed |
| `shop.item.default.icon` | shop header/map detail icon | `res://assets/art/ui/shop_item.png` | needed |
| `shop.weapon_master.default.icon` | master shop icon | `res://assets/art/ui/shop_weapon_master.png` | needed |
| `shop.magic_master.default.icon` | master shop icon | `res://assets/art/ui/shop_magic_master.png` | needed |
| `ui.currency.gold.icon` | gold/currency icon | `res://assets/art/ui/currency_gold.png` | needed |
| `ui.slot.weapon.icon` | weapon slot marker | `res://assets/art/ui/slot_weapon.png` | needed |
| `ui.slot.magic.icon` | magic slot marker | `res://assets/art/ui/slot_magic.png` | needed |
| `ui.button.refresh.icon` | shop refresh/service icon | `res://assets/art/ui/button_refresh.png` | needed |
| `ui.button.upgrade.icon` | upgrade service icon | `res://assets/art/ui/button_upgrade.png` | needed |
| `ui.button.fusion.icon` | fusion service icon | `res://assets/art/ui/button_fusion.png` | needed |

### Music State Icons And Audio Refs

Current config: `content/base/audio/base_audio.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `music_state.menu.icon` | music/debug state icon | `res://assets/art/music_states/menu.png` | needed for debug/UI state display |
| `music_state.map.chapter_1.icon` | music/debug state icon | `res://assets/art/music_states/map_chapter_1.png` | needed for debug/UI state display |
| `music_state.combat.chapter_1.mob.icon` | music/debug state icon | `res://assets/art/music_states/combat_chapter_1_mob.png` | needed for debug/UI state display |
| `music_state.combat.boss.icon` | music/debug state icon | `res://assets/art/music_states/combat_boss.png` | needed for debug/UI state display |
| `music_state.victory.icon` | music/debug state icon | `res://assets/art/music_states/victory.png` | needed for debug/UI state display |
| `bgm.menu` | music track ref | `res://assets/audio/music/menu.wav` | referenced by config and asset registry |
| `bgm.chapter_1.map` | music track ref | `res://assets/audio/music/chapter_1_map.wav` | referenced by config and asset registry |
| `bgm.chapter_1.mob` | music track ref | `res://assets/audio/music/chapter_1_mob.wav` | referenced by config and asset registry |
| `bgm.boss.default` | music track ref | `res://assets/audio/music/boss_default.wav` | referenced by config and asset registry |
| `bgm.victory` | music track ref | `res://assets/audio/music/victory.wav` | referenced by config and asset registry |

### SFX Refs

Current config: weapon, magic, monster files under `content/base`.

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `weapon.fries.attack` | attack SFX | `res://assets/audio/sfx/weapon_fries_attack.wav` | referenced by config and asset registry |
| `weapon.fries.hit` | hit SFX | `res://assets/audio/sfx/weapon_fries_hit.wav` | referenced by config and asset registry |
| `magic.comprehensive_development.cast` | cast SFX | `res://assets/audio/sfx/magic_comprehensive_development_cast.wav` | referenced by config and asset registry |
| `monster.sprouting_potato.hit` | monster hit SFX | `res://assets/audio/sfx/monster_sprouting_potato_hit.wav` | referenced by config and asset registry |

## Later Asset Work

- Add explicit `asset_refs` for character and boss configs once the presentation resolver contract is finalized.
- Add encounter art when `encounter_pool.default` receives concrete encounter entries.
- Add background arena art per chapter and floor once combat scene sizing is known.
- Add pickup/drop icons if coins, rewards, or temporary combat drops become physical objects.
- Add rarity frames and card backgrounds after UI wireframes settle.
- Add animation breakdowns only after the runtime decides between spritesheets, atlases, or skeletal animation.
