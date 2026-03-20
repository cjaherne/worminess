# LÖVE UX Design — Moles (Worms-style clone)

**Agent:** `love-ux`  
**Scope:** Screens, HUD, input affordances, resolution/scaling, focus/navigation — not combat math or physics (Game Designer / Architect).  
**Traceability:** Maps to `REQUIREMENTS.md` R1–R11.

---

## 1. High-level architecture (UX layer)

### 1.1 Design intent

- **Readable in motion:** HUD and world feedback must stay legible during camera pan, explosions, and turn transitions (R1).
- **Two local humans, zero ambiguity:** Always show *whose turn it is*, *which mole is active*, and *which device is bound to which side* (R4, R10, R11).
- **Match variables surfaced before play:** Health and related knobs are set in a dedicated flow so players never start with hidden rules (R9).
- **Session score is honest:** “Since launch” tallies visible on title and after each match so R6 is never a black box.

### 1.2 Recommended scene graph (labels only — for architect alignment)

| State / scene id        | Purpose |
|-------------------------|---------|
| `scene_title`           | Branding, session stats, primary navigation |
| `scene_match_setup`     | Input assignment, match variables, start match |
| `scene_gameplay`        | World + HUD + pause overlay |
| `scene_round_summary`   | Optional quick recap between rounds (if needed for clarity) |
| `scene_match_results`   | Winner, per-match breakdown, return to title or rematch |

Transitions are specified in §4.

### 1.3 UX data the gameplay layer must expose (contract)

The UI does not own simulation truth; it **subscribes** to a thin view model (names are suggestions):

```text
SessionView       { gamesPlayedP1, gamesPlayedP2, gamesDrawn }
MatchView         { moleHealthMax, teamsLocked (5v5), currentRoundIndex }
TurnView          { activePlayerIndex (1|2), activeMoleSlot (1..5), phase: aim|fire|resolve }
CombatHudView     { selectedWeapon: rocket|grenade, aimAngle, power01, fusePreview? (grenade) }
RosterView        { perPlayer: [{ slot, nameOrColor, hpCurrent, hpMax, alive }] }
MapMetaView       { seedOrLabel, generationStyle }  // optional, for debug / player trust
```

Coding agent: implement these as a plain table or small module returning snapshots; UI only reads.

---

## 2. Resolution, scaling, and safe areas

### 2.1 Base logical resolution

- **Design canvas:** `1280 × 720` logical pixels (16:9). All anchors below assume this; scale uniformly with letterboxing/pillarboxing on other aspect ratios.
- **Safe margin:** Keep interactive HUD and critical text **≥ 24 px** inside each edge (48 px for “never clip” elements on ultrawide letterbox).

### 2.2 Scaling policy

- Integer scale when window is large enough; otherwise smooth scale with crisp UI via a **separate UI canvas** at base res (architect decision — UX requirement is **no blurry 9pt text** on 1080p+).
- **Minimum playable window:** 960 × 540 logical minimum; below that, show a simple “window too small” banner on `scene_title` only (optional polish).

---

## 3. Wireframes — pixel regions (1280 × 720)

### 3.1 `scene_title`

| Region (x, y, w, h) | Element |
|---------------------|---------|
| (0, 0, 1280, 720) | Full-bleed illustrated background (burrow / night garden motif) + subtle vignette |
| (440, 180, 400, 280) | **Card panel** (rounded rect, elevated shadow): title logo/wordmark |
| (440, 420, 400, 140) | **Primary actions** (vertical stack, 56 px row height, 12 px gap): `Play`, `Match options`, `How to play`, `Quit` |
| (40, 40, 400, 120) | **Session score chip:** `P1 wins | P2 wins | Draws` in one line + short caption “This session” |
| (840, 600, 400, 80) | Version / credits line (low contrast) |

**Focus order (controller):** `Play` → `Match options` → `How to play` → `Quit`. Default focus: `Play`.

### 3.2 `scene_match_setup`

Split into **columns** so two players can orient side-by-side mentally (not split-screen yet — single full-screen UI).

| Region | Element |
|--------|---------|
| (40, 32, 1200, 64) | Header: “Match setup” + breadcrumb `Title ▸ Setup` |
| (40, 112, 580, 520) | **Player 1 column** — color strip + label “Player 1” |
| (660, 112, 580, 520) | **Player 2 column** — color strip + label “Player 2” |
| (40, 656, 1200, 48) | Footer bar: `Back` (left), `Start match` (right, primary) |

