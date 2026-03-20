# Testing (busted)

Pure Lua modules under `src/` are covered with **[busted](https://olivinelabs.com/busted/)** specs in `spec/`. The game targets **Lua 5.1** (LÖVE 11.x); specs run on **LuaJIT** for a close match.

## Prerequisites

- **LuaJIT** and **LuaRocks** on your `PATH` (e.g. [DEVCOM.LuaJIT](https://github.com/DevelopersCommunity/cmake-luajit) on Windows).
- On Windows, rocks with C extensions (`luasystem`, `luafilesystem`, …) need a **MinGW** toolchain (e.g. [LLVM-MinGW](https://github.com/mstorsjo/llvm-mingw)) so `x86_64-w64-mingw32-gcc` is available when LuaRocks builds.

Configure LuaRocks to use LuaJIT (once per machine):

```bash
luarocks --lua-version=5.1 config variables.LUA "C:/path/to/luajit.exe"
luarocks --lua-version=5.1 install busted
```

Ensure `busted` is on `PATH` (LuaRocks usually adds `%USERPROFILE%\AppData\Roaming\luarocks\bin`).

## Run

From the **repository root**:

```bash
busted
```

`spec/helper.lua` (via `.busted`) appends `src/?.lua` to `package.path` (same as `main.lua`) and stubs `love.math.random` so `game.map_seed` can load outside LÖVE.

## LÖVE smoke

After code changes, a quick manual check:

```bash
love .
```

There is no headless CI hook here; load errors appear in the console if you run with `love .` from a terminal.
