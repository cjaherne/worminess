# Stage: design (game-designer)

## Summary






Adding an explicit one-line override for architecture docs and updating the repo baseline to reference `src/sim/` (including `turn_state.lua`).









Here’s what was updated in `.pipeline/game-designer-design.md`:

### Normative override (overseer)

Under **Turn model**, the existing normative paragraph now ends with an explicit sentence:

- If merged **architecture** text (e.g. root `DESIGN.md`, LÖVE Architect) **conflicts** with this Turn Model, **this pseudocode wins** for player/mole rotation, and **`src/sim/turn_state.lua`** (and anything that drives it) should follow the pseudocode, not the conflicting wording.

### Repo baseline

The header **Repo baseline** line now reflects the current tree: `src/sim/turn_state.lua`, `terrain.lua`, `terrain_gen.lua`, `physics.lua`, `damage.lua`, and `src/config.defaults.lua`, in addition to the data modules already listed.

No implementation files were changed—design doc only.

## Files Created/Modified
- .pipeline/game-designer-design.md
