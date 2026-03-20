# LÖVE Architect Design — `love-architect`

**Scope:** Lua 5.1 / LÖVE **11.4** module layout, scene stack, lifecycle delegation, procedural map generation boundaries, input abstraction for 2P local (shared KB+M / dual gamepads).  
**Builds on:** The repo already contains `conf.lua`, `main.lua`, `src/bootstrap.lua`, `src/core/*`, `src/data/*`, `src/entities/*`, `src/game/*`, and `src/world/*` including `src/world/mapgen/*`. Root [`DESIGN.md`](DESIGN.md) still says there is no `main.lua` / `src/` — that line is **stale**; the orchestrator should replace it with the snapshot in §0 below when merging docs.

---

## 0. Repository snapshot (for DESIGN.md / brief refresh)

**Tech stack:** LÖVE 11.4, Lua 5.1 (embedded).  
**Entry:** [`main.lua`](main.lua) sets `package.path`, requires [`src/bootstrap.lua`](src/bootstrap.lua), then `require("app")` → **`app.register()`**.

**Present (Lua):**

| Area | Files |
|------|--------|
| Config | [`conf.lua`](conf.lua) |
| Core | [`src/core/rng.lua`](src/core/rng.lua), [`src/core/timer.lua`](src/core/timer.lua), [`src/core/vec2.lua`](src/core/vec2.lua) |
| Data | [`src/data/constants.lua`](src/data/constants.lua), [`src/data/weapons.lua`](src/data/weapons.lua) |
| Game | [`src/game/match_config.lua`](src/game/match_config.lua), [`src/game/session.lua`](src/game/session.lua), [`src/game/roster.lua`](src/game/roster.lua), [`src/game/turn_state.lua`](src/game/turn_state.lua) |
| World | [`src/world/map.lua`](src/world/map.lua), [`src/world/terrain.lua`](src/world/terrain.lua), [`src/world/collision.lua`](src/world/collision.lua) |
| Mapgen | [`src/world/mapgen/init.lua`](src/world/mapgen/init.lua), `heightfield.lua`, `caves.lua`, `spawns.lua` |
| Entities | [`src/entities/mole.lua`](src/entities/mole.lua), [`projectile.lua`](src/entities/projectile.lua), [`grenade.lua`](src/entities/grenade.lua) |

**Gap (blocking `love .`):** [`main.lua`](main.lua) requires **`app`**, but **`src/app.lua` is not present** in the tree the architect inspected — the Coding Agent must add `src/app.lua` (or relocate `app` under `src/` per `package.path`) so bootstrap succeeds.

**Still to add (architecture target):** `src/scene_manager.lua`, `src/scenes/*`, `src/input/*`, `src/systems/*` (weapons, explosions, world update, turn resolver, optional projectiles coordinator), and `assets/` as UX/audio needs.

---

## 1. High-level architecture

### Runtime model

- **Single-threaded** LÖVE loop: `love.load` → `love.update(dt)` / `love.draw()`.
- **Scene stack:** thin `scene_manager` forwards callbacks to the top scene; optional pause overlay.
- **Play scene** owns a **match runtime** object: `MatchConfig` snapshot + `Session` (session wins) + roster/turn + world (`map`, `terrain`, entities) + pending explosions/projectiles.
- **Pure Lua leaves:** `core/vec2`, `core/rng`, mapgen stages, and collision helpers should avoid pulling in `scenes` or `app` (mapgen already composes heightfield → caves → spawns via [`mapgen/init.lua`](src/world/mapgen/init.lua)).

### Dependency direction (require graph)

```
main.lua → bootstrap → app.lua → scene_manager → scenes/*

scenes/play.lua
  → game.session, game.match_config, game.roster, game.turn_state
  → world.map, world.terrain, world.collision
  → world.mapgen.init (on round start)
  → entities/* (via factories or world table)
  → systems/* (update pipeline)

world/mapgen/*  → world/terrain, world/map, core/rng  (no scenes)
entities/*      → should not require scenes; receive world/callbacks
```

**Rule:** No cycles — entities and mapgen never `require` `app` or `scenes/*`.

---

## 2. File / directory structure

### 2.1 Current + target layout

```
project root/
├── conf.lua
├── main.lua
├── DESIGN.md
├── assets/                    # (create as needed — fonts, sprites, sfx)
└── src/
    ├── bootstrap.lua          # EXISTS
    ├── app.lua                # REQUIRED BY main.lua — implement if missing
    ├── scene_manager.lua      # ADD
    ├── input/
    │   ├── bindings.lua       # ADD
    │   ├── devices.lua        # ADD — maps players to KB/mouse vs joystick indices
    │   └── input_state.lua    # ADD (optional but recommended)
    ├── core/                  # EXISTS
    ├── data/                  # EXISTS
    ├── game/                  # EXISTS
    ├── world/                 # EXISTS (+ mapgen/)
    ├── entities/              # EXISTS
    ├── systems/               # ADD — see §4
    └── scenes/                # ADD
        ├── boot.lua
        ├── main_menu.lua
        ├── match_setup.lua
        ├── play.lua
        ├── pause.lua
        └── game_over.lua
```

