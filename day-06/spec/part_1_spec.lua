local m = require "part1"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("run calculation", function()
        assert.are.equal(33210, m.run_calculation({
            numbers = { 123, 45, 6 },
            operator = "*"
        }))
        assert.are.equal(490, m.run_calculation({
            numbers = { 328, 64, 98 },
            operator = "+"
        }))
    end)
    it("test input", function()
        assert.are.equal(4277556, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(0, m.solution("./inputs/input.txt"))
    end)
end)
