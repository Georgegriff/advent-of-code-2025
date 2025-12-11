local m = require "part1"
local Graph = require "graph"
pcall(function() require("lldebugger").start() end)
describe("solutions", function()
    it("test input", function()
        assert.are.equal(5, m.solution("./inputs/test.txt"))
    end)
    it("input", function()
        assert.are.equal(585, m.solution("./inputs/input.txt"))
    end)

    it("parses graph", function()
        ---@type Graph
        local g = Graph()
        g:parse_input_line("aaa: you hhh")
        assert.are.equal("aaa: you hhh", string.format("%s", g.nodes["aaa"]))
        assert.are.equal("you: ", string.format("%s", g.nodes["you"]))
        g:parse_input_line("you: bbb ccc")
        assert.are.equal("you: bbb ccc", string.format("%s", g.nodes["you"]))
    end)
end)
