local mole = require("entities.mole")

describe("entities.mole", function()
  local m

  before_each(function()
    m = mole.new(1, 3, 100)
  end)

  it("damage applies from enemy; same team blocked when friendly_fire is false", function()
    mole.damage(m, 40, false, 1)
    assert.equals(100, m.hp)
    mole.damage(m, 40, false, 2)
    assert.equals(60, m.hp)
    assert.is_true(m.alive)
    mole.damage(m, 100, false, 2)
    assert.equals(0, m.hp)
    assert.is_false(m.alive)
  end)

  it("allows same-team damage when friendly_fire is true", function()
    mole.damage(m, 50, true, 1)
    assert.equals(50, m.hp)
  end)

  it("apply_impulse adds velocity when alive", function()
    mole.apply_impulse(m, 10, -5)
    assert.equals(10, m.vx)
    assert.equals(-5, m.vy)
    m.alive = false
    mole.apply_impulse(m, 99, 99)
    assert.equals(10, m.vx)
    assert.equals(-5, m.vy)
  end)
end)
