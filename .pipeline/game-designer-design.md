# Game Designer — Moles (Worms-style) Design

**Agent:** `game-designer`  
**Target:** LÖVE **11.4**  
**Codebase note:** Repository currently has no `main.lua` / `src/` yet (see `.pipeline/architecture-brief.md`). This spec is the mechanics and rules blueprint; **LÖVE Architect** should wire modules; **LÖVE UX** owns visual polish and HUD layout.

---

## requirementsChecklist

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

## targetLoveVersion

`11.4`

---

## mechanics

### High-level pitch

Turn-based **2D artillery** on a **destructible procedural map**. Two human players each command a **team of 5 moles**. One **active mole** per team per turn (classic Worms cadence). Players **aim**, set **shot power**, choose **weapons** (minimum: **rocket launcher**, **grenade**), and fire. **Terrain** is removed by blasts; moles can **fall**; **HP** tracks damage. A **round** ends when one side has no living moles; a **match** is a configurable **first-to-N rounds** (default e.g. best of 3). **Session scores** count round or match wins since launch.

### Team dynamics

- **Ownership:** Player A → Team A (moles A1–A5); Player B → Team B (B1–B5).
- **Turn model:** Strictly alternating **teams** (not alternating every mole on same team in one round—keep one active mole per side per turn unless you add “sudden death” rules later).
- **Information:** Both players see the full map (single shared view is fine for local 2P; split camera optional UX).
- **Win round:** All enemy moles eliminated (HP ≤ 0 or out-of-bounds if implemented).
- **Win match:** Reach target wins (session counter increments).

### Player & mole rotation (each round)

- **Player rotation (meta):** After each round, swap **priority** for UI flow: who confirms **match variables**, who picks **first turn**, or simply swap **who fires first** next round. Simplest rule: `startingPlayerIndex = (roundIndex) % 2` so P1 starts odd rounds, P2 even (or inverse—document one rule in code comments).
- **Mole rotation (roster):** Maintain a **cursor per team** into the list of 5 moles. At round start, **advance cursor by 1 (mod 5)** so the “first mole up” cycles. When a mole dies, **remove from active turn queue**; cursor skips dead entries. New round: living moles only; cursor still advances for variety.

### Weapons (core set)

| Weapon          | Behaviour summary |
|-----------------|-------------------|
| **Rocket launcher** | Straight or lightly arcing shot (choose one and stay consistent); **high speed**; **on impact**: spawn **explosion** (radius R_r), **terrain carve**, **impulse** to moles, **direct + splash damage** by distance. |
| **Grenade**     | **Arc** under gravity; **fuse** T seconds (match variable or fixed); **on timeout**: same explosion model as rocket (reuse one `explosion()` primitive). Optional: **tap fuse** or **variable throw power**—if scope tight, fixed fuse + aim + power only. |

Shared rules: **one shot** (or one “use”) ends the active mole’s turn unless a future item says otherwise; **backblast** optional (off by default).

### Procedural map

- **2D destructible heightfield** or **bitmap terrain** (Architect chooses). Designer requirements: **irregular surface**, **overhangs optional**, **minimum playable area**, **spawn platforms** for both teams (left/right bias or labeled spawn zones). **Seed** optional for reproducibility in debug.
- **Hazards (optional phase 2):** water = instant kill or damage per tick—omit v1 unless time permits.

### Damage, HP, and death

- **Mole HP:** Integer; **match variable** default e.g. 100; clamp to sensible min/max in UI.
- **Damage:** Splash falls off with distance; **direct hit** bonus for rocket on body.
- **Knockback:** Velocity impulse from explosion center; **fall damage** when vertical velocity or fall height exceeds threshold (tunable).
- **Death:** HP ≤ 0 or OOB; remove from turn queue; ragdoll/visual is UX.

### Wind (recommended for Worms feel)

- **Scalar wind** along +x / −x affecting projectile acceleration (rockets light effect, grenades medium). Expose as **match variable** or random per round.

### Match variables (pre-match lobby)

Minimum:

- **Mole health** (starting HP).
Recommended same screen:
- **Match length** (rounds to win).
- **Turn timer** (optional clock).
- **Wind strength** (0 = off).
- **Grenade fuse** (if not fixed).

All variables require **both players’ confirm** or **host-style P1 confirm**—pick one flow (recommend: **both press confirm**).

### Session scoring

- On **match end**: increment winner’s **sessionWins**.
- Display on **main menu** and **post-match** summary.
- **Reset** only on app quit (unless UX adds “reset scores” button—optional).

---

## controls

Design for **two locals** with **either** shared KB+M **or** two gamepads. Avoid assuming mouse for both if one player is gamepad-only.

### Actions (per player)

- **Move mole** (small left/right step along terrain, Worms-style)—limited **move budget** per turn (e.g. finite “energy” or N seconds).
- **Aim:** adjust **angle** (keyboard: up/down; gamepad: stick).
- **Power:** hold/charge or separate axis (keyboard: hold key increases power; gamepad: right trigger or second stick).
- **Fire:** confirm shot.
- **Weapon cycle:** switch between **rocket** / **grenade** (and future weapons).
- **Jump** (optional): short hop if Architect implements discrete cells; else omit v1.

### Suggested default bindings (implement as data table, remappable later)

**Player 1 — keyboard**

| Action        | Keys (example)   |
|---------------|------------------|
| Walk left/right | `A` / `D`      |
| Aim up/down   | `W` / `S`        |
| Increase power | `Shift` (hold) or `E` / `Q` |
| Fire          | `Space`          |
| Weapon next   | `1` / `2` or `[` / `]` |

