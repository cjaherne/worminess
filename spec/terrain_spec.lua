local Terrain = require("sim.terrain")

describe("sim.terrain", function()
  it("pixel_to_grid maps cell centers", function()
    local t = Terrain.new(4, 10, 10, function(x, y)
      return y >= 8
    end)
    local gx, gy = t:pixel_to_grid(0, 0)
    assert.are.equal(1, gx)
    assert.are.equal(1, gy)
  end)

  it("is_solid_px matches seeded cells", function()
    local t = Terrain.new(4, 5, 5, function(x, y)
      return x == 3 and y == 3
    end)
    assert.is_true(t:is_solid_px(10, 10))
    assert.is_false(t:is_solid_px(2, 2))
  end)

  it("carve_circle clears solid cells in radius", function()
    local t = Terrain.new(4, 20, 20, function(x, y)
      return y >= 10
    end)
    -- Use a pixel inside the grid; out-of-band coords use is_solid_px fallback (still "solid" below).
    local px, py = 40, 44
    assert.is_true(t:is_solid_px(px, py))
    t:carve_circle(px, py, 20)
    assert.is_false(t:is_solid_px(px, py))
  end)
end)
