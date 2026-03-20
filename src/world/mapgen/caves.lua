local M = {}

function M.carve_spheres(terrain, rng, count, min_r, max_r)
  for _ = 1, count do
    local r = rng:random(min_r, max_r)
    local wx = rng:random(r + 8, terrain.world_w - r - 8)
    local wy = rng:random(r + 80, terrain.world_h - r - 40)
    terrain:carveCircle(wx, wy, r)
  end
end

return M
