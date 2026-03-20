--- Main menu: session wins, Local match → match_setup, Options stub, Quit.
local theme = require("ui.theme")
local sfx = require("audio.sfx")

local ITEM_LOCAL = 1
local ITEM_OPTIONS = 2
local ITEM_QUIT = 3

local function new()
  local self = {
    ctx = nil,
    focus = ITEM_LOCAL,
    options_toast_t = 0,
  }

  function self:enter(ctx)
    self.ctx = ctx
    self.options_toast_t = 0
  end

  function self:update(dt)
    if self.options_toast_t > 0 then
      self.options_toast_t = math.max(0, self.options_toast_t - dt)
    end
  end

  local function confirm(self)
    if self.focus == ITEM_LOCAL then
      sfx.play("ui", 0.5)
      local ms = require("scenes.match_setup").new()
      self.ctx.scenes:replace(ms)
    elseif self.focus == ITEM_OPTIONS then
      self.options_toast_t = 2.5
    elseif self.focus == ITEM_QUIT then
      love.event.quit()
    end
  end

  function self:keypressed(key)
    if key == "up" or key == "w" then
      self.focus = self.focus - 1
      if self.focus < ITEM_LOCAL then
        self.focus = ITEM_QUIT
      end
    elseif key == "down" or key == "s" then
      self.focus = self.focus + 1
      if self.focus > ITEM_QUIT then
        self.focus = ITEM_LOCAL
      end
    elseif key == "return" or key == "space" or key == "kpenter" then
      confirm(self)
    elseif key == "escape" then
      love.event.quit()
    end
  end

  function self:gamepadpressed(_, button)
    if button == "a" then
      confirm(self)
    elseif button == "b" then
      love.event.quit()
    elseif button == "dpup" then
      self:keypressed("up")
    elseif button == "dpdown" then
      self:keypressed("down")
    end
  end

  function self:mousepressed(_, _, button)
    if button ~= 1 then
      return
    end
    -- Hit regions aligned with draw (left panel).
    local x0, y0, bw, bh, gap = 80, 160, 520, 56, 56
    for i = 1, 3 do
      local y = y0 + (i - 1) * (bh + gap)
      local mx, my = love.mouse.getPosition()
      local lw, scale = theme.logical_w, 1
      local dw, dh = love.graphics.getDimensions()
      local sc = math.min(dw / lw, dh / theme.logical_h)
      local ox = (dw - lw * sc) * 0.5
      local oy = (dh - theme.logical_h * sc) * 0.5
      local lx = (mx - ox) / sc
      local ly = (my - oy) / sc
      if lx >= x0 and lx <= x0 + bw and ly >= y and ly <= y + bh then
        self.focus = i
        confirm(self)
        break
      end
    end
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(c.void[1], c.void[2], c.void[3], 1)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    love.graphics.setFont(theme.font_title)
    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.printf("Moles", 0, 56, theme.logical_w, "center")

    local s1, s2 = self.ctx.session:get_scores()
    local mc = self.ctx.session.matches_completed
    love.graphics.setFont(theme.font_hud)
    love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], 1)
    love.graphics.printf("P1 match wins: " .. tostring(s1), 80, 118, 520, "left")
    love.graphics.setColor(c.team_b[1], c.team_b[2], c.team_b[3], 1)
    love.graphics.printf("P2 match wins: " .. tostring(s2), theme.logical_w - 80 - 520, 118, 520, "right")
    love.graphics.setFont(theme.font_body)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.85)
    love.graphics.printf("Matches completed: " .. tostring(mc), 0, 154, theme.logical_w, "center")

    local labels = { "Local match", "Options", "Quit" }
    local x0, y0, bw, bh, gap = 80, 160, 520, 56, 56
    for i = 1, #labels do
      local y = y0 + (i - 1) * (bh + gap)
      local sel = (self.focus == i)
      if sel then
        love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.35)
        love.graphics.rectangle("fill", x0 - 12, y - 8, bw + 24, bh + 16, 10, 10)
      end
      love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], sel and 1 or 0.75)
      love.graphics.rectangle("fill", x0, y, bw, bh, 8, 8)
      love.graphics.setFont(theme.font_body)
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
      love.graphics.printf(labels[i], x0, y + 14, bw, "center")
    end

    love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], 0.25)
    love.graphics.rectangle("fill", 640, 80, 560, 560, 12, 12)
    love.graphics.setFont(theme.font_body)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.5)
    love.graphics.printf("Art / mole panel\n(placeholder)", 640, 292, 560, "center")

    if self.options_toast_t > 0 then
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
      love.graphics.printf("Options: not in this build (stub).", 0, 612, theme.logical_w, "center")
    end

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.45)
    love.graphics.printf("Up/Down · Enter · Click · Pad A/B", 0, 676, theme.logical_w, "center")
  end

  return self
end

return { new = new }
