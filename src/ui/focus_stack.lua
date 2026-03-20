--- Lightweight focus stack for future menus/HUD; match_setup uses row index for now.
local M = {}
M.__index = M

function M.new()
  return setmetatable({ stack = {} }, M)
end

function M:push(id)
  table.insert(self.stack, id)
end

function M:pop()
  return table.remove(self.stack)
end

function M:top()
  return self.stack[#self.stack]
end

function M:clear()
  self.stack = {}
end

return M
