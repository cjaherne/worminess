## Original task (source of truth)

Create a beautifully styled 'moles' clone of the game 'worms' that implements the core game mechanics, including rocket launchers and grenades. The game should support 2 player local mode with procedurally generated maps, keep track of scores of games played since launching, allow teams of 5 moles per player, rotate players and moles each round, and enable players to set match variables like mole health. Additionally, support 2 players on a single keyboard/mouse or with separate controllers.

---

# Moles — Unified DESIGN.md (merged)

**Merged from:** `.pipeline/game-designer-design.md`, `.pipeline/love-architect-design.md`, `.pipeline/love-ux-design.md`  
**Conflict rule:** Prefer the **more specific** artifact (tables, schemas, file paths, numeric policies). **Behaviour** defaults to this document; **where code lives** follows the love-architect graph and the **implemented** tree below. **`.pipeline/love-ux-design.md`** remains canonical for full pixel wireframes where this file abbreviates.

**Doc hygiene:** The **Original task** appears **only in the section above** — do not duplicate it elsewhere in this file.

---

## Document roles

| Agent | Scope in this merge |
|--------|---------------------|
| `game-designer` | Mechanics, rotation, session semantics, controls, combat, **direct hits**, map **cadence**, `map_seed`, checklist tied to `src/` |
| `love-architect` | Scene stack, lifecycle, `require` graph, **implemented** snapshot, systems boundaries |
| `love-ux` | Resolution/scaling, HUD coordinates, menus, dual-ready, accessibility, structured JSON handoff |

**LÖVE target:** **11.4** (`conf.lua`: `t.version = "11.4"`).

---

## Anchor index (implementers)

| Topic | Section in **this** `DESIGN.md` |
|--------|----------------------------------|
| MatchConfig fields + clamps | **MatchConfig — single consolidated schema** |
| Session stats semantics | **Session stats definition** |
| Mapgen **when** + **seed/rematch** | **Map regeneration cadence** + **`src/game/map_seed.lua`** |
| Round UX (interstitial vs overlays) | **Round flow (canonical)** |
| `match_setup` layout + dual Ready | **UX — §5.3 `match_setup`** |
| `play_hud` clusters | **UX — §5.4 `play` HUD** |
| Scene / HUD obligations | **requirementsChecklist — UX** |
| User flows JSON | **UX — §10 Structured handoff JSON** |

---

## Repository snapshot (implemented)

**Tech stack:** LÖVE **11.4**, Lua 5.1 (embedded).

**Entry:** `main.lua` extends `package.path`, `require("bootstrap")`, `require("app")` → **`app.register()`** ([`src/app.lua`](src/app.lua)).

**Layout (authoritative file tree):**

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

**Optional:** `assets/` for future art/fonts; baseline **procedural SFX** in `src/audio/sfx.lua` (no bundled `.ogg` required for MVP).

---

## Session stats definition (Overseer / coding contract)

**For the phrase “scores of games played since launching”, `src/game/session.lua` means:**

- `scores[1]` and `scores[2]`: each player’s **match wins** since app launch (not round wins, not a per-player “games played” scoreboard).
- `matches_completed`: count of **fully finished matches** in this session (one increment per match end).
- Neither field may be repurposed for **round** tallies without renaming and updating UI copy.

**UI:** Label **wins** vs **matches played** distinctly (`main_menu`, `pause`, `game_over` **match_end**).

---

## Map regeneration cadence (authoritative)

**Default:** **Per round** — new procedural terrain **every round**, not once per match.

**When `world.mapgen.init.generate(match_config, seed)` runs:** **Once per round** at **round setup**: after the prior round outcome is known and flow advances, **before** moles are placed. **Round 1** uses the same path when entering **play**. **Do not** reuse the previous round’s terrain into the next round.

**Seed:** Always via **`src/game/map_seed.lua`** — **`map_seed.derive(procedural_seed, round_index)`** immediately before `generate` (do not duplicate seed logic elsewhere).

