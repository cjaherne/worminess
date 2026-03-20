# love-ux design — Moles (Worms-like) local 2P

**Agent:** love-ux  
**Scope:** Screens, HUD, focus/navigation, resolution/scaling, input affordances for menus and gameplay chrome. Does **not** define weapon math, terrain generation, or networking.

**Codebase note (current tree):** **`main.lua`** → **`src/bootstrap.lua`** → **`src/app.lua`** (`theme.load_fonts`, `audio.sfx.init`, `Session.new`, **`scene_manager`**, replace **`scenes/boot`**). **`src/scene_manager.lua`** forwards `love.update` / `draw` / input / resize to the stack (overlays draw above **`play`**). **Implemented UX modules:** **`src/ui/theme.lua`** (logical 1280×720, `begin_draw` / `end_draw`, `clear_void`, palette, `safe_margin`, fonts 22 / 28), **`src/ui/layout.lua`** (`safe_x0` / `safe_x1`, `screen_to_logical`), **`src/ui/focus_stack.lua`**, **`src/ui/hud/play_hud.lua`**. Menus and match flow live in **`src/scenes/*.lua`**; input in **`src/input/*`**; polish per **`README.md`** / **`CODING_NOTES.md`** (SFX, VFX, stick smoothing, wheel power). Game state: **`src/game/*`** (including optional **`map_seed.lua`** for round seeds — see **Map regeneration cadence** in **`DESIGN.md`**).

### Handoff: canonical documents & anchors (merged `DESIGN.md`)

Repo-root **`DESIGN.md`** is the **unified** blueprint. Use the same **section titles** as its **Anchor index** (and the tables those sections contain)—**do not** depend on stale phrases like “§3.1 UX table” or “love-ux §3.1” without naming the heading below.

| Topic | Anchor in **`DESIGN.md`** (section heading) |
|--------|---------------------------------------------|
| **MatchConfig** — fields, types, clamps | **MatchConfig — single consolidated schema** (table). **Code:** `src/game/match_config.lua`. |
| **Session** — `scores` vs `matches_completed` vs round tallies | **Session stats definition** |
| **When terrain regenerates** + seed / rematch behaviour | **Map regeneration cadence** |
| **`match_setup`** — dual column, dual Ready, `input_scheme` | **UX — §5.3 `match_setup`** (and checklist **requirementsChecklist — UX**) |
| **Scene / HUD obligations** | **requirementsChecklist — UX** plus narrative **UX §5–§7** blocks if present in merge |
| **User-flow JSON (duplicate)** | **UX — §10 Structured handoff JSON** (full JSON often pasted in merge) |

**Canonical for UX depth not fully inlined in `DESIGN.md`:** **`.pipeline/love-ux-design.md` (this file)** — wireframe pixel tables (**§5**), MatchConfig **widget/copy** extension (**§3.2**), **§6–§7**, and **§10** here. If anything conflicts: **`DESIGN.md`** wins on **MatchConfig**, **session semantics**, and **map cadence**; then **`src/game/*.lua`** and implemented scenes/HUD.

---

## 1. High-level UX architecture

### 1.1 Design pillars

- **Readable at a glance during motion:** large numerals, high-contrast team strips, minimal text during aiming.
- **Fair dual-input:** every menu path completable with **either** keyboard+mouse **or** gamepad; when two gamepads are connected, **Player 1** drives global menus unless a screen explicitly splits focus (**§4 — Component breakdown**, below).
- **Session truth:** “Games won since launch” is always visible from pause and end-of-match screens; optional compact chip in-match (see HUD). Source of truth: **`session.scores`**, **`session.matches_completed`** (`src/game/session.lua`).
- **Worms-like clarity:** active mole, team, weapon, and “commit” affordance (fire / jump) must never be ambiguous in 2P hot-seat.

### 1.2 Scene graph — reconciliation with architect (`src/scenes/`)

**Canonical scene modules** (must match architect filenames / stack): `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over`.

