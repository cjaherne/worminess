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

return M
