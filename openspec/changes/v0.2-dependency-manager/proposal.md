# Proposal — v0.2 Dependency Manager ("Gestor")

**Change**: v0.2-dependency-manager
**Project**: Nova2D (Lua/Love2D framework)

---

## Intent

Construir el gestor de dependencias de Nova2D. Una herramienta CLI separada del juego que lee `nova2d.lua`, descarga librerías desde GitHub, las instala en `libs/`, y mantiene un lockfile con versiones exactas.

---

## Scope

### IN

| Elemento | Descripción |
|---|---|
| `gestor/` directory | Entrada headless separada, `love gestor/ install` |
| 5 comandos CLI | install, install [lib], update, remove [lib], list |
| Downloader | curl para single-file y multi-file (zip) |
| Lockfile | `nova2d-lock.lua` con versiones y timestamp UNIX |
| Tool detection | curl + unzip, si falta imprime instrucciones y corta |
| `nova2d.lua` format | Con tipo (single/multi) para que el gestor sepa cómo bajar |

### OUT

| Elemento | Razón |
|---|---|
| Modificar `main.lua` | Frozen contract, no se toca |
| Auto-descargar curl/unzip | Mala práctica, solo avisar |
| Tests automatizados | No hay test runner para Lua/Love2D |
| Package registry remoto | v0.2 solo lee `nova2d.lua` local |

---

## User Journeys

### Instalar dependencias por primera vez
```bash
$ love gestor/ install
  > Leyendo nova2d.lua...
  > bump.lua 3.1.7 -> descargando...
  > anim8 2.3.0 -> descargando...
  > hump main -> descargando...
  > 3 dependencias instaladas en 2.3s
```

### Instalar una específica
```bash
$ love gestor/ install anim8
  > anim8 2.3.0 -> descargando...
  > Dependencia instalada
```

### Actualizar todo
```bash
$ love gestor/ update
  > Consultando GitHub...
  > bump.lua 3.1.7 -> 3.2.0 (actualizado)
  > anim8 2.3.0 -> 2.4.1 (actualizado)
  > nova2d.lua actualizado con nuevas versiones
```

### Eliminar una dependencia
```bash
$ love gestor/ remove anim8
  > anim8 eliminado de libs/
  > nova2d-lock.lua actualizado
```

### Listar instaladas
```bash
$ love gestor/ list
  > bump.lua 3.1.7 (instalado 2026-06-22)
  > hump main (instalado 2026-06-22)
```

---

## Architecture

```
gestor/
├── main.lua           -- Entry point
├── conf.lua            -- Headless config
├── cli.lua             -- Arg parser + dispatch
├── manifest.lua        -- Read + validate nova2d.lua
├── download.lua        -- Curl + unzip logic
├── lock.lua            -- Read + write nova2d-lock.lua
└── util.lua            -- OS detection, path helpers
```

### Flow: `love gestor/ install`
```
love gestor/ install
    ↓
conf.lua (headless, no window)
    ↓
main.lua → cli.parse(arg) → "install"
    ↓
tool.check("curl")     ← si falta → print instructions + exit
    ↓
manifest.read("../nova2d.lua")
    ↓
lock.read("../nova2d-lock.lua")
    ↓
FOR EACH dependency:
  IF already installed AND same version → SKIP
  IF different version or missing → download
    ├── single-file: curl -fsSL raw URL -o libs/X
    └── multi-file: curl -fsSL zip URL -o /tmp/X.zip
                    unzip -o X.zip -d libs/X/
                    Remove temp zip
    ↓
lock.write("../nova2d-lock.lua")  ← atomic write
    ↓
print summary
```

---

## nova2d.lua Format

