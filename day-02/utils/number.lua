local M = {}

function M.sum(arr)
    local sum = 0
    for _, v in ipairs(arr) do
        sum = sum + v
    end
    return sum
end

return M
