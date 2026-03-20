--- Turn model: Game Designer doc is authoritative.
--- On end_turn(P): advance mole_slot[P] to next living mole (ring); active_player = other(P).

local M = {}
M.__index = M

function M.new(settings)
  local first = settings.first_player
  if first == "random" then
    first = love.math.random(1, 2) == 1 and "1" or "2"
  end
  local active = tonumber(first) or 1
  local limit = settings.turn_time_seconds or 0
  local o = {
    active_player = active,
    mole_slot = { 1, 1 },
    turn_time_left = limit,
    _turn_limit = limit,
  }
  return setmetatable(o, M)
end

function M:alive_slot_for_player(moles, player, start_slot)
  for k = 0, 4 do
    local slot = ((start_slot - 1 + k) % 5) + 1
    for _, m in ipairs(moles) do
      if m.player == player and m.slot == slot and m.alive then
        return slot
      end
    end
  end
  return nil
end

function M:sync_slots_to_living(moles)
  for p = 1, 2 do
    local s = self.mole_slot[p]
    if not self:alive_slot_for_player(moles, p, s) then
      local any = self:alive_slot_for_player(moles, p, 1)
      if any then self.mole_slot[p] = any end
    end
  end
end

function M:active_mole(moles)
  local p = self.active_player
  local s = self.mole_slot[p]
  for _, m in ipairs(moles) do
    if m.player == p and m.slot == s and m.alive then
      return m
    end
  end
  return nil
end

--- Walk ring at least one step (next_index_in_ring), then until living (Designer pseudocode).
function M:advance_after_turn(moles)
  local p = self.active_player
  local cur = self.mole_slot[p]
  local idx = cur
  local chosen = nil
  for _ = 1, 5 do
    idx = (idx % 5) + 1
    for _, m in ipairs(moles) do
      if m.player == p and m.slot == idx and m.alive then
        chosen = idx
        break
      end
    end
    if chosen then break end
  end
  if chosen then
    self.mole_slot[p] = chosen
  end
  self.active_player = (p == 1) and 2 or 1
end

function M:end_turn(moles, settings)
  self._turn_limit = settings.turn_time_seconds or 0
  self:advance_after_turn(moles)
  self:sync_slots_to_living(moles)
  self.turn_time_left = self._turn_limit
end

function M:update_timer(dt, moles, settings)
  self._turn_limit = settings.turn_time_seconds or 0
  if self._turn_limit <= 0 then return false end
  self.turn_time_left = (self.turn_time_left or self._turn_limit) - dt
  if self.turn_time_left <= 0 then
    self:end_turn(moles, settings)
    return true
  end
  return false
end

return M
