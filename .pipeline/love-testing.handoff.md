# Stage: validation (love-testing)

## Summary

Reading the design and test setup, verifying `config.defaults` layout, then running busted and a brief LÖVE smoke check.






























































































Adding `spec/config_defaults_spec.lua` to lock in `config.defaults` loading and schema. All 36 tests passed; we'll run busted again after adding it.

















































## Summary

**Build / `config.defaults`:** `src/config/defaults.lua` is present (no stray `src/config.defaults.lua`). `npm run build` → `release check ok`. `spec/spec_helper.lua` preloads `config.defaults` from that path so busted matches LÖVE’s dotted `require` layout.

**Tests added:** `spec/config_defaults_spec.lua` — six examples that `require("config.defaults")` resolves, core numeric fields exist, `weapon` / `wind_force` / `colors` match the DESIGN schema (including RGB triples), and `require` caching holds.

**Docs:** `TESTING.md` now notes that `config.defaults` is covered by that spec.

**Executed commands**

| Command | Result |
|--------|--------|
| `npm run build` | OK |
| `busted` (Lua 5.4 on `PATH`) | **42 successes**, 0 failures (was 36 before the new spec) |
| `lovec.exe "<repo>"` ~4s then `Stop-Process` | Process was still running when stopped (no immediate crash); exit code **-1** from forced termination, not a clean game exit |

**Gaps (unchanged in spirit):** No busted coverage for scenes, `app`, input, render, audio, or full `world`/projectile integration. LÖVE smoke did not capture console errors (console redirect failed on older `ProcessStartInfo`); rely on `lovec`/`love .` manually if a load error is suspected.

**Windows note:** `lua` / `busted` live under paths like `...\Local\Programs\Lua\bin` and `...\Roaming\luarocks\bin`; add them to `PATH` (or use the `foreach` + explicit `lua ...\busted` recipe in `TESTING.md`) if a shell does not see `lua`.

---

```json
{
  "testFiles": [
    {
      "path": "spec/config_defaults_spec.lua",
      "content": "New busted describe block for require('config.defaults'): table shape, weapon/wind/colors schema, RGB triples, require cache identity."
    },
    {
      "path": "TESTING.md",
      "content": "Coverage section: note config.defaults covered by config_defaults_spec.lua via spec_helper."
    }
  ],
  "testCommands": [
    "npm run build",
    "busted (from repo root, with Lua 5.4 + luarocks busted on PATH)",
    "Start-Process 'C:\\Program Files\\LOVE\\lovec.exe' with game directory; Stop-Process after ~4s"
  ],
  "coverage": {
    "added": [
      "config.defaults module load via same preload path as LÖVE (src/config/defaults.lua)",
      "Presence and numeric types for core sim fields (cell, grid, gravity, mole_radius, speeds, max_dt)",
      "weapon.* rocket/grenade tuning keys",
      "wind_force low/med/high",
      "colors.* as 3-component numeric tables",
      "Lua require single-instance semantics for the module"
    ],
    "existing_suite": "damage, match_settings, mole, physics, session_scores, terrain, terrain_gen, timer, turn_state, vec2, weapons_registry (unchanged)",
    "not_covered": "LÖVE boot callbacks, rendering, input routing, scenes, sfx, full world/projectile integration"
  },
  "edgeCases": [
    "Palette tested as length-3 numeric sequences (#t == 3), not named r/g/b keys",
    "require cache test assumes no test reloads package.loaded['config.defaults']"
  ],
  "notes": "Release-check and busted confirm the config slice; spec_helper must stay aligned with main.lua setRequirePath. lovec stayed running until killed—good smoke for 'no instant quit', but not a substitute for reading a console error if the window shows the LÖVE error screen."
}
```

