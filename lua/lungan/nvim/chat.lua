local LLM = require("lungan.llm")

---@class Chat
---@field options table options
---@field args table the session args
---@field data table the parsed Markdown data
---@field prompt Prompt the chat prompt
---@field llm LLM the chat prompt
local Chat = {}

-- Creates a new instance the Chat class
-- @param options table The global options
-- @param args table The arguments for this option (source_buf, line ...)
-- @param prompt Prompt the prompt
-- @return An instance of the Chat class with the provided configurations.
function Chat:new(options, args, prompt)
	local o = {}
	setmetatable(o, { __index = self, __name = "Chat" })
	o.options = options
	o.args = args
	o.prompt = prompt
	o.data = nil
	o.llm = LLM:new(options)
	return o
end

local get_win_opts = function()
	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)
	local new_win_width = math.floor(win_width / 2)
	return {
		relative = "win",
		width = new_win_width - 3,
		height = win_height - 3,
		row = 0,
		col = new_win_width,
		style = "minimal",
		border = "shadow",
	}
end

function Chat:append(tokens)
	local all_lines = vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
	local last_row = #all_lines
	local last_row_content = all_lines[last_row]
	local last_col = string.len(last_row_content)
	local text = table.concat(tokens or {}, "\n")
	vim.api.nvim_buf_set_text(self.buffer, last_row - 1, last_col, last_row - 1, last_col, vim.split(text, "\n"))
	-- jump to the last line
	local total_lines = vim.api.nvim_buf_line_count(self.buffer)
	if self.win and total_lines > 0 then
		vim.api.nvim_win_set_cursor(self.win, { total_lines, 0 })
	end
end

function Chat:open()
	self.buffer = vim.api.nvim_create_buf(true, false)
	-- create the autogroups for this buf
	vim.api.nvim_buf_set_name(self.buffer, "Lungan Chat: #" .. self.buffer)
	vim.api.nvim_set_option_value("buftype", "nowrite", { buf = self.buffer })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.buffer })
	if self.prompt.data:frontmatter()["context"] then
		local collected_lines = {}
		local func, err = load(self.prompt.data:frontmatter()["context"])
		if not func then
			error(err)
		end
		local content = func()(self.args.source_buf, self.args.line1, self.args.line2)
		for _, line in ipairs(self.prompt.lines) do
			local parsed_line = require("lungan.utils").TemplateVars(content, line)
			for _, v in ipairs(parsed_line) do
				table.insert(collected_lines, v)
			end
		end
		vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, collected_lines)
	else
		vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, self.prompt.lines)
	end
	-- creat the window
	self.win = vim.api.nvim_open_win(self.buffer, true, get_win_opts())
	vim.api.nvim_set_option_value("wrap", true, { win = self.win })
	vim.api.nvim_set_option_value("wrapmargin", 20, { buf = self.buffer })
	vim.api.nvim_set_option_value("cursorline", true, { win = self.win })

	self._group = vim.api.nvim_create_augroup("LunganChat", { clear = true })
	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = self.buffer,
		group = self._group,
		callback = function()
			-- TODO delete autogroup
			vim.api.nvim_del_augroup_by_id(self._group)
			-- require("lungan.diff").clear_marks(M.options, M.sessions[self.buffer])
			-- M.sessions[args.buffer] = nil
			self.llm:stop(self)
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
		group = self._group,
		buffer = self.buffer,
		callback = function()
			self:refresh()
			if not self.initialized then
				-- fold the frontmatter
				vim.api.nvim_win_call(self.win, function()
					-- Manually set the fold start and end lines
					local content = self.data[1]
					if content and content.name == "frontmatter" then
						vim.opt.foldmethod = "manual"
						vim.cmd(content.row_start + 1 .. "," .. content.row_end .. "fold")
					end
				end)
				self.initialized = true
			end
		end,
	})

	-- create the keymaps for this buf
	vim.keymap.set("n", "<C-n>", function()
		self:append({ "\n<== user\n\n==>" })
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
	vim.keymap.set("n", "<C-c>", function()
		self.llm:stop(self)
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
	vim.keymap.set("n", "<C-r>", function()
		self.llm:chat(self)
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
	vim.keymap.set("n", "<C-y>", function()
		local func, err = load(self.prompt.data.fm.tree.preview)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
	vim.keymap.set("n", "<C-a>", function()
		local func, err = load(self.prompt.data.fm.tree.commit)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
	vim.keymap.set("n", "<C-l>", function()
		local func, err = load(self.prompt.data.fm.tree.clear)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = self.buffer,
	})
end

function Chat:refresh()
	self.data = require("lungan.markdown"):new(nil, vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false))
	require("lungan.nvim.renderer").render(self.options, self.win, self.buffer, self.data)
end

---Returns the llm data frome the chat
function Chat:get()
	local output = self.data:frontmatter()
	output.messages = {}
	for line in self.data:iter() do
		if line.type == "chat" then
			table.insert(output.messages, { role = line.role, content = line.text })
		end
	end
	return output
end

return Chat
