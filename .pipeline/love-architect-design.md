# LÖVE Architect Design — “Moles” (Worms-style clone)

**Agent:** `love-architect`  
**Scope:** Module boundaries, `require` graph, LÖVE lifecycle delegation, procedural map *architecture* (not art direction), session score tracking *architecture*.  
**Handoff:** Game Designer owns turn/weapon rules; LÖVE UX owns screens/HUD styling. This doc defines **where** logic lives and **how** the runtime wires it.

**Traceability:** Maps to `REQUIREMENTS.md` R1–R11.

---

## 1. High-level architecture

### 1.1 Runtime model

- **Single-threaded** LÖVE 11.x loop: `love.load` → repeated `love.update(dt)` / `love.draw()`.
- **Scene stack** (or ordered scene registry): `Boot` → `MainMenu` → `MatchSetup` → `Play` → `RoundEnd` / `MatchEnd` → back to menu or rematch. `Pause` overlays `Play` when active.
- **World simulation** during `Play`: deterministic-ish fixed timestep or capped `dt` (coding agent chooses; document recommends max `dt` clamp for stability).
- **Separation:**
  - **Simulation** (`src/sim/`, `src/world.lua`): positions, health, terrain mutations, projectiles, explosions — **no** `love.graphics` except where unavoidable (prefer passing drawables from assets layer).
  - **Presentation** (`src/render/`, `src/ui/`): cameras, sprites, particles, HUD; reads **snapshots** or immutable view structs from sim to avoid tearing during draw.
  - **Input** (`src/input/`): maps devices → **intent** (move, aim, fire, jump, weapon cycle, menu navigate). Play scene consumes intents, not raw keys.

### 1.2 Data flow (one frame in `Play`)

```
love.update(dt)
  → input.poll() → PlayerIntents[1..2]  -- R10: mouse routed only to turn owner when shared_kb
  → turn_state.on_frame(dt)             -- optional turn timer; end-turn commits handled by scene/input
  → world.update(dt, intents)         -- moles, projectiles, terrain, damage
  → camera.follow(active_mole)
  → session_scores unchanged until match end

love.draw()
  → render.background / parallax (optional)
  → render.terrain(world.terrain)
  → render.entities(world)
  → render.effects(particles)
  → ui.hud(match_state, intents feedback)
```

### 1.3 Parallel pipeline contract

| Owner | This architect |
|-------|----------------|
| Module paths & public APIs | Yes |
| `love.load` / `update` / `draw` delegation | Yes |
| Turn order, damage tables, weapon tuning numbers | Designer (consume via `MatchRules` / config tables) |
| Pixel look, fonts, menu layout | UX |

---

## 2. File / directory structure (proposed)

**Repo baseline (already present):** `main.lua` (forwards `love.*` to `app` after `setRequirePath`), `conf.lua` (LÖVE 11.4 window identity), `DESIGN.md` / `REQUIREMENTS.md`, `src/config.defaults.lua` (grid, gravity, weapon tuning, wind forces, palette — **not** match-setup UI defaults), `src/data/match_settings.lua` (`defaults`, `validate`, `merge_partial`; `input_mode` is `shared_kb` \| `dual_gamepad`), `src/data/session_scores.lua` (session counters + `record_match_outcome` / `get_snapshot`), `src/sim/terrain_gen.lua`, `src/sim/terrain.lua`, `src/sim/physics.lua`, `src/sim/damage.lua`, `src/sim/turn_state.lua` (turn model; header defers to Game Designer), `src/util/timer.lua`, `src/util/vec2.lua`.

**Still to add:** `src/app.lua` (required by `main.lua` but not in tree yet), `src/scenes/*`, `src/world.lua` (or equivalent integrator), moles/projectiles/weapons, `src/render/*`, `src/input/*`, `assets/*`, optional `keymaps_shared.lua`. **Do not** scatter globals in `main.lua` beyond forwarding callbacks.

