local gp_nav = require("util.gamepad_menu")
local sfx = require("audio.sfx")

local M = { id = "pause" }

local focus = 1
local labels = { "Resume", "How to play", "Forfeit match", "Quit to title" }
local show_howto = false
local forfeit_confirm = false
local gp = {}

function M.enter(_)
  focus = 1
  show_howto = false
  forfeit_confirm = false
  gp_nav.reset(gp)
end

function M.update(_, dt)
  gp_nav.tick_cooldown(gp, dt)
  if show_howto or forfeit_confirm then return end
  local dir = gp_nav.poll_nav(gp)
  if dir == "up" then
    focus = math.max(1, focus - 1)
  elseif dir == "down" then
    focus = math.min(#labels, focus + 1)
  end
end

function M.draw(app)
  love.graphics.setColor(0, 0, 0, 0.42)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)
  love.graphics.setColor(0.1, 0.12, 0.16, 1)
  love.graphics.rectangle("fill", 380, 180, 520, 360, 12, 12)
  love.graphics.setFont(app.fonts.title)
  love.graphics.setColor(0.94, 0.95, 0.97, 1)
  love.graphics.printf("Paused", 400, 200, 480, "center")
  love.graphics.setFont(app.fonts.hud)
  local y0 = 268
  for i, lab in ipairs(labels) do
    local sel = focus == i
    love.graphics.setColor(sel and 0.95 or 0.65, sel and 0.92 or 0.7, sel and 0.55 or 0.75, 1)
    love.graphics.printf((sel and "› " or "  ") .. lab, 420, y0 + (i - 1) * 52, 440, "left")
  end
  if forfeit_confirm then
    love.graphics.setColor(1, 0.55, 0.45, 1)
    love.graphics.printf("Press Enter / A to confirm forfeit (opponent wins)", 400, 470, 480, "center")
  end
  if show_howto then
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", 220, 140, 840, 440, 12, 12)
    love.graphics.setFont(app.fonts.small)
    love.graphics.setColor(0.92, 0.93, 0.96, 1)
    love.graphics.printf(
      "Shared keyboard: turn owner uses mouse to aim; each player has separate keys (see hint strip).\n\nGamepads: left stick move, right stick aim, A jump, B fire, bumpers cycle weapons, Y ends turn.\n\nDestroy terrain, knock foes into pits, win by eliminating the other team.",
      240,
      170,
      800,
      "left"
    )
    love.graphics.setColor(0.75, 0.82, 0.95, 1)
    love.graphics.printf("Esc / Enter / A / B to close", 240, 520, 800, "center")
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local function do_activate(app)
  if focus == 1 then
    app.pop()
  elseif focus == 2 then
    show_howto = true
  elseif focus == 3 then
    forfeit_confirm = true
  elseif focus == 4 then
    app.goto("menu")
  end
end

function M.keypressed(app, key)
  if show_howto then
    if key == "escape" or key == "return" or key == "kpenter" then
      show_howto = false
    end
    return
  end
  if key == "escape" then
    if forfeit_confirm then
      forfeit_confirm = false
    else
      app.pop()
    end
    return
  end
  if forfeit_confirm then
    if key == "return" or key == "kpenter" then
      local st = app.state
      local ap = st.world.turn.active_player
      local win = ap == 1 and 2 or 1
      app.quit_match_to_results(win, st.settings)
    end
    return
  end
  if key == "up" or key == "w" then
    focus = math.max(1, focus - 1)
  elseif key == "down" or key == "s" then
    focus = math.min(#labels, focus + 1)
  elseif key == "return" or key == "kpenter" then
    sfx.ui()
    do_activate(app)
  end
end

function M.gamepadpressed(app, _, button)
  if show_howto then
    if button == "a" or button == "b" then
      show_howto = false
      sfx.ui()
    end
    return
  end
  if button == "b" then
    sfx.ui()
    if forfeit_confirm then
      forfeit_confirm = false
    else
      app.pop()
    end
    return
  end
  if forfeit_confirm then
    if button == "a" then
      local st = app.state
      local ap = st.world.turn.active_player
      local win = ap == 1 and 2 or 1
      app.quit_match_to_results(win, st.settings)
    end
    return
  end
  if button == "a" then
    sfx.ui()
    do_activate(app)
  end
end

return M
