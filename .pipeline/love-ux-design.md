# love-ux design — Moles (Worms-like) local 2P

**Agent:** love-ux  
**Scope:** Screens, HUD, focus/navigation, resolution/scaling, input affordances for menus and gameplay chrome. Does **not** define weapon math, terrain generation, or networking.

**Codebase note (current tree):** The project already defines **`conf.lua`** (1280×720, resizable, `joystick` on), **`main.lua`** (`package.path` + `require("bootstrap")` + `app.register()`), and **`src/bootstrap.lua`** (`setDefaultFilter("nearest")`). Gameplay data and state live under **`src/game/session.lua`**, **`src/game/match_config.lua`**, **`src/game/roster.lua`**, **`src/game/turn_state.lua`**, with world/entities under **`src/world/*`** and **`src/entities/*`**. This UX spec **binds HUD and menus to those module shapes** and aligns **scene IDs** with **`.pipeline/love-architect-design.md`** (`src/scenes/*.lua`).

---

## 1. High-level UX architecture

### 1.1 Design pillars

- **Readable at a glance during motion:** large numerals, high-contrast team strips, minimal text during aiming.
- **Fair dual-input:** every menu path completable with **either** keyboard+mouse **or** gamepad; when two gamepads are connected, **Player 1** drives global menus unless a screen explicitly splits focus (see §4).
- **Session truth:** “Games won since launch” is always visible from pause and end-of-match screens; optional compact chip in-match (see HUD). Source of truth: **`session.scores`**, **`session.matches_completed`** (`src/game/session.lua`).
- **Worms-like clarity:** active mole, team, weapon, and “commit” affordance (fire / jump) must never be ambiguous in 2P hot-seat.

### 1.2 Scene graph — reconciliation with love-architect

**Canonical scene modules** (must match architect filenames / stack): `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over`.

| Architect scene (`src/scenes/…`) | UX role | Notes |
|----------------------------------|---------|--------|
| `boot` | Asset load + optional **title splash** | Architect: load fonts/audio then push `main_menu`. UX: treat **title** as either the first 1–2s of `boot` or the initial paint of `main_menu` (pick one in code; do not add a orphan scene without updating architect merge). |
| `main_menu` | Main hub | Buttons: **Local match** → `match_setup`; **Options** (optional v1: stub); **Quit**. Show **session** wins (`session.get_scores()`). |
| `match_setup` | Edit **`match_config`** + **input_scheme** + dual ready | Fields must mirror **`src/game/match_config.lua`** after `validate()` (see §3). **Dual confirm** (product brief): two **Ready** toggles, P1 and P2 (§5.3). |
| `play` | Gameplay + world draw + **HUD** | Formerly called `playing` in early UX drafts; **use `play` everywhere** in code. |
| `pause` | Modal overlay | Session stats + resume / restart / setup / main menu. |
| `game_over` | Round **or** match outcome + rematch | Replace UX-only label **`match_summary`**: same scene, **layout variant** `round_end` vs `match_end` (copy, primary button). Session bump occurs when mechanics say match finished (see §9). |

**In-`play` presentation (not separate scenes):**

| UX concept | Implementation hook |
|------------|---------------------|
| **`round_interstitial`** | Toast / banner driven by **`turn_state.phase`** (`interstitial`, `round_end`) while stack top remains **`play`**; avoid popping to `game_over` until designer rules say “round over UI”. |
| **`team_roster`** | Optional panel inside **`match_setup`** or omit v1; roster is already **`src/game/roster.lua`** (`mole_order`, five moles). |

Transitions: see §10 JSON `userFlows`.

### 1.3 Base resolution and scaling

- **Logical canvas:** `1280 × 720` (16:9) — already matches **`conf.lua`** (`t.window.width` / `height`) and **`src/data/constants.lua`** (`WORLD_W`, `WORLD_H`). All layout numbers below are **logical pixels** on that canvas.
- **Resizable window:** `conf.lua` sets `resizable = true` and minimum 800×450; UX must apply **uniform scale** + letterbox/pillarbox so HUD stays proportional. Maintain a **safe margin** of `24px` at 1× (scale with `uiScale`).
- **UI scale factor:** `uiScale = min(screenW/1280, screenH/720)`; multiply layout constants when drawing.

---

## 2. Proposed file / directory structure (UX-facing)

These paths are **specification only** — no implementation in this task. **Architect owns** `src/scenes/*.lua` and `src/app.lua`; **UX owns** composable draw/focus helpers under `src/ui/` that scenes **call into** (keep scenes thin).

