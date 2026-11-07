-- luacheck configuration — run from the repository root:
--   luacheck src main.lua tests
std = "lua51+love"
max_line_length = 120

-- Unused `self` in state callbacks (draw/update style) is expected.
self = false

-- Vendored dependencies and generated/build output are not ours to lint.
exclude_files = {
    "libs/**",
    "openspec/**",
    ".git/**",
}

-- main.lua is the frozen entry point: it requires every state so a broken
-- module fails at boot. The locals are intentionally unused.
files["main.lua"] = {
    ignore = { "211" },
}

files["tests"] = {
    -- busted exposes these as globals inside spec files
    globals = {
        "describe", "context", "it", "pending", "before_each", "after_each",
        "setup", "teardown", "lazy_setup", "lazy_teardown", "insulate",
        "randomize", "assert", "spy", "mock", "stub", "match",
    },
}
