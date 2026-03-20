--- Logical 1280×720 layout inside resizable window (uniform scale + letterbox).

local LW, LH = 1280, 720

local M = {}

function M.logical_size()
  return LW, LH
end

function M.fit_transform()
  local w, h = love.graphics.getDimensions()
  local s = math.min(w / LW, h / LH)
  local ox = (w - LW * s) * 0.5
  local oy = (h - LH * s) * 0.5
  return ox, oy, s
end

--- Window pixels → logical (0..LW, 0..LH)
function M.screen_to_logical(mx, my)
  local ox, oy, s = M.fit_transform()
  return (mx - ox) / s, (my - oy) / s
end

return M
