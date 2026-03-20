## Original task (source of truth)

Create a beautifully styled 'moles' clone of the game 'worms' that implements the core game mechanics, including rocket launchers and grenades. The game should support 2 player local mode with procedurally generated maps, keep track of scores of games played since launching, allow teams of 5 moles per player, rotate players and moles each round, and enable players to set match variables like mole health. Additionally, support 2 players on a single keyboard/mouse or with separate controllers.

---

# Moles (Worms-style) Design Document

**Agents:** `game-designer`, `love-architect`, `love-ux`  
**Target:** LÖVE **11.4**  
**Codebase note:** Repository currently has no `main.lua` / `src/` yet (see `.pipeline/architecture-brief.md`). This spec is the mechanics and rules blueprint; **LÖVE Architect** should wire modules; **LÖVE UX** owns visual polish and HUD layout.

---

## Requirements Checklist

Cross-reference: every distinct ask from the product brief must be tickable by implementation.

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena feel—not a different genre).
- [ ] Presentation is **beautifully styled** (cohesive mole/underground theme; UX agent handles pixels—mechanics must expose readable state for HUD).
- [ ] **Core Worms-like mechanics** are implemented: turn order, aiming + power, projectile flight, gravity, terrain collision, explosions carving terrain, knockback / fall damage (or equivalent lethality), elimination when HP ≤ 0, round/match flow.
- [ ] **Rocket launcher** weapon: fast projectile, impact explosion, terrain damage, damage to moles in radius.
- [ ] **Grenade** weapon: arcing throwable, timed or configurable fuse, explosion with terrain damage and area damage.
- [ ] **2-player local** mode only (no online in this scope).
- [ ] **Procedurally generated maps** each match or each round (designer choice: per match recommended for pacing).
- [ ] **Session score tracking**: wins (or points) accumulated **since app launch** (persist across matches in memory; optional save to disk is out of mechanics scope unless Architect adds settings persistence).
- [ ] **Teams:** **5 moles per player** (10 moles total in 1v1); clear team ownership and friendly-fire rule (recommend **friendly fire on** for Worms authenticity, or **off** as match option—see match variables).
- [ ] **Rotate players each round**: after a round ends, which human **selects options / goes first** alternates (e.g. P1 → P2 → P1…).
- [ ] **Rotate moles each round**: active mole assignment or spawn order **varies** round-to-round so the same mole isn’t always “first” (e.g. cyclic roster index per team).
- [ ] **Match variables** (pre-match): at minimum **mole max health** (or starting HP) set by players; room for wind strength, turn time, fuse length, etc.
- [ ] **Input:** two players can play on **one keyboard + mouse** **or** each with a **separate gamepad/controller** (hot-plug friendly); device assignment before/during match setup.

---

## Target LÖVE Version

`11.4`

---

## Mechanics

### High-level Pitch

Turn-based **2D artillery** on a **destructible procedural map**. Two human players each command a **team of 5 moles**. One **active mole** per team per turn (classic Worms cadence). Players **aim**, set **shot power**, choose **weapons** (minimum: **rocket launcher**, **grenade**), and fire. **Terrain** is removed by blasts; moles can **fall**; **HP** tracks damage. A **round** ends when one side has no living moles; a **match** is a configurable **first-to-N rounds** (default e.g. best of 3). **Session scores** count round or match wins since launch.

### Team Dynamics

- **Ownership:** Player A → Team A (moles A1–A5); Player B → Team B (B1–B5).
- **Turn model:** Strictly alternating **teams** (not alternating every mole on same team in one round—keep one active mole per side per turn unless you add “sudden death” rules later).
- **Information:** Both players see the full map (single shared view is fine for local 2P; split camera optional UX).
- **Win round:** All enemy moles eliminated (HP ≤ 0 or out-of-bounds if implemented).
- **Win match:** Reach target wins (session counter increments).

### Player & Mole Rotation (Each Round)