```
project root/
  main.lua                 -- [exists] setRequirePath; forward love.* → app
  conf.lua                 -- [exists] identity, window, vsync
  DESIGN.md                -- [exists] merged designer/UX/architect source
  REQUIREMENTS.md          -- [exists] R1–R11 IDs

  assets/
    fonts/                 -- TTF/OTF (UX)
    images/                -- sprites, tiles (UX)
    shaders/               -- optional water/sky (UX)

  src/
    app.lua                -- [add] scene manager, love callbacks entry
    bootstrap.lua          -- optional if path logic moves out of main.lua

    config.defaults.lua    -- [exists] sim/world tuning, weapon numbers, colors (see repo)

    scenes/
      scene.lua            -- base: enter/exit/update/draw (minimal)
      boot.lua
      menu.lua
      match_setup.lua      -- R9 match variables, input mode (R10/R11)
      play.lua
      pause.lua
      round_end.lua
      match_end.lua

    input/
      input_manager.lua    -- [add] aggregates devices; applies turn_owner + input_mode policy
      keyboard_mouse.lua   -- [add] R10: shared_kb only — dual keymaps + turn-owner mouse
      keymaps_shared.lua   -- [add] optional: logical action names / scancode tables for R10
      gamepad.lua          -- [add] R11: dual_gamepad — per-joystick mapping for P1/P2

    sim/
      world.lua            -- [add] World table: terrain, entities, projectiles; step()
      terrain.lua          -- [exists] destructible terrain / queries (extend as needed)
      terrain_gen.lua      -- [exists] procedural generation (see §5)
      mole.lua             -- mole state: team, hp, facing, grounded, weapon
      projectile.lua       -- rocket, grenade base behavior
      weapons/
        registry.lua       -- weapon id → module
        rocket.lua
        grenade.lua
      physics.lua          -- [exists] gravity, walking, collision helpers (extend)
      damage.lua           -- [exists] damage / knockback hooks (extend)
      turn_state.lua       -- [exists] active_player, mole_slot, end_turn, timer (R8)

    render/
      camera.lua
      terrain_draw.lua
      mole_draw.lua
      effects.lua          -- particles tied to sim events

    ui/
      hud.lua              -- wind, team HP summary, weapon, timer (coordinates with UX)
      widgets.lua          -- optional shared UI helpers

    data/
      session_scores.lua   -- [exists] R6 session counters
      match_settings.lua   -- [exists] match options + input_mode enum
      save_format.lua      -- versioned table for future expansion

    util/
      timer.lua            -- [exists]
      vec2.lua             -- [exists] pure 2D math
      signal.lua           -- optional decoupling: sim emits events for audio/FX
```

**Modification note:** Extend the tree above without renaming existing modules unless the merged `DESIGN.md` explicitly refactors them. `REQUIREMENTS.md` remains the requirement ID source. **Turn semantics:** normative default is **Game Designer pseudocode** in root `DESIGN.md` (Turn model); §4.1 maps it to `src/sim/turn_state.lua` and must not contradict it.

---

## 3. Key data models & interfaces

### 3.1 `MatchSettings` (R7, R9)

Table (Lua) validated in `match_settings.lua`:

```lua
-- Pseudocode shape (not implementation)
MatchSettings = {
  moles_per_team = 5,           -- R7 fixed for v1 or configurable upper bound 5
  mole_max_hp = 100,            -- R9
  turn_time_seconds = 60,       -- optional designer default
  wind_enabled = true,
  input_mode = "shared_kb" | "dual_gamepad",  -- align with src/data/match_settings.lua
  -- extend: gravity, fuse time for grenades, rocket blast radius multipliers
}
```

### 3.2 `SessionScores` (R6)

- **Scope:** “since launching” the executable → **session-only** in-memory counters unless product later asks for disk persistence.
- **Suggested fields:**

```lua
SessionScores = {
  player1_wins = 0,
  player2_wins = 0,
  draws = 0,
  games_played = 0,
}
```

- **API sketch** (`session_scores.lua`):

```lua
session_scores.reset()
session_scores.record_match_outcome(winner_id)  -- 0 = draw
session_scores.get_snapshot()  -- for HUD / match end screen
```

- **Persistence:** Optional Phase 2: `love.filesystem.write` JSON-like encoded table; v1 can skip file I/O to satisfy “since launching” literally.

### 3.3 `World` / entity handles

- **Terrain:** 2D destructible field. Recommended: **bitmap/grid** of material IDs + surface normals cached for walking/aim, or **mask image** LÖVE `ImageData` for blast carving (performance-sensitive; coding agent benchmarks).
- **Moles:** array or map of structs: `{ id, player_id, team_slot, x, y, vx, vy, hp, facing, current_weapon, alive }`.
- **Projectiles:** list of `{ type, owner_id, x, y, vx, vy, fuse, ... }`.
- **Turn state** (`turn_state.lua`): `{ active_player, active_mole_index, phase = "aim" | "moving" | "firing", time_left }` aligned with Designer’s turn rules.

