---@class Page
---@field path string
---@field options table
local Page = {}

function Page:open()
	vim.cmd("edit " .. self.path)
	self.buffer = vim.api.nvim_win_get_buf(0)
end

function Page:content()
	local handle = io.open(self.path, "r")
	if not handle then
		return
	end
	local content = handle:read("*a")
	handle:close()
	return vim.split(content, "\n")
end

function Page:name()
	local name_with_extension = vim.fn.fnamemodify(self.path, ":t")
	return vim.fn.substitute(name_with_extension, "\\..*", "", "g")
end

function Page:filename()
	return self.path
end

function Page:attach(win, buffer)
	self.win = win
	self.buffer = buffer
	local group = vim.api.nvim_create_augroup("LunganRedraw", { clear = true })
	-- TODO add close
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "WinScrolled" }, {
		buffer = buffer,
		group = group,
		callback = function()
			self:refresh()
		end,
	})

	-- create the keymaps for this page
	vim.keymap.set("n", "<leader>r", function()
		local row, _ = vim.api.nvim_win_get_cursor(0)
		local cell = self:content_at_line(row[1])
		if cell then
			local repl, status
			status, repl = self:get_repl(cell.lang, function(line, message, c)
				if not self.results then
					self.results = {}
				end
				message.line = line + c.from
				table.insert(self.results, message)
				self:refresh()
			end)
			if not status then
				require("lungan.log").error("lungan: unable to start IPython: " .. repl)
				return
			end
			cell.text = cell.text .. "\nlungan.plots()"
			assert(repl)
			repl:send(cell)
		end
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = buffer,
	})

	self:refresh()
end

function Page:content_at_line(line)
	return self.data:get(line)
end

function Page:refresh()
	self.data = require("lungan.markdown"):new(nil, vim.api.nvim_buf_get_lines(self.buffer, 0, -1, false))
	require("lungan.nvim.renderer").render(self.options, self.win, self.buffer, self.data, self.results)
end

function Page:get_repl(lang, callback)
	if self.repls == nil then
		self.repls = {}
	end
	if not self.repls[lang] then
		if lang == "python" or lang == "py" then
			local status, repl = require("lungan.repl.IPython"):new(require("lungan.nvim.Term"):new(), callback)
			if not status then
				return status, repl
			end
			self.repls[lang] = repl
		elseif lang == "lua" then
			local repl = require("lungan.repl.lua"):new(nil, self.options, function(line, message)
				table.insert(self.results[line], message)
				self:refresh()
			end)
			self.repls[lang] = repl
		else
			require("lungan.log").warn("Unsupported language: " .. lang)
		end
	end
	return true, self.repls[lang]
end

function Page:new(o, options, path)
	o = o or {}
	setmetatable(o, { __index = self })
	o.options = options
	o.path = path
	o.win = nil
	o.buffer = nil
	o.results = nil
	o.repls = nil
	return o
end

return Page