**Alignment with [`DESIGN.md`](DESIGN.md) hints:** Designer names like `systems/turn.lua` map to **`systems/turn_resolver.lua`** (or merge into `game/turn_state.lua` if kept tiny — prefer separate file if >~80 lines of FSM). `systems/projectiles.lua` is optional if `play.lua` + `entities/*` + `world/collision.lua` already integrate flight; architect recommends a **`systems/world_update.lua`** orchestrator either way.

---

## 3. Key data models, interfaces, schemas

### 3.1 `MatchConfig` — **single consolidated schema**

**Source of truth in code:** [`src/game/match_config.lua`](src/game/match_config.lua) (`defaults()` + `validate()`).  
**Designer components table** (“MatchConfig holds health, rounds to win, wind, fuse, friendly fire flag”) and **game-designer lobby** (turn timer, input) are folded into this one table — do not duplicate divergent field lists elsewhere.

| Field | Type | Purpose | Validation notes (existing) |
|--------|------|---------|-----------------------------|
| `mole_max_hp` | number | Starting / max HP per mole | Clamped 1–500 (integer) |
| `rounds_to_win` | number | First-to-N **round** wins for match | Clamped 1–9 |
| `wind_strength` | number | Scalar wind along ±x (units per s² or design-specific) | Clamped ±400; `0` = off |
| `grenade_fuse_seconds` | number | Base fuse for grenade weapon | Clamped 0.5–8 |
| `turn_time_limit` | number \| **nil** | Seconds per turn; **nil** = no limit | If set, clamped 5–120 |
| `friendly_fire` | boolean | Splash/direct vs same-team moles | No clamp in `validate` — ensure explosions respect this flag |
| `procedural_seed` | int \| **nil** | **nil** → pick random seed at round/match start | — |
| `map_width` | int | Terrain width (pixels) | Defaults from [`data/constants`](src/data/constants.lua) |
| `map_height` | int | Terrain height | Same |
| `teams_per_player` | int | Moles per human (product: **5**) | From constants |
| `input_scheme` | string | `"shared_kb"` \| `"dual_gamepad"` (extend if hybrid assignment stored) | Match setup UI writes this; `input/devices.lua` reads it |

**Weapon tuning** (rocket speed, radii) remains in [`src/data/weapons.lua`](src/data/weapons.lua); **grenade fuse** at fire time should use `MatchConfig.grenade_fuse_seconds` unless a weapon entry overrides (document one rule in code).

**Session vs match:** `Session` ([`src/game/session.lua`](src/game/session.lua)) tracks **match wins since app launch** (`scores`, `bump_match_win`); `rounds_to_win` is **per-match** configuration, not session state.

### 3.2 `Session` (in-memory — existing shape)

- `scores` — array `{ p1_wins, p2_wins }` (1-based player indices consistent with roster).
- `matches_completed`, `last_match_config`, `last_match_winner`, `bump_match_win`, `get_scores`.

### 3.3 `Roster` / `TurnState`

- Keep rotation rules from DESIGN.md: **starting player** alternates by round index; **per-team roster cursor** advances at round start; dead moles skipped. Implement in `turn_state.lua` + `systems/turn_resolver.lua` boundary: turn_state holds data, resolver applies transitions when projectiles/explosions finish.

### 3.4 Terrain / map

- **Implemented** in [`terrain.lua`](src/world/terrain.lua), [`map.lua`](src/world/map.lua), [`collision.lua`](src/world/collision.lua). Play scene should call into these rather than duplicating carve/damage.
- **Mapgen contract:** [`world.mapgen.init.generate(match_config, seed)`](src/world/mapgen/init.lua) returns `{ map, terrain, rng }`; play scene triggers on each new round (or match — designer prefers per match; round regen is also valid).

### 3.5 Weapons data

- [`src/data/weapons.lua`](src/data/weapons.lua) — data-only; `systems/weapons.lua` (to add) reads weapon id + `MatchConfig` to spawn `entities/projectile` or `entities/grenade`.

---

## 4. Component breakdown and responsibilities

| Module | Status | Responsibility |
|--------|--------|----------------|
| [`conf.lua`](conf.lua) | EXISTS | Window, joystick module on |
| [`main.lua`](main.lua) | EXISTS | path + bootstrap + app.register |
| `src/app.lua` | **MISSING** | Register all `love.*` callbacks; delegate to scene_manager |
| `scene_manager.lua` | ADD | Stack push/pop/replace; forward input, resize, visible |
| `scenes/match_setup.lua` | ADD | Edit + validate `MatchConfig`; device assignment; both-player confirm (per designer) |
| `scenes/play.lua` | ADD | Run update pipeline; own match runtime; call mapgen on round start |
| `input/*` | ADD | Semantic actions per player slot; route mouse to “active” player only when scheme uses mouse |
| `systems/world_update.lua` | ADD | Integrate moles, projectiles, grenades; gravity; terrain collision |
| `systems/weapons.lua` | ADD | Fire from active mole using aim/power + selected weapon |
| `systems/explosions.lua` | ADD | Single entry: terrain carve + damage + impulse; honor `friendly_fire` |
| `systems/turn_resolver.lua` | ADD | When world quiescent, advance turn / end round / match |

