local session_scores = require("data.session_scores")

local M = { id = "match_end" }

local args

function M.enter(_, a)
  args = a
end

function M.update(_, _) end

function M.draw(app)
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)
  love.graphics.setColor(0.08, 0.1, 0.14, 1)
  love.graphics.rectangle("fill", 240, 80, 800, 520, 14, 14)
  love.graphics.setFont(app.fonts.title)
  love.graphics.setColor(0.95, 0.96, 0.98, 1)
  local headline
  if args.winner == 0 then
    headline = "Draw"
  else
    headline = string.format("Player %i wins the match", args.winner)
  end
  love.graphics.printf(headline, 260, 110, 760, "center")
  love.graphics.setFont(app.fonts.hud)
  love.graphics.setColor(0.82, 0.86, 0.9, 1)
  local snap = session_scores.get_snapshot()
  love.graphics.printf(
    string.format("Session totals — P1: %i  P2: %i  Draws: %i", snap.gamesPlayedP1, snap.gamesPlayedP2, snap.gamesDrawn),
    260,
    200,
    760,
    "center"
  )
  local seed_label = args.map_seed_used or args.settings.map_seed or "(random)"
  love.graphics.printf("Map seed used: " .. tostring(seed_label), 260, 250, 760, "center")
  love.graphics.setFont(app.fonts.small)
  love.graphics.setColor(0.75, 0.8, 0.88, 1)
  love.graphics.printf("Enter: Rematch   S: New setup   Esc: Title", 260, 460, 760, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

function M.keypressed(app, key)
  if key == "return" or key == "kpenter" then
    app.goto("play", args.settings)
  elseif key == "s" then
    app.goto("match_setup")
  elseif key == "escape" then
    app.goto("menu")
  end
end

return M
