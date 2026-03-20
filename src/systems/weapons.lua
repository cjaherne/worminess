local weapons_data = require("data.weapons")
local projectile = require("entities.projectile")
local grenade = require("entities.grenade")
local turn_state = require("game.turn_state")

local M = {}

local function muzzle_offset(angle, dist)
  return math.cos(angle) * dist, math.sin(angle) * dist
end

function M.try_fire(ctx)
  local ts = ctx.turn
  if ts.phase ~= turn_state.phases.aim then
    return false
  end
  local m = turn_state.active_mole(ts, ctx.teams)
  if not m or not m.alive then
    return false
  end
  local wid = ts.weapons[ts.weapon_index]
  local def = weapons_data[wid]
  if not def then
    return false
  end
  local ang = ts.aim_angle
  local ox, oy = muzzle_offset(ang, m.radius + 6)
  local wx = m.x + ox
  local wy = m.y + oy
  local dirx, diry = math.cos(ang), math.sin(ang)
  local wind = ctx.match_config.wind_strength or 0
  local team = m.team
  local pwr = ts.power
  if pwr < 0.05 then
    pwr = 0.35
  end
  if wid == "rocket" then
    local p = projectile.new(team, def, wx, wy, dirx, diry, pwr, wind)
    ctx.projectiles[#ctx.projectiles + 1] = p
  elseif wid == "grenade" then
    local fuse = ctx.match_config.grenade_fuse_seconds or 3
    local bounce = def.restitution or 0.35
    local g = grenade.new(team, def, wx, wy, dirx, diry, pwr, fuse, wind)
    g._bounce = bounce
    ctx.grenades[#ctx.grenades + 1] = g
  else
    return false
  end
  if ctx.feedback and ctx.feedback.on_weapon_fire then
    ctx.feedback.on_weapon_fire(wid, wx, wy, ang)
  end
  ts.phase = turn_state.phases.flying
  ts.power = 0
  ts.charging = false
  ts.move_budget = 0
  return true
end

return M