- **Player rotation (meta):** After each round, swap **priority** for UI flow: who confirms **match variables**, who picks **first turn**, or simply swap **who fires first** next round. Simplest rule: `startingPlayerIndex = (roundIndex) % 2` so P1 starts odd rounds, P2 even (or inverse—document one rule in code comments).
- **Mole rotation (roster):** Maintain a **cursor per team** into the list of 5 moles. At round start, **advance cursor by 1 (mod 5)** so the “first mole up” cycles. When a mole dies, **remove from active turn queue**; cursor skips dead entries. New round: living moles only; cursor still advances for variety.

### Weapons (Core Set)

| Weapon          | Behaviour Summary |
|-----------------|-------------------|
| **Rocket launcher** | Straight or lightly arcing shot (choose one and stay consistent); **high speed**; **on impact**: spawn **explosion** (radius R_r), **terrain carve**, **impulse** to moles, **direct + splash damage** by distance. |
| **Grenade**     | **Arc** under gravity; **fuse** T seconds (match variable or fixed); **on timeout**: same explosion model as rocket (reuse one `explosion()` primitive). Optional: **tap fuse** or **variable throw power**—if scope tight, fixed fuse + aim + power only. |

Shared rules: **one shot** (or one “use”) ends the active mole’s turn unless a future item says otherwise; **backblast** optional (off by default).

### Procedural Map

- **2D destructible heightfield** or **bitmap terrain** (Architect chooses). Designer requirements: **irregular surface**, **overhangs optional**, **minimum playable area**, **spawn platforms** for both teams (left/right bias or labeled spawn zones). **Seed** optional for reproducibility in debug.
- **Hazards (optional phase 2):** water = instant kill or damage per tick—omit v1 unless time permits.

### Damage, HP, and Death

- **Mole HP:** Integer; **match variable** default e.g. 100; clamp to sensible min/max in UI.
- **Damage:** Splash falls off with distance; **direct hit** bonus for rocket on body.
- **Knockback:** Velocity impulse from explosion center; **fall damage** when vertical velocity or fall height exceeds threshold (tunable).
- **Death:** HP ≤ 0 or OOB; remove from turn queue; ragdoll/visual is UX.

### Wind (Recommended for Worms Feel)

- **Scalar wind** along +x / −x affecting projectile acceleration (rockets light effect, grenades medium). Expose as **match variable** or random per round.

### Match Variables (Pre-match Lobby)

Minimum:

- **Mole health** (starting HP).
Recommended same screen:
- **Match length** (rounds to win).
- **Turn timer** (optional clock).
- **Wind strength** (0 = off).
- **Grenade fuse** (if not fixed).

All variables require **both players’ confirm** or **host-style P1 confirm**—pick one flow (recommend: **both press confirm**).

### Session Scoring

- On **match end**: increment winner’s **sessionWins**.
- Display on **main menu** and **post-match** summary.
- **Reset** only on app quit (unless UX adds “reset scores” button—optional).

---

## Controls

Design for **two locals** with **either** shared KB+M **or** two gamepads. Avoid assuming mouse for both if one player is gamepad-only.

### Actions (Per Player)

- **Move mole** (small left/right step along terrain, Worms-style)—limited **move budget** per turn (e.g. finite “energy” or N seconds).
- **Aim:** adjust **angle** (keyboard: up/down; gamepad: stick).
- **Power:** hold/charge or separate axis (keyboard: hold key increases power; gamepad: right trigger or second stick).
- **Fire:** confirm shot.
- **Weapon cycle:** switch between **rocket** / **grenade** (and future weapons).
- **Jump** (optional): short hop if Architect implements discrete cells; else omit v1.

### Suggested Default Bindings (Implement as Data Table, Remappable Later)

**Player 1 — Keyboard**

| Action        | Keys (Example)   |
|---------------|------------------|
| Walk left/right | `A` / `D`      |
| Aim up/down   | `W` / `S`        |
| Increase power | `Shift` (hold) or `E` / `Q` |
| Fire          | `Space`          |
| Weapon next   | `1` / `2` or `[` / `]` |

**Player 2 — Keyboard (Shared Keyboard)**

