# Stage: design (love-architect)

## Summary

Reading the current architect design, game designer turn rules, and key source files so we can align §4.1 and the R10/R11 crosswalk.




Updating the architect design to align with the Game Designer’s turn model, correct the R10/R11 crosswalk, and reference the repo’s existing Lua files.









Here’s what changed in [`.pipeline/love-architect-design.md`](.pipeline/love-architect-design.md):

### §4.1 / `turn_state` (Overseer alignment)
- **Authoritative rule:** Matches Game Designer / `DESIGN.md`: on **end turn**, **`advance_mole_index(ended_player)`** only, then **`turn_player = other(ended_player)`**; opponent’s roster index is unchanged.
- **Match start:** `first_player` from `MatchSettings`; each `mole_index[p]` = first living mole; **no advance before the first turn**.
- Added explicit **state**, **invariants**, and **pseudocode**; stated that if anything else in the architect doc disagrees, **§4.1 wins**.

### `turn_state` / `input_manager` table rows
- `turn_state.lua` is described with that end-turn + roster model.
- `input_manager.lua` splits **R10** (shared KB+M + **turn-owner mouse routing**) vs **R11** (dual gamepad / dual joystick).

### R10 / R11 crosswalk (§12)
- **R10** → `input_manager` **turn-owner gating** + `keyboard_mouse.lua`, **`shared_kb` only**.
- **R11** → `input_manager` + `gamepad.lua`, **`dual_gamepad`**.

### Build on existing repo (§2, §3.1, §7.2, input tree)
- Lists **existing** files: `main.lua`, `conf.lua`, `DESIGN.md`, `REQUIREMENTS.md`, `src/config/defaults.lua`, `src/data/match_settings.lua`, `src/data/session_scores.lua`, `src/util/timer.lua`, `src/util/vec2.lua`.
- `input_mode` values match **`match_settings.lua`**: `shared_kb` | `dual_gamepad` (removed `split_kb`).
- `main.lua` section matches the repo: **`require("app")`** after `setRequirePath`, not `require("src.app")`.
- `keyboard_mouse.lua` / `gamepad.lua` blurbs updated so R10 is not “P1 always mouse”.

### Other touch-ups
- §1.2 update flow: mouse routing note; `turn_state.on_frame` for timers.
- §3.4: turn-owner policy for intents.
- §11 JSON: `turn_state.lua` public API sketch uses `on_end_turn(ended_player)`, `init`, etc.

No `.lua` implementation files were added or edited—only the architect markdown.

## Files Created/Modified
- .pipeline/love-architect-design.md
