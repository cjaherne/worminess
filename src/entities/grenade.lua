local vec2 = require("core.vec2")

local M = {}

function M.new(owner_team, weapon_def, ox, oy, dirx, diry, power01, fuse, wind_x)
  power01 = math.max(0.2, math.min(1, power01))
  local sp = weapon_def.speed * power01
  local v = vec2.scale(vec2.norm({ x = dirx, y = diry }), sp)
  return {
    kind = "grenade",
    owner_team = owner_team,
    def = weapon_def,
    pos = { x = ox, y = oy },
    vel = { x = v.x, y = v.y },
    fuse = fuse,
    wind_scale = weapon_def.wind_scale or 0.8,
    dead = false,
  }
end

function M.update(g, dt, gravity, wind_x, terrain, bounce)
  if g.dead then
    return
  end
  g.vel.y = g.vel.y + gravity * dt
  g.vel.x = g.vel.x + wind_x * g.wind_scale * dt
  local nx = g.pos.x + g.vel.x * dt
  local ny = g.pos.y + g.vel.y * dt
  local r = g.def.hit_radius or 10
  -- simple bounce: if center would be inside solid, reflect vy and nudge out
  if terrain:isSolidCircle(nx, ny, r) then
    -- try slide on x
    if not terrain:isSolidCircle(g.pos.x, ny, r) then
      nx = g.pos.x
      g.vel.x = -g.vel.x * bounce
    elseif not terrain:isSolidCircle(nx, g.pos.y, r) then
      ny = g.pos.y
      g.vel.y = -g.vel.y * bounce
    else
      g.vel.x = -g.vel.x * bounce * 0.6
      g.vel.y = -g.vel.y * bounce
      nx = g.pos.x
      ny = g.pos.y - 1
    end
  end
  g.pos.x, g.pos.y = nx, ny
  g.fuse = g.fuse - dt
  if g.fuse <= 0 then
    g.dead = true
  end
end

return M
