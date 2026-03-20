# Stage: coding (lua-coding)

## Summary

Reading the full DESIGN.md and existing codebase to implement the scene manager, entry point, and core game states.



















Implementing `src/app.lua`, `src/scene_manager.lua`, minimal `src/ui/theme.lua`, and scenes `boot`, `main_menu`, and `play`. Verifying whether `love` is available:









Creating the scene stack, `app.lua`, theme helper, and three scenes. Documenting in `CODING_NOTES.md` that we couldn't run a headless smoke test (windowed loop) and noting the installed LÖVE version if relevant.
























Verifying Lua loads by running LÖVE briefly and checking for startup errors:


































Here’s what was implemented for **sub-task 1** (scene stack + boot / main menu / play).

### What was added

1. **`src/scene_manager.lua`** — Stack with `push`, `pop`, `replace` (replaces **top** only so future pause overlays can stay under), `update` / `draw` (draw **bottom → top**), `resize`, and forwarding of input callbacks to the top scene, plus `emit` for later use.

2. **`src/app.lua`** — Owns a single **`Session`** (`game.session`), builds **`scene_manager.new(get_context)`**, starts with **`scenes.boot`**, registers `love.load` / `update` / `draw` / `resize` / keyboard / gamepad / mouse / wheel. **`dt`** is clamped with **`data.constants.MAX_DT`**. Draw path: **`theme.clear_void`** → logical canvas **`theme.begin_draw`** → **`sm:draw()`** → **`theme.end_draw`**.

3. **`src/ui/theme.lua`** — Design palette (void / paper / ink / team A–B / accent / danger) and **1280×720** uniform scale + letterboxing.

4. **`src/scenes/boot.lua`** — Splash, **~0.85 Hz** prompt pulse, auto-advance **~2.4 s**, **Enter / Space / gamepad A** → **`main_menu`**.

5. **`src/scenes/main_menu.lua`** — **P1/P2 match wins** + **matches completed**, **Local match** → **play**, **Options** toast stub, **Quit**; keyboard, gamepad (A / B / d-pad), mouse click on buttons; right panel placeholder.

6. **`src/scenes/play.lua`** — Placeholder shell; **Esc** or **gamepad B** → **`main_menu`**.

7. **`README.md`** — LÖVE version note and `love .` instructions.

8. **`CODING_NOTES.md`** — **Local match** skips **`match_setup`** for this slice (per full `DESIGN.md` flow) and notes the automated run limitation.

`main.lua` and `conf.lua` were already aligned with the design (`package.path`, `bootstrap`, `app.register()`, 11.4, 1280×720, joystick on).

### Verification

- LÖVE was started with **`--console`** from the project root; it exited **0** with **no Lua errors** in the capture (game ran a few seconds then was stopped).

### Design alignment note

Full **`DESIGN.md`** flow is **main_menu → match_setup → play**; this sub-task only required **boot / main_menu / play**, so **Local match** goes straight to the **play** stub until **`match_setup`** exists (documented in **`CODING_NOTES.md`**).

## Files Created/Modified
- (none)

## Shell Commands Run
- `where love 2>nul; love --version 2>nul`
- `Get-Command love -ErrorAction SilentlyContinue | Format-List`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -WindowStyle Hidden; Start-Sleep -Seconds 2; if (!$p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; if ($p.ExitCode -and $p.ExitCode -ne 0) { exit $p.ExitCode }`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; cmd /c "\"C:\Program Files\LOVE\love.exe\" --console ."`
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; & "C:\Program Files\LOVE\love.exe" --console .`
- `Stop-Process -Name love -Force -ErrorAction SilentlyContinue`
