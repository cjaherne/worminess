local defaults = require("config.defaults")

local M = {}

function M.spawn(world, mole, ang, power)
  local wdef = defaults.weapon
  local sp = wdef.rocket_speed * (0.45 + 0.55 * power)
  local vx = math.cos(ang) * sp
  local vy = math.sin(ang) * sp
  world.projectiles[#world.projectiles + 1] = {
    kind = "rocket",
    x = mole.x + math.cos(ang) * (mole.r + 6),
    y = mole.y + math.sin(ang) * (mole.r + 6),
    vx = vx,
    vy = vy,
    owner = mole.player,
    dead = false,
  }
end

return M
