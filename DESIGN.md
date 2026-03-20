## Original task (source of truth)

Create a beautifully styled 'moles' clone of the game 'worms' that implements the core game mechanics, including rocket launchers and grenades. The game should support 2 player local mode with procedurally generated maps, keep track of scores of games played since launching, and allow teams of 5 moles per player, rotating players and moles each round. Include options for players to set match variables like mole health and support for 2 players on a single keyboard/mouse or with separate controllers.

---


## Requirements traceability

Numbered requirements extracted from the user task: **[REQUIREMENTS.md](./REQUIREMENTS.md)**. Implementation must satisfy each item or document deferral in **CODING_NOTES.md**.

<!-- requirements-traceability-linked -->

---


# DESIGN.md

## Game Designer — Moles (Worms-like) Design

**Audience:** merge into `DESIGN.md` + Coding Agent blueprint  
**Framework:** LÖVE **11.4**  
**Repo baseline:** `REQUIREMENTS.md` (R1–R11); no gameplay source yet — design is greenfield but must stay compatible with parallel LÖVE Architect / UX agents.

---

## Requirements Checklist

Traceability: one bullet per distinct requirement from the user task and BigBoss brief. Coder ticks when implemented.

- [ ] **R-presentation**: Game is a **beautifully styled** presentation of a Worms-like experience (visual identity, readable entities, cohesive art direction — execution by art/UX; mechanics support clarity).
- [ ] **R-clone-scope**: Delivers a **“moles” clone** of **Worms** in spirit: side-view, destructible terrain, indirect weapon fire, turns, elimination win.
- [ ] **R-core-mechanics**: **Core Worms-style mechanics** present: terrain, gravity, movement/jumps, aiming, firing, damage, knockback, elimination, turn flow.
- [ ] **R-rocket**: **Rocket launcher** is a selectable weapon with distinct behavior (fast projectile, impact explosion, terrain destruction).
- [ ] **R-grenade**: **Grenade** is a selectable weapon with distinct behavior (arc trajectory, timed fuse, bounce optional, explosion + terrain destruction).
- [ ] **R-2p-local**: **Two-player local** multiplayer (same machine, hotseat or split attention as per input mode).
- [ ] **R-proc-maps**: **Procedurally generated maps** for each match (or per session rule — default: new terrain each new game), reproducible via seed for debugging/fairness.
- [ ] **R-session-score**: **Scores for games played since app launch** tracked (session-only persistence per REQUIREMENTS; reset on quit).
- [ ] **R-team-size**: Each human controls a **team of 5 moles**.
- [ ] **R-rotate-turns**: **Players alternate turns** each “turn” (standard Worms cadence: one team acts, then the other).
- [ ] **R-rotate-moles**: **Moles rotate** as the active character: when a player’s turn comes around again, control advances to the **next living mole** in a fixed team order (dead moles skipped).
- [ ] **R-match-vars**: **Match options** exposed before play (at minimum **mole max health / starting health**; room for more toggles without contradicting scope).
- [ ] **R-input-shared-kbm**: **Two players on one keyboard + mouse**: viable control scheme with clear ownership of input per active turn.
- [ ] **R-input-dual-pad**: **Two players with separate controllers** (gamepads): each player mapped to their own device where possible.
- [ ] **R-bigboss-teams**: Design supports **team dynamics**: two sides, friendly-fire policy, win when opposing team has no living moles, clarity of “which side am I on.”
- [ ] **R-bigboss-rotation**: Explicit **player + mole rotation** model documented and implemented (see **Turn model** below).

---

## Target LÖVE Version

`11.4` — match wiki/API stability used across the pipeline.

---

## Mechanics

### High-level Pitch

**Moles** is a **2D side-view**, **turn-based** artillery/tactics game. Two human players each command **5 moles** on **destructible procedural terrain**. On a turn, the active player moves and fires **one weapon** (from a small loadout including **rocket launcher** and **grenade**). The match ends when one side has **no living moles**. **Session score** records how many **match wins** each player (or each team slot) has earned **since the executable started**.

