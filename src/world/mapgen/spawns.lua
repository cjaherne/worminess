local C = require("data.constants")

local M = {}

local function surface_y_at(terrain, wx)
  local cell = terrain.cell
  local first_solid_cy = nil
  for cy = 0, terrain.gh - 1 do
    local wy = (cy + 0.5) * cell
    if terrain:isSolidPixel(wx, wy) then
      first_solid_cy = cy
      break
    end
  end
  if not first_solid_cy then
    return terrain.world_h * 0.45
  end
  local top_y = first_solid_cy * cell
  return top_y - C.MOLE_RADIUS - 2
end

function M.place_team_spawns(terrain, map, rng)
  local sp1, sp2 = {}, {}
  local margin = 90
  local spread = 52
  for i = 1, C.MOLES_PER_TEAM do
    local wx1 = margin + (i - 1) * spread * 0.85 + rng:random(-8, 8)
    local wx2 = terrain.world_w - margin - (i - 1) * spread * 0.85 + rng:random(-8, 8)
    wx1 = math.max(40, math.min(terrain.world_w * 0.42, wx1))
    wx2 = math.max(terrain.world_w * 0.58, math.min(terrain.world_w - 40, wx2))
    sp1[i] = { x = wx1, y = surface_y_at(terrain, wx1) }
    sp2[i] = { x = wx2, y = surface_y_at(terrain, wx2) }
  end
  map.spawn_team1 = sp1
  map.spawn_team2 = sp2
end

return M
