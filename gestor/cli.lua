-- Nova2D Gestor — CLI command dispatcher
-- Routes commands to their handlers

local manifest = require("manifest")
local lock = require("lock")
local util = require("util")

local cli = {}

function cli.dispatch(args)
    local cmd = args[1]
    local handlers = {
        install = function() return cmd_install(args) end,
        update  = function() return cmd_update(args) end,
        remove  = function() return cmd_remove(args) end,
        list    = function() return cmd_list(args) end,
    }

    local handler = handlers[cmd]
    if not handler then
        return false, "Unknown command: " .. cmd .. ". Valid commands: install, update, remove, list"
    end

    return handler()
end

function cmd_install(args)
    if not util.find_tool("curl") then
        return false, "curl not found. " .. util.tool_instructions("curl")
    end

    local root = util.get_project_root()
    local m, err = manifest.read(root)
    if not m then return false, err end

    local lf, lerr = lock.read(root)
    if not lf then return false, lerr end

    local to_install = lock.compare(m, lf)

    if #to_install == 0 then
        local count = 0
        for _ in pairs(m.dependencies) do count = count + 1 end
        print("> " .. count .. " dependencies up to date.")
        return true
    end

    -- Filter by specific name if provided
    if args[2] then
        local filtered = {}
        for _, item in ipairs(to_install) do
            if item.name == args[2] then
                table.insert(filtered, item)
                break
            end
        end
        if #filtered == 0 then
            -- Check if it exists in manifest at all
            if m.dependencies[args[2]] then
                print("> " .. args[2] .. " is already up to date.")
                return true
            end
            return false, "Dependency '" .. args[2] .. "' not found in nova2d.lua"
        end
        to_install = filtered
    end

    local libs_path = root .. "/libs"
    util.ensure_dir(libs_path)

    local download = require("download")

    for _, item in ipairs(to_install) do
        local ok, dlerr
        if item.dep.type == "single" then
            ok, dlerr = download.single_file(item.name, item.dep, libs_path)
        else
            if not util.find_tool("unzip") then
                print("[WARN] unzip not found. " .. util.tool_instructions("unzip"))
                print("[WARN] Skipping " .. item.name .. " (requires unzip for multi-file)")
                dlerr = "unzip not available"
            else
                ok, dlerr = download.multi_file(item.name, item.dep, libs_path)
            end
        end

        if ok then
            lf[item.name] = { version = item.dep.version, installed = os.time() }
            print("> " .. item.name .. " installed.")
        else
            print("[ERROR] " .. item.name .. ": " .. dlerr)
        end
    end

    local ok, werr = lock.write(root, lf)
    if not ok then
        return false, werr
    end

    local total = #to_install
    print("> " .. total .. " dependenc" .. (total == 1 and "y" or "ies") .. " processed.")
    return true
end

function cmd_update(args)
    if not util.find_tool("curl") then
        return false, "curl not found. " .. util.tool_instructions("curl")
    end

    local root = util.get_project_root()
    local m, err = manifest.read(root)
    if not m then return false, err end

    print("> Checking GitHub for updates...")

    local updated = false
    for name, dep in pairs(m.dependencies or {}) do
        local api_url = string.format(
            "https://api.github.com/repos/%s/releases/latest",
            dep.repo
        )

        local tmp_file = os.tmpname()
        local cmd = string.format(
            "curl -fsSL --connect-timeout 10 '%s' -o '%s' 2>/dev/null",
            api_url, tmp_file
        )
        local code = util.normalize_exit_code(os.execute(cmd))

        if code == 0 then
            local f = io.open(tmp_file, "r")
            if f then
                local content = f:read("*a")
                f:close()

                local latest = content:match('"tag_name"%s*:%s*"([^"]+)"')
                if latest and latest ~= dep.version then
                    print("> " .. name .. " updated: " .. dep.version .. " -> " .. latest)
                    dep.version = latest
                    updated = true
                end
            end
        else
            print("[WARN] " .. name .. ": could not check latest version (GitHub may be rate-limited). Skipping.")
        end

        os.remove(tmp_file)

        -- Polite delay to avoid rate limiting
        if next(m.dependencies, name) then
            os.execute("sleep 1 2>/dev/null || timeout /t 1 >nul 2>&1 || true")
        end
    end

    if not updated then
        print("> All dependencies are up to date.")
        return true
    end

    -- Rewrite nova2d.lua with updated versions
    local nova2d_path = root .. "/nova2d.lua"
    local lines = {
        "return {",
        '    name = "' .. (m.name or "my-game") .. '",',
        '    version = "' .. (m.version or "1.0.0") .. '",',
        '    author = "' .. (m.author or "") .. '",',
        "",
        "    dependencies = {",
    }

    for name, dep in pairs(m.dependencies) do
        if dep.type == "single" then
            table.insert(lines, string.format(
                '        ["%s"] = { repo = "%s", version = "%s", type = "single", file = "%s" },',
                name, dep.repo, dep.version, dep.file
            ))
        else
            table.insert(lines, string.format(
                '        ["%s"] = { repo = "%s", version = "%s", type = "multi" },',
                name, dep.repo, dep.version
            ))
        end
    end

    table.insert(lines, "    },")
    table.insert(lines, "}")

    local f, err = io.open(nova2d_path, "w")
    if not f then
        return false, "Cannot update nova2d.lua: " .. tostring(err)
    end
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()

    print("> nova2d.lua updated with new versions.")
    print("> Re-running install for updated dependencies...")

    -- Re-run install for all deps (versions may have changed)
    return cmd_install({"install"})
end

function cmd_remove(args)
    if not args[2] then
        return false, "Usage: love gestor/ remove <name>"
    end

    local name = args[2]
    local root = util.get_project_root()
    local lf, err = lock.read(root)
    if not lf then return false, err end

    if not lf[name] then
        return false, "Dependency '" .. name .. "' is not installed."
    end

    -- Remove from libs/
    local lib_path = root .. "/libs/" .. name
    if util.is_windows() then
        os.execute('rmdir /s /q "' .. lib_path .. '" 2>nul')
    else
        os.execute("rm -rf '" .. lib_path .. "'")
    end

    -- Remove from lockfile
    lf[name] = nil
    local ok, werr = lock.write(root, lf)
    if not ok then
        return false, werr
    end

    print("> " .. name .. " removed from libs/ and lockfile.")
    return true
end

function cmd_list(args)
    local root = util.get_project_root()
    local lf, err = lock.read(root)
    if not lf then return false, err end

    local count = 0
    for _ in pairs(lf) do count = count + 1 end

    if count == 0 then
        print("> No dependencies installed.")
        return true
    end

    print("> Installed dependencies:")
    for name, entry in pairs(lf) do
        local date = util.format_timestamp(entry.installed)
        print(string.format("    %-15s %-10s %s", name, entry.version, date))
    end

    return true
end

return cli
