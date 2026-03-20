local vec2 = require("core.vec2")

local M = {}

-- Returns first hit t in [0,1] along segment p0->p1 against solid terrain, or nil
function M.segment_terrain_hit(terrain, x0, y0, x1, y1, steps)
  steps = steps or 48
  local dx, dy = x1 - x0, y1 - y0
  for i = 1, steps do
    local t = i / steps
    local x = x0 + dx * t
    local y = y0 + dy * t
    if terrain:isSolidPixel(x, y) then
      return t, x, y
    end
  end
  return nil
end

function M.circle_resolve_slide(terrain, x, y, radius, vx, vy, dt)
  local nx = x + vx * dt
  local ny = y + vy * dt
  if not terrain:isSolidCircle(nx, ny, radius) then
    return nx, ny, vx, vy
  end
  if not terrain:isSolidCircle(x, ny, radius) then
    return x, ny, vx * 0.85, vy
  end
  if not terrain:isSolidCircle(nx, y, radius) then
    return nx, y, vx, vy * 0.85
  end
  return x, y, 0, vy * -0.1
end

return M
