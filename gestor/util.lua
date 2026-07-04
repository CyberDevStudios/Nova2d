-- Nova2D Gestor — Utility module
-- OS detection, path resolution, tool checks

local util = {}

function util.get_os()
    return love.system.getOS()
end

function util.is_windows()
    return util.get_os() == "Windows"
end

function util.find_tool(name)
    if util.is_windows() then
        local r = os.execute("where " .. name .. " >nul 2>nul")
        if r == 0 then return true end
        r = os.execute("where " .. name .. ".exe >nul 2>nul")
        return r == 0
    else
        -- Try command -v first (works in most environments)
        local r = os.execute("command -v " .. name .. " >/dev/null 2>&1")
        if r == 0 then return true end

        -- Fallback: check common paths directly via io.open
        -- Love2D sandboxes (Snap/Flatpak) may restrict os.execute PATH
        local common_dirs = {"/usr/bin/", "/usr/local/bin/", "/bin/", "/snap/bin/", "/opt/homebrew/bin/"}
        for _, dir in ipairs(common_dirs) do
            local f = io.open(dir .. name)
            if f then f:close(); return true end
        end

        return false
    end
end

function util.tool_instructions(tool)
    local os = util.get_os()
    if tool == "curl" then
        if os == "Linux" then
            return "Install it: sudo apt install curl (Debian/Ubuntu), sudo pacman -S curl (Arch), sudo dnf install curl (Fedora)"
        elseif os == "OS X" then
            return "Install it: brew install curl"
        elseif os == "Windows" then
            return "Win10+ includes curl.exe. If missing: https://curl.se/windows/"
        end
    elseif tool == "unzip" then
        if os == "Linux" then
            return "Install it: sudo apt install unzip (Debian/Ubuntu), sudo pacman -S unzip (Arch)"
        elseif os == "OS X" then
            return "Install it: brew install unzip"
        elseif os == "Windows" then
            return "Install from: https://infozip.sourceforge.net/ or use: choco install unzip"
        end
    end
    return "Install " .. tool .. " for your OS."
end

function util.get_project_root()
    local source = love.filesystem.getSource()
    -- Strip trailing slashes so the regex can strip the last path component
    source = source:gsub("/+$", ""):gsub("\\+$", "")
    return source:match("^(.+)/[^/]+$") or source
end

function util.ensure_dir(path)
    if util.is_windows() then
        os.execute('if not exist "' .. path .. '" mkdir "' .. path .. '"')
    else
        os.execute("mkdir -p '" .. path .. "'")
    end
end

function util.format_timestamp(ts)
    return os.date("%Y-%m-%d", ts)
end

function util.normalize_exit_code(code)
    if not code then return -1 end
    if code == 0 then return 0 end
    if code < 0 then return code end
    if code % 256 == 0 then
        return math.floor(code / 256)
    end
    return code
end

return util
