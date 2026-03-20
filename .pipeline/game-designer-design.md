# Game Designer — Moles (Worms-style) Design

**Agent:** `game-designer`  
**Target:** LÖVE **11.4** (`conf.lua` sets `t.version = "11.4"`)

## Codebase alignment (build on existing files)

The repo already implements core data and simulation modules under `src/`. This spec **refines rules and handoff**; the Coding Agent should **extend** these files rather than invent parallel structures:

| Area | Existing module(s) | Design expectation |
|------|-------------------|-------------------|
| Entry | `main.lua`, `src/bootstrap.lua` | `main.lua` requires `app` (orchestrator/scenes—may still be stubbed); bootstrap sets graphics defaults. |
| Match variables | `src/game/match_config.lua` | `defaults()` / `validate()` already include HP, rounds to win, wind, grenade fuse, turn limit, friendly fire, map size, `input_scheme`. New toggles belong here with validation clamps. |
| Session | `src/game/session.lua` | See **Session stats definition** below—fields are authoritative. |
| Turn FSM | `src/game/turn_state.lua` | Phases: `aim`, `firing`, `flying`, `round_end`, `interstitial`; weapon list `rocket` / `grenade`; `advance_turn` / `start_match_turn` + `next_living_mole_index` encode turn cadence. |
| Teams / rotation | `src/game/roster.lua` | `MOLES_PER_TEAM` from `src/data/constants.lua` (5); `mole_order` + `rotate_order()` implement mole-order rotation. |
| Moles | `src/entities/mole.lua` | HP, `damage(..., friendly_fire, attacker_team)`, physics fields. |
| Weapons data | `src/data/weapons.lua` | Rocket vs grenade tuning; grenade fuse comes from match config at fire time (comment in data). |
| Projectiles | `src/entities/projectile.lua`, `src/entities/grenade.lua` | Flight, impacts, fuse behaviour—keep **one shared explosion primitive** conceptually (coder may centralize in world or a future `systems/` module). |
| World | `src/world/terrain.lua`, `map.lua`, `collision.lua` | Destructible terrain + collision. |
| Proc map | `src/world/mapgen/init.lua` (+ `heightfield.lua`, `caves.lua`, `spawns.lua`) | Heightfield surface + cave carve + team spawns; seed from `match_config.procedural_seed`. |
| Core utils | `src/core/rng.lua`, `timer.lua`, `vec2.lua` | Seeded RNG for generation; helpers for gameplay timing/vectors. |

**LÖVE UX** owns HUD/menu layout; **Architect** owns any missing `app.lua` / scene graph. This document does **not** specify pixel coordinates.

---

## Session stats definition (Overseer / coding contract)

**For the original brief phrase "scores of games played since launching", the implementation in `src/game/session.lua` shall be read as follows: `scores[1]` and `scores[2]` count each player's **match wins** accumulated since app launch (not round wins, not "games played" per player), while `matches_completed` counts **how many matches have been fully finished** in this session (one increment per match end), and neither `scores` nor `matches_completed` may be repurposed to mean round tallies without renaming and updating the UI copy.**

---

## requirementsChecklist

Cross-reference: every distinct ask from the product brief must be tickable by implementation.

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena feel—not a different genre).
- [ ] Presentation is **beautifully styled** (cohesive mole/underground theme; UX handles pixels—mechanics expose state for HUD: see `turn_state`, `match_config`, mole entities).
- [ ] **Core Worms-like mechanics** are implemented: turn order, aiming + power, projectile flight, gravity, terrain collision, explosions carving terrain, knockback / fall damage (or equivalent lethality), elimination when HP ≤ 0, round/match flow.
- [ ] **Rocket launcher** weapon: fast projectile, impact explosion, terrain damage, damage to moles in radius (`src/data/weapons.lua` → `rocket`).
- [ ] **Grenade** weapon: arcing throwable, timed / configurable fuse, explosion with terrain and area damage (`grenade` + `match_config.grenade_fuse_seconds`).
- [ ] **2-player local** mode only (no online in this scope); `match_config.input_scheme` distinguishes shared keyboard vs dual gamepad.
- [ ] **Procedurally generated maps** (`src/world/mapgen/`); recommend **new terrain per match** (or per round if match flow resets map—stay consistent in one place).
- [ ] **Session score tracking** since launch: **`scores` = match wins per player**, **`matches_completed` = finished matches** (see Session stats definition above).
- [ ] **Teams:** **5 moles per player** (`src/data/constants.lua` `MOLES_PER_TEAM`); friendly-fire rule driven by `match_config.friendly_fire` (already defaults true).
- [ ] **Rotate players each round**: alternate **starting player** / priority between rounds (tie to match round index in play state; `turn_state.start_match_turn` accepts `starting_player`).
- [ ] **Rotate moles each round**: vary mole turn order via `roster.rotate_order` / `mole_order` at round boundaries so the same slot is not always first.
- [ ] **Match variables**: at minimum mole health (`mole_max_hp`); also wind, fuse, rounds to win, etc. in `match_config.lua`.
- [ ] **Input:** **one keyboard + mouse** or **two controllers**; hot-plug friendly; only active player's mole accepts input during `aim` (conceptual `InputRouter`—may live in `app` or future `src/input/`).

