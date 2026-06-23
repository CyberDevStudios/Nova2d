-- Nova2D Gestor — Download module
-- Handles single-file and multi-file downloads via curl

local util = require("util")

local download = {}

local CURL_FLAGS = "-fsSL --connect-timeout 10 --max-time 30"
local CURL_FLAGS_ZIP = "-fsSL --connect-timeout 10 --max-time 60"

function download.single_file(name, dep, libs_path)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s",
        dep.repo, dep.version, dep.file
    )
    local dest = libs_path .. "/" .. name

    util.ensure_dir(dest)

    local filepath = dest .. "/" .. dep.file
    local cmd = string.format("curl %s '%s' -o '%s'", CURL_FLAGS, url, filepath)
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

    -- Download zip
    local cmd = string.format("curl %s '%s' -o '%s'", CURL_FLAGS_ZIP, url, tmp_zip)
    local ok, msg = run_curl(cmd, name)
    if not ok then
        os.remove(tmp_zip)
        return false, msg
    end

    -- Extract
    local extract_cmd = string.format("unzip -o '%s' -d '%s' 2>/dev/null", tmp_zip, tmp_dir)
    local extract_ok = os.execute(extract_cmd)
    if extract_ok ~= 0 then
        os.remove(tmp_zip)
        os.execute("rm -rf '" .. tmp_dir .. "'")
        return false, "Failed to extract archive. unzip may be missing or archive is corrupt."
    end

    -- Get extracted directory (GitHub zip creates a single directory)
    local handle = io.popen("ls -1 '" .. tmp_dir .. "' 2>/dev/null")
    local extracted = handle:read("*l")
    handle:close()

    if not extracted or extracted == "" then
        os.remove(tmp_zip)
        os.execute("rm -rf '" .. tmp_dir .. "'")
        return false, "Archive is empty or invalid."
    end

    -- Move to final destination
    local dest = libs_path .. "/" .. name
    util.ensure_dir(dest)

    if util.is_windows() then
        os.execute(string.format(
            'xcopy /e /i /q "%s\\%s\\*" "%s\\" 2>nul',
            tmp_dir, extracted, dest
        ))
    else
        os.execute(string.format("cp -r '%s/%s/'* '%s/' 2>/dev/null", tmp_dir, extracted, dest))
    end

    -- Cleanup
    os.remove(tmp_zip)
    os.execute("rm -rf '" .. tmp_dir .. "'")

    return true
}

function run_curl(cmd, dep_name)
    print("> " .. dep_name .. " -> downloading...")
    local code = util.normalize_exit_code(os.execute(cmd))
    if code ~= 0 then
        return false, curl_error_message(code)
    end
    return true
end

function curl_error_message(code)
    local messages = {
        [6]  = "Could not resolve host. Check internet connection.",
        [7]  = "Connection refused by server.",
        [18] = "Download incomplete. Retry.",
        [22] = "Not found. Check repo or version in nova2d.lua.",
        [28] = "Connection timed out after 30s.",
        [52] = "Server returned empty response.",
        [56] = "Network failure. Check connection.",
        [60] = "SSL certificate error. Update CA certs.",
    }
    return messages[code] or "curl failed with exit code " .. code
end

return download
