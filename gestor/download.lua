-- Nova2D Gestor — Download module
-- Handles single-file and multi-file downloads via curl

local util = require("util")

local download = {}
local is_windows = util.is_windows()

local CURL_FLAGS = "-fsSL --connect-timeout 10 --max-time 30"
local CURL_FLAGS_ZIP = "-fsSL --connect-timeout 10 --max-time 60"

local function shell_quote(value)
    if is_windows then
        return '"' .. value:gsub('"', '\\"') .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function shell_remove_dir(path)
    if is_windows then
        return string.format("rmdir /s /q %s", shell_quote(path))
    end
    return string.format("rm -rf %s", shell_quote(path))
end

local function shell_list_dir(path)
    if is_windows then
        return string.format("dir /b %s", shell_quote(path))
    end
    return string.format("ls -1 %s 2>/dev/null", shell_quote(path))
end

function download.single_file(name, dep, libs_path)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s",
        dep.repo, dep.version, dep.file
    )
    local dest = libs_path .. "/" .. name

    util.ensure_dir(dest)

    local filepath = dest .. "/" .. dep.file
    local cmd = string.format("curl %s %s -o %s", CURL_FLAGS, shell_quote(url), shell_quote(filepath))
    local ok, msg = run_curl(cmd, name)
    if not ok then return false, msg end

    -- Verify file is not empty
    local f = io.open(filepath, "r")
    if f then
        local size = f:seek("end")
        f:close()
        if size == 0 then
            os.remove(filepath)
            return false, "Downloaded file is empty. Check repo or version."
        end
    end

    return true
end

function download.multi_file(name, dep, libs_path)
    local url = string.format(
        "https://api.github.com/repos/%s/zipball/%s",
        dep.repo, dep.version
    )

    local tmp_zip = os.tmpname() .. ".zip"
    local tmp_dir = os.tmpname()
    os.remove(tmp_dir)          -- os.tmpname() puede crear un archivo; lo borramos
    util.ensure_dir(tmp_dir)

    -- Download zip
    local cmd = string.format("curl %s %s -o %s", CURL_FLAGS_ZIP, shell_quote(url), shell_quote(tmp_zip))
    local ok, msg = run_curl(cmd, name)
    if not ok then
        os.remove(tmp_zip)
        return false, msg
    end

    -- Extract with io.popen (same approach as run_curl for sandbox compat)
    local extract_cmd = string.format("unzip -o %s -d %s 2>&1; echo NOVA2D_EXIT:$?", shell_quote(tmp_zip), shell_quote(tmp_dir))
    local handle = io.popen(extract_cmd)
    if not handle then
        os.remove(tmp_zip)
        os.execute(shell_remove_dir(tmp_dir))
        return false, "No se pudo lanzar unzip (io.popen falló)."
    end
    local extract_output = handle:read("*a")
    handle:close()
    local extract_code = tonumber(extract_output:match("NOVA2D_EXIT:(%-?%d+)"))
    if not extract_code then
        os.remove(tmp_zip)
        os.execute(shell_remove_dir(tmp_dir))
        return false, "No se pudo determinar el código de salida de unzip."
    end
    -- unzip exit codes: 0 = success, 1 = warning (files extracted), 2+ = error
    if extract_code ~= 0 and extract_code ~= 1 then
        os.remove(tmp_zip)
        os.execute(shell_remove_dir(tmp_dir))
        return false, "Failed to extract archive. unzip may be missing or archive is corrupt."
    end

    -- Get extracted directory (GitHub zip creates a single directory)
    local handle = io.popen(shell_list_dir(tmp_dir))
    local extracted = handle:read("*l")
    handle:close()

    if not extracted or extracted == "" then
        os.remove(tmp_zip)
        os.execute(shell_remove_dir(tmp_dir))
        return false, "Archive is empty or invalid."
    end

    -- Move to final destination
    local dest = libs_path .. "/" .. name
    util.ensure_dir(dest)

    if is_windows then
        os.execute(string.format(
            'xcopy /e /i /q "%s\\%s\\*" "%s\\" 2>nul',
            tmp_dir, extracted, dest
        ))
    else
        os.execute(string.format("cp -r %s/* %s/ 2>/dev/null", shell_quote(tmp_dir .. "/" .. extracted), shell_quote(dest)))
    end

    -- Cleanup
    os.remove(tmp_zip)
    os.execute(shell_remove_dir(tmp_dir))

    return true
end

function run_curl(cmd, dep_name)
    print("> " .. dep_name .. " -> downloading...")

    -- io.popen captura salida real + código de salida vía el shell,
    -- evitando depender del valor de retorno de os.execute() que puede
    -- devolver nil en entornos con sandbox (Snap/Flatpak).
    local handle = io.popen(cmd .. " 2>&1; echo NOVA2D_EXIT:$?")
    if not handle then
        return false, "No se pudo lanzar el subproceso (io.popen falló). "
            .. "Esto suele pasar cuando 'love' corre en un sandbox "
            .. "(Snap/Flatpak) que restringe la ejecución de comandos "
            .. "externos."
    end
    local output = handle:read("*a")
    handle:close()

    local code = tonumber(output:match("NOVA2D_EXIT:(%-?%d+)"))
    if not code then
        return false, "No se pudo determinar el código de salida de curl."
    end
    if code == 0 then return true end

    local messages = {
        [6]  = "No se pudo resolver el host (DNS)",
        [7]  = "No se pudo conectar al servidor",
        [22] = "Error HTTP (404/403) — revisa repo/version/file en nova2d.lua",
        [28] = "Tiempo de espera agotado",
        [35] = "Error de conexión SSL",
    }
    local detail = messages[code] or "curl falló con código " .. tostring(code)

    -- Limpiar el marcador de la salida para el diagnóstico
    local clean_output = output:gsub("NOVA2D_EXIT:.*\n?", "")
    return false, string.format(
        "%s\n  Comando: %s\n  Salida: %s",
        detail, cmd, clean_output
    )
end

return download