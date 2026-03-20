# Stage: coding (lua-coding)

## Summary

Implementing sub-task 3: reading the design and current HUD, input, match setup, and rendering code to identify gaps and polish.



















Sub-task 3 is largely implemented. Adding a center HUD panel for team vitality (aggregate HP and living counts), a friendly-fire indicator, and wiring the weapon UI to `sim.weapons.registry` for consistency with `world.lua`.














## Sub-task 3 status

The game already met most of sub-task 3 (HUD, projectile/mole polish, shared KB+M, dual gamepads, mole health and other match options in **Match setup**). This pass **extends** that work and tightens consistency.

### What I added or changed

1. **`src/ui/hud.lua` — `draw_match_vitals`**
   - Center column between weapon and wind: **Team A / Team B** with **aggregate HP bar**, **current HP vs full roster cap**, **living count**, the active **input mode** string, and **Friendly fire ON** when `friendly_fire` is enabled.
   - Weapon panel now uses **`sim.weapons.registry`** (`W.rocket` / `W.grenade`) instead of raw `1` / `2`.

2. **`src/scenes/play.lua`**
   - Calls **`hud.draw_match_vitals`** during play so session-style scoring (top right) and **team-level health** (center) are both visible.

3. **`src/render/mole_draw.lua`**
   - Aim preview length/color uses the same **registry** as the sim/HUD.

4. **`CODING_NOTES.md`** — Sub-task 3 section updated to describe the vitality panel, registry alignment, and match-setup coverage (R7/R9/R10/R11).

5. **`README.md`** — HUD section updated for the center panel and help strip.

### Verification

- **`love .`** smoke run: OK.
- **Lint:** no issues on edited files.
- **R1–R11:** Still mapped in `CODING_NOTES.md`; R9 (mole health, etc.) remains in **`match_setup`** + **`match_settings`**; R10/R11 remain in **`input_manager`** + **`keyboard_mouse`** / **`gamepad`** + setup **Input** row.

If you want the next iteration, a natural follow-up is a **numeric map-seed editor** on the seed row for gamepad-only users (called out in `CODING_NOTES` as keyboard-only today).

## Files Created/Modified
- CODING_NOTES.md
- README.md
- src/render/mole_draw.lua
- src/scenes/play.lua
- src/ui/hud.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -NoNewWindow; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }`
