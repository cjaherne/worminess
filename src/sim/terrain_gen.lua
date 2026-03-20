local Terrain = require("sim.terrain")
local defaults = require("config.defaults")

local M = {}

local function rng_next(seed)
  seed = (seed * 1103515245 + 12345) % (2 ^ 31)
  return seed, seed / (2 ^ 31)
end

local function height_at(seed, x, gw)
  local s = seed + x * 977
  local h = 0
  for i = 1, 4 do
    local r
    s, r = rng_next(s)
    local f = i * 0.015
    h = h + math.sin((x * f + r * 6) * math.pi * 2) * (0.08 / i)
  end
  local r
  s, r = rng_next(s)
  h = h + r * 0.05
  local base = 0.42 + h
  return math.max(0.22, math.min(0.78, base))
end

local function surface_y(terrain, gx)
  for gy = 1, terrain.gh do
    if terrain.solid[gx][gy] then
      return (gy - 1) * terrain.cell
    end
  end
  return terrain:height_px()
end

local function flat_run(terrain, gx0, gx1)
  local y0 = surface_y(terrain, gx0)
  local ok = true
  for gx = gx0, gx1 do
    if math.abs(surface_y(terrain, gx) - y0) > terrain.cell * 1.5 then
      ok = false
      break
    end
  end
  return ok, y0
end

local function find_spawns(terrain, gx0, gx1, count, mole_r)
  local ok, base_y = flat_run(terrain, gx0, gx1)
  if not ok then return nil end
  local w = (gx1 - gx0) * terrain.cell
  local step = w / (count + 1)
  local out = {}
  for i = 1, count do
    local px = (gx0 - 1) * terrain.cell + step * i
    local py = base_y - mole_r - 2
    out[#out + 1] = { x = px, y = py }
  end
  return out
end

--- Pure build: returns terrain + spawn tables or nil if retries exhausted
function M.build(seed, gw, gh, cell, mole_r, max_retries)
  gw = gw or defaults.grid_w
  gh = gh or defaults.grid_h
  cell = cell or defaults.cell
  mole_r = mole_r or defaults.mole_radius
  max_retries = max_retries or 48
  local attempt = 0
  local s = seed % 2147483647
  while attempt < max_retries do
    attempt = attempt + 1
    s = (s + attempt * 2654435761) % 2147483647
    local function solid_at(x, y)
      if y > gh or x < 1 or x > gw then return false end
      if y < 1 then return false end
      local nx = (x - 1) / (gw - 1)
      local h = height_at(s, nx, gw)
      local surface_row = math.floor((1 - h) * gh) + 1
      return y >= surface_row
    end
    local tr = Terrain.new(cell, gw, gh, solid_at)
    local left = find_spawns(tr, 8, math.floor(gw * 0.28), 5, mole_r)
    local right = find_spawns(tr, math.ceil(gw * 0.72), gw - 8, 5, mole_r)
    if left and right then
      return { terrain = tr, spawns_p1 = left, spawns_p2 = right, seed_used = s }
    end
  end
  return nil
end

return M
