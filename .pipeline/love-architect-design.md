# LÖVE Architect Design — `love-architect`

**Scope:** Lua 5.1 / LÖVE **11.4** — module boundaries, `require` direction, `love` lifecycle delegation, scene stack, systems layout, procedural mapgen contract, 2P input routing.  
**Authoritative merge:** Product goals, session semantics, and the canonical repo snapshot live in root [`DESIGN.md`](DESIGN.md) (*Moles — Unified DESIGN.md*). **This file does not repeat the product brief** — see [`DESIGN.md`](DESIGN.md) § **Original task (source of truth)** once (merge note on duplicate blocks below).

---

## 0. Doc hygiene note (orchestrator — not `DESIGN.md` edits by this agent)

[`DESIGN.md`](DESIGN.md) currently contains **two identical** “Original task (source of truth)” blocks near the top. **Recommendation:** keep **one** authoritative block (the first). Remove the second, *or* replace it with: *“Non-authoritative duplicate — see § Original task above.”* so future edits cannot drift. This pipeline artifact only records that guidance; per pipeline rules the love-architect agent does **not** patch [`DESIGN.md`](DESIGN.md).

---

## 1. Repository snapshot (cross-reference + architect deltas)

**Full file list and “what exists”:** use [`DESIGN.md`](DESIGN.md) § **Repository snapshot (authoritative for “what exists”)**.

**Architect-verified delta (workspace):** [`main.lua`](main.lua) requires `app`, but **`src/app.lua` is still absent** — `love .` remains blocked until the Coding Agent adds it (or changes entry wiring).

**Expected additions (aligned with unified DESIGN):** `src/app.lua`, `src/scene_manager.lua`, `src/scenes/*`, `src/input/*`, `src/systems/*`, **`src/ui/*`** (HUD/widgets per love-ux), `assets/*` as needed.

---

## 2. High-level architecture

### Runtime model

- **Single-threaded** LÖVE loop: `love.load` → `love.update(dt)` / `love.draw()`.
- **Scene stack:** `scene_manager` forwards callbacks to the top scene; pause as overlay or pushed scene per UX.
- **`play` scene** owns **match runtime**: frozen `MatchConfig` snapshot, reference to [`session`](src/game/session.lua), roster, [`turn_state`](src/game/turn_state.lua), `map` + `terrain`, entity lists, projectile/grenade lists, explosion queue.
- **Round UX without popping `play`:** per unified DESIGN / love-ux, **round interstitial** uses `turn_state.phase` values such as `interstitial` / `round_end` **while the stack top remains `play`** — do not add a separate scene unless the stack contract changes.
- **Pure Lua leaves:** [`core/rng`](src/core/rng.lua), [`core/vec2`](src/core/vec2.lua), [`world/mapgen/*`](src/world/mapgen/init.lua), [`world/collision.lua`](src/world/collision.lua) core math — no `require("app")` or `scenes/*`.

### Dependency direction (require graph)

```
main.lua → bootstrap → app.lua → scene_manager → scenes/*

scenes/play.lua
  → game.session, game.match_config, game.roster, game.turn_state
  → world.map, world.terrain, world.collision
  → world.mapgen.init (round/match boundary)
  → entities/*, systems/*
  → ui/* (draw/layout helpers; scenes own when to call)

world/mapgen/*  → terrain, map, core/rng only
entities/*      → no scenes; callbacks or world table passed in
```

**Rule:** No circular requires — `mapgen` and `entities` never `require` `app` or `scenes/*`.

---

## 3. File / directory structure

### 3.1 Current + target layout

```
project root/
├── conf.lua
├── main.lua
├── DESIGN.md
├── assets/
└── src/
    ├── bootstrap.lua          # EXISTS
    ├── app.lua                # ADD — required by main.lua
    ├── scene_manager.lua      # ADD
    ├── input/
    │   ├── bindings.lua
    │   ├── devices.lua
    │   └── input_state.lua    # optional; recommended
    ├── ui/                    # ADD — scaling, HUD panels, widgets (love-ux)
    ├── core/                  # EXISTS
    ├── data/                  # EXISTS
    ├── game/                  # EXISTS
    ├── world/                 # EXISTS (+ mapgen/)
    ├── entities/              # EXISTS
    ├── systems/               # ADD
    └── scenes/                # ADD
        ├── boot.lua
        ├── main_menu.lua
        ├── match_setup.lua
        ├── play.lua
        ├── pause.lua
        └── game_over.lua
```

