# Stage: validation (love-testing)

## Summary

Setting up busted tests for the LÖVE2D project: reading DESIGN.md, handoffs, existing specs, and key Lua modules.



















Checking for Lua/LuaRocks and reading handoff files for testing hints:







































Writing the spec suite and test harness while LuaJIT installs. Checking common install paths:
































































Creating `.busted`, `spec/helper.lua`, and busted spec files.









Verifying `map_seed` and `rng` expected values and fixing specs.














Fixing the mole spec: `friendly_fire == false` blocks same-team damage.









All tests passed. Adding `TESTING.md` and a short README section.




Here’s a concise summary and the pipeline-style JSON.

## Summary

- **Tooling:** LuaJIT and LuaRocks were configured for Lua **5.1**; **LLVM MinGW** was installed so LuaRocks could build native busted dependencies (`luasystem`, `luafilesystem`, etc.). **busted 2.3.0** is installed and runs from the repo root.
- **Specs added** under `spec/` with `.busted` pointing at `spec/helper.lua`, which extends `package.path` like `main.lua` and stubs `love.math.random` so `game.map_seed` runs without LÖVE.
- **Run:** `busted` → **37 successes, 0 failures** (~15 ms).
- **LÖVE smoke:** `love.exe` was started on the project folder for ~3s with stderr/stdout redirected; no output and the process was still running (then stopped), which is consistent with a normal game loop and **no immediate load error**.

**Covered:** `match_config` (defaults, validate, copy), `map_seed` (deterministic path, nil-seed stub, round coercion), `session`, `roster` (order rotation, team counts, spawns, `all_moles`), `turn_state` (living-mole selection, advance/start match, interstitial, `repair_active_slot`, weapon id), `core.vec2`, `core.rng`, `core.timer`, `entities.mole` damage / friendly-fire rules and impulse, `data.weapons` shape.

**Gaps / not covered:** Scenes, `world_update`, explosions, weapons system, input, mapgen, anything that needs real `love.*` (drawing, audio, filesystem). `mole.draw` is untested. `match_config.validate` does not assert `input_scheme` (none in code).

**Docs:** [TESTING.md](TESTING.md) describes setup and `busted`; [README.md](README.md) has a short “Tests” pointer.

---

```json
{
  "testFiles": [
    { "path": ".busted", "content": "busted default config + spec/helper.lua" },
    { "path": "spec/helper.lua", "content": "package.path + love.math.random stub" },
    { "path": "spec/match_config_spec.lua", "content": "defaults, validate clamps, copy" },
    { "path": "spec/map_seed_spec.lua", "content": "nil seed stub, deterministic derive, round floor" },
    { "path": "spec/session_spec.lua", "content": "new, bump_match_win" },
    { "path": "spec/roster_spec.lua", "content": "rotate_order, team, spawns, all_moles" },
    { "path": "spec/turn_state_spec.lua", "content": "turn advance, interstitial, repair_active_slot, weapons" },
    { "path": "spec/vec2_spec.lua", "content": "vector ops" },
    { "path": "spec/rng_spec.lua", "content": "deterministic RNG" },
    { "path": "spec/timer_spec.lua", "content": "countdown timer" },
    { "path": "spec/mole_spec.lua", "content": "damage / friendly_fire / impulse" },
    { "path": "spec/weapons_data_spec.lua", "content": "rocket vs grenade data" },
    { "path": "TESTING.md", "content": "how to install/run busted + love smoke note" }
  ],
  "testCommands": [
    "luarocks --lua-version=5.1 config variables.LUA \"<path-to-luajit.exe>\"",
    "luarocks --lua-version=5.1 install busted",
    "busted",
    "love . (3s smoke via Start-Process, no stderr/stdout captured)"
  ],
  "coverage": "Pure Lua: match_config, map_seed (with love.math mock), session, roster, turn_state, core vec2/rng/timer, mole combat helpers, weapons table. Not covered: LÖVE scenes/systems/mapgen/input/rendering/audio, turn_resolver, explosions, world_update, integration or both input schemes in-app.",
  "edgeCases": [
    "map_seed: procedural_seed nil → fixed stub value 424242; round_index ≤0 treated as 1",
    "mole: friendly_fire false blocks same-team damage; true allows it",
    "turn_state: repair_active_slot when active mole dead vs full team wipe",
    "roster: rotate_order does not mutate source table"
  ],
  "notes": "Windows: busted needs a C compiler for some LuaRocks deps (LLVM-MinGW worked). Specs use LuaJIT 5.1-compatible code (e.g. unpack). Real nil-seed map behaviour in-game uses LÖVE’s RNG, not the test stub. README links TESTING.md for full setup."
}
```

