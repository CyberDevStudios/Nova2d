# Nova2D Docs — Web de Documentación en React

> Especificación para construir el sitio de documentación oficial de Nova2D.
> Una SPA en React con estética de terminal modo blanco, navegación por botones, animaciones, y ejemplos de código con explicación.

---

## Concepto Visual

**Tema**: Terminal en modo blanco.
- Fondo: `#f8f9fa` (blanco roto)
- Texto: `#1a1a2e` (casi negro)
- Acentos: `#00b894` (verde terminal) + `#0984e3` (azul enlace)
- Tipografía: monoespaciada (`Fira Code`, `JetBrains Mono`, o `ui-monospace`)
- Bordes y separadores finos, como una terminal limpia

**Interacción**: Todo en una sola página. El contenido cambia al hacer clic en botones de navegación — no hay scroll infinito ni sections apiladas. Cada "pantalla" es una vista completa que reemplaza a la anterior con animación.

---

## Estructura de la Página

### Layout General

```
┌─────────────────────────────────────────────┐
│  ╭──────╮  Nova2D Docs                      │
│  │  >_  │  v0.1                              │
│  ╰──────╯                                    │
├─────────────────────────────────────────────┤
│                                              │
│  [ Instalación ]  [ Estados ]  [ API ]       │
│  [ Guía Rápida ]  [ Entities]  [ CLI ]       │
│                                              │
├─────────────────────────────────────────────┤
│                                              │
│           ← CONTENIDO PRINCIPAL →           │
│           (cambia según el botón)            │
│                                              │
├─────────────────────────────────────────────┤
│  Nova2D — Hecho para Love2D, pensado para   │
│  durar.  MIT License                         │
└─────────────────────────────────────────────┘
```

### Componentes React

| Componente | Rol |
|---|---|
| `App` | Layout raíz, estado de ruta activa |
| `TerminalHeader` | Logo `>_` + nombre del proyecto + versión |
| `NavBar` | Botones de navegación horizontal |
| `ContentView` | Renderiza la vista activa con animación |
| `InstallView` | Comando curl + instrucciones de instalación |
| `StatesView` | Diagrama de estados con código |
| `ApiView` | Referencia de funciones del framework |
| `QuickStartView` | Tutorial paso a paso en 5 minutos |
| `EntitiesView` | Guía de entidades + ejemplos |
| `CliView` | Comandos del gestor de dependencias |
| `CodeBlock` | Fragmento de código con explicación al lado |
| `Footer` | Licencia + link a GitHub |

---

## Navegación

### Botones del NavBar

| Botón | Vista | Descripción |
|---|---|---|
| `Instalación` | `InstallView` | Comando curl + requisitos |
| `Guía Rápida` | `QuickStartView` | Tutorial 5 min |
| `Estados` | `StatesView` | Diagrama + código de cada state |
| `Entities` | `EntitiesView` | Cómo crear entidades |
| `API` | `ApiView` | Referencia de módulos |
| `CLI` | `CliView` | Comandos del gestor |

### Comportamiento

- Click en un botón → cambia `ContentView` con animación
- El botón activo se resalta con un cursor de terminal parpadeante (`▌`) o un subrayado verde
- Transiciones: `fade + slide` (300ms ease-in-out)
- No hay scroll horizontal. El contenido es vertical si es necesario (ej: lista de APIs)
- URL update via hash routing: `#instalacion`, `#estados`, etc.

---

## Vistas Detalladas

### 1. InstallView — Instalación

```
╔═══════════════════════════════════════════╗
║  $ curl -fsSL https://nova2d.dev/sh      ║
╚═══════════════════════════════════════════╝
```

```
  ❯ Copia el comando de arriba y pégalo en tu terminal.
  ❯ Necesitás Love2D 11.x instalado.
  ❯ El script detecta tu SO, descarga el framework
    y te deja el proyecto listo.
```

Botón animado de "Copiar al portapapeles" que muestra ✓ al copiar.

Luego muestra los requisitos detallados en tabla:

| Requisito | Versión | Cómo verificarlo |
|---|---|---|
| Love2D | 11.x | `love --version` |
| curl | cualquier | `curl --version` |
| Lua | 5.1 (incluida en Love2D) | — |

### 2. QuickStartView — Guía Rápida

5 pasos enumerados, cada uno con su `CodeBlock`:

```
Paso 1: Crear un proyecto
┌──────────────────────────────────────────────┐
│  $ love .                                    │
└──────────────────────────────────────────────┘
  ❯ Esto arranca el splash de Nova2D.
    Si ves el logo y el menú, está funcionando.

Paso 2: Navegar el menú
  ❯ Usá Up/Down o click para seleccionar.
  ❯ Enter para confirmar.

Paso 3: Crear una entidad
┌──────────────────────────────────────────────┐
│  local Player = {}                           │
│                                              │
│  function Player:enter()                     │
│    self.x = 400                              │
│    self.y = 300                              │
│  end                                         │
│                                              │
│  function Player:update(dt)                  │
│    self.x = self.x + 100 * dt                │
│  end                                         │
│                                              │
│  function Player:draw()                      │
│    love.graphics.circle("fill",              │
│      self.x, self.y, 20)                     │
│  end                                         │
│                                              │
│  return Player                               │
└──────────────────────────────────────────────┘
  ❯ Cada entidad es un módulo Lua que retorna
    una tabla con update() y draw().

Paso 4: Agregarlo al juego
  ...

Paso 5: Usar hot reload (con lurker)
  ...
```

Cada `CodeBlock` tiene el código a la izquierda y la explicación a la derecha, separados por una línea vertical tenue.

### 3. StatesView — Diagrama de Estados

