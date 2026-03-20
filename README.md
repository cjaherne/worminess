# Moles

Local 2-player **Worms**-style artillery game (moles theme). Built for **LÖVE 11.4** (works with 11.x).

## Run

From the project root:

```bash
love .
```

Install LÖVE: [https://love2d.org/](https://love2d.org/)

## Flow

1. **Boot** → **Main menu** → **Match setup** (all `MatchConfig` fields, dual **Ready**, validate).
2. **Play** — procedural map **every round**, alternating turns, **rocket** + **grenade**, wind, optional turn timer.
3. **Pause** (Esc / Start) — resume, restart, setup, menu.
4. **Round / match end** overlays — continue rounds, **Rematch** uses `session.last_match_config`, session **match wins** only on full match victory.

## Layout (src)

| Area | Role |
|------|------|
| `src/scenes/` | `boot`, `main_menu`, `match_setup`, `play`, `pause`, `game_over` |
| `src/input/` | `bindings`, `devices` (dual pad assign), `input_state` (stub) |
| `src/systems/` | `world_update`, `weapons`, `explosions`, `turn_resolver` |
| `src/ui/` | `theme`, `layout`, `hud/play_hud` |
| `src/world/mapgen/` | `generate` each round via `game/map_seed` |
| `src/game/` | `match_config`, `session`, `turn_state`, `roster`, `map_seed` |

## Requirements

See `DESIGN.md` for the full checklist and UX contracts.
