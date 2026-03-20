# Stage: design (game-designer)

## Summary

Reviewing the game-designer design and architect handoff for conflicts, then updating the turn model per overseer feedback.




Resolving a conflict: bullets 4–5 implied advancing when a turn begins, while the pseudocode advances on `on_end_turn`. Architect doc mentions advancing the other team. Declaring symmetric same-slot intent, making the pseudocode normative, and aligning prose with the pseudocode. Updating the repo baseline to reference existing files.









Here’s what changed in `.pipeline/game-designer-design.md`:

### Overseer feedback

- **Symmetric same-slot turns** are now stated explicitly: each player’s roster index moves **only when that player ends their turn**, so after P1 then P2 both have advanced once and (until deaths) both sides stay on the **same slot number**.
- A **normative line** was added: the **`on_end_turn` / `advance_mole_index` pseudocode wins** over any other pipeline text (including LÖVE Architect wording about advancing the other team or advancing on turn **start**).

### Prose fixes

- Numbered bullets **4–6** were rewritten so they **match the pseudocode** (the old bullet 5 wrongly said the roster advances when a turn **begins again**).
- The pseudocode section title now says **normative** (still “design intent, not drop-in code”).
- **Repo baseline** mentions `main.lua` → `app`, `match_settings.lua`, `session_scores.lua`, and root `DESIGN.md`.
- **Persistence** points R6 at `src/data/session_scores.lua` and match options at `match_settings.lua`.
- **Notes for Coding Agent** tells implementers not to advance the inactive player’s roster on turn end.

No implementation files were added—only this design doc was updated. If you want LÖVE Architect’s `love-architect-design.md` §4.1 edited to match, that would be a separate agent pass (or orchestrator merge).

## Files Created/Modified
- .pipeline/game-designer-design.md
- .pipeline/love-architect-design.md
