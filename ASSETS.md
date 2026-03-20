# Asset manifest — Moles (Worms-like)

All raster paths are **repo-relative**. Images are **PNG** with **RGBA**; unused canvas pixels are **transparent** (alpha = 0).

## DALL·E / resolution (for coders)

Sprites are authored on **large square boards** (**1024×1024** for world art), the same **order of magnitude** as typical **OpenAI DALL·E 3** square exports (~1024 px). **Always scale at draw time** with `love.graphics.draw(image, x, y, rotation, sx, sy, ox, oy)` (or your camera’s world scale) — do **not** assume 1 texture pixel = 1 world unit.

**DALL·E caveat:** Real DALL·E outputs are often **fully opaque**; these shipped PNGs already use **alpha**. If you **replace** any file with MCP-generated art, plan to **chroma-key, trim**, or edit alpha as needed.

## `generate_sprite` MCP (pipeline)

The **`generate_sprite` MCP** tool is **not exposed to this agent runtime**, so **DALL·E 3 could not be invoked** here. Current files come from **`node tools/gen_sprites.mjs`** (reproducible pixel-style grids, palette aligned to `src/config.defaults.lua` **team1 / team2** hues). When MCP is available, regenerate into the **same paths** listed below.

---

## Table — file → `app.assets` key → use → scale

`app.assets` keys are set in **`src/app.lua`** (`love.graphics.newImage`).

| Path | `app.assets` key | Intended use | Suggested scale (design target ~32–48 px moles) | **As implemented** (reference) |
|------|------------------|--------------|-----------------------------------------------|------------------------------|
| `assets/sprites/mole_team_a_idle.png` | `mole_a_idle` | P1 / **Team A** — idle | `sx, sy` ≈ **0.05–0.07** | **`SPR_SCALE` 0.058** in `src/render/mole_draw.lua` (`sx` × **facing**) |
| `assets/sprites/mole_team_b_idle.png` | `mole_b_idle` | P2 / **Team B** — idle | same | same |
| `assets/sprites/mole_team_a_aim.png` | `mole_a_aim` | Team A — aim overlay (rotated with aim) | same | **0.95 ×** mole scale, rotated `aim_angle + π/2` |
| `assets/sprites/mole_team_b_aim.png` | `mole_b_aim` | Team B — aim overlay | same | same |
| `assets/sprites/mole_team_a_walk_1.png` | `mole_a_walk_1` | Team A — walk frame 1 | same | alternates with `_walk_2` when `|vx| > 12` |
| `assets/sprites/mole_team_a_walk_2.png` | `mole_a_walk_2` | Team A — walk frame 2 | same | same |
| `assets/sprites/mole_team_b_walk_1.png` | `mole_b_walk_1` | Team B — walk frame 1 | same | same |
| `assets/sprites/mole_team_b_walk_2.png` | `mole_b_walk_2` | Team B — walk frame 2 | same | same |
| `assets/sprites/rocket.png` | `rocket` | In-world **rocket** | **0.04–0.08** | **0.065**, origin center (`mole_draw.lua`) |
| `assets/sprites/grenade.png` | `grenade` | In-world **grenade** | **0.05–0.09** | **0.068 × fuse pulse**, origin center |
| `assets/sprites/ui_icon_rocket.png` | `ui_icon_rocket` | HUD weapon column — rocket | **0.35–0.55** of 128 px art → ~45–70 px | **`0.42`** in `src/ui/hud.lua` (`draw_weapon_panel`) |
| `assets/sprites/ui_icon_grenade.png` | `ui_icon_grenade` | HUD — grenade | same | **`0.42`** |
| `assets/sprites/ui_icon_wind.png` | `ui_icon_wind` | Wind panel icon | same | **`0.42`** at `(952, 132)` in `draw_wind_timer` |

**Mole anchor:** `ox = width×0.5`, `oy = height×0.85` — feet near **`m.x, m.y`** (see `mole_draw.lua`).

---

## Gaps / optional follow-ups

- **`assets/audio/*`**, **`assets/fonts/*`**, title **logo / background** art, **explosion** sheets, mole **hurt / death** frames — not shipped; SFX are procedural (`src/audio/sfx.lua`).
- **Terrain** is **runtime mask / proc gen** — no `terrain_tileset.png` in v1.

---

## Requirements touchpoints

- **R1**: Readable **pixel** identity, team accents, distinct weapons.
- **R2 / R3**: Rocket + grenade **world** sprites and **HUD** icons.
- **R6**: No art.
- **R10 / R11**: HUD icons support **shared KB+M** and **gamepad** play clarity.
