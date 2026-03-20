# Stage: design (game-designer)

## Summary

Refreshing `.pipeline/game-designer-design.md` to match the expanded codebase. Checking `map_seed.lua` and related gameplay hooks.









Updating `.pipeline/game-designer-design.md` to reflect the implemented architecture (including `map_seed.lua`, scenes, systems, and input) and to anchor map cadence and seed behaviour to the codebase.




## Updated: `.pipeline/game-designer-design.md`

Refreshed the **game-designer** pipeline doc so it matches the **current ~48-file** layout and the merged `DESIGN.md`, without adding any implementation code.

### What changed

- **Codebase alignment** — Tables now point at real modules: `src/app.lua`, `scene_manager`, all `scenes/`, `systems/` (including `explosions`, `weapons`, `world_update`, `turn_resolver`, `vfx`), `input/*`, `ui/*`, `audio/sfx.lua`, plus **`src/game/map_seed.lua`**.
- **Map regeneration cadence (Overseer)** — Still **per round**, **`generate` only at round setup** (round 1 = same path, no match-only gen). **Seed/rematch** is explicitly tied to **`map_seed.derive(procedural_seed, round_index)`**: `nil` → new random each call; locked seed → deterministic per round; **Rematch** with `last_match_config` repeats the same per-round sequence.
- **Session stats** — Same contract as before, aligned with `session.lua`.
- **Mechanics** — Adds **direct hit detonation** on living moles (per README/CODING_NOTES) and references **dead active mole** handling.
- **Controls / gameLoop** — Routed through `scene_manager` and `src/input/*`; notes README behaviours (wheel power, pads on active player, Start → pause).
- **fileStructure / components / implementationOrder** — Describe what exists; **implementationOrder** is now a **verification / maintenance** list, not a greenfield plan.
- **Pseudocode** — Uses `map_seed.derive` before `world.mapgen.init.generate`.

If you want the same **map_seed** wording copied into root `DESIGN.md`, that would be the orchestrator’s merge step—not done here per “only `.pipeline/game-designer-design.md`”.

## Files Created/Modified
- .pipeline/game-designer-design.md
- .pipeline/love-architect-design.md
- .pipeline/love-ux-design.md
