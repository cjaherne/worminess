# Stage: design (love-ux)

## Summary

Reading `DESIGN.md` and `.pipeline/love-ux-design.md` to fix section references and align with the merged design.




Updating `.pipeline/love-ux-design.md`: adding a canonical handoff section with `DESIGN.md` anchors, replacing fragile § cross-refs, and aligning the controls example with the merged `DESIGN.md`.
























## Updates to `.pipeline/love-ux-design.md`

### 1. **Handoff block (after codebase note)**
- Maps topics to **named sections in repo-root `DESIGN.md`**: **MatchConfig — single consolidated schema**, **Session stats definition**, **UX — scene graph & wireframes → `match_setup` (dual column)**, **requirementsChecklist — UX**.
- States explicitly that **`.pipeline/love-ux-design.md`** stays **canonical** for full wireframes (§5), widget/copy table (§3.2), §6–7, and §10 JSON when `DESIGN.md` is short; **conflict order:** `DESIGN.md` (MatchConfig + session rules) → `src/game/*.lua`.

### 2. **Replaced fragile / legacy cross-refs**
- `match_setup` row: no longer “see §3”; it points to **`DESIGN.md` MatchConfig table** + **`match_setup` (dual column)** + **§5.3** for pixels.
- `game_over` row: **`DESIGN.md` Session stats** + **§9** (this file).
- Transitions: **§10** + **`DESIGN.md` UX JSON**.
- **§3.1 Session:** tied to **`DESIGN.md` — Session stats definition**; copy clarifies **wins vs matches played**.
- **§3.2 Match config:** states **`DESIGN.md` MatchConfig** is the **authoritative** field list; §3.2 only adds **widget/copy** columns.
- **§3.3 / §6:** round tallies vs session fields clarified via **`DESIGN.md` Session stats definition**.
- **§5.3:** line at top linking **`DESIGN.md` `match_setup` (dual column)** to this pixel spec.
- **§6.2:** examples aligned with **merged `DESIGN.md` — Controls** (A/D, W/S, Shift, Space, 1/2); cites **`src/input/bindings.lua`** as the real source when it exists.
- **§6.3:** pause cross-ref ties **§5.5** to **`DESIGN.md` UX checklist**.
- **§1.1:** “see §4” → **§4 — Component breakdown (below)**.
- **§1.2 heading:** renamed to **architect (`src/scenes/`)** (no `.pipeline` file name).

### 3. **Component table**
- `screens.*` renamed to **`compose/*`** to match the file tree in §2.

---

Per instructions, **`DESIGN.md` was not edited** (design output stays under `.pipeline/`). If the orchestrator wants **`DESIGN.md` line 52** (“see love-ux §3.1”) updated to “**Session stats definition** (above) and **`.pipeline/love-ux-design.md` §3.1**”, that can be a separate merge edit.

## Files Created/Modified
- .pipeline/game-designer-design.md
- .pipeline/love-ux-design.md
