# Stage: design (love-architect)

## Summary

Exploring the codebase to align the LÖVE architecture design with existing structure, then writing `.pipeline/love-architect-design.md`.









Greenfield repo (no Lua yet). Writing a LÖVE-focused architecture document that defines module layout, scenes, lifecycle, and procedural map hooks for the moles/Worms-style game.





Summary of what was delivered:

## Delivered artifact

**Path:** [`.pipeline/love-architect-design.md`](C:\Users\Chris\Documents\GitHub\worminess\.pipeline\love-architect-design.md)

The repo is effectively **greenfield** (`.pipeline/architecture-brief.md` reports no source files), so the doc defines a **full initial** LÖVE 11 / Lua 5.1 layout rather than deltas to existing Lua.

## Contents (architect perspective)

1. **Runtime:** Scene stack (`scene_manager` + `scenes/*`), long-lived **game session** for match config, roster, turn state, terrain/entities, and **session-only win counts**.
2. **Require direction:** `mapgen` / `core/*` stay free of scenes and `app`; collisions live behind `world/collision.lua` for future swaps.
3. **File tree:** `main.lua`, `conf.lua`, `src/app.lua`, `src/scenes/` (boot, menus, match setup, play, pause, game over), `src/game/`, `src/world/` + `mapgen/`, `src/entities/`, `src/systems/`, `src/input/`, `src/data/`, `assets/`.
4. **Data shapes:** `MatchConfig`, `Session`, `Roster`, `TurnState`, terrain API sketch, weapon data tables.
5. **Lifecycle:** How `love.load` / `love.update` / `love.draw` and input callbacks forward through the scene manager and, in play, through systems (timers → physics → hits → explosions → turn).
6. **Procedural maps:** Seeded pipeline (heightfield → optional caves → mask → spawns) with deterministic RNG in `core/rng.lua`.
7. **2P input:** `input/bindings.lua` + `input/devices.lua` for keyboard+mouse vs dual gamepads and routing mouse aim to the configured “mouse” player.
8. **Handoff:** §8 API sketches, §9 JSON fragment for merge/tooling, §10 concrete notes for the Coding Agent (joystick module, shared explosion path, testable pure modules).

No `.lua` or other implementation files were added—only this design markdown, per your pipeline rules.

## Files Created/Modified
- .pipeline/love-architect-design.md
