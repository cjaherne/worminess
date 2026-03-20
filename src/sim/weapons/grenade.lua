--- Grenade: arcing shot, full gravity, timed fuse, terrain bounce + unstick (see `world.integrate_projectiles`).
local defaults = require("config.defaults")

local M = {}

function M.spawn(world, mole, ang, power)
  local wdef = defaults.weapon
  local sp = 280 * (0.5 + 0.5 * power) * wdef.grenade_speed_mul
  local vx = math.cos(ang) * sp
  local vy = math.sin(ang) * sp
  world.projectiles[#world.projectiles + 1] = {
    kind = "grenade",
    x = mole.x + math.cos(ang) * (mole.r + 4),
    y = mole.y + math.sin(ang) * (mole.r + 4),
    vx = vx,
    vy = vy,
    owner = mole.player,
    fuse = wdef.grenade_fuse,
    dead = false,
  }
end

return M