**Per-player column contents (stacked blocks, ~16 px vertical gap):**

1. **Input device** (focusable row): icon + text `Keyboard + Mouse` | `Gamepad 1` … + `Reassign` / `Detect` affordance.
2. **Team preview:** horizontal row of **5 mole icons** (slots 1–5); dim if eliminated later (in-match only; here all alive).
3. **Local label:** editable **team name** optional (short max 12 chars) or fixed “Team A/B” for MVP.

**Center / full-width block (spanning both columns below row 1):**

- **Match variables** (focusable list or grid):
  - `Mole health` — numeric stepper or preset chips: e.g. 50 / 75 / 100 / 150 (R9).
  - `Wind` — Off / Low / Med / High (if supported by design; else omit).
  - `Turn timer` — Off / 30s / 60s (optional; omit if out of scope).
  - `Map style` — if multiple generators exist (ties R5).

**Controller focus model:**

- **Horizontal wrap** within a row; **vertical** between rows.
- **Player columns:** use `LB/RB` or `L1/R1` to jump between Player 1 block and Player 2 block when focus is on a column-specific control; **or** single column order P1 entire column then P2 (document default: **P1 top→bottom, then P2 top→bottom**, then match variables, then footer).

Default focus on enter: **Player 1 → Input device**.

### 3.3 `scene_gameplay` — HUD clusters

**No split-screen** for 2P local (shared camera on one map — R4, R5). HUD is **full-width overlays**.

| Region | Owner | Content |
|--------|-------|---------|
| (24, 16, 600, 88) | Shared | **Turn banner strip:** “Player 1 — Mole 3” + team color dot; animate subtle pulse on turn change |
| (656, 16, 600, 88) | Shared | **Session mini-score:** `P1 2 — P2 1` (compact) |
| (24, 104, 340, 200) | Active player only | **Weapon & aim panel:** weapon icon (rocket/grenade), angle readout, power bar (R2, R3) |
| (916, 104, 340, 200) | Shared (compact) | **Wind / round** (if applicable): wind arrow + strength |
| (24, 620, 1232, 76) | Shared | **Roster bar:** two rows or one row with two groups — 5 slots per player, each slot = portrait pip + HP bar |

**Active-mole highlight:** world-space ring + corresponding roster slot **2 px stroke** glow in team color.

**Weapon switching:** show both weapons as toggles in the weapon panel; selected weapon has filled icon, other is outline.

**Grenade-specific:** when grenade selected, show **fuse indicator** (arc or numeric seconds) next to power (UX clarity for R3).

**Rocket-specific:** show **trajectory preview** in-world (gameplay feature — UX asks for **high-contrast dashed line** ending in a small impact disc that respects terrain).

### 3.4 Pause overlay (`overlay_pause` over `scene_gameplay`)

- Dim world to 40% brightness + **modal card** centered (520 × 360):
  - `Resume` (default focus)
  - `How to play` (short)
  - `Forfeit match` (destructive, secondary style)
  - `Quit to title`

Input: **Esc** / **Start** opens pause; **B** / **Esc** closes if `Resume` focused.

### 3.5 `scene_match_results`

| Region | Element |
|--------|---------|
| (240, 80, 800, 120) | Headline: `Player 1 wins!` / `Draw` |
| (240, 220, 800, 280) | Stats list: rounds played, surviving moles, damage dealt (optional), match duration |
| (240, 520, 800, 120) | Actions: `Rematch` (same settings), `New setup`, `Title` |

Update **SessionView** immediately when this screen mounts (R6).

---

## 4. User flows (step-by-step)

### 4.1 Cold start → first match

1. Launch → `scene_title` (session scores 0-0-0).
2. Player selects `Play` or `Match options`:
   - If `Play`: use **last used** or **default** match variables and **last used** input bindings; if first run, go to `scene_match_setup` instead (first-run gate).
3. `scene_match_setup`: assign P1/P2 inputs, adjust health etc., `Start match` → loading overlay (“Digging tunnel…”) → `scene_gameplay`.

### 4.2 In-match turn loop (UX-visible)