### 3.4 `PlayerIntent` (R4, R10, R11)

Per player slot, per frame (R10: non–turn-owner may still produce a table, but `input_manager` zeros gameplay fields or ignores mouse so only **turn owner** drives sim):

```lua
PlayerIntent = {
  move_x = -1..1,
  move_y = -1..1,   -- optional for ladders; 0 if worms-like horizontal only
  aim_x, aim_y,     -- world space or normalized direction
  jump = bool,
  fire_pressed = bool,
  fire_released = bool,  -- for grenade charge if designer specifies
  cycle_weapon = bool,
  menu_confirm = bool,
}
```

`input_manager.lua` fills intents from keyboard/mouse/gamepad **without** `Play` knowing raw device IDs.

---

## 4. Component breakdown & responsibilities

| Module | Responsibility |
|--------|----------------|
| `app.lua` | Scene stack, global services (`input`, `session_scores`, `assets`), dispatches `love.*` |
| `scenes/*.lua` | UI flow only; `play.lua` owns `World` lifecycle (create from `terrain_gen` + spawn moles) |
| `input_manager.lua` | **R10:** `shared_kb` — one keyboard + one mouse, **turn-owner routing** (mouse aim only for active player per `DESIGN.md`). **R11:** `dual_gamepad` — assign joystick 1→P1, 2→P2 via `gamepad.lua` |
| `terrain_gen.lua` | R5: deterministic seed → terrain + spawn points; **pure function** ideal for tests |
| `world.lua` | Integrates sim subsystems; order: projectiles → explosions → terrain → moles |
| `weapons/rocket.lua` | Straight-line or arced shot; blast radius; terrain carve; damage falloff (numbers from Designer) |
| `weapons/grenade.lua` | Timed fuse, bounce optional; explosion same pipeline as rocket |
| `turn_state.lua` | **R8:** Must match **`DESIGN.md` Turn model pseudocode**; see §4.1 mapping to `src/sim/turn_state.lua` (`end_turn`, `advance_after_turn`, timers) |
| `session_scores.lua` | R6: increment on `match_end` |
| `match_setup.lua` | R9: edit `MatchSettings`, select input mode, start match |

### 4.1 Turn rotation (R8) — **defer to Game Designer pseudocode; map to `turn_state.lua`**

**Normative default (behavioral contract):** Root **`DESIGN.md`** → *Game Designer* → **“Turn model (Players + Moles Rotation)”**, including the pseudocode block:

- `on_match_start()` — first player + each team’s first living mole; **no** roster advance before first turn.
- `on_end_turn(ended_player)` — `advance_mole_index(ended_player)` then `turn_player = other(ended_player)`.
- `advance_mole_index(p)` — walk roster ring `1..5`, skip dead moles until a living slot or team eliminated.

The same text appears in `.pipeline/game-designer-design.md` for pipeline history. **If this architect document or any code comment disagrees with that pseudocode, the Game Designer block in `DESIGN.md` wins** — treat this subsection as **implementation routing**, not an alternate ruleset.

**Module mapping (existing code):** `src/sim/turn_state.lua`

| Designer concept | Implementation hook |
|------------------|----------------------|
| `turn_player` | `active_player` (1 \| 2) |
| `mole_index[p]` | `mole_slot[p]` (slots 1..5 aligned with mole entities) |
| `on_match_start` / first player | `M.new(settings)` resolves `first_player` (`"random"` uses `love.math.random`) |
| `on_end_turn` + advance | `M:end_turn(moles, settings)` → `advance_after_turn` then `sync_slots_to_living` |
| Turn time limit | `M:update_timer(dt, moles, settings)` when `turn_time_seconds > 0` |

**Coding Agent checklist (must match pseudocode, not this table alone):**

- Ending a turn advances **only** the **ended** player’s roster pointer; opponent’s slot is unchanged until their own turns complete.
- **`advance_mole_index` semantics:** Designer pseudocode **steps the ring at least once** (`next_index_in_ring` before accepting a living mole). The ended player’s **next** turn must control a **different roster slot** than the mole who just acted (unless only one living mole remains). Reconcile `M:advance_after_turn` in `src/sim/turn_state.lua` if it ever re-selects the same `mole_slot` while that mole is still alive.
- Exactly one active mole receives movement / aim / fire for the current `active_player` (resolve via `active_mole(moles)` or equivalent).
- Weapon tuning and friendly-fire defaults remain in `src/config.defaults.lua` + `match_settings`, not in `turn_state.lua`.

