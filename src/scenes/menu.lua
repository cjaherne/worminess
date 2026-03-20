local session_scores = require("data.session_scores")
local gp_nav = require("util.gamepad_menu")
local sfx = require("audio.sfx")

local M = { id = "menu" }

local focus = 1
local labels = { "Play", "Match options", "How to play", "Quit" }
local show_howto = false
local gp = {}

local function activate(app)
  if focus == 1 then
    if app.last_match_settings then
      app.goto("play", app.last_match_settings)
    else
      app.goto("match_setup")
    end
  elseif focus == 2 then
    app.goto("match_setup")
  elseif focus == 3 then
    show_howto = true
  elseif focus == 4 then
    love.event.quit()
  end
end

function M.enter(_)
  focus = 1
  show_howto = false
  gp_nav.reset(gp)
end

function M.update(_, dt)
  gp_nav.tick_cooldown(gp, dt)
  if show_howto then return end
  local dir = gp_nav.poll_nav(gp)
  if dir == "up" then
    focus = math.max(1, focus - 1)
  elseif dir == "down" then
    focus = math.min(#labels, focus + 1)
  end
end

function M.draw(app)
  local ui = require("ui.hud")
  ui.draw_background()
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.setFont(app.fonts.title)
  love.graphics.setColor(0.08, 0.09, 0.12, 0.55)
  love.graphics.printf("MOLES", 442, 188, 400, "center")
  love.graphics.setColor(0.95, 0.96, 0.98, 1)
  love.graphics.printf("MOLES", 440, 180, 400, "center")

  love.graphics.setFont(app.fonts.hud)
  local y0 = 420
  for i, lab in ipairs(labels) do
    local sel = (focus == i)
    love.graphics.setColor(0, 0, 0, sel and 0.5 or 0.25)
    love.graphics.rectangle("fill", 440, y0 + (i - 1) * 68, 400, 56, 10, 10)
    love.graphics.setColor(sel and 1 or 0.75, sel and 0.95 or 0.8, sel and 0.55 or 0.65, 1)
    love.graphics.printf((sel and "› " or "  ") .. lab, 460, y0 + 14 + (i - 1) * 68, 360, "left")
  end

  local snap = session_scores.get_snapshot()
  love.graphics.setFont(app.fonts.small)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 36, 36, 520, 100, 10, 10)
  love.graphics.setColor(0.9, 0.92, 0.95, 1)
  love.graphics.print("This session", 52, 48)
  love.graphics.printf(
    string.format("P1 wins %i  ·  P2 wins %i  ·  Draws %i", snap.gamesPlayedP1, snap.gamesPlayedP2, snap.gamesDrawn),
    52,
    78,
    480,
    "left"
  )

  love.graphics.setFont(app.fonts.tiny)
  love.graphics.setColor(0.55, 0.58, 0.62, 1)
  love.graphics.printf("Gamepad: D-pad / stick · A confirm · Start not used here", 400, 600, 480, "center")
  love.graphics.printf("LÖVE 11.4 · local hotseat", 840, 612, 400, "right")

  if show_howto then
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", 200, 120, 880, 480, 14, 14)
    love.graphics.setFont(app.fonts.hud)
    love.graphics.setColor(0.94, 0.95, 0.97, 1)
    love.graphics.printf("How to play", 220, 140, 840, "center")
    love.graphics.setFont(app.fonts.small)
    local txt = [[
Two humans take turns on one machine (hotseat). Each team has five moles on destructible land.

Shared keyboard + mouse: only the active player’s mouse aims; each player has their own keys (see in-match hint strip).

Gamepads: connect two controllers; pick “Two gamepads” in Match options. Move with the left stick, aim with the right, B to fire, Y to end your turn.

Walk, jump, aim, pick rocket or grenade, fire once per turn, then press End turn to pass. Last team standing wins.

Esc pauses during a match.]]
    love.graphics.printf(txt, 240, 200, 800, "left")
    love.graphics.setColor(0.75, 0.8, 0.9, 1)
    love.graphics.printf("Press Esc, Enter, A, or B to close", 240, 540, 800, "center")
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.keypressed(app, key)
  if show_howto then
    if key == "escape" or key == "return" or key == "kpenter" then
      show_howto = false
    end
    return
  end
  if key == "up" or key == "w" then
    focus = math.max(1, focus - 1)
  elseif key == "down" or key == "s" then
    focus = math.min(#labels, focus + 1)
  elseif key == "return" or key == "kpenter" or key == "space" then
    sfx.ui()
    activate(app)
  end
end

function M.gamepadpressed(app, _, button)
  if show_howto then
    if button == "a" or button == "b" or button == "x" then
      show_howto = false
      sfx.ui()
    end
    return
  end
  if button == "a" then
    sfx.ui()
    activate(app)
  end
end

return M
