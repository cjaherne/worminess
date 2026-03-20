describe("game.map_seed", function()
  local map_seed

  before_each(function()
    package.loaded["game.map_seed"] = nil
    map_seed = require("game.map_seed")
  end)

  it("derive(nil, round) uses love.math.random stub from helper", function()
    local s = map_seed.derive(nil, 1)
    assert.equals(424242, s)
  end)

  it("derive is deterministic when procedural_seed is set", function()
    assert.equals(776289342, map_seed.derive(10, 1))
    assert.equals(1283241456, map_seed.derive(10, 2))
  end)

  it("coerces non-positive round_index to at least 1", function()
    assert.equals(map_seed.derive(10, 0), map_seed.derive(10, 1))
    assert.equals(map_seed.derive(10, -3), map_seed.derive(10, 1))
  end)

  it("returns positive integers for edge procedural_seed modulo", function()
    local s = map_seed.derive(2147483646, 1)
    assert.is_true(s >= 1)
    assert.equals(math.floor(s), s)
  end)
end)
