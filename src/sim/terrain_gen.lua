local Terrain = require("sim.terrain")
local defaults = require("config.defaults")

local M = {}

local function rng_next(seed)
  seed = (seed * 1103515245 + 12345) % (2 ^ 31)
  return seed, seed / (2 ^ 31)
end

--- Base height sample in ~[0.22, 0.78]; larger => surface row moves up (more sky / steeper silhouette).
local function height_at(seed, nx, _)
  local s = seed + nx * 977
  local h = 0
  for i = 1, 5 do
    local r
    s, r = rng_next(s)
    local f = i * 0.014
    h = h + math.sin((nx * f + r * 6.2) * math.pi * 2) * (0.09 / i)
  end
  local r
  s, r = rng_next(s)
  h = h + r * 0.045
  -- Ridged crests (readable silhouettes for artillery reads)
  local ridge = math.abs(math.sin(nx * math.pi * 3.1 + seed * 0.000001)) * 0.05
  h = h + ridge
  local base = 0.42 + h
  return math.max(0.22, math.min(0.78, base))
end

--- Per-column blended heights: warp + smooth + mild left/right bias so teams don’t mirror perfectly.
local function column_heights(seed, gw)
  local raw = {}
  for gx = 1, gw do
    local nx = (gx - 1) / math.max(1, gw - 1)
    raw[gx] = height_at(seed, nx, gw)
  end
  local warped = {}
  for gx = 1, gw do
    local w = math.sin(gx * 0.095 + seed * 3.1e-8) * 0.055
    local nx = (gx - 1) / math.max(1, gw - 1) + w
    nx = nx - math.floor(nx)
    warped[gx] = height_at(seed + gx * 131, nx, gw) * 0.5 + raw[gx] * 0.5
  end
  local sm = {}
  for gx = 1, gw do
    local a = warped[math.max(1, gx - 1)]
    local b = warped[gx]
    local c = warped[math.min(gw, gx + 1)]
    sm[gx] = (a + 2 * b + c) / 4
  end
  for gx = 1, gw do
    local t = (gx - 1) / math.max(1, gw - 1)
    local bias = (t - 0.5) * 0.065
    sm[gx] = math.max(0.22, math.min(0.78, sm[gx] + bias))
  end
  return sm
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
  local tol = math.max(terrain.cell * 12, 64)
  local ok = true
  for gx = gx0, gx1 do
    if math.abs(surface_y(terrain, gx) - y0) > tol then
      ok = false
      break
    end
  end
  return ok, y0
end

local function find_spawns(terrain, gx0, gx1, count, mole_r)
  local ok, base_y = flat_run(terrain, gx0, gx1)
  if not ok then return nil end
  local w = (gx1 - gx0 + 1) * terrain.cell
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
  max_retries = max_retries or 72
  local attempt = 0
  local s = seed % 2147483647
  while attempt < max_retries do
    attempt = attempt + 1
    s = (s + attempt * 2654435761) % 2147483647
    local col = column_heights(s, gw)
    local function solid_at(x, y)
      if y > gh or x < 1 or x > gw then return false end
      if y < 1 then return false end
      local h = col[x]
      local surface_row = math.floor((1 - h) * gh) + 1
      return y >= surface_row
    end
    local tr = Terrain.new(cell, gw, gh, solid_at)
    -- Narrow bands: `flat_run` requires uniform surface height across the whole span; a ~28% slice
    -- of the map is too wide for typical rolling heightfields and caused endless build failures.
    local band = math.max(14, math.min(32, math.floor(gw * 0.05)))
    local left = find_spawns(tr, 8, 8 + band - 1, 5, mole_r)
    local gx_right0 = gw - 8 - band + 1
    local right = find_spawns(tr, gx_right0, gw - 8, 5, mole_r)
    if left and right then
      return { terrain = tr, spawns_p1 = left, spawns_p2 = right, seed_used = s }
    end
  end
  return nil
end

return M
