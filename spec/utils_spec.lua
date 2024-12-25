local assert = require("luassert")
local get_code_fence = require("lungan.utils").get_code_fence

describe("get_code_fence", function()
	it("should extract code within a simple fence", function()
		local input = {
			"Some text",
			"```",
			"print('Hello, World!')",
			"```",
			"More text",
		}
		local expected_output = { "print('Hello, World!')" }
		local fenced_code, _ = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
	end)

	it("should extract code with a language specified", function()
		local input = {
			"Some text",
			"```lua",
			"print('Hello, World!')",
			"```",
			"More text",
		}
		local expected_output = { "print('Hello, World!')" }
		local fenced_code, language = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
		assert.is.Equal(language, "lua")
	end)

	it("should handle multiple fences", function()
		local input = {
			"Some text",
			"```",
			"print('Hello, World!')",
			"```",
			"More text",
			"```python",
			"print('Hello, Python!')",
			"```",
		}
		local expected_output = { "print('Hello, World!')", "print('Hello, Python!')" }
		local fenced_code, _ = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
	end)

	it("should return empty table if no fences are present", function()
		local input = {
			"Some text",
			"More text",
		}
		local expected_output = {}
		local fenced_code, _ = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
	end)

	it("should include all lines between fences", function()
		local input = {
			"Some text",
			"```",
			"print('Hello, World!')",
			"This is a line within the fenced block",
			"```",
			"More text",
		}
		local expected_output = { "print('Hello, World!')", "This is a line within the fenced block" }
		local fenced_code, _ = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
	end)

	it("should return empty table if no fences are present", function()
		local input = {
			"Some text",
			"More text",
		}
		local expected_output = {}
		local fenced_code, _ = get_code_fence(input)
		assert.are.same(fenced_code, expected_output)
	end)
end)