1. Turn begins → turn banner updates; camera focuses active mole; roster highlights slot.
2. Player aims → weapon panel shows angle/power; trajectory/fuse feedback updates live.
3. Fire → brief **input lock** with “resolve” phase indicator (small text or icon) so players don’t mash.
4. Damage applied → HP bars animate; knocked mole **screen-edge flash** in team color optional.
5. Round rotation → explicit **“Next: Player 2 — Mole 1”** toast (1.2s) if turn order changes (R8).

### 4.3 Match end

1. Last team eliminated or win condition met → short celebration particle/banner (2s) → `scene_match_results`.
2. Session scores increment → visible on results and next `scene_title`.

### 4.4 Controller connect mid-setup

- If P2 selects gamepad and none connected: show **inline warning** under control + `Search for controllers` soft prompt; do not block P1 keyboard start unless both sides invalid.

---

## 5. Input mappings and interactions

### 5.1 Input profiles

Two **profiles** living in config (conceptual):

- `profile_kb_mouse_shared` — both players use one keyboard/mouse with **non-overlapping** keys.
- `profile_gamepad` — one gamepad per player (R11).

UX must show **current binding summary** on `scene_match_setup` and in `How to play`.

### 5.2 Recommended default — shared keyboard/mouse (R10)

**Design constraint:** Mouse is **single pointer**; only **active player** may aim with mouse. Inactive player’s mouse movement does nothing (show tooltip first match: “Mouse aims for active player only”).

| Action | Player 1 | Player 2 |
|--------|----------|----------|
| Aim (mouse) | When active | When active |
| Adjust aim left/right | `A` / `D` | `Left` / `Right` |
| Power up/down | `W` / `S` | `Up` / `Down` |
| Fire | `Space` | `Right Ctrl` or `Enter` (pick one; avoid `Shift` conflicts) |
| Jump / small move (if in game) | `Q` | `]` or `Numpad 0` |
| Weapon prev/next | `1` / `2` or `[` / `]` | `,` / `.` |
| Pause | `Esc` | `Esc` |

**Why:** Clear left-hand vs right-hand sides of keyboard reduces fighting for the same keys.

### 5.3 Gamepad (per player, R11)

| Action | Mapping |
|--------|---------|
| Aim | Left stick (analog) |
| Fine aim | D-Pad left/right |
| Power | Triggers or up/down on right stick (document one; triggers preferred) |
| Fire | `A` (Nintendo B / Xbox A) |
| Weapon toggle | `LB` / `RB` |
| Pause | `Start` |

**Dead zones:** UX copy should mention 15% stick dead zone in `How to play` if stick drift is common.

### 5.5 Global

- **Window close / quit** from title only in MVP; pause offers quit to title.

---

## 6. Accessibility & readability

- **Contrast:** UI text on panels ≥ 4.5:1 against panel background; turn banner text uses **dark text on light chip** or inverse with stroke.
- **Color + icon:** Never use color alone for P1/P2 — always **P1 / P2 label** + shape (circle vs square) or position (left vs right).
- **Font sizes (logical px at 1280×720):** body 18–20, HUD numerals ≥ 22, title 36+.
- **Reduce motion option** (match variables or options screen): shorten turn toasts and disable screen shake (if any).
- **In-world:** projectiles and moles use **silhouette + outline** against terrain; explosion cores are high-contrast for 1–2 frames (R1 readability).

---

## 7. File / directory structure (UX-facing assets & modules)

Greenfield repo: propose paths the coding agent can create **without** implying gameplay logic ownership.

```text
assets/
  fonts/          # licensed or OFL fonts (title + HUD)
  ui/             # nine-slice panels, icons (rocket, grenade, mole pip)
  themes/         # optional JSON: colors, corner radii, spacing tokens
src/              # (architect-defined; UX-related suggestions only)
  ui/
    screens/      # title, match_setup, gameplay_hud, results, pause — by scene id
    widgets/      # focus list, stepper, roster_bar, turn_banner
    theme.lua     # spacing, colors (if not JSON)
  input/
    bindings.lua  # default tables + save/load (behavior owned by coding agent)
```

**Modify later:** only `REQUIREMENTS.md` today — no edits required by UX agent.

---

## 8. Component breakdown (responsibilities)

