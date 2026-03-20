# Stage: design (game-designer)

## Summary

Reading the pipeline design and key sim/input files to align the game-designer document with the implemented codebase.









Updating the game-designer pipeline doc to reflect the implemented codebase: accurate repo baseline, shipped controls, file map, assets, and a concise normative precedence line.
























Updated **`.pipeline/game-designer-design.md`** so it matches the **current shipped game** and still serves as the mechanics blueprint. Summary of changes:

### Repo & traceability
- **Repo baseline** now lists real modules: `app.lua`, scenes, sim (including `world.lua`, `weapons/*`), input, render, `hud`, `sfx`, plus **`CODING_NOTES.md`**, **`ASSETS.md`**, **`README.md`**.

### Turn model (overseer + code)
- Added a **one-line precedence** rule: Turn Model **pseudocode overrides** conflicting architecture text on rotation.
- Added **code alignment** notes for **`turn_state.lua`** and **`world.lua`** + `sync_slots_to_living` (per `CODING_NOTES.md`).
- **R-rotate-moles** checklist text now matches the normative rule (advance on **end of that player’s turn**, ring 1..5, symmetric same-slot).

### Mechanics / data
- **Weapon table** points to **`src/config.defaults.lua`** for numbers (including rocket gravity / ray steps, grenade fuse, unstick).
- **Match variables** include shipped fields: **`wind`**, **`input_mode`**, **`map_seed`**, and **v1 fixed 5 moles** from `match_settings.validate`.

### Controls
- Replaced “suggested” keys with the **implemented** layout (power **`Z`/`X`** vs **`I`/`K`**, P2 fire including **`Enter`**, etc.) and tied it to **`keyboard_mouse.lua`** / **`README.md`**.
- **Gamepad:** documented **B = fire**, **triggers = power**, menu on **first** pad; flagged drift vs older “RT fire” wording → **`CODING_NOTES.md`** + **`gamepad.lua`** as source of truth.

### Loop, files, assets, order
- **gameLoop** names actual scenes and `app.quit_match_to_results` / session recording.
- **fileStructure** is a **concern → module** map for the current tree.
- **assetStructure** matches **`assets/sprites/*`** and **`ASSETS.md`**; notes procedural **`sfx.lua`** and optional audio/fonts.
- **implementationOrder** reframed as **regression / feature order** now that the game exists.

### Session scores & notes
- Session scoring references **`record_match_outcome`**, **`get_snapshot`** (wins / draws / games played).
- **Notes for Coding Agent** reference **`CODING_NOTES.md`**, normative precedence over **`DESIGN.md` Part B/C**, and binding maintenance rules.

No `.lua` or other implementation files were modified—**design markdown only**.

## Files Created/Modified
- .pipeline/game-designer-design.md
- .pipeline/love-architect-design.md
