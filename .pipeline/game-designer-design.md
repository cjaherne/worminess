# Game Designer — Moles (Worms-style) Design

**Agent:** `game-designer`  
**Target:** LÖVE **11.4** (`conf.lua`: `t.version = "11.4"`)

## Codebase alignment (build on existing files)

The game is **implemented** under `src/` with scenes, systems, and input. This spec is the **mechanics + rules authority** for merges and future tweaks; extend these modules rather than adding parallel gameplay layers.

| Area | Module(s) | Design expectation |
|------|-----------|-------------------|
| Entry / lifecycle | `main.lua`, `src/bootstrap.lua`, `src/app.lua` | `app.register()` owns all `love.*` callbacks; forwards to `scene_manager`; clamps `dt` via `data.constants.MAX_DT`. |
| Scene stack | `src/scene_manager.lua`, `src/scenes/*.lua` | Stack draw order bottom→top; `play` owns match runtime; `pause` / `game_over` as overlays or stack pushes per Architect. |
| Match variables | `src/game/match_config.lua` | `defaults` / `validate` / `copy`; fields include HP, rounds to win, wind, fuse, turn limit, friendly fire, map size, `input_scheme`, `procedural_seed`. |
| Per-round seed | `src/game/map_seed.lua` | **`map_seed.derive(procedural_seed, round_index)`** implements Map regeneration cadence policy (see below). |
| Session | `src/game/session.lua` | **Session stats definition** below. |
| Turn FSM | `src/game/turn_state.lua` | Phases, `advance_turn`, `start_match_turn`, `next_living_mole_index`, weapon ids. |
| Teams / rotation | `src/game/roster.lua` | `MOLES_PER_TEAM` from `src/data/constants.lua` (5); `mole_order`, `rotate_order`. |
| Moles | `src/entities/mole.lua` | HP, `damage(..., friendly_fire, attacker_team)`, physics. |
| Weapons data | `src/data/weapons.lua` | Tunables for rocket / grenade. |
| Weapon + blast logic | `src/systems/weapons.lua`, `src/systems/explosions.lua` | Single explosion path; honor `friendly_fire`. |
| Projectiles | `src/entities/projectile.lua`, `src/entities/grenade.lua` | Flight, terrain/mole hits, fuse. |
| World sim | `src/systems/world_update.lua`, `src/systems/turn_resolver.lua` | Integration order, quiescence before turn advance. |
| World / gen | `src/world/terrain.lua`, `map.lua`, `collision.lua`, `src/world/mapgen/*` | Destructible terrain; **`world.mapgen.init.generate(match_config, seed)`**. |
| Input | `src/input/bindings.lua`, `devices.lua`, `stick.lua`, `input_state.lua` | Device assignment, smoothed sticks, semantic actions for active player. |
| Feedback | `src/systems/vfx.lua`, `src/audio/sfx.lua` | Non-mechanics presentation; mechanics must still expose state for HUD/SFX triggers. |
| UI shell | `src/ui/theme.lua`, `layout.lua`, `focus_stack.lua`, `src/ui/hud/play_hud.lua` | UX owns layout; see **README.md** / **CODING_NOTES.md** for implemented input/audio notes. |

**LÖVE UX** owns pixel wireframes; this doc does **not** specify coordinates.

---

## Session stats definition (Overseer / coding contract)

**For the original brief phrase "scores of games played since launching", `src/game/session.lua` shall mean:** `scores[1]` and `scores[2]` are each player’s **match wins** since app launch (not round wins, not per-player “games played” as a scoreboard); `matches_completed` is the count of **fully finished matches** in this session (one increment per match end); neither field may be repurposed for **round** tallies without renaming and updating UI copy.

---

## Map regeneration cadence (default — Overseer)

**Default cadence:** **Per round** — new procedural terrain **every round**, not once per match.

