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
	-- print("------------->" .. vim.inspect(content))
	-- check if the input is json and parse it, print the json
	-- check if the string starts with { and ends with }
	-- if type(content) == "table" then
	-- 	content = string.gsub(table.concat(content, ""), "\n", "")
	-- 	print("reveived '''" .. vim.inspect(content) .. "'''")
	-- 	if content:sub(1, 1) == "{" and content:sub(-1) == "}" then
	-- 		print('parsing json:"' .. content .. '"')
	-- 		content = vim.json.decode(content)
	-- 		print(vim.inspect(content))
	-- 	else
	-- 		print("LOG:" .. vim.inspect(content))
	-- 	end
	-- else
	-- 	print("other type:" .. vim.inspect(content))
	-- end
	--
	--
	-- if type(content) == "table" then
	-- 	print("reveived '''" .. vim.inspect(table.concat(content, "")) .. "'''")
	-- 	content = vim.json.decode(vim.fn.shellescape(table.concat(content, "")))
	-- 	print(vim.inspect(content))
	-- else
	-- 	print("ERROR: content is: " .. type(content) .. " " .. vim.inspect(content))
	-- end

	-- local result = {}
	-- for _, entry in ipairs(content) do
	-- 	if entry == ">" then
	-- 		if #result > 0 then
	-- 			local message = {
	-- 				stdout = result,
	-- 			}
	-- 			-- TODO: handle errors
	-- 			-- if self.response.has_err == true then
	-- 			-- 	local err, mes = self:__parse_error(self.response.stdout)
	-- 			-- 	if err then
	-- 			-- 		message.error = err
	-- 			-- 	else
	-- 			-- 		log.error("Error in parse error: " .. mes)
	-- 			-- 	end
	-- 			-- end
	-- 			self.on_message(self.line, message, self.cell)
	-- 		end
	-- 		self.state = state.IDLE
	-- 	elseif entry == ">>" then
	-- 		self.state = state.CONT
	-- 	elseif self.state ~= state.START then
	-- 		if str.trim(entry) ~= "" then
	-- 			table.insert(result, entry)
	-- 		end
	-- 	else
	-- 		log.debug("skip: " .. entry)
	-- 	end
	-- end
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

function FastMcp:new(term, on_message, on_close)
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
	local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h")
	local script_path = plugin_root .. "/rplugin/python3/mcp-server.py"
	local status, mes = o.term:run({ "python", script_path })
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
