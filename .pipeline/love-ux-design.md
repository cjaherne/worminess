# LÖVE UX Design — Moles (Worms-style clone)

**Agent:** `love-ux`  
**Scope:** Screens, HUD, input affordances, resolution/scaling, focus/navigation — not combat math or physics (Game Designer / LÖVE Architect).  
**Traceability:** Maps to `REQUIREMENTS.md` R1–R11 and the checklist in root **`DESIGN.md`**.  
**Merged-design note:** This file is the **complete** UX blueprint (flows, wireframes, safe-area policy, HUD clusters, pause modal, match results, default input tables). The orchestrator should fold it into **`DESIGN.md`** without dropping sections.

---

## 0. Codebase baseline (build on these files)

| File | UX relevance |
|------|----------------|
| **`conf.lua`** | Window **1280×720**, **min** **960×540**, resizable, vsync, identity `moles-wormslike`, title `Moles`, **LÖVE 11.4** — design anchors in §2 match this exactly. |
| **`main.lua`** | Thin callbacks; runtime will delegate to **`src/app.lua`** (per `.pipeline/love-architect-design.md`; not present yet). UI scenes live under architect’s `src/scenes/` + `src/ui/`. |
| **`src/data/match_settings.lua`** | **Authoritative schema** for match-setup controls: defaults, `validate()`, `merge_partial()`. UI must only mutate settings through this module (then pass validated table into sim). |
| **`src/data/session_scores.lua`** | **Session-only** wins/draws: `get_snapshot()`, `record_match_outcome(winner_id)`, `reset()`. HUD and results read the snapshot; match end calls `record_match_outcome`. |
| **`src/config/defaults.lua`** | Gameplay tuning + **`colors.team1` / `colors.team2`** — HUD, turn banner, and roster should use these RGB tuples for **consistent team chrome** (not ad-hoc hex in UI). |

**Pseudocode — binding UI to existing data modules (intent for Coding Agent):**

```lua
-- Match setup screen commit
local match_settings = require("data.match_settings")
local s = match_settings.merge_partial(last_settings, form_partial)
-- s is validated; pass into match start

-- Title / results / HUD session chip
local session_scores = require("data.session_scores")
local snap = session_scores.get_snapshot()
-- snap.gamesPlayedP1, snap.gamesPlayedP2, snap.gamesDrawn, snap.games_played

-- When match results screen confirms winner
session_scores.record_match_outcome(winner_id) -- 1, 2, or 0 draw
```

---

## 1. High-level architecture (UX layer)

### 1.1 Design intent

- **Readable in motion:** HUD and world feedback stay legible during camera pan, explosions, and turn transitions (R1).
- **Two local humans, zero ambiguity:** Always show *whose turn it is*, *which mole is active*, and *which input mode / device* applies (R4, R10, R11).
- **Match variables surfaced before play:** All knobs in **`match_settings`** are editable in setup (R9); nothing hidden at match start.
- **Session score is honest:** Tallies from **`session_scores.get_snapshot()`** on title, in HUD, and on results (R6).

### 1.2 Scene graph — UX ids ↔ architect scenes

Use **UX ids** in this doc; implement as architect scenes/modules:

| UX id | Architect scene (see `love-architect-design.md`) | Lua file hint |
|-------|--------------------------------------------------|---------------|
| `scene_title` | MainMenu | `src/scenes/menu.lua` |
| `scene_match_setup` | MatchSetup | `src/scenes/match_setup.lua` |
| `scene_gameplay` | Play | `src/scenes/play.lua` |
| `overlay_pause` | Pause (over `Play`) | `src/scenes/pause.lua` |
| `scene_round_summary` | RoundEnd (optional) | `src/scenes/round_end.lua` |
| `scene_match_results` | MatchEnd | `src/scenes/match_end.lua` |

Transitions: §4.

### 1.3 View model contract (UI reads sim; aligns with data modules)

**Session / persistent session UI** — mirror `session_scores.get_snapshot()`:

```text
SessionView = {
  gamesPlayedP1,   -- player1_wins
  gamesPlayedP2,   -- player2_wins
  gamesDrawn,      -- draws
  games_played,    -- total matches finished (optional sublabel "matches played")
}
```

