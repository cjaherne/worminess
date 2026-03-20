# Game Designer — Moles (Worms-like) Design

**Audience:** merge into `DESIGN.md` + Coding Agent blueprint  
**Framework:** LÖVE **11.4**  
**Repo baseline:** `REQUIREMENTS.md` (R1–R11); entry via `main.lua` → `app`; data `src/data/match_settings.lua`, `src/data/session_scores.lua` (R6); sim layer `src/sim/turn_state.lua`, `terrain.lua`, `terrain_gen.lua`, `physics.lua`, `damage.lua`; tuning `src/config.defaults.lua`. Full merged spec: root `DESIGN.md`.

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
- [ ] **R-rotate-moles**: **Moles rotate** as the active character: when a player’s turn comes around again, control advances to the **next living mole** in a fixed team order (dead moles skipped).
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

- **Knockback**: Explosions apply impulse; moles can fall or get **dunked** in water/death plane if implemented (optional V1: instant death below map).
- **Friendly fire**: **Match option** — default **OFF** for accessibility; when ON, own team can be damaged.

### Win / lose

- **Elimination**: When a player has **zero living moles**, the other player **wins the match**.
- **Draw**: Rare (simultaneous last kill) — resolve with **tie** or **sudden death** round (design: **tie** increments neither score unless UX prefers replay).

### Session scoring (since launch)

- On match end: increment **`wins[player]`** for winner.
- **Displayed** between matches and on a **session stats** area (exact HUD layout → UX agent).
- **Not** required to persist across quit (per R6 wording).

### Match variables (minimum set)

| Variable | Type | Notes |
|----------|------|-------|
| `mole_health` | int | Starting / max HP for all moles in match |
| `first_player` | P1 / P2 / random | Who takes first turn |
| `friendly_fire` | bool | Default false |
| `turn_time_limit` | float or off | Optional |
| `map_seed` | int | Optional override for proc gen |

Additional vars (nice-to-have, not required by R1–R11): wind, explosion radius scale, jump power.

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

### Two players — **separate gamepads**

- **Player 1** → first detected joystick or assignment from menu; **Player 2** → second.
- **Suggested:** Left stick or D-pad move; `A`/`X` jump; right stick **aim** (preferred) or bumpers for aim; `RT` fire; `LB`/`RB` weapon; `Y` end turn.
- **Hotseat rule:** Ignore non-active pad except **pause** if both can pause — UX decision.

### LÖVE callback mapping (where logic lives conceptually)

- `love.keypressed` / `love.keyreleased` → buffer digital state.
- `love.mousemoved` / `love.mousepressed` → only if `mouse_owner == turn_player` and match uses mouse aim.
- `love.joystickpressed` / axis polling in `love.update` → per-player slots.
- **Single module** conceptually responsible for **InputRouter(player, turn, scheme)** — actual file path is Architect’s call.

---

## gameLoop

### States (state machine)

1. **Boot / splash** (optional)
2. **Main menu** — new match, match options, input test, quit
3. **Match setup** — confirm seed, health, devices
4. **Playing** — turn-based combat
5. **Round interstitial** (optional) — only if multi-round match; REQ implies **match = one terrain + fight**; session is multiple matches
6. **Match over** — show winner, update session score, rematch or menu
7. **Pause** (overlay on Playing)

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

*Game-designer hints only — Architect owns full tree.*

| Area | Suggested responsibility |
|------|---------------------------|
| `main.lua` | Bootstrap, require scenes, delegate `love.*` |
| `conf.lua` | Window, vsync |
| Scene modules (e.g. `src/scenes/*.lua`) | Menu, play, gameover |
| World/combat modules | Terrain, mole entities, projectiles, explosions, turn controller |
| `src/data/` or inline | Weapon defs (damage, radius, fuse, sprite ids) |
| Input | Dedicated router used by play scene |

**Dependency direction:** scenes orchestrate; entities do not require scenes; weapons data tables do not require entities.

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

## persistence

- **Session score (R6):** Match wins since app launch — implement via existing module **`src/data/session_scores.lua`** (or successor API); **no disk persistence** required for R6.
- **Match options:** Tune from **`src/data/match_settings.lua`** / setup UI; align field names with `MatchRules` / architect tables.
- **Optional later:** `love.filesystem` for settings (volume, key binds) — **out of scope** for R6 unless UX expands.

---

## implementationOrder

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

## Visual gameplay (in-world)

- **Silhouette & scale:** Moles **chunky**, **team-colored accessory** visible at all times; weapons **readable** when equipped (small launcher on back or in hands).
- **Projectiles:** Rocket = **elongated**, fast, **orange/red trail**; Grenade = **round**, **arc**, **pulsing fuse** pixel or timer ring.
- **Animation hooks:** States listed under **assetStructure** drive which sprite set is shown.

---

## Notes for Coding Agent

- Treat `REQUIREMENTS.md` R1–R11 as **acceptance criteria**; this doc refines **behavior** only.
- **Turn/mole rotation:** Follow the **normative pseudocode** in **Turn model**; **symmetric same-slot** progression is intentional. **`turn_state.lua`** (or equivalent) must not advance the inactive player’s roster on turn end.
- **Player rotation** = strict **alternating turns** between humans; **mole rotation** = **that player’s** roster index advances **once per their own completed turn** (skip dead).
- **Mouse** in shared mode: **gate** all mouse handlers on `active_player == mouse_bound_player` or “only active turn.”
- Keep weapon parameters in **data tables** so tuning does not scatter magic numbers.
- Do not implement **network multiplayer** in this design scope.

---

*End of game-designer design document.*
