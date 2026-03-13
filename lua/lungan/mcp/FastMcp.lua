local str = require("str")
local log = require("lungan.log")

local state = {
	IDLE = 1,
	START = 2, -- server is starting
	WAIT = 3, -- wait for response
	CONT = 4, -- expect more content
}

local STARTUP_TIMEOUT = 5000
local EXECUTE_TIMEOUT = 10000

---@class FastMcp: IRepl
---@field prologue table
---@field on_message function
---@field repl ITerm
local FastMcp = {}

---Receive content from the Repl
---@param content any -- TODO: what is the type
function FastMcp:receive(content)
	if next(content) == nil then
		self.state = state.IDLE
	else
		for _, message in pairs(content) do
			if #message == 0 then
				print("END")
			else
				if message:sub(1, 1) == "{" and message:sub(-1) == "}" then
					local json = vim.json.decode(message)
					self.on_message(self.line, json, self.cell)
				else
					log.debug("LOG: " .. message)
				end
			end
		end
		self.state = state.IDLE
	end
end

---Wait for the current command
function FastMcp:wait()
	local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
		return self.state == state.IDLE
	end)
	if not w then
		error("WAIT_TIMEOUT: " .. require("str").to_string(wres))
	end
end

---Send a command to the Repl
---@param cell table the cell
function FastMcp:send(cell)
	log.debug("MCP send: " .. vim.inspect(cell))
	if self.state == state.START then
		assert(self.term)
		local w, wres = self.term:wait(STARTUP_TIMEOUT, function()
			return self.state == state.IDLE
		end)
		if not w then
			error("STARTUP_TIMEOUT: " .. require("str").to_string(wres))
		end
	end

	if self.state ~= state.IDLE then
		local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
			return self.state == state.IDLE
		end)
		if not w then
			error("EXECUTE_TIMEOUT:" .. wres)
		end
	end

	self.cell = cell
	for i, line in ipairs(str.lines(cell)) do
		if str.trim(line) ~= "" then
			local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
				return self.state == state.IDLE or self.state == state.CONT
			end)
			if not w then
				error("EXECUTE_TIMEOUT:" .. wres)
			end
			self.state = state.WAIT
			self.line = i
			self.term:send(line)
		end
	end
end

---Resolve the path to the mcp server script
---@param path string -- path to the mcp server script
---@return string|nil -- resolved path or nil if not found
function FastMcp:resolve_path(path)
	local script_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h")

	-- Check if path is already absolute and exists
	if vim.fn.isdirectory(vim.fn.fnamemodify(path, ":h")) ~= 0 then
		return path
	end

	local cwd = vim.fs.normalize(vim.fn.getcwd())
	-- local plugin_root_path = script_path:match("^(.*/rplugin)/")

	-- Check in current working directory first (relative to CWD)
	if not string.find(path, "/") and #path > 0 then
		local path_cwd = vim.fs.normalize(cwd .. "/" .. path)
		if vim.fn.filereadable(path_cwd) == 1 then
			return path_cwd
		end
	end

	-- Check in plugin root directory (relative to script location)
	for _, base_dir in ipairs({ cwd, script_path }) do
		local full_path = vim.fs.normalize(base_dir .. "/" .. path)
		if vim.fn.filereadable(full_path) == 1 then
			return full_path
		end
	end

	return nil
end

function FastMcp:new(term, server, on_message, on_close)
	local o = {}
	setmetatable(o, { __index = self, __name = "FastMcp" })
	setmetatable(FastMcp, { __index = require("lungan.repl.IRepl") })
	o.on_message = on_message
	o.term = term
	o.term:callback(function(line, message)
		o:receive(line, message)
	end)
	o.term.on_close = on_close
	o.state = state.START

	local path = self:resolve_path(server)
	if path == nil then
		log.error("server file not found: " .. server)
		return
	end
	local status, mes = o.term:run({ "python", path })
	if not status then
		return nil, mes
	end
	o:wait()
	local init =
		'{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"0.1.0","capabilities":{"roots":{},"sampling":{}},"clientInfo":{"name":"mcp-inspector","version":"0.1.0"}},"id":0}\r\n'
	o:send(init)

	o.count = 1
	o.response = {}
	o.sent = {}
	return o
end

return FastMcp
