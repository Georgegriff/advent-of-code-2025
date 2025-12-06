local m = require "part2"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("test input", function()
        assert.are.equal(3263827, m.solution("./inputs/test.txt"))
    end)
    -- broken...
    -- it("input", function()
    --     assert.are.equal(10194584711842, m.solution("./inputs/input.txt"))
    -- end)
end)
