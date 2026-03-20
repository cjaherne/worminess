local mole_ent = require("entities.mole")
local C = require("data.constants")

local M = {}

local function default_order()
  return { 1, 2, 3, 4, 5 }
end

function M.rotate_order(order)
  local o = { unpack(order) }
  table.insert(o, table.remove(o, 1))
  return o
end

function M.new_team(player_index, color, max_hp)
  local moles = {}
  for i = 1, C.MOLES_PER_TEAM do
    moles[i] = mole_ent.new(player_index, i, max_hp)
  end
  return {
    player_index = player_index,
    color = color,
    moles = moles,
    mole_order = default_order(),
  }
end

function M.team_living_count(team)
  local n = 0
  for i = 1, #team.moles do
    if team.moles[i].alive then
      n = n + 1
    end
  end
  return n
end

function M.all_moles(teams)
  local out = {}
  for t = 1, #teams do
    for i = 1, #teams[t].moles do
      out[#out + 1] = teams[t].moles[i]
    end
  end
  return out
end

return M
