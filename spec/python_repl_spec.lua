describe("Test the IPython repl", function()
	describe("IPython:receive", function()
		local ipython, received
		before_each(function()
			ipython = require("lungan.repl.IPython"):new(require("lungan.nvim.Term"):new(), function(_, message)
				received = message
			end)
		end)
		it("should handle session in", function()
			assert.are.equal(3, ipython.state)
			assert.are.equal(1, ipython.count)
			local content = { "In [2]: test" }
			ipython:receive(content)
			assert.are.equal(ipython.state, 1)
			assert.are.equal(ipython.count, 2)
		end)
		it("should handle session out", function()
			local content = { "Out[1]: result" }
			ipython:receive(content)
			assert.are.equal(#ipython.response.out, 1)
			assert.are.equal(ipython.response.out[1], "result")
		end)
		it("should handle session out, followed by session in", function()
			ipython:receive({ "Out[1]: result" })
			assert.are.equal(#ipython.response.out, 1)
			assert.are.equal(ipython.response.out[1], "result")
			ipython:receive({ "In[2]:" })
			assert.are.equal(#ipython.response.out, 1)
			assert.are.equal(ipython.response.out[1], "result")
		end)
		it("should handle stdout", function()
			ipython:receive({ "0", "1" })
			ipython:receive({ "2", "3", "4", "5", "6" })
			assert.is.True(ipython.response.has_err == nil)
			assert.are.equal(7, #ipython.response.stdout)
			assert.Same({ "0", "1", "2", "3", "4", "5", "6" }, ipython.response.stdout)
			ipython:receive({ "In [2]:" })
			assert.are.equal(7, #received.stdout)
		end)
		it("should handle continuation", function()
			local content = { "...:" }
			ipython:receive(content)
			assert.are.equal(4, ipython.state) -- state 4 is cont
		end)
		it("should handle errors", function()
			local content = {
				"---------------------------------------------------------------------------",
				"ZeroDivisionError                         Traceback (most recent call last)",
			}
			ipython:receive(content)
			assert.is_true(ipython.response.has_err)
		end)
		it("should reset response on error", function()
			local content = {
				"---------------------------------------------------------------------------",
				"ZeroDivisionError                         Traceback (most recent call last)",
			}
			ipython:receive(content)
			assert.are.equal(2, #ipython.response.stdout)
			ipython:receive({ "In [2]:" })
			assert.Same({
				"---------------------------------------------------------------------------",
				"ZeroDivisionError                         Traceback (most recent call last)",
			}, received.stdout)
		end)
		it("should return an error table", function()
			local content = {
				"---------------------------------------------------------------------------",
				"ZeroDivisionError                         Traceback (most recent call last)",
				"Cell In[7], line 1",
				"----> 1 a/0",
				"",
				"ZeroDivisionError: division by zero",
			}
			ipython:receive(content)
			-- assert.are.equal(1, #ipython.response.stdout)
			ipython:receive({ "In [2]:" })
			assert.Same(
				{ name = "ZeroDivisionError", desc = "division by zero", subline = "1", trace = { "1 a/0" } },
				received.error
			)
		end)
	end)
	describe("IPython:send", function()
		local ipython, received
		before_each(function()
			ipython = require("lungan.repl.IPython"):new(require("lungan.nvim.Term"):new(), function(line, message)
				received = message
			end)
		end)
		it("should return return 69", function()
			local content = {
				{ line = 1, text = "a = 42" },
				{ line = 2, text = "b = 27" },
				{ line = 3, text = "a+b" },
			}
			for i, c in ipairs(content) do
				ipython:send(c)
			end
			vim.wait(50)
			assert.Same({ [1] = 1, line = 1, out = { "69" } }, received)
		end)
		it("should return plot the image", function()
			local content = [[import matplotlib
matplotlib.use('module://elektron')

import matplotlib.pyplot as plt
import numpy as np

xpoints = np.array([1, 8])
ypoints = np.array([3, 10])

plt.plot(xpoints, ypoints)
plt.show()
]]
			for i, c in ipairs(require("lungan.str").lines(content)) do
				ipython:send({ line = i, text = c })
			end
			ipython:send({ line = #content, text = "elektron.plots()" })
			vim.wait(100)
			assert.are.Equal(640, received.images[1].width)
			assert.are.Equal(480, received.images[1].height)
			assert.are.Equal(21996, #received.images[1].base64)
		end)
	end)
end)