- **`procedural_seed == nil`:** new random integer per call (`love.math.random`) → unrelated terrain each round (and rematch rounds).
- **`procedural_seed` set:** deterministic mix of **(procedural_seed, round_index)** → rounds differ but replay reproduces the same **sequence**; **Rematch** with `last_match_config` preserves round-*k* parity for terrain.

---

## Round flow (canonical — reconciles UX + implementation)

| Phase | Where it lives | Purpose |
|--------|----------------|---------|
| **Round start interstitial** | **`play`** remains on stack; `turn_state.phase == interstitial`; **`play_hud`** full-width band + **`ctx.toast_text`** | “Round N — Player P · Mole M”, new map expectation |
| **Round victory** | Push **`game_over`** variant **`round_end`** **on top of** `play` (stack) | Summary + **Continue** → pop → `play:continue_after_round()` → **new** `map_seed.derive` + `generate` + mole spawn |
| **Match victory** | **`game_over`** **`match_end`** | **`session:bump_match_win`**; Rematch / New setup / Main menu |

Early UX drafts that describe *only* in-play toasts for round end are **superseded** by the **`game_over` round_end** overlay pattern above (matches **UX §10 `userFlows`** and typical stack design).

---

## requirementsChecklist — product / mechanics (game-designer + original task)

One tick per distinct ask from the **original task** (and aligned mechanics).

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena).
- [ ] Presentation is **beautifully styled** (theme/HUD/audio-VFX; mechanics expose state for HUD/SFX).
- [ ] **Core Worms-like mechanics:** turn order, aim + power, projectile flight, gravity, terrain collision, explosions carve terrain, knockback / fall damage (or equivalent), elimination at HP ≤ 0, round + match flow.
- [ ] **Rocket launcher** — fast shot, impact explosion, terrain + radial mole damage (`data/weapons.lua` → `rocket`; systems apply).
- [ ] **Grenades** — arc, configurable **fuse** (`match_config.grenade_fuse_seconds`), timed detonation, shared blast model with rocket where appropriate.
- [ ] **2-player local** only; `match_config.input_scheme` **`shared_kb`** vs **`dual_gamepad`**.
- [ ] **Procedurally generated maps** (`world/mapgen/`); **per-round regen** via **`map_seed.derive`** + **`world.mapgen.init.generate`** at round setup.
- [ ] **Scores since launch:** **`scores` = match wins per player**, **`matches_completed` = finished matches** (Session stats definition).
- [ ] **5 moles per player** (`MOLES_PER_TEAM` in `constants.lua`).
- [ ] **Rotate players each round** — alternate starting player (`starting_player` vs round index; `turn_state.start_match_turn`).
- [ ] **Rotate moles each round** — `roster.rotate_order` / `mole_order` at round boundaries; living-only selection on turn advances.
- [ ] **Match variables** including **mole health** (`mole_max_hp`) plus full `match_config` (wind, fuse, rounds to win, timer, friendly fire, seed, map size, input scheme).
- [ ] **Input:** two players on **one keyboard + mouse** and/or **separate controllers**; hot-plug; combat intents only for **active** player during aim (`input/*`, **`play`**).

### Direct hits (projectile vs mole)

**Rockets and grenades detonate on overlap with living moles**, not only on terrain impact (implement in `systems/world_update.lua`); **`friendly_fire`** and attacker team gate damage (`entities/mole.lua`, `systems/explosions.lua`). See **README.md** / **CODING_NOTES.md** for any implementation nuance.

---

## requirementsChecklist — architecture / delivery (love-architect)

