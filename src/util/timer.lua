local M = {}
M.__index = M

function M.new(duration)
  return setmetatable({ t = 0, duration = duration or 0, done = false }, M)
end

function M:reset(d)
  self.t = 0
  self.done = false
  if d then self.duration = d end
end

function M:update(dt)
  if self.done then return true end
  self.t = self.t + dt
  if self.t >= self.duration then
    self.done = true
    return true
  end
  return false
end

function M:ratio()
  if self.duration <= 0 then return 1 end
  return math.min(1, self.t / self.duration)
end

return M