| Action        | Keys (Example)   |
|---------------|------------------|
| Walk          | Numpad `4` / `6` or arrows |
| Aim           | Numpad `8` / `5` or `I`/`K` |
| Power         | Numpad `+` hold or `O`/`L` |
| Fire          | Numpad `Enter` or `Right Ctrl` |
| Weapon        | `-` / `+` on numpad |

**Mouse (Optional Shared):** **Click-drag** aim vector from mole; **scroll** power; **LMB** fire—**only when “active device” includes mouse** for that player to avoid stealing input.

**Gamepads:** Player 1 → first detected joystick index 1, Player 2 → index 2 (or assignment UI). **Left stick** move, **right stick** aim (or D-pad aim), **RT** power, **A** fire, **LB/RB** weapon.

### Input Routing

- Maintain `PlayerInputProfile` = `{ deviceKind, deviceId, bindings }`.
- Each frame, **only the active team’s active mole** accepts **that player’s** profile.
- **love.keypressed**, **love.gamepadpressed**, **love.mousepressed** dispatch to a central `InputSystem` that writes to **intent** structs (`aimDelta`, `powerDelta`, `firePressed`, etc.) consumed in `love.update`.

---

## Game Loop

State machine (conceptual; scene names for Architect):

1. **Boot / splash** — load assets, detect joysticks.
2. **Main menu** — session scores, **New match**, **Controls**, **Quit**.
3. **Match setup** — set **match variables**, assign **input devices**, **Start**.
4. **Play** — run **round loop**:
   - Generate / reset **procedural map** (per design choice).
   - Spawn 5 moles per team at **spawn zones**.
   - Apply **mole rotation** cursors and **starting player** from rotation rules.
   - **Turn loop:** select active mole → movement/aim/power → fire → resolve projectiles/explosions → check eliminations → next team.
   - **Round end** when one team wiped → update **session score** if match point, else next round.
5. **Pause** (optional) — overlay, freeze simulation `dt`.
6. **Match over** — show winner, session totals, **Rematch** (same settings) / **Main menu**.

**Update Order (Recommended):** input → turn FSM → mole movement integration → projectiles → explosions/deferred terrain updates → damage/knockback → fall damage → death/round check → camera (UX).

**Draw Order:** parallax/background → terrain → moles → projectiles/particles → HUD (UX).

---

## File Structure (Game-Relevant Hints Only)

Do not treat this as the full repo tree—**Architect** owns `src/`. Gameplay code should live in modules such as:

- `src/systems/turn.lua` — whose turn, mole selection, rotation application.
- `src/systems/weapons.lua` — rocket, grenade definitions; shared explosion.
- `src/systems/projectiles.lua` — integration, collision with terrain/moles.
- `src/world/terrain.lua` — procedural gen + carve.
- `src/entities/mole.lua` — HP, pose, physics state.
- `src/match/session.lua` — session wins, match variables snapshot.

**Assets (Conceptual):** `assets/sprites/moles/`, `assets/audio/sfx/explosion.ogg`, `assets/fonts/` — naming convention: `teamA_mole_01.png`, etc.

---

## Components (Responsibilities)

| Component           | Responsibility |
|---------------------|----------------|
| **MatchConfig**     | Holds health, rounds to win, wind, fuse, friendly fire flag. |
| **Team**            | Id, player binding, list of moles, roster cursor for rotation. |
| **Mole**            | HP, position, velocity, facing, active weapon, alive flag. |
| **TurnController**  | Active player, active mole, phase: move / aim / firing / resolving. |
| **Weapon**          | Fire(): spawn projectile(s) with initial state; ammo optional unlimited v1. |
| **Projectile**      | Update flight; on impact or timeout → queue explosion. |
| **Explosion**       | Terrain mask subtract; damage query by radius; apply impulses. |
| **Terrain**         | Generate; query collision; apply destruction. |
| **InputRouter**     | Maps devices to player ids; feeds TurnController. |
| **SessionStats**    | In-memory wins since launch. |

---

## Dependencies and Technology Choices

