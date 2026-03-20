--- Smoothed stick aim + analog trigger reads for gamepads.
local M = {}

function M.smooth2(px, py, tx, ty, dt, rate)
  rate = rate or 14
  local k = math.min(1, rate * dt)
  return px + (tx - px) * k, py + (ty - py) * k
end

function M.read_left_stick(joystick, deadzone)
  if not joystick or not joystick:isGamepad() then
    return 0, 0
  end
  deadzone = deadzone or 0.28
  local x = joystick:getGamepadAxis("leftx")
  local y = joystick:getGamepadAxis("lefty")
  if math.abs(x) < deadzone then
    x = 0
  end
  if math.abs(y) < deadzone then
    y = 0
  end
  return x, y
end

--- Combined analog triggers (0..~2); pads vary — pcall per axis.
function M.read_triggers(joystick)
  if not joystick or not joystick:isGamepad() then
    return 0
  end
  local tl, tr = 0, 0
  local ok, a = pcall(function()
    return joystick:getGamepadAxis("triggerleft")
  end)
  if ok and a then
    tl = math.max(0, a)
  end
  ok, a = pcall(function()
    return joystick:getGamepadAxis("triggerright")
  end)
  if ok and a then
    tr = math.max(0, a)
  end
  return tl + tr
end

return M
