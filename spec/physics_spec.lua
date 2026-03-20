local Terrain = require("sim.terrain")
local physics = require("sim.physics")

describe("sim.physics", function()
  local function flat_terrain()
    return Terrain.new(4, 80, 40, function(_, y)
      return y >= 30
    end)
  end

  it("segment_hits_terrain returns impact point", function()
    local t = flat_terrain()
    local px, py = physics.segment_hits_terrain(t, 10, 10, 10, 500, 64)
    assert.is_not_nil(px)
    assert.is_not_nil(py)
    assert.is_true(py < 200)
  end)

  it("ray_mole_hit picks nearest mole along segment", function()
    local m_far = { x = 50, y = 50, r = 16, alive = true, player = 2, slot = 1 }
    local m_near = { x = 20, y = 50, r = 16, alive = true, player = 2, slot = 2 }
    local hit, t = physics.ray_mole_hit({ m_far, m_near }, 0, 50, 100, 50, 1, false, 32)
    assert.are.same(m_near, hit)
    assert.is_true(t < 0.3)
  end)

  it("update_mole applies gravity and walking on flat ground", function()
    local t = flat_terrain()
    -- Start just above the flat surface (row 30 solid at y >= 116 in a 40-tall grid, cell 4).
    local mole = { x = 40, y = 80, vx = 0, vy = 0, r = 16, hp = 10, grounded = false, facing = 1 }
    for _ = 1, 240 do
      physics.update_mole(mole, t, 1 / 60, 0, false, 520)
    end
    assert.is_true(mole.grounded)
    assert.is_true(math.abs(mole.vy) < 2)
  end)
end)
