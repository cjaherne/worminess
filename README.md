# Moles

Local 2-player **Worms**-style artillery game (moles theme). Built for **LÖVE 11.4** (works with 11.x).

## Run

From the project root:

```bash
love .
```

Install LÖVE: [https://love2d.org/](https://love2d.org/)

## Tests

Unit tests use **busted** (LuaJIT + LuaRocks). From the project root run `busted`. See [TESTING.md](TESTING.md) for setup on Windows (compiler for native LuaRocks deps) and details.

## Flow

1. **Boot** → **Main menu** → **Match setup** (all `MatchConfig` fields, dual **Ready**, validate).
2. **Play** — procedural map **every round**, alternating turns, **rocket** + **grenade**, wind, optional turn timer.
3. **Pause** (Esc / Start) — resume, restart, setup, menu.
4. **Round / match end** overlays — continue rounds, **Rematch** uses `session.last_match_config`, session **match wins** only on full match victory.

## Polish (audio / VFX / input)

- **SFX:** synthesized at startup (`src/audio/sfx.lua`) — fire whoosh, grenade pop, explosion noise+thump, tiny UI blip.
- **VFX:** explosion rings + sparks + muzzle puffs + rocket exhaust puffs, camera shake, match-end confetti on the **`game_over`** overlay (`match_end` only).
- **Input:** smoothed left-stick aim in **`dual_gamepad`**, **LB/RB or analog triggers** to charge power, **Start** opens pause from **any** pad; dead moles during **aim** reassign the active slot or end the round if a team is wiped.
- **`shared_kb` extras:** **mouse wheel** adjusts shot power during aim; **optional gamepads** follow the active player (P1 → first pad, P2 → second pad or the only pad on P2’s turn). See `CODING_NOTES.md`.
- **Direct hits:** rockets (and grenades) **detonate on living mole overlap**, not only on terrain.

## Layout (src)

| Area | Role |
|------|------|
| `src/scenes/` | `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over` |
| `src/input/` | `bindings`, `devices`, `stick` (smooth aim + triggers), `input_state` (stub) |
| `src/systems/` | `world_update`, `weapons`, `explosions`, `turn_resolver`, `vfx` |
| `src/audio/` | `sfx` — procedural blips (no external sound files) |
| `src/ui/` | `theme`, `layout`, `focus_stack`, `hud/play_hud` |
| `src/world/mapgen/` | `generate` each round via `game/map_seed` |
| `src/game/` | `match_config`, `session`, `turn_state`, `roster`, `map_seed` |

## Requirements

See `DESIGN.md` for the full checklist and UX contracts.
