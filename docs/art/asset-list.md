# Demo Art Asset List

This list is a production checklist for the current Demo content pack. It is based on `docs/architecture/game-architecture.md` and the active files under `content/base`, including `content/base/assets/base_assets.json`.

Scope for this pass:
- document required asset IDs and file conventions only;
- do not add placeholder art, generated images, or code-drawn fallbacks;
- keep gameplay/domain code untouched.

Current implementation note:
- this pass generated and installed the Demo-critical hand-drawn runtime art for the player, monsters, Demo Boss, fries weapon, comprehensive development magic VFX, item/buff/reward icons, map nodes, route backgrounds, shop/UI icons, music-state icons, and basic UI skin pieces;
- temporary source sheets, processed frames, GIF previews, prompts, QC metadata, style previews, and production candidates have been removed from the repo;
- runtime-ready PNGs are mapped through `content/base/assets/base_assets.json`.

## Style Constraints

- The detailed runtime style contract lives in `docs/art/style-guide.md`.
- Current visual direction: original hand-drawn cel-animation art with thick ink outlines, clean painted fills, light brush texture, and lively squash-and-stretch silhouettes.
- Inspiration boundary: references such as vintage rubber-hose animation, dark whimsical survival-game illustration, and compact survivor-like mascot design are mood/craft references only. Do not copy specific characters, UI frames, icon compositions, palettes, poses, or proportions from any source game.
- Potato theme: use playful vegetable, fried-food, garden, mushroom, crystal, and corruption motifs, but keep outlines, facial details, weapons, and effects unique to Puritato.
- Combat readability: player, mob, boss, weapon hit area, magic VFX, and pickups must stay distinguishable under motion and overlapping effects.
- Combat character rig: the potato body can be handless in combat. Use small feet, sprout, scarf, facial expression, floating hands, weapon sockets, weapon sprites, projectiles, hit areas, and VFX instead of complex humanoid body anatomy.
- Concept-art boundary: portraits, concept sheets, story art, and marketing-style illustrations may show richer anatomy. Runtime combat sprites should keep the body silhouette simple.
- Route map direction: route selection art should use original 3/4 top-down hand-painted board layouts with clear circular pads, readable branching paths, and decorative biome edges. Node icons remain separate transparent assets.
- UI readability: icons should remain legible at 32 px and 64 px. Prefer strong silhouettes over fine texture, and keep transparent interiors for frames/slots that hold content.

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

### Monster And Boss

Current config: `content/base/monsters/sprouting_potato.json`, `content/base/bosses/demo_pollution_source.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `monster.sprouting_potato.sprite` | mob sprite | `res://assets/art/sprites/monsters/sprouting_potato.png` | referenced by config and asset registry |
| `monster.mushroom_spore.sprite` | mob sprite | `res://assets/art/sprites/monsters/mushroom_spore.png` | referenced by config and asset registry |
| `monster.mushroom_spore.icon` | mob icon | `res://assets/art/icons/monster_mushroom_spore.png` | available for UI |
| `monster.bomb_fruitling.sprite` | mob sprite | `res://assets/art/sprites/monsters/bomb_fruitling.png` | referenced by config and asset registry |
| `monster.bomb_fruitling.icon` | mob icon | `res://assets/art/icons/monster_bomb_fruitling.png` | available for UI |
| `monster.bomb_fruitling.explosion_vfx` | mob death/contact VFX | `res://assets/art/vfx/bomb_fruitling_explosion.png` | referenced by config and asset registry |
| `monster.bomb_fruitling.fire_wheel_vfx` | mob run foot VFX | `res://assets/art/vfx/bomb_fruitling_fire_wheel.png` | independent layered fire-wheel run animation |
| `monster.bomb_fruitling.sleep_zzz_vfx` | mob sleep VFX | `res://assets/art/vfx/bomb_fruitling_sleep_zzz.png` | independent sleep ZZZ pop animation |
| `monster.bomb_fruitling.run_dust_vfx` | mob run VFX | `res://assets/art/vfx/bomb_fruitling_run_dust.png` | independent foot dust puff animation |
| `boss.demo_pollution_source.sprite` | boss sprite | `res://assets/art/sprites/bosses/demo_pollution_source.png` | referenced by config and asset registry |
| `boss.demo_pollution_source.icon` | map / boss warning icon | `res://assets/art/icons/boss_demo_pollution_source.png` | referenced by config and asset registry |
| `boss.demo_pollution_source.warning_icon` | boss warning portrait | `res://assets/art/icons/boss_pollution_source_warning.png` | referenced by combat scene through asset registry |

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
| `buff.burning.icon` | status icon | `res://assets/art/icons/buff_burning.png` | reused by `buff.fuse_lit` |
| `buff.comprehensive_development.icon` | status icon | `res://assets/art/icons/buff_comprehensive_development.png` | needed for status UI |
| `buff.potato_enhancement.icon` | status icon | `res://assets/art/icons/buff_potato_enhancement.png` | needed for status UI |