- **LÖVE 11.4** — cross-platform input, graphics, audio; familiar loop.
- **Lua** modules — keep gameplay data-driven (`weapons.lua` as tables).
- **Collision:** grid/bitmask terrain vs circle/AABB moles (Architect). No external physics engine required for v1 if custom integration is simpler.
- **No implementation here** — if Architect adds `bump.lua` or similar, mechanics stay in terms of “hit radius” and “impulse.”

---

## Considerations

- **Determinism:** Fixed `dt` cap + documented RNG seed for proc-gen aids debugging.
- **Controller hot-plug:** On `love.joystickadded/removed`, pause assignment or show “press A to join” (UX).
- **Same-keyboard:** Ensure **no key overlap** between P1 and P2 bindings; document in README.
- **Turn timer:** If enabled, auto-fire at low power or skip turn—state in TurnController.
- **Performance:** Explosion terrain ops can spike—batch mask updates or limit carve radius per frame (implementation note for coder).

---

## Scenes or Screens

- Main menu  
- Match setup (variables + devices)  
- Play (core loop)  
- Pause (optional)  
- Round interstitial (short “Round N — Player X starts”)  
- Match over  

Transitions: Menu → Setup → Play ↔ Pause → Match over → Menu or Setup (rematch).

---

## Asset Structure

- `assets/sprites/` — moles, terrain tiles, projectiles, UI chrome (UX)  
- `assets/audio/sfx/` — fire, boom, walk, UI blip  
- `assets/audio/music/` — menu + battle (optional)  
- `assets/fonts/` — one display font, one monospace for debug (optional)  

Naming: lowercase, underscores; version by suffix if needed (`explosion_01.png`).

---

## Persistence

- **v1:** Session scores **in RAM only** (requirement: “since launching”).
- **Optional later:** `love.filesystem` JSON for high scores or last-used match variables—out of scope unless product expands.

---

## Implementation Order (for Coding Agent)

1. **Terrain stub + one mole + camera** — prove walk/collision.  
2. **Turn FSM + alternating teams + one weapon (rocket)** — full turn loop.  
3. **Explosion carving + damage + knockback + death**.  
4. **Grenade + fuse + shared explosion path**.  
5. **Procedural map gen + team spawn**.  
6. **5 moles per team + mole rotation + player rotation between rounds**.  
7. **Match setup UI + variables (HP, etc.)**.  
8. **Input profiles: dual keyboard + dual gamepad + optional mouse**.  
9. **Session score + match/round end screens** (with UX).  
10. **Polish:** wind, particles, audio hooks.

---

## Pseudocode Snippets (Behavioural, Not Production Lua)

**Explosion Primitive (Shared):**

```lua
function explode(world, center, radius, damageMax, knockbackMax):
  terrain.carveCircle(center, radius)
  for each mole in world.moles:
    d = distance(mole.pos, center)
    if d < radius:
      mole.hp -= lerp(damageMax, 0, d / radius)
      mole.vel += radialImpulse(center, mole.pos, knockbackMax)
```

**Round Start Rotation:**

```lua
for each team in teams:
  team.moleCursor = (team.moleCursor + 1) % 5
startingPlayer = (roundIndex - 1) % 2
```

**Turn End:**

```lua
switchActiveTeam()
activeMole = nextLivingMole(activeTeam, team.moleCursor)
```

---

## Handoff Notes

- **LÖVE UX:** All timers, meters, weapon icons, and “beautiful styling” consume **exposed game state** (`activeMole`, `aimAngle`, `power01`, `wind`, `round`, `sessionWins`).
- **LÖVE Architect:** Implements modules and dependency direction; this doc defines **rules and data** only.
- **BigBoss Alignment:** Rocket launcher, grenades, **player rotation**, **mole rotation**, **2P local**, **teams of 5**, **proc maps**, **match variables**, **session scoring**, and **flexible input** are all specified above.

---

## 1. High-level Architecture

### Runtime Model