**When `world.mapgen.init.generate(match_config, seed)` runs:** **Once per round** at **round setup**: after the prior round outcome is known and any `interstitial` / `round_end` flow advances, **before** teams/moles are placed for the new round. **Round 1** uses the **same** code path (entering play = first round setup). **Do not** reuse the previous round’s terrain into the next round.

**Seed passed to `generate`:** Use **`src/game/map_seed.lua`** — `map_seed.derive(procedural_seed, round_index)`:

- **`procedural_seed == nil`:** each call returns a **new random** integer (`love.math.random`) → every round (and rematch rounds) gets **unrelated** terrain.
- **`procedural_seed` set:** deterministic mix of **(procedural_seed, round_index)** → rounds differ but replay is reproducible; **Rematch** restoring `session.last_match_config` keeps the same field → **round *k* after Rematch matches round *k* of the prior match** for terrain sequence.

**Implementation note for Coding Agent:** `play.lua` (or equivalent) should call `map_seed.derive` immediately before `world.mapgen.init.generate`; do not duplicate seed logic elsewhere unless abstracted.

---

## requirementsChecklist

One tick per distinct ask from the **original task** (sentence-level).

- [ ] Game is a **moles** themed clone of **Worms** (artillery, teams, destructible arena).
- [ ] Presentation is **beautifully styled** (theme/HUD/audio-VFX per UX + README; mechanics expose simulation state for feedback).
- [ ] **Core Worms-like mechanics:** turn order, aim + power, projectile flight, gravity, terrain collision, explosions carve terrain, knockback / fall damage (or equivalent), elimination at HP ≤ 0, round + match flow.
- [ ] **Rocket launcher** — fast shot, impact explosion, terrain + radial mole damage (`src/data/weapons.lua` → `rocket`; systems apply).
- [ ] **Grenades** — arc, configurable **fuse** (`match_config.grenade_fuse_seconds`), timed detonation, same blast model as rocket where appropriate.
- [ ] **2-player local** only; `match_config.input_scheme` **shared_kb** vs **dual_gamepad**.
- [ ] **Procedurally generated maps** (`src/world/mapgen/`); **per-round regen** at round setup via **`world.mapgen.init.generate`** + **`map_seed.derive`** (see Map regeneration cadence).
- [ ] **Scores since launch:** **`scores` = match wins per player**, **`matches_completed` = finished matches** (Session stats definition).
- [ ] **5 moles per player** (`MOLES_PER_TEAM` in `constants.lua`).
- [ ] **Rotate players each round** — alternate starting player / priority (`starting_player` pattern with round index; `turn_state.start_match_turn`).
- [ ] **Rotate moles each round** — `roster.rotate_order` / `mole_order` at round boundaries; living-only selection in turn advances.
- [ ] **Match variables** including at least **mole health** (`mole_max_hp`) plus other `match_config` fields (wind, fuse, rounds to win, timer, friendly fire, seed, map size, input scheme).
- [ ] **Input:** **two players on one keyboard + mouse** and/or **separate controllers**; hot-plug; combat intents only for **active** player during aim (`src/input/*`, `play` scene).

---

## targetLoveVersion

`11.4`

---

## mechanics

### High-level pitch

**2D turn-based artillery** on **destructible procedural terrain** (**regenerated every round**; Map regeneration cadence). Two locals each run a **team of 5 moles**. **Alternating team turns**; one **active mole** fires per turn (`turn_state`). **Aim**, **power**, **rocket** or **grenade**; **wind** affects flight (`weapons.wind_scale` × config). **Blasts** carve terrain and apply **damage + knockback** (`systems/explosions.lua`); **fall damage** uses `constants.lua` thresholds. A **round** ends when one team has **zero** living moles; a **match** ends when one player has **`rounds_to_win`** **round** wins; then **`session.bump_match_win`**.

### Direct hits (projectile vs mole)

