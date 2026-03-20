# Stage: game-art (game-art)

## Summary

Game-art pass: verified **`DESIGN.md`** / **`REQUIREMENTS.md`** (current DESIGN is **config.defaults** relocation; art context from **`CODING_NOTES.md`** and **`.pipeline/game-designer.handoff.md`**, **`.pipeline/love-ux.handoff.md`**). Confirmed **`src/app.lua`** load keys and **`mole_draw.lua`** / **`hud.lua`** draw scales. **`generate_sprite` MCP is not available** in this runtime — no new PNGs; **`assets/sprites/*.png`** remain **1024×1024** from **`tools/gen_sprites.mjs`**.

## Outputs

- **`ASSETS.md`** — manifest updated: resolution/scaling notes, DALL·E transparency caveat, config path note (**`src/config/defaults.lua`** per DESIGN vs possible legacy flat file), full path → key → use → scale table aligned with code.
- **Sprites** — unchanged (no MCP).

## Follow-up for orchestrator

When **`generate_sprite`** is wired, regenerate the same paths with shared **pixel-art** prompts (team A cool / team B warm accents, readable silhouettes). Expect to adjust **`SPR_SCALE`** / HUD **`0.42`** after art swap.

## Files Created/Modified

- ASSETS.md
- .pipeline/game-art.handoff.md
