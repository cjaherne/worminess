-- Moles (Worms-style) — entry; gameplay lives under src/
-- When launched with `love .` from the project folder, `src/` resolves from the game root.
package.path = package.path .. ";src/?.lua;src/?/init.lua"

require("bootstrap")
local app = require("app")
app.register()
