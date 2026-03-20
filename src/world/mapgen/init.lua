local Rng = require("core.rng")
local terrain_mod = require("world.terrain")
local map_mod = require("world.map")
local heightfield = require("world.mapgen.heightfield")
local caves = require("world.mapgen.caves")
local spawns = require("world.mapgen.spawns")

local M = {}

function M.generate(match_config, seed)
  local tw = match_config.map_width
  local th = match_config.map_height
  local rng = Rng.new(seed)
  local terrain = terrain_mod.new(tw, th)
  terrain:clear_all_air()
  local base = th * 0.42
  local amp = th * 0.08
  heightfield.apply_surface(terrain, rng, base, amp)
  caves.carve_spheres(terrain, rng, 14, 18, 56)
  local map = map_mod.new()
  map.seed = seed
  spawns.place_team_spawns(terrain, map, rng)
  terrain:rebuildImageData()
  return { map = map, terrain = terrain, rng = rng }
end

return M
