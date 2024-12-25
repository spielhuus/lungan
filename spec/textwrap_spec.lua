local assert = require("luassert")
local textwrap = require("lungan.textwrap")
describe("Test the textwrapper", function()
	it("", function()
		local source = { "The ", "hidden ", "dra", "gon ", "." }
		local expected = "The hidden dragon."
		-- assert.same(expected, textwrap:new(nil, {}, {}))
	end)
end)
