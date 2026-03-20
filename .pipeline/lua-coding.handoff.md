# Stage: coding (lua-coding)

## Summary

Implementing sub-task 3: enhancing the HUD, polishing projectile and character visuals, and verifying turn rotation and match options. Reviewing the codebase.




Implementing HUD enhancements (scores, HP, turn phase), visual polish for moles and projectiles, syncing turn slots when moles die mid-match, and adding a read-only “5 moles per team” row in match setup.









Implementing changes: adding `turn:sync_slots_to_living` after mole deaths, then updating HUD, visuals, and match setup.




Fixing `love.graphics.arc` call for LÖVE 11 API (no `"open"` parameter).





























Here’s what sub-task **3 of 3** delivered.

### HUD (`src/ui/hud.lua`)

- **Turn banner:** Player number, **Team A/B**, **active slot**, **HP (current/max)**, a short **phase** line (resolving shot / reposition+end turn / move–aim–fire), plus **turn timer** when it’s enabled.
- **Session scores:** Three **chips** for **P1 wins**, **P2 wins**, and **draws**, plus **matches finished** (R6).
- **Weapon panel:** Clear **selection highlight**, rocket vs grenade label, **power bar**, and a **live grenade fuse** bar when a grenade is in the world.
- **Wind panel:** Icon + strength label + **blowing left/right** and a large arrow.
- **Roster:** **S1–S5**, **numeric HP** for living moles, stronger **2px-style outline** on the **active** mole (current player + slot), adjusted layout to fit **720p**.

### Visual polish (`src/render/mole_draw.lua`, `play.lua`)

- Moles: **shadow**, **team-colored ground ellipse**, **cooler tint** for the **non-active team**, clearer **active ring** and aim overlay.
- **Rocket:** **Trailing embers**, **nose glow**, **streak** ahead of the sprite.
- **Grenade:** **Fuse ring** (`love.graphics.arc` in LÖVE 11 form), **orbiting spark**, **pulsing** green outline + soft shadow.
- **Aim preview:** Orange for rocket, green tint for grenade.

### Turn rotation & living moles (`src/sim/world.lua`)

- After applying **HP → alive**, the world calls **`turn:sync_slots_to_living`** so if the **current mole dies during a shot**, the active **slot jumps to a living mole** before movement/input. **End-turn** still uses the existing **`turn_state`** ring advance (R8).

### Match options (`src/scenes/match_setup.lua`)

- First row is **read-only**: **“5 moles per team (fixed for v1)”** so R7/R9 are visible in setup; **mole health** and the rest are unchanged.

### Docs

- **`README.md`** — short **HUD** section.
- **`CODING_NOTES.md`** — **Sub-task 3** notes and **R1** traceability tweak.

`love .` was smoke-run successfully after these edits.

## Files Created/Modified
- CODING_NOTES.md
- README.md
- src/render/mole_draw.lua
- src/scenes/match_setup.lua
- src/scenes/play.lua
- src/sim/world.lua
- src/ui/hud.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -NoNewWindow; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }`
