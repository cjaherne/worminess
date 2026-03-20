local M = { id = "play" }

local World = require("sim.world")
local Camera = require("render.camera")
local terrain_draw = require("render.terrain_draw")
local mole_draw = require("render.mole_draw")
local hud = require("ui.hud")
local viewport = require("util.viewport")

function M.enter(app, settings)
  app.state = {
    world = World.new(settings),
    camera = Camera.new(),
    settings = settings,
  }
  local w = app.state.world
  app.state.camera.x = w.terrain:width_px() * 0.5
  app.state.camera.y = w.terrain:height_px() * 0.35
end

function M.leave(app)
  app.state = nil
end

function M.update(app, dt)
  local st = app.state
  local w = st.world
  if w.won then return end

  local use_mouse = (st.settings.input_mode == "shared_kb")
  local lx, ly = viewport.screen_to_logical(love.mouse.getX(), love.mouse.getY())
  local wmx, wmy = st.camera:logical_to_world(lx, ly)

  app.input:apply_pending_weapon(w)
  local intents = app.input:get_intents(w.turn, st.settings)
  w:update(dt, intents, wmx, wmy, use_mouse)
  st.camera:follow(w, dt)

  if w.won then
    local session_scores = require("data.session_scores")
    session_scores.record_match_outcome(w.winner)
    app.end_match({ winner = w.winner, settings = st.settings, map_seed_used = w.map_seed_used })
  end
end

function M.draw(app)
  local st = app.state
  local w = st.world
  local cam = st.camera
  local LW, LH = viewport.logical_size()

  hud.draw_background()
  love.graphics.push()
  love.graphics.translate(LW * 0.5, LH * 0.5)
  love.graphics.translate(-cam.x, -cam.y)

  terrain_draw.draw(w.terrain)
  mole_draw.draw_particles(w.particles)

  local active = w.turn:active_mole(w.moles)
  for _, m in ipairs(w.moles) do
    local is_active = (m == active) and not w.won
    mole_draw.draw_mole(app.assets, m, w.aim_angle, is_active, w.turn.active_player)
  end
  mole_draw.draw_projectiles(app.assets, w.projectiles)
  if active and active.alive and #w.projectiles == 0 and not w.fired_this_turn then
    mole_draw.draw_aim_preview(active, w.aim_angle, w.power, w.weapon_index)
  end

  love.graphics.pop()

  hud.draw_turn_banner(w, app.fonts)
  hud.draw_session_line(app.fonts)
  hud.draw_weapon_panel(w, app.fonts, app.assets)
  hud.draw_wind_timer(w, app.fonts, app.assets)
  hud.draw_help_strip(app.fonts, st.settings.input_mode)
  hud.draw_roster(w, app.fonts)

  if w.won then
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, LW, LH)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function M.keypressed(app, key, scancode)
  local st = app.state
  if key == "escape" then
    app.push("pause")
    return
  end
  if st.settings.input_mode == "shared_kb" then
    app.input:keypressed(key, scancode)
  end
end

function M.mousepressed(app, _, _, button)
  if button == 1 and app.state.settings.input_mode == "shared_kb" then
    app.input:mousepressed()
  end
end

function M.gamepadpressed(app, joystick, button)
  if app.state.settings.input_mode == "dual_gamepad" then
    app.input:gamepadpressed(joystick, button)
  end
end

return M
