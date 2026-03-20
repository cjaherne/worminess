# Moles — Unified DESIGN.md (merged)

**Merged from:** `.pipeline/game-designer-design.md`, `.pipeline/love-architect-design.md`, `.pipeline/love-ux-design.md`  
**Conflict rule:** Prefer the **more specific** artifact (tables, schemas, file paths, numeric policies). **Behaviour** defaults to this document; **where to place code** follows the love-architect graph. **Full UX depth** for wireframes / interactions / §10 JSON is copied from love-ux below; **`.pipeline/love-ux-design.md`** remains a peer canonical copy for pixel tables if this file is edited shorter later.

**Doc hygiene:** The **Original task** appears **only once** below (authoritative). Do not duplicate it elsewhere in this file.

---

## Original task (source of truth)

Create a beautifully styled 'moles' clone of the game 'worms' that implements the core game mechanics, including rocket launchers and grenades. The game should support 2 player local mode with procedurally generated maps, keep track of scores of games played since launching, allow teams of 5 moles per player, rotate players and moles each round, and enable players to set match variables like mole health. Additionally, support 2 players on a single keyboard/mouse or with separate controllers.

---

## Document roles

| Agent | Scope in this merge |
|--------|---------------------|
| `game-designer` | Mechanics, rotation, session semantics, controls, combat, proc map **cadence**, checklist tied to `src/` |
| `love-architect` | Scene stack, lifecycle, `require` graph, systems boundaries, repository snapshot |
| `love-ux` | Resolution/scaling, screens/HUD, focus, dual-ready, accessibility, structured JSON handoff |

**LÖVE target:** **11.4** (`conf.lua`: `t.version = "11.4"`).

---

## Anchor index (implementers)

| Topic | Section in **this** `DESIGN.md` |
|--------|----------------------------------|
| MatchConfig fields + clamps | **MatchConfig — single consolidated schema** |
| Session stats semantics | **Session stats definition** |
| Mapgen **when** + **seed/rematch** | **Map regeneration cadence** |
| `match_setup` layout + dual Ready | **UX — §5.3 `match_setup`** |
| Scene list + HUD obligations | **requirementsChecklist — UX** + **UX §5–§7** |
| User flows JSON | **UX — §10 Structured handoff JSON** |

---

## Repository snapshot (authoritative for “what exists”)

**Tech stack:** LÖVE 11.4, Lua 5.1 (embedded).

**Entry:** `main.lua` sets `package.path`, requires `src/bootstrap.lua`, then `require("app")` → **`app.register()`**.

**Typically present:** `conf.lua`, `main.lua`, `src/bootstrap.lua`, `src/core/{rng,timer,vec2}.lua`, `src/data/{constants,weapons}.lua`, `src/game/{match_config,roster,session,turn_state}.lua`, `src/world/{terrain,map,collision}.lua`, `src/world/mapgen/{init,heightfield,caves,spawns}.lua`, `src/entities/{mole,projectile,grenade}.lua`.

**Expected additions:** `src/app.lua`, `src/scene_manager.lua`, `src/scenes/*`, `src/input/*`, `src/systems/*`, `src/ui/*`, `assets/*` as needed. **`src/app.lua`** is required for `love .` to boot if `main.lua` requires `app`.

---

## Session stats definition (Overseer / coding contract)

**For the original brief phrase “scores of games played since launching”, `src/game/session.lua` shall mean:**

- `scores[1]` and `scores[2]`: each player’s **match wins** accumulated since app launch (not round wins, not “games played” per player as a scoreboard).
- `matches_completed`: **how many matches have been fully finished** in this session (one increment per match end).
- Neither `scores` nor `matches_completed` may be repurposed to mean **round** tallies without renaming and updating the UI copy.

**UI copy:** Label **wins** vs **matches played** distinctly (main menu, pause, `game_over`).

---

## Map regeneration cadence (default — game-designer authoritative)

**Default:** Regenerate procedural terrain **once per round** (not once per match).

**When `world.mapgen.init.generate(match_config, seed)` runs:** Exactly **once at the start of every round**, in the **round-setup** step—**after** the prior round’s winner is known (and any `interstitial` / `round_end` UI has advanced) and **before** teams are re-instantiated or moles are placed on spawns for that round. **Round 1** of a match uses this same path (first call when the match begins play). **Do not** reuse the previous round’s terrain bitmap across rounds within one match.

