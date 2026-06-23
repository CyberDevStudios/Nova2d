-- Nova2D Gestor — Lockfile (nova2d-lock.lua) manager
-- Atomic read/write for dependency lock state

local lock = {}

function lock.read(project_root)
    local path = project_root .. "/nova2d-lock.lua"
    local f = io.open(path, "r")
    if not f then return {} end

    f:close()
    local ok, data = pcall(dofile, path)
    if not ok then
        return nil, "Failed to parse nova2d-lock.lua. Delete it and re-run install."
    end

    return data or {}
end

function lock.write(project_root, data)
    local path = project_root .. "/nova2d-lock.lua"
    local tmp_path = path .. ".tmp"

    local lines = {"-- Generated automatically. Do not edit.\nreturn {"}
    for name, entry in pairs(data) do
        table.insert(lines, string.format(
            '    ["%s"] = { version = "%s", installed = %d },',
            name, entry.version, entry.installed
        ))
    end
    table.insert(lines, "}")

    local f, err = io.open(tmp_path, "w")
    if not f then
        return false, "Cannot write lockfile: " .. tostring(err)
    end
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()

    local ok = os.rename(tmp_path, path)
    if not ok then
        os.remove(tmp_path)
        return false, "Failed to finalize lockfile. Disk may be full."
    end

    return true
end

function lock.compare(manifest, lockfile)
    local to_install = {}
    for name, dep in pairs(manifest.dependencies or {}) do
        local locked = lockfile[name]
        if not locked or locked.version ~= dep.version then
            table.insert(to_install, { name = name, dep = dep })
        end
    end
    return to_install
end

function lock.remove_entry(project_root, name, lockfile)
    lockfile[name] = nil
    return lock.write(project_root, lockfile)
end

return lock