**`MatchRules` / weapons:** Damage tables and fuse times are Designer-owned; `turn_state` consumes **living** flags and slot indices from the world/mole list only.

---

## 5. Procedural map generation (architectural plan)

**Module:** `src/sim/terrain_gen.lua` (pure Lua; testable without LÖVE if terrain is arrays; if using `love.imagegenerator`, isolate IO behind `terrain_gen.build(seed, width, height) → TerrainModel`).

**Suggested pipeline:**

1. **Base shape:** Perlin/simplex heightmap or stacked sine bands → solid vs air boolean grid.
2. **Layers:** Optional strata (dirt, rock) for different blast resistance (Designer).
3. **Water / hazards:** Optional plane at bottom; moles spawn above water line.
4. **Spawn platforms:** Sample two regions (left/right thirds) for flat surfaces wide enough for 5 moles; if fail, reject and re-seed (bounded retries).
5. **Determinism:** `seed = os.time()` or user-entered seed from setup for reproducibility.

**Output:** `TerrainModel` consumed by `terrain.lua` to build runtime collision/render buffers.

**Performance note:** Regenerate only between matches, not each frame.

---

## 6. Score tracking (R6) — lifecycle hooks

| Event | Action |
|-------|--------|
| `love.load` | `session_scores` initialized once |
| `match_end` scene | Read winner from `World` / `turn_state`; call `record_match_outcome` |
| `menu` / HUD | Display running totals from `get_snapshot()` |

No requirement to persist across app restarts for v1.

---

## 7. LÖVE lifecycle delegation

### 7.1 `conf.lua`

- Title, window size, `t.modules` defaults; optional `t.console = true` for dev.

### 7.2 `main.lua`

**Existing pattern:** `love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. ...)` then `local app = require("app")` — **not** `require("src.app")`. Forward `love.keypressed` / `keyreleased` / mouse / joystick / `resize` as already stubbed in repo `main.lua`.

### 7.3 `app.lua`

- `load`: init `love.graphics` defaults, load fonts/images (via asset loader), create `InputManager`, `SessionScores`, push `Boot` → `Menu`.
- `update`: `input_manager.update()`; top scene `update(dt)`; scene may substitute stack (pause push/pop).
- `draw`: clear; scenes draw bottom-up; global HUD overlays if scene requests.

### 7.4 `play.lua` specifics

- `enter`: build `MatchSettings` from setup; `terrain = terrain_gen.build(...)`; spawn 10 moles (5 per player); init `turn_state`; reset camera.
- `update`: pass intents to `world.update`; detect win condition (one side all dead) → transition `match_end`.
- `leave`: dispose large objects if needed; keep `session_scores` alive on `app`.

---

## 8. Dependencies & technology choices

| Choice | Rationale |
|--------|-----------|
| **Stock LÖVE 11.x** | No external Lua rocks required for MVP; simpler CI and distribution. |
| **Lua version** | Target LuaJIT (LÖVE default); avoid 5.4-only APIs (`table.unpack` portability if shared code). |
| **No middleweight ECS library** | Small team count; plain tables + functions keep blueprint clear. |
| **Optional `push`/`hump` libraries** | Only if coding agent needs camera/timer; prefer minimal `src/util` first. |
| **Destructible terrain** | `ImageData` or Canvas mask is idiomatic in LÖVE; architect leaves final representation to coding agent with perf budget. |

---

## 9. `require` direction (avoid cycles)

```
app → scenes → world → (terrain, mole, projectile, weapons/*, turn_state)
app → input → (keyboard_mouse, gamepad)
world → util/vec2, util/timer
scenes → session_scores, match_settings
terrain_gen → (no scene/world imports)
```

**Rule:** `terrain_gen`, `damage`, `vec2` are **leaves** or near-leaves. `world` must not `require` `render/*`.

---

## 10. Implementation notes for the Coding Agent