**Match / setup** — mirror validated `match_settings` fields (after `validate()`):

```text
MatchSettingsView = {
  moles_per_team,      -- fixed 5 in validate(); still show "5 moles" for clarity (R7)
  mole_max_hp,         -- 10..500
  first_player,        -- "1" | "2" | "random"
  friendly_fire,       -- boolean
  turn_time_seconds,   -- 0 = off, else 1..300
  map_seed,            -- nil random, or integer
  input_mode,          -- "shared_kb" | "dual_gamepad"
  wind,                -- "off" | "low" | "med" | "high"
}
```

**Runtime-only (from sim / turn_state — not in match_settings.lua):**

```text
TurnView          { activePlayerIndex (1|2), activeMoleSlot (1..5), phase: aim|move|fire|resolve }
CombatHudView     { selectedWeapon: rocket|grenade, aimAngle, power01, fusePreview? (grenade) }
RosterView        { perPlayer: [{ slot 1..5, hpCurrent, hpMax, alive }] }
MapMetaView       { seedOrLabel }  -- optional HUD line for procedural trust (R5)
```

Coding Agent: build snapshots in sim/render boundary; UI modules only consume tables.

---

## 2. Resolution, scaling, and safe areas

### 2.1 Base logical resolution (locked to repo)

- **`conf.lua`** sets **`t.window.width = 1280`**, **`t.window.height = 720`**. All wireframes use this logical space.
- **`t.window.minwidth = 960`**, **`t.window.minheight = 540`** — UI must remain usable at minimum; critical controls stay inside safe area.

### 2.2 Safe margins

- **≥ 24 px** from each edge for interactive HUD and primary text.
- **≥ 48 px** for elements that must never clip under letterboxing on non-16:9 windows.

### 2.3 Scaling policy

- Scale UI with **uniform** scale from window size to logical 1280×720; letterbox/pillarbox as needed.
- Prefer **crisp UI**: render HUD/menu to an internal canvas at native logical size then draw scaled (architect/implementer choice); UX requirement: **no illegible micro-text** at 1080p+.
- **Optional:** If window `< 960×540` (should not occur if min size enforced), show **“Window too small”** on title only.

---

## 3. Wireframes — pixel regions (1280 × 720)

### 3.1 `scene_title` (MainMenu)

| Region (x, y, w, h) | Element |
|---------------------|---------|
| (0, 0, 1280, 720) | Full-bleed background + vignette |
| (440, 180, 400, 280) | **Card:** logo / “Moles” wordmark |
| (440, 420, 400, 140) | **Stack** (56 px row, 12 px gap): `Play`, `Match options`, `How to play`, `Quit` |
| (40, 40, 520, 120) | **Session chip** from `SessionView`: `P1 wins · P2 wins · Draws` + “This session” |
| (840, 600, 400, 80) | Version / credits (low contrast) |

**Focus order (controller):** `Play` → `Match options` → `How to play` → `Quit`. **Default:** `Play`.

**`Play` behavior:** If no saved setup, **force** `scene_match_setup`; else start with **last validated** `match_settings` + last input assignments.

### 3.2 `scene_match_setup` (MatchSetup)

Two **columns** (single full-screen UI; not split-world).

| Region | Element |
|--------|---------|
| (40, 32, 1200, 64) | Header “Match setup” · breadcrumb `Title ▸ Setup` |
| (40, 112, 580, 520) | **Player 1** column — strip uses `defaults.colors.team1` |
| (660, 112, 580, 520) | **Player 2** column — strip uses `defaults.colors.team2` |
| (40, 656, 1200, 48) | Footer: `Back` (left) · `Start match` (right, primary) |

**Per-player column**

1. **Device / profile hint** (informational + focus if implementing per-player override later): Under **`input_mode`**, show global mode:
   - **`shared_kb`:** “Player 1 & 2: shared keyboard + mouse (mouse = active player only).”
   - **`dual_gamepad`:** “Assign gamepad to P1 / P2” rows with slot status; warn if missing pad.
2. **Team preview:** **5 mole pips** (slots 1–5); labels “Mole 1 … Mole 5” optional.

**Full-width **match variables** block (below columns or centered band) — one-to-one with **`match_settings`:**

