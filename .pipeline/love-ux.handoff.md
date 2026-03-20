# Stage: design (love-ux)

## Summary

Reviewing `.pipeline/love-ux-design.md` and key sim modules so we can produce a complete, self-contained UX spec in `.pipeline/love-ux-design.md` (per pipeline rules we won't edit `DESIGN.md`).









Updating `.pipeline/love-ux-design.md`: fixing paths (`src/config.defaults.lua`), aligning the turn/HUD contract with `src/sim/turn_state.lua`, enriching wireframes with element inventories, expanding flows (pause/forfeit/rematch) and menu navigation, and adding a merge appendix for `DESIGN.md`.









## Update complete

Per pipeline rules, only **`.pipeline/love-ux-design.md`** was changed (not root `DESIGN.md`). The UX spec is expanded so an orchestrator can paste it into `DESIGN.md` **without losing content**.

### Changes

- **§0 — Repo alignment:** Uses **`src/config.defaults.lua`** (not `config/defaults.lua`); adds **`src/sim/turn_state.lua`**, **`terrain_gen.lua`**, and brief UX notes for **`terrain` / `damage` / `physics`**.
- **§1.3 — `TurnView`:** Matches **`turn_state`** (`active_player`, `mole_slot`, `turn_time_left`, phases); **`CombatHudView`** mentions live grenade fuse vs **`weapon.grenade_fuse`** from defaults.
- **§3 — Wireframes:** **Element inventories** under title, setup, and gameplay HUD so layouts are explicit.
- **§4 — Flows:** Turn timer behavior, **pause**, **forfeit + confirm**, **rematch / new setup / title**, dual-pad warning, and a **mermaid** state diagram.
- **§5 — Input:** **§5.5** menu/setup gamepad navigation (confirm/back, defaults).
- **§6 — Accessibility:** Slightly expanded in-world / optional damage numbers note.
- **§8 — Components:** Adds **`TurnTimerReadout`**, **`WindReadout`**, **`ConfirmDialog`**, **`LoadingBanner`**.
- **§10:** Correct **`require("config.defaults")`** for team colors.
- **§13 — Merge checklist:** Tells the orchestrator exactly which sections must land in **`DESIGN.md`** so the merged doc stays **self-contained** (addresses overseer feedback without editing `DESIGN.md` from this agent).

Opening note now states that **§2–§8**, **§11**, and **§12** are the primary block to merge under something like **`## LÖVE UX — Screens, HUD, flows, and input`**.

## Files Created/Modified
- .pipeline/love-ux-design.md
