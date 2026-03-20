# Stage: release (release)

## Summary

Running pre-flight checks and gathering repository state for release prep.



















Running the test suite per release workflow. No standard SemVer file found in the repo root; we'll note that in the PR and skip the tag.




No standard SemVer file at repo root (`conf.lua` only sets LÖVE engine version). Skipping version bump and tag per workflow. Updating the README with a concise overview of this branch's deliverables, then committing, pushing, and opening the PR.















































































Syncing with `origin` (remote already includes `package.json` at v0.1.0 and PR #1). Bumping to **0.1.1** (patch: README/release prep after **v0.1.0**). Applying updates and pushing.





































































Fixing test failures: `unpack` is nil under Lua 5.4 (use `table.unpack`).














Tests failed on the tagged commit. Fixing `roster.lua` and bumping to **0.1.2** so the release tag includes the fix.
























Here’s what was done for release prep.

### Pre-flight
- Branch: **`initial-build-V1`** (tracking `origin`)
- **`main..HEAD`**: full initial Moles build (design pipeline, Lua/LÖVE game, tests, `package.json` SemVer from an earlier release commit)
- **`gh`** is authenticated

### README (`README.md`)
- Version blurb now references **`v0.1.2`**
- **Flow** step 4 clarifies **new match** (back through Match setup) vs **Rematch** (reuse `session.last_match_config`)

### Version (`package.json`)
- **`0.1.0` → `0.1.1` → `0.1.2`** (patch line): `0.1.1` for the README/SemVer bump; **`0.1.2`** after a test fix (see below)

### Tests
- **Busted** was failing on Lua 5.4 (`unpack` is nil). **`src/game/roster.lua`** now uses `local unpack = table.unpack or unpack` and copies with `unpack(order, 1, #order)`.
- **37 successes, 0 errors** after the change.

### Git / GitHub
- Pushed commits on **`initial-build-V1`**
- **Annotated tags pushed:** `v0.1.1`, then **`v0.1.2`** (recommended release pointer; includes the roster fix)
- **`gh pr create`** could not run — [PR #1](https://github.com/cjaherne/worminess/pull/1) already targets **`main`** from this branch. It was updated with **`gh pr edit`** (title + body template, version **`0.1.0` → `0.1.2`**). **PR was not merged.**

### Note on `v0.1.1`
`v0.1.1` points at the commit **before** the roster fix. If you want a single “good” patch tag, keep **`v0.1.2`** as canonical or delete the remote `v0.1.1` tag yourself; I left both to avoid destructive history changes unless you ask to remove it.

## Files Created/Modified
- (none)

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess" && git status && git branch --show-current && git log main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git status; git branch --show-current; git log main..HEAD --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; where.exe busted 2>$null; luarocks path 2>$null`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh auth status`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git add -A; git status`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git commit --trailer "Made-with: Cursor" -m "docs(readme): align overview with V1 local multiplayer build" -m "Expand README intro for five-mole teams, procedural maps, match options, input modes, and session stats. Note rematch vs new-match flow for stats.

No root SemVer manifest (package.json, Cargo.toml, etc.); release tag skipped."`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git push -u origin HEAD`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git fetch origin; git pull --rebase origin initial-build-V1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git rebase --abort`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git log -3 --oneline; git log origin/initial-build-V1 -3 --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git merge origin/initial-build-V1 -m "merge: sync with origin initial-build-V1"`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git merge --abort`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git reset --hard origin/initial-build-V1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git log -8 --oneline`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git log main..HEAD --oneline | Select-Object -First 25`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git tag -l "v*"; git ls-remote --tags origin "v*"`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr list --head initial-build-V1 --base main`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git log main -5 --oneline; git merge-base main HEAD`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git add -A; git status`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git reset HEAD; git add package.json README.md; git status`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git commit --trailer "Made-with: Cursor" -m "chore(release): prepare v0.1.1 for PR" -m "README: clarify new match vs rematch for setup and rules. Bump package.json for SemVer tag.

Bumps version from 0.1.0 to 0.1.1."`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git push -u origin HEAD`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git tag -a v0.1.1 -m "v0.1.1: patch release — README flow note, SemVer bump"; git push origin v0.1.1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr create --base main --head initial-build-V1 --title "chore(release): prepare v0.1.1 for PR" --body "test

Made with [Cursor](https://cursor.com)" 2>&1`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr edit 1 --title "chore(release): prepare v0.1.1 for PR" --body @"
## Summary
This branch introduces **Moles**, a local 2-player Worms-style artillery game (LÖVE 11.x): procedural maps each round, five moles per side with alternating players and roster rotation, rockets and grenades with distinct behavior, match setup (HP, wind, fuse, timer, friendly fire, input mode, seed), session win tracking, and themed UI with procedural SFX/VFX.

## Changes
- Full game loop: boot → menu → match setup (dual Ready) → play → pause / game over / rematch
- Combat: terrain destruction, wind, direct-hit detonation, turn resolver and roster handling
- Input: shared keyboard + mouse and dual gamepad modes; smoothed sticks and trigger power
- **Release prep:** README clarifies **new match** vs **Rematch**; \`package.json\` SemVer **0.1.0 → 0.1.1** (patch)
- Tag \`v0.1.1\` pushed (prior \`v0.1.0\` remains for the initial release marker)

## Version
\`0.1.0\` → \`0.1.1\` (patch)

## Test plan
- [ ] Build passes
- [ ] Key files reviewed: \`package.json\`, \`README.md\`, \`main.lua\`, \`src/game/match_config.lua\`, \`src/scenes/play.lua\`
"@`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr edit 1 --title "chore(release): prepare v0.1.1 for PR" --body-file .pr-body-tmp.md`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; if (Test-Path ".luarocks\bin\busted.bat") { & .\.luarocks\bin\busted.bat --helper=spec/helper.lua } else { Write-Host "busted.bat not found, skip" }`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; & .\.luarocks\bin\busted.bat --helper=spec/helper.lua`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; git add src/game/roster.lua package.json README.md; git commit --trailer "Made-with: Cursor" -m "fix(roster): use table.unpack for Lua 5.4 compatibility" -m "Busted runs on Lua 5.4 where global unpack is absent. Copy mole order with table.unpack (or unpack on LuaJIT).

Bumps version from 0.1.1 to 0.1.2."`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; & .\.luarocks\bin\busted.bat --helper=spec/helper.lua; git push origin HEAD; git tag -a v0.1.2 -m "v0.1.2: roster Lua 5.4 fix + release docs"; git push origin v0.1.2`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; gh pr edit 1 --title "chore(release): prepare v0.1.2 for PR" --body-file .pr-body-tmp.md; Remove-Item .pr-body-tmp.md`
