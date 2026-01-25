local LLM = require("lungan.llm")
local log = require("lungan.log")

---Chat class for handling chat interactions with an LLM
---@class Chat
---@field options table
---@field args table
---@field prompt table
---@field data table
---@field llm LLM
---@field awaiting_tools integer
---@field mcp table
---@field _tool_accumulator table
---@field buffer integer
---@field win integer
---@field _group integer
---@field initialized boolean
local Chat = {}

-- Creates a new instance the Chat class
function Chat:new(options, args, prompt)
	local o = {}
	setmetatable(o, { __index = self, __name = "Chat" })
	o.options = options
	o.args = args
	o.prompt = prompt
	o.data = nil
	o.llm = LLM:new(options)

	o.awaiting_tools = 0

	o.mcp = require("lungan.mcp.FastMcp"):new(require("lungan.repl.NvimJob"):new({}), function(_, message, _)
		if message["result"] and message["result"]["tools"] ~= nil then
			o.prompt["tools"] = message
		elseif message["result"] and message["result"]["content"] then
			local output_text = ""
			for _, item in ipairs(message["result"]["content"]) do
				if item.type == "text" then
					output_text = output_text .. item.text
				end
			end

			local tool_id = message.id or ""

			-- Schedule the append to the main loop
			vim.schedule(function()
				o:append({ "", "<== tool " .. tool_id, output_text, "==>", "" })
				if o.awaiting_tools > 0 then
					o.awaiting_tools = o.awaiting_tools - 1
					if o.awaiting_tools == 0 then
						log.debug("All tools finished. Resuming LLM...")
						o:refresh()
						o.llm:chat(o)
					end
				end
			end)
		else
			log.info("MCP: " .. vim.inspect(message))
		end
	end, function()
		log.debug("mcp close")
	end)
	o.mcp:wait()
	o._tool_accumulator = {}
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

---Appends tokens to the chat buffer
---@param tokens table|string
function Chat:append(tokens)
	local all_lines = vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
	local last_row = #all_lines
	local last_row_content = all_lines[last_row]
	local last_col = string.len(last_row_content)
	local text = table.concat(tokens or {}, "\n")
	vim.api.nvim_buf_set_text(self.buffer, last_row - 1, last_col, last_row - 1, last_col, vim.split(text, "\n"))

	local total_lines = vim.api.nvim_buf_line_count(self.buffer)
	if self.win and total_lines > 0 then
		vim.api.nvim_win_set_cursor(self.win, { total_lines, 0 })
	end
end

---Processes tool calls from the LLM
---@param chunk table
function Chat:call_tools(chunk)
	-- accumulation phase
	if chunk.message and chunk.message.tools_call then
		for _, delta in ipairs(chunk.message.tools_call) do
			local idx = (delta.index or 0)
			if not self._tool_accumulator[idx] then
				self._tool_accumulator[idx] = { name = "", arguments = "", id = delta.id }
			end

			local fn_part = delta["function"]
			if fn_part then
				if fn_part.name then
					self._tool_accumulator[idx].name = self._tool_accumulator[idx].name .. fn_part.name
				end
				if fn_part.arguments then
					self._tool_accumulator[idx].arguments = self._tool_accumulator[idx].arguments .. fn_part.arguments
				end
			end
		end
	end

	-- execution phase
	if chunk.finish_reason == "tool_calls" then
		-- Prepare list of tools to call
		local tools_to_call = {}
		for _, tool_data in pairs(self._tool_accumulator) do
			table.insert(tools_to_call, tool_data)
		end

		-- Set the counter for the callback to track
		self.awaiting_tools = #tools_to_call

		-- Execute requests
		for _, tool_data in ipairs(tools_to_call) do
			local fn_name = tool_data.name
			local json_args = tool_data.arguments

			local success, args = pcall(vim.json.decode, json_args)
			if not success then
				args = vim.empty_dict()
			end
			if type(args) == "table" and next(args) == nil then
				args = vim.empty_dict()
			end

			local tool_id = tool_data.id

			local request = {
				jsonrpc = "2.0",
				method = "tools/call",
				params = { name = fn_name, arguments = args },
				id = tool_id,
			}

			local json_payload = vim.json.encode(request)
			log.info("Calling Tool: " .. json_payload)

			self.mcp:send(json_payload .. "\r\n")
			self.mcp:wait()
		end

		self._tool_accumulator = {}
	end
end

