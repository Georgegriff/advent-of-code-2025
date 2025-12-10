local m = require "part1"
local Operation = require "operation"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("parses input line", function()
        local input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"

        assert.are.equal("[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1)",
            string.format("%s", Operation.from_input_string(input)))
    end)
    it("test input", function()
        assert.are.equal(0, m.solution("./inputs/test.txt"))
    end)
    -- it("input", function()
    --     assert.are.equal(0, m.solution("./inputs/input.txt"))
    -- end)
end)
