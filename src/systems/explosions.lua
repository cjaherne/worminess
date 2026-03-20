local vec2 = require("core.vec2")
local roster = require("game.roster")
local mole_ent = require("entities.mole")

local M = {}

function M.apply(ctx, wx, wy, weapon_def, owner_team)
  local terrain = ctx.terrain
  local teams = ctx.teams
  local ff = ctx.match_config.friendly_fire
  local tr = weapon_def.terrain_radius or weapon_def.blast_radius
  terrain:carveCircle(wx, wy, tr)
  local br = weapon_def.blast_radius
  local dmax = weapon_def.damage_max
  local kb = weapon_def.knockback or 0
  local all = roster.all_moles(teams)
  local any_hurt = false
  for i = 1, #all do
    local m = all[i]
    if m.alive then
      local d = vec2.dist(m, { x = wx, y = wy })
      if d < br + m.radius then
        local t = 1 - (d / (br + m.radius))
        t = math.max(0, math.min(1, t))
        local dmg = dmax * t
        local hp0 = m.hp
        mole_ent.damage(m, dmg, ff, owner_team)
        if hp0 > m.hp then
          any_hurt = true
        end
        if m.alive then
          local dir = vec2.norm({ x = m.x - wx, y = m.y - wy })
          if dir.x == 0 and dir.y == 0 then
            dir.y = -1
          end
          mole_ent.apply_impulse(m, dir.x * kb * t * 0.02, dir.y * kb * t * 0.02)
        end
      end
    end
  end
  if any_hurt and ctx.feedback and ctx.feedback.on_moles_damaged then
    ctx.feedback.on_moles_damaged()
  end
  if ctx.feedback and ctx.feedback.on_explosion then
    ctx.feedback.on_explosion(wx, wy, weapon_def)
  end
end

return M
