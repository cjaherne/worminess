local defaults = require("config.defaults")

local M = {}
M.__index = M

function M.new(cell, gw, gh, solid_fn)
  local self = setmetatable({
    cell = cell or defaults.cell,
    gw = gw,
    gh = gh,
    solid = {},
    dirty = true,
  }, M)
  for x = 1, gw do
    self.solid[x] = {}
    for y = 1, gh do
      self.solid[x][y] = solid_fn and solid_fn(x, y) or false
    end
  end
  return self
end

function M:pixel_to_grid(px, py)
  local c = self.cell
  local gx = math.floor(px / c) + 1
  local gy = math.floor(py / c) + 1
  return gx, gy
end

function M:in_grid(gx, gy)
  return gx >= 1 and gx <= self.gw and gy >= 1 and gy <= self.gh
end

function M:is_solid_px(px, py)
  local gx, gy = self:pixel_to_grid(px, py)
  if not self:in_grid(gx, gy) then
    return gy > self.gh
  end
  return self.solid[gx][gy]
end

function M:is_solid_grid(gx, gy)
  if not self:in_grid(gx, gy) then
    return gy > self.gh
  end
  return self.solid[gx][gy]
end

function M:carve_circle(px, py, radius_px)
  local c = self.cell
  local r2 = radius_px * radius_px
  local gx0, gy0 = self:pixel_to_grid(px - radius_px, py - radius_px)
  local gx1, gy1 = self:pixel_to_grid(px + radius_px, py + radius_px)
  for gx = math.max(1, gx0 - 1), math.min(self.gw, gx1 + 1) do
    for gy = math.max(1, gy0 - 1), math.min(self.gh, gy1 + 1) do
      local cx = (gx - 0.5) * c
      local cy = (gy - 0.5) * c
      local dx, dy = cx - px, cy - py
      if dx * dx + dy * dy <= r2 then
        self.solid[gx][gy] = false
      end
    end
  end
  self.dirty = true
end

function M:width_px()
  return self.gw * self.cell
end

function M:height_px()
  return self.gh * self.cell
end

return M
