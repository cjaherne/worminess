--- Deterministic per-round seed when procedural_seed is set; otherwise random.
local M = {}

function M.derive(procedural_seed, round_index)
  local r = math.max(1, math.floor(round_index or 1))
  if procedural_seed == nil then
    return love.math.random(1, 2147483646)
  end
  local v = procedural_seed * 1315423911 + r * 2654435761
  v = v % 2147483647
  if v <= 0 then
    v = 1
  end
  return math.floor(v)
end

return M
