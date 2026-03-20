--- Registers all love.* callbacks; owns Session + SceneManager.
local scene_manager = require("scene_manager")
local Session = require("game.session")
local constants = require("data.constants")
local theme = require("ui.theme")

local sm
local session

local function get_context()
  return {
    scenes = sm,
    session = session,
  }
end

local function register()
  love.load = function()
    theme.load_fonts()
    session = Session.new()
    sm = scene_manager.new(get_context)
    local boot = require("scenes.boot").new()
    sm:replace(boot)
  end

  love.update = function(dt)
    dt = math.min(dt, constants.MAX_DT)
    sm:update(dt)
  end

  love.draw = function()
    theme.clear_void()
    theme.begin_draw()
    sm:draw()
    theme.end_draw()
  end

  love.resize = function(w, h)
    sm:resize(w, h)
  end

  love.keypressed = function(key, scancode, isrepeat)
    sm:keypressed(key, scancode, isrepeat)
  end

  love.keyreleased = function(key, scancode)
    sm:keyreleased(key, scancode)
  end

  love.gamepadpressed = function(joystick, button)
    sm:gamepadpressed(joystick, button)
  end

  love.gamepadreleased = function(joystick, button)
    sm:gamepadreleased(joystick, button)
  end

  love.mousepressed = function(x, y, button, istouch, presses)
    sm:mousepressed(x, y, button, istouch, presses)
  end

  love.mousereleased = function(x, y, button, istouch, presses)
    sm:mousereleased(x, y, button, istouch, presses)
  end

  love.mousemoved = function(x, y, dx, dy, istouch)
    sm:mousemoved(x, y, dx, dy, istouch)
  end

  love.wheelmoved = function(x, y)
    sm:wheelmoved(x, y)
  end

  love.joystickadded = function(_joystick)
    local devices = require("input.devices")
    devices.refresh_joysticks()
  end

  love.joystickremoved = function(_joystick)
    local devices = require("input.devices")
    devices.refresh_joysticks()
  end
end

return { register = register }