**Seed argument:**

- If `match_config.procedural_seed` is **`nil`**: pass a **fresh random integer** for **each** `generate` call (every round gets unrelated terrain; **Rematch** still randomizes each round).
- If `match_config.procedural_seed` is **set** (player/debug “lock”): pass a **deterministic function** of `(procedural_seed, round_index)` only (e.g. hash/mix in Lua) so **each round’s map differs** but the same config reproduces the same sequence; **Rematch** restoring `last_match_config` **preserves** that option—**round *k* after Rematch matches round *k* of the previous run** with the same locked seed.

**Module reference:** `generate` in `src/world/mapgen/init.lua` (required as `world.mapgen.init` from `src/`).

---

## requirementsChecklist — product / mechanics (game-designer + original task)

Cross-reference: every distinct ask from the product brief must be tickable by implementation.

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena feel—not a different genre).
- [ ] Presentation is **beautifully styled** (cohesive mole/underground theme; UX handles pixels—mechanics expose state for HUD: `turn_state`, `match_config`, mole entities).
- [ ] **Core Worms-like mechanics** are implemented: turn order, aiming + power, projectile flight, gravity, terrain collision, explosions carving terrain, knockback / fall damage (or equivalent lethality), elimination when HP ≤ 0, round/match flow.
- [ ] **Rocket launcher** weapon: fast projectile, impact explosion, terrain damage, damage to moles in radius (`src/data/weapons.lua` → `rocket`).
- [ ] **Grenade** weapon: arcing throwable, timed / configurable fuse, explosion with terrain and area damage (`grenade` + `match_config.grenade_fuse_seconds`).
- [ ] **2-player local** mode only (no online in this scope); `match_config.input_scheme` distinguishes shared keyboard vs dual gamepad.
- [ ] **Procedurally generated maps** (`src/world/mapgen/`); **default cadence: new terrain every round** via `world.mapgen.init.generate` at **round setup** (see **Map regeneration cadence**).
- [ ] **Session score tracking** since launch: **`scores` = match wins per player**, **`matches_completed` = finished matches** (see Session stats definition).
- [ ] **Teams:** **5 moles per player** (`src/data/constants.lua` `MOLES_PER_TEAM`); friendly-fire rule driven by `match_config.friendly_fire` (default on).
- [ ] **Rotate players each round**: alternate **starting player** / priority between rounds (`starting_player = ((round_number - 1) % 2) + 1` or equivalent); `turn_state.start_match_turn` accepts `starting_player`.
- [ ] **Rotate moles each round**: vary mole turn order via `roster.rotate_order` / `mole_order` at round boundaries; `next_living_mole_index` skips dead moles.
- [ ] **Match variables**: at minimum mole health (`mole_max_hp`); also wind, fuse, rounds to win, turn timer, friendly fire, input scheme, optional seed — see **MatchConfig** below.
- [ ] **Input:** **one keyboard + mouse** or **two controllers**; hot-plug friendly; only **active** player’s mole accepts combat input during `aim` (`InputRouter` in `app` / `src/input/*`).

---

## requirementsChecklist — architecture / delivery (love-architect)

- [ ] **Single-threaded** LÖVE loop: `love.load`, `love.update(dt)`, `love.draw()`.
- [ ] **Scene stack** via `scene_manager`; scenes under `src/scenes/`; **`play`** owns match runtime (config snapshot, session ref, roster, turn, map, terrain, entities, projectiles, explosion queue).
- [ ] **Round interstitial** uses `turn_state.phase` (`interstitial`, `round_end`) **while stack top remains `play`** — no extra scene unless stack contract changes.
- [ ] **`main.lua` → bootstrap → `app.register()`** wires all `love.*` callbacks to the scene manager.
- [ ] **`src/input/*`:** bindings, devices, optional `input_state`; semantic intents per **player slot**; mouse only for **active** player when `shared_kb`.
- [ ] **`src/systems/*`:** `world_update`, `weapons`, `explosions` (single explosion path; honor `friendly_fire`), `turn_resolver` when simulation idle.
- [ ] **No circular requires:** `mapgen` and `entities` do not `require` `app` or `scenes/*`.
- [ ] **`mapgen.init.generate(match_config, seed)`** at **every round start** per **Map regeneration cadence** (supersedes generic “pick one” wording in older architect text).
- [ ] **`conf.lua`:** joystick module on, window title, 1280×720 default, resizable, min window per `conf.lua`.

