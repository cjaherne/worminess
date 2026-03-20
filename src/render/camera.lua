local LW, LH = 1280, 720

local M = {}
M.__index = M

function M.new()
  return setmetatable({ x = LW * 0.5, y = LH * 0.5 }, M)
end

function M:follow(world, dt)
  local m = world.turn:active_mole(world.moles)
  if m then
    local k = math.min(1, 7 * dt)
    self.x = self.x + (m.x - self.x) * k
    self.y = self.y + (m.y - self.y) * k
  end
  local tr = world.terrain
  local hw, hh = LW * 0.5, LH * 0.5
  self.x = math.max(hw, math.min(tr:width_px() - hw, self.x))
  self.y = math.max(hh, math.min(tr:height_px() - hh, self.y))
end

--- Logical mouse (1280×720 layer) → world coordinates given camera center.
function M:logical_to_world(lx, ly)
  return lx - LW * 0.5 + self.x, ly - LH * 0.5 + self.y
end

return M
