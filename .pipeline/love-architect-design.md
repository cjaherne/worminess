# LÖVE Architect Design — `love-architect`

**Scope:** Lua 5.1 / LÖVE 11.x module layout, scene stack, lifecycle delegation, procedural map generation boundaries, input abstraction for 2P local (shared KB+M / dual gamepads).  
**Builds on:** No existing `main.lua` or `src/` in repo (see `.pipeline/architecture-brief.md`). This design defines the **initial** tree; Coding Agent creates files per this spec.

---

## 1. High-level architecture

### Runtime model

- **Single-threaded** LÖVE loop: `love.load` → repeated `love.update(dt)` / `love.draw()`.
- **Scene stack** (not inheritance-heavy): each scene is a table with optional `enter`, `leave`, `update`, `draw`, `keypressed`, `gamepadpressed`, etc. A thin **scene manager** forwards LÖVE callbacks to the top scene and optionally to a **global overlay** (pause, debug).
- **Game session** is a long-lived object created when entering **Play** from menus; it owns match config, roster, turn state, world (terrain + entities), and **session score** (wins since app start — persisted only in RAM unless product later adds saves).
- **Pure Lua leaves** for testability: trajectory math, collision resolution helpers, RNG-seeded map generation **data** (grid of materials / spawn points) separate from `love.graphics` drawing of that data.

### Dependency direction (require graph)

```
main.lua
  → conf.lua (LÖVE config only, no require)
  → src/bootstrap.lua  (optional: package.path for src/)
  → src/app.lua        (wires love.* to SceneManager)

SceneManager
  → scenes/*           (each scene requires only what it needs)

scenes/play.lua
  → src/game/session.lua
  → src/world/map.lua, src/world/terrain.lua
  → src/entities/* (via factory or world)
  → src/systems/* (turn, weapons, physics coordinator)

src/world/mapgen/*   (no love.* except optional debug — prefer pure)
src/systems/physics.lua → may call love.math if acceptable; prefer injected RNG
```

**Rule:** `mapgen` and `core/math_*` must not `require` scenes or `app.lua`. Avoid cycles: entities should not require the scene; pass callbacks or an **event bus** table if needed.

---

## 2. File / directory structure

```
project root/
├── conf.lua                 # window, modules (joystick on)
├── main.lua                 # minimal: require("src.app").register()
├── assets/
│   ├── fonts/
│   ├── images/              # moles, UI, particles (Coding Agent + UX)
│   └── sounds/
└── src/
    ├── app.lua              # love.load/update/draw/key*/gamepad* → SceneManager
    ├── scene_manager.lua    # stack push/pop/replace, callback forwarding
    ├── input/
    │   ├── bindings.lua     # action → keys + gamepad buttons/axes
    │   ├── devices.lua      # which player uses keyboard vs which joystick index
    │   └── input_state.lua  # edge vs level per frame (optional helper)
    ├── data/
    │   ├── weapons.lua      # weapon defs: type, fuse, radius, damage falloff (data tables)
    │   └── constants.lua    # gravity, default teams size, etc.
    ├── core/
    │   ├── rng.lua          # seeded wrapper (love.math.random or own state)
    │   ├── vec2.lua         # tiny 2D helpers (pure)
    │   └── timer.lua        # countdowns (grenade fuse, turn clock)
    ├── game/
    │   ├── session.lua      # session scores, match settings, seed
    │   ├── match_config.lua # schema + defaults (health, wind, turn time…)
    │   ├── roster.lua       # 2 players × 5 moles, alive/dead, team colors
    │   └── turn_state.lua   # current player, active mole index, phase enum
    ├── world/
    │   ├── map.lua          # width/height, spawn points, bounds
    │   ├── terrain.lua      # destructible mask / collision field API
    │   ├── collision.lua    # segment vs terrain, explosion carving (mostly pure + terrain mutator)
    │   └── mapgen/
    │       ├── init.lua     # public: generate(match_config, seed) → map + terrain
    │       ├── heightfield.lua
    │       ├── caves.lua    # optional worm-style negative space
    │       └── spawns.lua   # fair P1/P2 spawn placement
    ├── entities/
    │   ├── mole.lua         # state: pos, vel, hp, facing, grounded
    │   ├── projectile.lua   # rocket: instant ray or segmented sweep (design choice for coder)
    │   └── grenade.lua      # pos, vel, fuse, bounce
    ├── systems/
    │   ├── world_update.lua # integrate entities, apply gravity, terrain collision
    │   ├── weapons.lua      # fire rocket/grenade from active mole; ammo rules
    │   ├── explosions.lua   # damage moles + carve terrain
    │   └── turn_resolver.lua# end turn conditions, rotate player/mole
    └── scenes/
        ├── boot.lua         # load assets, fonts, audio (optional minimal)
        ├── main_menu.lua
        ├── match_setup.lua  # health, optional wind, seed display, input assignment
        ├── play.lua         # main gameplay scene
        ├── pause.lua        # overlay or sub-state
        └── game_over.lua    # round winner, session score, rematch → new map
```

