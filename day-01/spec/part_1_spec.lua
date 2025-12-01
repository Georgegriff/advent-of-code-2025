local m = require "part1"
-- pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("parses instruction", function()
        local instruction = m.parse_instruction("L68")
        assert.are.equal(instruction.direction, -1)
        assert.are.equal(instruction.amount, 68)
    end)
    it("follows instruction", function()
        assert.are.equal(82, m.follow_instruction(50, {
            direction = -1,
            amount = 68
        }))
        assert.are.equal(0, m.follow_instruction(52, {
            direction = 1,
            amount = 48
        }))
    end)
    it("follows instruction with wrap around", function()
        assert.are.equal(5, m.follow_instruction(0, {
            direction = 1,
            amount = 16
        }, 0, 10))
    end)
    it("test input", function()
        assert.are.equal(3, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(1158, m.solution("./inputs/input.txt"))
    end)
end)
