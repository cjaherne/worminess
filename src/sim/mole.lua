local defaults = require("config.defaults")

local M = {}

function M.spawn_team(spawns, player, max_hp)
  local list = {}
  for i = 1, #spawns do
    local s = spawns[i]
    list[#list + 1] = {
      x = s.x,
      y = s.y,
      vx = 0,
      vy = 0,
      r = defaults.mole_radius,
      hp = max_hp,
      max_hp = max_hp,
      player = player,
      slot = i,
      facing = player == 1 and 1 or -1,
      alive = true,
      grounded = false,
    }
  end
  return list
end

return M