### Camera / World

- **Side view** (Worms-like): gravity pulls downward; terrain is a bitmap or polygon mask treated as solid for collisions.
- **Scale**: moles readable at target resolution (~32–48 px tall baseline suggestion for art; coder scales consistently).

### Turn Model (Players + Moles Rotation)

1. **Turn owner**: Exactly one **human player** is active at a time (`PlayerId` 1 or 2).
2. **Active mole**: The active player controls **one mole** for the entire turn — the **current index** in that player’s roster (1..5).
3. **End of turn**: Triggered explicitly by player (**“End turn”** action) or optionally by **timeout** if match options include turn timer (recommended as optional match var, default off for first implementation).
4. **Advance after a side’s turn**: When Player A ends their turn, pass to Player B with **B’s current mole index unchanged** from B’s last turn (B continues controlling the same “slot” until that mole dies — see next bullet).
5. **Mole rotation (within team)**: When **Player A’s turn begins again** after B has played, advance A’s roster pointer to the **next living mole** in fixed order. If mole `k` is dead, skip to next living. If **no living moles**, that player has already lost (should not occur if win condition checked).
6. **First turn of match**: Menu or random determines **who goes first**; each team’s mole pointer starts at **mole 1** (first in roster).

*Pseudocode (design intent only):*

```lua
on_match_start():
  turn_player = option_or_random(P1, P2)
  for each player p: mole_index[p] = first_living_mole(p)  # typically 1

on_end_turn(ended_player):
  advance_mole_index(ended_player)   # roster pointer moves for NEXT time this player acts
  turn_player = other(ended_player)

advance_mole_index(p):
  repeat
    mole_index[p] = next_index_in_ring(mole_index[p], 1..5)
  until mole[p][mole_index[p]] is alive OR no living moles remain for p
```

**Clarification for Coding Agent:** When the active player **ends their turn**, advance **that player’s** mole roster pointer (skip dead moles). The opponent’s pointer is unchanged. On the **first** turn of the match, do not advance before play — starting indices are each team’s first living mole.

### Movement & Aiming

- **Movement**: Walk left/right on terrain surface; **jump** with limited air control (Worms-like). No infinite jetpack unless added later.
- **Player rotation (facing)**: Each mole has **facing** `left` | `right`. Walking updates facing. **Aiming** is a separate **aim angle** (e.g. radians or degrees) relative to facing or world-up — recommend **world-space aim cone** (e.g. −150° to −30° from horizontal) so rocket/grenade arcs read clearly. **Rotate aim** with dedicated inputs (keyboard or stick); mouse, when allowed, sets aim direction from mole to cursor.
- **Weapon inventory**: Minimal for V1: **Rocket**, **Grenade**, **maybe Skip / utility later**. Player cycles weapon with a **weapon next/prev** action (or fixed slots).

### Weapons (Behavioral Spec)

| Weapon        | Trajectory | Detonation | Terrain | Damage radius | Notes |
|---------------|------------|------------|---------|---------------|-------|
| Rocket launcher | Straight or mild gravity-affected raycast/segment motion | On impact with terrain or mole | Strong carve | Medium | Fast, thin **silhouette**; optional short **trail** for readability |
| Grenade       | Parabolic under gravity | **Fuse timer** (e.g. 3–5 s) or **impact** (choose one default: **timer** is classic); optional low bounce | Medium carve | Medium-large | Round **silhouette**; **blinking fuse** or color pulse for telegraph |

- **Knockback**: Explosions apply impulse; moles can fall or get **dunked** in water/death plane if implemented (optional V1: instant death below map).
- **Friendly fire**: **Match option** — default **OFF** for accessibility; when ON, own team can be damaged.

### Win / Lose

- **Elimination**: When a player has **zero living moles**, the other player **wins the match**.
- **Draw**: Rare (simultaneous last kill) — resolve with **tie** or **sudden death** round (design: **tie** increments neither score unless UX prefers replay).

