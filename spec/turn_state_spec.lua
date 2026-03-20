local turn_state = require("game.turn_state")
local roster = require("game.roster")
local C = require("data.constants")

local function make_teams()
  local t1 = roster.new_team(1, { 1, 0, 0 }, 100)
  local t2 = roster.new_team(2, { 0, 1, 0 }, 100)
  return { t1, t2 }
end

describe("game.turn_state", function()
  describe("next_living_mole_index", function()
    it("skips dead moles in mole_order", function()
      local team = roster.new_team(1, { 1, 0, 0 }, 10)
      team.mole_order = { 1, 2, 3, 4, 5 }
      team.moles[1].alive = false
      team.moles[2].alive = false
      assert.equals(3, turn_state.next_living_mole_index(team, 1))
    end)

    it("returns nil when team is wiped", function()
      local team = roster.new_team(1, { 1, 0, 0 }, 10)
      for i = 1, #team.moles do
        team.moles[i].alive = false
      end
      assert.is_nil(turn_state.next_living_mole_index(team, 1))
    end)
  end)

  describe("advance_turn", function()
    it("alternates active player and picks a living mole", function()
      local teams = make_teams()
      local ts = turn_state.new()
      ts.active_player = 1
      ts.active_mole_slot = 1
      turn_state.advance_turn(ts, teams, 1, 1)
      assert.equals(2, ts.active_player)
      assert.is_true(ts.active_mole_slot >= 1 and ts.active_mole_slot <= C.MOLES_PER_TEAM)
      assert.equals(turn_state.phases.aim, ts.phase)
      assert.equals(C.MOVE_BUDGET_MAX, ts.move_budget)
    end)
  end)

  describe("start_match_turn", function()
    it("sets starting player from argument", function()
      local teams = make_teams()
      local ts = turn_state.new()
      turn_state.start_match_turn(ts, teams, 2, 1, 1)
      assert.equals(2, ts.active_player)
      assert.equals(turn_state.phases.aim, ts.phase)
    end)
  end)

  describe("interstitial", function()
    it("begin_interstitial sets phase and timer", function()
      local ts = turn_state.new()
      turn_state.begin_interstitial(ts, 2)
      assert.equals(turn_state.phases.interstitial, ts.phase)
      assert.equals(2, ts.interstitial_t)
    end)

    it("tick_interstitial transitions to aim when elapsed", function()
      local ts = turn_state.new()
      turn_state.begin_interstitial(ts, 0.5)
      assert.is_false(turn_state.tick_interstitial(ts, 0.2))
      assert.is_true(turn_state.tick_interstitial(ts, 0.4))
      assert.equals(turn_state.phases.aim, ts.phase)
    end)
  end)

  describe("repair_active_slot", function()
    it("reassigns when active mole died", function()
      local teams = make_teams()
      local ts = turn_state.new()
      ts.active_player = 1
      ts.active_mole_slot = 1
      teams[1].moles[1].alive = false
      teams[1].moles[2].alive = true
      local r = turn_state.repair_active_slot(ts, teams)
      assert.equals("reassigned", r)
      assert.equals(2, ts.active_mole_slot)
    end)

    it("returns team_wiped when no living moles", function()
      local teams = make_teams()
      local ts = turn_state.new()
      ts.active_player = 1
      for i = 1, #teams[1].moles do
        teams[1].moles[i].alive = false
      end
      assert.equals("team_wiped", turn_state.repair_active_slot(ts, teams))
    end)
  end)

  describe("current_weapon_id", function()
    it("returns selected weapon id", function()
      local ts = turn_state.new()
      assert.equals("rocket", turn_state.current_weapon_id(ts))
      ts.weapon_index = 2
      assert.equals("grenade", turn_state.current_weapon_id(ts))
    end)
  end)
end)