---

## targetLoveVersion

`11.4`

---

## mechanics

### High-level pitch

Turn-based **2D artillery** on a **destructible procedural map**. Two human players each command **5 moles** (`roster.new_team`). **Alternating team turns** with one **active mole** per side per turn (`turn_state`). **Aim angle**, **charge power** (`POWER_CHARGE_RATE` in `constants.lua`), **weapon** rocket or grenade. **Terrain** carved by blasts; **moles** integrate position/velocity with **fall damage** thresholds in `constants.lua`. A **round** ends when one team has no living moles (`roster.team_living_count`). A **match** ends when one player reaches **`rounds_to_win`** round wins; then **`session.bump_match_win(winner)`** runs.

### Team dynamics

- **Ownership:** Player 1 → team 1 (moles indexed 1–5 in `team.moles`); Player 2 → team 2.
- **Turn model:** After a shot resolves, **`advance_turn`** switches `active_player` and picks next living mole using `mole_order` and preferred slot (see `turn_state.lua`).
- **Win round:** Enemy team `team_living_count == 0`.
- **Win match:** Round wins ≥ `rounds_to_win`; session updated as per Session stats definition.

### Player & mole rotation (each round)

- **Player rotation:** At the start of each **new round** within a match, set `starting_player = ((round_number - 1) % 2) + 1` (or equivalent 1-based alternation). Document chosen parity in code comments so UX copy matches.
- **Mole rotation:** Before placing moles or before first turn of the round, **`rotate_order(team.mole_order)`** for each team so cyclic order advances; `next_living_mole_index` must **skip dead moles** when resolving slots mid-match.

### Weapons (core set)

Aligned with `src/data/weapons.lua`:

| Id | Designer intent |
|----|-----------------|
| `rocket` | High `speed`, moderate wind coupling (`wind_scale`); on impact → blast using `blast_radius`, `terrain_radius`, `damage_max`, `knockback`. |
| `grenade` | Lower speed, bounce params (`restitution`, `roll_friction`); **fuse** from `match_config.grenade_fuse_seconds` at fire time; timed detonation → **same blast rules** as rocket for fairness. |

**Shared rule:** One firing action advances turn to **enemy** after projectiles settle (phases `flying` → resolution → `advance_turn`), unless a future weapon breaks that rule.

### Procedural map

Pipeline in `mapgen/init.lua`: heightfield surface → cave spheres → `spawns.place_team_spawns`. Requirements: both teams get **valid spawn anchors**; map dimensions respect `match_config.map_width` / `map_height`. **Seed** from config or random for variety.

### Damage, HP, and death

- **HP:** Set from `mole_max_hp` when spawning teams.
- **Damage:** Distance falloff in implementation; respect **`friendly_fire`** in `mole.damage`.
- **Fall damage:** Use `FALL_DAMAGE_THRESHOLD` / `FALL_DAMAGE_MULT` from `constants.lua` for consistency.
- **Death:** `alive = false`; exclude from `next_living_mole_index`.

### Wind

**Scalar horizontal acceleration** on projectiles scaled per weapon (`wind_scale` × `match_config.wind_strength`—exact formula is implementation detail but must be **shared** across weapons for predictability).

### Match variables (pre-match)

Source of truth: `match_config.defaults()` plus UX editing before `validate()`. **Confirm flow:** recommend both players confirm start (UX); store result in active `MatchConfig` for the match.

### Session scoring (recap)

On **match** end only: winner's `scores[winner] += 1`, `matches_completed += 1`, `last_match_winner` set, `last_match_config` snapshot optional for rematch. **Do not** increment `scores` on individual **round** wins—rounds feed **internal** round-win count toward `rounds_to_win` only.

---

## controls

### Actions (per active mole)

- **Move** along surface with **move budget** (`MOVE_BUDGET_MAX`, `MOVE_SPEED` in `constants.lua`).
- **Aim:** change `turn_state.aim_angle`.
- **Power:** `charging` + `power` clamped 0–1 (or project convention).
- **Fire:** transition `aim` → `firing` / spawn projectile.
- **Weapon:** cycle `weapon_index` over `turn_state.weapons`.

### Suggested bindings (data-driven table recommended; not necessarily all wired yet)

**P1 keyboard:** `A`/`D` move, `W`/`S` aim, hold e.g. `Shift` for power, `Space` fire, `1`/`2` weapons.  
**P2 keyboard (shared):** e.g. numpad `4`/`6`, `8`/`5`, numpad `+` power, `Enter` fire—**non-overlapping** with P1.  
**Mouse (optional):** when `input_scheme` allows, aim vector / click fire for **active** player only.  
**Gamepads:** P1/P2 joystick indices per `input_scheme == "dual_gamepad"`; sticks + trigger + face buttons as in prior design doc.

### Lua callback mapping

Centralize in orchestrator (`app` or future `input.lua`): `love.keypressed` / `love.keyreleased`, `love.gamepadpressed`, `love.mousepressed/moved` → **intents** (`aim_delta`, `move_dir`, `fire`, `weapon_next`) consumed in `love.update` only if `turn_state.phase == aim` and event targets `turn_state.active_player`.

