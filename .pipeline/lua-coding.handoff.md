# Stage: coding (lua-coding)

## Summary

Auditing polish layers (SFX, VFX, input, HUD, game_over) against DESIGN.md and filling gaps.














Implementing polish: wiring hurt SFX for explosion/fall damage, grenade smoke VFX, game_over D-pad navigation + UI SFX, and a subtle ≤1 Hz HUD pulse per accessibility spec.
































































Here’s what **sub-task 3 (polish)** added on top of the existing SFX/VFX/input/HUD/game-over work.

### Audio
- **`hurt`** is now used when moles actually lose HP: **`explosions.apply`** calls **`on_moles_damaged`** once per blast if any mole’s HP dropped; **fall damage** in **`world_update`** calls the same hook with **`true`** for a quieter mix (see ```7:46:src/systems/explosions.lua``` and ```10:25:src/systems/world_update.lua```).
- **`play.lua`** wires **`on_moles_damaged`** / **`on_grenade_trail`** into **`feedback`** alongside explosion and weapon cues.

### Visual effects
- **`vfx:add_grenade_smoke`** — grey smoke puffs while grenades are in flight (~every **0.08s**), via **`on_grenade_trail`** in ```108:145:src/systems/world_update.lua``` and ```57:75:src/systems/vfx.lua```.

### UI / accessibility (≤ ~1 Hz pulse)
- **`play_hud`**: round-start band and hint line use a slow sine on alpha (**0.9 Hz** / **0.75 Hz**) so prompts stay readable and within the design’s pulse cap (```63:69:src/ui/hud/play_hud.lua```, hint block).
- **`game_over`**: “Continue → next …” uses **0.85 Hz** brightness pulse; **D-pad up/down** moves focus on **`match_end`**; **A / Enter / B / Esc** paths get a light **`ui`** blip where appropriate; footer hints for controls (```93:104:src/scenes/game_over.lua```, draw section).

### Pause
- **`ui`** SFX on **Restart / Setup / Menu**, not on **Resume**, so closing pause stays quiet (```75:95:src/scenes/pause.lua```).

### Smoke test
- **`love .`** ran briefly without an immediate exit.

**Original task** (mechanics, 2P, proc maps, session wins, 5 moles, rotation, match vars, KB+gamepad) remains covered by the existing game code; this pass focused on **feedback polish and menu/HUD refinement** for the final pipeline slice.

## Files Created/Modified
- src/scenes/game_over.lua
- src/scenes/pause.lua
- src/scenes/play.lua
- src/systems/explosions.lua
- src/systems/vfx.lua
- src/systems/world_update.lua
- src/ui/hud/play_hud.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; if (Test-Path "C:\Program Files\LOVE\love.exe") { $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -WindowStyle Hidden; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }`