## Files Created/Modified
- README.md

## Shell Commands Run
- `where lua 2>$null; where luajit 2>$null; where luarocks 2>$null; lua -v 2>&1; luarocks --version 2>&1`
- `Get-Command love -ErrorAction SilentlyContinue | Format-List; $env:Path -split ';' | Select-String -Pattern 'love|Lua' -CaseSensitive:$false`
- `winget install --id LuaJIT.LuaJIT -e --accept-package-agreements --accept-source-agreements 2>&1`
- `winget search lua | Select-Object -First 25`
- `winget install --id DEVCOM.LuaJIT -e --accept-package-agreements --accept-source-agreements`
- `Start-Sleep -Seconds 15; Get-Content "C:\Users\Chris\.cursor\projects\C-Users-Chris-Documents-GitHub-worminess\terminals\963048.txt" -Tail 30`
- `Start-Sleep -Seconds 20; Get-ChildItem "C:\Program Files\LuaJIT" -ErrorAction SilentlyContinue; Get-ChildItem "C:\Program Files (x86)\LuaJIT" -ErrorAction SilentlyContinue; where.exe luajit 2>$null`
- `Get-ChildItem -Path "C:\Program Files","C:\Program Files (x86)" -Filter "luajit.exe" -Recurse -ErrorAction SilentlyContinue 2>$null | Select-Object -First 5 FullName`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); where.exe luajit; luajit -v`
- `where.exe luarocks 2>$null; Get-ChildItem "C:\Users\Chris\AppData\Local\Programs\LuaJIT" -Recurse -Filter "luarocks*" -ErrorAction SilentlyContinue | Select-Object FullName`
- `cd C:\Users\Chris\Documents\GitHub\worminess; luarocks install busted`
- `cd C:\Users\Chris\Documents\GitHub\worminess; luarocks config variables.LUA "C:\Users\Chris\AppData\Local\Programs\LuaJIT\bin\luajit.exe"; luarocks install busted`
- `luarocks --lua-version=5.1 config variables.LUA "C:\Users\Chris\AppData\Local\Programs\LuaJIT\bin\luajit.exe"; luarocks --lua-version=5.1 install busted`
- `where.exe gcc 2>$null; where.exe cl 2>$null`
- `winget install --id BrechtSanders.WinLibs.Personal.UCRT -e --accept-package-agreements --accept-source-agreements`
- `winget search mingw | Select-Object -First 15`
- `winget install --id MartinStorsjo.LLVM-MinGW.UCRT -e --accept-package-agreements --accept-source-agreements`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); where.exe x86_64-w64-mingw32-gcc; luarocks --lua-version=5.1 install busted`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); where.exe busted; busted --version`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); cd C:\Users\Chris\Documents\GitHub\worminess; luajit -e "package.path=package.path..';./src/?.lua;./src/?/init.lua'; local r=require('core.rng').new(12345); print(r:random(1,1000000)); r:seed(12345); print(r:random(1,1000000))"`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); cd C:\Users\Chris\Documents\GitHub\worminess; busted`
- `$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User"); cd C:\Users\Chris\Documents\GitHub\worminess; busted`
- `cd C:\Users\Chris\Documents\GitHub\worminess; $err = Join-Path $env:TEMP "love_smoke_err.txt"; $out = Join-Path $env:TEMP "love_smoke_out.txt"; Remove-Item $err,$out -ErrorAction SilentlyContinue; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "`"$PWD`"" -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput $out; Start-Sleep -Seconds 3; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; "--- stderr ---"; if (Test-Path $err) { Get-Content $err -ErrorAction SilentlyContinue }; "--- stdout ---"; if (Test-Path $out) { Get-Content $out -ErrorAction SilentlyContinue }; "--- exit ---"; if ($p.HasExited) { $p.ExitCode }`