1. **Fixed order in `world.update`:** wind → mole movement (active only) → weapon charge → projectiles → collisions → damage application → death removal → win check.
2. **Active mole:** `turn_state` exposes `get_active_mole_id()`; `world` ignores movement intents for others (or zeroes them in `input_manager` for cleaner separation — pick one place only).
3. **Rocket vs grenade:** share an `explosion_at(x, y, radius, damage_table)` in `damage.lua` / `world.lua` to avoid duplication.
4. **R10 (shared keyboard + mouse only):** Implement only when `input_mode == "shared_kb"`. Route **mouse aim and LMB** to the **turn owner** only; the idle player’s mouse does not steer aim (per `DESIGN.md`). Both players use distinct **keyboard** bindings on one device; suggested layouts live in Game Designer doc — implement in **`keyboard_mouse.lua`** (and optionally a thin router module). **Do not** put key strings in `src/config.defaults.lua` (physics, weapon numbers, colors).
5. **R11 (dual gamepad):** When `input_mode == "dual_gamepad"`, `love.joystick.getJoysticks()` (or menu ordering): joystick 1 → P1, joystick 2 → P2 in `gamepad.lua`; hotplug → pause or setup fallback.
6. **Testing hooks:** Keep `terrain_gen.generate(seed, w, h, rules) → grid` pure; keep `damage.compute(hp, distance, falloff)` pure for unit-style tests in pipeline if added later.
7. **Art vs sim:** Moles are capsules or simple AABB in sim; render can be skeletal sprites — **do not** tie collision to sprite pixel bounds without scaling factor.

---

## 11. JSON summary (orchestrator / merge-friendly)

```json
{
  "architecture": "LÖVE 11 scene stack (menu → setup → play → end); sim/render/input separation; world.update consumes PlayerIntents; session_scores updated at match end only.",
  "luaModules": {
    "src/app.lua": "Scene stack, love.* forwarding, service singletons",
    "src/scenes/play.lua": "Owns World lifecycle, win detection, camera target",
    "src/input/input_manager.lua": "Public: update(), get_intents(), reconfigure(MatchSettings)",
    "src/sim/world.lua": "Public: new(settings), update(dt, intents), draw_snapshot accessors",
    "src/sim/terrain_gen.lua": "Public: build(seed, width, height, rules) → TerrainModel (pure preferred)",
    "src/sim/turn_state.lua": "Public: init(world, settings), get_turn_player(), get_active_mole_id(), on_end_turn(ended_player), on_frame(dt) for optional timer; advance_mole_index internal per DESIGN.md",
    "src/data/session_scores.lua": "Public: reset(), record_match_outcome(winner), get_snapshot()",
    "src/data/match_settings.lua": "Public: defaults(), validate(t), merge_partial(ui_fields)"
  },
  "fileStructure": "See §2; root main.lua + conf.lua + src/** + assets/**",
  "loveLifecycle": "main.lua → app.load/update/draw; scenes handle domain; play delegates to world",
  "dependencies": ["LÖVE 11.x stock; optional small libs only if justified"],
  "considerations": [
    "Destructible terrain is perf-sensitive; generate once per match",
    "Turn order and roster advance: Game Designer pseudocode in DESIGN.md is normative",
    "Single source of truth for weapon tuning: config.defaults + match_settings",
    "Input mode switching must rebuild bindings without restarting app",
    "Session scores are in-memory for v1 unless extended"
  ]
}
```

---

## 12. Requirements crosswalk

| ID | Architectural home |
|----|---------------------|
| R1 | scenes + render + assets (styled presentation) |
| R2 | `weapons/rocket.lua` + shared explosion path |
| R3 | `weapons/grenade.lua` + fuse/timer in projectile |
| R4 | `input_manager` two slots; `play` sim for two teams |
| R5 | `terrain_gen.lua` + `terrain.lua` |
| R6 | `session_scores.lua` + `match_end` scene |
| R7 | spawn 5 moles per player in `play.enter` |
| R8 | `turn_state.lua` + Designer rules table |
| R9 | `match_setup.lua` → `MatchSettings` |
| R10 | **`keyboard_mouse.lua`** — shared **one keyboard + one mouse**; turn-owner mouse aim + dual keymaps (`shared_kb` only; see `DESIGN.md` controls) |
| R11 | `input_manager.lua` + `gamepad.lua` **dual joystick** slot assignment (`dual_gamepad`) |

---

*End of love-architect design. No implementation files were added by this agent.*
