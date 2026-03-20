local defaults = require("config.defaults")
local session_scores = require("data.session_scores")

local M = {}

local function fmt_time(t)
  if not t or t <= 0 then return "∞" end
  return string.format("%.0f", math.max(0, t))
end

function M.draw_background()
  local c1, c2 = defaults.colors.sky_top, defaults.colors.sky_bot
  for y = 0, 719, 4 do
    local t = y / 720
    love.graphics.setColor(
      c1[1] + (c2[1] - c1[1]) * t,
      c1[2] + (c2[2] - c1[2]) * t,
      c1[3] + (c2[3] - c1[3]) * t,
      1
    )
    love.graphics.rectangle("fill", 0, y, 1280, 4)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_turn_banner(world, fonts)
  local turn = world.turn
  local m = turn:active_mole(world.moles)
  local slot = turn.mole_slot[turn.active_player]
  local team = defaults.colors["team" .. turn.active_player]
  love.graphics.setFont(fonts.hud)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 20, 12, 560, 72, 8, 8)
  love.graphics.setColor(team[1], team[2], team[3], 1)
  love.graphics.circle("fill", 44, 48, 10)
  love.graphics.setColor(0.95, 0.96, 0.98, 1)
  local line = string.format("Player %i — mole slot %i", turn.active_player, slot)
  love.graphics.print(line, 64, 28)
  if (world.settings.turn_time_seconds or 0) > 0 then
    love.graphics.setColor(0.85, 0.88, 0.92, 1)
    love.graphics.print("Time: " .. fmt_time(turn.turn_time_left), 64, 52)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_session_line(fonts)
  local s = session_scores.get_snapshot()
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 640, 12, 620, 72, 8, 8)
  love.graphics.setColor(0.92, 0.93, 0.96, 1)
  local t = string.format("Session  P1 wins %i  ·  P2 wins %i  ·  Draws %i", s.gamesPlayedP1, s.gamesPlayedP2, s.gamesDrawn)
  love.graphics.printf(t, 650, 36, 600, "right")
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_weapon_panel(world, fonts, assets)
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 20, 96, 320, 188, 8, 8)
  local sel = world.weapon_index
  local function icon(img, x, y, on)
    if not img then return end
    love.graphics.setColor(1, 1, 1, on and 1 or 0.35)
    love.graphics.draw(img, x, y, 0, 0.42, 0.42)
  end
  icon(assets.ui_icon_rocket, 40, 112, sel == 1)
  icon(assets.ui_icon_grenade, 130, 112, sel == 2)
  love.graphics.setColor(0.9, 0.92, 0.95, 1)
  local deg = world.aim_angle * 180 / math.pi
  love.graphics.print(string.format("Aim %i°", math.floor(deg + 0.5)), 40, 220)
  love.graphics.rectangle("line", 40, 248, 200, 14, 4, 4)
  love.graphics.setColor(0.35, 0.85, 0.95, 0.9)
  love.graphics.rectangle("fill", 42, 250, 196 * world.power, 10, 2, 2)
  love.graphics.setColor(1, 1, 1, 1)
  if sel == 2 then
    love.graphics.setColor(0.85, 0.9, 0.95, 1)
    love.graphics.print(string.format("Grenade fuse %.1fs", defaults.weapon.grenade_fuse), 40, 176)
  end
end

function M.draw_wind_timer(world, fonts, assets)
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 940, 96, 320, 188, 8, 8)
  local w = world.settings.wind or "off"
  love.graphics.setColor(0.9, 0.92, 0.95, 1)
  if w ~= "off" and assets.ui_icon_wind then
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.draw(assets.ui_icon_wind, 960, 116, 0, 0.4, 0.4)
    love.graphics.setColor(0.9, 0.92, 0.95, 1)
    love.graphics.print("Wind: " .. w, 1040, 132)
  else
    love.graphics.print("Wind: off", 960, 132)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_roster(world, fonts)
  love.graphics.setFont(fonts.tiny)
  local function row(px, py, player, label)
    local team = defaults.colors["team" .. player]
    love.graphics.setColor(team[1], team[2], team[3], 0.85)
    love.graphics.print(label, px, py)
    for slot = 1, 5 do
      local m = nil
      for _, mm in ipairs(world.moles) do
        if mm.player == player and mm.slot == slot then m = mm break end
      end
      local x = px + (slot - 1) * 118
      local alive = m and m.alive
      love.graphics.setColor(0, 0, 0, alive and 0.35 or 0.2)
      love.graphics.rectangle("fill", x, py + 22, 108, 36, 6, 6)
      if m then
        love.graphics.setColor(1, 1, 1, alive and 1 or 0.35)
        local pct = alive and (m.hp / m.max_hp) or 0
        love.graphics.rectangle("fill", x + 4, py + 38, 100 * pct, 8, 2, 2)
        love.graphics.print(string.format("%i", slot), x + 6, py + 26)
      end
    end
  end
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 20, 608, 1240, 100, 8, 8)
  row(40, 618, 1, "Team A")
  row(40, 662, 2, "Team B")
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_help_strip(fonts, input_mode)
  love.graphics.setFont(fonts.tiny)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 24, 536, 1232, 64, 8, 8)
  love.graphics.setColor(0.88, 0.9, 0.93, 1)
  local msg = (input_mode == "dual_gamepad")
      and "Gamepads: left stick move · A jump · right stick aim · triggers power · B fire · LB/RB weapon · Y end turn · Start pause"
    or "Shared KB: P1 WASD Q/E aim Z/X power F fire G end 1/2 weapon · P2 arrows [ ] aim I/K power ; fire Backspace end , . weapon · mouse aims active player only"
  love.graphics.printf(msg, 36, 548, 1208, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

return M