| Field | Control | UX copy |
|-------|---------|---------|
| `moles_per_team` | Read-only label | “5 moles per team” (validated fixed at 5) |
| `mole_max_hp` | Stepper / presets (10, 25, 50, 100, 150, … capped 500) | “Mole health” |
| `first_player` | Segmented: P1 / P2 / Random | “Who goes first?” |
| `friendly_fire` | Toggle | “Friendly fire” |
| `turn_time_seconds` | 0 + presets (30, 60, 90) + custom within 1–300 | “Turn time limit” (0 = off) |
| `map_seed` | Empty = random; optional numeric field | “Map seed (optional)” |
| `input_mode` | Two large cards or radio | “Shared keyboard & mouse” vs “Two gamepads” |
| `wind` | Segmented | “Wind: Off / Low / Med / High” |

**Controller focus:** P1 column top → bottom → P2 column → match variables (top → bottom) → footer. **LB/RB** optional to jump between P1/P2 column headers. **Default focus on enter:** first interactive in P1 column or `input_mode` (if single global control first).

### 3.3 `scene_gameplay` (Play) — HUD clusters

Shared camera; **full-width HUD overlays**.

| Region | Content |
|--------|---------|
| (24, 16, 600, 88) | **Turn banner:** “Player 1 — Mole 3” + `team1`/`team2` color dot; subtle pulse on change |
| (656, 16, 600, 88) | **Session mini-score:** compact `P1 W · P2 W · D` from `SessionView` |
| (24, 104, 340, 200) | **Weapon & aim:** rocket/grenade icons, angle, **power bar**; grenade **fuse** readout |
| (916, 104, 340, 200) | **Wind** (if not off): arrow + strength; optional **turn timer** countdown if `turn_time_seconds` > 0 |
| (24, 620, 1232, 76) | **Roster bar:** two groups × **5 slots**; HP bar + alive/dead dimming |

**Active mole:** world ring + roster slot **2 px** glow using team color from `defaults.colors`.

**Rocket:** high-contrast **dashed trajectory** + small impact marker (gameplay provides geometry; UX specifies visibility).  
**Grenade:** **fuse** numeric or icon + optional arc preview.

### 3.4 `overlay_pause` (Pause) — modal over Play

- World dimmed ~**40%**.
- Centered card **520 × 360**:
  - **`Resume`** — **default focus**
  - **`How to play`**
  - **`Forfeit match`** (destructive, secondary style)
  - **`Quit to title`**

**Open:** **Esc** or **Start** (gamepad). **Close:** **Esc** or **B** when `Resume` focused.

### 3.5 `scene_match_results` (MatchEnd)

| Region | Element |
|--------|---------|
| (240, 80, 800, 120) | Headline: `Player 1 wins!` / `Player 2 wins!` / `Draw` |
| (240, 220, 800, 280) | Stats: rounds or turns, survivors, duration (optional) |
| (240, 520, 800, 120) | `Rematch` · `New setup` · `Title` |

On mount: **`session_scores.record_match_outcome(winner_id)`** already run or run here before drawing updated chip — either is fine if **snapshot** reflects new totals when screen appears (R6).

### 3.6 `scene_round_summary` (RoundEnd, optional)

Use if turn rotation is confusing: small toast or full-screen **“Next: Player 2 — Mole 2”** (1.2–2 s) or skip for MVP.

---

## 4. User flows (step-by-step)

### 4.1 Cold start → first match

1. `love.load` → Boot (if any) → **`scene_title`**; session zeros unless debug.
2. **`Match options`** → **`scene_match_setup`**; edit fields → validate via `match_settings.validate` → **`Start match`** → brief load (“Digging tunnel…”) → **`scene_gameplay`**.
3. **`Play`** from title: last settings or setup if none.

### 4.2 In-match (UX-visible)

1. Turn start → turn banner + roster highlight + camera on active mole.
2. Aim / move → weapon panel + in-world previews update.
3. Fire → short **resolve** state (disable double-fire feedback).
4. Damage → HP animation; optional team-color edge flash.
5. Handoff → optional **`scene_round_summary`** toast (R8).

### 4.3 Match end

1. Win condition → short celebration (≤2 s) → **`scene_match_results`**.
2. Updated **`SessionView`** on results and next title visit.

### 4.4 `dual_gamepad` without enough controllers

