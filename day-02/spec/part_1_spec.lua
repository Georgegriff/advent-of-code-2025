local m = require "part1"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("parses-multiple-inputs", function()
        ---@type (Range)[]
        local ranges = {
            [1] = {
                input = "12-12",
                first = 12,
                last = 12
            },
            [2] = {
                input = "120-190",
                first = 120,
                last = 190
            }
        }
        assert.are.same(ranges, m.parse_input("12-12,120-190"))
    end)
    it("parses range input", function()
        assert.are.same({
            input = "12-12",
            first = 12,
            last = 12
        }, m.parse_range("12-12"))
    end)

    it("identifies invalid numbers", function()
        assert.are.equal(true, m.is_invalid_number(11))
        assert.are.equal(true, m.is_invalid_number(99))
        assert.are.equal(true, m.is_invalid_number(1188511885))
    end)
    it("finds invalid numbers in range", function()
        assert.are.same({ 11, 22 }, m.find_invalid_in_range(m.parse_range("11-22")))
        assert.are.same({ 1188511885 }, m.find_invalid_in_range(m.parse_range("1188511880-1188511890")))
    end)
    it("test input", function()
        assert.are.equal(1227775554, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(17077011375, m.solution("./inputs/input.txt"))
    end)
end)
