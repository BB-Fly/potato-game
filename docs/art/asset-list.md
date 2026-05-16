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
- Combat character rig: the potato body can be handless in combat. Use small round floating hands / weapon sockets around the potato to hold equipped weapons; weapon attacks animate the floating hand, weapon sprite, projectile, hit area, and VFX instead of requiring a body attack animation.
- Concept-art boundary: portraits, concept sheets, story art, and marketing-style illustrations may still show the potato hero with hands. Runtime combat sprites should treat those hands as reference-only and keep the body silhouette simple.
- Route map direction: route selection art should use an original vertical rail/track-board composition inspired by roguelike route maps: player entrance at the bottom, two readable branching lanes, reward pads on both sides of each lane, one shared combat gate at the top, and visual room for camera scrolling between floors.
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
| `character.potato_hero.sprite` | combat body idle sheet | `res://assets/art/sprites/characters/potato_hero.png` | runtime 2x2 handless potato body idle sheet; combat body should not need weapon attack frames |
| `character.potato_hero.walk_sprite` | combat walk sprite | `res://assets/art/sprites/characters/potato_hero_walk.png` | runtime 4x4 handless potato body walk sheet |
| `concept.character.potato_hero.attack_fries` | concept/reference body attack sheet | `res://assets/art/sprites/characters/potato_hero_attack_fries.png` | legacy concept reference only; do not use for runtime weapon attacks |

### Monster And Boss

Current config: `content/base/monsters/sprouting_potato.json`, `content/base/bosses/demo_pollution_source.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `monster.sprouting_potato.sprite` | mob sprite | `res://assets/art/sprites/monsters/sprouting_potato.png` | referenced by config and asset registry |
| `monster.mushroom_spore.sprite` | mob sprite | `res://assets/art/sprites/monsters/mushroom_spore.png` | generated in `enemy_pack_01`, not yet referenced in config |
| `monster.mushroom_spore.icon` | mob icon | `res://assets/art/icons/monster_mushroom_spore.png` | generated in `enemy_pack_01`, not yet referenced in config |
| `monster.bomb_fruitling.sprite` | mob sprite | `res://assets/art/sprites/monsters/bomb_fruitling.png` | generated in `enemy_pack_01`, not yet referenced in config |
| `monster.bomb_fruitling.icon` | mob icon | `res://assets/art/icons/monster_bomb_fruitling.png` | generated in `enemy_pack_01`, not yet referenced in config |
| `boss.demo_pollution_source.sprite` | boss sprite | `res://assets/art/sprites/bosses/demo_pollution_source.png` | needed, not yet referenced in config |
| `boss.demo_pollution_source.icon` | map / boss warning icon | `res://assets/art/icons/boss_demo_pollution_source.png` | needed, not yet referenced in config |
| `boss.pollution_source.warning_icon` | boss warning portrait | `res://assets/art/icons/boss_pollution_source_warning.png` | generated in `enemy_pack_01`, not yet referenced in config |

### Weapon

Current config: `content/base/weapons/fries.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `weapon.fries.icon` | inventory/shop icon | `res://assets/art/icons/weapon_fries.png` | referenced by config and asset registry |
| `weapon.fries.sprite` | held / socket-mounted staff sprite | `res://assets/art/sprites/weapons/fries.png` | referenced by config and asset registry; a single oversized french-fry cudgel/staff, animates with floating hand/socket |
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

### Screen Backgrounds

Current target config: `content/base/scene_art/screen_scene_art.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `screen.main_menu.background` | main menu full-screen backdrop | `res://assets/art/screens/main_menu_background.png` | planned for this art pass; image file not generated here |
| `screen.settings.background` | settings/options full-screen backdrop | `res://assets/art/screens/settings_background.png` | planned for this art pass; image file not generated here |

### Map Scene Backgrounds

Current target config: `content/base/scene_art/screen_scene_art.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `map.chapter_1_route.background` | chapter 1 vertical route-select backdrop | `res://assets/art/map/backgrounds/chapter_1_route_background.png` | runtime backdrop; should show bottom entrance, two lanes, side reward pads, shared combat gate |
| `map.chapter_2_route.background` | chapter 2 vertical route-select backdrop | `res://assets/art/map/backgrounds/chapter_2_route_background.png` | runtime backdrop; same layout language with chapter 2 biome variation |
| `arena.chapter_1.background` | chapter 1 combat arena backdrop | `res://assets/art/map/arenas/chapter_1_arena.png` | planned for this art pass; image file not generated here |
| `arena.chapter_2.background` | chapter 2 combat arena backdrop | `res://assets/art/map/arenas/chapter_2_arena.png` | planned for this art pass; image file not generated here |

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
- Add a reusable combat hand/socket sprite or shader-tintable primitive if the first playable combat scene needs visible round hands. Keep it separate from the potato body sprite so weapon counts and positions can scale independently.
- Add encounter art when `encounter_pool.default` receives concrete encounter entries.
- Add background arena art per chapter and floor once combat scene sizing is known.
- Add pickup/drop icons if coins, rewards, or temporary combat drops become physical objects.
- Add rarity frames and card backgrounds after UI wireframes settle.
- Add animation breakdowns only after the runtime decides between spritesheets, atlases, or skeletal animation.

## UI Node Pack 01

Source pack: `assets/art/source/ui_node_pack_01/`

Generated as an original 3x4 clean pixel UI pack with built-in image generation, then processed with `generate2dsprite.py process`.

Runtime exports:

| Asset | Path |
| --- | --- |
| `node_elite_combat` | `assets/art/map/nodes/node_elite_combat.png` |
| `node_boss` | `assets/art/map/nodes/node_boss.png` |
| `node_rest` | `assets/art/map/nodes/node_rest.png` |
| `node_locked` | `assets/art/map/nodes/node_locked.png` |
| `node_selected_marker` | `assets/art/map/nodes/node_selected_marker.png` |
| `node_route_arrow` | `assets/art/map/nodes/node_route_arrow.png` |
| `card_common_frame` | `assets/art/ui/card_common_frame.png`, `assets/art/icons/ui_card_common_frame.png` |
| `card_rare_frame` | `assets/art/ui/card_rare_frame.png`, `assets/art/icons/ui_card_rare_frame.png` |
| `card_legendary_frame` | `assets/art/ui/card_legendary_frame.png`, `assets/art/icons/ui_card_legendary_frame.png` |
| `panel_wood_small` | `assets/art/ui/panel_wood_small.png`, `assets/art/icons/ui_panel_wood_small.png` |
| `panel_wood_wide` | `assets/art/ui/panel_wood_wide.png`, `assets/art/icons/ui_panel_wood_wide.png` |
| `cursor_select` | `assets/art/ui/cursor_select.png`, `assets/art/icons/ui_cursor_select.png` |

QC: final processed source uses `component_mode=largest`, `threshold=180`, `edge_threshold=220`, `fit_scale=0.88`, `shared_scale=true`; `edge_touch_frames` is empty in `assets/art/source/ui_node_pack_01/pipeline-meta/pipeline-meta.json`.

## Potato Hero Combat Body Redesign

Runtime source folders:

- `assets/art/source/potato_hero_idle_handless/`
- `assets/art/source/potato_hero_walk_handless/`

The combat runtime potato body is handless. It keeps the readable potato shape, green sprout, green scarf/sash, determined face, and small feet, while weapon handling is delegated to floating hand/socket presentation. Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `character.potato_hero.sprite` | `assets/art/sprites/characters/potato_hero.png` | 256 px 2x2 idle sheet |
| `character.potato_hero.walk_sprite` | `assets/art/sprites/characters/potato_hero_walk.png` | 384 px 4x4 directional walk sheet |

## Reward Icon Pack 01

Generated source: `assets/art/source/reward_icon_pack_01/`

Runtime icon outputs:

| Asset ID | Suggested path | Notes |
| --- | --- | --- |
| `item.battle_bamboo.icon` | `res://assets/art/icons/item_battle_bamboo.png` | 64 px transparent item icon |
| `item.alchemy_flower.icon` | `res://assets/art/icons/item_alchemy_flower.png` | 64 px transparent item icon |
| `item.assassin_garlic.icon` | `res://assets/art/icons/item_assassin_garlic.png` | 64 px transparent item icon |
| `item.thorn_potato_charm.icon` | `res://assets/art/icons/item_thorn_potato_charm.png` | 64 px transparent item icon |
| `buff.poison.icon` | `res://assets/art/icons/buff_poison.png` | 64 px transparent buff icon |
| `buff.burning.icon` | `res://assets/art/icons/buff_burning.png` | 64 px transparent buff icon |
| `buff.shield.icon` | `res://assets/art/icons/buff_shield.png` | 64 px transparent buff icon |
| `buff.haste.icon` | `res://assets/art/icons/buff_haste.png` | 64 px transparent buff icon |
| `buff.healing_sprout.icon` | `res://assets/art/icons/buff_healing_sprout.png` | 64 px transparent buff icon |
| `buff.frost.icon` | `res://assets/art/icons/buff_frost.png` | 64 px transparent buff icon |
| `reward.legendary_choice.icon` | `res://assets/art/icons/reward_legendary_choice.png` | also copied to `assets/art/ui/reward_legendary_choice.png` |
| `reward.gold_bonus.icon` | `res://assets/art/icons/reward_gold_bonus.png` | also copied to `assets/art/ui/reward_gold_bonus.png` |
| `reward.free_fusion.icon` | `res://assets/art/icons/reward_free_fusion.png` | also copied to `assets/art/ui/reward_free_fusion.png` |
| `reward.free_upgrade.icon` | `res://assets/art/icons/reward_free_upgrade.png` | also copied to `assets/art/ui/reward_free_upgrade.png` |
| `reward.reroll.icon` | `res://assets/art/icons/reward_reroll.png` | also copied to `assets/art/ui/reward_reroll.png` |
| `reward.luck_clover.icon` | `res://assets/art/icons/reward_luck_clover.png` | also copied to `assets/art/ui/reward_luck_clover.png` |

QC: processed through `generate2dsprite.py process` from built-in `image_gen` raw art. Script metadata reports source-cell `edge_touch_frames` at `[1,1]`, `[1,2]`, `[1,3]`, `[2,3]`, `[3,2]`, and `[3,3]` using a 2 px source margin. Final 64 px transparent icon files have no non-transparent edge pixels and remain usable for item, buff, and reward UI.

## Fries Staff Redesign

Source folder: `assets/art/source/fries_staff/`

The fries weapon is a staff/cudgel weapon with the silhouette of a single oversized french fry, closer in combat role to a magical monkey-king staff than to a blade or bundle of fries. Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `weapon.fries.sprite` | `assets/art/sprites/weapons/fries.png` | 96 px transparent held staff sprite |
| `weapon.fries.icon` | `assets/art/icons/weapon_fries.png` | 96 px transparent inventory/shop icon |

Design note: keep future fries weapon art as one long golden potato staff with toasted ridges and optional small metal bands; avoid fan-shaped fry bundles, swords, or cutting blades.
