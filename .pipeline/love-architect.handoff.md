# Stage: design (love-architect)

## Summary

Gathering project requirements and pipeline context to produce the LÖVE architect design document.




Workspace is greenfield for game code (only `REQUIREMENTS.md`). Writing the LÖVE architect design to `.pipeline/love-architect-design.md`.




Here’s what was delivered.

## Summary

`REQUIREMENTS.md` is the only game-related source file in the repo right now, so the design assumes a **greenfield LÖVE 11** layout and spells out how it should grow.

**Written artifact:** [`.pipeline/love-architect-design.md`](.pipeline/love-architect-design.md)

It includes:

- **Architecture:** Scene stack (`Boot` → `Menu` → `MatchSetup` → `Play` + `Pause` → `RoundEnd` / `MatchEnd`), split between **sim** (`src/sim/`), **render** (`src/render/`), **input** (`src/input/`), and **data** (`src/data/`).
- **File tree:** `main.lua` / `conf.lua` as thin entrypoints; `src/app.lua` owning callbacks; concrete module list (e.g. `terrain_gen.lua`, `turn_state.lua`, `session_scores.lua`, `weapons/rocket.lua`, `weapons/grenade.lua`).
- **Models:** `MatchSettings` (R7/R9), `SessionScores` (R6, session-only with optional later persistence), `World` / terrain / moles / projectiles, `PlayerIntent` for R4/R10/R11.
- **Procedural maps:** Pure (or mostly pure) `terrain_gen.build(seed, …) → TerrainModel`, heightmap-style baseline, spawn regions, bounded retries — **generate between matches**, not every frame.
- **Scores:** `session_scores` initialized in `love.load`, updated only from **`match_end`**, surfaced on menu/HUD via `get_snapshot()`.
- **`require` graph:** Direction rules to avoid cycles; sim leaves (`terrain_gen`, `vec2`, `damage`) documented.
- **Coding-agent notes:** Update order, shared explosion path, active-mole gating, keyboard+mouse vs dual gamepad, testable pure functions.
- **JSON block** at the end for orchestrator merge, plus an R1–R11 crosswalk.

No `.lua` or other implementation files were added—only this design markdown, as requested.

## Files Created/Modified
- .pipeline/love-architect-design.md
