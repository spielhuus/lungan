local log = require("lungan.log")

---@class Phantom
---@field args table
---@field result table
local Phantom = {}
Phantom.__index = Phantom

local namespace = vim.api.nvim_create_namespace("lungan.phantom")

---Clean result table: Extract code between fences and trim whitespace-only lines
---@param text string[]
---@return string[]
local function clean_result(text)
	local extracted = {}
	local in_fence = false
	local fence_found = false

	-- Try to extract content inside code fences
	for _, line in ipairs(text) do
		if line:match("^%s*```") then
			if in_fence then
				in_fence = false -- End of block
				break
			else
				in_fence = true
				fence_found = true
			end
		elseif in_fence then
			table.insert(extracted, line)
		end
	end

	-- If no fences were found, use the original text
	if not fence_found then
		extracted = text
	end

	-- Trim leading empty/whitespace lines
	local start = 1
	while start <= #extracted and extracted[start]:match("^%s*$") do
		start = start + 1
	end

	-- Trim trailing empty/whitespace lines
	local finish = #extracted
	while finish >= start and extracted[finish]:match("^%s*$") do
		finish = finish - 1
	end

	local result = {}
	if start <= finish then
		for i = start, finish do
			table.insert(result, extracted[i])
		end
	end

	return result
end

---Extract the last assistant message and clean it
local function extract_chat(data)
	if not data or not data.iter then
		log.error("Phantom: Invalid data object passed (missing iter)")
		return {}
	end

	local message = {}
	-- Iterate to find the last assistant message
	for m in data:iter() do
		if m.type == "chat" and m.role == "assistant" then
			message = vim.split(m.text, "\n")
		end
	end
	return clean_result(message)
end

function Phantom:new(args, data)
	local o = {}
	setmetatable(o, { __index = self })
	o.args = args

	-- Guard against nil data
	if not data then
		log.error("Phantom: No data available to render")
		return nil
	end

	o.result = extract_chat(data)

	if #o.result == 0 then
		log.warn("Lungan: No content to preview")
		return nil
	end

	o:render()
	o:set_keymaps()

	vim.notify("Lungan: Preview generated. <C-a> to commit, <C-c> to clear.", vim.log.levels.INFO)
	return o
end

function Phantom:render()
	self:clear()

	local virt_lines = {}
	for _, line in ipairs(self.result) do
		table.insert(virt_lines, { { line, "Comment" } })
	end

	-- Insert the virtual lines at the cursor position (line1)
	-- args.line1 is 1-based, set_extmark expects 0-based
	local line_idx = (self.args.line1 or 1) - 1
	local line_count = vim.api.nvim_buf_line_count(self.args.source_buf)
	if line_idx > line_count then
		line_idx = line_count
	end
	if line_idx < 0 then
		line_idx = 0
	end

	self.extmark_id = vim.api.nvim_buf_set_extmark(self.args.source_buf, namespace, line_idx, 0, {
		virt_lines = virt_lines,
		virt_lines_above = true,
	})
end

function Phantom:commit()
	if not self.args or not self.args.source_buf then
		return
	end

	local start_line = (self.args.line1 or 1) - 1
	local end_line = (self.args.line2 or 1)
	local is_selection = (self.args.line2 - self.args.line1) > 0

	if not is_selection then
		-- Cursor placement: Check if the current line is empty.
		-- If empty, replace it (consume it) to avoid leaving a trailing empty line.
		local lines = vim.api.nvim_buf_get_lines(self.args.source_buf, start_line, start_line + 1, false)
		local current_line = lines[1] or ""
		if current_line:match("^%s*$") then
			end_line = start_line + 1
		else
			end_line = start_line
		end
	end

	vim.api.nvim_buf_set_lines(self.args.source_buf, start_line, end_line, false, self.result)
	self:clear()
	vim.notify("Lungan: Changes committed", vim.log.levels.INFO)
end

function Phantom:clear()
	if self.args and self.args.source_buf and vim.api.nvim_buf_is_valid(self.args.source_buf) then
		vim.api.nvim_buf_clear_namespace(self.args.source_buf, namespace, 0, -1)
		pcall(vim.keymap.del, "n", "<C-a>", { buffer = self.args.source_buf })
		pcall(vim.keymap.del, "n", "<C-c>", { buffer = self.args.source_buf })
	end
end

function Phantom:set_keymaps()
	local buf = self.args.source_buf
	local opts = { nowait = true, noremap = true, silent = true, buffer = buf }
	vim.keymap.set("n", "<C-a>", function()
		self:commit()
	end, opts)
	vim.keymap.set("n", "<C-c>", function()
		self:clear()
	end, opts)
end

return {
	preview = function(opts_or_args, args_or_data, maybe_data)
		local args, data
		if maybe_data ~= nil then
			args = args_or_data
			data = maybe_data
		else
			args = opts_or_args
			data = args_or_data
		end
		return Phantom:new(args, data)
	end,
}
