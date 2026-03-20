# Moles

Local two-player, turn-based artillery game (Worms-style) built with **LÖVE 11.4**.

## Run

1. Install [LÖVE 11.4](https://love2d.org/) (or a compatible 11.x build).
2. From this project root:

```bash
love .
```

On Windows, you can drag the project folder onto `love.exe` or set `love` on your PATH.

## Controls

### Shared keyboard + mouse

- **Mouse** (active player only): aim; **left click** fires.
- **Player 1:** `A`/`D` move, `W` jump, `Q`/`E` aim, `Z`/`X` power, `F` fire, `G` end turn, `1`/`2` rocket/grenade, `Tab` cycle weapon.
- **Player 2:** arrows move, `Up`/`Right Shift` jump, `[` / `]` aim, `I`/`K` power, `;` / `Enter` / numpad `Enter` / `Right Ctrl` fire, `Backspace` or `\` end turn, `,` / `.` weapons, `-`/`=` cycle weapon.

### Two gamepads (Match setup → input mode)

Connect two controllers. **Player 1** uses the first joystick in `love.joystick.getJoysticks()`, **Player 2** the second.

- Left stick: move · **A**: jump · **Right stick**: aim · **Triggers**: power · **B**: fire · **LB/RB**: cycle weapon · **Y**: end turn · **Start**: pause / resume pause menu.

### Menus (any connected gamepad)

Uses the **first** gamepad in `love.joystick.getJoysticks()`: **D-pad** or **left stick** to move focus (with short cooldown), **A** to confirm, **B** to go back (e.g. setup → title, pause → resume, results → title). **Match results:** **X** = new setup.

### Audio

Short **procedural** sounds for weapon fire, explosions, and UI (`src/audio/sfx.lua`). Add files under `assets/audio/` later if you want recorded SFX.

## HUD (in match)

- **Top left:** whose turn it is, team, active mole **slot**, current mole **HP**, phase hint, optional **turn timer**.
- **Top right:** **session wins** for P1 / P2 and **draws** (since launch), plus total matches finished.
- **Lower panels:** weapon selection, aim angle, power; wind readout; **roster** with HP bars and numeric HP per slot (active mole outlined).
- **Turn handoff:** brief **toast** when the active player or mole slot changes after a turn.

## Project layout

- `main.lua` / `conf.lua` — entry and window (1280×720 logical, resizable).
- `src/app.lua` — scene stack, assets, lifecycle.
- `src/scenes/` — menu, match setup, play, pause, match end.
- `src/sim/` — terrain, physics, moles, weapons, turn state, world.
- `src/input/` — shared keyboard/mouse and dual gamepad routing.
- `src/audio/` — lightweight procedural SFX.
- `src/util/gamepad_menu.lua` — menu navigation helper.
- `assets/sprites/` — mole, weapon, and HUD art (see `ASSETS.md`).

## Requirements

Gameplay targets **R1–R11** in `REQUIREMENTS.md`; design authority is `DESIGN.md`. See `CODING_NOTES.md` for intentional deviations and environment notes.
