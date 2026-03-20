# Stage: design (core-code-designer)

## Summary

Reading `DESIGN.md`, `REQUIREMENTS.md`, and key references to produce a revised design that reflects the implemented state and incorporates the feedback.














Writing a revised `DESIGN.md` that records the completed `config.defaults` fix, merges feedback into a single normative spec (controls, gamepad, audio, weapons), and maps product requirements to the codebase.




### Revised `DESIGN.md`

The root **`DESIGN.md`** is rewritten so it works as a **single normative blueprint** for both the finished **`config.defaults`** work and the rest of **Moles**, and it **folds in your feedback** explicitly.

**What’s in it now**

1. **`config.defaults` (§2, §16–17)** — Still documents LÖVE’s dot→path resolution and **`src/config/defaults.lua`**, but framed as **implemented** with maintenance rules (`release-check.mjs`, `spec_helper`, no flat `config.defaults.lua`).

2. **Normative controls (§5)** — One table for **shared KB+M** aligned with ```57:82:src/input/keyboard_mouse.lua``` (including **Z/X**, **I/K**, and **P2 fire** on `return` / `kpenter` / etc.), plus **§5.1.1** calling out the **Enter vs future UI** risk. **Dual gamepad** matches ```46:80:src/input/gamepad.lua``` (**A** jump, **B** fire, **Y** end turn, **LB/RB** cycle, triggers = power). States clearly that this **overrides** older UX text that disagreed.

3. **Deviations / as-built (§12, §7)** — Full rocket + grenade, hybrid keyboard rationale, gamepad vs “RT fire” docs, procedural **`sfx.lua`** until real audio.

4. **Architecture & file map (§1, §8–11)** — Scene flow, layers, HUD/polish summary, terrain/combat pointers, dependency table.

5. **Turn model (§3)** — Cites **`turn_state.lua`** (`advance_after_turn`, `sync_slots_to_living`, `end_turn`) and the play-scene toast (no `round_end` scene).

6. **Traceability (§15)** — **`REQUIREMENTS.md`** R1–R3 plus the **R1–R11 product** table you supplied, mapped to concrete paths.

7. **Suggestions (§13)** — Round-end scene, real audio, `keymaps_shared.lua`, RT-edge fire, terrain canvas cache.

8. **Coding Agent notes (§14)** — Concrete guardrails (controls + Enter, release check, weapons/registry/defaults).

`CODING_NOTES.md` remains the day-to-day drift log; **`DESIGN.md`** is now the place that **locks** control layout and ties **meta** and **product** requirements together.

## Files Created/Modified
- DESIGN.md
