local M = {}

function M.new(seed)
  local state = seed or os.time()
  if state == 0 then
    state = 1
  end
  return {
    _state = state,
    seed = function(self, s)
      self._state = s % 2147483647
      if self._state <= 0 then
        self._state = 1
      end
    end,
    random = function(self, a, b)
      -- Park–Miller LCG (Lua-friendly integers)
      local s = self._state
      s = (s * 16807) % 2147483647
      self._state = s
      local u = s / 2147483647
      if not a then
        return u
      end
      if not b then
        return math.floor(u * a) + 1
      end
      return math.floor(u * (b - a + 1)) + a
    end,
  }
end

return M
