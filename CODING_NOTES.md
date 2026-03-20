## Deviations

- **Shared keyboard layout:** Implemented a hybrid of `DESIGN.md` Part A (Game Designer) and Part B §5.2 (LÖVE UX). Power is on **`Z`/`X` (P1)** and **`I`/`K` (P2)`** instead of UX §5.2’s `W`/`S` vs `Up`/`Down`, to avoid clashes with **jump** and **menu navigation** on `Up`/`Down`.
- **Gamepad mapping:** Uses **A = jump**, **B = fire** (with **Y = end turn**, **LB/RB = weapon**) for reliable one-press actions across common XInput layouts. `DESIGN.md` mentions **RT fire** in places; triggers are used for **power** only here.

## Issues Found

- **UX vs Designer controls:** Part A and Part B specify different key bindings for shared keyboard; the merged doc does not pick a single normative table. Implementation follows Designer P1/P2 columns for movement/aim/fire/end, with explicit power keys documented in `README.md`.
- **Enter as P2 fire (play scene only):** `Return` / `kpenter` now arm grenades/rockets for player 2 during gameplay. If future in-match UI uses Enter to confirm actions, route those keys before `keyboard_mouse.on_keypressed` or narrow the binding.

## Sub-task 2 — terrain, combat, two-player (implemented)

- **Procedural terrain:** `terrain_gen.lua` uses **smoothed columns**, **domain warp**, extra **ridge** detail, and a mild **left/right bias**; **72** retries for valid spawn plateaus.
- **Rocket:** **Gravity-scaled trajectory** (`rocket_gravity_mul`) and finer **swept collision** (`rocket_ray_steps`).
- **Grenade:** **Post-bounce unstick** (`grenade_unstick_px`) to reduce embedding in solid terrain after bounces.
- **Wind:** Uses **`built.seed_used`** so direction is tied to the map that was actually generated.
- **Local 2P:** Existing **hotseat + dual bindings + gamepads**; P2 fire widened to **`;` / Enter / RCtrl** per design alternatives.

## Suggestions

- Add **gamepad / D-pad navigation** on title, setup, pause, and match end (currently **keyboard-first** menus).
- Add a `keymaps_shared.lua` data table plus optional rebinding UI.
- Surface **RT-edge fire** on gamepad as an option once input buffering is unified.
- Cache terrain drawing in a canvas when profiling shows fill-rate limits on large maps.

## Environment

- Smoke-tested with **LÖVE 11.5** (`love.exe` on this machine); `conf.lua` targets **11.4** per design — 11.5 is API-compatible for this project.

## Requirements traceability (R1–R11)

| ID | Status |
|----|--------|
| R1 presentation | Menus, sky/terrain palette, scaled sprites, HUD panels |
| R2 rocket | `src/sim/weapons/rocket.lua` + world integration |
| R3 grenade | `src/sim/weapons/grenade.lua` + fuse + HUD |
| R4 2P local | Hotseat play scene, two teams |
| R5 procedural maps | `src/sim/terrain_gen.lua` + seed from match setup |
| R6 session scores | `src/data/session_scores.lua` + menu / HUD / match end |
| R7 five moles | Spawn in `World.new` / `mole.spawn_team` |
| R8 rotate turns/moles | `src/sim/turn_state.lua` per DESIGN.md pseudocode |
| R9 match variables | `src/scenes/match_setup.lua` + `match_settings` |
| R10 shared KB+M | `src/input/keyboard_mouse.lua` + turn-owner mouse in `world` |
| R11 dual gamepad | `src/input/gamepad.lua` + setup warning if fewer than two pads |
