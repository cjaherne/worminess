## Deviations

- **Audio:** All sounds are **procedural** (`src/audio/sfx.lua`, built in `love.load`) — no shipped `.ogg` assets. Timbral quality is “arcade placeholder” by design.
- **Analog triggers:** Charge power reads `triggerleft` / `triggerright` when the driver exposes them; some controllers map triggers differently — **shoulder buttons remain the reliable fallback**.
- **Turn timer expiry:** When the turn clock hits zero, the active mole auto-fires with at least **0.35** power (and current charge if higher). The design mentioned documenting auto-end policy in UI; this behaviour is implemented but not surfaced as a separate tooltip beyond the timer label.
- **Shared keyboard + gamepad mix:** In **`shared_kb`** mode, only keyboard/mouse routing is guaranteed for both players per spec. Gamepads are not additionally merged into shared mode (dual mode uses **`dual_gamepad`** exclusively).
- **Round toast vs turn:** The full-width interstitial toast runs at **each round start** (after mapgen). **Individual turns** after `advance_turn` go straight to **aim** without a second toast, to keep pacing snappy.

## Issues Found

- None blocking for this slice; confirm with playtests whether knockback strength (`explosions.apply` impulse scaling) needs tuning relative to `weapons.lua` values.

## Suggestions

- Add a tiny on-screen legend in **match_setup** for gamepad **X/Y** ready chips (already in footer for keys **1/2**).
- Consider sub-stepping grenades the same way as rockets if high-speed tunnels appear.
- Optional: persist session stats with `love.filesystem` (design v1 is RAM-only).
