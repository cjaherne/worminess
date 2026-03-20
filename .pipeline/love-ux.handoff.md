# Stage: design (love-ux)

## Summary

Gathering project requirements and pipeline context so we can produce a concrete UX design document.




Workspace is greenfield (only `REQUIREMENTS.md`). Creating a LÖVE2D-focused UX design that maps to R1–R11 and naming scene/state labels the architect can align with.




## Summary

Deliverable is **`.pipeline/love-ux-design.md`** — UX-only spec for the LÖVE “moles” clone, aligned with `REQUIREMENTS.md` R1–R11 and BigBoss’s brief (flows, match settings, dual input, HUD).

**What it specifies**

- **Scene labels** for the architect: `scene_title`, `scene_match_setup`, `scene_gameplay`, `scene_match_results`, plus `overlay_pause` and an optional `scene_round_summary`.
- **1280×720** logical layout with **pixel regions** for title card, two-column match setup (per-player input + team preview), gameplay HUD (turn banner, session mini-score, weapon/aim panel, roster bar), pause modal, and results.
- **View-model contract** (`SessionView`, `MatchView`, `TurnView`, etc.) so UI reads state without owning simulation.
- **Default controls:** shared keyboard/mouse (non-overlapping P1/P2 keys, mouse aims only for the active player) and per-player gamepad mappings; pause on Esc/Start.
- **Accessibility:** contrast targets, font sizes, P1/P2 not color-only, in-world readability for shots/explosions.
- **Suggested tree** under `assets/` and `src/ui/` (names only — no Lua implementation).

**Structured JSON** for orchestrator merge is included at the end of that file under §11.

No `.lua` or other implementation files were added.

## Files Created/Modified
- .pipeline/love-ux-design.md
