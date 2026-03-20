# Testing (Moles / LÖVE)

## Automated unit tests (Busted)

Pure Lua modules are covered with **[busted](https://lunarmodules.github.io/busted/)** specs under `spec/`. The helper `spec/spec_helper.lua` mirrors LÖVE’s `src/` require layout and registers `package.preload["config.defaults"]` so stock Lua resolves `src/config.defaults.lua` (Lua’s loader maps `config.defaults` to `config/defaults.lua` by default).

**Config:** `.busted` sets `helper` and disables **`auto-insulate`** so each spec file shares the same `package.*` (otherwise the helper’s loaders would not apply to insulated files).

### Run (Windows / PowerShell)

From the repo root, merge LuaRocks paths then invoke the **Lua 5.4** busted entrypoint (the `busted.bat` shim on some installs targets LuaJIT 5.1 and a different tree):

```powershell
cd path\to\worminess
foreach ($line in (cmd /c "luarocks path 2>nul")) {
  if ($line -match '^SET LUA_PATH=(.+)') { $env:LUA_PATH = $matches[1].Trim() }
  if ($line -match '^SET LUA_CPATH=(.+)') { $env:LUA_CPATH = $matches[1].Trim() }
}
lua "$env:APPDATA\luarocks\lib\luarocks\rocks-5.4\busted\2.3.0-1\bin\busted"
```

Adjust `lua` and the busted script path if your LuaRocks tree or version differs (`luarocks which busted`).

### Install tooling (if needed)

- **Lua + LuaRocks** (e.g. winget `DEVCOM.Lua`).
- **busted:** `luarocks install busted` — native rocks (`luasystem`, `luafilesystem`, …) need a **C compiler** on Windows (e.g. LLVM-MinGW from winget `MartinStorsjo.LLVM-MinGW.UCRT`); put `gcc` on `PATH` for the install, then you can remove it from `PATH` for day-to-day runs.

### Optional env

- `WORMINESS_ROOT` — absolute path to the repo if `spec_helper` cannot infer it from `debug.getinfo` (e.g. unusual loaders).

## LÖVE smoke

```bash
love .
```

Confirm the window opens without Lua errors. **Movement (manual):** start a match and verify the active player can move/jump with the configured shared-keyboard or gamepad scheme before deep-testing P2 / dual-pad modes.

## Session scores (R6)

`src/data/session_scores.lua` keeps wins/draws **in memory** for the process; there is **no** `love.filesystem` persistence (matches “since launching” / session-only wording). No disk smoke test applies unless persistence is added later.

## Coverage gaps

Not covered by busted here: `app.lua`, scenes, input routing, rendering, audio, full `world.lua` integration, weapon projectiles end-to-end, and LÖVE-specific APIs. Add focused specs or integration smoke as those layers gain test seams.
