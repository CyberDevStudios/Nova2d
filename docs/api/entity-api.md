# Entity API

Every entity module returns a table that implements these lifecycle methods.

## Methods

### `enter(parent, ...)`
Called when the entity is created or activated.
- `parent`: the owning state or manager
- `...`: any additional arguments

Initialize entity state here:
```lua
function Player:enter()
    self.x = 0
    self.y = 0
    self.hp = 100
end
```

### `update(dt)`
Called every frame. All game logic goes here.
- `dt`: delta time in seconds (frame-independent)

```lua
function Player:update(dt)
    self.x = self.x + self.speed * dt
end
```

### `draw()`
Called every frame after `update()`. All rendering goes here.
```lua
function Player:draw()
    love.graphics.circle("fill", self.x, self.y, 20)
end
```

### `leave()`
Called when the entity is removed or deactivated.

## Example: complete entity

```lua
local Enemy = {}

function Enemy:enter(parent, x, y)
    self.x = x
    self.y = y
    self.speed = 150
    self.hp = 50
end

function Enemy:update(dt)
    self.x = self.x - self.speed * dt
end

function Enemy:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y, 30, 30)
end

return Enemy
```
