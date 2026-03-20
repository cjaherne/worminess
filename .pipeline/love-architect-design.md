# LÖVE Architect Design — `love-architect`

**Role in the pipeline:** Module boundaries, `require` direction, `love` lifecycle wiring, scene stack behaviour, systems orchestration, procedural map **cadence** and **seed derivation** as they appear in code.  
**Product brief:** Not repeated here — single authoritative copy in root [`DESIGN.md`](DESIGN.md) § **Original task (source of truth)**. (Overseer: avoid duplicating that block in *this* file or elsewhere outside `DESIGN.md`; merged `DESIGN.md` already states “Original task appears only once”.)

**Conflict rule:** Behaviour and numeric policies → [`DESIGN.md`](DESIGN.md). **Where code lives and who requires whom** → this document + actual `src/` layout.

---

## 1. Repository snapshot (implemented — March 2026)

**Tech stack:** LÖVE **11.4**, Lua 5.1 ([`conf.lua`](conf.lua)).

**Entry:** [`main.lua`](main.lua) extends `package.path`, [`src/bootstrap.lua`](src/bootstrap.lua), `require("app")` → [`app.register()`](src/app.lua).

The architecture described in older merges as “expected additions” (`app`, `scene_manager`, `scenes`, `input`, `systems`, `ui`) is **now present**. If [`DESIGN.md`](DESIGN.md) still lists only “Expected additions”, the orchestrator should refresh that section to match the tree below (avoids implementers thinking modules are missing).

### 1.1 Layout (authoritative file tree)

```
(root)/
  conf.lua, main.lua
  DESIGN.md, README.md, CODING_NOTES.md
src/
  app.lua, bootstrap.lua, scene_manager.lua
  audio/sfx.lua
  core/rng.lua, timer.lua, vec2.lua
  data/constants.lua, weapons.lua
  entities/mole.lua, projectile.lua, grenade.lua
  game/match_config.lua, session.lua, roster.lua, turn_state.lua, map_seed.lua
  input/bindings.lua, devices.lua, input_state.lua, stick.lua
  scenes/boot.lua, main_menu.lua, match_setup.lua, play.lua, pause.lua, game_over.lua
  systems/world_update.lua, weapons.lua, explosions.lua, turn_resolver.lua, vfx.lua
  ui/theme.lua, layout.lua, focus_stack.lua
  ui/hud/play_hud.lua
  world/map.lua, terrain.lua, collision.lua
  world/mapgen/init.lua, heightfield.lua, caves.lua, spawns.lua
```

**Optional:** `assets/` for future non-procedural art; current README documents **procedural SFX** in [`src/audio/sfx.lua`](src/audio/sfx.lua) (no binary audio files required for baseline).

---

## 2. High-level architecture

### 2.1 Runtime

- **Single-threaded** LÖVE loop.
- **Application shell:** [`src/app.lua`](src/app.lua) owns `Session` ([`game.session`](src/game/session.lua)), constructs [`scene_manager.new(get_context)`](src/scene_manager.lua), registers **all** relevant `love.*` callbacks.
- **Frame pipeline:** `love.update` clamps `dt` via [`data.constants`](src/data/constants.lua) (`MAX_DT`), then `sm:update(dt)` (**top scene only**). `love.draw` clears via [`ui.theme`](src/ui/theme.lua), applies letterbox/scaling (`theme.begin_draw` / `end_draw`), draws **entire stack** bottom → top so pause overlays the play scene.
- **Match runtime** lives in [`scenes/play.lua`](src/scenes/play.lua): `MatchConfig` snapshot, roster, turn FSM, world (`map`, `terrain`), entities, weapons/explosions/VFX — not in a global singleton except what `app` holds (`session`, `sm`).

### 2.2 Map regeneration cadence (code ↔ DESIGN)

[`DESIGN.md`](DESIGN.md) **Map regeneration cadence** is the behaviour contract. Implementation pattern:

1. **Each round**, during round setup in **play** (after interstitial / winner known, before placing moles), compute `seed` with [`game.map_seed.derive(procedural_seed, round_index)`](src/game/map_seed.lua).
2. Call [`world.mapgen.init.generate(match_config, seed)`](src/world/mapgen/init.lua) → `{ map, terrain, rng }`.
3. **Never** reuse the previous round’s terrain ImageData for a new round within the same match.

**Seed semantics (implemented in `map_seed.lua`):**

- `procedural_seed == nil` → new random integer per round (`love.math.random`).
- `procedural_seed` set → deterministic mix of seed + `round_index` so each round differs but a locked config reproduces the same **sequence** across runs and Rematch.

### 2.3 Dependency direction (`require` graph)

