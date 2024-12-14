assert = require("luassert")
local tbl = require("lungan.tbl")
describe("Test the table utilities", function()
	it("should insert a value by root path", function()
		local result = {}
		tbl.set_with_path(result, "a", "b")
		assert.same({ a = "b" }, result)
	end)
	it("should insert a value by path", function()
		local result = {}
		tbl.set_with_path(result, "a.b", "b")
		assert.same({ a = { b = "b" } }, result)
	end)
	it("should insert a value by deeper path", function()
		local result = {}
		tbl.set_with_path(result, "a.b.c", "c")
		assert.same({ a = { b = { c = "c" } } }, result)
	end)
end)
