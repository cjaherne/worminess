local M = {}
M.__index = M

function M.new()
  return setmetatable({
    spawn_team1 = {},
    spawn_team2 = {},
    seed = 0,
  }, M)
end

return M
