# Stage: coding (lua-coding)

## Summary

Reading DESIGN.md and auditing gameplay systems against sub-task 2 requirements.


































Identifying a critical bug: `turn_resolver.resolve_flying_end` expects `ctx.team_turn_slot`, but `play_ctx()` omits it — causing a crash when a turn ends after projectiles settle. Adding `team_turn_slot` to `play_ctx()` and running a quick smoke test.









## Sub-task 2 status

Gameplay for this slice was already wired: **`play.lua`** (rounds, `map_seed.derive` + **`mapgen.generate`**, mole order rotation, alternating **`starting_player`**), **`turn_state`**, **`world_update`** (rockets/grenades, **direct mole hits**), **`weapons`**, **`explosions`**, **`turn_resolver`**, **`roster`** (5 moles, **`rotate_order`**), **`session`** (match wins + **`matches_completed`**), and **`input/*`**.

### Bug fix (turn advance)

**`turn_resolver.resolve_flying_end`** updates **`ctx.team_turn_slot`** and passes it into **`turn_state.advance_turn`**, but **`play_ctx()`** never exposed **`team_turn_slot`**. After a shot resolved, Lua would hit **“attempt to index a nil value”** when advancing the turn.

**Change:** include **`team_turn_slot = self.team_turn_slot`** in the table returned by **`play_ctx()`** in ```46:59:src/scenes/play.lua``` so turn progression and per-team mole rotation stay consistent with the design.

### Self-check vs **Original task**

| Requirement | Where it lives |
|-------------|----------------|
| Core artillery (aim, power, flight, terrain, blasts) | `play.lua`, `world_update`, `explosions`, `weapons` |
| Rocket + grenade | `data/weapons.lua`, `entities/*`, `world_update` |
| 2-player local | `match_config.input_scheme`, `play`, `devices` |
| Procedural maps, **per round** | `map_seed.lua`, `world/mapgen/init.lua`, `play:begin_round` |
| Scores since launch (match wins) | `session.lua`, HUD / menus |
| 5 moles / team | `MOLES_PER_TEAM`, `roster.new_team` |
| Rotate players each round | `starting_player = ((round_index - 1) % 2) + 1` |
| Rotate moles each round | `roster.rotate_order` in `begin_round` |
| Match vars (e.g. HP) | `match_config`, `match_setup` |
| KB+mouse and/or pads | `bindings`, `devices`, `play` input handlers |

**`main.lua`** still registers **`love.load` / `love.update` / `love.draw`** via **`app.register()`** (not duplicated in `main.lua` itself).

A short **`love .`** run completed without an immediate crash after the fix.

## Files Created/Modified
- src/scenes/play.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; if (Test-Path "C:\Program Files\LOVE\love.exe") { $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -WindowStyle Hidden; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; exit 0 } else { Write-Host "LOVE not installed at default path"; exit 0 }`
