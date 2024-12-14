assert = require("luassert")
local str = require("lungan.str")
describe("Test the string utilities", function()
	describe(", the string utilities", function()
		it("should remove trailing new lines", function()
			assert.same("Hello Mommy", str.stripnl("Hello Mommy\n"))
			assert.same("Hello Mommy", str.stripnl("Hello Mommy\r"))
			assert.same("Hello Mommy", str.stripnl("Hello Mommy\r\n"))
			assert.same("Hello Mommy", str.stripnl("Hello Mommy"))
		end)
		it("should split a string into lines", function()
			assert.same({ "a", "b" }, str.lines("a\nb"))
			assert.same({ "a", "b" }, str.lines("a\nb\n"))
			assert.same({ "a", "b", "c" }, str.lines("a\nb\r\nc\r\n"))
			assert.same({ "a", "b", "", "c" }, str.lines("a\nb\r\n\r\nc\r\n"))
			assert.same(
				{
					"import matplotlib",
					"matplotlib.use('module://lungan')",
					"",
					"import matplotlib.pyplot as plt",
					"import numpy as np",
					"",
					"xpoints = np.array([1, 8])",
					"ypoints = np.array([3, 10])",
					"",
					"plt.plot(xpoints,ypoints)",
				},
				str.lines(
					"import matplotlib\nmatplotlib.use('module://lungan')\n\nimport matplotlib.pyplot as plt\nimport numpy as np\n\nxpoints = np.array([1, 8])\nypoints = np.array([3, 10])\n\nplt.plot(xpoints,ypoints)"
				)
			)
		end)
	end)
	describe("Test the map clean", function()
		it("should clean the tables", function()
			assert.same({ "a", "b", "c" }, str.clean_table({ "", "", "a", "b", "c", "" }))
			assert.same({ "a", "b", "c" }, str.clean_table({ "\n", "", "a", "b", "c", "" }))
			assert.same({ "a", "b", "c" }, str.clean_table({ "\r", "", "a", "b", "c", "\r" }))
		end)
	end)
	describe("Test the space tokenizer", function()
		local text = [[a="a" b="b  b" c=false d="escaped \" test" e="nested 'quotes' test" f='single quote' g = false]]
		local expected = {
			'a="a"',
			'b="b  b"',
			"c=false",
			'd="escaped \\" test"',
			"e=\"nested 'quotes' test\"",
			"f='single quote'",
			"g",
			"=",
			"false",
		}
		it(" clean the tables", function()
			assert.same(expected, str.spaces(text))
		end)
	end)
	describe("Test param parser", function()
		it("parse params", function()
			local text =
				[[a="a" b="b  b" c=false d="escaped \" test" e="nested 'quotes' test" f='single quote' g = false]]
			local expected = {
				["a"] = "a",
				["c"] = false,
				["b"] = "b  b",
				["e"] = "nested 'quotes' test",
				["d"] = 'escaped " test',
				["g"] = false,
				["f"] = "single quote",
			}
			local tokens = str.spaces(text)
			assert.same(expected, str.params(tokens))
		end)
		it("parse keys with a dot", function()
			local text = [[a="a" b="b  b" c=false d="escaped \" test" e="nested 'quotes' test" f.state=false]]
			local expected = {
				["a"] = "a",
				["c"] = false,
				["b"] = "b  b",
				["e"] = "nested 'quotes' test",
				["d"] = 'escaped " test',
				["f.state"] = false,
			}
			local tokens = str.spaces(text)
			assert.same(expected, str.params(tokens))
		end)
	end)
end)
