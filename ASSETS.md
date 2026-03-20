# Asset manifest — Moles (Worms-like)

All raster paths are **repo-relative**. Images are **PNG** with **RGBA** where noted; empty regions are **fully transparent** (alpha = 0).

## Resolution note (scaling in LÖVE)

- **World sprites** (`mole_*`, `rocket.png`, `grenade.png`) are **1024×1024** canvases with the subject centered and large. This matches the **nominal “full artboard” size** you would get from typical **DALL·E 3** square outputs (~1024 px). **Scale down** in-game with `love.graphics.draw(image, x, y, r, sx, sy, ...)` (or a camera/world scale) so on-screen moles land near the design target (**~32–48 px tall** in **1280×720** logical space per `DESIGN.md`).
- **HUD icons** are **128×128** for crisp UI at the UX wireframe sizes (~340×200 weapon panel); scale as needed (often **0.35–0.6** in logical px height ≈ **45–80 px**).

**Transparency:** These PNGs use **true alpha** on unused canvas area—**no chroma-key** required. If you replace any file with **DALL·E** exports, those are often **opaque**; trim or key the background as needed.

## Tooling note (this pipeline run)

The **`generate_sprite` MCP** (DALL·E 3) was **not available** in this agent session. Sprites were produced with **`node tools/gen_sprites.mjs`** (chunky **pixel-style** art, **limited palette**) aligned to `src/config.defaults.lua` **team colors** (team A ≈ cyan `colors.team1`, team B ≈ coral `colors.team2`). Re-run that script after editing grids in the tool file, or **swap in** MCP-generated PNGs at the **same paths** when the tool is enabled.

---

## Table — path → use → suggested scale

| Path | Intended use | Suggested draw scale (starting point) |
|------|----------------|--------------------------------------|
| `assets/sprites/mole_team_a_idle.png` | Player 1 / **Team A** mole — **idle** | `sx, sy` ≈ **0.05–0.07** for ~36–48 px tall on 720p logical |
| `assets/sprites/mole_team_b_idle.png` | Player 2 / **Team B** mole — **idle** | same as team A |
| `assets/sprites/mole_team_a_aim.png` | Team A — **aim / combat stance** (V1 same pose as idle; hook for future) | same |
| `assets/sprites/mole_team_b_aim.png` | Team B — **aim / combat stance** | same |
| `assets/sprites/mole_team_a_walk_1.png` | Team A — **walk** frame 1 | same; alternate with `_walk_2` for bob/cycle |
| `assets/sprites/mole_team_a_walk_2.png` | Team A — **walk** frame 2 | same |
| `assets/sprites/mole_team_b_walk_1.png` | Team B — **walk** frame 1 | same |
| `assets/sprites/mole_team_b_walk_2.png` | Team B — **walk** frame 2 | same |
| `assets/sprites/rocket.png` | **Rocket** projectile in-world; elongated orange/red body per `DESIGN.md` | **0.04–0.08** (small fast silhouette); tune to `weapon.rocket_radius` |
| `assets/sprites/grenade.png` | **Grenade** projectile; round, green shell, fuse pixel | **0.05–0.09**; pair with fuse VFX / shader |
| `assets/sprites/ui_icon_rocket.png` | **Weapon panel** — rocket **selected / unselected** icon (`DESIGN.md` §3.3) | **0.4–0.55** of icon height in logical px (~56–72 px tall) |
| `assets/sprites/ui_icon_grenade.png` | **Weapon panel** — grenade icon | same |
| `assets/sprites/ui_icon_wind.png` | **Wind readout** arrow / rose (`DESIGN.md` UX — wind Low/Med/High) | **0.35–0.5** |

---

## Gaps / optional follow-ups

- **Audio** (`assets/audio/*`), **fonts** (`assets/fonts/*`), **title background**, **explosion / particles**, **hurt / death** mole frames — not in this pass; coder may use primitives or add art later.
- **Terrain** is expected to be **procedural / mask** at runtime (`terrain_gen`); no `terrain_tileset.png` shipped unless you add one.

---

## Requirements touchpoints

- **R1** (presentation): Cohesive **pixel** look, **team-readable** accents, distinct **rocket vs grenade** reads.
- **R2 / R3**: Dedicated **rocket** and **grenade** sprites + **HUD icons**.
- **R6**: No art; session scores are data-only.
- **R10 / R11**: **Weapon** and **wind** icons support HUD clarity for shared KB+M and gamepad modes.