---

## requirementsChecklist — UX (love-ux)

- [ ] **Logical canvas 1280×720** with **uniform scale** + letterbox/pillarbox; **safe margin 24px** (scaled with `uiScale`).
- [ ] **Canonical scenes:** `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over` — use `play` not `playing`; `game_over` not `match_summary`.
- [ ] **Round interstitial / toast** while stack top stays **`play`** (`turn_state.phase` `interstitial` / `round_end`).
- [ ] **Main menu:** Local match, Options (optional stub), Quit; show **`session.get_scores()`** and optionally **`matches_completed`** with correct labels.
- [ ] **Match setup:** Edit **all** MatchConfig fields in the **MatchConfig** table below; run **`match_config.validate`** before play; **dual Ready** (P1/P2) before **Start match** enabled.
- [ ] **Menus** completable with **keyboard+mouse OR gamepad**; focus navigation; P1 drives menu focus when two pads connected except **Ready** chips.
- [ ] **Theme colours:** void `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`.
- [ ] **HUD (`play`):** turn banner, weapon strip, wind, move budget, power/charge, optional session chip, hints that swap with **`active_player`**; grenade fuse when entity armed/in flight.
- [ ] **Pause:** dimmer + session block + Resume / Restart match / Match setup / Main menu; Esc; Start on either pad (v1 focus rule per UX §5.5).
- [ ] **`game_over` variants:** `round_end` vs `match_end`; **Rematch** uses `last_match_config`; **`session:bump_match_win`** only on **match** end path.
- [ ] **Accessibility:** menu body ≥22px, HUD scores ≥28px at 1×; P1/P2 + mole slot text — not colour alone; primary prompt pulse ≤1 Hz.
- [ ] **Dual-controller setup:** “Controller 1 ✓”, “Controller 2 press **A** to assign” when `dual_gamepad` selected.

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
| `procedural_seed` | int \| **nil** | **nil** → random per **Map regeneration cadence** | — |
| `map_width` | int | Terrain width (px) | Defaults from `constants` |
| `map_height` | int | Terrain height (px) | Defaults from `constants` |
| `teams_per_player` | int | Moles per human (**5**) | From `MOLES_PER_TEAM` |
| `input_scheme` | string | `"shared_kb"` \| `"dual_gamepad"` | Match setup + `input/devices.lua` |

**Weapon tuning** stays in `src/data/weapons.lua`. **Grenade fuse** at fire time uses `MatchConfig.grenade_fuse_seconds` unless a single override rule is documented in code.

### Match setup — UX widget column (love-ux §3.2)

| Field | Widget | UX copy |
|--------|--------|---------|
| `mole_max_hp` | Stepper/slider | “Mole health” (large numeral) |
| `rounds_to_win` | Stepper | “Rounds to win match” |
| `wind_strength` | Slider + off at 0 | “Wind” (← / → when ≠ 0) |
| `grenade_fuse_seconds` | Stepper | “Grenade fuse (s)” |
| `turn_time_limit` | Toggle + stepper or nil | “Turn timer” optional |
| `friendly_fire` | Toggle | “Friendly fire” |
| `procedural_seed` | Optional / “Random” | “Custom seed” (nil = random) |
| `input_scheme` | Radio | `shared_kb` vs `dual_gamepad` |
| `teams_per_player` | Read-only label | From `MOLES_PER_TEAM` (5) |

**Dual confirm:** `ready_p1` / `ready_p2` UI-local until both true → enable **Start match** (plus valid config).

---

## Mechanics (summary)

Turn-based **2D side-view artillery** on a **destructible procedural map** (**regenerated every round start**). Two players, **5 moles** each. **Alternating team turns**; one active mole fires per turn. **Rocket** and **grenade** share **one explosion primitive**. **Wind** scales per weapon. **Round** ends when a team has no living moles. **Match** ends at **`rounds_to_win`** round wins; then **`session:bump_match_win(winner)`** — do not increment session `scores` on round wins only.

### Player & mole rotation

- **Starting player:** `starting_player = ((round_number - 1) % 2) + 1` (document parity in code).
- **Mole rotation:** Before first turn of round, **`rotate_order(team.mole_order)`** per team; skip dead moles in `next_living_mole_index`.

