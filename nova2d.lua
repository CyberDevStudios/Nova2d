return {
    name    = "Nova2D",
    version = "0.5.0",
    author  = "Nova2D Contributors",

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
        ["lurker"] = {
            repo = "rxi/lurker",
            version = "main",
            type = "multi"
        },
        ["lovebird"] = {
            repo = "rxi/lovebird",
            version = "main",
            type = "multi"
        },
    },
}
