return {
    name    = "Nova2D",
    version = "0.5.0",
    author  = "Cyber Dev Studio",

    dependencies = {
        ["bump.lua"] = {
            repo = "kikito/bump.lua",
            version = "v3.1.7",
            type = "single",
            file = "bump.lua"
        },
        ["anim8"] = {
            repo = "kikito/anim8",
            version = "v2.3.0",
            type = "multi"
        },
        ["hump"] = {
            repo = "vrld/hump",
            version = "master",
            type = "multi"
        },
        ["lurker"] = {
            repo = "rxi/lurker",
            version = "master",
            type = "multi"
        },
        ["lume"] = {
            repo = "rxi/lume",
            version = "v2.3.0",
            type = "single",
            file = "lume.lua"
        },
        ["lovebird"] = {
            repo = "rxi/lovebird",
            version = "master",
            type = "multi"
        },
    },
}