| Architect scene (`src/scenes/…`) | UX role | Notes |
|----------------------------------|---------|--------|
| `boot` | Asset load + optional **title splash** | Architect: load fonts/audio then push `main_menu`. UX: treat **title** as either the first 1–2s of `boot` or the initial paint of `main_menu` (pick one in code; do not add a orphan scene without updating architect merge). |
| `main_menu` | Main hub | Buttons: **Local match** → `match_setup`; **Options** (optional v1: stub); **Quit**. Show **session** wins (`session.get_scores()`). |
| `match_setup` | Edit **`match_config`** + **input_scheme** + dual ready | Field set = **`DESIGN.md` — MatchConfig — single consolidated schema** + `validate()`. Layout / Ready: **`DESIGN.md` — UX — §5.3 `match_setup`** and **§5.3** (this file, pixels). |
| `play` | Gameplay + world draw + **HUD** | Formerly called `playing` in early UX drafts; **use `play` everywhere** in code. |
| `pause` | Modal overlay | Session stats + resume / restart / setup / main menu. |
| `game_over` | Round **or** match outcome + rematch | Replace UX-only label **`match_summary`**: same scene, **layout variant** `round_end` vs `match_end`. Session bump per **`DESIGN.md` — Session stats definition** + **§9** (below). |

**In-`play` presentation (not separate scenes):**

| UX concept | Implementation hook |
|------------|---------------------|
| **`round_interstitial`** | Toast / banner driven by **`turn_state.phase`** (`interstitial`, `round_end`) while stack top remains **`play`**; avoid popping to `game_over` until designer rules say “round over UI”. |
| **`team_roster`** | Optional panel inside **`match_setup`** or omit v1; roster is already **`src/game/roster.lua`** (`mole_order`, five moles). |

Transitions: **§10** (`userFlows`, below) and **`DESIGN.md` — UX — §10 Structured handoff JSON** (merged duplicate).

### 1.3 Base resolution and scaling

- **Logical canvas:** `1280 × 720` — **`conf.lua`**, **`data.constants`** (`WORLD_W`, `WORLD_H`), and **`ui.theme`** (`logical_w` / `logical_h`). All **§5** numbers are **logical pixels** before `theme.begin_draw()` scaling.
- **Uniform scale + letterbox:** Implemented in **`src/ui/theme.lua`** (`begin_draw` / `end_draw`); **`src/app.lua`** calls **`theme.clear_void()`** then **`begin_draw`** → **`scene_manager:draw()`** → **`end_draw`**.
- **Safe margin:** `theme.safe_margin` (**24**); **`layout.safe_x0` / `safe_x1`** for clamping hitboxes. Pointer coords: **`layout.screen_to_logical(mx, my)`** for UI under scale.

---

## 2. File / directory structure (UX-facing)

### 2.1 Implemented (repository)

```
src/app.lua                 # theme + SceneManager lifecycle
src/scene_manager.lua
src/scenes/boot.lua … game_over.lua
src/ui/theme.lua            # colors, logical canvas, begin/end draw, fonts
src/ui/layout.lua           # safe_x0/x1, screen_to_logical
src/ui/focus_stack.lua
src/ui/hud/play_hud.lua     # in-play HUD + interstitial strip (see §5.4)
src/audio/sfx.lua           # UI-adjacent blips (optional hooks)
```

**Match setup / menus** are drawn inside **`src/scenes/match_setup.lua`**, **`main_menu.lua`**, etc. (no separate `ui/compose/*` layer yet).

### 2.2 Optional extensions (if refactoring)

Split large scenes into **`src/ui/compose/*`**; add **`src/ui/widgets/*`** (button, stepper, slider) if menu code duplicates grow; extract a dedicated **`toast.lua`** only if non-`play` scenes need the same queue. **Atlas / TTF assets** under **`assets/`** when replacing `love.graphics.newFont` defaults.

**Rationale:** **`play_hud.draw(ctx)`** centralises combat HUD; **`theme`** owns transform so all UI shares one scale pipeline.

---

## 3. Key data the UI must bind to (interfaces / schemas)

Bind UI **directly** to existing tables where possible (`src/game/*.lua`). Below maps **UX labels → Lua fields**.

### 3.1 Session (`src/game/session.lua`)

Semantics are fixed in **`DESIGN.md` — Session stats definition**: **`scores`** = **match wins** (not round wins); **`matches_completed`** = **finished matches**. UI must **label** “Wins” vs “Matches played” distinctly (main menu, pause, `game_over`).