```
assets/
  fonts/
    ui_bold.ttf          # menu + HUD numerals (license-clear)
    ui_regular.ttf
  ui/
    atlas_moles_ui.png   # nine-slice panels, buttons, icons (weapon silhouettes)
    theme.lua            # optional: colors, corner radii (data, not logic)
src/
  scenes/                # love-architect: boot, main_menu, match_setup, play, pause, game_over
  ui/
    theme.lua            # semantic colors: teamA, teamB, accent, danger
    layout.lua           # anchors, safe rect, scale helper
    focus_stack.lua      # controller focus ring + stack for overlays
    widgets/
      button.lua
      slider.lua
      stepper.lua        # numeric match vars (health, wind, fuse, …)
      toggle.lua         # friendly_fire, per-player Ready
      panel.lua
    compose/
      main_menu_view.lua
      match_setup_view.lua
      pause_view.lua
      game_over_view.lua # variants: round_end | match_end
    hud/
      play_hud.lua       # turn banner, weapon strip, wind, move budget, optional session chip
      toast.lua          # short messages (“Player 2’s turn”, interstitial copy)
```

**Rationale:** **Scenes** handle stack lifecycle and delegate drawing/focus to **`src/ui/`**; **HUD** updates every frame from **`turn_state`** + **`match_config`** while **`play`** is on top.

---

## 3. Key data the UI must bind to (interfaces / schemas)

Bind UI **directly** to existing tables where possible (`src/game/*.lua`). Below maps **UX labels → Lua fields**.

### 3.1 Session (`src/game/session.lua`)

Returned by `session.new()`:

| Field | UX use |
|--------|--------|
| `scores[1]`, `scores[2]` | Session wins since launch; **main_menu**, **pause**, **game_over** headers |
| `matches_completed` | “Matches played” line (optional; increments via `bump_match_win`) |
| `last_match_winner` | 1, 2, or nil — highlight on **game_over** |
| `last_match_config` | **Rematch** pre-fill for **match_setup** |

```text
-- Pseudocode view-model
sessionWinsP1, sessionWinsP2 = session:get_scores()
matchesPlayed = session.matches_completed
```

### 3.2 Match config (`src/game/match_config.lua`)

Edit in **`match_setup`**; always run **`match_config.validate(c)`** before starting **`play`**. Expose these in the form (clamps are implementation-defined; current code uses HP 1–500, wind ±400, fuse 0.5–8, rounds_to_win 1–9, turn_time_limit 5–120 or nil):

| Field | Widget | UX copy |
|--------|--------|---------|
| `mole_max_hp` | Stepper/slider | “Mole health” (large numeral) |
| `rounds_to_win` | Stepper | “Rounds to win match” |
| `wind_strength` | Slider + “Off” at 0 | “Wind” (show direction arrow when ≠ 0) |
| `grenade_fuse_seconds` | Stepper | “Grenade fuse (s)” |
| `turn_time_limit` | Toggle + stepper or nil | “Turn timer” optional |
| `friendly_fire` | Toggle | “Friendly fire” (default on per data) |
| `procedural_seed` | Optional field / “Random” | Debug or “Custom seed” (nil = random) |
| `input_scheme` | Radio | `"shared_kb"` vs `"dual_gamepad"` (existing constants in code) |
| `teams_per_player` | Read-only label | From `data.constants.MOLES_PER_TEAM` (5) |

**Dual confirm (product brief):** two **`ready_p1` / `ready_p2`** booleans are **UI-local** until both true, then **Start match** enabled; or require each player to press **Confirm** on their device once settings are valid (see §5.3).

### 3.3 Turn + HUD presentation (`src/game/turn_state.lua` + roster + active mole)

| Field | UX use |
|--------|--------|
| `active_player` | 1 \| 2 — turn banner, which control legend to show |
| `active_mole_slot` | Index into **`team.moles`** for active player’s team |
| `phase` | `aim`, `firing`, `flying`, `round_end`, `interstitial` — HUD hints, pause certain inputs, **toasts** |
| `move_budget` | Move “fuel” bar (from constants `MOVE_BUDGET_MAX`) |
| `aim_angle`, `power`, `charging` | Aim reticle / power bar when `phase == aim` |
| `weapon_index`, `weapons` | Strip highlight; label from **`require("game.turn_state").current_weapon_id(ts)`** → `rocket` \| `grenade` |

**Per-mole:** `teams[active_player].moles[active_mole_slot].hp` vs `match_config.mole_max_hp` for **health pips** or numeric HP.