### Codebase alignment (game-designer)

| Area | Module(s) |
|------|-----------|
| Match variables | `src/game/match_config.lua` |
| Session | `src/game/session.lua` |
| Turn FSM | `src/game/turn_state.lua` — phases `aim`, `firing`, `flying`, `round_end`, `interstitial`; weapons `rocket` / `grenade` |
| Teams / rotation | `src/game/roster.lua` — `MOLES_PER_TEAM`, `rotate_order`, `mole_order` |
| Moles | `src/entities/mole.lua` |
| Weapons data | `src/data/weapons.lua` |
| Projectiles | `src/entities/projectile.lua`, `grenade.lua` |
| World | `src/world/terrain.lua`, `map.lua`, `collision.lua` |
| Proc map | `src/world/mapgen/*` |
| Core | `src/core/rng.lua`, `timer.lua`, `vec2.lua` |

### Weapons (core set)

| Id | Intent |
|----|--------|
| `rocket` | High `speed`, `wind_scale`; on impact → blast (`blast_radius`, `terrain_radius`, `damage_max`, `knockback`). |
| `grenade` | Lower speed, bounce (`restitution`, `roll_friction`); fuse from `match_config.grenade_fuse_seconds`; same blast rules as rocket. |

**Shared rule:** After projectiles settle, advance to enemy turn (`flying` → resolve → `advance_turn`) unless a future weapon breaks this.

### Controls (data-driven)

**P1 keyboard:** `A`/`D` move, `W`/`S` aim, hold e.g. `Shift` for power, `Space` fire, `1`/`2` weapons.  
**P2 keyboard (shared):** numpad / non-overlapping set per `bindings.lua`.  
**Mouse:** aim + fire for **active** player when `input_scheme` allows.  
**Gamepads:** indices per `dual_gamepad`; **Start** → pause.

**Routing:** `love.keypressed` / `gamepad*` / `mouse*` → intents → `love.update` only if `turn_state.phase == aim` and event targets `turn_state.active_player`.

---

## Game loop (combined)

1. **Boot** — `love.load`: paths, joystick scan.  
2. **Menu** — `session:get_scores()`, `matches_completed`, start match.  
3. **Match setup** — edit `match_config`, `input_scheme`, dual Ready, `validate()`.  
4. **Each round:** **`world.mapgen.init.generate(match_config, seed)`** (per **Map regeneration cadence**) → spawn teams / place moles → player + mole rotation → `turn_state.start_match_turn(...)`.  
5. **Per frame** — input → FSM → mole physics → projectiles/grenades → explosions → fall damage → round/match checks → camera.  
6. **Pause / game_over** — overlays; `dt = 0` for simulation when paused.

**Update order:** input → FSM → moles → projectiles → terrain mutations → damage → win checks → camera.  
**Draw order:** background → terrain → entities → VFX → HUD.

---

## File / directory structure (merged)

```
project root/
├── conf.lua
├── main.lua
├── DESIGN.md
├── assets/
│   ├── fonts/
│   ├── images/
│   └── sounds/
└── src/
    ├── bootstrap.lua
    ├── app.lua
    ├── scene_manager.lua
    ├── input/
    │   ├── bindings.lua
    │   ├── devices.lua
    │   └── input_state.lua    # optional; recommended
    ├── ui/
    │   ├── theme.lua
    │   ├── layout.lua
    │   ├── focus_stack.lua
    │   ├── widgets/ …
    │   ├── compose/ …
    │   └── hud/ …
    ├── core/
    ├── data/
    ├── game/
    ├── world/ (+ mapgen/)
    ├── entities/
    ├── systems/
    └── scenes/
        ├── boot.lua
        ├── main_menu.lua
        ├── match_setup.lua
        ├── play.lua
        ├── pause.lua
        └── game_over.lua
```

**Scene filenames:** `play` (not `playing`), `game_over` (not `match_summary`).

---

## `love` lifecycle delegation (love-architect)

### `love.load`

Bootstrap; load fonts/assets; `scene_manager.push(boot)` or `main_menu`; shared **`Session`** typically owned by `app` (avoid duplicate `Session.new()` without a plan).

### `love.update(dt)`