### Map Nodes

Current editable layout: `scenes/route_map_scene.tscn`

Map progression seed data still exists in `content/base/maps/demo_map.json`, but node placement and route-node logic for the playable slice are edited in the route map scene.

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

Dedicated screen backgrounds are not registered in the current runtime set. The demo config temporarily falls back to the chapter route backgrounds until final screen art is promoted.

### Map Scene Backgrounds

Current target config: `content/base/scene_art/screen_scene_art.json`

| Asset ID | Type | Suggested path | Status |
| --- | --- | --- | --- |
| `map.chapter_1_route.background` | chapter 1 vertical route-select backdrop | `res://assets/art/map/backgrounds/chapter_1_route_background.png` | runtime backdrop; should show bottom entrance, two lanes, side reward pads, shared combat gate |
| `map.chapter_2_route.background` | chapter 2 vertical route-select backdrop | `res://assets/art/map/backgrounds/chapter_2_route_background.png` | runtime backdrop; same layout language with chapter 2 biome variation |

Dedicated combat arena backgrounds are not registered in the current runtime set. The demo config temporarily falls back to the matching chapter route background.

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

- Add a reusable combat hand/socket sprite or shader-tintable primitive if the first playable combat scene needs visible round hands. Keep it separate from the potato body sprite so weapon counts and positions can scale independently.
- Add encounter art when `encounter_pool.default` receives concrete encounter entries.
- Add background arena art per chapter and floor once combat scene sizing is known.
- Add pickup/drop icons if coins, rewards, or temporary combat drops become physical objects.
- Add rarity frames and card backgrounds after UI wireframes settle.
- Add animation breakdowns only after the runtime decides between spritesheets, atlases, or skeletal animation.

## Potato Hero Combat Body Redesign

The combat runtime potato body is handless. It keeps the readable potato shape, green sprout, green scarf/sash, determined face, and small feet, while weapon handling is delegated to floating hand/socket presentation. Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `character.potato_hero.sprite` | `assets/art/sprites/characters/potato_hero.png` | 256 px 2x2 idle sheet |
| `character.potato_hero.walk_sprite` | `assets/art/sprites/characters/potato_hero_walk.png` | 384 px 4x4 directional walk sheet |

## Reward Icon Pack 01

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

## Fries Staff Redesign

The fries weapon is a staff/cudgel weapon with the silhouette of a single oversized french fry, closer in combat role to a magical monkey-king staff than to a blade or bundle of fries. Runtime exports:

| Asset ID | Path | Notes |
| --- | --- | --- |
| `weapon.fries.sprite` | `assets/art/sprites/weapons/fries.png` | 96 px transparent held staff sprite |
| `weapon.fries.icon` | `assets/art/icons/weapon_fries.png` | 96 px transparent inventory/shop icon |

Design note: keep future fries weapon art as one long golden potato staff with toasted ridges and optional small metal bands; avoid fan-shaped fry bundles, swords, or cutting blades.
