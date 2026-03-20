# Stage: design (game-designer)

## Summary

Exploring the codebase to align the design with existing structure, then writing `.pipeline/game-designer-design.md`.









Workspace is empty (no Lua sources yet). Writing a self-contained game design that references `.pipeline/architecture-brief.md` as the current state and guides the coding agent.




Here’s what was delivered.

## Summary

**Written:** `.pipeline/game-designer-design.md` — full game-design spec for a **LÖVE 11.4** moles/Worms-style game.

Because the repo is still empty (no Lua yet; `.pipeline/architecture-brief.md` shows 0 files), the doc is a **standalone blueprint** and only **hints** at modules (`src/systems/turn.lua`, `weapons.lua`, etc.) so it stays aligned with the handoff: **Architect** owns the real tree, **UX** owns look/HUD.

The spec includes:

- **`requirementsChecklist`** — one bullet per stated requirement (theme, core Worms mechanics, rocket + grenade, 2P local, proc maps, session scores, 5 moles per player, player + mole rotation, match variables like HP, keyboard+mouse and/or controllers).
- **`mechanics`** — turn model, teams, weapons, explosions, terrain, damage/knockback, wind, match variables, scoring.
- **`controls`** — dual keyboard layout examples, gamepad mapping, mouse-as-optional, `InputRouter` / intent idea.
- **`gameLoop`** — menu → setup → play → match over, update/draw order.
- **`fileStructure`** / **components** / **scenes** / **assets** / **persistence** / **`implementationOrder`** — actionable for the coder.
- **Pseudocode** for explosions and rotation only (behavioural, not ship-ready Lua).

No `.lua` or other implementation files were added.

## Files Created/Modified
- .pipeline/game-designer-design.md