1. `input_state` frame edges.  
2. `scene_manager.update(dt)`.  
3. In **play**: input → turn FSM → movement → projectiles → explosions / terrain → damage / knockback / fall → eliminations → round/match → camera.

### `love.draw`

Background → terrain → moles → projectiles/FX → UI/HUD (`src/ui/*` + scene).

### Input

Forward to `scene_manager` → **play** applies **active** player profile for combat.

---

## Components (responsibilities)

| Module | Responsibility |
|--------|----------------|
| `conf.lua` | Window, joystick on |
| `main.lua` | `package.path`, bootstrap, `app.register()` |
| `src/app.lua` | Register **all** `love.*` callbacks; scene_manager; optional InputRouter |
| `scene_manager.lua` | Stack, push/pop/replace, forward input, resize |
| `scenes/*` | Lifecycle per screen |
| `input/*` | Semantic actions per player slot |
| `ui/*` | Layout scale, HUD, menus |
| `systems/world_update.lua` | Moles, projectiles, grenades, gravity, terrain collision |
| `systems/weapons.lua` | Fire from active mole |
| `systems/explosions.lua` | Single primitive; `friendly_fire` |
| `systems/turn_resolver.lua` | Turn / round / match when idle |
| `game/match_config.lua` | `defaults`, `validate` |
| `game/session.lua` | `scores`, `matches_completed`, `bump_match_win` |
| `world/mapgen/init.lua` | `generate(match_config, seed)` |

---

## Procedural map generation

Pipeline: heightfield → caves → spawns → `rebuildImageData`. Extensions under `src/world/mapgen/` with `core/rng` only; no scene coupling.

---

## UX — scene graph (love-ux §1.2)

| Scene | Role |
|--------|------|
| `boot` | Assets + optional title splash → `main_menu` |
| `main_menu` | Local match → `match_setup`; session scores; Quit |
| `match_setup` | MatchConfig + `input_scheme` + dual Ready → validate → `play` |
| `play` | World + HUD + toasts for interstitial phases |
| `pause` | Overlay; session; Resume / Restart / Setup / Menu |
| `game_over` | Variants `round_end` / `match_end`; Rematch / New setup / Menu |

**In-play overlays (not separate scenes):** `round_interstitial` via toast + `turn_state.phase`; optional `team_roster` inside `match_setup` or omit v1.

---

## UX — wireframes (love-ux §5, 1280×720 logical)

### 5.1 Title splash (`boot` or first paint `main_menu`)

- Background: full-bleed gradient/vignette.  
- Center `x: 440–840`, `y: 220–500`: title, subtitle “Local 2 players · Moles with heavy weapons”, prompt “Press **Enter** / **A** to start” (blink ≤1 Hz).  
- Footer `y: 660–708`, `x: 40–1240`: version left; credits right (~14px at 1×).

### 5.2 `main_menu`

- Left panel `x: 80`, `y: 140`, `w: 520`, `h: 440`: buttons **Local match**, **Options**, **Quit** (~56px spacing).  
- Right art `x: 640–1200`, `y: 80–640`.  
- Default focus: Local match.

### 5.3 `match_setup`

Panel `x: 120–1160`, `y: 100–620`.

- **Column A — Match variables:** `mole_max_hp` stepper (step 5–10, **72px** numeral); `rounds_to_win` 1–9; wind slider −400…400 (0 calm); fuse 0.5–8 s; turn timer off/nil or 5–120; `friendly_fire` toggle; helper line about 5 moles and rotation.  
- **Column B — Input:** `shared_kb` (“active player uses mouse aim”); `dual_gamepad` + assign status (§6.4).  
- **Dual ready strip** `y: 520–600`: **P1 Ready** / **P2 Ready** chips; **Start match** disabled until both ready and config valid.  
- **Footer** `y: 640`: Back `x: 160`; Start match `x: 920`.

### 5.4 `play` HUD

Single shared camera v1. Clusters: turn banner top center (`w: 560`, `h: 64`, `y: 16`); scores top corners (P2 right-align `x: 1256`); optional session chip `y: 72`; interstitial uses toast region; move budget bar; weapon strip `y: 656`, icons 64×64, gap 16; wind `y: 88`; power/charge when `aim`; grenade fuse when entity active; help hints `y: 600–680` swap with `active_player`. Mouse: cursor + aim line when `shared_kb` + active player; keep HUD `y ≥ 600` where possible.

