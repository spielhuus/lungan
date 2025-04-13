local M = {}

---Extract fenced code
---@param code table[string] text lines.
M.get_code_fence = function(code)
	local in_fence = false
	local fenced_code = {}
	local fence_language = nil

	for _, line in ipairs(code) do
		if line:match("^%s*```") then
			if in_fence then
				-- End of a fenced block
				in_fence = false
			else
				-- Start of a fenced block
				in_fence = true
				fence_language = line:match("^%s*```(.*)")
			end
		elseif in_fence then
			table.insert(fenced_code, line)
		end
	end

	return fenced_code, fence_language
end

--- Generate a formatted code fence for the specified range in the buffer.
-- @param bufnr integer: Buffer number where the range is located.
-- @param start integer: Starting line of the range (1-based index).
-- @param end_ integer: Ending line of the range (inclusive, 1-based index).
-- @return table: Table containing formatted code fence as its only element.
local function code_fence(bufnr, start, end_)
	local current_lines = vim.api.nvim_buf_get_lines(bufnr, start - 1, end_, false)
	local message = vim.iter({
		"```" .. vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
		current_lines,
		"```",
	})
		:flatten()
		:totable()
	return message
end

--- Get a block of text from a buffer.
-- @param buf_nr integer: The buffer number where the block resides.
-- @param start integer: The starting line index (1-based) of the block.
-- @param last integer: The ending line index (1-based) of the block, or nil for until EOF.
M.GetBlock = function(buf_nr, start, last)
	return table.concat(code_fence(buf_nr, start, last), "\n")
end

--- Get a code snippet from a buffer.
-- Returns the top-level code block that contains the given line.
-- @param buf integer: The buffer ID.
-- @param line integer: The line number to search for a code block.
-- @return table|nil: A table representing the code block in markdown format,
-- or nil followed by an error message if no code block was found.
M.GetCodeBlock = function(buf, line)
	local parser, mes = vim.treesitter.get_parser(buf)
	if not parser then
		error("can not load treesitter parser: " .. mes)
	end
	local tree = parser:parse()[1]
	local root = tree:root()

	for item in root:iter_children() do
		if item:start() <= line and item:end_() >= line then
			return table.concat(code_fence(buf, item:start() + 1, item:end_() + 1), "\n")
		end
	end
	return {}
end

---This method takes a string as a template.
--All placeholders `{VAR}` will be replaced with
--the corresponding values from the dictionary.
M.TemplateVars = function(dict, text)
	-- Use a pattern to find all occurrences of {VAR} in the text
	local res = (
		string.gsub(text, "{{([%w|_]+)}}", function(var)
			-- Replace each occurrence with the corresponding value from the dictionary
			local substitude = dict[var]
			if substitude and type(substitude) == "table" then
				return vim.inspect(substitude)
			else
				return substitude
			end
		end)
	)
	return vim.split(res, "\n")
end

return M
