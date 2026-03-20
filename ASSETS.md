# Asset manifest — Moles (Worms-like)

All raster paths are **repo-relative**. Images are **PNG** with **RGBA**; unused canvas pixels are **transparent** (alpha = 0).

## Resolution & scaling (for coders)

Shipped sprites are **1024×1024** PNGs (procedural pixel art centered on a large canvas in **`tools/gen_sprites.mjs`**, same **order of magnitude** as typical **OpenAI DALL·E 3** square exports). **Always scale at draw time** with `love.graphics.draw(image, x, y, rotation, sx, sy, ox, oy)` (or your camera’s world scale) — do **not** assume 1 texture pixel = 1 world unit.

**DALL·E / MCP caveat:** If you **replace** any file with **`generate_sprite`** output, exports are often **fully opaque**. Plan to **chroma-key, trim**, or fix alpha. Re-tune **`SPR_SCALE`** in **`src/render/mole_draw.lua`** and HUD icon scale in **`src/ui/hud.lua`** if silhouettes change.

## `generate_sprite` MCP (pipeline)

The **`generate_sprite` MCP** tool is **not exposed in this agent runtime**, so **DALL·E 3 was not invoked** this pass. Existing **`assets/sprites/*.png`** are unchanged. Regenerate with consistent **pixel-art, limited-palette** prompts (earth tones + **team1 / team2** accents from **`src/config/defaults.lua`**, loaded as **`require("config.defaults")`**).

---

## Table — path → description → suggested scale

| Path | `app.assets` key (`src/app.lua`) | Intended use | Suggested scale | **As implemented** |
|------|----------------------------------|--------------|-----------------|-------------------|
| `assets/sprites/mole_team_a_idle.png` | `mole_a_idle` | P1 / Team A — idle | `sx, sy` ≈ **0.05–0.07** (~32–48 px tall at 1024 source) | **`SPR_SCALE` 0.058** in `src/render/mole_draw.lua` |
| `assets/sprites/mole_team_b_idle.png` | `mole_b_idle` | P2 / Team B — idle | same | same |
| `assets/sprites/mole_team_a_aim.png` | `mole_a_aim` | Team A — aim (rotated with aim) | same | **0.95 ×** mole `sx`/`sy`, rotation `aim_angle + π/2` |
| `assets/sprites/mole_team_b_aim.png` | `mole_b_aim` | Team B — aim | same | same |
| `assets/sprites/mole_team_a_walk_1.png` | `mole_a_walk_1` | Team A — walk frame 1 | same | Toggled with `_walk_2` when `|vx| > 12` |
| `assets/sprites/mole_team_a_walk_2.png` | `mole_a_walk_2` | Team A — walk frame 2 | same | same |
| `assets/sprites/mole_team_b_walk_1.png` | `mole_b_walk_1` | Team B — walk frame 1 | same | same |
| `assets/sprites/mole_team_b_walk_2.png` | `mole_b_walk_2` | Team B — walk frame 2 | same | same |
| `assets/sprites/rocket.png` | `rocket` | In-world rocket | **0.04–0.08** | **0.065**, origin image center |
| `assets/sprites/grenade.png` | `grenade` | In-world grenade | **0.05–0.09** | **0.068 × fuse pulse**, origin center |
| `assets/sprites/ui_icon_rocket.png` | `ui_icon_rocket` | HUD weapon column — rocket | **~0.35–0.55** for ~45–70 px on-screen | **`0.42`** in `src/ui/hud.lua` (`draw_weapon_panel`) |
| `assets/sprites/ui_icon_grenade.png` | `ui_icon_grenade` | HUD — grenade | same | **`0.42`** |
| `assets/sprites/ui_icon_wind.png` | `ui_icon_wind` | Wind panel | same | **`0.42`** at `(952, 132)` in wind/timer block |

**Mole anchor:** `ox = width×0.5`, `oy = height×0.85` — feet near **`m.x, m.y`** (`mole_draw.lua`).

---

## Gaps / optional follow-ups

- **`assets/audio/*`**, **`assets/fonts/*`**, title logo / background, **explosion** sheets, mole **hurt / death** frames — not shipped; SFX are procedural (`src/audio/sfx.lua`).
- **Terrain** is runtime mask / proc gen — no `terrain_tileset.png` in v1.

---

## Requirements traceability

- **`REQUIREMENTS.md`** (R1–R3) for this pipeline slice covers **`config.defaults`** module resolution, not art.
- Gameplay / presentation expectations for sprites and HUD icons are summarized under **CODING_NOTES.md** (e.g. R1 presentation, R2/R3 weapons, R10/R11 input clarity).
