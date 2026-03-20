-- Weapon definitions (data-only); systems/weapons.lua applies them
local M = {
  rocket = {
    id = "rocket",
    name = "Rocket",
    speed = 980,
    gravity_scale = 1,
    hit_radius = 8,
    blast_radius = 72,
    terrain_radius = 76,
    damage_max = 48,
    knockback = 320,
    wind_scale = 0.35,
  },
  grenade = {
    id = "grenade",
    name = "Grenade",
    speed = 420,
    gravity_scale = 1,
    hit_radius = 10,
    blast_radius = 88,
    terrain_radius = 90,
    damage_max = 55,
    knockback = 380,
    restitution = 0.35,
    roll_friction = 0.96,
    wind_scale = 0.85,
    -- fuse_seconds filled from MatchConfig at fire time
  },
}

return M