- [ ] **Single-threaded** LÖVE loop; **`app.register()`** owns **`love.load` / `update` / `draw`** and forwards input, resize, joystick hot-plug.
- [ ] **`dt`** clamped with **`data.constants.MAX_DT`** in **`love.update`**.
- [ ] **Scene stack** — `scene_manager`: **update top only**, **draw full stack** bottom → top (pause over `play`).
- [ ] **`play`** owns match runtime (config snapshot, roster, turn, terrain, projectiles, grenades, VFX hooks).
- [ ] **`map_seed.derive` + `mapgen.generate` each round** per Map regeneration cadence.
- [ ] **`src/input/*`:** bindings, devices, stick smoothing; semantic routing for **active** player.
- [ ] **`systems/*`:** `world_update`, `weapons`, `explosions` (single path; **`friendly_fire`**), `turn_resolver`, `vfx`.
- [ ] **No circular requires:** `mapgen` / `entities` do not `require` `app` or `scenes/*`.
- [ ] **`conf.lua`:** joystick on, 1280×720 default, resizable.

---

## requirementsChecklist — UX (love-ux)

- [ ] **Logical canvas 1280×720**; **uniform scale** + letterbox (`ui/theme` `begin_draw` / `end_draw`); **safe margin 24** (`layout.safe_x0` / `safe_x1`).
- [ ] **Scenes:** `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over` — use **`play`**, not `playing`.
- [ ] **Round start** interstitial band in **`play_hud`** when `phase == interstitial` + **`toast_text`**.
- [ ] **Main menu:** Local match, Options (stub OK), Quit; **`session.get_scores()`** + **`matches_completed`** with correct labels.
- [ ] **Match setup:** all **MatchConfig** fields; **`match_config.validate`** before play; **dual Ready** before Start.
- [ ] **Menus** completable with **keyboard+mouse OR gamepad**; P1 drives focus when two pads except Ready chips.
- [ ] **Theme:** void `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`.
- [ ] **HUD (`play_hud`):** round wins **this match**, turn banner, session match wins, wind, move budget, power, weapon strip, grenade fuse when in flight, hints for **`input_scheme`**.
- [ ] **Pause:** dimmer + session block + Resume / Restart / Setup / Menu; Esc; Start → pause.
- [ ] **`game_over`:** **`round_end`** vs **`match_end`**; Rematch uses **`last_match_config`**; **`bump_match_win`** only on match end.
- [ ] **Accessibility:** menu ≥22px, HUD ≥28px; P1/P2 + mole index text; prompt pulse ≤1 Hz.
- [ ] **Dual-controller setup** copy when `dual_gamepad`: Controller 1 ✓ / Controller 2 press A to assign.

---

## MatchConfig — single consolidated schema (source of truth)

**In code:** `src/game/match_config.lua` (`defaults`, `validate`, `copy`).

| Field | Type | Purpose | Validation notes |
|--------|------|---------|------------------|
| `mole_max_hp` | number | Per-mole HP | 1–500 (integer) |
| `rounds_to_win` | number | First-to-N **round** wins | 1–9 |
| `wind_strength` | number | Scalar wind ±x | ±400; 0 = off |
| `grenade_fuse_seconds` | number | Grenade fuse at fire | 0.5–8 |
| `turn_time_limit` | number \| **nil** | Seconds/turn; nil = off | 5–120 if set |
| `friendly_fire` | boolean | Same-team damage | Enforced in explosions / damage |
| `procedural_seed` | int \| **nil** | nil = random per **map_seed** rules | — |
| `map_width`, `map_height` | int | Terrain size (px) | From `constants` defaults |
| `teams_per_player` | int | Moles per human (**5**) | `MOLES_PER_TEAM` |
| `input_scheme` | string | `shared_kb` \| `dual_gamepad` | Match setup + `devices` |

### Match setup — UX widget column (love-ux §3.2)

| Field | Widget | UX copy |
|--------|--------|---------|
| `mole_max_hp` | Stepper | “Mole health” (large numeral target 72px where themed) |
| `rounds_to_win` | Stepper | “Rounds to win match” |
| `wind_strength` | Slider | “Wind” (←/→ when ≠ 0) |
| `grenade_fuse_seconds` | Stepper | “Grenade fuse (s)” |
| `turn_time_limit` | Toggle + stepper | “Turn timer” |
| `friendly_fire` | Toggle | “Friendly fire” |
| `procedural_seed` | Toggle + value | “Custom seed” / Random |
| `input_scheme` | Radio | Shared KB+mouse / Dual gamepad |
| `teams_per_player` | Read-only | From `MOLES_PER_TEAM` (5) |