Returned by `session.new()`:

| Field | UX use |
|--------|--------|
| `scores[1]`, `scores[2]` | **Match wins** since launch — **main_menu**, **pause**, **`game_over`** |
| `matches_completed` | **Matches finished** — show as “Matches played” (or equivalent), not as round score |
| `last_match_winner` | 1, 2, or nil — highlight on **game_over** |
| `last_match_config` | **Rematch** pre-fill for **match_setup** |

```text
-- Pseudocode view-model
sessionWinsP1, sessionWinsP2 = session:get_scores()
matchesPlayed = session.matches_completed
```

### 3.2 Match config (`src/game/match_config.lua`)

**Authoritative field list + validation:** **`DESIGN.md` — “MatchConfig — single consolidated schema (source of truth)”** (must match `match_config.lua`). Do not duplicate a competing table in code comments elsewhere.

Edit in **`match_setup`**; always run **`match_config.validate(c)`** before **`play`**. The following adds **UX-only** columns (widget + copy). Numeric clamps follow **`DESIGN.md`** MatchConfig table / `validate()`:

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

**Dual confirm (product brief):** two **`ready_p1` / `ready_p2`** booleans are **UI-local** until both true, then **Start match** enabled; aligns with **`DESIGN.md` — UX — §5.3 `match_setup`** and **§5.3** (this file).

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

**Round vs match score in HUD:** **Session** fields above are **not** round tallies (**`DESIGN.md` — Session stats definition**). If gameplay exposes “rounds won this match”, show separately (e.g. match HUD or `game_over`) without overloading `scores` / `matches_completed`.

### 3.4 Input routing (menus + play)

| Concept | Implementation hook (architect) |
|---------|----------------------------------|
| `menuOwner` | While in menus, default **keyboard** + **joystick 1** move focus; **joystick 2** optional for **Ready** only in **match_setup** |
| `input_scheme` | `match_config.input_scheme` — **`play`** scene routes KB/Mouse to **active_player** when `shared_kb`; maps **joystick id** to player when `dual_gamepad` |

When both pads connected, **Player 1** drives **focus** on `main_menu` / `match_setup` **except** dual-ready inputs (**§5.3** below; also **`DESIGN.md` — requirementsChecklist — UX**).

---

## 4. Component breakdown and responsibilities

| Component | Responsibility |
|-----------|----------------|
| `layout` | Exposes `getSafeRect()`, `anchorTopLeft(w,h, margin)`, split regions for future split-screen **if** camera splits; v1 may be single shared world view with turn-based camera follow — HUD still uses full width. |
| `theme` | Semantic palette: background `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`. WCAG-style contrast for **large text** on panels. |
| `widgets.*` | Draw + hit-test + **focus** state; emit `onConfirm`, `onCancel`, `onValueChange`. |
| `focus_stack` | Manages ordered focusable list, wrap at edges, visual focus ring `2px` offset, `accent` color. |
| `compose/*` | Full-screen / overlay **views** invoked from `src/scenes/*`; no gameplay rules. |
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

**Merged summary:** **`DESIGN.md` — `match_setup` (dual column)**. **This subsection** is the **pixel-accurate** expansion.

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

**Binding source of truth:** **`DESIGN.md` — Mechanics (summary) → Controls** and `src/input/bindings.lua` once implemented. HUD hints must **track `turn_state.active_player`** and the active **input_scheme**.

Document in-options / loading screen; HUD shows a **short subset** only:

- **Example (from merged DESIGN — adjust if bindings table differs):** P1 — `A`/`D` move, `W`/`S` aim, hold `Shift` for power, `Space` fire, `1`/`2` weapons; P2 — non-overlapping set (e.g. numpad / arrows) per bindings.
- **Mouse:** aim + fire for **active** player only when scheme allows (**`DESIGN.md` — Input routing**).

### 6.3 Gameplay layer (dual controllers)

- **Pad index** maps to **player index** for movement/aim when it is that player’s turn.
- When not their turn, pad inputs ignored except **Start** → pause (**§5.5 `pause`**, below — referenced from **`DESIGN.md` — requirementsChecklist — UX** pause item).

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
