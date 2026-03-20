local mole_ent = require("entities.mole")
local C = require("data.constants")

local unpack = table.unpack or unpack

local M = {}

local function default_order()
  return { 1, 2, 3, 4, 5 }
end

function M.rotate_order(order)
  local o = { unpack(order, 1, #order) }
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

--- Next index into mole_order (1..#order) after mole_idx fired.
function M.next_order_slot_after_mole(team, mole_idx)
  local order = team.mole_order
  for i = 1, #order do
    if order[i] == mole_idx then
      return (i % #order) + 1
    end
  end
  return 1
end

function M.place_team_from_spawns(team, spawn_list, max_hp)
  for i = 1, #team.moles do
    local m = team.moles[i]
    local sp = spawn_list[i]
    if sp then
      m.x, m.y = sp.x, sp.y
    end
    m.max_hp = max_hp
    m.hp = max_hp
    m.alive = true
    m.vx, m.vy = 0, 0
  end
end

return M
