# Stage: design (core-code-designer)

## Summary

Investigating how `config.defaults` is required and what the build checks expect so we can write an accurate DESIGN.md.









Running the build and tests to capture the failure mode.







































Confirming: LÖVE maps dotted module names to nested paths, so `require("config.defaults")` resolves to `src/config/defaults.lua`, not `src/config.defaults.lua`. The handoff doc notes this. Writing `DESIGN.md` as the implementation blueprint.




`DESIGN.md` is updated at the repo root as the blueprint for this task.

### What the design concludes

- **Cause:** LÖVE’s `require` turns dots in the module name into path segments under each `?.lua` template, so `require("config.defaults")` looks for **`src/config/defaults.lua`**, not `src/config.defaults.lua`. That mismatch is why the module is “missing” at runtime even when a flat `config.defaults.lua` file exists.
- **Fix:** Move the module to **`src/config/defaults.lua`**, keep all `require("config.defaults")` call sites as they are, then update **`spec/spec_helper.lua`** (sentinel path + preload `loadfile` target), **`tools/release-check.mjs`** (add the new path to the required list), and path mentions in **`TESTING.md`** / **`ASSETS.md`**.

The document also spells out the **returned config table shape**, a **checklist for the Coding Agent**, optional preload cleanup after tests, and **verification** (`npm run build`, `love .`, busted). Prior long-form game-design content that lived in the old `DESIGN.md` is not duplicated here; the new file points at **`.pipeline/*.md`** and the rest of the repo for that material.

## Files Created/Modified
- DESIGN.md

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess" && npm run build && (busted 2>&1 || lua -e "print('no busted')")`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; npm run build; busted`
- `where.exe lua 2>$null; where.exe luajit 2>$null`