- **Single-threaded** LÖVE loop: `love.load` → repeated `love.update(dt)` / `love.draw()`.
- **Scene stack** (not inheritance-heavy): each scene is a table with optional `enter`, `leave`, `update`, `draw`, `keypressed`, `gamepadpressed`, etc. A thin **scene manager** forwards LÖVE callbacks to the top scene and optionally to a **global overlay** (pause, debug).
- **Game session** is a long-lived object created when entering **Play** from menus; it owns match config, roster, turn state, world (terrain + entities), and **session score** (wins since app start — persisted only in RAM unless product later adds saves).
- **Pure Lua leaves** for testability: trajectory math, collision resolution helpers, RNG-seeded map generation **data** (grid of materials / spawn points) separate from `love.graphics` drawing of that data.

### Dependency Direction (Require Graph)

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

## 2. File / Directory Structure

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
    │   └── constants.lua     # gravity, default teams size, etc.
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

## 3. Key Data Models, Interfaces, Schemas

### 3.1 `MatchConfig` (Table Shape)

| Field | Type | Purpose |
|--------|------|---------|
| `mole_max_hp` | number | Per-mole health |
| `turn_time_limit` | number \| nil | Seconds; nil = no limit |
| `wind_strength` | number | Optional; scalar or vec2 for drift |
| `map_width`, `map_height` | int | Pixel or cell size (one convention, document in code) |
| `teams_per_player` | int | Fixed 5 for this product |
| `procedural_seed` | int \| nil | nil → random seed at match start |

### 3.2 `Session` (In-memory)

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

### 3.5 Terrain / Map (API Sketch, Not Code)

- **Terrain** exposes:
  - `is_solid(x, y)` → bool  
  - `damage_circle(cx, cy, radius, destroy_mask)` or polygon carve for explosions  
  - Optional `surface_normal(x, y)` for sliding
- **Map** exposes:
  - Spawn positions per player  
  - World bounds for camera clamping  

### 3.6 Weapon Definitions (`src/data/weapons.lua`)

Named entries, e.g. `rocket`, `grenade`:

- `damage`, `radius`, `terrain_radius`  
- Grenade: `fuse_seconds`, `restitution`, `roll_friction` (tuning)  
- Rocket: `speed`, `hit_radius`, `trail` (presentation; optional)

---

## 4. Component Breakdown and Responsibilities

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

## 5. `love` Lifecycle Delegation

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

### Input Callbacks

- `love.keypressed` / `love.keyreleased` → `InputState` + `SceneManager` forward  
- `love.gamepadpressed` / joystick events → same; use `joystick:getID()` or LÖVE gamepad index consistently  

**Mouse (Shared Keyboard/Mouse):** Typically **only active player** uses mouse for aiming in hotseat; architecturally, `input/devices.lua` marks P1 or P2 as “mouse owner” and play scene routes `love.mousemoved` to aim angle for that slot.

---

## 6. Procedural Map Generation (Architectural)

- **Entry:** `mapgen.init.generate(config, seed)` returns `{ map = Map, terrain = Terrain }` (constructors defined in `map.lua` / `terrain.lua`).  
- **Pipeline Stages (Conceptual):**  
  1. **Heightfield** — base surface (1D or 2D height array).  
  2. **Optional caves** — subtract tunnels/caverns for Worms-like variety.  
  3. **Material mask** — air vs ground vs indestructible border.  
  4. **Spawns** — place 5 mole anchors per side, min separation and line-of-sight sanity checks; if fail, re-roll sub-seed or nudge positions (max attempts).  
- **Determinism:** All randomness through `core/rng.lua` with match seed logged in debug overlay for repro.  
- **Performance:** Generate once per round; gameplay mutates terrain only via explosions.

---

## 7. Dependencies and Technology Choices

| Choice | Rationale |
|--------|-----------|
| **Stock LÖVE 11.x** | No extra Lua libs required for MVP; keeps bootstrap simple. |
| **`love.joystick` + `love.keyboard` + `love.mouse`** | 2P local: one keyboard+mouse + one gamepad, or two gamepads; bindings table centralizes differences. |
| **Lua 5.1 module pattern** | `local M = {} … return M` per file; matches LÖVE embedding. |
| **No globals for game state** | `GameSession` table passed into scenes/systems; only `SceneManager` module-level singleton acceptable if documented. |
| **Optional later:** `bump.lua` or custom grid — architecturally keep **collision** behind `world/collision.lua` so swapping implementation is localized. |

