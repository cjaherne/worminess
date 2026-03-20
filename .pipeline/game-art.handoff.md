# Stage: game-art (game-art)

## Summary

Running the game-art pass: reading design docs, handoffs, and the asset manifest, then checking for the `generate_sprite` MCP tool.














Confirming `generate_sprite` isn't in our available tools — we can't invoke DALL·E. Refreshing `ASSETS.md` to match the merged DESIGN (§7, §9) and palette from `src/config/defaults.lua`, and replacing the bloated `.pipeline/game-art.handoff.md` with a concise handoff.




## What happened

**`generate_sprite` is still not available** in this session (it isn’t in the agent’s tool list), so **DALL·E was not run** and **`assets/sprites/*.png` were not regenerated**. Everything under `assets/sprites/` is unchanged.

## What was updated

1. **`ASSETS.md`**
   - States clearly that textures are **1024×1022** class (same idea as typical DALL·E square output) and must be **scaled with `love.graphics.draw(..., sx, sy, ...)`**.
   - Adds a **palette cues** table from **`src/config/defaults.lua`** (`team1` / `team2` RGB) for future MCP prompts, plus pointers to **DESIGN.md** §7 / §9.
   - Keeps the full **path → `app.assets` key → use → suggested vs implemented scale** table (aligned with **`src/app.lua`**, **`mole_draw.lua`**, **`hud.lua`**).
   - Documents MCP absence, **`gen_sprites.mjs`** fallback, and the **opaque DALL·E** / alpha caveat.

2. **`.pipeline/game-art.handoff.md`**
   - Replaced the long transcript-style content with a **short** handoff: no MCP, no new art, **`ASSETS.md`** as the coder-facing manifest.

## Reads performed

- **DESIGN.md** — merged architecture; **`src/config/defaults.lua`**; **`assets/sprites/*.png`** in §9; HUD/polish in §7.
- **REQUIREMENTS.md** — R1–R3 are **`config.defaults`** meta; art expectations stay cross-linked to **CODING_NOTES** / **DESIGN** §7 in **`ASSETS.md`**.

When **`generate_sprite`** is enabled in your Cursor MCP config, the same **repo-relative** paths (e.g. `assets/sprites/mole_team_a_idle.png`, …) are the ones to target, using the palette section in **`ASSETS.md`** for consistent prompts.

## Files Created/Modified
- ASSETS.md
