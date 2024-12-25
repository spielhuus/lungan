---@class IRepl
---@field prologue table
---@field on_message function
---@field term ITerm
local IRepl = {}

---Receive content from the Repl
---@param content any -- TODO: what is the type
function IRepl:receive(content)
	error("`IRepl:receive` not implemented, called with (" .. content .. ")")
end

---Wait for the current command
function IRepl:wait()
	error("`IRepl:wait` not implemented")
end

---Send a command to the Repl
---@param cell table the cell
function IRepl:send(cell)
	error("`IRepl:send` not implemented, called with (" .. require("str").to_string(cell) .. ")")
end

---Create a new Repl
---@param term ITerm
---@param on_message function
---@return integer state
---@return table|string the Repl object or error message
function IRepl:new(term, on_message)
	local o = {}
	setmetatable(o, { __index = self })
	o.on_message = on_message
	o.term = term
	return 0, o
end

return IRepl
