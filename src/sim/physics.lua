local defaults = require("config.defaults")
local vec2 = require("util.vec2")

local M = {}

local function circle_terrain_overlap(terrain, cx, cy, r)
  local c = terrain.cell
  local steps = 10
  for i = 0, steps - 1 do
    local a = (i / steps) * math.pi * 2
    local px = cx + math.cos(a) * r
    local py = cy + math.sin(a) * r
    if terrain:is_solid_px(px, py) then
      return true
    end
  end
  if terrain:is_solid_px(cx, cy + r) then return true end
  if terrain:is_solid_px(cx, cy - r) then return true end
  return false
end

function M.update_mole(mole, terrain, dt, move_x, jump_pressed, gravity)
  gravity = gravity or defaults.gravity
  local r = mole.r
  mole.vy = mole.vy + gravity * dt
  if move_x ~= 0 then
    mole.facing = move_x > 0 and 1 or -1
  end
  mole.vx = move_x * defaults.walk_speed

  local nx = mole.x + mole.vx * dt
  local ny = mole.y + mole.vy * dt

  if circle_terrain_overlap(terrain, nx, mole.y, r) then
    mole.vx = 0
    nx = mole.x
  end

  local hit_ground = false
  if circle_terrain_overlap(terrain, nx, ny, r) then
    if mole.vy > 0 then
      local step = 2
      while not circle_terrain_overlap(terrain, mole.x, ny - step, r) and ny > r do
        ny = ny - step
      end
      mole.vy = 0
      hit_ground = true
    elseif mole.vy < 0 then
      mole.vy = 0
      ny = mole.y + 1
    end
    nx = mole.x + mole.vx * dt
    if circle_terrain_overlap(terrain, nx, ny, r) then
      nx = mole.x
      mole.vx = 0
    end
  end

  mole.grounded = circle_terrain_overlap(terrain, mole.x, ny + 1, r) or (hit_ground and mole.vy == 0)
  if jump_pressed and mole.grounded then
    mole.vy = -defaults.jump_speed
    mole.grounded = false
    ny = mole.y - 2
  end

  mole.x, mole.y = nx, ny

  if mole.y - r > terrain:height_px() + 200 then
    mole.hp = 0
  end
end

function M.segment_hits_terrain(terrain, x1, y1, x2, y2, steps)
  steps = steps or 32
  for i = 0, steps do
    local t = i / steps
    local px = x1 + (x2 - x1) * t
    local py = y1 + (y2 - y1) * t
    if terrain:is_solid_px(px, py) then
      return px, py
    end
  end
  return nil
end

function M.ray_mole_hit(moles, x1, y1, x2, y2, owner, friendly, steps)
  steps = steps or 40
  local best_t = nil
  local best_m = nil
  for i = 0, steps do
    local t = i / steps
    local px = x1 + (x2 - x1) * t
    local py = y1 + (y2 - y1) * t
    for _, m in ipairs(moles) do
      if m.alive then
        local same = (m.player == owner)
        if not same or friendly then
          local d = vec2.len(px - m.x, py - m.y)
          if d <= m.r + 2 then
            if not best_t or t < best_t then
              best_t = t
              best_m = m
            end
          end
        end
      end
    end
  end
  return best_m, best_t
end

return M
