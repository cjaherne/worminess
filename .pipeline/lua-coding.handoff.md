# Stage: coding (lua-coding)

## Summary

Auditing `love.graphics.printf` usage and `turn_state` phases per the overseer review.





























Implementing overseer review: adding theme font tiers so body/HUD meet ≥22/≥28px at scale 1.0, normalizing all scaled `printf` calls, and removing the unused `firing` phase.





























































































































## Overseer typography audit

**Approach:** Dropped all sub-1.0 `love.graphics.printf` scales in the listed UI files by introducing **`theme.font_title`** (56px), **`theme.font_banner`** (34px), raising **`font_body`** to **24px** and **`font_hud`** to **30px**, and picking the right font per block so **menu copy ≥22px** and **primary HUD ≥28px** at **scale 1.0**.

### Files touched

| Area | Change |
|------|--------|
| [`src/ui/theme.lua`](src/ui/theme.lua) | `font_body` 24, `font_hud` 30, new `font_title` / `font_banner`. |
| [`src/scenes/boot.lua`](src/scenes/boot.lua) | Title / subtitle / prompt / footer use tiered fonts, default `printf` scaling. |
| [`src/scenes/main_menu.lua`](src/scenes/main_menu.lua) | Title → `font_title`; stats → `font_hud`; rest → `font_body`. |
| [`src/scenes/match_setup.lua`](src/scenes/match_setup.lua) | Banner + body fonts; row spacing **38px**; ready/start/back layout + **mouse hit boxes** aligned with new layout. |
| [`src/scenes/game_over.lua`](src/scenes/game_over.lua) | Banner / HUD / body fonts; **mouse** hit regions updated for new button Y positions. |
| [`src/scenes/pause.lua`](src/scenes/pause.lua) | Same pattern for title, session text, menu, footer. |
| [`src/ui/hud/play_hud.lua`](src/ui/hud/play_hud.lua) | All primary HUD lines on **`font_hud`** at scale 1; **hints** on **`font_body`**; weapon cells **88×72** so **Rocket/Grenade** wrap cleanly at 30px. |
| [`src/entities/mole.lua`](src/entities/mole.lua) | Mole index uses **`theme.font_body`** instead of **0.65** scale (still ≥22px). |
| [`src/game/turn_state.lua`](src/game/turn_state.lua) | Removed unused **`firing`** phase (combat already uses **`aim` → `flying`** via `weapons.try_fire`). |
| [`CODING_NOTES.md`](CODING_NOTES.md) | Short **Suggestions** note on the font-tier policy. |

### Verification

- No remaining **`firing`** references.
- **`love .`** smoke run completed without an immediate crash.
- **`main.lua`** still wires **`love.load` / `update` / `draw`** through **`app.register()`** (unchanged).

## Files Created/Modified
- CODING_NOTES.md
- src/entities/mole.lua
- src/game/turn_state.lua
- src/scenes/boot.lua
- src/scenes/game_over.lua
- src/scenes/main_menu.lua
- src/scenes/match_setup.lua
- src/scenes/pause.lua
- src/ui/hud/play_hud.lua
- src/ui/theme.lua

## Shell Commands Run
- `cd "C:\Users\Chris\Documents\GitHub\worminess"; if (Test-Path "C:\Program Files\LOVE\love.exe") { $p = Start-Process -FilePath "C:\Program Files\LOVE\love.exe" -ArgumentList "." -PassThru -WindowStyle Hidden; Start-Sleep -Seconds 2; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }`
