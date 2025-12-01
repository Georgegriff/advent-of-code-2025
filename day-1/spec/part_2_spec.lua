local m = require "part2"
describe("solutions", function()
    it("follows instruction L68 from 50", function()
        assert.are.equal(82, m.follow_instruction(50, {
            direction = -1,
            amount = 68
        }))
    end)
    it("follows instruction L30 from 82", function()
        assert.are.equal(52, m.follow_instruction(82, {
            direction = -1,
            amount = 30
        }))
    end)
    it("follows instruction R48 from 52", function()
        assert.are.equal(0, m.follow_instruction(52, {
            direction = 1,
            amount = 48
        }))
    end)
    it("follows instruction L5 from 0", function()
        assert.are.equal(95, m.follow_instruction(0, {
            direction = -1,
            amount = 5
        }))
    end)
    it("follows instruction R60 from 95", function()
        assert.are.equal(55, m.follow_instruction(95, {
            direction = 1,
            amount = 60
        }))
    end)
    it("follows instruction L55 from 55", function()
        assert.are.equal(0, m.follow_instruction(55, {
            direction = -1,
            amount = 55
        }))
    end)
    it("follows instruction L1 from 0", function()
        assert.are.equal(99, m.follow_instruction(0, {
            direction = -1,
            amount = 1
        }))
    end)
    it("follows instruction L99 from 99", function()
        assert.are.equal(0, m.follow_instruction(99, {
            direction = -1,
            amount = 99
        }))
    end)
    it("follows instruction R14 from 0", function()
        assert.are.equal(14, m.follow_instruction(0, {
            direction = 1,
            amount = 14
        }))
    end)
    it("follows instruction L82 from 14", function()
        assert.are.equal(32, m.follow_instruction(14, {
            direction = -1,
            amount = 82
        }))
    end)
    it("follows instruction with wrap around", function()
        local next_value, zeroes = m.follow_instruction(50, {
            direction = 1,
            amount = 1000
        }, 0, 99)
        assert.are.equal(50, next_value)
        assert.are.equal(10, zeroes)
    end)
    it("test input", function()
        assert.are.equal(6, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(0, m.solution("./inputs/input.txt"))
    end)
end)
