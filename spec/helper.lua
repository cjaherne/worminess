-- Busted runs from the project root; mirror main.lua module resolution.
package.path = package.path .. ";./src/?.lua;./src/?/init.lua"

-- map_seed.derive(nil, …) calls love.math.random; stub when LÖVE is absent.
if not rawget(_G, "love") then
  _G.love = {
    math = {
      random = function(_a, _b)
        return 424242
      end,
    },
  }
end
