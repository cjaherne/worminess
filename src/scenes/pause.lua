--- Overlay: simulation frozen while not top of stack is irrelevant — only pause updates.
local theme = require("ui.theme")
local layout = require("ui.layout")
local sfx = require("audio.sfx")

local ITEM_RESUME = 1
local ITEM_RESTART = 2
local ITEM_SETUP = 3
local ITEM_MENU = 4

local function new(play_scene)
  local self = {
    play = play_scene,
    ctx = nil,
    focus = ITEM_RESUME,
  }

  function self:enter(ctx)
    self.ctx = ctx
    self.focus = ITEM_RESUME
  end

  function self:resume()
    self.ctx.scenes:pop()
  end

  function self:keypressed(key)
    if key == "escape" then
      self:resume()
    elseif key == "up" then
      self.focus = self.focus - 1
      if self.focus < ITEM_RESUME then
        self.focus = ITEM_MENU
      end
    elseif key == "down" then
      self.focus = self.focus + 1
      if self.focus > ITEM_MENU then
        self.focus = ITEM_RESUME
      end
    elseif key == "return" or key == "space" or key == "kpenter" then
      self:confirm()
    end
  end

  function self:gamepadpressed(joystick, button)
    if button == "b" then
      self:resume()
    elseif button == "a" then
      self:confirm()
    elseif button == "dpup" then
      self:keypressed("up")
    elseif button == "dpdown" then
      self:keypressed("down")
    elseif button == "start" then
      self:resume()
    end
  end

  function self:mousepressed(x, y, button)
    if button ~= 1 then
      return
    end
    local lx, ly = layout.screen_to_logical(x, y)
    local bx, by, bw, bh, gap = 380, 200, 520, 48, 12
    for i = 1, 4 do
      local yy = by + (i - 1) * (bh + gap)
      if lx >= bx and lx <= bx + bw and ly >= yy and ly <= yy + bh then
        self.focus = i
        self:confirm()
        break
      end
    end
  end

  function self:confirm()
    if self.focus == ITEM_RESUME then
      self:resume()
    else
      sfx.play("ui", 0.38)
    end
    if self.focus == ITEM_RESUME then
      return
    elseif self.focus == ITEM_RESTART then
      self.ctx.scenes:pop()
      self.play:restart_match()
    elseif self.focus == ITEM_SETUP then
      self.ctx.scenes:pop()
      local ms = require("scenes.match_setup").new()
      self.ctx.scenes:replace(ms)
    elseif self.focus == ITEM_MENU then
      self.ctx.scenes:pop()
      local mm = require("scenes.main_menu").new()
      self.ctx.scenes:replace(mm)
    end
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.rectangle("fill", 340, 160, 600, 400, 12, 12)
    love.graphics.setFont(theme.font_banner)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
    love.graphics.printf("Paused", 340, 172, 600, "center")

    local s1, s2 = self.ctx.session:get_scores()
    local mc = self.ctx.session.matches_completed
    love.graphics.setFont(theme.font_body)
    love.graphics.printf(
      "Session · match wins: P1 " .. tostring(s1) .. "   P2 " .. tostring(s2) .. "\nMatches completed: " .. tostring(mc),
      360,
      214,
      560,
      "center"
    )

    local labels = { "Resume", "Restart match", "Match setup", "Main menu" }
    local bx, by, bw, bh, gap = 380, 278, 520, 48, 12
    for i = 1, #labels do
      local yy = by + (i - 1) * (bh + gap)
      local sel = (self.focus == i)
      if sel then
        love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.4)
        love.graphics.rectangle("fill", bx - 8, yy - 6, bw + 16, bh + 12, 8, 8)
      end
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
      love.graphics.printf(labels[i], bx, yy + 10, bw, "center")
    end

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.5)
    love.graphics.printf("Esc / B / Start · Up/Down · Enter", 0, 512, theme.logical_w, "center")
  end

  return self
end

return { new = new }