### Session Scoring (Since Launch)

- On match end: increment **`wins[player]`** for winner.
- **Displayed** between matches and on a **session stats** area (exact HUD layout → UX agent).
- **Not** required to persist across quit (per R6 wording).

### Match Variables (Minimum Set)

| Variable | Type | Notes |
|----------|------|-------|
| `mole_health` | int | Starting / max HP for all moles in match |
| `first_player` | P1 / P2 / random | Who takes first turn |
| `friendly_fire` | bool | Default false |
| `turn_time_limit` | float or off | Optional |
| `map_seed` | int | Optional override for proc gen |

Additional vars (nice-to-have, not required by R1–R11): wind, explosion radius scale, jump power.

### Team Dynamics

- **Teams**: Player 1 = **Team A** (palette 1), Player 2 = **Team B** (palette 2). Moles spawn on **opposite halves** or **scattered** with clear team color **hats/vests/scarves** (art).
- **No AI teammates** in scope: exactly two humans, five moles each.

---

## Controls

### Actions (Semantic)

| Action | Purpose |
|--------|---------|
| Move left / right | Walk |
| Jump | Leave ground |
| Aim adjust + / − | Rotate launcher angle |
| Power + / − (optional) | If using charge mechanic; else fixed power |
| Fire | Launch rocket / throw grenade |
| Weapon next / prev | Select rocket vs grenade |
| End turn | Commit turn |
| Pause | Global (if UX implements) |

**Mouse (when active for current player):** aim toward cursor; **LMB** fire; **scroll** optional for weapon cycle.

### Two Players — **One Keyboard + Mouse**

**Policy:** Only the **turn owner** receives **mouse** aim. The other player’s inputs are ignored for gameplay (except pause if shared).

**Suggested layout (rebindable later):**

| Action | Player 1 | Player 2 |
|--------|----------|----------|
| Move | `A` / `D` | Left / Right arrows |
| Jump | `W` or `Space` | `Up` or `RShift` (or `Enter` as jump if UX prefers) |
| Aim − / + | `Q` / `E` | `[` / `]` or `,` / `.` |
| Fire | `F` or `LMB` when P1 turn | `;` or `LMB` when P2 turn |
| Weapon cycle | `1` / `2` or `Tab` | `-` / `=` |
| End turn | `G` | `Backspace` or `\` |

*Coding Agent:* centralize **input routing** by `turn_player` + **device policy** so key conflicts are minimized.

### Two Players — **Separate Gamepads**

- **Player 1** → first detected joystick or assignment from menu; **Player 2** → second.
- **Suggested:** Left stick or D-pad move; `A`/`X` jump; right stick **aim** (preferred) or bumpers for aim; `RT` fire; `LB`/`RB` weapon; `Y` end turn.
- **Hotseat rule:** Ignore non-active pad except **pause** if both can pause — UX decision.

### LÖVE Callback Mapping (Where Logic Lives Conceptually)

- `love.keypressed` / `love.keyreleased` → buffer digital state.
- `love.mousemoved` / `love.mousepressed` → only if `mouse_owner == turn_player` and match uses mouse aim.
- `love.joystickpressed` / axis polling in `love.update` → per-player slots.
- **Single module** conceptually responsible for **InputRouter(player, turn, scheme)** — actual file path is Architect’s call.

---

## Game Loop

### States (State Machine)

1. **Boot / splash** (optional)
2. **Main menu** — new match, match options, input test, quit
3. **Match setup** — confirm seed, health, devices
4. **Playing** — turn-based combat
5. **Round interstitial** (optional) — only if multi-round match; REQ implies **match = one terrain + fight**; session is multiple matches
6. **Match over** — show winner, update session score, rematch or menu
7. **Pause** (overlay on Playing)

### Update / Draw Flow (Per Frame)

```lua
update(dt):
  if pause: handle pause-only input; return
  if state == Playing:
    if projectiles_active: integrate physics, collisions, explosions, damage
    elif turn_phase == moving: apply mover input to active mole
    elif turn_phase == aiming: apply aim input; maybe charge timer
    check win condition

