# Stage: game-art

## Summary

- Re-read **`DESIGN.md`**, **`REQUIREMENTS.md`**, and pipeline handoffs (**game-designer**, **love-architect**, **love-ux**, **lua-coding**). Shipped **`assetStructure`** matches root **`DESIGN.md`** §assetStructure + **`src/app.lua`** loaders.
- **`generate_sprite` (DALL·E 3) MCP** is **not available** in this agent session — **no new raster generation** via MCP; existing **`assets/sprites/*.png`** + **`tools/gen_sprites.mjs`** remain the source.
- Updated root **`ASSETS.md`**: full path list, **`app.assets` keys**, intended use, **DALL·E ~1024 px** scaling note, transparency vs opaque MCP exports, and a column for **as-implemented** `love.graphics.draw` scales (`mole_draw.lua`, `hud.lua`).

## Files touched (this run)

- `ASSETS.md`
- `.pipeline/game-art.handoff.md`

## Coder pointers

- Replace PNGs in place when MCP is enabled; keep **`app.lua`** paths or update loaders to match.
- Tuning draw size: **`SPR_SCALE`** (`mole_draw.lua`), projectile constants in **`draw_projectiles`**, HUD **`0.42`** icon scale (`hud.lua`).
