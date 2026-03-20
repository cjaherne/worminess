--- Semantic action ids; actual keys checked in play / routers.
local M = {}

M.actions = {
  move_left = "move_left",
  move_right = "move_right",
  aim_up = "aim_up",
  aim_down = "aim_down",
  power = "power",
  fire = "fire",
  weapon_prev = "weapon_prev",
  weapon_next = "weapon_next",
  pause = "pause",
}

--- P1 keys when shared keyboard (also used for active player in shared_kb).
M.p1_keys = {
  move_left = "a",
  move_right = "d",
  aim_up = "w",
  aim_down = "s",
  power = "lshift",
  fire = "space",
  weapon_prev = "1",
  weapon_next = "2",
}

--- P2 keys when shared keyboard (non-overlapping).
M.p2_keys = {
  move_left = "left",
  move_right = "right",
  aim_up = "up",
  aim_down = "down",
  power = "rshift",
  fire = "return",
  weapon_prev = "kp1",
  weapon_next = "kp2",
}

function M.default_bindings()
  return {
    shared = { p1 = M.p1_keys, p2 = M.p2_keys },
  }
end

return M