**Note:** Exact file names are prescriptive for the Coding Agent; splitting `grenade`/`projectile` into one `entities/missiles.lua` is acceptable if documented in merged design.

---

## 3. Key data models, interfaces, schemas

### 3.1 `MatchConfig` (table shape)

| Field | Type | Purpose |
|--------|------|---------|
| `mole_max_hp` | number | Per-mole health |
| `turn_time_limit` | number \| nil | Seconds; nil = no limit |
| `wind_strength` | number | Optional; scalar or vec2 for drift |
| `map_width`, `map_height` | int | Pixel or cell size (one convention, document in code) |
| `teams_per_player` | int | Fixed 5 for this product |
| `procedural_seed` | int \| nil | nil → random seed at match start |

### 3.2 `Session` (in-memory)

| Field | Purpose |
|--------|---------|
| `scores` | `{ [playerId] = wins }` since app launch |
| `last_match_config` | For “play again” / rematch defaults |

### 3.3 `Roster`

- `players[1..2]` each: `{ moles = { moleState × 5 }, color, device_binding }`
- `moleState`: `{ id, hp, alive, spawn_index }` + reference or embed transform for active mole

### 3.4 `TurnState`

- `active_player` — 1 or 2  
- `active_mole_index` — 1..5 (only among alive moles for that player)  
- `phase` — e.g. `"aim"`, `"flying"`, `"resolve"`, `"round_end"`  
- **Rotation rule** (mechanical, but architecturally stored here): after each **completed** turn, advance `active_player` then choose next **alive** mole for that player (Game Designer may specify worm-style “walk order”; architecturally it’s a function `turn_resolver.next()`).

### 3.5 Terrain / map (API sketch, not code)

- **Terrain** exposes:
  - `is_solid(x, y)` → bool  
  - `damage_circle(cx, cy, radius, destroy_mask)` or polygon carve for explosions  
  - Optional `surface_normal(x, y)` for sliding
- **Map** exposes:
  - Spawn positions per player  
  - World bounds for camera clamping  

### 3.6 Weapon definitions (`src/data/weapons.lua`)

Named entries, e.g. `rocket`, `grenade`:

- `damage`, `radius`, `terrain_radius`  
- Grenade: `fuse_seconds`, `restitution`, `roll_friction` (tuning)  
- Rocket: `speed`, `hit_radius`, `trail` (presentation; optional)

---

## 4. Component breakdown and responsibilities

| Module | Responsibility |
|--------|----------------|
| `app.lua` | Register `love` callbacks; fixed timestep optional; delegate to `scene_manager` |
| `scene_manager.lua` | Stack, `push`/`pop`/`replace`, forward input and resize |
| `scenes/match_setup.lua` | Edit `MatchConfig`, assign P1 KB vs P2 pad (or both pads), start match |
| `scenes/play.lua` | Own `GameSession` instance; call world/systems update/draw; HUD hooks (UX layer may override draw order) |
| `game/session.lua` | Create/destroy session, bump score on round end, hold `MatchConfig` |
| `world/mapgen/*` | Deterministic procedural terrain + spawns from seed |
| `systems/weapons.lua` | Spawn projectiles from active mole aim vector |
| `systems/explosions.lua` | Unified entry: apply damage to moles + carve terrain |
| `systems/turn_resolver.lua` | When projectiles settle and no pending animations, advance turn |
| `input/*` | Map raw LÖVE events to semantic actions: `aim_left`, `aim_right`, `fire`, `jump`, `weapon_next`, `pause` per **slot** (player 1 / player 2) |

---

## 5. `love` lifecycle delegation

### `love.load`

1. `love.graphics.setDefaultFilter` (if desired)  
2. Load fonts/images/audio (scene `boot` or `app`)  
3. `SceneManager.push(MainMenu)`  

### `love.update(dt)`

1. `InputState` tick (clear “pressed this frame”)  
2. `SceneManager.update(dt)` → top scene; play scene updates `GameSession` → systems order:  
   - **Suggested order:** timers (grenades) → physics/integration → collisions → explosions queue → turn check → camera  

### `love.draw`

1. Clear / background  
2. `SceneManager.draw()` — play scene: world (terrain, entities, particles) then UI  

### Input callbacks

- `love.keypressed` / `love.keyreleased` → `InputState` + `SceneManager` forward  
- `love.gamepadpressed` / `joystick` events → same; use `joystick:getID()` or LÖVE gamepad index consistently  

**Mouse (shared keyboard/mouse):** Typically **only active player** uses mouse for aiming in hotseat; architecturally, `input/devices.lua` marks P1 or P2 as “mouse owner” and play scene routes `love.mousemoved` to aim angle for that slot.

---

## 6. Procedural map generation (architectural)

