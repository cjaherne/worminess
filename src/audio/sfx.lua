--- Minimal procedural SFX (no shipped WAVs). DESIGN asset list can replace via file load later.

local M = {
  enabled = true,
  _sources = {},
}

local function make_tone(freq_hz, duration_s, volume, kind)
  local rate = 22050
  local n = math.max(1, math.floor(rate * duration_s))
  local ok, sd = pcall(love.sound.newSoundData, n, rate, 16, 1)
  if not ok or not sd then return nil end
  for i = 0, n - 1 do
    local t = i / rate
    local env = 1 - (i / math.max(1, n - 1))
    local s
    if kind == "square" then
      local ph = t * freq_hz * math.pi * 2
      s = math.sin(ph) >= 0 and 1 or -1
    elseif kind == "noise" then
      s = (love.math.random() * 2 - 1) * 0.8
    else
      s = math.sin(t * freq_hz * math.pi * 2)
    end
    sd:setSample(i, math.max(-1, math.min(1, s * volume * env)))
  end
  local src_ok, src = pcall(love.audio.newSource, sd, "static")
  if not src_ok or not src then return nil end
  src:setVolume(0.65)
  return src
end

function M.init()
  M._sources.fire = make_tone(880, 0.06, 0.35, "square")
  M._sources.ui = make_tone(520, 0.04, 0.25, "sine")
  M._sources.boom = make_tone(120, 0.18, 0.55, "noise")
end

local function play(name)
  if not M.enabled then return end
  local s = M._sources[name]
  if not s then return end
  s:stop()
  s:play()
end

function M.fire()
  play("fire")
end

function M.explosion()
  play("boom")
end

function M.ui()
  play("ui")
end

return M
