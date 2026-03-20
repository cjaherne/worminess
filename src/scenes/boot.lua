--- Title splash → main_menu (time, Enter, Space, or gamepad A).
local theme = require("ui.theme")

local AUTO_ADVANCE_S = 2.4
local PULSE_HZ = 0.85

local function go_menu(self)
  local main_menu = require("scenes.main_menu").new()
  self.ctx.scenes:replace(main_menu)
end

local function new()
  local self = {
    t = 0,
    ctx = nil,
  }

  function self:enter(ctx)
    self.ctx = ctx
    self.t = 0
  end

  function self:update(dt)
    self.t = self.t + dt
    if self.t >= AUTO_ADVANCE_S then
      go_menu(self)
    end
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(c.void[1], c.void[2], c.void[3], 1)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    local title = "Moles"
    local subtitle = "Local 2 players · Moles with heavy weapons"
    local pulse = 0.55 + 0.45 * math.sin(self.t * math.pi * 2 * PULSE_HZ)

    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.printf(title, 0, 240, theme.logical_w, "center", 0, 2.2, 2.2)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.92)
    love.graphics.printf(subtitle, 80, 320, theme.logical_w - 160, "center", 0, 1.05, 1.05)

    love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], pulse)
    love.graphics.printf(
      "Press Enter / Space / A to start",
      0,
      420,
      theme.logical_w,
      "center",
      0,
      1.1,
      1.1
    )

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.55)
    love.graphics.printf("LÖVE 11.4 · v0", 40, 668, 600, "left", 0, 0.65, 0.65)
    love.graphics.printf("Moles / Worms-like", theme.logical_w - 640 - 40, 668, 600, "right", 0, 0.65, 0.65)
  end

  function self:keypressed(key)
    if key == "return" or key == "space" or key == "kpenter" then
      go_menu(self)
    end
  end

  function self:gamepadpressed(_, button)
    if button == "a" then
      go_menu(self)
    end
  end

  return self
end

return { new = new }
