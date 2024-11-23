local Repl = require("lungan.repl.IPython")
local Term = require("lungan.lua.Term")

local code = [[a = 44
b = 25
a + b]]

local repl = Repl:new(Term:new(), function(_, message)
	if message["out"] then
		print(message["out"][1])
	end
end)

print(code)
repl:send({
	text = code,
})

repl:wait()

local plot = [[
import matplotlib
matplotlib.use('module://matplotlib-backend-kitty')
matplotlib.pyplot.ion()

import matplotlib.pyplot as plt
import numpy as np

xpoints = np.array([1, 8])
ypoints = np.array([3, 10])

plt.plot(xpoints, ypoints)]]
-- plt.show()]]

print("\n---\n" .. plot)
repl:send({
	text = plot,
})

repl:wait()
