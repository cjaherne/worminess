# Stage: design (love-ux)

## Summary

Reading the codebase and existing UX design to update `.pipeline/love-ux-design.md` so it aligns with implemented data modules and `conf.lua`.



















Updating `.pipeline/love-ux-design.md` to align with `conf.lua`, `src/data/match_settings.lua`, `src/data/session_scores.lua`, `src/config/defaults.lua`, and the architect’s scene names (`MainMenu`, `MatchSetup`, `Play`, etc.).




## Done

**Updated:** `.pipeline/love-ux-design.md` so the UX spec matches the **current repo** and stays merge-ready for root `DESIGN.md`.

**What changed**

- **§0 Codebase baseline** — Ties UX to `conf.lua` (1280×720, min 960×540, 11.4), `main.lua` → future `src/app.lua`, and the real modules **`src/data/match_settings.lua`**, **`src/data/session_scores.lua`**, **`src/config/defaults.lua`**, with pseudocode for `merge_partial` / `get_snapshot` / `record_match_outcome`.
- **Scene mapping** — UX ids mapped to architect names (`MainMenu`, `MatchSetup`, `Play`, `Pause`, `RoundEnd`, `MatchEnd`) and suggested `src/scenes/*.lua` paths.
- **Data alignment** — Match setup controls match **validated** fields: `mole_max_hp`, `first_player`, `friendly_fire`, `turn_time_seconds`, `map_seed`, `input_mode` (`shared_kb` / `dual_gamepad`), `wind`, fixed **5** moles; session HUD uses **`get_snapshot()`** keys (`gamesPlayedP1`, etc.).
- **Team chrome** — HUD must use **`defaults.colors.team1` / `team2`**.
- **§3.2** — Expanded match-variables table; **`input_mode`** copy for shared KB vs dual pads.
- **§7 / §8 / §10** — File tree and components reference **existing** `src/` layout and “no duplicate validation” rule.
- **§11 JSON** — Full wireframe regions (title, setup, gameplay HUD, **pause modal**, results), flows including **pause**, plus `dataModuleFields` for orchestrator merge.

No implementation files (`.lua` gameplay/UI) were added—only this design doc.

## Files Created/Modified
- .pipeline/love-ux-design.md
