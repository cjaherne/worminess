local roster = require("game.roster")
local C = require("data.constants")

describe("game.roster", function()
  describe("rotate_order", function()
    it("rotates mole order left", function()
      assert.same({ 2, 3, 1 }, roster.rotate_order({ 1, 2, 3 }))
    end)

    it("does not mutate the original table", function()
      local o = { 1, 2, 3 }
      roster.rotate_order(o)
      assert.same({ 1, 2, 3 }, o)
    end)
  end)

  describe("new_team", function()
    it("creates MOLES_PER_TEAM living moles", function()
      local t = roster.new_team(1, { 1, 0, 0 }, 50)
      assert.equals(1, t.player_index)
      assert.equals(C.MOLES_PER_TEAM, #t.moles)
      assert.equals(C.MOLES_PER_TEAM, #t.mole_order)
      for i = 1, #t.moles do
        assert.is_true(t.moles[i].alive)
        assert.equals(50, t.moles[i].hp)
        assert.equals(1, t.moles[i].team)
      end
    end)
  end)

  describe("team_living_count", function()
    it("counts only living moles", function()
      local t = roster.new_team(1, { 1, 0, 0 }, 10)
      t.moles[1].alive = false
      assert.equals(C.MOLES_PER_TEAM - 1, roster.team_living_count(t))
    end)
  end)

  describe("next_order_slot_after_mole", function()
    it("returns next slot in mole_order wrapping", function()
      local t = roster.new_team(1, { 1, 0, 0 }, 10)
      t.mole_order = { 3, 1, 5, 2, 4 }
      assert.equals(2, roster.next_order_slot_after_mole(t, 3))
      assert.equals(1, roster.next_order_slot_after_mole(t, 4))
    end)
  end)

  describe("place_team_from_spawns", function()
    it("positions moles and resets hp and velocity", function()
      local t = roster.new_team(1, { 1, 0, 0 }, 10)
      t.moles[1].alive = false
      local spawns = {
        { x = 10, y = 20 },
        { x = 30, y = 40 },
      }
      roster.place_team_from_spawns(t, spawns, 99)
      assert.equals(10, t.moles[1].x)
      assert.equals(20, t.moles[1].y)
      assert.is_true(t.moles[1].alive)
      assert.equals(99, t.moles[1].hp)
      assert.equals(0, t.moles[1].vx)
      assert.equals(0, t.moles[1].vy)
    end)
  end)

  describe("all_moles", function()
    it("flattens moles from all teams", function()
      local a = roster.new_team(1, { 1, 0, 0 }, 5)
      local b = roster.new_team(2, { 0, 1, 0 }, 5)
      local all = roster.all_moles({ a, b })
      assert.equals(C.MOLES_PER_TEAM * 2, #all)
    end)
  end)
end)