### 5.5 `pause`

- Dimmer `rgba(0,0,0,0.55)`.  
- Panel `x: 340`, `y: 160`, `w: 600`, `h: 400`: “Paused”; session stats; **Resume**, **Restart match**, **Match setup**, **Main menu**.  
- Esc toggles; Start on either pad opens pause; **v1:** first Start wins focus until resume.

### 5.6 `round_interstitial` (toast)

- Full-width toast `y: 200`, `h: 120`.  
- Copy e.g. “Round 4 — **Player 1 · Mole 2**”.  
- Auto-dismiss ~1.5s or Confirm.

### 5.7 `game_over`

- **`round_end`:** smaller panel; round winner; **Continue** → `play` (new round per rules — **includes mapgen**).  
- **`match_end`:** hero outcome `y: 180–320`; session table; emphasize `last_match_winner`.  
- Buttons: **Rematch** (`last_match_config`), **New setup** → `match_setup`, **Main menu**.

---

## UX — interactions (love-ux §6)

### 6.1 Menu layer

| Action | KB/Mouse | Gamepad |
|--------|----------|---------|
| Focus up/down | Up/Down | D-Pad / stick (debounced) |
| Confirm | Enter / click | A |
| Back | Esc / Backspace | B |
| Tab focus | Tab | LB/RB optional |
| Stepper/slider | Left/Right | D-Pad L/R |

Focused control: `accent` outline.

### 6.2 Gameplay hot-seat

HUD hints track `active_player` and `input_scheme`; bindings from **Controls** + `bindings.lua`.

### 6.3 Dual controllers

Pad maps to player on their turn; when not their turn ignore except **Start** → pause.

### 6.4 Controller assign (`match_setup`)

“Controller 1: detected ✓”; “Controller 2: press **A** to assign”; timeout → fall back if required.

---

## UX — accessibility (love-ux §7)

- Menu body ≥22px; HUD scores ≥28px; warnings ≥26px bold.  
- Never colour alone — P1/P2 + mole index.  
- Flashing UI ≤3 Hz; subtle primary pulse ≤1 Hz.  
- v1: distinct hues + labels; optional stripe patterns later.

---

## UX — dependencies & visual style (love-ux §8, §11)

- Built-in fonts OK for prototype; optional licensed TTF for ship.  
- Nine-slice via quads/mesh; optional atlas.  
- No mandatory external UI framework.  
- **Tone:** playful underground, rounded panels, soft shadows, paper texture 8–12% opacity; chunky moles; weapons readable at 64×64; heavy particles only on `match_end`.

---

## UX — implementation notes (love-ux §9)

1. HUD reads `turn_state`, `match_config`, `session`, roster/mole — no duplicate turn logic in UI.  
2. Toast queue re-entrant safe.  
3. Uniform scale + letterbox (`theme.void`).  
4. Reassert focus on resize / hot-plug.  
5. **`bump_match_win` only on match finished** (not mid-match quit).  
6. Weapon strip always shows rocket + grenade slots.  
7. Scenes thin; compose in `src/ui/`.

---

## UX — §10 Structured handoff JSON

```json
{
  "userFlows": {
    "cold_start": [
      "Launch → love.load → app → SceneManager",
      "boot → main_menu (title optional)",
      "main_menu → match_setup",
      "match_setup: match_config + input_scheme; dual Ready; validate → play",
      "play: HUD + toast for interstitial/round_end without popping play",
      "round complete → game_over round_end → play (regenerate map per Map regeneration cadence)",
      "match complete → game_over match_end → bump session → Rematch/New setup/Main menu",
      "Esc / Start → pause → Resume / Restart / match_setup / main_menu"
    ],
    "session_stats": [
      "session.scores[1|2] on main_menu, pause, game_over match_end",
      "bump_match_win only on match victory path"
    ]
  },
  "wireframes": {
    "baseResolution": [1280, 720],
    "safeMarginPx": 24,
    "architectScenes": ["boot", "main_menu", "match_setup", "play", "pause", "game_over"],
    "uxOverlaysInsidePlay": ["toast", "phase_interstitial", "round_banner"],
    "gameOverVariants": ["round_end", "match_end"]
  },
  "interactions": {
    "menu": {
      "nav": ["up/down", "dpad", "stick_debounced"],
      "confirm": ["enter", "mouse_click", "gamepad_a"],
      "back": ["escape", "gamepad_b"],
      "match_setup_ready": ["per_player_confirm_for_ready_chips"]
    },
    "gameplay_hot_seat": {
      "principle": "shared_kb: KB/mouse to active_player only; HUD follows active_player"
    },
    "gameplay_dual_pad": {
      "principle": "dual_gamepad: joystick to player on turn; Start → pause"
    }
  },
  "accessibility": {
    "contrast": "Light ink on dark void; P1/P2 + mole slot text",
    "fontMinSizesPx": { "menuBody": 22, "hudScore": 28 },
    "motion": "Primary prompt pulse ≤ 1 Hz"
  },
  "recommendations": [
    "Skip heavy character creator v1; mole slot + team colour",
    "Optional parallax on main_menu art",
    "Playtest HUD bottom vs low-angle aim"
  ]
}
```