**Wind display:** `match_config.wind_strength` (scalar); format as arrow + magnitude.

**Round vs match score in HUD:** if the game layer tracks “rounds won this match”, surface that beside session scores or only on **game_over** — follow merged game-designer spec; minimum is **session** from §3.1.

### 3.4 Input routing (menus + play)

| Concept | Implementation hook (architect) |
|---------|----------------------------------|
| `menuOwner` | While in menus, default **keyboard** + **joystick 1** move focus; **joystick 2** optional for **Ready** only in **match_setup** |
| `input_scheme` | `match_config.input_scheme` — **`play`** scene routes KB/Mouse to **active_player** when `shared_kb`; maps **joystick id** to player when `dual_gamepad` |

When both pads connected, **Player 1** drives **focus** on `main_menu` / `match_setup` **except** dual-ready inputs (§5.3).

---

## 4. Component breakdown and responsibilities

| Component | Responsibility |
|-----------|----------------|
| `layout` | Exposes `getSafeRect()`, `anchorTopLeft(w,h, margin)`, split regions for future split-screen **if** camera splits; v1 may be single shared world view with turn-based camera follow — HUD still uses full width. |
| `theme` | Semantic palette: background `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`. WCAG-style contrast for **large text** on panels. |
| `widgets.*` | Draw + hit-test + **focus** state; emit `onConfirm`, `onCancel`, `onValueChange`. |
| `focus_stack` | Manages ordered focusable list, wrap at edges, visual focus ring `2px` offset, `accent` color. |
| `screens.*` | Full-screen or overlay compositions; no gameplay rules. |
| `hud/play_hud` | Non-modal layer: turn strip, weapon icons, wind, move budget, compact score/session chip, crosshair-adjacent hints (if mouse player). |
| `hud/toast` | Queue of short-lived banners (1.2–2.0s) for turn changes and round rotation text. |

---

## 5. Wireframes — pixel regions (1280×720 logical)

### 5.1 Title splash (inside `boot` or first paint of `main_menu`)

- **Background:** full-bleed illustration or gradient; vignette for readability.
- **Center block:** `x: 440–840`, `y: 220–500`
  - Title wordmark
  - Subtitle: “Local 2 players · Moles with heavy weapons”
  - **Primary prompt:** “Press **Enter** / **A** to start” (blink at 1 Hz)
- **Footer:** `y: 660–708`, `x: 40–1240` — version string left; “©” / credits right, `ui_regular` 14px equivalent at 1× scale.

### 5.2 `main_menu`

- **Left panel:** `x: 80`, `y: 140`, `w: 520`, `h: 440` — vertical button stack, spacing `56px` between centers.
  - Buttons: **Local match**, **Options**, **Quit**
- **Right art pane:** `x: 640–1200`, `y: 80–640` — decorative mole silhouettes / preview still.
- **Default focus:** first button (`Local match`).

### 5.3 `match_setup`

Two-column form inside panel `x: 120–1160`, `y: 100–620`.

- **Column A — Match variables** (mirror **`match_config`**)
  - **Mole health** (`mole_max_hp`): stepper, step `5` or `10`, **72px** numeral in `ui_bold`; clamp after validate **1–500**.
  - **Rounds to win** (`rounds_to_win`): stepper **1–9**.
  - **Wind** (`wind_strength`): slider **−400…400** with **0 = calm** center tick; show **← / →** icon.
  - **Grenade fuse** (`grenade_fuse_seconds`): stepper **0.5–8** s.
  - **Turn timer** (`turn_time_limit`): “Off” (nil) or **5–120** s.
  - **Friendly fire** (`friendly_fire`): toggle.
  - Helper line: “**5 moles** per player (`MOLES_PER_TEAM`). Turns alternate **teams**; **mole order** rotates each round (`roster.mole_order`).”
- **Column B — Input mode**
  - Radio: **`shared_kb`** — “One keyboard + mouse: **active player** uses mouse aim.”
  - Radio: **`dual_gamepad`** — “Two controllers”; show **assign** status (§6.4).
- **Dual ready strip** (`y: 520–600`, full width): two large chips **P1 Ready** / **P2 Ready** (filled when that player presses **Confirm** on their bound device). **Start match** stays **disabled** until both ready **and** config valid.
- **Footer actions** (horizontal): `Back` (left), `Start match` (right) — `y: 640`, `x: 160` and `x: 920`.

### 5.4 `play` HUD (single shared view — v1)

Scene name **`play`** (not `playing`). Assume **one** world camera (no per-player split) unless architect mandates split-screen later.

