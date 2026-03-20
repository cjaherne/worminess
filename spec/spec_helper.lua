-- Busted helper: game modules live under src/ (same layout as love.filesystem.setRequirePath in main.lua).
-- Stubs minimal `love` APIs used by some sim modules when tests require them outside LÖVE.

local sep = package.config:sub(1, 1)

local function path_join(a, b, c)
  return a .. sep .. b .. (c and (sep .. c) or "")
end

--- Resolve repo root: directory that contains src/config/defaults.lua
local function repo_root()
  local env = os.getenv("WORMINESS_ROOT")
  if env and env ~= "" then
    local probe = path_join(path_join(env, "src", "config"), "defaults.lua")
    local f = io.open(probe, "r")
    if f then
      f:close()
      return env
    end
  end

  for level = 2, 20 do
    local info = debug.getinfo(level, "S")
    if not info then
      break
    end
    local s = info.source or ""
    if s:sub(1, 1) == "@" then
      s = s:sub(2):gsub("\\", "/")
      local dir = s:match("^(.+)/[^/]+$")
      while dir do
        local rel = dir .. "/src/config/defaults.lua"
        local probe = rel:gsub("/", sep)
        local f = io.open(probe, "r")
        if f then
          f:close()
          return dir:gsub("/", sep)
        end
        dir = dir:match("^(.+)/[^/]+$")
      end
    end
  end

  local f = io.open(path_join(path_join(path_join(".", "src"), "config"), "defaults.lua"), "r")
  if f then
    f:close()
    return "."
  end

  return "."
end

local root = repo_root()

-- LÖVE / Lua: dotted module names map to nested paths under src/?.lua — config.defaults -> src/config/defaults.lua
local config_defaults_path = path_join(path_join(root, "src", "config"), "defaults.lua")
package.preload["config.defaults"] = function()
  return assert(loadfile(config_defaults_path))()
end

package.path = path_join(root, "src", "?.lua") .. ";"
  .. path_join(root, "src", "?") .. sep .. "init.lua;"
  .. package.path

_G.love = _G.love or {}
love.math = love.math or {}
if not love.math.random then
  love.math.random = math.random
end

math.atan2 = math.atan2 or function(y, x)
  return math.atan(y, x)
end