---

## Persistence

- **v1:** session RAM only.  
- **Optional later:** `love.filesystem` for config or totals.

---

## Considerations (game-designer + architect)

- Cap `dt` (`MAX_DT` in `constants.lua`).  
- Joystick hot-plug: refresh devices; UX reassignment.  
- Explosion terrain: batch/throttle if spikes.  
- Per-round mapgen: `rebuildImageData` may hitch — optional loading frame.  
- Turn timer: if set, auto-end policy (e.g. fire at min power) — document in UI.

---

## Implementation order (combined)

1. **`src/app.lua` + `scene_manager` + `main_menu`** — unblock boot.  
2. **Input** — dual KB, dual pad, optional mouse; `input_scheme`.  
3. **Match setup** — full MatchConfig UI, dual Ready, `validate`.  
4. **`play`** — **mapgen every round**, roster spawn, turn FSM, projectiles, shared explosions, round/match resolution.  
5. **UI/HUD** — theme, layout, HUD, toasts, pause, `game_over` variants.  
6. **Polish** — wind, audio/VFX, spawn fairness, playtest clamps.

---

## Pseudocode (behavioural)

**Match end:**

```
on_match_winner_decided(winner_player_index):
  session:bump_match_win(winner_player_index)
```

**Round start:**

```
seed = derive_seed(match_config.procedural_seed, round_index)  -- or random if nil
world_state = world.mapgen.init.generate(match_config, seed)
starting_player = ((round_index - 1) % 2) + 1
for each team: team.mole_order = roster.rotate_order(team.mole_order)
-- respawn moles at new spawns, full HP from mole_max_hp
turn_state.start_match_turn(ts, teams, starting_player, slot1, slot2)
```

**Explosion:**

```
terrain.carveCircle(center, terrain_radius)
for each mole in blast_radius:
  damage falloff + knockback; respect friendly_fire and attacker_team
```

---

## Dependencies

- Stock **LÖVE 11.4**; no third-party Lua libs required for baseline.  
- Collision behind `world/collision.lua`.

---

## `luaModules` — public API sketch

| Path | Surface (indicative) |
|------|----------------------|
| `src/app.lua` | `register()` |
| `src/scene_manager.lua` | `push`, `pop`, `replace`, `update`, `draw`, `emit` |
| `src/input/bindings.lua` | `default_bindings()` |
| `src/input/devices.lua` | `set_from_match_config`, joystick assignment |
| `src/input/input_state.lua` | pressed/released/down |
| `game/match_config.lua` | `defaults()`, `validate(c)` |
| `game/session.lua` | `new()`, `bump_match_win`, `get_scores` |
| `world/mapgen/init.lua` | `generate(match_config, seed)` |
| `systems/explosions.lua` | `apply` / queue |
| `systems/weapons.lua` | `try_fire(ctx)` |
| `systems/turn_resolver.lua` | `step(ctx)` when idle |

---

## Handoff notes

- **game-designer:** Session stats + **Map regeneration cadence** + rotation + combat are binding.  
- **love-architect:** Scene stack, systems split, `app.lua` required; **per-round mapgen** is fixed here (overrides older “pick one” notes in pipeline architect file).  
- **love-ux:** Wireframes §5–§7 + JSON §10 above; compose under `src/ui/`.  
- **Coder:** On conflict, **this `DESIGN.md`** wins for behaviour; **`src/game/*.lua`** for exact validation if drift.

---

*End of unified DESIGN.md*