---

## gameLoop

1. **Boot** — `love.load`: require paths set in `main.lua`; joystick scan.  
2. **Menu** — show `session:get_scores()`, `matches_completed`, start match.  
3. **Match setup** — edit `match_config`, pick `input_scheme`, validate.  
4. **Play** — `mapgen.generate(match_config, seed)`; build teams via `roster.new_team`; apply **player** and **mole** rotation rules; `turn_state.start_match_turn(...)`.  
5. **Per frame** — input → turn phase → mole physics (`collision` vs `terrain`) → projectiles/grenades → explosions → fall damage → check round end (`interstitial` / `round_end`) → match end → `session.bump_match_win`.  
6. **Pause / match over** — UX overlays; simulation `dt` zeroed when paused.

**Update order:** input → FSM → moles → projectiles → terrain mutations → damage → win checks → camera (UX).  
**Draw order:** background → terrain image → entities → VFX → HUD.

---

## fileStructure

**Existing (do not duplicate conceptually):**

- `conf.lua`, `main.lua`
- `src/bootstrap.lua`
- `src/core/{rng,timer,vec2}.lua`
- `src/data/{constants,weapons}.lua`
- `src/entities/{mole,projectile,grenade}.lua`
- `src/game/{match_config,roster,session,turn_state}.lua`
- `src/world/{terrain,map,collision}.lua`
- `src/world/mapgen/{init,heightfield,caves,spawns}.lua`

**Likely additions (when orchestration lands):** `src/app.lua` (or `src/scenes/*.lua`) for menu/play states and **input routing**—Architect owns naming; game-designer only requires **behaviour** above.

---

## components (responsibilities)

| Concept | Where it lives (current) |
|---------|---------------------------|
| Match variables | `match_config` table |
| Session win counts | `session.scores`, `matches_completed` |
| Turn phases / active mole | `turn_state` |
| Team + mole order rotation | `roster` |
| Weapon stats | `data/weapons` |
| Mole HP / damage rules | `entities/mole` |
| Projectile / grenade behaviour | `entities/projectile`, `entities/grenade` |
| Terrain + proc map | `world/*`, `world/mapgen/*` |

---

## dependencies and technology choices

- **LÖVE 11.4** only; no extra physics library required if custom collision stays sufficient.
- **Data-driven weapons** in Lua tables (`weapons.lua`).
- **Seeded RNG** (`core/rng`) for reproducible maps in QA.

---

## considerations

- Cap `dt` with `MAX_DT` in `constants.lua` for stability.
- **Joystick hot-plug:** refresh device list; UX prompts reassignment.
- **Explosion + terrain:** batch or throttle heavy mask writes if frame spikes occur.
- **Turn time limit:** if `turn_time_limit` non-nil, auto-end turn policy (e.g. fire at current aim with min power) should be documented in UX copy.

---

## scenesOrScreens

- Main menu (session totals)  
- Match setup (match_config + input)  
- Play  
- Pause (optional)  
- Round interstitial  
- Match over → rematch or menu  

---

## assetStructure

- `assets/sprites/`, `assets/audio/sfx/`, `assets/fonts/` (create as UX needs)  
- Reference from draw code in orchestrator; mechanics modules stay mostly asset-agnostic.

---

## persistence

- **Session:** RAM only in `session.lua` for v1 (matches "since launching").  
- **Optional later:** save `last_match_config` or session totals via `love.filesystem`—product decision.

---

## implementationOrder (delta from current codebase)

1. **Orchestrator + scenes** — wire `main.lua` → `app` with menu / play / game-over if missing.  
2. **Input** — full dual-keyboard + dual-gamepad + optional mouse routing to `turn_state`.  
3. **Round / match rules** — wire `rounds_to_win`, interstitials, **player** and **mole** rotation at round boundaries.  
4. **Session UI** — display `scores` as **match wins** and optionally `matches_completed` as **matches played** (clarify strings—see Session stats definition).  
5. **Combat polish** — wind on projectiles, shared explosion path, audio/VFX hooks.  
6. **Playtesting** — clamps in `match_config.validate`, spawn fairness in `spawns.lua`.

---

## Pseudocode (behavioural)

**Match end (session):**

```
on_match_winner_decided(winner_player_index):
  session:bump_match_win(winner_player_index)  -- increments scores[winner] AND matches_completed by 1
```

**Round start (rotation):**

```
starting_player = ((round_index - 1) % 2) + 1
for each team: team.mole_order = roster.rotate_order(team.mole_order)
turn_state.start_match_turn(ts, teams, starting_player, slot1, slot2)
```

---

## Handoff notes

- **BigBoss:** Rocket, grenade, player rotation, mole rotation, 2P local, teams of five, proc maps, match variables, flexible input—covered above and mapped to files.  
- **UX:** Label session UI so players understand **wins** vs **matches played** per Session stats definition.  
- **Coder:** When merging with `DESIGN.md`, treat this file's **Session stats definition** as authoritative for `session.lua` semantics.
