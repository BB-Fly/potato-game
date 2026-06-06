# Approved Rubberhose Art Direction V01

This folder keeps the accepted reference assets for the potato game art style.
Other generated drafts are temporary and can be removed.

## Accepted Assets

- `boss_potato_pump.png`
  - Accepted as the boss style reference.
  - Good points: clear silhouette, bold black outlines, bright cel colors, readable machinery parts, theatrical cartoon expression.
- `enemy_potato_flower.png`
  - Accepted as the small monster / map plant enemy reference.
  - Good points: simple hand-drawn shape, friendly but creature-like expression, readable leaf and flower parts, strong color contrast.
- `buff_sprouting_vigor_icon.png`
  - Accepted as the buff icon reference.
  - Good points: strong circular icon composition, readable at small size, simple symbol language, bright game UI feeling.
- `shop_fries_stand_reference.png`
  - Accepted as the shop visual reference.
  - Note: good as a final look reference, but it is not layer-separated. Future shop production should split it into background, main booth body, foreground counter, shopkeeper, hanging sign, and item props.
- `hero_body_reference_red_nose.png`
  - Accepted only as a rough hero direction reference.
  - Required next change: remove the red nose, give the face a slight grin, and push the expression toward a confident "wandering hero / daxia" feel.

## Core Style

Use a bright hand-drawn vintage rubber-hose cartoon style inspired by Cuphead-like plant enemies and projectiles:

- Thick black ink outlines with clean readable silhouettes.
- Rounded cartoon forms, not realistic anatomy.
- Bright cel colors with a small amount of soft vintage shading.
- Medium detail: richer than a flat icon, simpler than a concept-art illustration.
- Slight hand-drawn ink and paper feel.
- Expressive faces and theatrical poses.
- Warm off-white review background or flat chroma-key background when transparency is needed.

Avoid:

- Realistic rendering.
- 3D or plastic toy rendering.
- Dark fantasy, horror, western RPG armor, ornate fantasy weapons.
- Gritty textures or cinematic lighting.
- Overly minimal icon style.
- Overly detailed AI concept-art look.
- Anime mascot proportions.

## Reusable Shared Prompt

```text
Bright hand-drawn vintage rubber-hose cartoon game art, thick black ink outline,
flat cel colors with light vintage shading, rounded readable silhouette, playful
theatrical expression, medium detail, subtle paper and ink texture, isolated 2D
game asset on a warm off-white review background. Similar in spirit to cartoon
plant enemies and projectiles. No realistic rendering, no 3D, no dark fantasy,
no western RPG look, no gritty texture, no cinematic lighting, no glossy AI
concept-art look, no complex background.
```

## Accepted Prompt Seeds

### Boss

```text
Design an original cartoon boss for a potato-themed casual roguelike. The boss
is a squat grumpy potato pump creature: round potato body, big simple angry
eyes, tiny rubber-hose arms with white gloves, two small boots, one simple metal
sprayer nozzle on the side, a valve or pump detail on top, and several small
green poison bubbles. It should look funny and theatrical, not scary.

Use bright hand-drawn vintage rubber-hose cartoon game art, thick black ink
outline, flat cel colors with light vintage shading, rounded readable silhouette,
medium detail, subtle paper and ink texture, isolated on a warm off-white review
background.
```

### Small Monster / Plant Enemy

```text
Design an original cartoon plant enemy for a potato-themed casual roguelike.
A small potato-flower creature with a purple tulip-like flower head, cheerful
expressive face, two large green leaves, a potato bulb at the base, and little
root feet. It should feel like a playful cartoon enemy or map creature, not a
real plant illustration.

Use bright hand-drawn vintage rubber-hose cartoon game art, thick black ink
outline, flat cel colors with light vintage shading, rounded readable silhouette,
medium detail, subtle paper and ink texture, isolated on a warm off-white review
background.
```

### Buff Icon

```text
Design an original cartoon buff icon for a potato-themed casual roguelike. The
icon shows a smiling potato charm with two green leaves, a bold circular black
border, a turquoise speed/healing swirl, a plus symbol, and a small sparkle.
It must be bold, simple, and readable at small size.

Use bright hand-drawn vintage rubber-hose cartoon game art, thick black ink
outline, flat cel colors, rounded readable icon composition, medium-low detail,
subtle paper and ink texture, isolated on a warm off-white review background.
```

### Shop Reference

```text
Design an original cartoon fries shop map asset for a potato-themed casual
roguelike. A small wooden fries stand with a red-and-cream striped awning,
rounded wooden beams, a hanging potato sign, a potato shopkeeper in a chef hat,
jars on the counter, and a basket full of fries. It should feel like a charming
rubber-hose cartoon food booth, not a medieval fantasy shop.

Use bright hand-drawn vintage rubber-hose cartoon game art, thick black ink
outline, flat cel colors with light vintage shading, rounded readable silhouette,
medium detail, subtle paper and ink texture, isolated on a warm off-white review
background.
```

Future production note: generate this shop as separate layer assets:

- rear background panel / dark interior
- main booth body and awning
- foreground counter
- shopkeeper
- hanging potato sign
- jars / fries basket / small props

### Hero Next-Pass Prompt

```text
Create a 2D game sprite body layer for the potato protagonist. Use the accepted
hero reference as the base direction: a rounded potato body, thick black outline,
warm potato colors, small sprout, potato spots, simple feet, and a confident
cartoon face. Remove the red nose completely. Change the mouth into a slight
grin, with a calm confident wandering-hero / daxia expression. Keep the character
body-only: no arms, no hands, no weapon, because four floating hand sprites will
be animated separately.

Bright hand-drawn vintage rubber-hose cartoon game art, thick black ink outline,
flat cel colors with light vintage shading, rounded readable silhouette, medium
detail, subtle paper and ink texture. Avoid cute mascot exaggeration, grotesque
features, big red nose, anime face, realistic rendering, 3D, dark fantasy,
western RPG, and glossy AI concept-art look.
```

## Production Notes

- For final game assets, prefer transparent PNGs after style approval.
- For concept selection, warm off-white backgrounds are acceptable and often
  preserve color better than chroma-key removal.
- Keep sprite silhouettes simple enough for animation, but do not remove all
  hand-drawn line detail.
- Separate animated parts early: hero body, floating hands, weapons, shop layers,
  boss attachments, projectiles, and VFX.
