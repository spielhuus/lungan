local assert = require("luassert")
require("lungan.log").level = "warn"
describe("Test the LUA repl", function()
	local luarepl, received
	before_each(function()
		local mes
		luarepl, mes = require("lungan.repl.Lua"):new(
			require("lungan.repl.NvimTerm"):new({ repl_show = true }),
			function(_, message)
				if received == nil then
					received = message
				else
					table.insert(received.stdout, message.stdout)
				end
			end
		)
		assert(luarepl, mes)
	end)
	it("should handle session in", function()
		assert.are.equal(2, luarepl.state)
		luarepl:wait()
		assert.are.equal(1, luarepl.state)
	end)

	it("should handle session in", function()
		assert.are.equal(2, luarepl.state)
		luarepl:wait()
		assert.are.equal(1, luarepl.state)
		luarepl:receive({ "hello morgan", ">" })
		assert.is.Same({ stdout = { "hello morgan" } }, received)
	end)

	it("should handle multiple session in", function()
		assert.are.equal(2, luarepl.state)
		luarepl:wait()
		assert.are.equal(1, luarepl.state)
		received = nil
		luarepl:receive({ "1", "2", "3", "4", "5", "6", "7", "8", "9", ">" })
		assert.is.Same({ stdout = { "1", "2", "3", "4", "5", "6", "7", "8", "9" } }, received)
	end)

	-- 	it("should handle errors", function()
	-- 		local content = {
	-- 			"---------------------------------------------------------------------------",
	-- 			"ZeroDivisionError                         Traceback (most recent call last)",
	-- 		}
	-- 		luarepl:receive(content)
	-- 		assert.is_true(luarepl.response.has_err)
	-- 	end)
	-- 	it("should reset response on error", function()
	-- 		local content = {
	-- 			"---------------------------------------------------------------------------",
	-- 			"ZeroDivisionError                         Traceback (most recent call last)",
	-- 		}
	-- 		luarepl:receive(content)
	-- 		assert.are.equal(2, #luarepl.response.stdout)
	-- 		luarepl:receive({ "In [2]:" })
	-- 		assert.Same({
	-- 			"---------------------------------------------------------------------------",
	-- 			"ZeroDivisionError                         Traceback (most recent call last)",
	-- 		}, received.stdout)
	-- 	end)
	-- 	it("should return an error table", function()
	-- 		local content = {
	-- 			"---------------------------------------------------------------------------",
	-- 			"ZeroDivisionError                         Traceback (most recent call last)",
	-- 			"Cell In[7], line 1",
	-- 			"----> 1 a/0",
	-- 			"",
	-- 			"ZeroDivisionError: division by zero",
	-- 		}
	-- 		luarepl:receive(content)
	-- 		-- assert.are.equal(1, #luarepl.response.stdout)
	-- 		luarepl:receive({ "In [2]:" })
	-- 		assert.Same(
	-- 			{ name = "ZeroDivisionError", desc = "division by zero", subline = "1", trace = { "1 a/0" } },
	-- 			received.error
	-- 		)
	-- 	end)
	-- end)
	-- describe("Python:send", function()
	-- 	local luarepl, received
	-- 	before_each(function()
	-- 		local mes
	-- 		luarepl, mes = require("lungan.repl.Python"):new(
	-- 			require("lungan.repl.NvimTerm"):new({ repl_show = true }),
	-- 			function(_, message)
	-- 				received = message
	-- 			end
	-- 		)
	-- 		if luarepl == nil then
	-- 			print(mes)
	-- 		end
	-- 		assert.is.True(luarepl ~= nil)
	-- 	end)
	-- 	it("should not echo the inputs", function()
	-- 		local content = {
	-- 			{ line = 1, text = "a = 42" },
	-- 			{ line = 2, text = "b = 27 " },
	-- 			{ line = 3, text = "a+b " },
	-- 		}
	-- 		for _, c in ipairs(content) do
	-- 			luarepl:send(c)
	-- 		end
	-- 		luarepl:wait()
	-- 		assert.Same({ out = { "69" } }, received)
	-- 	end)
	it("should return return 69", function()
		local content = {
			{ line = 1, text = "a = 42" },
			{ line = 2, text = "b = 27" },
			{ line = 3, text = "print(a+b)" },
		}
		received = nil
		for _, c in ipairs(content) do
			luarepl:send(c)
		end
		luarepl:wait()
		assert.Same({ stdout = { "69" } }, received)
	end)
	it("should return return 69 when function called", function()
		local content = {
			{ line = 1, text = "function add(a, b)\n  return a+b\nend" },
			{ line = 2, text = "print(add(45, 24))" },
		}
		received = nil
		for _, c in ipairs(content) do
			luarepl:send(c)
		end
		luarepl:wait()
		assert.Same({ stdout = { "69" } }, received)
	end)
end)
