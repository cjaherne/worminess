# Stage: design (love-architect)

## Summary

Reviewing the codebase and existing pipeline design to refresh `.pipeline/love-architect-design.md` and consolidate the MatchConfig schema per overseer feedback.














Noting `main.lua` requires `app`, but `src/app.lua` isn't in the repo—documenting that gap. Updating `.pipeline/love-architect-design.md`: align with implemented modules, consolidate `MatchConfig` with `match_config.lua`, and add a DESIGN.md merge note for the stale codebase snapshot.




Here’s what changed in [`.pipeline/love-architect-design.md`](C:\Users\Chris\Documents\GitHub\worminess\.pipeline\love-architect-design.md).

### Repo snapshot (overseer / DESIGN.md)

- Added **§0** with an up-to-date file list and tech stack, and called out that root [`DESIGN.md`](DESIGN.md) still claims there is no `main.lua` / `src/` — that’s **out of date**.
- Per pipeline rules I did **not** edit `DESIGN.md`; §0 is written so the orchestrator can paste/replace that paragraph when merging.

### `MatchConfig` consolidation (§3.1)

- **Single schema** aligned with live [`src/game/match_config.lua`](src/game/matchiness/src/game/match_config.lua) **and** the designer “Components” list: `mole_max_hp`, `rounds_to_win`, `wind_strength`, `grenade_fuse_seconds`, `turn_time_limit`, `friendly_fire`, `procedural_seed`, `map_width`, `map_height`, `teams_per_player`, `input_scheme`.
- Documented how **`validate()`** clamps each field, and where **`friendly_fire`** must be enforced (`systems/explosions.lua`).
- Clarified **session** (`scores` / match wins) vs **`rounds_to_win`** (per-match target).

### Build-on-current-code

- Marked what **exists** vs what’s **missing**: `main.lua` → `require("app")` but **`src/app.lua` is absent** in the tree — flagged as boot-blocking.
- Pointed at real modules (`session`, `mapgen/init`, etc.) instead of a greenfield story.
- File tree is split into **present** + **add** (`app`, `scene_manager`, `scenes/`, `input/`, `systems/`).

No `.lua` or other implementation files were added—only the pipeline markdown design doc.

## Files Created/Modified
- .pipeline/love-architect-design.md
- .pipeline/love-ux-design.md
