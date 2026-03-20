# Stage: design (love-architect)

## Summary

Reading `.pipeline/love-architect-design.md` and updating it to align with the merged DESIGN and apply overseer deduplication guidance.




Checking whether `src/app.lua` exists and scanning `DESIGN.md` for the repository snapshot section:




Updating `.pipeline/love-architect-design.md`: pointing to unified `DESIGN.md` as authoritative (no repeated product brief), adding `src/ui/*` and play-scene interstitial contract, and documenting overseer guidance for deduplicating `DESIGN.md`'s duplicate "Original task" blocks — we won't edit `DESIGN.md` (pipeline rule).




Updated [`.pipeline/love-architect-design.md`](C:\Users\Chris\Documents\GitHub\worminess\.pipeline\love-architect-design.md) with these changes:

### Overseer: dedupe / drift
- **No repeated “Original task”** in this pipeline doc — it points once to [`DESIGN.md`](DESIGN.md) § *Original task (source of truth)*.
- **§0** records orchestrator guidance: `DESIGN.md` currently has **two identical** original-task blocks; keep the first as canonical or mark the second *non-authoritative*. This agent still does **not** edit `DESIGN.md` (pipeline rule).

### Aligned with unified `DESIGN.md`
- **§1** treats [`DESIGN.md`](DESIGN.md) § *Repository snapshot* as authoritative; this doc only adds **architect-verified gaps** (e.g. missing `src/app.lua`) and lists **`src/ui/*`** with the other expected additions.
- **Session stats:** cross-reference only — points to [`DESIGN.md`](DESIGN.md) § *Session stats definition* (`scores` = match wins, `matches_completed` = finished matches).
- **Play / UX contract:** **round interstitial** via `turn_state.phase` (`interstitial` / `round_end`) **while stack top stays `play`**, matching the merged UX checklist.
- **Scene names:** explicit alignment (`play`, `game_over`).
- **§11 conflict rule:** behaviour prefers more specific [`DESIGN.md`](DESIGN.md); this file owns **wiring** (files, requires, lifecycle).

### Structure cleanup
- Removed the long duplicate file table from the old §0 (replaced by cross-reference + deltas).
- Removed the stale note that root `DESIGN.md` claimed no `src/` — merged `DESIGN.md` already has the authoritative snapshot.

Still **design-only** — no `.lua` or other implementation files touched.

## Files Created/Modified
- .pipeline/love-architect-design.md
- .pipeline/love-ux-design.md
