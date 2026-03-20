# Stage: design (love-architect)

## Summary

Verifying the repository layout and key integration points so we can refresh `.pipeline/love-architect-design.md` to match the implemented codebase.



















Writing an updated architect document that reflects the implemented 48-file layout and aligns with `DESIGN.md` (map cadence, `map_seed`, session semantics).




Updated [`.pipeline/love-architect-design.md`](C:\Users\Chris\Documents\GitHub\worminess\.pipeline\love-architect-design.md) so it matches the **current ~48-file implementation** and stays aligned with merged [`DESIGN.md`](DESIGN.md).

### What changed

- **No duplicated product brief** — points at `DESIGN.md` § *Original task* only, and notes overseer hygiene (merged `DESIGN.md` already keeps a single authoritative block).
- **Repository snapshot** — Lists the **implemented** tree (`app`, `scene_manager`, all `scenes/`, `systems/`, `input/`, `ui/`, `audio/`, `game/map_seed.lua`, etc.) and flags that `DESIGN.md`’s “Expected additions” section may be **stale** and should be refreshed by the orchestrator.
- **Architecture** — Documents real behaviour: `app` owns `Session` + `scene_manager`, `dt` clamp, `theme` draw bracket, stack **draw all / update top**, joystick refresh hooks.
- **Map cadence** — Ties [`DESIGN.md`](DESIGN.md) map-regeneration rules to [`src/scenes/play.lua`](src/scenes/play.lua) + [`src/game/map_seed.lua`](src/game/map_seed.lua) + [`src/world/mapgen/init.lua`](src/world/mapgen/init.lua), including nil vs locked `procedural_seed` semantics.
- **Components / lifecycle / `luaModules` / JSON** — Updated to reflect files that exist now, with pseudocode for round setup.
- **Testing note** — `map_seed.derive` uses `love.math.random` when seed is nil → not headless-pure without a stub.

No `.lua` or other implementation files were edited—only this pipeline markdown.

## Files Created/Modified
- .pipeline/love-ux-design.md
- .pipeline/love-architect-design.md
