-- spec/my_module_spec.lua
local m = require "part1"

describe("solutions", function()
    it("get distance", function()
        assert.are.equal(1, m.get_distance(3, 4))
    end)
    it("test input", function()
        assert.are.equal(11, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(2264607, m.solution("./inputs/input.txt"))
    end)
end)
