local C = require("data.constants")

local M = {}
M.__index = M

local DIRT = { 0.45, 0.32, 0.22, 1 }
local DIRT2 = { 0.38, 0.26, 0.18, 1 }

function M.new(world_w, world_h, cell)
  cell = cell or C.CELL
  local gw = math.floor(world_w / cell)
  local gh = math.floor(world_h / cell)
  local self = setmetatable({
    world_w = world_w,
    world_h = world_h,
    cell = cell,
    gw = gw,
    gh = gh,
    solid = {},
    imageData = nil,
    image = nil,
    dirty = true,
  }, M)
  for i = 1, gw * gh do
    self.solid[i] = false
  end
  return self
end

function M:_i(cx, cy)
  return cy * self.gw + cx + 1
end

function M:clear_all_air()
  for i = 1, self.gw * self.gh do
    self.solid[i] = false
  end
  self.dirty = true
end

function M:setSolid(cx, cy, v)
  if cx < 0 or cy < 0 or cx >= self.gw or cy >= self.gh then
    return
  end
  local i = self:_i(cx, cy)
  if self.solid[i] ~= v then
    self.solid[i] = v
    self.dirty = true
  end
end

function M:isSolidCell(cx, cy)
  if cx < 0 or cy < 0 or cx >= self.gw or cy >= self.gh then
    return true
  end
  return self.solid[self:_i(cx, cy)]
end

function M:worldToCell(wx, wy)
  return math.floor(wx / self.cell), math.floor(wy / self.cell)
end

function M:isSolidPixel(wx, wy)
  local cx, cy = self:worldToCell(wx, wy)
  return self:isSolidCell(cx, cy)
end

function M:isSolidCircle(wx, wy, radius)
  local cs = math.ceil(radius / self.cell) + 1
  local cx, cy = self:worldToCell(wx, wy)
  for dy = -cs, cs do
    for dx = -cs, cs do
      local gx, gy = cx + dx, cy + dy
      if self:isSolidCell(gx, gy) then
        local px = (gx + 0.5) * self.cell
        local py = (gy + 0.5) * self.cell
        local ddx, ddy = px - wx, py - wy
        if ddx * ddx + ddy * ddy <= (radius + self.cell * 0.71) ^ 2 then
          return true
        end
      end
    end
  end
  return false
end

function M:carveCircle(wx, wy, radius)
  local cx0, cy0 = self:worldToCell(wx - radius, wy - radius)
  local cx1, cy1 = self:worldToCell(wx + radius, wy + radius)
  local r2 = radius * radius
  for cy = cy0, cy1 do
    for cx = cx0, cx1 do
      local px = (cx + 0.5) * self.cell
      local py = (cy + 0.5) * self.cell
      local dx, ddy = px - wx, py - wy
      if dx * dx + ddy * ddy <= r2 then
        self:setSolid(cx, cy, false)
      end
    end
  end
end

function M:rebuildImageData()
  local id = love.image.newImageData(self.gw, self.gh)
  id:mapPixel(function(x, y)
    if self.solid[self:_i(x, y)] then
      local t = (x * 13 + y * 7) % 5
      if t == 0 then
        return DIRT2[1], DIRT2[2], DIRT2[3], DIRT2[4]
      end
      return DIRT[1], DIRT[2], DIRT[3], DIRT[4]
    end
    return 0, 0, 0, 0
  end)
  self.imageData = id
  if self.image then
    self.image:release()
  end
  self.image = love.graphics.newImage(id)
  self.dirty = false
end

function M:draw()
  if self.dirty then
    self:rebuildImageData()
  end
  if self.image then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, 0, 0, 0, self.cell, self.cell)
  end
end

return M