**Player 2 — keyboard (shared keyboard)**

| Action        | Keys (example)   |
|---------------|------------------|
| Walk          | Numpad `4` / `6` or arrows |
| Aim           | Numpad `8` / `5` or `I`/`K` |
| Power         | Numpad `+` hold or `O`/`L` |
| Fire          | Numpad `Enter` or `Right Ctrl` |
| Weapon        | `-` / `+` on numpad |

**Mouse (optional shared):** **click-drag** aim vector from mole; **scroll** power; **LMB** fire—**only when “active device” includes mouse** for that player to avoid stealing input.

**Gamepads:** Player 1 → first detected joystick index 1, Player 2 → index 2 (or assignment UI). **Left stick** move, **right stick** aim (or D-pad aim), **RT** power, **A** fire, **LB/RB** weapon.

### Input routing

- Maintain `PlayerInputProfile` = `{ deviceKind, deviceId, bindings }`.
- Each frame, **only the active team’s active mole** accepts **that player’s** profile.
- **love.keypressed**, **love.gamepadpressed**, **love.mousepressed** dispatch to a central `InputSystem` that writes to **intent** structs (`aimDelta`, `powerDelta`, `firePressed`, etc.) consumed in `love.update`.

---

## gameLoop

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

**Update order (recommended):** input → turn FSM → mole movement integration → projectiles → explosions/deferred terrain updates → damage/knockback → fall damage → death/round check → camera (UX).

**Draw order:** parallax/background → terrain → moles → projectiles/particles → HUD (UX).

---

## fileStructure (game-relevant hints only)

Do not treat this as the full repo tree—**Architect** owns `src/`. Gameplay code should live in modules such as:

- `src/systems/turn.lua` — whose turn, mole selection, rotation application.
- `src/systems/weapons.lua` — rocket, grenade definitions; shared explosion.
- `src/systems/projectiles.lua` — integration, collision with terrain/moles.
- `src/world/terrain.lua` — procedural gen + carve.
- `src/entities/mole.lua` — HP, pose, physics state.
- `src/match/session.lua` — session wins, match variables snapshot.

**Assets (conceptual):** `assets/sprites/moles/`, `assets/audio/sfx/explosion.ogg`, `assets/fonts/` — naming convention: `teamA_mole_01.png`, etc.

---

## components (responsibilities)

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

## dependencies and technology choices

- **LÖVE 11.4** — cross-platform input, graphics, audio; familiar loop.
- **Lua** modules — keep gameplay data-driven (`weapons.lua` as tables).
- **Collision:** grid/bitmask terrain vs circle/AABB moles (Architect). No external physics engine required for v1 if custom integration is simpler.
- **No implementation here** — if Architect adds `bump.lua` or similar, mechanics stay in terms of “hit radius” and “impulse.”

---

## considerations

- **Determinism:** Fixed `dt` cap + documented RNG seed for proc-gen aids debugging.
- **Controller hot-plug:** On `love.joystickadded/removed`, pause assignment or show “press A to join” (UX).
- **Same-keyboard:** Ensure **no key overlap** between P1 and P2 bindings; document in README.
- **Turn timer:** If enabled, auto-fire at low power or skip turn—state in TurnController.
- **Performance:** Explosion terrain ops can spike—batch mask updates or limit carve radius per frame (implementation note for coder).

---

## scenesOrScreens

- Main menu  
- Match setup (variables + devices)  
- Play (core loop)  
- Pause (optional)  
- Round interstitial (short “Round N — Player X starts”)  
- Match over  

Transitions: Menu → Setup → Play ↔ Pause → Match over → Menu or Setup (rematch).

---

## assetStructure

- `assets/sprites/` — moles, terrain tiles, projectiles, UI chrome (UX)  
- `assets/audio/sfx/` — fire, boom, walk, UI blip  
- `assets/audio/music/` — menu + battle (optional)  
- `assets/fonts/` — one display font, one monospace for debug (optional)  

Naming: lowercase, underscores; version by suffix if needed (`explosion_01.png`).

---

## persistence

- **v1:** Session scores **in RAM only** (requirement: “since launching”).
- **Optional later:** `love.filesystem` JSON for high scores or last-used match variables—out of scope unless product expands.

---

## implementationOrder (for Coding Agent)

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

## Pseudocode snippets (behavioural, not production Lua)

**Explosion primitive (shared):**

```
function explode(world, center, radius, damageMax, knockbackMax):
  terrain.carveCircle(center, radius)
  for each mole in world.moles:
    d = distance(mole.pos, center)
    if d < radius:
      mole.hp -= lerp(damageMax, 0, d / radius)
      mole.vel += radialImpulse(center, mole.pos, knockbackMax)
```

**Round start rotation:**

```
for each team in teams:
  team.moleCursor = (team.moleCursor + 1) % 5
startingPlayer = (roundIndex - 1) % 2
```

**Turn end:**

```
switchActiveTeam()
activeMole = nextLivingMole(activeTeam, team.moleCursor)
```

---

## Handoff notes

- **LÖVE UX:** All timers, meters, weapon icons, and “beautiful styling” consume **exposed game state** (`activeMole`, `aimAngle`, `power01`, `wind`, `round`, `sessionWins`).
- **LÖVE Architect:** Implements modules and dependency direction; this doc defines **rules and data** only.
- **BigBoss alignment:** Rocket launcher, grenades, **player rotation**, **mole rotation**, **2P local**, **teams of 5**, **proc maps**, **match variables**, **session scoring**, and **flexible input** are all specified above.
