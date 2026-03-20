local C = require("data.constants")

local M = {}

function M.new(team_index, index_in_team, max_hp)
  return {
    team = team_index,
    index = index_in_team,
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    hp = max_hp,
    max_hp = max_hp,
    alive = true,
    radius = C.MOLE_RADIUS,
    facing = 1,
    grounded = false,
  }
end

function M.damage(m, amount, friendly_fire, attacker_team)
  if not m.alive then
    return
  end
  if not friendly_fire and attacker_team == m.team then
    return
  end
  m.hp = m.hp - amount
  if m.hp <= 0 then
    m.hp = 0
    m.alive = false
    m.vx, m.vy = 0, 0
  end
end

function M.apply_impulse(m, ix, iy)
  if not m.alive then
    return
  end
  m.vx = m.vx + ix
  m.vy = m.vy + iy
end

function M.draw(m, team_color)
  if not m.alive then
    return
  end
  local r = m.radius
  love.graphics.setColor(0, 0, 0, 0.22)
  love.graphics.ellipse("fill", m.x, m.y + r * 0.85, r * 1.05, r * 0.38)
  love.graphics.setColor(team_color[1] * 0.88, team_color[2] * 0.88, team_color[3] * 0.88, 1)
  love.graphics.circle("fill", m.x, m.y - 1, r * 1.02)
  love.graphics.setColor(team_color[1], team_color[2], team_color[3], 1)
  love.graphics.circle("fill", m.x, m.y, r)
  love.graphics.setColor(0.12, 0.08, 0.12, 0.85)
  love.graphics.circle("line", m.x, m.y, r)
  love.graphics.setColor(0.95, 0.9, 0.85, 1)
  love.graphics.printf(tostring(m.index), m.x - r, m.y - 6, r * 2, "center", 0, 0.65, 0.65)
end

return M
