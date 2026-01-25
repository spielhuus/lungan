local str = require("lungan.str")

---@class NvimJob: ITerm
---@field sent table[string]
---@field term table
---@field options table
---@field _stdout_buffer table
local NvimJob = {}

function NvimJob:__is_echo(value)
	for i, v in ipairs(self.sent) do
		if str.rtrim(v) == value then
			table.remove(self.sent, i)
			return true
		end
	end
	return false
end

function NvimJob:wait(timeout, fn)
	return vim.wait(timeout, fn)
end

-- remove all \r and \n from the string
function NvimJob:_clean_str(value)
	return value:gsub("\r", ""):gsub("\n", "")
end

function NvimJob:callback(fn)
	self.on_message = fn
end

function NvimJob:on_close(fn)
	self.on_close = fn
end

function NvimJob:new(options, on_message, on_close)
	local o = {}
	setmetatable(o, { __index = self, name = "NvimJob" })
	o.term = {}
	o.messages = {}
	o.on_message = on_message
	o.on_close = on_close
	o.count = 1
	o.response = {}
	o.sent = {}
	o.options = options

	-- Initialize the stdout buffer with one empty string to start
	o._stdout_buffer = { "" }

	if options.repl_show then
		if not o.term.buffer then
			o.term.buffer = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(o.term.buffer, "Lungan REPL: #" .. o.term.buffer)
			vim.api.nvim_set_option_value("buftype", "nowrite", { buf = o.term.buffer })
			vim.api.nvim_set_option_value("filetype", "markdown", { buf = o.term.buffer })

			-- create the window
			local win_width = vim.api.nvim_win_get_width(0)
			local win_height = vim.api.nvim_win_get_height(0)
			local new_win_width = math.floor(win_width / 2)
			o.term.win = vim.api.nvim_open_win(o.term.buffer, true, {
				relative = "win",
				width = new_win_width - 3,
				height = win_height - 3,
				row = 0,
				col = new_win_width,
				style = "minimal",
				border = "shadow",
			})
			vim.api.nvim_set_option_value("cursorline", false, { win = o.term.win })
			local group = vim.api.nvim_create_augroup("LunganTerm", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
				buffer = o.term.buffer,
				group = group,
				callback = function()
					if o.on_close then
						o.on_close()
					end
				end,
			})
			vim.cmd("wincmd p")
		end
	end
	return o
end

function NvimJob:run(cmd)
	-- Shared callback options
	local opts = {
		on_exit = function(_, code, _)
			self.term.code = code
			self.term.chanid = nil
			self.term.opened = 0
			self.term.win = nil
			self.term.buffer = nil
		end,
		on_stderr = function(_, data, _)
			-- You might want to filter empty stderr messages
			if data and #data > 1 or (#data == 1 and data[1] ~= "") then
				self.on_message(str.clean_table(data))
			end
		end,
		on_stdout = function(_, data, _)
			-- STANDARD NEOVIM STDOUT BUFFERING
			-- data is always a table of strings.
			-- If a line is split, data[1] completes the previous line.
			-- The last element of data is the start of the next line (incomplete).
			if data then
				self._stdout_buffer[#self._stdout_buffer] = self._stdout_buffer[#self._stdout_buffer] .. data[1]

				-- If there are more lines, push them onto the buffer
				if #data > 1 then
					for i = 2, #data do
						table.insert(self._stdout_buffer, data[i])
					end
				end

				local complete_lines = {}
				while #self._stdout_buffer > 1 do
					local line = table.remove(self._stdout_buffer, 1)
					local stripped = str.stripnl(line)
					-- Filter out echoes and empty lines
					if stripped ~= "" and not self:__is_echo(stripped) then
						table.insert(complete_lines, stripped)
					end
				end

				if #complete_lines > 0 then
					self.on_message(complete_lines)
				end
			end
		end,
	}

	if self.options.repl_show and self.term.win and vim.api.nvim_win_is_valid(self.term.win) then
		-- Debug mode: Switch to window and use termopen
		local current_win = vim.api.nvim_get_current_win()
		vim.api.nvim_set_current_win(self.term.win)

		local status
		status, self.term.chan = pcall(vim.fn.termopen, cmd, opts)

		vim.api.nvim_set_current_win(current_win) -- Go back to caller
		return status, self.term.chan
	else
		local job_id = vim.fn.jobstart(cmd, opts)
		if job_id > 0 then
			self.term.chan = job_id
			return true, job_id
		else
			return false, "Failed to start job via jobstart"
		end
	end
end

function NvimJob:stop()
	if self.term.chan ~= nil then
		vim.fn.jobstop(self.term.chan)
		self.term.chan = nil
	end
end

function NvimJob:send(message)
	if not self.term.chan then
		return
	end

	if type(message) == "table" then
		for _, m in ipairs(message) do
			table.insert(self.sent, m)
			vim.api.nvim_chan_send(self.term.chan, m .. "\n")
		end
	else
		table.insert(self.sent, message)
		vim.api.nvim_chan_send(self.term.chan, message .. "\n")
	end
end

return NvimJob
