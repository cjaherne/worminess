local TurnState = require("sim.turn_state")

local function mole(player, slot, alive)
  return { player = player, slot = slot, alive = alive, hp = alive and 100 or 0 }
end

describe("sim.turn_state", function()
  local function all_living()
    local m = {}
    for p = 1, 2 do
      for s = 1, 5 do
        m[#m + 1] = mole(p, s, true)
      end
    end
    return m
  end

  it("new honors fixed first_player", function()
    local ts = TurnState.new({ first_player = "2", turn_time_seconds = 0 })
    assert.are.equal(2, ts.active_player)
  end)

  it("active_mole returns the living mole for active player and slot", function()
    local ts = TurnState.new({ first_player = "1", turn_time_seconds = 0 })
    local moles = all_living()
    local m = ts:active_mole(moles)
    assert.are.equal(1, m.player)
    assert.are.equal(1, m.slot)
  end)

  it("end_turn advances only ended player's slot and swaps active player", function()
    local ts = TurnState.new({ first_player = "1", turn_time_seconds = 0 })
    local moles = all_living()
    local settings = { turn_time_seconds = 0 }
    ts:end_turn(moles, settings)
    assert.are.equal(2, ts.mole_slot[1])
    assert.are.equal(1, ts.mole_slot[2])
    assert.are.equal(2, ts.active_player)
  end)

  it("advance skips dead moles in ring order", function()
    local ts = TurnState.new({ first_player = "1", turn_time_seconds = 0 })
    ts.mole_slot[1] = 1
    local moles = {
      mole(1, 1, true),
      mole(1, 2, false),
      mole(1, 3, true),
      mole(1, 4, true),
      mole(1, 5, true),
      mole(2, 1, true),
      mole(2, 2, true),
      mole(2, 3, true),
      mole(2, 4, true),
      mole(2, 5, true),
    }
    ts:end_turn(moles, { turn_time_seconds = 0 })
    assert.are.equal(3, ts.mole_slot[1])
  end)

  it("sync_slots_to_living advances along the roster ring when the current slot is dead", function()
    local ts = TurnState.new({ first_player = "1", turn_time_seconds = 0 })
    ts.mole_slot[1] = 2
    local moles = {
      mole(1, 1, true),
      mole(1, 2, false),
      mole(1, 3, true),
      mole(1, 4, true),
      mole(1, 5, true),
      mole(2, 1, true),
      mole(2, 2, true),
      mole(2, 3, true),
      mole(2, 4, true),
      mole(2, 5, true),
    }
    ts:sync_slots_to_living(moles)
    assert.are.equal(3, ts.mole_slot[1])
  end)

  it("update_timer ends turn when limit elapses", function()
    local ts = TurnState.new({ first_player = "1", turn_time_seconds = 1 })
    local moles = all_living()
    local settings = { turn_time_seconds = 1 }
    assert.is_false(ts:update_timer(0.5, moles, settings))
    assert.is_true(ts:update_timer(0.6, moles, settings))
    assert.are.equal(2, ts.active_player)
  end)
end)
