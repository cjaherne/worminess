# Stage: coding (lua-coding)

## Summary

Reviewing the implementation for sub-task 2: procedural terrain, rocket/grenade combat, and two-player local play.




Enhancing procedural terrain generation, refining rocket/grenade combat (trajectories, hits, wind coupling), and strengthening two-player input (e.g. P2 Enter to fire).




Implementing enhanced procedural terrain (smoothed multi-octave height, lateral bias), combat tweaks (rocket gravity, finer collision sampling, grenade escape from terrain), deterministic wind from the map seed, and clearer P2 fire bindings.
























Here’s what sub-task **2 of 3** changed, building on what you already had.

### Procedural terrain (`src/sim/terrain_gen.lua`)

- Height is built **per column** from a **5-octave** sine stack plus **ridged** detail for clearer silhouettes.
- **Domain warp** (lateral sine offset) mixes a second height sample so adjacent columns aren’t a simple sine.
- **3-tap smoothing** reduces harsh jag and helps **spawn plateaus** stay valid.
- **Left/right bias** breaks perfect symmetry between team sides.
- **Retry cap** raised to **72** so “flat enough” P1/P2 strips are found more reliably.

### Combat (`src/sim/world.lua`, `src/config.defaults.lua`)

- **Rocket:** Applies **`rocket_gravity_mul`** (fraction of world gravity) each step so the path droops slightly, matching the “mild gravity” idea in the design.
- **Rocket vs terrain/moles:** Uses **`rocket_ray_steps`** (default **56**) for the segment sweep.
- **Grenade:** After a bounce, **`grenade_unstick_px`** nudges the projectile upward up to 10 steps so it’s less likely to sit inside solid cells.
- **Wind:** `wind_vx` now keys off **`built.seed_used`**, so wind direction matches the **map that was actually generated**, including when `map_seed` is random in settings.

### Second player / local multiplayer (`src/input/keyboard_mouse.lua`, docs)

- Gameplay was already **two-team hotseat** with separate P1/P2 keys and **dual gamepad** mode.
- **Player 2 fire** now also accepts **`Enter`**, **numpad Enter**, and **`Right Ctrl`** (on top of `;`), aligned with the design’s “Enter / Right Ctrl” options.
- **`README.md`**, **`CODING_NOTES.md`**, and the in-game HUD hint line were updated; **Issues Found** notes a possible future clash if in-match UI starts using **Enter** for confirmations.

`love .` was smoke-run again with no immediate startup failure. R1–R11 remain covered as in the existing traceability table; sub-task 2 details are under **`## Sub-task 2`** in **`CODING_NOTES.md`**.

## Files Created/Modified
- CODING_NOTES.md
- README.md
- src/config.defaults.lua
- src/input/keyboard_mouse.lua
- src/sim/terrain_gen.lua
- src/sim/world.lua
- src/ui/hud.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -NoNewWindow; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }`
