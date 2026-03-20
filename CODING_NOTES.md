## Deviations

- **Main menu → play:** For sub-task 1 (boot / main menu / play only), **Local match** goes straight to the **play** shell. Unified `DESIGN.md` user flow is **main_menu → match_setup → play**; `match_setup` should be inserted when that scene is implemented so `match_config.validate` and dual Ready run before a real match.
- **Automated run check:** A short headless run was not reliable from this environment (windowed `love .` was started then stopped). Syntax and wiring were reviewed statically; please run `love .` locally once to confirm.

## Issues Found

- None in `DESIGN.md` for this slice.

## Suggestions

- When **match_setup** lands, replace the direct **main_menu → play** transition and keep **play** as the sole owner of match runtime (per architect checklist).
