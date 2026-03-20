--- Shared D-pad / left-stick navigation for menu-style scenes (any first gamepad).

local COOLDOWN = 0.22

local M = {}

function M.reset(state)
  state.gp_cd = 0
end

function M.tick_cooldown(state, dt)
  state.gp_cd = math.max(0, (state.gp_cd or 0) - dt)
end

function M.first_gamepad()
  for _, j in ipairs(love.joystick.getJoysticks()) do
    if j:isGamepad() then return j end
  end
end

--- Returns "up", "down", "left", "right", or nil. Uses hold + cooldown so sticks don’t spin.
function M.poll_nav(state)
  if (state.gp_cd or 0) > 0 then return nil end
  local j = M.first_gamepad()
  if not j then return nil end
  local y = j:getGamepadAxis("lefty")
  local x = j:getGamepadAxis("leftx")
  local t = 0.52
  if j:isGamepadDown("dpup") or y < -t then
    state.gp_cd = COOLDOWN
    return "up"
  end
  if j:isGamepadDown("dpdown") or y > t then
    state.gp_cd = COOLDOWN
    return "down"
  end
  if j:isGamepadDown("dpleft") or x < -t then
    state.gp_cd = COOLDOWN
    return "left"
  end
  if j:isGamepadDown("dpright") or x > t then
    state.gp_cd = COOLDOWN
    return "right"
  end
  return nil
end

return M
