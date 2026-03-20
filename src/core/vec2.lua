local M = {}

function M.new(x, y)
  return { x = x or 0, y = y or 0 }
end

function M.copy(v)
  return { x = v.x, y = v.y }
end

function M.add(a, b)
  return { x = a.x + b.x, y = a.y + b.y }
end

function M.sub(a, b)
  return { x = a.x - b.x, y = a.y - b.y }
end

function M.scale(v, s)
  return { x = v.x * s, y = v.y * s }
end

function M.len2(v)
  return v.x * v.x + v.y * v.y
end

function M.len(v)
  return math.sqrt(M.len2(v))
end

function M.norm(v)
  local l = M.len(v)
  if l < 1e-8 then
    return { x = 0, y = 0 }
  end
  return { x = v.x / l, y = v.y / l }
end

function M.dot(a, b)
  return a.x * b.x + a.y * b.y
end

function M.dist(a, b)
  return M.len(M.sub(b, a))
end

return M
