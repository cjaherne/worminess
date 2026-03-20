local Terrain = require("sim.terrain")
local damage = require("sim.damage")

describe("sim.damage", function()
  local function make_world(moles)
    return {
      terrain = Terrain.new(4, 60, 40, function(_, y)
        return y >= 25
      end),
      moles = moles,
    }
  end

  it("damages enemy inside blast and respects friendly_fire", function()
    local m1 = { x = 100, y = 100, vx = 0, vy = 0, r = 16, hp = 100, max_hp = 100, player = 1, slot = 1, alive = true }
    local m2 = { x = 120, y = 100, vx = 0, vy = 0, r = 16, hp = 100, max_hp = 100, player = 2, slot = 1, alive = true }
    local w = make_world({ m1, m2 })
    damage.explosion(w, 110, 100, 80, 40, 200, 1, false)
    assert.is_true(m1.hp > 99)
    assert.is_true(m2.hp < 100)
  end)

  it("zeros damage for same team when friendly_fire is off", function()
    local a = { x = 100, y = 100, vx = 0, vy = 0, r = 16, hp = 50, max_hp = 50, player = 1, slot = 1, alive = true }
    local b = { x = 105, y = 100, vx = 0, vy = 0, r = 16, hp = 50, max_hp = 50, player = 1, slot = 2, alive = true }
    local w = make_world({ a, b })
    damage.explosion(w, 100, 100, 120, 80, 0, 1, false)
    assert.are.equal(50, a.hp)
    assert.are.equal(50, b.hp)
  end)

  it("allows same-team damage when friendly_fire is on", function()
    local a = { x = 100, y = 100, vx = 0, vy = 0, r = 16, hp = 50, max_hp = 50, player = 1, slot = 1, alive = true }
    local w = make_world({ a })
    damage.explosion(w, 100, 100, 120, 80, 0, 1, true)
    assert.is_true(a.hp < 50)
  end)
end)