**Dual confirm:** `ready_p1` / `ready_p2` UI-local → enable **Start** + valid config + dual pads if required.

---

## Mechanics (summary)

**2D turn-based artillery** on **destructible procedural terrain** (**regenerated every round**). Two locals, **5 moles** each. **Alternating team turns**; one active mole fires. **Rocket** / **grenade**; **wind** × weapon `wind_scale`. **Explosions** carve terrain and apply damage + knockback; **fall damage** via `constants`. **Round** ends when a team has **zero** living moles; **match** ends at **`rounds_to_win`** round wins → **`session:bump_match_win`**.

### Player & mole rotation

- **Starting player:** e.g. `starting_player = ((round_number - 1) % 2) + 1` at each round setup (document parity in code comments).
- **Mole order:** `roster.rotate_order(team.mole_order)` each round; `next_living_mole_index` skips dead moles; **dead active mole during aim** — reassign or end round if team wiped (no deadlock).

### Codebase alignment (game-designer)

| Area | Module(s) |
|------|-----------|
| Entry / lifecycle | `main.lua`, `bootstrap.lua`, `app.lua` |
| Scenes | `scene_manager.lua`, `scenes/*.lua` |
| Match variables | `game/match_config.lua` |
| Per-round seed | **`game/map_seed.lua`** |
| Session | `game/session.lua` |
| Turn FSM | `game/turn_state.lua` |
| Teams / rotation | `game/roster.lua` |
| Moles | `entities/mole.lua` |
| Weapons + blasts | `systems/weapons.lua`, `systems/explosions.lua` |
| Sim integration | `systems/world_update.lua`, `systems/turn_resolver.lua` |
| World / gen | `world/*`, `world/mapgen/*` |
| Input | `input/*` |
| UI | `ui/theme.lua`, `layout.lua`, `ui/hud/play_hud.lua` |
| Feedback | `systems/vfx.lua`, `audio/sfx.lua` |

### Weapons

| Id | Intent |
|----|--------|
| `rocket` | High velocity; detonation → shared explosion (terrain + splash + impulse). |
| `grenade` | Arc, bounce/fuse; timed blast uses **same explosion path** as rocket. |

**Turn rule:** Fire → projectiles until quiescent → advance or end round/match (`turn_resolver` + `play`).

### Controls & devices

- **Bindings:** `src/input/bindings.lua`.
- **Devices / hot-plug:** `src/input/devices.lua`; **stick smoothing:** `src/input/stick.lua`.
- **README / CODING_NOTES:** **`shared_kb`** — mouse wheel may adjust power during aim; optional pads may follow **active** player; **`dual_gamepad`** — triggers/LB/RB charge, **Start** → pause from any pad.

**Routing:** `love.*` input → `scene_manager` → top **scene** → intents (only **active** player for combat in **`play`**).

---

## Game loop (combined)

1. **Boot** → **main_menu**.  
2. **Match setup** — edit `match_config`, dual Ready, validate → **play**.  
3. **Each round:** `seed = map_seed.derive(...)` → `mapgen.generate` → spawn moles, rotations, `start_match_turn`, interstitial toast.  
4. **Per frame:** input → FSM → moles → projectiles/grenades → explosions → fall → win checks → VFX/audio.  
5. **Round win** → **`game_over` round_end** → Continue → next round.  
6. **Match win** → **`game_over` match_end** → bump session → Rematch / setup / menu.  
7. **Pause** — stack push; sim frozen (top scene has no sim `update` or play not top).

**Sim order:** input → turn FSM → moles → projectiles → terrain/explosions → damage → eliminations → camera/VFX.

---

## `love` lifecycle (as implemented)

