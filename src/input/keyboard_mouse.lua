--- Shared keyboard + mouse (R10). Per DESIGN.md Part A (two-player one keyboard) + mouse aim for turn owner only.

local M = {}

local function intent_empty()
  return {
    move_x = 0,
    jump = false,
    aim_delta = 0,
    power_delta = 0,
    cycle_weapon = false,
    fire_pressed = false,
    end_turn_pressed = false,
  }
end

function M.build_intents(input, turn_state, _)
  local out = { intent_empty(), intent_empty() }
  local ap = turn_state.active_player
  local i1, i2 = out[1], out[2]

  if ap == 1 then
    if love.keyboard.isScancodeDown("a") then i1.move_x = i1.move_x - 1 end
    if love.keyboard.isScancodeDown("d") then i1.move_x = i1.move_x + 1 end
    i1.jump = love.keyboard.isScancodeDown("w") or love.keyboard.isScancodeDown("space")
    if love.keyboard.isScancodeDown("q") then i1.aim_delta = i1.aim_delta - 1 end
    if love.keyboard.isScancodeDown("e") then i1.aim_delta = i1.aim_delta + 1 end
    if love.keyboard.isScancodeDown("z") then i1.power_delta = i1.power_delta - 1 end
    if love.keyboard.isScancodeDown("x") then i1.power_delta = i1.power_delta + 1 end
    i1.cycle_weapon = input.consume_key_cycle_p1 or false
    i1.fire_pressed = input.consume_fire_p1 or input.consume_mouse_fire or false
    i1.end_turn_pressed = input.consume_end_p1 or false
  else
    if love.keyboard.isScancodeDown("left") then i2.move_x = i2.move_x - 1 end
    if love.keyboard.isScancodeDown("right") then i2.move_x = i2.move_x + 1 end
    i2.jump = love.keyboard.isScancodeDown("up") or love.keyboard.isScancodeDown("rshift")
    if love.keyboard.isScancodeDown("leftbracket") then i2.aim_delta = i2.aim_delta - 1 end
    if love.keyboard.isScancodeDown("rightbracket") then i2.aim_delta = i2.aim_delta + 1 end
    if love.keyboard.isScancodeDown("k") then i2.power_delta = i2.power_delta - 1 end
    if love.keyboard.isScancodeDown("i") then i2.power_delta = i2.power_delta + 1 end
    i2.cycle_weapon = input.consume_key_cycle_p2 or false
    i2.fire_pressed = input.consume_fire_p2 or input.consume_mouse_fire or false
    i2.end_turn_pressed = input.consume_end_p2 or false
  end

  input.consume_key_cycle_p1 = false
  input.consume_key_cycle_p2 = false
  input.consume_fire_p1 = false
  input.consume_fire_p2 = false
  input.consume_mouse_fire = false
  input.consume_end_p1 = false
  input.consume_end_p2 = false

  return out
end

function M.on_keypressed(input, key, scancode)
  if key == "1" then
    input.pending_weapon_team = 1
    input.pending_weapon_index = 1
  elseif key == "2" then
    input.pending_weapon_team = 1
    input.pending_weapon_index = 2
  elseif key == "," then
    input.pending_weapon_team = 2
    input.pending_weapon_index = 1
  elseif key == "." then
    input.pending_weapon_team = 2
    input.pending_weapon_index = 2
  elseif scancode == "g" then
    input.consume_end_p1 = true
  elseif scancode == "backspace" or scancode == "backslash" then
    input.consume_end_p2 = true
  elseif scancode == "f" then
    input.consume_fire_p1 = true
  elseif scancode == "semicolon" or scancode == "rctrl" or scancode == "return" or scancode == "kpenter" then
    input.consume_fire_p2 = true
  elseif scancode == "tab" then
    input.consume_key_cycle_p1 = true
  elseif scancode == "minus" or scancode == "equals" then
    input.consume_key_cycle_p2 = true
  end
end

return M
