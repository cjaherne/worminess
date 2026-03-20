local vec2 = require("util.vec2")

local M = {}

function M.explosion(world, px, py, blast_r, damage_max, knock, owner_player, friendly_fire)
  local terrain = world.terrain
  terrain:carve_circle(px, py, blast_r * 0.82)
  for _, m in ipairs(world.moles) do
    if m.alive then
      local dx, dy = m.x - px, m.y - py
      local d = vec2.len(dx, dy)
      if d < blast_r + m.r then
        local falloff = 1 - math.min(1, d / (blast_r + m.r))
        local dmg = damage_max * falloff
        local same_team = (m.player == owner_player)
        if same_team and not friendly_fire then
          dmg = 0
        end
        if dmg > 0 then
          m.hp = m.hp - dmg
          if knock and knock > 0 and falloff > 0.15 then
            local nx, ny = vec2.normalize(dx, dy)
            local imp = knock * falloff
            m.vx = m.vx + nx * imp
            m.vy = m.vy + ny * imp * 0.65
          end
        end
      end
    end
  end
end

return M
