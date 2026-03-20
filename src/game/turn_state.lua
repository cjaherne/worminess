local M = {}

local phases = {
  aim = "aim",
  firing = "firing",
  flying = "flying",
  round_end = "round_end",
  interstitial = "interstitial",
}

function M.new()
  return {
    phase = phases.aim,
    active_player = 1,
    active_mole_slot = 1,
    move_budget = 0,
    aim_angle = -math.pi / 2,
    power = 0,
    charging = false,
    weapon_index = 1,
    weapons = { "rocket", "grenade" },
    interstitial_t = 0,
    turn_time_left = nil,
  }
end

function M.active_mole(ts, teams)
  local team = teams[ts.active_player]
  if not team then
    return nil
  end
  return team.moles[ts.active_mole_slot]
end

function M.current_weapon_id(ts)
  return ts.weapons[ts.weapon_index]
end

function M.next_living_mole_index(team, preferred_slot)
  -- preferred_slot is index into mole_order (1..5)
  local order = team.mole_order
  for k = 0, #order - 1 do
    local idx = order[((preferred_slot - 1 + k) % #order) + 1]
    local m = team.moles[idx]
    if m and m.alive then
      return idx
    end
  end
  return nil
end

function M.advance_turn(ts, teams, starting_slot_team1, starting_slot_team2)
  local next_p = ts.active_player == 1 and 2 or 1
  ts.active_player = next_p
  local team = teams[next_p]
  local slot = next_p == 1 and starting_slot_team1 or starting_slot_team2
  local midx = M.next_living_mole_index(team, slot)
  ts.active_mole_slot = midx or 1
  ts.phase = phases.aim
  ts.move_budget = require("data.constants").MOVE_BUDGET_MAX
  ts.power = 0
  ts.charging = false
  ts.aim_angle = -math.pi / 2
  ts.interstitial_t = 0
end

function M.start_match_turn(ts, teams, starting_player, mole_slot_team1, mole_slot_team2)
  ts.active_player = starting_player
  local team = teams[starting_player]
  local slot = starting_player == 1 and mole_slot_team1 or mole_slot_team2
  local midx = M.next_living_mole_index(team, slot)
  ts.active_mole_slot = midx or 1
  ts.phase = phases.aim
  ts.move_budget = require("data.constants").MOVE_BUDGET_MAX
  ts.power = 0
  ts.charging = false
  ts.aim_angle = -math.pi / 2
  ts.interstitial_t = 0
end

function M.begin_interstitial(ts, duration)
  ts.phase = phases.interstitial
  ts.interstitial_t = duration or 1.5
end

function M.tick_interstitial(ts, dt)
  if ts.phase ~= phases.interstitial then
    return false
  end
  ts.interstitial_t = ts.interstitial_t - dt
  if ts.interstitial_t <= 0 then
    ts.interstitial_t = 0
    ts.phase = phases.aim
    return true
  end
  return false
end

--- If the active mole died (fall, etc.), pick next living on same team. Returns "ok" | "reassigned" | "team_wiped".
function M.repair_active_slot(ts, teams)
  local team = teams[ts.active_player]
  if not team then
    return "ok"
  end
  local m = team.moles[ts.active_mole_slot]
  if m and m.alive then
    return "ok"
  end
  local idx = M.next_living_mole_index(team, 1)
  if idx then
    ts.active_mole_slot = idx
    ts.move_budget = require("data.constants").MOVE_BUDGET_MAX
    ts.power = 0
    ts.charging = false
    ts.aim_angle = -math.pi / 2
    return "reassigned"
  end
  return "team_wiped"
end

M.phases = phases

return M
