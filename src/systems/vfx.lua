--- World-space particles: explosion rings/sparks, rocket puffs, light match-end burst.
local theme = require("ui.theme")

local M = {}
M.__index = M

function M.new()
  return setmetatable({
    rings = {},
    sparks = {},
    puffs = {},
    shake = 0,
  }, M)
end

function M:add_explosion(wx, wy, blast_radius, opts)
  opts = opts or {}
  local br = blast_radius or 72
  local heavy = opts.heavy
  self.shake = math.min(heavy and 26 or 16, self.shake + math.min(14, 6 + br * 0.08))
  local life = heavy and 0.55 or 0.42
  self.rings[#self.rings + 1] = { x = wx, y = wy, r = 8, rmax = br * 1.05, t = 0, life = life, a = 0.85 }
  self.rings[#self.rings + 1] = { x = wx, y = wy, r = 4, rmax = br * 0.65, t = 0.05, life = life * 0.9, a = 0.55 }
  local n = heavy and 28 or 18
  for _ = 1, n do
    local ang = love.math.random() * math.pi * 2
    local sp = love.math.random(80, 320) * (heavy and 1.15 or 1)
    self.sparks[#self.sparks + 1] = {
      x = wx,
      y = wy,
      vx = math.cos(ang) * sp,
      vy = math.sin(ang) * sp,
      t = 0,
      life = love.math.random(28, 55) / 100,
      s = love.math.random(3, 7),
      c = { theme.colors.accent[1], theme.colors.accent[2], theme.colors.accent[3] },
    }
  end
end

function M:add_muzzle(wx, wy, ang)
  for _ = 1, 5 do
    local a = ang + (love.math.random() - 0.5) * 0.5
    local sp = love.math.random(40, 120)
    self.puffs[#self.puffs + 1] = {
      x = wx,
      y = wy,
      vx = math.cos(a) * sp,
      vy = math.sin(a) * sp,
      t = 0,
      life = 0.12,
      r = love.math.random(2, 4),
    }
  end
end

function M:add_rocket_trail(x, y)
  self.puffs[#self.puffs + 1] = {
    x = x + love.math.random(-2, 2),
    y = y + love.math.random(-2, 2),
    vx = love.math.random(-20, 20),
    vy = love.math.random(-20, 20),
    t = 0,
    life = 0.18,
    r = love.math.random(2, 5),
    c = { 1, 0.55, 0.15 },
  }
end

function M:update(dt)
  self.shake = math.max(0, self.shake - dt * 26)

  for i = #self.rings, 1, -1 do
    local r = self.rings[i]
    r.t = r.t + dt
    if r.t >= r.life then
      table.remove(self.rings, i)
    end
  end
  for i = #self.sparks, 1, -1 do
    local s = self.sparks[i]
    s.t = s.t + dt
    s.vy = s.vy + 420 * dt
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
    if s.t >= s.life then
      table.remove(self.sparks, i)
    end
  end
  for i = #self.puffs, 1, -1 do
    local p = self.puffs[i]
    p.t = p.t + dt
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    if p.t >= p.life then
      table.remove(self.puffs, i)
    end
  end

end

function M:shake_offset()
  if self.shake <= 0.01 then
    return 0, 0
  end
  local s = self.shake
  return (love.math.random() - 0.5) * 2 * s, (love.math.random() - 0.5) * 2 * s
end

function M:draw_world()
  for _, r in ipairs(self.rings) do
    local k = r.t / r.life
    local rad = r.r + (r.rmax - r.r) * k
    local a = r.a * (1 - k)
    love.graphics.setColor(1, 0.75, 0.35, a)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", r.x, r.y, rad)
    love.graphics.setLineWidth(1)
  end
  for _, s in ipairs(self.sparks) do
    local k = s.t / s.life
    love.graphics.setColor(s.c[1], s.c[2], s.c[3], 1 - k)
    love.graphics.rectangle("fill", s.x - s.s * 0.5, s.y - s.s * 0.5, s.s, s.s)
  end
  for _, p in ipairs(self.puffs) do
    local k = p.t / p.life
    local c = p.c or { 1, 0.85, 0.5 }
    love.graphics.setColor(c[1], c[2], c[3], (1 - k) * 0.85)
    love.graphics.circle("fill", p.x, p.y, p.r * (1 + k * 0.4))
  end
end

return M
