# Quick Start

Get Nova2D running in under 5 minutes.

## Prerequisites

- [Love2D 11.x](https://love2d.org/) installed

## 1. Clone the project

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
```

## 2. Run it

```bash
love .
```

You should see the Nova2D splash screen, followed by the main menu with New Game, Credits, and Quit options.

## 3. Create a moving entity

Create `src/entities/player.lua`:

```lua
local Player = {}

function Player:enter()
    self.x = 400
    self.y = 300
end

function Player:update(dt)
    self.x = self.x + 100 * dt
end

function Player:draw()
    love.graphics.circle("fill", self.x, self.y, 20)
end

return Player
```

## 4. Next steps

- Read the [States guide](../core-concepts/states.md) to understand screen management
- Read the [Entities guide](../core-concepts/entities.md) for game objects
- Install dependencies with `love gestor/ install`
