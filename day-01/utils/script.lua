local M = {}

function M.is_main()
    local info = debug.getinfo(2, "S")
    return info and info.what == "main"
end

return M

