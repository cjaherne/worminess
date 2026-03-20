# Game Designer — Moles (Worms-like) Design

**Audience:** merge into `DESIGN.md` + Coding Agent blueprint  
**Framework:** LÖVE **11.4**  
**Repo baseline (implemented):** `REQUIREMENTS.md` (R1–R11) · `CODING_NOTES.md` (UX/designer drift + env notes) · `ASSETS.md` (sprite scale manifest) · `README.md` (player-facing controls). Entry `main.lua` → `src/app.lua` (scene stack). **Sim:** `src/sim/world.lua`, `mole.lua`, `turn_state.lua`, `terrain.lua`, `terrain_gen.lua`, `physics.lua`, `damage.lua`, `src/sim/weapons/{registry,rocket,grenade}.lua`. **Flow:** `src/scenes/{menu,match_setup,play,pause,match_end}.lua`. **Input:** `src/input/{input_manager,keyboard_mouse,gamepad}.lua`. **Presentation:** `src/render/{camera,terrain_draw,mole_draw}.lua`, `src/ui/hud.lua`, `src/audio/sfx.lua`. **Data:** `src/data/match_settings.lua`, `session_scores.lua` · **Tuning:** `src/config.defaults.lua`. Merged umbrella spec: root `DESIGN.md`.

---

## requirementsChecklist

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
- [ ] **R-rotate-moles**: **Moles rotate** per roster slot: when a player **ends their turn**, **that player’s** slot pointer advances to the **next living mole** in fixed order 1..5 (ring, skip dead) — symmetric same-slot pacing with the opponent; see **Turn model** pseudocode.
- [ ] **R-match-vars**: **Match options** exposed before play (at minimum **mole max health / starting health**; room for more toggles without contradicting scope).
- [ ] **R-input-shared-kbm**: **Two players on one keyboard + mouse**: viable control scheme with clear ownership of input per active turn.
- [ ] **R-input-dual-pad**: **Two players with separate controllers** (gamepads): each player mapped to their own device where possible.
- [ ] **R-bigboss-teams**: Design supports **team dynamics**: two sides, friendly-fire policy, win when opposing team has no living moles, clarity of “which side am I on.”
- [ ] **R-bigboss-rotation**: Explicit **player + mole rotation** model documented and implemented (see **Turn model** below).

---

## targetLoveVersion

`11.4` — match wiki/API stability used across the pipeline.

---

## mechanics

### High-level pitch

**Moles** is a **2D side-view**, **turn-based** artillery/tactics game. Two human players each command **5 moles** on **destructible procedural terrain**. On a turn, the active player moves and fires **one weapon** (from a small loadout including **rocket launcher** and **grenade**). The match ends when one side has **no living moles**. **Session score** records how many **match wins** each player (or each team slot) has earned **since the executable started**.

### Camera / world

- **Side view** (Worms-like): gravity pulls downward; terrain is a bitmap or polygon mask treated as solid for collisions.
- **Scale**: moles readable at target resolution (~32–48 px tall baseline suggestion for art; coder scales consistently).

### Turn model (players + moles rotation)

**Normative rule:** The **`on_end_turn` / `advance_mole_index` pseudocode block below is authoritative** for turn and mole rotation. Any prose in other pipeline docs (e.g. LÖVE Architect) that implies advancing the **opponent’s** roster when a turn ends, or advancing a roster when a turn **starts**, is **out of date** — implement the pseudocode. **Where merged architecture prose (e.g. `DESIGN.md`, LÖVE Architect) disagrees with this Turn Model, this pseudocode overrides it for player/mole rotation; align `src/sim/turn_state.lua` (and callers) to the pseudocode, not the conflicting paragraph.**

**One-line precedence:** *Turn Model pseudocode overrides conflicting architecture prose whenever they disagree on player/mole rotation.*

**Code alignment:** `src/sim/turn_state.lua` is written to this model (`advance_after_turn` / `end_turn`); `world.lua` should keep calling `sync_slots_to_living` after damage/death so the active slot never points at a dead mole mid-turn (see `CODING_NOTES.md`).

**Product intent — symmetric same-slot progression:** Each human alternates as **turn owner**. Each player’s **roster slot index** (1..5) advances **only when that player ends their own turn**, so after a full **player–player cycle** (P1 acts, then P2 acts), **both** teams have stepped forward one **living** mole in lockstep when no asymmetrical deaths have occurred — i.e. both sides stay on the **same slot number** relative to their rosters (both on “slot 2” for their next respective turns, etc.). Deaths desync indices by skipping dead moles per `advance_mole_index`.

