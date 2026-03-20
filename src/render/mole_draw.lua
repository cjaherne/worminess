local defaults = require("config.defaults")
local W = require("sim.weapons.registry")

local M = {}

local SPR_SCALE = 0.058

local function team_key(player)
  return player == 1 and "a" or "b"
end

local function draw_sprite_shadow(img, x, y, r, sx, sy, ox, oy)
  love.graphics.setColor(0, 0, 0, 0.38)
  love.graphics.draw(img, x + 4, y + 5, r, sx, sy, ox, oy)
end

--- `turn_owner` dims the non-active team slightly for readability (whose turn it is).
function M.draw_mole(assets, m, aim_angle, is_active, turn_owner)
  local team = team_key(m.player)
  local moving = math.abs(m.vx) > 12
  local img
  if moving then
    local f = (love.timer.getTime() * 6) % 2 < 1 and 1 or 2
    img = assets["mole_" .. team .. "_walk_" .. f]
  else
    img = assets["mole_" .. team .. "_idle"]
  end
  if not img then return end
  local iw, ih = img:getDimensions()
  local sx = SPR_SCALE * m.facing
  local sy = SPR_SCALE
  local ox = iw * 0.5
  local oy = ih * 0.85

  local dim = (turn_owner and m.player ~= turn_owner and m.alive) and true or false
  if dim then
    love.graphics.setColor(0.78, 0.82, 0.9, 0.88)
  else
    love.graphics.setColor(1, 1, 1, m.alive and 1 or 0.32)
  end

  draw_sprite_shadow(img, m.x, m.y, 0, sx, sy, ox, oy)
  love.graphics.draw(img, m.x, m.y, 0, sx, sy, ox, oy)

  if m.alive then
    local tc = defaults.colors["team" .. m.player]
    love.graphics.setColor(tc[1], tc[2], tc[3], 0.55)
    love.graphics.ellipse("fill", m.x, m.y + m.r * 0.35, m.r * 1.1, m.r * 0.45)
  end

  if is_active and m.alive then
    love.graphics.setColor(1, 1, 1, 0.95)
    local aim_img = assets["mole_" .. team .. "_aim"]
    if aim_img then
      draw_sprite_shadow(aim_img, m.x, m.y, aim_angle + math.pi * 0.5, sx * 0.95, sy * 0.95, ox, oy)
      love.graphics.draw(aim_img, m.x, m.y, aim_angle + math.pi * 0.5, sx * 0.95, sy * 0.95, ox, oy)
    end
    love.graphics.setLineWidth(3)
    love.graphics.setColor(1, 0.92, 0.35, 0.92)
    love.graphics.circle("line", m.x, m.y, m.r + 6)
    love.graphics.setLineWidth(1)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local function draw_rocket_trail(pr)
  local vx, vy = pr.vx, pr.vy
  local len = math.sqrt(vx * vx + vy * vy)
  if len < 40 then return end
  local nx, ny = vx / len, vy / len
  for k = 1, 10 do
    local t = k / 10
    local px = pr.x - nx * (8 + k * 7)
    local py = pr.y - ny * (8 + k * 7)
    love.graphics.setColor(1, 0.25 + t * 0.45, 0.08, 0.5 * (1 - t * 0.85))
    love.graphics.circle("fill", px, py, 2.5 + t * 3.5)
  end
end

function M.draw_projectiles(assets, projectiles)
  for _, pr in ipairs(projectiles) do
    if pr.kind == "rocket" then
      draw_rocket_trail(pr)
      local img = assets.rocket
      if img then
        local ang = math.atan2(pr.vy, pr.vx)
        love.graphics.setColor(1, 0.55, 0.2, 0.95)
        love.graphics.circle("fill", pr.x - math.cos(ang) * 10, pr.y - math.sin(ang) * 10, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, pr.x, pr.y, ang, 0.065, 0.065, img:getWidth() * 0.5, img:getHeight() * 0.5)
        love.graphics.setColor(1, 0.95, 0.75, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.line(pr.x, pr.y, pr.x - math.cos(ang) * 22, pr.y - math.sin(ang) * 22)
        love.graphics.setLineWidth(1)
      else
        love.graphics.setColor(1, 0.35, 0.15, 1)
        love.graphics.circle("fill", pr.x, pr.y, 5)
        love.graphics.setColor(1, 1, 1, 1)
      end
    elseif pr.kind == "grenade" then
      local img = assets.grenade
      local pulse = 0.82 + 0.18 * math.sin(love.timer.getTime() * 16)
      local total = defaults.weapon.grenade_fuse
      local frac = math.max(0, pr.fuse) / total
      love.graphics.setColor(0.15, 0.15, 0.18, 0.65)
      love.graphics.circle("fill", pr.x + 3, pr.y + 4, 10 * pulse)
      love.graphics.setColor(1, 0.35, 0.12, 0.75)
      love.graphics.setLineWidth(2)
      love.graphics.arc("line", pr.x, pr.y, 16, -math.pi * 0.5, -math.pi * 0.5 + frac * math.pi * 2, 24)
      love.graphics.setLineWidth(1)
      local spark_a = love.timer.getTime() * 5
      love.graphics.setColor(1, 0.92, 0.35, pulse)
      love.graphics.circle(
        "fill",
        pr.x + math.cos(spark_a) * 12,
        pr.y + math.sin(spark_a) * 12,
        3
      )
      if img then
        love.graphics.setColor(0.35, 0.95, 0.45, pulse)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", pr.x, pr.y, 9 * pulse)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, pr.x, pr.y, 0, 0.068 * pulse, 0.068 * pulse, img:getWidth() * 0.5, img:getHeight() * 0.5)
      else
        love.graphics.setColor(0.35, 0.85, 0.35, pulse)
        love.graphics.circle("fill", pr.x, pr.y, 7)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end

function M.draw_particles(particles)
  for _, p in ipairs(particles) do
    love.graphics.setColor(p.c[1], p.c[2], p.c[3], math.max(0, p.t * 2.5))
    love.graphics.circle("fill", p.x, p.y, 3)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_aim_preview(m, aim_angle, power, weapon_index)
  if not m or not m.alive then return end
  love.graphics.setLineWidth(2)
  local col = weapon_index == W.rocket and { 1, 0.55, 0.25, 0.4 } or { 0.35, 0.95, 0.45, 0.4 }
  love.graphics.setColor(col[1], col[2], col[3], col[4])
  local len = weapon_index == W.rocket and 720 or 420
  local step = 14
  local ox = m.x + math.cos(aim_angle) * (m.r + 8)
  local oy = m.y + math.sin(aim_angle) * (m.r + 8)
  local px, py = ox, oy
  for i = 1, math.floor(len / step) do
    local nx = ox + math.cos(aim_angle) * (i * step)
    local ny = oy + math.sin(aim_angle) * (i * step)
    if i % 2 == 1 then
      love.graphics.line(px, py, nx, ny)
    end
    px, py = nx, ny
  end
  love.graphics.setColor(1, 0.9, 0.3, 0.45)
  love.graphics.circle("line", ox + math.cos(aim_angle) * len * 0.85, oy + math.sin(aim_angle) * len * 0.85, 6 + power * 6)
  love.graphics.setLineWidth(1)
  love.graphics.setColor(1, 1, 1, 1)
end

return M
