local M = {}

local defaults = {
  moles_per_team = 5,
  mole_max_hp = 100,
  first_player = "random", -- "1", "2", "random"
  friendly_fire = false,
  turn_time_seconds = 0, -- 0 = off
  map_seed = nil, -- nil = random each match
  input_mode = "shared_kb", -- "shared_kb" | "dual_gamepad"
  wind = "off", -- "off" | "low" | "med" | "high"
}

function M.defaults()
  local t = {}
  for k, v in pairs(defaults) do
    if type(v) == "table" then
      t[k] = {}
      for kk, vv in pairs(v) do t[k][kk] = vv end
    else
      t[k] = v
    end
  end
  return t
end

function M.validate(s)
  s = s or {}
  s.moles_per_team = 5
  s.mole_max_hp = math.max(10, math.min(500, tonumber(s.mole_max_hp) or defaults.mole_max_hp))
  if s.first_player ~= "1" and s.first_player ~= "2" and s.first_player ~= "random" then
    s.first_player = "random"
  end
  s.friendly_fire = not not s.friendly_fire
  s.turn_time_seconds = math.max(0, math.min(300, tonumber(s.turn_time_seconds) or 0))
  s.input_mode = (s.input_mode == "dual_gamepad") and "dual_gamepad" or "shared_kb"
  local w = tostring(s.wind or "off"):lower()
  if w == "low" or w == "med" or w == "high" then
    s.wind = w
  else
    s.wind = "off"
  end
  if s.map_seed ~= nil then
    s.map_seed = math.floor(tonumber(s.map_seed) or 0)
  end
  return s
end

function M.merge_partial(base, partial)
  local t = M.defaults()
  if base then
    for k, v in pairs(base) do t[k] = v end
  end
  if partial then
    for k, v in pairs(partial) do t[k] = v end
  end
  return M.validate(t)
end

return M
