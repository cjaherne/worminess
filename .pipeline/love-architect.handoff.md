# Stage: design (love-architect)

## Summary

Reading the architect design, `turn_state.lua`, and the game designer turn model to align §4.1 and the R10 crosswalk with the repo and merged DESIGN.md.









Updating the architect design to reflect the implemented codebase, merged DESIGN.md Part A (normative turn model + override clause), and overseer R10/input_manager clarity.



















Summary of updates to [`.pipeline/love-architect-design.md`](.pipeline/love-architect-design.md):

### As-built architecture (§1–2, §5–7, §9)
- **Scene flow** matches `src/app.lua`: `menu` → `match_setup` → `play` / `pause` → `match_end`, plus `app.quit_match_to_results` / `app.end_match`.
- **§2** is an **as-built tree**: `assets/sprites/`, `src/audio/sfx.lua`, `src/render/*`, `src/ui/hud.lua`, `src/util/viewport.lua`, `src/util/gamepad_menu.lua`, `tools/gen_sprites.mjs`, and root docs (`CODING_NOTES.md`, `ASSETS.md`, `README.md`). Removed obsolete `[add]` / `boot` / `round_end` entries.
- **§5** describes **current** `terrain_gen` usage and consumers instead of a greenfield recipe.
- **§6** documents **`app.quit_match_to_results`** → `session_scores.record_match_outcome`.
- **§7.3** matches real `app.load` (sprites, SFX, `push("menu")`, viewport).
- **§9** `require` graph updated for viewport, audio, and play drawing through scenes.

### §4.1 — Overseer: default = Game Designer pseudocode
- States clearly: **normative spec** is **`DESIGN.md` Part A** — *Turn model* pseudocode.
- Quotes the merged doc rule: **that pseudocode overrides conflicting architecture prose** (including this file).
- Adds a short **symmetric same-slot** summary with “pseudocode wins on edge cases.”
- **As-built table** tied to `turn_state.lua` (`advance_after_turn` with ring step ≥ 1, `end_turn`, `update_timer`, `active_mole`).
- Removed the old “reconcile if same slot” warning; current `advance_after_turn` matches the designer intent.
- **Maintenance:** `end_turn` advances **`active_player`**’s roster, then switches turn — callers must preserve that invariant.

### R10 / input (Overseer)
- **`input_manager.lua`** row: **R10 is not the traceability owner**; R10 lives in **`keyboard_mouse.lua`** only; R11 in **`gamepad.lua`**.
- **§12 R10** unchanged: still **`keyboard_mouse.lua`** only for shared KB+M (`shared_kb`).
- **§10** item 2 uses **`turn_state:active_mole(moles)`**.

### Other
- **§3.1** `MatchSettings` shape aligned with **`match_settings.lua`** (`wind`, `first_player`, `friendly_fire`, `map_seed`, etc.).
- **§3.3** turn state description matches the real fields (no fictional `phase` enum).
- **§11 JSON** `luaModules` expanded for keyboard/gamepad, viewport, audio, and corrected `turn_state` API names.

No `.lua` or other implementation files were changed—design markdown only.

## Files Created/Modified
- .pipeline/love-architect-design.md
