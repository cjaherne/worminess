function love.conf(t)
  t.identity = "moles-wormslike"
  t.version = "11.4"
  t.console = false

  t.window.title = "Moles — Local Artillery"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.minwidth = 800
  t.window.minheight = 450
  t.window.vsync = 1

  t.modules.joystick = true
  t.modules.audio = true
end