Diagrama de transiciones renderizado con SVG animado:

```
         [Splash] ──3s──→ [Menu] ──New Game──→ [Game]
            ↑                │                     │
         any key         Credits               Esc │
            ↑                ↓                     ↓
            └───────────────── [Credits] ←─── [Pause]
                                    Esc/click
```

Cada estado es clickeable → muestra el código de ese `src/states/*.lua` en un `CodeBlock`.

Las flechas tienen animación de "flujo" (dash-offset animado).

### 4. ApiView — Referencia de Módulos

Tabla expandible por módulo:

| Módulo | Archivo | Propósito |
|---|---|---|
| `main.lua` | `main.lua` | Entry point (no tocar) |
| `conf.lua` | `conf.lua` | Configuración de ventana |
| `splash` | `src/states/splash.lua` | Pantalla de inicio |
| `menu` | `src/states/menu.lua` | Menú principal |
| ... | ... | ... |

Click en una fila → expande mostrando la firma de funciones y un ejemplo de uso.

### 5. EntitiesView — Guía de Entidades

Template para crear entidades:

```lua
-- Template para una entidad Nova2D
local MiEntidad = {}

function MiEntidad:enter(parent, args)
  self.x = 0
  self.y = 0
  self.speed = 200
end

function MiEntidad:update(dt)
  -- lógica acá
end

function MiEntidad:draw()
  -- render acá
end

return MiEntidad
```

Explicación al lado de cada sección del template.

### 6. CliView — Referencia de Comandos

| Comando | Descripción |
|---|---|
| `love gestor install` | Instala dependencias |
| `love gestor install bump.lua` | Instala una específica |
| `love gestor update` | Actualiza todo |
| `love gestor remove anim8` | Elimina una lib |
| `love gestor list` | Lista instaladas |

Cada comando es clickeable → muestra un ejemplo de output esperado.

---

## Animaciones

| Elemento | Animación | Detalle |
|---|---|---|
| Cambio de vista | `fade + slide` | 300ms, ease-in-out. La vista vieja se desvanece mientras la nueva entra desde abajo |
| Botón hover | `background-color` + `scale(1.02)` | 200ms, transición suave |
| Botón activo | cursor `▌` parpadeante | CSS keyframes, 1s ciclo |
| Código | `highlight` en sintaxis | Prism.js o highlight.js con tema terminal |
| Flechas de estado | dash-offset animado | SVG `stroke-dashoffset`, 2s ciclo |
| Copiar botón | checkmark aparece | 300ms, icono cambia a ✓ y vuelve |
| Header `>_` | parpadeo sutil | opacity oscila cada 3s |

---

## CodeBlock — Componente Clave

```
┌───────────────────────┬──────────────────────┐
│  Código Lua           │  Explicación          │
│                       │                       │
│  local function       │  ❯ Cada state es un   │
│    hello()            │    módulo que retorna  │
│    print("hola")      │    una tabla.          │
│  end                  │                       │
│                       │  ❯ Los callbacks son   │
│                       │    enter, update, draw │
└───────────────────────┴──────────────────────┘
```

- Código: `font-family: monospace`, `background: #1a1a2e`, `color: #00ff88`
- Explicación: mismo fondo que el sitio, ícono `❯` como bullet
- Línea vertical separadora tenue
- El código se copia con un botón en la esquina superior derecha

---

## Routing

Usar hash-based routing (no React Router necesario, es una sola página con ~6 vistas):

```js
// Estado de la app
const [view, setView] = useState('install')

// Hash sync (opcional)
useEffect(() => {
  const hash = window.location.hash.slice(1) || 'install'
  setView(hash)
}, [])

// Render condicional
const views = {
  install: <InstallView />,
  quickstart: <QuickStartView />,
  states: <StatesView />,
  entities: <EntitiesView />,
  api: <ApiView />,
  cli: <CliView />,
}
```

---

## Stack Técnico Sugerido

| Capa | Tecnología | Razón |
|---|---|---|
| Framework | React 18+ (Vite) | Rápido, moderno |
| Animaciones | CSS transitions + keyframes | Sin dependencias extra |
| Syntax highlight | Prism.js (tema terminal) | Liviano, Lua support |
| Routing | Hash-based manual | Sin React Router, es SPA chica |
| SVG diagramas | React inline SVG | Control total de animaciones |
| Despliegue | GitHub Pages o Vercel | Gratuito, simple |

---

## Archivos del Proyecto

```
nova2d-docs/
├── index.html
├── src/
│   ├── main.jsx
│   ├── App.jsx
│   ├── components/
│   │   ├── TerminalHeader.jsx
│   │   ├── NavBar.jsx
│   │   ├── ContentView.jsx
│   │   ├── CodeBlock.jsx
│   │   └── Footer.jsx
│   ├── views/
│   │   ├── InstallView.jsx
│   │   ├── QuickStartView.jsx
│   │   ├── StatesView.jsx
│   │   ├── EntitiesView.jsx
│   │   ├── ApiView.jsx
│   │   └── CliView.jsx
│   └── styles/
│       └── terminal.css
├── vite.config.js
└── package.json
```

---

## Próximos Pasos para Implementar

1. Scaffold con Vite: `npm create vite@latest nova2d-docs -- --template react`
2. Crear `terminal.css` con las variables de color y animaciones
3. Implementar `App.jsx` con estado de vista + render condicional
4. Crear `NavBar` con botones y estado activo
5. Implementar cada vista empezando por `InstallView`
6. Agregar `CodeBlock` con Prism.js
7. Agregar animaciones CSS
8. Desplegar a GitHub Pages o Vercel

---

*Esta página es una especificación de diseño. Para construirla, seguí los pasos de implementación arriba.*
