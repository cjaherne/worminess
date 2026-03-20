# Stage: game-art (game-art)

## Summary

Read **DESIGN.md** (merged Moles + `config.defaults`; §7 HUD/polish, §9 `assets/sprites/*.png`), **REQUIREMENTS.md** (R1–R3 meta), **CODING_NOTES.md** / pipeline UX handoffs for presentation context. **`generate_sprite` MCP is not available** in this agent runtime — **no DALL·E generation**, **no PNG changes**. **`ASSETS.md`** refreshed: ~1024 px scaling note, palette table from **`src/config/defaults.lua`**, manifest table aligned with **`src/app.lua`** / **`mole_draw.lua`** / **`hud.lua`**.

## Outputs

- **ASSETS.md** — canonical path → use → scale table; MCP unavailable + **`gen_sprites.mjs`** fallback; transparency caveat for future DALL·E exports.
- **Sprites** — unchanged on disk.

## Next step (orchestrator)

Wire **`generate_sprite`** in Cursor and regenerate **`assets/sprites/*.png`** with shared pixel-art prompts (team A cyan / team B coral accents). Expect to tweak **`SPR_SCALE`** and HUD **`0.42`** after new silhouettes.

## Files modified

- ASSETS.md
- .pipeline/game-art.handoff.md
