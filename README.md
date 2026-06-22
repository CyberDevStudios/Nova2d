# Nova2D 🎮

> Framework base para Love2D que estandariza la estructura, gestión de dependencias y herramientas de desarrollo para juegos 2D en Lua.

## Estado del Proyecto

| Fase | Estado |
|---|---|
| **v0.1** — Base structure + states | ✅ Completado |
| **v0.2** — Dependency manager | ⏳ Por hacer |
| **v0.3** — Hot reload | ⏳ Por hacer |
| **v0.4** — Installer | ⏳ Por hacer |
| **v0.5** — Web documentation | ⏳ Por hacer |
| **v1.0** — Public release | ⏳ Por hacer |

## Requisitos

- [Love2D 11.x](https://love2d.org/) (Lua 5.1)
- `curl` (para el gestor de dependencias, v0.2+)

## Inicio Rápido

```bash
git clone <repo-url> mi-juego
cd mi-juego
love .
```

Verás el splash de Nova2D → Menú principal → Pantalla de juego lista para construir.

## Estructura del Proyecto

```
mi-juego/
├── main.lua              ← Punto de entrada (no modificar)
├── conf.lua              ← Configuración de ventana
├── nova2d.lua            ← Dependencias del proyecto
├── nova2d-lock.lua       ← Lockfile generado automáticamente
├── src/
│   ├── states/           ← Pantallas (splash, menu, game, pause, credits)
│   ├── entities/         ← Jugador, enemigos, objetos
│   ├── systems/          ← Física, audio, colisiones
│   └── utils/            ← Helpers
├── assets/
│   ├── images/           ← Sprites, texturas
│   ├── sounds/           ← Efectos de sonido
│   └── fonts/            ← Tipografías
└── libs/                 ← Dependencias externas
    └── hump/             ← Gamestate management
```

## Pantallas Disponibles (v0.1)

| Pantalla | Descripción |
|---|---|
| **Splash** | Logo de Nova2D, transición automática a los 3s |
| **Menú Principal** | Nuevo juego, Créditos, Salir — navegación por teclado y mouse |
| **Game** | Pantalla vacía lista para tu juego |
| **Pausa** | Overlay semi-transparente con Escape |
| **Créditos** | Librerías incluidas y sus autores |

## Convenciones

- `camelCase` para variables y funciones
- `PascalCase` para entidades y sistemas
- `local` siempre que sea posible
- Separación estricta entre `update()` (lógica) y `draw()` (presentación)
- Un archivo por entidad o sistema

## Librerías Incluidas

| Librería | Propósito |
|---|---|
| **hump.gamestate** | Manejo de pantallas y escenas |
| **bump.lua** (v0.2+) | Colisiones AABB |
| **anim8** (v0.2+) | Animaciones de sprites |
| **lurker** (v0.3+) | Hot reload |
| **lovebird** (v0.2+) | Debug en navegador |

## Licencia

MIT