**Rockets and grenades detonate on overlap with living moles**, not only on terrain impact (see **README.md** / **CODING_NOTES.md**). Friendly-fire gating still uses `match_config.friendly_fire` and attacker team when applying damage.

### Team dynamics

- Player 1 → team 1; Player 2 → team 2; moles indexed 1–5 in `team.moles`.
- After a shot fully resolves, **`advance_turn`** gives the other team the next living mole via `mole_order`.
- **Round win:** enemy `team_living_count == 0`. **Match win:** round-wins threshold.

### Player & mole rotation

- **Player:** e.g. `starting_player = ((round_number - 1) % 2) + 1` at each **round setup** (document parity in code for UX strings).
- **Mole:** `roster.rotate_order(team.mole_order)` each round; mid-round, `next_living_mole_index` skips dead slots (including if active mole dies in aim — README: reassign or end round if wipe).

### Weapons

| Id | Intent |
|----|--------|
| `rocket` | High velocity; impact → shared explosion (terrain + splash damage + impulse). |
| `grenade` | Arc, bounce/fuse behaviour from data + `grenade_fuse_seconds`; timed blast uses **same explosion path** as rocket for consistency. |

**Turn rule:** One fire resolves projectiles until world quiescent (`turn_resolver` / `world_update`), then **enemy** turn unless round/match end.

### Procedural map

`mapgen/init.lua`: heightfield → caves → `spawns.place_team_spawns`. Dimensions from `match_config`. **Seed:** always via **`map_seed.derive`** before `generate`.

### Session scoring (recap)

Increment **`scores`** and **`matches_completed`** only on **full match** victory, not per round.

---

## controls

### Actions

Move (budgeted), aim angle, charge power, fire, weapon cycle — consumed only when **`turn_state.phase == aim`** (or as coded for timers) for **`turn_state.active_player`**.

### Bindings & devices

- **Data:** `src/input/bindings.lua`; **devices / hot-plug:** `src/input/devices.lua` (refreshed from `app` joystick callbacks).
- **Gamepad aim smoothing:** `src/input/stick.lua` (especially **dual_gamepad**).
- **README / CODING_NOTES behaviour:** **shared_kb** — mouse wheel may adjust power during aim; optional pads follow **active** player; **dual_gamepad** — triggers/LB/RB for power, **Start** → pause from any pad.

### Callback flow

`love.keypressed` / `gamepadpressed` / `mouse*` / `wheelmoved` → `scene_manager` → active **scene** (`play`, `match_setup`, …) → input modules → **intents** on simulation.

---

## gameLoop

1. **Boot** — `scenes/boot.lua` → replace with **main_menu**.  
2. **Main menu** — session totals, navigate to **match_setup**.  
3. **Match_setup** — edit `match_config`, dual Ready, `match_config.validate`, push **play**.  
4. **Play** — each **round:** `seed = map_seed.derive(config.procedural_seed, round_index)` → `world.mapgen.init.generate(config, seed)` → spawn teams, rotations, `turn_state.start_match_turn` / `advance_turn` loop; **world_update** + **turn_resolver**; overlays for round/match end.  
5. **Pause** — stack or overlay; freeze or zero sim `dt` per implementation.  
6. **Game_over** — rematch (`session.last_match_config`) or menu.

**Sim update order (conceptual):** input → turn FSM → moles → projectiles → explosions/terrain → damage → fall → win checks → VFX/audio hooks.

---

## fileStructure (game-relevant)

| Path | Role |
|------|------|
| `conf.lua`, `main.lua` | LÖVE entry |
| `src/app.lua`, `src/scene_manager.lua` | Callbacks, stack |
| `src/scenes/{boot,main_menu,match_setup,play,pause,game_over}.lua` | Flow |
| `src/game/{match_config,map_seed,roster,session,turn_state}.lua` | Rules + seed |
| `src/data/{constants,weapons}.lua` | Tunables |
| `src/entities/{mole,projectile,grenade}.lua` | Entities |
| `src/systems/{world_update,weapons,explosions,turn_resolver,vfx}.lua` | Simulation |
| `src/world/*`, `src/world/mapgen/*` | Terrain + generation |
| `src/input/*` | Input |
| `src/ui/*`, `src/ui/hud/play_hud.lua` | UI |
| `src/audio/sfx.lua` | SFX |
| `README.md`, `CODING_NOTES.md` | Player-facing + implementer notes |

