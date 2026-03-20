local defaults = require("config.defaults")

local M = {}

function M.draw(terrain)
  local c = terrain.cell
  local col_dirt = defaults.colors.dirt
  local col_dark = defaults.colors.dirt_dark
  local col_grass = defaults.colors.grass
  love.graphics.setColor(col_dirt[1], col_dirt[2], col_dirt[3], 1)
  for gx = 1, terrain.gw do
    for gy = 1, terrain.gh do
      if terrain.solid[gx][gy] then
        local px = (gx - 1) * c
        local py = (gy - 1) * c
        local above = gy > 1 and terrain.solid[gx][gy - 1]
        if not above then
          love.graphics.setColor(col_grass[1], col_grass[2], col_grass[3], 1)
        else
          local shade = ((gx + gy) % 3 == 0) and col_dark or col_dirt
          love.graphics.setColor(shade[1], shade[2], shade[3], 1)
        end
        love.graphics.rectangle("fill", px, py, c, c)
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return M
