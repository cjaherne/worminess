--- round_end or match_end panel on top of play.
local theme = require("ui.theme")
local layout = require("ui.layout")

local function spawn_confetti()
  local parts = {}
  local lw, lh = theme.logical_w, theme.logical_h
  for _ = 1, 52 do
    parts[#parts + 1] = {
      x = love.math.random(20, lw - 20),
      y = love.math.random(-40, lh * 0.35),
      vx = love.math.random(-95, 95),
      vy = love.math.random(-120, -20),
      ay = 340 + love.math.random(0, 120),
      rot = love.math.random() * 6.28,
      vr = love.math.random(-5, 5),
      s = love.math.random(5, 10),
      hue = love.math.random(),
      life = love.math.random(90, 170) / 100,
      t = 0,
    }
  end
  return parts
end

local function new(opts)
  opts = opts or {}
  local self = {
    variant = opts.variant or "round_end",
    winner = opts.winner,
    ctx = opts.ctx,
    session = opts.session,
    on_continue = opts.on_continue,
    on_rematch = opts.on_rematch,
    on_new_setup = opts.on_new_setup,
    on_menu = opts.on_menu,
    focus = 1,
    confetti = nil,
  }

  function self:enter(ctx)
    self.ctx = ctx
    self.focus = 1
    if self.variant == "match_end" then
      self.confetti = spawn_confetti()
    else
      self.confetti = nil
    end
  end

  function self:update(dt)
    if not self.confetti then
      return
    end
    for _, p in ipairs(self.confetti) do
      p.t = p.t + dt
      p.vy = p.vy + p.ay * dt
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.rot = p.rot + p.vr * dt
    end
  end

  local function n_items()
    if self.variant == "round_end" then
      return 1
    end
    return 3
  end

  function self:keypressed(key)
    local n = n_items()
    if key == "up" then
      self.focus = self.focus - 1
      if self.focus < 1 then
        self.focus = n
      end
    elseif key == "down" then
      self.focus = self.focus + 1
      if self.focus > n then
        self.focus = 1
      end
    elseif key == "return" or key == "space" or key == "kpenter" then
      self:confirm()
    elseif key == "escape" and self.variant == "round_end" then
      if self.on_continue then
        self.on_continue()
      end
    end
  end

  function self:gamepadpressed(_, button)
    if button == "a" then
      self:confirm()
    elseif button == "b" and self.variant == "round_end" and self.on_continue then
      self.on_continue()
    end
  end

  function self:mousepressed(x, y, button)
    if button ~= 1 then
      return
    end
    local lx, ly = layout.screen_to_logical(x, y)
    local bx, by, bw, bh, gap = 400, 360, 480, 44, 10
    local n = n_items()
    for i = 1, n do
      local yy = by + (i - 1) * (bh + gap)
      if lx >= bx and lx <= bx + bw and ly >= yy and ly <= yy + bh then
        self.focus = i
        self:confirm()
        break
      end
    end
  end

  function self:confirm()
    if self.variant == "round_end" then
      if self.on_continue then
        self.on_continue()
      end
      return
    end
    if self.focus == 1 and self.on_rematch then
      self.on_rematch()
    elseif self.focus == 2 and self.on_new_setup then
      self.on_new_setup()
    elseif self.focus == 3 and self.on_menu then
      self.on_menu()
    end
  end

  function self:draw()
    local c = theme.colors
    if self.confetti then
      for _, p in ipairs(self.confetti) do
        local k = math.min(1, p.t / p.life)
        local r = 0.55 + 0.45 * math.sin(p.hue * 8 + p.t * 3)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rot)
        love.graphics.setColor(r, 0.72, 0.95, 0.8 * (1 - k))
        love.graphics.rectangle("fill", -p.s * 0.5, -p.s * 0.5, p.s, p.s, 2, 2)
        love.graphics.pop()
      end
    end

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.rectangle("fill", 320, 140, 640, 440, 14, 14)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)

    if self.variant == "round_end" then
      love.graphics.printf("Round finished", 340, 170, 600, "center", 0, 1.35, 1.35)
      love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], 1)
      if self.winner == 2 then
        love.graphics.setColor(c.team_b[1], c.team_b[2], c.team_b[3], 1)
      end
      love.graphics.printf(
        "Winner: Player " .. tostring(self.winner or "?"),
        340,
        230,
        600,
        "center",
        0,
        1.2,
        1.2
      )
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.85)
      love.graphics.printf("Continue → next round (new terrain)", 340, 290, 600, "center", 0, 0.95, 0.95)
      local sel = (self.focus == 1)
      if sel then
        love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.35)
        love.graphics.rectangle("fill", 400, 350, 480, 52, 8, 8)
      end
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
      love.graphics.printf("Continue", 400, 366, 480, "center", 0, 1.05, 1.05)
    else
      love.graphics.printf("Match finished", 340, 170, 600, "center", 0, 1.45, 1.45)
      love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], 1)
      if self.winner == 2 then
        love.graphics.setColor(c.team_b[1], c.team_b[2], c.team_b[3], 1)
      end
      love.graphics.printf(
        "Champion: Player " .. tostring(self.winner or "?"),
        340,
        220,
        600,
        "center",
        0,
        1.25,
        1.25
      )
      local s1, s2 = self.session:get_scores()
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.9)
      love.graphics.printf(
        "Session match wins · P1: " .. tostring(s1) .. "   P2: " .. tostring(s2),
        340,
        280,
        600,
        "center",
        0,
        0.9,
        0.9
      )
      local labels = { "Rematch", "New setup", "Main menu" }
      local bx, by, bw, bh, gap = 400, 330, 480, 44, 10
      for i = 1, #labels do
        local yy = by + (i - 1) * (bh + gap)
        local sel = (self.focus == i)
        if sel then
          love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.35)
          love.graphics.rectangle("fill", bx - 6, yy - 4, bw + 12, bh + 8, 6, 6)
        end
        love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
        love.graphics.printf(labels[i], bx, yy + 10, bw, "center", 0, 1, 1)
      end
    end
  end

  return self
end

return { new = new }