| Callback | Delegation |
|----------|------------|
| `love.load` | `theme.load_fonts()`, `audio.sfx.init()`, `Session.new()`, `scene_manager.new`, `replace(boot)` |
| `love.update` | `dt = min(dt, MAX_DT)`, `sm:update(dt)` (**top only**) |
| `love.draw` | `theme.clear_void()`, `begin_draw`, `sm:draw()` (**full stack**), `end_draw` |
| `love.resize` | all scenes |
| Input + **`wheelmoved`** | top scene |
| `joystickadded` / `removed` | `devices.refresh_joysticks()` |

---

## File / structure reference

See **Repository snapshot** for the full tree. **Optional future refactor:** `ui/widgets/*`, `ui/compose/*` if scenes grow — not required for baseline.

---

## Components (responsibilities)

| Concept | Primary home |
|---------|----------------|
| MatchConfig | `game/match_config` |
| Per-round seed | **`game/map_seed`** |
| Session | `game/session` |
| Turn / weapons | `game/turn_state` |
| Rosters | `game/roster` |
| Blast + carve | `systems/explosions` |
| Fire | `systems/weapons` |
| Frame integration | `systems/world_update`, `turn_resolver` |
| Proc terrain | `world/mapgen/init` |

---

## Procedural map generation

Pipeline: heightfield → caves → `spawns.place_team_spawns` → `rebuildImageData`. Extensions stay under `world/mapgen/` with `core/rng`; **no** scene coupling from mapgen.

---

## UX — scene graph

| Scene | Role |
|--------|------|
| `boot` | Title → **main_menu** |
| `main_menu` | Session stats, Local match → **match_setup** |
| `match_setup` | MatchConfig + dual Ready → **play** |
| `play` | World + HUD + round-start interstitial |
| `pause` | Overlay |
| `game_over` | **`round_end`** / **`match_end`** |

---

## UX — §5 Wireframes (summary + `play_hud` as implemented)

### 5.1–5.3 Boot / main_menu / match_setup

Pixel regions per **`.pipeline/love-ux-design.md` §5.1–5.3** (center block 440–840×220–500; main menu left panel 80,140,520,440; match_setup panel 120–1160 × 100–620; dual Ready strip y≈520–600; footer y≈640).

### 5.4 `play` HUD — clusters as implemented (`play_hud.lua`)

| Cluster | Placement |
|---------|-----------|
| Round wins (this match) | P1: x=24,y=20; P2: right x=lw−464,y=20 |
| Turn banner | Paper rect center, y=16, 560×56 |
| Session match wins | Center y=78 |
| Wind | Center y=100 |
| Turn timer | Right y=120 if set |
| Interstitial toast | Full width y=200, h=120 when `phase==interstitial` |
| Move / power bars | y≈620–642 |
| Weapon strip | y=656, slots 64×64, gap 16 |
| Grenade fuse | Right of weapon row when live grenade |
| Hints | Center y=568 |

### 5.5–5.7 Pause / interstitial / game_over

Per love-ux §5.5–5.7; **`game_over` match_end** should show **`session.scores`** and **`matches_completed`** (“matches played”) for parity with menu/pause.

---

## UX — §6 Interactions (summary)

- **Menus:** Up/Down, Enter, click, gamepad A/B; Tab focus in **match_setup**.  
- **Play `shared_kb`:** route KB/mouse to **active_player**; wheel power per README.  
- **`dual_gamepad`:** pad maps to player on turn; **Start** → pause.  
- **Match setup assign:** Controller 2 press A (see **match_setup** scene).

---

## UX — §7 Accessibility

Menu body ≥22px; HUD ≥28px; P1/P2 + mole labels; flashing ≤3 Hz; primary pulse ≤1 Hz.

---

## UX — §8–§9 Dependencies & implementation notes

Built-in fonts OK; optional TTF later. No mandatory external UI framework. **HUD `ctx`** assembled only in **`scenes/play`**. **`bump_match_win`** only on **match** end. Keep **`bindings.lua`**, **`play_hud`** hints, and **README** in sync.

---

## UX — §10 Structured handoff JSON

