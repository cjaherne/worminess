# Moles

Local 2-player **Worms**-style artillery game (moles theme). Built with **LÖVE 11.4** (compatible with LÖVE 11.x).

## Run

From the project root:

```bash
love .
```

Install LÖVE: [https://love2d.org/](https://love2d.org/)

## Layout

- `main.lua` — sets `package.path`, loads `bootstrap`, registers callbacks via `src/app.lua`
- `conf.lua` — window (1280×720 default, resizable), joystick module on
- `src/scene_manager.lua` — scene stack (`push` / `pop` / `replace`)
- `src/scenes/` — `boot`, `main_menu`, `play` (match runtime to be expanded)

## Requirements

See `DESIGN.md` for the full product and architecture checklist.
