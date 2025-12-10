local m = require "part1"
local Operation = require "operation"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("parses input line", function()
        local input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"

        assert.are.equal("[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1)",
            string.format("%s", Operation.from_input_string(input)))
    end)
    it("can xor the state", function()
        local input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"

        ---@type Operation
        local operation = Operation.from_input_string(input)
        local input_button = { operation.buttons[5], operation.buttons[6] }
        operation:xor_array(input_button)

        assert.are.equal(".##.", string.format("%s", operation.current))
        assert.are.equal(true, operation:state_matches_target())
    end)
    it("can find min button presses for operation", function()
        local input = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"
        ---@type Operation
        local operation = Operation.from_input_string(input)
        assert.are.equal(2, operation:find_min_presses())
    end)
    it("test input", function()
        assert.are.equal(7, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(375, m.solution("./inputs/input.txt"))
    end)
end)
