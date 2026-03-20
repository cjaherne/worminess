# Stage: design (game-designer)

## Summary

Reading `.pipeline/game-designer-design.md` and updating it with a definitive map-regeneration cadence and `mapgen.generate` timing (including rematch/seed).









Adding an authoritative **map regeneration cadence** section and updating the checklist, procedural-map mechanics, `gameLoop`, pseudocode, and handoff notes.














## Done

Updated **`.pipeline/game-designer-design.md`** with an Overseer block **Map regeneration cadence (default)** and aligned the checklist, high-level mechanics, procedural-map section, `gameLoop`, pseudocode, `implementationOrder`, considerations, and handoff.

### Decisions captured

| Topic | Spec |
|--------|------|
| **Default cadence** | **Per round** — new terrain every round. |
| **When `world.mapgen.init.generate` runs** | **Once per round**, in **round setup**: after the previous round is decided / interstitial advances, **before** mole placement for that round. **Round 1** uses the same path (first match entry = first round setup). **No** match-only shortcut and **no** carrying the old terrain into the next round. |
| **`procedural_seed` nil** | New **random** seed **each** call → each round (and rematch) gets new layouts. |
| **`procedural_seed` set** | Deterministic **`f(seed, round_index)`** so rounds differ but replay is stable; **Rematch** with the same saved config repeats the **same terrain sequence** (round *k* matches the earlier match’s round *k*). |
| **Module** | Points to **`src/world/mapgen/init.lua`** / require **`world.mapgen.init`**. |

No `.lua` or other implementation files were changed—design doc only.

## Files Created/Modified
- .pipeline/game-designer-design.md