```lua
return {
    name    = "mi-juego",
    version = "1.0.0",
    author  = "Tu Nombre",

    dependencies = {
        ["bump.lua"] = {
            repo = "kikito/bump.lua",
            version = "3.1.7",
            type = "single",
            file = "bump.lua"
        },
        ["anim8"] = {
            repo = "kikito/anim8",
            version = "2.3.0",
            type = "multi"
        },
        ["hump"] = {
            repo = "vrld/hump",
            version = "main",
            type = "multi"
        },
    }
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `repo` | string | yes | GitHub "user/repo" |
| `version` | string | yes | Tag, branch, or commit |
| `type` | string | yes | `"single"` or `"multi"` |
| `file` | string | only if single | Nombre del archivo raw |

---

## nova2d-lock.lua Format

```lua
-- Generated automatically. Do not edit.
return {
    ["bump.lua"] = {
        version = "3.1.7",
        installed = 1750617600
    },
    ["anim8"] = {
        version = "2.3.0",
        installed = 1750617600
    },
}
```

`installed` es timestamp UNIX (`os.time()`).

---

## Download URLs

### Single-file
```
https://raw.githubusercontent.com/{repo}/{version}/{file}
Ej: https://raw.githubusercontent.com/kikito/bump.lua/3.1.7/bump.lua
```

### Multi-file (ZIP)
```
https://api.github.com/repos/{repo}/zipball/{version}
Ej: https://api.github.com/repos/vrld/hump/zipball/main
```

---

## Tool Detection

### curl
```lua
-- Linux/macOS: "curl"
-- Windows: "curl.exe" (Win10+), "curl" (some envs)
-- Si no se encuentra → OS-specific message + exit
```

### unzip
```lua
-- Solo necesario para type="multi"
-- Linux/macOS: built-in
-- Windows: no viene → instructions to install or use PowerShell
-- Si no se encuentra → OS-specific message + exit
```

### Mensajes de error
```
Windows:
  "curl.exe no encontrado.
   Win10+ deberia traerlo. Si no funciona:
   > https://curl.se/windows/"

Linux:
  "curl no encontrado. Instalalo:
   > sudo apt install curl    (Debian/Ubuntu)
   > sudo pacman -S curl      (Arch)
   > sudo dnf install curl    (Fedora)"

macOS:
  "curl no encontrado. Instalalo:
   > brew install curl"
```

---

## Edge Cases

| Caso | Manejo |
|---|---|
| Sin internet | curl timeout → "No se pudo conectar. Verifica tu conexion." |
| 404 en GitHub | curl code 22 → "repositorio o version no encontrado" |
| Error SSL | curl code 60 → "Error SSL. Si es necesario: curl -k (inseguro)" |
| Descarga parcial | curl code 18 → borrar archivo parcial, reintentar |
| Archivo vacío | check size = 0 → borrar y avisar |
| Sin permisos | `io.open()` falla → "No se puede escribir en libs/" |
| Lockfile corrupto | Atomic write: temp + os.rename() |
| `update` cambios en nova2d.lua | Siempre re-evalúa: compara lock vs manifest, reinstala si diff |
| `update` sin internet | Fallo en primera consulta → "No se pudo consultar GitHub" |

---

## Risks

| Riesgo | Impacto | Mitigacion |
|---|---|---|
| Windows sin curl | Alto | Detectar, avisar claro |
| GitHub rate limiting | Medio | No hacer requests innecesarias (skip si ya instalado) |
| Cambios breaking en libs | Medio | Lockfile congela versiones, user decide update |
| Multi-file extract mal | Medio | Verificar que el directorio destino existe antes de copiar |

---

## Dependencies

- **curl**: única dependencia externa del gestor
- **unzip**: solo para librerías multi-archivo
- **Love2D 11.x**: runtime para ejecutar el gestor en modo headless

---

## Impact Analysis

- `nova2d.lua`: pasa de stub vacío a tener dependencias reales
- `nova2d-lock.lua`: pasa de stub a ser generado automáticamente
- `libs/`: recibe las librerías descargadas
- `main.lua`: SIN CAMBIOS (frozen contract)
- `conf.lua`: SIN CAMBIOS
- `.gitignore`: actualizar para excluir libs/ y zip temporales

---

## Complexity

**Media-alta**. 5 comandos, download con curl + unzip, lockfile atómico, detección de OS. Es el módulo más complejo del framework hasta ahora.

**Líneas estimadas**: ~500-600 Lua.
