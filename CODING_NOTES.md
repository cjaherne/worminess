## Deviations

- **Pipeline sub-task 1 wording (“rocket stub”):** The repo implements a **full** rocket (trajectory, hits, terrain, damage, SFX) and also **grenade** (R3). Nothing was stripped back to a stub so later sub-tasks and R2/R3 stay intact.
- **Shared keyboard layout:** Implemented a hybrid of `DESIGN.md` Part A (Game Designer) and Part B §5.2 (LÖVE UX). Power is on **`Z`/`X` (P1)** and **`I`/`K` (P2)`** instead of UX §5.2’s `W`/`S` vs `Up`/`Down`, to avoid clashes with **jump** and **menu navigation** on `Up`/`Down`.
- **Gamepad mapping:** Uses **A = jump**, **B = fire** (with **Y = end turn**, **LB/RB = weapon**) for reliable one-press actions across common XInput layouts. `DESIGN.md` mentions **RT fire** in places; triggers are used for **power** only here.
- **Audio:** No bundled `assets/audio/*.wav` yet. **`src/audio/sfx.lua`** uses short **procedural** beeps (fire / explosion / UI). Drop-in WAV/OGG loading can replace `sfx.init()` internals later without changing call sites.

## Issues Found

- **UX vs Designer controls:** Part A and Part B specify different key bindings for shared keyboard; the merged doc does not pick a single normative table. Implementation follows Designer P1/P2 columns for movement/aim/fire/end, with explicit power keys documented in `README.md`.
- **Enter as P2 fire (play scene only):** `Return` / `kpenter` now arm grenades/rockets for player 2 during gameplay. If future in-match UI uses Enter to confirm actions, route those keys before `keyboard_mouse.on_keypressed` or narrow the binding.

## Sub-task 1 — session loop, menu, locomotion, aim, rocket (satisfied)

| Ask | Where |
|-----|--------|
| `love.load` / `update` / `draw` | `main.lua` → `src/app.lua` (scene stack, letterboxed draw) |
| Minimal menu | `src/scenes/menu.lua` (+ `match_setup`, `play`, `pause`, `match_end`) |
| Locomotion + aim | `src/sim/physics.lua`, `src/sim/world.lua`, `src/input/*` |
| Rocket weapon | `src/sim/weapons/rocket.lua` + `world` projectile integration |
| Playable | Start match from menu → `play` scene with movement, aim, fire, end turn |

Window **focus**: `love.focus` → `app.focus` mutes `love.audio` when the game loses focus.

## Sub-task 3 — HUD, polish, input modes, match vars (implemented)

- **HUD:** Turn banner shows **player, team label, active slot, HP, phase line**, and **turn timer** when enabled. **Session scores** use three **chips** (P1 / P2 / draws) plus matches played. **Center “Team vitality”** panel: **aggregate HP bar**, **HP total vs team cap**, **living count** per team, current **input mode** line, and **Friendly fire ON** when enabled (R1/R6/R9/R10/R11 readability). **Weapon panel** uses **`sim.weapons.registry`**; highlights selected weapon; **live grenade fuse** in flight; power bar. **Wind** panel shows drift hint. **Roster** shows **per-slot HP**, **active slot** outline, **S1…S5** labels. **Help strip** summarizes controls per input mode.
- **Visual polish:** Moles: **shadow**, **team ground ellipse**, **dim non-active team**, **active ring**. Projectiles: rocket **trail/glow/streak**; grenade **fuse ring**, **spark**, **pulse outline**, shadow. Aim preview colors keyed to **rocket vs grenade** via registry.
- **Turn rotation:** `world.update` calls **`turn:sync_slots_to_living`** after damage so the active slot never sticks on a dead mole mid-turn (`turn_state` still advances roster on **end turn**).
- **Match setup:** **Mole health** (`mole_max_hp` stepper), **first turn**, **friendly fire**, **turn limit**, **map seed**, **input mode** (`shared_kb` / `dual_gamepad`), **wind**; read-only **5 moles per team** (R7).

## Overseer drift closure (menus + SFX + turn toast)

- **Gamepad menus:** `menu`, `match_setup`, `match_end`, and `pause` implement **`gamepadpressed`** plus **`util/gamepad_menu.lua`** (D-pad / left stick + cooldown) in **`update`**. **A** ≈ confirm, **B** ≈ back (setup → title, pause → resume/cancel, results → title). **Match end:** **X** = new setup. **Map seed** row still needs **keyboard** digits.
- **SFX hooks:** `audio/sfx.lua` + `world` **fire** / **explosion**; **UI blip** on menu confirmations and match actions.
- **Turn handoff toast (UX §3.6):** **`play`** shows a short **“Next: Player · Mole slot”** banner when turn ownership or active slot changes (not a separate `round_end` scene).

## Sub-task 2 — procedural maps, distinct weapons, 2P turn combat (satisfied)

| Pipeline ask | Implementation |
|--------------|------------------|
| Procedural map **in gameplay** | `terrain_gen.build` from `World.new` (`world.lua`); `map_seed` / random from `match_settings` |
| **Rocket** vs **grenade** distinct | Rocket: fast segment sweep, mild `rocket_gravity_mul`, impact detonation. Grenade: arc, full `gravity`, **fuse**, bounce + `grenade_unstick_px`. Different blast/damage in `config.defaults.weapon`. |
| **Two-player turns** + combat | `turn_state.lua` (Designer pseudocode); `play.lua` drives `world:update` + win → `match_end`; damage/knockback `damage.lua`, terrain carve on explosion |

`world.weapon_index` uses **`sim.weapons.registry`** (`rocket` / `grenade` constants) so slots stay aligned with R2/R3 and HUD.

## Suggestions

- Optional full-screen **`round_end` scene** (1–2 s) instead of/in addition to the play toast.
- Load **real** `assets/audio/*` clips when available; keep procedural fallbacks as default.
- Add a `keymaps_shared.lua` data table plus optional rebinding UI.
- Surface **RT-edge fire** on gamepad as an option once input buffering is unified.
- Cache terrain drawing in a canvas when profiling shows fill-rate limits on large maps.

## Environment

- Smoke-tested with **LÖVE 11.5** (`love.exe` on this machine); `conf.lua` targets **11.4** per design — 11.5 is API-compatible for this project.

## Requirements traceability (R1–R11)

| ID | Status |
|----|--------|
| R1 presentation | Above + procedural SFX + gamepad-friendly menus + turn toast |
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
