local defaults = require("config.defaults")
local damage = require("sim.damage")
local physics = require("sim.physics")
local mole_mod = require("sim.mole")
local terrain_gen = require("sim.terrain_gen")
local TurnState = require("sim.turn_state")
local rocket_w = require("sim.weapons.rocket")
local grenade_w = require("sim.weapons.grenade")
local vec2 = require("util.vec2")

local M = {}
M.__index = M

local function team_alive(moles, player)
  for _, m in ipairs(moles) do
    if m.player == player and m.alive then return true end
  end
  return false
end

local function wind_vx(settings, terrain_seed_used)
  local w = settings.wind or "off"
  local f = defaults.wind_force
  if w == "off" then return 0 end
  local mag = (w == "high" and f.high) or (w == "med" and f.med) or f.low
  local salt = terrain_seed_used or settings.map_seed or 1
  return salt % 2 == 0 and mag or -mag
end

local function rocket_segment_hit(world, ox, oy, nx, ny, owner)
  local tr = world.terrain
  local steps = defaults.weapon.rocket_ray_steps or 56
  for i = 1, steps do
    local t = i / steps
    local px = ox + (nx - ox) * t
    local py = oy + (ny - oy) * t
    if tr:is_solid_px(px, py) then
      return px, py
    end
    for _, m in ipairs(world.moles) do
      if m.alive then
        local same = m.player == owner
        if not same or world.settings.friendly_fire then
          if vec2.len(px - m.x, py - m.y) <= m.r + 3 then
            return m.x, m.y
          end
        end
      end
    end
  end
  return nil, nil
end

