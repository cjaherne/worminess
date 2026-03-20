# Moles — Unified DESIGN.md (merged)

**Merged from:** `.pipeline/game-designer-design.md`, `.pipeline/love-architect-design.md`, `.pipeline/love-ux-design.md`  
**Conflicts:** Prefer the **more specific** section (tables, schemas, file paths). Where the game designer maps behaviour to **existing `src/` modules**, that mapping is **authoritative** for implementation.

---

## Original task (source of truth)

Create a beautifully styled 'moles' clone of the game 'worms' that implements the core game mechanics, including rocket launchers and grenades. The game should support 2 player local mode with procedurally generated maps, keep track of scores of games played since launching, allow teams of 5 moles per player, rotate players and moles each round, and enable players to set match variables like mole health. Additionally, support 2 players on a single keyboard/mouse or with separate controllers.

---

## Document roles

| Agent | Scope in this merge |
|--------|---------------------|
| `game-designer` | Mechanics, rotation rules, session semantics, controls, combat, proc map intent, checklist tied to `src/` where applicable |
| `love-architect` | Scene stack, lifecycle, **single MatchConfig schema**, module layout, repository snapshot, systems boundaries |
| `love-ux` | Resolution/scaling, screens/HUD wireframes, menu focus, dual-ready flow, accessibility, structured JSON handoff |

**LÖVE target:** **11.4** (`conf.lua`: `t.version = "11.4"`).

---

## Repository snapshot (authoritative for “what exists”)

**Tech stack:** LÖVE 11.4, Lua 5.1 (embedded).

**Entry:** `main.lua` sets `package.path`, requires `src/bootstrap.lua`, then `require("app")` → **`app.register()`**.

**Present (typical):** `conf.lua`, `main.lua`, `src/bootstrap.lua`, `src/core/{rng,timer,vec2}.lua`, `src/data/{constants,weapons}.lua`, `src/game/{match_config,roster,session,turn_state}.lua`, `src/world/{terrain,map,collision}.lua`, `src/world/mapgen/{init,heightfield,caves,spawns}.lua`, `src/entities/{mole,projectile,grenade}.lua`.

**Expected additions (architecture):** `src/app.lua`, `src/scene_manager.lua`, `src/scenes/*`, `src/input/*`, `src/systems/*`, `src/ui/*`, `assets/*` as needed.

---

## Session stats definition (Overseer / coding contract)

**For the original brief phrase “scores of games played since launching”, `src/game/session.lua` shall mean:**

- `scores[1]` and `scores[2]`: each player’s **match wins** accumulated since app launch (not round wins).
- `matches_completed`: **how many matches have been fully finished** in this session (one increment per match end).
- Neither `scores` nor `matches_completed` may be repurposed to mean round tallies without renaming and updating UI copy.

**UI copy:** Label **wins** vs **matches played** clearly (see love-ux §3.1).

---

## requirementsChecklist — product / mechanics (game-designer + original task)

Cross-reference: every distinct ask from the product brief must be tickable by implementation.

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena feel—not a different genre).
- [ ] Presentation is **beautifully styled** (cohesive mole/underground theme; UX handles pixels—mechanics expose state for HUD: `turn_state`, `match_config`, mole entities).
- [ ] **Core Worms-like mechanics** are implemented: turn order, aiming + power, projectile flight, gravity, terrain collision, explosions carving terrain, knockback / fall damage (or equivalent lethality), elimination when HP ≤ 0, round/match flow.
- [ ] **Rocket launcher** weapon: fast projectile, impact explosion, terrain damage, damage to moles in radius (`src/data/weapons.lua` → `rocket`).
- [ ] **Grenade** weapon: arcing throwable, timed / configurable fuse, explosion with terrain and area damage (`grenade` + `match_config.grenade_fuse_seconds`).
- [ ] **2-player local** mode only (no online in this scope); `match_config.input_scheme` distinguishes shared keyboard vs dual gamepad.
- [ ] **Procedurally generated maps** (`src/world/mapgen/`); **consistent** choice: new terrain **per round** or **per match**—document in one place (regen on round start is valid).
- [ ] **Session score tracking** since launch: **`scores` = match wins per player**, **`matches_completed` = finished matches** (see Session stats definition above).
- [ ] **Teams:** **5 moles per player** (`src/data/constants.lua` `MOLES_PER_TEAM`); friendly-fire rule driven by `match_config.friendly_fire` (default on).
- [ ] **Rotate players each round**: alternate **starting player** / priority between rounds (e.g. `starting_player = ((round_number - 1) % 2) + 1`); `turn_state.start_match_turn` accepts `starting_player`.
- [ ] **Rotate moles each round**: vary mole turn order via `roster.rotate_order` / `mole_order` at round boundaries; `next_living_mole_index` skips dead moles.
- [ ] **Match variables**: at minimum mole health (`mole_max_hp`); also wind, fuse, rounds to win, turn timer, friendly fire, input scheme, optional seed — see **MatchConfig** below.
- [ ] **Input:** **one keyboard + mouse** or **two controllers**; hot-plug friendly; only **active** player’s mole accepts combat input during `aim` (central `InputRouter` in `app` / `src/input/*`).

