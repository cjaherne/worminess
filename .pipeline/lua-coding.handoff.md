# Stage: coding (lua-coding)

## Summary

Implementing sub-task 2: gameplay mechanics, mapgen integration, input, systems, and UI (match setup + HUD). Reading the codebase and DESIGN.md to build on existing code.



















Implementing gameplay systems, input, map seeding, match setup, full play scene with rounds/mapgen, HUD, pause, and game_over. Working incrementally.



























































Removing the unused require from `play_hud.lua` and implementing `match_setup`, `play`, `pause`, and `game_over`.









Writing `match_setup.lua` and the full `play.lua`.




Implementing the full `play.lua`.




Fixing `play.lua` update logic (remove duplicate projectile updates), fixing `turn_resolver` duplicate phase set, moving `mole` require to the top, calling `theme.load_fonts` from `app`, wiring `main_menu` → `match_setup`, and adding joystick hot-plug handlers.






















































Here’s what was implemented for **sub-task 2**: full combat loop, per-round proc mapgen, match setup + HUD, input modes, and overlays.

### Gameplay & world
- **`src/game/map_seed.lua`** — `derive(procedural_seed, round_index)` per DESIGN (random vs deterministic sequence).
- **`src/systems/world_update.lua`** — Mole gravity/slide vs terrain, fall damage, rocket substeps + terrain hits, grenade physics via `entities.grenade.update`.
- **`src/systems/weapons.lua`** — Fire rocket/grenade from the active mole (`turn_state.active_mole`), wind from `MatchConfig`, fuse from `grenade_fuse_seconds`.
- **`src/systems/explosions.lua`** — Single carve + radial damage/knockback, respects **`friendly_fire`** via `mole.damage`.
- **`src/systems/turn_resolver.lua`** — When nothing is flying: **round win** (living count) or **advance turn** with `team_turn_slot` + `roster.next_order_slot_after_mole`.
- **`src/game/roster.lua`** — `next_order_slot_after_mole`, `place_team_from_spawns` (full heal + position each round).
- **`src/game/match_config.lua`** — `copy()` for snapshots / rematch.
- **`src/game/turn_state.lua`** — `active_mole`, interstitial timing helpers.
- **`src/entities/mole.lua`** — `apply_impulse`, `draw` (team colour + mole index label).

### Input
- **`src/input/bindings.lua`** — P1/P2 shared KB sets (Worms-style).
- **`src/input/devices.lua`** — `shared_kb` vs `dual_gamepad`, P1 auto-pick first pad, P2 **A to assign**, hot-plug refresh.
- **`src/input/input_state.lua`** — Stub for future edge tracking.

### UI & scenes
- **`src/ui/theme.lua`** — `load_fonts()` (22px body, 28px HUD scores).
- **`src/ui/layout.lua`** — `screen_to_logical` for clicks.
- **`src/ui/hud/play_hud.lua`** — Turn banner, **round wins vs session match wins**, wind, move/power bars, weapon strip, fuse line, hints, interstitial toast area.
- **`src/ui/focus_stack.lua`** — Small stack helper for later menus.
- **`src/scenes/match_setup.lua`** — All **MatchConfig** fields, Tab/arrow editing, **1 / 2** (and pad **X/Y**) for Ready, dual-controller status, validate → **`play.new(cfg)`**, `session.last_match_config` updated.
- **`src/scenes/play.lua`** — Owns match: **mapgen every round**, mole rotation + `starting_player = ((round_index-1)%2)+1`, aim/move/power, mouse aim in **`shared_kb`**, pad aim/charge/fire in **`dual_gamepad`**, pause (**Esc** / **Start**), stack **`pause`** / **`game_over`**.
- **`src/scenes/pause.lua`**, **`src/scenes/game_over.lua`** — UX flow: resume / restart / setup / menu; round vs match end; **Rematch** uses `session.last_match_config`; **`session:bump_match_win`** only on **match** end.

### Wiring
- **`src/scenes/main_menu.lua`** — **Local match** → **`match_setup`** (no direct play).
- **`src/app.lua`** — `theme.load_fonts()` in `love.load`; **`joystickadded` / `joystickremoved`** refresh devices.

### Docs
- **`README.md`** — Updated structure and flow.
- **`CODING_NOTES.md`** — Turn-timer auto-fire, shared vs dual input, toast cadence, tuning notes.

### Original task (sanity)
| Requirement | Where it’s covered |
|-------------|-------------------|
| Worms-like core (aim, power, wind, terrain, explosions, HP, turns, rounds/match) | `play`, systems, `turn_state`, `game_over` |
| Rocket + grenade | `weapons.lua`, `data/weapons.lua`, entities |
| 2P local, proc maps each round | `mapgen/init` + `map_seed`, `play:begin_round` |
| Session **match** wins / matches completed | `session.lua`, HUD + menus |
| 5 moles, rotation | `constants`, `roster.rotate_order` each round |
| Starting player alternation | `((round_index-1)%2)+1` |
| Match variables | `match_setup` + `match_config.validate` |
| Shared KB+mouse / dual pads | `bindings`, `devices`, `play` routing |

Run locally with **`love .`** from the repo root; fonts and scaling load in **`love.load`** via `theme.load_fonts()`.

## Files Created/Modified
- CODING_NOTES.md
- README.md
- src/app.lua
- src/entities/mole.lua
- src/game/match_config.lua
- src/game/roster.lua
- src/game/turn_state.lua
- src/scenes/main_menu.lua
- src/scenes/play.lua
- src/ui/theme.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; & "C:\Program Files\LOVE\love.exe" --console . 2>&1 | Select-Object -First 40`
- `Stop-Process -Name love -Force -ErrorAction SilentlyContinue`
