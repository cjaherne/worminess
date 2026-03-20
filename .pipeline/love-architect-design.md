# LÖVE Architect Design — “Moles” (Worms-style clone)

**Agent:** `love-architect`  
**Scope:** Module boundaries, `require` graph, LÖVE lifecycle delegation, procedural map *architecture* (not art direction), session score tracking *architecture*.  
**Handoff:** Game Designer owns turn/weapon rules; LÖVE UX owns screens/HUD styling. This doc defines **where** logic lives and **how** the runtime wires it.

**Traceability:** Maps to `REQUIREMENTS.md` R1–R11.

---

## 1. High-level architecture

### 1.1 Runtime model

- **Single-threaded** LÖVE 11.x loop: `love.load` → repeated `love.update(dt)` / `love.draw()`.
- **Scene stack** (as implemented in `src/app.lua`): `menu` → `match_setup` → `play` → `match_end`; `pause` is pushed on top of `play` when active. Helpers: `app.goto`, `app.end_match`, `app.quit_match_to_results` (pops play + pause, records `session_scores`, pushes `match_end`).
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

## 2. File / directory structure (as-built + extension points)

**Documentation at repo root:** `DESIGN.md` (merged Part A–C), `REQUIREMENTS.md`, `CODING_NOTES.md` (deferrals / coder notes), `README.md` (run + controls), `ASSETS.md` (sprite manifest).

**Core entry:** `main.lua` → `require("app")` after `setRequirePath`; forwards `love.*` including `textinput`.

```
project root/
  main.lua, conf.lua
  DESIGN.md, REQUIREMENTS.md, CODING_NOTES.md, README.md, ASSETS.md

  assets/sprites/          -- mole teams, rocket, grenade, HUD weapon/wind icons (see ASSETS.md)
  tools/gen_sprites.mjs    -- optional art pipeline

  src/
    app.lua                -- scene stack, assets/fonts, viewport wrapper, match/session hooks
    config.defaults.lua      -- grid, physics, weapon tuning, wind_force table, colors

    audio/sfx.lua          -- procedural SFX init/play

    data/match_settings.lua
    data/session_scores.lua

    input/input_manager.lua
    input/keyboard_mouse.lua
    input/gamepad.lua

    scenes/menu.lua
    scenes/match_setup.lua -- R9 + input_mode (R10/R11 selector)
    scenes/play.lua
    scenes/pause.lua
    scenes/match_end.lua

    sim/world.lua          -- integrates terrain, moles, wind, weapons, turn_state
    sim/terrain.lua
    sim/terrain_gen.lua    -- R5 procedural map (see §5)
    sim/mole.lua
    sim/physics.lua
    sim/damage.lua
    sim/turn_state.lua     -- R8; normative rules → DESIGN.md Part A pseudocode
    sim/weapons/registry.lua, rocket.lua, grenade.lua

    render/camera.lua, terrain_draw.lua, mole_draw.lua
    ui/hud.lua

    util/timer.lua, vec2.lua, viewport.lua, gamepad_menu.lua
```

**Optional / not present:** dedicated `effects.lua`, `save_format.lua`, `signal.lua` — add only if new features need them.

**Modification note:** Prefer editing existing modules over duplicating responsibilities. **Turn semantics:** root `DESIGN.md` **Part A — Game Designer — Turn model** (pseudocode) is **normative**; merged `DESIGN.md` states it **overrides** conflicting prose in other pipeline docs — see §4.1.

---

## 3. Key data models & interfaces

### 3.1 `MatchSettings` (R7, R9)

Table (Lua) validated in `match_settings.lua`:

```lua
-- Pseudocode shape (not implementation)
MatchSettings = {
  moles_per_team = 5,           -- R7 (validated fixed to 5 in match_settings.lua)
  mole_max_hp = 100,            -- R9
  first_player = "1" | "2" | "random",
  friendly_fire = bool,
  turn_time_seconds = 0,        -- 0 = off (see match_settings clamp)
  map_seed = int | nil,
  input_mode = "shared_kb" | "dual_gamepad",
  wind = "off" | "low" | "med" | "high",
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
- **Turn state** (`turn_state.lua`): `active_player` (1 \| 2), `mole_slot[1..2]`, `turn_time_left` / `_turn_limit`; resolve active entity with `active_mole(moles)`. Phase splitting (move vs aim) may live in `world.lua` / UX; rotation rules are **only** from `DESIGN.md` pseudocode.

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
| `input_manager.lua` | Selects `keyboard_mouse` vs `gamepad` from `input_mode`; applies **turn-owner** gating for gameplay. **R11** implementation: `gamepad.lua`. **R10** is **not** owned here for traceability — see `keyboard_mouse.lua` (§12 R10). |
| `terrain_gen.lua` | R5: deterministic seed → terrain + spawn points; **pure function** ideal for tests |
| `world.lua` | Integrates sim subsystems; order: projectiles → explosions → terrain → moles |
| `weapons/rocket.lua` | Straight-line or arced shot; blast radius; terrain carve; damage falloff (numbers from Designer) |
| `weapons/grenade.lua` | Timed fuse, bounce optional; explosion same pipeline as rocket |
| `turn_state.lua` | **R8:** Must match **`DESIGN.md` Turn model pseudocode**; see §4.1 mapping to `src/sim/turn_state.lua` (`end_turn`, `advance_after_turn`, timers) |
| `session_scores.lua` | R6: increment on `match_end` |
| `match_setup.lua` | R9: edit `MatchSettings`, select input mode, start match |

### 4.1 Turn rotation (R8) — **default = Game Designer pseudocode (`DESIGN.md` Part A)**

**Authoritative spec (do not paraphrase for behavior):** Root **`DESIGN.md`**, **Part A — Game Designer**, section **“Turn model (players + moles rotation)”**, including the `on_match_start` / `on_end_turn` / `advance_mole_index` pseudocode. The merged `DESIGN.md` explicitly states: **where merged architecture prose (e.g. this file) disagrees with that Turn Model, the pseudocode overrides** player/mole rotation — implement **`src/sim/turn_state.lua`** and its **callers** to match the pseudocode, not a conflicting paragraph elsewhere.

**Product intent (summary only; pseudocode wins on edge cases):** *Symmetric same-slot progression* — each roster index advances **only when that human ends their own turn**; opponent’s `mole_slot` does not change on handoff. After a full P1→P2 cycle with symmetric casualties, both sides typically advance one **living** mole in step (deaths desync via `advance_mole_index` skipping dead slots).

**This architect doc defers to that block as the default**; §4.1 below is **module wiring**, not a second ruleset.

**As-built mapping:** `src/sim/turn_state.lua`

| Designer / merged-DESIGN concept | Code hook |
|----------------------------------|-----------|
| `turn_player` | `active_player` |
| `mole_index[p]` | `mole_slot[p]` (aligned with `mole.slot` in world) |
| Match start / first player | `M.new(settings)` — `first_player` including `"random"` |
| `on_end_turn` + advance + handoff | `M:end_turn(moles, settings)` → `advance_after_turn` (ring step **≥ 1** before picking living mole) → `sync_slots_to_living` |
| Turn timer | `M:update_timer(dt, moles, settings)` |

**Maintenance checklist:** On end turn, only the **ended** player’s roster advances; `play.lua` / `world.lua` must call `end_turn` with the correct active player context. Weapon numbers live in `config.defaults.lua`; match toggles in `match_settings.lua`.

---

## 5. Procedural map generation (R5) — **as implemented**

**Module:** `src/sim/terrain_gen.lua` — invoked when building a match world (from `play.lua` / `world.lua`); consumes logical size from `config.defaults.lua` (`grid_w`, `grid_h`, `cell`) and optional `MatchSettings.map_seed`.

**Design intent (typical pipeline):** height / noise → solid mask → spawn bands for two teams → bounded retries for valid placements. **Determinism:** user seed from `match_setup` or pseudo-random per match when `map_seed` is nil.

**Consumers:** `src/sim/terrain.lua` (solid grid + carve/damage queries), `src/render/terrain_draw.lua`, `src/sim/world.lua`.

**Performance:** Regenerate **once per match**, not per frame.

---

## 6. Score tracking (R6) — lifecycle hooks

| Event | Action |
|-------|--------|
| `love.load` | Module `session_scores` ready (counters in module table) |
| Match victory | `app.quit_match_to_results(winner_id, settings)` → `session_scores.record_match_outcome` → `match_end` scene |
| `menu` / `src/ui/hud.lua` | `get_snapshot()` for session wins / draws / games played |

No requirement to persist across app restarts for v1.

---

## 7. LÖVE lifecycle delegation

### 7.1 `conf.lua`

- Title, window size, `t.modules` defaults; optional `t.console = true` for dev.

### 7.2 `main.lua`

**Existing pattern:** `love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. ...)` then `local app = require("app")` — **not** `require("src.app")`. Forward `love.keypressed` / `keyreleased` / mouse / joystick / `resize` as already stubbed in repo `main.lua`.

### 7.3 `app.lua`

- `load`: `love.graphics` defaults, `audio.sfx.init()`, fonts, **sprite assets** under `assets/sprites/`, empty stack → `push("menu")`.
- `update` / `draw`: delegate to top scene; `draw` applies `util.viewport.fit_transform()` for letterboxed logical resolution.
- `textinput` / gamepad / resize forwarded from `main.lua` to `app` for setup menus and viewport.

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
app → scenes → (world, match_settings, session_scores, render modules for draw)
app → input.input_manager → keyboard_mouse | gamepad
world → terrain, terrain_gen, mole, physics, damage, turn_state, weapons/*
scenes/play → world, camera, hud, mole_draw, terrain_draw
terrain_gen → (avoid requiring love.* where possible; ok if current code uses LÖVE APIs)
```

**Rule:** `world` must not `require` draw modules; **drawing** pulls state from `world` in scenes. `audio.sfx` is triggered from gameplay / UI, not from pure sim leaves where avoidable.

---

## 10. Implementation notes for the Coding Agent

1. **Fixed order in `world.update`:** wind → mole movement (active only) → weapon charge → projectiles → collisions → damage application → death removal → win check.
2. **Active mole:** Use `turn_state:active_mole(moles)` (as in `turn_state.lua`); gate intents in `input_manager` / `world` so only the turn owner’s active mole moves.
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
