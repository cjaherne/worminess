local turn_state = require("game.turn_state")
local roster = require("game.roster")

local M = {}

function M.sim_idle(ctx)
  return #ctx.projectiles == 0 and #ctx.grenades == 0
end

--- After all projectiles settle: round win or advance turn. Returns "round_end", "advanced", or nil.
function M.resolve_flying_end(ctx)
  local ts = ctx.turn
  if ts.phase ~= turn_state.phases.flying then
    return nil
  end
  if not M.sim_idle(ctx) then
    return nil
  end
  local teams = ctx.teams
  local c1 = roster.team_living_count(teams[1])
  local c2 = roster.team_living_count(teams[2])
  if c1 == 0 or c2 == 0 then
    local winner = (c1 == 0) and 2 or 1
    return "round_end", winner
  end
  local prev_p = ts.active_player
  local prev_midx = ts.active_mole_slot
  ctx.team_turn_slot[prev_p] = roster.next_order_slot_after_mole(teams[prev_p], prev_midx)
  turn_state.advance_turn(ts, teams, ctx.team_turn_slot[1], ctx.team_turn_slot[2])
  if ctx.match_config.turn_time_limit then
    ts.turn_time_left = ctx.match_config.turn_time_limit
  else
    ts.turn_time_left = nil
  end
  return "advanced"
end

return M
