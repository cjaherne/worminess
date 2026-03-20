local M = {}

function M.len(x, y)
  return math.sqrt(x * x + y * y)
end

function M.normalize(x, y)
  local l = M.len(x, y)
  if l < 1e-6 then
    return 1, 0
  end
  return x / l, y / l
end

function M.dot(ax, ay, bx, by)
  return ax * bx + ay * by
end

function M.add(ax, ay, bx, by)
  return ax + bx, ay + by
end

function M.scale(x, y, s)
  return x * s, y * s
end

function M.angle_to(dx, dy)
  return math.atan2(dy, dx)
end

return M
