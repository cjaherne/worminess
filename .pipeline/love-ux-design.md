# love-ux design — Moles (Worms-like) local 2P

**Agent:** love-ux  
**Scope:** Screens, HUD, focus/navigation, resolution/scaling, input affordances for menus and gameplay chrome. Does **not** define weapon math, terrain generation, or networking.

**Codebase note:** The repository currently has no `main.lua` / `conf.lua` in the tree snapshot used for this design. The UX spec below assumes a standard LÖVE2D layout once implemented; paths are **proposed** for the Coding Agent to adopt consistently with the LÖVE Architect merge.

---

## 1. High-level UX architecture

### 1.1 Design pillars

- **Readable at a glance during motion:** large numerals, high-contrast team strips, minimal text during aiming.
- **Fair dual-input:** every menu path completable with **either** keyboard+mouse **or** gamepad; when two gamepads are connected, **Player 1** drives global menus unless a screen explicitly splits focus (see §4).
- **Session truth:** “Games won since launch” is always visible from pause and end-of-match screens; optional compact chip in-match (see HUD).
- **Worms-like clarity:** active mole, team, weapon, and “commit” affordance (fire / jump) must never be ambiguous in 2P hot-seat.

### 1.2 Scene graph (labels for architect alignment)

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

### 1.3 Base resolution and scaling

- **Logical canvas:** `1280 × 720` (16:9). All layout numbers below are in **logical pixels** relative to this canvas.
- **`conf.lua` guidance (for implementer):** `t.window.width/height` or `love.window.setMode` targeting 1280×720; enable **resizable** with **uniform scale** (letterbox/pillarbox) so UI stays proportional. Maintain a **safe margin** of `24px` from each edge for critical HUD (scale this margin with the same UI scale factor).
- **UI scale factor:** `uiScale = min(screenW/1280, screenH/720)`; multiply layout constants when drawing so 720p assets remain crisp on 1080p/4K.

---

## 2. Proposed file / directory structure (UX-facing)

These paths are **specification only** — no implementation in this task.

```
assets/
  fonts/
    ui_bold.ttf          # menu + HUD numerals (license-clear)
    ui_regular.ttf
  ui/
    atlas_moles_ui.png   # nine-slice panels, buttons, icons (weapon silhouettes)
    theme.lua            # optional: colors, corner radii (data, not logic)
src/
  ui/
    theme.lua            # semantic colors: teamA, teamB, accent, danger
    layout.lua           # anchors, safe rect, scale helper
    focus_stack.lua      # controller focus ring + stack for overlays
    widgets/
      button.lua
      slider.lua
      stepper.lua        # numeric match vars (health)
      panel.lua
    screens/
      title.lua
      main_menu.lua
      match_setup.lua
      pause.lua
      match_summary.lua
    hud/
      playing_hud.lua    # turn banner, weapon strip, wind, session chip
      toast.lua          # short messages (“Player 2’s turn”)
```

**Rationale:** Keeps **screens** separate from **HUD** (different update cadence: menus step on input; HUD follows game state every frame).

---

## 3. Key data the UI must bind to (interfaces / schemas)

The Coding Agent should treat these as **view-model fields** (names are suggestive, not API law):

### 3.1 `SessionModel` (persistent for app lifetime)

```text
sessionGamesPlayed: integer
sessionWins: { p1: integer, p2: integer }   # or keyed by team id
lastMatchResult: enum { p1, p2, draw } | null
```

### 3.2 `MatchOptions` (set in `match_setup`, frozen for match)

```text
molesPerTeam: 5   # fixed for this product vision; UI shows as read-only label unless design expands later
moleBaseHealth: number   # slider/stepper; show current value large
# optional future keys reserved in UI copy only: turnTimeSeconds, windStrength, etc.
```

### 3.3 `TurnPresentation` (HUD reads each frame)

```text
activePlayerIndex: 1 | 2
activeMoleIndex: 1..5   # within that player's roster
activeMoleDisplayName: string   # “Mole 3” or custom name
teamColor: color
selectedWeaponId: enum { rocket, grenade, ... }
aimMode: enum { idle, aiming, charging }   # affects HUD hints
grenadeFuseSeconds: number | null           # show only when grenade armed/flying if applicable
windVectorLabel: string                     # e.g. “← 3” or icon + chevrons
scoresThisMatch: { p1: integer, p2: integer }
```

### 3.4 `InputRoutingMode` (for menus)

```text
menuOwner: enum { shared_keyboard_mouse, pad1, pad2 }
# When both pads connected, default menuOwner = pad1; Player 2 uses “Join/Override” only where specified
```

---

## 4. Component breakdown and responsibilities

| Component | Responsibility |
|-----------|----------------|
| `layout` | Exposes `getSafeRect()`, `anchorTopLeft(w,h, margin)`, split regions for future split-screen **if** camera splits; v1 may be single shared world view with turn-based camera follow — HUD still uses full width. |
| `theme` | Semantic palette: background `#1a1423`, paper `#f4ede0`, ink `#2b1f33`, team A `#6cb5c8`, team B `#e8a23c`, accent `#c44dff`, danger `#e24a4a`. WCAG-style contrast for **large text** on panels. |
| `widgets.*` | Draw + hit-test + **focus** state; emit `onConfirm`, `onCancel`, `onValueChange`. |
| `focus_stack` | Manages ordered focusable list, wrap at edges, visual focus ring `2px` offset, `accent` color. |
| `screens.*` | Full-screen or overlay compositions; no gameplay rules. |
| `hud/playing_hud` | Non-modal layer: turn strip, weapon icons, wind, compact score/session chip, crosshair-adjacent hints (if mouse player). |
| `hud/toast` | Queue of short-lived banners (1.2–2.0s) for turn changes and round rotation text. |

