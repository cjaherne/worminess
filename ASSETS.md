# Asset manifest — Moles (Worms-like)

All raster paths are **repo-relative**. Images are **PNG** with **RGBA**; unused canvas pixels are **transparent** (alpha = 0).

## Resolution & scaling (for coders)

Textures are authored on a **1024×1024** canvas (matches typical **DALL·E 3** square output and the **`tools/gen_sprites.mjs`** export size). **Scale at draw time** with `love.graphics.draw(image, x, y, rotation, sx, sy, ox, oy)` — do **not** assume 1 texture pixel = 1 world unit.

**DALL·E / MCP:** Raw model output is often **opaque**; chroma-key, trim, or fix alpha before shipping. After any art swap, re-check **`SPR_SCALE`** (`src/render/mole_draw.lua`) and HUD icon scale (`src/ui/hud.lua`).

## Palette cues (for regeneration)

Team tints in **`src/config/defaults.lua`** (`require("config.defaults")` → `colors`):

| Key | Normalized RGB | Role |
|-----|----------------|------|
| `team1` | ≈ (0.35, 0.75, 0.95) | P1 / Team A — cool cyan accent |
| `team2` | ≈ (0.95, 0.45, 0.35) | P2 / Team B — warm coral accent |
| `dirt` / `grass` / `sky_*` | see same file | World read against procedural terrain |

Use **limited palette pixel art**, **strong silhouette**, **readable at ~40 px tall** when scaled.

**Design context:** HUD / mole polish described in **DESIGN.md** §7; tree reference §9 lists **`assets/sprites/*.png`**.

## `generate_sprite` MCP (pipeline)

**This Cursor agent session does not expose a `generate_sprite` tool**, so **DALL·E 3 was not called** and **no PNGs were overwritten**. To regenerate: enable the MCP, then call **`generate_sprite`** for each path below with consistent pixel-art prompts keyed to the table above.

**Fallback:** `node tools/gen_sprites.mjs` rebuilds the same filenames procedurally.

---

## Table — path → description → suggested scale

| Path | `app.assets` key (`src/app.lua`) | Intended use | Suggested scale | **As implemented** |
|------|----------------------------------|--------------|-----------------|---------------------|
| `assets/sprites/mole_team_a_idle.png` | `mole_a_idle` | P1 / Team A — idle | `sx, sy` ≈ **0.05–0.07** | **`SPR_SCALE` 0.058** in `src/render/mole_draw.lua` |
| `assets/sprites/mole_team_b_idle.png` | `mole_b_idle` | P2 / Team B — idle | same | same |
| `assets/sprites/mole_team_a_aim.png` | `mole_a_aim` | Team A — aim overlay | same | **0.95 ×** mole scale, rot. `aim_angle + π/2` |
| `assets/sprites/mole_team_b_aim.png` | `mole_b_aim` | Team B — aim overlay | same | same |
| `assets/sprites/mole_team_a_walk_1.png` | `mole_a_walk_1` | Team A — walk frame 1 | same | Alternates with `_walk_2` when `|vx| > 12` |
| `assets/sprites/mole_team_a_walk_2.png` | `mole_a_walk_2` | Team A — walk frame 2 | same | same |
| `assets/sprites/mole_team_b_walk_1.png` | `mole_b_walk_1` | Team B — walk frame 1 | same | same |
| `assets/sprites/mole_team_b_walk_2.png` | `mole_b_walk_2` | Team B — walk frame 2 | same | same |
| `assets/sprites/rocket.png` | `rocket` | In-world rocket | **0.04–0.08** | **0.065**, origin center |
| `assets/sprites/grenade.png` | `grenade` | In-world grenade | **0.05–0.09** | **0.068 × fuse pulse**, origin center |
| `assets/sprites/ui_icon_rocket.png` | `ui_icon_rocket` | HUD — rocket weapon | **~0.35–0.55** → ~45–70 px | **`0.42`** in `src/ui/hud.lua` |
| `assets/sprites/ui_icon_grenade.png` | `ui_icon_grenade` | HUD — grenade | same | **`0.42`** |
| `assets/sprites/ui_icon_wind.png` | `ui_icon_wind` | HUD — wind | same | **`0.42`** at `(952, 132)` |

**Mole anchor:** `ox = width×0.5`, `oy = height×0.85` — feet at **`m.x, m.y`**.

---

## Gaps / optional follow-ups

- **`assets/audio/*`**, **`assets/fonts/*`**, title art, **explosion** sheets, mole **hurt / death** — not shipped; SFX procedural (`src/audio/sfx.lua`).
- **Terrain** — proc mask only; no tileset in v1.

---

## Requirements traceability

- **`REQUIREMENTS.md`** R1–R3: **`config.defaults`** build slice — not art-specific.
- Product presentation / weapons / HUD: **DESIGN.md** §7, **CODING_NOTES.md** (R1–R11 narrative).