```
main.lua → bootstrap → app.lua
app.lua → scene_manager, game.session, data.constants, ui.theme, audio.sfx (load), scenes.boot

scene_manager → (scenes pushed by app / scene transitions)

scenes/* → game.*, input.*, ui.*, systems.*, world.*, entities.* as needed

world/mapgen/* → world/terrain, world/map, core/rng (no scenes, no app)

entities/* → avoid requiring scenes; receive world/callbacks from systems or play

systems/* → world, entities, game state tables passed from play (no scene require)
```

**Rule:** No cycles — `mapgen` and `entities` do not `require` `app` or `scenes/*`.

### 2.4 Scene stack semantics

- [`scene_manager.lua`](src/scene_manager.lua): `push`, `pop`, `replace` (replaces **top** only; underlays stay — used for pause over play).
- **Input:** forwarded to **top** scene only (`keypressed`, mouse, gamepad, wheel).
- **`emit`:** optional `top:on_emit(name, ...)` for cross-cutting signals.

### 2.5 Round UX vs scenes

Per unified DESIGN / UX: **round interstitial** / **round_end** phases should stay **inside** [`scenes/play.lua`](src/scenes/play.lua) (`turn_state.phase`), not a separate scene, unless the stack contract is deliberately changed.

---

## 3. `love` lifecycle (as implemented)

| Callback | Delegation |
|----------|------------|
| `love.load` | `theme.load_fonts()`, `audio.sfx.init()`, `Session.new()`, `scene_manager.new`, `replace(boot)` |
| `love.update` | `dt = min(dt, MAX_DT)`, `sm:update(dt)` |
| `love.draw` | `theme.clear_void()`, `begin_draw`, `sm:draw()` (full stack), `end_draw` |
| `love.resize` | all scenes `resize` |
| `love.keypressed` / `released` | forward to top scene |
| `love.gamepadpressed` / `released` | forward to top scene |
| `love.mousepressed` / `released` / `moved` / `wheelmoved` | forward to top scene |
| `love.joystickadded` / `removed` | `input.devices.refresh_joysticks()` |

**Pseudocode (round world build in play):**

```lua
-- Inside play scene round setup (conceptual)
local seed = map_seed.derive(cfg.procedural_seed, round_index)
local world = mapgen.generate(cfg, seed)
-- then spawn moles from map spawns, reset projectiles/VFX queues, etc.
```

---

## 4. Component breakdown and responsibilities

| Path | Responsibility |
|------|----------------|
| [`src/app.lua`](src/app.lua) | Global `love` registration; owns `session` + `scene_manager`; context `{ scenes, session }` |
| [`src/scene_manager.lua`](src/scene_manager.lua) | Stack, lifecycle, draw all layers, input to top, `emit` |
| [`src/scenes/boot.lua`](src/scenes/boot.lua) | Hand off to main menu |
| [`src/scenes/main_menu.lua`](src/scenes/main_menu.lua) | Session scores, navigate to match setup |
| [`src/scenes/match_setup.lua`](src/scenes/match_setup.lua) | Edit `MatchConfig`, dual Ready, `match_config.validate`, start play |
| [`src/scenes/play.lua`](src/scenes/play.lua) | Mapgen each round, combat loop, turn FSM, push pause, overlays, HUD data |
| [`src/scenes/pause.lua`](src/scenes/pause.lua) | Overlay; resume / restart / setup / menu |
| [`src/scenes/game_over.lua`](src/scenes/game_over.lua) | Match end, rematch (uses `session.last_match_config`), menu |
| [`src/input/*`](src/input/) | Bindings, device assignment, stick smoothing, optional `input_state` |
| [`src/systems/world_update.lua`](src/systems/world_update.lua) | Integrate moles, projectiles, grenades, terrain collision |
| [`src/systems/weapons.lua`](src/systems/weapons.lua) | Fire weapons from active mole |
| [`src/systems/explosions.lua`](src/systems/explosions.lua) | Terrain carve, damage, impulse; honor `friendly_fire` |
| [`src/systems/turn_resolver.lua`](src/systems/turn_resolver.lua) | Advance turn / round / match when world quiescent |
| [`src/systems/vfx.lua`](src/systems/vfx.lua) | Particles, shake, cosmetic feedback |
| [`src/audio/sfx.lua`](src/audio/sfx.lua) | Procedural sound hooks |
| [`src/ui/theme.lua`](src/ui/theme.lua), [`layout.lua`](src/ui/layout.lua), [`focus_stack.lua`](src/ui/focus_stack.lua) | Scaling, colours, menu focus |
| [`src/ui/hud/play_hud.lua`](src/ui/hud/play_hud.lua) | In-match HUD |
| [`src/game/map_seed.lua`](src/game/map_seed.lua) | Per-round seed derivation (DESIGN contract) |
| [`src/world/mapgen/init.lua`](src/world/mapgen/init.lua) | Orchestrate heightfield → caves → spawns → `rebuildImageData` |

