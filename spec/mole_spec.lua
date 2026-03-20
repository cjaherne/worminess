local mole = require("sim.mole")

describe("sim.mole", function()
  it("spawn_team creates five slotted moles with hp", function()
    local spawns = { { x = 1, y = 2 }, { x = 3, y = 4 }, { x = 5, y = 6 }, { x = 7, y = 8 }, { x = 9, y = 10 } }
    local team = mole.spawn_team(spawns, 2, 77)
    assert.are.equal(5, #team)
    for i = 1, 5 do
      assert.are.equal(2, team[i].player)
      assert.are.equal(i, team[i].slot)
      assert.is_true(team[i].alive)
      assert.are.equal(77, team[i].hp)
      assert.are.equal(77, team[i].max_hp)
      assert.are.equal(spawns[i].x, team[i].x)
    end
    assert.are.equal(-1, team[1].facing)
  end)
end)