---Generates the final output with messages and frontmatter
---@return table
function Chat:get()
	local output = self.data:frontmatter()
	output.messages = {}
	for line in self.data:iter() do
		if line.type == "chat" then
			local msg = { role = line.role, content = line.text }

			if line.role == "tool" then
				msg.tool_call_id = vim.trim(line.meta or "")
			end

			if line.role == "assistant" then
				local text = vim.trim(line.text)
				if vim.startswith(text, "[") then
					local success, calls = pcall(vim.json.decode, text)
					if success and type(calls) == "table" then
						msg.tool_calls = calls
						msg.content = nil
					end
				end
			end

			table.insert(output.messages, msg)
		end
	end
	return output
end

---Opens the chat window and sets up the buffer
---@param filename string?
function Chat:open(filename)
	self.buffer = vim.api.nvim_create_buf(true, false)
	if filename then
		vim.api.nvim_buf_set_name(self.buffer, filename)
	else
		vim.api.nvim_buf_set_name(
			self.buffer,
			self.options.data_path() .. "/" .. os.date("%Y-%m-%d") .. "-" .. self.prompt.data:frontmatter()["name"]
		)
	end
	vim.api.nvim_set_option_value("buftype", "nowrite", { buf = self.buffer })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.buffer })

	if self.prompt.data:frontmatter()["mcp"] then
		local request = '{ "jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {} }\r\n'
		self.mcp:send(request)
		self.mcp:wait()
	end

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

	self.win = vim.api.nvim_open_win(self.buffer, true, get_win_opts())
	vim.api.nvim_set_option_value("wrap", true, { win = self.win })
	vim.api.nvim_set_option_value("wrapmargin", 20, { buf = self.buffer })
	vim.api.nvim_set_option_value("cursorline", true, { win = self.win })

	self._group = vim.api.nvim_create_augroup("LunganChat", { clear = true })
	vim.api.nvim_create_autocmd("WinClosed", {
		buffer = self.buffer,
		group = self._group,
		callback = function()
			vim.api.nvim_del_augroup_by_id(self._group)
			require("lungan.utils").ensure_directory_exists(self.options.data_path())
			local buffer_lines = vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false)
			local buffer_content = table.concat(buffer_lines, "\n")
			local file, err = io.open(vim.api.nvim_buf_get_name(self.buffer), "w")
			if not file then
				log.error("Error opening file: " .. err)
				return
			end
			file:write(buffer_content)
			file:close()
			self.llm:stop(self)
			vim.api.nvim_buf_delete(self.buffer, { force = true })
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
		group = self._group,
		buffer = self.buffer,
		callback = function()
			self:refresh()
			if not self.initialized then
				vim.api.nvim_win_call(self.win, function()
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

	-- Keymaps...
	vim.keymap.set("n", "<C-n>", function()
		self:append({ "\n<== user\n\n==>" })
	end, { nowait = true, noremap = true, silent = true, buffer = self.buffer })
	vim.keymap.set("n", "<C-c>", function()
		self.llm:stop(self)
	end, { nowait = true, noremap = true, silent = true, buffer = self.buffer })
	vim.keymap.set("n", "<C-r>", function()
		self.llm:chat(self)
	end, { nowait = true, noremap = true, silent = true, buffer = self.buffer })
	vim.keymap.set("n", "<C-y>", function()
		local func, err = load(self.prompt.data.fm.tree.preview)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, { nowait = true, noremap = true, silent = true, buffer = self.buffer })
	vim.keymap.set("n", "<C-a>", function()
		local func, err = load(self.prompt.data.fm.tree.commit)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, { nowait = true, noremap = true, silent = true, buffer = self.args.source_buf })
	vim.keymap.set("n", "<C-l>", function()
		local func, err = load(self.prompt.data.fm.tree.clear)
		if not func then
			error(err)
		end
		func()(self.args, self.data)
	end, { nowait = true, noremap = true, silent = true, buffer = self.args.source_buf })

	self.args.buffer = self.buffer
	self.args.win = self.win

	if self.prompt.data:frontmatter()["autorun"] then
		vim.schedule(function()
			self:refresh()
			self.llm:chat(self)
		end)
	end
end

---Refreshes the chat display
function Chat:refresh()
	self.data = require("lungan.markdown"):new(nil, vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false))
	require("lungan.nvim.renderer").render(self.options, self.win, self.buffer, self.data)
end

return Chat
