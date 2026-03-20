# Stage: release (release)

## Summary

Running pre-flight checks and inspecting the repository to prepare the release.





























Checking remote state and running tests. No standard version file found — we'll add a root `package.json` with version `0.1.0` so we can tag per your requirements.









Adding `package.json` at `0.1.0` (initial release). Updating the README with a concise Features section and version note.


































Creating and pushing `main` from the repository root so we can open a PR against it.





























## Release prep complete

### What changed
- **README** — Added a **Features** section (Worms-style combat, procedural rounds, 5 moles per side, match setup including HP, session match wins, `shared_kb` / `dual_gamepad`, VFX/SFX) and a short note that **SemVer** lives in `package.json` with tags like `v0.1.0`.
- **Version** — Added root **`package.json`** with **`0.1.0`** (no other listed version file existed). Treating this as the **initial** SemVer for the playable build.
- **Git** — Commit `dfc46e4`: `chore(release): prepare v0.1.0 for PR`. Branch **`initial-build-V1`** pushed; annotated tag **`v0.1.0`** pushed.

### PR
- **Pull request:** [worminess#1](https://github.com/cjaherne/worminess/pull/1) — `initial-build-V1` → **`main`**, not merged.

### Base branch `main`
`main` was **missing** on the remote (only `initial-build-V1` existed), so `gh pr create --base main` failed until **`main`** was created at the repo’s root commit (`90f46a8`) and pushed. You may want to set the GitHub **default branch** to `main` under repo settings after you’re happy with the workflow.

### Tests
**`busted`** is not installed in this environment, so tests weren’t run here; the PR body still lists `love .` and `busted` in the test plan.

### Tag order
Branch was pushed first, then **`v0.1.0`** was created and pushed, then the PR was opened, matching your requested sequence.

## Files Created/Modified
- (none)

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess" && git status && git branch --show-current && git log main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git status; git branch --show-current; git log main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git branch -a; git remote -v`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git fetch origin main 2>&1; git log origin/main..HEAD --oneline 2>&1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git ls-remote --heads origin; git log --oneline -30`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh repo view --json defaultBranchRef 2>&1; busted 2>&1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git add -A; git status`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git commit --trailer "Made-with: Cursor" -m "chore(release): prepare v0.1.0 for PR" -m "- README: feature overview, session scoring, input modes, SemVer note" -m "- package.json: initial 0.1.0 for release tags" -m "Bumps version from unversioned to 0.1.0."`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git push -u origin HEAD`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git tag -a v0.1.0 -m "v0.1.0: initial local multiplayer moles artillery"; git push origin v0.1.0`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git fetch origin; git branch -r`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr create --base main --title "chore(release): prepare v0.1.0 for PR" --body @"
## Summary
This branch delivers **Moles**, a styled local 2-player Worms-like artillery game for LÖVE 11.x: procedural rounds, rockets and grenades, match configuration (including mole HP), session match-win scoring, and shared keyboard/mouse or dual gamepad input. Release prep adds SemVer metadata and README coverage of the shipped feature set.

## Changes
- **Gameplay / UX** (prior commits on branch): turn-based combat, weapons, explosions, VFX/SFX, match setup, pause, game over, HUD, roster/turn rotation, input schemes.
- **Release prep** (this PR): expanded README (**Features**, version note); root **package.json** at **0.1.0** for SemVer and **v0.1.0** git tag.

## Version
\`(none)\` → \`0.1.0\` (initial / minor pre-1.0)

## Test plan
- [ ] Build passes
- [ ] Key files reviewed: README.md, package.json, conf.lua, src/scenes/play.lua, src/game/match_config.lua

Made with [Cursor](https://cursor.com)
"@`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git rev-list --max-parents=0 HEAD`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git push origin 90f46a8fcf23bb7dffcb06f225e7bd2ab0815f68:refs/heads/main`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git log main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git fetch origin main; git log origin/main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git rev-parse origin/main; git log origin/main -1 --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr create --base main --head initial-build-V1 --title "chore(release): prepare v0.1.0 for PR" --body @"
## Summary
This branch delivers **Moles**, a styled local 2-player Worms-like artillery game for LÖVE 11.x: procedural rounds, rockets and grenades, match configuration (including mole HP), session match-win scoring, and shared keyboard/mouse or dual gamepad input. Release prep adds SemVer metadata and README coverage of the shipped feature set.

## Changes
- **Gameplay / UX** (branch history): turn-based combat, rockets/grenades, wind, terrain destruction, match setup with validation, pause, game over, HUD, roster and turn rotation, procedural mapgen each round, VFX/SFX, input schemes (\`shared_kb\` / \`dual_gamepad\`).
- **Release prep** (latest commit): README **Features** section and SemVer note; root **package.json** at **0.1.0**; git tag **v0.1.0** pushed.

## Version
\`(none)\` → \`0.1.0\` (initial SemVer / pre-1.0 minor)

## Test plan
- [ ] Build passes (\`love .\` from project root)
- [ ] \`busted\` passes when LuaRocks/busted is installed (see TESTING.md)
- [ ] Key files reviewed: README.md, package.json, conf.lua, src/scenes/play.lua, src/game/match_config.lua

Made with [Cursor](https://cursor.com)
"@`
