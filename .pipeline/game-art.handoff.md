# Stage: game-art (game-art)

## Summary

Reading design docs, handoffs, and code that references assets to align the art pass. Checking whether `generate_sprite` is available.




Checking how assets are loaded so ASSETS.md matches the implementation. `generate_sprite` isn't available in this session.




Confirming `generate_sprite` isn't in our tool set. Updating `ASSETS.md` to align with shipped code (`app.lua` paths, `mole_draw.lua` / `hud.lua` scales) and refreshing the game-art handoff.









Here’s the status of this **game-art** pass.

## Read / verified

- **`DESIGN.md`** (including shipped **`assetStructure`** and references to **`ASSETS.md`** / `mole_draw` / `hud`).
- **`REQUIREMENTS.md`** (R1–R11).
- **`.pipeline/game-art.handoff.md`** and **`lua-coding.handoff.md`** for what’s implemented.
- **`src/app.lua`** image paths and keys, **`src/render/mole_draw.lua`** scales, **`src/ui/hud.lua`** icon/wind draw.

## `generate_sprite` MCP

This environment still **does not expose** a `generate_sprite` tool, so **DALL·E 3 could not be called** and **no new PNGs** were produced. Existing sprites under **`assets/sprites/`** are unchanged (still from **`tools/gen_sprites.mjs`** unless you replace them locally).

## What changed

1. **`ASSETS.md`** — Reworked manifest:
   - Explicit **~1024 px / DALL·E-style** scaling note and **opaque vs alpha** warning for future MCP art.
   - **MCP unavailable** + **`gen_sprites.mjs`** regeneration note.
   - Table columns: **path → `app.assets` key → use → suggested scale → shipped scale** (from **`mole_draw.lua`** / **`hud.lua`**).
   - Mole **origin** (feet at `m.x, m.y`) called out.

2. **`.pipeline/game-art.handoff.md`** — Short, clean handoff for this run (no long transcript).

No edits to **`main.lua`**, **`conf.lua`**, or other gameplay Lua.

When **`generate_sprite`** is wired in Cursor, re-run it for each **`assets/sprites/*.png`** path with consistent **pixel-art, limited-palette** prompts, then adjust **`SPR_SCALE` / HUD `0.42`** if the new silhouettes read differently.

## Files Created/Modified
- ASSETS.md
