# Nova2D — AI Agent Instructions

Este archivo define cómo los agentes de IA deben trabajar en este proyecto.

## Stack

- **Lenguaje**: Lua 5.1 (Love2D 11.x)
- **Framework**: Nova2D sobre Love2D
- **Gestión de estados**: hump.gamestate
- **Gestor de dependencias**: Nova2D propio (v0.2+)
- **Testing**: No hay test runner disponible (Lua puro)

## Convenciones de Código

- `camelCase` para variables y funciones
- `PascalCase` para entidades y sistemas
- `local` siempre, sin globales excepto `Gamestate`
- Separación estricta: `update(dt)` para lógica, `draw()` para render
- Un archivo por módulo, cada archivo retorna una tabla
- `main.lua` es frozen — no debe modificarse

## SDD (Spec-Driven Development)

Este proyecto usa SDD para cambios significativos. Los artefactos viven en `openspec/`.

### Ciclo SDD
1. `sdd-init` → inicializa contexto
2. `sdd-new` → propuesta de cambio
3. `sdd-spec` + `sdd-design` → especificación + diseño
4. `sdd-tasks` → desglose en tareas
5. `sdd-apply` → implementación
6. `sdd-verify` → verificación contra specs
7. `sdd-archive` → cierre del cambio

### Skills Relevantes

Los siguientes skills del sistema Gentle AI aplican a este proyecto:

| Skill | Cuándo usarlo |
|---|---|
| `sdd-init` | Inicializar SDD en el proyecto |
| `sdd-propose` | Crear propuestas de cambio |
| `sdd-spec` | Escribir especificaciones detalladas |
| `sdd-design` | Diseñar arquitectura técnica |
| `sdd-tasks` | Desglosar cambios en tareas |
| `sdd-apply` | Implementar tareas |
| `sdd-verify` | Verificar implementación |
| `sdd-archive` | Archivar cambios completados |
| `cognitive-doc-design` | Escribir documentación clara |
| `work-unit-commits` | Commits como unidades revisables |

## Fases del Proyecto

| Fase | Descripción | Estado |
|---|---|---|
| v0.1 | Base structure + 5 states | ✅ Completado |
| v0.2 | Dependency manager (gestor) | ⏳ Pendiente |
| v0.3 | Hot reload (lurker) | ⏳ Pendiente |
| v0.4 | Installer script (curl) | ⏳ Pendiente |
| v0.5 | Documentación web | ⏳ Pendiente |
| v1.0 | Lanzamiento público | ⏳ Pendiente |

## Engram

Este proyecto usa Engram para memoria persistente entre sesiones. Las decisiones arquitectónicas, bugs, y descubrimientos importantes se guardan automáticamente.

### Topic Keys

| Artifact | Topic Key |
|---|---|
| Init | `sdd-init/framework` |
| Testing | `sdd/framework/testing-capabilities` |
| Proposal | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply Progress | `sdd/{change-name}/apply-progress` |
| Verify Report | `sdd/{change-name}/verify-report` |
| Archive | `sdd/{change-name}/archive-report` |
