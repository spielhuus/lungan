--- Repl
---
--- Implementations:
--- [NvimRepl](lua://NvimRepl) using the nvim uv package
--- [LuvRepl](lua://LuvRepl) using the luv package
---@class ITerm
local ITerm = {}
ITerm.__index = ITerm

---Wait for timeout or when the callback returns true
---@param timeout integer
---@param fn fun(): boolean
---@return boolean
function ITerm:wait(timeout, fn)
	print(timeout)
	return fn()
end

function ITerm:callback(fn)
	self.on_message = fn
end

function ITerm:on_close(fn)
	self.on_close = fn
end

-- ---Create a new Repl
-- ---@param options table
-- ---@param on_message fun()
-- ---@return integer state
-- ---@return table|string the Repl object or error message
-- function ITerm:new(options, on_message)
-- 	local o = {}
-- 	setmetatable(o, { __index = self })
-- 	o.on_message = on_message
-- 	o.options = options
-- 	return 0, o
-- end

---Run a command in the Repl
---@param cmd table The commands
---@return boolean state true if successfull otherwise false
---@return string The error message
function ITerm:run(cmd)
	print(cmd)
	return false, "not implemented"
end

---Stop a running Repl
function ITerm:stop() end

---Send a command to the Repl
---@param message string|table[string]
function ITerm:send(message)
	print(message)
end

return ITerm
