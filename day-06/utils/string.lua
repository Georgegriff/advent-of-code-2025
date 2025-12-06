local M = {}
function M.split(str, sep, mapper)
    local t = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        if type(mapper) == "function" then
            table.insert(t, mapper(part))
        else
            table.insert(t, part)
        end
    end
    return t
end

function M.chars(str, mapper)
    local chars = {}
    for c in str:gmatch(".") do
        if type(mapper) == "function" then
            table.insert(chars, mapper(c))
        else
            table.insert(chars, c)
        end
    end
    return chars
end

return M
