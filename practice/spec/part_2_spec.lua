-- spec/my_module_spec.lua
local m = require "part2"

describe("solutions", function()
    it("test input", function()
        assert.are.equal(31, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(19457120, m.solution("./inputs/input.txt"))
    end)
end)