---

## requirementsChecklist — architecture / delivery (love-architect)

- [ ] **Single-threaded** LÖVE loop: `love.load`, `love.update(dt)`, `love.draw()`.
- [ ] **Scene stack** via `scene_manager`; scenes under `src/scenes/`; **`play`** owns match runtime (config, session ref, roster, turn, world, projectiles, explosions queue).
- [ ] **`main.lua` → bootstrap → `app.register()`** wires all `love.*` callbacks to the scene manager.
- [ ] **`src/input/*`:** bindings, devices, optional `input_state`; semantic intents per **player slot**; mouse only for **active** player when `shared_kb`.
- [ ] **`src/systems/*`:** `world_update`, `weapons`, `explosions` (single explosion path; honor `friendly_fire`), `turn_resolver` (or equivalent) when world quiescent.
- [ ] **No circular requires:** `mapgen` and `entities` do not `require` `app` or `scenes/*`.
- [ ] **`mapgen.init.generate(match_config, seed)`** returns `{ map, terrain, rng }` (or as implemented); invoked on round/match start per design choice.
- [ ] **`conf.lua`:** joystick module on, window title, 1280×720 default, resizable.

---

## requirementsChecklist — UX (love-ux)

- [ ] **Logical canvas 1280×720** with **uniform scale** + letterbox/pillarbox; **safe margin 24px** (scaled with `uiScale`).
- [ ] **Canonical scenes:** `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over` — filenames match architect (`play` not `playing`; `game_over` replaces label `match_summary`).
- [ ] **Round interstitial / toast** while stack top stays **`play`** (`turn_state.phase` `interstitial` / `round_end`); do not orphan a separate scene unless architect stack updated.
- [ ] **Main menu:** Local match, Options (optional stub), Quit; show **`session.get_scores()`** and optionally **`matches_completed`**.
- [ ] **Match setup:** Edit **all** MatchConfig fields listed in §3.1 UX table; run **`match_config.validate`** before play; **dual Ready** (P1/P2) before **Start match** enabled.
- [ ] **Menus** completable with **keyboard+mouse OR gamepad**; focus navigation; P1 drives menu focus when two pads connected except **Ready** chips (dual confirm).
- [ ] **Theme colours:** void `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`.
- [ ] **HUD (`play`):** turn banner, weapon strip, wind, move budget, power/charge, optional session chip, hints that swap with **`active_player`**; grenade fuse when relevant (in-flight / armed).
- [ ] **Pause:** dimmer + session block + Resume / Restart match / Match setup / Main menu; Esc; Start on either pad (v1 focus rule per UX §5.5).
- [ ] **`game_over` variants:** `round_end` vs `match_end` (layout/copy); **Rematch** uses `last_match_config`; session bump only on **match** end path.
- [ ] **Accessibility:** menu body ≥22px, HUD scores ≥28px at 1×; P1/P2 + mole slot text — not colour alone; prompt pulse ≤1 Hz.
- [ ] **Dual-controller setup:** status “Controller 1 ✓”, “Controller 2 press A to assign” when `dual_gamepad` selected.

---

## MatchConfig — single consolidated schema (source of truth)

**In code:** `src/game/match_config.lua` (`defaults()` + `validate()`). Do not maintain divergent field lists elsewhere.

| Field | Type | Purpose | Validation notes |
|--------|------|---------|------------------|
| `mole_max_hp` | number | Starting / max HP per mole | Clamped 1–500 (integer) |
| `rounds_to_win` | number | First-to-N **round** wins for match | Clamped 1–9 |
| `wind_strength` | number | Scalar wind along ±x | Clamped ±400; `0` = off |
| `grenade_fuse_seconds` | number | Grenade fuse at fire time | Clamped 0.5–8 |
| `turn_time_limit` | number \| **nil** | Seconds per turn; **nil** = none | If set, 5–120 |
| `friendly_fire` | boolean | Damage to same-team moles | Enforced in explosions / direct hit |
| `procedural_seed` | int \| **nil** | **nil** → random seed at start | — |
| `map_width` | int | Terrain width (px) | Defaults from `constants` |
| `map_height` | int | Terrain height (px) | Defaults from `constants` |
| `teams_per_player` | int | Moles per human (**5**) | From `MOLES_PER_TEAM` |
| `input_scheme` | string | `"shared_kb"` \| `"dual_gamepad"` | Match setup + `input/devices.lua` |

