# Stage: design (game-designer)

## Summary

Reading the codebase to align the design with implemented modules and updating `.pipeline/game-designer-design.md`, including an explicit session-stats definition per overseer feedback.



















Updating `.pipeline/game-designer-design.md` to align with the implemented `src/` layout and adding the overseer's one-sentence session-stats definition.




## Update complete

`.pipeline/game-designer-design.md` is rewritten to **match the real tree** (`conf.lua`, `main.lua`, `src/bootstrap.lua`, `src/game/*`, `src/data/*`, `src/entities/*`, `src/world/*`, `src/world/mapgen/*`, `src/core/*`) and to **drop** the old “no sources yet” note.

### Overseer ask — session stats (one explicit sentence)

Added a dedicated **“Session stats definition”** block with a single binding sentence for coders: **`scores[1]`/`scores[2]` = match wins since launch (not rounds, not per-player “games played”); `matches_completed` = number of fully finished matches in the session; don’t repurpose these fields for round tallies without renaming and fixing UI copy.** That matches what `src/game/session.lua` already does with `bump_match_win`.

### Everything else

- **requirementsChecklist** still tracks each original-task bullet (including beautiful styling, proc maps, 5 moles, rotations, input modes).
- **mechanics / controls / gameLoop** are tied to **`turn_state`**, **`roster`**, **`match_config`**, **`weapons.lua`**, **`constants.lua`**, and **mapgen**.
- **implementationOrder** is a **delta** from the current codebase (orchestrator/input/UI first, not “terrain stub from zero”).
- **`main.lua` → `app`** is noted; `app.lua` wasn’t in the glob—called out as likely Architect-owned.

No implementation files were added or changed—only `.pipeline/game-designer-design.md`.

## Files Created/Modified
- .pipeline/game-designer-design.md
