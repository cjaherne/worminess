local kb = require("input.keyboard_mouse")
local gp = require("input.gamepad")

local M = {}

function M.new()
  return {
    consume_mouse_fire = false,
    consume_pad_fire = false,
    consume_pad_end = false,
    consume_pad_cycle = false,
    consume_fire_p1 = false,
    consume_fire_p2 = false,
    consume_end_p1 = false,
    consume_end_p2 = false,
    consume_key_cycle_p1 = false,
    consume_key_cycle_p2 = false,
    pending_weapon_team = nil,
    pending_weapon_index = nil,
    js_p1 = nil,
    js_p2 = nil,
  }
end

function M:keypressed(key, scancode)
  kb.on_keypressed(self, key, scancode)
end

--- Mouse fire is consumed into the active player’s intent in `keyboard_mouse.build_intents`.
function M:mousepressed()
  self.consume_mouse_fire = true
end

function M:gamepadpressed(joystick, button)
  gp.on_gamepadpressed(self, joystick, button)
end

function M:get_intents(turn_state, settings)
  if settings.input_mode == "dual_gamepad" then
    return gp.build_intents(self, turn_state, settings)
  end
  return kb.build_intents(self, turn_state, settings)
end

function M:apply_pending_weapon(world)
  local t, idx = self.pending_weapon_team, self.pending_weapon_index
  if t and idx and world.turn.active_player == t then
    world.weapon_index = idx
  end
  self.pending_weapon_team = nil
  self.pending_weapon_index = nil
end

return M