1. **Turn owner**: Exactly one **human player** is active at a time (`PlayerId` 1 or 2).
2. **Active mole**: The active player controls **one mole** for the entire turn — the **current index** in that player’s roster (1..5).
3. **End of turn**: Triggered explicitly by player (**“End turn”** action) or optionally by **timeout** if match options include turn timer (recommended as optional match var, default off for first implementation).
4. **Handoff to opponent**: When the active player ends their turn, **only the ended player’s** roster pointer is advanced (see pseudocode); the opponent’s `mole_index` **does not change** at that moment. Turn ownership passes to the other player.
5. **Skipping dead moles**: `advance_mole_index` walks the ring 1..5 until a **living** mole is selected or the team is eliminated (win check should run before offering a turn to a dead team).
6. **First turn of match**: Menu or random determines **who goes first**; each team’s `mole_index` starts at **first living mole** (typically slot 1). **Do not** call `advance_mole_index` before the first turn’s gameplay begins.

*Pseudocode (normative — design intent, not drop-in code):*

```
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

**Clarification for Coding Agent:** Advance **only** the **player who ended the turn**; switching `turn_player` does **not** by itself advance anyone’s roster. This yields **symmetric same-slot** pacing versus classic “only one team’s worm advances per global step” rulesets — it matches **R8** (“rotating players and moles each round”) as written for this product.

### Movement & aiming

- **Movement**: Walk left/right on terrain surface; **jump** with limited air control (Worms-like). No infinite jetpack unless added later.
- **Player rotation (facing)**: Each mole has **facing** `left` | `right`. Walking updates facing. **Aiming** is a separate **aim angle** (e.g. radians or degrees) relative to facing or world-up — recommend **world-space aim cone** (e.g. −150° to −30° from horizontal) so rocket/grenade arcs read clearly. **Rotate aim** with dedicated inputs (keyboard or stick); mouse, when allowed, sets aim direction from mole to cursor.
- **Weapon inventory**: Minimal for V1: **Rocket**, **Grenade**, **maybe Skip / utility later**. Player cycles weapon with a **weapon next/prev** action (or fixed slots).

### Weapons (behavioral spec)

| Weapon        | Trajectory | Detonation | Terrain | Damage radius | Notes |
|---------------|------------|------------|---------|---------------|-------|
| Rocket launcher | Straight or mild gravity-affected raycast/segment motion | On impact with terrain or mole | Strong carve | Medium | Fast, thin **silhouette**; optional short **trail** for readability |
| Grenade       | Parabolic under gravity | **Fuse timer** (e.g. 3–5 s) or **impact** (choose one default: **timer** is classic); optional low bounce | Medium carve | Medium-large | Round **silhouette**; **blinking fuse** or color pulse for telegraph |

**Tuning source of truth (shipped):** numeric weapon behavior (`rocket_speed`, `rocket_gravity_mul`, `rocket_ray_steps`, `grenade_fuse`, `grenade_bounce`, `grenade_unstick_px`, blast radii, damage) lives in **`src/config.defaults.lua`** under `weapon` — keep designer-facing tables in sync when changing defaults.

- **Knockback**: Explosions apply impulse; moles can fall or get **dunked** in water/death plane if implemented (optional V1: instant death below map).
- **Friendly fire**: **Match option** — default **OFF** for accessibility; when ON, own team can be damaged.

### Win / lose

- **Elimination**: When a player has **zero living moles**, the other player **wins the match**.
- **Draw**: Rare (simultaneous last kill) — resolve with **tie** or **sudden death** round (design: **tie** increments neither score unless UX prefers replay).

### Session scoring (since launch)

- On match end: increment wins via **`src/data/session_scores.lua`** (`record_match_outcome` from `app.quit_match_to_results`).
- **Displayed** in HUD chips + match end (`src/ui/hud.lua`, `match_end.lua`); draws tracked if implemented in session module.
- **Not** required to persist across quit (per R6 wording).

### Match variables (minimum set)

| Variable | Type | Notes |
|----------|------|-------|
| `mole_health` | int | Starting / max HP for all moles in match |
| `first_player` | P1 / P2 / random | Who takes first turn |
| `friendly_fire` | bool | Default false |
| `turn_time_limit` | float or off | Optional |
| `map_seed` | int \| nil | Optional override for proc gen (`nil` = random each match) |
| `wind` | `"off"` \| `"low"` \| `"med"` \| `"high"` | Shipped in **`src/data/match_settings.lua`**; forces use `config.defaults.wind_force` |
| `input_mode` | `"shared_kb"` \| `"dual_gamepad"` | Match setup → routing in **`input_manager`** |

**Shipped constraint:** `moles_per_team` is fixed at **5** for v1 (`match_settings.validate`).

Additional tuning (global, not per-match UI): explosion scale, jump power — adjust in **`src/config.defaults.lua`** if needed.

### Team dynamics

- **Teams**: Player 1 = **Team A** (palette 1), Player 2 = **Team B** (palette 2). Moles spawn on **opposite halves** or **scattered** with clear team color **hats/vests/scarves** (art).
- **No AI teammates** in scope: exactly two humans, five moles each.

---

## controls

### Actions (semantic)

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

### Two players — **one keyboard + mouse**

**Policy:** Only the **turn owner** receives **mouse** aim + **LMB** fire; the inactive player’s mouse does not steer shots (`world` / input consume flags gate this).

**Canonical layout (as implemented — duplicate of `README.md` for blueprint):**

| Action | Player 1 | Player 2 |
|--------|----------|----------|
| Move | `A` / `D` | Left / Right |
| Jump | `W` or `Space` | `Up` or `Right Shift` |
| Aim − / + | `Q` / `E` | `[` / `]` |
| Power − / + | `Z` / `X` | `I` / `K` *(chosen to avoid clash with P2 jump on `Up` — see `CODING_NOTES.md`)* |
| Fire | `F` and/or **LMB** (when P1 turn) | `;` / `Enter` / numpad Enter / `Right Ctrl` and/or **LMB** (when P2 turn) |
| Weapon pick | `1` rocket · `2` grenade · `Tab` cycle | `,` rocket · `.` grenade · `-` / `=` cycle |
| End turn | `G` | `Backspace` or `\` |

*Implementation:* `src/input/keyboard_mouse.lua` (`build_intents`, `on_keypressed`); edge cases (e.g. `Enter` as P2 fire vs future UI) documented in **`CODING_NOTES.md`**.

### Two players — **separate gamepads**

- **Assignment:** Joystick order from `love.joystick.getJoysticks()` — first = P1, second = P2; **`match_setup`** warns if `dual_gamepad` and fewer than two devices.
- **Canonical (as implemented):** Left stick move · **A** jump · **right stick** aim · **triggers** power · **B** fire · **LB/RB** weapon · **Y** end turn · **Start** pause. Menu navigation on **first** pad: D-pad / stick + **A** confirm + **B** back (`util/gamepad_menu.lua`).
- **Designer note:** Some merged UX copy still mentions **RT** as fire; shipped game uses **B** for fire and triggers for **power** — treat **`CODING_NOTES.md`** + `gamepad.lua` as authoritative for gamepad.

### LÖVE callback mapping (shipped wiring)

- `main.lua` forwards to **`src/app.lua`** (`love.load` / `update` / `draw` / input / joystick / `resize`).
- Digital keys: `app` → active scene + **`src/input/input_manager.lua`** → `keyboard_mouse.on_keypressed` / `gamepad.lua`.
- Mouse: only when play scene + world considers turn owner (`consume_mouse_fire` pattern).
- Text input: `love.textinput` → `app.textinput` (e.g. seed entry in setup).

---

## gameLoop

### States (state machine)

**Implemented scene modules** (`app.push` / `app.goto` / `app.pop`): **`menu`** → **`match_setup`** → **`play`**; **`pause`** overlays play; **`match_end`** after win (`app.quit_match_to_results` records **`session_scores`** then pushes results). No separate boot splash unless added later.

1. **Menu** — `src/scenes/menu.lua`
2. **Match setup** — `src/scenes/match_setup.lua` (health, first player, wind, timer, seed, input mode)
3. **Playing** — `src/scenes/play.lua` owns `World` lifecycle; turn toast on handoff (UX §3.6 style)
4. **Pause** — `src/scenes/pause.lua` overlay
5. **Match over** — `src/scenes/match_end.lua` (rematch → setup, or title)

**Match =** one proc map + fight until elimination; **session** can chain many matches; scores in **`session_scores.lua`** only for process lifetime (R6).

### Update / draw flow (per frame)

```
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

