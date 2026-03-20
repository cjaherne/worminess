--- Play scene shell: full match runtime will live here (mapgen, roster, turn FSM).
--- For now: placeholder + Esc → main menu.
local theme = require("ui.theme")

local function new()
  local self = { ctx = nil }

  function self:enter(ctx)
    self.ctx = ctx
  end

  function self:keypressed(key)
    if key == "escape" then
      local main_menu = require("scenes.main_menu").new()
      self.ctx.scenes:replace(main_menu)
    end
  end

  function self:gamepadpressed(_, button)
    if button == "b" then
      self:keypressed("escape")
    end
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(c.void[1], c.void[2], c.void[3], 1)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.printf("Play", 0, 200, theme.logical_w, "center", 0, 2, 2)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
    love.graphics.printf(
      "Match loop, mapgen, and combat ship in later tasks.\n\nEsc or gamepad B → Main menu",
      120,
      300,
      theme.logical_w - 240,
      "center",
      0,
      1.1,
      1.1
    )
  end

  return self
end

return { new = new }
