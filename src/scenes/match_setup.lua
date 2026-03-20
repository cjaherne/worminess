local match_settings = require("data.match_settings")

local M = {}

local draft
local focus = 1
local seed_buf = ""

local rows = {
  { key = "mole_max_hp", label = "Mole health", kind = "step", step = 10, min = 10, max = 500 },
  { key = "first_player", label = "First turn", kind = "first" },
  { key = "friendly_fire", label = "Friendly fire", kind = "bool" },
  { key = "turn_time_seconds", label = "Turn limit (0=off)", kind = "turns" },
  { key = "map_seed", label = "Map seed (blank=random)", kind = "seed" },
  { key = "input_mode", label = "Input", kind = "input" },
  { key = "wind", label = "Wind", kind = "wind" },
}

function M.enter(app)
  draft = match_settings.merge_partial(app.last_match_settings or match_settings.defaults(), {})
  focus = 1
  seed_buf = draft.map_seed and tostring(draft.map_seed) or ""
  app.setup_seed_buffer = seed_buf
end

local function sync_seed()
  if seed_buf == "" then
    draft.map_seed = nil
  else
    draft.map_seed = tonumber(seed_buf)
  end
end

function M.update(_, _) end

function M.draw(app)
  local ui = require("ui.hud")
  ui.draw_background()
  love.graphics.setColor(0, 0, 0, 0.3)
  love.graphics.rectangle("fill", 0, 0, 1280, 720)

  love.graphics.setFont(app.fonts.title)
  love.graphics.setColor(0.95, 0.96, 0.98, 1)
  love.graphics.print("Match setup", 48, 28)
  love.graphics.setFont(app.fonts.small)
  love.graphics.setColor(0.7, 0.74, 0.8, 1)
  love.graphics.print("Title ▸ Setup", 48, 78)

  love.graphics.setFont(app.fonts.hud)
  local y = 120
  for i, row in ipairs(rows) do
    local sel = focus == i
    love.graphics.setColor(0, 0, 0, sel and 0.45 or 0.28)
    love.graphics.rectangle("fill", 40, y, 1180, 52, 8, 8)
    love.graphics.setColor(0.92, 0.93, 0.96, 1)
    local val = ""
    if row.kind == "step" then
      val = tostring(draft[row.key])
    elseif row.kind == "first" then
      val = tostring(draft.first_player)
    elseif row.kind == "bool" then
      val = draft.friendly_fire and "on" or "off"
    elseif row.kind == "turns" then
      val = tostring(draft.turn_time_seconds)
    elseif row.kind == "seed" then
      val = seed_buf == "" and "(random)" or seed_buf
    elseif row.kind == "input" then
      val = draft.input_mode == "dual_gamepad" and "Two gamepads" or "Shared keyboard + mouse"
    elseif row.kind == "wind" then
      val = draft.wind
    end
    love.graphics.print((sel and "› " or "  ") .. row.label .. ":  " .. val, 64, y + 14)
    y = y + 60
  end

  local list = love.joystick.getJoysticks()
  love.graphics.setFont(app.fonts.small)
  love.graphics.setColor(1, 0.75, 0.45, 1)
  if draft.input_mode == "dual_gamepad" and #list < 2 then
    love.graphics.print("Warning: fewer than two gamepads detected — plug in two or switch input mode.", 48, y + 16)
  end

  love.graphics.setColor(0.85, 0.88, 0.92, 1)
  love.graphics.printf("Enter: start match     Esc: title     Left/Right: change     Up/Down: row     (seed row: type digits, Backspace deletes)", 48, 668, 1180, "center")
end

local function cycle_first()
  local o = { "1", "2", "random" }
  local cur = draft.first_player
  local idx = 1
  for i, v in ipairs(o) do
    if v == cur then idx = i break end
  end
  idx = (idx % #o) + 1
  draft.first_player = o[idx]
end

local function cycle_input()
  draft.input_mode = draft.input_mode == "dual_gamepad" and "shared_kb" or "dual_gamepad"
end

local function cycle_wind()
  local o = { "off", "low", "med", "high" }
  local idx = 1
  for i, v in ipairs(o) do
    if v == draft.wind then idx = i break end
  end
  idx = (idx % #o) + 1
  draft.wind = o[idx]
end

local function nudge_turn_time(delta)
  local presets = { 0, 30, 60, 90, 120, 180, 300 }
  local v = draft.turn_time_seconds
  local best, bi = presets[1], 1
  for i, p in ipairs(presets) do
    if math.abs(p - v) < math.abs(best - v) then best, bi = p, i end
  end
  bi = math.max(1, math.min(#presets, bi + delta))
  draft.turn_time_seconds = presets[bi]
end

function M.keypressed(app, key)
  local row = rows[focus]
  if key == "escape" then
    app.goto("menu")
    return
  end
  if key == "up" or key == "w" then
    focus = math.max(1, focus - 1)
  elseif key == "down" or key == "s" then
    focus = math.min(#rows, focus + 1)
  elseif key == "return" or key == "kpenter" then
    draft = match_settings.validate(draft)
    sync_seed()
    draft = match_settings.validate(draft)
    app.last_match_settings = draft
    app.goto("play", draft)
  elseif key == "backspace" and row and row.kind == "seed" then
    seed_buf = seed_buf:sub(1, -2)
  elseif key == "left" or key == "a" then
    if row.kind == "step" then
      draft[row.key] = math.max(row.min, draft[row.key] - row.step)
    elseif row.kind == "first" then
      cycle_first()
    elseif row.kind == "bool" then
      draft.friendly_fire = not draft.friendly_fire
    elseif row.kind == "turns" then
      nudge_turn_time(-1)
    elseif row.kind == "input" then
      cycle_input()
    elseif row.kind == "wind" then
      cycle_wind()
    end
  elseif key == "right" or key == "d" then
    if row.kind == "step" then
      draft[row.key] = math.min(row.max, draft[row.key] + row.step)
    elseif row.kind == "first" then
      cycle_first()
    elseif row.kind == "bool" then
      draft.friendly_fire = not draft.friendly_fire
    elseif row.kind == "turns" then
      nudge_turn_time(1)
    elseif row.kind == "input" then
      cycle_input()
    elseif row.kind == "wind" then
      cycle_wind()
    end
  end
end

function M.textinput(_, t)
  local row = rows[focus]
  if not row or row.kind ~= "seed" then return end
  if t:match("%d") then
    seed_buf = seed_buf .. t
    if #seed_buf > 12 then seed_buf = seed_buf:sub(-12) end
  end
end

return M
