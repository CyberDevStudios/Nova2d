# Nova2D

> Framework base para Love2D que estandariza la estructura, gestion de dependencias y herramientas de desarrollo para juegos 2D en Lua.

## Estado del Proyecto

| Fase | Estado |
|---|---|
| **v0.1** — Base structure + states | Completado |
| **v0.2** — Dependency manager | Por hacer |
| **v0.3** — Hot reload | Por hacer |
| **v0.4** — Installer | Por hacer |
| **v0.5** — Web documentation | Por hacer |
| **v1.0** — Public release | Por hacer |

## Requisitos

- [Love2D 11.x](https://love2d.org/) (Lua 5.1)
- `curl` (para el gestor de dependencias, v0.2+)

## Inicio Rapido

```bash
git clone https://github.com/MatFon73/Nova2d.git mi-juego
cd mi-juego
love .
```

Veras el splash de Nova2D, Menu principal, Pantalla de juego lista para construir.

## Estructura del Proyecto

```
mi-juego/
├── main.lua              -- Punto de entrada (no modificar)
├── conf.lua              -- Configuracion de ventana
├── nova2d.lua            -- Dependencias del proyecto
├── nova2d-lock.lua       -- Lockfile generado automaticamente
├── src/
│   ├── states/           -- Pantallas (splash, menu, game, pause, credits)
│   ├── entities/         -- Jugador, enemigos, objetos
│   ├── systems/          -- Fisica, audio, colisiones
│   └── utils/            -- Helpers
├── assets/
│   ├── images/           -- Sprites, texturas
│   ├── sounds/           -- Efectos de sonido
│   └── fonts/            -- Tipografias
└── libs/                 -- Dependencias externas
    └── hump/             -- Gamestate management
```

## Pantallas Disponibles (v0.1)

| Pantalla | Descripcion |
|---|---|
| **Splash** | Logo de Nova2D, transicion automatica a los 3s |
| **Menu Principal** | Nuevo juego, Creditos, Salir - navegacion por teclado y mouse |
| **Game** | Pantalla vacia lista para tu juego |
| **Pausa** | Overlay semi-transparente con Escape |
| **Creditos** | Librerias incluidas y sus autores |

## Convenciones

- `camelCase` para variables y funciones
- `PascalCase` para entidades y sistemas
- `local` siempre que sea posible
- Separacion estricta entre `update()` (logica) y `draw()` (presentacion)
- Un archivo por entidad o sistema

## Librerias Incluidas

| Libreria | Proposito |
|---|---|
| **hump.gamestate** | Manejo de pantallas y escenas |
| **bump.lua** (v0.2+) | Colisiones AABB |
| **anim8** (v0.2+) | Animaciones de sprites |
| **lurker** (v0.3+) | Hot reload |
| **lovebird** (v0.2+) | Debug en navegador |

## Licencia

MIT