**Turn phases (recommended):** `moving` → `aiming` → `firing` → `watching` (projectiles/explosions resolve) → auto-return to `moving` or prompt **End turn**. Simpler V1: single phase **combined** move+aim until Fire or End turn — still document projectile resolution as **watching**.

---

## fileStructure

*Game-designer map to **shipped** layout — extend here when adding mechanics, not a second architecture doc.*

| Game concern | Primary modules |
|--------------|-----------------|
| App / scenes | `src/app.lua`, `src/scenes/*.lua` |
| Turn order + roster | `src/sim/turn_state.lua` (normative rotation) |
| World step + combat | `src/sim/world.lua`, `damage.lua`, `physics.lua` |
| Terrain + proc gen | `terrain.lua`, `terrain_gen.lua` |
| Moles | `mole.lua`, `render/mole_draw.lua` |
| Weapons | `sim/weapons/*.lua` + tuning in `config.defaults.lua` |
| Match / session data | `data/match_settings.lua`, `data/session_scores.lua` |
| Input routing | `input/input_manager.lua`, `keyboard_mouse.lua`, `gamepad.lua` |
| HUD / UX chrome | `ui/hud.lua` (layout owned by UX spec; mechanics feed it turn + HP + fuse) |
| Audio feedback | `audio/sfx.lua` (procedural until `assets/audio` added) |

