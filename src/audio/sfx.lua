--- Procedural SFX (no external assets); lazy-built on first play.
local M = {
  _inited = false,
  sources = {},
  volume = 0.85,
}

local function tone_sweep(rate, dur, f0, f1, amp)
  local n = math.max(1, math.floor(rate * dur))
  local sd = love.sound.newSoundData(n, rate, 16, 1)
  for i = 0, n - 1 do
    local t = i / n
    local f = f0 + (f1 - f0) * t
    local env = math.sin(math.pi * t) -- 0→1→0
    local ph = (i / rate) * f * math.pi * 2
    sd:setSample(i, math.sin(ph) * amp * env)
  end
  return sd
end

local function noise_burst(rate, dur, amp)
  local n = math.max(1, math.floor(rate * dur))
  local sd = love.sound.newSoundData(n, rate, 16, 1)
  for i = 0, n - 1 do
    local t = i / n
    local env = math.sin(math.pi * t) ^ 0.8
    sd:setSample(i, (love.math.random() * 2 - 1) * amp * env)
  end
  return sd
end

local function thump(rate, dur, freq, amp)
  local n = math.max(1, math.floor(rate * dur))
  local sd = love.sound.newSoundData(n, rate, 16, 1)
  for i = 0, n - 1 do
    local t = i / rate
    local env = math.exp(-t * 14)
    sd:setSample(i, math.sin(t * freq * math.pi * 2) * amp * env)
  end
  return sd
end

function M.init()
  if M._inited then
    return
  end
  M._inited = true
  local r = 44100
  M.sources.fire = love.audio.newSource(tone_sweep(r, 0.09, 520, 1400, 0.22), "static")
  M.sources.grenade_pop = love.audio.newSource(tone_sweep(r, 0.07, 300, 680, 0.2), "static")
  M.sources.explosion = love.audio.newSource(noise_burst(r, 0.32, 0.35), "static")
  M.sources.explosion_tail = love.audio.newSource(thump(r, 0.45, 55, 0.45), "static")
  M.sources.hurt = love.audio.newSource(tone_sweep(r, 0.05, 220, 90, 0.25), "static")
  M.sources.ui = love.audio.newSource(tone_sweep(r, 0.04, 660, 880, 0.12), "static")
  for _, s in pairs(M.sources) do
    s:setVolume(M.volume)
  end
end

function M.play(id, vol_mul)
  M.init()
  local s = M.sources[id]
  if not s then
    return
  end
  vol_mul = vol_mul or 1
  s:setVolume(M.volume * vol_mul)
  s:stop()
  s:play()
end

function M.play_explosion(vol_mul)
  M.init()
  vol_mul = vol_mul or 1
  local a = M.sources.explosion
  local b = M.sources.explosion_tail
  if a then
    a:setVolume(M.volume * vol_mul)
    a:stop()
    a:play()
  end
  if b then
    b:setVolume(M.volume * vol_mul * 0.9)
    b:stop()
    b:play()
  end
end

return M