**Weapon tuning** stays in `src/data/weapons.lua`. **Grenade fuse** at fire time uses `MatchConfig.grenade_fuse_seconds` unless code documents a single override rule.

---

## Mechanics (summary)

Turn-based **2D side-view artillery** on a **destructible procedural map**. Two players, **5 moles** each. **Alternating team turns**; one active mole fires per turn. **Rocket** (fast projectile) and **grenade** (arc, fuse, bounce params) share **one explosion primitive** (terrain carve + radial damage + knockback + fall damage). **Wind** scales per weapon. **Round** ends when a team has no living moles. **Match** ends at **`rounds_to_win`** round wins; then **`session:bump_match_win(winner)`** — **do not** increment session scores on individual round wins only.

### Player & mole rotation

- **Starting player:** `starting_player = ((round_index - 1) % 2) + 1` (document parity in code comments).
- **Mole rotation:** Before first turn of round, **`rotate_order(team.mole_order)`** per team; advance cursor mod 5; skip dead moles when resolving turns.

### Session scoring (recap)

On **match** end only: winner `scores[winner] += 1`, `matches_completed += 1`, `last_match_winner`, optional `last_match_config` snapshot for rematch.

### Controls (data-driven)

**P1 keyboard:** `A`/`D` move, `W`/`S` aim, hold e.g. `Shift` for power, `Space` fire, `1`/`2` weapons.  
**P2 keyboard (shared):** numpad / non-overlapping set per bindings table.  
**Mouse:** optional aim + fire for **active** player when scheme allows.  
**Gamepads:** indices per `dual_gamepad`; sticks, trigger, face buttons; **Start** → pause.

**Lua routing:** `love.keypressed` / `gamepad*` / `mouse*` → intents → consumed in `love.update` only if `turn_state.phase == aim` and event targets `turn_state.active_player`.

---

## File / directory structure (merged)

```
project root/
├── conf.lua
├── main.lua
├── DESIGN.md
├── README.md                    # optional
├── assets/
│   ├── fonts/                   # optional TTF; fallback OK for prototype
│   ├── images/
│   └── sounds/
└── src/
    ├── bootstrap.lua
    ├── app.lua                  # register love callbacks → scene_manager
    ├── scene_manager.lua
    ├── core/                    # rng, timer, vec2
    ├── data/                    # constants, weapons
    ├── game/                    # match_config, session, roster, turn_state
    ├── world/                   # map, terrain, collision, mapgen/*
    ├── entities/                # mole, projectile, grenade
    ├── input/                   # bindings, devices, input_state (optional)
    ├── systems/                 # world_update, weapons, explosions, turn_resolver
    ├── scenes/                  # boot, main_menu, match_setup, play, pause, game_over
    └── ui/                      # theme, layout, focus_stack, widgets, hud, compose (per UX)
```

Designer hint names: `systems/turn.lua` → prefer **`turn_resolver.lua`** or thin FSM in `turn_state` + resolver.

---

## `love` lifecycle & update order

1. **`love.load`:** graphics defaults (bootstrap); load fonts/assets; `scene_manager.push(boot)` or `main_menu`; hold `Session.new()` from app or first scene.  
2. **`love.update`:** clear input edges → `scene_manager.update(dt)` → in **play**: input → turn FSM → moles → projectiles/grenades → explosions / terrain → damage / fall → death → round/match check → camera.  
3. **`love.draw`:** background → terrain → entities → FX → HUD.  
4. **Input:** forward to scene_manager → **play** applies **active player** profile only.

---

## Procedural map generation

- **Entry:** `world.mapgen.init.generate(match_config, seed)`.  
- **Pipeline (current intent):** heightfield surface → cave carves → spawns for both teams → `terrain:rebuildImageData`.  
- **Determinism:** seeded `core/rng` for QA.  
- **Performance:** batch/throttle heavy terrain writes if spikes occur.

---

## UX — scene graph & wireframes (abridged; full detail in love-ux)

### Scene reconciliation

| `src/scenes/…` | Role |
|----------------|------|
| `boot` | Load assets; optional title splash; push `main_menu` |
| `main_menu` | Session wins, Local match → `match_setup`, Quit |
| `match_setup` | MatchConfig + `input_scheme` + **dual Ready** → validate → `play` |
| `play` | World + **HUD** + toasts for interstitial |
| `pause` | Overlay on `play` (or stack) |
| `game_over` | Variants **`round_end`** / **`match_end`** |

