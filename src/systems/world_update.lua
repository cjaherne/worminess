local C = require("data.constants")
local collision = require("world.collision")
local explosions = require("systems.explosions")
local roster = require("game.roster")
local mole_ent = require("entities.mole")
local grenade_mod = require("entities.grenade")

local M = {}

local function update_mole_physics(ctx, m, terrain, dt)
  if not m.alive then
    return
  end
  m.vy = m.vy + C.GRAVITY * dt
  local nx, ny, nvx, nvy = collision.circle_resolve_slide(terrain, m.x, m.y, m.radius, m.vx, m.vy, dt)
  m.x, m.y, m.vx, m.vy = nx, ny, nvx, nvy
  local ground = terrain:isSolidCircle(m.x, m.y + m.radius + 1, 2)
  m.grounded = ground
  if m.grounded and m.vy > C.FALL_DAMAGE_THRESHOLD * dt then
    local dmg = (m.vy - C.FALL_DAMAGE_THRESHOLD * dt) * C.FALL_DAMAGE_MULT
    if dmg > 2 then
      local hp0 = m.hp
      mole_ent.damage(m, dmg, true, m.team)
      if ctx.feedback and ctx.feedback.on_moles_damaged and m.hp < hp0 then
        ctx.feedback.on_moles_damaged(true)
      end
    end
  end
end

function M.update_moles(ctx, dt)
  local terrain = ctx.terrain
  local teams = ctx.teams
  for t = 1, #teams do
    for i = 1, #teams[t].moles do
      update_mole_physics(ctx, teams[t].moles[i], terrain, dt)
    end
  end
end

--- Projectile vs living mole capsule (circle); any team.
local function living_mole_hit_at(teams, px, py, pr)
  local all = roster.all_moles(teams)
  for i = 1, #all do
    local m = all[i]
    if m.alive then
      local dx, dy = px - m.x, py - m.y
      local rr = pr + m.radius
      if dx * dx + dy * dy <= rr * rr then
        return true
      end
    end
  end
  return false
end

local function step_rocket(ctx, p, dt)
  local terrain = ctx.terrain
  local def = p.def
  local steps = math.max(1, math.ceil((math.abs(p.vel.x) + math.abs(p.vel.y)) * dt / 6))
  local sub = dt / steps
  for _ = 1, steps do
    p.vel.y = p.vel.y + C.GRAVITY * sub
    local wind = (ctx.match_config.wind_strength or 0) * (p.wind_scale or 0.5)
    p.vel.x = p.vel.x + wind * sub
    local nx = p.pos.x + p.vel.x * sub
    local ny = p.pos.y + p.vel.y * sub
    local r = def.hit_radius or 8
    if nx < -80 or nx > ctx.world_w + 80 or ny < -200 or ny > ctx.world_h + 200 then
      p.dead = true
      return
    end
    if living_mole_hit_at(ctx.teams, nx, ny, r) then
      explosions.apply(ctx, nx, ny, def, p.owner_team)
      p.dead = true
      return
    end
    if terrain:isSolidCircle(nx, ny, r) then
      explosions.apply(ctx, p.pos.x, p.pos.y, def, p.owner_team)
      p.dead = true
      return
    end
    p.pos.x, p.pos.y = nx, ny
  end
  if not p.dead and ctx.feedback and ctx.feedback.on_rocket_trail then
    ctx.feedback.on_rocket_trail(p.pos.x, p.pos.y)
  end
end

function M.update_projectiles(ctx, dt)
  local list = ctx.projectiles
  local i = 1
  while i <= #list do
    local p = list[i]
    if p.dead then
      table.remove(list, i)
    else
      step_rocket(ctx, p, dt)
      if p.dead then
        table.remove(list, i)
      else
        i = i + 1
      end
    end
  end
end

function M.update_grenades(ctx, dt)
  local terrain = ctx.terrain
  local list = ctx.grenades
  local wind = ctx.match_config.wind_strength or 0
  local i = 1
  while i <= #list do
    local g = list[i]
    if g.dead then
      local def = g.def
      explosions.apply(ctx, g.pos.x, g.pos.y, def, g.owner_team)
      table.remove(list, i)
    else
      local bounce = g._bounce or (g.def.restitution or 0.35)
      grenade_mod.update(g, dt, C.GRAVITY, wind, terrain, bounce)
      if g.dead then
        local def = g.def
        explosions.apply(ctx, g.pos.x, g.pos.y, def, g.owner_team)
        table.remove(list, i)
      else
        local gr = g.def.hit_radius or 10
        if living_mole_hit_at(ctx.teams, g.pos.x, g.pos.y, gr) then
          local def = g.def
          explosions.apply(ctx, g.pos.x, g.pos.y, def, g.owner_team)
          table.remove(list, i)
        else
          g._trail_acc = (g._trail_acc or 0) + dt
          if g._trail_acc >= 0.08 then
            g._trail_acc = 0
            if ctx.feedback and ctx.feedback.on_grenade_trail then
              ctx.feedback.on_grenade_trail(g.pos.x, g.pos.y)
            end
          end
          i = i + 1
        end
      end
    end
  end
end

return M
