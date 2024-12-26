local log = require("lungan.log")

---@class Page
---@field path string
---@field data Markdown
---@field options table
---@field results table
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
			if not self.edit_content then
				self:refresh()
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "ModeChanged" }, {
		buffer = buffer,
		group = group,
		callback = function()
			local mode = vim.fn.mode()
			if mode == "i" then
				local current_line = vim.fn.line(".")
				local content = self:content_at_line(current_line)
				if content then
					require("lungan.nvim.renderer").clear(
						self.options,
						self.win,
						self.buffer,
						content["from"] - 1,
						content["to"]
					)
					self.edit_content = content
				end
			elseif mode == "n" and self.edit_content then
				self:refresh()
				self.edit_content = nil
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMovedI" }, {
		buffer = buffer,
		group = group,
		callback = function()
			local current_line = vim.fn.line(".")
			if
				self.edit_content
				and self.edit_content["from"] >= current_line
				and self.edit_content["to"] <= current_line
			then
				return
			else
				self:refresh()
				local content = self:content_at_line(current_line)
				if content then
					require("lungan.nvim.renderer").clear(
						self.options,
						self.win,
						self.buffer,
						content["from"] - 1,
						content["to"]
					)
					self.edit_content = content
				end
			end
		end,
	})

	-- clear all the results in the page
	vim.keymap.set("n", "<leader>nc", function()
		self.results = {}
		self:refresh()
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = buffer,
	})

	local function send_cell(cell)
		-- get the repl
		local repl, mes
		repl, mes = self:get_repl(cell.lang, function(line, message, c)
			log.trace("RECEIVE: ", line, message, c)
			message.line = line + c.from
			table.insert(self.results, message)
			self:refresh()
		end)
		if not repl then
			require("lungan.log").error(
				"lungan: unable to start Repl(" .. (cell.lang or "unknown") .. "): " .. (mes or "nil")
			)
			return
		end
		-- get the image when we are using a python repl
		if cell.lang == "py" or cell.lang == "python" then
			cell.text = cell.text .. "\nlungan.plots()"
		end
		assert(repl)
		log.trace("SEND:", cell)
		repl:send(cell)
	end

	vim.keymap.set("n", "<leader>na", function()
		self.results = {}
		for cell in self.data:iter() do
			if cell.type == "code" then
				send_cell(cell)
			end
		end

		self:refresh()
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = buffer,
	})

	-- create the keymaps for this page
	vim.keymap.set("n", "<leader>nr", function()
		local row, _ = vim.api.nvim_win_get_cursor(0)
		local cell = self:content_at_line(row[1])
		assert(cell)
		if cell then
			-- remove the old entry for this cell
			local new_results = {}
			for _, res in ipairs(self.results) do
				if res.line < cell.from or res.line > cell.to then
					table.insert(new_results, res)
				end
				self.results = new_results
			end
			-- get the repl
			send_cell(cell)
		end
	end, {
		nowait = true,
		noremap = true,
		silent = true,
		buffer = buffer,
	})

	self:refresh()
end

---@return table|nil
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
			local repl, mes =
				require("lungan.repl.Python"):new(require("lungan.repl.NvimTerm"):new(self.options), callback)
			if not repl then
				return repl, mes
			end
			self.repls[lang] = repl
		elseif lang == "lua" then
			local repl, mes =
				require("lungan.repl.Lua"):new(require("lungan.repl.NvimTerm"):new(self.options), callback)
			if not repl then
				return repl, mes
			end
			self.repls[lang] = repl
		else
			return nil, "Unsupported language: " .. lang
		end
	end
	return self.repls[lang], nil
end

function Page:new(o, options, path)
	o = o or {}
	setmetatable(o, { __index = self })
	o.options = options
	o.path = path
	o.win = nil
	o.buffer = nil
	o.results = {}
	o.repls = nil
	return o
end

return Page