## Files Created/Modified
- TESTING.md

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess" && where busted 2>nul; where lua 2>nul; where love 2>nul; lua -v 2>&1`
- `Set-Location "C:\Users\Chris\Documents\GitHub\worminess"; Get-Command busted -ErrorAction SilentlyContinue; Get-Command lua -ErrorAction SilentlyContinue; Get-Command love -ErrorAction SilentlyContinue; lua -v 2>&1`
- `Get-Command luarocks -ErrorAction SilentlyContinue; Get-ChildItem "C:\Program Files\Lua" -ErrorAction SilentlyContinue; Get-ChildItem "$env:LOCALAPPDATA\Programs" -Filter "lua*" -ErrorAction SilentlyContinue | Select-Object FullName`
- `winget search lua --accept-source-agreements 2>&1 | Select-Object -First 30`
- `Set-Location "C:\Users\Chris\Documents\GitHub\worminess"; npm run build 2>&1`
- `winget install --id DEVCOM.Lua -e --accept-package-agreements --accept-source-agreements 2>&1`
- `Get-ChildItem "C:\Program Files\Lua" -Recurse -Filter "lua.exe" -ErrorAction SilentlyContinue | Select-Object -First 5 FullName; Get-ChildItem "$env:ProgramFiles(x86)\Lua" -Recurse -Filter "lua.exe" -ErrorAction SilentlyContinue | Select-Object -First 5 FullName; Get-ChildItem "$env:LOCALAPPDATA\Programs" -Recurse -Filter "lua.exe" -ErrorAction SilentlyContinue | Select-Object -First 5 FullName`
- `winget list Lua 2>&1; Get-ChildItem "C:\Program Files" -Filter "lua*" -Directory -ErrorAction SilentlyContinue | Select-Object FullName`
- `Get-ChildItem "C:\Users\Chris\AppData\Local\Microsoft\WinGet\Packages" -Recurse -Filter "lua.exe" -ErrorAction SilentlyContinue 2>$null | Select-Object -First 10 FullName; Get-ChildItem "C:\Program Files\LuaJIT" -ErrorAction SilentlyContinue; where.exe lua 2>$null`
- `$paths = @(
  "C:\lua",
  "C:\Lua",
  "C:\Program Files\Lua\5.4\bin",
  "C:\Program Files (x86)\Lua\5.4\bin",
  "$env:USERPROFILE\scoop\apps\lua\current",
  "$env:USERPROFILE\scoop\shims"
)
foreach ($p in $paths) { if (Test-Path "$p\lua.exe") { Write-Output $p } }
Get-ChildItem "C:\" -Filter "lua54.exe" -Recurse -ErrorAction SilentlyContinue -Depth 4 | Select-Object -First 3 FullName`
- `Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match 'Lua' } | Select-Object DisplayName, InstallLocation; Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Lua' } | Select-Object DisplayName, InstallLocation`
- `Get-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Lua' } | Select-Object DisplayName, InstallLocation, UninstallString`
- `[Environment]::GetEnvironmentVariable("Path", "Machine") -split ';' | Where-Object { $_ -match 'lua|Lua|LUA' }
[Environment]::GetEnvironmentVariable("Path", "User") -split ';' | Where-Object { $_ -match 'lua|Lua|LUA' }`
- `$env:Path = "C:\Users\Chris\AppData\Local\Programs\Lua\bin;C:\Users\Chris\AppData\Roaming\luarocks\bin;C:\Users\Chris\AppData\Local\Programs\LuaJIT\bin;" + $env:Path
Set-Location "C:\Users\Chris\Documents\GitHub\worminess"
lua -v
Get-Command busted -ErrorAction SilentlyContinue | Format-List`
- `$env:Path = "C:\Users\Chris\AppData\Local\Programs\Lua\bin;C:\Users\Chris\AppData\Roaming\luarocks\bin;" + $env:Path
Set-Location "C:\Users\Chris\Documents\GitHub\worminess"
busted 2>&1`
- `& "C:\Program Files\LOVE\love.exe" --help 2>&1 | Select-Object -First 25`
- `Stop-Process -Id 21064 -Force -ErrorAction SilentlyContinue`
- `$env:Path = "C:\Users\Chris\AppData\Local\Programs\Lua\bin;C:\Users\Chris\AppData\Roaming\luarocks\bin;" + $env:Path
Set-Location "C:\Users\Chris\Documents\GitHub\worminess"
busted 2>&1`
- `Get-ChildItem "C:\Program Files\LOVE" | Select-Object Name`
- `Test-Path "C:\Program Files\LOVE\love.exe"; Get-ChildItem "C:\Program Files\LOVE\" -ErrorAction SilentlyContinue`
- `$love = "C:\Program Files\LOVE\lovec.exe"
$game = "C:\Users\Chris\Documents\GitHub\worminess"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $love
$psi.ArgumentList.Add($game)
$psi.RedirectStandardError = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()
$deadline = (Get-Date).AddSeconds(5)
$stdout = ""
$stderr = ""
while (-not $p.HasExited -and (Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 200
  $stdout += $p.StandardOutput.ReadToEnd()
  $stderr += $p.StandardError.ReadToEnd()
}
if (-not $p.HasExited) {
  $stdout += $p.StandardOutput.ReadToEnd()
  $stderr += $p.StandardError.ReadToEnd()
  $p.Kill()
  $p.WaitForExit(3000)
}
$exit = $p.ExitCode
Write-Output "--- exit: $exit ---"
Write-Output "--- stderr ---"
Write-Output $stderr
Write-Output "--- stdout (head) ---"
Write-Output ($stdout.Substring(0, [Math]::Min(2000, $stdout.Length)))`
- `$p = Start-Process -FilePath "C:\Program Files\LOVE\lovec.exe" -ArgumentList "`"C:\Users\Chris\Documents\GitHub\worminess`"" -PassThru
Start-Sleep -Seconds 4
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; $p.WaitForExit(5000) }
"HasExited=$($p.HasExited) ExitCode=$($p.ExitCode)"
Get-Process lovec -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue`
