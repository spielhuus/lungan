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

---@class Lua: IRepl
---@field prologue table
---@field on_message function
---@field messages table[string]
---@field repl ITerm
local Lua = {}

function Lua:_result_clean(line)
	local indexes = {}
	for i, v in ipairs(self.messages) do
		if v.line == line then
			table.insert(indexes, i)
		end
	end
	for _, del in ipairs(indexes) do
		table.remove(self.messages, del)
	end
end

function Lua:run(cell)
	local handle = io.popen("lua -e '" .. vim.fn.shellescape(vim.json.encode(cell.text)) .. "'")
	if not handle then
		error("io.popen returned nil, is it supported on your system?")
	end
	local result = handle:read("*a")
	if not self.response.stdout then
		self.response.stdout = {}
	end
	for _, l in ipairs(vim.split(result, "\n")) do
		table.insert(self.response.stdout, l)
	end
	handle:close()

	local response = {
		line = cell.to,
		stdout = self.response.stdout,
		stderr = self.response.stderr,
		out = self.response.out,
	}
	self:_result_clean(cell.to)
	table.insert(self.messages, response)
	self.response = {}
	-- local env = setmetatable({}, { __index = _G })
	-- local func, errmsg = load(cell.text, "=(execute)", "t", env)
	-- if func then
	--     local old_stdout = io.stdout
	--     local t = {}
	--     io.stdout = {
	--         write = function(_, ...)
	--             for _, v in ipairs({ ... }) do
	--                 print("STDOUT:" .. v)
	--                 table.insert(t, tostring(v))
	--             end
	--         end,
	--     }
	--     func()
	--     io.stdout = old_stdout
	--     local stdout = table.concat(t, "")
	--     print("RES_OUT" .. vim.inspect(stdout))
	--     print("RES_DATA" .. vim.inspect(env))
	-- else
	--     error(errmsg)
	-- end
end

---Receive content from the Repl
---@param content any -- TODO: what is the type
function Lua:receive(content)
	log.debug("receive content: " .. self.state .. " " .. require("str").to_string(content))
	for _, entry in ipairs(content) do
		if entry == ">" then
			self.state = state.IDLE
		elseif entry == ">>" then
			self.state = state.CONT
		elseif self.state ~= state.START then
			log.trace("stdout: " .. entry .. ", cell:" .. str.to_string(self.cell))
			local message = {
				self.line,
				out = nil,
				stdout = { entry },
				line = self.line,
			}
			-- if self.response.has_err == true then
			-- 	local err, mes = self:__parse_error(self.response.stdout)
			-- 	if err then
			-- 		message.error = err
			-- 	else
			-- 		log.error("Error in parse error: " .. mes)
			-- 	end
			-- end
			self.on_message(self.line, message, self.cell)
			-- table.insert(self.messages, entry)
		else
			log.debug("skip: " .. entry)
		end
	end
end

---Wait for the current command
function Lua:wait()
	error("`Lua:wait` not implemented")
end

---Send a command to the Repl
---@param cell table the cell
function Lua:send(cell)
	self.cell = cell
	log.debug("send:" .. require("str").to_string(cell))

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

	local has_continue = false
	for i, line in ipairs(str.lines(cell.text)) do
		if str.trim(line) ~= "" then
			local w, wres = self.term:wait(EXECUTE_TIMEOUT, function()
				return self.state == state.IDLE or self.state == state.CONT
			end)
			if not w then
				error("EXECUTE_TIMEOUT:" .. wres)
			end
			if self.state == state.CONT then
				has_continue = true
			end
			self.state = state.WAIT
			self.line = i
			self.term:send(line)
		end
	end
	if has_continue then
		self.term:send("\r")
	end
	-- for _, line in ipairs(cell) do
	-- log.debug(">send: " .. cell.text)
	-- self.term:send(cell.text)
	-- end
end

function Lua:new(term, on_message)
	local o = {}
	setmetatable(o, { __index = self, __name = "Lua" })
	setmetatable(Lua, { __index = require("lungan.repl.IRepl") })
	o.on_message = on_message
	o.term = term
	o.term:callback(function(line, message)
		o:receive(line, message)
	end)
	o.state = state.START
	local status, mes = o.term:run({ "luajit" })
	if not status then
		return nil, mes
	end
	o.messages = {}
	o.count = 1
	o.response = {}
	o.sent = {}
	return o
end

return Lua
