local match_config = require("game.match_config")

local M = {}

function M.new()
  return {
    scores = { 0, 0 },
    matches_completed = 0,
    last_match_config = match_config.defaults(),
    last_match_winner = nil,
    bump_match_win = function(self, player_index)
      self.scores[player_index] = (self.scores[player_index] or 0) + 1
      self.matches_completed = self.matches_completed + 1
      self.last_match_winner = player_index
    end,
    get_scores = function(self)
      return self.scores[1], self.scores[2]
    end,
  }
end

return M