---

## 5. Key data models and schemas

### 5.1 `MatchConfig`

**Source of truth:** [`src/game/match_config.lua`](src/game/match_config.lua) — `defaults`, `validate`, `copy`.

Fields: `mole_max_hp`, `rounds_to_win`, `wind_strength`, `grenade_fuse_seconds`, `turn_time_limit`, `friendly_fire`, `procedural_seed`, `map_width`, `map_height`, `teams_per_player`, `input_scheme` (`shared_kb` | `dual_gamepad`).

Lobby UX must stay aligned with [`DESIGN.md`](DESIGN.md) MatchConfig table + clamps.

### 5.2 Session

**Semantics:** [`DESIGN.md`](DESIGN.md) § **Session stats definition** — `scores[1|2]` = **match wins** since launch; `matches_completed` = completed **matches**; not round tallies without rename.

Implementation reference: [`src/game/session.lua`](src/game/session.lua).

### 5.3 Turn / roster

[`src/game/turn_state.lua`](src/game/turn_state.lua), [`src/game/roster.lua`](src/game/roster.lua) — starting player alternation, mole rotation, `next_living_mole_index`, phases including interstitial (see DESIGN checklists).

---

## 6. Performance and testing notes

- **Hot paths:** per-frame `world_update`, terrain queries in collision, explosion carving, `terrain:rebuildImageData` only when the mask changes (not every frame).
- **Pure / testable leaves:** [`core/vec2`](src/core/vec2.lua), [`core/rng`](src/core/rng.lua) (when not using global `love.math`), mapgen numeric stages, collision math in [`world/collision.lua`](src/world/collision.lua).  
- **`map_seed.derive`:** when `procedural_seed` is nil, uses `love.math.random` — **not** headless-pure; for automated tests, inject or stub RNG if needed.

---

## 7. Dependencies

| Choice | Rationale |
|--------|-----------|
| Stock LÖVE 11.4 | Project standard |
| No third-party Lua libs in tree | Simpler deploy |
| Procedural audio in [`audio/sfx.lua`](src/audio/sfx.lua) | Zero asset pipeline for SFX MVP |

---

## 8. `luaModules` — public surface (sketch)

| Module | Indicative API |
|--------|----------------|
| `app` | `register()` |
| `scene_manager` | `new(get_context)`, `push`, `pop`, `replace`, `update`, `draw`, `resize`, input forwards, `emit` |
| `game.match_config` | `defaults`, `validate`, `copy` |
| `game.session` | `new`, `bump_match_win`, `get_scores`, fields per DESIGN |
| `game.map_seed` | `derive(procedural_seed, round_index)` |
| `world.mapgen.init` | `generate(match_config, seed)` |
| `input.devices` | `refresh_joysticks`, scheme routing (see `CODING_NOTES.md`) |
| `systems.*` | Called from `play` with a shared context table (pattern in code) |

---

## 9. JSON handoff fragment

```json
{
  "architecture": "app registers love.*; scene_manager stack; update top-only, draw full stack; play owns match runtime; map_seed.derive + mapgen.generate each round per DESIGN cadence.",
  "luaModules": "See §8; implemented under src/.",
  "fileStructure": "§1.1",
  "loveLifecycle": "§3",
  "dependencies": ["LÖVE 11.4"],
  "considerations": [
    "Refresh DESIGN.md repository snapshot if it still says 'expected additions' only.",
    "map_seed uses love.math.random when procedural_seed is nil — stub for headless tests if needed.",
    "Pause uses stack push over play — keep input forwarding consistent (top scene only)."
  ]
}
```

---

## 10. Implementation notes for future Coding Agent work

1. **Preserve** `require` direction when adding features: new gameplay modules hang off `play` or `systems/*`, not from `mapgen` back to scenes.  
2. **Map cadence:** Any change to when `generate` runs must stay consistent with [`DESIGN.md`](DESIGN.md) **Map regeneration cadence** and [`map_seed.lua`](src/game/map_seed.lua).  
3. **Session semantics:** Do not overload `scores` / `matches_completed` without DESIGN + UI updates.  
4. **Theme draw bracket:** New global draw hooks (debug overlay) should respect `theme.begin_draw` / `end_draw` so resolution stays consistent.  
5. **Joystick hot-plug:** Already wired in `app` → `devices.refresh_joysticks`; extend assignment UI in match setup if adding device pickers.

---

*Design-only artifact: `.pipeline/love-architect-design.md`. No game implementation files created or modified by this agent.*