### `match_setup` (dual column)

- **Column A:** steppers/sliders for all MatchConfig fields (see UX §3.2 in source doc).  
- **Column B:** `shared_kb` vs `dual_gamepad`; controller assign status.  
- **Dual ready strip:** P1 Ready / P2 Ready; **Start** disabled until both ready and config valid.  
- **Footer:** Back, Start match.

### `play` HUD clusters (1280×720 logical)

Turn banner top center; scores top corners; session chip optional; weapon strip bottom; wind; move budget; power; grenade fuse when relevant; help hints bottom — swap with `active_player`.

### Structured `userFlows` (JSON)

```json
{
  "userFlows": {
    "cold_start": [
      "Launch → love.load → app → SceneManager",
      "boot → main_menu (title optional in boot)",
      "main_menu → match_setup",
      "match_setup: edit match_config + input_scheme; dual Ready; validate → play",
      "play: interstitial/round_end as toast in play",
      "round complete → game_over round_end → play",
      "match complete → game_over match_end → bump session → Rematch / New setup / Main menu",
      "Esc / Start → pause → Resume / Restart / match_setup / main_menu"
    ],
    "session_stats": [
      "Show session.scores[1], session.scores[2] on main_menu, pause, game_over match_end",
      "bump_match_win only on match victory path"
    ]
  },
  "wireframes": {
    "baseResolution": [1280, 720],
    "safeMarginPx": 24,
    "architectScenes": ["boot", "main_menu", "match_setup", "play", "pause", "game_over"],
    "gameOverVariants": ["round_end", "match_end"]
  },
  "accessibility": {
    "fontMinSizesPx": { "menuBody": 22, "hudScore": 28 },
    "motion": "Primary prompt pulse ≤ 1 Hz"
  }
}
```

### Visual style (art direction)

Playful underground: rounded panels, soft shadows, optional paper texture 8–12% opacity; chunky mole silhouettes; weapon icons readable at 64×64; celebrate on `match_end` only.

---

## Components (responsibilities)

| Concept | Typical location |
|---------|------------------|
| Match variables | `match_config` |
| Session wins / matches played | `session` |
| Turn phases / active mole | `turn_state` |
| Team + mole order rotation | `roster` |
| Weapon stats | `data/weapons` |
| Mole HP / damage | `entities/mole` |
| Projectile / grenade | `entities/projectile`, `entities/grenade` |
| Terrain + proc map | `world/*`, `world/mapgen/*` |
| Explosions | `systems/explosions` |
| Input routing | `input/*` + `app` / `play` |

---

## Persistence

- **v1:** session **RAM only** (“since launching”).  
- **Optional later:** `love.filesystem` for config or totals.

---

## Implementation order (combined)

1. **Unblock boot:** `src/app.lua` + `scene_manager` + minimal `main_menu`.  
2. **Input:** dual keyboard, dual gamepad, optional mouse; `input_scheme`.  
3. **Match setup** + validate MatchConfig + dual Ready.  
4. **Play scene:** mapgen, roster spawn, turn FSM, projectiles, **shared explosions**, round/match resolution.  
5. **HUD / UI:** `src/ui/theme`, layout, HUD, toasts, pause, `game_over` variants.  
6. **Polish:** wind, audio/VFX hooks, spawn fairness, playtesting clamps.

---

## Pseudocode (behavioural)

**Match end (session):**

```
on_match_winner_decided(winner_player_index):
  session:bump_match_win(winner_player_index)
```

**Round start (rotation):**

```
starting_player = ((round_index - 1) % 2) + 1
for each team: team.mole_order = roster.rotate_order(team.mole_order)
turn_state.start_match_turn(ts, teams, starting_player, slot1, slot2)
```

**Explosion (shared):**

```
terrain.carveCircle(center, terrain_radius)
for each mole:
  if distance(mole, center) < blast_radius:
    apply damage falloff + knockback; respect friendly_fire and attacker_team
```

---

## Dependencies

- **Stock LÖVE 11.4**; no extra Lua libs required for MVP.  
- Collision stays behind `world/collision.lua` where possible.

---

## Handoff notes

- **game-designer:** Session stats definition + rotation + combat rules are binding for `session.lua` and play flow.  
- **love-architect:** Single MatchConfig schema; scene stack; systems layer; fix stale “no src/” notes in any brief by pointing to this snapshot.  
- **love-ux:** Wireframes, dual Ready, theme, accessibility, `game_over` variants; compose under `src/ui/`, thin scenes.  
- **Coder:** When UX and mechanics disagree on labels, **mechanics + session definition** win; adjust UI strings.

---

*End of unified DESIGN.md*
