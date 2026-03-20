local M = {}

-- Fills terrain solid where y >= surface(x) + cave noise (simple 1D surface)
function M.apply_surface(terrain, rng, base_y, amp)
  local w = terrain.world_w
  local cell = terrain.cell
  local samples = math.ceil(w / cell)
  local surf = {}
  for i = 0, samples - 1 do
    local x = i * cell
    local n =
      math.sin(x / 90) * amp * 0.6 + math.sin(x / 40 + 1.7) * amp * 0.35 + rng:random() * amp * 0.12
    surf[i + 1] = base_y + n
  end
  for cy = 0, terrain.gh - 1 do
    for cx = 0, terrain.gw - 1 do
      local wx = (cx + 0.5) * cell
      local ix = math.min(samples, math.max(1, math.floor(wx / cell) + 1))
      local sy = surf[ix]
      local wy = (cy + 0.5) * cell
      if wy >= sy then
        terrain:setSolid(cx, cy, true)
      end
    end
  end
end

return M
