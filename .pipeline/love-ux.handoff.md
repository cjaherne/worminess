# Stage: design (love-ux)

## Summary

Aligning `.pipeline/love-ux-design.md` with the implemented UI, input, and assets. Reading key source files.





























Rewriting `.pipeline/love-ux-design.md` to match the implemented UI (`src/ui/hud.lua`, scenes, input) and asset manifest, while preserving merge-ready flows, input §5–6, and the component list.




## Summary

**Updated only** `.pipeline/love-ux-design.md` (per pipeline rules, **not** `DESIGN.md`). The doc now matches the **current game build** and stays merge-ready for the orchestrator.

### What changed

- **§0 / §1:** Points at real modules: `src/app.lua`, `src/ui/hud.lua`, `src/scenes/*.lua`, `src/util/viewport.lua`, `src/util/gamepad_menu.lua`, `src/input/*`, `ASSETS.md`, and where **`session_scores.record_match_outcome`** runs (play win vs forfeit).
- **§3 Wireframes:** **Measured regions** from `hud.lua` / `menu.lua` / `match_setup.lua` / `play.lua` / `pause.lua` / `match_end.lua` (e.g. turn banner `20,10,600,96`, weapon panel `20,114,328,200`, help strip `24,532,1232,64`, roster `20,604,1240,108`, toast `400,312,480,56`). **Match setup** is documented as the **single vertical list** (not the older two-column concept), with optional polish called out.
- **§4 Flows:** Includes **Start-button pause** via `app.gamepadpressed`, **forfeit confirm** in `pause.lua`, **match_end** actions (**S** / **X** for new setup), and **mermaid** state diagram.
- **§5 Input:** Tables match **`keyboard_mouse.lua`** and **`gamepad.lua`** (e.g. P1 **F** fire, **W/Space** jump; P2 **; / RCtrl / Enter / kpenter** fire; **20%** stick deadzone; mouse **left** = fire for active player).
- **§6–§8:** Accessibility, file tree, and **component → code** mapping (`draw_turn_banner`, `draw_help_strip`, etc.).
- **§11 JSON:** Regions and flows updated to the implementation.

The header **merge note** tells the orchestrator to copy **§2–§8**, **§11**, and **§12** into `DESIGN.md` so the merged doc stays self-contained (title/setup/HUD/pause/results, flows, input, accessibility, components).

## Files Created/Modified
- .pipeline/game-designer-design.md
- .pipeline/love-architect-design.md
- .pipeline/love-ux-design.md