function M.new(settings)
  local seed = settings.map_seed
  if seed == nil then
    seed = love.math.random(1, 2000000000)
  end
  local built = terrain_gen.build(seed, defaults.grid_w, defaults.grid_h, defaults.cell, defaults.mole_radius)
  if not built then
    built = terrain_gen.build(love.math.random(1, 2000000000), defaults.grid_w, defaults.grid_h, defaults.cell, defaults.mole_radius)
  end
  local moles = {}
  for _, m in ipairs(mole_mod.spawn_team(built.spawns_p1, 1, settings.mole_max_hp)) do
    moles[#moles + 1] = m
  end
  for _, m in ipairs(mole_mod.spawn_team(built.spawns_p2, 2, settings.mole_max_hp)) do
    moles[#moles + 1] = m
  end
  local self = setmetatable({
    settings = settings,
    terrain = built.terrain,
    moles = moles,
    projectiles = {},
    particles = {},
    turn = TurnState.new(settings),
    map_seed_used = built.seed_used,
    aim_angle = -math.pi * 0.4,
    power = 0.72,
    weapon_index = 1,
    fired_this_turn = false,
    won = false,
    winner = 0,
    wind_vx = wind_vx(settings, built.seed_used),
    match_time = 0,
  }, M)
  self.turn:sync_slots_to_living(self.moles)
  return self
end

function M:check_win()
  local a = team_alive(self.moles, 1)
  local b = team_alive(self.moles, 2)
  if not a and not b then
    self.won, self.winner = true, 0
  elseif not a then
    self.won, self.winner = true, 2
  elseif not b then
    self.won, self.winner = true, 1
  end
end

function M:explode_at(px, py, blast, dmg, owner)
  damage.explosion(self, px, py, blast, dmg, 420, owner, self.settings.friendly_fire)
  for _ = 1, 18 do
    local a = love.math.random() * math.pi * 2
    local sp = 80 + love.math.random() * 160
    self.particles[#self.particles + 1] = {
      x = px,
      y = py,
      vx = math.cos(a) * sp,
      vy = math.sin(a) * sp,
      t = 0.35 + love.math.random() * 0.25,
      c = { 1, 0.45 + love.math.random() * 0.2, 0.15 },
    }
  end
  self:check_win()
end

function M:update_particles(dt)
  for i = #self.particles, 1, -1 do
    local p = self.particles[i]
    p.t = p.t - dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.vy = p.vy + 120 * dt
    if p.t <= 0 then table.remove(self.particles, i) end
  end
end

function M:integrate_projectiles(dt)
  local wdef = defaults.weapon
  local tr = self.terrain
  local g = defaults.gravity

  for i = #self.projectiles, 1, -1 do
    local pr = self.projectiles[i]
    if pr.dead then
      table.remove(self.projectiles, i)
    elseif pr.kind == "rocket" then
      local ox, oy = pr.x, pr.y
      local rg = wdef.rocket_gravity_mul or 0.2
      pr.vy = pr.vy + g * rg * dt
      pr.x = pr.x + pr.vx * dt + self.wind_vx * dt * 0.12
      pr.y = pr.y + pr.vy * dt
      local hx, hy = rocket_segment_hit(self, ox, oy, pr.x, pr.y, pr.owner)
      if hx then
        self:explode_at(hx, hy, wdef.rocket_blast, wdef.rocket_damage, pr.owner)
        pr.dead = true
      elseif pr.x < -200 or pr.x > tr:width_px() + 200 or pr.y < -400 or pr.y > tr:height_px() + 400 then
        pr.dead = true
      end
    elseif pr.kind == "grenade" then
      pr.vy = pr.vy + g * dt
      pr.vx = pr.vx + self.wind_vx * dt * 0.25
      local ox, oy = pr.x, pr.y
      pr.x = pr.x + pr.vx * dt
      pr.y = pr.y + pr.vy * dt
      pr.fuse = pr.fuse - dt
      if tr:is_solid_px(pr.x, pr.y) then
        pr.x, pr.y = ox, oy
        pr.vy = -pr.vy * wdef.grenade_bounce
        pr.vx = pr.vx * wdef.grenade_bounce
        local unst = wdef.grenade_unstick_px or 3
        for _ = 1, 10 do
          if not tr:is_solid_px(pr.x, pr.y) then break end
          pr.y = pr.y - unst
        end
      end
      if pr.fuse <= 0 then
        self:explode_at(pr.x, pr.y, wdef.grenade_blast, wdef.grenade_damage, pr.owner)
        pr.dead = true
      end
    end
  end
end

function M:try_fire()
  if self.won or self.fired_this_turn or #self.projectiles > 0 then return false end
  local m = self.turn:active_mole(self.moles)
  if not m or not m.alive then return false end
  if self.weapon_index == 1 then
    rocket_w.spawn(self, m, self.aim_angle, self.power)
  else
    grenade_w.spawn(self, m, self.aim_angle, self.power)
  end
  self.fired_this_turn = true
  return true
end

function M:try_end_turn()
  if self.won or #self.projectiles > 0 then return false end
  self.turn:end_turn(self.moles, self.settings)
  self.fired_this_turn = false
  self:check_win()
  return true
end

function M:update(dt, intents, cam_mx, cam_my, use_mouse_aim)
  dt = math.min(dt, defaults.max_dt)
  self.match_time = self.match_time + dt
  self:update_particles(dt)

  if self.won then return end

  if self.turn:update_timer(dt, self.moles, self.settings) then
    self.fired_this_turn = false
    self:check_win()
  end

  self:integrate_projectiles(dt)

  for _, m in ipairs(self.moles) do
    if m.hp <= 0 then m.alive = false end
  end

  local active = self.turn:active_mole(self.moles)
  local ap = self.turn.active_player
  local intent = intents and intents[ap] or nil

  for _, m in ipairs(self.moles) do
    if m.alive then
      if active and m == active and intent and #self.projectiles == 0 then
        if intent._use_absolute_aim and intent._aim_absolute then
          self.aim_angle = intent._aim_absolute
        elseif use_mouse_aim and cam_mx and cam_my then
          self.aim_angle = vec2.angle_to(cam_mx - m.x, cam_my - m.y)
        end
        local ang = self.aim_angle
        if intent.aim_delta ~= 0 then
          ang = ang + intent.aim_delta * dt * 1.85
        end
        self.aim_angle = math.max(-math.pi * 0.95, math.min(-0.08, ang))
        if intent.power_delta ~= 0 then
          self.power = math.max(0.35, math.min(1, self.power + intent.power_delta * dt * 0.55))
        end
        if intent.cycle_weapon then
          self.weapon_index = 3 - self.weapon_index
        end
        if intent.fire_pressed then
          self:try_fire()
        end
        if intent.end_turn_pressed then
          self:try_end_turn()
        end
        physics.update_mole(m, self.terrain, dt, intent.move_x or 0, intent.jump, defaults.gravity)
      else
        physics.update_mole(m, self.terrain, dt, 0, false, defaults.gravity)
      end
    end
  end

  self:check_win()
end

return M
