local M = {
  player1_wins = 0,
  player2_wins = 0,
  draws = 0,
  games_played = 0,
}

function M.reset()
  M.player1_wins = 0
  M.player2_wins = 0
  M.draws = 0
  M.games_played = 0
end

--- winner_id: 1, 2, or 0 draw
function M.record_match_outcome(winner_id)
  M.games_played = M.games_played + 1
  if winner_id == 1 then
    M.player1_wins = M.player1_wins + 1
  elseif winner_id == 2 then
    M.player2_wins = M.player2_wins + 1
  else
    M.draws = M.draws + 1
  end
end

function M.get_snapshot()
  return {
    gamesPlayedP1 = M.player1_wins,
    gamesPlayedP2 = M.player2_wins,
    gamesDrawn = M.draws,
    games_played = M.games_played,
  }
end

return M
