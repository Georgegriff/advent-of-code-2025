local M = {}

-- Only run main code if this file is executed directly (not when required by tests)
function M.should_run_main()
    if love then return false end
    -- Check the call stack to see if we're being required
    local level = 2
    while true do
        local info = debug.getinfo(level, "S")
        if not info then break end
        -- If we find a require call in the stack, we're being required
        if info.source and info.source:match("spec/") then
            return false
        end
        level = level + 1
        if level > 10 then break end
    end
    -- Check if this is the main chunk and not being required
    local info = debug.getinfo(2, "S")
    return info and info.what == "main"
end

return M
