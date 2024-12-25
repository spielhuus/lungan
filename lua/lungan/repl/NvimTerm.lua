local str = require("lungan.str")
local log = require("lungan.log")

---@class NvimRepl: ITerm
---@field sent table[string]
---@field term table
local NvimRepl = {}

function NvimRepl:__is_echo(value)
	for i, v in ipairs(self.sent) do
		if str.rtrim(v) == value then
			table.remove(self.sent, i)
			return true
		end
	end
	return false
end

function NvimRepl:wait(timeout, fn)
	return vim.wait(timeout, fn)
end

-- remove all \r and \n from the string
function NvimRepl:_clean_str(value)
	return value:gsub("\r", ""):gsub("\n", "")
end

function NvimRepl:callback(fn)
	self.on_message = fn
end

function NvimRepl:new(options, on_message)
	local o = {}
	setmetatable(o, { __index = self, name = "NvimRepl" })
	o.term = {}
	o.messages = {}
	o.on_message = on_message
	o.count = 1
	o.response = {}
	o.sent = {}
	o.options = options
	-- open the buffer
	if not o.term.buffer then
		o.term.buffer = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(o.term.buffer, "Lungan REPL: #" .. o.term.buffer)
		vim.api.nvim_set_option_value("buftype", "nowrite", { buf = o.term.buffer })
		vim.api.nvim_set_option_value("filetype", "markdown", { buf = o.term.buffer })

		if options.repl_show then -- TODO: this does not work with termopen
			-- creat the window
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
		end
	end
	return o
end

function NvimRepl:run(cmd)
	-- initialize the repl
	local status
	status, self.term.chan = pcall(vim.fn.termopen, cmd, {
		on_exit = function(_, code, _)
			self.term.code = code
			self.term.chanid = nil
			self.term.opened = 0
			self.term.win = nil
			self.term.buffer = nil
		end,
		on_stderr = function(_, data, _)
			log.error("ERROR: " .. vim.inspect(data))
		end,
		on_stdout = function(_, data, _)
			local clean_in = str.clean_table(data)
			local result = {}
			for _, c in ipairs(clean_in) do
				local stripped = str.stripnl(c)
				if not self:__is_echo(str.stripnl(stripped)) then
					table.insert(result, stripped)
				end
			end
			self.on_message(str.clean_table(result))
		end,
	})
	vim.cmd("wincmd p") -- go back to the caller win
	return status, self.term.chan
end

function NvimRepl:stop()
	if self.job_id ~= nil then
		vim.fn.jobstop(self.job_id)
		self.job_id = nil
	end
end

function NvimRepl:send(message)
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

return NvimRepl
