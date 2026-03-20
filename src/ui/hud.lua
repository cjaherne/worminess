local defaults = require("config.defaults")
local session_scores = require("data.session_scores")

local M = {}

local function fmt_time(t)
  if not t or t <= 0 then return "∞" end
  return string.format("%.0f", math.max(0, t))
end

local function turn_phase(world)
  if #world.projectiles > 0 then
    return "Resolving projectile…"
  end
  if world.fired_this_turn then
    return "Reposition, then end turn when ready"
  end
  return "Move, aim & fire (one shot per turn)"
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
  local team_name = turn.active_player == 1 and "Team A" or "Team B"
  love.graphics.setFont(fonts.hud)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 20, 10, 600, 96, 10, 10)
  love.graphics.setColor(team[1], team[2], team[3], 1)
  love.graphics.circle("fill", 42, 42, 11)
  love.graphics.setColor(0.96, 0.97, 0.99, 1)
  love.graphics.print(string.format("Player %i · %s", turn.active_player, team_name), 64, 18)
  love.graphics.setColor(0.88, 0.91, 0.95, 1)
  love.graphics.print(string.format("Active mole slot %i", slot), 64, 42)
  if m and m.alive then
    love.graphics.setColor(0.78, 0.95, 0.88, 1)
    love.graphics.print(string.format("HP %i / %i", math.max(0, math.floor(m.hp + 0.5)), m.max_hp), 64, 66)
  else
    love.graphics.setColor(1, 0.72, 0.55, 1)
    love.graphics.print("No active mole (syncing…)", 64, 66)
  end
  love.graphics.setColor(0.72, 0.78, 0.9, 1)
  love.graphics.setFont(fonts.small)
  love.graphics.print(turn_phase(world), 320, 24)
  if (world.settings.turn_time_seconds or 0) > 0 then
    love.graphics.setColor(1, 0.9, 0.55, 1)
    love.graphics.print("Turn timer: " .. fmt_time(turn.turn_time_left), 320, 46)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_session_line(fonts)
  local s = session_scores.get_snapshot()
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 636, 10, 624, 96, 10, 10)
  love.graphics.printf("Session scores (this launch)", 650, 16, 590, "right")
  local function chip(x, y, w, h, col, label, val)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(col[1], col[2], col[3], 1)
    love.graphics.circle("fill", x + 16, y + h * 0.5, 6)
    love.graphics.setColor(0.93, 0.94, 0.96, 1)
    love.graphics.printf(label, x + 28, y + 8, w - 36, "left")
    love.graphics.setFont(fonts.hud)
    love.graphics.printf(tostring(val), x + 8, y + 32, w - 16, "center")
    love.graphics.setFont(fonts.small)
  end
  local t1, t2 = defaults.colors.team1, defaults.colors.team2
  chip(650, 38, 168, 52, t1, "Player 1 wins", s.gamesPlayedP1)
  chip(830, 38, 168, 52, t2, "Player 2 wins", s.gamesPlayedP2)
  chip(1010, 38, 168, 52, { 0.75, 0.78, 0.88 }, "Draws", s.gamesDrawn)
  love.graphics.setColor(0.65, 0.68, 0.74, 1)
  love.graphics.printf("Matches finished: " .. tostring(s.games_played), 650, 86, 590, "right")
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_weapon_panel(world, fonts, assets)
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 20, 114, 328, 200, 10, 10)
  local sel = world.weapon_index
  local function icon(img, x, y, on)
    if not img then return end
    love.graphics.setColor(1, 1, 1, on and 1 or 0.32)
    if on then
      love.graphics.setColor(0.2, 0.85, 1, 0.35)
      love.graphics.rectangle("fill", x - 6, y - 6, 76, 76, 10, 10)
      love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.draw(img, x, y, 0, 0.42, 0.42)
  end
  icon(assets.ui_icon_rocket, 40, 128, sel == 1)
  icon(assets.ui_icon_grenade, 130, 128, sel == 2)
  love.graphics.setColor(0.9, 0.92, 0.95, 1)
  love.graphics.print(sel == 1 and "Rocket (fast, direct)" or "Grenade (arc, timed fuse)", 40, 210)
  local deg = world.aim_angle * 180 / math.pi
  love.graphics.print(string.format("Aim %i°", math.floor(deg + 0.5)), 40, 232)
  love.graphics.setColor(0.55, 0.58, 0.65, 1)
  love.graphics.print("Power", 40, 256)
  love.graphics.rectangle("line", 100, 258, 200, 14, 4, 4)
  love.graphics.setColor(0.25, 0.82, 0.95, 0.95)
  love.graphics.rectangle("fill", 102, 260, 196 * world.power, 10, 2, 2)
  love.graphics.setColor(1, 1, 1, 1)
  if sel == 2 then
    love.graphics.setColor(0.82, 0.9, 0.95, 1)
    love.graphics.print(string.format("Fuse length %.1fs (armed in-air below)", defaults.weapon.grenade_fuse), 40, 186)
  end
  for _, pr in ipairs(world.projectiles) do
    if pr.kind == "grenade" then
      local total = defaults.weapon.grenade_fuse
      local frac = math.max(0, pr.fuse) / total
      love.graphics.setColor(1, 0.45, 0.25, 0.9)
      love.graphics.print(string.format("Live grenade: %.1fs", math.max(0, pr.fuse)), 40, 278)
      love.graphics.rectangle("line", 40, 298, 200, 8, 3, 3)
      love.graphics.setColor(1, 0.35, 0.2, 0.85)
      love.graphics.rectangle("fill", 42, 300, 196 * frac, 4, 2, 2)
      break
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_wind_timer(world, fonts, assets)
  love.graphics.setFont(fonts.small)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 932, 114, 328, 200, 10, 10)
  local w = world.settings.wind or "off"
  love.graphics.setColor(0.9, 0.92, 0.95, 1)
  if w ~= "off" and assets.ui_icon_wind then
    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.draw(assets.ui_icon_wind, 952, 132, 0, 0.42, 0.42)
    love.graphics.setColor(0.9, 0.92, 0.95, 1)
    love.graphics.print("Wind: " .. w, 1040, 148)
    local mag = world.wind_vx or 0
    love.graphics.print(mag >= 0 and "Blowing →" or "Blowing ←", 1040, 174)
    local dir = mag >= 0 and "→" or "←"
    love.graphics.setFont(fonts.hud)
    love.graphics.printf(dir, 952, 200, 260, "center")
  else
    love.graphics.print("Wind: off", 952, 148)
  end
  if (world.settings.turn_time_seconds or 0) > 0 then
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.85, 0.88, 0.92, 1)
    love.graphics.print("Turn limit enabled — see banner", 952, 228)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_roster(world, fonts)
  local turn = world.turn
  love.graphics.setFont(fonts.tiny)
  local function row(px, py, player, label)
    local team = defaults.colors["team" .. player]
    love.graphics.setColor(team[1], team[2], team[3], 0.9)
    love.graphics.print(label .. " · HP", px, py)
    for slot = 1, 5 do
      local m = nil
      for _, mm in ipairs(world.moles) do
        if mm.player == player and mm.slot == slot then
          m = mm
          break
        end
      end
      local x = px + (slot - 1) * 118
      local alive = m and m.alive
      local is_active = alive and (player == turn.active_player) and (slot == turn.mole_slot[player])
      love.graphics.setColor(0, 0, 0, alive and 0.4 or 0.22)
      love.graphics.rectangle("fill", x, py + 22, 108, 40, 6, 6)
      if is_active then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0.92, 0.38, 0.95)
        love.graphics.rectangle("line", x - 1, py + 21, 110, 42, 8, 8)
      end
      if m then
        love.graphics.setColor(1, 1, 1, alive and 1 or 0.32)
        local pct = alive and math.max(0, m.hp / m.max_hp) or 0
        love.graphics.rectangle("fill", x + 4, py + 44, 100 * pct, 9, 2, 2)
        love.graphics.setColor(0.95, 0.96, 0.98, alive and 1 or 0.45)
        love.graphics.print(string.format("S%i", slot), x + 6, py + 26)
        if alive then
          love.graphics.setColor(0.82, 0.92, 0.98, 1)
          love.graphics.print(string.format("%i", math.max(0, math.floor(m.hp + 0.5))), x + 52, py + 26)
        else
          love.graphics.setColor(0.65, 0.55, 0.55, 1)
          love.graphics.print("—", x + 70, py + 26)
        end
      end
    end
  end
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 20, 604, 1240, 108, 10, 10)
  row(40, 612, 1, "Team A")
  row(40, 658, 2, "Team B")
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_help_strip(fonts, input_mode)
  love.graphics.setFont(fonts.tiny)
  love.graphics.setColor(0, 0, 0, 0.45)
  love.graphics.rectangle("fill", 24, 532, 1232, 64, 8, 8)
  love.graphics.setColor(0.88, 0.9, 0.93, 1)
  local mode = (input_mode == "dual_gamepad") and "Two gamepads" or "Shared keyboard + mouse"
  local msg = (input_mode == "dual_gamepad")
      and ("Input: " .. mode .. " · left stick move · A jump · right stick aim · triggers power · B fire · LB/RB weapon · Y end turn · Start pause")
    or ("Input: " .. mode .. " · P1 WASD Q/E Z/X F G 1/2 · P2 arrows [ ] I/K ; Enter RCtrl BS · mouse = aim+fire for active player only")
  love.graphics.printf(msg, 36, 544, 1208, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

return M
