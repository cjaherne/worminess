local M = {}

function M.countdown(seconds)
  return {
    t = seconds or 0,
    update = function(self, dt)
      if self.t > 0 then
        self.t = self.t - dt
        if self.t < 0 then
          self.t = 0
        end
      end
    end,
    done = function(self)
      return self.t <= 0
    end,
    reset = function(self, s)
      self.t = s
    end,
  }
end

return M
