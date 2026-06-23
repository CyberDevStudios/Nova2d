# Entities

Entities are game objects — players, enemies, items, and anything else that exists in your game world. Each entity is a separate Lua module.

## Entity structure

```lua
-- src/entities/player.lua
local Player = {}

function Player:enter(parent, args)
    self.x = 400
    self.y = 300
    self.speed = 200
    self.hp = 100
end

function Player:update(dt)
    -- Movement
    if love.keyboard.isDown("left") then
        self.x = self.x - self.speed * dt
    elseif love.keyboard.isDown("right") then
        self.x = self.x + self.speed * dt
    end
end

function Player:draw()
    -- Render
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, 20)
end

return Player
```

## Conventions

- `PascalCase` for entity module names
- One file per entity
- Each file returns a table
- `local` everywhere, no globals
- `update(dt)` for logic, `draw()` for rendering
- `enter()` for initialization

## Entity lifecycle

| Method | Purpose |
|---|---|
| `enter(parent, ...)` | Initialize entity state |
| `update(dt)` | Per-frame logic |
| `draw()` | Per-frame rendering |
| `leave()` | Cleanup when removed |
