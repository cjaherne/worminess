# Stage: design (love-ux)

## Summary

Reading the current UX design doc and codebase to reconcile scene IDs and restore any truncated sections.














Updating `.pipeline/love-ux-design.md`: aligning with the codebase and love-architect scene names (`play`, `game_over`, etc.), binding view-models to `session.lua`, `match_config.lua`, and `turn_state.lua`, and adding a reconciliation section.



























































## Done

Updated **`.pipeline/love-ux-design.md`** so it matches the **real repo** and **love-architect** scenes, and fixed the JSON fence (there was an **extra trailing ` ``` `** after §10).

### Reconciliation (scene IDs)

| Earlier UX label | Canonical (architect / `src/scenes/`) |
|------------------|----------------------------------------|
| `playing` | **`play`** |
| `match_summary` | **`game_over`** with variants **`round_end`** / **`match_end`** |
| `title` | **Title splash** inside **`boot`** or first paint of **`main_menu`** (documented; no orphan scene) |
| `round_interstitial` | **Toast / HUD overlay** while **`play`** is top, driven by **`turn_state.phase`** (`interstitial`, `round_end`) |

### Codebase alignment

- **`conf.lua`** / **`constants.lua`**: 1280×720 noted as already aligned.
- **§3** now maps UI to **`session.lua`** (`scores`, `matches_completed`, `last_match_config`, `bump_match_win`), **`match_config.lua`** (all validated fields + `input_scheme`), **`turn_state.lua`** (`phase`, `active_player`, `active_mole_slot`, weapons, move budget, etc.), plus **`roster`** / mole HP.
- **`match_setup`**: expanded for **rounds to win**, **wind**, **fuse**, **turn timer**, **friendly fire**, **`shared_kb` / `dual_gamepad`**, and **dual Ready** chips per product brief.
- **§2**: `src/scenes/` + thin **`src/ui/compose/*`** and **`play_hud.lua`** (renamed from `playing_hud`).
- **§10 JSON**: `userFlows`, `wireframes`, and `interactions` use architect scene names; **`gameOverVariants`** added.
- **§11**: celebration target corrected to **`game_over (match_end)`**.

If you want **`src/app.lua`** mentioned only when it exists in-tree, we can soften that line—but it already matches your **`main.lua`** contract.

## Files Created/Modified
- .pipeline/love-ux-design.md
