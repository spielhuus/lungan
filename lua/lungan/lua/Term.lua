local uv = require("luv")
local str = require("lungan.str")
local log = require("lungan.log")
local Repl = {}

function Repl:__is_echo(value)
	for i, v in ipairs(self.sent) do
		if str.rtrim(v) == value then
			table.remove(self.sent, i)
			return true
		end
	end
	return false
end

function Repl:wait(timeout, fn)
	local start_time = uv.hrtime()
	while true do
		if fn() then
			return true
		end
		local elapsed_time = uv.hrtime() - start_time
		if elapsed_time >= timeout * 1e6 then
			return false
		end
		uv.run("nowait")
	end
end

-- remove all \r and \n from the string
function Repl:_clean_str(value)
	return value:gsub("\r", ""):gsub("\n", "")
end

function Repl:callback(fn)
	self.on_message = fn
end

function Repl:new(on_message)
	local o = {}
	setmetatable(o, { __index = self })
	o.term = {}
	o.messages = {}
	o.on_message = on_message
	o.count = 1
	o.response = {}
	o.sent = {}
	return o
end

function Repl:run(cmd)
	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()
	self.job_id = uv.spawn(table.remove(cmd, 1), {
		args = cmd,
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function(code)
		print(str.to_string("Term:Exit:" .. code))
		-- on_exit(code, self:response())
	end)

	uv.read_start(self.stdout, function(err, data)
		require("lungan.log").trace("STDERR:", err, data)
		local clean_in = str.lines(data)
		local result = {}
		for _, c in ipairs(clean_in) do
			local stripped = str.stripnl(c)
			if not self:__is_echo(str.stripnl(stripped)) then
				table.insert(result, stripped)
			end
		end
		self.on_message(str.clean_table(result))
	end)

	uv.read_start(self.stderr, function(err, data)
		log.error("TERM:STDERR: Err:" .. (err or "nil") .. ", data:'" .. str.to_string(data) .. "'")
		if data then
			local clean_table = str.clean_table({ data })
			for _, token in ipairs(clean_table) do
				table.insert(self.stderr, token)
			end
		end
	end)
	return self.job_id
end

function Repl:stop()
	if self.job_id ~= nil then
		vim.fn.jobstop(self.job_id)
		self.job_id = nil
	end
end

function Repl:send(message)
	if type(message) == "table" then
		for _, m in ipairs(message) do
			table.insert(self.sent, m)
			uv.write(self.stdin, m .. "\r\n")
		end
	else
		table.insert(self.sent, message)
		uv.write(self.stdin, message .. "\r\n\r\n")
	end
end

return Repl
