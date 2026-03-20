-- Moles — Worms-like local 2P game (LÖVE 11.4)
love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

local app = require("app")

function love.load()
  app.load()
end

function love.update(dt)
  app.update(dt)
end

function love.draw()
  app.draw()
end

function love.keypressed(key, scancode, isrepeat)
  app.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  app.keyreleased(key, scancode)
end

function love.textinput(t)
  app.textinput(t)
end

function love.mousemoved(x, y, dx, dy, istouch)
  app.mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
  app.mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
  app.mousereleased(x, y, button, istouch, presses)
end

function love.joystickadded(j)
  app.joystickadded(j)
end

function love.joystickremoved(j)
  app.joystickremoved(j)
end

function love.gamepadpressed(j, button)
  app.gamepadpressed(j, button)
end

function love.gamepadreleased(j, button)
  app.gamepadreleased(j, button)
end

function love.resize(w, h)
  app.resize(w, h)
end

function love.focus(has_focus)
  app.focus(has_focus)
end
