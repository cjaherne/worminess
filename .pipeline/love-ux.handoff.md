# Stage: design (love-ux)

## Summary

Exploring the codebase to align the UX design with existing structure, then writing `.pipeline/love-ux-design.md`.









Workspace is greenfield (no Lua sources yet). Producing a LÖVE2D UX design anchored to a concrete base resolution and aligned with typical scene names for architect handoff.




## Summary

**Written:** `.pipeline/love-ux-design.md` (design-only; no Lua or other implementation files).

**Grounding:** The repo snapshot had no game source yet (architecture brief listed 0 files), so the doc defines a **1280×720 logical canvas**, letterboxing, safe margins, and **proposed** `src/ui/` + `assets/` layout for the Coding Agent to match the architect merge.

**What it specifies:**

- **Scene states** (`boot` → `title` → `main_menu` → `match_setup` → `playing` → `pause` / `round_interstitial` / `match_summary`) with transitions.
- **HUD clusters** with logical pixel anchors: turn banner, corner scores, weapon strip, wind, optional grenade fuse, session score chip, hints.
- **2P input:** shared keyboard+mouse hot-seat vs two controllers; menu focus, confirm/back, and pause behavior; pad assignment UX in setup.
- **View-model fields** (`SessionModel`, `MatchOptions`, `TurnPresentation`, `InputRoutingMode`) so UI binds cleanly to gameplay.
- **Theme colors**, typography minimums, accessibility (contrast, no color-only cues, motion).
- **§10 JSON** block for orchestrator merge: `userFlows`, `wireframes`, `interactions`, `accessibility`, `recommendations`.

If you want the next pass to assume a different base resolution (e.g. 1920×1080) or mandatory split-screen cameras, say so and that section can be revised in a follow-up design edit.

## Files Created/Modified
- .pipeline/love-ux-design.md
