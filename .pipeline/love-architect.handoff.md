# Stage: design (love-architect)

## Summary

Reading the architect design and `turn_state.lua` to align §4.1 with the Game Designer model and fix the R10 crosswalk.














Updating the design doc: aligning §2 with the repo (`src/config.defaults.lua`, existing `src/sim/*`), rewriting §4.1 to defer to the Game Designer's pseudocode as normative, and narrowing the R10 crosswalk to shared keyboard+mouse only.
























Noting a possible mismatch: `turn_state.lua`'s `advance_after_turn` may re-select the current slot. Adding a coding-agent note to align with the Designer's ring-advance.




Here’s what was updated in [`.pipeline/love-architect-design.md`](.pipeline/love-architect-design.md):

### §4.1 — Defer to Game Designer pseudocode
- **Normative behavior** is explicitly the **`DESIGN.md` → Game Designer → “Turn model”** block (`on_match_start`, `on_end_turn`, `advance_mole_index`), with `.pipeline/game-designer-design.md` as a duplicate for history.
- Stated clearly: **if anything disagrees, that `DESIGN.md` pseudocode wins**; §4.1 is **routing/mapping**, not a second ruleset.
- Removed the duplicate architect pseudocode block; replaced with a **table** mapping designer concepts → `src/sim/turn_state.lua` (`active_player`, `mole_slot`, `M:end_turn`, `M:update_timer`, etc.).
- Added a **coding-agent** bullet: ring advance must match designer semantics (**at least one step** on the roster); flag to reconcile `M:advance_after_turn` if it can keep the same living slot after end-turn.

### §12 — R10 crosswalk (shared KB+M only)
- **R10** now points only to **`keyboard_mouse.lua`** (and `DESIGN.md` for bindings), scoped to **`shared_kb`**. `input_manager.lua` is **not** listed on R10.

### §2 + §10 — Repo alignment
- Baseline and tree updated for **`src/config.defaults.lua`** (not `src/config/defaults.lua`) and **existing** `src/sim/*` (`terrain`, `terrain_gen`, `physics`, `damage`, `turn_state`).
- Optional **`keymaps_shared.lua`** moved under **`src/input/`**.
- §10 item 4 references **`src/config.defaults.lua`** and **`keyboard_mouse.lua`** for R10.

### §4 component table + JSON
- `turn_state.lua` row now cites **`DESIGN.md`** + §4.1 mapping.
- JSON **considerations** includes normative turn spec in **`DESIGN.md`**.

No `.lua` files were edited—design markdown only.

## Files Created/Modified
- .pipeline/love-architect-design.md
- .pipeline/love-ux-design.md
