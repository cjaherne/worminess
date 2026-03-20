--- Joystick assignment for dual_gamepad; refreshed on hot-plug.
local M = {}

M.scheme = "shared_kb"
M.joy_p1 = nil
M.joy_p2 = nil

function M.set_scheme(scheme)
  M.scheme = scheme or "shared_kb"
  if M.scheme ~= "dual_gamepad" then
    M.joy_p1 = nil
    M.joy_p2 = nil
  end
end

function M.refresh_joysticks()
  local list = love.joystick.getJoysticks()
  if M.scheme ~= "dual_gamepad" then
    return list
  end
  local valid = {}
  for _, j in ipairs(list) do
    if j:isGamepad() then
      valid[#valid + 1] = j
    end
  end
  if M.joy_p1 and not M.joy_p1:isConnected() then
    M.joy_p1 = nil
  end
  if M.joy_p2 and not M.joy_p2:isConnected() then
    M.joy_p2 = nil
  end
  if not M.joy_p1 and valid[1] then
    M.joy_p1 = valid[1]
  end
  return valid
end

function M.try_assign_p2(joystick)
  if M.scheme ~= "dual_gamepad" then
    return false
  end
  if not joystick or not joystick:isGamepad() then
    return false
  end
  if M.joy_p1 == joystick then
    return false
  end
  if not M.joy_p2 then
    M.joy_p2 = joystick
    return true
  end
  return false
end

function M.slot_for_joystick(joystick)
  if joystick and M.joy_p1 == joystick then
    return 1
  end
  if joystick and M.joy_p2 == joystick then
    return 2
  end
  return nil
end

function M.has_dual_ready()
  if M.scheme ~= "dual_gamepad" then
    return true
  end
  M.refresh_joysticks()
  return M.joy_p1 ~= nil and M.joy_p2 ~= nil
end

return M
