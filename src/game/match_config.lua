local C = require("data.constants")

local M = {}

function M.defaults()
  return {
    mole_max_hp = 100,
    rounds_to_win = 2,
    wind_strength = 0,
    grenade_fuse_seconds = 3,
    turn_time_limit = nil,
    friendly_fire = true,
    procedural_seed = nil,
    map_width = C.WORLD_W,
    map_height = C.WORLD_H,
    teams_per_player = C.MOLES_PER_TEAM,
    input_scheme = "shared_kb", -- "shared_kb" | "dual_gamepad"
  }
end

function M.validate(c)
  c.mole_max_hp = math.max(1, math.min(500, math.floor(c.mole_max_hp + 0.5)))
  c.rounds_to_win = math.max(1, math.min(9, math.floor(c.rounds_to_win + 0.5)))
  c.wind_strength = math.max(-400, math.min(400, c.wind_strength))
  c.grenade_fuse_seconds = math.max(0.5, math.min(8, c.grenade_fuse_seconds))
  if c.turn_time_limit ~= nil then
    c.turn_time_limit = math.max(5, math.min(120, c.turn_time_limit))
  end
  return c
end

function M.copy(c)
  return {
    mole_max_hp = c.mole_max_hp,
    rounds_to_win = c.rounds_to_win,
    wind_strength = c.wind_strength,
    grenade_fuse_seconds = c.grenade_fuse_seconds,
    turn_time_limit = c.turn_time_limit,
    friendly_fire = c.friendly_fire,
    procedural_seed = c.procedural_seed,
    map_width = c.map_width,
    map_height = c.map_height,
    teams_per_player = c.teams_per_player,
    input_scheme = c.input_scheme,
  }
end

return M