| Cluster | Anchor | Size / notes |
|---------|--------|----------------|
| **Turn banner** | top center | `w: 560`, `h: 64`, `y: 16`, centered — “Player **N** · Mole **slot**” from `active_player` + `active_mole_slot` + team color bar `8px` |
| **Scores** | top corners | P1: `x: 24`, `y: 24`; P2: right-aligned `x: 1256`, `y: 24`. Show **match** round wins if available; else session-only in chip |
| **Session chip** | below score or `y: 72` | “Session **a–b**” optional; else **pause** only |
| **Phase / interstitial** | overlay | When `turn_state.phase` is `interstitial` or `round_end`, reuse **toast** region (§5.6) without leaving **`play`** |
| **Move budget** | near mole or bottom | Bar for `move_budget` vs `MOVE_BUDGET_MAX` |
| **Weapon strip** | bottom center | `y: 656`, icons `64×64`, gap `16`; highlight `current_weapon_id` |
| **Wind** | top center `y: 88` | From `match_config.wind_strength` |
| **Power / charge** | bottom | Visible when `charging` or `phase == aim`; binds to `power` |
| **Grenade fuse** | near active mole or weapon strip | When grenade entity armed / in flight (entity state), not only static config |
| **Help hints** | bottom corners | `y: 600–680`: swap legend when **`active_player`** changes |

**Mouse-specific:** when **`input_scheme == shared_kb`** and **`active_player`** uses mouse, show **cursor** + aim line; keep HUD `y ≥ 600` where possible for low-angle shots.

### 5.5 `pause`

- **Dimmer:** `rgba(0,0,0,0.55)` full screen.
- **Panel:** `x: 340`, `y: 160`, `w: 600`, `h: 400`
  - Title: “Paused”
  - **Session stats** block: games played, wins, last result
  - Buttons: **Resume**, **Restart match**, **Match setup**, **Main menu**
- **Input rule:** Either player can pause **if** using their device:
  - **Keyboard:** `Esc` toggles
  - **Controller:** `Start` on **either** pad opens pause; **last opener** owns focus by default; other player can “steal” focus with their `Start` (optional v2) — **v1:** first `Start` wins focus; second press does nothing until resume (document clearly in options).

### 5.6 `round_interstitial` (lightweight)

- Full-width **toast** at `y: 200`, `h: 120`, semi-transparent panel
- Copy pattern: “Round 4 — **Player 1 · Mole 2**”
- Auto-dismiss `1.5s` or on any `Confirm` input

### 5.7 `game_over` (replaces UX label `match_summary`)

Single scene with **variants**:

- **`round_end`:** smaller panel — round winner, living mole counts, **Continue** → back to **`play`** (new round / map per game rules).
- **`match_end`:** full **hero outcome** `y: 180–320`, **session** table (`session.scores`, `matches_completed`), **last_match_winner** emphasis.
- Buttons (both variants where applicable): **Rematch** (restore `session.last_match_config`), **New setup** → **`match_setup`**, **Main menu** → **`main_menu`**.

---

## 6. Interactions — input mappings (menus + global)

### 6.1 Menu / UI layer (when `UIConsumesInput == true`)

| Action | Keyboard/Mouse | Gamepad (either pad when “active” for menus) |
|--------|----------------|---------------------------------------------|
| Move focus up/down | `Up` / `Down` | D-Pad up/down or left stick (debounced) |
| Confirm | `Enter` / **Left click** on focused | `A` (bottom button) |
| Back / cancel | `Esc` / `Backspace` | `B` |
| Tab next widget | `Tab` | `RB` / `LB` optional |
| Adjust stepper/slider | `Left`/`Right` | D-Pad left/right |

**Mouse:** clickable regions must mirror focus order; focused element shows `accent` outline.

### 6.2 Gameplay layer (hot-seat keyboard+mouse)

Document in-options screen; HUD shows subset:

- **Player 1** default bindings example: `WASD` move, `Q/E` cycle weapon, hold `Space` power, release fire, `Shift` jump — **exact keys** owned by Game Designer / input module; UX only requires **on-screen prompt** updates when the active player changes.
- **Player 2** when active: suggest **arrow keys + RCtrl** or **IJKL** — must be **spatially distinct** from P1 to reduce accidental input.

### 6.3 Gameplay layer (dual controllers)

- **Pad index** maps to **player index** for movement/aim when it is that player’s turn.
- When not their turn, pad inputs ignored except **Start** → pause (see §5.5).

### 6.4 `match_setup` — assigning controllers

