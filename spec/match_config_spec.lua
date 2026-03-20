local match_config = require("game.match_config")
local C = require("data.constants")

describe("game.match_config", function()
  describe("defaults", function()
    it("returns a valid baseline config", function()
      local d = match_config.defaults()
      assert.equals(100, d.mole_max_hp)
      assert.equals(2, d.rounds_to_win)
      assert.equals(0, d.wind_strength)
      assert.equals(3, d.grenade_fuse_seconds)
      assert.is_nil(d.turn_time_limit)
      assert.is_true(d.friendly_fire)
      assert.is_nil(d.procedural_seed)
      assert.equals(C.WORLD_W, d.map_width)
      assert.equals(C.WORLD_H, d.map_height)
      assert.equals(C.MOLES_PER_TEAM, d.teams_per_player)
      assert.equals("shared_kb", d.input_scheme)
    end)
  end)

  describe("validate", function()
    it("clamps mole_max_hp, rounds, wind, fuse, and turn timer", function()
      local c = match_config.defaults()
      c.mole_max_hp = 9999
      c.rounds_to_win = 99
      c.wind_strength = 900
      c.grenade_fuse_seconds = 0.1
      c.turn_time_limit = 3
      match_config.validate(c)
      assert.equals(500, c.mole_max_hp)
      assert.equals(9, c.rounds_to_win)
      assert.equals(400, c.wind_strength)
      assert.equals(0.5, c.grenade_fuse_seconds)
      assert.equals(5, c.turn_time_limit)
    end)

    it("leaves turn_time_limit nil when unset", function()
      local c = match_config.defaults()
      c.turn_time_limit = nil
      match_config.validate(c)
      assert.is_nil(c.turn_time_limit)
    end)
  end)

  describe("copy", function()
    it("produces an independent shallow copy", function()
      local a = match_config.defaults()
      a.mole_max_hp = 77
      local b = match_config.copy(a)
      assert.equals(77, b.mole_max_hp)
      a.mole_max_hp = 1
      assert.equals(77, b.mole_max_hp)
    end)
  end)
end)
