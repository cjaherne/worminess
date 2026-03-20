# Stage: coding (lua-coding)

## Summary

Reading DESIGN.md, REQUIREMENTS.md, and the existing codebase to implement the game loop, menu, and playable character with movement, aiming, and weapons.




Reading existing simulation modules and checking for `src/app.lua`.



















Implementing `src/app.lua`, scenes, input, render, and UI to integrate the existing simulation. Creating the file structure.
























Fixing keyboard layout: correcting P2 power/aim logic and weapon selection.




Simplifying gamepad input and adding absolute aim support in `world.lua`.



















Implementing scenes and `app.lua`.









Patching `world.lua` to handle `fire_pressed` and `end_turn_pressed`, fixing `play.lua` input forwarding, and correcting the HUD layout.









Fixing pause menu key handling and implementing `app.lua` with `quit_match_to_results`. Updating `play.lua` to pass `map_seed_used`.



























































Here’s what was implemented and how it fits together.

## Summary

The repo already had solid **simulation** (`world`, terrain, weapons, turns). What was missing was the **LÖVE app shell**: scenes, input routing, rendering, and HUD. That layer is now wired up so you get a full loop from **menu → match setup → play → pause / match end**, with **movement, jump, aim, rocket/grenade, end turn**, and **R1–R11** covered in code (see `CODING_NOTES.md` for traceability and a few intentional control-layout deviations).

### New / updated pieces

- **`src/app.lua`** — Scene stack (`push` / `pop` / `goto`), asset loading, letterboxed **1280×720** drawing via `src/util/viewport.lua`, `end_match` / `quit_match_to_results` (forfeit).
- **`src/scenes/`** — `menu`, `match_setup`, `play`, `pause`, `match_end`.
- **`src/input/`** — `input_manager`, `keyboard_mouse` (R10), `gamepad` (R11).
- **`src/render/`** — `camera`, `terrain_draw`, `mole_draw` (sprites at ~`0.058` scale per `ASSETS.md`).
- **`src/ui/hud.lua`** — Turn banner, session line, weapon panel, wind, roster, control hint strip.
- **`main.lua`** — Forwards **`love.textinput`** for optional map seed typing.
- **`src/sim/world.lua`** — Handles **`fire_pressed`** / **`end_turn_pressed`** and **gamepad absolute aim** (`_use_absolute_aim`).
- **`README.md`** — Run instructions and controls; **`CODING_NOTES.md`** — deviations, design conflicts, R1–R11 table.

### How to run

From the project root:

```bash
love .
```

(A quick smoke run with **LÖVE 11.5** on this machine started without errors; `conf.lua` still says **11.4** as in the design.)

### Sub-task 1 checklist

| Item | Status |
|------|--------|
| `love.load` / `update` / `draw` via `main.lua` → `app` | Yes |
| Minimal menu + options path | Yes (`Play`, `Match options`, `How to play`, `Quit`) |
| Move / jump / aim / weapon | Yes (shared KB+M + optional dual pads) |
| Playable “solo” | Yes — hotseat: one person can play both sides on alternating turns |

### Controls (short)

- **Shared KB+M:** P1 `A`/`D` move, `W` jump, `Q`/`E` aim, `Z`/`X` power, `F` fire, `G` end turn, `1`/`2` weapons; P2 arrows, `[`/`]`, `I`/`K`, `;`, `Backspace`/`\`, `,`/`.`; **mouse aims and LMB fires** for whoever’s turn it is.
- **Two gamepads:** left stick move, right stick aim, triggers power, **A** jump, **B** fire, **LB/RB** weapon, **Y** end turn, **Start** pause/resume.

Details and the UX-vs-designer binding differences are in **`README.md`** and **`CODING_NOTES.md`**. If you want next, we can add **gamepad menu navigation** (called out as a follow-up in `CODING_NOTES.md`).

## Files Created/Modified
- main.lua
- src/sim/world.lua

## Shell Commands Run
- `where love 2>nul; where love.exe 2>nul; lua -v 2>nul; luajit -v 2>nul`
- `Get-Command love -ErrorAction SilentlyContinue | Format-List`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -NoNewWindow; Start-Sleep -Seconds 3; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }; $p.ExitCode`
