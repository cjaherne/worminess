local viewport = require("util.viewport")
local input_mod = require("input.input_manager")

local app = {
  stack = {},
  input = input_mod.new(),
  last_match_settings = nil,
  fonts = {},
  assets = {},
}

local function load_image(path)
  local ok, img = pcall(love.graphics.newImage, path)
  if ok then
    img:setFilter("nearest", "nearest")
    return img
  end
  return nil
end

function app.push(name, ...)
  local sc = require("scenes." .. name)
  table.insert(app.stack, sc)
  if sc.enter then sc.enter(app, ...) end
end

function app.pop()
  local sc = table.remove(app.stack)
  if sc and sc.leave then sc.leave(app) end
  return sc
end

function app.goto(name, ...)
  while #app.stack > 0 do
    app.pop()
  end
  app.push(name, ...)
end

function app.end_match(args)
  while #app.stack > 0 do
    app.pop()
  end
  if args and args.settings then
    app.last_match_settings = args.settings
  end
  app.push("match_end", args)
end

function app.quit_match_to_results(winner_id, settings)
  local seed
  if app.state and app.state.world then
    seed = app.state.world.map_seed_used
  end
  local session_scores = require("data.session_scores")
  session_scores.record_match_outcome(winner_id)
  app.pop()
  app.pop()
  app.last_match_settings = settings
  app.push("match_end", { winner = winner_id, settings = settings, map_seed_used = seed })
end

function app.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  local sfx = require("audio.sfx")
  sfx.init()
  app.fonts.title = love.graphics.newFont(40)
  app.fonts.hud = love.graphics.newFont(20)
  app.fonts.small = love.graphics.newFont(17)
  app.fonts.tiny = love.graphics.newFont(14)

  app.assets.mole_a_idle = load_image("assets/sprites/mole_team_a_idle.png")
  app.assets.mole_a_aim = load_image("assets/sprites/mole_team_a_aim.png")
  app.assets.mole_a_walk_1 = load_image("assets/sprites/mole_team_a_walk_1.png")
  app.assets.mole_a_walk_2 = load_image("assets/sprites/mole_team_a_walk_2.png")
  app.assets.mole_b_idle = load_image("assets/sprites/mole_team_b_idle.png")
  app.assets.mole_b_aim = load_image("assets/sprites/mole_team_b_aim.png")
  app.assets.mole_b_walk_1 = load_image("assets/sprites/mole_team_b_walk_1.png")
  app.assets.mole_b_walk_2 = load_image("assets/sprites/mole_team_b_walk_2.png")
  app.assets.rocket = load_image("assets/sprites/rocket.png")
  app.assets.grenade = load_image("assets/sprites/grenade.png")
  app.assets.ui_icon_rocket = load_image("assets/sprites/ui_icon_rocket.png")
  app.assets.ui_icon_grenade = load_image("assets/sprites/ui_icon_grenade.png")
  app.assets.ui_icon_wind = load_image("assets/sprites/ui_icon_wind.png")

  app.stack = {}
  app.push("menu")
end

function app.update(dt)
  local top = app.stack[#app.stack]
  if top and top.update then top.update(app, dt) end
end

function app.draw()
  local ox, oy, s = viewport.fit_transform()
  local lw, lh = viewport.logical_size()
  love.graphics.clear(0.04, 0.05, 0.07, 1)
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(s)
  love.graphics.setFont(app.fonts.hud)
  local top = app.stack[#app.stack]
  if top and top.draw then top.draw(app) end
  love.graphics.pop()
end

function app.keypressed(key, scancode, isrepeat)
  if isrepeat then return end
  local top = app.stack[#app.stack]
  if top and top.keypressed then top.keypressed(app, key, scancode) end
end

function app.keyreleased(key, scancode) end

function app.textinput(t)
  local top = app.stack[#app.stack]
  if top and top.textinput then top.textinput(app, t) end
end

function app.mousemoved(_, _, _, _, _) end

function app.mousepressed(x, y, button, istouch, presses)
  local top = app.stack[#app.stack]
  if top and top.mousepressed then top.mousepressed(app, x, y, button, istouch, presses) end
end

function app.mousereleased(_, _, _, _, _) end

function app.joystickadded(_)
  require("input.gamepad").assign_joysticks(app.input)
end

function app.joystickremoved(_)
  require("input.gamepad").assign_joysticks(app.input)
end

function app.gamepadpressed(joystick, button)
  local top = app.stack[#app.stack]
  if button == "start" then
    if top and top.id == "play" then
      app.push("pause")
      return
    elseif top and top.id == "pause" then
      app.pop()
      return
    end
  end
  if top and top.gamepadpressed then top.gamepadpressed(app, joystick, button) end
end

function app.gamepadreleased(_, _) end

function app.resize(_, _) end

return app
