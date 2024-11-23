---@class Prompt
---@field path string
---@field options table
local Prompt = {}

function Prompt:_from_file()
	-- create a scratch buffer and parse the content
	local scratch = vim.api.nvim_create_buf(false, true)
	local lines = vim.fn.readfile(self.path)
	-- Set the lines in the scratch
	vim.api.nvim_buf_set_lines(scratch, 0, -1, true, lines)
	-- Parse the content using the parser module
	local data = require("lungan.markdown"):new(nil, lines)
	self.lines = lines
	self.data = data
end

function Prompt:new(o, options, path)
	o = o or {}
	setmetatable(o, { __index = self, __name = "Prompt" })
	o.options = options
	o.path = path
	o:_from_file()
	return o
end

return Prompt
