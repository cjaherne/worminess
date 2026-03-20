local vec2 = require("core.vec2")

local M = {}

function M.new(owner_team, weapon_def, ox, oy, dirx, diry, power01, wind_x)
  power01 = math.max(0.15, math.min(1, power01))
  local sp = weapon_def.speed * power01
  local v = vec2.scale(vec2.norm({ x = dirx, y = diry }), sp)
  return {
    kind = "rocket",
    owner_team = owner_team,
    def = weapon_def,
    pos = { x = ox, y = oy },
    vel = { x = v.x, y = v.y },
    wind_scale = weapon_def.wind_scale or 0.5,
    dead = false,
    trail_t = 0,
  }
end

function M.update(p, dt, gravity, wind_x)
  if p.dead then
    return nil
  end
  p.vel.y = p.vel.y + gravity * dt
  p.vel.x = p.vel.x + wind_x * p.wind_scale * dt
  p.pos.x = p.pos.x + p.vel.x * dt
  p.pos.y = p.pos.y + p.vel.y * dt
  p.trail_t = p.trail_t + dt
  return p
end

return M