- If user selects “Two controllers”, show **inline status**: “Controller 1: detected ✓”, “Controller 2: press **A** to assign” with timeout return to keyboard mode if no second pad.

---

## 7. Accessibility and readability

- **Type sizes (1× logical scale):** menu body ≥ `22px`; HUD scores ≥ `28px`; critical warnings ≥ `26px` bold.
- **Color:** never rely on color alone — prepend player glyph (P1 / P2) and mole index.
- **Motion:** reduce flashing UI to ≤ 3 Hz; avoid rapid full-screen flashes in interstitials.
- **Color-blind:** optional pattern fill on team bars (diagonal stripes vs solid) — flag in options later; v1 use **distinct hues + labels**.

---

## 8. Dependencies and technology choices (UX)

- **LÖVE2D** built-in fonts acceptable for prototype; ship **one bold + one regular** TTF for consistent kerning at low res.
- **Nine-slice** panels: implement via quads or `love.graphics.mesh` — art exported as single atlas for batching.
- **No external UI framework required** if team prefers minimal deps; optional `slab` / `SUIT` only if architect merge mandates — this design is agnostic.

---

## 9. Implementation notes for Coding Agent

1. **Single source of truth:** HUD reads **`turn_state`**, **`match_config`**, **`session`**, and **`roster`** / active **mole** entity — never duplicate turn resolution in UI.
2. **Toast queue:** re-entrant safe; serialize when `phase` flips and round events fire in the same frame.
3. **Resolution:** implement `push`-style transform or equivalent: uniform scale + letterbox bars (`theme.void`); respect **`conf.lua`** min window size.
4. **Focus:** on resize / gamepad hot-plug, reassert default focus on the active scene (`main_menu`, `match_setup`, `pause`, `game_over`).
5. **Session scores:** call **`session:bump_match_win(player_index)`** only when game rules declare **match** finished (typically from **`game_over` match_end** path or turn resolver), not when exiting **`play`** mid-match.
6. **Weapon UX:** rocket vs grenade — grenade shows **fuse** + arc expectation; strip always reserves slot for both **`weapons`** entries in `turn_state`.
7. **Scene filenames:** use **`src/scenes/play.lua`**, **`game_over.lua`**, etc., per **love-architect**; UX compose modules under **`src/ui/`** only.
8. **`main.lua`** expects **`app.register()`** — wire **`SceneManager`** there; first push **`boot`** or **`main_menu`** per architect merge.

---

## 10. Structured handoff JSON

```json
{
  "userFlows": {
    "cold_start": [
      "Launch → love.load → app → SceneManager",
      "boot: load fonts/audio/ui atlas → push main_menu (title splash optional inside boot)",
      "main_menu: Local match → match_setup",
      "match_setup: edit match_config fields + input_scheme; dual Ready; validate → push play",
      "play: gameplay + play_hud; phase interstitial/round_end shows toast without popping scene",
      "play: round complete → game_over variant round_end → play (or regenerate map per rules)",
      "play: match complete → game_over variant match_end → bump session → Rematch/New setup/Main menu",
      "any: Esc / Start → pause overlay on play (and optionally menus) → Resume / Restart / match_setup / main_menu"
    ],
    "session_stats": [
      "Display session.scores[1], session.scores[2] on main_menu, pause, game_over match_end",
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
      "principle": "input_scheme shared_kb: route KB/mouse to active_player only; HUD legend follows active_player"
    },
    "gameplay_dual_pad": {
      "principle": "input_scheme dual_gamepad: map joystick to player slot on turn; Start opens pause"
    }
  },
  "accessibility": {
    "contrast": "Light ink on dark void for menus; team IDs textual (P1/P2 + mole slot)",
    "fontMinSizesPx": { "menuBody": 22, "hudScore": 28 },
    "motion": "Subtle pulse ≤ 1 Hz for primary prompts"
  },
  "recommendations": [
    "v1: skip heavy character creator; display mole slot index + team color from roster",
    "Parallax optional on main_menu art pane",
    "Playtest: bottom HUD y vs low-angle aim; tune weapon strip position"
  ]
}
```

---

## 11. Visual style direction (for art/audio agents)

- **Tone:** playful underground — rounded panels, soft shadows, paper texture overlay at 8–12% opacity.
- **Silhouettes:** chunky moles, oversized weapons readable at 64×64 icon size.
- **Particles:** keep UI chrome free of heavy particles; confine celebration to **`game_over` (`match_end`)**.

---

*End of love-ux design — implementation deliberately omitted per pipeline role.*