- **Entry:** `mapgen.init.generate(config, seed)` returns `{ map = Map, terrain = Terrain }` (constructors defined in `map.lua` / `terrain.lua`).  
- **Pipeline stages (conceptual):**  
  1. **Heightfield** — base surface (1D or 2D height array).  
  2. **Optional caves** — subtract tunnels/caverns for Worms-like variety.  
  3. **Material mask** — air vs ground vs indestructible border.  
  4. **Spawns** — place 5 mole anchors per side, min separation and line-of-sight sanity checks; if fail, re-roll sub-seed or nudge positions (max attempts).  
- **Determinism:** All randomness through `core/rng.lua` with match seed logged in debug overlay for repro.  
- **Performance:** Generate once per round; gameplay mutates terrain only via explosions.

---

## 7. Dependencies and technology choices

| Choice | Rationale |
|--------|-----------|
| **Stock LÖVE 11.x** | No extra Lua libs required for MVP; keeps bootstrap simple. |
| **`love.joystick` + `love.keyboard` + `love.mouse`** | 2P local: one keyboard+mouse + one gamepad, or two gamepads; bindings table centralizes differences. |
| **Lua 5.1 module pattern** | `local M = {} … return M` per file; matches LÖVE embedding. |
| **No globals for game state** | `GameSession` table passed into scenes/systems; only `SceneManager` module-level singleton acceptable if documented. |
| **Optional later:** `bump.lua` or custom grid — architecturally keep **collision** behind `world/collision.lua` so swapping implementation is localized. |

---

## 8. `luaModules` — public API sketch (for Coding Agent)

| Path | Purpose | Public surface (indicative) |
|------|---------|------------------------------|
| `src/app.lua` | Wire LÖVE | `register()` |
| `src/scene_manager.lua` | Scene stack | `push(s)`, `pop()`, `replace(s)`, `update(dt)`, `draw()`, `send(event, ...)` |
| `src/input/bindings.lua` | Defaults | `default_actions()`, `action_for_key(key)`, `action_for_button(btn)` |
| `src/input/devices.lua` | 2P routing | `set_scheme(scheme)`, `actions_for_player(p, input_snapshot)` |
| `src/game/match_config.lua` | Defaults | `defaults()`, `validate(c)` |
| `src/game/session.lua` | Session | `new(config)`, `on_round_winner(player)`, `get_scores()` |
| `src/game/turn_state.lua` | Turns | `new(roster)`, `advance_after_turn()`, `current_mole()` |
| `src/world/terrain.lua` | Destructible world | `new(w,h)`, methods as in §3.5 |
| `src/world/mapgen/init.lua` | Procedural | `generate(config, seed)` |
| `src/systems/explosions.lua` | Combat | `apply(world, payload)` |
| `src/systems/weapons.lua` | Firing | `try_fire(session, weapon_id, aim)` |

---

## 9. JSON handoff fragment (orchestrator / tooling)

```json
{
  "architecture": "Scene stack + GameSession; pure mapgen and math leaves; input layer maps devices to per-player actions; systems pipeline in play scene.",
  "luaModules": "See §8 table; each maps to path under fileStructure.",
  "fileStructure": "See §2 tree; root main.lua + conf.lua + src/* + assets/*",
  "loveLifecycle": "load → push menu; update → scene then session systems in order; draw → scene; input → InputState then scene",
  "dependencies": ["LÖVE 11.x stock APIs only for baseline"],
  "considerations": [
    "Avoid circular requires: entities take world interfaces, not scenes.",
    "Rocket vs terrain: choose raycast+instant explode vs fast projectile early; keep in one system file.",
    "Session score is RAM-only unless persistence added later via love.filesystem.",
    "Joystick indices: test hot-plug; devices.lua should tolerate missing pad (show UI warning)."
  ]
}
```

---

## 10. Implementation notes for Coding Agent

1. **`conf.lua`:** Enable `t.modules.joystick = true`; set title; reasonable default window size for split terrain view.  
2. **Scene transitions:** New round → regenerate map with new seed (or “same seed” debug option from match setup).  
3. **Active mole only:** Input for weapons applies only to `turn_state:current_mole()`; other moles are idle (or cosmetic idle anim — UX).  
4. **Grenades vs rockets:** Share explosion path in `systems/explosions.lua`; differ only in flight (`entities/grenade.lua` vs `projectile.lua`).  
5. **Camera:** Single camera following active mole or free-look between turns — product decision; keep camera state in `play.lua` or `game/session.lua`, not globals.  
6. **Testing hooks:** Expose `mapgen.init.generate` and trajectory functions without requiring `love.graphics`; use `busted` or plain `lua` tests on those modules if CI adds Lua later.  
7. **Merge alignment:** Game Designer owns exact turn order, damage numbers, and control schemes; LÖVE UX owns HUD/layout — this document owns **where** those concerns live in code.

---

*End of love-architect design. No implementation files were created.*
