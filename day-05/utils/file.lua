local M = {}

function M.read_file(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Cannot open file: " .. filename)
    end
    local content = file:read("*all")
    file:close()
    return content
end

function M.read_file_lines(filename, callback)
    local file = io.open(filename, "r")
    if not file then
        error("Cannot open file: " .. filename)
    end
    for line in file:lines() do
        local should_continue = callback(line)
        if type(should_continue) == "boolean" and should_continue == false then
            break
        end
    end
    file:close()
end

return M