---

## 8. `luaModules` — Public API Sketch (for Coding Agent)

| Path | Purpose | Public Surface (Indicative) |
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

## 9. JSON Handoff Fragment (Orchestrator / Tooling)

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

## 10. Implementation Notes for Coding Agent

1. **`conf.lua`:** Enable `t.modules.joystick = true`; set title; reasonable default window size for split terrain view.  
2. **Scene transitions:** New round → regenerate map with new seed (or “same seed” debug option from match setup).  
3. **Active mole only:** Input for weapons applies only to `turn_state:current_mole()`; other moles are idle (or cosmetic idle anim — UX).  
4. **Grenades vs rockets:** Share explosion path in `systems/explosions.lua`; differ only in flight (`entities/grenade.lua` vs `projectile.lua`).  
5. **Camera:** Single camera following active mole or free-look between turns — product decision; keep camera state in `play.lua` or `game/session.lua`, not globals.  
6. **Testing hooks:** Expose `mapgen.init.generate` and trajectory functions without requiring `love.graphics`; use `busted` or plain `lua` tests on those modules if CI adds Lua later.  
7. **Merge alignment:** Game Designer owns exact turn order, damage numbers, and control schemes; LÖVE UX owns HUD/layout — this document owns **where** those concerns live in code.

---

## 1. High-level UX Architecture

### 1.1 Design Pillars

- **Readable at a glance during motion:** large numerals, high-contrast team strips, minimal text during aiming.
- **Fair dual-input:** every menu path completable with **either** keyboard+mouse **or** gamepad; when two gamepads are connected, **Player 1** drives global menus unless a screen explicitly splits focus (see §4).
- **Session truth:** “Games won since launch” is always visible from pause and end-of-match screens; optional compact chip in-match (see HUD).
- **Worms-like clarity:** active mole, team, weapon, and “commit” affordance (fire / jump) must never be ambiguous in 2P hot-seat.

### 1.2 Scene Graph (Labels for Architect Alignment)

Use these **state names** in code/docs so parallel agents converge:

| State ID            | Purpose |
|---------------------|---------|
| `boot`              | Load assets, detect controllers, apply saved options |
| `title`             | Logo, press start / main menu entry |
| `main_menu`         | Play local, Options, Quit |
| `match_setup`       | Per-match variables (mole health, etc.), start match |
| `team_roster`       | Optional: name/color confirmation for 5 moles per player (can be minimal v1) |
| `playing`           | Core gameplay + in-world HUD |
| `pause`             | Overlay; both players may open (see §4.3) |
| `round_interstitial`| Brief banner: round end, score tick, next active mole hint |
| `match_summary`     | Match outcome + session stats + rematch / main menu |

Transitions are detailed in §3 (JSON `userFlows`).

### 1.3 Base Resolution and Scaling

- **Logical canvas:** `1280 × 720` (16:9). All layout numbers below are in **logical pixels** relative to this canvas.
- **`conf.lua` guidance (for implementer):** `t.window.width/height` or `love.window.setMode` targeting 1280×720; enable **resizable** with **uniform scale** (letterbox/pillarbox) so UI stays proportional. Maintain a **safe margin** of `24px` from each edge for critical HUD (scale this margin with the same UI scale factor).
- **UI scale factor:** `uiScale = min(screenW/1280, screenH/720)`; multiply layout constants when drawing so 720p assets remain crisp on 1080p/4K.

---

## 2. Proposed File / Directory Structure (UX-Facing)

These paths are **specification only** — no implementation in this task.

```
assets/
  fonts/
    ui_bold.ttf          # menu + HUD numerals (license-clear)
    ui_regular.ttf
  ui/
    atlas_moles_ui.png   # nine-slice panels, buttons, icons (weapon silhouettes)
   