local theme = require("ui.theme")
local turn_state = require("game.turn_state")
local weapons_data = require("data.weapons")

local M = {}

local function fmt_player(p)
  return "P" .. tostring(p)
end

function M.draw(ctx)
  local c = theme.colors
  local ts = ctx.turn
  local cfg = ctx.match_config
  local teams = ctx.teams
  local lw = theme.logical_w
  local fh = theme.font_hud or love.graphics.getFont()

  love.graphics.setFont(fh)
  love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], 1)
  love.graphics.printf("P1 round wins: " .. tostring(ctx.round_wins[1]), 24, 20, 440, "left")
  love.graphics.setColor(c.team_b[1], c.team_b[2], c.team_b[3], 1)
  love.graphics.printf("P2 round wins: " .. tostring(ctx.round_wins[2]), lw - 464, 20, 440, "right")

  love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 0.92)
  love.graphics.rectangle("fill", lw * 0.5 - 280, 16, 560, 56, 8, 8)
  love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
  local ap = ts.active_player
  local am = turn_state.active_mole(ts, teams)
  local mi = am and am.index or 0
  local phase_label = ts.phase
  if ts.phase == turn_state.phases.interstitial then
    phase_label = "round start"
  end
  love.graphics.printf(
    "Round " .. tostring(ctx.round_index) .. " · " .. fmt_player(ap) .. " · Mole " .. tostring(mi) .. " · " .. phase_label,
    lw * 0.5 - 270,
    32,
    540,
    "center",
    0,
    0.85,
    0.85
  )

  love.graphics.setFont(theme.font_body or love.graphics.getFont())
  love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.85)
  local s1, s2 = ctx.session:get_scores()
  love.graphics.printf("Session match wins  " .. tostring(s1) .. " — " .. tostring(s2), lw * 0.5 - 200, 78, 400, "center", 0, 0.7, 0.7)

  local wind = cfg.wind_strength or 0
  love.graphics.printf(
    wind == 0 and "Wind: calm" or ("Wind: " .. (wind > 0 and "→ " or "← ") .. string.format("%.0f", math.abs(wind))),
    lw * 0.5 - 160,
    100,
    320,
    "center",
    0,
    0.8,
    0.8
  )

  if ts.phase == turn_state.phases.interstitial and ctx.toast_text then
    local pulse = 0.88 + 0.12 * math.sin(love.timer.getTime() * 2 * math.pi * 0.9)
    love.graphics.setColor(0, 0, 0, 0.38 + 0.12 * pulse)
    love.graphics.rectangle("fill", 0, 200, lw, 120, 0, 0)
    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], pulse)
    love.graphics.printf(ctx.toast_text, 40, 232, lw - 80, "center", 0, 1.05, 1.05)
  end

  local mb = ts.move_budget or 0
  love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
  love.graphics.printf("Move", 48, 620, 120, "left", 0, 0.75, 0.75)
  love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.35)
  love.graphics.rectangle("fill", 48, 642, 200, 12, 4, 4)
  love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.9)
  local bw = 200 * math.max(0, math.min(1, mb / require("data.constants").MOVE_BUDGET_MAX))
  love.graphics.rectangle("fill", 48, 642, bw, 12, 4, 4)

  if ts.phase == turn_state.phases.aim then
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
    love.graphics.printf("Power", lw * 0.5 - 100, 620, 200, "center", 0, 0.75, 0.75)
    love.graphics.setColor(c.danger[1], c.danger[2], c.danger[3], 0.25)
    love.graphics.rectangle("fill", lw * 0.5 - 100, 642, 200, 12, 4, 4)
    love.graphics.setColor(c.danger[1], c.danger[2], c.danger[3], 0.95)
    love.graphics.rectangle("fill", lw * 0.5 - 100, 642, 200 * ts.power, 12, 4, 4)
  end

  local wy = 656
  local wx = 48
  for i, wid in ipairs(ts.weapons) do
    local def = weapons_data[wid]
    local sel = (ts.weapon_index == i)
    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], sel and 1 or 0.55)
    love.graphics.rectangle("fill", wx, wy, 64, 64, 6, 6)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
    if def then
      love.graphics.printf(def.name, wx, wy + 22, 64, "center", 0, 0.55, 0.55)
    end
    if sel then
      love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 1)
      love.graphics.rectangle("line", wx - 2, wy - 2, 68, 68, 8, 8)
    end
    wx = wx + 64 + 16
  end

  local fuse_txt = nil
  for j = 1, #ctx.grenades do
    local g = ctx.grenades[j]
    if g.fuse and g.fuse > 0 then
      fuse_txt = string.format("Grenade fuse: %.1fs", g.fuse)
      break
    end
  end
  if fuse_txt then
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
    love.graphics.printf(fuse_txt, lw - 280, wy + 8, 240, "right", 0, 0.85, 0.85)
  end

  local scheme = cfg.input_scheme or "shared_kb"
  local hint
  if scheme == "shared_kb" then
    hint = (ap == 1) and "P1: A/D move · W/S aim · Shift power · Mouse wheel power · Space fire · 1/2 weapon · Mouse aim · optional pad" or "P2: Arrows / optional 2nd (or shared) pad · RShift · Wheel power · Enter · Start pause"
  else
    hint = "Your turn: stick aim · A fire · LB/RB or triggers charge power · Start = pause (any pad)"
  end
  local hint_a = 0.58 + 0.2 * math.sin(love.timer.getTime() * 2 * math.pi * 0.75)
  love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], hint_a)
  love.graphics.printf(hint, 24, 568, lw - 48, "center", 0, 0.72, 0.72)

  if ts.turn_time_left then
    love.graphics.setColor(c.danger[1], c.danger[2], c.danger[3], 0.95)
    love.graphics.printf(string.format("Turn time: %.0fs", ts.turn_time_left), lw - 220, 120, 200, "right", 0, 0.8, 0.8)
  end
end

return M
