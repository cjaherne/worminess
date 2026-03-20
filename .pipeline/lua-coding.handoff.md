# Stage: coding (lua-coding)

## Summary

Reading DESIGN.md, REQUIREMENTS.md, and scanning the codebase for `config.defaults` references.




Creating `src/config/defaults.lua`, removing the old file, and updating references. Reading `TESTING.md`, `ASSETS.md`, and `CODING_NOTES.md`.














Creating the nested module path, updating the spec helper and release check, and documenting REQUIREMENTS.md traceability in CODING_NOTES.md.




Checking `path_join`: it only accepts three arguments; calls with four segments are incorrect.




Fixing `path_join` usage: it accepts only three parameters, so four-argument calls dropped `defaults.lua`.


























































Here is what was wrong, what changed, and how it was checked.

### Cause (R1)

With `love.filesystem.setRequirePath("src/?.lua;…")`, `require("config.defaults")` resolves to **`src/config/defaults.lua`** (dots → path segments). A single file **`src/config.defaults.lua`** never matched that pattern, so the module looked “missing” even though the table existed.

### Fix (R2)

- **Added** `src/config/defaults.lua` (same `return { … }` as before).
- **Removed** `src/config.defaults.lua`.
- **`spec/spec_helper.lua`**: repo-root detection, `package.preload["config.defaults"]` `loadfile` target, and comments now use `src/config/defaults.lua`. `path_join` only takes three parameters, so paths are built as `path_join(path_join(root, "src", "config"), "defaults.lua")` (four-part paths were wrong before and would have truncated to `…/config` without `defaults.lua`).
- **`tools/release-check.mjs`**: `src/config/defaults.lua` is in the `required` list so `npm run build` fails if it is missing.
- **`TESTING.md`**, **`ASSETS.md`**: paths/wording updated.
- **`CODING_NOTES.md`**: table for **REQUIREMENTS.md R1–R3** with traceability and R3 verification notes.
- **`.pipeline/game-art.handoff.md`** and **`.pipeline/context-cache.json`**: file map entry updated for consistency.

`require("config.defaults")` at call sites is unchanged, as in the design.

### Verification (R3)

- **`npm run build`** — succeeds (`release check ok`).
- **Busted / `lua` on PATH** — not available here; **`CODING_NOTES.md`** records that. **`love.exe`** is at `C:\Program Files\LOVE\love.exe` for a local `love .` smoke test.

Other `.pipeline/*.md` files still mention the old filename in historical snippets; the design called those optional and they are not required for the game or `npm run build`.

## Files Created/Modified
- ASSETS.md
- CODING_NOTES.md
- TESTING.md
- spec/spec_helper.lua
- src/config.defaults.lua
- tools/release-check.mjs

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess" && npm run build`
- `where lua 2>nul; where busted 2>nul; where love 2>nul`
- `Set-Location "C:\Users\Chris\Documents\GitHub\worminess"; npm run build`
- `Get-Command lua, busted, love -ErrorAction SilentlyContinue | Format-Table Name, Source -AutoSize`
- `cmd /c "where lua 2>nul"`
