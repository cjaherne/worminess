# Stage: game-art (game-art)

## Summary

Reading design docs and pipeline handoffs, then checking how we can generate sprites (MCP or workspace scripts).









Checking for Python/Pillow to produce sprites: `generate_sprite` isn't in our available tools.









Implementing a small Node.js PNG generator (no extra npm deps) using zlib, since `generate_sprite` isn't available and Python isn't installed.




Fixing the sprite generator: correcting mole grid logic and removing conflicting palette keys.
























Writing `ASSETS.md` and `.pipeline/game-art.handoff.md`. Documenting that the `generate_sprite` MCP wasn't available; sprites were generated procedurally at 1024×1024 to match the expected coder workflow.




Here’s what was done for the **game-art** pass.

## Context read

- **`DESIGN.md`**: Worms-like moles, teams A/B with **accent colors**, idle/walk/aim, rocket vs grenade, HUD weapon/wind areas (`1280×720`, ~**32–48 px** mole height).
- **`REQUIREMENTS.md`**: R1–R11 (presentation + weapons + HUD support).
- **`.pipeline/*.handoff.md`**: Designer turn-model notes, architect/UX doc alignment — no extra sprite paths beyond the merged design.

## `generate_sprite` MCP

That tool **is not exposed in this agent’s tool set**, so DALL·E 3 could not be called here. **`ASSETS.md`** states this and records a **fallback**: reproducible **1024×1024** (world) / **128×128** (HUD icons) PNGs from **`node tools/gen_sprites.mjs`**, using a **limited palette** and **`config.defaults` team hues** (cyan / coral). You can **drop in** MCP-generated files at the **same paths** when the MCP is available.

## Deliverables

| Output | Role |
|--------|------|
| **`assets/sprites/`** | 13 PNGs: mole **idle / aim / walk×2** × teams A & B, **rocket**, **grenade**, **ui_icon_rocket**, **ui_icon_grenade**, **ui_icon_wind** |
| **`ASSETS.md`** | Manifest: path → use → **suggested `love.graphics.draw` scale**, **1024-style** sizing note, **alpha** (no chroma-key for these files), gaps |
| **`tools/gen_sprites.mjs`** | Regenerate sprites after editing ASCII grids (Node only, no npm) |
| **`.pipeline/game-art.handoff.md`** | Short handoff for the pipeline |

No changes to **`main.lua`**, **`conf.lua`**, or gameplay Lua.

**Canonical list for the coder:** root **`ASSETS.md`**.

## Files Created/Modified
- (none)

## Shell Commands Run
- `python --version 2>&1; pip show Pillow 2>&1`
- `node --version 2>&1; where.exe magick 2>&1`
- `node "C:\Users\Chris\Documents\GitHub\worminess\tools\gen_sprites.mjs"`
- `Get-ChildItem -Recurse "C:\Users\Chris\Documents\GitHub\worminess\assets" | Select-Object FullName, Length`
- `dir "C:\Users\Chris\Documents\GitHub\worminess\assets\sprites"`
