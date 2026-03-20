--- Scene stack: push / pop / replace, lifecycle, callback forwarding.
--- Draw order is bottom → top so overlays (e.g. pause) render above play.

local M = {}
M.__index = M

function M.new(get_context)
  assert(type(get_context) == "function", "get_context must be a function")
  local self = setmetatable({
    stack = {},
    get_context = get_context,
  }, M)
  return self
end

function M:context()
  return self.get_context()
end

function M:top()
  return self.stack[#self.stack]
end

function M:push(scene)
  table.insert(self.stack, scene)
  if scene.enter then
    scene:enter(self:context())
  end
end

function M:pop()
  local scene = table.remove(self.stack)
  if scene and scene.exit then
    scene:exit()
  end
  return scene
end

--- Replace the top scene only (keeps any underlays intact).
function M:replace(scene)
  local top = table.remove(self.stack)
  if top and top.exit then
    top:exit()
  end
  self:push(scene)
end

function M:clear()
  while #self.stack > 0 do
    self:pop()
  end
end

function M:update(dt)
  local top = self:top()
  if top and top.update then
    top:update(dt)
  end
end

function M:draw()
  for i = 1, #self.stack do
    local s = self.stack[i]
    if s.draw then
      s:draw()
    end
  end
end

function M:resize(w, h)
  for i = 1, #self.stack do
    local s = self.stack[i]
    if s.resize then
      s:resize(w, h)
    end
  end
end

local function forward(method, self, ...)
  local top = self:top()
  if top and top[method] then
    return top[method](top, ...)
  end
end

function M:keypressed(key, scancode, isrepeat)
  return forward("keypressed", self, key, scancode, isrepeat)
end

function M:keyreleased(key, scancode)
  return forward("keyreleased", self, key, scancode)
end

function M:gamepadpressed(joystick, button)
  return forward("gamepadpressed", self, joystick, button)
end

function M:gamepadreleased(joystick, button)
  return forward("gamepadreleased", self, joystick, button)
end

function M:mousepressed(x, y, button, istouch, presses)
  return forward("mousepressed", self, x, y, button, istouch, presses)
end

function M:mousereleased(x, y, button, istouch, presses)
  return forward("mousereleased", self, x, y, button, istouch, presses)
end

function M:mousemoved(x, y, dx, dy, istouch)
  return forward("mousemoved", self, x, y, dx, dy, istouch)
end

function M:wheelmoved(x, y)
  return forward("wheelmoved", self, x, y)
end

--- Optional hook for cross-scene signals (HUD queues, etc.).
function M:emit(name, ...)
  local top = self:top()
  if top and top.on_emit then
    top:on_emit(name, ...)
  end
end

return M
