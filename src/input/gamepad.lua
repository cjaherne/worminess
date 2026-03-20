--- Two gamepads (R11). `love.joystick.getJoysticks()[1]` → P1, `[2]` → P2.

local DEADZONE = 0.2

local M = {}

local function stick_axis(j, ax, ay)
  if not j or not j:isGamepad() then return 0, 0 end
  local x = j:getGamepadAxis(ax)
  local y = j:getGamepadAxis(ay)
  if math.abs(x) < DEADZONE then x = 0 end
  if math.abs(y) < DEADZONE then y = 0 end
  return x, y
end

local function intent_empty()
  return {
    move_x = 0,
    jump = false,
    aim_delta = 0,
    power_delta = 0,
    cycle_weapon = false,
    fire_pressed = false,
    end_turn_pressed = false,
    _aim_absolute = nil,
    _use_absolute_aim = false,
  }
end

function M.assign_joysticks(input)
  local list = love.joystick.getJoysticks()
  input.js_p1 = list[1]
  input.js_p2 = list[2]
end

function M.build_intents(input, turn_state, _)
  M.assign_joysticks(input)
  local out = { intent_empty(), intent_empty() }
  local ap = turn_state.active_player
  local j = ap == 1 and input.js_p1 or input.js_p2
  local i = out[ap]
  if not j or not j:isGamepad() then
    return out
  end

  local mx, _ = stick_axis(j, "leftx", "lefty")
  i.move_x = mx
  i.jump = j:isGamepadDown("a")

  local ax, ay = stick_axis(j, "rightx", "righty")
  if ax ~= 0 or ay ~= 0 then
    i._aim_absolute = math.atan2(ay, ax)
    i._use_absolute_aim = true
  end

  local lt = j:getGamepadAxis("triggerleft") or 0
  local rt = j:getGamepadAxis("triggerright") or 0
  i.power_delta = rt - lt

  i.fire_pressed = input.consume_pad_fire or false
  i.end_turn_pressed = input.consume_pad_end or false
  i.cycle_weapon = input.consume_pad_cycle or false

  input.consume_pad_fire = false
  input.consume_pad_end = false
  input.consume_pad_cycle = false

  return out
end

function M.on_gamepadpressed(input, joystick, button)
  M.assign_joysticks(input)
  local j1, j2 = input.js_p1, input.js_p2
  if joystick ~= j1 and joystick ~= j2 then return end
  if button == "b" then
    input.consume_pad_fire = true
  elseif button == "y" then
    input.consume_pad_end = true
  elseif button == "leftshoulder" or button == "rightshoulder" then
    input.consume_pad_cycle = true
  end
end

return M