---

## components (responsibilities)

| Concept | Primary home |
|---------|----------------|
| MatchConfig | `game/match_config` |
| Per-round seed | `game/map_seed` |
| Session totals | `game/session` |
| Turn / weapons selection | `game/turn_state` |
| Rosters | `game/roster` |
| Blast + terrain carve | `systems/explosions` |
| Fire weapons | `systems/weapons` |
| Frame integration | `systems/world_update`, `turn_resolver` |
| Proc terrain | `world/mapgen/init` |

---

## dependencies and technology choices

- **LÖVE 11.4**, Lua 5.1 (embedded).  
- **No external physics library** required if custom collision remains sufficient.  
- **Procedural SFX** in `audio/sfx.lua` (optional external assets later).

---

## considerations

- **`MAX_DT`** cap (already in `app`).  
- **Joystick hot-plug** — `devices.refresh_joysticks`.  
- **Per-round mapgen** — `terrain:rebuildImageData` cost; brief hitch acceptable or show interstitial.  
- **Turn timer** — if `turn_time_limit` set, document auto-fire / skip in UX.  
- **Dead active mole during aim** — README: reassign or end round; must not deadlock turn FSM.

---

## scenesOrScreens

`boot` → `main_menu` → `match_setup` → `play` (with round/match overlays) ↔ `pause` → `game_over` → rematch or `main_menu`.

---

## assetStructure

- **Current:** synthesized audio in `src/audio/sfx.lua` (no bundled `assets/audio` required for SFX).  
- **Optional:** `assets/sprites/`, `assets/fonts/` for future art passes; reference from `ui/theme` / scenes.

---

## persistence

- **Session stats** in RAM (`session.lua`) for “since launching.”  
- **Rematch** uses `session.last_match_config` copy.  
- **Optional later:** `love.filesystem` for settings or high scores — product call.

---

## implementationOrder (maintenance / verification)

1. **Regression pass** — per-round `generate` + `map_seed.derive` on every round start (including round 1 and post-rematch).  
2. **Rotation** — player start + `rotate_order` each round; no stale terrain between rounds.  
3. **Session semantics** — UI strings: wins vs matches played (Session stats definition).  
4. **Input matrix** — `shared_kb` vs `dual_gamepad` per README; active-player gating.  
5. **Combat edge cases** — direct mole hits, friendly fire flag, wipe while aiming.  
6. **Polish** — wind feel, VFX/SFX triggers, spawn fairness (`spawns.lua`).

---

## Pseudocode (behavioural)

**Round setup:**

```
seed = map_seed.derive(match_config.procedural_seed, round_index)
world_bundle = world.mapgen.init.generate(match_config, seed)
starting_player = ((round_index - 1) % 2) + 1
for each team: team.mole_order = roster.rotate_order(team.mole_order)
-- respawn moles at map spawns, full HP
turn_state.start_match_turn(ts, teams, starting_player, slot_team1, slot_team2)
```

**Match end:**

```
session:bump_match_win(winner_player_index)
```

---

## Handoff notes

- **BigBoss:** Rockets, grenades, rotations, 2P local, teams of five, proc maps, match variables, flexible input — mapped to concrete `src/` modules above.  
- **Merged DESIGN.md:** This file’s **Session stats definition**, **Map regeneration cadence**, and **`map_seed.derive`** linkage are authoritative for mechanics coders.  
- **UX:** Win vs matches-played labeling; interstitial copy for round start and seed lock behaviour.
