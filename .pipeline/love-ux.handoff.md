# Stage: design (love-ux)

## Summary

Reading `.pipeline/love-ux-design.md` and key implementation files to align the UX design with the codebase and DESIGN.md anchors.



















Updating `.pipeline/love-ux-design.md` to align with the merged `DESIGN.md` anchor index, the implemented UI (`theme`, `layout`, `play_hud`), and the map-regeneration cadence.
































































## Summary

Updated **`.pipeline/love-ux-design.md`** so it matches the **merged `DESIGN.md` anchor index**, the **Overseer handoff rules**, and the **current repo** (`app`, `scene_manager`, `scenes/*`, `ui/theme`, `layout`, `focus_stack`, `hud/play_hud`, `README` / `CODING_NOTES` behaviour).

### Handoff / anchors
- Replaced the old “§3.1 UX table” style with **exact `DESIGN.md` section titles**: **MatchConfig — single consolidated schema**, **Session stats definition**, **Map regeneration cadence**, **UX — §5.3 `match_setup`**, **requirementsChecklist — UX**, **UX — §10 Structured handoff JSON**.
- Stated clearly that **`.pipeline/love-ux-design.md`** stays **canonical** for depth **when `DESIGN.md` is short** (§5–§7, §3.2 widgets, §10 here), with conflict order: **`DESIGN.md`** → **`src/game/*.lua`** → code.

### Codebase alignment
- **§1.3** documents real scaling: **`theme.begin_draw` / `end_draw`**, **`clear_void`**, **`layout.screen_to_logical`**.
- **§2** split into **2.1 Implemented** vs **2.2 Optional** (`widgets/`, `compose/` not in tree).
- **§3.3** rewritten around **`play_hud.draw(ctx)`**: `round_wins`, `toast_text`, `grenades` fuse, `turn_time_left`, session vs round labels; **Map regeneration cadence** called out for copy/toasts.
- **§4** reflects **`theme`**, **`layout`**, **`focus_stack`**, **`play_hud`** (no separate `toast` module).
- **§5.4** is a **implementation-faithful** layout table (coordinates from **`play_hud.lua`**).
- **§5.6** notes interstitial is **implemented in `play_hud`**, driven by **`ctx.toast_text`**.
- **§6.2** matches **current hint strings** + **`README.md`** (wheel power, pads).
- **§9** is tuned to the existing stack (**`ctx`**, scaling, **`bump_match_win`**, hints vs **`bindings.lua`**).
- **§10 JSON** adds **round terrain regen** per **`DESIGN.md` — Map regeneration cadence**.
- Closing line notes the spec is **design-only** but **code may already exist**.

**`DESIGN.md`** was not modified (per pipeline rule).

## Files Created/Modified
- .pipeline/love-ux-design.md