| Component | Responsibility |
|-----------|----------------|
| `TurnBanner` | Reads `TurnView`; animates change; never blocks input |
| `RosterBar` | Renders 5+5 slots; HP bars; click/hover optional for MVP |
| `WeaponPanel` | Weapon icons, angle, power, grenade fuse; listens to local input preview only |
| `MatchVariablesForm` | Binds to match config model; validates ranges |
| `InputAssignmentRow` | Device pickers; shows conflict warnings |
| `SessionScoreChip` | Reads `SessionView`; used on title + results |
| `PauseMenu` | Modal focus trap; resume/forfeit/title |
| `HowToPlayOverlay` | Scrollable text + pictograms for KB and pad |

---

## 9. Dependencies & technology (rationale)

- **LÖVE2D 11.x+:** standard for this stack; UI built with `love.graphics` + optional lightweight immediate-mode helper (architect picks library; UX has no dependency on which).
- **Fonts:** one **display** face + one **UI** face; avoid more than two families.
- **Save format for bindings:** human-readable (e.g. JSON in `%appdata%`) — out of UX doc except to require **persistence of last setup** for fast `Play`.

---

## 10. Implementation notes for Coding Agent

1. **Single active pointer:** When `TurnView.activePlayerIndex` maps to a profile using mouse, enable mouse capture for aim; otherwise ignore mouse move clicks except UI.
2. **Focus stack:** Title → Setup use keyboard/gamepad focus; gameplay uses **HUD focus only when** in menu mode (pause); during aim, focus is “in world.”
3. **HUD z-order:** Pause > toasts > HUD > world.
4. **Roster bar and 5 moles (R7):** fixed slot index equals mole identity for UI stability across rounds (R8).
5. **Session score (R6):** increment on `scene_match_results` confirm; draws explicit third counter.
6. **No implementation in this doc:** all Lua filenames are suggestions; align names with merged architecture doc.

---

## 11. Structured handoff JSON

```json
{
  "userFlows": {
    "coldStart": [
      "Title → (first run) Match setup → Gameplay",
      "Title → (returning) Play uses last bindings + vars → Gameplay"
    ],
    "inMatch": [
      "Turn start → HUD highlight active mole → aim/fire → resolve → HP update → turn toast → next turn"
    ],
    "matchEnd": [
      "Win condition → short banner → Match results → session scores update → Rematch | Setup | Title"
    ]
  },
  "wireframes": {
    "baseResolution": [1280, 720],
    "scenes": ["scene_title", "scene_match_setup", "scene_gameplay", "scene_match_results"],
    "hudRegions": {
      "turnBanner": [24, 16, 600, 88],
      "sessionScore": [656, 16, 600, 88],
      "weaponPanel": [24, 104, 340, 200],
      "rosterBar": [24, 620, 1232, 76]
    }
  },
  "interactions": {
    "keyboardMouseShared": "see_section_5.2_table",
    "gamepad": "see_section_5.3_table",
    "pause": ["Esc", "Start"]
  },
  "accessibility": {
    "contrast": "UI text >= 4.5:1; P1/P2 labeled with text + secondary cue",
    "fonts": "body 18-20px logical, HUD >= 22px",
    "inWorld": "projectile/mole silhouette + outline; brief hi-contrast explosion core"
  },
  "recommendations": [
    "Optional round_summary scene if turn rotation is hard to follow",
    "Reduce motion toggle in match options",
    "Trajectory preview mandatory for rocket; fuse readout mandatory for grenade"
  ]
}
```

---

## 12. Requirements crosswalk

| ID | UX coverage |
|----|-------------|
| R1 | Visual style, HUD polish, in-world readability (§6, §3.3) |
| R2–R3 | Weapon panel, trajectory/fuse (§3.3) |
| R4 | 2P labels, turn clarity, setup columns (§3.2–3.3) |
| R5 | Optional map label in HUD (§1.3 `MapMetaView`) |
| R6 | Session chip + results (§3.1, §3.5, §10.5) |
| R7 | Roster 5+5 (§3.3) |
| R8 | Turn banner + next-turn toast (§4.2) |
| R9 | Match variables block (§3.2) |
| R10 | Shared KB/Mouse table (§5.2) |
| R11 | Gamepad table + assignment (§3.2, §5.3) |

---

*End of love-ux design document.*