- Inline **warning**; allow **Back** to switch to `shared_kb` or wait for device; do not hard-crash.

---

## 5. Input mappings and interactions

### 5.1 Modes vs `match_settings.input_mode`

| Value | Meaning |
|-------|---------|
| `shared_kb` | One keyboard + one mouse; **mouse aim only for active player** (R10). |
| `dual_gamepad` | Two gamepads; P1/P2 mapped to joystick instances (R11). |

Show **binding summary** on setup and in **`How to play`**.

### 5.2 Shared keyboard + mouse (R10)

| Action | Player 1 | Player 2 |
|--------|----------|----------|
| Aim (mouse) | When active | When active |
| Aim left/right | `A` / `D` | `Left` / `Right` |
| Power up/down | `W` / `S` | `Up` / `Down` |
| Fire | `Space` | `Right Ctrl` **or** `Enter` (implement one; document in How to play) |
| Jump | `Q` | `]` or `Numpad 0` |
| Weapon prev/next | `1` / `2` or `[` / `]` | `,` / `.` |
| End turn (if exposed) | `E` | `Numpad Enter` (optional) |
| Pause | `Esc` | `Esc` |

**First-run tooltip:** “Mouse aims for the **active** player only.”

### 5.3 Gamepad per player (R11)

| Action | Mapping |
|--------|---------|
| Aim | Left stick |
| Fine aim | D-Pad L/R |
| Power | Triggers (preferred) or R-stick vertical |
| Fire | Bottom face button (A / cross) |
| Weapon | `LB` / `RB` |
| Pause | `Start` |

**How to play:** mention ~**15%** stick dead zone if drift is common.

### 5.4 Global

- Quit from title; pause offers **Quit to title**.

---

## 6. Accessibility & readability

- **Contrast:** UI text ≥ **4.5:1** on panels; turn banner: **text + chip** or stroked text.
- **P1/P2:** never color alone — always **label** + position (left/right) or shape.
- **Font sizes (logical):** body **18–20**, HUD numbers **≥ 22**, title **≥ 36**.
- **Reduce motion** (optional match option): shorten toasts, disable shake.
- **In-world:** mole/projectile **silhouette + outline**; explosion **1–2** frames high-contrast core (R1).

---

## 7. File / directory structure (UX-facing; extends repo)

Existing: `conf.lua`, `main.lua`, `src/data/match_settings.lua`, `src/data/session_scores.lua`, `src/config/defaults.lua`, `src/util/*`.

**Add (per architect; UX-owned content):**

```text
assets/
  fonts/
  ui/                    # panels, weapon icons, mole pips
  themes/                # optional JSON tokens

src/
  app.lua                # scene manager (architect)
  scenes/
    menu.lua             # scene_title
    match_setup.lua      # scene_match_setup
    play.lua             # scene_gameplay
    pause.lua            # overlay_pause
    match_end.lua        # scene_match_results
    round_end.lua        # optional
  ui/
    hud.lua              # orchestrates HUD regions §3.3
    widgets/             # turn_banner, roster_bar, weapon_panel, session_chip, ...
    theme.lua              # spacing, radii (if not assets/themes)
  input/
    input_manager.lua    # maps devices → intents (architect)
```

**Do not** duplicate validation logic in UI — always run **`match_settings.validate`** (or `merge_partial`) on commit.

---

## 8. Component breakdown

| Component | Responsibility |
|-----------|----------------|
| `SessionScoreChip` | Binds to `session_scores.get_snapshot()` |
| `MatchSettingsForm` | Edits fields in §3.2; outputs partial for `merge_partial` |
| `InputModeSelector` | Sets `input_mode`; shows device warnings |
| `TurnBanner` | `TurnView` |
| `RosterBar` | `RosterView` + team colors from `defaults.colors` |
| `WeaponPanel` | `CombatHudView` |
| `PauseMenu` | Modal focus; §3.4 |
| `MatchResultsPanel` | Headline + actions; triggers or reflects `record_match_outcome` |
| `HowToPlayOverlay` | KB + pad diagrams |

---

## 9. Dependencies & technology

- **LÖVE 11.4** (`conf.lua` / `DESIGN.md`).
- **Two font families** max (display + UI).
- Optional UI lib: architect’s choice; spec stays **layout- and region-based**.

