local defaults = require("config.defaults")

local function is_rgb3(t)
  return type(t) == "table" and #t == 3
    and type(t[1]) == "number" and type(t[2]) == "number" and type(t[3]) == "number"
end

describe("config.defaults", function()
  it("loads and returns a table", function()
    assert.is_table(defaults)
  end)

  it("exposes core sim tuning fields", function()
    assert.is_number(defaults.cell)
    assert.is_number(defaults.grid_w)
    assert.is_number(defaults.grid_h)
    assert.is_number(defaults.gravity)
    assert.is_number(defaults.mole_radius)
    assert.is_number(defaults.jump_speed)
    assert.is_number(defaults.walk_speed)
    assert.is_number(defaults.max_dt)
  end)

  it("exposes weapon tuning nested table", function()
    assert.is_table(defaults.weapon)
    local w = defaults.weapon
    assert.is_number(w.rocket_speed)
    assert.is_number(w.rocket_radius)
    assert.is_number(w.rocket_blast)
    assert.is_number(w.rocket_damage)
    assert.is_number(w.rocket_gravity_mul)
    assert.is_number(w.rocket_ray_steps)
    assert.is_number(w.grenade_speed_mul)
    assert.is_number(w.grenade_fuse)
    assert.is_number(w.grenade_blast)
    assert.is_number(w.grenade_damage)
    assert.is_number(w.grenade_bounce)
    assert.is_number(w.grenade_unstick_px)
  end)

  it("exposes wind presets", function()
    assert.is_table(defaults.wind_force)
    local wf = defaults.wind_force
    assert.is_number(wf.low)
    assert.is_number(wf.med)
    assert.is_number(wf.high)
  end)

  it("exposes palette entries as RGB triples", function()
    assert.is_table(defaults.colors)
    local c = defaults.colors
    assert.is_true(is_rgb3(c.team1))
    assert.is_true(is_rgb3(c.team2))
    assert.is_true(is_rgb3(c.sky_top))
    assert.is_true(is_rgb3(c.sky_bot))
    assert.is_true(is_rgb3(c.dirt))
    assert.is_true(is_rgb3(c.dirt_dark))
    assert.is_true(is_rgb3(c.grass))
  end)

  it("is cached by require (single module instance)", function()
    assert.are.same(defaults, require("config.defaults"))
  end)
end)
