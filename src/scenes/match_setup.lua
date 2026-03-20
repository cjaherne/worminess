--- Full MatchConfig editor, dual Ready, validate → play.
local theme = require("ui.theme")
local layout = require("ui.layout")
local sfx = require("audio.sfx")
local match_config = require("game.match_config")
local devices = require("input.devices")
local C = require("data.constants")

local F_MOLE = 1
local F_ROUNDS = 2
local F_WIND = 3
local F_FUSE = 4
local F_TIMER_ON = 5
local F_TIMER_VAL = 6
local F_FF = 7
local F_SEED_MODE = 8
local F_SEED_VAL = 9
local F_SCHEME = 10
local F_BACK = 11
local F_START = 12

local function new()
  local self = {
    ctx = nil,
    cfg = match_config.copy(match_config.defaults()),
    focus = F_MOLE,
    ready_p1 = false,
    ready_p2 = false,
    use_custom_seed = false,
    timer_on = false,
    err_text = nil,
  }

  function self:enter(ctx)
    self.ctx = ctx
    devices.set_scheme(self.cfg.input_scheme)
    devices.refresh_joysticks()
    self.err_text = nil
    self.timer_on = self.cfg.turn_time_limit ~= nil
  end

  function self:sync_seed_field()
    if not self.use_custom_seed then
      self.cfg.procedural_seed = nil
    elseif self.cfg.procedural_seed == nil then
      self.cfg.procedural_seed = love.math.random(1, 999999)
    end
  end

  function self:validate_and_start()
    self.err_text = nil
    local c = match_config.copy(self.cfg)
    match_config.validate(c)
    if self.cfg.input_scheme == "dual_gamepad" and not devices.has_dual_ready() then
      self.err_text = "Assign two controllers (P2: press A on second pad)."
      return
    end
    if not (self.ready_p1 and self.ready_p2) then
      self.err_text = "Both players must Ready."
      return
    end
    self.ctx.session.last_match_config = match_config.copy(c)
    sfx.play("ui", 0.55)
    local play = require("scenes.play").new(c)
    self.ctx.scenes:replace(play)
  end

  function self:keypressed(key, scancode, isrepeat)
    if isrepeat then
      return
    end
    if key == "1" then
      self.ready_p1 = not self.ready_p1
      return
    elseif key == "2" then
      self.ready_p2 = not self.ready_p2
      return
    end

    if key == "tab" then
      self.focus = self.focus + 1
      if self.focus > F_START then
        self.focus = F_MOLE
      end
      return
    end

    if key == "up" then
      self.focus = self.focus - 1
      if self.focus < F_MOLE then
        self.focus = F_START
      end
      return
    elseif key == "down" then
      self.focus = self.focus + 1
      if self.focus > F_START then
        self.focus = F_MOLE
      end
      return
    end

    local function adj(dx)
      local f = self.focus
      if f == F_MOLE then
        self.cfg.mole_max_hp = math.max(1, math.min(500, self.cfg.mole_max_hp + dx * 5))
      elseif f == F_ROUNDS then
        self.cfg.rounds_to_win = math.max(1, math.min(9, self.cfg.rounds_to_win + dx))
      elseif f == F_WIND then
        self.cfg.wind_strength = math.max(-400, math.min(400, self.cfg.wind_strength + dx * 20))
      elseif f == F_FUSE then
        self.cfg.grenade_fuse_seconds = math.max(0.5, math.min(8, self.cfg.grenade_fuse_seconds + dx * 0.5))
      elseif f == F_TIMER_ON then
        if dx ~= 0 then
          self.timer_on = not self.timer_on
          self.cfg.turn_time_limit = self.timer_on and (self.cfg.turn_time_limit or 45) or nil
        end
      elseif f == F_TIMER_VAL and self.timer_on then
        self.cfg.turn_time_limit = math.max(5, math.min(120, (self.cfg.turn_time_limit or 45) + dx * 5))
      elseif f == F_FF then
        if dx ~= 0 then
          self.cfg.friendly_fire = not self.cfg.friendly_fire
        end
      elseif f == F_SEED_MODE then
        if dx ~= 0 then
          self.use_custom_seed = not self.use_custom_seed
          self:sync_seed_field()
        end
      elseif f == F_SEED_VAL and self.use_custom_seed then
        local s = self.cfg.procedural_seed or 1
        self.cfg.procedural_seed = math.max(1, s + dx * 9973)
      elseif f == F_SCHEME then
        if dx < 0 then
          self.cfg.input_scheme = "shared_kb"
        elseif dx > 0 then
          self.cfg.input_scheme = "dual_gamepad"
        end
        devices.set_scheme(self.cfg.input_scheme)
      end
    end

    if key == "left" or key == "a" then
      adj(-1)
      return
    elseif key == "right" or key == "d" then
      adj(1)
      return
    end

    if key == "return" or key == "space" or key == "kpenter" then
      if self.focus == F_BACK then
        local mm = require("scenes.main_menu").new()
        self.ctx.scenes:replace(mm)
      elseif self.focus == F_START then
        self:validate_and_start()
      end
      return
    end

    if key == "escape" then
      local mm = require("scenes.main_menu").new()
      self.ctx.scenes:replace(mm)
    end
  end

  function self:gamepadpressed(joystick, button)
    devices.refresh_joysticks()
    if self.cfg.input_scheme == "dual_gamepad" then
      if button == "a" then
        devices.try_assign_p2(joystick)
      end
    end
    if button == "a" then
      if self.focus == F_BACK then
        self:keypressed("escape")
      elseif self.focus == F_START then
        self:validate_and_start()
      end
    elseif button == "b" then
      self:keypressed("escape")
    elseif button == "dpup" then
      self:keypressed("up")
    elseif button == "dpdown" then
      self:keypressed("down")
    elseif button == "dpleft" then
      self:keypressed("left")
    elseif button == "dpright" then
      self:keypressed("right")
    elseif button == "x" then
      self.ready_p1 = not self.ready_p1
    elseif button == "y" then
      self.ready_p2 = not self.ready_p2
    end
  end

  function self:mousepressed(x, y, button)
    if button ~= 1 then
      return
    end
    local lx, ly = layout.screen_to_logical(x, y)
    local function hit(px, py, pw, ph)
      return lx >= px and lx <= px + pw and ly >= py and ly <= py + ph
    end

    if hit(160, 520, 180, 40) then
      self.ready_p1 = not self.ready_p1
      return
    end
    if hit(360, 520, 180, 40) then
      self.ready_p2 = not self.ready_p2
      return
    end
    if hit(160, 640, 140, 44) then
      self.focus = F_BACK
      local mm = require("scenes.main_menu").new()
      self.ctx.scenes:replace(mm)
      return
    end
    if hit(980, 640, 200, 44) then
      self.focus = F_START
      self:validate_and_start()
      return
    end

    local colx, y0, rowh = 140, 118, 36
    local rows = {
      F_MOLE,
      F_ROUNDS,
      F_WIND,
      F_FUSE,
      F_TIMER_ON,
      F_TIMER_VAL,
      F_FF,
      F_SEED_MODE,
      F_SEED_VAL,
      F_SCHEME,
    }
    for i, fid in ipairs(rows) do
      local yy = y0 + (i - 1) * rowh
      if hit(colx, yy - 4, 900, rowh - 4) then
        self.focus = fid
        return
      end
    end
  end

  function self:update(dt)
    devices.refresh_joysticks()
  end

  function self:resize(_w, _h)
    devices.refresh_joysticks()
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(c.void[1], c.void[2], c.void[3], 1)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    love.graphics.setColor(c.paper[1], c.paper[2], c.paper[3], 1)
    love.graphics.rectangle("fill", 120, 100, 1040, 520, 10, 10)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
    love.graphics.printf("Match setup", 0, 112, theme.logical_w, "center", 0, 1.35, 1.35)

    local function row(fid, label, value_str, y)
      local sel = (self.focus == fid)
      if sel then
        love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.22)
        love.graphics.rectangle("fill", 132, y - 6, 1016, 30, 6, 6)
      end
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.92)
      love.graphics.printf(label, 150, y, 420, "left", 0, 0.92, 0.92)
      love.graphics.printf(value_str, 520, y, 600, "left", 0, 0.95, 0.95)
    end

    local y = 140
    row(F_MOLE, "Mole health", tostring(self.cfg.mole_max_hp), y)
    y = y + 36
    row(F_ROUNDS, "Rounds to win match", tostring(self.cfg.rounds_to_win), y)
    y = y + 36
    local wtxt = self.cfg.wind_strength == 0 and "0 (off)" or tostring(self.cfg.wind_strength)
    row(F_WIND, "Wind (← / →)", wtxt, y)
    y = y + 36
    row(F_FUSE, "Grenade fuse (s)", string.format("%.1f", self.cfg.grenade_fuse_seconds), y)
    y = y + 36
    row(F_TIMER_ON, "Turn timer", self.timer_on and "On" or "Off", y)
    y = y + 36
    row(
      F_TIMER_VAL,
      "Turn seconds",
      self.timer_on and tostring(self.cfg.turn_time_limit or 45) or "—",
      y
    )
    y = y + 36
    row(F_FF, "Friendly fire", self.cfg.friendly_fire and "On" or "Off", y)
    y = y + 36
    row(F_SEED_MODE, "Custom seed", self.use_custom_seed and "Yes" or "Random", y)
    y = y + 36
    row(
      F_SEED_VAL,
      "Seed value",
      self.use_custom_seed and tostring(self.cfg.procedural_seed or 0) or "—",
      y
    )
    y = y + 36
    row(
      F_SCHEME,
      "Input",
      self.cfg.input_scheme == "shared_kb" and "Shared keyboard + mouse" or "Dual gamepad",
      y
    )

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.75)
    love.graphics.printf("Moles per player: " .. tostring(C.MOLES_PER_TEAM) .. " (rotation each round)", 140, 500, 1000, "left", 0, 0.78, 0.78)

    local rp1 = self.ready_p1
    local rp2 = self.ready_p2
    love.graphics.setColor(c.team_a[1], c.team_a[2], c.team_a[3], rp1 and 0.55 or 0.2)
    love.graphics.rectangle("fill", 160, 520, 180, 40, 8, 8)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 1)
    love.graphics.printf("P1 Ready" .. (rp1 and " ✓" or ""), 160, 532, 180, "center", 0, 0.85, 0.85)

    love.graphics.setColor(c.team_b[1], c.team_b[2], c.team_b[3], rp2 and 0.55 or 0.2)
    love.graphics.rectangle("fill", 360, 520, 180, 40, 8, 8)
    love.graphics.printf("P2 Ready" .. (rp2 and " ✓" or ""), 360, 532, 180, "center", 0, 0.85, 0.85)

    if self.cfg.input_scheme == "dual_gamepad" then
      devices.refresh_joysticks()
      local j1 = devices.joy_p1 ~= nil
      local j2 = devices.joy_p2 ~= nil
      love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.85)
      love.graphics.printf(
        j1 and "Controller 1 ✓" or "Controller 1: connect",
        560,
        520,
        300,
        "left",
        0,
        0.78,
        0.78
      )
      love.graphics.printf(
        j2 and "Controller 2 ✓" or "Controller 2: press A to assign",
        560,
        544,
        420,
        "left",
        0,
        0.78,
        0.78
      )
    end

    local can_start = self.ready_p1 and self.ready_p2
    if self.cfg.input_scheme == "dual_gamepad" then
      can_start = can_start and devices.has_dual_ready()
    end
    love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], can_start and 0.45 or 0.12)
    love.graphics.rectangle("fill", 980, 640, 200, 44, 8, 8)
    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], can_start and 1 or 0.45)
    love.graphics.printf("Start match", 980, 654, 200, "center", 0, 0.95, 0.95)

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.8)
    love.graphics.printf("Back", 160, 654, 140, "center", 0, 0.9, 0.9)

    if self.err_text then
      love.graphics.setColor(c.danger[1], c.danger[2], c.danger[3], 1)
      love.graphics.printf(self.err_text, 140, 580, 1000, "center", 0, 0.88, 0.88)
    end

    love.graphics.setColor(c.ink[1], c.ink[2], c.ink[3], 0.5)
    love.graphics.printf(
      "Tab/↑↓ focus · ←/→ adjust · 1 / 2 = P1/P2 Ready · Pad X/Y ready · Esc back",
      0,
      692,
      theme.logical_w,
      "center",
      0,
      0.68,
      0.68
    )
  end

  return self
end

return { new = new }
