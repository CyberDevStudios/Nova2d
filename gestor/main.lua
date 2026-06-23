local cli = require("cli")

function love.load(args)
    if #args == 0 then
        print("Usage: love gestor/ [install|update|remove|list] [name]")
        love.event.quit(1)
        return
    end

    local ok, err = cli.dispatch(args)
    if not ok then
        print("[ERROR] " .. err)
        love.event.quit(1)
    else
        love.event.quit(0)
    end
end
