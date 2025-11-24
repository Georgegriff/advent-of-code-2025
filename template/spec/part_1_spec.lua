local m = require "part1"

describe("solutions", function()
    it("test input", function()
        assert.are.equal(0, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(0, m.solution("./inputs/input.txt"))
    end)
end)