draw():
  draw terrain → moles → projectiles → particles → UI (UX owns layout)
```

**Turn Phases (Recommended):** `moving` → `aiming` → `firing` → `watching` (projectiles/explosions resolve) → auto-return to `moving` or prompt **End turn**. Simpler V1: single phase **combined** move+aim until Fire or End turn — still document projectile resolution as **watching**.

---

## File Structure

*Game-designer hints only — Architect owns full tree.*

| Area | Suggested Responsibility |
|------|---------------------------|
| `main.lua` | Bootstrap, require scenes, delegate `love.*` |
| `conf.lua` | Window, vsync |
| Scene modules (e.g. `src/scenes/*.lua`) | Menu, play, gameover |
| World/combat modules | Terrain, mole entities, projectiles, explosions, turn controller |
| `src/data/` or inline | Weapon defs (damage, radius, fuse, sprite ids) |
| Input | Dedicated router used by play scene |

**Dependency direction:** scenes orchestrate; entities do not require scenes; weapons data tables do not require entities.

---

## Considerations

- **Determinism:** Proc gen + session score + turn order should use explicit seeds where useful for **replays / QA**.
- **Controller detection:** On menu, show **which device** is assigned to P1/P2; allow **reassign**.
- **Keyboard conflict:** Shared-keyboard layout must avoid **same key** for both players’ primary actions.
- **Performance:** Destructible terrain updates are costly — Architect may choose mask + batch redraw; designer constraint: **explosion count** per turn bounded by weapon types.
- **Readability:** Rockets vs grenades must differ by **shape, color, motion, and audio** (see below).

---

## Scenes or Screens

| Scene | Entry | Exit |
|-------|-------|------|
| Main menu | Boot | Start match → setup; Quit |
| Match setup | Menu | Play |
| Play | Setup / rematch | Match over when win; Pause |
| Pause | Play | Resume Play or Menu |
| Match over | Play | Rematch (new proc map) or Menu |

---

## Asset Structure

*Naming for game-art handoff — paths illustrative.*

```
assets/
  sprites/
    mole_team_a_idle.png / mole_team_a_walk_*.png / mole_team_a_aim.png
    mole_team_b_*.png
    rocket.png
    grenade.png
    terrain_tileset.png (if tile-based) OR generated at runtime (coder)
  audio/
    sfx_rocket_fire.wav
    sfx_grenade_toss.wav
    sfx_explosion_*.wav
    ui_click.wav
  fonts/
    (UI font — UX picks)
```

**Animation states (minimum):** idle, walk (2+ frames or bob), aim/fire pose, hurt, death (simple fall off or poof).

---

## Persistence

- **Session score only** in memory: `wins = { [1]=0, [2]=0 }`.
- **Optional later:** `love.filesystem` for settings (volume, key binds) — **out of scope** for R6 unless UX expands.

---

## Implementation Order

1. **Core loop + terrain + one mole** movement/jump on static test map.
2. **Second mole + turn switching** (no weapons) to validate rotation pointers.
3. **Rocket** + collisions + terrain destruction + damage.
4. **Grenade** + fuse + distinct VFX.
5. **5 moles per team**, spawn placement, elimination win, **session score**.
6. **Proc gen** maps hooked to match start + seed option.
7. **Match options** (health, friendly fire, first player).
8. **Input modes**: shared KB+M routing + two gamepads.
9. **Polish**: particles, screenshake (subtle), sound; menu flow to UX spec.

---

## Visual Gameplay (In-World)

- **Silhouette & scale:** Moles **chunky**, **team-colored accessory** visible at all times; weapons **readable** when equipped (small launcher on back or in hands).
- **Projectiles:** Rocket = **elongated**, fast, **orange/red trail**; Grenade = **round**, **arc**, **pulsing fuse** pixel or timer ring.
- **Animation hooks:** States listed under **assetStructure** drive which sprite set is shown.

---

## Notes for Coding Agent

- Treat `REQUIREMENTS.md` R1–R11 as **acceptance criteria**; this doc refines **behavior** only.
- **Player rotation** = strict **alternating turns** between humans; **mole rotation** = **roster index advances** when that player **ends their turn** (skip dead).
- **Mouse** in shared mode: **gate** all mouse handlers on `active_player == mouse_bound_player` or “only active turn.”
- Keep weapon parameters in **data tables** so tuning does not scatter magic numbers.
- Do not implement **network multiplayer** in this design scope.

---

## LÖVE Architect Design — “Moles” (Worms-style clone)

**Agent:** `love-architect`  
**Scope:** Module boundaries, `require` graph, LÖVE lifecycle delegation, procedural map *architecture* (not art direction), session score tracking *architecture*.  
**Traceability:** Maps to `REQUIREMENTS.md` R1–R11.

---

## 1. High-level Architecture

### 1.1 Runtime Model

- **Single-threaded** LÖVE 11.x loop: `love.load` → repeated `love.update(dt)` / `love.draw()`.
- **Scene stack** (or ordered scene registry): `Boot` → `MainMenu` → `MatchSetup` → `Play` → `RoundEnd` / `MatchEnd` → back to menu or rematch. `Pause` overlays `Play` when active.
- **World simulation** during `Play`: deterministic-ish fixed timestep or capped `dt` (coding agent chooses; document recommends max `dt` clamp for stability).
- **Separation:**
  - **Simulation** (`src/sim/`, `src/world.lua`): positions, health, terrain mutations, projectiles, explosions — **no** `love.graphics` except where unavoidable (prefer passing drawables from assets layer).
  - **Presentation** (`src/render/`, `src/ui/`): cameras, sprites, particles, HUD; reads **snapshots** or immutable view structs from sim to avoid tearing during draw.
  - **Input** (`src/input/`): maps devices → **intent** (move, aim, fire, jump, weapon cycle, menu navigate). Play scene consumes intents, not raw keys.

### 1.2 Data Flow (One Frame in `Play`)

```lua
love.update(dt)
  → input.poll() → PlayerIntents[1..2]
  → turn.resolve_if_timer_or_commit()  -- when applicable
  → world.update(dt, intents)           -- moles, projectiles, terrain, damage
  → camera.follow(active_mole)
  → session_scores unchanged until match end

love.draw()
  → render.background / parallax (optional)
  → render.terrain(world.terrain)
  → render.entities(world)
  → render.effects(particles)
  → ui.hud(match_state, intents feedback)
```

### 1.3 Parallel Pipeline Contract

| Owner | This Architect |
|-------|----------------|
| Module paths & public APIs | Yes |
| `love.load` / `update` / `draw` delegation | Yes |
| Turn order, damage tables, weapon tuning numbers | Designer (consume via `MatchRules` / config tables) |
| Pixel look, fonts, menu layout | UX |

---

## 2. File / Directory Structure (Proposed)

Greenfield repo: introduce standard LÖVE layout. **Do not** scatter globals in `main.lua` beyond bootstrapping.

```
project root/
  main.lua                 -- thin: require bootstrap, forward love.*
  conf.lua                 -- window title, modules, vsync
  README.md                -- how to run (coding agent)

  assets/
    fonts/                 -- TTF/OTF (UX)
    images/                -- sprites, tiles (UX)
    shaders/               -- optional water/sky (UX)

  src/
    app.lua                -- owns scene manager, love callbacks entry
    bootstrap.lua          -- optional: package.path for src/

    config/
      defaults.lua         -- default MatchSettings, key bindings layout
      keymaps_shared.lua   -- logical action names only (no love.keyboard here)

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
      input_manager.lua    -- aggregates devices, produces intents per slot
      keyboard_mouse.lua   -- P1 mouse aim + keys; P2 keys-only profile
      gamepad.lua          -- per-joystick mapping for P1/P2

    sim/
      world.lua            -- World table: terrain, entities, projectiles; step()
      terrain.lua          -- grid or polygon API; destructible; collision queries
      terrain_gen.lua      -- **pure** procedural generation (see §5)
      mole.lua             -- mole state: team, hp, facing, grounded, weapon
      projectile.lua       -- rocket, grenade base behavior
      weapons/
        registry.lua       -- weapon id → module
        rocket.lua
        grenade.lua
      physics.lua          -- gravity, walking, simple collision resolution (pure helpers)
      damage.lua           -- apply damage, knockback hooks (pure)
      turn_state.lua       -- whose turn, selected mole, timers (drives rotation R8)

    render/
      camera.lua
      terrain_draw.lua
      mole_draw.lua
      effects.lua          -- particles tied to sim events

    ui/
      hud.lua              -- wind, team HP summary, weapon, timer (coordinates with UX)
      widgets.lua          -- optional shared UI helpers

    data/
      session_scores.lua   -- in-memory + optional persistence (R6)
      match_settings.lua   -- schema + validation for setup screen
      save_format.lua      -- versioned table for future expansion

    util/
      timer.lua
      vec2.lua             -- pure 2D math
      signal.lua           -- optional decoupling: sim emits events for audio/FX
```

**Modification note:** There is no existing Lua tree; the coding agent creates these files. `REQUIREMENTS.md` remains the source of requirement IDs.

---

## 3. Key Data Models & Interfaces

### 3.1 `MatchSettings` (R7, R9)

Table (Lua) validated in `match_settings.lua`:

```lua
-- Pseudocode shape (not implementation)
MatchSettings = {
  moles_per_team = 5,           -- R7 fixed for v1 or configurable upper bound 5
  mole_max_hp = 100,            -- R9
  turn_time_seconds = 60,       -- optional designer default
  wind_enabled = true,
  input_mode = "shared_kb" | "split_kb" | "dual_gamepad",
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

### 3.3 `World` / Entity Handles

- **Terrain:** 2D destructible field. Recommended: **bitmap/grid** of material IDs + surface normals cached for walking/aim, or **mask image** LÖVE `ImageData` for blast carving (performance-sensitive; coding agent benchmarks).
- **Moles:** array or map of structs: `{ id, player_id, team_slot, x, y, vx, vy, hp, facing, current_weapon, alive }`.
- **Projectiles:** list of `{ type, owner_id, x, y, vx, vy, fuse, ... }`.
- **Turn state** (`turn_state.lua`): `{ active_player, active_mole_index, phase = "aim" | "moving" | "firing", time_left }` aligned with Designer’s turn rules.

### 3.4 `PlayerIntent` (R4, R10, R11)

Per player slot, per frame:

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

## 4. Component Breakdown & Responsibilities

| Module | Responsibility |
|--------|----------------|
| `app.lua` | Scene stack, global services (`input`, `session_scores`, `assets`), dispatches `love.*` |
| `scenes/*.lua` | UI flow only; `play.lua` owns `World` lifecycle (create from `terrain_gen` + spawn moles) |
| `input_manager.lua` | R10/R11: bind two players to devices per `MatchSettings.input_mode` |
| `terrain_gen.lua` | R5: deterministic seed → terrain + spawn points; **pure function** ideal for tests |
| `world.lua` | Integrates sim subsystems; order: projectiles → explosions → terrain → moles |
| `weapons/rocket.lua` | Straight-line or arced shot; blast radius; terrain carve; damage falloff (numbers from Designer) |
| `weapons/grenade.lua` | Timed fuse, bounce optional; explosion same pipeline as rocket |
| `turn_state.lua` | R8: after a mole acts (or turn ends), advance to next **alive** mole on other team, then alternate **player**; skip dead moles |
| `session_scores.lua` | R6: increment on `match_end` |
| `match_setup.lua` | R9: edit `MatchSettings`, select input mode, start match |

### 4.1 Turn Rotation (R8) — Architectural Rule

- Maintain **round-robin** across teams: Player 1 uses mole `k`, then Player 2 uses mole `k` (same slot index if both alive), or Designer may specify “strict alternation per mole count” — **implementation reads rules from a single `MatchRules` table** (owned by Designer doc) to avoid hardcoding in `turn_state.lua`.
- **Invariant:** Only one active mole receives movement + aim + fire each turn segment.

---

## 5. Procedural Map Generation (Architectural Plan)

**Module:** `src/sim/terrain_gen.lua` (pure Lua; testable without LÖVE if terrain is arrays; if using `love.imagegenerator`, isolate IO behind `terrain_gen.build(seed, width, height) → TerrainModel`).

**Suggested Pipeline:**

1. **Base shape:** Perlin/simplex heightmap or stacked sine bands → solid vs air boolean grid.
2. **Layers:** Optional strata (dirt, rock) for different blast resistance (Designer).
3. **Water / hazards:** Optional plane at bottom; moles spawn above water line.
4. **Spawn platforms:** Sample two regions (left/right thirds) for flat surfaces wide enough for 5 moles; if fail, reject and re-seed (bounded retries).
5. **Determinism:** `seed = os.time()` or user-entered seed from setup for reproducibility.

**Output:** `TerrainModel` consumed by `terrain.lua` to build runtime collision/render buffers.

**Performance Note:** Regenerate only between matches, not each frame.

---

## 6. Score Tracking (R6) — Lifecycle Hooks

| Event | Action |
|-------|--------|
| `love.load` | `session_scores` initialized once |
| `match_end` scene | Read winner from `World` / `turn_state`; call `record_match_outcome` |
| `menu` / HUD | Display running totals from `get_snapshot()` |

No requirement to persist across app restarts for v1.

---

## 7. LÖVE Lifecycle Delegation

### 7.1 `conf.lua`

- Title, window size, `t.modules` defaults; optional `t.console = true` for dev.

### 7.2 `main.lua`

```lua
-- Pseudocode
local app = require("src.app")
function love.load(...) return app.load(...) end
function love.update(dt) return app.update(dt) end
function love.draw() return app.draw() end
function love.keypressed(k, sc, r) return app.keypressed(...) end
-- forward gamepad*, mouse*, resize as needed
```

### 7.3 `app.lua`

- `load`: init `love.graphics` defaults, load fonts/images (via asset loader), create `InputManager`, `SessionScores`, push `Boot` → `Menu`.
- `update`: `input_manager.update()`; top scene `update(dt)`; scene may substitute stack (pause push/pop).
- `draw`: clear; scenes draw bottom-up; global HUD overlays if scene requests.

### 7.4 `play.lua` Specifics

- `enter`: build `MatchSettings` from setup; `terrain = terrain_gen.build(...)`; spawn 10 moles (5 per player); init `turn_state`; reset camera.
- `update`: pass intents to `world.update`; detect win condition (one side all dead) → transition `match_end`.
- `leave`: dispose large objects if needed; keep `session_scores` alive on `app`.

---

## 8. Dependencies & Technology Choices

| Choice | Rationale |
|--------|-----------|
| **Stock LÖVE 11.x** | No external Lua rocks required for MVP; simpler CI and distribution. |
| **Lua version** | Target LuaJIT (LÖVE default); avoid 5.4-only APIs (`table.unpack` portability if shared code). |
| **No middleweight ECS library** | Small team count; plain tables + functions keep blueprint clear. |
| **Optional `push`/`hump` libraries** | Only if coding agent needs camera/timer; prefer minimal `src/util` first. |
| **Destructible terrain** | `ImageData` or Canvas mask is idiomatic in LÖVE; architect leaves final representation to coding agent with perf budget. |

---

## 9. `require` Direction (Avoid Cycles)

```
app → scenes → world → (terrain, mole, projectile, weapons/*, turn_state)
app → input → (keyboard_mouse, gamepad)
world → util/vec2, util/timer
scenes → session_scores, match_settings
terrain_gen → (no scene/world imports)
```

**Rule:** `terrain_gen`, `damage`, `vec2` are **leaves** or near-leaves. `world` must not `require` `render/*`.

---

## 10. Implementation Notes for the Coding Agent

1. **Fixed order in `world.update`:** wind → mole movement (active only) → weapon charge → projectiles → collisions → damage application → death removal → win check.
2. **Active mole:** `turn_state` exposes `get_active_mole_id()`; `world` ignores movement intents for others (or zeroes them in `input_manager` for cleaner separation — pick one place only).
3. **Rocket vs grenade:** share an `explosion_at(x, y, radius, damage_table)` in `damage.lua` / `world.lua` to avoid duplication.
4. **Two players one keyboard:** P1 uses mouse for aim; P2 uses keys for aim vector (e.g. IJKL or numpad); document in `defaults.lua`.
5. **Separate controllers:** `love.joystick.getJoysticks()`; assign joystick 1 → P1, joystick 2 → P2 in `dual_gamepad` mode; handle hotplug gracefully (fallback to menu).
6. **Testing hooks:** Keep `terrain_gen.generate(seed, w, h, rules) → grid` pure; keep `damage.compute(hp, distance, falloff)` pure for unit-style tests in pipeline if added later.
7. **Art vs sim:** Moles are capsules or simple AABB in sim; render can be skeletal sprites — **do not** tie collision to sprite pixel bounds without scaling factor.

---

## 11. JSON Summary (Orchestrator / Merge-Friendly)

```json
{
  "architecture": "LÖVE 11 scene stack (menu → setup → play → end); sim/render/input separation; world.update consumes PlayerIntents; session_scores updated at match end only.",
  "luaModules": {
    "src/app.lua": "Scene stack, love.* forwarding, service singletons",
    "src/scenes/play.lua": "Owns World lifecycle, win detection, camera target",
    "src/input/input_manager.lua": "Public: update(), get_intents(), reconfigure(MatchSettings)",
    "src/sim/world.lua": "Public: new(settings), update(dt, intents), draw_snapshot accessors",
    "src/sim/terrain_gen.lua": "Public: build(seed, width, height, rules) → TerrainModel (pure preferred)",
    "src/sim/turn_state.lua": "Public: advance(), active_mole(), on_mole_action_complete()",
    "src/data/session_scores.lua": "Public: reset(), record_match_outcome(winner), get_snapshot()",
    "src/data/match_settings.lua": "Public: defaults(), validate(t), merge_partial(ui_fields)"
  },
  "fileStructure": "See §2; root main.lua + conf.lua + src/** + assets/**",
  "loveLifecycle": "main.lua → app.load/update/draw; scenes handle domain; play delegates to world",
  "dependencies": ["LÖVE 11.x stock; optional small libs only if justified"],
  "considerations": [
    "Destructible terrain is perf-sensitive; generate once per match",
    "Single source of truth for MatchRules to sync Designer + turn_state + weapons",
    "Input mode switching must rebuild bindings without restarting app",
    "Session scores are in-memory for v1 unless extended"
  ]
}
```

---

## 12. Requirements Crosswalk

| ID | Architectural Home |
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
| R10 | `keyboard_mouse` + `gamepad` input handling |
| R11 | `input_manager` for dual gamepad support |

---

## LÖVE UX Design — Moles (Worms-style clone)

**Agent:** `love-ux`  
**Scope:** Screens, HUD, input affordances, resolution/scaling, focus/navigation — not combat math or physics (Game Designer / Architect).  
**Traceability:** Maps to `REQUIREMENTS.md` R1–R11.

---

## 1. High-level Architecture (UX Layer)

### 1.1 Design Intent

- **Readable in motion:** HUD and world feedback must stay legible during camera pan, explosions, and turn transitions (R1).
- **Two