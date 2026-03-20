local defaults = require("config.defaults")

local M = {}

local SPR_SCALE = 0.058

local function team_key(player)
  return player == 1 and "a" or "b"
end

function M.draw_mole(assets, m, aim_angle, is_active)
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
  love.graphics.setColor(1, 1, 1, m.alive and 1 or 0.35)
  love.graphics.draw(img, m.x, m.y, 0, sx, sy, ox, oy)
  if is_active and m.alive then
    love.graphics.setColor(1, 1, 1, 0.9)
    local aim_img = assets["mole_" .. team .. "_aim"]
    if aim_img then
      love.graphics.draw(aim_img, m.x, m.y, aim_angle + math.pi * 0.5, sx * 0.95, sy * 0.95, ox, oy)
    end
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 0.95, 0.4, 0.85)
    love.graphics.circle("line", m.x, m.y, m.r + 5)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_projectiles(assets, projectiles)
  for _, pr in ipairs(projectiles) do
    if pr.kind == "rocket" then
      local img = assets.rocket
      if img then
        local ang = math.atan2(pr.vy, pr.vx)
        love.graphics.draw(img, pr.x, pr.y, ang, 0.06, 0.06, img:getWidth() * 0.5, img:getHeight() * 0.5)
      else
        love.graphics.setColor(1, 0.35, 0.15, 1)
        love.graphics.circle("fill", pr.x, pr.y, 4)
        love.graphics.setColor(1, 1, 1, 1)
      end
    elseif pr.kind == "grenade" then
      local img = assets.grenade
      local pulse = 0.85 + 0.15 * math.sin(love.timer.getTime() * 14)
      if img then
        love.graphics.setColor(1, 1, 1, pulse)
        love.graphics.draw(img, pr.x, pr.y, 0, 0.065 * pulse, 0.065 * pulse, img:getWidth() * 0.5, img:getHeight() * 0.5)
        love.graphics.setColor(1, 1, 1, 1)
      else
        love.graphics.setColor(0.35, 0.85, 0.35, pulse)
        love.graphics.circle("fill", pr.x, pr.y, 6)
        love.graphics.setColor(1, 1, 1, 1)
      end
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
  love.graphics.setColor(1, 1, 1, 0.35)
  local len = weapon_index == 1 and 720 or 420
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
  love.graphics.setColor(1, 0.9, 0.3, 0.5)
  love.graphics.circle("line", ox + math.cos(aim_angle) * len * 0.85, oy + math.sin(aim_angle) * len * 0.85, 6 + power * 6)
  love.graphics.setColor(1, 1, 1, 1)
end

return M