---

## 10. Implementation notes for Coding Agent

1. **Mouse:** When active player’s profile uses mouse, route `love.mousemoved` to aim; otherwise ignore for world (UI hit-test excepted).
2. **Focus:** Menus = focus navigation; **Play** = world input unless pause.
3. **Z-order:** Pause > toasts > HUD > world.
4. **Roster slot index** = stable mole identity (R7/R8).
5. **Session:** Call **`record_match_outcome`** once per match end; HUD reads **`get_snapshot()`**.
6. **Team color:** Read **`require("config.defaults").colors.team1/team2`** for HUD strips and highlights.
7. **`main.lua`** already wires **joystick** callbacks — keep pause/gamepad consistent when `app` lands.

---

## 11. Structured handoff JSON

```json
{
  "userFlows": {
    "coldStart": [
      "Title → Match options → Match setup → validate match_settings → Play",
      "Title → Play (last settings) or first-time → Match setup"
    ],
    "inMatch": [
      "Turn banner → aim/move → fire → resolve → HP update → optional round toast → next turn"
    ],
    "pause": [
      "Esc|Start → overlay_pause → Resume | How to play | Forfeit | Quit to title"
    ],
    "matchEnd": [
      "Win/draw → Match results → record_match_outcome → Rematch | New setup | Title"
    ]
  },
  "wireframes": {
    "baseResolution": [1280, 720],
    "minWindow": [960, 540],
    "safeMarginPx": 24,
    "scenes": {
      "scene_title": { "sessionChip": [40, 40, 520, 120], "actionStack": [440, 420, 400, 140] },
      "scene_match_setup": { "p1Column": [40, 112, 580, 520], "p2Column": [660, 112, 580, 520], "footer": [40, 656, 1200, 48] },
      "scene_gameplay": {
        "turnBanner": [24, 16, 600, 88],
        "sessionScore": [656, 16, 600, 88],
        "weaponPanel": [24, 104, 340, 200],
        "windOrTimer": [916, 104, 340, 200],
        "rosterBar": [24, 620, 1232, 76]
      },
      "overlay_pause": { "modal": [380, 180, 520, 360] },
      "scene_match_results": { "headline": [240, 80, 800, 120], "stats": [240, 220, 800, 280], "actions": [240, 520, 800, 120] }
    }
  },
  "interactions": {
    "inputModes": ["shared_kb", "dual_gamepad"],
    "keyboardMouseShared": "section_5.2_table",
    "gamepad": "section_5.3_table",
    "pauseOpen": ["Escape", "start"],
    "pauseClose": ["Escape", "back"]
  },
  "accessibility": {
    "contrast": ">= 4.5:1 on UI panels",
    "p1p2": "text label plus non-color cue",
    "fontsLogicalPx": { "body": "18-20", "hud": ">=22", "title": ">=36" },
    "inWorld": "silhouette, outline, short hi-contrast explosion"
  },
  "dataModuleFields": {
    "match_settings": ["moles_per_team", "mole_max_hp", "first_player", "friendly_fire", "turn_time_seconds", "map_seed", "input_mode", "wind"],
    "session_scores_snapshot": ["gamesPlayedP1", "gamesPlayedP2", "gamesDrawn", "games_played"]
  },
  "recommendations": [
    "Optional round_end scene if rotation is unclear",
    "Reduce motion toggle tied to match_settings or global options",
    "Show map seed in MapMetaView when non-random for competitive clarity"
  ]
}
```

---

## 12. Requirements / DESIGN.md crosswalk

| Req | UX coverage |
|-----|-------------|
| R1 | §1.1, §3.3, §6 |
| R2–R3 | §3.3 weapon panel + trajectory/fuse |
| R4 | §3.2–3.3, §4 |
| R5 | §1.3 `MapMetaView`, optional seed display |
| R6 | §0 `session_scores`, §3.1, §3.5, §10.5 |
| R7 | §3.2–3.3 five pips; `moles_per_team` label |
| R8 | §3.6, §4.2 |
| R9 | §3.2 full `match_settings` form |
| R10 | §5.1–5.2 |
| R11 | §5.1, §5.3, §4.4 |

---

*End of love-ux design document.*
