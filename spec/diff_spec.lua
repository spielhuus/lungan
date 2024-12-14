assert = require("luassert") -- luacheck: ignore
describe("Test the diff funcitons", function()
	describe("Clean the result table", function()
		it("should remove all the leading and trailing empty entries and those with code fences", function()
			local source = { "", "```", "a", "b", "c", "```", "" }
			local expected = { "a", "b", "c" }
			assert.same(expected, require("lungan.nvim.diff").__clean_result(source))
		end)
		it("should remove also when the fence has a language", function()
			local source = { "", "```llama", "a", "b", "c", "```", "" }
			local expected = { "a", "b", "c" }
			assert.same(expected, require("lungan.nvim.diff").__clean_result(source))
		end)
		it("should remove also when there are no fences", function()
			local source = { "", "a", "b", "c", "" }
			local expected = { "a", "b", "c" }
			assert.same(expected, require("lungan.nvim.diff").__clean_result(source))
		end)
	end)
	describe("Find the Longest Common Subsequence (LCS)", function()
		it("should solve the example", function()
			local original = "lorem ipsum"
			local modified = "loem kipsum"
			local expected = "loem ipsum"
			assert.same(expected, require("lungan.nvim.diff").lcs(original, modified))
		end)
		it("should diff the example", function()
			local original = "lorem ipsum"
			local modified = "loem kipsum"
			-- local expected = "lo-r-em +k+ipsum"
			local expected = {
				{
					"l",
					"@comment",
				},
				{
					"o",
					"@comment",
				},
				{
					"r",
					"@label",
				},
				{
					"e",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"k",
					"@error",
				},
				{
					"i",
					"@comment",
				},
				{
					"p",
					"@comment",
				},
				{
					"s",
					"@comment",
				},
				{
					"u",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
			}
			assert.same(expected, require("lungan.nvim.diff").diff(original, modified))
		end)

		it("should diff first character", function()
			local original = "The plugin name is 'lungan.nvim'"
			local modified = "the plugin name is 'lungan.nvim'"
			local expected = {
				{
					"T",
					"@label",
				},
				{
					"t",
					"@error",
				},
				{
					"h",
					"@comment",
				},
				{
					"e",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"p",
					"@comment",
				},
				{
					"l",
					"@comment",
				},
				{
					"u",
					"@comment",
				},
				{
					"g",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"a",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
				{
					"e",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"s",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"'",
					"@comment",
				},
				{
					"l",
					"@comment",
				},
				{
					"u",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"g",
					"@comment",
				},
				{
					"a",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					".",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"v",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
				{
					"'",
					"@comment",
				},
			}
			assert.same(expected, require("lungan.nvim.diff").diff(original, modified))
		end)
		it("should diff last character", function()
			local original = "The plugin name is 'lungan.nvim'."
			local modified = "The plugin name is 'lungan.nvim'"
			local expected = {
				{
					"T",
					"@comment",
				},
				{
					"h",
					"@comment",
				},
				{
					"e",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"p",
					"@comment",
				},
				{
					"l",
					"@comment",
				},
				{
					"u",
					"@comment",
				},
				{
					"g",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"a",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
				{
					"e",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"s",
					"@comment",
				},
				{
					" ",
					"@comment",
				},
				{
					"'",
					"@comment",
				},
				{
					"l",
					"@comment",
				},
				{
					"u",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"g",
					"@comment",
				},
				{
					"a",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					".",
					"@comment",
				},
				{
					"n",
					"@comment",
				},
				{
					"v",
					"@comment",
				},
				{
					"i",
					"@comment",
				},
				{
					"m",
					"@comment",
				},
				{
					"'",
					"@comment",
				},
				{
					".",
					"@label",
				},
			}
			assert.same(expected, require("lungan.nvim.diff").diff(original, modified))
		end)
	end)
end)