**Scene filenames:** Must match UX canon: `play` (not `playing`), `game_over` (not `match_summary`).

---

## 4. Key data models, interfaces, schemas

### 4.1 `MatchConfig` (single schema)

**Code source of truth:** [`src/game/match_config.lua`](src/game/match_config.lua) (`defaults`, `validate`).  
**Narrative / lobby table:** [`DESIGN.md`](DESIGN.md) MatchConfig / match-setup sections.

| Field | Notes |
|--------|--------|
| `mole_max_hp`, `rounds_to_win`, `wind_strength`, `grenade_fuse_seconds`, `turn_time_limit`, `friendly_fire`, `procedural_seed`, `map_width`, `map_height`, `teams_per_player`, `input_scheme` | As implemented + validated in `match_config.lua`; match setup must edit **all** fields the unified DESIGN lists for the lobby. |

**Weapons tuning:** [`src/data/weapons.lua`](src/data/weapons.lua). Grenade fuse at fire time: prefer `match_config.grenade_fuse_seconds` unless a single override rule is documented in code.

### 4.2 `Session` semantics

**Do not redefine here.** Follow [`DESIGN.md`](DESIGN.md) § **Session stats definition**: `scores[1|2]` = **match wins** since launch; `matches_completed` = finished **matches**; not round tallies without rename + UI update.

### 4.3 Roster / turn rotation

**Behaviour:** [`DESIGN.md`](DESIGN.md) requirements (starting player alternation, `roster.rotate_order` / `mole_order`, `next_living_mole_index`, `turn_state.start_match_turn(starting_player)`). **Architecture split:** [`turn_state.lua`](src/game/turn_state.lua) holds phase + indices; `systems/turn_resolver.lua` advances when the world is quiescent (projectiles settled, explosion queue drained).

### 4.4 Mapgen contract

- **API:** [`world.mapgen.init.generate(match_config, seed)`](src/world/mapgen/init.lua) → `{ map, terrain, rng }` (as today).
- **When to call:** Pick **one** policy — new terrain **per round** or **per match** — document in [`scenes/play.lua`](src/scenes/play.lua) (comment + one constant) so designers and UX stay consistent.

### 4.5 Terrain / collision

Use existing [`terrain.lua`](src/world/terrain.lua), [`map.lua`](src/world/map.lua), [`collision.lua`](src/world/collision.lua); `systems/explosions.lua` performs carve + damage in one path, honoring `friendly_fire`.

---

## 5. Component breakdown and responsibilities

| Module | Status | Responsibility |
|--------|--------|------------------|
| [`conf.lua`](conf.lua) | EXISTS | Window, joystick on |
| [`main.lua`](main.lua) | EXISTS | `package.path`, bootstrap, `app.register()` |
| `src/app.lua` | **ADD** | Register **all** `love.*` callbacks; forward to `scene_manager`; optional central `InputRouter` hook |
| `scene_manager.lua` | ADD | Stack, `push`/`pop`/`replace`, forward input, resize, visibility |
| `scenes/boot.lua` | ADD | Assets, joystick detect |
| `scenes/main_menu.lua` | ADD | New match, session scores via [`session.get_scores`](src/game/session.lua), quit |
| `scenes/match_setup.lua` | ADD | Edit `MatchConfig`, dual Ready → Start; `match_config.validate` before entering `play` |
| `scenes/play.lua` | ADD | Match runtime owner; update pipeline; mapgen trigger; **interstitial phases** on same scene |
| `scenes/pause.lua` | ADD | Overlay or stack; `dt = 0` for simulation when paused |
| `scenes/game_over.lua` | ADD | Match end, rematch / menu |
| `input/*` | ADD | Semantic intents per **player slot**; **only active player** gets combat input during aim when `shared_kb`; mouse routing per devices module |
| `ui/*` | ADD | Logical 1280×720 layout helpers, HUD, menus — consume `turn_state`, `match_config`, entities |
| `systems/world_update.lua` | ADD | Moles, projectiles, grenades, gravity, terrain collision |
| `systems/weapons.lua` | ADD | Fire from active mole |
| `systems/explosions.lua` | ADD | Single explosion primitive; `friendly_fire` |
| `systems/turn_resolver.lua` | ADD | Turn / round / match transitions when simulation idle |

---

