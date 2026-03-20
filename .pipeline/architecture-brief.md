# Architecture Brief

Tech stack: Node.js
Files: 47

## File Map

### ./
- **README.md** (80 lines) — Provides an overview and instructions for the Moles game project, including versioning and session loop details.
- **conf.lua** (13 lines) — Configures the LÖVE game settings such as window size, title, and version.
- **main.lua** (65 lines) — Sets up the main game loop and delegates LÖVE callbacks to the app module.
- **package.json** (10 lines) — Defines project metadata and includes a build script for automated checks.

### spec/
- **damage_spec.lua** (39 lines) — Contains unit tests for the damage mechanics in the game, ensuring correct damage application and friendly fire rules.
- **match_settings_spec.lua** (42 lines) — Tests the match settings module to ensure defaults and validation rules are functioning correctly.
- **mole_spec.lua** (19 lines) — Tests the mole spawning functionality to ensure teams are created correctly with the expected properties.
- **physics_spec.lua** (38 lines) — Tests the physics module to verify terrain collision detection works as intended.
- **session_scores_spec.lua** (19 lines) — Tests the session scores module to ensure match outcomes are recorded accurately.
- **spec_helper.lua** (74 lines) — Provides helper functions and stubs for testing game modules outside of the LÖVE environment.
- **terrain_gen_spec.lua** (21 lines) — Tests the terrain generation module to ensure it produces consistent and valid terrain based on a seed.
- **terrain_spec.lua** (32 lines) — Tests the terrain module to ensure pixel-to-grid mapping and solid cell detection are accurate.
- **timer_spec.lua** (32 lines) — Tests the timer utility to ensure it functions correctly for timing events in the game.
- **turn_state_spec.lua** (88 lines) — Tests the turn state management to ensure player turns are handled correctly.
- **vec2_spec.lua** (41 lines) — Tests the vector utility functions for length calculation and normalization.
- **weapons_registry_spec.lua** (11 lines) — Tests the weapons registry to ensure weapon slots and names are correctly defined.

### src/
- **app.lua** (161 lines) — Manages the application state, including scene transitions and asset loading.
- **config.defaults.lua** (37 lines) — Defines default configuration settings for the game, including physics and gameplay parameters.

### src/audio/
- **sfx.lua** (60 lines) — Handles the creation of procedural sound effects for the game.

### src/data/
- **match_settings.lua** (61 lines) — Manages match settings, including defaults and validation for gameplay rules.
- **session_scores.lua** (37 lines) — Tracks and manages the scores and outcomes of matches played.

### src/input/
- **gamepad.lua** (85 lines) — Handles input from gamepads, including axis movement and button presses.
- **input_manager.lua** (55 lines) — Manages input from both keyboard and gamepad, consolidating actions for players.
- **keyboard_mouse.lua** (86 lines) — Handles input from keyboard and mouse for a shared control scheme for two players.

### src/render/
- **camera.lua** (29 lines) — Manages the camera's position and movement to follow the active mole in the game.
- **mole_draw.lua** (168 lines) — Handles the drawing of mole sprites, including shadows and visual effects.
- **terrain_draw.lua** (31 lines) — Handles the rendering of the terrain based on its properties and state.

### src/scenes/
- **match_end.lua** (73 lines) — Displays the match end screen, showing scores and allowing players to proceed.
- **match_setup.lua** (238 lines) — Manages the match setup scene, allowing players to configure match settings.
- **menu.lua** (145 lines) — Handles the main menu scene, allowing players to navigate options and start the game.
- **pause.lua** (148 lines) — Game scene module (pause)
- **play.lua** (133 lines) — Game scene module (play)

### src/sim/
- **damage.lua** (34 lines) — Source file (.lua)
- **mole.lua** (28 lines) — Source file (.lua)
- **physics.lua** (113 lines) — Source file (.lua)
- **terrain.lua** (76 lines) — Source file (.lua)
- **terrain_gen.lua** (131 lines) — Source file (.lua)
- **turn_state.lua** (106 lines) — State management
- **world.lua** (263 lines) — Source file (.lua)

### src/sim/weapons/
- **grenade.lua** (24 lines) — Source file (.lua)
- **registry.lua** (7 lines) — Source file (.lua)
- **rocket.lua** (24 lines) — Source file (.lua)

### src/ui/
- **hud.lua** (282 lines) — Source file (.lua)

### src/util/
- **gamepad_menu.lua** (49 lines) — Source file (.lua)
- **timer.lua** (30 lines) — Source file (.lua)
- **vec2.lua** (35 lines) — Source file (.lua)
- **viewport.lua** (26 lines) — Source file (.lua)
