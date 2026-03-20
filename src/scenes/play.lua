--- Match runtime: mapgen each round, roster, turn FSM, combat, HUD, overlays via stack.
local theme = require("ui.theme")
local match_config_mod = require("game.match_config")
local roster = require("game.roster")
local turn_state = require("game.turn_state")
local map_seed = require("game.map_seed")
local mapgen = require("world.mapgen.init")
local world_update = require("systems.world_update")
local weapons = require("systems.weapons")
local turn_resolver = require("systems.turn_resolver")
local devices = require("input.devices")
local bindings = require("input.bindings")
local play_hud = require("ui.hud.play_hud")
local layout = require("ui.layout")
local C = require("data.constants")
local mole_ent = require("entities.mole")
local sfx = require("audio.sfx")
local vfx_mod = require("systems.vfx")
local stick = require("input.stick")

local function new(match_cfg)
  local cfg = match_config_mod.validate(match_config_mod.copy(match_cfg))

  local self = {
    ctx = nil,
    cfg = cfg,
    teams = nil,
    turn = nil,
    terrain = nil,
    map = nil,
    projectiles = {},
    grenades = {},
    round_index = 1,
    round_wins = { 0, 0 },
    team_turn_slot = { 1, 1 },
    cam_x = 0,
    cam_y = 0,
    toast_text = "",
    vfx = vfx_mod.new(),
    feedback = nil,
    _aim_sx = 0,
    _aim_sy = -1,
    _endgame_armed = false,
  }

  function self:play_ctx()
    return {
      turn = self.turn,
      teams = self.teams,
      team_turn_slot = self.team_turn_slot,
      terrain = self.terrain,
      match_config = self.cfg,
      projectiles = self.projectiles,
      grenades = self.grenades,
      world_w = self.terrain and self.terrain.world_w or C.WORLD_W,
      world_h = self.terrain and self.terrain.world_h or C.WORLD_H,
      feedback = self.feedback,
    }
  end

  function self:enter(ctx)
    self.ctx = ctx
    devices.set_scheme(self.cfg.input_scheme)
    devices.refresh_joysticks()
    self.ctx.session.last_match_config = match_config_mod.copy(self.cfg)
    self.feedback = {
      on_moles_damaged = function(is_fall)
        sfx.play("hurt", is_fall and 0.22 or 0.38)
      end,
      on_explosion = function(wx, wy, def)
        self.vfx:add_explosion(wx, wy, def.blast_radius, { heavy = false })
        sfx.play_explosion(0.72)
      end,
      on_weapon_fire = function(wid, wx, wy, ang)
        if wid == "grenade" then
          sfx.play("grenade_pop", 0.68)
        else
          sfx.play("fire", 0.62)
        end
        self.vfx:add_muzzle(wx, wy, ang)
      end,
      on_rocket_trail = function(x, y)
        self.vfx:add_rocket_trail(x, y)
      end,
      on_grenade_trail = function(x, y)
        self.vfx:add_grenade_smoke(x, y)
      end,
    }
    self:start_match()
  end

  function self:start_match()
    self._endgame_armed = false
    self.round_index = 1
    self.round_wins = { 0, 0 }
    self.team_turn_slot = { 1, 1 }
    self.teams = {
      roster.new_team(1, theme.colors.team_a, self.cfg.mole_max_hp),
      roster.new_team(2, theme.colors.team_b, self.cfg.mole_max_hp),
    }
    self.turn = turn_state.new()
    self.projectiles = {}
    self.grenades = {}
    self:begin_round()
  end

  function self:begin_round()
    self._endgame_armed = false
    self.projectiles = {}
    self.grenades = {}
    self._aim_sx, self._aim_sy = 0, -1
    local seed = map_seed.derive(self.cfg.procedural_seed, self.round_index)
    local world = mapgen.generate(self.cfg, seed)
    self.terrain = world.terrain
    self.map = world.map
    roster.place_team_from_spawns(self.teams[1], self.map.spawn_team1, self.cfg.mole_max_hp)
    roster.place_team_from_spawns(self.teams[2], self.map.spawn_team2, self.cfg.mole_max_hp)
    self.teams[1].mole_order = roster.rotate_order(self.teams[1].mole_order)
    self.teams[2].mole_order = roster.rotate_order(self.teams[2].mole_order)
    self.team_turn_slot = { 1, 1 }
    local starting_player = ((self.round_index - 1) % 2) + 1
    turn_state.start_match_turn(self.turn, self.teams, starting_player, 1, 1)
    if self.cfg.turn_time_limit then
      self.turn.turn_time_left = self.cfg.turn_time_limit
    else
      self.turn.turn_time_left = nil
    end
    local m = turn_state.active_mole(self.turn, self.teams)
    self.toast_text = string.format(
      "Round %d — %s · Mole %d",
      self.round_index,
      starting_player == 1 and "Player 1" or "Player 2",
      m and m.index or 0
    )
    turn_state.begin_interstitial(self.turn, 1.45)
  end

  function self:continue_after_round()
    self.round_index = self.round_index + 1
    self:begin_round()
  end

  function self:restart_match()
    self:start_match()
  end

  function self:rematch_from_session()
    local c = self.ctx.session.last_match_config
    if c then
      self.cfg = match_config_mod.validate(match_config_mod.copy(c))
      devices.set_scheme(self.cfg.input_scheme)
    end
    self:start_match()
  end

  function self:update_camera(dt)
    local m = turn_state.active_mole(self.turn, self.teams)
    local tw, th = self.terrain.world_w, self.terrain.world_h
    local lw, lh = theme.logical_w, theme.logical_h
    local tx = (m and m.alive) and m.x or tw * 0.5
    local ty = (m and m.alive) and m.y or th * 0.5
    local target_x = tx - lw * 0.5
    local target_y = ty - lh * 0.5
    target_x = math.max(0, math.min(math.max(0, tw - lw), target_x))
    target_y = math.max(0, math.min(math.max(0, th - lh), target_y))
    local k = math.min(1, dt * 6)
    self.cam_x = self.cam_x + (target_x - self.cam_x) * k
    self.cam_y = self.cam_y + (target_y - self.cam_y) * k
  end

  function self:on_round_victory(winner)
    if self._endgame_armed then
      return
    end
    self._endgame_armed = true
    local ts = self.turn
    ts.phase = turn_state.phases.round_end
    self.round_wins[winner] = self.round_wins[winner] + 1
    local sm = self.ctx.scenes
    if self.round_wins[winner] >= self.cfg.rounds_to_win then
      self.ctx.session:bump_match_win(winner)
      sfx.play_explosion(0.95)
      local go = require("scenes.game_over").new({
        variant = "match_end",
        winner = winner,
        session = self.ctx.session,
        on_rematch = function()
          self._endgame_armed = false
          sm:pop()
          self:rematch_from_session()
        end,
        on_new_setup = function()
          self._endgame_armed = false
          sm:pop()
          sm:replace(require("scenes.match_setup").new())
        end,
        on_menu = function()
          self._endgame_armed = false
          sm:pop()
          sm:replace(require("scenes.main_menu").new())
        end,
      })
      sm:push(go)
    else
      local go = require("scenes.game_over").new({
        variant = "round_end",
        winner = winner,
        session = self.ctx.session,
        on_continue = function()
          self._endgame_armed = false
          sm:pop()
          self:continue_after_round()
        end,
      })
      sm:push(go)
    end
  end

  function self:update_mouse_aim()
    if self.cfg.input_scheme ~= "shared_kb" then
      return
    end
    if self.turn.phase ~= turn_state.phases.aim then
      return
    end
    if self.turn.active_player ~= 1 and self.turn.active_player ~= 2 then
      return
    end
    local m = turn_state.active_mole(self.turn, self.teams)
    if not m or not m.alive then
      return
    end
    local mx, my = love.mouse.getPosition()
    local lx, ly = layout.screen_to_logical(mx, my)
    local wx = lx + self.cam_x
    local wy = ly + self.cam_y
    self.turn.aim_angle = math.atan2(wy - m.y, wx - m.x)
  end

  local function binding_for_active()
    local ap = self.turn.active_player
    if self.cfg.input_scheme == "shared_kb" then
      return ap == 1 and bindings.p1_keys or bindings.p2_keys
    end
    return bindings.p1_keys
  end

  --- Hybrid: P1 uses first gamepad if present; P2 uses second pad or the only pad on their turn.
  local function shared_kb_joy_for_turn(ts)
    local pads = {}
    for _, j in ipairs(love.joystick.getJoysticks()) do
      if j:isGamepad() then
        pads[#pads + 1] = j
      end
    end
    if ts.active_player == 1 and #pads >= 1 then
      return pads[1]
    end
    if ts.active_player == 2 and #pads >= 2 then
      return pads[2]
    end
    if ts.active_player == 2 and #pads == 1 then
      return pads[1]
    end
    return nil
  end

  local function try_move(self, dir, dt)
    local ts = self.turn
    if ts.phase ~= turn_state.phases.aim then
      return
    end
    local m = turn_state.active_mole(ts, self.teams)
    if not m or not m.alive or ts.move_budget <= 0 then
      return
    end
    local sp = C.MOVE_SPEED * dir
    local try_x = m.x + sp * dt
    if
      not self.terrain:isSolidCircle(try_x, m.y, m.radius * 0.92)
      and not self.terrain:isSolidCircle(try_x, m.y + m.radius * 0.5, m.radius * 0.5)
    then
      m.x = try_x
      m.facing = dir > 0 and 1 or -1
      ts.move_budget = math.max(0, ts.move_budget - dt)
    end
  end

  function self:update_aim_controls(dt)
    local ts = self.turn
    if ts.phase ~= turn_state.phases.aim then
      return
    end
    local scheme = self.cfg.input_scheme
    if scheme == "shared_kb" then
      local b = binding_for_active()
      if love.keyboard.isDown(b.move_left) then
        try_move(self, -1, dt)
      end
      if love.keyboard.isDown(b.move_right) then
        try_move(self, 1, dt)
      end
      if love.keyboard.isDown(b.aim_up) then
        ts.aim_angle = ts.aim_angle - 1.6 * dt
      end
      if love.keyboard.isDown(b.aim_down) then
        ts.aim_angle = ts.aim_angle + 1.6 * dt
      end
      local j = shared_kb_joy_for_turn(ts)
      local shoulder, trig = false, 0
      if j and j:isGamepad() then
        local lx, ly = stick.read_left_stick(j, 0.28)
        if math.abs(lx) > 0.02 then
          try_move(self, lx > 0 and 1 or -1, dt * math.min(1, math.abs(lx) * 1.25))
        end
        if math.abs(lx) > 0.04 or math.abs(ly) > 0.04 then
          self._aim_sx, self._aim_sy = stick.smooth2(self._aim_sx, self._aim_sy, lx, ly, dt, 18)
          ts.aim_angle = math.atan2(self._aim_sy, self._aim_sx)
        end
        shoulder = j:isGamepadDown("leftshoulder") or j:isGamepadDown("rightshoulder")
        trig = stick.read_triggers(j)
      end
      if love.keyboard.isDown(b.power) or shoulder or trig > 0.2 then
        ts.charging = true
      end
      if j and j:isGamepad() then
        local kb_on = love.keyboard.isDown(b.power)
        if not kb_on and not shoulder and trig < 0.1 then
          ts.charging = false
        end
      end
      local boost = 1
      if shoulder or trig > 0.2 then
        boost = 1 + trig * 0.45
      end
      if ts.charging then
        ts.power = math.min(1, ts.power + C.POWER_CHARGE_RATE * dt * boost)
      end
    elseif scheme == "dual_gamepad" then
      local j = devices.joy_p1
      if ts.active_player == 2 then
        j = devices.joy_p2
      end
      devices.refresh_joysticks()
      if j and j:isGamepad() then
        local lx, ly = stick.read_left_stick(j, 0.28)
        self._aim_sx, self._aim_sy = stick.smooth2(self._aim_sx, self._aim_sy, lx, ly, dt, 18)
        if math.abs(lx) > 0.02 then
          try_move(self, lx > 0 and 1 or -1, dt * math.min(1, math.abs(lx) * 1.25))
        end
        if math.abs(self._aim_sx) > 0.04 or math.abs(self._aim_sy) > 0.04 then
          ts.aim_angle = math.atan2(self._aim_sy, self._aim_sx)
        end
        local shoulder = j:isGamepadDown("leftshoulder") or j:isGamepadDown("rightshoulder")
        local trig = stick.read_triggers(j)
        if shoulder or trig > 0.2 then
          ts.charging = true
        end
        if ts.charging then
          ts.power = math.min(1, ts.power + C.POWER_CHARGE_RATE * dt * (1 + trig * 0.45))
        end
        if not shoulder and trig < 0.1 then
          ts.charging = false
        end
      end
    end
  end

  function self:update_turn_timer(dt)
    local ts = self.turn
    if ts.phase ~= turn_state.phases.aim then
      return
    end
    if not ts.turn_time_left then
      return
    end
    ts.turn_time_left = ts.turn_time_left - dt
    if ts.turn_time_left <= 0 then
      ts.turn_time_left = 0
      ts.power = math.max(0.35, ts.power)
      weapons.try_fire(self:play_ctx())
    end
  end

  function self:update(dt)
    devices.refresh_joysticks()
    self.vfx:update(dt)
    self:update_mouse_aim()

    local ts = self.turn
    if ts.phase == turn_state.phases.interstitial then
      if turn_state.tick_interstitial(ts, dt) then
        if self.cfg.turn_time_limit then
          ts.turn_time_left = self.cfg.turn_time_limit
        end
      end
      self:update_camera(dt)
      return
    end

    if ts.phase == turn_state.phases.round_end then
      self:update_camera(dt)
      return
    end

    self:update_aim_controls(dt)
    self:update_turn_timer(dt)

    world_update.update_moles(self:play_ctx(), dt)

    if ts.phase == turn_state.phases.aim then
      local st = turn_state.repair_active_slot(ts, self.teams)
      if st == "reassigned" then
        sfx.play("ui", 0.35)
      elseif st == "team_wiped" then
        local loser = ts.active_player
        local w = loser == 1 and 2 or 1
        self:on_round_victory(w)
      end
    end

    local pctx = self:play_ctx()
    world_update.update_projectiles(pctx, dt)
    world_update.update_grenades(pctx, dt)

    if ts.phase == turn_state.phases.flying then
      local c1 = roster.team_living_count(self.teams[1])
      local c2 = roster.team_living_count(self.teams[2])
      if c1 == 0 or c2 == 0 then
        self.projectiles = {}
        self.grenades = {}
        local w = (c1 == 0) and 2 or 1
        self:on_round_victory(w)
      else
        local ev, w = turn_resolver.resolve_flying_end(pctx)
        if ev == "round_end" and w then
          self:on_round_victory(w)
        end
      end
    end

    self:update_camera(dt)
  end

  function self:keypressed(key, scancode, isrepeat)
    if isrepeat then
      return
    end
    local ts = self.turn
    if key == "escape" then
      self.ctx.scenes:push(require("scenes.pause").new(self))
      return
    end
    if self.cfg.input_scheme == "dual_gamepad" then
      return
    end
    if ts.phase ~= turn_state.phases.aim then
      return
    end
    local b = binding_for_active()
    if key == b.weapon_prev then
      ts.weapon_index = 1
    elseif key == b.weapon_next then
      ts.weapon_index = 2
    elseif key == b.fire then
      weapons.try_fire(self:play_ctx())
    end
  end

  function self:keyreleased(key, scancode)
    if self.cfg.input_scheme == "dual_gamepad" then
      return
    end
    local ts = self.turn
    local b = binding_for_active()
    if key == b.power then
      if self.cfg.input_scheme == "shared_kb" then
        local j = shared_kb_joy_for_turn(ts)
        local pad_charging = false
        if j and j:isGamepad() then
          local shoulder = j:isGamepadDown("leftshoulder") or j:isGamepadDown("rightshoulder")
          local trig = stick.read_triggers(j)
          pad_charging = shoulder or trig > 0.2
        end
        if not pad_charging then
          ts.charging = false
        end
      else
        ts.charging = false
      end
    end
  end

  function self:gamepadpressed(joystick, button)
    if button == "start" then
      self.ctx.scenes:push(require("scenes.pause").new(self))
      return
    end
    if self.turn.phase ~= turn_state.phases.aim then
      return
    end
    if self.cfg.input_scheme == "shared_kb" then
      local j = shared_kb_joy_for_turn(self.turn)
      if j ~= joystick then
        return
      end
    end
    local slot = devices.slot_for_joystick(joystick)
    if self.cfg.input_scheme == "dual_gamepad" then
      if slot == nil or slot ~= self.turn.active_player then
        return
      end
    end
    if button == "a" then
      weapons.try_fire(self:play_ctx())
    elseif button == "x" then
      self.turn.weapon_index = 1
    elseif button == "y" then
      self.turn.weapon_index = 2
    end
  end

  function self:gamepadreleased(joystick, button)
    if self.cfg.input_scheme == "shared_kb" then
      local j = shared_kb_joy_for_turn(self.turn)
      if j ~= joystick then
        return
      end
    end
    local slot = devices.slot_for_joystick(joystick)
    if self.cfg.input_scheme == "dual_gamepad" and slot ~= self.turn.active_player then
      return
    end
    if button == "leftshoulder" or button == "rightshoulder" then
      local ts = self.turn
      if self.cfg.input_scheme == "shared_kb" then
        local b = binding_for_active()
        local kb_on = love.keyboard.isDown(b.power)
        local trig = stick.read_triggers(joystick)
        local sh = joystick:isGamepadDown("leftshoulder") or joystick:isGamepadDown("rightshoulder")
        if not kb_on and trig < 0.1 and not sh then
          ts.charging = false
        end
      elseif self.cfg.input_scheme == "dual_gamepad" then
        ts.charging = false
      end
    end
  end

  function self:mousepressed(x, y, button, istouch, presses)
    if button ~= 1 then
      return
    end
    if self.turn.phase ~= turn_state.phases.aim then
      return
    end
    if self.cfg.input_scheme ~= "shared_kb" then
      return
    end
    if self.turn.active_player ~= 1 and self.turn.active_player ~= 2 then
      return
    end
    weapons.try_fire(self:play_ctx())
  end

  function self:wheelmoved(_x, y)
    if self.cfg.input_scheme ~= "shared_kb" then
      return
    end
    if self.turn.phase ~= turn_state.phases.aim then
      return
    end
    local ts = self.turn
    local step = 0.12
    ts.power = math.max(0, math.min(1, ts.power - y * step))
  end

  function self:draw()
    local c = theme.colors
    love.graphics.setColor(c.void[1], c.void[2], c.void[3], 1)
    love.graphics.rectangle("fill", 0, 0, theme.logical_w, theme.logical_h)

    local shx, shy = self.vfx:shake_offset()
    love.graphics.push()
    love.graphics.translate(-math.floor(self.cam_x + shx), -math.floor(self.cam_y + shy))
    self.terrain:draw()
    for t = 1, #self.teams do
      local team = self.teams[t]
      for i = 1, #team.moles do
        local m = team.moles[i]
        mole_ent.draw(m, team.color)
      end
    end
    self.vfx:draw_world()
    for i = 1, #self.projectiles do
      local p = self.projectiles[i]
      local sp = 5 + (p.trail_t or 0) * 2 % 3
      love.graphics.setColor(1, 0.92, 0.55, 0.45)
      love.graphics.circle("fill", p.pos.x, p.pos.y, sp + 4)
      love.graphics.setColor(1, 0.45, 0.08, 1)
      love.graphics.circle("fill", p.pos.x, p.pos.y, 5)
      love.graphics.setColor(1, 1, 1, 0.35)
      love.graphics.circle("line", p.pos.x, p.pos.y, 7)
    end
    for i = 1, #self.grenades do
      local g = self.grenades[i]
      love.graphics.setColor(0.25, 0.75, 0.35, 0.5)
      love.graphics.circle("fill", g.pos.x, g.pos.y, 11)
      love.graphics.setColor(0.45, 0.95, 0.42, 1)
      love.graphics.circle("fill", g.pos.x, g.pos.y, 7)
      if g.fuse and g.fuse > 0 then
        love.graphics.setColor(1, 0.35, 0.35, 0.65)
        love.graphics.circle("line", g.pos.x, g.pos.y, 9 + (1 - g.fuse % 1) * 3)
      end
    end

    if self.turn.phase == turn_state.phases.aim then
      local m = turn_state.active_mole(self.turn, self.teams)
      if m and m.alive then
        local ax = m.x + math.cos(self.turn.aim_angle) * (m.radius + 30)
        local ay = m.y + math.sin(self.turn.aim_angle) * (m.radius + 30)
        love.graphics.setColor(c.accent[1], c.accent[2], c.accent[3], 0.65)
        love.graphics.setLineWidth(2)
        love.graphics.line(m.x, m.y, ax, ay)
        love.graphics.setLineWidth(1)
      end
    end
    love.graphics.pop()

    local hud_ctx = self:play_ctx()
    hud_ctx.session = self.ctx.session
    hud_ctx.round_index = self.round_index
    hud_ctx.round_wins = self.round_wins
    hud_ctx.toast_text = self.toast_text
    play_hud.draw(hud_ctx)
  end

  return self
end

return { new = new }