## 6. `love` lifecycle delegation

### `love.load`

Bootstrap ([`src/bootstrap.lua`](src/bootstrap.lua)); load persistent resources; `scene_manager.push(boot)` or `main_menu` per UX.

### `love.update(dt)`

1. `input_state` frame edges.  
2. `scene_manager.update(dt)`.  
3. In **`play`**, order matches unified DESIGN **Game Loop**: input → turn FSM → movement → projectiles → explosions / terrain → damage / knockback / fall → eliminations → round/match checks → camera.

### `love.draw`

Parallax/bg → terrain → moles → projectiles/FX → **UI/HUD** (`src/ui/*` + scene).

### Input

`love.keypressed` / `gamepadpressed` / mouse → `input_state` → `scene_manager` → scene; **play** applies only the **active** player’s profile for combat.

---

## 7. Procedural map generation (architectural)

Pipeline today: heightfield surface → cave carve → spawns → `rebuildImageData` ([`mapgen/init.lua`](src/world/mapgen/init.lua)). Extensions stay under `src/world/mapgen/` with [`core/rng`](src/core/rng.lua) only.

---

## 8. Dependencies and technology choices

| Choice | Rationale |
|--------|-----------|
| Stock LÖVE 11.4 | [`conf.lua`](conf.lua) |
| No third-party Lua libs (baseline) | Matches current repo |
| Collision behind [`world/collision.lua`](src/world/collision.lua) | Localized algorithm swaps |
| Session RAM-only | Optional later: `love.filesystem` |

---

## 9. `luaModules` — public API sketch (Coding Agent)

| Path | Public surface (indicative) |
|------|------------------------------|
| `src/app.lua` | `register()` |
| `src/scene_manager.lua` | `push`, `pop`, `replace`, `update`, `draw`, `emit(event, ...)` |
| `src/input/bindings.lua` | `default_bindings()` |
| `src/input/devices.lua` | `set_from_match_config(c)`, joystick index assignment |
| `src/input/input_state.lua` | `pressed`, `released`, `down` per action |
| `src/ui/*` | layout scale, HUD builders — surface defined with love-ux |
| [`game/match_config.lua`](src/game/match_config.lua) | `defaults()`, `validate(c)` |
| [`game/session.lua`](src/game/session.lua) | `new()`, `bump_match_win`, `get_scores` |
| [`world/mapgen/init.lua`](src/world/mapgen/init.lua) | `generate(match_config, seed)` |
| `systems/explosions.lua` | `apply` / queue drain |
| `systems/weapons.lua` | `try_fire(ctx)` |
| `systems/turn_resolver.lua` | `step(ctx)` when idle |

---

## 10. JSON handoff fragment (orchestrator / tooling)

```json
{
  "architecture": "app → scene_manager → scenes; play owns match runtime + turn_state phases for round interstitial; mapgen.init.generate at round/match boundary; systems layer; ui/* for HUD; DESIGN.md authoritative for product + session stats.",
  "luaModules": "See §9.",
  "fileStructure": "§3.1",
  "loveLifecycle": "§6",
  "dependencies": ["LÖVE 11.4"],
  "considerations": [
    "Implement src/app.lua before shipping.",
    "DESIGN.md: dedupe duplicate Original task blocks (§0).",
    "Session: match wins only in scores — see DESIGN Session stats definition.",
    "Round interstitial: turn_state.phase inside play, not a new scene unless stack spec changes.",
    "Document per-round vs per-match map regen in play scene."
  ]
}
```

---

## 11. Implementation notes for Coding Agent

1. **Boot order:** `app.register()` registers callbacks once; scenes receive a shared `Session` (or global app context table) — avoid scattering `Session.new()` per scene without a plan.  
2. **Match setup:** Dual Ready + Start matches unified DESIGN; validate config before `play`.  
3. **`friendly_fire`:** Enforced in `systems/explosions.lua` (and direct-hit path if separate).  
4. **Testing:** Prefer headless-safe tests for `mapgen`, `vec2`, collision numeric helpers.  
5. **Conflicts:** If [`DESIGN.md`](DESIGN.md) and this file disagree, **prefer the more specific path in [`DESIGN.md`](DESIGN.md)** for behaviour; this file wins only on **where** to place wiring (files, require graph, lifecycle order).

---

*Design-only artifact: `.pipeline/love-architect-design.md`. No implementation files created.*
