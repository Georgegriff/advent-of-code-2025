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
        callback(line)
    end
    file:close()
end

return M
