--- Logical 1280×720 canvas, uniform scale, letterboxing (void outside).
local constants = require("data.constants")

local M = {}

M.colors = {
  void = { 26 / 255, 20 / 255, 35 / 255, 1 },
  paper = { 244 / 255, 237 / 255, 224 / 255, 1 },
  ink = { 43 / 255, 31 / 255, 51 / 255, 1 },
  team_a = { 108 / 255, 181 / 255, 200 / 255, 1 },
  team_b = { 232 / 255, 162 / 255, 60 / 255, 1 },
  accent = { 196 / 255, 77 / 255, 255 / 255, 1 },
  danger = { 226 / 255, 74 / 255, 74 / 255, 1 },
}

M.safe_margin = 24
M.logical_w = constants.WORLD_W
M.logical_h = constants.WORLD_H

M.font_body = nil
M.font_hud = nil

function M.load_fonts()
  M.font_body = love.graphics.newFont(22)
  M.font_hud = love.graphics.newFont(28)
  love.graphics.setFont(M.font_body)
end

function M.begin_draw()
  local dw, dh = love.graphics.getDimensions()
  local lw, lh = M.logical_w, M.logical_h
  local scale = math.min(dw / lw, dh / lh)
  local ox = (dw - lw * scale) * 0.5
  local oy = (dh - lh * scale) * 0.5
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(scale, scale)
end

function M.end_draw()
  love.graphics.pop()
end

--- Screen-space clear before logical draw (identity transform).
function M.clear_void()
  local c = M.colors.void
  love.graphics.clear(c[1], c[2], c[3], c[4])
end

return M