---

## 5. Wireframes — pixel regions (1280×720 logical)

### 5.1 `title`

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

- **Column A — Match variables**
  - **Mole health** stepper: large value `min 1 — max TBD by game design`, step `5` or `10`; show number `72px` tall in `ui_bold`.
  - Helper line: “Each player fields **5 moles**. Turn order rotates **player → mole** each round.”
- **Column B — Input mode** (radio group or toggle)
  - **Shared keyboard + mouse** (hot-seat): explain “Mouse aims when it’s your mole; keyboard shortcuts shown in HUD.”
  - **Two controllers**: “P1 Menu = D-Pad / Left stick + A/B; P2 joins with Start on pad 2.”
- **Footer actions** (horizontal): `Back` (left), `Start match` (right) — `y: 640`, `x: 160` and `x: 920`.

### 5.4 `playing` HUD (single shared view — v1)

Assume **one** world camera (no per-player split) unless architect mandates split-screen later.

| Cluster | Anchor | Size / notes |
|---------|--------|----------------|
| **Turn banner** | top center | `w: 560`, `h: 64`, `y: 16`, centered — shows “Player 2 · Mole 4” + team color bar `8px` under text |
| **Scores** | top corners | P1: `x: 24`, `y: 24`; P2: right-aligned `x: 1256`, `y: 24` (measure from right). Large digits `ui_bold` |
| **Session chip** | below score or `y: 72` | Small text: “Session: P1 3 — P2 1” optional; if clutter, show **only** in pause |
| **Weapon strip** | bottom center | `y: 656`, icons `64×64`, gap `16`; highlight selected; show ammo/infinite per design |
| **Wind** | top center below banner or `x: 640` | Compact: arrow + number, `y: 88` |
| **Grenade fuse** | near active mole or bottom-left of weapon strip | Only visible when relevant; numeric + ring |
| **Help hints** | bottom corners | `y: 600–680`: context keys — e.g. “Tab: weapon”, “Hold Space: power” (actual bindings from input spec) |

**Mouse-specific:** when active input is keyboard/mouse for current player, show **cursor** and **aim line** (gameplay); HUD does not obscure cursor hotspot — keep bottom strip `y ≥ 600` so cursor can reach lower angles (tune after playtest).

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

### 5.7 `match_summary`

- **Hero outcome:** center, `y: 180–320`
- **Score table:** this match + session totals
- Buttons: **Rematch** (pre-fills last options), **New setup**, **Main menu**

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

1. **Single source of truth:** `TurnPresentation` drives HUD; do not duplicate turn logic in UI.
2. **Toast queue:** re-entrant safe — multiple events in one frame should serialize messages.
3. **Resolution:** implement `push` library pattern or equivalent: `love.graphics.translate` + uniform scale + letterbox bars filled with `theme.void`.
4. **Focus:** on window resize / gamepad connect, **reassert** default focus on current screen.
5. **Session scores:** increment on `match_summary` confirm path, not on `playing` exit, to avoid double-count on crash mid-match.
6. **Weapon UX:** rocket vs grenade — grenade needs **fuse** and **arc** affordances; HUD reserves space even if hidden until equipped.
7. **Architect alignment:** screen IDs in §1.2 should match whatever scene stack the merged design names; rename consistently if merged doc differs.

---

## 10. Structured handoff JSON

```json
{
  "userFlows": {
    "cold_start": [
      "Launch → boot (assets) → title",
      "Title: confirm → main_menu",
      "main_menu: Local match → match_setup",
      "match_setup: set mole health, choose input mode, assign pads if needed → playing",
      "playing: end-of-round → round_interstitial → playing",
      "playing: last mole eliminated → match_summary",
      "match_summary: Rematch → playing (same options) | New setup → match_setup | Main menu → main_menu",
      "any: Esc/Start → pause → Resume/Restart/Setup/Quit branches"
    ],
    "session_stats": [
      "sessionWins update on match_summary acknowledgment",
      "pause always shows session totals"
    ]
  },
  "wireframes": {
    "baseResolution": [1280, 720],
    "safeMarginPx": 24,
    "screens": ["title", "main_menu", "match_setup", "playing", "pause", "round_interstitial", "match_summary"]
  },
  "interactions": {
    "menu": {
      "nav": ["up/down", "dpad", "stick_debounced"],
      "confirm": ["enter", "mouse_click", "gamepad_a"],
      "back": ["escape", "gamepad_b"]
    },
    "gameplay_hot_seat": {
      "principle": "HUD and prompts switch with activePlayerIndex; non-active inputs suppressed"
    },
    "gameplay_dual_pad": {
      "principle": "playerIndex maps to joystick id on their turn; Start opens pause"
    }
  },
  "accessibility": {
    "contrast": "Light ink on dark void for menus; team IDs textual",
    "fontMinSizesPx": { "menuBody": 22, "hudScore": 28 },
    "motion": "Subtle pulse ≤ 1 Hz for primary prompts"
  },
  "recommendations": [
    "v1: skip heavy character creator; use 'Mole 1–5' + team color",
    "If performance allows, add subtle parallax on title/menu art pane",
    "Playtest: bottom HUD height vs low-angle aiming; may raise to y=620–640"
  ]
}
```

---

## 11. Visual style direction (for art/audio agents)

- **Tone:** playful underground — rounded panels, soft shadows, paper texture overlay at 8–12% opacity.
- **Silhouettes:** chunky moles, oversized weapons readable at 64×64 icon size.
- **Particles:** keep UI chrome free of heavy particles; confine celebration to `match_summary`.

---

*End of love-ux design — implementation deliberately omitted per pipeline role.*
