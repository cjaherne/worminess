# Stage: design (game-designer)

## Summary

Reading project requirements and pipeline context so the design aligns with the repo.




Writing the game-designer document: aligning with REQUIREMENTS.md (R1–R11), BigBoss (rockets, grenades, rotation, teams, 2P local), and the handoff contract.




Tightening the turn-advance pseudocode so the mole-rotation rule is unambiguous for implementers.




Here’s what was delivered.

## Output

**File:** `.pipeline/game-designer-design.md`

It’s a **design-only** blueprint for a LÖVE **11.4** “moles” Worms-like game, aligned with `REQUIREMENTS.md` (R1–R11) and the BigBoss brief (rockets, grenades, **player + mole rotation**, teams, 2P local).

### Highlights

- **`requirementsChecklist`:** One checkbox per requirement (presentation, clone scope, core mechanics, rocket, grenade, 2P local, proc maps, session score, 5 moles each, alternating players, mole roster rotation, match vars including health, shared KB+M, dual gamepads, team dynamics).
- **Turn model:** Alternating human turns; **when a player ends their turn**, advance **that** player’s mole index to the **next living mole** (skip dead). Opponent’s index unchanged. First turn of the match uses each team’s first living mole without a pre-play advance.
- **Weapons:** Rocket vs grenade called out for **trajectory, detonation, terrain, and silhouette** (trail vs round + fuse telegraph).
- **Controls:** Semantic actions plus concrete **shared-keyboard** and **dual-gamepad** suggestions; **mouse** only for the **active** turn owner in hotseat.
- **Game loop:** States (menu → setup → play → pause / match over), update/draw responsibilities, optional turn phases.
- **Handoff:** Light **`fileStructure`** hints only; **art naming** under `assetStructure`; **persistence** = session wins only per R6; **`implementationOrder`** for the coder.

No implementation files were added—only this markdown design doc. If you want the checklist to mirror exact R1–R11 wording one-to-one, that can be adjusted in a follow-up edit.

## Files Created/Modified
- .pipeline/game-designer-design.md
