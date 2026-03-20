--- Helpers for logical 1280×720 layout (safe margin from theme).
local theme = require("ui.theme")

local M = {}

function M.safe_x0()
  return theme.safe_margin
end

function M.safe_x1()
  return theme.logical_w - theme.safe_margin
end

function M.screen_to_logical(mx, my)
  local dw, dh = love.graphics.getDimensions()
  local lw, lh = theme.logical_w, theme.logical_h
  local sc = math.min(dw / lw, dh / lh)
  local ox = (dw - lw * sc) * 0.5
  local oy = (dh - lh * sc) * 0.5
  return (mx - ox) / sc, (my - oy) / sc
end

return M