```json
{
  "userFlows": {
    "cold_start": [
      "Launch → love.load → app → SceneManager",
      "boot → main_menu",
      "main_menu → match_setup",
      "match_setup: match_config + input_scheme; dual Ready; validate → play",
      "play: play_hud; interstitial toast (phase interstitial + toast_text) on play stack",
      "round setup: map_seed.derive + mapgen.generate before placing moles",
      "round complete → game_over round_end (stack) → Continue → play next round",
      "match complete → game_over match_end → bump session → Rematch/New setup/Main menu",
      "Esc / Start → pause on stack → Resume / Restart / match_setup / main_menu"
    ],
    "session_stats": [
      "session.scores[1|2] and matches_completed on main_menu, pause, game_over match_end",
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
    "menu": { "nav": ["up/down", "dpad"], "confirm": ["enter", "click", "gamepad_a"], "back": ["escape", "gamepad_b"] },
    "gameplay_hot_seat": { "principle": "shared_kb: active_player only; wheel power per README" },
    "gameplay_dual_pad": { "principle": "joystick to player on turn; Start → pause" }
  },
  "accessibility": {
    "fontMinSizesPx": { "menuBody": 22, "hudScore": 28 },
    "motion": "Primary prompt pulse ≤ 1 Hz"
  }
}
```

---

## UX — §11 Visual style

Playful underground; rounded panels; soft shadows; optional paper texture; chunky moles; weapon icons ~64×64; heavy celebration particles on **match_end** only.

---

## Persistence

- **v1:** session **RAM** only.  
- **Rematch:** `session.last_match_config`.  
- **Optional later:** `love.filesystem`.

---

## Considerations

- **`MAX_DT`** cap.  
- **Joystick hot-plug.**  
- **Per-round mapgen** — `rebuildImageData` cost; hitch or loading beat acceptable.  
- **Turn timer** — auto-fire at expiry (document in UI / **CODING_NOTES**).  
- **Dead active mole** — must not deadlock FSM.

---

## Implementation order (maintenance)

1. Regression: per-round **`map_seed.derive` + `generate`**.  
2. Rotation + no stale terrain between rounds.  
3. Session UI strings: wins vs matches played.  
4. Input matrix **`shared_kb` / `dual_gamepad`**.  
5. Combat: **direct mole hits**, **friendly_fire**, wipe while aiming.  
6. Polish: wind, VFX/SFX, spawns.

---

## Pseudocode

**Round setup:**

```
seed = map_seed.derive(match_config.procedural_seed, round_index)
world_bundle = world.mapgen.init.generate(match_config, seed)
starting_player = ((round_index - 1) % 2) + 1
for each team: team.mole_order = roster.rotate_order(team.mole_order)
-- place moles at spawns, full HP
turn_state.start_match_turn(ts, teams, starting_player, slot1, slot2)
```

**Match end:**

```
session:bump_match_win(winner_player_index)
```

---

## Dependencies

- Stock **LÖVE 11.4**; no third-party Lua libs required for baseline.  
- **Procedural SFX** in `audio/sfx.lua`.

---

## `luaModules` — public surface (sketch)

| Module | Indicative API |
|--------|----------------|
| `app` | `register()` |
| `scene_manager` | `new(get_context)`, `push`, `pop`, `replace`, `update`, `draw`, input forwards |
| `game.match_config` | `defaults`, `validate`, `copy` |
| `game.session` | `new`, `bump_match_win`, `get_scores` |
| **`game.map_seed`** | **`derive(procedural_seed, round_index)`** |
| `world.mapgen.init` | `generate(match_config, seed)` |
| `input.devices` | `refresh_joysticks`, scheme routing |

---

## Handoff notes

- **game-designer:** Session stats, **Map regeneration cadence**, **`map_seed`**, **direct hits**, rotation — authoritative for mechanics.  
- **love-architect:** Stack semantics (**update top / draw all**), **`require`** graph, implemented tree.  
- **love-ux:** Full §5–§7 detail in **`.pipeline/love-ux-design.md`** when not fully inlined here.  
- **Coder:** On conflict, **this `DESIGN.md`** then **`src/game/*.lua`** for validation.

---

*End of unified DESIGN.md*
