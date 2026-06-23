-- Nova2D Gestor — Manifest (nova2d.lua) reader
-- Reads and validates the project dependency manifest

local util = require("util")

local manifest = {}

function manifest.read(project_root)
    local path = project_root .. "/nova2d.lua"
    local f, err = io.open(path, "r")
    if not f then
        return nil, "nova2d.lua not found at " .. path .. ". Create one before running install."
    end
    f:close()

    local ok, result = pcall(dofile, path)
    if not ok then
        return nil, "Failed to parse nova2d.lua: " .. tostring(result)
    end

    if type(result) ~= "table" then
        return nil, "nova2d.lua must return a table"
    end

    if type(result.dependencies) ~= "table" then
        result.dependencies = {}
    end

    for name, dep in pairs(result.dependencies) do
        if type(dep) ~= "table" then
            return nil, "Dependency '" .. name .. "' must be a table"
        end
        if not dep.repo then
            return nil, "Dependency '" .. name .. "' is missing required field 'repo'"
        end
        if not dep.version then
            return nil, "Dependency '" .. name .. "' is missing required field 'version'"
        end
        if not dep.type then
            dep.type = "multi"
        end
        if dep.type == "single" and not dep.file then
            return nil, "Dependency '" .. name .. "' is type 'single' but missing 'file' field"
        end
        if dep.type ~= "single" and dep.type ~= "multi" then
            return nil, "Dependency '" .. name .. "' has invalid type '" .. dep.type .. "'. Use 'single' or 'multi'."
        end
    end

    return result
end

return manifest
