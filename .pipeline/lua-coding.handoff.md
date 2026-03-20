# Stage: coding (lua-coding)

## Summary

Implementing sub-task 3 polish: reading the codebase and DESIGN.md, then adding audio, VFX, input refinements, and gameplay edge-case fixes.









Implementing procedural audio, a VFX system (explosions, trails, match-end celebration), input smoothing and gamepad triggers, gameplay edge-case fixes, and wiring feedback hooks.














Updating `play.lua` to integrate VFX, SFX, stick smoothing, triggers, elimination handling, and refactored endgame flow.














Removing frozen celebration from `play` (won't update under overlay) and adding confetti to `game_over` for `match_end`.

















































Here’s what sub-task **3 of 3** added and how it ties together.

### Audio (`src/audio/sfx.lua`)
- Procedural **`SoundData`** built once in **`love.load`** via `require("audio.sfx").init()` in ```17:24:src/app.lua```.
- Cues: **fire** sweep, **grenade_pop**, **explosion** (noise + low **thump**), **hurt** (unused for now), **ui** blip.
- Wired from **`ctx.feedback`** in explosions/weapons, menu/match flow, and reassigned active mole.

### VFX (`src/systems/vfx.lua` + `play` draw)
- **Explosions:** expanding rings, gravity sparks, screen **shake**.
- **Weapons:** muzzle puffs on fire; **rocket trails** from ```59:62:src/systems/world_update.lua```.
- **Projectiles / grenades:** clearer layered draw (glow, core, fuse ring on grenades) in ```play.lua```.
- **Match end:** confetti runs on the **`game_over`** overlay (`match_end` only) with **`self:update`** so it animates while the stack top is `game_over` — see ```19:47:src/scenes/game_over.lua```.

### Input (`src/input/stick.lua` + `play.lua`)
- **Dual gamepad:** smoothed **left-stick** aim (`stick.smooth2`), **LB/RB** or **analog triggers** (`stick.read_triggers`) for charging; release when triggers &lt; ~0.1 and shoulders up.
- **Start → pause** stays **before** the active-player gate so **any** pad can pause (```368:375:src/scenes/play.lua```).
- **Nil slot:** non-assigned pads don’t fire weapons in dual mode (`slot == nil` guard).

### Gameplay edge cases
- **`turn_state.repair_active_slot`** (```86:108:src/game/turn_state.lua```): if the **active mole dies in aim** (e.g. fall), pick another living mole on that team or treat the team as wiped.
- **`play:on_round_victory`** centralises round/match overlays, uses **`_endgame_armed`** to avoid double-opens, resets flags in **`begin_round` / `start_match`** and overlay callbacks.
- **Flying:** if a team hits **0** living mid-flight, projectiles/grenades are cleared and the round ends immediately (no waiting on an empty “flying” resolve).

### Visual polish
- **Moles:** soft **shadow ellipse** + stacked fill for a bit more depth in ```mole.draw```.

### Session / match config
- **Rematch** still **`validate` + `copy`** from `session.last_match_config`; **Start match** still validates and stores **`last_match_config`** before **`play.new(c)`**.
- **`match_setup:resize`** refreshes joysticks after window changes (DESIGN hot-plug note).

### Docs
- **`README.md`**: polish section + layout rows for **`audio/`**, **`vfx`**, **`stick`**.
- **`CODING_NOTES.md`**: procedural audio, trigger axis variability.

`love .` was started briefly from the project root with no immediate Lua errors. If anything misbehaves on a specific pad, it’s usually trigger axis naming — shoulders remain the reliable charge input (noted in **CODING_NOTES**).

## Files Created/Modified
- CODING_NOTES.md
- README.md
- src/app.lua
- src/entities/mole.lua
- src/game/turn_state.lua
- src/scenes/game_over.lua
- src/scenes/main_menu.lua
- src/scenes/match_setup.lua
- src/scenes/play.lua
- src/systems/explosions.lua
- src/systems/weapons.lua
- src/systems/world_update.lua
- src/ui/hud/play_hud.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -NoNewWindow -PassThru | ForEach-Object { Start-Sleep -Seconds 3; if (-not $_.HasExited) { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue } }`