---

## 5. `love` lifecycle delegation

### `love.load`

1. [`bootstrap`](src/bootstrap.lua) already sets default filter.  
2. Load fonts/assets (boot scene or `app`).  
3. `scene_manager.push(main_menu)` with `Session.new()` held by `app` or first scene.

### `love.update(dt)`

1. `input_state` clear per-frame edges.  
2. `scene_manager.update(dt)`.  
3. In **play**: recommended order aligns with DESIGN.md — input intents → turn FSM → mole movement → projectiles/grenades → explosions / terrain → damage / knockback / fall → death & round/match check → camera.

### `love.draw`

- Background → terrain → entities → FX → HUD (HUD owned by UX modules/scenes).

### Input

- `love.keypressed` / `gamepad*` / mouse → `input_state` → scene_manager → play scene applies only **active player** profile.

---

## 6. Procedural map generation (architectural)

- **Entry:** [`world.mapgen.init.generate(match_config, seed)`](src/world/mapgen/init.lua).  
- **Pipeline (current):** RNG → terrain fill → heightfield surface → cave carve → team spawns → `rebuildImageData`.  
- **Extension point:** Additional stages stay in `mapgen/` with `core/rng` only; no scene coupling.

---

## 7. Dependencies and technology choices

| Choice | Rationale |
|--------|-----------|
| Stock LÖVE 11.4 | Matches [`conf.lua`](conf.lua) `t.version` |
| No extra Lua libs for MVP | Current code uses only std + love |
| Collision stays behind [`world/collision.lua`](src/world/collision.lua) | Swap algorithms without touching entities |
| `Session` RAM-only | Optional later: `love.filesystem` for high scores |

---

## 8. `luaModules` — public API sketch (Coding Agent)

| Path | Purpose | Public surface (indicative) |
|------|---------|------------------------------|
| `src/app.lua` | Wire LÖVE | `register()` |
| `src/scene_manager.lua` | Scene stack | `push`, `pop`, `replace`, `update`, `draw`, `emit(name, ...)` |
| `src/input/bindings.lua` | Key/button → action | `default_bindings()`, lookup helpers |
| `src/input/devices.lua` | 2P routing | `set_from_match_config(c)`, `poll_intents(player, state)` |
| [`game/match_config.lua`](src/game/match_config.lua) | Config | `defaults()`, `validate(c)` — extend only if new lobby fields added |
| [`game/session.lua`](src/game/session.lua) | Session wins | `new()`, `bump_match_win`, `get_scores` |
| [`world/mapgen/init.lua`](src/world/mapgen/init.lua) | Procedural | `generate(match_config, seed)` |
| `systems/explosions.lua` | Combat | `queue` / `apply(world, ex)` |
| `systems/weapons.lua` | Firing | `try_fire(ctx)` |

---

## 9. JSON handoff fragment (orchestrator / tooling)

```json
{
  "architecture": "Scene stack via app+scene_manager; play scene owns match runtime; mapgen.init.generate on round/match start; systems layer coordinates entities + terrain; MatchConfig single schema in game/match_config.lua.",
  "luaModules": "See §8; existing game/world/entity/core/data modules remain sources of truth.",
  "fileStructure": "§2.1; add app.lua, scene_manager, scenes/, input/, systems/.",
  "loveLifecycle": "load → menu; update/draw/input → scene_manager → active scene; play runs ordered systems.",
  "dependencies": ["LÖVE 11.4"],
  "considerations": [
    "main.lua requires app — implement src/app.lua immediately.",
    "MatchConfig: use §3.1 as sole field list; align DESIGN.md Components table with match_config.lua.",
    "friendly_fire must be enforced in systems/explosions.lua (and direct hits if applicable).",
    "grenade_fuse_seconds from MatchConfig should drive grenade entity fuse unless explicitly overridden."
  ]
}
```

---

## 10. Implementation notes for Coding Agent

1. **Unblock boot:** Add [`src/app.lua`](src/app.lua) implementing `register()` and requiring `scene_manager` + initial scene.  
2. **MatchConfig UI:** Match setup scene edits the same keys as §3.1; call `match_config.validate` before play.  
3. **Input scheme:** `input_scheme` in config must agree with `input/devices.lua` (shared KB vs two gamepads); support reassignment of joystick indices in match setup.  
4. **Explosions:** One code path for rocket impact and grenade timeout; read `friendly_fire` from the active match snapshot.  
5. **Testing:** `mapgen.init.generate`, `vec2`, collision helpers runnable with `lua` / busted without opening a window where possible.  
6. **DESIGN.md hygiene:** Replace stale “no main.lua / src” note with §0 snapshot when merging (orchestrator).

---

*Design-only artifact for `.pipeline/love-architect-design.md`. No implementation files created by this agent.*