**Dependency direction:** scenes orchestrate world; sim modules do not require scenes; weapons registry stays data-driven from defaults + world.

---

## considerations

- **Determinism:** Proc gen + session score + turn order should use explicit seeds where useful for **replays / QA**.
- **Controller detection:** On menu, show **which device** is assigned to P1/P2; allow **reassign**.
- **Keyboard conflict:** Shared-keyboard layout must avoid **same key** for both players’ primary actions.
- **Performance:** Destructible terrain updates are costly — Architect may choose mask + batch redraw; designer constraint: **explosion count** per turn bounded by weapon types.
- **Readability:** Rockets vs grenades must differ by **shape, color, motion, and audio** (see below).

---

## scenesOrScreens

| Scene | Entry | Exit |
|-------|-------|------|
| Main menu | Boot | Start match → setup; Quit |
| Match setup | Menu | Play |
| Play | Setup / rematch | Match over when win; Pause |
| Pause | Play | Resume Play or Menu |
| Match over | Play | Rematch (new proc map) or Menu |

---

## assetStructure

**Shipped raster (see `ASSETS.md` for resolution + draw-scale guidance):**

```
assets/sprites/
  mole_team_{a,b}_{idle,aim,walk_1,walk_2}.png
  rocket.png
  grenade.png
  ui_icon_rocket.png
  ui_icon_grenade.png
  ui_icon_wind.png
```

Terrain is **generated** into the sim (`terrain_gen` / mask), not a tileset PNG in v1.

**Optional / gaps:** `assets/audio/*`, `assets/fonts/*`, hurt/death mole frames, explosion sheets — listed as follow-ups in **`ASSETS.md`**. V1 uses **`src/audio/sfx.lua`** procedural blips.

**Animation states (minimum, shipped):** idle, walk (2 frames), aim; hurt/death may remain visual hacks until art lands.

---

## persistence

- **Session score (R6):** Match wins since app launch — implement via existing module **`src/data/session_scores.lua`** (or successor API); **no disk persistence** required for R6.
- **Match options:** Tune from **`src/data/match_settings.lua`** / setup UI; align field names with `MatchRules` / architect tables.
- **Optional later:** `love.filesystem` for settings (volume, key binds) — **out of scope** for R6 unless UX expands.

---

## implementationOrder

**Status:** Core game is **implemented** per upstream `lua-coding` passes. Use this as **regression / feature order** when touching mechanics:

1. **`turn_state` + `world`** — verify end-turn advance + `sync_slots_to_living` after damage (R8).
2. **Weapons** — rocket/grenade vs `config.defaults` tuning; wind + proc seed consistency.
3. **Input** — shared KB+M gating + gamepad parity; check `CODING_NOTES.md` when changing bindings.
4. **Match setup / HUD** — new match vars must flow `match_settings` → `World` / HUD.
5. **Polish** — replace procedural SFX, add missing sprites, optional `round_end` beat (`CODING_NOTES.md` suggestions).

---

## Visual gameplay (in-world)

- **Silhouette & scale:** Moles **chunky**, **team-colored accessory** visible at all times; weapons **readable** when equipped (small launcher on back or in hands).
- **Projectiles:** Rocket = **elongated**, fast, **orange/red trail**; Grenade = **round**, **arc**, **pulsing fuse** pixel or timer ring.
- **Animation hooks:** States listed under **assetStructure** drive which sprite set is shown.

---

## Notes for Coding Agent

- Treat `REQUIREMENTS.md` R1–R11 as **acceptance criteria**; trace status in **`CODING_NOTES.md`**.
- **Turn/mole rotation:** **Normative pseudocode** in **Turn model** wins over any conflicting **`DESIGN.md` Part B/C** prose; **`src/sim/turn_state.lua`** already encodes `advance_after_turn` + `end_turn` accordingly.
- **Player rotation** = alternating **human** turns; **mole rotation** = ended player’s **slot** advances once per **completed** turn (skip dead).
- **Controls:** Player-facing list = **`README.md`**; scancodes = **`keyboard_mouse.lua`** / **`gamepad.lua`**; document binding changes in **`CODING_NOTES.md`** if UX and Part A diverge.
- **Mouse:** Turn-owner-only aim/fire in play; watch **`Enter`** / **`Return`** overlap if in-match UI grows.
- Weapon numbers: **`src/config.defaults.lua`** (`weapon` + `wind_force`); avoid duplicating magic constants in weapon modules.
- **Scope:** No **network multiplayer**.

---

*End of game-designer design document.*
