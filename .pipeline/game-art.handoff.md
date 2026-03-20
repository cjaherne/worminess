# Stage: game-art (game-art)

## Summary

Acting as the game-art pass: reading design docs, pipeline handoffs, and the sprite folder, then checking for the `generate_sprite` MCP tool and updating `ASSETS.md`.




Reading pipeline handoffs and `src/app.lua` to align the manifest with code. Checking whether `config` lives under `src/config/`.














Checking sprite dimensions to document resolution accurately:














Confirming sprites are 1024×1024 from `gen_sprites.mjs`. Updating `ASSETS.md` to reference `src/config/defaults.lua` per DESIGN and refreshing `.pipeline/game-art.handoff.md`. The `generate_sprite` tool isn't available in this session.




Here’s what this pass did.

## Context

- **`DESIGN.md`** / **`REQUIREMENTS.md`** in the repo are about fixing **`config.defaults`** path layout, not visual specs. Art-relevant detail comes from **`CODING_NOTES.md`** (HUD, moles, rocket/grenade) and pipeline UX/design handoffs, which already match **`assets/sprites/*`** and **`ASSETS.md`**.
- **`generate_sprite`** is **not** available in this Cursor session (no MCP tool by that name in the tool list), so **no new PNGs** were produced and nothing under **`assets/sprites/`** was overwritten.

## Verified against code

Sprite keys and paths match **`src/app.lua`**:

```72:84:C:\Users\Chris\Documents\GitHub\worminess\src\app.lua
  app.assets.mole_a_idle = load_image("assets/sprites/mole_team_a_idle.png")
  app.assets.mole_a_aim = load_image("assets/sprites/mole_team_a_aim.png")
  app.assets.mole_a_walk_1 = load_image("assets/sprites/mole_team_a_walk_1.png")
  app.assets.mole_a_walk_2 = load_image("assets/sprites/mole_team_a_walk_2.png")
  app.assets.mole_b_idle = load_image("assets/sprites/mole_team_b_idle.png")
  app.assets.mole_b_aim = load_image("assets/sprites/mole_team_b_aim.png")
  app.assets.mole_b_walk_1 = load_image("assets/sprites/mole_team_b_walk_1.png")
  app.assets.mole_b_walk_2 = load_image("assets/sprites/mole_team_b_walk_2.png")
  app.assets.rocket = load_image("assets/sprites/rocket.png")
  app.assets.grenade = load_image("assets/sprites/grenade.png")
  app.assets.ui_icon_rocket = load_image("assets/sprites/ui_icon_rocket.png")
  app.assets.ui_icon_grenade = load_image("assets/sprites/ui_icon_grenade.png")
  app.assets.ui_icon_wind = load_image("assets/sprites/ui_icon_wind.png")
```

Scales in **`ASSETS.md`** match **`mole_draw.lua`** (`SPR_SCALE` **0.058**, rocket **0.065**, grenade **0.068 × pulse**, aim **0.95×** mole scale) and **`hud.lua`** (**0.42** for icons). Sprites are **1024×1024** from **`tools/gen_sprites.mjs`** (`centerOnCanvas` / `encodePngRgba(1024, 1024, …)`), i.e. the same ballpark as DALL·E square output.

## Files updated

1. **`ASSETS.md`** — Single manifest: resolution/scaling, MCP/DALL·E alpha warning, palette note pointing at **`src/config/defaults.lua`** (`require("config.defaults")`), full table **path → `app.assets` key → use → suggested vs implemented scale**, gaps, and requirements note (R1–R3 vs **CODING_NOTES** for presentation).
2. **`.pipeline/game-art.handoff.md`** — Short handoff for this run: no MCP, outputs unchanged, follow-up when **`generate_sprite`** exists.

If you want DALL·E replacements later, enable the **`generate_sprite`** MCP in Cursor and we can re-run prompts against the same **`assets/sprites/*.png`** paths; you’ll likely tweak **`SPR_SCALE`** and HUD **`0.42`** after swapping art.

## Files Created/Modified
- ASSETS.md

## Shell Commands Run
- `powershell -NoProfile -Command "Get-ChildItem 'C:\Users\Chris\Documents\GitHub\worminess\assets\sprites\*.png' | ForEach-Object { Add-Type -AssemblyName System.Drawing; $img = [System.Drawing.Image]::FromFile($_.FullName); Write-Output (\"$($_.Name) $($img.Width)x$($img.Height)\"); $img.Dispose() }"`
